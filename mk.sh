#!/bin/sh -ex

tmp=$(mktemp -d)
netget () { if type wget >/dev/null 2>&1; then wget -nv -O - "$@"; else curl -L "$@"; fi }

disturl='https://distfiles.adelielinux.org/adelie'
platform='rootfs-mini'
arch='x86_64'

netget 'https://www.adelielinux.org/download/' >"$tmp/index.html"
version="$(rg -m 1 -r '$1' ' +version = "([^"]+).*' "$tmp/index.html")"
release="$(rg -m 1 -r '$1' ' +release = "([^"]+).*' "$tmp/index.html")"

rootfs_url="${disturl}/${version}/iso/${release}/adelie-${platform}-${arch}-${version}-${release}.txz"

netget "$rootfs_url" >"$tmp/rootfs.txz"

img=quay.io/andykluger/adelie
ctnr="${img}-building"

buildah from --name "$ctnr" scratch
buildah add "$ctnr" "$tmp/rootfs.txz"
buildah run "$ctnr" apk upgrade

buildah run "$ctnr" sh -c 'rm -rf /var/cache/apk/*'

today=$(date +%Y.%j)
buildah tag "$(buildah commit -q --rm "$ctnr" "$img:$today")" "$img:latest"

rm -rf "$tmp"

if [ "$1" = --push ]; then
  podman push "$img:latest"
  podman push "$img:$today"
fi
