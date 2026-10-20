// Builds national_teams.json for GridironFC.
//
// The Transfermarkt DB's `current_national_team_id` linkage is incomplete/unreliable
// (many big nations have no linked players, while small nations have inflated squads).
// Instead we assemble each national squad from the REAL club players already imported,
// grouped by nationality, and enrich with DB national-team metadata (confederation,
// FIFA ranking, coach) where the country name matches.
const fs = require('fs');
const path = require('path');
const { DuckDBInstance } = require('@duckdb/node-api');

const DB = process.env.USERPROFILE + '\\Downloads\\transfermarkt-datasets.duckdb';
const OUT = path.join(__dirname, '..', 'GridironFC', 'Data', 'Resources');
const DATA_SEASON = '2025';
const SQUAD_LIMIT = 26;

// Normalise DB team names to the nationality strings used by the club importer.
function normName(s) {
  if (!s) return '';
  return s
    .replace(/\u00a0/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/^Korea, South$/i, 'Korea, South')
    .replace(/^South Korea$/i, 'Korea, South')
    .replace(/^USA$/i, 'United States')
    .replace(/^United States of America$/i, 'United States')
    .replace(/^Cote d'Ivoire$/i, "Cote d'Ivoire")
    .replace(/^Ivory Coast$/i, "Cote d'Ivoire")
    .replace(/^Czechia$/i, 'Czech Republic')
    .replace(/^Turkiye$/i, 'Türkiye')
    .replace(/^Republic of Ireland$/i, 'Ireland')
    .replace(/^Hong Kong$/i, 'Hongkong');
}

(async () => {
  const inst = await DuckDBInstance.create(DB, { access_mode: 'READ_ONLY' });
  const conn = await inst.connect();

  // 1. Metadata keyed by national team name.
  const metaRes = await conn.run(`
    SELECT name, country_code, confederation, fifa_ranking, coach_name
    FROM national_teams
    WHERE last_season = '${DATA_SEASON}' AND confederation IS NOT NULL
      AND name NOT ILIKE '%women%' AND name NOT ILIKE '%olympic%'
      AND name NOT ILIKE 'U1%' AND name NOT ILIKE 'U2%'
  `);
  const metaRows = await metaRes.getRows();
  const metaByName = new Map();
  for (const [name, code, conf, ranking, coach] of metaRows) {
    metaByName.set(normName(name), {
      countryCode: code || null,
      confederation: conf,
      fifaRanking: ranking != null ? Number(ranking) : null,
      coach: coach || null,
    });
  }

  // 2. Collect every real player from all imported tier JSONs, grouped by nationality.
  const tierFiles = fs.readdirSync(OUT).filter(f => /^tier\d+\.json$/.test(f));
  const byNationality = new Map();
  const seen = new Set(); // dedupe identical players across clubs

  for (const file of tierFiles) {
    const data = JSON.parse(fs.readFileSync(path.join(OUT, file), 'utf8'));
    for (const club of data.clubs) {
      for (const p of club.players) {
        const nat = normName(p.nationality);
        if (!nat) continue;
        const key = `${p.firstName}|${p.lastName}|${p.age}`;
        if (seen.has(key)) continue;
        seen.add(key);
        if (!byNationality.has(nat)) byNationality.set(nat, []);
        byNationality.get(nat).push({
          firstName: p.firstName,
          lastName: p.lastName,
          nationality: nat,
          age: p.age,
          positions: p.positions,
          overall: p.overall,
          potential: p.potential,
          ...(p.preferredFoot ? { preferredFoot: p.preferredFoot } : {}),
        });
      }
    }
  }

  // 3. Build teams (skip nationalities with too few players for a squad).
  const teams = [];
  for (const [nat, players] of byNationality) {
    if (players.length < 14) continue;
    // Prefer higher-rated, then younger.
    players.sort((a, b) => b.overall - a.overall || a.age - b.age);
    const squad = players.slice(0, SQUAD_LIMIT);
    const meta = metaByName.get(nat) || {};
    teams.push({
      id: nat.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
      name: nat,
      countryCode: meta.countryCode || null,
      confederation: meta.confederation || 'UEFA',
      fifaRanking: meta.fifaRanking ?? null,
      coach: meta.coach || null,
      players: squad,
    });
  }

  // Rank order: by FIFA ranking if present (best first), else alphabetical.
  teams.sort((a, b) => {
    if (a.fifaRanking != null && b.fifaRanking != null) return a.fifaRanking - b.fifaRanking;
    if (a.fifaRanking != null) return -1;
    if (b.fifaRanking != null) return 1;
    return a.name.localeCompare(b.name);
  });

  fs.writeFileSync(path.join(OUT, 'national_teams.json'), JSON.stringify({ teams }));
  const byConf = {};
  for (const t of teams) byConf[t.confederation] = (byConf[t.confederation] || 0) + 1;
  console.log(`national-teams: ${teams.length} teams, ${teams.reduce((s, t) => s + t.players.length, 0)} players`);
  console.log('by confederation:', JSON.stringify(byConf));
  console.log('top 12:', teams.slice(0, 12).map(t => `${t.name}(${t.players.length})`).join(', '));
})().catch(e => console.error('ERR', e));
