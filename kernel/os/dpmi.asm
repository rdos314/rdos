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
; DPMI.ASM
; DPMI emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME dpmi

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE driver.def
INCLUDE user.def
INCLUDE os.def
INCLUDE system.inc
INCLUDE user.inc
INCLUDE os.inc
INCLUDE dpmi.inc

	.386p

	extrn init_dpmi32:near
	extrn init_dpmi16:near

code	SEGMENT byte public use16 'CODE'

	assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ENTER_DPMI
;
;		DESCRIPTION:	SETUP DPMI CLIENT
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enter_dpmi_name	DB 'Enter Dpmi',0

enter_dpmi	PROC far
	push cx
	push si
	push di
;
	mov al,[bp].vm_eax
	test al,1
	jz enter16

enter32:
	mov al,32
	SetBitness
	EnterDos32
	jmp enter_env

enter16:
	mov al,16
	SetBitness
	EnterDos16

enter_env:
	AllocateLdt
	mov edx,[bp].vm_ss
	shl edx,4
	mov ah,[bp].vm_eax
	and ah,1
	shl ah,6
	mov word ptr [bx],0FFFFh
	mov [bx+2],edx
	mov byte ptr [bx+5],0F2h
	shr edx,16
	mov dl,ah
	mov [bx+6],dx
	or bl,7
	mov es,bx
	mov [bp].vm_ss,bx
	mov di,[bp].vm_esp
	xor edx,edx
	mov dx,es:[di]
	mov [bp].vm_eip,dx
	mov dx,es:[di+2]
	add di,4
	mov [bp].vm_esp,di
	shl edx,4
	AllocateLdt
	mov word ptr [bx],0FFFFh
	mov [bx+2],edx
	mov byte ptr [bx+5],0FAh
	shr edx,16
	xor dl,dl
	mov [bx+6],dx
	or bl,7
	mov [bp].vm_cs,bx
	AllocateLdt
	mov edx,[bp].vm_ds
	shl edx,4
	mov word ptr [bx],0FFFFh
	mov [bx+2],edx
	mov byte ptr [bx+5],0F2h
	shr edx,16
	mov dl,ah
	mov [bx+6],dx
	or bl,7
	mov [bp].pm_ds,bx
	mov dx,[bp].vm_eflags
	or dx,200h
	and dx,NOT 7000h
	mov [bp].vm_eflags,dx
	mov word ptr [bp+2].vm_eflags,0
	GetPspSel
	mov es,bx
	xor dx,dx
	pop di
	pop si
	pop cx
	ret
enter_dpmi	ENDP

page

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			QUERY_DPMI16
;
;		DESCRIPTION:	Query DPMI info
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

query_dpmi16_name DB 'Query Dpmi16',0

dos_text	DB 'MS-DOS',0

query_dpmi16	PROC far
	cmp al,8Ah
	jnz query_not_extensions
	push cx
	push si
	push es
	push di
	mov cx,cs
	mov es,cx
	mov di,OFFSET dos_text
	mov cx,7
	repe cmpsb
	jnz query_not_dos
	xor al,al
	add sp,4
	xor di,di
	mov es,di
	pop si
	pop cx
	ret	
query_not_dos:
	pop di
	pop es
	pop si
	pop cx
query_not_extensions:
	ret
query_dpmi16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			QUERY_DPMI
;
;		DESCRIPTION:	Query DPMI info
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

query_dpmi_name	DB 'Query Dpmi',0

query_dpmi	PROC far
	cmp al,86h
	jne not_test_dpmi
	xor ax,ax
	ret
not_test_dpmi:
	cmp al,87h
	jne not_dpmi_entry
	mov di,dpmi_data_sel
	mov ds,di
	mov di,ds:dpmi_handler_seg
	mov [bp].vm_es,di
	xor di,di
	mov bx,1
	mov cl,3
	mov dh,1
	mov dl,0
	xor si,si
	xor ax,ax
	ret
not_dpmi_entry:
	ret
query_dpmi	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init driver
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dpmi_handler_begin:
	DpmiEntry
dpmi_handler_end:

init	PROC far
	pusha
	push ds
	mov bx,dpmi_code16_sel
	InitDevice
;
	mov eax,OFFSET dpmi_data_size
	mov bx,dpmi_data_sel
	AllocateFixedSystemMem
;
	mov ax,cs
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
	mov eax,OFFSET dpmi_handler_end - OFFSET dpmi_handler_begin
	AllocateFixedVMLinear
	mov cx,ax
	mov edi,edx
	mov si,OFFSET dpmi_handler_begin
dpmi_handler_move:
	lodsb
	mov es:[edi],al
	inc edi
	loop dpmi_handler_move
	shr edx,4
	mov ax,dpmi_data_sel
	mov ds,ax
	mov ds:dpmi_handler_seg,dx
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET enter_dpmi
	mov di,OFFSET enter_dpmi_name
	xor cl,cl
	mov ax,enter_dpmi_nr
	RegisterOsGate
;
	mov si,OFFSET query_dpmi
	mov di,OFFSET query_dpmi_name
	xor cl,cl
	mov ax,query_dpmi_nr
	RegisterOsGate
;
	mov si,OFFSET query_dpmi16
	mov di,OFFSET query_dpmi16_name
	xor cl,cl
	mov ax,query_dpmi16_nr
	RegisterOsGate
;
	call init_dpmi16
	mov si,OFFSET init_dpmi32
	mov ax,dpmi_code16_sel
	mov bx,dpmi_code32_sel
	AliasCode32
;
	pop ds
	popa
	ret
init	ENDP

code	ENDS

	END init

