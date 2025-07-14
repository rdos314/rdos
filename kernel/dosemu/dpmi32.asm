;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; DPMI32.ASM
; 32-bit DPMI functions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

@WordSize = 4

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE int.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE dpmi.inc
INCLUDE system.inc

	.386p

code	SEGMENT byte public use32 'CODE'

	assume cs:code	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_DESCR
;
;		DESCRIPTION:	ALLOCATE SELECTORS
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_descr	PROC far
	cmp cx,1
	je dpmi_create_one
	AllocateMultipleLdt
	jmp dpmi_create_done
dpmi_create_one: 
	AllocateLdt
dpmi_create_done:
	GetThread
	mov ds,ax
	mov ds,ds:p_ldt_sel
	xor ax,ax
	mov [bx],ax
	mov [bx+2],ax
	mov [bx+4],al
	mov byte ptr [bx+5],0F2h
	mov [bx+7],al
	mov byte ptr [bx+6],40h
	mov ax,bx
	or ax,7
	mov ebx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags,NOT 1
	retf
allocate_descr	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FREE_DESCR
;
;		DESCRIPTION:	FREE SELECTOR
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_descr	PROC far
	push ds
	push es
	push fs
	push gs
	xor ax,ax
	mov ds,ax
	mov es,ax
	mov fs,ax
	mov gs,ax
	test bl,4
	jz free_descr_fail
	and bl,0F8h
	FreeLdt
	clc
	pop eax
	verr ax
	jnz free_gs
	mov gs,ax
free_gs:
	pop eax
	verr ax
	jnz free_fs
	mov fs,ax
free_fs:
	pop eax
	verr ax
	jnz free_es
	mov es,ax
free_es:
	pop eax
	verr ax
	jnz free_ds
	mov ds,ax
free_ds:
	and byte ptr [bp].vm_eflags,NOT 1
	mov eax,[bp].vm_eax
	mov bx,[bp].vm_ebx
	retf
free_descr_fail:
	or byte ptr [bp].vm_eflags,1
	mov ax,[bp].vm_eax
	mov bx,[bp].vm_ebx
	pop gs
	pop fs
	pop es
	pop ds
	retf
free_descr	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_DECSR_DIST
;
;		DESCRIPTION:	GET DISTANCE BETWEEN SELECTORS
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_descr_dist	PROC far
	mov ax,8
	and byte ptr [bp].vm_eflags,NOT 1
	retf
get_descr_dist	ENDP

page

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_DECSR_BASE
;
;		DESCRIPTION:	GET SELCTOR BASE
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_descr_base	PROC far
	test bl,4
	jz get_descr_base_fail
	GetThread
	mov ds,ax
	mov ds,ds:p_ldt_sel
	and bl,0F8h
	mov al,[bx+5]
	and al,70h
	cmp al,70h
	jnz get_descr_base_fail
	mov dx,[bx+2]
	mov cl,[bx+4]
	mov ch,[bx+7]
	mov bx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags,NOT 1
	retf
get_descr_base_fail:
	or byte ptr [bp].vm_eflags,1
	retf
get_descr_base	ENDP

page

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_DECSR_BASE
;
;		DESCRIPTION:	SET SELCTOR BASE
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_descr_base	PROC far
	push es
	push fs
	push gs
	test bl,4
	jz set_descr_base_fail
	push ax
	GetThread
	mov ds,ax
	pop ax
	mov ds,ds:p_ldt_sel
	and bl,0F8h
	mov al,[bx+5]
	and al,70h
	cmp al,70h
	jnz set_descr_base_fail
	mov [bx+2],dx
	mov [bx+4],cl
	mov [bx+7],ch
	mov ax,[bp].vm_eax
	mov bx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags,NOT 1
	pop gs
	pop fs
	pop es
	retf
set_descr_base_fail:
	or byte ptr [bp].vm_eflags,1
	pop gs
	pop fs
	pop es
	retf
set_descr_base	ENDP

page

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_DECSR_LIMIT
;
;		DESCRIPTION:	SET SELCTOR LIMIT
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_descr_limit	PROC far
	push es
	push fs
	push gs
	test bl,4
	jz set_descr_limit_fail
	GetThread
	mov ds,ax
	mov ds,ds:p_ldt_sel
	and bl,0F8h
	mov al,[bx+5]
	and al,70h
	cmp al,70h
	jnz set_descr_limit_fail
	push cx
	push dx
	pop eax
	cmp eax,100000h
	jc set_descr_small
	shr eax,12
	or byte ptr [bx+6],80h
	jmp set_descr_lim_do
set_descr_small:
	and byte ptr [bx+6],7Fh
set_descr_lim_do:
	mov [bx],ax
	shr eax,16
	mov ah,[bx+6]
	and ah,0F0h
	or al,ah
	mov [bx+6],al
	and byte ptr [bp].vm_eflags,NOT 1
	mov eax,[bp].vm_eax
	mov bx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	pop gs
	pop fs
	pop es
	retf
set_descr_limit_fail:
	or byte ptr [bp].vm_eflags,1
	pop gs
	pop fs
	pop es
	retf
set_descr_limit	ENDP

page

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_CODE_DESCR_ALIAS
;
;		DESCRIPTION:	CREATES CODE DESCRIPTOR ALIAS
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_code_descr_alias	PROC far
	or bl,3
	verr bx
	jnz create_code_alias_fail
	test bl,4
	jz create_code_alias_fail
	GetThread
	mov ds,ax
	mov ds,ds:p_ldt_sel
	and bl,0F8h
	push es
	push esi
	push edi
	mov ax,ds
	mov es,ax
	movzx esi,bx
	AllocateLdt
	movzx edi,bx
	movsd
	movsd
	mov byte ptr [bx+5],0F2h
	pop edi
	pop esi
	pop es
	mov ax,bx
	or al,7
	mov bx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags,NOT 1
	retf
create_code_alias_fail:
	mov ax,[bp].vm_eax
	mov bx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	or byte ptr [bp].vm_eflags,1
	retf
create_code_descr_alias	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SEGMENT_TO_DESCR
;
;		DESCRIPTION:	SEGMENT TO DESCR
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment_to_descr	PROC far
	AllocateLdt
	movzx eax,word ptr[bp].vm_ebx
	shl eax,4
	mov [bx+2],eax
	xor ax,ax
	mov byte ptr [bx+5],0F2h
	mov [bx+7],al
	dec ax
	mov [bx],ax
	mov byte ptr [bx+6],40h
	or bx,7
	mov [bp].vm_eax,bx
	mov eax,[bp].vm_eax
	mov ebx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags,NOT 1
	retf
segment_to_descr	ENDP

page

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_DECSR_ACCESS
;
;		DESCRIPTION:	SET SELCTOR ACCESS RIGHTS
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_descr_access	PROC far
	push es
	push fs
	push gs
	test bl,4
	jz set_descr_access_fail
	mov al,cl
	and al,70h
	cmp al,70h
	jnz set_descr_access_fail
	test cl,8
	jz set_descr_access_ok
	test cl,4
	jnz set_descr_access_fail
	test cl,2
	jz set_descr_access_fail
set_descr_access_ok:
	test ch,30h
	jnz set_descr_access_fail
	and ch,0F0h
	GetThread
	mov ds,ax
	mov ds,ds:p_ldt_sel
	and bl,0F8h
	mov al,[bx+5]
	and al,70h
	cmp al,70h
	jnz set_descr_access_fail
	mov [bx+5],cl
	mov al,[bx+6]
	and al,0Fh
	or al,ch
	mov [bx+6],al
	and byte ptr [bp].vm_eflags,NOT 1
	mov ax,[bp].vm_eax
	mov bx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	pop gs
	pop fs
	pop es
	retf
set_descr_access_fail:
	mov ax,[bp].vm_eax
	or byte ptr [bp].vm_eflags,1
	pop gs
	pop fs
	pop es
	retf
set_descr_access	ENDP

page

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_DESCR
;
;		DESCRIPTION:	GET DESCRIPTOR
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_descr	PROC far
	test bl,4
	jz get_descr_fail
	GetThread
	mov ds,ax
	mov ds,ds:p_ldt_sel
	and bl,0F8h
	mov al,[bx+5]
	and al,70h
	cmp al,70h
	jnz get_descr_fail
	mov eax,[bx]
	mov es:[edi],eax
	mov eax,[bx+4]
	mov es:[edi+4],eax
	mov eax,[bp].vm_eax
	mov bx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags,NOT 1
	retf
get_descr_fail:
	or byte ptr [bp].vm_eflags,1
	retf
get_descr	ENDP

page

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_DESCR
;
;		DESCRIPTION:	SET DESCRIPTOR
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_descr	PROC far
	push es
	push fs
	push gs
	test bl,4
	jz set_descr_fail
	mov al,es:[edi+6]
	test al,30h
	jnz set_descr_fail
	mov al,es:[edi+5]
	and al,70h
	cmp al,70h
	jnz set_descr_fail
	mov al,es:[edi+5]
	test al,8
	jz set_descr_ok
	test al,4
	jnz set_descr_fail
	test al,2
	jz set_descr_fail
set_descr_ok:
	GetThread
	mov ds,ax
	mov ds,ds:p_ldt_sel
	and bl,0F8h
	mov al,[bx+5]
	and al,70h
	cmp al,70h
	jnz set_descr_fail
	mov eax,es:[edi]
	mov [bx],eax
	mov eax,es:[edi+4]
	mov [bx+4],eax
	mov eax,[bp].vm_eax
	mov bx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags,NOT 1
	pop gs
	pop fs
	pop es
	retf
set_descr_fail:
	mov ax,[bp].vm_eax
	or byte ptr [bp].vm_eflags,1
	pop gs
	pop fs
	pop es
	retf
set_descr	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_SPECIFIC_DESCR
;
;		DESCRIPTION:	ALLOCATE SPECIFIC DESCRIPTOR
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_specific_descr	PROC far
	test bl,4
	jz alloc_spec_descr_fail
	cmp bx,100h
	jnc alloc_spec_descr_fail
	and bl,0F8h	
	GetThread
	mov ds,ax
	mov ds,ds:p_ldt_sel
	mov al,[bx+5]
	or al,al
	jnz alloc_spec_descr_fail
	xor ax,ax
	mov [bx],ax
	mov [bx+2],ax
	mov [bx+4],al
	mov byte ptr [bx+5],0F2h
	mov byte ptr [bx+6],40h
	mov [bx+7],al
	mov ax,[bp].vm_eax
	mov ebx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags,NOT 1
	retf
alloc_spec_descr_fail:
	mov ax,[bp].vm_eax
	or byte ptr [bp].vm_eflags,1
	retf
allocate_specific_descr	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_DOS_MEM
;
;		DESCRIPTION:	
;
;		PARAMETERS:		BX			NUMBER OF PARAGRAPH
;						
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dos_mem	PROC far
	push ds
	push es
	push bx
	movzx eax,bx
	shl eax,4
	AllocateDosMem
	jc allocate_dos_mem_fail
	GetThread
	mov ds,ax
	mov ds,ds:p_ldt_sel
	mov bx,es
	mov dx,bx
	and bx,0FFF8h
	mov eax,[bx+2]
	shr eax,4
	and eax,0FFFFh
	and byte ptr [bp].vm_eflags,NOT 1
	pop bx
	pop es
	pop ds
	retf

allocate_dos_mem_fail:
	pop bx
	pop es
	pop ds
	push eax
	push edx
	AvailableDosLinear
	shr edx,4
	mov bx,dx
	pop edx
	pop eax
	or byte ptr [bp].vm_eflags,1
	retf
allocate_dos_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FREE_DOS_MEM
;
;		DESCRIPTION:	
;
;		PARAMETERS:		DX			SELECTOR TO FREE
;						
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_dos_mem	PROC far
	push es
;
	verr dx
	jnz free_dos_mem_fail
;
	mov es,dx
	FreeMem
	and byte ptr [bp].vm_eflags,NOT 1
	pop es
	retf

free_dos_mem_fail:
	or byte ptr [bp].vm_eflags,1
	mov ax,8022h
	pop es
	retf
free_dos_mem	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_REAL_INT
;
;		DESCRIPTION:	GET REAL MODE INT VECTOR
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_real_int	PROC far
	mov al,bl
	GetVMInt
	mov cx,dx
	mov dx,bx
	mov ax,[bp].vm_eax
	mov bx,[bp].vm_ebx
	and byte ptr [bp].vm_eflags,NOT 1
	retf
get_real_int	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_REAL_INT
;
;		DESCRIPTION:	SET REAL MODE INT VECTOR
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_real_int	PROC far
	mov al,bl
	mov bx,dx
	mov dx,cx
	SetVMInt
	mov ax,[bp].vm_eax
	mov bx,[bp].vm_ebx
	and byte ptr [bp].vm_eflags,NOT 1
	retf
set_real_int	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_EXCEPTION
;
;		DESCRIPTION:	GET EXCEPTION VECTOR
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exception	PROC far
	push es
	push edi
	mov al,bl
	GetException
	mov cx,es
	mov edx,edi
	pop edi
	pop es
	mov ax,[bp].vm_eax
	and byte ptr [bp].vm_eflags,NOT 1
	retf
get_exception	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_EXCEPTION
;
;		DESCRIPTION:	SET EXCEPTION VECTOR
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_exception	PROC far
	push es
	push edi
	mov al,bl
	cmp al,1
	je set_exc_ignore
;
	cmp al,3
	je set_exc_ignore
;
	cmp al,0Dh
	je set_exc_ignore
;
	mov es,cx
	mov edi,edx
	SetException

set_exc_ignore:
	pop edi
	pop es
	mov ax,[bp].vm_eax
	and byte ptr [bp].vm_eflags,NOT 1
	retf
set_exception	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_VECTOR
;
;		DESCRIPTION:	GET INT VECTOR
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vector	PROC far
	push es
	push edi
	mov al,bl
	GetPMInt
	mov cx,es
	mov edx,edi
	pop edi
	pop es
	mov ax,[bp].vm_eax
	and byte ptr [bp].vm_eflags,NOT 1
	retf
get_vector	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_VECTOR
;
;		DESCRIPTION:	SET INT VECTOR
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_vector	PROC far
	push es
	push edi
	mov al,bl
	mov es,cx
	mov edi,edx
	SetPMInt
	pop edi
	pop es
	mov ax,[bp].vm_eax
	and byte ptr [bp].vm_eflags,NOT 1
	retf
set_vector	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SIM_REAL_INT
;
;		DESCRIPTION:	SIMULERA REAL MODE INT
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_real_int	PROC far
	push esi
	mov ds,[bp].vm_ss
	movzx esi,word ptr [bp].vm_esp
	mov al,bl
	DpmiInt
	pop esi
	mov ds,[bp].pm_ds
	mov eax,[bp].vm_eax
	and byte ptr [bp].vm_eflags, NOT 1
	retf
sim_real_int	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SIM_REAL_CALL
;
;		DESCRIPTION:	SIMULERA REAL MODE CALL
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_real_call	PROC far
	push esi
	mov ds,[bp].vm_ss
	movzx esi,word ptr [bp].vm_esp
	DpmiCall
	pop esi
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags, NOT 1
	retf
sim_real_call	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SIM_REAL_CALL_INT
;
;		DESCRIPTION:	SIMULERA REAL MODE CALL WITH IRET
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_real_call_int	PROC far
	push esi
	mov ds,[bp].vm_ss
	movzx esi,word ptr [bp].vm_esp
	DpmiCallInt
	pop esi
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags, NOT 1
	retf
sim_real_call_int	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_VM_CALLBACK
;
;		DESCRIPTION:	ALLOKERA VM CALLBACK
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_vm_callback	PROC far
	AllocateVMCallback
	mov cx,dx
	mov dx,ax
	mov ax,[bp].vm_eax
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags, NOT 1
	retf
allocate_vm_callback	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FREE_VM_CALLBACK
;
;		DESCRIPTION:	FRIG™R VM CALLBACK
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_vm_callback	PROC far
	push cx
	push dx
	mov ax,dx
	mov dx,cx
	FreeVMCallback
	pop dx
	pop cx
	and byte ptr [bp].vm_eflags, NOT 1
	retf
free_vm_callback	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DPMI_GET_STATE_SR_ADDR
;
;		DESCRIPTION:	GET STATE SAVE/RESTORE ADDRESS
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dpmi_get_save_restore_addr	PROC far
	xor ax,ax
	and byte ptr [bp].vm_eflags,NOT 1
	retf
dpmi_get_save_restore_addr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DPMI_GET_RAW_SWITCH_ADDR
;
;		DESCRIPTION:	GET RAW MODE SWITCH ADDRESS
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dpmi_get_raw_switch_addr	PROC far
	GetRawSwitchAds
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags,NOT 1
	retf
dpmi_get_raw_switch_addr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_VERSION
;
;		DESCRIPTION:	GET DPMI VERSION
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
get_version	PROC far
	mov ax,9
	mov bx,5
	mov cl,3
	mov dx,2838h
	and byte ptr [bp].vm_eflags,NOT 1
	retf
get_version	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_FREE_MEM
;
;		DESCRIPTION:	GET FREE MEMORY INFO
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
get_free_mem	PROC far
	push eax
	push edx
	UsedLocalLinear
	mov edx,eax
	AvailableLocalLinear
	add edx,eax
	shr edx,12
	mov es:[edi],eax
	shr eax,12
	mov es:[edi+4],eax
	mov es:[edi+8],eax
	mov es:[edi+12],edx
	mov es:[edi+28],edx
	mov dword ptr es:[edi+16],-1
	GetFreePhysical
	shr eax,12
	mov es:[edi+20],eax
	mov dword ptr es:[edi+24],-1
	mov dword ptr es:[edi+32],-1
	pop edx		
	pop eax
	and byte ptr [bp].vm_eflags,NOT 1
	retf
get_free_mem	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_MEM
;
;		DESCRIPTION:	ALLOCATE LOCAL MEMORY
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_mem	PROC far
	push edx
	push ecx
	mov eax,8
	AllocateLocalLinear
	push edx
	mov di,dx
	shr edx,16
	mov si,dx
	mov ax,flat_sel
	mov ds,ax	
	mov ax,bx
	shl eax,16
	mov ax,cx
	AllocateLocalLinear
	pop ecx
	mov [ecx],eax
	mov [ecx+4],edx
	pop ecx
	mov cx,dx
	shr edx,16
	mov bx,dx
	pop edx
	mov eax,[bp].vm_eax
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags,NOT 1
	retf
allocate_mem	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FREE_MEM
;
;		DESCRIPTION:	FREE LOCAL MEMORY
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_mem	PROC far
	push ecx
	push edx
	mov dx,si
	shl edx,16
	mov dx,di
	mov ax,flat_sel
	mov ds,ax
	mov ecx,[edx]
	mov edx,[edx+4]
	FreeLinear
	pop edx
	pop ecx
	mov eax,[bp].vm_eax
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags,NOT 1
	retf
free_mem	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RESIZE_MEM
;
;		DESCRIPTION:	RESIZE LOCAL MEMORY
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

resize_mem	PROC far
	push edx
;
	mov ax,flat_sel
	mov ds,ax
;
	mov ax,bx
	shl eax,16
	mov ax,cx
;
	shl esi,16
	mov si,di
	mov ecx,[esi]
	mov edx,[esi+4]
	sub edx,local_page_linear
	ResizeFlatLinear
	jc resize_mem_fail
;
	add edx,local_page_linear
	mov [esi],eax
	mov [esi+4],edx
	mov cx,[esi+4]
	mov bx,[esi+6]
	mov di,si
	shr esi,16
	and byte ptr [bp].vm_eflags,NOT 1
	jmp resize_mem_done

resize_mem_fail:
	mov [esi],ecx
	mov [esi+4],edx
	mov cx,[esi+4]
	mov bx,[esi+6]
	mov di,si
	shr esi,16
	or byte ptr [bp].vm_eflags,1
	
resize_mem_done:
	pop edx
	mov ds,[bp].pm_ds
	retf
resize_mem	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_PAGE_ATTRIB
;
;		DESCRIPTION:	Set page attributes
;
;		PARAMETERS:		ESI		Memory handle
;						EBX		Offset within block
;						ECX		Number of pages
;						ES:EDX	Buffer to attributes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_page_attrib	PROC far
	push ecx
	push edx
	push edi
;
	mov eax,flat_sel
	mov ds,ax
	mov edi,edx
	shl ecx,12
	mov eax,[esi]
	mov edx,[esi+4]
	and bx,0F000h
;
	sub eax,ecx
	jc set_page_range_fail
;
	sub eax,ebx
	jc set_page_range_fail
;
	add edx,ebx
	sub edx,local_page_linear
	jc set_page_range_fail
;
	shr ecx,12

set_page_attrib_loop:
	mov ax,es:[edi]
	test al,7
	jz set_page_uncommited
;
	test al,8
	jz set_page_readonly
;
	mov eax,1000h
	SetFlatLinearReadWrite
	jmp set_page_attrib_next

set_page_readonly:
	mov eax,1000h
	SetFlatLinearRead
	jmp set_page_attrib_next

set_page_uncommited:
	mov eax,1000h
	SetFlatLinearInvalid

set_page_attrib_next:
	add edi,2
	loop set_page_attrib_loop
;
	pop edi
	pop edx
	pop ecx
;
	mov eax,[bp].vm_eax
	mov ds,[bp].pm_ds
	and byte ptr [bp].vm_eflags,NOT 1
	retf

set_page_range_fail:
	mov ax,8025h
;
	or byte ptr [bp].vm_eflags,1
	pop edi
	pop edx
	pop ecx
	xor ecx,ecx
	mov ds,[bp].pm_ds
	retf
set_page_attrib	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DPMI_PAGE_SIZE
;
;		DESCRIPTION:	GET PAGE SIZE 16 AND 32-BIT
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dpmi_page_size	PROC far
	xor bx,bx
	mov cx,1000h
	and byte ptr [bp].vm_eflags,NOT 1
	retf
dpmi_page_size	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_INT
;
;		DESCRIPTION:	GET VIRTUAL INTERRUPT STATE
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


get_int	PROC far
	xor ax,ax
	GetFlags
	shr ax,9
	and al,1
	mov ah,9
	and byte ptr [bp].vm_eflags,NOT 1
	retf
get_int	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_DISABLE_INT
;
;		DESCRIPTION:	GET AND DISABLE VIRTUAL INTERRUPT STATE
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disable_int	PROC far
	xor ax,ax
	GetFlags
	SimCli
	shr ax,9
	and al,1
	mov ah,9
	and byte ptr [bp].vm_eflags,NOT 1
	retf
get_disable_int	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_ENABLE_INT
;
;		DESCRIPTION:	GET AND ENABLE VIRTUAL INTERRUPT STATE
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_enable_int	PROC near
	xor ax,ax
	GetFlags
	SimSti
	shr ax,9
	and al,1
	mov ah,9
	and byte ptr [bp].vm_eflags,NOT 1
	retf
get_enable_int	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_FPU_EMULATION
;
;		DESCRIPTION:	Set FPU emulation
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_fpu_emulation	PROC near
	and byte ptr [bp].vm_eflags,NOT 1
	retf
set_fpu_emulation	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DPMI_DUMMY
;
;		DESCRIPTION:	DUMMY DPMI
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dpmi_dummy	PROC far
	and byte ptr [bp].vm_eflags,NOT 1
	retf
dpmi_dummy	ENDP

dpmi_error	PROC far
	int 3
	or byte ptr [bp].vm_eflags,1
	retf
dpmi_error	ENDP

dpmi_descriptor:
dd_ant	DD 0Dh
dd00	DD OFFSET allocate_descr
dd01	DD OFFSET free_descr
dd02	DD OFFSET segment_to_descr
dd03	DD OFFSET get_descr_dist
dd04	DD OFFSET dpmi_error
dd05	DD OFFSET dpmi_error
dd06	DD OFFSET get_descr_base
dd07	DD OFFSET set_descr_base
dd08	DD OFFSET set_descr_limit
dd09	DD OFFSET set_descr_access
dd0A	DD OFFSET create_code_descr_alias
dd0B	DD OFFSET get_descr
dd0C	DD OFFSET set_descr
dd0D	DD OFFSET allocate_specific_descr

dpmi_dosmem:
ds_ant	DD 2
ds00	DD OFFSET allocate_dos_mem
ds01	DD OFFSET free_dos_mem
ds02	DD OFFSET dpmi_error

dpmi_int:
di_ant	DD 12h
di00	DD OFFSET get_real_int
di01	DD OFFSET set_real_int
di02	DD OFFSET get_exception
di03	DD OFFSET set_exception
di04	DD OFFSET get_vector
di05	DD OFFSET set_vector
di06	DD OFFSET dpmi_error
di07	DD OFFSET dpmi_error
di08	DD OFFSET dpmi_error
di09	DD OFFSET dpmi_error
di0A	DD OFFSET dpmi_error
di0B	DD OFFSET dpmi_error
di0C	DD OFFSET dpmi_error
di0D	DD OFFSET dpmi_error
di0E	DD OFFSET dpmi_error
di0F	DD OFFSET dpmi_error
di10	DD OFFSET get_exception
di11	DD OFFSET dpmi_error
di12	DD OFFSET set_exception

dpmi_translate:
dt_ant	DD 6
dt00	DD OFFSET sim_real_int
dt01	DD OFFSET sim_real_call
dt02	DD OFFSET sim_real_call_int
dt03	DD OFFSET allocate_vm_callback
dt04	DD OFFSET free_vm_callback
dt05	DD OFFSET dpmi_get_save_restore_addr
dt06	DD OFFSET dpmi_get_raw_switch_addr

dpmi_ver:
dv_ant	DD 0
dv00	DD OFFSET get_version

dpmi_mem:
dm_ant	DD 7
dm00	DD OFFSET get_free_mem
dm01	DD OFFSET allocate_mem
dm02	DD OFFSET free_mem
dm03	DD OFFSET resize_mem
dm04	DD OFFSET dpmi_error
dm05	DD OFFSET dpmi_error
dm06	DD OFFSET dpmi_error
dm07	DD OFFSET set_page_attrib

dpmi_page:
dp_ant	DD 4
dp00	DD OFFSET dpmi_dummy
dp01	DD OFFSET dpmi_dummy
dp02	DD OFFSET dpmi_dummy
dp03	DD OFFSET dpmi_dummy
dp04	DD OFFSET dpmi_page_size

dpmi_paging:
dg_ant	DD 3
dg00	DD OFFSET dpmi_error
dg01	DD OFFSET dpmi_error
dg02	DD OFFSET dpmi_dummy
dg03	DD OFFSET dpmi_dummy

dpmi_physical:
dy_ant	DD 0
dy00	DD OFFSET dpmi_dummy

dpmi_virtint:
dr_ant	DD 2
dr00	DD OFFSET get_disable_int
dr01	DD OFFSET get_enable_int
dr02	DD OFFSET get_int

dpmi_vendorapi:
da_ant	DD 0
da00	DD OFFSET dpmi_error

dpmi_debug:
de_ant	DD 3
de00	DD OFFSET dpmi_error
de01	DD OFFSET dpmi_error
de02	DD OFFSET dpmi_error
de03	DD OFFSET dpmi_error

dpmi_empty:
d0_ant	DD 0
d000	DD OFFSET dpmi_error

dpmi_fpu:
df_ant	DD 2
df00	DD OFFSET dpmi_error
df01	DD OFFSET set_fpu_emulation

dpmi_tab:
dpmi00	DD OFFSET dpmi_descriptor
dpmi01	DD OFFSET dpmi_dosmem
dpmi02	DD OFFSET dpmi_int
dpmi03	DD OFFSET dpmi_translate
dpmi04	DD OFFSET dpmi_ver
dpmi05	DD OFFSET dpmi_mem
dpmi06	DD OFFSET dpmi_page
dpmi07	DD OFFSET dpmi_paging
dpmi08	DD OFFSET dpmi_physical
dpmi09	DD OFFSET dpmi_virtint
dpmi0A	DD OFFSET dpmi_vendorapi
dpmi0B	DD OFFSET dpmi_debug
dpmi0C	DD OFFSET dpmi_empty
dpmi0D	DD OFFSET dpmi_empty
dpmi0E	DD OFFSET dpmi_fpu

int31:
	cmp ah,0Fh
	jae int31_fail
;
	movzx ebx,ah
	mov ebx,dword ptr cs:[ebx*4].dpmi_tab
	cmp al,cs:[ebx]
	jz int31_ok
	jc int31_ok

int31_fail:
	mov ebx,OFFSET dpmi_error
	jmp int31_do

int31_ok:
	movzx eax,al
	mov ebx,cs:[eax*4+ebx+4]
int31_do:
	push ebx
	mov eax,[bp].vm_eax
	mov ebx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	retn

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_DPMI32
;
;		DESCRIPTION:	Init 32-bit DPMI
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_dpmi32

init_dpmi32	PROC far
	push ds
	push es
	pushad
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov al,31h
	mov edi,OFFSET int31
	HookProt32Int
;
	popad
	pop es
	pop ds
	ret
init_dpmi32	ENDP

code	ENDS

	END
