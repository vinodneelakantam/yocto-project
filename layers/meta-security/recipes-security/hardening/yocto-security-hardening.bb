SUMMARY = "Security hardening policy package"
DESCRIPTION = "Installs baseline hardening configuration placeholders"
LICENSE = "MIT"
PR = "r0"

SRC_URI = "file://README.hardening"
S = "${WORKDIR}"

do_install() {
    install -d ${D}${sysconfdir}/yocto-security
    install -m 0644 ${WORKDIR}/README.hardening ${D}${sysconfdir}/yocto-security/README.hardening
}

FILES:${PN} += "${sysconfdir}/yocto-security/README.hardening"
