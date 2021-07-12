---
layout: post
title:  Feodora Copr farm of builders - status of July 2021
date:   2021-07-12 00:00:00 +0000
lang:   en
---

There's a little bit of history behind what we have now, so sorry for
rather a long post.  Please skip the article and go to "The current
status" paragraph if you just want to see the numbers.


The history
-----------

Initially we had some hardware and custom scripts for starting VMs there.

Then we had a Fedora-infra OpenStack cloud with x86\_64 and ppc64le
architecture support, those days it was living on fedorainfracloud.org
hostname.  [Mirek started][initial-openstack-commit] the OpenStack
installation in 2014.  That cloud was giving us several tens of instances
those days (concurrently about 10 ppc64le and 30 x86\_64, from what I
barely remember).

Unfortunately, the lab which hosted the cloud was planned for relocation,
and we had to evacuate OpenStack in 2020.  We were offered to host the
Copr build system in AWS under the Fedora Infrastructure community
account.  The migration started late in 2019 (when we began starting
builder VMs in AWS) and finished in [Feb 2020][aws-migration-outage] (when
the infrastructure, like frontend, backend, etc. was moved).

A big benefit of the move to AWS was that we newly got a native support
for the aarch64 architecture (only x86\_64 and aarch64 are available in
AWS).  But we lost the ppc64le architecture, as those OpenStack
hypervisors were shut down.  AWS also gave us possibility to scale
horizontally, so in peak situations we handled about 120 concurrent
builds.

The transition to AWS brought several approaches, namely we didn't have
the only source of computational power -- we had two (AWS and OpenStack,
at least for the transition period).  At that time we started using the
[Resalloc server][resalloc] for (pre)allocating VMs.

The use of Resalloc server is nicer for VM quota, we don't have to start
all the VMs in advance when they are not used.  The server keeps just some
of the VMs pre-allocated (so new builds don't wait till the VM is started)
and is able to allocate more when needed.

Later, `fedorainfracloud.org` OpenStack was [finally
discontinued][openstack-shutdown], and till now we don't have any
OpenStack in hand.

During the last few months, we Fedora Infra folks began racking the
machines from the old OpenStack cloud into a new RDU lab.  It allows us to
finally install them, and gives us an opportunity to grow again on those
"in-house" machines.  We already finished installation of four x86\_64
boxes (one died in the meantime and is waiting for HW service) and we
managed to start 20 builder VMs on each of those machines (so we have
additional 60 x86\_64 builders now).

The fact we have those builders now, we don't have to depend on that many
builders in AWS.  So first - we decreased the maximum numbers of AWS
builders and second - we also migrated the rest instances from On-demand
to [Spot][spot] (about 30% of On-Demand price).


The current status
------------------

- 60 x86\_64 builders preallocated (on 3 working, in-house, hypervisors)
- from 5 to 30 On-Demand x86\_64 AWS builders
- from 20 to 60 Spot x86\_64 AWS builders
- from 2 to 8 On-Demand aarch64 AWS builders (2 always preallocated)
- from 6 to 30 Spot aarc64 builders (6 always preallocated)

This gives us from 93 to 188 machines, depending on the current
utilization (the more machines is used, the more is started).


Future plans
------------

We should get two Power8 machines soon (one is already racked, one is
WIP).  By a rough guess, this should give us about 40 ppc64le builders (We
tweaked the thin-provisioning setup on the LibVirt level,
overcommitted RAM, so we get much more builder machines than before on
OpenStack).

One x86\_64 hypervisor should get HW vendor service.   We also believe
that we should handle another +10 builders more on each x86 hypervisor.
It means that there will be +30 (on the fixed box) and +3x10 x86\_64
builders (120 in-house in total) - so it will decrease the AWS budget a
bit more.

The current implementation of Resalloc server pre-allocates virtual
machines, and delegates the Copr build tasks there by random.  This is
though a economically sub-optimal process - we should instead primarily
use the in-house builders (the cheapest power), then Spot instances, and
only if all are taken - take the most expensive On-Demand instances.
We'll implement this prioritization soon.

We are currently discussing possibilities around the **s390x**
architecture, and also we have two **aarch64** boxes that could be racked
to do native **armhfp** builds.  So eventually, we could get a native
support for all the architectures supported by Fedora - even though this
is not yet certain/near future.


[initial-openstack-commit]: https://pagure.io/fedora-infra/ansible/c/cec386a0ffe7dc59100a4950ed4b4e2129e150d5
[aws-migration-outage]: https://pagure.io/fedora-infrastructure/issue/8668
[resalloc]: https://github.com/praiskup/resalloc
[openstack-shutdown]: https://pagure.io/fedora-infra/ansible/c/aa580f72c50bffc77cb3c32bcb5e6b96c815fbe3
[spot]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html
