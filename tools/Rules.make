# Copyright (C) 2015 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export DISTRO_ARCHIVE_ADDRESS
export DISTRO_SSTATE_ADDRESS
export CURL_CA_BUNDLE=$(DISTRO_CA_BUNDLE)

# Toolchain variables
OE_HOST_SYSROOT=$(BUILD_ROOT)/build/tmp/sysroots/$(shell uname -m)-linux/
# Some toolchain dirs are named different than their toolchain prefix
# For example ppc
TOOLCHAIN_BIN_PATH=$(OE_HOST_SYSROOT)/usr/bin/$(TOOLCHAIN_DIR_PREFIX)

# Export this variables from the environment to simplify key management when using an agent
export SSH_AGENT_PID
export SSH_AUTH_SOCK
ifneq ($(VERBOSE),)
 export VERBOSE
endif
export BUILDDIR=$(BUILD_ROOT)/build
export BB_ENV_EXTRAWHITE=MACHINE DISTRO TCMODE TCLIBC HTTP_PROXY http_proxy HTTPS_PROXY https_proxy FTP_PROXY ftp_proxy ALL_PROXY all_proxy NO_PROXY no_proxy SSH_AGENT_PID SSH_AUTH_SOCK BB_SRCREV_POLICY SDKMACHINE BB_NUMBER_THREADS BB_NO_NETWORK PARALLEL_MAKE GIT_PROXY_COMMAND SOCKS5_PASSWD SOCKS5_USER SCREENDIR STAMPS_DIR PLATFORM_DTS_FILE BUILD_ROOT NFSROOTPATH NFSROOTIP
export PATH:=$(BUILD_ROOT)/yocto/poky/scripts:$(BUILD_ROOT)/yocto/poky/bitbake/bin:$(BUILD_ROOT)/tools/bin:$(PATH)
export LD_LIBRARY_PATH:=$(BUILD_ROOT)/tools/lib:$(LD_LIBRARY_PATH)

# Some well known locations
KERNEL_STAGING_DIR=$(shell cd $(BUILDDIR) ; $(BUILD_ROOT)/yocto/poky/bitbake/bin/bitbake -e | awk -F= '/^STAGING_KERNEL_DIR=/ { gsub(/"/, "", $$2); print $$2 }')
DISTRO_VERSION=$(shell cd $(BUILDDIR) ; $(BUILD_ROOT)/yocto/poky/bitbake/bin/bitbake -e | awk -F= '/^DISTRO_VERSION=/ { gsub(/"/, "", $$2); print $$2 }')
STAGING_DIR_TARGET=$(shell cd $(BUILDDIR) ; $(BUILD_ROOT)/yocto/poky/bitbake/bin/bitbake -e | awk -F= '/^STAGING_DIR_TARGET=/ { gsub(/"/, "", $$2); print $$2 }')
STAGING_DIR_NATIVE=$(shell cd $(BUILDDIR) ; $(BUILD_ROOT)/yocto/poky/bitbake/bin/bitbake -e | awk -F= '/^STAGING_DIR_NATIVE=/ { gsub(/"/, "", $$2); print $$2 }')
# Used to identify the valid layers
YOCTO_LAYERS=$(shell cd $(BUILDDIR) ; $(BUILD_ROOT)/yocto/poky/bitbake/bin/bitbake -e | awk -F'=' '/^BBLAYERS=/ { print $$2 }')
BASE_UIMAGE_FILE = $(BUILDDIR)/tmp/deploy/images/$(CONFIGURED_PLATFORM)/uImage
BASE_IMAGE_FILE = $(BUILDDIR)/tmp/deploy/images/$(CONFIGURED_PLATFORM)/Image
BASE_ZIMAGE_FILE = $(BUILDDIR)/tmp/deploy/images/$(CONFIGURED_PLATFORM)/zImage
BASE_BZIMAGE_FILE = $(BUILDDIR)/tmp/deploy/images/$(CONFIGURED_PLATFORM)/bzImage
BASE_SIMPLEIMAGE_FILE = $(BUILDDIR)/tmp/deploy/images/$(CONFIGURED_PLATFORM)/simpleImage.$(CONFIGURED_PLATFORM)
BASE_SIMPLEIMAGE_INITRAMFS_FILE = $(BUILDDIR)/tmp/deploy/images/$(CONFIGURED_PLATFORM)/simpleImage.$(CONFIGURED_PLATFORM)-initramfs-$(CONFIGURED_PLATFORM).bin
BASE_VMLINUX_FILE = $(BUILDDIR)/tmp/deploy/images/$(CONFIGURED_PLATFORM)/vmlinux
BASE_CPIO_FS_FILE = $(BUILDDIR)/tmp/deploy/images/$(CONFIGURED_PLATFORM)/$(DISTRO_FS_TARGET)-$(CONFIGURED_PLATFORM).cpio.gz
BASE_TARGZ_FS_FILE = $(BUILDDIR)/tmp/deploy/images/$(CONFIGURED_PLATFORM)/$(DISTRO_FS_TARGET)-$(CONFIGURED_PLATFORM).tar.gz
BASE_HDDIMG_FS_FILE = $(BUILDDIR)/tmp/deploy/images/$(CONFIGURED_PLATFORM)/$(DISTRO_FS_TARGET)-$(CONFIGURED_PLATFORM).hddimg
BASE_OVA_FILE = $(BUILDDIR)/tmp/deploy/images/$(CONFIGURED_PLATFORM)/$(DISTRO_FS_TARGET)-$(CONFIGURED_PLATFORM).ova
BASE_BOX_FILE = $(BUILDDIR)/tmp/deploy/images/$(CONFIGURED_PLATFORM)/$(DISTRO_FS_TARGET)-$(CONFIGURED_PLATFORM).box
BASE_ONIE_INSTALLER_FILE = $(BUILDDIR)/tmp/deploy/images/$(CONFIGURED_PLATFORM)/$(ONIE_INSTALLER_FILE)
BASE_DOCKER_IMAGE = openhalon/${CONFIGURED_PLATFORM}

PYTEST_NATIVE=$(STAGING_DIR_NATIVE)/usr/bin/py.test

# Some makefile macros

# Parameters: first argument is the fatal error message
define FATAL_ERROR
	$(ECHO) ; \
	 $(ECHO) "$(RED)ERROR:$(GRAY) $(1)" ; \
	 $(ECHO) ; \
	 exit 1
endef

# Parameters: first argument is the message
define WARNING
	$(ECHO) ; \
	 $(ECHO) "$(YELLOW)WARNING:$(GRAY) $(1)" ; \
	 $(ECHO)
endef

# Parameters: first argument is the recipe to bake
define BITBAKE
	cd $(BUILDDIR) ; umask 002 ; \
	 $(BUILD_ROOT)/yocto/poky/bitbake/bin/bitbake $(1)
endef

# Parameters: first argument is the recipe to bake
define BITBAKE_NO_FAILURE
	cd $(BUILDDIR) ; umask 002 ; \
	 $(BUILD_ROOT)/yocto/poky/bitbake/bin/bitbake $(1) || exit 1
endef

define DEVTOOL
	 cd $(BUILDDIR) ; umask 002 ; \
	 $(BUILD_ROOT)/yocto/poky/scripts/devtool $(1) || exit 1
endef

# Rule to regenerate the site.conf file if proxies changed
include tools/config/proxy.conf

build/conf/site.conf: tools/config/site.conf.in tools/config/proxy.conf
	$(V)mkdir -p $(dir $@)
	$(V)cp tools/config/site.conf.in $@
	$(V)if [ -n "$(GIT_PROXY_COMMAND)" ] ; then \
           sed -i -e "s|##GIT_PROXY_COMMAND##|GIT_PROXY_COMMAND = \"$(GIT_PROXY_COMMAND)\"|" $@ ; \
	 fi
	$(V)if [ -n "$(PROXY)" ] ; then \
	   sed -i -e "s|##ALL_PROXY##|ALL_PROXY = \"http://$(PROXY):$(PROXY_PORT)\"|" $@ ; \
	 fi

build/conf/local.conf: .platform
	$(V)mkdir -p $(dir $@)
	$(V)\
	 sed \
	   -e "s|##DISTRO##|$(DISTRO)|" \
	   -e "s|##PLATFORM##|$(CONFIGURED_PLATFORM)|" \
           -e "s|##DISTRO_SSTATE_ADDRESS##|$(DISTRO_SSTATE_ADDRESS)|" \
	   -e "s|##DISTRO_ARCHIVE_ADDRESS##|$(DISTRO_ARCHIVE_ADDRESS)|" \
	   tools/config/local.conf.in > $@

header:: build/conf/site.conf build/conf/local.conf

-include yocto/*/meta-platform-$(DISTRO)-$(CONFIGURED_PLATFORM)/Rules.make
export PLATFORM_DTS_FILE

########## Common targets shared by most platforms ##############
HOST_ARCH=$(shell uname -m)

.PHONY: kernel _kernel _kernel_links kernelconfig
kernel: header _kernel

_KERNEL_TARGET ?= _kernel

DISTRO_KERNEL_SYMBOLS_FILE ?= $(BASE_VMLINUX_FILE)
_kernel:
	$(V) $(ECHO) "$(YELLOW)Building kernel...$(GRAY)\n"
	$(V)$(call BITBAKE,virtual/kernel)
	$(V) $(MAKE) _kernel_links
	$(V) $(ECHO)

_kernel_links:
	$(V)if test -f $(DISTRO_KERNEL_FILE) ; then ln -sf $(DISTRO_KERNEL_FILE) images/kernel-$(CONFIGURED_PLATFORM).bin ; fi
	$(V)if test -f $(DISTRO_KERNEL_SYMBOLS_FILE) ; then ln -sf $(DISTRO_KERNEL_SYMBOLS_FILE) images/kernel-$(CONFIGURED_PLATFORM).elf ; fi

$(DISTRO_KERNEL_FILE) images/kernel-$(CONFIGURED_PLATFORM).bin:
	$(V) $(MAKE) $(_KERNEL_TARGET)

.PHONY: fs _fs _fs_links
ifneq ($(findstring fs,$(MAKECMDGOALS)),)
 ifeq ($(DISTRO_FS_TARGET),undefined)
  $(error ====== DISTRO_FS_TARGET variable is empty, please specify it on your board meta-<product>/Rules.make =====)
 endif
endif
fs: header _fs

_fs images/fs-$(CONFIGURED_PLATFORM):
	$(V) $(ECHO) "$(YELLOW)Building fs ($(DISTRO_FS_TARGET))...$(GRAY)\n"
	$(V)$(call BITBAKE,$(DISTRO_FS_TARGET))
	$(V) $(MAKE) _fs_links
	$(V) $(ECHO)

_fs_links:
	$(V)ln -sf $(DISTRO_FS_FILE) images/`basename $(DISTRO_FS_FILE)`
	$(V)for extra_fs in $(DISTRO_EXTRA_FS_FILES) ; do ln -sf $$extra_fs images/`basename $$extra_fs` ; done
	@# If we have a tar.gz file, also link it, useful for docker images
	$(V)if [ -f $(BASE_TARGZ_FS_FILE) ] ; then ln -sf $(BASE_TARGZ_FS_FILE) images/`basename $(BASE_TARGZ_FS_FILE)` ; fi
	$(V)ln -sf `basename $(DISTRO_FS_FILE)` images/fs-$(CONFIGURED_PLATFORM)
	$(V)ln -sf `dirname $(DISTRO_FS_FILE)`/`basename $(DISTRO_FS_FILE) |  cut -d'.' -f1`.manifest images/`basename $(DISTRO_FS_FILE) | cut -d'.' -f1`.manifest

.PHONY: bake _bake
$(eval $(call PARSE_ARGUMENTS,bake))
RECIPE?=$(EXTRA_ARGS)
ifneq ($(findstring bake,$(MAKECMDGOALS)),)
 ifeq ($(RECIPE),)
  $(error ====== RECIPE variable is empty, please specify which recipe you want to bake =====)
 endif
endif
bake: header _bake

_bake:
	$(V)$(call BITBAKE,$(RECIPE))

.PHONY: cleansstate _cleansstate
$(eval $(call PARSE_ARGUMENTS,cleansstate))
RECIPE?=$(EXTRA_ARGS)
ifneq ($(findstring cleansstate,$(MAKECMDGOALS)),)
 ifeq ($(RECIPE),)
  $(error ====== RECIPE variable is empty, please specify which recipe you want to clean =====)
 endif
endif
cleansstate: header _cleansstate

_cleansstate:
	$(V)$(call BITBAKE,-c cleansstate $(RECIPE))

CONTAINER_NAME?=openhalon
.PHONY: deploy_container
deploy_container:
	$(V) if ! which lxc-create > /dev/null ; then \
	  $(call FATAL_ERROR,LXC does not seems installed, could not find lxc-create) ; \
	fi
	$(V) if ! lsmod | grep -q openvswitch ; then \
	  $(call FATAL_ERROR,OpenVswitch module not running on the host machine... please load the openvswitch kernel module) ; \
	fi
	$(V) if ! which ovs-vsctl > /dev/null ; then \
	  $(call FATAL_ERROR,ovs-vsctl tool not available, please install the openvswitch tools) ; \
	fi
	$(V) if ! test -f images/`basename $(BASE_TARGZ_FS_FILE)` ; then \
	  $(call FATAL_ERROR,Your platform has not generated a .tar.gz file that can be used to create the container) ; \
	fi
	$(V) $(ECHO) "Exporting an lxc-container with name '$(CONTAINER_NAME)' may ask for admin password..."
	$(V) $(ECHO) -n "Checking that no container with the same name already exists..."
	$(V) if $(SUDO) lxc-info -n $(CONTAINER_NAME) >/dev/null 2>&1 ; then \
	  echo ; \
	  $(call FATAL_ERROR, A container '$(CONTAINER_NAME)' already exists... aborting.\nYou may remove it with 'sudo lxc-destroy -n $(CONTAINER_NAME)') ; \
	else \
	  echo done ; \
	fi
	$(V) export OPENHALON_IMAGE=$(BUILD_ROOT)/images/`basename $(BASE_TARGZ_FS_FILE)` ; \
	export BUILD_ROOT ; \
	$(SUDO) -E lxc-create -n $(CONTAINER_NAME) -f /dev/null -t $(BUILD_ROOT)/tools/lxc/lxc-openhalon
	$(V) $(ECHO) "Exporting completed.\nRun with 'sudo lxc-start -n $(CONTAINER_NAME)'"

.PHONY: export_docker_image
$(eval $(call PARSE_ARGUMENTS, export_docker_image))
DOCKER_IMAGE:=$(EXTRA_ARGS)
ifeq ($(DOCKER_IMAGE),)
DOCKER_IMAGE=$(BASE_DOCKER_IMAGE)
endif
export_docker_image:
	$(V) if ! which docker > /dev/null ; then \
	    $(call FATAL_ERROR, Docker is not installed. \
	                        Could not find 'docker' command.) ; \
	fi
	$(V) if docker images $(DOCKER_IMAGE) | grep $(DOCKER_IMAGE) >/dev/null ; then \
	    $(call FATAL_ERROR, Docker image '$(DOCKER_IMAGE)' is already created.\n \
	                       \tYou can remove it using - docker rmi $(DOCKER_IMAGE)) ; \
	fi
	$(V) if ! test -f images/`basename $(BASE_TARGZ_FS_FILE)` ; then \
	    $(call FATAL_ERROR, Unable to find $(BASE_TARGZ_FS_FILE)\n \
	                       \tRun 'make' at the top level to create root-fs.) ; \
	fi
	$(V) $(ECHO) "Exporting '$(BASE_TARGZ_FS_FILE)' as a Docker Container Image '$(DOCKER_IMAGE)'"
	$(V) /bin/cat $(BASE_TARGZ_FS_FILE) | docker import - $(DOCKER_IMAGE)

.PHONY: deploy_nfsroot
NFSROOTPATH?=$(BUILD_ROOT)/nfsroot-${CONFIGURED_PLATFORM}
export NFSROOTPATH
deploy_nfsroot:
	$(V) if ! which exportfs > /dev/null ; then \
	  $(call FATAL_ERROR,Missing exportfs utility, unable to export rootfs. Did you install the NFS server package?) ; \
	fi
	$(V) if ! test -f images/$(notdir $(BASE_TARGZ_FS_FILE)) ; then \
	  $(call FATAL_ERROR,Your platform has not generated a .tar.gz file that can be used to deploy the NFS root) ; \
	fi
	$(V) if [ -d $(NFSROOTPATH) ] ; then \
	  $(call WARNING,Removing previous deployed nfsroot directory at $(NFSROOTPATH) before re-deploying) ; \
	  $(ECHO) "Press any key to continue wipping out previous nfsroot, or ctrl+c to abort..." ; \
	  read ; \
	  $(SUDO) rm -Rf $(NFSROOTPATH) ; \
	fi
	$(V) mkdir -p $(NFSROOTPATH)
	$(V) $(ECHO) -n "Extracting the NFS root into $(NFSROOTPATH)... "
	$(V) tar -xzf images/$(notdir $(BASE_TARGZ_FS_FILE)) -C $(NFSROOTPATH)
	$(V) $(ECHO) done
	$(V) if ! [ -f /etc/exports.d/$(notdir $(NFSROOTPATH)).exports ] ; then \
	  $(ECHO) "\nExporting NFS directory, may ask for admin password..." ; \
	  $(SUDO) mkdir -p /etc/exports.d ; \
	  $(SUDO) bash -c 'echo "$(NFSROOTPATH) *(rw,no_root_squash,sync,no_subtree_check,insecure)" > /etc/exports.d/$(notdir $(NFSROOTPATH)).exports' ; \
	  if which service > /dev/null ; then \
	    $(SUDO) service nfs-kernel-server start ; \
	  fi ; \
	  echo ; \
	fi

.PHONY: devshell
$(eval $(call PARSE_ARGUMENTS,devshell))
RECIPE?=$(EXTRA_ARGS)
ifneq ($(findstring devshell,$(MAKECMDGOALS)),)
 ifeq ($(RECIPE),)
  $(error ====== RECIPE variable is empty, please specify which recipe you want the devshell for  =====)
 endif
endif

# OK, here is an interesting behavior: when se call screen from devshell
# in recent versions of Yocto (Dora and up), it doesn't like to be called
# when the MAKEOVERRIDES variable is set, therefore causing the devshell
# to fail. Unsetting it manually
devshell: header
	$(V)unset MAKEOVERRIDES ; $(call BITBAKE, -c devshell $(RECIPE))

.PHONY: sdk _sdk
sdk: header _sdk
	$(V) ln -fs $(BUILD_ROOT)/build/tmp/deploy/sdk/$(DISTRO)-glibc-`uname -m`-*-toolchain-*.sh images

_sdk:
	$(V) $(ECHO) "$(YELLOW)Building SDK...$(GRAY)\n"
	$(V)$(call BITBAKE,meta-toolchain-$(DISTRO))

# Used to generate the dtb for the board
.PHONY: dtb
dtb: images/$(CONFIGURED_PLATFORM).dtb

# We need to remove the chosen section of the file, since will be added by uboot
images/$(CONFIGURED_PLATFORM).dtb: $(PLATFORM_DTS_FILE)
	$(V) $(ECHO) " Generating dtb from dts..."
	$(V) cp $< images/$(CONFIGURED_PLATFORM).dts
	$(V) dtc images/$(CONFIGURED_PLATFORM).dts -O dtb -o $@ -p 2048

MKIMAGE=tools/bin/mkimage

$(MKIMAGE): build/tmp/sysroots/$(HOST_ARCH)-linux/usr/bin/uboot-mkimage
	$(V) ln -sf $(BUILD_ROOT)/build/tmp/sysroots/$(HOST_ARCH)-linux/usr/bin/mkimage $@

build/tmp/sysroots/$(HOST_ARCH)-linux/usr/bin/uboot-mkimage:
	$(V)$(ECHO) " Building mkimage..."
	$(V)$(call BITBAKE,u-boot-mkimage-native)

# FIT image for uboot
.PHONY: itb
itb:: images/$(CONFIGURED_PLATFORM).itb
	$(V) $(ECHO) "$(YELLOW)Building itb file...$(GRAY)\n"
	$(V)$(MAKE) images/$(CONFIGURED_PLATFORM).itb

images/$(CONFIGURED_PLATFORM).itb:: $(DISTRO_PLATFORM_ITS_FILE) $(MKIMAGE)
	$(V) $(ECHO) " Generating itb from its..."
	$(V)cat $(DISTRO_PLATFORM_ITS_FILE) > images/$(CONFIGURED_PLATFORM).its
	$(V) $(MKIMAGE) -f images/$(CONFIGURED_PLATFORM).its $@

# ONIE installer
.PHONY: onie-installer
onie-installer: header _onie-installer _kernel_links _fs_links

DISTRO_ONIE_INSTALLER_FILE?= $(BASE_ONIE_INSTALLER_FILE)
_onie-installer::
	$(V) $(ECHO) "$(YELLOW)Building ONIE Installer file ($(ONIE_INSTALLER_RECIPE))...$(GRAY)\n"
	$(V)$(call BITBAKE,$(ONIE_INSTALLER_RECIPE))
	$(V)ln -sf $(DISTRO_ONIE_INSTALLER_FILE) images/`basename $(DISTRO_ONIE_INSTALLER_FILE)`

ifneq ($(findstring onie-installer,$(MAKECMDGOALS)),)
 ifeq ($(ONIE_INSTALLER_RECIPE),)
  $(error ====== ONIE_INSTALLER_RECIPE variable is empty, please define it in your platform's Rules.make  =====)
 endif
endif

# Devenv code
GITREVIEWUSER:=$(shell git config --get gitreview.username)
ifneq ($(GITREVIEWUSER),)
 REVIEWUSER?=$(GITREVIEWUSER)
endif
REVIEWUSER?=$(USER)

setup-git-review:
	$(V) $(ECHO) "$(YELLOW)Setting up git-review system...$(GRAY)\n"
	$(V)$(MAKE) _setup-git-review

_setup-git-review:: .git/hooks/commit-msg
	$(V) if which git-review > /dev/null ; then \
	  git review -s ; \
	else \
	  $(call WARNING,git-review wasn't found... skipping his configuration) ; \
	fi

.git/hooks/commit-msg:
	$(V) gitdir=$$(git rev-parse --git-dir); scp -q -p -P 29418 $(REVIEWUSER)@review.openhalon.io:hooks/commit-msg $${gitdir}/hooks/

.PHONY: devenv_init devenv_clean devenv_add devenv_rm devenv_status devenv_cscope devenv_list_all 
.PHONY: devenv_import dev_header devenv_refresh _devenv_refresh

-include src/Rules.make

dev_header: header
	$(V) flock -n $(BUILDDIR)/bitbake.lock echo -n || \
	   { echo "Bitbake is currently running... can't proceed further, aborting" ; \
             exit 255 ; }
	$(V) if ! [ -f .devenv ] ; then \
	  $(call FATAL_ERROR, devenv is not initialized, use 'devenv_init') ; \
	fi

devenv_init: header
	$(V) $(ECHO) "$(YELLOW)Configuring development enviroment...$(GRAY)\n"
	$(V) $(call BITBAKE,meta-ide-support)
	$(V) touch .devenv
	$(V) $(MAKE) setup-git-review

# We try to export this symbol only when the target is invoked, since the expansion
# can cause to trigger bitbake before is configured in other cases
ifneq ($(findstring devenv_list_all,$(MAKECMDGOALS)),)
  export YOCTO_LAYERS
endif
devenv_list_all: header
	$(V)$(ECHO) "List of available devenv packages for $(CONFIGURED_PLATFORM) platform:"
	$(V) for layer in $$YOCTO_LAYERS ; do \
	   test -d $$layer || continue ; \
	   DEVCONFS="$$DEVCONFS `find $$layer -name devenv.conf`" ; \
	 done ; \
	 for devconf in $$DEVCONFS ; do \
	   while read recipe ; do \
	     [[ $$recipe == \#* ]] && continue ; \
	     $(ECHO) "  * $$recipe" ; \
	   done < $$devconf ; \
	done

devenv_cscope: header
	$(V) if !  which cscope > /dev/null ; then \
	  $(call FATAL_ERROR,Could not find cscope in your path, please install it.) ; \
	fi
	$(V) $(ECHO) "$(YELLOW)Updating cscope indexes for development environment...$(GRAY)\n"
	$(V)find $(STAGING_DIR_TARGET)/usr/include -type f -name "*.[chxsS]" -print > $(BUILD_ROOT)/src/cscope.files
	$(V)find $(BUILD_ROOT)/src -type f -name "*.[chxsS]" -print >> $(BUILD_ROOT)/src/cscope.files
	$(V)cd $(BUILD_ROOT)/src/ ; cscope -b -q -k

devenv_clean: dev_header
	$(V)$(call DEVTOOL, reset -a)
	$(V)rm -Rf src .devenv

DEVENV_BRANCH?=master

define DEVENV_ADD
	if ! grep -q $(1) .devenv 2>/dev/null ; then \
	  $(call DEVTOOL, modify --extract $(1) $(BUILD_ROOT)/src/$(1)) ; \
	  pushd . > /dev/null ; \
	  cd $(BUILD_ROOT)/src/$(1) ; \
	  if [ -f .gitreview ] ; then \
	    gitdir=$$(git rev-parse --git-dir); scp -q -p -P 29418 $(REVIEWUSER)@review.openhalon.io:hooks/commit-msg $${gitdir}/hooks/ ; \
	  fi ; \
	  git checkout $(DEVENV_BRANCH) || { $(call FATAL_ERROR, Unable to checkout the request branch '$(DEVENV_BRANCH)') ; } ; \
	  popd > /dev/null ; \
	  sed -e "s/##RECIPE##/$(1)/g" $(BUILD_ROOT)/tools/devenv-recipe-template.make >> $(BUILD_ROOT)/src/Rules.make ; \
	  echo $(1) >> $(BUILD_ROOT)/.devenv ; \
	else \
	  $(ECHO) "$(YELLOW)$(1)$(GRAY) is already in your devenv" ; \
	fi ;
endef

$(eval $(call PARSE_ARGUMENTS,devenv_add))
PACKAGE?=$(EXTRA_ARGS)
ifneq ($(findstring devenv_add,$(MAKECMDGOALS)),)
  ifeq ($(PACKAGE),)
   $(error ====== PACKAGE variable is empty, please specify which package you want  =====)
  endif
endif
devenv_add: dev_header
	$(V)$(foreach P, $(PACKAGE), $(call DEVENV_ADD,$(P)))

ifeq (devenv_import,$(firstword $(MAKECMDGOALS)))
  PACKAGE := $(wordlist 2, 2,$(MAKECMDGOALS))
  IMPORTED_SRC := $(wordlist 3, 3,$(MAKECMDGOALS))
  $(eval $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))::;@:)
  ifeq ($(PACKAGE),)
   $(error ====== PACKAGE variable is empty, please specify which package you want  =====)
  endif
  ifeq ($(IMPORTED_SRC),)
   $(error ====== IMPORTED_SRC variable is empty, please specify the source to import  =====)
  endif
endif
devenv_import:
	$(V) grep  -q $(PACKAGE) .devenv 2>/dev/null || $(call DEVTOOL, modify $(PACKAGE) $(IMPORTED_SRC)) && \
	mkdir -p $(BUILD_ROOT)/src && \
	sed -e "s/##RECIPE##/$(PACKAGE)/g" $(BUILD_ROOT)/tools/devenv-recipe-template.make >> $(BUILD_ROOT)/src/Rules.make && \
	echo $(PACKAGE) >> $(BUILD_ROOT)/.devenv

$(eval $(call PARSE_ARGUMENTS,devenv_rm))
PACKAGE?=$(EXTRA_ARGS)
ifneq ($(findstring devenv_rm,$(MAKECMDGOALS)),)
  ifeq ($(PACKAGE),)
   $(error ====== PACKAGE variable is empty, please specify which package you want =====)
  endif
endif
devenv_rm: dev_header
	$(V)$(V)sed -i -e "/#$(PACKAGE)/,/#END_$(PACKAGE)/d" src/Rules.make
	$(V)sed -i -e "/$(PACKAGE)/d" .devenv
	$(V)$(call DEVTOOL,reset $(PACKAGE))
	$(V)rm -Rf src/$(PACKAGE)

devenv_status: dev_header
	$(V) $(call DEVTOOL,status)

$(eval $(call PARSE_ARGUMENTS,devenv_update_recipe))
PACKAGE?=$(EXTRA_ARGS)
ifneq ($(findstring devenv_update_recipe,$(MAKECMDGOALS)),)
  ifeq ($(PACKAGE),)
   $(error ====== PACKAGE variable is empty, please specify which package you want =====)
  endif
endif
devenv_update_recipe: dev_header
	$(V)$(call DEVTOOL,update-recipe $(PACKAGE))

$(eval $(call PARSE_ARGUMENTS,devenv_patch_recipe))
PACKAGE?=$(EXTRA_ARGS)
ifneq ($(findstring devenv_patch_recipe,$(MAKECMDGOALS)),)
  ifeq ($(PACKAGE),)
   $(error ====== PACKAGE variable is empty, please specify which package you want =====)
  endif
endif
devenv_patch_recipe: dev_header
	$(V)$(call DEVTOOL,update-recipe -m patch $(PACKAGE))


devenv_refresh: dev_header _devenv_refresh

_devenv_refresh:
	$(V) $(ECHO) "$(YELLOW)Updating all the repositories on the developer environment...$(GRAY)"
	$(V) while read repo ; do \
	  echo -e "\nUpdating src/$$repo" ; \
	  pushd . >/dev/null ; \
	  cd src/$$repo ; \
	  git pull --rebase || $(ECHO) "${RED}WARNING: git pull failed, skipping this error$(GRAY)" ; \
	  popd >/dev/null ; \
	done < .devenv
	$(V) $(ECHO) "\n$(GREEN)Update completed$(GRAY)"

# Git support
.PHONY: git_pull
git_pull: header
	$(V)$(ECHO) "Updating the base git repository..."
	$(V)git pull --rebase || $(ECHO) "${RED}WARNING: git pull failed, skipping this error$(GRAY)"
	$(V)for gitpath in `find yocto/ -maxdepth 2 -name .git` ; do \
	   repo=`dirname $$gitpath` ; \
	   $(ECHO) "\nUpdating the $$repo git repository..." ; \
	   pushd . >/dev/null ; \
	   cd $$repo ; \
	   git pull --rebase || $(ECHO) "${RED}WARNING: git pull failed, skipping this error$(GRAY)" ; \
	   popd >/dev/null ; \
	 done
	$(V)if test -f .devenv ; then \
	  echo ; $(MAKE) _devenv_refresh ; \
	 else \
	  $(ECHO) "\n$(GREEN)Update completed$(GRAY)" ; \
	 fi

.PHONY: devenv_ct_init devenv_ct_test
devenv_ct_init: dev_header
	$(call BITBAKE,halon-vsi-native)
	/bin/cp tools/pytest.ini src/pytest.ini

$(eval $(call PARSE_ARGUMENTS, devenv_ct_test))
PY_TEST_ARGS:=$(EXTRA_ARGS)
ifeq ($(PY_TEST_ARGS),)
PY_TEST_ARGS=src
endif
devenv_ct_test:
	$(SUDO) $(PYTEST_NATIVE) $(PY_TEST_ARGS)

## Support commands
## Use with caution!!!!

$(eval $(call PARSE_ARGUMENTS,share_screen_with))
USERTOSHARE?=$(EXTRA_ARGS)
ifneq ($(findstring share_screen_with,$(MAKECMDGOALS)),)
  ifeq ($(USERTOSHARE),)
   $(error ====== USERTOSHARE variable is empty, please specify an user =====)
  endif
endif
share_screen_with:
	$(V) $(ECHO) "Enabling shared console with user: $(USERTOSHARE)..."
	$(V) $(ECHO) "  Enabling suid in screen binary and fixing permissions, may need root password..."
	$(V) $(SUDO) chmod +s `which screen`
	$(V) $(SUDO) chmod g-w /var/run/screen
	$(V) $(ECHO) "  Starting shared screen session..."
	$(V) screen -d -m -S shared-with-$(USERTOSHARE) ; \
	 sleep 1 ; \
	 screen -x shared-with-$(USERTOSHARE) -X multiuser on ; \
	 screen -x shared-with-$(USERTOSHARE) -X acladd $(USERTOSHARE) ; \
	 screen -x shared-with-$(USERTOSHARE) -r
	$(V) $(ECHO) "  Disabling suid and restoring permissions..."
	$(V) $(SUDO) chmod -s `which screen`
	$(V) $(SUDO) chmod g+w /var/run/screen

$(eval $(call PARSE_ARGUMENTS,attach_screen_with))
USERTOSHARE?=$(EXTRA_ARGS)
ifneq ($(findstring attach_screen_with,$(MAKECMDGOALS)),)
  ifeq ($(USERTOSHARE),)
    $(error ====== USERTOSHARE variable is empty, please specify an user =====)
  endif
endif
attach_screen_with:
	$(V)$(ECHO) "Attaching to a shared screen by user: $(USERTOSHARE)..."
	$(V)screen -x $(USERTOSHARE)/shared-with-$(USER)
	$(V)$(ECHO) "Leaving shared screen"
