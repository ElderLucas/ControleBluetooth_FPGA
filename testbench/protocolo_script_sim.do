
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

vcom -check_synthesis ../vhdl/protocolo.vhd

# Simulação ModelSim
vcom -check_synthesis ../testbench/protocolo_tb.vhd

# 5 - Start Simulation
vsim work.PROTOCOLO_TB

# 6 - Prepare Simulation : set up your simulation/debug environment for the design
view objects
view locals
view source

# Detach wave as a separate window (undock)
view wave -undock

# 7 - Add wave
add wave /PROTOCOLO_TB/CLK
add wave /PROTOCOLO_TB/RST

add wave /PROTOCOLO_TB/data_send
add wave /PROTOCOLO_TB/data_in

add wave -noupdate -divider { PROTOCOLO }
add wave /PROTOCOLO_TB/protocolo_rx/CLK
add wave /PROTOCOLO_TB/protocolo_rx/RST
add wave /PROTOCOLO_TB/protocolo_rx/data_en_in

add wave -noupdate -divider {SINAIS DA UART}
add wave /PROTOCOLO_TB/sdata_bus_cs
add wave /PROTOCOLO_TB/sdata_bus_en_i
add wave /PROTOCOLO_TB/sdata_bus_en_o
add wave /PROTOCOLO_TB/sdata_bus_rw

add wave /PROTOCOLO_TB/protocolo_rx/state

add wave -noupdate -divider {SINAIS DA UART}
#add wave -radix unsigned /PROTOCOLO_TB/protocolo_rx/

#add wave -color #ff2255 -format Analog-Step -height 74 -max 3.0 -min -4.0 /adc128s022_tb/ADC_CH_ADDRESS_S

#add wave *
#add wave /sttran/count_v

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

run 30ms
