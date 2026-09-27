# Classy-O 80

iPhone/iPad replica of the Casio MS-80BM, shipped as Classy-O 80. See README.md for layout
and commands.

## Rules

- Behavior changes start in `docs/SPEC.md` and a failing test in `Packages/CalcEngine/Tests`,
  then the engine change. The manual outranks the spec; the spec outranks memory of how
  "calculators usually work".
- The manual is Casio's and is not in this repo. Fetch it from Casio's support site and keep it
  outside the working tree. `ManualExamplesTests.swift` is the checked-in record of every example it
  contains — when the manual is not to hand, that file is the next best authority.
- Every manual example lives in `ManualExamplesTests.swift`. Never weaken one to make a change pass.
- Keep the engine free of UI and platform code. The app only maps touches to `Key` and renders
  `Display`.
- Results truncate to 8 digits (the `100 C2 C3` = 83.202212 example depends on it). Use
  `Numeric.fit`, never `rounded`.
- Regenerate the Xcode project with `xcodegen generate` after adding files; the `.xcodeproj` is
  gitignored.
- The shipping product is **Classy-O 80**: that is the target, the module, the scheme, the bundle
  ID and the Home Screen name. `Panel.brandName` and `Panel.modelName` are ours too.
- Four places name the hardware, on purpose, because provenance has to live somewhere: this file,
  `README.md`, the source-of-truth line in `docs/SPEC.md`, and the header of
  `ManualExamplesTests.swift`. Nowhere else — not in source comments, not in the App Store listing,
  not in an identifier or a path.
- New stored or transmitted data changes three files together: `ClassyO80/PrivacyInfo.xcprivacy`,
  the privacy answers in `docs/appstore/listing.md`, and `docs/privacy.md`.

## Commands

- Engine tests: `cd Packages/CalcEngine && swift test`
- App build/test: `xcodegen generate && xcodebuild test -project ClassyO80.xcodeproj -scheme ClassyO80 -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- Release build: `Scripts/release.sh` (add `--upload` to send it to App Store Connect). Checklist in
  `docs/RELEASE.md`.
