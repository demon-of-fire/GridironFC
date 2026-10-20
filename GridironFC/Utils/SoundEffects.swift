//
//  SoundEffects.swift
//  GridironFC
//
//  Lightweight sound + haptic feedback for key match events. Tones are synthesised
//  in-memory (no bundled audio assets) and played through AVAudioPlayer. Respects
//  GameState.soundEnabled.
//

import Foundation
import AVFoundation
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

    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private let audioQueue = DispatchQueue(label: "com.gridironfc.sound")
    private var audioSessionConfigured = false

    private init() {
        configureAudioSession()
        prepareTones()
    }

    private func configureAudioSession() {
        guard !audioSessionConfigured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            audioSessionConfigured = true
        } catch {
            // Non-fatal: fall back to haptics only.
        }
    }

    /// Synthesises a short tone sequence for each effect and caches the players.
    private func prepareTones() {
        players[.goal] = makePlayer(notes: [(880, 0.10), (1175, 0.10), (1568, 0.22)], waveform: .bright)
        players[.win] = makePlayer(notes: [(523, 0.12), (659, 0.12), (784, 0.12), (1047, 0.28)], waveform: .bright)
        players[.draw] = makePlayer(notes: [(440, 0.18), (440, 0.18)], waveform: .mellow)
        players[.loss] = makePlayer(notes: [(392, 0.18), (311, 0.18), (233, 0.28)], waveform: .mellow)
        players[.whistle] = makePlayer(notes: [(2200, 0.30)], waveform: .whistle)
        players[.click] = makePlayer(notes: [(1200, 0.05)], waveform: .mellow)
    }

    private enum Waveform { case bright, mellow, whistle }

    /// Builds a WAV-backed AVAudioPlayer from a list of (frequency, duration) notes.
    private func makePlayer(notes: [(Double, Double)], waveform: Waveform) -> AVAudioPlayer? {
        let sampleRate = 44100.0
        var samples: [Int16] = []

        for (frequency, duration) in notes {
            let count = Int(sampleRate * duration)
            for i in 0..<count {
                let t = Double(i) / sampleRate
                let envelope = min(1.0, t / 0.01) * min(1.0, (duration - t) / 0.03)
                let value: Double
                switch waveform {
                case .bright:
                    value = sin(2 * .pi * frequency * t) + 0.35 * sin(4 * .pi * frequency * t)
                case .mellow:
                    value = sin(2 * .pi * frequency * t)
                case .whistle:
                    value = sin(2 * .pi * frequency * t) + 0.2 * sin(2 * .pi * frequency * 2 * t)
                }
                let scaled = max(-1.0, min(1.0, value * 0.6)) * envelope
                samples.append(Int16(scaled * 32000))
            }
        }

        let wav = makeWAV(samples: samples, sampleRate: Int(sampleRate))
        do {
            let player = try AVAudioPlayer(data: wav)
            player.prepareToPlay()
            return player
        } catch {
            return nil
        }
    }

    /// Wraps PCM samples in a minimal WAV container.
    private func makeWAV(samples: [Int16], sampleRate: Int) -> Data {
        var data = Data()
        let byteRate = sampleRate * 2
        let dataSize = samples.count * 2

        func append(_ string: String) { data.append(contentsOf: Array(string.utf8)) }
        func append32(_ value: UInt32) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        func append16(_ value: UInt16) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }

        append("RIFF")
        append32(UInt32(36 + dataSize))
        append("WAVE")
        append("fmt ")
        append32(16)              // PCM chunk size
        append16(1)               // PCM format
        append16(1)               // mono
        append32(UInt32(sampleRate))
        append32(UInt32(byteRate))
        append16(2)               // block align
        append16(16)              // bits per sample
        append("data")
        append32(UInt32(dataSize))
        for sample in samples {
            var v = sample.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }
        return data
    }

    public func play(_ effect: SoundEffect, enabled: Bool) {
        guard enabled else { return }
        configureAudioSession()
        if let player = players[effect] {
            player.currentTime = 0
            player.play()
        }
        // Haptics as a complement (not a replacement).
        switch effect {
        case .goal, .win:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .loss:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .whistle, .click, .draw:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    public func playWin(enabled: Bool) { play(.win, enabled: enabled) }
    public func playGoal(enabled: Bool) { play(.goal, enabled: enabled) }
    public func playWhistle(enabled: Bool) { play(.whistle, enabled: enabled) }
    public func playClick(enabled: Bool) { play(.click, enabled: enabled) }
}
