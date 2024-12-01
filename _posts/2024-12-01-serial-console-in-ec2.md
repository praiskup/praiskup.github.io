---
layout: post
title: Access to serial console in EC2
date: 2024-12-01 00:00:00 +0000
lang: en
---

Even in the cloud, it is sometimes convenient to monitor systemd logs via the
[serial console][sc] (or even log into the machine) when services like `sshd`
fail or disks fail to mount.  With EC2, you can use SSH for this purpose.

Get the instance ID
-------------------

Either go to the console (web-ui) and get the instance ID there, or just ssh to
the machine and query the [Metadata Service][ms]:

    $ ssh <user>@<host>
    $ TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    $ curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id ; echo
    i-015xxxxxxxxxxxxxx
    $ exit

Access the serial console
-------------------------

On your machine, setup a few environment variables:

    $ instance_id=i-015xxxxxxxxxxxxxx
    $ pubkey=/home/praiskup/.ssh/id_rsa.pub
    $ region=us-east-1

Tell EC2 what SSH key you want to use first, and then ssh to the console:

    $ aws ec2-instance-connect send-serial-console-ssh-public-key \
        --instance-id "$instance_id" \
        --serial-port 0 \
        --ssh-public-key file://"$pubkey" \
        --region "$region"
    -----------------------------------------------------
    |           SendSerialConsoleSSHPublicKey           |
    +----------------------------------------+----------+
    |                RequestId               | Success  |
    +----------------------------------------+----------+
    |  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  |  True    |
    +----------------------------------------+----------+

    $ ssh "$instance_id".port0@serial-console.ec2-instance-connect."$region".aws
    copr-fe-dev login: 

Work with the console over SSH
------------------------------

Use the neat SSH control keys, start with `~?`, quit the session with `~.`:

    copr-fe-dev login: ~?
    Supported escape sequences:
     ~.   - terminate connection (and any multiplexed sessions)
     ~B   - send a BREAK to the remote system
     ~R   - request rekey
     ~V/v - decrease/increase verbosity (LogLevel)
     ~^Z  - suspend ssh
     ~#   - list forwarded connections
     ~&   - background ssh (when waiting for connections to terminate)
     ~?   - this message
     ~~   - send the escape character by typing it twice
    (Note that escapes are only recognized immediately after newline.)

Watch the systemd logs over SSH:

    [root@copr-fe-dev ~][STG]# reboot 
             Stopping session-160.scope - Session 160 of User root...
             Stopping session-49.scope - Session 49 of User root...
    [  OK  ] Removed slice system-modprobe.slice - Slice /system/modprobe.
    [  OK  ] Removed slice system-sshd\x2dkeygen.slice - Slice /system/sshd-keygen.
    [  OK  ] Removed slice system-systemd\x2dzr…- Slice /system/systemd-zram-setup.
    ...

<!--
Prolong grub2 timeout
---------------------

    $ vim /etc/default/grub                 # change the $GRUB_TIMEOUT
    $ cp /boot/grub2/grub.cfg /var/tmp/     # backup
    $ grub2-mkconfig > /boot/grub2/grub.cfg # re-generate
    $ vim -d /boot/grub2/grub.cfg /var/tmp/grub.cfg  # review!
-->

[sc]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/troubleshoot-using-serial-console.html
[ms]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
