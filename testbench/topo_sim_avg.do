
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
add wave -noupdate -divider { PROTOCOLO : RAM DE DADOS }

add wave -noupdate -radix hexadecimal /TOPO_TB/CONFIG_WORD

add wave /TOPO_TB/utt/channel_0/RST
add wave /TOPO_TB/utt/channel_0/CLK

add wave /TOPO_TB/utt/channel_0/sum
add wave /TOPO_TB/utt/channel_0/count
add wave /TOPO_TB/utt/channel_0/enb_data_s
add wave /TOPO_TB/utt/channel_0/average_s


set Top_Level_Name tb

#add wave *

view structure
view signals

run 50ms
