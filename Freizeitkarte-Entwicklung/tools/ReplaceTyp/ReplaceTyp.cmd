@echo off
setlocal enabledelayedexpansion
if "%~1"=="" goto error

:: check the existence of gmaptool
if not exist %~dps0gmt.exe goto error

:again
echo Select the desired TYP file:

:: replace these with your own (and add as many as you want)
echo A: freizeit - standard design of all Freizeitkarten project maps
echo B: outdoor - design based on "Top50" and "ICAO" maps
echo C: outdoor-light - no symbols on the areas included
echo D: contrast - colors are "stronger" in compare to "freizeit"
echo E: small - optimized for GPS devices with small displays
echo F: outdoor-contrast - similar to contrast, no symbols in areas
echo Q: Quit
echo.

:: edit this too to match the number of options
set /p userinp=Enter your choice (A-F, Q):
set userinp=%userinp:~0,1%

:: match the options above; use the typ file names here
if /i "%userinp%"=="A" set typfile=freizeit.TYP
if /i "%userinp%"=="B" set typfile=outdoor.TYP
if /i "%userinp%"=="C" set typfile=outdoorl.TYP
if /i "%userinp%"=="D" set typfile=contrast.TYP
if /i "%userinp%"=="E" set typfile=small.TYP
if /i "%userinp%"=="F" set typfile=outdoorc.TYP
if /i "%userinp%"=="Q" goto end
if "%typfile%"=="" goto again

:: check the existence of the chosen typ file
if not exist %~dps0%typfile% goto error

:: find FID of map in IMG file
for /f "tokens=5 delims=, " %%G in ('%~dps0gmt.exe -i "%~1"^|findstr /c:", FID "') do set mapfid=%%G
echo.
echo.
echo Family ID of this map: %mapfid%
echo.
echo.

:: change FID of TYP file
%~dps0gmt.exe -w -y %mapfid% %~dps0%typfile%

:: add TYP file to IMG file
%~dps0gmt.exe -w -x %~dps0%typfile% "%~1"

echo.
echo.
echo .typ file in %~n1%~x1 is replaced by %typfile%
goto end

:error
echo.
echo.
echo Prerequisite:
echo.
echo Keep the files ReplaceTyp.cmd, gmt.exe and the .typ files
echo together in the same folder.
echo.
echo Usage:
echo.
echo Drag the gmapsupp.img file to the icon of ReplaceTyp.cmd
echo and select the .typ file you want to use.

:end
echo.
echo.
pause
