module PMOD_adapter(input pdh,
                    output trigger,
                    inout PMOD0,
                    inout PMOD1);

         IOBUF pdh1 (
      //.O(O),   // 1-bit output: Buffer output
      .I(pdh),   // 1-bit input: Buffer input
      .IO(PMOD0), // 1-bit inout: Buffer inout (connect directly to top-level port)
      .T(1'b0)    // 1-bit input: 3-state enable input
   );

     IOBUF trig (
      .O(trigger),   // 1-bit output: Buffer output
      .I(1'b0),   // 1-bit input: Buffer input
      .IO(PMOD1), // 1-bit inout: Buffer inout (connect directly to top-level port)
      .T(1'b1)    // 1-bit input: 3-state enable input
   );
endmodule