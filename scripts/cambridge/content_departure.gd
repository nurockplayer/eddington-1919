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
	return L.t("劍橋天文台・1919 年 3 月，出發前一晚\n（重建場景）")


## Played on entering. The blackout curtain is gone; crates by the door.
static func opening() -> Array:
	return [
		{"s": K, "t": L.t("窗簾拆了。整整四年，我第一次在這個房間看見外面的路燈。")},
		{"s": K, "t": L.t("你的茶。糖還是配給的——這一點是我省下來的，不要浪費。")},
		{"s": K, "t": L.t("最後一頁。我念底片上量到的數，你對清單。對完這頁，箱子就可以釘起來了。"),
			"key": "open", "choices": [L.t("「好。」"), L.t("「你省下來的？那你呢？」")],
			"then": [
				[],
				[{"s": K, "t": L.t("我說過了，我喝不慣甜的。")}, {"s": K, "t": L.t("……兩年了，你還在問。快去。")}],
			]},
	]


## Five entries for the last shared check. Coordinates are measuring-machine plate x/y in mm
## (FICTION; deliberately not real star positions). hand: whose handwriting is on the list.
## Exactly one entry (slip) is the player's own transcription slip (transposed digits).
static func check_entries() -> Array:
	return [
		{"id": "s21", "label": L.t("第 21 號"), "list": L.t("x 38.42　y 12.07"), "plate": L.t("x 38.42　y 12.07"), "hand": "kit"},
		{"id": "s22", "label": L.t("第 22 號"), "list": L.t("x 40.15　y 19.88"), "plate": L.t("x 40.15　y 19.88"), "hand": "you"},
		{"id": "s23", "label": L.t("第 23 號"), "list": L.t("x 41.27　y 18.63"), "plate": L.t("x 41.27　y 16.83"), "hand": "you", "slip": true},
		{"id": "s24", "label": L.t("第 24 號"), "list": L.t("x 44.90　y 21.35"), "plate": L.t("x 44.90　y 21.35"), "hand": "kit"},
		{"id": "s25", "label": L.t("第 25 號"), "list": L.t("x 47.06　y 15.52"), "plate": L.t("x 47.06　y 15.52"), "hand": "you"},
	]


## Kit reads each plate value aloud before the player marks it.
static func kit_reads(entry: Dictionary) -> Array:
	return [{"s": K, "t": L.t("%s。%s。") % [entry.label, entry.plate]}]


## After the five marks. caught_by_player: the player marked the slip x themselves.
## false_alarm: the player marked a correct entry x (Kit re-reads it; no penalty).
static func slip_found(caught_by_player: bool, false_alarm: bool) -> Array:
	var seq: Array = []
	if false_alarm:
		seq.append({"s": K, "t": L.t("（又念了一次）……那一行是對的。眼睛累了。沒關係，就是要這樣一行一行對。")})
	if caught_by_player:
		seq.append({"s": K, "t": L.t("你先看到了。十八點六三，十六點八三——兩個數字換了位置。")})
	else:
		seq.append({"s": K, "t": L.t("等等。第 23 號，再念一次：十六點八三。")})
		seq.append({"s": K, "t": L.t("清單上寫的是十八點六三。兩個數字換了位置。")})
	seq.append({"s": K, "t": L.t("（把清單轉過來給你看）……是你的字。")})
	seq.append({"s": YOU, "t": L.t("（兩年前在這張桌子上，你在報告裡寫過：對不上的地方，要寫它對不上。）")})
	seq.append({"s": K, "t": L.t("怎麼改？"),
		"key": "slip_fix", "choices": [L.t("劃一條線，旁邊寫正確的數字，簽上縮寫。"), L.t("擦掉，直接寫上正確的數字。")],
		"then": [
			[{"s": K, "t": L.t("（看你簽名）好。以後拿到這張紙的人，看得出這裡改過，也看得出是誰改的。")}],
			[{"s": K, "t": L.t("……乾淨多了。")}, {"s": K, "t": L.t("只是，到了那邊，如果有人問這個數字是從哪裡來的——你記得是你改的。紙不記得。")}],
		]})
	seq.append({"s": K, "t": L.t("兩年，一千多行，錯一行。我量變星的時候，一個晚上就不只錯一行了。")})
	return seq


## Small acts of care. Any one choice sets Story.bond_tone; it only colours later lines.
## Index 0 → "close", 1 and 2 → "warm". Never a score.
static func before_closing() -> Array:
	return [
		{"s": "", "t": L.t("（你的鉛筆削好了，排在清單旁邊。不是你削的。）")},
		{"s": K, "t": L.t("箱子明天早上六點來搬。我叫了推車。")},
		{"s": K, "t": L.t("所以……今晚沒有別的事了。"),
			"key": "bond", "choices": [L.t("「那再坐一下。」"), L.t("「我來收拾。」"), L.t("「你連推車都叫好了，那我呢？也要釘進箱子裡？」")],
			"then": [
				[{"s": K, "t": L.t("（把椅子拉近看片台。沒有說話。燈光底下，兩個人的影子落在同一張底片上。）")}],
				[{"s": "", "t": L.t("（和 Kit 一起把底片收進木框，一格一格，誰也沒說話。）")}, {"s": K, "t": L.t("……好了。比我一個人快一倍。")}],
				[{"s": K, "t": L.t("如果釘得進去的話。")}, {"s": K, "t": L.t("……別讓我想像那個畫面。")}],
			]},
	]


## The sky-sharing promise. bond_tone: "close" | "warm". No confession on any route.
static func sky_promise(bond_tone: String) -> Array:
	var seq: Array = [
		{"s": K, "t": L.t("到了那邊，記得告訴我天空是什麼樣子。")},
		{"s": K, "t": L.t("不是底片上的。是你自己抬頭看到的。"),
			"key": "promise", "choices": [L.t("「那你也得告訴我，這裡有什麼變了。」"), L.t("「全食只有五分鐘，我會在換底片。」")],
			"then": [
				[{"s": K, "t": L.t("這裡？（笑）這裡什麼都不會變。")}, {"s": K, "t": L.t("……好。我寫。")}],
				[{"s": K, "t": L.t("那就在五分鐘之前，或是之後。")}, {"s": K, "t": L.t("那裡的天空也有晚上。我會問你。")}],
			]},
		{"s": K, "t": L.t("（翻開工作簿，最後面有一頁是空的。上面已經寫好了日期：1919 年 5 月 29 日。）"), "key": "workbook"},
		{"s": K, "t": L.t("那裡看到的，記在這裡。回來的時候，我要看。")},
	]
	if bond_tone == "close":
		seq.append({"s": K, "t": L.t("還有——")})
		seq.append({"s": "", "t": L.t("（Kit 停了很久。）")})
		seq.append({"s": K, "t": L.t("……你的鉛筆。記得帶。")})
	else:
		seq.append({"s": K, "t": L.t("還有你的鉛筆。上次你借走我三枝。")})
	return seq


## Ashby, alone, in the corridor. Gift = CAST.MENTOR_GIFT (placeholder type; never claimed real).
## slip_fix: 0 = struck and initialled, 1 = overwritten (Ashby has seen the last page).
static func mentor_farewell(slip_fix: int) -> Array:
	var seq: Array = [
		{"s": A, "t": L.t("清單我看過了。最後一頁也看了。")},
	]
	if slip_fix == 0:
		seq.append({"s": A, "t": L.t("第 23 號劃了一條線，旁邊簽了名。兩年前你還不會這樣做。")})
	else:
		seq.append({"s": A, "t": L.t("第 23 號擦過。紙面上看得出來。")})
		seq.append({"s": A, "t": L.t("下次劃一條線，簽上名字。不是因為規定——是因為改過的地方，也是紀錄。")})
	seq.append_array([
		{"s": A, "t": L.t("（從口袋裡拿出一個布包）這個給你。%s。") % L.t(CAST.MENTOR_GIFT)},
		{"s": A, "t": L.t("我第一份量底片的工作，帶我的人給我的。用了三十年，鏡片我自己磨過一次。")},
		{"s": A, "t": L.t("你會說你用不上。普林西比有 Eddington 的儀器。"),
			"key": "gift", "choices": [L.t("「我會帶著。」"), L.t("「先生，這太貴重了。」")],
			"then": [
				[{"s": A, "t": L.t("好。")}],
				[{"s": A, "t": L.t("貴重的是用它看見的東西。這個只是黃銅。")}],
			]},
		# Issue #37 loop 3 (proposal): the closed box again, now with light. FICTION: Ashby's own
		# working. Physics: relative to an accelerating box, a light ray lands lower on the far wall;
		# across a room the drop is far smaller than an atom, so no real box could show it.
		{"s": A, "t": L.t("Eddington 那個箱子，我後來又想了一次。這回在一面牆上開個小洞，讓一道光照進去。")},
	])
	return seq


## Conversion arc move E (FICTION): the light in the box, played by hand in the sketch.
static func mentor_farewell_after() -> Array:
	return [
		{"s": A, "t": L.t("箱子越走越快，光還沒到對面，地板已經迎上來了。光落在對面牆上的點，會比洞低一點。箱子裡的人看來——光彎了。")},
		{"s": A, "t": L.t("低多少？一個房間那麼寬，比一個原子還小得多。誰也看不見。"),
			"key": "light_box", "choices": [L.t("「所以要用太陽。」"), L.t("「那就只是想像。」")],
			"then": [
				[{"s": A, "t": L.t("對。要一個重得多的東西——太陽。讓星光擦著它的邊走過去。")}],
				[{"s": A, "t": L.t("到今天為止，是。所以你要去量。")}],
			]},
		{"s": A, "t": L.t("我還是不信。你知道的。")},
		{"s": A, "t": L.t("可是我希望你帶回來的，是一張讓我不得不信、或者讓他不得不放棄的底片。哪一種都好——只要是乾淨的。")},
		{"s": A, "t": L.t("去看看吧。無論你看見什麼，都把它記下來。")},
	]


## Captions over black between departure and Príncipe. Moves the tail of M1's montage here;
## M1 now ends on the 1918 bridge (content_1917.montage()).
static func montage() -> Array:
	return [
		{"t": L.t("1919 年 3 月 8 日，兩支日食隊從利物浦搭船出發。"), "tag": "HISTORICAL"},
		{"t": L.t("工作簿最後一頁還是空的。你把它放在箱子的最上層。"), "tag": "FICTION"},
		{"t": L.t("歷史上，普林西比的觀測者是 Eddington 與 Cottingham 兩人。你和他們同行——這是虛構的。"), "tag": "FICTION"},
		{"t": L.t("1919 年 5 月 29 日・普林西比"), "tag": "HISTORICAL"},
	]



## 1919 night phase hook (text only; never alters measurement or score): the workbook's blank page.
## plates: the run's developed plates (EclipseSim.plates); plate_changed: a plate change
## was actually made. The page says only what the run's exposures saw, read from
## Cottingham's band on each plate the player closed (brief or unread plates say nothing
## about the sky).
static func principe_workbook(bond_tone: String, plates: Array, plate_changed: bool) -> Array:
	var bands: Array = plates.map(func(p): return p.get("sky_read", ""))
	var sky := L.t("「早上下大雨。全食的時候，雲在太陽前面走。")
	if "clear" in bands:
		sky += L.t("有幾秒，雲薄到看得見日冕——像有人在霧後面點了一盞燈。」")
	elif "mixed" in bands:
		sky += L.t("有一陣，雲裂開一半，透出一點光。」")
	elif "cloud" in bands and bands.all(func(b): return b == "cloud"):
		sky += L.t("我們拍的每一張，都在雲後面。」")
	elif "cloud" in bands:
		sky += L.t("Cottingham 看過的那幾張，都在雲後面；其餘的，我說不上來。」")
	elif not plates.is_empty():
		sky += L.tn("底片拍了 %d 張，我不知道上面會留下什麼。」", plates.size()) % plates.size()
	else:
		sky += L.t("我一張底片也沒有拍成。」")
	var seq: Array = [
		{"s": "", "t": L.t("（工作簿最後一頁。日期是 Kit 的字：1919 年 5 月 29 日。）")},
		{"s": YOU, "t": L.t("（你想了很久，只寫了幾行。）")},
		{"s": "", "t": sky},
	]
	if bond_tone == "close":
		seq.append({"s": "", "t": L.t("「你說，要我自己抬頭看。我看了。」")})
	elif plate_changed:
		seq.append({"s": "", "t": L.t("「換底片的空檔，我還是抬頭看了一眼。」")})
	else:
		seq.append({"s": "", "t": L.t("「我抬頭看了很久。」")})
	return seq
