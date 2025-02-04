@echo off
setlocal enabledelayedexpansion
title SysInfo
:: config

:: Webhook that the data is set to
set WEBHOOK_URL="Webhook URL Here"

:: Change if bundling the program with curl
set curl_dir="curl"

::USERNAMES
:: Change to false to disable usernames
set enableusernames=true

:: True sets the username to the username of the logged in user (only applies when enableusernames is true)
set usernameisaccountname=true

:: TIME INFO
::true collects timeinformation about the system (time, date and timezone. Doesn't include boottime)
set collectsystemtimeinfo=true

:: True collects the boot time
set collectboottime=true


:: Display a consent message to the user
echo This script will collect information about your system (such as CPU, RAM, GPU, etc.) and send it to a remote server. 
echo Do you consent to sharing this information? (Y/N)

:: Ask for user input
set /p userConsent="Enter Y to consent or N to decline: "

:: Check if the user consents
if /i "%userConsent%"=="Y" (
    cls
    echo You have consented to share your system information.

::checks if usernames are enabled
    if /i "%enableusernames%"=="true" (
        if /i "%usernameisaccountname%"=="true" (
            :: Sets the selected username to the logged in account's username
            set selectedusername=!username!'s
            :: Collects system information
            goto collectinfo
        ) else (
            :: Proceed to username consent
            goto usernameconsent
        )
    ) else (
        :: Makes the selected username blank
        set selectedusername=
        :: Collects system information
        goto collectinfo

    )
) else (
    cls
    echo You have declined to share your system information. The script will now exit.
   pause
   exit
)
:usernameconsent
:: Checks if the user wants a username
echo Would you like to add a username? (Y/N)
set /p usernameConsent="Enter Y or N to decline: "
if /i "%usernameConsent%"=="Y" (
    goto usernameselection
) else (
    cls
    :: Sets the username to anonymous
    set selectedusername="Anonymous'"
    echo You have declined to add a username.
    :: Proceed with collecting system information
   goto collectinfo
)
:usernameselection
cls
echo What would you like your username to be? (leave blank for no username)
set /p selectedusername="Username: "
if /i "%selectedusername%"=="" (
    cls
    :: Sets the username to anonymous
    set selectedusername="Anonymous'"
    echo Your username has been reset
    :: Proceed with collecting system information
    goto collectinfo
) else (
    cls
    echo Your username is !selectedusername!
    echo Is this correct? Y/N
    set /p usernameconsent="Enter Y or N to confirm: "
    if /i "%usernameconsent%"=="Y" (
    set selectedusername=%selectedusername%'s
    cls
    :: Proceed with collecting system information
    goto collectinfo
) else (
    cls
    set selectedusername=
    goto usernameselection
)
)
:collectinfo
echo Collecting System Information
set "infoindex=-1"
:infoindex
set /a infoindex+=1
goto !infoindex!
:0
for /f "skip=1 delims=" %%a in ('wmic os get Caption') do (
    set "version=%%a"
    goto infoindex
)
:1
for /f "skip=1 delims=" %%a in ('wmic cpu get name') do (
    set "cpuname=%%a"
    goto infoindex
)
:2
for /f "skip=1 delims=" %%a in ('wmic cpu get numberofcores') do (
    set "cpucores=%%a"
    goto infoindex
)
:3
for /f "skip=1 delims=" %%a in ('wmic cpu get threadcount') do (
    set "cputhreads=%%a"
    goto infoindex
)
:4
set "gpuinfo="
:: Loop through each line of output from wmic
for /f "skip=1 delims=" %%a in ('wmic path win32_VideoController get name 2^>nul') do (
    set "line=%%a"
    :: Remove leading and trailing spaces from each line
    for /f "tokens=* delims=" %%b in ("!line!") do (
        if not "%%b"=="" (
            :: Append each entry to gpuinfo
            if defined gpuinfo (
                set "gpuinfo=!gpuinfo!, %%b"
            ) else (
                set "gpuinfo=%%b"
            )
        )
    )
)
    goto infoindex
:5
:: Get the value from wmic and assign to the variable in batch
for /f "tokens=2 delims==" %%a in ('wmic computersystem get TotalPhysicalMemory /value') do set "totalMemory=%%a"

:: Now, use PowerShell to divide the memory by 1073741824 (1GB)
for /f "tokens=* delims=" %%b in ('powershell -command "[math]::Round(%totalMemory% / 1073741824, 2)"') do set ram=%%b
goto infoindex
:6
for /f "skip=1 delims=" %%a in ('wmic memphysical get MemoryDevices') do (
    set "ramsticks=%%a"
    goto infoindex
)
:7
for /f "skip=1 delims=" %%a in ('wmic computersystem get model') do (
    set "motherboard=%%a"
    goto infoindex
)
:8
for /f "skip=1 delims=" %%a in ('wmic computersystem get manufacturer') do (
    set "vendor=%%a"
    goto infoindex
)
:9
for /f "skip=1 delims=" %%a in ('wmic bios get manufacturer') do (
    set "biosvendor=%%a"
    goto infoindex
)
:10
for /f "skip=1 delims=" %%a in ('wmic bios get SMBIOSBIOSVERSION') do (
    set "biosversion=%%a"
    goto infoindex
)
:11
for /f "skip=1 delims=" %%a in ('wmic os get OsArchitecture') do (
    set "architecture=%%a"
    goto infoindex
)
:12
for /f "skip=1 delims=" %%a in ('wmic os get version') do (
    set "detailedversion=%%a"
    goto infoindex
)
:13
for /f "skip=1 delims=" %%a in ('wmic MemoryChip get Speed') do (
    set "ramspeed=%%a"
    goto infoindex
)
:14
for /f "skip=1" %%i in ('wmic MemoryChip get SMBIOSMemoryType') do (
    set "memType=%%i"
    goto infoindex
)
:15
::Translate the memory type to DDR version
for /f "tokens=4,5 delims=,. "  %%a in ('ver') do set "build_n=%%a.%%b"
::Avoids script error if memtype is blank
if "%memtype%"=="" ( 
    set "ddrVersion="
    goto infoindex
)
if %memType%==27 (
    set "ddrVersion=DDR5"
    goto infoindex
)
if %memType%==34 (
    set "ddrVersion=DDR5"
    goto infoindex
)
if %memType%==26 (
    set "ddrVersion=DDR4"
    goto infoindex)
if %memType%==24 (
    set "ddrVersion=DDR3"
    goto infoindex
)
if %memType%==21 (
set "ddrVersion=DDR2"
goto infoindex
)
if %memType%==20 (
    set "ddrVersion=DDR"
    goto infoindex
)
set "ddrVersion=Unknown DDR Version"
goto infoindex
:16
for /f "skip=1 delims=" %%a in ('wmic diskdrive get model 2^>nul') do (
    set "line=%%a"
    :: Remove leading and trailing spaces from each line
    for /f "tokens=* delims=" %%b in ("!line!") do (
        if not "%%b"=="" (
            :: Append each entry to DriveModel
            if defined DriveModel (
                set "DriveModel=!DriveModel!, %%b"
            ) else (
                set "DriveModel=%%b"
            )
        )
    )
)
goto infoindex
:17
for /f "skip=1 delims=" %%a in ('wmic diskdrive get size 2^>nul') do (
    set "line=%%a"
    :: Remove leading and trailing spaces from each line
    for /f "tokens=* delims=" %%b in ("!line!") do (
        if not "%%b"=="" (
            :: Append each entry to DriveCapacity
            if defined DriveCapacity (
                set "DriveCapacity=!DriveCapacity!, %%bBytes"
            ) else (
                set "DriveCapacity=%%bBytes"
            )
        )
    )
)
goto infoindex
:18
for /f "tokens=3,*" %%A in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v DisplayVersion 2^>nul') do set DisplayVersion=%%A
:19
if !collectsystemtimeinfo!==true (
for /f "skip=1 delims=" %%a in ('wmic timezone get caption') do (
    set "Timeinfo=### Time:\n**System Date:** %date%\n**System Time:** %time%\n**Timezone:** %%a\n"
    goto infoindex
)

) else (
    set "Timeinfo="
    goto infoindex
)

:20
:: Create a temporary file to store systeminfo output
set tempFile=%temp%\sysinfotemp%RANDOM%
systeminfo > "%tempFile%" 2>nul

:: Extract only the System Boot Time
for /f "tokens=2,*" %%A in ('findstr /c:"System Boot Time" "%tempFile%"') do set BootTime=%%B
set BootTime=%BootTime:~5%
:: Clean up temporary file
del "%tempFile%" >nul 2>&1
goto infoindex
:21
:: Work around for if statements messing up the Boot Time function
if !collectboottime!==true (
    set "BootTimeVar=\n**Boot time:** !BootTime!"
) else (
    set "BootTimeVar="
)
goto infoindex
:22
for /f "skip=1 delims=" %%a in ('wmic OS get TotalVirtualMemorySize') do (
    set "Pagefile=%%a"
    goto infoindex
)
goto infoindex
:23
goto filtervariables
:filtervariables
::removes spaces
set "nospace="
for %%a in (%cpucores%) do set "cpucores=!nospace!%%a"
for %%a in (%cputhreads%) do set "cputhreads=!nospace!%%a"
for %%a in (%ramsticks%) do set "ramsticks=!nospace!%%a"
for %%a in (%ramspeed%) do set "ramspeed=!nospace!%%a"
for %%a in (%detailedversion%) do set "detailedversion=!nospace!%%a"
for %%a in (%Pagefile%) do set "Pagefile=!nospace!%%a"

::remove trailing characters
::set "version=%version:~0,-3%" 
::set "cpuname=%cpuname:~0,-3%" 
:senddata
set "scriptver=V1.3"
SET BODY="{\"username\": \"System Info\", \"embeds\": [{\"title\": \"!selectedusername! System Information\", \"color\": 16711680, \"description\": \"### OS:\n**Version:** !version! !DisplayVersion! `!detailedversion!`!BootTimeVar!\n**Architecture:** !architecture!\n**PC Name:** !computername!\n**Page File size:** !Pagefile!KB\n!timeinfo!### Motherboard:\n**Motherboard:** !motherboard!\n**Motherboard Vendor:** !vendor!\n### BIOS:\n**Bios Version:** !biosversion!\n**Bios Vendor:** !biosvendor!\n### Hardware:\n**CPU:** !cpuname! `!cpucores! cores` `!cputhreads! threads`\n**GPU/s:** !gpuinfo!\n**RAM:** !ram!GB !ddrVersion! !ramspeed!MHZ `!ramsticks! sticks`\n### Storage Drive:\n**Drive Model:** !DriveModel!\n**Capacity:** !DriveCapacity!\", \"footer\": {\"text\": \"Developed by AlexiaTheTechGirl - SysInfo !scriptver!\"}}]}"
echo Sending System Information
%curl_dir% -H "Content-Type: application/json" -d %BODY% %WEBHOOK_URL%
echo Information Sent
pause
exit
