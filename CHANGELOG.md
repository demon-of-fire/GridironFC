# Changelog

All notable changes to GridironFC are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Transfer market search** — filter the market by position, minimum rating, and
  maximum age; sort by rating, value, age, or name; option to include free agents.
- **Inbox tab** — the news inbox is now a first-class tab, seeded with board
  objectives, transfer-window and free-agent scouting messages when you take over.
- **Post-match league results** — the full-time recap now lists every other
  result from the same matchweek.
- **Close/Done buttons** — Settings, Inbox, and Match History can be dismissed
  back to the dashboard.

### Changed

- **Calendar-driven progression** — the dashboard *Continue* button now advances
  day by day to your next fixture (simulating other clubs' matches as it goes)
  instead of requiring a separate *Prepare for Match* step, which was removed.
- **Match engine balance** — possession is now clamped to a realistic 32–68%
  range and chance frequency/conversion retuned for more realistic scorelines,
  with scoring throttled once a side builds a multi-goal lead.

### Fixed

- **Squad tap-to-substitute** — tapping a bench player and a starter now swaps
  them correctly via the new `swapIntoStartingXI` helper.
- **Full league simulation** — other clubs' fixtures are now simulated through
  the matchweek after your match, so standings no longer stall.
- **Multi-season rollover** — end-of-season now transitions correctly, and the
  dashboard offers *Start New Season* once the campaign is complete.
- **Sound effects** — goal/win/draw/loss/whistle/click cues are now synthesised
  as in-memory WAV tones (previous system-sound approach was unreliable).

## [0.1.0] - 2026-10-20

First public build of GridironFC. Ships as an **unsigned `.ipa`** for sideloading
with a tool such as Feather (re-sign with your own certificate).

### Added

- **Three career modes**
  - *Create a Club* — define a name, stadium, city, and kit colours, then replace a League Two side.
  - *Manage Existing Club* — take charge of any of the 92 clubs across the four English divisions.
  - *Create a Player* — build a custom player, assign a starting club, and follow their career.
- **English football pyramid** — 92 real clubs and 2,208 real players across four tiers
  (Premier League, Championship, League One, League Two), bundled as offline JSON.
- **Deep player simulation** — 30+ technical, physical, mental, and goalkeeping attributes
  generated from position-specific templates with randomised variance.
- **Minute-by-minute match engine** — possession, shots, xG, fouls, cards, injuries,
  fatigue, and dynamic commentary with player ratings (1.0–10.0).
- **Position-cam match replay** — top-down animated pitch with 22 interpolated player
  dots and the ball, replaying each minute of the match.
- **Procedural faces and crests** — every player portrait and club badge is generated
  deterministically from a stable seed. No real likenesses or trademarked imagery.
- **Transfer market** — bid for players at other clubs or sign free agents, with budget,
  wage, and valuation checks resolved by the selling club.
- **Season progression** — promotions, relegations (Premier League ↔ Championship ↔
  League One ↔ League Two) and four-team play-offs each season.
- **VoiceOver-first accessibility** — combined elements, custom rotor actions, spoken
  match-event announcements, and Dynamic Type scaling up to `.accessibility3`.
- **Persistence** — multi-slot and autosave JSON saves in the app's Documents container.
  Zero external dependencies or network calls.

### Notes

- Signed release: **no** — build is intentionally unsigned for side-loading.
- Internal app version (`CFBundleShortVersionString`): `0.1.0`.
- Minimum iOS version: `17.0`.

[0.1.0]: https://github.com/demon-of-fire/GridironFC/releases/tag/v0.1.0
