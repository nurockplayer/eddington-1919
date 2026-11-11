# Steam depots, upload, Auto-Cloud and the wait from fee to release (B1, B2, B9)

edd-lead, 2026-11-12 04:5x JST. Compiled from one oracle-ego round, then each Steam fact below was checked by the lead against the live Steamworks page named beside it (`partner.steamgames.com/doc/...`, read 2026-11-12 04:5x JST).

**Nothing here has been tried on Steam: there is no App ID yet (B1).** Every ID is a placeholder. Items marked *unverified* are not stated on the pages read and need a test once an App ID exists.

## 1. What the release ZIPs hold today

Listed from the 0.4.6 ZIPs (`tools/export_release.sh`, KIOXIA `eddington/builds/0.4.6/`):

| Platform | In the ZIP | For Steam |
|---|---|---|
| Windows | `Eddington1919-0.4.6-Windows.exe`, `Eddington1919-0.4.6-Windows.pck` | The names carry the version, and a launch option must not change with each build: rename the pair to `Eddington1919.exe` and `Eddington1919.pck` when staging (Godot loads the `.pck` that shares the executable's base name) |
| macOS | `雲層之後 · Eddington 1919.app` (universal; ad-hoc signed, `codesign/codesign=1`; `notarization/notarization=0`); the `.pck` is inside `Contents/Resources/` | Rename the bundle to `Eddington1919.app` when staging so the launch option is plain ASCII. See section 5 for notarization |
| Linux | `Eddington1919.x86_64`, `Eddington1919.pck` | As is; set the executable bit after unpacking |

The three `.pck` files are the same size (27,288,344 bytes), but the macOS one has to sit inside the bundle, so a shared content depot would save 27 MB at the cost of a different layout per platform. Not worth it for a first release.

## 2. Depots and launch options

Three depots, one per OS, each holding the complete build (`/doc/store/application/depots`: platform-specific content goes in a depot marked for that OS). Language stays `[All Languages]`: the four languages ship in one `.pck`.

| Depot | Placeholder ID | OS | Content at the depot root | Launch option (Installation > General) |
|---|---|---|---|---|
| Windows | `1234561` | Windows | `Eddington1919.exe`, `Eddington1919.pck` | `Eddington1919.exe`, OS Windows |
| macOS | `1234562` | macOS | `Eddington1919.app/` | `Eddington1919.app`, OS macOS |
| Linux | `1234563` | Linux + SteamOS | `Eddington1919.x86_64`, `Eddington1919.pck` | `Eddington1919.x86_64`, OS Linux |

- macOS: `/doc/sdk/uploading` says an app may be launched by its bundle or by the binary inside it, and prefers the bundle.
- A package that lacks a depot for an OS ticked on the store page shows a warning on the app landing page, and owners cannot download on that OS. Each depot must be added to the store package and to the developer (autogrant) package.
- Order of work from `/doc/store/application/platforms`: create the depots, upload a build, set it live on a password-protected beta branch, test on each OS, and only at release tick the OS boxes under Supported Operating Systems and move the build to the default branch.

## 3. Staging and upload (SteamPipe)

```
steam-upload/
  scripts/   app_build.vdf  depot_windows.vdf  depot_macos.vdf  depot_linux.vdf
  content/   windows/  macos/  linux/     (unpacked ZIPs, renamed as in section 1)
  output/    (build logs and cache)
```

Stage the unpacked files, not the ZIPs. Unpack the macOS ZIP with `ditto -x -k` so the bundle's modes and signature survive; after unpacking Linux run `chmod +x content/linux/Eddington1919.x86_64`.

`scripts/app_build.vdf`:

```
"AppBuild"
{
	"AppID" "1234560"
	"Desc" "Eddington 1919 <version> <git sha>"
	"ContentRoot" "../content"
	"BuildOutput" "../output"
	"Depots"
	{
		"1234561" "depot_windows.vdf"
		"1234562" "depot_macos.vdf"
		"1234563" "depot_linux.vdf"
	}
}
```

`scripts/depot_windows.vdf` (the macOS and Linux files differ only in `DepotID` and in `macos/*` or `linux/*`):

```
"DepotBuild"
{
	"DepotID" "1234561"
	"FileMapping"
	{
		"LocalPath" "windows/*"
		"DepotPath" "."
		"Recursive" "1"
	}
}
```

Upload: `steamcmd +login <build account> +run_app_build <absolute path>/scripts/app_build.vdf +quit`. The keys and the relative `ContentRoot` and `LocalPath` follow the examples on `/doc/sdk/uploading`. Without a `SetLive` key the build is uploaded but goes live on no branch; set it on the beta branch by hand in Steamworks. Never put `"SetLive" "default"` in the script.

## 4. Steam Auto-Cloud: `checkpoint.save` only

No Steamworks SDK is needed: Auto-Cloud syncs the named files when the game launches and when it exits (`/doc/features/cloud`).

`project.godot` sets `config/use_custom_user_dir=true` and `config/custom_user_dir_name="Eddington1919"`, so `user://` is:

| OS | `user://` | Auto-Cloud root | Subdirectory | Pattern |
|---|---|---|---|---|
| Windows | `%APPDATA%\Eddington1919` | `WinAppDataRoaming` (`%USERPROFILE%\AppData\Roaming\`) | `Eddington1919` | `checkpoint.save` |
| macOS | `~/Library/Application Support/Eddington1919` | `MacAppSupport` (`~/Library/Application Support/`) | `Eddington1919` | `checkpoint.save` |
| Linux | `$XDG_DATA_HOME/Eddington1919`, by default `~/.local/share/Eddington1919` | `LinuxXdgDataHome` (`$XDG_DATA_HOME/`) | `Eddington1919` | `checkpoint.save` |

The root names and their paths are from the table on `/doc/features/cloud`. The `user://` paths are Godot's documented ones for a custom user dir (`docs.godotengine.org`, "File paths in Godot projects"); the macOS one is confirmed on this Mac, the Windows and Linux ones are still to be read from a packaged run.

Settings to enter (Steamworks > Cloud):

```
Byte quota per user        10485760   (10 MiB; the lead's choice, Valve only asks for "reasonable")
Number of files allowed    10

Auto-Cloud root path
  Root            WinAppDataRoaming
  Subdirectory    Eddington1919
  Pattern         checkpoint.save
  OS              [Cross-Platform]
  Recursive       off

Root overrides
  WinAppDataRoaming -> macOS -> MacAppSupport       Add/Replace Path empty, Replace Path off
  WinAppDataRoaming -> Linux -> LinuxXdgDataHome    Add/Replace Path empty, Replace Path off
```

- One cross-platform root plus overrides, not three OS-restricted roots: the page says files saved under an OS-restricted root are locked to that OS and will not sync to the others, and that overrides require `[Cross-Platform]` on the root.
- The subdirectory is `Eddington1919` on all three systems, so the overrides change only the root. (The page's Unity example needs Add/Replace Path because Unity's directory differs per OS; ours does not.) Check the path preview in Steamworks before publishing.
- `settings.cfg` does not sync: the pattern is the exact file name and Recursive is off. The page says to keep machine-specific settings such as video quality out of the Cloud. The test file `checkpoint.test.save` does not match either.
- Steam writes `steam_autocloud.vdf` into the directory; the game ignores it.

Things to test once an App ID exists (all *unverified* until then):

1. Save on Windows, continue on macOS and on native Linux, and back.
2. Proton: a player who forces the Windows build on Linux or Deck saves inside the Proton prefix, not in `~/.local/share`. Whether that copy syncs with the native one is not stated on the pages read.
3. A checkpoint written while Steam is offline, then a newer one from another machine: see which copy Steam offers. The page does not say which wins.
4. Steam Deck suspend: Auto-Cloud uploads at exit, not at suspend. Dynamic Cloud Sync covers suspend but needs API support in the game, so it stays off.

The page's test procedure for an app in developer-only Cloud mode: open `steam://open/console`, enter `testappcloudpaths <AppID>` and `set_spew_level 4 4`, play, save, exit, check a second machine; end with `testappcloudpaths 0` and `set_spew_level 0 0`.

## 5. macOS: Valve's page requires notarization (open, the Owner's call)

`/doc/store/application/platforms`: "Starting October 14th, 2019 Steam will require all new macOS Applications to be 64-bit and notarized by Apple." In Steamworks, tick "macOS -> 64 Bit Binaries Included" (true for our universal build) and, once notarized, "App Bundles Are Notarized".

Where the project stands: the bundle is universal 64-bit, ad-hoc signed and not notarized. The 2026-11-07 plan (B2) was to check a real Steam install first and pay Apple only if that failed. That plan was made without this page. The build review also requires that the product "successfully launch in all supported operating systems listed on the store page" (`/doc/store/review_process`).

Notarization needs a Developer ID certificate, which needs the paid Apple Developer Program (US$99 a year at the time of writing; Apple's price, not from a Steam page). That is money, so it is the Owner's decision:

| Option | What it costs | Risk |
|---|---|---|
| A. Join the Apple Developer Program, sign with Developer ID, notarize and staple | The yearly fee; one export-preset change and a signing step on this Mac | None against Valve's stated rule |
| B. Keep the 2026-11-07 plan: test an un-notarized build from a real Steam install, pay only if it fails | Nothing up front | The build goes to review against a written requirement it does not meet; a failure costs a review round (3–5 business days) late in the schedule |
| C. Launch on Windows and Linux, add macOS later | Nothing | macOS players wait; the store page and depots change again later |

Lead's recommendation: A, decided before the store page lists macOS. Until the Owner answers, engineering assumes B and macOS stays in scope.

If the build is notarized it runs under the hardened runtime, and the page lists two entitlements for the Steam overlay: `com.apple.security.cs.disable-library-validation` and `com.apple.security.cs.allow-dyld-environment-variables`. `com.apple.security.app-sandbox` must stay off: Steam is not compatible with it.

## 6. Linux and Steam Deck

- Executable bit: set it on `Eddington1919.x86_64` before upload (section 3).
- Linux Runtime (`/doc/store/application/platforms/linux`): a native title may pick a Steam Linux Runtime version per branch under Installation > Linux Runtime, once a Linux launch option exists; the page says the runtime must match the SDK the executable was compiled with. Godot's stock export template is not built with a Steam SDK. *Unverified*: which runtime to pick; test the Steam-installed build on the default setting first.
- No Steam Deck claim (B2 and section 9 of `STORE_PAGE.md`). Valve's compatibility review is separate from the release review and does not gate release. For later reference, Verified needs (`/doc/steamhardware/compat`): all content reachable with the default controller configuration; glyphs that match the active input, with no mouse or keyboard glyphs while a controller is in use; an on-screen keyboard wherever text is typed; 1280x800 or 1280x720 supported; the smallest text at least 9 px tall at 1280x800; 30 fps at 800p on default settings; any launcher fully usable with a controller (the game has none).

## 7. From the fee to release: Valve's stated waits

| Step | Valve's stated time | Page |
|---|---|---|
| Steam Direct fee | US$100 per app, not refundable, recouped once the app passes US$1,000 adjusted gross revenue | `/doc/gettingstarted/appfee` |
| Fee to release | **21 days** from paying the fee before that game can release | `/doc/gettingstarted/onboarding` |
| Tax information check | up to 30 days, by a third party; more documents may be asked for | same page |
| Store page review | typically 3–5 business days; submit at least 7 business days before the page should be live | `/doc/store/review_process` |
| Coming Soon | must be public for at least two weeks before release; "Post as Coming Soon" is pressed by hand after approval | `/doc/store/coming_soon` |
| Build review | typically 3–5 business days, plan 7; the store page must be submitted before the build can be; a near-final build is expected | `/doc/store/review_process`, `/doc/store/releasing` |
| Trailer | required for release; the game cannot be released while a trailer is converting | `/doc/store/trailer` |
| Release | by hand: Release App > Publish Now > Release Now. The account needs "Publish app changes to Steam" and "Manage pricing and discounts" | `/doc/store/releasing` |

The oracle-ego reply first gave 30 days for the fee wait and then corrected itself to 21; the Onboarding page read directly says 21. The store review also checks that the page shows only content that exists at launch, that capsules carry a readable title, and that screenshots are gameplay only.

What can run in parallel: everything in the project (art, trailer, exports, tests) runs during the fee wait and the tax check. On Steam, the store page, depots and Cloud settings need the App ID, which exists only after B1. *Unverified*: whether a pending tax check blocks building the store page.

Dates for the proposed 2027-01-12 release (B4: Coming Soon up 28 days or more). These are the lead's arithmetic from the waits above, not Valve's promises:

| By | What |
|---|---|
| Fri 2026-12-04 | Store page submitted for review (7 business days before 2026-12-15). Needs the App ID, capsules, 5 screenshots, four-language text, content survey (B6) |
| Tue 2026-12-15 | Coming Soon posted: 28 days before release, the project's own rule |
| Tue 2026-12-22 | Latest day to pay the fee for the 21-day wait alone; in practice the fee comes first, since the App ID follows it |
| Tue 2026-12-29 | Valve's hard minimum: Coming Soon posted 14 days before release |
| Mon 2026-12-21 | Build submitted for review and trailer uploaded, ahead of the year-end holidays. The bare minimum of 7 business days before release would be 2026-12-31 |
| Tue 2027-01-12 | Release by hand |

B1 has been waiting on the Owner since 2026-11-07 08:34 JST. If the paperwork and tax check take their full 30 days from today, the App ID arrives about 2026-12-12, the store page cannot be reviewed before about 2026-12-23, and under the 28-day rule the release moves to the first Tuesday on or after 2027-01-20, which is 2027-01-26. From here each further week before B1 moves the release by about a week.
