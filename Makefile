all: qarma_64

BUILD := build/

qarma_64: $(BUILD)/Vqarma_64_icarus

$(BUILD)/Vqarma_64_icarus: qarma_64.v test/qarma_64_test.v
	mkdir -p $(BUILD)
	iverilog -o $@ -DICARUS $^
	./$@

clean:
	rm -rf $(BUILD)
