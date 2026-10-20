// European top-flight league definitions for GridironFC (Stage 2).
// Outputs tier5.json (La Liga), tier6.json (Serie A), tier7.json (Bundesliga), tier8.json (Ligue 1).
// Run: node tools/build-europe.js
//
// Club metadata: [name, shortName, stadium, capacity, city, primary, secondary, reputation, manager, budgetM, wageBudgetK]
// Players live in tools/data/players-europe.js keyed by club name.
const fs = require('fs');
const path = require('path');

const SEASON = '2026-27';
const AGE_OFFSET = 1;

const metadata = {
  5: [
    ['Real Madrid', 'RMA', 'Santiago Bernabéu', 81044, 'Madrid', '#FFFFFF', '#FEBE10', 96, 'Xabi Alonso', 200, 4000],
    ['FC Barcelona', 'BAR', 'Spotify Camp Nou', 99354, 'Barcelona', '#A50044', '#004D98', 94, 'Hansi Flick', 120, 3200],
    ['Atlético Madrid', 'ATM', 'Riyadh Air Metropolitano', 70460, 'Madrid', '#CB3524', '#FFFFFF', 88, 'Diego Simeone', 80, 2400],
    ['Athletic Club', 'ATH', 'San Mamés', 53289, 'Bilbao', '#EE2523', '#FFFFFF', 82, 'Ernesto Valverde', 40, 1300],
    ['Villarreal', 'VIL', 'Estadio de la Cerámica', 23500, 'Villarreal', '#FFE667', '#005187', 80, 'Marcelino', 35, 1100],
    ['Real Sociedad', 'RSO', 'Reale Arena', 39500, 'San Sebastián', '#0067B1', '#FFFFFF', 79, 'Sergio Francisco', 35, 1150],
    ['Real Betis', 'BET', 'Benito Villamarín', 60721, 'Seville', '#00954C', '#FFFFFF', 79, 'Manuel Pellegrini', 35, 1200],
    ['Sevilla', 'SEV', 'Ramón Sánchez-Pizjuán', 43883, 'Seville', '#FFFFFF', '#D80027', 78, 'Matías Almeyda', 30, 1100],
    ['Valencia', 'VAL', 'Mestalla', 49430, 'Valencia', '#FFFFFF', '#F18E00', 78, 'Carlos Corberán', 30, 1050],
    ['Girona', 'GIR', 'Montilivi', 14624, 'Girona', '#CD2534', '#FFFFFF', 76, 'Míchel', 25, 850],
    ['Celta Vigo', 'CEL', 'Abanca-Balaídos', 29000, 'Vigo', '#8AC3EE', '#FFFFFF', 75, 'Claudio Giráldez', 20, 750],
    ['Rayo Vallecano', 'RAY', 'Estadio de Vallecas', 14708, 'Madrid', '#FFFFFF', '#E53027', 74, 'Íñigo Pérez', 15, 650],
    ['Osasuna', 'OSA', 'El Sadar', 23576, 'Pamplona', '#D91A21', '#0A346F', 74, 'Alessio Lisci', 15, 650],
    ['Getafe', 'GET', 'Coliseum', 17393, 'Getafe', '#005999', '#FFFFFF', 73, 'José Bordalás', 15, 620],
    ['Mallorca', 'MLL', 'Son Moix', 23142, 'Palma', '#E20613', '#000000', 73, 'Jagoba Arrasate', 15, 650],
    ['Alavés', 'ALA', 'Mendizorroza', 19840, 'Vitoria-Gasteiz', '#0761AF', '#FFFFFF', 72, 'Eduardo Coudet', 12, 560],
    ['Espanyol', 'ESP', 'RCDE Stadium', 40000, 'Barcelona', '#FFFFFF', '#0072CE', 72, 'Manolo González', 12, 560],
    ['Real Oviedo', 'OVI', 'Carlos Tartiere', 30500, 'Oviedo', '#0A4FA3', '#FFFFFF', 70, 'Luis Carrión', 10, 500],
    ['Levante', 'LEV', 'Ciutat de València', 26354, 'Valencia', '#004B9D', '#B4053F', 70, 'Julián Calero', 10, 480],
    ['Elche', 'ELC', 'Martínez Valero', 31388, 'Elche', '#FFFFFF', '#00913F', 69, 'Eder Sarabia', 8, 450],
  ],
  6: [
    ['Inter Milan', 'INT', 'San Siro', 75923, 'Milan', '#0068A8', '#000000', 90, 'Cristian Chivu', 80, 2600],
    ['Napoli', 'NAP', 'Diego Armando Maradona', 54726, 'Naples', '#12A0D7', '#FFFFFF', 89, 'Antonio Conte', 70, 2500],
    ['AC Milan', 'MIL', 'San Siro', 75923, 'Milan', '#FB090B', '#000000', 88, 'Massimiliano Allegri', 70, 2400],
    ['Juventus', 'JUV', 'Allianz Stadium', 41507, 'Turin', '#000000', '#FFFFFF', 87, 'Luciano Spalletti', 65, 2200],
    ['Atalanta', 'ATA', 'Gewiss Stadium', 24950, 'Bergamo', '#1D2951', '#FFFFFF', 84, 'Ivan Jurić', 45, 1500],
    ['AS Roma', 'ROM', 'Stadio Olimpico', 70634, 'Rome', '#8E1F2F', '#F0BC42', 84, 'Gian Piero Gasperini', 45, 1700],
    ['Lazio', 'LAZ', 'Stadio Olimpico', 70634, 'Rome', '#87D8F7', '#FFFFFF', 82, 'Maurizio Sarri', 35, 1400],
    ['Fiorentina', 'FIO', 'Artemio Franchi', 43147, 'Florence', '#592C82', '#FFFFFF', 81, 'Stefano Pioli', 35, 1300],
    ['Bologna', 'BOL', 'Renato Dall\'Ara', 36462, 'Bologna', '#1A2F48', '#A21C25', 80, 'Vincenzo Italiano', 30, 1200],
    ['Torino', 'TOR', 'Olimpico Grande Torino', 28177, 'Turin', '#88121A', '#FFFFFF', 77, 'Marco Baroni', 20, 850],
    ['Udinese', 'UDI', 'Bluenergy Stadium', 25144, 'Udine', '#000000', '#FFFFFF', 76, 'Kosta Runjaić', 18, 780],
    ['Genoa', 'GEN', 'Luigi Ferraris', 33205, 'Genoa', '#A21C25', '#1A2F5A', 75, 'Patrick Vieira', 15, 700],
    ['Como', 'COM', 'Giuseppe Sinigaglia', 13602, 'Como', '#005CA9', '#FFFFFF', 74, 'Cesc Fàbregas', 15, 700],
    ['Cagliari', 'CAG', 'Unipol Domus', 16416, 'Cagliari', '#B50E12', '#1A2F5A', 73, 'Fabio Pisacane', 12, 600],
    ['Sassuolo', 'SAS', 'Mapei Stadium', 21584, 'Reggio Emilia', '#00A752', '#000000', 73, 'Fabio Grosso', 12, 620],
    ['Parma', 'PAR', 'Ennio Tardini', 22359, 'Parma', '#FFE500', '#005CA9', 72, 'Carlos Cuesta', 12, 560],
    ['Lecce', 'LEC', 'Via del Mare', 31533, 'Lecce', '#F2C60C', '#D8151C', 71, 'Eusebio Di Francesco', 10, 520],
    ['Hellas Verona', 'VER', 'Marcantonio Bentegodi', 39211, 'Verona', '#1D2951', '#F2C60C', 71, 'Paolo Zanetti', 10, 520],
    ['Pisa', 'PIS', 'Arena Garibaldi', 25000, 'Pisa', '#1A2F5A', '#FFFFFF', 69, 'Alberto Gilardino', 8, 450],
    ['Cremonese', 'CRM', 'Giovanni Zini', 20641, 'Cremona', '#A21C25', '#B9B9B9', 69, 'Davide Nicola', 8, 440],
  ],
  7: [
    ['Bayern Munich', 'FCB', 'Allianz Arena', 75024, 'Munich', '#DC052D', '#FFFFFF', 96, 'Vincent Kompany', 120, 3200],
    ['Bayer Leverkusen', 'B04', 'BayArena', 30210, 'Leverkusen', '#E32221', '#000000', 87, 'Kasper Hjulmand', 60, 2000],
    ['Borussia Dortmund', 'BVB', 'Signal Iduna Park', 81365, 'Dortmund', '#FDE100', '#000000', 87, 'Niko Kovač', 60, 2000],
    ['RB Leipzig', 'RBL', 'Red Bull Arena', 47069, 'Leipzig', '#DD0741', '#FFFFFF', 85, 'Ole Werner', 55, 1900],
    ['Eintracht Frankfurt', 'SGE', 'Deutsche Bank Park', 58000, 'Frankfurt', '#E1000F', '#000000', 83, 'Dino Toppmöller', 40, 1500],
    ['VfB Stuttgart', 'VFB', 'MHPArena', 60449, 'Stuttgart', '#FFFFFF', '#E32219', 83, 'Sebastian Hoeneß', 40, 1500],
    ['SC Freiburg', 'SCF', 'Europa-Park Stadion', 34700, 'Freiburg', '#000000', '#E1000F', 80, 'Julian Schuster', 25, 1000],
    ['Borussia Mönchengladbach', 'BMG', 'Borussia-Park', 54042, 'Mönchengladbach', '#FFFFFF', '#000000', 80, 'Gerardo Seoane', 25, 1100],
    ['VfL Wolfsburg', 'WOB', 'Volkswagen Arena', 30000, 'Wolfsburg', '#65B32E', '#FFFFFF', 79, 'Paul Simonis', 30, 1200],
    ['1899 Hoffenheim', 'TSG', 'PreZero Arena', 30150, 'Sinsheim', '#1C63B7', '#FFFFFF', 78, 'Christian Ilzer', 25, 1000],
    ['Werder Bremen', 'SVW', 'Weserstadion', 42100, 'Bremen', '#1D9053', '#FFFFFF', 78, 'Horst Steffen', 20, 880],
    ['FC Augsburg', 'FCA', 'WWK Arena', 30660, 'Augsburg', '#BA3733', '#FFFFFF', 76, 'Sandro Wagner', 18, 760],
    ['1. FC Union Berlin', 'FCU', 'An der Alten Försterei', 22012, 'Berlin', '#EB1923', '#F7C800', 77, 'Steffen Baumgart', 18, 780],
    ['1. FSV Mainz 05', 'M05', 'Mewa Arena', 33305, 'Mainz', '#C3141E', '#FFFFFF', 76, 'Bo Henriksen', 15, 700],
    ['FC St. Pauli', 'STP', 'Millerntor-Stadion', 29546, 'Hamburg', '#663300', '#FFFFFF', 74, 'Alexander Blessin', 12, 560],
    ['1. FC Köln', 'KOE', 'RheinEnergieStadion', 50000, 'Cologne', '#FFFFFF', '#ED1C24', 76, 'Lukas Kwasniok', 15, 720],
    ['Hamburger SV', 'HSV', 'Volksparkstadion', 57000, 'Hamburg', '#FFFFFF', '#0A5CA8', 76, 'Merlin Polzin', 15, 720],
    ['1. FC Heidenheim', 'HDH', 'Voith-Arena', 15000, 'Heidenheim', '#E30613', '#003A80', 72, 'Frank Schmidt', 10, 480],
  ],
  8: [
    ['Paris Saint-Germain', 'PSG', 'Parc des Princes', 47929, 'Paris', '#004170', '#DA291C', 95, 'Luis Enrique', 150, 3500],
    ['Olympique de Marseille', 'OM', 'Orange Vélodrome', 67394, 'Marseille', '#FFFFFF', '#2FAEE0', 84, 'Roberto De Zerbi', 50, 1600],
    ['AS Monaco', 'ASM', 'Stade Louis II', 18523, 'Monaco', '#E63329', '#FFFFFF', 84, 'Sébastien Pocognoli', 55, 1700],
    ['Olympique Lyonnais', 'OL', 'Groupama Stadium', 59186, 'Lyon', '#FFFFFF', '#1D4E9B', 82, 'Paulo Fonseca', 35, 1300],
    ['LOSC Lille', 'LIL', 'Stade Pierre-Mauroy', 50186, 'Lille', '#E01E13', '#FFFFFF', 82, 'Bruno Génésio', 35, 1300],
    ['RC Lens', 'RCL', 'Stade Bollaert-Delelis', 38223, 'Lens', '#F6C800', '#E30613', 81, 'Pierre Sage', 30, 1100],
    ['OGC Nice', 'NIC', 'Allianz Riviera', 35624, 'Nice', '#E30613', '#000000', 80, 'Franck Haise', 30, 1100],
    ['Stade Rennais', 'REN', 'Roazhon Park', 29778, 'Rennes', '#E30613', '#000000', 80, 'Habib Beye', 30, 1100],
    ['RC Strasbourg', 'STR', 'Stade de la Meinau', 26109, 'Strasbourg', '#005CA9', '#FFFFFF', 78, 'Liam Rosenior', 20, 850],
    ['Toulouse FC', 'TFC', 'Stadium de Toulouse', 33150, 'Toulouse', '#663399', '#FFFFFF', 77, 'Carles Martínez Novell', 18, 780],
    ['Stade Brestois', 'BRE', 'Stade Francis-Le Blé', 15931, 'Brest', '#E30613', '#FFFFFF', 76, 'Eric Roy', 15, 680],
    ['Auxerre', 'AJA', 'Stade Abbé-Deschamps', 18541, 'Auxerre', '#FFFFFF', '#005CA9', 75, 'Christophe Pélissier', 15, 650],
    ['FC Nantes', 'NAN', 'Stade de la Beaujoire', 38128, 'Nantes', '#FCD200', '#008C45', 75, 'Luis Castro', 15, 680],
    ['Angers SCO', 'SCO', 'Stade Raymond Kopa', 18752, 'Angers', '#000000', '#FFFFFF', 74, 'Alexandre Dujeux', 12, 560],
    ['Le Havre AC', 'HAC', 'Stade Océane', 25278, 'Le Havre', '#005CA9', '#8BC53F', 73, 'Didier Digard', 10, 520],
    ['FC Metz', 'MET', 'Stade Saint-Symphorien', 30000, 'Metz', '#7B0033', '#FFFFFF', 73, 'Stéphane Le Mignan', 10, 520],
    ['FC Lorient', 'FCL', 'Stade du Moustoir', 18110, 'Lorient', '#F7A800', '#00693E', 72, 'Olivier Pantaloni', 10, 500],
    ['Paris FC', 'PFC', 'Stade Jean-Bouin', 20000, 'Paris', '#005A9C', '#FFFFFF', 72, 'Stéphane Gilli', 10, 500],
  ],
};

const resourcesDir = path.join(__dirname, '..', 'GridironFC', 'Data', 'Resources');
fs.mkdirSync(resourcesDir, { recursive: true });

const squads = require(path.join(__dirname, 'data', 'players-europe.js'));

const leagueNameByTier = { 5: 'La Liga', 6: 'Serie A', 7: 'Bundesliga', 8: 'Ligue 1' };

let grand = 0;
for (const tier of [5, 6, 7, 8]) {
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
  const league = { name: leagueNameByTier[tier], season: SEASON, tier, clubs };
  const outFile = path.join(resourcesDir, `tier${tier}.json`);
  fs.writeFileSync(outFile, JSON.stringify(league));
  console.log(`tier${tier}.json (${leagueNameByTier[tier]}): ${clubs.length} clubs, ${clubs.reduce((s, c) => s + c.players.length, 0)} players`);
}
console.log(`total European players: ${grand}`);
