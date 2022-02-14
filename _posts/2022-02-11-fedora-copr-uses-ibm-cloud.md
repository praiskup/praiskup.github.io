---
layout: post
title:  IBM Cloud and IBM Z machines in Fedora Copr
date:   2022-02-11 00:00:00 +0000
lang:   en
---

IBM Z machines in Fedora Copr
=============================

Late in May 2021, IBM LinuxONE experts contacted our team with the intentions to
have the native s390x architecture support in Fedora Copr — to be able to
process some of their Copr use-cases.  After the initial discussions, due to the
"cloud nature" of the Copr build system (and the need for short-lived VMs),
[IBM Cloud][ibm-cloud] was quickly chosen as the best fit.  Later that year
IBM folks managed to provide us an IBM Cloud account and sponsor
the s390x (Z13) compute power (for all Copr users), thank you!  The year 2021
was full of operational work in Copr so we managed to finalize this task in
[January 2022][announcement].

This post is technical, about how do we start Fedora builder machines in IBM
Cloud, and some initial problems we had (that you might face, too).


Spawning IBM Cloud machines
---------------------------

We use the IBM Cloud Python library/SDK to start/stop the machines.  For this,
[two][sdk-package] [new][cli-package] packages were added to Fedora, and a
[helper script][helper-script] (using the Python API) was invented.

The notation used in IBM Cloud is very similar to OpenStack or AWS.  One
peculiarity compared to the other clouds:  The new instances don't get a public
IP address automatically.  A Floating IP needs to be reserved explicitly and
then assigned to the instance (fortunately this can be done via
a [single API call][floating-api-call], even though not available in the Python
API).  The script is automatically [executed][resalloc-config]
[by Resalloc][resalloc-config-2].

The s390x architecture is only supported in **Tokyo** in IBM Cloud, locations
(`jp-tok-1`, `jp-tok-2` and `jp-tok-3`).  A bit far away from the rest of the
Copr infrastructure (hosted in North Carolina mostly), though things seem to
work pretty fine (the heavy network stuff goes through mirrored DNF
repositories).  We just need to get the package sources to the builder machine,
and later download the built results (usually small stuff, but beware if you
maintain a large package(s)!).


Working with the QCOW2 images in IBM Cloud
------------------------------------------

TL;DR, cloud-init-based, even the default Fedora `s390x` QCOW2 images work!

When preparing a custom image, one can spawn a fresh machine, modify it
accordingly (e.g. with Ansible) and then snapshot it.  This approach broke
subscription-manager, see below.

But fortunately, we observed we can run our guestfish scripting on
the `s390x` virtual machines (normally we need to run those scripts on a
bare-metal box).  Feel free to take a look at our related
[HOWTO document][generate-images].

The generated QCOW2 image file needs to be uploaded into the S3 bucket, and then
a new IBM Cloud "image" is created from that bucket.  Unfortunately, the
`ibmcloud-vpc` library lacks the support for this.  The web UI doesn't help much
either (even if you can afford to spend a few manual clicks), because there's
a "200 MB" [upload limit][upload-limit].

Therefore we use the official ([not yet open][ibmcloud-cli-request]) `ibmcloud`
utility.  To simplify our automation, we use this [image][s390x-image]
(note that this Podman image must be built on an s390x box **before** it is
uploaded to quay.io!).  Using that image, it is just a single command to upload
the locally generated QCOW2 file twist it into a new VM image.


Problems spotted
----------------

Several notable things before you start.

1. Fedora SSO has not been implemented so far, one needs to create
   the user+password access assigned to a concrete SIG's e-mail.

2. Occasionally the cloud leaks some resources.  We had to create two tickets so
   far to clean up some stuff, as we couldn't do it ourselves (4 images, and one
   instance).

3. The "OS type" category for Fedora 35 is missing.  One can upload a Fedora F35
   image (or even a Rawhide), but the metadata will claim it is Fedora 34 at
   best (you can pick RHEL).  I filled a ticket for this, but it is WONTFIX
   (adding a new OS type is not possible till at least one of the officially
   supported images is also of that OS type)

4. If you need subscription-manager, be careful with snapshots.  When a snapshot
   image is generated in IBM Cloud, some very weird, not-GPG-signed,
   katello-related package is installed automatically into the snapshot image.
   It breaks RHSM (at least on Fedora).  This problem is still to be reported.

5. Uploading images is not very straight-forward on Fedora.

Conclusion
----------

The s390x support in IBM Cloud, controlled via Python API (with some tweaks with
`/bin/ibmcloud`) seems pretty solid.  Things work fine for us, (mostly) since
the beginning.  We run from 6 up to 18 VMs there (s390x, z13) with 2xCPU,
4G RAM, and plenty of swap space.


[ibm-cloud]: https://cloud.ibm.com
[sdk-package]: https://src.fedoraproject.org/rpms/python-ibm-cloud-sdk-core
[cli-package]: https://src.fedoraproject.org/rpms/python-ibm-vpc
[helper-script]: https://pagure.io/fedora-infra/ansible/blob/ddd65268d5646c45f204dcebd749f69ba149ef74/f/roles/copr/backend/templates/resalloc/ibm-cloud-vm.j2
[floating-api-call]: https://pagure.io/fedora-infra/ansible/blob/ddd65268d5646c45f204dcebd749f69ba149ef74/f/roles/copr/backend/templates/resalloc/ibm-cloud-vm.j2#_85-108
[announcement]: https://lists.fedoraproject.org/archives/list/copr-devel@lists.fedorahosted.org/message/AR3ZDKET3EXZHV3MSU3UHMO7EIKBGAN2/
[resalloc-config]: https://pagure.io/fedora-infra/ansible/blob/ddd65268d5646c45f204dcebd749f69ba149ef74/f/roles/copr/backend/templates/resalloc/pools.yaml#_144-145
[resalloc-config-2]: https://pagure.io/fedora-infra/ansible/blob/ddd65268d5646c45f204dcebd749f69ba149ef74/f/roles/copr/backend/templates/resalloc/vm-delete.j2#_24-25
[generate-images]: https://docs.pagure.org/copr.copr/how_to_upgrade_builders.html#prepare-ibmcloud-source-images
[ibmcloud-cli-request]: https://github.com/IBM-Cloud/ibm-cloud-cli-release/issues/162
[s390x-image]: https://github.com/praiskup/ibmcloud-cli-fedora-container
[upload-limit]: https://cloud.ibm.com/docs/vpc?topic=vpc-managing-images#import-custom-image
