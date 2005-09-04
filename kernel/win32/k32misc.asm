;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2000, Leif Ekblad
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. The only exception to this rule
; is for commercial usage in embedded systems. For information on
; usage in commercial embedded systems, contact embedded@rdos.net
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;
; The author of this program may be contacted at leif@rdos.net
;
; K32MISC.ASM
; 32-bit kernel32.dll utilities
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
	NAME  k32misc

;;;;;;;;; INTERNAL ProcEDURES ;;;;;;;;;;;

.386p
.model flat

include ..\user.def
include ..\driver.def
include ..\os\protseg.def

UserGate	MACRO gate_nr
	db 9Ah
	dd gate_nr
	dw 2
			ENDM

systime		STRUC
	wYear		dw ?
	wMonth		dw ?
	wDayOfWeek	dw ?
	wDay 		dw ?
	wHour 		dw ?
	wMinute 	dw ?
	wSecond 	dw ?
	wMilliseconds	dw ?
systime		ENDS

time_zone_information	STRUC
	Bias			dd ?
	StandardName	db 32 dup (?)
	StandardDate	systime	<>
	StandardBias	dd ?
	DaylightName	db 32 dup (?) 
	DaylightDate	systime <>
	DaylightBias	dd ?
time_zone_information	ENDS

system_info	STRUC

siArchitectureType	DW ?
siReserved1			DW ?
siPageSize			DD ?
siMinAddress		DD ?
siMaxAddress		DD ?
siActiveCpuMask		DD ?
siNumOfCpus			DD ?
siCpuType			DD ?
siAppGranularity	DD ?
siCpuLevel			DW ?
siCpuRevision		DW ?

system_info ENDS

.code

	EXTRN  ExitProcess: near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DebugBreak
;
;       DESCRIPTION:   	Break execution
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public DebugBreak

DebugBreak Proc near
	int 3
	ret
DebugBreak ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           QueryPerformanceFrequency
;
;       DESCRIPTION:   	Return performance counter frequency
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public QueryPerformanceFrequency

QueryPerformanceFrequency Proc near
	mov eax,[esp+4]
	mov dword ptr [eax],1193000
	mov dword ptr [eax+4],0
	mov eax,1
	ret
QueryPerformanceFrequency Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           QueryPerformanceCounter
;
;       DESCRIPTION:   	Return performance counter value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public QueryPerformanceCounter

QueryPerformanceCounter Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	UserGate get_thread_nr
	mov bx,ax
	UserGate get_cpu_time_nr
	mov ebx,[ebp+8]
	mov dword ptr [ebx],eax
	mov dword ptr [ebx+4],edx
;
	pop ebx	
	pop ebp
	ret 4
QueryPerformanceCounter Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WideCharToMultibyte
;
;       DESCRIPTION:   	Wide -> Ansi
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WideCharToMultiByte

WideCharToMultiByte Proc near
	push ebx
	mov ecx,[esp + 16 + 4] ; number of input chrs
	mov edx,[esp + 12 + 4] ; input string
	mov ebx,[esp + 20 + 4] ; output string
	sub eax,eax
	test ebx,ebx
	jz wcmbDone

wcmbLoop:
	mov al,[edx]
	inc edx
	inc edx
	mov [ebx],al
	inc ebx
	test al,al
	jz wcmbDone
;
	loop wcmbLoop

wcmbDone:
	sub	ebx,[esp + 20 + 4]
	mov	eax, ebx
	pop ebx
	ret 32
WideCharToMultiByte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MultiByteToWideChar
;
;       DESCRIPTION:   	Ansi -> Wide
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public MultiByteToWideChar

MultiByteToWideChar Proc near
	push ebx
	mov ecx,[esp + 16 + 4] ; number of input chrs
	mov edx,[esp + 12 + 4] ; input string
	mov ebx,[esp + 20 + 4] ; output string
	test ebx,ebx
	jz mbwcDone

	sub eax,eax

mbwcLoop:
	mov al,[edx]
	inc edx
	mov [ebx],ax
	inc ebx
	inc ebx
	test	al, al
	jz mbwcDone
;	
	loop mbwcLoop

mbwcDone:
	sub	ebx, [esp + 20 + 4]
	mov	eax, ebx
	pop	ebx
	ret 24
MultiByteToWideChar Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeEnvironmentStrings
;
;       DESCRIPTION:   	Free environment string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FreeEnvironmentStringsW
	public FreeEnvironmentStringsA

FreeEnvironmentStringsW Proc near
	mov eax,1
	ret 4
FreeEnvironmentStringsW	Endp

FreeEnvironmentStringsA Proc near
	mov eax,1
	ret 4
FreeEnvironmentStringsA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetCurrentTime
;
;       DESCRIPTION:   	Get current time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetCurrentTime
	public GetTickCount

GetCurrentTime Proc near
GetTickCount:
	UserGate get_system_time_nr
	mov ecx,1193
	div ecx
	ret
GetCurrentTime	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalFileTimeToFileTime
;
;       DESCRIPTION:   	Dummies
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LocalFileTimeToFileTime
	public FileTimeToLocalFileTime

LocalFileTimeToFileTime Proc near
FileTimeToLocalFileTime:
	mov edx,[esp+4]
	mov ecx,[esp+8]
	mov eax,[edx]
	mov edx,[edx+4]
	mov [ecx],eax
	mov [ecx+4],edx
	mov eax,1
	ret 8
LocalFileTimeToFileTime ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetSystemTimeAsFileTime
;
;       DESCRIPTION:   	
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetSystemTimeAsFileTime

GetSystemTimeAsFileTime PROC near
	sub	esp, 16
	mov	eax, esp
	push dword ptr [esp + 4 + 16]
	push eax
	push eax
	call GetSystemTime
	call SystemTimeToFileTime
	add	esp, 16
	ret 4
GetSystemTimeAsFileTime ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetTimeZoneInformation
;
;       DESCRIPTION:   	Time zone
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetTimeZoneInformation

GetTimeZoneInformation Proc near
	mov edx,[esp+4]
	mov [edx].Bias,0
	mov [edx].StandardName,0
	mov [edx].StandardDate.wMonth,0
	mov [edx].StandardBias,0
	mov [edx].DaylightName,0
	mov [edx].DaylightDate.wMonth,0
	mov DaylightBias[edx],0
	mov eax,1
	ret 4
GetTimeZoneInformation ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetSystemTime
;
;       DESCRIPTION:   	Get system time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetSystemTime
	public GetLocalTime

gstData	EQU 8

GetSystemTime Proc near
GetLocalTime:
	push ebp
	mov ebp,esp
	push ebx
	push esi
;
	UserGate get_time_nr
	UserGate binary_to_time_nr
	mov esi,[ebp].gstData
	mov [esi].wYear,dx
	movzx dx,ch
	mov [esi].wMonth,dx
	mov [esi].wDayOfWeek,0
	movzx dx,cl
	mov [esi].wDay,dx
	movzx dx,bh
	mov [esi].wHour,dx
	movzx dx,bl
	mov [esi].wMinute,dx
	movzx dx,ah
	mov [esi].wSecond,dx
	mov [esi].wMilliseconds,0
	mov eax,1
;
	pop esi
	pop ebx
	pop ebp
	ret 4
GetSystemTime ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FileTimeToSystemTime
;
;       DESCRIPTION:   	File time -> system time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FileTimeToSystemTime

fttstFileTime	EQU 8
fttstSystemTime	EQU 12

FileTimeToSystemTime Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
;
	mov esi,[ebp].fttstFileTime
	mov eax,[esi]
	mov edx,[esi+4]
	UserGate binary_to_time_nr
	mov esi,[ebp].fttstSystemTime
	mov [esi].wYear,dx
	movzx dx,ch
	mov [esi].wMonth,dx
	mov [esi].wDayOfWeek,0
	movzx dx,cl
	mov [esi].wDay,dx
	movzx dx,bh
	mov [esi].wHour,dx
	movzx dx,bl
	mov [esi].wMinute,dx
	movzx dx,ah
	mov [esi].wSecond,dx
	mov [esi].wMilliseconds,0
	mov eax,1
;
	pop esi
	pop ebx
	pop ebp
	ret 8
FileTimeToSystemTime ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SystemTimeToFileTime
;
;       DESCRIPTION:   	System time -> file time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SystemTimeToFileTime

sttftSystemTime	EQU 8
sttftFileTime	EQU 12

SystemTimeToFileTime Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
;
	mov esi,[ebp].sttftSystemTime
	mov dx,[esi].wYear
	mov ch, byte ptr [esi].wMonth
	mov cl, byte ptr [esi].wDay
	mov bh, byte ptr [esi].wHour
	mov bl, byte ptr [esi].wMinute
	mov ah, byte ptr [esi].wSecond
	UserGate time_to_binary_nr
	mov esi,[ebp].sttftFileTime
	mov [esi],eax
	mov [esi+4],edx
	mov eax,1
;
	pop esi
	pop ebx
	pop ebp
	ret 8
SystemTimeToFileTime ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FileTimeToDosDateTime
;
;       DESCRIPTION:   	File time -> DOS file time & date
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FileTimeToDosDateTime

fttddtFileTime		EQU 8
fttddtDosDate		EQU 12
fttddtDosTime		EQU 16

FileTimeToDosDateTime Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
;
	mov esi,[ebp].fttddtFileTime
	mov eax,[esi]
	mov edx,[esi+4]
	UserGate binary_to_time_nr
	shl cl,3
	shr cx,3
	sub dx,1980
	mov dh,dl
	shl dh,1
	xor dl,dl
	or dx,cx
	mov al,ah
	shr al,1
	shl bl,2
	shl bx,3
	or bl,al
	mov esi,[ebp].fttddtDosTime
	mov [esi],bx
	mov esi,[ebp].fttddtDosDate
	mov [esi],dx
	mov eax,1
;
	pop esi
	pop ebx
	pop ebp
	ret 12
FileTimeToDosDateTime ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DosDateTimeToFileTime
;
;       DESCRIPTION:   	DOS file time & date -> File time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public DosDateTimeToFileTime

ddttftDosDate	EQU 8
ddttftDosTime	EQU 12
ddttftFileTime	EQU 16

DosDateTimeToFileTime Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
;
	mov dx,[ebp].ddttftDosDate
	mov ax,dx
	shr dx,9
	add dx,1980
	mov cx,ax
	shr cx,5
	mov ch,cl
	and ch,0Fh
	mov cl,al
	and cl,1Fh
	mov bx,[ebp].ddttftDosTime
	mov ax,bx
	shr bx,11
	mov bh,bl
	shr ax,5
	and al,3Fh
	mov bl,al
	mov ax,[ebp].ddttftDosTime
	mov ah,al
	add ah,ah
	and ah,3Fh
	UserGate time_to_binary_nr
	mov esi,[ebp].ddttftFileTime
	mov [esi],eax
	mov [esi+4],edx
	mov eax,1
	ret 12
DosDateTimeToFileTime ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetSystemInfo
;
;       DESCRIPTION:   	Get system info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetSystemInfo

gsiData	EQU 8

GetSystemInfo Proc near
	push ebp
	mov ebp,esp
;
	mov edx,[ebp].gsiData
	mov [edx].siArchitectureType,0
	mov [edx].siPageSize,1000h
	mov [edx].siMinAddress,0
	mov [edx].siMaxAddress,flat_size
	mov [edx].siActiveCpuMask,3
	mov [edx].siNumOfCpus,1
	mov [edx].siCpuType,386
	mov [edx].siAppGranularity,1000h
	mov [edx].siCpuLevel,3
	mov [edx].siCpuRevision,0
	pop ebp
	ret 4
GetSystemInfo Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetLocaleInfoA
;
;       DESCRIPTION:   	Get local params
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetLocaleInfoA

LOCALE_WDOSX  label byte
LOCALE_SMONTHNAME13 label byte
LOCALE_IFIRSTWEEKOFYEAR label byte
LOCALE_ICALENDARTYPE label byte
LOCALE_IOPTIONALCALENDAR label byte
LOCALE_ICENTURY  label byte
LOCALE_IDATE  label byte
LOCALE_ILDATE  label byte
LOCALE_ITIME  label byte
LOCALE_ITIMEMARKPOSN label byte
LOCALE_ICURRENCY db 0

LOCALE_SNEGATIVESIGN label byte
LOCALE_INEGCURR  label byte
LOCALE_ILZERO  label byte
LOCALE_INEGNUMBER label byte
	 db '-'

LOCALE_SPOSITIVESIGN db '+'

LOCALE_IPOSSYMPRECEDES label byte
LOCALE_IPOSSEPBYSPACE label byte
LOCALE_INEGSYMPRECEDES label byte
LOCALE_INEGSEPBYSPACE label byte
LOCALE_IPOSSIGNPOSN label byte
LOCALE_INEGSIGNPOSN label byte
LOCALE_IDAYLZERO label byte
LOCALE_IMONLZERO label byte
LOCALE_ITLZERO  label byte
LOCALE_IMEASURE  label byte
LOCALE_IDEFAULTLANGUAGE label byte
LOCALE_IDEFAULTCOUNTRY label byte
LOCALE_ICOUNTRY  label byte
LOCALE_ILANGUAGE db '0',0

LOCALE_SNATIVELANGNAME label byte
LOCALE_SABBREVLANGNAME label byte
LOCALE_SENGLANGUAGE label byte
LOCALE_SLANGUAGE label byte

LOCALE_SCOUNTRY  label byte
LOCALE_SENGCOUNTRY label byte
LOCALE_SABBREVCTRYNAME label byte
LOCALE_SNATIVECTRYNAME db 0

LOCALE_IDEFAULTCODEPAGE label byte
LOCALE_IDEFAULTANSICODEPAGE db '437',0

LOCALE_SDECIMAL  label byte
LOCALE_SMONDECIMALSEP label byte
LOCALE_SLIST  db ',',0
LOCALE_SMONTHOUSANDSEP label byte
LOCALE_STHOUSAND db '.',0
LOCALE_SMONGROUPING label byte
LOCALE_SGROUPING db '3',0
LOCALE_IDIGITS  db '2',0
LOCALE_ICURRDIGITS label near
LOCALE_IINTLCURRDIGITS label near
LOCALE_SNATIVEDIGITS db '0123456789',0
LOCALE_SINTLSYMBOL label byte
LOCALE_SCURRENCY db '$',0
LOCALE_SDATE  db '/',0
LOCALE_STIME  db ':',0

LOCALE_SSHORTDATE db 'yy/mm/dd',0
LOCALE_SLONGDATE db 'yyyy/mm/dd',0
LOCALE_STIMEFORMAT db 'hh:mm:ss',0

LOCALE_S1159  db 'AM',0
LOCALE_S2359  db 'PM',0

LOCALE_IFIRSTDAYOFWEEK label byte
LOCALE_SABBREVDAYNAME1 label byte
LOCALE_SDAYNAME1 db 'Monday',0
LOCALE_SABBREVDAYNAME2 label byte
LOCALE_SDAYNAME2 db 'Tuesday',0
LOCALE_SABBREVDAYNAME3 label byte
LOCALE_SDAYNAME3 db 'Wednesday',0
LOCALE_SABBREVDAYNAME4 label byte
LOCALE_SDAYNAME4 db 'Thursday',0
LOCALE_SABBREVDAYNAME5 label byte
LOCALE_SDAYNAME5 db 'Friday',0
LOCALE_SABBREVDAYNAME6 label byte
LOCALE_SDAYNAME6 db 'Saturday',0
LOCALE_SABBREVDAYNAME7 label byte
LOCALE_SDAYNAME7 db 'Sunday',0

LOCALE_SABBREVMONTHNAME1 label byte
LOCALE_SMONTHNAME1 db 'January',0
LOCALE_SABBREVMONTHNAME2 label byte
LOCALE_SMONTHNAME2 db 'February',0
LOCALE_SABBREVMONTHNAME3 label byte
LOCALE_SMONTHNAME3 db 'March',0
LOCALE_SABBREVMONTHNAME4 label byte
LOCALE_SMONTHNAME4 db 'April',0
LOCALE_SABBREVMONTHNAME5 label byte
LOCALE_SMONTHNAME5 db 'May',0
LOCALE_SABBREVMONTHNAME6 label byte
LOCALE_SMONTHNAME6 db 'June',0
LOCALE_SABBREVMONTHNAME7 label byte
LOCALE_SMONTHNAME7 db 'July',0
LOCALE_SABBREVMONTHNAME8 label byte
LOCALE_SMONTHNAME8 db 'August',0
LOCALE_SABBREVMONTHNAME9 label byte
LOCALE_SMONTHNAME9 db 'September',0
LOCALE_SABBREVMONTHNAME10 label byte
LOCALE_SMONTHNAME10 db 'October',0
LOCALE_SABBREVMONTHNAME11 label byte
LOCALE_SMONTHNAME11 db 'November',0
LOCALE_SABBREVMONTHNAME12 label byte
LOCALE_SMONTHNAME12 db 'December',0

LocaleTable LABEL dword

dd offset LOCALE_ILANGUAGE,       00000001h   ; language id
dd offset LOCALE_SLANGUAGE,          00000002h   ; localized name of language
dd offset LOCALE_SENGLANGUAGE,       00001001h   ; English name of language
dd offset LOCALE_SABBREVLANGNAME,    00000003h   ; abbreviated language name
dd offset LOCALE_SNATIVELANGNAME,    00000004h   ; native name of language
dd offset LOCALE_ICOUNTRY,           00000005h   ; country code
dd offset LOCALE_SCOUNTRY,           00000006h   ; localized name of country
dd offset LOCALE_SENGCOUNTRY,        00001002h   ; English name of country
dd offset LOCALE_SABBREVCTRYNAME,    00000007h   ; abbreviated country name
dd offset LOCALE_SNATIVECTRYNAME,    00000008h   ; native name of country
dd offset LOCALE_IDEFAULTLANGUAGE,   00000009h   ; default language id
dd offset LOCALE_IDEFAULTCOUNTRY,    0000000Ah   ; default country code
dd offset LOCALE_IDEFAULTCODEPAGE,   0000000Bh   ; default oem code page
dd offset LOCALE_IDEFAULTANSICODEPAGE,00001004h   ; default ansi code page
dd offset LOCALE_SLIST,              0000000Ch   ; list item separator
dd offset LOCALE_IMEASURE,           0000000Dh   ; 0 = metric,1 = US
dd offset LOCALE_SDECIMAL,           0000000Eh   ; decimal separator
dd offset LOCALE_STHOUSAND,          0000000Fh   ; thousand separator
dd offset LOCALE_SGROUPING,          00000010h   ; digit grouping
dd offset LOCALE_IDIGITS,            00000011h   ; number of fractional digits
dd offset LOCALE_ILZERO,             00000012h   ; leading zeros for decimal
dd offset LOCALE_INEGNUMBER,         00001010h   ; negative number mode
dd offset LOCALE_SNATIVEDIGITS,      00000013h   ; native ascii 0-9
dd offset LOCALE_SCURRENCY,          00000014h   ; local monetary symbol
dd offset LOCALE_SINTLSYMBOL,        00000015h   ; intl monetary symbol
dd offset LOCALE_SMONDECIMALSEP,     00000016h   ; monetary decimal separator
dd offset LOCALE_SMONTHOUSANDSEP,    00000017h   ; monetary thousand separator
dd offset LOCALE_SMONGROUPING,       00000018h   ; monetary grouping
dd offset LOCALE_ICURRDIGITS,        00000019h   ; # local monetary digits
dd offset LOCALE_IINTLCURRDIGITS,    0000001Ah   ; # intl monetary digits
dd offset LOCALE_ICURRENCY,          0000001Bh   ; positive currency mode
dd offset LOCALE_INEGCURR,           0000001Ch   ; negative currency mode
dd offset LOCALE_SDATE,              0000001Dh   ; date separator
dd offset LOCALE_STIME,              0000001Eh   ; time separator
dd offset LOCALE_SSHORTDATE,         0000001Fh   ; short date format string
dd offset LOCALE_SLONGDATE,          00000020h   ; long date format string
dd offset LOCALE_STIMEFORMAT,        00001003h   ; time format string
dd offset LOCALE_IDATE,              00000021h   ; short date format ordering
dd offset LOCALE_ILDATE,             00000022h   ; long date format ordering
dd offset LOCALE_ITIME,              00000023h   ; time format specifier
dd offset LOCALE_ITIMEMARKPOSN,      00001005h   ; time marker position
dd offset LOCALE_ICENTURY,           00000024h   ; century format specifier (short date)
dd offset LOCALE_ITLZERO,            00000025h   ; leading zeros in time field
dd offset LOCALE_IDAYLZERO,          00000026h   ; leading zeros in day field (short date)
dd offset LOCALE_IMONLZERO,          00000027h   ; leading zeros in month field (short date)
dd offset LOCALE_S1159,              00000028h   ; AM designator
dd offset LOCALE_S2359,              00000029h   ; PM designator
dd offset LOCALE_ICALENDARTYPE,      00001009h   ; type of calendar specifier
dd offset LOCALE_IOPTIONALCALENDAR,  0000100Bh   ; additional calendar types specifier
dd offset LOCALE_IFIRSTDAYOFWEEK,    0000100Ch   ; first day of week specifier
dd offset LOCALE_IFIRSTWEEKOFYEAR,   0000100Dh   ; first week of year specifier
dd offset LOCALE_SDAYNAME1,          0000002Ah   ; long name for Monday
dd offset LOCALE_SDAYNAME2,          0000002Bh   ; long name for Tuesday
dd offset LOCALE_SDAYNAME3,          0000002Ch   ; long name for Wednesday
dd offset LOCALE_SDAYNAME4,          0000002Dh   ; long name for Thursday
dd offset LOCALE_SDAYNAME5,          0000002Eh   ; long name for Friday
dd offset LOCALE_SDAYNAME6,          0000002Fh   ; long name for Saturday
dd offset LOCALE_SDAYNAME7,          00000030h   ; long name for Sunday
dd offset LOCALE_SABBREVDAYNAME1,    00000031h   ; abbreviated name for Monday
dd offset LOCALE_SABBREVDAYNAME2,    00000032h   ; abbreviated name for Tuesday
dd offset LOCALE_SABBREVDAYNAME3,    00000033h   ; abbreviated name for Wednesday
dd offset LOCALE_SABBREVDAYNAME4,    00000034h   ; abbreviated name for Thursday
dd offset LOCALE_SABBREVDAYNAME5,    00000035h   ; abbreviated name for Friday
dd offset LOCALE_SABBREVDAYNAME6,    00000036h   ; abbreviated name for Saturday
dd offset LOCALE_SABBREVDAYNAME7,    00000037h   ; abbreviated name for Sunday
dd offset LOCALE_SMONTHNAME1,        00000038h   ; long name for January
dd offset LOCALE_SMONTHNAME2,        00000039h   ; long name for February
dd offset LOCALE_SMONTHNAME3,        0000003Ah   ; long name for March
dd offset LOCALE_SMONTHNAME4,        0000003Bh   ; long name for April
dd offset LOCALE_SMONTHNAME5,        0000003Ch   ; long name for May
dd offset LOCALE_SMONTHNAME6,        0000003Dh   ; long name for June
dd offset LOCALE_SMONTHNAME7,        0000003Eh   ; long name for July
dd offset LOCALE_SMONTHNAME8,        0000003Fh   ; long name for August
dd offset LOCALE_SMONTHNAME9,        00000040h   ; long name for September
dd offset LOCALE_SMONTHNAME10,       00000041h   ; long name for October
dd offset LOCALE_SMONTHNAME11,       00000042h   ; long name for November
dd offset LOCALE_SMONTHNAME12,       00000043h   ; long name for December
dd offset LOCALE_SABBREVMONTHNAME1,  00000044h   ; abbreviated name for January
dd offset LOCALE_SABBREVMONTHNAME2,  00000045h   ; abbreviated name for February
dd offset LOCALE_SABBREVMONTHNAME3,  00000046h   ; abbreviated name for March
dd offset LOCALE_SABBREVMONTHNAME4,  00000047h   ; abbreviated name for April
dd offset LOCALE_SABBREVMONTHNAME5,  00000048h   ; abbreviated name for May
dd offset LOCALE_SABBREVMONTHNAME6,  00000049h   ; abbreviated name for June
dd offset LOCALE_SABBREVMONTHNAME7,  0000004Ah   ; abbreviated name for July
dd offset LOCALE_SABBREVMONTHNAME8,  0000004Bh   ; abbreviated name for August
dd offset LOCALE_SABBREVMONTHNAME9,  0000004Ch   ; abbreviated name for September
dd offset LOCALE_SABBREVMONTHNAME10, 0000004Dh   ; abbreviated name for October
dd offset LOCALE_SABBREVMONTHNAME11, 0000004Eh   ; abbreviated name for November
dd offset LOCALE_SABBREVMONTHNAME12, 0000004Fh   ; abbreviated name for December
dd offset LOCALE_SPOSITIVESIGN,      00000050h   ; positive sign
dd offset LOCALE_SNEGATIVESIGN,      00000051h   ; negative sign
dd offset LOCALE_IPOSSIGNPOSN,       00000052h   ; positive sign position
dd offset LOCALE_INEGSIGNPOSN,       00000053h   ; negative sign position
dd offset LOCALE_IPOSSYMPRECEDES,    00000054h   ; mon sym precedes pos amt
dd offset LOCALE_IPOSSEPBYSPACE,     00000055h   ; mon sym sep by space from pos amt
dd offset LOCALE_INEGSYMPRECEDES,    00000056h   ; mon sym precedes neg amt
dd offset LOCALE_INEGSEPBYSPACE,     00000057h   ; mon sym sep by space from neg amt
dd offset LOCALE_WDOSX,0

GetLocaleInfoA Proc near
	mov edx,offset LocaleTable
	mov ecx,[esp+8]
	and ecx,0ffffh

gliLoop:
	mov eax,[edx+4]
	test eax,eax
	jz short gliFound

	cmp eax,ecx
	jz short gliFound

	add edx,8
	jmp short gliLoop

gliFound:
	mov edx,[edx]
	mov eax,[esp+12]
	mov ch,255

	mov cl,[esp+8]
	cmp cl,31h
	jc short gliCopy

	cmp cl,38h
	jc short gliCopy3

	cmp cl,44h
	jc short gliCopy

	cmp cl,50h
	jnc short gliCopy

gliCopy3:
	mov ch,3

gliCopy:
	mov cl,[edx]
	mov [eax],cl
	inc edx
	inc eax
	test cl,cl
	jz short gliCopyEnd

	dec ch
	jnz short gliCopy

	mov [eax],ch
	inc eax

gliCopyEnd:
	sub eax,[esp+12]
	cmp eax,2
	sbb eax,0
	ret 16
GetLocaleInfoA ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsDBCSLeadByteEx
;
;       DESCRIPTION:   	Check for lead byte
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public IsDBCSLeadByteEx

IsDBCSLeadByteEx Proc near
	xor eax,eax
	ret 8
IsDBCSLeadByteEx ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetCPInfo
;
;       DESCRIPTION:   	Get CP info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetCPInfo

GetCPInfo Proc near
	mov eax,[esp + 8]
	mov dword ptr [eax],1
	mov dword ptr [eax + 4],20h
	and dword ptr [eax + 8],0
	and dword ptr [eax + 12],0
	and dword ptr [eax + 14],0
	ret 8
GetCPInfo ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetThreadLocale
;
;       DESCRIPTION:   	Get thread locale
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetThreadLocale

GetThreadLocale Proc near
	int 3
	xor eax,eax
	ret
GetThreadLocale	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetSystemDefaultLCID
;
;       DESCRIPTION:   	Get system default LCID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetSystemDefaultLCID

GetSystemDefaultLCID Proc near
	int 3
	xor eax,eax
	ret
GetSystemDefaultLCID Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LCMapString
;
;       DESCRIPTION:   	LC map string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LCMapStringW
	public LCMapStringA

LCMapStringW Proc near
	int 3
	xor eax,eax
	ret
LCMapStringW	Endp

LCMapStringA Proc near
	int 3
	xor eax,eax
	ret
LCMapStringA Endp

	END
