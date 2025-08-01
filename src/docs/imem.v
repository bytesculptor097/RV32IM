module ram (
    input wire clk,
    input wire we,
    input wire [31:0] addr,
    input wire [31:0] din,
    output reg [31:0] dout
);
    reg [31:0] mem [0:1023]; // 4KB RAM

    always @(posedge clk) begin
        if (we)
            mem[addr[11:2]] <= din;
        dout <= mem[addr[11:2]];
    end


    initial begin
      mem[0] = 32'h30152573;
      mem[1] = 32'h026281b3;
      mem[2] = 32'h0262c233;
      mem[3] = 32'h0262e3b3;
    end

endmodule
