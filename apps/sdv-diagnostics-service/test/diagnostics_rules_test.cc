// Unit tests for sdv::EvaluateDiagnostics.
//
// Dependency-free assertions (no GoogleTest), matching the style of
// libs/vss-common/signal_store_test.cc.

#include "src/diagnostics_rules.h"

#include <algorithm>
#include <cstdio>

namespace {

int g_failures = 0;

void Check(bool condition, const char* message) {
  if (!condition) {
    std::fprintf(stderr, "FAIL: %s\n", message);
    ++g_failures;
  }
}

bool Contains(const std::vector<std::string>& codes, const std::string& code) {
  return std::find(codes.begin(), codes.end(), code) != codes.end();
}

}  // namespace

int main() {
  {
    sdv::SignalStore store;
    const auto codes = sdv::EvaluateDiagnostics(store);
    Check(codes.empty(), "no signals set must yield no codes");
  }
  {
    sdv::SignalStore store;
    store.Set("Vehicle.Powertrain.Battery.StateOfCharge", 5.0);
    const auto codes = sdv::EvaluateDiagnostics(store);
    Check(Contains(codes, "DTC_LOW_BATTERY_SOC"), "low SoC must raise DTC_LOW_BATTERY_SOC");
  }
  {
    sdv::SignalStore store;
    store.Set("Vehicle.Speed", 200.0);
    const auto codes = sdv::EvaluateDiagnostics(store);
    Check(Contains(codes, "DTC_OVERSPEED"), "high speed must raise DTC_OVERSPEED");
  }
  {
    sdv::SignalStore store;
    store.Set("Vehicle.Powertrain.Battery.StateOfCharge", 5.0);
    store.Set("Vehicle.Speed", 200.0);
    const auto codes = sdv::EvaluateDiagnostics(store);
    Check(codes.size() == 2, "both rules can fire together");
  }

  if (g_failures != 0) {
    std::fprintf(stderr, "%d check(s) failed\n", g_failures);
    return 1;
  }
  std::fprintf(stderr, "OK\n");
  return 0;
}
