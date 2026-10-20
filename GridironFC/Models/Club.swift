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

    // Youth Academy Prospects (aged 15-18, develop before promotion to the senior squad)
    public var academyProspects: [Player]
    
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
        academyProspects: [Player] = [],
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
        self.academyProspects = academyProspects
        
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
    
    // MARK: - Youth Academy

    public mutating func addProspect(_ prospect: Player) {
        if !academyProspects.contains(where: { $0.id == prospect.id }) {
            academyProspects.append(prospect)
        }
    }

    @discardableResult
    public mutating func promoteProspect(withId id: UUID) -> Player? {
        guard let idx = academyProspects.firstIndex(where: { $0.id == id }) else { return nil }
        let promoted = academyProspects.remove(at: idx)
        addPlayer(promoted)
        return promoted
    }

    @discardableResult
    public mutating func releaseProspect(withId id: UUID) -> Player? {
        guard let idx = academyProspects.firstIndex(where: { $0.id == id }) else { return nil }
        return academyProspects.remove(at: idx)
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

    // MARK: - Codable (tolerant of saves predating the youth academy)

    private enum CodingKeys: String, CodingKey {
        case id, name, shortName, stadium, stadiumCapacity, city
        case primaryColor, secondaryColor, leagueTier, reputation, isUserClub
        case players, manager, academyProspects, finances, staff
        case trainingFacilityLevel, youthAcademyLevel, medicalFacilityLevel
        case tactics, seasonResults
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        shortName = try c.decode(String.self, forKey: .shortName)
        stadium = try c.decode(String.self, forKey: .stadium)
        stadiumCapacity = try c.decode(Int.self, forKey: .stadiumCapacity)
        city = try c.decode(String.self, forKey: .city)
        primaryColor = try c.decode(String.self, forKey: .primaryColor)
        secondaryColor = try c.decode(String.self, forKey: .secondaryColor)
        leagueTier = try c.decode(LeagueTier.self, forKey: .leagueTier)
        reputation = try c.decode(Int.self, forKey: .reputation)
        isUserClub = try c.decode(Bool.self, forKey: .isUserClub)
        players = try c.decode([Player].self, forKey: .players)
        manager = try c.decode(String.self, forKey: .manager)
        academyProspects = try c.decodeIfPresent([Player].self, forKey: .academyProspects) ?? []
        finances = try c.decode(ClubFinances.self, forKey: .finances)
        staff = try c.decode([StaffMember].self, forKey: .staff)
        trainingFacilityLevel = try c.decode(Int.self, forKey: .trainingFacilityLevel)
        youthAcademyLevel = try c.decode(Int.self, forKey: .youthAcademyLevel)
        medicalFacilityLevel = try c.decode(Int.self, forKey: .medicalFacilityLevel)
        tactics = try c.decode(Tactics.self, forKey: .tactics)
        seasonResults = try c.decode([MatchResult].self, forKey: .seasonResults)
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
        // Country strength scales top-flight money; level scales down the pyramid.
        let countryFactor: Double = {
            switch tier.country {
            case .england, .spain, .italy, .germany: return 1.0
            case .france: return 0.75
            case .portugal, .netherlands, .turkey, .scotland, .belgium: return 0.5
            default: return 0.35
            }
        }()
        let levelScale: Double = {
            switch tier.level {
            case 1: return 1.0
            case 2: return 0.18
            case 3: return 0.05
            default: return 0.018
            }
        }()
        let scale = countryFactor * levelScale

        func scaled(_ base: Int) -> Int { Int(Double(base) * scale) }

        return ClubFinances(
            transferBudget: scaled(45_000_000),
            wageBudget: max(8_000, scaled(1_800_000)),
            currentWageBill: max(6_000, scaled(1_500_000)),
            balance: scaled(75_000_000),
            tvIncome: scaled(110_000_000),
            matchdayIncome: max(15_000, scaled(1_400_000)),
            sponsorshipIncome: scaled(40_000_000),
            merchandiseIncome: scaled(18_000_000)
        )
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
        
        switch tier.level {
        case 1: baseQuality = 4; baseWage = 7_000
        case 2: baseQuality = 3; baseWage = 3_000
        case 3: baseQuality = 2; baseWage = 1_200
        default: baseQuality = 2; baseWage = 600
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
