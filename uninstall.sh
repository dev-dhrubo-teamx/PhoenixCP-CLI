#!/bin/bash

# =====================================================
# PhoenixCP / Web Stack FULL UNINSTALL (NUKE MODE)
# Author: @dev-dhrubo-teamx
# =====================================================

set -e

echo "🔥 PhoenixCP & Web Stack FULL REMOVAL"
echo "⚠️ This will WIPE EVERYTHING (Apache, Nginx, PHP, MySQL, FTP, Cloudflare)"
read -p "Type YES to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo "❌ Aborted"
  exit 1
fi

echo "🛑 Stopping running services..."

# Kill processes (systemd or not)
pkill -f apache2 2>/dev/null || true
pkill -f nginx 2>/dev/null || true
pkill -f php-fpm 2>/dev/null || true
pkill -f mysqld 2>/dev/null || true
pkill -f pure-ftpd 2>/dev/null || true
pkill -f cloudflared 2>/dev/null || true

sleep 2

echo "🧹 Removing panel commands..."
rm -f /usr/local/bin/phoenixcp
rm -f /usr/local/bin/phoenix
rm -f /usr/local/bin/minipanel

echo "🧹 Removing websites & configs..."
rm -rf /var/www
rm -rf /etc/apache2
rm -rf /etc/nginx
rm -rf /etc/mysql
rm -rf /etc/php
rm -rf /run/php
rm -rf /usr/share/phpmyadmin
rm -rf /etc/nginx/ssl
rm -rf /etc/apache2/ssl

echo "🧹 Removing cron jobs..."
crontab -l 2>/dev/null | grep -Ev 'phoenix|cloudflared' | crontab - || true

echo "📦 Purging packages..."

export DEBIAN_FRONTEND=noninteractive

apt purge -y \
  apache2* nginx* php* \
  mariadb* mysql* \
  phpmyadmin pure-ftpd* \
  cloudflared || true

apt autoremove -y
apt autoclean -y

echo "🧹 Removing Cloudflare repo..."
rm -f /etc/apt/sources.list.d/cloudflared.list
rm -f /usr/share/keyrings/cloudflare-public-v2.gpg

echo "🧹 Removing leftover users (FTP/site users)..."
awk -F: '$3 >= 1000 {print $1}' /etc/passwd | grep -v root | xargs -r userdel -r 2>/dev/null || true

echo "🧹 Cleaning APT cache..."
rm -rf /var/lib/apt/lists/*

echo "🔍 Final check (should be empty):"
ss -lntp || true

echo
echo "✅ ALL DONE"
echo "🟢 VPS is now CLEAN like a fresh install"
echo "🔁 You can now reinstall PhoenixCP safely"
