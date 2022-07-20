---
layout: post
title:  SHA-1 package signatures distrusted on RHEL 9
date:   2022-07-18 00:00:00 +0000
lang:   en
---

Red Hat Enterprise Linux 9 [deprecated SHA-1 for signing][sha1kb] for security
reasons.  However, it is still used by many for signing packages.  I will
discuss typical problems users may face (and ways around), Fedora SHA-1 status
and how you can alter your infrastructure to use a more secure SHA-256.


## Infra mistakes → user struggles

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

Per the warning/error above, DNF on RHEL 9 refuses to install the package.  DNF
is told to check signatures (DNF configuration `gpgcheck=1`) but the package
signature hash algorithm is SHA-1.  RPM is forbidden to even check it, on
system-level crypto layer.

## Can this happen on RHEL 8 or older?

No, at least not by default.  The packaging stack on Enterprise Linux 8 (and
older) accepts SHA-1 signatures without complaints.  Potential problems can
occur during in-place upgrades from RHEL 8 to the RHEL 9 system.  Please pay
attention to the [warnings issued by LEAPP][kb-leapp].

Preparation for this crypto policy change though started on RHEL 8.  Hence if
you want to experiment even on RHEL 8, you can bring the configuration from the
future RHEL by:

    # update-crypto-policies --set FUTURE


## Why are packages signed by SHA-1 in 2022?

The official packages for RHEL and Fedora distributions are signed with SHA-256
for a very long time (all the currently supported distribution versions).

The problem is with third-party packages.  SHA-1 is the default hash algorithm
for the `rpmsign` utility on Enterprise Linux 7.  Also, the default hash
algorithm in [OBS signd is still SHA-1][obs-defaults].  So many third-party
package providers might still unconsciously use SHA-1 signatures.


## State of Fedora SHA-1 deprecation

In this case, Enterprise Linux has been moved forward earlier than Fedora.  At
the time of RHEL 9 release, the latest released Fedora version was 36, and
actually (at the time of writing this post) switching Fedora policy is
[planned for Fedora 39][fedora-change] (about +18 months after the RHEL 9
release).  Still, if you want to experiment with such a setup on Fedora, there
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


## How am I supposed to sign packages, then?

Please switch to SHA-256 (or SHA-512).  With the `rpmsign` utility, one option
is to move he signing host to a newer distro than RHEL 7.

One can also modify the `%__gpg_sign_cmd` macro (copy-pasted from the
`/usr/lib/rpm/macros` file) so it contains the `--digest-algo sha256 ` option.
Can be done in the `~/.rpmmacros` file:

    %__gpg_sign_cmd                 %{__gpg} \
            gpg --batch --no-verbose --no-armor --passphrase-fd 3 \
            %{?_gpg_digest_algo:--digest-algo %{_gpg_digest_algo}} \
            --no-secmem-warning \
            --digest-algo sha256 \
            -u "%{_gpg_name}" -sbo %{__signature_filename} %{__plaintext_filename}

For more info take a look at [signing KB article][kb-signing].  With OBS signd,
there's `sign -h sha256` [option][obs-sign-man].


## I still want to install SHA-1 signed package!

This is discouraged.  Even a signature from a years old RPM could be hacked
recently by an attacker.  If you **really** know what you are doing, there's a
possibility to use `dnf --nogpgcheck` option.

Alternatively you can also switch to the legacy crypto policy:

    update-crypto-policies --set LEGACY

Or explicitly allow the SHA-1:

    update-crypto-policies --set DEFAULT:SHA1

But please don't forget to switch back, e.g.:

    update-crypto-policies --set DEFAULT


## Next steps

You know how to install SHA-1 signed packages (when really necessary and you
understand the security consequences).  But please don't forget to report to
your software provider that the SHA-1 problem exists!

From the other side, administrators, please fix your infrastructure.  Make the
SW distribution chain fluent again.  Then forget about this post.

[sha1kb]: https://access.redhat.com/articles/6846411
[obs-defaults]: https://github.com/openSUSE/obs-sign/issues/34
[kb-leapp]: https://access.redhat.com/solutions/6868611
[kb-signing]: https://access.redhat.com/articles/3359321
[fedora-change]: https://fedoraproject.org/wiki/Changes/StrongCryptoSettings3
[obs-sign-man]: https://github.com/openSUSE/obs-sign/blob/e738925441fd69ae5f374b306736459c02c883c1/sign.8#L158-L159
