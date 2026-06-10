SUMMARY = "Base package group for portfolio image"
DESCRIPTION = "Packages for a demonstrable Yocto portfolio baseline"
LICENSE = "MIT"
PR = "r0"

inherit packagegroup

RDEPENDS:${PN} = " \
    packagegroup-core-boot \
    openssh \
    ca-certificates \
"
