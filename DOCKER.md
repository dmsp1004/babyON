# Docker Setup for babyON

This document explains how to run the babyON application using Docker Compose.

## Prerequisites

- Docker Desktop installed and running
- Docker Compose (included with Docker Desktop)

## Services

The Docker Compose configuration includes two services:

1. **db** (MySQL 8.0)
   - Port: 3306
   - Database: `babyon_db`
   - Root Password: `q123456789`

2. **backend** (Spring Boot Application)
   - Port: 8080 (mapped to internal port 8085)
   - Connects to MySQL database
   - Automatically applies Flyway migrations on startup

## Quick Start

### 1. Start all services

```bash
docker-compose up -d
```

This will:
- Pull the MySQL 8.0 image (if not already available)
- Build the Spring Boot backend application
- Start both services with proper dependency management
- Wait for MySQL to be healthy before starting the backend

### 2. View logs

```bash
# View all logs
docker-compose logs -f

# View backend logs only
docker-compose logs -f backend

# View database logs only
docker-compose logs -f db
```

### 3. Stop services

```bash
# Stop but keep containers
docker-compose stop

# Stop and remove containers
docker-compose down

# Stop and remove containers + volumes (removes all data)
docker-compose down -v
```

## Accessing Services

- **Backend API**: http://localhost:8080
- **Swagger UI**: http://localhost:8080/swagger-ui.html
- **MySQL Database**: localhost:3306
  - Database: `babyon_db`
  - Username: `root`
  - Password: `q123456789`

## Development Workflow

### Rebuild backend after code changes

```bash
docker-compose up -d --build backend
```

### Connect to MySQL database

```bash
docker-compose exec db mysql -uroot -pq123456789 babyon_db
```

### Execute SQL files

```bash
docker-compose exec -T db mysql -uroot -pq123456789 babyon_db < your-script.sql
```

### View MySQL logs

```bash
docker-compose exec db tail -f /var/log/mysql/error.log
```

## Flyway Migrations

Flyway will automatically run on application startup:
- Migration files are located in: `babyon/src/main/resources/db/migration/`
- Initial schema: `V1__initial_schema.sql`
- New migrations should follow the naming convention: `V{version}__{description}.sql`

### Check migration status

Access the backend container and check Flyway schema history:

```bash
docker-compose exec db mysql -uroot -pq123456789 babyon_db -e "SELECT * FROM flyway_schema_history;"
```

## Troubleshooting

### Backend fails to connect to database

Check if MySQL is healthy:
```bash
docker-compose ps
```

If MySQL is not healthy, check its logs:
```bash
docker-compose logs db
```

### Backend fails to start

View backend logs:
```bash
docker-compose logs backend
```

### Reset database completely

```bash
docker-compose down -v
docker-compose up -d
```

This will remove all data and start fresh.

### Port conflicts

If port 3306 or 8080 is already in use, edit `docker-compose.yml` and change the port mappings:

```yaml
ports:
  - "3307:3306"  # Map to different host port
```

## Production Considerations

For production deployment:

1. **Change default passwords** in `docker-compose.yml`
2. **Use Docker secrets** instead of environment variables for sensitive data
3. **Add volume backups** for MySQL data
4. **Configure proper logging** (e.g., to external log aggregation service)
5. **Set resource limits** for containers
6. **Use external managed database** instead of containerized MySQL

## Network

All services run on a custom bridge network called `babyon-network`, which allows:
- Service discovery by service name (e.g., backend can reach db at `db:3306`)
- Isolation from other Docker networks
- Easy addition of new services

## Data Persistence

MySQL data is persisted in a Docker volume named `mysql_data`. This ensures data survives container restarts. To backup:

```bash
docker-compose exec db mysqldump -uroot -pq123456789 babyon_db > backup.sql
```

To restore:

```bash
docker-compose exec -T db mysql -uroot -pq123456789 babyon_db < backup.sql
```
