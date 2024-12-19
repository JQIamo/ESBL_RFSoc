
module frequency_change_DMA (
    // AXI4Stream sink: Clock
		S_AXIS_ACLK,
		// AXI4Stream sink: Reset
		S_AXIS_ARESETN,
		// Ready to accept data in
		S_AXIS_TREADY,
		// Data in
		S_AXIS_TDATA,
		// Byte qualifier
		S_AXIS_TSTRB,
		// Indicates boundary of last packet
		S_AXIS_TLAST,
		// Data is in valid
		S_AXIS_TVALID,

        dac0_nco_freq,
        dac0_nco_phase,
        dac0_nco_phase_rst,
        dac0_nco_update_en,
        dac0_nco_update_busy,
        dac0_nco_update_req


);

parameter C_S_AXIS_TDATA_WIDTH = 64;


// AXI4Stream sink: Clock
input wire  S_AXIS_ACLK;
// AXI4Stream sink: Reset
input wire  S_AXIS_ARESETN;
// Ready to accept data in
output reg  S_AXIS_TREADY;
// Data in
input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA;
// Byte qualifier
input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB;
// Indicates boundary of last packet
input wire  S_AXIS_TLAST;
// Data is in valid
input wire  S_AXIS_TVALID;

output [47:0] dac0_nco_freq;
output reg [17:0] dac0_nco_phase = 0;
output reg dac0_nco_phase_rst = 0;
output reg [5:0] dac0_nco_update_en = 6'b000111; 
                                                // Bit 5: Enable write to phase reset
                                                // Bit 4: Enable write to NCO phase bits 17:16
                                                // Bit 3: Enable write to NCO phase bits 15:0
                                                // Bit 2: Enable write to NCO frequency bits 47:32
                                                // Bit 1: Enable write to NCO frequency bits 31:16
                                                // Bit 0: Enable write to NCO frequency bits 15:0
    
input [1:0 ] dac0_nco_update_busy; // bit 0 is the busy state of the NCO and bit 1 is used for multi-tile synchronization
output reg dac0_nco_update_req;

`define FC_idle 0
`define FC_transmit 1
`define FC_pulse 2
`define FC_wait 3

reg [1:0] state = `FC_idle;
reg [1:0] next_state = `FC_idle;
reg [7:0] timer = 0; 

wire nco_busy;
assign nco_busy = dac0_nco_update_busy[0];

assign dac0_nco_freq = S_AXIS_TDATA[47:0];

always @(*)
begin
    next_state = state;
    if (S_AXIS_ARESETN) begin
        case (state)
            `FC_idle:begin
                if (S_AXIS_TVALID &&  ~ nco_busy) next_state = `FC_pulse;
            end

            `FC_pulse:begin
                next_state = `FC_wait;
            end

            `FC_wait:begin
                if (nco_busy || (timer >= 200)) next_state = `FC_transmit;
            end

            `FC_transmit:begin
                if (~ nco_busy) next_state = `FC_idle;

            end

            default: begin
                next_state = `FC_idle;
            end

        endcase
    end
end



always @(posedge S_AXIS_ACLK)
begin
    state <= next_state;
end

always @(*)
begin
    dac0_nco_update_req = 0;
    S_AXIS_TREADY = 0;

    case (state)
            `FC_idle:begin
                S_AXIS_TREADY = 1;

            end

            `FC_pulse:begin
                dac0_nco_update_req = 1;
                S_AXIS_TREADY = 0;
            end

            `FC_wait:begin
                dac0_nco_update_req = 0;
                S_AXIS_TREADY = 0;
            end

            `FC_transmit:begin
                S_AXIS_TREADY = 0;
            end
            default:begin
                dac0_nco_update_req = 0;
                S_AXIS_TREADY = 0;
            end

        endcase
end



always @(posedge S_AXIS_ACLK)
begin
    if (state != next_state)
    timer <= 0;
    else
    timer <= timer + 1;

end




endmodule

