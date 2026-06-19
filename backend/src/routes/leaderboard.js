const express = require('express');
const { stmts } = require('../db');

const router = express.Router();

const DEFAULT_PAGE_SIZE = parseInt(process.env.PAGE_SIZE || '20', 10);
const MAX_PAGE_SIZE = 100;

// GET /leaderboard
// Query params:
//   page  – 1-indexed page number (default: 1)
//   limit – entries per page (default: PAGE_SIZE env var, max: 100)
//
// Response:
// {
//   scores: [{ rank, username, score, date }],
//   pagination: { page, limit, total, totalPages }
// }
router.get('/', (req, res) => {
  let page = parseInt(req.query.page, 10);
  let limit = parseInt(req.query.limit, 10);

  // Sanitise page
  if (isNaN(page) || page < 1) page = 1;

  // Sanitise limit
  if (isNaN(limit) || limit < 1) limit = DEFAULT_PAGE_SIZE;
  if (limit > MAX_PAGE_SIZE) limit = MAX_PAGE_SIZE;

  const offset = (page - 1) * limit;

  const rows = stmts.getLeaderboard.all(limit, offset);
  const { total } = stmts.countScores.get();
  const totalPages = Math.ceil(total / limit);

  const scores = rows.map((row, i) => ({
    rank: offset + i + 1,
    username: row.username,
    score: row.score,
    date: new Date(row.created_at).toISOString(),
  }));

  return res.status(200).json({
    scores,
    pagination: {
      page,
      limit,
      total,
      totalPages,
    },
  });
});

module.exports = router;
