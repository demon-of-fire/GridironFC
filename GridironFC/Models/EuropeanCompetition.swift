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

        for f in fixtures where f.isPlayed && f.stage == "League Phase" {
            rows[f.homeClubId]?.record(goalsFor: f.homeGoals, goalsAgainst: f.awayGoals)
            rows[f.awayClubId]?.record(goalsFor: f.awayGoals, goalsAgainst: f.homeGoals)
        }
        return rows.values.sorted(by: EuropeanRow.sort)
    }

    /// True once every league-phase fixture has a result.
    public var leaguePhaseComplete: Bool {
        let leagueFixtures = fixtures.filter { $0.stage == "League Phase" }
        return !leagueFixtures.isEmpty && leagueFixtures.allSatisfy { $0.isPlayed }
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

    /// Number of clubs that contest the knockout bracket. Larger fields use the
    /// play-off round; smaller ones fall back to a compact power-of-two bracket.
    private var knockoutFieldSize: Int {
        let available = table().count
        if available >= 24 { return 24 }
        if available >= 16 { return 16 }
        if available >= 8 { return 8 }
        if available >= 4 { return 4 }
        return 0
    }

    /// The knockout round currently in progress, if any.
    public var activeKnockoutRound: String? {
        let rounds: [String]
        switch knockoutFieldSize {
        case 24...:
            rounds = Self.knockoutOrder
        case 16:
            rounds = ["Round of 16", "Quarter-Final", "Semi-Final", "Final"]
        case 8:
            rounds = ["Quarter-Final", "Semi-Final", "Final"]
        case 4:
            rounds = ["Semi-Final", "Final"]
        default:
            rounds = []
        }

        for round in rounds {
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

        if stage == .leaguePhase {
            guard leaguePhaseComplete else { return }
            stage = .knockout
            generateNextKnockoutRound()
            return
        }

        guard stage == .knockout else { return }

        // The active round can legitimately have no fixtures when the previous
        // round has just finished; generate it now instead of waiting forever.
        guard let round = activeKnockoutRound else {
            finishCompetition()
            return
        }
        let roundFixtures = fixtures.filter { $0.stage == round }
        if roundFixtures.isEmpty || roundFixtures.allSatisfy({ $0.isPlayed }) {
            generateNextKnockoutRound()
        }
    }

    private mutating func finishCompetition() {
        guard stage != .complete else { return }
        stage = .complete
        guard let final = fixtures.first(where: { $0.stage == "Final" && $0.isPlayed }) else { return }
        championClubId = tieWinner(first: final.homeClubId, second: final.awayClubId, stage: "Final")
    }

    /// Two-legged tie winner by aggregate (ties broken by away goals then a shootout).
    private func tieWinner(first: UUID, second: UUID, stage: String) -> UUID {
        let legs = fixtures.filter {
            $0.stage == stage &&
            (($0.homeClubId == first && $0.awayClubId == second) ||
             ($0.homeClubId == second && $0.awayClubId == first))
        }.filter { $0.isPlayed }

        // A single-match final has no aggregate or away-goals rule: a draw goes
        // straight to a penalty shootout.
        if legs.count == 1, let final = legs.first {
            if final.homeGoals != final.awayGoals {
                return final.homeGoals > final.awayGoals ? final.homeClubId : final.awayClubId
            }
            return Double.random(in: 0...1) < 0.5 ? first : second
        }

        var firstGoals = 0, secondGoals = 0
        var firstAway = 0, secondAway = 0
        for leg in legs {
            if leg.homeClubId == first {
                firstGoals += leg.homeGoals; secondGoals += leg.awayGoals; secondAway += leg.awayGoals
            } else {
                secondGoals += leg.homeGoals; firstGoals += leg.awayGoals; firstAway += leg.awayGoals
            }
        }
        if firstGoals != secondGoals { return firstGoals > secondGoals ? first : second }
        if firstAway != secondAway { return firstAway > secondAway ? first : second }
        // Level on aggregate (and away goals): decide the tie with a shootout.
        return Double.random(in: 0...1) < 0.5 ? first : second
    }

    /// Generates the fixtures for the next outstanding knockout round. Larger
    /// fields use the play-off/Round of 16 path; smaller ones drop straight into
    /// a compact power-of-two bracket seeded from the league table.
    private mutating func generateNextKnockoutRound() {
        guard let round = activeKnockoutRound else {
            finishCompetition()
            return
        }

        let baseWeek = (fixtures.map { $0.matchweek }.max() ?? competition.leaguePhaseMatches) + 1
        let standings = table()
        let orderedIds = standings.map { $0.clubId }
        var newFixtures: [EuropeanFixture] = []

        switch round {
        case "Knockout Play-off":
            guard orderedIds.count >= 24 else { return }
            let playOff = Array(orderedIds[8..<24])
            for i in 0..<8 {
                let home = playOff[i], away = playOff[15 - i]
                newFixtures.append(contentsOf: twoLeggedTie(home: home, away: away, stage: round, baseWeek: baseWeek))
            }

        case "Round of 16":
            let top8 = Array(orderedIds.prefix(8))
            let playOffWinners = knockoutWinners(from: "Knockout Play-off")
            let winners: [UUID]
            if playOffWinners.count >= 8 {
                winners = Array(playOffWinners.prefix(8))
            } else if orderedIds.count >= 16 {
                winners = Array(orderedIds[8..<16])
            } else {
                winners = Array(orderedIds.dropFirst(8))
            }
            newFixtures.append(contentsOf: seededTies(home: top8, away: winners, stage: round, baseWeek: baseWeek))

        case "Quarter-Final":
            let r16Winners = knockoutWinners(from: "Round of 16")
            let qualifiers = r16Winners.count >= 2 ? r16Winners : Array(orderedIds.prefix(8))
            newFixtures.append(contentsOf: pairedTies(qualifiers: qualifiers, stage: round, baseWeek: baseWeek))

        case "Semi-Final":
            let qfWinners = knockoutWinners(from: "Quarter-Final")
            let qualifiers = qfWinners.count >= 2 ? qfWinners : Array(orderedIds.prefix(4))
            newFixtures.append(contentsOf: pairedTies(qualifiers: qualifiers, stage: round, baseWeek: baseWeek))

        case "Final":
            let sfWinners = knockoutWinners(from: "Semi-Final")
            let finalists = sfWinners.count >= 2 ? sfWinners : Array(orderedIds.prefix(2))
            if finalists.count == 2 {
                newFixtures.append(EuropeanFixture(
                    homeClubId: finalists[0],
                    awayClubId: finalists[1],
                    matchweek: baseWeek,
                    stage: round,
                    leg: 0
                ))
            }

        default:
            break
        }

        fixtures.append(contentsOf: newFixtures)
    }

    /// First leg at `home`, second leg at `away`.
    private func twoLeggedTie(home: UUID, away: UUID, stage: String, baseWeek: Int) -> [EuropeanFixture] {
        [
            EuropeanFixture(homeClubId: home, awayClubId: away, matchweek: baseWeek, stage: stage, leg: 1),
            EuropeanFixture(homeClubId: away, awayClubId: home, matchweek: baseWeek + 1, stage: stage, leg: 2)
        ]
    }

    /// Seeded two-legged ties pairing each home seed with the corresponding away seed.
    private func seededTies(home: [UUID], away: [UUID], stage: String, baseWeek: Int) -> [EuropeanFixture] {
        let pairCount = min(home.count, away.count)
        guard pairCount >= 2 else { return [] }
        var ties: [EuropeanFixture] = []
        for i in 0..<pairCount {
            ties.append(contentsOf: twoLeggedTie(home: home[i], away: away[i], stage: stage, baseWeek: baseWeek))
        }
        return ties
    }

    /// Two-legged ties pairing qualifiers in order: 1st v 2nd, 3rd v 4th, …
    private func pairedTies(qualifiers: [UUID], stage: String, baseWeek: Int) -> [EuropeanFixture] {
        guard qualifiers.count >= 2 else { return [] }
        var ties: [EuropeanFixture] = []
        for i in stride(from: 0, to: qualifiers.count - 1, by: 2) {
            ties.append(contentsOf: twoLeggedTie(
                home: qualifiers[i],
                away: qualifiers[i + 1],
                stage: stage,
                baseWeek: baseWeek
            ))
        }
        return ties
    }

    /// Returns the ordered winners of every completed knockout round tie. Ties
    /// with an unplayed leg are ignored so a partially simulated round cannot
    /// produce a phantom winner.
    private func knockoutWinners(from stage: String) -> [UUID] {
        let roundFixtures = fixtures.filter { $0.stage == stage }
        var seen = Set<UUID>()
        var winners: [UUID] = []
        for f in roundFixtures {
            if seen.contains(f.homeClubId) { continue }
            let a = f.homeClubId, b = f.awayClubId
            seen.insert(a); seen.insert(b)

            let legs = roundFixtures.filter {
                ($0.homeClubId == a && $0.awayClubId == b) ||
                ($0.homeClubId == b && $0.awayClubId == a)
            }
            guard !legs.isEmpty, legs.allSatisfy({ $0.isPlayed }) else { continue }
            winners.append(tieWinner(first: a, second: b, stage: stage))
        }
        return winners
    }
}
