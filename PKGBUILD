# Maintainer: recmanj <recmanj at gmail dot com>

pkgname=nordvpn-bin
_pkgname=nordvpn
pkgver=1.0
pkgrel=1
pkgdesc='NordVPN client and daemon for Linux (binary release)'
arch=(x86_64 aarch64)
url='https://nordvpn.com/download/linux/'
# Sources are GPL-3.0-only; the deb also bundles closed NordVPN libraries
# (libmoose*, libquench) and upstream labels it "License: Proprietary"
license=('GPL-3.0-only' 'LicenseRef-NordVPN')
depends=(ca-certificates glibc hicolor-icon-theme iproute2 libcap-ng libgcc libidn2 libnl libxslt
	procps-ng sqlite zlib)
optdepends=('iptables: legacy firewall backend'
	'nordvpn-gui-bin: graphical interface')
provides=("$_pkgname=$pkgver")
conflicts=("$_pkgname")
install=$pkgname.install
options=(!strip !debug)
_pool="https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/$_pkgname"
source_x86_64=("$_pool/${_pkgname}_${pkgver}_amd64.deb")
source_aarch64=("$_pool/${_pkgname}_${pkgver}_arm64.deb")
# The deb is not signed; these come from the signed repo metadata,
# see .github/scripts/upstream.sh
sha256sums_x86_64=('f8b5489babb2b67fb49dc8ed891b9e423078831dbb3ad276fae1e5c6254731fb')
sha256sums_aarch64=('d3f8f8ddce79d4ca4560d006744c76bddf2e9ff1184057d46618937b94ad1cd6')

_license_note() {
	install -Dm0644 /dev/stdin "$1/LICENSE.NordVPN" <<-'EOF'
	The NordVPN for Linux sources are published under GPL-3.0-only at
	https://github.com/NordSecurity/nordvpn-linux.

	The binaries in this package are taken unmodified from NordVPN's Debian
	repository, which labels them "License: Proprietary". They include closed
	NordVPN components and are subject to NordVPN's Terms of Service:
	https://my.nordaccount.com/legal/terms-of-service/
	EOF
}

package() {
	# makepkg extracts the deb; data.tar.* is its payload
	bsdtar -xf "$srcdir"/data.tar.* -C "$pkgdir"
	cd "$pkgdir"

	# /usr/sbin is a symlink to /usr/bin on Arch
	mv usr/sbin/nordvpnd usr/bin/nordvpnd
	rmdir usr/sbin
	sed -i 's|/usr/sbin/nordvpnd|/usr/bin/nordvpnd|' \
		usr/lib/systemd/system/nordvpnd.service \
		usr/lib/systemd/system/nordvpnd-killswitch.service
	if grep -rq /usr/sbin usr/lib/systemd; then
		echo 'Unexpected /usr/sbin reference left in systemd units' >&2
		return 1
	fi

	# SysV script, a /dev/null mask for a unit that no longer exists, Debian changelog
	rm -r etc/init.d usr/share/doc
	rm usr/lib/systemd/system/nordvpn.service
	rmdir etc 2> /dev/null || :

	# The deb's postinst does this with ldconfig and a libsqlite3.so symlink.
	# Arch's sqlite already ships libsqlite3.so, and pacman runs ldconfig.
	install -Dm0644 /dev/stdin etc/ld.so.conf.d/nordvpn.conf <<< '/usr/lib/nordvpn'
	chmod 0644 usr/lib/nordvpn/*.so

	# The deb's preinst creates the group with groupadd
	install -Dm0644 /dev/stdin usr/lib/sysusers.d/nordvpn.conf <<< 'g nordvpn - -'
	chmod 0644 usr/lib/tmpfiles.d/nordvpn.conf
	echo 'd /var/log/nordvpn 0750 root nordvpn' >> usr/lib/tmpfiles.d/nordvpn.conf

	chmod 0644 usr/share/bash-completion/completions/nordvpn

	# Upstream's zsh file is meant to be sourced with $PROG set; turn it into
	# an autoloadable completion function
	local _zsh=usr/share/zsh/functions/Completion/Unix/_nordvpn_auto_complete
	# shellcheck disable=SC2016
	if [[ $(head -n1 "$_zsh") != '#compdef $PROG' ]] ||
		[[ $(tail -n1 "$_zsh") != 'compdef _cli_zsh_autocomplete $PROG' ]]; then
		echo 'Unexpected zsh completion template' >&2
		return 1
	fi
	install -dm0755 usr/share/zsh/site-functions
	# shellcheck disable=SC2016
	sed -e '1s/.*/#compdef nordvpn/' \
		-e '$s/.*/_cli_zsh_autocomplete "$@"/' \
		"$_zsh" > usr/share/zsh/site-functions/_nordvpn
	chmod 0644 usr/share/zsh/site-functions/_nordvpn
	rm -r usr/share/zsh/functions

	mv usr/share/licenses/nordvpn "usr/share/licenses/$pkgname"
	_license_note "usr/share/licenses/$pkgname"
}
