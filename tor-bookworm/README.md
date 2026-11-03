# Tor 0.4.9.15 for eBlockerOS 4.0.3

The eBlockerOS 4.0.3 VM is based on Debian 12 Bookworm and ships Tor 0.4.7.16.
That client fails with missing `Desc=3 Microdesc=3` protocols
([issue #460][issue]). This recipe rebuilds Tor Project's Tor 0.4.9.15 Debian
source package on Bookworm. The Raspberry Pi 4/5 image is 64-bit; the intended
package architectures are `amd64` (VM/PC) and `arm64` (Pi). No binary packages
or source archives are committed here.

## Build

Use a clean Debian 12 Bookworm build environment of the target architecture.
Install the build dependencies, then run the script from this directory:

```sh
apt-get install --no-install-recommends \
  build-essential fakeroot dpkg-dev debhelper quilt libssl-dev zlib1g-dev \
  libevent-dev asciidoc docbook-xml docbook-xsl xmlto dh-apparmor \
  libsystemd-dev pkg-config libcap-dev dh-autoreconf \
  liblzma-dev libzstd-dev dh-runit curl ca-certificates
if [ "$(dpkg --print-architecture)" = amd64 ]; then
  apt-get install --no-install-recommends libseccomp-dev
fi
DEBFULLNAME='Your Name' DEBEMAIL='you@example.org' \
  ./build.sh /path/to/new-empty-build-directory
```

The script downloads three pinned inputs over HTTPS, checks their SHA256
digests, and creates `tor` and `tor-geoipdb` packages. The upstream tarball's
signed checksum was independently verified against Tor developer keys in the
lab. Release engineering should repeat that signature check. The default
`~eblab12+1` suffix identifies a lab build; maintainers can set
`PACKAGE_VERSION` for an official package revision.

Lab builds use `DEB_BUILD_OPTIONS=nocheck`; upstream unit tests are not run.
Pass `DEB_BUILD_OPTIONS=''` to run them in a release build.

## Validation on 3 November 2026

The `amd64` package was built in an isolated Debian 12 Bookworm environment.
Installation on an isolated official eBlockerOS 4.0.3 VM upgraded only `tor`
and `tor-geoipdb` from 0.4.7.16-1. `tor@eblocker.service` reached 100%
bootstrap; HTTPS through its Unix SOCKS socket returned HTTP 200 from
torstatus.greensec.de and `IsTor: true` from check.torproject.org. After a VM
reboot, the service again bootstrapped 100% and the HTTPS check returned 200.

The `arm64` package was built natively in an isolated Debian 12 Bookworm
environment on a Raspberry Pi 4 running eBlockerOS 4.0.3. Installation again
upgraded only `tor` and `tor-geoipdb` from 0.4.7.16-1. The eBlocker Tor instance
reached 100% bootstrap, and a DNS query through its Tor DNS port returned an A
record. After a Pi reboot, Tor again reached 100%; the DNS query succeeded,
HTTPS through its Unix SOCKS socket returned HTTP 200, and Tor Project's API
returned `IsTor: true`.

A routed eBlocker device test, upstream unit tests and maintainer review remain
release checks. This package does not change eBlocker itself or the security
support status of its Debian base.

[issue]: https://github.com/eblocker/eblocker/issues/460
