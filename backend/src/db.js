// node:sqlite is built into Node.js >= 22.5.0 (stable in Node 24).
// No native compilation needed — it ships as a bundled WASM module.
const { DatabaseSync } = require('node:sqlite');
const path = require('path');
const fs = require('fs');

// Store the DB in /app/data when running in Docker,
// or a local ./data directory during development.
const dataDir = process.env.DB_DIR || path.join(__dirname, '..', 'data');
fs.mkdirSync(dataDir, { recursive: true });
const DB_PATH = path.join(dataDir, 'scores.db');

const db = new DatabaseSync(DB_PATH);

// --- Schema ---
db.exec(`
  PRAGMA journal_mode = WAL;

  CREATE TABLE IF NOT EXISTS scores (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    username   TEXT    NOT NULL,
    score      INTEGER NOT NULL,
    created_at INTEGER NOT NULL
  );

  CREATE INDEX IF NOT EXISTS idx_scores_score ON scores (score DESC);

  CREATE TABLE IF NOT EXISTS sessions (
    token_id   TEXT    PRIMARY KEY,
    username   TEXT    NOT NULL,
    started_at INTEGER NOT NULL,
    used       INTEGER NOT NULL DEFAULT 0,
    expires_at INTEGER NOT NULL
  );
`);

// --- Prepared statements ---
// DatabaseSync.prepare() returns a statement object; call .run() or .get() / .all() on it.

const stmts = {
  insertSession: db.prepare(
    `INSERT INTO sessions (token_id, username, started_at, used, expires_at)
     VALUES (?, ?, ?, 0, ?)`
  ),

  getSession: db.prepare(
    `SELECT * FROM sessions WHERE token_id = ?`
  ),

  markSessionUsed: db.prepare(
    `UPDATE sessions SET used = 1 WHERE token_id = ?`
  ),

  insertScore: db.prepare(
    `INSERT INTO scores (username, score, created_at) VALUES (?, ?, ?)`
  ),

  getLeaderboard: db.prepare(
    `SELECT username, score, created_at FROM scores
     ORDER BY score DESC
     LIMIT ? OFFSET ?`
  ),

  countScores: db.prepare(
    `SELECT COUNT(*) AS total FROM scores`
  ),

  getRank: db.prepare(
    `SELECT COUNT(*) + 1 AS rank FROM scores WHERE score > ?`
  ),

  // Housekeeping: remove expired unused sessions
  pruneExpiredSessions: db.prepare(
    `DELETE FROM sessions WHERE expires_at < ? AND used = 0`
  ),
};

module.exports = { db, stmts };
