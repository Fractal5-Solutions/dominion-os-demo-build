#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TELEMETRY_DIR="${SCRIPT_DIR}/telemetry"
SUPERVISOR_PID_FILE="${TELEMETRY_DIR}/monitor_supervisor.pid"
SUPERVISOR_LOCK_FILE="${TELEMETRY_DIR}/monitor_supervisor.lock"
SUPERVISOR_LOG="${TELEMETRY_DIR}/monitor_supervisor.log"
CHECK_INTERVAL="${PHI_SUPERVISOR_INTERVAL:-20}"
DETACHED_EXEC_SCRIPT="${SCRIPT_DIR}/detached_exec.sh"

CONTINUOUS_SCRIPT="${TELEMETRY_DIR}/continuous_monitor.sh"
CONTINUOUS_PID_FILE="${TELEMETRY_DIR}/monitor.pid"
SOVEREIGN_SCRIPT="${SCRIPT_DIR}/sovereign_monitor.sh"
SOVEREIGN_PID_FILE="${TELEMETRY_DIR}/sovereign_monitor_launcher.pid"
AUTO_AUDIT_SCRIPT="/workspaces/dominion-command-center/scripts/live_ops_auto_audit_daemon.sh"
AUTO_AUDIT_PID_FILE="/workspaces/dominion-command-center/out/audits/auto/daemon.pid"

mkdir -p "${TELEMETRY_DIR}"

log() {
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$1" | tee -a "${SUPERVISOR_LOG}"
}

is_pid_alive() {
  local pid="$1"
  [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null
}

with_lock_or_exit() {
  exec 9>"${SUPERVISOR_LOCK_FILE}"
  if command -v flock >/dev/null 2>&1; then
    if ! flock -n 9; then
      log "Another supervisor instance is active; exiting"
      exit 0
    fi
  fi
}

start_continuous_monitor() {
  if [ ! -x "${CONTINUOUS_SCRIPT}" ]; then
    log "continuous monitor script missing: ${CONTINUOUS_SCRIPT}"
    return 1
  fi

  nohup bash "${CONTINUOUS_SCRIPT}" >> "${TELEMETRY_DIR}/continuous_monitor.log" 2>&1 &
  local pid=$!
  echo "${pid}" > "${CONTINUOUS_PID_FILE}"
  log "Started continuous monitor (PID ${pid})"
}

start_sovereign_monitor() {
  nohup bash "${SOVEREIGN_SCRIPT}" >> "${TELEMETRY_DIR}/sovereign_monitor_boot.log" 2>&1 &
  local pid=$!
  echo "${pid}" > "${SOVEREIGN_PID_FILE}"
  log "Started sovereign monitor (PID ${pid})"
}

start_auto_audit_daemon() {
  if [ ! -x "${AUTO_AUDIT_SCRIPT}" ]; then
    log "auto audit daemon script missing: ${AUTO_AUDIT_SCRIPT}"
    return 1
  fi

  bash "${AUTO_AUDIT_SCRIPT}" start >> "${TELEMETRY_DIR}/monitor_supervisor.log" 2>&1 || true
  mkdir -p "$(dirname "${AUTO_AUDIT_PID_FILE}")"
  local pid=""
  if [ -f "${AUTO_AUDIT_PID_FILE}" ]; then
    pid="$(cat "${AUTO_AUDIT_PID_FILE}" 2>/dev/null || true)"
  fi
  log "Started auto audit daemon (PID ${pid})"
}

ensure_continuous_monitor() {
  local pid=""
  if [ -f "${CONTINUOUS_PID_FILE}" ]; then
    pid="$(cat "${CONTINUOUS_PID_FILE}" 2>/dev/null || true)"
  fi

  if is_pid_alive "${pid}"; then
    return 0
  fi

  start_continuous_monitor || true
}

ensure_sovereign_monitor() {
  local pid=""
  if [ -f "${SOVEREIGN_PID_FILE}" ]; then
    pid="$(cat "${SOVEREIGN_PID_FILE}" 2>/dev/null || true)"
  fi

  if is_pid_alive "${pid}"; then
    return 0
  fi

  start_sovereign_monitor || true
}

ensure_auto_audit_daemon() {
  local pid=""
  if [ -f "${AUTO_AUDIT_PID_FILE}" ]; then
    pid="$(cat "${AUTO_AUDIT_PID_FILE}" 2>/dev/null || true)"
  fi

  if is_pid_alive "${pid}"; then
    return 0
  fi

  start_auto_audit_daemon || true
}

run_supervisor() {
  with_lock_or_exit
  echo "$$" > "${SUPERVISOR_PID_FILE}"
  log "Monitor supervisor active (interval=${CHECK_INTERVAL}s)"

  trap 'rm -f "${SUPERVISOR_PID_FILE}"; log "Monitor supervisor stopped"; exit 0' INT TERM

  while true; do
    ensure_continuous_monitor
    ensure_sovereign_monitor
    ensure_auto_audit_daemon
    sleep "${CHECK_INTERVAL}"
  done
}

start_daemon() {
  if [ -f "${SUPERVISOR_PID_FILE}" ] && is_pid_alive "$(cat "${SUPERVISOR_PID_FILE}" 2>/dev/null || true)"; then
    log "Supervisor already running (PID $(cat "${SUPERVISOR_PID_FILE}"))"
    return 0
  fi

  local pid=""
  if [ -x "${DETACHED_EXEC_SCRIPT}" ]; then
    pid="$(bash "${DETACHED_EXEC_SCRIPT}" "${SUPERVISOR_PID_FILE}" "${SUPERVISOR_LOG}" "bash '$0' run" 2>/dev/null || true)"
  else
    nohup bash "$0" run >> "${SUPERVISOR_LOG}" 2>&1 &
    pid=$!
    echo "${pid}" > "${SUPERVISOR_PID_FILE}"
  fi

  if is_pid_alive "${pid}"; then
    log "Supervisor daemon started (PID ${pid})"
  else
    log "Supervisor daemon start attempt did not remain active"
  fi
}

stop_all() {
  local pid

  if [ -f "${SUPERVISOR_PID_FILE}" ]; then
    pid="$(cat "${SUPERVISOR_PID_FILE}" 2>/dev/null || true)"
    kill "${pid}" 2>/dev/null || true
    rm -f "${SUPERVISOR_PID_FILE}"
    log "Supervisor daemon stop requested"
  fi

  if [ -f "${CONTINUOUS_PID_FILE}" ]; then
    pid="$(cat "${CONTINUOUS_PID_FILE}" 2>/dev/null || true)"
    kill "${pid}" 2>/dev/null || true
    rm -f "${CONTINUOUS_PID_FILE}"
    log "Continuous monitor stop requested"
  fi

  if [ -f "${SOVEREIGN_PID_FILE}" ]; then
    pid="$(cat "${SOVEREIGN_PID_FILE}" 2>/dev/null || true)"
    kill "${pid}" 2>/dev/null || true
    rm -f "${SOVEREIGN_PID_FILE}"
    log "Sovereign monitor stop requested"
  fi

  if [ -f "${AUTO_AUDIT_PID_FILE}" ]; then
    pid="$(cat "${AUTO_AUDIT_PID_FILE}" 2>/dev/null || true)"
    kill "${pid}" 2>/dev/null || true
    rm -f "${AUTO_AUDIT_PID_FILE}"
    log "Auto audit daemon stop requested"
  fi
}

status_all() {
  local sup="stopped"
  local cm="stopped"
  local sm="stopped"
  local aa="stopped"

  if [ -f "${SUPERVISOR_PID_FILE}" ] && is_pid_alive "$(cat "${SUPERVISOR_PID_FILE}" 2>/dev/null || true)"; then
    sup="running(pid=$(cat "${SUPERVISOR_PID_FILE}"))"
  fi
  if [ -f "${CONTINUOUS_PID_FILE}" ] && is_pid_alive "$(cat "${CONTINUOUS_PID_FILE}" 2>/dev/null || true)"; then
    cm="running(pid=$(cat "${CONTINUOUS_PID_FILE}"))"
  fi
  if [ -f "${SOVEREIGN_PID_FILE}" ] && is_pid_alive "$(cat "${SOVEREIGN_PID_FILE}" 2>/dev/null || true)"; then
    sm="running(pid=$(cat "${SOVEREIGN_PID_FILE}"))"
  fi
  if [ -f "${AUTO_AUDIT_PID_FILE}" ] && is_pid_alive "$(cat "${AUTO_AUDIT_PID_FILE}" 2>/dev/null || true)"; then
    aa="running(pid=$(cat "${AUTO_AUDIT_PID_FILE}"))"
  fi

  printf 'supervisor=%s\ncontinuous_monitor=%s\nsovereign_monitor=%s\nauto_audit=%s\n' "${sup}" "${cm}" "${sm}" "${aa}"
}

case "${1:-start}" in
  start) start_daemon ;;
  run) run_supervisor ;;
  stop) stop_all ;;
  restart) stop_all; sleep 1; start_daemon ;;
  status) status_all ;;
  *)
    echo "Usage: $0 {start|run|stop|restart|status}"
    exit 1
    ;;
esac
