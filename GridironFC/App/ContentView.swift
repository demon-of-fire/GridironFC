//
//  ContentView.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Root navigation coordinator presenting screen flows based on GameState.currentScreen.
//  Employs NavigationStack and an accessible tabbed interface for managerial operations.
//

import SwiftUI

public struct ContentView: View {
    @Environment(GameState.self) private var gameState
    @State private var selectedTab: TabDestination = .dashboard
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            switch gameState.currentScreen {
            case .mainMenu:
                MainMenuView()
            case .clubCreation:
                ClubCreationView()
            case .clubSelect:
                ClubSelectView()
            case .playerCreation:
                PlayerCreationView()
            case .dashboard, .squad, .tactics, .standings, .fixtures, .results, .transferHub, .playerSearch, .training, .staff, .finances:
                InGameTabView(selectedTab: $selectedTab)
            case .matchDay:
                MatchDayView()
            case .liveMatch:
                LiveMatchView()
            case .postMatch:
                PostMatchView()
            case .negotiation:
                NegotiationView()
            case .settings:
                SettingsView()
            case .mailbox:
                MailboxView()
            case .matchHistory:
                MatchHistoryView()
            case .playerDetail(let playerId):
                PlayerDetailView(playerId: playerId)
            }
        }
        .dynamicTypeBounds()
    }
}

// MARK: - In-Game Tab Destinations

public enum TabDestination: String, CaseIterable, Identifiable {
    case dashboard = "Home"
    case squad = "Squad"
    case tactics = "Tactics"
    case league = "League"
    case transfers = "Transfers"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .dashboard: return "house.fill"
        case .squad: return "person.3.fill"
        case .tactics: return "list.bullet.clipboard.fill"
        case .league: return "trophy.fill"
        case .transfers: return "arrow.left.arrow.right"
        }
    }
}

// MARK: - In-Game Tab Navigation

public struct InGameTabView: View {
    @Environment(GameState.self) private var gameState
    @Binding var selectedTab: TabDestination
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(TabDestination.dashboard.rawValue, systemImage: TabDestination.dashboard.iconName)
                }
                .tag(TabDestination.dashboard)
            
            SquadView()
                .tabItem {
                    Label(TabDestination.squad.rawValue, systemImage: TabDestination.squad.iconName)
                }
                .tag(TabDestination.squad)
            
            TacticsView()
                .tabItem {
                    Label(TabDestination.tactics.rawValue, systemImage: TabDestination.tactics.iconName)
                }
                .tag(TabDestination.tactics)
            
            StandingsView()
                .tabItem {
                    Label(TabDestination.league.rawValue, systemImage: TabDestination.league.iconName)
                }
                .tag(TabDestination.league)
            
            TransferHubView()
                .tabItem {
                    Label(TabDestination.transfers.rawValue, systemImage: TabDestination.transfers.iconName)
                }
                .tag(TabDestination.transfers)
        }
        .navigationTitle(navigationTitleForTab(selectedTab))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    gameState.currentScreen = .mainMenu
                } label: {
                    Image(systemName: "house")
                }
                .accessibilityLabel("Main Menu")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        gameState.currentScreen = .mailbox
                    } label: {
                        Label("Inbox", systemImage: "tray.full")
                    }
                    Button {
                        gameState.currentScreen = .matchHistory
                    } label: {
                        Label("Match History", systemImage: "sportscourt")
                    }
                    Divider()
                    Button {
                        gameState.currentScreen = .settings
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More options")
            }
        }
    }
    
    private func navigationTitleForTab(_ tab: TabDestination) -> String {
        if let club = gameState.userClub {
            return "\(club.name) • \(tab.rawValue)"
        }
        return tab.rawValue
    }
}

// MARK: - Main Menu Screen

public struct MainMenuView: View {
    @Environment(GameState.self) private var gameState
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "sportscourt.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    
                    Text("GridironFC")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                    
                    Text("Association Football Management")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("GridironFC Football Management")
                
                if gameState.userClub != nil {
                    Button(action: {
                        gameState.currentScreen = .dashboard
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Continue Career — \(gameState.userClub?.name ?? "")")
                                .fontWeight(.semibold)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityLabel("Continue career with \(gameState.userClub?.name ?? "your club")")
                }
                
                VStack(spacing: 14) {
                    ForEach(GameMode.allCases) { mode in
                        GameModeCard(mode: mode) {
                            startMode(mode)
                        }
                    }
                }
                
                Button(action: {
                    gameState.currentScreen = .settings
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("Settings & Saves")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityLabel("Settings and saves")
                
                Text("An offline football management simulation. Player and club names are used for identification only; all badges and faces are procedurally generated.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    private func startMode(_ mode: GameMode) {
        gameState.gameMode = mode
        switch mode {
        case .createClub:
            gameState.currentScreen = .clubCreation
        case .manageClub:
            gameState.currentScreen = .clubSelect
        case .createPlayer:
            gameState.currentScreen = .playerCreation
        }
    }
}

// MARK: - Game Mode Card

public struct GameModeCard: View {
    public let mode: GameMode
    public let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(mode.modeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.displayName). \(mode.modeDescription)")
        .accessibilityHint("Double tap to start \(mode.displayName)")
    }
    
    private var iconName: String {
        switch mode {
        case .createClub: return "shield.lefthalf.filled"
        case .manageClub: return "person.badge.shield.checkmark.fill"
        case .createPlayer: return "figure.soccer"
        }
    }
}

// MARK: - Club Creation Screen

public struct ClubCreationView: View {
    @Environment(GameState.self) private var gameState
    
    @State private var clubName = "AFC Phoenix"
    @State private var shortName = "PHX"
    @State private var stadiumName = "Phoenix Arena"
    @State private var cityName = "Manchester"
    @State private var primaryColor = "#EF0107"
    @State private var secondaryColor = "#FFFFFF"
    @State private var selectedReplaceClubId: UUID?
    
    private var leagueTwoClubs: [Club] {
        return gameState.clubs.filter { $0.leagueTier == .leagueTwo }
    }
    
    public var body: some View {
        Form {
            Section(header: Text("Club Identity")) {
                TextField("Club Name", text: $clubName)
                    .accessibilityLabel("Club Name input")
                TextField("Short Name (3 Letters)", text: $shortName)
                    .textInputAutocapitalization(.characters)
                    .accessibilityLabel("Three-letter abbreviation input")
                TextField("Stadium Name", text: $stadiumName)
                    .accessibilityLabel("Stadium Name input")
                TextField("Home City", text: $cityName)
                    .accessibilityLabel("Home City input")
            }
            
            Section(header: Text("Kit & Badge Colors")) {
                HStack {
                    Text("Primary Color")
                    Spacer()
                    TextField("Hex Code", text: $primaryColor)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Secondary Color")
                    Spacer()
                    TextField("Hex Code", text: $secondaryColor)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section(header: Text("League Two Club to Replace")) {
                Picker("Club to Replace", selection: $selectedReplaceClubId) {
                    Text("Select Club").tag(nil as UUID?)
                    ForEach(leagueTwoClubs) { club in
                        Text(club.name).tag(club.id as UUID?)
                    }
                }
                .accessibilityLabel("Select League Two Club to Replace")
            }
            
            Section {
                Button(action: {
                    let targetId = selectedReplaceClubId ?? leagueTwoClubs.first?.id ?? UUID()
                    _ = gameState.createCustomClub(
                        name: clubName,
                        shortName: shortName,
                        stadium: stadiumName,
                        stadiumCapacity: 5000,
                        city: cityName,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        replaceClubId: targetId
                    )
                    
                    // Assign generated squad to the user's club
                    if let userClub = gameState.userClub {
                        var updatedUserClub = userClub
                        updatedUserClub.players = DataLoader.generateProceduralSquad(targetCount: 22, tier: .leagueTwo)
                        updatedUserClub.autoPickStartingXI()
                        gameState.clubs.removeAll { $0.id == updatedUserClub.id }
                        gameState.clubs.append(updatedUserClub)
                    }
                    
                    try? SaveManager.shared.autoSave(gameState: gameState)
                    gameState.currentScreen = .dashboard
                }) {
                    Text("Launch Franchise")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
                .disabled(clubName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Launch Franchise")
                .accessibilityHint("Finalizes club creation and opens the manager dashboard")
            }
        }
        .navigationTitle("Create Your Club")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedReplaceClubId == nil {
                selectedReplaceClubId = leagueTwoClubs.first?.id
            }
        }
    }
}

// MARK: - Club Select Screen (Manage Existing Club)

public struct ClubSelectView: View {
    @Environment(GameState.self) private var gameState
    
    @State private var searchText = ""
    @State private var selectedTier: LeagueTier? = nil
    
    private var filteredClubs: [Club] {
        gameState.clubs
            .filter { selectedTier == nil || $0.leagueTier == selectedTier }
            .filter {
                searchText.isEmpty
                || $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.shortName.localizedCaseInsensitiveContains(searchText)
            }
            .sorted {
                if $0.leagueTier != $1.leagueTier { return $0.leagueTier < $1.leagueTier }
                return $0.name < $1.name
            }
    }
    
    public var body: some View {
        List {
            Section {
                Picker("Division", selection: $selectedTier) {
                    Text("All Divisions").tag(nil as LeagueTier?)
                    ForEach(LeagueTier.allCases) { tier in
                        Text(tier.displayName).tag(tier as LeagueTier?)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Filter by division")
            }
            
            Section(header: Text("\(filteredClubs.count) Clubs")) {
                ForEach(filteredClubs) { club in
                    Button {
                        select(club)
                    } label: {
                        HStack(spacing: 14) {
                            CrestView(club: club, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(club.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(club.leagueTier.displayName) • \(club.stadium)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Rep \(club.reputation)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(club.name), \(club.leagueTier.displayName), reputation \(club.reputation)")
                    .accessibilityHint("Double tap to become the manager of \(club.name)")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search clubs")
        .navigationTitle("Select a Club")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func select(_ club: Club) {
        _ = gameState.takeOverExistingClub(clubId: club.id)
        try? SaveManager.shared.autoSave(gameState: gameState)
        gameState.currentScreen = .dashboard
    }
}

// MARK: - Player Creation Screen (Create a Player)

public struct PlayerCreationView: View {
    @Environment(GameState.self) private var gameState
    
    @State private var firstName = "Alex"
    @State private var lastName = "Hunter"
    @State private var nationality = "England"
    @State private var age = 18
    @State private var selectedPosition: Position = .ST
    @State private var preferredFoot: Foot = .right
    @State private var height = 180
    @State private var weight = 75
    @State private var selectedClubId: UUID?
    
    private var clubsSorted: [Club] {
        gameState.clubs.sorted {
            if $0.leagueTier != $1.leagueTier { return $0.leagueTier < $1.leagueTier }
            return $0.name < $1.name
        }
    }
    
    private var previewPlayer: Player {
        let attrs = DataLoader.generateAttributes(
            overall: startingOverall,
            position: selectedPosition
        )
        return Player(
            firstName: firstName.isEmpty ? "New" : firstName,
            lastName: lastName.isEmpty ? "Player" : lastName,
            nationality: nationality,
            age: age,
            height: height,
            weight: weight,
            preferredFoot: preferredFoot,
            positions: [selectedPosition],
            attributes: attrs,
            overall: startingOverall,
            potential: max(startingOverall + 8, selectedPosition == .GK ? 70 : 78)
        )
    }
    
    private var startingOverall: Int {
        // Young players begin modest and grow; GK just below outfield debutants.
        let base = selectedPosition == .GK ? 60 : 62
        return min(72, base + max(0, age - 18))
    }
    
    public var body: some View {
        Form {
            Section(header: Text("Player Identity")) {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Nationality", text: $nationality)
            }
            
            Section(header: Text("Profile")) {
                Stepper("Age: \(age)", value: $age, in: 16...40)
                Picker("Position", selection: $selectedPosition) {
                    ForEach(Position.allCases) { pos in
                        Text("\(pos.abbreviation) — \(pos.displayName)").tag(pos)
                    }
                }
                Picker("Preferred Foot", selection: $preferredFoot) {
                    ForEach(Foot.allCases) { foot in
                        Text(foot.displayName).tag(foot)
                    }
                }
                Stepper("Height: \(height) cm", value: $height, in: 160...205)
                Stepper("Weight: \(weight) kg", value: $weight, in: 55...105)
            }
            
            Section(header: Text("Starting Club")) {
                Picker("Club", selection: $selectedClubId) {
                    Text("Select Club").tag(nil as UUID?)
                    ForEach(clubsSorted) { club in
                        Text("\(club.shortName) — \(club.name)").tag(club.id as UUID?)
                    }
                }
                .accessibilityLabel("Starting club selection")
            }
            
            Section(header: Text("Preview")) {
                HStack(spacing: 16) {
                    FaceView(player: previewPlayer, size: 64, style: .full)
                        .frame(width: 64, height: 64)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(previewPlayer.fullName)
                            .font(.headline)
                        Text("\(previewPlayer.primaryPosition.displayName) • Age \(previewPlayer.age)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Overall \(previewPlayer.overall) • Potential \(previewPlayer.potential)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                Button(action: launchCareer) {
                    Text("Begin Player Career")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
                .disabled(selectedClubId == nil || firstName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Begin player career")
                .accessibilityHint("Creates your player and makes their club your managed team")
            }
        }
        .navigationTitle("Create a Player")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedClubId == nil {
                selectedClubId = gameState.clubs.first(where: { $0.leagueTier == .leagueTwo })?.id
                    ?? gameState.clubs.first?.id
            }
        }
    }
    
    private func launchCareer() {
        guard let clubId = selectedClubId,
              let clubIdx = gameState.clubs.firstIndex(where: { $0.id == clubId }) else {
            return
        }
        
        let player = previewPlayer
        gameState.clubs[clubIdx].addPlayer(player)
        _ = gameState.takeOverExistingClub(clubId: clubId)
        gameState.userPlayerId = player.id
        
        gameState.addNews(
            headline: "\(player.fullName) Begins Professional Career",
            body: "\(player.fullName), aged \(player.age), has signed for \(gameState.clubs[clubIdx].name). You now guide both the club and the player's development.",
            category: .transfer
        )
        
        try? SaveManager.shared.autoSave(gameState: gameState)
        gameState.currentScreen = .dashboard
    }
}

public struct DashboardView: View {
    @Environment(GameState.self) private var gameState
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Primary action: single Continue button
                Button(action: { gameState.advanceWeek() }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Continue")
                                .font(.headline)
                            Text(continueSubtitle)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .accessibilityLabel("Continue")
                .accessibilityHint("Advances the calendar and simulates pending matches")

                // Next Match Card
                if let nextFixture = gameState.nextUserFixture,
                   let userClub = gameState.userClub,
                   let opponentId = nextFixture.opponentId(for: userClub.id),
                   let opponent = gameState.club(withId: opponentId) {
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Next Match")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                CrestView(club: userClub, size: 34)
                                Text(userClub.shortName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(nextFixture.homeClubId == userClub.id ? "Home" : "Away")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("VS")
                                    .font(.caption)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(.tertiary)
                                Text("Matchweek \(nextFixture.matchWeek)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                CrestView(club: opponent, size: 34)
                                Text(opponent.shortName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(opponent.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button(action: {
                            gameState.activeMatchFixtureId = nextFixture.id
                            gameState.currentScreen = .matchDay
                        }) {
                            Text("Prepare for Match")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .accessibilityLabel("Prepare for match against \(opponent.name)")
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // League Standing Snapshot
                if let userClub = gameState.userClub,
                   let currentLeague = gameState.currentLeague {
                    let standings = gameState.currentLeagueStandings
                    let rank = (standings.firstIndex(where: { $0.clubId == userClub.id }) ?? 0) + 1
                    let userStanding = standings.first { $0.clubId == userClub.id }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentLeague.name)
                                .font(.headline)
                            Text("Position: \(rank) of \(standings.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(userStanding?.points ?? 0) pts")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("\(userStanding?.won ?? 0)W \(userStanding?.drawn ?? 0)D \(userStanding?.lost ?? 0)L")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // My Player Card (Create a Player mode)
                if let playerId = gameState.userPlayerId,
                   let lookup = gameState.player(withId: playerId) {
                    let player = lookup.player
                    NavigationLink(destination: PlayerDetailView(playerId: player.id)) {
                        HStack(spacing: 14) {
                            FaceView(player: player, size: 48, style: .full)
                                .frame(width: 48, height: 56)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("My Player")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(player.fullName)
                                    .font(.headline)
                                Text("Avg Rating \(String(format: "%.2f", player.seasonStats.averageRating)) • \(player.seasonStats.goals) goals")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(player.overall)")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("My player \(player.fullName), overall \(player.overall)")
                }
                
                // Club Finances Quick Snapshot
                if let userClub = gameState.userClub {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Transfer Budget")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(Player.formatCurrency(userClub.finances.transferBudget))
                                .font(.headline)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Wage Budget")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(Player.formatCurrency(userClub.finances.currentWageBill)) / \(Player.formatCurrency(userClub.finances.wageBudget))")
                                .font(.headline)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // News Feed
                VStack(alignment: .leading, spacing: 12) {
                    Text("Latest News")
                        .font(.headline)
                    
                    ForEach(gameState.news.prefix(5)) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.headline)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(item.body)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private var continueSubtitle: String {
        if let fixture = gameState.nextUserFixture {
            return "Next: Matchweek \(fixture.matchWeek) • \(fixture.date)"
        }
        return "Advance to the next calendar week"
    }
}

// MARK: - Squad Screen

public struct SquadView: View {
    @Environment(GameState.self) private var gameState
    @State private var selectedStarterId: UUID?
    @State private var substitutionBanner: String?

    public var body: some View {
        ScrollView {
            if let userClub = gameState.userClub {
                VStack(spacing: 16) {
                    FormationPitchView(
                        formation: userClub.tactics.formation,
                        players: userClub.startingXIPlayers,
                        selectedPlayerId: selectedStarterId,
                        onSelect: { player in
                            if let selected = selectedStarterId, selected != player.id {
                                selectedStarterId = nil
                                substitutionBanner = nil
                            } else {
                                selectedStarterId = (selectedStarterId == player.id) ? nil : player.id
                                if let id = selectedStarterId,
                                   let p = userClub.players.first(where: { $0.id == id }) {
                                    substitutionBanner = "Selected \(p.displayName) — tap a substitute below to swap."
                                } else {
                                    substitutionBanner = nil
                                }
                            }
                        }
                    )
                    .padding(.horizontal)

                    if let banner = substitutionBanner {
                        Text(banner)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }

                    squadSection(
                        title: "Substitutes (\(userClub.substitutePlayers.count))",
                        players: userClub.substitutePlayers,
                        clubName: userClub.name,
                        isBench: true
                    )

                    squadSection(
                        title: "Reserves (\(userClub.reservePlayers.count))",
                        players: userClub.reservePlayers,
                        clubName: userClub.name,
                        isBench: false
                    )
                }
                .padding(.vertical)
            } else {
                ContentUnavailableView("No Club", systemImage: "person.3", description: Text("Take charge of a club to view your squad."))
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    @ViewBuilder
    private func squadSection(title: String, players: [Player], clubName: String, isBench: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            ForEach(players) { player in
                VStack(spacing: 0) {
                    if isBench && selectedStarterId != nil {
                        Button {
                            if let starterId = selectedStarterId {
                                gameState.swapIntoStartingXI(playerId: player.id, replacing: starterId)
                                selectedStarterId = nil
                                substitutionBanner = nil
                            }
                        } label: {
                            HStack {
                                PlayerRowView(player: player)
                                Spacer(minLength: 4)
                                Image(systemName: "arrow.up.arrow.down.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                                    .font(.title3)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Bring on \(player.fullName)")
                        .accessibilityHint("Substitutes this player into the starting eleven")
                    } else {
                        NavigationLink(destination: PlayerDetailView(playerId: player.id)) {
                            PlayerRowView(player: player)
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                        .accessiblePlayerCard(player: player, clubName: clubName)
                    }
                    Divider().padding(.leading)
                }
            }
        }
        .padding(.vertical, 4)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
}

public struct PlayerRowView: View {
    public let player: Player
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                FaceView(player: player, size: 40)
                
                Text(player.primaryPosition.abbreviation)
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 38, height: 26)
                    .background(player.primaryPosition.category.accentColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.fullName)
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Age \(player.age) • \(player.statusBadgeText)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(player.overall)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(player.formattedValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            FaceStatStripView(player: player)
                .padding(.leading, 52)
        }
    }
}

// MARK: - Tactics Screen

public struct TacticsView: View {
    @Environment(GameState.self) private var gameState
    
    public var body: some View {
        Form {
            if let userClub = gameState.userClub {
                Section(header: Text("Formation")) {
                    Picker("Formation Preset", selection: Binding(
                        get: { userClub.tactics.formation },
                        set: { newPreset in
                            var updated = userClub
                            updated.tactics.formation = newPreset
                            updated.autoPickStartingXI()
                            gameState.clubs.removeAll { $0.id == updated.id }
                            gameState.clubs.append(updated)
                        }
                    )) {
                        ForEach(FormationPreset.allCases) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                }
                
                Section(header: Text("Tactical Instructions")) {
                    Picker("Mentality", selection: Binding(
                        get: { userClub.tactics.mentality },
                        set: { newM in
                            var updated = userClub
                            updated.tactics.mentality = newM
                            gameState.clubs.removeAll { $0.id == updated.id }
                            gameState.clubs.append(updated)
                        }
                    )) {
                        ForEach(Mentality.allCases) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    
                    Picker("Pressing", selection: Binding(
                        get: { userClub.tactics.pressing },
                        set: { newP in
                            var updated = userClub
                            updated.tactics.pressing = newP
                            gameState.clubs.removeAll { $0.id == updated.id }
                            gameState.clubs.append(updated)
                        }
                    )) {
                        ForEach(PressingIntensity.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    
                    Picker("Passing Style", selection: Binding(
                        get: { userClub.tactics.passingStyle },
                        set: { newPass in
                            var updated = userClub
                            updated.tactics.passingStyle = newPass
                            gameState.clubs.removeAll { $0.id == updated.id }
                            gameState.clubs.append(updated)
                        }
                    )) {
                        ForEach(PassingStyle.allCases) { pass in
                            Text(pass.displayName).tag(pass)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        var updated = userClub
                        updated.autoPickStartingXI()
                        gameState.clubs.removeAll { $0.id == updated.id }
                        gameState.clubs.append(updated)
                    }) {
                        Text("Auto-Pick Optimal XI")
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityLabel("Auto pick optimal eleven")
                    .accessibilityHint("Selects the highest rated available players for each position")
                }
            }
        }
    }
}

// MARK: - Standings Screen

public struct StandingsView: View {
    @Environment(GameState.self) private var gameState
    
    public var body: some View {
        List {
            Section(header: standingsHeader) {
                ForEach(Array(gameState.currentLeagueStandings.enumerated()), id: \.element.id) { index, standing in
                    let rank = index + 1
                    let club = gameState.club(withId: standing.clubId)
                    HStack {
                        Text("\(rank)")
                            .font(.caption)
                            .frame(width: 24, alignment: .leading)
                        
                        Text(club?.name ?? "Club")
                            .font(.subheadline)
                            .fontWeight(club?.isUserClub == true ? .bold : .regular)
                        
                        Spacer()
                        
                        Text("\(standing.played)")
                            .font(.caption)
                            .frame(width: 28, alignment: .trailing)
                        Text("\(standing.goalDifference)")
                            .font(.caption)
                            .frame(width: 32, alignment: .trailing)
                        Text("\(standing.points)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(width: 36, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(AccessibilityFormatter.standingRow(rank: rank, clubName: club?.name ?? "Club", standing: standing))
                }
            }
        }
    }
    
    private var standingsHeader: some View {
        HStack {
            Text("#").frame(width: 24, alignment: .leading)
            Text("Club")
            Spacer()
            Text("P").frame(width: 28, alignment: .trailing)
            Text("GD").frame(width: 32, alignment: .trailing)
            Text("Pts").frame(width: 36, alignment: .trailing)
        }
        .font(.caption)
        .fontWeight(.bold)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Transfer Hub Screen

public struct TransferHubView: View {
    @Environment(GameState.self) private var gameState
    
    public var body: some View {
        List {
            Section(header: Text("Transfer Overview")) {
                if let userClub = gameState.userClub {
                    HStack {
                        Text("Available Transfer Budget")
                        Spacer()
                        Text(Player.formatCurrency(userClub.finances.transferBudget))
                            .fontWeight(.bold)
                    }
                    HStack {
                        Text("Wage Headroom")
                        Spacer()
                        Text("\(Player.formatCurrency(userClub.finances.weeklyWageSurplus))/w")
                            .fontWeight(.bold)
                    }
                }
            }
            
            Section(header: Text("Free Agent Market (\(gameState.freeAgents.count))")) {
                if gameState.freeAgents.isEmpty {
                    Text("No free agents currently scouting.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(gameState.freeAgents.prefix(15)) { player in
                        NavigationLink(destination: PlayerDetailView(playerId: player.id)) {
                            PlayerRowView(player: player)
                        }
                    }
                }
            }
            
            Section(header: Text("Recent League Transfers")) {
                if gameState.transferHistory.isEmpty {
                    Text("No transfers registered this window.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(gameState.transferHistory.prefix(10)) { record in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.playerName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(record.fromClubName) → \(record.toClubName) • \(record.formattedFee)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Match Day Screen

public struct MatchDayView: View {
    @Environment(GameState.self) private var gameState
    
    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if let fixture = gameState.activeMatchFixture,
               let home = gameState.club(withId: fixture.homeClubId),
               let away = gameState.club(withId: fixture.awayClubId) {
                
                Text(fixture.competition)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 20) {
                    VStack {
                        Text(home.shortName)
                            .font(.largeTitle)
                            .fontWeight(.black)
                        Text(home.name)
                            .font(.caption)
                    }
                    
                    Text("VS")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    VStack {
                        Text(away.shortName)
                            .font(.largeTitle)
                            .fontWeight(.black)
                        Text(away.name)
                            .font(.caption)
                    }
                }
                
                Text("Venue: \(home.stadium)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        gameState.currentScreen = .liveMatch
                    }) {
                        Text("Live Commentary Mode")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityLabel("Launch live commentary match simulation")
                    
                    Button(action: {
                        // Quick instant simulation
                        if let idx = gameState.season.fixtures.firstIndex(where: { $0.id == fixture.id }) {
                            gameState.simulateMatch(fixture: &gameState.season.fixtures[idx])
                            gameState.finishMatchweekAfterUserMatch()
                            gameState.currentScreen = .postMatch
                        }
                    }) {
                        Text("Instant Result")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityLabel("Simulate instant match result")
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Match Day")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Post Match Screen

public struct PostMatchView: View {
    @Environment(GameState.self) private var gameState
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let fixture = gameState.activeMatchFixture,
                   let res = fixture.result,
                   let home = gameState.club(withId: fixture.homeClubId),
                   let away = gameState.club(withId: fixture.awayClubId) {
                    
                    Text("Full Time")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 24) {
                        VStack {
                            Text(home.shortName).font(.title).fontWeight(.bold)
                            Text("\(res.homeGoals)").font(.system(size: 48, weight: .black))
                        }
                        Text("-").font(.title).foregroundStyle(.secondary)
                        VStack {
                            Text(away.shortName).font(.title).fontWeight(.bold)
                            Text("\(res.awayGoals)").font(.system(size: 48, weight: .black))
                        }
                    }
                    
                    // Goal timeline
                    if !res.goalEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Goals")
                                .font(.headline)
                            ForEach(res.goalEvents) { event in
                                HStack(spacing: 10) {
                                    Text("\(event.minute)'")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 34, alignment: .trailing)
                                    Image(systemName: "soccerball")
                                        .foregroundStyle(.primary)
                                    Text(event.shortText)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(event.isHomeTeam ? home.shortName : away.shortName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }
                    
                    // Match Stats Overview
                    VStack(spacing: 8) {
                        StatComparisonRow(title: "Possession", home: "\(Int(res.homeStats.possession))%", away: "\(Int(res.awayStats.possession))%")
                        StatComparisonRow(title: "Shots", home: "\(res.homeStats.shots)", away: "\(res.awayStats.shots)")
                        StatComparisonRow(title: "Shots on Target", home: "\(res.homeStats.shotsOnTarget)", away: "\(res.awayStats.shotsOnTarget)")
                        StatComparisonRow(title: "Corners", home: "\(res.homeStats.corners)", away: "\(res.awayStats.corners)")
                        StatComparisonRow(title: "Fouls", home: "\(res.homeStats.fouls)", away: "\(res.awayStats.fouls)")
                        StatComparisonRow(title: "Expected Goals (xG)", home: String(format: "%.2f", res.homeStats.xG), away: String(format: "%.2f", res.awayStats.xG))
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    
                    if res.attendance > 0 {
                        Text("Attendance: \(res.attendance.formatted())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            gameState.currentScreen = .matchHistory
                        }) {
                            Label("View Match History", systemImage: "list.bullet.rectangle")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: {
                            gameState.currentScreen = .dashboard
                        }) {
                            Text("Return to Dashboard")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 32)
                } else {
                    ContentUnavailableView("No Match Summary", systemImage: "sportscourt", description: Text("Play a match to see the full-time recap."))
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Match Summary")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard let fixture = gameState.activeMatchFixture,
                  let res = fixture.result,
                  let userClub = gameState.userClub else { return }
            let outcome = res.outcomeLetter(for: userClub.id)
            switch outcome {
            case "W": SoundManager.shared.play(.win, enabled: gameState.soundEnabled)
            case "L": SoundManager.shared.play(.loss, enabled: gameState.soundEnabled)
            default: SoundManager.shared.play(.draw, enabled: gameState.soundEnabled)
            }
        }
    }
}

public struct StatComparisonRow: View {
    public let title: String
    public let home: String
    public let away: String
    
    public var body: some View {
        HStack {
            Text(home).frame(width: 60, alignment: .leading).fontWeight(.semibold)
            Spacer()
            Text(title).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(away).frame(width: 60, alignment: .trailing).fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

// MARK: - Player Detail Screen

public struct PlayerDetailView: View {
    @Environment(GameState.self) private var gameState
    public let playerId: UUID
    
    public var body: some View {
        ScrollView {
            if let lookup = gameState.player(withId: playerId) {
                let player = lookup.player
                let club = lookup.club
                
                VStack(spacing: 20) {
                    // Header Card
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            FaceView(player: player, size: 72, style: .full)
                                .frame(width: 72, height: 88)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(player.fullName)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                if let club = club {
                                    HStack(spacing: 6) {
                                        CrestView(club: club, size: 20)
                                        Text(club.name)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text("Free Agent")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Text("\(player.primaryPosition.displayName) • Age \(player.age) • \(player.nationality)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                        
                        HStack(spacing: 24) {
                            VStack {
                                Text("Overall")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(player.overall)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            VStack {
                                Text("Value")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(player.formattedValue)
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            VStack {
                                Text("Wage")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(player.formattedWage)
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Headline face stats (FIFA-style)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(player.primaryPosition == .GK ? "Goalkeeping" : "Face Stats")
                            .font(.headline)
                        FaceStatGridView(player: player)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Technical Attributes
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Technical Attributes").font(.headline)
                        AttributeBarView(name: "Passing", value: player.attributes.passing)
                        AttributeBarView(name: "Shooting", value: player.attributes.shooting)
                        AttributeBarView(name: "Dribbling", value: player.attributes.dribbling)
                        AttributeBarView(name: "First Touch", value: player.attributes.firstTouch)
                        AttributeBarView(name: "Crossing", value: player.attributes.crossing)
                        AttributeBarView(name: "Tackling", value: player.attributes.tackling)
                        AttributeBarView(name: "Heading", value: player.attributes.heading)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Physical Attributes
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Physical Attributes").font(.headline)
                        AttributeBarView(name: "Pace", value: player.attributes.pace)
                        AttributeBarView(name: "Stamina", value: player.attributes.stamina)
                        AttributeBarView(name: "Strength", value: player.attributes.strength)
                        AttributeBarView(name: "Agility", value: player.attributes.agility)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Transfer action: only for players not already at the user's club.
                    if let userClub = gameState.userClub, club?.id != userClub.id {
                        Button {
                            gameState.negotiationTargetPlayerId = player.id
                            gameState.currentScreen = .negotiation
                        } label: {
                            Label("Make Transfer Bid", systemImage: "arrow.left.arrow.right")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .accessibilityLabel("Make a transfer bid for \(player.fullName)")
                    }
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Player Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

public struct AttributeBarView: View {
    public let name: String
    public let value: Int
    
    public var body: some View {
        HStack {
            Text(name)
                .font(.caption)
                .frame(width: 90, alignment: .leading)
            
            ProgressView(value: Double(value), total: 99.0)
                .tint(colorForStat(value))
            
            Text("\(value)")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 28, alignment: .trailing)
        }
        .accessibleStatBar(statName: name, value: value)
    }
    
    private func colorForStat(_ stat: Int) -> Color {
        switch stat {
        case 80...99: return .green
        case 65...79: return .blue
        case 50...64: return .orange
        default: return .red
        }
    }
}

// MARK: - Settings & Saves Screen

public struct SettingsView: View {
    @Environment(GameState.self) private var gameState
    @State private var alertMessage: String?
    @State private var showAlert = false
    
    public var body: some View {
        List {
            Section(header: Text("Preferences")) {
                Toggle(isOn: Binding(
                    get: { gameState.soundEnabled },
                    set: { gameState.soundEnabled = $0 }
                )) {
                    Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                }
                .accessibilityHint("Plays sound and haptic feedback for goals, wins and losses")
            }
            
            Section(header: Text("Manual Save Slots")) {
                ForEach([SaveSlot.slot1, SaveSlot.slot2, SaveSlot.slot3], id: \.self) { slot in
                    let metadata = SaveManager.shared.getMetadata(for: slot)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(slot.displayName)
                                .font(.headline)
                            if let meta = metadata {
                                Text("\(meta.clubName) • Season \(meta.seasonYear)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Saved: \(meta.formattedRealDate)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            } else {
                                Text("Empty Slot")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Save") {
                            do {
                                try SaveManager.shared.save(gameState: gameState, to: slot)
                                alertMessage = "Career saved to \(slot.displayName)."
                                showAlert = true
                            } catch {
                                alertMessage = "Save failed: \(error.localizedDescription)"
                                showAlert = true
                            }
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Save to \(slot.displayName)")
                    }
                }
            }
            
            Section {
                Button(role: .destructive, action: {
                    gameState.currentScreen = .mainMenu
                }) {
                    Text("Exit to Main Menu")
                }
            }
        }
        .navigationTitle("Settings & Saves")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Save Manager"), message: Text(alertMessage ?? ""), dismissButton: .default(Text("OK")))
        }
    }
}

// MARK: - Negotiation View

public struct NegotiationView: View {
    @Environment(GameState.self) private var gameState
    
    @State private var bidFee: Double = 0
    @State private var wage: Double = 1_000
    @State private var contractYears = 3
    @State private var outcomeMessage: String?
    @State private var showOutcome = false
    
    private var target: (player: Player, club: Club?)? {
        guard let id = gameState.negotiationTargetPlayerId else { return nil }
        return gameState.player(withId: id)
    }
    
    public var body: some View {
        Group {
            if let lookup = target {
                form(for: lookup.player, club: lookup.club)
            } else {
                ContentUnavailableView("No Negotiation in Progress", systemImage: "arrow.left.arrow.right")
            }
        }
        .navigationTitle("Negotiate")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Transfer Update", isPresented: $showOutcome) {
            Button("OK") { gameState.currentScreen = .dashboard }
        } message: {
            Text(outcomeMessage ?? "")
        }
        .onAppear(perform: primeFields)
    }
    
    private func form(for player: Player, club: Club?) -> some View {
        Form {
            Section(header: Text("Target")) {
                HStack(spacing: 14) {
                    FaceView(player: player, size: 52, style: .full)
                        .frame(width: 52, height: 60)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(player.fullName).font(.headline)
                        Text("\(player.primaryPosition.displayName) • Age \(player.age)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(club?.name ?? "Free Agent") • Value \(player.formattedValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section(header: Text("Your Offer")) {
                VStack(alignment: .leading) {
                    Text("Transfer Fee: \(Player.formatCurrency(Int(bidFee)))")
                    Slider(value: $bidFee, in: 0...max(Double(player.value) * 1.5, 100_000), step: 50_000)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Transfer fee")
                .accessibilityValue(Player.formatCurrency(Int(bidFee)))
                
                VStack(alignment: .leading) {
                    Text("Weekly Wage: \(Player.formatCurrency(Int(wage)))/w")
                    Slider(value: $wage, in: 500...max(Double(player.wage) * 3, 50_000), step: 500)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Weekly wage offer")
                .accessibilityValue("\(Player.formatCurrency(Int(wage))) per week")
                
                Stepper("Contract: \(contractYears) years", value: $contractYears, in: 1...5)
            }
            
            if let userClub = gameState.userClub {
                Section(header: Text("Budget Check")) {
                    HStack {
                        Text("Transfer Budget")
                        Spacer()
                        Text(Player.formatCurrency(userClub.finances.transferBudget))
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Wage Headroom")
                        Spacer()
                        Text("\(Player.formatCurrency(userClub.finances.weeklyWageSurplus))/w")
                            .fontWeight(.semibold)
                    }
                }
            }
            
            Section {
                Button(action: submit) {
                    Text("Submit Bid")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
                .accessibilityLabel("Submit transfer bid")
            }
        }
    }
    
    private func primeFields() {
        guard let lookup = target else { return }
        bidFee = Double(lookup.player.value)
        wage = Double(max(lookup.player.wage, 1_000))
    }
    
    private func submit() {
        guard let id = gameState.negotiationTargetPlayerId else { return }
        let offer = gameState.submitTransferBid(
            playerId: id,
            fee: Int(bidFee),
            offeredWage: Int(wage),
            contractYears: contractYears
        )
        if offer?.status == .completed {
            outcomeMessage = "Deal completed! The player has signed for your club."
        } else {
            outcomeMessage = "Your bid was rejected. The selling club wanted a higher fee or the wage was outside your budget."
        }
        showOutcome = true
        try? SaveManager.shared.autoSave(gameState: gameState)
    }
}
