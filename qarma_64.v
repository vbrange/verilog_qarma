module Qarma64(
    input clk,
    input reset_n,
    input [63:0] in,
    input [63:0] tweak,
    input [127:0] key,
    output [63:0] out,
    output ready);

  localparam STATE_BUSY = 0;
  localparam STATE_IDLE = 1;

  reg state;
  reg [4:0] round;
  reg buf_ready;

  reg [63:0]  buf_tweak;
  reg [63:0]  buf_out;
  reg [63:0]  buf_in;
  reg [63:0]  buf_round_key;

  assign out = buf_out;
  assign ready = buf_ready;

  function [3:0] Sbox (input [3:0] x);
  begin
    case (x)
      0:  Sbox = 0;  1:  Sbox = 14;
      2:  Sbox = 2;  3:  Sbox = 10;
      4:  Sbox = 9;  5:  Sbox = 15;
      6:  Sbox = 8;  7:  Sbox = 11;
      8:  Sbox = 6;  9:  Sbox = 4;
      10: Sbox = 3;  11: Sbox = 7;
      12: Sbox = 13; 13: Sbox = 12;
      14: Sbox = 1;  15: Sbox = 5;
    endcase
  end
  endfunction

  function [63:0] SubCells (input [63:0] buf_state);
    integer i;
  begin
    for (i = 0; i < 16; i = i + 1)
    begin
      SubCells[i*4+:4] = Sbox(buf_state[i*4+:4]);
    end
  end
  endfunction

  function [63:0] ShuffleCells (input [63:0] buf_state);
  begin
    ShuffleCells[63:60] = buf_state[63:60];
    ShuffleCells[59:56] = buf_state[19:16];
    ShuffleCells[55:52] = buf_state[39:36];
    ShuffleCells[51:48] = buf_state[11:8];
    ShuffleCells[47:44] = buf_state[23:20];
    ShuffleCells[43:40] = buf_state[59:56];
    ShuffleCells[39:36] = buf_state[15:12];
    ShuffleCells[35:32] = buf_state[35:32];
    ShuffleCells[31:28] = buf_state[43:40];
    ShuffleCells[27:24] = buf_state[7:4];
    ShuffleCells[23:20] = buf_state[51:48];
    ShuffleCells[19:16] = buf_state[31:28];
    ShuffleCells[15:12] = buf_state[3:0];
    ShuffleCells[11:8] = buf_state[47:44];
    ShuffleCells[7:4] = buf_state[27:24];
    ShuffleCells[3:0] = buf_state[55:52];
  end
  endfunction

  function [63:0] ShuffleCellsBackwards (input [63:0] buf_state);
  begin
    ShuffleCellsBackwards[63:60] = buf_state[63:60];
    ShuffleCellsBackwards[59:56] = buf_state[43:40];
    ShuffleCellsBackwards[55:52] = buf_state[3:0];
    ShuffleCellsBackwards[51:48] = buf_state[23:20];
    ShuffleCellsBackwards[47:44] = buf_state[11:8];
    ShuffleCellsBackwards[43:40] = buf_state[31:28];
    ShuffleCellsBackwards[39:36] = buf_state[55:52];
    ShuffleCellsBackwards[35:32] = buf_state[35:32];
    ShuffleCellsBackwards[31:28] = buf_state[19:16];
    ShuffleCellsBackwards[27:24] = buf_state[7:4];
    ShuffleCellsBackwards[23:20] = buf_state[47:44];
    ShuffleCellsBackwards[19:16] = buf_state[59:56];
    ShuffleCellsBackwards[15:12] = buf_state[39:36];
    ShuffleCellsBackwards[11:8] = buf_state[51:48];
    ShuffleCellsBackwards[7:4] = buf_state[27:24];
    ShuffleCellsBackwards[3:0] = buf_state[15:12];
  end 
  endfunction

  function [63:0] MixColumns (input [63:0] buf_state);
  begin
    MixColumns[3:0] = { buf_state[18:16], buf_state[19:19] } ^ { buf_state[33:32], buf_state[35:34] } ^ { buf_state[50:48], buf_state[51:51] };
    MixColumns[19:16] = { buf_state[2:0], buf_state[3:3] } ^ { buf_state[34:32], buf_state[35:35] } ^ { buf_state[49:48], buf_state[51:50] };
    MixColumns[35:32] = { buf_state[1:0], buf_state[3:2] } ^ { buf_state[18:16], buf_state[19:19] } ^ { buf_state[50:48], buf_state[51:51] };
    MixColumns[51:48] = { buf_state[2:0], buf_state[3:3] } ^ { buf_state[17:16], buf_state[19:18] } ^ { buf_state[34:32], buf_state[35:35] };
    MixColumns[7:4] = { buf_state[22:20], buf_state[23:23] } ^ { buf_state[37:36], buf_state[39:38] } ^ { buf_state[54:52], buf_state[55:55] };
    MixColumns[23:20] = { buf_state[6:4], buf_state[7:7] } ^ { buf_state[38:36], buf_state[39:39] } ^ { buf_state[53:52], buf_state[55:54] };
    MixColumns[39:36] = { buf_state[5:4], buf_state[7:6] } ^ { buf_state[22:20], buf_state[23:23] } ^ { buf_state[54:52], buf_state[55:55] };
    MixColumns[55:52] = { buf_state[6:4], buf_state[7:7] } ^ { buf_state[21:20], buf_state[23:22] } ^ { buf_state[38:36], buf_state[39:39] };
    MixColumns[11:8] = { buf_state[26:24], buf_state[27:27] } ^ { buf_state[41:40], buf_state[43:42] } ^ { buf_state[58:56], buf_state[59:59] };
    MixColumns[27:24] = { buf_state[10:8], buf_state[11:11] } ^ { buf_state[42:40], buf_state[43:43] } ^ { buf_state[57:56], buf_state[59:58] };
    MixColumns[43:40] = { buf_state[9:8], buf_state[11:10] } ^ { buf_state[26:24], buf_state[27:27] } ^ { buf_state[58:56], buf_state[59:59] };
    MixColumns[59:56] = { buf_state[10:8], buf_state[11:11] } ^ { buf_state[25:24], buf_state[27:26] } ^ { buf_state[42:40], buf_state[43:43] };
    MixColumns[15:12] = { buf_state[30:28], buf_state[31:31] } ^ { buf_state[45:44], buf_state[47:46] } ^ { buf_state[62:60], buf_state[63:63] };
    MixColumns[31:28] = { buf_state[14:12], buf_state[15:15] } ^ { buf_state[46:44], buf_state[47:47] } ^ { buf_state[61:60], buf_state[63:62] };
    MixColumns[47:44] = { buf_state[13:12], buf_state[15:14] } ^ { buf_state[30:28], buf_state[31:31] } ^ { buf_state[62:60], buf_state[63:63] };
    MixColumns[63:60] = { buf_state[14:12], buf_state[15:15] } ^ { buf_state[29:28], buf_state[31:30] } ^ { buf_state[46:44], buf_state[47:47] };
  end
  endfunction

  function [63:0] RoundForward (input [63:0] buf_state, input [63:0] round_key);
  begin
    RoundForward = SubCells(MixColumns(ShuffleCells(buf_state ^ round_key)));
  end
  endfunction

  function [63:0] PartialRoundForward (input [63:0] buf_state, input [63:0] round_key);
  begin
    PartialRoundForward = SubCells(buf_state ^ round_key);
  end
  endfunction

  function [63:0] RoundBackwards (input [63:0] buf_state, input [63:0] round_key);
  begin
    RoundBackwards = ShuffleCellsBackwards(MixColumns(SubCells(buf_state))) ^ round_key;
  end
  endfunction

  function [63:0] PartialRoundBackwards (input [63:0] buf_state, input [63:0] round_key);
  begin
    PartialRoundBackwards = SubCells(buf_state) ^ round_key;
  end
  endfunction

  function [3:0] LfsrForward (input [3:0] nibble);
  begin
    LfsrForward = { nibble[0]^nibble[1], nibble[3], nibble[2], nibble[1] };
  end
  endfunction

  function [3:0] LfsrBackwards (input [3:0] nibble);
  begin
    LfsrBackwards = { nibble[2], nibble[1], nibble[0], nibble[0]^nibble[3] };
  end
  endfunction

  function [63:0] TweakForward (input [63:0] buf_state);
  begin
    TweakForward[47:44] = LfsrForward(buf_state[63:60]);
    TweakForward[43:40] = buf_state[59:56];
    TweakForward[39:36] = buf_state[55:52];
    TweakForward[35:32] = buf_state[51:48];
    TweakForward[19:16] = LfsrForward(buf_state[47:44]);
    TweakForward[59:56] = LfsrForward(buf_state[43:40]);
    TweakForward[63:60] = LfsrForward(buf_state[39:36]);
    TweakForward[31:28] = LfsrForward(buf_state[35:32]);
    TweakForward[15:12] = buf_state[31:28];
    TweakForward[11:8] = LfsrForward(buf_state[27:24]);
    TweakForward[7:4] = buf_state[23:20];
    TweakForward[3:0] = buf_state[19:16];
    TweakForward[27:24] = buf_state[15:12];
    TweakForward[23:20] = buf_state[11:8];
    TweakForward[55:52] = buf_state[7:4];
    TweakForward[51:48] = LfsrForward(buf_state[3:0]);
  end
  endfunction

  function [63:0] TweakBackwards (input [63:0] buf_state);
  begin
    TweakBackwards[63:60] = LfsrBackwards(buf_state[47:44]);
    TweakBackwards[59:56] = buf_state[43:40];
    TweakBackwards[55:52] = buf_state[39:36];
    TweakBackwards[51:48] = buf_state[35:32];
    TweakBackwards[47:44] = LfsrBackwards(buf_state[19:16]);
    TweakBackwards[43:40] = LfsrBackwards(buf_state[59:56]);
    TweakBackwards[39:36] = LfsrBackwards(buf_state[63:60]);
    TweakBackwards[35:32] = LfsrBackwards(buf_state[31:28]);
    TweakBackwards[31:28] = buf_state[15:12];
    TweakBackwards[27:24] = LfsrBackwards(buf_state[11:8]);
    TweakBackwards[23:20] = buf_state[7:4];
    TweakBackwards[19:16] = buf_state[3:0];
    TweakBackwards[15:12] = buf_state[27:24];
    TweakBackwards[11:8] = buf_state[23:20];
    TweakBackwards[7:4] = buf_state[55:52];
    TweakBackwards[3:0] = LfsrBackwards(buf_state[51:48]);
  end
  endfunction

  function [63:0] PseudoReflect (input [63:0] buf_state, input [63:0] round_key);
  begin
    PseudoReflect = ShuffleCellsBackwards(MixColumns(ShuffleCells(buf_state)) ^ round_key);
  end
  endfunction

  wire [63:0] round_circuit;
  assign round_circuit = RoundForward(buf_in, buf_round_key);

  wire [63:0] partial_round_circuit;
  assign partial_round_circuit = PartialRoundForward(buf_in, buf_round_key);

  wire [63:0] round_inv_circuit;
  assign round_inv_circuit = RoundBackwards(buf_in, buf_round_key);

  wire [63:0] partial_round_inv_circuit;
  assign partial_round_inv_circuit = PartialRoundBackwards(buf_in, buf_round_key);

  wire [63:0] pseudo_reflect_circuit;
  assign pseudo_reflect_circuit = PseudoReflect(buf_in, buf_round_key);

  wire [63:0] tweak_circuit;
  assign tweak_circuit = TweakForward(buf_tweak);

  wire [63:0] tweak_inv_circuit;
  assign tweak_inv_circuit = TweakBackwards(buf_tweak);

  wire [63:0] w0;
  assign w0 = key[127:64];
  wire [63:0] w1;
  assign w1 = { key[64], key[127:66], key[65] ^ key[127] };

  always @(posedge clk)
  begin
    if (!reset_n)
    begin
      state <= STATE_BUSY;
      buf_ready <= 0;

      buf_out <= 0;
      buf_tweak <= tweak;
      buf_in <= in ^ w0;

      buf_round_key <= key[63:0] ^ tweak;
      round <= 0;
    end
    else
    begin
      case (state)
          STATE_BUSY:
          begin
              case (round)
              0: begin
                buf_round_key <= 64'h13198A2E03707344 ^ tweak_circuit ^ key[63:0];
                buf_tweak <= tweak_circuit;
                buf_in <= partial_round_circuit;
              end
              1: begin
                buf_round_key <= 64'hA4093822299F31D0 ^ tweak_circuit ^ key[63:0];
                buf_tweak <= tweak_circuit;
                buf_in <= round_circuit;
              end
              2: begin
                buf_round_key <= 64'h082EFA98EC4E6C89 ^ tweak_circuit ^ key[63:0];
                buf_tweak <= tweak_circuit;
                buf_in <= round_circuit;
              end
              3: begin
                buf_round_key <= 64'h452821E638D01377 ^ tweak_circuit ^ key[63:0];
                buf_tweak <= tweak_circuit;
                buf_in <= round_circuit;
              end
              4: begin
                buf_round_key <= 64'hBE5466CF34E90C6C ^ tweak_circuit ^ key[63:0];
                buf_tweak <= tweak_circuit;
                buf_in <= round_circuit;
              end
              5: begin
                buf_round_key <= 64'h3F84D5B5B5470917 ^ tweak_circuit ^ key[63:0];
                buf_tweak <= tweak_circuit;
                buf_in <= round_circuit;
              end
              6: begin
                buf_round_key <= tweak_circuit ^ w1;
                buf_tweak <= tweak_circuit;
                buf_in <= round_circuit;
              end
              7: begin
                buf_round_key <= key[63:0];
                buf_in <= round_circuit;
              end
              8: begin
                buf_round_key <= buf_tweak ^ w0;
                buf_in <= pseudo_reflect_circuit;
                buf_tweak <= tweak_inv_circuit;
              end
              9: begin
                buf_round_key <= 64'h3F84D5B5B5470917 ^ buf_tweak ^ key[63:0] ^ 64'hC0AC29B7C97C50DD;
                buf_in <= round_inv_circuit;
                buf_tweak <= tweak_inv_circuit;
              end
              10: begin
                buf_round_key <= 64'hBE5466CF34E90C6C ^ buf_tweak ^ key[63:0] ^ 64'hC0AC29B7C97C50DD;
                buf_in <= round_inv_circuit;
                buf_tweak <= tweak_inv_circuit;
              end
              11: begin
                buf_round_key <= 64'h452821E638D01377 ^ buf_tweak ^ key[63:0] ^ 64'hC0AC29B7C97C50DD;
                buf_in <= round_inv_circuit;
                buf_tweak <= tweak_inv_circuit;
              end
              12: begin
                buf_round_key <= 64'h082EFA98EC4E6C89 ^ buf_tweak ^ key[63:0] ^ 64'hC0AC29B7C97C50DD;
                buf_in <= round_inv_circuit;
                buf_tweak <= tweak_inv_circuit;
              end
              13: begin
                buf_round_key <= 64'hA4093822299F31D0 ^ buf_tweak ^ key[63:0] ^ 64'hC0AC29B7C97C50DD;
                buf_in <= round_inv_circuit;
                buf_tweak <= tweak_inv_circuit;
              end
              14: begin
                buf_round_key <= 64'h13198A2E03707344 ^ buf_tweak ^ key[63:0] ^ 64'hC0AC29B7C97C50DD;
                buf_in <= round_inv_circuit;
                buf_tweak <= tweak_inv_circuit;
              end
              15: begin
                buf_round_key <= buf_tweak ^ key[63:0] ^ 64'hC0AC29B7C97C50DD;
                buf_in <= round_inv_circuit;
                buf_tweak <= tweak_inv_circuit;
              end
              16: begin
                buf_in <= partial_round_inv_circuit;
              end
              17: begin
                buf_out <= buf_in ^ w1;

                buf_ready <= 1;
                state <= STATE_IDLE;
              end
              endcase

              round <= round + 1;
          end
      endcase
    end
  end
endmodule
