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
; K32FILE.ASM
; 32-bit kernel32.dll file support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
	NAME  k32file

;;;;;;;;; INTERNAL ProcEDURES ;;;;;;;;;;;

.386p
.model flat

include ..\os\user.def

UserGate      MACRO gate_nr
	db 66h
	db 9Ah
	dw 0
	dw 200Bh + (gate_nr SHL 4)
			ENDM


;
; handle masks
;

FF_HANDLE = 0A7650000h
FILE_HANDLE = 3AB60000h
STD_HANDLE = 3AB80000h
STD_IN = STD_HANDLE
STD_OUT = STD_HANDLE + 1
STD_ERR = STD_HANDLE + 2

ffStruc	STRUC

ffAttributes	DD ?
ffCreateTime	DD ?,?
ffLastAccess	DD ?,?
ffLastWrite		DD ?,?
ffSizeHigh		DD ?
ffSizeLow		DD ?
ffCurEntry		DD ?
ffResv			DD ?
ffName			DB 260 DUP(?)

ffStruc	ENDS

bhfiStruc	STRUC

bhfiAttributes	DD ?
bhfiCreateTime	DD ?,?
bhfiLastAccess	DD ?,?
bhfiLastWrite	DD ?,?
bhfiVolume		DD ?
bhfiSizeHigh	DD ?
bhfiSizeLow		DD ?
bhfiLinks		DD ?
bhfiIndex		DD ?,?

bhfiStruc	ENDS

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

.code

	extrn ReadConsole:near
	extrn WriteConsole:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           Wide2Ansi
;
;       DESCRIPTION:    Convert wide string to ansi string
;
;		PARAMETERS:		ECX		Max size of Ansi string
;						ESI		Source Wide string
;						EDI		Dest Ansi string
;
;		RETURNS:		NC		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Wide2Ansi Proc near
	push ecx
	push esi
	push edi

w2aLoop:
	mov al,[esi]
	add esi,2
	mov [edi],al
	inc edi
	or al,al
	clc
	jz w2aDone
	loop w2aLoop
;
	xor eax,eax
	stc

w2aDone:
	pop edi
	pop esi
	pop ecx
	ret
Wide2Ansi	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetDiskFreeSpace
;
;       DESCRIPTION:    Get free disk space
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetDiskFreeSpaceA

gdfsRootPath			EQU 8
gdfsSectorsPerCluster	EQU 12
gdfsBytesPerSector		EQU 16
gdfsFreeClusters		EQU 20
gdfsTotalClusters		EQU 24

GetDiskFreeSpaceA Proc near
	push ebp
	mov ebp,esp
	push esi
;
	mov eax,[ebp].gdfsRootPath
	test eax,eax
	je gdfsDefault

	mov al,[eax]
	and al,NOT 20h
	sub al,'A'
	jmp gdfsNotDefault

gdfsDefault:
	UserGate get_cur_drive_nr

gdfsNotDefault:
	UserGate get_drive_info_nr
	mov esi,[ebp].gdfsSectorsPerCluster
	mov dword ptr [esi],1
;
	movzx ecx,cx
	mov esi,[ebp].gdfsBytesPerSector
	mov [esi],ecx
;
	mov esi,[ebp].gdfsFreeClusters
	mov [esi],eax
;
	mov esi,[ebp].gdfsTotalClusters
	mov [esi],edx
;
	pop esi
	pop ebp
	mov eax,1
	ret 20
GetDiskFreeSpaceA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FlushFileBuffers
;
;       DESCRIPTION:    Flush file buffers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FlushFileBuffers

FlushFileBuffers Proc near
	mov eax,1
	ret 4
FlushFileBuffers Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetHandleCount
;
;       DESCRIPTION:    Set handle count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetHandleCount

SetHandleCount Proc near
	mov eax,[esp+4]
	ret 4
SetHandleCount Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetCurrentDirectory
;
;       DESCRIPTION:    Get current directory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetCurrentDirectoryA

gcdSize	EQU 8
gcdBuf	EQU 12

GetCurrentDirectoryA Proc near
	push ebp
	mov ebp,esp
	push esi
	push edi
	sub esp,256
;
	mov edi,esp
	UserGate get_cur_drive_nr
	mov ah,al
	add ah,'A'
	mov [edi],ah
	inc edi
	mov word ptr [edi],'\:'
	inc edi
	inc edi
;
	UserGate get_cur_dir_nr
	jc short gcdError

	mov esi,esp
	mov edi,[ebp].gcdBuf
	mov ecx,[ebp].gcdSize
gcdMoveLoop:
	mov al,[esi]
	mov [edi],al
	or al,al
	jz short gcdMoveDone
;
	inc esi
	inc edi
	sub ecx,1
	jnz gcdMoveLoop
	jmp gcdMoveDone

gcdError:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax
	jmp gcdDone

gcdMoveDone:
	sub edi,[ebp].gcdBuf
	mov eax,edi

gcdDone:
	add esp,256
	pop edi
	pop esi
	pop ebp
	ret 8
GetCurrentDirectoryA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetFullPathName
;
;       DESCRIPTION:    Get full path name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetFullPathNameA

gfpnFile	EQU 8
gfpnSize	EQU 12
gfpnPath	EQU 16
gfpnFilePtr	EQU 20

GetFullPathNameA Proc near
	push ebp
	mov ebp,esp
	push esi
	push edi
	sub esp,256
;
	mov edi,esp
	UserGate get_cur_drive_nr
	mov ah,al
	add ah,'A'
	mov [edi],ah
	inc edi
	mov word ptr [edi],'\:'
	inc edi
	inc edi
;
	UserGate get_cur_dir_nr
	jc short gcdError

	mov esi,esp
	mov edi,[ebp].gfpnPath
	mov ecx,[ebp].gfpnSize
gfpnMoveLoop:
	mov al,[esi]
	mov [edi],al
	or al,al
	jz short gfpnMoveDone
;
	inc esi
	inc edi
	sub ecx,1
	jnz gfpnMoveLoop
	jmp gfpnMoveDone

gfpnError:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax
	jmp gfpnDone

gfpnMoveDone:
	mov esi,[ebp].gfpnFilePtr
	mov [esi],edi
	cmp byte ptr [edi-1],'\'
	jz short gfpnSlashOk

	mov byte ptr [edi],'\'
	inc edi

gfpnSlashOk:
	mov esi,[ebp].gfpnFile

gfpnAppendLoop:
	mov al,[esi]
	mov [edi],al
	or al,al
	jz gfpnAppendDone
;
	inc esi
	inc edi
	sub ecx,1
	jnz gfpnAppendLoop

gfpnAppendDone:
	sub edi,[ebp].gfpnPath
	mov eax,edi

gfpnDone:
	add esp,256
	pop edi
	pop esi
	pop ebp
	ret 16
GetFullPathNameA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateDirectory
;
;       DESCRIPTION:    Create directory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CreateDirectoryA
	public CreateDirectoryW

mkdPath	EQU 8

CreateDirectoryW Proc near
	push ebp
	mov ebp,esp
	push esi
	push edi
	mov ecx,256
	sub esp,ecx
;
	mov esi,[ebp].mkdPath
	mov edi,esp
	call Wide2Ansi
	jc short mkdirwError
;
	UserGate make_dir_nr
	jc short mkdirwError
;
	mov eax,1
	jmp mkdirwDone

mkdirwError:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

mkdirwDone:
	add esp,256
	pop edi
	pop esi
	pop ebp
	ret 8
CreateDirectoryW Endp	

CreateDirectoryA Proc near
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp].mkdPath
	UserGate make_dir_nr
	jc short mkdiraError
;
	mov eax,1
	jmp mkdiraDone

mkdiraError:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

mkdiraDone:
	pop edi
	pop ebp
	ret 8
CreateDirectoryA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RemoveDirectory
;
;       DESCRIPTION:    Create directory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RemoveDirectoryA
	public RemoveDirectoryW

rmdPath	EQU 8

RemoveDirectoryW Proc near
	push ebp
	mov ebp,esp
	push esi
	push edi
	mov ecx,256
	sub esp,ecx
;
	mov esi,[ebp].rmdPath
	mov edi,esp
	call Wide2Ansi
	jc short rmdirwError
;
	UserGate remove_dir_nr
	jc short rmdirwError
;
	mov eax,1
	jmp rmdirwDone

rmdirwError:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

rmdirwDone:
	add esp,256
	pop edi
	pop esi
	pop ebp
	ret 4
RemoveDirectoryW Endp	

RemoveDirectoryA Proc near
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp].rmdPath
	UserGate remove_dir_nr
	jc short rmdiraError
;
	mov eax,1
	jmp rmdiraDone

rmdiraError:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

rmdiraDone:
	pop edi
	pop ebp
	ret 4
RemoveDirectoryA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetCurrentDirectory
;
;       DESCRIPTION:    Set current directory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetCurrentDirectoryA
	public SetCurrentDirectoryW


chdPath	EQU 8

SetCurrentDirectoryW Proc near
	push ebp
	mov ebp,esp
	push esi
	push edi
	mov ecx,256
	sub esp,ecx
;
	mov esi,[ebp].chdPath
	mov edi,esp
	call Wide2Ansi
	jc short chdirwError
;
	cmp byte ptr [edi+1],':'
	jnz short chdirwDriveOk
;
	mov al,[edi]
	or al,20h
	sub al,'a'
	UserGate set_cur_drive_nr
	add edi,2

chdirwDriveOk:
	mov fs:pvLastError,0
	UserGate set_cur_dir_nr
	jc short chdirwError
	mov eax,1
	jmp chdirwDone

chdirwError:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

chdirwDone:
	add esp,256
	pop edi
	pop esi
	pop ebp
	ret 4
SetCurrentDirectoryW Endp	

SetCurrentDirectoryA Proc near
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp].chdPath
	cmp byte ptr [edi+1],':'
	jnz short chdiraDriveOk
;
	mov al,[edi]
	or al,20h
	sub al,'a'
	UserGate set_cur_drive_nr
	add edi,2

chdiraDriveOk:
	mov fs:pvLastError,0
	UserGate set_cur_dir_nr
	jc short chdiraError
	mov eax,1
	jmp chdiraDone

chdiraError:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

chdiraDone:
	pop edi
	pop ebp
	ret 4
SetCurrentDirectoryA Endp	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVolumeInformation
;
;       DESCRIPTION:    Get volume information
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetVolumeInformationA

gviRootPath			EQU 8
gviVolumeNameBuf	EQU 12
gviVolumeNameSize	EQU 16
gviSerialNumber		EQU 20
gviCompLen			EQU 24
gviFlags			EQU 28
gviFsNameBuf		EQU 32
gviFsNameSize		EQU 36

GetVolumeInformationA Proc near
	push ebp
	mov ebp,esp
;
	mov edx,[ebp].gviVolumeNameBuf
	test edx,edx
	jz short gvi01

	mov byte ptr [edx],0

gvi01:
	mov edx,[ebp].gviSerialNumber
	test edx,edx
	jz short gvi02

	mov dword ptr [edx],0

gvi02:
	mov edx,[ebp].gviCompLen
	test edx,edx
	jz short gvi03

	mov dword ptr [edx],12

gvi03:
	mov edx,[ebp].gviFlags
	test edx,edx
	jz short gvi04

	and dword ptr [edx],0

gvi04:
	mov edx,[ebp].gviFsNameBuf
	test edx,edx
	jz short gvi05

	mov dword ptr [edx],'TAF'

gvi05:
	mov eax,1
	pop ebp
	ret 32
GetVolumeInformationA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetDriveType
;
;       DESCRIPTION:    Get drive type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetDriveTypeA

GetDriveTypeA Proc near
	int 3
	xor eax,eax
	ret 4
GetDriveTypeA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetLogicalDrives
;
;       DESCRIPTION:    Get logical drives
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetLogicalDrives

GetLogicalDrives Proc near
	push edi
	sub esp,256
;
	mov edi,esp
	mov al,'z' - 'a'
	xor ecx,ecx
gldLoop:
	UserGate get_cur_dir_nr
	cmc
	rcl ecx,1
	dec al
	or al,al
	jnz gldLoop
;
	mov eax,ecx
	add esp,256
	pop edi
	ret
GetLogicalDrives Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenFileSearch
;
;       DESCRIPTION:    Open file search
;
;		PARAMETERS:		ESI		File to search for
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_dir	DB 0

OpenFileSearch	Proc near
	push eax
	push ecx
	push edx
	push edi
;
	xor ecx,ecx
	push esi
ofsSizeLoop:
	lods byte ptr [esi]
	or al,al
	jz ofsSizeFound
	inc ecx
	jmp ofsSizeLoop
ofsSizeFound:
	or ecx,ecx
	je ofsDirFound
	mov edi,ecx
ofsDirLoop:
	dec esi
	mov al,[esi]
	cmp al,'\'
	je ofsDirFound
	sub ecx,1
	jne ofsDirLoop
	pop esi
	mov ax,cs
	mov es,ax
	mov edi,OFFSET default_dir
	UserGate open_dir_nr
	jmp ofsDone
ofsDirFound:
	pop esi
	mov eax,ecx
	add eax,4
	UserGate allocate_app_mem_nr
	push eax
	mov edi,edx
	rep movsb
	push edi
	xor al,al
	stosb
	mov edi,edx
	UserGate open_dir_nr
	pop edi
	pop eax
	pushf
	inc esi
	push ebx
	UserGate free_app_mem_nr
	pop ebx
	popf
ofsDone:
	pop edi
	pop edx
	pop ecx
	pop eax
	ret
OpenFileSearch	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetMatchingFiles
;
;       DESCRIPTION:    Get all matching files
;
;		PARAMETERS:		ESI		Filename
;						BX		Handle to dir
;
;		RETURNS:		EDX		Entries array
;						ECX		Number of entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MatchTab:
ct00 DB	0,		0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct08 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct10 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct18 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct20 DB ' ',	'!',	0FFh,	'#',	'$',	'%',	'&',	27h
ct28 DB '(',	')',	'*',	0FFh,	0FFh,	'-',	'.',	0
ct30 DB '0',	'1',	'2',	'3',	'4',	'5',	'6',	'7'
ct38 DB '8',	'9',	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	'?'
ct40 DB '@',	'A',	'B',	'C',	'D',	'E',	'F',	'G'
ct48 DB 'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O'
ct50 DB 'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W'
ct58 DB	'X',	'Y',	'Z',	0FFh,	0,		0FFh,	'^',	'_'
ct60 DB 60h,	'A',	'B',	'C',	'D',	'E',	'F',	'G'
ct68 DB 'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O'
ct70 DB 'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W'
ct78 DB 'X',	'Y',	'Z',	'{',	0FFh,	'}',	'~',	0FFh
ct80 DB	0FFh,	9Ah,	90h,	0FFh,	'é',	0FFh,	'è',	0FFh
ct88 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	'é',	'è'
ct90 DB	0FFh,	0FFh,	0FFh,	0FFh,	'ô',	0FFh,	0FFh,	0FFh
ct98 DB	0FFh,	'ô',	9Ah,	9Bh,	9Ch,	9Dh,	9Eh,	9Fh
ctA0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0A5h,	0A5h,	0A6h,	0A7h
ctA8 DB	0A8h,	0A9h,	0AAh,	0ABh,	0ACh,	0ADh,	0AEh,	0AFh
ctB0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctB8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctC0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctC8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctD0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctD8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctE0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctE8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctF0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctF8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh

gmfEntry	EQU -2
gmfHandle	EQU -4
gmfMemBase	EQU -8
gmfCurrBase	EQU -12
gmfEntries	EQU -16

GetMatchingFiles Proc near
	push ebp
	sub esp,260
	mov ebp,esp
	sub esp,16
	push eax
	push ebx
	push edi
;
	push ebx
	mov eax,20000h
	UserGate allocate_app_mem_nr
	pop ebx
	mov edi,ebp
	mov [ebp].gmfMemBase,edx
	mov [ebp].gmfCurrBase,edx
	mov dword ptr [ebp].gmfEntries,0
	mov word ptr [ebp].gmfEntry,-1
	mov [ebp].gmfHandle,bx

gmfLoop:
	mov bx,[ebp].gmfHandle
	mov dx,[ebp].gmfEntry
	inc dx
	mov [ebp].gmfEntry,dx
	mov ecx,260
	mov edi,ebp
	UserGate read_dir_nr
	jc gmfDone
;
	push esi
	xchg esi,edi
	mov ebx,OFFSET MatchTab
gmfTestBase:
	mov al,[edi]
	cmp al,'*'
	je gmfStarExt
	cmp al,'.'
	je gmfDotFound
	cmp al,'?'
	je gmfBaseCharOk
	xlat byte ptr cs:MatchTab
	mov ah,al
	mov al,es:[esi]
	xlat byte ptr cs:MatchTab
	cmp al,ah
	jne short gmfNext
	mov al,ah
gmfBaseCharOk:
	or al,al
	je short gmfOk
	inc esi
	inc edi
	jmp gmfTestBase

gmfStarExt:
	inc edi
gmfParseStar:
	mov al,[edi]
	inc edi
	cmp al,'.'
	je gmfStarFile
	or al,al	
	je gmfOk
	jmp gmfParseStar
gmfStarFile:
	mov al,[esi]
	inc esi
	or al,al
	je gmfParseEndFile
	cmp al,'.'
	je gmfTestExt
	jmp gmfStarFile

gmfDotFound:
	inc edi
gmfParseExt:
	mov al,[esi]
	or al,al
	je gmfParseEndFile
	cmp al,'.'
	jne gmfNext
	inc esi
	jmp gmfTestExt

gmfParseEndFile:
	mov al,[edi]
	cmp al,'*'
	je gmfOk
	or al,al
	je gmfOk
	cmp al,'?'
	jne gmfNext
	inc edi
	jmp gmfParseEndFile

gmfTestExt:
	mov al,[edi]
	cmp al,'*'
	je gmfOk
	cmp al,'?'
	je gmfExtCharOk
	xlat byte ptr cs:MatchTab
	mov ah,al
	mov al,[esi]
	xlat byte ptr cs:MatchTab
	cmp al,ah
	jne gmfNext
	mov al,ah
gmfExtCharOk:
	or al,al
	je gmfOk
	inc esi
	inc edi
	jmp gmfTestExt

gmfOk:
	mov edi,[ebp].gmfCurrBase
	mov ax,[ebp].gmfEntry
	stosw
	mov [ebp].gmfCurrBase,edi
	inc dword ptr [ebp].gmfEntries

gmfNext:
	xchg esi,edi
	pop esi
	jmp gmfLoop

gmfDone:
	mov edx,[ebp].gmfMemBase
	mov ecx,[ebp].gmfEntries
	pop edi
	pop ebx
	pop eax
	add esp,260+16
	pop ebp
	ret
GetMatchingFiles	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateSearchCache
;
;       DESCRIPTION:    Create a cache for search
;
;		PARAMETERS:		BX		Handle to dir
;						EDX		Entries array
;						ECX		Number of entries
;
;		RETURNS:		EBX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSearchCache Proc near
	push eax
	push ecx
	push edx
	push esi
	push edi
;
	push edx
	mov esi,edx
	mov eax,SIZE ffStruc
	mul ecx
	add eax,12
	push ebx
	UserGate allocate_app_mem_nr
	mov edi,edx
	pop ebx
	stosd
	sub eax,12
	stosd
	xor eax,eax
	stosd
	push edi

cscLoop:
	push bx
	push ecx
;
	push edi
	lodsw
	mov dx,ax
	add edi,OFFSET ffName
	mov ecx,260
	UserGate read_dir_nr
	pop edi
;
	mov [edi].ffSizeLow,ecx
	mov [edi].ffSizeHigh,0
	mov [edi].ffLastAccess,0
	mov [edi].ffLastAccess+4,0
	movzx ebx,bx
	mov [edi].ffAttributes,ebx
	mov [edi].ffCreateTime,0
	mov [edi].ffCreateTime+4,0
	mov [edi].ffLastWrite,eax
	mov [edi].ffLastWrite+4,edx
	mov [edi].ffCurEntry,1
;
	add edi,SIZE ffStruc
	pop ecx
	pop bx
	loop cscLoop
;
	UserGate close_dir_nr
	pop ecx
	pop edx
	mov eax,20000h
	UserGate free_app_mem_nr
	mov ebx,ecx
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop eax
	ret
CreateSearchCache Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetAllFiles
;
;       DESCRIPTION:    Get all files
;
;		PARAMETERS:		BX		Handle to dir
;
;		RETURNS:		EBX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAllFiles Proc near
	push ebp
	sub esp,260
	mov ebp,esp
	push eax
	push edx
	push esi
	push edi
;
	xor edx,edx
	mov edi,esp

gafCountLoop:
	push ebx
	push edx
	mov ecx,260
	UserGate read_dir_nr
	pop edx
	pop ebx
	inc edx
	jnc gafCountLoop
;
	mov ecx,edx
	sub ecx,1
	jz gafDone
;
	mov eax,SIZE ffStruc
	mul ecx
	add eax,12
	push ebx
	UserGate allocate_app_mem_nr
	mov edi,edx
	pop ebx
	stosd
	sub eax,12
	stosd
	xor eax,eax
	stosd
	push ecx
	push edi
	xor edx,edx

gafReadLoop:
	push ecx
	push ebx
	push edx
;
	push edi
	add edi,OFFSET ffName
	mov ecx,260
	UserGate read_dir_nr
	pop edi
	mov [edi].ffSizeLow,ecx
	mov [edi].ffSizeHigh,0
	mov [edi].ffLastAccess,0
	mov [edi].ffLastAccess+4,0
	movzx ebx,bx
	mov [edi].ffAttributes,ebx
	mov [edi].ffCreateTime,0
	mov [edi].ffCreateTime+4,0
	mov [edi].ffLastWrite,eax
	mov [edi].ffLastWrite+4,edx
	mov [edi].ffCurEntry,1
;
	pop edx
	pop ebx
	pop ecx
	add edi,SIZE ffStruc
	inc edx
	loop gafReadLoop	
;
	pop edx
	pop ecx

gafDone:
	UserGate close_dir_nr
	mov ebx,edx
;
	pop edi
	pop esi
	pop edx
	pop eax
	add esp,260
	pop ebp
	ret
GetAllFiles Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindFirstFileA
;
;       DESCRIPTION:    Find first file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FindFirstFileA


fffFile		EQU 8
fffData		EQU 12

FindFirstFileA Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov edi,[ebp].fffFile
	UserGate open_dir_nr
	jc fffSearch
;
	call GetAllFiles
	or ecx,ecx
	jnz fffFirst
	jmp fffFailed

fffSearch:
	mov esi,edi
	call OpenFileSearch
	jc short fffFailed
	call GetMatchingFiles
	or ecx,ecx
	jz fffNoMatch
;	
	call CreateSearchCache
fffFirst:
	mov edi,[ebp].fffData
	mov esi,ebx
	mov ecx,SIZE ffStruc
	rep movsb
	mov [ebx-4],esi
	mov eax,ebx
	jmp fffDone

fffNoMatch:
	UserGate close_dir_nr
	mov eax,20000h
	UserGate free_app_mem_nr

fffFailed:
	xor eax,eax

fffDone:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 8
FindFirstFileA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindNextFileA
;
;       DESCRIPTION:    Find next file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FindNextFileA

fnfHandle	EQU 8
fnfData		EQU 12

FindNextFileA Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov ebx,[ebp].fnfHandle
	sub dword ptr [ebx-8],SIZE ffStruc
	jbe fnfFailed
;
	mov esi,[ebx-4]
	mov edi,[ebp].fnfData
	mov ecx,SIZE ffStruc
	rep movsb
	mov [ebx-4],esi
	mov eax,1
	jmp fnfDone

fnfFailed:
	xor eax,eax

fnfDone:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 8
FindNextFileA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindClose
;
;       DESCRIPTION:    Find close
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FindClose

fclHandle	EQU 8

FindClose Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov edx,[ebp].fclHandle
	cmp edx,-1
	je fclDone
	or edx,edx
	je fclDone
;
	sub edx,12
	mov eax,[edx]
	UserGate free_app_mem_nr

fclDone:
	mov eax,1
;
	pop ebx
	pop ebp
	ret 4
FindClose Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetFileInformationByHandle
;
;       DESCRIPTION:    Get information about handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetFileInformationByHandle

gfibhHandle	EQU 8
gfibhData	EQU 12

GetFileInformationByHandle Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov eax,[ebp].gfibhHandle
	mov bx,ax
	xor ax,ax
	cmp eax,FILE_HANDLE
	mov eax,6
	jne gfibhFailed
;	
	UserGate get_file_size_nr
	jc gfibhFailed
;
	mov edi,[ebp].gfibhHandle
	mov [edi].bhfiAttributes,20h
	mov [edi].bhfiCreateTime,0
	mov [edi].bhfiCreateTime+4,0
	mov [edi].bhfiLastAccess,0
	mov [edi].bhfiLastAccess+4,0
	mov [edi].bhfiLastWrite,0
	mov [edi].bhfiLastWrite+4,0
	mov [edi].bhfiSizeHigh,0
	mov [edi].bhfiSizeLow,eax
	mov [edi].bhfiLinks,1
	mov [edi].bhfiIndex,0
	mov [edi].bhfiIndex+4,0	
	mov eax,1
	jmp gfibhDone

gfibhFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

gfibhDone:
	pop edi
	pop ebx
	pop ebp
	ret 8
GetFileInformationByHandle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MoveFile
;
;       DESCRIPTION:    Move file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public MoveFileA
	public MoveFileW

mvaExisting	EQU 8
mvaNew		EQU 12

MoveFileW Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
	mov ecx,256
	sub esp,ecx
	mov edi,esp
	sub esp,ecx
;
	mov esi,[ebp].mvaExisting
	call Wide2Ansi
	jc short mvawError
;
	mov ebx,edi
	mov esi,[ebp].mvaNew
	mov edi,esp
	call Wide2Ansi
	jc short mvawError
;
	mov esi,ebx
	UserGate rename_file_nr
	jc short mvawError
;
	mov eax,1
	jmp mvawDone

mvawError:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

mvawDone:
	add esp,ecx
	add esp,ecx
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 8
MoveFileW Endp	

MoveFileA Proc near
	push ebp
	mov ebp,esp
	push esi
	push edi
;
	mov esi,[ebp].mvaExisting
	mov edi,[ebp].mvaNew
	UserGate rename_file_nr
	jc short mvaaError
;
	mov eax,1
	jmp mvaaDone

mvaaError:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

mvaaDone:
	pop edi
	pop esi
	pop ebp
	ret 8
MoveFileA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteFile
;
;       DESCRIPTION:    Delete file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public DeleteFileA
	public DeleteFileW

dfPath	EQU 8

DeleteFileW Proc near
	push ebp
	mov ebp,esp
	push esi
	push edi
	mov ecx,256
	sub esp,ecx
;
	mov esi,[ebp].dfPath
	mov edi,esp
	call Wide2Ansi
	jc short dlwError
;
	UserGate delete_file_nr
	jc short dlwError
;
	mov eax,1
	jmp dlwDone

dlwError:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

dlwDone:
	add esp,256
	pop edi
	pop esi
	pop ebp
	ret 4
DeleteFileW Endp	

DeleteFileA Proc near
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp].dfPath
	UserGate delete_file_nr
	jc short dlaError
;
	mov eax,1
	jmp dlaDone

dlaError:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

dlaDone:
	pop edi
	pop ebp
	ret 4
DeleteFileA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SearchPath
;
;       DESCRIPTION:    Search for file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SearchPathA

spPath		EQU 8
spFile		EQU 12
spExt		EQU 16
spSize		EQU 20
spBuf		EQU 24
spFilePtr	EQU 28

SearchPathA Proc near
	push ebp
	mov ebp,esp
;
	int 3
	mov eax,[ebp].spPath
	mov eax,[ebp].spFile
	mov eax,[ebp].spExt
;
	pop ebp
	ret 24
SearchPathA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteFile
;
;       DESCRIPTION:    Write file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteFile

wfHandle	EQU 8
wfBuf		EQU 12
wfCount		EQU 16
wfWritten	EQU 20
wfOverlap	EQU 24

WriteFile Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov eax,[ebp].wfHandle
	mov bx,ax
	xor ax,ax
	cmp eax,FILE_HANDLE
	je wfFile
	cmp eax,STD_HANDLE
	je wfConsole
	mov eax,6
	jmp wfFailed

wfConsole:
	mov edi,[ebp].wfBuf
	mov ecx,[ebp].wfCount
	call WriteConsole
	jmp wfCheck
	
wfFile:
	mov edi,[ebp].wfBuf
	mov ecx,[ebp].wfCount
	UserGate write_file_nr

wfCheck:
	jc short wfFailed
;
	mov ecx,[ebp].wfWritten
	mov [ecx],eax
	mov eax,1
	jmp wfDone

wfFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

wfDone:
	pop edi
	pop ebx
	pop ebp
	ret 20
WriteFile Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetFilePointer
;
;       DESCRIPTION:    Set file pointer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetFilePointer


sfHandle		EQU 8
sfDistanceLow	EQU 12
sfDistanceHigh	EQU 16
sfMethod		EQU 20

SetFilePointer	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp].sfHandle
	mov bx,ax
	xor ax,ax
	cmp eax,FILE_HANDLE
	mov eax,6
	jne sfFailed
;
	mov ecx,[ebp].sfDistanceHigh
	or ecx,ecx
	jz sfMove
;
	mov dword ptr [ecx],0

sfMove:
	mov eax,[ebp].sfMethod
	or eax,eax
	jz SfBOF
	sub eax,1
	jz SfRF
	sub eax,1
	jz SfEOF
	mov eax,6
	jmp sfFailed

sfBOF:
	mov eax,[ebp].sfDistanceLow
	UserGate set_file_pos_nr
	jmp sfValidate

sfRF:
	UserGate get_file_pos_nr
	add eax,[ebp].sfDistanceLow
	UserGate set_file_pos_nr
	jmp sfValidate

sfEOF:
	UserGate get_file_size_nr
	add eax,[ebp].sfDistanceLow
	UserGate set_file_pos_nr

sfValidate:
	mov fs:pvLastError,0
	jnc short sfDone

sfFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	mov eax,-1
	jmp sfDone

sfDone:
	pop ebx
	pop ebp
	ret 16
SetFilePointer	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetEndOfFile
;
;       DESCRIPTION:    Set end of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetEndOfFile

seofHandle	EQU 8

SetEndOfFile	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp].seofHandle
	mov bx,ax
	xor ax,ax
	cmp eax,FILE_HANDLE
	mov eax,6
	jne seofFailed
;
	UserGate get_file_pos_nr
	UserGate set_file_size_nr
	mov eax,1
	jnc seofDone

seofFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

seofDone:
	pop ebx
	pop ebp
	ret 4
SetEndOfFile	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadFile
;
;       DESCRIPTION:    Read from file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadFile

rfHandle	EQU 8
rfBuf		EQU 12
rfCount		EQU 16
rfRead		EQU 20
rfOverlap	EQU 24

ReadFile Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov eax,[ebp].rfHandle
	mov bx,ax
	xor ax,ax
	cmp eax,FILE_HANDLE
	je rfFile
	cmp eax,STD_HANDLE
	je rfConsole
	mov eax,6
	jmp rfFailed

rfConsole:
	mov edi,[ebp].rfBuf
	mov ecx,[ebp].rfCount
	call ReadConsole
	jmp rfCheck

rfFile:
	mov edi,[ebp].rfBuf
	mov ecx,[ebp].rfCount
	UserGate read_file_nr

rfCheck:
	jc short rfFailed
;
	mov ecx,[ebp].rfRead
	mov [ecx],eax
	mov eax,1
	jmp rfDone

rfFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

rfDone:
	pop edi
	pop ebx
	pop ebp
	ret 20
ReadFile Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetStdHandle
;
;       DESCRIPTION:    Get standard handles
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetStdHandle

gshHandle	EQU 8

GetStdHandle Proc near
	push ebp
	mov ebp,esp
;
	mov eax,[ebp].gshHandle
	neg eax
	sub eax,10
	jc short gshFailed

	cmp eax,3
	jnc short gshFailed
;
	add eax,STD_HANDLE
	jmp gshDone

gshFailed:
	mov eax,-1

gshDone:
	pop ebp
	ret 4
GetStdHandle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetStdHandle
;
;       DESCRIPTION:    Set standard handles
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetStdHandle

SetStdHandle Proc near
	mov eax,1
	ret 8
SetStdHandle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:          	GetFileSize
;
;       DESCRIPTION:    Get size of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetFileSize

gfsHandle	EQU 8
gfsSizeHigh	EQU 12

GetFileSize	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp].gfsHandle
	mov bx,ax
	xor ax,ax
	cmp eax,FILE_HANDLE
	mov eax,6
	jne gfsFailed
;
	UserGate get_file_size_nr
	jc gfsFailed
;
	mov ecx,[ebp].gfsSizeHigh
	or ecx,ecx
	jz gfsDone
;
	mov dword ptr [ecx],0
	jmp gfsDone

gfsFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	mov eax,-1

gfsDone:
	pop ebx
	pop ebp
	ret 8
GetFileSize	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:          	GetFileType
;
;       DESCRIPTION:    Get type of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetFileType

gftHandle	EQU 8

GetFileType	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp].gftHandle
	mov bx,ax
	xor ax,ax
	cmp eax,FILE_HANDLE
	je gftFile

	cmp eax,STD_HANDLE
	je gftConsole

gftConsole:
	mov eax,2
	jmp gftDone

gftFile:
	mov eax,1
	jmp gftDone

gftFailed:
	xor eax,eax
	jmp gftDone

gftDone:
	pop ebx
	pop ebp
	ret 4
GetFileType	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:          	CreateFile
;
;       DESCRIPTION:    Create a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CreateFileA
	public CreateFileW

winconin DB 'CONIN$',0
winconout DB 'CONOUT$',0

AccessTransl:
	DB	0
	DB	1
	DB  0
	DB  2

cfPath			EQU 8
cfAccess		EQU 12
cfShareMode		EQU 16
cfSecurityAttr	EQU 20
cfCreateDistr	EQU 24
cfFlagsAttr		EQU 28
cfTemplateFile	EQU 32

;
; EDI = Path in
; EAX = handle out if found
;

GetConsole Proc near
	push esi
;
	cld
	push edi
	mov esi,edi
	mov edi,OFFSET winconin
	mov eax,STD_IN
	mov ecx,7
	repe cmpsb
	pop edi
	clc
	je gcDone
;
	push edi
	mov esi,edi
	mov edi,OFFSET winconout
	mov eax,STD_OUT
	mov ecx,8
	repe cmpsb
	pop edi
	clc
	je gcDone
;
	stc

gcDone:
	pop esi
	ret
GetConsole Endp

;
; EDI path

CreateFile	Proc near
	mov eax,[ebp].cfCreateDistr
	cmp eax,1
	je cfNew
;
	cmp eax,2
	je cfAlways
	cmp eax,3
	je ofExisting
	cmp eax,4
	je ofAlways
	cmp eax,5
	je cfTruncate
	mov eax,6
	jmp cfFail

cfNew:
	mov eax,[ebp].cfAccess
	rol eax,2
	and eax,3
	mov cl,byte ptr [eax].AccessTransl
	UserGate open_file_nr
	jc cfAlways
	UserGate close_file_nr
	mov eax,80
	jmp cfFail

cfAlways:
	mov ecx,[ebp].cfFlagsAttr
	and ecx,4
	UserGate create_file_nr
	jmp cfValidate

ofExisting:
	mov eax,[ebp].cfAccess
	rol eax,2
	and eax,3
	mov cl,byte ptr [eax].AccessTransl
	UserGate open_file_nr
	jmp cfValidate

ofAlways:
	mov eax,[ebp].cfAccess
	rol eax,2
	and eax,3
	mov cl,byte ptr [eax].AccessTransl
	UserGate open_file_nr
	jnc cfOk
	jmp cfAlways

cfTruncate:
	mov eax,[ebp].cfAccess
	rol eax,2
	and eax,3
	mov cl,byte ptr [eax].AccessTransl
	UserGate open_file_nr
	jc cfFail
	xor eax,eax
	UserGate set_file_size_nr

cfValidate:
	jc cfFail

cfOk:
	mov eax,FILE_HANDLE
	mov ax,bx
	jmp cfDone

cfFail:
	movzx eax,al
	mov fs:pvLastError,eax
	mov eax,-1

cfDone:
	ret
CreateFile	Endp
	
CreateFileW	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
	mov ecx,256
	sub esp,ecx
;
	mov esi,[ebp].cfPath
	mov edi,esp
	call Wide2Ansi
	jc short cfwError
;
	call GetConsole
	jnc cfwDone
;
	call CreateFile
	jmp cfwDone

cfwError:
	movzx eax,al
	mov fs:pvLastError,eax
	mov eax,-1

cfwDone:
	add esp,256
	pop edi
	pop ebx
	pop ebp
	ret 28
CreateFileW	Endp
	
CreateFileA	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp].cfPath
	call GetConsole
	jnc cfaDone
;
	call CreateFile

cfaDone:
	pop edi
	pop ebx
	pop ebp
	ret 28
CreateFileA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:          	CloseHandle
;
;       DESCRIPTION:    Close a handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CloseHandle

chHandle	EQU 8

CloseHandle	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp].chHandle
	mov bx,ax
	xor ax,ax
	cmp eax,FILE_HANDLE
	mov eax,6
	jne chFailed
;
	UserGate close_file_nr
	jc chFailed
	mov eax,1
	jmp gftDone

chFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax
	jmp chDone

chDone:
	pop ebx
	pop ebp
	ret 4
CloseHandle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:          	GetFileAttributes
;
;       DESCRIPTION:    Get file attributes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetFileAttributesA
	public GetFileAttributesW

gfaPath	EQU 8

GetFileAttributesW	Proc near
	push ebp
	mov ebp,esp
	push edi
	mov ecx,256
	sub esp,ecx
;
	mov esi,[ebp].gfaPath
	mov edi,esp
	call Wide2Ansi
	jc short gfawFailed
;
	UserGate get_file_attribute_nr
	jc gfawFailed
;
	mov eax,80h
	and ecx,037h
	jz short gfawDone
;
	mov eax,ecx
	jmp gfawDone

gfawFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	mov eax,-1

gfawDone:
	add esp,256
	pop edi
	pop ebp
	ret 4
GetFileAttributesW	Endp

GetFileAttributesA	Proc near
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp].gfaPath
	UserGate get_file_attribute_nr
	jc gfaaFailed
;
	mov eax,80h
	and ecx,037h
	jz short gfaaDone
;
	mov eax,ecx
	jmp gfaaDone

gfaaFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	mov eax,-1

gfaaDone:
	pop edi
	pop ebp
	ret 4
GetFileAttributesA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:          	SetFileAttributes
;
;       DESCRIPTION:    Set file attributes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetFileAttributesA
	public SetFileAttributesW

sfaPath	EQU 8
sfaAttr	EQU 12

SetFileAttributesW	Proc near
	push ebp
	mov ebp,esp
	push edi
	mov ecx,256
	sub esp,ecx
;
	mov esi,[ebp].sfaPath
	mov edi,esp
	call Wide2Ansi
	jc short sfawFailed
;
	mov ecx,[ebp].sfaAttr
	and ecx,37h
	UserGate set_file_attribute_nr
	jc sfawFailed
;
	mov eax,1
	jmp sfawDone

sfawFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

sfawDone:
	add esp,256
	pop edi
	pop ebp
	ret 8
SetFileAttributesW	Endp

SetFileAttributesA	Proc near
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp].sfaPath
	mov ecx,[ebp].sfaAttr
	and ecx,37h
	UserGate set_file_attribute_nr
	jc sfaaFailed
;
	mov eax,1
	jmp sfaaDone

sfaaFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

sfaaDone:
	pop edi
	pop ebp
	ret 8
SetFileAttributesA	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:          	GetFileTime
;
;       DESCRIPTION:    Get file time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetFileTime

gftimHandle		EQU 8
gftimCreateTime	EQU 12
gftimLastAccess	EQU 16
gftimLastWrite	EQU 20

GetFileTime	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp].gftimHandle
	mov bx,ax
	xor ax,ax
	cmp eax,FILE_HANDLE
	mov eax,6
	jne gftimFailed
;
	UserGate get_file_time_nr
	jc gftimFailed
;
	mov ecx,[ebp].gftimLastWrite
	or ecx,ecx
	jz gftimLastWriteDone
;
	mov [ecx],eax
	mov [ecx+4],edx

gftimLastWriteDone:
	mov ecx,[ebp].gftimLastAccess
	or ecx,ecx
	jz gftimLastAccessDone
;
	mov [ecx],eax
	mov [ecx+4],edx

gftimLastAccessDone:
	mov ecx,[ebp].gftimCreateTime
	or ecx,ecx
	jz gftimCreateTimeDone
;
	mov [ecx],eax
	mov [ecx+4],edx

gftimCreateTimeDone:
	mov eax,1
	jmp gftimDone

gftimFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax
	jmp gftimDone

gftimDone:
	pop ebx
	pop ebp
	ret 16
GetFileTime	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:          	SetFileTime
;
;       DESCRIPTION:    Set file time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetFileTime

sftimHandle		EQU 8
sftimCreateTime	EQU 12
sftimLastAccess	EQU 16
sftimLastWrite	EQU 20

SetFileTime	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp].sftimHandle
	mov bx,ax
	xor ax,ax
	cmp eax,FILE_HANDLE
	mov eax,6
	jne sftimFailed
;
	mov ecx,[ebp].sftimLastWrite
	or ecx,ecx
	jz sftimOk
;
	mov eax,[ecx]
	mov edx,[ecx+4]
	UserGate set_file_time_nr
	jc sftimFailed

sftimOk:
	mov eax,1
	jmp sftimDone

sftimFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax
	jmp sftimDone

sftimDone:
	pop ebx
	pop ebp
	ret 16
SetFileTime	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:          	CreateFileMapping
;
;       DESCRIPTION:    Create a file mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CreateFileMappingA

cfmFile			EQU 8
cfmSec			EQU 12
cfmProtect		EQU 16
cfmMaxSizeHigh	EQU 20
cfmMaxSizeLow	EQU 24
cfmName			EQU 28

CreateFileMappingA Proc near
	push ebp
	mov ebp,esp
;
	mov ebx,[ebp].cfmFile
	xor eax,eax
;
	pop ebp
	ret 24
CreateFileMappingA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:          	MapViewOfFile
;
;       DESCRIPTION:    Map view of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public MapViewOfFile

mvofHandle		EQU 8
mvofAccess		EQU 12
mvofOffsetHigh	EQU 16
mvofOffsetLow	EQU 20
mvofSize		EQU 24

MapViewOfFile Proc near
	push ebp
	mov ebp,esp
;
	int 3
	mov ebx,[ebp].mvofHandle
	xor eax,eax
;
	pop ebp
	ret 20
MapViewOfFile Endp

	END
