# local run
docker compose up -d --build

# check endpoints
curl -I http://localhost:8081      # blue direct
curl -I http://localhost:8082      # green direct
curl -I http://localhost:8080      # through nginx (active)

# simulate chaos (grader will call this on the direct ports)
curl -X POST "http://localhost:8081/chaos/start?mode=error"
curl -X POST "http://localhost:8081/chaos/stop"

# manually toggle active pool (for testing)
# change ACTIVE_POOL in .env then run:
docker compose restart nginx
# or, to avoid restart, you can rebuild nginx (grader will set ACTIVE_POOL)
