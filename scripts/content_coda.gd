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
static func workbook_again(kit_line := "") -> Array:
	var seq: Array = [{"s": "", "t": "（你又讀了一遍工作簿最後一頁。字比你記得的還要歪。）"}]
	if not kit_line.is_empty():
		seq.append({"s": "工作簿", "t": kit_line})
	return seq


## fit: Judgment fit of the telegram (2 best, 1 defensible, 0 wrong). clean: plate selection
## was made by image quality before seeing values. measured_any: at least one plate measured.
static func ashby_answer(fit: int, clean: bool, measured_any: bool, any_usable := false) -> Array:
	var seq: Array = [{"s": "", "t": "（你拿起 %s的放大鏡。）" % CAST.MENTOR}]
	if not measured_any and any_usable:
		seq.append({"s": YOU, "t": "（放大鏡底下有星點——是你沒有拿去量的那幾張。）"})
		seq.append({"s": YOU, "t": "（雲很厚，可是不是什麼都沒留下。回去以後，先把它們量完。）"})
	elif not measured_any:
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


## Issue #37 loop 5 (proposal): the old small doubts come back beside tonight's numbers.
## residual_found: the plate-14 residual was found in 1917. FICTION; claims no proof.
static func small_numbers(residual_found: bool, measured_any: bool) -> Array:
	var seq: Array = []
	if residual_found:
		seq.append({"s": YOU, "t": "（14 號底片上那一點極淡的白。兩年了，還是沒有人知道它是什麼。）"})
	seq.append({"s": YOU, "t": "（Eddington 那個關緊的箱子。從裡面分不出來——所以才要到這裡，看太陽旁邊的星。）"})
	if measured_any:
		seq.append({"s": YOU, "t": "（今晚量出來的，也只是幾個很小的數字。小，不等於沒有；也不等於證明。）"})
	else:
		seq.append({"s": YOU, "t": "（今晚什麼也沒量到。沒有數字，也是一筆紀錄。）"})
	return seq


## bond_tone: "close" | "warm" (Story). Restrained; no confession, no letter.
## kit_choice is the 1917 answer about the childhood star chart (-1: no prologue).
## overclaimed: the telegram said more than the plates (CONFIRMED).
static func kit_close(bond_tone: String, kit_choice := -1, overclaimed := false, misread := false, clean := true, sky_promise := -1) -> Array:
	var seq: Array = [{"s": YOU, "t": "（工作簿後面還有很多空白頁。回去的路還很長。）"}]
	match kit_choice:
		0:
			if overclaimed:
				seq.append({"s": YOU, "t": "（小時候那張星圖。畫錯，跟說謊，不是一回事——可是今晚的電報，寫得比底片上的多。）"})
			elif misread:
				seq.append({"s": YOU, "t": "（小時候那張星圖。畫錯，跟說謊，不是一回事——今晚的電報，和底片上的不一樣。）"})
			else:
				seq.append({"s": YOU, "t": "（小時候那張星圖。畫錯，跟說謊，不是一回事。今晚的電報，只寫了底片上有的。）"})
		2:
			seq.append({"s": YOU, "t": "（那天晚上 Kit 問起那張星圖，你沒有回答。見了面，也許可以從那張圖說起。）"})
	if bond_tone == "close":
		seq.append({"s": YOU, "t": "（有些話，也許可以等到見了面再說。）"})
		seq.append({"s": YOU, "t": "（也許。）"})
	else:
		seq.append({"s": YOU, "t": "（Kit 一定會先問天空，再問底片。）"})
	match sky_promise:
		0:
			seq.append({"s": YOU, "t": "（出發前我要 Kit 告訴我，劍橋這段時間變了什麼。她大概已經記了一整頁。）"})
		1:
			seq.append({"s": YOU, "t": "（我跟 Kit 說過，全食那五分鐘我會在換底片。我換了。她會想知道換到第幾張。）"})
	var no_mistake := not overclaimed and not misread and clean
	var replies: Array = []
	for i in 3:
		replies.append([{"s": YOU, "t": kit_first_reply(i, no_mistake)}])
	seq.append({"s": YOU, "t": "（見到 Kit，第一句話要說什麼？）", "key": "kit_first",
		"choices": ["先說天空：雲在最後才薄下去。", "先說不確定：數字很小，範圍很寬。",
			"先說那張星圖。" if no_mistake else "先說錯誤：我今天也犯了一個錯。"],
		"then": replies})
	seq.append({"s": "", "t": "（你吹熄了燈。）"})
	return seq


static func kit_first_reply(choice: int, no_mistake: bool) -> String:
	match choice:
		0:
			return "雲在最後才薄下去，我一直看著。"
		1:
			return "數字很小，範圍很寬，我還不能說得更確定。"
		2:
			return "我還記得小時候那張星圖。" if no_mistake else "我今天也犯了一個錯，回去再慢慢告訴你。"
	return ""
