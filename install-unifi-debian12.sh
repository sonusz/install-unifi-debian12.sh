#!/usr/bin/env bash
# Install/upgrade UniFi Network Application on Debian 12 (bookworm)
# Based on: Ubiquiti "Updating and Installing Self-Hosted UniFi Network Servers (Linux)"
# Adapted to use MongoDB 7.0 on Debian 12.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root, e.g.: sudo $0"
  exit 1
fi

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  if [[ "${ID:-}" != "debian" || "${VERSION_CODENAME:-}" != "bookworm" ]]; then
    echo "Warning: this script is tailored for Debian 12 (bookworm)."
    echo "         Continuing anyway in 5 seconds... (Ctrl+C to abort)"
    sleep 5
  fi
fi

echo "[1/5] Updating APT and installing base packages..."
apt-get update
apt-get install -y gnupg curl ca-certificates apt-transport-https

echo "[2/5] Adding MongoDB 7.0 repo (Debian bookworm)..."
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \
  | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg

cat >/etc/apt/sources.list.d/mongodb-org-7.0.list <<'EOF'
deb [ arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main
EOF

# If you previously followed the old 3.6 step from the UI doc, disable that list:
if [[ -f /etc/apt/sources.list.d/mongodb-org-3.6.list ]]; then
  echo "  - Disabling legacy mongodb-org-3.6.list to avoid conflicts..."
  mv /etc/apt/sources.list.d/mongodb-org-3.6.list \
     /etc/apt/sources.list.d/mongodb-org-3.6.list.disabled || true
fi

echo "[3/5] Adding UniFi APT repo and GPG key..."
curl -fsSL https://dl.ui.com/unifi/unifi-repo.gpg \
  | gpg --dearmor -o /usr/share/keyrings/unifi-repo.gpg

cat >/etc/apt/sources.list.d/unifi.list <<'EOF'
deb [ arch=amd64 signed-by=/usr/share/keyrings/unifi-repo.gpg ] https://www.ui.com/downloads/unifi/debian stable ubiquiti
EOF

echo "[4/5] Updating APT with new repos..."
apt-get update

echo "[5/5] Installing MongoDB and UniFi Network Application..."
apt-get install -y mongodb-org
systemctl enable --now mongod

apt-get install -y unifi
systemctl enable --now unifi

echo
echo "UniFi installation complete on Debian 12."
echo
echo "Services:"
echo "  systemctl status mongod"
echo "  systemctl status unifi"
echo
echo "Web UI:  https://<this-server-ip>:8443"
echo
