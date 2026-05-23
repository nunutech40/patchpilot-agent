#!/usr/bin/env bash
set -euo pipefail

echo "== PatchPilot VPS preflight =="
echo

echo "-- identity"
hostname
whoami
id
echo

echo "-- os"
uname -a
if command -v lsb_release >/dev/null 2>&1; then
  lsb_release -ds
else
  cat /etc/os-release
fi
echo

echo "-- uptime"
uptime
echo

echo "-- disk"
df -h / /home 2>/dev/null || df -h /
echo

echo "-- memory"
free -h
echo

echo "-- ports"
ss -ltnp 2>/dev/null | sed -n '1,120p' || ss -ltn | sed -n '1,120p'
echo

echo "-- docker"
if command -v docker >/dev/null 2>&1; then
  docker --version
  docker compose version || true
  docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' || true
else
  echo "docker not installed"
fi
echo

echo "-- firewall"
if command -v ufw >/dev/null 2>&1; then
  sudo ufw status verbose || true
else
  echo "ufw not installed"
fi
echo

echo "-- reboot"
if [ -f /var/run/reboot-required ]; then
  cat /var/run/reboot-required
else
  echo "no-reboot-required"
fi
