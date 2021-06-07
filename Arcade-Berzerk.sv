//============================================================================
//  Arcade: Berzerk
//
//  Version for MiSTer
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        VGA_CLK,

	//Multiple resolutions are supported using different VGA_CE rates.
	//Must be based on CLK_VIDEO
	output        VGA_CE,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,

	//Base video clock. Usually equals to CLK_SYS.
	output        HDMI_CLK,

	//Multiple resolutions are supported using different HDMI_CE rates.
	//Must be based on CLK_VIDEO
	output        HDMI_CE,

	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_DE,   // = ~(VBlank | HBlank)
	output  [1:0] HDMI_SL,   // scanlines fx

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] HDMI_ARX,
	output  [7:0] HDMI_ARY,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	
	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT
	
	
);

assign VGA_F1    = 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign HDMI_ARX = status[1] ? 8'd16 : 8'd4;
assign HDMI_ARY = status[1] ? 8'd9  : 8'd3;

`include "build_id.v" 
localparam CONF_STR = {
	"A.BERZERK;;",
	"H0O1,Aspect Ratio,Original,Wide;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"O89,Bonus Life,None,5000,10000,5000 and 10000;",
	"OAB,Language,English,German,French,Spanish;",
	"OC,Cabinet,Upright,Cocktail;",
	"OD,Color Test,Off,On;",
	"OE,Input Test,Off,On;",
	"OF,Crosshair Pattern,Off,On;",
	"OG,Color Mode,Bright,Dark;",
	"-;",
	"R0,Reset;",
	"J1,Fire,Start 1P,Start 2P,Coin;",
	"jn,A,Start,Select,R;",
	"jp,B,Start,Select,R;",
	"V,v",`BUILD_DATE
};

wire [7:0]m_dip_f2 = {status[9:8],1'b0,1'b0,1'b0,1'b0,status[13],status[13]};
wire [7:0]m_dip_f3 = {status[11:10],1'b0,1'b0,1'b0,1'b0,status[15],status[14]};
// dip_switch_1  => x"FF",  -- Coinage_B(7-4) / Cont. play(3) / Fuel consumption(2) / Fuel lost when collision (1-0)
// dip_switch_2  => x"FE",  -- Diag(7) / Demo(6) / Zippy(5) / Freeze (4) / M-Km(3) / Coin mode (2) / Cocktail(1) / Flip(0)

////////////////////   CLOCKS   ///////////////////

wire clk_sys, clk_snd;
wire pll_locked;
wire clk_40,clk_10;
assign clk_sys=clk_40;
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_40),
	.outclk_1(clk_10),
	.locked(pll_locked)
);



///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [10:0] ps2_key;

wire [15:0] joystick_0,joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire [21:0] gamma_bus;


hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.status_menumask(direct_video),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.ps2_key(ps2_key)
);

wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code)
			'hX75: btn_up          <= pressed; // up
			'hX72: btn_down        <= pressed; // down
			'hX6B: btn_left        <= pressed; // left
			'hX74: btn_right       <= pressed; // right
			'h029: btn_fire        <= pressed; // space
			'h014: btn_fire        <= pressed; // ctrl

			'h005: btn_start_1     <= pressed; // F1
			'h006: btn_start_2     <= pressed; // F2
			
			// JPAC/IPAC/MAME Style Codes
			'h016: btn_start_1     <= pressed; // 1
			'h01E: btn_start_2     <= pressed; // 2
			'h02E: btn_coin_1      <= pressed; // 5
			'h036: btn_coin_2      <= pressed; // 6
			'h02D: btn_up_2        <= pressed; // R
			'h02B: btn_down_2      <= pressed; // F
			'h023: btn_left_2      <= pressed; // D
			'h034: btn_right_2     <= pressed; // G
			'h01C: btn_fire_2      <= pressed; // A
		endcase
	end
end

reg btn_up    = 0;
reg btn_down  = 0;
reg btn_right = 0;
reg btn_left  = 0;
reg btn_fire  = 0;

reg btn_start_1=0;
reg btn_start_2=0;
reg btn_coin_1=0;
reg btn_coin_2=0;
reg btn_up_2=0;
reg btn_down_2=0;
reg btn_left_2=0;
reg btn_right_2=0;
reg btn_fire_2=0;

wire m_up     = btn_up    | joy[3];
wire m_down   = btn_down  | joy[2];
wire m_left   = btn_left  | joy[1];
wire m_right  = btn_right | joy[0];
wire m_fire   = btn_fire  | joy[4];

wire m_up_2     = btn_up_2    | joy[3];
wire m_down_2   = btn_down_2  | joy[2];
wire m_left_2   = btn_left_2  | joy[1];
wire m_right_2  = btn_right_2 | joy[0];
wire m_fire_2   = btn_fire_2  | joy[4];

wire m_start1 = btn_start_1 | joystick_0[5];
wire m_start2 = btn_start_1 | joy[6] | joystick_1[6];
wire m_coin   = btn_coin_1  | joy[7];


wire hblank, vblank;
wire hs, vs;
wire r;
wire g;
wire b;

/*
-- adapt video to 4bits/color only
video_r	<= "1100" when r = '1' and hi = '1' else
				"0100" when r = '1' and hi = '0' else
				"0000";
				
video_g	<= "1100" when g = '1' and hi = '1' else
				"0100" when g = '1' and hi = '0' else
				"0000";
				
video_b	<= "1100" when b = '1' and hi = '1' else
				"0100" when b = '1' and hi = '0' else
				"0000";
*/

// the hi wire changes the color
wire video_hi;

wire [2:0] d_video_r = { video_hi? r : 1'b0, r , 1'b0};
wire [2:0] d_video_g = { video_hi? g : 1'b0, g , 1'b0};
wire [2:0] d_video_b = { video_hi? b : 1'b0, b , 1'b0};


// brighter colors?
wire [2:0] b_video_r = { r,video_hi? r : 1'b0, r };
wire [2:0] b_video_g = { g,video_hi? g : 1'b0, g };
wire [2:0] b_video_b = { b,video_hi? b : 1'b0, b };

// select between dark and bright
wire [2:0] video_r = status[16] ? d_video_r : b_video_r;
wire [2:0] video_g = status[16] ? d_video_g : b_video_g;
wire [2:0] video_b = status[16] ? d_video_b : b_video_b;

reg ce_pix;
always @(posedge clk_40) begin
	reg [2:0] div;

	div <= div + 1'd1;
	ce_pix <= !div;
end

wire no_rotate = status[2] | direct_video;

//arcade_video #(260,260,9) arcade_video
arcade_video #(260,260,9) arcade_video
(
	.*,

	.clk_video(clk_40),
	.RGB_in({video_r,video_g,video_b}),

	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),

	.no_rotate(1),
        .rotate_ccw(0),
	.fx(status[5:3])
);


wire [15:0] audio;
assign AUDIO_L =  audio;
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;

 
berzerk berzerk(
	.clock_10(clk_10),
	.clk_sys(clk_sys),
	.reset(RESET | status[0] | buttons[1] | ioctl_download),

	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr),

	

	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_hi(video_hi),
	.video_clk(),
	.video_csync(),
	.video_hs(hs),
	.video_vs(vs),
	.video_hb(hblank),
	.video_vb(vblank),
	.audio_out(audio),  
	.start2(m_start2),
	.start1(m_start1),
	.coin1(m_coin|btn_coin_2),
	.cocktail(status[12]),
	.right1(m_right),
	.left1(m_left),
	.down1(m_down),
	.up1(m_up),
	.fire1(m_fire),
	.right2(m_right_2),
	.left2(m_left_2),		
	.down2(m_down_2),
	.up2(m_up_2),
	.fire2(m_fire_2),
	.dip_f2(m_dip_f2),
	.dip_f3(m_dip_f3),
	
	.ledr(),
	.dbg_cpu_di(),
	.dbg_cpu_addr(),
	.dbg_cpu_addr_latch()
);

endmodule
