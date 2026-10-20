//
//  InjuryEngine.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Simulates match injury risk rolls, physiological fatigue, workload accumulation,
//  and weekly physio-assisted rehabilitation.
//

import Foundation

public struct InjuryEngine {
    
    // MARK: - In-Match Injury Assessment
    
    /// Evaluates probability of a matchday injury based on player fitness, age, fatigue, and tactical intensity.
    public static func checkForInjury(
        player: Player,
        matchMinute: Int,
        intensity: Double = 1.0
    ) -> Injury? {
        // Base injury chance per event opportunity (~0.4% per check)
        var baseProbability = 0.004
        
        // 1. Match fitness factor (fatigued players run much higher injury risk)
        if player.matchFitness < 50.0 {
            baseProbability *= 3.5
        } else if player.matchFitness < 70.0 {
            baseProbability *= 2.2
        } else if player.matchFitness < 85.0 {
            baseProbability *= 1.3
        }
        
        // 2. Age factor: older bodies are more susceptible to muscle strains
        if player.age >= 34 {
            baseProbability *= 2.0
        } else if player.age >= 30 {
            baseProbability *= 1.4
        }
        
        // 3. Low stamina modifier (exhausted players lose physical stability)
        let staminaDampener = max(0.6, Double(player.attributes.stamina) / 100.0)
        baseProbability /= staminaDampener
        
        // 4. Minute fatigue multiplier (injuries spike in the final 20 minutes)
        if matchMinute > 75 {
            baseProbability *= 1.6
        } else if matchMinute > 60 {
            baseProbability *= 1.25
        }
        
        // 5. Tactical pressing intensity multiplier
        baseProbability *= intensity
        
        // Roll for injury
        let roll = Double.random(in: 0.0...1.0)
        guard roll < baseProbability else { return nil }
        
        // Determine injury type based on weighted distribution
        let typeRoll = Double.random(in: 0.0...100.0)
        let injuryType: InjuryType
        
        switch typeRoll {
        case 0..<40:
            injuryType = .minorKnock
        case 40..<68:
            injuryType = .muscleStrain
        case 68..<85:
            injuryType = .hamstring
        case 85..<93:
            injuryType = .ankleLigament
        case 93..<97:
            injuryType = .brokenBone
        case 97..<99:
            injuryType = .kneeInjury
        default:
            injuryType = .aclTear
        }
        
        // Pick weeks from the injury's recovery range
        let range = injuryType.recoveryWeeksRange
        let weeks = Int.random(in: range.lowerBound...range.upperBound)
        
        return Injury(type: injuryType, weeksRemaining: max(1, weeks))
    }
    
    // MARK: - Pre-Match Injury Risk Calculator
    
    /// Returns calculated percentage risk (0.0% to 100.0%) for squad management display.
    public static func calculateInjuryRisk(
        player: Player,
        pressing: PressingIntensity
    ) -> Double {
        var risk = 2.0
        
        if player.matchFitness < 60 {
            risk += 25.0
        } else if player.matchFitness < 75 {
            risk += 14.0
        } else if player.matchFitness < 90 {
            risk += 5.0
        }
        
        if player.age > 32 {
            risk += Double(player.age - 32) * 3.0
        }
        
        if player.attributes.stamina < 60 {
            risk += Double(60 - player.attributes.stamina) * 0.3
        }
        
        switch pressing {
        case .high: risk *= 1.35
        case .medium: risk *= 1.00
        case .low: risk *= 0.80
        }
        
        return min(95.0, max(1.0, risk))
    }
    
    // MARK: - Weekly Rehabilitation
    
    /// Decrements injury timers across all squad members and leverages club physio quality.
    public static func processWeeklyRecovery(
        players: inout [Player],
        physioQuality: Int = 3
    ) {
        for idx in 0..<players.count {
            guard let currentInjury = players[idx].injury else {
                // Uninjured players regenerate match fitness naturally
                let staminaBoost = Double(players[idx].attributes.stamina) * 0.18
                players[idx].recoverFitness(amount: 25.0 + staminaBoost)
                continue
            }
            
            // Physio quality bonus: high quality physios (4-5 stars) occasionally accelerate recovery
            var weeksToDeduct = 1
            if physioQuality >= 4 && currentInjury.weeksRemaining > 2 {
                let physioHealRoll = Double.random(in: 0.0...1.0)
                let chance = physioQuality == 5 ? 0.35 : 0.20
                if physioHealRoll < chance {
                    weeksToDeduct = 2
                }
            }
            
            let updatedWeeks = currentInjury.weeksRemaining - weeksToDeduct
            if updatedWeeks <= 0 {
                // Player has recovered
                players[idx].injury = nil
                // Recovered players return with basic fitness ready to build sharpness
                players[idx].matchFitness = 65.0 + Double(physioQuality * 3)
            } else {
                players[idx].injury = Injury(type: currentInjury.type, weeksRemaining: updatedWeeks)
            }
        }
    }
}
