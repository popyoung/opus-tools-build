#!/usr/bin/env bash
set -euo pipefail
root="$PWD"
prefix="$root/build/prefix"
mkdir -p build/sources "$prefix" output/licenses
cat > output/source-sha256.txt <<'HASHES'
6ffcb593207be92584df15b32466ed64bbec99109f007c82205f0194572411a1  opus-1.6.1.tar.gz
f616d3aff9b2034547894ccb8ab56c36cf1a4acb0d922c5d7119f97bbe58642c  libopusenc-0.3.tar.gz
b4e56cb00d3e509acfba9a9b627ffd8273b876b4e2408642259f6da28fa0ff86  opus-tools-0.2.tar.gz
83e6704730683d004d20e21b8f7f55dcb3383cdf84c0daedf30bde175f774638  libogg-1.3.6.tar.gz
118d8601c12dd6a44f52423e68ca9083cc9f2bfe72da7a8c1acb22a80ae3550b  opusfile-0.12.tar.gz
HASHES
cd build/sources
for archive in opus-1.6.1.tar.gz libopusenc-0.3.tar.gz opus-tools-0.2.tar.gz libogg-1.3.6.tar.gz opusfile-0.12.tar.gz; do
  group=opus
  if [[ "$archive" == libogg-* ]]; then group=ogg; fi
  curl --fail --location --retry 3 --proto '=https' --proto-redir '=https' "https://downloads.xiph.org/releases/$group/$archive" --output "$archive"
done
sha256sum --check "$root/output/source-sha256.txt"
for archive in *.tar.gz; do tar -xzf "$archive"; done
export CC=x86_64-w64-mingw32-gcc
export AR=x86_64-w64-mingw32-ar
export RANLIB=x86_64-w64-mingw32-ranlib
export PKG_CONFIG_LIBDIR="$prefix/lib/pkgconfig"
export CFLAGS='-O2'
export LDFLAGS='-static -static-libgcc'
common=(--host=x86_64-w64-mingw32 --prefix="$prefix" --disable-shared --enable-static)
for package in libogg-1.3.6 opus-1.6.1 libopusenc-0.3 opusfile-0.12; do
  cd "$root/build/sources/$package"
  extra=()
  case "$package" in
    opus-*) extra=(--disable-extra-programs --disable-doc);;
    libopusenc-*) extra=(--disable-examples --disable-doc);;
    opusfile-*) extra=(--disable-http --disable-examples --disable-doc);;
  esac
  ./configure "${common[@]}" "${extra[@]}"
  make -j2
  make install
  cp COPYING "$root/output/licenses/$package-COPYING.txt"
done
cd "$root/build/sources/opus-tools-0.2"
./configure "${common[@]}" --without-flac --disable-stack-protector --disable-pie
make -j2 opusenc.exe opusinfo.exe
cp opusenc.exe opusinfo.exe "$root/output/"
cp COPYING "$root/output/licenses/opus-tools-0.2-COPYING.txt"
cd "$root"
cp README.md output/README.md
{
  printf 'Repository: %s\nCommit: %s\nRun: %s\n' "$GITHUB_REPOSITORY" "$GITHUB_SHA" "$GITHUB_RUN_ID"
  printf 'libopus=1.6.1 libopusenc=0.3 opus-tools=0.2 libogg=1.3.6 opusfile=0.12\n'
  "$CC" --version
  dpkg-query -W gcc-mingw-w64-x86-64 binutils-mingw-w64-x86-64
} > output/build-info.txt
x86_64-w64-mingw32-objdump -p output/opusenc.exe | sed -n '/DLL Name:/p' | tee output/dll-dependencies.txt
if grep -Ei 'DLL Name:.*(libgcc|libwinpthread|libssp|libopus|libogg)' output/dll-dependencies.txt; then
  echo 'Unexpected non-system DLL dependency' >&2
  exit 1
fi
