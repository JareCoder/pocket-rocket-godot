# AGENTS.md — space-shooty/backend

Guidance for AI agents working in this directory.

## What this is

A Node.js / Express REST backend for the Space Shooty game.
It handles the public leaderboard, game session tokens, and basic anti-cheat validation.
It is meant to be deployed as a Docker container.

## Tech stack

| Concern | Choice |
|---|---|
| Runtime | Node.js ≥ 22.5.0 |
| Framework | Express 4 |
| Database | SQLite via built-in `node:sqlite` (no native build step) |
| Auth | HMAC-signed JWTs (`jsonwebtoken`) |
| UUID | `crypto.randomUUID()` (built-in, no package) |
| Deployment | Docker + Docker Compose |

> **Do NOT add `better-sqlite3` or `uuid` as dependencies.** Both have been explicitly replaced by built-in Node.js APIs (`node:sqlite` and `crypto.randomUUID()`) to avoid native C++ compilation on Windows.

## Directory layout

```
backend/
├── src/
│   ├── index.js            ← Express entry point, rate limiters, session pruning
│   ├── db.js               ← Opens the DB, defines schema, exports prepared statements
│   └── routes/
│       ├── game.js         ← POST /game/start  POST /game/end
│       └── leaderboard.js  ← GET  /leaderboard
├── package.json
├── Dockerfile
├── docker-compose.yml
├── .env.example            ← Copy to .env, never commit .env
├── .gitignore
└── README.md               ← Full API reference
```

## Environment variables

Defined in `.env.example`. All are required at runtime:

| Variable | Description | Default |
|---|---|---|
| `JWT_SECRET` | HMAC secret for signing session tokens | **none — must be set** |
| `PORT` | HTTP port | `3000` |
| `SCORE_CAP` | Max score (points) the server will accept | `50000` |
| `BASE_SCORE_PER_SECOND` | Score tick points rate per second | `10` |
| `ITEM_BONUS_GRACE` | Flat grace points budget for popped items | `500` |
| `PAGE_SIZE` | Default leaderboard page size | `20` |
| `DB_DIR` | Directory for `scores.db` | `./data` (local) / `/app/data` (Docker) |

The server **exits on startup** if `JWT_SECRET` is missing or still set to the placeholder value.

## Running locally

```bash
cp .env.example .env
# Edit .env — set a real JWT_SECRET:
# node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"

npm install
npm run dev      # uses node --watch for auto-restart
```

Server starts on `http://localhost:3000`.

## Running with Docker

```bash
cp .env.example .env   # fill in JWT_SECRET
docker compose up --build
```

The SQLite file is stored in the `db_data` Docker volume and persists across container restarts.

## API surface

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/health` | Liveness check — returns `{ status: "ok" }` |
| `POST` | `/game/start` | Issue a signed session token for a new game |
| `POST` | `/game/end` | Submit a score, validate it, write to leaderboard |
| `GET` | `/leaderboard` | Paginated top scores (`?page=1&limit=20`) |

Full request/response shapes are in [README.md](./README.md).

## Database

`src/db.js` opens the database and exports a `stmts` object of prepared statements.
Always use the prepared statements — **never construct SQL strings** with user input.

Two tables:

- **`scores`** — leaderboard entries `(id, username, score, time_played, created_at)`
- **`sessions`** — one row per game session, tracks `used` flag and expiry

`score` and `time_played` are **separate fields**:
- `score` — the game's point value, sent by the client via `POST /game/end`.
- `time_played` — wall-clock seconds elapsed since session start, computed server-side at `/game/end` from `startedAt` in the JWT. The client never sends this value.

## Anti-cheat logic (important — do not weaken)

`POST /game/end` in `src/routes/game.js` applies these checks in order:

1. Token is a valid, unexpired JWT (signature check)
2. Session `jti` exists in the `sessions` table
3. Session has not already been used (`used = 0`)
4. `score ≤ floor((now − startedAt) / 1000) * BASE_SCORE_PER_SECOND + ITEM_BONUS_GRACE + GRACE_SECONDS * BASE_SCORE_PER_SECOND`
5. `score ≤ SCORE_CAP`

Step 4 is the core check: it validates the claimed score against the elapsed wall-clock time scaled by the base points per second rate, plus a flat buffer for Point Orb pops. Do not remove or relax this check without corresponding changes to the game's scoring system.

The `elapsedSeconds` value computed during step 4 is also written to `scores.time_played`, so `time_played` is always authoritative and uncheateable.

## Rate limiting

- `/game/*` — 10 requests / minute / IP
- `/leaderboard` — 60 requests / minute / IP

Configured in `src/index.js`. Adjust `max` values if needed but do not remove the limiters.

## Conventions

- All route handlers use **synchronous** `node:sqlite` calls (no async DB layer needed).
- Errors always return `{ error: "..." }` JSON with an appropriate HTTP status code.
- No tests exist yet — when adding them, place them in a `tests/` directory and use Node's built-in test runner (`node:test`).
- Do not add a build step. This is plain CommonJS; just run `node src/index.js`.

## Common tasks

**Add a new route:**
1. Create `src/routes/<name>.js`, export an Express router.
2. Mount it in `src/index.js` with an appropriate rate limiter.

**Change the DB schema:**
Edit the `db.exec(...)` block in `src/db.js`. Add new prepared statements to the `stmts` object.
Note: `node:sqlite` uses positional `?` parameters, not named `@param` style.

**Update the score cap:**
Change `SCORE_CAP` in `.env`. No code change required.
