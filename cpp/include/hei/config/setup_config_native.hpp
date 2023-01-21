#pragma once
#ifndef HEI_CONFIG_SETUP_CONFIG_NATIVE_HPP_INCLUDE
#define HEI_CONFIG_SETUP_CONFIG_NATIVE_HPP_INCLUDE

#include "Empirical/include/emp/config/ArgManager.hpp"

#include "try_read_config_file.hpp"

namespace hei {

void setup_config_native(hei::Config & config, int argc, char* argv[]) {
  auto specs = emp::ArgManager::make_builtin_specs(&config);
  emp::ArgManager am(argc, argv, specs);
  hei::try_read_config_file(config, am);
}

} // namespace hei

#endif // #ifndef HEI_CONFIG_SETUP_CONFIG_NATIVE_HPP_INCLUDE
