//
//  GameState.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Root @Observable state container managing world simulation, calendar advancement,
//  match simulation, AI club activities, news feed, and UI navigation.
//

import Foundation
import Observation

// MARK: - News Item Model

public struct NewsItem: Codable, Identifiable, Hashable {
    public let id: UUID
    public var headline: String
    public var body: String
    public var date: String
    public var category: NewsCategory
    /// Who the correspondence is from (e.g. "The Board", "Agent", "Club Secretary").
    public var sender: String
    /// Whether the manager has opened this message.
    public var isRead: Bool
    /// When set, this message is an actionable transfer negotiation and links to
    /// the referenced offer so the inbox can present Accept / Reject / Counter.
    public var transferOfferId: UUID?

    public init(
        id: UUID = UUID(),
        headline: String,
        body: String,
        date: String,
        category: NewsCategory,
        sender: String = "Club News Desk",
        isRead: Bool = false,
        transferOfferId: UUID? = nil
    ) {
        self.id = id
        self.headline = headline
        self.body = body
        self.date = date
        self.category = category
        self.sender = sender
        self.isRead = isRead
        self.transferOfferId = transferOfferId
    }

    private enum CodingKeys: String, CodingKey {
        case id, headline, body, date, category, sender, isRead, transferOfferId
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        headline = try c.decode(String.self, forKey: .headline)
        body = try c.decode(String.self, forKey: .body)
        date = try c.decode(String.self, forKey: .date)
        category = try c.decode(NewsCategory.self, forKey: .category)
        sender = try c.decodeIfPresent(String.self, forKey: .sender) ?? "Club News Desk"
        isRead = try c.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        transferOfferId = try c.decodeIfPresent(UUID.self, forKey: .transferOfferId)
    }
}

// MARK: - Game State Class

@Observable
public final class GameState: Codable {
    
    // Core Game Setup
    public var gameMode: GameMode
    public var clubs: [Club]
    public var leagues: [League]
    public var season: Season
    public var userClubId: UUID?
    
    // Global Market & History
    public var freeAgents: [Player]
    public var transferHistory: [TransferRecord]
    public var pendingTransferOffers: [TransferOffer]
    public var news: [NewsItem]
    
    // Navigation & Live Match Context
    public var currentScreen: AppScreen
    public var isMatchInProgress: Bool
    public var activeMatchFixtureId: UUID?
    public var negotiationTargetPlayerId: UUID?
    
    // Preferences
    public var soundEnabled: Bool
    /// In-match user preferences (speed, half-time stop, auto-substitution rules).
    public var matchSettings: MatchSettings
    
    // Managerial Career
    public var manager: ManagerProfile
    public var jobOffers: [JobOffer]
    // Ownership Career. This remains independent of the manager profile so an
    // owner never becomes the person selecting the XI.
    public var owner: OwnerProfile
    /// Ensures a manager can run only one dedicated training session per week.
    public var lastTrainingWeek: Int?
    /// Board expectations and job security for the manager career.
    public var jobSecurity: JobSecurity
    /// This week's team talk, applied once before/during matchday preparation.
    public var teamTalk: TeamTalkStyle?
    public var teamTalkAppliedWeek: Int?
    
    // European club competitions (Champions League, Europa League, Conference League)
    public var europeanCompetitions: [EuropeanCompetitionState]
    /// European matchweek pointer; advances alongside the domestic calendar.
    public var europeanMatchweek: Int

    // International management (national teams + tournaments)
    public var nationalTeams: [NationalTeam]
    public var internationalTournaments: [InternationalTournament.State]
    /// The national team the user is currently managing, if any.
    public var managedNationalTeamId: String?
    
    // MARK: - Initializer
    
    public init(
        gameMode: GameMode = .createClub,
        clubs: [Club] = [],
        leagues: [League] = [],
        season: Season = Season(),
        userClubId: UUID? = nil,
        freeAgents: [Player] = [],
        transferHistory: [TransferRecord] = [],
        pendingTransferOffers: [TransferOffer] = [],
        news: [NewsItem] = [],
        currentScreen: AppScreen = .mainMenu,
        isMatchInProgress: Bool = false,
        activeMatchFixtureId: UUID? = nil,
        negotiationTargetPlayerId: UUID? = nil,
        soundEnabled: Bool = true,
        matchSettings: MatchSettings = MatchSettings(),
        manager: ManagerProfile = ManagerProfile(),
        jobOffers: [JobOffer] = [],
        owner: OwnerProfile = OwnerProfile(),
        lastTrainingWeek: Int? = nil,
        jobSecurity: JobSecurity = JobSecurity(),
        teamTalk: TeamTalkStyle? = nil,
        teamTalkAppliedWeek: Int? = nil,
        europeanCompetitions: [EuropeanCompetitionState] = [],
        europeanMatchweek: Int = 0,
        nationalTeams: [NationalTeam] = [],
        internationalTournaments: [InternationalTournament.State] = [],
        managedNationalTeamId: String? = nil
    ) {
        self.gameMode = gameMode
        self.clubs = clubs
        self.leagues = leagues
        self.season = season
        self.userClubId = userClubId
        self.freeAgents = freeAgents
        self.transferHistory = transferHistory
        self.pendingTransferOffers = pendingTransferOffers
        self.news = news
        self.currentScreen = currentScreen
        self.isMatchInProgress = isMatchInProgress
        self.activeMatchFixtureId = activeMatchFixtureId
        self.negotiationTargetPlayerId = negotiationTargetPlayerId
        self.soundEnabled = soundEnabled
        self.matchSettings = matchSettings
        self.manager = manager
        self.jobOffers = jobOffers
        self.owner = owner
        self.lastTrainingWeek = lastTrainingWeek
        self.jobSecurity = jobSecurity
        self.teamTalk = teamTalk
        self.teamTalkAppliedWeek = teamTalkAppliedWeek
        self.europeanCompetitions = europeanCompetitions
        self.europeanMatchweek = europeanMatchweek
        self.nationalTeams = nationalTeams
        self.internationalTournaments = internationalTournaments
        self.managedNationalTeamId = managedNationalTeamId
    }    // MARK: - Computed Properties
    
    public var userClub: Club? {
        guard let id = userClubId else { return nil }
        return clubs.first { $0.id == id }
    }
    
    /// True when the user has a manager profile but no club (started unemployed
    /// or between jobs).
    public var isUnemployed: Bool {
        return userClub == nil
    }
    
    public var currentLeague: League? {
        guard let club = userClub else { return nil }
        return leagues.first { $0.tier == club.leagueTier }
    }
    
    public var activeMatchFixture: Fixture? {
        guard let id = activeMatchFixtureId else { return nil }
        return season.fixtures.first { $0.id == id }
    }
    
    public var nextUserFixture: Fixture? {
        guard let userClubId = userClubId else { return nil }
        return season.upcomingFixtures(forClub: userClubId).first
    }
    
    public var recentUserResults: [MatchResult] {
        guard let userClub = userClub else { return [] }
        return userClub.seasonResults.suffix(5).reversed()
    }
    
    public var currentLeagueStandings: [LeagueStanding] {
        guard let league = currentLeague else { return [] }
        return standings(for: league)
    }
    
    public func standings(for league: League) -> [LeagueStanding] {
        var table: [UUID: LeagueStanding] = [:]
        
        for clubId in league.clubIds {
            table[clubId] = LeagueStanding(clubId: clubId)
        }
        
        let leagueFixtures = season.fixtures.filter { f in
            league.clubIds.contains(f.homeClubId) && f.isPlayed
        }
        
        for f in leagueFixtures {
            guard let res = f.result else { continue }
            table[f.homeClubId]?.recordResult(goalsFor: res.homeGoals, goalsAgainst: res.awayGoals)
            table[f.awayClubId]?.recordResult(goalsFor: res.awayGoals, goalsAgainst: res.homeGoals)
        }
        
        return table.values.sorted(by: LeagueStanding.standardSort)
    }
    
    public func club(withId id: UUID) -> Club? {
        return clubs.first { $0.id == id }
    }
    
    public func player(withId id: UUID) -> (player: Player, club: Club?)? {
        for club in clubs {
            if let p = club.player(withId: id) {
                return (p, club)
            }
        }
        if let freeP = freeAgents.first(where: { $0.id == id }) {
            return (freeP, nil)
        }
        return nil
    }
    
    /// Every player in the world except the user's own squad, paired with their club
    /// (nil for free agents). Used by the transfer search screen.
    public func transferSearchCandidates() -> [(player: Player, club: Club?)] {
        var results: [(Player, Club?)] = []
        for club in clubs where !club.isUserClub {
            for player in club.players {
                results.append((player, club))
            }
        }
        for freeAgent in freeAgents {
            results.append((freeAgent, nil))
        }
        return results
    }
    
    /// Filters transfer candidates by optional criteria.
    public func searchPlayers(
        positionCategory: PositionCategory? = nil,
        specificPosition: Position? = nil,
        minOverall: Int = 0,
        maxAge: Int = 99,
        maxFee: Int? = nil,
        includeFreeAgents: Bool = true
    ) -> [(player: Player, club: Club?)] {
        transferSearchCandidates().filter { entry in
            let player = entry.player
            if let category = positionCategory,
               !player.positions.contains(where: { $0.category == category }) {
                return false
            }
            if let specific = specificPosition,
               !player.positions.contains(specific) {
                return false
            }
            if player.overall < minOverall { return false }
            if player.age > maxAge { return false }
            if !includeFreeAgents && entry.club == nil { return false }
            if let maxFee = maxFee, let club = entry.club, player.value > maxFee { return false }
            return true
        }
    }
    
    // MARK: - Calendar & Progression
    
    /// Advances the in-game calendar by 1 day.
    public func advanceDay() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let currentDate = formatter.date(from: season.currentDate),
              let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else {
            return
        }
        
        season.currentDate = formatter.string(from: nextDate)
    }
    
    /// Advances the in-game calendar day by day toward the user's next fixture.
    /// Fixtures that do not involve the user's club are simulated as their matchweek
    /// arrives, but the user's own match is left unplayed so they can manage and play it.
    /// Returns `true` when it reaches the user's match day (caller should show Match Day).
    @discardableResult
    public func advanceCalendar() -> Bool {
        if isEndOfSeason { return false }
        guard let userClubId = userClubId,
              let nextFixture = season.nextFixture(forClub: userClubId) else {
            return false
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard var date = formatter.date(from: season.currentDate),
              let targetDate = formatter.date(from: nextFixture.date) else {
            return false
        }
        
        // Step one day at a time so any intervening matchweeks get simulated.
        while date < targetDate {
            date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? targetDate
            season.currentDate = formatter.string(from: date)
            simulateDueWeeks(excludingUserMatch: true)
        }
        
        // Arrived at match day: surface the user's fixture and their matchweek.
        season.currentWeek = nextFixture.matchWeek
        activeMatchFixtureId = nextFixture.id
        return true
    }
    
    /// Simulates every unplayed fixture in matchweeks whose date has already passed,
    /// optionally leaving the user's own fixtures for the player to manage.
    private func simulateDueWeeks(excludingUserMatch: Bool) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let today = formatter.date(from: season.currentDate) else { return }
        
        for idx in season.fixtures.indices {
            let fixture = season.fixtures[idx]
            guard !fixture.isPlayed else { continue }
            guard let fixtureDate = formatter.date(from: fixture.date) else { continue }
            guard fixtureDate <= today else { continue }
            if excludingUserMatch, let userClubId, fixture.involves(clubId: userClubId) {
                continue
            }
            simulateMatch(fixture: &season.fixtures[idx])
        }
    }

    /// Simulates every remaining unplayed fixture in the current matchweek, then
    /// performs weekly upkeep (fitness, finances, AI transfers), advances the
    /// calendar, and checks for season completion. Shared by `advanceWeek()` and
    /// the post-user-match flow so the rest of the league always keeps pace.
    /// Each completed matchday is auto-saved, overwriting the previous autosave.
    public func finishMatchweekAfterUserMatch() {
        advanceWeek()
        try? SaveManager.shared.autoSave(gameState: self)
    }

    /// Advances the in-game week: simulates all pending matchweek matches, recovers fitness,
    /// runs AI transfer evaluation, updates financial balances, and checks promotion/relegation.
    public func advanceWeek() {
        // 1. Simulate all unplayed fixtures of the current matchweek
        let currentWeekFixtures = season.fixtures(forWeek: season.currentWeek).filter { !$0.isPlayed }
        for fixture in currentWeekFixtures {
            if let idx = season.fixtures.firstIndex(where: { $0.id == fixture.id }) {
                simulateMatch(fixture: &season.fixtures[idx])
            }
        }
        
        // 2. Weekly player fitness recovery & sharpness decay
        for clubIdx in 0..<clubs.count {
            for playerIdx in 0..<clubs[clubIdx].players.count {
                clubs[clubIdx].players[playerIdx].advanceWeekRecovery()
            }
            // Weekly financial accounting. Home clubs bank gate receipts scaled
            // by the calibre of the visiting side.
            let homeFixture = season.fixtures(forWeek: season.currentWeek)
                .first { $0.homeClubId == clubs[clubIdx].id }
            var gate = 0
            if let homeFixture,
               let away = club(withId: homeFixture.awayClubId) {
                gate = clubs[clubIdx].finances.matchdayRevenue(opponentReputation: away.reputation)
            }
            clubs[clubIdx].finances.processWeeklyCashFlow(
                isHomeMatchThisWeek: homeFixture != nil,
                gateReceipts: gate
            )
        }
        
        // 3. AI manager autonomous dealings and transfer negotiation resolution
        processAITransfers()
        processTransferNegotiations()
        processAIIncomingBids()
        
        // 4. Advance calendar date by 7 days
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let currentDate = formatter.date(from: season.currentDate),
           let nextWeekDate = Calendar.current.date(byAdding: .day, value: 7, to: currentDate) {
            season.currentDate = formatter.string(from: nextWeekDate)
        }
        
        // 5. Advance matchweek counter
        season.currentWeek += 1

        // 5b. Advance European competitions (one European matchweek from domestic week 3).
        advanceEuropeanCompetitions()
        
        // 5c. Advance international tournaments.
        advanceInternationalTournaments()
        
        // 6. Check if season has completed
        if season.isSeasonFinished && season.currentPhase != .endOfSeason {
            processEndOfSeason()
        }
    }

    /// Advances every European competition one matchweek, simulating its fixtures
    /// with an Elo-style scoreline derived from club strength. Lakes a week off to
    /// avoid clashing with the very start of the domestic season.
    public func advanceEuropeanCompetitions() {
        guard !europeanCompetitions.isEmpty else { return }
        guard season.currentWeek >= 3 else { return }

        europeanMatchweek += 1
        let week = europeanMatchweek

        for idx in europeanCompetitions.indices {
            var competition = europeanCompetitions[idx]
            competition.advanceMatchweek(week: week) { [weak self] home, away in
                guard let self, let hc = self.club(withId: home), let ac = self.club(withId: away) else {
                    return (0, 0)
                }
                return Self.simulateEuropeanScore(home: hc, away: ac)
            }

            // Surface the final result as news when a champion is crowned.
            if competition.stage == .complete, competition.championClubId != nil,
               europeanCompetitions[idx].championClubId == nil,
               let champ = competition.championClubId {
                addNews(
                    headline: "\(clubName(for: champ)) Win the \(competition.competition.displayName)!",
                    body: "\(clubName(for: champ)) are crowned champions of Europe.",
                    category: .award
                )
            }

            europeanCompetitions[idx] = competition
        }
    }

    // MARK: - International Management

    /// Builds international tournaments from the loaded national teams. Called at
    /// boot and after a data reload.
    public func seedInternationalTournaments() {
        guard !nationalTeams.isEmpty else { return }
        if internationalTournaments.isEmpty {
            internationalTournaments = InternationalTournamentBuilder.build(from: nationalTeams)
        }
    }

    public func nationalTeam(withId id: String) -> NationalTeam? {
        nationalTeams.first { $0.id == id }
    }

    /// The national team the user currently manages, if any.
    public var managedNationalTeam: NationalTeam? {
        guard let id = managedNationalTeamId else { return nil }
        return nationalTeam(withId: id)
    }

    /// Takes charge of a national team.
    public func takeOverNationalTeam(id: String) {
        guard nationalTeams.contains(where: { $0.id == id }) else { return }
        managedNationalTeamId = id
        if let team = nationalTeam(withId: id) {
            addNews(
                headline: "You Are the New \(team.name) Manager",
                body: "The \(team.name) federation has appointed you as head coach. Your first task is to prepare the squad for international competition.",
                category: .board,
                sender: "\(team.name) Federation"
            )
        }
    }

    public func resignNationalTeam() {
        managedNationalTeamId = nil
    }

    /// Advances all international tournaments one round, simulating every unplayed
    /// fixture from national-team strength.
    public func advanceInternationalTournaments() {
        guard !internationalTournaments.isEmpty else { return }
        for idx in internationalTournaments.indices {
            var tournament = internationalTournaments[idx]
            tournament.simulateAll { [weak self] homeId, awayId in
                guard let self,
                      let home = self.nationalTeam(withId: homeId),
                      let away = self.nationalTeam(withId: awayId) else { return (0, 0) }
                return Self.simulateNationalScore(home: home.strength, away: away.strength)
            }

            if tournament.stage == .complete, tournament.championId != nil,
               internationalTournaments[idx].championId == nil,
               let championId = tournament.championId {
                let name = nationalTeam(withId: championId)?.name ?? championId
                addNews(
                    headline: "\(name) Win the \(tournament.kind.displayName)!",
                    body: "\(name) are crowned champions of the \(tournament.kind.displayName).",
                    category: .award
                )
            }

            internationalTournaments[idx] = tournament
        }
    }

    /// A lightweight international scoreline from two teams' strengths.
    static func simulateNationalScore(home: Double, away: Double) -> (Int, Int) {
        let diff = ((home + 2.0) - away) / 8.0   // small home advantage
        var rng = SystemRandomNumberGenerator()
        func goals(for attackDiff: Double) -> Int {
            let expected = max(0.15, 1.25 + attackDiff)
            var goals = 0
            let probability = expected / (expected + 1.0)
            for _ in 0..<6 {
                if Double.random(in: 0...1, using: &rng) < probability * 0.85 { goals += 1 }
            }
            return min(goals, 6)
        }
        return (goals(for: diff), goals(for: -diff))
    }

    /// European-night scoreline approximation from two clubs' starting XIs.
    static func simulateEuropeanScore(home: Club, away: Club) -> (Int, Int) {
        func strength(_ club: Club) -> Double {
            let xi = club.players.sorted { $0.overall > $1.overall }.prefix(11)
            guard !xi.isEmpty else { return 60 }
            return Double(xi.map { $0.overall }.reduce(0, +)) / Double(xi.count)
        }
        let homeStrength = strength(home) + 3.0   // home advantage
        let awayStrength = strength(away)
        let diff = (homeStrength - awayStrength) / 8.0

        var rng = SystemRandomNumberGenerator()
        func goals(for attackDiff: Double) -> Int {
            let base = 1.25 + attackDiff
            let expected = max(0.15, base)
            var goals = 0
            let probability = expected / (expected + 1.0)
            for _ in 0..<6 {
                if Double.random(in: 0...1, using: &rng) < probability * 0.85 { goals += 1 }
            }
            return min(goals, 6)
        }
        return (goals(for: diff), goals(for: -diff))
    }

    /// True once all fixtures are played and the end-of-season processing has run.
    public var isEndOfSeason: Bool {
        season.currentPhase == .endOfSeason
    }
    
    // MARK: - Match Engine Simulation
    
    /// Simulates a single fixture by delegating to the shared `MatchEngine`, then
    /// writes the updated rosters (fatigue, injuries, stats) and result back into world state.
    public func simulateMatch(fixture: inout Fixture) {
        guard !fixture.isPlayed else { return }
        guard let homeIdx = clubs.firstIndex(where: { $0.id == fixture.homeClubId }),
              let awayIdx = clubs.firstIndex(where: { $0.id == fixture.awayClubId }) else {
            return
        }
        
        var homeClub = clubs[homeIdx]
        var awayClub = clubs[awayIdx]
        
        let config = MatchEngine.SimulationConfig(
            neutralVenue: false,
            matchWeek: fixture.matchWeek,
            competition: fixture.competition,
            date: fixture.date,
            isKnockout: false
        )
        
        let result = MatchEngine.simulateFullMatch(home: &homeClub, away: &awayClub, config: config)
        
        homeClub.seasonResults.append(result)
        awayClub.seasonResults.append(result)
        
        clubs[homeIdx] = homeClub
        clubs[awayIdx] = awayClub
        
        fixture.isPlayed = true
        fixture.result = result

        if fixture.involves(clubId: userClubId ?? UUID()) {
            updateBoardConfidence(after: result, userWasHome: fixture.homeClubId == userClubId)
        }
    }
    
    // MARK: - User Transfer Bidding
    
    /// Opens a transfer negotiation by submitting an opening bid from the user's
    /// club for a player at another club, or signing a free agent. Bids are no
    /// longer resolved instantly: they are logged as live offers and the selling
    /// club responds (accept / reject / counter) over the following weeks.
    @discardableResult
    public func submitTransferBid(
        playerId: UUID,
        fee: Int,
        offeredWage: Int,
        contractYears: Int = 3
    ) -> TransferOffer? {
        guard let userClubId = userClubId,
              let buyerIdx = clubs.firstIndex(where: { $0.id == userClubId }) else {
            return nil
        }

        // Resolve the target player and their current club (nil = free agent).
        var sellerIdx: Int? = nil
        var targetPlayer: Player? = nil
        for (idx, club) in clubs.enumerated() where !club.isUserClub {
            if let p = club.player(withId: playerId) {
                sellerIdx = idx
                targetPlayer = p
                break
            }
        }
        let isFreeAgent: Bool
        if targetPlayer == nil, let freeP = freeAgents.first(where: { $0.id == playerId }) {
            targetPlayer = freeP
            isFreeAgent = true
        } else {
            isFreeAgent = false
        }

        guard let player = targetPlayer else { return nil }

        let buyer = clubs[buyerIdx]
        let askingPrice = sellingValuation(for: player, at: sellerIdx.map { clubs[$0] }, buyerReputation: buyer.reputation)

        var offer = TransferOffer(
            playerId: playerId,
            fromClubId: sellerIdx.map { clubs[$0].id } ?? UUID(),
            toClubId: userClubId,
            fee: fee,
            isLoan: false,
            status: .pending,
            offeredWage: offeredWage,
            contractYears: contractYears,
            askingPrice: askingPrice,
            isIncoming: false,
            createdDate: season.currentDate,
            weeksUntilResponse: isFreeAgent ? 0 : 1
        )

        // Budget sanity: the buyer can never commit more than the bank allows.
        let canAffordFee = isFreeAgent || fee <= buyer.finances.transferBudget
        if !canAffordFee {
            offer.status = .rejected
            pendingTransferOffers.append(offer)
            addNews(
                headline: "Bid for \(player.fullName) Rejected",
                body: "The transfer fee exceeded \(buyer.name)'s budget. Raise funds before bidding again.",
                category: .transfer,
                sender: "Club Secretary"
            )
            return offer
        }

        // Free agents go straight to personal terms; contract players await the club.
        if isFreeAgent {
            offer.status = .personalTerms
        }

        pendingTransferOffers.append(offer)
        addNews(
            headline: "Bid Submitted for \(player.fullName)",
            body: "You have tabled a \(Player.formatCurrency(fee)) bid\(isFreeAgent ? "" : " to \(sellerIdx.map { clubs[$0].name } ?? "the club")") for \(player.fullName). Expect a response in the coming days.",
            category: .transfer,
            sender: "Director of Football",
            transferOfferId: offer.id
        )
        return offer
    }

    /// Realistic asking price: market value adjusted for the seller's need and
    /// reputation, with a premium for players on long, secure contracts.
    private func sellingValuation(for player: Player, at seller: Club?, buyerReputation: Int) -> Int {
        var value = Double(player.value)
        // Long contracts mean the seller can demand a premium; expiring deals a discount.
        let years = Double(player.contract?.yearsRemaining ?? 1)
        value *= 1.0 + max(0, min(3, years - 1)) * 0.12
        // A big club selling to a smaller one digs in for more.
        if let seller = seller {
            let gap = Double(seller.reputation - buyerReputation)
            value *= 1.0 + max(-0.15, min(0.35, gap / 100.0))
        }
        // Young high-potential players carry a scarcity premium.
        if player.age <= 23, player.potential - player.overall >= 8 {
            value *= 1.15
        }
        return max(10_000, Int(value))
    }

    /// The wage a player will demand to sign, scaling with their valuation and the
    /// gap between the buyer and seller's stature.
    private func wageDemand(for player: Player, buyer: Club, seller: Club?) -> Int {
        let base = max(player.wage, player.value / 250)
        var demand = Double(base)
        if let seller = seller, seller.reputation > buyer.reputation {
            demand *= 1.0 + min(0.5, Double(seller.reputation - buyer.reputation) / 120.0)
        }
        demand *= Double.random(in: 0.95...1.15)
        return max(500, Int(demand))
    }

    /// Resolves every live transfer negotiation one step: selling clubs evaluate
    /// bids (accept / reject / counter), players decide personal terms, and stances
    /// are surfaced to the inbox. Runs each week from `advanceWeek`.
    public func processTransferNegotiations() {
        guard let userClubId = userClubId else {
            // Even without a user club, age out stale offers.
            pendingTransferOffers.removeAll { !$0.isLive && $0.weeksUntilResponse <= 0 }
            return
        }

        for idx in pendingTransferOffers.indices {
            guard pendingTransferOffers[idx].isLive else { continue }

            // Count down the response timer.
            if pendingTransferOffers[idx].weeksUntilResponse > 0 {
                pendingTransferOffers[idx].weeksUntilResponse -= 1
                continue
            }

            resolveOffer(at: idx, userClubId: userClubId)
        }

        // Drop offers that have been dead for a while to stop the array growing forever.
        pruneResolvedOffers()
    }

    /// Resolves a single live offer based on its current status.
    private func resolveOffer(at idx: Int, userClubId: UUID) {
        var offer = pendingTransferOffers[idx]
        guard let (player, _) = player(withId: offer.playerId) else {
            offer.status = .withdrawn
            pendingTransferOffers[idx] = offer
            return
        }

        // Incoming bids (AI club bidding for a user player) are handled elsewhere;
        // here we only auto-resolve outgoing user bids and free-agent terms.
        guard !offer.isIncoming else { return }

        switch offer.status {
        case .personalTerms:
            resolvePersonalTerms(at: idx, player: player, userClubId: userClubId)
        case .pending, .counterOffer, .accepted:
            resolveClubFee(at: idx, player: player, userClubId: userClubId)
        default:
            break
        }
    }

    /// The selling club evaluates the (possibly countered) fee.
    private func resolveClubFee(at idx: Int, player: Player, userClubId: UUID) {
        var offer = pendingTransferOffers[idx]
        guard let sellerIdx = clubs.firstIndex(where: { $0.id == offer.fromClubId }) else {
            offer.status = .rejected
            pendingTransferOffers[idx] = offer
            return
        }
        let seller = clubs[sellerIdx]
        let bid = Double(offer.fee)
        let asking = Double(offer.askingPrice)

        // Ladder of tolerance: met-or-beat is done; near-misses get a counter or a
        // random accept; lowballs are rejected.
        if bid >= asking {
            offer.status = .completed
            completeSigning(player: player, buyerIdx: clubs.firstIndex(where: { $0.id == userClubId })!, sellerIdx: sellerIdx, fee: offer.fee, wage: offer.offeredWage ?? player.wage, years: offer.contractYears ?? 3)
            completeOfferMessage(offer, player: player)
            pendingTransferOffers[idx] = offer
            return
        }

        if bid >= asking * 0.9 {
            // Close enough — the club usually accepts, sometimes counters once more.
            if offer.negotiationRound >= 2 || Double.random(in: 0...1) < 0.6 {
                offer.status = .completed
                completeSigning(player: player, buyerIdx: clubs.firstIndex(where: { $0.id == userClubId })!, sellerIdx: sellerIdx, fee: offer.fee, wage: offer.offeredWage ?? player.wage, years: offer.contractYears ?? 3)
                completeOfferMessage(offer, player: player)
            } else {
                issueCounter(at: idx, offer: offer, seller: seller, player: player)
            }
            pendingTransferOffers[idx] = offer
            return
        }

        if bid >= asking * 0.7 {
            // Meaningfully short — counter with a figure they can accept.
            issueCounter(at: idx, offer: offer, seller: seller, player: player)
            pendingTransferOffers[idx] = offer
            return
        }

        // Lowball rejection.
        offer.status = .rejected
        pendingTransferOffers[idx] = offer
        addNews(
            headline: "Bid for \(player.fullName) Rejected",
            body: "\(seller.name) dismissed your \(Player.formatCurrency(offer.fee)) bid as far below their valuation of \(Player.formatCurrency(offer.askingPrice)).",
            category: .transfer,
            sender: "Director of Football"
        )
    }

    /// Issues a counter-offer from the selling club, routed to the inbox.
    private func issueCounter(at idx: Int, offer: TransferOffer, seller: Club, player: Player) {
        var offer = offer
        let target: Double
        if let existing = offer.counterFee {
            // Converge toward the asking price from the last counter.
            target = Double(existing) + (Double(offer.askingPrice) - Double(existing)) * 0.5
        } else {
            target = Double(offer.askingPrice)
        }
        offer.counterFee = Int(max(Double(offer.fee), target))
        offer.negotiationRound += 1
        offer.status = .counterOffer
        offer.weeksUntilResponse = 1
        pendingTransferOffers[idx] = offer

        addNews(
            headline: "\(seller.name) Counter Your Bid for \(player.fullName)",
            body: "\(seller.name) want \(Player.formatCurrency(offer.counterFee ?? offer.askingPrice)) for \(player.fullName) — your offer was \(Player.formatCurrency(offer.fee)). Accept, reject, or raise your bid.",
            category: .transfer,
            sender: seller.name,
            transferOfferId: offer.id
        )
    }

    /// A free agent (or a club-approved move) settles personal terms with the player.
    private func resolvePersonalTerms(at idx: Int, player: Player, userClubId: UUID) {
        var offer = pendingTransferOffers[idx]
        guard let buyerIdx = clubs.firstIndex(where: { $0.id == userClubId }) else {
            offer.status = .rejected
            pendingTransferOffers[idx] = offer
            return
        }
        let buyer = clubs[buyerIdx]
        let sellerIdx = clubs.firstIndex(where: { $0.id == offer.fromClubId })
        let demand = wageDemand(for: player, buyer: buyer, seller: sellerIdx.map { clubs[$0] })

        if let offered = offer.offeredWage, offered >= demand {
            offer.status = .completed
            completeSigning(player: player, buyerIdx: buyerIdx, sellerIdx: sellerIdx, fee: offer.fee, wage: offered, years: offer.contractYears ?? 3)
            completeOfferMessage(offer, player: player)
            pendingTransferOffers[idx] = offer
            return
        }

        // Player wants more — allow one counter, then accept or walk away.
        if offer.negotiationRound < 1 {
            offer.demandedWage = demand
            offer.negotiationRound += 1
            offer.status = .personalTerms
            offer.weeksUntilResponse = 1
            pendingTransferOffers[idx] = offer
            addNews(
                headline: "\(player.fullName)'s Agent Responds",
                body: "\(player.fullName) is holding out for \(Player.formatCurrency(demand))/w. He is currently being offered \(Player.formatCurrency(offer.offeredWage ?? 0))/w. Meet the demand or withdraw.",
                category: .transfer,
                sender: "Agent of \(player.fullName)",
                transferOfferId: offer.id
            )
        } else {
            offer.status = .withdrawn
            pendingTransferOffers[idx] = offer
            addNews(
                headline: "\(player.fullName) Talks Collapse",
                body: "\(player.fullName) rejected your personal terms and the deal is off.",
                category: .transfer,
                sender: "Director of Football"
            )
        }
    }

    /// Records a completed signing in the inbox (user-facing).
    private func completeOfferMessage(_ offer: TransferOffer, player: Player) {
        guard let buyer = club(withId: offer.toClubId) else { return }
        addNews(
            headline: "\(player.fullName) Signs for \(buyer.name)!",
            body: "The deal is done — \(player.fullName) joins \(buyer.name) for \(Player.formatCurrency(offer.fee)).",
            category: .transfer,
            sender: "Director of Football"
        )
    }

    /// Removes resolved and ignored offers that have gone stale.
    private func pruneResolvedOffers() {
        pendingTransferOffers.removeAll { offer in
            if offer.isLive { return false }
            // Keep finished offers visible for a few weeks, then forget them.
            return offer.weeksUntilResponse <= -3
        }
        // Tick down the display timer for dead offers.
        for idx in pendingTransferOffers.indices where !pendingTransferOffers[idx].isLive {
            pendingTransferOffers[idx].weeksUntilResponse -= 1
        }
    }

    // MARK: - User Actions on Offers

    /// The user accepts a counter-offer from a selling club, continuing the deal.
    public func acceptCounter(offerId: UUID) {
        guard let idx = pendingTransferOffers.firstIndex(where: { $0.id == offerId }) else { return }
        var offer = pendingTransferOffers[idx]
        guard let counter = offer.counterFee else { return }
        offer.fee = counter
        offer.status = .pending
        offer.weeksUntilResponse = 1
        pendingTransferOffers[idx] = offer
        markOfferMailRead(offerId: offerId)

        addNews(
            headline: "You Accept the Counter for \(playerName(for: offer.playerId))",
            body: "You have met the asking price of \(Player.formatCurrency(counter)). The clubs will now discuss personal terms.",
            category: .transfer,
            sender: "Director of Football"
        )
    }

    /// The user walks away from an offer.
    public func withdrawOffer(offerId: UUID) {
        guard let idx = pendingTransferOffers.firstIndex(where: { $0.id == offerId }) else { return }
        pendingTransferOffers[idx].status = .withdrawn
        pendingTransferOffers[idx].weeksUntilResponse = 0
        markOfferMailRead(offerId: offerId)
        addNews(
            headline: "Offer Withdrawn",
            body: "You have withdrawn your bid for \(playerName(for: pendingTransferOffers[idx].playerId)).",
            category: .transfer,
            sender: "Director of Football"
        )
    }

    /// The user raises their bid on an outgoing offer (renegotiation from the inbox).
    public func bumpOffer(offerId: UUID, newFee: Int, newWage: Int? = nil) {
        guard let idx = pendingTransferOffers.firstIndex(where: { $0.id == offerId }) else { return }
        var offer = pendingTransferOffers[idx]
        offer.fee = newFee
        if let w = newWage { offer.offeredWage = w }
        offer.status = .pending
        offer.weeksUntilResponse = 1
        pendingTransferOffers[idx] = offer
        markOfferMailRead(offerId: offerId)

        addNews(
            headline: "Revised Bid Submitted",
            body: "You have raised your bid for \(playerName(for: offer.playerId)) to \(Player.formatCurrency(newFee)).",
            category: .transfer,
            sender: "Director of Football"
        )
    }

    /// The user accepts an AI club's incoming bid for one of their players.
    public func acceptIncomingOffer(offerId: UUID) {
        guard let idx = pendingTransferOffers.firstIndex(where: { $0.id == offerId }) else { return }
        var offer = pendingTransferOffers[idx]
        guard offer.isIncoming,
              let (player, _) = player(withId: offer.playerId),
              let sellerIdx = clubs.firstIndex(where: { $0.id == userClubId }),
              let buyerIdx = clubs.firstIndex(where: { $0.id == offer.toClubId }) else { return }

        completeSigning(player: player, buyerIdx: buyerIdx, sellerIdx: sellerIdx, fee: offer.fee, wage: offer.offeredWage ?? player.wage, years: offer.contractYears ?? 3)
        offer.status = .completed
        offer.weeksUntilResponse = 0
        pendingTransferOffers[idx] = offer
        markOfferMailRead(offerId: offerId)
    }

    /// The user rejects an AI club's incoming bid.
    public func rejectIncomingOffer(offerId: UUID) {
        guard let idx = pendingTransferOffers.firstIndex(where: { $0.id == offerId }) else { return }
        var offer = pendingTransferOffers[idx]
        guard offer.isIncoming else { return }
        offer.status = .rejected
        offer.weeksUntilResponse = 0
        pendingTransferOffers[idx] = offer
        markOfferMailRead(offerId: offerId)

        addNews(
            headline: "Bid for \(playerName(for: offer.playerId)) Rejected",
            body: "You have turned down \(club(withId: offer.toClubId)?.name ?? "the club")'s \(Player.formatCurrency(offer.fee)) offer.",
            category: .transfer,
            sender: "Director of Football"
        )
    }

    /// Marks any inbox message linked to an offer as read.
    private func markOfferMailRead(offerId: UUID) {
        for idx in news.indices where news[idx].transferOfferId == offerId {
            news[idx].isRead = true
        }
    }

    /// Returns the live offers the user still needs to act on.
    public var actionableOffers: [TransferOffer] {
        pendingTransferOffers.filter { $0.isLive }
    }

    private func playerName(for id: UUID) -> String {
        player(withId: id)?.player.fullName ?? "the player"
    }

    // MARK: - AI Bidding for User Players

    /// AI clubs occasionally bid for members of the user's squad, generating an
    /// actionable inbox message the user must accept or reject.
    public func processAIIncomingBids() {
        guard let userIdx = clubs.firstIndex(where: { $0.isUserClub }) else { return }
        let userClub = clubs[userIdx]
        guard userClub.players.count > 18 else { return }

        // Only a handful of realistic bids per week.
        guard Double.random(in: 0...1) < 0.6 else { return }

        // Find an AI club that can afford a squad player and wants them.
        let candidates = clubs.enumerated().filter { !$0.element.isUserClub }
        guard let (_, bidder) = candidates.randomElement() else { return }

        // Target a non-star player the user might be willing to sell.
        let sellable = userClub.players
            .filter { $0.overall < 88 && $0.contract?.yearsRemaining ?? 0 <= 2 }
            .sorted { $0.value < $1.value }
        guard let target = sellable.first ?? userClub.players.min(by: { $0.overall < $1.overall }) else { return }

        let bid = Int(Double(target.value) * Double.random(in: 1.0...1.6))
        guard bid <= bidder.finances.transferBudget else { return }

        // Avoid duplicate live bids for the same player.
        guard !pendingTransferOffers.contains(where: { $0.playerId == target.id && $0.isLive }) else { return }

        let wage = max(target.wage, Int(Double(bid) / 250))
        var offer = TransferOffer(
            playerId: target.id,
            fromClubId: userClub.id,
            toClubId: bidder.id,
            fee: bid,
            status: .pending,
            offeredWage: wage,
            contractYears: 3,
            askingPrice: bid,
            isIncoming: true,
            createdDate: season.currentDate,
            weeksUntilResponse: 0
        )
        offer.isIncoming = true
        pendingTransferOffers.append(offer)

        addNews(
            headline: "\(bidder.name) Bid for \(target.fullName)",
            body: "\(bidder.name) have offered \(Player.formatCurrency(bid)) for \(target.fullName). Accept the offer, reject it, or negotiate.",
            category: .transfer,
            sender: bidder.name,
            transferOfferId: offer.id
        )
    }

    
    /// Executes the movement of a player between clubs (or free agency) and records it.
    private func completeSigning(
        player: Player,
        buyerIdx: Int,
        sellerIdx: Int?,
        fee: Int,
        wage: Int,
        years: Int
    ) {
        var signed = player
        signed.contract = Contract(wage: wage, yearsRemaining: years, signingDate: season.currentDate)
        
        var fromClubName = "Free Agent"
        var fromClubId = UUID()
        
        if let sellerIdx = sellerIdx {
            fromClubName = clubs[sellerIdx].name
            fromClubId = clubs[sellerIdx].id
            _ = clubs[sellerIdx].removePlayer(withId: player.id)
            // Seller receives the fee, minus any agreed sell-on owed to the player's
            // former club (approximated by a share of the fee when a sell-on exists).
            var sellerProceeds = fee
            if let sellOn = player.contract?.sellOnPercentage, sellOn > 0 {
                let owed = Int(Double(fee) * sellOn)
                sellerProceeds = max(0, fee - owed)
                if let originIdx = clubs.firstIndex(where: { $0.id == fromClubId }), originIdx != sellerIdx {
                    clubs[originIdx].finances.transferBudget += owed
                }
            }
            clubs[sellerIdx].finances.transferBudget += sellerProceeds
        } else {
            freeAgents.removeAll { $0.id == player.id }
        }
        
        clubs[buyerIdx].finances.transferBudget -= fee
        clubs[buyerIdx].addPlayer(signed)
        clubs[buyerIdx].finances.currentWageBill = clubs[buyerIdx].totalWeeklyWageBill
        
        transferHistory.append(
            TransferRecord(
                playerId: signed.id,
                playerName: signed.fullName,
                fromClubId: fromClubId,
                fromClubName: fromClubName,
                toClubId: clubs[buyerIdx].id,
                toClubName: clubs[buyerIdx].name,
                fee: fee,
                date: season.currentDate
            )
        )
    }
    
    // MARK: - Free Agent Bootstrapping
    
    /// Populates every club with an initial youth academy cohort. Idempotent:
    /// clubs that already have prospects are skipped.
    public func seedAcademies() {
        for cIdx in 0..<clubs.count where clubs[cIdx].academyProspects.isEmpty {
            let intake = max(2, min(5, clubs[cIdx].youthAcademyLevel + 1))
            let prospects = DataLoader.generateAcademyProspects(count: intake, club: clubs[cIdx])
            clubs[cIdx].academyProspects = prospects
        }
    }
    
    /// Populates the free-agent market with a pool of unattached players so the
    /// user (and AI clubs) always have signings available from day one.
    public func seedFreeAgents(count: Int = 40) {
        guard freeAgents.count < 8 else { return }
        
        let firstNames = ["Jack", "Liam", "Marcus", "Tom", "Sam", "Ollie", "Callum", "Reuben",
                          "Tyrese", "Kwame", "Diego", "Bruno", "Yuki", "Andrei", "Mateo", "Idris",
                          "Finley", "Kai", "Noah", "Ethan", "Leo", "Rafael", "Adam", "Isaac"]
        let lastNames = ["Bennett", "Okafor", "Silva", "Mensah", "Vargas", "Novak", "Petrov",
                         "Haddad", "Bauer", "Rossi", "Tanaka", "Adebayo", "Clarke", "Murphy",
                         "Fernandes", "Kovac", "Larsson", "Diallo", "Moretti", "Suzuki"]
        let nationalities = ["England", "Scotland", "Wales", "Ireland", "France", "Spain",
                             "Portugal", "Germany", "Italy", "Brazil", "Nigeria", "Ghana",
                             "Netherlands", "Belgium", "Denmark", "Sweden", "Japan", "USA"]
        
        for _ in 0..<count {
            let position = Position.allCases.randomElement() ?? .CM
            let tierRoll = Int.random(in: 0...100)
            let overall: Int
            if tierRoll < 10 { overall = Int.random(in: 68...76) }
            else if tierRoll < 40 { overall = Int.random(in: 58...67) }
            else { overall = Int.random(in: 46...57) }
            
            let age = Int.random(in: 18...35)
            let potential = min(99, overall + (age <= 23 ? Int.random(in: 3...12) : Int.random(in: 0...3)))
            let attrs = DataLoader.generateAttributes(overall: overall, position: position)
            
            let player = Player(
                firstName: firstNames.randomElement() ?? "Alex",
                lastName: lastNames.randomElement() ?? "Smith",
                nationality: nationalities.randomElement() ?? "England",
                age: age,
                height: Int.random(in: 172...192),
                weight: Int.random(in: 66...88),
                preferredFoot: [Foot.right, Foot.right, Foot.left, Foot.both].randomElement() ?? .right,
                positions: [position],
                attributes: attrs,
                overall: overall,
                potential: potential
            )
            freeAgents.append(player)
        }
    }
    
    // MARK: - AI Manager Transfer Engine
    
    public func processAITransfers() {
        // AI clubs look to fill vacancies or offload surplus players
        for clubIdx in 0..<clubs.count {
            if clubs[clubIdx].isUserClub { continue }
            
            // AI buys from free agency if squad depth is under 20
            if clubs[clubIdx].players.count < 20 && !freeAgents.isEmpty {
                let candidateIdx = Int.random(in: 0..<freeAgents.count)
                var signedPlayer = freeAgents.remove(at: candidateIdx)
                let weeklyWage = max(500, signedPlayer.overall * 35)
                signedPlayer.contract = Contract(wage: weeklyWage, yearsRemaining: 2, signingDate: season.currentDate)
                clubs[clubIdx].addPlayer(signedPlayer)
                
                transferHistory.append(
                    TransferRecord(
                        playerId: signedPlayer.id,
                        playerName: signedPlayer.fullName,
                        fromClubId: UUID(),
                        fromClubName: "Free Agent",
                        toClubId: clubs[clubIdx].id,
                        toClubName: clubs[clubIdx].name,
                        fee: 0,
                        date: season.currentDate
                    )
                )
            }
        }

        // Occasional AI-to-AI transfers between clubs, keeping the league fluid.
        guard Double.random(in: 0...1) < 0.35 else { return }
        let clubIndices = clubs.indices.filter { !clubs[$0].isUserClub && clubs[$0].players.count > 18 }
        guard clubIndices.count >= 2 else { return }
        guard let buyerIdx = clubIndices.randomElement() else { return }
        let buyer = clubs[buyerIdx]
        let sellers = clubIndices.filter { $0 != buyerIdx && clubs[$0].players.count > 20 }
        guard let sellerIdx = sellers.randomElement() else { return }

        // Target an affordable player from the seller's squad.
        let affordable = clubs[sellerIdx].players.filter {
            $0.value > 0 && $0.value <= buyer.finances.transferBudget
        }
        guard let target = affordable.randomElement(),
              let playerIdx = clubs[sellerIdx].players.firstIndex(where: { $0.id == target.id }) else { return }

        let fee = Int(Double(target.value) * Double.random(in: 1.0...1.4))
        guard fee <= buyer.finances.transferBudget else { return }

        let wage = max(target.wage, Int(Double(fee) / 260))
        _ = playerIdx
        completeSigning(
            player: target,
            buyerIdx: buyerIdx,
            sellerIdx: sellerIdx,
            fee: fee,
            wage: wage,
            years: 3
        )
    }
    
    // MARK: - Club Creation Helper
    
    public func createCustomClub(
        name: String,
        shortName: String,
        stadium: String,
        stadiumCapacity: Int = 5000,
        city: String,
        primaryColor: String,
        secondaryColor: String,
        replaceClubId: UUID
    ) -> Club? {
        guard let replacedIdx = clubs.firstIndex(where: { $0.id == replaceClubId }) else {
            return nil
        }
        
        let replacedClub = clubs[replacedIdx]
        
        // Free up players of replaced club into free agents pool
        for player in replacedClub.players {
            freeAgents.append(player)
        }
        
        let userClub = Club(
            name: name,
            shortName: shortName.uppercased(),
            stadium: stadium,
            stadiumCapacity: stadiumCapacity,
            city: city,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            leagueTier: replacedClub.leagueTier,
            reputation: 45,
            isUserClub: true,
            players: [],
            manager: gameMode == .createClub ? "Interim Manager" : manager.fullName
        )
        
        // Substitute in clubs array
        clubs[replacedIdx] = userClub
        self.userClubId = userClub.id
        
        // Update League clubIds
        if let leagueIdx = leagues.firstIndex(where: { $0.tier == replacedClub.leagueTier }) {
            if let idIdx = leagues[leagueIdx].clubIds.firstIndex(of: replaceClubId) {
                leagues[leagueIdx].clubIds[idIdx] = userClub.id
            }
        }
        
        // Update fixtures containing replaced club
        for fIdx in 0..<season.fixtures.count {
            if season.fixtures[fIdx].homeClubId == replaceClubId {
                season.fixtures[fIdx].homeClubId = userClub.id
            }
            if season.fixtures[fIdx].awayClubId == replaceClubId {
                season.fixtures[fIdx].awayClubId = userClub.id
            }
        }
        
        addNews(
            headline: "\(userClub.name) Enters \(userClub.leagueTier.displayName)!",
            body: gameMode == .createClub
                ? "\(owner.name) has founded \(userClub.name). Your first decision is who will lead the football department."
                : "\(userClub.name) has officially taken over at \(userClub.stadium).",
            category: .board,
            sender: "The Board — \(userClub.name)"
        )
        if gameMode != .createClub { seedManagerInbox() }
        
        return userClub
    }

    /// An owner advances the club's week as an observer. Fixtures are fully
    /// simulated; the owner then reacts through appointments and investment.
    public func advanceOwnerWeek() {
        guard gameMode == .createClub, userClub != nil else { return }
        advanceWeek()
        owner.legacyPoints += 1
        try? SaveManager.shared.autoSave(gameState: self)
    }

    /// Allows owners to shape resources and public sentiment without selecting
    /// the team or changing match tactics.
    @discardableResult
    public func approveOwnerInvestment(_ investment: OwnerInvestment) -> Bool {
        guard gameMode == .createClub,
              owner.legacyPoints >= investment.cost,
              let index = clubs.firstIndex(where: { $0.isUserClub }) else { return false }

        owner.legacyPoints -= investment.cost
        switch investment {
        case .recruitment:
            clubs[index].finances.transferBudget += 650_000
            owner.supporterConfidence = min(100, owner.supporterConfidence + 1)
        case .facilities:
            clubs[index].finances.balance += 450_000
            owner.supporterConfidence = min(100, owner.supporterConfidence + 2)
        case .community:
            owner.supporterConfidence = min(100, owner.supporterConfidence + 6)
            clubs[index].reputation = min(100, clubs[index].reputation + 1)
        }
        addNews(
            headline: "Board Approves \(investment.title)",
            body: investment.detail,
            category: .board,
            sender: "Owner's Office"
        )
        try? SaveManager.shared.autoSave(gameState: self)
        return true
    }

    /// Runs one intentional training session per matchweek. Dedicated sessions
    /// trade one form of readiness for another, so preparation remains a choice.
    @discardableResult
    public func runTrainingSession(_ focus: TrainingFocus) -> Bool {
        guard gameMode != .createClub,
              lastTrainingWeek != season.currentWeek,
              let clubIndex = clubs.firstIndex(where: { $0.isUserClub }) else { return false }

        for playerIndex in clubs[clubIndex].players.indices where clubs[clubIndex].players[playerIndex].injury == nil {
            switch focus {
            case .balanced:
                clubs[clubIndex].players[playerIndex].recoverFitness(amount: 3)
                clubs[clubIndex].players[playerIndex].sharpness = min(100, clubs[clubIndex].players[playerIndex].sharpness + 3)
            case .fitness:
                clubs[clubIndex].players[playerIndex].recoverFitness(amount: 7)
                clubs[clubIndex].players[playerIndex].sharpness = min(100, clubs[clubIndex].players[playerIndex].sharpness + 1)
            case .sharpness:
                clubs[clubIndex].players[playerIndex].consumeFitness(amount: 2)
                clubs[clubIndex].players[playerIndex].sharpness = min(100, clubs[clubIndex].players[playerIndex].sharpness + 7)
            case .morale:
                clubs[clubIndex].players[playerIndex].boostMorale()
                clubs[clubIndex].players[playerIndex].recoverFitness(amount: 1)
            }
        }
        lastTrainingWeek = season.currentWeek
        addNews(
            headline: "\(focus.title) Session Complete",
            body: "The first team completed a focused \(focus.title.lowercased()) session ahead of the next fixture.",
            category: .board,
            sender: "Coaching Staff"
        )
        try? SaveManager.shared.autoSave(gameState: self)
        return true
    }

    /// Sets a matchweek team talk. It is intentionally a small, temporary edge:
    /// preparation and player quality still decide the match.
    @discardableResult
    public func chooseTeamTalk(_ style: TeamTalkStyle) -> Bool {
        guard gameMode != .createClub, userClub != nil else { return false }
        teamTalk = style
        teamTalkAppliedWeek = nil
        addNews(headline: "Team Talk Set: \(style.rawValue)", body: style.effectSummary, category: .board, sender: "Manager's Office")
        return true
    }

    /// Applies the selected talk once, immediately before the user fixture is simulated.
    public func applyTeamTalkIfNeeded() {
        guard let style = teamTalk,
              teamTalkAppliedWeek != season.currentWeek,
              let clubIndex = clubs.firstIndex(where: { $0.isUserClub }) else { return }
        for playerIndex in clubs[clubIndex].players.indices where clubs[clubIndex].players[playerIndex].injury == nil {
            switch style {
            case .calm, .rally, .protect:
                clubs[clubIndex].players[playerIndex].boostMorale()
            case .firedUp:
                clubs[clubIndex].players[playerIndex].boostMorale()
                clubs[clubIndex].players[playerIndex].sharpness = min(100, clubs[clubIndex].players[playerIndex].sharpness + 2)
            case .demand:
                clubs[clubIndex].players[playerIndex].sharpness = min(100, clubs[clubIndex].players[playerIndex].sharpness + 4)
                if clubs[clubIndex].players[playerIndex].morale == .furious { clubs[clubIndex].players[playerIndex].dampenMorale() }
            }
        }
        teamTalkAppliedWeek = season.currentWeek
    }

    private func updateBoardConfidence(after result: MatchResult, userWasHome: Bool) {
        let goalsFor = userWasHome ? result.homeGoals : result.awayGoals
        let goalsAgainst = userWasHome ? result.awayGoals : result.homeGoals
        let won = goalsFor > goalsAgainst
        let drawn = goalsFor == goalsAgainst
        if won {
            jobSecurity.gamesWithoutWin = 0
            jobSecurity.underperformingWeeks = max(0, jobSecurity.underperformingWeeks - 1)
            jobSecurity.boardConfidence = min(100, jobSecurity.boardConfidence + (goalsFor - goalsAgainst >= 3 ? 6 : 3))
        } else {
            jobSecurity.gamesWithoutWin += 1
            if !drawn { jobSecurity.underperformingWeeks += 1 }
            let drop = drawn ? 1 : min(8, 3 + jobSecurity.gamesWithoutWin / 2)
            jobSecurity.boardConfidence = max(0, jobSecurity.boardConfidence - drop)
        }
        let tone = jobSecurity.boardConfidence < 40 ? "The board need an immediate improvement." : "The board remain focused on the season objective."
        addNews(headline: "Board Confidence: \(jobSecurity.status)", body: "Confidence is \(jobSecurity.boardConfidence) out of 100 after the result. \(tone)", category: .board, sender: "The Board")
    }

    /// Owner-only budget split. Reallocating cash is capped by available balance,
    /// so the owner cannot manufacture funds by changing a percentage.
    @discardableResult
    public func setOwnerBudgetAllocation(transferPercent: Int) -> Bool {
        guard gameMode == .createClub, let index = clubs.firstIndex(where: { $0.isUserClub }) else { return false }
        let transfer = max(0, min(100, transferPercent))
        owner.budgetAllocation = BudgetAllocation(transferBudgetPercent: transfer, wageBudgetPercent: 100 - transfer)
        let flexibleCash = max(0, clubs[index].finances.balance / 4)
        clubs[index].finances.transferBudget = max(clubs[index].finances.transferBudget, flexibleCash * transfer / 100)
        clubs[index].finances.wageBudget = max(clubs[index].finances.wageBudget, flexibleCash * (100 - transfer) / 100)
        return true
    }

    /// Signs one sensible commercial partner per owner career. The annual value
    /// scales with club reputation and is credited to sponsorship income.
    @discardableResult
    public func signSponsorshipDeal(_ tier: SponsorshipTier) -> Bool {
        guard gameMode == .createClub,
              owner.sponsorshipDeals.count < 3,
              let index = clubs.firstIndex(where: { $0.isUserClub }) else { return false }
        let reputationFactor = 0.55 + Double(clubs[index].reputation) / 200.0
        let annualValue = Int(Double(tier.baseIncome) * reputationFactor)
        let names = ["Northstar", "Civic", "Vertex", "Harbour", "Summit"]
        let deal = SponsorshipDeal(sponsorName: "\(names[owner.sponsorshipDeals.count]) \(tier.rawValue)", tier: tier, annualValue: annualValue, performanceBonus: annualValue / 10)
        owner.sponsorshipDeals.append(deal)
        clubs[index].finances.sponsorshipIncome += annualValue
        addNews(headline: "New Commercial Partner", body: "\(deal.sponsorName) has agreed a \(Player.formatCurrency(annualValue)) per year deal, plus performance bonuses.", category: .board, sender: "Commercial Director")
        return true
    }

    public func appointManager(_ candidate: ManagerCandidate) -> Bool {
        guard gameMode == .createClub,
              let index = clubs.firstIndex(where: { $0.isUserClub }),
              clubs[index].finances.balance >= candidate.compensation else { return false }
        clubs[index].finances.balance -= candidate.compensation
        clubs[index].finances.wageBudget = max(clubs[index].finances.wageBudget, candidate.wage + 2_000)
        clubs[index].manager = candidate.name
        owner.supporterConfidence = min(100, owner.supporterConfidence + 5)
        addNews(headline: "\(candidate.name) Appointed Manager", body: "The board have appointed \(candidate.name). Their stated approach: \(candidate.style).", category: .board, sender: "Owner's Office")
        return true
    }

    public func dismissManager() -> Bool {
        guard gameMode == .createClub,
              let index = clubs.firstIndex(where: { $0.isUserClub }),
              clubs[index].manager != "Interim Manager" else { return false }
        let outgoing = clubs[index].manager
        let settlement = max(250_000, clubs[index].finances.wageBudget * 8)
        guard clubs[index].finances.balance >= settlement else { return false }
        clubs[index].finances.balance -= settlement
        clubs[index].manager = "Interim Manager"
        owner.supporterConfidence = max(0, owner.supporterConfidence - 4)
        addNews(headline: "\(outgoing) Leaves \(clubs[index].name)", body: "The manager has been relieved of duties. A compensation payment of \(Player.formatCurrency(settlement)) has been made; appoint a successor promptly.", category: .board, sender: "Owner's Office")
        return true
    }
    
    // MARK: - Existing Club Take-Over Helper
    
    /// Assigns an existing club as the user's club (Manage Existing Club mode),
    /// ensuring a valid starting XI and flagging it as the user-controlled side.
    @discardableResult
    public func takeOverExistingClub(clubId: UUID) -> Club? {
        guard let idx = clubs.firstIndex(where: { $0.id == clubId }) else { return nil }
        
        for otherIdx in 0..<clubs.count {
            clubs[otherIdx].isUserClub = (otherIdx == idx)
        }
        clubs[idx].ensureTacticalIntegrity()
        clubs[idx].manager = manager.fullName
        self.userClubId = clubId
        seedAcademies()
        
        addNews(
            headline: "You Are Now the Manager of \(clubs[idx].name)!",
            body: "The board at \(clubs[idx].name) have appointed you as first-team manager at \(clubs[idx].stadium). Transfer budget: \(Player.formatCurrency(clubs[idx].finances.transferBudget)).",
            category: .board,
            sender: "The Board — \(clubs[idx].name)"
        )
        seedManagerInbox()
        if !freeAgents.isEmpty {
            addNews(
                headline: "\(freeAgents.count) Free Agents Available",
                body: "Our scouts have identified \(freeAgents.count) unattached players. Several could improve the squad at no transfer cost.",
                category: .transfer,
                sender: "Chief Scout"
            )
        }
        return clubs[idx]
    }
    
    // MARK: - Club Mutation Helpers

    /// Replaces a club in world state with an updated copy, matched by id.
    public func updateClub(_ updated: Club) {
        guard let idx = clubs.firstIndex(where: { $0.id == updated.id }) else { return }
        clubs[idx] = updated
    }

    /// Swaps a bench player into the starting XI (and the outgoing starter to the bench).
    /// Used by the squad screen's tap-to-select substitution flow.
    public func swapIntoStartingXI(playerId: UUID, replacing starterId: UUID) {
        guard let idx = clubs.firstIndex(where: { $0.isUserClub }) else { return }
        var club = clubs[idx]

        guard let starterIdx = club.tactics.startingXI.firstIndex(of: starterId),
              let benchIdx = club.tactics.substitutes.firstIndex(of: playerId) else {
            return
        }

        club.tactics.startingXI[starterIdx] = playerId
        club.tactics.substitutes[benchIdx] = starterId

        clubs[idx] = club
    }

    // MARK: - Season Transition

    public func startNewSeason() {
        let years = season.year.components(separatedBy: "-")
        let startYearInt: Int
        let endYearInt: Int
        if years.count == 2, let y1 = Int(years[0]), let y2 = Int(years[1]) {
            startYearInt = y1 + 1
            endYearInt = y2 + 1
        } else {
            startYearInt = 2027
            endYearInt = 2028
        }
        let nextYear = "\(startYearInt)-\(String(format: "%02d", endYearInt % 100))"
        
        // Derive fixture start date and preseason date dynamically from the new season year.
        let seasonStartDate = String(format: "%d-08-09", startYearInt)
        let preseasonDate = String(format: "%d-08-01", startYearInt)
        
        // Regenerate fixtures for all leagues
        var allNewFixtures: [Fixture] = []
        for league in leagues {
            let generated = FixtureGenerator.generateDoubleRoundRobin(
                clubIds: league.clubIds,
                competitionName: league.name,
                startDateString: seasonStartDate
            )
            allNewFixtures.append(contentsOf: generated)
        }
        
        self.season = Season(
            year: nextYear,
            currentWeek: 1,
            currentPhase: .preseason,
            fixtures: allNewFixtures,
            currentDate: preseasonDate
        )

        // Rebuild the European competitions for the new season.
        europeanCompetitions = EuropeanCompetitionBuilder.build(from: clubs)
        europeanMatchweek = 0
        
        // Reset player seasonal match statistics
        for cIdx in 0..<clubs.count {
            clubs[cIdx].seasonResults = []
            for pIdx in 0..<clubs[cIdx].players.count {
                clubs[cIdx].players[pIdx].seasonStats = SeasonStats()
                clubs[cIdx].players[pIdx].yellowCards = 0
                clubs[cIdx].players[pIdx].suspendedMatches = 0
                // Decrement contract duration
                if var contract = clubs[cIdx].players[pIdx].contract {
                    contract.yearsRemaining -= 1
                    clubs[cIdx].players[pIdx].contract = contract
                }
            }
        }
        
        // Youth academy: age and develop existing prospects, then perform a new
        // intake whose size scales with the club's academy level.
        for cIdx in 0..<clubs.count {
            var club = clubs[cIdx]

            // Age existing prospects; develop them toward their potential.
            for pIdx in club.academyProspects.indices {
                club.academyProspects[pIdx].age += 1
                let ceiling = club.academyProspects[pIdx].potential
                if club.academyProspects[pIdx].overall < ceiling {
                    let growth = Int.random(in: 1...max(1, (ceiling - club.academyProspects[pIdx].overall)))
                    club.academyProspects[pIdx].overall = min(ceiling, club.academyProspects[pIdx].overall + growth)
                }
            }

            // Annual intake: 2-4 new prospects, more for better academies.
            let intake = max(2, min(5, club.youthAcademyLevel + 1))
            let newProspects = DataLoader.generateAcademyProspects(count: intake, club: club)
            for prospect in newProspects {
                club.addProspect(prospect)
            }
            // Keep the academy from ballooning.
            if club.academyProspects.count > 10 {
                club.academyProspects.sort { $0.potential > $1.potential }
                club.academyProspects = Array(club.academyProspects.prefix(10))
            }
            clubs[cIdx] = club
        }

        if let userClub = userClub {
            let standout = userClub.academyProspects.max { $0.potential < $1.potential }
            if let standout = standout, standout.potential >= 75 {
                addNews(
                    headline: "Academy Starlet Emerges",
                    body: "Your academy staff are excited about \(standout.fullName) (\(standout.primaryPosition.displayName), age \(standout.age)) — potential rated \(standout.potential). Consider promoting them to the senior squad.",
                    category: .board,
                    sender: "Head of Youth Development"
                )
            } else {
                addNews(
                    headline: "Youth Intake Complete",
                    body: "The academy has welcomed a new crop of prospects this summer. Review them in the Youth Academy screen.",
                    category: .board,
                    sender: "Head of Youth Development"
                )
            }
        }

        addNews(
            headline: "Welcome to Season \(nextYear)!",
            body: "The new league season is officially underway. Training camps are open.",
            category: .general
        )
    }
    
    public func processEndOfSeason() {
        season.currentPhase = .endOfSeason
        
        // Determine final tables per tier before any movement occurs.
        var finalTables: [LeagueTier: [LeagueStanding]] = [:]
        for league in leagues {
            finalTables[league.tier] = standings(for: league)
        }
        
        // Accumulate the club movements to apply after computing all tables.
        var promotions: [LeagueTier: [UUID]] = [:]
        var relegations: [LeagueTier: [UUID]] = [:]
        var playOffPromotions: [LeagueTier: [UUID]] = [:]
        
        for tier in LeagueTier.allCases {
            guard let table = finalTables[tier] else { continue }
            let n = table.count
            guard n > 0 else { continue }
            
            // Relegation from the bottom of the table.
            let relegationCount = min(tier.relegationCount, n)
            if relegationCount > 0 {
                let relegated = table.suffix(relegationCount).map { $0.clubId }
                relegations[tier] = relegated
            }
            
            // Automatic promotion from the top of the table (never a top flight).
            if !tier.isTopFlight {
                let autoCount = min(tier.autoPromotionCount, n)
                if autoCount > 0 {
                    promotions[tier] = table.prefix(autoCount).map { $0.clubId }
                }
                
                // Playoff promotion decided among the clubs immediately below the auto slots.
                if tier.playoffPromotionCount > 0 {
                    let lower = autoCount
                    let upper = min(autoCount + 4, n)
                    if lower < upper {
                        let playOffClubs = Array(table[lower..<upper])
                        let winner = simulatePlayOffFinal(for: tier, contenders: playOffClubs)
                        playOffPromotions[tier] = [winner.clubId]
                        addNews(
                            headline: "\(clubName(for: winner.clubId)) Win the \(tier.displayName) Play-Off Final!",
                            body: "\(clubName(for: winner.clubId)) have secured promotion via the play-offs.",
                            category: .promotion
                        )
                    }
                }
            }
        }
        
        // Map each promoted club to the destination tier and each relegated club downward.
        // Only move between tiers that actually exist this season (countries whose lower
        // divisions are not yet populated must not send clubs into a phantom league).
        let existingTiers = Set(leagues.map { $0.tier })

        func destinationTierForPromotion(from tier: LeagueTier) -> LeagueTier? {
            guard let dest = tier.higherTier, existingTiers.contains(dest) else { return nil }
            return dest
        }
        
        func destinationTierForRelegation(from tier: LeagueTier) -> LeagueTier? {
            guard let dest = tier.lowerTier, existingTiers.contains(dest) else { return nil }
            return dest
        }
        
        // Apply promotions.
        for (fromTier, clubIds) in promotions {
            guard let toTier = destinationTierForPromotion(from: fromTier) else { continue }
            for clubId in clubIds {
                moveClub(clubId, to: toTier)
                addNews(
                    headline: "\(clubName(for: clubId)) Promoted to the \(toTier.displayName)!",
                    body: "\(clubName(for: clubId)) finish in the automatic promotion places and go up.",
                    category: .promotion
                )
            }
        }
        
        for (fromTier, clubIds) in playOffPromotions {
            guard let toTier = destinationTierForPromotion(from: fromTier) else { continue }
            for clubId in clubIds {
                moveClub(clubId, to: toTier)
            }
        }
        
        // Apply relegations.
        for (fromTier, clubIds) in relegations {
            guard let toTier = destinationTierForRelegation(from: fromTier) else { continue }
            for clubId in clubIds {
                moveClub(clubId, to: toTier)
                addNews(
                    headline: "\(clubName(for: clubId)) Relegated to the \(toTier.displayName)",
                    body: "\(clubName(for: clubId)) drop down to the \(toTier.displayName) for next season.",
                    category: .relegation
                )
            }
        }
        
        // Crown each tier champion.
        for tier in LeagueTier.allCases {
            guard let table = finalTables[tier], let champion = table.first else { continue }
            addNews(
                headline: "\(clubName(for: champion.clubId)) Crowned \(tier.displayName) Champions!",
                body: "\(clubName(for: champion.clubId)) finish top of the table with \(champion.points) points.",
                category: .award
            )
        }
        
        // Snapshot the user's season into their managerial career history.
        if let userClub = userClub, let table = finalTables[userClub.leagueTier],
           let pos = table.firstIndex(where: { $0.clubId == userClub.id }) {
            let standing = table[pos]
            var honours: [String] = []
            if pos == 0 { honours.append("\(userClub.leagueTier.displayName) Champions") }
            recordManagerSeason(
                club: userClub,
                position: pos + 1,
                played: standing.played,
                won: standing.won,
                drawn: standing.drawn,
                lost: standing.lost,
                honours: honours
            )
        }
        
        addNews(
            headline: "Season \(season.year) Concludes!",
            body: "The final standings have been locked. Congratulations to all champions and promoted clubs. Tap 'Start New Season' on the Home screen to begin the next campaign.",
            category: .award
        )
    }
    
    // MARK: - Season End Helpers
    
    /// Returns a club's display name, falling back to a placeholder when unknown.
    public func clubName(for id: UUID) -> String {
        return clubs.first { $0.id == id }?.name ?? "Unknown Club"
    }
    
    /// Moves a club into a new tier, updating both the club record and the league membership lists.
    public func moveClub(_ clubId: UUID, to newTier: LeagueTier) {
        guard let clubIdx = clubs.firstIndex(where: { $0.id == clubId }) else { return }
        let oldTier = clubs[clubIdx].leagueTier
        guard oldTier != newTier else { return }
        
        clubs[clubIdx].leagueTier = newTier
        
        // Adjust finances baseline for the new division's economics, preserving balance/history.
        let newFinances = ClubFinances.defaultFor(tier: newTier)
        clubs[clubIdx].finances.transferBudget = newFinances.transferBudget
        clubs[clubIdx].finances.wageBudget = newFinances.wageBudget
        clubs[clubIdx].finances.tvIncome = newFinances.tvIncome
        clubs[clubIdx].finances.matchdayIncome = newFinances.matchdayIncome
        clubs[clubIdx].finances.sponsorshipIncome = newFinances.sponsorshipIncome
        clubs[clubIdx].finances.merchandiseIncome = newFinances.merchandiseIncome
        
        // Remove from the old league's membership.
        if let oldLeagueIdx = leagues.firstIndex(where: { $0.tier == oldTier }) {
            leagues[oldLeagueIdx].clubIds.removeAll { $0 == clubId }
        }
        // Add to the new league's membership.
        if let newLeagueIdx = leagues.firstIndex(where: { $0.tier == newTier }) {
            if !leagues[newLeagueIdx].clubIds.contains(clubId) {
                leagues[newLeagueIdx].clubIds.append(clubId)
            }
        }
    }
    
    /// Resolves a four-team play-off by seeded single-elimination, favouring the club
    /// that finished higher in the league table while still allowing upsets.
    private func simulatePlayOffFinal(for tier: LeagueTier, contenders: [LeagueStanding]) -> LeagueStanding {
        guard !contenders.isEmpty else {
            return LeagueStanding(clubId: UUID())
        }
        guard contenders.count > 1 else { return contenders[0] }
        
        // Seeded bracket: 1st vs 4th, 2nd vs 3rd, with the higher seed hosting.
        var bracket = contenders
        while bracket.count > 1 {
            var nextRound: [LeagueStanding] = []
            var i = 0
            while i < bracket.count {
                if i + 1 < bracket.count {
                    nextRound.append(playOffWinner(bracket[i], bracket[i + 1]))
                } else {
                    nextRound.append(bracket[i])
                }
                i += 2
            }
            bracket = nextRound
        }
        return bracket[0]
    }
    
    /// Favours the higher-placed club but allows an upset based on relative points.
    private func playOffWinner(_ higher: LeagueStanding, _ lower: LeagueStanding) -> LeagueStanding {
        let pointGap = Double(higher.points - lower.points)
        // Base probability the better side advances, scaled by the points gap.
        let higherChance = max(0.35, min(0.80, 0.55 + pointGap / 100.0))
        return Double.random(in: 0...1) < higherChance ? higher : lower
    }
    
    // MARK: - Managerial Career & Job Offers

    /// Clears any club association, leaving the user unemployed but with a
    /// manager profile intact.
    public func goUnemployed() {
        userClubId = nil
        for idx in 0..<clubs.count {
            clubs[idx].isUserClub = false
        }
    }

    /// Builds a pool of realistic job offers for the user based on their current
    /// reputation. Vacancies skew toward clubs whose reputation is within reach
    /// of the manager's own standing; unemployed users see more low-reputation
    /// openings, successful managers attract bigger clubs.
    public func generateJobOffers(maxCount: Int = 4, excludeUserClub: Bool = true) {
        guard clubs.count > 2 else { return }

        let userRep = manager.reputation
        let userClubIdLocal = userClubId

        let candidates = clubs.filter { club in
            if excludeUserClub, let uid = userClubIdLocal, club.id == uid { return false }
            // Only clubs at or below the manager's reach (allow some stretch upward).
            return club.reputation <= userRep + 15
        }

        // Weight selection toward the best-fitting roles without randomising the
        // whole world every week — offers are generated on demand (job screen / news).
        let sorted = candidates.sorted { $0.reputation > $1.reputation }
        var newOffers: [JobOffer] = []
        for club in sorted.prefix(max(maxCount * 3, maxCount)) {
            let league = leagues.first { $0.tier == club.leagueTier }
            let wage = max(1_000, club.finances.wageBudget / 40)
            newOffers.append(
                JobOffer(
                    clubId: club.id,
                    kind: .club,
                    teamName: club.name,
                    leagueName: league?.name ?? club.leagueTier.displayName,
                    reputation: club.reputation,
                    offeredWage: wage,
                    seasonYear: season.year
                )
            )
        }

        // Shuffle a little so the ordering isn't strictly by reputation.
        newOffers.shuffle()
        let chosen = Array(newOffers.prefix(maxCount))

        // De-duplicate against offers we already hold.
        let existingClubIds = Set(jobOffers.compactMap { $0.clubId })
        let fresh = chosen.filter { offer in
            guard let cid = offer.clubId else { return true }
            return !existingClubIds.contains(cid)
        }
        jobOffers.append(contentsOf: fresh)

        for offer in fresh {
            addNews(
                headline: "\(offer.teamName) Approach You",
                body: "\(offer.teamName) of the \(offer.leagueName) would like you to become their next manager. Visit Job Offers to respond.",
                category: .board,
                sender: "\(offer.teamName) Board"
            )
        }
    }

    /// Accepts a job offer, moving the user to that club. Any current club is
    /// vacated first. Returns the new club on success.
    @discardableResult
    public func acceptJobOffer(_ offer: JobOffer) -> Club? {
        guard let clubId = offer.clubId,
              let idx = clubs.firstIndex(where: { $0.id == clubId }) else {
            // National-team offers are handled by a later stage; just drop them.
            jobOffers.removeAll { $0.id == offer.id }
            return nil
        }

        for otherIdx in 0..<clubs.count {
            clubs[otherIdx].isUserClub = (otherIdx == idx)
        }
        clubs[idx].ensureTacticalIntegrity()
        userClubId = clubId
        jobOffers.removeAll()

        // Reputation is nudged toward the new role's standing.
        manager.reputation = min(100, max(manager.reputation, min(offer.reputation, manager.reputation + 10)))
        clubs[idx].manager = manager.fullName

        addNews(
            headline: "You Are Now the Manager of \(clubs[idx].name)!",
            body: "\(clubs[idx].name) have appointed \(manager.fullName) as first-team manager.",
            category: .board,
            sender: "The Board — \(clubs[idx].name)"
        )
        seedManagerInbox()
        return clubs[idx]
    }

    /// Declines a single job offer.
    public func declineJobOffer(_ offer: JobOffer) {
        jobOffers.removeAll { $0.id == offer.id }
    }

    /// Declines every outstanding offer.
    public func declineAllJobOffers() {
        jobOffers.removeAll()
    }

    /// Appends a completed season to the manager's career history and lightly
    /// adjusts reputation based on final position and the division's strength.
    public func recordManagerSeason(
        club: Club,
        position: Int,
        played: Int,
        won: Int,
        drawn: Int,
        lost: Int,
        honours: [String] = []
    ) {
        let league = leagues.first { $0.tier == club.leagueTier }
        let record = ManagerSeasonRecord(
            seasonYear: season.year,
            clubName: club.name,
            leagueName: league?.name ?? club.leagueTier.displayName,
            played: played,
            won: won,
            drawn: drawn,
            lost: lost,
            finalPosition: position,
            honours: honours
        )
        manager.careerHistory.append(record)

        // Reputation drifts toward a target based on league strength and finish.
        let tierBonus: Int
        switch club.leagueTier.level {
        case 1: tierBonus = club.leagueTier.country == .england ? 25 : 20
        case 2: tierBonus = 15
        case 3: tierBonus = 8
        default: tierBonus = 3
        }
        let positionPenalty = min(20, max(0, position - 1) * 2)
        let target = min(100, max(5, club.reputation / 2 + tierBonus - positionPenalty))
        manager.reputation = (manager.reputation * 2 + target) / 3
        manager.age += 1
    }

    public func addNews(headline: String, body: String, category: NewsCategory, sender: String = "Club News Desk", transferOfferId: UUID? = nil) {
        let item = NewsItem(
            headline: headline,
            body: body,
            date: season.currentDate,
            category: category,
            sender: sender,
            transferOfferId: transferOfferId
        )
        news.insert(item, at: 0)
    }

    /// Number of unread manager messages.
    public var unreadMailCount: Int {
        news.reduce(0) { $0 + ($1.isRead ? 0 : 1) }
    }

    /// Marks every message in the inbox as read.
    public func markAllMailRead() {
        for idx in news.indices where !news[idx].isRead {
            news[idx].isRead = true
        }
    }

    /// Marks a single message as read.
    public func markMailRead(id: UUID) {
        guard let idx = news.firstIndex(where: { $0.id == id }) else { return }
        news[idx].isRead = true
    }

    /// Seeds the manager's inbox with the board's welcome and season objectives the
    /// first time a club is taken over.
    public func seedManagerInbox() {
        guard let club = userClub else { return }
        let boardTone = club.reputation >= 70 ? "a club of our standing"
            : club.reputation >= 45 ? "an ambitious club"
            : "a club with real potential"
        addNews(
            headline: "Welcome to \(club.name)",
            body: "The board is delighted to appoint you as first-team manager. We see \(boardTone) and believe you are the right person to lead it. The squad is yours — good luck.",
            category: .board,
            sender: "The Board — \(club.name)"
        )
        addNews(
            headline: "Season Objectives",
            body: "Our minimum expectation this season is a \(boardExpectation(for: club)). Exceed it and the board will back you in the transfer market and reward you with a new contract.",
            category: .board,
            sender: "The Board — \(club.name)"
        )
        addNews(
            headline: "Transfer Window Open",
            body: "You have until the end of the window to strengthen the squad. Your available budget and wage headroom are shown in the Transfer Hub.",
            category: .transfer,
            sender: "Club Secretary"
        )
    }

    /// Board's minimum season expectation derived from the club's tier and reputation.
    private func boardExpectation(for club: Club) -> String {
        if club.leagueTier.isTopFlight {
            if club.reputation >= 75 { return "title challenge" }
            if club.reputation >= 55 { return "top-half finish and a European push" }
            return "comfortable mid-table safety"
        }
        if club.reputation >= 55 { return "promotion challenge" }
        if club.reputation >= 40 { return "top-half finish" }
        return "battle against relegation"
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case gameMode
        case clubs
        case leagues
        case season
        case userClubId
        case freeAgents
        case transferHistory
        case pendingTransferOffers
        case news
        case currentScreen
        case isMatchInProgress
        case activeMatchFixtureId
        case negotiationTargetPlayerId
        case soundEnabled
        case matchSettings
        case manager
        case jobOffers
        case owner
        case lastTrainingWeek
        case jobSecurity
        case teamTalk
        case teamTalkAppliedWeek
        case europeanCompetitions
        case europeanMatchweek
        case nationalTeams
        case internationalTournaments
        case managedNationalTeamId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gameMode, forKey: .gameMode)
        try container.encode(clubs, forKey: .clubs)
        try container.encode(leagues, forKey: .leagues)
        try container.encode(season, forKey: .season)
        try container.encodeIfPresent(userClubId, forKey: .userClubId)
        try container.encode(freeAgents, forKey: .freeAgents)
        try container.encode(transferHistory, forKey: .transferHistory)
        try container.encode(pendingTransferOffers, forKey: .pendingTransferOffers)
        try container.encode(news, forKey: .news)
        try container.encode(currentScreen, forKey: .currentScreen)
        try container.encode(isMatchInProgress, forKey: .isMatchInProgress)
        try container.encodeIfPresent(activeMatchFixtureId, forKey: .activeMatchFixtureId)
        try container.encodeIfPresent(negotiationTargetPlayerId, forKey: .negotiationTargetPlayerId)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(matchSettings, forKey: .matchSettings)
        try container.encode(manager, forKey: .manager)
        try container.encode(jobOffers, forKey: .jobOffers)
        try container.encode(owner, forKey: .owner)
        try container.encodeIfPresent(lastTrainingWeek, forKey: .lastTrainingWeek)
        try container.encode(jobSecurity, forKey: .jobSecurity)
        try container.encodeIfPresent(teamTalk, forKey: .teamTalk)
        try container.encodeIfPresent(teamTalkAppliedWeek, forKey: .teamTalkAppliedWeek)
        try container.encode(europeanCompetitions, forKey: .europeanCompetitions)
        try container.encode(europeanMatchweek, forKey: .europeanMatchweek)
        try container.encode(nationalTeams, forKey: .nationalTeams)
        try container.encode(internationalTournaments, forKey: .internationalTournaments)
        try container.encodeIfPresent(managedNationalTeamId, forKey: .managedNationalTeamId)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.gameMode = try container.decode(GameMode.self, forKey: .gameMode)
        self.clubs = try container.decode([Club].self, forKey: .clubs)
        self.leagues = try container.decode([League].self, forKey: .leagues)
        self.season = try container.decode(Season.self, forKey: .season)
        self.userClubId = try container.decodeIfPresent(UUID.self, forKey: .userClubId)
        self.freeAgents = try container.decode([Player].self, forKey: .freeAgents)
        self.transferHistory = try container.decode([TransferRecord].self, forKey: .transferHistory)
        self.pendingTransferOffers = try container.decode([TransferOffer].self, forKey: .pendingTransferOffers)
        self.news = try container.decode([NewsItem].self, forKey: .news)
        self.currentScreen = try container.decode(AppScreen.self, forKey: .currentScreen)
        self.isMatchInProgress = try container.decode(Bool.self, forKey: .isMatchInProgress)
        self.activeMatchFixtureId = try container.decodeIfPresent(UUID.self, forKey: .activeMatchFixtureId)
        self.negotiationTargetPlayerId = try container.decodeIfPresent(UUID.self, forKey: .negotiationTargetPlayerId)
        self.soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        self.matchSettings = try container.decodeIfPresent(MatchSettings.self, forKey: .matchSettings) ?? MatchSettings()
        self.manager = try container.decodeIfPresent(ManagerProfile.self, forKey: .manager) ?? ManagerProfile()
        self.jobOffers = try container.decodeIfPresent([JobOffer].self, forKey: .jobOffers) ?? []
        self.owner = try container.decodeIfPresent(OwnerProfile.self, forKey: .owner) ?? OwnerProfile()
        self.lastTrainingWeek = try container.decodeIfPresent(Int.self, forKey: .lastTrainingWeek)
        self.jobSecurity = try container.decodeIfPresent(JobSecurity.self, forKey: .jobSecurity) ?? JobSecurity()
        self.teamTalk = try container.decodeIfPresent(TeamTalkStyle.self, forKey: .teamTalk)
        self.teamTalkAppliedWeek = try container.decodeIfPresent(Int.self, forKey: .teamTalkAppliedWeek)
        self.europeanCompetitions = try container.decodeIfPresent([EuropeanCompetitionState].self, forKey: .europeanCompetitions) ?? []
        self.europeanMatchweek = try container.decodeIfPresent(Int.self, forKey: .europeanMatchweek) ?? 0
        self.nationalTeams = try container.decodeIfPresent([NationalTeam].self, forKey: .nationalTeams) ?? []
        self.internationalTournaments = try container.decodeIfPresent([InternationalTournament.State].self, forKey: .internationalTournaments) ?? []
        self.managedNationalTeamId = try container.decodeIfPresent(String.self, forKey: .managedNationalTeamId)
    }
}
