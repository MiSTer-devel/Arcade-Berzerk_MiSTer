---------------------------------------------------------------------------------
-- 
-- Arcade: Berzerk Port to MiSTer
-- 24 March 2019
-- 
---------------------------------------------------------------------------------
-- Berzerk FPGA by Dar - (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
-- 
-- Support screen and controls rotation on HDMI output.
-- Only controls are rotated on VGA output.
-- 
-- 
-- Keyboard inputs :
--
--   F2          : Coin + Start 2 players
--   F1          : Coin + Start 1 player
--   UP,DOWN,LEFT,RIGHT arrows : Movements
--   Space,Ctrl  : Fire
--
-- MAME/IPAC/JPAC Style Keyboard inputs:
--   5           : Coin 1
--   6           : Coin 2
--   1           : Start 1 Player
--   2           : Start 2 Players
--   R,F,D,G     : Player 2 Movements
--   A           : Player 2 Fire
--   
-- Joystick support.
-- 
---------------------------------------------------------------------------------




-------------------------------------------------
-- Berzerk FPGA by Dar - (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
-------------------------------------------------
-- Berzerk releases
--
-- Release 0.0 - 07/07/2018 - Dar
-------------------------------------------------
Educational use only
Do not redistribute synthetized file with roms
Do not redistribute roms whatever the form
Use at your own risk
--------------------------------------------------------------------
make sure to use berzerk.zip roms 
--------------------------------------------------------------------
--
-- Main features :
--  PS2 keyboard input @gpio pins 35/34 (beware voltage translation/protection) 
--  Audio pwm output   @gpio pins 1/3 (beware voltage translation/protection) 
--
-- Uses 1 pll for 10MHz generation from 50MHz
--
-- Board key :
--   0 : reset game
--
-- Board switch :
--	  1 : tv 15Khz mode / VGA 640x480 mode
--
-- Keyboard players inputs :
--
--   F3 : Add coin
--   F2 : Start 2 players
--   F1 : Start 1 player
--   SPACE       : fire
--   RIGHT arrow : move right
--   LEFT  arrow : move left
--   UP    arrow : move up 
--   DOWN  arrow : move down
--
-- Sound effects : OK
-- Speech synthesis : todo 
--
---------------
VHDL File list 
---------------

max10_pll_10M.vhd       Pll 10MHz from 50MHz altera mf

berzerk_de10_lite.vhd   Top level for de10-lite board
berzerk.vhd             Main logic
berzerk_sound_fx.vhd    Music logic
berzerk_program1.vhd
berzerk_program2.vhd

video_gen.vhd           Video scheduler, syncs (h,v and composite)
line_doubler.vhd        Line doubler 15kHz -> 31kHz VGA

kbd_joystick.vhd        Keyboard key to player/coin input

T80se.vhd               T80 release 304  
T80_Reg.vhd
T80_Pack.vhd
T80_MCode.vhd
T80_ALU.vhd
T80.vhd

io_ps2_keyboard.vhd     Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
gen_ram.vhd

decodeur_7_seg.vhd      for debug

----------------------
Quartus project files
----------------------
de10_lite/berzerk_de10_lite.qsf   de10_lite settings (files,pins,...)
de10_lite/berzerk_de10_lite.qpf   de10_lite project
de10_lite/berzerk_de10_lite.sdc   timequest constraints


+----------------------------------------------------------------------------------+
; Fitter Summary                                                                   ;
+------------------------------------+---------------------------------------------+
; Fitter Status                      ; Successful - Sat Jul 07 07:38:44 2018       ;
; Quartus Prime Version              ; 16.1.0 Build 196 10/24/2016 SJ Lite Edition ;
; Revision Name                      ; berzerk_de10_lite                           ;
; Top-level Entity Name              ; berzerk_de10_lite                           ;
; Family                             ; MAX 10                                      ;
; Device                             ; 10M50DAF484C6GES                            ;
; Timing Models                      ; Preliminary                                 ;
; Total logic elements               ; 3,277 / 49,760 ( 7 % )                      ;
;     Total combinational functions  ; 3,043 / 49,760 ( 6 % )                      ;
;     Dedicated logic registers      ; 886 / 49,760 ( 2 % )                        ;
; Total registers                    ; 886                                         ;
; Total pins                         ; 121 / 360 ( 34 % )                          ;
; Total virtual pins                 ; 0                                           ;
; Total memory bits                  ; 241,664 / 1,677,312 ( 14 % )                ;
; Embedded Multiplier 9-bit elements ; 0 / 288 ( 0 % )                             ;
; Total PLLs                         ; 1 / 4 ( 25 % )                              ;
; UFM blocks                         ; 0 / 1 ( 0 % )                               ;
; ADC blocks                         ; 0 / 2 ( 0 % )                               ;
+------------------------------------+---------------------------------------------+
-----------------------------
Required ROMs (Not included)
-----------------------------

                                *** Attention ***

ROMs are not included. In order to use this arcade, you need to provide the
correct ROMs.

To simplify the process .mra files are provided in the releases folder, that
specifies the required ROMs with checksums. The ROMs .zip filename refers to the
corresponding file of the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for
information on how to setup and use the environment.

Quickreference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/_Arcade/mame/<mame rom>.zip
/_Arcade/hbmame/<hbmame rom>.zip

---------------------------------
Compiling for de10_lite
---------------------------------
You can rebuild the project with ROM image embeded in the sof file. DO NOT REDISTRIBUTE THESE FILES.
4 steps

 - put the VHDL rom files into the project directory
 - rebuild berzerk_de10_lite
 - program berzerk_de10_lite.sof into the fpga 

------------------------
End of file
------------------------
