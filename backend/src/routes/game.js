const express = require('express');
const jwt = require('jsonwebtoken');
const { randomUUID } = require('crypto');
const { stmts } = require('../db');

const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET;
const SCORE_CAP = parseInt(process.env.SCORE_CAP || '50000', 10);
// Grace buffer in seconds: allows for network/client latency
const GRACE_SECONDS = 10;
// Session TTL: 2 hours in seconds
const SESSION_TTL = 2 * 60 * 60;

// Validates a username string: non-empty, max 32 chars, printable characters only
function validateUsername(username) {
  if (typeof username !== 'string') return false;
  const trimmed = username.trim();
  if (trimmed.length === 0 || trimmed.length > 32) return false;
  // Allow letters, numbers, spaces, underscores, hyphens
  return /^[\w\- ]+$/.test(trimmed);
}

// POST /game/start
// Body: { username: string }
// Response: { token: string, startedAt: number }
router.post('/start', (req, res) => {
  const { username } = req.body;

  if (!validateUsername(username)) {
    return res.status(400).json({
      error: 'Invalid username. Use 1–32 characters: letters, numbers, spaces, _ or -.',
    });
  }

  const cleanName = username.trim();
  const now = Date.now();
  const expiresAt = Math.floor(now / 1000) + SESSION_TTL;
  const tokenId = randomUUID();

  const payload = {
    jti: tokenId,
    username: cleanName,
    startedAt: now,
  };

  const token = jwt.sign(payload, JWT_SECRET, { expiresIn: SESSION_TTL });

  // Persist session so we can validate it on /end
  stmts.insertSession.run(tokenId, cleanName, now, expiresAt);

  return res.status(200).json({ token, startedAt: now });
});

// POST /game/end
// Body: { token: string, score: number }
// Response: { success: true, rank: number }
router.post('/end', (req, res) => {
  const { token, score } = req.body;

  // --- 1. Basic type checks ---
  if (typeof token !== 'string' || token.trim() === '') {
    return res.status(400).json({ error: 'Missing or invalid token.' });
  }

  const scoreInt = parseInt(score, 10);
  if (isNaN(scoreInt) || scoreInt < 0) {
    return res.status(400).json({ error: 'Score must be a non-negative integer.' });
  }

  // --- 2. Verify JWT signature & expiry ---
  let decoded;
  try {
    decoded = jwt.verify(token, JWT_SECRET);
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired session token.' });
  }

  const { jti, username, startedAt } = decoded;

  // --- 3. Look up session in DB ---
  const session = stmts.getSession.get(jti);
  if (!session) {
    return res.status(401).json({ error: 'Unknown session.' });
  }

  // --- 4. One-use check ---
  if (session.used === 1) {
    return res.status(401).json({ error: 'Session token has already been used.' });
  }

  // --- 5. Wall-clock score validation ---
  const now = Date.now();
  const elapsedSeconds = Math.floor((now - startedAt) / 1000);
  
  const BASE_SCORE_PER_SECOND = parseInt(process.env.BASE_SCORE_PER_SECOND || '10', 10);
  const ITEM_BONUS_GRACE = parseInt(process.env.ITEM_BONUS_GRACE || '500', 10);
  const MAX_ORB_RATE_PER_SECOND = 20; // Allowable points rate from collectibles (orbs)
  
  const maxAllowedScore = Math.floor(elapsedSeconds * (BASE_SCORE_PER_SECOND + MAX_ORB_RATE_PER_SECOND))
                        + ITEM_BONUS_GRACE
                        + (GRACE_SECONDS * BASE_SCORE_PER_SECOND);

  if (scoreInt > maxAllowedScore) {
    return res.status(400).json({
      error: `Score ${scoreInt} exceeds allowed limit for elapsed time (${elapsedSeconds}s).`,
    });
  }

  // --- 6. Absolute cap ---
  if (scoreInt > SCORE_CAP) {
    return res.status(400).json({ error: `Score exceeds the maximum allowed value of ${SCORE_CAP}.` });
  }

  // --- 7. Mark token used & persist score (atomic) ---
  stmts.markSessionUsed.run(jti);
  stmts.insertScore.run(username, scoreInt, elapsedSeconds, now);

  // --- 8. Return rank ---
  const { rank } = stmts.getRank.get(scoreInt);

  return res.status(200).json({ success: true, rank });
});

module.exports = router;
