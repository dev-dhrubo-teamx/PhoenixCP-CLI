#!/bin/bash
set -e

# ===============================
# PhoenixCP CLI v1.0 Installer
# Author: @dev-dhrubo-teamx
# ===============================

REPO_RAW="https://raw.githubusercontent.com/dev-dhrubo-teamx/PhoenixCP-CLI/main"

clear
echo "🐦‍🔥 PhoenixCP CLI v1.0 Installer"
echo "Rise • Control • Deploy"
echo
sleep 1

# Root check
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

# Basic tools
echo "📦 Installing base requirements..."
apt update -y
apt install -y curl wget nano

# Install panel
echo "⬇ Downloading PhoenixCP CLI..."
curl -fsSL $REPO_RAW/minipanel.sh -o /usr/local/bin/minipanel

chmod +x /usr/local/bin/minipanel

echo
echo "✅ PhoenixCP CLI installed successfully!"
echo "🚀 Launching panel..."
sleep 1

minipanel
