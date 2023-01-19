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

                  input wire [31 : 0]  prescaler_init,
                  input wire [31 : 0]  watchdog_init,
                  input wire           start_stop,

                  output wire [31 : 0] curr_watchdog,
                  output wire          ready
                  );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam CTRL_IDLE      = 2'h0;
  localparam CTRL_PRESCALER = 2'h1;
  localparam CTRL_WATCHDOG  = 2'h2;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg          ready_reg;
  reg          ready_new;
  reg          ready_we;

  reg [31 : 0] prescaler_reg;
  reg [31 : 0] prescaler_new;
  reg          prescaler_we;
  reg          prescaler_set;
  reg          prescaler_dec;

  reg [31 : 0] watchdog_reg;
  reg [31 : 0] watchdog_new;
  reg          watchdog_we;
  reg          watchdog_set;
  reg          watchdog_dec;

  reg [1 : 0]  core_ctrl_reg;
  reg [1 : 0]  core_ctrl_new;
  reg          core_ctrl_we;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign curr_watchdog = watchdog_reg;
  assign ready      = ready_reg;


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin: reg_update
      if (!reset_n)
        begin
          ready_reg     <= 1'h1;
	  prescaler_reg <= 32'h0;
	  watchdog_reg     <= 32'h0;
          core_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (ready_we) begin
            ready_reg <= ready_new;
	  end

	  if (prescaler_we) begin
	    prescaler_reg <= prescaler_new;
	  end

	  if (watchdog_we) begin
	    watchdog_reg <= watchdog_new;
	  end

          if (core_ctrl_we) begin
            core_ctrl_reg <= core_ctrl_new;
          end
	end
    end // reg_update


  //----------------------------------------------------------------
  // prescaler_ctr
  //----------------------------------------------------------------
  always @*
    begin : prescaler_ctr
      prescaler_new = 32'h0;
      prescaler_we  = 1'h0;

      if (prescaler_set) begin
	prescaler_new = prescaler_init;
	prescaler_we  = 1'h1;
      end
      else if (prescaler_dec) begin
	prescaler_new = prescaler_reg - 1'h1;
	prescaler_we  = 1'h1;
      end
    end


  //----------------------------------------------------------------
  // watchdog_ctr
  //----------------------------------------------------------------
  always @*
    begin : watchdog_ctr
      watchdog_new = 32'h0;
      watchdog_we  = 1'h0;

      if (watchdog_set) begin
	watchdog_new = watchdog_init;
	watchdog_we  = 1'h1;
      end
      else if (watchdog_dec) begin
	watchdog_new = watchdog_reg - 1'h1;
	watchdog_we  = 1'h1;
      end
    end


  //----------------------------------------------------------------
  // Core control FSM.
  //----------------------------------------------------------------
  always @*
    begin : core_ctrl
      ready_new     = 1'h0;
      ready_we      = 1'h0;
      prescaler_set = 1'h0;
      prescaler_dec = 1'h0;
      watchdog_set     = 1'h0;
      watchdog_dec     = 1'h0;
      core_ctrl_new = CTRL_IDLE;
      core_ctrl_we  = 1'h0;

      case (core_ctrl_reg)
        CTRL_IDLE: begin
          if (start_stop)
            begin
              ready_new     = 1'h0;
              ready_we      = 1'h1;
	      prescaler_set = 1'h1;
	      watchdog_set     = 1'h1;
	      if (prescaler_init == 0) begin
		core_ctrl_new = CTRL_WATCHDOG;
		core_ctrl_we  = 1'h1;
		end else begin
		  core_ctrl_new = CTRL_PRESCALER;
		  core_ctrl_we  = 1'h1;
		end
            end
        end


	CTRL_PRESCALER: begin
	  if (start_stop) begin
            ready_new     = 1'h1;
            ready_we      = 1'h1;
            core_ctrl_new = CTRL_IDLE;
            core_ctrl_we  = 1'h1;
	  end

	  else begin
	    if (prescaler_reg == 1) begin
              core_ctrl_new = CTRL_WATCHDOG;
              core_ctrl_we  = 1'h1;
	    end else begin
	      prescaler_dec = 1'h1;
	    end
	  end
	end


	CTRL_WATCHDOG: begin
	  if (start_stop) begin
            ready_new     = 1'h1;
            ready_we      = 1'h1;
            core_ctrl_new = CTRL_IDLE;
            core_ctrl_we  = 1'h1;
	  end

	  else begin
	    if (watchdog_reg == 1) begin
              ready_new     = 1'h1;
              ready_we      = 1'h1;
              core_ctrl_new = CTRL_IDLE;
              core_ctrl_we  = 1'h1;
	    end

	    else begin
	      watchdog_dec = 1'h1;

	      if (prescaler_init > 0) begin
		prescaler_set = 1'h1;
		core_ctrl_new = CTRL_PRESCALER;
		core_ctrl_we  = 1'h1;
	      end
	    end
	  end
	end

        default: begin
        end
      endcase // case (core_ctrl_reg)
    end // core_ctrl

endmodule // watchdog_core

//======================================================================
// EOF watchdog_core.v
//======================================================================
