#include <device.hh>

Device::Device(bool cacheable): cacheable_(cacheable) {}

bool Device::is_cacheable() { return cacheable_; }