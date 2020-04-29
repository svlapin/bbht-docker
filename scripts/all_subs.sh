#!/bin/sh

home_dir="/home/runner"
jhaddix_wordlist="$home_dir/tools/SecLists/Discovery/DNS/clean-jhaddix-dns.txt"
mass_dns_dir="$home_dir/tools/massdns"
mass_dns_resolvers="$mass_dns_dir/lists/resolvers.txt"
mass_dns_wordlist="$mass_dns_dir/lists/names.txt"

###
# curl
# jq
# awk
###
certsh() {
  curl -s "https://crt.sh/?output=json&q=$1" 2>/dev/null | jq '.[].name_value' -r
}

certspotter() {
  curl -s "https://certspotter.com/api/v0/certs\?domain\=$1" 2>/dev/null | jq -r '.[].dns_names[]' 2>/dev/null
}

all_subs() {
  {
    certspotter "$1"
    certsh "$1"
  } | awk '{print tolower($0)}' | sed -e 's/^*.//' | sort - | uniq
}

# output:
# domain. A IP
# domain. CNAME anotherdomain.
# notice trailing dots! (defined by massdns output format - here it's simple text)
massdns_brute() {
  "$mass_dns_dir/scripts/subbrute.py" "$mass_dns_wordlist" "$1" | "$mass_dns_dir/bin/massdns" -q -r "$mass_dns_resolvers" -o S 2>/dev/null
}

massdns_filter() {
  "$mass_dns_dir/bin/massdns" -q -r "$mass_dns_resolvers" -o S - 2>/dev/null
}

all_subs "$1" | massdns_filter

# TODO: implement brute when a flag is provided
# massdns_brute "$1"
