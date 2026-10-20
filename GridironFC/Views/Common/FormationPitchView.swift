//
//  FormationPitchView.swift
//  GridironFC
//
//  Interactive top-down formation board for the squad screen. Draws the current
//  formation as a pitch with a token for each starting player. Tapping a token
//  selects that player so they can be swapped with a substitute (manager mode).
//

import SwiftUI

// MARK: - Formation Layout

/// Computes normalised (0...1) slot coordinates for each position in a formation.
/// Coordinates run from the user's own goal (y = 1.0, bottom) to the opponent goal
/// (y = 0.0, top), i.e. an attacking-first orientation.
enum FormationLayout {

    /// A horizontal role column used to separate players sharing a line.
    private enum Lane {
        case gk, leftCenter, center, rightCenter, left, right, leftInner, rightInner

        var x: CGFloat {
            switch self {
            case .gk: return 0.50
            case .leftCenter: return 0.36
            case .center: return 0.50
            case .rightCenter: return 0.64
            case .leftInner: return 0.28
            case .rightInner: return 0.72
            case .left: return 0.14
            case .right: return 0.86
            }
        }
    }

    private struct Slot {
        let lane: Lane
        let depth: CGFloat   // 0 (own goal line) ... 1 (near halfway/attack)
    }

    /// Returns up to 11 slot coordinates, ordered to match `formation.defaultPositions`.
    static func slots(for formation: FormationPreset) -> [CGPoint] {
        let positions = formation.defaultPositions
        let raw: [Slot] = positions.map { slot(for: $0) }
        return raw.map { CGPoint(x: $0.lane.x, y: 0.90 - $0.depth * 0.78) }
    }

    /// Maps a position in a formation to a lane + depth. Depth is derived from the
    /// position's category so lines stay visually separated.
    private static func slot(for position: Position) -> Slot {
        switch position {
        case .GK:
            return Slot(lane: .gk, depth: 0.02)

        case .CB:
            return Slot(lane: .center, depth: 0.10)
        case .LB:
            return Slot(lane: .left, depth: 0.12)
        case .RB:
            return Slot(lane: .right, depth: 0.12)
        case .LWB:
            return Slot(lane: .left, depth: 0.24)
        case .RWB:
            return Slot(lane: .right, depth: 0.24)

        case .CDM:
            return Slot(lane: .center, depth: 0.26)
        case .CM:
            return Slot(lane: .center, depth: 0.40)
        case .LM:
            return Slot(lane: .left, depth: 0.40)
        case .RM:
            return Slot(lane: .right, depth: 0.40)
        case .CAM:
            return Slot(lane: .center, depth: 0.54)

        case .LW:
            return Slot(lane: .left, depth: 0.66)
        case .RW:
            return Slot(lane: .right, depth: 0.66)
        case .ST:
            return Slot(lane: .center, depth: 0.74)
        case .CF:
            return Slot(lane: .center, depth: 0.66)
        }
    }

    /// Spreads slots that share both a lane and a depth so they do not overlap.
    static func resolvedSlots(for formation: FormationPreset) -> [CGPoint] {
        var points = slots(for: formation)
        // Group near-identical points and fan them horizontally.
        var used: [Int: Int] = [:]  // bucket key -> count so far
        for i in points.indices {
            let key = Int(points[i].y * 100)
            let seen = used[key, default: 0]
            used[key] = seen + 1
            if seen > 0 {
                let shift = CGFloat(seen) * 0.16
                points[i].x = min(0.94, max(0.06, points[i].x + shift))
            }
        }
        return points
    }
}

// MARK: - Formation Pitch View

public struct FormationPitchView: View {
    public let formation: FormationPreset
    public let players: [Player]
    public let selectedPlayerId: UUID?
    public let onSelect: (Player) -> Void

    public init(
        formation: FormationPreset,
        players: [Player],
        selectedPlayerId: UUID?,
        onSelect: @escaping (Player) -> Void
    ) {
        self.formation = formation
        self.players = players
        self.selectedPlayerId = selectedPlayerId
        self.onSelect = onSelect
    }

    public var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let slots = FormationLayout.resolvedSlots(for: formation)

            ZStack {
                Canvas { context, canvasSize in
                    drawPitch(in: &context, size: canvasSize)
                }
                .frame(width: size.width, height: size.height)

                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    if index < slots.count {
                        let point = slots[index]
                        PlayerTokenView(
                            player: player,
                            isSelected: player.id == selectedPlayerId
                        )
                        .position(x: point.x * size.width, y: point.y * size.height)
                        .onTapGesture { onSelect(player) }
                        .accessibilityLabel("\(player.fullName), \(player.primaryPosition.displayName), overall \(player.overall)")
                        .accessibilityAddTraits(player.id == selectedPlayerId ? [.isSelected, .isButton] : .isButton)
                        .accessibilityHint("Double tap to select this player for substitution")
                    }
                }
            }
        }
        .aspectRatio(68.0 / 105.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.25), lineWidth: 2)
        )
        .accessibilityElement(children: .contain)
    }

    private func drawPitch(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height

        let stripeCount = 8
        for i in 0..<stripeCount {
            let rect = CGRect(x: 0, y: h * CGFloat(i) / CGFloat(stripeCount), width: w, height: h / CGFloat(stripeCount))
            let color = i % 2 == 0 ? Color.pitchGrassLight : Color.pitchGrassDark
            context.fill(Path(rect), with: .color(color))
        }

        let lineColor = Color.white.opacity(0.7)
        let lineWidth = max(1.5, w * 0.005)
        let inset = w * 0.03
        let field = CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2)
        context.stroke(Path(field), with: .color(lineColor), lineWidth: lineWidth)

        var halfway = Path()
        halfway.move(to: CGPoint(x: field.minX, y: field.midY))
        halfway.addLine(to: CGPoint(x: field.maxX, y: field.midY))
        context.stroke(halfway, with: .color(lineColor), lineWidth: lineWidth)

        let circleRadius = field.width * 0.13
        context.stroke(
            Path(ellipseIn: CGRect(x: field.midX - circleRadius, y: field.midY - circleRadius, width: circleRadius * 2, height: circleRadius * 2)),
            with: .color(lineColor),
            lineWidth: lineWidth
        )

        let boxW = field.width * 0.55
        let boxH = field.height * 0.14
        let topBox = CGRect(x: field.midX - boxW / 2, y: field.minY, width: boxW, height: boxH)
        let bottomBox = CGRect(x: field.midX - boxW / 2, y: field.maxY - boxH, width: boxW, height: boxH)
        context.stroke(Path(topBox), with: .color(lineColor), lineWidth: lineWidth)
        context.stroke(Path(bottomBox), with: .color(lineColor), lineWidth: lineWidth)

        let goalW = field.width * 0.28
        let goalH = boxH * 0.42
        let topGoal = CGRect(x: field.midX - goalW / 2, y: field.minY, width: goalW, height: goalH)
        let bottomGoal = CGRect(x: field.midX - goalW / 2, y: field.maxY - goalH, width: goalW, height: goalH)
        context.stroke(Path(topGoal), with: .color(lineColor), lineWidth: lineWidth)
        context.stroke(Path(bottomGoal), with: .color(lineColor), lineWidth: lineWidth)
    }
}

// MARK: - Player Token

public struct PlayerTokenView: View {
    public let player: Player
    public let isSelected: Bool

    public init(player: Player, isSelected: Bool) {
        self.player = player
        self.isSelected = isSelected
    }

    public var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(player.primaryPosition.category.accentColor)
                    .frame(width: 34, height: 34)
                Circle()
                    .stroke(isSelected ? Color.white : Color.black.opacity(0.35), lineWidth: isSelected ? 3 : 1)
                    .frame(width: 34, height: 34)
                Text(player.primaryPosition.abbreviation)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 42, height: 42)
                }
            }
            Text(player.displayName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
                .lineLimit(1)
            Text("\(player.overall)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Formation") {
    let positions: [Position] = [.GK, .LB, .CB, .CB, .RB, .LM, .CM, .CM, .RM, .ST, .ST]
    let players = positions.enumerated().map { idx, pos in
        Player(
            firstName: "Player",
            lastName: "\(idx + 1)",
            nationality: "England",
            age: 24,
            height: 180,
            weight: 75,
            preferredFoot: .right,
            positions: [pos],
            attributes: PlayerAttributes(),
            overall: 60 + idx,
            potential: 75
        )
    }
    return FormationPitchView(formation: .f442, players: players, selectedPlayerId: players[5].id, onSelect: { _ in })
        .padding()
}
#endif
