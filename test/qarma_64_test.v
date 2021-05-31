module TestBench_Qarma64(
    input clk_in);

`ifdef ICARUS
  reg clk = 1;
  always #1 clk = ~clk;

`else // VERILATOR
  wire clk = clk_in;
`endif

  reg reset_n = 0;
  reg [63:0] in;
  reg [63:0] tweak;
  reg [127:0] key;
  wire [63:0] out;
  wire ready;

  reg [4:0] state;

  initial
  begin
    state = 0;
    reset_n = 0;
  end

  always @(posedge clk)
  begin
    $display("%d %x", ready, out);

    state <= state + 1;

    case (state)
    1: begin
      in <= 64'hfb623599da6e8127;
      tweak <= 64'h477d469dec0b8762;
      key <= { 64'h84be85ce9804e94b, 64'hec2802d4e0a488e9 };
    end

    2: begin
      reset_n <= 1;
    end

    31: $finish;
    endcase
  end

  Qarma64 a (
    .clk(clk),
    .reset_n(reset_n),
    .in(in),
    .tweak(tweak),
    .key(key),
    .out(out),
    .ready(ready)
  );
endmodule
