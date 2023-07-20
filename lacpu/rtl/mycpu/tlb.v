module tlb
(
  input clk,

  //search port 1
  input       [12:0]  s0_vppn,
  input       [9:0]   s0_asid,
  input               s0_odd,
  output  reg [11:0]  s0_ppn,
  output  reg [3:0]   s0_index,
  output  reg         s0_found,
  //search port 2
  input       [12:0]  s1_vppn,
  input       [9:0]   s1_asid,
  input               s1_odd,
  output  reg [11:0]  s1_ppn,
  output  reg [3:0]   s1_index,
  output  reg         s1_found,

  //read port
  input   [3:0]   r_index,
  output  [12:0]  r_vppn,
  output  [5:0]   r_ps,
  output          r_g,
  output  [9:0]   r_asid,
  output          r_e,
  output  [11:0]  r_ppn0,
  output  [1:0]   r_plv0,
  output  [1:0]   r_mat0,
  output          r_d0,
  output          r_v0,
  output  [11:0]  r_ppn1,
  output  [1:0]   r_plv1,
  output  [1:0]   r_mat1,
  output          r_d1,
  output          r_v1, 


  //write port
  input           we,
  input   [3:0]   w_index,
  input   [12:0]  w_vppn,
  input   [5:0]   w_ps,
  input           w_g,
  input   [9:0]   w_asid,
  input           w_e,
  input   [11:0]  w_ppn0,
  input   [1:0]   w_plv0,
  input   [1:0]   w_mat0,
  input           w_d0,
  input           w_v0,
  input   [11:0]  w_ppn1,
  input   [1:0]   w_plv1,
  input   [1:0]   w_mat1,
  input           w_d1,
  input           w_v1

);

reg   [12:0]  tlb_vppn  [0:15];
reg   [5:0]   tlb_ps    [0:15];
reg           tlb_g     [0:15];
reg   [9:0]   tlb_asid  [0:15];
reg           tlb_e     [0:15];
reg   [11:0]  tlb_ppn0  [0:15];
reg   [1:0]   tlb_plv0  [0:15];
reg   [1:0]   tlb_mat0  [0:15];
reg           tlb_d0    [0:15];
reg           tlb_v0    [0:15];
reg   [11:0]  tlb_ppn1  [0:15];
reg   [1:0]   tlb_plv1  [0:15];
reg   [1:0]   tlb_mat1  [0:15];
reg           tlb_d1    [0:15];
reg           tlb_v1    [0:15];


//search 
integer i;
reg match0 [0:15];
reg match1 [0:15];
always @(*) begin 
  for(i = 0; i < 16; i++) begin 
    match0[i] = (s0_vppn == tlb_vppn[i]) && ((s0_asid == tlb_asid[i]) || tlb_g[i]);
    match1[i] = (s1_vppn == tlb_vppn[i]) && ((s1_asid == tlb_asid[i]) || tlb_g[i]);
  end
end

always @(*) begin 
  s0_found = match0[0];
  s1_found = match1[0];
  for(i = 1; i < 16; i++) begin 
    s0_found = match0[i] || s0_found;
    s1_found = match1[i] || s1_found;
  end
end

always @(*) begin 
  case (1'b1)
    match0[0]:  begin s0_ppn = s0_odd ? tlb_ppn0[0] : tlb_ppn1[0];   s0_index = 4'd0;  end
    match0[1]:  begin s0_ppn = s0_odd ? tlb_ppn0[1] : tlb_ppn1[1];   s0_index = 4'd1;  end
    match0[2]:  begin s0_ppn = s0_odd ? tlb_ppn0[2] : tlb_ppn1[2];   s0_index = 4'd2;  end
    match0[3]:  begin s0_ppn = s0_odd ? tlb_ppn0[3] : tlb_ppn1[3];   s0_index = 4'd3;  end
    match0[4]:  begin s0_ppn = s0_odd ? tlb_ppn0[4] : tlb_ppn1[4];   s0_index = 4'd4;  end
    match0[5]:  begin s0_ppn = s0_odd ? tlb_ppn0[5] : tlb_ppn1[5];   s0_index = 4'd5;  end
    match0[6]:  begin s0_ppn = s0_odd ? tlb_ppn0[6] : tlb_ppn1[6];   s0_index = 4'd6;  end
    match0[7]:  begin s0_ppn = s0_odd ? tlb_ppn0[7] : tlb_ppn1[7];   s0_index = 4'd7;  end
    match0[8]:  begin s0_ppn = s0_odd ? tlb_ppn0[8] : tlb_ppn1[8];   s0_index = 4'd8;  end
    match0[9]:  begin s0_ppn = s0_odd ? tlb_ppn0[9] : tlb_ppn1[9];   s0_index = 4'd9;  end
    match0[10]: begin s0_ppn = s0_odd ? tlb_ppn0[10] : tlb_ppn1[10];  s0_index = 4'd10; end
    match0[11]: begin s0_ppn = s0_odd ? tlb_ppn0[11] : tlb_ppn1[11];  s0_index = 4'd11; end
    match0[12]: begin s0_ppn = s0_odd ? tlb_ppn0[12] : tlb_ppn1[12];  s0_index = 4'd12; end
    match0[13]: begin s0_ppn = s0_odd ? tlb_ppn0[13] : tlb_ppn1[13];  s0_index = 4'd13; end
    match0[14]: begin s0_ppn = s0_odd ? tlb_ppn0[14] : tlb_ppn1[14];  s0_index = 4'd14; end
    match0[15]: begin s0_ppn = s0_odd ? tlb_ppn0[15] : tlb_ppn1[15];  s0_index = 4'd15; end
  default: begin
    s0_ppn = 12'b0;
    s0_index = 4'd0;
  end
  endcase

  case (1'b1)
    match1[0]:  begin s1_ppn = s1_odd ? tlb_ppn0[0] : tlb_ppn1[0];   s1_index = 4'd0;  end
    match1[1]:  begin s1_ppn = s1_odd ? tlb_ppn0[1] : tlb_ppn1[1];   s1_index = 4'd1;  end
    match1[2]:  begin s1_ppn = s1_odd ? tlb_ppn0[2] : tlb_ppn1[2];   s1_index = 4'd2;  end
    match1[3]:  begin s1_ppn = s1_odd ? tlb_ppn0[3] : tlb_ppn1[3];   s1_index = 4'd3;  end
    match1[4]:  begin s1_ppn = s1_odd ? tlb_ppn0[4] : tlb_ppn1[4];   s1_index = 4'd4;  end
    match1[5]:  begin s1_ppn = s1_odd ? tlb_ppn0[5] : tlb_ppn1[5];   s1_index = 4'd5;  end
    match1[6]:  begin s1_ppn = s1_odd ? tlb_ppn0[6] : tlb_ppn1[6];   s1_index = 4'd6;  end
    match1[7]:  begin s1_ppn = s1_odd ? tlb_ppn0[7] : tlb_ppn1[7];   s1_index = 4'd7;  end
    match1[8]:  begin s1_ppn = s1_odd ? tlb_ppn0[8] : tlb_ppn1[8];   s1_index = 4'd8;  end
    match1[9]:  begin s1_ppn = s1_odd ? tlb_ppn0[9] : tlb_ppn1[9];   s1_index = 4'd9;  end
    match1[10]: begin s1_ppn = s1_odd ? tlb_ppn0[10] : tlb_ppn1[10];  s1_index = 4'd10; end
    match1[11]: begin s1_ppn = s1_odd ? tlb_ppn0[11] : tlb_ppn1[11];  s1_index = 4'd11; end
    match1[12]: begin s1_ppn = s1_odd ? tlb_ppn0[12] : tlb_ppn1[12];  s1_index = 4'd12; end
    match1[13]: begin s1_ppn = s1_odd ? tlb_ppn0[13] : tlb_ppn1[13];  s1_index = 4'd13; end
    match1[14]: begin s1_ppn = s1_odd ? tlb_ppn0[14] : tlb_ppn1[14];  s1_index = 4'd14; end
    match1[15]: begin s1_ppn = s1_odd ? tlb_ppn0[15] : tlb_ppn1[15];  s1_index = 4'd15; end
  default: begin
    s1_ppn = 12'b0;
  end
  endcase
end

//read 
assign r_vppn = (we && w_index == r_index) ? w_vppn : tlb_vppn[r_index];
assign r_ps   = (we && w_index == r_index) ? w_ps : tlb_ps[r_index];
assign r_g    = (we && w_index == r_index) ? w_g : tlb_g[r_index];
assign r_asid = (we && w_index == r_index) ? w_asid : tlb_asid[r_index];
assign r_e    = (we && w_index == r_index) ? w_e : tlb_e[r_index];
assign r_ppn0 = (we && w_index == r_index) ? w_ppn0 : tlb_ppn0[r_index];
assign r_plv0 = (we && w_index == r_index) ? w_plv0 : tlb_plv0[r_index];
assign r_mat0 = (we && w_index == r_index) ? w_mat0 : tlb_mat0[r_index];
assign r_d0   = (we && w_index == r_index) ? w_d0 : tlb_d0[r_index];
assign r_v0   = (we && w_index == r_index) ? w_v0 : tlb_v0[r_index];
assign r_ppn1 = (we && w_index == r_index) ? w_ppn1 : tlb_ppn1[r_index];
assign r_plv1 = (we && w_index == r_index) ? w_plv1 : tlb_plv1[r_index];
assign r_mat1 = (we && w_index == r_index) ? w_mat1 : tlb_mat1[r_index];
assign r_d1   = (we && w_index == r_index) ? w_d1 : tlb_d1[r_index];
assign r_v1   = (we && w_index == r_index) ? w_v1 : tlb_v1[r_index];

//write
always @(posedge clk) begin 
  if(we) begin 
    tlb_vppn[w_index] <= w_vppn;
    tlb_ps[w_index]   <= w_ps;
    tlb_g[w_index]    <= w_g;
    tlb_asid[w_index] <= w_asid;
    tlb_e[w_index]    <= w_e;
    tlb_ppn0[w_index] <= w_ppn0;
    tlb_plv0[w_index] <= w_plv0;
    tlb_mat0[w_index] <= w_mat0;
    tlb_d0[w_index]   <= w_d0;
    tlb_v0[w_index]   <= w_v0;
    tlb_ppn1[w_index] <= w_ppn1;
    tlb_plv1[w_index] <= w_plv1;
    tlb_mat1[w_index] <= w_mat1;
    tlb_d1[w_index]   <= w_d1;
    tlb_v1[w_index]   <= w_v1;
  end
end

endmodule
