// SDV vehicle-signal store.
//
// A tiny, dependency-free in-memory key/value store keyed by COVESA VSS-style
// signal paths (e.g. "Vehicle.Speed").  It stands in for a real KUKSA-style
// data broker so the Bazel + Yocto integration can be demonstrated end to end
// without pulling a large dependency tree.

#ifndef SDV_VEHICLE_SERVICE_SIGNAL_STORE_H_
#define SDV_VEHICLE_SERVICE_SIGNAL_STORE_H_

#include <map>
#include <string>

namespace sdv {

// Thread-compatible (not thread-safe) store of vehicle signals.
class SignalStore {
 public:
  // Sets the value for a VSS-style signal path, overwriting any prior value.
  void Set(const std::string& path, double value);

  // Returns true and fills *value when the path exists, false otherwise.
  bool Get(const std::string& path, double* value) const;

  // Number of distinct signal paths currently stored.
  std::size_t Size() const;

 private:
  std::map<std::string, double> signals_;
};

}  // namespace sdv

#endif  // SDV_VEHICLE_SERVICE_SIGNAL_STORE_H_
