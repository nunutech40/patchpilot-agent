#!/usr/bin/env bash
set -euo pipefail

APP_USER="${APP_USER:-patchpilot}"
APP_DIR="${APP_DIR:-/opt/patchpilot}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run with sudo or as root."
  exit 1
fi

echo "== Bootstrap PatchPilot VPS =="

apt-get update
apt-get install -y ca-certificates curl git ufw

if ! command -v docker >/dev/null 2>&1; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

if ! id "$APP_USER" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash "$APP_USER"
fi

usermod -aG docker "$APP_USER"

mkdir -p "$APP_DIR"
chown "$APP_USER:$APP_USER" "$APP_DIR"
chmod 750 "$APP_DIR"

if ! grep -q '^AllowUsers ' /etc/ssh/sshd_config 2>/dev/null; then
  echo "SSH AllowUsers not configured; leaving SSH policy unchanged."
fi

ufw allow OpenSSH
ufw --force enable

echo
echo "Bootstrap done."
echo "Next:"
echo "  1. Copy deploy/ files to $APP_DIR"
echo "  2. Copy deploy/.env.patchpilot.example to $APP_DIR/.env"
echo "  3. Fill secrets in $APP_DIR/.env"
echo "  4. Run: cd $APP_DIR && docker compose up -d --build"
