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
    
    /// Position on the tactics slider (0 = lowest).
    public var sliderIndex: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
    
    public static func fromSlider(_ index: Int) -> PressingIntensity? {
        switch index {
        case 0: return .low
        case 1: return .medium
        case 2: return .high
        default: return nil
        }
    }
    
    /// How much this pressing level denies the opponent's attacking chances.
    public var defensiveMultiplier: Double {
        switch self {
        case .low: return 0.90
        case .medium: return 1.00
        case .high: return 1.12
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
    
    public var sliderIndex: Int {
        switch self {
        case .slow: return 0
        case .normal: return 1
        case .fast: return 2
        }
    }
    
    public static func fromSlider(_ index: Int) -> Tempo? {
        switch index {
        case 0: return .slow
        case 1: return .normal
        case 2: return .fast
        default: return nil
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
    
    /// A defensive bonus for compact narrow shapes; a chance-creation edge for width.
    public var defensiveMultiplier: Double {
        switch self {
        case .narrow: return 1.08
        case .normal: return 1.00
        case .wide: return 0.94
        }
    }
    
    public var attackingMultiplier: Double {
        switch self {
        case .narrow: return 0.94
        case .normal: return 1.00
        case .wide: return 1.06
        }
    }
    
    public var sliderIndex: Int {
        switch self {
        case .narrow: return 0
        case .normal: return 1
        case .wide: return 2
        }
    }
    
    public static func fromSlider(_ index: Int) -> Width? {
        switch index {
        case 0: return .narrow
        case 1: return .normal
        case 2: return .wide
        default: return nil
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
    
    /// Possession retention: short passing keeps the ball, long/direct surrenders it.
    public var possessionMultiplier: Double {
        switch self {
        case .short: return 1.08
        case .mixed: return 1.00
        case .long: return 0.95
        case .direct: return 0.92
        }
    }
    
    /// Chance creation: direct/long produce more chances but lower quality.
    public var chanceMultiplier: Double {
        switch self {
        case .short: return 0.96
        case .mixed: return 1.00
        case .long: return 1.05
        case .direct: return 1.08
        }
    }
    
    public var sliderIndex: Int {
        switch self {
        case .short: return 0
        case .mixed: return 1
        case .long: return 2
        case .direct: return 3
        }
    }
    
    public static func fromSlider(_ index: Int) -> PassingStyle? {
        switch index {
        case 0: return .short
        case 1: return .mixed
        case 2: return .long
        case 3: return .direct
        default: return nil
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
    case f451 = "4-5-1"
    case f4411 = "4-4-1-1"
    case f3142 = "3-1-4-2"
    case f4222 = "4-2-2-2"
    case f5221 = "5-2-2-1"
    case f3412 = "3-4-1-2"
    case f4321wide = "4-3-3 (Attack)"
    case f4312 = "4-3-1-2"
    
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
        case .f451:
            return [.GK, .LB, .CB, .CB, .RB, .CDM, .LM, .CM, .CM, .RM, .ST]
        case .f4411:
            return [.GK, .LB, .CB, .CB, .RB, .LM, .CM, .CM, .RM, .CF, .ST]
        case .f3142:
            return [.GK, .CB, .CB, .CB, .CDM, .LWB, .CM, .CM, .RWB, .ST, .ST]
        case .f4222:
            return [.GK, .LB, .CB, .CB, .RB, .CDM, .CDM, .CAM, .CAM, .ST, .ST]
        case .f5221:
            return [.GK, .LWB, .CB, .CB, .CB, .RWB, .CM, .CM, .CAM, .CAM, .ST]
        case .f3412:
            return [.GK, .CB, .CB, .CB, .LM, .CM, .CM, .RM, .CAM, .ST, .ST]
        case .f4321wide:
            return [.GK, .LB, .CB, .CB, .RB, .CM, .CM, .CAM, .LW, .ST, .RW]
        case .f4312:
            return [.GK, .LB, .CB, .CB, .RB, .CM, .CM, .CM, .CAM, .ST, .ST]
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

    /// Attacking bias from shape: more forwards / fewer defenders = more threat.
    public var attackingBias: Double {
        switch (defenderCount, forwardCount) {
        case (3, 3...): return 1.06
        case (3, _): return 1.03
        case (4, 3...): return 1.02
        case (5, _): return 0.96
        default: return 1.00
        }
    }

    /// Defensive bias from shape: more defenders = harder to break down.
    public var defensiveBias: Double {
        switch defenderCount {
        case 5...: return 1.10
        case 4: return 1.00
        case 3: return 0.95
        default: return 1.00
        }
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

/// A national division the user can manage in. Every country is modelled as a
/// four-level pyramid (levels 1–4); level 1 of each country feeds European
/// competition. `rawValue` is `countryIndex * 10 + level` so tiers sort by
/// country and then by division strength.
public enum LeagueTier: Int, Codable, CaseIterable, Identifiable, Comparable, Hashable {
    // England
    case eng1 = 11, eng2 = 12, eng3 = 13, eng4 = 14
    // Spain
    case esp1 = 21, esp2 = 22, esp3 = 23, esp4 = 24
    // Italy
    case ita1 = 31, ita2 = 32, ita3 = 33, ita4 = 34
    // Germany
    case ger1 = 41, ger2 = 42, ger3 = 43, ger4 = 44
    // France
    case fra1 = 51, fra2 = 52, fra3 = 53, fra4 = 54
    // Portugal
    case por1 = 61, por2 = 62, por3 = 63, por4 = 64
    // Netherlands
    case ned1 = 71, ned2 = 72, ned3 = 73, ned4 = 74
    // Turkey
    case tur1 = 81, tur2 = 82, tur3 = 83, tur4 = 84
    // Scotland
    case sco1 = 91, sco2 = 92, sco3 = 93, sco4 = 94
    // Belgium
    case bel1 = 101, bel2 = 102, bel3 = 103, bel4 = 104
    // Argentina
    case arg1 = 111, arg2 = 112, arg3 = 113, arg4 = 114
    // Australia
    case aus1 = 121, aus2 = 122, aus3 = 123, aus4 = 124
    // Austria
    case aut1 = 131, aut2 = 132, aut3 = 133, aut4 = 134
    // Brazil
    case bra1 = 141, bra2 = 142, bra3 = 143, bra4 = 144
    // Croatia
    case cro1 = 151, cro2 = 152, cro3 = 153, cro4 = 154
    // Czech Republic
    case cze1 = 161, cze2 = 162, cze3 = 163, cze4 = 164
    // Denmark
    case den1 = 171, den2 = 172, den3 = 173, den4 = 174
    // Greece
    case gre1 = 181, gre2 = 182, gre3 = 183, gre4 = 184
    // Japan
    case jpn1 = 191, jpn2 = 192, jpn3 = 193, jpn4 = 194
    // South Korea
    case kor1 = 201, kor2 = 202, kor3 = 203, kor4 = 204
    // Mexico
    case mex1 = 211, mex2 = 212, mex3 = 213, mex4 = 214
    // Norway
    case nor1 = 221, nor2 = 222, nor3 = 223, nor4 = 224
    // Poland
    case pol1 = 231, pol2 = 232, pol3 = 233, pol4 = 234
    // Romania
    case rou1 = 241, rou2 = 242, rou3 = 243, rou4 = 244
    // Russia
    case rus1 = 251, rus2 = 252, rus3 = 253, rus4 = 254
    // Saudi Arabia
    case ksa1 = 261, ksa2 = 262, ksa3 = 263, ksa4 = 264
    // Serbia
    case srb1 = 271, srb2 = 272, srb3 = 273, srb4 = 274
    // Sweden
    case swe1 = 281, swe2 = 282, swe3 = 283, swe4 = 284
    // Switzerland
    case sui1 = 291, sui2 = 292, sui3 = 293, sui4 = 294
    // Ukraine
    case ukr1 = 301, ukr2 = 302, ukr3 = 303, ukr4 = 304
    // United States
    case usa1 = 311, usa2 = 312, usa3 = 313, usa4 = 314

    // MARK: Back-compat aliases
    public static let premierLeague = LeagueTier.eng1
    public static let championship = LeagueTier.eng2
    public static let leagueOne = LeagueTier.eng3
    public static let leagueTwo = LeagueTier.eng4
    public static let laLiga = LeagueTier.esp1
    public static let serieA = LeagueTier.ita1
    public static let bundesliga = LeagueTier.ger1
    public static let ligue1 = LeagueTier.fra1

    public var id: Int { rawValue }

    public static func < (lhs: LeagueTier, rhs: LeagueTier) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    /// The country this division belongs to.
    public var country: LeagueCountry {
        LeagueCountry.allCases.first { self.rawValue / 10 == $0.index } ?? .england
    }

    /// The division level within the country (1 = top flight).
    public var level: Int {
        return rawValue % 10
    }

    /// The tier one level above within the same country, if any.
    public var higherTier: LeagueTier? {
        guard level > 1 else { return nil }
        return LeagueTier(rawValue: rawValue - 1)
    }

    /// The tier one level below within the same country, if any.
    public var lowerTier: LeagueTier? {
        guard level < 4 else { return nil }
        return LeagueTier(rawValue: rawValue + 1)
    }

    public var isTopFlight: Bool { level == 1 }

    public var displayName: String {
        return country.divisionName(level: level)
    }

    /// Short label used for compact UI, e.g. "ENG 2".
    public var shortLabel: String {
        return "\(country.code) \(level)"
    }

    /// The four divisions of a given country, top flight first.
    public static func pyramid(for country: LeagueCountry) -> [LeagueTier] {
        let base = country.index * 10
        return (1...4).compactMap { LeagueTier(rawValue: base + $0) }
    }

    public var clubCount: Int {
        return country.clubCount(level: level)
    }

    public var autoPromotionCount: Int {
        guard level < 4 else { return level == 4 ? 3 : 0 }
        return level == 1 ? 0 : 2
    }

    public var playoffPromotionCount: Int {
        guard level > 1 else { return 0 }
        return 1
    }

    public var relegationCount: Int {
        switch level {
        case 1: return country.topFlightRelegationCount
        case 2: return 3
        case 3: return 4
        default: return 2
        }
    }

    /// Number of European qualification slots this division grants (top flight only).
    public var europeanSlots: Int {
        guard isTopFlight else { return 0 }
        return country.europeanSlots
    }
}

// MARK: - League Country

public enum LeagueCountry: String, Codable, CaseIterable, Identifiable, Hashable {
    // Indices 1-10: original shipped countries (order MUST stay stable).
    case england
    case spain
    case italy
    case germany
    case france
    case portugal
    case netherlands
    case turkey
    case scotland
    case belgium
    // Indices 11-31: appended from the Transfermarkt dataset.
    case argentina
    case australia
    case austria
    case brazil
    case croatia
    case czechRepublic
    case denmark
    case greece
    case japan
    case southKorea
    case mexico
    case norway
    case poland
    case romania
    case russia
    case saudiArabia
    case serbia
    case sweden
    case switzerland
    case ukraine
    case unitedStates

    public var id: String { rawValue }

    /// Stable index used to derive `LeagueTier.rawValue`.
    public var index: Int {
        return (LeagueCountry.allCases.firstIndex(of: self) ?? 0) + 1
    }

    public var displayName: String {
        switch self {
        case .england: return "England"
        case .spain: return "Spain"
        case .italy: return "Italy"
        case .germany: return "Germany"
        case .france: return "France"
        case .portugal: return "Portugal"
        case .netherlands: return "Netherlands"
        case .turkey: return "Türkiye"
        case .scotland: return "Scotland"
        case .belgium: return "Belgium"
        case .argentina: return "Argentina"
        case .australia: return "Australia"
        case .austria: return "Austria"
        case .brazil: return "Brazil"
        case .croatia: return "Croatia"
        case .czechRepublic: return "Czech Republic"
        case .denmark: return "Denmark"
        case .greece: return "Greece"
        case .japan: return "Japan"
        case .southKorea: return "South Korea"
        case .mexico: return "Mexico"
        case .norway: return "Norway"
        case .poland: return "Poland"
        case .romania: return "Romania"
        case .russia: return "Russia"
        case .saudiArabia: return "Saudi Arabia"
        case .serbia: return "Serbia"
        case .sweden: return "Sweden"
        case .switzerland: return "Switzerland"
        case .ukraine: return "Ukraine"
        case .unitedStates: return "United States"
        }
    }

    /// Three-letter code used in compact labels.
    public var code: String {
        switch self {
        case .england: return "ENG"
        case .spain: return "ESP"
        case .italy: return "ITA"
        case .germany: return "GER"
        case .france: return "FRA"
        case .portugal: return "POR"
        case .netherlands: return "NED"
        case .turkey: return "TUR"
        case .scotland: return "SCO"
        case .belgium: return "BEL"
        case .argentina: return "ARG"
        case .australia: return "AUS"
        case .austria: return "AUT"
        case .brazil: return "BRA"
        case .croatia: return "CRO"
        case .czechRepublic: return "CZE"
        case .denmark: return "DEN"
        case .greece: return "GRE"
        case .japan: return "JPN"
        case .southKorea: return "KOR"
        case .mexico: return "MEX"
        case .norway: return "NOR"
        case .poland: return "POL"
        case .romania: return "ROU"
        case .russia: return "RUS"
        case .saudiArabia: return "KSA"
        case .serbia: return "SRB"
        case .sweden: return "SWE"
        case .switzerland: return "SUI"
        case .ukraine: return "UKR"
        case .unitedStates: return "USA"
        }
    }

    public var flag: String {
        switch self {
        case .england: return "🏴󠁧󠁢󠁥󠁮󠁧󠁿"
        case .spain: return "🇪🇸"
        case .italy: return "🇮🇹"
        case .germany: return "🇩🇪"
        case .france: return "🇫🇷"
        case .portugal: return "🇵🇹"
        case .netherlands: return "🇳🇱"
        case .turkey: return "🇹🇷"
        case .scotland: return "🏴󠁧󠁢󠁳󠁣󠁴󠁿"
        case .belgium: return "🇧🇪"
        case .argentina: return "🇦🇷"
        case .australia: return "🇦🇺"
        case .austria: return "🇦🇹"
        case .brazil: return "🇧🇷"
        case .croatia: return "🇭🇷"
        case .czechRepublic: return "🇨🇿"
        case .denmark: return "🇩🇰"
        case .greece: return "🇬🇷"
        case .japan: return "🇯🇵"
        case .southKorea: return "🇰🇷"
        case .mexico: return "🇲🇽"
        case .norway: return "🇳🇴"
        case .poland: return "🇵🇱"
        case .romania: return "🇷🇴"
        case .russia: return "🇷🇺"
        case .saudiArabia: return "🇸🇦"
        case .serbia: return "🇷🇸"
        case .sweden: return "🇸🇪"
        case .switzerland: return "🇨🇭"
        case .ukraine: return "🇺🇦"
        case .unitedStates: return "🇺🇸"
        }
    }

    /// Display name of the division at the given level for this country.
    public func divisionName(level: Int) -> String {
        switch (self, level) {
        case (.england, 1): return "Premier League"
        case (.england, 2): return "Championship"
        case (.england, 3): return "League One"
        case (.england, 4): return "League Two"
        case (.spain, 1): return "La Liga"
        case (.spain, 2): return "LaLiga 2"
        case (.spain, 3): return "Primera Federación"
        case (.spain, 4): return "Segunda Federación"
        case (.italy, 1): return "Serie A"
        case (.italy, 2): return "Serie B"
        case (.italy, 3): return "Serie C"
        case (.italy, 4): return "Serie D"
        case (.germany, 1): return "Bundesliga"
        case (.germany, 2): return "2. Bundesliga"
        case (.germany, 3): return "3. Liga"
        case (.germany, 4): return "Regionalliga"
        case (.france, 1): return "Ligue 1"
        case (.france, 2): return "Ligue 2"
        case (.france, 3): return "National"
        case (.france, 4): return "National 2"
        case (.portugal, 1): return "Primeira Liga"
        case (.portugal, 2): return "Liga Portugal 2"
        case (.portugal, 3): return "Liga 3"
        case (.portugal, 4): return "Campeonato de Portugal"
        case (.netherlands, 1): return "Eredivisie"
        case (.netherlands, 2): return "Eerste Divisie"
        case (.netherlands, 3): return "Tweede Divisie"
        case (.netherlands, 4): return "Derde Divisie"
        case (.turkey, 1): return "Süper Lig"
        case (.turkey, 2): return "1. Lig"
        case (.turkey, 3): return "2. Lig"
        case (.turkey, 4): return "3. Lig"
        case (.scotland, 1): return "Scottish Premiership"
        case (.scotland, 2): return "Scottish Championship"
        case (.scotland, 3): return "Scottish League One"
        case (.scotland, 4): return "Scottish League Two"
        case (.belgium, 1): return "Belgian Pro League"
        case (.belgium, 2): return "Challenger Pro League"
        case (.belgium, 3): return "Eerste Nationale"
        case (.belgium, 4): return "Tweede Nationale"
        case (.argentina, 1): return "Liga Profesional"
        case (.australia, 1): return "A-League"
        case (.austria, 1): return "Austrian Bundesliga"
        case (.brazil, 1): return "Brasileirão Série A"
        case (.croatia, 1): return "SuperSport HNL"
        case (.czechRepublic, 1): return "Chance Liga"
        case (.denmark, 1): return "Superliga"
        case (.greece, 1): return "Super League Greece"
        case (.japan, 1): return "J1 League"
        case (.southKorea, 1): return "K League 1"
        case (.mexico, 1): return "Liga MX"
        case (.norway, 1): return "Eliteserien"
        case (.poland, 1): return "Ekstraklasa"
        case (.romania, 1): return "SuperLiga"
        case (.russia, 1): return "Russian Premier League"
        case (.saudiArabia, 1): return "Saudi Pro League"
        case (.serbia, 1): return "Serbian SuperLiga"
        case (.sweden, 1): return "Allsvenskan"
        case (.switzerland, 1): return "Swiss Super League"
        case (.ukraine, 1): return "Ukrainian Premier League"
        case (.unitedStates, 1): return "Major League Soccer"
        default: return "\(displayName) Division \(level)"
        }
    }

    /// Number of clubs in a division at the given level.
    public func clubCount(level: Int) -> Int {
        switch (self, level) {
        case (.england, 1): return 20
        case (.england, 2), (.england, 3), (.england, 4): return 24
        case (.spain, 1): return 20
        case (.spain, 2): return 22
        case (.spain, 3): return 20
        case (.spain, 4): return 20
        case (.italy, 1): return 20
        case (.italy, 2): return 20
        case (.italy, 3): return 20
        case (.italy, 4): return 20
        case (.germany, 1): return 18
        case (.germany, 2): return 18
        case (.germany, 3): return 20
        case (.germany, 4): return 20
        case (.france, 1), (.france, 2): return 18
        case (.france, 3): return 18
        case (.france, 4): return 18
        case (.portugal, 1): return 18
        case (.portugal, 2): return 18
        case (.portugal, 3): return 20
        case (.portugal, 4): return 20
        case (.netherlands, 1): return 18
        case (.netherlands, 2): return 20
        case (.netherlands, 3): return 18
        case (.netherlands, 4): return 18
        case (.turkey, 1): return 18
        case (.turkey, 2): return 18
        case (.turkey, 3): return 18
        case (.turkey, 4): return 18
        case (.scotland, 1): return 12
        case (.scotland, 2): return 10
        case (.scotland, 3): return 10
        case (.scotland, 4): return 10
        case (.belgium, 1): return 16
        case (.belgium, 2): return 16
        case (.belgium, 3): return 18
        case (.belgium, 4): return 18
        case (.argentina, 1): return 30
        case (.australia, 1): return 12
        case (.austria, 1): return 12
        case (.brazil, 1): return 20
        case (.croatia, 1): return 10
        case (.czechRepublic, 1): return 16
        case (.denmark, 1): return 12
        case (.greece, 1): return 14
        case (.japan, 1): return 20
        case (.southKorea, 1): return 12
        case (.mexico, 1): return 18
        case (.norway, 1): return 16
        case (.poland, 1): return 18
        case (.romania, 1): return 16
        case (.russia, 1): return 16
        case (.saudiArabia, 1): return 18
        case (.serbia, 1): return 16
        case (.sweden, 1): return 16
        case (.switzerland, 1): return 12
        case (.ukraine, 1): return 16
        case (.unitedStates, 1): return 30
        default: return 18
        }
    }

    /// Number of clubs relegated straight out of the top flight each season.
    public var topFlightRelegationCount: Int {
        switch self {
        case .england, .spain, .italy, .germany, .france: return 3
        default: return 2
        }
    }

    /// European qualification slots granted by this country's top flight.
    public var europeanSlots: Int {
        switch self {
        case .england, .spain, .italy, .germany: return 4
        case .france, .portugal, .netherlands: return 3
        case .turkey, .belgium, .austria, .greece, .czechRepublic, .scotland, .denmark, .croatia, .switzerland, .serbia, .norway, .sweden, .poland, .romania, .ukraine, .russia: return 2
        default: return 1
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
    case unemployed
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .createClub: return "Create a Club"
        case .manageClub: return "Manage Existing Club"
        case .unemployed: return "Start Unemployed"
        }
    }
    
    public var modeDescription: String {
        switch self {
        case .createClub:
            return "Build a club from scratch, customize your stadium and badge, and climb from League Two."
        case .manageClub:
            return "Take charge of an existing English club with real squads and established expectations."
        case .unemployed:
            return "Begin without a club and wait for job offers. Work your way up from the bottom."
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
    case board
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
        case .board: return "Board & Management"
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
        case .board: return "person.badge.shield.checkmark.fill"
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
    case managerCreation
    case jobOffers
    case managerProfile
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
    case mailbox
    case matchHistory
    case europeanCompetitions
    case youthAcademy
    case international
    case news
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
        case .managerCreation:
            try container.encode("managerCreation", forKey: .screenType)
        case .jobOffers:
            try container.encode("jobOffers", forKey: .screenType)
        case .managerProfile:
            try container.encode("managerProfile", forKey: .screenType)
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
        case .mailbox:
            try container.encode("mailbox", forKey: .screenType)
        case .matchHistory:
            try container.encode("matchHistory", forKey: .screenType)
        case .europeanCompetitions:
            try container.encode("europeanCompetitions", forKey: .screenType)
        case .youthAcademy:
            try container.encode("youthAcademy", forKey: .screenType)
        case .international:
            try container.encode("international", forKey: .screenType)
        case .news:
            try container.encode("news", forKey: .screenType)
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
        case "managerCreation": self = .managerCreation
        case "jobOffers": self = .jobOffers
        case "managerProfile": self = .managerProfile
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
        case "mailbox": self = .mailbox
        case "matchHistory": self = .matchHistory
        case "europeanCompetitions": self = .europeanCompetitions
        case "youthAcademy": self = .youthAcademy
        case "international": self = .international
        case "news": self = .news
        case "playerDetail":
            let uuid = try container.decode(UUID.self, forKey: .playerId)
            self = .playerDetail(uuid)
        default:
            self = .mainMenu
        }
    }
}
