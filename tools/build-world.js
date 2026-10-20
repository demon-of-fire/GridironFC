// Emits GridironFC/Data/Resources/tier<rawValue>.json for every division in world-data.js.
// rawValue = countryIndex*10 + level  (england=1 -> ENG, ..., belgium=10 -> BEL)
const fs = require('fs');
const path = require('path');
const { world, squadFor, SEASON, resourcesDir } = require('./world-data.js');

const countries = ['ENG', 'ESP', 'ITA', 'GER', 'FRA', 'POR', 'NED', 'TUR', 'SCO', 'BEL'];
const divisionNames = {
  ENG: ['Premier League', 'Championship', 'League One', 'League Two'],
  ESP: ['La Liga', 'LaLiga 2', 'Primera Federación', 'Segunda Federación'],
  ITA: ['Serie A', 'Serie B', 'Serie C', 'Serie D'],
  GER: ['Bundesliga', '2. Bundesliga', '3. Liga', 'Regionalliga'],
  FRA: ['Ligue 1', 'Ligue 2', 'National', 'National 2'],
  POR: ['Primeira Liga', 'Liga Portugal 2', 'Liga 3', 'Campeonato de Portugal'],
  NED: ['Eredivisie', 'Eerste Divisie', 'Tweede Divisie', 'Derde Divisie'],
  TUR: ['Süper Lig', '1. Lig', '2. Lig', '3. Lig'],
  SCO: ['Scottish Premiership', 'Scottish Championship', 'Scottish League One', 'Scottish League Two'],
  BEL: ['Belgian Pro League', 'Challenger Pro League', 'Eerste Nationale', 'Tweede Nationale'],
};

fs.mkdirSync(resourcesDir, { recursive: true });

let written = 0;
let totalClubs = 0;
let totalPlayers = 0;

countries.forEach((code, ci) => {
  const countryIndex = ci + 1;
  for (let level = 1; level <= 4; level++) {
    const clubs = (world[code] && world[code][level]) || [];
    if (clubs.length === 0) continue; // omit divisions we have no data for yet

    const rawValue = countryIndex * 10 + level;
    const clubObjs = clubs.map(([name, short, stadium, capacity, city, c1, c2, rep, manager]) => {
      const rawSquad = squadFor(name);
      const players = rawSquad.map(([firstName, lastName, nationality, age, positions, overall, potential, foot, specialties]) => {
        const o = { firstName, lastName, nationality, age, positions, overall, potential };
        if (foot) o.preferredFoot = foot;
        if (specialties) o.specialties = specialties;
        return o;
      });
      totalPlayers += players.length;
      return {
        name, shortName: short, stadium, stadiumCapacity: capacity, city,
        primaryColor: c1, secondaryColor: c2, reputation: rep, manager,
        budget: 0, wageBudget: 0, players,
      };
    });

    const league = { name: divisionNames[code][level - 1], season: SEASON, tier: rawValue, clubs: clubObjs };
    const outFile = path.join(resourcesDir, `tier${rawValue}.json`);
    fs.writeFileSync(outFile, JSON.stringify(league));
    written++;
    totalClubs += clubObjs.length;
  }
});

console.log(`world build: ${written} divisions, ${totalClubs} clubs, ${totalPlayers} authored players`);
