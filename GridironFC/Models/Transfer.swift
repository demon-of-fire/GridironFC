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

    // MARK: Negotiation state
    /// The selling club's valuation captured when the bid was made, used for counters.
    public var askingPrice: Int
    /// Fee the selling club is willing to accept (their latest counter). nil = none.
    public var counterFee: Int?
    /// Wage the player is demanding (their latest counter). nil = accepts offer.
    public var demandedWage: Int?
    /// Which way the offer flows: true when the user is bidding, false when an AI club bids.
    public var isIncoming: Bool
    /// Number of back-and-forth rounds already exchanged.
    public var negotiationRound: Int
    /// In-game date the offer was made.
    public var createdDate: String
    /// Weeks until the counterparty responds (0 = ready to resolve this week).
    public var weeksUntilResponse: Int

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
        contractYears: Int? = nil,
        askingPrice: Int = 0,
        counterFee: Int? = nil,
        demandedWage: Int? = nil,
        isIncoming: Bool = false,
        negotiationRound: Int = 0,
        createdDate: String = "",
        weeksUntilResponse: Int = 1
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
        self.askingPrice = askingPrice
        self.counterFee = counterFee
        self.demandedWage = demandedWage
        self.isIncoming = isIncoming
        self.negotiationRound = negotiationRound
        self.createdDate = createdDate
        self.weeksUntilResponse = weeksUntilResponse
    }

    /// True while the offer is waiting on a response (fee negotiation or the
    /// player's personal terms) and can still be resolved or countered.
    public var isLive: Bool {
        switch status {
        case .pending, .counterOffer, .personalTerms, .accepted: return true
        case .rejected, .completed, .withdrawn: return false
        }
    }

    public var formattedFee: String {
        return Player.formatCurrency(fee)
    }

    public var formattedOfferedWage: String {
        guard let wage = offeredWage else { return "N/A" }
        return "\(Player.formatCurrency(wage))/w"
    }

    // MARK: - Codable (tolerant of saves predating the richer negotiation model)

    private enum CodingKeys: String, CodingKey {
        case id, playerId, fromClubId, toClubId, fee, isLoan, loanWeeks, status
        case offeredWage, contractYears, askingPrice, counterFee, demandedWage
        case isIncoming, negotiationRound, createdDate, weeksUntilResponse
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        playerId = try c.decode(UUID.self, forKey: .playerId)
        fromClubId = try c.decode(UUID.self, forKey: .fromClubId)
        toClubId = try c.decode(UUID.self, forKey: .toClubId)
        fee = try c.decode(Int.self, forKey: .fee)
        isLoan = try c.decodeIfPresent(Bool.self, forKey: .isLoan) ?? false
        loanWeeks = try c.decodeIfPresent(Int.self, forKey: .loanWeeks)
        status = try c.decodeIfPresent(TransferOfferStatus.self, forKey: .status) ?? .pending
        offeredWage = try c.decodeIfPresent(Int.self, forKey: .offeredWage)
        contractYears = try c.decodeIfPresent(Int.self, forKey: .contractYears)
        askingPrice = try c.decodeIfPresent(Int.self, forKey: .askingPrice) ?? fee
        counterFee = try c.decodeIfPresent(Int.self, forKey: .counterFee)
        demandedWage = try c.decodeIfPresent(Int.self, forKey: .demandedWage)
        isIncoming = try c.decodeIfPresent(Bool.self, forKey: .isIncoming) ?? false
        negotiationRound = try c.decodeIfPresent(Int.self, forKey: .negotiationRound) ?? 0
        createdDate = try c.decodeIfPresent(String.self, forKey: .createdDate) ?? ""
        weeksUntilResponse = try c.decodeIfPresent(Int.self, forKey: .weeksUntilResponse) ?? 0
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
