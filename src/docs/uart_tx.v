module uart_tx_8n1 #(
    parameter CLOCK_FREQ = 50000000,  // System clock frequency
    parameter BAUD_RATE = 9600        // Desired baud rate
)(
    input wire clk,                   // System clock
    input wire [7:0] txbyte,          // Byte to transmit
    input wire senddata,              // Trigger transmission
    output reg txdone,                // Transmission complete
    output wire tx                    // UART TX line
);

    // UART states
    localparam STATE_IDLE     = 2'd0;
    localparam STATE_START    = 2'd1;
    localparam STATE_DATA     = 2'd2;
    localparam STATE_STOP     = 2'd3;

    reg [1:0] state = STATE_IDLE;
    reg [7:0] shift_reg = 8'b0;
    reg [3:0] bit_count = 0;
    reg txbit = 1'b1;

    assign tx = txbit;

    // Baud rate generator
    wire baud_tick;
    baud_rate_generator #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_gen (
        .clk(clk),
        .baud_tick(baud_tick)
    );

    always @(posedge clk) begin
        if (senddata && state == STATE_IDLE) begin
            shift_reg <= txbyte;
            state <= STATE_START;
            txdone <= 1'b0;
        end
    end

    always @(posedge baud_tick) begin
        case (state)
            STATE_IDLE: begin
                txbit <= 1'b1;  // Idle line high
            end

            STATE_START: begin
                txbit <= 1'b0;  // Start bit
                state <= STATE_DATA;
                bit_count <= 0;
            end

            STATE_DATA: begin
                txbit <= shift_reg[0];
                shift_reg <= shift_reg >> 1;
                bit_count <= bit_count + 1;
                if (bit_count == 7)
                    state <= STATE_STOP;
            end

            STATE_STOP: begin
                txbit <= 1'b1;  // Stop bit
                txdone <= 1'b1;
                state <= STATE_IDLE;
            end
        endcase
    end

endmodule