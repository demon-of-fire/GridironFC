//
//  MatchEngine.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Core match simulation engine simulating minute-by-minute action, tactical duels,
//  set pieces, fatigue progression, substitutions, extra time, and penalty shootouts.
//

import Foundation

public struct MatchEngine {
    
    // MARK: - Match Configuration
    
    public struct SimulationConfig {
        public var neutralVenue: Bool
        public var matchWeek: Int
        public var competition: String
        public var date: String
        public var isKnockout: Bool
        
        public init(
            neutralVenue: Bool = false,
            matchWeek: Int = 1,
            competition: String = "League Match",
            date: String = "2024-09-01",
            isKnockout: Bool = false
        ) {
            self.neutralVenue = neutralVenue
            self.matchWeek = matchWeek
            self.competition = competition
            self.date = date
            self.isKnockout = isKnockout
        }
    }
    
    // MARK: - In-Match Active Player State
    
    private struct ActiveMatchPlayer {
        var player: Player
        var currentFatigue: Double = 0.0 // 0 to 100% fatigue during the game
        var currentRating: Double = 6.0
        var goals: Int = 0
        var assists: Int = 0
        var yellowCards: Int = 0
        var isSentOff: Bool = false
        var isSubstitutedOut: Bool = false
        var minutesPlayed: Int = 0
        
        /// Dynamic effective performance level accounting for base attributes, form, morale, and in-game fatigue.
        func effectiveSkill(for roleCategory: PositionCategory) -> Double {
            guard !isSentOff else { return 0.0 }
            
            // Base skill
            var skill = Double(player.overall)
            
            // Form modifier (±10%)
            let avgForm = player.averageForm // 1.0 - 10.0 scale, average ~6.5
            let formModifier = 1.0 + ((avgForm - 6.5) * 0.02)
            skill *= min(1.10, max(0.90, formModifier))
            
            // Morale modifier (±10%)
            skill *= player.morale.performanceMultiplier
            
            // In-match fatigue penalty (up to -25% when completely exhausted)
            let fatiguePenalty = (currentFatigue / 100.0) * 0.25
            skill *= (1.0 - fatiguePenalty)
            
            return skill
        }
    }
    
    // MARK: - Public API
    
    /// Standard convenience signature conforming to specification.
    public static func simulateMatch(
        home: Club,
        away: Club,
        neutralVenue: Bool = false
    ) -> MatchResult {
        var mutableHome = home
        var mutableAway = away
        let config = SimulationConfig(
            neutralVenue: neutralVenue,
            matchWeek: 1,
            competition: "League Match",
            date: "2024-09-01",
            isKnockout: false
        )
        return simulate(homeClub: &mutableHome, awayClub: &mutableAway, config: config)
    }
    
    /// Full match simulation returning updated club rosters (with fatigue, cards, injuries applied) and MatchResult.
    public static func simulateFullMatch(
        home: inout Club,
        away: inout Club,
        config: SimulationConfig
    ) -> MatchResult {
        return simulate(homeClub: &home, awayClub: &away, config: config)
    }
    
    // MARK: - Core Simulation Loop
    
    private static func simulate(
        homeClub: inout Club,
        awayClub: inout Club,
        config: SimulationConfig
    ) -> MatchResult {
        homeClub.ensureTacticalIntegrity()
        awayClub.ensureTacticalIntegrity()
        
        // 1. Prepare active rosters
        var homeActive = homeClub.startingXIPlayers.map { ActiveMatchPlayer(player: $0) }
        var awayActive = awayClub.startingXIPlayers.map { ActiveMatchPlayer(player: $0) }
        var homeBench = homeClub.substitutePlayers
        var awayBench = awayClub.substitutePlayers
        
        var homeSubsUsed = 0
        var awaySubsUsed = 0
        let maxSubs = 5
        
        var homeGoals = 0
        var awayGoals = 0
        var events: [MatchEvent] = []
        
        var homeShots = 0
        var awayShots = 0
        var homeShotsOnTarget = 0
        var awayShotsOnTarget = 0
        var homeCorners = 0
        var awayCorners = 0
        var homeFouls = 0
        var awayFouls = 0
        var homeXG = 0.0
        var awayXG = 0.0
        var homeSaves = 0
        var awaySaves = 0
        var homePossessionSeconds = 0.0
        var awayPossessionSeconds = 0.0
        
        // Kickoff event
        events.append(
            MatchEvent(
                minute: 1,
                type: .kickOff,
                shortText: "Kick-off! \(homeClub.name) vs \(awayClub.name) is underway.",
                detailText: "The referee blows the whistle and the match begins at \(homeClub.stadium).",
                isHomeTeam: true
            )
        )
        
        // Calculate injury times
        let firstHalfStoppage = Int.random(in: 1...4)
        let secondHalfStoppage = Int.random(in: 2...6)
        
        // Determine total minutes (90 + stoppage, or 120 if knockout & draw)
        var maxMinute = 90 + secondHalfStoppage
        
        // Minute-by-minute simulation
        var minute = 1
        while minute <= maxMinute {
            
            // Half-time whistle
            if minute == 45 {
                let ht = Commentary.halfTimeSummary(
                    home: homeClub,
                    away: awayClub,
                    homeGoals: homeGoals,
                    awayGoals: awayGoals
                )
                events.append(
                    MatchEvent(
                        minute: 45,
                        type: .halfTime,
                        shortText: ht.short,
                        detailText: ht.detail,
                        isHomeTeam: true
                    )
                )
            }
            
            // Atmospheric commentary check (~every 15-20 mins)
            if minute == 15 || minute == 32 || minute == 62 || minute == 80 {
                let atmos = Commentary.atmosphere(
                    homeClub: homeClub,
                    awayClub: awayClub,
                    minute: minute,
                    homeGoals: homeGoals,
                    awayGoals: awayGoals
                )
                events.append(
                    MatchEvent(
                        minute: minute,
                        type: .commentary,
                        shortText: atmos.short,
                        detailText: atmos.detail,
                        isHomeTeam: true
                    )
                )
            }
            
            // 2. Increment minutes & fatigue
            updateFatigue(activePlayers: &homeActive, tactics: homeClub.tactics)
            updateFatigue(activePlayers: &awayActive, tactics: awayClub.tactics)
            
            // 3. AI / Tactical Substitutions (Between 58' and 82')
            if minute >= 58 && minute <= 82 {
                tryPerformSubstitution(
                    activePlayers: &homeActive,
                    bench: &homeBench,
                    subsUsed: &homeSubsUsed,
                    maxSubs: maxSubs,
                    club: homeClub,
                    isHome: true,
                    minute: minute,
                    events: &events
                )
                tryPerformSubstitution(
                    activePlayers: &awayActive,
                    bench: &awayBench,
                    subsUsed: &awaySubsUsed,
                    maxSubs: maxSubs,
                    club: awayClub,
                    isHome: false,
                    minute: minute,
                    events: &events
                )
            }
            
            // 4. Calculate relative team strengths for this minute
            let homeStrength = calculateTeamStrength(
                activePlayers: homeActive,
                tactics: homeClub.tactics,
                isHome: true,
                neutralVenue: config.neutralVenue
            )
            let awayStrength = calculateTeamStrength(
                activePlayers: awayActive,
                tactics: awayClub.tactics,
                isHome: false,
                neutralVenue: config.neutralVenue
            )
            
            // Possession allocation for this minute
            let totalStrength = max(1.0, homeStrength + awayStrength)
            let homePossessionChance = homeStrength / totalStrength
            let isHomeInPossession = Double.random(in: 0...1) < homePossessionChance
            if isHomeInPossession {
                homePossessionSeconds += 60.0
            } else {
                awayPossessionSeconds += 60.0
            }
            
            // 5. Roll for minute events (Tempo influences event frequency)
            let attackingTactics = isHomeInPossession ? homeClub.tactics : awayClub.tactics
            let tempoChanceModifier: Double
            switch attackingTactics.tempo {
            case .fast: tempoChanceModifier = 1.25
            case .normal: tempoChanceModifier = 1.00
            case .slow: tempoChanceModifier = 0.80
            }
            
            let eventRoll = Double.random(in: 0...100)
            
            if eventRoll < (16.5 * tempoChanceModifier) {
                // Open play chance
                resolveChance(
                    isHomeAttacking: isHomeInPossession,
                    homeActive: &homeActive,
                    awayActive: &awayActive,
                    homeClub: homeClub,
                    awayClub: awayClub,
                    homeGoals: &homeGoals,
                    awayGoals: &awayGoals,
                    homeShots: &homeShots,
                    awayShots: &awayShots,
                    homeShotsOnTarget: &homeShotsOnTarget,
                    awayShotsOnTarget: &awayShotsOnTarget,
                    homeSaves: &homeSaves,
                    awaySaves: &awaySaves,
                    homeXG: &homeXG,
                    awayXG: &awayXG,
                    minute: minute,
                    events: &events
                )
            } else if eventRoll < (21.0 * tempoChanceModifier) {
                // Corner Kick
                resolveCorner(
                    isHomeAttacking: isHomeInPossession,
                    homeActive: &homeActive,
                    awayActive: &awayActive,
                    homeClub: homeClub,
                    awayClub: awayClub,
                    homeGoals: &homeGoals,
                    awayGoals: &awayGoals,
                    homeCorners: &homeCorners,
                    awayCorners: &awayCorners,
                    homeShots: &homeShots,
                    awayShots: &awayShots,
                    homeShotsOnTarget: &homeShotsOnTarget,
                    awayShotsOnTarget: &awayShotsOnTarget,
                    homeXG: &homeXG,
                    awayXG: &awayXG,
                    minute: minute,
                    events: &events
                )
            } else if eventRoll < (23.5 * tempoChanceModifier) {
                // Dangerous Free Kick
                resolveFreeKick(
                    isHomeAttacking: isHomeInPossession,
                    homeActive: &homeActive,
                    awayActive: &awayActive,
                    homeClub: homeClub,
                    awayClub: awayClub,
                    homeGoals: &homeGoals,
                    awayGoals: &awayGoals,
                    homeShots: &homeShots,
                    awayShots: &awayShots,
                    homeShotsOnTarget: &homeShotsOnTarget,
                    awayShotsOnTarget: &awayShotsOnTarget,
                    homeXG: &homeXG,
                    awayXG: &awayXG,
                    minute: minute,
                    events: &events
                )
            } else if eventRoll < 28.0 {
                // Foul and Disciplinary check
                resolveFoul(
                    isHomeTeamFouling: !isHomeInPossession,
                    homeActive: &homeActive,
                    awayActive: &awayActive,
                    homeClub: homeClub,
                    awayClub: awayClub,
                    homeFouls: &homeFouls,
                    awayFouls: &awayFouls,
                    homeGoals: &homeGoals,
                    awayGoals: &awayGoals,
                    minute: minute,
                    events: &events
                )
            } else if eventRoll < 29.5 {
                // In-match injury roll
                checkInMatchInjury(
                    homeActive: &homeActive,
                    awayActive: &awayActive,
                    homeClub: homeClub,
                    awayClub: awayClub,
                    minute: minute,
                    events: &events
                )
            }
            
            // Check if knockout match reached full time tied -> Trigger Extra Time (91-120)
            if minute == (90 + secondHalfStoppage) && config.isKnockout && homeGoals == awayGoals && maxMinute < 120 {
                events.append(
                    MatchEvent(
                        minute: 90,
                        type: .extraTimeStart,
                        shortText: "⚡ EXTRA TIME! Scores tied at \(homeGoals)-\(awayGoals)",
                        detailText: "90 minutes could not separate these sides. We head into 30 minutes of extra time!",
                        isHomeTeam: true
                    )
                )
                maxMinute = 120
            }
            
            minute += 1
        }
        
        // 6. Penalty Shootout if tied after 120 minutes in knockout match
        if config.isKnockout && homeGoals == awayGoals {
            resolvePenaltyShootout(
                homeClub: homeClub,
                awayClub: awayClub,
                homeActive: homeActive,
                awayActive: awayActive,
                homeGoals: &homeGoals,
                awayGoals: &awayGoals,
                events: &events
            )
        }
        
        // 7. Full-time whistle event
        let motm = determineManOfTheMatch(homeActive: homeActive, awayActive: awayActive)
        let ftSummary = Commentary.fullTimeSummary(
            home: homeClub,
            away: awayClub,
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            motm: motm?.player
        )
        events.append(
            MatchEvent(
                minute: min(minute - 1, 90),
                type: .fullTime,
                shortText: ftSummary.short,
                detailText: ftSummary.detail,
                isHomeTeam: true
            )
        )
        
        // 8. Compile Match Statistics
        let totalSeconds = max(1.0, homePossessionSeconds + awayPossessionSeconds)
        let homePossession = ((homePossessionSeconds / totalSeconds) * 1000.0).rounded() / 10.0
        let awayPossession = ((100.0 - homePossession) * 10.0).rounded() / 10.0
        
        let homeStats = MatchStats(
            possession: homePossession,
            shots: homeShots,
            shotsOnTarget: homeShotsOnTarget,
            corners: homeCorners,
            fouls: homeFouls,
            offsides: Int.random(in: 1...4),
            passAccuracy: round(Double.random(in: 78...88) * 10) / 10,
            tacklesWon: Int.random(in: 12...22),
            saves: homeSaves,
            xG: (homeXG * 100).rounded() / 100
        )
        
        let awayStats = MatchStats(
            possession: awayPossession,
            shots: awayShots,
            shotsOnTarget: awayShotsOnTarget,
            corners: awayCorners,
            fouls: awayFouls,
            offsides: Int.random(in: 1...4),
            passAccuracy: round(Double.random(in: 76...87) * 10) / 10,
            tacklesWon: Int.random(in: 12...22),
            saves: awaySaves,
            xG: (awayXG * 100).rounded() / 100
        )
        
        // Player ratings map
        var ratingsMap: [UUID: Double] = [:]
        for ap in homeActive { ratingsMap[ap.player.id] = (ap.currentRating * 10).rounded() / 10 }
        for ap in awayActive { ratingsMap[ap.player.id] = (ap.currentRating * 10).rounded() / 10 }
        
        let attendancePct = Double.random(in: 0.78...0.98)
        let attendance = Int(Double(homeClub.stadiumCapacity) * attendancePct)
        
        let matchResult = MatchResult(
            homeClubId: homeClub.id,
            awayClubId: awayClub.id,
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            events: events,
            matchWeek: config.matchWeek,
            competition: config.competition,
            date: config.date,
            attendance: attendance,
            homeStats: homeStats,
            awayStats: awayStats,
            playerRatings: ratingsMap,
            manOfTheMatch: motm?.player.id
        )
        
        // 9. Sync results back to clubs and update players' persistent models
        applyMatchToClub(club: &homeClub, activePlayers: homeActive, opponentGoals: awayGoals, motmId: motm?.player.id)
        applyMatchToClub(club: &awayClub, activePlayers: awayActive, opponentGoals: homeGoals, motmId: motm?.player.id)
        
        homeClub.seasonResults.append(matchResult)
        awayClub.seasonResults.append(matchResult)
        
        return matchResult
    }
    
    // MARK: - Chance Resolution
    
    private static func resolveChance(
        isHomeAttacking: Bool,
        homeActive: inout [ActiveMatchPlayer],
        awayActive: inout [ActiveMatchPlayer],
        homeClub: Club,
        awayClub: Club,
        homeGoals: inout Int,
        awayGoals: inout Int,
        homeShots: inout Int,
        awayShots: inout Int,
        homeShotsOnTarget: inout Int,
        awayShotsOnTarget: inout Int,
        homeSaves: inout Int,
        awaySaves: inout Int,
        homeXG: inout Double,
        awayXG: inout Double,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        if isHomeAttacking { homeShots += 1 } else { awayShots += 1 }
        
        let attackingClub = isHomeAttacking ? homeClub : awayClub
        let defendingClub = isHomeAttacking ? awayClub : homeClub
        
        // Pick shooter and assister
        let attackingSquad = isHomeAttacking ? homeActive : awayActive
        let availableShooters = attackingSquad.filter { !$0.isSentOff }
        guard !availableShooters.isEmpty else { return }
        
        // Weight forwards and attacking midfielders higher for shots
        let weightedShooters = availableShooters.sorted { p1, p2 in
            let score1 = p1.player.attributes.shooting + (p1.player.primaryPosition.isAttacking ? 30 : 0)
            let score2 = p2.player.attributes.shooting + (p2.player.primaryPosition.isAttacking ? 30 : 0)
            return score1 > score2
        }
        let shooterIdxInAvailable = Int.random(in: 0..<min(4, weightedShooters.count))
        let shooter = weightedShooters[shooterIdxInAvailable]
        
        let assisterCandidates = availableShooters.filter { $0.player.id != shooter.player.id }
        let assister = Double.random(in: 0...1) < 0.75 ? assisterCandidates.randomElement() : nil
        
        // Calculate shot quality and xG
        let shootingSkill = Double(shooter.player.attributes.shooting)
        let composureSkill = Double(shooter.player.attributes.composure)
        let baseChanceQuality = (shootingSkill * 0.6 + composureSkill * 0.4) / 100.0
        
        let chanceXG = min(0.75, max(0.04, baseChanceQuality * Double.random(in: 0.3...0.85)))
        if isHomeAttacking { homeXG += chanceXG } else { awayXG += chanceXG }
        
        // Opposition goalkeeper
        let defendingSquad = isHomeAttacking ? awayActive : homeActive
        let gkIdx = defendingSquad.firstIndex(where: { $0.player.primaryPosition == .GK && !$0.isSentOff }) ?? 0
        let gk = defendingSquad[gkIdx]
        let gkReflexes = Double(gk.player.attributes.reflexes)
        let gkPositioning = Double(gk.player.attributes.gkPositioning)
        let gkSkill = (gkReflexes * 0.6 + gkPositioning * 0.4) / 100.0
        
        let conversionProbability = chanceXG * (1.2 - (gkSkill * 0.4))
        let roll = Double.random(in: 0...1)
        
        if roll < conversionProbability {
            // GOAL SCORED!
            if isHomeAttacking {
                homeGoals += 1
                homeShotsOnTarget += 1
            } else {
                awayGoals += 1
                awayShotsOnTarget += 1
            }
            
            // Update shooter stats & rating
            if let idx = (isHomeAttacking ? homeActive : awayActive).firstIndex(where: { $0.player.id == shooter.player.id }) {
                if isHomeAttacking {
                    homeActive[idx].goals += 1
                    homeActive[idx].currentRating = min(10.0, homeActive[idx].currentRating + 1.2)
                } else {
                    awayActive[idx].goals += 1
                    awayActive[idx].currentRating = min(10.0, awayActive[idx].currentRating + 1.2)
                }
            }
            // Update assister stats
            if let a = assister, let aIdx = (isHomeAttacking ? homeActive : awayActive).firstIndex(where: { $0.player.id == a.player.id }) {
                if isHomeAttacking {
                    homeActive[aIdx].assists += 1
                    homeActive[aIdx].currentRating = min(10.0, homeActive[aIdx].currentRating + 0.6)
                } else {
                    awayActive[aIdx].assists += 1
                    awayActive[aIdx].currentRating = min(10.0, awayActive[aIdx].currentRating + 0.6)
                }
            }
            
            let commentary = Commentary.goal(
                scorer: shooter.player,
                assister: assister?.player,
                club: attackingClub,
                opponent: defendingClub,
                minute: minute,
                homeGoals: homeGoals,
                awayGoals: awayGoals,
                isHome: isHomeAttacking
            )
            
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .goal,
                    clubId: attackingClub.id,
                    playerId: shooter.player.id,
                    assistPlayerId: assister?.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeAttacking
                )
            )
        } else if roll < conversionProbability + 0.35 {
            // Shot on target saved by Goalkeeper
            if isHomeAttacking {
                homeShotsOnTarget += 1
                awaySaves += 1
            } else {
                awayShotsOnTarget += 1
                homeSaves += 1
            }
            
            if isHomeAttacking {
                awayActive[gkIdx].currentRating = min(10.0, awayActive[gkIdx].currentRating + 0.3)
            } else {
                homeActive[gkIdx].currentRating = min(10.0, homeActive[gkIdx].currentRating + 0.3)
            }
            
            let commentary = Commentary.save(
                keeper: gk.player,
                shooter: shooter.player,
                keeperClub: defendingClub,
                minute: minute,
                isHome: !isHomeAttacking
            )
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .shotOnTarget,
                    clubId: attackingClub.id,
                    playerId: shooter.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeAttacking
                )
            )
        } else if roll < conversionProbability + 0.45 {
            // Hit woodwork
            let commentary = Commentary.miss(
                shooter: shooter.player,
                club: attackingClub,
                minute: minute,
                isWoodwork: true
            )
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .woodwork,
                    clubId: attackingClub.id,
                    playerId: shooter.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeAttacking
                )
            )
        } else {
            // Chance missed off-target
            let commentary = Commentary.miss(
                shooter: shooter.player,
                club: attackingClub,
                minute: minute,
                isWoodwork: false
            )
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .chanceMissed,
                    clubId: attackingClub.id,
                    playerId: shooter.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeAttacking
                )
            )
        }
    }
    
    // MARK: - Corner Resolution
    
    private static func resolveCorner(
        isHomeAttacking: Bool,
        homeActive: inout [ActiveMatchPlayer],
        awayActive: inout [ActiveMatchPlayer],
        homeClub: Club,
        awayClub: Club,
        homeGoals: inout Int,
        awayGoals: inout Int,
        homeCorners: inout Int,
        awayCorners: inout Int,
        homeShots: inout Int,
        awayShots: inout Int,
        homeShotsOnTarget: inout Int,
        awayShotsOnTarget: inout Int,
        homeXG: inout Double,
        awayXG: inout Double,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        if isHomeAttacking { homeCorners += 1 } else { awayCorners += 1 }
        
        let attackingClub = isHomeAttacking ? homeClub : awayClub
        let defendingClub = isHomeAttacking ? awayClub : homeClub
        let attackingSquad = isHomeAttacking ? homeActive : awayActive
        
        // Find designated or best corner taker
        let cornerTakerId = attackingClub.tactics.cornerTaker
        let taker = attackingSquad.first { $0.player.id == cornerTakerId && !$0.isSentOff } ??
            attackingSquad.max(by: { $0.player.attributes.crossing < $1.player.attributes.crossing })!
        
        // Find top aerial threat
        let aerialTargets = attackingSquad.filter { $0.player.id != taker.player.id && !$0.isSentOff }
        let headerTarget = aerialTargets.max(by: { ($0.player.attributes.heading + $0.player.attributes.jumping) < ($1.player.attributes.heading + $1.player.attributes.jumping) }) ?? taker
        
        // xG for corner
        let cornerXG = 0.08 + (Double(taker.player.attributes.crossing) / 500.0)
        if isHomeAttacking { homeXG += cornerXG } else { awayXG += cornerXG }
        if isHomeAttacking { homeShots += 1 } else { awayShots += 1 }
        
        // Goal chance (~11% for high quality set-pieces)
        let headingSkill = Double(headerTarget.player.attributes.heading)
        let goalChance = (Double(taker.player.attributes.crossing) * 0.05 + headingSkill * 0.08) / 100.0
        
        if Double.random(in: 0...1) < goalChance {
            if isHomeAttacking {
                homeGoals += 1
                homeShotsOnTarget += 1
            } else {
                awayGoals += 1
                awayShotsOnTarget += 1
            }
            
            if let idx = (isHomeAttacking ? homeActive : awayActive).firstIndex(where: { $0.player.id == headerTarget.player.id }) {
                if isHomeAttacking {
                    homeActive[idx].goals += 1
                    homeActive[idx].currentRating += 1.2
                } else {
                    awayActive[idx].goals += 1
                    awayActive[idx].currentRating += 1.2
                }
            }
            if let tIdx = (isHomeAttacking ? homeActive : awayActive).firstIndex(where: { $0.player.id == taker.player.id }) {
                if isHomeAttacking {
                    homeActive[tIdx].assists += 1
                    homeActive[tIdx].currentRating += 0.6
                } else {
                    awayActive[tIdx].assists += 1
                    awayActive[tIdx].currentRating += 0.6
                }
            }
            
            let commentary = Commentary.goal(
                scorer: headerTarget.player,
                assister: taker.player,
                club: attackingClub,
                opponent: defendingClub,
                minute: minute,
                homeGoals: homeGoals,
                awayGoals: awayGoals,
                isHome: isHomeAttacking,
                goalType: .glancingCornerHeader
            )
            
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .corner,
                    clubId: attackingClub.id,
                    playerId: headerTarget.player.id,
                    assistPlayerId: taker.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeAttacking
                )
            )
        }
    }
    
    // MARK: - Free Kick Resolution
    
    private static func resolveFreeKick(
        isHomeAttacking: Bool,
        homeActive: inout [ActiveMatchPlayer],
        awayActive: inout [ActiveMatchPlayer],
        homeClub: Club,
        awayClub: Club,
        homeGoals: inout Int,
        awayGoals: inout Int,
        homeShots: inout Int,
        awayShots: inout Int,
        homeShotsOnTarget: inout Int,
        awayShotsOnTarget: inout Int,
        homeXG: inout Double,
        awayXG: inout Double,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        let attackingClub = isHomeAttacking ? homeClub : awayClub
        let defendingClub = isHomeAttacking ? awayClub : homeClub
        let attackingSquad = isHomeAttacking ? homeActive : awayActive
        
        let freeKickTakerId = attackingClub.tactics.freeKickTaker
        let taker = attackingSquad.first { $0.player.id == freeKickTakerId && !$0.isSentOff } ??
            attackingSquad.max(by: { $0.player.attributes.freeKicks < $1.player.attributes.freeKicks })!
        
        let fkSkill = Double(taker.player.attributes.freeKicks)
        let chanceXG = 0.07 + (fkSkill / 400.0)
        if isHomeAttacking {
            homeShots += 1
            homeXG += chanceXG
        } else {
            awayShots += 1
            awayXG += chanceXG
        }
        
        let conversionChance = (fkSkill * 0.12) / 100.0
        if Double.random(in: 0...1) < conversionChance {
            if isHomeAttacking {
                homeGoals += 1
                homeShotsOnTarget += 1
            } else {
                awayGoals += 1
                awayShotsOnTarget += 1
            }
            
            if let idx = (isHomeAttacking ? homeActive : awayActive).firstIndex(where: { $0.player.id == taker.player.id }) {
                if isHomeAttacking {
                    homeActive[idx].goals += 1
                    homeActive[idx].currentRating += 1.3
                } else {
                    awayActive[idx].goals += 1
                    awayActive[idx].currentRating += 1.3
                }
            }
            
            let commentary = Commentary.goal(
                scorer: taker.player,
                assister: nil,
                club: attackingClub,
                opponent: defendingClub,
                minute: minute,
                homeGoals: homeGoals,
                awayGoals: awayGoals,
                isHome: isHomeAttacking,
                goalType: .curlingFreeKick
            )
            
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .freeKick,
                    clubId: attackingClub.id,
                    playerId: taker.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeAttacking
                )
            )
        }
    }
    
    // MARK: - Foul & Penalty Resolution
    
    private static func resolveFoul(
        isHomeTeamFouling: Bool,
        homeActive: inout [ActiveMatchPlayer],
        awayActive: inout [ActiveMatchPlayer],
        homeClub: Club,
        awayClub: Club,
        homeFouls: inout Int,
        awayFouls: inout Int,
        homeGoals: inout Int,
        awayGoals: inout Int,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        if isHomeTeamFouling { homeFouls += 1 } else { awayFouls += 1 }
        
        let foulingClub = isHomeTeamFouling ? homeClub : awayClub
        let fouledClub = isHomeTeamFouling ? awayClub : homeClub
        var foulingSquad = isHomeTeamFouling ? homeActive : awayActive
        
        let activeFoulers = foulingSquad.filter { !$0.isSentOff }
        guard let fouler = activeFoulers.randomElement() else { return }
        guard let foulerIdx = (isHomeTeamFouling ? homeActive : awayActive).firstIndex(where: { $0.player.id == fouler.player.id }) else { return }
        
        let aggression = Double(fouler.player.attributes.aggression)
        let tackling = Double(fouler.player.attributes.tackling)
        
        // Probability of a card given foul
        let cardProbability = (aggression * 0.45 + (100.0 - tackling) * 0.3) / 100.0
        
        if Double.random(in: 0...1) < cardProbability {
            // Check if penalty in the box (~1 in 9 fouls)
            let isPenalty = Double.random(in: 0...1) < 0.12
            
            if isPenalty {
                resolveInMatchPenalty(
                    isHomeKicking: !isHomeTeamFouling,
                    homeActive: &homeActive,
                    awayActive: &awayActive,
                    homeClub: homeClub,
                    awayClub: awayClub,
                    homeGoals: &homeGoals,
                    awayGoals: &awayGoals,
                    minute: minute,
                    events: &events
                )
            }
            
            // Card roll: yellow or straight red
            let isStraightRed = Double.random(in: 0...1) < 0.03
            
            if isStraightRed {
                if isHomeTeamFouling {
                    homeActive[foulerIdx].isSentOff = true
                    homeActive[foulerIdx].currentRating = max(4.0, homeActive[foulerIdx].currentRating - 1.5)
                } else {
                    awayActive[foulerIdx].isSentOff = true
                    awayActive[foulerIdx].currentRating = max(4.0, awayActive[foulerIdx].currentRating - 1.5)
                }
                
                let commentary = Commentary.card(
                    player: fouler.player,
                    club: foulingClub,
                    isRed: true,
                    isSecondYellow: false,
                    minute: minute
                )
                events.append(
                    MatchEvent(
                        minute: minute,
                        type: .redCard,
                        clubId: foulingClub.id,
                        playerId: fouler.player.id,
                        shortText: commentary.short,
                        detailText: commentary.detail,
                        isHomeTeam: isHomeTeamFouling
                    )
                )
            } else {
                // Yellow card
                let currentYellows = isHomeTeamFouling ? homeActive[foulerIdx].yellowCards : awayActive[foulerIdx].yellowCards
                if currentYellows >= 1 {
                    // Second yellow -> Red
                    if isHomeTeamFouling {
                        homeActive[foulerIdx].yellowCards += 1
                        homeActive[foulerIdx].isSentOff = true
                        homeActive[foulerIdx].currentRating = max(4.0, homeActive[foulerIdx].currentRating - 1.2)
                    } else {
                        awayActive[foulerIdx].yellowCards += 1
                        awayActive[foulerIdx].isSentOff = true
                        awayActive[foulerIdx].currentRating = max(4.0, awayActive[foulerIdx].currentRating - 1.2)
                    }
                    
                    let commentary = Commentary.card(
                        player: fouler.player,
                        club: foulingClub,
                        isRed: true,
                        isSecondYellow: true,
                        minute: minute
                    )
                    events.append(
                        MatchEvent(
                            minute: minute,
                            type: .secondYellow,
                            clubId: foulingClub.id,
                            playerId: fouler.player.id,
                            shortText: commentary.short,
                            detailText: commentary.detail,
                            isHomeTeam: isHomeTeamFouling
                        )
                    )
                } else {
                    // First yellow
                    if isHomeTeamFouling {
                        homeActive[foulerIdx].yellowCards = 1
                        homeActive[foulerIdx].currentRating = max(4.0, homeActive[foulerIdx].currentRating - 0.4)
                    } else {
                        awayActive[foulerIdx].yellowCards = 1
                        awayActive[foulerIdx].currentRating = max(4.0, awayActive[foulerIdx].currentRating - 0.4)
                    }
                    
                    let commentary = Commentary.card(
                        player: fouler.player,
                        club: foulingClub,
                        isRed: false,
                        minute: minute
                    )
                    events.append(
                        MatchEvent(
                            minute: minute,
                            type: .yellowCard,
                            clubId: foulingClub.id,
                            playerId: fouler.player.id,
                            shortText: commentary.short,
                            detailText: commentary.detail,
                            isHomeTeam: isHomeTeamFouling
                        )
                    )
                }
            }
        }
    }
    
    // MARK: - In-Match Penalty Kick
    
    private static func resolveInMatchPenalty(
        isHomeKicking: Bool,
        homeActive: inout [ActiveMatchPlayer],
        awayActive: inout [ActiveMatchPlayer],
        homeClub: Club,
        awayClub: Club,
        homeGoals: inout Int,
        awayGoals: inout Int,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        let kickingClub = isHomeKicking ? homeClub : awayClub
        let defendingClub = isHomeKicking ? awayClub : homeClub
        let kickingSquad = isHomeKicking ? homeActive : awayActive
        let defendingSquad = isHomeKicking ? awayActive : homeActive
        
        let penaltyTakerId = kickingClub.tactics.penaltyTaker
        let taker = kickingSquad.first { $0.player.id == penaltyTakerId && !$0.isSentOff } ??
            kickingSquad.max(by: { $0.player.attributes.penalties < $1.player.attributes.penalties })!
        
        let gk = defendingSquad.first { $0.player.primaryPosition == .GK && !$0.isSentOff } ?? defendingSquad[0]
        
        let penaltySkill = Double(taker.player.attributes.penalties)
        let composure = Double(taker.player.attributes.composure)
        let gkOneOnOnes = Double(gk.player.attributes.oneOnOnes)
        let gkReflexes = Double(gk.player.attributes.reflexes)
        
        let conversionRate = 0.76 + ((penaltySkill + composure) - (gkOneOnOnes + gkReflexes)) * 0.0015
        let isScored = Double.random(in: 0...1) < min(0.92, max(0.55, conversionRate))
        
        if isScored {
            if isHomeKicking { homeGoals += 1 } else { awayGoals += 1 }
            
            if let idx = (isHomeKicking ? homeActive : awayActive).firstIndex(where: { $0.player.id == taker.player.id }) {
                if isHomeKicking {
                    homeActive[idx].goals += 1
                    homeActive[idx].currentRating += 1.0
                } else {
                    awayActive[idx].goals += 1
                    awayActive[idx].currentRating += 1.0
                }
            }
            
            let commentary = Commentary.goal(
                scorer: taker.player,
                assister: nil,
                club: kickingClub,
                opponent: defendingClub,
                minute: minute,
                homeGoals: homeGoals,
                awayGoals: awayGoals,
                isHome: isHomeKicking,
                goalType: .clinicalPenalty
            )
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .penalty,
                    clubId: kickingClub.id,
                    playerId: taker.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeKicking
                )
            )
        } else {
            let shortText = "❌ PENALTY SAVED! \(taker.player.displayName) misses! \(minute)'"
            let detailText = "\(taker.player.fullName) struck it towards the bottom corner, but \(gk.player.fullName) guessed correctly and pulled off a stunning penalty save!"
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .penaltyMissed,
                    clubId: kickingClub.id,
                    playerId: taker.player.id,
                    shortText: shortText,
                    detailText: detailText,
                    isHomeTeam: isHomeKicking
                )
            )
        }
    }
    
    // MARK: - Penalty Shootout
    
    private static func resolvePenaltyShootout(
        homeClub: Club,
        awayClub: Club,
        homeActive: [ActiveMatchPlayer],
        awayActive: [ActiveMatchPlayer],
        homeGoals: inout Int,
        awayGoals: inout Int,
        events: inout [MatchEvent]
    ) {
        events.append(
            MatchEvent(
                minute: 120,
                type: .penaltyShootout,
                shortText: "⚡ PENALTY SHOOTOUT BEGINS!",
                detailText: "All square after 120 minutes! The tie will be decided from twelve yards.",
                isHomeTeam: true
            )
        )
        
        var homeTakers = homeActive.filter { !$0.isSentOff }.sorted { $0.player.attributes.penalties > $1.player.attributes.penalties }
        var awayTakers = awayActive.filter { !$0.isSentOff }.sorted { $0.player.attributes.penalties > $1.player.attributes.penalties }
        
        let homeGk = homeActive.first { $0.player.primaryPosition == .GK } ?? homeActive[0]
        let awayGk = awayActive.first { $0.player.primaryPosition == .GK } ?? awayActive[0]
        
        var homeShootoutScore = 0
        var awayShootoutScore = 0
        
        // Best of 5 rounds + sudden death
        for round in 1...11 {
            let homeTaker = homeTakers[(round - 1) % homeTakers.count]
            let awayTaker = awayTakers[(round - 1) % awayTakers.count]
            
            let homeSuccess = Double.random(in: 0...1) < (0.75 + Double(homeTaker.player.attributes.penalties - awayGk.player.attributes.reflexes) * 0.002)
            if homeSuccess { homeShootoutScore += 1 }
            
            let awaySuccess = Double.random(in: 0...1) < (0.75 + Double(awayTaker.player.attributes.penalties - homeGk.player.attributes.reflexes) * 0.002)
            if awaySuccess { awayShootoutScore += 1 }
            
            // Check best of 5 termination or sudden death
            if round >= 5 && homeShootoutScore != awayShootoutScore {
                break
            }
        }
        
        // Award victory by adding 1 shootout goal
        if homeShootoutScore > awayShootoutScore {
            homeGoals += 1
            events.append(
                MatchEvent(
                    minute: 120,
                    type: .penaltyShootout,
                    shortText: "🏆 \(homeClub.name) win on penalties (\(homeShootoutScore)-\(awayShootoutScore))!",
                    detailText: "Jubilation for \(homeClub.name) as they prevail in the dramatic penalty shootout!",
                    isHomeTeam: true
                )
            )
        } else {
            awayGoals += 1
            events.append(
                MatchEvent(
                    minute: 120,
                    type: .penaltyShootout,
                    shortText: "🏆 \(awayClub.name) win on penalties (\(awayShootoutScore)-\(homeShootoutScore))!",
                    detailText: "Heroics in the shootout! \(awayClub.name) triumph from the spot!",
                    isHomeTeam: false
                )
            )
        }
    }
    
    // MARK: - Tactical Strength Calculator
    
    private static func calculateTeamStrength(
        activePlayers: [ActiveMatchPlayer],
        tactics: Tactics,
        isHome: Bool,
        neutralVenue: Bool
    ) -> Double {
        var baseStrength = 0.0
        var count = 0
        
        for ap in activePlayers where !ap.isSentOff {
            baseStrength += ap.effectiveSkill(for: ap.player.primaryPosition.category)
            count += 1
        }
        
        guard count > 0 else { return 30.0 }
        let average = baseStrength / Double(count)
        
        // Red card handicap (playing with 10 or 9 men severely damages performance)
        let redCardPenalty = Double(11 - count) * 4.5
        var total = max(20.0, average - redCardPenalty)
        
        // Mentality modifier
        total *= tactics.mentality.attackingMultiplier
        
        // Home advantage (~8% boost unless neutral venue)
        if isHome && !neutralVenue {
            total *= 1.08
        }
        
        return total
    }
    
    // MARK: - Fatigue Progression
    
    private static func updateFatigue(
        activePlayers: inout [ActiveMatchPlayer],
        tactics: Tactics
    ) {
        let pressingDrain = tactics.pressing.staminaDrainMultiplier
        
        for idx in 0..<activePlayers.count {
            guard !activePlayers[idx].isSentOff && !activePlayers[idx].isSubstitutedOut else { continue }
            activePlayers[idx].minutesPlayed += 1
            
            let staminaStat = Double(activePlayers[idx].player.attributes.stamina)
            let baseDrain = (0.28 - (staminaStat * 0.0015)) * pressingDrain
            activePlayers[idx].currentFatigue = min(100.0, activePlayers[idx].currentFatigue + baseDrain)
        }
    }
    
    // MARK: - Substitutions
    
    private static func tryPerformSubstitution(
        activePlayers: inout [ActiveMatchPlayer],
        bench: inout [Player],
        subsUsed: inout Int,
        maxSubs: Int,
        club: Club,
        isHome: Bool,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        guard subsUsed < maxSubs && !bench.isEmpty else { return }
        
        // Find most fatigued starter (excluding GK unless injured)
        let candidates = activePlayers.enumerated().filter { _, ap in
            !ap.isSentOff && !ap.isSubstitutedOut && ap.player.primaryPosition != .GK
        }
        guard let (outIdx, playerToSub) = candidates.max(by: { $0.1.currentFatigue < $1.1.currentFatigue }),
              playerToSub.currentFatigue > 60.0 else { return }
        
        // Find compatible player on bench
        let cat = playerToSub.player.primaryPosition.category
        let benchMatchIdx = bench.firstIndex(where: { $0.primaryPosition.category == cat }) ?? 0
        let incomingPlayer = bench.remove(at: benchMatchIdx)
        
        // Mark outgoing
        activePlayers[outIdx].isSubstitutedOut = true
        
        // Insert fresh legs into active match players
        let freshSub = ActiveMatchPlayer(player: incomingPlayer, currentFatigue: 0.0, currentRating: 6.0)
        activePlayers[outIdx] = freshSub
        subsUsed += 1
        
        let commentary = Commentary.substitution(
            playerIn: incomingPlayer,
            playerOut: playerToSub.player,
            club: club,
            minute: minute
        )
        events.append(
            MatchEvent(
                minute: minute,
                type: .substitution,
                clubId: club.id,
                playerId: incomingPlayer.id,
                shortText: commentary.short,
                detailText: commentary.detail,
                isHomeTeam: isHome
            )
        )
    }
    
    // MARK: - In-Match Injury Check
    
    private static func checkInMatchInjury(
        homeActive: inout [ActiveMatchPlayer],
        awayActive: inout [ActiveMatchPlayer],
        homeClub: Club,
        awayClub: Club,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        let isHome = Double.random(in: 0...1) < 0.5
        let intensity = isHome ? homeClub.tactics.pressing.staminaDrainMultiplier : awayClub.tactics.pressing.staminaDrainMultiplier
        
        if isHome {
            guard let idx = homeActive.indices.randomElement(), !homeActive[idx].isSentOff else { return }
            if let injury = InjuryEngine.checkForInjury(player: homeActive[idx].player, matchMinute: minute, intensity: intensity) {
                homeActive[idx].player.injury = injury
                let commentary = Commentary.injury(player: homeActive[idx].player, club: homeClub, minute: minute, injuryType: injury.type)
                events.append(
                    MatchEvent(
                        minute: minute,
                        type: .injury,
                        clubId: homeClub.id,
                        playerId: homeActive[idx].player.id,
                        shortText: commentary.short,
                        detailText: commentary.detail,
                        isHomeTeam: true
                    )
                )
            }
        } else {
            guard let idx = awayActive.indices.randomElement(), !awayActive[idx].isSentOff else { return }
            if let injury = InjuryEngine.checkForInjury(player: awayActive[idx].player, matchMinute: minute, intensity: intensity) {
                awayActive[idx].player.injury = injury
                let commentary = Commentary.injury(player: awayActive[idx].player, club: awayClub, minute: minute, injuryType: injury.type)
                events.append(
                    MatchEvent(
                        minute: minute,
                        type: .injury,
                        clubId: awayClub.id,
                        playerId: awayActive[idx].player.id,
                        shortText: commentary.short,
                        detailText: commentary.detail,
                        isHomeTeam: false
                    )
                )
            }
        }
    }
    
    // MARK: - Man of the Match
    
    private static func determineManOfTheMatch(
        homeActive: [ActiveMatchPlayer],
        awayActive: [ActiveMatchPlayer]
    ) -> ActiveMatchPlayer? {
        let all = homeActive + awayActive
        return all.max(by: { $0.currentRating < $1.currentRating })
    }
    
    // MARK: - Post-Match Club State Synchronization
    
    private static func applyMatchToClub(
        club: inout Club,
        activePlayers: [ActiveMatchPlayer],
        opponentGoals: Int,
        motmId: UUID?
    ) {
        let isCleanSheet = (opponentGoals == 0)
        
        for ap in activePlayers {
            if var p = club.player(withId: ap.player.id) {
                let isMotm = (p.id == motmId)
                let gotYellow = (ap.yellowCards >= 1)
                let gotRed = ap.isSentOff
                
                p.recordMatch(
                    rating: (ap.currentRating * 10).rounded() / 10,
                    minutes: ap.minutesPlayed,
                    goals: ap.goals,
                    assists: ap.assists,
                    yellowCard: gotYellow,
                    redCard: gotRed,
                    cleanSheet: isCleanSheet,
                    isMotm: isMotm
                )
                
                if let inj = ap.player.injury {
                    p.injury = inj
                }
                
                club.updatePlayer(p)
            }
        }
    }
}
