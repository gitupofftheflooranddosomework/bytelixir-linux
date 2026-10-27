#!/usr/bin/env bash
#
# install.sh — install blx-proxy and build 3proxy from source.
#
# 3proxy is not shipped in Debian/Ubuntu's default repositories, so the
# reliable path is building upstream's source (gcc + make only, no exotic
# dependencies). The build is pinned to a tested commit (see below).
#
# Usage: sudo ./install.sh
# After install, run: sudo blx-proxy setup
#
set -euo pipefail

# Pinned 3proxy source snapshot (verified to build on Ubuntu 24.04).
# Update this deliberately, with a rebuild + `blx-proxy test`, not casually.
PROXY_REPO="https://github.com/3proxy/3proxy.git"
PROXY_COMMIT="371e78691d321f703cbf19b46e5cc4d22dff1241"

die() { echo "install.sh: $*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || die "must run as root (use sudo)"

echo "== blx-proxy install =="

# --- dependencies ---
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -qq
  apt-get install -y -qq gcc make git openssl curl procps iproute2 >/dev/null \
    || die "apt install failed"
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y -q gcc make git openssl curl procps-ng iproute >/dev/null \
    || die "dnf install failed"
else
  die "unsupported package manager — install gcc, make, git, openssl, curl manually, then re-run"
fi

# --- build 3proxy from pinned source ---
BUILD_DIR="$(mktemp -d /tmp/blx-3proxy-build.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT
git clone -q "$PROXY_REPO" "$BUILD_DIR" || die "git clone failed"
cd "$BUILD_DIR"
git checkout -q "$PROXY_COMMIT" || die "pinned commit $PROXY_COMMIT not found"
make -f Makefile.Linux >/dev/null 2>&1 || die "3proxy build failed"
install -m 0755 bin/3proxy /usr/local/bin/3proxy
echo "3proxy installed: $(/usr/local/bin/3proxy 2>&1 | head -1 || true)"

# --- install blx-proxy files ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
install -m 0755 "$SCRIPT_DIR/blx-proxy" /usr/local/bin/blx-proxy
mkdir -p /etc/blx-proxy /var/log/blx-proxy
cp "$SCRIPT_DIR/3proxy.cfg.template" /etc/blx-proxy/3proxy.cfg.template
cp "$SCRIPT_DIR/blx-proxy.service" /etc/systemd/system/blx-proxy.service
if command -v systemctl >/dev/null 2>&1; then
  systemctl daemon-reload
fi

echo
echo "Installed. Next steps:"
echo "  1. Make sure your Bytelixir account has passed KYC (required before"
echo "     proxies can be added — an unverified account cannot add proxies)."
echo "  2. Run:  sudo blx-proxy setup"
echo "  3. Paste the printed string into Bytelixir: Proxies -> Add proxies."
echo "  4. Verify: sudo blx-proxy test   (proves it is not an open relay)"
