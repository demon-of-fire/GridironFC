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
            case .managerCreation:
                ManagerCreationView()
            case .jobOffers:
                JobOffersView()
            case .managerProfile:
                ManagerProfileView()
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
            case .europeanCompetitions:
                EuropeanCompetitionsView()
            case .youthAcademy:
                YouthAcademyView()
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
    case inbox = "Inbox"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .dashboard: return "house.fill"
        case .squad: return "person.3.fill"
        case .tactics: return "list.bullet.clipboard.fill"
        case .league: return "trophy.fill"
        case .transfers: return "arrow.left.arrow.right"
        case .inbox: return "tray.full.fill"
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
            
            MailboxView()
                .tabItem {
                    Label(TabDestination.inbox.rawValue, systemImage: TabDestination.inbox.iconName)
                }
                .badge(gameState.unreadMailCount)
                .tag(TabDestination.inbox)
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
                    Button {
                        gameState.currentScreen = .europeanCompetitions
                    } label: {
                        Label("European Competitions", systemImage: "globe.europe.africa")
                    }
                    Button {
                        gameState.currentScreen = .youthAcademy
                    } label: {
                        Label("Youth Academy", systemImage: "figure.and.child.holdinghands")
                    }
                    Button {
                        gameState.currentScreen = .managerProfile
                    } label: {
                        Label("My Profile", systemImage: "person.crop.circle")
                    }
                    Button {
                        gameState.currentScreen = .jobOffers
                    } label: {
                        Label(
                            gameState.jobOffers.isEmpty ? "Job Offers" : "Job Offers (\(gameState.jobOffers.count))",
                            systemImage: "briefcase"
                        )
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
        // Every career mode now begins with manager customisation.
        gameState.currentScreen = .managerCreation
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
        case .unemployed: return "briefcase.fill"
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
                Menu {
                    Button("All Divisions") { selectedTier = nil }
                    ForEach(LeagueCountry.allCases) { country in
                        let tiers = LeagueTier.pyramid(for: country).filter { tier in
                            gameState.clubs.contains { $0.leagueTier == tier }
                        }
                        if !tiers.isEmpty {
                            Menu("\(country.flag) \(country.displayName)") {
                                ForEach(tiers) { tier in
                                    Button(tier.displayName) { selectedTier = tier }
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Division")
                        Spacer()
                        Text(selectedTier?.displayName ?? "All Divisions")
                            .foregroundStyle(.secondary)
                    }
                }
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

// MARK: - Manager Creation Screen

public struct ManagerCreationView: View {
    @Environment(GameState.self) private var gameState

    @State private var firstName = "Alex"
    @State private var lastName = "Morgan"
    @State private var nationality: ManagerNationality = .england
    @State private var age = 38

    // Coaching attributes (allocatable pool keeps it feel like a builder).
    @State private var tactical = 55
    @State private var attacking = 55
    @State private var defending = 55
    @State private var youth = 55

    private var previewProfile: ManagerProfile {
        ManagerProfile(
            firstName: firstName.isEmpty ? "New" : firstName,
            lastName: lastName.isEmpty ? "Manager" : lastName,
            nationality: nationality.rawValue,
            age: age,
            faceSeed: ManagerProfile.generateSeed(first: firstName, last: lastName),
            tactical: tactical,
            attacking: attacking,
            defending: defending,
            youthDevelopment: youth,
            reputation: reputationForMode
        )
    }

    /// Reputation the manager starts with, seeded by the chosen career mode.
    private var reputationForMode: Int {
        switch gameState.gameMode {
        case .unemployed: return 15
        case .createClub: return 10
        case .manageClub: return 40
        }
    }

    public var body: some View {
        Form {
            Section(header: Text("Manager Identity")) {
                TextField("First Name", text: $firstName)
                    .accessibilityLabel("Manager first name")
                TextField("Last Name", text: $lastName)
                    .accessibilityLabel("Manager last name")
                Picker("Nationality", selection: $nationality) {
                    ForEach(ManagerNationality.allCases) { nat in
                        Text("\(nat.flag) \(nat.rawValue)").tag(nat)
                    }
                }
                Stepper("Age: \(age)", value: $age, in: 30...70)
            }

            Section(header: Text("Preview")) {
                HStack(spacing: 16) {
                    FaceView(seed: previewProfile.faceSeed, size: 72, style: .full)
                        .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(previewProfile.fullName)
                            .font(.headline)
                        Text("\(previewProfile.flag) \(nationality.rawValue) • Age \(age)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Reputation \(reputationForMode)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(header: Text("Coaching Attributes")) {
                attributeSlider(title: CoachingAttribute.tactical.displayName, value: $tactical)
                attributeSlider(title: CoachingAttribute.attacking.displayName, value: $attacking)
                attributeSlider(title: CoachingAttribute.defending.displayName, value: $defending)
                attributeSlider(title: CoachingAttribute.youthDevelopment.displayName, value: $youth)
            }

            Section {
                Button(action: launch) {
                    Text("Confirm Manager")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
                .disabled(firstName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Confirm manager and continue")
            }
        }
        .navigationTitle("Create Your Manager")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func attributeSlider(title: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(value.wrappedValue)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(width: 28, alignment: .trailing)
            }
            Slider(value: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = Int($0) }
            ), in: 20...90, step: 1)
        }
    }

    private func launch() {
        gameState.manager = previewProfile
        switch gameState.gameMode {
        case .createClub:
            gameState.currentScreen = .clubCreation
        case .manageClub:
            gameState.currentScreen = .clubSelect
        case .unemployed:
            // No club; generate an initial slate of job offers and drop the user
            // straight into the Job Offers screen.
            gameState.goUnemployed()
            gameState.generateJobOffers(maxCount: 5)
            try? SaveManager.shared.autoSave(gameState: gameState)
            gameState.currentScreen = .jobOffers
        }
    }
}

// MARK: - Job Offers Screen

public struct JobOffersView: View {
    @Environment(GameState.self) private var gameState

    public var body: some View {
        List {
            Section {
                if gameState.isUnemployed {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Currently Unemployed", systemImage: "briefcase")
                            .font(.headline)
                        Text("You have no club. Accept a role below to begin your managerial career.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if let club = gameState.userClub {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("In Charge of \(club.name)", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                        Text("Accepting another role will end your current stint at \(club.name).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(header: Text("Offers (\(gameState.jobOffers.count))")) {
                if gameState.jobOffers.isEmpty {
                    VStack(spacing: 10) {
                        Text("No offers on the table right now.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Search for Vacancies") {
                            gameState.generateJobOffers(maxCount: 5)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                } else {
                    ForEach(gameState.jobOffers) { offer in
                        offerRow(offer)
                    }
                }
            }
        }
        .navigationTitle("Job Offers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    gameState.currentScreen = gameState.userClub == nil ? .jobOffers : .dashboard
                }
                .accessibilityLabel("Close job offers")
            }
        }
    }

    private func offerRow(_ offer: JobOffer) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: offer.kind.iconName)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(offer.teamName)
                        .font(.headline)
                    Text("\(offer.leagueName) • Reputation \(offer.reputation)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    gameState.acceptJobOffer(offer)
                    try? SaveManager.shared.autoSave(gameState: gameState)
                    gameState.currentScreen = .dashboard
                } label: {
                    Label("Accept", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    gameState.declineJobOffer(offer)
                } label: {
                    Label("Decline", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(offer.kind.displayName), \(offer.teamName), \(offer.leagueName), reputation \(offer.reputation)")
    }
}

// MARK: - Manager Profile Screen

public struct ManagerProfileView: View {
    @Environment(GameState.self) private var gameState

    public var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    FaceView(seed: gameState.manager.faceSeed, size: 72, style: .full)
                        .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(gameState.manager.fullName)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("\(gameState.manager.flag) \(gameState.manager.nationality) • Age \(gameState.manager.age)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let club = gameState.userClub {
                            Text("Manager of \(club.name)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Currently Unemployed")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            Section(header: Text("Reputation")) {
                HStack {
                    Text("Reputation")
                    Spacer()
                    Text("\(gameState.manager.reputation)")
                        .fontWeight(.bold)
                }
                ProgressView(value: Double(gameState.manager.reputation), total: 100)
            }

            Section(header: Text("Coaching Attributes")) {
                attributeRow(.tactical, value: gameState.manager.tactical)
                attributeRow(.attacking, value: gameState.manager.attacking)
                attributeRow(.defending, value: gameState.manager.defending)
                attributeRow(.youthDevelopment, value: gameState.manager.youthDevelopment)
            }

            Section(header: Text("Career History")) {
                if gameState.manager.careerHistory.isEmpty {
                    Text("No completed seasons yet. Finish a campaign to build your record.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(gameState.manager.careerHistory.reversed()) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(record.seasonYear) — \(record.clubName)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(record.finalPosition > 0 ? "P\(record.finalPosition)" : "—")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            Text("\(record.leagueName) • P\(record.played) W\(record.won) D\(record.drawn) L\(record.lost) • \(Int(record.winPercentage))% win rate")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(record.honours, id: \.self) { honour in
                                Label(honour, systemImage: "trophy.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    gameState.currentScreen = gameState.userClub == nil ? .jobOffers : .dashboard
                }
                .accessibilityLabel("Close profile")
            }
        }
    }

    private func attributeRow(_ attr: CoachingAttribute, value: Int) -> some View {
        HStack {
            Label(attr.displayName, systemImage: attr.iconName)
                .font(.subheadline)
            Spacer()
            Text("\(value)")
                .font(.subheadline)
                .fontWeight(.bold)
        }
    }
}

public struct DashboardView: View {
    @Environment(GameState.self) private var gameState
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Unemployed: surface job offers as the primary action.
                if gameState.isUnemployed {
                    Button(action: {
                        gameState.generateJobOffers(maxCount: 5)
                        gameState.currentScreen = .jobOffers
                    }) {
                        HStack {
                            Image(systemName: "briefcase.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Job Offers")
                                    .font(.headline)
                                Text(gameState.jobOffers.isEmpty
                                     ? "You are unemployed — search for vacancies"
                                     : "\(gameState.jobOffers.count) club(s) interested in you")
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
                    .accessibilityLabel("Job offers")
                } else {
                // Primary action: single Continue button
                Button(action: {
                    if gameState.isEndOfSeason {
                        gameState.startNewSeason()
                    } else if gameState.advanceCalendar() {
                        gameState.currentScreen = .matchDay
                    }
                }) {
                    HStack {
                        Image(systemName: gameState.isEndOfSeason ? "arrow.triangle.2.circlepath.circle.fill" : "calendar")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(gameState.isEndOfSeason ? "Start New Season" : "Continue")
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
                .accessibilityLabel(gameState.isEndOfSeason ? "Start new season" : "Continue")
                .accessibilityHint("Advances the calendar to your next match day")
                }

                // Next Match Card
                if let nextFixture = gameState.nextUserFixture,
                   let userClub = gameState.userClub,
                   let opponentId = nextFixture.opponentId(for: userClub.id),
                   let opponent = gameState.club(withId: opponentId) {
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(isMatchDay ? "Match Day" : "Next Match")
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
                                Text(nextFixture.date)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
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
        if gameState.isEndOfSeason {
            return "Season \(gameState.season.year) complete — begin next campaign"
        }
        if isMatchDay {
            return "Match day — tap to play your fixture"
        }
        if let fixture = gameState.nextUserFixture {
            return "Next: Matchweek \(fixture.matchWeek) • \(fixture.date)"
        }
        return "Advance to the next calendar week"
    }

    private var isMatchDay: Bool {
        guard let fixture = gameState.nextUserFixture else { return false }
        return fixture.date == gameState.season.currentDate
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
                    NavigationLink(destination: PlayerSearchView()) {
                        Label("Search & Sign Players", systemImage: "magnifyingglass")
                            .fontWeight(.semibold)
                    }
                    .accessibilityHint("Browse the transfer market with filters")
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

// MARK: - Player Search / Transfer Market

public struct PlayerSearchView: View {
    @Environment(GameState.self) private var gameState

    @State private var positionCategory: PositionCategory? = nil
    @State private var minOverall = 0
    @State private var maxAge = 99
    @State private var includeFreeAgents = true
    @State private var maxFeeFilter: Int? = nil
    @State private var sortMode: SortMode = .overall

    enum SortMode: String, CaseIterable, Identifiable {
        case overall = "Rating"
        case value = "Value"
        case age = "Age"
        case name = "Name"
        var id: String { rawValue }
    }

    private var results: [(player: Player, club: Club?)] {
        let base = gameState.searchPlayers(
            positionCategory: positionCategory,
            minOverall: minOverall,
            maxAge: maxAge,
            maxFee: maxFeeFilter,
            includeFreeAgents: includeFreeAgents
        )
        switch sortMode {
        case .overall: return base.sorted { $0.player.overall > $1.player.overall }
        case .value: return base.sorted { $0.player.value > $1.player.value }
        case .age: return base.sorted { $0.player.age < $1.player.age }
        case .name: return base.sorted { $0.player.lastName < $1.player.lastName }
        }
    }

    public var body: some View {
        List {
            Section(header: Text("Filters")) {
                Picker("Position", selection: $positionCategory) {
                    Text("Any").tag(PositionCategory?.none)
                    ForEach(PositionCategory.allCases) { category in
                        Text(category.displayName).tag(PositionCategory?.some(category))
                    }
                }

                Picker("Sort By", selection: $sortMode) {
                    ForEach(SortMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                HStack {
                    Text("Min Rating: \(minOverall)")
                    Slider(value: Binding(
                        get: { Double(minOverall) },
                        set: { minOverall = Int($0) }
                    ), in: 0...99, step: 1)
                }

                HStack {
                    Text("Max Age: \(maxAge == 99 ? "Any" : "\(maxAge)")")
                    Slider(value: Binding(
                        get: { Double(maxAge) },
                        set: { maxAge = Int($0) }
                    ), in: 16...40, step: 1)
                }

                Toggle("Include Free Agents", isOn: $includeFreeAgents)
            }

            Section(header: Text("\(results.count) Players Found")) {
                if results.isEmpty {
                    Text("No players match your filters.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(results.prefix(80), id: \.player.id) { entry in
                        NavigationLink(destination: PlayerDetailView(playerId: entry.player.id)) {
                            VStack(alignment: .leading, spacing: 2) {
                                PlayerRowView(player: entry.player)
                                Text(entry.club?.name ?? "Free Agent")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Transfer Market")
        .navigationBarTitleDisplayMode(.inline)
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
                    
                    // Player of the Match
                    if let potm = potmPlayer(for: res) {
                        VStack(spacing: 8) {
                            Text("Player of the Match")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 12) {
                                FaceView(player: potm.player, size: 52, style: .full)
                                    .frame(width: 52, height: 52)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(potm.player.fullName)
                                        .font(.headline)
                                    Text("\(potm.clubName) • \(potm.player.primaryPosition.abbreviation)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                    Text(String(format: "%.1f", potm.rating))
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
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
                    
                    // Rest of the league's results for this matchweek.
                    let otherResults = otherResultsThisWeek(for: fixture)
                    if !otherResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Elsewhere in Matchweek \(fixture.matchWeek)")
                                .font(.headline)
                            ForEach(otherResults, id: \.fixture.id) { entry in
                                HStack {
                                    Text(entry.homeName)
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                    Text("\(entry.result.homeGoals) - \(entry.result.awayGoals)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                    Text(entry.awayName)
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
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

    private func otherResultsThisWeek(for fixture: Fixture) -> [(fixture: Fixture, homeName: String, awayName: String, result: MatchResult)] {
        gameState.season.fixtures(forWeek: fixture.matchWeek)
            .filter { $0.isPlayed && $0.id != fixture.id && $0.competition == fixture.competition }
            .compactMap { f in
                guard let result = f.result,
                      let home = gameState.club(withId: f.homeClubId),
                      let away = gameState.club(withId: f.awayClubId) else { return nil }
                return (f, home.shortName, away.shortName, result)
            }
    }

    /// Resolves the match's Player of the Match into a displayable tuple.
    /// Prefers the engine-designated MOTM, falling back to the highest-rated
    /// player if none was recorded.
    private func potmPlayer(for res: MatchResult) -> (player: Player, clubName: String, rating: Double)? {
        var playerId = res.manOfTheMatch
        if playerId == nil {
            playerId = res.playerRatings.max(by: { $0.value < $1.value })?.key
        }
        guard let id = playerId,
              let lookup = gameState.player(withId: id) else { return nil }
        let rating = res.playerRatings[id] ?? 0
        return (lookup.player, lookup.club?.name ?? "Unknown", rating)
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    if gameState.userClub != nil {
                        gameState.currentScreen = .dashboard
                    } else {
                        gameState.currentScreen = .mainMenu
                    }
                }
                .accessibilityLabel("Close settings")
            }
        }
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

// MARK: - European Competitions Screen

public struct EuropeanCompetitionsView: View {
    @Environment(GameState.self) private var gameState
    @State private var selectedCompetition: EuropeanCompetition = .championsLeague

    private var competitionState: EuropeanCompetitionState? {
        gameState.europeanCompetitions.first { $0.competition == selectedCompetition }
    }

    public var body: some View {
        List {
            Section {
                Picker("Competition", selection: $selectedCompetition) {
                    ForEach(EuropeanCompetition.allCases) { comp in
                        Text(comp.shortName).tag(comp)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Select competition")
            }

            if let state = competitionState {
                Section(header: Text(state.competition.displayName)) {
                    if state.stage == .complete, let champ = state.championClubId {
                        HStack {
                            Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                            Text("\(gameState.club(withId: champ)?.name ?? "Champion") — Champions")
                                .fontWeight(.semibold)
                        }
                    } else {
                        Text(state.stage == .leaguePhase
                             ? "League Phase — Matchweek \(min(gameState.europeanMatchweek, state.competition.leaguePhaseMatches)) of \(state.competition.leaguePhaseMatches)"
                             : "Knockout Stage")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(header: leaguePhaseHeader) {
                    let rows = state.table()
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        let rank = index + 1
                        let club = gameState.club(withId: row.clubId)
                        HStack {
                            Text("\(rank)")
                                .font(.caption)
                                .frame(width: 24, alignment: .leading)
                            Text(club?.name ?? "Club")
                                .font(.subheadline)
                                .fontWeight(club?.isUserClub == true ? .bold : .regular)
                            Spacer()
                            Text("\(row.played)").font(.caption).frame(width: 26, alignment: .trailing)
                            Text("\(row.goalDifference)").font(.caption).frame(width: 30, alignment: .trailing)
                            Text("\(row.points)").font(.subheadline).fontWeight(.bold).frame(width: 32, alignment: .trailing)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                if let userClubId = gameState.userClubId {
                    let userFixtures = state.fixtures
                        .filter { $0.homeClubId == userClubId || $0.awayClubId == userClubId }
                        .sorted { $0.matchweek < $1.matchweek }
                    if !userFixtures.isEmpty {
                        Section(header: Text("Your \(state.competition.shortName) Fixtures")) {
                            ForEach(userFixtures) { fx in
                                EuropeanFixtureRow(fixture: fx, competitionState: state)
                            }
                        }
                    }
                }
            } else {
                Text("No European competitions loaded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("European Competitions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var leaguePhaseHeader: some View {
        HStack {
            Text("#").frame(width: 24, alignment: .leading)
            Text("Club")
            Spacer()
            Text("P").frame(width: 26, alignment: .trailing)
            Text("GD").frame(width: 30, alignment: .trailing)
            Text("Pts").frame(width: 32, alignment: .trailing)
        }
        .font(.caption)
        .fontWeight(.bold)
        .foregroundStyle(.secondary)
    }
}

private struct EuropeanFixtureRow: View {
    @Environment(GameState.self) private var gameState
    let fixture: EuropeanFixture
    let competitionState: EuropeanCompetitionState

    public var body: some View {
        let home = gameState.club(withId: fixture.homeClubId)?.name ?? "Home"
        let away = gameState.club(withId: fixture.awayClubId)?.name ?? "Away"
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(home) vs \(away)").font(.subheadline)
                Text("\(fixture.stage) • MW \(fixture.matchweek)").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if fixture.isPlayed {
                Text("\(fixture.homeGoals)–\(fixture.awayGoals)").font(.subheadline).fontWeight(.bold)
            } else {
                Text("—").foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Youth Academy Screen

public struct YouthAcademyView: View {
    @Environment(GameState.self) private var gameState
    @State private var outcomeMessage: String?
    @State private var showOutcome = false

    public var body: some View {
        List {
            if let club = gameState.userClub {
                Section(header: Text("Academy Overview")) {
                    HStack {
                        Text("Academy Level")
                        Spacer()
                        Text("\(club.youthAcademyLevel) / 5")
                            .fontWeight(.bold)
                    }
                    HStack {
                        Text("Prospects")
                        Spacer()
                        Text("\(club.academyProspects.count)")
                            .fontWeight(.bold)
                    }
                    Text("Prospects develop each season and a new intake arrives every summer. Promote promising youngsters to the senior squad.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if club.academyProspects.isEmpty {
                    Section {
                        Text("No prospects in the academy yet. A new intake arrives at the start of next season.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section(header: Text("Prospects")) {
                        ForEach(club.academyProspects.sorted { $0.potential > $1.potential }) { prospect in
                            prospectRow(prospect, club: club)
                        }
                    }
                }
            } else {
                Text("Take charge of a club to manage its youth academy.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Youth Academy")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Academy", isPresented: $showOutcome) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(outcomeMessage ?? "")
        }
    }

    private func prospectRow(_ prospect: Player, club: Club) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                FaceView(player: prospect, size: 40)
                Text(prospect.primaryPosition.abbreviation)
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 38, height: 26)
                    .background(prospect.primaryPosition.category.accentColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(prospect.fullName)
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Age \(prospect.age) • \(prospect.nationality)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(prospect.overall)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Pot \(prospect.potential)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 10) {
                Button {
                    promote(prospect)
                } label: {
                    Label("Promote", systemImage: "arrow.up.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    release(prospect)
                } label: {
                    Label("Release", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            .padding(.leading, 52)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(prospect.fullName), \(prospect.primaryPosition.displayName), age \(prospect.age), overall \(prospect.overall), potential \(prospect.potential)")
    }

    private func promote(_ prospect: Player) {
        guard let clubIdx = gameState.clubs.firstIndex(where: { $0.isUserClub }) else { return }
        if let promoted = gameState.clubs[clubIdx].promoteProspect(withId: prospect.id) {
            gameState.addNews(
                headline: "\(promoted.fullName) Promoted to First Team",
                body: "Academy graduate \(promoted.fullName) (age \(promoted.age), \(promoted.primaryPosition.displayName)) has been promoted to the senior squad.",
                category: .board,
                sender: "Head of Youth Development"
            )
            outcomeMessage = "\(promoted.fullName) has joined the senior squad."
        } else {
            outcomeMessage = "Could not promote that prospect."
        }
        showOutcome = true
        try? SaveManager.shared.autoSave(gameState: gameState)
    }

    private func release(_ prospect: Player) {
        guard let clubIdx = gameState.clubs.firstIndex(where: { $0.isUserClub }) else { return }
        if gameState.clubs[clubIdx].releaseProspect(withId: prospect.id) != nil {
            outcomeMessage = "\(prospect.fullName) has been released from the academy."
        }
        showOutcome = true
        try? SaveManager.shared.autoSave(gameState: gameState)
    }
}
