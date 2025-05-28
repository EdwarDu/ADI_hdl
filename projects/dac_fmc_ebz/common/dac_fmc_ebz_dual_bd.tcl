###############################################################################
## Copyright (C) 2019-2023 Analog Devices, Inc. All rights reserved.
### SPDX short identifier: ADIBSD
###############################################################################

source $ad_hdl_dir/library/jesd204/scripts/jesd204.tcl

set JESD_M    $ad_project_params(JESD_M)
set JESD_L    $ad_project_params(JESD_L)
set NUM_LINKS $ad_project_params(NUM_LINKS)

set NUM_OF_CONVERTERS [expr $NUM_LINKS * $JESD_M]
set NUM_OF_LANES [expr $NUM_LINKS * $JESD_L]
set SAMPLES_PER_FRAME $ad_project_params(JESD_S)
set SAMPLE_WIDTH $ad_project_params(JESD_NP)

set DAC_DATA_WIDTH [expr $NUM_OF_LANES * 32]
set SAMPLES_PER_CHANNEL [expr $DAC_DATA_WIDTH / $NUM_OF_CONVERTERS / $SAMPLE_WIDTH]

set MAX_NUM_OF_LANES 8
# Top level ports

create_bd_port -dir I inst0_dac_fifo_bypass

# dac peripherals

# JESD204 PHY layer peripheral
ad_ip_instance axi_adxcvr inst0_dac_jesd204_xcvr [list \
  NUM_OF_LANES $NUM_OF_LANES \
  QPLL_ENABLE 1 \
  TX_OR_RX_N 1 \
]

# JESD204 link layer peripheral
adi_axi_jesd204_tx_create inst0_dac_jesd204_link $NUM_OF_LANES $NUM_LINKS

# JESD204 transport layer peripheral
adi_tpl_jesd204_tx_create inst0_dac_jesd204_transport $NUM_OF_LANES \
                                                $NUM_OF_CONVERTERS \
                                                $SAMPLES_PER_FRAME \
                                                $SAMPLE_WIDTH

ad_ip_instance util_upack2 inst0_dac_upack [list \
  NUM_OF_CHANNELS $NUM_OF_CONVERTERS \
  SAMPLES_PER_CHANNEL $SAMPLES_PER_CHANNEL \
  SAMPLE_DATA_WIDTH $SAMPLE_WIDTH \
]

set dac_dma_data_width $DAC_DATA_WIDTH
ad_ip_instance axi_dmac inst0_dac_dma [list \
  DMA_TYPE_SRC 0 \
  DMA_TYPE_DEST 1 \
  DMA_DATA_WIDTH_SRC 64 \
  DMA_DATA_WIDTH_DEST $dac_dma_data_width \
]

ad_dacfifo_create inst0_axi_dac_fifo \
                  $DAC_DATA_WIDTH \
                  $dac_dma_data_width \
                  $dac_fifo_address_width

# shared transceiver core

ad_ip_instance util_adxcvr inst0_util_dac_jesd204_xcvr [list \
  RX_NUM_OF_LANES 0 \
  TX_NUM_OF_LANES $MAX_NUM_OF_LANES \
  TX_LANE_INVERT [expr 0x0F] \
  QPLL_REFCLK_DIV 1 \
  QPLL_FBDIV_RATIO 1 \
  QPLL_FBDIV 0x80 \
  TX_OUT_DIV 1 \
]

ad_connect sys_cpu_resetn inst0_util_dac_jesd204_xcvr/up_rstn
ad_connect sys_cpu_clk inst0_util_dac_jesd204_xcvr/up_clk

# reference clocks & resets

for {set i 0} {$i < $MAX_NUM_OF_LANES} {incr i} {
  if {$i % 4 == 0} {
    create_bd_port -dir I inst0_tx_ref_clk_${i}
    ad_xcvrpll inst0_tx_ref_clk_${i} inst0_util_dac_jesd204_xcvr/qpll_ref_clk_${i}
    set inst0_quad_ref_clk inst0_tx_ref_clk_${i}
  }
  ad_xcvrpll $inst0_quad_ref_clk inst0_util_dac_jesd204_xcvr/cpll_ref_clk_${i}
}

ad_xcvrpll inst0_dac_jesd204_xcvr/up_pll_rst inst0_util_dac_jesd204_xcvr/up_qpll_rst_*
ad_xcvrpll inst0_dac_jesd204_xcvr/up_pll_rst inst0_util_dac_jesd204_xcvr/up_cpll_rst_*

# connections (dac)

ad_xcvrcon inst0_util_dac_jesd204_xcvr inst0_dac_jesd204_xcvr inst0_dac_jesd204_link {} {} {} $MAX_NUM_OF_LANES


ad_connect inst0_util_dac_jesd204_xcvr/tx_out_clk_0 inst0_dac_jesd204_transport/link_clk
ad_connect inst0_util_dac_jesd204_xcvr/tx_out_clk_0 inst0_dac_upack/clk
ad_connect inst0_dac_jesd204_link_rstgen/peripheral_reset inst0_dac_upack/reset

ad_connect inst0_dac_jesd204_link/tx_data inst0_dac_jesd204_transport/link

ad_connect inst0_dac_jesd204_transport/dac_valid_0 inst0_dac_upack/fifo_rd_en
for {set i 0} {$i < $NUM_OF_CONVERTERS} {incr i} {
  ad_connect inst0_dac_upack/fifo_rd_data_$i inst0_dac_jesd204_transport/dac_data_$i
  ad_connect inst0_dac_jesd204_transport/dac_enable_$i  inst0_dac_upack/enable_$i
}

ad_connect   inst0_util_dac_jesd204_xcvr/tx_out_clk_0         inst0_axi_dac_fifo/dac_clk
ad_connect   inst0_dac_jesd204_link_rstgen/peripheral_reset   inst0_axi_dac_fifo/dac_rst
ad_connect   inst0_dac_upack/s_axis_valid                     VCC
ad_connect   inst0_dac_upack/s_axis_ready                     inst0_axi_dac_fifo/dac_valid
ad_connect   inst0_dac_upack/s_axis_data                      inst0_axi_dac_fifo/dac_data
ad_connect   inst0_dac_jesd204_transport/dac_dunf             inst0_axi_dac_fifo/dac_dunf
ad_connect   sys_cpu_clk                                      inst0_axi_dac_fifo/dma_clk
ad_connect   sys_cpu_reset                                    inst0_axi_dac_fifo/dma_rst
ad_connect   sys_cpu_clk                                      inst0_dac_dma/m_axis_aclk
ad_connect   sys_cpu_resetn                                   inst0_dac_dma/m_src_axi_aresetn
ad_connect   inst0_axi_dac_fifo/dma_xfer_req                  inst0_dac_dma/m_axis_xfer_req
ad_connect   inst0_axi_dac_fifo/dma_ready                     inst0_dac_dma/m_axis_ready
ad_connect   inst0_axi_dac_fifo/dma_data                      inst0_dac_dma/m_axis_data
ad_connect   inst0_axi_dac_fifo/dma_valid                     inst0_dac_dma/m_axis_valid
ad_connect   inst0_axi_dac_fifo/dma_xfer_last                 inst0_dac_dma/m_axis_last

# interconnect (cpu)

ad_cpu_interconnect 0x44A60000 inst0_dac_jesd204_xcvr
ad_cpu_interconnect 0x44A04000 inst0_dac_jesd204_transport
ad_cpu_interconnect 0x44A90000 inst0_dac_jesd204_link
ad_cpu_interconnect 0x7c420000 inst0_dac_dma

##############     INST1 
create_bd_port -dir I inst1_dac_fifo_bypass

# dac peripherals

# JESD204 PHY layer peripheral
ad_ip_instance axi_adxcvr inst1_dac_jesd204_xcvr [list \
  NUM_OF_LANES $NUM_OF_LANES \
  QPLL_ENABLE 1 \
  TX_OR_RX_N 1 \
]

# JESD204 link layer peripheral
adi_axi_jesd204_tx_create inst1_dac_jesd204_link $NUM_OF_LANES $NUM_LINKS

# JESD204 transport layer peripheral
adi_tpl_jesd204_tx_create inst1_dac_jesd204_transport $NUM_OF_LANES \
                                                $NUM_OF_CONVERTERS \
                                                $SAMPLES_PER_FRAME \
                                                $SAMPLE_WIDTH

ad_ip_instance util_upack2 inst1_dac_upack [list \
  NUM_OF_CHANNELS $NUM_OF_CONVERTERS \
  SAMPLES_PER_CHANNEL $SAMPLES_PER_CHANNEL \
  SAMPLE_DATA_WIDTH $SAMPLE_WIDTH \
]

set dac_dma_data_width $DAC_DATA_WIDTH
ad_ip_instance axi_dmac inst1_dac_dma [list \
  DMA_TYPE_SRC 0 \
  DMA_TYPE_DEST 1 \
  DMA_DATA_WIDTH_SRC 64 \
  DMA_DATA_WIDTH_DEST $dac_dma_data_width \
]

ad_dacfifo_create inst1_axi_dac_fifo \
                  $DAC_DATA_WIDTH \
                  $dac_dma_data_width \
                  $dac_fifo_address_width

# shared transceiver core

ad_ip_instance util_adxcvr inst1_util_dac_jesd204_xcvr [list \
  RX_NUM_OF_LANES 0 \
  TX_NUM_OF_LANES $MAX_NUM_OF_LANES \
  TX_LANE_INVERT [expr 0x0F] \
  QPLL_REFCLK_DIV 1 \
  QPLL_FBDIV_RATIO 1 \
  QPLL_FBDIV 0x80 \
  TX_OUT_DIV 1 \
]

ad_connect sys_cpu_resetn inst1_util_dac_jesd204_xcvr/up_rstn
ad_connect sys_cpu_clk inst1_util_dac_jesd204_xcvr/up_clk

# reference clocks & resets

for {set i 0} {$i < $MAX_NUM_OF_LANES} {incr i} {
  if {$i % 4 == 0} {
    create_bd_port -dir I inst1_tx_ref_clk_${i}
    ad_xcvrpll inst1_tx_ref_clk_${i} inst1_util_dac_jesd204_xcvr/qpll_ref_clk_${i}
    set inst1_quad_ref_clk inst1_tx_ref_clk_${i}
  }
  ad_xcvrpll $inst1_quad_ref_clk inst1_util_dac_jesd204_xcvr/cpll_ref_clk_${i}
}

ad_xcvrpll inst1_dac_jesd204_xcvr/up_pll_rst inst1_util_dac_jesd204_xcvr/up_qpll_rst_*
ad_xcvrpll inst1_dac_jesd204_xcvr/up_pll_rst inst1_util_dac_jesd204_xcvr/up_cpll_rst_*

# connections (dac)

ad_xcvrcon inst1_util_dac_jesd204_xcvr inst1_dac_jesd204_xcvr inst1_dac_jesd204_link {} {} {} $MAX_NUM_OF_LANES

ad_connect inst1_util_dac_jesd204_xcvr/tx_out_clk_0 inst1_dac_jesd204_transport/link_clk
ad_connect inst1_util_dac_jesd204_xcvr/tx_out_clk_0 inst1_dac_upack/clk
ad_connect inst1_dac_jesd204_link_rstgen/peripheral_reset inst1_dac_upack/reset

ad_connect inst1_dac_jesd204_link/tx_data inst1_dac_jesd204_transport/link

ad_connect inst1_dac_jesd204_transport/dac_valid_0 inst1_dac_upack/fifo_rd_en
for {set i 0} {$i < $NUM_OF_CONVERTERS} {incr i} {
  ad_connect inst1_dac_upack/fifo_rd_data_$i inst1_dac_jesd204_transport/dac_data_$i
  ad_connect inst1_dac_jesd204_transport/dac_enable_$i  inst1_dac_upack/enable_$i
}

ad_connect   inst1_util_dac_jesd204_xcvr/tx_out_clk_0         inst1_axi_dac_fifo/dac_clk
ad_connect   inst1_dac_jesd204_link_rstgen/peripheral_reset   inst1_axi_dac_fifo/dac_rst
ad_connect   inst1_dac_upack/s_axis_valid                     VCC
ad_connect   inst1_dac_upack/s_axis_ready                     inst1_axi_dac_fifo/dac_valid
ad_connect   inst1_dac_upack/s_axis_data                      inst1_axi_dac_fifo/dac_data
ad_connect   inst1_dac_jesd204_transport/dac_dunf             inst1_axi_dac_fifo/dac_dunf
ad_connect   sys_cpu_clk                                      inst1_axi_dac_fifo/dma_clk
ad_connect   sys_cpu_reset                                    inst1_axi_dac_fifo/dma_rst
ad_connect   sys_cpu_clk                                      inst1_dac_dma/m_axis_aclk
ad_connect   sys_cpu_resetn                                   inst1_dac_dma/m_src_axi_aresetn
ad_connect   inst1_axi_dac_fifo/dma_xfer_req                  inst1_dac_dma/m_axis_xfer_req
ad_connect   inst1_axi_dac_fifo/dma_ready                     inst1_dac_dma/m_axis_ready
ad_connect   inst1_axi_dac_fifo/dma_data                      inst1_dac_dma/m_axis_data
ad_connect   inst1_axi_dac_fifo/dma_valid                     inst1_dac_dma/m_axis_valid
ad_connect   inst1_axi_dac_fifo/dma_xfer_last                 inst1_dac_dma/m_axis_last

# interconnect (cpu)
ad_cpu_interconnect 0x44B60000 inst1_dac_jesd204_xcvr
ad_cpu_interconnect 0x44B04000 inst1_dac_jesd204_transport
ad_cpu_interconnect 0x44B90000 inst1_dac_jesd204_link
ad_cpu_interconnect 0x7c520000 inst1_dac_dma

# interconnect (mem/dac)

ad_mem_hp1_interconnect sys_cpu_clk sys_ps7/S_AXI_HP1
ad_mem_hp1_interconnect sys_cpu_clk inst0_dac_dma/m_src_axi

ad_mem_hp2_interconnect sys_cpu_clk sys_ps7/S_AXI_HP1
ad_mem_hp2_interconnect sys_cpu_clk inst1_dac_dma/m_src_axi

# interrupts

ad_cpu_interrupt ps-10 mb-15 inst0_dac_jesd204_link/irq
ad_cpu_interrupt ps-12 mb-13 inst0_dac_dma/irq

ad_connect inst0_axi_dac_fifo/bypass inst0_dac_fifo_bypass

ad_cpu_interrupt ps-2 mb-7 inst0_dac_jesd204_link/irq
ad_cpu_interrupt ps-4 mb-5 inst0_dac_dma/irq

ad_connect inst0_axi_dac_fifo/bypass inst0_dac_fifo_bypass

