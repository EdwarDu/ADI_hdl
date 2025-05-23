// ***************************************************************************
// ***************************************************************************
// Copyright (C) 2024 Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/main/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module gearbox_64b66b (
  input             clk,
  input             reset,

  input      [63:0] i_data,

  output reg [65:0] o_data,
  output reg        o_valid
);

  reg  [63:0] buff_r;
  reg  [ 5:0] gear_cnt;
  wire        invalid;
  wire [65:0] gears [0:32];

  always @(posedge clk) begin
    buff_r <= i_data;
  end

  always @(posedge clk) begin
    if (reset) begin
      gear_cnt <= 6'd0;
    end else if (gear_cnt[5]) begin
      gear_cnt <= 6'd0;
    end else begin
      gear_cnt <= gear_cnt + 1'b1;
    end
  end

  assign invalid = gear_cnt == 0;

  generate
    genvar i;
    for (i=0; i < 33; i=i+1) begin
      if (i == 0) begin
        assign gears[0] = 66'hx; // Invalid, don't care
      end else begin
        assign gears[i] = {i_data[2*i-1:0], buff_r[63:2*(i-1)]};
      end
    end
  endgenerate

  always @(posedge clk) begin
    o_data <= gears[gear_cnt];
    o_valid <= ~invalid;
  end

endmodule
