\m4_TLV_version 1d: tl-x.org
\SV

   // =========================================
   // Welcome!  Try the tutorials via the menu.
   // =========================================s

   // Default Makerchip TL-Verilog Code Template
   
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   //$reset = *reset;  // commented this out to use reset in pipeline
   
   //---------------------------------------------------------------
   // Calculator
   //---------------------------------------------------------------
   
   
   |calc
      @1
         $valid       = *reset ? 0 : >>1$valid + 1;  // Free running Counter implements alternate valid states
         $reset       = *reset;                      // let reset propogate through the pipeline
      ?$valid    // implement the valid signal (only once in two cycles)
         @1
            $in1[31:0] = $reset == 1 ? 0 : >>2$outcalc[31:0];  // output shifted by 2 stages
            $in2[31:0] = $reset == 1 ? 0 : $rand2[3:0];

            $outmul[31:0]  = $in1[31:0] * $in2[31:0];
            $outdiv[31:0]  = $in1[31:0] / $in2[31:0];
            $outsub[31:0]  = $in1[31:0] - $in2[31:0];
            $outadd[31:0]  = $in1[31:0] + $in2[31:0];

         @2
            //$select[2:0] = *reset ? 0 : >>1$select + 1; // TEST: Let select also loop, to get all combinations.
            // calculator output
            $outcalc[31:0] = $reset       == 1         ? 32'd0      :  //reset : set to 0
                             $select[2:0] == 4         ? >>2$mem    :  // recall the memory
                             $select[2:0] == 3         ? $outmul    :  //3 multiply
                             $select[2:0] == 2         ? $outdiv    :  //2 divide
                             $select[2:0] == 1         ? $outsub    :  //1 subtract
                                                         $outadd;      //0 add
            // memory element
            $mem[31:0]    =  $reset       == 1         ? 32'd0       : // reset : set to 0
                             $select[2:0] == 5         ? >>2$outcalc : // store output to memory
                                                         >>2$mem;      // default: retain ($RETAIN?)

   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
