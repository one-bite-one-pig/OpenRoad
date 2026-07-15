# Positive-slack and unconstrained non-clock NDR nets must retain the vanilla
# resistance-aware filtering behavior.
source "helpers.tcl"
read_lef "sky130hs/sky130hs.tlef"
read_lef "sky130hs/sky130hs_std_cell.lef"
read_liberty "sky130hs/sky130hs_tt.lib"
read_def "critical_nets_percentage.def"

current_design gcd
create_clock -name core_clock -period 100.0 [get_ports clk]
set_input_delay 0.0 -clock core_clock \
  [delete_from_list [all_inputs] [get_ports clk]]
set_output_delay 0.0 -clock core_clock [all_outputs]
set_false_path -from [get_ports reset]
set_propagated_clock [get_clocks core_clock]

source "sky130hs/sky130hs.rc"
set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met5
estimate_parasitics -placement

create_ndr -name TEST_NDR \
  -spacing { li1 0.51 met1 0.42 met2 0.42 met3 0.9 met4 0.9 met5 4.8 } \
  -width { li1 0.34 met1 0.28 met2 0.28 met3 0.6 met4 0.6 met5 3.2 }
assign_ndr -ndr TEST_NDR -net req_rdy
assign_ndr -ndr TEST_NDR -net reset

set_nets_to_route {req_rdy reset}
set_routing_layers -signal met1-met5 -clock met3-met5
set_global_routing_layer_adjustment met1-met5 0.8
set_debug_level GRT resAware 1

with_output_to_variable route_log {
  global_route -resistance_aware
}
check "positive and unconstrained NDR nets are filtered" {
  regexp {Number of nets with resistance-aware strategy: 0 \(0\.00%\)} \
    $route_log
} 1

exit_summary
