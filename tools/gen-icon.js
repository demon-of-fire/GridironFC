// Generates a 1024x1024 app icon PNG for GridironFC with no external dependencies.
// Uses a raw RGBA buffer encoded as a PNG (zlib via Node's built-in zlib).
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const SIZE = 1024;
const buf = Buffer.alloc(SIZE * SIZE * 4, 0);

function set(x, y, r, g, b, a = 255) {
  if (x < 0 || y < 0 || x >= SIZE || y >= SIZE) return;
  const i = (y * SIZE + x) * 4;
  buf[i] = r; buf[i + 1] = g; buf[i + 2] = b; buf[i + 3] = a;
}

// Blade-of-grass stripes background (dark green pitch).
function pitchColor(y) {
  const band = Math.floor(y / 128) % 2;
  return band === 0 ? [29, 100, 55] : [35, 117, 66];
}
for (let y = 0; y < SIZE; y++) {
  const [r, g, b] = pitchColor(y);
  for (let x = 0; x < SIZE; x++) set(x, y, r, g, b);
}

// Rounded-ish white border frame.
function drawLineRect(x0, y0, x1, y1, thickness, color) {
  const [r, g, b] = color;
  for (let y = y0; y <= y1; y++) {
    for (let x = x0; x <= x1; x++) {
      const onEdge = x < x0 + thickness || x > x1 - thickness || y < y0 + thickness || y > y1 - thickness;
      if (onEdge) set(x, y, r, g, b);
    }
  }
}

drawLineRect(70, 70, SIZE - 70, SIZE - 70, 14, [255, 255, 255]);

// Centre circle.
const cx = SIZE / 2, cy = SIZE / 2;
function circle(cx, cy, radius, thickness, color) {
  const [r, g, b] = color;
  for (let y = 0; y < SIZE; y++) {
    for (let x = 0; x < SIZE; x++) {
      const d = Math.hypot(x - cx, y - cy);
      if (d >= radius - thickness && d <= radius) set(x, y, r, g, b);
    }
  }
}
circle(cx, cy, 190, 14, [255, 255, 255]);
circle(cx, cy, 18, 18, [255, 255, 255]);

// Football (soccer ball): white disc with dark pentagon accents.
function filledCircle(cx, cy, radius, color) {
  const [r, g, b] = color;
  for (let y = 0; y < SIZE; y++) {
    for (let x = 0; x < SIZE; x++) {
      if (Math.hypot(x - cx, y - cy) <= radius) set(x, y, r, g, b);
    }
  }
}
filledCircle(cx, cy, 300, [250, 250, 250]);
// Simple dark patches to suggest panels.
function filledPoly(points, color) {
  const [r, g, b] = color;
  let minX = SIZE, maxX = 0, minY = SIZE, maxY = 0;
  for (const [x, y] of points) { minX = Math.min(minX, x); maxX = Math.max(maxX, x); minY = Math.min(minY, y); maxY = Math.max(maxY, y); }
  for (let y = Math.floor(minY); y <= Math.ceil(maxY); y++) {
    for (let x = Math.floor(minX); x <= Math.ceil(maxX); x++) {
      let inside = false;
      for (let i = 0, j = points.length - 1; i < points.length; j = i++) {
        const xi = points[i][0], yi = points[i][1];
        const xj = points[j][0], yj = points[j][1];
        if (((yi > y) !== (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) inside = !inside;
      }
      if (inside) set(x, y, r, g, b);
    }
  }
}
function pentagon(cx, cy, radius, rotation, color) {
  const pts = [];
  for (let i = 0; i < 5; i++) {
    const a = rotation + i * (Math.PI * 2 / 5);
    pts.push([cx + Math.cos(a) * radius, cy + Math.sin(a) * radius]);
  }
  filledPoly(pts, color);
}
const dark = [34, 34, 34];
pentagon(cx, cy, 95, -Math.PI / 2, dark);
pentagon(cx, cy - 190, 70, Math.PI / 2, dark);
pentagon(cx - 180, cy + 90, 70, Math.PI / 2 + 0.4, dark);
pentagon(cx + 180, cy + 90, 70, Math.PI / 2 - 0.4, dark);

// Encode PNG.
function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const typeBuf = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])) >>> 0, 0);
  return Buffer.concat([len, typeBuf, data, crc]);
}

let crcTable = null;
function crc32(buf) {
  if (!crcTable) {
    crcTable = [];
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      crcTable[n] = c >>> 0;
    }
  }
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = crcTable[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(SIZE, 0);
ihdr.writeUInt32BE(SIZE, 4);
ihdr[8] = 8;    // bit depth
ihdr[9] = 6;    // color type RGBA
ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;

// Add filter byte (0) at the start of each row.
const raw = Buffer.alloc(SIZE * (SIZE * 4 + 1));
for (let y = 0; y < SIZE; y++) {
  raw[y * (SIZE * 4 + 1)] = 0;
  buf.copy(raw, y * (SIZE * 4 + 1) + 1, y * SIZE * 4, (y + 1) * SIZE * 4);
}
const idat = zlib.deflateSync(raw, { level: 9 });

const png = Buffer.concat([sig, chunk('IHDR', ihdr), chunk('IDAT', idat), chunk('IEND', Buffer.alloc(0))]);

const out = path.join(__dirname, '..', 'GridironFC', 'Assets.xcassets', 'AppIcon.appiconset', 'icon-1024.png');
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, png);
console.log('Wrote', out, png.length, 'bytes');
