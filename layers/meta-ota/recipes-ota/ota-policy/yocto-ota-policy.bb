SUMMARY = "OTA policy package"
DESCRIPTION = "Installs OTA policy placeholders for A/B update safety"
LICENSE = "MIT"
PR = "r0"

SRC_URI = "file://ota-policy.conf"
S = "${WORKDIR}"

do_install() {
    install -d ${D}${sysconfdir}/yocto-ota
    install -m 0644 ${WORKDIR}/ota-policy.conf ${D}${sysconfdir}/yocto-ota/ota-policy.conf
}

FILES:${PN} += "${sysconfdir}/yocto-ota/ota-policy.conf"
