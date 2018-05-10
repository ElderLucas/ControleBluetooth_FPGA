onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /adc128s022_tb/CLK
add wave -noupdate /adc128s022_tb/RST
add wave -noupdate /adc128s022_tb/CONV_ENB_S
add wave -noupdate /adc128s022_tb/CONV_CH_SEL_S
add wave -noupdate /adc128s022_tb/DATA_VALID_S
add wave -noupdate -color #002255 -format Analog-Step -height 74 -max 3.0 -min -4.0 /adc128s022_tb/ADC_CH_ADDRESS_S
add wave -noupdate /adc128s022_tb/ADC_DATAOUT_S
add wave -noupdate /adc128s022_tb/SCLKC_S
add wave -noupdate /adc128s022_tb/SS_S
add wave -noupdate /adc128s022_tb/MOSI_S
add wave -noupdate /adc128s022_tb/MISO_S
add wave -noupdate /adc128s022_tb/utt/r_counter_data
add wave -noupdate /adc128s022_tb/utt/r_sclk_fall
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1221190000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {6541541376 ps}
