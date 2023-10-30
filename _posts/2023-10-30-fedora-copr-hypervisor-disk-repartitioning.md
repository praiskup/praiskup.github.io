---
layout: post
title: Re-partition Fedora Copr Hypervisors
lang: en
---

{% include note.html content="
Never directly copy-paste commands from this guide, always think twice
the action you do to avoid <b>DATA LOSS</b>.
" %}

This post documents our experience from the recent administrative work with
Fedora Copr, during which we had to [re-partition the volume layout on a set of
machines](https://github.com/fedora-copr/copr/issues/2869).  It can serve as a
reference in the future when working with `LVM` setups on non-trivial `mdadm`
arrays.


The problem
-----------

The Fedora [Copr][copr] hypervisors are relatively old machines, hosted in the
Fedora Infrastructure lab.  They were originally used as Koji builders, then
repurposed for OpenStack cloud nodes, and finally, repurposed for Fedora Copr.
It's possible that the disks on these machines are aging, or perhaps there have
been recent changes in the structure of Copr build tasks.  Regardless, there was
a significant slowdown some time ago.

The disks were so slow that everything took ages.  In extreme situations, [the
disk would hang][infra issue], causing **every process that accessed the
disks**, either on the hypervisor host or in the VM, to end up in an
[uninterruptible state 'D'][]. This even included the LibVirt daemon process,
which, in turn, meant that even the administrator couldn't recover from this
situation (when I cannot remove the I/O intensive virtual machine, I cannot make
things better…).  **SSHD was still running** on the hypervisor; however, any new
**attempt to establish a new connection touched the disk and failed** (for
example, `/bin/bash` binary needs to be loaded from the disk, but it couldn't).
The only way out of this situation was a cold reboot.

Actually, not only was SSHD itself running, but the **established SSH
connections** to VMs on the hypervisor were still seemingly working (processing
SSH keep-alive packets doesn't touch the disk, so it kept the controlling
connection alive).  But whatever action over the SSH connection hanged,
obviously.  This [tricked our processes miserably](https://github.com/fedora-copr/copr/issues/2888).

The root problem was the disk layout.  Despite having 8 (10 in some cases) SAS
disks, they were all part of a `raid6` (`raid5` in one case) software RAID, and
**everything** was stored on that array (including the `/` volume, the host's
SWAP volume, guest disks and SWAP volumes, etc.).  The Copr builders use the
[Mock tmpfs feature][mock tmpfs], and some extreme builds expectedly use SWAP
extensively.  Under pressure, RAID redundancy simply overloaded the disk,
eventually causing it to hang (deadlock?).  Isn't this possibly a bug in the
RAID kernel code?  On Copr Backend and `raid10`, the default periodic RAID
checks used to hang our systems similarly (lowering `dev.raid.speed_limit_max`
helped us to work around that).

So, we tried multiple reboots…  The solution?  Changing the disk layout.
Unfortunately, we had no physical access to the lab, and remote reinstallation
was unlikely possible (at least for some of those machines without a working
console).  There was no chance to hot-plug additional storage to offload `/`
"somewhere."  However, thanks to LVM and the `raid6` redundancy, we were able to
"online" re-partition the layout so that (a) the `/` is now moved to its own
(different and smaller) `raid6` and (b) everything else is uniformly "striped"
over all the disks to maximize parallel I/O throughput.


The old disk layout
-------------------

We used to have this (multiply the `lsblk` output by 8 or 10, as all the
physical disks used to have the same layout):

```plaintext
sdj                      8:144  0 446.6G  0 disk
└─sdj3                   8:147  0 445.2G  0 part
  └─md127                9:127  0   3.5T  0 raid6
    ├─vg_guests-root   253:0    0  37.3G  0 lvm   /
    ├─vg_guests-swap   253:1    0   300G  0 lvm   [SWAP]
    └─vg_guests-images 253:2    0   3.2T  0 lvm   /libvirt-images
```

Note the `md127` was `raid6`.  Guest swaps were created as sparse files in
`/libvirt-images`.  SWAP was on the same `md127`.  Fortunately, `lvm` was used,
as detailed below.

Please also note that I intentionally filtered out the boot-related `raid1`
partitions. These remain unchanged in this post (yes, `raid1` spread across 8+
disks, resulting in high redundancy, but that's the only small point of interest
here).

The new layout
--------------

We iterated to this (see below how).  Again multiply by 8 or 10:

```plaintext
sdj                      8:144  0 446.6G  0 disk
├─sdj3                   8:147  0    40G  0 part  [SWAP]
├─sdj4                   8:148  0    15G  0 part
│ └─md13                 9:13   0   105G  0 raid6
│   └─vg_server-root   253:0    0  37.3G  0 lvm   /
└─sdj5                   8:149  0 390.1G  0 part
  └─md0                  9:0    0   3.8T  0 raid0
    └─vg_guests-images 253:1    0   1.9T  0 lvm   /libvirt-images
```

Here, `/` stays on `raid6` as it deserves disk redundancy to keep the machine
bootable upon a disk failure.  However, note that it is on a different
`vg_server` volume group.  The SWAP is spread across separate 40G partitions
(8 or 10 of them).  Please note that when "mounted" (with `swapon`) with the
same priority, the kernel can [stripe swap][kernel raid].  And everything else
is on an independent, striped `raid0`!


## How We Did This

The trick is in the RAID redundancy (there are some spare disks to use) and the
possibility to migrate Volume Groups (VGs) across Physical Volumes (PVs).

1. **Don't reboot until the end.**

2. **Stop all the VMs on the machine.**

3. **Backup data on the being destroyed filesystem.**

   ```
   $ cp /libvirt-images/copr-builder-x86_64-20230608_112008 /dev/shm/
   ```

   *Warning: This is not a real backup.*

4. **Drop the large filesystem and swap.**

   ```
   $ umount /libvirt-images
   $ swapoff -a

   # Keep the root LV!
   lvremove /dev/vg_guests/images
   lvremove /dev/vg_guests/swap
   ```

5. **For the case of accidental reboot, comment out stuff in `/etc/fstab`.**

   ```plaintext
   $ cat /etc/fstab
   ...
   # LABEL=swap none swap sw 0 0
   # LABEL=vmvolumes /libvirt-images ext4 defaults 0 0
   ```

6. **Rename the VG from `vg_guests` to `vg_server`, and LV to a self-describing name.**

   ```
   vgrename vg_guests vg_server
   lvrename /dev/vg_server/LogVol00 /dev/vg_server/root
   ```

7. **Fix `fstab`.**

   ```plaintext
   $ cat /etc/fstab
   ...
   /dev/mapper/vg_server-root  / ext4    defaults  1 1
   ```

8. **Cut out one of the disks from the `raid6` (we choose the last one).**

   We need to a) fail the disk and b) then remove it from the array.

   ```
   $ mdadm /dev/md127 -f /dev/sdh3
   $ mdadm /dev/md127 -r /dev/sdh3
   ```

   Check `/proc/mdstat`, the array is still consistent.

9. **Don't let the kernel think the volume is part of RAID.**

   ```
   $ mdadm --zero-superblock /dev/sdh3
   ```

10. **Partition the disk.**

    We used `cfdisk`. Dropped the 3rd partition and later created the 3rd partition again as a `40G` partition, the 4th partition as 15G (for `/` `raid6`), and the rest for `raid0` on the 5th. Something like:

    ```plaintext
    sdh                      8:112  0 446.6G  0 disk
    ...skip boot partitions...
    ├─sdh3                   8:115  0    40G  0 part
    ├─sdh4                   8:116  0    15G  0 part
    └─sdh5                   8:117  0 390.1G  0 part
    ```

    If you have to use extended partitions, an additional `sdh` partition with 1K size is expected in `lsblk` output.

    You might need to run `partprobe`.

    On one of the Power8 machines with multipath ON, I had to run `multipath -r`.

11. **Move the VG onto the new partition.**

    **Warning:** No `/` redundancy now.  We could afford risking this, you might not.  Think twice.

    ```
    $ vgextend vg_server /dev/sdh5  # does pvcreate in the background
    $ pvmove -i 10 /dev/md127       # print status every 10s
    ```

    This magically evacuates our `raid6` volume, and then since unused, allows us to repartition the rest of the physical disks.

12. **Partition the other 7 (or 9) disks the same way as in step 10.**

13. **Create `raid6` for `/`.**

    Well, let's increase the possible disk failure by a single hot-spare.

    ```
    $ mdadm --create --name=server --verbose /dev/md/server --level=6 --raid-devices=9 --spare-devices=1 /dev/sd{a,b,c,d,e,f,g,h,i,j}4
    ```

    Might be a good idea to wait until `/proc/mdstat` reports the array is synced.

14. **Move the data to the new `raid6` above:**

    ```
    $ vgextend vg_server /dev/md/server
    Physical volume "/dev/md/server" successfully created.
    Volume group "vg_server" successfully extended.
    $ pvmove -i 10 /dev/sdh5
    ```

15. **Drop the volume from VG:**

    ```
    $ vgreduce vg_server /dev/sdh6
    ```

16. **Create a RAID-0 disk volume group and a new VG on it:**

    ```
    $ mdadm --create --name=guests --verbose /dev/md/guests --level=0 --raid-devices=10 /dev/sd{a,b,c,d,e,f,g,h,i,j}5
    $ vgcreate vg_guests /dev/md/guests
    ```

17. **Create a logical volume and `/libvirt-images`:**

    ```
    $ lvcreate -n images -l 50%FREE vg_guests
    $ mkfs.ext4 /dev/mapper/vg_guests-images -L vmvolumes
    $ edit fstab  # Uncomment the commented-out /libvirt-images mountpoint.
    $ mount /libvirt-images/  # Likely already auto-mounted by systemd.
    ```

18. **Create SWAP partitions:**

    ```
    x=0; for i in /dev/sd{a,b,c,d,e,f,g,h,i,j}3; do x=$(( x + 1 )); mkswap -L swap-$(printf "%02d\n" "$x") $i; done
    ```

    Adjust `fstab` with:

    ```
    LABEL=swap-01 none swap sw,pri=2 0 0
    LABEL=swap-02 none swap sw,pri=2 0 0
    ...
    LABEL=swap-10 none swap sw,pri=2 0 0
    ```

    And "mount" the swap with:

    ```
    $ swapon -a
    ```

19. **Fix LibVirt:**

    ```
    $ cp /dev/shm/copr-builder-x86_64-20230608_112008 /libvirt-images/  # "backup" restore
    $ restorecon -RvF /libvirt-images/
    ```

    Note that we had to migrate the golden image from QCOW2 to RAW format, as the new layout does not support QCOW2 format (drastic slowdown after the move from `raid6` to `raid0`, initially scared me a lot!).

    ```
    $ qemu-img convert -O raw copr-builder-ppc64le-20230608_110920 image.raw
    $ cp --sparse=always image.raw copr-builder-ppc64le-20230608_110920
    cp: overwrite 'copr-builder-ppc64le-20230608_110920'? yes
    ```

    Try to start some VMs.

20. **Fixing mdadm config:**

    Actually, I'm not sure this is needed. Kernel boot process seems to auto-assemble the arrays, but it's not good to keep the config file inconsistent.

    ```
    $ mdadm --detail --scan
    ...
    ARRAY /dev/md/server metadata=1.2 name=server UUID=ecd6ef8f:d946eedc:72ba0726:d9287d44
    ARRAY /dev/md/guests metadata=1.2 name=guests UUID=9558e2e0:779d8a1b:87630417:e57d7b91
    ```

    These lines must be in `/etc/mdadm.conf`, so drop the old, non-existing entries.


21. **Fix GRUB:**

    Note that we moved the `/` volume from one MD to another.  This required
    changing the kernel cmdline (NB I managed to cause headaches on one of the
    hypervisors by omitting this step 😖).

    We also removed the non-existing `resume=/dev/mapper/vg_guests-swap` swap
    partition.  We can't hibernate now, but we never needed or tried anyway.

    We updated the `rd.md.uuid` hosting the `/` volume.

    There's the `grubby` utility that helps with this task:

    ```
    $ grubby --update-kernel=ALL --args 'root=/dev/mapper/vg_server-root ro crashkernel=auto rd.md.uuid=9c39034c:d618eca6:c7f4f9e7:d05ec5d4 rd.lvm.lv=vg_server/root rd.md.uuid=79366fc3:a8df5fb4:caba2898:5c8bd9d2'
    ```

    Note that I had a lot of [fun with GRUB2][grub2] and I had to play with
    `grub2-mkconfig` on a few of the hypervisors, too.  Not sure why.  Make sure
    you double-check the `/boot/grub2/grubenv` config is correct, the same as
    `/etc/default/grub` or `/etc/sysconfig/grub`, etc.  Perhaps some
    modifications are needed (you really risk losing your remote box).

22. **Double-check:**

    Double check GRUB config again. Double check `/etc/fstab`.

23. **Reboot and enjoy!**

[copr]: https://docs.pagure.org/copr.copr/index.html
[uninterruptible state 'D']: https://en.wikipedia.org/wiki/Sleep_(system_call)
[infra issue]: https://pagure.io/fedora-infrastructure/issue/11476
[mock tmpfs]: https://rpm-software-management.github.io/mock/Plugin-Tmpfs
[kernel raid]: https://raid.wiki.kernel.org/index.php/Why_RAID%3F
[grub2]: https://fedoraproject.org/wiki/GRUB_2
