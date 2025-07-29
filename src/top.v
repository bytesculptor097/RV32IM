module top (
    input wire clk,
    input wire rst,
    output wire uart_txd 
);

    wire [31:0] din;
    wire uart_tx_busy;
    reg uart_tx_en;
    reg [7:0] uart_tx_data;

 uart_tx #(
    .BIT_RATE(9600),
    .CLK_HZ(50_000_000),
    .PAYLOAD_BITS(8),
    .STOP_BITS(1)

 ) uart_tx_inst (
    .clk(clk),
    .resetn(~rst),
    .uart_txd(uart_txd),
    .uart_tx_busy(uart_tx_busy),
    .uart_tx_en(uart_tx_en),
    .uart_tx_data(uart_tx_data)
 );

    // Internal wires
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
    wire [31:0] write_data = memtoreg ? mem_data : alu_result;
    wire [31:0] x3_debug;
    wire [31:0] x5_debug;
    wire zero;
    wire [31:0] branch_target;



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
        .RegWrite(regwrite),
        .ALUSrc(alusrc),
        .MemRead(memread),
        .MemWrite(memwrite),
        .Branch(branch),
        .Jump(jump),
        .Jump_r(jump_r),
        .memtoreg(memtoreg),
        .AUIPC(auipc),
        .ALUOp(aluop)
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
        .x5_debug(x5_debug)
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

    reg [1:0] byte_index;
    reg [31:0] x5_buffer;
    reg [15:0] send_timer;

    always @(posedge clk) begin
        if (rst) begin
            uart_tx_en <= 0;
            byte_index <= 0;
            send_timer <= 0;
        end else begin
            send_timer <= send_timer + 1;

            if (send_timer == 10000 && !uart_tx_busy) begin
                x5_buffer <= x5_debug;
                byte_index <= 0;
                send_timer <= 0;
            end

            if (!uart_tx_busy && byte_index < 4) begin
                case (byte_index)
                    0: uart_tx_data <= x5_buffer[7:0];
                    1: uart_tx_data <= x5_buffer[15:8];
                    2: uart_tx_data <= x5_buffer[23:16];
                    3: uart_tx_data <= x5_buffer[31:24];
                endcase
                uart_tx_en <= 1;
                byte_index <= byte_index + 1;
            end else begin
                uart_tx_en <= 0;
            end
        end
    end

    
endmodule
