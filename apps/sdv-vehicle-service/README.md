# SDV vehicle-signal service

A small, **COVESA VSS / Eclipse KUKSA-style** Software-Defined-Vehicle service,
built with **Bazel** to exercise the C/C++/Python toolchain and the Yocto
integration in this repository.

It is intentionally dependency-light (native Bazel `cc_*` rules + Python
standard library) so it builds with no external fetches — which keeps it
reproducible inside Yocto where the network is disabled during the build. The
same Bazel structure scales up to a large C++ codebase (e.g. Baidu Apollo)
later; see `docs/sdv-bazel-app.md`.

## Components

| Target | Language | Purpose |
|---|---|---|
| `//apps/sdv-vehicle-service:sdv-vehicle-service` | C++ | Service binary; seeds and prints VSS-style signals |
| `//apps/sdv-vehicle-service:signal_store` | C++ | In-memory VSS signal store library |
| `//apps/sdv-vehicle-service:signal_store_test` | C++ | Unit tests for the store |
| `//apps/sdv-vehicle-service:vehicle-cli` | Python | CLI to list/get VSS signals |
| `//apps/sdv-vehicle-service:vehicle_cli_test` | Python | Unit tests for the CLI |

## Inner loop (developer / devcontainer)

```bash
# Build everything
bazel build //apps/sdv-vehicle-service/...

# Run the C++ and Python tests
bazel test //apps/sdv-vehicle-service/...

# Run the service (single snapshot) and the CLI
bazel run //apps/sdv-vehicle-service:sdv-vehicle-service -- --once
bazel run //apps/sdv-vehicle-service:vehicle-cli -- list
bazel run //apps/sdv-vehicle-service:vehicle-cli -- get Vehicle.Speed
```

## Outer loop (Yocto image)

The recipe `layers/meta-sdv/recipes-sdv/sdv-vehicle-service` drives this same
Bazel build with the Yocto SDK cross toolchain and installs the service binary,
the Python CLI, and a systemd unit into the target image. See
`docs/sdv-bazel-app.md`.
