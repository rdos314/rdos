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
; INI.ASM
; Ini file handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME ini

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\handle.inc

ini_handle_seg	STRUC

ih_hheader	handle_header <>

ih_sel			DW ?
ih_file_handle	DW ?
ih_base			DD ?
ih_size		    DD ?
ih_mmap_handle	DW ?

ini_handle_seg	ENDS

ini_sect_seg    STRUC

is_prev			DD ?
is_next			DD ?
is_file_pos     DD ?
is_file_size    DD ?
is_data         DD ?

ini_sect_seg    ENDS

ini_file_seg STRUC

if_prev			DW ?
if_next			DW ?
if_section      section_typ <>
if_list			DD ?
if_usage		DW ?
if_file_sel     DW ?
if_access       DB ?

ini_file_seg ENDS

ini_sys_seg  STRUC

is_section      section_typ <>

is_sys_sel      DW ?
is_ini_list     DW ?

ini_sys_seg  ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

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

DefaultSysIniName	DB 'z:\system.ini', 0
SysIniVar	DB 'SYSINI', 0

OpenSystemIni	Proc near
	push ds
	push es
	push eax
	push si
	push di
;
	OpenSysEnv
;
	mov eax,1000h
	AllocateGlobalMem
	xor di,di
;
	mov ax,cs
	mov ds,ax
	mov si,OFFSET SysIniVar
;
	FindEnvVar
	pushf
	CloseEnv
	popf
	jc open_sys_ini_test_file
;
	mov cl,0
	OpenFile

open_sys_ini_test_file:
	pushf
	FreeMem
	popf
	jnc open_sys_ini_done
;	
	mov ax,cs
	mov es,ax
	mov di,OFFSET DefaultSysIniName
	OpenFile

open_sys_ini_done:
	pop di
	pop si
	pop eax
	pop es
	pop ds
	ret
OpenSystemIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MapIni
;
;       DESCRIPTION:    Memory map ini file
;
;		PARAMETERS:		DS:BX		handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapIni	Proc near
	push ds
	push es
	pushad
;
	mov si,bx
;
	mov bx,[si].ih_file_handle
	GetFileSize
	and ax,0F000h
	add eax,1000h
	AllocateLocalLinear
	sub edx,local_page_linear
	mov ds:[si].ih_base,edx
	mov ds:[si].ih_size,eax	
;
	CreateFileMapping
	mov ds:[si].ih_mmap_handle,bx
;
	mov ax,flat_data_sel
	mov es,ax
	mov edi,ds:[si].ih_base
	mov ecx,ds:[si].ih_size
	UserGateForce32 map_view_nr
;	
	popad
	pop es
	pop ds
	ret
MapIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnmapIni
;
;       DESCRIPTION:    Memory unmap ini file
;
;		PARAMETERS:		DS:BX		handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnmapIni	Proc near
	push ds
	push es
	pushad
;
	mov si,bx
;
	mov bx,ds:[si].ih_mmap_handle
	UnmapView
	CloseMapping
	mov ds:[si].ih_mmap_handle,0
;
	mov edx,ds:[si].ih_base
	or edx,edx
	jz uiNoMem
;
	add edx,local_page_linear
	mov ecx,ds:[si].ih_size
	FreeLinear

uiNoMem:
	popad
	pop es
	pop ds
	ret
UnmapIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateIniSel
;
;       DESCRIPTION:    Create ini selector
;
;		PARAMETERS:		BX			original file handle
;
;		RETURNS:		DS			ini selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIniSel	proc near
	push es
	push eax
	push cx
;
	mov eax,SIZE ini_file_seg
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
;
	InitSection ds:if_section
	GetFileInfo
	mov ds:if_access,cl
	mov ds:if_file_sel,ax
	mov ds:if_usage,0
	mov ds:if_list,0
;
	pop cx
	pop eax
	pop es
	ret
CreateIniSel	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:         	FreeIniSel
;
;       DESCRIPTION:    Free ini selector (if usage permits)
;
;		PARAMETERS:		DS			ini selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeIniSel	proc near
	push es
	push ax
	push cx
;
	sub ds:if_usage,1
	jnz fisDone
;
	mov cx,ds
	mov ax,inifile_sys_sel
	mov ds,ax
	cmp cx,ds:is_sys_sel
	jne fisPriv
;
	EnterSection ds:is_section
	mov es,cx
	mov ds:is_sys_sel,0
	FreeMem
	LeaveSection ds:is_section
	jmp fisDone

fisPriv:
	EnterSection ds:is_section
	mov es,cx
	push si
	push di
	push ds
	mov di,es:if_next
	cmp di,ds:is_ini_list
	mov ds:is_ini_list,di
	mov si,es:if_prev
	mov ds,di
	mov ds:if_prev,si
	mov ds,si
	mov ds:if_next,di
	pop ds
	pop di
	pop si
	jne fisUncache
;
	mov ds:is_ini_list,0

fisUncache:
	FreeMem
	LeaveSection ds:is_section

fisDone:
	pop cx
	pop ax
	pop es
	ret
FreeIniSel	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateIniHandle
;
;       DESCRIPTION:    Create ini handle
;
;		PARAMETERS:		DS			ini selector
;						BX			"original" file handle or 0
;
;		RETURNS:		BX			ini handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIniHandle	proc near
	push ds
	push ax
	push cx
;
	inc ds:if_usage
	or bx,bx
	jnz cihNew
;
	mov cl,ds:if_access
	mov ax,ds:if_file_sel
	DuplFileInfo

cihNew:
	push ds
	push bx
	mov cx,SIZE ini_handle_seg
	AllocateHandle
	pop ax
	mov [bx].ih_file_handle,ax
	pop ax
	mov [bx].ih_sel,ax
	mov [bx].hh_sign,INI_HANDLE
	call MapIni
	mov bx,[bx].hh_handle
;
	pop cx
	pop ax
	pop ds
	ret
CreateIniHandle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateSysIni
;
;       DESCRIPTION:    Create system ini object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSysIni	Proc near
	push ds
	push es
	push ax
	push bx
;
	call OpenSystemIni
	jc csiDone
;
	call CreateIniSel
;
	mov ax,inifile_sys_sel
	mov es,ax
	mov es:is_sys_sel,ds

csiDone:
	pop bx
	pop ax
	pop es
	pop ds
	ret
CreateSysIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenSysIni
;
;       DESCRIPTION:    Open system ini file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_sys_ini_name	DB 'Open Sys Ini', 0

open_sys_ini	Proc far
	push ds
	push es
	push ax
;
	xor bx,bx
	mov ax,inifile_sys_sel
	mov ds,ax
	EnterSection ds:is_section
;
	mov ax,ds:is_sys_sel
	or ax,ax
	jnz osiCreateHandle
;
	call OpenSystemIni
	jc osiDone
;
	call CreateIniSel
;
	mov ax,inifile_sys_sel
	mov es,ax
	mov es:is_sys_sel,ds

osiCreateHandle:
	mov ax,inifile_sys_sel
	mov ds,ax
	LeaveSection ds:is_section
;
	mov ds,ds:is_sys_sel
	call CreateIniHandle
	clc

osiDone:
	pop ax
	pop es
	pop ds
	retf32
open_sys_ini	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CloseIni
;
;		DESCRIPTION:	Close ini
;
;		PARAMETERS:		BX			INI HANDLE
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_ini_name	DB 'Close Ini', 0

close_ini	Proc far
	push ds
	push bx
;
	mov ax,INI_HANDLE
	DerefHandle
	jc ciDone
;
	call UnmapIni
	push ds:[bx].ih_file_handle
	mov ds,ds:[bx].ih_sel
	call FreeIniSel
	pop bx
	CloseFile

ciDone:
	pop bx
	pop ds
	retf32
close_ini	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindIniSection
;
;       DESCRIPTION:    Find section in .ini file
;
;		PARAMETERS:		BX			ini file handle
;						DS:ESI		Section to find
;						ES:EDI		Buffer
;
;		RETURNS:		EAX			Size of section
;						EDX			File position
;						NC			Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindIniSection	Proc near
	mov eax,100h
	AllocateGlobalMem
	xor edx,edx
FindIniSectionNext:
	mov eax,edx
	SetFilePos
	mov cx,1000h
	xor edi,edi
	ReadFile
	or ax,ax
	stc
	jz FindIniSectionDone
	
FindIniSectionScan:
	mov cx,ax
	mov al,'['
	repne scasb
	add edx,edi
	cmp byte ptr es:[di-1],'['
	je FindIniSectionTest
;
	mov eax,edx
	SetFilePos
	mov cx,1000h
	xor di,di
	ReadFile
	or ax,ax
	stc
	jnz FindIniSectionScan
	jmp FindIniSectionDone
	
FindIniSectionTest:
	mov eax,edx
	SetFilePos
	mov cx,1000h
	xor di,di
	ReadFile
	or ax,ax
	stc
	jz FindIniSectionDone
;
	push esi
	repe cmps byte ptr ds:[esi],es:[edi]
	dec esi
	dec edi
	lods byte ptr es:[esi]
	or al,al
	jne FindIniSectionWrongName
;
	mov al,es:[di]
	cmp al,']'
	jne FindIniSectionWrongName
;
	pop esi
	inc di
	add edx,edi
	push edx
FindIniSectionSize:
	mov eax,edx
	SetFilePos
	mov cx,1000h
	xor edi,edi
	ReadFile
	mov cx,ax
	mov al,'['
	repne scasb
	add edx,edi
	dec edx
	or cx,cx
	je FindIniSectionSize
;
	mov eax,edx
	pop edx
	sub eax,edx
	clc
	jmp FindIniSectionDone	
	
FindIniSectionWrongName:
	pop esi
	add edx,edi
	inc edx
	jmp FindIniSectionNext
	
FindIniSectionDone:
	pushf
	FreeMem
	popf
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
;						DS:ESI		Key to find
;						EDX			File position
;						EAX			Size of section
;						ES:EDI		Key value
;						NC			Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindIniKey	Proc near
	mov ecx,eax
	AllocateGlobalMem
	mov eax,edx
	SetFilePos
	xor edi,edi
	ReadFile	
	
FindIniKeyControl:
	mov al,es:[edi]
	cmp al,0Dh
	je FindIniKeyControlPass
	cmp al,0Ah
	je FindIniKeyControlPass
	cmp al,' '
	je FindIniKeyControlPass
	cmp al,9
	jne FindIniKeyScan
	
FindIniKeyControlPass:
	inc edi
	sub ecx,1
	jne FindIniKeyControl
	stc
	jmp FindIniKeyDone
	
FindIniKeyScan:
	push esi
	repe cmps byte ptr ds:[esi],es:[edi]
	dec esi
	dec edi
	inc ecx
	lods byte ptr ds:[esi]
	pop esi
	or al,al
	jne FindIniKeyWrongName
	
FindIniKeySpacePass:
	mov al,es:[edi]
	cmp al,'='
	je FindIniKeyCorrectName
	cmp al,' '
	je FindIniKeySpacePass
	cmp al,9
	jne FindIniKeyWrongName
;	
	inc edi
	sub ecx,1
	jc FindIniKeyDone
	jmp FindIniKeySpacePass
	
FindIniKeyWrongName:
	mov al,es:[edi]
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
;		PARAMETERS:		ES:DI	String
;						(E)AX	Size of section
;						AX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIniInt	PROC near
	push bx
	mov bx,ax
	xor ax,ax
	xor ch,ch
GetIniIntPass:
	mov cl,es:[di]
	inc di
	sub bx,1
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
	dec di
	inc bx
GetIniIntLoop:
	mov cl,es:[di]
	sub cl,30h
	jc GetIniIntEnd
	cmp cl,0Ah
	jnc GetIniIntEnd
	mov dx,10
	mul dx
	add al,cl
	adc ah,0
	inc di
	sub bx,1
	jnz GetIniIntLoop
GetIniIntEnd:
	test ch,80h
	jz GetIniIntPos
	neg ax
GetIniIntPos:
	pop bx
	ret
GetIniInt	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetProfileInt
;
;       DESCRIPTION:    Get .ini file integer
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Default		default value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetProfileInt

GetProfileInt	Proc far
	push bp
	mov bp,sp
	push ds
	push es
	push si
	push di
	call OpenSystemIni
	lds si,[bp+12]
	call FindIniSection
	jc GetProfileIntSectionFail
	lds si,[bp+8]
	call FindIniKey
	jc GetProfileIntKeyFail
	call GetIniInt
	FreeMem
	jmp GetProfileIntEnd
GetProfileIntKeyFail:
	FreeMem
GetProfileIntSectionFail:
	mov ax,[bp+6]
GetProfileIntEnd:
	push ax
	CloseFile
	pop ax
	pop di
	pop si
	pop es
	pop ds
	pop bp
	ret 10
GetProfileInt	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetProfileString
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

		public GetProfileString

GetProfileString	Proc far
	push bp
	mov bp,sp
	push ds
	push es
	push si
	push di
	call OpenSystemIni
	lds si,[bp+20]
	call FindIniSection
	jc GetProfileStringSectionFail
	lds si,[bp+16]
	call FindIniKey
	jc GetProfileStringKeyFail
	mov cx,ax
	xor dx,dx
	cmp cx,[bp+6]
	jc GetProfileStringWhole
	mov cx,[bp+6]
	dec cx
GetProfileStringWhole:
	push es
	mov ax,es
	mov ds,ax
	mov si,di
	les di,[bp+8]
GetProfileStringCopy:
	lodsb
	cmp al,0Dh
	je GetProfileStringCopied
	cmp al,0Ah
	je GetProfileStringCopied
	inc dx
	stosb
	loop GetProfileStringCopy
GetProfileStringCopied:
	xor ax,ax
	stosb
	mov ds,ax
	pop es
	FreeMem
	jmp GetProfileStringEnd
GetProfileStringKeyFail:
	FreeMem
GetProfileStringSectionFail:
	lds si,[bp+12]
	les di,[bp+8]
	mov cx,[bp+6]
	dec cx
	xor dx,dx
GetProfileStringDefault:
	lodsb
	stosb
	or al,al
	je GetProfileStringEnd
	inc dx
	loop GetProfileStringDefault
GetProfileStringEnd:
	CloseFile
	mov ax,dx
	pop di
	pop si
	pop es
	pop ds
	pop bp
	ret 18
GetProfileString	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteProfileInt
;
;       DESCRIPTION:    Write .ini file string
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Value		value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public WriteProfileString

WriteProfileString	Proc far
	xor ax,ax
	ret 12
WriteProfileString	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init_thread
;
;		DESCRIPTION:	Create thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_thread_name	DB 'Ini File', 0

test_thread:
	int 3
	OpenSysIni
	mov dx,bx
	OpenSysIni
	CloseIni
	mov bx,dx
	CloseIni

init_thread	Proc far
	push ds
	push es
	pushad
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET test_thread
	mov di,OFFSET test_thread_name
	mov ax,3
	mov cx,256
	CreateThread
;
	popad
	pop es
	pop ds
init_thread	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Delete_handle
;
;		DESCRIPTION:	Delete handle (called from handle module)
;
;		PARAMETERS:		BX			INI HANDLE
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle	Proc far
	push ds
	push bx
;
	mov ax,INI_HANDLE
	DerefHandle
	jc delete_handle_done
;
	push ds
	mov ds,ds:[bx].ih_sel
	call FreeIniSel
	pop ds

delete_handle_done:
	pop bx
	pop ds
	ret
delete_handle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           Init
;
;       DESCRIPTION:    Init driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	push ds
	push es
	pusha
;
	mov bx,inifile_code_sel
	InitDevice
;
	mov eax,SIZE ini_sys_seg
	mov bx,inifile_sys_sel
	AllocateFixedSystemMem
	InitSection es:is_section
	mov es:is_sys_sel,0
	mov es:is_ini_list,0
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_thread
	HookInitTasking
;
	mov si,OFFSET open_sys_ini
	mov di,OFFSET open_sys_ini_name
	xor dx,dx
	mov ax,open_sys_ini_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET close_ini
	mov di,OFFSET close_ini_name
	xor dx,dx
	mov ax,close_ini_nr
	RegisterBimodalUserGate
;
	mov di,OFFSET delete_handle
	mov ax,INI_HANDLE
	RegisterHandle
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init

