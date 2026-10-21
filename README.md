# ⚽ GridironFC — iOS Association Football Management

**GridironFC** is a pure SwiftUI football (soccer) management simulation built for iOS 17.0+. Experience the journey of creating your own club, replacing an existing team in English League Two, and navigating tactical adjustments, squad recruitment, training development, and dynamic match simulations to climb to the Premier League.

---

## 🌟 Key Features

- **Distinct Career Roles**: *Own a New Club* is an owner-first career with a boardroom, manager appointments, staff recruitment, facilities and stadium investment. *Manage Existing Club* is a head-coach career centred on tactics, squad selection and matchdays. *Start Unemployed* begins a traditional manager journey from the job market.
- **Dynamic State Engine (`@Observable GameState`)**: Built on modern iOS 17 Observation macros for seamless, reactive data updates across all views.
- **Deep Player Simulation**: Over 30 technical, physical, mental, and goalkeeping attributes generated using position-specific procedural templates with randomized variance and specialty overrides.
- **Procedural Faces & Crests**: Every player portrait and club badge is generated deterministically from a stable seed — no real likenesses or trademarked imagery are used, keeping the build fully offline and asset-free.
- **Minute-by-Minute Match Engine**: Simulated tactical matches calculating possession, shots, xG, fouls, cards, injuries, fatigue depletion, dynamic crowd reaction text, and player ratings (1.0–10.0).
- **Position-Cam Match Replay**: A top-down pitch animation replays each match minute-by-minute with 22 interpolated player dots and the ball, announcing key events for VoiceOver as they occur.
- **English Football Pyramid**: Features 92 English clubs across 4 tiers (Premier League, Championship, League One, League Two) with real club and player names, plus promotions, relegations, and play-offs each season.
- **Working Transfer Market**: Bid for players at other clubs or sign free agents, with budget, wage, and valuation checks resolved by the selling club.
- **Autonomous AI Management**: Competitor clubs scout players, renew contracts, manage finances, rotate squads, and make bids during summer and winter transfer windows.
- **First-Class VoiceOver Accessibility**: Custom accessibility modifiers, descriptive spoken summaries for cards and stats, rotor actions, event announcements, and Dynamic Type scaling.
- **Persistence & Save Management**: Robust multi-slot JSON persistence (3 manual slots + autosave) in the app's local Documents container. Zero external dependencies or network calls required.

---

## 🏗 Architecture & Code Structure

```
GridironFC/
├── project.yml                          # XcodeGen specification
├── README.md                            # Documentation
├── .github/
│   └── workflows/
│       └── build.yml                    # Automated CI/CD pipeline (macOS-14 runner)
└── GridironFC/
    ├── App/
    │   ├── GridironFCApp.swift          # Main entrypoint with environment injection
    │   └── ContentView.swift            # Root navigation coordinator & screen routing
    ├── Models/
    │   ├── Enums.swift                  # Positions, tactics, match events, tiers, screen states
    │   ├── Player.swift                 # Player, PlayerAttributes, SeasonStats, Contract, Injury
    │   ├── Club.swift                   # Club, ClubFinances, StaffMember, Tactics
    │   ├── League.swift                 # League, Season, Fixture, LeagueStanding, FixtureGenerator
    │   ├── Match.swift                  # MatchResult, MatchEvent, MatchStats
    │   ├── Transfer.swift               # TransferOffer, TransferRecord
    │   └── GameState.swift              # @Observable root state with calendar advancement
    ├── Data/
    │   ├── DataLoader.swift             # Bundle JSON decoding & procedural attribute generator
    │   └── Resources/                   # Bundled tier1–tier4 league datasets (92 clubs, 2,208 players)
    ├── Engine/
    │   ├── MatchEngine.swift            # Minute-by-minute match simulation
    │   ├── Commentary.swift             # Dynamic commentary text generation
    │   └── InjuryEngine.swift           # Injury risk and weekly recovery
    ├── Views/
    │   ├── Common/
    │   │   ├── Theme.swift              # Design tokens & preview mocks
    │   │   ├── CrestView.swift          # Procedural club crest renderer
    │   │   └── FaceView.swift           # Procedural player portrait renderer
    │   └── LiveMatch/
    │       └── PitchReplayView.swift    # Position-cam match replay & live match screen
    ├── Persistence/
    │   └── SaveManager.swift            # Documents directory multi-slot JSON persistence
    └── Accessibility/
        └── AccessibilityHelpers.swift   # VoiceOver modifiers, formatters, and Dynamic Type helpers
```

---

## 🎮 Game Modes

| Mode | Description |
| --- | --- |
| **Own a New Club** | Found a club, set its long-term vision, appoint or dismiss the manager, hire specialist staff and invest in training, academy, medical and stadium infrastructure. |
| **Manage Existing Club** | Create a manager, then take charge of an existing club's tactics, squad, training and matchdays. |
| **Start Unemployed** | Create a manager without a club and work your way through job offers. |

---

## 🛠 Local Setup & Building

### Prerequisites

1. **macOS Sonoma (14.0+)** with **Xcode 15.0+** (Swift 5.9+).
2. **XcodeGen** installed via Homebrew:
   ```bash
   brew install xcodegen
   ```

### Generating the Xcode Project

1. Navigate to the repository root:
   ```bash
   cd "path/to/GridironFC"
   ```
2. Generate the `.xcodeproj` file:
   ```bash
   xcodegen generate
   ```
3. Open `GridironFC.xcodeproj` in Xcode:
   ```bash
   open GridironFC.xcodeproj
   ```
4. Select an iOS 17.0+ Simulator or physical device and press **Cmd + R** to run.

### Publishing and retrieving a release IPA

Push releases through the included PowerShell helper from the repository root:

```powershell
.\tools\Push-And-FetchIPA.ps1
```

It pushes `main`, waits for the matching **Build iOS App** GitHub Actions run,
fails loudly if the workflow does not succeed, and downloads the published
`GridironFC.ipa` to the repository root. The download is checked against the
release's SHA-256 manifest and verified to contain the expected iOS app payload.
`GridironFC.ipa` is intentionally gitignored.

---

## 🚀 Continuous Integration (GitHub Actions)

A GitHub Actions workflow is preconfigured in `.github/workflows/build.yml`:
- Triggered automatically on push to `main` or via **Run workflow** manual dispatch.
- Runs on GitHub's `macos-14` runner.
- Generates the Xcode project with XcodeGen, executes `xcodebuild archive`, packages `GridironFC.ipa`, and uploads it as an artifact.
- Publishes both the IPA and a `release-manifest.json` containing the build
  version, commit SHA and IPA checksum, so the local retrieval helper can
  verify that the release asset is complete and unmodified.
- Supports Apple Developer code signing secrets (`BUILD_CERTIFICATE_BASE64`, `BUILD_PROVISION_PROFILE_BASE64`, `KEYCHAIN_PASSWORD`) or generates unsigned builds for ad-hoc testing.

---

## ♿ Accessibility Standards

GridironFC is built from the ground up for VoiceOver users:
- **Semantic Structure**: Player cards use `.accessibilityElement(children: .combine)` with custom action rotors ("View Profile", "Make Substitution").
- **Stat Readouts**: Numerical ratings (1–99) are translated into qualitative speech ratings ("World Class", "Excellent", "Average").
- **Non-Color Dependence**: Every metric combines visual color indicators with iconography and explicit text labels.
- **Dynamic Type**: All views scale responsively up to `.accessibility3` sizes using `.dynamicTypeBounds()`.

---

## 📄 License

GridironFC is distributed under the MIT License.
