//
//  Manager.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Manager profile model covering identity, appearance, coaching attributes,
//  reputation tracking, and career history for the user's managerial avatar.
//

import Foundation

// MARK: - Manager Nationality

/// A broad set of footballing nationalities the user can pick from when
/// customising their manager. Kept as a free-form string on the profile so
/// custom values remain possible.
public enum ManagerNationality: String, Codable, CaseIterable, Identifiable, Hashable {
    case england = "England"
    case scotland = "Scotland"
    case wales = "Wales"
    case ireland = "Ireland"
    case spain = "Spain"
    case italy = "Italy"
    case germany = "Germany"
    case france = "France"
    case portugal = "Portugal"
    case netherlands = "Netherlands"
    case brazil = "Brazil"
    case argentina = "Argentina"
    case usa = "United States"

    public var id: String { rawValue }

    /// Short country code for compact display.
    public var flag: String {
        switch self {
        case .england: return "ENG"
        case .scotland: return "SCO"
        case .wales: return "WAL"
        case .ireland: return "IRL"
        case .spain: return "ESP"
        case .italy: return "ITA"
        case .germany: return "GER"
        case .france: return "FRA"
        case .portugal: return "POR"
        case .netherlands: return "NED"
        case .brazil: return "BRA"
        case .argentina: return "ARG"
        case .usa: return "USA"
        }
    }
}

// MARK: - Coaching Attribute

/// The four headline coaching attributes shown on a manager profile.
public enum CoachingAttribute: String, Codable, CaseIterable, Identifiable, Hashable {
    case tactical
    case attacking
    case defending
    case youthDevelopment

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .tactical: return "Tactical Knowledge"
        case .attacking: return "Attacking Coaching"
        case .defending: return "Defensive Coaching"
        case .youthDevelopment: return "Youth Development"
        }
    }

    public var iconName: String {
        switch self {
        case .tactical: return "chess.piece.bishop.fill"
        case .attacking: return "flame.fill"
        case .defending: return "shield.lefthalf.filled"
        case .youthDevelopment: return "graduationcap.fill"
        }
    }
}

// MARK: - Manager Background

/// A manager's playing/coaching pedigree, chosen at the start of a career.
/// The background — not free sliders — determines the starting coaching
/// attributes, giving each career a distinct tactical identity.
public enum ManagerBackground: String, Codable, CaseIterable, Identifiable, Hashable {
    case exStriker = "Former Striker"
    case exDefender = "Former Defender"
    case exMidfielder = "Former Midfielder"
    case exGoalkeeper = "Former Goalkeeper"
    case academyCoach = "Academy Coach"
    case dataAnalyst = "Data Analyst"
    case journeyman = "Journeyman Pro"

    public var id: String { rawValue }

    public var summary: String {
        switch self {
        case .exStriker: return "A lethal finisher in his day; builds adventurous, front-foot sides."
        case .exDefender: return "A no-nonsense centre-half; teams are organised, compact and hard to beat."
        case .exMidfielder: return "A metronome who dictates tempo; balanced, possession-minded football."
        case .exGoalkeeper: return "A born organiser; reads the game superbly from the back."
        case .academyCoach: return "Twenty years developing teenagers; unrivalled at bringing youth through."
        case .dataAnalyst: return "A modern, analytics-first thinker with sharp tactical insight."
        case .journeyman: return "A well-travelled pro with no glaring weakness and no great strength."
        }
    }

    /// The fixed starting coaching spread (tactical, attacking, defending, youth).
    public var attributes: (tactical: Int, attacking: Int, defending: Int, youth: Int) {
        switch self {
        case .exStriker:     return (60, 74, 52, 50)
        case .exDefender:    return (62, 50, 76, 50)
        case .exMidfielder:  return (70, 62, 62, 54)
        case .exGoalkeeper:  return (68, 52, 70, 52)
        case .academyCoach:  return (56, 54, 54, 80)
        case .dataAnalyst:   return (78, 60, 64, 52)
        case .journeyman:    return (60, 60, 60, 60)
        }
    }
}

// MARK: - Manager Profile

/// The user's managerial persona. Purely cosmetic + reputation tracking; the
/// match engine does not yet weight coaching attributes, but they are surfaced
/// on the profile for flavour and future use.
public struct ManagerProfile: Codable, Hashable {
    public var firstName: String
    public var lastName: String
    public var nationality: String
    public var age: Int
    /// Stable seed driving the procedural manager avatar (same RNG as player faces).
    public var faceSeed: UInt64

    /// Coaching attributes on the standard 1-99 scale.
    public var tactical: Int
    public var attacking: Int
    public var defending: Int
    public var youthDevelopment: Int

    /// Career reputation mirroring club reputation scale (1-100).
    public var reputation: Int

    /// Season-by-season managerial record, newest last.
    public var careerHistory: [ManagerSeasonRecord]

    public init(
        firstName: String = "Alex",
        lastName: String = "Morgan",
        nationality: String = ManagerNationality.england.rawValue,
        age: Int = 38,
        faceSeed: UInt64 = 0,
        tactical: Int = 55,
        attacking: Int = 55,
        defending: Int = 55,
        youthDevelopment: Int = 55,
        reputation: Int = 30,
        careerHistory: [ManagerSeasonRecord] = []
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.nationality = nationality
        self.age = age
        self.faceSeed = faceSeed == 0 ? ManagerProfile.generateSeed(first: firstName, last: lastName) : faceSeed
        self.tactical = min(99, max(1, tactical))
        self.attacking = min(99, max(1, attacking))
        self.defending = min(99, max(1, defending))
        self.youthDevelopment = min(99, max(1, youthDevelopment))
        self.reputation = min(100, max(1, reputation))
        self.careerHistory = careerHistory
    }

    // MARK: - Identity Helpers

    public var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    public var displayName: String {
        guard let firstChar = firstName.first else { return lastName }
        return "\(firstChar). \(lastName)"
    }

    public var nationalityEnum: ManagerNationality? {
        ManagerNationality(rawValue: nationality)
    }

    public var flag: String {
        nationalityEnum?.flag ?? "INT"
    }

    /// Average of the four coaching attributes, for a quick "overall coach" read.
    public var overallCoaching: Int {
        (tactical + attacking + defending + youthDevelopment) / 4
    }

    /// Deterministic seed derivation so the same name always yields the same face.
    public static func generateSeed(first: String, last: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in "\(first)|\(last)".lowercased().utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash == 0 ? 0x9E3779B97F4A7C15 : hash
    }
}

// MARK: - Manager Season Record

/// A single season's snapshot of the user's managerial career, kept for the
/// profile's history list and used when evaluating job offers.
public struct ManagerSeasonRecord: Codable, Hashable, Identifiable {
    public var id: UUID
    public var seasonYear: String
    public var clubName: String
    public var leagueName: String
    public var played: Int
    public var won: Int
    public var drawn: Int
    public var lost: Int
    public var finalPosition: Int
    /// Trophies or notable achievements, e.g. "Premier League Champions".
    public var honours: [String]
    /// Points per game for a quick form read.
    public var pointsPerGame: Double {
        guard played > 0 else { return 0 }
        return Double(won * 3 + drawn) / Double(played)
    }

    public init(
        id: UUID = UUID(),
        seasonYear: String,
        clubName: String,
        leagueName: String,
        played: Int = 0,
        won: Int = 0,
        drawn: Int = 0,
        lost: Int = 0,
        finalPosition: Int = 0,
        honours: [String] = []
    ) {
        self.id = id
        self.seasonYear = seasonYear
        self.clubName = clubName
        self.leagueName = leagueName
        self.played = played
        self.won = won
        self.drawn = drawn
        self.lost = lost
        self.finalPosition = finalPosition
        self.honours = honours
    }

    public var winPercentage: Double {
        guard played > 0 else { return 0 }
        return Double(won) / Double(played) * 100.0
    }
}

// MARK: - Board Expectations & Job Security

/// The board's stated objective for a manager this season.
public enum BoardExpectation: String, Codable, CaseIterable, Hashable {
    case stayUp = "Avoid Relegation"
    case midTable = "Consolidate in Mid-Table"
    case topHalf = "Finish in the Top Half"
    case europe = "Qualify for European Competition"
    case titleChallenge = "Challenge for the Title"
    case immediatePromotion = "Secure Promotion"
    case promotionChallenge = "Push for Promotion"

    public var minimumPosition: Int {
        switch self {
        case .stayUp: return 17  // 18th and below triggers concern in lower leagues; logic varies by size
        case .midTable: return 12
        case .topHalf: return 9
        case .europe: return 7
        case .titleChallenge: return 3
        case .immediatePromotion: return 2
        case .promotionChallenge: return 6
        }
    }

    public var importance: Int {
        switch self {
        case .stayUp: return 95
        case .midTable: return 70
        case .topHalf: return 80
        case .europe: return 90
        case .titleChallenge: return 95
        case .immediatePromotion: return 95
        case .promotionChallenge: return 80
        }
    }
}

/// A manager's security of tenure, driven by board expectations.
public struct JobSecurity: Codable, Hashable {
    public var boardConfidence: Int  // 0-100
    public var expectation: BoardExpectation
    public var gamesWithoutWin: Int
    public var underperformingWeeks: Int

    public init(boardConfidence: Int = 70, expectation: BoardExpectation = .midTable, gamesWithoutWin: Int = 0, underperformingWeeks: Int = 0) {
        self.boardConfidence = max(0, min(100, boardConfidence))
        self.expectation = expectation
        self.gamesWithoutWin = max(0, gamesWithoutWin)
        self.underperformingWeeks = max(0, underperformingWeeks)
    }

    public var status: String {
        if boardConfidence >= 80 { return "Secure" }
        if boardConfidence >= 60 { return "Stable" }
        if boardConfidence >= 40 { return "Under Pressure" }
        if boardConfidence >= 25 { return "Perilous" }
        return "Job On The Line"
    }

    public var statusColor: String {
        if boardConfidence >= 60 { return "green" }
        if boardConfidence >= 40 { return "orange" }
        return "red"
    }
}

// MARK: - Man Management

public enum TeamTalkStyle: String, Codable, CaseIterable, Identifiable, Hashable {
    case calm = "Calm & Rational"
    case firedUp = "Fired Up"
    case rally = "Rally The Troops"
    case demand = "Demand More"
    case protect = "Protect The Squad"

    public var id: String { rawValue }

    public var effectSummary: String {
        switch self {
        case .calm: return "Steady nerves, keeps spirits level"
        case .firedUp: return "Big morale boost, risks a bit of tension"
        case .rally: return "Lifts underdogs, boosts togetherness"
        case .demand: return "Sharpens focus, can rattle fragile players"
        case .protect: return "Reassures squad after criticism, builds loyalty"
        }
    }
}

// MARK: - Owner Budget & Sponsorship

public enum SponsorshipTier: String, Codable, CaseIterable, Hashable {
    case local = "Local Business"
    case regional = "Regional Brand"
    case national = "National Sponsor"
    case global = "Global Partner"

    public var baseIncome: Int {
        switch self {
        case .local: return 1_200_000
        case .regional: return 3_500_000
        case .national: return 8_000_000
        case .global: return 18_000_000
        }
    }
}

public struct SponsorshipDeal: Codable, Hashable, Identifiable {
    public var id: UUID
    public var sponsorName: String
    public var tier: SponsorshipTier
    public var annualValue: Int
    public var yearsRemaining: Int
    public var performanceBonus: Int

    public init(id: UUID = UUID(), sponsorName: String, tier: SponsorshipTier, annualValue: Int, yearsRemaining: Int = 3, performanceBonus: Int = 0) {
        self.id = id
        self.sponsorName = sponsorName
        self.tier = tier
        self.annualValue = annualValue
        self.yearsRemaining = yearsRemaining
        self.performanceBonus = performanceBonus
    }
}

public struct BudgetAllocation: Codable, Hashable {
    public var transferBudgetPercent: Int  // 0-100
    public var wageBudgetPercent: Int

    public init(transferBudgetPercent: Int = 65, wageBudgetPercent: Int = 35) {
        self.transferBudgetPercent = max(0, min(100, transferBudgetPercent))
        self.wageBudgetPercent = max(0, min(100, wageBudgetPercent))
    }
}
