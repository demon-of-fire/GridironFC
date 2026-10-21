//
//  PitchReplayView.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Two-dimensional position-cam match replay. Renders 22 interpolated player dots
//  and the ball on a top-down pitch, driven by a minute ticker, and announces major
//  events for VoiceOver. Animation only; match outcome is decided by MatchEngine.
//

import SwiftUI
import Accessibility

// MARK: - Pitch Replay View

public struct PitchReplayView: View {
    public let fixture: Fixture
    public let homeClub: Club
    public let awayClub: Club
    public let minute: Int
    
    public var body: some View {
        GeometryReader { geo in
            let size = geo.size
            Canvas { context, canvasSize in
                drawPitch(in: &context, size: canvasSize)
                drawPlayers(in: &context, size: canvasSize)
                drawBall(in: &context, size: canvasSize)
            }
            .frame(width: size.width, height: size.height)
            .background(Color.pitchGrassDark)
        }
        .aspectRatio(68.0 / 105.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.25), lineWidth: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Match pitch replay, minute \(minute). Visual pitch only; use the live commentary list below for each match event.")
    }
    
    // MARK: - Pitch Drawing
    
    private func drawPitch(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        
        // Mowing stripes
        let stripeCount = 8
        for i in 0..<stripeCount {
            let rect = CGRect(
                x: 0,
                y: h * CGFloat(i) / CGFloat(stripeCount),
                width: w,
                height: h / CGFloat(stripeCount)
            )
            let color = i % 2 == 0 ? Color.pitchGrassLight : Color.pitchGrassDark
            context.fill(Path(rect), with: .color(color))
        }
        
        // Outer boundary
        let lineColor = Color.white.opacity(0.7)
        let lineWidth = max(1.5, w * 0.005)
        let inset = w * 0.03
        let field = CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2)
        context.stroke(Path(field), with: .color(lineColor), lineWidth: lineWidth)
        
        // Halfway line
        var halfway = Path()
        halfway.move(to: CGPoint(x: field.minX, y: field.midY))
        halfway.addLine(to: CGPoint(x: field.maxX, y: field.midY))
        context.stroke(halfway, with: .color(lineColor), lineWidth: lineWidth)
        
        // Centre circle
        let circleRadius = field.width * 0.13
        context.stroke(
            Path(ellipseIn: CGRect(
                x: field.midX - circleRadius,
                y: field.midY - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            )),
            with: .color(lineColor),
            lineWidth: lineWidth
        )
        
        // Penalty boxes (top & bottom)
        let boxW = field.width * 0.55
        let boxH = field.height * 0.14
        let topBox = CGRect(x: field.midX - boxW / 2, y: field.minY, width: boxW, height: boxH)
        let bottomBox = CGRect(x: field.midX - boxW / 2, y: field.maxY - boxH, width: boxW, height: boxH)
        context.stroke(Path(topBox), with: .color(lineColor), lineWidth: lineWidth)
        context.stroke(Path(bottomBox), with: .color(lineColor), lineWidth: lineWidth)
        
        // Goal boxes
        let goalW = field.width * 0.28
        let goalH = boxH * 0.42
        let topGoal = CGRect(x: field.midX - goalW / 2, y: field.minY, width: goalW, height: goalH)
        let bottomGoal = CGRect(x: field.midX - goalW / 2, y: field.maxY - goalH, width: goalW, height: goalH)
        context.stroke(Path(topGoal), with: .color(lineColor), lineWidth: lineWidth)
        context.stroke(Path(bottomGoal), with: .color(lineColor), lineWidth: lineWidth)
    }
    
    // MARK: - Player Positioning
    
    /// Returns a normalised (0...1) attacking position for a player index at the given minute.
    /// The shape drifts toward the attacking goal and wobbles deterministically over time.
    private func position(for index: Int, isHome: Bool, minute: Int) -> CGPoint
    {
        // Formation slot layout (x: 0..1 across width, y: 0..1 up the pitch from own goal).
        let homeSlots: [CGPoint] = [
            CGPoint(x: 0.50, y: 0.06), // GK
            CGPoint(x: 0.14, y: 0.24), CGPoint(x: 0.38, y: 0.22), CGPoint(x: 0.62, y: 0.22), CGPoint(x: 0.86, y: 0.24),
            CGPoint(x: 0.16, y: 0.44), CGPoint(x: 0.38, y: 0.46), CGPoint(x: 0.62, y: 0.46), CGPoint(x: 0.84, y: 0.44),
            CGPoint(x: 0.40, y: 0.68), CGPoint(x: 0.60, y: 0.68)
        ]
        let slot = homeSlots[min(index, homeSlots.count - 1)]
        
        // Time-based deterministic wobble so the picture breathes as minutes pass.
        let phase = Double(minute) * 0.35 + Double(index) * 1.7
        let wobbleX = sin(phase) * 0.045
        let wobbleY = cos(phase * 0.8) * 0.035
        
        // A gentle push toward the opponent goal grows through the match.
        let push = min(0.12, Double(minute) / 90.0 * 0.12) * (slot.y > 0.3 ? 1 : 0)
        
        var nx = slot.x + wobbleX
        var ny = slot.y + wobbleY + push
        
        // Flip vertically for the away team (attacking the other way).
        if !isHome {
            ny = 1.0 - ny
            nx = 1.0 - nx
        }
        
        nx = min(0.98, max(0.02, nx))
        ny = min(0.98, max(0.02, ny))
        return CGPoint(x: nx, y: ny)
    }
    
    private func drawPlayers(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let radius = max(4, w * 0.018)
        let homeColor = Color(hex: homeClub.primaryColor)
        let awayColor = Color(hex: awayClub.primaryColor)
        
        for index in 0..<11 {
            let homePos = position(for: index, isHome: true, minute: minute)
            let homeCenter = CGPoint(x: homePos.x * w, y: homePos.y * h)
            let homeRect = CGRect(
                x: homeCenter.x - radius,
                y: homeCenter.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.fill(Path(ellipseIn: homeRect), with: .color(homeColor))
            context.stroke(Path(ellipseIn: homeRect), with: .color(.white.opacity(0.85)), lineWidth: 1.2)
            
            let awayPos = position(for: index, isHome: false, minute: minute)
            let awayCenter = CGPoint(x: awayPos.x * w, y: awayPos.y * h)
            let awayRect = CGRect(
                x: awayCenter.x - radius,
                y: awayCenter.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.fill(Path(ellipseIn: awayRect), with: .color(awayColor))
            context.stroke(Path(ellipseIn: awayRect), with: .color(.black.opacity(0.6)), lineWidth: 1.2)
        }
    }
    
    private func drawBall(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let radius = max(2.5, w * 0.010)
        
        // The ball roams around the middle third, moving deterministically with the clock.
        let phase = Double(minute) * 0.9
        let bx = 0.5 + sin(phase) * 0.28
        let by = 0.5 + cos(phase * 1.3) * 0.33
        let center = CGPoint(x: bx * w, y: by * h)
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        
        context.fill(Path(ellipseIn: rect), with: .color(.white))
        context.stroke(Path(ellipseIn: rect), with: .color(.black.opacity(0.7)), lineWidth: 1)
    }
}

// MARK: - Live Match Screen

public struct LiveMatchView: View {
    @Environment(GameState.self) private var gameState
    
    @State private var minute = 0
    @State private var isPlaying = false
    @State private var didSimulate = false
    @State private var ticker: Timer?
    
    private var fixture: Fixture? { gameState.activeMatchFixture }
    private var result: MatchResult? { fixture?.result }
    
    public var body: some View {
        VStack(spacing: 14) {
            if let fixture = fixture,
               let home = gameState.club(withId: fixture.homeClubId),
               let away = gameState.club(withId: fixture.awayClubId) {
                
                scoreboard(home: home, away: away)
                
                PitchReplayView(
                    fixture: fixture,
                    homeClub: home,
                    awayClub: away,
                    minute: minute
                )
                .padding(.horizontal, 12)
                
                timelineFeed
                
                controls(fixture: fixture)
            } else {
                ContentUnavailableView("No Active Match", systemImage: "sportscourt")
            }
        }
        .padding(.vertical)
        .navigationTitle("Live Match")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: prepare)
        .onDisappear { stopTicker() }
    }
    
    // MARK: - Subviews
    
    private func scoreboard(home: Club, away: Club) -> some View {
        VStack(spacing: 6) {
            Text(fixture?.competition ?? "Match")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                HStack(spacing: 8) {
                    CrestView(club: home, size: 30)
                    Text(home.shortName).font(.headline)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                VStack(spacing: 2) {
                    Text(scoreText)
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(width: 90)
                    Text("\(minute)'")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 8) {
                    Text(away.shortName).font(.headline)
                    CrestView(club: away, size: 30)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(home.name) \(currentHomeGoals), \(away.name) \(currentAwayGoals), minute \(minute)")
    }
    
    private var timelineFeed: some View {
        List {
            let visible = (result?.events ?? []).filter { $0.minute <= minute }
            if visible.isEmpty {
                Text(minute == 0 ? "Kick-off imminent..." : "No key events yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(visible.reversed()) { ev in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Image(systemName: ev.type.icon)
                                .foregroundStyle(.secondary)
                            Text("\(ev.minute)'").fontWeight(.bold)
                            Text(ev.shortText)
                        }
                        .font(.subheadline)
                    }
                    .accessibleMatchEvent(ev)
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func controls(fixture: Fixture) -> some View {
        HStack(spacing: 12) {
            Button {
                isPlaying ? stopTicker() : startTicker()
            } label: {
                Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(minute >= 90)
            .accessibilityLabel(isPlaying ? "Pause replay" : "Play replay")
            
            Button {
                finish(fixture: fixture)
            } label: {
                Label("Full-Time", systemImage: "flag.checkered")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityLabel("Skip to full time")
        }
        .padding(.horizontal)
    }
    
    // MARK: - Logic
    
    private var currentHomeGoals: Int {
        (result?.goalEvents ?? []).filter { $0.minute <= minute && $0.isHomeTeam }.count
    }
    
    private var currentAwayGoals: Int {
        (result?.goalEvents ?? []).filter { $0.minute <= minute && !$0.isHomeTeam }.count
    }
    
    private var scoreText: String {
        "\(currentHomeGoals) - \(currentAwayGoals)"
    }
    
    private func prepare() {
        guard let fixture = fixture else { return }
        // Simulate first (pre-decides the outcome), then replay it minute by minute.
        if !didSimulate {
            if !fixture.isPlayed,
               let idx = gameState.season.fixtures.firstIndex(where: { $0.id == fixture.id }) {
                gameState.applyTeamTalkIfNeeded()
                gameState.simulateMatch(fixture: &gameState.season.fixtures[idx])
            }
            didSimulate = true
        }
        minute = 0
        startTicker()
    }
    
    private func startTicker() {
        guard minute < 90 else { return }
        isPlaying = true
        ticker?.invalidate()
        let interval = gameState.matchSettings.speed.tickInterval
        ticker = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            Task { @MainActor in
                advanceMinute()
                if minute >= 90 {
                    timer.invalidate()
                    isPlaying = false
                } else if gameState.matchSettings.stopAtHalfTime && minute == 45 {
                    timer.invalidate()
                    isPlaying = false
                    AccessibilityNotification.Announcement("Half-time. Paused for substitutions.").post()
                }
            }
        }
    }
    
    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
        isPlaying = false
    }
    
    private func advanceMinute() {
        let previous = minute
        minute = min(90, minute + 1)
        
        // Announce major events as their minute arrives.
        let newEvents = (result?.events ?? []).filter {
            $0.minute > previous && $0.minute <= minute && $0.type.isMajorEvent
        }
        for ev in newEvents {
            AccessibilityNotification.Announcement(ev.detailText).post()
            if ev.type == .goal {
                SoundManager.shared.play(.goal, enabled: gameState.soundEnabled)
            }
        }
    }
    
    private func finish(fixture: Fixture) {
        stopTicker()
        if let idx = gameState.season.fixtures.firstIndex(where: { $0.id == fixture.id }) {
            if !gameState.season.fixtures[idx].isPlayed {
                gameState.simulateMatch(fixture: &gameState.season.fixtures[idx])
            }
            minute = 90
            gameState.finishMatchweekAfterUserMatch()
            gameState.currentScreen = .postMatch
        }
    }
}
