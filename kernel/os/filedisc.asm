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
; FILEDISC.ASM
; File based disc driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME filedisc

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\drive.inc

file_header     STRUC

fh_sectors_per_unit     DW ?
fh_units                DW ?
fh_size                 DD ?
fh_fs_name              DB 50 DUP (?)

file_header     ENDS

file_disc_data_seg  STRUC

fd_header               file_header <>

fd_disc_sel             DW ?
fd_disc_nr              DB ?
fd_drive_nr             DB ?

fd_access               DB ?
fd_selector             DW ?

file_disc_data_seg  ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			read_drive
;
;		DESCRIPTION:	Read drive
;
;		PARAMETERS:		FS		Disc selector
;						ESI		Disc handle array
;						ECX		Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_drive	Proc near
	ret
read_drive	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			write_drive
;
;		DESCRIPTION:	Perform a write request
;
;		PARAMETERS:		DS		Disc selector
;						ESI		Disc handle array
;						ECX		Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_drive	Proc near
	ret
write_drive	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			perform_one
;
;		DESCRIPTION:	Perform one request
;
;		PARAMETERS:		FS		Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

perform_one	Proc near

perform_one_loop:
	mov ecx,255
	GetDiscRequestArray
	jc perform_one_done
;
	mov edi,es:[esi]
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	je perform_one_read
;
	cmp al,STATE_DIRTY
	je perform_one_write
;
	cmp al,STATE_SEQ
	jne perform_one_done

perform_one_write:
	call write_drive
	jmp perform_one_loop

perform_one_read:
	call read_drive
	jmp perform_one_loop

perform_one_done:
	ret
perform_one	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DISCBUF_THREAD
;
;		DESCRIPTION:	Thread to handle disc buffer queue
;
;		PARAMETERS:		FS		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

discbuf_name    DB 'File drive', 0

discbuf_thread:
	mov ax,flat_sel
	mov es,ax
;
	mov bx,fs:fd_disc_sel

discbuf_thread_loop:
	WaitForDiscRequest
    int 3
	call perform_one
	jmp discbuf_thread_loop

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateFileDrive
;
;		DESCRIPTION:    Create file as a filesystem & return drive
;
;		PARAMETERS:		DS:(E)SI            Requested filesystem
;                       ES:(E)DI            Filename to use
;                       (E)CX               Size of filesystem
;
;       RETURNS:        AL                  Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_file_drive_name  DB 'Create File Drive',0

create_file_drive   Proc near
    push ds
    push es
    push fs
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    UserGateForce32 is_file_system_available_nr
    jc cfdDone
;
    push cx
    xor cx,cx
    UserGateForce32 create_file_nr
    pop cx
    jc cfdDone
;
	mov eax,SIZE file_disc_data_seg
	AllocateSmallGlobalMem
    mov di,OFFSET fh_fs_name

cfdMoveName:
    lodsb
    stosb
    or al,al
    jnz cfdMoveName
;
    mov eax,ecx
    mov cx,1
	dec eax
	shr eax,9
	inc eax

cfdIterate:
	cmp eax,100000h
	jb cfdSave
;
    shl cx,1
    shr eax,1
    jmp cfdIterate

cfdSave:
    mov es:fh_sectors_per_unit,cx
	mov es:fh_units,ax
	mul cx
	push dx
	push ax
	pop eax
    shl eax,9
    mov es:fh_size,eax
;
    xor di,di
    mov cx,SIZE file_header
    WriteFile
;
    mov eax,es:fh_size
    SetFileSize
;
    GetFileInfo
    mov es:fd_access,cl
    mov es:fd_selector,ax
;
	mov ecx,200h
	mov bx,es
	InstallDisc
	mov es:fd_disc_sel,bx
	mov es:fd_disc_nr,al
;
    mov ax,es:fh_sectors_per_unit
    mov cx,200h
    mov dx,es:fh_units
    xor si,si
    xor di,di    
	SetDiscParam
;
	AllocateDynamicDrive
	mov es:fd_drive_nr,al
;
	mov ah,es:fd_disc_nr
	mov edx,1
	mov ecx,es:fh_size
	shr ecx,9
	dec ecx
	OpenDrive
;
    push es
    push ecx
    mov ax,es
    mov fs,ax
    mov ax,cs
    mov ds,ax
    mov es,ax
	mov si,OFFSET discbuf_thread
	mov di,OFFSET discbuf_name
	mov ax,4
	mov cx,100h
	CreateThread
	pop ecx
	pop es
;
    mov al,es:fd_drive_nr
    mov di,OFFSET fh_fs_name
	FormatFileSystem
	InstallFileSystem
	StartFileSystem

cfdDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
    pop ds
    ret
create_file_drive   Endp

create_file_drive32 Proc far
    call create_file_drive
	retf32
create_file_drive32 Endp

create_file_drive16 Proc far
    push ecx
    push esi
    push edi
    movzx ecx,cx
    movzx esi,si
    movzx edi,di
    call create_file_drive
    pop edi
    pop esi
    pop ecx
    ret
create_file_drive16 Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    OpenFileDrive
;
;		DESCRIPTION:    Open file as a logical drive
;
;		PARAMETERS:		ES:(E)DI        Filename
;
;       RETURNS:        AL              Logical drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_file_drive_name  DB 'Open File Drive',0

open_file_drive Proc near
    push ds
    push es
    push fs
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    xor cx,cx
    UserGateForce32 open_file_nr
    jc ofdDone
;
    int 3
	mov eax,SIZE file_disc_data_seg
    mov cx,ax
	AllocateSmallGlobalMem
    xor di,di
    mov es:fh_fs_name,0
    ReadFile
    jc ofdFail
;
    IsFileSystemAvailable
    jc ofdFail
;
    GetFileInfo
    mov es:fd_access,cl
    mov es:fd_selector,ax
;
	mov ecx,200h
	mov bx,es
	InstallDisc
	mov es:fd_disc_sel,bx
	mov es:fd_disc_nr,al
;
    mov ax,es:fh_sectors_per_unit
    mov cx,200h
    mov dx,es:fh_units
    xor si,si
    xor di,di    
	SetDiscParam
;
	AllocateDynamicDrive
	mov es:fd_drive_nr,al
;
	mov ah,es:fd_disc_nr
	mov edx,1
	mov ecx,es:fh_size
	shr ecx,9
	dec ecx
	OpenDrive
;
    push es
    mov ax,es
    mov fs,ax
    mov ax,cs
    mov ds,ax
    mov es,ax
	mov si,OFFSET discbuf_thread
	mov di,OFFSET discbuf_name
	mov ax,4
	mov cx,100h
	CreateThread
	pop es
;
	mov al,es:fd_drive_nr
    mov di,OFFSET fh_fs_name
	InstallFileSystem
	StartFileSystem
	clc
	jmp ofdDone

ofdFail:
    FreeMem
    stc
    
ofdDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop fs
	pop es
    pop ds
	ret
open_file_drive	Endp

open_file_drive32 Proc far
    call open_file_drive
	retf32
open_file_drive32 Endp

open_file_drive16 Proc far
    push edi
    movzx edi,di
    call open_file_drive
    pop edi
    ret
open_file_drive16 Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init device
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	push ds
	push es
	pusha
	mov bx,file_disc_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov bx,OFFSET create_file_drive16
	mov si,OFFSET create_file_drive32
	mov di,OFFSET create_file_drive_name
	mov dx,virt_es_in
	mov ax,create_file_drive_nr
	RegisterUserGate
;
	mov bx,OFFSET open_file_drive16
	mov si,OFFSET open_file_drive32
	mov di,OFFSET open_file_drive_name
	mov dx,virt_es_in
	mov ax,open_file_drive_nr
	RegisterUserGate
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init

