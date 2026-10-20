// Imports real top-flight clubs + squads from the local Transfermarkt DuckDB
// (davidcariboo/player-scores) and emits GridironFC/Data/Resources/tier<rawValue>.json
//
// rawValue = countryIndex*10 + level  (level 1 = top flight)
// Only top flights come from the DB; tiers 2-4 remain authored/procedural.
//
// Ratings are derived globally from market value (absolute log curve) and age.
const fs = require('fs');
const path = require('path');
const { DuckDBInstance } = require('@duckdb/node-api');

const DB = process.env.USERPROFILE + '\\Downloads\\transfermarkt-datasets.duckdb';
const OUT = path.join(__dirname, '..', 'GridironFC', 'Data', 'Resources');
const SEASON = '2026-27';
const DATA_SEASON = '2025';
const AGE_YEAR = 2026;

// Country ordering -> rawValue = index*10 + level. Indices 1-10 are the original
// shipped countries; 11-31 are appended (stable, never renumber existing ones).
const COUNTRIES = [
  { code: 'GB1', name: 'England',        division: 'Premier League',            index: 1,  clubCount: 20 },
  { code: 'ES1', name: 'Spain',          division: 'La Liga',                   index: 2,  clubCount: 20 },
  { code: 'IT1', name: 'Italy',          division: 'Serie A',                   index: 3,  clubCount: 20 },
  { code: 'L1',  name: 'Germany',        division: 'Bundesliga',                index: 4,  clubCount: 18 },
  { code: 'FR1', name: 'France',         division: 'Ligue 1',                   index: 5,  clubCount: 18 },
  { code: 'PO1', name: 'Portugal',       division: 'Primeira Liga',             index: 6,  clubCount: 18 },
  { code: 'NL1', name: 'Netherlands',    division: 'Eredivisie',                index: 7,  clubCount: 18 },
  { code: 'TR1', name: 'Türkiye',        division: 'Süper Lig',                 index: 8,  clubCount: 18 },
  { code: 'SC1', name: 'Scotland',       division: 'Scottish Premiership',      index: 9,  clubCount: 12 },
  { code: 'BE1', name: 'Belgium',        division: 'Belgian Pro League',        index: 10, clubCount: 16 },
  { code: 'ARG1', name: 'Argentina',     division: 'Liga Profesional',          index: 11, clubCount: 30 },
  { code: 'AUS1', name: 'Australia',     division: 'A-League',                  index: 12, clubCount: 12 },
  { code: 'A1',   name: 'Austria',       division: 'Austrian Bundesliga',       index: 13, clubCount: 12 },
  { code: 'BRA1', name: 'Brazil',        division: 'Brasileirão Série A',       index: 14, clubCount: 20 },
  { code: 'KR1',  name: 'Croatia',       division: 'SuperSport HNL',            index: 15, clubCount: 10 },
  { code: 'TS1',  name: 'Czech Republic',division: 'Chance Liga',               index: 16, clubCount: 16 },
  { code: 'DK1',  name: 'Denmark',       division: 'Superliga',                 index: 17, clubCount: 12 },
  { code: 'GR1',  name: 'Greece',        division: 'Super League Greece',       index: 18, clubCount: 14 },
  { code: 'JAP1', name: 'Japan',         division: 'J1 League',                 index: 19, clubCount: 20 },
  { code: 'RSK1', name: 'South Korea',   division: 'K League 1',                index: 20, clubCount: 12 },
  { code: 'MEX1', name: 'Mexico',        division: 'Liga MX',                   index: 21, clubCount: 18 },
  { code: 'NO1',  name: 'Norway',        division: 'Eliteserien',               index: 22, clubCount: 16 },
  { code: 'PL1',  name: 'Poland',        division: 'Ekstraklasa',               index: 23, clubCount: 18 },
  { code: 'RO1',  name: 'Romania',       division: 'SuperLiga',                 index: 24, clubCount: 16 },
  { code: 'RU1',  name: 'Russia',        division: 'Russian Premier League',    index: 25, clubCount: 16 },
  { code: 'SA1',  name: 'Saudi Arabia',  division: 'Saudi Pro League',          index: 26, clubCount: 18 },
  { code: 'SER1', name: 'Serbia',        division: 'Serbian SuperLiga',         index: 27, clubCount: 16 },
  { code: 'SE1',  name: 'Sweden',        division: 'Allsvenskan',               index: 28, clubCount: 16 },
  { code: 'C1',   name: 'Switzerland',   division: 'Swiss Super League',        index: 29, clubCount: 12 },
  { code: 'UKR1', name: 'Ukraine',       division: 'Ukrainian Premier League',  index: 30, clubCount: 16 },
  { code: 'MLS1', name: 'United States', division: 'Major League Soccer',       index: 31, clubCount: 30 },
];

// Position mapping: Transfermarkt position/sub_position -> GridironFC PositionCategory
// GridironFC Position codes: GK CB LB RB LWB RWB CDM CM CAM LM RM LW RW ST CF
const POS_BY_POSITION = {
  'Goalkeeper': 'GK',
  'Defender': 'CB',
  'Midfield': 'CM',
  'Attack': 'ST',
};
// Refine using sub_position where possible
const POS_BY_SUB = {
  'Goalkeeper': 'GK',
  'Centre-Back': 'CB', 'Left-Back': 'LB', 'Right-Back': 'RB',
  'Defensive Midfield': 'CDM', 'Central Midfield': 'CM', 'Attacking Midfield': 'CAM',
  'Left Midfield': 'LM', 'Right Midfield': 'RM',
  'Left Winger': 'LW', 'Right Winger': 'RW',
  'Centre-Forward': 'ST', 'Second Striker': 'CF', 'Striker': 'ST',
};

function posCode(position, subPosition) {
  if (position === 'Goalkeeper') return 'GK';
  if (subPosition && POS_BY_SUB[subPosition]) return POS_BY_SUB[subPosition];
  return POS_BY_POSITION[position] || 'CM';
}

// Global absolute rating from market value (EUR) + age.
// Higher of value-based and a small age bonus for youth; potential from age.
function ratingFromValue(value) {
  if (!value || value <= 0) return 55;
  const v = Math.max(10_000, Math.min(200_000_000, value));
  const val = 58 + 6.2 * Math.log(v / 500_000);
  return Math.max(42, Math.min(94, Math.round(val)));
}

function ageFromDOB(dob) {
  if (!dob) return 26;
  const d = new Date(dob);
  return Math.max(16, Math.min(42, AGE_YEAR - d.getUTCFullYear()));
}

function potentialFrom(overall, age) {
  let pot;
  if (age <= 21) pot = Math.min(95, overall + 12);
  else if (age <= 24) pot = Math.min(94, overall + 8);
  else if (age <= 27) pot = Math.min(93, overall + 4);
  else if (age <= 30) pot = Math.min(overall + 2, 92);
  else pot = overall;
  return Math.max(overall, pot);
}

function slug(s) {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}

(async () => {
  const inst = await DuckDBInstance.create(DB, { access_mode: 'READ_ONLY' });
  const conn = await inst.connect();
  fs.mkdirSync(OUT, { recursive: true });

  let totalClubs = 0, totalPlayers = 0, leaguesWritten = 0;

  for (const country of COUNTRIES) {
    const rawValue = country.index * 10 + 1;

    const clubRes = await conn.run(`
      SELECT club_id, name, stadium_name, stadium_seats, squad_size, average_age, coach_name
      FROM clubs
      WHERE domestic_competition_id = '${country.code}'
        AND last_season = '${DATA_SEASON}'
        AND squad_size IS NOT NULL
      ORDER BY total_market_value DESC NULLS LAST
      LIMIT ${country.clubCount}
    `);
    const clubRows = await clubRes.getRows();

    const clubs = [];
    for (const [clubId, name, stadium, seats, squadSize, avgAge, coach] of clubRows) {
      const playerRes = await conn.run(`
        SELECT first_name, last_name, name, position, sub_position, foot, date_of_birth,
               country_of_citizenship, market_value_in_eur
        FROM players
        WHERE current_club_id = '${clubId}' AND last_season = '${DATA_SEASON}' AND position <> 'Missing'
        ORDER BY market_value_in_eur DESC NULLS LAST
      `);
      const pRows = await playerRes.getRows();
      const limit = Math.max(18, Math.min(squadSize || 25, 30));

      const players = [];
      for (const p of pRows.slice(0, limit)) {
        const [firstName, lastName, fullName, position, subPosition, foot, dob, nationality, value] = p;
        const overall = ratingFromValue(value);
        const age = ageFromDOB(dob);
        const o = {
          firstName: firstName || (fullName || '').split(' ')[0] || 'Unknown',
          lastName: lastName || (fullName || '').split(' ').slice(1).join(' ') || fullName || 'Player',
          nationality: nationality || country.name,
          age,
          positions: [posCode(position, subPosition)],
          overall,
          potential: potentialFrom(overall, age),
        };
        if (foot === 'left' || foot === 'right') o.preferredFoot = foot;
        players.push(o);
      }
      totalPlayers += players.length;

      clubs.push({
        name,
        shortName: name.split(' ').map(w => w[0]).join('').slice(0, 3).toUpperCase() || slug(name).slice(0, 3).toUpperCase(),
        stadium: stadium || `${name} Stadium`,
        stadiumCapacity: seats || 15000,
        city: name.replace(/ (FC|AFC|SC|CF|AC|United|City)$/i, '').trim() || name,
        primaryColor: '#1B5E20',
        secondaryColor: '#FFFFFF',
        reputation: 70,
        manager: coach || 'Head Coach',
        budget: 0,
        wageBudget: 0,
        players,
      });
    }

    if (clubs.length === 0) continue;
    totalClubs += clubs.length;

    const league = { name: country.division, season: SEASON, tier: rawValue, clubs };
    fs.writeFileSync(path.join(OUT, `tier${rawValue}.json`), JSON.stringify(league));
    leaguesWritten++;
  }

  console.log(`import: ${leaguesWritten} leagues, ${totalClubs} clubs, ${totalPlayers} players`);
})();
