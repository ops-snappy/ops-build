SUMMARY = "Mininet: Rapid Prototyping for Software Defined Networks"
HOMEPAGE = "http://mininet.org"
SECTION = "devel/python"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://LICENSE;md5=d9ccab8f5115cadad300993df353cd47"

SRC_URI = "git://github.com/mininet/mininet"
SRCREV = "2.2.1"

S = "${WORKDIR}/git"

inherit setuptools

RDEPENDS_${PN} += " \
    python-core python-re python-subprocess python-terminal python-math \
    python-textutils python-shell python-netclient python-logging python-readline \
"

RDEPENDS_${PN}_class-native = ""
RDEPENDS_${PN}_class-nativesdk = ""

BBCLASSEXTEND = "native nativesdk"