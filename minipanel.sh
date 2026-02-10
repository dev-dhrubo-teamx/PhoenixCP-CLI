#!/bin/bash

# =====================================================
# PhoenixCP CLI v1.4 – Apache Only Stable Edition
# Author: @dev-dhrubo-teamx
# =====================================================

WWW_ROOT="/var/www"
PHP_VER="8.1"

pause(){ read -p "Press Enter to continue..."; }

# =====================================================
clear_system() {
  echo "🔥 FULL SYSTEM RESET (NUKE MODE)"
  echo "This will REMOVE apache, php, mysql, phpMyAdmin, FTP"
  read -p "Type YES to confirm: " c
  [ "$c" != "YES" ] && return

  pkill apache2 php-fpm mysqld pure-ftpd cloudflared 2>/dev/null

  apt purge -y apache2* php* mariadb* mysql* phpmyadmin pure-ftpd* cloudflared
  apt autoremove -y
  apt autoclean -y

  rm -rf /etc/apache2 /etc/php /etc/mysql /var/www /run/php /usr/share/phpmyadmin

  crontab -l 2>/dev/null | grep -v cloudflared | crontab -

  echo "✅ SYSTEM COMPLETELY CLEANED"
  pause
}

# =====================================================
install_dependencies() {
  echo "📦 Installing Apache Web Stack (Stable Mode)"

  apt update
  apt install -y \
    apache2 mariadb-server curl openssl \
    php${PHP_VER}-fpm php${PHP_VER}-cli php${PHP_VER}-mysql \
    php${PHP_VER}-curl php${PHP_VER}-mbstring php${PHP_VER}-xml \
    phpmyadmin pure-ftpd

  # Apache modules for PHP-FPM
  a2enmod proxy proxy_fcgi rewrite setenvif
  a2enconf php${PHP_VER}-fpm

  # FTP config (simple)
  echo yes > /etc/pure-ftpd/conf/NoAnonymous
  echo no  > /etc/pure-ftpd/conf/PAMAuthentication
  echo yes > /etc/pure-ftpd/conf/UnixAuthentication

  mkdir -p /run/php
  php-fpm${PHP_VER}
  apachectl start
  pure-ftpd &
  mysqld_safe --bind-address=127.0.0.1 &

  mkdir -p /var/www/html
  echo "<?php phpinfo(); ?>" > /var/www/html/index.php

  echo "✅ Apache Web Stack READY"
  echo "👉 phpMyAdmin: http://localhost/phpmyadmin"
  pause
}

# =====================================================
create_website() {
  read -p "Enter domain name: " domain
  SITE_ROOT="$WWW_ROOT/$domain/public_html"

  mkdir -p "$SITE_ROOT"

  cat > /etc/apache2/sites-available/$domain.conf <<EOF
<VirtualHost *:80>
  ServerName $domain
  ServerAlias www.$domain
  DocumentRoot $SITE_ROOT

  <Directory $SITE_ROOT>
    AllowOverride All
    Require all granted
  </Directory>

  <FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php/php${PHP_VER}-fpm.sock|fcgi://localhost/"
  </FilesMatch>

  ErrorLog \${APACHE_LOG_DIR}/$domain-error.log
  CustomLog \${APACHE_LOG_DIR}/$domain-access.log combined
</VirtualHost>
EOF

  a2ensite $domain.conf
  apachectl reload

  echo "<?php echo 'Website $domain is working'; ?>" > "$SITE_ROOT/index.php"

  clear
  echo "🌐 WEBSITE CREATED SUCCESSFULLY"
  echo "--------------------------------"
  echo "Domain       : $domain"
  echo "Public Dir   : $SITE_ROOT"
  echo
  echo "📂 FTP DETAILS"
  echo "Host         : SERVER_IP / DOMAIN"
  echo "Username     : root"
  echo "Password     : root"
  echo "Port         : 21"
  pause
}

# =====================================================
list_websites() {
  echo "📂 Hosted Websites:"
  ls /etc/apache2/sites-enabled | sed 's/.conf//'
  pause
}

# =====================================================
delete_website() {
  read -p "Domain to delete: " domain

  a2dissite $domain.conf 2>/dev/null
  rm -f /etc/apache2/sites-available/$domain.conf
  rm -rf "$WWW_ROOT/$domain"

  apachectl reload
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
  echo "📊 PhoenixCP Advanced Status (Apache Mode)"
  echo "-----------------------------------------"

  pgrep apache2 >/dev/null && echo "Apache : RUNNING" || echo "Apache : STOPPED"
  pgrep php-fpm >/dev/null && echo "PHP-FPM: RUNNING" || echo "PHP-FPM: STOPPED"
  pgrep mysqld >/dev/null && echo "MySQL  : RUNNING" || echo "MySQL  : STOPPED"
  pgrep pure-ftpd >/dev/null && echo "FTP    : RUNNING" || echo "FTP    : STOPPED"

  echo
  uptime
  free -h
  df -h /
  pause
}

# =====================================================
while true; do
  clear
  echo "==============================="
  echo " PhoenixCP CLI v1.4"
  echo "==============================="
  echo "1) Install Website Dependencies"
  echo "2) Create Website"
  echo "3) List Websites"
  echo "4) Delete Website"
  echo "5) Advanced Service Status"
  echo "6) Install Cloudflare Tunnel"
  echo "7) Enable Cloudflare Tunnel Auto-Start"
  echo "8) Create MySQL DB & User"
  echo "9) 🔥 Clear System (NUKE MODE)"
  echo "10) Exit"
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
    8) mysql_create ;;
    9) clear_system ;;
    10) exit ;;
    *) echo "Invalid option"; pause ;;
  esac
done
