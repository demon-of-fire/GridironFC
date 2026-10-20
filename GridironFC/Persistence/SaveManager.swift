//
//  SaveManager.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Persistence controller managing Codable JSON serialization to the app's
//  Documents directory, supporting multiple manual slots and automatic saving.
//

import Foundation

// MARK: - Save Slot Identifier

public enum SaveSlot: String, CaseIterable, Identifiable, Codable {
    case slot1 = "save_slot_1.json"
    case slot2 = "save_slot_2.json"
    case slot3 = "save_slot_3.json"
    case autoSave = "autosave.json"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .slot1: return "Slot 1"
        case .slot2: return "Slot 2"
        case .slot3: return "Slot 3"
        case .autoSave: return "Autosave"
        }
    }
}

// MARK: - Save Slot Metadata Header

public struct SaveSlotMetadata: Codable, Hashable {
    public let slot: SaveSlot
    public let clubName: String
    public let managerName: String
    public let seasonYear: String
    public let inGameDate: String
    public let savedAt: Date
    public let gameMode: GameMode
    
    public init(
        slot: SaveSlot,
        clubName: String,
        managerName: String,
        seasonYear: String,
        inGameDate: String,
        savedAt: Date = Date(),
        gameMode: GameMode
    ) {
        self.slot = slot
        self.clubName = clubName
        self.managerName = managerName
        self.seasonYear = seasonYear
        self.inGameDate = inGameDate
        self.savedAt = savedAt
        self.gameMode = gameMode
    }
    
    public var formattedRealDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: savedAt)
    }
}

// MARK: - Save Envelope

private struct SaveEnvelope: Codable {
    let metadata: SaveSlotMetadata
    let state: GameState
}

// MARK: - Save Manager Errors

public enum SaveManagerError: LocalizedError {
    case documentDirectoryUnavailable
    case fileNotFound(SaveSlot)
    case decodingFailed(String)
    case encodingFailed(String)
    case writeFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .documentDirectoryUnavailable:
            return "Unable to access the application documents directory."
        case .fileNotFound(let slot):
            return "No saved career found for \(slot.displayName)."
        case .decodingFailed(let reason):
            return "Failed to parse save file data: \(reason)"
        case .encodingFailed(let reason):
            return "Failed to serialize save state: \(reason)"
        case .writeFailed(let reason):
            return "Failed to write save file to disk: \(reason)"
        }
    }
}

// MARK: - Save Manager

public final class SaveManager {
    
    public static let shared = SaveManager()
    
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    public init() {
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted]
        self.encoder.dateEncodingStrategy = .iso8601
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - File URL Helpers
    
    private func documentsDirectory() throws -> URL {
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw SaveManagerError.documentDirectoryUnavailable
        }
        return url
    }
    
    public func fileURL(for slot: SaveSlot) throws -> URL {
        return try documentsDirectory().appendingPathComponent(slot.rawValue)
    }
    
    // MARK: - Save Operations
    
    /// Persists current GameState to a designated manual or autosave slot.
    public func save(gameState: GameState, to slot: SaveSlot) throws {
        let metadata = SaveSlotMetadata(
            slot: slot,
            clubName: gameState.userClub?.name ?? "Created Club",
            managerName: gameState.userClub?.manager ?? "Manager",
            seasonYear: gameState.season.year,
            inGameDate: gameState.season.currentDate,
            savedAt: Date(),
            gameMode: gameState.gameMode
        )
        
        let envelope = SaveEnvelope(metadata: metadata, state: gameState)
        
        let data: Data
        do {
            data = try encoder.encode(envelope)
        } catch {
            throw SaveManagerError.encodingFailed(error.localizedDescription)
        }
        
        let targetUrl = try fileURL(for: slot)
        do {
            try data.write(to: targetUrl, options: [.atomicWrite, .completeFileProtection])
        } catch {
            throw SaveManagerError.writeFailed(error.localizedDescription)
        }
    }
    
    /// Shortcut to trigger an autosave.
    public func autoSave(gameState: GameState) throws {
        try save(gameState: gameState, to: .autoSave)
    }
    
    // MARK: - Load Operations
    
    /// Loads the GameState stored in the designated save slot.
    public func load(from slot: SaveSlot) throws -> GameState {
        let targetUrl = try fileURL(for: slot)
        guard fileManager.fileExists(atPath: targetUrl.path) else {
            throw SaveManagerError.fileNotFound(slot)
        }
        
        let data = try Data(contentsOf: targetUrl)
        do {
            let envelope = try decoder.decode(SaveEnvelope.self, from: data)
            return envelope.state
        } catch {
            throw SaveManagerError.decodingFailed(error.localizedDescription)
        }
    }
    
    public func loadAutoSave() throws -> GameState {
        return try load(from: .autoSave)
    }
    
    // MARK: - Metadata & Inspection
    
    /// Reads only the save metadata header without retaining the full world state.
    public func getMetadata(for slot: SaveSlot) -> SaveSlotMetadata? {
        guard let targetUrl = try? fileURL(for: slot),
              fileManager.fileExists(atPath: targetUrl.path),
              let data = try? Data(contentsOf: targetUrl) else {
            return nil
        }
        
        struct HeaderOnly: Codable {
            let metadata: SaveSlotMetadata
        }
        
        let header = try? decoder.decode(HeaderOnly.self, from: data)
        return header?.metadata
    }
    
    public func doesSaveExist(for slot: SaveSlot) -> Bool {
        guard let url = try? fileURL(for: slot) else { return false }
        return fileManager.fileExists(atPath: url.path)
    }
    
    public func deleteSave(for slot: SaveSlot) throws {
        let url = try fileURL(for: slot)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
}
