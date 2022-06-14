module switch (
    input wire          clk,
    input wire          reset,
    input wire          data_status,
    input wire  [7:0]   data,
    output wire [7:0]   port0,
    output wire [7:0]   port1,
    output wire [7:0]   port2,
    output wire [7:0]   port3,
    output wire         ready_0,
    output wire         ready_1,
    output wire         ready_2,
    output wire         ready_3,
    input wire          read_0,
    input wire          read_1,
    input wire          read_2,
    input wire          read_3,
    input wire          mem_en,
    input wire          mem_rd_wr,
    input wire  [1:0]   mem_add,
    input wire  [7:0]   mem_data
);

    wire [7:0]  data_out_0;
    wire [7:0]  data_out_1;
    wire [7:0]  data_out_2;
    wire [7:0]  data_out_3;
    wire        ll0;
    wire        ll1;
    wire        ll2;
    wire        ll3;
    wire        empty_0;
    wire        empty_1;
    wire        empty_2;
    wire        empty_3;
    wire        ffee;
    wire        ffee0;
    wire        ffee1;
    wire        ffee2;
    wire        ffee3;
    wire        ld0;
    wire        ld1;
    wire        ld2;
    wire        ld3;
    wire        hold;
    wire [3:0]  write_enb;
    wire [7:0]  data_out_fsm;
    wire [7:0]  addr;

    reg [7:0] mem [3:0];

    fifo queue_0 (
        .clk        (clk            ),
        .reset      (reset          ),
        .write_enb  (write_enb[0]   ),
        .read       (read_0         ),
        .data_in    (data_out_fsm   ),
        .data_out   (data_out_0     ),
        .empty      (empty_0        ),
        .full       (ll0            )
    );

    fifo queue_1 (
        .clk        (clk            ),
        .reset      (reset          ),
        .write_enb  (write_enb[1]   ),
        .read       (read_1         ),
        .data_in    (data_out_fsm   ),
        .data_out   (data_out_1     ),
        .empty      (empty_1        ),
        .full       (ll1            )
    );

    fifo queue_2 (
        .clk        (clk            ),
        .reset      (reset          ),
        .write_enb  (write_enb[2]   ),
        .read       (read_2         ),
        .data_in    (data_out_fsm   ),
        .data_out   (data_out_2     ),
        .empty      (empty_2        ),
        .full       (ll2            )
    );

    fifo queue_3 (
        .clk        (clk            ),
        .reset      (reset          ),
        .write_enb  (write_enb[3]   ),
        .read       (read_3         ),
        .data_in    (data_out_fsm   ),
        .data_out   (data_out_3     ),
        .empty      (empty_3        ),
        .full       (ll3            )
    );

    port_fsm in_port(
        .clk         (clk           ),
        .reset       (reset         ),
        .mem0        (mem[0]        ),
        .mem1        (mem[1]        ),
        .mem2        (mem[2]        ),
        .mem3        (mem[3]        ),
        .ffee        (ffee          ),
        .hold        (hold          ),
        .data_status (data_status   ),
        .write_enb   (write_enb     ),
        .data_in     (data          ),
        .addr        (addr          ),
        .data_out    (data_out_fsm  )
    );

    assign port0 = data_out_0; //make note assignment only for consistency with vlog env
    assign port1 = data_out_1;
    assign port2 = data_out_2;
    assign port3 = data_out_3;

    assign ready_0 = ~empty_0;
    assign ready_1 = ~empty_1;
    assign ready_2 = ~empty_2;
    assign ready_3 = ~empty_3;

    assign ffee0 = (empty_0 | ( addr != mem[0]));
    assign ffee1 = (empty_1 | ( addr != mem[1]));
    assign ffee2 = (empty_2 | ( addr != mem[2]));
    assign ffee3 = (empty_3 | ( addr != mem[3]));

    assign ffee = ffee0 & ffee1 & ffee2 & ffee3;

    assign ld0 = (ll0 & (addr == mem[0]));
    assign ld1 = (ll1 & (addr == mem[1]));
    assign ld2 = (ll2 & (addr == mem[2]));
    assign ld3 = (ll3 & (addr == mem[3]));

    assign hold = ld0 | ld1 | ld2 | ld3;

    always@(posedge clk) begin
        if(mem_en)
            if(mem_rd_wr) begin
                mem[mem_add]=mem_data;
                // $display("%d %d %d %d %d",mem_add,mem[0],mem[1],mem[2],mem[3]);
            end
    end

endmodule