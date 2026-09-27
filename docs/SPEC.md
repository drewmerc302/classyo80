# Classy-O 80 behavior spec

Source of truth: the Casio MS-80BM User's Guide (HDC463AE0P7, SA1711-A, 2018) and a front-panel
photograph of the unit, neither of which is redistributed here — they are Casio's. Download the
guide from Casio's support site, or use the sheet that came in the box, and keep it outside the
repo. Every example in it is an executable test in
`Packages/CalcEngine/Tests/CalcEngineTests/ManualExamplesTests.swift`, which is this project's
checked-in record of what the guide says.

Where the manual is silent, the behavior below follows the basic-calculator logic of that era. Those
rows are marked **(assumed)** so they can be checked against the physical unit.

## Front panel (5 columns x 6 rows)

| Row | Col 1 | Col 2 | Col 3 | Col 4 | Col 5 |
|---|---|---|---|---|---|
| 1 (small keys) | OFF | ▶ | COST | SELL | MAR |
| 2 | MRC (`C3` above) | M− (`C2` above) | M+ (`C1` above) | % (`SET` above) | ÷ |
| 3 | M/EX (`MODE` above) | 7 | 8 | 9 | × |
| 4 | +/− | 4 | 5 | 6 | − |
| 5 | C (orange) | 1 | 2 | 3 | + (double height) |
| 6 | AC (orange, `ON` to the left) | 0 | . | = | (+ continues) |

No √ key, no 00 key, no GT key.

## Display

- 8 digits. The decimal point is always shown (`0.`, `35.`, `11.4`).
- Three-digit separators on the integer part (`1'234'567.8`).
- Indicators: `−` (negative), `M` (memory holds a nonzero value), `E` (error), `K` (constant),
  `COST`, `SELL`, `MAR`, `%`, `EXCH`, `RATE`, `C1`, `C2`, `C3`, `SET`.
- Results are **truncated** (not rounded) to 8 digits, and only those 8 digits carry into the next
  step of a chain. Evidence: the manual's `100 C2 C3` example shows `83.202212`, which only comes
  out when the intermediate is cut to 8 digits (see Currency below). So `2 ÷ 3 × 3 =` is
  `1.9999998`, the same as `2 ÷ 3 = × 3 =`.
- The leading `0` of a fraction occupies a digit: the smallest positive value is `0.0000001`.

## Arithmetic

- Immediate execution, left to right, no precedence: `6 ÷ 3 × 5 + 2.4 − 1 =` → `11.4`.
- `+/−` flips the sign of the entry or the displayed result: `2 × 3 +/− =` → `−6.`
- Pressing a different operator right after another replaces it: `2 + − 7 =` → `−5.`
- Operator then `=` with no second number reuses the first (**assumed**): `5 × =` → `25.`
- `=` repeated without `K` does nothing more (**assumed**).

## Constant calculations (K)

Pressing the same operator twice sets a constant and shows `K`:

| Keys | Display | Rule |
|---|---|---|
| `23 + + 12 =` then `45 =` | `35.`, `68.` | x + k (k = 23) |
| `5 − − 7 =` then `2 =` | `2.`, `−3.` | x − k (k = 5) |
| `12 × × 2 =` then `4 =` | `24.`, `48.` | k × x (k = 12) |
| `9 ÷ ÷ 45 =` then `72 =` | `5.`, `8.` | x ÷ k (k = 9) |

- `=` again with no new entry applies the constant to the display, so `3 × × = =` → `9.`, `27.` (**assumed**).
- A single operator press cancels `K` (**assumed**). `AC` cancels `K`.

## Percent

| Keys | Display | Meaning |
|---|---|---|
| `200 × 5 %` | `10.` | 5% of 200 |
| `100 × 5 % +` | `105.` | add-on |
| `500 × 20 % −` | `400.` | discount |
| `30 ÷ 60 %` | `50.` | 30 is ?% of 60 |
| `12 − 10 %` | `20.` | percent change from 10 to 12 |
| `120 + 25 % −` | `160.`, `40.` | markup: 120 is 75% of 160; `−` gives the margin amount |

- `A + B %` = A ÷ (1 − B/100). The `−` right after it gives result − A.
- `+`/`−` right after `A × B %` finish the add-on or discount and end the calculation, so
  `100 × 5 % + 20 =` shows `20.` (**assumed**; the manual only shows the `105.`).
- With `K` set for ×: `x %` = k × x ÷ 100. With `K` for ÷: x ÷ k × 100. With `K` for + or −, `%`
  acts like `=` (all **assumed**).

## Correction

- `C` clears the current entry only: `2 + 3 C 4 =` → `6.`
- `▶` deletes the last digit typed: `5 + 77 ▶ =` → `12.` A trailing point is invisible, so it
  goes with the digit before it (`12. ▶` → `1.`), and backspacing to empty drops the sign
  (**assumed**).
- `AC` clears everything except independent memory and the currency rates.

## Independent memory (Memory mode)

- `M+` / `M−` finish any pending calculation (like `=`), then add/subtract the display to memory.
- `MRC` once recalls memory. `MRC` twice in a row clears memory.
- `M` shows while memory is nonzero.
- Example: `MRC MRC 8 × 9 M+` (`72.`), `5 × 6 M−` (`30.`), `2 × 3 M+` (`6.`), `MRC` → `48.`

## Currency conversion (Conversion mode)

- `M/EX` toggles Memory mode ↔ Conversion mode (`EXCH` shows in Conversion mode). In Conversion mode
  the MRC / M− / M+ keys act as C3 / C2 / C1. Memory contents are kept.
- C1 is the home currency, rate fixed at 1. C2 = X, C3 = Y. Formulas (A = input or displayed value):
  C2→C1 = A/X, C3→C1 = A/Y, C1→C2 = A×X, C1→C3 = A×Y, C2→C3 = (A/X)×Y, C3→C2 = (A/Y)×X.
- `100 C2` tags 100 as C2. The next Cn press converts. Conversions always start from the
  originally tagged amount, so switching back returns the exact original.
- Manual examples (C2 = 0.9025, C3 = 0.7509):
  - `AC 100 C2 C1` → `110.80332` (C1 EXCH); `C2` → `100.` (C2 EXCH)
  - `AC 110 C1 C3` → `82.599` (C3 EXCH); `C1` → `110.` (C1 EXCH)
  - `AC 100 C2 C3` → `83.202212` (C3 EXCH); `C2` → `100.` (C2 EXCH)
  - Cross-rate: A/X is truncated to 8 digits (110.80332), × 0.7509 = 83.2022129…, truncated to
    `83.202212`. Full precision would give 83.202216, so truncation is load-bearing here.
- `AC` then `C2`/`C3` (no number typed) shows the current rate with `RATE`. An `M/EX` in between
  still counts (`AC M/EX C2`), since starting from Memory mode needs it. The manual shows no display
  for this; the `RATE` indicator is inferred from the SET display (**assumed**).

### Setting a rate

`AC`, hold `%` until `SET` appears, `C2`, `0.9025`, `%` → display `0.9025` with `C2 EXCH RATE`.

- Rate ≥ 1: up to 6 digits. Rate < 1: up to 8 digits including the integer `0` and leading zeros,
  but at most 6 significant digits (`0.123456`, `0.0123456`).
- C1 cannot be set. A zero rate is rejected (**assumed**). `AC` abandons SET.
- The rate keys work in either mode while `SET` is showing (**assumed**).

## Cost / Sell / Margin

Three registers. Entering a number then COST, SELL or MAR stores it. Once two are known, pressing
the third key computes it. MAR shows the margin percent (`MAR %`); pressing MAR again toggles to the
margin amount (`MAR`).

- S = C ÷ (1 − M/100), M = (S − C) ÷ S × 100, C = S × (1 − M/100), amount = S − C.

| Keys | Display |
|---|---|
| `AC 800 COST 2000 SELL MAR` | `60.` (MAR %) |
| `AC 120 COST 40 MAR MAR` then `SELL` | `80.` (MAR), `200.` (SELL) |
| `AC 150 SELL 30 MAR MAR` then `COST` | `45.` (MAR), `105.` (COST) |

- The two most recently entered registers define the third. `AC` clears all three (**assumed**).
- Derived values are truncated to 8 digits before the margin amount is taken, so
  `100 COST 30 MAR MAR` shows `42.85714` (= 142.85714 − 100) (**assumed**).
- M = 100 or S = 0 gives `E`.

## Errors

- `E` appears when a result's integer part needs more than 8 digits. The display shows the leading
  digits with the decimal point shifted 8 places (value ÷ 10^8), classic desk-calculator style (**assumed**).
- Division by zero gives `E` with `0.` (**assumed**).
- Memory overflow gives `E` and leaves memory unchanged (**assumed**).
- While `E` shows, only `AC` (and OFF) respond.

## Power

- `OFF` blanks the display. `AC` (ON) turns it back on and clears like `AC`.
- Auto power off about 6 minutes after the last key press.
- Memory, rates and mode survive power off (**assumed**; the app also persists them across launches).
