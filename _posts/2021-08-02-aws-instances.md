---
layout: post
title:  AWS spot/on-demand Copr builders
date:   2021-08-02 00:00:00 +0000
lang:   en
---

AWS spot/on-demand Copr builders
================================

Most of the builders we use nowadays in AWS are started in the [spot
tenancy][spot].  The reason is simple - they are significantly cheaper, and it isn't a
big problem when some builder machine gets suddenly terminated (if that happened
we simply start a new VM that will re-try the build task).

We still keep also several complementary "on-demand" builders just in case there
was some spot request allocation outage.  Admittedly, this has not happened to us
so far - probably because we set the maximum spot price circa on the level of
the on-demand price, and our builders are usually run for a short period of time.


Pricing
-------

Currently, we use the `i3.large` instance type for x86\_64 builders, and
the `a1.xlarge` for the `aarch64`.  The `a1.xlarge` has insufficient storage, so
for those arm-based machines we allocate an additional 160G *gp2* volume, per [EBS
pricing][ebs-pricing]:

- 160G * $0.1 (per month) / 30 days / 24 hours = **$0.022**/h

Fedora Copr runs in N. Virginia region, so the [on-demand price][cost] is:

- **$0.156**/h for *i3.large*
- *$0.102*/h for *a1.xlarge* + *$0.022*/h for 160G volume = **$0.124**/h

How to check the spot pricing?  Log into the AWS web UI => go to "EC2" category
=> Open collapsible "Instances" menu on the left side => "Spot Requests" =>
press "Pricing history" in the right top corner => search the instance types,
see the history of spot price.

- *$0.0468*/h for *i3.large*, about **70% savings**
- *$0.0336*/h for *a1.xlarge* + *$0.022*/h for the volume (nothing changes
  here) = *$0.0556*/h, that is **45% savings**

Despite the fact that most of the demand goes to x86 architecture, we have about
50:50 x86 vs. arm ratio in AWS.  That's because we have our own in-house
x86 hypervisors that provide additional power.


How do we start them?
---------------------

We need to have a flexible builder allocation mechanism, depending on the
current usage.  And we want to have always some machines preallocated, so when
users come they don't have to wait till the VMs are booted (2-3 minutes).  We
use the [resalloc server][resalloc] for the VM allocation, where a script is
called to [start][start-script], [stop][stop-script] and [check][check-script]
the virtual machine.

The [starting script][start-script] is just a thin wrapper around a [set
of][playbook-1] [our][playbook-2] ["configuration"][playbook-3]
[playbooks][playbook-4], those include the crucial spawning [task
file][task-file].  There are related [configuration][config] [files][config-2]
in the inventory.


Caveats
-------

Because some AWS subnet (lab) locations may be temporarily unavailable (outage)
we [randomly pick][choosing-subnet] from a predefined set of subnets;  So when
this happens Resalloc just stops and re-tries the allocation in a different
location.

The good thing on this Ansible approach is that we can "declaratively" describe
the machine to be started, and it usually "just works".  The bad thing is that
the starting process isn't 100% under our control, and sometimes the playbook
fails while the resource stays in some intermediate (but still running, and thus
charged) state in AWS.  So, we have also a [cron job][cron] doing periodic
cleanups.

The 'spot\_price' argument can not be set to `null` or a float number easily (as
specified by `ansible-doc ec2`) with the Jinja2 templating in Ansible.
Therefore we use ["" or "float" strings][strings] (fortunately it works as we
expect).

[ebs-pricing]: https://aws.amazon.com/ebs/pricing/
[cost]: https://instances.vantage.sh/
[resalloc]: https://github.com/praiskup/resalloc/blob/main/config/pools.yaml
[start-script]: https://pagure.io/fedora-infra/ansible/blob/25dd4678194c08228ed96c977b402892c402343b//f/roles/copr/backend/templates/resalloc/vm-aws-new
[stop-script]: https://pagure.io/fedora-infra/ansible/blob/25dd4678194c08228ed96c977b402892c402343b//f/roles/copr/backend/templates/resalloc/vm-aws-delete
[check-script]: https://pagure.io/fedora-infra/ansible/blob/25dd4678194c08228ed96c977b402892c402343b//f/roles/copr/backend/templates/resalloc/vm-check
[playbook-1]: https://pagure.io/fedora-infra/ansible/blob/25dd4678194c08228ed96c977b402892c402343b//f/roles/copr/backend/files/provision/builderpb-aws-x86_64.yml
[playbook-2]: https://pagure.io/fedora-infra/ansible/blob/25dd4678194c08228ed96c977b402892c402343b//f/roles/copr/backend/files/provision/builderpb-aws-aarch64.yml
[playbook-3]: https://pagure.io/fedora-infra/ansible/blob/25dd4678194c08228ed96c977b402892c402343b//f/roles/copr/backend/files/provision/builderpb-aws-spot-x86_64.yml
[playbook-4]: https://pagure.io/fedora-infra/ansible/blob/25dd4678194c08228ed96c977b402892c402343b//f/roles/copr/backend/files/provision/builderpb-aws-spot-aarch64.yml
[task-file]: https://pagure.io/fedora-infra/ansible/blob/25dd4678194c08228ed96c977b402892c402343b//f/roles/copr/backend/files/provision/spinup_aws_task.yml
[config]: https://pagure.io/fedora-infra/ansible/blob/25dd4678194c08228ed96c977b402892c402343b/f/inventory/group_vars/copr_aws#_56-62
[config-2]: https://pagure.io/fedora-infra/ansible/blob/25dd4678194c08228ed96c977b402892c402343b/f/roles/copr/backend/templates/provision/aws_cloud_vars.yml
[choosing-subnet]: https://pagure.io/fedora-infra/ansible/blob/25dd4678194c08228ed96c977b402892c402343b/f/roles/copr/backend/files/provision/spinup_aws_task.yml#_6
[cron]: https://pagure.io/fedora-infra/ansible/blob/25dd4678194c08228ed96c977b402892c402343b/f/roles/copr/backend/files/cleanup-vms-aws-resalloc
[strings]: https://pagure.io/fedora-infra/ansible/blob/25dd4678194c08228ed96c977b402892c402343b/f/roles/copr/backend/files/provision/spinup_aws_task.yml#_28
[spot]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html
