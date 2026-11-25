# nordvpn-bin

Arch Linux package for the NordVPN daemon and CLI, repackaged from NordVPN's
official Debian repository. For the GUI, see
[nordvpn-gui-bin](https://github.com/recmanj/nordvpn-gui-bin).

## Installation

```sh
git clone https://github.com/recmanj/nordvpn-bin.git
cd nordvpn-bin
makepkg -si
```

Enable the daemon and add yourself to the `nordvpn` group:

```sh
sudo systemctl enable --now nordvpnd.socket nordvpnd.service
sudo usermod -aG nordvpn "$USER"
```

Log out and back in, then run `nordvpn login`.

## Updating

```sh
git pull
makepkg -si
```

A daily workflow opens a pull request when NordVPN publishes a new version.

## Differences from the .deb

- `nordvpnd` is installed to `/usr/bin`.
- The `nordvpn` group, `/var/log/nordvpn` and the library path are set up with
  sysusers.d, tmpfiles.d and `/etc/ld.so.conf.d` instead of install scripts.
- The service is not enabled and no user is added to the group on install.
- Removing the package stops and disables the daemon.

## Checksums

NordVPN does not sign the .deb files, only the repository metadata. The
checksums in the PKGBUILD are taken from the repository's `Packages` index,
which is checked against the `InRelease` file signed with the key in
[`keys/pgp`](keys/pgp) (`BC5480EFEC5C081CE5BCFBE26B219E535C964CA1`). CI repeats
this check on every change.
