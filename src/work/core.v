module core (
    input wire clk,
    input wire rst,
    output wire [7:0] result,
    output wire uarttx
);

    wire [31:0] din;    


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

// UART TX for debugging
wire        int_osc;
reg  [27:0] frequency_counter_i;

// 9600 Hz clock generation (from 12 MHz)
reg clk_9600 = 0;
reg [31:0] cntr_9600 = 32'b0;
parameter period_9600 = 625;

always @(posedge int_osc) begin
    frequency_counter_i <= frequency_counter_i + 1;
    cntr_9600 <= cntr_9600 + 1;
    if (cntr_9600 == period_9600) begin
        clk_9600 <= ~clk_9600;
        cntr_9600 <= 0;
    end
end

// Internal Oscillator
SB_HFOSC #(.CLKHF_DIV("0b10")) u_SB_HFOSC (
    .CLKHFPU(1'b1),
    .CLKHFEN(1'b1),
    .CLKHF(int_osc)
);

// UART string buffer
reg [7:0] string_data [0:15];
reg [3:0] string_index = 0;
reg [7:0] tx_byte;
reg send = 0;
wire txdone;

initial begin
    string_data[0]  = "H";
    string_data[1]  = "e";
    string_data[2]  = "l";
    string_data[3]  = "l";
    string_data[4]  = "o";
    string_data[5]  = ",";
    string_data[6]  = " ";
    string_data[7]  = "W";
    string_data[8]  = "o";
    string_data[9]  = "r";
    string_data[10] = "l";
    string_data[11] = "d";
    string_data[12] = "!";
    string_data[13] = "\n";
    string_data[14] = "\r";
    string_data[15] = 8'h00; // Null terminator
end

// UART transmission logic
always @(posedge clk_9600) begin
    send <= 0; // Default: no send

    if (txdone && string_data[string_index] != 8'h00) begin
        tx_byte <= string_data[string_index];
        send <= 1;
        string_index <= string_index + 1;
    end
end

// UART transmitter instantiation
uart_tx_8n1 DanUART (
    .clk(clk_9600),
    .txbyte(tx_byte),
    .senddata(send),
    .txdone(txdone),
    .tx(uarttx)
);                     
    
endmodule