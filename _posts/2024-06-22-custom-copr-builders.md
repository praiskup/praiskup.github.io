---
layout: post
title: "Need something extra? Employ your own Copr builders!"
date: 2024-06-22 00:00:00 +0000
lang: en
---

In Copr, we deploy the [Resalloc server][resalloc] to manage our farm of
builders.  The _Copr_ build system (specifically the _copr-backend_ package)
acts as the "client," creating tickets with _Resalloc_ and requesting specific
kinds of worker virtual machines ("resources") for particular build tasks.
To do this, _Copr_ uses a known set of per-ticket tags to describe particular
needs (e.g., `--tag arch_x86_64`, `--tag powerful`, and so on).

_Resalloc's_ task is to match the _client's_ ticket tags with pre-allocated VMs
(or allocate new VMs if needed).

A [recent contribution][per-pkg-tags] has enabled Copr administrators to request
high-performance builders for specific build tasks.  And as a nice side effect,
it also opened the door to providing any other **custom workers**.  More
importantly for you, if you don't want to wait in the queue anymore, you can now
have **workers dedicated to your team**!


What's Needed?
--------------

Copr administrators should be able to configure a specific _Resalloc_ pool of
VMs (builders) for you and make *your builds* use them.  Of course, they'll need
your permission to start the machines in your name (_IBM Cloud_ or _EC2_ token
needed, SSH key granting access to your VM hypervisor machine, or
similar).

Your builders can either be booted on demand (which may delay the build
processing by 2 or 3 minutes, but it depends...) or use VM pre-allocation (a few
builders are booted in advance, you pay the cloud costs for them, but they are
ready to take your tasks immediately).

Community Sponsors
------------------

_Resalloc_ also allows Copr admins to configure additional pools of workers for
the general public.  This can be beneficial for custom use-cases (platform
enablement, specific hardware needs, AI-related builds, etc.), or even just to
boost the overall Copr throughput.  Thank you in advance!

What next?
----------

You are welcome to talk to us, either on the [copr-devel list][list], the team
e-mail `copr-team@redhat.com`, or [submit an issue][tracker].


[tracker]: https://github.com/fedora-copr/copr/issues/new
[list]: https://lists.fedorahosted.org/archives/list/copr-devel%40lists.fedorahosted.org/
[resalloc]: https://github.com/praiskup/resalloc
[per-pkg-tags]: https://github.com/fedora-copr/copr/commit/9e71174fca5bd18feee1ebc3959cf6f36c4b0c28
[fedora-copr]: https://copr.fedorainfracloud.org/
