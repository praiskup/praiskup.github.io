#! /bin/sh -x

set -e
resultdir=$PWD
git clone https://github.com/praiskup/tar.git --depth 1
cd tar

# optional part; drop if building against 'master' is enough
if test -z "$REVISION"; then
    # the hook_payload file contains webhook JSON payload (copr creates it for
    # us); it is created only if the build is triggered by Custom webhook.
    if test -f "$resultdir"/hook_payload; then
        git clone https://github.com/praiskup/copr-ci-tooling \
            "$resultdir/cct" --depth 1
        export PATH="$resultdir/cct:$PATH"
        # use 'github-checkout' here instead for the 'GitHub's webhook support'
        copr-travis-checkout "$resultdir"/hook_payload
    fi
else
    git checkout "$REVISION"
fi

./bootstrap && ./configure && make dist-xz
tarball=$(echo tar-*.tar.xz)
version=${tarball%%.tar.xz}
version=${version##tar-}

# download Fedora's spec file and do some fixes
curl https://src.fedoraproject.org/rpms/tar/raw/master/f/tar.spec \
    | grep -v Patch | grep -v ^Source1: \
    | sed "s/^Version: .*/Version: $version/" \
    | sed "s/^Release: .*/Release: $(date +"%Y%m%d_%H%M%S")/" \
    > "$resultdir"/tar.spec

mv "$tarball" "$resultdir"
