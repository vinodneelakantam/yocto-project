SUMMARY = "SDV diagnostics service (Bazel C++)"
DESCRIPTION = "A small COVESA VSS-style diagnostics service built with Bazel. \
Reuses the same //libs/vss-common signal-store library as sdv-vehicle-service \
(no forked signal model), demonstrating that independently-built Bazel \
services can share one Yocto packaging pattern."
HOMEPAGE = "https://github.com/vinodneelakantam/yocto-project"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# ── Source ─────────────────────────────────────────────────────────────────
# Same Bazel workspace as sdv-vehicle-service (see that recipe for the full
# rationale). Override SDV_APP_GIT_URI / SRCREV to track a fork.
SDV_APP_GIT_URI ?= "gitsm://github.com/vinodneelakantam/yocto-project.git;protocol=https;branch=main"
SRC_URI = "${SDV_APP_GIT_URI} \
           file://sdv-diagnostics-service.service"

SRCREV ?= "${AUTOREV}"
SDV_ALLOW_AUTOREV ?= "0"
PV = "0.1+git${SRCPV}"

python () {
    if d.getVar('SRCREV') == 'AUTOREV' and d.getVar('SDV_ALLOW_AUTOREV') != '1':
        bb.fatal("sdv-diagnostics-service: SRCREV is AUTOREV. Pin SRCREV to a commit "
                 "for reproducible builds, or set SDV_ALLOW_AUTOREV=1 to override.")
}

S = "${WORKDIR}/git"

# Bazel package label and the directory of the app within the workspace.
SDV_BAZEL_PACKAGE ?= "//apps/sdv-diagnostics-service"
SDV_APP_SUBDIR ?= "apps/sdv-diagnostics-service"

inherit systemd

do_configure[noexec] = "1"

SDV_BAZEL_OUTPUT_BASE = "${WORKDIR}/bazel-output-base"
SDV_BAZEL_DISTDIR ?= "${DL_DIR}/bazel-distdir"

export CC
export CXX
export CFLAGS
export CXXFLAGS
export LDFLAGS

do_compile() {
    bazel_cmd=""
    if command -v bazel >/dev/null 2>&1; then
        bazel_cmd="bazel"
    elif command -v bazelisk >/dev/null 2>&1; then
        bazel_cmd="bazelisk"
    else
        bbfatal "bazel/bazelisk not found on the build host. Run scripts/bootstrap-worker-packages.sh."
    fi

    distdir_arg=""
    if [ -d "${SDV_BAZEL_DISTDIR}" ]; then
        distdir_arg="--distdir=${SDV_BAZEL_DISTDIR}"
    fi

    cd "${S}"
    ${bazel_cmd} --output_base="${SDV_BAZEL_OUTPUT_BASE}" \
        build \
        --config=yocto-cross \
        ${distdir_arg} \
        "${SDV_BAZEL_PACKAGE}:sdv-diagnostics-service"
}

do_install() {
    install -d ${D}${bindir}

    install -m 0755 ${S}/bazel-bin/${SDV_APP_SUBDIR}/sdv-diagnostics-service \
        ${D}${bindir}/sdv-diagnostics-service

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/sdv-diagnostics-service.service \
        ${D}${systemd_system_unitdir}/sdv-diagnostics-service.service
}

SYSTEMD_SERVICE:${PN} = "sdv-diagnostics-service.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} += " \
    ${bindir}/sdv-diagnostics-service \
    ${systemd_system_unitdir}/sdv-diagnostics-service.service \
"

# Bazel-built binaries already encode the cross toolchain's build-id handling;
# do not attempt host-style debug splitting on prebuilt outputs.
INSANE_SKIP:${PN} += "ldflags"
