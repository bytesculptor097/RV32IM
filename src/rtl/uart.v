module uart (
    input wire clk,
    input wire rst,

    // Transmit interface
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx,
    output reg tx_busy,

    // Receive interface
    input wire rx,
    output reg [7:0] rx_data,
    output reg rx_ready
);

    parameter CLK_FREQ = 50000000;
    parameter BAUD_RATE = 9600;
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // TX internal
    reg [15:0] tx_clk_count = 0;
    reg [3:0] tx_bit_index = 0;
    reg [9:0] tx_shift = 10'b1111111111;
    reg tx_sending = 0;

    // RX internal
    reg [15:0] rx_clk_count = 0;
    reg [3:0] rx_bit_index = 0;
    reg [7:0] rx_shift = 0;
    reg rx_receiving = 0;
    reg [15:0] rx_wait_count = 0;
    reg rx_sample = 0;

    // RX sync
    reg rx_sync_0, rx_sync_1;
    always @(posedge clk) begin
        rx_sync_0 <= rx;
        rx_sync_1 <= rx_sync_0;
    end

    // TX logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx <= 1'b1;
            tx_busy <= 0;
            tx_clk_count <= 0;
            tx_bit_index <= 0;
            tx_sending <= 0;
        end else begin
            if (tx_start && !tx_sending) begin
                tx_shift <= {1'b1, tx_data, 1'b0}; // Stop, data, start
                tx_sending <= 1;
                tx_busy <= 1;
                tx_clk_count <= 0;
                tx_bit_index <= 0;
            end else if (tx_sending) begin
                if (tx_clk_count < CLKS_PER_BIT - 1) begin
                    tx_clk_count <= tx_clk_count + 1;
                end else begin
                    tx_clk_count <= 0;
                    tx <= tx_shift[tx_bit_index];
                    tx_bit_index <= tx_bit_index + 1;

                    if (tx_bit_index == 9) begin
                        tx_sending <= 0;
                        tx_busy <= 0;
                        tx <= 1'b1;
                    end
                end
            end
        end
    end

    // RX logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_receiving <= 0;
            rx_ready <= 0;
            rx_clk_count <= 0;
            rx_bit_index <= 0;
            rx_wait_count <= 0;
        end else begin
            rx_ready <= 0;

            if (!rx_receiving && !rx_sync_1) begin
                // Start bit detected
                rx_receiving <= 1;
                rx_wait_count <= CLKS_PER_BIT + (CLKS_PER_BIT >> 1); // 1.5 bit times
                rx_bit_index <= 0;
            end else if (rx_receiving) begin
                if (rx_wait_count > 0) begin
                    rx_wait_count <= rx_wait_count - 1;
                end else begin
                    rx_shift[rx_bit_index] <= rx_sync_1;
                    rx_bit_index <= rx_bit_index + 1;

                    if (rx_bit_index == 7) begin
                        rx_data <= rx_shift;
                        rx_ready <= 1;
                        rx_receiving <= 0;
                    end else begin
                        rx_wait_count <= CLKS_PER_BIT - 1;
                    end
                end
            end
        end
    end
endmodule