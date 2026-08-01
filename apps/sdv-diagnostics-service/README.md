# SDV diagnostics service

A small, independent second Bazel-built SDV application that reuses
`//libs/vss-common` (the same VSS-style signal store used by
[sdv-vehicle-service](../sdv-vehicle-service)) instead of forking its own copy.

It exists to demonstrate a cleanly **partitioned** Bazel build graph: each
service is independently buildable/testable, while common code is shared
through one reusable library package. See
[docs/bazel-build-system.md](../../docs/bazel-build-system.md).

## Components

| Target | Language | Purpose |
|---|---|---|
| `//apps/sdv-diagnostics-service:sdv-diagnostics-service` | C++ | Service binary; evaluates threshold rules and prints active DTCs |
| `//apps/sdv-diagnostics-service:diagnostics_rules` | C++ | Pure threshold-rule library (low battery SoC, overspeed) |
| `//apps/sdv-diagnostics-service:diagnostics_rules_test` | C++ | Unit tests for the rules |

## Usage

```bash
bazel build //apps/sdv-diagnostics-service/...
bazel test  //apps/sdv-diagnostics-service/...
bazel run   //apps/sdv-diagnostics-service:sdv-diagnostics-service -- --once
```
