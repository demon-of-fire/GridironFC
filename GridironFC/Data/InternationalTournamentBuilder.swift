//
//  InternationalTournamentBuilder.swift
//  GridironFC
//
//  Seeds international tournaments from the loaded national teams: takes the top
//  ranked nations eligible for each competition, draws them into groups, and
//  schedules a round-robin group stage.
//

import Foundation

public enum InternationalTournamentBuilder {

    /// Builds every international tournament from the available national teams.
    public static func build(from teams: [NationalTeam]) -> [InternationalTournament.State] {
        var states: [InternationalTournament.State] = []
        for kind in InternationalTournament.Kind.allCases {
            if let state = build(kind: kind, from: teams) {
                states.append(state)
            }
        }
        return states
    }

    /// Builds a single tournament for the given kind.
    public static func build(kind: InternationalTournament.Kind, from teams: [NationalTeam]) -> InternationalTournament.State? {
        // Eligible nations: matching confederation (or all for the World Cup), ranked.
        let eligible: [NationalTeam]
        if let confederation = kind.confederation {
            eligible = teams.filter { $0.confederation == confederation }
        } else {
            eligible = teams
        }

        let ranked = eligible.sorted { lhs, rhs in
            switch (lhs.fifaRanking, rhs.fifaRanking) {
            case let (l?, r?): return l < r
            case (.some, .none): return true
            case (.none, .some): return false
            default: return lhs.strength > rhs.strength
            }
        }

        let field = Array(ranked.prefix(kind.teamCount))
        guard field.count >= 8 else { return nil }

        // Draw into groups serpentine-style for balanced pools.
        let groupCount = kind.groupCount
        var groups: [[NationalTeam]] = Array(repeating: [], count: groupCount)
        for (i, team) in field.enumerated() {
            let round = i / groupCount
            let slot = (round % 2 == 0) ? (i % groupCount) : (groupCount - 1 - (i % groupCount))
            groups[slot].append(team)
        }

        var assignments: [String: [String]] = [:]
        var fixtures: [InternationalTournament.Fixture] = []

        for (gIdx, group) in groups.enumerated() {
            let groupName = "Group \(String(UnicodeScalar(65 + gIdx)!))"
            assignments[groupName] = group.map { $0.id }
            fixtures.append(contentsOf: roundRobin(group.map { $0.id }, stage: groupName))
        }

        return InternationalTournament.State(
            kind: kind,
            stage: .groupStage,
            participantIds: field.map { $0.id },
            groupAssignments: assignments,
            fixtures: fixtures
        )
    }

    /// Round-robin fixtures for a 4-team group (6 matches).
    private static func roundRobin(_ ids: [String], stage: String) -> [InternationalTournament.Fixture] {
        var fixtures: [InternationalTournament.Fixture] = []
        for i in 0..<ids.count {
            for j in (i + 1)..<ids.count {
                fixtures.append(InternationalTournament.Fixture(homeTeamId: ids[i], awayTeamId: ids[j], stage: stage))
            }
        }
        return fixtures
    }
}
