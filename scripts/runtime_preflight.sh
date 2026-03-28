#!/bin/bash
set -euo pipefail

docker_cli_available() {
    command -v docker >/dev/null 2>&1
}

docker_daemon_available() {
    docker_cli_available && docker info >/dev/null 2>&1
}

docker_runtime_blocked() {
    if ! docker_cli_available; then
        return 0
    fi

    if docker_daemon_available; then
        return 1
    fi

    case "$(docker info 2>&1 || true)" in
        *"Cannot connect to the Docker daemon"*)
            return 0
            ;;
    esac

    return 1
}

print_docker_runtime_note() {
    local context="${1:-docker operations}"

    cat <<EOF
[RUNTIME LIMITATION]
$context requires a reachable Docker daemon.
Docker CLI is present, but this runtime cannot connect to docker.sock.
Use local non-Docker verification here, or rerun on a Docker-enabled host.
EOF
}
