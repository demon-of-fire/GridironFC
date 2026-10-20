//
//  Theme.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Design system colors, pitch theme aesthetics, and mock GameState factory for previews.
//

import SwiftUI
import Foundation

// MARK: - Color Hex Initializer

extension Color {
    public init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch clean.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 45, 139, 78) // Fallback to pitch green
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
    
    // MARK: - Theme Palette
    
    /// Football pitch primary brand green (#2D8B4E)
    public static let pitchGreen = Color(hex: "2D8B4E")
    public static let pitchDarkGreen = Color(hex: "174C2B")
    public static let pitchLightGreen = Color(hex: "3FA365")
    public static let pitchGrassLight = Color(hex: "237542")
    public static let pitchGrassDark = Color(hex: "1D6437")
    
    /// Dark theme backgrounds
    public static let darkBackground = Color(hex: "0D1117")
    public static let darkSurface = Color(hex: "161B22")
    public static let cardBackground = Color(hex: "161B22")
    public static let cardSecondary = Color(hex: "21262D")
    public static let cardBorder = Color(hex: "30363D")
    
    /// Accents & Status
    public static let goldAccent = Color(hex: "F1C40F")
    public static let silverAccent = Color(hex: "BDC3C7")
    public static let bronzeAccent = Color(hex: "E67E22")
    
    /// Positional Colors
    public static let gkColor = Color(hex: "F39C12")      // Warm Amber / Yellow
    public static let defColor = Color(hex: "2980B9")     // Solid Blue
    public static let midColor = Color(hex: "27AE60")     // Pitch Green
    public static let fwdColor = Color(hex: "E74C3C")     // Striker Red
    
    /// Result Colors
    public static let winGreen = Color(hex: "2ECC71")
    public static let drawGray = Color(hex: "7F8C8D")
    public static let lossRed = Color(hex: "E74C3C")
}

// MARK: - Position Category Color Extension

extension PositionCategory {
    public var accentColor: Color {
        switch self {
        case .goalkeeper: return .gkColor
        case .defender: return .defColor
        case .midfielder: return .midColor
        case .forward: return .fwdColor
        }
    }
}

extension Position {
    public var accentColor: Color {
        return category.accentColor
    }
}

// MARK: - Mock GameState Preview Helper

extension GameState {
    
    /// Static mock state pre-populated with realistic League Two squad, fixtures, and standings.
    public static var previewMock: GameState {
        let userClubId = UUID()
        let opponentClubId = UUID()
        let rivalClubId = UUID()
        
        // Generate players for preview
        let players = makeSampleSquad()
        let userClub = Club(
            id: userClubId,
            name: "Harrogate Athletic",
            shortName: "HAR",
            stadium: "Wetherby Road",
            stadiumCapacity: 5000,
            city: "Harrogate",
            primaryColor: "#2D8B4E",
            secondaryColor: "#F1C40F",
            leagueTier: .leagueTwo,
            reputation: 45,
            isUserClub: true,
            players: players,
            manager: "Alex Ferguson",
            finances: ClubFinances(
                transferBudget: 1_500_000,
                wageBudget: 40_000,
                currentWageBill: 32_500,
                balance: 2_100_000,
                tvIncome: 900_000,
                matchdayIncome: 55_000,
                sponsorshipIncome: 450_000,
                merchandiseIncome: 180_000
            ),
            tactics: Tactics(
                formation: .f442,
                mentality: .balanced,
                pressing: .medium,
                tempo: .normal,
                width: .normal,
                passingStyle: .mixed,
                startingXI: Array(players.prefix(11).map { $0.id }),
                substitutes: Array(players.dropFirst(11).prefix(7).map { $0.id }),
                cornerTaker: players.first?.id,
                freeKickTaker: players.first?.id,
                penaltyTaker: players.first?.id,
                captain: players.first?.id
            )
        )
        
        let opponentClub = Club(
            id: opponentClubId,
            name: "Wrexham AFC",
            shortName: "WRE",
            stadium: "Racecourse Ground",
            stadiumCapacity: 10771,
            city: "Wrexham",
            primaryColor: "#D11A2A",
            secondaryColor: "#FFFFFF",
            leagueTier: .leagueTwo,
            reputation: 52,
            isUserClub: false
        )
        
        let rivalClub = Club(
            id: rivalClubId,
            name: "Stockport County",
            shortName: "STK",
            stadium: "Edgeley Park",
            stadiumCapacity: 10852,
            city: "Stockport",
            primaryColor: "#00205B",
            secondaryColor: "#FFFFFF",
            leagueTier: .leagueTwo,
            reputation: 50,
            isUserClub: false
        )
        
        let league = League(
            id: UUID(),
            name: "League Two",
            tier: .leagueTwo,
            clubIds: [userClubId, opponentClubId, rivalClubId]
        )
        
        let fixtures = [
            Fixture(
                homeClubId: userClubId,
                awayClubId: opponentClubId,
                matchWeek: 1,
                date: "2024-08-10",
                competition: "League Two",
                isPlayed: true,
                result: MatchResult(
                    homeClubId: userClubId,
                    awayClubId: opponentClubId,
                    homeGoals: 2,
                    awayGoals: 1,
                    events: [
                        MatchEvent(minute: 23, type: .goal, clubId: userClubId, shortText: "⚽ GOAL! J. Smith 23'", detailText: "Clinical finish into the bottom right.", isHomeTeam: true),
                        MatchEvent(minute: 67, type: .goal, clubId: opponentClubId, shortText: "⚽ GOAL! P. Mullin 67'", detailText: "Header off a set piece.", isHomeTeam: false),
                        MatchEvent(minute: 88, type: .goal, clubId: userClubId, shortText: "⚽ GOAL! T. Walker 88'", detailText: "Volley into top bin!", isHomeTeam: true)
                    ],
                    matchWeek: 1,
                    competition: "League Two",
                    date: "2024-08-10",
                    attendance: 4850
                )
            ),
            Fixture(
                homeClubId: rivalClubId,
                awayClubId: userClubId,
                matchWeek: 2,
                date: "2024-08-17",
                competition: "League Two",
                isPlayed: true,
                result: MatchResult(
                    homeClubId: rivalClubId,
                    awayClubId: userClubId,
                    homeGoals: 1,
                    awayGoals: 1,
                    events: [],
                    matchWeek: 2,
                    competition: "League Two",
                    date: "2024-08-17",
                    attendance: 6200
                )
            ),
            Fixture(
                homeClubId: userClubId,
                awayClubId: rivalClubId,
                matchWeek: 3,
                date: "2024-08-24",
                competition: "League Two",
                isPlayed: false
            )
        ]
        
        let news = [
            NewsItem(
                headline: "Pre-Season Training Underway",
                body: "Harrogate Athletic squad has reported for double fitness sessions ahead of the league opener.",
                date: "2024-08-01",
                category: .general
            ),
            NewsItem(
                headline: "Transfer Window Heating Up",
                body: "Clubs across League Two are actively seeking reinforcements before deadline day.",
                date: "2024-08-05",
                category: .transfer
            ),
            NewsItem(
                headline: "Opening Day Victory!",
                body: "Harrogate Athletic claimed an inspiring 2-1 win over Wrexham at Wetherby Road.",
                date: "2024-08-10",
                category: .result
            )
        ]
        
        let state = GameState(
            gameMode: .createClub,
            clubs: [userClub, opponentClub, rivalClub],
            leagues: [league],
            season: Season(
                year: "2024-25",
                currentWeek: 3,
                currentPhase: .inSeason,
                fixtures: fixtures,
                currentDate: "2024-08-20"
            ),
            userClubId: userClubId,
            freeAgents: [],
            transferHistory: [],
            pendingTransferOffers: [],
            news: news,
            currentScreen: .dashboard,
            isMatchInProgress: false
        )
        
        return state
    }
    
    private static func makeSampleSquad() -> [Player] {
        var squad: [Player] = []
        
        // Goalkeepers
        squad.append(Player(
            firstName: "Mark", lastName: "Oxley", nationality: "England", age: 33, height: 191, weight: 85,
            preferredFoot: .right, positions: [.GK], squadNumber: 1,
            attributes: PlayerAttributes(pace: 45, stamina: 55, strength: 70, agility: 62, reflexes: 68, handling: 65, gkPositioning: 64, oneOnOnes: 62, kicking: 58, commandOfArea: 66),
            overall: 65, potential: 65, form: [6.8, 7.0, 6.5, 6.7, 7.2], morale: .happy, matchFitness: 95.0, sharpness: 90.0
        ))
        squad.append(Player(
            firstName: "Lewis", lastName: "Thomas", nationality: "Wales", age: 24, height: 188, weight: 80,
            preferredFoot: .right, positions: [.GK], squadNumber: 13,
            attributes: PlayerAttributes(pace: 48, stamina: 60, strength: 65, agility: 60, reflexes: 58, handling: 56, gkPositioning: 55, oneOnOnes: 54, kicking: 52, commandOfArea: 54),
            overall: 56, potential: 62, form: [6.0], morale: .content, matchFitness: 100.0, sharpness: 75.0
        ))
        
        // Defenders
        squad.append(Player(
            firstName: "Warren", lastName: "Burrell", nationality: "England", age: 34, height: 185, weight: 79,
            preferredFoot: .right, positions: [.CB, .RB], squadNumber: 4,
            attributes: PlayerAttributes(heading: 68, tackling: 67, marking: 66, pace: 52, stamina: 64, strength: 72, composure: 65, leadership: 75),
            overall: 63, potential: 63, form: [6.5, 6.8, 6.7, 7.0, 6.9], morale: .happy, matchFitness: 88.0, sharpness: 92.0
        ))
        squad.append(Player(
            firstName: "Anthony", lastName: "O'Connor", nationality: "Ireland", age: 31, height: 188, weight: 82,
            preferredFoot: .right, positions: [.CB], squadNumber: 5,
            attributes: PlayerAttributes(heading: 71, tackling: 68, marking: 67, pace: 55, stamina: 68, strength: 75, leadership: 70),
            overall: 65, potential: 65, form: [7.1, 6.9, 6.8, 7.2, 7.0], morale: .delighted, matchFitness: 92.0, sharpness: 94.0
        ))
        squad.append(Player(
            firstName: "Kayne", lastName: "Ramsay", nationality: "England", age: 23, height: 181, weight: 74,
            preferredFoot: .right, positions: [.RB, .RWB], squadNumber: 2,
            attributes: PlayerAttributes(dribbling: 61, crossing: 62, tackling: 60, pace: 78, stamina: 74, agility: 72),
            overall: 62, potential: 70, form: [6.6, 6.5, 6.8, 6.9, 6.7], morale: .happy, matchFitness: 90.0, sharpness: 88.0
        ))
        squad.append(Player(
            firstName: "Matty", lastName: "Foulds", nationality: "England", age: 26, height: 184, weight: 76,
            preferredFoot: .left, positions: [.LB, .LWB], squadNumber: 3,
            attributes: PlayerAttributes(crossing: 64, tackling: 62, marking: 60, pace: 71, stamina: 72),
            overall: 62, potential: 66, form: [6.7, 6.4, 6.8, 6.6, 6.9], morale: .content, matchFitness: 85.0, sharpness: 86.0
        ))
        squad.append(Player(
            firstName: "Rod", lastName: "McDonald", nationality: "England", age: 32, height: 190, weight: 84,
            preferredFoot: .left, positions: [.CB], squadNumber: 15,
            attributes: PlayerAttributes(heading: 69, tackling: 64, marking: 63, strength: 74),
            overall: 61, potential: 61, form: [6.2], morale: .content, matchFitness: 100.0, sharpness: 70.0
        ))
        
        // Midfielders
        squad.append(Player(
            firstName: "Josh", lastName: "Falkingham", nationality: "England", age: 33, height: 175, weight: 70,
            preferredFoot: .right, positions: [.CM, .CDM], squadNumber: 6,
            attributes: PlayerAttributes(passing: 66, tackling: 65, stamina: 72, vision: 67, workRate: 85, leadership: 88),
            overall: 64, potential: 64, form: [7.0, 7.1, 6.9, 7.3, 7.0], morale: .delighted, matchFitness: 90.0, sharpness: 95.0
        ))
        squad.append(Player(
            firstName: "George", lastName: "Thomson", nationality: "England", age: 31, height: 178, weight: 73,
            preferredFoot: .right, positions: [.RM, .CM, .CAM], squadNumber: 7,
            attributes: PlayerAttributes(passing: 68, shooting: 65, crossing: 70, freeKicks: 74, pace: 67, vision: 69),
            overall: 66, potential: 66, form: [7.2, 7.5, 6.8, 7.1, 7.4], morale: .happy, matchFitness: 91.0, sharpness: 93.0
        ))
        squad.append(Player(
            firstName: "Dean", lastName: "Cornelius", nationality: "Scotland", age: 23, height: 177, weight: 71,
            preferredFoot: .right, positions: [.CM, .CDM], squadNumber: 8,
            attributes: PlayerAttributes(passing: 63, dribbling: 62, pace: 68, stamina: 76, workRate: 72),
            overall: 62, potential: 69, form: [6.6, 6.8, 6.7, 6.9, 6.5], morale: .happy, matchFitness: 94.0, sharpness: 89.0
        ))
        squad.append(Player(
            firstName: "Abraham", lastName: "Odoh", nationality: "England", age: 23, height: 173, weight: 68,
            preferredFoot: .right, positions: [.LM, .LW, .RM], squadNumber: 11,
            attributes: PlayerAttributes(shooting: 58, dribbling: 72, crossing: 61, pace: 82, agility: 79),
            overall: 63, potential: 71, form: [6.8, 7.2, 6.7, 7.0, 7.1], morale: .delighted, matchFitness: 89.0, sharpness: 91.0
        ))
        squad.append(Player(
            firstName: "Levi", lastName: "Sutton", nationality: "England", age: 27, height: 178, weight: 72,
            preferredFoot: .right, positions: [.CM], squadNumber: 18,
            attributes: PlayerAttributes(passing: 61, tackling: 62, stamina: 70, workRate: 71),
            overall: 60, potential: 62, form: [6.4], morale: .content, matchFitness: 100.0, sharpness: 78.0
        ))
        squad.append(Player(
            firstName: "Stephen", lastName: "Dooley", nationality: "Northern Ireland", age: 32, height: 174, weight: 70,
            preferredFoot: .left, positions: [.LM, .CM], squadNumber: 22,
            attributes: PlayerAttributes(passing: 64, dribbling: 63, pace: 63),
            overall: 60, potential: 60, form: [6.3], morale: .content, matchFitness: 100.0, sharpness: 72.0
        ))
        
        // Forwards
        squad.append(Player(
            firstName: "Jack", lastName: "Muldoon", nationality: "England", age: 34, height: 179, weight: 75,
            preferredFoot: .right, positions: [.ST, .CF], squadNumber: 9,
            attributes: PlayerAttributes(shooting: 67, heading: 66, pace: 65, strength: 71, composure: 68, workRate: 80),
            overall: 64, potential: 64, form: [7.1, 6.9, 7.4, 6.8, 7.3], morale: .happy, matchFitness: 86.0, sharpness: 90.0
        ))
        squad.append(Player(
            firstName: "Luke", lastName: "Armstrong", nationality: "England", age: 28, height: 184, weight: 78,
            preferredFoot: .right, positions: [.ST], squadNumber: 10,
            attributes: PlayerAttributes(shooting: 68, heading: 70, pace: 69, strength: 74, composure: 68),
            overall: 66, potential: 67, form: [7.4, 7.0, 7.2, 7.6, 7.1], morale: .delighted, matchFitness: 91.0, sharpness: 94.0
        ))
        squad.append(Player(
            firstName: "Sam", lastName: "Folarin", nationality: "England", age: 23, height: 180, weight: 73,
            preferredFoot: .right, positions: [.ST, .RW], squadNumber: 12,
            attributes: PlayerAttributes(shooting: 60, dribbling: 64, pace: 84, agility: 78),
            overall: 61, potential: 69, form: [6.5], morale: .content, matchFitness: 96.0, sharpness: 80.0
        ))
        squad.append(Player(
            firstName: "Josh", lastName: "March", nationality: "England", age: 27, height: 176, weight: 72,
            preferredFoot: .right, positions: [.ST], squadNumber: 19,
            attributes: PlayerAttributes(shooting: 62, pace: 72, composure: 61),
            overall: 61, potential: 63, form: [6.4], morale: .content, matchFitness: 98.0, sharpness: 79.0
        ))
        
        return squad
    }
}

// MARK: - View Modifiers

public struct FootballCardStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 5, x: 0, y: 3)
    }
}

extension View {
    public func footballCardStyle() -> some View {
        modifier(FootballCardStyle())
    }
}
