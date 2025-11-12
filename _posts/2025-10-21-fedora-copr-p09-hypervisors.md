---
layout: post
title: Disk partitioning on Fedora Copr Power9 machines
lang: en
---

{% include note.html content="
Never directly copy-paste commands from this guide, always think twice
the action you do to avoid <b>DATA LOSS</b>.
" %}

Fedora Infrastructure / Red Hat IT folks recently racked three POWER9 servers
for Fedora Copr.  Thank you!  I'm going to quickly recap the steps I took to
make them (almost) work.

This is a (somewhat easier, this time) follow-up to [my previous action of that
kind][previous].


## Getting Machines Installed

With Kevin (Fedora Infra), we made a few installation attempts via
the [kickstart][] he prepared.

1. The first attempt was with a single large RAID10.  The machine was booting
   fine, but that layout would likely be slow for both (a) libvirt disks and (b)
   SWAP.  We need **striping** for both.

2. Instead of doing the very slow manual re-creation work like
   [previously][previous], we decided to reinstall the machine with a modified
   kickstart—without `--growfs` and keeping the `/` partition small.  I then
   manually created striped **SWAP** and **RAID0** for `/libvirt-images`.  This
   initially worked fine, and we even started building RPMs on those machines.
   However, the machine did not survive a reboot (for newly added clevis &
   tang).  We noticed:

   ```plaintext
   mdadm: failed to add /dev/sde5 to /dev/md/3_0: Invalid argument
   ```

   We thought that the manually created RAIDs on Fedora 43 had broken the
   **Petitboot** bootloader.  Hence...

3. We reinstalled for the 3rd time, with all the RAIDs created by Anaconda
   kickstart (that attempt seemed reasonable, because the other MDs also created
   by Anaconda were just working fine).  Well, even now the machine failed to
   boot, with the very same error.

Yeah, so neither manually created MDs nor the Anaconda installation could make
the **Petitboot** bootloader happy with our five MDs use-case.


Debugging
---------

When I switched to the **Petitboot** command-line shell and re-scanned the MDs
(failing the mdadm command), things became a bit more normal.  At least `/boot`
and the root filesystem (`/`) on the RAID arrays started working!

<details>
<summary>Here is the full <strong>mdadm --assemble --scan</strong> error output.</summary>

{% highlight bash %}
mdadm: /dev/md/unused-249:1 has been started with 8 drives.
mdadm: /dev/md/unused-249:0 has been started with 8 drives.
mdadm: /dev/md/unused-249:2 has been started with 8 drives.
mdadm: failed to add /dev/sdb3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sdc3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sdd3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sde3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sdf3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sdg3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sdh3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sda3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to RUN_ARRAY /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sdb2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sdc2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sdd2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sde2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sdf2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sdg2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sdh2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sda2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to RUN_ARRAY /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sdb3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sdc3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sdd3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sde3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sdf3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sdg3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sdh3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sda3 to /dev/md/unused-249:3: Invalid argument
mdadm: failed to RUN_ARRAY /dev/md/unused-249:3: Invalid argument
mdadm: failed to add /dev/sdb2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sdc2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sdd2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sde2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sdf2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sdg2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sdh2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to add /dev/sda2 to /dev/md/unused-249:4: Invalid argument
mdadm: failed to RUN_ARRAY /dev/md/unused-249:4: Invalid argument
{% endhighlight %}
</details>
<br/>
Kevin also observed these weird disk errors:

    fdisk: device has more than 2^32 sectors, can't use all of them

Anyway, after a manual post-start `--assemble --scan` manually, and I got the
most important MDs working so the machine could boot.  At least something!


Planning the fix
----------------

The error we **saw** seemed to be related to some **32-bit limit**.  What if we
**re-created** the non-working RAIDs once more, manually, directly inside
Petitboot's shell?  I **believed** that MDs created in Petitboot would later be
readable by **Petitboot**..

On the booted machine:

<details>
<summary>[root@unused-249 ~]# lsblk /dev/sdh</summary>
{% highlight bash %}
[root@unused-249 ~]# lsblk /dev/sdh
NAME                                            MAJ:MIN RM   SIZE RO TYPE   MOUNTPOINTS
sdh                                               8:112  0   3.6T  0 disk
├─sdh1                                            8:113  0     8M  0 part
├─sdh2                                            8:114  0     3T  0 part
│ └─md4                                           9:4    0    24T  0 raid0
│   └─luks-bd506244-b18a-4ea8-9af1-15db95c63d7d 252:2    0    24T  0 crypt  /vmvolumes
├─sdh3                                            8:115  0    64G  0 part
│ └─md3                                           9:3    0 511.5G  0 raid0
│   └─luks-3d68312d-7c05-42d2-86b9-be636676d5bf 252:0    0 511.5G  0 crypt
├─sdh4                                            8:116  0    32G  0 part
│ └─md2                                           9:2    0 127.9G  0 raid10
│   └─luks-fde52936-8c89-479d-9d70-cede214f7314 252:1    0 127.9G  0 crypt  /
├─sdh5                                            8:117  0  1000M  0 part
│ └─md0                                           9:0    0   999M  0 raid1  /boot
└─sdh6                                            8:118  0   500M  0 part
  └─md1                                           9:1    0 499.9M  0 raid1  /boot/efi
{% endhighlight %}
</details>

<br>
Ok, we'll recreate `md3` and `md4`, i.e. everything on `sd*2` and `sd*3`.


Cleanup first
-------------

Stop swap:

    swapoff -a

Comment-out things from `/etc/fstab`, `/etc/crypttab` and `/etc/mdadm.conf`
appropriately.  All the stuff related to `md{3,4}`!  Then:

    umount /vmvolumes

    cryptsetup close luks-bd506244-b18a-4ea8-9af1-15db95c63d7d
    cryptsetup close luks-3d68312d-7c05-42d2-86b9-be636676d5bf

    mdadm --stop md3
    mdadm --stop md4

    mdadm --zero-superblock /dev/sd*2
    mdadm --zero-superblock /dev/sd*3


**Reboot to Petitboot**!

Back in Petitboot shell
----------------------

    # mdadm --create /dev/md3 /dev/sd*2 --level=0 --raid-devices=8
    # mdadm --create /dev/md4 /dev/sd*3 --level=0 --raid-devices=8

Reboot once more, and... **voilà**, even though we have five MDs
(boot/efi/vmvolumes/swap/root), **the machine boots**, and Petitboot is happy!

So let's re-configure `mdadm.conf` to cover the two new `md3` and `md4`:

    [root@vmhost-p09-copr03 ~][PROD-RDU3]# cat /etc/mdadm.conf
    # mdadm.conf written out by anaconda
    MAILADDR root
    ARRAY /dev/md0 metadata=1.2 UUID=aaaaaaaa:bbbbbbbb:cccccccc:dddddddd
    ARRAY /dev/md1 metadata=1.0 UUID=bbbbbbbb:cccccccc:dddddddd:aaaaaaaa
    ARRAY /dev/md2 metadata=1.2 UUID=aaaaaaaa:bbbbbbbb:cccccccc:dddddddd
    ARRAY /dev/md3 metadata=1.2 UUID=bbbbbbbb:cccccccc:dddddddd:aaaaaaaa
    ARRAY /dev/md4 metadata=1.2 UUID=aaaaaaaa:bbbbbbbb:cccccccc:dddddddd

Encrypt SWAP with a random key:

    cryptsetup open --type plain /dev/md4 swap_crypt --key-file /dev/urandom

Setup automatic decryption of SWAP:

    # echo swap_crypt   UUID=$(mdadm --detail --scan | grep md/4 | sed 's/.*UUID=//') /dev/urandom  swap,plain,cipher=aes-xts-plain64,size=256 >> /etc/crypttab

Create the SWAP:

    mkswap /dev/mapper/swap_crypt
    echo /dev/mapper/swap_crypt   none    swap    sw      0       0 >> /etc/fstab
    swapon -a

Create auto-decryption for the `/libvirt-images` (note we don't mount, that's
done by [copr-hypervisor playbook][]).

    dd if=/dev/urandom of=/root/libvirt-luks-images.key bs=4096 count=1
    cryptsetup luksFormat /dev/md3 /root/libvirt-luks-images.key
    cryptsetup luksOpen /dev/md3 vmimages_crypt --key-file /root/libvirt-luks-images.key
    mkfs.ext4 -L vmvolumes /dev/mapper/vmimages_crypt
    chmod 0600 /root/libvirt-luks-images.key
    echo vmimages_crypt  UUID=$(mdadm --detail --scan | grep md/3 | sed 's/.*UUID=//') /root/libvirt-luks-images.key  luks >> /etc/crypttab

Backup old grub config!  And then fix it (all MDs but efi mentioned?).

    echo $(for i in $(mdadm --detail --scan | sort | grep -e md/4 -e md/3 | sed 's/.*UUID=//'); do echo rd.md.uuid=$i; done)
    rd.md.uuid=48a41879:9301e678:bf629bf1:b05eb5ae rd.md.uuid=1e0bd440:a22ea797:fef650fd:5df66d17
    grubby --update-kernel=ALL --args 'rd.md.uuid=663b53dc:bab1869d:84e94f2a:7fee5168 rd.luks.uuid=luks-1483fbff-398d-49bf-8a6b-e16e839c261a rd.md.uuid=06df0fa7:0a1ac337:18840fd9:96e5f9e5 net.ifnames=0 console=ttyS1,115200'

Rebuild initramfs:

    dracut -f

Uh!  UUIDs don't work reliably in `/etc/crypttab`, but since we fixed
intitramfs, it is OK to use symbolic `/dev/mdX` references:

    vmimages_crypt /dev/md3 /root/libvirt-luks-images.key luks
    swap_crypt /dev/md4 /dev/urandom swap,plain,cipher=aes-xts-plain64,size=256

Reboot, and enjoy!  Now, let's fix the [ipv6 issues][], but that's a different
story.



[kickstart]: https://pagure.io/fedora-infra/ansible/blob/main/f/roles/kickstarts/templates/hardware-fedora-ppc64le-08disk.j2
[previous]: https://pavel.raiskup.cz/blog/fedora-copr-hypervisor-disk-repartitioning.html
[copr-hypervisor playbook]: https://pagure.io/fedora-infra/ansible/blob/c447162152f0b6c5a2a28ec08aae6618c0f160f7/f/roles/copr/hypervisor/tasks/main.yml#_65-68
[ipv6 issues]: https://pagure.io/fedora-infra/ansible/blob/c447162152f0b6c5a2a28ec08aae6618c0f160f7/f/roles/copr/hypervisor/tasks/main.yml#_65-68
