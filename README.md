# Team Members Details

Name : Indhra SS;
Email Id: indhrass29@gmail.com

Name: Aathi Sankar;
Email Id: aathisankara2005@gmail.com

Name: Arvindh TE;
Email: tearvindh9105@gmail.com

(Stage 1 details are located belowe Stage 2)

# Stage 2

# How the Judges' Feedback Helped Us Improve
The judges helped us refine our approach with insightful feedback that guided us toward a truly systolic design. They pointed out that:

"Your design was structured as a 2D array of MACs rather than a true systolic array. In a systolic array, inputs should enter from the left (activations) and top (weights), propagating in a staggered manner across cycles. Please revisit your design to ensure proper systolic movement."


## Fixes we implemented

- Activations now enter from the left and propagate right, while weights enter from the top and move downward in a structured pipeline.
- The first row initializes, while the remaining rows accumulate results in a systematic manner.
- Each PE receives inputs from its neighbors in the previous cycle, avoiding simultaneous updates.
- Final Output , The last row properly stores accumulated results after a necessary delay, ensuring accuracy.
- find **systolic_final.tlv**

## About Design
- Changes in the architecture of systolic array to get input one by one and process it to output it one by one
- designed in a way that it uses a flattened 1D array of PEs, where each PE computes a Multiply-Accumulate (MAC) operation. (Row and column indices are derived from the PE's position) 
- Activations shift horizontally across PEs in the same row, while partial sums propagate vertically down the columns. This ensures continuous data flow and maximizes throughput.



## Design Schematic
![Pasted image](https://github.com/user-attachments/assets/2dfb6067-b00a-409e-941e-463728f5cf05)



# C++ Program for Conv2D

## Implement Conv2D in C++and Generate Assembly Code

- We implemented a simple 2D convolution efficiently with loop unrolling .It performs convolution on a 3×3 input with a 2×2 kernel. We Used WARP-V.org to generate assembly.
- Example taken is 3X3 Image and 2X2 kernel [ [1,2,3],[4,5,6],[7,8,9]] and [[1,1] ,[1,1]]
- please find the **convoulution_final.cpp** and **assembly_final.tlv under simulation folder**


## Calculate CPU-Only Cycles

![image](https://github.com/user-attachments/assets/a9663db0-f6fa-42ae-9a0e-a5b74183b111)

**Cycles Taken: 198**


# Implementation on VSDSquadron Mini FPGA

## Software Stack
* Sandpiper-saas
* yosys
* nextpnr
* iceprog
* icepack

## Generated verilog files to generate your FPGA bitstream

- Using SandPiper-SaaS we convert TLV to SV, find the systolic_final.sv
- While implementing UART communication, we encountered challenges in receiving outputs correctly.
- We done by splitting into two ways. One is to ensure the results in fpga through rgb led lights and other through edaplayground to verify and see the output and clock cycles.
  
## Result Ensuring
### For fpga 

- **We revised the sandpiper system verilog code into rgb light based code for checking Hardware**
- Example taken is 3X3 Image and 2X2 kernel [ [1,2,3],[4,5,6],[7,8,9]] and [[1,1] ,[1,1]]
- Please find the code file **conv2d_systolic.sv under Implementation folder**

### For Cylces

- We revised the sandpiper system verilog code by adding a counter module in it
- please find the code file revised_systolic.sv under Fpga_cycles folder
- generally for 100MHZ , we code like forever #5 clk = ~ clk
- **since VSDSquadron is 12MHZ , we need to ensure that is  #41.67 clk = ~clk; ( SINCE Period = 83.33 ns )**
- Please find the code file **sys_cycles_tb.sv under Implementation folder**
- Example taken is 3X3 Image and 2X2 kernel [ [1,2,3],[4,5,6],[7,8,9]] and [[1,1] ,[1,1]]
- **Execution time taken is 600ns , cycles = time * clck frequency**
- **Cycles Taken: 7.2 cycles**

## Demo Video - VSDSquadron Mini FPGA
https://www.youtube.com/watch?v=zXLgHzfCSQo

- The state transitions immediately from **INPUT (red) near to reset button → KERNEL(blue) → OUTPUT (green)**   1:56 in consecutive clock cycles.
The blue LED may turn on for only 1 cycle, which is too fast to observe.


# Performance comparison in cycles.
- **CPU ALONE - 198 CYCLES**
- **CPU + ACCELERATOR - 7.2 CYCLES**

- Systolic array provides hardware parallelism that the sequential RISC-V implementation cannot match
- where as the FPGA implementation uses memory buffers and optimized data movement
- The ratio between the cycles (198/7.2 ≈ 27.5x speedup) (sequential CPU processing vs parallel hardware implementations)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Stage 1

[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/XgHZXonc)

https://youtu.be/OViYSqMbNXc?si=-NyVCGD_Ug_CFysz

## 8×8 Systolic Array for Matrix Multiplication

This design implements an efficient 8×8 systolic array for matrix multiplication using Processing Elements (PEs). The systolic array performs element-wise multiplication and accumulates the results over multiple cycles.

### Micro-Architecture

#### Processing Element (PE)
Each Processing Element (PE) performs the following operations:
1. **Input Reception**:
   - Receives input values `A` and `B` from an external source.
2. **Partial Product Calculation**:
   - Computes the partial product: `partial_product = A * B`.
3. **Accumulation**:
   - Accumulates the sum over multiple cycles: `acc_sum = prev(acc_sum) + partial_product`.
4. **Pipeline Propagation**:
   - Passes values along the pipeline for further computation.

#### Systolic Array Architecture
- We made systolic array as a 2D array of 8×8 PEs.
- Each PE independently computes and accumulates results for its corresponding matrix elements.
- Pipeline registers to ensure the correct propagation of data across cycles and to maintaine synchronization.

### Dataflow and Execution

#### Execution Steps:
1. **Cycle 0**: Initializee matrices `A` and `B` with random values.
2. **Cycle 1**: compute element-wise multiplication:
   - `partial_product = A * B`.
3. **Cycle 2**: Accumulate the sum:
   - `acc_sum_reg = prev(acc_sum_reg) + partial_product`.
4. **Cycle 3+**: continue accumulation and output results when computation completes.

#### Dataflow Type
- This design follows a row stationary dataflow model. In this setup, the partial product for each matrix element is computed and accumulated across rows. The values of A and B are processed row-wise, and accumulation happens for each row over multiple cycles.
- We opted for row stationary as a practical starting point. This design approach is effective for basic matrix operations, offering simplicity, parallelism, and scalability, it also ensures that each row’s data is efficiently processed across the pipeline, laying the groundwork for optimization to weight stationary.

### Optimizations

1. **Pipelined Execution**:
   - Enables parallel computation by processing data in  staggered manner, maximizing throughput.
2. **Efficient Accumulation**:
   - Utilizes shift registers (`>>1`) to reference and update previous accumulation values efficiently.
3. **Parallel Processing**:
   - All PEs operate simultaneously, to reduce computation time for the matrix multiplication.

### Design Highlights
- **Scalability**: It allows for easy scaling for larger systolic arrays.
- **Performance**: Maximum throughput achieved through parallelism and pipelining.
- **Efficiency**: optimized dataflow ensures minimal cycle delays and efficient hardware utilization.

![IMG-20250209-WA0010](https://github.com/user-attachments/assets/8847b2af-5bdc-4160-a713-ba5cd89af572)


---

This systolic array design offers a solution for matrix multiplication, using parallelism and pipelining to improve computation efficiency.
