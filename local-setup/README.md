# Local setup (Docker Compose)

## Start
```bash
cd local-setup
cp .env.example .env        # first time only
docker compose up --build
```
Open http://localhost:3000 (API docs: http://localhost:8000/api/docs).

## Use
```bash
docker compose ps                 # status + health
docker compose logs -f backend    # logs
docker compose restart backend    # restart one service
```

## Stop
```bash
docker compose down        # stop, keep data
docker compose down -v     # stop AND delete the database volume
```

## SonarQube (optional)
```bash
sudo sysctl -w vm.max_map_count=262144   # Linux only, needed once per boot
docker compose --profile sonar up -d
```
Open http://localhost:9000 (admin / admin).