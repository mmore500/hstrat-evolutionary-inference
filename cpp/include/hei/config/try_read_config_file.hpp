#pragma once
#ifndef HEI_CONFIG_TRY_READ_CONFIG_FILE_HPP_INCLUDE
#define HEI_CONFIG_TRY_READ_CONFIG_FILE_HPP_INCLUDE

#include <cstdlib>
#include <filesystem>
#include <iostream>

#include "Config.hpp"

namespace hei {

void try_read_config_file(hei::Config & config, emp::ArgManager & am) {
  if(std::filesystem::exists("hei.cfg")) {
    std::cout << "Configuration read from hei.cfg" << '\n';
    config.Read("hei.cfg");
  }
  am.UseCallbacks();
  if (am.HasUnused())
    std::exit(EXIT_FAILURE);
}

} // namespace hei

#endif // #ifndef HEI_CONFIG_TRY_READ_CONFIG_FILE_HPP_INCLUDE
