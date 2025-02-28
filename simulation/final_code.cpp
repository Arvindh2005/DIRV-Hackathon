#include <iostream>
#include <vector>
#include <cstdlib>
#include <cstdint>   // For fixed-width types (uint16_t, int16_t)
#include <iomanip>   // For formatted UART output
using namespace std;

#define Q8_8_SHIFT 8  // Fixed-point Q8.8 shift value

// Convert float to Q8.8 fixed-point
inline int16_t float_to_fixed(float val) {
    return static_cast<int16_t>(val * (1 << Q8_8_SHIFT));
}

// Convert Q8.8 fixed-point to float
inline float fixed_to_float(int16_t val) {
    return static_cast<float>(val) / (1 << Q8_8_SHIFT);
}

// RISC-V Cycle Counter Function
static inline uint64_t rdcycle() {
    asm volatile("fence.i" ::: "memory");
    __sync_synchronize();
    uint64_t cycles;
    asm volatile("rdcycle %0" : "=r"(cycles));
    asm volatile("fence" ::: "memory");
    __sync_synchronize();
    return cycles;
}

// Generate a random Q8.8 fixed-point matrix
vector<vector<int16_t>> generate_random_matrix(int rows, int cols) {
    vector<vector<int16_t>> matrix(rows, vector<int16_t>(cols));
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            matrix[i][j] = float_to_fixed(((rand() % 10) - 5) * 0.1);  // Random [-0.5, 0.5]
        }
    }
    return matrix;
}

// UART Streaming for FPGA Debugging
void uart_stream(const vector<vector<int16_t>>& output, int chunk_size) {
    cout << "=== UART OUTPUT START ===\n";
    for (size_t i = 0; i < output.size(); i += chunk_size) {
        for (size_t j = 0; j < output[i].size(); j += chunk_size) {
            for (size_t ii = i; ii < min(i + chunk_size, output.size()); ii++) {
                for (size_t jj = j; jj < min(j + chunk_size, output[ii].size()); jj++) {
                    cout << fixed << setprecision(2) << fixed_to_float(output[ii][jj]) << " ";
                }
                cout << "\n";
            }
            cout << "--- CHUNK END ---\n";
        }
    }
    cout << "=== UART OUTPUT END ===\n";
}

// Optimized im2col with SRAM-friendly tiling
void im2col_sram(const vector<vector<int16_t>>& input, int16_t* im2col_matrix, int tile_x, int tile_y, int tile_size, int k_size) {
    int input_size = input.size();
    int tile_width = min(tile_size, input_size - k_size + 1 - tile_x);
    int tile_height = min(tile_size, input_size - k_size + 1 - tile_y);

    for (int i = 0; i < tile_height; i++) {
        for (int j = 0; j < tile_width; j++) {
            int col_index = (i * tile_width + j) * (k_size * k_size);
            for (int ki = 0; ki < k_size; ki++) {
                for (int kj = 0; kj < k_size; kj++) {
                    im2col_matrix[col_index++] = input[tile_y + i + ki][tile_x + j + kj];
                }
            }
        }
    }
}

// Optimized Conv2D with im2col + GEMM on FPGA
vector<vector<int16_t>> conv2d_tiled_fpga(const vector<vector<int16_t>>& input, const vector<vector<int16_t>>& kernel, int tile_size) {
    int in_size = input.size();
    int k_size = kernel.size();
    int out_size = in_size - k_size + 1;
    vector<vector<int16_t>> output(out_size, vector<int16_t>(out_size, 0));

    // Flatten kernel for optimized memory access
    vector<int16_t> kernel_flat(k_size * k_size);
    for (int i = 0; i < k_size * k_size; i++) {
        kernel_flat[i] = kernel[i / k_size][i % k_size];
    }

    uint64_t total_cpu_cycles = 0;
    uint64_t total_gemm_cycles = 0;

    // Allocate im2col buffer
    vector<int16_t> im2col_matrix(tile_size * tile_size * k_size * k_size);

    for (int tile_i = 0; tile_i < out_size; tile_i += tile_size) {
        for (int tile_j = 0; tile_j < out_size; tile_j += tile_size) {
            uint64_t start_cpu = rdcycle();
            im2col_sram(input, im2col_matrix.data(), tile_j, tile_i, tile_size, k_size);
            uint64_t end_cpu = rdcycle();
            total_cpu_cycles += (end_cpu - start_cpu);

            uint64_t start_gemm = rdcycle();
            for (int i = 0; i < tile_size; i++) {
                for (int j = 0; j < tile_size; j++) {
                    int16_t sum = 0;
                    for (int k = 0; k < k_size * k_size; k++) {
                        sum += im2col_matrix[(i * tile_size + j) * (k_size * k_size) + k] * kernel_flat[k];
                    }
                    output[tile_i + i][tile_j + j] = sum;
                }
            }
            uint64_t end_gemm = rdcycle();
            total_gemm_cycles += (end_gemm - start_gemm);

            cout << "UART TILE [" << tile_i << "," << tile_j << "] CPU: " 
                 << (end_cpu - start_cpu) << " cycles, GEMM: " 
                 << (end_gemm - start_gemm) << " cycles" << endl;
        }
    }

    cout << "UART Final CPU (im2col): " << total_cpu_cycles << " cycles\n";
    cout << "UART Final FPGA (GEMM): " << total_gemm_cycles << " cycles\n";

    return output;
}

int main() {
    srand(42);
    int input_size = 8, kernel_size = 3, tile_size = 2;
    auto image = generate_random_matrix(input_size, input_size);
    auto kernel = generate_random_matrix(kernel_size, kernel_size);
    auto output = conv2d_tiled_fpga(image, kernel, tile_size);
    uart_stream(output, 2);
    return 0;
}
