#!/bin/bash
# PHI Expenditure System - Master Control
# Purpose: Central command & control for full autopilot operation
# Generated: 2026-02-27 by PHI Chief Sovereign Mode

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TELEMETRY_DIR="${SCRIPT_DIR}/../telemetry"
AUTOPILOT_SCRIPT="${SCRIPT_DIR}/phi_expenditure_autopilot.sh"

mkdir -p "$TELEMETRY_DIR"

# Banner
echo -e "${MAGENTA}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   ██████╗ ██╗  ██╗██╗    ███████╗██╗  ██╗██████╗ ███████╗███╗   ██╗   ║
║   ██╔══██╗██║  ██║██║    ██╔════╝╚██╗██╔╝██╔══██╗██╔════╝████╗  ██║   ║
║   ██████╔╝███████║██║    █████╗   ╚███╔╝ ██████╔╝█████╗  ██╔██╗ ██║   ║
║   ██╔═══╝ ██╔══██║██║    ██╔══╝   ██╔██╗ ██╔═══╝ ██╔══╝  ██║╚██╗██║   ║
║   ██║     ██║  ██║██║    ███████╗██╔╝ ██╗██║     ███████╗██║ ╚████║   ║
║   ╚═╝     ╚═╝  ╚═╝╚═╝    ╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═══╝   ║
║                                                                  ║
║            EXPENDITURE TRACKING SYSTEM - MASTER CONTROL         ║
║              Full Autopilot | NHITL Mode | AI-Optimized         ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Command dispatcher
COMMAND="${1:-status}"

show_usage() {
    echo -e "${CYAN}MASTER CONTROL - Command Reference${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC} $0 <command> [options]"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo -e "  ${GREEN}deploy${NC}       Deploy system in full autopilot mode"
    echo -e "  ${GREEN}start${NC}        Start all services"
    echo -e "  ${GREEN}stop${NC}         Stop all services gracefully"
    echo -e "  ${GREEN}restart${NC}      Restart all services"
    echo -e "  ${GREEN}status${NC}       Show system status"
    echo -e "  ${GREEN}health${NC}       Display health check results"
    echo -e "  ${GREEN}logs${NC}         Tail all service logs"
    echo -e "  ${GREEN}stats${NC}        Show operational statistics"
    echo -e "  ${GREEN}test${NC}         Run system tests"
    echo -e "  ${GREEN}cleanup${NC}      Stop and remove all services"
    echo ""
    echo -e "${CYAN}Deployment Modes:${NC}"
    echo -e "  local        Local development (default)"
    echo -e "  docker       Docker containerized"
    echo -e "  systemd      System service"
    echo -e "  cloud-run    Google Cloud Run"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "  $0 deploy local 3600        # Deploy locally, ingest every hour"
    echo -e "  $0 deploy docker 1800       # Deploy with Docker, ingest every 30min"
    echo -e "  $0 status                   # Check system status"
    echo -e "  $0 logs                     # Watch all logs"
    echo ""
}

get_pid_status() {
    local pid_file="$1"
    local service_name="$2"

    if [ -f "$pid_file" ]; then
        pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${GREEN}● ${service_name}: RUNNING${NC} (PID: $pid)"
            return 0
        else
            echo -e "${RED}● ${service_name}: DEAD${NC} (stale PID: $pid)"
            return 1
        fi
    else
        echo -e "${YELLOW}● ${service_name}: STOPPED${NC}"
        return 2
    fi
}

show_status() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📊 SYSTEM STATUS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Service status
    echo -e "${YELLOW}Services:${NC}"
    get_pid_status "${TELEMETRY_DIR}/dashboard.pid" "Dashboard"
    get_pid_status "${TELEMETRY_DIR}/ingestion.pid" "Ingestion Service"
    get_pid_status "${TELEMETRY_DIR}/health_monitor.pid" "Health Monitor"
    echo ""

    # Database status
    echo -e "${YELLOW}Database:${NC}"
    if psql "$EXPENDITURE_DB" -c "SELECT 1" &>/dev/null; then
        echo -e "${GREEN}● PostgreSQL: CONNECTED${NC}"

        # Get metrics
        expenditure_count=$(psql "$EXPENDITURE_DB" -t -c "SELECT COUNT(*) FROM expenditures" 2>/dev/null | xargs)
        pending_count=$(psql "$EXPENDITURE_DB" -t -c "SELECT COUNT(*) FROM expenditures WHERE verified = false" 2>/dev/null | xargs)
        vendor_count=$(psql "$EXPENDITURE_DB" -t -c "SELECT COUNT(DISTINCT vendor) FROM expenditures" 2>/dev/null | xargs)

        echo -e "  Total expenditures: ${expenditure_count:-0}"
        echo -e "  Pending verification: ${pending_count:-0}"
        echo -e "  Unique vendors: ${vendor_count:-0}"
    else
        echo -e "${RED}● PostgreSQL: DISCONNECTED${NC}"
    fi
    echo ""

    # Health status
    if [ -f "${TELEMETRY_DIR}/health_status.json" ]; then
        echo -e "${YELLOW}Health:${NC}"
        cat "${TELEMETRY_DIR}/health_status.json" | jq -r '
            "  Last check: \(.timestamp)",
            "  Database: \(.components.database)",
            "  Dashboard: \(.components.dashboard)",
            "  Ingestion: \(.components.ingestion)"
        ' 2>/dev/null || echo "  (Health data unavailable)"
    fi
    echo ""

    # Last ingestion
    if [ -f "${TELEMETRY_DIR}/last_ingestion.json" ]; then
        echo -e "${YELLOW}Last Ingestion:${NC}"
        cat "${TELEMETRY_DIR}/last_ingestion.json" | jq -r '
            "  Time: \(.last_ingestion)",
            "  Status: \(.status)",
            "  Iteration: \(.iteration)"
        ' 2>/dev/null || echo "  (Ingestion data unavailable)"
    fi
    echo ""
}

show_health() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}💓 HEALTH CHECK${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if [ -f "${TELEMETRY_DIR}/expenditure_health.json" ]; then
        cat "${TELEMETRY_DIR}/expenditure_health.json" | jq '.' || cat "${TELEMETRY_DIR}/expenditure_health.json"
    else
        echo -e "${YELLOW}No health data available yet${NC}"
        echo "Run: $0 deploy"
    fi
    echo ""
}

show_logs() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📜 SERVICE LOGS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Following all service logs... (Ctrl+C to stop)${NC}"
    echo ""

    # Tail all log files
    tail -f \
        "${TELEMETRY_DIR}/expenditure_autopilot.log" \
        "${TELEMETRY_DIR}/dashboard.log" \
        "${TELEMETRY_DIR}/ingestion.log" \
        "${TELEMETRY_DIR}/health_monitor.log" \
        2>/dev/null
}

show_stats() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📈 OPERATIONAL STATISTICS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if psql "$EXPENDITURE_DB" -c "SELECT 1" &>/dev/null; then
        echo -e "${YELLOW}Expenditure Statistics:${NC}"

        # Total and verified
        psql "$EXPENDITURE_DB" -c "
            SELECT
                COUNT(*) as total,
                SUM(CASE WHEN verified THEN 1 ELSE 0 END) as verified,
                SUM(CASE WHEN NOT verified THEN 1 ELSE 0 END) as pending
            FROM expenditures;
        " 2>/dev/null || echo "Query failed"

        echo ""
        echo -e "${YELLOW}By Confidence Level:${NC}"
        psql "$EXPENDITURE_DB" -c "
            SELECT
                confidence,
                COUNT(*) as count,
                ROUND(AVG(amount)::numeric, 2) as avg_amount,
                ROUND(SUM(amount)::numeric, 2) as total_amount
            FROM expenditures
            GROUP BY confidence
            ORDER BY confidence DESC;
        " 2>/dev/null || echo "Query failed"

        echo ""
        echo -e "${YELLOW}Top 10 Vendors by Spending:${NC}"
        psql "$EXPENDITURE_DB" -c "
            SELECT
                vendor,
                COUNT(*) as transactions,
                ROUND(SUM(amount)::numeric, 2) as total_spent
            FROM expenditures
            GROUP BY vendor
            ORDER BY SUM(amount) DESC
            LIMIT 10;
        " 2>/dev/null || echo "Query failed"

        echo ""
        echo -e "${YELLOW}Recent Activity (Last 7 Days):${NC}"
        psql "$EXPENDITURE_DB" -c "
            SELECT
                DATE(date) as day,
                COUNT(*) as transactions,
                ROUND(SUM(amount)::numeric, 2) as total
            FROM expenditures
            WHERE date >= CURRENT_DATE - INTERVAL '7 days'
            GROUP BY DATE(date)
            ORDER BY DATE(date) DESC;
        " 2>/dev/null || echo "Query failed"

    else
        echo -e "${RED}Cannot connect to database${NC}"
    fi
    echo ""
}

deploy_system() {
    local mode="${1:-local}"
    local interval="${2:-3600}"
    local ai_opt="${3:-enabled}"

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🚀 DEPLOYING SYSTEM${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Mode:${NC} $mode"
    echo -e "${YELLOW}Ingestion Interval:${NC} $interval seconds"
    echo -e "${YELLOW}AI Optimization:${NC} $ai_opt"
    echo ""

    # Run autopilot script
    bash "$AUTOPILOT_SCRIPT" "$mode" "$interval" "$ai_opt"
}

start_services() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}▶️  STARTING SERVICES${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Start dashboard
    if [ ! -f "${TELEMETRY_DIR}/dashboard.pid" ] || ! ps -p "$(cat ${TELEMETRY_DIR}/dashboard.pid)" > /dev/null 2>&1; then
        echo -e "${YELLOW}Starting dashboard...${NC}"
        nohup python3 "${SCRIPT_DIR}/expenditure_dashboard.py" > "${TELEMETRY_DIR}/dashboard.log" 2>&1 &
        echo $! > "${TELEMETRY_DIR}/dashboard.pid"
        echo -e "${GREEN}✓ Dashboard started (PID: $!)${NC}"
    else
        echo -e "${YELLOW}⚠ Dashboard already running${NC}"
    fi

    # Start ingestion (if OAuth is configured)
    if [ -f "${SCRIPT_DIR}/token.json" ]; then
        if [ ! -f "${TELEMETRY_DIR}/ingestion.pid" ] || ! ps -p "$(cat ${TELEMETRY_DIR}/ingestion.pid)" > /dev/null 2>&1; then
            echo -e "${YELLOW}Starting ingestion service...${NC}"
            nohup bash "${SCRIPT_DIR}/phi_expenditure_continuous_ingestion.sh" > "${TELEMETRY_DIR}/ingestion_service.log" 2>&1 &
            echo $! > "${TELEMETRY_DIR}/ingestion.pid"
            echo -e "${GREEN}✓ Ingestion service started (PID: $!)${NC}"
        else
            echo -e "${YELLOW}⚠ Ingestion service already running${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Gmail OAuth not configured - skipping ingestion service${NC}"
    fi

    # Start health monitor
    if [ ! -f "${TELEMETRY_DIR}/health_monitor.pid" ] || ! ps -p "$(cat ${TELEMETRY_DIR}/health_monitor.pid)" > /dev/null 2>&1; then
        echo -e "${YELLOW}Starting health monitor...${NC}"
        nohup bash "${SCRIPT_DIR}/phi_expenditure_health_monitor.sh" > "${TELEMETRY_DIR}/health_service.log" 2>&1 &
        echo $! > "${TELEMETRY_DIR}/health_monitor.pid"
        echo -e "${GREEN}✓ Health monitor started (PID: $!)${NC}"
    else
        echo -e "${YELLOW}⚠ Health monitor already running${NC}"
    fi

    echo ""
    echo -e "${GREEN}✅ All services started${NC}"
    echo ""
}

stop_services() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}⏹️  STOPPING SERVICES${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Stop all services
    for service in dashboard ingestion health_monitor; do
        pid_file="${TELEMETRY_DIR}/${service}.pid"
        if [ -f "$pid_file" ]; then
            pid=$(cat "$pid_file")
            if ps -p "$pid" > /dev/null 2>&1; then
                echo -e "${YELLOW}Stopping ${service} (PID: $pid)...${NC}"
                kill "$pid" 2>/dev/null || true
                sleep 1

                # Force kill if still running
                if ps -p "$pid" > /dev/null 2>&1; then
                    kill -9 "$pid" 2>/dev/null || true
                fi

                echo -e "${GREEN}✓ ${service} stopped${NC}"
            fi
            rm -f "$pid_file"
        fi
    done

    echo ""
    echo -e "${GREEN}✅ All services stopped${NC}"
    echo ""
}

run_tests() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🧪 RUNNING SYSTEM TESTS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Test database connection
    echo -e "${YELLOW}Testing database connection...${NC}"
    if psql "$EXPENDITURE_DB" -c "SELECT 1" &>/dev/null; then
        echo -e "${GREEN}✓ Database connection successful${NC}"
    else
        echo -e "${RED}✗ Database connection failed${NC}"
    fi

    # Test AI optimizer
    echo -e "${YELLOW}Testing AI optimizer...${NC}"
    if python3 "${SCRIPT_DIR}/phi_expenditure_ai_optimizer.py" --test &>/dev/null; then
        echo -e "${GREEN}✓ AI optimizer functional${NC}"
    else
        echo -e "${RED}✗ AI optimizer failed${NC}"
    fi

    # Test dashboard (if running)
    echo -e "${YELLOW}Testing dashboard endpoints...${NC}"
    if curl -s -f http://localhost:5000/api/health &>/dev/null; then
        echo -e "${GREEN}✓ Dashboard responding${NC}"
    else
        echo -e "${YELLOW}⚠ Dashboard not responding (may not be running)${NC}"
    fi

    echo ""
    echo -e "${GREEN}✅ Tests complete${NC}"
    echo ""
}

cleanup_system() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🧹 CLEANUP${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Stop all services first
    stop_services

    # Remove telemetry files
    echo -e "${YELLOW}Removing telemetry files...${NC}"
    rm -f "${TELEMETRY_DIR}"/expenditure_*.{log,json}
    rm -f "${TELEMETRY_DIR}"/{dashboard,ingestion,health_monitor,health_service,ingestion_service}.log
    rm -f "${TELEMETRY_DIR}"/{last_ingestion,health_status}.json
    echo -e "${GREEN}✓ Telemetry cleaned${NC}"

    echo ""
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    echo ""
}

# Main command dispatcher
case "$COMMAND" in
    deploy)
        deploy_system "${2:-local}" "${3:-3600}" "${4:-enabled}"
        ;;
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        stop_services
        sleep 2
        start_services
        ;;
    status)
        show_status
        ;;
    health)
        show_health
        ;;
    logs)
        show_logs
        ;;
    stats)
        show_stats
        ;;
    test)
        run_tests
        ;;
    cleanup)
        cleanup_system
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac
