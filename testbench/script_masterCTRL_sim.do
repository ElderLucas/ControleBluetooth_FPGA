
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
vcom -check_synthesis ../vhdl/masterCTRL.vhd

# Simulação ModelSim
vcom -check_synthesis ../testbench/masterCTRL_test_bench.vhd

# 5 - Start Simulation
vsim work.masterCTRLTB

# 6 - Prepare Simulation : set up your simulation/debug environment for the design
view objects
view locals
view source

# Detach wave as a separate window (undock)
view wave -undock


# 7 - Add wave
add wave /masterCTRLTB/CLK
add wave /masterCTRLTB/RST

#add wave /adc128s022_tb/utt/r_counter_clock

add wave /masterCTRLTB/utt/clk
add wave /masterCTRLTB/utt/data_in
add wave /masterCTRLTB/utt/reset
add wave /masterCTRLTB/utt/data_out
add wave /masterCTRLTB/utt/state
add wav -color #ff2255 /masterCTRLTB/Busy_s

add wave -noupdate -divider {BARRAMENTO ADC}


add wave /masterCTRLTB/utt_ad/i_clk
add wave /masterCTRLTB/utt_ad/i_rstb
add wave /masterCTRLTB/utt_ad/i_conv_ena
add wave /masterCTRLTB/utt_ad/i_adc_ch
add wave /masterCTRLTB/utt_ad/o_adc_data_valid
add wave /masterCTRLTB/utt_ad/o_adc_ch
add wave /masterCTRLTB/utt_ad/o_adc_data
add wave /masterCTRLTB/utt_ad/o_sclk
add wave /masterCTRLTB/utt_ad/o_ss
add wave /masterCTRLTB/utt_ad/o_mosi
add wave /masterCTRLTB/utt_ad/i_miso


add wave /masterCTRLTB/CLK
add wave /masterCTRLTB/RST
add wave /masterCTRLTB/CONV_ENB_S
add wave /masterCTRLTB/CONV_CH_SEL_S
add wave /masterCTRLTB/DATA_VALID_S
add wave /masterCTRLTB/ADC_CH_ADDRESS_S
add wave /masterCTRLTB/ADC_DATAOUT_S

add wave /masterCTRLTB/SCLKC_S
add wave /masterCTRLTB/SS_S
add wave /masterCTRLTB/MOSI_S
add wave /masterCTRLTB/MISO_S



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

run 900us
