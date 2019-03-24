@echo off

set    zip=berzerk.zip
set ifiles=berzerk_rc31_1d.rom1.1d+berzerk_rc31_3d.rom2.3d+berzerk_rc31_5d.rom3.5d+berzerk_rc31_6d.rom4.6d+berzerk_rc31_5c.rom5.5c+berzerk_rc31_5c.rom5.5c+berzerk_rc31_5c.rom5.5c+berzerk_rc31_5c.rom5.5c+berzerk_rc31_1c.rom0.1c+berzerk_rc31_1c.rom0.1c+berzerk_r_vo_1c.1c+berzerk_r_vo_2c.2c
set  ofile=a.berzerk.rom

rem =====================================
setlocal ENABLEDELAYEDEXPANSION

set pwd=%~dp0
echo.
echo.

if EXIST %zip% (

	!pwd!7za x -otmp %zip%
	if !ERRORLEVEL! EQU 0 ( 
		cd tmp

		copy /b/y %ifiles% !pwd!%ofile%
		if !ERRORLEVEL! EQU 0 ( 
			echo.
			echo ** done **
			echo.
			echo Copy "%ofile%" into root of SD card
		)
		cd !pwd!
		rmdir /s /q tmp
	)

) else (

	echo Error: Cannot find "%zip%" file
	echo.
	echo Put "%zip%", "7za.exe" and "%~nx0" into the same directory
)

echo.
echo.
pause
