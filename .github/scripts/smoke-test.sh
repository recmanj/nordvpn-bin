#!/usr/bin/env bash
set -euo pipefail

getent group nordvpn
missing=$(ldd /usr/bin/nordvpn /usr/bin/nordvpnd /usr/lib/nordvpn/{norduserd,nordfileshare,openvpn} |
  grep 'not found' || :)
if [[ -n $missing ]]; then
  echo "$missing"
  echo '::error::Unresolved shared libraries'
  exit 1
fi
nordvpn --version
