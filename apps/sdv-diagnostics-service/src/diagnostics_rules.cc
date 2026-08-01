#include "src/diagnostics_rules.h"

namespace sdv {

namespace {
constexpr double kLowBatterySocThreshold = 15.0;
constexpr double kOverspeedThreshold = 130.0;
}  // namespace

std::vector<std::string> EvaluateDiagnostics(const SignalStore& store) {
  std::vector<std::string> codes;

  double soc = 0.0;
  if (store.Get("Vehicle.Powertrain.Battery.StateOfCharge", &soc) &&
      soc < kLowBatterySocThreshold) {
    codes.push_back("DTC_LOW_BATTERY_SOC");
  }

  double speed = 0.0;
  if (store.Get("Vehicle.Speed", &speed) && speed > kOverspeedThreshold) {
    codes.push_back("DTC_OVERSPEED");
  }

  return codes;
}

}  // namespace sdv
