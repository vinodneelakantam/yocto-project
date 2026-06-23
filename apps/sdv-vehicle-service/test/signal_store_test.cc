// Unit tests for sdv::SignalStore.
//
// Dependency-free assertions (no GoogleTest) so the C++ test target builds
// with Bazel's native cc rules and needs no external fetches inside Yocto.

#include "src/signal_store.h"

#include <cstdio>
#include <cstdlib>

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
  Check(value == 7.0, "overwrite must update value");
  Check(store.Size() == 1, "overwrite must not grow store");

  // Get tolerates a null out pointer.
  Check(store.Get("Vehicle.Speed", nullptr), "null out pointer must be allowed");

  if (g_failures != 0) {
    std::fprintf(stderr, "%d assertion(s) failed\n", g_failures);
    return EXIT_FAILURE;
  }
  std::printf("all signal_store assertions passed\n");
  return EXIT_SUCCESS;
}
