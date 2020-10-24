\m4_TLV_version 1d: tl-x.org
\SV

   // =========================================
   // Welcome!  Try the tutorials via the menu.
   // =========================================s

   // Default Makerchip TL-Verilog Code Template
   
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   `include "sqrt32.v";
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   $reset = *reset;
   
   //---------------------------------------------------------------
   // error condition with pipeline
   //---------------------------------------------------------------
   //...
   // Implementing a 6 stage pipeline for error condition aggregation
   // $error3 = is the final aggregated error coming out of pipeline
   
   |error
      @0
         $error1 = $bad_input | $illegal_op; //error1 aggregates bad input, illegal op
      // @2 skipped, implicit.
      @3
         $error2 = $overflow | $error1;      // error2 aggregates error1 and overflow
      // @4 skipped, implicit
      // @5 skipped, implicit
      @6
         $error3 = $error2 | $div_by_zero;   // error3 aggregates error2 and div_by_zero
   //---------------------------------------------------------------
   
   //---------------------------------------------------------------
   //Free running Counter (random stuff running on background)
   //---------------------------------------------------------------
   $counter[31:0] = $reset ? 0 : >>1$counter + 1; // Free running Counter starts from 0

   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
