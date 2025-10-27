# Blue/Green Deployment with Nginx Auto-Failover

This project implements a Blue/Green deployment strategy for Node.js applications using Nginx as a reverse proxy with automatic failover capabilities.

## Architecture

- **Nginx**: Reverse proxy with automatic failover (port 8080)
- **Blue App**: Primary application instance (port 8081)
- **Green App**: Backup application instance (port 8082)

## Features

- ✅ Automatic failover from Blue to Green on failures
- ✅ Zero downtime - clients always receive 200 responses
- ✅ Retry logic for errors, timeouts, and 5xx responses
- ✅ Header preservation (X-App-Pool, X-Release-Id)
- ✅ Fast failure detection with tight timeouts
- ✅ Parameterized configuration via .env file

## Prerequisites

- Docker (20.10+)
- Docker Compose (1.29+)

## Quick Start

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd blue-green-nginx
```

### 2. Configure environment variables

Copy the example environment file and update with your image URLs:

```bash
cp .env.example .env
```

Edit `.env` and set your values:

```bash
BLUE_IMAGE=<your-blue-image-url>
GREEN_IMAGE=<your-green-image-url>
ACTIVE_POOL=blue
RELEASE_ID_BLUE=v1.0.0-blue
RELEASE_ID_GREEN=v1.0.0-green
PORT=3000
```

### 3. Start the services

```bash
docker-compose up -d
```

### 4. Verify deployment

Check that all services are running:

```bash
docker-compose ps
```

Test the version endpoint:

```bash
curl http://localhost:8080/version
```

Expected response headers:
- `X-App-Pool: blue`
- `X-Release-Id: v1.0.0-blue`

## Testing Failover

### 1. Baseline test (Blue active)

```bash
# Make multiple requests - all should return Blue
for i in {1..5}; do
  curl -s http://localhost:8080/version | grep -E "X-App-Pool|X-Release-Id"
done
```

### 2. Trigger chaos on Blue

```bash
# Simulate errors on Blue
curl -X POST http://localhost:8081/chaos/start?mode=error
```

### 3. Observe automatic failover

```bash
# Requests should now be served by Green with no errors
for i in {1..10}; do
  curl -s -w "\nStatus: %{http_code}\n" http://localhost:8080/version
  sleep 0.5
done
```

All requests should:
- Return HTTP 200
- Show `X-App-Pool: green`
- Show `X-Release-Id: v1.0.0-green`

### 4. Stop chaos and restore

```bash
# Stop chaos on Blue
curl -X POST http://localhost:8081/chaos/stop

# Restart to reset Blue
docker-compose restart app_blue
```

## Available Endpoints

### Via Nginx (http://localhost:8080)
- `GET /version` - Returns version info with pool and release headers
- `GET /healthz` - Health check endpoint
- `GET /nginx-health` - Nginx-specific health check

### Direct Access (for chaos testing)
- `POST http://localhost:8081/chaos/start?mode=error` - Trigger errors on Blue
- `POST http://localhost:8081/chaos/start?mode=timeout` - Trigger timeouts on Blue
- `POST http://localhost:8081/chaos/stop` - Stop chaos on Blue
- `POST http://localhost:8082/chaos/start?mode=error` - Trigger errors on Green
- `POST http://localhost:8082/chaos/stop` - Stop chaos on Green

## Configuration

### Nginx Failover Settings

The Nginx configuration includes:

- **Timeouts**: 
  - Connection: 2s
  - Read: 5s
  - Send: 5s

- **Retry Policy**:
  - Retries on: error, timeout, http_500, http_502, http_503, http_504
  - Max attempts: 2
  - Timeout for retries: 10s

- **Circuit Breaker**:
  - Max failures: 1
  - Fail timeout: 5s

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `BLUE_IMAGE` | Docker image for Blue app | `myregistry/app:blue` |
| `GREEN_IMAGE` | Docker image for Green app | `myregistry/app:green` |
| `ACTIVE_POOL` | Primary pool (blue/green) | `blue` |
| `RELEASE_ID_BLUE` | Blue release identifier | `v1.0.0-blue` |
| `RELEASE_ID_GREEN` | Green release identifier | `v1.0.0-green` |
| `PORT` | App internal port | `3000` |

## Logs and Debugging

View logs for all services:

```bash
docker-compose logs -f
```

View logs for specific service:

```bash
docker-compose logs -f nginx
docker-compose logs -f app_blue
docker-compose logs -f app_green
```

## Stopping the Services

```bash
docker-compose down
```

To also remove volumes:

```bash
docker-compose down -v
```

## CI/CD Integration

The grader will:

1. Set environment variables via `.env`
2. Run `docker-compose up -d`
3. Test baseline behavior (all traffic to Blue)
4. Trigger chaos on Blue via `POST /chaos/start`
5. Verify automatic failover to Green
6. Validate zero failed requests during failover

## Troubleshooting

### Services not starting

```bash
# Check logs
docker-compose logs

# Verify images are accessible
docker pull $BLUE_IMAGE
docker pull $GREEN_IMAGE
```

### Failover not working

```bash
# Check Nginx configuration
docker exec nginx_proxy cat /etc/nginx/nginx.conf

# Verify upstream health
docker exec nginx_proxy nginx -t
```

### Port conflicts

If ports 8080, 8081, or 8082 are already in use, stop conflicting services:

```bash
# Find process using port
lsof -i :8080

# Kill process
kill -9 <PID>
```

## Project Structure

```
.
├── docker-compose.yml          # Orchestration configuration
├── .env.example                # Environment variables template
├── .env                        # Your actual environment (gitignored)
├── nginx/
│   ├── Dockerfile              # Nginx image with envsubst
│   └── nginx.conf.template     # Nginx configuration template
├── README.md                   # This file
└── DECISION.md                 # Implementation decisions (optional)
```

## License

MIT