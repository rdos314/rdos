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

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			map_flash
;
;		DESCRIPTION:	Setup flash position
;
;		PARAMETERS:		EAX     Offset within flash
;
;       RETURNS:        ESI     Flash address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_flash   Proc near
    push eax
    push bx
    push cx
    push dx
;    
    mov esi,eax
    and esi,1FFFh
    add esi,0C8000h
;
    shr eax,13
    mov bl,40h
    mov cl,fs:disc_sub_unit
    shl bl,cl
    or al,bl
    mov dx,210h
    out dx,al 
;
    pop dx
    pop cx
    pop bx
    pop eax
    ret 
map_flash   Endp   

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ERASE
;
;		DESCRIPTION:	Erase sectors
;
;		PARAMETERS:		BX		Disc handle
;                       EDX     Flash offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

erase	Proc far
    pushad
;
	mov cx,8

EraseLoop:
    mov eax,edx
    and eax,0F0000h
    add eax,5555h
    call map_flash    
    mov byte ptr es:[esi],0AAh
;
    mov eax,edx
    and eax,0F0000h
    add eax,2AAAh
    call map_flash    
    mov byte ptr es:[esi],55h
;    
    mov eax,edx
    and eax,0F0000h
    add eax,5555h
    call map_flash    
    mov byte ptr es:[esi],80h
;    
    mov eax,edx
    and eax,0F0000h
    add eax,5555h
    call map_flash    
    mov byte ptr es:[esi],0AAh
;
    mov eax,edx
    and eax,0F0000h
    add eax,2AAAh
    call map_flash    
    mov byte ptr es:[esi],55h
;
    mov eax,edx
    and eax,0F0000h
    call map_flash    
    mov byte ptr es:[esi],30h
;
    mov ax,10
    WaitMilliSec
;
    mov si,1000    

EraseWait:
    mov al,byte ptr es:[esi]
    test al,80h
	clc
    jnz EraseDone
;
	test al,20h
	jnz EraseNext
;
    mov ax,2
    WaitMilliSec
    sub si,1
    jnz EraseWait
    jmp EraseFail

EraseNext:
    sub cx,1
	jnz EraseLoop

EraseFail:
	stc

EraseDone:
    popad
	ret
erase	Endp

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
    push eax
    push bx
    push cx
    push dx
    push esi
;    
    mov bl,40h
    mov cl,fs:disc_sub_unit
    shl bl,cl
;
    mov esi,0C8000h
    movzx eax,es:[edi].dh_sector
    shl eax,9
    and eax,1FFFh
    add esi,eax
;
    mov ax,es:[edi].dh_sector    
    shr ax,4
    or bl,al
;
    mov ax,es:[edi].dh_unit
    shl ax,3
    or bl,al
;
    mov dx,210h
    mov al,bl
    out dx,al
;
    push edi
    mov edi,es:[edi].dh_data
    mov ecx,80h
    rep movs dword ptr es:[edi],es:[esi]
    pop edi
;
    xor al,al
    out dx,al 
;    
    mov es:[edi].dh_state,STATE_USED
;	
    clc
;
    pop esi
    pop dx
    pop cx
    pop bx
    pop eax
	ret
read_drive	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			lock_erase_sectors
;
;		DESCRIPTION:	Lock a sectors before an erase
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
    mov cx,80h

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

write_drive_retry:
    mov dx,es:[edi].dh_sector
    mov ax,es:[edi].dh_unit
    shl ax,7
    or dx,ax
    movzx edx,dx
    shl edx,9
;
    mov ebx,es:[edi].dh_data    
    mov cx,200h

write_drive_loop:
    mov eax,edx
    call map_flash
    mov al,es:[ebx]
    cmp al,es:[esi]
    je write_drive_next
;    
    xor al,es:[esi]
    and al,es:[ebx]
    jnz write_drive_erase
;
    mov eax,edx
    and eax,0F0000h
    add eax,5555h
    call map_flash    
    mov byte ptr es:[esi],0AAh
;
    mov eax,edx
    and eax,0F0000h
    add eax,2AAAh
    call map_flash
    mov byte ptr es:[esi],55h
;
    mov eax,edx
    and eax,0F0000h
    add eax,5555h
    call map_flash
    mov byte ptr es:[esi],0A0h
;
    mov eax,edx
    call map_flash
    mov al,es:[ebx]
    mov es:[esi],al

write_drive_wait:
	mov ah,es:[esi]
	push dx
	mov dl,ah
	xor dl,al
	test dl,80h
	pop dx
	jz write_drive_check
;
	test ah,20h
	jz write_drive_wait
;
	mov ah,es:[esi]
	xor ah,al
	test ah,80h
	jz write_drive_check

write_drive_erase:
    call lock_erase_sectors
    call erase
    jmp write_drive_retry

write_drive_check:
    mov al,es:[ebx]
    cmp al,es:[esi]
    jne write_drive_loop

write_drive_next:  
    inc ebx
    inc edx
    sub cx,1
    jnz write_drive_loop 
;
    xor al,al
    out dx,al 
;    
	mov es:[edi].dh_state,STATE_USED
    clc

write_drive_done:	
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
    EnterSection ds:flash_section
    push ds
   	call perform_one
   	pop ds
   	LeaveSection ds:flash_section
	jmp discbuf_thread_loop

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			read_flash
;
;		DESCRIPTION:	Read flash position
;
;		PARAMETERS:		CL      Device #
;                       EDX     Offset within flash
;
;       RETURNS:        AL      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_flash   Proc near
    push es
    push bx
    push cx
    push dx
    push esi
;   
    mov ax,flat_sel
    mov es,ax
    mov eax,edx 
    mov esi,eax
    and esi,1FFFh
    add esi,0C8000h
;
    shr eax,13
    mov bl,40h
    shl bl,cl
    or al,bl
    mov dx,210h
    out dx,al 
    mov al,es:[esi]
;
    pop esi
    pop dx
    pop cx
    pop bx
    pop es
    ret 
read_flash   Endp   

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			write_flash
;
;		DESCRIPTION:	Write flash position
;
;		PARAMETERS:		CL      Device #
;                       EDX     Offset within flash
;                       AL      Data
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_flash   Proc near
    push es
    push bx
    push cx
    push dx
    push esi
;   
    push ax
    mov ax,flat_sel
    mov es,ax
    mov eax,edx 
    mov esi,eax
    and esi,1FFFh
    add esi,0C8000h
;
    shr eax,13
    mov bl,40h
    shl bl,cl
    or al,bl
    mov dx,210h
    out dx,al 
    pop ax
    mov es:[esi],al
;
    pop esi
    pop dx
    pop cx
    pop bx
    pop es
    ret 
write_flash   Endp   


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
disc1	DB 'Flash Disc 1',0

disc_name_tab:
dnt00	DW OFFSET disc0
dnt01	DW OFFSET disc1

install_unit	Proc near
    push ax
    mov cl,al
;    
    mov al,0AAh
    mov edx,5555h    
    call write_flash
; 
    mov al,55h
    mov edx,2AAAh
    call write_flash   
;    
    mov al,90h
    mov edx,5555h    
    call write_flash
;
    mov edx,0
    call read_flash
;    
    push ax
    mov al,0F0h
    mov edx,0    
    call write_flash
    pop ax
;        
    cmp al,1
    pop ax
    jne install_unit_done
;
  	push ax
	mov eax,SIZE disc_struc
	AllocateSmallGlobalMem
	mov bx,es
	mov fs,bx
	pop ax
	mov fs:disc_sub_unit,al
	InitSection fs:disc_section
;
	mov ecx,200h
	mov bx,fs
	InstallDisc
	mov fs:disc_sel,bx
	mov fs:disc_nr,al
;
    mov ax,80h
    mov cx,200h
    mov dx,8
    mov si,80h
    mov di,8
    SetDiscParam
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	movzx di,fs:disc_sub_unit
	add di,di
	mov di,word ptr cs:[di].disc_name_tab
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
flash1	DB 'Flash disc 1',0

disc_assign	Proc far
	push ds
	push es
	pusha
;
    mov ax,flash_disc_data_sel
    mov ds,ax
    EnterSection ds:flash_section
    push ds
;    
	mov al,0
	mov di,OFFSET flash0
	call install_unit
;	
	mov al,1
	mov di,OFFSET flash1
	call install_unit
;
    pop ds
   	LeaveSection ds:flash_section
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
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET disc_ctrl
	HookInitDisc
;	
	popa
	pop es
	pop ds
	ret
init	ENDP

code ENDS

END init

