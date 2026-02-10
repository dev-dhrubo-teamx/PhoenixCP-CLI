#!/bin/bash

# =====================================================
# PhoenixCP CLI v1.8 – FULL PANEL (Apache Only)
# Author: @dev-dhrubo-teamx
# =====================================================

WWW_ROOT="/var/www"
PHP_VER="8.1"
PHP_SOCK="/run/php/php${PHP_VER}-fpm.sock"
FTP_PASS="root"
MYSQL_ROOT_PASS="root"

pause(){ read -p "Press Enter to continue..."; }

# =====================================================
start_all_services() {
  echo "🚀 Starting all services"
  mkdir -p /run/php

  apachectl start 2>/dev/null
  php-fpm${PHP_VER} 2>/dev/null
  pure-ftpd &>/dev/null &
  mysqld_safe --bind-address=127.0.0.1 &>/dev/null &
  pgrep -f cloudflared >/dev/null && cloudflared &>/dev/null &

  echo "✅ All services started"
  pause
}

stop_all_services() {
  echo "🛑 Stopping all services"
  pkill apache2 php-fpm mysqld pure-ftpd cloudflared 2>/dev/null
  echo "✅ All services stopped"
  pause
}

# =====================================================
auto_start_cron() {
  (crontab -l 2>/dev/null; echo "@reboot /usr/local/bin/phoenixcp start-all") | crontab -
  echo "✅ Auto-start enabled via cron"
  pause
}

# =====================================================
clear_system() {
  echo "🔥 FULL SYSTEM RESET (NUKE MODE)"
  read -p "Type YES to confirm: " c
  [ "$c" != "YES" ] && return

  stop_all_services
  apt purge -y apache2* php* mariadb* mysql* phpmyadmin pure-ftpd* cloudflared
  apt autoremove -y
  apt autoclean -y

  rm -rf /etc/apache2 /etc/php /etc/mysql /var/www /run/php /usr/share/phpmyadmin
  rm -f /etc/apt/sources.list.d/cloudflared.list
  rm -f /usr/share/keyrings/cloudflare-public-v2.gpg
  crontab -r 2>/dev/null

  echo "✅ SYSTEM COMPLETELY CLEANED"
  pause
}

# =====================================================
install_dependencies() {
  echo "📦 Installing Apache Web Stack"

  apt update
  apt install -y \
    apache2 mariadb-server curl openssl \
    php${PHP_VER}-fpm php${PHP_VER}-cli php${PHP_VER}-mysql \
    php${PHP_VER}-curl php${PHP_VER}-mbstring php${PHP_VER}-xml \
    phpmyadmin pure-ftpd

  a2enmod proxy proxy_fcgi rewrite ssl
  a2enconf php${PHP_VER}-fpm
  a2ensite default-ssl

  echo yes > /etc/pure-ftpd/conf/NoAnonymous
  echo no  > /etc/pure-ftpd/conf/PAMAuthentication
  echo yes > /etc/pure-ftpd/conf/UnixAuthentication
  echo yes > /etc/pure-ftpd/conf/ChrootEveryone

  # -----------------------------
  # phpMyAdmin Apache FIX (AUTO)
  # -----------------------------
  cat > /etc/apache2/conf-available/phpmyadmin.conf <<EOF
Alias /phpmyadmin /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin>
    Options SymLinksIfOwnerMatch
    DirectoryIndex index.php
    AllowOverride All
    Require all granted
</Directory>

<Directory /usr/share/phpmyadmin/setup>
    Require all denied
</Directory>

<FilesMatch "\.php$">
    SetHandler "proxy:unix:$PHP_SOCK|fcgi://localhost/"
</FilesMatch>
EOF

  a2enconf phpmyadmin

  # -----------------------------
  # MySQL ROOT AUTO SET (phpMyAdmin ready)
  # -----------------------------
  mkdir -p /run/php
  mysqld_safe --bind-address=127.0.0.1 &>/dev/null &
  sleep 5

  mysql -uroot <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';
FLUSH PRIVILEGES;
EOF

  mkdir -p /var/www/html
  echo "<?php phpinfo(); ?>" > /var/www/html/index.php

  start_all_services
  apachectl reload

  echo "✅ Apache + phpMyAdmin READY"
  echo "👉 phpMyAdmin URL : http://localhost/phpmyadmin"
  echo "👉 MySQL Login    : root / root"
  pause
}

# =====================================================
create_site_ftp_user() {
  local user=$1
  local home=$2
  userdel -r $user 2>/dev/null
  useradd -d $home -s /usr/sbin/nologin $user
  echo "$user:$FTP_PASS" | chpasswd
}

# -----------------------------
# Apache Production Fix
# -----------------------------

# Disable default Apache site
a2dissite 000-default.conf 2>/dev/null || true

# Remove phpinfo test file
rm -f /var/www/html/index.php

apachectl reload


# =====================================================
create_website() {
  read -p "Domain name: " domain
  SITE_ROOT="$WWW_ROOT/$domain/public_html"

  mkdir -p "$SITE_ROOT"
  create_site_ftp_user "$domain" "$WWW_ROOT/$domain"

  # -----------------------------
  # Apache VirtualHost
  # -----------------------------
  cat > /etc/apache2/sites-available/$domain.conf <<EOF
<VirtualHost *:80>
  ServerName $domain
  ServerAlias www.$domain
  DocumentRoot $SITE_ROOT

  DirectoryIndex index.php index.html

  <Directory $SITE_ROOT>
    AllowOverride All
    Require all granted
    Options Indexes FollowSymLinks
  </Directory>

  <FilesMatch \.php$>
    SetHandler "proxy:unix:$PHP_SOCK|fcgi://localhost/"
  </FilesMatch>

  ErrorLog \${APACHE_LOG_DIR}/$domain-error.log
  CustomLog \${APACHE_LOG_DIR}/$domain-access.log combined
</VirtualHost>
EOF

  # Enable site
  a2ensite $domain.conf

  # HARD GUARD — disable Apache default sites
  a2dissite 000-default.conf 2>/dev/null || true
  a2dissite default-ssl.conf 2>/dev/null || true
  apachectl reload

  # -----------------------------
  # Install File Manager (AUTO)
  # -----------------------------
  FILE_MANAGER="$SITE_ROOT/filemanager.php"

  if [ ! -f "$FILE_MANAGER" ]; then
    curl -fsSL \
      https://raw.githubusercontent.com/dev-dhrubo-teamx/PhoenixCP-CLI-File-Manager/master/tinyfilemanager.php \
      -o "$FILE_MANAGER"
  fi

  chown -R www-data:www-data "$WWW_ROOT/$domain"
  chmod 755 "$SITE_ROOT"
  chmod 644 "$FILE_MANAGER"

  # -----------------------------
  # Optional test file (user can delete)
  # -----------------------------
  echo "<?php echo 'Directory listing enabled. Site $domain is working.'; ?>" > "$SITE_ROOT/index.php"

  clear
  echo "🌐 WEBSITE CREATED (Directory Listing + File Manager)"
  echo "----------------------------------------------------"
  echo "Domain       : $domain"
  echo "Public Dir   : $SITE_ROOT"
  echo
  echo "📂 ACCESS"
  echo "Website      : http://$domain/"
  echo "File Manager : http://$domain/filemanager.php"
  echo
  echo "📂 BEHAVIOR"
  echo "- index.php found  → loads index.php"
  echo "- index.php missing → shows directory listing"
  echo
  echo "📂 FTP (SITE USER)"
  echo "Host : $domain"
  echo "User : $domain"
  echo "Pass : root"
  echo
  echo "📂 FTP (ADMIN)"
  echo "User : root"
  echo "Pass : root"
  pause
}
# =====================================================
list_websites() {
  echo "📂 Hosted Websites:"
  ls /etc/apache2/sites-enabled | sed 's/.conf//'
  pause
}

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
install_ssl() {
  read -p "Domain for SSL: " domain
  SSL_DIR="/etc/apache2/ssl/$domain"
  mkdir -p $SSL_DIR

  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout $SSL_DIR/key.pem \
    -out $SSL_DIR/cert.pem \
    -days 3650 \
    -subj "/CN=$domain"

  cat > /etc/apache2/sites-available/$domain-ssl.conf <<EOF
<VirtualHost *:443>
  ServerName $domain
  DocumentRoot $WWW_ROOT/$domain/public_html
  SSLEngine on
  SSLCertificateFile $SSL_DIR/cert.pem
  SSLCertificateKeyFile $SSL_DIR/key.pem

  <FilesMatch \.php$>
    SetHandler "proxy:unix:$PHP_SOCK|fcgi://localhost/"
  </FilesMatch>
</VirtualHost>
EOF

  a2ensite $domain-ssl.conf
  apachectl reload
  echo "🔒 SSL installed for $domain"
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
  echo "✅ Cloudflare Tunnel installed"
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
  pgrep apache2 >/dev/null && echo "Apache      : RUNNING" || echo "Apache      : STOPPED"
  pgrep php-fpm >/dev/null && echo "PHP-FPM     : RUNNING" || echo "PHP-FPM     : STOPPED"
  pgrep mysqld >/dev/null && echo "MySQL       : RUNNING" || echo "MySQL       : STOPPED"
  pgrep -f pure-ftpd >/dev/null && echo "FTP         : RUNNING" || echo "FTP         : STOPPED"
  pgrep -f cloudflared >/dev/null && echo "Cloudflare  : RUNNING" || echo "Cloudflare  : STOPPED"
  uptime
  free -h
  pause
}

# =====================================================
while true; do
  clear
  echo "==============================="
  echo " PhoenixCP CLI v1.8"
  echo "==============================="
  echo "1) Install Website Dependencies"
  echo "2) Create Website"
  echo "3) List Websites"
  echo "4) Delete Website"
  echo "5) Advanced Service Status"
  echo "6) 🚀 Start All Services"
  echo "7) 🛑 Stop All Services"
  echo "8) 🔒 Install SSL (Apache)"
  echo "9) ☁ Install Cloudflare Tunnel"
  echo "10) ☁ Enable Cloudflare Auto-Start"
  echo "11) 🔁 Enable Auto-start (cron)"
  echo "12) 🔥 Clear System (NUKE MODE)"
  echo "13) Exit"
  echo "==============================="
  read -p "Choose option: " opt

  case $opt in
    1) install_dependencies ;;
    2) create_website ;;
    3) list_websites ;;
    4) delete_website ;;
    5) advanced_status ;;
    6) start_all_services ;;
    7) stop_all_services ;;
    8) install_ssl ;;
    9) install_cloudflare ;;
    10) cloudflare_autostart ;;
    11) auto_start_cron ;;
    12) clear_system ;;
    13) exit ;;
    *) pause ;;
  esac
done
