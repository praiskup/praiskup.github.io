---
layout: post
title:  Fedora Copr builders - September 2025
date:   2025-09-05 00:00:00 +0000
lang:   en
---

It's been more than four years since [my last post][last time] like this.

A few changes have happened since then, so let me do a quick recap.


Changes in last 4 years, a.k.a. "News"
--------------------------------------

Namely, Fedora Copr now provides native build support for all supported Fedora
architectures: **aarch64**, **ppc64le**, **s390x**, and **x86_64**.  This means
we no longer have to emulate any architecture using `qemu-user-static`.  It's
faster, and more reliable.

Some package builds are known to be especially demanding, so we've created a way
to request [high-performance workers][high-perf].

Although it's not news (it's over three years old), IBM has started sponsoring
the **s390x** architecture through a community account in IBM Cloud.  Since
then, we've managed to bump and reorganize our quota a few times, and we also
have high-performance **s390x** workers.  Thank you, IBM!

A more recent development is the [ppc64le high-performance][ppc64le hp] profile
support, thanks to [OSUOSL][osuosl].  By the way, OSUOSL is our only source of
Power10 machines right now.  Thank you, OSUOSL!

Since 2022 we've started using [Red Hat-subscribed Fedora builders][rhelchroots]
to allow users to build against the official Red Hat Enterprise Linux content.
Since then, we've booted and subscribed millions of ephemeral Fedora VMs.  Thank
you, Red Hat.

Mirek has become one of the main administrators for the Fedora community EC2
account.  He's also started moving our EC2 machines from spot/on-demand to
reserved instances, which allows for more cost-effective planning.  EC2 machines
handle a large portion of **x86_64** builds and all of the **aarch64** builds,
and EC2 also sponsors other parts of Fedora Copr infrastructure.  Thank you,
Amazon AWS team!  Mirek is also paying close attention to accounting for
resources in Fedora community account and [cleaning up unused things
there][xsuchy scripts].  Thank you, Mirek.

The Current Status
------------------

The number of machines has [roughly doubled][pools] since the last time:

![Screenshot from Pools page showing we start 400+ VMs](/images/2025-09-05-copr-farm/Screenshot_20250905_135901.png)

Thanks to a few optimizations, our throughput has more than doubled—Fedora Copr
can now handle tens of thousands of Mock builds daily:

![Chart describing that we even build 40k+ Mock builds daily](/images/2025-09-05-copr-farm/Screenshot_20250905_135503.png)


We currently have machines dedicated to the following architectures:

* **aarch64**
    * 37 EC2 reserved machines
    * Up to 30 EC2 spot machines
    * Up to 8 EC2 on-demand machines

* **s390x**
    * Up to 18 IBM Cloud on-demand machines (across 6 locations in São Paulo and Madrid)
    * Up to 2 IBM Cloud high-performance machines

* **ppc64le**
    * Our own hardware:
        * 28 Power8 machines
        * 31 Power9 machines
    * OSUOSL machines:
        * Up to 15 standard machines
        * Up to 3 high-performance machines

* **x86_64**
    * 80 of our own machines, always running in the Fedora Lab
    * 46 EC2 reserved machines
    * Up to 70 EC2 spot machines
    * Up to 20 EC2 on-demand machines
    * Up to 20 powerful EC2 machines

In total, we have **235 machines running at all times** and the ability to **auto-scale up to 428 machines**.


Future Plans
------------

The Power8 machines are aging, and with the help of the Fedora Infrastructure
team, we plan on replacing them with newer [Power9 machines][p9ticket].

The number of workers we have is mostly sufficient for current load.  While we
would like to have more **s390x** machines, computational power is not the main
concern for the Fedora Copr team.  Our primary challenge is storage (our current
RAID deployment provides about **40TB**).  Another area of concern is the
computational power required on the [copr-backend][architecture] to keep the RPM
repository metadata up-to-date.  To address these, we plan to ["outsource" our
storage via PULP][pulp], which should offload these things to the
subject-matter-expert team—and allow us to concentrate on achieving an even
higher build throughput.

Additionally, we may want to [dedicate a separate VM for the Resalloc
machine][resalloc].  The process of machine allocation is quite demanding,
involving hundreds of shell and Python processes to control the machines being
started.


[last time]: https://pavel.raiskup.cz/blog/copr-farm-of-builders.html
[s390x post]: https://lists.fedorahosted.org/archives/list/copr-devel@lists.fedorahosted.org/message/AR3ZDKET3EXZHV3MSU3UHMO7EIKBGAN2/
[high-perf]: https://docs.pagure.org/copr.copr/user_documentation/powerful_builders.html#high-performance-builders
[ppc64le hp]: https://github.com/fedora-copr/copr/issues/3092
[osuosl]: https://osuosl.org/
[xsuchy scripts]: https://github.com/xsuchy/fedora-infra-scripts
[pools]: https://download.copr.fedorainfracloud.org/resalloc/pools
[p9ticket]: https://github.com/fedora-copr/copr/issues/3786
[pulp]: https://github.com/fedora-copr/copr/issues/2533
[architecture]: https://docs.pagure.org/copr.copr/developer_documentation/architecture.html
[resalloc]: https://github.com/fedora-copr/copr/issues/3864
[rhelchroots]: https://rpm-software-management.github.io/mock/Feature-rhelchroots.html
