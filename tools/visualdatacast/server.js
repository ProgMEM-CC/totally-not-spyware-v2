/*
 VisualDataCast server
 - Receives live frames (webp/jpg) and issue batches from a browser
 - Stores into sessions/<id> and, on stop, builds animated WebP + issues.json + zip

 Requirements:
 - node >= 14
 - npm i express multer body-parser
 - Optional tools on host for packaging output:
   - ffmpeg (to encode animated webp)
   - zip (to produce a zip bundle)
*/

const fs = require('fs');
const path = require('path');
const express = require('express');
const multer = require('multer');
const bodyParser = require('body-parser');
const { spawnSync } = require('child_process');

const app = express();

// Basic CORS for local capture across devices
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

app.use(bodyParser.json({ limit: '16mb' }));
const upload = multer({ limits: { fileSize: 16 * 1024 * 1024 } });

const ROOT = path.join(__dirname, 'sessions');
ensureDir(ROOT);

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function sanitizeId(id) {
  if (typeof id !== 'string') return '';
  return id.replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 64);
}

function listFramesSorted(framesDir) {
  if (!fs.existsSync(framesDir)) return [];
  return fs
    .readdirSync(framesDir)
    .filter((n) => n.endsWith('.webp') || n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.png'))
    .sort();
}

app.get('/vdc/health', (req, res) => {
  res.json({ ok: true, root: ROOT });
});

app.post('/vdc/start', (req, res) => {
  const meta = req.body && req.body.meta ? req.body.meta : {};
  const id = (
    Date.now().toString(36) + Math.random().toString(36).slice(2, 8)
  );
  const safeId = sanitizeId(id);
  const base = path.join(ROOT, safeId);
  ensureDir(path.join(base, 'frames'));
  fs.writeFileSync(
    path.join(base, 'meta.json'),
    JSON.stringify({ id: safeId, meta, started: new Date().toISOString() }, null, 2)
  );
  res.json({ id: safeId });
});

let frameSeqPerSession = new Map();

app.post('/vdc/frame', upload.single('frame'), (req, res) => {
  const id = sanitizeId(req.body && req.body.id);
  const ts = req.body && req.body.ts ? Number(req.body.ts) : Date.now();
  if (!id || !req.file) return res.status(400).end('missing id or frame');
  const base = path.join(ROOT, id, 'frames');
  ensureDir(base);

  const ext = req.file.mimetype === 'image/webp' ? 'webp' : (req.file.mimetype === 'image/png' ? 'png' : 'jpg');
  const seq = (frameSeqPerSession.get(id) || 0) + 1;
  frameSeqPerSession.set(id, seq);
  const name = `${String(ts)}_${String(seq).padStart(6, '0')}.${ext}`;
  fs.writeFileSync(path.join(base, name), req.file.buffer);
  res.json({ ok: true, saved: name });
});

app.post('/vdc/issues', (req, res) => {
  const id = sanitizeId(req.body && req.body.id);
  const issues = (req.body && (req.body.issues || req.body.issueBatch)) || [];
  const meta = (req.body && req.body.meta) || {};
  if (!id) return res.status(400).end('missing id');
  const file = path.join(ROOT, id, 'issues.jsonl');
  const line = JSON.stringify({ ts: Date.now(), issues, meta }) + '\n';
  fs.appendFileSync(file, line);
  res.json({ ok: true, count: Array.isArray(issues) ? issues.length : 1 });
});

app.get('/vdc/session/:id', (req, res) => {
  const id = sanitizeId(req.params.id);
  const base = path.join(ROOT, id);
  const meta = fs.existsSync(path.join(base, 'meta.json'))
    ? JSON.parse(fs.readFileSync(path.join(base, 'meta.json'), 'utf8'))
    : null;
  const frames = listFramesSorted(path.join(base, 'frames'));
  res.json({ id, meta, frames });
});

app.post('/vdc/stop', (req, res) => {
  const id = sanitizeId(req.body && req.body.id);
  if (!id) return res.status(400).end('missing id');
  const base = path.join(ROOT, id);
  const framesDir = path.join(base, 'frames');
  const outDir = path.join(base, 'out');
  ensureDir(outDir);

  // Collapse JSONL to JSON array
  const jsonl = path.join(base, 'issues.jsonl');
  const issuesOut = path.join(outDir, 'issues.json');
  if (fs.existsSync(jsonl)) {
    const arr = fs
      .readFileSync(jsonl, 'utf8')
      .trim()
      .split('\n')
      .filter(Boolean)
      .map((l) => JSON.parse(l));
    fs.writeFileSync(issuesOut, JSON.stringify(arr, null, 2));
  } else {
    fs.writeFileSync(issuesOut, '[]');
  }

  // Encode animated webp using ffmpeg if available
  const outWebp = path.join(outDir, `${id}.webp`);
  const frames = listFramesSorted(framesDir);
  let encoded = false;
  if (frames.length > 0) {
    // Prefer webp frames, fallback to jpg/png
    const hasWebp = frames.some((f) => f.endsWith('.webp'));
    const glob = hasWebp ? '*.webp' : (frames.some((f) => f.endsWith('.png')) ? '*.png' : '*.jpg');
    try {
      const r = spawnSync(
        'ffmpeg',
        [
          '-y',
          '-pattern_type',
          'glob',
          '-i',
          path.join(framesDir, glob),
          '-vf',
          'fps=10,scale=480:-1:flags=lanczos',
          '-loop',
          '0',
          '-c:v',
          'libwebp',
          '-q:v',
          '60',
          outWebp,
        ],
        { stdio: 'inherit' }
      );
      if (r.status === 0) encoded = true;
    } catch (e) {
      // ffmpeg missing or failed; leave frames as-is
    }
  }

  // Zip results if possible
  const zipPath = path.join(outDir, `${id}-visual-report.zip`);
  try {
    const filesToZip = ['issues.json'];
    if (encoded && fs.existsSync(outWebp)) filesToZip.push(path.basename(outWebp));
    const r = spawnSync('zip', ['-9', zipPath, ...filesToZip], { cwd: outDir, stdio: 'inherit' });
    if (r.status !== 0) {
      // zip tool not present; ignore
    }
  } catch (e) {
    // ignore
  }

  res.json({ ok: true, out: { issuesJson: issuesOut, webp: encoded ? outWebp : null, zip: fs.existsSync(zipPath) ? zipPath : null } });
});

const PORT = process.env.VDC_PORT ? Number(process.env.VDC_PORT) : 3344;
app.listen(PORT, () => {
  console.log(`VisualDataCast server listening on http://0.0.0.0:${PORT}`);
  console.log(`Sessions dir: ${ROOT}`);
});


