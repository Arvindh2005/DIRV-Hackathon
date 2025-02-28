// `include "uart_trx.v"

//----------------------------------------------------------------------------
//                         Module Declaration                                --
//----------------------------------------------------------------------------
module systolic_conv_uart (
    output wire led_red,     // Red LED - Not used here (can be error indicator)
    output wire led_blue,    // Blue LED - Processing
    output wire led_green,   // Green LED - Computation Done
    output wire uarttx,      // UART Transmission Pin
    input wire clk           // System Clock (12 MHz input)
);

    parameter DATA_WIDTH = 8;
    parameter OUTPUT_WIDTH = DATA_WIDTH * 2;

    // Predefined 3x3 Image (Flattened after Im2Col transformation for 2x2 kernel)
    reg [DATA_WIDTH-1:0] input_matrix[0:3];
    reg [DATA_WIDTH-1:0] kernel_matrix[0:3];

    // Output result storage
    reg [OUTPUT_WIDTH-1:0] output_matrix[0:3];
    reg done = 0;
    
    // Systolic Array Registers
    reg [DATA_WIDTH-1:0] activations[0:3];
    reg [DATA_WIDTH-1:0] weights[0:3];
    reg [OUTPUT_WIDTH-1:0] psum[0:3];

    // Initialization of matrices
    always @(*) begin
        input_matrix[0] = 8'd1;
        input_matrix[1] = 8'd2;
        input_matrix[2] = 8'd4;
        input_matrix[3] = 8'd5;
        
        kernel_matrix[0] = 8'd1;
        kernel_matrix[1] = 8'd0;
        kernel_matrix[2] = 8'd0;
        kernel_matrix[3] = 8'd1;
    end

    // 9600 baud clock divider
    reg clk_9600 = 0;
    reg [31:0] cntr_9600 = 32'b0;
    parameter period_9600 = 625;

    // UART instance
    uart_tx_8n1 uart_inst (
        .clk(clk_9600),
        .txbyte(uart_data),
        .senddata(send_uart),
        .tx(uarttx)
    );

    reg [7:0] uart_data;
    reg send_uart = 0;
    reg [4:0] uart_index = 0; // UART sending state
    integer i;
    // Clock Divider for 9600 baud
    always @(posedge clk) begin
        cntr_9600 <= cntr_9600 + 1;
        if (cntr_9600 == period_9600) begin
            clk_9600 <= ~clk_9600;
            cntr_9600 <= 32'b0;
        end
    end

    // Load weights (Weight-Stationary)
    always @(posedge clk) begin
        if (!done) begin
            for (i = 0; i < 4; i = i + 1) begin
                weights[i] <= kernel_matrix[i];
                activations[i] <= input_matrix[i]; // Data moves through rows
                psum[i] <= psum[i] + (activations[i] * weights[i]); // MAC Operation
            end
            done <= 1; // Finish processing
        end
    end

    // Store the result
    always @(posedge clk) begin
        if (done) begin
            for (i = 0; i < 4; i = i + 1)
                output_matrix[i] <= psum[i];
        end
    end
    reg tx_bit;
    // UART Transmission for Output
    always @(posedge clk_9600) begin
        if (done && uart_index < 8) begin
            uart_data <= output_matrix[uart_index];
            send_uart <= 1;
            uart_index <= uart_index + 1;
        end else begin
            send_uart <= 0;
            uart_index <= 0;
        end
    end

endmodule
