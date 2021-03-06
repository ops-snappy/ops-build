SUMMARY = "OpenSwitch System Daemon (sysd)"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

DEPENDS = "ops-utils ops-hw-config ops-ovsdb ops-cli ops-supportability"
RDEPENDS_${PN} = "dmidecode"

SRC_URI = "git://git.openswitch.net/openswitch/ops-sysd;protocol=https;branch=rel/dill \
           file://ops-sysd-snappy.patch \
           file://ops-sysd.service \
"

SRCREV = "7e4cc9cadc9e574e3dca7a954039fcf4e45459a3"

# When using AUTOREV, we need to force the package version to the revision of git
# in order to avoid stale shared states.
PV = "git${SRCPV}"

S = "${WORKDIR}/git"

do_install_append() {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/ops-sysd.service ${D}${systemd_unitdir}/system
    # Code to copy System custom validators to /usr/share/opsplugins.
    install -d ${D}/usr/share/opsplugins
    for plugin in $(find ${S}/opsplugins -name "*.py"); do \
        install -m 0644 ${plugin} ${D}/usr/share/opsplugins
    done
}

FILES_${PN} += "/usr/lib/cli/plugins/ /usr/share/opsplugins"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE_${PN} = "ops-sysd.service"

EXTRA_OECMAKE+="${@bb.utils.contains('MACHINE_FEATURES', 'ops-container', '-DUSE_SW_FRU=ON', '',d)}"

inherit openswitch cmake systemd pkgconfig
