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

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def
INCLUDE acpi.def

acpi_data_seg STRUC        

acpi_table_count        DW ?
acpi_table_arr          DD ?

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
    mov ecx,1000h
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
;		NAME:			GetTable
;
;		DESCRIPTION:    Get a table
;
;       PARAMETERS:     EAX     Physical address
;
;       RETURNS:        NC      OK
;                       ES      Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetTable Proc near
    push ds
    pushad
;   
    mov ebp,eax 
    mov eax,1000h
    AllocateBigLinear
    mov eax,ebp
    movzx ebx,ax
    and bx,0FFFh
    and ax,0F000h
    or al,7    
    SetPhysicalPage
;    
    push edx
    add edx,ebx
    AllocateGdt        
    mov ecx,1000h
    CreateDataSelector16
    mov ds,bx    
    pop edx
;
    mov ecx,ds:acpi_size
    xor eax,eax
    mov ds,ax
    SetPhysicalPage
    push ecx
    mov ecx,1000h
    FreeLinear
    pop ecx
    FreeGdt
;    
    cmp ecx,10000h - SIZE acpi_table
    jae get_table_fail
;   
    mov eax,ecx     
    sub eax,SIZE acpi_header
    add eax,SIZE acpi_table
    AllocateSmallGlobalMem
    mov eax,ecx
    sub eax,SIZE acpi_header
    mov es:act_size,ax
    mov di,SIZE acpi_table
;    
    movzx eax,bp
    and ax,0FFFh
    add eax,ecx
    add eax,1000h
    dec eax
    and ax,0F000h
    add eax,1000h
    AllocateBigLinear
;
    mov ecx,eax
    shr ecx,12
    push ecx
;        
    mov eax,ebp
    movzx ebx,ax
    and bx,0FFFh
;
    push ecx
    push edx
    add edx,ebx
    AllocateGdt        
    shl ecx,12
    CreateDataSelector16
    mov ds,bx    
    pop edx
    pop ecx
;
    push edx
    and ax,0F000h
    or al,7    

get_table_set_phys:
    SetPhysicalPage
    add eax,1000h
    add edx,1000h
    loop get_table_set_phys
    pop edx
;    
    mov si,SIZE acpi_header
    mov ecx,ds:acpi_size
    sub ecx,SIZE acpi_header
;
    xor ah,ah

get_table_copy:
    lodsb
    add ah,al
    stosb
    loop get_table_copy
;
    mov cx,SIZE acpi_header
    xor si,si

get_table_check:
    lodsb
    add ah,al
    loop get_table_check
;
    or ah,ah
    jnz get_table_pop_fail
;
    mov eax,ds:acpi_sign
    mov es:act_sign,eax
    mov eax,ds:acpi_oem_id
    mov es:act_oem_id,eax
    mov eax,ds:acpi_oem_id+4
    mov es:act_oem_id+4,eax
    jmp get_table_free

get_table_pop_fail:
    pop ecx
    jmp get_table_fail

get_table_free:
    pop ecx
;
    xor eax,eax
    push ecx
    push edx

get_table_free_phys:
    SetPhysicalPage
    add edx,1000h
    loop get_table_free_phys
    pop edx
    pop ecx
;
    shl ecx,12
    movzx ecx,cx
    FreeLinear
;
    xor ax,ax
    mov ds,ax
    FreeGdt
;
    mov eax,es:act_sign
    or eax,eax
    jnz get_table_ok    

get_table_fail:
    FreeMem
    stc
    jmp get_table_done

get_table_ok:
    clc

get_table_done:
    popad
    pop ds
    ret
GetTable    Endp    
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetAcpiTable
;
;		DESCRIPTION:	Get ACPI table
;
;       PARAMETERS:     EAX     Table ID
;
;       RETURNS:        NC      Ok
;                           ES  Table selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_acpi_table_name    DB 'Get ACPI Table',0

get_acpi_table  Proc far
    push ds
    push cx
    push si
;
    mov cx,acpi_data_sel
    mov ds,cx
    mov cx,ds:acpi_table_count
    mov si,OFFSET acpi_table_arr

get_acpi_table_loop:
    mov es,[si]
    cmp eax,es:act_sign
    je get_acpi_table_ok
;    
    add si,2
    loop get_acpi_table_loop
;
    xor cx,cx
    mov es,cx
    stc
    jmp get_acpi_table_done

get_acpi_table_ok:
    clc

get_acpi_table_done:
    pop si
    pop cx
    pop ds
    ret
get_acpi_table  Endp

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
    call GetRsdp
    jc acpi_fail
;    
    call GetTable
    jc acpi_fail
;
    mov ax,es
    mov ds,ax
    mov cx,ds:act_size
    shr cx,1
;    
	mov ax,OFFSET acpi_table_arr
	add ax,cx
	movzx eax,ax
	mov bx,acpi_data_sel
	AllocateFixedSystemMem
	mov es,bx
;
    shr cx,1
    mov es:acpi_table_count,cx
;
    mov si,SIZE acpi_table
    mov di,OFFSET acpi_table_arr

acpi_load_loop:
    lods dword ptr [si]
    push es
    call GetTable
    mov ax,es
    pop es
    jnc acpi_load_save
;        
    xor ax,ax

acpi_load_save:
    stosw
    loop acpi_load_loop
;    
    mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET get_acpi_table
	mov di,OFFSET get_acpi_table_name
	xor cl,cl
	mov ax,get_acpi_table_nr
	RegisterOsGate

acpi_fail:
	ret
init	Endp

code	ENDS

	END init
