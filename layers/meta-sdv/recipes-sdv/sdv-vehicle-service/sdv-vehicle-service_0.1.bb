SUMMARY = "SDV vehicle-signal service (Bazel C++/Python)"
DESCRIPTION = "A small COVESA VSS / Eclipse KUKSA-style Software-Defined-Vehicle \
service built with Bazel.  Demonstrates cross-compiling a Bazel C/C++/Python \
application against the Yocto SDK toolchain and packaging it into the image. \
The same Bazel structure scales up to a large C++ codebase (e.g. Apollo)."
HOMEPAGE = "https://github.com/vinodneelakantam/yocto-project"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# ── Source ─────────────────────────────────────────────────────────────────
# The Bazel workspace that contains apps/sdv-vehicle-service.  By default this
# is the project repository itself; pin SRCREV to a known-good commit.  Override
# SDV_APP_GIT_URI / SRCREV to track a fork or a downstream application repo.
SDV_APP_GIT_URI ?= "git://github.com/vinodneelakantam/yocto-project.git;protocol=https;branch=main"
SRC_URI = "${SDV_APP_GIT_URI} \
           file://sdv-vehicle-service.service"

# Pin to a real commit for reproducible builds.  AUTOREV is allowed only as an
# explicit opt-in (SDV_ALLOW_AUTOREV=1); otherwise the build fails fast so a
# floating revision never slips into an image.
SRCREV ?= "${AUTOREV}"
SDV_ALLOW_AUTOREV ?= "0"
PV = "0.1+git${SRCPV}"

python () {
    if d.getVar('SRCREV') == 'AUTOREV' and d.getVar('SDV_ALLOW_AUTOREV') != '1':
        bb.fatal("sdv-vehicle-service: SRCREV is AUTOREV. Pin SRCREV to a commit "
                 "for reproducible builds, or set SDV_ALLOW_AUTOREV=1 to override.")
}

S = "${WORKDIR}/git"

# Bazel package label and the directory of the app within the workspace.
SDV_BAZEL_PACKAGE ?= "//apps/sdv-vehicle-service"
SDV_APP_SUBDIR ?= "apps/sdv-vehicle-service"

# ── Build tooling ────────────────────────────────────────────────────────────
# Bazel is NOT a Yocto-native dependency here; it is provided on the build host
# (devcontainer / worker) by scripts/bootstrap-worker-packages.sh as Bazelisk.
# The cross toolchain is injected from this recipe's environment: BitBake already
# exports CC/CXX/CFLAGS/CXXFLAGS/LDFLAGS for the target, and the shared .bazelrc
# `--config=yocto-cross` profile forwards them into Bazel actions.
inherit systemd

# Bazel manages its own parallelism and does not use the autotools/make flow.
do_configure[noexec] = "1"

# Keep all Bazel state inside the recipe work directory so builds are isolated
# and reproducible.  --distdir lets the build run with BB_NO_NETWORK by serving
# pre-fetched external module archives from a local mirror (see
# docs/sdv-bazel-app.md, "Offline dependency strategy").
SDV_BAZEL_OUTPUT_BASE = "${WORKDIR}/bazel-output-base"
SDV_BAZEL_DISTDIR ?= "${DL_DIR}/bazel-distdir"

export CC
export CXX
export CFLAGS
export CXXFLAGS
export LDFLAGS

do_compile() {
    if ! command -v bazel >/dev/null 2>&1; then
        bbfatal "bazel/bazelisk not found on the build host. Run scripts/bootstrap-worker-packages.sh."
    fi

    distdir_arg=""
    if [ -d "${SDV_BAZEL_DISTDIR}" ]; then
        distdir_arg="--distdir=${SDV_BAZEL_DISTDIR}"
    fi

    cd "${S}"
    bazel --output_base="${SDV_BAZEL_OUTPUT_BASE}" \
        build \
        --config=yocto-cross \
        ${distdir_arg} \
        "${SDV_BAZEL_PACKAGE}:sdv-vehicle-service" \
        "${SDV_BAZEL_PACKAGE}:vehicle-cli"
}

do_install() {
    install -d ${D}${bindir}

    # C++ service binary produced by Bazel.
    install -m 0755 ${S}/bazel-bin/${SDV_APP_SUBDIR}/sdv-vehicle-service \
        ${D}${bindir}/sdv-vehicle-service

    # Python CLI: install the source module and a thin launcher so it runs on
    # the target's python3 without Bazel's runfiles wrapper.
    install -d ${D}${libdir}/sdv-vehicle-service
    install -m 0644 ${S}/${SDV_APP_SUBDIR}/python/vehicle_cli.py \
        ${D}${libdir}/sdv-vehicle-service/vehicle_cli.py
    cat > ${D}${bindir}/vehicle-cli <<EOF
#!/bin/sh
exec /usr/bin/env python3 ${libdir}/sdv-vehicle-service/vehicle_cli.py "\$@"
EOF
    chmod 0755 ${D}${bindir}/vehicle-cli

    # systemd service unit.
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/sdv-vehicle-service.service \
        ${D}${systemd_system_unitdir}/sdv-vehicle-service.service
}

SYSTEMD_SERVICE:${PN} = "sdv-vehicle-service.service"
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN} += "python3-core"

FILES:${PN} += " \
    ${bindir}/sdv-vehicle-service \
    ${bindir}/vehicle-cli \
    ${libdir}/sdv-vehicle-service \
    ${systemd_system_unitdir}/sdv-vehicle-service.service \
"

# Bazel-built binaries already encode the cross toolchain's build-id handling;
# do not attempt host-style debug splitting on prebuilt outputs.
INSANE_SKIP:${PN} += "ldflags"
