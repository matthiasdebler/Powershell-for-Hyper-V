Quelle ct 20/2020


@echo off
setlocal enabledelayedexpansion

set Hinweis=Bitte lesen Sie unbedingt die Anleitung zu diesem Skript in c't 20/2020!


rem --------- Variablen fuer das Skript setzen  -----------

rem *** Arbeitsverzeichnis ***
rem Pfad des Ordners, in dem das Skript liegt.
rem Falls eine Antwortdatei in die VHD-Datei soll, muss sie 
rem als "autounattend.xml" ebenfalls hier liegen.
set workdir=%~d0%~p0

rem *** Temporaerer Unterordner ***
rem Wird standardmaessig im Arbeitsverzeichnis erstellt.
set folder=%~n0-tmp

rem --------- Variablen fuer die VM setzen  -----------

rem *** VM: Anzahl der virtuellen CPUs
set cpu=4

rem *** VM: Start-RAM-Groesse in MByte ***
set startram=2048

rem *** VM: Minmale RAM-Groesse in MByte ***
set minram=1024

rem *** VM: Maximale RAM-Groesse in MByte ***
set maxram=4096

rem *** VM: Netzwerkswitch auswaehlen. Zum Aktivieren "rem" vor der naechsten Zeile entfernen und bei Bedarf Switchname in Anfuehrungsstrichen (') anpassen
rem set switch=-switchname 'default switch'

rem *** VM: Automatische Pruefpunkte an (1) oder aus (0)
set autocheckpoints=0

rem *** VM: Generation 1 (Legacy BIOS) oder 2 (UEFI)? ***
set gen=1

rem --------- Variablen fuer die VHD(x) setzen  -----------

rem *** VHD: (maximale) Dateigroesse in MByte ***
set vhdsize=127000

rem *** VHD-Typ: 0 (feste Groesse) oder 1 (dynamisch wachsend) ***
set vhdtyp=1

rem *** VHD: Partitionsgroesse Boot-/EFI-Partition ***
set partboot=500

rem *** VHD: Partitionsgroesse MSR-Partition ***
set partmsr=128

rem *** VHD: Partitionsgroesse Recovery-Partition ***
set partre=1000

rem --------- Variablen fuer die unbeaufsichtigte Installation -----------

rem *** 64-Bit-Antwortdatei ***
set autox64=Autounattendx64.xml

rem *** 32-Bit-Antwortdatei ***
set autox86=Autounattendx86.xml

rem ------------- Ende der Anpassungen -----------

set operation=*** Hilfe erwuenscht? ***
if /i %1.==. goto hilfe
if /i %1.==/?. goto hilfe
if /i %1.==-?. goto hilfe
if /i %1.==/h. goto hilfe
if /i %1.==-h. goto hilfe
if /i %1.==--h. goto hilfe
if /i %1.==/help. goto hilfe
if /i %1.==-help. goto hilfe
if /i %1.==--help. goto hilfe

rem *** Optik anpassen ***
cls
color 0F
set farbtmp=
for /f "tokens=3" %%b in ('reg query ^"HKLM^\Software^\Microsoft^\Windows NT^\CurrentVersion^" /v ^"ReleaseID^" 2^>nul') do set farbtmp=%%b >nul 2>nul
if "%farbtmp%."=="." goto start

set ESC=
set weiss=%esc%[97m
set gruen=%esc%[92m
set rot=%esc%[91m
set gelb=%esc%[93m

:start
echo.%gelb%
echo ****************************************************
echo ***        Willkommen bei c't-Win2Hyper-V        ***
echo ****************************************************
echo.
echo %hinweis%%weiss%
echo.

echo *** Einige Pruefungen vorab ... ***
echo.

set operation=*** Temporaerer Ordner bereits vorhanden? ***
if not exist %workdir%%folder% goto istfrei
set /a foldernr=1
set tempfolder=%folder%
:ring
set /a foldernr=%foldernr%+1 
set folder=%tempfolder%-%foldernr%
if exist %workdir%%folder% goto ring
:istfrei

set operation=*** Skript braucht mindestens Windows 10 Versin 1709 ***
for /f "tokens=3" %%a in ('reg query ^"HKLM^\SOFTWARE^\Microsoft^\Windows NT^\CurrentVersion^" /v ^"ReleaseID^"') do set versionhost=%%a
if %versionhost% lss 1709 goto fehler1

set operation=*** Skript muss mit Administratorrechten laufen ***
whoami /groups | find "S-1-16-12288" > nul
if errorlevel 1 goto fehler1

set operation=*** Hyper-V muss aktiviert sein ***
dism /online /get-features /format:table | find "Microsoft-Hyper-V " | find "Aktiviert" > nul
if errorlevel 1 goto fehler1

set operation=*** Hyper-V-Modul fuer Windows PowerShell muss aktiviert sein ***
dism /online /get-features /format:table | find "Microsoft-Hyper-V-Management-PowerShell" | find "Aktiviert" > nul
if errorlevel 1 goto fehler1

set operation=*** Es muss eine ISO-, WIM- oder ESD-Datei uebergeben werden ***
set pfad=%*
set pfad="%pfad:"=%"
if .%pfad:~-4,3% neq .wim if .%pfad:~-4,3% neq .esd if .%pfad:~-4,3% neq .iso goto fehler1

echo *** Keine Probleme gefunden, jetzt geht es los ***
echo.

if .%pfad:~-4,3% neq .iso (
  set wim=%pfad%
  goto wahl
)

set operation=*** ISO-Datei einbinden ***
echo %weiss%%operation%%gruen%
set iso="%pfad:"=%"
powershell "mount-diskimage '%iso%'"
if errorlevel 1 goto fehler2
set isolw=
for /f "skip=3" %%i in ('powershell "get-diskimage '%iso%' | get-volume | select driveletter"') do set isolw=%%i
if "%isolw%."=="." goto fehler2

set operation=*** ISO-Datei muss WIM- oder ESD-Datei enthalten ***
if exist %isolw%:\sources\install.esd (
  set wim=%isolw%:\sources\install.esd
) else if exist %isolw%:\sources\install.wim (
  set wim=%isolw%:\sources\install.wim
) else (
  goto fehler1
)
if errorlevel 1 goto fehler2

:wahl
set operation=*** Image auswaehlen ***
echo %weiss%%operation%%gruen%
set index=1
set letztenummer=1
for /f "tokens=1,2* delims=: " %%L in ('%windir%\system32\dism /get-wiminfo /wimfile:%wim%') do (
   if "%%L"=="Index" set /a letztenummer=%%M
)
if %letztenummer% equ 1 goto weiter
%windir%\system32\dism /english /get-wiminfo /wimfile:%wim% 
if errorlevel 1 goto fehler2
echo.%gelb%
set /p Index=Nummer des Images eingeben:
echo.

set operation=*** Pruefe ausgewaehltes Image ***
echo %weiss%%operation%%gruen%

set operation=*** Ausgewaehltes Image muss vorhanden sein ***
if %index% gtr %letztenummer% goto fehler1
if %index% lss 1 goto fehler1
echo.
:weiter

set Operation=*** In Generation-2-VMs laeuft nur x64-Windows ***
for /f "tokens=*" %%L in ('%windir%\system32\dism /english /get-wiminfo /wimfile:%wim% /index:%index% ^| find "Architecture"') do (set archtmp=%%L)
set architektur=%archtmp:~15%
if %gen%==2 if not %architektur%==x64 goto fehler1

set Operation=*** In Generation-2-VMs laufen weder Vista noch Windows 7 ***
for /f "tokens=*" %%L in ('%windir%\system32\dism /english /get-wiminfo /wimfile:%wim% /index:%index% ^| find "Version"') do (set vertmp=%%L)
set version=%vertmp:~10%
set alter=neu
if not %version:~0,3%==6.2 if not %version:~0,3%==6.3 if not %version:~0,3%==6.4 if not %version:~0,3%==10. set alter=alt
if %gen%==2 if %alter%==alt goto fehler1

echo %gruen%OK
echo.

set Operation=*** Speicherpfad fuer VMs auslesen ***
echo %weiss%%operation%%gruen%
echo.
set vmpfad=
for /f "tokens=3" %%a in ('reg query ^"HKLM^\SOFTWARE^\Microsoft^\Windows NT^\CurrentVersion^\Virtualization^" /v ^"DefaultExternalDataRoot^" 2^>nul') do set vmpfad=%%a
if "%vmpfad%."=="." set vmpfad=%allusersprofile%\Microsoft\Windows\Hyper-V\
echo Gespeichert wird die VM unter: %vmpfad%
echo.

set Operation=*** Temporaeren Ordner anlegen *** 
echo %weiss%%operation%%gruen%
echo.
md %workdir%%folder%
echo Temporaerer Ordner angelegt: %workdir%%folder%
echo.

set operation=*** Release-ID auslesen ***
echo %weiss%%operation%%gruen%
echo.
%workdir%7z.exe e %wim% -o%workdir%%folder% %index%\Windows\System32\config\Software >nul 2>nul
reg load HKLM\VHD %workdir%%folder%\software >nul 2>nul
if errorlevel 1 goto fehler2
set reltmp=
for /f "tokens=3" %%b in ('reg query ^"HKLM^\VHD^\Microsoft^\Windows NT^\CurrentVersion^" /v ^"ReleaseID^" 2^>nul') do set reltmp=%%b >nul 2>nul
if "%reltmp%."=="." echo Keine Release-ID gefunden. && goto unload
echo Release-ID ist %reltmp% 
set release=%reltmp%_
:unload
reg unload HKLM\VHD >nul 2>nul
if errorlevel 1 goto fehler2
echo.

set operation=*** Name der VM zusammenstellen ***
echo %weiss%%operation%%gruen%
echo.
for /f "tokens=*" %%L in ('%windir%\system32\dism /english /get-wiminfo /wimfile:%wim% /index:%index% ^| find "Name"') do (set edittmp=%%L)
set edition=%edittmp:~7%
set edition=%edition: =_%
set edition=%edition:~0,41%
for /f "tokens=*" %%L in ('%windir%\system32\dism /english /get-wiminfo /wimfile:%wim% /index:%index% ^| find "Default"') do (set langtmp=%%L)
set sprache=%langtmp:~0,5%
set VMname=%edition%_%release%%architektur%_%sprache%_Gen%gen%_%version%
set vmname=%vmname: =%
chcp 65001 >nul
set vmname=%vmname:ä=ae%
set vmname=%vmname:ö=oe%
set vmname=%vmname:ü=ue%
set vmname=%vmname:ß=ss%
set vmname=%vmname:Ä=Ae%
set vmname=%vmname:Ö=Oe%
set vmname=%vmname:Ü=Ue%
set vmname=%vmname::=.%
chcp 850 >nul
if not exist %vmpfad%%vmname% goto nunaber
set /a nr=1
set tempvmname=%vmname%
:schleife
set /a nr=%nr%+1 
set vmname=%tempvmname%-%nr%
if exist %vmpfad%%vmname% goto schleife
:nunaber
md %vmpfad%%vmname%
echo Als Name der VM wird festgelegt: %vmname%
echo.

set operation=*** Freien Laufwerksbuchstaben fuer Windows-Partition in VHD(X) suchen ***
echo %weiss%%operation%%gruen%
echo.
for %%l in (P Q R S T U V W X Y Z D E F G H I J K L M N O) do (  
  set vhdlw=%%l
  mountvol %%l: /L >nul
  if errorlevel 1 (
    subst | findstr /B "%%l:" >nul
    if errorlevel 1 (
      net use %%l: >nul 2>&1
      if errorlevel 1 goto weiter2
    )
  )
)
goto fehler1
:weiter2
echo Verwende %vhdlw%:
echo.

subst %vhdlw%: %workdir%%folder% 
set operation=*** Freien Laufwerksbuchstaben fuer Boot-Partition in VHD(X) suchen ***
echo %weiss%%operation%%gruen%
echo.
for %%l in (P Q R S T U V W X Y Z D E F G H I J K L M N O) do (  
  set efilw=%%l
  mountvol %%l: /L >nul
  if errorlevel 1 (
    subst | findstr /B "%%l:" >nul
    if errorlevel 1 (
      net use %%l: >nul 2>&1
      if errorlevel 1 goto weiter3
    )
  )
)
goto fehler1
:weiter3
subst %vhdlw%: /d
echo Verwende %efilw%:
echo.

set operation=*** VHD erzeugen ***
echo %weiss%%operation%%gruen%
if %vhdtyp%==1 (set typ=expandable) else set typ=fixed
set format=vhd
if %gen%==2 set format=vhdx
echo create vdisk file=%vmpfad%%vmname%\%vmname%.%format% maximum=%vhdsize% type=%typ% > %workdir%%folder%\diskpart.txt
echo attach vdisk >> %workdir%%folder%\diskpart.txt
if %gen%==2 (
  echo convert gpt >> %workdir%%folder%\diskpart.txt
  echo create partition efi size=%partboot% >> %workdir%%folder%\diskpart.txt
  echo format fs=fat32 quick label="System" >> %workdir%%folder%\diskpart.txt
) else (
  echo create partition primary size=%partboot% >> %workdir%%folder%\diskpart.txt
  echo format quick fs=ntfs label="System" >> %workdir%%folder%\diskpart.txt
  echo active >> %workdir%%folder%\diskpart.txt
)
echo assign letter=%efilw% >> %workdir%%folder%\diskpart.txt
if %gen%==2 echo create partition msr size=%partmsr% >> %workdir%%folder%\diskpart.txt
echo create partition primary >> %workdir%%folder%\diskpart.txt
echo shrink minimum=%partre% >> %workdir%%folder%\diskpart.txt
echo format fs=ntfs quick label="Windows" >> %workdir%%folder%\diskpart.txt
echo assign letter=%vhdlw% >> %workdir%%folder%\diskpart.txt
echo create partition primary >> %workdir%%folder%\diskpart.txt
echo format quick fs=ntfs label="Recovery" >> %workdir%%folder%\diskpart.txt
if %gen%==1 (
  echo set id=27 >> %workdir%%folder%\diskpart.txt
) else (
  echo set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac" >> %workdir%%folder%\diskpart.txt
  echo gpt attributes=0x8000000000000001 >> %workdir%%folder%\diskpart.txt
)
echo exit >> %workdir%%folder%\diskpart.txt
diskpart /s %workdir%%folder%\diskpart.txt
if errorlevel 1 goto fehler2

echo.
set operation=*** Image in VHD kopieren ***
echo %weiss%%operation%%gruen%
dism /apply-image /imagefile=%wim% /index:%index% /applydir=%vhdlw%:
if errorlevel 1 goto fehler2

echo.
set auto=%autox64%
if not %architektur%==x64 set auto=%autox86%
if not exist %~d0%~p0%auto% goto bcdboot
set operation=*** autounattend.xml ergaenzen ***
echo %weiss%%operation%%gruen%
echo.
md %vhdlw%:\windows\panther\unattend
copy %~d0%~p0%auto% %vhdlw%:\windows\panther\unattend\unattend.xml

:bcdboot
echo.
set operation=*** Bootloader ergaenzen ***
echo %weiss%%operation%%gruen%
echo.
if %gen%==1  bcdboot /d %vhdlw%:\windows /s %efilw%: /addlast /l de-de /f BIOS
if %gen%==2  bcdboot /d %vhdlw%:\windows /s %efilw%: /addlast /l de-de /f UEFI
if errorlevel 1 goto fehler2
echo.

set operation=*** Entfernen von Registry-Schluessel "MountedDevices" aus der VHD ***
reg load HKLM\VHD %vhdlw%:\windows\system32\config\system >nul 2>nul
if errorlevel 1 goto fehler2
reg query HKLM\VHD\MountedDevices >nul 2>nul
if errorlevel 1 goto unload 
echo %weiss%%operation%%gruen%
echo.
reg delete HKLM\VHD\MountedDevices /f >nul 2>nul
if errorlevel 1 goto fehler2
echo Registry-Schluessel entfernt
echo.
:unload
reg unload HKLM\VHD >nul 2>nul
if errorlevel 1 goto fehler2

set operation=*** VM erzeugen ***
echo %weiss%%operation%%gruen%
powershell new-vm -name '%vmname%' -path '%vmpfad%%vmname%' -VHDpath '%vmpfad%%vmname%\%vmname%.%format%'  -MemoryStartupBytes %startram%MB -generation %gen% %switch%
powershell set-vm -name '%vmname%' -ProcessorCount %cpu% -DynamicMemory -MemoryMaximumBytes %maxram%MB -MemoryMinimumBytes %minram%MB -AutomaticCheckpointsEnabled %autocheckpoints%
if %alter%==alt (
  powershell Remove-VMNetworkAdapter -vmname '%vmname%'
  powershell Add-VMNetworkAdapter -vmname '%vmname%' -IsLegacy $true
)

set operation=*** Temporaere Laufwerke wieder aushaengen ***
echo %weiss%%operation%%gruen%
echo.
if exist %workdir%%folder% rd /q /s %workdir%%folder%
if not %efilw%.==. if not %vhdlw%.==. if not %efilw%.==%vhdlw%. mountvol %efilw%: /d >nul 2>nul
if exist %vhdlw%: powershell dismount-vhd -path '%vmpfad%%vmname%\%vmname%.%format%'
if exist %isolw%: powershell "dismount-diskimage '%iso%'"

set operation=*** Starte VM ***
echo %weiss%%operation%%gruen%
echo.
powershell Start-VM -name '%vmname%'

echo %weiss%*** Fertig! ***
echo.
pause
goto :eof

rem *** Fehlerbehandlung ***

rem Bedingung nicht erfuellt
:fehler1
set text=Folgende Bedingung wurde nicht erfuellt: 
goto Fehlerausgabe

rem Fehler bei der Durchfuehrung
:fehler2
set text=Operation fehlgeschlagen:
goto Fehlerausgabe


:fehlerausgabe
echo.
echo %rot%%text%
echo.
echo %rot%%operation%
echo.
echo %rot%%hinweis%
echo.

:aufraeumen
set operation=*** Raeume hinter mir auf ***
pause
echo.
echo %weiss%%operation%%gruen%
echo.
if exist %workdir%%folder% rd /q /s %workdir%%folder%
if not %efilw%.==. mountvol %efilw%: /d >nul 2>nul
if exist %vhdlw%: powershell dismount-vhd -path '%vmpfad%%vmname%\%vmname%.%format%' >nul 2>nul
if exist %isolw%: powershell "dismount-diskimage '%iso%'" >nul 2>nul
echo.
set operation=*** Fertig! ***
echo %weiss%%operation%%gruen%
echo.
pause
echo.
goto :eof

:hilfe
echo.
echo %~nx0 erzeugt Hyper-V-VMs
echo.
echo Als Quelle akzeptiert %~nx0 WIM- und ESD-Dateien sowie 
echo ISOs und DVDs, die solche Dateien im Ordner "Sources" enthalten.
echo.
echo %~nx0 muss mit Administratorrechten gestartet werden!
echo.
echo %Hinweis%
echo.
pause
goto :eof
;
REM Erstellt 2020 von Axel Vahldiek/c't
REM mailto: axv@ct.de


