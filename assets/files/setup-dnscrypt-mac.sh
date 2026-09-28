#!/bin/zsh
# ------------------------------------------------------------------
# Private DNS setup for macOS (advanced fallback)
# Use this ONLY if the double-click profile (Private-DNS-Cloudflare.mobileconfig)
# won't install -- e.g. a VPN like ExpressVPN is blocking it.
# It installs a local DNS-over-HTTPS resolver (dnscrypt-proxy).
# Requires: Homebrew (https://brew.sh) and your admin password.
# ------------------------------------------------------------------
set -e

echo ">> Checking Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
  echo "!! Homebrew is not installed. Install it from https://brew.sh first, then re-run this."
  exit 1
fi

echo ">> Installing dnscrypt-proxy..."
brew install dnscrypt-proxy

ETC="$(brew --prefix)/etc/dnscrypt-proxy.toml"
echo ">> Writing config to $ETC"
[ -f "$ETC" ] && cp "$ETC" "$ETC.orig.bak" && echo "   (backed up original to $ETC.orig.bak)"
cat > "$ETC" <<'CFG'
# Local DoH resolver -> Cloudflare, over port 443.
# Works on networks that block port 53 to external DNS.
listen_addresses = ['127.0.0.1:53']
max_clients = 250
ipv4_servers = true
ipv6_servers = false
dnscrypt_servers = false
doh_servers = true
require_dnssec = false
require_nolog = false
require_nofilter = false
server_names = ['cf-1111', 'cf-cdn', 'moz-cf']
netprobe_timeout = 0
netprobe_address = '1.1.1.1:443'
bootstrap_resolvers = ['1.1.1.1:443']
ignore_system_dns = true
cache = true
cache_size = 4096

[static]
  # Primary: Cloudflare via 1.1.1.1
  [static.'cf-1111']
  stamp = 'sdns://AgcAAAAAAAAABzEuMS4xLjEAEmRucy5jbG91ZGZsYXJlLmNvbQovZG5zLXF1ZXJ5'
  # Fallback 1: Cloudflare on a shared CDN IP (hard for filters to block)
  [static.'cf-cdn']
  stamp = 'sdns://AgAAAAAAAAAADjEwNC4xNi4yNDkuMjQ5ABJjbG91ZGZsYXJlLWRucy5jb20KL2Rucy1xdWVyeQ'
  # Fallback 2: Mozilla's Cloudflare DoH (different CDN range)
  [static.'moz-cf']
  stamp = 'sdns://AgAAAAAAAAAACzE3Mi42NC40MS40ABptb3ppbGxhLmNsb3VkZmxhcmUtZG5zLmNvbQovZG5zLXF1ZXJ5'
CFG

echo ">> Starting the resolver as a system service (needs your password)..."
sudo brew services start dnscrypt-proxy

echo ">> Pointing your active network at the local resolver..."
# Set 127.0.0.1 on every active network service (Wi-Fi, Ethernet, etc.)
IFS=$'\n'
for svc in $(networksetup -listallnetworkservices | tail -n +2 | sed 's/^\*//'); do
  # only set on services that currently have an IP (are in use)
  if networksetup -getinfo "$svc" 2>/dev/null | grep -q "IP address: [0-9]"; then
    networksetup -setdnsservers "$svc" 127.0.0.1 && echo "   set DNS on: $svc"
  fi
done
unset IFS

sleep 2
echo ">> Verifying..."
if dig +time=5 +tries=2 @127.0.0.1 example.com +short | grep -qE '[0-9]'; then
  echo "   SUCCESS -- encrypted DNS is working."
else
  echo "   Could not verify. Check: sudo brew services list  and  cat $ETC"
fi

echo
echo "Done. To UNDO later, run setup-dnscrypt-mac-UNINSTALL.sh"
