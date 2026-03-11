# Agency Fleet — Docker Runtime

Isolated Docker container running 112 AI agent specs from The Agency,
monitored by Ground Control v3.

## Quick Start

1. Build: `docker build -t agency-fleet -f docker/Dockerfile ..`
2. Start: `docker compose -f docker/docker-compose.yml up -d`
3. Auth: `docker exec -it agency-fleet claude login`
4. Verify: `curl http://localhost:7890/health`
5. Seed GC: `cd .. && npx tsx scripts/seed-gc.ts`

## Isolation

- Container has its own `/home/agency/.claude/` — no host config mounted
- Auth token persisted in Docker volume `agency-auth`
- Workspace persisted in Docker volume `agency-workspace`
- Reports executions to Ground Control at `http://host.docker.internal:3456`

## API

| Endpoint  | Method | Description                |
| --------- | ------ | -------------------------- |
| `/health` | GET    | Health check + agent count |
| `/agents` | GET    | List all agent slugs       |
| `/task`   | POST   | Dispatch task to an agent  |

### POST /task

```json
{
  "agent": "engineering-frontend-developer",
  "prompt": "Build a React component for...",
  "run_id": "optional-tracking-id"
}
```

Returns `202 Accepted` immediately. Results reported to Ground Control async.
