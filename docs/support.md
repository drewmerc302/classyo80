---
title: Support
---

# Classy-O 80 — Support

An 8-digit desk calculator for iPhone and iPad, rebuilt key for key.

**Contact:** [drewmerc@gmail.com](mailto:drewmerc@gmail.com) — questions, bug reports and
disagreements about how a key should behave are all welcome. If a key gives a different answer than
the hardware on your desk, please say which keys you pressed, in order, and what each unit showed.

## Things that look like bugs and are not

**The display went blank.** Either `OFF` was pressed, or the calculator powered itself off after
about six idle minutes, as the hardware does. Press `AC` to bring it back. Memory and stored rates
are kept.

**`6 ÷ 3 × 5 + 2.4 − 1 =` gives 11.4, not what my phone calculator says.** There is no operator
precedence: keys are worked left to right, in the order pressed, as on the original.

**`100 ÷ 3 × 3 =` gives 99.999999.** Results are truncated to 8 digits rather than rounded, and
only those 8 digits carry into the next operation.

**`12 − 10 %` gives 20.** On this kind of calculator, `%` after `−` is a percent-change key: 12 is
20% more than 10, so the answer is the change from 10 to 12 as a percentage. The full set of percent
behaviours is listed below.

## How the less obvious keys work

| Keys | Shows | What it means |
|---|---|---|
| `200 × 5 %` | 10 | 5% of 200 |
| `100 × 5 % +` | 105 | add-on |
| `500 × 20 % −` | 400 | discount |
| `30 ÷ 60 %` | 50 | 30 is 50% of 60 |
| `12 − 10 %` | 20 | percent change from 10 to 12 |
| `23 + + 12 =` then `45 =` | 35, then 68 | constant (`K`) |
| `500 COST` `700 SELL` `MAR` | 28.571428 | margin percent |
| `MAR` `MAR` | 200 | the margin amount |
| `M/EX` then hold `%` | `SET` | store an exchange rate in `C1`, `C2` or `C3` |
| `MRC` `MRC` | | recall, then clear memory |

## Extras that the hardware does not have

- Long-press the display to copy the value.
- On iPad, a hardware keyboard works: digits, `+ - * /`, Return or `=` for equals, `%`, Delete
  for `▶`, Escape for `AC`, `c` for `C`.
- VoiceOver reads every key and speaks the display as it changes.

## Privacy

The app collects nothing and has no network access. See the
[privacy policy](privacy).

## Requirements

iOS 18 or later, on iPhone or iPad.
