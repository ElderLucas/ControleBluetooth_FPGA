
################################################################################
# Simulação do projeto
################################################################################
# ref : http://www.tkt.cs.tut.fi/tools/public/tutorials/mentor/modelsim/getting_started/gsms.html

# 1 - Open Directory
#../testbench

# 2 - Create my own design library ...
vlib work

# 3 - ... and map it as 'work'
vmap work ./work

# 4 - Now it's time to compile the sources
vcom -check_synthesis ../vhdl/uart_parity.vhd
vcom -check_synthesis ../vhdl/uart_tx.vhd
vcom -check_synthesis ../vhdl/uart_rx.vhd
vcom -check_synthesis ../vhdl/uart.vhd

vcom -check_synthesis ../vhdl/timer.vhd
vcom -check_synthesis ../vhdl/masterCTRL.vhd
vcom -check_synthesis ../vhdl/ADC128S022.vhd
vcom -check_synthesis ../vhdl/moving_average.vhd
vcom -check_synthesis ../vhdl/protocolo.vhd
vcom -check_synthesis ../vhdl/topo.vhd

# Simulação ModelSim
vcom -check_synthesis ../testbench/topo_tb.vhd

# 5 - Start Simulation
vsim work.TOPO_TB

# 6 - Prepare Simulation : set up your simulation/debug environment for the design
view objects
view locals
view source

# Detach wave as a separate window (undock)
view wave -undock

################################################################################
# 1 - Add wave
################################################################################
add wave -noupdate -divider { }
add wave /TOPO_TB/CLK
add wave /TOPO_TB/RST

add wave -noupdate -divider { UART RX DATA TOPO TB }
add wave /TOPO_TB/tx_uart
add wave /TOPO_TB/rx_uart

add wave -noupdate -divider { ENTRADA PARALELA UART TX }
add wave -noupdate -radix hexadecimal /TOPO_TB/data_in
add wave /TOPO_TB/data_send
add wave /TOPO_TB/busy

add wave -noupdate -divider { DENTRO DO TOPO }

add wave -noupdate -divider { }

add wave -noupdate -divider { UART RX }
add wave /TOPO_TB/utt/CLK
add wave /TOPO_TB/utt/RST
add wave /TOPO_TB/utt/UART_RXD
add wave /TOPO_TB/utt/uart_rxd_shreg
add wave /TOPO_TB/utt/uart_clk_en
add wave /TOPO_TB/utt/uart_rxd_debounced

add wave -noupdate -divider { UART RX : SAÍDA PARALELA DO BLOCO }
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/rDATA_OUT
add wave /TOPO_TB/utt/rDATA_VLD


################################################################################
# 2 - Add wave PROTOCOLO
################################################################################

add wave -noupdate -divider { }
add wave -noupdate -divider { PROTOCOLO : ENTRADA DO BLOCO }

add wave /TOPO_TB/utt/protocolo_rx/data_en_in
add wave /TOPO_TB/utt/protocolo_rx/data_in
add wave /TOPO_TB/utt/protocolo_rx/count_rx_data

add wave -noupdate -divider { PROTOCOLO : STATE MACHINE }
add wave /TOPO_TB/utt/protocolo_rx/state

add wave -noupdate -divider { }
add wave -noupdate -divider { PROTOCOLO : RAM DE DADOS }
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/protocolo_rx/rSTART
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/protocolo_rx/rADDRESS
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/protocolo_rx/rCOMMAND
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/protocolo_rx/rSTOP
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/protocolo_rx/DATA_RAM_REG

add wave -noupdate -divider { PROTOCOLO : SAÍDA }
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/protocolo_rx/address_bus_out
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/protocolo_rx/command_bus_out
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/protocolo_rx/chip_select
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/protocolo_rx/data_bus_out
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/protocolo_rx/crud_out
add wave /TOPO_TB/utt/protocolo_rx/state


add wave -noupdate -divider { }
add wave -noupdate -divider { MASTER INSIDE }
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/controlador/CLK
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/controlador/RST
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/controlador/r_chip_select
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/controlador/crud_in
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/controlador/chip_select
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/controlador/data_bus_in
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/controlador/address_bus_in
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/controlador/enable_data_in
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/controlador/data_bus_out
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/controlador/enable_data_out
add wave -noupdate -radix hexadecimal /TOPO_TB/utt/controlador/address_bus_out



set Top_Level_Name tb

#add wave *

view structure
view signals

run 50ms
