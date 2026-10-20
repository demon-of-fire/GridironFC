//
//  MatchSettings.swift
//  GridironFC
//
//  User preferences controlling how live matches are played back and how the
//  team is automatically managed during a match.
//

import Foundation

public struct MatchSettings: Codable, Hashable {

    /// Playback speed of the live match replay.
    public enum Speed: String, Codable, CaseIterable, Identifiable, Hashable {
        case slow = "Slow"
        case normal = "Normal"
        case fast = "Fast"
        case veryFast = "Very Fast"

        public var id: String { rawValue }

        /// Seconds between displayed minutes during replay.
        public var tickInterval: Double {
            switch self {
            case .slow: return 0.7
            case .normal: return 0.35
            case .fast: return 0.18
            case .veryFast: return 0.08
            }
        }

        public var displayName: String { rawValue }
    }

    /// When automatic substitutions should occur.
    public enum AutoSubTiming: String, Codable, CaseIterable, Identifiable, Hashable {
        case off = "Off"
        case halfTime = "At Half-Time"
        case secondHalf = "In the Second Half"
        case throughout = "Throughout"

        public var id: String { rawValue }
        public var displayName: String { rawValue }
    }

    /// How aggressively the assistant manager rotates players.
    public enum AutoSubAggression: String, Codable, CaseIterable, Identifiable, Hashable {
        case conservative = "Conservative"
        case balanced = "Balanced"
        case aggressive = "Aggressive"

        public var id: String { rawValue }
        public var displayName: String { rawValue }

        /// Fatigue percentage above which a tired player is replaced.
        public var fatigueThreshold: Double {
            switch self {
            case .conservative: return 78
            case .balanced: return 68
            case .aggressive: return 58
            }
        }

        /// Maximum substitutions the assistant will make.
        public var maxSubs: Int {
            switch self {
            case .conservative: return 3
            case .balanced: return 5
            case .aggressive: return 5
            }
        }
    }

    /// Playback speed for replaying a live match.
    public var speed: Speed
    /// Pause the replay at half-time to let the manager make changes.
    public var stopAtHalfTime: Bool
    /// When the assistant manager makes automatic substitutions.
    public var autoSubTiming: AutoSubTiming
    /// How aggressively the assistant rotates players.
    public var autoSubAggression: AutoSubAggression

    public init(
        speed: Speed = .normal,
        stopAtHalfTime: Bool = true,
        autoSubTiming: AutoSubTiming = .secondHalf,
        autoSubAggression: AutoSubAggression = .balanced
    ) {
        self.speed = speed
        self.stopAtHalfTime = stopAtHalfTime
        self.autoSubTiming = autoSubTiming
        self.autoSubAggression = autoSubAggression
    }
}
