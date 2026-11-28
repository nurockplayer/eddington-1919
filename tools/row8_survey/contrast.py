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
    return max(abs(a - b) for a, b in zip(first, second))


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
        change = difference(ink, paper)
        if change >= 6 and difference(ink, repeat) <= min(4, change // 3):
            point = index % width, index // width
            pixels[point] = contrast_ratio(ink, paper), ink, paper, point

    components = []
    while pixels:
        point, strongest = pixels.popitem()
        pending = [point]
        area = 0
        while pending:
            x, y = pending.pop()
            area += 1
            for dx, dy in NEIGHBORS:
                neighbor = x + dx, y + dy
                if neighbor in pixels:
                    strongest = max(strongest, pixels.pop(neighbor))
                    pending.append(neighbor)
        components.append((strongest, area))

    # Use each component's strongest pixel to estimate its ink. Weight the
    # lower quartile by area so stray edge fragments cannot set the score.
    rank = (sum(area for _, area in components) - 1) // 4
    for sample, area in sorted(components):
        if rank < area:
            return (*sample, len(components))
        rank -= area
    return None
