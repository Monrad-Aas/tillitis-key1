//======================================================================
//
// watchdog.v
// --------
// Top level wrapper for the watchdog core.
//
//
// Author: Joachim Strombergson
// Copyright (C) 2022 - Tillitis AB
// SPDX-License-Identifier: GPL-2.0-only
//
//======================================================================

`default_nettype none

module watchdog(
		input wire           clk,
		input wire           reset_n,

		input wire           cs,
		input wire           we,

		input wire  [7 : 0]  address,
		input wire  [31 : 0] write_data,
		output wire [31 : 0] read_data,
		output wire          ready,

		output wire          timeout
	       );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  // API
  localparam ADDR_CTRL          = 8'h08;
  localparam CTRL_START_BIT     = 0;
  localparam CTRL_STOP_BIT      = 1;

  localparam ADDR_STATUS        = 8'h09;
  localparam STATUS_RUNNING_BIT = 0;

  localparam ADDR_TIMER_INIT    = 8'h0a;

  // At 18 MHz the default timeout value corresponds to 7.45s.
  localparam DEFAULT_TIMEOUT_VALUE = 28'h7ff_ffff;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [27 : 0] timer_init_reg;
  reg          timer_init_we;

  reg          start_reg;
  reg          start_new;

  reg          stop_reg;
  reg          stop_new;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0]  tmp_read_data;
  reg           tmp_ready;

  wire [27 : 0] core_curr_timer;
  wire          core_running;
  wire          core_timeout;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data = tmp_read_data;
  assign ready     = tmp_ready;
  assign timeout   = core_timeout;


  //----------------------------------------------------------------
  // core instantiation.
  //----------------------------------------------------------------
  watchdog_core core(
                     .clk(clk),
                     .reset_n(reset_n),

                     .timer_init(timer_init_reg),
                     .start(start_reg),
                     .stop(stop_reg),

                     .running(core_running),
                     .timeout(core_timeout)
                    );


  //----------------------------------------------------------------
  // reg_update.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update
      if (!reset_n) begin
	start_reg      <= 1'h0;
	stop_reg       <= 1'h0;
	timer_init_reg <= DEFAULT_TIMEOUT_VALUE;
      end

      else begin
	start_reg <= start_new;
	stop_reg  <= stop_new;

	if (timer_init_we) begin
	  timer_init_reg <= write_data[27 : 0];
	end
      end
    end // reg_update


  //----------------------------------------------------------------
  // api.
  //----------------------------------------------------------------
  always @*
    begin : api
      start_new     = 1'h0;
      stop_new      = 1'h0;
      timer_init_we = 1'h0;
      tmp_read_data = 32'h0;
      tmp_ready     = 1'h0;

      if (cs) begin
	tmp_ready = 1'h1;

        if (we) begin
          if (address == ADDR_CTRL) begin
	    start_new = write_data[CTRL_START_BIT];
	    stop_new  = write_data[CTRL_STOP_BIT];
	  end

          if (address == ADDR_TIMER_INIT) begin
	    if (!core_running) begin
	      timer_init_we = 1'h1;
	    end
	  end
	end

	else begin
	  if (address == ADDR_STATUS) begin
	    tmp_read_data[STATUS_RUNNING_BIT] = core_running;
	  end

          if (address == ADDR_TIMER_INIT) begin
	    tmp_read_data[27 : 0] = timer_init_reg;
	  end
        end
      end
    end // api
endmodule // watchdog

//======================================================================
// EOF watchdog.v
//======================================================================
