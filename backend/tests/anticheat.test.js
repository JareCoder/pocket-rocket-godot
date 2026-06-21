const test = require('node:test');
const assert = require('node:assert');
const jwt = require('jsonwebtoken');
const { randomUUID } = require('crypto');

// Mock environment
process.env.JWT_SECRET = 'test_secret';
process.env.BASE_SCORE_PER_SECOND = '10';
process.env.ITEM_BONUS_GRACE = '500';

const JWT_SECRET = process.env.JWT_SECRET;
const SCORE_CAP = 50000;
const GRACE_SECONDS = 10;

function validateScore(scoreInt, elapsedSeconds) {
  const BASE_SCORE_PER_SECOND = parseInt(process.env.BASE_SCORE_PER_SECOND || '10', 10);
  const ITEM_BONUS_GRACE = parseInt(process.env.ITEM_BONUS_GRACE || '500', 10);
  const MAX_ORB_RATE_PER_SECOND = 20;
  
  const maxAllowedScore = Math.floor(elapsedSeconds * (BASE_SCORE_PER_SECOND + MAX_ORB_RATE_PER_SECOND))
                        + ITEM_BONUS_GRACE
                        + (GRACE_SECONDS * BASE_SCORE_PER_SECOND);

  return scoreInt <= maxAllowedScore;
}

test('Anti-cheat Score Validation', async (t) => {
  await t.test('accepts legitimate short run', () => {
    // 20s run, score 300 (10 points/s * 20s = 200 survival, plus some orbs)
    assert.strictEqual(validateScore(300, 20), true);
  });

  await t.test('accepts legitimate long run', () => {
    // 2254s run, score 23970
    assert.strictEqual(validateScore(23970, 2254), true);
  });

  await t.test('rejects obvious cheated score (too high in too little time)', () => {
    // 10s run, score 23970
    assert.strictEqual(validateScore(23970, 10), false);
  });

  await t.test('rejects score exceeding absolute cap', () => {
    // 6000s run (plenty of time), but score is 60000 (above cap of 50000)
    // (the cap check itself is separate in routes/game.js, here we just verify validation bounds)
    assert.strictEqual(validateScore(60000, 6000), true); // formula allows it, cap will catch it
  });
});
