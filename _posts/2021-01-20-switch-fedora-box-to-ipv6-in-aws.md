---
layout: post
title:  Migrating Fedora boxes in AWS to IPv6?
date:   2021-01-20 00:00:00 +0000
lang:   en
---

Staring at the [AWS IPv6 migration docs][aws-ipv6-migration] recently -- at the
time when we tried to move Copr build system to combined IPv4/IPv6 stack from
IPv4 -- I wasn't able to re-configure the pre-existing Fedora machines correctly
for automatic IPv6 stack configuration.  While there's **no problem with freshly
started Fedora Cloud VMs** (at the time of writing this article I work with
Fedora 33 where is `cloud-init-19.4-7.fc33.noarch`), I struggled to instruct
*cloud-init* to **re-configure** the existing IPv4-only network.

The only solution that worked for me was to use manual configuration.  This was
useful-workaround, at least till the old instances can be replaced with fresh
ones (when they'd be replaced with Fedora 34 or 35).

So eventually the only thing I had to do was to modify the network device
configuration file, like this:

{% highlight text %}
$ cat /etc/sysconfig/network-scripts/ifcfg-eth0
# Created by cloud-init on instance boot automatically, do not edit.
...

# Manually appended!
IPV6INIT=yes
IPV6_DEFROUTE=yes
IPV6_AUTOCONF=yes
IPV6ADDR=2600:1f18:8ee:ae00:f595:7aa7:3966:671d/128
{% endhighlight %}

Reboot of the box made the IPv4+IPv6 stack fully working.  Unfortunately,
there's still no [Elastic IP][aws-elastic-ips] support for IPv6 yet, so the
traffic still can not be arbitrarily redirected (brings you AAAA outages when
you are replacing VMs with newer ones).

[aws-ipv6-migration]: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-migrate-ipv6.html
[aws-elastic-ips]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html
