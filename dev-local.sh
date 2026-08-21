#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_DIR="$ROOT_DIR/amilab-maintenance-api"
ADMIN_DIR="$ROOT_DIR/amilab-maintenance-admin"
MOBILE_DIR="$ROOT_DIR/amilab-maintenance-mobile"
SHARED_DIR="$ROOT_DIR/amilab-maintenance-shared"
STATE_DIR="$ROOT_DIR/.local-dev"
LOG_DIR="$STATE_DIR/logs"
PID_DIR="$STATE_DIR/pids"

API_PORT="${AMILAB_API_PORT:-3000}"
ADMIN_PORT="${AMILAB_ADMIN_PORT:-4200}"
EXPO_PORT="${AMILAB_EXPO_PORT:-8081}"
DB_PORT="${AMILAB_DB_PORT:-5433}"
REDIS_PORT="${AMILABREDIS_PORT:-6379}"
TERMINAL_EMULATOR="${AMILAB_TERMINAL:-}"

mkdir -p "$LOG_DIR" "$PID_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { printf '[amilab] %s\n' "$*"; }
ok()   { printf "${GREEN}[amilab] ✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}[amilab] ⚠ %s${NC}\n" "$*"; }
err()  { printf "${RED}[amilab] ✗ %s${NC}\n" "$*" >&2; }
hdr()  { printf "\n${BOLD}${CYAN}═══ %s ═══${NC}\n" "$*"; }

service_log() { printf '%s/%s.log' "$LOG_DIR" "$1"; }
service_pid() { printf '%s/%s.pid' "$PID_DIR" "$1"; }

usage() {
  cat <<'EOF'
Uso:
  ./dev-local.sh setup      # instala dependencias (node, pnpm, docker)
  ./dev-local.sh doctor     # verifica que todo este listo
  ./dev-local.sh up         # levanta shared, db, api, admin, mobile
  ./dev-local.sh down       # detiene todo
  ./dev-local.sh restart    # down + up
  ./dev-local.sh status     # estado de servicios
  ./dev-local.sh logs [svc] # logs (shared|docker|api|admin|mobile)
  ./dev-local.sh build      # build producción (shared + api + admin)
  ./dev-local.sh deploy     # build + docker compose up -d (producción)
  ./dev-local.sh kill-ports # mata procesos en puertos
  ./dev-local.sh migrate    # ejecuta prisma migrate (cuando exista)

Variables opcionales:
  AMILAB_API_PORT, AMILAB_ADMIN_PORT, AMILAB_EXPO_PORT,
  AMILAB_DB_PORT, AMILAB_REDIS_PORT, AMILAB_TERMINAL
EOF
}

# ─── DETECCIÓN DE SISTEMA ────────────────────────────────────────────

detect_distro() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "${ID:-unknown}"
  elif command -v lsb_release >/dev/null 2>&1; then
    lsb_release -is | tr '[:upper:]' '[:lower:]'
  else
    echo "unknown"
  fi
}

detect_pkg_manager() {
  local distro
  distro="$(detect_distro)"
  case "$distro" in
    ubuntu|debian|kali|linuxmint|pop)
      echo "apt" ;;
    arch|manjaro|endeavouros)
      echo "pacman" ;;
    fedora)
      echo "dnf" ;;
    centos|rhel|rocky|alma)
      echo "yum" ;;
    alpine)
      echo "apk" ;;
    *)
      echo "unknown" ;;
  esac
}

# ─── SETUP: INSTALACIÓN AUTOMÁTICA ────────────────────────────────────

cmd_setup() {
  hdr "Setup — detectando sistema e instalando dependencias"

  local distro pkg_mgr
  distro="$(detect_distro)"
  pkg_mgr="$(detect_pkg_manager)"
  log "Distro: $distro | Package manager: $pkg_mgr"

  # Node.js
  if command -v node >/dev/null 2>&1; then
    ok "Node $(node -v)"
  else
    log "Instalando Node.js..."
    case "$pkg_mgr" in
      apt)
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 2>/dev/null
        sudo apt-get install -y nodejs >/dev/null 2>&1
        ;;
      pacman)
        sudo pacman -S --noconfirm nodejs npm >/dev/null 2>&1
        ;;
      dnf|yum)
        curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash - 2>/dev/null
        sudo "$pkg_mgr" install -y nodejs >/dev/null 2>&1
        ;;
      *)
        err "No se puede instalar Node.js automáticamente para $distro"
        err "Instala manualmente: https://nodejs.org/"
        return 1
        ;;
    esac
    ok "Node $(node -v)"
  fi

  # pnpm
  if command -v pnpm >/dev/null 2>&1; then
    ok "pnpm $(pnpm -v)"
  else
    log "Instalando pnpm..."
    npm install -g pnpm >/dev/null 2>&1
    ok "pnpm $(pnpm -v)"
  fi

  # Docker
  if command -v docker >/dev/null 2>&1; then
    ok "Docker $(docker --version | awk '{print $3}' | tr -d ',')"
  else
    log "Instalando Docker..."
    case "$pkg_mgr" in
      apt)
        sudo apt-get update -qq >/dev/null 2>&1
        sudo apt-get install -y docker.io docker-compose-plugin >/dev/null 2>&1
        ;;
      pacman)
        sudo pacman -S --noconfirm docker docker-compose >/dev/null 2>&1
        ;;
      dnf|yum)
        sudo "$pkg_mgr" install -y docker docker-compose-plugin >/dev/null 2>&1
        ;;
      *)
        curl -fsSL https://get.docker.com | sudo sh 2>/dev/null
        ;;
    esac
    sudo usermod -aG docker "${USER:-root}" 2>/dev/null || true
    sudo systemctl enable docker >/dev/null 2>&1 || true
    sudo systemctl start docker >/dev/null 2>&1 || true
    ok "Docker $(docker --version | awk '{print $3}' | tr -d ',')"
  fi

  # Docker Compose (plugin o standalone)
  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose $(docker compose version | awk '{print $NF}')"
  elif command -v docker-compose >/dev/null 2>&1; then
    ok "docker-compose $(docker-compose --version | awk '{print $NF}')"
  else
    log "Instalando Docker Compose plugin..."
    case "$pkg_mgr" in
      apt)
        sudo apt-get install -y docker-compose-plugin >/dev/null 2>&1
        ;;
      pacman)
        sudo pacman -S --noconfirm docker-compose >/dev/null 2>&1
        ;;
      *)
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f4)
        sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
          -o /usr/local/bin/docker-compose >/dev/null 2>&1
        sudo chmod +x /usr/local/bin/docker-compose
        ;;
    esac
    ok "Docker Compose instalado"
  fi

  # lsof (para kill-ports)
  if command -v lsof >/dev/null 2>&1; then
    ok "lsof"
  else
    log "Instalando lsof..."
    case "$pkg_mgr" in
      apt)    sudo apt-get install -y lsof >/dev/null 2>&1 ;;
      pacman) sudo pacman -S --noconfirm lsof >/dev/null 2>&1 ;;
      *)      sudo "$pkg_mgr" install -y lsof >/dev/null 2>&1 ;;
    esac
    ok "lsof"
  fi

  # curl
  if command -v curl >/dev/null 2>&1; then
    ok "curl"
  else
    case "$pkg_mgr" in
      apt)    sudo apt-get install -y curl >/dev/null 2>&1 ;;
      pacman) sudo pacman -S --noconfirm curl >/dev/null 2>&1 ;;
      *)      sudo "$pkg_mgr" install -y curl >/dev/null 2>&1 ;;
    esac
    ok "curl"
  fi

  # Instalar dependencias del proyecto
  hdr "Instalando dependencias del proyecto"
  (cd "$SHARED_DIR" && pnpm install --frozen-lockfile 2>/dev/null || pnpm install) >/dev/null 2>&1 && ok "shared" || warn "shared — instala manualmente"
  (cd "$API_DIR" && pnpm install --frozen-lockfile 2>/dev/null || pnpm install) >/dev/null 2>&1 && ok "api" || warn "api — instala manualmente"
  (cd "$ADMIN_DIR" && pnpm install --frozen-lockfile 2>/dev/null || pnpm install) >/dev/null 2>&1 && ok "admin" || warn "admin — instala manualmente"
  (cd "$MOBILE_DIR" && pnpm install --frozen-lockfile 2>/dev/null || pnpm install) >/dev/null 2>&1 && ok "mobile" || warn "mobile — instala manualmente"

  ok "Setup completo"
  log "Ejecuta: ./dev-local.sh doctor  para verificar"
}

# ─── DOCTOR: VERIFICACIÓN ─────────────────────────────────────────────

cmd_doctor() {
  hdr "Doctor — verificando entorno"
  local errors=0

  # Node
  if command -v node >/dev/null 2>&1; then
    local ver
    ver="$(node -v)"
    if [[ "$ver" > "v20" ]]; then
      ok "Node $ver"
    else
      warn "Node $ver (se recomienda >=22)"
      ((errors++))
    fi
  else
    err "Node.js NO encontrado"
    ((errors++))
  fi

  # pnpm
  if command -v pnpm >/dev/null 2>&1; then
    ok "pnpm $(pnpm -v)"
  else
    err "pnpm NO encontrado"
    ((errors++))
  fi

  # Docker
  if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
      ok "Docker daemon corriendo"
    else
      warn "Docker instalado pero daemon apagado"
      ((errors++))
    fi
  else
    err "Docker NO encontrado"
    ((errors++))
  fi

  # Docker Compose
  if docker compose version >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1; then
    ok "Docker Compose"
  else
    err "Docker Compose NO encontrado"
    ((errors++))
  fi

  # lsof
  if command -v lsof >/dev/null 2>&1; then ok "lsof"; else warn "lsof faltante (kill-ports no funcionará)"; fi

  # curl
  if command -v curl >/dev/null 2>&1; then ok "curl"; else warn "curl faltante"; fi

  # Proyectos
  hdr "Verificando proyecto"
  for dir in "$SHARED_DIR" "$API_DIR" "$ADMIN_DIR" "$MOBILE_DIR"; do
    local name
    name="$(basename "$dir")"
    if [[ -f "$dir/package.json" ]]; then
      if [[ -d "$dir/node_modules" ]]; then
        ok "$name — dependencias instaladas"
      else
        warn "$name — sin node_modules (ejecuta: cd $name && pnpm install)"
        ((errors++))
      fi
    else
      err "$name — package.json no encontrado"
      ((errors++))
    fi
  done

  # Docker services
  hdr "Verificando Docker services"
  (cd "$API_DIR" && docker compose ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null) || warn "Docker compose no disponible en API dir"

  # Puertos
  hdr "Verificando puertos"
  for port_name in "API:$API_PORT" "Admin:$ADMIN_PORT" "Expo:$EXPO_PORT" "DB:$DB_PORT" "Redis:$REDIS_PORT"; do
    local label="${port_name%%:*}"
    local port="${port_name##*:}"
    if is_port_in_use "$port"; then
      warn "$label — puerto $port en uso"
    else
      ok "$label — puerto $port libre"
    fi
  done

  printf "\n"
  if [[ $errors -eq 0 ]]; then
    ok "Todo listo. Ejecuta: ./dev-local.sh up"
  else
    warn "$errors problemas encontrados. Ejecuta: ./dev-local.sh setup"
  fi
  return $errors
}

# ─── FUNCIONES EXISTENTES ─────────────────────────────────────────────

detect_terminal_emulator() {
  # Check current session first
  if [[ -n "${DISPLAY:-}" && -n "$(command -v alacritty 2>/dev/null || true)" ]]; then
    printf '%s' "alacritty"
    return 0
  fi
  if [[ -n "${WAYLAND_DISPLAY:-}" && -n "$(command -v alacritty 2>/dev/null || true)" ]]; then
    printf '%s' "alacritty"
    return 0
  fi

  # Detect from running display server (for SSH sessions)
  local xdg_run="/run/user/$(id -u)"
  if [[ -d "$xdg_run" ]]; then
    local wayland_socket
    for wayland_socket in "$xdg_run"/wayland-*; do
      [[ -S "$wayland_socket" ]] && WAYLAND_DISPLAY="$(basename "$wayland_socket")" && export WAYLAND_DISPLAY && export XDG_RUNTIME_DIR="$xdg_run"
      if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v alacritty >/dev/null 2>&1; then
        printf '%s' "alacritty"
        return 0
      fi
    done
    local x11_sock="/tmp/.X11-unix/X0"
    if [[ -S "$x11_sock" ]]; then
      DISPLAY=":0" && export DISPLAY
      if command -v alacritty >/dev/null 2>&1; then
        printf '%s' "alacritty"
        return 0
      fi
    fi
  fi

  if [[ -n "${DISPLAY:-}" ]]; then
    for candidate in alacritty gnome-terminal x-terminal-emulator konsole kitty xfce4-terminal terminator xterm; do
      if command -v "$candidate" >/dev/null 2>&1; then printf '%s' "$candidate"; return 0; fi
    done
  fi

  return 1
}

is_running() {
  local pid_file="$1"
  [[ -f "$pid_file" ]] || return 1
  local pid; pid="$(<"$pid_file" 2>/dev/null || true)"
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null
}

is_port_in_use() {
  local port="$1"
  ss -ltn 2>/dev/null | awk -v needle=":$port" 'NR > 1 && $4 ~ needle { found = 1 } END { exit(found ? 0 : 1) }'
}

start_background() {
  local name="$1" workdir="$2"; shift 2
  local pid_file; pid_file="$(service_pid "$name")"
  if is_running "$pid_file"; then log "$name ya corriendo PID $(cat "$pid_file")"; return 0; fi
  local log_file; log_file="$(service_log "$name")"; : >"$log_file"
  local terminal_cmd
  if ! terminal_cmd="$(detect_terminal_emulator)"; then
    (cd "$workdir"; nohup "$@" >>"$log_file" 2>&1 & echo $! >"$pid_file")
    sleep 1
    if ! is_running "$pid_file"; then err "No pude levantar $name. Revisa $log_file"; return 1; fi
    log "$name arriba PID $(cat "$pid_file")"; return 0
  fi
  local child_pid
  case "$terminal_cmd" in
    alacritty) "$terminal_cmd" --title "Amilab $name" --working-directory "$workdir" --hold -e bash -lc 'cd "$PWD" && exec "$@"' bash "$@" >"$log_file" 2>&1 & child_pid=$! ;;
    gnome-terminal) "$terminal_cmd" --title="Amilab $name" --working-directory="$workdir" -- bash -lc 'cd "$PWD" && exec "$@"' bash "$@" >"$log_file" 2>&1 & child_pid=$! ;;
    konsole) "$terminal_cmd" --new-tab --title "Amilab $name" -e bash -lc 'cd "$PWD" && exec "$@"' bash "$@" >"$log_file" 2>&1 & child_pid=$! ;;
    kitty) "$terminal_cmd" --title "Amilab $name" --working-directory "$workdir" bash -lc 'cd "$PWD" && exec "$@"' bash "$@" >"$log_file" 2>&1 & child_pid=$! ;;
    *) "$terminal_cmd" -T "Amilab $name" -e bash -lc 'cd "$PWD" && exec "$@"' bash "$@" >"$log_file" 2>&1 & child_pid=$! ;;
  esac
  echo "$child_pid" >"$pid_file"; sleep 2
  log "$name enviado a terminal PID $child_pid"; return 0
}

stop_background() {
  local name="$1" pid_file; pid_file="$(service_pid "$name")"
  [[ -f "$pid_file" ]] || { log "$name sin PID"; return 0; }
  local pid; pid="$(cat "$pid_file")"
  if kill -0 "$pid" 2>/dev/null; then kill "$pid" 2>/dev/null || true; sleep 1; kill -9 "$pid" 2>/dev/null || true; log "$name detenido"; else log "$name ya no corria"; fi
  rm -f "$pid_file"
}

kill_port() {
  local port="$1" label="$2" pids
  pids="$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"
  [[ -z "$pids" ]] && { log "$label libre en $port"; return 0; }
  log "Deteniendo $label en $port: $pids"; kill $pids 2>/dev/null || true; sleep 1
  pids="$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"
  [[ -n "$pids" ]] && kill -9 $pids 2>/dev/null || true
}

kill_ports() { kill_port "$EXPO_PORT" "Expo"; kill_port "$ADMIN_PORT" "Admin"; kill_port "$API_PORT" "API"; }

wait_for_http() {
  local name="$1" url="$2" attempts="${3:-30}"
  for ((i = 1; i <= attempts; i++)); do
    curl -fsS "$url" >/dev/null 2>&1 && { log "$name responde en $url"; return 0; }
    sleep 1
  done
  log "$name no respondio en $url"; return 1
}

detect_lan_ip() {
  local detected
  detected="$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i=1;i<=NF;i++) if ($i == "src") {print $(i+1); exit}}')"
  [[ -n "$detected" ]] && { printf '%s' "$detected"; return 0; }
  detected="$(hostname -I 2>/dev/null | awk '{print $1}')"
  printf '%s' "$detected"
}

write_mobile_env() {
  local lan_ip; lan_ip="$(detect_lan_ip)"
  [[ -z "$lan_ip" ]] && { log "No se detectó IP LAN"; return 0; }
  cat >"$MOBILE_DIR/.env" <<EOF
EXPO_PUBLIC_API_BASE_URL=http://$lan_ip:$API_PORT/api
EXPO_PUBLIC_SOCKET_BASE_URL=http://$lan_ip:$API_PORT
EOF
  log "Mobile .env → LAN $lan_ip"
}

start_network_watcher() {
  local pid_file; pid_file="$(service_pid netwatch)"
  if is_running "$pid_file"; then return 0; fi
  (
    local last_ip=""
    while true; do
      local current_ip; current_ip="$(detect_lan_ip)"
      if [[ -n "$current_ip" && "$current_ip" != "$last_ip" ]]; then
        if [[ -n "$last_ip" ]]; then
          warn "Red cambió: $last_ip → $current_ip"
          write_mobile_env
          ok "Mobile .env actualizado para $current_ip"
        fi
        last_ip="$current_ip"
      fi
      sleep 5
    done
  ) &
  echo $! >"$pid_file"
  log "Network watcher PID $!"
}

stop_network_watcher() {
  local pid_file; pid_file="$(service_pid netwatch)"
  [[ -f "$pid_file" ]] || return 0
  local pid; pid="$(cat "$pid_file")"
  kill "$pid" 2>/dev/null || true
  rm -f "$pid_file"
}

# ─── START FUNCTIONS ──────────────────────────────────────────────────

start_shared() {
  log "Construyendo shared..."
  (cd "$SHARED_DIR" && pnpm build >"$(service_log shared)" 2>&1)
  ok "shared listo"
  start_background shared "$SHARED_DIR" pnpm exec tsc -w -p tsconfig.json --preserveWatchOutput
}

start_db() {
  log "Levantando Postgres y Redis..."
  (cd "$API_DIR" && docker compose up -d >>"$(service_log docker)" 2>&1)
  ok "Docker services arrancados"
}

start_api() {
  if wait_for_http "API existente" "http://127.0.0.1:$API_PORT/api/health" 2 >/dev/null 2>&1; then ok "API ya en $API_PORT"; return 0; fi
  start_background api "$API_DIR" pnpm start:dev
  wait_for_http "API" "http://127.0.0.1:$API_PORT/api/health" 40 && ok "API lista" || warn "API lenta"
}

start_admin() {
  if wait_for_http "Admin existente" "http://127.0.0.1:$ADMIN_PORT/" 2 >/dev/null 2>&1; then ok "Admin ya en $ADMIN_PORT"; return 0; fi
  start_background admin "$ADMIN_DIR" pnpm exec next dev --turbopack -p "$ADMIN_PORT"
  wait_for_http "Admin" "http://127.0.0.1:$ADMIN_PORT/" 40 && ok "Admin listo" || warn "Admin lento"
}

start_mobile() {
  write_mobile_env
  if is_port_in_use "$EXPO_PORT"; then ok "Expo ya en $EXPO_PORT"; return 0; fi

  local pid_file; pid_file="$(service_pid mobile)"
  local log_file; log_file="$(service_log mobile)"; : >"$log_file"

  local terminal_cmd
  if terminal_cmd="$(detect_terminal_emulator 2>/dev/null)"; then
    case "$terminal_cmd" in
      alacritty) "$terminal_cmd" --title "Amilab mobile" --working-directory "$MOBILE_DIR" --hold -e bash -lc 'cd "$PWD" && exec "$@"' bash env CI=1 pnpm exec expo start --host lan --port "$EXPO_PORT" --clear &
        echo $! >"$pid_file" ;;
      gnome-terminal) "$terminal_cmd" --title="Amilab mobile" --working-directory="$MOBILE_DIR" -- bash -lc 'cd "$PWD" && exec "$@"' bash env CI=1 pnpm exec expo start --host lan --port "$EXPO_PORT" --clear &
        echo $! >"$pid_file" ;;
      *) "$terminal_cmd" -T "Amilab mobile" -e bash -lc 'cd "$PWD" && exec "$@"' bash env CI=1 pnpm exec expo start --host lan --port "$EXPO_PORT" --clear &
        echo $! >"$pid_file" ;;
    esac
  else
    (cd "$MOBILE_DIR"; nohup env CI=1 pnpm exec expo start --host lan --port "$EXPO_PORT" --clear >>"$log_file" 2>&1 &
      echo $! >"$pid_file")
  fi

  sleep 4
  for ((i = 1; i <= 20; i++)); do
    if is_port_in_use "$EXPO_PORT"; then
      ok "Expo listo en $EXPO_PORT"
      local lan_ip; lan_ip="$(detect_lan_ip)"
      printf "\n${BOLD}${CYAN}═══ MOBILE ═══${NC}\n"
      printf "  Expo Go: ${BOLD}http://%s:%s${NC}\n" "$lan_ip" "$EXPO_PORT"
      printf "  API:     ${BOLD}http://%s:%s/api${NC}\n" "$lan_ip" "$API_PORT"
      printf "  Admin:   ${BOLD}http://%s:%s${NC}\n" "$lan_ip" "$ADMIN_PORT"
      if [[ -s "$log_file" ]]; then
        printf "\n${DIM}Log:${NC}\n"
        grep -iE "exp|qr|url|http|ready|network|metro" "$log_file" 2>/dev/null | tail -10 || tail -n 5 "$log_file" 2>/dev/null
      fi
      printf "\n"
      return 0
    fi
    sleep 1
  done
  warn "Expo no quedó listo. Revisa: tail -f $(service_log mobile)"
}

# ─── SHOW STATUS ──────────────────────────────────────────────────────

show_status() {
  hdr "Estado"
  for service in shared api admin mobile; do
    local pid_file; pid_file="$(service_pid "$service")"
    local port=""
    case "$service" in api) port="$API_PORT" ;; admin) port="$ADMIN_PORT" ;; mobile) port="$EXPO_PORT" ;; esac
    if is_running "$pid_file"; then
      printf "  ${GREEN}%-10s running (PID %s)${NC}\n" "$service" "$(cat "$pid_file")"
    elif [[ -n "$port" ]] && is_port_in_use "$port"; then
      printf "  ${YELLOW}%-10s listening on %s (externo)${NC}\n" "$service" "$port"
    else
      printf "  ${RED}%-10s stopped${NC}\n" "$service"
    fi
  done
  (cd "$API_DIR" && docker compose ps 2>/dev/null) || true
  printf "\n${BOLD}URLs:${NC}\n"
  printf "  API:   http://localhost:%s/api\n" "$API_PORT"
  printf "  Admin: http://localhost:%s/\n" "$ADMIN_PORT"
  printf "  Expo:  http://localhost:%s\n" "$EXPO_PORT"
  local lan_ip; lan_ip="$(detect_lan_ip)"
  [[ -n "$lan_ip" ]] && printf "  LAN:   http://%s:%s (API)\n" "$lan_ip" "$API_PORT"
}

# ─── DEPLOY PRODUCCIÓN ────────────────────────────────────────────────

cmd_build() {
  hdr "Build producción"
  log "Building shared..."
  (cd "$SHARED_DIR" && pnpm install && pnpm build) && ok "shared" || { err "shared falló"; return 1; }
  log "Building API..."
  (cd "$API_DIR" && pnpm install && pnpm build) && ok "api" || { err "api falló"; return 1; }
  log "Building Admin..."
  (cd "$ADMIN_DIR" && pnpm install && pnpm build) && ok "admin" || { err "admin falló"; return 1; }
  ok "Build completo"
}

cmd_deploy() {
  hdr "Deploy producción"
  cmd_build
  log "Levantando Docker services..."
  (cd "$API_DIR" && docker compose up -d --build) && ok "Docker services" || { err "Docker falló"; return 1; }
  log "Esperando que API responda..."
  wait_for_http "API" "http://127.0.0.1:$API_PORT/api/health" 60 && ok "API desplegada" || warn "API no respondió"
  ok "Deploy completo"
  show_status
}

cmd_migrate() {
  hdr "Migraciones"
  if [[ -d "$API_DIR/prisma" ]]; then
    (cd "$API_DIR" && pnpm prisma migrate deploy) && ok "Migraciones aplicadas" || err "Migraciones fallaron"
  elif [[ -d "$API_DIR/src" ]] && grep -q "typeorm" "$API_DIR/package.json" 2>/dev/null; then
    (cd "$API_DIR" && pnpm start:prod) && ok "TypeORM sync" || warn "Revisar migraciones manualmente"
  else
    warn "No se encontró prisma/ ni typeorm en API"
  fi
}

# ─── UP / DOWN / RESTART ─────────────────────────────────────────────

up() {
  hdr "Levantando Amilab"
  start_shared
  start_db
  start_api
  start_admin
  start_mobile
  start_network_watcher
  show_status
}

down() {
  hdr "Deteniendo Amilab"
  stop_network_watcher
  stop_background mobile; stop_background admin; stop_background api; stop_background shared
  (cd "$API_DIR" && docker compose down >>"$(service_log docker)" 2>&1 || true)
  ok "Todo detenido"
}

show_logs() {
  local target="${1:-}"
  if [[ -z "$target" ]]; then
    printf 'Logs: %s\n' "$LOG_DIR"
    ls -1t "$LOG_DIR" 2>/dev/null; return 0
  fi
  local file; file="$(service_log "$target")"
  [[ -f "$file" ]] || { err "No existe log para $target"; return 1; }
  tail -n 120 -f "$file"
}

# ─── MAIN ─────────────────────────────────────────────────────────────

command="${1:-up}"

case "$command" in
  setup)      cmd_setup ;;
  doctor)     cmd_doctor ;;
  up)         up ;;
  down)       down ;;
  restart)    down; up ;;
  status)     show_status ;;
  logs)       show_logs "${2:-}" ;;
  build)      cmd_build ;;
  deploy)     cmd_deploy ;;
  migrate)    cmd_migrate ;;
  kill-ports) kill_ports ;;
  *)          usage; exit 1 ;;
esac
