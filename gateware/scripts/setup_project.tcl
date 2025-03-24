# Starting gui
start_gui


set_param board.repoPaths RFSoC4x2-BSP-2020.2/board_files/rfsoc4x2/1.0/
xhub::refresh_catalog [xhub::get_xstores xilinx_board_store]
create_project ESBL_RFSoC ./ESBL_RFSoC -part xczu48dr-ffvg1517-2-e
set_property board_part realdigital.org:rfsoc4x2:part0:1.0 [current_project]

create_bd_design "main"


# Add all the source files

add_files -norecurse ./hdl/syntactic_sugar.vh
add_files -norecurse ./hdl/arbitrary_registers.v
add_files -norecurse ./hdl/phase_generator_parallel.v
add_files -norecurse ./hdl/frequency_change_DMA.v
add_files -norecurse ./hdl/serializer_8_bits.v
add_files -norecurse ./hdl/flag_manager.v
update_compile_order -fileset sources_1

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 ./sim/esb_module_tb.v
update_compile_order -fileset sim_1

add_files -fileset sim_1 -norecurse ./sim/esb_module_tb_behav.wcfg
add_files -fileset sim_1 -norecurse ./sim/frequency_change_DMA_tb.sv
set_property xsim.view .sim/esb_module_tb_behav.wcfg [get_filesets sim_1]


add_files -fileset constrs_1 -norecurse ./constraints/4x2_PMOD.xdc


# Adding memory configuration files that are saved in the folder /hdl/lut/

<<<<<<< HEAD
set lutlist [dir ./hdl/lut/]
set lutroot [file normalize ./hdl/lut/]
foreach i $lutlist {add_files -norecurse ${lutroot}/${i} }
=======
set lutlist [glob -nocomplain ./hdl/lut/*]
foreach i $lutlist {add_files -norecurse [file normalize ${i}] }
>>>>>>> 371af6e (changed unsupported <dir> wit <glob> in TCL script)


update_compile_order -fileset sources_1





#Adding all the external ports used for triggers and for PDH outputs 

create_bd_port -dir I PMOD0_0
create_bd_port -dir I PMOD0_1
create_bd_port -dir O PMOD0_4
create_bd_port -dir O PMOD0_5


#Adding all blocks in design


startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.4 zynq_ultra_ps_e_0
endgroup

startgroup
create_bd_cell -type module -reference phase_generator_parallel phase_generator_0
endgroup

create_bd_cell -type module -reference flag_manager flag_manager_0
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1



apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" } \
                                                                     [get_bd_cells zynq_ultra_ps_e_0]

set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {and} CONFIG.LOGO_FILE {data/sym_orgate.png}] [get_bd_cells util_vector_logic_1]
set_property location {1 140 -248} [get_bd_cells zynq_ultra_ps_e_0]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:usp_rf_data_converter:2.6 usp_rf_data_converter_0
set_property -dict [list    CONFIG.DAC_NCO_RTS {true}  \
                            CONFIG.ADC0_Enable {0}  \
                            CONFIG.ADC0_Fabric_Freq {0.0}  \
                            CONFIG.ADC_Slice00_Enable {false}  \
                            CONFIG.ADC_Decimation_Mode00 {0}  \
                            CONFIG.ADC_Mixer_Type00 {3}  \
                            CONFIG.ADC_RESERVED_1_00 {false}  \
                            CONFIG.ADC_Slice01_Enable {false}  \
                            CONFIG.ADC_Decimation_Mode01 {0}  \
                            CONFIG.ADC_Mixer_Type01 {3}  \
                            CONFIG.ADC_RESERVED_1_02 {false}  \
                            CONFIG.ADC_OBS02 {false}  \
                            CONFIG.DAC0_Enable {1}  \
                            CONFIG.DAC0_PLL_Enable {true}  \
                            CONFIG.DAC0_Sampling_Rate {9.8304}  \
                            CONFIG.DAC0_Refclk_Freq {491.520}  \
                            CONFIG.DAC0_Outclk_Freq {307.200}  \
                            CONFIG.DAC0_Fabric_Freq {307.200}  \
                            CONFIG.DAC_Slice00_Enable {true}  \
                            CONFIG.DAC_Data_Width00 {2}  \
                            CONFIG.DAC_Interpolation_Mode00 {16}  \
                            CONFIG.DAC_Mixer_Type00 {2}  \
                            CONFIG.DAC_Mixer_Mode00 {0}  \
                            CONFIG.DAC_Invsinc_Ctrl00 {true}  \
                            CONFIG.DAC_Coarse_Mixer_Freq00 {3}  \
                            CONFIG.DAC_Mode00 {1}  \
                            CONFIG.DAC_RESERVED_1_00 {false}  \
                            CONFIG.DAC_RESERVED_1_01 {false}  \
                            CONFIG.DAC_RESERVED_1_02 {false}  \
                            CONFIG.DAC_RESERVED_1_03 {false}] [get_bd_cells usp_rf_data_converter_0]

endgroup

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto}
                                                          Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD}
                                                          Slave {/usp_rf_data_converter_0/s_axi} 
                                                          ddr_seg {Auto} 
                                                          intc_ip {New AXI Interconnect} 
                                                          master_apm {0}}  [get_bd_intf_pins usp_rf_data_converter_0/s_axi]


apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)}
                                                            Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} 
                                                            Master {/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD} 
                                                            Slave {/usp_rf_data_converter_0/s_axi}
                                                            ddr_seg {Auto} 
                                                            intc_ip {/ps8_0_axi_periph}
                                                            master_apm {0}}  [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD]
apply_bd_automation -rule xilinx.com:bd_rule:rf_converter_usp -config {ADC0_AXIS_SOURCE "Custom"
                                                                       DAC0_AXIS_SOURCE "Custom" }  [get_bd_cells usp_rf_data_converter_0]


startgroup
create_bd_cell -type module -reference arbitrary_registers ESBL_control_reg
endgroup



apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)}
                                                            Clk_slave {Auto}
                                                            Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)}
                                                            Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD}
                                                            Slave {/ESBL_control_reg/S_AXI}
                                                            ddr_seg {Auto}
                                                            intc_ip {/ps8_0_axi_periph}
                                                            master_apm {0}}  [get_bd_intf_pins ESBL_control_reg/S_AXI]



connect_bd_net [get_bd_pins usp_rf_data_converter_0/clk_dac0] [get_bd_pins usp_rf_data_converter_0/s0_axis_aclk]




save_bd_design
update_compile_order -fileset sources_1


startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
endgroup

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1
endgroup
set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells xlconstant_1]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
endgroup

startgroup
create_bd_cell -type module -reference serializer_8_bits serializer_8_bits_0
endgroup


startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
endgroup

startgroup
set_property -dict [list CONFIG.JITTER_SEL {Min_O_Jitter} \
                         CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {614.4} \
                         CONFIG.MMCM_DIVCLK_DIVIDE {7} \
                         CONFIG.MMCM_BANDWIDTH {HIGH} \
                         CONFIG.MMCM_CLKFBOUT_MULT_F {25.000} \
                         CONFIG.MMCM_CLKOUT0_DIVIDE_F {2.500} \
                         CONFIG.CLKOUT1_JITTER {73.951} \
                         CONFIG.CLKOUT1_PHASE_ERROR {121.275}] [get_bd_cells clk_wiz_0]
endgroup


connect_bd_net [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins usp_rf_data_converter_0/clk_dac0]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins usp_rf_data_converter_0/s0_axis_aresetn]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_0] [get_bd_pins phase_generator_0/f]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_1] [get_bd_pins phase_generator_0/multiplier]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_2] [get_bd_pins phase_generator_0/phase]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_3] [get_bd_pins phase_generator_0/i_amp]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_4] [get_bd_pins phase_generator_0/q_amp]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_5] [get_bd_pins phase_generator_0/phase_PDH]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins usp_rf_data_converter_0/s00_axis_tvalid]
connect_bd_net [get_bd_pins usp_rf_data_converter_0/clk_dac0] [get_bd_pins phase_generator_0/sys_clk]
connect_bd_net [get_bd_pins phase_generator_0/packed_output] [get_bd_pins usp_rf_data_converter_0/s00_axis_tdata]
connect_bd_net [get_bd_pins phase_generator_0/clr] [get_bd_pins xlconstant_1/dout]
connect_bd_net [get_bd_pins phase_generator_0/sys_rst] [get_bd_pins xlconstant_1/dout]
connect_bd_net [get_bd_ports PMOD0_4] [get_bd_pins serializer_8_bits_0/single_ended_out]
connect_bd_net [get_bd_pins phase_generator_0/pdh_output] [get_bd_pins serializer_8_bits_0/parallel_input]
connect_bd_net [get_bd_pins serializer_8_bits_0/slow_clock] [get_bd_pins usp_rf_data_converter_0/clk_dac0]
connect_bd_net [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins usp_rf_data_converter_0/clk_dac0]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins serializer_8_bits_0/fast_clock]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_reset] [get_bd_pins clk_wiz_0/reset]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_reset] [get_bd_pins serializer_8_bits_0/rst]

# Dummy Connection of Triggers and PDH outputs
# startgroup
# create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0
# endgroup
# set_property -dict [list CONFIG.C_SIZE {1}] [get_bd_cells util_vector_logic_0]
# connect_bd_net [get_bd_ports PMOD0_1] [get_bd_pins util_vector_logic_0/Op1]
# connect_bd_net [get_bd_ports PMOD0_0] [get_bd_pins util_vector_logic_0/Op2]
# connect_bd_net [get_bd_ports PMOD0_5] [get_bd_pins util_vector_logic_0/Res]






apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {Custom} Manual_Source {Auto}}  [get_bd_pins proc_sys_reset_0/ext_reset_in]


make_wrapper -files [get_files ./ESBL_RFSoC/ESBL_RFSoC.srcs/sources_1/bd/main/main.bd] -top
add_files -norecurse ./ESBL_RFSoC/ESBL_RFSoC.gen/sources_1/bd/main/hdl/main_wrapper.v
update_compile_order -fileset sources_1



# DMA addition
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0
endgroup

set_property -dict [list CONFIG.c_include_sg {0} \
                        CONFIG.c_sg_length_width {26} \
                        CONFIG.c_sg_include_stscntrl_strm {0} \
                        CONFIG.c_include_mm2s {1} \
                        CONFIG.c_m_axi_mm2s_data_width {64} \
                        CONFIG.c_m_axis_mm2s_tdata_width {64} \
                        CONFIG.c_mm2s_burst_size {16} \
                        CONFIG.c_include_s2mm {0} \
                        CONFIG.c_addr_width {32}] [get_bd_cells axi_dma_0]


apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {Auto} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_dma_0/S_AXI_LITE} ddr_seg {Auto} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_dma_0/S_AXI_LITE]

startgroup

set_property -dict [list CONFIG.PSU__USE__S_AXI_GP0 {1} CONFIG.PSU__USE__S_AXI_GP1 {1} ] [get_bd_cells zynq_ultra_ps_e_0]
endgroup


startgroup



apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/axi_dma_0/M_AXI_MM2S} Slave {/zynq_ultra_ps_e_0/S_AXI_HPC1_FPD} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HPC1_FPD]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {Auto} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_dma_0/M_AXI_MM2S} Slave {/zynq_ultra_ps_e_0/S_AXI_HPC0_FPD} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HPC0_FPD]



endgroup

delete_bd_objs [get_bd_addr_segs] [get_bd_addr_segs -excluded]
assign_bd_address

startgroup
set_property -dict [list CONFIG.DAC_NCO_RTS {true}] [get_bd_cells usp_rf_data_converter_0]
endgroup

create_bd_cell -type module -reference frequency_change_DMA frequency_change_DMA_0


delete_bd_objs [get_bd_intf_nets axi_dma_0_M_AXIS_MM2S]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] [get_bd_intf_pins frequency_change_DMA_0/S_AXIS]
connect_bd_net [get_bd_pins frequency_change_DMA_0/S_AXIS_ACLK] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
connect_bd_net [get_bd_pins frequency_change_DMA_0/S_AXIS_ARESETN] [get_bd_pins rst_ps8_0_99M/peripheral_aresetn]

connect_bd_net [get_bd_pins frequency_change_DMA_0/dac0_nco_freq] [get_bd_pins usp_rf_data_converter_0/dac00_nco_freq]
connect_bd_net [get_bd_pins frequency_change_DMA_0/dac0_nco_phase] [get_bd_pins usp_rf_data_converter_0/dac00_nco_phase]
connect_bd_net [get_bd_pins frequency_change_DMA_0/dac0_nco_phase_rst] [get_bd_pins usp_rf_data_converter_0/dac00_nco_phase_rst]
connect_bd_net [get_bd_pins frequency_change_DMA_0/dac0_nco_update_en] [get_bd_pins usp_rf_data_converter_0/dac00_nco_update_en]
connect_bd_net [get_bd_pins frequency_change_DMA_0/dac0_nco_update_req] [get_bd_pins usp_rf_data_converter_0/dac0_nco_update_req]
connect_bd_net [get_bd_pins frequency_change_DMA_0/dac0_nco_update_busy] [get_bd_pins usp_rf_data_converter_0/dac0_nco_update_busy]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_6] [get_bd_pins flag_manager_0/flag_int]
connect_bd_net [get_bd_ports PMOD0_0] [get_bd_pins util_vector_logic_1/Op2]
connect_bd_net [get_bd_pins util_vector_logic_1/Res] [get_bd_pins frequency_change_DMA_0/EX_TRIGGER]
connect_bd_net [get_bd_pins flag_manager_0/software_DMA_trigger] [get_bd_pins util_vector_logic_1/Op1]


# Modification to add DC offsets to the I Q components
# This should be only used only to test the effects of the impairments.

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:c_addsub:12.0 c_addsub_0
endgroup
copy_bd_objs /  [get_bd_cells {c_addsub_0}]
set_property location {6.5 3212 -463} [get_bd_cells c_addsub_0]
set_property location {6.5 3440 -458} [get_bd_cells c_addsub_1]
group_bd_cells offset_adder [get_bd_cells c_addsub_0] [get_bd_cells c_addsub_1]
set_property -dict [list CONFIG.B_Width.VALUE_SRC USER CONFIG.A_Width.VALUE_SRC USER CONFIG.B_Type.VALUE_SRC PROPAGATED] [get_bd_cells offset_adder/c_addsub_0]
set_property -dict [list CONFIG.Implementation {DSP48} CONFIG.A_Width {16} CONFIG.B_Width {16} CONFIG.Latency {2} CONFIG.A_Width {16} CONFIG.B_Width {16} CONFIG.Out_Width {16} CONFIG.Latency {2} CONFIG.B_Value {0000000000000000}] [get_bd_cells offset_adder/c_addsub_0]
delete_bd_objs [get_bd_cells offset_adder/c_addsub_1]
copy_bd_objs offset_adder  [get_bd_cells {offset_adder/c_addsub_0}]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 offset_adder/xlslice_0
endgroup
copy_bd_objs offset_adder  [get_bd_cells {offset_adder/xlslice_0}]
connect_bd_net [get_bd_pins offset_adder/xlslice_1/Din] [get_bd_pins offset_adder/xlslice_0/Din]
connect_bd_net [get_bd_pins offset_adder/xlslice_0/Dout] [get_bd_pins offset_adder/c_addsub_1/A]
connect_bd_net [get_bd_pins offset_adder/xlslice_1/Dout] [get_bd_pins offset_adder/c_addsub_0/A]
startgroup
set_property -dict [list CONFIG.DIN_FROM {31} CONFIG.DOUT_WIDTH {32}] [get_bd_cells offset_adder/xlslice_1]
endgroup
startgroup
set_property -dict [list CONFIG.DIN_FROM {15} CONFIG.DOUT_WIDTH {16}] [get_bd_cells offset_adder/xlslice_1]
endgroup
startgroup
set_property -dict [list CONFIG.DIN_TO {16} CONFIG.DIN_FROM {31} CONFIG.DOUT_WIDTH {16}] [get_bd_cells offset_adder/xlslice_0]
endgroup
set_property location {1 154 57} [get_bd_cells offset_adder/xlslice_1]
copy_bd_objs offset_adder  [get_bd_cells {offset_adder/xlslice_1}]
copy_bd_objs offset_adder  [get_bd_cells {offset_adder/xlslice_0}]
connect_bd_net [get_bd_pins offset_adder/xlslice_3/Dout] [get_bd_pins offset_adder/c_addsub_0/B]
connect_bd_net [get_bd_pins offset_adder/xlslice_2/Dout] [get_bd_pins offset_adder/c_addsub_1/B]
connect_bd_net [get_bd_pins offset_adder/xlslice_3/Din] [get_bd_pins offset_adder/xlslice_2/Din]
create_bd_pin -dir I -from 31 -to 0 offset_adder/I_Q
set_property location {-7 62} [get_bd_pins offset_adder/I_Q]
set_property location {-9 56} [get_bd_pins offset_adder/I_Q]
startgroup
copy_bd_objs offset_adder  [get_bd_pins {offset_adder/I_Q}]
set_property location {-17 57} [get_bd_pins offset_adder/I_Q1]
endgroup
delete_bd_objs [get_bd_pins offset_adder/I_Q1]
create_bd_pin -dir I offset_adder/OFFSETS
connect_bd_net [get_bd_pins offset_adder/I_Q] [get_bd_pins offset_adder/xlslice_1/Din]
connect_bd_net [get_bd_pins offset_adder/OFFSETS] [get_bd_pins offset_adder/xlslice_3/Din]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 offset_adder/xlconcat_0
endgroup
connect_bd_net [get_bd_pins offset_adder/xlconcat_0/In0] [get_bd_pins offset_adder/c_addsub_0/S]
connect_bd_net [get_bd_pins offset_adder/xlconcat_0/In1] [get_bd_pins offset_adder/xlconcat_0/dout]
undo
connect_bd_net [get_bd_pins offset_adder/c_addsub_1/S] [get_bd_pins offset_adder/xlconcat_0/In1]
create_bd_pin -dir O -from 31 -to 0 offset_adder/I_Q_OUT
connect_bd_net [get_bd_pins offset_adder/I_Q_OUT] [get_bd_pins offset_adder/xlconcat_0/dout]
startgroup
set_property -dict [list CONFIG.IN1_WIDTH.VALUE_SRC USER CONFIG.IN0_WIDTH.VALUE_SRC USER] [get_bd_cells offset_adder/xlconcat_0]
set_property -dict [list CONFIG.IN0_WIDTH {16} CONFIG.IN1_WIDTH {16}] [get_bd_cells offset_adder/xlconcat_0]
endgroup
startgroup
create_bd_pin -dir I offset_adder/CLK
connect_bd_net [get_bd_pins offset_adder/CLK] [get_bd_pins offset_adder/c_addsub_0/CLK]
endgroup
startgroup
connect_bd_net [get_bd_pins offset_adder/CLK] [get_bd_pins offset_adder/c_addsub_1/CLK]
endgroup
startgroup
create_bd_pin -dir I offset_adder/CE
connect_bd_net [get_bd_pins offset_adder/CE] [get_bd_pins offset_adder/c_addsub_0/CE]
endgroup
startgroup
connect_bd_net [get_bd_pins offset_adder/CE] [get_bd_pins offset_adder/c_addsub_1/CE]
endgroup
delete_bd_objs [get_bd_pins offset_adder/CE]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 offset_adder/xlconstant_0
endgroup
connect_bd_net [get_bd_pins offset_adder/xlconstant_0/dout] [get_bd_pins offset_adder/c_addsub_0/CE]
save_bd_design
update_compile_order -fileset sources_1
set_property location {6.5 3115 -84} [get_bd_cells offset_adder]
set_property location {4 1875 -635} [get_bd_cells offset_adder]
delete_bd_objs [get_bd_nets phase_generator_0_packed_output]
connect_bd_net [get_bd_pins phase_generator_0/packed_output] [get_bd_pins offset_adder/I_Q]
connect_bd_net [get_bd_pins offset_adder/CLK] [get_bd_pins usp_rf_data_converter_0/clk_dac0]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_7] [get_bd_pins offset_adder/OFFSETS]
connect_bd_net [get_bd_pins usp_rf_data_converter_0/s00_axis_tdata] [get_bd_pins usp_rf_data_converter_0/clk_dac0]
undo
connect_bd_net [get_bd_pins usp_rf_data_converter_0/s00_axis_tdata] [get_bd_pins offset_adder/I_Q_OUT]





validate_bd_design


