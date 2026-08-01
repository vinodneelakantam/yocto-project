// Diagnostic threshold rules for the SDV diagnostics service.
//
// Pure / side-effect-free so it is independently unit-testable without a
// live signal source, and reuses //libs/vss-common:signal_store rather than
// forking its own copy — see docs/bazel-build-system.md.

#ifndef SDV_DIAGNOSTICS_SERVICE_DIAGNOSTICS_RULES_H_
#define SDV_DIAGNOSTICS_SERVICE_DIAGNOSTICS_RULES_H_

#include <string>
#include <vector>

#include "signal_store.h"

namespace sdv {

// Evaluates a fixed set of threshold rules against the signal store and
// returns the diagnostic trouble codes (DTC-style) that fired.
std::vector<std::string> EvaluateDiagnostics(const SignalStore& store);

}  // namespace sdv

#endif  // SDV_DIAGNOSTICS_SERVICE_DIAGNOSTICS_RULES_H_
