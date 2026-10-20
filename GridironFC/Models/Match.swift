//
//  Match.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Match simulation output models including MatchResult, timeline MatchEvent,
//  and team MatchStats tracking expected goals (xG), possession, and discipline.
//

import Foundation

// MARK: - Match Result

public struct MatchResult: Codable, Identifiable, Hashable {
    public let id: UUID
    public var homeClubId: UUID
    public var awayClubId: UUID
    public var homeGoals: Int
    public var awayGoals: Int
    public var events: [MatchEvent]
    public var matchWeek: Int
    public var competition: String       // e.g., "Premier League", "FA Cup Third Round"
    public var date: String              // "YYYY-MM-DD"
    public var attendance: Int
    public var homeStats: MatchStats
    public var awayStats: MatchStats
    public var playerRatings: [UUID: Double]  // Player UUID -> Match Rating (1.0 to 10.0)
    public var manOfTheMatch: UUID?
    
    public init(
        id: UUID = UUID(),
        homeClubId: UUID,
        awayClubId: UUID,
        homeGoals: Int,
        awayGoals: Int,
        events: [MatchEvent] = [],
        matchWeek: Int,
        competition: String,
        date: String,
        attendance: Int,
        homeStats: MatchStats = .empty,
        awayStats: MatchStats = .empty,
        playerRatings: [UUID: Double] = [:],
        manOfTheMatch: UUID? = nil
    ) {
        self.id = id
        self.homeClubId = homeClubId
        self.awayClubId = awayClubId
        self.homeGoals = homeGoals
        self.awayGoals = awayGoals
        self.events = events
        self.matchWeek = matchWeek
        self.competition = competition
        self.date = date
        self.attendance = attendance
        self.homeStats = homeStats
        self.awayStats = awayStats
        self.playerRatings = playerRatings
        self.manOfTheMatch = manOfTheMatch
    }
    
    // MARK: - Computed Properties
    
    public var scoreText: String {
        return "\(homeGoals) - \(awayGoals)"
    }
    
    public var isDraw: Bool {
        return homeGoals == awayGoals
    }
    
    public var winnerClubId: UUID? {
        if homeGoals > awayGoals {
            return homeClubId
        } else if awayGoals > homeGoals {
            return awayClubId
        } else {
            return nil
        }
    }
    
    /// Returns "W", "D", or "L" from the vantage point of a designated club.
    public func outcomeLetter(for clubId: UUID) -> String {
        if homeGoals == awayGoals {
            return "D"
        }
        if clubId == homeClubId {
            return homeGoals > awayGoals ? "W" : "L"
        } else if clubId == awayClubId {
            return awayGoals > homeGoals ? "W" : "L"
        }
        return "-"
    }
    
    /// List of goal events recorded during this fixture.
    public var goalEvents: [MatchEvent] {
        return events.filter { $0.type == .goal || $0.type == .ownGoal || $0.type == .penalty }
    }
    
    /// Major timeline highlights for quick post-match reviews.
    public var majorEvents: [MatchEvent] {
        return events.filter { $0.type.isMajorEvent }
    }
}

// MARK: - Match Event

public struct MatchEvent: Codable, Identifiable, Hashable {
    public let id: UUID
    public var minute: Int
    public var type: MatchEventType
    public var clubId: UUID?
    public var playerId: UUID?
    public var assistPlayerId: UUID?
    public var shortText: String        // Single line commentary header (e.g., "⚽ GOAL! B. Fernandes 23'")
    public var detailText: String       // Full expanded narrative description for commentary view
    public var isHomeTeam: Bool
    
    public init(
        id: UUID = UUID(),
        minute: Int,
        type: MatchEventType,
        clubId: UUID? = nil,
        playerId: UUID? = nil,
        assistPlayerId: UUID? = nil,
        shortText: String,
        detailText: String = "",
        isHomeTeam: Bool
    ) {
        self.id = id
        self.minute = minute
        self.type = type
        self.clubId = clubId
        self.playerId = playerId
        self.assistPlayerId = assistPlayerId
        self.shortText = shortText
        self.detailText = detailText.isEmpty ? shortText : detailText
        self.isHomeTeam = isHomeTeam
    }
    
    public var minuteDisplay: String {
        return "\(minute)'"
    }
}

// MARK: - Match Stats

public struct MatchStats: Codable, Hashable {
    public var possession: Double       // Percentage (e.g., 52.4)
    public var shots: Int
    public var shotsOnTarget: Int
    public var corners: Int
    public var fouls: Int
    public var offsides: Int
    public var passAccuracy: Double     // Percentage (e.g., 84.0)
    public var tacklesWon: Int
    public var saves: Int
    public var xG: Double               // Expected goals (e.g., 1.84)
    
    public init(
        possession: Double = 50.0,
        shots: Int = 0,
        shotsOnTarget: Int = 0,
        corners: Int = 0,
        fouls: Int = 0,
        offsides: Int = 0,
        passAccuracy: Double = 80.0,
        tacklesWon: Int = 0,
        saves: Int = 0,
        xG: Double = 0.0
    ) {
        self.possession = possession
        self.shots = shots
        self.shotsOnTarget = shotsOnTarget
        self.corners = corners
        self.fouls = fouls
        self.offsides = offsides
        self.passAccuracy = passAccuracy
        self.tacklesWon = tacklesWon
        self.saves = saves
        self.xG = xG
    }
    
    public static var empty: MatchStats {
        return MatchStats()
    }
}
