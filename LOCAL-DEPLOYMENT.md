# 🚀 Quick Start - Local Deployment

## ✅ All Fixed! Now You Can Deploy

Your Docker Compose configuration is now fixed and ready to use.

---

## 🎯 Start Local Services

Run this command in your terminal (PowerShell or Git Bash):

```bash
docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d
```

---

## 📊 What This Does

1. Pulls Docker images from registry
2. Creates and starts all services:
   - **API** (Node.js server)
   - **Frontend** (Web UI)
   - **PostgreSQL** (Database)
   - **Redis** (Cache)
   - **Prometheus** (Metrics)

3. Creates Docker network & volumes
4. Starts health checks
5. Outputs logs

---

## ✅ Verify Services Are Running

```bash
# Check all services
docker compose ps

# Output should show all containers UP
```

---

## 🌐 Access Services

Open in browser:

| Service | URL |
|---------|-----|
| API | http://localhost:3000 |
| Frontend | http://localhost:5173 |
| Prometheus | http://localhost:9090 |
| Grafana | http://localhost:3001 (password: admin) |

---

## 📝 Check Logs

```bash
# API logs
docker compose logs -f api

# Frontend logs
docker compose logs -f frontend

# All logs
docker compose logs -f
```

---

## 🛑 Stop Services

```bash
docker compose down
```

---

## 🔧 Customize Before Starting

Edit `.env` file with your values:

```bash
# Windows PowerShell or Git Bash
nano .env

# Or use your editor
# Change: POSTGRES_PASSWORD, REDIS_PASSWORD, API_KEY, etc.
```

Then start services:

```bash
docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d
```

---

## 🐛 Troubleshooting

### Services won't start?
```bash
# Check logs
docker compose logs

# Remove and retry
docker compose down -v
docker compose up -d
```

### Port already in use?
```bash
# Edit docker-compose file and change port
nano docker-compose.staging.yml

# Change: "3000:3000" to "3001:3000"
```

### Out of memory?
```bash
# Check resource usage
docker stats

# Increase Docker memory in Docker Desktop settings
```

---

## 📚 Next Steps

1. ✅ Start services (see above)
2. ✅ Verify they're running
3. ✅ Test endpoints
4. ✅ Check monitoring dashboards
5. ✅ Review logs
6. ✅ Stop and clean up when done

---

## 🎉 You're Ready!

**Run this command now:**

```bash
docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d
```

**Then access:**
- API: http://localhost:3000/health
- Frontend: http://localhost:5173
- Monitoring: http://localhost:9090

---

**Need help?** See `DOCKER-COMPOSE-FIXED.md` or `QUICK-REFERENCE.md`

