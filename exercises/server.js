require('dotenv').config();
const express = require('express');
const mysql   = require('mysql2/promise');
const path    = require('path');

const app  = express();
const PORT = process.env.PORT || 3737;

// ── DB pool ──────────────────────────────────────────────────────────────────
const pool = mysql.createPool({
  host:            process.env.DB_HOST,
  user:            process.env.DB_USER,
  password:        process.env.DB_PASSWORD,
  database:        process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 5,
  connectTimeout:  10000,
});

// ── Static files (serves explorer.html) ──────────────────────────────────────
app.use(express.static(path.join(__dirname)));

// ── Helper: build WHERE clause from query params ──────────────────────────────
const FILTER_COLS = {
  organism:  'Organism',
  tissue:    'Tissue',
  stage:     'Stage',
  platform:  'platform',
  strategy:  'library_strategy',
  status:    'Status',
};

function buildWhere(query) {
  const clauses = [];
  const params  = [];
  for (const [key, col] of Object.entries(FILTER_COLS)) {
    if (query[key]) {
      clauses.push(`\`${col}\` = ?`);
      params.push(query[key]);
    }
  }
  if (query.search) {
    clauses.push('(SampleID LIKE ? OR SpecimenID LIKE ? OR Organism LIKE ?)');
    const s = `%${query.search}%`;
    params.push(s, s, s);
  }
  return { where: clauses.length ? 'WHERE ' + clauses.join(' AND ') : '', params };
}

// ── GET /api/samples — paginated, filtered, sorted ───────────────────────────
app.get('/api/samples', async (req, res) => {
  try {
    const page    = Math.max(1, parseInt(req.query.page)  || 1);
    const limit   = Math.min(200, parseInt(req.query.limit) || 25);
    const offset  = (page - 1) * limit;
    const { where, params } = buildWhere(req.query);

    const SAFE_COLS = new Set([
      'RefCode','SpecimenID','SampleID','Organism','Tissue','Stage',
      'Status','Provider','library_strategy','platform','instrument_model','SRA',
    ]);
    const sortCol = SAFE_COLS.has(req.query.sort) ? req.query.sort : 'RefCode';
    const sortDir = req.query.dir === 'desc' ? 'DESC' : 'ASC';

    const [rows]  = await pool.query(
      `SELECT RefCode, SpecimenID, SampleID, Organism, Tissue, Stage, Status,
              Provider, library_strategy, library_source, library_selection,
              library_layout, platform, instrument_model, technique, SRA,
              filename1, filename2, Comments
       FROM G_genomics ${where}
       ORDER BY \`${sortCol}\` ${sortDir}
       LIMIT ? OFFSET ?`,
      [...params, limit, offset]
    );

    const [[{ total }]] = await pool.query(
      `SELECT COUNT(*) AS total FROM G_genomics ${where}`, params
    );

    res.json({ total, page, limit, rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// ── GET /api/summary — aggregate stats for cards & charts ────────────────────
app.get('/api/summary', async (req, res) => {
  try {
    const { where, params } = buildWhere(req.query);

    const [[counts]] = await pool.query(
      `SELECT
         COUNT(*)                                    AS total,
         COUNT(DISTINCT SpecimenID)                  AS specimens,
         COUNT(DISTINCT Organism)                    AS species,
         COUNT(DISTINCT Tissue)                      AS tissues,
         SUM(SRA IS NOT NULL AND SRA != '')          AS with_sra
       FROM G_genomics ${where}`, params
    );

    const [byOrgTissue] = await pool.query(
      `SELECT Organism, Tissue, COUNT(*) AS n
       FROM G_genomics ${where}
       GROUP BY Organism, Tissue
       ORDER BY Organism, n DESC`, params
    );

    const [byPlatform] = await pool.query(
      `SELECT platform, COUNT(*) AS n
       FROM G_genomics ${where}
       GROUP BY platform ORDER BY n DESC`, params
    );

    const [byStrategy] = await pool.query(
      `SELECT library_strategy, COUNT(*) AS n
       FROM G_genomics ${where}
       GROUP BY library_strategy ORDER BY n DESC`, params
    );

    const [byStage] = await pool.query(
      `SELECT Stage, COUNT(*) AS n
       FROM G_genomics ${where}
       GROUP BY Stage ORDER BY n DESC`, params
    );

    const [byStatus] = await pool.query(
      `SELECT Status, COUNT(*) AS n
       FROM G_genomics ${where}
       GROUP BY Status`, params
    );

    res.json({ counts, byOrgTissue, byPlatform, byStrategy, byStage, byStatus });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// ── GET /api/filters — distinct values for dropdowns ─────────────────────────
app.get('/api/filters', async (req, res) => {
  try {
    const cols = { organism: 'Organism', tissue: 'Tissue', stage: 'Stage',
                   platform: 'platform', strategy: 'library_strategy', status: 'Status' };
    const result = {};
    for (const [key, col] of Object.entries(cols)) {
      const [rows] = await pool.query(
        `SELECT DISTINCT \`${col}\` AS v FROM G_genomics
         WHERE \`${col}\` IS NOT NULL AND \`${col}\` != ''
         ORDER BY \`${col}\``
      );
      result[key] = rows.map(r => r.v);
    }
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Start ─────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`Sample explorer → http://localhost:${PORT}/explorer.html`);
  console.log(`API             → http://localhost:${PORT}/api/samples`);
});
