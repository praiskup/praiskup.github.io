---
layout: post
title:  Submit Copr builds by GitHub “push” actions
date:   2020-08-05 00:00:00 +0000
draft:  true
lang:   en
---

Since [my last on-topic post][ci-cd-travis] (mostly about GitHub's
third-party CI provider [Travis CI][travis]) another alternative for submitting
RPM builds in Copr appeared on GitHub -- [GitHub Actions][actions-introduced].

Let's admit this fact now:  From our perspective, GitHub Actions do not
bring anything new into the game.  Namely, we have Turing-complete language
(good) and we still can not store **private tokens** (Copr API token, e.g.)
which could be [used securely at the pull-request time][github-problem] (bad,
especially for Open Source projects).

But, yes, at least we don't have to use a third-party application for
computational power, and the format of defining Actions (or “workflows”) is
(at least subjectively) simpler than before.


# Setup the CI for GitHub push events

First go to the GitHub project you maintain, and:

1. Go to *Settings* menu.
2. Go to *Actions* sub-menu.
3. Toggle the *Enable local and third party Actions for this repository* radio
   button option.  This is needed to successfully run external
   `actions/checkout@v1` action.
4. Go to *Secrets* menu, and provide a *New Secret* named `COPR_API_TOKEN`,
   filled by contents of the [Copr API page][copr-api] (login required).

Then go to the local clone of your project, and push an arbitrarily named
`*.yml` file into `.github/workflows/` directory;  with content similar to this
one:

{% highlight yaml %}
---
name: RPM build in Fedora Copr
on:
  # Build only on pushes into master branch.
  push:
    branches: [master]

jobs:
  build:
    name: Submit a build from Fedora container
    # Run in Fedora container on Ubuntu VM (no direct Fedora support)
    container: fedora:latest
    runs-on: ubuntu-latest

    steps:
      - name: Check out proper version of sources
        uses: actions/checkout@v1

      - name: Install API token for copr-cli
        env:
          API_TOKEN_CONTENT: $\{{ secrets.COPR_API_TOKEN }}
        run: |
          mkdir -p "$HOME/.config"
          echo "$API_TOKEN_CONTENT" > "$HOME/.config/copr"

      - name: Install tooling for source RPM build
        run: |
          dnf -y install @development-tools @rpm-development-tools
          dnf -y install copr-cli make

      - name: Build the source RPM
        run: cd rpm && make srpm

      - name: Submit the build by uploading the source RPM
        run: copr build praiskup/argparse-manpage-ci rpm/*.src.rpm
{% endhighlight %}

This is a simple example (or template) that needs a custom tweaks, namely
packages and commands needed to build source RPM.  But it is indeed
[enough in practice][deployment].

Having Actions as a 1:1 alternative for Travis CI, feel free to read the [old
post][ci-cd-travis].   You can implement the very same work-flow using Github
Actions (perhaps for pull-requests, too).  But this post provided a lot simpler,
a "starter", Actions example.

Happy building!


[ci-cd-travis]: copr-ci-and-custom-source-method.html
[travis]: https://travis-ci.org/
[github-problem]: https://github.community/t/make-secrets-available-to-builds-of-forks/16166/31
[actions-introduced]: https://github.blog/2018-10-17-action-demos/
[copr-api]: https://copr.fedorainfracloud.org/api/
[deployment]: https://github.com/praiskup/argparse-manpage/blob/master/.github/workflows/push-copr-build.yml
