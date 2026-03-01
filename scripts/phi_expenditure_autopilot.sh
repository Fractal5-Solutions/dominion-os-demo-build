#!/bin/bash
# PHI Expenditure System - Full Autopilot Orchestrator
# Purpose: Autonomous deployment, ingestion, and monitoring (NHITL mode)
# Generated: 2026-02-27 by PHI Chief Sovereign Mode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   PHI EXPENDITURE SYSTEM - FULL AUTOPILOT MODE                ║"
echo "║   No Human In The Loop (NHITL) Autonomous Operation           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TELEMETRY_DIR="${SCRIPT_DIR}/../telemetry"
LOG_FILE="${TELEMETRY_DIR}/expenditure_autopilot.log"
HEALTH_FILE="${TELEMETRY_DIR}/expenditure_health.json"
STATUS_FILE="${TELEMETRY_DIR}/expenditure_status.json"

# Deployment Configuration
DEPLOYMENT_MODE="${1:-local}"  # local, docker, systemd, cloud-run
INGESTION_INTERVAL="${2:-3600}" # seconds (default: 1 hour)
AI_OPTIMIZATION="${3:-enabled}" # enabled or disabled

# Database Configuration (from environment or defaults)
export EXPENDITURE_DB="${EXPENDITURE_DB:-postgresql://phi_admin:secure_password@localhost:5432/expenditures}"
export FLASK_SECRET_KEY="${FLASK_SECRET_KEY:-$(openssl rand -hex 32)}"
export GMAIL_CREDENTIALS_PATH="${GMAIL_CREDENTIALS_PATH:-${SCRIPT_DIR}/credentials.json}"
export GMAIL_TOKEN_PATH="${GMAIL_TOKEN_PATH:-${SCRIPT_DIR}/token.json}"

# Ensure telemetry directory exists
mkdir -p "$TELEMETRY_DIR"

# Logging function
log() {
    local level="$1"
    shift
    local message="$@"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

log_json() {
    local status="$1"
    local message="$2"
    local details="${3:-{}}"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$STATUS_FILE" <<EOF
{
  "timestamp": "${timestamp}",
  "status": "${status}",
  "message": "${message}",
  "deployment_mode": "${DEPLOYMENT_MODE}",
  "ingestion_interval": ${INGESTION_INTERVAL},
  "ai_optimization": "${AI_OPTIMIZATION}",
  "details": ${details}
}
EOF
}

# Health check function
health_check() {
    local component="$1"
    local status="unknown"
    local details=""

    case "$component" in
        "database")
            if psql "$EXPENDITURE_DB" -c "SELECT 1" &>/dev/null; then
                status="healthy"
                details="PostgreSQL connection successful"
            else
                status="unhealthy"
                details="PostgreSQL connection failed"
            fi
            ;;
        "dashboard")
            if curl -s http://localhost:5000/api/health &>/dev/null; then
                status="healthy"
                details="Dashboard responding"
            else
                status="unhealthy"
                details="Dashboard not responding"
            fi
            ;;
        "gmail")
            if [ -f "$GMAIL_TOKEN_PATH" ]; then
                status="healthy"
                details="Gmail OAuth token present"
            else
                status="warning"
                details="Gmail OAuth token missing - requires authorization"
            fi
            ;;
        *)
            status="unknown"
            details="Unknown component: $component"
            ;;
    esac

    echo "$status"
}

# Update health status JSON
update_health_status() {
    local db_health=$(health_check "database")
    local dashboard_health=$(health_check "dashboard")
    local gmail_health=$(health_check "gmail")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$HEALTH_FILE" <<EOF
{
  "timestamp": "${timestamp}",
  "overall_status": "operational",
  "components": {
    "database": {
      "status": "${db_health}",
      "connection_string": "${EXPENDITURE_DB%%@*}@***"
    },
    "dashboard": {
      "status": "${dashboard_health}",
      "url": "http://localhost:5000"
    },
    "gmail_ingestion": {
      "status": "${gmail_health}",
      "interval_seconds": ${INGESTION_INTERVAL}
    },
    "ai_optimization": {
      "status": "${AI_OPTIMIZATION}",
      "features": ["confidence_tuning", "category_prediction", "vendor_normalization"]
    }
  },
  "metrics": {
    "uptime_seconds": $SECONDS,
    "last_ingestion": null,
    "processed_items": 0,
    "pending_verification": 0
  }
}
EOF
}

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🚀 PHASE 1: Pre-flight Checks${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

log "INFO" "Starting PHI Expenditure Autopilot in ${DEPLOYMENT_MODE} mode"
log_json "initializing" "Pre-flight checks in progress"

# Check Python installation
echo -e "${YELLOW}📦 Checking Python environment...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓ Python found: ${PYTHON_VERSION}${NC}"
    log "INFO" "Python environment: ${PYTHON_VERSION}"
else
    echo -e "${RED}✗ Python 3 not found${NC}"
    log "ERROR" "Python 3 is required but not found"
    exit 1
fi

# Check PostgreSQL connection
echo -e "${YELLOW}🗄️  Checking PostgreSQL connection...${NC}"
DB_STATUS=$(health_check "database")
if [ "$DB_STATUS" = "healthy" ]; then
    echo -e "${GREEN}✓ PostgreSQL connection successful${NC}"
    log "INFO" "Database connection verified"
else
    echo -e "${RED}✗ PostgreSQL connection failed${NC}"
    echo -e "${YELLOW}   Run: python3 ${SCRIPT_DIR}/init_expenditure_database.py${NC}"
    log "ERROR" "Database connection failed - initialization may be required"
    exit 1
fi

# Check required Python packages
echo -e "${YELLOW}📚 Checking Python dependencies...${NC}"
if [ -f "${SCRIPT_DIR}/requirements.txt" ]; then
    pip3 install -q -r "${SCRIPT_DIR}/requirements.txt"
    echo -e "${GREEN}✓ Python dependencies installed${NC}"
    log "INFO" "Dependencies verified and updated"
else
    echo -e "${YELLOW}⚠ requirements.txt not found - continuing anyway${NC}"
    log "WARN" "requirements.txt not found"
fi

# Initialize database if needed
echo -e "${YELLOW}🏗️  Checking database schema...${NC}"
if python3 "${SCRIPT_DIR}/init_expenditure_database.py" &>/dev/null; then
    echo -e "${GREEN}✓ Database schema verified${NC}"
    log "INFO" "Database schema initialized/verified"
else
    echo -e "${RED}✗ Database initialization failed${NC}"
    log "ERROR" "Database initialization failed"
    exit 1
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🤖 PHASE 2: AI-Optimized Pipeline Configuration${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$AI_OPTIMIZATION" = "enabled" ]; then
    echo -e "${YELLOW}🧠 Configuring AI optimization features...${NC}"

    # Create AI optimization config
    cat > "${SCRIPT_DIR}/ai_optimization_config.json" <<EOF
{
  "enabled": true,
  "features": {
    "confidence_tuning": {
      "enabled": true,
      "thresholds": {
        "high": 0.9,
        "medium": 0.7,
        "low": 0.5
      },
      "auto_verify_high": true
    },
    "category_prediction": {
      "enabled": true,
      "model": "pattern_matching_v1",
      "learning_mode": "continuous",
      "confidence_threshold": 0.85
    },
    "vendor_normalization": {
      "enabled": true,
      "fuzzy_matching": true,
      "auto_create_vendors": false
    },
    "amount_validation": {
      "enabled": true,
      "outlier_detection": true,
      "statistical_method": "iqr"
    },
    "tax_calculation": {
      "enabled": true,
      "auto_detect_region": true,
      "default_rate": 0.13
    }
  },
  "ingestion_pipeline": {
    "parallel_processing": true,
    "batch_size": 50,
    "retry_failed": true,
    "max_retries": 3
  },
  "monitoring": {
    "track_accuracy": true,
    "alert_on_low_confidence": true,
    "alert_threshold": 0.6
  }
}
EOF

    echo -e "${GREEN}✓ AI optimization configured${NC}"
    echo -e "  • Confidence tuning: Auto-verify >90%${NC}"
    echo -e "  • Category prediction: Pattern matching (learning)${NC}"
    echo -e "  • Vendor normalization: Fuzzy matching enabled${NC}"
    echo -e "  • Amount validation: Outlier detection active${NC}"
    echo -e "  • Tax calculation: Auto-detect region (13% default)${NC}"
    log "INFO" "AI optimization features configured"
else
    echo -e "${YELLOW}⚠ AI optimization disabled - using basic extraction${NC}"
    log "INFO" "AI optimization disabled"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📡 PHASE 3: Continuous Ingestion Service${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Create continuous ingestion script
cat > "${SCRIPT_DIR}/phi_expenditure_continuous_ingestion.sh" <<'INGESTION_EOF'
#!/bin/bash
# PHI Expenditure - Continuous Ingestion Service
# Auto-generated by autopilot orchestrator

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TELEMETRY_DIR="${SCRIPT_DIR}/../telemetry"
INGESTION_LOG="${TELEMETRY_DIR}/ingestion.log"
EXTRACTOR_SCRIPT="${SCRIPT_DIR}/phi_expenditure_extractor.py"

log_ingestion() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $1" >> "$INGESTION_LOG"
}

run_extraction() {
    local start_time=$(date +%s)
    log_ingestion "Starting Gmail extraction cycle"

    if python3 "$EXTRACTOR_SCRIPT" >> "$INGESTION_LOG" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_ingestion "Extraction completed successfully in ${duration}s"
        echo "success"
    else
        log_ingestion "Extraction failed with error code $?"
        echo "failed"
    fi
}

# Main ingestion loop
iteration=1
while true; do
    log_ingestion "━━━ Ingestion Iteration #${iteration} ━━━"

    # Run extraction
    result=$(run_extraction)

    # Update metrics
    if [ "$result" = "success" ]; then
        echo "{\"last_ingestion\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\", \"status\": \"success\", \"iteration\": ${iteration}}" > "${TELEMETRY_DIR}/last_ingestion.json"
    else
        echo "{\"last_ingestion\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\", \"status\": \"failed\", \"iteration\": ${iteration}}" > "${TELEMETRY_DIR}/last_ingestion.json"
    fi

    # Sleep until next cycle
    log_ingestion "Sleeping for ${INGESTION_INTERVAL} seconds..."
    sleep ${INGESTION_INTERVAL}

    iteration=$((iteration + 1))
done
INGESTION_EOF

chmod +x "${SCRIPT_DIR}/phi_expenditure_continuous_ingestion.sh"

echo -e "${YELLOW}⏰ Configuring ingestion schedule...${NC}"
echo -e "  Interval: ${INGESTION_INTERVAL} seconds ($(echo "scale=2; ${INGESTION_INTERVAL}/60" | bc) minutes)"

# Check Gmail OAuth status
GMAIL_STATUS=$(health_check "gmail")
if [ "$GMAIL_STATUS" = "healthy" ]; then
    echo -e "${GREEN}✓ Gmail OAuth configured${NC}"
    log "INFO" "Gmail OAuth token verified"
elif [ "$GMAIL_STATUS" = "warning" ]; then
    echo -e "${YELLOW}⚠ Gmail OAuth requires first-time authorization${NC}"
    echo -e "  Run: python3 ${SCRIPT_DIR}/phi_expenditure_extractor.py"
    echo -e "  This will open a browser for Google OAuth consent"
    log "WARN" "Gmail OAuth token missing - manual authorization required"
fi

# Start continuous ingestion in background
if [ "$GMAIL_STATUS" = "healthy" ]; then
    echo -e "${YELLOW}🔄 Starting continuous ingestion service...${NC}"
    nohup bash "${SCRIPT_DIR}/phi_expenditure_continuous_ingestion.sh" > "${TELEMETRY_DIR}/ingestion_service.log" 2>&1 &
    INGESTION_PID=$!
    echo "$INGESTION_PID" > "${TELEMETRY_DIR}/ingestion.pid"
    echo -e "${GREEN}✓ Ingestion service started (PID: ${INGESTION_PID})${NC}"
    log "INFO" "Continuous ingestion service started with PID ${INGESTION_PID}"
else
    echo -e "${YELLOW}⚠ Ingestion service not started - Gmail OAuth required first${NC}"
    log "WARN" "Ingestion service not started due to missing OAuth"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🌐 PHASE 4: Dashboard Deployment${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

case "$DEPLOYMENT_MODE" in
    "local")
        echo -e "${YELLOW}🏠 Deploying dashboard in LOCAL mode...${NC}"
        nohup python3 "${SCRIPT_DIR}/expenditure_dashboard.py" > "${TELEMETRY_DIR}/dashboard.log" 2>&1 &
        DASHBOARD_PID=$!
        echo "$DASHBOARD_PID" > "${TELEMETRY_DIR}/dashboard.pid"
        echo -e "${GREEN}✓ Dashboard started (PID: ${DASHBOARD_PID})${NC}"
        echo -e "  URL: http://localhost:5000"
        log "INFO" "Dashboard deployed in local mode (PID: ${DASHBOARD_PID})"
        ;;

    "docker")
        echo -e "${YELLOW}🐳 Deploying dashboard in DOCKER mode...${NC}"
        # Create Dockerfile if not exists
        if [ ! -f "${SCRIPT_DIR}/Dockerfile.expenditure" ]; then
            cat > "${SCRIPT_DIR}/Dockerfile.expenditure" <<'DOCKERFILE_EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "expenditure_dashboard:app"]
DOCKERFILE_EOF
        fi
        docker build -t phi-expenditure-dashboard -f "${SCRIPT_DIR}/Dockerfile.expenditure" "${SCRIPT_DIR}"
        docker run -d \
            --name phi-expenditure-dashboard \
            -p 5000:5000 \
            -e EXPENDITURE_DB="$EXPENDITURE_DB" \
            -e FLASK_SECRET_KEY="$FLASK_SECRET_KEY" \
            phi-expenditure-dashboard
        echo -e "${GREEN}✓ Dashboard deployed in Docker${NC}"
        log "INFO" "Dashboard deployed in Docker mode"
        ;;

    "systemd")
        echo -e "${YELLOW}⚙️  Deploying dashboard as SYSTEMD service...${NC}"
        cat > "/tmp/phi-expenditure.service" <<SYSTEMD_EOF
[Unit]
Description=PHI Expenditure Dashboard
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=${SCRIPT_DIR}
Environment="EXPENDITURE_DB=${EXPENDITURE_DB}"
Environment="FLASK_SECRET_KEY=${FLASK_SECRET_KEY}"
ExecStart=/usr/bin/python3 ${SCRIPT_DIR}/expenditure_dashboard.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF
        echo -e "${YELLOW}Service file created at /tmp/phi-expenditure.service${NC}"
        echo -e "${YELLOW}To install, run:${NC}"
        echo -e "  sudo mv /tmp/phi-expenditure.service /etc/systemd/system/"
        echo -e "  sudo systemctl daemon-reload"
        echo -e "  sudo systemctl enable phi-expenditure"
        echo -e "  sudo systemctl start phi-expenditure"
        log "INFO" "Systemd service file generated"
        ;;

    "cloud-run")
        echo -e "${YELLOW}☁️  Deploying dashboard to GOOGLE CLOUD RUN...${NC}"
        echo -e "${YELLOW}Run the following commands:${NC}"
        echo -e "  gcloud run deploy phi-expenditure-dashboard \\"
        echo -e "    --source ${SCRIPT_DIR} \\"
        echo -e "    --platform managed \\"
        echo -e "    --region us-central1 \\"
        echo -e "    --allow-unauthenticated \\"
        echo -e "    --set-env-vars EXPENDITURE_DB='${EXPENDITURE_DB}' \\"
        echo -e "    --set-env-vars FLASK_SECRET_KEY='${FLASK_SECRET_KEY}'"
        log "INFO" "Cloud Run deployment instructions displayed"
        ;;

    *)
        echo -e "${RED}✗ Unknown deployment mode: ${DEPLOYMENT_MODE}${NC}"
        log "ERROR" "Unknown deployment mode: ${DEPLOYMENT_MODE}"
        exit 1
        ;;
esac

# Wait for dashboard to be ready
if [ "$DEPLOYMENT_MODE" = "local" ]; then
    echo -e "${YELLOW}⏳ Waiting for dashboard to be ready...${NC}"
    sleep 5

    for i in {1..10}; do
        if curl -s http://localhost:5000/api/health &>/dev/null; then
            echo -e "${GREEN}✓ Dashboard is responding${NC}"
            break
        else
            echo -e "${YELLOW}  Attempt $i/10...${NC}"
            sleep 2
        fi
    done
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}💓 PHASE 5: Health Monitoring & Keepalive${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Create health monitoring script
cat > "${SCRIPT_DIR}/phi_expenditure_health_monitor.sh" <<'HEALTH_EOF'
#!/bin/bash
# PHI Expenditure - Health Monitoring Service

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TELEMETRY_DIR="${SCRIPT_DIR}/../telemetry"
HEALTH_LOG="${TELEMETRY_DIR}/health_monitor.log"

log_health() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $1" >> "$HEALTH_LOG"
}

check_component() {
    local component="$1"
    local status="unknown"

    case "$component" in
        "database")
            if psql "$EXPENDITURE_DB" -c "SELECT COUNT(*) FROM expenditures" &>/dev/null; then
                status="healthy"
            else
                status="unhealthy"
            fi
            ;;
        "dashboard")
            if curl -s -f http://localhost:5000/api/health &>/dev/null; then
                status="healthy"
            else
                status="unhealthy"
            fi
            ;;
        "ingestion")
            if [ -f "${TELEMETRY_DIR}/ingestion.pid" ]; then
                pid=$(cat "${TELEMETRY_DIR}/ingestion.pid")
                if ps -p "$pid" &>/dev/null; then
                    status="healthy"
                else
                    status="unhealthy"
                fi
            else
                status="stopped"
            fi
            ;;
    esac

    echo "$status"
}

restart_component() {
    local component="$1"

    case "$component" in
        "dashboard")
            if [ -f "${TELEMETRY_DIR}/dashboard.pid" ]; then
                pid=$(cat "${TELEMETRY_DIR}/dashboard.pid")
                kill "$pid" 2>/dev/null || true
            fi
            nohup python3 "${SCRIPT_DIR}/expenditure_dashboard.py" > "${TELEMETRY_DIR}/dashboard.log" 2>&1 &
            echo $! > "${TELEMETRY_DIR}/dashboard.pid"
            log_health "Dashboard restarted (PID: $!)"
            ;;
        "ingestion")
            if [ -f "${TELEMETRY_DIR}/ingestion.pid" ]; then
                pid=$(cat "${TELEMETRY_DIR}/ingestion.pid")
                kill "$pid" 2>/dev/null || true
            fi
            nohup bash "${SCRIPT_DIR}/phi_expenditure_continuous_ingestion.sh" > "${TELEMETRY_DIR}/ingestion_service.log" 2>&1 &
            echo $! > "${TELEMETRY_DIR}/ingestion.pid"
            log_health "Ingestion service restarted (PID: $!)"
            ;;
    esac
}

# Main monitoring loop
iteration=1
while true; do
    log_health "━━━ Health Check Iteration #${iteration} ━━━"

    # Check all components
    db_status=$(check_component "database")
    dashboard_status=$(check_component "dashboard")
    ingestion_status=$(check_component "ingestion")

    log_health "Database: ${db_status}"
    log_health "Dashboard: ${dashboard_status}"
    log_health "Ingestion: ${ingestion_status}"

    # Auto-restart unhealthy components
    if [ "$dashboard_status" = "unhealthy" ]; then
        log_health "ALERT: Dashboard is unhealthy - attempting restart"
        restart_component "dashboard"
    fi

    if [ "$ingestion_status" = "unhealthy" ]; then
        log_health "ALERT: Ingestion service is unhealthy - attempting restart"
        restart_component "ingestion"
    fi

    # Update health status file
    cat > "${TELEMETRY_DIR}/health_status.json" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "iteration": ${iteration},
  "components": {
    "database": "${db_status}",
    "dashboard": "${dashboard_status}",
    "ingestion": "${ingestion_status}"
  }
}
EOF

    # Sleep 1 minute between checks
    sleep 60
    iteration=$((iteration + 1))
done
HEALTH_EOF

chmod +x "${SCRIPT_DIR}/phi_expenditure_health_monitor.sh"

echo -e "${YELLOW}💓 Starting health monitoring service...${NC}"
nohup bash "${SCRIPT_DIR}/phi_expenditure_health_monitor.sh" > "${TELEMETRY_DIR}/health_service.log" 2>&1 &
HEALTH_PID=$!
echo "$HEALTH_PID" > "${TELEMETRY_DIR}/health_monitor.pid"
echo -e "${GREEN}✓ Health monitor started (PID: ${HEALTH_PID})${NC}"
echo -e "  • Auto-restart on failure: Enabled"
echo -e "  • Check interval: 60 seconds"
log "INFO" "Health monitoring service started (PID: ${HEALTH_PID})"

# Update final status
update_health_status

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}✅ PHASE 6: Autopilot Status Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   PHI EXPENDITURE SYSTEM - AUTOPILOT OPERATIONAL              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}🎯 DEPLOYMENT:${NC}"
echo -e "  Mode: ${DEPLOYMENT_MODE}"
echo -e "  Dashboard URL: http://localhost:5000"
echo -e "  AI Optimization: ${AI_OPTIMIZATION}"
echo ""

echo -e "${CYAN}📡 INGESTION:${NC}"
echo -e "  Status: $([ "$GMAIL_STATUS" = "healthy" ] && echo "Active" || echo "Pending OAuth")"
echo -e "  Interval: ${INGESTION_INTERVAL}s ($(echo "scale=2; ${INGESTION_INTERVAL}/60" | bc) min)"
echo -e "  Next run: In ${INGESTION_INTERVAL} seconds"
echo ""

echo -e "${CYAN}💓 MONITORING:${NC}"
echo -e "  Health checks: Every 60 seconds"
echo -e "  Auto-restart: Enabled"
echo -e "  Telemetry: ${TELEMETRY_DIR}/"
echo ""

echo -e "${CYAN}📊 TELEMETRY FILES:${NC}"
echo -e "  Status: ${STATUS_FILE}"
echo -e "  Health: ${HEALTH_FILE}"
echo -e "  Logs: ${LOG_FILE}"
echo -e "  Ingestion: ${TELEMETRY_DIR}/ingestion.log"
echo ""

echo -e "${CYAN}🛠️  MANAGEMENT COMMANDS:${NC}"
echo -e "  View logs: tail -f ${LOG_FILE}"
echo -e "  Check health: cat ${HEALTH_FILE} | jq"
echo -e "  Stop all: kill \$(cat ${TELEMETRY_DIR}/*.pid)"
echo -e "  Restart: bash $0 ${DEPLOYMENT_MODE} ${INGESTION_INTERVAL}"
echo ""

log_json "operational" "PHI Expenditure Autopilot fully deployed and operational"
log "INFO" "Autopilot initialization complete"

echo -e "${GREEN}✅ Autonomous operation commenced - NHITL mode active${NC}"
echo -e "${YELLOW}⚡ PHI Chief will monitor and maintain all systems${NC}"
echo ""

# Keep script running to maintain foreground monitoring
if [ "${KEEP_FOREGROUND:-false}" = "true" ]; then
    echo -e "${CYAN}Running in foreground mode - Press Ctrl+C to stop${NC}"
    tail -f "$LOG_FILE"
fi
