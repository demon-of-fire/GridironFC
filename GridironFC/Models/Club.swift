//
//  Club.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Club model encompassing squad personnel, tactical instructions, club finances,
//  staff management, facility upgrades, and historical season results.
//

import Foundation

// MARK: - Club Model

public struct Club: Codable, Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var shortName: String          // Standard 3-letter abbreviation (e.g., "ARS", "MUN")
    public var stadium: String
    public var stadiumCapacity: Int
    public var city: String
    public var primaryColor: String        // Hex code (e.g., "#EF0107")
    public var secondaryColor: String      // Hex code (e.g., "#FFFFFF")
    public var leagueTier: LeagueTier
    public var reputation: Int             // Scale 1 - 100
    public var isUserClub: Bool
    
    public var players: [Player]
    public var manager: String
    
    // Financial Standing
    public var finances: ClubFinances
    
    // Coaching & Scouting Staff
    public var staff: [StaffMember]
    
    // Club Infrastructure Levels (1 - 5)
    public var trainingFacilityLevel: Int
    public var youthAcademyLevel: Int
    public var medicalFacilityLevel: Int
    
    // Strategic & In-Match Setup
    public var tactics: Tactics
    
    // Completed Match Logs
    public var seasonResults: [MatchResult]
    
    // MARK: - Initializer
    
    public init(
        id: UUID = UUID(),
        name: String,
        shortName: String,
        stadium: String,
        stadiumCapacity: Int,
        city: String,
        primaryColor: String,
        secondaryColor: String,
        leagueTier: LeagueTier,
        reputation: Int,
        isUserClub: Bool = false,
        players: [Player] = [],
        manager: String = "Manager",
        finances: ClubFinances? = nil,
        staff: [StaffMember] = [],
        trainingFacilityLevel: Int = 2,
        youthAcademyLevel: Int = 2,
        medicalFacilityLevel: Int = 2,
        tactics: Tactics? = nil,
        seasonResults: [MatchResult] = []
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.stadium = stadium
        self.stadiumCapacity = stadiumCapacity
        self.city = city
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.leagueTier = leagueTier
        self.reputation = reputation
        self.isUserClub = isUserClub
        self.players = players
        self.manager = manager
        
        let initialFinances = finances ?? ClubFinances.defaultFor(tier: leagueTier)
        self.finances = initialFinances
        
        self.staff = staff.isEmpty ? StaffMember.defaultStaffFor(tier: leagueTier) : staff
        self.trainingFacilityLevel = trainingFacilityLevel
        self.youthAcademyLevel = youthAcademyLevel
        self.medicalFacilityLevel = medicalFacilityLevel
        self.tactics = tactics ?? Tactics.defaultTactics
        self.seasonResults = seasonResults
        
        // Synchronize initial wage bill & pick lineup if players are provided
        self.finances.currentWageBill = self.totalWeeklyWageBill
        if !players.isEmpty && self.tactics.startingXI.isEmpty {
            self.autoPickStartingXI()
        }
    }
    
    // MARK: - Squad Query Helpers
    
    /// Players currently assigned to the starting XI in order.
    public var startingXIPlayers: [Player] {
        return tactics.startingXI.compactMap { id in
            players.first { $0.id == id }
        }
    }
    
    /// Players assigned to the bench.
    public var substitutePlayers: [Player] {
        return tactics.substitutes.compactMap { id in
            players.first { $0.id == id }
        }
    }
    
    /// Players unassigned to starting XI or substitutes.
    public var reservePlayers: [Player] {
        let matchdayIds = Set(tactics.startingXI + tactics.substitutes)
        return players.filter { !matchdayIds.contains($0.id) }
    }
    
    /// Available players without injuries or active suspensions.
    public var availablePlayers: [Player] {
        return players.filter { $0.isAvailable }
    }
    
    public var injuredPlayers: [Player] {
        return players.filter { $0.isInjured }
    }
    
    public var suspendedPlayers: [Player] {
        return players.filter { $0.isSuspended }
    }
    
    public var squadSize: Int {
        return players.count
    }
    
    /// Total weekly wage obligation (all players + coaching staff).
    public var totalWeeklyWageBill: Int {
        return totalPlayerWageBill + totalStaffWageBill
    }
    
    public var totalPlayerWageBill: Int {
        return players.reduce(0) { $0 + ($1.contract?.wage ?? 0) }
    }
    
    public var totalStaffWageBill: Int {
        return staff.reduce(0) { $0 + $1.wage }
    }
    
    /// Mean overall rating across the entire registered squad.
    public var squadAverageOverall: Double {
        guard !players.isEmpty else { return 50.0 }
        let total = players.reduce(0) { $0 + $1.overall }
        return Double(total) / Double(players.count)
    }
    
    /// Mean overall rating of the starting 11 players.
    public var startingXIAverageOverall: Double {
        let xi = startingXIPlayers
        guard !xi.isEmpty else { return squadAverageOverall }
        let total = xi.reduce(0) { $0 + $1.overall }
        return Double(total) / Double(xi.count)
    }
    
    // MARK: - Player Access & Mutation
    
    public func player(withId id: UUID) -> Player? {
        return players.first { $0.id == id }
    }
    
    public mutating func updatePlayer(_ updated: Player) {
        if let idx = players.firstIndex(where: { $0.id == updated.id }) {
            players[idx] = updated
            finances.currentWageBill = totalWeeklyWageBill
        }
    }
    
    public mutating func addPlayer(_ newPlayer: Player) {
        if !players.contains(where: { $0.id == newPlayer.id }) {
            players.append(newPlayer)
            finances.currentWageBill = totalWeeklyWageBill
        }
    }
    
    @discardableResult
    public mutating func removePlayer(withId id: UUID) -> Player? {
        guard let idx = players.firstIndex(where: { $0.id == id }) else { return nil }
        let removed = players.remove(at: idx)
        
        tactics.startingXI.removeAll { $0 == id }
        tactics.substitutes.removeAll { $0 == id }
        if tactics.captain == id { tactics.captain = nil }
        if tactics.cornerTaker == id { tactics.cornerTaker = nil }
        if tactics.freeKickTaker == id { tactics.freeKickTaker = nil }
        if tactics.penaltyTaker == id { tactics.penaltyTaker = nil }
        
        finances.currentWageBill = totalWeeklyWageBill
        return removed
    }
    
    // MARK: - Lineup & Tactical Intelligence
    
    /// Automatically selects the optimal 11 starters and bench players matching the current formation preset.
    public mutating func autoPickStartingXI() {
        var selectedStarters: [UUID] = []
        var pool = availablePlayers
        
        let requiredPositions = tactics.formation.defaultPositions
        
        // 1. Fill each designated position with the best suited player available
        for targetPos in requiredPositions {
            // Find best exact match
            if let bestIdx = pool.firstIndex(where: { $0.positions.contains(targetPos) }) {
                let chosen = pool.remove(at: bestIdx)
                selectedStarters.append(chosen.id)
            } else if let bestCatIdx = pool.firstIndex(where: { $0.primaryPosition.category == targetPos.category }) {
                // Secondary fallback: same general position category
                let chosen = pool.remove(at: bestCatIdx)
                selectedStarters.append(chosen.id)
            } else if !pool.isEmpty {
                // Fallback to highest overall player remaining (excluding GKs unless slot is GK)
                let nonGkPool = pool.filter { targetPos == .GK ? $0.primaryPosition == .GK : $0.primaryPosition != .GK }
                let candidates = nonGkPool.isEmpty ? pool : nonGkPool
                if let bestAny = candidates.max(by: { $0.overall < $1.overall }),
                   let idx = pool.firstIndex(where: { $0.id == bestAny.id }) {
                    let chosen = pool.remove(at: idx)
                    selectedStarters.append(chosen.id)
                }
            }
        }
        
        tactics.startingXI = selectedStarters
        
        // 2. Select up to 7 substitute options (1 backup GK + defenders, midfielders, forwards)
        var subs: [UUID] = []
        
        // Backup GK
        if let backupGkIdx = pool.firstIndex(where: { $0.primaryPosition == .GK }) {
            subs.append(pool.remove(at: backupGkIdx).id)
        }
        
        // Sort remaining by overall rating
        pool.sort { $0.overall > $1.overall }
        while subs.count < 7 && !pool.isEmpty {
            subs.append(pool.removeFirst().id)
        }
        
        tactics.substitutes = subs
        
        // 3. Assign set piece takers & captain if unset
        let starters = startingXIPlayers
        if tactics.captain == nil || !selectedStarters.contains(tactics.captain!) {
            tactics.captain = starters.max(by: { $0.attributes.leadership < $1.attributes.leadership })?.id
        }
        if tactics.penaltyTaker == nil || !selectedStarters.contains(tactics.penaltyTaker!) {
            tactics.penaltyTaker = starters.max(by: { $0.attributes.penalties < $1.attributes.penalties })?.id
        }
        if tactics.freeKickTaker == nil || !selectedStarters.contains(tactics.freeKickTaker!) {
            tactics.freeKickTaker = starters.max(by: { $0.attributes.freeKicks < $1.attributes.freeKicks })?.id
        }
        if tactics.cornerTaker == nil || !selectedStarters.contains(tactics.cornerTaker!) {
            tactics.cornerTaker = starters.max(by: { $0.attributes.crossing < $1.attributes.crossing })?.id
        }
    }
    
    /// Validates and repairs startingXI and bench arrays, removing nonexistent IDs and replenishing if needed.
    public mutating func ensureTacticalIntegrity() {
        let playerIds = Set(players.map { $0.id })
        
        tactics.startingXI.removeAll { !playerIds.contains($0) }
        tactics.substitutes.removeAll { !playerIds.contains($0) }
        
        if tactics.startingXI.count < 11 {
            autoPickStartingXI()
        }
    }
}

// MARK: - Club Finances

public struct ClubFinances: Codable, Hashable {
    public var transferBudget: Int
    public var wageBudget: Int          // Max allowed weekly wage
    public var currentWageBill: Int      // Actual current weekly wage
    public var balance: Int              // Total bank balance
    public var tvIncome: Int             // Annualized TV broadcast rights
    public var matchdayIncome: Int       // Estimated average gate receipts per home match
    public var sponsorshipIncome: Int    // Annualized sponsorship agreements
    public var merchandiseIncome: Int    // Annualized merchandise sales
    
    public init(
        transferBudget: Int,
        wageBudget: Int,
        currentWageBill: Int,
        balance: Int,
        tvIncome: Int,
        matchdayIncome: Int,
        sponsorshipIncome: Int,
        merchandiseIncome: Int
    ) {
        self.transferBudget = transferBudget
        self.wageBudget = wageBudget
        self.currentWageBill = currentWageBill
        self.balance = balance
        self.tvIncome = tvIncome
        self.matchdayIncome = matchdayIncome
        self.sponsorshipIncome = sponsorshipIncome
        self.merchandiseIncome = merchandiseIncome
    }
    
    public var weeklyWageSurplus: Int {
        return wageBudget - currentWageBill
    }
    
    public var isHealthy: Bool {
        return balance >= 0
    }
    
    public var weeklySponsorshipShare: Int {
        return sponsorshipIncome / 52
    }
    
    public var weeklyTvShare: Int {
        return tvIncome / 52
    }
    
    /// Processes weekly financial ledger: payroll debits and steady sponsorship/TV credits.
    public mutating func processWeeklyCashFlow(isHomeMatchThisWeek: Bool = false) {
        let weeklyIncome = weeklySponsorshipShare + weeklyTvShare + (isHomeMatchThisWeek ? matchdayIncome : 0)
        let weeklyExpense = currentWageBill
        balance += (weeklyIncome - weeklyExpense)
    }
    
    public static func defaultFor(tier: LeagueTier) -> ClubFinances {
        switch tier {
        case .premierLeague:
            return ClubFinances(
                transferBudget: 45_000_000,
                wageBudget: 1_800_000,
                currentWageBill: 1_500_000,
                balance: 75_000_000,
                tvIncome: 110_000_000,
                matchdayIncome: 1_400_000,
                sponsorshipIncome: 40_000_000,
                merchandiseIncome: 18_000_000
            )
        case .championship:
            return ClubFinances(
                transferBudget: 8_000_000,
                wageBudget: 350_000,
                currentWageBill: 300_000,
                balance: 14_000_000,
                tvIncome: 10_000_000,
                matchdayIncome: 350_000,
                sponsorshipIncome: 6_000_000,
                merchandiseIncome: 2_500_000
            )
        case .leagueOne:
            return ClubFinances(
                transferBudget: 2_000_000,
                wageBudget: 95_000,
                currentWageBill: 80_000,
                balance: 3_500_000,
                tvIncome: 2_200_000,
                matchdayIncome: 120_000,
                sponsorshipIncome: 1_400_000,
                merchandiseIncome: 600_000
            )
        case .leagueTwo:
            return ClubFinances(
                transferBudget: 500_000,
                wageBudget: 40_000,
                currentWageBill: 35_000,
                balance: 1_200_000,
                tvIncome: 900_000,
                matchdayIncome: 55_000,
                sponsorshipIncome: 450_000,
                merchandiseIncome: 180_000
            )
        case .laLiga, .serieA, .bundesliga, .ligue1:
            return ClubFinances(
                transferBudget: 35_000_000,
                wageBudget: 1_300_000,
                currentWageBill: 1_100_000,
                balance: 55_000_000,
                tvIncome: 80_000_000,
                matchdayIncome: 1_000_000,
                sponsorshipIncome: 30_000_000,
                merchandiseIncome: 12_000_000
            )
        }
    }
}

// MARK: - Staff Member

public struct StaffMember: Codable, Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var role: StaffRole
    public var quality: Int     // 1 to 5 Stars
    public var wage: Int        // Weekly wage in GBP
    
    public init(
        id: UUID = UUID(),
        name: String,
        role: StaffRole,
        quality: Int,
        wage: Int
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.quality = max(1, min(5, quality))
        self.wage = wage
    }
    
    public static func defaultStaffFor(tier: LeagueTier) -> [StaffMember] {
        let baseQuality: Int
        let baseWage: Int
        
        switch tier {
        case .premierLeague:
            baseQuality = 4
            baseWage = 8_000
        case .championship:
            baseQuality = 3
            baseWage = 3_000
        case .leagueOne:
            baseQuality = 2
            baseWage = 1_200
        case .leagueTwo:
            baseQuality = 2
            baseWage = 600
        case .laLiga, .serieA, .bundesliga, .ligue1:
            baseQuality = 4
            baseWage = 7_000
        }
        
        return [
            StaffMember(name: "John Terry", role: .assistantManager, quality: baseQuality, wage: baseWage),
            StaffMember(name: "Michael Carrick", role: .coach, quality: baseQuality, wage: baseWage - 100),
            StaffMember(name: "Steve Walsh", role: .scout, quality: baseQuality, wage: baseWage - 200),
            StaffMember(name: "Gary Lewin", role: .physio, quality: baseQuality, wage: baseWage - 150),
            StaffMember(name: "Neil Bath", role: .youthCoach, quality: baseQuality, wage: baseWage - 200)
        ]
    }
}

// MARK: - Tactics

public struct Tactics: Codable, Hashable {
    public var formation: FormationPreset
    public var mentality: Mentality
    public var pressing: PressingIntensity
    public var tempo: Tempo
    public var width: Width
    public var passingStyle: PassingStyle
    
    public var startingXI: [UUID]     // Array of 11 Player IDs
    public var substitutes: [UUID]    // Array of up to 7 Player IDs
    
    // Set Piece Taker Assignments
    public var cornerTaker: UUID?
    public var freeKickTaker: UUID?
    public var penaltyTaker: UUID?
    public var captain: UUID?
    
    public init(
        formation: FormationPreset = .f442,
        mentality: Mentality = .balanced,
        pressing: PressingIntensity = .medium,
        tempo: Tempo = .normal,
        width: Width = .normal,
        passingStyle: PassingStyle = .mixed,
        startingXI: [UUID] = [],
        substitutes: [UUID] = [],
        cornerTaker: UUID? = nil,
        freeKickTaker: UUID? = nil,
        penaltyTaker: UUID? = nil,
        captain: UUID? = nil
    ) {
        self.formation = formation
        self.mentality = mentality
        self.pressing = pressing
        self.tempo = tempo
        self.width = width
        self.passingStyle = passingStyle
        self.startingXI = startingXI
        self.substitutes = substitutes
        self.cornerTaker = cornerTaker
        self.freeKickTaker = freeKickTaker
        self.penaltyTaker = penaltyTaker
        self.captain = captain
    }
    
    public static var defaultTactics: Tactics {
        return Tactics(
            formation: .f442,
            mentality: .balanced,
            pressing: .medium,
            tempo: .normal,
            width: .normal,
            passingStyle: .mixed
        )
    }
}
