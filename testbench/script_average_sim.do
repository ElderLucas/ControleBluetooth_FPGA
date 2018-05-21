
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
vcom -check_synthesis ../vhdl/moving_average.vhd

# Simulação ModelSim
vcom -check_synthesis ../testbench/average_tb.vhd

# 5 - Start Simulation
vsim work.average_tb

# 6 - Prepare Simulation : set up your simulation/debug environment for the design
view objects
view locals
view source

# Detach wave as a separate window (undock)
view wave -undock


# 7 - Add wave
add wave /average_tb/CLK
add wave /average_tb/RST

add wave /average_tb/enb_data_in1_s
add wave /average_tb/sample_data

add wave -noupdate -divider {Average Module}
add wave /average_tb/channel_1/CLK
add wave /average_tb/channel_1/RST
add wave /average_tb/channel_1/load
add wave /average_tb/channel_1/sample
add wave /average_tb/channel_1/average
add wave /average_tb/channel_1/enb_data_out
add wave -noupdate -divider {Average Module SIGNALS}
add wave /average_tb/channel_1/count
add wave /average_tb/channel_1/sum
add wave /average_tb/channel_1/shift_reg_s

add wave -noupdate -divider {UUT}
add wave /average_tb/channel_1/CLK
add wave /average_tb/channel_1/RST





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
