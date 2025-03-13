\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)


m4_define(NUM_ROWS, 4)
m4_define(NUM_COLS, 4)
m4_define(NUM_PE, NUM_ROWS * NUM_COLS)


\TLV pe_multiply_accumulate($output, $activation, $weight, $reset, $activation_out, $partial_sum_out)
   |pipe
      @0
         $output[31:0] = $reset ? 0 : \$signed($activation[7:0]) * \$signed($weight[7:0]) + >>1$partial_sum;
      @1
         $activation_out[7:0] = >>1$activation; // shift activation right to the next PE
         $partial_sum_out[31:0] = $output; // store partial sum to pass downward

// Here we made flattened 1D
\TLV systolic_array_1d(/pe, $output, $activation_in, $weight_in, $reset)
   /pe[NUM_PE-1:0]
      // Compute row and column indices
      $index = #m4_strip_prefix(/pe);
      $row = $index / NUM_COLS;
      $col = $index % NUM_COLS;

     // first column and shift right --- Activations
      $activation[7:0] = ($col == 0) ? $activation_in : >>1/pe[$index - 1]$activation_out;

      //  first row and shift downward -- weights
      $weight[7:0] = ($row == 0) ? $weight_in : >>1/pe[$index - NUM_COLS]$weight;

      // Partial sum
      $partial_sum[31:0] = ($row == 0) ? 0 : >>1/pe[$index - NUM_COLS]$partial_sum_out;

      // computing mac
      m5+pe_multiply_accumulate($output, $activation, $weight, $reset, $activation_out, $partial_sum_out)

\SV
   m5_makerchip_module
\TLV
   $reset = *reset;

  
   m4_rand($activation_stream, 7, 0)
   m4_rand($weight_stream, 7, 0)

  
   m5+systolic_array_1d(/pe, $output, $activation_stream, $weight_stream, $reset)

   
   /result[NUM_COLS-1:0]$final_result[31:0] = >>1/pe[NUM_ROWS*NUM_COLS - NUM_COLS:NUM_ROWS*NUM_COLS - 1]$output;

\SV
   endmodule

