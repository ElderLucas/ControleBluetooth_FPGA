
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
#vcom -check_synthesis ../vhdl/lock_pkg.vhd
#vcom -check_synthesis ../vhdl/lock.vhd


vcom -check_synthesis ../vhdl/uart_parity.vhd
vcom -check_synthesis ../vhdl/uart_tx.vhd
vcom -check_synthesis ../vhdl/uart_rx.vhd

vcom -check_synthesis ../vhdl/uart.vhd


# Simulação ModelSim
#vcom -check_synthesis ../testbench/tb_lock.vhd
vcom -check_synthesis ../testbench/uart_tb.vhd

# 5 - Start Simulation
vsim work.uart_tb

# 6 - Prepare Simulation : set up your simulation/debug environment for the design
view objects
view locals
view source

# Detach wave as a separate window (undock)
view wave -undock

# 7 - Add wave
#add wave *
#add wave /sttran/count_v

add wave /CLK
add wave /RST
add wave /tx_uart
add wave /rx_uart
add wave /data_vld
add wave /data_out
add wave /frame_error
add wave /data_send
add wave /busy
add wave /data_in


add wave /uart_tb/utt/uart_tx_i/tx_clk_en




# 8 - Add wave
#force -deposit /rst_n 0 0, 1 {45 ns}
#force -deposit /clk 1 0, 0 {10 ns}
#force -deposit /clk 1 0, 0 {10 ns} -repeat 20
#force -deposit /clk 1 0, 0 {10 ns} -repeat 20 ns
#force -deposit /keys_in 0000 0

set Top_Level_Name tb

#add wave *

view structure
view signals
run –all
