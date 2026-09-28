#!/bin/zsh
# ------------------------------------------------------------------
# DNS / network diagnostic for macOS
# Safe & read-only, except it resets your Wi-Fi DNS to automatic so
# you regain a normal connection while testing.
# Run it on the problem network:   zsh dns-diagnostic.sh
# Then read the results it prints (also saved to ~/dns-diag-results.txt).
# ------------------------------------------------------------------
OUT=~/dns-diag-results.txt
{
echo "==== DNS / NETWORK DIAGNOSTIC  $(date) ===="

echo
echo "## Resetting Wi-Fi DNS to automatic so you have working network for this test..."
networksetup -setdnsservers "Wi-Fi" "Empty" 2>/dev/null
sleep 2
echo "   Wi-Fi DNS now: $(networksetup -getdnsservers Wi-Fi)"

echo
echo "## The network's own DNS / router:"
ipconfig getpacket en0 2>/dev/null | grep -E 'server_identifier|domain_name_server|router' | sed 's/^/   /'

echo
echo "## Can plain DNS (port 53) reach outside resolvers?  (NO ANSWER = blocked)"
for ip in 8.8.8.8 1.1.1.1 9.9.9.9; do
  printf "   dig @%-8s " "$ip"
  ans=$(dig +time=3 +tries=1 @$ip example.com +short 2>/dev/null | head -1)
  [ -n "$ans" ] && echo "-> $ans" || echo "-> NO ANSWER (blocked)"
done

echo
echo "## Can encrypted DNS (DoH, port 443) get through?  (HTTP 200 = yes)"
doh(){ printf "   %-32s " "$1 @ $2"; curl -s --max-time 8 --resolve "$1:443:$2" -o /dev/null -w "HTTP %{http_code} (%{time_total}s)\n" -H 'accept: application/dns-message' "https://$1/dns-query?dns=AAABAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB" 2>&1 || echo "FAIL/blocked"; }
doh cloudflare-dns.com 104.16.249.249
doh mozilla.cloudflare-dns.com 172.64.41.4
doh dns.google 8.8.8.8

echo
echo "## Is a specific site blocked by DNS or by IP?  (edit SITE below to test another)"
SITE=www.roblox.com
echo "   -- what the network's DNS says for $SITE (a 'block-page' name = DNS block):"
printf "      "; dig +time=3 +tries=1 "$SITE" +short 2>/dev/null | head -2 | tr '\n' ' '; echo
echo "   -- the REAL address via encrypted DNS:"
REAL=$(curl -s --max-time 8 --resolve cloudflare-dns.com:443:104.16.249.249 -H 'accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=$SITE&type=A" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(" ".join(a["data"] for a in d.get("Answer",[]) if a.get("type")==1))' 2>/dev/null)
echo "      $REAL"
echo "   -- is that REAL address reachable? (BLOCKED here = IP/firewall block, DNS cannot fix):"
for ip in $REAL; do printf "      %-16s " "$ip:443"; nc -z -G 4 -w 4 "$ip" 443 >/dev/null 2>&1 && echo "OPEN (DNS fix will work)" || echo "BLOCKED (needs a VPN)"; done

echo
echo "## Sanity: a normal site should work:"
printf "      curl https://example.com : "; curl -s --max-time 8 -o /dev/null -w "HTTP %{http_code}\n" https://example.com 2>&1 || echo "FAIL"
echo "==== END ===="
} 2>&1 | tee "$OUT"
echo
echo "Saved to $OUT"
