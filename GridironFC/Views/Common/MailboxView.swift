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
    @State private var unreadOnly = false

    private var items: [NewsItem] {
        var result = gameState.news
        if unreadOnly { result = result.filter { !$0.isRead } }
        if let filter = filter { result = result.filter { $0.category == filter } }
        return result
    }

    public var body: some View {
        List {
            Section {
                HStack {
                    Text(unreadCountLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Button("Mark All Read") {
                        gameState.markAllMailRead()
                    }
                    .font(.caption)
                    .disabled(gameState.unreadMailCount == 0)
                    .accessibilityLabel("Mark all messages as read")
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(nil, label: "All")
                        unreadChip
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
                    description: Text(unreadOnly ? "No unread messages." : "Club correspondence will appear here.")
                )
            } else {
                ForEach(items) { item in
                    MailRow(item: item)
                        .listRowBackground(item.isRead ? Color.clear : Color.accentColor.opacity(0.08))
                        .onTapGesture { gameState.markMailRead(id: item.id) }
                }
            }
        }
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { gameState.markAllMailRead() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    gameState.currentScreen = .dashboard
                }
                .accessibilityLabel("Close inbox")
            }
        }
    }

    private var unreadCountLabel: String {
        let n = gameState.unreadMailCount
        return n == 0 ? "No unread messages" : "\(n) unread"
    }

    private var unreadChip: some View {
        Button {
            unreadOnly.toggle()
        } label: {
            Text("Unread")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(unreadOnly ? Color.accentColor : Color(UIColor.secondarySystemGroupedBackground))
                .foregroundStyle(unreadOnly ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show unread messages only")
        .accessibilityAddTraits(unreadOnly ? .isSelected : [])
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
                HStack(spacing: 6) {
                    Text(item.sender)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    if !item.isRead {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 7, height: 7)
                            .accessibilityLabel("Unread")
                    }
                }
                Text(item.headline)
                    .font(.subheadline)
                    .fontWeight(item.isRead ? .semibold : .bold)
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
        .accessibilityLabel("\(item.isRead ? "" : "Unread. ")From \(item.sender). \(item.category.displayName). \(item.headline). \(item.body)")
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
