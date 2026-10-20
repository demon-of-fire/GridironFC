//
//  FaceStatsView.swift
//  GridironFC
//
//  Reusable FIFA-style attribute displays used across player cards and profiles.
//  Shows the six headline ratings (PAC/SHO/PAS/DRI/DEF/PHY for outfielders and
//  DIV/HAN/KIC/REF/SPD/POS for goalkeepers).
//

import SwiftUI

// MARK: - Face Stat Colour

private extension PlayerAttributes.FaceStat {
    /// A colour that escalates with the rating so strong attributes stand out.
    var tint: Color {
        switch value {
        case 80...: return Color(hex: "2ECC71")
        case 70..<80: return Color(hex: "A6E22E")
        case 60..<70: return Color(hex: "F1C40F")
        case 50..<60: return Color(hex: "E67E22")
        default: return Color(hex: "E74C3C")
        }
    }
}

// MARK: - Compact Face Stat Row

/// A dense horizontal strip of the six headline stats, suitable for list rows.
public struct FaceStatStripView: View {
    public let player: Player
    public var showsHeaders: Bool = true

    public init(player: Player, showsHeaders: Bool = true) {
        self.player = player
        self.showsHeaders = showsHeaders
    }

    public var body: some View {
        let stats = player.faceStats
        HStack(spacing: 10) {
            ForEach(stats) { stat in
                VStack(spacing: 1) {
                    if showsHeaders {
                        Text(stat.code)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text("\(stat.value)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(stat.tint)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(stat.label) \(stat.value)")
            }
        }
    }
}

// MARK: - Full Face Stat Grid

/// A two-row grid of large stat tiles used on the player detail screen.
public struct FaceStatGridView: View {
    public let player: Player
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    public init(player: Player) {
        self.player = player
    }

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(player.faceStats) { stat in
                VStack(spacing: 2) {
                    Text(stat.code)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text("\(stat.value)")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(stat.tint)
                    Text(stat.label)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(stat.label) \(stat.value) out of 99")
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Face Stats") {
    let attrs = PlayerAttributes(
        passing: 74, shooting: 88, dribbling: 82, firstTouch: 80, crossing: 70,
        freeKicks: 65, penalties: 84, heading: 79, longShots: 85, tackling: 42, marking: 38,
        pace: 91, stamina: 78, strength: 76, agility: 88, jumping: 74, balance: 80,
        vision: 72, composure: 85, decisions: 70, workRate: 66, aggression: 60,
        leadership: 68, teamwork: 72, positioning: 75, offTheBall: 87, concentration: 71
    )
    let player = Player(
        firstName: "Marcus",
        lastName: "Vega",
        nationality: "England",
        age: 24,
        height: 181,
        weight: 76,
        preferredFoot: .right,
        positions: [.ST],
        attributes: attrs,
        overall: 84,
        potential: 90
    )
    return ScrollView {
        VStack(spacing: 20) {
            FaceStatGridView(player: player)
            FaceStatStripView(player: player)
        }
        .padding()
    }
}
#endif
