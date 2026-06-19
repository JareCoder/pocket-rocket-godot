# Space Shooty – Backend

Node.js / Express REST backend for the Space Shooty game, handling the public leaderboard and score submission with basic anti-cheat validation.

---

## Stack

| | |
|---|---|
| Runtime | Node.js 22 (Alpine) |
| Framework | Express 4 |
| Database | SQLite via `better-sqlite3` |
| Auth | HMAC-signed JWTs (`jsonwebtoken`) |
| Deployment | Docker + Docker Compose |

---

## Setup

### 1. Configure environment

```bash
cp .env.example .env
```

Edit `.env` and set a strong `JWT_SECRET`:

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

### 2. Run with Docker (recommended)

```bash
docker compose up --build
```

The server starts on `http://localhost:3000`. The SQLite database is stored in a Docker volume (`db_data`) and persists across container restarts.

### 3. Run locally (development)

```bash
npm install
npm run dev
```

> Requires Node.js 18+. The database is created at `./data/scores.db`.

---

## API Reference

### Health

```
GET /health
```
Returns `{ "status": "ok" }`. Use for uptime monitoring.

---

### Start a game session

```
POST /game/start
Content-Type: application/json

{ "username": "PlayerOne" }
```

**Response `200`**
```json
{
  "token": "<jwt>",
  "startedAt": 1718745600000
}
```

Store `token` in your game client and send it when the game ends.

**Username rules:** 1–32 characters, letters/numbers/spaces/`_`/`-`.

---

### End a game session & submit score

```
POST /game/end
Content-Type: application/json

{ "token": "<jwt>", "score": 42 }
```

**Response `200`**
```json
{
  "success": true,
  "rank": 7
}
```

`rank` is the all-time leaderboard position for this score.

**Validation applied:**
- Token must be valid, unexpired, and unused
- `score` must be ≤ wall-clock seconds elapsed since `/game/start` + 10s grace
- `score` must be ≤ `SCORE_CAP` (default: 3600)

---

### Leaderboard

```
GET /leaderboard?page=1&limit=20
```

| Param | Default | Max | Description |
|---|---|---|---|
| `page` | `1` | — | 1-indexed page number |
| `limit` | `20` | `100` | Entries per page |

**Response `200`**
```json
{
  "scores": [
    { "rank": 1, "username": "PlayerOne", "score": 312, "date": "2024-06-18T21:00:00.000Z" }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 47,
    "totalPages": 3
  }
}
```

---

## Anti-Cheat Summary

| Check | Details |
|---|---|
| Signed session token | HMAC-SHA256 JWT, 2-hour expiry |
| One-use tokens | Each token can only submit one score |
| Wall-clock validation | `score ≤ elapsed_seconds + 10s` |
| Score cap | Configurable via `SCORE_CAP` (default 3600s) |
| Rate limiting | 10 req/min per IP on `/game/*`, 60 on `/leaderboard` |
| Username sanitisation | Regex + length check |

---

## Godot Client Integration

The game needs to:

1. **Before Play:** show a username input, call `POST /game/start`, store the returned `token` in `Global`.
2. **On Game Over:** call `POST /game/end` with the stored `token` and `Global.score`, then display the returned `rank`.
3. **Leaderboard screen:** call `GET /leaderboard?page=1` and display results.

Use Godot's built-in `HTTPRequest` node for all calls.
