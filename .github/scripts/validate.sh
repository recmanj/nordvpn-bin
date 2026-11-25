#!/usr/bin/env bash
# Lints, builds, installs and runs the package as root. Only run this in jobs
# with a read-only token and nothing that later publishes from the workspace.
set -euo pipefail

pacman -Syu --noconfirm --needed namcap shellcheck

id builder &>/dev/null || useradd -m builder
echo 'builder ALL=(root) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/builder
chown -R builder: .

sudo -u builder bash -euo pipefail <<'EOF'
echo '::group::.SRCINFO is up to date'
diff -u .SRCINFO <(makepkg --printsrcinfo)
echo '::endgroup::'

echo '::group::shellcheck'
shellcheck --shell=bash --exclude=SC2034,SC2154,SC2164 PKGBUILD
shellcheck --shell=bash nordvpn-bin.install
shellcheck .github/scripts/*.sh
echo '::endgroup::'

echo '::group::Checksums match the signed repo metadata'
diff -u <(.github/scripts/upstream.sh sums "$(source PKGBUILD; echo "$pkgver")") \
  <(.github/scripts/pkgbuild-sums.sh)
echo '::endgroup::'

# --verifysource only checks CARCH
for arch in $(source PKGBUILD; echo "${arch[@]}"); do
  echo "::group::Checksums ($arch)"
  sed "s/^CARCH=.*/CARCH=\"$arch\"/" /etc/makepkg.conf > "/tmp/makepkg-$arch.conf"
  makepkg --config "/tmp/makepkg-$arch.conf" --verifysource --noconfirm
  echo '::endgroup::'
done

echo '::group::namcap PKGBUILD'
namcap PKGBUILD | tee /tmp/namcap.txt
echo '::endgroup::'

echo '::group::Build'
PKGEXT=.pkg.tar makepkg --syncdeps --cleanbuild --noconfirm
echo '::endgroup::'

echo '::group::namcap package'
namcap ./*.pkg.tar | tee -a /tmp/namcap.txt
echo '::endgroup::'

if grep -q ' E: ' /tmp/namcap.txt; then
  echo '::error::namcap reported errors'
  exit 1
fi
EOF

echo '::group::Install and smoke test'
pacman -U --noconfirm ./*.pkg.tar
getent group nordvpn
missing=$(ldd /usr/bin/nordvpn /usr/bin/nordvpnd /usr/lib/nordvpn/{norduserd,nordfileshare,openvpn} |
  grep 'not found' || :)
if [[ -n $missing ]]; then
  echo "$missing"
  echo '::error::Unresolved shared libraries'
  exit 1
fi
nordvpn --version
echo '::endgroup::'
