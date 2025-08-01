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
; uacpi.ASM
; uACPI support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
include acpi.def
include acpi.inc
INCLUDE pci.inc
INCLUDE ..\os\core.inc
INCLUDE acpitab.inc

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF


data    SEGMENT byte public 'DATA'

acpi_init_hooks         DW ?
acpi_init_hook_arr      DD 32 DUP(?,?)

data    ENDS

code    SEGMENT byte public use32 'CODE'

    assume cs:code

    extern init_server:near
    extern HasApic:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HookInitAcpi
;
;           DESCRIPTION:    Hook init ACPI
;
;           PARAMETERS:     ES:EDI       CALLBACK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_init_acpi_name      DB 'Hook Init ACPI',0

hook_init_acpi   Proc far
    push ds
    push eax
    push ebx
;    
    mov eax,SEG data
    mov ds,eax
    mov ax,ds:acpi_init_hooks
    mov bx,ax
    shl bx,3
    add bx,OFFSET acpi_init_hook_arr
    mov [bx],edi
    mov [bx+4],es
    inc ax
    mov ds:acpi_init_hooks,ax
;
    pop ebx
    pop eax
    pop ds
    ret
hook_init_acpi   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CheckRsdp
;
;           DESCRIPTION:    Check for an RSDP
;
;       PARAMETERS:     DS:SI       Base address to check
;
;       RETURNS:        NC      OK
;                       EBX:EAX Physical address
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
    push ecx
    push esi
;    
    xor al,al    
    mov ecx,20

check_rsdp_loop:
    add al,[si]
    inc si
    loop check_rsdp_loop
;
    pop esi
    pop ecx    
;
    or al,al
    jnz check_rsdp_fail
;
    mov al,[si+15]
    cmp al,2
    jb check_get32
;
    mov ax,[si+20]
    cmp ax,32
    jb check_get32
;
    mov eax,[si+24]
    mov ebx,[si+28]       
    clc
    jmp check_rsdp_done

check_get32:    
    mov eax,[si+16]
    xor ebx,ebx
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
;           NAME:           GetRsdp
;
;           DESCRIPTION:    Get the RSDP
;
;       RETURNS:            NC      OK
;                           EBX:EAX     Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRsdp Proc near
    push ds
    push es
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov eax,system_data_sel
    mov es,eax
;    
    mov eax,1000h
    AllocateBigLinear
    AllocateGdt
    push bx
;    
    mov ecx,1000h
    CreateDataSelector16        
    mov ds,bx    
;
    mov eax,es:efi_acpi
    or eax,es:efi_acpi+4
    jz get_rsdp_not_efi
;    
    mov eax,es:efi_acpi
    mov ebx,es:efi_acpi+4
    mov si,ax
    and si,00FFFh
    and ax,0F000h
    mov al,7h
    SetPageEntry
;        
    call CheckRsdp
    jnc get_rsdp_ok
    
get_rsdp_not_efi:
    xor ebx,ebx
    mov eax,7h
    SetPageEntry
;    
    mov esi,40Eh
    mov si,[si]
    movzx esi,si
    shl esi,4
;
    mov eax,esi
    and ax,0F000h
    or al,7
    SetPageEntry
    and si,0FFFh
;    
    mov ecx,40h

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
    SetPageEntry
;
    mov esi,edi
    and si,0FFFh
;
    mov ecx,100h

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
    SetPageEntry
    mov ecx,1000h
    FreeLinear
    popf
    pop eax
;
    mov edx,ebx
    pop bx
    pushf
    FreeGdt    
    popf
;    
    mov ebx,edx
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop es
    pop ds
    ret
GetRsdp Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetTableSign
;
;       DESCRIPTION:    Get a table signature
;
;       PARAMETERS:     EBX:EAX     Physical address
;
;       RETURNS:        NC      OK
;                       EDX     Signature
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetTableSign Proc near
    push ds
    push eax
    push ebx
    push ecx
    push esi
;   
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    movzx esi,ax
    and si,0FFFh
;
    and ax,0F000h
    or al,7    
    SetPageEntry
;    
    push edx
    add edx,esi
    AllocateGdt    
    mov ecx,1000h
    CreateDataSelector16
    mov ds,bx    
    pop edx
;
    mov esi,ds:acpi_sign
    push ebx
    xor ebx,ebx
    xor eax,eax
    mov ds,ax
    SetPageEntry
    pop ebx
;    
    mov ecx,1000h
    FreeLinear
    FreeGdt
;
    mov edx,esi
;
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
GetTableSign    Endp    
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetTable
;
;           DESCRIPTION:    Get a table
;
;       PARAMETERS:         EBX:EAX     Physical address
;
;       RETURNS:            NC      OK
;                           ES      Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetTable Proc near
    push ds
    pushad
;   
    mov ebp,eax 
    mov edi,ebx
    mov eax,1000h
    AllocateBigLinear
    mov eax,ebp
    movzx esi,ax
    and si,0FFFh
;
    and ax,0F000h
    or al,7    
    SetPageEntry
;    
    push edx
    add edx,esi
    AllocateGdt    
    mov ecx,1000h
    CreateDataSelector16
    mov ds,bx    
    pop edx
;
    push ebx
    mov ecx,ds:acpi_size
    xor ebx,ebx
    xor eax,eax
    mov ds,ax
    SetPageEntry
    pop ebx
;    
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
    push ebx
    push edx
;
    mov ebx,edi
    and ax,0F000h
    or al,7    

get_table_set_phys:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop get_table_set_phys
;
    pop edx
    pop ebx
;    
    mov edi,SIZE acpi_table
    mov esi,SIZE acpi_header
    mov ecx,ds:acpi_size
    sub ecx,SIZE acpi_header
    jz get_table_copied
;
    xor ah,ah

get_table_copy:
    lods byte ptr ds:[esi]
    add ah,al
    stos byte ptr es:[edi]
    loop get_table_copy

get_table_copied:
    mov ecx,SIZE acpi_header
    xor esi,esi

get_table_check:
    lods byte ptr ds:[esi]
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
    FreeMem
    jmp get_table_fail

get_table_free:
    pop ecx
;
    push ebx
    push ecx
    push edx
;    
    xor eax,eax
    xor ebx,ebx

get_table_free_phys:
    SetPageEntry
    add edx,1000h
    loop get_table_free_phys

    pop edx
    pop ecx
    pop ebx
;
    shl ecx,12
    movzx ecx,cx
    FreeLinear
;
    xor eax,eax
    mov ds,eax
    FreeGdt
;
    mov eax,es:act_sign
    or eax,eax
    jnz get_table_ok    
;
    FreeMem

get_table_fail:
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
;           NAME:           AddApicTable
;
;           DESCRIPTION:    Add Apic table
;
;       PARAMETERS:         EBX:EAX     Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


AddApicTable   PROC near 
    push ds
    push es
    push eax
;
    call GetTable
    jc aatDone
;
    mov eax,system_data_sel
    mov ds,eax
;
    mov ds:acpi_apic_table,es

aatDone:
    pop eax
    pop es
    pop ds
    ret
AddApicTable   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHpetTable
;
;           DESCRIPTION:    Add HPET table
;
;       PARAMETERS:         EBX:EAX     Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


AddHpetTable   PROC near 
    push ds
    push es
    push eax
;
    call GetTable
    jc ahtDone
;
    mov eax,system_data_sel
    mov ds,eax
;
    mov ds:acpi_hpet_table,es

ahtDone:
    pop eax
    pop es
    pop ds
    ret
AddHpetTable   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddTable
;
;           DESCRIPTION:    Add ACPI table
;
;           PARAMETERS:     AX     Table sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

apic_tab DB 'APIC'
hpet_tab DB 'HPET'
fadt_tab DB 'FACP'

AddTable   PROC near 
    push ds
    push es
    push eax
    push ebx
;
    mov es,eax
    mov eax,system_data_sel
    mov ds,eax
;
    mov eax,es:act_sign
    cmp eax,dword ptr cs:fadt_tab
    jne atDone
;
    mov ax,es:act_size
    cmp ax,130
    jb atDone
;
    mov ebx,SIZE acpi_table
;
    mov eax,es:[ebx+116-36]
    cmp al,3
    jae atDone
;
    mov ds:acpi_reset_method,al
;
    shr eax,8
    cmp al,8
    jne atFadtFail
;
    shr eax,8
    or al,al
    jne atFadtFail
;
    shr eax,8
    cmp al,1
    jne atFadtFail
;
    mov eax,es:[ebx+120-36]
    mov ds:acpi_reset_addr,eax
;
    mov eax,es:[ebx+124-36]
    mov ds:acpi_reset_addr+4,eax
;
    mov al,es:[ebx+128-36]
    mov ds:acpi_reset_data,al
    jmp atDone

atFadtFail:
    mov ds:acpi_reset_method,-1

atDone:
    pop ebx
    pop eax
    pop es
    pop ds
    ret
AddTable   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ProcessTable
;
;           DESCRIPTION:    Process table
;
;       PARAMETERS:         EBX:EAX     Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProcessTable   PROC near
    call GetTableSign
    cmp edx,dword ptr cs:apic_tab
    jne ptNotApic
;
    call AddApicTable
    jmp ptDone

ptNotApic:
    cmp edx,dword ptr cs:hpet_tab
    jne ptNotHpet
;
    call AddHpetTable
    jmp ptDone

ptNotHpet:
    push es
    call GetTable
    mov ax,es
    pop es
    jnc ptSave
;    
    xor ax,ax

ptSave:
    call AddTable

ptDone:
    ret
ProcessTable  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitAcpiTable
;
;           DESCRIPTION:    Init ACPI tables
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitAcpiTable   PROC near
    push ds
    push es
    pushad
;    
    mov eax,system_data_sel
    mov ds,eax
    mov ds:acpi_reset_method,-1
    mov ds:acpi_apic_table,0
    mov ds:acpi_hpet_table,0
;
    call GetRsdp
    jc iatDone
;    
    call GetTable
    jc iatDone
;
    mov ax,es
    mov ds,ax
    mov eax,es:act_sign
    cmp eax,'TDSX'
    je iatGet64
;
    cmp eax,'TDSR'
    jne iatDone

iatGet32:    
    movzx ecx,ds:act_size
    shr ecx,2
    mov esi,SIZE acpi_table

iatLoop32:
    mov eax,[esi]
    xor ebx,ebx
    add si,4
    call ProcessTable
    loop iatLoop32
;
    jmp iatDone

iatGet64:
    movzx ecx,ds:act_size
    shr ecx,3
    mov esi,SIZE acpi_table

iatLoop64:
    mov eax,[esi]
    mov ebx,[esi+4]
    add esi,8
    call ProcessTable
    loop iatLoop64

iatDone:
    popad
    pop es
    pop ds
    ret
InitAcpiTable   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiGetAcpi
;
;       DESCRIPTION:    Get ACPI
;
;       RETURNS:        EDX:EAX       RDSP physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_get_acpi_name DB 'uACPI Get Acpi', 0

uacpi_get_acpi   PROC far
    push ds
    push es
    push ebx
    push ecx
    push esi
    push edi
    push ebp
;
    mov eax,system_data_sel
    mov es,eax
;    
    mov eax,1000h
    AllocateBigLinear
    AllocateGdt
    push ebx
;    
    mov ecx,1000h
    CreateDataSelector16
    mov ds,bx    
;
    mov eax,es:efi_acpi
    or eax,es:efi_acpi+4
    jz ugaNotEfi
;    
    mov eax,es:efi_acpi
    mov ebx,es:efi_acpi+4
    mov si,ax
    and si,00FFFh
    and ax,0F000h
    mov al,7h
    SetPageEntry
;        
    call CheckRsdp
    jnc ugaOk

ugaNotEfi:    
    xor ebx,ebx
    mov eax,7h
    SetPageEntry
;    
    mov esi,40Eh
    mov si,[si]
    movzx esi,si
    shl esi,4
;
    mov eax,esi
    and ax,0F000h
    or al,7
    SetPageEntry
    and si,0FFFh
;    
    mov ecx,40h

ugaBda:
    call CheckRsdp
    jnc ugaOk
;
    add si,10h
    loop ugaBda
;     
    mov edi,0E0000h
    mov bp,20h

ugaBios:
    mov eax,edi
    and ax,0F000h
    or al,7
    SetPageEntry
;
    mov esi,edi
    and si,0FFFh
;
    mov ecx,100h

ugaBiosPage:
    call CheckRsdp
    jnc ugaOk
;    
    add si,10h
    loop ugaBiosPage
;
    add edi,1000h
    sub bp,1
    jnz ugaBios
;
    xor eax,eax
    xor edx,edx
    jmp ugaDone

ugaOk:
    GetPageEntry
    and ax,0F000h
    or ax,si

ugaDone:  
    push eax
    push ebx
;
    xor eax,eax
    xor ebx,ebx
    mov ds,ax
    SetPageEntry
    mov ecx,1000h
    FreeLinear
;
    pop edx
    pop eax
;
    pop ebx
    FreeGdt    
;    
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
uacpi_get_acpi   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiMap
;
;       DESCRIPTION:    Map physical address
;
;       PARAMETERS:     EDX:EAX          Physical address
;                       ECX              Size
;
;       RETURNS:        EAX              Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_map_name DB 'uACPI Map', 0

uacpi_map   PROC far
    push ebx
    push ecx
    push esi
;
    mov ebx,edx
    mov si,ax
    and si,0FFFh
;
    add ecx,eax
    and ax,0F000h
    sub ecx,eax
;
    push eax
    mov eax,ecx
    AllocateLocalLinear
    pop eax
;
    or ax,867h

    dec ecx
    and cx,0F000h
    add ecx,1000h
    shr ecx,12
    push edx

umapLoop:
    SetPageEntry
    add edx,1000h
    add eax,1000h
    loop umapLoop
;    
    pop eax
    or ax,si
;
    pop esi
    pop ecx
    pop ebx
    ret
uacpi_map   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiUnmap
;
;       DESCRIPTION:    Unmap address
;
;       PARAMETERS:     EDX              Linear address
;                       ECX              Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_unmap_name DB 'uACPI Unmap', 0

uacpi_unmap   PROC far
    push ecx
    push edx
;
    add ecx,edx
    and dx,0F000h
    sub ecx,edx
    dec ecx
    and cx,0F000h
    add ecx,1000h
    FreeLinear
;
    pop edx
    pop ecx
    ret
uacpi_unmap   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiEnableIo
;
;       DESCRIPTION:    Enable IO
;
;       PARAMETERS:     EDX               Port
;                       ECX               Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_enable_io_name DB 'uACPI Enable IO', 0

uacpi_enable_io   PROC far
    push ds
    push eax
    push ecx
    push edx
    push esi
;
    GetThread
    mov ds,eax
    mov esi,ds:p_tss_linear
    mov eax,flat_sel
    mov ds,eax

ueLoop:
    btr dword ptr ds:[esi].tss32_io_bitmap,edx
    inc edx
    loop ueLoop
;
    clc
;
    pop esi
    pop edx
    pop ecx
    pop eax
    pop ds    
    ret
uacpi_enable_io   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiDisableIo
;
;       DESCRIPTION:    Disable IO
;
;       PARAMETERS:     EDX               Port
;                       ECX               Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_disable_io_name DB 'uACPI Disable IO', 0

uacpi_disable_io   PROC far
    ret
uacpi_disable_io   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiStartPci
;
;       DESCRIPTION:    Start PCI hooks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_start_pci_name DB 'uACPI Start PCI', 0

    extern init_pci_thread:near

init_pci_thread_name DB 'Init PCI', 0

uacpi_start_pci   PROC far
    push ds
    push es
    pushad
;
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET init_pci_thread
    mov edi,OFFSET init_pci_thread_name
    mov ax,3
    mov cx,stack0_size
    CreateThread
;
    popad
    pop es
    pop ds
    ret
uacpi_start_pci    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiHasApic
;
;       DESCRIPTION:    Check for APIC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_has_apic_name DB 'uACPI Has APIC', 0

uacpi_has_apic   PROC far
    call HasApic
    ret
uacpi_has_apic   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiAllocateInts
;
;       DESCRIPTION:    Allocate IRQs
;
;       PARAMETERS:     ECX               Count
;                       AL                Prio
;
;       RETURNS:        AL                Base IRQ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_allocate_ints_name DB 'uACPI Allocate Ints', 0

uacpi_allocate_ints   PROC far
    call HasApic
    jc uaiFail
;
    AllocateInts
    jnc uaiDone

uaiFail:
    xor al,al

uaiDone:
    ret
uacpi_allocate_ints   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiFreeInt
;
;       DESCRIPTION:    Free IRQ
;
;       PARAMETERS:     AL                IRQ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_free_int_name DB 'uACPI Free Int', 0

uacpi_free_int   PROC far
    FreeInt
    ret
uacpi_free_int   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiGetMsiAddress
;
;       DESCRIPTION:    Get MSI address
;
;       PARAMETERS:     AX                Core
;
;       RETURNS:        EAX               Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_get_msi_address_name DB 'uACPI Get MSI Address', 0

uacpi_get_msi_address   PROC far
    push fs
;
    GetCoreNumber
    mov eax,fs:cs_apic
    shl eax,12
    or eax,0FEE00000h
;
    pop fs
    ret
uacpi_get_msi_address   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiGetMsiData
;
;       DESCRIPTION:    Get MSI data
;
;       PARAMETERS:     AL                IRQ
;
;       RETURNS:        EAX               Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_get_msi_data_name DB 'uACPI Get MSI Data', 0

uacpi_get_msi_data   PROC far
    movzx eax,al
    ret
uacpi_get_msi_data   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AcpiServer
;
;       DESCRIPTION:    ACPI server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lpname DB 'uacpi', 0
lpcmd  DB 0

AcpiServer:
    call init_server
;    
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET uacpi_get_acpi
    mov edi,OFFSET uacpi_get_acpi_name
    xor cl,cl
    mov ax,uacpi_get_acpi_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET uacpi_map
    mov edi,OFFSET uacpi_map_name
    xor cl,cl
    mov ax,uacpi_map_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET uacpi_unmap
    mov edi,OFFSET uacpi_unmap_name
    xor cl,cl
    mov ax,uacpi_unmap_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET uacpi_enable_io
    mov edi,OFFSET uacpi_enable_io_name
    xor cl,cl
    mov ax,uacpi_enable_io_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET uacpi_disable_io
    mov edi,OFFSET uacpi_disable_io_name
    xor cl,cl
    mov ax,uacpi_disable_io_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET uacpi_start_pci
    mov edi,OFFSET uacpi_start_pci_name
    xor cl,cl
    mov ax,uacpi_start_pci_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET uacpi_has_apic
    mov edi,OFFSET uacpi_has_apic_name
    xor cl,cl
    mov ax,uacpi_has_apic_nr
    RegisterPrivateServGate    
;
    mov esi,OFFSET uacpi_allocate_ints
    mov edi,OFFSET uacpi_allocate_ints_name
    xor cl,cl
    mov ax,uacpi_allocate_ints_nr
    RegisterPrivateServGate    
;
    mov esi,OFFSET uacpi_free_int
    mov edi,OFFSET uacpi_free_int_name
    xor cl,cl
    mov ax,uacpi_free_int_nr
    RegisterPrivateServGate    
;
    mov esi,OFFSET uacpi_get_msi_address
    mov edi,OFFSET uacpi_get_msi_address_name
    xor cl,cl
    mov ax,uacpi_get_msi_address_nr
    RegisterPrivateServGate    
;
    mov esi,OFFSET uacpi_get_msi_data
    mov edi,OFFSET uacpi_get_msi_data_name
    xor cl,cl
    mov ax,uacpi_get_msi_data_nr
    RegisterPrivateServGate    
;
    mov esi,OFFSET lpcmd
    mov edi,OFFSET lpname
    mov ax,4
    xor bx,bx
    LoadServer

aLoop:
    mov ax,250
    WaitMilliSec
    jmp aLoop
;
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LoadAcpiServer
;
;       DESCRIPTION:    Load ACPI server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadAcpiServer  Proc near
    push ds
    push es
    pushad
;
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET AcpiServer
    mov edi,OFFSET lpname
    mov al,2
    CreateServerProcess
;
    popad
    pop es
    pop ds
    ret
LoadAcpiServer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_pci
;
;           DESCRIPTION:    Create hook thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_pci    Proc far
    push ds
    push es
    pushad
;    
    mov eax,SEG data
    mov ds,eax
    movzx ecx,ds:acpi_init_hooks
    or ecx,ecx
    je ipLoad
;
    mov ebx,OFFSET acpi_init_hook_arr

ipLoop:
    push ds
    push ebx
    push ecx
    call fword ptr [ebx]
    pop ecx
    pop ebx
    pop ds
    add ebx,8
    loop ipLoop

ipLoad:
    call LoadAcpiServer
;
    popad
    pop es
    pop ds
    ret
init_pci    Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_uacpi
;
;           DESCRIPTION:    Init uacpi
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_uacpi

init_uacpi    Proc near
    mov ebx,SEG data
    mov ds,ebx
    mov ds:acpi_init_hooks,0
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov edi,OFFSET init_pci
    HookInitTasking
;
    mov esi,OFFSET hook_init_acpi
    mov edi,OFFSET hook_init_acpi_name
    mov ax,hook_init_acpi_nr
    RegisterOsGate
;
    call InitAcpiTable
    clc
    ret
init_uacpi    Endp

code    ENDS

    END
