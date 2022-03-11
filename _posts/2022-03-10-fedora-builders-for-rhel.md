---
layout: post
title: Building RHEL on a subscribed Fedora cloud box
lang: en
---

Building RHEL on Fedora?
------------------------

Historically, this wasn't easy.  E.g. Fedora Koji—while building Fedora EPEL
packages against the official Red Hat Enterprise Linux (RHEL) packages—is used
to maintain their own "private" mirror of RHEL repositories.  This approach
though brings a great level of inconsistency between "how the official Fedora
EPEL is built," and how the contributors can actually "reproduce the build
locally." Contributors usually aren't able to mirror the RHEL content locally,
so they just build against a different (a fork) distribution (CentOS, Alma
Linux, Rocky Linux, ...).

Some time ago we added [support for Subscription Manager][mock-rhel-chroots] to
the [Mock tool][mock].  But not many EPEL contributors are aware of this, and
only [until recently][deployed-to-copr], this feature has not been used in any
"production" code.


The current Copr status and configuration
-----------------------------------------

The Copr builders are "cloud" machines, spawned from a VM image, kept working
for a while, and then destroyed.  Thus any Red Hat subscription needs to be
automatically taken, and automatically destroyed:

1. We use a very insistent [snippet][subscribe-script] for taking subscriptions.
   Yes, from time to time the attempt to subscribe or attach a subscription
   fails and we can not afford such a failure because a lot of time was already
   spent on starting the VM, and would be completely wasted.  This is also a
   reason why we don't use the [Ansible community general module][ansible-subscription]
   that turned out to be extremely unreliable from this perspective.

2. We also [try our best to unregister][unsubscribe-script] the VM before we
   delete it.

3. Because we start thousands of machines every day, we can not blindly rely on
   the flawlessness of step 2 (unregistering may fail, but also some small
   percentage of our builders die without letting us know what happened).
   Therefore we also install a [cron job][cron-job] (run
   [twice per hour][cron-install]) that automatically removes the leftover
   entitlements (automatically lists the remaining systems, and subscriptions
   for systems that appear to be already deleted are also deleted, using the
   [RHSM API][rhsm-api]).

When the system is registered (see step 1. above), Mock is able to lift up
the generated PEM certificates and properly work with the official RHEL
repositories hosted in Red Hat's CDN—as configured in the ``mock-core-configs``
package (see ``rpm -ql mock-core-configs | grep rhel``, and related
[docs][mock-rhel-chroots], we, in particular, rely on ``/etc/mock/rhel+epel-8*``
files for the `epel-8-x86_64` chroots).


Conclusion
----------

Copr is trying the best to be as close as possible to the end-user perspective,
doing mostly what the user would do with mock locally (this way we get the reports
that "something is broken" in Mock or Copr really fast).  And this small RHSM
step allowed us to make the EPEL builds in Koji, Copr, and local Mock builds
(even though [only optional][mock-pr]) much, much close to each other.  Till now
it seems to be working well!  Feel free to try ``mock -r rhel-8-x86_64``
yourself.


[mock]: https://rpm-software-management.github.io/mock/
[mock-rhel-chroots]: https://rpm-software-management.github.io/mock/Feature-rhelchroots
[deployed-to-copr]: https://lists.fedoraproject.org/archives/list/copr-devel@lists.fedorahosted.org/thread/6J2SADUV5SF5I63COQR5HBQNO64IBS2X/
[subscribe-script]: https://pagure.io/fedora-infra/ansible/blob/d731413fc51bfb79357b3fb62691d41a7da0c5b1/f/roles/copr/backend/files/provision/copr-rh-subscribe.sh#_79-83
[unsubscribe-script]: https://pagure.io/fedora-infra/ansible/blob/8b7f2dda0b1543423ff9d4850bf1717cf4d55412/f/roles/copr/backend/templates/resalloc/vm-delete.j2#_10-14
[ansible-subscription]: https://docs.ansible.com/ansible/latest/collections/community/general/redhat_subscription_module.html
[cron-job]: https://pagure.io/fedora-infra/ansible/blob/main/f/roles/copr/backend/templates/cleanup-unused-redhat-subscriptions
[cron-install]: https://pagure.io/fedora-infra/ansible/blob/8b7f2dda0b1543423ff9d4850bf1717cf4d55412/f/roles/copr/backend/tasks/main.yml#_373
[mock-pr]: https://github.com/rpm-software-management/mock/pull/817
[rhsm-api]: https://access.redhat.com/management/api/rhsm
