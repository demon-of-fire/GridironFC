//
//  EuropeanCompetition.swift
//  GridironFC
//
//  European club competitions (Champions League, Europa League, Conference League)
//  modelled as a 36/36/32-team league phase followed by a knockout bracket, mirroring
//  the modern UEFA "Swiss" format. Each competition runs its own schedule so it stays
//  decoupled from the domestic fixture engine.
//

import Foundation

// MARK: - Competition Identifier

public enum EuropeanCompetition: String, Codable, CaseIterable, Identifiable, Hashable {
    case championsLeague
    case europaLeague
    case conferenceLeague

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .championsLeague: return "UEFA Champions League"
        case .europaLeague: return "UEFA Europa League"
        case .conferenceLeague: return "UEFA Conference League"
        }
    }

    public var shortName: String {
        switch self {
        case .championsLeague: return "UCL"
        case .europaLeague: return "UEL"
        case .conferenceLeague: return "UECL"
        }
    }

    /// Number of clubs in the league phase.
    public var leaguePhaseCount: Int {
        switch self {
        case .championsLeague, .europaLeague: return 36
        case .conferenceLeague: return 32
        }
    }

    /// Matches each club plays in the league phase.
    public var leaguePhaseMatches: Int {
        switch self {
        case .championsLeague, .europaLeague: return 8
        case .conferenceLeague: return 6
        }
    }

    /// Clubs eliminated directly after the league phase (below the knockout spots).
    public var directEliminationCount: Int { 12 }

    /// Colour used to tint the competition in the UI.
    public var accentColorHex: String {
        switch self {
        case .championsLeague: return "#1A2A6C"
        case .europaLeague: return "#F58220"
        case .conferenceLeague: return "#00A650"
        }
    }
}

// MARK: - Fixture (two-legged tie aware)

public struct EuropeanFixture: Codable, Identifiable, Hashable {
    public var id: UUID
    public var homeClubId: UUID
    public var awayClubId: UUID
    public var matchweek: Int
    public var stage: String
    public var leg: Int                  // 1 or 2 (0 for single-match finals)
    public var isPlayed: Bool
    public var homeGoals: Int
    public var awayGoals: Int

    public init(
        id: UUID = UUID(),
        homeClubId: UUID,
        awayClubId: UUID,
        matchweek: Int,
        stage: String,
        leg: Int,
        isPlayed: Bool = false,
        homeGoals: Int = 0,
        awayGoals: Int = 0
    ) {
        self.id = id
        self.homeClubId = homeClubId
        self.awayClubId = awayClubId
        self.matchweek = matchweek
        self.stage = stage
        self.leg = leg
        self.isPlayed = isPlayed
        self.homeGoals = homeGoals
        self.awayGoals = awayGoals
    }
}

// MARK: - League-phase row

public struct EuropeanRow: Codable, Identifiable, Hashable {
    public var id: UUID { clubId }
    public var clubId: UUID
    public var played: Int
    public var won: Int
    public var drawn: Int
    public var lost: Int
    public var goalsFor: Int
    public var goalsAgainst: Int
    public var goalDifference: Int { goalsFor - goalsAgainst }
    public var points: Int

    public init(clubId: UUID) {
        self.clubId = clubId
        self.played = 0
        self.won = 0
        self.drawn = 0
        self.lost = 0
        self.goalsFor = 0
        self.goalsAgainst = 0
        self.points = 0
    }

    public mutating func record(goalsFor gf: Int, goalsAgainst ga: Int) {
        played += 1
        goalsFor += gf
        goalsAgainst += ga
        if gf > ga { won += 1; points += 3 }
        else if gf == ga { drawn += 1; points += 1 }
        else { lost += 1 }
    }

    public static func sort(_ a: EuropeanRow, _ b: EuropeanRow) -> Bool {
        if a.points != b.points { return a.points > b.points }
        if a.goalDifference != b.goalDifference { return a.goalDifference > b.goalDifference }
        if a.goalsFor != b.goalsFor { return a.goalsFor > b.goalsFor }
        return a.won > b.won
    }
}

// MARK: - Competition state

public struct EuropeanCompetitionState: Codable, Identifiable, Hashable {
    public var id: UUID
    public var competition: EuropeanCompetition
    public var stage: Stage
    public var participantClubIds: [UUID]
    public var fixtures: [EuropeanFixture]
    public var championClubId: UUID?

    public enum Stage: String, Codable, Hashable {
        case leaguePhase
        case knockout
        case complete
    }

    public init(
        id: UUID = UUID(),
        competition: EuropeanCompetition,
        stage: Stage = .leaguePhase,
        participantClubIds: [UUID] = [],
        fixtures: [EuropeanFixture] = [],
        championClubId: UUID? = nil
    ) {
        self.id = id
        self.competition = competition
        self.stage = stage
        self.participantClubIds = participantClubIds
        self.fixtures = fixtures
        self.championClubId = championClubId
    }

    /// Current league-phase table.
    public func table() -> [EuropeanRow] {
        var rows: [UUID: EuropeanRow] = [:]
        for clubId in participantClubIds { rows[clubId] = EuropeanRow(clubId: clubId) }

        for f in fixtures where f.isPlayed {
            rows[f.homeClubId]?.record(goalsFor: f.homeGoals, goalsAgainst: f.awayGoals)
            rows[f.awayClubId]?.record(goalsFor: f.awayGoals, goalsAgainst: f.homeGoals)
        }
        return rows.values.sorted(by: EuropeanRow.sort)
    }

    /// True once every league-phase fixture has a result.
    public var leaguePhaseComplete: Bool {
        fixtures.filter { $0.stage == "League Phase" }.allSatisfy { $0.isPlayed }
    }

    /// All fixtures for a given matchweek.
    public func fixtures(matchweek: Int) -> [EuropeanFixture] {
        fixtures.filter { $0.matchweek == matchweek }
    }

    /// True when every fixture in the current knockout round is finished.
    public func currentRoundComplete() -> Bool {
        guard let round = activeKnockoutRound else { return false }
        let roundFixtures = fixtures.filter { $0.stage == round }
        return !roundFixtures.isEmpty && roundFixtures.allSatisfy { $0.isPlayed }
    }

    /// The knockout round currently in progress, if any.
    public var activeKnockoutRound: String? {
        for round in Self.knockoutOrder {
            let roundFixtures = fixtures.filter { $0.stage == round }
            if roundFixtures.isEmpty { return round }
            if !roundFixtures.allSatisfy({ $0.isPlayed }) { return round }
        }
        return nil
    }

    static let knockoutOrder = ["Knockout Play-off", "Round of 16", "Quarter-Final", "Semi-Final", "Final"]

    /// Advances the competition by simulating one matchweek; generates the next
    /// knockout round once the current one is complete.
    public mutating func advanceMatchweek(
        week: Int,
        simulate: (UUID, UUID) -> (Int, Int)
    ) {
        for idx in fixtures.indices where fixtures[idx].matchweek == week && !fixtures[idx].isPlayed {
            let (hg, ag) = simulate(fixtures[idx].homeClubId, fixtures[idx].awayClubId)
            fixtures[idx].homeGoals = hg
            fixtures[idx].awayGoals = ag
            fixtures[idx].isPlayed = true
        }

        if stage == .leaguePhase && leaguePhaseComplete {
            stage = .knockout
            generateNextKnockoutRound()
        } else if stage == .knockout && currentRoundComplete() {
            generateNextKnockoutRound()
        }
    }

    /// Two-legged tie winner by aggregate (ties broken by away goals then first-listed).
    private func tieWinner(first: UUID, second: UUID, stage: String) -> UUID {
        let legs = fixtures.filter {
            $0.stage == stage &&
            (($0.homeClubId == first && $0.awayClubId == second) ||
             ($0.homeClubId == second && $0.awayClubId == first))
        }
        var firstGoals = 0, secondGoals = 0
        var firstAway = 0, secondAway = 0
        for leg in legs where leg.isPlayed {
            if leg.homeClubId == first {
                firstGoals += leg.homeGoals; secondGoals += leg.awayGoals; secondAway += leg.awayGoals
            } else {
                secondGoals += leg.homeGoals; firstGoals += leg.awayGoals; firstAway += leg.awayGoals
            }
        }
        if firstGoals != secondGoals { return firstGoals > secondGoals ? first : second }
        if firstAway != secondAway { return firstAway > secondAway ? first : second }
        return first
    }

    /// Generates the fixtures for the next outstanding knockout round.
    private mutating func generateNextKnockoutRound() {
        guard let round = activeKnockoutRound else {
            stage = .complete
            if let final = fixtures.first(where: { $0.stage == "Final" && $0.isPlayed }) {
                championClubId = final.homeGoals >= final.awayGoals ? final.homeClubId : final.awayClubId
                stage = .complete
            }
            return
        }

        let baseWeek = (fixtures.map { $0.matchweek }.max() ?? competition.leaguePhaseMatches) + 1
        var newFixtures: [EuropeanFixture] = []

        switch round {
        case "Knockout Play-off":
            let standings = table()
            guard standings.count >= 24 else { return }
            let playOff = Array(standings[8..<24].map { $0.clubId })
            for i in 0..<8 {
                let home = playOff[i], away = playOff[15 - i]
                newFixtures.append(EuropeanFixture(homeClubId: home, awayClubId: away, matchweek: baseWeek, stage: round, leg: 1))
                newFixtures.append(EuropeanFixture(homeClubId: away, awayClubId: home, matchweek: baseWeek + 1, stage: round, leg: 2))
            }

        case "Round of 16":
            let standings = table()
            guard standings.count >= 16 else { return }
            let top8 = standings.prefix(8).map { $0.clubId }
            let playOff = Array(standings[8..<24].map { $0.clubId })
            let winners = (0..<8).map { i in
                tieWinner(first: playOff[i], second: playOff[15 - i], stage: "Knockout Play-off")
            }
            for (home, away) in zip(top8, winners) {
                newFixtures.append(EuropeanFixture(homeClubId: home, awayClubId: away, matchweek: baseWeek, stage: round, leg: 1))
                newFixtures.append(EuropeanFixture(homeClubId: away, awayClubId: home, matchweek: baseWeek + 1, stage: round, leg: 2))
            }

        case "Quarter-Final", "Semi-Final":
            let prev = round == "Quarter-Final" ? "Round of 16" : "Quarter-Final"
            let pairs = knockoutWinners(from: prev)
            for i in stride(from: 0, to: pairs.count - 1, by: 2) {
                let home = pairs[i], away = pairs[i + 1]
                newFixtures.append(EuropeanFixture(homeClubId: home, awayClubId: away, matchweek: baseWeek, stage: round, leg: 1))
                newFixtures.append(EuropeanFixture(homeClubId: away, awayClubId: home, matchweek: baseWeek + 1, stage: round, leg: 2))
            }

        case "Final":
            let pairs = knockoutWinners(from: "Semi-Final")
            if let home = pairs.first, let away = pairs.dropFirst().first {
                newFixtures.append(EuropeanFixture(homeClubId: home, awayClubId: away, matchweek: baseWeek, stage: round, leg: 0))
            }

        default:
            break
        }

        fixtures.append(contentsOf: newFixtures)
        // If the final was just generated it is the last round; completion is detected
        // after it is simulated on the following advance.
    }

    /// Returns the ordered winners of every tie in a completed knockout round.
    private func knockoutWinners(from stage: String) -> [UUID] {
        let roundFixtures = fixtures.filter { $0.stage == stage }
        var seen = Set<UUID>()
        var winners: [UUID] = []
        for f in roundFixtures {
            if seen.contains(f.homeClubId) { continue }
            let a = f.homeClubId, b = f.awayClubId
            seen.insert(a); seen.insert(b)
            winners.append(tieWinner(first: a, second: b, stage: stage))
        }
        return winners
    }
}
