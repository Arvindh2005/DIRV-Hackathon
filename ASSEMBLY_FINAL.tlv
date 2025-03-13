\m5_TLV_version 1d --inlineGen --bestsv --noline --noDirectiveComments: tl-x.org
\SV
   /*
   Copyright 2025 Redwood EDA, LLC
   
   Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
   
   The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
   
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
   */
\m5
   use(m5-1.0)

   var(PROG_NAME, my_custom)
   var(ISA, RISCV)
   var(EXT_E, 0)
   var(EXT_M, 0)
   var(EXT_F, 0)
   var(EXT_B, 0)
   var(NUM_CORES, 1)
   var(NUM_VCS, 2)
   var(NUM_PRIOS, 2)
   var(MAX_PACKET_SIZE, 8)
   var(soft_reset, 1'b0)
   var(cpu_blocked, 1'b0)
   var(BRANCH_PRED, two_bit)
   var(EXTRA_REPLAY_BUBBLE, 0)
   var(EXTRA_PRED_TAKEN_BUBBLE, 0)
   var(EXTRA_JUMP_BUBBLE, 0)
   var(EXTRA_BRANCH_BUBBLE, 0)
   var(EXTRA_INDIRECT_JUMP_BUBBLE, 0)
   var(EXTRA_NON_PIPELINED_BUBBLE, 1)
   var(EXTRA_TRAP_BUBBLE, 1)
   var(NEXT_PC_STAGE, 0)
   var(FETCH_STAGE, 0)
   var(DECODE_STAGE, 1)
   var(BRANCH_PRED_STAGE, 1)
   var(REG_RD_STAGE, 1)
   var(EXECUTE_STAGE, 2)
   var(RESULT_STAGE, 2)
   var(REG_WR_STAGE, 3)
   var(MEM_WR_STAGE, 3)
   var(LD_RETURN_ALIGN, 4)
\SV
   // Include WARP-V.
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v/544d93e160a1e4267a4832611af5f8aa459deae5/warp-v.tlv'])
\m5
   TLV_fn(riscv_my_custom_prog, {
      ~assemble(['
         # /=====================\
         # | 2D Convolution      |
         # \=====================/
         #
         # Simple 2D convolution for a 3x3 image and 2x2 kernel.
         # Result is stored in memory locations 0x1000 to 0x1003.
         #
         # Regs:
         # t0: image base address
         # t1: kernel base address
         # t2: output base address
         # t3: loop counter (i)
         # t4: loop counter (j)
         # t5: temporary result
         # t6: temporary register for calculations
         reset:
            ORI t0, zero, 0x1000    #     image base address
            ORI t1, zero, 0x2000    #     kernel base address
            ORI t2, zero, 0x3000    #     output base address
            ORI t3, zero, 0         #     i = 0
         outer_loop:
            ORI t4, zero, 0         #     j = 0
         inner_loop:
            # Load image and kernel elements
            LW t5, 0(t0)            #     t5 = image[i][j]
            LW t6, 0(t1)            #     t6 = kernel[0][0]
            # Multiply using repeated addition (since MUL is not supported)
            ADD t5, t5, t6          #     t5 = image[i][j] * kernel[0][0]
            LW t6, 4(t0)            #     t6 = image[i][j+1]
            LW a1, 4(t1)            #     a1 = kernel[0][1]
            ADD t6, t6, a1          #     t6 = image[i][j+1] * kernel[0][1]
            ADD t5, t5, t6          #     t5 += t6
            LW t6, 8(t0)            #     t6 = image[i+1][j]
            LW a1, 8(t1)            #     a1 = kernel[1][0]
            ADD t6, t6, a1          #     t6 = image[i+1][j] * kernel[1][0]
            ADD t5, t5, t6          #     t5 += t6
            LW t6, 12(t0)           #     t6 = image[i+1][j+1]
            LW a1, 12(t1)           #     a1 = kernel[1][1]
            ADD t6, t6, a1          #     t6 = image[i+1][j+1] * kernel[1][1]
            ADD t5, t5, t6          #     t5 += t6
            # Store result
            SW t5, 0(t2)            #     store result at output[j]
            ADDI t2, t2, 4          #     output address += 4
            ADDI t4, t4, 1          #     j++
            ADDI t0, t0, 4          #     image address += 4
            ADDI t1, t1, 4          #     kernel address += 4
            ORI t6, zero, 2         #     t6 = 2
            BLT t4, t6, inner_loop  #  ^- branch back if j < 2
            ADDI t3, t3, 1          #     i++
            ORI t6, zero, 2         #     t6 = 2
            BLT t3, t6, outer_loop  #  ^- branch back if i < 2
         # Result should be stored in memory locations 0x3000 to 0x3003.
            LW t5, -4(t2)           #     load the final value
            ADDI t6, zero, 0x2d     #     expected result (0x2d)
            BEQ t5, t6, pass        #     pass if as expected
         
            # Branch to one of these to report pass/fail to the default testbench.
         fail:
            ADD t6, t6, zero        #     nop fail
         pass:
            ADD t5, t5, zero        #     nop pass
         
      '])
   })
m4+module_def()
\TLV
   m5+warpv_top()
\SV
   endmodule
