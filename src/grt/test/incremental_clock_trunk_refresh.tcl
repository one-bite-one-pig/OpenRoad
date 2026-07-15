# Verify that incremental clock topology changes refresh the FastRoute trunk
# classification used by the resistance-aware policy.
source "helpers.tcl"
read_liberty "sky130hs/sky130hs_tt.lib"
read_lef "sky130hs/sky130hs.tlef"
read_lef "sky130hs/sky130hs_std_cell.lef"
read_def "clock_route.def"

current_design gcd
create_clock -name core_clock -period 2.0 [get_ports clk]
set_propagated_clock [get_clocks core_clock]

set_global_routing_layer_adjustment met1 0.8
set_global_routing_layer_adjustment met2 0.7
set_global_routing_layer_adjustment * 0.5
set_routing_layers -signal met1-met5 -clock met3-met5

set_debug_level GRT resAware 2
global_route -resistance_aware

set block [ord::get_db_block]
set rebuffer1 [$block findInst rebuffer1]
set rebuffer2 [$block findInst rebuffer2]
set buffer_driver [$rebuffer1 findITerm X]
set buffer_sink [$rebuffer2 findITerm A]

global_route -start_incremental
set eco_clk [odb::dbNet_create $block eco_clk]
$eco_clk setSigType CLOCK
$buffer_driver disconnect
$buffer_sink disconnect
odb::dbITerm_connect $buffer_driver $eco_clk
odb::dbITerm_connect $buffer_sink $eco_clk
with_output_to_variable trunk_log {
  global_route -end_incremental -resistance_aware
}
check "new incremental clock net is a trunk" {
  regexp {Clock policy eco_clk: trunk=true} $trunk_log
} 1

set leaf_net [$block findNet clknet_2_0__leaf_clk]
set leaf_inst [$block findInst _614_]
set leaf_clk [$leaf_inst findITerm CLK]

global_route -start_incremental
$leaf_clk disconnect
odb::dbITerm_connect $leaf_clk $eco_clk
with_output_to_variable leaf_log {
  global_route -end_incremental -resistance_aware
}
check "clock net becomes a leaf after register sink is attached" {
  regexp {Clock policy eco_clk: trunk=false} $leaf_log
} 1

global_route -start_incremental
$leaf_clk disconnect
odb::dbITerm_connect $leaf_clk $leaf_net
with_output_to_variable restored_log {
  global_route -end_incremental -resistance_aware
}
check "clock net becomes a trunk after register sink is removed" {
  regexp {Clock policy eco_clk: trunk=true} $restored_log
} 1

exit_summary
