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
; KERNEL32.ASM
; 32-bit kernel32.dll emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
	NAME  kernel32

;;;;;;;;; INTERNAL ProcEDURES ;;;;;;;;;;;

.386p
.model flat

include ..\os\user.def

UserGate      MACRO gate_nr
	db 66h
	db 9Ah
	dw 0
	dw 180Bh + (gate_nr SHL 4)
			ENDM

MemoryStatus	STRUC

dwLength		dd ?	; sizeof(memorystatus) 
dwMemoryLoad	dd ?	; percent of memory in use 
dwTotalPhys		dd ?	; bytes of physical memory 
dwAvailPhys		dd ?	; free physical memory bytes 
dwTotalPageFile	dd ?	; bytes of paging file 
dwAvailPageFile	dd ?	; free bytes of paging file 
dwTotalVirtual	dd ?	; user bytes of address space 
dwAvailVirtual	dd ?	; free user bytes 

MemoryStatus	ENDS

tib_data	STRUC

pvFirstExcept		DD ?
pvStackUserTop		DD ?
pvStackUserBottom	DD ?
pvLastError			DD ?
pvResv1				DD ?
pvArbitrary			DD ?
pvTEB				DD ?
pvResv2				DD ?
pvThreadHandle		DD ?
pvModuleHandle		DD ?
pvTLSBitmap			DD ?
pvTLSArray			DD ?

tib_data	ENDS

.data

IniBuf	DB 400h DUP(?)

.code

	extrn InitConsole:near
	extrn lstrlen:near
	extrn InitException:near
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DllMain
;
;       DESCRIPTION:    DLL initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dmHandle	EQU 8
dmReason	EQU 12
dmDebugger	EQU 16

DllMain	Proc near
	push ds
	pop es
	or eax,eax
	jz dll_no_exc
;
	call InitException

dll_no_exc:
	call InitConsole
	ret 12
DllMain Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DebugStartup
;
;       DESCRIPTION:    Debug startup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	public DebugStartup

DebugStartup Proc near
	int 3
	ret
DebugStartup Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           Borland32
;
;       DESCRIPTION:    Borland32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	public Borland32

Borland32:
	int 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalMemoryStatus
;
;       DESCRIPTION:    Global memory status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GlobalMemoryStatus

gmsData	EQU 8

GlobalMemoryStatus Proc near
	push ebp
	mov ebp, esp
;
	mov edx,[ebp].gmsData
	mov [edx].dwMemoryLoad,50
	mov [edx].dwTotalPhys,-1
	mov [edx].dwAvailPhys,-1
	mov [edx].dwTotalPageFile,0
	mov [edx].dwAvailPageFile,0
	UserGate available_local_linear_nr
	mov [edx].dwAvailVirtual,eax
	UserGate used_local_linear_nr
	add eax,[edx].dwAvailVirtual
	mov [edx].dwTotalVirtual,eax
;
	pop ebp
	ret 4
GlobalMemoryStatus Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetEnvironmentVariableA
;
;       DESCRIPTION:    Get environment variable
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetEnvironmentVariableA

gevName	EQU 8
gevBuf	EQU 12
gevSize	EQU 16

GetEnvironmentVariableA Proc near
	push ebp
	mov ebp,esp
	push esi
	push edi
;
	call GetEnvironmentStrings
	mov edi,[ebp].gevName
	mov esi,eax

gevFind:
	push edi
gevLoop:
	cmpsb
	jnz gevNext
;
	mov al,[edi]
	or al,al
	jnz gevLoop
;
	mov al,[esi]
	cmp al,'='
	je gevFound

gevNext:
	pop edi

gevNextBp:
	lodsb
	or al,al
	jnz gevNextBp
;
	mov al,[esi]
	or al,al
	jne gevFind
;
	xor eax,eax
	jmp gevDone

gevFound:
	inc esi
	mov ecx,[ebp].gevSize
	mov edi,[ebp].gevBuf
	xor edx,edx

gevMoveLoop:
	inc edx
	lodsb
	stosb
	or al,al
	jnz gevMoveLoop
;
	mov eax,edx	

gevDone:
	pop edi
	pop esi
	pop ebp
	ret 12
GetEnvironmentVariableA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetEnvironmentVariableA
;
;       DESCRIPTION:    Set environment variable
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetEnvironmentVariableA
	public SetEnvironmentVariableW

SetEnvironmentVariableA Proc near
	xor eax,eax
	ret 8
SetEnvironmentVariableA Endp

SetEnvironmentVariableW Proc near
	xor eax,eax
	ret 8
SetEnvironmentVariableW Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetEnvironmentStrings
;
;       DESCRIPTION:    Get environment strings
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetEnvironmentStrings
	public GetEnvironmentStringsA
	public GetEnvironmentStringsW

GetEnvironmentStrings Proc near
GetEnvironmentStringsA:
	push edi
	UserGate get_env_nr
	mov eax,edi
	pop edi
	ret
GetEnvironmentStrings Endp

GetEnvironmentStringsW Proc near
	xor eax,eax
	ret
GetEnvironmentStringsW Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetLastError
;
;       DESCRIPTION:    Get last error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetLastError

GetLastError Proc near
	mov eax, fs:pvLastError
	ret
GetLastError Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetLastError
;
;       DESCRIPTION:    Set last error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetLastError

SetLastError Proc near
	mov eax,[esp+4]
	mov fs:pvLastError,eax
	ret 4
SetLastError Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetCommandLine
;
;       DESCRIPTION:    Get command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetCommandLineA
	public GetCommandLineW

GetCommandLineA Proc near
	push edi
	UserGate get_cmd_line_nr
	mov eax,edi
	pop edi
	ret
GetCommandLineA Endp

GetCommandLineW Proc near
	int 3
	ret
GetCommandLineW Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetStringType
;
;       DESCRIPTION:    Get string type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetStringTypeA
	public GetStringTypeW

GetStringTypeA Proc near
	int 3
	ret
GetStringTypeA Endp

GetStringTypeW Proc near
	int 3
	ret
GetStringTypeW Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetDateFormat
;
;       DESCRIPTION:    Get date format
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetDateFormatA

GetDateFormatA Proc near
	int 3
	sub eax, eax
	ret 24
GetDateFormatA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           EnumCalendarInfoA
;
;       DESCRIPTION:    Enum calendar info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EnumCalendarInfoA

EnumCalendarInfoA Proc near 
	int 3
	mov fs:pvLastError, 5555h
	xor eax,eax
	ret 16
EnumCalendarInfoA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenSystemIni
;
;       DESCRIPTION:    Opens system ini file
;
;		RETURNS:		BX			ini file handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SysIniName	DB 'z:\system.ini',0

OpenSystemIni	Proc
	mov edi,OFFSET SysIniName
	xor cl,cl
	UserGate open_file_nr
	ret
OpenSystemIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenPrivateIni
;
;       DESCRIPTION:    Opens private INI file
;
;		PARAMETERS:		EDI			Ini file name
;
;		RETURNS:		BX			ini file handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPrivateIni	Proc
	xor cl,cl
	UserGate open_file_nr
	ret
OpenPrivateIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindIniSection
;
;       DESCRIPTION:    Find section in .ini file
;
;		PARAMETERS:		BX			ini file handle
;						ESI			Section to find
;
;		RETURNS:		EAX			Size of section
;						EDX			File position
;						NC			Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindIniSection	Proc
	xor edx,edx
FindIniSectionNext:
	mov eax,edx
	UserGate set_file_pos_nr
	mov ecx,400h
	mov edi,OFFSET IniBuf
	UserGate read_file_nr
	or eax,eax
	stc
	jz FindIniSectionDone
FindIniSectionScan:
	mov ecx,eax
	mov al,'['
	repne scasb
	add edx,edi
	sub edx,OFFSET IniBuf
	cmp byte ptr [edi-1],'['
	je FindIniSectionTest
	mov eax,edx
	UserGate set_file_pos_nr
	mov ecx,400h
	mov edi,OFFSET IniBuf
	UserGate read_file_nr
	or eax,eax
	stc
	jnz FindIniSectionScan
	jmp FindIniSectionDone
FindIniSectionTest:
	mov eax,edx
	UserGate set_file_pos_nr
	mov ecx,400h
	mov edi,OFFSET IniBuf
	UserGate read_file_nr
	or eax,eax
	stc
	jz FindIniSectionDone
	push esi
	repe cmpsb
	dec esi
	dec edi
	lodsb
	or al,al
	jne FindIniSectionWrongName
	mov al,[edi]
	cmp al,']'
	jne FindIniSectionWrongName
	pop esi
	inc edi
	add edx,edi
	sub edx,OFFSET IniBuf
	push edx
FindIniSectionSize:
	mov eax,edx
	UserGate set_file_pos_nr
	mov cx,400h
	mov edi,OFFSET IniBuf
	UserGate read_file_nr
	mov ecx,eax
	mov al,'['
	repne scasb
	add edx,edi
	sub edx,OFFSET IniBuf + 1
	or ecx,ecx
	je FindIniSectionSize
	mov eax,edx
	pop edx
	sub eax,edx
	clc
	jmp FindIniSectionDone	
FindIniSectionWrongName:
	pop esi
	add edx,edi
	sub edx,OFFSET IniBuf - 1
	jmp FindIniSectionNext
FindIniSectionDone:
	ret
FindIniSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindIniKey
;
;       DESCRIPTION:    Find key in section
;
;		PARAMETERS:		BX			ini file handle
;						ESI			Key to find
;						EDX			File position
;						EAX			Size of section
;						EDI			Key value
;						NC			Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindIniKey	Proc
	mov ecx,400h
	mov eax,edx
	UserGate set_file_pos_nr
	mov eax,ecx
	mov edi,OFFSET IniBuf
	UserGate read_file_nr
FindIniKeyControl:
	mov al,[edi]
	cmp al,0Dh
	je FindIniKeyControlPass
	cmp al,0Ah
	je FindIniKeyControlPass
	cmp al,' '
	je FindIniKeyControlPass
	cmp al,'['
	je FindIniKeyFail
	cmp al,9
	jne FindIniKeyScan
FindIniKeyControlPass:
	inc edi
	loop FindIniKeyControl

FindIniKeyFail:
	stc
	jmp FindIniKeyDone
FindIniKeyScan:
	push esi
	repe cmpsb
	dec esi
	dec edi
	inc ecx
	lodsb
	pop esi
	or al,al
	jne FindIniKeyWrongName
FindIniKeySpacePass:
	mov al,[edi]
	cmp al,'='
	je FindIniKeyCorrectName
	cmp al,' '
	je FindIniKeySpacePass
	cmp al,9
	jne FindIniKeyWrongName
	inc edi
	sub ecx,1
	jc FindIniKeyDone
	jmp FindIniKeySpacePass
FindIniKeyWrongName:
	mov al,[edi]
	cmp al,0Dh
	je FindIniKeyControl
	inc edi	
	sub ecx,1
	jc FindIniKeyDone
	jmp FindIniKeyWrongName
FindIniKeyCorrectName:
	inc edi
	clc
FindIniKeyDone:
	ret
FindIniKey	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetIniInt
;
;		DESCRIPTION:	Read ini file key as integer
;
;		PARAMETERS:		EDI		String
;						EAX		Size of section
;						EAX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIniInt	PROC
	push ebx
	mov ebx,eax
	xor eax,eax
	xor ch,ch
GetIniIntPass:
	mov cl,[edi]
	inc edi
	sub ebx,1
	jz GetIniIntEnd
	cmp cl,' '
	je GetIniIntPass
	cmp cl,'	'
	je GetIniIntPass
	cmp cl,'+'
	je GetIniIntPass
	cmp cl,'-'
	jne GetIniIntDecode
	mov ch,80h
	jmp GetIniIntPass
GetIniIntDecode:
	dec edi
	inc ebx
GetIniIntLoop:
	mov cl,[edi]
	sub cl,30h
	jc GetIniIntEnd
	cmp cl,0Ah
	jnc GetIniIntEnd
	mov edx,10
	mul edx
	movzx edx,cl
	add eax,edx
	inc edi
	sub ebx,1
	jnz GetIniIntLoop
GetIniIntEnd:
	test ch,80h
	jz GetIniIntPos
	neg eax
GetIniIntPos:
	pop ebx
	ret
GetIniInt	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetProfileIntA
;
;       DESCRIPTION:    Get .ini file integer
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Default		default value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetProfileIntA

gpiAppName	EQU 8
gpiKeyName	EQU 12
gpiDefault	EQU 16

GetProfileIntA	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	call OpenSystemIni
	jc gpiFail
	mov esi,[ebp].gpiAppName
	call FindIniSection
	jc gpiFail
;
	mov esi,[ebp].gpiKeyName
	call FindIniKey
	jc gpiFail
;
	call GetIniInt
	jmp gpiEnd

gpiFail:
	mov eax,[ebp].gpiDefault

gpiEnd:
	push eax
	UserGate close_file_nr
	pop eax
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 12
GetProfileIntA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetProfileStringA
;
;       DESCRIPTION:    Get .ini file string
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Default		default value
;						ReturnedStr	returned string
;						Size		size of ReturnedStr string 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetProfileStringA

gpsAppName	EQU 8
gpsKeyName	EQU 12
gpsDefault	EQU 16
gpsResult	EQU 20
gpsSize		EQU 24

GetProfileStringA	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	call OpenSystemIni
	jc gpsFail
	mov esi,[ebp].gpsAppName
	call FindIniSection
	jc gpsFail
;
	mov esi,[ebp].gpsKeyName
	call FindIniKey
	jc gpsFail
;
	mov ecx,eax
	xor edx,edx
	cmp ecx,[ebp].gpsSize
	jc gpsWhole
;
	mov ecx,[ebp].gpsSize
	dec ecx
gpsWhole:
	mov esi,edi
	mov edi,[ebp].gpsResult
gpsCopy:
	lodsb
	cmp al,0Dh
	je gpsCopied
	cmp al,0Ah
	je gpsCopied
	inc edx
	stosb
	loop gpsCopy
gpsCopied:
	xor al,al
	stosb
	jmp gpsEnd

gpsFail:
	mov esi,[ebp].gpsDefault
	mov edi,[ebp].gpsResult
	mov ecx,[ebp].gpsSize
	dec ecx
	xor edx,edx
gpsDef:
	lodsb
	stosb
	or al,al
	je gpsEnd
	inc edx
	loop gpsDef

gpsEnd:
	UserGate close_file_nr
	mov eax,edx
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 20
GetProfileStringA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteProfileStringA
;
;       DESCRIPTION:    Write .ini file string
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Value		value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public WriteProfileStringA

WriteProfileStringA	Proc
	int 3
	xor eax,eax
	ret 12
WriteProfileStringA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetPrivateProfileIntA
;
;       DESCRIPTION:    Get .ini file integer
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Default		default value
;						File
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetPrivateProfileIntA

gppiAppName	EQU 8
gppiKeyName	EQU 12
gppiDefault	EQU 16
gppiFile	EQU 20

GetPrivateProfileIntA	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov edi,[ebp].gppiFile
	call OpenPrivateIni
	jc gppiFail
	mov esi,[ebp].gppiAppName
	call FindIniSection
	jc gppiFail
;
	mov esi,[ebp].gppiKeyName
	call FindIniKey
	jc gppiFail
;
	call GetIniInt
	jmp gppiEnd

gppiFail:
	mov eax,[ebp].gppiDefault

gppiEnd:
	push eax
	UserGate close_file_nr
	pop eax
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 16
GetPrivateProfileIntA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetPrivateProfileStringA
;
;       DESCRIPTION:    Get .ini file string
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Default		default value
;						ReturnedStr	returned string
;						Size		size of ReturnedStr string 
;						File
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetPrivateProfileStringA

gppsAppName	EQU 8
gppsKeyName	EQU 12
gppsDefault	EQU 16
gppsResult	EQU 20
gppsSize	EQU 24
gppsFile	EQU 28

GetPrivateProfileStringA	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov edi,[ebp].gppsFile
	call OpenPrivateIni
	mov esi,[ebp].gppsAppName
	call FindIniSection
	jc gppsFail
;
	mov esi,[ebp].gppsKeyName
	call FindIniKey
	jc gppsFail
;
	mov ecx,eax
	xor edx,edx
	cmp ecx,[ebp].gppsSize
	jc gppsWhole
;
	mov ecx,[ebp].gppsSize
	dec ecx
gppsWhole:
	mov esi,edi
	mov edi,[ebp].gppsResult
gppsCopy:
	lodsb
	cmp al,0Dh
	je gppsCopied
	cmp al,0Ah
	je gppsCopied
	inc edx
	stosb
	loop gppsCopy
gppsCopied:
	xor al,al
	stosb
	jmp gppsEnd

gppsFail:
	mov esi,[ebp].gppsDefault
	mov edi,[ebp].gppsResult
	mov ecx,[ebp].gppsSize
	dec ecx
	xor edx,edx
gppsDef:
	lodsb
	stosb
	or al,al
	je gppsEnd
	inc edx
	loop gppsDef

gppsEnd:
	UserGate close_file_nr
	mov eax,edx
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 24
GetPrivateProfileStringA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WritePrivateProfileStringA
;
;       DESCRIPTION:    Write .ini file string
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Value		value
;						File
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public WritePrivateProfileStringA

WritePrivateProfileStringA	Proc
	xor eax,eax
	ret 16
WritePrivateProfileStringA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LoadResource
;
;       DESCRIPTION:    Load a resource
;
;		PARAMETERS:		Module
;						Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public LoadResource

lrModule	EQU 8
lrHandle	EQU 12

LoadResource	Proc near
	int 3
	push ebp
	mov ebp,esp
	mov eax,[ebp].lrHandle
	mov eax,[eax]
	pop ebp
	ret 8
LoadResource	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LockResource
;
;       DESCRIPTION:    Lock a resource
;
;		PARAMETERS:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public LockResource

lckHandle	EQU	8

LockResource	Proc near
	push ebp
	mov ebp,esp
	mov eax,[ebp].lckHandle
	pop ebp
	ret 4
LockResource	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeResource
;
;       DESCRIPTION:    Free a resource
;
;		PARAMETERS:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public FreeResource

FreeResource	Proc near
	mov eax,1
	ret 4
FreeResource	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SizeofResource
;
;       DESCRIPTION:    Get size of a resource
;
;		PARAMETERS:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public SizeofResource

srModule	EQU 8
srHandle	EQU 12

SizeofResource	Proc near
	int 3
	push ebp
	mov ebp,esp
	mov eax,[ebp].srHandle
	mov eax,[eax+4]
	pop ebp
	ret 8
SizeofResource	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindResourceA
;
;       DESCRIPTION:    Find a resource
;
;		PARAMETERS:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public FindResourceA

frModule	EQU 8
frName		EQU 12
frType		EQU 16

FindResourceA	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	int 3
	mov ebx,[ebp].frModule
	mov eax,[ebp].frName
	mov edx,[ebp].frType
	UserGate get_dll_resource_nr	
;
	pop ebx
	pop ebp
	ret 12
FindResourceA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FormatMessage
;
;       DESCRIPTION:    Format a message
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FormatMessageA

fmsgmsg db 'Default error notification',0

FormatMessageA Proc near
	mov edx, OFFSET fmsgmsg
	mov eax, [esp+20]

fmsgaloop:
	mov cl, [edx]
	inc edx
	mov [eax], cl
	inc eax
	test cl, cl
	jne fmsgaloop

	sub eax, [esp+20]
	dec eax
	ret 28
FormatMessageA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CompareString
;
;       DESCRIPTION:    Format a message
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CompareStringA

CompareStringA Proc near
	push esi
	push edi

	cmp dword ptr [esp+24], -1
	jne short cstra1

	push dword ptr [esp+20]
	call lstrlen
	mov dword ptr [esp+24], eax

cstra1:
	cmp dword ptr [esp+32], -1
	jne short cstra2

	push dword ptr [esp+28]
	call lstrlen
	mov dword ptr [esp+32], eax

cstra2:
	mov eax, 2
	mov esi, [esp+20]
	mov edi, [esp+28]
	mov ecx, [esp+24]
	cmp ecx, [esp+32]
	jnc short csta01

	mov ecx, [esp+32]

csta01:
	cld
	repe cmpsb
	jne csta02

	mov ecx, [esp+24]
	cmp ecx, [esp+32]
	je csta03

csta02:
	sbb eax, eax
	and eax, 3
	xor al, 2
	 
csta03:
	pop esi
	pop edi
	ret 24
CompareStringA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetConsoleCtrlHandler
;
;       DESCRIPTION:    Set console CTRL handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetConsoleCtrlHandler

SetConsoleCtrlHandler Proc near
	mov eax, 1
	ret 8
SetConsoleCtrlHandler Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVersion
;
;       DESCRIPTION:    Get version
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetVersion

GetVersion Proc near
	mov eax, 80000103h
	ret
GetVersion Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVersionEx
;
;       DESCRIPTION:    Get version extended
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetVersionExA
	public GetVersionExW

GetVersionExA Proc near
GetVersionExW:
	mov edx, [esp+4]
	mov dword ptr [edx+4], 3
	mov dword ptr [edx+8], 5
	mov dword ptr [edx+12], 1000
	mov dword ptr [edx+16], 0
	mov dword ptr [edx+20], 0
	mov eax, 1
	ret 4
GetVersionExA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetStartupInfo
;
;       DESCRIPTION:    Get startup info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetStartupInfoA

GetStartupInfoA Proc near
	mov edx, [esp+4]
	sub eax, eax
	mov DWORD PTR [edx], 17 * 4
	mov DWORD PTR [edx + 4], eax
	mov DWORD PTR [edx + 8], eax
	mov DWORD PTR [edx +12], eax
	mov DWORD PTR [edx +16], eax
	mov DWORD PTR [edx +20], eax
	mov DWORD PTR [edx +24], eax
	mov DWORD PTR [edx +28], eax
	mov DWORD PTR [edx +32], 80
	mov DWORD PTR [edx +36], 25
	mov DWORD PTR [edx +40], 7
	mov DWORD PTR [edx +44], eax
	mov DWORD PTR [edx +48], eax
	mov DWORD PTR [edx +52], eax
	mov DWORD PTR [edx +56], eax
	inc eax
	mov DWORD PTR [edx +60], eax
	inc eax
	mov DWORD PTR [edx +64], eax
	ret 4
GetStartupInfoA Endp

	END DllMain
