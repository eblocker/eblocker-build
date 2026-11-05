# Tor 0.4.9.15 for eBlockerOS 3

eBlockerOS 3.2.3 is based on Debian/Raspbian Buster and currently supplies Tor
0.4.5.16. That client rejects the Tor network consensus with missing
`Desc=3 Microdesc=3` protocols ([issue #460][issue]). This directory proposes
a reproducible Buster backport from Tor Project's 0.4.9.15 source and Debian
packaging. It does not contain third-party source archives or built binaries.

The only packaging change is to remove `dh-runit`: Buster's available version
does not meet the Tor packaging requirement. The systemd integration used by
eBlocker's `tor@eblocker.service` remains. The build is limited to `amd64` and
`armhf`, the two architectures tested with eBlockerOS 3.

## Build

Use a clean, native Debian 10 Buster `amd64` or Raspbian 10 Buster `armhf`
environment. Install the build dependencies there, rather than replacing
libraries on a running eBlocker appliance:

```sh
apt-get install --no-install-recommends \
  build-essential fakeroot dpkg-dev debhelper quilt libssl-dev zlib1g-dev \
  libevent-dev asciidoc docbook-xml docbook-xsl xmlto dh-apparmor \
  libsystemd-dev pkg-config libcap-dev dh-autoreconf liblzma-dev libzstd-dev
if [ "$(dpkg --print-architecture)" = amd64 ]; then
  apt-get install --no-install-recommends libseccomp-dev
fi
DEBFULLNAME='Your Name' DEBEMAIL='you@example.org' \
  ./build.sh /path/to/new-empty-build-directory
```

The script downloads three pinned inputs over HTTPS, checks their SHA256
digests, applies `buster.patch`, checks Debian build dependencies, and creates
`tor` and `tor-geoipdb` packages. The upstream tarball's signed checksum was
also verified in the lab against Tor developer keys; release engineering
should repeat that signature check independently. The default version suffix
`~eblab10+1` identifies the tested lab build. A maintainer can set
`PACKAGE_VERSION` for an official repository revision.

The lab builds used `DEB_BUILD_OPTIONS=nocheck`, so upstream unit tests were
not run. For a release build, run the test suite by passing an empty value:
`DEB_BUILD_OPTIONS='' ./build.sh ...`.

## Validation on 3 November 2026

| Target | Installation and network result |
| --- | --- |
| eBlockerOS 3.2.3 VM, Buster `amd64` | Installed `tor` and `tor-geoipdb` 0.4.9.15. `tor@eblocker` reached 100% bootstrap; HTTPS via its SOCKS port returned HTTP 200 from torstatus.greensec.de and `IsTor: true` from check.torproject.org. |
| eBlockerOS 3.2.3 Raspberry Pi 4, Raspbian `armhf` | Same result, repeated after a reboot; root SSH and the Tor instance started again. |
| Generic Debian 11 Bullseye `amd64` | A separate Bullseye package installed in a chroot and passed the same Tor network checks. It is outside this Buster recipe and was not tested as an eBlocker VM. |

These tests establish Tor client connectivity. A routed eBlocker device test,
upstream unit tests, and review of the final package revision remain release
checks. Updating Tor does not restore operating-system security support for
Buster. Boris and the eBlocker maintainers would still need to choose the
package revision, sign and publish it through the eBlocker update channel.

[issue]: https://github.com/eblocker/eblocker/issues/460
