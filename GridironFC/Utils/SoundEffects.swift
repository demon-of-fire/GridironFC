//
//  SoundEffects.swift
//  GridironFC
//
//  Lightweight sound + haptic feedback for key match events. Uses system audio
//  services (no bundled audio required). Respects GameState.soundEnabled.
//

import Foundation
import AudioToolbox
import UIKit

public enum SoundEffect {
    case goal
    case win
    case draw
    case loss
    case whistle
    case click
}

public final class SoundManager {
    public static let shared = SoundManager()

    private init() {}

    public func play(_ effect: SoundEffect, enabled: Bool) {
        guard enabled else { return }
        let soundID: SystemSoundID
        switch effect {
        case .goal:
            soundID = 1025 // Tock
        case .win:
            soundID = 1025
        case .draw:
            soundID = 1104
        case .loss:
            soundID = 1053
        case .whistle:
            soundID = 1114
        case .click:
            soundID = 1105
        }
        AudioServicesPlaySystemSound(soundID)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    public func playWin(enabled: Bool) { play(.win, enabled: enabled) }
    public func playGoal(enabled: Bool) { play(.goal, enabled: enabled) }
    public func playWhistle(enabled: Bool) { play(.whistle, enabled: enabled) }
    public func playClick(enabled: Bool) { play(.click, enabled: enabled) }
}
