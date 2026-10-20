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
