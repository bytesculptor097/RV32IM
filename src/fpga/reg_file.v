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
    output wire [31:0] x5_debug
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

 initial begin
    regs[1] = 32'd15;    
    regs[2] = 32'd4;  
 end

    always @(posedge clk) begin
    $display("x3 = %h, x5 = %h", regs[3], regs[5]);
    end

initial begin
 $display("rs1value = %h", rs1_val);
 $display("rs2value = %h", rs2_val);
end


endmodule