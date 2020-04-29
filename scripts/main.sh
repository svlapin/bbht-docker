#!/bin/sh

subs=$($(dirname $0)/all_subs.sh $1)

cnames=$(echo "$subs" | grep "CNAME")
a_records=$(echo "$subs" | grep " A ")

scan_ip_with_nmap() {
  nmap -sV -T3 -Pn -n --top-ports 1000 "$1"
}

echo "CNAMES:"
for s in "$cnames"; do
  echo "$s"
done
echo

echo "A records:"
ips=$(echo "$subs" | grep " A " | cut -d " " -f 3 | sort | uniq)

echo "$ips" | while read ip; do
  echo "=== $ip"
  echo "$subs" | grep "$ip"
  scan_ip_with_nmap "$ip"
done
