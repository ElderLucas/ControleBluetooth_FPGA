
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
vcom -check_synthesis ../vhdl/UART_PARITY.vhd
vcom -check_synthesis ../vhdl/UART_TX.vhd
vcom -check_synthesis ../vhdl/UART_RX.vhd
vcom -check_synthesis ../vhdl/UART.vhd

vcom -check_synthesis ../vhdl/timer.vhd
vcom -check_synthesis ../vhdl/masterCTRL.vhd
vcom -check_synthesis ../vhdl/ADC128S022.vhd
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

# 7 - Add wave
add wave /TOPO_TB/CLK
add wave /TOPO_TB/RST

add wave -noupdate -divider { TOPO }
add wave /TOPO_TB/utt/CLK
add wave /TOPO_TB/utt/RST
add wave /TOPO_TB/utt/RST_s
add wave /TOPO_TB/utt/timer_1seg_s
add wave /TOPO_TB/led_out_s

add wave -noupdate -divider {TIMER 1 Segundo}
add wave -radix unsigned /topo_tb/utt/tic_1segundo/timer_1seg_cnt
add wave /topo_tb/utt/tic_1segundo/CLK
add wave /topo_tb/utt/tic_1segundo/RST
add wave /topo_tb/utt/tic_1segundo/TIMER_1SEG
add wave /topo_tb/utt/tic_1segundo/timer_1seg_cnt

add wave -noupdate -divider {CONTROLE ADC}

add wave /topo_tb/utt/adc128s022/i_rstb
add wave /topo_tb/utt/adc128s022/i_clk


add wave /topo_tb/utt/timer_1seg_s
add wave /topo_tb/utt/RST
add wave /topo_tb/utt/CONV_ENB_S
add wave /topo_tb/utt/DATA_VALID_S
add wave /topo_tb/utt/CONV_CH_SEL_S
add wave /topo_tb/utt/Busy_s
add wave /topo_tb/utt/DATA_OUT_S
add wave -noupdate -divider {SERIAL ADC}
add wave /topo_tb/utt/SCLKC_S
add wave /topo_tb/utt/SS_S
add wave /topo_tb/utt/MOSI_S
add wave /topo_tb/utt/MISO_S

add wave -noupdate -divider {MAQUINA DE ESTADOS MASTER}
add wave /topo_tb/utt/controlador/state


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
