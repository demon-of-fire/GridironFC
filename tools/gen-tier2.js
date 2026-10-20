const fs = require('fs');
const path = require('path');

// Championship 2025-26: hi = star rating ceiling, mid = squad-average band
const clubs = [
  { name: 'Leicester City', hi: 79, mid: 70, stars: [
    ['Marcus', 'Rashford', 'England', 28, ['LW', 'ST'], 79, 79, 'right', { dribbling: 84, pace: 86 }],
    ['Mads', 'Hermansen', 'Denmark', 25, ['GK'], 76, 80, 'right'],
    ['Wilfred', 'Ndidi', 'Nigeria', 28, ['CDM', 'CM'], 76, 76, 'right'],
    ['Abdul', 'Fatawu', 'Ghana', 21, ['RW', 'RM'], 74, 83, 'left'],
    ['Harry', 'Winks', 'England', 29, ['CM', 'CDM'], 75, 75, 'right'],
  ] },
  { name: 'Ipswich Town', hi: 78, mid: 70, stars: [
    ['Liam', 'Delap', 'England', 22, ['ST'], 78, 85, 'right', { shooting: 80 }],
    ['Omari', 'Hutchinson', 'England', 22, ['RW', 'CAM'], 72, 80, 'left'],
    ['Julio', 'Enciso', 'Paraguay', 22, ['ST', 'RW'], 73, 81, 'left'],
    ['Jacob', 'Greaves', 'England', 25, ['CB', 'LB'], 68, 72, 'left'],
    ['Leif', 'Davis', 'England', 26, ['LB', 'LWB'], 73, 76, 'left'],
  ] },
  { name: 'Southampton', hi: 77, mid: 70, stars: [
    ['Aaron', 'Ramsdale', 'England', 28, ['GK'], 77, 78, 'right'],
    ['Tyler', 'Dibling', 'England', 19, ['RW', 'CAM'], 70, 82, 'left'],
    ['Flynn', 'Downes', 'England', 27, ['CDM', 'CM'], 73, 75, 'right'],
    ['Cameron', 'Archer', 'England', 23, ['ST'], 71, 78, 'right'],
    ['Lesley', 'Ugochukwu', 'France', 21, ['CDM', 'CM'], 70, 79, 'right'],
  ] },
  { name: 'Birmingham City', hi: 74, mid: 68, stars: [
    ['Jay', 'Stansfield', 'England', 22, ['ST'], 72, 80, 'right', { shooting: 74 }],
    ['Demarai', 'Gray', 'England', 29, ['LW', 'RW'], 71, 71, 'right'],
    ['Krystian', 'Bielik', 'Poland', 27, ['CB', 'CDM'], 70, 72, 'right'],
    ['Willum', 'Willumsson', 'Iceland', 27, ['CAM', 'RW'], 68, 70, 'left'],
    ['Marc', 'Leonard', 'Scotland', 24, ['CM', 'CDM'], 67, 73, 'right'],
  ] },
  { name: 'Middlesbrough', hi: 74, mid: 68, stars: [
    ['Riley', 'McGree', 'Australia', 27, ['LM', 'CAM'], 70, 71, 'left'],
    ['Hayden', 'Hackney', 'England', 23, ['CM', 'CDM'], 71, 79, 'right'],
    ['Finn', 'Azaz', 'England', 25, ['CAM', 'LW'], 70, 74, 'right'],
    ['Tommy', 'Conway', 'Scotland', 23, ['ST'], 70, 77, 'left'],
    ['Rav', 'van den Berg', 'Netherlands', 20, ['CB', 'LB'], 69, 80, 'right'],
  ] },
  { name: 'Coventry City', hi: 74, mid: 67, stars: [
    ['Jack', 'Rudoni', 'England', 24, ['LM', 'CM'], 70, 76, 'left'],
    ['Haji', 'Wright', 'United States', 27, ['ST', 'LW'], 70, 71, 'left'],
    ['Tatsuhiro', 'Sakamoto', 'Japan', 28, ['RW', 'LW'], 70, 71, 'right'],
    ['Ben', 'Sheaf', 'England', 28, ['CM', 'CDM'], 69, 70, 'right'],
    ['Milan', 'van Ewijk', 'Netherlands', 25, ['RB', 'RWB'], 68, 71, 'right'],
  ] },
  { name: 'Sheffield United', hi: 74, mid: 68, stars: [
    ['Gustavo', 'Hamer', 'Netherlands', 28, ['CM', 'CAM'], 72, 73, 'left'],
    ['Anel', 'Ahmedhodzic', 'Bosnia', 26, ['CB'], 73, 76, 'right'],
    ['Tyrese', 'Campbell', 'England', 25, ['ST', 'LW'], 71, 76, 'right'],
    ['Jesurun', 'Rak-Sakyi', 'England', 23, ['RW', 'LW'], 71, 78, 'right'],
    ['Michael', 'Cooper', 'England', 26, ['GK'], 73, 78, 'right'],
  ] },
  { name: 'West Bromwich Albion', hi: 72, mid: 66, stars: [
    ['Karlan', 'Grant', 'England', 28, ['ST', 'LW'], 69, 70, 'left'],
    ['Josh', 'Maja', 'Nigeria', 27, ['ST'], 70, 72, 'right'],
    ['John', 'Swift', 'England', 30, ['CM', 'CAM'], 70, 70, 'right'],
    ['Okay', 'Yokuslu', 'Turkey', 31, ['CDM', 'CM'], 70, 70, 'right'],
    ['Dara', 'O\'Shea', 'Ireland', 26, ['CB'], 72, 74, 'right'],
  ] },
  { name: 'Norwich City', hi: 73, mid: 67, stars: [
    ['Gabriel', 'Sara', 'Brazil', 25, ['CM', 'CAM'], 72, 77, 'right'],
    ['Josh', 'Sargent', 'United States', 25, ['ST'], 73, 77, 'right'],
    ['Borja', 'Sainz', 'Spain', 25, ['LW', 'LM'], 71, 75, 'left'],
    ['Marcelino', 'Nunez', 'Chile', 25, ['CAM', 'LW'], 69, 73, 'left'],
    ['Adam', 'Idah', 'Ireland', 24, ['ST'], 69, 76, 'right'],
  ] },
  { name: 'Watford', hi: 73, mid: 66, stars: [
    ['Yaser', 'Asprilla', 'Colombia', 22, ['RW', 'CAM'], 70, 79, 'left'],
    ['Ismael', 'Koné', 'Canada', 23, ['CM', 'LM'], 68, 75, 'left'],
    ['Imrân', 'Louza', 'Morocco', 26, ['CM', 'CAM'], 70, 74, 'left'],
    ['Matheus', 'França', 'Brazil', 21, ['ST', 'CAM'], 67, 76, 'right'],
    ['Kwadwo', 'Baah', 'Ghana', 22, ['RW', 'LW'], 66, 73, 'right'],
  ] },
  { name: 'Bristol City', hi: 71, mid: 65, stars: [
    ['Jason', 'Knight', 'Ireland', 24, ['CM', 'CDM'], 70, 76, 'right'],
    ['Tom', 'Conway', 'Scotland', 23, ['ST'], 70, 76, 'left'],
    ['Yu', 'Hirakawa', 'Japan', 24, ['RW', 'LW'], 69, 75, 'right'],
    ['Anis', 'Mehmeti', 'Albania', 24, ['LW', 'LM'], 68, 73, 'left'],
    ['Scott', 'Twine', 'England', 26, ['CAM', 'LW'], 68, 71, 'left'],
  ] },
  { name: 'Swansea City', hi: 70, mid: 64, stars: [
    ['Matt', 'Grimes', 'England', 30, ['CM', 'CDM'], 69, 69, 'left'],
    ['Eom', 'Ji-sung', 'South Korea', 25, ['ST', 'LW'], 66, 70, 'left'],
    ['Ben', 'Cabango', 'Wales', 25, ['CB'], 68, 73, 'right'],
    ['Ollie', 'Cooper', 'Wales', 23, ['CM', 'CAM'], 66, 72, 'right'],
    ['Ben', 'Cabrera', 'Argentina', 24, ['LW', 'LM'], 65, 71, 'left'],
  ] },
  { name: 'Preston North End', hi: 70, mid: 64, stars: [
    ['Tom', 'Cannon', 'Ireland', 23, ['ST'], 68, 75, 'right'],
    ['Milutin', 'Osmajic', 'Montenegro', 26, ['ST'], 68, 71, 'left'],
    ['Ben', 'Whiteman', 'England', 29, ['CM', 'CDM'], 68, 69, 'right'],
    ['Alan', 'Browne', 'Ireland', 30, ['CM', 'CAM'], 68, 68, 'right'],
    ['Joe', 'Rodon', 'Wales', 28, ['CB'], 69, 70, 'right'],
  ] },
  { name: 'Queens Park Rangers', hi: 71, mid: 65, stars: [
    ['Lucas', 'Borges', 'Portugal', 23, ['LM', 'CM'], 66, 74, 'left'],
    ['Sam', 'Field', 'England', 28, ['CM', 'CDM'], 68, 69, 'left'],
    ['Jimmy', 'Dunne', 'Ireland', 28, ['CB', 'CDM'], 66, 67, 'right'],
    ['Hamzed', 'Chermiti', 'Tunisia', 21, ['ST'], 64, 72, 'right'],
    ['Kieran', 'Morgan', 'Wales', 19, ['CAM', 'CM'], 60, 72, 'right'],
  ] },
  { name: 'Derby County', hi: 70, mid: 64, stars: [
    ['Jacob', 'Zetterström', 'Sweden', 26, ['GK'], 69, 72, 'right'],
    ['Ebou', 'Adams', 'Gambia', 25, ['CDM', 'CM'], 67, 71, 'left'],
    ['Nathaniel', 'Mendez-Laing', 'Guatemala', 33, ['RW', 'LW'], 64, 64, 'right'],
    ['Conor', 'Hourihane', 'Ireland', 35, ['CM', 'CAM'], 64, 64, 'left'],
    ['Cyrus', 'Christie', 'Ireland', 33, ['RB', 'RWB'], 65, 65, 'right'],
  ] },
  { name: 'Hull City', hi: 72, mid: 65, stars: [
    ['Jaden', 'Philogene', 'England', 23, ['LW', 'RW'], 73, 80, 'right'],
    ['Alex', 'Scott', 'England', 22, ['CM', 'CAM'], 70, 78, 'right'],
    ['Tyler', 'Morton', 'England', 23, ['CM', 'CDM'], 69, 77, 'right'],
    ['Abdülkadir', 'Ömür', 'Turkey', 27, ['CAM', 'RW'], 67, 68, 'right'],
    ['Liam', 'Millar', 'Canada', 26, ['LW', 'LM'], 67, 69, 'left'],
  ] },
  { name: 'Charlton Athletic', hi: 72, mid: 65, stars: [
    ['Mika', 'Biereth', 'Denmark', 21, ['ST'], 69, 80, 'right'],
    ['Tyler', 'Adams', 'United States', 27, ['CDM', 'CM'], 72, 73, 'right'],
    ['Harry', 'Anderson', 'England', 28, ['RW', 'RM'], 65, 66, 'right'],
    ['Jack', 'Payne', 'England', 31, ['CAM', 'CM'], 66, 66, 'right'],
    ['Alex', 'Gilbey', 'England', 31, ['CM', 'CAM'], 66, 66, 'right'],
  ] },
  { name: 'Oxford United', hi: 70, mid: 64, stars: [
    ['Sammie', 'Szmodics', 'Ireland', 30, ['ST', 'CAM'], 68, 68, 'right'],
    ['Siriki', 'Dembélé', 'Ivory Coast', 29, ['LW', 'ST'], 67, 68, 'right'],
    ['Cameron', 'Branagan', 'England', 29, ['CM', 'CDM'], 67, 67, 'left'],
    ['Tyler', 'Goodrham', 'England', 22, ['CAM', 'RW'], 64, 72, 'right'],
    ['Ibrahim', 'Sulemana', 'Ghana', 23, ['CDM', 'CM'], 65, 72, 'right'],
  ] },
  { name: 'Portsmouth', hi: 70, mid: 64, stars: [
    ['Colby', 'Bishop', 'England', 28, ['ST'], 67, 68, 'right'],
    ['Josh', 'Murphy', 'England', 31, ['LW', 'LM'], 66, 66, 'left'],
    ['Sam', 'Silvera', 'Australia', 25, ['RW', 'ST'], 65, 69, 'right'],
    ['Reeco', 'Hackett', 'England', 28, ['CAM', 'RM'], 65, 66, 'left'],
    ['Conor', 'Shaughnessy', 'Ireland', 29, ['CB', 'CDM'], 66, 66, 'right'],
  ] },
  { name: 'Blackburn Rovers', hi: 71, mid: 65, stars: [
    ['Tyrhys', 'Dolan', 'England', 24, ['LW', 'CAM'], 67, 72, 'right'],
    ['Dilan', 'Markanday', 'England', 24, ['RW', 'LW'], 66, 72, 'right'],
    ['Harry', 'Leonard', 'England', 21, ['ST'], 66, 75, 'left'],
    ['Dominic', 'Hyam', 'Scotland', 30, ['CB'], 68, 68, 'right'],
    ['Lewis', 'Travis', 'England', 28, ['CDM', 'CM'], 66, 66, 'right'],
  ] },
  { name: 'Stoke City', hi: 71, mid: 65, stars: [
    ['Bae', 'Jun-ho', 'South Korea', 23, ['CAM', 'RW'], 70, 78, 'right', { dribbling: 74 }],
    ['Wouter', 'Burger', 'Netherlands', 25, ['CM', 'CDM'], 67, 71, 'right'],
    ['Jes', 'Rak-Sakyi', 'England', 22, ['RW', 'LW'], 67, 74, 'right'],
    ['Ash', 'Phillips', 'Wales', 20, ['CB'], 66, 76, 'right'],
    ['Emre', 'Tezgel', 'England', 19, ['ST'], 63, 76, 'right'],
  ] },
  { name: 'Wrexham', hi: 70, mid: 64, stars: [
    ['Paul', 'Mullin', 'England', 30, ['ST'], 68, 68, 'right'],
    ['Elliot', 'Lee', 'England', 30, ['CAM', 'CM'], 67, 67, 'right'],
    ['Arthur', 'Okonkwo', 'England', 24, ['GK'], 69, 75, 'right'],
    ['James', 'McClean', 'Ireland', 36, ['LM', 'LWB'], 64, 64, 'left'],
    ['Ryan', 'Barnett', 'England', 26, ['RB', 'RWB'], 66, 68, 'right'],
  ] },
  { name: 'Sheffield Wednesday', hi: 71, mid: 65, stars: [
    ['Callum', 'Paterson', 'Scotland', 31, ['ST', 'CB'], 66, 66, 'right'],
    ['Barry', 'Bannan', 'Scotland', 36, ['CM', 'CAM'], 66, 66, 'left'],
    ['Josh', 'Windass', 'England', 32, ['CAM', 'ST'], 65, 65, 'right'],
    ['Ayo', 'Obileye', 'England', 26, ['CB'], 64, 68, 'right'],
    ['Liam', 'Palmer', 'Scotland', 34, ['RB', 'CB'], 63, 63, 'right'],
  ] },
  { name: 'Millwall', hi: 70, mid: 64, stars: [
    ['Mihailo', 'Ivanović', 'Serbia', 26, ['ST'], 68, 70, 'right'],
    ['Ryan', 'Longstaff', 'England', 29, ['CM', 'CAM'], 65, 65, 'right'],
    ['Shaun', 'Hutchinson', 'Scotland', 35, ['CB'], 64, 64, 'right'],
    ['Billy', 'Mitchell', 'England', 24, ['CM', 'CDM'], 64, 68, 'right'],
    ['Casper', 'de Norre', 'Belgium', 29, ['LB', 'LWB'], 64, 65, 'left'],
  ] },
];

const firstNames = ['Tom', 'Jack', 'Lewis', 'Josh', 'Connor', 'Tyler', 'Callum', 'Ryan', 'Charlie', 'Nathan', 'Kyle', 'Ben', 'Adam', 'Sam', 'Joe', 'Ollie', 'Elliot', 'Harvey', 'Kieran', 'Reece', 'Marcus', 'Daniel', 'Luke', 'Mason', 'Harry', 'Alfie', 'Freddie', 'Jacob', 'Jamie', 'Danny', 'Sean', 'Declan', 'Craig', 'Gareth', 'Owen', 'Rhys', 'Jordan', 'Ashley', 'Darren', 'Kai', 'Emerson', 'Liam', 'Brandon', 'Taylor', 'Cameron', 'Dylan', 'Morgan', 'Cody', 'Jaden', 'Kayden'];
const lastNames = ['Whitmore', 'Hartley', 'Pearce', 'Donnelly', 'Braithwaite', 'Fletcher', 'Worthington', 'Sutcliffe', 'Lever', 'Kelleher', 'Burgess', 'Rigby', 'Stanley', 'Ferrand', 'Dawson', 'Patterson', 'Grimshaw', 'Ashworth', 'Bamber', 'Duxbury', 'Earnshaw', 'Fullerton', 'Glendon', 'Handley', 'Ince', 'Jefferies', 'Keeley', 'Lomax', 'McSheffrey', 'Naylor', 'Oswald', 'Pritchard', 'Quirk', 'Radcliffe', 'Standish', 'Threlfall', 'Underhill', 'Vickers', 'Waddington', 'Yates', 'Ainsworth', 'Bellamy', 'Cairns', 'Doyle', 'Farrell', 'Gallagher', 'Hankin', 'Lambert', 'Murrell', 'Oakes'];
const nations = ['England', 'England', 'England', 'England', 'England', 'England', 'England', 'Wales', 'Scotland', 'Ireland', 'Northern Ireland', 'Jamaica', 'Ghana', 'Nigeria', 'Ivory Coast', 'Australia', 'France', 'Netherlands', 'Portugal', 'Spain', 'Brazil', 'Denmark', 'Belgium'];
const defPos = [['CB'], ['CB'], ['CB', 'RB'], ['LB'], ['LB', 'LWB'], ['RB'], ['RB', 'RWB'], ['CB', 'CDM']];
const midPos = [['CM'], ['CM'], ['CM', 'CDM'], ['CDM'], ['CDM', 'CM'], ['CAM'], ['CAM', 'CM'], ['LM'], ['RM']];
const fwdPos = [['ST'], ['ST'], ['ST', 'LW'], ['LW'], ['RW'], ['RW', 'ST'], ['CF', 'ST'], ['LW', 'LM']];

let seed = 999001;
function rnd() { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; }
function pick(arr) { return arr[Math.floor(rnd() * arr.length)]; }
function shuffled(arr) { const a = arr.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1));[a[i], a[j]] = [a[j], a[i]]; } return a; }

const usedNames = new Set();
function makeName() {
  for (let t = 0; t < 60; t++) {
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
  if (r < 0.14) return 18 + Math.floor(rnd() * 3);
  if (r < 0.78) return 22 + Math.floor(rnd() * 9);
  return 31 + Math.floor(rnd() * 6);
}
function potFor(age, ovr) {
  if (age <= 21) return Math.min(93, ovr + 5 + Math.floor(rnd() * 11));
  if (age <= 24) return ovr + 1 + Math.floor(rnd() * 6);
  return ovr + (rnd() < 0.15 ? 1 : 0);
}

const out = {};
for (const club of clubs) {
  const squad = [];
  for (const s of club.stars) { usedNames.add(s[0] + '|' + s[1]); squad.push(s); }
  const countPos = (pred) => squad.filter((p) => p[4].some(pred)).length;
  for (let i = countPos((x) => x === 'GK'); i < 3; i++) {
    const [f, l] = makeName(); const o = ovrFor(club.hi - 8, club.mid - 6, 16 + i); const a = ageFor();
    squad.push([f, l, 'England', a, ['GK'], o, potFor(a, o), rnd() < 0.85 ? 'right' : 'left']);
  }
  const dp = shuffled(defPos);
  for (let i = countPos((x) => ['CB', 'LB', 'RB', 'LWB', 'RWB'].includes(x)); i < 8;) {
    const [f, l] = makeName(); const o = ovrFor(club.hi - 4, club.mid, 8 + (i % 8)); const a = ageFor();
    squad.push([f, l, pick(nations), a, dp[i % dp.length], o, potFor(a, o), rnd() < 0.8 ? 'right' : 'left']); i++;
  }
  const mp = shuffled(midPos);
  for (let i = countPos((x) => ['CDM', 'CM', 'CAM', 'LM', 'RM'].includes(x)); i < 7;) {
    const [f, l] = makeName(); const o = ovrFor(club.hi - 3, club.mid + 1, 6 + (i % 7)); const a = ageFor();
    squad.push([f, l, pick(nations), a, mp[i % mp.length], o, potFor(a, o), rnd() < 0.8 ? 'right' : 'left']); i++;
  }
  const fp = shuffled(fwdPos);
  for (let i = countPos((x) => ['LW', 'RW', 'ST', 'CF'].includes(x)); i < 6;) {
    const [f, l] = makeName(); const o = ovrFor(club.hi - 1, club.mid + 1, 5 + (i % 6)); const a = ageFor();
    squad.push([f, l, pick(nations), a, fp[i % fp.length], o, potFor(a, o), rnd() < 0.8 ? 'right' : 'left']); i++;
  }
  while (squad.length < 24) {
    const [f, l] = makeName(); const o = ovrFor(club.hi - 5, club.mid - 2, 13); const a = ageFor();
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
fs.writeFileSync(path.join(__dirname, 'data', 'players-tier2.js'), text);
console.log('wrote tier2:', Object.keys(out).length, 'clubs');
