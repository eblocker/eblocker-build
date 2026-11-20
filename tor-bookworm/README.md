# Tor 0.4.9.17 for eBlockerOS 4.0.3 and 4.1.0

The eBlockerOS 4.0.3 VM is based on Debian 12 Bookworm and ships Tor 0.4.7.16.
That client fails with missing `Desc=3 Microdesc=3` protocols
([issue #460][issue]). An isolated eBlockerOS 4.1.0 VM also uses Bookworm and
shipped Tor 0.4.9.11, which bootstrapped successfully before this update. This
recipe rebuilds Tor Project's Tor 0.4.9.17 Debian source package on Bookworm
for both eBlockerOS releases. The Raspberry Pi 4/5 image is 64-bit; the
intended package architectures are `amd64` (VM/PC) and `arm64` (Pi). No binary
packages or source archives are committed here.

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
digests, and creates `tor` and `tor-geoipdb` packages. For 0.4.9.17, the
upstream tarball's signed checksum was verified against signatures from David
Goulet and Alexander Færøy with the fingerprints published by the Tor Project.
Release engineering should repeat that signature check. The default
`~eblab12+1` suffix identifies a lab build; maintainers can set
`PACKAGE_VERSION` for an official package revision.

Lab builds use `DEB_BUILD_OPTIONS=nocheck`; upstream unit tests are not run.
Pass `DEB_BUILD_OPTIONS=''` to run them in a release build.

## Source and client validation on 19–20 November 2026

The 0.4.9.17 tarball, Debian source descriptor and packaging diff matched the
SHA256 values pinned in `build.sh`. The signed upstream tarball checksum was
verified against the two Tor developer keys. `dpkg-source -x` succeeded.

The `amd64` recipe completed in an isolated Debian 12 Bookworm chroot with
`DEB_BUILD_OPTIONS=nocheck`. Its `tor` and `tor-geoipdb` packages installed in
that chroot; `tor --version` reported 0.4.9.17, the default configuration
validated, and `dpkg --audit` reported no problem. Upstream unit tests and a
runtime test of these **lab-built** packages on eBlockerOS were not performed.

On an eBlockerOS 4.1 T620 (Debian 12, `amd64`), the **official Tor Project
binary packages** `tor` and `tor-geoipdb` version
`0.4.9.17-1~d12.bookworm+1` were installed from the signed Bookworm repository.
Only those two packages were upgraded; the Tor Project keyring was added. After
an explicit restart, `tor@eblocker` reached 100% bootstrap and Tor DNSPort
answered a query. The eBlocker Tor configuration was unchanged. This validates
the official binary path on one client; it is not an eBlocker runtime test of
the lab packages produced by this recipe. The separate `arm64` lab-package
runtime test is described below; the `amd64` lab packages remain untested on
an eBlockerOS 4 client.

On 20 November, the same recipe was built natively in an isolated Debian 12
`arm64` chroot on a Raspberry Pi 4 running eBlockerOS 4.0.3. The resulting
`tor` and `tor-geoipdb` packages (`0.4.9.17-1~eblab12+1`) installed in that
chroot; `tor --version` reported 0.4.9.17, the default configuration was valid,
and `dpkg --audit` was clean. Only these two packages were then upgraded on the
Pi from the previously tested 0.4.9.15 lab pair. After an explicit restart,
`tor@eblocker` reached 100% bootstrap and an HTTPS request through its Unix
SOCKS socket returned HTTP 200 and `IsTor: true` from Tor Project's status API.
The eBlocker Tor configuration hash remained unchanged. The previous package
pair was kept locally for rollback. After a Pi reboot, both package versions,
100% bootstrap, HTTPS 200, `IsTor: true`, and the unchanged configuration hash
were confirmed again. This is an eBlockerOS 4.0.3 `arm64` runtime test of the
lab-built 0.4.9.17 packages; no 4.1.0 Pi runtime test was done.

## Historical lab validation on 3 November 2026 (0.4.9.15)

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

An isolated clone of an eBlockerOS 4.1.0 VM (Debian 12 Bookworm, `amd64`) was
then tested with the same `amd64` lab package pair. Its existing Tor 0.4.9.11
already reached 100% bootstrap. An apt simulation and installation upgraded
only `tor` and `tor-geoipdb` to 0.4.9.15. After restarting `tor@eblocker`, it
reached 100% bootstrap; HTTPS through its Unix SOCKS socket returned HTTP 200
and Tor Project's API reported `IsTor: true`. The package versions, 100%
bootstrap, HTTPS 200 and `IsTor: true` were confirmed again after a VM reboot.
Neither running 4.1.0 VM received a package change; a snapshot of one was used
to create the isolated clone. An eBlockerOS 4.1.0 Raspberry Pi runtime was not
available for this test; the `arm64` build was tested on the
Bookworm-based 4.0.3 Pi as described above.

A routed eBlocker device test, upstream unit tests and maintainer review remain
release checks. This package does not change eBlocker itself or the security
support status of its Debian base.

[issue]: https://github.com/eblocker/eblocker/issues/460
