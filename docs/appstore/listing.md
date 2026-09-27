# App Store Connect listing

Copy for every text field in App Store Connect, ready to paste. Apple's character limits are in
brackets. This file is where the copy lives: edit it here, paste from here, so the listing and the
repo never drift apart.

**No Casio mark appears anywhere in this listing, and none should.** The app is a replica of
hardware someone else designed, so the listing describes what it *does* rather than what it copies.
Naming the manufacturer in the name, subtitle, keywords or description invites a rejection under
[Guideline 5.2.1](https://developer.apple.com/app-store/review/guidelines/#intellectual-property)
and gives no benefit in search. See docs/RELEASE.md for the rest of that reasoning.

## Identity

| Field | Value |
|---|---|
| Bundle ID | `com.drewmerc.classyO80` |
| SKU | `classy-o-80` |
| Primary language | English (U.S.) |
| Primary category | Utilities |
| Secondary category | Finance |
| Age rating | 4+ (no objectionable content in any category) |
| Price | (decide before submitting — see docs/RELEASE.md) |
| Copyright | 2026 Andrew Mercurio |

## Name [30]

```
Classy-O 80 — Desk Calculator
```

## Subtitle [30]

```
Retro 8-digit desk calculator
```

## Promotional text [170]

Editable without a new build, so use it for whatever is timely.

```
Practising for a case interview? This is the desk calculator they hand you: truncating, strictly left to right, with the odd percent key and COST/SELL/MAR all intact.
```

## Keywords [100, comma separated]

```
desk,case interview,consulting,margin,cost,sell,percent,memory,retro,vintage,mental math,8 digit
```

Do not repeat words already in the name or subtitle — Apple indexes those separately.

## Description [4000]

```
An 8-digit desk calculator, rebuilt key for key.

Classy-O 80 is a faithful replica of the brown-and-grey desk calculator that still sits on finance and consulting desks: the same five-by-six keypad, the same seven-segment LCD, and the same immediate-execution logic that makes it behave quite differently from the calculator built into your phone.

WHY IT FEELS RIGHT
• Truncation, not rounding. 100 ÷ 3 × 3 shows 99.999999, exactly as the hardware does.
• No operator precedence. 6 ÷ 3 × 5 + 2.4 − 1 = is 11.4, worked left to right as you type.
• Three-digit separators, the always-visible decimal point, and the M, K and E indicators.

EVERY KEY WORKS
• Constants: press an operator twice for K. 23 + + 12 = is 35, and 45 = is then 68.
• The quirky percent key: 200 × 5 % is 10, 500 × 20 % − is 400, 30 ÷ 60 % is 50, and 12 − 10 % is 20.
• Independent memory: M+, M−, and MRC twice to clear.
• COST / SELL / MAR: enter any two and get the third. Press MAR twice for the margin amount.
• Currency conversion: M/EX switches modes, then hold % to store a rate in C1, C2 or C3.
• C clears the entry, ▶ deletes the last digit, AC clears everything but memory.
• OFF blanks the display and AC brings it back, and it powers itself off after six idle minutes.

BUILT FOR PRACTICE
Case interviews and trading desks still hand you a physical calculator. Practising on one that divides, truncates and chains the way that unit does means no surprises on the day.

A FEW MODERN CONVENIENCES
• Long-press the display to copy the value.
• A hardware keyboard works on iPad: digits, + − * /, Return for =, Delete for ▶, Escape for AC.
• Memory, stored rates and the current mode survive relaunches.
• Full VoiceOver support: every key is labelled, and the display is spoken as it changes.

No account, no ads, no analytics, no network access. Nothing you type leaves your device.
```

## What's New [4000]

For 1.0:

```
First release.
```

## URLs

| Field | Value |
|---|---|
| Support URL | `https://drewmerc302.github.io/classyo80/support` |
| Marketing URL | (optional — leave empty for 1.0) |
| Privacy Policy URL | `https://drewmerc302.github.io/classyo80/privacy` |

Both pages are in this repo as `docs/support.md` and `docs/privacy.md`; publish them by turning on
GitHub Pages for the `main` branch, `/docs` folder, then open the two URLs and confirm they render
before submitting. App Review does follow these links, and a dead support URL is a rejection under
Guideline 1.5.

## App privacy (the nutrition label)

Answer App Store Connect's privacy questionnaire as follows.

- **Do you or your third-party partners collect data from this app?** → **No**

That single answer produces a "Data Not Collected" label and skips the rest of the questionnaire.
It is accurate: the app has no networking code, no SDKs, no analytics and no crash reporter. The
only stored data is the calculator's own memory, exchange rates and mode, kept in `UserDefaults`
on the device and declared in `ClassyO80/PrivacyInfo.xcprivacy` (reason `CA92.1`).

If a future version adds anything that leaves the device, this answer, the privacy manifest and
`docs/privacy.md` all have to change together.

## Export compliance

`ITSAppUsesNonExemptEncryption` is `NO` in `project.yml`, so App Store Connect stops asking about
encryption. The app uses no cryptography at all.

## Notes for App Review

Paste into "Notes" on the version page. The auto power off and the OFF key are the two things that
look like bugs to someone who has never used the hardware, so lead with them.

```
This app replicates a physical desk calculator, including two behaviours that may look like defects:

1. OFF (top-left, small grey key) blanks the display on purpose, exactly as the hardware key does. Press AC (orange, bottom-left) to turn the display back on.
2. The calculator powers itself off after about six minutes with no key presses, as the hardware does. Press AC to bring it back. Nothing is lost: memory and stored rates are kept.

Things you may want to try:
• 6 ÷ 3 × 5 + 2.4 − 1 = shows 11.4. There is no operator precedence, as on the original hardware.
• 100 ÷ 3 × 3 = shows 99.999999. Results truncate to 8 digits rather than rounding.
• COST, SELL and MAR (top row): enter 500 COST, 700 SELL, then MAR shows the 28.571428% margin.
• M/EX switches to currency-conversion mode, where M+, M− and MRC act as rate slots C1, C2 and C3. Hold the % key for about a second to store the entered number as a rate.

No sign-in, no account, no network access. No demo or test content is included.
```

## Build to submit

Produced by `Scripts/release.sh --upload`. Confirm the version and build number on the App Store
Connect version page match `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`.
