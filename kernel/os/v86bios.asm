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
; V86BIOS.ASM
; V86 mode code emulation in boot-time environment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME v86bios

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\user.def
INCLUDE ..\os\os.def
INCLUDE ..\os\user.inc
INCLUDE ..\os\os.inc
INCLUDE ..\os\system.inc

list_entry	STRUC

list_link		DW ?
list_thread		DW ?
list_eax		DD ?
list_ebx		DD ?
list_ecx		DD ?
list_edx		DD ?
list_esi		DD ?
list_edi		DD ?
list_ebp		DD ?
list_ds			DW ?
list_es			DW ?
list_flags		DW ?
list_int		DB ?

list_entry	ENDS

v86_bios_data	STRUC

bios_thread		DW ?
bios_list		DW ?
bios_section	section_typ <>

v86_bios_data	ENDS

code	SEGMENT byte public 'CODE'

.386p

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DecodeSelector
;
;		DESCRIPTION:	Decode a selector
;
;		PARAMETERS:		BX		Selector
;
;		RETURNS:		EDX		Base
;						ECX		Limit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeSelector	Proc near
	push ds
	push ax
;
	test bx,7
	jnz decode_sel_fail
;
	mov ax,gdt_sel
	mov ds,ax
	mov al,[bx+5]
	test al,80h
	jz decode_sel_fail
;
	test al,10h
	jz decode_sel_fail
;
	test al,8
	jnz decode_sel_fail
;
	test al,2
	jz decode_sel_fail
;
	xor ch,ch
	mov cl,[bx+6]
	and cl,0Fh
	shl ecx,16
	mov cx,[bx]
	test byte ptr [bx+6],80h
	jz decode_size_ok
;
	shl ecx,12
	or cx,0FFFh

decode_size_ok:
	inc ecx
	mov edx,[bx+2]
	rol edx,8
	mov dl,[bx+7]
	ror edx,8
;
	sub edx,global_page_linear
	jc decode_sel_fail
;
	cmp edx,global_page_size
	jae decode_sel_fail
;
	test dx,0FFFh
	jnz decode_sel_fail
;
	add edx,global_page_linear
	clc
	jmp decode_sel_done

decode_sel_fail:
	stc

decode_sel_done:
	pop ax
	pop ds
	ret
DecodeSelector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HandleInputSel
;
;		DESCRIPTION:	Handle input selectors
;
;		PARAMETERS:		FS		List
;
;		RETURNS:		DS,ES	BIOS selectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleInputSel	Proc near
	mov bx,fs:list_ds
	call DecodeSelector
	jc handle_input_ds_fail
;
	mov ax,process_page_sel
	mov gs,ax
	mov esi,edx
	shr esi,10
	mov edi,40h
	dec ecx
	shr ecx,12
	inc cx
	cmp cx,10h
	jbe handle_input_ds_move
;
	mov cx,10h

handle_input_ds_move:
	mov eax,gs:[esi]
	xchg eax,gs:[edi]
	and ax,0F000h
	or eax,eax
	jz handle_input_ds_next
;
	FreePhysical
handle_input_ds_next:
	add esi,4
	add edi,4
	loop handle_input_ds_move
;
	mov ax,v86_bios_ds_sel
	mov ds,ax
	jmp handle_input_es

handle_input_ds_fail:
	xor ax,ax
	mov ds,ax

handle_input_es:
	mov bx,fs:list_es
	call DecodeSelector
	jc handle_input_es_fail
;
	mov ax,process_page_sel
	mov gs,ax
	mov esi,edx
	shr esi,10
	mov edi,80h
	dec ecx
	shr ecx,12
	inc cx
	cmp cx,10h
	jbe handle_input_es_move
;
	mov cx,10h

handle_input_es_move:
	mov eax,gs:[esi]
	mov gs:[edi],eax
	xchg eax,gs:[edi]
	and ax,0F000h
	or eax,eax
	jz handle_input_es_next
;
	FreePhysical
handle_input_es_next:
	add esi,4
	add edi,4
	loop handle_input_es_move
;
	mov ax,v86_bios_es_sel
	mov es,ax
	jmp handle_input_done

handle_input_es_fail:
	xor ax,ax
	mov es,ax

handle_input_done:
	ret
HandleInputSel	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HandleOutputSel
;
;		DESCRIPTION:	Handle output selectors
;
;		PARAMETERS:		FS		List
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleOutputSel	Proc near
	mov ax,ds
	or ax,ax
	jz handle_output_es
;
	cmp ax,v86_bios_ds_sel
	je handle_output_ds_same
;
	mov bx,fs:list_ds
	call DecodeSelector
	jc handle_output_es
;
	mov ax,process_page_sel
	mov gs,ax
	mov edi,edx
	shr edi,10
;
	mov bx,ds
	push ecx
	GetSelectorBaseSize
	pop ecx
	mov esi,edx
	shr esi,10
	dec ecx
	shr ecx,12
	inc cx
	cmp cx,10h
	jbe handle_output_ds_copy
;
	mov cx,10h

handle_output_ds_copy:
	mov eax,gs:[edi]
	and ax,0F000h
	or eax,eax
	jz handle_output_ds_copy_next
;
	FreePhysical

handle_output_ds_copy_next:
	mov eax,gs:[esi]
	mov gs:[edi],eax
	add esi,4
	add edi,4
	loop handle_output_ds_copy
;
	jmp handle_output_es

handle_output_ds_same:
	mov bx,fs:list_ds
	call DecodeSelector
	jc handle_output_es
;
	mov ax,process_page_sel
	mov gs,ax
	mov edi,edx
	shr edi,10
	mov esi,40h
	dec ecx
	shr ecx,12
	inc cx
	cmp cx,10h
	jbe handle_output_ds_move
;
	mov cx,10h

handle_output_ds_move:
	xor eax,eax
	xchg eax,gs:[esi]
	mov gs:[edi],eax
	add esi,4
	add edi,4
	loop handle_output_ds_move

handle_output_es:
	mov ax,es
	or ax,ax
	jz handle_output_done
;
	cmp ax,v86_bios_es_sel
	je handle_output_es_same
;
	mov bx,fs:list_es
	call DecodeSelector
	jc handle_output_done
;
	mov ax,process_page_sel
	mov gs,ax
	mov edi,edx
	shr edi,10
;
	mov bx,es
	push ecx
	GetSelectorBaseSize
	pop ecx
	mov esi,edx
	shr esi,10
	dec ecx
	shr ecx,12
	inc cx
	cmp cx,10h
	jbe handle_output_es_copy
;
	mov cx,10h

handle_output_es_copy:
	mov eax,gs:[edi]
	and ax,0F000h
	or eax,eax
	jz handle_output_es_copy_next
;
	FreePhysical

handle_output_es_copy_next:
	mov eax,gs:[esi]
	mov gs:[edi],eax
	add esi,4
	add edi,4
	loop handle_output_es_copy
;
	jmp handle_output_done

handle_output_es_same:
	mov bx,fs:list_es
	call DecodeSelector
	jc handle_output_done
;
	mov ax,process_page_sel
	mov gs,ax
	mov edi,edx
	shr edi,10
	mov esi,80h
	dec ecx
	shr ecx,12
	inc cx
	cmp cx,10h
	jbe handle_output_es_move
;
	mov cx,10h

handle_output_es_move:
	xor eax,eax
	xchg eax,gs:[esi]
	mov gs:[edi],eax
	add esi,4
	add edi,4
	loop handle_output_es_move

handle_output_done:
	ret
HandleOutputSel	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			bios_process
;
;		DESCRIPTION:	BIOS process
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bios_name		DB 'V86 BIOS',0

bios_process:
	mov al,16
	SetBitness
;
	mov ax,process_page_sel
	mov ds,ax
	xor bx,bx
	mov eax,7
	mov [bx],eax
;
	mov eax,0A0007h
	mov bx,0A0000h SHR 10
	mov cx,40h
rom_loop:
	mov [bx],eax
	add eax,1000h
	add bx,4
	loop rom_loop
;
	mov eax,0F0007h
	mov bx,0F0000h SHR 10
	mov cx,10h
bios_loop:
	mov [bx],eax
	add eax,1000h
	add bx,4
	loop bios_loop
;
	mov ax,thread_tss_sel
	mov es,ax
	mov di,OFFSET tss_bitmap_space + 3A0h SHR 3
	xor ax,ax
	mov cx,4
	rep stosw	
;
	mov ax,flat_sel
	mov ds,ax
	xor al,al
	mov cx,9
	xor si,si
bios_int_loop1:
	mov bx,[si]
	add si,2
	mov dx,[si]
	add si,2
	SetVMInt
	inc al
	loop bios_int_loop1
;
	mov al,10h
	mov cx,68h
	mov si,10h * 4
bios_int_loop2:
	mov bx,[si]
	add si,2
	mov dx,[si]
	add si,2
	SetVMInt
	inc al
	loop bios_int_loop2
;
	mov al,80h
	mov cx,80h
	mov si,80h * 4
bios_int_loop3:
	mov bx,[si]
	add si,2
	mov dx,[si]
	add si,2
	SetVMInt
	inc al
	loop bios_int_loop3
;
	mov ax,v86_bios_data_sel
	mov ds,ax
	GetThread
	mov ds:bios_thread,ax
	jmp bios_proc_check

bios_proc_loop:
	WaitForSignal
	mov ax,v86_bios_data_sel
	mov ds,ax

bios_proc_check:
	mov ax,ds:bios_list
	or ax,ax
	jz bios_proc_loop
;
	EnterSection ds:bios_section
	mov fs,ds:bios_list
	mov ax,fs:list_link
	mov ds:bios_list,ax
	LeaveSection ds:bios_section
;
	mov ax,flat_sel
	mov ds,ax
	movzx bx,fs:list_int
	shl bx,2
	push dword ptr [bx]
;
	call HandleInputSel
	push fs:list_flags
	mov eax,fs:list_eax
	mov ebx,fs:list_ebx
	mov ecx,fs:list_ecx
	mov edx,fs:list_edx
	mov esi,fs:list_esi
	mov edi,fs:list_edi
	mov ebp,fs:list_ebp
	popf
	CallVm
;
	pushf
	pop fs:list_flags
	mov fs:list_eax,eax
	mov fs:list_ebx,ebx
	mov fs:list_ecx,ecx
	mov fs:list_edx,edx
	mov fs:list_esi,esi
	mov fs:list_edi,edi
	mov fs:list_ebp,ebp
	call HandleOutputSel
;
	mov bx,fs:list_thread
	xor ax,ax
	mov fs,ax
	Signal
	jmp bios_proc_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			V86BiosInt
;
;		DESCRIPTION:	Run int in real BIOS
;
;		PARAMETERS:		Stack	Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

v86_bios_int_name	DB 'V86 BIOS Int',0

V86_bios_int	Proc far
	push ds
	push es
;
	push eax
	pushf
	mov eax,SIZE list_entry
	AllocateSmallGlobalMem
	pop es:list_flags
	pop es:list_eax
	pop es:list_es
	pop es:list_ds
	mov es:list_ebx,ebx
	mov es:list_ecx,ecx
	mov es:list_edx,edx
	mov es:list_esi,esi
	mov es:list_edi,edi
	mov es:list_ebp,ebp
	mov bp,sp
	mov al,[bp+4]
	mov es:list_int,al	
;
	GetThread
	mov es:list_thread,ax
	mov ax,v86_bios_data_sel
	mov ds,ax
;
	ClearSignal
	EnterSection ds:bios_section
	mov ax,ds:bios_list
	mov es:list_link,ax
	mov ds:bios_list,es
	LeaveSection ds:bios_section
;
	mov bx,ds:bios_thread
	Signal
	WaitForSignal
;
	mov eax,es:list_eax
	mov ebx,es:list_ebx
	mov ecx,es:list_ecx
	mov edx,es:list_edx
	mov esi,es:list_esi
	mov edi,es:list_edi
	mov ebp,es:list_ebp
	push es:list_ds
	push es:list_es
	push es:list_flags
	FreeMem
	popf
;
	pop es
	pop ds
	ret 2
v86_bios_int	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_process
;
;		DESCRIPTION:	init BIOS process
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process	PROC far
	push ds
	push es
	pusha
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET bios_process
	mov di,OFFSET bios_name
	mov ecx,512
	mov ax,5
	CreateProcess
	popa
	pop es
	pop ds
	ret
init_process	ENDP

init	PROC far
	push ds
	push es
	pusha
	mov bx,v86_bios_code_sel
	InitDevice
;
	mov eax,SIZE v86_bios_data
	mov bx,v86_bios_data_sel
	AllocateFixedSystemMem
	mov ds,bx
	InitSection ds:bios_section
	mov ds:bios_list,0
	mov ds:bios_thread,0
;
	mov bx,v86_bios_ds_sel
	mov edx,10000h
	mov ecx,10000h
	CreateDataSelector16
;
	mov bx,v86_bios_es_sel
	mov edx,20000h
	mov ecx,10000h
	CreateDataSelector16
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET init_process
	HookInitTasking
;
	mov si,OFFSET v86_bios_int
	mov di,OFFSET v86_bios_int_name
	mov cl,1
	mov ax,v86_bios_int_nr
	RegisterOsGate
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init
