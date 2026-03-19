# Linux Bash Automation Toolkit

Учебный проект, демонстрирующий разработку bash-скриптов для автоматизации эксплуатационных задач контейнеризированного приложения.

## Описание

Проект представляет собой набор bash-скриптов, предназначенных для управления и обслуживания Docker-based приложения.

Скрипты реализуют:

- проверку окружения перед запуском (preflight)
- деплой приложения
- проверку доступности сервиса (healthcheck)
- резервное копирование PostgreSQL
- восстановление базы данных из backup
- ротацию backup-файлов
- сбор логов для диагностики

Все скрипты написаны с учетом production-практик:
- строгий режим выполнения (set -Eeuo pipefail)
- обработка ошибок через trap
- защита от параллельного запуска (lockfile)
- централизованное логирование
- корректные exit codes

## Стек технологий

- Bash
- Docker
- Docker Compose
- PostgreSQL
- Linux

## Структура проекта

```text
.
├── scripts/
│   ├── lib.sh
│   ├── preflight.sh
│   ├── healthcheck.sh
│   ├── backup_postgres.sh
│   ├── restore_postgres.sh
│   ├── deploy.sh
│   ├── collect_logs.sh
│   └── rotate_backups.sh
├── config/
│   └── env.example
├── backups/
├── logs/
└── README.md
```

## Переменные окружения

Скопируйте файл конфигурации:

```bash
cp config/env.example .env.ops
```

Загрузите переменные:

```bash
set -a
source .env.ops
set +a
```

Пример содержимого:

```bash
PROJECT_NAME=devops-app
BACKUP_DIR=./backups
LOG_DIR=./logs
LOCK_DIR=/tmp/devops-app-locks

COMPOSE_FILE=docker-compose.yml

DB_CONTAINER=postgres_db
DB_NAME=appdb
DB_USER=appuser

APP_HEALTH_URL=http://localhost:8080/health
```

## Подготовка

Сделайте скрипты исполняемыми:

```bash
chmod +x scripts/*.sh
```

## Использование

### Проверка окружения

```bash
./scripts/preflight.sh
```

Проверяет:
- наличие docker и docker compose
- доступность docker daemon
- корректность docker-compose.yml
- права на директории

---

### Деплой приложения

```bash
./scripts/deploy.sh
```

Опции:

```bash
BUILD=true PULL=false ./scripts/deploy.sh
```

Что делает:
- выполняет preflight
- собирает контейнеры
- запускает сервисы
- проверяет доступность приложения

---

### Проверка состояния сервиса

```bash
./scripts/healthcheck.sh
```

Настройки:

```bash
TIMEOUT_SECONDS=60
SLEEP_SECONDS=3
```

---

### Резервное копирование PostgreSQL

```bash
./scripts/backup_postgres.sh
```

Результат:
- создается backup
- архивируется в gzip
- генерируется sha256 checksum

Файлы сохраняются в:

```text
backups/
```

---

### Восстановление базы данных

```bash
./scripts/restore_postgres.sh <backup.sql.gz>
```

Пример:

```bash
./scripts/restore_postgres.sh backups/appdb_2026-03-19_18-00-00.sql.gz
```

---

### Ротация backup-файлов

Удаляет старые backup-файлы:

```bash
RETENTION_DAYS=7 ./scripts/rotate_backups.sh
```

Dry-run режим:

```bash
DRY_RUN=true ./scripts/rotate_backups.sh
```

---

### Сбор логов

```bash
./scripts/collect_logs.sh
```

Сохраняет:
- docker compose logs
- docker ps

в директорию:

```text
logs/
```

---

## Особенности реализации

- используется lockfile для защиты от параллельного запуска
- все скрипты используют trap для корректного завершения
- временные файлы автоматически удаляются
- ошибки приводят к немедленному завершению выполнения
- логирование унифицировано

## Безопасность

- не используются жестко закодированные пароли
- доступ к базе осуществляется через docker container
- backup-файлы сопровождаются checksum

## Возможные проблемы

Контейнер базы не запущен:

```bash
docker ps
```

Проблемы с docker:

```bash
docker info
```

Проблемы с compose:

```bash
docker compose config
```

## Что демонстрирует проект

- умение писать надежные bash-скрипты
- работу с Linux-инструментами
- автоматизацию эксплуатационных задач
- управление контейнеризированным приложением
- базовые практики DevOps

## Возможные улучшения

- интеграция с systemd (service + timer)
- отправка уведомлений (Telegram, Slack)
- автоматический rollback при неудачном deploy
- хранение backup в облаке (S3)
- интеграция с CI/CD pipeline

## Автор

Ильшат Нуриев  
https://github.com/IlshatNuriev