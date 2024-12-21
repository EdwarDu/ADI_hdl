// ***************************************************************************
// ***************************************************************************
// Copyright (C) 2014-2023 Analog Devices, Inc. All rights reserved.
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

module system_top (

  input       [12:0]      gpio_bd_i,
  output      [ 7:0]      gpio_bd_o,

  inout                   iic_scl,
  inout                   iic_sda,

  input                   inst0_ref_clk0_p,
  input                   inst0_ref_clk0_n,
  input                   inst0_ref_clk1_p,
  input                   inst0_ref_clk1_n,
  input       [ 3:0]      inst0_rx_data_p,
  input       [ 3:0]      inst0_rx_data_n,
  output      [ 3:0]      inst0_tx_data_p,
  output      [ 3:0]      inst0_tx_data_n,
  output                  inst0_rx_sync_p,
  output                  inst0_rx_sync_n,
  output                  inst0_rx_os_sync_p,
  output                  inst0_rx_os_sync_n,
  input                   inst0_tx_sync_p,
  input                   inst0_tx_sync_n,
  input                   inst0_tx_sync_1_p,
  input                   inst0_tx_sync_1_n,
  input                   inst0_sysref_p,
  input                   inst0_sysref_n,

  output                  inst0_sysref_out_p,
  output                  inst0_sysref_out_n,

  output                  inst0_spi_csn_ad9528,
  output                  inst0_spi_csn_adrv9009,
  output                  inst0_spi_clk,
  output                  inst0_spi_mosi,
  input                   inst0_spi_miso,

  inout                   inst0_ad9528_reset_b,
  inout                   inst0_ad9528_sysref_req,
  inout                   inst0_adrv9009_tx1_enable,
  inout                   inst0_adrv9009_tx2_enable,
  inout                   inst0_adrv9009_rx1_enable,
  inout                   inst0_adrv9009_rx2_enable,
  inout                   inst0_adrv9009_test,
  inout                   inst0_adrv9009_reset_b,
  inout                   inst0_adrv9009_gpint,

  inout                   inst0_adrv9009_gpio_00,
  inout                   inst0_adrv9009_gpio_01,
  inout                   inst0_adrv9009_gpio_02,
  inout                   inst0_adrv9009_gpio_03,
  inout                   inst0_adrv9009_gpio_04,
  inout                   inst0_adrv9009_gpio_05,
  inout                   inst0_adrv9009_gpio_06,
  inout                   inst0_adrv9009_gpio_07,
  inout                   inst0_adrv9009_gpio_15,
  inout                   inst0_adrv9009_gpio_08,
  inout                   inst0_adrv9009_gpio_09,
  inout                   inst0_adrv9009_gpio_10,
  inout                   inst0_adrv9009_gpio_11,
  inout                   inst0_adrv9009_gpio_12,
  inout                   inst0_adrv9009_gpio_14,
  inout                   inst0_adrv9009_gpio_13,
  inout                   inst0_adrv9009_gpio_17,
  inout                   inst0_adrv9009_gpio_16,
  inout                   inst0_adrv9009_gpio_18,

  input                   inst1_ref_clk0_p,
  input                   inst1_ref_clk0_n,
  input                   inst1_ref_clk1_p,
  input                   inst1_ref_clk1_n,
  input       [ 3:0]      inst1_rx_data_p,
  input       [ 3:0]      inst1_rx_data_n,
  output      [ 3:0]      inst1_tx_data_p,
  output      [ 3:0]      inst1_tx_data_n,
  output                  inst1_rx_sync_p,
  output                  inst1_rx_sync_n,
  output                  inst1_rx_os_sync_p,
  output                  inst1_rx_os_sync_n,
  input                   inst1_tx_sync_p,
  input                   inst1_tx_sync_n,
  input                   inst1_tx_sync_1_p,
  input                   inst1_tx_sync_1_n,
  input                   inst1_sysref_p,
  input                   inst1_sysref_n,

  output                  inst1_sysref_out_p,
  output                  inst1_sysref_out_n,

  output                  inst1_spi_csn_ad9528,
  output                  inst1_spi_csn_adrv9009,
  output                  inst1_spi_clk,
  output                  inst1_spi_mosi,
  input                   inst1_spi_miso,

  inout                   inst1_ad9528_reset_b,
  inout                   inst1_ad9528_sysref_req,
  inout                   inst1_adrv9009_tx1_enable,
  inout                   inst1_adrv9009_tx2_enable,
  inout                   inst1_adrv9009_rx1_enable,
  inout                   inst1_adrv9009_rx2_enable,
  inout                   inst1_adrv9009_test,
  inout                   inst1_adrv9009_reset_b,
  inout                   inst1_adrv9009_gpint,

  inout                   inst1_adrv9009_gpio_00,
  inout                   inst1_adrv9009_gpio_01,
  inout                   inst1_adrv9009_gpio_02,
  inout                   inst1_adrv9009_gpio_03,
  inout                   inst1_adrv9009_gpio_04,
  inout                   inst1_adrv9009_gpio_05,
  inout                   inst1_adrv9009_gpio_06,
  inout                   inst1_adrv9009_gpio_07,
  inout                   inst1_adrv9009_gpio_15,
  inout                   inst1_adrv9009_gpio_08,
  inout                   inst1_adrv9009_gpio_09,
  inout                   inst1_adrv9009_gpio_10,
  inout                   inst1_adrv9009_gpio_11,
  inout                   inst1_adrv9009_gpio_12,
  inout                   inst1_adrv9009_gpio_14,
  inout                   inst1_adrv9009_gpio_13,
  inout                   inst1_adrv9009_gpio_17,
  inout                   inst1_adrv9009_gpio_16,
  inout                   inst1_adrv9009_gpio_18
);

  // internal signals

  wire        [94:0]      gpio_i;
  wire        [94:0]      gpio_o;
  wire        [94:0]      gpio_t;
  wire        [20:0]      gpio_bd;
  wire        [ 2:0]      inst0_spi_csn;
  wire                    inst0_ref_clk0;
  wire                    inst0_ref_clk1;
  wire                    inst0_rx_sync;
  wire                    inst0_rx_os_sync;
  wire                    inst0_tx_sync;

  wire        [ 2:0]      inst1_spi_csn;
  wire                    inst1_ref_clk0;
  wire                    inst1_ref_clk1;
  wire                    inst1_rx_sync;
  wire                    inst1_rx_os_sync;
  wire                    inst1_tx_sync;

  wire                    sysref;

  // assign gpio_i[94:92] = gpio_o[94:92];
  assign gpio_i[31:21] = gpio_o[31:21];

  assign sysref_out = 0;

  // instantiations

  IBUFDS_GTE4 inst0_i_ibufds_rx_ref_clk (
    .CEB (1'd0),
    .I (inst0_ref_clk0_p),
    .IB (inst0_ref_clk0_n),
    .O (inst0_ref_clk0),
    .ODIV2 ());

  IBUFDS_GTE4 inst0_i_ibufds_ref_clk1 (
    .CEB (1'd0),
    .I (inst0_ref_clk1_p),
    .IB (inst0_ref_clk1_n),
    .O (inst0_ref_clk1),
    .ODIV2 (inst0_ref_clk1_odiv2));

  BUFG_GT inst0_i_bufg_ref_clk (
    .I (inst0_ref_clk1_odiv2),
    .O (inst0_ref_clk1_bufg));

  OBUFDS inst0_i_obufds_rx_sync (
    .I (inst0_rx_sync),
    .O (inst0_rx_sync_p),
    .OB (inst0_rx_sync_n));

  OBUFDS inst0_i_obufds_rx_os_sync (
    .I (inst0_rx_os_sync),
    .O (inst0_rx_os_sync_p),
    .OB (inst0_rx_os_sync_n));

  OBUFDS inst0_i_obufds_sysref_out (
    .I (inst0_sysref_out),
    .O (inst0_sysref_out_p),
    .OB (inst0_sysref_out_n));

  IBUFDS inst0_i_ibufds_tx_sync (
    .I (inst0_tx_sync_p),
    .IB (inst0_tx_sync_n),
    .O (inst0_tx_sync));

  IBUFDS inst0_i_ibufds_tx_sync_1 (
    .I (inst0_tx_sync_1_p),
    .IB (inst0_tx_sync_1_n),
    .O (inst0_tx_sync_1));

  IBUFDS inst0_i_ibufds_sysref (
    .I (inst0_sysref_p),
    .IB (inst0_sysref_n),
    .O (inst0_sysref));

  // INST1
  IBUFDS_GTE4 inst1_i_ibufds_rx_ref_clk (
    .CEB (1'd0),
    .I (inst1_ref_clk0_p),
    .IB (inst1_ref_clk0_n),
    .O (inst1_ref_clk0),
    .ODIV2 ());

  IBUFDS_GTE4 inst1_i_ibufds_ref_clk1 (
    .CEB (1'd0),
    .I (inst1_ref_clk1_p),
    .IB (inst1_ref_clk1_n),
    .O (inst1_ref_clk1),
    .ODIV2 (inst1_ref_clk1_odiv2));

  BUFG_GT inst1_i_bufg_ref_clk (
    .I (inst1_ref_clk1_odiv2),
    .O (inst1_ref_clk1_bufg));

  OBUFDS inst1_i_obufds_rx_sync (
    .I (inst1_rx_sync),
    .O (inst1_rx_sync_p),
    .OB (inst1_rx_sync_n));

  OBUFDS inst1_i_obufds_rx_os_sync (
    .I (inst1_rx_os_sync),
    .O (inst1_rx_os_sync_p),
    .OB (inst1_rx_os_sync_n));

  OBUFDS inst1_i_obufds_sysref_out (
    .I (inst1_sysref_out),
    .O (inst1_sysref_out_p),
    .OB (inst1_sysref_out_n));

  IBUFDS inst1_i_ibufds_tx_sync (
    .I (inst1_tx_sync_p),
    .IB (inst1_tx_sync_n),
    .O (inst1_tx_sync));

  IBUFDS inst1_i_ibufds_tx_sync_1 (
    .I (inst1_tx_sync_1_p),
    .IB (inst1_tx_sync_1_n),
    .O (inst1_tx_sync_1));

  IBUFDS inst1_i_ibufds_sysref (
    .I (inst1_sysref_p),
    .IB (inst1_sysref_n),
    .O (inst1_sysref));

  ad_iobuf #(
    .DATA_WIDTH(28)
  ) inst0_i_iobuf (
    .dio_t ({gpio_t[59:32]}),
    .dio_i ({gpio_o[59:32]}),
    .dio_o ({gpio_i[59:32]}),
    .dio_p ({ inst0_ad9528_reset_b,       // 59
              inst0_ad9528_sysref_req,    // 58
              inst0_adrv9009_tx1_enable,  // 57
              inst0_adrv9009_tx2_enable,  // 56
              inst0_adrv9009_rx1_enable,  // 55
              inst0_adrv9009_rx2_enable,  // 54
              inst0_adrv9009_test,        // 53
              inst0_adrv9009_reset_b,     // 52
              inst0_adrv9009_gpint,       // 51
              inst0_adrv9009_gpio_00,     // 50
              inst0_adrv9009_gpio_01,     // 49
              inst0_adrv9009_gpio_02,     // 48
              inst0_adrv9009_gpio_03,     // 47
              inst0_adrv9009_gpio_04,     // 46
              inst0_adrv9009_gpio_05,     // 45
              inst0_adrv9009_gpio_06,     // 44
              inst0_adrv9009_gpio_07,     // 43
              inst0_adrv9009_gpio_15,     // 42
              inst0_adrv9009_gpio_08,     // 41
              inst0_adrv9009_gpio_09,     // 40
              inst0_adrv9009_gpio_10,     // 39
              inst0_adrv9009_gpio_11,     // 38
              inst0_adrv9009_gpio_12,     // 37
              inst0_adrv9009_gpio_14,     // 36
              inst0_adrv9009_gpio_13,     // 35
              inst0_adrv9009_gpio_17,     // 34
              inst0_adrv9009_gpio_16,     // 33
              inst0_adrv9009_gpio_18}));  // 32

  ad_iobuf #(
    .DATA_WIDTH(28)
  ) inst1_i_iobuf (
    .dio_t ({gpio_t[91:64]}),
    .dio_i ({gpio_o[91:64]}),
    .dio_o ({gpio_i[91:64]}),
    .dio_p ({ inst1_ad9528_reset_b,       // 59
              inst1_ad9528_sysref_req,    // 58
              inst1_adrv9009_tx1_enable,  // 57
              inst1_adrv9009_tx2_enable,  // 56
              inst1_adrv9009_rx1_enable,  // 55
              inst1_adrv9009_rx2_enable,  // 54
              inst1_adrv9009_test,        // 53
              inst1_adrv9009_reset_b,     // 52
              inst1_adrv9009_gpint,       // 51
              inst1_adrv9009_gpio_00,     // 50
              inst1_adrv9009_gpio_01,     // 49
              inst1_adrv9009_gpio_02,     // 48
              inst1_adrv9009_gpio_03,     // 47
              inst1_adrv9009_gpio_04,     // 46
              inst1_adrv9009_gpio_05,     // 45
              inst1_adrv9009_gpio_06,     // 44
              inst1_adrv9009_gpio_07,     // 43
              inst1_adrv9009_gpio_15,     // 42
              inst1_adrv9009_gpio_08,     // 41
              inst1_adrv9009_gpio_09,     // 40
              inst1_adrv9009_gpio_10,     // 39
              inst1_adrv9009_gpio_11,     // 38
              inst1_adrv9009_gpio_12,     // 37
              inst1_adrv9009_gpio_14,     // 36
              inst1_adrv9009_gpio_13,     // 35
              inst1_adrv9009_gpio_17,     // 34
              inst1_adrv9009_gpio_16,     // 33
              inst1_adrv9009_gpio_18}));  // 32

  assign gpio_i[ 7: 0] = gpio_o[ 7: 0];
  assign gpio_i[20: 8] = gpio_bd_i;
  assign gpio_bd_o = gpio_o[ 7: 0];

  assign inst0_spi_csn_ad9528 =  inst0_spi_csn[0];
  assign inst0_spi_csn_adrv9009 =  inst0_spi_csn[1];

  assign inst1_spi_csn_ad9528 =  inst1_spi_csn[0];
  assign inst1_spi_csn_adrv9009 =  inst1_spi_csn[1];

  system_wrapper i_system_wrapper (
    .inst0_dac_fifo_bypass (gpio_o[60]),
    .inst0_adc_fir_filter_active (gpio_o[61]),
    .inst0_dac_fir_filter_active (gpio_o[62]),
    .inst1_dac_fifo_bypass (gpio_o[92]),
    .inst1_adc_fir_filter_active (gpio_o[93]),
    .inst1_dac_fir_filter_active (gpio_o[94]),
    .gpio_i (gpio_i),
    .gpio_o (gpio_o),
    .gpio_t (gpio_t),
    .inst0_rx_data_0_n (inst0_rx_data_n[0]),
    .inst0_rx_data_0_p (inst0_rx_data_p[0]),
    .inst0_rx_data_1_n (inst0_rx_data_n[1]),
    .inst0_rx_data_1_p (inst0_rx_data_p[1]),
    .inst0_rx_data_2_n (inst0_rx_data_n[2]),
    .inst0_rx_data_2_p (inst0_rx_data_p[2]),
    .inst0_rx_data_3_n (inst0_rx_data_n[3]),
    .inst0_rx_data_3_p (inst0_rx_data_p[3]),
    .inst0_rx_ref_clk_0 (inst0_ref_clk1),
    .inst0_rx_ref_clk_2 (inst0_ref_clk1),
    .inst0_rx_sync_0 (inst0_rx_sync),
    .inst0_rx_sync_2 (inst0_rx_os_sync),
    .inst0_rx_sysref_0 (inst0_sysref),
    .inst0_rx_sysref_2 (inst0_sysref),
    .inst1_rx_data_0_n (inst1_rx_data_n[0]),
    .inst1_rx_data_0_p (inst1_rx_data_p[0]),
    .inst1_rx_data_1_n (inst1_rx_data_n[1]),
    .inst1_rx_data_1_p (inst1_rx_data_p[1]),
    .inst1_rx_data_2_n (inst1_rx_data_n[2]),
    .inst1_rx_data_2_p (inst1_rx_data_p[2]),
    .inst1_rx_data_3_n (inst1_rx_data_n[3]),
    .inst1_rx_data_3_p (inst1_rx_data_p[3]),
    .inst1_rx_ref_clk_0 (inst1_ref_clk1),
    .inst1_rx_ref_clk_2 (inst1_ref_clk1),
    .inst1_rx_sync_0 (inst1_rx_sync),
    .inst1_rx_sync_2 (inst1_rx_os_sync),
    .inst1_rx_sysref_0 (inst1_sysref),
    .inst1_rx_sysref_2 (inst1_sysref),
    .spi0_sclk (inst0_spi_clk),
    .spi0_csn (inst0_spi_csn),
    .spi0_miso (inst0_spi_miso),
    .spi0_mosi (inst0_spi_mosi),
    .spi1_sclk (inst1_spi_clk),
    .spi1_csn (inst1_spi_csn),
    .spi1_miso (inst1_spi_miso),
    .spi1_mosi (inst1_spi_mosi),
    .inst0_tx_data_0_n (inst0_tx_data_n[0]),
    .inst0_tx_data_0_p (inst0_tx_data_p[0]),
    .inst0_tx_data_1_n (inst0_tx_data_n[1]),
    .inst0_tx_data_1_p (inst0_tx_data_p[1]),
    .inst0_tx_data_2_n (inst0_tx_data_n[2]),
    .inst0_tx_data_2_p (inst0_tx_data_p[2]),
    .inst0_tx_data_3_n (inst0_tx_data_n[3]),
    .inst0_tx_data_3_p (inst0_tx_data_p[3]),
    .inst0_tx_ref_clk_0 (inst0_ref_clk1),
    .inst0_tx_sync_0 (inst0_tx_sync),
    .inst0_tx_sysref_0 (inst0_sysref),
    .inst0_ref_clk (inst0_ref_clk1_bufg),
    .inst1_tx_data_0_n (inst1_tx_data_n[0]),
    .inst1_tx_data_0_p (inst1_tx_data_p[0]),
    .inst1_tx_data_1_n (inst1_tx_data_n[1]),
    .inst1_tx_data_1_p (inst1_tx_data_p[1]),
    .inst1_tx_data_2_n (inst1_tx_data_n[2]),
    .inst1_tx_data_2_p (inst1_tx_data_p[2]),
    .inst1_tx_data_3_n (inst1_tx_data_n[3]),
    .inst1_tx_data_3_p (inst1_tx_data_p[3]),
    .inst1_tx_ref_clk_0 (inst1_ref_clk1),
    .inst1_tx_sync_0 (inst1_tx_sync),
    .inst1_tx_sysref_0 (inst1_sysref),
    .inst1_ref_clk (inst1_ref_clk1_bufg));

endmodule
