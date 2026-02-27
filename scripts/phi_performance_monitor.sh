#!/bin/bash
# PHI Performance Monitor - Autonomous Service Benchmarking
# Purpose: Continuous performance testing and anomaly detection
# Authority: Level 9/9 Sovereign Power
# Interval: Every 15 minutes

set -e

TELEMETRY_DIR="/workspaces/dominion-os-demo-build/telemetry"
PERFORMANCE_DIR="$TELEMETRY_DIR/performance"
LOG_FILE="$TELEMETRY_DIR/performance.log"
STOP_FILE="$TELEMETRY_DIR/STOP_AUTONOMOUS"

mkdir -p "$PERFORMANCE_DIR"

log() {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] $1" | tee -a "$LOG_FILE"
}

# Banner
cat << 'EOF' | tee -a "$LOG_FILE"

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   PHI PERFORMANCE MONITOR                                    ║
║   Autonomous Service Benchmarking & Anomaly Detection         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

EOF

log "Timestamp: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
log "Authority: 9/9 Sovereign Power"
log "Mode: Continuous Performance Monitoring"
log "Check Interval: 15 minutes"
log ""

# Performance thresholds (milliseconds)
THRESHOLD_EXCELLENT=100
THRESHOLD_GOOD=300
THRESHOLD_ACCEPTABLE=1000
THRESHOLD_SLOW=3000

cycle=0

while true; do
    # Check for stop signal
    if [ -f "$STOP_FILE" ]; then
        log "⚠ STOP signal detected - shutting down gracefully"
        exit 0
    fi

    cycle=$((cycle + 1))
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "PERFORMANCE CYCLE #$cycle"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""

    # Get all Cloud Run services
    log "[1/5] Discovering services..."

    services_p1=$(gcloud run services list --project=dominion-os-1-0-main --format="value(name,status.url)" 2>/dev/null || echo "")
    services_p2=$(gcloud run services list --project=dominion-core-prod --format="value(name,status.url)" 2>/dev/null || echo "")

    total_services=0
    tested_services=0
    excellent_count=0
    good_count=0
    acceptable_count=0
    slow_count=0
    failed_count=0

    results_file="$PERFORMANCE_DIR/cycle_${cycle}.json"
    echo "{" > "$results_file"
    echo "  \"cycle\": $cycle," >> "$results_file"
    echo "  \"timestamp\": \"$(date -u +"%Y-%m-%d %H:%M:%S UTC")\"," >> "$results_file"
    echo "  \"services\": [" >> "$results_file"

    log "  ✓ Services discovered"
    log ""
    log "[2/5] Running performance tests..."

    first=true

    # Test project 1 services
    while IFS=$'\t' read -r name url; do
        [ -z "$name" ] && continue
        total_services=$((total_services + 1))

        # Add comma for JSON array
        if [ "$first" = false ]; then
            echo "," >> "$results_file"
        fi
        first=false

        log "  Testing: $name"

        # Perform HTTP request and measure time
        start_time=$(date +%s%3N)
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
        end_time=$(date +%s%3N)
        response_time=$((end_time - start_time))

        # Determine status
        if [ "$http_code" = "000" ]; then
            status="failed"
            rating="FAILED"
            failed_count=$((failed_count + 1))
        elif [ $response_time -le $THRESHOLD_EXCELLENT ]; then
            status="excellent"
            rating="EXCELLENT"
            excellent_count=$((excellent_count + 1))
            tested_services=$((tested_services + 1))
        elif [ $response_time -le $THRESHOLD_GOOD ]; then
            status="good"
            rating="GOOD"
            good_count=$((good_count + 1))
            tested_services=$((tested_services + 1))
        elif [ $response_time -le $THRESHOLD_ACCEPTABLE ]; then
            status="acceptable"
            rating="ACCEPTABLE"
            acceptable_count=$((acceptable_count + 1))
            tested_services=$((tested_services + 1))
        elif [ $response_time -le $THRESHOLD_SLOW ]; then
            status="slow"
            rating="SLOW"
            slow_count=$((slow_count + 1))
            tested_services=$((tested_services + 1))
        else
            status="timeout"
            rating="TIMEOUT"
            failed_count=$((failed_count + 1))
        fi

        log "    → ${response_time}ms (HTTP $http_code) [$rating]"

        # Write JSON
        cat >> "$results_file" << JSONEOF
    {
      "name": "$name",
      "project": "dominion-os-1-0-main",
      "url": "$url",
      "response_time_ms": $response_time,
      "http_code": "$http_code",
      "status": "$status",
      "rating": "$rating"
    }
JSONEOF

    done <<< "$services_p1"

    # Test project 2 services
    while IFS=$'\t' read -r name url; do
        [ -z "$name" ] && continue
        total_services=$((total_services + 1))

        # Add comma for JSON array
        if [ "$first" = false ]; then
            echo "," >> "$results_file"
        fi
        first=false

        log "  Testing: $name"

        # Perform HTTP request and measure time
        start_time=$(date +%s%3N)
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
        end_time=$(date +%s%3N)
        response_time=$((end_time - start_time))

        # Determine status
        if [ "$http_code" = "000" ]; then
            status="failed"
            rating="FAILED"
            failed_count=$((failed_count + 1))
        elif [ $response_time -le $THRESHOLD_EXCELLENT ]; then
            status="excellent"
            rating="EXCELLENT"
            excellent_count=$((excellent_count + 1))
            tested_services=$((tested_services + 1))
        elif [ $response_time -le $THRESHOLD_GOOD ]; then
            status="good"
            rating="GOOD"
            good_count=$((good_count + 1))
            tested_services=$((tested_services + 1))
        elif [ $response_time -le $THRESHOLD_ACCEPTABLE ]; then
            status="acceptable"
            rating="ACCEPTABLE"
            acceptable_count=$((acceptable_count + 1))
            tested_services=$((tested_services + 1))
        elif [ $response_time -le $THRESHOLD_SLOW ]; then
            status="slow"
            rating="SLOW"
            slow_count=$((slow_count + 1))
            tested_services=$((tested_services + 1))
        else
            status="timeout"
            rating="TIMEOUT"
            failed_count=$((failed_count + 1))
        fi

        log "    → ${response_time}ms (HTTP $http_code) [$rating]"

        # Write JSON
        cat >> "$results_file" << JSONEOF
    {
      "name": "$name",
      "project": "dominion-core-prod",
      "url": "$url",
      "response_time_ms": $response_time,
      "http_code": "$http_code",
      "status": "$status",
      "rating": "$rating"
    }
JSONEOF

    done <<< "$services_p2"

    log ""
    log "[3/5] Analyzing results..."

    # Close JSON
    echo "" >> "$results_file"
    echo "  ]," >> "$results_file"
    echo "  \"summary\": {" >> "$results_file"
    echo "    \"total_services\": $total_services," >> "$results_file"
    echo "    \"tested_services\": $tested_services," >> "$results_file"
    echo "    \"excellent\": $excellent_count," >> "$results_file"
    echo "    \"good\": $good_count," >> "$results_file"
    echo "    \"acceptable\": $acceptable_count," >> "$results_file"
    echo "    \"slow\": $slow_count," >> "$results_file"
    echo "    \"failed\": $failed_count" >> "$results_file"
    echo "  }" >> "$results_file"
    echo "}" >> "$results_file"

    log "  ✓ Performance data analyzed"
    log ""
    log "[4/5] Generating recommendations..."

    # Anomaly detection
    anomalies=0
    recommendations=""

    if [ $failed_count -gt 0 ]; then
        anomalies=$((anomalies + 1))
        recommendations="${recommendations}\n     • Investigate $failed_count failed service(s) - possible downtime"
    fi

    if [ $slow_count -gt 0 ]; then
        anomalies=$((anomalies + 1))
        recommendations="${recommendations}\n     • Review $slow_count slow service(s) - performance degradation detected"
    fi

    if [ $anomalies -eq 0 ]; then
        log "  ✓ No anomalies detected - all systems performing optimally"
        recommendations="     • All services within acceptable performance thresholds\n     • Continue monitoring for baseline establishment"
    else
        log "  ⚠ $anomalies anomalie(s) detected"
    fi

    log ""
    log "[5/5] Summary & Recommendations..."
    log "  📊 Performance Distribution:"
    log "     • Excellent (<${THRESHOLD_EXCELLENT}ms): $excellent_count services"
    log "     • Good (<${THRESHOLD_GOOD}ms): $good_count services"
    log "     • Acceptable (<${THRESHOLD_ACCEPTABLE}ms): $acceptable_count services"
    log "     • Slow (<${THRESHOLD_SLOW}ms): $slow_count services"
    log "     • Failed: $failed_count services"
    log ""
    log "  📋 Recommendations:"
    echo -e "$recommendations" | tee -a "$LOG_FILE"
    log ""

    # Create summary
    summary_file="$PERFORMANCE_DIR/latest_summary.json"
    cp "$results_file" "$summary_file"

    log "╔═══════════════════════════════════════════════════════════════╗"
    log "║  CYCLE #$cycle COMPLETE                                          "
    log "║  Tested: $tested_services/$total_services | Excellent: $excellent_count | Good: $good_count | Acceptable: $acceptable_count"
    log "╚═══════════════════════════════════════════════════════════════╝"
    log ""
    log "⏳ Next performance cycle in 15 minutes..."
    log ""

    # Sleep for 15 minutes (900 seconds)
    sleep 900
done
