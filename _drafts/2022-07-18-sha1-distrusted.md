---
layout: post
title:  SHA-1 package signatures distrusted on RHEL 9
date:   2022-07-18 00:00:00 +0000
lang:   en
---

For security reasons, the SHA1 algorithm has been
[deprecated for signatures][sha1kb] in Red Hat Enterprise Linux.  But even on
RHEL 8 you can experiment with the configuration from RHEL 9, by using the
`FUTURE` security policy:

    $ update-crypto-policies --set FUTURE

While that configuration will be refusing SHA-1 all over the system, the problem
we'll discuss today looks like this:

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

Per warning warning and error above, DNF refuses to install the SHA-1 signed
package.


## State of Fedora SHA1 deprecation

In this case, Enterprise Linux has been moved earlier than Fedora.  At the time
of RHEL 9 release, the latest released Fedora version was 36, and (at the time
of writing this post) the plan to do similar switch is
[planned for Fedora 39][fedora-change] (about +18 months after the RHEL 9
release).  Still, if you can or want to experiment with such a setup:

    # update-crypto-policies --set TEST-FEDORA39
    Setting system policy to TEST-FEDORA39
    Note: System-wide crypto policies are applied on application start-up.
    It is recommended to restart the system for the change of policies
    to fully take place.

Can be tested e.g. with:

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


## Why are packages signed by SHA1 in 2022?

The official packages for RHEL and Fedora distributions are signed with SHA256
for a very long time (all supported versions).

The problem might though be with third-party packages.  SHA1 is the default hash
algorithm for `rpmsign` on Enterprise Linux 7.  Also, the default hashalgo
in [OBS signd is SHA1][obs-defaults].  So third-party package providers might
unconsciously use deprecated signatures.


# Any problems on RHEL 8 and older?

The packaging stack on Enterprise Linux 8 and older accepts SHA1 signatures
without complaints.  Potential troubles can occur while in-place upgrading
systems to RHEL 9, but the Red Hat upgrade tool LEAPP should at least
[issue a warning][kb-leapp] in advance.


## How to sign packages?

Third party package providers should switch to `SHA256`.  With `rpmsign`, one
can edit the `%__gpg_sign_cmd` macro and add `--digest-algo sha256 ` explicitly
in `~/.rpmmacros`, e.g.:

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

But you But please don't forget to switch back, e.g.:

    update-crypto-policies --set DEFAULT


[sha1kb]: https://access.redhat.com/articles/6846411
[obs-defaults]: https://github.com/openSUSE/obs-sign/issues/34
[kb-leapp]: https://access.redhat.com/solutions/6868611
[kb-signing]: https://access.redhat.com/articles/3359321
[fedora-change]: https://fedoraproject.org/wiki/Changes/StrongCryptoSettings3
[obs-sign-man]: https://github.com/openSUSE/obs-sign/blob/e738925441fd69ae5f374b306736459c02c883c1/sign.8#L158-L159
