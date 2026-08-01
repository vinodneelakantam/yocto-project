#include "signal_store.h"

#ifdef SDV_VERBOSE_LOGGING
#include <cstdio>
#endif

namespace sdv {

void SignalStore::Set(const std::string& path, double value) {
#ifdef SDV_VERBOSE_LOGGING
  // Only compiled in for --config=debug; see tools/variants and
  // docs/bazel-build-system.md#variant-management.
  std::fprintf(stderr, "[signal_store] Set(%s, %g)\n", path.c_str(), value);
#endif
  signals_[path] = value;
}

bool SignalStore::Get(const std::string& path, double* value) const {
  auto it = signals_.find(path);
  if (it == signals_.end()) {
    return false;
  }
  if (value != nullptr) {
    *value = it->second;
  }
  return true;
}

std::size_t SignalStore::Size() const { return signals_.size(); }

}  // namespace sdv
