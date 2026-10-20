//
//  GridironFCApp.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Application entrypoint initializing the root GameState environment
//  and handling background state autosaving.
//

import SwiftUI

@main
struct GridironFCApp: App {
    
    @State private var gameState: GameState
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Attempt to load existing autosave or bootstrap initial data
        if let savedState = try? SaveManager.shared.loadAutoSave() {
            _gameState = State(initialValue: savedState)
        } else {
            let (clubs, leagues) = DataLoader.loadAllData()
            
            // Build initial season fixtures across all leagues
            var allFixtures: [Fixture] = []
            for league in leagues {
                let fixtures = FixtureGenerator.generateDoubleRoundRobin(
                    clubIds: league.clubIds,
                    competitionName: league.name,
                    startDateString: "2026-08-08"
                )
                allFixtures.append(contentsOf: fixtures)
            }
            
            let initialSeason = Season(
                year: "2026-27",
                currentWeek: 1,
                currentPhase: .preseason,
                fixtures: allFixtures,
                currentDate: "2026-08-01"
            )
            
            let state = GameState(
                gameMode: .createClub,
                clubs: clubs,
                leagues: leagues,
                season: initialSeason,
                currentScreen: .mainMenu,
                europeanCompetitions: EuropeanCompetitionBuilder.build(from: clubs),
                nationalTeams: DataLoader.loadNationalTeams()
            )
            state.seedFreeAgents()
            state.seedAcademies()
            state.seedInternationalTournaments()
            
            _gameState = State(initialValue: state)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameState)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                // Auto-save on backgrounding
                try? SaveManager.shared.autoSave(gameState: gameState)
            }
        }
    }
}
