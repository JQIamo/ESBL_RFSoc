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
add_files -norecurse ./hdl/phase_generator.v
add_files -norecurse ./hdl/frequency_change_DMA.v
update_compile_order -fileset sources_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 ./sim/esb_module_tb.v
update_compile_order -fileset sim_1

add_files -fileset sim_1 -norecurse ./sim/esb_module_tb_behav.wcfg
add_files -fileset sim_1 -norecurse ./sim/frequency_change_DMA_tb.sv
set_property xsim.view .sim/esb_module_tb_behav.wcfg [get_filesets sim_1]


update_compile_order -fileset sources_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.4 zynq_ultra_ps_e_0
endgroup

startgroup
create_bd_cell -type module -reference phase_generator phase_generator_0
endgroup


apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" } \
                                                                     [get_bd_cells zynq_ultra_ps_e_0]
set_property location {1 140 -248} [get_bd_cells zynq_ultra_ps_e_0]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:usp_rf_data_converter:2.6 usp_rf_data_converter_0
set_property -dict [list CONFIG.ADC0_Enable {0} \
                    CONFIG.ADC0_Fabric_Freq {0.0} \
                    CONFIG.ADC_Slice00_Enable {false} \
                    CONFIG.ADC_Decimation_Mode00 {0} \
                    CONFIG.ADC_Mixer_Type00 {3} \
                    CONFIG.ADC_RESERVED_1_00 {0} \
                    CONFIG.ADC_Slice01_Enable {false} \
                    CONFIG.ADC_Decimation_Mode01 {0} \
                    CONFIG.ADC_Mixer_Type01 {3} \
                    CONFIG.ADC_RESERVED_1_02 {0} \
                    CONFIG.ADC_OBS02 {0} \
                    CONFIG.DAC0_Enable {1} \
                    CONFIG.DAC0_PLL_Enable {true} \
                    CONFIG.DAC0_Sampling_Rate {9.85} \
                    CONFIG.DAC0_Refclk_Freq {307.813} \
                    CONFIG.DAC0_Outclk_Freq {307.813} \
                    CONFIG.DAC0_Fabric_Freq {307.813} \
                    CONFIG.DAC_Slice00_Enable {true} \
                    CONFIG.DAC_Interpolation_Mode00 {2} \
                    CONFIG.DAC_Mixer_Type00 {2} \
                    CONFIG.DAC_Mixer_Mode00 {0} \
                    CONFIG.DAC_Coarse_Mixer_Freq00 {3} \
                    CONFIG.DAC_Mode00 {1} \
                    CONFIG.DAC_RESERVED_1_00 {0} \
                    CONFIG.DAC_RESERVED_1_01 {0} \
                    CONFIG.DAC_RESERVED_1_02 {0} \
                    CONFIG.DAC_RESERVED_1_03 {0}] [get_bd_cells usp_rf_data_converter_0]

set_property -dict [list CONFIG.DAC0_Fabric_Freq {307.813} \
                         CONFIG.DAC_Data_Width00 {2} \
                         CONFIG.DAC_Interpolation_Mode00 {16}] [get_bd_cells usp_rf_data_converter_0]

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


startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0
endgroup

startgroup
set_property -dict [list CONFIG.IN0_WIDTH.VALUE_SRC USER CONFIG.IN1_WIDTH.VALUE_SRC USER] [get_bd_cells xlconcat_0]
set_property -dict [list CONFIG.IN0_WIDTH {16} CONFIG.IN1_WIDTH {16}] [get_bd_cells xlconcat_0]
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


connect_bd_net [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins usp_rf_data_converter_0/clk_dac0]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins usp_rf_data_converter_0/s0_axis_aresetn]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_0] [get_bd_pins phase_generator_0/f]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_1] [get_bd_pins phase_generator_0/multiplier]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_2] [get_bd_pins phase_generator_0/phase]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_3] [get_bd_pins phase_generator_0/i_amp]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_4] [get_bd_pins phase_generator_0/q_amp]
connect_bd_net [get_bd_pins ESBL_control_reg/reg_5] [get_bd_pins phase_generator_0/phase_PDH]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins usp_rf_data_converter_0/s00_axis_tvalid]
connect_bd_net [get_bd_pins phase_generator_0/i] [get_bd_pins xlconcat_0/In0]
connect_bd_net [get_bd_pins phase_generator_0/q] [get_bd_pins xlconcat_0/In1]
connect_bd_net [get_bd_pins usp_rf_data_converter_0/clk_dac0] [get_bd_pins phase_generator_0/sys_clk]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins usp_rf_data_converter_0/s00_axis_tdata]
connect_bd_net [get_bd_pins phase_generator_0/clr] [get_bd_pins xlconstant_1/dout]
connect_bd_net [get_bd_pins phase_generator_0/sys_rst] [get_bd_pins xlconstant_1/dout]


# This lowers the data converter sampling frequency so that the NCO can start without "error 7"
startgroup
set_property -dict [list CONFIG.DAC0_PLL_Enable {true}\
                         CONFIG.DAC0_Sampling_Rate {6.88128}\
                         CONFIG.DAC_Mode00 {0} \
                         CONFIG.DAC0_Refclk_Freq {491.520} \
                         CONFIG.DAC0_Outclk_Freq {430.080} \
                         CONFIG.DAC0_Fabric_Freq {430.080} \
                         CONFIG.DAC_RESERVED_1_00 {0} \
                         CONFIG.DAC_RESERVED_1_01 {0} \
                         CONFIG.DAC_RESERVED_1_02 {0} \
                         CONFIG.DAC_RESERVED_1_03 {0}] [get_bd_cells usp_rf_data_converter_0]
endgroup



set_property -dict [list CONFIG.DAC0_Sampling_Rate {6.88128} \
                         CONFIG.DAC0_Outclk_Freq {430.080} \
                         CONFIG.DAC0_Fabric_Freq {430.080}] [get_bd_cells usp_rf_data_converter_0]





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



startgroup

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
endgroup
set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_SI {2}] [get_bd_cells smartconnect_0]
set_property name axi_smc [get_bd_cells smartconnect_0]

set_property -dict [list CONFIG.PSU__USE__S_AXI_GP0 {1} CONFIG.PSU__USE__S_AXI_GP1 {1} ] [get_bd_cells zynq_ultra_ps_e_0]
endgroup

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {Auto} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_dma_0/S_AXI_LITE} ddr_seg {Auto} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_dma_0/S_AXI_LITE]

# startgroup
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {Auto} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_dma_0/M_AXI_MM2S} Slave {/zynq_ultra_ps_e_0/S_AXI_HPC1_FPD} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HPC1_FPD]

# endgroup

# delete_bd_objs [get_bd_addr_segs axi_dma_0/Data_MM2S/SEG_zynq_ultra_ps_e_0_HPC0_DDR_LOW]
# delete_bd_objs [get_bd_addr_segs axi_dma_0/Data_S2MM/SEG_zynq_ultra_ps_e_0_HPC0_DDR_LOW]
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






validate_bd_design
