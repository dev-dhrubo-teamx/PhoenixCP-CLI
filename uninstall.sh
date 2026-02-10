echo "🔥 Removing PhoenixCP CLI & all web stack..."

# Stop running processes
pkill nginx 2>/dev/null
pkill php-fpm 2>/dev/null
pkill mysqld 2>/dev/null
pkill cloudflared 2>/dev/null

# Remove panel commands
rm -f /usr/local/bin/minipanel
rm -f /usr/local/bin/phoenix

# Remove websites & configs
rm -rf /var/www
rm -rf /etc/nginx
rm -rf /etc/mysql
rm -rf /etc/nginx/ssl

# Remove packages
apt purge -y nginx* php* mariadb* mysql* cloudflared
apt autoremove -y
apt autoclean -y

# Remove cloudflare repo
rm -f /etc/apt/sources.list.d/cloudflared.list
rm -f /usr/share/keyrings/cloudflare-public-v2.gpg

# Remove cron (cloudflared autostart)
crontab -l 2>/dev/null | grep -v cloudflared | crontab -

echo "✅ ALL DONE — System cleaned"
