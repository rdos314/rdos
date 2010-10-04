;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
; KDEBUG.ASM
; Kernel part kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  KDEBUG

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\os\kdebug.def
INCLUDE ..\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.def

;	ds = datasegment

.386p
.387

osgate_entry    STRUC
og_sel          DW ?
og_offset           DW ?
og_name_sel         DW ?
og_name_offset  DW ?
osgate_entry    ENDS

code	SEGMENT byte use16 public 'CODE'

	extrn init_local:near
	extrn init_ipc_debug:near

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadData
;
;		DESCRIPTION:	
;
;		PARAMETERS:		DX:EBX	ADDRESS
;						ES		THREAD
;						AL		RESULT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadData
    
ReadData	Proc near
	push bx
	push esi
	mov esi,ebx
	mov bx,es
	test gs:tss_eflags+2,2
	jz read_data_prot
read_data_virt:
	ReadThreadSegment
	jmp read_data_done
read_data_prot:
	ReadThreadSelector
read_data_done:
	pop esi
	pop bx
	ret
ReadData	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetIllegalOsGate
;
;           DESCRIPTION:    Get illegal OS gate name
;
;           PARAMETERS:     ES:DI       Name buffer
;                           CX          Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetIllegalOsGate
    
GetIllegalOsGate    PROC near
    push ds
    push fs
    mov ax,osgate_sel
    mov ds,ax
    mov fs,[bx].og_name_sel
    mov si,[bx].og_name_offset
    xor bx,bx
illegal_out_os_loop:
    mov al,fs:[si]
    or al,al
    je illegal_out_os_ok
    stosb
    inc si
    inc bx
    loop illegal_out_os_loop
illegal_out_os_ok:
    inc cx
    mov al,' '
    rep stosb       
    pop fs
    pop ds
    ret
GetIllegalOsGate    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Register writes
;
;		DESCRIPTION:	
;
;		PARAMETERS:		GS			Address to readable TSS
;						FS			Screen selector
;						Uses all registers
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ds_sel
ds_sel	PROC near
	mov ax,gs:tss_ds
	mov ds:data_sel,ax
	ret
ds_sel	ENDP

	public ss_sel
ss_sel	PROC near
	mov ax,gs:tss_ss
	mov ds:data_sel,ax
	ret
ss_sel	ENDP

	public cs_sel
cs_sel	PROC near
	mov ax,gs:tss_cs
	mov ds:data_sel,ax
	ret
cs_sel	ENDP

	public es_sel
es_sel	PROC near
	mov ax,gs:tss_es
	mov ds:data_sel,ax
	ret
es_sel	ENDP

	public fs_sel
fs_sel	PROC near
	mov ax,gs:tss_fs
	mov ds:data_sel,ax
	ret
fs_sel	ENDP

	public gs_sel
gs_sel	PROC near
	mov ax,gs:tss_gs
	mov ds:data_sel,ax
	ret
gs_sel	ENDP

	public no_adr
no_adr	PROC near
	xor eax,eax
	ret
no_adr	ENDP

	public bx_adr
bx_adr	PROC near
	movzx eax,gs:tss_ebx
	ret
bx_adr	ENDP

	public bp_adr
bp_adr	PROC near
	movzx eax,gs:tss_ebp
	ret
bp_adr	ENDP

	public si_adr
si_adr	PROC near
	movzx eax,gs:tss_esi
	ret
si_adr	ENDP

	public di_adr
di_adr	PROC near
	movzx eax,gs:tss_edi
	ret
di_adr	ENDP

	public eax_adr
eax_adr	PROC near
	mov eax,dword ptr gs:tss_eax
	ret
eax_adr	ENDP

	public ebx_adr
ebx_adr	PROC near
	mov eax,dword ptr gs:tss_ebx
	ret
ebx_adr	ENDP

	public ecx_adr
ecx_adr	PROC near
	mov eax,dword ptr gs:tss_ecx
	ret
ecx_adr	ENDP

	public edx_adr
edx_adr	PROC near
	mov eax,dword ptr gs:tss_edx
	ret
edx_adr	ENDP

	public esi_adr
esi_adr	PROC near
	mov eax,dword ptr gs:tss_esi
	ret
esi_adr	ENDP

	public edi_adr
edi_adr	PROC near
	mov eax,dword ptr gs:tss_edi
	ret
edi_adr	ENDP

	public ebp_adr
ebp_adr	PROC near
	mov eax,dword ptr gs:tss_ebp
	ret
ebp_adr	ENDP

	public esp_adr
esp_adr	PROC near
	mov eax,dword ptr gs:tss_esp
	ret
esp_adr	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		DESCRIPTION:	Init kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    call init_local
    call init_ipc_debug
    ret
init    Endp
	
code	ENDS

	END init
