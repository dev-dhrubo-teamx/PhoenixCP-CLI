#!/bin/bash

# =====================================================
# PhoenixCP CLI v1.3 – Full Panel + FTP + Monitoring
# Author: @dev-dhrubo-teamx
# =====================================================

WWW_ROOT="/var/www"
NGX_CONF="/etc/nginx/conf.d"
SSL_BASE="/etc/nginx/ssl"
PHP_VER="8.1"
PHP_SOCK="/run/php/php${PHP_VER}-fpm.sock"

pause(){ read -p "Press Enter to continue..."; }

# =====================================================
install_dependencies() {
  echo "📦 Installing FULL Web Stack + FTP + phpMyAdmin"

  apt update
  apt install -y \
    nginx apache2 mariadb-server curl openssl \
    php${PHP_VER}-fpm php${PHP_VER}-cli php${PHP_VER}-mysql \
    php${PHP_VER}-curl php${PHP_VER}-mbstring php${PHP_VER}-xml \
    phpmyadmin pure-ftpd

  sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
  a2enmod proxy proxy_fcgi rewrite

  echo yes > /etc/pure-ftpd/conf/NoAnonymous
  echo no  > /etc/pure-ftpd/conf/PAMAuthentication
  echo yes > /etc/pure-ftpd/conf/UnixAuthentication

  apachectl start
  php-fpm${PHP_VER}
  pure-ftpd &
  mysqld_safe --bind-address=127.0.0.1 &

  mkdir -p /var/www/html $NGX_CONF

  cat > $NGX_CONF/default.conf <<EOF
server {
  listen 80;
  server_name _;
  root /var/www/html;
  index index.php index.html;

  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
  }

  location ~ \.php\$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:$PHP_SOCK;
  }
}
EOF

  cat > $NGX_CONF/phpmyadmin.conf <<EOF
location /phpmyadmin {
  alias /usr/share/phpmyadmin/;
  index index.php;

  location ~ \.php\$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:$PHP_SOCK;
  }
}
EOF

  echo "<?php phpinfo(); ?>" > /var/www/html/index.php

  nginx -t && nginx
  nginx -s reload

  echo "✅ Dependencies installed successfully"
  pause
}

# =====================================================
create_website() {
  read -p "Enter domain name: " domain
  SITE_ROOT="$WWW_ROOT/$domain/public_html"

  mkdir -p "$SITE_ROOT"

  cat > $NGX_CONF/$domain.conf <<EOF
server {
  listen 80;
  server_name $domain www.$domain;
  root $SITE_ROOT;
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

  echo "<?php echo 'Website $domain is working'; ?>" > "$SITE_ROOT/index.php"

  nginx -t && nginx -s reload

  clear
  echo "🌐 WEBSITE CREATED"
  echo "Domain     : $domain"
  echo "Public Dir : $SITE_ROOT"
  echo
  echo "📂 FTP ACCESS"
  echo "Host     : $domain"
  echo "Username : root"
  echo "Password : root"
  echo "Port     : 21"
  pause
}

# =====================================================
list_websites() {
  echo "📂 Hosted Websites:"
  ls $NGX_CONF | grep '.conf' | grep -v default | grep -v phpmyadmin | sed 's/.conf//'
  pause
}

# =====================================================
delete_website() {
  read -p "Domain to delete: " domain
  rm -rf "$WWW_ROOT/$domain"
  rm -f "$NGX_CONF/$domain.conf"
  nginx -s reload
  echo "🗑 Website deleted: $domain"
  pause
}

# =====================================================
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

# =====================================================
install_ssl() {
  read -p "Domain for SSL: " domain
  SSL_DIR="$SSL_BASE/$domain"
  mkdir -p "$SSL_DIR"

  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout $SSL_DIR/origin.key \
    -out $SSL_DIR/origin.crt \
    -days 3650 \
    -subj "/CN=$domain"

  cat > $NGX_CONF/$domain.conf <<EOF
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

# =====================================================
ssl_status() {
  read -p "Domain name: " domain
  if [ -f "$SSL_BASE/$domain/origin.crt" ]; then
    openssl x509 -in "$SSL_BASE/$domain/origin.crt" -noout -dates
  else
    echo "❌ No SSL found for $domain"
  fi
  pause
}

# =====================================================
install_cloudflare() {
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

cloudflare_autostart() {
  read -p "Tunnel name: " TUN
  (crontab -l 2>/dev/null; \
   echo "@reboot cloudflared tunnel run $TUN >/var/log/cloudflared.log 2>&1 &") | crontab -
  echo "✅ Cloudflare tunnel auto-start enabled"
  pause
}

# =====================================================
advanced_status() {
  clear
  echo "📊 PhoenixCP Advanced Status"
  echo "----------------------------"
  pgrep nginx >/dev/null && echo "Nginx   : RUNNING" || echo "Nginx   : STOPPED"
  pgrep apache2 >/dev/null && echo "Apache  : RUNNING" || echo "Apache  : STOPPED"
  pgrep php-fpm >/dev/null && echo "PHP-FPM : RUNNING" || echo "PHP-FPM : STOPPED"
  pgrep mysqld >/dev/null && echo "MySQL   : RUNNING" || echo "MySQL   : STOPPED"
  pgrep pure-ftpd >/dev/null && echo "FTP     : RUNNING" || echo "FTP     : STOPPED"
  echo
  uptime
  free -h
  df -h /
  pause
}

# =====================================================
clear_system() {
  echo "🔥 FULL SYSTEM RESET (NUKE MODE)"
  read -p "Type YES to confirm: " c
  [ "$c" != "YES" ] && return

  pkill nginx apache2 php-fpm mysqld pure-ftpd cloudflared 2>/dev/null
  apt purge -y nginx* apache2* php* mariadb* mysql* phpmyadmin pure-ftpd* cloudflared
  apt autoremove -y
  rm -rf /etc/nginx /etc/apache2 /etc/mysql /etc/php /var/www /run/php
  echo "✅ System wiped"
  pause
}

# =====================================================
while true; do
  clear
  echo "==============================="
  echo "   PhoenixCP CLI v1.3"
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
  echo "11) 🔥 Clear System (NUKE MODE)"
  echo "12) Exit"
  echo "==============================="
  read -p "Choose option: " opt

  case $opt in
    1) install_dependencies ;;
    2) create_website ;;
    3) list_websites ;;
    4) delete_website ;;
    5) advanced_status ;;
    6) install_cloudflare ;;
    7) cloudflare_autostart ;;
    8) install_ssl ;;
    9) ssl_status ;;
    10) mysql_create ;;
    11) clear_system ;;
    12) exit ;;
    *) echo "Invalid option"; pause ;;
  esac
done
