#! /bin/sh

set -e

info () { echo >&2 " * $*" ; }

info "running $0"

lfs_url=https://media.githubusercontent.com/media/praiskup/praiskup.github.io/master

lfs_dir=_lfs-images

all_images=$(cd "$lfs_dir" && find . -name '*.png' -printf '%P\n')

for file in $all_images
do
    dest="$(pwd)/assets/$file"
    dir=$(dirname "$dest")

    test -f "$dest" || {
        info "downloading $file from github's lfs"
        mkdir -p "$dir"
        curl -SLs "$lfs_url/$lfs_dir/$file" > "$dest"
    }
done
