#include "Catch/single_include/catch2/catch.hpp"
#include "Empirical/include/emp/base/array.hpp"

#include "sgpl/algorithm/execute_core.hpp"
#include "sgpl/hardware/Core.hpp"
#include "sgpl/library/OpLibrary.hpp"
#include "sgpl/operations/comparison/NotEqual.hpp"
#include "sgpl/program/Program.hpp"
#include "sgpl/spec/Spec.hpp"

// typedefs
using library_t = sgpl::OpLibrary<sgpl::NotEqual>;
struct spec_t : public sgpl::Spec<library_t> {
  static constexpr inline size_t num_registers{ 4 }; // eslint-disable-line no-eval
};

TEST_CASE("Test Not Equal, operands not equal") {

  const sgpl::Program<spec_t> program(R"(
    {
      "value0": [
        {
          "operation": "Not Equal",
          "args": {
            "value0": 2,
            "value1": 0,
            "value2": 1
          },
          "bitstring": "0000000000000000000000000000000000000000000000000000000000000000",
          "descriptors": []
        }
      ]
    }
  )");

  // define value constants
  const float operand1 = 97.f;
  const float operand2 = 3.f;

  sgpl::Core<spec_t> core( {operand1, operand2, {}, {}} );

  // execute single instruction
  sgpl::advance_core(core, program);

  // check final state
  REQUIRE(core.registers == emp::array<float, 4>{operand1, operand2, true, {}});

}

TEST_CASE("Test Not Equal, operands equal") {

  const sgpl::Program<spec_t> program(R"(
    {
      "value0": [
        {
          "operation": "Not Equal",
          "args": {
            "value0": 2,
            "value1": 0,
            "value2": 1
          },
          "bitstring": "0000000000000000000000000000000000000000000000000000000000000000",
          "descriptors": []
        }
      ]
    }
  )");

  // define value constants
  const float operand1 = 99.f;
  const float operand2 = 99.f;

  sgpl::Core<spec_t> core( {operand1, operand2, true, {}} );

  // execute single instruction
  sgpl::advance_core(core, program);

  // check final state
  REQUIRE(
    core.registers
    == emp::array<float, 4>{operand1, operand2, false, {}}
  );

}
