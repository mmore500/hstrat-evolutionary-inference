#include <iostream>

#include "Empirical/include/emp/base/vector.hpp"

#include "hei/config/Config.hpp"
#include "hei/config/setup_config_native.hpp"
#include "hei/example.hpp"

// This is the main function for the NATIVE version of hstrat Evolutionary Inference.

hei::Config cfg;

int main(int argc, char* argv[]) {
  // Set up a configuration panel for native application
  setup_config_native(cfg, argc, argv);
  cfg.Write(std::cout);

  std::cout << "Hello, world!" << "\n";

  return hei::example();
}
