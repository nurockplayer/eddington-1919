# 雲層之後（工作標題） · Eddington 1919

**Godot 3D 歷史懸疑冒險遊戲原型**。背景是 1919 年 5 月 29 日的日食觀測；玩家作為虛構觀測助手，在有限時間、天候與不完整證據中行動和判斷。

> 狀態：**第一個可玩切片已完成（v0.1，2026-10-19）**。可以從頭玩到結局，也可以重玩。完整流程已用自動化輸入走過，**真人試玩尚未進行**。詳見 [試玩紀錄](docs/PLAYTEST.md)。正式遊戲名稱尚未決定。

## 怎麼玩（Godot 4.7.2）

```bash
# 從原始碼直接執行（需要 Godot 4.7.2 stable）
godot --path .
# 匯出 macOS 版（需要 4.7.2 匯出範本）→ build/Eddington1919-macOS.zip
godot --headless --path . --export-release "macOS" build/Eddington1919-macOS.zip
# 邏輯測試（無視窗）
godot --headless --path . --script res://tests/test_sim.gd
# 自動化走完整流程並截圖（不能取代真人試玩）
godot --path . --always-on-top -- --autoplay=careful --shots=/tmp/e1919 --speed=2
```

主選單第一個按鈕「序章　劍橋，1917」進入 M1：比對底片與抄錄圖、查日誌、請 Kit 獨立複核、填報告並共同規劃公平的日食觀測，再接 M2 出發前夜：逐行核對清單、留下更正痕跡、與 Kit 約定記下天空，走到走廊向 Ashby 告別後進入 1919 準備階段（[M2 驗證](docs/M2_VERIFICATION.md)）。M3 接上普林西比暗房的工作簿、放大鏡與熄燈收尾，結局先呈現電報、回應與證據，歷史紀錄可展開閱讀（[M3 驗證](docs/M3_VERIFICATION.md)）。「普林西比，1919」仍可直接開始既有切片。序章台詞由 Game Director 撰寫（人物名 Kit、Ashby 為暫定名）。尚未真人試玩；M1 的 12–18 分鐘、M2 的 6–9 分鐘均為設計目標，並非已測量遊玩時長。新手試玩方法見 [docs/PLAYTEST_NEWCOMER.md](docs/PLAYTEST_NEWCOMER.md)。

序章額外操作：看片台內拖曳描圖紙、翻面、Q／E 或按鈕旋轉；Tab 在兩章都可開關最近 60 行對話紀錄。

```bash
godot --headless --path . --script res://tests/test_prologue.gd
godot --path . --always-on-top -- --prologue-autoplay=honest --shots=/tmp/m1-honest
# 另有 tidy、accuse 兩種報告路線；JSON 收據與逐幕截圖寫到 --shots 目錄。
```

**流程（約 6–10 分鐘）**
1. 準備：在 Roça Sundy 觀測站向 Eddington 報到，從暗房搬底片匣，再幫 Cottingham 上發條、對天文鐘校走速。倒數在對話時暫停。
2. 全食（302 秒，時間壓縮）：抬頭看漂移的雲，按空白鍵喊「開始」或「停」。雲在太陽上的厚薄，就是底片實際收到的光。
3. 夜晚：在暗房檢視沖洗出來的底片，看星點數、雲霧和星像拖線。先決定要量哪幾張，再看數值。
4. 判斷：選一封電報和一個理由，Eddington 會依你的證據和選片方式回應。結局附上史實對照，可以用同一片雲或新的天空重玩。

操作：WASD 移動、滑鼠或方向鍵觀看、Shift 跑、E 互動（按住＝持續動作）、空白鍵／E／左鍵 在全食時喊開始或停、Esc 暫停。

## 已確定的方向（Owner，2026-10-19 JST）

- 使用 **Godot** 製作可實際操作的 **3D 歷史冒險**；原生桌面建置優先。具體 Godot 穩定版本與內部實作由 Game Director 選擇並記錄。
- **單人優先**；長期希望能選擇 **1–4 人合作**，但第一個原型**不要求連線**，也不預建多人伺服器。
- 表面必須先是一款有意思的冒險／懸疑／人物遊戲；科學方法與跨時代主題透過行動、證據和角色自然浮現，避免教科書式問答。
- 首個可玩切片：可控制角色／鏡頭在一小塊 **3D 觀測環境**探索；觀察、與人物互動、執行一項有後果的觀測操作；在後續分析環節查看不同品質的證據並作出有理由的判斷。**玩法設計由 Opus 5.5 主導，參考而不照抄先前提案。**
- 尊重史實與真實人物，不把後人已知答案塞給當時角色，也不為戲劇張力抹黑歷史人物。必要虛構（玩家、台詞、事故、設備故障）需與可考史料區分。
- 不要在這裡實作《沒有名字的病》Web 原型；它在 [nurockplayer/unnamed-disease](https://github.com/nurockplayer/unnamed-disease) 由既有開發線繼續完成。

## 重要入口

- [Game Director Handoff](docs/HANDOFF.md)：接手、里程碑與真正可玩證據的回報約定。
- [1919 歷史背景與查核邊界](docs/HISTORY_1919.md)：用於創作的史料錨點、事實與虛構界線。
- [決策紀錄](docs/DECISIONS.md)：Owner 已定方向與 Game Director 可自行調整的選擇。
- [素材溯源](docs/PROVENANCE.md)：遊戲中每項史實、重建與虛構的標記和來源。
- [試玩紀錄](docs/PLAYTEST.md)：實際測過什麼、沒測過什麼。
- [美術聖經 Art Bible](art/BIBLE.md) 與 [美術管線](art/PIPELINE.md)：視覺方向、快速生圖→Blender→Godot 驗收閉環、提示詞與素材紀錄。
- [先前 Notion 的日食互動切片草案](https://app.notion.com/p/3fdd7d8b39078183a159e6bd58fc0b7e)：**僅為舊提案**；其中「固定 2D 視角」「原型必做 Hub」「底片一律數日後沖洗」等項目**不構成新需求**，且需依史料修正。
- [系列構想整理](https://app.notion.com/p/3f9d7d8b390781ec8049f6533b1760b4)：長期歷史題材版圖／尚未批准的構想混合資料。

## 開發與驗收

由 **Opus 5.5 擔任 Game Director**，自行決定玩法、素材、場景、腳本架構、工作拆分與驗證策略；Sol/Codex 可協助，獨立審查可核對實際玩法與史實。避免因文件過長或過度設計而延遲第一個真正能玩的 Godot 場景。

至少應保留：實際啟動指令／Godot 版本、可玩的場景或匯出建置、玩家操作 → 證據變化 → 判斷與回應的閉環、可重玩路徑，以及 GitHub 上有連結的測試／試玩證據。**程式能建置不等於遊戲已經好玩。**

不強制建立 `CLAUDE.md` 或 `AGENTS.md`；需要時由 Game Director 自行判斷。亦不為第一段切片預先建置時空大地圖、通用 RPG 系統、帳號或 MMO 基礎設施。
