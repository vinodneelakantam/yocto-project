// SDV diagnostics service entry point.
//
// A second, independently-built service that reuses the shared
// //libs/vss-common signal store — demonstrating that the Bazel build graph
// is cleanly partitioned (each service builds/tests on its own) while still
// sharing common code. See docs/bazel-build-system.md and, for the sibling
// service, apps/sdv-vehicle-service.

#include <chrono>
#include <cstring>
#include <iostream>
#include <thread>

#include "signal_store.h"
#include "src/diagnostics_rules.h"

namespace {

void PrintReport(const sdv::SignalStore& store) {
  const auto codes = sdv::EvaluateDiagnostics(store);
  std::cout << "[sdv-diagnostics-service] " << codes.size() << " code(s) active\n";
  for (const auto& code : codes) {
    std::cout << "  " << code << "\n";
  }
  std::cout.flush();
}

}  // namespace

int main(int argc, char** argv) {
  bool once = false;
  for (int i = 1; i < argc; ++i) {
    if (std::strcmp(argv[i], "--once") == 0) {
      once = true;
    }
  }

  sdv::SignalStore store;
  store.Set("Vehicle.Speed", 0.0);
  // Seeded low so the demo prints an active DTC on the first snapshot.
  store.Set("Vehicle.Powertrain.Battery.StateOfCharge", 12.0);

  double speed = 0.0;
  do {
    speed += 20.0;
    if (speed > 150.0) {
      speed = 0.0;
    }
    store.Set("Vehicle.Speed", speed);
    PrintReport(store);
    if (once) {
      break;
    }
    std::this_thread::sleep_for(std::chrono::seconds(5));
  } while (true);

  return 0;
}
