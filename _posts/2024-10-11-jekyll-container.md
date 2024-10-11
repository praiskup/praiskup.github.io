---
layout: post
title: Debugging Jekyll posts locally
date: 2024-10-11 00:00:00 +0000
lang: en
---

Just a quick post about a small side-project.  For a few years now, I've
been maintaining a [Jekyll Container image][repo].  Mostly for my own
convenience—whether I'm working on posts for this blog or writing
[documentation for Mock][mock docs] (or other).  I thought I’d share a few
words about it now.

Keep My Box Clean! (and DRY)
----------------------------

The motivation was simple: to be able to debug Jekyll/GitHub Pages posts
locally before pushing them to GitHub.  I wanted to do this consistently
across multiple pages, and I didn't want to repeat myself in the future
(following the DRY principle).

Back then, I realized that running Jekyll locally wasn't a trivial task—at
least not on Fedora, if, like me, you prefer staying on a "pure" Fedora
system (meaning you only install software distributed through Fedora
repositories).  Notably, installing the GitHub Pages additions from gems
[wasn't easy either][bug1], and [it still isn't][bug2] (as of autumn 2024).
Building your own container can also cause [some headaches][bughosting].

Jekyll made easy
----------------

So here we are—assuming you have a blog post or any documentation root
directory, you can run the Jekyll server in a container, and available on
[http://localhost:4000/](http://localhost:4000/), using just:

    $ jekyll-host ./your-jekyll-root
    Installing deps, may take several minutes
    =========================================
     Server listens on http://127.0.0.1:4000
     Jekyll Log: /tmp/jekyll-server.log (in container)
     Install logs: /tmp/bundler-install.log (in container)
    =========================================

The `jekyll-host` script (which must be in your `$PATH`) is just a [one-line
wrapper][wrapper] around a `podman run` command that uses a pre-built
container image hosted and built by [https://quay.io/](https://quay.io/).

I prefer to stay 100% focused on writing, not on the infrastructure.
After a quick chat with my colleagues, it seems this setup could be
helpful to others as well.  If that's the case, enjoy!

[repo]: https://github.com/praiskup/jekyll-container
[mock docs]: https://rpm-software-management.github.io/mock/
[bug1]: https://talk.jekyllrb.com/t/error-no-implicit-conversion-of-hash-into-integer/5890/5
[bug2]: https://stackoverflow.com/questions/75452016/installation-messed-up-with-ruby-unable-to-install-jekyll
[bughosting]: https://github.com/jekyll/jekyll/issues/8846
[wrapper]: https://github.com/praiskup/jekyll-container/blob/main/jekyll-host
