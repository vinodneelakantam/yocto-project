// SDV vehicle-signal service entry point.
//
// Seeds a few COVESA VSS-style signals and prints a periodic snapshot.  On a
// Yocto target this runs as a systemd service (see layers/meta-sdv).  Use
// `--once` to print a single snapshot and exit (handy for CI smoke tests).

#include <chrono>
#include <cstring>
#include <iostream>
#include <thread>

#include "signal_store.h"

namespace {

void PrintSnapshot(const sdv::SignalStore& store) {
  const char* paths[] = {"Vehicle.Speed", "Vehicle.Powertrain.Battery.StateOfCharge",
                         "Vehicle.CurrentLocation.Heading"};
  std::cout << "[sdv-vehicle-service] snapshot (" << store.Size() << " signals)\n";
  for (const char* path : paths) {
    double value = 0.0;
    if (store.Get(path, &value)) {
      std::cout << "  " << path << " = " << value << "\n";
    }
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
  store.Set("Vehicle.Powertrain.Battery.StateOfCharge", 87.5);
  store.Set("Vehicle.CurrentLocation.Heading", 90.0);

  double speed = 0.0;
  do {
    speed += 5.0;
    if (speed > 120.0) {
      speed = 0.0;
    }
    store.Set("Vehicle.Speed", speed);
    PrintSnapshot(store);
    if (once) {
      break;
    }
    std::this_thread::sleep_for(std::chrono::seconds(5));
  } while (true);

  return 0;
}
