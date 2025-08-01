module core (
    input wire clk,
    input wire rst,
    output wire [7:0] result,
    output wire uart_tx
);

    wire [31:0] din;

    reg uart_send = 0;
    reg [7:0] uart_data = 8'b0;
    wire uart_txdone;
    


    // Internal wires
    wire branch;
    wire [31:0] curr_addr;
    reg [31:0] next_addr;
    wire [31:0] ram_out;
    wire [6:0] opcode, funct7;
    wire [4:0] rd;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [2:0] funct3;
    wire [31:0] imm;
    wire regwrite, alusrc, memread, memwrite, jump, auipc, jump_r;
    wire branch_taken = branch & zero; // branch taken if condition is true
    wire [1:0] aluop;
    wire memtoreg;
    wire [3:0] alu_control;
    wire [31:0] rs1value, rs2value;
    wire [31:0] input_b = alusrc ? imm : rs2value;
    wire [31:0] alu_result;
    wire [31:0] mem_data;
    wire [31:0] write_data = is_csr ? csr_read_data : (memtoreg ? mem_data : alu_result);
    wire [31:0] x3_debug;
    wire [31:0] x5_debug;
    wire zero;
    wire [31:0] branch_target;
    wire csr_read_en, csr_write_en, is_csr;
    wire [31:0] csr_read_data;
    wire [31:0] x10_debug;
    wire [31:0] x7_debug;
    wire [31:0] x4_debug;


   uart_tx_8n1 #(
    .CLOCK_FREQ(50000000),  // Adjust to match your board
    .BAUD_RATE(9600)
   ) uart_inst (
    .clk(clk),
    .txbyte(uart_data),
    .senddata(uart_send),
    .txdone(uart_txdone),
    .tx(uart_tx)
   );

    // Instantiate CSR module

  csr csr_inst (
    .clk(clk),
    .reset(rst),
    .csr_addr(ram_out[31:20]),      // CSR address field from instruction
    .csr_read_en(csr_read_en),
    .csr_write_en(csr_write_en),
    .csr_write_data(rs1value),      // CSR write data from rs1
    .csr_read_data(csr_read_data)
  );


    // Instantiate PC
    pc pc_inst (
        .clk(clk),
        .rst(rst),
        .next_addr(next_addr),
        .curr_addr(curr_addr)
    );

    // RAM (Instruction Memory)
    ram ram_inst (
        .clk(clk),
        .we(1'b0),
        .addr(curr_addr),
        .din(din),
        .dout(ram_out)
    );

    // Decoder
    decode decode_inst (
        .instr(ram_out),
        .opcode(opcode),
        .funct7(funct7),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .imm(imm)
    );

    // Control Unit
    control_unit control_unit_inst (
        .opcode(opcode),
        .funct3(funct3),
        .RegWrite(regwrite),
        .ALUSrc(alusrc),
        .MemRead(memread),
        .MemWrite(memwrite),
        .Branch(branch),
        .Jump(jump),
        .Jump_r(jump_r),
        .memtoreg(memtoreg),
        .AUIPC(auipc),
        .ALUOp(aluop),
        .csr_read_en(csr_read_en),
        .csr_write_en(csr_write_en),
        .is_csr(is_csr)
    );

    // ALU Control
    alu_control alu_control_inst (
        .ALUOp(aluop),
        .funct3(funct3),
        .funct7(funct7),
        .ALUControl(alu_control)
    );

    // Register File
    regfile regfile_inst (
        .clk(clk),
        .reg_write(regwrite),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(write_data),
        .rs1_val(rs1value),
        .rs2_val(rs2value),
        .x3_debug(x3_debug),
        .x5_debug(x5_debug),
        .x10_debug(x10_debug),
        .x7_debug(x7_debug),
        .x4_debug(x4_debug) 
    );

    // ALU
    ALU ALU_inst (
        .A(rs1value),
        .B(input_b),
        .ALUControl(alu_control),
        .Result(alu_result),
        .zero(zero)
    );

    // Data RAM
    data_ram data_ram_inst (
        .clk(clk),
        .we(memwrite),
        .addr(alu_result),
        .din(rs2value),
        .dout(mem_data)
    );
    


    // Cycle counter and debug display
    reg [31:0] cycle = 0;
    always @(posedge clk) begin
        cycle <= cycle + 1;
        $display("Cycle %0d: PC = %h, x3 = %h, x4 = %h result = %h, x10 = %h, x7 = %h, x5 = %d", cycle, curr_addr, x3_debug, x4_debug, result, x10_debug, x7_debug, x5_debug);

        $display("Control: RegWrite=%b, ALUSrc=%b, memtoreg=%b, ALUOp=%b", regwrite, alusrc, memtoreg, aluop);
        $display("Core sees rd = %b (%d)", rd, rd);
    end


    initial begin
        $display("Core initialized. PC starts at %h", curr_addr);
    
   
     $display("Fetched instruction = %h", ram_out);
    end
    // PC increment logic
    always @(*) begin
     if (jump_r)
        next_addr = rs1value + imm;
     else if (jump)
        next_addr = curr_addr + imm;
     else if (branch && zero)
        next_addr = curr_addr + imm;
     else
        next_addr = curr_addr + 4;
    end

    assign result = x5_debug[7:0]; // Output the lower 8 bits of x5 for result

    reg [3:0] uart_state = 0;

 always @(posedge clk) begin
    case (uart_state)
        0: begin
            uart_data <= x3_debug[7:0];  // Send lower byte of x5
            uart_send <= 1;
            uart_state <= 1;
        end
        1: begin
            uart_send <= 0;  // Clear send after one cycle
            if (uart_txdone)
                uart_state <= 2;
        end
        2: begin
            // Transmission complete, ready for next byte or idle
        end
    endcase
end
   


 
    
endmodule