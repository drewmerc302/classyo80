# Releasing to the App Store

Everything needed for a submission that lives in this repo is in place. What is left is the work
that can only happen on a Mac with Xcode and in App Store Connect, listed under
[Before the first submission](#before-the-first-submission).

The app ships as **Classy-O 80**. It is a replica of hardware Casio designed, and it deliberately
carries none of Casio's marks: the panel wordmark is `CLASSY-O` (`Panel.brandName`), the model
plate is `CO-80BM` (`Panel.modelName`), and the Home Screen name is `Classy-O 80`. Keep it that way
— see [Intellectual property](#intellectual-property).

## What is in the repo

| Path | What it is for |
|---|---|
| `Scripts/release.sh` | Tests, archives, exports, and optionally uploads the build. |
| `Scripts/ExportOptions.plist` | App Store Connect export settings for `xcodebuild -exportArchive`. |
| `ClassyO80/PrivacyInfo.xcprivacy` | Privacy manifest. Required: the app touches `UserDefaults`. |
| `docs/appstore/listing.md` | Every text field in App Store Connect, within Apple's limits. |
| `docs/appstore/screenshots.md` | Required sizes, what to show, and the commands to capture them. |
| `docs/privacy.md` | The privacy policy to publish at the Privacy Policy URL. |
| `docs/support.md` | The page to publish at the Support URL. |
| `docs/_config.yml`, `docs/index.md` | Publish those two pages with GitHub Pages, and nothing else. |

Release-relevant settings in `project.yml`:

- `MARKETING_VERSION` 1.0 and `CURRENT_PROJECT_VERSION` 1 — the version and build users and App
  Store Connect see.
- `Release` config: whole-module optimisation, `-O`, `dwarf-with-dsym` so crash reports
  symbolicate, and `VALIDATE_PRODUCT`.
- The `ClassyO80` scheme archives in `Release` and runs, tests and analyses in `Debug`.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO` — no export-compliance questionnaire.
- `INFOPLIST_KEY_NSHumanReadableCopyright` — shown in Settings and on the App Store page.
- `INFOPLIST_KEY_UIUserInterfaceStyle: Dark` plus the `LaunchBackground` colour asset, so a cold
  start does not flash white before the first frame. `LaunchAppearanceTests` keeps that asset in
  step with `Palette.desk`.

## Before the first submission

These need a Mac, an Apple Developer account, or both. Nothing in the repo can stand in for them.

The repository was renamed from `casiocalc` to `classyo80` on 27 September 2026, so nothing
anywhere still carries the old name. GitHub redirects the old git URL, but a clone made before the
rename is worth repointing: `git remote set-url origin https://github.com/drewmerc302/classyo80.git`.

1. **Verify the build.** `xcodegen generate`, then run both test suites (see the commands in
   `README.md`). The changes above were written on a machine without Xcode, so the first real build
   is also the first check of the new `project.yml`, the privacy manifest and the new test.
   Confirm on a device or simulator that:
   - the Home Screen name reads *Classy-O 80* and the panel reads *CLASSY-O* / *CO-80BM*,
   - the launch screen is desk-brown rather than white,
   - `PrivacyInfo.xcprivacy` is at the root of the built `.app` bundle
     (`find build -name '*.app' -maxdepth 6 | head -1`, then `ls` it).
2. **Decide the price.** Free or paid; there is no in-app purchase code, so nothing else follows
   from it.
3. **Create the app record** in App Store Connect: Utilities category, bundle ID
   `com.drewmerc.classyO80`, SKU `classy-o-80`, name from `docs/appstore/listing.md`.
4. **Publish the two pages.** Turn on GitHub Pages for `main` / `/docs` (Settings → Pages), then
   open `https://drewmerc302.github.io/classyo80/privacy` and `.../support` and confirm they render.
   App Review follows both. `docs/_config.yml` keeps the developer documentation out of the
   published site, so the site is those two pages and an index and nothing else.
5. **Capture screenshots** per `docs/appstore/screenshots.md`. The old images in
   `docs/screenshots/` are README illustrations at the wrong sizes, and they still show the old
   `MS-80BM` model plate — recapture those two as well while the simulators are booted.
6. **Fill the listing** from `docs/appstore/listing.md`, including the Notes for App Review — the
   `OFF` key and the six-minute auto power off both look like defects to a reviewer who has never
   used the hardware.
7. **Answer the privacy questionnaire**: "No" to data collection, which yields a *Data Not
   Collected* label.
8. **Age rating**: 4+, nothing objectionable in any category.

## Cutting a build

```sh
Scripts/release.sh            # test, archive, export to build/export/ClassyO80.ipa
Scripts/release.sh --upload   # the same, then validate and upload to App Store Connect
```

The script refuses to run on a dirty working tree, so every uploaded build maps to a commit. It
needs `ASC_KEY_ID` and `ASC_ISSUER_ID` in the environment to upload; without them, open
`build/ClassyO80.xcarchive` in Xcode Organizer and use *Distribute App*.

Then, in App Store Connect: attach the build to the version, submit for review, and choose manual
or automatic release.

## Versioning

- `MARKETING_VERSION` is the user-visible version (`1.0`, `1.1`, `2.0`). Bump it for a new App
  Store version.
- `CURRENT_PROJECT_VERSION` must increase for **every** build uploaded, even a replacement for a
  rejected one. App Store Connect rejects a duplicate.
- Both live in `settings.base` in `project.yml`. Tag the commit after a successful upload:
  `git tag -a v1.0 -m "Classy-O 80 1.0 (1)"`.

## Intellectual property

This is the likeliest reason for a rejection, so it is worth being deliberate about. Apple's
[Guideline 5.2.1](https://developer.apple.com/app-store/review/guidelines/#intellectual-property)
covers apps that use someone else's marks or product designs.

What the app does about it:

- No Casio wordmark, model number or logo appears in the app, its name, or its listing. The panel
  prints `CLASSY-O` and `CO-80BM`, both ours.
- The listing describes behaviour — truncation, left-to-right evaluation, the percent key — and
  never names the manufacturer. Behaviour is not protectable the way a mark is.
- `docs/appstore/listing.md` says all of this inline, so the next person to edit the copy sees it.
- **Casio's user guide is not redistributed.** The scans that used to sit in `docs/manual/` are
  gone from the working tree. `docs/SPEC.md` cites the guide by its printed part numbers and says
  where to get it; `ManualExamplesTests.swift` remains the checked-in record of every example in
  it, which is what the engine is actually held to. Keep your own copy of the guide outside the
  repo.

  **The history was rewritten to match**, on 27 September 2026:
  `git filter-repo --path docs/manual --invert-paths`, force-pushed on `main` and the working
  branch. No commit in this repository holds the scans any more, and `git log --all -- docs/manual`
  finds nothing. Every SHA from the first commit onward changed, so an older clone cannot
  fast-forward — re-clone rather than merge. Two loose ends live outside this repository:

  - GitHub keeps unreachable objects fetchable by SHA for a while after a force push, and any fork
    taken before the rewrite keeps its own copy. To be certain the old blobs are gone, ask GitHub
    Support to garbage-collect the repository, and check the fork list.
  - Anything pinned to an old SHA — a CI config, a bookmark, a draft PR — now points at a commit
    that does not exist. There were no tags and no open pull requests when this ran.
- **`README.md` and `docs/SPEC.md` name the hardware**, which is accurate and descriptive use for
  developer documentation. The README carries a disclaimer for anyone who arrives from the support
  link.

## Other review risks

- **Guideline 4.3, duplicate apps.** The store is full of calculators. The listing leans on what
  makes this one different — truncation, no precedence, the percent key, COST/SELL/MAR — rather
  than on "calculator", which is also the honest description.
- **Guideline 2.1, apparent defects.** The `OFF` key and the six-minute auto power off are the two
  behaviours a reviewer is most likely to file as a bug. The review notes in
  `docs/appstore/listing.md` lead with both; keep them there.
- **Guideline 1.5, support URL.** A support URL that 404s is a rejection on its own, so publish the
  pages before submitting, not after.

## When something changes

- A behaviour change starts in `docs/SPEC.md` and a failing engine test, per `CLAUDE.md`.
- Anything that collects, stores or transmits new data has to move together:
  `ClassyO80/PrivacyInfo.xcprivacy`, the App Store privacy answers in `docs/appstore/listing.md`,
  and `docs/privacy.md`.
- A new key, gesture or mode belongs in the review notes if it is not obvious, and probably in a
  screenshot.
