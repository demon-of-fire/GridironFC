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

        /// The knockout round currently in progress, if any.
        public var activeKnockoutRound: String? {
            for round in Self.knockoutOrder {
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

            if stage == .groupStage && groupStageComplete {
                stage = .knockout
                generateNextKnockoutRound()
            } else if stage == .knockout && currentRoundComplete {
                generateNextKnockoutRound()
            }
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
                stage = .complete
                if let final = fixtures.first(where: { $0.stage == "Final" && $0.isPlayed }) {
                    championId = final.homeGoals >= final.awayGoals ? final.homeTeamId : final.awayTeamId
                }
                return
            }

            var newFixtures: [Fixture] = []
            let ranked = participantIds.sorted { ($0) < ($1) }   // placeholder ordering
            let ranking: (String) -> Int = { id in ranked.firstIndex(of: id) ?? 999 }

            switch round {
            case "Round of 16":
                let qualifiers = groupQualifiers()
                guard qualifiers.count >= 16 else { return }
                // Pair each group winner with a runner-up from another group.
                let winners = stridedQualifiers(qualifiers, index: 0)
                let runnersUp = stridedQualifiers(qualifiers, index: 1)
                for i in 0..<8 {
                    let home = winners[i]
                    let away = runnersUp[(i + 1) % runnersUp.count]
                    newFixtures.append(Fixture(homeTeamId: home, awayTeamId: away, stage: round))
                }

            case "Quarter-Final", "Semi-Final", "Third Place":
                let prev: String
                switch round {
                case "Quarter-Final": prev = "Round of 16"
                case "Semi-Final": prev = "Quarter-Final"
                default: prev = "Semi-Final"
                }
                let winners = knockoutWinners(from: prev, ranking: ranking)
                if round == "Third Place" {
                    // Losers of the semis; fall back to reusing winners if unavailable.
                    let losers = knockoutLosers(from: "Semi-Final")
                    if losers.count >= 2 {
                        newFixtures.append(Fixture(homeTeamId: losers[0], awayTeamId: losers[1], stage: round))
                    }
                    break
                }
                for i in stride(from: 0, to: winners.count - 1, by: 2) {
                    newFixtures.append(Fixture(homeTeamId: winners[i], awayTeamId: winners[i + 1], stage: round))
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
            for group in groupNames {
                let table = table(forGroup: group)
                if table.count >= 1 { winners.append(table[0].teamId) }
                if table.count >= 2 { runnersUp.append(table[1].teamId) }
            }
            return winners + runnersUp
        }

        private func stridedQualifiers(_ qualifiers: [String], index: Int) -> [String] {
            let half = qualifiers.count / 2
            let winners = Array(qualifiers.prefix(half))
            let runnersUp = Array(qualifiers.suffix(half))
            return index == 0 ? winners : runnersUp
        }

        private func knockoutWinners(from stage: String, ranking: (String) -> Int) -> [String] {
            let roundFixtures = fixtures.filter { $0.stage == stage }
            var seen = Set<String>()
            var winners: [String] = []
            for f in roundFixtures {
                if seen.contains(f.homeTeamId) || f.stage == "Third Place" { continue }
                let a = f.homeTeamId, b = f.awayTeamId
                seen.insert(a); seen.insert(b)
                winners.append(tieWinner(a, b, stage: stage, ranking: ranking))
            }
            return winners
        }

        private func knockoutLosers(from stage: String) -> [String] {
            let roundFixtures = fixtures.filter { $0.stage == stage && $0.isPlayed }
            var losers: [String] = []
            for f in roundFixtures {
                if f.homeGoals > f.awayGoals { losers.append(f.awayTeamId) }
                else if f.awayGoals > f.homeGoals { losers.append(f.homeTeamId) }
            }
            return losers
        }
    }
}
