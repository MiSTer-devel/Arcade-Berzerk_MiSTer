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
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;

assign VGA_F1    = 0;
assign VGA_SCALER =0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign AUDIO_MIX = 0;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

wire [1:0] ar = status[15:14];

assign VIDEO_ARX =  (!ar) ? ( 8'd4) : (ar - 1'd1);
assign VIDEO_ARY =  (!ar) ? ( 8'd3) : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
	"A.BERZERK;;",
	"H0OEF,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;", 
	"O89,Bonus Life,None,5000,10000,5000 and 10000;",
	"OAB,Language,English,German,French,Spanish;",
	"OC,Cabinet,Upright,Cocktail;",
	"OD,Color Test,Off,On;",
	"OH,Input Test,Off,On;",
	"OI,Crosshair Pattern,Off,On;",
	"OG,Color Mode,Bright,Dark;",
	"OR,Autosave Hiscores,Off,On;",
	"P1,Pause options;",
	"P1OP,Pause when OSD is open,On,Off;",
	"P1OQ,Dim video after 10s,On,Off;",
	"-;",
	"R0,Reset;",
	"J1,Fire,Start 1P,Start 2P,Coin,Pause;",
	"jn,A,Start,Select,R,L;",
	"V,v",`BUILD_DATE
};

wire [7:0]m_dip_f2 = {status[9:8],1'b0,1'b0,1'b0,1'b0,status[13],status[13]};
wire [7:0]m_dip_f3 = {status[11:10],1'b0,1'b0,1'b0,1'b0,status[18],status[17]};
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
wire        ioctl_upload;
wire        ioctl_upload_req;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;
wire  [7:0] ioctl_index;
wire        ioctl_wait;

wire [10:0] ps2_key;

wire [15:0] joystick_0,joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire [21:0] gamma_bus;


hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),

	.buttons(buttons),
	.status(status),
	.status_menumask(direct_video),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),
	.ioctl_wait(ioctl_wait),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1)
);


wire m_up     = joy[3];
wire m_down   = joy[2];
wire m_left   = joy[1];
wire m_right  = joy[0];
wire m_fire   = joy[4];

wire m_up_2     = joy[3];
wire m_down_2   = joy[2];
wire m_left_2   = joy[1];
wire m_right_2  = joy[0];
wire m_fire_2   = joy[4];

wire m_start1 = joy[5];
wire m_start2 = joy[6];
wire m_coin   = joy[7];
wire m_pause  = joy[8];

// PAUSE SYSTEM
wire				pause_cpu;
wire [8:0]		rgb_out;
pause #(3,3,3,40) pause (
	.*,
	.r(video_r),
	.g(video_g),
	.b(video_b),
	.user_button(m_pause),
	.pause_request(hs_pause),
	.options(~status[26:25])
);

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

//wire no_rotate = status[2] | direct_video;

arcade_video #(260,9) arcade_video
(
	.*,

	.clk_video(clk_40),
	.RGB_in(rgb_out),

	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),

	.fx(status[5:3])
);


wire [15:0] audio;
assign AUDIO_L = pause_cpu ? 16'b0 : audio;
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;

wire reset = RESET | status[0] | buttons[1] | ioctl_download;
wire rom_download = ioctl_download && !ioctl_index;
 
berzerk berzerk(
	.clock_10(clk_10),
	.clk_sys(clk_sys),
	.reset(reset),

	.pause(pause_cpu),

	.dn_addr(ioctl_download ? ioctl_addr[15:0] : hs_address),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr & rom_download),
	.dn_nvram_wr(ioctl_wr & (ioctl_index == 8'd4)), 
	.dn_din(hs_data_out),
	.dn_nvram(ioctl_index == 8'd4),

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
	.coin1(m_coin),
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
	//.dbg_cpu_di(),
	.dbg_cpu_addr(),
	.dbg_cpu_addr_latch()
);

// HISCORE SYSTEM
// --------------
wire [9:0] hs_address;
wire [7:0] hs_data_out;
wire hs_pause;

nvram #(
	.DUMPWIDTH(10),
	.CONFIGINDEX(3),
	.DUMPINDEX(4),
	.PAUSEPAD(2)
) hi (
	.*,
	.clk(clk_sys),
	.paused(pause_cpu),
	.autosave(status[27]),
	.nvram_address(hs_address),
	.nvram_data_out(hs_data_out),
	.pause_cpu(hs_pause)
);

endmodule
