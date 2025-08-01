module regfile (
    input wire clk,
    input wire reg_write,
    input wire [4:0] rs1,
    input wire [4:0] rs2,
    input wire [4:0] rd,
    input wire [31:0] wd,
    output wire [31:0] rs1_val,
    output wire [31:0] rs2_val,
    output wire [31:0] x3_debug,
    output wire [31:0] x5_debug,
    output wire [31:0] x10_debug,
    output wire [31:0] x7_debug,
    output wire [31:0] x4_debug
);

    reg [31:0] regs [0:31];


    // Read logic
    assign rs1_val = regs[rs1];
    assign rs2_val = regs[rs2];

    // Write logic
    always @(posedge clk) begin
        if (reg_write && rd != 5'd0) begin
            regs[rd] <= wd;
            $display("WRITE: x%0d <= %h at time %0t", rd, wd, $time);
        end
    end

    // Debug outputs
    assign x3_debug = regs[3];
    assign x5_debug = regs[5];
    assign x10_debug = regs[10];
    assign x7_debug = regs[7];
    assign x4_debug = regs[4];

    integer i;
  initial begin

    for (i = 0; i < 32; i = i + 1) begin
        regs[i] = 32'b0; // Initialize all registers to zero
    end

    regs[5] = 32'd31;
    regs[6] = 32'd6;


end

    always @(posedge clk) begin
    $display("x3 = %h, x4 = %h, x7 = %h, x10 = %h", regs[3], regs[4], regs[7], regs[10]);
    end

initial begin
 $display("rs1value = %h", rs1_val);
 $display("rs2value = %h", rs2_val);
end


endmodule