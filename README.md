# DIRV-Hackathon

## Key Aspects of the Implementation

### Displaying Output via UART
- Convolution results are streamed via UART to the terminal, ensuring compliance with hackathon requirements.  
- Output is structured in small data chunks for improved readability and debugging.  

### Full Convolution Implementation on FPGA
- Convolution is executed using **im2col + GEMM**, rather than a single matrix-matrix multiplication.  
- **FPGA SRAM** is utilized to store inputs, activations, filter weights, and outputs for optimized memory usage.  

### Performance Comparison: CPU vs FPGA
- Execution time is measured using **RISC-V cycle counting (rdcycle())**.  
- A cycle count comparison between **CPU-based im2col + GEMM** and **FPGA-accelerated convolution** demonstrates the performance benefits of hardware acceleration.  

### Optimized im2col with SRAM-Friendly Tiling
- **Tiled processing** is implemented to efficiently handle larger input sizes that exceed the systolic array dimensions.  
- This ensures **efficient memory access** and minimizes redundant computations.  

### Fixed-Point Q8.8 Representation for Efficient Computation
- **Q8.8 fixed-point arithmetic** replaces floating-point operations, reducing computational overhead while maintaining precision.  
- This approach is more suitable for **FPGA implementations**, where floating-point operations are costly.  

### RISC-V Simulation Using QEMU
- The implementation is first validated through **QEMU-based RISC-V simulation** before deploying it on the FPGA.  
- This allows for **faster debugging and performance analysis** without requiring direct hardware access.

  The below figure shows the simulated output:


![WhatsApp Image 2025-02-28 at 22 26 58](https://github.com/user-attachments/assets/7d69d1fc-ec02-4234-9ead-e05e81bb4dc9)
