all: qarma_64

BUILD := build/

qarma_64: $(BUILD)/Vqarma_64_icarus $(BUILD)/Vqarma_64

$(BUILD)/Vqarma_64_icarus: qarma_64.v test/qarma_64_test.v
	mkdir -p $(BUILD)
	iverilog -o $@ -DICARUS $^
	./$@

IS_VERILATOR_4 = $(shell verilator --version | grep "Verilator 4")

$(BUILD)/Vqarma_64: qarma_64.v test/qarma_64_test.v test/qarma_64_test_main.cpp
ifeq ($(IS_VERILATOR_4),)
	echo "Verilator 4 missing: Skipping test"
else
	mkdir -p $(BUILD)
	verilator --cc --exe -Wall -Wno-DECLFILENAME --build $^ -Mdir $(BUILD)/
	./$@
endif

clean:
	rm -rf $(BUILD)
