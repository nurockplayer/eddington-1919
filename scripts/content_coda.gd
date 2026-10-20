extends RefCounted
class_name ContentCoda
## M3 — Príncipe coda for players who came through the prologue (Story.from_prologue).
## Plays after Eddington's response to the telegram and before the ending screen.
## Written by the Game Director (Opus 5.5). FICTION; internal lines of the protagonist are
## parenthetical. Pays off Ashby's charge (M1/M2) and Kit's sky promise (M2) without letters,
## reunion, keepsake or any confession. Pure data: no Story/scene references (headless-safe).

const CAST = preload("res://scripts/cambridge/cast.gd")

const YOU := CAST.YOU


static func opening() -> Array:
	return [
		{"s": "", "t": "（Eddington 把電報稿折好，收進外套口袋，出去找送電報的人。）"},
		{"s": "", "t": "（雨早就停了。屋外的蟲聲很響，暗房裡只剩下你和桌上的燈。）"},
	]


## When the workbook page was already written during the night phase.
static func workbook_again() -> Array:
	return [{"s": "", "t": "（你又讀了一遍工作簿最後一頁。字比你記得的還要歪。）"}]


## fit: Judgment fit of the telegram (2 best, 1 defensible, 0 wrong). clean: plate selection
## was made by image quality before seeing values. measured_any: at least one plate measured.
static func ashby_answer(fit: int, clean: bool, measured_any: bool) -> Array:
	var seq: Array = [{"s": "", "t": "（你拿起 %s的放大鏡。）" % CAST.MENTOR}]
	if not measured_any:
		seq.append({"s": YOU, "t": "（放大鏡底下沒有可以量的東西——只有雲留下的一片灰。）"})
		seq.append({"s": YOU, "t": "（可是你把雲記下來了。他說過：無論看見什麼。）"})
	elif fit == 2 and clean:
		seq.append({"s": YOU, "t": "（底片、數字、電報——每一步都寫在紙上了，連那幾張不能用的也是。）"})
		seq.append({"s": YOU, "t": "（他不會因為這樣就相信。可是他會一頁一頁讀下去。這就夠了。）"})
	elif fit == 2:
		seq.append({"s": YOU, "t": "（電報沒有說錯。可是選片那一頁，有一行你寫得不夠乾淨。）"})
		seq.append({"s": YOU, "t": "（回去以後把它補上——在他問之前。）"})
	elif fit == 1:
		seq.append({"s": YOU, "t": "（電報寫得太小心，或是太寬鬆——你自己也說不準。）"})
		seq.append({"s": YOU, "t": "（他會在旁邊畫一個問號。問號不丟人。）"})
	else:
		seq.append({"s": YOU, "t": "（電報已經發出去了，收不回來。）"})
		seq.append({"s": YOU, "t": "（你想起他說的：要被一張乾淨的底片說服，而不是被一個好故事。）"})
		seq.append({"s": YOU, "t": "（這一次，你差一點就成了那個好故事。）"})
	return seq


## bond_tone: "close" | "warm" (Story). Restrained; no confession, no letter.
static func kit_close(bond_tone: String) -> Array:
	var seq: Array = [{"s": YOU, "t": "（工作簿後面還有很多空白頁。回去的路還很長。）"}]
	if bond_tone == "close":
		seq.append({"s": YOU, "t": "（有些話，也許可以等到見了面再說。）"})
		seq.append({"s": YOU, "t": "（也許。）"})
	else:
		seq.append({"s": YOU, "t": "（Kit 一定會先問天空，再問底片。你已經想好要怎麼回答了。）"})
	seq.append({"s": "", "t": "（你吹熄了燈。）"})
	return seq
