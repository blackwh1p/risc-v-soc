## ============================================================
## Constraints : Nexys A7-100T
## Project     : Custom RISC-V SoC
## ============================================================

## --- System Clock (100MHz) ---
set_property PACKAGE_PIN E3 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
create_clock -add -name sys_clk_pin -period 10.00 \
    -waveform {0 5} [get_ports clk_100mhz]

## --- CPU Reset Button (BTNC — center button, active low) ---
set_property PACKAGE_PIN N17 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## --- UART ---
set_property PACKAGE_PIN D4 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property PACKAGE_PIN C4 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

## --- LEDs ---
set_property PACKAGE_PIN H17 [get_ports {leds[0]}]
set_property PACKAGE_PIN K15 [get_ports {leds[1]}]
set_property PACKAGE_PIN J13 [get_ports {leds[2]}]
set_property PACKAGE_PIN N14 [get_ports {leds[3]}]
set_property PACKAGE_PIN R18 [get_ports {leds[4]}]
set_property PACKAGE_PIN V17 [get_ports {leds[5]}]
set_property PACKAGE_PIN U17 [get_ports {leds[6]}]
set_property PACKAGE_PIN U16 [get_ports {leds[7]}]
set_property PACKAGE_PIN V16 [get_ports {leds[8]}]
set_property PACKAGE_PIN T15 [get_ports {leds[9]}]
set_property PACKAGE_PIN U14 [get_ports {leds[10]}]
set_property PACKAGE_PIN T16 [get_ports {leds[11]}]
set_property PACKAGE_PIN V15 [get_ports {leds[12]}]
set_property PACKAGE_PIN V14 [get_ports {leds[13]}]
set_property PACKAGE_PIN V12 [get_ports {leds[14]}]
set_property PACKAGE_PIN V11 [get_ports {leds[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[*]}]

## --- Switches ---
set_property PACKAGE_PIN J15 [get_ports {switches[0]}]
set_property PACKAGE_PIN L16 [get_ports {switches[1]}]
set_property PACKAGE_PIN M13 [get_ports {switches[2]}]
set_property PACKAGE_PIN R15 [get_ports {switches[3]}]
set_property PACKAGE_PIN R17 [get_ports {switches[4]}]
set_property PACKAGE_PIN T18 [get_ports {switches[5]}]
set_property PACKAGE_PIN U18 [get_ports {switches[6]}]
set_property PACKAGE_PIN R13 [get_ports {switches[7]}]
set_property PACKAGE_PIN T8  [get_ports {switches[8]}]
set_property PACKAGE_PIN U8  [get_ports {switches[9]}]
set_property PACKAGE_PIN R16 [get_ports {switches[10]}]
set_property PACKAGE_PIN T13 [get_ports {switches[11]}]
set_property PACKAGE_PIN H6  [get_ports {switches[12]}]
set_property PACKAGE_PIN U12 [get_ports {switches[13]}]
set_property PACKAGE_PIN U11 [get_ports {switches[14]}]
set_property PACKAGE_PIN V10 [get_ports {switches[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {switches[*]}]

## --- Buttons ---
set_property PACKAGE_PIN M18 [get_ports {buttons[0]}]
set_property PACKAGE_PIN P17 [get_ports {buttons[1]}]
set_property PACKAGE_PIN M17 [get_ports {buttons[2]}]
set_property PACKAGE_PIN N17 [get_ports {buttons[3]}]
set_property PACKAGE_PIN P18 [get_ports {buttons[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {buttons[*]}]