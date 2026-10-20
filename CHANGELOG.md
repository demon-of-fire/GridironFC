# Changelog

All notable changes to GridironFC are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-10-20

### Added

- **International management** — take charge of one of 85 national teams
  assembled from real club players by nationality, each with confederation,
  FIFA ranking and coach metadata. The **International** hub (overflow menu)
  shows your nation, squad and the tournaments you are contesting.
- **International tournaments** — the FIFA World Cup plus the EURO, Copa
  América, Africa Cup of Nations and Asian Cup. Each is drawn into groups and
  played out through a knockout bracket, simulated alongside your club season.
- **Rich Latest News feed** — a dedicated **News** tab with category filters,
  full stories and unread state. The Inbox (mail) now lives on the Home screen
  with an unread badge.
- **More formations and meaningful tactics** — ten additional formations, and
  pressing, tempo, width and passing are now sliders that genuinely influence
  possession, chance creation and defensive solidity in the match engine.
- **Match playback settings** — choose replay speed (Slow → Very Fast) and
  pause at half-time for substitutions.
- **Assistant-manager auto-substitutions** — configurable timing (off,
  half-time, second half, throughout) and rotation aggression.
- **Squad edit mode** — tap a player to open their profile as normal, or switch
  on Edit Squad to highlight and swap players for substitutions.

### Changed

- Transfer search is now **filter-then-search**: set your filters and tap
  Search Market. Free agents are hidden unless the Include Free Agents filter
  is switched on.
- The **More options** menu now appears only on the Home screen.
- Transfer and wage budgets are read as separate VoiceOver values and now
  genuinely constrain signings.
- Duplicate players are removed at load (cross-club, by name and age).
- Only file-driven leagues appear; authored non-English lower tiers were
  dropped while the English pyramid remains as a procedural fallback.

### Removed

- **All emojis** — event icons now use SF Symbols and flags render as
  three-letter country codes.

## [Unreleased]

### Added

- **Realistic, multi-week transfer negotiations** — bids are no longer resolved
  instantly. Selling clubs respond over the following weeks, either accepting,
  rejecting, or issuing a **counter-offer** with a specific asking price. Free
  agents negotiate personal terms, and players can hold out for a higher wage.
- **Negotiations run through your inbox** — every offer, counter and rejection
  arrives as actionable mail. Accept a counter, raise your bid, pay a player's
  wage demand, or withdraw, all directly from the message. Your Inbox tab and
  the Transfer Hub both surface outstanding negotiations.
- **AI clubs bid for your players** — rival clubs now make offers for members of
  your squad, which you can accept, reject, or reject-and-hold from the inbox.
- **Smarter valuations** — asking prices account for contract length, the gap in
  stature between clubs, and young high-potential talent. Sell-on clauses now
  pay the player's former club a share of future fees.

- **Youth academy** — every club now runs a youth academy. Prospects (aged
  15-18) develop toward their potential each season and a new intake arrives
  every summer, with quality scaling by academy level, reputation and division.
  Promote standouts to the senior squad or release them from the new
  **Youth Academy** screen (overflow menu).
- **Manager inbox** — correspondence is now addressed to the manager, with a
  sender on every message (The Board, Chief Scout, Head of Youth Development,
  Club Secretary). New **Board & Management** category, per-message read state,
  an unread filter, a "Mark All Read" action, and an unread badge on the Inbox
  tab. Taking over a club seeds a welcome letter and season objectives.

### Removed

- **Create a Player** career mode has been removed to keep the game focused on
  club management.

- **European competitions** — the UEFA Champions League, Europa League and
  Conference League now run in-game with their modern format: a single-table
  league phase (36 clubs, 8 matches each; 32/6 for the Conference League),
  followed by a two-legged knockout play-off, Round of 16, Quarter-Finals,
  Semi-Finals and a single-match Final. Real participant clubs are seeded from
  the dataset and padded with the strongest remaining top-flight clubs.
  View tables and your own fixtures from the overflow menu under
  **European Competitions**.

- **Real-world data import** — the world is now populated from a real
  Transfermarkt dataset (club names, stadiums, capacities, coaches, and full
  squads with real player names, ages, nationalities, positions, and feet).
  Player ratings are derived from real market values and age. The world now spans
  **31 countries** and **40 divisions**, all playable offline.
- **31 playable top flights** — England, Spain, Italy, Germany, France, Portugal,
  Netherlands, Türkiye, Scotland, Belgium, Argentina, Australia, Austria, Brazil,
  Croatia, Czech Republic, Denmark, Greece, Japan, South Korea, Mexico, Norway,
  Poland, Romania, Russia, Saudi Arabia, Serbia, Sweden, Switzerland, Ukraine, and
  the United States — each with its real clubs and squads (~14,500 real players).
- **Country × division grid** — leagues are modelled as a country with up to four
  divisions and a stable index structure; lower divisions (England 2-4, Spain 2-4,
  Italy 2, Germany 2, France 2) carry authored club metadata with procedurally
  generated squads pending a lower-league data source.

> **Accuracy note:** Squad data reflects a recent-season snapshot, not the exact
> 2026-27 rosters; some players may appear at a former club and ages are projected.
> All crests and faces remain procedurally generated.

- **European top flights** — four new fully playable leagues: **La Liga**, **Serie A**,
  **Bundesliga**, and **Ligue 1**, each with real clubs and real players bundled as
  offline JSON (`tier5`–`tier8`). Together with the English pyramid the world now spans
  **five countries and eight divisions** (~2,200 additional players).
- **Country & division structure** — leagues now carry a country grouping; the four
  English divisions keep their promotion/relegation pyramid while the continental
  top flights are standalone leagues. European qualification slots are modelled per
  league (5 for the Premier League, 4 for the continental top flights).

> **Accuracy note:** European club and player data reflects recent squads and is
> provided for identification only; some squad members and ages will be out of date
> relative to the 2026-27 season. All crests and faces remain procedurally generated.

- **Manager customisation** — every career now begins by creating your manager:
  name, nationality, age, and four allocatable coaching attributes, with a
  procedurally generated avatar. Your profile tracks reputation, a coaching
  attribute card, and a season-by-season career history (positions, records,
  honours).
- **Start Unemployed** — a new career mode that begins without a club. Job offers
  arrive based on your reputation; accept a role to begin work.
- **Job offers & managerial mobility** — clubs approach you with vacancies, from
  your inbox and a dedicated Job Offers screen. Accept to switch clubs (ending a
  current stint) or decline. Reputation drifts with results.
- **Player of the Match** — the full-time recap now names the match's best player
  with their club and rating before the other details.
- **My Profile / Job Offers** added to the in-game overflow menu.
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
