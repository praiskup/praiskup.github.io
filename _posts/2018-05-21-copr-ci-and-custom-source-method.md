---
layout: post
title:  CI/CD with Copr, finally for any project?
date:   2018-05-21 00:00:00 +0000
lang:   en
---

It's been some time since the only option to build RPM package in
Copr build-system was to upload (locally pre-built) source RPM.  There are now
[many different ways][ref-src-methods] to let Copr generate also the source RPM
-- e.g. directly from remote VCS repository.  In this post, I'd like to present
-- on one concrete CI deployment scenario -- the newest [Custom source
method][ref-custom-method] we've [managed to merge][ref-the-PR] into Copr
sources recently, which is now also available in [production Fedora
Copr][ref-copr].


## The Problem

Consider you want to build some RPM package for each change in
[upstream][ref-upstream-def] VCS repository, or consider you want to have an RPM
repository in hand which provides the bleeding edge (git) version of the RPM(s)
in question.  Copr build-system is the natural tool for such task nowadays,
but...  Also assume that the project development (of which you might or might
not be part of) is conservative enough to not accept changes specific to
Copr build-system.  It means you probably want to use the Custom source method.

In this post, I'll work with [GNU tar][ref-tar] project using Autoconf.  Mainly
because adding support for RPM oriented tools like
[tito][ref-tito] or [rpkg][ref-rpkg] into GNU package is unlikely, and `make
srpm` support would be kind of hack (autotooled projects have no Makefile until
`./configure` is executed).

I'll work with a repo hosted on GitHub repository, mostly because that's one of
the most popular git hostings nowadays, to reach a larger audience.  I'm
cheating a bit, you're right -- GNU projects wouldn't be hosted on proprietary
services like GitHub is -- but GitHub service gives us a bit more features to
present in this post compared to the official [Savannah repo][ref-savannah].
And the GitHub repo is cron-synchronized, so it doesn't make much difference.
Of course, if you can yourself administrate your server-side git hooks (I can't
do that on Savannah), you can live fine without GitHub and still stay focused
(we'll get to it).


## The Solution: packaging CI/CD with Copr

Quick overview:  **First** we'll create a script for building the SRPM
sources from (remote) git repo, **then** we'll setup a new Copr project `tar-ci`
and **define** new Copr package named `tar` inside which will be built by the
prepared script. **Last**, we'll setup the automatic rebuilds triggered by
upstream git repository changes.


### Script that generates the sources

This is the script I'll use for SRPM builds from [the repo][ref-myfork]:

{% highlight bash %}
$ cat ./get-tar-sources.sh
{% include_relative scripts/copr-get-tar-sources.sh %}
{% endhighlight %}

Note the optional part.  It's there to precisely pair particular git commits
with Copr builds -- otherwise there would be a risk that different (but fast
enough) git changes trigger more builds against the same git revision.  Since
there's quite a few things to think about to have this `Github <-> Copr`
communication implemented, I wrapped the logic into separate [copr-ci-tooling
project][ref-citools], and I'm just reusing it in the script.


### Setup the Copr project

Working `copr` command in `$PATH` is a pre-requisite:

1. `dnf install copr-cli` (or `pip install copr-cli`)
2. get the [Fedora account][ref-fedoraaccount], then
3. log in to [Fedora Copr][ref-copr]
4. obtain the `~/.config/copr` [token][ref-api-token]

Let's create the Copr project which will build RPM packages for Fedora Rawhide
and CentOS 7 distributions (`--chroot` options).  Make sure to have all the
dependencies for building sources installed (`--script-builddeps` option).
And spin-up the first build:

{% highlight terminal %}
$ copr create tar-ci --chroot fedora-rawhide-x86_64 --chroot epel-7-x86_64
New project was successfully created.

$ copr add-package-custom tar-ci --name tar \
    --script ./get-tar-sources.sh \
    --script-builddeps 'automake autoconf gettext-devel gcc make \
                        texinfo git rsync wget bison tar'
Create or edit operation was successful.

$ copr build-package tar-ci --name tar
Build was added to tar-ci.
Created builds: 755916
Watching build(s): (this may be safely interrupted)
  12:52:42 Build 755916: pending
  12:53:13 Build 755916: running
  13:18:36 Build 755916: succeeded

{% endhighlight %}

Since the build succeeded, apparently the `--script` works fine.  Now what
remains is to setup automatic builds.

### Enable Copr's Custom webhook

There's no `copr` API functionality for this [yet][ref-webhook-api], so for now:

- log into [copr webUI][ref-copr]
- find the newly created copr project (`praiskup/tar-ci` in my case)
- go to project `[Settings] => [webhooks]`
- remember or copy the `Custom webhook` URL, it will be needed soon..

### Option 1: Trigger the build by Travis CI

To make things work, you'll have to commit something similar to the following
`./.travis.yml` specification into _the_ [Travis enabled][ref-travis-start]
GitHub repository:

{% highlight yaml %}
language: c
git:
  submodules: false
script:
- |
  set -e
  test "$TRAVIS_EVENT_TYPE" = push || exit 0
  test -n "$COPR_PUSH_WEBHOOK"
  curl -o copr-build https://raw.githubusercontent.com/praiskup/copr-ci-tooling/master/copr-travis-submit
  exec bash copr-build
{% endhighlight %}

Finally, in the corresponding Travis project ([in my case this
one][ref-travis-project]) setup the `$COPR_PUSH_WEBHOOK` [secure
variable][ref-travis-sec] -- fill in the full URL address of the `Custom
webhook` above (replace `<PACKAGE_NAME>` appropriately).  **Double check** that
the `script:` from `.travis.yml` doesn't actually print out the secret URL so
it can not be seen in the public log output.

It's done!  Any subsequent _git push_ to the repository will automatically
trigger a new Copr build.  Of course, any Copr build failure will fail also the
corresponding Travis job which in turn means that I'm informed about that by
email (and in GitHub web-UI).


### Option 2: Use GitHub's webhook support

In your GitHub project page, go to `Settings -> Webhooks` and hit the `Add
Webhook` button.

1. fill in the `Payload URL` with the `Custom Webhook` url above
2. make sure to use `application/json` `Content Type`, otherwise Copr will
   refuse to handle the webhook calls

Slightly patched `./get-tar-sources.sh` script (above) is needed ...

{% highlight patch %}
- copr-travis-checkout "$resultdir"/hook_payload
+ github-checkout --hook-file "$resultdir"/hook_payload
{% endhighlight %}

... because GitHub's web-hook content has a different format than the
`copr-travis-submit` script.

You'll need to hit `copr edit-package-custom` (take the inspiration from the
`copr add-package-custom` above).  That's it.

This option doesn't allow us to see the nice green check-mark :heavy_check_mark:
for each git commit in the GitHub's web UI (nor it sends email notifications).
At least as long as we don't have better support for GitHub built in Copr you'd
have to live without that; but the nice **benefit is** that no external CI
service is required.

To get the build status notification, consider listening on the [fedmsg
bus][ref-fedmsg] where Copr is used to send the info about finished builds.

### Option 3: The git server-side hook

For the cases where GitHub is not an option, create `pre-receive` executable
script under your (bare) git repo directory, say `tar.git/hooks/pre-receive`.
You can use [example script][ref-pre-receive], e.g. like this (the
`$CUSTOM_WEBHOOK` variable needs to be set manually):

{% highlight shell %}
#! /bin/sh
export CUSTOM_WEBHOOK=<THE_CUSTOM_WEBHOOK_ABOVE>
exec bash copr-pre-receive-submit # download this!
{% endhighlight %}

.. but **for security** reason's don't download the `copr-pre-receive-submit`
script automatically :smirk: and precisely check that the script isn't doing
something nasty, _no warranty_!

Same as with Option 2, [fedmsg][ref-fedmsg] is necessary to get info about
finished builds.


What next?
----------

I managed to setup packaging continuous integration for [distgen][ref-distgen]
project, including the pull request CI (by that I mean that the GitHub's
pull-request is blocked if the automatic build in Copr is failing).  It's not
yet 100% bulletproof solution, but feel free to follow the `./.travis.yml` there
if you are curious.  There's ongoing discussion about better [GitHub/Copr
integration][ref-ghapps], so we could have a better way soon...  stay tuned.

[ref-src-methods]: https://docs.pagure.org/copr.copr/user_documentation.html#build-source-types
[ref-custom-method]: https://docs.pagure.org/copr.copr/custom_source_method.html
[ref-the-PR]: https://pagure.io/copr/copr/pull-request/185
[ref-copr]: https://copr.fedorainfracloud.org/
[ref-upstream-def]: https://fedoraproject.org/wiki/Staying_close_to_upstream_projects
[ref-distgen]: https://github.com/devexp-db/distgen.git
[ref-ghapps]: https://lists.fedorahosted.org/archives/list/copr-devel@lists.fedorahosted.org/thread/SD2LCGXMROREK4RQHFVLRLXAB6H5M7RQ/
[ref-tar]: https://www.gnu.org/software/tar/
[ref-citools]: https://github.com/praiskup/copr-ci-tooling
[ref-fedoraaccount]: https://admin.fedoraproject.org/accounts/user/new
[ref-api-token]: https://copr.fedorainfracloud.org/api/
[ref-travis-start]: https://docs.travis-ci.com/user/getting-started/#To-get-started-with-Travis-CI
[ref-webhook-api]: https://pagure.io/copr/copr/issue/229
[ref-savannah]: http://git.savannah.gnu.org/cgit/tar.git/?h=HEAD
[ref-travis-sec]: https://developer.github.com/webhooks/securing/
[ref-travis-project]: https://travis-ci.org/praiskup/tar
[ref-myfork]: https://github.com/praiskup/tar
[ref-pre-receive]: https://github.com/praiskup/copr-ci-tooling/blob/master/copr-pre-receive-submit
[ref-fedmsg]: http://www.fedmsg.com/en/stable/
[ref-tito]: https://github.com/dgoodwin/tito
[ref-rpkg]: https://pagure.io/rpkg-util
