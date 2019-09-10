---
layout: post
title:  Copr code ported to fedora-messaging
date:   2019-09-10 00:00:00 +0000
lang:   en
---

What happened?
==============

For reliability reasons, [Fedora infrastructure is moving][to-fm] from
ZeroMQ based [fedmsg][fedmsg] to AMQP based [fedora-messaging][fm].
In [Copr project][copr] we went through the transition as well and copr backend
now communicates with the new bus directly (for the transition period, there's
`fedmsg <==> fedora-messaging` proxy).

The new bus policies required us to provide [schemas][schemas] for copr
messages, so those are now provided in `python3-copr-messaging` package.


How to consume now?
===================

The easiest way is to install `python3-copr-messaging` package, and use
`fedora-messaging` tool from command-line:

```
$ fedora-messaging --conf /etc/fedora-messaging/fedora.toml \
    consume --routing-key '#.copr.#'
...
Copr Message in project "@copr/copr-dev": build 1031266: chroot "fedora-29-ppc64le" ended as "succeeded".
Copr Message in project "decathorpe/elementary-nightly": build 1031275: chroot "fedora-30-x86_64" started.
...
```

But usually one needs a better filtering capabilities, or somehow react on the
messages.  That is fairly easy now:

```python
#! /usr/bin/python3

from copr_messaging import fedora

class Consumer(fedora.Consumer):
    def build_chroot_ended(self, message):
        if message.project_full_name != 'praiskup/ping':
            return
        if message.chroot != "fedora-rawhide-x86_64":
            return
        # do something useful here...
        toogle_ci_tooling('praiskup/ping')

    def build_chroot_started(self, message):
        pass
```

Note that the message object automatically carries the full type information, so
you can enjoy the schema capabilities in your code (e.g. the property
`project_full_name`).  And what is more important -- the schema provides the
message API -- so once you use that, your code will continue to work even if we
eventually changed the plain text json message format in future.

Notice!  At the time of writing this blog post, users still can listen on fedmsg
(as [Mirek blogged about it][old-blog]) because there's the
fedmsg-to-fedora-messaging proxy, but everyone should make sure to move soon.

[to-fm]: https://communityblog.fedoraproject.org/moving-from-fedmsg-to-fedora-messaging/
[fedmsg]: https://github.com/fedora-infra/fedmsg
[fm]: https://github.com/fedora-infra/fedora-messaging
[copr]: https://pagure.io/copr/copr
[old-blog]: http://miroslav.suchy.cz/blog/archives/2014/03/21/how_to_get_notification_about_your_builds_in_copr/index.html
[schemas]: https://pagure.io/copr/copr/blob/master/f/messaging
