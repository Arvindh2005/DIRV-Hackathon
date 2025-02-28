TOP = systolic_conv_uart
PCF_FILE = VSDSquadronFM.pcf
BOARD_FREQ = 12
FPGA_VARIANT = up5k
FPGA_PACKAGE = sg48

VERILOG_FILES = top.v uart_trx.v

PICO_DEVICE=/dev/serial/by-id/usb-FTDI_Single_RS232-HS-if00-port0	#replace by the terminal used by your device
BAUDS=9600

build:
	yosys -q -p "synth_ice40 -abc9 -device u -dsp -top $(TOP) -json $(TOP).json" $(VERILOG_FILES)
	nextpnr-ice40 --force --json $(TOP).json --pcf $(PCF_FILE) --asc $(TOP).asc --freq $(BOARD_FREQ) --$(FPGA_VARIANT) --package $(FPGA_PACKAGE) --opt-timing
	icetime -p $(PCF_FILE) -P $(FPGA_PACKAGE) -r $(TOP).timings -d $(FPGA_VARIANT) -t $(TOP).asc
	icepack -s $(TOP).asc $(TOP).bin

flash:
	iceprog $(TOP).bin

clean:
	rm -rf $(TOP).blif $(TOP).asc $(TOP).bin $(TOP).json $(TOP).timings

terminal:
	sudo picocom -b $(BAUDS) $(PICO_DEVICE) --imap lfcrlf,crcrlf --omap delbs,crlf,8bithex -d 8 -s 1 

.PHONY: build flash clean terminal
