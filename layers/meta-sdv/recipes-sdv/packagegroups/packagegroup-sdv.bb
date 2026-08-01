SUMMARY = "Package group for SDV (Software-Defined-Vehicle) applications"
DESCRIPTION = "Bazel-built SDV applications to install into the target image"
LICENSE = "MIT"
PR = "r0"

inherit packagegroup

RDEPENDS:${PN} = " \
    sdv-vehicle-service \
    sdv-diagnostics-service \
"
