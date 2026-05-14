# API (Rails 8.1)

Ruby 3.4.2 | MySQL 8.0 | Elasticsearch 8.13 | Sidekiq + Redis

## Commands

```bash
bundle exec rails s -b 0.0.0.0          # Start server (port 3000)
bundle exec rails db:create db:migrate   # Setup database
bundle exec rails db:seed                # Seed data
bundle exec rspec                        # Run all tests
bundle exec rspec spec/requests/         # Run request specs only
bundle exec rubocop                      # Lint
bundle exec rubocop -a                   # Lint with auto-fix
bundle exec brakeman                     # Security scan
bundle exec sidekiq                      # Start background jobs
```

## Architecture

```
app/
  controllers/api/v1/   API v1 endpoints (BaseController for shared logic)
  models/               ActiveRecord models (Game, Match, User, Rank, Skill...)
  services/             Business logic (games/, matches/, ranks/)
  repositories/         Data access (GameRepository)
  jobs/games/           Sidekiq jobs (index, delete_index, update_statuses)
```

- **Service pattern:** services return `ServiceResult` objects, inherit `ApplicationService`
- **Repository pattern:** `GameRepository` abstracts data access for games
- **Elasticsearch:** feature-flagged via `ELASTICSEARCH_ENABLED` env var, concern `GameSearchable` on Game model

## API routes

All endpoints under `/api/v1/`:

| Method | Path | Controller |
|--------|------|-----------|
| POST | /signup | registrations |
| POST | /login | sessions |
| DELETE | /logout | sessions |
| GET/PATCH | /me | me, profile |
| GET/POST | /games | games |
| GET | /games/search | games (Elasticsearch) |
| POST | /games/:id/join | games |
| POST | /games/:id/leave | games |
| GET/POST | /games/:id/matches | matches |
| POST | /games/:id/matches/:id/finish | matches |

Swagger UI: `http://localhost:3000/api-docs`

## Database

- Adapter: mysql2 (utf8mb4)
- Dev DB: `api_development` | Test DB: `api_test`
- Docker MySQL exposed on host port **13306**
- Production: multi-database (primary, cache, queue, cable shards)

## Background jobs

- Sidekiq Web UI: `http://localhost:3000/sidekiq`
- Cron: `Games::UpdateStatusesJob` runs every 50 minutes (game status transitions)

## Elasticsearch rake tasks

```bash
ELASTICSEARCH_ENABLED=true bundle exec rake elasticsearch:setup    # First-time index creation
ELASTICSEARCH_ENABLED=true bundle exec rake elasticsearch:reindex  # Blue-green reindex
ELASTICSEARCH_ENABLED=true bundle exec rake elasticsearch:status   # Show index info
ELASTICSEARCH_ENABLED=true bundle exec rake elasticsearch:drop     # Delete all indices
```

## Linting (RuboCop)

- `EnabledByDefault: true` with many cops selectively disabled
- Max line length: 132
- Max method length: 12
- Max ABC size: 20
- Excludes: `db/`, `bin/`, `tmp/`
- Trailing commas in arrays/hashes: allowed (disabled cops)

## Environment variables

See `.env.example` for required vars: `DB_HOST`, `DB_USERNAME`, `DB_PASSWORD`, `REDIS_HOST`, `REDIS_PORT`, `ELASTICSEARCH_URL`, `ELASTICSEARCH_ENABLED`, `FE_ORIGIN`.
