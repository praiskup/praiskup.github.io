---
layout: post
title:  SHA-1 package signatures distrusted on RHEL 9
date:   2022-07-18 00:00:00 +0000
lang:   en
---

Red Hat Enterprise Linux 9 [deprecated SHA-1][sha1kb] for security reasons for
package signing.  However, it is still used by many for signing packages.  I
will discuss typical problems users may face (and ways around), Fedora status
and how you can alter your infrastructure to use a more secure SHA-256.


## Users struggle

While the default security policy might refuse SHA-1 all over the system, the
problem we discuss today looks like:

    # dnf install package-name -y
    Dependencies resolved.
    =============================================================
     Package   Arch   Version   Repository                  Size
    =============================================================
    Installing:
     package-name x86_64 1-1.el9
                                repoName                    3.0 k

    Transaction Summary
    =============================================================
    Install  1 Package

    Total size: 3.0 k
    Installed size: 21
    Downloading Packages:
    [SKIPPED] package-name-1-1.el9.x86_64.rpm: Already downloaded
    warning: Signature not supported. Hash algorithm SHA1 not available.
    Problem opening package package-name-1-1.el9.x86_64.rpm
    The downloaded packages were saved in cache until the next successful transaction.
    You can remove cached packages by executing 'dnf clean packages'.
    Error: GPG check FAILED

Per the warning/error above, DNF on RHEL 9 refuses to install the package.  The
reason is that RPM is unable to validate the SHA-1 signature.

For the record, preparations for this change started even on RHEL 8.  You can
experiment with similar setup even on RHEL 8 system, just try:

    # update-crypto-policies --set FUTURE


## Why are packages signed by SHA1 in 2022?

The official packages for RHEL and Fedora distributions are signed with SHA256
for a very long time (all supported versions).

The problem might though be with third-party packages.  SHA1 is the default hash
algorithm for `rpmsign` on Enterprise Linux 7.  Also, the default hash algorithm
in [OBS signd is still SHA1][obs-defaults].  So many third-party package
providers still unconsciously use deprecated signatures.


## Any problems on RHEL 8 and older?

The packaging stack on Enterprise Linux 8 (and older) accepts SHA1 signatures
without complaints.  Potential troubles can occur when doing in-place upgrades
to the RHEL 9 system, even though Red Hat upgrade tool LEAPP should at least
[issue a warning][kb-leapp] in advance.


## State of Fedora SHA1 deprecation

In this case, Enterprise Linux has been moved earlier than Fedora.  At the time
of RHEL 9 release, the latest released Fedora version was 36, and actually (at
the time of writing this post) switching fedora is
[planned for Fedora 39][fedora-change] (about +18 months after the RHEL 9
release).  Still, if you want to experiment with such a setup on Fedora there
exists a special policy (Fedora 36+):

    # update-crypto-policies --set TEST-FEDORA39
    Setting system policy to TEST-FEDORA39
    Note: System-wide crypto policies are applied on application start-up.
    It is recommended to restart the system for the change of policies
    to fully take place.

The expected failure can then be tested with:

    # curl https://copr-be.cloud.fedoraproject.org/archive/2022-07-18-blogpost-sha1/test.repo > /etc/yum.repos.d/test.repo
    # dnf install dummy-pkg
    ...
    Importing GPG key 0xFCFBE669:
    ...
    Key imported successfully
    Import of key(s) didn't help, wrong key(s)?
    Problem opening package dummy-pkg-20220622_1500-1.el7.x86_64.rpm. Failing package is: dummy-pkg-20220622_1500-1.el7.x86_64
     GPG Keys are configured as: https://copr-be.cloud.fedoraproject.org/archive/2022-07-18-blogpost-sha1/pubkey.gpg
    The downloaded packages were saved in cache until the next successful transaction.
    You can remove cached packages by executing 'dnf clean packages'.
    Error: GPG check FAILED


## How to sign packages?

Third party package providers should switch to `SHA256`.  With `rpmsign`, one
can edit the `%__gpg_sign_cmd` macro (copied from `/usr/lib/rpm/macros`) and add
`--digest-algo sha256 ` option explicitly, e.g. in `~/.rpmmacros`:

    %__gpg_sign_cmd                 %{__gpg} \
            gpg --batch --no-verbose --no-armor --passphrase-fd 3 \
            %{?_gpg_digest_algo:--digest-algo %{_gpg_digest_algo}} \
            --no-secmem-warning --digest-algo sha256 \
            -u "%{_gpg_name}" -sbo %{__signature_filename} %{__plaintext_filename}

For more info take a look at [signing KB article][kb-signing].  With OBS signd,
there's `sign -h sha256` [option][obs-sign-man].


## I still want to install SHA1 signed package!

This is discouraged.  Even a signature from a years old RPM could be hacked
recently by an attacker.  If you **really** know what you are doing, there's a
possibility to use `dnf --nogpgcheck` option.

Alternatively you can also switch to the legacy policy:

    update-crypto-policies --set LEGACY

Or explicitly allow the SHA1:

    update-crypto-policies --set DEFAULT:SHA1

But please don't forget to switch back, e.g.:

    update-crypto-policies --set DEFAULT


[sha1kb]: https://access.redhat.com/articles/6846411
[obs-defaults]: https://github.com/openSUSE/obs-sign/issues/34
[kb-leapp]: https://access.redhat.com/solutions/6868611
[kb-signing]: https://access.redhat.com/articles/3359321
[fedora-change]: https://fedoraproject.org/wiki/Changes/StrongCryptoSettings3
[obs-sign-man]: https://github.com/openSUSE/obs-sign/blob/e738925441fd69ae5f374b306736459c02c883c1/sign.8#L158-L159
