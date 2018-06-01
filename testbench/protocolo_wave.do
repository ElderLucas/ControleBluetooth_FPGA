onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /protocolo_tb/CLK
add wave -noupdate /protocolo_tb/RST
add wave -noupdate /protocolo_tb/data_send
add wave -noupdate /protocolo_tb/data_in
add wave -noupdate -divider {UART TX}
add wave -noupdate /protocolo_tb/tx_uart
add wave -noupdate /protocolo_tb/rx_uart
add wave -noupdate -divider {UART RX}
add wave -noupdate /protocolo_tb/sdata
add wave -noupdate /protocolo_tb/data_vld
add wave -noupdate /protocolo_tb/frame_error
add wave -noupdate -divider PROTOCOLO
add wave -noupdate /protocolo_tb/protocolo_rx/CLK
add wave -noupdate /protocolo_tb/protocolo_rx/RST
add wave -noupdate /protocolo_tb/protocolo_rx/data_en_in
add wave -noupdate /protocolo_tb/protocolo_rx/state
add wave -noupdate -radix hexadecimal /protocolo_tb/protocolo_rx/reg_data_in
add wave -noupdate -divider {SINAIS DA UART}
add wave -noupdate /protocolo_tb/sdata_bus_cs
add wave -noupdate /protocolo_tb/sdata_bus_en_i
add wave -noupdate /protocolo_tb/sdata_bus_en_o
add wave -noupdate /protocolo_tb/sdata_bus_rw
add wave -noupdate -divider {SINAIS DA UART}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {29999992222 ps} 0}
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
WaveRestoreZoom {29998730914 ps} {30001260194 ps}
