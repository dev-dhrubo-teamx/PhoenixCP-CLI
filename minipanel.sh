#!/bin/bash

# =============================
# CONFIG
# =============================
WWW_ROOT="/var/www"
NGX_DIR="/etc/nginx/sites-enabled"
SSL_BASE="/etc/nginx/ssl"
PHP_VER="8.1"
PHP_SOCK="/run/php/php${PHP_VER}-fpm.sock"

pause(){ read -p "Press Enter to continue..."; }

# =============================
install_dependencies() {
  echo "📦 Installing web stack..."
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
  echo "✅ Dependencies installed"
  pause
}

# =============================
install_cloudflare() {
  echo "☁ Installing Cloudflare Tunnel..."
  mkdir -p /usr/share/keyrings
  curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg \
    | tee /usr/share/keyrings/cloudflare-public-v2.gpg >/dev/null

  echo "deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] \
https://pkg.cloudflare.com/cloudflared any main" \
    | tee /etc/apt/sources.list.d/cloudflared.list

  apt update && apt install -y cloudflared
  echo "✅ cloudflared installed"
  pause
}

# =============================
cloudflare_autostart() {
  read -p "Tunnel name: " TUN
  (crontab -l 2>/dev/null; \
   echo "@reboot cloudflared tunnel run $TUN >/var/log/cloudflared.log 2>&1 &") | crontab -
  echo "✅ cloudflared auto-start enabled"
  pause
}

# =============================
create_site() {
  read -p "Domain name: " domain
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

  echo "<?php echo 'Site $domain working'; ?>" > $WWW_ROOT/$domain/public_html/index.php
  nginx -s reload
  echo "✅ Website created: $domain"
  pause
}

# =============================
delete_site() {
  read -p "Domain to delete: " domain
  rm -rf $WWW_ROOT/$domain
  rm -f $NGX_DIR/$domain.conf
  nginx -s reload
  echo "🗑️ Website deleted: $domain"
  pause
}

# =============================
list_sites() {
  echo "📂 Websites:"
  ls $NGX_DIR | grep .conf | sed 's/.conf//'
  pause
}

# =============================
mysql_create() {
  read -p "Database name: " db
  read -p "DB username: " user
  read -s -p "DB password: " pass
  echo

  mysql <<EOF
CREATE DATABASE $db;
CREATE USER '$user'@'localhost' IDENTIFIED BY '$pass';
GRANT ALL PRIVILEGES ON $db.* TO '$user'@'localhost';
FLUSH PRIVILEGES;
EOF

  echo "✅ Database & user created"
  pause
}

# =============================
install_ssl() {
  read -p "Domain for SSL: " domain
  SSL_DIR="$SSL_BASE/$domain"
  CONF="$NGX_DIR/$domain.conf"

  mkdir -p $SSL_DIR

  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout $SSL_DIR/origin.key \
    -out $SSL_DIR/origin.crt \
    -days 3650 \
    -subj "/CN=$domain"

  cat > $CONF <<EOF
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
  echo "🔒 SSL installed for $domain"
  pause
}

# =============================
ssl_status() {
  read -p "Domain name: " domain
  if [ -f "$SSL_BASE/$domain/origin.crt" ]; then
    echo "🔐 SSL installed for $domain"
    openssl x509 -in $SSL_BASE/$domain/origin.crt -noout -dates
  else
    echo "❌ No SSL found for $domain"
  fi
  pause
}

# =============================
advanced_status() {
  clear
  echo "📊 Service Status"
  pgrep nginx >/dev/null && echo "Nginx  : RUNNING" || echo "Nginx  : STOPPED"
  pgrep php-fpm >/dev/null && echo "PHP    : RUNNING" || echo "PHP    : STOPPED"
  pgrep mysqld >/dev/null && echo "MySQL  : RUNNING" || echo "MySQL  : STOPPED"
  echo
  echo "Ports:"
  ss -lnt | awk 'NR>1{print $4}' | sort -u
  echo
  echo "Websites:"
  ls $NGX_DIR | grep .conf | wc -l
  echo
  free -h
  pause
}

# =============================
while true; do
  clear
  echo "==============================="
  echo "        MiniPanel (CLI)"
  echo "==============================="
  echo "1) Install Website Dependencies"
  echo "2) Create Website"
  echo "3) List Websites"
  echo "4) Delete Website"
  echo "5) Advanced Service Status"
  echo "6) Install Cloudflare Tunnel"
  echo "7) Enable Cloudflare Tunnel Auto-Start"
  echo "8) Install SSL for Website"
  echo "9) SSL Status Check"
  echo "10) Create MySQL DB & User"
  echo "11) Exit"
  echo "==============================="
  read -p "Choose option: " opt

  case $opt in
    1) install_dependencies ;;
    2) create_site ;;
    3) list_sites ;;
    4) delete_site ;;
    5) advanced_status ;;
    6) install_cloudflare ;;
    7) cloudflare_autostart ;;
    8) install_ssl ;;
    9) ssl_status ;;
    10) mysql_create ;;
    11) exit ;;
    *) echo "Invalid option"; pause ;;
  esac
done
