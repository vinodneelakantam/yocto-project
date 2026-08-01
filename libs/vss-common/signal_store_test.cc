// Unit tests for sdv::SignalStore.
//
// Dependency-free assertions (no GoogleTest) so the C++ test target builds
// with Bazel's native cc rules and needs no external fetches inside Yocto.

#include "signal_store.h"

#include <cstdio>

namespace {

int g_failures = 0;

void Check(bool condition, const char* message) {
  if (!condition) {
    std::fprintf(stderr, "FAIL: %s\n", message);
    ++g_failures;
  }
}

}  // namespace

int main() {
  sdv::SignalStore store;

  // Missing path returns false.
  double value = -1.0;
  Check(!store.Get("Vehicle.Speed", &value), "unset path must not be found");
  Check(store.Size() == 0, "empty store size must be 0");

  // Set then get round-trips the value.
  store.Set("Vehicle.Speed", 42.0);
  Check(store.Get("Vehicle.Speed", &value), "set path must be found");
  Check(value == 42.0, "value must round-trip");
  Check(store.Size() == 1, "size must be 1 after one set");

  // Overwrite updates in place without growing the store.
  store.Set("Vehicle.Speed", 7.0);
  Check(store.Get("Vehicle.Speed", &value), "overwritten path must be found");
  Check(value == 7.0, "overwritten value must round-trip");
  Check(store.Size() == 1, "size must stay 1 after overwrite");

  // A second, distinct path grows the store.
  store.Set("Vehicle.Powertrain.Battery.StateOfCharge", 87.5);
  Check(store.Size() == 2, "size must be 2 after a second distinct path");

  if (g_failures != 0) {
    std::fprintf(stderr, "%d check(s) failed\n", g_failures);
    return 1;
  }
  std::fprintf(stderr, "OK\n");
  return 0;
}
