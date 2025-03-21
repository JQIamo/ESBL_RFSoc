module flag_manager(input [31:0] flag_int,
                    output wire software_DMA_trigger);

      assign software_DMA_trigger = flag_int[0];

endmodule