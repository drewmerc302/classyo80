# Screenshots

App Store Connect needs one set per required display size. A 6.9" iPhone set and a 13" iPad set
cover every device Apple will ask about for this app; Apple scales them down for smaller hardware.

| Size class | Simulator | Pixels (portrait) | How many |
|---|---|---|---|
| iPhone 6.9" | iPhone 17 Pro Max | 1320 × 2868 | 3 to 10 (required) |
| iPad 13" | iPad Pro 13-inch (M4) | 2064 × 2752 | 3 to 10 (required, because the app supports iPad) |

Landscape iPad shots are allowed at 2752 × 2064 and are worth one slot, since the app stretches
sideways rather than letterboxing.

The existing `docs/screenshots/iphone.png` and `ipad.png` are README illustrations at the wrong
sizes, and they still show the old `MS-80BM` model plate. They cannot be uploaded, and the README
pair wants recapturing too; both come out of the recipe below.

## What to show

Five shots, in this order. The display content comes from the `--keys` launch argument, which
presses keys once at launch (DEBUG builds only, see `ClassyO80App.pressLaunchKeys`). Key names are
the accessibility identifiers without the `key.` prefix: `0`–`9`, `point`, `plus`, `minus`,
`multiply`, `divide`, `equals`, `percent`, `C`, `AC`, `MRC`, `Mplus`, `Mminus`, `MEX`, `COST`,
`SELL`, `MAR`, `plusMinus`, `backspace`, `OFF`.

| # | `--keys` | Shows | Caption idea |
|---|---|---|---|
| 1 | `6 divide 3 multiply 5 plus 2 point 4 minus 1 equals` | 11.4 | "Left to right, like the hardware" |
| 2 | `1 0 0 divide 3 multiply 3 equals` | 99.999999 | "Truncates to 8 digits, never rounds" |
| 3 | `2 3 plus plus 1 2 equals` | 35 with `K` lit | "Constants, on a double-tapped operator" |
| 4 | `5 0 0 COST 7 0 0 SELL MAR` | 28.571428 with `MAR` lit | "COST, SELL, MARGIN" |
| 5 | `1 2 3 4 5 6 7 8 Mplus` | 12'345'678 with `M` lit | "Independent memory" |

## Capturing them

```sh
xcodegen generate

device="iPhone 17 Pro Max"          # then repeat with "iPad Pro 13-inch (M4)"
xcrun simctl boot "$device" || true
xcrun simctl bootstatus "$device"    # waits until it is ready to take a launch
xcodebuild build \
  -project ClassyO80.xcodeproj -scheme ClassyO80 \
  -destination "platform=iOS Simulator,name=$device" \
  -derivedDataPath build/dd
app=build/dd/Build/Products/Debug-iphonesimulator/ClassyO80.app
xcrun simctl install "$device" "$app"

shoot() {                            # shoot <file> <keys...>
  out=$1; shift
  xcrun simctl terminate "$device" com.drewmerc.classyO80 2>/dev/null || true
  xcrun simctl launch "$device" com.drewmerc.classyO80 --uitesting --keys "$*"
  sleep 2
  xcrun simctl io "$device" screenshot --type=png "$out"
}

mkdir -p build/screenshots
shoot build/screenshots/1-chain.png 6 divide 3 multiply 5 plus 2 point 4 minus 1 equals
shoot build/screenshots/2-truncate.png 1 0 0 divide 3 multiply 3 equals
shoot build/screenshots/3-constant.png 2 3 plus plus 1 2 equals
shoot build/screenshots/4-margin.png 5 0 0 COST 7 0 0 SELL MAR
shoot build/screenshots/5-memory.png 1 2 3 4 5 6 7 8 Mplus
```

`--uitesting` sends the run to a throwaway defaults store, so a rate or memory value left over from
earlier play does not show up in a screenshot.

Check the pixel dimensions before uploading — a simulator running in a scaled window still captures
at native resolution, but a mismatched device name silently gives the wrong size:

```sh
for f in build/screenshots/*.png; do echo "$f: $(sips -g pixelWidth -g pixelHeight "$f" | tail -2 | tr -d ' \n')"; done
```

Screenshots live in `build/` (gitignored) rather than in the repo: they are release artefacts, and
uploading them is a one-off per version.
