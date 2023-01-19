//======================================================================
//
// tb_watchdog_core.v
// --------------
// Testbench for the watchdog core.
//
//
// Author: Joachim Strombergson
// Copyright (C) 2022 - Tillitis AB
// SPDX-License-Identifier: GPL-2.0-only
//
//======================================================================

`default_nettype none

module tb_watchdog_core();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG     = 0;
  parameter DUMP_WAIT = 0;

  parameter CLK_HALF_PERIOD = 1;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0] cycle_ctr;
  reg [31 : 0] error_ctr;
  reg [31 : 0] tc_ctr;
  reg          tb_monitor;

  reg           tb_clk;
  reg           tb_reset_n;
  reg           tb_start;
  reg           tb_stop;
  reg  [31 : 0] tb_prescaler;
  reg  [31 : 0] tb_watchdog;
  wire [31 : 0] tb_curr_watchdog;
  wire          tb_ready;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  watchdog_core dut(
		 .clk(tb_clk),
                 .reset_n(tb_reset_n),
                 .prescaler_value(tb_prescaler),
		 .watchdog_value(tb_watchdog),
		 .start(tb_start),
		 .stop(tb_stop),
		 .curr_watchdog(tb_curr_watchdog),
		 .ready(tb_ready)
                );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Always running clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD;
      tb_clk = !tb_clk;
    end // clk_gen


  //----------------------------------------------------------------
  // sys_monitor()
  //
  // An always running process that creates a cycle counter and
  // conditionally displays information about the DUT.
  //----------------------------------------------------------------
  always
    begin : sys_monitor
      cycle_ctr = cycle_ctr + 1;
      #(CLK_PERIOD);
      if (tb_monitor)
        begin
          dump_dut_state();
        end
    end


  //----------------------------------------------------------------
  // dump_dut_state()
  //
  // Dump the state of the dump when needed.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("State of DUT");
      $display("------------");
      $display("Cycle: %08d", cycle_ctr);
      $display("");
      $display("Inputs and outputs:");
      $display("start: 0x%1x, stop: 0x%1x, ready: 0x%1x",
	       dut.start, dut.stop, dut.ready);
      $display("prescaler_value: 0x%08x, watchdog_value: 0x%08x",
	       dut.prescaler_value, dut.watchdog_value);
      $display("");
      $display("Internal state:");
      $display("prescaler_reg: 0x%08x, prescaler_new: 0x%08x",
	       dut.prescaler_reg, dut.prescaler_new);
      $display("prescaler_set: 0x%1x, prescaler_dec: 0x%1x",
	       dut.prescaler_set, dut.prescaler_dec);
      $display("");
      $display("watchdog_reg: 0x%08x, watchdog_new: 0x%08x",
	       dut.watchdog_reg, dut.watchdog_new);
      $display("watchdog_set: 0x%1x, watchdog_dec: 0x%1x",
	       dut.watchdog_set, dut.watchdog_dec);
      $display("");
      $display("core_ctrl_reg: 0x%02x, core_ctrl_new: 0x%02x, core_ctrl_we: 0x%1x",
	       dut.core_ctrl_reg, dut.core_ctrl_new, dut.core_ctrl_we);
      $display("");
      $display("");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut;
    begin
      $display("--- DUT before reset:");
      dump_dut_state();
      $display("--- Toggling reset.");
      tb_reset_n = 0;
      #(2 * CLK_PERIOD);
      tb_reset_n = 1;
      $display("--- DUT after reset:");
      dump_dut_state();
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // wait_ready()
  //
  // Wait for the ready flag in the dut to be set.
  //
  // Note: It is the callers responsibility to call the function
  // when the dut is actively processing and will in fact at some
  // point set the flag.
  //----------------------------------------------------------------
  task wait_ready;
    begin
      #(2 * CLK_PERIOD);
      while (!tb_ready)
        begin
          #(CLK_PERIOD);
          if (DUMP_WAIT)
            begin
              dump_dut_state();
            end
        end
    end
  endtask // wait_ready


  //----------------------------------------------------------------
  // init_sim()
  //
  // Initialize all counters and testbed functionality as well
  // as setting the DUT inputs to defined values.
  //----------------------------------------------------------------
  task init_sim;
    begin
      cycle_ctr  = 0;
      error_ctr  = 0;
      tc_ctr     = 0;
      tb_monitor = 0;

      tb_clk     = 0;
      tb_reset_n = 1;

      tb_start     = 1'h0;
      tb_stop      = 1'h0;
      tb_prescaler = 32'h0;
      tb_watchdog     = 32'h0;
    end
  endtask // init_sim


  //----------------------------------------------------------------
  // test()
  // Runs an encipher, decipher test with given key and plaintext
  // The generated ciphertext is verified with the given ciphertet.
  // The generated plaintxt is also verified against the
  // given plaintext.
  //----------------------------------------------------------------
  task test1;
    begin
      tc_ctr = tc_ctr + 1;
      tb_monitor = 1;

      $display("--- test1 started.");
      dump_dut_state();
      tb_prescaler = 32'h6;
      tb_watchdog     = 32'h9;
      #(CLK_PERIOD);
      tb_start = 1'h1;
      #(CLK_PERIOD);
      tb_start = 1'h0;
      wait_ready();
      #(CLK_PERIOD);
      tb_monitor = 0;
      $display("--- test1 completed.");
      $display("");
    end
  endtask // test1


  //----------------------------------------------------------------
  // watchdog_core_test
  //
  // Test vectors from:
  //----------------------------------------------------------------
  initial
    begin : watchdog_core_test
      $display("--- Simulation of WATCHDOG core started.");
      $display("");

      init_sim();
      reset_dut();

      test1();

      $display("");
      $display("--- Simulation of watchdog core completed.");
      $finish;
    end // watchdog_core_test
endmodule // tb_watchdog_core

//======================================================================
// EOF tb_watchdog_core.v
//======================================================================
