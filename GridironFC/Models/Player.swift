//
//  Player.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Core player model containing detailed technical, physical, mental, and goalkeeping
//  attributes, dynamic fitness/morale conditions, contract terms, and match statistics.
//

import Foundation

// MARK: - Player Model

public struct Player: Codable, Identifiable, Hashable {
    public let id: UUID
    public var firstName: String
    public var lastName: String
    public var nationality: String
    public var age: Int
    public var height: Int          // in cm
    public var weight: Int          // in kg
    public var preferredFoot: Foot
    public var positions: [Position]
    public var squadNumber: Int?
    
    // Attributes (1-99 scale)
    public var attributes: PlayerAttributes
    
    // Ability & Potential
    public var overall: Int
    public var potential: Int
    
    // Dynamic Match-to-Match Conditions
    public var form: [Double]       // Rolling window of last 5 match ratings (1.0 - 10.0)
    public var morale: Morale
    public var matchFitness: Double // 0.0 - 100.0%
    public var sharpness: Double    // 0.0 - 100.0%
    
    // Discipline & Physical Health
    public var injury: Injury?
    public var suspendedMatches: Int
    public var yellowCards: Int     // Accumulated regular season yellow cards
    
    // Season Performance
    public var seasonStats: SeasonStats
    
    // Financial & Valuation
    public var contract: Contract?
    public var value: Int           // Market valuation in GBP
    
    // MARK: - Initializer
    
    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        nationality: String,
        age: Int,
        height: Int,
        weight: Int,
        preferredFoot: Foot,
        positions: [Position],
        squadNumber: Int? = nil,
        attributes: PlayerAttributes,
        overall: Int? = nil,
        potential: Int,
        form: [Double] = [6.5, 6.7, 6.4],
        morale: Morale = .content,
        matchFitness: Double = 100.0,
        sharpness: Double = 90.0,
        injury: Injury? = nil,
        suspendedMatches: Int = 0,
        yellowCards: Int = 0,
        seasonStats: SeasonStats = SeasonStats(),
        contract: Contract? = nil,
        value: Int? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.nationality = nationality
        self.age = age
        self.height = height
        self.weight = weight
        self.preferredFoot = preferredFoot
        self.positions = positions.isEmpty ? [.CM] : positions
        self.squadNumber = squadNumber
        self.attributes = attributes
        
        let primaryPos = positions.first ?? .CM
        let calculatedOverall = overall ?? attributes.calculateOverall(for: primaryPos)
        self.overall = calculatedOverall
        self.potential = max(potential, calculatedOverall)
        
        self.form = form
        self.morale = morale
        self.matchFitness = matchFitness
        self.sharpness = sharpness
        self.injury = injury
        self.suspendedMatches = suspendedMatches
        self.yellowCards = yellowCards
        self.seasonStats = seasonStats
        self.contract = contract
        
        if let explicitValue = value {
            self.value = explicitValue
        } else {
            self.value = Player.calculateMarketValue(overall: calculatedOverall, potential: potential, age: age, position: primaryPos)
        }
    }
    
    // MARK: - Computed Properties
    
    public var displayName: String {
        guard let firstChar = firstName.first else { return lastName }
        return "\(firstChar). \(lastName)"
    }
    
    public var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    public var primaryPosition: Position {
        return positions.first ?? .CM
    }
    
    /// Stable deterministic seed for procedural face generation.
    /// Uses an FNV-1a hash of the UUID string so the face is identical across launches
    /// (unlike Swift's `hashValue`, which is randomized per process).
    public var faceSeed: UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in id.uuidString.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
    
    public var isInjured: Bool {
        return injury != nil
    }
    
    public var isSuspended: Bool {
        return suspendedMatches > 0
    }
    
    public var isAvailable: Bool {
        return !isInjured && !isSuspended
    }
    
    public var averageForm: Double {
        guard !form.isEmpty else { return 6.0 }
        let sum = form.reduce(0.0, +)
        return sum / Double(form.count)
    }
    
    public var wage: Int {
        return contract?.wage ?? 0
    }
    
    public var formattedValue: String {
        return Player.formatCurrency(value)
    }
    
    public var formattedWage: String {
        return "\(Player.formatCurrency(wage))/w"
    }
    
    public var formattedHeight: String {
        return "\(height) cm"
    }
    
    public var formattedWeight: String {
        return "\(weight) kg"
    }
    
    public var statusBadgeText: String {
        if let inj = injury {
            return inj.weeksRemaining > 1 ? "\(inj.type.displayName) (\(inj.weeksRemaining) wks)" : "\(inj.type.displayName) (1 wk)"
        }
        if suspendedMatches > 0 {
            return "Suspended (\(suspendedMatches) \(suspendedMatches == 1 ? "match" : "matches"))"
        }
        if matchFitness < 70 {
            return "Tired (\(Int(matchFitness))%)"
        }
        return "Available"
    }
    
    // MARK: - State Mutation Methods
    
    /// Records match performance data and updates rolling form and seasonal totals.
    public mutating func recordMatch(
        rating: Double,
        minutes: Int,
        goals: Int = 0,
        assists: Int = 0,
        yellowCard: Bool = false,
        redCard: Bool = false,
        cleanSheet: Bool = false,
        isMotm: Bool = false
    ) {
        seasonStats.appearances += 1
        seasonStats.minutesPlayed += minutes
        seasonStats.goals += goals
        seasonStats.assists += assists
        seasonStats.cleanSheets += cleanSheet ? 1 : 0
        seasonStats.manOfTheMatch += isMotm ? 1 : 0
        
        let previousTotalScore = seasonStats.averageRating * Double(seasonStats.appearances - 1)
        seasonStats.averageRating = (previousTotalScore + rating) / Double(seasonStats.appearances)
        
        form.append(rating)
        if form.count > 5 {
            form.removeFirst()
        }
        
        // Fatigue depletion
        let staminaFactor = Double(attributes.stamina) / 100.0
        let fatigueLoss = (Double(minutes) / 90.0) * (30.0 - (staminaFactor * 12.0))
        matchFitness = max(0.0, matchFitness - fatigueLoss)
        sharpness = min(100.0, sharpness + (Double(minutes) / 90.0) * 8.0)
        
        // Disciplinary tracking
        if yellowCard {
            yellowCards += 1
            seasonStats.yellowCards += 1
            if yellowCards % 5 == 0 {
                suspendedMatches += 1
            }
        }
        
        if redCard {
            seasonStats.redCards += 1
            suspendedMatches += 3
        }
        
        // Morale impact from match performance
        if rating >= 8.0 {
            boostMorale()
        } else if rating <= 5.0 {
            dampenMorale()
        }
    }
    
    /// Simulates weekly natural regeneration for fitness, sharpness decay, and injury recovery.
    public mutating func advanceWeekRecovery() {
        if let currentInjury = injury {
            let remaining = currentInjury.weeksRemaining - 1
            if remaining <= 0 {
                self.injury = nil
                self.matchFitness = 65.0
            } else {
                self.injury = Injury(type: currentInjury.type, weeksRemaining: remaining)
            }
        } else {
            // Fitness recovery
            let recoveryRate = 25.0 + (Double(attributes.stamina) * 0.15)
            matchFitness = min(100.0, matchFitness + recoveryRate)
        }
        
        // Sharpness decay if unplayed
        sharpness = max(20.0, sharpness - 4.0)
    }
    
    public mutating func recoverFitness(amount: Double) {
        matchFitness = min(100.0, matchFitness + amount)
    }
    
    public mutating func consumeFitness(amount: Double) {
        matchFitness = max(0.0, matchFitness - amount)
    }
    
    public mutating func boostMorale() {
        switch morale {
        case .furious: morale = .unhappy
        case .unhappy: morale = .content
        case .content: morale = .happy
        case .happy, .delighted: morale = .delighted
        }
    }
    
    public mutating func dampenMorale() {
        switch morale {
        case .delighted: morale = .happy
        case .happy: morale = .content
        case .content: morale = .unhappy
        case .unhappy, .furious: morale = .furious
        }
    }
    
    // MARK: - Currency Formatting Helper
    
    public static func formatCurrency(_ amount: Int) -> String {
        if amount >= 1_000_000 {
            let millions = Double(amount) / 1_000_000.0
            return String(format: "£%.1fM", millions)
        } else if amount >= 1_000 {
            let thousands = amount / 1_000
            return "£\(thousands)K"
        } else {
            return "£\(amount)"
        }
    }
    
    // MARK: - Valuation Calculation
    
    public static func calculateMarketValue(overall: Int, potential: Int, age: Int, position: Position) -> Int {
        var baseValue: Double
        
        switch overall {
        case 85...99:
            baseValue = 50_000_000.0 + Double(overall - 85) * 8_000_000.0
        case 75...84:
            baseValue = 12_000_000.0 + Double(overall - 75) * 3_800_000.0
        case 65...74:
            baseValue = 2_000_000.0 + Double(overall - 65) * 1_000_000.0
        case 55...64:
            baseValue = 350_000.0 + Double(overall - 55) * 165_000.0
        default:
            baseValue = max(20_000.0, Double(overall) * 6_000.0)
        }
        
        // Age factor: youth premium vs twilight discount
        let ageFactor: Double
        if age <= 21 {
            let upside = max(0, potential - overall)
            ageFactor = 1.35 + (Double(upside) * 0.05)
        } else if age <= 25 {
            ageFactor = 1.20
        } else if age <= 29 {
            ageFactor = 1.00
        } else if age <= 32 {
            ageFactor = 0.65
        } else {
            ageFactor = 0.30
        }
        
        // Position scarcity factor
        let posFactor: Double
        switch position {
        case .ST, .CF: posFactor = 1.20
        case .CAM, .LW, .RW, .LM, .RM: posFactor = 1.15
        case .CM, .CDM: posFactor = 1.00
        case .CB, .LB, .RB, .LWB, .RWB: posFactor = 0.90
        case .GK: posFactor = 0.75
        }
        
        let calculated = baseValue * ageFactor * posFactor
        return max(15_000, Int(calculated))
    }
}

// MARK: - Player Attributes

public struct PlayerAttributes: Codable, Hashable {
    // Technical
    public var passing: Int
    public var shooting: Int
    public var dribbling: Int
    public var firstTouch: Int
    public var crossing: Int
    public var freeKicks: Int
    public var penalties: Int
    public var heading: Int
    public var longShots: Int
    public var tackling: Int
    public var marking: Int
    
    // Physical
    public var pace: Int
    public var stamina: Int
    public var strength: Int
    public var agility: Int
    public var jumping: Int
    public var balance: Int
    
    // Mental
    public var vision: Int
    public var composure: Int
    public var decisions: Int
    public var workRate: Int
    public var aggression: Int
    public var leadership: Int
    public var teamwork: Int
    public var positioning: Int
    public var offTheBall: Int
    public var concentration: Int
    
    // Goalkeeping (GK specific)
    public var reflexes: Int
    public var handling: Int
    public var gkPositioning: Int
    public var oneOnOnes: Int
    public var kicking: Int
    public var commandOfArea: Int
    
    public init(
        passing: Int = 50,
        shooting: Int = 50,
        dribbling: Int = 50,
        firstTouch: Int = 50,
        crossing: Int = 50,
        freeKicks: Int = 50,
        penalties: Int = 50,
        heading: Int = 50,
        longShots: Int = 50,
        tackling: Int = 50,
        marking: Int = 50,
        pace: Int = 50,
        stamina: Int = 50,
        strength: Int = 50,
        agility: Int = 50,
        jumping: Int = 50,
        balance: Int = 50,
        vision: Int = 50,
        composure: Int = 50,
        decisions: Int = 50,
        workRate: Int = 50,
        aggression: Int = 50,
        leadership: Int = 50,
        teamwork: Int = 50,
        positioning: Int = 50,
        offTheBall: Int = 50,
        concentration: Int = 50,
        reflexes: Int = 15,
        handling: Int = 15,
        gkPositioning: Int = 15,
        oneOnOnes: Int = 15,
        kicking: Int = 15,
        commandOfArea: Int = 15
    ) {
        self.passing = passing
        self.shooting = shooting
        self.dribbling = dribbling
        self.firstTouch = firstTouch
        self.crossing = crossing
        self.freeKicks = freeKicks
        self.penalties = penalties
        self.heading = heading
        self.longShots = longShots
        self.tackling = tackling
        self.marking = marking
        
        self.pace = pace
        self.stamina = stamina
        self.strength = strength
        self.agility = agility
        self.jumping = jumping
        self.balance = balance
        
        self.vision = vision
        self.composure = composure
        self.decisions = decisions
        self.workRate = workRate
        self.aggression = aggression
        self.leadership = leadership
        self.teamwork = teamwork
        self.positioning = positioning
        self.offTheBall = offTheBall
        self.concentration = concentration
        
        self.reflexes = reflexes
        self.handling = handling
        self.gkPositioning = gkPositioning
        self.oneOnOnes = oneOnOnes
        self.kicking = kicking
        self.commandOfArea = commandOfArea
    }
    
    // MARK: - Category Averages
    
    public var technicalAverage: Double {
        let stats = [passing, shooting, dribbling, firstTouch, crossing, freeKicks, penalties, heading, longShots, tackling, marking]
        return Double(stats.reduce(0, +)) / Double(stats.count)
    }
    
    public var physicalAverage: Double {
        let stats = [pace, stamina, strength, agility, jumping, balance]
        return Double(stats.reduce(0, +)) / Double(stats.count)
    }
    
    public var mentalAverage: Double {
        let stats = [vision, composure, decisions, workRate, aggression, leadership, teamwork, positioning, offTheBall, concentration]
        return Double(stats.reduce(0, +)) / Double(stats.count)
    }
    
    public var gkAverage: Double {
        let stats = [reflexes, handling, gkPositioning, oneOnOnes, kicking, commandOfArea]
        return Double(stats.reduce(0, +)) / Double(stats.count)
    }
    
    // MARK: - Position-Specific Overall Rating Calculation
    
    public func calculateOverall(for position: Position) -> Int {
        let rating: Double
        
        switch position {
        case .GK:
            rating = (Double(reflexes) * 0.28) +
                     (Double(handling) * 0.22) +
                     (Double(gkPositioning) * 0.20) +
                     (Double(oneOnOnes) * 0.12) +
                     (Double(commandOfArea) * 0.10) +
                     (Double(kicking) * 0.08)
            
        case .CB:
            rating = (Double(tackling) * 0.22) +
                     (Double(marking) * 0.18) +
                     (Double(heading) * 0.14) +
                     (Double(strength) * 0.14) +
                     (Double(positioning) * 0.12) +
                     (Double(jumping) * 0.10) +
                     (Double(pace) * 0.10)
            
        case .LB, .RB:
            rating = (Double(pace) * 0.20) +
                     (Double(stamina) * 0.16) +
                     (Double(tackling) * 0.16) +
                     (Double(crossing) * 0.14) +
                     (Double(marking) * 0.12) +
                     (Double(positioning) * 0.12) +
                     (Double(workRate) * 0.10)
            
        case .LWB, .RWB:
            rating = (Double(pace) * 0.22) +
                     (Double(stamina) * 0.18) +
                     (Double(crossing) * 0.18) +
                     (Double(dribbling) * 0.12) +
                     (Double(tackling) * 0.12) +
                     (Double(workRate) * 0.10) +
                     (Double(positioning) * 0.08)
            
        case .CDM:
            rating = (Double(tackling) * 0.20) +
                     (Double(positioning) * 0.16) +
                     (Double(passing) * 0.16) +
                     (Double(stamina) * 0.14) +
                     (Double(marking) * 0.12) +
                     (Double(strength) * 0.12) +
                     (Double(teamwork) * 0.10)
            
        case .CM:
            rating = (Double(passing) * 0.20) +
                     (Double(vision) * 0.16) +
                     (Double(stamina) * 0.14) +
                     (Double(firstTouch) * 0.14) +
                     (Double(dribbling) * 0.12) +
                     (Double(decisions) * 0.12) +
                     (Double(tackling) * 0.12)
            
        case .CAM:
            rating = (Double(vision) * 0.22) +
                     (Double(passing) * 0.20) +
                     (Double(dribbling) * 0.16) +
                     (Double(shooting) * 0.14) +
                     (Double(firstTouch) * 0.14) +
                     (Double(composure) * 0.14)
            
        case .LM, .RM:
            rating = (Double(pace) * 0.22) +
                     (Double(crossing) * 0.18) +
                     (Double(dribbling) * 0.18) +
                     (Double(stamina) * 0.14) +
                     (Double(passing) * 0.14) +
                     (Double(workRate) * 0.14)
            
        case .LW, .RW:
            rating = (Double(pace) * 0.24) +
                     (Double(dribbling) * 0.22) +
                     (Double(crossing) * 0.14) +
                     (Double(shooting) * 0.14) +
                     (Double(agility) * 0.14) +
                     (Double(firstTouch) * 0.12)
            
        case .ST:
            rating = (Double(shooting) * 0.28) +
                     (Double(composure) * 0.18) +
                     (Double(heading) * 0.14) +
                     (Double(offTheBall) * 0.14) +
                     (Double(pace) * 0.14) +
                     (Double(strength) * 0.12)
            
        case .CF:
            rating = (Double(shooting) * 0.24) +
                     (Double(dribbling) * 0.18) +
                     (Double(firstTouch) * 0.18) +
                     (Double(passing) * 0.14) +
                     (Double(vision) * 0.14) +
                     (Double(composure) * 0.12)
        }
        
        return min(99, max(1, Int(round(rating))))
    }
}

// MARK: - Season Stats

public struct SeasonStats: Codable, Hashable {
    public var appearances: Int
    public var goals: Int
    public var assists: Int
    public var cleanSheets: Int
    public var yellowCards: Int
    public var redCards: Int
    public var averageRating: Double
    public var minutesPlayed: Int
    public var manOfTheMatch: Int
    
    public init(
        appearances: Int = 0,
        goals: Int = 0,
        assists: Int = 0,
        cleanSheets: Int = 0,
        yellowCards: Int = 0,
        redCards: Int = 0,
        averageRating: Double = 0.0,
        minutesPlayed: Int = 0,
        manOfTheMatch: Int = 0
    ) {
        self.appearances = appearances
        self.goals = goals
        self.assists = assists
        self.cleanSheets = cleanSheets
        self.yellowCards = yellowCards
        self.redCards = redCards
        self.averageRating = averageRating
        self.minutesPlayed = minutesPlayed
        self.manOfTheMatch = manOfTheMatch
    }
}

// MARK: - Contract

public struct Contract: Codable, Hashable {
    public var wage: Int                  // Weekly in GBP
    public var yearsRemaining: Int
    public var releaseClause: Int?
    public var sellOnPercentage: Double?  // e.g. 0.15 for 15%
    public var signingDate: String        // "YYYY-MM"
    
    public init(
        wage: Int,
        yearsRemaining: Int,
        releaseClause: Int? = nil,
        sellOnPercentage: Double? = nil,
        signingDate: String = "2024-07"
    ) {
        self.wage = wage
        self.yearsRemaining = yearsRemaining
        self.releaseClause = releaseClause
        self.sellOnPercentage = sellOnPercentage
        self.signingDate = signingDate
    }
}

// MARK: - Injury

public struct Injury: Codable, Hashable {
    public var type: InjuryType
    public var weeksRemaining: Int
    
    public init(type: InjuryType, weeksRemaining: Int) {
        self.type = type
        self.weeksRemaining = weeksRemaining
    }
    
    public var description: String {
        return "\(type.displayName) (\(weeksRemaining) \(weeksRemaining == 1 ? "week" : "weeks") remaining)"
    }
}
