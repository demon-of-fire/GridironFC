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
    
    public init(
        id: UUID = UUID(),
        headline: String,
        body: String,
        date: String,
        category: NewsCategory
    ) {
        self.id = id
        self.headline = headline
        self.body = body
        self.date = date
        self.category = category
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
    public var userPlayerId: UUID?
    
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
    
    // Managerial Career
    public var manager: ManagerProfile
    public var jobOffers: [JobOffer]
    
    // MARK: - Initializer
    
    public init(
        gameMode: GameMode = .createClub,
        clubs: [Club] = [],
        leagues: [League] = [],
        season: Season = Season(),
        userClubId: UUID? = nil,
        userPlayerId: UUID? = nil,
        freeAgents: [Player] = [],
        transferHistory: [TransferRecord] = [],
        pendingTransferOffers: [TransferOffer] = [],
        news: [NewsItem] = [],
        currentScreen: AppScreen = .mainMenu,
        isMatchInProgress: Bool = false,
        activeMatchFixtureId: UUID? = nil,
        negotiationTargetPlayerId: UUID? = nil,
        soundEnabled: Bool = true,
        manager: ManagerProfile = ManagerProfile(),
        jobOffers: [JobOffer] = []
    ) {
        self.gameMode = gameMode
        self.clubs = clubs
        self.leagues = leagues
        self.season = season
        self.userClubId = userClubId
        self.userPlayerId = userPlayerId
        self.freeAgents = freeAgents
        self.transferHistory = transferHistory
        self.pendingTransferOffers = pendingTransferOffers
        self.news = news
        self.currentScreen = currentScreen
        self.isMatchInProgress = isMatchInProgress
        self.activeMatchFixtureId = activeMatchFixtureId
        self.negotiationTargetPlayerId = negotiationTargetPlayerId
        self.soundEnabled = soundEnabled
        self.manager = manager
        self.jobOffers = jobOffers
    }
    
    // MARK: - Computed Properties
    
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
    public func finishMatchweekAfterUserMatch() {
        advanceWeek()
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
            // Weekly financial accounting
            let isHomeMatch = season.fixtures(forWeek: season.currentWeek).contains { $0.homeClubId == clubs[clubIdx].id }
            clubs[clubIdx].finances.processWeeklyCashFlow(isHomeMatchThisWeek: isHomeMatch)
        }
        
        // 3. AI manager autonomous dealings
        processAITransfers()
        
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
        
        // 6. Check if season has completed
        if season.isSeasonFinished && season.currentPhase != .endOfSeason {
            processEndOfSeason()
        }
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
    }
    
    // MARK: - User Transfer Bidding
    
    /// Submits a transfer bid from the user's club for a player at another club,
    /// or signs a free agent. Resolves the offer immediately against the selling
    /// club's valuation and the user's budget, returning the resulting offer record.
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
        
        let askingPrice = player.value
        var offer = TransferOffer(
            playerId: playerId,
            fromClubId: sellerIdx.map { clubs[$0].id } ?? UUID(),
            toClubId: userClubId,
            fee: fee,
            isLoan: false,
            status: .pending,
            offeredWage: offeredWage,
            contractYears: contractYears
        )
        
        // Budget check: transfer fee plus first-year wage commitment must fit.
        let buyer = clubs[buyerIdx]
        let canAffordFee = isFreeAgent || fee <= buyer.finances.transferBudget
        let wageHeadroom = buyer.finances.wageBudget - buyer.finances.currentWageBill
        // A signing is permitted as long as the new wage is covered by existing headroom,
        // or does not blow more than ~20% past the current wage structure. This avoids the
        // situation where a club sitting exactly at its wage ceiling can never sign anyone.
        let wageCeiling = max(wageHeadroom, 0) + Int(Double(max(buyer.finances.wageBudget, 1)) * 0.20) + 2_000
        let canAffordWage = offeredWage <= wageCeiling || offeredWage <= max(wageHeadroom, 0) + 8_000
        
        // Selling club decision: accept when the bid meets or beats their valuation,
        // with a graded tolerance for near-misses.
        let valuation = Double(askingPrice)
        let acceptableFee: Bool
        if isFreeAgent {
            acceptableFee = true
        } else if Double(fee) >= valuation {
            acceptableFee = true
        } else if Double(fee) >= valuation * 0.9 {
            acceptableFee = true
        } else if Double(fee) >= valuation * 0.75 {
            acceptableFee = Double.random(in: 0...1) < 0.4
        } else {
            acceptableFee = false
        }
        
        if !canAffordFee || !canAffordWage || !acceptableFee {
            offer.status = .rejected
            pendingTransferOffers.append(offer)
            addNews(
                headline: "Bid for \(player.fullName) Rejected",
                body: !canAffordFee
                    ? "The transfer fee exceeded \(buyer.name)'s budget."
                    : (!canAffordWage
                        ? "The offered wage exceeded \(buyer.name)'s wage structure."
                        : "\(sellerIdx.map { clubs[$0].name } ?? "The club") rejected the bid for \(player.fullName)."),
                category: .transfer
            )
            return offer
        }
        
        completeSigning(player: player, buyerIdx: buyerIdx, sellerIdx: sellerIdx, fee: isFreeAgent ? 0 : fee, wage: offeredWage, years: contractYears)
        offer.status = .completed
        pendingTransferOffers.append(offer)
        return offer
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
            clubs[sellerIdx].finances.transferBudget += fee
        } else {
            freeAgents.removeAll { $0.id == player.id }
        }
        
        clubs[buyerIdx].finances.transferBudget -= fee
        clubs[buyerIdx].addPlayer(signed)
        
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
        
        addNews(
            headline: "\(signed.fullName) Signs for \(clubs[buyerIdx].name)!",
            body: "\(clubs[buyerIdx].name) have completed the \(fee == 0 ? "free transfer" : "£" + String(fee)) signing of \(signed.fullName) from \(fromClubName).",
            category: .transfer
        )
    }
    
    // MARK: - Free Agent Bootstrapping
    
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
    ) -> Club {
        guard let replacedIdx = clubs.firstIndex(where: { $0.id == replaceClubId }) else {
            fatalError("Target club to replace was not found in world state.")
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
            manager: manager.fullName
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
            body: "\(userClub.name) has officially taken over at \(userClub.stadium).",
            category: .general
        )
        
        return userClub
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
        
        addNews(
            headline: "You Are Now the Manager of \(clubs[idx].name)!",
            body: "The board at \(clubs[idx].name) have appointed you as first-team manager at \(clubs[idx].stadium).",
            category: .general
        )
        addNews(
            headline: "Board Objectives for \(season.year)",
            body: "The board expect \(clubs[idx].name) to be competitive in the \(clubs[idx].leagueTier.displayName). Transfer budget: \(Player.formatCurrency(clubs[idx].finances.transferBudget)).",
            category: .general
        )
        addNews(
            headline: "Transfer Window Open",
            body: "The transfer window is now open. Head to the Transfers tab and use Search & Sign Players to strengthen your squad.",
            category: .transfer
        )
        if !freeAgents.isEmpty {
            addNews(
                headline: "\(freeAgents.count) Free Agents Available",
                body: "Our scouts have identified \(freeAgents.count) unattached players. Several could improve the squad at no transfer cost.",
                category: .transfer
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
            
            // Automatic promotion from the top of the table (never the top flight).
            if tier != .premierLeague {
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
        func destinationTierForPromotion(from tier: LeagueTier) -> LeagueTier? {
            switch tier {
            case .premierLeague: return nil
            case .championship: return .premierLeague
            case .leagueOne: return .championship
            case .leagueTwo: return .leagueOne
            }
        }
        
        func destinationTierForRelegation(from tier: LeagueTier) -> LeagueTier? {
            switch tier {
            case .premierLeague: return .championship
            case .championship: return .leagueOne
            case .leagueOne: return .leagueTwo
            case .leagueTwo: return nil // Bottom tier: no relegation out of the playable world.
            }
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
        for club in sorted.prefix(max(count: maxCount * 3, count: maxCount)) {
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
                category: .general
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
            category: .general
        )
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
        switch club.leagueTier {
        case .premierLeague: tierBonus = 25
        case .championship: tierBonus = 15
        case .leagueOne: tierBonus = 8
        case .leagueTwo: tierBonus = 3
        }
        let positionPenalty = min(20, max(0, position - 1) * 2)
        let target = min(100, max(5, club.reputation / 2 + tierBonus - positionPenalty))
        manager.reputation = (manager.reputation * 2 + target) / 3
        manager.age += 1
    }

    public func addNews(headline: String, body: String, category: NewsCategory) {        let item = NewsItem(
            headline: headline,
            body: body,
            date: season.currentDate,
            category: category
        )
        news.insert(item, at: 0)
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case gameMode
        case clubs
        case leagues
        case season
        case userClubId
        case userPlayerId
        case freeAgents
        case transferHistory
        case pendingTransferOffers
        case news
        case currentScreen
        case isMatchInProgress
        case activeMatchFixtureId
        case negotiationTargetPlayerId
        case soundEnabled
        case manager
        case jobOffers
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gameMode, forKey: .gameMode)
        try container.encode(clubs, forKey: .clubs)
        try container.encode(leagues, forKey: .leagues)
        try container.encode(season, forKey: .season)
        try container.encodeIfPresent(userClubId, forKey: .userClubId)
        try container.encodeIfPresent(userPlayerId, forKey: .userPlayerId)
        try container.encode(freeAgents, forKey: .freeAgents)
        try container.encode(transferHistory, forKey: .transferHistory)
        try container.encode(pendingTransferOffers, forKey: .pendingTransferOffers)
        try container.encode(news, forKey: .news)
        try container.encode(currentScreen, forKey: .currentScreen)
        try container.encode(isMatchInProgress, forKey: .isMatchInProgress)
        try container.encodeIfPresent(activeMatchFixtureId, forKey: .activeMatchFixtureId)
        try container.encodeIfPresent(negotiationTargetPlayerId, forKey: .negotiationTargetPlayerId)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(manager, forKey: .manager)
        try container.encode(jobOffers, forKey: .jobOffers)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.gameMode = try container.decode(GameMode.self, forKey: .gameMode)
        self.clubs = try container.decode([Club].self, forKey: .clubs)
        self.leagues = try container.decode([League].self, forKey: .leagues)
        self.season = try container.decode(Season.self, forKey: .season)
        self.userClubId = try container.decodeIfPresent(UUID.self, forKey: .userClubId)
        self.userPlayerId = try container.decodeIfPresent(UUID.self, forKey: .userPlayerId)
        self.freeAgents = try container.decode([Player].self, forKey: .freeAgents)
        self.transferHistory = try container.decode([TransferRecord].self, forKey: .transferHistory)
        self.pendingTransferOffers = try container.decode([TransferOffer].self, forKey: .pendingTransferOffers)
        self.news = try container.decode([NewsItem].self, forKey: .news)
        self.currentScreen = try container.decode(AppScreen.self, forKey: .currentScreen)
        self.isMatchInProgress = try container.decode(Bool.self, forKey: .isMatchInProgress)
        self.activeMatchFixtureId = try container.decodeIfPresent(UUID.self, forKey: .activeMatchFixtureId)
        self.negotiationTargetPlayerId = try container.decodeIfPresent(UUID.self, forKey: .negotiationTargetPlayerId)
        self.soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        self.manager = try container.decodeIfPresent(ManagerProfile.self, forKey: .manager) ?? ManagerProfile()
        self.jobOffers = try container.decodeIfPresent([JobOffer].self, forKey: .jobOffers) ?? []
    }
}
