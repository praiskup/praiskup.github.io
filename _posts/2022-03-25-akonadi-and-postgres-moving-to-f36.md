---
layout: post
title: Migrating Akonadi+PostgreSQL to Fedora N+1
lang: en
---

These Akonadi updates are "mostly" fluent on Fedora nowadays.  At least for the
several previous releases.  But I sometimes need to think a bit during the
upgrade and **do some manual steps**.  Steps that I'm not completely sure I
would be able to do, without my previous PostgreSQL packaging maintenance
experience.  So let me reconstruct the latest upgrade from Fedora 35 to Fedora
36.

The Fedora upgrade
==================

I started without any preparation with this:

    $ sudo dnf update fedora-upgrade --enablerepo updates-testing
    $ sudo fedora-upgrade

I've chosen the "online" upgrade (not supported) variant.  If done in `tmux`, I
found it more reliable actually (even before I started using `fedora-upgrade`
for upgrades, I was confident with `dnf distro-sync --releasever N+1` and never
experienced any major problems).

I gave some answers to the tool, the upgrade started (I calmly continued with my
normal daily work), after about 30 minutes some problems with libraries appeared
(old RPMs and thus libraries started disappearing).  Finally, I answered some of
the Y/N questions and rebooted.

The problems with Akonadi upgrade
=================================

KMail started to shout at me that Akonadi is not working;  so from previous
experience, I immediately correctly guessed that there was something wrong
with the PostgreSQL backend (upgraded from v13 to v14 this time).  Hurry up to
command-line:

    $ akonadictl start
    org.kde.pim.akonadictl: Starting Akonadi Server...
    org.kde.pim.akonadictl:    done.
    Connecting to deprecated signal QDBusConnectionInterface::serviceOwnerChanged(QString,QString,QString)
    10:54:42 ~/rh/projects/rhcopr/pagure/maint$ org.kde.pim.akonadiserver: Starting up the Akonadi Server...
    org.kde.pim.akonadiserver: Cluster PG_VERSION is 13 , PostgreSQL server is version  14 , will attempt to upgrade the cluster
    org.kde.pim.akonadiserver: Postgres db cluster upgrade failed, Akonadi will fail to start. Sorry.
    org.kde.pim.akonadiserver: Database process exited unexpectedly during initial connection!
    org.kde.pim.akonadiserver: executable: "/usr/bin/pg_ctl"
    org.kde.pim.akonadiserver: arguments: ("start", "-w", "--timeout=10",....
    org.kde.pim.akonadiserver: stdout: "waiting for server to start....
    2022-03-22 10:54:42.685 CET [14272] FATAL:  database files are incompatible with server
    2022-03-22 10:54:42.685 CET [14272] DETAIL:  The data directory was initialized
    org.kde.pim.akonadiserver: stderr: "pg_ctl: could not start server\nExamine the log output.\n"
    org.kde.pim.akonadiserver: exit code: 1
    org.kde.pim.akonadiserver: process error: "Unknown error"
    org.kde.pim.akonadiserver: Shutting down AkonadiServer...
    org.kde.pim.akonadicontrol: Application '/usr/bin/akonadiserver' exited normally...

This was weird, per *Postgres db cluster upgrade failed* it looks upgrade is
automatized by Akonadi, but it failed without a clear reason.  Here I'm clearly
missing a hint that `postgresql-upgrade` package must be installed (that brings
PostgreSQL 13 on the new system, so we can do the in-place upgrade to v14):

    $ sudo dnf install -y postgresql-upgrade

Then re-trying:

    $ akonadictl start
    org.kde.pim.akonadictl: Starting Akonadi Server...
    org.kde.pim.akonadictl:    done.
    Connecting to deprecated signal QDBusConnectionInterface::serviceOwnerChanged(QString,QString,QString)
    10:55:35 ~/rh/projects/rhcopr/pagure/maint$ org.kde.pim.akonadiserver: Starting up the Akonadi Server...
    org.kde.pim.akonadiserver: Cluster PG_VERSION is 13 , PostgreSQL server is version  14 , will attempt to upgrade the cluster
    org.kde.pim.akonadiserver: Postgres cluster update: "new_db_data" cluster already exists, trying to remove it first
    org.kde.pim.akonadiserver: Postgres cluster upgrade: creating a new cluster for current Postgres server
    The files belonging to this database system will be owned by user "praiskup".
    This user must also own the server process.

    The database cluster will be initialized with locale "C".
    The default text search configuration will be set to "english".

    Data page checksums are disabled.

    fixing permissions on existing directory /home/praiskup/.local/share/akonadi/new_db_data ... ok
    creating subdirectories ... ok
    selecting dynamic shared memory implementation ... posix
    selecting default max_connections ... 100
    selecting default shared_buffers ... 128MB
    selecting default time zone ... Europe/Prague
    creating configuration files ... ok
    running bootstrap script ... ok
    performing post-bootstrap initialization ... ok
    syncing data to disk ... ok

    initdb: warning: enabling "trust" authentication for local connections
    You can change this by editing pg_hba.conf or using the option -A, or
    --auth-local and --auth-host, the next time you run initdb.

    Success. You can now start the database server using:

        /usr/bin/pg_ctl -D /home/praiskup/.local/share/akonadi/new_db_data -l logfile start

    org.kde.pim.akonadiserver: Postgres cluster update: starting pg_upgrade to upgrade your Akonadi DB cluster
    org.kde.pim.akonadiserver: Postgres cluster update: pg_upgrade finished with exit code 1 , please run migration manually.
    org.kde.pim.akonadiserver: Postgres db cluster upgrade failed, Akonadi will fail to start. Sorry.
    org.kde.pim.akonadiserver: Database process exited unexpectedly during initial connection!
    org.kde.pim.akonadiserver: executable: "/usr/bin/pg_ctl"
    org.kde.pim.akonadiserver: arguments: ("start", "-w", "--timeout=10", ...
    org.kde.pim.akonadiserver: stdout: "waiting for server to start....
    2022-03-22 10:55:36.766 CET [14842] FATAL:  database files are incompatible with server
    [repeating the previous error]

Looked better, but still failed.  Without an obvious reason why.  Per
*"pg_upgrade finished with exit code 1 , please run migration manually"*,
I tried:

    $ postgresql-upgrade /home/praiskup/.local/share/akonadi/db_data/
    FATAL: /home/praiskup/.local/share/akonadi/db_data_old already exists

Ah, I already did this before :-) so trying once more:

    $ mv /home/praiskup/.local/share/akonadi/db_data_old{,_old}
    $ postgresql-upgrade /home/praiskup/.local/share/akonadi/db_data/
     * cmd: /usr/bin/initdb --pgdata=/home/praiskup/.local/share/akonadi/db_data --auth=ident

    The files belonging to this database system will be owned by user "praiskup".
    This user must also own the server process.

    The database cluster will be initialized with locale "en_US.UTF-8".
    The default database encoding has accordingly been set to "UTF8".
    The default text search configuration will be set to "english".

    Data page checksums are disabled.

    fixing permissions on existing directory /home/praiskup/.local/share/akonadi/db_data ... ok
    creating subdirectories ... ok
    selecting dynamic shared memory implementation ... posix
    selecting default max_connections ... 100
    selecting default shared_buffers ... 128MB
    selecting default time zone ... Europe/Prague
    creating configuration files ... ok
    running bootstrap script ... ok
    performing post-bootstrap initialization ... ok
    syncing data to disk ... ok

    Success. You can now start the database server using:

        /usr/bin/pg_ctl -D /home/praiskup/.local/share/akonadi/db_data -l logfile start

     * logs are stored in /tmp/postgresql_upgrade_oUNSi7

     * cmd: /usr/bin/pg_upgrade --old-bindir=/usr/lib64/pgsql/postgresql-13/bin --new-bindir=/usr/bin --old-datadir=/home/praiskup/.local/share/akonadi/db_data_old --new-datadir=/home/praiskup/.local/share/akonadi/db_data --link

    Performing Consistency Checks
    -----------------------------
    Checking cluster versions                                   ok

    The source cluster was not shut down cleanly.
    Failure, exiting
     * restoring previous datadir

Now it is clear.  I forgot to shut down the old PostgreSQL server when rebooting
on (still) Fedora 35.  The system-default PostgreSQL server, when started by the
default systemd unit files, would be shut-down automatically during the RPM
upgrade (in post scriptlet, as a result of unsuccessful service restart after
the major PG upgrade).  Our case is not a system-default service but one started
by Akonadi (under my UID, not `postgres=26`).

So, this *"The source cluster was not shut down cleanly"* means here that there's
a leftover lock/pid file in the data directory, and the PG upgrade would probably
simply recover after the lockfile removal.  But since we have have PG 13
installed (the postgresql-upgrade package), we can be more careful and let the
PG itself fix this for us:

    $ /usr/lib64/pgsql/postgresql-13/bin/pg_ctl start -D /home/praiskup/.local/share/akonadi/db_data/
    waiting for server to start....
    2022-03-22 11:00:47.480 CET [15461] LOG:  redirecting log output to logging collector process
    2022-03-22 11:00:47.480 CET [15461] HINT:  Future log output will appear in directory "log".
    done
    server started
    $ /usr/lib64/pgsql/postgresql-13/bin/pg_ctl stop -D /home/praiskup/.local/share/akonadi/db_data/
    waiting for server to shut down.... done
    server stopped

And finally we can upgrade:

    $ postgresql-upgrade /home/praiskup/.local/share/akonadi/db_data/
    ... snip ...
    Performing Consistency Checks
    -----------------------------
    Checking cluster versions                                   ok
    ... snip ...
    Performing Upgrade
    ------------------
    Analyzing all rows in the new cluster                       ok
    ... snip ...
    Upgrade Complete
    ----------------
    Optimizer statistics are not transferred by pg_upgrade.
    Once you start the new server, consider running:
        /usr/bin/vacuumdb --all --analyze-in-stages

    Running this script will delete the old cluster's data files:
        ./delete_old_cluster.sh
     * old data directory and configuration is in /home/praiskup/.local/share/akonadi/db_data_old

But because the "lock file problem" was fixed, I bet that simply doing
`akonadictl start` at this point would just work, too.
I haven't tried because I was curious if the `postgresql-upgrade` script
actually works.

So starting now:

    $ akonadictl start
    org.kde.pim.akonadictl: Starting Akonadi Server...
    org.kde.pim.akonadictl:    done.
    org.kde.pim.akonadiserver: Starting up the Akonadi Server...
    org.kde.pim.akonadiserver: Running DB initializer
    org.kde.pim.akonadiserver: DB initializer done
    org.kde.pim.akonadicontrol: Akonadi server is now operational.
    ...


And the last recommendation, *"Once you start the new server, consider running:
/usr/bin/vacuumdb --all --analyze-in-stages"*:

    $ ps x | grep /bin/postgres
    15737 ?        Ss     2:54 /usr/bin/postgres -D /home/praiskup/.local/share/akonadi/db_data -k/tmp/akonadi-praiskup.L3Q6By -h
    $ /usr/bin/vacuumdb --all --analyze-in-stages -h /tmp/akonadi-praiskup.L3Q6By
    vacuumdb: processing database "akonadi": Generating minimal optimizer statistics (1 target)
    vacuumdb: processing database "postgres": Generating minimal optimizer statistics (1 target)
    vacuumdb: processing database "template1": Generating minimal optimizer statistics (1 target)
    vacuumdb: processing database "akonadi": Generating medium optimizer statistics (10 targets)
    vacuumdb: processing database "postgres": Generating medium optimizer statistics (10 targets)
    vacuumdb: processing database "template1": Generating medium optimizer statistics (10 targets)
    vacuumdb: processing database "akonadi": Generating default (full) optimizer statistics
    vacuumdb: processing database "postgres": Generating default (full) optimizer statistics
    vacuumdb: processing database "template1": Generating default (full) optimizer statistics

Yeah, one needs to realize where PG cluster stores the socket file (`-k`
option), and run `vacuumdb` with the `-h` option.  Note the size of the datadir:

    $ du -h --max-depth 0 /home/praiskup/.local/share/akonadi/db_data/
    2.9G    /home/praiskup/.local/share/akonadi/db_data/

... and still, the in-place upgrade is done almost instantly.  We just need to
be prepared for some automation hiccups.
