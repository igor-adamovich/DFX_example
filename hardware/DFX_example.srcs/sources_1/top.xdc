#pcie_clk
create_clock -period 10.000 -name pcie_clk [get_ports pcie_clk_p]
set_property LOC IBUFDS_GTE2_X0Y2 [get_cells pcie.pcie_clk_buf]

#pcie_rstn
set_property IOSTANDARD LVCMOS33 [get_ports pcie_rstn]
set_property PULLTYPE PULLUP [get_ports pcie_rstn]
set_property PACKAGE_PIN M20 [get_ports pcie_rstn]

#ext_clk
set_property PACKAGE_PIN P16 [get_ports ext_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ext_clk]

#Define clocks
create_clock -period 11.111 -name ext_clk [get_ports ext_clk]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets config_core/core.clock/inst/clk_in_clk_wiz]
set_false_path -from [get_clocks userclk1] -to [get_clocks clk_out_clk_wiz]
set_false_path -from [get_clocks clk_out_clk_wiz] -to [get_clocks userclk1]

#Bit-file properties
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

create_pblock pblock_dummy.axis_dummy
add_cells_to_pblock [get_pblocks pblock_dummy.axis_dummy] [get_cells -quiet [list dummy.axis_dummy]]
resize_pblock [get_pblocks pblock_dummy.axis_dummy] -add {SLICE_X24Y231:SLICE_X49Y244}
resize_pblock [get_pblocks pblock_dummy.axis_dummy] -add {DSP48_X2Y94:DSP48_X2Y97}
resize_pblock [get_pblocks pblock_dummy.axis_dummy] -add {RAMB18_X2Y94:RAMB18_X2Y97}
resize_pblock [get_pblocks pblock_dummy.axis_dummy] -add {RAMB36_X2Y47:RAMB36_X2Y48}
set_property SNAPPING_MODE ON [get_pblocks pblock_dummy.axis_dummy]

