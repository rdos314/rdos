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
; SHUTDOWN.ASM
; ZFX86 COM1 "panic" module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME shutdown

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\user.def
INCLUDE ..\os\os.def

	.386p

WriteSIO    Macro index, data
    mov al,index
    out 2Eh,al
    mov al,data
    out 2Fh,al
        ENDM

ReadSIO    Macro index
    mov al,index
    out 2Eh,al
    in al,2Fh
        ENDM

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			boot_ram
;
;		DESCRIPTION:	get free ram during boot
;
;		RETURNS:		ESI		address to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

boot_ram	Proc near
	push ds
	push ax
	mov ax,system_data_sel
	mov ds,ax
	mov esi,ds:alloc_base
    mov ax,flat_sel
    mov ds,ax
    jmp RamNext
RamLoop:
    mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je RamFound
RamNext:
    add esi,1000h
    jmp RamLoop
    
RamFound:
	mov ax,system_data_sel
	mov ds,ax
	mov ds:alloc_base,esi
	pop ax
	pop ds
	ret
boot_ram	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StartSerial
;
;		DESCRIPTION:	start serial port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartSerial	Proc near
    WriteSIO 7, 3
    WriteSIO 30h, 1
    WriteSIO 60h, 3
    WriteSIO 61h, 0F8h
;
	mov al,83h
	mov dx,3F8h + 3
	out dx,al				; set line control to divisor access
;
	mov dx,3F8h
	mov al,1
	out dx,al				; output LSB divisor latch
;
	mov dx,3F8h + 1
	mov al,0
	out dx,al				; output MSB divisor latch
;
    mov dx,3F8h + 2
    mov al,1
    out dx,al               ; enable FIFOs if present
;
	mov al,3
	mov dx,3F8h + 3
	out dx,al				; set line control 
;
	mov dx,3F8h + 1
	mov al,0
	out dx,al				; disable rx ints, disable tx, line and modem ints
;
	mov dx,3F8h + 4
	mov al,0Bh
	out dx,al				; modem control, DTR = high, RTS = high
	ret
StartSerial	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteChar
;
;		DESCRIPTION:	Write a char to serial port
;
;		PARAMETERS:		AL		CHAR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteChar	PROC near
    push ax
    push dx
;
    mov ah,al
    
WriteCharWaitLoop:
    mov dx,3F8h+5
    in al,dx
    test al,40h
    jz WriteCharWaitLoop
;
    mov dx,3F8h
    mov al,ah
    out dx,al
;
    pop dx
    pop ax
	ret
WriteChar	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteCRLF
;
;		DESCRIPTION:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCRLF	Proc near
    push ax
    push dx
    mov al,0Dh
    call WriteChar
    mov al,0Ah
    call WriteChar
    pop dx
    pop ax
    ret
WriteCRLF   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SingleHex
;
;		DESCRIPTION:
;
;		PARAMETERS:		AL		Value in
;						AX		Value out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SingleHex	Proc near
	mov ah,al
	and al,0F0h
	rol al,4
	cmp al,0Ah
	jb ok_low1
	add al,7
ok_low1:
	add al,30h
	and ah,0Fh
	cmp ah,0Ah
	jb ok_high1
	add ah,7
ok_high1:
	add ah,30h
	ret
SingleHex   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexByte
;
;		DESCRIPTION:
;
;		PARAMETERS:		AL		HEX DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    Proc near
    push ax
	call SingleHex
	call WriteChar
	xchg al,ah
    call WriteChar
    pop ax
    ret
WriteHexByte    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexWord
;
;		DESCRIPTION:
;
;		PARAMETERS:		AX		HEX DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord	Proc near
    xchg al,ah
    call WriteHexByte
    xchg al,ah
    call WriteHexByte
    ret
WriteHexWord    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexDword
;
;		DESCRIPTION:
;
;		PARAMETERS:		EAX		HEX DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword	Proc near
    push eax
    shr eax,16
    call WriteHexWord
    pop eax
    call WriteHexWord
    ret
WriteHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteSizeString
;
;		DESCRIPTION:	Write string to screen
;
;		PARAMETERS:		ES:DI	Address to string
;                       CX      Number of chars
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteSizeString	PROC near
    push ax
    push di

WriteSizeStringLoop:
    call WriteChar
    loop WriteSizeStringLoop

WriteSizeStringDone:
    pop di
    pop ax       
	ret
WriteSizeString	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    WriteDwordReg
;
;		DESCRIPTION:	Write 32-bit registers
;
;		PARAMETERS:		ES:DI	ADDRESS TO TABLE
;						GS		TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	assume gs:tss_seg

WriteDwordReg	PROC near
	push cx
	mov cx,4
	call WriteSizeString
	pop cx
;
	add di,4
	mov bx,es:[di]
	mov eax,gs:[bx]
	call WriteHexDword
	add di,2
	mov al,' '
	call WriteChar
	mov al,es:[di]
	or al,al
	jnz WriteDwordReg
;
	ret
WriteDwordReg	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteWordReg
;
;		DESCRIPTION:	Write 16-bit registers
;
;		PARAMETERS:		ES:DI	ADDRESS TO TABLE
;						GS		TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	assume gs:tss_seg

WriteWordReg	PROC near
	push cx
	mov cx,3
	call WriteSizeString
	pop cx
;
	add di,3
	mov bx,es:[di]
	mov ax,gs:[bx]
	call WriteHexWord
	add di,2
	mov al,' '
	call WriteChar
	mov al,es:[di]
	or al,al
	jnz WriteWordReg
;
	ret
WriteWordReg	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteElags
;
;		DESCRIPTION:	Write EFLAGS
;
;		PARAMETERS:		GS		TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


eflags_tab:
;
;		reset		set
et_cf	DB 'NC ',	'CY '
et_1	DB 0,0,0,	0,0,0
et_pf	DB 'PO ',	'PE '
et_3	DB 0,0,0,	0,0,0
et_af	DB 'NA ',	'AC '
et_5	DB 0,0,0,	0,0,0
et_zf	DB 'NZ ',	'ZR '
et_sf	DB 'PL ',	'NG '
et_tf	DB 0,0,0,	0,0,0
et_if	DB 'DI ',	'EI '
et_df	DB 'UP ',	'DN '
et_of	DB 'NV ',	'OV '
et_12	DB 0,0,0,	0,0,0
et_13	DB 0,0,0,	0,0,0
et_14	DB 'PR ' ,	'NT '
et_15	DB 0,0,0,	0,0,0
et_16	DB 0,0,0,	0,0,0
et_vm	DB 'PM ',	'VM '
et_end	DB 0FFh

WriteEflags	PROC near
	mov bx,OFFSET tss_eflags
	mov eax,gs:[bx]
	mov di,OFFSET eflags_tab
	mov cx,cs
	mov es,cx
eflags_loop:
	mov ch,es:[di]
	or ch,ch
	je eflags_next
	cmp ch,0FFh
	je eflags_done
	push di
	mov cl,10
	test ax,1
	jz eflags_pos_ok
	add di,3
eflags_pos_ok:
	push ax
	mov cx,3
	call WriteSizeString
	pop ax
	pop di
eflags_next:
	add di,6
	shr eax,1
	jmp eflags_loop
eflags_done:
	ret
WriteEflags	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteFault
;
;		DESCRIPTION:	Write fault string
;
;		PARAMETERS:		GS		TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ft_idt	DB 'Idt '
ft_ldt	DB 'Ldt '
ft_gdt	DB 'Gdt '

WriteFault	PROC near
	mov ax,cs
	mov es,ax
	mov ax,gs:tss_error_code
	test ax,2
	jz fault_not_idt
	mov di,OFFSET ft_idt
	jmp write_fault_reason
fault_not_idt:
	mov di,OFFSET ft_gdt
	test ax,4
	jz write_fault_reason
	mov di,OFFSET ft_ldt
write_fault_reason:
	mov cx,4
	call WriteSizeString
	mov ax,gs:tss_error_code
	and ax,0FFF8h
	mov cl,11
	call WriteHexWord
write_fault_end:
	ret
WriteFault	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ABORT_PR
;
;		DESCRIPTION:	Abort app and display dump
;
;		PARAMETERS:		DS		Readable TSS for thread
;						ES		Readable GDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	assume ds:tss_seg

error_code_tab:
ke00	DB 'Divide error            '
ke01	DB 'Single step             '
ke02	DB 'NMI                     '
ke03	DB 'Breakpoint              '
ke04	DB 'Overflow                '
ke05	DB 'Array bounds error      '
ke06	DB 'Invalid OP-code         '
ke07	DB '80387 not present       '
ke08	DB 'Double fault            '
ke09	DB '80387 overrun           '
ke0A	DB 'Invalid TSS             '
ke0B	DB 'Segment not present     '
ke0C	DB 'Stack fault             '
ke0D	DB 'Protection fault        '
ke0E	DB 'Page fault              '
ke0F	DB 'Unknown Fault           '
ke10	DB '80387 error             '
ke11	DB 'Cannot emulate          '
ke12	DB 'Cannot emulate 80387    '
ke13	DB 'Now in real mode        '
ke14	DB '----------------------- '
ke15	DB 'Illegal int request     '
ke16	DB 'Undefined method        '
ke17	DB 'Invalid handle          '
ke18	DB 'Invalid selector        '

dword_reg_tab1:
	DB 'EAX='
	DW OFFSET tss_eax
	DB 'EBX='
	DW OFFSET tss_ebx
	DB 'ECX='
	DW OFFSET tss_ecx
	DB 'EDX='
	DW OFFSET tss_edx
	DB 'ESI='
	DW OFFSET tss_esi
	DB 'EDI='
	DW OFFSET tss_edi
	DB 0
dword_reg_tab2:
	DB 'EPC='
	DW OFFSET tss_eip
	DB 'ESP='
	DW OFFSET tss_esp
	DB 'EBP='
	DW OFFSET tss_ebp
	DB 0
word_reg_tab:
	DB 'CS='
	DW OFFSET tss_cs
	DB 'SS='
	DW OFFSET tss_ss
	DB 'DS='
	DW OFFSET tss_ds
	DB 'ES='
	DW OFFSET tss_es
	DB 'FS='
	DW OFFSET tss_fs
	DB 'GS='
	DW OFFSET tss_gs
	DB 0

pm_es	EQU -12

abort_pretask:
	cli
	cld
	push es
	movzx bx,al
;
	mov ax,system_data_sel
	mov es,ax
	mov eax,[bp].vm_eip
	mov dword ptr es:tss_eip,eax
	mov eax,[bp].vm_eflags
	mov dword ptr es:tss_eflags,eax
	mov eax,[bp].vm_eax
	mov dword ptr es:tss_eax,eax
	mov dword ptr es:tss_ecx,ecx
	mov dword ptr es:tss_edx,edx
	mov eax,[bp].vm_ebx
	mov dword ptr es:tss_ebx,eax
	movzx eax,bp
	add eax,18
	mov dword ptr es:tss_esp,eax
	mov dword ptr es:tss_esi,esi
	mov dword ptr es:tss_edi,edi
	mov ax,[bp].vm_cs
	mov es:tss_cs,ax
	mov es:tss_ss,ss
	mov ax,[bp].pm_ds
	mov es:tss_ds,ax
	mov ax,[bp].pm_es
	mov es:tss_es,ax
	mov es:tss_fs,fs
	mov es:tss_gs,gs
	mov bp,[bp].vm_bp
	mov dword ptr es:tss_ebp,ebp
	sldt ax
	mov es:tss_ldt,ax	
	mov ax,es
	mov gs,ax

abort_fatal_write:
	push bx
	call StartSerial
	mov di,bx
	shl di,3
	mov ax,di
	add ax,ax
	add di,ax
	mov ax,cs
	mov es,ax
	add di,OFFSET error_code_tab
	mov cx,24
	call WriteSizeString
	call WriteCRLF
	call WriteCRLF
	call WriteFault
	call WriteCRLF
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET dword_reg_tab1
	call WriteDwordReg
	call WriteCRLF
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET dword_reg_tab2
	call WriteDwordReg
	call WriteEflags
	call WriteCRLF
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET word_reg_tab
	call WriteWordReg
halt_sys:
	jmp halt_sys
	
abort_task:
	cli
	cld
	call StartSerial
	xor dx,dx
	mov ax,system_data_sel
	mov ds,ax
		assume ds:system_seg
	mov si,OFFSET debug_list
remove_next_waiting:
	mov ax,[si]
	or ax,ax
	jz abort_system
		assume ds:thread_seg,es:thread_seg
	push si
	mov es,[si]
	push di
	push ds
	mov di,es:p_prev
	cmp di,[si]
	mov [si],di
	mov si,es:p_next
	mov ds,di
	mov p_next,si
	mov ds,si
	mov p_prev,di
	pop ds
	pop di
	pop si
	jne not_empty_r
	mov word ptr [si],0
not_empty_r:
	push ds
	push si
	mov ax,es
	call WriteHexWord
	mov al,' '
	call WriteChar
;
	mov di,OFFSET thread_name
	mov cx,30
	call WriteSizeString
;
	mov di,es:p_error_code
	mov gs,es:p_tss_data_sel
	shl di,3
	mov ax,di
	add ax,ax
	add di,ax
	mov ax,cs
	mov es,ax
	add di,OFFSET error_code_tab
	mov cx,24
	call WriteSizeString
	call WriteCRLF
	call WriteCRLF
	call WriteFault
	call WriteCRLF
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET dword_reg_tab1
	call WriteDwordReg
	call WriteCRLF
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET dword_reg_tab2
	call WriteDwordReg
	call WriteEflags
	call WriteCRLF
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET word_reg_tab
	call WriteWordReg
	call WriteCRLF
;
	pop si
	pop ds
	add dh,2
	jmp remove_next_waiting

abort_system:
	jmp abort_system

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init
;
;		DESCRIPTION:	Initialize module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	mov ax,gdt_sel
	mov ds,ax
;
	mov bx,shutdown_pretask_gate
	mov word ptr [bx],OFFSET abort_pretask
	mov [bx+2],cs
	mov word ptr [bx+4],8400h
	mov word ptr [bx+6],0
;
	mov bx,shutdown_task_gate
	mov word ptr [bx],OFFSET abort_task
	mov [bx+2],cs
	mov word ptr [bx+4],8400h
	mov word ptr [bx+6],0
	ret
init	Endp

code	ENDS

.186

END init
