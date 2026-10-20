//
//  DataLoader.swift
//  GridironFC
//
//  Created for GridironFC - iOS Football Manager Game.
//  Loads and decodes league and club JSON files from the app bundle.
//  Includes the position-template procedural attribute generation algorithm,
//  specialty overrides, realistic valuation/wage formulas, and full fallback dataset.
//

import Foundation

// MARK: - Raw JSON Transfer DTOs

public struct RawLeagueData: Codable {
    public let name: String
    public let tier: Int
    public let clubs: [RawClubData]
}

public struct RawClubData: Codable {
    public let name: String
    public let shortName: String
    public let stadium: String
    public let stadiumCapacity: Int
    public let primaryColor: String
    public let secondaryColor: String
    public let city: String
    public let manager: String
    public let reputation: Int
    public let budget: Int?
    public let wageBudget: Int?
    public let players: [RawPlayerData]
}

public struct RawPlayerData: Codable {
    public let firstName: String
    public let lastName: String
    public let nationality: String
    public let age: Int
    public let positions: [String]
    public let overall: Int
    public let potential: Int
    public let preferredFoot: String?
    public let height: Int?
    public let weight: Int?
    public let value: Int?
    public let wage: Int?
    public let contractYears: Int?
    public let specialties: [String: Int]?
}

// MARK: - DataLoader

public final class DataLoader {
    
    // MARK: - Public Entrypoint
    
    /// Loads all 4 league divisions and all registered clubs.
    /// Looks first in the main bundle for JSON files (tier1.json through tier4.json).
    /// If bundle files are absent, builds the world from the comprehensive embedded dataset.
    public static func loadAllData() -> ([Club], [League]) {
        var allClubs: [Club] = []
        var allLeagues: [League] = []

        for tier in LeagueTier.allCases {
            let raw = loadRawLeague(for: tier)
            if let rawLeague = raw {
                var leagueClubIds: [UUID] = []
                for rawClub in rawLeague.clubs {
                    let club = buildClub(from: rawClub, tier: tier)
                    allClubs.append(club)
                    leagueClubIds.append(club.id)
                }
                let league = League(name: rawLeague.name, tier: tier, clubIds: leagueClubIds)
                allLeagues.append(league)
            } else if tier.country == .england {
                // Fallback to the built-in programmatic catalog for the English pyramid.
                let (clubsForTier, league) = buildFallbackTier(tier: tier, name: tier.displayName)
                allClubs.append(contentsOf: clubsForTier)
                allLeagues.append(league)
            }
            // Non-English leagues require their JSON; if missing they are omitted.
        }

        return (allClubs, allLeagues)
    }

    /// Candidate bundle resource names for a tier, in priority order.
    /// Canonical name is `tier<rawValue>`; historical short names are kept as aliases.
    private static func resourceNames(for tier: LeagueTier) -> [String] {
        var names: [String] = ["tier\(tier.rawValue)"]
        switch tier {
        case .eng1: names += ["tier1", "league_premier", "premier_league"]
        case .eng2: names += ["tier2", "championship"]
        case .eng3: names += ["tier3", "league_one"]
        case .eng4: names += ["tier4", "league_two"]
        case .esp1: names += ["tier5", "laliga", "spain"]
        case .ita1: names += ["tier6", "seriea", "italy"]
        case .ger1: names += ["tier7", "bundesliga", "germany"]
        case .fra1: names += ["tier8", "ligue1", "france"]
        default: break
        }
        return names
    }

    private static func loadRawLeague(for tier: LeagueTier) -> RawLeagueData? {
        for res in resourceNames(for: tier) {
            if let bundleUrl = Bundle.main.url(forResource: res, withExtension: "json"),
               let data = try? Data(contentsOf: bundleUrl),
               let rawLeague = try? JSONDecoder().decode(RawLeagueData.self, from: data) {
                return rawLeague
            }
        }
        return nil
    }
    
    // MARK: - Raw Club Conversion
    
    public static func buildClub(from raw: RawClubData, tier: LeagueTier) -> Club {
        var clubPlayers: [Player] = []
        for rawPlayer in raw.players {
            let player = buildPlayer(from: rawPlayer, tier: tier)
            clubPlayers.append(player)
        }
        
        // If club has fewer than 18 players, supplement with procedurally generated squad members
        if clubPlayers.count < 18 {
            let filler = generateProceduralSquad(targetCount: 22 - clubPlayers.count, tier: tier)
            clubPlayers.append(contentsOf: filler)
        }
        
        let finances = ClubFinances(
            transferBudget: raw.budget ?? ClubFinances.defaultFor(tier: tier).transferBudget,
            wageBudget: raw.wageBudget ?? ClubFinances.defaultFor(tier: tier).wageBudget,
            currentWageBill: 0,
            balance: (raw.budget ?? 10_000_000) * 2,
            tvIncome: ClubFinances.defaultFor(tier: tier).tvIncome,
            matchdayIncome: Int(Double(raw.stadiumCapacity) * 22.0),
            sponsorshipIncome: ClubFinances.defaultFor(tier: tier).sponsorshipIncome,
            merchandiseIncome: ClubFinances.defaultFor(tier: tier).merchandiseIncome
        )
        
        return Club(
            name: raw.name,
            shortName: raw.shortName,
            stadium: raw.stadium,
            stadiumCapacity: raw.stadiumCapacity,
            city: raw.city,
            primaryColor: raw.primaryColor,
            secondaryColor: raw.secondaryColor,
            leagueTier: tier,
            reputation: raw.reputation,
            players: clubPlayers,
            manager: raw.manager,
            finances: finances
        )
    }
    
    // MARK: - Raw Player Conversion
    
    public static func buildPlayer(from raw: RawPlayerData, tier: LeagueTier) -> Player {
        let mappedPositions: [Position] = raw.positions.compactMap { Position(rawValue: $0) }
        let positions = mappedPositions.isEmpty ? [.CM] : mappedPositions
        let primaryPos = positions.first ?? .CM
        
        let foot: Foot
        switch raw.preferredFoot?.lowercased() {
        case "left": foot = .left
        case "both": foot = .both
        default: foot = .right
        }
        
        let height = raw.height ?? Int.random(in: 174...189)
        let weight = raw.weight ?? Int.random(in: 68...84)
        
        let attributes = generateAttributes(
            overall: raw.overall,
            position: primaryPos,
            specialties: raw.specialties
        )
        
        let contractYears = raw.contractYears ?? Int.random(in: 2...4)
        let weeklyWage = raw.wage ?? max(400, raw.overall * 40 * tier.level)
        let contract = Contract(wage: weeklyWage, yearsRemaining: contractYears, signingDate: "2024-07")
        
        return Player(
            firstName: raw.firstName,
            lastName: raw.lastName,
            nationality: raw.nationality,
            age: raw.age,
            height: height,
            weight: weight,
            preferredFoot: foot,
            positions: positions,
            attributes: attributes,
            overall: raw.overall,
            potential: max(raw.potential, raw.overall),
            contract: contract,
            value: raw.value
        )
    }
    
    // MARK: - Procedural Attribute Generation Algorithm
    
    /// Generates full 30+ player attributes using positional weighting templates,
    /// randomized natural variance (±3), and optional specialty attribute overrides.
    public static func generateAttributes(
        overall: Int,
        position: Position,
        specialties: [String: Int]? = nil
    ) -> PlayerAttributes {
        
        func calculateStat(offset: Int) -> Int {
            let noise = Int.random(in: -3...3)
            let rawValue = overall + offset + noise
            return min(99, max(1, rawValue))
        }
        
        var attrs = PlayerAttributes()
        
        switch position {
        case .GK:
            // High Goalkeeping, low outfield
            attrs.reflexes = calculateStat(offset: 4)
            attrs.handling = calculateStat(offset: 3)
            attrs.gkPositioning = calculateStat(offset: 3)
            attrs.oneOnOnes = calculateStat(offset: 2)
            attrs.kicking = calculateStat(offset: 1)
            attrs.commandOfArea = calculateStat(offset: 2)
            
            attrs.jumping = calculateStat(offset: 1)
            attrs.strength = calculateStat(offset: 0)
            attrs.agility = calculateStat(offset: 1)
            attrs.composure = calculateStat(offset: -2)
            attrs.concentration = calculateStat(offset: 3)
            
            attrs.passing = calculateStat(offset: -25)
            attrs.shooting = calculateStat(offset: -40)
            attrs.dribbling = calculateStat(offset: -35)
            attrs.tackling = calculateStat(offset: -30)
            attrs.marking = calculateStat(offset: -35)
            attrs.pace = calculateStat(offset: -15)
            attrs.stamina = calculateStat(offset: -10)
            
        case .CB:
            // High defense, physical strength, aerial ability
            attrs.tackling = calculateStat(offset: 5)
            attrs.marking = calculateStat(offset: 4)
            attrs.heading = calculateStat(offset: 5)
            attrs.strength = calculateStat(offset: 6)
            attrs.jumping = calculateStat(offset: 4)
            attrs.positioning = calculateStat(offset: 3)
            attrs.aggression = calculateStat(offset: 4)
            attrs.teamwork = calculateStat(offset: 2)
            attrs.concentration = calculateStat(offset: 2)
            attrs.stamina = calculateStat(offset: 0)
            attrs.pace = calculateStat(offset: -3)
            attrs.passing = calculateStat(offset: -4)
            attrs.firstTouch = calculateStat(offset: -5)
            attrs.dribbling = calculateStat(offset: -12)
            attrs.shooting = calculateStat(offset: -20)
            
        case .LB, .RB:
            // High pace, stamina, crossing, solid tackling
            attrs.pace = calculateStat(offset: 5)
            attrs.stamina = calculateStat(offset: 6)
            attrs.crossing = calculateStat(offset: 4)
            attrs.tackling = calculateStat(offset: 3)
            attrs.marking = calculateStat(offset: 2)
            attrs.workRate = calculateStat(offset: 5)
            attrs.dribbling = calculateStat(offset: 1)
            attrs.passing = calculateStat(offset: 1)
            attrs.agility = calculateStat(offset: 3)
            attrs.positioning = calculateStat(offset: 1)
            attrs.shooting = calculateStat(offset: -14)
            
        case .LWB, .RWB:
            // Wing back: higher attacking emphasis and crossing
            attrs.pace = calculateStat(offset: 6)
            attrs.stamina = calculateStat(offset: 7)
            attrs.crossing = calculateStat(offset: 5)
            attrs.dribbling = calculateStat(offset: 3)
            attrs.workRate = calculateStat(offset: 5)
            attrs.tackling = calculateStat(offset: 1)
            attrs.marking = calculateStat(offset: 0)
            attrs.agility = calculateStat(offset: 3)
            attrs.passing = calculateStat(offset: 2)
            attrs.shooting = calculateStat(offset: -10)
            
        case .CDM:
            // Defensive shield: tackling, positioning, stamina, distribution
            attrs.tackling = calculateStat(offset: 5)
            attrs.positioning = calculateStat(offset: 5)
            attrs.passing = calculateStat(offset: 3)
            attrs.stamina = calculateStat(offset: 5)
            attrs.marking = calculateStat(offset: 4)
            attrs.strength = calculateStat(offset: 3)
            attrs.teamwork = calculateStat(offset: 4)
            attrs.decisions = calculateStat(offset: 3)
            attrs.workRate = calculateStat(offset: 4)
            attrs.firstTouch = calculateStat(offset: 2)
            attrs.dribbling = calculateStat(offset: -2)
            attrs.shooting = calculateStat(offset: -8)
            
        case .CM:
            // Balanced engine: passing, vision, first touch, decisions
            attrs.passing = calculateStat(offset: 5)
            attrs.vision = calculateStat(offset: 4)
            attrs.firstTouch = calculateStat(offset: 4)
            attrs.stamina = calculateStat(offset: 4)
            attrs.decisions = calculateStat(offset: 3)
            attrs.dribbling = calculateStat(offset: 2)
            attrs.tackling = calculateStat(offset: 1)
            attrs.positioning = calculateStat(offset: 2)
            attrs.teamwork = calculateStat(offset: 4)
            attrs.longShots = calculateStat(offset: 2)
            attrs.shooting = calculateStat(offset: 0)
            
        case .CAM:
            // Creative architect: vision, passing, dribbling, composure
            attrs.vision = calculateStat(offset: 6)
            attrs.passing = calculateStat(offset: 5)
            attrs.dribbling = calculateStat(offset: 5)
            attrs.firstTouch = calculateStat(offset: 5)
            attrs.shooting = calculateStat(offset: 3)
            attrs.composure = calculateStat(offset: 4)
            attrs.longShots = calculateStat(offset: 3)
            attrs.agility = calculateStat(offset: 3)
            attrs.offTheBall = calculateStat(offset: 3)
            attrs.tackling = calculateStat(offset: -10)
            attrs.marking = calculateStat(offset: -12)
            
        case .LM, .RM:
            // Wide midfielder: pace, crossing, stamina, teamwork
            attrs.pace = calculateStat(offset: 5)
            attrs.crossing = calculateStat(offset: 5)
            attrs.dribbling = calculateStat(offset: 4)
            attrs.stamina = calculateStat(offset: 4)
            attrs.passing = calculateStat(offset: 3)
            attrs.workRate = calculateStat(offset: 4)
            attrs.agility = calculateStat(offset: 3)
            attrs.firstTouch = calculateStat(offset: 3)
            attrs.shooting = calculateStat(offset: 0)
            attrs.tackling = calculateStat(offset: -4)
            
        case .LW, .RW:
            // Modern winger: electric pace, 1v1 dribbling, finishing
            attrs.pace = calculateStat(offset: 7)
            attrs.dribbling = calculateStat(offset: 6)
            attrs.agility = calculateStat(offset: 5)
            attrs.crossing = calculateStat(offset: 3)
            attrs.shooting = calculateStat(offset: 3)
            attrs.firstTouch = calculateStat(offset: 4)
            attrs.offTheBall = calculateStat(offset: 3)
            attrs.composure = calculateStat(offset: 2)
            attrs.tackling = calculateStat(offset: -15)
            attrs.marking = calculateStat(offset: -18)
            
        case .ST:
            // Striker: lethal shooting, composure, heading, off the ball
            attrs.shooting = calculateStat(offset: 7)
            attrs.composure = calculateStat(offset: 5)
            attrs.offTheBall = calculateStat(offset: 5)
            attrs.heading = calculateStat(offset: 4)
            attrs.firstTouch = calculateStat(offset: 3)
            attrs.strength = calculateStat(offset: 3)
            attrs.pace = calculateStat(offset: 3)
            attrs.jumping = calculateStat(offset: 3)
            attrs.penalties = calculateStat(offset: 4)
            attrs.tackling = calculateStat(offset: -20)
            attrs.marking = calculateStat(offset: -22)
            
        case .CF:
            // Center forward / False 9: dribbling, link-up passing, shooting
            attrs.shooting = calculateStat(offset: 5)
            attrs.dribbling = calculateStat(offset: 5)
            attrs.firstTouch = calculateStat(offset: 5)
            attrs.passing = calculateStat(offset: 4)
            attrs.vision = calculateStat(offset: 4)
            attrs.composure = calculateStat(offset: 4)
            attrs.offTheBall = calculateStat(offset: 4)
            attrs.agility = calculateStat(offset: 3)
            attrs.tackling = calculateStat(offset: -15)
        }
        
        // Base outfield non-GK attributes for outfielders
        if position != .GK {
            attrs.reflexes = 12
            attrs.handling = 10
            attrs.gkPositioning = 10
            attrs.oneOnOnes = 10
            attrs.kicking = 15
            attrs.commandOfArea = 10
        }
        
        // Apply specialties dictionary overrides
        if let specs = specialties {
            applySpecialties(&attrs, specialties: specs)
        }
        
        return attrs
    }
    
    private static func applySpecialties(_ attrs: inout PlayerAttributes, specialties: [String: Int]) {
        for (key, val) in specialties {
            let clamped = min(99, max(1, val))
            switch key.lowercased() {
            case "passing": attrs.passing = clamped
            case "shooting": attrs.shooting = clamped
            case "dribbling": attrs.dribbling = clamped
            case "firsttouch": attrs.firstTouch = clamped
            case "crossing": attrs.crossing = clamped
            case "freekicks": attrs.freeKicks = clamped
            case "penalties": attrs.penalties = clamped
            case "heading": attrs.heading = clamped
            case "longshots": attrs.longShots = clamped
            case "tackling": attrs.tackling = clamped
            case "marking": attrs.marking = clamped
            case "pace": attrs.pace = clamped
            case "stamina": attrs.stamina = clamped
            case "strength": attrs.strength = clamped
            case "agility": attrs.agility = clamped
            case "jumping": attrs.jumping = clamped
            case "balance": attrs.balance = clamped
            case "vision": attrs.vision = clamped
            case "composure": attrs.composure = clamped
            case "decisions": attrs.decisions = clamped
            case "workrate": attrs.workRate = clamped
            case "aggression": attrs.aggression = clamped
            case "leadership": attrs.leadership = clamped
            case "teamwork": attrs.teamwork = clamped
            case "positioning": attrs.positioning = clamped
            case "offtheball": attrs.offTheBall = clamped
            case "concentration": attrs.concentration = clamped
            case "reflexes": attrs.reflexes = clamped
            case "handling": attrs.handling = clamped
            case "gkpositioning": attrs.gkPositioning = clamped
            case "oneonones": attrs.oneOnOnes = clamped
            case "kicking": attrs.kicking = clamped
            case "commandofarea": attrs.commandOfArea = clamped
            default: break
            }
        }
    }
    
    // MARK: - Procedural Squad Generator (e.g. for Created Club or Fillers)
    
    public static func generateProceduralSquad(targetCount: Int = 22, tier: LeagueTier) -> [Player] {
        let firstNames = ["James", "Jack", "Harry", "Oliver", "George", "Noah", "Charlie", "Jacob", "Alfie", "Freddie", "Oscar", "Leo", "Logan", "Archie", "Theo", "Thomas", "Arthur", "Mason", "Henry", "Lucas", "Liam", "Ethan"]
        let lastNames = ["Smith", "Jones", "Taylor", "Brown", "Williams", "Wilson", "Johnson", "Davies", "Robinson", "Wright", "Thompson", "Evans", "Walker", "White", "Roberts", "Green", "Hall", "Wood", "Jackson", "Clarke"]
        
        let targetPositions: [Position] = [
            .GK, .GK,
            .CB, .CB, .CB, .CB,
            .LB, .RB,
            .CDM, .CDM,
            .CM, .CM, .CM,
            .CAM,
            .LM, .RM,
            .LW, .RW,
            .ST, .ST, .ST, .CF
        ]
        
        let baseRating: Int
        switch tier.level {
        case 1: baseRating = tier.country == .england ? 78 : 76
        case 2: baseRating = 67
        case 3: baseRating = 59
        default: baseRating = 51
        }
        
        var squad: [Player] = []
        for i in 0..<min(targetCount, targetPositions.count) {
            let pos = targetPositions[i]
            let fn = firstNames.randomElement() ?? "Alex"
            let ln = lastNames.randomElement() ?? "Hunter"
            let age = Int.random(in: 18...33)
            let variance = Int.random(in: -5...6)
            let overall = max(40, min(92, baseRating + variance))
            let potential = age < 24 ? overall + Int.random(in: 4...12) : overall
            
            let attrs = generateAttributes(overall: overall, position: pos)
            let weeklyWage = max(400, overall * 35)
            let contract = Contract(wage: weeklyWage, yearsRemaining: Int.random(in: 1...4))
            
            let player = Player(
                firstName: fn,
                lastName: ln,
                nationality: "England",
                age: age,
                height: pos == .GK ? Int.random(in: 187...196) : Int.random(in: 172...188),
                weight: pos == .GK ? Int.random(in: 80...92) : Int.random(in: 66...82),
                preferredFoot: Double.random(in: 0...1) < 0.25 ? .left : .right,
                positions: [pos],
                attributes: attrs,
                overall: overall,
                potential: potential,
                contract: contract
            )
            squad.append(player)
        }
        
        return squad
    }
    
    // MARK: - Youth Academy Prospect Generator

    /// Generates a batch of youth academy prospects (aged 15-18) whose quality
    /// scales with the club's academy level, reputation and tier.
    public static func generateAcademyProspects(count: Int, club: Club) -> [Player] {
        let firstNames = ["James", "Jack", "Harry", "Oliver", "George", "Noah", "Charlie", "Jacob", "Alfie", "Freddie", "Oscar", "Leo", "Logan", "Archie", "Theo", "Thomas", "Arthur", "Mason", "Henry", "Lucas", "Liam", "Ethan", "Kai", "Reece", "Finley", "Blake"]
        let lastNames = ["Smith", "Jones", "Taylor", "Brown", "Williams", "Wilson", "Johnson", "Davies", "Robinson", "Wright", "Thompson", "Evans", "Walker", "White", "Roberts", "Green", "Hall", "Wood", "Jackson", "Clarke", "Patel", "Murphy", "Hughes", "Okafor", "Mensah", "Doyle"]
        let nationalities = ["England", "Spain", "France", "Portugal", "Brazil", "Netherlands", "Germany", "Italy", "Argentina", "Belgium"]

        let developmentPositions: [Position] = [.GK, .CB, .LB, .RB, .CDM, .CM, .CAM, .LM, .RM, .LW, .RW, .ST, .CB, .CM, .ST]

        // Academy level (1-5) and reputation drive the ceiling.
        let levelBonus = (club.youthAcademyLevel - 3) * 3
        let repBonus = (club.reputation - 55) / 6
        let tierBase: Int
        switch club.leagueTier.level {
        case 1: tierBase = 52
        case 2: tierBase = 48
        case 3: tierBase = 44
        default: tierBase = 40
        }
        let base = tierBase + levelBonus + repBonus

        var prospects: [Player] = []
        for _ in 0..<count {
            let pos = developmentPositions.randomElement() ?? .CM
            let age = Int.random(in: 15...18)
            let variance = Int.random(in: -3...4)
            let overall = max(35, min(70, base + variance))
            // Potential scales with youth-development investment and youth.
            let potBonus = Int.random(in: 6...18) + (club.youthAcademyLevel - 2) * 3
            let potential = max(overall + 5, min(88, overall + potBonus))

            let attrs = generateAttributes(overall: overall, position: pos)
            let player = Player(
                firstName: firstNames.randomElement() ?? "Alex",
                lastName: lastNames.randomElement() ?? "Hunter",
                nationality: nationalities.randomElement() ?? "England",
                age: age,
                height: pos == .GK ? Int.random(in: 180...194) : Int.random(in: 165...188),
                weight: pos == .GK ? Int.random(in: 72...88) : Int.random(in: 58...78),
                preferredFoot: Double.random(in: 0...1) < 0.25 ? .left : .right,
                positions: [pos],
                attributes: attrs,
                overall: overall,
                potential: potential,
                contract: Contract(wage: max(150, overall * 12), yearsRemaining: 3)
            )
            prospects.append(player)
        }
        return prospects
    }

    // MARK: - Built-in Programmatic Tier Catalogs
    
    private static func buildFallbackTier(tier: LeagueTier, name: String) -> ([Club], League) {
        var clubs: [Club] = []
        
        let clubData: [(name: String, short: String, stadium: String, cap: Int, city: String, c1: String, c2: String, rep: Int)]
        
        switch tier {
        case .eng1:
            clubData = [
                ("Arsenal", "ARS", "Emirates Stadium", 60704, "London", "#EF0107", "#FFFFFF", 90),
                ("Aston Villa", "AVL", "Villa Park", 42682, "Birmingham", "#670E36", "#95BFE5", 82),
                ("Chelsea", "CHE", "Stamford Bridge", 40341, "London", "#034694", "#FFFFFF", 86),
                ("Liverpool", "LIV", "Anfield", 61276, "Liverpool", "#C8102E", "#FFFFFF", 92),
                ("Manchester City", "MCI", "Etihad Stadium", 53400, "Manchester", "#6CABDD", "#FFFFFF", 95),
                ("Manchester United", "MUN", "Old Trafford", 74310, "Manchester", "#DA291C", "#FBE122", 89),
                ("Newcastle United", "NEW", "St James' Park", 52305, "Newcastle", "#241F20", "#FFFFFF", 84),
                ("Tottenham Hotspur", "TOT", "Tottenham Hotspur Stadium", 62850, "London", "#132257", "#FFFFFF", 85),
                ("Brighton & Hove Albion", "BHA", "Amex Stadium", 31800, "Brighton", "#0057B8", "#FFFFFF", 80),
                ("West Ham United", "WHU", "London Stadium", 62500, "London", "#7A263A", "#1BB1E7", 81),
                ("Wolverhampton Wanderers", "WOL", "Molineux", 31750, "Wolverhampton", "#FDB913", "#231F20", 78),
                ("Crystal Palace", "CRY", "Selhurst Park", 25486, "London", "#1B458F", "#A7A5A6", 78),
                ("Fulham", "FUL", "Craven Cottage", 25700, "London", "#FFFFFF", "#000000", 77),
                ("Bournemouth", "BOU", "Vitality Stadium", 11307, "Bournemouth", "#DA291C", "#000000", 76),
                ("Brentford", "BRE", "Gtech Community Stadium", 17250, "London", "#E30613", "#FFFFFF", 77),
                ("Everton", "EVE", "Goodison Park", 39572, "Liverpool", "#003399", "#FFFFFF", 78),
                ("Nottingham Forest", "NFO", "City Ground", 30445, "Nottingham", "#DD0000", "#FFFFFF", 76),
                ("Leicester City", "LEI", "King Power Stadium", 32261, "Leicester", "#003090", "#FDBE11", 79),
                ("Ipswich Town", "IPS", "Portman Road", 29673, "Ipswich", "#003399", "#FFFFFF", 74),
                ("Southampton", "SOU", "St Mary's Stadium", 32384, "Southampton", "#D71920", "#FFFFFF", 76)
            ]
            
        case .eng2:
            clubData = [
                ("Leeds United", "LEE", "Elland Road", 37890, "Leeds", "#FFCD00", "#1D428A", 77),
                ("Burnley", "BUR", "Turf Moor", 21944, "Burnley", "#6C1D45", "#99D6EA", 76),
                ("Sheffield United", "SHU", "Bramall Lane", 32050, "Sheffield", "#EE2737", "#000000", 75),
                ("Sunderland", "SUN", "Stadium of Light", 49000, "Sunderland", "#EB172B", "#FFFFFF", 74),
                ("Middlesbrough", "MID", "Riverside Stadium", 34742, "Middlesbrough", "#E00000", "#FFFFFF", 73),
                ("West Bromwich Albion", "WBA", "The Hawthorns", 26850, "West Bromwich", "#122F67", "#FFFFFF", 74),
                ("Norwich City", "NOR", "Carrow Road", 27244, "Norwich", "#00A650", "#FFF200", 74),
                ("Coventry City", "COV", "Coventry Building Society Arena", 32609, "Coventry", "#59B3E4", "#002B49", 73),
                ("Bristol City", "BRC", "Ashton Gate", 27000, "Bristol", "#E21836", "#FFFFFF", 71),
                ("Watford", "WAT", "Vicarage Road", 22200, "Watford", "#FBEE23", "#ED2127", 73),
                ("Stoke City", "STK", "bet365 Stadium", 30089, "Stoke", "#E03A3E", "#FFFFFF", 72),
                ("Blackburn Rovers", "BLB", "Ewood Park", 31367, "Blackburn", "#0053A0", "#FFFFFF", 72),
                ("Millwall", "MIL", "The Den", 20146, "London", "#001E62", "#FFFFFF", 71),
                ("Swansea City", "SWA", "Swansea.com Stadium", 21088, "Swansea", "#FFFFFF", "#000000", 72),
                ("Preston North End", "PNE", "Deepdale", 23408, "Preston", "#002D62", "#FFFFFF", 70),
                ("Queens Park Rangers", "QPR", "Loftus Road", 18439, "London", "#1D428A", "#FFFFFF", 71),
                ("Hull City", "HUL", "MKM Stadium", 25586, "Hull", "#F58220", "#000000", 72),
                ("Derby County", "DER", "Pride Park", 33597, "Derby", "#FFFFFF", "#000000", 72),
                ("Portsmouth", "POR", "Fratton Park", 20899, "Portsmouth", "#001489", "#FFFFFF", 71),
                ("Oxford United", "OXF", "Kassam Stadium", 12500, "Oxford", "#FEEB00", "#0B2265", 69),
                ("Plymouth Argyle", "PLY", "Home Park", 17900, "Plymouth", "#103C28", "#FFFFFF", 69),
                ("Sheffield Wednesday", "SHW", "Hillsborough", 39732, "Sheffield", "#0E4EA2", "#FFFFFF", 71),
                ("Luton Town", "LUT", "Kenilworth Road", 12000, "Luton", "#F78F1E", "#002D62", 74),
                ("Cardiff City", "CAR", "Cardiff City Stadium", 33280, "Cardiff", "#0047AB", "#FFFFFF", 71)
            ]
            
        case .eng3:
            clubData = [
                ("Birmingham City", "BIR", "St Andrew's", 29409, "Birmingham", "#0000FF", "#FFFFFF", 72),
                ("Huddersfield Town", "HUD", "John Smith's Stadium", 24121, "Huddersfield", "#0072CE", "#FFFFFF", 70),
                ("Rotherham United", "ROT", "New York Stadium", 12021, "Rotherham", "#EE2737", "#FFFFFF", 69),
                ("Bolton Wanderers", "BOL", "Toughsheet Community Stadium", 28723, "Bolton", "#001D48", "#FFFFFF", 69),
                ("Peterborough United", "PET", "London Road", 15314, "Peterborough", "#0053A0", "#FFFFFF", 68),
                ("Barnsley", "BAR", "Oakwell", 23287, "Barnsley", "#EE2737", "#FFFFFF", 68),
                ("Blackpool", "BLP", "Bloomfield Road", 16616, "Blackpool", "#F37021", "#FFFFFF", 68),
                ("Lincoln City", "LIN", "Sincil Bank", 10669, "Lincoln", "#EE2737", "#FFFFFF", 67),
                ("Charlton Athletic", "CHA", "The Valley", 27111, "London", "#EE2737", "#FFFFFF", 68),
                ("Wycombe Wanderers", "WYC", "Adams Park", 10000, "High Wycombe", "#55A5D9", "#112244", 67),
                ("Reading", "REA", "Madejski Stadium", 24161, "Reading", "#002F6C", "#FFFFFF", 68),
                ("Wrexham", "WXH", "Racecourse Ground", 12600, "Wrexham", "#EE2737", "#FFFFFF", 69),
                ("Stockport County", "STC", "Edgeley Park", 10852, "Stockport", "#0053A0", "#FFFFFF", 67),
                ("Mansfield Town", "MAN", "Field Mill", 9186, "Mansfield", "#FDB913", "#002D62", 66),
                ("Stevenage", "STE", "Broadhall Way", 7800, "Stevenage", "#EE2737", "#FFFFFF", 65),
                ("Northampton Town", "NOR", "Sixfields Stadium", 7798, "Northampton", "#7A263A", "#FFFFFF", 65),
                ("Exeter City", "EXE", "St James Park", 8720, "Exeter", "#EE2737", "#FFFFFF", 65),
                ("Bristol Rovers", "BRR", "Memorial Stadium", 12300, "Bristol", "#0053A0", "#FFFFFF", 66),
                ("Wigan Athletic", "WIG", "Brick Community Stadium", 25138, "Wigan", "#0053A0", "#FFFFFF", 67),
                ("Leyton Orient", "LEY", "Brisbane Road", 9271, "London", "#EE2737", "#FFFFFF", 66),
                ("Shrewsbury Town", "SHR", "New Meadow", 9875, "Shrewsbury", "#0053A0", "#FDB913", 64),
                ("Burton Albion", "BUR", "Pirelli Stadium", 6912, "Burton", "#FFDD00", "#000000", 64),
                ("Cambridge United", "CAM", "Abbey Stadium", 8127, "Cambridge", "#FDB913", "#000000", 64),
                ("Crawley Town", "CRA", "Broadfield Stadium", 6134, "Crawley", "#EE2737", "#FFFFFF", 63)
            ]
            
        case .eng4:
            clubData = [
                ("Doncaster Rovers", "DON", "Eco-Power Stadium", 15231, "Doncaster", "#EE2737", "#FFFFFF", 63),
                ("Bradford City", "BRA", "Valley Parade", 25136, "Bradford", "#800000", "#FFBF00", 64),
                ("Milton Keynes Dons", "MKD", "Stadium MK", 30500, "Milton Keynes", "#FFFFFF", "#000000", 64),
                ("Chesterfield", "CHF", "SMH Group Stadium", 10504, "Chesterfield", "#0053A0", "#FFFFFF", 63),
                ("Port Vale", "POV", "Vale Park", 15695, "Stoke", "#FFFFFF", "#000000", 63),
                ("Notts County", "NTC", "Meadow Lane", 19841, "Nottingham", "#000000", "#FFFFFF", 63),
                ("Gillingham", "GIL", "Priestfield", 11582, "Gillingham", "#0053A0", "#FFFFFF", 62),
                ("Salford City", "SAL", "Moor Lane", 5108, "Salford", "#EE2737", "#000000", 62),
                ("Walsall", "WAL", "Bescot Stadium", 11300, "Walsall", "#EE2737", "#FFFFFF", 62),
                ("Crewe Alexandra", "CRE", "Gresty Road", 10153, "Crewe", "#EE2737", "#FFFFFF", 62),
                ("AFC Wimbledon", "WIM", "Plough Lane", 9215, "London", "#003399", "#FFD700", 62),
                ("Tranmere Rovers", "TRA", "Prenton Park", 16587, "Birkenhead", "#FFFFFF", "#003399", 61),
                ("Swindon Town", "SWI", "County Ground", 15728, "Swindon", "#EE2737", "#FFFFFF", 61),
                ("Barrow", "BRW", "Holker Street", 5045, "Barrow", "#0053A0", "#FFFFFF", 60),
                ("Grimsby Town", "GRI", "Blundell Park", 9052, "Cleethorpes", "#000000", "#FFFFFF", 60),
                ("Harrogate Town", "HAR", "Wetherby Road", 5000, "Harrogate", "#FFFF00", "#000000", 59),
                ("Accrington Stanley", "ACC", "Crown Ground", 5450, "Accrington", "#EE2737", "#FFFFFF", 60),
                ("Newport County", "NEW", "Rodney Parade", 7850, "Newport", "#FDB913", "#000000", 59),
                ("Colchester United", "COL", "Colchester Community Stadium", 10105, "Colchester", "#0053A0", "#FFFFFF", 60),
                ("Bromley", "BRO", "Hayes Lane", 5100, "London", "#FFFFFF", "#000000", 58),
                ("Carlisle United", "CAR", "Brunton Park", 17949, "Carlisle", "#0053A0", "#EE2737", 61),
                ("Fleetwood Town", "FLE", "Highbury Stadium", 5327, "Fleetwood", "#EE2737", "#FFFFFF", 61),
                ("Cheltenham Town", "CHL", "Whaddon Road", 7066, "Cheltenham", "#EE2737", "#FFFFFF", 60),
                ("Morecambe", "MOR", "Mazuma Stadium", 6476, "Morecambe", "#EE2737", "#000000", 59)
            ]
        default:
            // Non-English leagues are authored in JSON; the procedural fallback is empty.
            clubData = []
        }
        
        var clubIds: [UUID] = []
        for c in clubData {
            let squad = generateProceduralSquad(targetCount: 22, tier: tier)
            let finances = ClubFinances.defaultFor(tier: tier)
            let club = Club(
                name: c.name,
                shortName: c.short,
                stadium: c.stadium,
                stadiumCapacity: c.cap,
                city: c.city,
                primaryColor: c.c1,
                secondaryColor: c.c2,
                leagueTier: tier,
                reputation: c.rep,
                players: squad,
                manager: "Head Coach",
                finances: finances
            )
            clubs.append(club)
            clubIds.append(club.id)
        }
        
        let league = League(name: name, tier: tier, clubIds: clubIds)
        return (clubs, league)
    }
}
