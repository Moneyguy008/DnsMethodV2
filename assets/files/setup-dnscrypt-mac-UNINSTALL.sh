#!/bin/zsh
# Undo the dnscrypt-proxy private-DNS setup on macOS.
echo ">> Resetting DNS to automatic on all network services..."
IFS=$'\n'
for svc in $(networksetup -listallnetworkservices | tail -n +2 | sed 's/^\*//'); do
  networksetup -setdnsservers "$svc" "Empty" 2>/dev/null && echo "   reset: $svc"
done
unset IFS
echo ">> Stopping and removing the resolver..."
sudo brew services stop dnscrypt-proxy 2>/dev/null || true
brew uninstall dnscrypt-proxy 2>/dev/null || true
echo "Done. Back to normal network DNS."
