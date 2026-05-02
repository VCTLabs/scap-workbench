============================================
 OSCAP Assessment and Development Workflows
============================================

The Security Content Automation Protocol (SCAP) is a method of using
certain interoperable security standards to automate evaluating policy
compliance of deployed systems.

The SCAP tools described here are required to perform OS-level scanning
of compliance with specific security standards; note this applies to multiple
Linux OS distributions, including any Linux runtime built using Yocto project
tools.

Current (upstream) packages and/or SCAP profiles may not be available for
non-RHEL environments, eg, the baseline openembedded profile was only recently
merged into the SSG source code.

Development workflows
=====================

* content (profile) development/tailoring
* upstream/backports integration
* packaging/deployment

.. note:: All of the above workflows are supported in each forked repository.
          An initial openembedded profile compliance workflow is supported either
          via the meta-security-backports_ layer on LTS branches starting with
          dunfell_ or on the *very* latest branches in the meta-security_ layer.

As of ``v0.1.76``, scap-security-guide recognizes the following OpenEmbedded
variants:

* OE ``nodistro``
* Yocto reference distro ``poky``
* Xilinx SDK distro ``petalinux``
* meta-hardening distro ``harden``


Dev components and tool dependencies
------------------------------------

* openscap_ - NIST Certified SCAP 1.2+ toolkit
* SCAP Security Guide (SSG_ aka content) - Security automation content in SCAP,
  Bash, Ansible, and other formats
* `SCAP Workbench`_ - SCAP Scanner And Tailoring GUI


.. _SCAP: https://csrc.nist.gov/projects/security-content-automation-protocol
.. _openscap: https://www.open-scap.org/tools/openscap-base/#documentation
.. _SSG: https://complianceascode.readthedocs.io/en/latest/
.. _SCAP Workbench: https://static.open-scap.org/scap-workbench-1.1/
.. _meta-security-backports: https://github.com/VCTLabs/meta-security-backports
.. _meta-security: https://git.yoctoproject.org/meta-security/
.. _dunfell: https://github.com/VCTLabs/meta-security-backports/tree/dunfell

Development workflows require recent Python_ and Tox_, along with the (tox)
workflow files on the current development branches in the VCTLabs Github
repos shown below.

::

  $ cd openscap
  $ source .tox/tools/bin/activate
  (tools) $ oscap --version | head -n1
  OpenSCAP command line tool (oscap) 1.3.10

--and--

::

  $ cd scap-security-guide
  $ bash utils/version.sh
  0.1.75

--and--

::

  $ cd scap-workbench
  $ source .tox/venv/bin/activate
  (venv) $ scap-workbench --version
  19:15:28 | info     | SCAP Workbench 1.2.1, compiled with Qt 5.15.12, using OpenSCAP 1.3.10
  SCAP Workbench 1.2.1

Alternately, the current repository state for the repolite-synced components
can be viewed by overriding the default argument for the ``tox -e sync`` cmd,
e.g., using scap-workbench from the previous example, run the following command:

::

  $ tox -e sync -- --show
  sync: commands[0]> repolite --show
  INFO:root:Repository oscap: branch is workbench-1.3, commit is 1.3.10-2-ga358f4657
  INFO:root:Repository content: branch is oe-stable-too-new, commit is v0.1.75-36-ge1f2e9a2f4
  INFO:root:Repository ymltoxml: branch is main, commit is 0.4.2
    sync: OK (0.25=setup[0.04]+cmd[0.21] seconds)
    congratulations :) (0.28 seconds)

.. note:: Some of the upstream repositories changed their release workflows,
          e.g., tags in the content repo moved from master to stable, thus
          the above output shows the "last" tag on master branch instead of
          the most recent tag. In this case ``git describe`` may need the
          branch name to show the latest tag::

            $ git describe --tags --always  origin/stable
            v0.1.75-32-gb9e06eeb74


The VCT branches for the configured workflows were forked from either
master or the latest stable "maint" branch:

* openscap - 1.3.13 tag plus 2 patches on workbench-1.3_ branch (``tox.ini`` file)

  + enable RPATH install support for local workflows
  + add basic tox file and update gitignore for tox dir

* SSG - stabilization-v0.1.79 merge plus 4 patches on oe-stable-too-new_ branch
  (``tox-dev.ini`` file)

  + oe standard: cleanup passwd aging and related login-defs checks
  + openembedded: add platform_package_overrides, update pkg applicability
  + enable RPATH install for openscap, bump reqs version
  + pluck tox-dev, repolite cfgs, and reqs updates

* SCAP Workbench - 6 patches on v1-2-devel_ (``tox.ini`` file)

  + bump workflow deps and patches to 1.3.10 and 0.1.75
  + roll back to fixed 1.3 branch for openscap, update metadata
  + add example sudoers file for remote scan host
  + add cmake RPATH install mod, update tox and repolite cfgs
  + add yaml tools to repolite cfg, cleanup tox file
  + add tox file/plugin and repolite config for local dev workflow

* SCAP Workbench - 2 patches on build-fixes (GCC-13 and Qt5.15)

  + set the base C++ std version to c++11 and do not force c++20 err
  + fix qt_version_check: 5.15 => 5.14

Each fork also has a repolite_ configuration file that specifies the
required repository and metadata used to checkout the work branches (or
specific git hashes for a reproducible "locked" repolite config).

.. note:: Any previously listed patches for oscap and SSG content have been
          accepted upstream and incorporated in recent releases.


.. _Python: https://www.python.org/downloads/
.. _Tox: https://github.com/tox-dev/tox
.. _workbench-1.3: https://github.com/VCTLabs/openscap/tree/workbench-1.3
.. _oe-stable-too-new: https://github.com/VCTLabs/scap-security-guide/tree/oe-stable-too-new
.. _v1-2-devel: https://github.com/VCTLabs/scap-workbench/commits/ branch/
.. _repolite: https://github.com/sarnold/repolite


Build dependencies and ordering
-------------------------------

SCAP component dependencies on each other form a build sequence which is
reflected in the repositories synced by each workflow and the tox commands
used to build the local checkouts for each workflow:

1. openscap can build stand-alone, so it should be built first
2. SSG content requires the openscap library and schema files so
   the SSG workflow must sync, build, and install openscap
3. SCAP workbench requires both of the previous components, so the
   workflow must sync, build, and install both openscap and the SSG

All 3 components use CMake, thus the development environment requires
the basic package building tools and either a GNU or Clang toolchain. On
Ubuntu focal, it might be something like this::

  $ sudo apt-get install flex bison build-essential

Additional Qt5 GUI and desktop dependencies for scap-workbench are also
required; again, for Ubuntu focal use something like this::

  $ sudo apt-get install libqt5xmlpatterns5-dev ssh-askpass libpolkit-agent-1-0

Tox will install any python and cmake-specific tools into the target
environment from PyPI.

SSH keys and remote scanning
----------------------------

The right SSH key and sudoers setup is required for both oscap permissions
and smooth workflows. This can be *mostly* baked in for custom (yocto) images,
but will need to be done manually for other hosts.

Prerequisites
~~~~~~~~~~~~~

* "dev" host - Linux with openscap/SSG/workbench installed, plus ssh-askpass
* target host - Linux with openscap scanner installed plus ssh server
* target host - scan user has sudo/nopasswd config for ``oscap``
  (sudoers for scan user should be restricted to ``oscap`` command only)
* optional - create ssh key for dev host user on target host w/o passphrase

Test logging into the target host using the scan user's login id, something
like::

  $ ssh admin@192.168.1.175
  beaglebone-yocto:~$  oscap --version | head -n1
  OpenSCAP command line tool (oscap) 1.3.9


Development workflow usage
--------------------------

General considerations:

* run ``tox list`` to view the tox environment commands
* except openscap, first run the workflow command to sync tool repositories
* then run the build/install commands to create the virtual environment

Specific tox environment commands:

* openscap - tools,tests,clean
* scap-security-guide - sync,tools,install,tests,clean
* scap-workbench - sync,oscap,content,product,install,clean,depclean

.. note:: Since the upstream SSG repository already had a ``tox.ini`` file,
          the workflow commands are documented in ``tox-dev.ini`` instead
          of the default (tox) config. Workflow commands in the SSG repository
          must use the config file argument for all commands, for example:

          ::

            $ tox -c tox-dev.ini list        # --or--
            $ tox -c tox-dev.ini -e tools    # and so on


As shown in the note above, use the (built-in) "list" command to view a brief
description of each custom environment command, e.g.,

::

  $ tox list                  # --or--
  $ tox -c tox-dev.ini list   # in the SSG repo

Running the above command in the scap-workbench repo would show the following
output::

  default environments:
  oscap    -> Install required oscap lib or content dependencies into shared /home/user/src/scap-workbench/.tox/venv path
  content  -> Install required oscap lib or content dependencies into shared /home/user/src/scap-workbench/.tox/venv path
  install  -> Install scap workbench into shared /home/user/src/scap-workbench/.tox/venv path
  product  -> Run build_product to install a single product (default: openembedded)
  sync     -> Install repolite and use it for handling workflow deps => openscap, SSG, python tools
  clean    -> Clean the cmake build tree
  depclean -> Clean the dependent cmake build trees

.. note:: By default, tox environment commands create an isolated environment
          for each command using the command name, *however*, in these workflows
          (including the above scap-workbench example) some of the tox commands
          use a shared environment, possibly with a name that is *not* a command
          name. In this example the tox commands ``oscap,content,product,install``
          all use a shared virtual environment under ``.tox/venv``.


SCAP workbench example
----------------------

With the toolchain and Qt5 dependencies installed, clone the repository
and change directories, then build::

  $ git clone https://github.com/VCTLabs/scap-workbench.git
  $ cd scap-workbench/
  $ git checkout v1-2-devel
  $ tox -e sync                   # clone the oscap repos
  $ tox -e oscap,content,install  # build and install all products   --or--
  $ tox -e oscap,product,install  # build and install a single product


.. important:: If using GCC 13+ then scap-workbench may not yet have the
               patches merged and the build may fail.  To fix the build,
               rebase the work branch on top of the ``build-fixes`` branch,
               e.g.,

               ::

                 $ git checkout v1-2-devel
                 $ git pull --rebase=merges origin build-fixes


In this workflow, all subsequent commands should be run from *inside* the
virtual environment created by the tox commands above, e.g.,

::

  $ cd scap-workbench/  # after running the above install commands
  $ source .venv/bin/activate
  (venv) $ scap-workbench    # use the GUI to open a data stream (ds file)
                             # from inside the virtual environment


The installation path for SSG content is under the ``.tox/venv/`` folder::

  (venv) $ ls .tox/venv/
  bin  etc  include  lib  lib64  libexec  pyvenv.cfg  share
  (venv) $ ls .tox/venv/share/xml/scap/ssg/content/ssg-openembedded*
  .tox/venv/share/xml/scap/ssg/content/ssg-openembedded-cpe-dictionary.xml
  .tox/venv/share/xml/scap/ssg/content/ssg-openembedded-cpe-oval.xml
  .tox/venv/share/xml/scap/ssg/content/ssg-openembedded-ds-1.2.xml
  .tox/venv/share/xml/scap/ssg/content/ssg-openembedded-ds.xml
  .tox/venv/share/xml/scap/ssg/content/ssg-openembedded-ocil.xml
  .tox/venv/share/xml/scap/ssg/content/ssg-openembedded-oval.xml
  .tox/venv/share/xml/scap/ssg/content/ssg-openembedded-xccdf.xml


Note that remote scans using scap-workbench are only supported when using
one of the datastream files shown above.

Remote scan with scap workbench
-------------------------------

From the virtual environment created in the previous section, start the
workbench and perform the following steps to initiate a remote scan:

1. Start the scap workbench GUI with the path to the datastream file as shown;
   the console will display any messages, errors or otherwise:

::

  source .tox/venv/bin/activate
  (venv) $ scap-workbench .tox/venv/share/xml/scap/ssg/content/ssg-openembedded-ds.xml

2. Verify the GUI displays the correct content guide and profile
   (select another profile as needed)
3. For **Target** select "Remote Machine (over SSH)
4. For **User and host** enter the credentials tested previously, e.g.,
   ``admin@192.168.1.175``
5. Click the large button in the bottom corner labeled **Scan**
6. Be patient; messages are displayed in the status bar of the GUI *and*
   in the console window
7. Wait for the "Processing..." message, eventually it should complete with
   ``Processing has been finished!``
8. Use the Show Report or Save Results buttons to review the output

To save and/or handoff the results, use Save Results and select both XCCDF
Result file and HTML Report.  Use Firefox/Chromium or another modern browser
to review the HTML report file.


Production workflows
====================

* profile compliance
* malware/CVE scans
* packaging/deployment

Production workflows will generally use released (and possibly backported)
packages, and avoid the use of tox or locally cloned repositories. The main
exception is using a development workflow to create an environment for running
remote scans.

Production components
---------------------

Production workflows typically require *at least* openscap and either the
full SSG or the XCCDF/datastream files for the target host profile. SCAP
Workbench provides an optional GUI for scanning or tailoring tasks.

Backported packages are used when the required versions are not available
in the given host environment, e.g., the packages available in Ubuntu 20.04
(focal) are not new enough to scan a focal install, therefore the backports
from a PPA are used instead. The intent is to provide the appropriate SSG
content to allow self-hosted scans for both compliance and tailoring.

* OE board targets: meta-security-backports_ provides current openscap and
  SSG packages for openembedded, poky, and petalinux images
* Ubuntu dev targets: the `embedded device PPA`_ provides current openscap
  and SSG packages for Ubuntu 20.04, 22.04, and 24.04 (v0.1.76+ only) development hosts
* Gentoo dev targets: the embedded-overlay_ provides current openscap and
  SSG packages for Gentoo 2.x development hosts

.. note:: Gentoo development hosts are only supported for content
          development or remote scanning. Self-hosted scans are
          not currently supported.

.. _embedded device PPA: https://launchpad.net/~nerdboy/+archive/ubuntu/embedded
.. _embedded-overlay: https://github.com/VCTLabs/embedded-overlay

Production workflow usage
-------------------------

General considerations:

* installing from PPA or overlay requires a (one-time) setup step
* OE scans require a specific build image with the scan tools

Ubuntu PPA setup
~~~~~~~~~~~~~~~~

The preferred Ubuntu target host for SCAP workflows is 22.04 (jammy); first
make sure to have the ``add-apt-repository`` command installed and then add
the PPA:

::

  $ sudo apt-get install software-properties-common
  $ sudo add-apt-repository -y -s ppa:nerdboy/embedded

If you get a key error you will also need to manually import the PPA
signing key like so:

::

  $ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys <PPA_KEY>

where <PPA_KEY> is the key shown in the launchpad PPA page under "Adding
this PPA to your system", eg, ``41113ed57774ed19`` for `Embedded device ppa`_.

For tailoring workflows, install the workbench::

  $ sudo apt-get install scap-workbench

For remote scanning workflows, install the openscap-scanner package, on
the target host, otherwise for self-hosted scans install the desired SSG
package::

  $ sudo apt-get install openscap-scanner   # --or--
  $ sudo apt-get install ssg-nondebian      # to scan openembedded/other, or
  $ sudo apt-get install ssg-debderived     # to scan all Ubuntu versions

This is also an example of source packages that each generate several binary
packages, which can be viewed on the PPA page. In this case, open the page for
the `embedded device PPA`_ in a browser and click on `View package details`_.
Scroll to the desired (source) package name and click the arrow button to
the left of Package Name (e.g., ``scap-security-guide``) to see the list of
"Built packages".  Use the built package names in ``apt`` install commands.

Gentoo overlay setup
~~~~~~~~~~~~~~~~~~~~

Follow the `overlay install instructions`_ and sync the overlay. There is not
currently any Gentoo support in openscap, but you can install the workbench
for remote scanning or tailoring a specific XCCDF profile::

  $ sudo emerge scap-workbench


.. _overlay install instructions: https://github.com/VCTLabs/embedded-overlay#install-the-overlay-without-layman
.. _View package details: https://launchpad.net/~nerdboy/+archive/ubuntu/embedded/+packages


OE (self-hosted) scan example
-----------------------------

TODO

Practical considerations
========================

* minimum (extra) software requirements for compliance scanning varies
  based on scan scenario, ie, self-hosted or remote scan

  + self-hosted scan **does not** require a network connection
  + self-hosted scan **does** require both oscap scanner *and* SSG
    packages insalled
  + self-hosted scan **does** require (physical) console access,
    and writable tmp directory

* minimum requirements for remote scan include:

  + oscap scanner, ssh server, sudo installed on target host
  + scap-workbench, ssh-askpass installed on scan host
  + password-less sudo configuration for oscap/admin user
  + optional - user key installed on scan host, user pubkey
    installed for target host scan user

Selecting a profile
-------------------

Use the ``oscap`` command directly from the console to select a specific
profile or display all available profiles using the info command on the
datastream file for a given product.

If using OS packages, replace ``.tox/venv`` in the path with the local
install prefix, probably ``/usr``::

  $ oscap info .tox/venv/share/xml/scap/ssg/content/ssg-openembedded-ds.xml
  Document type: Source Data Stream
  Imported: 2024-02-19T12:03:35

  Stream: scap_org.open-scap_datastream_from_xccdf_ssg-openembedded-xccdf.xml
  Generated: (null)
  Version: 1.3
  Checklists:
          Ref-Id: scap_org.open-scap_cref_ssg-openembedded-xccdf.xml
                  Status: draft
                  Generated: 2024-02-19
                  Resolved: true
                  Profiles:
                          Title: Sample expanded Security Profile for OpenEmbedded Distros
                                  Id: xccdf_org.ssgproject.content_profile_expanded
                          Title: Sample Security Profile for OpenEmbedded Distros
                                  Id: xccdf_org.ssgproject.content_profile_standard
                  Referenced check files:
                          ssg-openembedded-oval.xml
                                  system: http://oval.mitre.org/XMLSchema/oval-definitions-5
                          ssg-openembedded-ocil.xml
                                  system: http://scap.nist.gov/schema/ocil/2
  Checks:
          Ref-Id: scap_org.open-scap_cref_ssg-openembedded-oval.xml
          Ref-Id: scap_org.open-scap_cref_ssg-openembedded-ocil.xml
          Ref-Id: scap_org.open-scap_cref_ssg-openembedded-cpe-oval.xml
  Dictionaries:
          Ref-Id: scap_org.open-scap_cref_ssg-openembedded-cpe-dictionary.xml

To run a scan using the "expanded" profile shown above, use the following
command on the target host::

  $ sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_expanded \
      --results results.xml \
      --report report.html \
      .tox/venv/share/xml/scap/ssg/content/ssg-openembedded-ds.xml
