//
//  Enums.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Complete enumeration definitions governing gameplay, tactical setups,
//  match events, player conditions, and progression state.
//

import Foundation

// MARK: - Position

/// Football field player positions.
public enum Position: String, Codable, CaseIterable, Identifiable, Hashable {
    case GK
    case CB
    case LB
    case RB
    case LWB
    case RWB
    case CDM
    case CM
    case CAM
    case LM
    case RM
    case LW
    case RW
    case ST
    case CF
    
    public var id: String { rawValue }
    
    /// High-level positional category for broad role matching and depth charts.
    public var category: PositionCategory {
        switch self {
        case .GK:
            return .goalkeeper
        case .CB, .LB, .RB, .LWB, .RWB:
            return .defender
        case .CDM, .CM, .CAM, .LM, .RM:
            return .midfielder
        case .LW, .RW, .ST, .CF:
            return .forward
        }
    }
    
    /// User-facing descriptive name for the position.
    public var displayName: String {
        switch self {
        case .GK: return "Goalkeeper"
        case .CB: return "Center Back"
        case .LB: return "Left Back"
        case .RB: return "Right Back"
        case .LWB: return "Left Wing Back"
        case .RWB: return "Right Wing Back"
        case .CDM: return "Defensive Midfielder"
        case .CM: return "Central Midfielder"
        case .CAM: return "Attacking Midfielder"
        case .LM: return "Left Midfielder"
        case .RM: return "Right Midfielder"
        case .LW: return "Left Winger"
        case .RW: return "Right Winger"
        case .ST: return "Striker"
        case .CF: return "Center Forward"
        }
    }
    
    /// Standard 2-3 character positional code.
    public var abbreviation: String {
        return rawValue
    }
    
    /// Flag indicating whether the position plays on the flank.
    public var isWide: Bool {
        switch self {
        case .LB, .RB, .LWB, .RWB, .LM, .RM, .LW, .RW:
            return true
        default:
            return false
        }
    }
    
    /// Flag indicating defensive bias.
    public var isDefensive: Bool {
        return category == .defender || self == .CDM
    }
    
    /// Flag indicating midfield role.
    public var isMidfielder: Bool {
        return category == .midfielder
    }
    
    /// Flag indicating attacking role.
    public var isAttacking: Bool {
        return category == .forward || self == .CAM
    }
    
    /// Flag indicating goalkeeper role.
    public var isGoalkeeper: Bool {
        return self == .GK
    }
}

// MARK: - Position Category

public enum PositionCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case goalkeeper
    case defender
    case midfielder
    case forward
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .goalkeeper: return "Goalkeeper"
        case .defender: return "Defender"
        case .midfielder: return "Midfielder"
        case .forward: return "Forward"
        }
    }
}

// MARK: - Preferred Foot

public enum Foot: String, Codable, CaseIterable, Identifiable, Hashable {
    case left
    case right
    case both
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .both: return "Both (Ambidextrous)"
        }
    }
}

// MARK: - Morale

public enum Morale: String, Codable, CaseIterable, Identifiable, Hashable {
    case delighted
    case happy
    case content
    case unhappy
    case furious
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .delighted: return "Delighted"
        case .happy: return "Happy"
        case .content: return "Content"
        case .unhappy: return "Unhappy"
        case .furious: return "Furious"
        }
    }
    
    /// Performance scaling multiplier applied during match simulation.
    public var performanceMultiplier: Double {
        switch self {
        case .delighted: return 1.10
        case .happy: return 1.05
        case .content: return 1.00
        case .unhappy: return 0.95
        case .furious: return 0.85
        }
    }
    
    /// SF Symbol icon name representing morale state.
    public var iconName: String {
        switch self {
        case .delighted: return "face.smiling.fill"
        case .happy: return "face.smiling"
        case .content: return "face.dashed"
        case .unhappy: return "face.frowning"
        case .furious: return "flame.fill"
        }
    }
}

// MARK: - Injury Type

public enum InjuryType: String, Codable, CaseIterable, Identifiable, Hashable {
    case minorKnock
    case muscleStrain
    case hamstring
    case ankleLigament
    case kneeInjury
    case aclTear
    case brokenBone
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .minorKnock: return "Minor Knock"
        case .muscleStrain: return "Muscle Strain"
        case .hamstring: return "Hamstring Injury"
        case .ankleLigament: return "Ankle Ligament Damage"
        case .kneeInjury: return "Knee Injury"
        case .aclTear: return "Torn ACL"
        case .brokenBone: return "Broken Bone"
        }
    }
    
    /// Expected duration of injury in calendar weeks.
    public var recoveryWeeksRange: ClosedRange<Int> {
        switch self {
        case .minorKnock: return 0...1
        case .muscleStrain: return 1...2
        case .hamstring: return 2...6
        case .ankleLigament: return 4...8
        case .kneeInjury: return 8...24
        case .aclTear: return 24...36
        case .brokenBone: return 8...16
        }
    }
    
    public var averageRecoveryWeeks: Int {
        let range = recoveryWeeksRange
        return (range.lowerBound + range.upperBound) / 2
    }
    
    public var iconName: String {
        switch self {
        case .minorKnock: return "bandage"
        case .muscleStrain, .hamstring: return "figure.walk"
        case .ankleLigament, .kneeInjury: return "cross.fill"
        case .aclTear, .brokenBone: return "cross.case.fill"
        }
    }
}

// MARK: - Tactical Enums

public enum Mentality: String, Codable, CaseIterable, Identifiable, Hashable {
    case defensive
    case cautious
    case balanced
    case attacking
    case allOutAttack
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .defensive: return "Defensive"
        case .cautious: return "Cautious"
        case .balanced: return "Balanced"
        case .attacking: return "Attacking"
        case .allOutAttack: return "All-Out Attack"
        }
    }
    
    /// Multiplier modifying attacking chance generation.
    public var attackingMultiplier: Double {
        switch self {
        case .defensive: return 0.70
        case .cautious: return 0.85
        case .balanced: return 1.00
        case .attacking: return 1.15
        case .allOutAttack: return 1.30
        }
    }
    
    /// Multiplier modifying defensive solidity (higher = fewer chances conceded).
    public var defensiveMultiplier: Double {
        switch self {
        case .defensive: return 1.30
        case .cautious: return 1.15
        case .balanced: return 1.00
        case .attacking: return 0.85
        case .allOutAttack: return 0.70
        }
    }
}

public enum PressingIntensity: String, Codable, CaseIterable, Identifiable, Hashable {
    case low
    case medium
    case high
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .low: return "Low Block"
        case .medium: return "Mid Block"
        case .high: return "High Press"
        }
    }
    
    public var staminaDrainMultiplier: Double {
        switch self {
        case .low: return 0.85
        case .medium: return 1.00
        case .high: return 1.25
        }
    }
}

public enum Tempo: String, Codable, CaseIterable, Identifiable, Hashable {
    case slow
    case normal
    case fast
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .slow: return "Slow & Patient"
        case .normal: return "Standard"
        case .fast: return "Fast & Direct"
        }
    }
}

public enum Width: String, Codable, CaseIterable, Identifiable, Hashable {
    case narrow
    case normal
    case wide
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .narrow: return "Narrow"
        case .normal: return "Balanced"
        case .wide: return "Wide"
        }
    }
}

public enum PassingStyle: String, Codable, CaseIterable, Identifiable, Hashable {
    case short
    case mixed
    case long
    case direct
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .short: return "Short Tiki-Taka"
        case .mixed: return "Mixed"
        case .long: return "Long Ball"
        case .direct: return "Direct Route"
        }
    }
}

// MARK: - Formation Preset

public enum FormationPreset: String, Codable, CaseIterable, Identifiable, Hashable {
    case f442 = "4-4-2"
    case f433 = "4-3-3"
    case f4231 = "4-2-3-1"
    case f352 = "3-5-2"
    case f532 = "5-3-2"
    case f4141 = "4-1-4-1"
    case f343 = "3-4-3"
    case f4321 = "4-3-2-1"
    case f3421 = "3-4-2-1"
    case f41212 = "4-1-2-1-2"
    
    public var id: String { rawValue }
    
    public var displayName: String { rawValue }
    
    /// Exactly 11 positions designated by the formation.
    public var defaultPositions: [Position] {
        switch self {
        case .f442:
            return [.GK, .LB, .CB, .CB, .RB, .LM, .CM, .CM, .RM, .ST, .ST]
        case .f433:
            return [.GK, .LB, .CB, .CB, .RB, .CDM, .CM, .CM, .LW, .ST, .RW]
        case .f4231:
            return [.GK, .LB, .CB, .CB, .RB, .CDM, .CDM, .CAM, .LM, .RM, .ST]
        case .f352:
            return [.GK, .CB, .CB, .CB, .LWB, .CDM, .CM, .CAM, .RWB, .ST, .ST]
        case .f532:
            return [.GK, .LWB, .CB, .CB, .CB, .RWB, .CM, .CM, .CM, .ST, .ST]
        case .f4141:
            return [.GK, .LB, .CB, .CB, .RB, .CDM, .LM, .CM, .CM, .RM, .ST]
        case .f343:
            return [.GK, .CB, .CB, .CB, .LM, .CM, .CM, .RM, .LW, .ST, .RW]
        case .f4321:
            return [.GK, .LB, .CB, .CB, .RB, .CM, .CM, .CM, .CAM, .CAM, .ST]
        case .f3421:
            return [.GK, .CB, .CB, .CB, .LM, .CM, .CM, .RM, .CAM, .CAM, .ST]
        case .f41212:
            return [.GK, .LB, .CB, .CB, .RB, .CDM, .LM, .RM, .CAM, .ST, .ST]
        }
    }
    
    public var defenderCount: Int {
        defaultPositions.filter { $0.category == .defender }.count
    }
    
    public var midfielderCount: Int {
        defaultPositions.filter { $0.category == .midfielder }.count
    }
    
    public var forwardCount: Int {
        defaultPositions.filter { $0.category == .forward }.count
    }
}

// MARK: - Match Event Type

public enum MatchEventType: String, Codable, CaseIterable, Identifiable, Hashable {
    case kickOff
    case goal
    case ownGoal
    case chance
    case chanceMissed
    case shotOnTarget
    case yellowCard
    case redCard
    case secondYellow
    case substitution
    case injury
    case penalty
    case penaltyMissed
    case freeKick
    case corner
    case woodwork
    case varDecision
    case halfTime
    case fullTime
    case extraTimeStart
    case penaltyShootout
    case commentary
    
    public var id: String { rawValue }
    
    /// Emoji representation for timeline rendering.
    public var icon: String {
        switch self {
        case .kickOff: return "⏱"
        case .goal: return "⚽"
        case .ownGoal: return "⚽🤦"
        case .chance: return "🎯"
        case .chanceMissed: return "💨"
        case .shotOnTarget: return "🧤"
        case .yellowCard: return "🟡"
        case .redCard, .secondYellow: return "🟥"
        case .substitution: return "🔄"
        case .injury: return "🏥"
        case .penalty: return "⚽🅿️"
        case .penaltyMissed: return "❌🅿️"
        case .freeKick: return "🎯"
        case .corner: return "🏁"
        case .woodwork: return "🪵"
        case .varDecision: return "📺"
        case .halfTime, .fullTime: return "📋"
        case .extraTimeStart, .penaltyShootout: return "⚡"
        case .commentary: return "●"
        }
    }
    
    /// Determines whether the event should trigger user attention or commentary highlights.
    public var isMajorEvent: Bool {
        switch self {
        case .goal, .ownGoal, .redCard, .secondYellow, .penalty, .penaltyMissed, .injury, .halfTime, .fullTime:
            return true
        default:
            return false
        }
    }
}

// MARK: - Staff Role

public enum StaffRole: String, Codable, CaseIterable, Identifiable, Hashable {
    case assistantManager
    case coach
    case scout
    case physio
    case youthCoach
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .assistantManager: return "Assistant Manager"
        case .coach: return "First Team Coach"
        case .scout: return "Scout"
        case .physio: return "Head Physiotherapist"
        case .youthCoach: return "Youth Academy Director"
        }
    }
    
    public var roleDescription: String {
        switch self {
        case .assistantManager:
            return "Advises on team selection, tactics, and press conferences."
        case .coach:
            return "Accelerates weekly player attribute growth."
        case .scout:
            return "Identifies transfer targets and evaluates hidden potential."
        case .physio:
            return "Shortens player recovery times and prevents recurring injuries."
        case .youthCoach:
            return "Improves the caliber of annual youth intake academy prospects."
        }
    }
}

// MARK: - League Tier

public enum LeagueTier: Int, Codable, CaseIterable, Identifiable, Comparable, Hashable {
    case premierLeague = 1
    case championship = 2
    case leagueOne = 3
    case leagueTwo = 4
    
    public var id: Int { rawValue }
    
    public static func < (lhs: LeagueTier, rhs: LeagueTier) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var displayName: String {
        switch self {
        case .premierLeague: return "Premier League"
        case .championship: return "Championship"
        case .leagueOne: return "League One"
        case .leagueTwo: return "League Two"
        }
    }
    
    public var clubCount: Int {
        switch self {
        case .premierLeague: return 20
        case .championship, .leagueOne, .leagueTwo: return 24
        }
    }
    
    public var autoPromotionCount: Int {
        switch self {
        case .premierLeague: return 0
        case .championship, .leagueOne: return 2
        case .leagueTwo: return 3
        }
    }
    
    public var playoffPromotionCount: Int {
        switch self {
        case .premierLeague: return 0
        case .championship, .leagueOne, .leagueTwo: return 1
        }
    }
    
    public var relegationCount: Int {
        switch self {
        case .premierLeague: return 3
        case .championship: return 3
        case .leagueOne: return 4
        case .leagueTwo: return 2
        }
    }
}

// MARK: - Transfer Status

public enum TransferStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case available
    case notForSale
    case transferListed
    case loanListed
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .available: return "Available"
        case .notForSale: return "Not for Sale"
        case .transferListed: return "Transfer Listed"
        case .loanListed: return "Loan Listed"
        }
    }
}

// MARK: - Squad Role

public enum SquadRole: String, Codable, CaseIterable, Identifiable, Hashable {
    case keyPlayer
    case firstTeam
    case rotation
    case backup
    case youngster
    case notNeeded
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .keyPlayer: return "Key Player"
        case .firstTeam: return "First Team Regular"
        case .rotation: return "Rotation Option"
        case .backup: return "Squad Backup"
        case .youngster: return "Hot Prospect"
        case .notNeeded: return "Surplus to Requirements"
        }
    }
    
    /// Target percentage of matches expected to start without morale deterioration.
    public var expectedStartsRatio: Double {
        switch self {
        case .keyPlayer: return 0.85
        case .firstTeam: return 0.65
        case .rotation: return 0.40
        case .backup: return 0.15
        case .youngster: return 0.10
        case .notNeeded: return 0.00
        }
    }
}

// MARK: - Season Phase

public enum SeasonPhase: String, Codable, CaseIterable, Identifiable, Hashable {
    case preseason
    case inSeason
    case winterBreak
    case endOfSeason
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .preseason: return "Pre-Season"
        case .inSeason: return "In Season"
        case .winterBreak: return "Winter Break"
        case .endOfSeason: return "End of Season"
        }
    }
}

// MARK: - Game Mode

public enum GameMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case createClub
    case manageClub
    case createPlayer
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .createClub: return "Create a Club"
        case .manageClub: return "Manage Existing Club"
        case .createPlayer: return "Create a Player"
        }
    }
    
    public var modeDescription: String {
        switch self {
        case .createClub:
            return "Build a club from scratch, customize your stadium and badge, and climb from League Two."
        case .manageClub:
            return "Take charge of an existing English club with real squads and established expectations."
        case .createPlayer:
            return "Guide a single player's career through European football."
        }
    }
}

// MARK: - News Category

public enum NewsCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case transfer
    case injury
    case result
    case contractExpiry
    case promotion
    case relegation
    case award
    case general
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .transfer: return "Transfers"
        case .injury: return "Injuries"
        case .result: return "Match Results"
        case .contractExpiry: return "Contracts"
        case .promotion: return "Promotion"
        case .relegation: return "Relegation"
        case .award: return "Awards & Accolades"
        case .general: return "Club News"
        }
    }
    
    public var iconName: String {
        switch self {
        case .transfer: return "arrow.left.arrow.right"
        case .injury: return "cross.case"
        case .result: return "sportscourt"
        case .contractExpiry: return "doc.text"
        case .promotion: return "arrow.up.circle.fill"
        case .relegation: return "arrow.down.circle.fill"
        case .award: return "trophy.fill"
        case .general: return "newspaper.fill"
        }
    }
}

// MARK: - Transfer Offer Status

public enum TransferOfferStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case pending
    case accepted
    case rejected
    case counterOffer
    case personalTerms
    case completed
    case withdrawn
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending Review"
        case .accepted: return "Bid Accepted"
        case .rejected: return "Bid Rejected"
        case .counterOffer: return "Counter Offer Made"
        case .personalTerms: return "Contract Negotiations"
        case .completed: return "Deal Completed"
        case .withdrawn: return "Offer Withdrawn"
        }
    }
}

// MARK: - App Screen

public enum AppScreen: Hashable, Codable {
    case mainMenu
    case clubCreation
    case clubSelect
    case playerCreation
    case dashboard
    case squad
    case tactics
    case matchDay
    case liveMatch
    case postMatch
    case standings
    case fixtures
    case results
    case transferHub
    case playerSearch
    case negotiation
    case training
    case staff
    case finances
    case settings
    case playerDetail(UUID)
    
    private enum CodingKeys: String, CodingKey {
        case screenType
        case playerId
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .mainMenu:
            try container.encode("mainMenu", forKey: .screenType)
        case .clubCreation:
            try container.encode("clubCreation", forKey: .screenType)
        case .clubSelect:
            try container.encode("clubSelect", forKey: .screenType)
        case .playerCreation:
            try container.encode("playerCreation", forKey: .screenType)
        case .dashboard:
            try container.encode("dashboard", forKey: .screenType)
        case .squad:
            try container.encode("squad", forKey: .screenType)
        case .tactics:
            try container.encode("tactics", forKey: .screenType)
        case .matchDay:
            try container.encode("matchDay", forKey: .screenType)
        case .liveMatch:
            try container.encode("liveMatch", forKey: .screenType)
        case .postMatch:
            try container.encode("postMatch", forKey: .screenType)
        case .standings:
            try container.encode("standings", forKey: .screenType)
        case .fixtures:
            try container.encode("fixtures", forKey: .screenType)
        case .results:
            try container.encode("results", forKey: .screenType)
        case .transferHub:
            try container.encode("transferHub", forKey: .screenType)
        case .playerSearch:
            try container.encode("playerSearch", forKey: .screenType)
        case .negotiation:
            try container.encode("negotiation", forKey: .screenType)
        case .training:
            try container.encode("training", forKey: .screenType)
        case .staff:
            try container.encode("staff", forKey: .screenType)
        case .finances:
            try container.encode("finances", forKey: .screenType)
        case .settings:
            try container.encode("settings", forKey: .screenType)
        case .playerDetail(let uuid):
            try container.encode("playerDetail", forKey: .screenType)
            try container.encode(uuid, forKey: .playerId)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .screenType)
        switch type {
        case "mainMenu": self = .mainMenu
        case "clubCreation": self = .clubCreation
        case "clubSelect": self = .clubSelect
        case "playerCreation": self = .playerCreation
        case "dashboard": self = .dashboard
        case "squad": self = .squad
        case "tactics": self = .tactics
        case "matchDay": self = .matchDay
        case "liveMatch": self = .liveMatch
        case "postMatch": self = .postMatch
        case "standings": self = .standings
        case "fixtures": self = .fixtures
        case "results": self = .results
        case "transferHub": self = .transferHub
        case "playerSearch": self = .playerSearch
        case "negotiation": self = .negotiation
        case "training": self = .training
        case "staff": self = .staff
        case "finances": self = .finances
        case "settings": self = .settings
        case "playerDetail":
            let uuid = try container.decode(UUID.self, forKey: .playerId)
            self = .playerDetail(uuid)
        default:
            self = .mainMenu
        }
    }
}
