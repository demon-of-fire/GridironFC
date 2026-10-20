//
//  NationalTeam.swift
//  GridironFC
//
//  National teams available for international management. Squads are assembled
//  from real club players grouped by nationality, enriched with Transfermarkt
//  national-team metadata (confederation, FIFA ranking, coach).
//

import Foundation

// MARK: - Confederation

public enum Confederation: String, Codable, CaseIterable, Identifiable, Hashable {
    case uefa = "UEFA"
    case conmebol = "CONMEBOL"
    case caf = "CAF"
    case afc = "AFC"
    case concacaf = "CONCACAF"
    case ofc = "OFC"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .uefa: return "Europe (UEFA)"
        case .conmebol: return "South America (CONMEBOL)"
        case .caf: return "Africa (CAF)"
        case .afc: return "Asia (AFC)"
        case .concacaf: return "North & Central America (CONCACAF)"
        case .ofc: return "Oceania (OFC)"
        }
    }

    /// Regional championship staged by this confederation, if any.
    public var regionalTournament: InternationalTournament.Kind? {
        switch self {
        case .uefa: return .euro
        case .conmebol: return .copaAmerica
        case .caf: return .africaCupOfNations
        case .afc: return .asianCup
        case .concacaf, .ofc: return nil
        }
    }
}

// MARK: - National team

public struct NationalTeam: Codable, Identifiable, Hashable {
    public var id: String
    public var name: String
    public var countryCode: String?
    public var confederation: Confederation
    public var fifaRanking: Int?
    public var coach: String?
    public var players: [Player]

    public init(
        id: String,
        name: String,
        countryCode: String? = nil,
        confederation: Confederation,
        fifaRanking: Int? = nil,
        coach: String? = nil,
        players: [Player] = []
    ) {
        self.id = id
        self.name = name
        self.countryCode = countryCode
        self.confederation = confederation
        self.fifaRanking = fifaRanking
        self.coach = coach
        self.players = players
    }

    /// Best eleven by overall rating (used to score matches).
    public var bestEleven: [Player] {
        Array(players.sorted { $0.overall > $1.overall }.prefix(11))
    }

    /// Mean overall of the best eleven.
    public var strength: Double {
        let xi = bestEleven
        guard !xi.isEmpty else { return 55 }
        return Double(xi.map { $0.overall }.reduce(0, +)) / Double(xi.count)
    }
}

// MARK: - Raw loader DTOs

public struct RawNationalTeamData: Codable {
    public let id: String
    public let name: String
    public let countryCode: String?
    public let confederation: String?
    public let fifaRanking: Int?
    public let coach: String?
    public let players: [RawNationalPlayerData]
}

public struct RawNationalPlayerData: Codable {
    public let firstName: String
    public let lastName: String
    public let nationality: String
    public let age: Int
    public let positions: [String]
    public let overall: Int
    public let potential: Int
    public let preferredFoot: String?
}

public struct RawNationalTeamFile: Codable {
    public let teams: [RawNationalTeamData]
}
