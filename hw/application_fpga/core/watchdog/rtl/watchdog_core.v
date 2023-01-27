//======================================================================
//
// watchdog_core.v
// ------------
// watchdog core.
//
//
// Author: Joachim Strombergson
// Copyright (C) 2022 - Tillitis AB
// SPDX-License-Identifier: GPL-2.0-only
//
//======================================================================

`default_nettype none

module watchdog_core(
                     input wire           clk,
                     input wire           reset_n,

                     input wire [27 : 0]  timer_init,
                     input wire           start,
                     input wire           stop,

                     output wire          running,
		     output wire          timeout
                  );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam CTRL_IDLE      = 2'h0;
  localparam CTRL_START     = 2'h1;
  localparam CTRL_COUNTDOWN = 2'h2;
  localparam CTRL_TIMEOUT   = 2'h3;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg          running_reg;
  reg          running_new;
  reg          running_we;

  reg [27 : 0] timer_reg;
  reg [27 : 0] timer_new;
  reg          timer_set;
  reg          timer_dec;
  reg          timer_we;

  reg          timeout_reg;
  reg          timeout_new;

  reg [1 : 0]  core_ctrl_reg;
  reg [1 : 0]  core_ctrl_new;
  reg          core_ctrl_we;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign running    = running_reg;
  assign timeout    = timeout_reg;


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin: reg_update
      if (!reset_n)
        begin
          running_reg   <= 1'h0;
	  timer_reg     <= 28'h0;
	  timeout_reg   <= 1'h0;
          core_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
	  timeout_reg <= timeout_new;

          if (running_we) begin
            running_reg <= running_new;
	  end

	  if (timer_we) begin
	    timer_reg <= timer_new;
	  end

          if (core_ctrl_we) begin
            core_ctrl_reg <= core_ctrl_new;
          end
	end
    end // reg_update


  //----------------------------------------------------------------
  // timer_ctr
  //----------------------------------------------------------------
  always @*
    begin : timer_ctr
      timer_new = 28'h0;
      timer_we  = 1'h0;

      if (timer_set) begin
	timer_new = timer_init;
	timer_we  = 1'h1;
      end

      else if (timer_dec) begin
	timer_new = timer_reg - 1'h1;
	timer_we  = 1'h1;
      end
    end


  //----------------------------------------------------------------
  // Core control FSM.
  //----------------------------------------------------------------
  always @*
    begin : core_ctrl
      timer_set     = 1'h0;
      timer_dec     = 1'h0;
      running_new   = 1'h0;
      running_we    = 1'h0;
      timeout_new   = 1'h0;
      core_ctrl_new = CTRL_IDLE;
      core_ctrl_we  = 1'h0;

      case (core_ctrl_reg)
        CTRL_IDLE: begin
          if (start) begin
            running_new   = 1'h1;
            running_we    = 1'h1;
	    core_ctrl_new = CTRL_START;
	    core_ctrl_we  = 1'h1;
	  end
        end

        CTRL_START: begin
	  timer_set     = 1'h1;
	  core_ctrl_new = CTRL_COUNTDOWN;
	  core_ctrl_we  = 1'h1;
        end

	CTRL_COUNTDOWN: begin
	  timer_dec = 1'h1;
	  if (stop) begin
            running_new   = 1'h0;
            running_we    = 1'h1;
	    core_ctrl_new = CTRL_IDLE;
	  end

	  else if (start) begin
	    core_ctrl_we  = 1'h1;
            core_ctrl_new = CTRL_START;
            core_ctrl_we  = 1'h1;
	  end

	  else if (timer_reg == 28'h0) begin
            core_ctrl_new = CTRL_TIMEOUT;
            core_ctrl_we  = 1'h1;
	  end
	end

        CTRL_TIMEOUT: begin
	  timeout_new = 1'h1;
        end

        default: begin
        end
      endcase // case (core_ctrl_reg)
    end // core_ctrl

endmodule // watchdog_core

//======================================================================
// EOF watchdog_core.v
//======================================================================
