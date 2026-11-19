#!/bin/sh
# Build Tor 0.4.9.17 packages for eBlockerOS 4's Bookworm base.
set -eu

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 EMPTY_BUILD_DIRECTORY" >&2
    exit 2
fi

. /etc/os-release
if [ "${VERSION_CODENAME:-}" != bookworm ]; then
    echo "Build inside a Debian or Raspberry Pi OS Bookworm environment." >&2
    exit 2
fi

case "$(dpkg --print-architecture)" in
    amd64|arm64) ;;
    *) echo "Only amd64 and arm64 are supported by this recipe." >&2; exit 2 ;;
esac

for command in curl sha256sum dpkg-source dpkg-checkbuilddeps dpkg-buildpackage; do
    command -v "$command" >/dev/null 2>&1 || {
        echo "Missing build command: $command" >&2
        exit 2
    }
done

mkdir -p "$1"
cd "$1"
if [ -n "$(ls -A .)" ]; then
    echo "Build directory must be empty: $1" >&2
    exit 2
fi

curl -fLsS --retry 3 \
    https://archive.torproject.org/tor-package-archive/tor-0.4.9.17.tar.gz \
    -o tor_0.4.9.17.orig.tar.gz
curl -fLsS --retry 3 \
    https://deb.torproject.org/torproject.org/pool/main/t/tor/tor_0.4.9.17-1.dsc \
    -o tor_0.4.9.17-1.dsc
curl -fLsS --retry 3 \
    https://deb.torproject.org/torproject.org/pool/main/t/tor/tor_0.4.9.17-1.diff.gz \
    -o tor_0.4.9.17-1.diff.gz

cat > SHA256SUMS <<'EOF'
ff372c41ee7013557fe5b7acd96c909950b27a7959c59fcb87c02591682fabe2  tor_0.4.9.17.orig.tar.gz
5152b6eecbdc786237756650b2e39e777d7bd492d19add7ee2ec880b5c87594d  tor_0.4.9.17-1.dsc
9c0bbccfa0dc7081a759549e791d1c8a5aaccba853f654922fa3a124dcab01b3  tor_0.4.9.17-1.diff.gz
EOF
sha256sum -c SHA256SUMS

dpkg-source -x tor_0.4.9.17-1.dsc

package_version=${PACKAGE_VERSION:-0.4.9.17-1~eblab12+1}
maintainer_name=${DEBFULLNAME:-Tor backport lab}
maintainer_email=${DEBEMAIL:-lab@localhost.invalid}
{
    printf 'tor (%s) bookworm; urgency=medium\n\n' "$package_version"
    printf '  * Rebuild Tor 0.4.9.17 for eBlockerOS 4 on Bookworm.\n\n'
    printf ' -- %s <%s>  %s\n\n' "$maintainer_name" "$maintainer_email" "$(date -R)"
    cat tor-0.4.9.17/debian/changelog
} > changelog.new
mv changelog.new tor-0.4.9.17/debian/changelog

(
    cd tor-0.4.9.17
    dpkg-checkbuilddeps
    DEB_BUILD_OPTIONS=${DEB_BUILD_OPTIONS-nocheck} \
        dpkg-buildpackage -b -us -uc -j"${JOBS:-2}"
)

echo 'Built packages:'
sha256sum ./*.deb
