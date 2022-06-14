module fifo (
    input wire          clk,
    input wire          reset,
    input wire          write_enb,
    input wire          read,
    input wire  [7:0]   data_in,
    output reg  [7:0]   data_out,
    output wire         empty,
    output wire         full
);

    reg [7:0] ram [0:25];
    reg tmp_empty;
    reg tmp_full;
    integer write_ptr;
    integer read_ptr;

    always@(negedge reset) begin
        data_out    = 8'd0;
        tmp_empty   = 1'b1;
        tmp_full    = 1'b0;
        write_ptr   = 0;
        read_ptr    = 0;
    end
    
    always @(posedge clk) begin
        if ((write_enb == 1'b1) && (tmp_full == 1'b0)) begin
            ram[write_ptr] = data_in;
            tmp_empty <= 1'b0;
            write_ptr = (write_ptr + 1) % 16;
            if ( read_ptr == write_ptr )
                tmp_full <= 1'b1;
        end
        
        if ((read == 1'b1) && (tmp_empty == 1'b0)) begin
            data_out <= ram[read_ptr];
            tmp_full <= 1'b0;
            read_ptr = (read_ptr + 1) % 16;
            if ( read_ptr == write_ptr )
                tmp_empty <= 1'b1;
        end
    end

    assign empty = tmp_empty;
    assign full = tmp_full;

endmodule
