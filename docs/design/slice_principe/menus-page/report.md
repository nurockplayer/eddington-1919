# Menus on the engraved page

Code candidate: `3cbe66f9b9884ce9942543510996fe2d960e2499`.
Captured: 2026-11-22 00:44 JST.

Seed 7; windowed 1280×720, fixed 60 fps; project canvas and stretch settings unchanged. Every screen has its opening focus. Options are opened from title; pause/help/history from camp; ending uses the real run record. The English default set includes pause after the native second-contact transition.

Sheets: `sheet-en.jpg`, `sheet-ja.jpg`, `sheet-zh_TW.jpg`, `sheet-ko.jpg`. Each tile and native JPEG is named `<locale>_<default|max>_<screen>`. Maximum text size is 1.2. Focus uses reversed ink and a heavier rule.

Contrast uses the darkest and lightest repeated solid pixels (at least three occurrences) inside the recorded body/focused-text rectangles in `frames.json`, before JPEG encoding. Antialias edge coverage is excluded; RGB samples and ratios are retained below. Credits body rows were corrected from the first 200 visible pixels of the native JPEGs after discovering the original scrolling label crop included off-frame black padding. All other measurements retain their original lossless frame samples; the lossless scratch has been deleted.

| Frame | Body | Focused row | Body RGB (ink/paper) | Focus RGB (ink/paper) |
|---|---:|---:|---|---|
| en_default_title | 13.41:1 | 11.30:1 | (35, 29, 25)/(239, 230, 210) | (34, 28, 24)/(219, 211, 192) |
| en_default_options | 13.56:1 | 9.63:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(204, 195, 178) |
| en_default_credits | 12.89:1 | 9.12:1 | (46, 38, 27)/(246, 238, 219) | (34, 28, 24)/(198, 190, 173) |
| en_default_pause | 13.56:1 | 10.56:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(213, 204, 186) |
| en_default_help | 13.41:1 | 9.12:1 | (35, 29, 25)/(239, 230, 210) | (34, 28, 24)/(198, 190, 173) |
| en_default_history | 13.56:1 | 12.12:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(227, 218, 199) |
| en_default_pause_totality | 13.56:1 | 10.56:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(213, 204, 186) |
| en_default_ending | 13.56:1 | 13.32:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(237, 228, 208) |
| en_max_title | 13.41:1 | 13.07:1 | (35, 29, 25)/(239, 230, 210) | (34, 28, 24)/(235, 226, 206) |
| en_max_options | 13.56:1 | 13.44:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(238, 229, 209) |
| en_max_credits | 14.59:1 | 12.36:1 | (33, 28, 24)/(246, 238, 217) | (34, 28, 24)/(229, 220, 201) |
| en_max_pause | 13.56:1 | 12.95:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(234, 225, 205) |
| en_max_help | 13.56:1 | 12.36:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(229, 220, 201) |
| en_max_history | 13.56:1 | 13.19:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(236, 227, 207) |
| en_max_ending | 13.56:1 | 13.07:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(235, 226, 206) |
| ja_default_title | 12.97:1 | 12.59:1 | (38, 32, 27)/(239, 230, 210) | (34, 28, 24)/(231, 222, 202) |
| ja_default_options | 13.56:1 | 9.43:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(202, 193, 176) |
| ja_default_credits | 11.78:1 | 9.24:1 | (51, 44, 38)/(245, 237, 218) | (34, 28, 24)/(200, 191, 175) |
| ja_default_pause | 13.56:1 | 10.67:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(214, 205, 187) |
| ja_default_help | 13.41:1 | 9.24:1 | (35, 29, 25)/(239, 230, 210) | (34, 28, 24)/(200, 191, 175) |
| ja_default_history | 13.41:1 | 8.54:1 | (35, 29, 25)/(239, 230, 210) | (34, 28, 24)/(192, 184, 167) |
| ja_default_ending | 13.56:1 | 11.89:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(225, 216, 197) |
| ja_max_title | 13.41:1 | 13.19:1 | (35, 29, 25)/(239, 230, 210) | (34, 28, 24)/(236, 227, 207) |
| ja_max_options | 13.56:1 | 13.44:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(238, 229, 209) |
| ja_max_credits | 14.08:1 | 12.83:1 | (37, 30, 24)/(245, 237, 216) | (34, 28, 24)/(233, 224, 204) |
| ja_max_pause | 13.56:1 | 12.01:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(226, 217, 198) |
| ja_max_help | 13.41:1 | 12.83:1 | (35, 29, 25)/(239, 230, 210) | (34, 28, 24)/(233, 224, 204) |
| ja_max_history | 13.56:1 | 13.07:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(235, 226, 206) |
| ja_max_ending | 13.56:1 | 13.08:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(235, 226, 207) |
| zh_TW_default_title | 13.56:1 | 13.07:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(235, 226, 206) |
| zh_TW_default_options | 13.56:1 | 10.65:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(213, 205, 187) |
| zh_TW_default_credits | 13.53:1 | 10.78:1 | (42, 33, 26)/(245, 237, 218) | (34, 28, 24)/(215, 206, 188) |
| zh_TW_default_pause | 13.56:1 | 10.65:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(213, 205, 187) |
| zh_TW_default_help | 13.41:1 | 10.78:1 | (35, 29, 25)/(239, 230, 210) | (34, 28, 24)/(215, 206, 188) |
| zh_TW_default_history | 13.41:1 | 8.54:1 | (35, 29, 25)/(239, 230, 210) | (34, 28, 24)/(192, 184, 167) |
| zh_TW_default_ending | 13.56:1 | 12.01:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(226, 217, 198) |
| ko_default_title | 13.56:1 | 13.56:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(239, 230, 210) |
| ko_default_options | 13.56:1 | 12.24:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(228, 219, 200) |
| ko_default_credits | 13.94:1 | 9.33:1 | (38, 31, 23)/(245, 237, 216) | (34, 28, 24)/(201, 192, 175) |
| ko_default_pause | 13.56:1 | 9.43:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(202, 193, 176) |
| ko_default_help | 13.41:1 | 9.33:1 | (35, 29, 25)/(239, 230, 210) | (34, 28, 24)/(201, 192, 175) |
| ko_default_history | 13.11:1 | 11.86:1 | (37, 31, 27)/(239, 230, 210) | (34, 28, 24)/(224, 216, 197) |
| ko_default_ending | 13.56:1 | 13.08:1 | (34, 28, 24)/(239, 230, 210) | (34, 28, 24)/(235, 226, 207) |
