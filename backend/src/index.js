require('dotenv').config();

const express = require('express');
const rateLimit = require('express-rate-limit');
const { stmts } = require('./db');

if (!process.env.JWT_SECRET || process.env.JWT_SECRET === 'change_me_to_a_long_random_string') {
  console.error('[FATAL] JWT_SECRET is not set or is still the default placeholder. Set it in your .env file.');
  process.exit(1);
}

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.set('trust proxy', 1);

const gameLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please slow down.' },
});

const leaderboardLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please slow down.' },
});

// --- Routes ---
app.use('/game', gameLimiter, require('./routes/game'));
app.use('/leaderboard', leaderboardLimiter, require('./routes/leaderboard'));

app.get('/health', (_req, res) => res.status(200).json({ status: 'ok' }));

// 404 fallback
app.use((_req, res) => res.status(404).json({ error: 'Not found.' }));

// Global error handler
app.use((err, _req, res, _next) => {
  console.error('[ERROR]', err);
  res.status(500).json({ error: 'Internal server error.' });
});

// --- Session housekeeping ---
// Prune expired unused sessions every 10 minutes to keep the DB tidy
setInterval(() => {
  const cutoff = Math.floor(Date.now() / 1000);
  stmts.pruneExpiredSessions.run(cutoff);
}, 10 * 60 * 1000);

// --- Start ---
app.listen(PORT, () => {
  console.log(`[space-shooty-backend] Listening on port ${PORT}`);
  console.log(`[space-shooty-backend] Score cap: ${process.env.SCORE_CAP || 3600}s`);
});
