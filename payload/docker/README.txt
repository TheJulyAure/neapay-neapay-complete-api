==============================================
  NeaPay Complete - Docker Configuration
==============================================

This folder contains Docker-related files for NeaPay Complete.

FILES:
------
- docker-compose.yml          # Main Docker Compose configuration
- docker-compose.override.yml # Local development overrides

USAGE:
------
# Start NeaPay
docker compose up -d

# Stop NeaPay
docker compose down

# View logs
docker compose logs -f

REQUIREMENTS:
-------------
- Docker Desktop for Windows
- WSL2 backend (recommended)
- 4GB RAM minimum
- 20GB disk space

PORTS:
------
- API:    8080 (configurable)
- Frontend: 3000 (configurable)

For more info, see: https://docs.neapay.com/docker
