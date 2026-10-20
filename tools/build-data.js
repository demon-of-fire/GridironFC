// Builds tier1.json..tier4.json into GridironFC/GridironFC/Data/Resources for the iOS bundle.
// Run: node tools/build-data.js
const fs = require('fs');
const path = require('path');

const SEASON = '2026-27';
const AGE_OFFSET = 1; // source rosters reflect the previous season; advance ages one year

// [name, shortName, stadium, capacity, city, primary, secondary, reputation, manager, budgetM, wageBudgetK, playersPerWeek]
const metadata = {
  1: [
    ['Arsenal', 'ARS', 'Emirates Stadium', 60704, 'London', '#EF0107', '#FFFFFF', 90, 'Mikel Arteta', 80, 1800],
    ['Aston Villa', 'AVL', 'Villa Park', 42682, 'Birmingham', '#670E36', '#95BFE5', 82, 'Unai Emery', 45, 1200],
    ['AFC Bournemouth', 'BOU', 'Vitality Stadium', 11307, 'Bournemouth', '#DA291C', '#000000', 76, 'Andoni Iraola', 25, 750],
    ['Brentford', 'BRE', 'Gtech Community Stadium', 17250, 'London', '#E30613', '#FFFFFF', 76, 'Keith Andrews', 30, 800],
    ['Brighton & Hove Albion', 'BHA', 'American Express Stadium', 31800, 'Brighton', '#0057B8', '#FFFFFF', 79, 'Fabian Hürzeler', 40, 950],
    ['Burnley', 'BUR', 'Turf Moor', 21944, 'Burnley', '#6C1D45', '#99D6EA', 72, 'Scott Parker', 18, 550],
    ['Chelsea', 'CHE', 'Stamford Bridge', 40341, 'London', '#034694', '#FFFFFF', 86, 'Enzo Maresca', 90, 2000],
    ['Crystal Palace', 'CRY', 'Selhurst Park', 25486, 'London', '#1B458F', '#A7A5A6', 78, 'Oliver Glasner', 30, 850],
    ['Everton', 'EVE', 'Hill Dickinson Stadium', 52888, 'Liverpool', '#003399', '#FFFFFF', 77, 'David Moyes', 25, 800],
    ['Fulham', 'FUL', 'Craven Cottage', 25700, 'London', '#FFFFFF', '#000000', 76, 'Marco Silva', 28, 800],
    ['Leeds United', 'LEE', 'Elland Road', 37890, 'Leeds', '#FFCD00', '#1D428A', 75, 'Daniel Farke', 30, 700],
    ['Liverpool', 'LIV', 'Anfield', 61276, 'Liverpool', '#C8102E', '#FFFFFF', 92, 'Arne Slot', 100, 2200],
    ['Manchester City', 'MCI', 'Etihad Stadium', 53400, 'Manchester', '#6CABDD', '#FFFFFF', 95, 'Pep Guardiola', 120, 2500],
    ['Manchester United', 'MUN', 'Old Trafford', 74310, 'Manchester', '#DA291C', '#FBE122', 87, 'Rúben Amorim', 95, 2100],
    ['Newcastle United', 'NEW', "St James' Park", 52305, 'Newcastle', '#241F20', '#FFFFFF', 84, 'Eddie Howe', 70, 1600],
    ['Nottingham Forest', 'NFO', 'City Ground', 30445, 'Nottingham', '#DD0000', '#FFFFFF', 77, 'Nuno Espírito Santo', 40, 900],
    ['Sunderland', 'SUN', 'Stadium of Light', 49000, 'Sunderland', '#EB172B', '#FFFFFF', 72, 'Régis Le Bris', 25, 600],
    ['Tottenham Hotspur', 'TOT', 'Tottenham Hotspur Stadium', 62850, 'London', '#132257', '#FFFFFF', 84, 'Thomas Frank', 75, 1800],
    ['West Ham United', 'WHU', 'London Stadium', 62500, 'London', '#7A263A', '#1BB1E7', 80, 'Graham Potter', 35, 1000],
    ['Wolverhampton Wanderers', 'WOL', 'Molineux Stadium', 31750, 'Wolverhampton', '#FDB913', '#231F20', 75, 'Vítor Pereira', 30, 750],
  ],
  2: [
    ['Birmingham City', 'BIR', "St Andrew's", 29409, 'Birmingham', '#0000FF', '#FFFFFF', 71, 'Chris Davies', 20, 450],
    ['Blackburn Rovers', 'BLA', 'Ewood Park', 31367, 'Blackburn', '#0053A0', '#FFFFFF', 68, 'John Eustace', 12, 320],
    ['Bristol City', 'BRC', 'Ashton Gate', 27000, 'Bristol', '#E1000F', '#FFFFFF', 66, 'Liam Manning', 10, 280],
    ['Charlton Athletic', 'CHA', 'The Valley', 27111, 'London', '#D71920', '#FFFFFF', 64, 'Nathan Jones', 8, 240],
    ['Coventry City', 'COV', 'Coventry Building Society Arena', 32609, 'Coventry', '#69B3E7', '#1B1B1B', 69, 'Frank Lampard', 14, 350],
    ['Derby County', 'DER', 'Pride Park Stadium', 32936, 'Derby', '#232323', '#FFFFFF', 67, 'John Eustace', 12, 320],
    ['Hull City', 'HUL', 'MKM Stadium', 25400, 'Kingston upon Hull', '#F5A623', '#1A1A1A', 65, 'Selim Ayaz', 8, 250],
    ['Ipswich Town', 'IPS', 'Portman Road', 29673, 'Ipswich', '#3A64A8', '#FFFFFF', 72, 'Kieran McKenna', 25, 500],
    ['Leicester City', 'LEI', 'King Power Stadium', 32262, 'Leicester', '#003090', '#FDBE11', 74, 'Steve Cooper', 22, 550],
    ['Middlesbrough', 'MID', 'Riverside Stadium', 34988, 'Middlesbrough', '#E11B22', '#FFFFFF', 69, 'Rob Edwards', 14, 350],
    ['Millwall', 'MIL', 'The Den', 20146, 'London', '#002D62', '#FFFFFF', 64, 'Alex Neil', 7, 220],
    ['Norwich City', 'NOR', 'Carrow Road', 27244, 'Norwich', '#FFF200', '#00A650', 68, 'Liam Manning', 12, 330],
    ['Oxford United', 'OXF', 'Kassam Stadium', 12500, 'Oxford', '#F9E547', '#000000', 61, 'Gary Rowett', 6, 180],
    ['Portsmouth', 'POR', 'Fratton Park', 20620, 'Portsmouth', '#0054A6', '#FFFFFF', 64, 'John Mousinho', 7, 220],
    ['Preston North End', 'PNE', 'Deepdale', 23500, 'Preston', '#FFFFFF', '#1A3C78', 64, 'Paul Heckingbottom', 7, 210],
    ['Queens Park Rangers', 'QPR', 'Loftus Road', 18439, 'London', '#00549D', '#FFFFFF', 65, 'Marti Cifuentes', 8, 240],
    ['Sheffield United', 'SHU', 'Bramall Lane', 32050, 'Sheffield', '#EE2737', '#FFFFFF', 70, 'Ruben Selles', 15, 380],
    ['Sheffield Wednesday', 'SHW', 'Hillsborough', 39732, 'Sheffield', '#0054A6', '#FFFFFF', 66, 'Danny Röhl', 10, 280],
    ['Southampton', 'SOU', "St Mary's Stadium", 32389, 'Southampton', '#D71920', '#FFFFFF', 72, 'Will Still', 20, 480],
    ['Stoke City', 'STK', 'Bet365 Stadium', 30089, 'Stoke-on-Trent', '#E03A3E', '#FFFFFF', 66, 'Mark Robins', 10, 290],
    ['Swansea City', 'SWA', 'Swansea.com Stadium', 21088, 'Swansea', '#FFFFFF', '#111111', 63, 'Alan Sheehan', 6, 200],
    ['Watford', 'WAT', 'Vicarage Road', 21500, 'Watford', '#Fbee23', '#ED2127', 65, 'Tom Cleverley', 9, 260],
    ['West Bromwich Albion', 'WBA', 'The Hawthorns', 26850, 'West Bromwich', '#122F67', '#FFFFFF', 66, 'Carlos Corberán', 10, 280],
    ['Wrexham', 'WRE', 'Racecourse Ground', 10771, 'Wrexham', '#E32636', '#FFFFFF', 63, 'Phil Parkinson', 12, 250],
  ],
  3: [
    ['Barnsley', 'BAR', 'Oakwell', 23288, 'Barnsley', '#D2122E', '#FFFFFF', 66, 'Darrell Clarke', 6, 160],
    ['Blackpool', 'BLA', 'Bloomfield Road', 16750, 'Blackpool', '#F57C1F', '#FFFFFF', 64, 'Steve Bruce', 5, 140],
    ['Bolton Wanderers', 'BOL', 'Toughsheet Community Stadium', 28723, 'Bolton', '#FFFFFF', '#1A3C78', 67, 'Ian Evatt', 7, 190],
    ['Bradford City', 'BRA', 'Valley Parade', 25136, 'Bradford', '#7E1E32', '#FCE300', 63, 'Graham Alexander', 5, 130],
    ['Bristol Rovers', 'BRO', 'Memorial Stadium', 12300, 'Bristol', '#002F5F', '#FFFFFF', 61, 'Inigo Calderá', 4, 110],
    ['Burton Albion', 'BUR', 'Pirelli Stadium', 6912, 'Burton upon Trent', '#000000', '#FCB517', 58, 'Gary Bowyer', 3, 90],
    ['Cambridge United', 'CAM', 'Abbey Stadium', 8127, 'Cambridge', '#FBE122', '#000000', 57, 'Neil Harris', 3, 85],
    ['Cardiff City', 'CAR', 'Cardiff City Stadium', 33288, 'Cardiff', '#0072B6', '#FFFFFF', 68, 'Brian Barry-Murphy', 8, 200],
    ['Crawley Town', 'CRA', 'Broadfield Stadium', 6134, 'Crawley', '#D2122E', '#FFFFFF', 55, 'Rob Elliott', 2, 70],
    ['Doncaster Rovers', 'DON', 'Eco-Power Stadium', 15231, 'Doncaster', '#D9292F', '#FFFFFF', 60, 'Grant McCann', 4, 105],
    ['Exeter City', 'EXE', 'St James Park', 8720, 'Exeter', '#D9292F', '#FFFFFF', 58, 'Gary Caldwell', 3, 90],
    ['Fleetwood Town', 'FLE', 'Highbury Stadium', 5327, 'Fleetwood', '#1B458F', '#FFFFFF', 56, 'Charlie Adam', 2, 75],
    ['Huddersfield Town', 'HUD', 'John Smith\'s Stadium', 24500, 'Huddersfield', '#0E63AD', '#FFFFFF', 65, 'Michael Duff', 6, 150],
    ['Leyton Orient', 'LEY', 'Brisbane Road', 9271, 'London', '#E32636', '#FFFFFF', 57, 'Richie Wellens', 3, 85],
    ['Lincoln City', 'LIN', 'Sincil Bank', 10120, 'Lincoln', '#FB2828', '#FFFFFF', 58, 'Michael Skubala', 3, 90],
    ['Luton Town', 'LUT', 'Kenilworth Road', 10356, 'Luton', '#F78F1E', '#002F5F', 64, 'Matt Bloomfield', 6, 150],
    ['Mansfield Town', 'MAN', 'Field Mill', 10000, 'Mansfield', '#F2C030', '#003E7E', 55, 'Nigel Clough', 2, 70],
    ['Northampton Town', 'NOR', 'Sixfields Stadium', 7793, 'Northampton', '#D9292F', '#FFFFFF', 57, 'Kevin Nolan', 3, 85],
    ['Peterborough United', 'PET', 'London Road', 15314, 'Peterborough', '#003090', '#FFFFFF', 63, 'Darren Ferguson', 5, 130],
    ['Plymouth Argyle', 'PLY', 'Home Park', 17900, 'Plymouth', '#004E34', '#F6D112', 62, 'Wayne Rooney', 5, 135],
    ['Reading', 'REA', 'Select Carleasing Stadium', 24161, 'Reading', '#1261A0', '#FFFFFF', 61, 'Noel Hunt', 4, 100],
    ['Rotherham United', 'ROT', 'New York Stadium', 12021, 'Rotherham', '#D9292F', '#FFFFFF', 58, 'Steve Evans', 3, 90],
    ['Stockport County', 'STO', 'Edgeley Park', 10841, 'Stockport', '#1B458F', '#FFFFFF', 60, 'Dave Challinor', 4, 105],
    ['Wycombe Wanderers', 'WYC', 'Adams Park', 10137, 'High Wycombe', '#1A3C78', '#FFFFFF', 59, 'Matt Bloomfield', 3, 90],
  ],
  4: [
    ['Accrington Stanley', 'ACC', 'Wham Stadium', 5057, 'Accrington', '#E32636', '#FFFFFF', 52, 'John Doolan', 1.2, 40],
    ['AFC Wimbledon', 'AFC', 'Plough Lane', 9215, 'London', '#0057B8', '#FFE500', 56, 'Steve Cotterill', 2, 60],
    ['Barrow', 'BAR', 'Holker Street', 5329, 'Barrow-in-Furness', '#7B2D8B', '#FFFFFF', 51, 'Steven Clemente', 1, 35],
    ['Bromley', 'BRO', 'Hayes Lane', 5000, 'London', '#000000', '#FFFFFF', 50, 'Andy Woodman', 1, 32],
    ['Carlisle United', 'CAR', 'Brunton Park', 18202, 'Carlisle', '#1B458F', '#FFFFFF', 54, 'Mark Hughes', 1.5, 48],
    ['Cheltenham Town', 'CHE', 'Whaddon Road', 7066, 'Cheltenham', '#1B458F', '#FFFFFF', 50, 'Michael Flynn', 1, 33],
    ['Chesterfield', 'CHS', 'SMH Group Stadium', 10504, 'Chesterfield', '#1A3C78', '#FFFFFF', 55, 'Paul Cook', 1.6, 50],
    ['Colchester United', 'COL', 'JobServe Community Stadium', 10000, 'Colchester', '#1B458F', '#FFFFFF', 51, 'Danny Cowley', 1.1, 37],
    ['Crewe Alexandra', 'CRE', 'Gresty Road', 10153, 'Crewe', '#D2122E', '#FFFFFF', 51, 'Bell Ingham', 1.1, 36],
    ['FC Halifax Town', 'FCH', 'The Shay', 10400, 'Halifax', '#0057B8', '#FFFFFF', 49, 'Jubril Okedina', 0.9, 30],
    ['Gillingham', 'GIL', 'Priestfield Stadium', 11582, 'Gillingham', '#0057B8', '#FFFFFF', 54, 'Stephen Clemente', 1.5, 48],
    ['Grimsby Town', 'GRI', 'Blundell Park', 9052, 'Cleethorpes', '#0057B8', '#FFFFFF', 52, 'David Artell', 1.2, 40],
    ['Harrogate Town', 'HAR', 'The EnviroVent Stadium', 5000, 'Harrogate', '#F6C90E', '#1A1A1A', 48, 'Simon Weaver', 0.8, 28],
    ['Milton Keynes Dons', 'MKD', 'Stadium MK', 30500, 'Milton Keynes', '#E32636', '#FFFFFF', 55, 'Mike Williamson', 1.8, 55],
    ['Morecambe', 'MOR', 'Mazuma Stadium', 6476, 'Morecambe', '#F5A623', '#000000', 47, 'Ged Brannan', 0.7, 25],
    ['Newport County', 'NEW', 'Rodney Parade', 9872, 'Newport', '#FDB913', '#000000', 51, 'Nelson Jardim', 1, 34],
    ['Notts County', 'NOC', 'Meadow Lane', 19588, 'Nottingham', '#1A1A1A', '#FFFFFF', 56, 'Stuart Maynard', 1.8, 55],
    ['Port Vale', 'PVL', 'Vale Park', 19052, 'Burslem', '#7B2D8B', '#FFFFFF', 54, 'Darren Moore', 1.5, 48],
    ['Salford City', 'SAL', 'Peninsula Stadium', 5106, 'Salford', '#D2122E', '#FFFFFF', 52, 'Karl Robinson', 1.4, 45],
    ['Shrewsbury Town', 'SHR', 'The Croud Meadow', 9875, 'Shrewsbury', '#0057B8', '#FFE500', 50, 'Paul Hurst', 1, 33],
    ['Stevenage', 'STE', 'Lamex Stadium', 7800, 'Stevenage', '#E32636', '#FFFFFF', 51, 'Alex Revell', 1.1, 36],
    ['Swindon Town', 'SWI', 'County Ground', 15728, 'Swindon', '#D2122E', '#FFFFFF', 51, 'Ian Holloway', 1.2, 40],
    ['Tranmere Rovers', 'TRA', 'Prenton Park', 16587, 'Birkenhead', '#FFFFFF', '#1A3C78', 52, 'Adrian Heath', 1.2, 40],
    ['Walsall', 'WAL', 'Bescot Stadium', 11300, 'Walsall', '#FFFFFF', '#000000', 54, 'Mat Sadler', 1.5, 48],
  ],
};

const resourcesDir = path.join(__dirname, '..', 'GridironFC', 'Data', 'Resources');
fs.mkdirSync(resourcesDir, { recursive: true });

let grand = 0;
for (const tier of [1, 2, 3, 4]) {
  const squads = require(path.join(__dirname, 'data', `players-tier${tier}.js`));
  const clubs = [];
  for (const [name, shortName, stadium, capacity, city, primaryColor, secondaryColor, reputation, manager, budget, wageBudget] of metadata[tier]) {
    const players = squads[name];
    if (!players) throw new Error(`tier${tier}: missing squad for ${name}`);
    const playerObjs = players.map(([firstName, lastName, nationality, age, positions, overall, potential, foot, specialties]) => {
      const o = { firstName, lastName, nationality, age: age + AGE_OFFSET, positions, overall, potential };
      if (foot) o.preferredFoot = foot;
      if (specialties) o.specialties = specialties;
      return o;
    });
    grand += playerObjs.length;
    clubs.push({
      name, shortName, stadium, stadiumCapacity: capacity, city, primaryColor, secondaryColor,
      reputation, manager, budget: Math.round(budget * 1_000_000), wageBudget: Math.round(wageBudget * 1_000), players: playerObjs,
    });
  }
  const league = {
    name: tier === 1 ? 'Premier League' : tier === 2 ? 'EFL Championship' : tier === 3 ? 'League One' : 'League Two',
    season: SEASON,
    tier,
    clubs,
  };
  const outFile = path.join(resourcesDir, `tier${tier}.json`);
  fs.writeFileSync(outFile, JSON.stringify(league));
  console.log(`tier${tier}.json: ${clubs.length} clubs, ${clubs.reduce((s, c) => s + c.players.length, 0)} players`);
}
console.log(`total players: ${grand}`);
