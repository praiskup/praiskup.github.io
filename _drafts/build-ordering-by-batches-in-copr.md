---
layout: post
title: Order your Copr builds using batches
date: 2020-12-10 00:00:00 +0000
lang: en
---

[Introducing the build batches][bb] feature in Copr raised more questions than
we initially thought.  So let me go a little bit into detail and explain the
feature on a practical example.

The Copr command-line tool now has two options `--after-build-id` and
`--with-build-id` in **all the build commands** (like `copr build`, `copr
build-package`, `buildscm`, `build-dist-git`, ..).  The feature is also exposed
in the web-UI, but it's far less convenient, so we'll avoid the web-UI today.


The problem
-----------

Copr build system itself is maintained as a set of components that are
packaged as RPM.  To build all the Copr packages "from scratch" we have to take
care of the package build order because the components have various
inter-dependencies.

The components are:

- `python-copr-common` - common tooling, helpers, all of our packages depend on
  this, except for clients
- `python-copr` - this is a client Python API that maps user requests to REST
  API, and allows communication with the `copr-frontend`.
- `copr-cli` - command-line client, transforms command-line requests to
  the Python API
- `copr-frontend`, `copr-frontend`, `copr-dist-git`, `copr-keygen` - these are
  the main packages installed on our servers.  `copr-backend` is a bit specific
  because it also depends on the Python API package `python-copr`.
- `copr-rpmbuild` - package that is installed on Copr builder, and controls the
  build processes

The build-dependency graph looks like:

![The build dependencies in Copr project](/images/build-ordering-by-batches/project-deps.png)

Some of those packages need to built sooner than others (so others can install
and use them at build time).

A user can of course submit the build for the main `python-copr-common` packages,
wait for the build, submit others, wait, submit, ... but nowadays we want to
submit everything **at once**, and later come to grab the build results.

The ordering/batch tooling?
---------------------------

Even though the new options accept **build IDs** arguments, Copr actually
operates with batches of builds where such batch can be represented by
**any batch member** (any contained build ID).

You can compose a tree (or rather a forest) of such build batches, meaning that
each batch can be blocked by exactly **one** other *parent* batch.

Batches can only be in `blocked`, `processing`, or `finished` state.  Batch is
`blocked` when *parent* batch is `processing` -- and switches to `processing`
when *parent* goes to the `finished` state.  At the time of writing this post,
we [still][proposal] don't take *failed* builds differently from *succeeded* or
*canceled* builds - batch is simply *finished* when all contained builds
finish.

The `--with-build-id BUILD_ID` makes sure that the newly created batch is built
together  with the `BUILD_ID` (at the same time, if possible, on different
builder machines).  Effectively it puts those builds into the same batch.

The other `--after-build-id BUILD_ID` option OTOH always creates a new batch for
the new build and makes sure that the new build is blocked by the batch of
builds with the `BUILD_ID`.

Since we allow build-dependencies across Copr projects, the set of builds in one
batch tree (or even in one batch) **can belong to multiple Copr projects**.  The
only limitation is that the user who tries to put the build into an existing batch
(`--with-build-id`) needs to have the *builder* permissions for at least one of
the Copr projects that are already part of that batch.  Still, anyone can chain
their own builds with others' batches using `--after-build-id` option.

In terms of ordering, doing builds `B after A` and `C with B` is almost
equivalent to doing `B after A` and `C after A`, except that the later creates
three batches (`{A}, {B} and {C}`) instead of two (`{A}, {B, C}`).  Both
variants may be more useful depending on a concrete situation, see below.


Chained approach (slower)
-------------------------

We could split the builds into three batches, and still keep the right build
order:

![chained batches](/images/build-ordering-by-batches/chained.png)

The downside here is that `copr-cli` and `copr-backend` will wait unnecessarily
long till everything else finishes.  And the dependency is only `python-copr`.


Tree approach (faster)
-------------------------

A better option is to split the task into four batches:

![chained batches](/images/build-ordering-by-batches/tree.png)

Now all the builds from the batch II. and III. can still be processed right
after I., but `copr-cli` and `copr-backend` in batch IV. can start building as
soon as batch II. finishes which is likely to happen sooner (see the screenshot
below).


Submit the batch builds
-----------------------

Copr packages can be built using Tito command directly from the default upstream
branch, therefor we use `buildscm` method:

{% highlight shell %}
# first build python-copr-common
copr buildscm --subdir common copr-project-name --nowait --method tito_test --clone-url https://pagure.io/copr/copr.git
Created build: 1823602

# build python-copr once python-copr-common is built
copr buildscm --subdir python copr-project-name --nowait --after-build-id 1823602 --method tito_test --clone-url https://pagure.io/copr/copr.git
Created build: 1823603

# build server packages + rpmbuild after python-copr-common
copr buildscm --subdir frontend copr-project-name --nowait --after-build-id 1823602 --method tito_test --clone-url https://pagure.io/copr/copr.git
Created build: 1823604
copr buildscm --subdir dist-git copr-project-name --nowait --with-build-id 1823604 --method tito_test --clone-url https://pagure.io/copr/copr.git
Created build: 1823605
copr buildscm --subdir keygen copr-project-name --nowait --with-build-id 1823604 --method tito_test --clone-url https://pagure.io/copr/copr.git
Created build: 1823606
copr buildscm --subdir rpmbuild copr-project-name --nowait --with-build-id 1823604 --method tito_test --clone-url https://pagure.io/copr/copr.git
Created build: 1823607

# and once python-copr is built (and copr-common), build backend and cli
copr buildscm --subdir cli copr-project-name --nowait --after-build-id 1823603 --method tito_test --clone-url https://pagure.io/copr/copr.git
Created build: 1823608
copr buildscm --subdir backend copr-project-name --nowait --with-build-id 1823608 --method tito_test --clone-url https://pagure.io/copr/copr.git
Created build: 1823609
{% endhighlight %}


The batches tab then looks like (after a few minutes):

![chained batches](/images/build-ordering-by-batches/batches.png)

Note that *batch 3125 (IV.)* is already being processed while the *batch 3124
(III.)* is not yet finished.

Discussion
----------

Sometimes it would be convenient if one batch could depend on multiple batches,
not just one.  This is not yet implemented (patches are welcome!).  In such
situation, users should tend to fall-back to the more chained-like approach, even if
it is the slower variant (the right order must be guaranteed).

Because it is quite some typing to run all the commands, some script that
triggers the build batches is a convenient thing.  Here's [an
example][example-script] of such script.

The [currently processed batches][actual-batches] are publicly visible.  Happy
building!

[proposal]: https://pagure.io/copr/copr/issue/1563
[bb]: https://docs.pagure.org/copr.copr/release-notes/2020-11-13.html#build-batches
[actual-batches]: https://copr.fedorainfracloud.org/status/batches/
[example-script]: https://pagure.io/copr/copr/blob/master/f/build_aux/rebuild-copr-stack
