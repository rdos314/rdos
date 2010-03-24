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
; FLASH.ASM
; Flash disk driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  flash

GateSize = 16

INCLUDE \rdos\kernel\driver.def
INCLUDE \rdos\kernel\user.def
INCLUDE \rdos\kernel\os.def
INCLUDE \rdos\kernel\user.inc
INCLUDE \rdos\kernel\os.inc
INCLUDE \rdos\kernel\drive.inc
INCLUDE \rdos\kernel\os\port.def

FLASH_BASE 			EQU 0D0000h
FLASH_WINDOW_SIZE	EQU 8000h

boot_struc	STRUC

boot_jmp					DB ?,?,?
boot_name					DB 8 DUP(?)
boot_bytes_per_sector		DW ?
boot_sectors_per_cluster	DB ?
boot_resv_sectors			DW ?
boot_fats					DB ?
boot_root_dirs				DW ?
boot_sectors				DW ?
boot_media					DB ?
boot_fat_sectors			DW ?
boot_sectors_per_cyl		DW ?
boot_heads					DW ?
boot_hidden_sectors			DD ?
boot_big_sectors			DD ?
boot_drive_nr				DB ?,?
boot_signature				DB ?
boot_serial					DD ?
boot_volume					DB 11 DUP(?)
boot_fs						DB 8 DUP(?)

boot_struc		ENDS

flash_disc_data STRUC

flash_section        section_typ <>

flash_disc_data ENDS

disc_struc	STRUC

disc_section			section_typ <>
disc_fs_handle			DW ?
disc_sel				DW ?
disc_thread				DW ?
disc_sub_unit			DB ?
disc_nr					DB ?

disc_struc		ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code	SEGMENT byte public 'CODE'

	assume cs:code

.386c

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MapFlash
;
;		DESCRIPTION:	Map the flash chip
;
;		PARAMETERS:		EDX		Offset in flash chip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapFlash	Proc near
	push eax
	push dx
;
	push edx
	mov dx,218h
	mov al,2Eh
	out dx,al
	mov dx,21Ah
	pop eax
	sub eax,FLASH_BASE
	and eax,0FFFFFFh
	out dx,eax
;
	pop dx
	pop eax
	ret
MapFlash	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DEMAND_MOUNT
;
;		DESCRIPTION:	Mount disc drive on demand
;
;		PARAMETERS:		BX		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

demand_mount	Proc far
	ret
demand_mount	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Erase
;
;		DESCRIPTION:	Erase a 4k block
;
;		PARAMETERS:		BX		Disc handle
;                       EDX     Flash offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

erase   Proc far
	push es
    pushad
;
	mov ax,flash_disc_sel
	mov es,ax
;
	push edx
	xor edx,edx
	call MapFlash
	pop edx
;
	mov al,0AAh
	mov si,555h SHL 1
	mov es:[si],al
;
	mov al,55h
	mov si,2AAh SHL 1
	mov es:[si],al
;
    mov al,80h
	mov si,555h SHL 1
	mov es:[si],al
;
	mov al,0AAh
	mov si,555h SHL 1
	mov es:[si],al
;
	mov al,55h
	mov si,2AAh SHL 1
	mov es:[si],al
;
    push edx
    mov dx,218h
    mov al,2Eh
    out dx,al
    pop eax
;
    mov dx,21Ah
	sub eax,FLASH_BASE
    and eax,0FFF000h
    out dx,eax
;    
    xor si,si
    mov al,30h
    mov es:[si],al
;
	xor edx,edx
	call MapFlash
;
	xor si,si
    mov al,es:[si]

wait_erase_loop:
    mov ah,es:[si]
    xor al,ah
    test al,40h
    jz wait_erase_done
;
    mov al,ah
    jmp wait_erase_loop

wait_erase_done:
    popad
	pop es
    ret
erase   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			check_media
;
;		DESCRIPTION:	Check for media change
;
;		PARAMETERS:		BX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_media	Proc far
    clc
	ret
check_media	Endp

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			read_drive
;
;		DESCRIPTION:	Read drive
;
;		PARAMETERS:		FS		Disc selector
;						EDI		Disc handle of first sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_drive	Proc near
    push ds
    push eax
    push ecx
    push edx
    push esi
;
    mov ax,flash_disc_sel
    mov ds,ax
;    
    mov dx,es:[edi].dh_sector
    mov ax,es:[edi].dh_unit
    shl ax,3
    or dx,ax
    movzx edx,dx
    shl edx,9    
    call MapFlash
;
    mov esi,FLASH_BASE
    push edi
    mov edi,es:[edi].dh_data
    mov ecx,80h
    rep movs dword ptr es:[edi],es:[esi]
    pop edi    
    mov es:[edi].dh_state,STATE_USED	
    clc
;
    pop esi
    pop edx
    pop ecx
    pop eax
    pop ds
	ret
read_drive	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			lock_erase_sectors
;
;		DESCRIPTION:	Lock all sectors before an erase
;
;		PARAMETERS:		DS		Disc selector
;						EDI		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_erase_sectors  Proc near
    pushad
;    
    xor ax,ax
    mov dx,es:[edi].dh_unit
    mov cx,8

lock_load_loop:
    push ax
    mov bx,fs:disc_sel
    LockDiscRequest
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    jne lock_load_modify
;
    call read_drive

lock_load_modify:    
    ModifyDiscRequest
    UnlockDiscRequest
;
    pop ax
    inc ax
    loop lock_load_loop
;
    popad
    ret
lock_erase_sectors  Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			write_drive
;
;		DESCRIPTION:	Perform a write request
;
;		PARAMETERS:		DS		Disc selector
;						EDI		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_drive	Proc near
    push ds
    pushad
;
    mov ax,flash_disc_sel
    mov ds,ax    

write_drive_retry:
    mov dx,es:[edi].dh_sector
    mov ax,es:[edi].dh_unit
    shl ax,3
    or dx,ax
    movzx edx,dx
    shl edx,9
;
    mov ebx,es:[edi].dh_data    
    mov cx,100h

write_drive_loop:
    push edx
    and dx,NOT 0FFFh
    call MapFlash
    pop edx
;
    mov si,dx
    and si,0FFFh
;        
    mov ax,es:[ebx]
    cmp ax,[si]
    je write_drive_next
;    
    xor ax,[si]
    and ax,es:[ebx]
    jnz write_drive_erase
;
    push edx
	xor edx,edx
	call MapFlash
	pop edx
;	
	mov al,0AAh
	mov si,555h SHL 1
	mov ds:[si],al
;
	mov al,55h
	mov si,2AAh SHL 1
	mov ds:[si],al
;
    mov al,0A0h
	mov si,555h SHL 1
	mov ds:[si],al
;	
    push edx
    and dx,NOT 0FFFh
    call MapFlash
    pop edx
    mov si,dx
    and si,0FFFh
    mov ax,es:[ebx]
    mov [si],ax
;
    mov al,[si]

wait_program_loop:
    mov ah,[si]
    xor al,ah
    test al,40h
    jz write_drive_check
;
    mov al,ah
    jmp wait_program_loop

write_drive_erase:
    call lock_erase_sectors
    call erase
    jmp write_drive_retry

write_drive_check:
    mov ax,es:[ebx]
    cmp ax,[si]
    jne write_drive_loop

write_drive_next:  
    add ebx,2
    add edx,2
    sub cx,1
    jnz write_drive_loop 
;
	xor edx,edx
	call MapFlash
;    
	mov es:[edi].dh_state,STATE_USED
    clc

write_drive_done:	
    popad
    pop ds
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
	mov bx,fs:disc_sel
	GetDiscRequest
	jc perform_one_done
;
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
	jc perform_one_fail
	jmp perform_one_completed

perform_one_read:
	call read_drive
	jc perform_one_fail

perform_one_completed:
	mov bx,fs:disc_sel
	DiscRequestCompleted
	jmp perform_one_loop

perform_one_fail:
	int 3
	mov bx,fs:disc_sel
	DiscRequestCompleted
;	FlushDisc

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

discbuf_thread:
	GetThread
	mov fs:disc_thread,ax
;
    mov ax,flash_disc_data_sel
    mov ds,ax
	mov ax,flat_sel
	mov es,ax

discbuf_thread_loop:
	mov bx,fs:disc_sel
	WaitForDiscRequest
;
    mov esi,OFFSET flash_section
    EnterNewSection
    push ds
   	call perform_one
   	pop ds
    mov esi,OFFSET flash_section
    LeaveNewSection
    jmp discbuf_thread_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSTALL_UNIT
;
;		DESCRIPTION:	Install a disk unit
;
;		PARAMETERS:		AL		UNIT #
;						DI		NAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc0	DB 'Flash Disc 0',0

install_unit	Proc near
	mov eax,SIZE disc_struc
	AllocateSmallGlobalMem
	mov bx,es
	mov fs,bx
	mov fs:disc_sub_unit,0
	InitSection fs:disc_section
;
	mov ecx,200h
	mov bx,fs
	InstallDisc
	mov fs:disc_sel,bx
	mov fs:disc_nr,al
;
    mov ax,8
    mov cx,200h
    mov dx,200h
    mov si,80h
    mov di,8
    SetDiscParam
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET disc0
	mov si,OFFSET discbuf_thread
	mov ax,1
	mov cx,100h
	CreateThread
	
install_unit_done:
	ret
install_unit	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			disc_assign
;
;		DESCRIPTION:	Assign discs
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flash0	DB 'Flash disc 0',0

disc_assign	Proc far
	push ds
	push es
	pusha
;
    mov ax,flash_disc_data_sel
    mov ds,ax
    mov esi,OFFSET flash_section
    EnterNewSection
    push ds
;    
	mov al,0
	mov di,OFFSET flash0
	call install_unit
;
    pop ds
    mov esi,OFFSET flash_section
    LeaveNewSection
;
	popa
	pop es
	pop ds	
	ret
disc_assign	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DRIVE_ASSIGN1
;
;		DESCRIPTION:	Assign disc drives, pass 1
;
;		PARAMETERS:		BX		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drive_assign1	Proc far
	ret
drive_assign1	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DRIVE_ASSIGN2
;
;		DESCRIPTION:	Assign disc drives, pass 2
;
;		PARAMETERS:		BX		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drive_assign2	Proc far
	ret
drive_assign2	Endp

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

disc_ctrl:
dct00	DW OFFSET disc_assign,		flash_disc_code_sel
dct01	DW OFFSET drive_assign1,	flash_disc_code_sel
dct02	DW OFFSET drive_assign2,	flash_disc_code_sel
dct03	DW OFFSET demand_mount,		flash_disc_code_sel
dct04   DW OFFSET erase,            flash_disc_code_sel

init	PROC far
	push ds
	push es
	pusha
	mov bx,flash_disc_code_sel
	InitDevice
;
	mov eax,SIZE flash_disc_data
	mov bx,flash_disc_data_sel
	AllocateFixedSystemMem
	InitSection es:flash_section
;	
    mov dx,218h
    mov al,26h
    out dx,al
    mov dx,21Ah
    mov eax,FLASH_BASE
    out dx,eax
;
    mov dx,218h
    mov al,2Ah
    out dx,al
    mov dx,21Ah
    mov eax,FLASH_WINDOW_SIZE
    out dx,eax
;
    mov dx,218h
    mov al,2Eh
    out dx,al
    mov dx,21Ah
    mov eax,1000000h - FLASH_BASE
    out dx,eax
;
	mov dx,218h
	mov al,5Ah
	out dx,al
	mov dx,219h
	in al,dx
	and al,011101110b
;
    push ax
	mov dx,218h
	mov al,5Ah
	out dx,al
	mov dx,219h
	pop ax
	out dx,al
;
	mov eax,FLASH_WINDOW_SIZE
	AllocateBigLinear
;
	mov bx,flash_disc_sel
	mov ecx,FLASH_WINDOW_SIZE
	CreateDataSelector32
;
	mov eax,FLASH_BASE + 3

init_flash_loop:
	SetPhysicalPage
	add eax,1000h	
	add edx,1000h
	sub ecx,1000h
	jnz init_flash_loop
;
	mov ax,flash_disc_sel
	mov ds,ax
;
	mov al,0AAh
	mov si,555h SHL 1
	mov [esi],al
;
	mov al,55h
	mov si,2AAh SHL 1
	mov [esi],al
;
    mov al,90h
	mov si,555h SHL 1
	mov [esi],al
;
    xor si,si
    mov eax,[esi]
    mov byte ptr [esi],0F0h
;
	cmp eax,22D80001h
	je start_flash
;
	cmp eax,224A0001h
	je start_flash
;
	cmp eax,22CB0001h
	je start_flash
;
	cmp eax,22D60001h
	je start_flash
;
	cmp eax,22580001h
	je start_flash
;
	cmp eax,22D20001h
	je start_flash
;
	cmp eax,22D70001h
	je start_flash
;
	cmp eax,22560001h
	je start_flash
;
	cmp eax,22530001h
	je start_flash
;
	cmp eax,225F0001h
	jne init_end

start_flash:
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET disc_ctrl
	HookInitDisc

init_end:	
	popa
	pop es
	pop ds
	ret
init	ENDP

code ENDS

END init

