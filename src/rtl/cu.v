module control_unit(
    input [6:0] opcode,
    output reg RegWrite,
    output reg ALUSrc,
    output reg MemRead,
    output reg MemWrite,
    output reg Branch,
    output reg Jump,
    output reg Jump_r,
    output reg memtoreg,
    output reg AUIPC,
    output reg [1:0] ALUOp
);

 always @(*) begin
    // Default values
    RegWrite = 0;
    ALUSrc   = 0;
    MemRead  = 0;
    MemWrite = 0;
    Branch   = 0;
    Jump     = 0;
    Jump_r   = 0;
    ALUOp    = 2'b00;
    AUIPC    = 0;
    memtoreg = 0;

    case (opcode)
        7'b0110011: begin // R-type (e.g., add, sub)
            RegWrite = 1;
            ALUSrc   = 0;
            ALUOp    = 2'b10;
            memtoreg = 0; // Write ALU result to register
        end

        7'b0010011: begin // I-type (e.g., addi)
            RegWrite = 1;
            ALUSrc   = 1;
            ALUOp    = 2'b00;
            MemRead  = 0;
            MemWrite = 0;
            memtoreg = 0; // Write ALU result to register
        end

        7'b0000011: begin // I-type (e.g., lw)
            RegWrite = 1;
            ALUSrc   = 1;
            MemRead  = 1;
            MemWrite = 0;
            memtoreg = 1; // Read data from memory
            ALUOp    = 2'b00;
        end

        7'b0100011: begin // S-type (e.g., sw)
            RegWrite = 0;
            ALUSrc   = 1;
            MemWrite = 1;
            ALUOp    = 2'b00;
        end

        7'b1100011: begin // B-type (e.g., beq)
            RegWrite = 0;
            ALUSrc   = 0;
            Branch   = 1;
            ALUOp    = 2'b01;
        end

        7'b0110111: begin // U-type (e.g., lui)
            RegWrite = 1;
            ALUSrc   = 1;
            ALUOp    = 2'b11; // Custom code for LUI
        end

        7'b1101111: begin // J-type (e.g., jal)
            RegWrite = 1;
            Jump   = 1;
            ALUSrc   = 1;
            ALUOp    = 2'b00;
        end

        7'b1100111: begin // I-type (e.g., jalr)
            RegWrite = 1;
            Jump_r   = 1;
            ALUSrc   = 1;
            ALUOp    = 2'b00;
        end

        7'b0010111: begin // U-type (auipc) 
            RegWrite = 1;
            AUIPC    = 1;
            ALUSrc   = 1;
            ALUOp    = 2'b00; // Use ALU to add PC + imm
        end

        default: begin
            
        end

        
    endcase


    $display("Control Unit: RegWrite=%b, ALUSrc=%b, MemRead=%b, MemWrite=%b, Branch=%b, Jump=%b, Jump_r=%b, memtoreg=%b, AUIPC=%b, ALUOp=%b", 
             RegWrite, ALUSrc, MemRead, MemWrite, Branch, Jump, Jump_r, memtoreg, AUIPC, ALUOp);
 end


endmodule