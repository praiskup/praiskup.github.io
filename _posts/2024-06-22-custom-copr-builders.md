---
layout: post
title: "Need something extra? Employ your own Copr builders!"
date: 2024-06-22 00:00:00 +0000
lang: en
---

Each Copr deployment needs to [manage][resalloc] a farm of builders (normally
virtual machines) across various clouds, with various architectures and
performance profiles.

For example, in the [Fedora Copr instance][fedora-copr], where there is normally
a reasonable amount of `x86_64/amd64` builders, users very often wait for
`s390x/Z` builders.

The [recent Copr contribution][per-pkg-tags] has given us option to allocate
[high-performance builders][powerful] for specific build tasks.  And as a nice
side effect, it also opened the door to providing any other **custom workers**.
And, if you don't want to wait in the queue anymore, you can also have **workers
dedicated to your team**!

What's Needed?
--------------

Copr administrators should be able to configure a new pool(s) of VMs (builders)
for you, and then make *your builds* use them.

Of course, admins will need your permission to start the machines in your name.
There's already a built-in support for working with _IBM Cloud_, _OpenStack_,
_EC2_ or _LibVirt_ (so a cloud token is needed, or SSH access to hypervisor).
Support for other clouds could be added, too — we'd just need a bit more help
from you (scripting and golden-image preparation).

You need to make a budget decision.  Your builders can either be booted on
demand (which may delay the build processing by 2 or 3 minutes, but it
depends...) or use the VM pre-allocation mechanism (a few builders are booted in
advance, you pay the cloud costs for them, but they are pre-prepared to take
your tasks immediately).

Then one note (similar like with the _high-performance builders_).  For the
configured builds, your cloud account (and only that) will be used for virtual
machine allocation, and it probably isn't limitless.

Community Sponsors
------------------

_Resalloc_ also allows Copr admins to configure additional pools of workers for
the general public.  This can be beneficial for interesting use-cases (platform
enablement, specific hardware needs, AI-related builds, etc.), or even just to
boost the overall Copr throughput.  If you plan to help the community this way,
or you already do, THANK YOU very much!


What next?
----------

Please consult the options with us, either on the [copr-devel list][list], the
team e-mail `copr-team@redhat.com`, or [submit an issue][tracker].


[tracker]: https://github.com/fedora-copr/copr/issues/new
[list]: https://lists.fedorahosted.org/archives/list/copr-devel%40lists.fedorahosted.org/
[resalloc]: https://github.com/praiskup/resalloc
[per-pkg-tags]: https://github.com/fedora-copr/copr/commit/9e71174fca5bd18feee1ebc3959cf6f36c4b0c28
[fedora-copr]: https://copr.fedorainfracloud.org/
[powerful]: https://docs.pagure.org/copr.copr/user_documentation/powerful_builders.html
