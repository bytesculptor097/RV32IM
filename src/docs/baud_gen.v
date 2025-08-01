module baud_rate_generator #(
    parameter CLOCK_FREQ = 50000000,  // 50 MHz system clock
    parameter BAUD_RATE = 9600        // Desired baud rate
)(
    input wire clk,                   // System clock
    output reg baud_tick              // Tick at baud rate
);

    // Calculate number of clock cycles per baud tick
    localparam integer BAUD_DIV = CLOCK_FREQ / BAUD_RATE;
    localparam integer CNT_WIDTH = $clog2(BAUD_DIV);

    reg [CNT_WIDTH-1:0] counter = 0;

    always @(posedge clk) begin
        if (counter == BAUD_DIV - 1) begin
            counter <= 0;
            baud_tick <= 1;
        end else begin
            counter <= counter + 1;
            baud_tick <= 0;
        end
    end

endmodule