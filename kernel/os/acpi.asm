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
; ACPI.ASM
; ACPI support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
        NAME acpi
              
GateSize = 16

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def

acpi_data_seg STRUC

acpi_rsdp  DD ?

acpi_data_seg ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CheckRsdp
;
;		DESCRIPTION:    Check for an RSDP
;
;       PARAMETERS:     DS:SI       Base address to check
;
;       RETURNS:        NC          OK
;                       EAX         Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rsd1 DB 'RSD '
rsd2 DB 'PTR '

CheckRsdp   Proc near
    mov eax,dword ptr cs:rsd1
    cmp eax,[si]
    jne check_rsdp_fail
;
    mov eax,dword ptr cs:rsd2
    cmp eax,[si+4]
    jne check_rsdp_fail
;
    push cx
    push si
;    
    xor al,al        
    mov cx,20

check_rsdp_loop:
    add al,[si]
    inc si
    loop check_rsdp_loop
;
    pop si
    pop cx    
;
    or al,al
    jnz check_rsdp_fail
;
    mov eax,[si+16]
    clc
    jmp check_rsdp_done

check_rsdp_fail:
    stc

check_rsdp_done:    
    ret
CheckRsdp   Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetRsdp
;
;		DESCRIPTION:    Get the RSDP
;
;       RETURNS:        NC          OK
;                       EAX         Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRsdp Proc near
    push ds
    push es
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push bp
;
    mov eax,1000h
    AllocateBigLinear
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov eax,7h
    SetPhysicalPage
    mov ds,bx    
;    
    mov esi,40Eh
    mov si,[si]
    movzx esi,si
    shl esi,4
;
    mov eax,esi
    and ax,0F000h
    or al,7
    SetPhysicalPage
    and si,0FFFh
    mov eax,cr3
    mov cr3,eax
;        
    mov cx,40h

get_rsdp_bda:
    call CheckRsdp
    jnc get_rsdp_ok
;
    add si,10h
    loop get_rsdp_bda
;     
    mov edi,0E0000h
    mov bp,20h

get_rsdp_bios:
    mov eax,edi
    and ax,0F000h
    or al,7
    SetPhysicalPage
    mov eax,cr3
    mov cr3,eax
;
    mov esi,edi
    and si,0FFFh
;
    mov cx,100h

get_rsdp_bios_page:
    call CheckRsdp
    jnc get_rsdp_ok
;    
    add si,10h
    loop get_rsdp_bios_page
;
    add edi,1000h
    sub bp,1
    jnz get_rsdp_bios
;
    stc
    jmp get_rsdp_done

get_rsdp_ok:
    clc

get_rsdp_done:	
    push eax
    pushf
    xor eax,eax
    mov ds,ax
    SetPhysicalPage
    FreeLinear
    FreeGdt    
    popf
    pop eax
;    
    pop bp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
GetRsdp Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			acpi_pr
;
;		DESCRIPTION:	ACPI thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

acpi_name	DB 'Acpi',0


acpi_pr:
    int 3
    call GetRsdp
    jc acpi_fail
;
    push eax
    mov eax,2000h
    AllocateBigLinear
    pop eax
    movzx ebx,ax
    and bx,0FFFh
    and ax,0F000h
    or al,7    
    SetPhysicalPage
    add eax,1000h
    add edx,1000h
    SetPhysicalPage
    sub edx,1000h
;    
    push edx
    add edx,ebx
    AllocateGdt        
    mov ecx,1000h
    CreateDataSelector16
    mov ds,bx    
    pop edx
;    

acpi_fail:
    
PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_acpi_thread
;
;		DESCRIPTION:	Init acpi thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_acpi_thread	PROC far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;	
	mov si,OFFSET acpi_pr
	mov di,OFFSET acpi_name
	mov cx,500
	mov ax,4
	CreateThread
;
	popa
	pop es
	pop ds
	ret
init_acpi_thread	ENDP

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
	push ds
	push es
	pusha
;
	mov bx,acpi_code_sel
	InitDevice
;
	mov eax,SIZE acpi_data_seg
	mov bx,acpi_data_sel
	AllocateFixedSystemMem
	mov es,bx
;
    mov ax,cs
	mov es,ax
	mov di,OFFSET init_acpi_thread
	HookInitTasking
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
