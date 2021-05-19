#!/bin/sh -ex

netget () { if type wget >/dev/null 2>&1; then wget -nv -O - "$@"; else curl -L "$@"; fi }
tmp=$(mktemp -d)

netget 'https://www.adelielinux.org/download/' >"$tmp/index.html"
rootfs_url=$(grep -Eom 1 'https://distfiles\.adelielinux\.org/adelie/[^"]+/adelie-rootfs-mini-x86_64-[^"]+\.txz' "$tmp/index.html")
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
