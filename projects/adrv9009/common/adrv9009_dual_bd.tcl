###############################################################################
## Copyright (C) 2018-2024 Analog Devices, Inc. All rights reserved.
### SPDX short identifier: ADIBSD
###############################################################################

# Parameter description:
#   [TX/RX/RX_OS]_JESD_M  : Number of converters per link
#   [TX/RX/RX_OS]_JESD_L  : Number of lanes per link
#   [TX/RX/RX_OS]_JESD_S  : Number of samples per frame
#   [TX/RX/RX_OS]_JESD_NP : Number of bits per sample

set MAX_TX_NUM_OF_LANES 4
set MAX_RX_NUM_OF_LANES 2
set MAX_RX_OS_NUM_OF_LANES 2

set DATAPATH_WIDTH 4
source $ad_hdl_dir/library/jesd204/scripts/jesd204.tcl
source $ad_hdl_dir/projects/common/xilinx/adi_fir_filter_bd.tcl

# TX parameters
set TX_NUM_OF_LANES $ad_project_params(TX_JESD_L)      ; # L
set TX_NUM_OF_CONVERTERS $ad_project_params(TX_JESD_M) ; # M
set TX_SAMPLES_PER_FRAME $ad_project_params(TX_JESD_S) ; # S
set TX_SAMPLE_WIDTH 16                                 ; # N/NP

set TX_TPL_WIDTH [ expr { [info exists ad_project_params(TX_TPL_WIDTH)] \
                          ? $ad_project_params(TX_TPL_WIDTH) : {} } ]

set TX_DATAPATH_WIDTH [adi_jesd204_calc_tpl_width $DATAPATH_WIDTH $TX_NUM_OF_LANES $TX_NUM_OF_CONVERTERS $TX_SAMPLES_PER_FRAME $TX_SAMPLE_WIDTH $TX_TPL_WIDTH]
set TX_SAMPLES_PER_CHANNEL [expr $TX_NUM_OF_LANES * 8 * $TX_DATAPATH_WIDTH / ($TX_NUM_OF_CONVERTERS * $TX_SAMPLE_WIDTH)]

# RX parameters
set RX_NUM_OF_LANES $ad_project_params(RX_JESD_L)      ; # L
set RX_NUM_OF_CONVERTERS $ad_project_params(RX_JESD_M) ; # M
set RX_SAMPLES_PER_FRAME $ad_project_params(RX_JESD_S) ; # S
set RX_SAMPLE_WIDTH 16                                 ; # N/NP

set RX_OCTETS_PER_FRAME [expr $RX_NUM_OF_CONVERTERS * $RX_SAMPLES_PER_FRAME * $RX_SAMPLE_WIDTH / (8 * $RX_NUM_OF_LANES)] ; # F
set DPW [expr max(4, $RX_OCTETS_PER_FRAME)] ; #max(4, F)
set RX_SAMPLES_PER_CHANNEL [expr $RX_NUM_OF_LANES * 8 * $DPW / ($RX_NUM_OF_CONVERTERS * $RX_SAMPLE_WIDTH)] ; # L * 8 * DPW / (M* N)

set adc_dma_data_width [expr $RX_NUM_OF_LANES * 8 * $DPW]

# RX Observation parameters
set RX_OS_NUM_OF_LANES $ad_project_params(RX_OS_JESD_L)      ; # L
set RX_OS_NUM_OF_CONVERTERS $ad_project_params(RX_OS_JESD_M) ; # M
set RX_OS_SAMPLES_PER_FRAME $ad_project_params(RX_OS_JESD_S) ; # S
set RX_OS_SAMPLE_WIDTH 16                                    ; # N/NP

set RX_OS_TPL_WIDTH [ expr { [info exists ad_project_params(RX_OS_TPL_WIDTH)] \
                          ? $ad_project_params(RX_OS_TPL_WIDTH) : {} } ]

set RX_OS_DATAPATH_WIDTH [adi_jesd204_calc_tpl_width $DATAPATH_WIDTH $RX_OS_NUM_OF_LANES $RX_OS_NUM_OF_CONVERTERS $RX_OS_SAMPLES_PER_FRAME $RX_OS_SAMPLE_WIDTH $RX_OS_TPL_WIDTH]
set RX_OS_SAMPLES_PER_CHANNEL [expr $RX_OS_NUM_OF_LANES * 8 * $RX_OS_DATAPATH_WIDTH / ($RX_OS_NUM_OF_CONVERTERS * $RX_OS_SAMPLE_WIDTH)]

set inst0_dac_fifo_name inst0_axi_adrv9009_dacfifo
set dac_data_width [expr $TX_SAMPLE_WIDTH * $TX_NUM_OF_CONVERTERS * $TX_SAMPLES_PER_CHANNEL]

# adrv9009
create_bd_port -dir I inst0_ref_clk

create_bd_port -dir I inst0_dac_fifo_bypass
create_bd_port -dir I inst0_adc_fir_filter_active
create_bd_port -dir I inst0_dac_fir_filter_active

# dac peripherals
ad_ip_instance axi_clkgen inst0_axi_adrv9009_tx_clkgen
ad_ip_parameter inst0_axi_adrv9009_tx_clkgen CONFIG.ID 2
ad_ip_parameter inst0_axi_adrv9009_tx_clkgen CONFIG.CLKIN_PERIOD 4
ad_ip_parameter inst0_axi_adrv9009_tx_clkgen CONFIG.VCO_DIV 1
ad_ip_parameter inst0_axi_adrv9009_tx_clkgen CONFIG.VCO_MUL 4
ad_ip_parameter inst0_axi_adrv9009_tx_clkgen CONFIG.CLK0_DIV 4
# ad_ip_parameter inst0_axi_adrv9009_tx_clkgen CONFIG.ENABLE_CLKOUT1 {true}
# ad_ip_parameter inst0_axi_adrv9009_tx_clkgen CONFIG.CLK1_DIV 4

ad_ip_instance axi_adxcvr inst0_axi_adrv9009_tx_xcvr
ad_ip_parameter inst0_axi_adrv9009_tx_xcvr CONFIG.NUM_OF_LANES $MAX_TX_NUM_OF_LANES
ad_ip_parameter inst0_axi_adrv9009_tx_xcvr CONFIG.QPLL_ENABLE 1
ad_ip_parameter inst0_axi_adrv9009_tx_xcvr CONFIG.TX_OR_RX_N 1
ad_ip_parameter inst0_axi_adrv9009_tx_xcvr CONFIG.SYS_CLK_SEL 3
ad_ip_parameter inst0_axi_adrv9009_tx_xcvr CONFIG.OUT_CLK_SEL 3

adi_axi_jesd204_tx_create inst0_axi_adrv9009_tx_jesd $TX_NUM_OF_LANES

ad_ip_instance util_upack2 inst0_util_adrv9009_tx_upack [list \
  NUM_OF_CHANNELS $TX_NUM_OF_CONVERTERS \
  SAMPLES_PER_CHANNEL $TX_SAMPLES_PER_CHANNEL \
  SAMPLE_DATA_WIDTH $TX_SAMPLE_WIDTH \
]

ad_add_interpolation_filter "inst0_tx_fir_interpolator" 8 $TX_NUM_OF_CONVERTERS 2 {122.88} {15.36} \
                             "$ad_hdl_dir/library/util_fir_int/coefile_int.coe"


adi_tpl_jesd204_tx_create inst0_tx_adrv9009_tpl_core $TX_NUM_OF_LANES \
                                               $TX_NUM_OF_CONVERTERS \
                                               $TX_SAMPLES_PER_FRAME \
                                               $TX_SAMPLE_WIDTH

ad_ip_instance axi_dmac inst0_axi_adrv9009_tx_dma
ad_ip_parameter inst0_axi_adrv9009_tx_dma CONFIG.DMA_TYPE_SRC 0
ad_ip_parameter inst0_axi_adrv9009_tx_dma CONFIG.DMA_TYPE_DEST 1
ad_ip_parameter inst0_axi_adrv9009_tx_dma CONFIG.CYCLIC 1
ad_ip_parameter inst0_axi_adrv9009_tx_dma CONFIG.ASYNC_CLK_DEST_REQ 1
ad_ip_parameter inst0_axi_adrv9009_tx_dma CONFIG.ASYNC_CLK_SRC_DEST 1
ad_ip_parameter inst0_axi_adrv9009_tx_dma CONFIG.ASYNC_CLK_REQ_SRC 1
ad_ip_parameter inst0_axi_adrv9009_tx_dma CONFIG.DMA_2D_TRANSFER 0
ad_ip_parameter inst0_axi_adrv9009_tx_dma CONFIG.DMA_DATA_WIDTH_DEST $dac_data_width
ad_ip_parameter inst0_axi_adrv9009_tx_dma CONFIG.MAX_BYTES_PER_BURST 256
ad_ip_parameter inst0_axi_adrv9009_tx_dma CONFIG.AXI_SLICE_DEST true
ad_ip_parameter inst0_axi_adrv9009_tx_dma CONFIG.AXI_SLICE_SRC true

ad_dacfifo_create $inst0_dac_fifo_name $dac_data_width $dac_data_width $dac_fifo_address_width

# adc peripherals
ad_ip_instance axi_clkgen inst0_axi_adrv9009_rx_clkgen
ad_ip_parameter inst0_axi_adrv9009_rx_clkgen CONFIG.ID 2
ad_ip_parameter inst0_axi_adrv9009_rx_clkgen CONFIG.CLKIN_PERIOD 4
ad_ip_parameter inst0_axi_adrv9009_rx_clkgen CONFIG.VCO_DIV 1
ad_ip_parameter inst0_axi_adrv9009_rx_clkgen CONFIG.VCO_MUL 4
ad_ip_parameter inst0_axi_adrv9009_rx_clkgen CONFIG.CLK0_DIV 4
ad_ip_parameter inst0_axi_adrv9009_rx_clkgen CONFIG.ENABLE_CLKOUT1 {true}
ad_ip_parameter inst0_axi_adrv9009_rx_clkgen CONFIG.CLK1_DIV 8

ad_ip_instance axi_adxcvr inst0_axi_adrv9009_rx_xcvr
ad_ip_parameter inst0_axi_adrv9009_rx_xcvr CONFIG.NUM_OF_LANES $MAX_RX_NUM_OF_LANES
ad_ip_parameter inst0_axi_adrv9009_rx_xcvr CONFIG.QPLL_ENABLE 0
ad_ip_parameter inst0_axi_adrv9009_rx_xcvr CONFIG.TX_OR_RX_N 0
ad_ip_parameter inst0_axi_adrv9009_rx_xcvr CONFIG.SYS_CLK_SEL 0
ad_ip_parameter inst0_axi_adrv9009_rx_xcvr CONFIG.OUT_CLK_SEL 3

adi_axi_jesd204_rx_create inst0_axi_adrv9009_rx_jesd $RX_NUM_OF_LANES
ad_ip_parameter inst0_axi_adrv9009_rx_jesd/rx CONFIG.SYSREF_IOB false
ad_ip_parameter inst0_axi_adrv9009_rx_jesd/rx CONFIG.TPL_DATA_PATH_WIDTH $DPW

ad_ip_instance util_cpack2 inst0_util_adrv9009_rx_cpack [list \
  NUM_OF_CHANNELS $RX_NUM_OF_CONVERTERS \
  SAMPLES_PER_CHANNEL $RX_SAMPLES_PER_CHANNEL \
  SAMPLE_DATA_WIDTH $RX_SAMPLE_WIDTH \
  ]

adi_tpl_jesd204_rx_create inst0_rx_adrv9009_tpl_core $RX_NUM_OF_LANES \
                                               $RX_NUM_OF_CONVERTERS \
                                               $RX_SAMPLES_PER_FRAME \
                                               $RX_SAMPLE_WIDTH

ad_add_decimation_filter "inst0_rx_fir_decimator" 8 $RX_NUM_OF_CONVERTERS 1 {122.88} {122.88} \
                          "$ad_hdl_dir/library/util_fir_int/coefile_int.coe"

ad_ip_instance axi_dmac inst0_axi_adrv9009_rx_dma
ad_ip_parameter inst0_axi_adrv9009_rx_dma CONFIG.DMA_TYPE_SRC 2
ad_ip_parameter inst0_axi_adrv9009_rx_dma CONFIG.DMA_TYPE_DEST 0
ad_ip_parameter inst0_axi_adrv9009_rx_dma CONFIG.CYCLIC 0
ad_ip_parameter inst0_axi_adrv9009_rx_dma CONFIG.SYNC_TRANSFER_START 1
ad_ip_parameter inst0_axi_adrv9009_rx_dma CONFIG.ASYNC_CLK_DEST_REQ 1
ad_ip_parameter inst0_axi_adrv9009_rx_dma CONFIG.ASYNC_CLK_SRC_DEST 1
ad_ip_parameter inst0_axi_adrv9009_rx_dma CONFIG.ASYNC_CLK_REQ_SRC 1
ad_ip_parameter inst0_axi_adrv9009_rx_dma CONFIG.DMA_2D_TRANSFER 0
ad_ip_parameter inst0_axi_adrv9009_rx_dma CONFIG.DMA_DATA_WIDTH_SRC $adc_dma_data_width
ad_ip_parameter inst0_axi_adrv9009_rx_dma CONFIG.MAX_BYTES_PER_BURST 256
ad_ip_parameter inst0_axi_adrv9009_rx_dma CONFIG.AXI_SLICE_DEST true
ad_ip_parameter inst0_axi_adrv9009_rx_dma CONFIG.AXI_SLICE_SRC true

# # adc-os peripherals
# ad_ip_instance axi_clkgen inst0_axi_adrv9009_rx_os_clkgen
# ad_ip_parameter inst0_axi_adrv9009_rx_os_clkgen CONFIG.ID 2
# ad_ip_parameter inst0_axi_adrv9009_rx_os_clkgen CONFIG.CLKIN_PERIOD 4
# ad_ip_parameter inst0_axi_adrv9009_rx_os_clkgen CONFIG.VCO_DIV 1
# ad_ip_parameter inst0_axi_adrv9009_rx_os_clkgen CONFIG.VCO_MUL 4
# ad_ip_parameter inst0_axi_adrv9009_rx_os_clkgen CONFIG.CLK0_DIV 4

ad_ip_instance axi_adxcvr inst0_axi_adrv9009_rx_os_xcvr
ad_ip_parameter inst0_axi_adrv9009_rx_os_xcvr CONFIG.NUM_OF_LANES $MAX_RX_OS_NUM_OF_LANES
ad_ip_parameter inst0_axi_adrv9009_rx_os_xcvr CONFIG.QPLL_ENABLE 0
ad_ip_parameter inst0_axi_adrv9009_rx_os_xcvr CONFIG.TX_OR_RX_N 0
ad_ip_parameter inst0_axi_adrv9009_rx_os_xcvr CONFIG.SYS_CLK_SEL 0
ad_ip_parameter inst0_axi_adrv9009_rx_os_xcvr CONFIG.OUT_CLK_SEL 3

adi_axi_jesd204_rx_create inst0_axi_adrv9009_rx_os_jesd $RX_OS_NUM_OF_LANES

ad_ip_instance util_cpack2 inst0_util_adrv9009_rx_os_cpack [list \
  NUM_OF_CHANNELS $RX_OS_NUM_OF_CONVERTERS \
  SAMPLES_PER_CHANNEL $RX_OS_SAMPLES_PER_CHANNEL\
  SAMPLE_DATA_WIDTH $RX_OS_SAMPLE_WIDTH \
]

adi_tpl_jesd204_rx_create inst0_rx_os_adrv9009_tpl_core $RX_OS_NUM_OF_LANES \
                                                  $RX_OS_NUM_OF_CONVERTERS \
                                                  $RX_OS_SAMPLES_PER_FRAME \
                                                  $RX_OS_SAMPLE_WIDTH

ad_ip_instance axi_dmac inst0_axi_adrv9009_rx_os_dma
ad_ip_parameter inst0_axi_adrv9009_rx_os_dma CONFIG.DMA_TYPE_SRC 2
ad_ip_parameter inst0_axi_adrv9009_rx_os_dma CONFIG.DMA_TYPE_DEST 0
ad_ip_parameter inst0_axi_adrv9009_rx_os_dma CONFIG.CYCLIC 0
ad_ip_parameter inst0_axi_adrv9009_rx_os_dma CONFIG.SYNC_TRANSFER_START 1
ad_ip_parameter inst0_axi_adrv9009_rx_os_dma CONFIG.ASYNC_CLK_DEST_REQ 1
ad_ip_parameter inst0_axi_adrv9009_rx_os_dma CONFIG.ASYNC_CLK_SRC_DEST 1
ad_ip_parameter inst0_axi_adrv9009_rx_os_dma CONFIG.ASYNC_CLK_REQ_SRC 1
ad_ip_parameter inst0_axi_adrv9009_rx_os_dma CONFIG.DMA_2D_TRANSFER 0
ad_ip_parameter inst0_axi_adrv9009_rx_os_dma CONFIG.DMA_DATA_WIDTH_SRC [expr $RX_OS_SAMPLE_WIDTH * \
                                                                       $RX_OS_NUM_OF_CONVERTERS * \
                                                                       $RX_OS_SAMPLES_PER_CHANNEL];
ad_ip_parameter inst0_axi_adrv9009_rx_os_dma CONFIG.MAX_BYTES_PER_BURST 256
ad_ip_parameter inst0_axi_adrv9009_rx_os_dma CONFIG.AXI_SLICE_DEST true
ad_ip_parameter inst0_axi_adrv9009_rx_os_dma CONFIG.AXI_SLICE_SRC true

# common cores
ad_ip_instance util_adxcvr inst0_util_adrv9009_xcvr
ad_ip_parameter inst0_util_adrv9009_xcvr CONFIG.RX_NUM_OF_LANES [expr $MAX_RX_NUM_OF_LANES+$MAX_RX_OS_NUM_OF_LANES]
ad_ip_parameter inst0_util_adrv9009_xcvr CONFIG.TX_NUM_OF_LANES $MAX_TX_NUM_OF_LANES
ad_ip_parameter inst0_util_adrv9009_xcvr CONFIG.TX_OUT_DIV 1
ad_ip_parameter inst0_util_adrv9009_xcvr CONFIG.CPLL_FBDIV 4
ad_ip_parameter inst0_util_adrv9009_xcvr CONFIG.CPLL_FBDIV_4_5 5
ad_ip_parameter inst0_util_adrv9009_xcvr CONFIG.RX_CLK25_DIV 10
ad_ip_parameter inst0_util_adrv9009_xcvr CONFIG.TX_CLK25_DIV 10
ad_ip_parameter inst0_util_adrv9009_xcvr CONFIG.RX_PMA_CFG 0x001E7080
ad_ip_parameter inst0_util_adrv9009_xcvr CONFIG.RX_CDR_CFG 0x0b000023ff10400020
ad_ip_parameter inst0_util_adrv9009_xcvr CONFIG.QPLL_FBDIV 0x080

# xcvr interfaces
set inst0_tx_ref_clk     inst0_tx_ref_clk_0
set inst0_rx_ref_clk     inst0_rx_ref_clk_0
set inst0_rx_obs_ref_clk inst0_rx_ref_clk_$MAX_RX_NUM_OF_LANES

create_bd_port -dir I $inst0_tx_ref_clk
create_bd_port -dir I $inst0_rx_ref_clk
create_bd_port -dir I $inst0_rx_obs_ref_clk
ad_connect  $sys_cpu_resetn inst0_util_adrv9009_xcvr/up_rstn
ad_connect  $sys_cpu_clk inst0_util_adrv9009_xcvr/up_clk

# Tx
ad_connect inst0_adrv9009_tx_device_clk inst0_axi_adrv9009_tx_clkgen/clk_0

if {$TX_NUM_OF_LANES == 4} {
  ad_xcvrcon inst0_util_adrv9009_xcvr inst0_axi_adrv9009_tx_xcvr \
    inst0_axi_adrv9009_tx_jesd {0 3 2 1} \
    inst0_adrv9009_tx_device_clk {} $MAX_TX_NUM_OF_LANES \
    {} 1 "inst0_"
} else {
    if {$TX_NUM_OF_LANES == 2} {
      ad_xcvrcon inst0_util_adrv9009_xcvr inst0_axi_adrv9009_tx_xcvr \
        inst0_axi_adrv9009_tx_jesd {0 3 2 1} \
        inst0_adrv9009_tx_device_clk {} $MAX_TX_NUM_OF_LANES \
        {0 2} 1 "inst0_"
    } else {
      ad_xcvrcon inst0_util_adrv9009_xcvr inst0_axi_adrv9009_tx_xcvr \
        inst0_axi_adrv9009_tx_jesd {0 3 2 1} \
        inst0_adrv9009_tx_device_clk {} $MAX_TX_NUM_OF_LANES \
        {0} 1 "inst0_"
    }
}
ad_connect inst0_ref_clk inst0_axi_adrv9009_tx_clkgen/clk
ad_xcvrpll $inst0_tx_ref_clk inst0_util_adrv9009_xcvr/qpll_ref_clk_0
ad_xcvrpll inst0_axi_adrv9009_tx_xcvr/up_pll_rst inst0_util_adrv9009_xcvr/up_qpll_rst_0

# Rx
if {$RX_NUM_OF_LANES == 2} {
  ad_connect inst0_adrv9009_rx_device_clk inst0_axi_adrv9009_rx_clkgen/clk_0
  ad_xcvrcon inst0_util_adrv9009_xcvr inst0_axi_adrv9009_rx_xcvr \
    inst0_axi_adrv9009_rx_jesd {} \
    inst0_adrv9009_rx_device_clk {} $MAX_RX_NUM_OF_LANES \
    {} 1 "inst0_"
} else {
  # for RX_NUM_OF_LANES = 1, RX_OCTETS_PER_FRAME = 8
  ad_connect inst0_adrv9009_rx_device_clk inst0_axi_adrv9009_rx_clkgen/clk_1
  ad_connect inst0_adrv9009_rx_link_clk inst0_axi_adrv9009_rx_clkgen/clk_0
  ad_xcvrcon inst0_util_adrv9009_xcvr inst0_axi_adrv9009_rx_xcvr \
    inst0_axi_adrv9009_rx_jesd {0 1 2 3} \
    inst0_adrv9009_rx_link_clk inst0_adrv9009_rx_device_clk $MAX_RX_NUM_OF_LANES \
    {0} 0 "inst0_"
  ad_connect inst0_axi_adrv9009_rx_xcvr/up_es_0 inst0_util_adrv9009_xcvr/up_es_0
  ad_connect inst0_axi_adrv9009_rx_xcvr/up_es_1 inst0_util_adrv9009_xcvr/up_es_1
  ad_connect inst0_axi_adrv9009_rx_xcvr/up_ch_0 inst0_util_adrv9009_xcvr/up_rx_0
  ad_connect inst0_axi_adrv9009_rx_xcvr/up_ch_1 inst0_util_adrv9009_xcvr/up_rx_1

  ad_connect inst0_adrv9009_rx_link_clk inst0_util_adrv9009_xcvr/rx_clk_0
  ad_connect inst0_adrv9009_rx_link_clk inst0_util_adrv9009_xcvr/rx_clk_1

  create_bd_port -dir I inst0_rx_data_0_p
  create_bd_port -dir I inst0_rx_data_0_n
  create_bd_port -dir I inst0_rx_data_1_p
  create_bd_port -dir I inst0_rx_data_1_n
  ad_connect inst0_util_adrv9009_xcvr/rx_0_p inst0_rx_data_0_p
  ad_connect inst0_util_adrv9009_xcvr/rx_0_n inst0_rx_data_0_n
  ad_connect inst0_util_adrv9009_xcvr/rx_1_p inst0_rx_data_1_p
  ad_connect inst0_util_adrv9009_xcvr/rx_1_n inst0_rx_data_1_n
}

ad_connect inst0_ref_clk inst0_axi_adrv9009_rx_clkgen/clk
for {set i 0} {$i < $MAX_RX_NUM_OF_LANES} {incr i} {
  set ch [expr $i]
  ad_xcvrpll  $inst0_rx_ref_clk inst0_util_adrv9009_xcvr/cpll_ref_clk_$ch
  ad_xcvrpll  inst0_axi_adrv9009_rx_xcvr/up_pll_rst inst0_util_adrv9009_xcvr/up_cpll_rst_$ch
}

# Rx - OBS
# ad_connect inst0_adrv9009_rx_os_device_clk inst0_axi_adrv9009_rx_os_clkgen/clk_0

if {$RX_OS_NUM_OF_LANES == 2} {
  ad_xcvrcon inst0_util_adrv9009_xcvr inst0_axi_adrv9009_rx_os_xcvr \
    inst0_axi_adrv9009_rx_os_jesd {} \
    inst0_adrv9009_tx_device_clk {} $MAX_RX_OS_NUM_OF_LANES \
    {} 1 "inst0_"
} else {
  ad_xcvrcon inst0_util_adrv9009_xcvr inst0_axi_adrv9009_rx_os_xcvr \
    inst0_axi_adrv9009_rx_os_jesd {0 1 2 3} \
    inst0_adrv9009_tx_device_clk {} $MAX_RX_OS_NUM_OF_LANES \
    {2} 0 "inst0_"
  ad_connect inst0_axi_adrv9009_rx_os_xcvr/up_es_0 inst0_util_adrv9009_xcvr/up_es_2
  ad_connect inst0_axi_adrv9009_rx_os_xcvr/up_es_1 inst0_util_adrv9009_xcvr/up_es_3
  ad_connect inst0_axi_adrv9009_rx_os_xcvr/up_ch_0 inst0_util_adrv9009_xcvr/up_rx_2
  ad_connect inst0_axi_adrv9009_rx_os_xcvr/up_ch_1 inst0_util_adrv9009_xcvr/up_rx_3

  ad_connect inst0_adrv9009_tx_device_clk inst0_util_adrv9009_xcvr/rx_clk_2
  ad_connect inst0_adrv9009_tx_device_clk inst0_util_adrv9009_xcvr/rx_clk_3

  create_bd_port -dir I inst0_rx_data_2_p
  create_bd_port -dir I inst0_rx_data_2_n
  create_bd_port -dir I inst0_rx_data_3_p
  create_bd_port -dir I inst0_rx_data_3_n
  ad_connect inst0_util_adrv9009_xcvr/rx_2_p inst0_rx_data_2_p
  ad_connect inst0_util_adrv9009_xcvr/rx_2_n inst0_rx_data_2_n
  ad_connect inst0_util_adrv9009_xcvr/rx_3_p inst0_rx_data_3_p
  ad_connect inst0_util_adrv9009_xcvr/rx_3_n inst0_rx_data_3_n
}

# ad_connect inst0_ref_clk inst0_axi_adrv9009_rx_os_clkgen/clk
for {set i 0} {$i < $MAX_RX_OS_NUM_OF_LANES} {incr i} {
  # channel indexing starts from the last RX
  set ch [expr $MAX_RX_NUM_OF_LANES + $i]
  ad_xcvrpll  $inst0_rx_obs_ref_clk inst0_util_adrv9009_xcvr/cpll_ref_clk_$ch
  ad_xcvrpll  inst0_axi_adrv9009_rx_os_xcvr/up_pll_rst inst0_util_adrv9009_xcvr/up_cpll_rst_$ch
}

# connections (dac)
ad_connect  inst0_axi_adrv9009_tx_clkgen/clk_0 inst0_tx_adrv9009_tpl_core/link_clk
ad_connect  inst0_axi_adrv9009_tx_jesd/tx_data inst0_tx_adrv9009_tpl_core/link

ad_connect  inst0_axi_adrv9009_tx_clkgen/clk_0 inst0_util_adrv9009_tx_upack/clk
ad_connect  inst0_adrv9009_tx_device_clk_rstgen/peripheral_reset inst0_util_adrv9009_tx_upack/reset

if {$TX_NUM_OF_CONVERTERS <= 2} {
  ad_connect  inst0_tx_fir_interpolator/valid_out_0  inst0_util_adrv9009_tx_upack/fifo_rd_en
} else {
  ad_ip_instance util_vector_logic inst0_logic_or [list \
  C_OPERATION {or} \
  C_SIZE 1]

  ad_connect  inst0_logic_or/Op1  inst0_tx_fir_interpolator/valid_out_0
  ad_connect  inst0_logic_or/Op2  inst0_tx_fir_interpolator/valid_out_2
  ad_connect  inst0_logic_or/Res  inst0_util_adrv9009_tx_upack/fifo_rd_en
}

ad_connect inst0_tx_fir_interpolator/aclk inst0_axi_adrv9009_tx_clkgen/clk_0
for {set i 0} {$i < $TX_NUM_OF_CONVERTERS} {incr i} {
  ad_connect  inst0_tx_adrv9009_tpl_core/dac_enable_$i  inst0_tx_fir_interpolator/dac_enable_$i
  ad_connect  inst0_tx_adrv9009_tpl_core/dac_valid_$i  inst0_tx_fir_interpolator/dac_valid_$i

  ad_connect  inst0_util_adrv9009_tx_upack/fifo_rd_data_$i  inst0_tx_fir_interpolator/data_in_${i}
  ad_connect  inst0_util_adrv9009_tx_upack/enable_$i  inst0_tx_fir_interpolator/enable_out_${i}

  ad_connect  inst0_tx_fir_interpolator/data_out_${i}  inst0_tx_adrv9009_tpl_core/dac_data_$i
}

ad_connect  inst0_tx_fir_interpolator/active inst0_dac_fir_filter_active

ad_connect  inst0_axi_adrv9009_tx_clkgen/clk_0 inst0_axi_adrv9009_dacfifo/dac_clk
ad_connect  inst0_adrv9009_tx_device_clk_rstgen/peripheral_reset inst0_axi_adrv9009_dacfifo/dac_rst

# TODO: Add streaming AXI interface for DAC FIFO
ad_connect  inst0_util_adrv9009_tx_upack/s_axis_valid VCC
ad_connect  inst0_util_adrv9009_tx_upack/s_axis_ready inst0_axi_adrv9009_dacfifo/dac_valid
ad_connect  inst0_util_adrv9009_tx_upack/s_axis_data inst0_axi_adrv9009_dacfifo/dac_data

ad_connect  $sys_dma_clk inst0_axi_adrv9009_dacfifo/dma_clk
ad_connect  $sys_dma_reset inst0_axi_adrv9009_dacfifo/dma_rst
ad_connect  $sys_dma_clk inst0_axi_adrv9009_tx_dma/m_axis_aclk
ad_connect  inst0_axi_adrv9009_dacfifo/dma_valid inst0_axi_adrv9009_tx_dma/m_axis_valid
ad_connect  inst0_axi_adrv9009_dacfifo/dma_data inst0_axi_adrv9009_tx_dma/m_axis_data
ad_connect  inst0_axi_adrv9009_dacfifo/dma_ready inst0_axi_adrv9009_tx_dma/m_axis_ready
ad_connect  inst0_axi_adrv9009_dacfifo/dma_xfer_req inst0_axi_adrv9009_tx_dma/m_axis_xfer_req
ad_connect  inst0_axi_adrv9009_dacfifo/dma_xfer_last inst0_axi_adrv9009_tx_dma/m_axis_last
ad_connect  inst0_axi_adrv9009_dacfifo/dac_dunf inst0_tx_adrv9009_tpl_core/dac_dunf
ad_connect  inst0_axi_adrv9009_dacfifo/bypass inst0_dac_fifo_bypass
ad_connect  $sys_dma_resetn inst0_axi_adrv9009_tx_dma/m_src_axi_aresetn

# connections (adc)

if {$RX_OCTETS_PER_FRAME == 8} {
  ad_connect  inst0_axi_adrv9009_rx_clkgen/clk_1 inst0_rx_adrv9009_tpl_core/link_clk
  ad_connect  inst0_axi_adrv9009_rx_clkgen/clk_1 inst0_util_adrv9009_rx_cpack/clk
  ad_connect  inst0_rx_fir_decimator/aclk inst0_axi_adrv9009_rx_clkgen/clk_1
  ad_connect  inst0_axi_adrv9009_rx_clkgen/clk_1 inst0_axi_adrv9009_rx_dma/fifo_wr_clk

} else {
  ad_connect  inst0_axi_adrv9009_rx_clkgen/clk_0 inst0_rx_adrv9009_tpl_core/link_clk
  ad_connect  inst0_axi_adrv9009_rx_clkgen/clk_0 inst0_util_adrv9009_rx_cpack/clk
  ad_connect  inst0_rx_fir_decimator/aclk inst0_axi_adrv9009_rx_clkgen/clk_0
  ad_connect  inst0_axi_adrv9009_rx_clkgen/clk_0 inst0_axi_adrv9009_rx_dma/fifo_wr_clk
}

ad_connect  inst0_axi_adrv9009_rx_jesd/rx_sof inst0_rx_adrv9009_tpl_core/link_sof
ad_connect  inst0_axi_adrv9009_rx_jesd/rx_data_tdata inst0_rx_adrv9009_tpl_core/link_data
ad_connect  inst0_axi_adrv9009_rx_jesd/rx_data_tvalid inst0_rx_adrv9009_tpl_core/link_valid

ad_connect  inst0_adrv9009_rx_device_clk_rstgen/peripheral_reset inst0_util_adrv9009_rx_cpack/reset

for {set i 0} {$i < $RX_NUM_OF_CONVERTERS} {incr i} {
  ad_connect  inst0_rx_adrv9009_tpl_core/adc_valid_$i inst0_rx_fir_decimator/valid_in_$i
  ad_connect  inst0_rx_adrv9009_tpl_core/adc_enable_$i inst0_rx_fir_decimator/enable_in_$i
  ad_connect  inst0_rx_adrv9009_tpl_core/adc_data_$i inst0_rx_fir_decimator/data_in_${i}

  ad_connect  inst0_rx_fir_decimator/enable_out_$i inst0_util_adrv9009_rx_cpack/enable_$i
  ad_connect  inst0_rx_fir_decimator/data_out_${i} inst0_util_adrv9009_rx_cpack/fifo_wr_data_$i
}

ad_connect inst0_rx_fir_decimator/active inst0_adc_fir_filter_active

ad_connect  inst0_rx_fir_decimator/valid_out_0 inst0_util_adrv9009_rx_cpack/fifo_wr_en
ad_connect  inst0_rx_adrv9009_tpl_core/adc_dovf inst0_util_adrv9009_rx_cpack/fifo_wr_overflow

ad_connect  inst0_util_adrv9009_rx_cpack/packed_fifo_wr inst0_axi_adrv9009_rx_dma/fifo_wr
ad_connect  inst0_util_adrv9009_rx_cpack/packed_sync inst0_axi_adrv9009_rx_dma/sync
ad_connect  $sys_dma_resetn inst0_axi_adrv9009_rx_dma/m_dest_axi_aresetn

# connections (adc-os)
## ad_connect  inst0_axi_adrv9009_rx_os_clkgen/clk_0 inst0_rx_os_adrv9009_tpl_core/link_clk
## ad_connect  inst0_axi_adrv9009_rx_os_clkgen/clk_0 inst0_util_adrv9009_rx_os_cpack/clk
## ad_connect  inst0_axi_adrv9009_rx_os_clkgen/clk_0 inst0_axi_adrv9009_rx_os_dma/fifo_wr_clk

ad_connect  inst0_axi_adrv9009_tx_clkgen/clk_0 inst0_rx_os_adrv9009_tpl_core/link_clk
ad_connect  inst0_axi_adrv9009_tx_clkgen/clk_0 inst0_util_adrv9009_rx_os_cpack/clk
ad_connect  inst0_axi_adrv9009_tx_clkgen/clk_0 inst0_axi_adrv9009_rx_os_dma/fifo_wr_clk

ad_connect  inst0_axi_adrv9009_rx_os_jesd/rx_sof inst0_rx_os_adrv9009_tpl_core/link_sof
ad_connect  inst0_axi_adrv9009_rx_os_jesd/rx_data_tdata inst0_rx_os_adrv9009_tpl_core/link_data
ad_connect  inst0_axi_adrv9009_rx_os_jesd/rx_data_tvalid inst0_rx_os_adrv9009_tpl_core/link_valid

# ad_connect  inst0_adrv9009_rx_os_device_clk_rstgen/peripheral_reset inst0_util_adrv9009_rx_os_cpack/reset
ad_connect  inst0_adrv9009_tx_device_clk_rstgen/peripheral_reset inst0_util_adrv9009_rx_os_cpack/reset

ad_connect  inst0_rx_os_adrv9009_tpl_core/adc_valid_0 inst0_util_adrv9009_rx_os_cpack/fifo_wr_en
for {set i 0} {$i < $RX_OS_NUM_OF_CONVERTERS} {incr i} {
  ad_connect  inst0_rx_os_adrv9009_tpl_core/adc_enable_$i inst0_util_adrv9009_rx_os_cpack/enable_$i
  ad_connect  inst0_rx_os_adrv9009_tpl_core/adc_data_$i inst0_util_adrv9009_rx_os_cpack/fifo_wr_data_$i
}
ad_connect  inst0_rx_os_adrv9009_tpl_core/adc_dovf inst0_util_adrv9009_rx_os_cpack/fifo_wr_overflow
ad_connect  inst0_util_adrv9009_rx_os_cpack/packed_fifo_wr inst0_axi_adrv9009_rx_os_dma/fifo_wr
ad_connect  inst0_util_adrv9009_rx_os_cpack/packed_sync inst0_axi_adrv9009_rx_os_dma/sync

ad_connect  $sys_dma_resetn inst0_axi_adrv9009_rx_os_dma/m_dest_axi_aresetn

# interconnect (cpu)
ad_cpu_interconnect 0x43C00000 inst0_axi_adrv9009_tx_clkgen
ad_cpu_interconnect 0x43C10000 inst0_axi_adrv9009_rx_clkgen
## ad_cpu_interconnect 0x43C20000 inst0_axi_adrv9009_rx_os_clkgen
ad_cpu_interconnect 0x44A00000 inst0_rx_adrv9009_tpl_core
ad_cpu_interconnect 0x44A04000 inst0_tx_adrv9009_tpl_core
ad_cpu_interconnect 0x44A08000 inst0_rx_os_adrv9009_tpl_core
ad_cpu_interconnect 0x44A50000 inst0_axi_adrv9009_rx_os_xcvr
ad_cpu_interconnect 0x44A60000 inst0_axi_adrv9009_rx_xcvr
ad_cpu_interconnect 0x44A80000 inst0_axi_adrv9009_tx_xcvr
ad_cpu_interconnect 0x44A90000 inst0_axi_adrv9009_tx_jesd
ad_cpu_interconnect 0x44AA0000 inst0_axi_adrv9009_rx_jesd
ad_cpu_interconnect 0x44AB0000 inst0_axi_adrv9009_rx_os_jesd
ad_cpu_interconnect 0x7c400000 inst0_axi_adrv9009_rx_dma
ad_cpu_interconnect 0x7c420000 inst0_axi_adrv9009_tx_dma
ad_cpu_interconnect 0x7c440000 inst0_axi_adrv9009_rx_os_dma

#####################################INST1############################################
set inst1_dac_fifo_name inst1_axi_adrv9009_dacfifo

# adrv9009
create_bd_port -dir I inst1_ref_clk

create_bd_port -dir I inst1_dac_fifo_bypass
create_bd_port -dir I inst1_adc_fir_filter_active
create_bd_port -dir I inst1_dac_fir_filter_active

# DAC inst1
ad_ip_instance axi_clkgen inst1_axi_adrv9009_tx_clkgen
ad_ip_parameter inst1_axi_adrv9009_tx_clkgen CONFIG.ID 2
ad_ip_parameter inst1_axi_adrv9009_tx_clkgen CONFIG.CLKIN_PERIOD 4
ad_ip_parameter inst1_axi_adrv9009_tx_clkgen CONFIG.VCO_DIV 1
ad_ip_parameter inst1_axi_adrv9009_tx_clkgen CONFIG.VCO_MUL 4
ad_ip_parameter inst1_axi_adrv9009_tx_clkgen CONFIG.CLK0_DIV 4
# ad_ip_parameter inst1_axi_adrv9009_tx_clkgen CONFIG.ENABLE_CLKOUT1 {true}
# ad_ip_parameter inst1_axi_adrv9009_tx_clkgen CONFIG.CLK1_DIV 4

ad_ip_instance axi_adxcvr inst1_axi_adrv9009_tx_xcvr
ad_ip_parameter inst1_axi_adrv9009_tx_xcvr CONFIG.NUM_OF_LANES $MAX_TX_NUM_OF_LANES
ad_ip_parameter inst1_axi_adrv9009_tx_xcvr CONFIG.QPLL_ENABLE 1
ad_ip_parameter inst1_axi_adrv9009_tx_xcvr CONFIG.TX_OR_RX_N 1
ad_ip_parameter inst1_axi_adrv9009_tx_xcvr CONFIG.SYS_CLK_SEL 3
ad_ip_parameter inst1_axi_adrv9009_tx_xcvr CONFIG.OUT_CLK_SEL 3

adi_axi_jesd204_tx_create inst1_axi_adrv9009_tx_jesd $TX_NUM_OF_LANES

ad_ip_instance util_upack2 inst1_util_adrv9009_tx_upack [list \
  NUM_OF_CHANNELS $TX_NUM_OF_CONVERTERS \
  SAMPLES_PER_CHANNEL $TX_SAMPLES_PER_CHANNEL \
  SAMPLE_DATA_WIDTH $TX_SAMPLE_WIDTH \
]

ad_add_interpolation_filter "inst1_tx_fir_interpolator" 8 $TX_NUM_OF_CONVERTERS 2 {122.88} {15.36} \
                             "$ad_hdl_dir/library/util_fir_int/coefile_int.coe"


adi_tpl_jesd204_tx_create inst1_tx_adrv9009_tpl_core $TX_NUM_OF_LANES \
                                               $TX_NUM_OF_CONVERTERS \
                                               $TX_SAMPLES_PER_FRAME \
                                               $TX_SAMPLE_WIDTH

ad_ip_instance axi_dmac inst1_axi_adrv9009_tx_dma
ad_ip_parameter inst1_axi_adrv9009_tx_dma CONFIG.DMA_TYPE_SRC 0
ad_ip_parameter inst1_axi_adrv9009_tx_dma CONFIG.DMA_TYPE_DEST 1
ad_ip_parameter inst1_axi_adrv9009_tx_dma CONFIG.CYCLIC 1
ad_ip_parameter inst1_axi_adrv9009_tx_dma CONFIG.ASYNC_CLK_DEST_REQ 1
ad_ip_parameter inst1_axi_adrv9009_tx_dma CONFIG.ASYNC_CLK_SRC_DEST 1
ad_ip_parameter inst1_axi_adrv9009_tx_dma CONFIG.ASYNC_CLK_REQ_SRC 1
ad_ip_parameter inst1_axi_adrv9009_tx_dma CONFIG.DMA_2D_TRANSFER 0
ad_ip_parameter inst1_axi_adrv9009_tx_dma CONFIG.DMA_DATA_WIDTH_DEST $dac_data_width
ad_ip_parameter inst1_axi_adrv9009_tx_dma CONFIG.MAX_BYTES_PER_BURST 256
ad_ip_parameter inst1_axi_adrv9009_tx_dma CONFIG.AXI_SLICE_DEST true
ad_ip_parameter inst1_axi_adrv9009_tx_dma CONFIG.AXI_SLICE_SRC true

ad_dacfifo_create $inst1_dac_fifo_name $dac_data_width $dac_data_width $dac_fifo_address_width

# ADC inst1
ad_ip_instance axi_clkgen inst1_axi_adrv9009_rx_clkgen
ad_ip_parameter inst1_axi_adrv9009_rx_clkgen CONFIG.ID 2
ad_ip_parameter inst1_axi_adrv9009_rx_clkgen CONFIG.CLKIN_PERIOD 4
ad_ip_parameter inst1_axi_adrv9009_rx_clkgen CONFIG.VCO_DIV 1
ad_ip_parameter inst1_axi_adrv9009_rx_clkgen CONFIG.VCO_MUL 4
ad_ip_parameter inst1_axi_adrv9009_rx_clkgen CONFIG.CLK0_DIV 4
ad_ip_parameter inst1_axi_adrv9009_rx_clkgen CONFIG.ENABLE_CLKOUT1 {true}
ad_ip_parameter inst1_axi_adrv9009_rx_clkgen CONFIG.CLK1_DIV 8

ad_ip_instance axi_adxcvr inst1_axi_adrv9009_rx_xcvr
ad_ip_parameter inst1_axi_adrv9009_rx_xcvr CONFIG.NUM_OF_LANES $MAX_RX_NUM_OF_LANES
ad_ip_parameter inst1_axi_adrv9009_rx_xcvr CONFIG.QPLL_ENABLE 0
ad_ip_parameter inst1_axi_adrv9009_rx_xcvr CONFIG.TX_OR_RX_N 0
ad_ip_parameter inst1_axi_adrv9009_rx_xcvr CONFIG.SYS_CLK_SEL 0
ad_ip_parameter inst1_axi_adrv9009_rx_xcvr CONFIG.OUT_CLK_SEL 3

adi_axi_jesd204_rx_create inst1_axi_adrv9009_rx_jesd $RX_NUM_OF_LANES
ad_ip_parameter inst1_axi_adrv9009_rx_jesd/rx CONFIG.SYSREF_IOB false
ad_ip_parameter inst1_axi_adrv9009_rx_jesd/rx CONFIG.TPL_DATA_PATH_WIDTH $DPW

ad_ip_instance util_cpack2 inst1_util_adrv9009_rx_cpack [list \
  NUM_OF_CHANNELS $RX_NUM_OF_CONVERTERS \
  SAMPLES_PER_CHANNEL $RX_SAMPLES_PER_CHANNEL \
  SAMPLE_DATA_WIDTH $RX_SAMPLE_WIDTH \
  ]

adi_tpl_jesd204_rx_create inst1_rx_adrv9009_tpl_core $RX_NUM_OF_LANES \
                                               $RX_NUM_OF_CONVERTERS \
                                               $RX_SAMPLES_PER_FRAME \
                                               $RX_SAMPLE_WIDTH

ad_add_decimation_filter "inst1_rx_fir_decimator" 8 $RX_NUM_OF_CONVERTERS 1 {122.88} {122.88} \
                          "$ad_hdl_dir/library/util_fir_int/coefile_int.coe"

ad_ip_instance axi_dmac inst1_axi_adrv9009_rx_dma
ad_ip_parameter inst1_axi_adrv9009_rx_dma CONFIG.DMA_TYPE_SRC 2
ad_ip_parameter inst1_axi_adrv9009_rx_dma CONFIG.DMA_TYPE_DEST 0
ad_ip_parameter inst1_axi_adrv9009_rx_dma CONFIG.CYCLIC 0
ad_ip_parameter inst1_axi_adrv9009_rx_dma CONFIG.SYNC_TRANSFER_START 1
ad_ip_parameter inst1_axi_adrv9009_rx_dma CONFIG.ASYNC_CLK_DEST_REQ 1
ad_ip_parameter inst1_axi_adrv9009_rx_dma CONFIG.ASYNC_CLK_SRC_DEST 1
ad_ip_parameter inst1_axi_adrv9009_rx_dma CONFIG.ASYNC_CLK_REQ_SRC 1
ad_ip_parameter inst1_axi_adrv9009_rx_dma CONFIG.DMA_2D_TRANSFER 0
ad_ip_parameter inst1_axi_adrv9009_rx_dma CONFIG.DMA_DATA_WIDTH_SRC $adc_dma_data_width
ad_ip_parameter inst1_axi_adrv9009_rx_dma CONFIG.MAX_BYTES_PER_BURST 256
ad_ip_parameter inst1_axi_adrv9009_rx_dma CONFIG.AXI_SLICE_DEST true
ad_ip_parameter inst1_axi_adrv9009_rx_dma CONFIG.AXI_SLICE_SRC true

# ADC-OS inst1
## ad_ip_instance axi_clkgen inst1_axi_adrv9009_rx_os_clkgen
## ad_ip_parameter inst1_axi_adrv9009_rx_os_clkgen CONFIG.ID 2
## ad_ip_parameter inst1_axi_adrv9009_rx_os_clkgen CONFIG.CLKIN_PERIOD 4
## ad_ip_parameter inst1_axi_adrv9009_rx_os_clkgen CONFIG.VCO_DIV 1
## ad_ip_parameter inst1_axi_adrv9009_rx_os_clkgen CONFIG.VCO_MUL 4
## ad_ip_parameter inst1_axi_adrv9009_rx_os_clkgen CONFIG.CLK0_DIV 4

ad_ip_instance axi_adxcvr inst1_axi_adrv9009_rx_os_xcvr
ad_ip_parameter inst1_axi_adrv9009_rx_os_xcvr CONFIG.NUM_OF_LANES $MAX_RX_OS_NUM_OF_LANES
ad_ip_parameter inst1_axi_adrv9009_rx_os_xcvr CONFIG.QPLL_ENABLE 0
ad_ip_parameter inst1_axi_adrv9009_rx_os_xcvr CONFIG.TX_OR_RX_N 0
ad_ip_parameter inst1_axi_adrv9009_rx_os_xcvr CONFIG.SYS_CLK_SEL 0
ad_ip_parameter inst1_axi_adrv9009_rx_os_xcvr CONFIG.OUT_CLK_SEL 3

adi_axi_jesd204_rx_create inst1_axi_adrv9009_rx_os_jesd $RX_OS_NUM_OF_LANES

ad_ip_instance util_cpack2 inst1_util_adrv9009_rx_os_cpack [list \
  NUM_OF_CHANNELS $RX_OS_NUM_OF_CONVERTERS \
  SAMPLES_PER_CHANNEL $RX_OS_SAMPLES_PER_CHANNEL\
  SAMPLE_DATA_WIDTH $RX_OS_SAMPLE_WIDTH \
]

adi_tpl_jesd204_rx_create inst1_rx_os_adrv9009_tpl_core $RX_OS_NUM_OF_LANES \
                                                  $RX_OS_NUM_OF_CONVERTERS \
                                                  $RX_OS_SAMPLES_PER_FRAME \
                                                  $RX_OS_SAMPLE_WIDTH

ad_ip_instance axi_dmac inst1_axi_adrv9009_rx_os_dma
ad_ip_parameter inst1_axi_adrv9009_rx_os_dma CONFIG.DMA_TYPE_SRC 2
ad_ip_parameter inst1_axi_adrv9009_rx_os_dma CONFIG.DMA_TYPE_DEST 0
ad_ip_parameter inst1_axi_adrv9009_rx_os_dma CONFIG.CYCLIC 0
ad_ip_parameter inst1_axi_adrv9009_rx_os_dma CONFIG.SYNC_TRANSFER_START 1
ad_ip_parameter inst1_axi_adrv9009_rx_os_dma CONFIG.ASYNC_CLK_DEST_REQ 1
ad_ip_parameter inst1_axi_adrv9009_rx_os_dma CONFIG.ASYNC_CLK_SRC_DEST 1
ad_ip_parameter inst1_axi_adrv9009_rx_os_dma CONFIG.ASYNC_CLK_REQ_SRC 1
ad_ip_parameter inst1_axi_adrv9009_rx_os_dma CONFIG.DMA_2D_TRANSFER 0
ad_ip_parameter inst1_axi_adrv9009_rx_os_dma CONFIG.DMA_DATA_WIDTH_SRC [expr $RX_OS_SAMPLE_WIDTH * \
                                                                       $RX_OS_NUM_OF_CONVERTERS * \
                                                                       $RX_OS_SAMPLES_PER_CHANNEL];
ad_ip_parameter inst1_axi_adrv9009_rx_os_dma CONFIG.MAX_BYTES_PER_BURST 256
ad_ip_parameter inst1_axi_adrv9009_rx_os_dma CONFIG.AXI_SLICE_DEST true
ad_ip_parameter inst1_axi_adrv9009_rx_os_dma CONFIG.AXI_SLICE_SRC true

ad_ip_instance util_adxcvr inst1_util_adrv9009_xcvr
ad_ip_parameter inst1_util_adrv9009_xcvr CONFIG.RX_NUM_OF_LANES [expr $MAX_RX_NUM_OF_LANES+$MAX_RX_OS_NUM_OF_LANES]
ad_ip_parameter inst1_util_adrv9009_xcvr CONFIG.TX_NUM_OF_LANES $MAX_TX_NUM_OF_LANES
ad_ip_parameter inst1_util_adrv9009_xcvr CONFIG.TX_OUT_DIV 1
ad_ip_parameter inst1_util_adrv9009_xcvr CONFIG.CPLL_FBDIV 4
ad_ip_parameter inst1_util_adrv9009_xcvr CONFIG.CPLL_FBDIV_4_5 5
ad_ip_parameter inst1_util_adrv9009_xcvr CONFIG.RX_CLK25_DIV 10
ad_ip_parameter inst1_util_adrv9009_xcvr CONFIG.TX_CLK25_DIV 10
ad_ip_parameter inst1_util_adrv9009_xcvr CONFIG.RX_PMA_CFG 0x001E7080
ad_ip_parameter inst1_util_adrv9009_xcvr CONFIG.RX_CDR_CFG 0x0b000023ff10400020
ad_ip_parameter inst1_util_adrv9009_xcvr CONFIG.QPLL_FBDIV 0x080

# xcvr inst1
set inst1_tx_ref_clk     inst1_tx_ref_clk_0
set inst1_rx_ref_clk     inst1_rx_ref_clk_0
set inst1_rx_obs_ref_clk inst1_rx_ref_clk_$MAX_RX_NUM_OF_LANES

create_bd_port -dir I $inst1_tx_ref_clk
create_bd_port -dir I $inst1_rx_ref_clk
create_bd_port -dir I $inst1_rx_obs_ref_clk
ad_connect  $sys_cpu_resetn inst1_util_adrv9009_xcvr/up_rstn
ad_connect  $sys_cpu_clk inst1_util_adrv9009_xcvr/up_clk

# Tx inst1
ad_connect inst1_adrv9009_tx_device_clk inst1_axi_adrv9009_tx_clkgen/clk_0

if {$TX_NUM_OF_LANES == 4} {
  ad_xcvrcon inst1_util_adrv9009_xcvr inst1_axi_adrv9009_tx_xcvr \
    inst1_axi_adrv9009_tx_jesd {0 3 2 1} \
    inst1_adrv9009_tx_device_clk {} $MAX_TX_NUM_OF_LANES \
    {} 1 "inst1_"
} else {
    if {$TX_NUM_OF_LANES == 2} {
      ad_xcvrcon inst1_util_adrv9009_xcvr inst1_axi_adrv9009_tx_xcvr \
        inst1_axi_adrv9009_tx_jesd {0 3 2 1} \
        inst1_adrv9009_tx_device_clk {} $MAX_TX_NUM_OF_LANES \
        {0 2} 1 "inst1_"
    } else {
      ad_xcvrcon inst1_util_adrv9009_xcvr inst1_axi_adrv9009_tx_xcvr \
        inst1_axi_adrv9009_tx_jesd {0 3 2 1} \
        inst1_adrv9009_tx_device_clk {} $MAX_TX_NUM_OF_LANES \
        {0} 1 "inst1_"
    }
}

ad_connect inst1_ref_clk inst1_axi_adrv9009_tx_clkgen/clk
ad_xcvrpll $inst1_tx_ref_clk inst1_util_adrv9009_xcvr/qpll_ref_clk_0
ad_xcvrpll inst1_axi_adrv9009_tx_xcvr/up_pll_rst inst1_util_adrv9009_xcvr/up_qpll_rst_0

# Rx Inst1
if {$RX_NUM_OF_LANES == 2} {
  ad_connect inst1_adrv9009_rx_device_clk inst1_axi_adrv9009_rx_clkgen/clk_0
  ad_xcvrcon inst1_util_adrv9009_xcvr inst1_axi_adrv9009_rx_xcvr \
    inst1_axi_adrv9009_rx_jesd {} \
    inst1_adrv9009_rx_device_clk {} $MAX_RX_NUM_OF_LANES \
    {} 1 "inst1_"
} else {
  # for RX_NUM_OF_LANES = 1, RX_OCTETS_PER_FRAME = 8
  ad_connect inst1_adrv9009_rx_device_clk inst1_axi_adrv9009_rx_clkgen/clk_1
  ad_connect inst1_adrv9009_rx_link_clk inst1_axi_adrv9009_rx_clkgen/clk_0

  ad_xcvrcon inst1_util_adrv9009_xcvr inst1_axi_adrv9009_rx_xcvr \
    inst1_axi_adrv9009_rx_jesd {0 1 2 3} \
    inst1_adrv9009_rx_link_clk inst1_adrv9009_rx_device_clk $MAX_RX_NUM_OF_LANES \
    {0} 0 "inst1_"
  ad_connect inst1_axi_adrv9009_rx_xcvr/up_es_0 inst1_util_adrv9009_xcvr/up_es_0
  ad_connect inst1_axi_adrv9009_rx_xcvr/up_es_1 inst1_util_adrv9009_xcvr/up_es_1
  ad_connect inst1_axi_adrv9009_rx_xcvr/up_ch_0 inst1_util_adrv9009_xcvr/up_rx_0
  ad_connect inst1_axi_adrv9009_rx_xcvr/up_ch_1 inst1_util_adrv9009_xcvr/up_rx_1

  ad_connect inst1_adrv9009_rx_link_clk inst1_util_adrv9009_xcvr/rx_clk_0
  ad_connect inst1_adrv9009_rx_link_clk inst1_util_adrv9009_xcvr/rx_clk_1

  create_bd_port -dir I inst1_rx_data_0_p
  create_bd_port -dir I inst1_rx_data_0_n
  create_bd_port -dir I inst1_rx_data_1_p
  create_bd_port -dir I inst1_rx_data_1_n
  ad_connect inst1_util_adrv9009_xcvr/rx_0_p inst1_rx_data_0_p
  ad_connect inst1_util_adrv9009_xcvr/rx_0_n inst1_rx_data_0_n
  ad_connect inst1_util_adrv9009_xcvr/rx_1_p inst1_rx_data_1_p
  ad_connect inst1_util_adrv9009_xcvr/rx_1_n inst1_rx_data_1_n
}

ad_connect inst1_ref_clk inst1_axi_adrv9009_rx_clkgen/clk
for {set i 0} {$i < $MAX_RX_NUM_OF_LANES} {incr i} {
  set ch [expr $i]
  ad_xcvrpll  $inst1_rx_ref_clk inst1_util_adrv9009_xcvr/cpll_ref_clk_$ch
  ad_xcvrpll  inst1_axi_adrv9009_rx_xcvr/up_pll_rst inst1_util_adrv9009_xcvr/up_cpll_rst_$ch
}

# Rx - OBS inst1
# ad_connect inst1_adrv9009_rx_os_device_clk inst1_axi_adrv9009_tx_clkgen/clk_0

if {$RX_OS_NUM_OF_LANES == 2} {
  ad_xcvrcon inst1_util_adrv9009_xcvr inst1_axi_adrv9009_rx_os_xcvr \
    inst1_axi_adrv9009_rx_os_jesd {} \
    inst1_adrv9009_tx_device_clk {} $MAX_RX_OS_NUM_OF_LANES \
    {} 1 "inst1_"
} else {
  ad_xcvrcon inst1_util_adrv9009_xcvr inst1_axi_adrv9009_rx_os_xcvr \
    inst1_axi_adrv9009_rx_os_jesd {0 1 2 3} \
    inst1_adrv9009_tx_device_clk {} $MAX_RX_OS_NUM_OF_LANES \
    {2} 0 "inst1_"

  ad_connect inst1_axi_adrv9009_rx_os_xcvr/up_es_0 inst1_util_adrv9009_xcvr/up_es_2
  ad_connect inst1_axi_adrv9009_rx_os_xcvr/up_es_1 inst1_util_adrv9009_xcvr/up_es_3
  ad_connect inst1_axi_adrv9009_rx_os_xcvr/up_ch_0 inst1_util_adrv9009_xcvr/up_rx_2
  ad_connect inst1_axi_adrv9009_rx_os_xcvr/up_ch_1 inst1_util_adrv9009_xcvr/up_rx_3

  ad_connect inst1_adrv9009_tx_device_clk inst1_util_adrv9009_xcvr/rx_clk_2
  ad_connect inst1_adrv9009_tx_device_clk inst1_util_adrv9009_xcvr/rx_clk_3

  create_bd_port -dir I inst1_rx_data_2_p
  create_bd_port -dir I inst1_rx_data_2_n
  create_bd_port -dir I inst1_rx_data_3_p
  create_bd_port -dir I inst1_rx_data_3_n
  ad_connect inst1_util_adrv9009_xcvr/rx_2_p inst1_rx_data_2_p
  ad_connect inst1_util_adrv9009_xcvr/rx_2_n inst1_rx_data_2_n
  ad_connect inst1_util_adrv9009_xcvr/rx_3_p inst1_rx_data_3_p
  ad_connect inst1_util_adrv9009_xcvr/rx_3_n inst1_rx_data_3_n
}

# ad_connect inst1_ref_clk inst1_axi_adrv9009_rx_os_clkgen/clk
for {set i 0} {$i < $MAX_RX_OS_NUM_OF_LANES} {incr i} {
  # channel indexing starts from the last RX
  set ch [expr $MAX_RX_NUM_OF_LANES + $i]
  ad_xcvrpll  $inst1_rx_obs_ref_clk inst1_util_adrv9009_xcvr/cpll_ref_clk_$ch
  ad_xcvrpll  inst1_axi_adrv9009_rx_os_xcvr/up_pll_rst inst1_util_adrv9009_xcvr/up_cpll_rst_$ch
}

# connections (dac)
ad_connect  inst1_axi_adrv9009_tx_clkgen/clk_0 inst1_tx_adrv9009_tpl_core/link_clk
ad_connect  inst1_axi_adrv9009_tx_jesd/tx_data inst1_tx_adrv9009_tpl_core/link

ad_connect  inst1_axi_adrv9009_tx_clkgen/clk_0 inst1_util_adrv9009_tx_upack/clk
ad_connect  inst1_adrv9009_tx_device_clk_rstgen/peripheral_reset inst1_util_adrv9009_tx_upack/reset

if {$TX_NUM_OF_CONVERTERS <= 2} {
  ad_connect  inst1_tx_fir_interpolator/valid_out_0  inst1_util_adrv9009_tx_upack/fifo_rd_en
} else {
  ad_ip_instance util_vector_logic inst1_logic_or [list \
  C_OPERATION {or} \
  C_SIZE 1]

  ad_connect  inst1_logic_or/Op1  inst1_tx_fir_interpolator/valid_out_0
  ad_connect  inst1_logic_or/Op2  inst1_tx_fir_interpolator/valid_out_2
  ad_connect  inst1_logic_or/Res  inst1_util_adrv9009_tx_upack/fifo_rd_en
}

ad_connect inst1_tx_fir_interpolator/aclk inst1_axi_adrv9009_tx_clkgen/clk_0
for {set i 0} {$i < $TX_NUM_OF_CONVERTERS} {incr i} {
  ad_connect  inst1_tx_adrv9009_tpl_core/dac_enable_$i  inst1_tx_fir_interpolator/dac_enable_$i
  ad_connect  inst1_tx_adrv9009_tpl_core/dac_valid_$i  inst1_tx_fir_interpolator/dac_valid_$i

  ad_connect  inst1_util_adrv9009_tx_upack/fifo_rd_data_$i  inst1_tx_fir_interpolator/data_in_${i}
  ad_connect  inst1_util_adrv9009_tx_upack/enable_$i  inst1_tx_fir_interpolator/enable_out_${i}

  ad_connect  inst1_tx_fir_interpolator/data_out_${i}  inst1_tx_adrv9009_tpl_core/dac_data_$i
}

ad_connect  inst1_tx_fir_interpolator/active inst1_dac_fir_filter_active

ad_connect  inst1_axi_adrv9009_tx_clkgen/clk_0 inst1_axi_adrv9009_dacfifo/dac_clk
ad_connect  inst1_adrv9009_tx_device_clk_rstgen/peripheral_reset inst1_axi_adrv9009_dacfifo/dac_rst

# TODO: Add streaming AXI interface for DAC FIFO
ad_connect  inst1_util_adrv9009_tx_upack/s_axis_valid VCC
ad_connect  inst1_util_adrv9009_tx_upack/s_axis_ready inst1_axi_adrv9009_dacfifo/dac_valid
ad_connect  inst1_util_adrv9009_tx_upack/s_axis_data inst1_axi_adrv9009_dacfifo/dac_data

ad_connect  $sys_dma_clk inst1_axi_adrv9009_dacfifo/dma_clk
ad_connect  $sys_dma_reset inst1_axi_adrv9009_dacfifo/dma_rst
ad_connect  $sys_dma_clk inst1_axi_adrv9009_tx_dma/m_axis_aclk
ad_connect  inst1_axi_adrv9009_dacfifo/dma_valid inst1_axi_adrv9009_tx_dma/m_axis_valid
ad_connect  inst1_axi_adrv9009_dacfifo/dma_data inst1_axi_adrv9009_tx_dma/m_axis_data
ad_connect  inst1_axi_adrv9009_dacfifo/dma_ready inst1_axi_adrv9009_tx_dma/m_axis_ready
ad_connect  inst1_axi_adrv9009_dacfifo/dma_xfer_req inst1_axi_adrv9009_tx_dma/m_axis_xfer_req
ad_connect  inst1_axi_adrv9009_dacfifo/dma_xfer_last inst1_axi_adrv9009_tx_dma/m_axis_last
ad_connect  inst1_axi_adrv9009_dacfifo/dac_dunf inst1_tx_adrv9009_tpl_core/dac_dunf
ad_connect  inst1_axi_adrv9009_dacfifo/bypass inst1_dac_fifo_bypass
ad_connect  $sys_dma_resetn inst1_axi_adrv9009_tx_dma/m_src_axi_aresetn

# connections (adc)

if {$RX_OCTETS_PER_FRAME == 8} {
  ad_connect  inst1_axi_adrv9009_rx_clkgen/clk_1 inst1_rx_adrv9009_tpl_core/link_clk
  ad_connect  inst1_axi_adrv9009_rx_clkgen/clk_1 inst1_util_adrv9009_rx_cpack/clk
  ad_connect  inst1_rx_fir_decimator/aclk inst1_axi_adrv9009_rx_clkgen/clk_1
  ad_connect  inst1_axi_adrv9009_rx_clkgen/clk_1 inst1_axi_adrv9009_rx_dma/fifo_wr_clk
} else {
  ad_connect  inst1_axi_adrv9009_rx_clkgen/clk_0 inst1_rx_adrv9009_tpl_core/link_clk
  ad_connect  inst1_axi_adrv9009_rx_clkgen/clk_0 inst1_util_adrv9009_rx_cpack/clk
  ad_connect  inst1_rx_fir_decimator/aclk inst1_axi_adrv9009_rx_clkgen/clk_0
  ad_connect  inst1_axi_adrv9009_rx_clkgen/clk_0 inst1_axi_adrv9009_rx_dma/fifo_wr_clk
}

ad_connect  inst1_axi_adrv9009_rx_jesd/rx_sof inst1_rx_adrv9009_tpl_core/link_sof
ad_connect  inst1_axi_adrv9009_rx_jesd/rx_data_tdata inst1_rx_adrv9009_tpl_core/link_data
ad_connect  inst1_axi_adrv9009_rx_jesd/rx_data_tvalid inst1_rx_adrv9009_tpl_core/link_valid

ad_connect  inst1_adrv9009_rx_device_clk_rstgen/peripheral_reset inst1_util_adrv9009_rx_cpack/reset

for {set i 0} {$i < $RX_NUM_OF_CONVERTERS} {incr i} {
  ad_connect  inst1_rx_adrv9009_tpl_core/adc_valid_$i inst1_rx_fir_decimator/valid_in_$i
  ad_connect  inst1_rx_adrv9009_tpl_core/adc_enable_$i inst1_rx_fir_decimator/enable_in_$i
  ad_connect  inst1_rx_adrv9009_tpl_core/adc_data_$i inst1_rx_fir_decimator/data_in_${i}

  ad_connect  inst1_rx_fir_decimator/enable_out_$i inst1_util_adrv9009_rx_cpack/enable_$i
  ad_connect  inst1_rx_fir_decimator/data_out_${i} inst1_util_adrv9009_rx_cpack/fifo_wr_data_$i
}

ad_connect inst1_rx_fir_decimator/active inst1_adc_fir_filter_active

ad_connect  inst1_rx_fir_decimator/valid_out_0 inst1_util_adrv9009_rx_cpack/fifo_wr_en
ad_connect  inst1_rx_adrv9009_tpl_core/adc_dovf inst1_util_adrv9009_rx_cpack/fifo_wr_overflow

ad_connect  inst1_util_adrv9009_rx_cpack/packed_fifo_wr inst1_axi_adrv9009_rx_dma/fifo_wr
ad_connect  inst1_util_adrv9009_rx_cpack/packed_sync inst1_axi_adrv9009_rx_dma/sync
ad_connect  $sys_dma_resetn inst1_axi_adrv9009_rx_dma/m_dest_axi_aresetn

# connections (adc-os)
ad_connect  inst1_axi_adrv9009_tx_clkgen/clk_0 inst1_rx_os_adrv9009_tpl_core/link_clk
ad_connect  inst1_axi_adrv9009_tx_clkgen/clk_0 inst1_util_adrv9009_rx_os_cpack/clk
ad_connect  inst1_axi_adrv9009_tx_clkgen/clk_0 inst1_axi_adrv9009_rx_os_dma/fifo_wr_clk

ad_connect  inst1_axi_adrv9009_rx_os_jesd/rx_sof inst1_rx_os_adrv9009_tpl_core/link_sof
ad_connect  inst1_axi_adrv9009_rx_os_jesd/rx_data_tdata inst1_rx_os_adrv9009_tpl_core/link_data
ad_connect  inst1_axi_adrv9009_rx_os_jesd/rx_data_tvalid inst1_rx_os_adrv9009_tpl_core/link_valid

ad_connect  inst1_adrv9009_tx_device_clk_rstgen/peripheral_reset inst1_util_adrv9009_rx_os_cpack/reset
# ad_connect  inst1_adrv9009_rx_os_device_clk_rstgen/peripheral_reset inst1_util_adrv9009_rx_os_cpack/reset

ad_connect  inst1_rx_os_adrv9009_tpl_core/adc_valid_0 inst1_util_adrv9009_rx_os_cpack/fifo_wr_en
for {set i 0} {$i < $RX_OS_NUM_OF_CONVERTERS} {incr i} {
  ad_connect  inst1_rx_os_adrv9009_tpl_core/adc_enable_$i inst1_util_adrv9009_rx_os_cpack/enable_$i
  ad_connect  inst1_rx_os_adrv9009_tpl_core/adc_data_$i inst1_util_adrv9009_rx_os_cpack/fifo_wr_data_$i
}
ad_connect  inst1_rx_os_adrv9009_tpl_core/adc_dovf inst1_util_adrv9009_rx_os_cpack/fifo_wr_overflow
ad_connect  inst1_util_adrv9009_rx_os_cpack/packed_fifo_wr inst1_axi_adrv9009_rx_os_dma/fifo_wr
ad_connect  inst1_util_adrv9009_rx_os_cpack/packed_sync inst1_axi_adrv9009_rx_os_dma/sync

ad_connect  $sys_dma_resetn inst1_axi_adrv9009_rx_os_dma/m_dest_axi_aresetn

# interconnect (cpu) inst1
ad_cpu_interconnect 0x43D00000 inst1_axi_adrv9009_tx_clkgen
ad_cpu_interconnect 0x43D10000 inst1_axi_adrv9009_rx_clkgen
# ad_cpu_interconnect 0x43D20000 inst1_axi_adrv9009_rx_os_clkgen
ad_cpu_interconnect 0x44B00000 inst1_rx_adrv9009_tpl_core
ad_cpu_interconnect 0x44B04000 inst1_tx_adrv9009_tpl_core
ad_cpu_interconnect 0x44B08000 inst1_rx_os_adrv9009_tpl_core
ad_cpu_interconnect 0x44B50000 inst1_axi_adrv9009_rx_os_xcvr
ad_cpu_interconnect 0x44B60000 inst1_axi_adrv9009_rx_xcvr
ad_cpu_interconnect 0x44B80000 inst1_axi_adrv9009_tx_xcvr
ad_cpu_interconnect 0x44B90000 inst1_axi_adrv9009_tx_jesd
ad_cpu_interconnect 0x44BA0000 inst1_axi_adrv9009_rx_jesd
ad_cpu_interconnect 0x44BB0000 inst1_axi_adrv9009_rx_os_jesd
ad_cpu_interconnect 0x7c500000 inst1_axi_adrv9009_rx_dma
ad_cpu_interconnect 0x7c520000 inst1_axi_adrv9009_tx_dma
ad_cpu_interconnect 0x7c540000 inst1_axi_adrv9009_rx_os_dma

# gt uses hp0, and 100MHz clock for both DRP and AXI4
ad_mem_hp0_interconnect $sys_cpu_clk inst0_axi_adrv9009_rx_xcvr/m_axi
ad_mem_hp0_interconnect $sys_cpu_clk inst0_axi_adrv9009_rx_os_xcvr/m_axi

ad_mem_hp0_interconnect $sys_cpu_clk inst1_axi_adrv9009_rx_xcvr/m_axi
ad_mem_hp0_interconnect $sys_cpu_clk inst1_axi_adrv9009_rx_os_xcvr/m_axi

# interconnect (mem/dac)
ad_mem_hp1_interconnect $sys_dma_clk sys_ps7/S_AXI_HP1
ad_mem_hp1_interconnect $sys_dma_clk inst0_axi_adrv9009_rx_os_dma/m_dest_axi
ad_mem_hp1_interconnect $sys_dma_clk inst1_axi_adrv9009_rx_os_dma/m_dest_axi

ad_mem_hp2_interconnect $sys_dma_clk sys_ps7/S_AXI_HP2
ad_mem_hp2_interconnect $sys_dma_clk inst0_axi_adrv9009_rx_dma/m_dest_axi
ad_mem_hp2_interconnect $sys_dma_clk inst1_axi_adrv9009_rx_dma/m_dest_axi

ad_mem_hp3_interconnect $sys_dma_clk sys_ps7/S_AXI_HP3
ad_mem_hp3_interconnect $sys_dma_clk inst0_axi_adrv9009_tx_dma/m_src_axi
ad_mem_hp3_interconnect $sys_dma_clk inst1_axi_adrv9009_tx_dma/m_src_axi


# interrupts

# For PS - 8 ~ 15 -> 135 ~ 143 , device tree -32: 103 ~ 111
ad_cpu_interrupt ps-8 mb-8 inst0_axi_adrv9009_rx_os_jesd/irq
ad_cpu_interrupt ps-9 mb-7 inst0_axi_adrv9009_tx_jesd/irq
ad_cpu_interrupt ps-10 mb-15 inst0_axi_adrv9009_rx_jesd/irq
ad_cpu_interrupt ps-11 mb-14 inst0_axi_adrv9009_rx_os_dma/irq
ad_cpu_interrupt ps-12 mb-13 inst0_axi_adrv9009_tx_dma/irq
ad_cpu_interrupt ps-13 mb-12 inst0_axi_adrv9009_rx_dma/irq

# For PS - 0 ~ 7 -> 121 ~ 128 , device tree -32: 89 ~ 96 
ad_cpu_interrupt ps-1 mb-1 inst1_axi_adrv9009_rx_os_jesd/irq
ad_cpu_interrupt ps-2 mb-0 inst1_axi_adrv9009_tx_jesd/irq
ad_cpu_interrupt ps-3 mb-6 inst1_axi_adrv9009_rx_jesd/irq
ad_cpu_interrupt ps-4 mb-5 inst1_axi_adrv9009_rx_os_dma/irq
ad_cpu_interrupt ps-5 mb-4 inst1_axi_adrv9009_tx_dma/irq
ad_cpu_interrupt ps-6 mb-3 inst1_axi_adrv9009_rx_dma/irq

