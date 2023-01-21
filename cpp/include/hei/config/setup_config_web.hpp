#pragma once
#ifndef HEI_CONFIG_SETUP_CONFIG_WEB_HPP_INCLUDE
#define HEI_CONFIG_SETUP_CONFIG_WEB_HPP_INCLUDE

#include "Empirical/include/emp/config/ArgManager.hpp"
#include "Empirical/include/emp/web/UrlParams.hpp"
#include "Empirical/include/emp/web/web.hpp"

#include "Config.hpp"
#include "try_read_config_file.hpp"

namespace hei {

void setup_config_web(hei::Config & config)  {
  auto specs = emp::ArgManager::make_builtin_specs(&config);
  emp::ArgManager am(emp::web::GetUrlParams(), specs);
  hei::try_read_config_file(config, am);
}

} // namespace hei

#endif // #ifndef HEI_CONFIG_SETUP_CONFIG_WEB_HPP_INCLUDE
