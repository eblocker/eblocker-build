# Tor 0.4.9.17 for eBlockerOS 3

eBlockerOS 3.2.3 is based on Debian/Raspbian Buster and currently supplies Tor
0.4.5.16. That client rejects the Tor network consensus with missing
`Desc=3 Microdesc=3` protocols ([issue #460][issue]). This directory proposes
a reproducible Buster backport from Tor Project's 0.4.9.17 source and Debian
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
`tor` and `tor-geoipdb` packages. For 0.4.9.17, the upstream tarball's
checksum was verified against signatures from David Goulet and Alexander
Færøy with the fingerprints published by the Tor Project. Release engineering
should repeat that signature check independently. The default version suffix
`~eblab10+1` identifies the tested lab build. A maintainer can set
`PACKAGE_VERSION` for an official repository revision.

The lab builds used `DEB_BUILD_OPTIONS=nocheck`, so upstream unit tests were
not run. For a release build, run the test suite by passing an empty value:
`DEB_BUILD_OPTIONS='' ./build.sh ...`.

## Source validation on 19 November 2026

The 0.4.9.17 tarball, Debian source descriptor and packaging diff matched the
SHA256 values pinned in `build.sh`. The signed upstream tarball checksum was
verified against the two Tor developer keys. `dpkg-source -x` succeeded and
`buster.patch` applied in a dry run. The historical runtime results below
belong to 0.4.9.15.

The `amd64` recipe then completed in an isolated Debian 10 Buster chroot with
`DEB_BUILD_OPTIONS=nocheck`. Its `tor` and `tor-geoipdb` packages installed in
that chroot; `tor --version` reported 0.4.9.17, the default configuration
validated, and `dpkg --audit` reported no problem. This does not establish a
working Tor circuit on eBlockerOS 3. The Buster runtime warned that its
OpenSSL 1.1.1 is no longer maintained. Upstream unit tests, an eBlockerOS 3
runtime test of the new lab packages and an `armhf` build remain open.

## Historical runtime validation on 3 November 2026 (0.4.9.15)

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
