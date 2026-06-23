#include "src/signal_store.h"

namespace sdv {

void SignalStore::Set(const std::string& path, double value) {
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
