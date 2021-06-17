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
  reg [16:0] round;

  reg [63:0] buf_tweak;
  reg [63:0] buf_out;
  reg [63:0] buf_in;

  assign out = buf_out;
  assign ready = state == STATE_IDLE;

  function [3:0] Sbox (input [3:0] x);
  begin
    /*
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
    */
    Sbox = {
      ~((x[3] | ~x[0]) & ~(~(x[1] & x[3]) & x[2])),
      ((x[1] ^ x[0]) | (x[1] ^ x[3])) ^ x[1],
      ~(~(x[1] & ~x[2]) & ~((x[3] ^ x[0]) & ~(x[3] & x[2]))),
      ~((x[3] ^ x[1]) | ~(x[1] | x[2])) | ((x[0] ^ x[3]) & x[2])
    };
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

  function [3:0] LfsrForward (input [3:0] nibble);
  begin
    LfsrForward = { nibble[0] ^ nibble[1], nibble[3], nibble[2], nibble[1] };
  end
  endfunction

  function [3:0] LfsrBackwards (input [3:0] nibble);
  begin
    LfsrBackwards = { nibble[2], nibble[1], nibble[0], nibble[0] ^ nibble[3] };
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

  // Shared SubCells circuitry.
  /*
  wire [63:0] sub_cells_circuit_in;
  wire [63:0] sub_cells_circuit;

  assign sub_cells_circuit_in =
    is_fwd ? round_forward_step2 : // rounds using RoundForward
    is_bwd ? buf_in :              // rounds using RoundBackward
    0;
  assign sub_cells_circuit = SubCells(sub_cells_circuit_in);
  */
  // Shared ShuffleCellsBackwards+MixColumns+ShuffleCells circuitry.
  wire [63:0] shared_circuit_in;
  wire [63:0] shared_circuit;

  wire is_fwd;
  assign is_fwd = (tmp == 0);
    /* round[0] | round[1] | round[2] | round[3] | 
    round[4] | round[5] | round[6] | round[7]; */

  wire is_bwd;
  assign is_bwd = (tmp2 == 0);
  /*
    round[ 9] | round[10] | round[11] | round[12] | 
    round[13] | round[14] | round[15] | round[16];
  */
  assign shared_circuit_in =
    is_fwd ? round_forward_step1 :     // rounds using RoundForward
    is_bwd ? round_inv_circuit_step0 : // rounds using RoundBackward
    buf_in;                            // PseudoReflect

  wire [63:0] shared_circuit_step0 = (is_fwd || round[8]) ? ShuffleCells(shared_circuit_in) : shared_circuit_in;
  wire [63:0] shared_circuit_step1 = MixColumns(shared_circuit_step0);
  wire [63:0] shared_circuit_step2 = round[8] ? (shared_circuit_step1 ^ k1) : shared_circuit_step1;
  assign shared_circuit = (is_bwd || round[8]) ? ShuffleCellsBackwards(shared_circuit_step2) : shared_circuit_step2;

  // RoundForward
  wire [63:0] round_forward_round_key = round[7] ? (buf_tweak ^ w1) : (k0 ^ round_key ^ buf_tweak);
  wire [63:0] round_forward_step1 = buf_in ^ round_forward_round_key;
  wire [63:0] round_forward_step2 = round[0] ? round_forward_step1 : shared_circuit; // MixColumns(ShuffleCells(round_forward_step1));
  wire [63:0] round_circuit;
  assign round_circuit = SubCells(round_forward_step2); // sub_cells_circuit; // 

  // RoundBackwards
  wire [63:0] round_reverse_round_key = round[9] ? (buf_tweak ^ w0) : (k1 ^ round_key ^ buf_tweak ^ 64'hC0AC29B7C97C50DD);
  wire [63:0] round_inv_circuit_step0 = SubCells(buf_in); // sub_cells_circuit; // 
  wire [63:0] round_inv_circuit_step1 = round[16] ? round_inv_circuit_step0 : shared_circuit; //ShuffleCellsBackwards(MixColumns(round_inv_circuit_step0));
  wire [63:0] round_inv_circuit;
  assign round_inv_circuit = round_inv_circuit_step1 ^ round_reverse_round_key;

  // PseudoReflect
  wire [63:0] pseudo_reflect_circuit;
  assign pseudo_reflect_circuit = shared_circuit; //ShuffleCellsBackwards(MixColumns(ShuffleCells(buf_in)) ^ k1);

  // TweakForward
  wire [63:0] tweak_circuit;
  assign tweak_circuit = TweakForward(buf_tweak);

  // TweakBackwards
  wire [63:0] tweak_inv_circuit;
  assign tweak_inv_circuit = TweakBackwards(buf_tweak);

  wire [63:0] w0;
  assign w0 = key[127:64];
  wire [63:0] w1;
  assign w1 = { key[64], key[127:66], key[65] ^ key[127] }; // w0 ^ ROTL64(w0, 1)

  wire [63:0] k0;
  assign k0 = key[63:0];
  wire [63:0] k1;
  assign k1 = key[63:0];

  reg tmp;
  reg tmp2;

  wire [63:0] round_key;
  assign round_key =
    (round[1] || round[15]) ? 64'h13198A2E03707344 :
    (round[2] || round[14]) ? 64'hA4093822299F31D0 :
    (round[3] || round[13]) ? 64'h082EFA98EC4E6C89 :
    (round[4] || round[12]) ? 64'h452821E638D01377 :
    (round[5] || round[11]) ? 64'hBE5466CF34E90C6C :
    (round[6] || round[10]) ? 64'h3F84D5B5B5470917 :
    0;

  always @(posedge clk)
  begin
    if (!reset_n)
    begin
      state <= STATE_BUSY;

      buf_out <= 0;
      buf_tweak <= tweak;
      buf_in <= in ^ w0;

      round <= 1;
      tmp <= 0;
      tmp2 <= 1;
    end
    else
    begin
      case (state)
          STATE_BUSY:
          begin
              if (tmp == 0) begin
                if (!round[7])
                  buf_tweak <= tweak_circuit;
                buf_in <= round_circuit;
              end
              if (tmp2 == 0) begin
                buf_in <= round_inv_circuit;
                buf_tweak <= tweak_inv_circuit;
              end

              if (round[7]) begin
                tmp <= 1;
              end
              if (round[8]) begin
                buf_in <= pseudo_reflect_circuit;
                tmp2 <= 0;
              end
              if (round[16]) begin
                buf_out <= round_inv_circuit ^ w1;
                state <= STATE_IDLE;
              end

              round <= round << 1;
          end
      endcase
    end
  end
endmodule
