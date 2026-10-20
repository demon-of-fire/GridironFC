//
//  JobOffer.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Managerial job offers extended to the user when they are unemployed, or when
//  a bigger club comes calling during an active stint.
//

import Foundation

// MARK: - Job Offer Kind

public enum JobOfferKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case club
    case nationalTeam

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .club: return "Club Vacancy"
        case .nationalTeam: return "International Post"
        }
    }

    public var iconName: String {
        switch self {
        case .club: return "building.2.fill"
        case .nationalTeam: return "globe.europe.africa.fill"
        }
    }
}

// MARK: - Job Offer

/// An invitation to manage a club (or, later, a national team). Offers arrive
/// via the inbox and are resolved on the Job Offers screen.
public struct JobOffer: Codable, Identifiable, Hashable {
    public let id: UUID
    /// The club or national side making the approach. Nil for national teams
    /// until those are represented as clubs in the world model.
    public var clubId: UUID?
    public var kind: JobOfferKind
    /// Display name of the prospective employer.
    public var teamName: String
    public var leagueName: String
    /// Reputation of the role (1-100), used to decide whether the user is a fit.
    public var reputation: Int
    /// Weekly wage the employer is offering.
    public var offeredWage: Int
    /// Season the offer was made (e.g., "2026-27").
    public var seasonYear: String

    public init(
        id: UUID = UUID(),
        clubId: UUID?,
        kind: JobOfferKind = .club,
        teamName: String,
        leagueName: String,
        reputation: Int,
        offeredWage: Int,
        seasonYear: String
    ) {
        self.id = id
        self.clubId = clubId
        self.kind = kind
        self.teamName = teamName
        self.leagueName = leagueName
        self.reputation = reputation
        self.offeredWage = offeredWage
        self.seasonYear = seasonYear
    }
}
