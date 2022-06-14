module port_fsm (
    input wire          clk,
    input wire          reset,
    input wire  [7:0]   mem0,
    input wire  [7:0]   mem1,
    input wire  [7:0]   mem2,
    input wire  [7:0]   mem3,
    input wire          ffee,
    input wire          hold,
    input wire          data_status,
    output wire [3:0]   write_enb,
    input wire  [7:0]   data_in,
    output reg  [7:0]   addr,
    output reg  [7:0]   data_out
);

    reg [3:0]   write_enb_r;
    reg         fsm_write_enb;
    reg [3:0]   state_r;
    reg [3:0]   state;
    reg [7:0]   parity;
    reg [7:0]   parity_delayed;
    reg         sus_data_in;
    reg         error;

    parameter ADDR_WAIT     = 4'd0;
    parameter DATA_LOAD     = 4'd1;
    parameter PARITY_LOAD   = 4'd2;
    parameter HOLD_STATE    = 4'd3;
    parameter BUSY_STATE    = 4'd4;

    always@(negedge reset) begin
        error           = 1'd0;
        data_out        = 8'd0;
        addr            = 8'd0;
        write_enb_r     = 3'd0;
        fsm_write_enb   = 1'd0;
        state_r         = 4'd0;
        state           = 4'd0;
        parity          = 8'd0;
        parity_delayed  = 8'd0;
        sus_data_in     = 1'd0;
    end

    assign busy = sus_data_in;
    
    always @(data_status) begin : addr_mux
        if (data_status == 1'b1) begin
            case (data_in)
                mem0: begin
                    write_enb_r[0] = 1'b1;
                    write_enb_r[1] = 1'b0;
                    write_enb_r[2] = 1'b0;
                    write_enb_r[3] = 1'b0;
                end
                mem1: begin
                    write_enb_r[0] = 1'b0;
                    write_enb_r[1] = 1'b1;
                    write_enb_r[2] = 1'b0;
                    write_enb_r[3] = 1'b0;
                end
                mem2: begin
                    write_enb_r[0] = 1'b0;
                    write_enb_r[1] = 1'b0;
                    write_enb_r[2] = 1'b1;
                    write_enb_r[3] = 1'b0;
                end
                mem3: begin
                    write_enb_r[0] = 1'b0;
                    write_enb_r[1] = 1'b0;
                    write_enb_r[2] = 1'b0;
                    write_enb_r[3] = 1'b1;
                end
                default :write_enb_r = 3'b000;
            endcase
            // $display(" data_inii %d ,mem0 %d ,mem1 %d ,mem2 %d mem3",data_in,mem0,mem1,mem2,mem3);
        end //if
    end //addr_mux;

    always @(posedge clk) begin : fsm_state
        state_r <= state;
    end //fsm_state;

    always @(state_r or data_status or ffee or hold or data_in) begin : fsm_core
        state = state_r; //Default state assignment

        case (state_r) 
            ADDR_WAIT : begin
                if ((data_status == 1'b1) && 
                    ((mem0 == data_in)||(mem1 == data_in)||(mem3 == data_in) ||(mem2 == data_in))) begin
                    if (ffee == 1'b1)
                        state = DATA_LOAD;
                    else
                        state = BUSY_STATE;
                end
                sus_data_in = !ffee;
                if ((data_status == 1'b1) && 
                    ((mem0 == data_in)||(mem1 == data_in)||(mem3 == data_in) ||(mem2 == data_in)) && 
                    (ffee == 1'b1)) begin
                    addr = data_in;
                    data_out = data_in;
                    fsm_write_enb = 1'b1;
                end
                else begin
                    fsm_write_enb = 1'b0;
                end
            end //ADDR_WAIT
            
            PARITY_LOAD : begin
                state = ADDR_WAIT;
                data_out = data_in;
                fsm_write_enb = 1'b0;
            end //PARITY_LOAD
            
            DATA_LOAD : begin
                if ((data_status == 1'b1) && (hold == 1'b0)) begin
                    state = DATA_LOAD;
                end
                else if ((data_status == 1'b0) && (hold == 1'b0)) begin
                    state = PARITY_LOAD;
                end
                else begin
                    state = HOLD_STATE;
                end //if
                
                sus_data_in = 1'b0;
                
                if ((data_status == 1'b1) && (hold == 1'b0)) begin
                    data_out = data_in;
                    fsm_write_enb = 1'b1;
                end
                else if ((data_status == 1'b0) && (hold == 1'b0)) begin
                    data_out = data_in;
                    fsm_write_enb = 1'b1;
                end
                else begin
                    fsm_write_enb = 1'b0;
                end //if
            end //DATA_LOAD
            
            HOLD_STATE : begin
                if (hold == 1'b1) begin
                    state = HOLD_STATE;
                end
                else if ((hold == 1'b0) && (data_status == 1'b0)) begin
                    state = PARITY_LOAD;
                end
                else begin
                    state = DATA_LOAD;
                end //if
                if (hold == 1'b1) begin
                    sus_data_in = 1'b1;
                    fsm_write_enb = 1'b0;
                end
                else begin
                    fsm_write_enb = 1'b1;
                    data_out = data_in;
                end
            end //HOLD_STATE
            
            BUSY_STATE : begin
                if (ffee == 1'b0) begin
                    state = BUSY_STATE;
                end
                else begin
                    state = DATA_LOAD;
                end //if
                if (ffee == 1'b0) begin
                    sus_data_in = 1'b1;
                end
                else begin
                    addr = data_in;
                    data_out = data_in;
                    fsm_write_enb = 1'b1;
                end
            end //BUSY_STATE
        endcase
    end //fsm_core

    assign write_enb[0] = write_enb_r[0] & fsm_write_enb;
    assign write_enb[1] = write_enb_r[1] & fsm_write_enb;
    assign write_enb[2] = write_enb_r[2] & fsm_write_enb;
    assign write_enb[3] = write_enb_r[3] & fsm_write_enb;

endmodule