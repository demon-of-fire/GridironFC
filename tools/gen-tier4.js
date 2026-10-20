const fs = require('fs');

// League Two 2025-26 clubs: [name, starOverall, avgOverall, notable real stars as tuples]
const clubs = [
  { name: 'Notts County', hi: 68, mid: 59, stars: [['Macaulay', 'Langstaff', 'England', 29, ['ST'], 68, 68, 'right', { shooting: 72 }], ['Dan', 'Crowe', 'England', 26, ['LW', 'LM'], 64, 67, 'left']] },
  { name: 'Port Vale', hi: 67, mid: 58, stars: [['Ryan', 'Rydel', 'England', 25, ['LB', 'LWB'], 64, 68, 'left'], ['Conor', 'Grant', 'Ireland', 30, ['CM'], 65, 65, 'left']] },
  { name: 'Walsall', hi: 66, mid: 58, stars: [['Jamille', 'Matt', 'England', 31, ['ST'], 65, 65, 'right'], ['Tom', 'Knowles', 'England', 27, ['RM', 'RW'], 64, 66, 'right']] },
  { name: 'Chesterfield', hi: 66, mid: 58, stars: [['Tom', 'Naylor', 'England', 34, ['CDM', 'CM'], 64, 64, 'right'], ['Armando', 'Dobra', 'Albania', 24, ['CAM', 'LW'], 65, 70, 'right']] },
  { name: 'Milton Keynes Dons', hi: 66, mid: 57, stars: [['Mo', 'Eisa', 'Sudan', 31, ['ST'], 64, 64, 'right'], ['Conor', 'McGrandles', 'Scotland', 31, ['CM', 'CDM'], 63, 63, 'right']] },
  { name: 'Grimsby Town', hi: 64, mid: 56, stars: [['Jordan', 'Gnonto', 'England', 22, ['ST', 'RW'], 63, 70, 'right']] },
  { name: 'Gillingham', hi: 64, mid: 56, stars: [['Jonny', 'Williams', 'Wales', 32, ['CAM', 'CM'], 63, 63, 'right']] },
  { name: 'Morecambe', hi: 58, mid: 50, stars: [['Ged', 'Brannan', 'England', 36, ['CM', 'CDM'], 58, 58, 'right']] },
  { name: 'Tranmere Rovers', hi: 63, mid: 55, stars: [['Kane', 'Hemmings', 'England', 34, ['ST'], 62, 62, 'right']] },
  { name: 'Swindon Town', hi: 63, mid: 55, stars: [['Charlie', 'Austin', 'England', 36, ['ST'], 62, 62, 'right']] },
  { name: 'AFC Wimbledon', hi: 63, mid: 55, stars: [['James', 'Tilley', 'England', 27, ['CAM', 'LW'], 63, 65, 'left']] },
  { name: 'Carlisle United', hi: 62, mid: 54, stars: [['Josh', 'Vela', 'England', 31, ['CM', 'CDM'], 61, 61, 'right']] },
  { name: 'Colchester United', hi: 62, mid: 54, stars: [['Tom', 'Hopper', 'England', 31, ['ST'], 62, 62, 'right']] },
  { name: 'Crewe Alexandra', hi: 62, mid: 54, stars: [['Chris', 'Long', 'England', 31, ['ST'], 62, 62, 'right']] },
  { name: 'Newport County', hi: 62, mid: 54, stars: [['Bryce', 'Hosannah', 'England', 26, ['RB', 'RWB'], 61, 63, 'right']] },
  { name: 'Salford City', hi: 62, mid: 54, stars: [['Callum', 'Morton', 'England', 27, ['ST'], 62, 64, 'right']] },
  { name: 'Shrewsbury Town', hi: 61, mid: 53, stars: [['John', 'Marquis', 'England', 34, ['ST'], 61, 61, 'right']] },
  { name: 'Stevenage', hi: 61, mid: 53, stars: [['Charlie', 'Kirk', 'England', 28, ['LW', 'LM'], 62, 63, 'left']] },
  { name: 'Barrow', hi: 60, mid: 52, stars: [['Kian', 'Spence', 'England', 25, ['CM', 'CAM'], 61, 65, 'right']] },
  { name: 'Bromley', hi: 60, mid: 52, stars: [['Michael', 'Cheek', 'England', 33, ['ST'], 61, 61, 'right']] },
  { name: 'Accrington Stanley', hi: 60, mid: 52, stars: [['Jack', 'Nolan', 'England', 24, ['CAM', 'LW'], 61, 66, 'left']] },
  { name: 'Cheltenham Town', hi: 59, mid: 51, stars: [['Tom', 'Barnett', 'England', 26, ['CM'], 60, 62, 'right']] },
  { name: 'FC Halifax Town', hi: 59, mid: 51, stars: [['Millenic', 'Alli', 'England', 28, ['ST'], 60, 60, 'right']] },
  { name: 'Harrogate Town', hi: 59, mid: 51, stars: [['George', 'Thomason', 'England', 25, ['CDM', 'CM'], 60, 63, 'right']] },
];

const firstNames = ['Tom', 'Jack', 'Lewis', 'Josh', 'Connor', 'Tyler', 'Callum', 'Ryan', 'Charlie', 'Nathan', 'Kyle', 'Ben', 'Adam', 'Sam', 'Joe', 'Ollie', 'Elliot', 'Harvey', 'Kieran', 'Reece', 'Marcus', 'Daniel', 'Luke', 'Mason', 'Harry', 'Alfie', 'Freddie', 'Jacob', 'Jamie', 'Danny', 'Sean', 'Declan', 'Craig', 'Gareth', 'Owen', 'Craig', 'Rhys', 'Jordan', 'Ashley', 'Darren', 'Kai', 'Emerson', 'Zack', 'Liam', 'Brandon', 'Taylor', 'Cameron', 'Dylan', 'Morgan', 'Cody'];
const lastNames = ['Whitmore', 'Hartley', 'Pearce', 'Donnelly', 'Braithwaite', 'Fletcher', 'Worthington', 'Sutcliffe', 'Lever', 'Kelleher', 'Burgess', 'Rigby', 'Stanley', 'Ferrand', 'Dawson', 'Patterson', 'Grimshaw', 'Ashworth', 'Bamber', 'Chewins', 'Duxbury', 'Earnshaw', 'Fullerton', 'Glendon', 'Handley', 'Ince', 'Jefferies', 'Keeley', 'Lomax', 'McSheffrey', 'Naylor', 'Oswald', 'Pritchard', 'Quirk', 'Radcliffe', 'Standish', 'Threlfall', 'Underhill', 'Vickers', 'Waddington', 'Yates', 'Zammit', 'Ainsworth', 'Bellamy', 'Cairns', 'Doyle', 'Everton', 'Farrell', 'Gallagher', 'Hankin'];
const nations = ['England', 'England', 'England', 'England', 'England', 'England', 'England', 'England', 'Wales', 'Scotland', 'Ireland', 'Northern Ireland', 'Jamaica', 'Ghana', 'Nigeria', 'Ivory Coast', 'Australia', 'Ireland', 'Scotland', 'England'];
const defPos = [['CB'], ['CB'], ['CB', 'RB'], ['LB'], ['LB', 'LWB'], ['RB'], ['RB', 'RWB'], ['CB', 'CDM']];
const midPos = [['CM'], ['CM'], ['CM', 'CDM'], ['CDM'], ['CDM', 'CM'], ['CAM'], ['CAM', 'CM'], ['LM']];
const fwdPos = [['ST'], ['ST'], ['ST', 'LW'], ['LW'], ['RW'], ['RW', 'ST'], ['CF', 'ST'], ['LW', 'LM']];

let seed = 424242;
function rnd() { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; }
function pick(arr) { return arr[Math.floor(rnd() * arr.length)]; }
function shuffled(arr) { const a = arr.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1));[a[i], a[j]] = [a[j], a[i]]; } return a; }

const usedNames = new Set();
function makeName() {
  for (let t = 0; t < 50; t++) {
    const n = pick(firstNames) + '|' + pick(lastNames);
    if (!usedNames.has(n)) { usedNames.add(n); return n.split('|'); }
  }
  const n = pick(firstNames) + '|' + pick(lastNames) + Math.floor(rnd() * 90 + 10);
  usedNames.add(n);
  return n.split('|');
}
function ovrFor(hi, mid, rank) {
  if (rank === 0) return hi;
  if (rank < 6) return hi - 1 - Math.floor(rnd() * 2);
  if (rank < 14) return mid + 2 - Math.floor(rnd() * 3);
  return mid - 2 - Math.floor(rnd() * 4);
}
function ageFor() {
  const r = rnd();
  if (r < 0.15) return 18 + Math.floor(rnd() * 3);
  if (r < 0.75) return 23 + Math.floor(rnd() * 8);
  return 31 + Math.floor(rnd() * 6);
}
function potFor(age, ovr) {
  if (age <= 21) return Math.min(95, ovr + 5 + Math.floor(rnd() * 11));
  if (age <= 24) return ovr + 1 + Math.floor(rnd() * 6);
  return ovr + (rnd() < 0.2 ? 1 : 0);
}

const out = {};
for (const club of clubs) {
  const squad = [];
  club.stars.forEach((s) => { usedNames.add(s[0] + '|' + s[1]); squad.push(s); });
  // 3 GK
  for (let i = squad.filter((p) => p[4][0] === 'GK').length; i < 3; i++) {
    const [f, l] = makeName(); const o = ovrFor(club.hi - 6, club.mid - 5, 14 + i); const a = ageFor();
    squad.push([f, l, 'England', a, ['GK'], o, potFor(a, o), rnd() < 0.85 ? 'right' : 'left']);
  }
  // 8 DEF
  let n = squad.filter((p) => p[4].some((x) => ['CB', 'LB', 'RB', 'LWB', 'RWB'].includes(x))).length;
  const dp = shuffled(defPos);
  for (let i = 0; n < 8; i++, n++) {
    const [f, l] = makeName(); const o = ovrFor(club.hi - 2, club.mid, 6 + (i % 8)); const a = ageFor();
    squad.push([f, l, pick(nations), a, dp[i % dp.length], o, potFor(a, o), rnd() < 0.8 ? 'right' : 'left']);
  }
  // 7 MID
  n = squad.filter((p) => p[4].some((x) => ['CDM', 'CM', 'CAM', 'LM', 'RM'].includes(x))).length;
  const mp = shuffled(midPos);
  for (let i = 0; n < 7; i++, n++) {
    const [f, l] = makeName(); const o = ovrFor(club.hi - 1, club.mid + 1, 5 + (i % 7)); const a = ageFor();
    squad.push([f, l, pick(nations), a, mp[i % mp.length], o, potFor(a, o), rnd() < 0.8 ? 'right' : 'left']);
  }
  // 6 FW
  n = squad.filter((p) => p[4].some((x) => ['LW', 'RW', 'ST', 'CF'].includes(x))).length;
  const fp = shuffled(fwdPos);
  for (let i = 0; n < 6; i++, n++) {
    const [f, l] = makeName(); const o = ovrFor(club.hi, club.mid + 1, 4 + (i % 6)); const a = ageFor();
    squad.push([f, l, pick(nations), a, fp[i % fp.length], o, potFor(a, o), rnd() < 0.8 ? 'right' : 'left']);
  }
  while (squad.length < 24) {
    const [f, l] = makeName(); const o = ovrFor(club.hi - 3, club.mid - 2, 12); const a = ageFor();
    squad.push([f, l, pick(nations), a, pick(defPos.concat(midPos, fwdPos)), o, potFor(a, o), rnd() < 0.8 ? 'right' : 'left']);
  }
  out[club.name] = squad.slice(0, 24);
}

let text = 'module.exports = {\n';
for (const [club, players] of Object.entries(out)) {
  text += '  ' + JSON.stringify(club) + ': [\n';
  for (const p of players) {
    text += '    [' + p.map((v) => (Array.isArray(v) ? '[' + v.map((x) => JSON.stringify(x)).join(', ') + ']' : typeof v === 'object' ? JSON.stringify(v) : typeof v === 'string' ? JSON.stringify(v) : String(v))).join(', ') + '],\n';
  }
  text = text.replace(/,\n$/, '\n') + '  ],\n';
}
text = text.replace(/,\n$/, '\n') + '};\n';
fs.writeFileSync(require('path').join(__dirname, 'data', 'players-tier4.js'), text);
console.log('wrote tier4:', Object.keys(out).length, 'clubs');
