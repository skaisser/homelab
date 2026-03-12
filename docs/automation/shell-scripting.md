# 📜 Advanced Shell Scripting for Homelab #automation #bash #scripting #devops

Master bash scripting with production-ready patterns, error handling, and practical homelab automation scripts. Learn best practices for reliable, maintainable shell code.

## Table of Contents
- [Script Structure Best Practices](#script-structure-best-practices)
- [Input Validation](#input-validation)
- [Error Handling Patterns](#error-handling-patterns)
- [Logging Framework](#logging-framework)
- [Homelab Automation Patterns](#homelab-automation-patterns)
- [Environment Variables](#environment-variables)
- [Cron Integration](#cron-integration)
- [Debugging Tips](#debugging-tips)
- [Best Practices](#best-practices)
- [Additional Resources](#additional-resources)

## Script Structure Best Practices

**Minimal script template with set options:**
```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'        # Change Internal Field Separator

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
LOG_FILE="/var/log/myapp/${SCRIPT_NAME}.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Trap errors and cleanup
trap cleanup EXIT
trap 'echo "Script interrupted"; exit 130' INT TERM

cleanup() {
  local exit_code=$?
  [[ $exit_code -ne 0 ]] && echo "Script failed with code $exit_code"
  return $exit_code
}

# Main function
main() {
  echo "Starting ${SCRIPT_NAME}..."
  # Script logic here
}

main "$@"
```

**Script with function structure:**
```bash
#!/bin/bash
set -euo pipefail

# Configuration
readonly CONFIG_DIR="/etc/myapp"
readonly DATA_DIR="/var/lib/myapp"
readonly LOG_FILE="/var/log/myapp/operations.log"

# Logging function
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Function for cleanup operations
cleanup() {
  log "Performing cleanup..."
  [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}

# Function for database backup
backup_database() {
  local db_name=$1
  local backup_dir=$2

  log "Backing up database: $db_name"
  mkdir -p "$backup_dir"

  pg_dump "$db_name" | gzip > "$backup_dir/${db_name}-$(date +%s).sql.gz"
  log "Backup completed successfully"
}

main() {
  trap cleanup EXIT
  log "Script started"

  backup_database "myapp_db" "$DATA_DIR/backups"
}

main "$@"
```

## Input Validation

**Validate arguments and options:**
```bash
#!/bin/bash
set -euo pipefail

# Check minimum argument count
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <action> [options]"
  exit 1
fi

ACTION=$1
shift

# Validate action
case "$ACTION" in
  start|stop|restart|status)
    # Valid action
    ;;
  *)
    echo "Error: Unknown action '$ACTION'"
    echo "Valid actions: start, stop, restart, status"
    exit 1
    ;;
esac

# Validate paths exist
check_required_file() {
  local file=$1
  local name=${2:-"File"}

  if [[ ! -f "$file" ]]; then
    echo "Error: $name not found: $file" >&2
    exit 1
  fi
}

check_required_dir() {
  local dir=$1
  local name=${2:-"Directory"}

  if [[ ! -d "$dir" ]]; then
    echo "Error: $name not found: $dir" >&2
    exit 1
  fi
}

# Check if port is available
check_port_available() {
  local port=$1

  if netstat -tln 2>/dev/null | grep -q ":$port "; then
    echo "Error: Port $port is already in use" >&2
    return 1
  fi
  return 0
}

# Validate numeric input
validate_number() {
  local input=$1
  local name=${2:-"Value"}

  if ! [[ "$input" =~ ^[0-9]+$ ]]; then
    echo "Error: $name must be a number, got: $input" >&2
    return 1
  fi
}

# Validate email
validate_email() {
  local email=$1

  if ! [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Error: Invalid email address: $email" >&2
    return 1
  fi
}

# Usage examples
check_required_file "/etc/myapp/config.conf" "Configuration file"
check_required_dir "/opt/myapp" "Application directory"
check_port_available 8080 || exit 1
validate_number "$PORT" "Port number" || exit 1
validate_email "$ADMIN_EMAIL" || exit 1
```

## Error Handling Patterns

**Comprehensive error handling:**
```bash
#!/bin/bash
set -euo pipefail

# Error handling with context
run_command() {
  local context=$1
  shift

  echo "Running: $context"
  if ! "$@" 2>&1; then
    echo "Error: Failed to $context" >&2
    return 1
  fi
}

# Try-catch pattern
try_command() {
  local max_attempts=3
  local attempt=1

  while (( attempt <= max_attempts )); do
    if "$@"; then
      return 0
    fi
    echo "Attempt $attempt failed, retrying..." >&2
    ((attempt++))
    sleep $((attempt * 2))
  done

  return 1
}

# Command with timeout
run_with_timeout() {
  local timeout=$1
  shift

  if timeout "$timeout" "$@"; then
    return 0
  else
    local code=$?
    if [[ $code -eq 124 ]]; then
      echo "Error: Command timed out after ${timeout}s" >&2
    fi
    return $code
  fi
}

# Safe file operations
safe_copy() {
  local source=$1
  local dest=$2

  if [[ ! -e "$source" ]]; then
    echo "Error: Source file does not exist: $source" >&2
    return 1
  fi

  if [[ -e "$dest" ]]; then
    echo "Warning: Destination exists, creating backup: ${dest}.bak"
    cp "$dest" "${dest}.bak"
  fi

  cp "$source" "$dest"
}

# Verify operation success
verify_file_created() {
  local file=$1

  if [[ -f "$file" && -s "$file" ]]; then
    echo "OK: File created successfully: $file"
    return 0
  else
    echo "Error: File creation failed or empty: $file" >&2
    return 1
  fi
}

# Usage examples
try_command wget https://example.com/file.tar.gz -O /tmp/file.tar.gz
run_with_timeout 30 docker ps
safe_copy /etc/nginx/nginx.conf /etc/nginx/nginx.conf.new
verify_file_created /opt/app/config.yml
```

## Logging Framework

**Production logging function:**
```bash
#!/bin/bash

LOG_FILE="${LOG_FILE:-/var/log/myapp/script.log}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"  # DEBUG, INFO, WARN, ERROR

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  local level=$1
  shift
  local message="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_debug() {
  [[ "$LOG_LEVEL" != "DEBUG" ]] && return 0
  log "DEBUG" "$@"
}

log_info() {
  log "INFO" "$@"
}

log_warn() {
  log "WARN" "$@" >&2
}

log_error() {
  log "ERROR" "$@" >&2
}

# Usage
log_info "Starting backup process"
log_debug "Config directory: $CONFIG_DIR"
log_warn "Database connection slow"
log_error "Failed to connect to database"
```

## Homelab Automation Patterns

**Health check script:**
```bash
#!/bin/bash
set -euo pipefail

check_service_health() {
  local service=$1
  local port=$2
  local timeout=5

  # Check if service is running
  if ! systemctl is-active --quiet "$service"; then
    echo "ERROR: Service $service is not running"
    return 1
  fi

  # Check if port is listening
  if ! nc -w $timeout -z localhost "$port" 2>/dev/null; then
    echo "ERROR: Service $service not listening on port $port"
    return 1
  fi

  echo "OK: Service $service is healthy"
  return 0
}

# Monitor all homelab services
monitor_services() {
  local services=(
    "docker:2375"
    "nginx:80"
    "postgresql:5432"
    "redis:6379"
  )

  local failed=0

  for service_port in "${services[@]}"; do
    IFS=: read -r service port <<< "$service_port"

    if ! check_service_health "$service" "$port"; then
      ((failed++))
      systemctl restart "$service" || true
    fi
  done

  return $((failed > 0 ? 1 : 0))
}

monitor_services
```

**Backup script with rotation:**
```bash
#!/bin/bash
set -euo pipefail

BACKUP_DIR="/backups"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

backup_docker_volumes() {
  local volume=$1
  local dest="$BACKUP_DIR/${volume}_${TIMESTAMP}.tar.gz"

  mkdir -p "$BACKUP_DIR"
  docker run --rm -v "$volume":/data -v "$BACKUP_DIR":/backup \
    alpine tar czf "/backup/$(basename "$dest")" -C /data .

  echo "Backed up volume: $volume"
}

rotate_backups() {
  find "$BACKUP_DIR" -name "*.tar.gz" -mtime "+$RETENTION_DAYS" -delete
  echo "Cleaned up backups older than $RETENTION_DAYS days"
}

backup_docker_volumes "postgres_data"
backup_docker_volumes "app_data"
rotate_backups
```

**Cleanup script:**
```bash
#!/bin/bash
set -euo pipefail

cleanup_docker_images() {
  echo "Cleaning up unused Docker images..."
  docker image prune -a --force --filter "until=240h" 2>/dev/null || true
}

cleanup_docker_containers() {
  echo "Cleaning up stopped containers..."
  docker container prune -f 2>/dev/null || true
}

cleanup_logs() {
  echo "Compressing old logs..."
  find /var/log -name "*.log" -mtime +30 -exec gzip {} \;

  echo "Removing very old logs..."
  find /var/log -name "*.log.gz" -mtime +90 -delete
}

cleanup_temp() {
  echo "Cleaning temporary files..."
  find /tmp -type f -atime +7 -delete
  find /var/tmp -type f -atime +7 -delete
}

cleanup_docker_images
cleanup_docker_containers
cleanup_logs
cleanup_temp

echo "Cleanup completed"
```

## Environment Variables

**Safe environment variable handling:**
```bash
#!/bin/bash
set -euo pipefail

# Load from .env file
load_env_file() {
  local env_file=${1:-.env}

  if [[ ! -f "$env_file" ]]; then
    echo "Error: Environment file not found: $env_file" >&2
    return 1
  fi

  # Source only safe variables (no eval)
  set -a
  source "$env_file"
  set +a
}

# Require environment variables
require_env_vars() {
  local missing=()

  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      missing+=("$var")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Error: Missing required environment variables: ${missing[*]}" >&2
    return 1
  fi
}

# With defaults
get_env_or_default() {
  local var_name=$1
  local default=${2:-}

  echo "${!var_name:-$default}"
}

# Usage
load_env_file "/opt/app/.env"
require_env_vars DB_HOST DB_USER DB_PASSWORD
API_PORT=$(get_env_or_default "API_PORT" "8080")
```

## Cron Integration

**Script for cron execution:**
```bash
#!/bin/bash

# Ensure proper paths in cron environment
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export LC_ALL=C

LOG_FILE="/var/log/myapp/cron.log"
LOCK_FILE="/var/run/myapp.lock"

# Prevent concurrent execution
acquire_lock() {
  local timeout=300
  local start_time=$(date +%s)

  while [[ -f "$LOCK_FILE" ]]; do
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))

    if [[ $elapsed -gt $timeout ]]; then
      echo "Lock timeout, forcing removal" >> "$LOG_FILE"
      rm -f "$LOCK_FILE"
      break
    fi

    sleep 5
  done

  echo $$ > "$LOCK_FILE"
}

release_lock() {
  rm -f "$LOCK_FILE"
}

trap release_lock EXIT

# Cron job wrapper with logging
run_cron_job() {
  {
    echo "===== Starting cron job at $(date) ====="
    acquire_lock

    # Actual job logic
    /opt/app/backup.sh

    echo "===== Cron job completed at $(date) ====="
  } >> "$LOG_FILE" 2>&1
}

run_cron_job
```

**Example crontab entries:**
```bash
# Daily backup at 2 AM
0 2 * * * /opt/app/backup.sh

# Every hour
0 * * * * /opt/app/hourly-task.sh

# Every 15 minutes
*/15 * * * * /opt/app/frequent-task.sh

# Weekly on Sunday at 3 AM
0 3 * * 0 /opt/app/weekly-maintenance.sh

# First day of month at midnight
0 0 1 * * /opt/app/monthly-report.sh
```

## Debugging Tips

**Enable debug mode:**
```bash
# Run script with debug output
bash -x /opt/app/script.sh

# Enable in script
set -x  # Turn on debug
set +x  # Turn off debug

# Or run with environment variable
BASH_XTRACEFD=3 bash /opt/app/script.sh 3> /tmp/debug.log
```

**Use shellcheck for validation:**
```bash
# Install shellcheck
apt-get install shellcheck  # Debian/Ubuntu
brew install shellcheck     # macOS

# Check script syntax
shellcheck /opt/app/script.sh

# Check all scripts in directory
shellcheck /opt/app/*.sh

# Disable specific warnings
shellcheck -x -S warning /opt/app/script.sh
```

## Best Practices

1. **Always use set -euo pipefail** - Fail fast and loud
2. **Quote variables** - Use "$var" not $var
3. **Use readonly for constants** - Prevent accidental changes
4. **Add logging** - Always know what your script did
5. **Validate inputs** - Never trust external data
6. **Use functions** - Keep code DRY and testable
7. **Handle signals** - Clean up resources properly
8. **Document scripts** - Add comments and help text
9. **Test before automation** - Run scripts manually first
10. **Use absolute paths** - Never rely on working directory

## Additional Resources

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck - Find bugs in your shell scripts](https://www.shellcheck.net/)
- [Bash Manual](https://www.gnu.org/software/bash/manual/)
- [Advanced Bash Scripting Guide](https://www.tldp.org/LDP/abs/html/)

---

✅ Comprehensive shell scripting guide with error handling patterns, logging frameworks, and production-ready homelab automation examples.
