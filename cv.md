---
layout: page
title: Profile
permalink: /cv/
order: 1
comments: false
geometry: margin=3cm
---

# Pavel Raiskup

**Hacker, engineer, maintainer, designer, team leader, DevOps, CI/CD addict, DIY
person.**

I can appreciate perspective projects, good (SW) design, supportive automation,
ambitious folks, no obfuscation, and natural knowledge sharing.

Current role: Senior Software Engineer, team/tech lead for the Community
Packaging Tools team, Red Hat, Inc. (Brno office).


# Key interests

GNU/Linux, cloud tech, containers/microservices, system programming, software
compilation, integration and distribution, package maintenance, debugging and
bug-fixing.

Python, Shell, C, Ansible, and [others][languages].


# Languages

* English (professional working proficiency)
* Czech (native proficiency).


# Actual projects

**[Copr build system][copr]** (team lead, devel, admin).  Package build system
with users' project hosting, oriented on ease of use and continuous integration.
The team operates a public [instance][Fedora Copr] — 4 persistent
infrastructure VMs and up to ~250 concurrent, dynamically spawned VMs across
several clouds (AWS, OpenStack, IBM Cloud, on-premise hardware).  We host [>10
TB][stats] of data (SW packages, repositories, metadata, build logs).  We also
operate another Copr instance (Red Hat private).  Related [news][release-notes].

**[Mock (RPM build tool)][mock]** (main developer, maintainer).  Tool for
building RPMs in a reproducible environment.  Used by Copr.  Used also by
Koji build system thus used for building all the Fedora, CentOS, Red Hat
Enterprise Linux, etc. packages.

**[Resalloc][resalloc]** (author, maintainer).  A client/server resource
management and ticketing system.  Used to take care of the wide range of
dynamically spawned Copr builders (aka "resources").

**[DistGit][distgit]** (maintainer).  The place to (proxy-)store the RPM package
sources, so build-systems can use them reproducibly.  This is part of any Copr
deployment.

**[Fedora project][packages]** (package maintainer).  A [proven][proven]
packager, and Fedora tooling contributor.

**[RPM Packaging for Beginners][pkgworkshop]** (lector).  Periodic (3/year)
course/workshop for Red Hat colleagues who start with RPM packaging.

Smaller projects/worth noting:

- [**dnf diff**][dnf-plugin-diff], author, simple plugin to print the changes in
  locally installed RPMs
- [**argparse-manpage**][argparse-manpage], developer, tool for automatic
  building manual pages from Python default argument parser.
- [**distgen**][distgen], author, a Linux distribution-oriented templating system.
- [**postgresql-setup**][pgsetup], previous maintainer, I decoupled that
  scripting from several places (packages, SCLs, ..) so it can be maintained in
  one place.
- one RPM building oriented patent pending

# Previous projects

[Red Hat Enterprise Linux][rhel] package maintainer.  I originally started
(Y2012) with a small set of archivers (tar, cpio, pax, star, ncompress).  Later
I started maintaining Autotools (autoconf, automake, libtool).  Later, when
I moved to the databases team I took care of the PostgreSQL stack (its library
bindings and plugins).  I was also involved in database-related [Software
Collection][scls] development, and I also authored the PostgreSQL module (aka
opt-in, alternative package version streams for PostgreSQL).

Red Hat [container image][sclimages] developer.  I contributed to CI/CD, build
tooling, and several container images.  I was responsible for a [PostgreSQL
container][postgresql-container] (development, design, automatic upgrades).

I originally started in Red Hat as an intern (and later continued as an associate)
in a code scanning project ([some][csdiff] public [parts][csmock]), where I
basically analyzed the output from several static analyzers (Coverity, LLVM,
ShellCheck, PyLint), reported back to Red Hat maintainers and contributed with
fixes upstream.  Provided fixes for the analysis tooling.

I several times helped with the Red Hat Brno office hiring events, Open House
(mostly by working on the [Bug Hunting][bughunting] sessions).

# Courses or certifications

Red Hat Certified Engineer, Red Hat SELinux, Red Hat Virtualisation, Ansible,
Red Hat OpenShift maintenance.

# Links

* [Personal (technical) blog](https://pavel.raiskup.cz/blog/)
* [GitHub activities](https://github.com/praiskup)
* [Pagure.io activities](https://pagure.io/user/praiskup)
* [Fedora Packages](https://src.fedoraproject.org/user/praiskup)
* [LinkedIn profile](https://www.linkedin.com/in/pavel-raiskup)
* [Open Hub monitoring](https://www.openhub.net/accounts/praiskup)
* [Fedora Badges received](https://badges.fedoraproject.org/user/praiskup)
* [GitLab](https://gitlab.com/praiskup)


# Work history

*Apr 2019 — present*, **Senior Software Engineer**, team leader, Red Hat, Inc.
Completely moved to Copr team, later named Community Packaging Tools team.
Giving up *most* of the package maintenance responsibilities and concentrating on
Copr development.  Became the Mock maintainer (mock is the underlying, low-level
tool used by Copr).  Still maintaining several packages in Fedora, to stay up to
date with trends and to understand what package maintainers need.  Improving the
packaging/automation/CI experience,  Becoming involved in [Packit][packit] a bit.

*Feb 2017 — Mar 2019*, **Senior Software Engineer**, Red Hat, Inc. Brno office.
Continued with the package maintenance, with the focus on PostgreSQL stack,
Autotools, archiving, compressing.  DevOps for the Red Hat private Copr stack,
service becomes internally popular, supported, installed on dedicated hardware.

*Oct 2013 — Jan 2017*, **Software Engineer**, Red Hat, Inc., Brno.  Continued
with the workload - but moved to the databases team, and continuously starting
maintenance of the databases-related stuff, mainly the PostgreSQL stack.
Software Collections.  As a side/hobby project I deployed the Red Hat private
Copr service.

*Feb 2012 – Sep 2013*, **Associate Software Engineer**, Red Hat, Inc.
Full-timer since Sep 2012, after graduation.  Got more archivers, some
compressors, started maintaining Autotools suite (all Fedora and Red Hat
Enterprise Linux).

*Jul 2011 – Jan 2012*, Red Hat **Intern**, Brno.  Part of a static analysis
team.  Later started with Fedora/RHEL package maintenance (archivers like tar,
cpio, etc.).  Proposing patches to upstream communities.


Education
=========

*Sep 2010 – Jul 2012*, Master's degree, [BUT FIT][BUT FIT], Intelligent
Systems.  Thesis: Improvement of live variable analysis using points-to analysis
(I contributed to a GCC-based static analysis project [Predator][Predator], by
the implementation of Flow-Intensive Context-Sensitive algorithm, FIPS).

*2nd half of 2010*, one semester Erasmus, [University of Eastern Finland,
Joensuu][uef], IT field.

*Sep 2007 – Jul 2010*, Bachelor's degree, [BUT FIT][BUT FIT].  Thesis: Extension
of FTP Implementation within libcurl" (implementing a wild-card pattern matching
downloads for the FTP-related part of [curl library][curl].

[BUT FIT]: https://www.fit.vut.cz/.en
[Predator]: https://github.com/kdudka/predator
[uef]: https://www.uef.fi/en
[languages]: https://www.openhub.net/accounts/praiskup/languages
[copr]: https://pagure.io/copr/copr/
[Fedora Copr]: https://copr.fedorainfracloud.org/
[stats]: https://copr-be.cloud.fedoraproject.org/stats/index.html
[mock]: https://github.com/rpm-software-management/mock
[resalloc]: https://github.com/praiskup/resalloc
[distgit]: https://github.com/release-engineering/dist-git
[packages]: https://src.fedoraproject.org/user/praiskup/projects
[proven]: https://docs.fedoraproject.org/en-US/fesco/Provenpackager_policy/
[dnf-plugin-diff]: https://github.com/praiskup/dnf-plugin-diff
[argparse-manpage]: https://github.com/praiskup/argparse-manpage
[rhel]: https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux
[postgresql-container]: https://github.com/sclorg/postgresql-container
[scls]: https://developers.redhat.com/products/softwarecollections/overview
[pkgworkshop]: https://praiskup.fedorapeople.org/courses/packaging/
[sclimages]: https://github.com/sclorg
[csdiff]: https://github.com/csutils/csdiff
[csmock]: https://github.com/csutils/csmock
[bughunting]: https://gitlab.com/bughunting/bughunting
[curl]: https://curl.se/
[packit]: https://packit.dev/
[distgen]: https://github.com/devexp-db/distgen
[pgsetup]: https://github.com/devexp-db/postgresql-setup
[release-notes]: https://docs.pagure.org/copr.copr/release_notes.html
