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
এটা দিলে ttyd চলবে এবং bash খুলবে:
```
ttyd -p 7681 bash
```
👉 Browser থেকে খুলবে:
```
http://SERVER_IP:7681
```
# Gdown ইনস্টল করার সবচেয়ে clean ও reliable উপায়
```
apt update
apt install -y python3-pip
pip3 install gdown
```
