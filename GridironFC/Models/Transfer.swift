//
//  Transfer.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Transfer negotiation offers, personal terms agreements, and completed transaction records.
//

import Foundation

// MARK: - Transfer Offer

public struct TransferOffer: Codable, Identifiable, Hashable {
    public let id: UUID
    public var playerId: UUID
    public var fromClubId: UUID       // The club currently holding the player's contract
    public var toClubId: UUID         // The bidding club
    public var fee: Int               // Transfer fee in GBP
    public var isLoan: Bool
    public var loanWeeks: Int?        // Duration if loan
    public var status: TransferOfferStatus
    public var offeredWage: Int?      // Weekly wage offer for personal terms
    public var contractYears: Int?    // Contract length in years
    
    public init(
        id: UUID = UUID(),
        playerId: UUID,
        fromClubId: UUID,
        toClubId: UUID,
        fee: Int,
        isLoan: Bool = false,
        loanWeeks: Int? = nil,
        status: TransferOfferStatus = .pending,
        offeredWage: Int? = nil,
        contractYears: Int? = nil
    ) {
        self.id = id
        self.playerId = playerId
        self.fromClubId = fromClubId
        self.toClubId = toClubId
        self.fee = fee
        self.isLoan = isLoan
        self.loanWeeks = loanWeeks
        self.status = status
        self.offeredWage = offeredWage
        self.contractYears = contractYears
    }
    
    public var formattedFee: String {
        return Player.formatCurrency(fee)
    }
    
    public var formattedOfferedWage: String {
        guard let wage = offeredWage else { return "N/A" }
        return "\(Player.formatCurrency(wage))/w"
    }
}

// MARK: - Transfer Record

public struct TransferRecord: Codable, Identifiable, Hashable {
    public let id: UUID
    public var playerId: UUID
    public var playerName: String
    public var fromClubId: UUID
    public var fromClubName: String
    public var toClubId: UUID
    public var toClubName: String
    public var fee: Int
    public var isLoan: Bool
    public var date: String           // Date completed "YYYY-MM-DD"
    
    public init(
        id: UUID = UUID(),
        playerId: UUID,
        playerName: String,
        fromClubId: UUID,
        fromClubName: String,
        toClubId: UUID,
        toClubName: String,
        fee: Int,
        isLoan: Bool = false,
        date: String
    ) {
        self.id = id
        self.playerId = playerId
        self.playerName = playerName
        self.fromClubId = fromClubId
        self.fromClubName = fromClubName
        self.toClubId = toClubId
        self.toClubName = toClubName
        self.fee = fee
        self.isLoan = isLoan
        self.date = date
    }
    
    public var formattedFee: String {
        if isLoan {
            return "Loan"
        }
        if fee == 0 {
            return "Free Transfer"
        }
        return Player.formatCurrency(fee)
    }
}
