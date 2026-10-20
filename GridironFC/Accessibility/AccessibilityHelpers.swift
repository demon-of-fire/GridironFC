//
//  AccessibilityHelpers.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  VoiceOver ViewModifiers, descriptive accessibility speech builders,
//  custom accessibility actions, and Dynamic Type helpers.
//

import SwiftUI

// MARK: - Accessible Player Card Modifier

public struct AccessiblePlayerCardModifier: ViewModifier {
    public let player: Player
    public let clubName: String?
    public var onSelect: (() -> Void)?
    public var onSubstitute: (() -> Void)?
    
    public init(
        player: Player,
        clubName: String? = nil,
        onSelect: (() -> Void)? = nil,
        onSubstitute: (() -> Void)? = nil
    ) {
        self.player = player
        self.clubName = clubName
        self.onSelect = onSelect
        self.onSubstitute = onSubstitute
    }
    
    public func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AccessibilityFormatter.playerSummary(player: player, clubName: clubName))
            .accessibilityValue(AccessibilityFormatter.playerStatus(player: player))
            .accessibilityHint("Double tap to open full player profile and attribute breakdown.")
            .accessibilityActions {
                if let onSelect = onSelect {
                    Button("View Profile", action: onSelect)
                }
                if let onSubstitute = onSubstitute {
                    Button("Make Substitution", action: onSubstitute)
                }
            }
    }
}

// MARK: - Accessible Stat Bar Modifier

public struct AccessibleStatBarModifier: ViewModifier {
    public let statName: String
    public let value: Int
    public let maxValue: Int
    
    public init(statName: String, value: Int, maxValue: Int = 99) {
        self.statName = statName
        self.value = value
        self.maxValue = maxValue
    }
    
    public func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(statName)
            .accessibilityValue("\(value) out of \(maxValue), \(qualityDescriptor(for: value))")
    }
    
    private func qualityDescriptor(for val: Int) -> String {
        switch val {
        case 85...99: return "World Class"
        case 75...84: return "Excellent"
        case 65...74: return "Good"
        case 50...64: return "Average"
        default: return "Developing"
        }
    }
}

// MARK: - Accessible Match Event Modifier

public struct AccessibleMatchEventModifier: ViewModifier {
    public let event: MatchEvent
    
    public func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Minute \(event.minute), \(event.type.rawValue)")
            .accessibilityValue(event.detailText)
    }
}

// MARK: - Accessibility Formatter Helpers

public struct AccessibilityFormatter {
    
    /// Builds a comprehensive spoken description for a footballer.
    public static func playerSummary(player: Player, clubName: String?) -> String {
        var parts: [String] = []
        parts.append(player.fullName)
        parts.append(player.primaryPosition.displayName)
        parts.append("Overall rating \(player.overall)")
        
        if let club = clubName {
            parts.append(club)
        }
        
        parts.append("Age \(player.age)")
        parts.append("Nationality \(player.nationality)")
        return parts.joined(separator: ", ")
    }
    
    /// Spoken descriptor for physical readiness and availability.
    public static func playerStatus(player: Player) -> String {
        var statusParts: [String] = []
        
        if let inj = player.injury {
            statusParts.append("Injured with \(inj.type.displayName), out for \(inj.weeksRemaining) weeks")
        } else if player.suspendedMatches > 0 {
            statusParts.append("Suspended for \(player.suspendedMatches) matches")
        } else {
            statusParts.append("Match fit at \(Int(player.matchFitness)) percent")
        }
        
        statusParts.append("Morale is \(player.morale.displayName)")
        statusParts.append("Form rating \(String(format: "%.1f", player.averageForm))")
        
        return statusParts.joined(separator: ". ")
    }
    
    /// Spoken descriptor for a match fixture or completed result.
    public static func fixtureDescription(
        fixture: Fixture,
        homeClubName: String,
        awayClubName: String
    ) -> String {
        if fixture.isPlayed, let res = fixture.result {
            return "Matchweek \(fixture.matchWeek): \(homeClubName) \(res.homeGoals), \(awayClubName) \(res.awayGoals). Played on \(fixture.date)."
        } else {
            return "Upcoming matchweek \(fixture.matchWeek): \(homeClubName) versus \(awayClubName) on \(fixture.date)."
        }
    }
    
    /// Spoken descriptor for a league table row.
    public static func standingRow(
        rank: Int,
        clubName: String,
        standing: LeagueStanding
    ) -> String {
        return "Position \(rank): \(clubName), \(standing.points) points. Played \(standing.played), won \(standing.won), drawn \(standing.drawn), lost \(standing.lost). Goal difference \(standing.goalDifference > 0 ? "plus \(standing.goalDifference)" : "\(standing.goalDifference)")."
    }
}

// MARK: - View Extensions for Accessibility

public extension View {
    
    /// Attaches comprehensive VoiceOver metadata and actions to a player card.
    func accessiblePlayerCard(
        player: Player,
        clubName: String? = nil,
        onSelect: (() -> Void)? = nil,
        onSubstitute: (() -> Void)? = nil
    ) -> some View {
        modifier(AccessiblePlayerCardModifier(
            player: player,
            clubName: clubName,
            onSelect: onSelect,
            onSubstitute: onSubstitute
        ))
    }
    
    /// Formats a graphical attribute slider/bar with clear numerical and qualitative descriptions.
    func accessibleStatBar(statName: String, value: Int, maxValue: Int = 99) -> some View {
        modifier(AccessibleStatBarModifier(statName: statName, value: value, maxValue: maxValue))
    }
    
    /// Configures VoiceOver for timeline commentary events.
    func accessibleMatchEvent(_ event: MatchEvent) -> some View {
        modifier(AccessibleMatchEventModifier(event: event))
    }
    
    /// Establishes accessible Dynamic Type scaling bounds.
    func dynamicTypeBounds(
        min: DynamicTypeSize = .medium,
        max: DynamicTypeSize = .accessibility3
    ) -> some View {
        self.dynamicTypeSize(min...max)
    }
}
