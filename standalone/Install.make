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
ROOTFS:=$(BUILD_ROOT)/build/tmp/work/$(PLATFORM_PATH)-$(DISTRO)-linux/$(DISTRO)-disk-image/1.0-r0/rootfs

# Local rebuild of host opennsl
HOSTBUILD:=$(BUILD_ROOT)/build/tmp/work/host-opennsl

# Debian-specific
DEBDIR:=standalone/debian

ifeq ($(CONFIGURED_PLATFORM),alphanetworks-snx-60a0-486f)

# TODO - The following variables need to be dynamically defined as they are currently
#        hardcoded for the SNX-60A0-486F.
BCM_PLATFORM:=snx60a0-486f
BCM_VENDOR:=alpha-$(BCM_PLATFORM)
KERNEL_VERSION:=3.18.32-amd64

else ifeq ($(CONFIGURED_PLATFORM),alphanetworks-snh-60a0-320f)

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
libssl \

relocated-libs:=\
libaudit \
libcrypto \

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
libyaml-0 \

bin-daemons:=\
ops-arpmgrd \
ops-fand \
ops-hw-vtep \
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
bufmond \
vtysh \
ops-classifierd \

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
usr/lib/openvswitch/plugins \
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

define install-service-overrides
	for svc in $(DESTDIR)/lib/systemd/system/*.service ; do \
		svcname=$${svc##*/} ; \
		svcname=$${svcname%.service} ; \
		install -d $(DESTDIR)/etc/systemd/system/$$svcname.service.d ; \
		case $$svcname in \
		cfgd|switchd|ops-init) \
			install -m 644 $(DEBDIR)/systemd_service_overrides/$$svcname.conf $(DESTDIR)/etc/systemd/system/$$svcname.service.d ; \
			;; \
		aaautils|ops-ntpd|restd) \
			install -m 644 $(DEBDIR)/systemd_service_overrides/pypath.conf $(DESTDIR)/etc/systemd/system/$$svcname.service.d ; \
			;; \
		*) \
			install -m 644 $(DEBDIR)/systemd_service_overrides/openswitch.conf $(DESTDIR)/etc/systemd/system/$$svcname.service.d ; \
			;; \
		esac ; \
	done
endef

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
		echo Installing dir $(1) ; \
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

.PHONY: install-common install-debian install-snappy host-opennsl

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

	$(call install-file,image.manifest,$(ROOTFS)/etc/openswitch,$(DESTDIR)/etc/openswitch)
	$(call install-file,useradd,$(ROOTFS)/etc/sudoers.d,$(DESTDIR)/etc/sudoers.d)

# switchd/opennsl for host

ifdef CDPDIR
	install -d $(DESTDIR)/lib/modules/$(KERNEL_VERSION)/extra/opennsl
	install -m 0755 $(CDP_LIBDIR)/netserve $(DESTDIR)/usr/bin
	install $(CDP_BUILD)/*.ko $(DESTDIR)/lib/modules/$(KERNEL_VERSION)/extra/opennsl
	install $(CDP_LIBDIR)/libopennsl.so.1 $(DESTDIR)$(OPSLIB)
	cd $(DESTDIR)$(OPSLIB) && ln -s libopennsl.so.1 libopennsl.so
	install -m 0755 $(CDPDIR)/openswitch/opennsl.pc $(DESTDIR)$(OPSLIB)/pkgconfig
	sed -i -- "s/-DCDP_EXCLUDE/-UCDP_EXCLUDE/" $(DESTDIR)$(OPSLIB)/pkgconfig/opennsl.pc
	install -d $(DESTDIR)/etc/modules-load.d
	install -m 0655 $(CDPDIR)/openswitch/bcm-modules.conf $(DESTDIR)/etc/modules-load.d/
	install -d $(DESTDIR)/etc/modprobe.d/
	install -m 0655 $(CDPDIR)/openswitch/bcm-options.conf $(DESTDIR)/etc/modprobe.d/
	install -d $(DESTDIR)/etc/udev/rules.d
	install -m 0644 $(CDPDIR)/openswitch/bcm.rules $(DESTDIR)/etc/udev/rules.d/70-bcm.rules
	install -m 0755 $(CDPDIR)/openswitch/bcm_devices.sh $(DESTDIR)/etc/udev/rules.d
	install -d $(DESTDIR)/usr/lib/openvswitch/plugins
	install $(ROOTFS)/usr/lib/openvswitch/plugins/* $(DESTDIR)/usr/lib/openvswitch/plugins
endif

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

# Service overrides set up OpenSwitch-specific environment

	$(call install-service-overrides)

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
# Since opennsl generates kernel objects, it must be rebuilt for the target system.
#

# Expects CDPDIR, LINUX_HEADERS, and KERNEL_VERSION to be set by caller
host-opennsl: $(CDPDIR) $(LINUX_HEADERS)
	test -d $(CDP_SYSTEMS) || mkdir -p $(CDP_SYSTEMS)
	cp yocto/openswitch/meta-platform-openswitch-$(CONFIGURED_PLATFORM)/recipes-asic/opennsl/opennsl-cdp/Makefile-modules $(CDP_SYSTEMS)/Makefile
	cd $(CDP_SYSTEMS) && KERNEL_SRC=$(LINUX_HEADERS)/usr/src/linux-headers-$(KERNEL_VERSION) KBUILD_OUTPUT=$(LINUX_HEADERS)/usr/src/linux-headers-$(KERNEL_VERSION) SDK="$(CDPDIR)/sdk-$(SDK_VERSION)-gpl-modules" CROSS_COMPILE="" make
