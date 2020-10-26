\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/RISC-V_MYTH_Workshop
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/RISC-V_MYTH_Workshop/c1719d5b338896577b79ee76c2f443ca2a76e14f/tlv_lib/risc-v_shell_lib.tlv'])

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV

   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program for MYTH Workshop to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  r10 (a0): In: 0, Out: final sum
   //  r12 (a2): 10
   //  r13 (a3): 1..10
   //  r14 (a4): Sum
   // 
   // External to function:
   m4_asm(ADD, r10, r0, r0)             // Initialize r10 (a0) to 0.
   // Function:
   m4_asm(ADD, r14, r10, r0)            // Initialize sum register a4 with 0x0
   m4_asm(ADDI, r12, r10, 1010)         // Store count of 10 in register a2.
   m4_asm(ADD, r13, r10, r0)            // Initialize intermediate sum register a3 with 0
   // Loop:
   m4_asm(ADD, r14, r13, r14)           // Incremental addition
   m4_asm(ADDI, r13, r13, 1)            // Increment intermediate register by 1
   m4_asm(BLT, r13, r12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   m4_asm(ADD, r10, r14, r0)            // Store final result to register a0 so that it can be read by main program
   
   // Optional:
   // m4_asm(JAL, r7, 00000000000000000000) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   m4_define_hier(['M4_IMEM'], M4_NUM_INSTRS)

   // Macro instantiations for:
   //  o instruction memory
   //  o register file
   //  o data memory
   //  o CPU visualization
   |cpu
      m4+imem(@1)    // Args: (read stage)
      m4+rf(@1, @1)  // Args: (read stage, write stage) - if equal, no register bypass is required
      //m4+dmem(@4)    // Args: (read/write stage)
   
   m4+cpu_viz(@4)    // For visualisation, argument should be at least equal to the last stage of CPU logic
                       // @4 would work for all labs
   
   // Code begins here
   |cpu
      @0
         $reset = *reset;
         
         // YOUR CODE HERE
         // aarright, let's start :)
         //-----------------------------------------------------------------
         //1. PC logic:
         $pc[31:0] = (>>1$reset) ? 0 : >>1$pc + 4;  // address unit: byte, Instruction size: 4 byte
         
         //2. IMEM fetch logic 
         // 2.1 (stage 0 - address instr)
         $imem_rd_en = !$reset;
         $imem_rd_addr[M4_IMEM_INDEX_CNT-1:0] = $pc[M4_IMEM_INDEX_CNT+1:2]; //PC must be word aligned, and only needs to address as per imem size.
         
      @1   
         // 2.2 IMEM fetch logic (stage 1 - read instr)
         $instr[31:0] = $imem_rd_data[31:0];
  
         //3. Instruction Decode:
         // 3.1 Decode Instruction type:
         //  3.1.1 I-type:
         $is_i_instr = $instr[6:2] ==? 5'b0000x ||
                       $instr[6:2] ==? 5'b001x0 ||
                       $instr[6:2] ==  5'b11001 ||
                       $instr[6:2] ==  5'b11100 ?  1 : 0;
         //  3.1.2 R-type:
         $is_r_instr = $instr[6:2] ==? 5'b011x0 ||
                       $instr[6:2] ==  5'b01010 ||
                       $instr[6:2] ==  5'b10100 ?  1 : 0;
         //  3.1.3 S-type:
         $is_s_instr = $instr[6:2] ==? 5'b0100x ?  1 : 0;
         //  3.1.4 B-type:
         $is_b_instr = $instr[6:2] ==  5'b11000 ?  1 : 0;
         //  3.1.5 U-type:
         $is_u_instr = $instr[6:2] ==? 5'b0x101 ?  1 : 0;
         //  3.1.6 J-type:
         $is_j_instr = $instr[6:2] ==  5'b11011 ?  1 : 0;
         
         // 3.2 Extract immediate field:
         $imm[31:0] = $is_i_instr ? { {21{$instr[31]}}, {$instr[30:20]}                                                            } :
                      $is_s_instr ? { {21{$instr[31]}}, {$instr[30:25]}, {$instr[11:8]},  {$instr[7]}                              } :
                      $is_b_instr ? { {20{$instr[31]}}, {$instr[7]},     {$instr[30:25]}, {$instr[11:8]},  {1'b0}                  } :
                      $is_u_instr ? { {$instr[31]}    , {$instr[30:20]}, {$instr[19:12]}, {11'b0}                                  } :
                                    { {9{$instr[31]}},  {$instr[19:12]}, {$instr[20]},    {$instr[30:25]}, {$instr[24:21]}, {1'b0} }; //default for j-type
         
         // 3.3 Extract other fields:
         $funct7_valid = $is_r_instr ? 1 : 0;
         ?$funct7_valid
            $funct7[6:0] = $instr[31:25];
         $rs2_valid = ($is_r_instr | $is_s_instr | $is_b_instr) ? 1 : 0;
         ?$rs2_valid
            $rs2[4:0]    = $instr[24:20];
         $rs1_valid = ($is_i_instr | $is_r_instr | $is_s_instr | $is_b_instr) ? 1 : 0;
         ?$rs1_valid
            $rs1[4:0]    = $instr[19:15];
         $funct3_valid = $rs1_valid;
         ?$funct3_valid
            $funct3[2:0] = $instr[14:12];
         $rd_valid = ($is_i_instr | $is_r_instr | $is_u_instr | $is_j_instr) ? 1 : 0;
         ?$rd_valid
            $rd[4:0]     = $instr[11:7];
         $opcode[6:0] = $instr[6:0]; //opcode is always valid
         
         // 3.4 Decode the instruction:
         //  3.4.1 decode signal extraction:
         $dec_bits[10:0] = { {$funct7[5]}, {$funct3}, {$opcode} };
         
         // 3.4.2 Arithmetic & logic instructions:
         $is_add    = ($dec_bits[10:0] ==? 11'bx_000_0110011);
         $is_addi   = ($dec_bits[10:0] ==? 11'bx_000_0010011);
         
         // 3.4.3 Branch instructions:
         $is_branch = ($opcode ==? 7'b1100011);
         ?$is_branch
            $is_beq  = ($funct3 == 0);
            $is_bne  = ($funct3 == 1);
            $is_blt  = ($funct3 == 4);
            $is_bge  = ($funct3 == 5);
            $is_bltu = ($funct3 == 6);
            $is_bgeu = ($funct3 == 7);
         
         //4 : Register File operations
         // 4.1 Register File read
         //  4.1.1 Address for source registers
         $rf_rd_en1 = $rs1_valid;
         $rf_rd_index1[4:0] = $rs1[4:0];
         $rf_rd_en2 = $rs2_valid;
         $rf_rd_index2[4:0] = $rs2[4:0];
         
         //  4.1.2 Read into ALU
         $src1_value[31:0] = $rf_rd_data1;
         $src2_value[31:0] = $rf_rd_data2;
         
         // 4.2 Register file write (hookup to next stage, ALU dependent here)
         $rf_wr_en = $rd_valid && !($rd[4:0] == 5'b0);
         $rf_wr_index[4:0] = $rd[4:0];
         $rf_wr_data[31:0] = $result[31:0];

         //5: ALU :) Compute + MUX(select) based on instruction
         $result[31:0] = 
            $is_addi      ? $src1_value[31:0] + $imm[31:0]        : //addi
            $is_add       ? $src1_value[31:0] + $src2_value[31:0] : //add
                            32'bx;                                  // default, dont care
         

      // Note: Because of the magic we are using for visualisation, if visualisation is enabled below,
      //       be sure to avoid having unassigned signals (which you might be using for random inputs)
      //       other than those specifically expected in the labs. You'll get strange errors for these.

   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
   
\SV
   endmodule

