//
//  InternationalTournament.swift
//  GridironFC
//
//  International tournaments contested by national teams: the FIFA World Cup
//  plus the continental championships (EURO, Copa América, AFCON, Asian Cup).
//  Modelled as a group stage followed by a single-elimination knockout bracket.
//

import Foundation

public enum InternationalTournament {

    public enum Kind: String, Codable, CaseIterable, Identifiable, Hashable {
        case worldCup
        case euro
        case copaAmerica
        case africaCupOfNations
        case asianCup

        public var id: String { rawValue }

        public var displayName: String {
            switch self {
            case .worldCup: return "FIFA World Cup"
            case .euro: return "UEFA European Championship"
            case .copaAmerica: return "Copa América"
            case .africaCupOfNations: return "Africa Cup of Nations"
            case .asianCup: return "AFC Asian Cup"
            }
        }

        public var shortName: String {
            switch self {
            case .worldCup: return "World Cup"
            case .euro: return "EURO"
            case .copaAmerica: return "Copa América"
            case .africaCupOfNations: return "AFCON"
            case .asianCup: return "Asian Cup"
            }
        }

        /// Confederation whose members contest this tournament (nil = whole world).
        public var confederation: Confederation? {
            switch self {
            case .worldCup: return nil
            case .euro: return .uefa
            case .copaAmerica: return .conmebol
            case .africaCupOfNations: return .caf
            case .asianCup: return .afc
            }
        }

        /// Field size (number of nations).
        public var teamCount: Int {
            switch self {
            case .worldCup: return 32
            case .euro: return 24
            case .copaAmerica: return 16
            case .africaCupOfNations: return 24
            case .asianCup: return 24
            }
        }

        /// Teams per group.
        public var groupSize: Int { 4 }

        public var groupCount: Int { teamCount / groupSize }
    }

    // MARK: - Group row

    public struct GroupRow: Codable, Identifiable, Hashable {
        public var id: String { teamId }
        public var teamId: String
        public var played: Int
        public var won: Int
        public var drawn: Int
        public var lost: Int
        public var goalsFor: Int
        public var goalsAgainst: Int
        public var goalDifference: Int { goalsFor - goalsAgainst }
        public var points: Int

        public init(teamId: String) {
            self.teamId = teamId
            played = 0; won = 0; drawn = 0; lost = 0
            goalsFor = 0; goalsAgainst = 0; points = 0
        }

        public mutating func record(goalsFor gf: Int, goalsAgainst ga: Int) {
            played += 1
            goalsFor += gf
            goalsAgainst += ga
            if gf > ga { won += 1; points += 3 }
            else if gf == ga { drawn += 1; points += 1 }
            else { lost += 1 }
        }

        public static func sort(_ a: GroupRow, _ b: GroupRow) -> Bool {
            if a.points != b.points { return a.points > b.points }
            if a.goalDifference != b.goalDifference { return a.goalDifference > b.goalDifference }
            if a.goalsFor != b.goalsFor { return a.goalsFor > b.goalsFor }
            return a.won > b.won
        }
    }

    // MARK: - Fixture

    public struct Fixture: Codable, Identifiable, Hashable {
        public var id: UUID
        public var homeTeamId: String
        public var awayTeamId: String
        public var stage: String        // "Group A" … "Round of 16", "Final"
        public var isPlayed: Bool
        public var homeGoals: Int
        public var awayGoals: Int

        public init(
            id: UUID = UUID(),
            homeTeamId: String,
            awayTeamId: String,
            stage: String,
            isPlayed: Bool = false,
            homeGoals: Int = 0,
            awayGoals: Int = 0
        ) {
            self.id = id
            self.homeTeamId = homeTeamId
            self.awayTeamId = awayTeamId
            self.stage = stage
            self.isPlayed = isPlayed
            self.homeGoals = homeGoals
            self.awayGoals = awayGoals
        }
    }

    // MARK: - Tournament state

    public struct State: Codable, Identifiable, Hashable {
        public var id: UUID
        public var kind: Kind
        public var stage: Stage
        public var participantIds: [String]
        public var groupAssignments: [String: [String]]   // groupId -> teamIds
        public var fixtures: [Fixture]
        public var championId: String?

        public enum Stage: String, Codable, Hashable {
            case groupStage
            case knockout
            case complete
        }

        public init(
            id: UUID = UUID(),
            kind: Kind,
            stage: Stage = .groupStage,
            participantIds: [String] = [],
            groupAssignments: [String: [String]] = [:],
            fixtures: [Fixture] = [],
            championId: String? = nil
        ) {
            self.id = id
            self.kind = kind
            self.stage = stage
            self.participantIds = participantIds
            self.groupAssignments = groupAssignments
            self.fixtures = fixtures
            self.championId = championId
        }

        /// Ordered group names, e.g. ["Group A", "Group B", …].
        public var groupNames: [String] {
            groupAssignments.keys.sorted()
        }

        /// Computes the table for a given group.
        public func table(forGroup group: String) -> [GroupRow] {
            guard let teamIds = groupAssignments[group] else { return [] }
            var rows: [String: GroupRow] = [:]
            for id in teamIds { rows[id] = GroupRow(teamId: id) }
            for f in fixtures where f.stage == group {
                guard f.isPlayed else { continue }
                rows[f.homeTeamId]?.record(goalsFor: f.homeGoals, goalsAgainst: f.awayGoals)
                rows[f.awayTeamId]?.record(goalsFor: f.awayGoals, goalsAgainst: f.homeGoals)
            }
            return rows.values.sorted(by: GroupRow.sort)
        }

        public var groupStageComplete: Bool {
            let groupFixtures = fixtures.filter { $0.stage.hasPrefix("Group ") }
            return !groupFixtures.isEmpty && groupFixtures.allSatisfy { $0.isPlayed }
        }

        /// Number of qualifiers that contest the knockout bracket. The bracket
        /// always uses a power-of-two field (4, 8 or 16) so every round can be
        /// completed without byes.
        private var knockoutFieldSize: Int {
            let available = groupQualifiers().count
            if available >= 16 { return 16 }
            if available >= 8 { return 8 }
            if available >= 4 { return 4 }
            return 0
        }

        /// The knockout round currently in progress, if any.
        public var activeKnockoutRound: String? {
            let rounds: [String]
            switch knockoutFieldSize {
            case 16...:
                rounds = Self.knockoutOrder
            case 8:
                rounds = ["Quarter-Final", "Semi-Final", "Third Place", "Final"]
            case 4:
                rounds = ["Semi-Final", "Third Place", "Final"]
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

        public var currentRoundComplete: Bool {
            guard let round = activeKnockoutRound else { return false }
            let fixturesForRound = fixtures.filter { $0.stage == round }
            return !fixturesForRound.isEmpty && fixturesForRound.allSatisfy { $0.isPlayed }
        }

        static let knockoutOrder = ["Round of 16", "Quarter-Final", "Semi-Final", "Third Place", "Final"]

        /// Simulates every unplayed fixture once and rolls the tournament forward.
        public mutating func simulateAll(simulate: (String, String) -> (Int, Int)) {
            for idx in fixtures.indices where !fixtures[idx].isPlayed {
                let (hg, ag) = simulate(fixtures[idx].homeTeamId, fixtures[idx].awayTeamId)
                fixtures[idx].homeGoals = hg
                fixtures[idx].awayGoals = ag
                fixtures[idx].isPlayed = true
            }

            if stage == .groupStage {
                guard groupStageComplete else { return }
                stage = .knockout
                generateNextKnockoutRound()
                return
            }

            guard stage == .knockout else { return }

            // The active round can legitimately have no fixtures when the previous
            // round has just finished; generate it now instead of waiting forever.
            guard let round = activeKnockoutRound else {
                finishTournament()
                return
            }
            let roundFixtures = fixtures.filter { $0.stage == round }
            if roundFixtures.isEmpty || roundFixtures.allSatisfy({ $0.isPlayed }) {
                generateNextKnockoutRound()
            }
        }

        private mutating func finishTournament() {
            guard stage != .complete else { return }
            stage = .complete
            guard let final = fixtures.first(where: { $0.stage == "Final" && $0.isPlayed }) else { return }
            let ranked = participantIds
            let ranking: (String) -> Int = { id in ranked.firstIndex(of: id) ?? 999 }
            championId = tieWinner(final.homeTeamId, final.awayTeamId, stage: "Final", ranking: ranking)
        }

        /// Winner of a single-elimination tie (draws resolved by higher-ranked team).
        private func tieWinner(_ a: String, _ b: String, stage: String, ranking: (String) -> Int) -> String {
            guard let f = fixtures.first(where: {
                $0.stage == stage && $0.isPlayed &&
                (($0.homeTeamId == a && $0.awayTeamId == b) || ($0.homeTeamId == b && $0.awayTeamId == a))
            }) else { return a }
            if f.homeGoals > f.awayGoals { return f.homeTeamId }
            if f.awayGoals > f.homeGoals { return f.awayTeamId }
            return ranking(a) <= ranking(b) ? a : b
        }

        private mutating func generateNextKnockoutRound() {
            guard let round = activeKnockoutRound else {
                finishTournament()
                return
            }

            var newFixtures: [Fixture] = []
            // `participantIds` is seeded in FIFA-ranking order by the builder, so
            // it doubles as the tie-break ranking for drawn knockout matches.
            let ranked = participantIds
            let ranking: (String) -> Int = { id in ranked.firstIndex(of: id) ?? 999 }

            switch round {
            case "Round of 16":
                let qualifiers = Array(groupQualifiers().prefix(16))
                guard qualifiers.count >= 16 else { return }
                let winners = Array(qualifiers.prefix(8))
                let runnersUp = Array(qualifiers.suffix(8))
                for i in 0..<8 {
                    let home = winners[i]
                    let away = runnersUp[(i + 1) % runnersUp.count]
                    newFixtures.append(Fixture(homeTeamId: home, awayTeamId: away, stage: round))
                }

            case "Quarter-Final":
                let contenders: [String]
                if fixtures.contains(where: { $0.stage == "Round of 16" }) {
                    contenders = knockoutWinners(from: "Round of 16", ranking: ranking)
                } else {
                    contenders = Array(groupQualifiers().prefix(8))
                }
                guard contenders.count >= 4 else { return }
                let field = Array(contenders.prefix(8))
                for i in 0..<(field.count / 2) {
                    newFixtures.append(
                        Fixture(homeTeamId: field[i], awayTeamId: field[field.count - 1 - i], stage: round)
                    )
                }

            case "Semi-Final":
                let contenders: [String]
                if fixtures.contains(where: { $0.stage == "Quarter-Final" }) {
                    contenders = knockoutWinners(from: "Quarter-Final", ranking: ranking)
                } else {
                    contenders = Array(groupQualifiers().prefix(4))
                }
                guard contenders.count >= 4 else { return }
                let field = Array(contenders.prefix(4))
                for i in 0..<(field.count / 2) {
                    newFixtures.append(
                        Fixture(homeTeamId: field[i], awayTeamId: field[field.count - 1 - i], stage: round)
                    )
                }

            case "Third Place":
                let losers = knockoutLosers(from: "Semi-Final", ranking: ranking)
                if losers.count >= 2 {
                    newFixtures.append(Fixture(homeTeamId: losers[0], awayTeamId: losers[1], stage: round))
                }

            case "Final":
                let winners = knockoutWinners(from: "Semi-Final", ranking: ranking)
                if winners.count >= 2 {
                    newFixtures.append(Fixture(homeTeamId: winners[0], awayTeamId: winners[1], stage: round))
                }

            default:
                break
            }

            fixtures.append(contentsOf: newFixtures)
        }

        /// All qualifiers (winners then runners-up) across every group.
        private func groupQualifiers() -> [String] {
            var winners: [String] = []
            var runnersUp: [String] = []
            var thirdPlaced: [GroupRow] = []
            for group in groupNames {
                let table = table(forGroup: group)
                if table.count >= 1 { winners.append(table[0].teamId) }
                if table.count >= 2 { runnersUp.append(table[1].teamId) }
                if table.count >= 3 { thirdPlaced.append(table[2]) }
            }
            // If 6 groups (24 teams like EURO/AFCON/Asian Cup), take top 4 third-placed teams
            // to make a full 16-nation knockout bracket.
            if winners.count == 6 && runnersUp.count == 6 {
                let sortedThird = thirdPlaced.sorted(by: GroupRow.sort)
                let bestThird = sortedThird.prefix(4).map { $0.teamId }
                return winners + runnersUp + bestThird
            }
            return winners + runnersUp
        }

        private func knockoutWinners(from stage: String, ranking: (String) -> Int) -> [String] {
            let roundFixtures = fixtures.filter { $0.stage == stage && $0.isPlayed }
            var seen = Set<String>()
            var winners: [String] = []
            for f in roundFixtures {
                if seen.contains(f.homeTeamId) { continue }
                let a = f.homeTeamId, b = f.awayTeamId
                seen.insert(a); seen.insert(b)
                winners.append(tieWinner(a, b, stage: stage, ranking: ranking))
            }
            return winners
        }

        private func knockoutLosers(from stage: String, ranking: (String) -> Int) -> [String] {
            let roundFixtures = fixtures.filter { $0.stage == stage && $0.isPlayed }
            var losers: [String] = []
            for f in roundFixtures {
                let winner = tieWinner(f.homeTeamId, f.awayTeamId, stage: stage, ranking: ranking)
                losers.append(winner == f.homeTeamId ? f.awayTeamId : f.homeTeamId)
            }
            return losers
        }
    }
}
