;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; CFG2ROM.ASM
; Rom file creator for RDOS. Uses a .CFG file for settings
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  CFG2ROM

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.model Small

ConfigSize = 2000h

GateSize = 16

INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os\system.def

exeh_seg	SEGMENT AT 0
exeh_signature		DW ?
exeh_size_lsb		DW ?
exeh_size_msb		DW ?
exeh_reloc_ant		DW ?
exeh_size_header	DW ?
exeh_minalloc		DW ?
exeh_maxalloc		DW ?
exeh_ss				DW ?
exeh_sp				DW ?
exeh_checksum		DW ?
exeh_ip				DW ?
exeh_cs				DW ?
exeh_reloc_offs		DW ?
exeh_ov_nr			DW ?
exeh_seg	ENDS

file_header	STRUC

file_base		DB 8 DUP(?)
file_ext		DB 3 DUP(?)
file_attrib		DB ?
file_resv		DB 10 DUP(?)
file_time		DW ?
file_date		DW ?
file_cluster	DW ?
file_size		DD ?

file_header	ENDS

.stack
.data

cfg_handle  DW ?
rom_handle  DW ?

driver_name		DB 128 DUP(?)
driver_param	DB 128 DUP(?)

config_text DB ConfigSize DUP(?)

.fardata Buffer

RdosHeader  rdos_header <>
buf         DB 0FFF0h DUP(0)

.fardata DTA

DTA_space	DB 80 DUP(?)

.code

cfg_error   DB 'cannot find .cfg file',0Dh,0Ah,24h
rom_error   DB 'cannot create .rom file',0Dh,0Ah,24h
cfg_io_error DB 'read error from .cfg file',0Dh,0Ah,24h
cfg_size_error DB 'to large .cfg file',0Dh,0Ah,24h
kernel_error DB 'cannot find kernel ',24h
shutdown_error DB 'cannot find shutdown ',24h
font_error  DB 'cannot find font-file ',24h
device_error DB 'cannot find device-driver ',24h
file_error  DB 'cannot find file ',24h
boot_error  DB 'cannot file boot.exe', 0Dh, 0Ah, 24h

crlf        DB 0Dh,0Ah,24h

.386c

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Log
;
;		DESCRIPTION:	Log error
;
;       PARAMETERS:     DX      offset to error message
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Log Proc near
    push ds
    pushf
    push ax
    mov ax,cs
    mov ds,ax
    mov ah,9
	int 21h
    pop ax
    popf
    pop ds
    ret
Log Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteFileName
;
;		DESCRIPTION:	Write name of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteFileName Proc near
    push ds
    pushf
    push ax
    mov si,OFFSET driver_name
WriteFileNameNext:
    lodsb
    or al,al
    jz WriteFileNameDone
    mov dl,al
    mov ah,2
    int 21h
    jmp WriteFileNameNext
WriteFileNameDone:
    pop ax
    popf
    pop ds
    ret
WriteFileName Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CalcCrc
;
;		DESCRIPTION:	Calculate CRC for one byte
;
;       PARAMETERS:     AL      Byte
;                       DS:SI   Address till data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcCrc Proc near
    push cx
    mov cl,[si]
    inc si
	xor ah,cl
;
	mov cx,1021h
	shl ax,1
	jnc no_xor0
	xor ax,cx
no_xor0:
	shl ax,1
	jnc no_xor1
	xor ax,cx
no_xor1:
	shl ax,1
	jnc no_xor2
	xor ax,cx
no_xor2:
	shl ax,1
	jnc no_xor3
	xor ax,cx
no_xor3:
	shl ax,1
	jnc no_xor4
	xor ax,cx
no_xor4:
	shl ax,1
	jnc no_xor5
	xor ax,cx
no_xor5:
	shl ax,1
	jnc no_xor6
	xor ax,cx
no_xor6:
	shl ax,1
	jnc no_xor7
	xor ax,cx
no_xor7:
    pop cx
    ret
CalcCrc Endp

    assume ds:_data

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateDosFileName
;
;		DESCRIPTION:	Create dos file name in DTA area for Windows NT
;
;       PARAMETERS:     ES:BX	DTA BUFFER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDosFileName Proc near
	push cx
	push si
	push di
;
	lea di,[bx+1]
	lea si,[bx+1Eh]
	mov cx,8
CreateDosBaseName:
	lods byte ptr es:[si]
	cmp al,'.'
	je CreateDosBaseDone
	or al,al
	jz CreateDosBaseDone
	stosb
	loop CreateDosBaseName
CreateDosBaseDone:
	or al,al
	jne CreateDosBasePad
	dec si
CreateDosBasePad:
	mov al,' '
	rep stosb
	mov cx,3
CreateDosExtName:
	lods byte ptr es:[si]
	or al,al
	je CreateDosExtDone
	cmp al,'.'
	je CreateDosExtName
	stosb
	loop CreateDosExtName
CreateDosExtDone:
	mov al,' '
	rep stosb
;
	pop di
	pop si
	pop cx
	ret
CreateDosFileName Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OutputFile
;
;		DESCRIPTION:	Write buffer to ROM fil
;
;       PARAMETERS:     AX      Section typ
;                       ECX     Size of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputFile  Proc near
    push ds
    pusha
    mov bx,rom_handle
    mov dx,SEG Buffer
    mov ds,dx
        assume ds:Buffer
    mov RdosHeader.crc,0
    mov RdosHeader.sign,RdosSign
    mov RdosHeader.typ,ax
    xor ax,ax
	jcxz OutputFileCrcDone
    push cx
    mov si,OFFSET buf
OutputFileCrcLoop:
    call CalcCrc
    loop OutputFileCrcLoop
    pop cx
OutputFileCrcDone:
    mov RdosHeader.crc,ax
;
    add ecx,SIZE RdosHeader
    mov RdosHeader.len,ecx
    xor dx,dx
    mov ah,40h
    int 21h
    popa
        assume ds:_data
    pop ds
    ret
OutputFile  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OutputEmptyHeader
;
;		DESCRIPTION:	Write empty header to ROM fil
;
;       PARAMETERS:     AX      Section typ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputEmptyHeader  Proc near
    push ds
    pusha
    mov ecx,SIZE RdosHeader
    mov bx,rom_handle
    mov dx,SEG Buffer
    mov ds,dx
        assume ds:Buffer
    mov RdosHeader.crc,0
    mov RdosHeader.sign,RdosSign
    mov RdosHeader.typ,ax
    mov RdosHeader.len,SIZE RdosHeader
    xor dx,dx
    mov ah,40h
    int 21h
    popa
        assume ds:_data
    pop ds
    ret
OutputEmptyHeader  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OutputBlock
;
;		DESCRIPTION:	Write a block to ROM fil
;
;       PARAMETERS:     AX      Input CRC
;                       CX      Size of block
;
;       RETURNS:        AX      Output CRC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputBlock  Proc near
    push ds
    push bx
    push si
    mov bx,rom_handle
    mov dx,SEG Buffer
    mov ds,dx
    push cx
    mov si,OFFSET buf
OutputBlockCrcLoop:
    call CalcCrc
    loop OutputBlockCrcLoop
    pop cx
;
    push ax
    mov dx,OFFSET buf
    mov ah,40h
    int 21h
    pop ax
        assume ds:_data
    pop si
    pop bx
    pop ds
    ret
OutputBlock  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OutputFinalHeader
;
;		DESCRIPTION:	Write final header to ROM fil
;
;       PARAMETERS:     AX      Crc
;                       ECX     Size of data part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputFinalHeader  Proc near
    push ds
    pusha
    mov bx,rom_handle
    push ax
    push ecx
;
    add ecx,SIZE RdosHeader
    neg ecx
    push ecx
    pop dx
    pop cx
    mov ax,4201h
    int 21h
    push dx
    push ax
;
    mov cx,SIZE RdosHeader
    mov dx,SEG Buffer
    mov ds,dx
        assume ds:Buffer
    xor dx,dx
    mov ah,3Fh
    int 21h
;
    pop dx
    pop cx
    mov ax,4200h
    int 21h
;
    pop ecx
    pop ax
	add ecx,SIZE RdosHeader
    mov RdosHeader.crc,ax
    mov RdosHeader.len,ecx
    mov cx,SIZE RdosHeader
    xor dx,dx
    mov ah,40h
    int 21h
;
    xor dx,dx
    xor cx,cx
    mov ax,4202h
    int 21h
;
    popa
        assume ds:_data
    pop ds
    ret
OutputFinalHeader  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadKernel
;
;		DESCRIPTION:	Load OS kernel
;
;		PARAMETERS:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadKernel	PROC near
	push ds
	push es
	push si
	push di
;
	mov dx,OFFSET driver_name
	mov ax,3D00h
	int 21h
    jnc load_kernel_ok
    mov dx,OFFSET kernel_error
    call Log
    call WriteFileName
    mov dx,OFFSET crlf
    call Log
    jmp load_kernel_done
load_kernel_ok:
	mov bx,ax
	push ds
	mov ax,SEG Buffer
	mov ds,ax
        assume ds:Buffer
	xor dx,dx
	mov cx,1Ch
	mov ah,3Fh
	int 21h
	push bx
    mov ax,ds:exeh_ip
    mov bx,OFFSET buf
    mov [bx].init_ip,ax
	xor eax,eax
	xor ebx,ebx
	mov ax,ds:exeh_size_msb
	shl eax,5
	mov bx,ds:exeh_size_lsb
	shr bx,4
	inc bx
	add eax,ebx
	mov bx,ds:exeh_size_header
	mov dx,bx
	shl dx,4
	sub eax,ebx
	add ax,ds:exeh_minalloc
	pop bx
	push ax
	xor cx,cx
	mov ax,4200h
	int 21h
	pop cx
	shl cx,4
	mov dx,OFFSET buf + SIZE device_header
	mov ah,3Fh
	int 21h
    movzx ecx,ax
	add ecx,SIZE device_header
	mov ah,3Eh
	int 21h
        assume ds:_data
	pop ds
    mov ax,RdosKernel
    call OutputFile
load_kernel_done:
	pop di
	pop si
	pop es
	pop ds
	ret
LoadKernel	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadShutDown
;
;		DESCRIPTION:	Shut-down device driver
;
;		PARAMETERS:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadShutDown	PROC near
	push ds
	push es
	push si
	push di
;
	mov dx,OFFSET driver_name
	mov ax,3D00h
	int 21h
    jnc load_shutdown_ok
    mov dx,OFFSET shutdown_error
    call Log
    call WriteFileName
    mov dx,OFFSET crlf
    call Log
    jmp load_shutdown_done
load_shutdown_ok:
	mov bx,ax
	push ds
	mov ax,SEG Buffer
	mov ds,ax
        assume ds:Buffer
	xor dx,dx
	mov cx,1Ch
	mov ah,3Fh
	int 21h
	push bx
    mov ax,ds:exeh_ip
    mov bx,OFFSET buf
    mov [bx].init_ip,ax
	xor eax,eax
	xor ebx,ebx
	mov ax,ds:exeh_size_msb
	shl eax,5
	mov bx,ds:exeh_size_lsb
	shr bx,4
	inc bx
	add eax,ebx
	mov bx,ds:exeh_size_header
	mov dx,bx
	shl dx,4
	sub eax,ebx
	add ax,ds:exeh_minalloc
	pop bx
	push ax
	xor cx,cx
	mov ax,4200h
	int 21h
	pop cx
	shl cx,4
	mov dx,OFFSET buf + SIZE device_header
	mov ah,3Fh
	int 21h
    movzx ecx,ax
	add ecx,SIZE device_header
	mov ah,3Eh
	int 21h
        assume ds:_data
	pop ds
    mov ax,RdosShutDown
    call OutputFile
load_shutdown_done:
	pop di
	pop si
	pop es
	pop ds
	ret
LoadShutDown	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadFont
;
;		DESCRIPTION:	Load font file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadFont    Proc near
	push es
	push si
	push di
;
	mov dx,OFFSET driver_name
	mov ax,3D00h
	int 21h
    jnc load_font_ok
    mov dx,OFFSET font_error
    call Log
    call WriteFileName
    mov dx,OFFSET crlf
    call Log
    jmp load_font_done
load_font_ok:
	mov bx,ax
	mov bx,ax
    mov ax,RdosFont
    call OutputEmptyHeader
;
    xor ax,ax
	xor edi,edi
load_font_read_loop:
    push ds
    push ax
	mov ax,SEG Buffer
	mov ds,ax
	mov dx,OFFSET Buf
	mov cx,8000h
	mov ah,3Fh
	int 21h
    or ax,ax
    jz load_font_read_done
    movzx ecx,ax
    add edi,ecx
    pop ax
    pop ds
    call OutputBlock
    jmp load_font_read_loop
load_font_read_done:
	mov ah,3Eh
	int 21h
    pop ax
    pop ds
    mov ecx,edi
    call OutputFinalHeader
load_font_done:
	pop di
	pop si
	pop es
    ret
LoadFont    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadDevice
;
;		DESCRIPTION:	Load device file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadDevice    Proc near
	push es
	push si
	push di
;
	mov dx,OFFSET driver_name
	mov ax,3D00h
	int 21h
    jnc load_device_ok
    mov dx,OFFSET device_error
    call Log
    call WriteFileName
    mov dx,OFFSET crlf
    call Log
    jmp load_device_done
load_device_ok:
	mov bx,ax
	push ds
	mov ax,SEG Buffer
	mov ds,ax
        assume ds:Buffer
	xor dx,dx
	mov cx,1Ch
	mov ah,3Fh
	int 21h
	push bx
    mov ax,ds:exeh_ip
    mov bx,OFFSET buf
    mov [bx].init_ip,ax
	xor eax,eax
	xor ebx,ebx
	mov ax,ds:exeh_size_msb
	shl eax,5
	mov bx,ds:exeh_size_lsb
	shr bx,4
	inc bx
	add eax,ebx
	mov bx,ds:exeh_size_header
	mov dx,bx
	shl dx,4
	sub eax,ebx
	add ax,ds:exeh_minalloc
	pop bx
	push ax
	xor cx,cx
	mov ax,4200h
	int 21h
	pop cx
	shl cx,4
	mov dx,OFFSET buf + SIZE device_header
	mov ah,3Fh
	int 21h
    movzx ecx,ax
	add ecx,SIZE device_header
	mov ah,3Eh
	int 21h
        assume ds:_data
	pop ds
    mov ax,RdosDevice
    call OutputFile
load_device_done:
	pop di
	pop si
	pop es
    ret
LoadDevice    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadFile
;
;		DESCRIPTION:	Load file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadFile    Proc near
	push ds
	push es
	push esi
	push di
;
	mov dx,OFFSET driver_name
	mov ax,3D00h
	int 21h
    jnc load_file_ok
    mov dx,OFFSET file_error
    call Log
    call WriteFileName
    mov dx,OFFSET crlf
    call Log
    jmp load_file_done
load_file_ok:
	mov bx,ax
    mov ax,RdosFile
    call OutputEmptyHeader
;
	push ds
	mov ax,SEG DTA
	mov ds,ax
	mov dx,OFFSET DTA_Space
	mov ah,1Ah
	int 21h
	pop ds
;
	mov dx,OFFSET driver_name
	xor cx,cx
	mov ah,4Eh
	int 21h
;
    push ds
    push bx
	mov ax,SEG DTA
	mov es,ax
	mov bx,OFFSET DTA_Space
	call CreateDosFileName
    mov ax,SEG Buffer
    mov ds,ax
    mov di,OFFSET Buf
	mov eax,es:[bx+1]
	mov dword ptr [di].file_base,eax
	mov eax,es:[bx+5]
	mov dword ptr [di].file_base+4,eax
	mov ax,es:[bx+9]
	mov word ptr [di].file_ext,ax
	mov al,es:[bx+11]
	mov byte ptr [di].file_ext+2,al
	mov al,es:[bx+15h]
	mov [di].file_attrib,al
	mov ax,es:[bx+16h]
	mov [di].file_time,ax
	mov ax,es:[bx+18h]
	mov [di].file_date,ax
	mov eax,es:[bx+1Ah]
	mov [di].file_size,eax
    pop bx
    pop ds
;
    xor ax,ax
    mov cx,SIZE file_header
    call OutputBlock
    mov edi,SIZE file_header
load_file_read_loop:
    push ds
    push ax
	mov ax,SEG Buffer
	mov ds,ax
	mov dx,OFFSET Buf
	mov cx,8000h
	mov ah,3Fh
	int 21h
    or ax,ax
    jz load_file_read_done
    movzx ecx,ax
    add edi,ecx
    pop ax
    pop ds
    call OutputBlock
    jmp load_file_read_loop
load_file_read_done:
	mov ah,3Eh
	int 21h
    pop ax
    pop ds
    mov ecx,edi
    call OutputFinalHeader
load_file_done:
	pop di
	pop esi
	pop es
	pop ds
    ret
LoadFile    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadCommand
;
;		DESCRIPTION:	Load a command
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadCommand    Proc near
    push es
	push si
	push di
;
    mov ax,SEG Buffer
    mov es,ax
    xor ecx,ecx
    mov di,OFFSET buf
    mov si,OFFSET driver_name
command_load_more:
    lodsb
    or al,al
    jz command_load_done
    stosb
    inc ecx
    jmp command_load_more
command_load_done:
    stosb
    inc ecx
    mov ax,RdosCommand
    call OutputFile
;
	pop di
	pop si
    pop es
    ret
LoadCommand    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadDLL
;
;		DESCRIPTION:	Load DLL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadDLL    Proc near
    push es
	push si
	push di
;
	call LoadFile
	mov dx,OFFSET driver_name
	xor cx,cx
	mov ah,4Eh
	int 21h
;
    push ds
    push bx
	mov ah,2Fh
	int 21h
	inc bx
    mov ax,SEG Buffer
    mov ds,ax
	mov di,OFFSET buf
	mov cx,8
	xor dx,dx
dll_move_loop:
	mov al,es:[bx]
	cmp al,' '
	je dll_move_done
	mov [di],al
	inc bx
	inc di
	inc dx
	loop dll_move_loop
dll_move_done:
	xor al,al
	mov [di],al
	pop bx
	pop ds
	inc dx
	movzx ecx,dx
    mov ax,RdosDll
    call OutputFile
;
	pop di
	pop si
    pop es
    ret
LoadDLL    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadPath
;
;		DESCRIPTION:	Load PATH setting
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadPath    Proc near
	push es
	push si
	push di
;
	mov ax,SEG buffer
	mov es,ax
    xor ecx,ecx
    mov di,OFFSET buf
    mov si,OFFSET driver_name
load_path_more:
    lodsb
    or al,al
    jz load_path_done
    stosb
    inc ecx
    jmp load_path_more
load_path_done:
    stosb
    inc ecx
    mov ax,RdosPath
    call OutputFile
;
	pop di
	pop si
	pop es
	ret
LoadPath    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadSet
;
;		DESCRIPTION:	Load SET variable
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadSet    Proc near
    push es
	push si
	push di
;
	mov ax,SEG buffer
	mov es,ax
    xor ecx,ecx
    mov di,OFFSET buf
    mov si,OFFSET driver_name
load_set_more:
    lodsb
    or al,al
    jz load_set_done
    stosb
    inc ecx
    jmp load_set_more
load_set_done:
    stosb
    inc ecx
    mov ax,RdosSet
    call OutputFile
;
	pop di
	pop si
	pop es
    ret
LoadSet    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadDrivers
;
;		DESCRIPTION:	Load device-drivers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kernel_text DB 'kernel',0
shutdown_text DB 'shutdown',0
font_text DB 'font',0
device_text	DB 'device',0
dll_text DB 'dll',0
file_text DB 'file',0
run_text DB 'run',0
set_text DB 'set',0
path_text DB 'path',0

driver_tab:
kernel_l    DW OFFSET kernel_text,      OFFSET LoadKernel
shut_l		DW OFFSET shutdown_text,	OFFSET LoadShutDown
font_l		DW OFFSET font_text,		OFFSET LoadFont
device_l	DW OFFSET device_text,		OFFSET LoadDevice
file_l		DW OFFSET file_text,		OFFSET LoadFile
run_l		DW OFFSET run_text,			OFFSET LoadCommand
load_l		DW OFFSET dll_text,		    OFFSET LoadDLL
path_l		DW OFFSET path_text,		OFFSET LoadPath
set_l		DW OFFSET set_text,			OFFSET LoadSet
driver_end	DW 0

LoadDrivers	PROC near
    push ds
    push es
	mov bx,cfg_handle
	mov si,OFFSET config_text
init_driver_bypass1:
	lodsb
	or al,al
	jz init_driver_eot
	cmp al,' '
	je init_driver_bypass1
	cmp al,'	'
	je init_driver_bypass1
	cmp al,0Dh
	je init_driver_bypass1
	cmp al,0Ah
	je init_driver_bypass1
	dec si
	mov ax,cs
	mov es,ax
	mov di,OFFSET driver_tab
init_driver_next_text:
	mov ax,es:[di]
	or ax,ax
	je init_driver_bypass1
	mov cx,20h
	push si
	push di
	mov di,ax
	repe cmpsb
	dec di
	mov al,es:[di]
	or al,al
	pop di
	pop si
	jz init_driver_found
	add di,4
	jmp init_driver_next_text
init_driver_found:
	add si,1Fh
	sub si,cx
init_driver_bypass2:
	lodsb
	or al,al
	jz short init_driver_eot
	cmp al,'='
	je init_driver_bypass2
	cmp al,' '
	je init_driver_bypass2
	cmp al,'	'
	je init_driver_bypass2
	cmp al,0Ah
	je init_driver_bypass1
	cmp al,0Dh
	je init_driver_bypass1
	push di
	mov ax,ds
	mov es,ax
	mov di,OFFSET driver_name
	dec si
driver_name_move_next:
	lodsb
	or al,al
	je driver_name_moved
	cmp al,' '
	je driver_name_moved
	cmp al,'	'
	je driver_name_moved
	cmp al,0Dh
	je driver_name_moved
	cmp al,0Dh
	je driver_name_moved
	stosb
	jmp driver_name_move_next
driver_name_moved:
	xor al,al
	stosb
	dec si
	mov di,OFFSET driver_param
driver_bypass3:
	lodsb
	or al,al
	je driver_param_moved
	cmp al,' '
	je driver_bypass3
	cmp al,'	'
	je driver_bypass3
	cmp al,0Dh
	je driver_param_moved
	cmp al,0Ah
	je driver_param_moved
	dec si
driver_param_loop:
	lodsb
	or al,al
	je driver_param_moved
	cmp al,0Dh
	je driver_param_moved
	cmp al,0Ah
	je driver_param_moved
	stosb
	jmp driver_param_loop
driver_param_moved:
	xor al,al
	stosb
	dec si
	pop di
	call cs:word ptr [di+2]
	jmp init_driver_bypass1
init_driver_eot:
    mov ax,RdosEnd
	xor ecx,ecx
    call OutputFile
    pop es
    pop ds
	ret
LoadDrivers	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadConfig
;
;		DESCRIPTION:	Load config file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadConfig	PROC near
    mov bx,cfg_handle
	mov dx,OFFSET config_text
	mov ah,3Fh
	mov cx,ConfigSize
	int 21h
    jnc LoadConfigOk
    mov dx,OFFSET cfg_io_error
    call Log
    stc
    jmp LoadConfigDone
LoadConfigOk:
    cmp ax,cx
    clc
    jne LoadConfigDone
    mov dx,OFFSET cfg_size_error
    call Log
    stc
LoadConfigDone:
	ret
LoadConfig	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenFiles
;
;		DESCRIPTION:	Open input & output files
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

opn_name    EQU -128
opn_pos     EQU -130

OpenFiles   Proc near
    push bp
    mov bp,sp
    sub sp,130
    push ds
    push es
    push si
    push di
;
	mov ax,ss
	mov es,ax
	mov ah,62h
	int 21h
	mov ds,bx
	mov si,81h
    lea di,[bp].opn_name
init_file_next:
	lodsb
	cmp al,0Dh
	je init_file_done
	cmp al,' '
	je init_file_next
	cmp al,'	'
	je init_file_next
init_file_save_next:
	stosb
	lodsb
	cmp al,0Dh
	je init_file_done
	cmp al,' '
	je init_file_done
	cmp al,'	'
	je init_file_done
	jmp init_file_save_next
init_file_done:
	mov [bp].opn_pos,di
	mov ax,'C.'
	stosw
	mov ax,'GF'
	stosw
	xor ax,ax
	stosw
;
	mov ax,ss
	mov ds,ax
	lea dx,[bp].opn_name
	mov ax,3D00h
	int 21h
    jnc OpenCfgOk
    mov dx,OFFSET cfg_error
    call Log
    jmp OpenFilesDone
OpenCfgOk:
    mov bx,SEG _data
    mov ds,bx
	mov cfg_handle,ax
;
	mov ax,ss
	mov ds,ax
	mov es,ax
	mov di,[bp].opn_pos
	mov ax,'R.'
	stosw
	mov ax,'MO'
	stosw
	xor ax,ax
	stosw
	lea dx,[bp].opn_name
	xor cx,cx
	mov ah,3Ch
	int 21h
    jnc OpenRomOk
    mov dx,OFFSET rom_error
    call Log
    jmp OpenFilesDone
OpenRomOk:
    mov bx,SEG _data
    mov ds,bx
    mov rom_handle,ax
    clc
OpenFilesDone:
;
    pop di
    pop si
    pop es
    pop ds
    lahf
    add sp,130
    sahf
    pop bp
    ret
OpenFiles   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CloseFiles
;
;		DESCRIPTION:	Close input & output files
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseFiles  Proc near
    mov bx,cfg_handle
	mov ah,3Eh
	int 21h
;
    mov bx,rom_handle
    mov ah,3Eh
    int 21h
    ret
CloseFiles   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadBoot
;
;		DESCRIPTION:	Load boot file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

boot_name   DB 'boot.exe',0

LoadBoot    Proc near
    push ds
	push es
	push si
	push di
;
    mov dx,OFFSET boot_name
    mov ax,cs
    mov ds,ax   
	mov ax,3D00h
	int 21h
    jnc load_boot_ok
;
    mov dx,OFFSET boot_error
    call Log
    mov dx,OFFSET crlf
    call Log
    jmp load_boot_done
    
load_boot_ok:
	mov bx,ax
	mov ax,SEG Buffer
	mov ds,ax
        assume ds:Buffer
	xor dx,dx
	mov cx,1Ch
	mov ah,3Fh
	int 21h
    mov ax,ds:exeh_ip
	push ax
	push bx
	xor eax,eax
	xor ebx,ebx
	mov ax,ds:exeh_size_msb
	shl eax,5
	mov bx,ds:exeh_size_lsb
	shr bx,4
	inc bx
	add eax,ebx
	mov bx,ds:exeh_size_header
	mov dx,bx
	shl dx,4
	sub eax,ebx
	add ax,ds:exeh_minalloc
	pop bx
	xor cx,cx
	mov ax,4200h
	int 21h
	pop cx
	add cx,10h
	mov dx,OFFSET buf
	mov ah,3Fh
	int 21h
    movzx ecx,ax
	mov ah,3Eh
	int 21h
;
    mov si,OFFSET buf
    add si,cx
    mov ax,[si-1Eh]
    neg ax
    add ax,0FFF0h
    mov [si-1Eh],ax
;
    mov bx,SEG _data
    mov ds,bx
        assume ds:_data
    mov bx,rom_handle
;
	push cx
	xor cx,cx
	xor dx,dx
	mov ax,4202h
	int 21h
	push dx
	push ax
	pop edx
	pop cx
	add edx,ecx
;
    mov ax,SEG buf
    mov ds,ax
	mov si,OFFSET buf
	add si,cx
	neg edx
	mov [si-4],edx
;
    mov dx,OFFSET buf
    mov ah,40h
    int 21h
    
load_boot_done:
	pop di
	pop si
	pop es
	pop ds
    ret
LoadBoot    Endp

init:
    mov ax,_data
    mov ds,ax
    mov ax,SEG Buffer
    mov es,ax
    call OpenFiles
    jc load_error
    call LoadConfig
    jc load_close
    call LoadDrivers
    call LoadBoot
load_close:
    call CloseFiles
load_error:
	mov ax,4C00h
	int 21h

    END init

