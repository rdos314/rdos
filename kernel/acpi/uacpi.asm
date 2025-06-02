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

acpitab STRUC

acpi_table_count        DD ?
acpi_table_arr          DD ?

acpitab  ENDS


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
    shr ecx,1
;    
    mov eax,OFFSET acpi_table_arr
    add eax,ecx
    mov bx,pci_acpi_sel
    AllocateFixedSystemMem
    mov es,bx
;
    shr ecx,1
    mov es:acpi_table_count,ecx
;
    mov esi,SIZE acpi_table
    mov edi,OFFSET acpi_table_arr

iatLoop32:
    mov eax,[esi]
    xor ebx,ebx
    add si,4
    push es
    call GetTable
    mov ax,es
    pop es
    jnc iatSave32
;    
    xor ax,ax

iatSave32:
    stos word ptr es:[edi]
    loop iatLoop32
;
    jmp iatDone

iatGet64:
    movzx ecx,ds:act_size
    shr ecx,2
;    
    mov eax,OFFSET acpi_table_arr
    add eax,ecx
    mov bx,pci_acpi_sel
    AllocateFixedSystemMem
    mov es,bx
;
    shr ecx,1
    mov es:acpi_table_count,ecx
;
    mov esi,SIZE acpi_table
    mov edi,OFFSET acpi_table_arr

iatLoop64:
    mov eax,[esi]
    mov ebx,[esi+4]
    add esi,8
    push es
    call GetTable
    mov ax,es
    pop es
    jnc iatSave64
;    
    xor ax,ax

iatSave64:
    stos word ptr es:[edi]
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
;           NAME:           GetAcpiTable
;
;           DESCRIPTION:    Get ACPI table
;
;       PARAMETERS:         EAX     Table ID
;
;       RETURNS:            NC      Ok
;                           ES  Table selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetAcpiTable

GetAcpiTable  Proc near
    push ds
    push ecx
    push esi
;
    mov ecx,pci_acpi_sel
    mov ds,ecx
    mov ecx,ds:acpi_table_count
    mov esi,OFFSET acpi_table_arr

gtLoop:
    mov es,[esi]
    cmp eax,es:act_sign
    je gtOk
;    
    add esi,2
    loop gtLoop
;
    xor ecx,ecx
    mov es,ecx
    stc
    jmp gtDone

gtOk:
    clc

gtDone:
    pop esi
    pop ecx
    pop ds
    ret
GetAcpiTable  Endp

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
;       NAME:           AcpiServer
;
;       DESCRIPTION:    ACPI server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lpname DB 'uacpi', 0
lpcmd  DB 0

AcpiServer:
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
    mov esi,OFFSET uacpi_start_pci
    mov edi,OFFSET uacpi_start_pci_name
    xor cl,cl
    mov ax,uacpi_start_pci_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET lpcmd
    mov edi,OFFSET lpname
    mov ax,4
    xor bx,bx
    LoadServer
;
    mov ax,1000
    WaitMilliSec
;
    mov ax,3Eh+5
    SetFocus

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
