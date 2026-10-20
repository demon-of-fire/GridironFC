//
//  CrestView.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Procedural, fully deterministic club crest renderer. No real club badges or
//  trademarked imagery are used; each crest is derived from the club's short name
//  and kit colours so identical inputs always produce an identical badge.
//

import SwiftUI

// MARK: - Crest Style

/// Deterministic badge shape chosen from a club's identity hash.
public enum CrestShape: String, CaseIterable, Hashable {
    case shield
    case roundedShield
    case circle
    case diamond
    case chevron
    case hexagon
}

// MARK: - Crest Geometry

/// Builds the outline path for a crest shape inside the supplied rectangle.
/// The returned path is unit-agnostic so it can be scaled by the caller.
struct CrestShapeGeometry {
    static func path(for shape: CrestShape, in rect: CGRect) -> Path {
        switch shape {
        case .shield:
            return shieldPath(in: rect, pointed: false)
        case .roundedShield:
            return shieldPath(in: rect, pointed: true)
        case .circle:
            return Path(ellipseIn: rect.insetBy(dx: rect.width * 0.05, dy: rect.width * 0.05))
        case .diamond:
            return diamondPath(in: rect)
        case .chevron:
            return chevronPath(in: rect)
        case .hexagon:
            return hexagonPath(in: rect)
        }
    }
    
    private static func shieldPath(in rect: CGRect, pointed: Bool) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY
        
        let topCurve = h * 0.10
        let shoulder = h * 0.62
        let tipY = pointed ? y + h : y + h * 0.94
        
        path.move(to: CGPoint(x: x, y: y + topCurve))
        path.addQuadCurve(
            to: CGPoint(x: x + w * 0.5, y: y),
            control: CGPoint(x: x + w * 0.18, y: y)
        )
        path.addQuadCurve(
            to: CGPoint(x: x + w, y: y + topCurve),
            control: CGPoint(x: x + w * 0.82, y: y)
        )
        path.addLine(to: CGPoint(x: x + w, y: shoulder))
        path.addQuadCurve(
            to: CGPoint(x: x + w * 0.5, y: tipY),
            control: CGPoint(x: x + w, y: tipY - h * 0.10)
        )
        path.addQuadCurve(
            to: CGPoint(x: x, y: shoulder),
            control: CGPoint(x: x, y: tipY - h * 0.10)
        )
        path.closeSubpath()
        return path
    }
    
    private static func diamondPath(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        path.move(to: CGPoint(x: cx, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: cy))
        path.addLine(to: CGPoint(x: cx, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: cy))
        path.closeSubpath()
        return path
    }
    
    private static func chevronPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY
        path.move(to: CGPoint(x: x, y: y + h * 0.15))
        path.addLine(to: CGPoint(x: x + w * 0.5, y: y))
        path.addLine(to: CGPoint(x: x + w, y: y + h * 0.15))
        path.addLine(to: CGPoint(x: x + w, y: y + h * 0.75))
        path.addLine(to: CGPoint(x: x + w * 0.5, y: y + h))
        path.addLine(to: CGPoint(x: x, y: y + h * 0.75))
        path.closeSubpath()
        return path
    }
    
    private static func hexagonPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY
        let points: [CGPoint] = [
            CGPoint(x: x + w * 0.5, y: y),
            CGPoint(x: x + w, y: y + h * 0.25),
            CGPoint(x: x + w, y: y + h * 0.75),
            CGPoint(x: x + w * 0.5, y: y + h),
            CGPoint(x: x, y: y + h * 0.75),
            CGPoint(x: x, y: y + h * 0.25)
        ]
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Crest Identity

/// Deterministic visual identity derived from a club's short name and colours.
public struct CrestIdentity {
    public let shape: CrestShape
    public let pattern: Int          // 0 none, 1 horizontal band, 2 vertical stripe, 3 diagonal
    public let monogramFontSizeRatio: Double
    public let hasRing: Bool
    
    public init(seedKey: String) {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in seedKey.uppercased().utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        let shapes = CrestShape.allCases
        self.shape = shapes[Int(hash % UInt64(shapes.count))]
        self.pattern = Int((hash / 7) % 4)
        self.monogramFontSizeRatio = 0.42 + Double((hash / 13) % 4) * 0.02
        self.hasRing = (hash / 17) % 2 == 0
    }
}

// MARK: - Crest View

/// Renders a procedurally generated club badge from colours and short name.
public struct CrestView: View {
    public let shortName: String
    public let primaryColor: Color
    public let secondaryColor: Color
    public var size: CGFloat
    
    private var identity: CrestIdentity {
        CrestIdentity(seedKey: shortName)
    }
    
    public init(
        shortName: String,
        primaryColor: Color,
        secondaryColor: Color,
        size: CGFloat = 48
    ) {
        self.shortName = shortName
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.size = size
    }
    
    /// Convenience initialiser building the crest directly from a `Club`.
    public init(club: Club, size: CGFloat = 48) {
        self.shortName = club.shortName
        self.primaryColor = Color(hex: club.primaryColor)
        self.secondaryColor = Color(hex: club.secondaryColor)
        self.size = size
    }
    
    public var body: some View {
        let ident = identity
        ZStack {
            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)
                let path = CrestShapeGeometry.path(for: ident.shape, in: rect)
                
                // Base fill
                path.fill(primaryColor)
                
                // Pattern overlay clipped to the crest outline
                if ident.pattern != 0 {
                    patternPath(for: ident, in: rect)
                        .fill(secondaryColor.opacity(0.9))
                        .clipShape(path)
                }
                
                // Outline
                path.stroke(secondaryColor, lineWidth: max(1.5, size * 0.05))
                
                if ident.hasRing {
                    let inset = rect.insetBy(dx: rect.width * 0.10, dy: rect.height * 0.10)
                    CrestShapeGeometry.path(for: ident.shape, in: inset)
                        .stroke(secondaryColor.opacity(0.7), lineWidth: max(1, size * 0.025))
                }
            }
            .frame(width: size, height: size)
            
            // Monogram
            Text(monogram)
                .font(.system(size: size * identity.monogramFontSizeRatio, weight: .black, design: .rounded))
                .foregroundStyle(secondaryColor)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .shadow(color: primaryColor.opacity(0.6), radius: 1, x: 0, y: 1)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(shortName) crest")
    }
    
    private var monogram: String {
        let letters = shortName.uppercased().filter { $0.isLetter || $0.isNumber }
        let trimmed = String(letters.prefix(3))
        return trimmed.isEmpty ? "FC" : trimmed
    }
    
    private func patternPath(for identity: CrestIdentity, in rect: CGRect) -> Path {
        var path = Path()
        switch identity.pattern {
        case 1: // Horizontal band
            let bandHeight = rect.height * 0.22
            path.addRect(CGRect(
                x: rect.minX,
                y: rect.midY - bandHeight / 2,
                width: rect.width,
                height: bandHeight
            ))
        case 2: // Vertical stripe
            let stripeWidth = rect.width * 0.24
            path.addRect(CGRect(
                x: rect.midX - stripeWidth / 2,
                y: rect.minY,
                width: stripeWidth,
                height: rect.height
            ))
        case 3: // Diagonal sash
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.18))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY * 0.82))
            path.closeSubpath()
        default:
            break
        }
        return path
    }
}

// MARK: - Preview

#Preview("Crests") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
            ForEach(["ARS", "MUN", "LIV", "MCI", "CHE", "TOT", "NEW", "AVL"], id: \.self) { code in
                VStack {
                    CrestView(
                        shortName: code,
                        primaryColor: .pitchGreen,
                        secondaryColor: .goldAccent,
                        size: 64
                    )
                    Text(code).font(.caption)
                }
            }
        }
        .padding()
    }
}
