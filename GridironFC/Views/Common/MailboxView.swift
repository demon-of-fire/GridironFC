//
//  MailboxView.swift
//  GridironFC
//
//  Inbox for club correspondence (news, transfer decisions, results) and a
//  browsable match history for the user's club.
//

import SwiftUI

// MARK: - Mailbox / Messages Hub

public struct MailboxView: View {
    @Environment(GameState.self) private var gameState
    @State private var filter: NewsCategory?

    private var items: [NewsItem] {
        guard let filter = filter else { return gameState.news }
        return gameState.news.filter { $0.category == filter }
    }

    public var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(nil, label: "All")
                        ForEach(NewsCategory.allCases) { category in
                            filterChip(category, label: category.displayName)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowInsets(EdgeInsets())

            if items.isEmpty {
                ContentUnavailableView(
                    "Inbox Empty",
                    systemImage: "tray",
                    description: Text("Club correspondence will appear here.")
                )
            } else {
                ForEach(items) { item in
                    MailRow(item: item)
                }
            }
        }
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    gameState.currentScreen = .dashboard
                }
                .accessibilityLabel("Close inbox")
            }
        }
    }

    private func filterChip(_ category: NewsCategory?, label: String) -> some View {
        Button {
            filter = category
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(filter == category ? Color.accentColor : Color(UIColor.secondarySystemGroupedBackground))
                .foregroundStyle(filter == category ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(label)")
        .accessibilityAddTraits(filter == category ? .isSelected : [])
    }
}

private struct MailRow: View {
    let item: NewsItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.category.iconName)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.headline)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(item.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(item.date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.category.displayName). \(item.headline). \(item.body)")
    }
}

// MARK: - Match History

public struct MatchHistoryView: View {
    @Environment(GameState.self) private var gameState

    private var results: [MatchResult] {
        guard let userClub = gameState.userClub else { return [] }
        return userClub.seasonResults.reversed()
    }

    public var body: some View {
        List {
            if results.isEmpty {
                ContentUnavailableView(
                    "No Matches Played",
                    systemImage: "sportscourt",
                    description: Text("Your completed matches will be logged here.")
                )
            } else {
                ForEach(results, id: \.id) { result in
                    if let userClub = gameState.userClub {
                        MatchResultRow(result: result, userClub: userClub)
                    }
                }
            }
        }
        .navigationTitle("Match History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    gameState.currentScreen = .dashboard
                }
                .accessibilityLabel("Close match history")
            }
        }
    }
}

// MARK: - Shared Match Result Row

public struct MatchResultRow: View {
    public let result: MatchResult
    public let userClub: Club

    public init(result: MatchResult, userClub: Club) {
        self.result = result
        self.userClub = userClub
    }

    private var isHome: Bool { result.homeClubId == userClub.id }
    private var goalsFor: Int { isHome ? result.homeGoals : result.awayGoals }
    private var goalsAgainst: Int { isHome ? result.awayGoals : result.homeGoals }
    private var outcome: String {
        if goalsFor > goalsAgainst { return "W" }
        if goalsFor < goalsAgainst { return "L" }
        return "D"
    }
    private var outcomeColor: Color {
        switch outcome {
        case "W": return .winGreen
        case "L": return .lossRed
        default: return .drawGray
        }
    }

    public var body: some View {
        HStack(spacing: 12) {
            Text(outcome)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(outcomeColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(isHome ? "vs" : "at") opponent • MW \(result.matchWeek)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(result.competition)
                    .font(.subheadline)
                Text(result.date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text("\(goalsFor) - \(goalsAgainst)")
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(outcome). \(goalsFor) goals to \(goalsAgainst), matchweek \(result.matchWeek)")
    }
}
