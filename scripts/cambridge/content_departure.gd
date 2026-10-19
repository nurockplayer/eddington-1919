extends RefCounted
class_name CambridgeContentDeparture
## M2 — the night before departure, Cambridge, March 1919. All dialogue and examine text.
## Written by the Game Director (Opus 5.5) as a PROPOSAL inside the Owner-approved structure
## (Narrative Bible §3B mentor farewell + gift concept, §3I–3M peer + sky promise, romance tempo:
## unspoken before departure). Names are placeholders (cast.gd). No confession on any route.
## No keepsake / microimage (canon open). Every line is FICTION unless the montage marks it.

const CAST = preload("res://scripts/cambridge/cast.gd")

const K := CAST.KIT
const A := CAST.MENTOR
const YOU := CAST.YOU


static func intro_caption() -> String:
	return "劍橋天文台・1919 年 3 月，出發前一晚\n（重建場景）"


## Played on entering. The blackout curtain is gone; crates by the door.
static func opening() -> Array:
	return [
		{"s": K, "t": "窗簾拆了。整整四年，我第一次在這個房間看見外面的路燈。"},
		{"s": K, "t": "你的茶。糖還是配給的——這一點是我省下來的，不要浪費。"},
		{"s": K, "t": "最後一頁。我念底片上量到的數，你對清單。對完這頁，箱子就可以釘起來了。",
			"key": "open", "choices": ["「好。」", "「你省下來的？那你呢？」"],
			"then": [
				[],
				[{"s": K, "t": "我說過了，我喝不慣甜的。"}, {"s": K, "t": "……兩年了，你還在問。快去。"}],
			]},
	]


## Five entries for the last shared check. Coordinates are measuring-machine plate x/y in mm
## (FICTION; deliberately not real star positions). hand: whose handwriting is on the list.
## Exactly one entry (slip) is the player's own transcription slip (transposed digits).
static func check_entries() -> Array:
	return [
		{"id": "s21", "label": "第 21 號", "list": "x 38.42　y 12.07", "plate": "x 38.42　y 12.07", "hand": "kit"},
		{"id": "s22", "label": "第 22 號", "list": "x 40.15　y 19.88", "plate": "x 40.15　y 19.88", "hand": "you"},
		{"id": "s23", "label": "第 23 號", "list": "x 41.27　y 18.63", "plate": "x 41.27　y 16.83", "hand": "you", "slip": true},
		{"id": "s24", "label": "第 24 號", "list": "x 44.90　y 21.35", "plate": "x 44.90　y 21.35", "hand": "kit"},
		{"id": "s25", "label": "第 25 號", "list": "x 47.06　y 15.52", "plate": "x 47.06　y 15.52", "hand": "you"},
	]


## Kit reads each plate value aloud before the player marks it.
static func kit_reads(entry: Dictionary) -> Array:
	return [{"s": K, "t": "%s。%s。" % [entry.label, entry.plate]}]


## After the five marks. caught_by_player: the player marked the slip ✗ themselves.
## false_alarm: the player marked a correct entry ✗ (Kit re-reads it; no penalty).
static func slip_found(caught_by_player: bool, false_alarm: bool) -> Array:
	var seq: Array = []
	if false_alarm:
		seq.append({"s": K, "t": "（又念了一次）……那一行是對的。眼睛累了。沒關係，就是要這樣一行一行對。"})
	if caught_by_player:
		seq.append({"s": K, "t": "你先看到了。十八點六三，十六點八三——兩個數字換了位置。"})
	else:
		seq.append({"s": K, "t": "等等。第 23 號，再念一次：十六點八三。"})
		seq.append({"s": K, "t": "清單上寫的是十八點六三。兩個數字換了位置。"})
	seq.append({"s": K, "t": "（把清單轉過來給你看）……是你的字。"})
	seq.append({"s": YOU, "t": "（兩年前在這張桌子上，你在報告裡寫過：對不上的地方，要寫它對不上。）"})
	seq.append({"s": K, "t": "怎麼改？",
		"key": "slip_fix", "choices": ["劃一條線，旁邊寫正確的數字，簽上縮寫。", "擦掉，直接寫上正確的數字。"],
		"then": [
			[{"s": K, "t": "（看你簽名）好。以後拿到這張紙的人，看得出這裡改過，也看得出是誰改的。"}],
			[{"s": K, "t": "……乾淨多了。"}, {"s": K, "t": "只是，到了那邊，如果有人問這個數字是從哪裡來的——你記得是你改的。紙不記得。"}],
		]})
	seq.append({"s": K, "t": "兩年，一千多行，錯一行。我量變星的時候，一個晚上就不只錯一行了。"})
	return seq


## Small acts of care. Any one choice sets Story.bond_tone; it only colours later lines.
## Index 0 → "close", 1 and 2 → "warm". Never a score.
static func before_closing() -> Array:
	return [
		{"s": "", "t": "（你的鉛筆削好了，排在清單旁邊。不是你削的。）"},
		{"s": K, "t": "箱子明天早上六點來搬。我叫了推車。"},
		{"s": K, "t": "所以……今晚沒有別的事了。",
			"key": "bond", "choices": ["「那再坐一下。」", "「我來收拾。」", "「你連推車都叫好了，那我呢？也要釘進箱子裡？」"],
			"then": [
				[{"s": K, "t": "（把椅子拉近看片台。沒有說話。燈光底下，兩個人的影子落在同一張底片上。）"}],
				[{"s": "", "t": "（和 Kit 一起把底片收進木框，一格一格，誰也沒說話。）"}, {"s": K, "t": "……好了。比我一個人快一倍。"}],
				[{"s": K, "t": "如果釘得進去的話。"}, {"s": K, "t": "……別讓我想像那個畫面。"}],
			]},
	]


## The sky-sharing promise. bond_tone: "close" | "warm". No confession on any route.
static func sky_promise(bond_tone: String) -> Array:
	var seq: Array = [
		{"s": K, "t": "到了那邊，記得告訴我天空是什麼樣子。"},
		{"s": K, "t": "不是底片上的。是你自己抬頭看到的。",
			"key": "promise", "choices": ["「那你也得告訴我，這裡有什麼變了。」", "「全食只有五分鐘，我會在換底片。」"],
			"then": [
				[{"s": K, "t": "這裡？（笑）這裡什麼都不會變。"}, {"s": K, "t": "……好。我寫。"}],
				[{"s": K, "t": "那就在五分鐘之前，或是之後。"}, {"s": K, "t": "那裡的天空也有晚上。我會問你。"}],
			]},
		{"s": K, "t": "（翻開工作簿，最後面有一頁是空的。上面已經寫好了日期：1919 年 5 月 29 日。）"},
		{"s": K, "t": "那裡看到的，記在這裡。回來的時候，我要看。"},
	]
	if bond_tone == "close":
		seq.append({"s": K, "t": "還有——"})
		seq.append({"s": "", "t": "（Kit 停了很久。）"})
		seq.append({"s": K, "t": "……你的鉛筆。記得帶。"})
	else:
		seq.append({"s": K, "t": "還有你的鉛筆。上次你借走我三枝。"})
	return seq


## Ashby, alone, in the corridor. Gift = CAST.MENTOR_GIFT (placeholder type; never claimed real).
## slip_fix: 0 = struck and initialled, 1 = overwritten (Ashby has seen the last page).
static func mentor_farewell(slip_fix: int) -> Array:
	var seq: Array = [
		{"s": A, "t": "清單我看過了。最後一頁也看了。"},
	]
	if slip_fix == 0:
		seq.append({"s": A, "t": "第 23 號劃了一條線，旁邊簽了名。兩年前你還不會這樣做。"})
	else:
		seq.append({"s": A, "t": "第 23 號擦過。紙面上看得出來。"})
		seq.append({"s": A, "t": "下次劃一條線，簽上名字。不是因為規定——是因為改過的地方，也是紀錄。"})
	seq.append_array([
		{"s": A, "t": "（從口袋裡拿出一個布包）這個給你。%s。" % CAST.MENTOR_GIFT},
		{"s": A, "t": "我第一份量底片的工作，帶我的人給我的。用了三十年，鏡片我自己磨過一次。"},
		{"s": A, "t": "你會說你用不上。普林西比有 Eddington 的儀器。",
			"key": "gift", "choices": ["「我會帶著。」", "「先生，這太貴重了。」"],
			"then": [
				[{"s": A, "t": "好。"}],
				[{"s": A, "t": "貴重的是用它看見的東西。這個只是黃銅。"}],
			]},
		{"s": A, "t": "我還是不信。你知道的。"},
		{"s": A, "t": "可是我希望你帶回來的，是一張讓我不得不信、或者讓他不得不放棄的底片。哪一種都好——只要是乾淨的。"},
		{"s": A, "t": "去看看吧。無論你看見什麼，都把它記下來。"},
	])
	return seq


## Captions over black between departure and Príncipe. Moves the tail of M1's montage here;
## M1 now ends on the 1918 bridge (content_1917.montage()).
static func montage() -> Array:
	return [
		{"t": "1919 年 3 月 8 日，兩支日食隊從利物浦搭船出發。", "tag": "HISTORICAL"},
		{"t": "工作簿最後一頁還是空的。你把它放在箱子的最上層。", "tag": "FICTION"},
		{"t": "歷史上，普林西比的觀測者是 Eddington 與 Cottingham 兩人。你和他們同行——這是虛構的。", "tag": "FICTION"},
		{"t": "1919 年 5 月 29 日・普林西比", "tag": "HISTORICAL"},
	]



## 1919 night phase hook (text only; never alters measurement or score): the workbook's blank page.
static func principe_workbook(bond_tone: String) -> Array:
	var seq: Array = [
		{"s": "", "t": "（工作簿最後一頁。日期是 Kit 的字：1919 年 5 月 29 日。）"},
		{"s": YOU, "t": "（你想了很久，只寫了幾行。）"},
		{"s": "", "t": "「早上下大雨。全食的時候，雲在太陽前面走。有幾秒，雲薄到看得見日冕——像有人在霧後面點了一盞燈。」"},
	]
	if bond_tone == "close":
		seq.append({"s": "", "t": "「你說，要我自己抬頭看。我看了。」"})
	else:
		seq.append({"s": "", "t": "「換底片的空檔，我還是抬頭看了一眼。」"})
	return seq
