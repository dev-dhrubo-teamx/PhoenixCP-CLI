# 🐦‍🔥 PhoenixCP CLI

**PhoenixCP CLI** is a lightweight, systemd-free, menu-based CLI control panel  
designed for low-resource VPS environments.

> **Rise • Control • Deploy**

Built for developers who want:
- No heavy web panels
- No systemd dependency
- Full control with minimal RAM usage

---

## ✨ Features

- ✅ Menu-based interactive CLI
- ✅ Multi-website hosting (Nginx + PHP-FPM)
- ✅ MySQL / MariaDB support
- ✅ Cloudflare Tunnel integration
- ✅ SSL support (Cloudflare Origin SSL)
- ✅ SSL status check per website
- ✅ Create / Delete websites
- ✅ Auto create MySQL database & user
- ✅ Advanced service status dashboard
- ✅ 1 GB RAM friendly
- ❌ No heavy Web UI
- ❌ No systemd required

---

## 📦 System Requirements

- OS: **Ubuntu 20.04 / 22.04 / 24.04**
- CPU: 1 Core (2 recommended)
- RAM: **1 GB minimum**
- Root access required

---

## 🚀 1-Click Installation

Run the following command on your VPS:

# Install Command
```bash
curl -fsSL https://raw.githubusercontent.com/dev-dhrubo-teamx/PhoenixCP-CLI/main/phoenix.sh | bash
```
# Uninstall Command
```bash
curl -fsSL https://raw.githubusercontent.com/dev-dhrubo-teamx/PhoenixCP-CLI/main/uninstall.sh | bash
```
# Others Command If Necessary Need

Vps web Browser SSH Access TTYD Method
```bash
apt update
apt install -y ttyd
```
This run ttyyd :
```
ttyd -p 7681 bash
```
👉 Browser :
```
http://SERVER_IP:7681
```
# Gdown Install clean ও reliable Method
```
apt update
apt install -y python3-pip
pip3 install gdown
```
# If Come Default Apache Page 
```
a2dissite 000-default.conf
a2dissite default-ssl.conf
apachectl -k graceful
```
# Tiny Default User 

username : admin
pass : admin@123

# Phpmyadmin Default User :

user: root
pass : root

# Website Match or Redirect  Same Domain

1 
```
echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf
a2enconf servername
apachectl -k graceful
```
2
```
cat > /etc/apache2/sites-available/000-catchall.conf <<EOF
<VirtualHost *:80>
  ServerName _
  DocumentRoot /var/www/_invalid

  <Directory /var/www/_invalid>
    Require all denied
  </Directory>
</VirtualHost>
EOF
```
3
```
apachectl -k graceful
```
# Php Ini Update Mysql Upload Limit 

1. 
```
php -v
php --ini
```
2.
```
sudo nano /etc/php/8.2/fpm/php.ini
```
3.
```
sudo systemctl restart php8.2-fpm
```
