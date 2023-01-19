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
		output wire          ready
	       );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam ADDR_CTRL        = 8'h08;

  localparam ADDR_STATUS      = 8'h09;
  localparam STATUS_READY_BIT = 0;

  localparam ADDR_PRESCALER   = 8'h0a;
  localparam ADDR_WATCHDOG    = 8'h0b;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [31 : 0] prescaler_reg;
  reg          prescaler_we;

  reg [31 : 0] watchdog_reg;
  reg          watchdog_we;

  reg          start_stop_reg;
  reg          start_stop_new;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0]  tmp_read_data;
  reg           tmp_ready;

  wire          core_ready;
  wire [31 : 0] core_curr_watchdog;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data = tmp_read_data;
  assign ready = tmp_ready;


  //----------------------------------------------------------------
  // core instantiation.
  //----------------------------------------------------------------
  watchdog_core core(
                     .clk(clk),
                     .reset_n(reset_n),

                     .prescaler_init(prescaler_reg),
                     .watchdog_init(watchdog_reg),
                     .start_stop(start_stop_reg),

		     .curr_watchdog(core_curr_watchdog),
                     .ready(core_ready)
                    );


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update
      if (!reset_n) begin
	start_stop_reg <= 1'h0;
	prescaler_reg  <= 32'h0;
	watchdog_reg   <= 32'h0;
      end
      else begin
	start_stop_reg <= start_stop_new;

	if (prescaler_we) begin
	  prescaler_reg <= write_data;
	end

	if (watchdog_we) begin
	  watchdog_reg <= write_data;
	end
      end
    end // reg_update


  //----------------------------------------------------------------
  // api
  //
  // The interface command decoding logic.
  //----------------------------------------------------------------
  always @*
    begin : api
      start_stop_new = 1'h0;
      prescaler_we   = 1'h0;
      watchdog_we    = 1'h0;
      tmp_read_data  = 32'h0;
      tmp_ready      = 1'h0;

      if (cs) begin
	tmp_ready = 1'h1;

        if (we) begin
          if (address == ADDR_CTRL) begin
	    start_stop_new = 1'h1;
	  end

	  if (core_ready) begin
            if (address == ADDR_PRESCALER) begin
	      prescaler_we = 1'h1;
	    end

            if (address == ADDR_WATCHDOG) begin
	      watchdog_we = 1'h1;
	    end
	  end
        end

        else begin
	  if (address == ADDR_STATUS) begin
	    tmp_read_data = {31'h0, core_ready};
	  end

	  if (address == ADDR_PRESCALER) begin
	    tmp_read_data = prescaler_reg;
	  end

	  if (address == ADDR_WATCHDOG) begin
	    if (core_ready) begin
	      tmp_read_data = watchdog_reg;
	    end else begin
	      tmp_read_data = core_curr_watchdog;
	    end
	  end
        end
      end
    end // addr_decoder
endmodule // watchdog

//======================================================================
// EOF watchdog.v
//======================================================================
