#!/usr/bin/env bash
set -euo pipefail

# =========================================
# Configuração básica
# =========================================
DOMAIN="${DOMAIN:-exemplo.com}"
UPSTREAM_NAME="${UPSTREAM_NAME:-backend_pool}"
LB_METHOD="${LB_METHOD:-least_conn}"   # round_robin | least_conn | ip_hash
NGINX_CONF="${NGINX_CONF:-/etc/nginx/sites-available/${DOMAIN}.conf}"
NGINX_LINK="${NGINX_LINK:-/etc/nginx/sites-enabled/${DOMAIN}.conf}"

# Backends separados por espaço
# Exemplo:
# BACKENDS="10.0.0.11:8080 10.0.0.12:8080 10.0.0.13:8080"
BACKENDS="${BACKENDS:-127.0.0.1:3000 127.0.0.1:3001}"

# Porta pública
LISTEN_PORT="${LISTEN_PORT:-80}"

# Timeouts
PROXY_CONNECT_TIMEOUT="${PROXY_CONNECT_TIMEOUT:-5s}"
PROXY_SEND_TIMEOUT="${PROXY_SEND_TIMEOUT:-60s}"
PROXY_READ_TIMEOUT="${PROXY_READ_TIMEOUT:-60s}"
SEND_TIMEOUT="${SEND_TIMEOUT:-60s}"

# =========================================
# Funções auxiliares
# =========================================
log() {
  printf '[+] %s\n' "$*"
}

err() {
  printf '[!] %s\n' "$*" >&2
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "Este script precisa ser executado como root."
    exit 1
  fi
}

detect_pkg_manager() {
  if command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v apk >/dev/null 2>&1; then
    echo "apk"
  else
    echo ""
  fi
}

install_nginx() {
  if command -v nginx >/dev/null 2>&1; then
    log "Nginx já está instalado."
    return
  fi

  local pm
  pm="$(detect_pkg_manager)"

  case "$pm" in
    apt)
      log "Instalando Nginx via apt..."
      apt update -y
      apt install -y nginx
      ;;
    dnf)
      log "Instalando Nginx via dnf..."
      dnf install -y nginx
      ;;
    yum)
      log "Instalando Nginx via yum..."
      yum install -y epel-release || true
      yum install -y nginx
      ;;
    apk)
      log "Instalando Nginx via apk..."
      apk add --no-cache nginx
      ;;
    *)
      err "Gerenciador de pacotes não suportado. Instale o Nginx manualmente."
      exit 1
      ;;
  esac
}

enable_service() {
  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable nginx
    systemctl restart nginx
  else
    rc-service nginx restart || true
    rc-update add nginx default || true
  fi
}

build_upstream_block() {
  local servers=""
  local backend

  for backend in $BACKENDS; do
    servers+="    server ${backend} max_fails=3 fail_timeout=10s;\n"
  done

  case "$LB_METHOD" in
    least_conn)
      printf "upstream %s {\n    least_conn;\n%b}\n" "$UPSTREAM_NAME" "$servers"
      ;;
    ip_hash)
      printf "upstream %s {\n    ip_hash;\n%b}\n" "$UPSTREAM_NAME" "$servers"
      ;;
    round_robin)
      printf "upstream %s {\n%b}\n" "$UPSTREAM_NAME" "$servers"
      ;;
    *)
      err "Método de balanceamento inválido: $LB_METHOD"
      err "Use: round_robin | least_conn | ip_hash"
      exit 1
      ;;
  esac
}

write_nginx_config() {
  mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

  local upstream_block
  upstream_block="$(build_upstream_block)"

  cat > "$NGINX_CONF" <<EOF
# Gerado automaticamente por setup-nginx-lb.sh

map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}

${upstream_block}

server {
    listen ${LISTEN_PORT};
    server_name ${DOMAIN};

    access_log /var/log/nginx/${DOMAIN}_access.log;
    error_log  /var/log/nginx/${DOMAIN}_error.log warn;

    client_max_body_size 64m;

    location / {
        proxy_pass http://${UPSTREAM_NAME};

        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;

        # WebSocket / Upgrade
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;

        # Timeouts
        proxy_connect_timeout ${PROXY_CONNECT_TIMEOUT};
        proxy_send_timeout ${PROXY_SEND_TIMEOUT};
        proxy_read_timeout ${PROXY_READ_TIMEOUT};
        send_timeout ${SEND_TIMEOUT};

        # Failover passivo
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_next_upstream_tries 3;

        # Buffering
        proxy_buffering on;
        proxy_buffers 16 16k;
        proxy_buffer_size 16k;
    }

    location /nginx-health {
        access_log off;
        return 200 "ok\n";
        add_header Content-Type text/plain;
    }
}
EOF

  ln -sf "$NGINX_CONF" "$NGINX_LINK"
}

remove_default_site() {
  rm -f /etc/nginx/sites-enabled/default || true
  rm -f /etc/nginx/conf.d/default.conf || true
}

test_nginx() {
  log "Validando configuração do Nginx..."
  nginx -t
}

show_summary() {
  cat <<EOF

=========================================
Configuração aplicada com sucesso
=========================================
Domínio:              ${DOMAIN}
Porta pública:        ${LISTEN_PORT}
Upstream:             ${UPSTREAM_NAME}
Método LB:            ${LB_METHOD}
Backends:             ${BACKENDS}
Arquivo de config:    ${NGINX_CONF}

Teste local:
  curl -I http://127.0.0.1:${LISTEN_PORT}/
  curl http://127.0.0.1:${LISTEN_PORT}/nginx-health

EOF
}

main() {
  require_root
  install_nginx
  remove_default_site
  write_nginx_config
  test_nginx
  enable_service
  show_summary
}

main "$@"