//
//  Ownership.swift
//  GridironFC
//
//  The owner career is intentionally separate from the manager career. Owners
//  make long-term football and business decisions; managers run the matches.
//

import Foundation

public enum ClubVision: String, Codable, CaseIterable, Identifiable, Hashable {
    case sustainable = "Sustainable Builder"
    case youthFirst = "Youth First"
    case ambitious = "Ambitious Challenger"

    public var id: String { rawValue }

    public var summary: String {
        switch self {
        case .sustainable: return "Protect the club's future with sensible wages and steady growth."
        case .youthFirst: return "Build a pathway from academy to first team."
        case .ambitious: return "Back the manager and chase rapid promotion."
        }
    }
}

public struct OwnerMilestone: Codable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let detail: String
    public let bonusPoints: Int
    public var isUnlocked: Bool

    public init(id: String, title: String, detail: String, bonusPoints: Int, isUnlocked: Bool = false) {
        self.id = id
        self.title = title
        self.detail = detail
        self.bonusPoints = bonusPoints
        self.isUnlocked = isUnlocked
    }

    public static let standard: [OwnerMilestone] = [
        OwnerMilestone(id: "first_win", title: "First Victory", detail: "Win your first competitive match under your ownership", bonusPoints: 4),
        OwnerMilestone(id: "clean_sheet", title: "Clean Sheet", detail: "Record a shutout in any league fixture", bonusPoints: 3),
        OwnerMilestone(id: "commercial_partner", title: "Commercial Partner", detail: "Sign your first official club sponsorship deal", bonusPoints: 5),
        OwnerMilestone(id: "reserves", title: "Solid Reserves", detail: "Build club cash reserves to over £2,500,000", bonusPoints: 6),
        OwnerMilestone(id: "five_unbeaten", title: "5 Unbeaten", detail: "Go five consecutive league matches without defeat", bonusPoints: 8),
        OwnerMilestone(id: "promotion", title: "Ascent", detail: "Earn promotion to a higher tier of English football", bonusPoints: 15)
    ]
}

public struct OwnerProfile: Codable, Hashable {
    public var name: String
    public var vision: ClubVision
    /// 0–100 supporter confidence. It reacts to appointments and investment.
    public var supporterConfidence: Int
    public var legacyPoints: Int
    public var budgetAllocation: BudgetAllocation
    public var sponsorshipDeals: [SponsorshipDeal]
    public var milestones: [OwnerMilestone]

    public init(
        name: String = "Club Owner",
        vision: ClubVision = .sustainable,
        supporterConfidence: Int = 62,
        legacyPoints: Int = 0,
        budgetAllocation: BudgetAllocation = BudgetAllocation(),
        sponsorshipDeals: [SponsorshipDeal] = [],
        milestones: [OwnerMilestone] = OwnerMilestone.standard
    ) {
        self.name = name
        self.vision = vision
        self.supporterConfidence = max(0, min(100, supporterConfidence))
        self.legacyPoints = max(0, legacyPoints)
        self.budgetAllocation = budgetAllocation
        self.sponsorshipDeals = sponsorshipDeals
        self.milestones = milestones.isEmpty ? OwnerMilestone.standard : milestones
    }

    private enum CodingKeys: String, CodingKey {
        case name, vision, supporterConfidence, legacyPoints, budgetAllocation, sponsorshipDeals, milestones
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Club Owner"
        self.vision = try container.decodeIfPresent(ClubVision.self, forKey: .vision) ?? .sustainable
        self.supporterConfidence = try container.decodeIfPresent(Int.self, forKey: .supporterConfidence) ?? 62
        self.legacyPoints = try container.decodeIfPresent(Int.self, forKey: .legacyPoints) ?? 0
        self.budgetAllocation = try container.decodeIfPresent(BudgetAllocation.self, forKey: .budgetAllocation) ?? BudgetAllocation()
        self.sponsorshipDeals = try container.decodeIfPresent([SponsorshipDeal].self, forKey: .sponsorshipDeals) ?? []
        self.milestones = try container.decodeIfPresent([OwnerMilestone].self, forKey: .milestones) ?? OwnerMilestone.standard
    }
}

/// One-off board interventions funded by legacy points. They give an owner a
/// concrete way to steer the club without taking over the manager's role.
public enum OwnerInvestment: String, CaseIterable, Identifiable, Hashable {
    case recruitment
    case facilities
    case community

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .recruitment: return "Recruitment Injection"
        case .facilities: return "Infrastructure Grant"
        case .community: return "Supporter Initiative"
        }
    }
    public var cost: Int {
        switch self {
        case .recruitment: return 8
        case .facilities: return 6
        case .community: return 4
        }
    }
    public var detail: String {
        switch self {
        case .recruitment: return "Adds £650K to the transfer allocation for your manager."
        case .facilities: return "Adds £450K club cash for medical or stadium projects."
        case .community: return "Builds supporter confidence and raises the club profile."
        }
    }
}

public enum TrainingFocus: String, CaseIterable, Identifiable, Hashable {
    case balanced
    case fitness
    case sharpness
    case morale

    public var id: String { rawValue }
    public var title: String { rawValue.capitalized }
    public var icon: String {
        switch self {
        case .balanced: return "equal.circle.fill"
        case .fitness: return "figure.run"
        case .sharpness: return "scope"
        case .morale: return "person.2.fill"
        }
    }
    public var detail: String {
        switch self {
        case .balanced: return "A small fitness and sharpness lift across the squad."
        case .fitness: return "Prioritise recovery for a fresher matchday squad."
        case .sharpness: return "Sharpen execution, with a small fitness trade-off."
        case .morale: return "Build belief and cohesion across the healthy squad."
        }
    }
}

public struct ManagerCandidate: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let style: String
    public let reputation: Int
    public let wage: Int
    public let compensation: Int

    public init(name: String, style: String, reputation: Int, wage: Int, compensation: Int) {
        self.name = name
        self.style = style
        self.reputation = reputation
        self.wage = wage
        self.compensation = compensation
    }

    public static let shortlist: [ManagerCandidate] = [
        ManagerCandidate(name: "Maya Brooks", style: "Possession & youth development", reputation: 58, wage: 7_500, compensation: 850_000),
        ManagerCandidate(name: "Daniel Okafor", style: "High press & man management", reputation: 64, wage: 9_500, compensation: 1_200_000),
        ManagerCandidate(name: "Elena Rossi", style: "Defensive structure & set pieces", reputation: 61, wage: 8_500, compensation: 1_000_000),
        ManagerCandidate(name: "Tomás Silva", style: "Attacking football & recruitment", reputation: 69, wage: 12_000, compensation: 1_800_000)
    ]
}
