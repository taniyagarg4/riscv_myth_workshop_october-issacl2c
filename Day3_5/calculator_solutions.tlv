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
   $reset = *reset;
   
   //---------------------------------------------------------------
   // Calculator
   //---------------------------------------------------------------
   
   |calc
      @1
         $in1[31:0] = *reset == 1 ? 0 : >>2$outcalc[31:0];  // output shifted by 2 stages
         $in2[31:0] = *reset == 1 ? 0 : $rand2[3:0];
  
         $outmul[31:0]  = $in1[31:0] * $in2[31:0];
         $outdiv[31:0]  = $in1[31:0] / $in2[31:0];
         $outsub[31:0]  = $in1[31:0] - $in2[31:0];
         $outadd[31:0]  = $in1[31:0] + $in2[31:0];
         
         $valid = *reset ? 0 : >>1$valid + 1; // Free running Counter implements alternate cycling
         
      @2
         $outcalc[31:0] = (*reset | !$valid) == 1   ? 32'd0   :  //reset : make 0
                          $select[1:0] == 3         ? $outmul :  //3
                          $select[1:0] == 2         ? $outmul :  //2
                          $select[1:0] == 1         ? $outsub :  //1
                                                      $outadd;   //0 default

   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
