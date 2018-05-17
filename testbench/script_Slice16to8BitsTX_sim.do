
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
vcom -check_synthesis ../vhdl/slice16to8bitsTX.vhd

# Simulação ModelSim
vcom -check_synthesis ../testbench/tb_slice16to8bitsTX.vhd

# 5 - Start Simulation
vsim work.SLICE_TB

# 6 - Prepare Simulation : set up your simulation/debug environment for the design
view objects
view locals
view source

# Detach wave as a separate window (undock)
view wave -undock


# 7 - Add wave
add wave /SLICE_TB/CLK
add wave /SLICE_TB/RST

add wave -noupdate -divider {Data}

add wave /SLICE_TB/EN_DATA_s
add wave /SLICE_TB/READ_BUSY_s

add wave -noupdate -divider {UUT}
add wave /SLICE_TB/utt/CLK
add wave /SLICE_TB/utt/RST

add wave /SLICE_TB/utt/DATA_IN
add wave /SLICE_TB/utt/EN_DATA_IN
add wave /SLICE_TB/utt/data_reg_s

add wave -noupdate -divider {Saída}
add wave /SLICE_TB/utt/data_out_s

add wave -noupdate -divider {READ BUSY}
add wave /SLICE_TB/utt/reg_busy_s
add wave /SLICE_TB/utt/READ_BUSY

add wave -noupdate -divider {State Machine}
add wave /SLICE_TB/utt/tx_state
add wave /SLICE_TB/utt/EN_DATA_OUT
add wave /SLICE_TB/utt/DATA_OUT


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

run 2000us
