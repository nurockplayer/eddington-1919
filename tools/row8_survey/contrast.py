from collections import Counter

SRGB = [
    value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4
    for value in (channel / 255 for channel in range(256))
]
NEIGHBORS = (
    (0, -1), (-1, 0), (1, 0), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)
)


def luminance(rgb):
    return sum(SRGB[channel] * weight for channel, weight in zip(rgb, (0.2126, 0.7152, 0.0722)))


def contrast_ratio(ink, paper):
    low, high = sorted((luminance(ink), luminance(paper)))
    return (high + 0.05) / (low + 0.05)


def difference(first, second):
    return max(
        abs(first[0] - second[0]),
        abs(first[1] - second[1]),
        abs(first[2] - second[2]),
    )


def spans(components, axis, gap):
    """Group components by their projected intervals on one axis."""
    group = []
    end = -1
    for component in sorted(components, key=lambda part: part[2][axis]):
        first = component[2][axis]
        if group and first - end > gap:
            yield group
            group = []
        end = max(end, component[2][axis + 2])
        group.append(component)
    if group:
        yield group


def lower_quartile(components):
    rank = (sum(area for _, area, _ in components) - 1) // 4
    for sample, area, _ in sorted(components):
        if rank < area:
            return sample
        rank -= area


def measure(visible, hidden, restored, width):
    """Measure a cropped text rect from three RGB rasters in row-major order."""
    paper, count = Counter(visible).most_common(1)[0]
    # Hiding text can change the panel behind it. A flat paper color that
    # dominates both text-on frames is a better witness when it disappears.
    size = len(visible)
    if count * 3 >= size * 2 and restored.count(paper) * 3 >= size * 2 and hidden.count(paper) * 2 < size:
        hidden = (paper,) * size

    pixels = {}
    for index, (ink, paper, repeat) in enumerate(zip(visible, hidden, restored)):
        if ink == paper:
            continue
        change = difference(ink, paper)
        if change >= 6 and difference(ink, repeat) <= min(4, change // 3):
            point = index % width, index // width
            pixels[point] = contrast_ratio(ink, paper), ink, paper, point

    components = []
    while pixels:
        point, strongest = pixels.popitem()
        pending = [point]
        area = 0
        left = right = point[0]
        top = bottom = point[1]
        while pending:
            x, y = pending.pop()
            area += 1
            left, top = min(left, x), min(top, y)
            right, bottom = max(right, x), max(bottom, y)
            for dx, dy in NEIGHBORS:
                neighbor = x + dx, y + dy
                if neighbor in pixels:
                    strongest = max(strongest, pixels.pop(neighbor))
                    pending.append(neighbor)
        components.append((strongest, area, (left, top, right, bottom)))

    if not components:
        return None
    # Estimate ink from each component's strongest pixel. Keep the area-weighted
    # lower quartile for the full control and for word-sized runs. A short dim
    # run can otherwise disappear among stronger letters in a long caption.
    weakest = lower_quartile(components)
    for line in spans(components, axis=1, gap=1):
        height = max(part[2][3] for part in line) - line[0][2][1] + 1
        for run in spans(line, axis=0, gap=max(3, round(height / 4))):
            width = max(part[2][2] for part in run) - run[0][2][0] + 1
            if width >= 0.75 * height:
                weakest = min(weakest, lower_quartile(run))
    return (*weakest, len(components))
