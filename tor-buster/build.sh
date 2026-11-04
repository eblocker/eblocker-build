#!/bin/sh
# Build Tor 0.4.9.15 packages for eBlockerOS 3's Buster base.
set -eu

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 EMPTY_BUILD_DIRECTORY" >&2
    exit 2
fi

. /etc/os-release
if [ "${VERSION_CODENAME:-}" != buster ]; then
    echo "Build inside a Debian or Raspbian Buster environment." >&2
    exit 2
fi

case "$(dpkg --print-architecture)" in
    amd64|armhf) ;;
    *) echo "Only amd64 and armhf were tested." >&2; exit 2 ;;
esac

for command in curl sha256sum dpkg-source patch dpkg-checkbuilddeps dpkg-buildpackage; do
    command -v "$command" >/dev/null 2>&1 || {
        echo "Missing build command: $command" >&2
        exit 2
    }
done

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
mkdir -p "$1"
cd "$1"
if [ -n "$(ls -A .)" ]; then
    echo "Build directory must be empty: $1" >&2
    exit 2
fi

curl -fLsS --retry 3 \
    https://archive.torproject.org/tor-package-archive/tor-0.4.9.15.tar.gz \
    -o tor_0.4.9.15.orig.tar.gz
curl -fLsS --retry 3 \
    https://deb.torproject.org/torproject.org/pool/main/t/tor/tor_0.4.9.15-1.dsc \
    -o tor_0.4.9.15-1.dsc
curl -fLsS --retry 3 \
    https://deb.torproject.org/torproject.org/pool/main/t/tor/tor_0.4.9.15-1.diff.gz \
    -o tor_0.4.9.15-1.diff.gz

# Pinned inputs: the .dsc also records the tarball and diff checksums.
cat > SHA256SUMS <<'EOF'
1911f5b216a6814ed143a08bbcff1c6dc96d2ca3b505df9a21876080a92963f3  tor_0.4.9.15.orig.tar.gz
f0e8424f39541ef58e55706ed986ac8a0e13caf964f72eaec81313dbcf8542ed  tor_0.4.9.15-1.dsc
a2e8beab0e4ba9649013573816bfb5ee5818786cdd5beba72ffb2a8a26c00f89  tor_0.4.9.15-1.diff.gz
EOF
sha256sum -c SHA256SUMS

dpkg-source -x tor_0.4.9.15-1.dsc
patch -d tor-0.4.9.15 -p1 < "$script_dir/buster.patch"

package_version=${PACKAGE_VERSION:-0.4.9.15-1~eblab10+1}
maintainer_name=${DEBFULLNAME:-Tor backport lab}
maintainer_email=${DEBEMAIL:-lab@localhost.invalid}
{
    printf 'tor (%s) buster; urgency=medium\n\n' "$package_version"
    printf '  * Backport Tor 0.4.9.15 for eBlockerOS 3 on Buster.\n'
    printf '  * Omit unavailable dh-runit integration; retain systemd.\n\n'
    printf ' -- %s <%s>  %s\n\n' "$maintainer_name" "$maintainer_email" "$(date -R)"
    cat tor-0.4.9.15/debian/changelog
} > changelog.new
mv changelog.new tor-0.4.9.15/debian/changelog

(
    cd tor-0.4.9.15
    dpkg-checkbuilddeps
    DEB_BUILD_OPTIONS=${DEB_BUILD_OPTIONS-nocheck} \
        dpkg-buildpackage -b -us -uc -j"${JOBS:-2}"
)

echo 'Built packages:'
sha256sum ./*.deb
