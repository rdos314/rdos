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

usergate_entry	STRUC
ug_name_sel			DW ?
ug_name_offset		DW ?
ug_entry_offset16	DW ?
ug_entry_sel16		DW ?
ug_entry_offset32	DW ?
ug_entry_sel32		DW ?
ug_entry_offset_v86	DW ?	
ug_entry_sel_v86	DW ?
ug_sel16			DW ?
ug_sel32			DW ?
ug_transfer			DW ?
usergate_entry	ENDS

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
;           NAME:           GetIllegalUserGate
;
;           DESCRIPTION:    Get illegal user gate name
;
;           PARAMETERS:     ES:DI       Name buffer
;                           CX          Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetIllegalUserGate
    
GetIllegalUserGate      PROC near
    push ds
    push fs
    mov ax,usergate_sel
    mov ds,ax
    mov fs,[bx].ug_name_sel
    mov si,[bx].ug_name_offset
    xor bx,bx
illegal_out_user_loop:
    mov al,fs:[si]
    or al,al
    je illegal_out_user_ok
    stosb
    inc si
    inc bx
    loop illegal_out_user_loop
illegal_out_user_ok:
    inc cx
    mov al,' '
    rep stosb       
    pop fs
    pop ds
    ret
GetIllegalUserGate      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetOsCall
;
;           DESCRIPTION:    Get OS call gate name
;
;           PARAMETERS:     ES:DI       Name buffer
;                           CX          Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetOsCall
    
GetOsCall       PROC near
    push ds
    push fs
    push si
;    
    mov ax,gs:tss_eflags+2
    test ax,2
    jnz short get_oscall_error
;
    push cx
    mov ax,osgate_sel
    mov ds,ax
    xor si,si
    mov cx,osgate_entries

get_oscall_scan_loop:
    cmp dx,ds:[si].og_sel
    jne get_oscall_scan_next
;
    cmp bx,ds:[si].og_offset
    je get_oscall_found

get_oscall_scan_next:
    add si,8
    loop get_oscall_scan_loop
;
    pop cx
    jmp short get_oscall_error

get_oscall_found:
    pop cx
    mov fs,[si].og_name_sel
    mov si,[si].og_name_offset
    xor bx,bx

get_oscall_out_loop:
    mov al,fs:[si]
    or al,al
    je get_oscall_out_ok
;
    stosb
    inc si
    inc bx
    loop get_oscall_out_loop

get_oscall_out_ok:
    inc cx
    mov al,' '
    rep stosb       
    clc
    jmp get_oscall_end

get_oscall_error:
    stc

get_oscall_end:
    pop si
    pop fs
    pop ds
    ret
GetOsCall       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetUserCall
;
;           DESCRIPTION:    Get user gate name
;
;           PARAMETERS:     ES:DI       Name buffer
;                           CX          Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetUserCall
    
GetUserCall     PROC near
    push ds
    push fs
    push si
    mov ax,gs:tss_eflags+2
    test ax,2
    jnz short get_usercall_error
;
    push cx
    mov ax,usergate_sel
    mov ds,ax
    xor si,si
    mov cx,usergate_entries

get_usercall_scan_loop:
    cmp dx,ds:[si].ug_entry_sel16
    jne get_usercall_not_entry16
;
    cmp bx,ds:[si].ug_entry_offset16
    je get_usercall_found

get_usercall_not_entry16:
    cmp dx,ds:[si].ug_entry_sel32
    jne get_usercall_not_entry32
;
    cmp bx,ds:[si].ug_entry_offset32
    je get_usercall_found

get_usercall_not_entry32:
    cmp dx,ds:[si].ug_sel16
    je get_usercall_found
;
    cmp dx,ds:[si].ug_sel32
    je get_usercall_found
;
    add si,32
    loop get_usercall_scan_loop
;
    pop cx
    jmp short get_usercall_error

get_usercall_found:
    pop cx
    mov fs,[si].ug_name_sel
    mov si,[si].ug_name_offset
    xor bx,bx

get_usercall_out_loop:
    mov al,fs:[si]
    or al,al
    je get_usercall_out_ok
;
    stosb
    inc si
    inc bx
    loop get_usercall_out_loop

get_usercall_out_ok:
    inc cx
    mov al,' '
    rep stosb       
    clc
    jmp get_usercall_end

get_usercall_error:
    stc

get_usercall_end:
    pop si
    pop fs
    pop ds
    ret
GetUserCall     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			interact_inc
;
;		DESCRIPTION:	Interact increment
;
;		PARAMETERS:		GS			TSS
;						DX:ESI		Adress to data
;						CL  		Number of digits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public interact_incr
    
interact_incr	PROC near
	push eax
	push bx
	push esi
	xor eax,eax
	clc
	rcr cl,1
	mov al,cl
	pushf
	add esi,eax
	mov bx,gs:tss_thread
	test gs:tss_eflags+2,2
	jz interact_inc_read_prot
interact_inc_read_virt:
	ReadThreadSegment
	jmp interact_inc_read_done
interact_inc_read_prot:
	ReadThreadSelector
interact_inc_read_done:
	popf
	jnc inc_low
inc_hi:
	add al,10h
	jmp inc_j
inc_low:
	mov ah,al
	inc al
	and al,0Fh
	and ah,0F0h
	or al,ah
inc_j:
	test gs:tss_eflags+2,2
	jz interact_inc_write_prot
interact_inc_write_virt:
	WriteThreadSegment
	jmp interact_inc_write_done
interact_inc_write_prot:
	WriteThreadSelector
interact_inc_write_done:
	pop esi
	pop bx
	pop eax
	ret
interact_incr	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			interact_dec
;
;		DESCRIPTION:	Interact decrement
;
;		PARAMETERS:		GS			TSS
;						DX:ESI		Adress to data
;						CL  		Number of digits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public interact_decr
    
interact_decr	PROC near
	push eax
	push bx
	push esi
	xor eax,eax
	clc
	rcr cl,1
	mov al,cl
	pushf
	add esi,eax
	mov bx,gs:tss_thread
	test gs:tss_eflags+2,2
	jz interact_dec_read_prot
interact_dec_read_virt:
	ReadThreadSegment
	jmp interact_dec_read_done
interact_dec_read_prot:
	ReadThreadSelector
interact_dec_read_done:
	popf
	jnc dec_low
dec_hi:
	sub al,10h
	jmp dec_j
dec_low:
	mov ah,al
	dec al
	and al,0Fh
	and ah,0F0h
	or al,ah
dec_j:
	test gs:tss_eflags+2,2
	jz interact_dec_write_prot
interact_dec_write_virt:
	WriteThreadSegment
	jmp interact_dec_write_done
interact_dec_write_prot:
	WriteThreadSelector
interact_dec_write_done:
	pop esi
	pop bx
	pop eax
	ret
interact_decr	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			interact_set_value
;
;		DESCRIPTION:	Interact set new value
;
;		PARAMETERS:		GS			TSS
;						DX:ESI		Adress to data
;						CL  		Digit #
;						CH			Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public interact_set_value

interact_set_value	PROC near
	push eax
	push bx
	push esi
	xor eax,eax
	clc
	rcr cl,1
	mov al,cl
	pushf
	add esi,eax
	mov bx,gs:tss_thread
	test gs:tss_eflags+2,2
	jz interact_set_read_prot
interact_set_read_virt:
	ReadThreadSegment
	jmp interact_set_read_done
interact_set_read_prot:
	ReadThreadSelector
interact_set_read_done:
	popf
	jnc set_low
set_hi:
	and al,0Fh
	mov ah,ch
	shl ah,4
	or al,ah
	jmp set_j
set_low:
	and al,0F0h
	or al,ch
set_j:
	test gs:tss_eflags+2,2
	jz interact_set_write_prot
interact_set_write_virt:
	WriteThreadSegment
	jmp interact_set_write_done
interact_set_write_prot:
	WriteThreadSelector
interact_set_write_done:
	pop esi
	pop bx
	pop eax
	ret
interact_set_value	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec
;
;           DESCRIPTION:    INC / DEC
;
;           PARAMETERS:     GS          80386 TSS
;                           DX:ESI      address to data
;                           AL          operation ('+' och '-')
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

incdec  PROC near
    mov fs,dx
    cmp al,'+'
    jne not_inc_reg
;
    inc dword ptr fs:[esi]
    ret
not_inc_reg:
    cmp al,'-'
    jne not_dec_reg
;
    dec dword ptr fs:[esi]
    ret
not_dec_reg:
    ret
incdec  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_eax
;
;           DESCRIPTION:    INC / DEC EAX
;
;           PARAMETERS:     GS              8086 TSS
;                           AL          operation ('+' och '-')
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_eax
    
incdec_eax      PROC near
    mov dx,gs
    mov esi,OFFSET tss_eax
    call incdec
    ret
incdec_eax      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_ebx
;
;           DESCRIPTION:    INC / DEC EBX
;
;           PARAMETERS:         GS              8086 TSS
;                           AL          operation ('+' och '-')
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_ebx

incdec_ebx      PROC near
    mov dx,gs
    mov esi,OFFSET tss_ebx
    call incdec
    ret
incdec_ebx      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_ecx
;
;           DESCRIPTION:    INC / DEC ECX
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_ecx

incdec_ecx      PROC near
    mov dx,gs
    mov esi,OFFSET tss_ecx
    call incdec
    ret
incdec_ecx      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_edx
;
;           DESCRIPTION:    INC / DEC EDX
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_edx

incdec_edx      PROC near
    mov dx,gs
    mov esi,OFFSET tss_edx
    call incdec
    ret
incdec_edx      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_esi
;
;           DESCRIPTION:    INC / DEC ESI
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_esi

incdec_esi      PROC near
    mov dx,gs
    mov esi,OFFSET tss_esi
    call incdec
    ret
incdec_esi      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_edi
;
;           DESCRIPTION:    INC / DEC EDI
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_edi

incdec_edi      PROC near
    mov dx,gs
    mov esi,OFFSET tss_edi
    call incdec
    ret
incdec_edi      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_esp
;
;           DESCRIPTION:    INC / DEC ESP
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_esp

incdec_esp      PROC near
    mov dx,gs
    mov esi,OFFSET tss_esp
    call incdec
    ret
incdec_esp      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_ebp
;
;           DESCRIPTION:    INC / DEC EBP
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_ebp

incdec_ebp      PROC near
    mov dx,gs
    mov esi,OFFSET tss_ebp
    call incdec
    ret
incdec_ebp      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_epc
;
;           DESCRIPTION:    INC / DEC EIP
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_epc

incdec_epc      PROC near
    mov dx,gs
    mov esi,OFFSET tss_eip
    call incdec
    ret
incdec_epc      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_cs
;
;           DESCRIPTION:    INC / DEC CS
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_cs

incdec_cs       PROC near
    mov dx,gs
    mov esi,OFFSET tss_cs
    call incdec
    ret
incdec_cs       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_ds
;
;           DESCRIPTION:    INC / DEC DS
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_ds

incdec_ds       PROC near
    mov dx,gs
    mov esi,OFFSET tss_ds
    call incdec
    ret
incdec_ds       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_es
;
;           DESCRIPTION:    INC / DEC ES
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_es

incdec_es       PROC near
    mov dx,gs
    mov esi,OFFSET tss_es
    call incdec
    ret
incdec_es       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_fs
;
;           DESCRIPTION:    INC / DEC FS
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_fs

incdec_fs       PROC near
    mov dx,gs
    mov esi,OFFSET tss_fs
    call incdec
    ret
incdec_fs       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_gs
;
;           DESCRIPTION:    INC / DEC GS
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_gs

incdec_gs       PROC near
    mov dx,gs
    mov esi,OFFSET tss_gs
    call incdec
    ret
incdec_gs       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           incdec_ss
;
;           DESCRIPTION:    INC / DEC SS
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_ss

incdec_ss       PROC near
    mov dx,gs
    mov esi,OFFSET tss_ss
    call incdec
    ret
incdec_ss       ENDP

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
