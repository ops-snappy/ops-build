# In order to avoid openswitch libraries, apps, and python pkgs conflicting
# with similar objects already installed on the host, we'll install everything
# under $OPSUSR.
#
# In debian, We'll use systemd service overrides to adjust the environment to
# find the everything in the correct place.
#
# In snappy, TBD
#
OPSUSR:=/usr/$(DISTRO)
OPSLIB:=$(OPSUSR)/lib
OPSBIN:=$(OPSUSR)/bin
PYPATH:=$(OPSLIB)/python2.7/site-packages

# The OpenSwitch native build installation location
PLATFORM_PATH:=$(subst -,_,$(CONFIGURED_PLATFORM))
ifeq ($(CONFIGURED_PLATFORM),appliance)
ROOTFS:=$(BUILD_ROOT)/build/tmp/work/$(PLATFORM_PATH)-$(DISTRO)-linux/$(DISTRO)-appliance-image/1.0-r0/rootfs
else
ROOTFS:=$(BUILD_ROOT)/build/tmp/work/$(PLATFORM_PATH)-$(DISTRO)-linux/$(DISTRO)-disk-image/1.0-r0/rootfs
endif

# Local rebuild of host opennsl
HOSTBUILD:=$(BUILD_ROOT)/build/tmp/work/host-opennsl

# Debian-specific
DEBDIR:=standalone/debian

ifeq ($(CONFIGURED_PLATFORM),alphanetworks-snx-60a0-486f)

BCM_PLATFORM:=snx60a0-486f
BCM_VENDOR:=alpha-$(BCM_PLATFORM)
KERNEL_VERSION:=3.18.32-amd64

else ifeq ($(CONFIGURED_PLATFORM),alphanetworks-snh-60a0-320f)

BCM_PLATFORM:=snh60a0-320f
BCM_VENDOR:=alpha-$(BCM_PLATFORM)
KERNEL_VERSION:=3.18.32-amd64

else ifeq ($(CONFIGURED_PLATFORM),appliance)

else ifeq ($(CONFIGURED_PLATFORM),as6712)

BCM_PLATFORM:=x86-smp_generic_64-2_6
BCM_VENDOR:=as6712
KERNEL_VERSION:=4.4.0-21

endif
CDP_VERSION:=3.1.0.9
SDK_VERSION:=6.4.10
CDP_SYSTEMS=$(CDPDIR)/sdk-$(SDK_VERSION)-gpl-modules/systems/linux/user/$(BCM_PLATFORM)
CDP_BUILD=$(CDPDIR)/sdk-$(SDK_VERSION)-gpl-modules/build/linux/user/$(BCM_PLATFORM)
CDP_LIBDIR=$(CDPDIR)/bin/$(BCM_VENDOR)

relocated-usr-libs:=\
libcrypto \
libssl \
libnetsnmp \

relocated-libs:=\
libaudit \

relocate-bins:=\

usr-libs:=\
librbac \
libsupportability \
libswitchd_plugins \
libovscommon \
libovsdb \
libsflow \
libconfig-yaml \
libffi \
libjemalloc \
libofproto \
libopenvswitch \
libopsutils \
libops-cli \
libops_snmptrap \
libyaml-0 \
libyaml-cpp \
libatomic \
libospf  \
libzebra \

bin-daemons:=\
ops-arpmgrd \
ops-fand \
ops-intfd \
ops-lacpd \
ops-ledd \
ops-pmd \
ops-portd \
ops-krtd \
ops-sysd \
ops-tempd \
ops-udpfwd \
ops-vland \
ops-powerd \
vtysh \
ops-classifierd \
ops-passwd-srv \



sbin-daemons:=\
ops-bgpd \
ops-init \
ops-lldpd \
ops-ospfd \
ops-zebra \
ovsdb-server \

bin-cmds:=\
ops-broadview \
ops_mgmtintfcfg \
ovsdb-client \
ovsdb-tool \
ovs-appctl \
nwdiag \
cfgdbutil \

sbin-cmds:=\
ops-switchd

other-svcs:=\
aaautils \
cfgd \
mgmt-intf \
ops-ntpd \
switchd \

python-cmds:=\
ops_ntpd_sync_to_ovsdb \
ops_aaautilspamcfg \
ops_cfgd \
ops_ntpd \
restd \

yamls:=\
etc/openswitch/supportability \
var/lib

dirs:=\
usr/share/openvswitch \
srv/www \
etc/openswitch/platform \
etc/raddb \
usr/lib/cli/plugins \
usr/lib/openvswitch/plugins \
etc/ops-passwd-srv \
usr/share/opsplugins \

debug-dirs:=\
usr/lib/debug \
usr/src/debug \

ssl-certs:=\
server.crt \
server-private.key \

#pam-files:=\
common-account-access \
common-auth-access \
common-password-access \
common-session-access \
common-session-noninteractive \
groupadd \
groupdel \
groupmems \
groupmod \
useradd \
userdel \
usermod \

pam-files:=\
common-account-access \
common-auth-access \
common-session-access \
common-password-access \

ifeq ($(CONFIGURED_PLATFORM),appliance)

ovssbin-daemons:=\
ovs-vswitchd-sim \
ovsdb-server \

openvswitch-bin-cmds:=\
ovs-appctl \
ovs-benchmark \
ovs-dpctl \
ovs-dpctl-top \
ovs-l3ping \
ovs-ofctl \
ovs-parse-backtrace \
ovs-pcap \
ovs-pki \
ovs-tcpundump \
ovs-test \
ovs-vlan-test \
ovs-vsctl \
ovsdb-client \
ovsdb-tool \
vtep-ctl \

openvswitch-share:=\
vswitch.ovsschema \
vtep.ovsschema \

other-svcs+=\
openvswitch-sim \
ovsdb-server-sim \

else

bin-daemons+=\
ops-hw-vtep \
bufmond \

endif

define install-service
	echo Installing service $(1) ; \
	if [ -f $(ROOTFS)/lib/systemd/system/$(1).service ] ; then \
		install $(ROOTFS)/lib/systemd/system/$(1).service $(DESTDIR)/lib/systemd/system ; \
	fi
endef

define install-daemon
	echo Installing daemon $(1) ; \
	install $(2)/$(1) $(3) ; \
	$(call install-service,$(1))
endef

define install-lib
	echo Installing library $(1) ; \
	cp -a $(2)/$(1).* $(3)
endef

define install-file
	if [ -f $(2)/$(1) ] ; then \
		echo Installing file $(1) ; \
		install $(2)/$(1) $(3) ; \
	fi
endef

define install-dir
	if [ -d $(ROOTFS)/$(1) ] ; then \
		echo Installing dir $(ROOTFS)/$(1) to $(DESTDIR)/$(1) ; \
		install -d $(DESTDIR)/$(1) && cp -R $(ROOTFS)/$(1)/* $(DESTDIR)/$(1) ; \
	fi
endef

define install-py-cmd
	echo installing py-cmd $(1) ; \
	if [ -f $(ROOTFS)/usr/bin/$(1) ] ; then \
		$(call install-file,$(1),$(ROOTFS)/usr/bin,$(DESTDIR)/usr/bin) ; \
	fi ; \
	$(call install-service,$(1))
endef

define install-yamls
	echo Installing yaml $(1) ; \
	install -d $(DESTDIR)/$(1) && cp -a $(ROOTFS)/$(1)/*.yaml $(DESTDIR)/$(1)
endef

.PHONY: install-common install-debian install-snappy gdbinit host-opennsl

#
# Common installation for all targets
#

install-common:
	install -d $(DESTDIR)$(OPSLIB)
	install -d $(DESTDIR)$(OPSLIB)/pkgconfig
	install -d $(DESTDIR)$(PYPATH)
	install -d $(DESTDIR)$(OPSUSR)/bin
	install -d $(DESTDIR)/var/run/openvswitch
	install -d $(DESTDIR)/lib/systemd/system
	install -d $(DESTDIR)/usr/lib
	install -d $(DESTDIR)/usr/bin
	install -d $(DESTDIR)/usr/sbin
	install -d $(DESTDIR)/etc/openswitch
	install -d $(DESTDIR)/etc/init.d
	install -d $(DESTDIR)/etc/sudoers.d
	install -d $(DESTDIR)/etc/systemd/system
	install -d $(DESTDIR)/etc/ssl/certs
	install -d $(DESTDIR)/etc/pam.d
ifeq ($(CONFIGURED_PLATFORM),appliance)
	install -d $(DESTDIR)/opt/openvswitch/bin
	install -d $(DESTDIR)/opt/openvswitch/sbin
	install -d $(DESTDIR)/opt/openvswitch/share/openvswitch
	install -d $(DESTDIR)/var/run/openvswitch-sim
endif

	for i in $(usr-libs) ; do \
		$(call install-lib,$$i,$(ROOTFS)/usr/lib,$(DESTDIR)/usr/lib) ; \
	done

	for i in $(bin-daemons) ; do \
		$(call install-daemon,$$i,$(ROOTFS)/usr/bin,$(DESTDIR)/usr/bin) ; \
	done

	for i in $(bin-cmds) ; do \
		$(call install-file,$$i,$(ROOTFS)/usr/bin,$(DESTDIR)/usr/bin) ; \
	done

	for i in $(sbin-daemons) ; do \
		$(call install-daemon,$$i,$(ROOTFS)/usr/sbin,$(DESTDIR)/usr/sbin) ; \
	done

	for i in $(other-svcs) ; do \
		$(call install-service,$$i) ; \
	done

	for i in $(sbin-cmds) ; do \
		$(call install-file,$$i,$(ROOTFS)/usr/sbin,$(DESTDIR)/usr/sbin) ; \
	done

	for i in $(dirs) ; do \
		$(call install-dir,$$i) ; \
	done

	for i in $(yamls) ; do \
		$(call install-yamls,$$i) ; \
	done

	for i in $(ssl-certs) ; do \
		$(call install-file,$$i,$(ROOTFS)/etc/ssl/certs,$(DESTDIR)/etc/ssl/certs) ; \
	done

	for i in $(pam-files) ; do \
		$(call install-file,$$i,$(ROOTFS)/etc/pam.d,$(DESTDIR)/etc/pam.d) ; \
	done

	for i in $(python-cmds) ; do \
		$(call install-py-cmd,$$i) ; \
	done

	install -d $(DESTDIR)/usr/lib/openvswitch/plugins
	install $(ROOTFS)/usr/lib/openvswitch/plugins/* $(DESTDIR)/usr/lib/openvswitch/plugins

ifeq ($(CONFIGURED_PLATFORM),appliance)
	for i in $(ovssbin-daemons) ; do \
		$(call install-daemon,$$i,$(ROOTFS)/opt/openvswitch/sbin,$(DESTDIR)/opt/openvswitch/sbin) ; \
	done

	for i in $(openvswitch-bin-cmds) ; do \
		$(call install-file,$$i,$(ROOTFS)/opt/openvswitch/bin,$(DESTDIR)/opt/openvswitch/bin) ; \
	done

	for i in $(openvswitch-share) ; do \
		$(call install-file,$$i,$(ROOTFS)/opt/openvswitch/share/openvswitch,$(DESTDIR)/opt/openvswitch/share/openvswitch) ; \
	done
endif

	$(call install-file,image.manifest,$(ROOTFS)/etc/openswitch,$(DESTDIR)/etc/openswitch)
	$(call install-file,useradd,$(ROOTFS)/etc/sudoers.d,$(DESTDIR)/etc/sudoers.d)

	for i in $(debug-dirs) ; do \
		$(call install-dir,$$i) ; \
	done
	if [ -d $(DESTDIR)/usr/src/debug ] ; then \
		find $(DESTDIR)/usr/src/debug -type d -exec chmod 755 {} \; ; \
		find $(DESTDIR)/usr/src/debug -type f -exec chmod 644 {} \; ; \
	fi

# switchd/opennsl for host

install-debian-opennsl: host-opennsl

	install -d $(DESTDIR)/usr/bin
	install -m 0755 $(CDP_LIBDIR)/netserve $(DESTDIR)/usr/bin
	install -d $(DESTDIR)/lib/modules/$(KERNEL_VERSION)/extra/opennsl
	install $(CDP_BUILD)/*.ko $(DESTDIR)/lib/modules/$(KERNEL_VERSION)/extra/opennsl
	install -d $(DESTDIR)$(OPSLIB)
	install $(CDP_LIBDIR)/libopennsl.so.1 $(DESTDIR)$(OPSLIB)
	cd $(DESTDIR)$(OPSLIB) && ln -sf libopennsl.so.1 libopennsl.so
	install -d $(DESTDIR)$(OPSLIB)/pkgconfig
	install -m 0755 $(CDPDIR)/openswitch/opennsl.pc $(DESTDIR)$(OPSLIB)/pkgconfig
	sed -i -- "s/-DCDP_EXCLUDE/-UCDP_EXCLUDE/" $(DESTDIR)$(OPSLIB)/pkgconfig/opennsl.pc
	install -d $(DESTDIR)/etc/modules-load.d
	install -m 0655 $(CDPDIR)/openswitch/bcm-modules.conf $(DESTDIR)/etc/modules-load.d/
	install -d $(DESTDIR)/etc/modprobe.d/
	install -m 0655 $(CDPDIR)/openswitch/bcm-options.conf $(DESTDIR)/etc/modprobe.d/
	install -d $(DESTDIR)/etc/udev/rules.d
	install -m 0644 $(CDPDIR)/openswitch/bcm.rules $(DESTDIR)/etc/udev/rules.d/70-bcm.rules
	install -m 0755 $(CDPDIR)/openswitch/bcm_devices.sh $(DESTDIR)/etc/udev/rules.d

#
# Debian needs to relocate some objects that may conflict with existing debian installation
#

install-debian: install-common

# Relocate objects that may conflict with existing debian installation

	for i in $(relocated-usr-libs) ; do \
		$(call install-lib,$$i,$(ROOTFS)/usr/lib,$(DESTDIR)$(OPSLIB)) ; \
	done
	for i in $(relocated-libs) ; do \
		$(call install-lib,$$i,$(ROOTFS)/lib,$(DESTDIR)$(OPSLIB)) ; \
	done
	for i in $(relocate-bins) ; do \
		$(call install-file,$$i,$(ROOTFS)/usr/bin,$(DESTDIR)$(OPSBIN)) ; \
	done

	cp -a $(ROOTFS)/usr/bin/py* $(DESTDIR)$(OPSBIN)
	cp -a $(ROOTFS)/usr/lib/libpy* $(DESTDIR)$(OPSLIB)
	cp -a $(ROOTFS)/usr/lib/python2.7 $(DESTDIR)$(OPSLIB)

# Fix up permissions

	find $(DESTDIR) -name *.yaml | xargs chmod 644
	find $(DESTDIR) -name *.service | xargs chmod 644

#
# Snappy doesn't have to relocate anything since application is containerized
#

install-snappy: install-common

	for i in $(relocated-usr-libs) ; do \
		$(call install-lib,$$i,$(ROOTFS)/usr/lib,$(DESTDIR)/usr/lib) ; \
	done
	for i in $(relocated-libs) ; do \
		$(call install-lib,$$i,$(ROOTFS)/lib,$(DESTDIR)/lib) ; \
	done
	for i in $(relocate-bins) ; do \
		$(call install-file,$$i,$(ROOTFS)/usr/bin,$(DESTDIR)/usr/bin) ; \
	done

	cp -a $(ROOTFS)/usr/bin/py* $(DESTDIR)/usr/bin
	cp -a $(ROOTFS)/usr/lib/libpy* $(DESTDIR)/usr/lib
	cp -a $(ROOTFS)/usr/lib/python2.7 $(DESTDIR)/usr/lib

#
# Point to local debug information for remote debugging on target
#
gdbinit:
	echo "directory $(ROOTFS)" > $(DESTDIR)/.gdbinit
	echo "set debug-file-directory $(ROOTFS)/usr/lib/debug" >> $(DESTDIR)/.gdbinit
	echo "set solib-search-path $(ROOTFS)/usr/lib:\\" >> $(DESTDIR)/.gdbinit
	echo "$(ROOTFS)/usr/lib/openvswitch/plugins:\\" >> $(DESTDIR)/.gdbinit
	echo "$(ROOTFS)/usr/lib/cli/plugins" >> $(DESTDIR)/.gdbinit

#
# Since opennsl generates kernel objects, it must be rebuilt for the target system.
#

# Expects CDPDIR, LINUX_SRC, LINUX_KBUILD to be set by caller
host-opennsl: $(CDPDIR) $(LINUX_SRC) $(LINUX_KBUILD)
	test -d $(CDP_SYSTEMS) || mkdir -p $(CDP_SYSTEMS)
	cp yocto/openswitch/meta-platform-openswitch-$(CONFIGURED_PLATFORM)/recipes-asic/opennsl/opennsl-cdp/Makefile-modules $(CDP_SYSTEMS)/Makefile
	cd $(CDP_SYSTEMS) && KERNEL_SRC=$(LINUX_SRC) KBUILD_OUTPUT=$(LINUX_KBUILD) SDK="$(CDPDIR)/sdk-$(SDK_VERSION)-gpl-modules" CROSS_COMPILE="" make
