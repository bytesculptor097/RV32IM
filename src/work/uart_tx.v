// 8N1 UART Module, transmit only with baud rate control
module uart_tx_8n1 (
    input wire clk,           // input clock
    input wire [7:0] txbyte,  // outgoing byte
    input wire senddata,      // trigger tx
    output reg txdone,        // outgoing byte sent
    output wire tx            // tx wire
);

    // Parameters
    localparam STATE_IDLE    = 8'd0;
    localparam STATE_STARTTX = 8'd1;
    localparam STATE_TXING   = 8'd2;
    localparam STATE_TXDONE  = 8'd3;

    // Baud rate divider (for 9600 baud @ 50 MHz)
    localparam BAUD_DIV = 5208; // 50_000_000 / 9600

    reg [12:0] baud_counter = 0;
    reg baud_tick = 0;

    // State variables
    reg [7:0] state     = 8'b0;
    reg [7:0] buf_tx    = 8'b0;
    reg [3:0] bits_sent = 4'b0;
    reg txbit           = 1'b1;

    // Wiring
    assign tx = txbit;

    // Baud rate tick generator
    always @(posedge clk) begin
        if (state == STATE_IDLE) begin
            baud_counter <= 0;
            baud_tick <= 0;
        end else begin
            if (baud_counter == BAUD_DIV - 1) begin
                baud_counter <= 0;
                baud_tick <= 1;
            end else begin
                baud_counter <= baud_counter + 1;
                baud_tick <= 0;
            end
        end
    end

    // UART FSM with baud control
    always @(posedge clk) begin
        if (senddata == 1 && state == STATE_IDLE) begin
            state     <= STATE_STARTTX;
            buf_tx    <= txbyte;
            txdone    <= 1'b0;
            bits_sent <= 0;
        end else if (state == STATE_IDLE) begin
            txbit  <= 1'b1;
            txdone <= 1'b0;
        end

        if (baud_tick) begin
            case (state)
                STATE_STARTTX: begin
                    txbit <= 1'b0; // Start bit
                    state <= STATE_TXING;
                end

                STATE_TXING: begin
                    if (bits_sent < 8) begin
                        txbit     <= buf_tx[0];
                        buf_tx    <= buf_tx >> 1;
                        bits_sent <= bits_sent + 1;
                    end else begin
                        txbit     <= 1'b1; // Stop bit
                        bits_sent <= 0;
                        state     <= STATE_TXDONE;
                    end
                end

                STATE_TXDONE: begin
                    txdone <= 1'b1;
                    state  <= STATE_IDLE;
                end
            endcase
        end
    end

    // Debug message
    always @(posedge clk) begin
        if (txdone) begin
            $display("UART FSM: txdone asserted, byte sent");
        end
    end

endmodule