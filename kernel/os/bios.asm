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
; BIOS.ASM
; BIOS emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME bios

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.inc

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

real_int15:
	ReflectPmToVm

bios_error	PROC far
	or byte ptr [bp].vm_eflags,1
	ret
bios_error	ENDP

device_busy	PROC far
	or al,al
	jne not_disc_busy
	mov ax,flat_sel
	mov ds,ax
	mov bx,048Eh
	cli
	mov al,[bx]
	cmp al,0FFh
	je disc_busy_ok
disc_wait_loop:
	sti
	mov ax,4
	WaitMilliSec
	cli
	mov al,[bx]
	cmp al,0FFh
	jnz disc_wait_loop
disc_busy_ok:
	sti
	mov al,90h
	mov [bp].vm_eax,al
	and byte ptr [bp].vm_eflags,NOT 1
	mov ax,[bp].vm_eax
	mov bx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	ret
not_disc_busy:
	jmp real_int15
device_busy	ENDP

mem_size	PROC far
	xor ax,ax
	ret
mem_size	ENDP

int15_tab:
bio00	DW OFFSET real_int15
bio01	DW OFFSET real_int15
bio02	DW OFFSET real_int15
bio03	DW OFFSET real_int15
bio04	DW OFFSET real_int15
bio05	DW OFFSET real_int15
bio06	DW OFFSET real_int15
bio07	DW OFFSET real_int15
bio08	DW OFFSET real_int15
bio09	DW OFFSET real_int15
bio0A	DW OFFSET real_int15
bio0B	DW OFFSET real_int15
bio0C	DW OFFSET real_int15
bio0D	DW OFFSET real_int15
bio0E	DW OFFSET real_int15
bio0F	DW OFFSET real_int15
bio10	DW OFFSET real_int15
bio11	DW OFFSET real_int15
bio12	DW OFFSET real_int15
bio13	DW OFFSET real_int15
bio14	DW OFFSET real_int15
bio15	DW OFFSET real_int15
bio16	DW OFFSET real_int15
bio17	DW OFFSET real_int15
bio18	DW OFFSET real_int15
bio19	DW OFFSET real_int15
bio1A	DW OFFSET real_int15
bio1B	DW OFFSET real_int15
bio1C	DW OFFSET real_int15
bio1D	DW OFFSET real_int15
bio1E	DW OFFSET real_int15
bio1F	DW OFFSET real_int15
bio20	DW OFFSET real_int15
bio21	DW OFFSET real_int15
bio22	DW OFFSET real_int15
bio23	DW OFFSET real_int15
bio24	DW OFFSET real_int15
bio25	DW OFFSET real_int15
bio26	DW OFFSET real_int15
bio27	DW OFFSET real_int15
bio28	DW OFFSET real_int15
bio29	DW OFFSET real_int15
bio2A	DW OFFSET real_int15
bio2B	DW OFFSET real_int15
bio2C	DW OFFSET real_int15
bio2D	DW OFFSET real_int15
bio2E	DW OFFSET real_int15
bio2F	DW OFFSET real_int15
bio30	DW OFFSET real_int15
bio31	DW OFFSET real_int15
bio32	DW OFFSET real_int15
bio33	DW OFFSET real_int15
bio34	DW OFFSET real_int15
bio35	DW OFFSET real_int15
bio36	DW OFFSET real_int15
bio37	DW OFFSET real_int15
bio38	DW OFFSET real_int15
bio39	DW OFFSET real_int15
bio3A	DW OFFSET real_int15
bio3B	DW OFFSET real_int15
bio3C	DW OFFSET real_int15
bio3D	DW OFFSET real_int15
bio3E	DW OFFSET real_int15
bio3F	DW OFFSET real_int15
bio40	DW OFFSET real_int15
bio41	DW OFFSET real_int15
bio42	DW OFFSET real_int15
bio43	DW OFFSET real_int15
bio44	DW OFFSET real_int15
bio45	DW OFFSET real_int15
bio46	DW OFFSET real_int15
bio47	DW OFFSET real_int15
bio48	DW OFFSET real_int15
bio49	DW OFFSET real_int15
bio4A	DW OFFSET real_int15
bio4B	DW OFFSET real_int15
bio4C	DW OFFSET real_int15
bio4D	DW OFFSET real_int15
bio4E	DW OFFSET real_int15
bio4F	DW OFFSET real_int15
bio50	DW OFFSET real_int15
bio51	DW OFFSET real_int15
bio52	DW OFFSET real_int15
bio53	DW OFFSET real_int15
bio54	DW OFFSET real_int15
bio55	DW OFFSET real_int15
bio56	DW OFFSET real_int15
bio57	DW OFFSET real_int15
bio58	DW OFFSET real_int15
bio59	DW OFFSET real_int15
bio5A	DW OFFSET real_int15
bio5B	DW OFFSET real_int15
bio5C	DW OFFSET real_int15
bio5D	DW OFFSET real_int15
bio5E	DW OFFSET real_int15
bio5F	DW OFFSET real_int15
bio60	DW OFFSET real_int15
bio61	DW OFFSET real_int15
bio62	DW OFFSET real_int15
bio63	DW OFFSET real_int15
bio64	DW OFFSET real_int15
bio65	DW OFFSET real_int15
bio66	DW OFFSET real_int15
bio67	DW OFFSET real_int15
bio68	DW OFFSET real_int15
bio69	DW OFFSET real_int15
bio6A	DW OFFSET real_int15
bio6B	DW OFFSET real_int15
bio6C	DW OFFSET real_int15
bio6D	DW OFFSET real_int15
bio6E	DW OFFSET real_int15
bio6F	DW OFFSET real_int15
bio70	DW OFFSET real_int15
bio71	DW OFFSET real_int15
bio72	DW OFFSET real_int15
bio73	DW OFFSET real_int15
bio74	DW OFFSET real_int15
bio75	DW OFFSET real_int15
bio76	DW OFFSET real_int15
bio77	DW OFFSET real_int15
bio78	DW OFFSET real_int15
bio79	DW OFFSET real_int15
bio7A	DW OFFSET real_int15
bio7B	DW OFFSET real_int15
bio7C	DW OFFSET real_int15
bio7D	DW OFFSET real_int15
bio7E	DW OFFSET real_int15
bio7F	DW OFFSET real_int15
bio80	DW OFFSET real_int15
bio81	DW OFFSET real_int15
bio82	DW OFFSET real_int15
bio83	DW OFFSET real_int15
bio84	DW OFFSET real_int15
bio85	DW OFFSET real_int15
bio86	DW OFFSET real_int15
bio87	DW OFFSET bios_error
bio88	DW OFFSET mem_size
bio89	DW OFFSET real_int15
bio8A	DW OFFSET real_int15
bio8B	DW OFFSET real_int15
bio8C	DW OFFSET real_int15
bio8D	DW OFFSET real_int15
bio8E	DW OFFSET real_int15
bio8F	DW OFFSET real_int15
bio90	DW OFFSET device_busy
bio91	DW OFFSET real_int15
bio92	DW OFFSET real_int15
bio93	DW OFFSET real_int15
bio94	DW OFFSET real_int15
bio95	DW OFFSET real_int15
bio96	DW OFFSET real_int15
bio97	DW OFFSET real_int15
bio98	DW OFFSET real_int15
bio99	DW OFFSET real_int15
bio9A	DW OFFSET real_int15
bio9B	DW OFFSET real_int15
bio9C	DW OFFSET real_int15
bio9D	DW OFFSET real_int15
bio9E	DW OFFSET real_int15
bio9F	DW OFFSET real_int15
bioA0	DW OFFSET real_int15
bioA1	DW OFFSET real_int15
bioA2	DW OFFSET real_int15
bioA3	DW OFFSET real_int15
bioA4	DW OFFSET real_int15
bioA5	DW OFFSET real_int15
bioA6	DW OFFSET real_int15
bioA7	DW OFFSET real_int15
bioA8	DW OFFSET real_int15
bioA9	DW OFFSET real_int15
bioAA	DW OFFSET real_int15
bioAB	DW OFFSET real_int15
bioAC	DW OFFSET real_int15
bioAD	DW OFFSET real_int15
bioAE	DW OFFSET real_int15
bioAF	DW OFFSET real_int15
bioB0	DW OFFSET real_int15
bioB1	DW OFFSET real_int15
bioB2	DW OFFSET real_int15
bioB3	DW OFFSET real_int15
bioB4	DW OFFSET real_int15
bioB5	DW OFFSET real_int15
bioB6	DW OFFSET real_int15
bioB7	DW OFFSET real_int15
bioB8	DW OFFSET real_int15
bioB9	DW OFFSET real_int15
bioBA	DW OFFSET real_int15
bioBB	DW OFFSET real_int15
bioBC	DW OFFSET real_int15
bioBD	DW OFFSET real_int15
bioBE	DW OFFSET real_int15
bioBF	DW OFFSET real_int15
bioC0	DW OFFSET real_int15
bioC1	DW OFFSET real_int15
bioC2	DW OFFSET real_int15
bioC3	DW OFFSET real_int15
bioC4	DW OFFSET real_int15
bioC5	DW OFFSET real_int15
bioC6	DW OFFSET real_int15
bioC7	DW OFFSET real_int15
bioC8	DW OFFSET real_int15
bioC9	DW OFFSET real_int15
bioCA	DW OFFSET real_int15
bioCB	DW OFFSET real_int15
bioCC	DW OFFSET real_int15
bioCD	DW OFFSET real_int15
bioCE	DW OFFSET real_int15
bioCF	DW OFFSET real_int15
bioD0	DW OFFSET real_int15
bioD1	DW OFFSET real_int15
bioD2	DW OFFSET real_int15
bioD3	DW OFFSET real_int15
bioD4	DW OFFSET real_int15
bioD5	DW OFFSET real_int15
bioD6	DW OFFSET real_int15
bioD7	DW OFFSET real_int15
bioD8	DW OFFSET real_int15
bioD9	DW OFFSET real_int15
bioDA	DW OFFSET real_int15
bioDB	DW OFFSET real_int15
bioDC	DW OFFSET real_int15
bioDD	DW OFFSET real_int15
bioDE	DW OFFSET real_int15
bioDF	DW OFFSET real_int15
bioE0	DW OFFSET real_int15
bioE1	DW OFFSET real_int15
bioE2	DW OFFSET real_int15
bioE3	DW OFFSET real_int15
bioE4	DW OFFSET real_int15
bioE5	DW OFFSET real_int15
bioE6	DW OFFSET real_int15
bioE7	DW OFFSET real_int15
bioE8	DW OFFSET real_int15
bioE9	DW OFFSET real_int15
bioEA	DW OFFSET real_int15
bioEB	DW OFFSET real_int15
bioEC	DW OFFSET real_int15
bioED	DW OFFSET real_int15
bioEE	DW OFFSET real_int15
bioEF	DW OFFSET real_int15
bioF0	DW OFFSET real_int15
bioF1	DW OFFSET real_int15
bioF2	DW OFFSET real_int15
bioF3	DW OFFSET real_int15
bioF4	DW OFFSET real_int15
bioF5	DW OFFSET real_int15
bioF6	DW OFFSET real_int15
bioF7	DW OFFSET real_int15
bioF8	DW OFFSET real_int15
bioF9	DW OFFSET real_int15
bioFA	DW OFFSET real_int15
bioFB	DW OFFSET real_int15
bioFC	DW OFFSET real_int15
bioFD	DW OFFSET real_int15
bioFE	DW OFFSET real_int15
bioFF	DW OFFSET real_int15

int15:
	SimSti
	mov bl,ah
	xor bh,bh
	add bx,bx
	push word ptr cs:[bx].int15_tab
	mov bx,[bp].vm_ebx
	retn

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DEFAULT_GET_BIOS_DATA
;
;		DESCRIPTION:	Default for GetBiosData
;
;		PARAMETERS:		AL		Value
;						BX		Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_get_bios_data	PROC far
	push ds
	push dx
	mov dx,flat_sel
	mov ds,dx
	movzx ebx,bx
	mov al,[ebx+400h].page0_linear
	pop dx
	pop ds
	ret
default_get_bios_data	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DEFAULT_SET_BIOS_DATA
;
;		DESCRIPTION:	Default for SetBiosData
;
;		PARAMETERS:		AL		Value
;						BX		Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_set_bios_data	PROC far
	push ds
	push dx
	mov dx,flat_sel
	mov ds,dx
	movzx ebx,bx
	mov [ebx+400h].page0_linear,al
	pop dx
	pop ds
	ret
default_set_bios_data	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GET_BIOS_DATA
;
;		DESCRIPTION:	Get BIOS data
;
;		PARAMETERS:		AL		Value
;						BX		Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_bios_data_name	DB 'Get BIOS Data',0

get_bios_data	PROC far
	push bios_data_sel
	pop ds
	shl bx,3
	push word ptr [bx+2]
	push word ptr [bx]
	shr bx,3
	ret
get_bios_data	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SET_BIOS_DATA
;
;		DESCRIPTION:	Set BIOS data
;
;		PARAMETERS:		AL		Value
;						BX		Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_bios_data_name	DB 'Set BIOS Data',0

set_bios_data	PROC far
	push bios_data_sel
	pop ds
	shl bx,3
	push word ptr [bx+6]
	push word ptr [bx+4]
	shr bx,3
	ret
set_bios_data	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HOOK_GET_BIOS_DATA
;
;		DESCRIPTION:	Add hook for GetBiosData
;
;		PARAMETERS:		BX		Offset in BDA
;						ES:DI	Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_get_bios_data_name	DB 'Hook Get BIOS Data',0

hook_get_bios_data	PROC far
	push ds
	push ax
	push bx
	mov ax,bios_data_sel
	mov ds,ax
	shl bx,3	
	mov [bx],di
	mov [bx+2],es
	pop bx
	pop ax
	pop ds
	ret
hook_get_bios_data	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HOOK_SET_BIOS_DATA
;
;		DESCRIPTION:	Add hook for SetBiosData
;
;		PARAMETERS:		BX		Offset in BDA
;						ES:DI	Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_set_bios_data_name	DB 'Hook Set BIOS Data',0

hook_set_bios_data	PROC far
	push ds
	push ax
	push bx
	mov ax,bios_data_sel
	mov ds,ax
	shl bx,3
	mov [bx+4],di
	mov [bx+6],es
	pop bx
	pop ax
	pop ds
	ret
hook_set_bios_data	ENDP

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


init	PROC far
	pusha
	push ds
	push es
	mov bx,bios_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov al,15h
	mov di,OFFSET int15
	HookVMInt
;
	mov si,OFFSET get_bios_data
	mov di,OFFSET get_bios_data_name
	xor cl,cl
	mov ax,get_bios_data_nr
	RegisterOsGate
;
	mov si,OFFSET set_bios_data
	mov di,OFFSET set_bios_data_name
	xor cl,cl
	mov ax,set_bios_data_nr
	RegisterOsGate
;
	mov si,OFFSET hook_get_bios_data
	mov di,OFFSET hook_get_bios_data_name
	xor cl,cl
	mov ax,hook_get_bios_data_nr
	RegisterOsGate
;
	mov si,OFFSET hook_set_bios_data
	mov di,OFFSET hook_set_bios_data_name
	xor cl,cl
	mov ax,hook_set_bios_data_nr
	RegisterOsGate
;
	mov eax,800h
	mov bx,bios_data_sel
	AllocateFixedSystemMem
	mov ds,bx
	xor bx,bx
	mov cx,100h
init_bios_data_loop:
	mov word ptr [bx],OFFSET default_get_bios_data
	mov [bx+2],cs
	mov word ptr [bx+4],OFFSET default_set_bios_data
	mov [bx+6],cs
	add bx,8
	loop init_bios_data_loop
;	
	pop es
	pop ds
	popa
	ret
init	ENDP

code	ENDS

	END init

