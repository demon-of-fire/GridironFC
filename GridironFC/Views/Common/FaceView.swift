//
//  FaceView.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Procedural, deterministic player portrait renderer. Faces are stylised geometric
//  avatars generated from a player's stable face seed; they are NOT likenesses of any
//  real person and carry no photographic data.
//

import SwiftUI

// MARK: - Deterministic Random Source

/// Lightweight deterministic RNG (SplitMix64) so a given seed always yields the same face.
private struct SeededRandom {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }
    
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    
    /// Uniform double in 0..<1.
    mutating func unit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
    
    /// Uniform double in the supplied closed range.
    mutating func range(_ lower: Double, _ upper: Double) -> Double {
        lower + unit() * (upper - lower)
    }
    
    /// Uniform integer in 0..<upperBound.
    mutating func int(_ upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }
    
    /// True with the supplied probability.
    mutating func chance(_ probability: Double) -> Bool {
        unit() < probability
    }
}

// MARK: - Face Traits

/// All cosmetic parameters that make up a single procedural face.
private struct FaceTraits {
    var skinTone: Color
    var hairColor: Color
    var hairStyle: Int          // 0 short, 1 buzz, 2 curly, 3 long, 4 bald, 5 mohawk
    var beardStyle: Int         // 0 none, 1 stubble, 2 full, 3 goatee, 4 moustache
    var eyeColor: Color
    var browThickness: Double
    var noseWidth: Double
    var mouthWidth: Double
    var headWidth: Double
    var headHeight: Double
    var hasEarring: Bool
    var eyeSpacing: Double
    
    static func derive(from seed: UInt64) -> FaceTraits {
        var rng = SeededRandom(seed: seed)
        
        // Skin tones spanning a realistic range.
        let skins: [Color] = [
            Color(hex: "F8D9B8"), Color(hex: "F1C9A5"), Color(hex: "E8BC93"),
            Color(hex: "D8A87A"), Color(hex: "C68D5E"), Color(hex: "AE7248"),
            Color(hex: "8D5A34"), Color(hex: "6B4226"), Color(hex: "4E2F1A")
        ]
        // Hair colours.
        let hairs: [Color] = [
            Color(hex: "1A1A1A"), Color(hex: "2E1E12"), Color(hex: "4A2F1A"),
            Color(hex: "6B4A2B"), Color(hex: "8B6914"), Color(hex: "C0A060"),
            Color(hex: "D9D0C0"), Color(hex: "3A3A3A"), Color(hex: "A0522D")
        ]
        // Eye colours.
        let eyes: [Color] = [
            Color(hex: "5B3A1E"), Color(hex: "3B2A1A"), Color(hex: "2E4A2E"),
            Color(hex: "3A5F8A"), Color(hex: "4A6A8A"), Color(hex: "2A2A2A")
        ]
        
        return FaceTraits(
            skinTone: skins[rng.int(skins.count)],
            hairColor: hairs[rng.int(hairs.count)],
            hairStyle: rng.int(6),
            beardStyle: rng.int(5),
            eyeColor: eyes[rng.int(eyes.count)],
            browThickness: rng.range(0.5, 1.0),
            noseWidth: rng.range(0.6, 1.0),
            mouthWidth: rng.range(0.6, 1.0),
            headWidth: rng.range(0.88, 1.0),
            headHeight: rng.range(0.92, 1.08),
            hasEarring: rng.chance(0.15),
            eyeSpacing: rng.range(0.62, 0.84)
        )
    }
}

// MARK: - Face View

/// Renders a deterministic stylised portrait for a player.
public struct FaceView: View {
    public let seed: UInt64
    public var size: CGFloat
    public var style: FaceStyle
    
    public enum FaceStyle {
        case full       // Includes neck/shoulders
        case avatar     // Head only, clipped to a circle
    }
    
    public init(seed: UInt64, size: CGFloat = 44, style: FaceStyle = .avatar) {
        self.seed = seed
        self.size = size
        self.style = style
    }
    
    /// Convenience initialiser building the portrait directly from a `Player`.
    public init(player: Player, size: CGFloat = 44, style: FaceStyle = .avatar) {
        self.seed = player.faceSeed
        self.size = size
        self.style = style
    }
    
    public var body: some View {
        let traits = FaceTraits.derive(from: seed)
        ZStack {
            if style == .avatar {
                Circle().fill(backgroundColor(for: traits))
            } else {
                backgroundColor(for: traits)
            }
            
            Canvas { context, canvasSize in
                drawFace(in: &context, size: canvasSize, traits: traits)
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .clipShape(style == .avatar ? FaceClipShape(Circle()) : FaceClipShape(RoundedRectangle(cornerRadius: size * 0.12)))
        .overlay(
            (style == .avatar ? FaceClipShape(Circle()) : FaceClipShape(RoundedRectangle(cornerRadius: size * 0.12)))
                .stroke(Color.black.opacity(0.15), lineWidth: 1)
        )
        .accessibilityHidden(true)
    }
    
    private func backgroundColor(for traits: FaceTraits) -> Color {
        traits.skinTone.opacity(0.18)
    }
    
    // MARK: - Drawing
    
    private func drawFace(in context: inout GraphicsContext, size: CGSize, traits: FaceTraits) {
        let w = size.width
        let h = size.height
        let cx = w / 2
        let cy = h * 0.52
        let headW = w * 0.52 * traits.headWidth
        let headH = h * 0.60 * traits.headHeight
        
        // Shoulders / neck (full style)
        if style == .full {
            let shoulder = Path { p in
                p.addArc(
                    center: CGPoint(x: cx, y: h * 1.05),
                    radius: w * 0.55,
                    startAngle: .degrees(200),
                    endAngle: .degrees(340),
                    clockwise: false
                )
                p.closeSubpath()
            }
            context.fill(shoulder, with: .color(Color(hex: "2C3E50")))
        }
        
        // Neck
        let neckRect = CGRect(
            x: cx - headW * 0.22,
            y: cy + headH * 0.30,
            width: headW * 0.44,
            height: headH * 0.42
        )
        context.fill(
            Path(roundedRect: neckRect, cornerRadius: headW * 0.18),
            with: .color(traits.skinTone)
        )
        
        // Hair back (behind head)
        if traits.hairStyle == 3 {
            let hairBack = CGRect(
                x: cx - headW * 0.62,
                y: cy - headH * 0.62,
                width: headW * 1.24,
                height: headH * 1.30
            )
            context.fill(
                Path(ellipseIn: hairBack),
                with: .color(traits.hairColor)
            )
        }
        
        // Head
        let headRect = CGRect(
            x: cx - headW / 2,
            y: cy - headH / 2,
            width: headW,
            height: headH
        )
        context.fill(Path(ellipseIn: headRect), with: .color(traits.skinTone))
        
        // Ears
        let earSize = headW * 0.16
        let earY = cy + headH * 0.02
        context.fill(
            Path(ellipseIn: CGRect(x: headRect.minX - earSize * 0.5, y: earY, width: earSize, height: earSize * 1.3)),
            with: .color(traits.skinTone)
        )
        context.fill(
            Path(ellipseIn: CGRect(x: headRect.maxX - earSize * 0.5, y: earY, width: earSize, height: earSize * 1.3)),
            with: .color(traits.skinTone)
        )
        
        if traits.hasEarring {
            let ringSize = earSize * 0.4
            context.stroke(
                Path(ellipseIn: CGRect(x: headRect.minX - ringSize, y: earY + earSize * 1.1, width: ringSize, height: ringSize)),
                with: .color(.yellow),
                lineWidth: max(1, w * 0.012)
            )
        }
        
        // Hair front
        drawHair(in: &context, headRect: headRect, cx: cx, traits: traits)
        
        // Eyebrows
        let eyeY = cy - headH * 0.06
        let eyeDX = headW * traits.eyeSpacing / 2
        let browWidth = headW * 0.20
        let browThickness = max(1, h * 0.012 * traits.browThickness)
        for sign in [-1.0, 1.0] {
            let bx = cx + CGFloat(sign) * eyeDX
            var brow = Path()
            brow.move(to: CGPoint(x: bx - browWidth / 2, y: eyeY - headH * 0.10))
            brow.addLine(to: CGPoint(x: bx + browWidth / 2, y: eyeY - headH * 0.11))
            context.stroke(brow, with: .color(traits.hairColor), lineWidth: browThickness)
        }
        
        // Eyes
        let eyeW = headW * 0.13
        let eyeH = headH * 0.075
        for sign in [-1.0, 1.0] {
            let ex = cx + CGFloat(sign) * eyeDX
            let eyeRect = CGRect(x: ex - eyeW / 2, y: eyeY - eyeH / 2, width: eyeW, height: eyeH)
            context.fill(Path(ellipseIn: eyeRect), with: .color(.white))
            let pupilRect = CGRect(
                x: ex - eyeW * 0.28,
                y: eyeY - eyeH * 0.30,
                width: eyeW * 0.56,
                height: eyeH * 0.60
            )
            context.fill(Path(ellipseIn: pupilRect), with: .color(traits.eyeColor))
        }
        
        // Nose
        let noseW = headW * 0.12 * traits.noseWidth
        var nose = Path()
        nose.move(to: CGPoint(x: cx, y: cy - headH * 0.02))
        nose.addLine(to: CGPoint(x: cx - noseW / 2, y: cy + headH * 0.12))
        nose.addQuadCurve(
            to: CGPoint(x: cx + noseW / 2, y: cy + headH * 0.12),
            control: CGPoint(x: cx, y: cy + headH * 0.18)
        )
        context.stroke(
            nose,
            with: .color(traits.skinTone.opacity(0.55)),
            style: StrokeStyle(lineWidth: max(1, w * 0.012), lineCap: .round)
        )
        
        // Mouth
        let mouthW = headW * 0.26 * traits.mouthWidth
        let mouthY = cy + headH * 0.24
        var mouth = Path()
        mouth.move(to: CGPoint(x: cx - mouthW / 2, y: mouthY))
        mouth.addQuadCurve(
            to: CGPoint(x: cx + mouthW / 2, y: mouthY),
            control: CGPoint(x: cx, y: mouthY + headH * 0.06)
        )
        context.stroke(
            mouth,
            with: .color(Color(hex: "8B3A3A")),
            style: StrokeStyle(lineWidth: max(1, w * 0.014), lineCap: .round)
        )
        
        // Facial hair
        drawBeard(in: &context, headRect: headRect, cx: cx, mouthY: mouthY, traits: traits)
    }
    
    private func drawHair(in context: inout GraphicsContext, headRect: CGRect, cx: CGFloat, traits: FaceTraits) {
        let headW = headRect.width
        let headH = headRect.height
        let topY = headRect.minY
        
        switch traits.hairStyle {
        case 0: // Short
            let capRect = CGRect(
                x: headRect.minX,
                y: topY - headH * 0.02,
                width: headW,
                height: headH * 0.42
            )
            var cap = Path(ellipseIn: capRect)
            cap.addRect(CGRect(x: headRect.minX, y: capRect.midY, width: headW, height: headH * 0.5))
            context.fill(cap, with: .color(traits.hairColor))
        case 1: // Buzz
            let capRect = CGRect(x: headRect.minX, y: topY, width: headW, height: headH * 0.30)
            context.fill(Path(ellipseIn: capRect), with: .color(traits.hairColor.opacity(0.85)))
        case 2: // Curly
            let capRect = CGRect(x: headRect.minX, y: topY - headH * 0.05, width: headW, height: headH * 0.38)
            var cap = Path(ellipseIn: capRect)
            cap.addRect(CGRect(x: headRect.minX, y: capRect.midY, width: headW, height: headH * 0.4))
            context.fill(cap, with: .color(traits.hairColor))
            for i in 0..<6 {
                let px = headRect.minX + headW * (CGFloat(i) + 0.5) / 6
                let puff = CGRect(x: px - headW * 0.10, y: topY - headH * 0.08, width: headW * 0.20, height: headH * 0.20)
                context.fill(Path(ellipseIn: puff), with: .color(traits.hairColor))
            }
        case 3: // Long (drawn behind, plus fringe here)
            let fringe = CGRect(x: headRect.minX, y: topY, width: headW, height: headH * 0.28)
            context.fill(Path(ellipseIn: fringe), with: .color(traits.hairColor))
        case 4: // Bald
            break
        case 5: // Mohawk
            let stripW = headW * 0.22
            let stripRect = CGRect(x: cx - stripW / 2, y: topY - headH * 0.14, width: stripW, height: headH * 0.34)
            var strip = Path(ellipseIn: stripRect)
            strip.addRect(CGRect(x: cx - stripW / 2, y: stripRect.midY, width: stripW, height: headH * 0.2))
            context.fill(strip, with: .color(traits.hairColor))
        default:
            break
        }
    }
    
    private func drawBeard(in context: inout GraphicsContext, headRect: CGRect, cx: CGFloat, mouthY: CGFloat, traits: FaceTraits) {
        let headW = headRect.width
        let headH = headRect.height
        let beardColor = traits.hairColor
        
        switch traits.beardStyle {
        case 1: // Stubble
            let jaw = CGRect(
                x: headRect.minX + headW * 0.06,
                y: mouthY - headH * 0.06,
                width: headW * 0.88,
                height: headH * 0.34
            )
            context.fill(Path(ellipseIn: jaw), with: .color(beardColor.opacity(0.28)))
        case 2: // Full
            let beard = CGRect(
                x: headRect.minX - headW * 0.02,
                y: mouthY - headH * 0.04,
                width: headW * 1.04,
                height: headH * 0.42
            )
            context.fill(Path(ellipseIn: beard), with: .color(beardColor.opacity(0.92)))
        case 3: // Goatee
            let goatee = CGRect(
                x: cx - headW * 0.14,
                y: mouthY,
                width: headW * 0.28,
                height: headH * 0.26
            )
            context.fill(Path(ellipseIn: goatee), with: .color(beardColor))
        case 4: // Moustache
            let mo = CGRect(
                x: cx - headW * 0.20,
                y: mouthY - headH * 0.09,
                width: headW * 0.40,
                height: headH * 0.09
            )
            context.fill(Path(ellipseIn: mo), with: .color(beardColor))
        default:
            break
        }
    }
}

// MARK: - FaceClipShape Helper

/// Type-erased shape allowing dynamic switching between clip shapes.
private struct FaceClipShape: Shape {
    private let pathBuilder: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        self.pathBuilder = { rect in shape.path(in: rect) }
    }
    
    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}

// MARK: - Preview

#Preview("Faces") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
            ForEach(0..<24, id: \.self) { index in
                VStack(spacing: 6) {
                    FaceView(seed: UInt64(index) &* 0x9E3779B97F4A7C15, size: 56)
                    FaceView(seed: UInt64(index) &* 0x9E3779B97F4A7C15, size: 56, style: .full)
                        .frame(height: 56)
                }
            }
        }
        .padding()
    }
}
