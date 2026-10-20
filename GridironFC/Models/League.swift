//
//  League.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  League structures, seasonal schedules, round-robin fixture generation,
//  and dynamic league table standings calculations.
//

import Foundation

// MARK: - League Model

public struct League: Codable, Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var tier: LeagueTier
    public var clubIds: [UUID]
    
    public init(
        id: UUID = UUID(),
        name: String,
        tier: LeagueTier,
        clubIds: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.tier = tier
        self.clubIds = clubIds
    }
}

// MARK: - Season Model

public struct Season: Codable, Hashable {
    public var year: String                 // e.g., "2026-27"
    public var currentWeek: Int             // Matchweek index (1 to 46)
    public var currentPhase: SeasonPhase
    public var fixtures: [Fixture]
    public var currentDate: String          // In-game calendar date "YYYY-MM-DD"
    
    public init(
        year: String = "2026-27",
        currentWeek: Int = 1,
        currentPhase: SeasonPhase = .inSeason,
        fixtures: [Fixture] = [],
        currentDate: String = "2026-08-08"
    ) {
        self.year = year
        self.currentWeek = currentWeek
        self.currentPhase = currentPhase
        self.fixtures = fixtures
        self.currentDate = currentDate
    }
    
    // MARK: - Fixture Queries
    
    public func fixtures(forWeek week: Int) -> [Fixture] {
        return fixtures.filter { $0.matchWeek == week }
    }
    
    public var currentWeekFixtures: [Fixture] {
        return fixtures(forWeek: currentWeek)
    }
    
    public func upcomingFixtures(forClub clubId: UUID) -> [Fixture] {
        return fixtures
            .filter { $0.involves(clubId: clubId) && !$0.isPlayed }
            .sorted { $0.matchWeek < $1.matchWeek }
    }
    
    public func completedFixtures(forClub clubId: UUID) -> [Fixture] {
        return fixtures
            .filter { $0.involves(clubId: clubId) && $0.isPlayed }
            .sorted { $0.matchWeek < $1.matchWeek }
    }
    
    public func nextFixture(forClub clubId: UUID) -> Fixture? {
        return upcomingFixtures(forClub: clubId).first
    }
    
    public var totalMatchWeeks: Int {
        return fixtures.map { $0.matchWeek }.max() ?? 38
    }
    
    public var isSeasonFinished: Bool {
        return currentWeek > totalMatchWeeks
    }
}

// MARK: - Fixture Model

public struct Fixture: Codable, Identifiable, Hashable {
    public let id: UUID
    public var homeClubId: UUID
    public var awayClubId: UUID
    public var matchWeek: Int
    public var date: String                 // "YYYY-MM-DD"
    public var competition: String
    public var isPlayed: Bool
    public var result: MatchResult?
    
    public init(
        id: UUID = UUID(),
        homeClubId: UUID,
        awayClubId: UUID,
        matchWeek: Int,
        date: String,
        competition: String,
        isPlayed: Bool = false,
        result: MatchResult? = nil
    ) {
        self.id = id
        self.homeClubId = homeClubId
        self.awayClubId = awayClubId
        self.matchWeek = matchWeek
        self.date = date
        self.competition = competition
        self.isPlayed = isPlayed
        self.result = result
    }
    
    public func involves(clubId: UUID) -> Bool {
        return homeClubId == clubId || awayClubId == clubId
    }
    
    public func opponentId(for clubId: UUID) -> UUID? {
        if homeClubId == clubId { return awayClubId }
        if awayClubId == clubId { return homeClubId }
        return nil
    }
}

// MARK: - League Standing

public struct LeagueStanding: Codable, Hashable, Identifiable {
    public var id: UUID { clubId }
    public var clubId: UUID
    public var played: Int
    public var won: Int
    public var drawn: Int
    public var lost: Int
    public var goalsFor: Int
    public var goalsAgainst: Int
    public var goalDifference: Int
    public var points: Int
    public var form: [String]               // Last 5 outcomes: ["W", "D", "L", "W", "W"]
    
    public init(
        clubId: UUID,
        played: Int = 0,
        won: Int = 0,
        drawn: Int = 0,
        lost: Int = 0,
        goalsFor: Int = 0,
        goalsAgainst: Int = 0,
        goalDifference: Int = 0,
        points: Int = 0,
        form: [String] = []
    ) {
        self.clubId = clubId
        self.played = played
        self.won = won
        self.drawn = drawn
        self.lost = lost
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
        self.goalDifference = goalDifference
        self.points = points
        self.form = form
    }
    
    /// Records a single match outcome into this standing record.
    public mutating func recordResult(goalsFor: Int, goalsAgainst: Int) {
        self.played += 1
        self.goalsFor += goalsFor
        self.goalsAgainst += goalsAgainst
        self.goalDifference = self.goalsFor - self.goalsAgainst
        
        if goalsFor > goalsAgainst {
            self.won += 1
            self.points += 3
            appendForm("W")
        } else if goalsFor == goalsAgainst {
            self.drawn += 1
            self.points += 1
            appendForm("D")
        } else {
            self.lost += 1
            appendForm("L")
        }
    }
    
    private mutating func appendForm(_ resultLetter: String) {
        form.append(resultLetter)
        if form.count > 5 {
            form.removeFirst()
        }
    }
    
    /// Sorting comparator standard for association football tables.
    public static func standardSort(lhs: LeagueStanding, rhs: LeagueStanding) -> Bool {
        if lhs.points != rhs.points {
            return lhs.points > rhs.points
        }
        if lhs.goalDifference != rhs.goalDifference {
            return lhs.goalDifference > rhs.goalDifference
        }
        if lhs.goalsFor != rhs.goalsFor {
            return lhs.goalsFor > rhs.goalsFor
        }
        return lhs.won > rhs.won
    }
}

// MARK: - Fixture Generator

public struct FixtureGenerator {
    
    /// Generates a complete double round-robin schedule for a given set of club IDs.
    /// Every club plays every other club exactly once at home and once away.
    public static func generateDoubleRoundRobin(
        clubIds: [UUID],
        competitionName: String,
        startDateString: String = "2024-08-10"
    ) -> [Fixture] {
        var clubs = clubIds
        if clubs.count % 2 != 0 {
            // Need even number of teams for standard round robin
            return []
        }
        
        let n = clubs.count
        let singleRounds = n - 1
        let matchesPerRound = n / 2
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let baseDate = dateFormatter.date(from: startDateString) ?? Date()
        let calendar = Calendar.current
        
        var generatedFixtures: [Fixture] = []
        
        // Use polygon rotation method
        // Keep clubs[0] stationary, rotate clubs[1..<n]
        var rotatingClubs = Array(clubs[1...])
        
        // 1. Generate First Half of the Season (Rounds 1 to n-1)
        for round in 1...singleRounds {
            let roundDate = calendar.date(byAdding: .day, value: (round - 1) * 7, to: baseDate) ?? baseDate
            let dateStr = dateFormatter.string(from: roundDate)
            
            for match in 0..<matchesPerRound {
                let home: UUID
                let away: UUID
                
                if match == 0 {
                    // Match against the stationary club
                    let opponent = rotatingClubs[0]
                    if round % 2 == 1 {
                        home = clubs[0]
                        away = opponent
                    } else {
                        home = opponent
                        away = clubs[0]
                    }
                } else {
                    let teamA = rotatingClubs[match]
                    let teamB = rotatingClubs[rotatingClubs.count - match]
                    if match % 2 == 1 {
                        home = teamA
                        away = teamB
                    } else {
                        home = teamB
                        away = teamA
                    }
                }
                
                generatedFixtures.append(
                    Fixture(
                        homeClubId: home,
                        awayClubId: away,
                        matchWeek: round,
                        date: dateStr,
                        competition: competitionName
                    )
                )
            }
            
            // Rotate circular array (last element moves to index 0)
            if let last = rotatingClubs.popLast() {
                rotatingClubs.insert(last, at: 0)
            }
        }
        
        // 2. Generate Second Half of the Season (Rounds n to 2*(n-1))
        // Mirrors first half with inverted venues
        for round in 1...singleRounds {
            let secondHalfWeek = round + singleRounds
            let roundDate = calendar.date(byAdding: .day, value: (secondHalfWeek - 1) * 7, to: baseDate) ?? baseDate
            let dateStr = dateFormatter.string(from: roundDate)
            
            let firstHalfMatches = generatedFixtures.filter { $0.matchWeek == round }
            for match in firstHalfMatches {
                generatedFixtures.append(
                    Fixture(
                        homeClubId: match.awayClubId, // Inverted
                        awayClubId: match.homeClubId, // Inverted
                        matchWeek: secondHalfWeek,
                        date: dateStr,
                        competition: competitionName
                    )
                )
            }
        }
        
        return generatedFixtures
    }
}
