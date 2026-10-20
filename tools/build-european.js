// Emits GridironFC/Data/Resources/european_competitions.json listing the real
// participant clubs for each European competition, from the local Transfermarkt DB.
const fs = require('fs');
const path = require('path');
const { DuckDBInstance } = require('@duckdb/node-api');

const DB = process.env.USERPROFILE + '\\Downloads\\transfermarkt-datasets.duckdb';
const OUT = path.join(__dirname, '..', 'GridironFC', 'Data', 'Resources', 'european_competitions.json');

const COMPS = [
  { key: 'championsLeague', id: 'CL', name: 'UEFA Champions League', short: 'UCL', limit: 36 },
  { key: 'europaLeague', id: 'EL', name: 'UEFA Europa League', short: 'UEL', limit: 36 },
  { key: 'conferenceLeague', id: 'UCOL', name: 'UEFA Conference League', short: 'UECL', limit: 32 },
];

(async () => {
  const inst = await DuckDBInstance.create(DB, { access_mode: 'READ_ONLY' });
  const conn = await inst.connect();

  const competitions = [];
  for (const comp of COMPS) {
    const r = await conn.run(`
      SELECT c.name, MAX(c.total_market_value) AS mv
      FROM clubs c
      WHERE CAST(c.club_id AS VARCHAR) IN (
        SELECT CAST(home_club_id AS VARCHAR) FROM games WHERE competition_id='${comp.id}' AND season='2025'
        UNION SELECT CAST(away_club_id AS VARCHAR) FROM games WHERE competition_id='${comp.id}' AND season='2025'
      )
      GROUP BY c.name
      ORDER BY mv DESC NULLS LAST
    `);
    const rows = await r.getRows();
    const names = rows.map(x => x[0]).slice(0, comp.limit);
    competitions.push({ key: comp.key, name: comp.name, shortName: comp.short, clubNames: names });
    console.log(`${comp.name}: ${names.length} clubs`);
  }

  fs.writeFileSync(OUT, JSON.stringify({ competitions }, null, 0));
  console.log('wrote', OUT);
})();
