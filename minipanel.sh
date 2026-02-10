#!/bin/bash

# =====================================================
# PhoenixCP CLI v1.0
# Rise • Control • Deploy
# Author: @dev-dhrubo-teamx
# =====================================================

# -----------------------------
# THEME (Glass + Neon)
# -----------------------------
DARK="\e[48;5;235m"
ORANGE="\e[38;5;208m"
CYAN="\e[38;5;45m"
WHITE="\e[97m"
DIM="\e[2m"
RESET="\e[0m"
CLEAR="\e[2J\e[H"

# -----------------------------
# CONFIG
# -----------------------------
WWW_ROOT="/var/www"
NGX_DIR="/etc/nginx/sites-enabled"
SSL_BASE="/etc/nginx/ssl"
PHP_VER="8.1"
PHP_SOCK="/run/php/php${PHP_VER}-fpm.sock"

pause(){ echo; read -p "↩ Press Enter to continue..."; }

# -----------------------------
# ANIMATED LOGO
# -----------------------------
phoenix_logo() {
  clear
  echo -e "$CLEAR"
  logo=(
"██████╗ ██╗  ██╗ ██████╗ ███████╗███╗   ██╗██╗██╗  ██╗"
"██╔══██╗██║  ██║██╔═══██╗██╔════╝████╗  ██║██║╚██╗██╔╝"
"██████╔╝███████║██║   ██║█████╗  ██╔██╗ ██║██║ ╚███╔╝ "
"██╔═══╝ ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║██║ ██╔██╗ "
"██║     ██║  ██║╚██████╔╝███████╗██║ ╚████║██║██╔╝ ██╗"
"╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝"
  )

  for l in "${logo[@]}"; do
    echo -e "${ORANGE}$l${RESET}"
    sleep 0.04
  done

  echo
  echo -e "${CYAN}           P H O E N I X   C P   C L I${RESET}"
  echo -e "${DIM}         Rise • Control • Deploy${RESET}"
  echo -e "${DIM}                v1.0${RESET}"
  echo
  sleep 0.6
}

# -----------------------------
# CORE FUNCTIONS
# -----------------------------
install_dependencies() {
  echo -e "${ORANGE}📦 Installing Web Stack...${RESET}"
  apt update
  apt install -y nginx mariadb-server openssl curl \
    php${PHP_VER}-fpm php${PHP_VER}-cli php${PHP_VER}-mysql \
    php${PHP_VER}-curl php${PHP_VER}-mbstring php${PHP_VER}-xml

  nginx || true
  php-fpm${PHP_VER} || true
  mysqld_safe --bind-address=127.0.0.1 &

  mkdir -p /var/www/html

  cat > $NGX_DIR/default.conf <<EOF
server {
  listen 80;
  server_name _;
  root /var/www/html;
  index index.php index.html;

  location / {
    try_files \$uri \$uri/ =404;
  }

  location ~ \.php\$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:$PHP_SOCK;
  }
}
EOF

  echo "<?php phpinfo(); ?>" > /var/www/html/index.php
  nginx -s reload

  echo -e "${CYAN}✅ Web stack ready${RESET}"
  pause
}

create_site() {
  read -p "🌐 Domain name: " domain
  mkdir -p $WWW_ROOT/$domain/public_html

  cat > $NGX_DIR/$domain.conf <<EOF
server {
  listen 80;
  server_name $domain www.$domain;
  root $WWW_ROOT/$domain/public_html;
  index index.php index.html;

  location / {
    try_files \$uri \$uri/ =404;
  }

  location ~ \.php\$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:$PHP_SOCK;
  }
}
EOF

  echo "<?php echo 'PhoenixCP CLI site: $domain'; ?>" > $WWW_ROOT/$domain/public_html/index.php
  nginx -s reload

  echo -e "${CYAN}🔥 Website created: $domain${RESET}"
  pause
}

delete_site() {
  read -p "🗑 Domain to delete: " domain
  rm -rf $WWW_ROOT/$domain
  rm -f $NGX_DIR/$domain.conf
  nginx -s reload
  echo -e "${ORANGE}✔ Deleted $domain${RESET}"
  pause
}

list_sites() {
  echo -e "${CYAN}📂 Active Websites${RESET}"
  ls $NGX_DIR | grep .conf | sed 's/.conf//'
  pause
}

mysql_create() {
  read -p "DB name: " db
  read -p "DB user: " user
  read -s -p "DB password: " pass
  echo

  mysql <<EOF
CREATE DATABASE $db;
CREATE USER '$user'@'localhost' IDENTIFIED BY '$pass';
GRANT ALL PRIVILEGES ON $db.* TO '$user'@'localhost';
FLUSH PRIVILEGES;
EOF

  echo -e "${CYAN}🛢 Database ready${RESET}"
  pause
}

install_ssl() {
  read -p "🔐 Domain for SSL: " domain
  SSL_DIR="$SSL_BASE/$domain"
  mkdir -p $SSL_DIR

  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout $SSL_DIR/origin.key \
    -out $SSL_DIR/origin.crt \
    -days 3650 \
    -subj "/CN=$domain"

  cat > $NGX_DIR/$domain.conf <<EOF
server {
  listen 80;
  server_name $domain www.$domain;
  return 301 https://\$host\$request_uri;
}

server {
  listen 443 ssl;
  server_name $domain www.$domain;

  ssl_certificate     $SSL_DIR/origin.crt;
  ssl_certificate_key $SSL_DIR/origin.key;

  root $WWW_ROOT/$domain/public_html;
  index index.php index.html;

  location / {
    try_files \$uri \$uri/ =404;
  }

  location ~ \.php\$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:$PHP_SOCK;
  }
}
EOF

  nginx -s reload
  echo -e "${CYAN}🔒 SSL enabled for $domain${RESET}"
  pause
}

ssl_status() {
  read -p "Domain: " domain
  if [ -f "$SSL_BASE/$domain/origin.crt" ]; then
    echo -e "${CYAN}✔ SSL ACTIVE${RESET}"
    openssl x509 -in $SSL_BASE/$domain/origin.crt -noout -dates
  else
    echo -e "${ORANGE}✖ No SSL found${RESET}"
  fi
  pause
}

advanced_status() {
  clear
  echo -e "${CYAN}📊 System Status${RESET}"
  echo "------------------------------"
  pgrep nginx >/dev/null && echo "Nginx   : RUNNING" || echo "Nginx   : STOPPED"
  pgrep php-fpm >/dev/null && echo "PHP     : RUNNING" || echo "PHP     : STOPPED"
  pgrep mysqld >/dev/null && echo "MySQL   : RUNNING" || echo "MySQL   : STOPPED"
  echo
  echo "Websites: $(ls $NGX_DIR | grep .conf | wc -l)"
  free -h
  pause
}

# -----------------------------
# DASHBOARD
# -----------------------------
phoenix_logo

while true; do
  clear
  echo -e "${CYAN}╭──────────────────────────────────────╮${RESET}"
  echo -e "${CYAN}│     🐦‍🔥 PhoenixCP CLI Dashboard     │${RESET}"
  echo -e "${CYAN}╰──────────────────────────────────────╯${RESET}"
  echo
  echo -e "${ORANGE}1)${RESET} Install Website Dependencies"
  echo -e "${ORANGE}2)${RESET} Create Website"
  echo -e "${ORANGE}3)${RESET} List Websites"
  echo -e "${ORANGE}4)${RESET} Delete Website"
  echo -e "${ORANGE}5)${RESET} Install SSL (Cloudflare Origin)"
  echo -e "${ORANGE}6)${RESET} SSL Status Check"
  echo -e "${ORANGE}7)${RESET} Create MySQL DB & User"
  echo -e "${ORANGE}8)${RESET} Advanced System Status"
  echo -e "${ORANGE}9)${RESET} Exit"
  echo
  read -p "Choose option ➜ " opt

  case $opt in
    1) install_dependencies ;;
    2) create_site ;;
    3) list_sites ;;
    4) delete_site ;;
    5) install_ssl ;;
    6) ssl_status ;;
    7) mysql_create ;;
    8) advanced_status ;;
    9) clear; exit ;;
    *) echo "Invalid option"; pause ;;
  esac
done
