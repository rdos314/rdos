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
; ACPIBASE.ASM
; Basic ACPI support functions not available from RDOS device-driver interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
include ..\..\kernel\serv.def
include ..\..\kernel\serv.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def
INCLUDE ..\..\kernel\os\core.inc
INCLUDE acpi.inc

    .686p

acpi_data_seg STRUC    

acpi_table_count    DW ?
acpi_table_arr      DD ?

acpi_data_seg ENDS

acpi_int_seg	STRUC

acpi_proc       DD ?,?
acpi_context	DD ?,?

acpi_int_seg	ENDS

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetValue
;
;       Purpose:        Get value from environment
;
;       Parameters:     ES:EDI      Name
;
;       Returns:        NC          Found
;                       AX          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
GetValue    Proc near
    push ds
    push ebx
    push ecx
    push esi
;
    LockSysEnv
    mov ds,bx
    xor esi,esi
    
find_val:
    push edi

find_val_loop:
    cmpsb
    jnz find_val_next
;       
    mov al,es:[edi]
    or al,al
    jnz find_val_loop
    mov al,[esi]
    cmp al,'='
    je find_val_found

find_val_next:
    pop edi

find_val_next_bp:
    lodsb
    or al,al
    jnz find_val_next_bp
;
    mov al,[esi]
    or al,al
    jne find_val
;
    xor ax,ax
    stc
    jmp find_val_done

find_val_found:
    pop edi
    inc esi  
    xor ax,ax

find_val_digit:
    mov bl,[esi]
    inc esi
    sub bl,'0'
    jc find_val_save
;
    cmp bl,10
    jnc find_val_save
;       
    mov cx,10
    mul cx
    add al,bl
    adc ah,0
    jmp find_val_digit

find_val_save:
    clc

find_val_done:
    pushf
    UnlockSysEnv
    popf
;
    pop esi
    pop ecx
    pop ebx
    pop ds
    ret
GetValue    Endp
      
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
;       NAME:           AcpiOsGetRootPointer
;
;       DESCRIPTION:    Get the RSDP
;
;       RETURNS:        EDX:EAX     Physical address or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AcpiOsGetRootPointer_
    
AcpiOsGetRootPointer_ Proc near
    push ds
    push es
    push ebx
    push ecx
    push esi
    push edi
    push bp
;
    mov ax,system_data_sel
    mov es,ax
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
    jz os_get_not_efi
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
    jnc os_get_rsdp_ok

os_get_not_efi:    
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
    mov cx,40h

os_get_rsdp_bda:
    call CheckRsdp
    jnc os_get_rsdp_ok
;
    add si,10h
    loop os_get_rsdp_bda
;     
    mov edi,0E0000h
    mov bp,20h

os_get_rsdp_bios:
    mov eax,edi
    and ax,0F000h
    or al,7
    SetPageEntry
;
    mov esi,edi
    and si,0FFFh
;
    mov cx,100h

os_get_rsdp_bios_page:
    call CheckRsdp
    jnc os_get_rsdp_ok
;    
    add si,10h
    loop os_get_rsdp_bios_page
;
    add edi,1000h
    sub bp,1
    jnz os_get_rsdp_bios
;
    xor eax,eax
    jmp os_get_rsdp_done

os_get_rsdp_ok:
    GetPageEntry
    and ax,0F000h
    or ax,si

os_get_rsdp_done:  
    push eax
    xor eax,eax
    mov ds,ax
    SetPageEntry
    mov ecx,1000h
    FreeLinear
    pop eax
    mov edx,ebx
;
    pop bx    
    FreeGdt    
;    
    pop bp
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
AcpiOsGetRootPointer_ Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AcpiOsIsEfi
;
;       DESCRIPTION:    Check for EFI boot
;
;       RETURNS:        EAX          1 = EFI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AcpiOsIsEfi_
    
AcpiOsIsEfi_ Proc near
    push ds
;
    mov ax,system_data_sel
    mov ds,ax
;
    mov eax,es:efi_acpi
    or eax,es:efi_acpi+4
    jz os_is_efi_done
;
    mov eax,1

os_is_efi_done:
    pop ds
    ret
AcpiOsIsEfi_  Endp    
      
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
    push bp
;
    mov ax,system_data_sel
    mov es,ax
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
    SetPageEntry
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
    pop bp
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
    mov di,SIZE acpi_table
    mov si,SIZE acpi_header
    mov ecx,ds:acpi_size
    sub ecx,SIZE acpi_header
    jz get_table_copied
;
    xor ah,ah

get_table_copy:
    lods byte ptr ds:[si]
    add ah,al
    stos byte ptr es:[di]
    loop get_table_copy

get_table_copied:
    mov cx,SIZE acpi_header
    xor si,si

get_table_check:
    lods byte ptr ds:[si]
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
    xor ax,ax
    mov ds,ax
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
;           NAME:           GetAcpiTable
;
;           DESCRIPTION:    Get ACPI table
;
;       PARAMETERS:     EAX     Table ID
;
;       RETURNS:    NC      Ok
;               ES  Table selector
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
;       NAME:           GetAcpiDeviceIrq
;
;       DESCRIPTION:    Get ACPI device IRQ
;
;       PARAMETERS:     EAX     Device #
;                       EDX     Index
;
;       RETURNS:        NC   OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_acpi_device_irq_name    DB 'Get ACPI Device Irq',0

    extrn GetAcpiDeviceIrqBase:near

get_acpi_device_irq  Proc far
    push es
    push ecx
    push edi
    sub esp,4
    mov ecx,ss
    mov es,ecx
    mov edi,esp
    call GetAcpiDeviceIrqBase
    or eax,eax
    jz gadiFail

gadiOk:
    pop eax
    mov edx,eax
    shr edx,16
    clc
    jmp gadiDone

gadiFail:
    stc
    pop eax

gadiDone:
    pop edi
    pop ecx
    pop es
    ret
get_acpi_device_irq Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetAcpiDeviceIo
;
;       DESCRIPTION:    Get ACPI device IO
;
;       PARAMETERS:     EAX     Device #
;                       EDX     Index
;
;       RETURNS:        NC   OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_acpi_device_io_name    DB 'Get ACPI Device Io',0

    extrn GetAcpiDeviceIoBase:near

get_acpi_device_io  Proc far
    push es
    sub esp,4
    mov ecx,ss
    mov es,ecx
    mov edi,esp
    call GetAcpiDeviceIoBase
    or eax,eax
    jz gadioFail

gadioOk:
    pop esi
    mov edi,esi
    shr edi,16
    mov ecx,eax
    clc
    jmp gadioDone

gadioFail:
    add esp,4
    stc

gadioDone:
    pop es
    ret
get_acpi_device_io Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetAcpiDeviceMem
;
;       DESCRIPTION:    Get ACPI device memory
;
;       PARAMETERS:     EAX     Device #
;                       EDX     Index
;
;       RETURNS:        NC   OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_acpi_device_mem_name    DB 'Get ACPI Device Mem',0

    extrn GetAcpiDeviceMemBase:near

get_acpi_device_mem  Proc far
    push es
    sub esp,8
    mov ecx,ss
    mov es,ecx
    mov edi,esp
    call GetAcpiDeviceMemBase
    or eax,eax
    jz gadmemFail

gadmemOk:
    pop esi
    pop edi
    mov ecx,eax
    clc
    jmp gadmemDone

gadmemFail:
    add esp,8
    stc

gadmemDone:
    pop es
    ret
get_acpi_device_mem Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetPciDeviceInfo
;
;       DESCRIPTION:    Get PCI device info
;
;       PARAMETERS:     EAX     PCI Device #
;
;       RETURNS:        NC   OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_device_info_name    DB 'Get PCI Device Info',0

    extrn GetPciDeviceBase:near

get_pci_device_info  Proc far
    push es
    push eax
    push edi
    sub esp,4
    mov ebx,ss
    mov es,ebx
    mov edi,esp
    call GetPciDeviceBase
    or eax,eax
    jz gpdiFail

gpdiOk:
    pop edi
    mov bx,di
    xchg bl,bh
    shr edi,16
    mov cx,di
    xchg cl,ch
    clc
    jmp gpdiDone

gpdiFail:
    add esp,4
    stc

gpdiDone:
    pop edi
    pop eax
    pop es
    ret
get_pci_device_info Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetCpuVersion
;
;       DESCRIPTION:    Get CPU version
;
;       PARAMETERS:     ES:(E)DI    Vendor string
;
;       RETURNS:        AL      Version
;                       EBX     Frequency
;                       EDX     Feature flags
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cpu_version_name    DB 'Get CPU Version',0

    extrn GetCpuId:near
    extrn GetCpuVendorFeature:near
    extrn GetCpuFreq:near

get_cpu_version16  Proc far
    push edi
    movzx edi,di
    call GetCpuVendorFeature
    call GetCpuFreq
    call GetCpuId
    pop edi
    ret
get_cpu_version16 Endp

get_cpu_version32  Proc far
    call GetCpuVendorFeature
    call GetCpuFreq
    call GetCpuId
    ret
get_cpu_version32 Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           EnterC3
;
;       DESCRIPTION:    Enter C3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enter_c3_name    DB 'Enter C3',0

    extrn ImplEnterC3:near

enter_c3    Proc far
    push fs
    push eax
;    
    GetCore
    movzx eax,fs:cs_acpi
    call ImplEnterC3
;
    pop eax    
    pop fs
    ret
enter_c3    Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetIntelTemperature
;
;       DESCRIPTION:    Get Intel CPU temperature
;
;       RETURNS:        EAX     Temperature in 1/10th of degrees celsius
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetIntelTermOffset_
    
GetIntelTermOffset_    Proc near
    push ecx
    push edx
;
    mov ecx,19Ch    
    rdmsr
;
    shr eax,16
    and eax,7Fh
    cmp ax,7Fh - 0Ah
    jbe gitoDone
;
    or eax,0FFFFFF00h

gitoDone:    
    pop edx
    pop ecx
    ret
GetIntelTermOffset_ Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetAndTemp
;
;       DESCRIPTION:    Get AMD CPU temperature
;
;       RETURNS:        EAX     Temperature in 1/10th of degrees celsius
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetAmdTemp_
    
GetAmdTemp_    Proc near
    push ebx
    push ecx
    push edx
;    
    xor bh,bh
    mov bl,24
    mov ch,3
    mov cl,0A4h
    ReadPciDword
    shr eax,21    
    mov edx,10
    mul edx
    shr eax,3
    clc
;
    pop edx
    pop ecx
    pop ebx
    ret
GetAmdTemp_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCpuInfo
;
;           DESCRIPTION:    Get CPU info (CPUID 1)
;
;           RETURNS:        EAX     ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetCpuInfo_

GetCpuInfo_    Proc near
    push ecx
    push edx
    mov eax,1
    cpuid
    pop edx
    pop ecx
    ret
GetCpuInfo_     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPicMode
;
;           DESCRIPTION:    Get PIC mode
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetPicMode_

GetPicMode_    Proc near
    mov eax,apic_code_sel
    verr ax
    jz gpmApic
;
    xor eax,eax
    jmp gpmDone

gpmApic:
    mov eax,1

gpmDone:        
    ret
GetPicMode_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReqPStateUpdate
;
;           DESCRIPTION:    Req p-state update for all cores
;
;           PARAMETERS:     ECX      Number of cores
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReqPStateUpdate_

ReqPStateUpdate_    Proc near
    push fs
    push eax
;    
    xor eax,eax

req_update_loop:    
    GetCoreNumber
    lock or fs:cs_flags,CS_FLAG_P_STATE
;
    inc eax
    cmp eax,ecx
    jne req_update_loop
;
    pop eax
    pop fs                
    ret
ReqPStateUpdate_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReqShutdown
;
;           DESCRIPTION:    Req a shutdown for a core
;
;           PARAMETERS:     EAX     Core #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReqShutdown_

ReqShutdown_    Proc near
    push fs
;    
    GetCoreNumber
    lock or fs:cs_flags,CS_FLAG_SHUTDOWN
;
    pop fs                
    ret
ReqShutdown_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetExtFeatureFlags
;
;           DESCRIPTION:    Req extended feature flags
;
;           RETURNS:        EAX     Extended feature flags
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetExtFeatureFlags_

GetExtFeatureFlags_    Proc near
    push ds
;    
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:cpu_ext_flags
;
    pop ds    
    ret
GetExtFeatureFlags_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitAcpiTables
;
;           DESCRIPTION:    Initialize ACPI tables
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitAcpiTables_

InitAcpiTables_    Proc near
    push ds
    push es
    pushad
;    
    call GetRsdp
    jc acpi_fail
;    
    call GetTable
    jc acpi_fail
;
    mov ax,es
    mov ds,ax
    mov eax,es:act_sign
    cmp eax,'TDSX'
    je acpi_get64
;
    cmp eax,'TDSR'
    jne acpi_fail

acpi_get32:    
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

acpi_load_loop32:
    mov eax,[si]
    xor ebx,ebx
    add si,4
    push es
    call GetTable
    mov ax,es
    pop es
    jnc acpi_load_save32
;    
    xor ax,ax

acpi_load_save32:
    stos word ptr es:[di]
    loop acpi_load_loop32
;
    jmp acpi_setup_gates

acpi_get64:
    mov cx,ds:act_size
    shr cx,2
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

acpi_load_loop64:
    mov eax,[si]
    mov ebx,[si+4]
    add si,8
    push es
    call GetTable
    mov ax,es
    pop es
    jnc acpi_load_save64
;    
    xor ax,ax

acpi_load_save64:
    stos word ptr es:[di]
    loop acpi_load_loop64
    
acpi_setup_gates:    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_acpi_table
    mov edi,OFFSET get_acpi_table_name
    xor cl,cl
    mov ax,get_acpi_table_nr
    RegisterOsGate
;
    mov esi,OFFSET get_pci_device_info
    mov edi,OFFSET get_pci_device_info_name
    xor dx,dx
    mov ax,get_acpi_pci_device_info_nr
    RegisterOsGate
;
    mov esi,OFFSET enter_c3
    mov edi,OFFSET enter_c3_name
    xor cl,cl
    mov ax,enter_c3_nr
    RegisterOsGate
;
    mov esi,OFFSET get_acpi_device_irq
    mov edi,OFFSET get_acpi_device_irq_name
    xor dx,dx
    mov ax,get_acpi_device_irq_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_acpi_device_io
    mov edi,OFFSET get_acpi_device_io_name
    xor dx,dx
    mov ax,get_acpi_device_io_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_acpi_device_mem
    mov edi,OFFSET get_acpi_device_mem_name
    xor dx,dx
    mov ax,get_acpi_device_mem_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_cpu_version16
    mov esi,OFFSET get_cpu_version32
    mov edi,OFFSET get_cpu_version_name
    mov dx,virt_es_in
    mov ax,get_cpu_version_nr
    RegisterUserGate
;
    call SetupServerGates

acpi_fail:
    popad
    pop es
    pop ds
    ret
InitAcpiTables_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UseAcpiReset
;
;           DESCRIPTION:    Use ACPI Reset
;
;           RETURNS:        EAX     1 if use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_name             DB 'ACPI.RESET',0

    public UseAcpiReset_

UseAcpiReset_    Proc near
    push es
    push edi
;
    mov eax,cs
    mov es,eax
    mov edi,OFFSET reset_name
    call GetValue
    jnc uarOk
;
    mov ax,1

uarOk:
    movzx eax,ax
;
    pop edi
    pop es    
    ret
UseAcpiReset_     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IrqEntry
;
;           DESCRIPTION:    IRQ entrypoint
;
;           PARAMETERS:     DS		ACPI int seg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn IrqStart:near

IrqEntry	Proc far
    mov esi,ds:acpi_proc
    mov fs,ds:acpi_proc+4
    mov edi,ds:acpi_context
    mov es,ds:acpi_context+4
    call IrqStart    
    ret
IrqEntry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LinkIrq
;
;           DESCRIPTION:    Link IRQ
;
;           PARAMETERS:     AL		Irq
;                           FS:ESI      Handler
;                           ES:EDI      Context
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LinkIrq_

LinkIrq_    Proc near
    push ds
    push es
    push edi
;    
    push es
    push eax
    mov eax,SIZE acpi_int_seg
    AllocateSmallGlobalMem
    mov eax,es
    mov ds,eax
    pop eax
    pop es
;
    mov ds:acpi_proc,esi
    mov ds:acpi_proc+4,fs
    mov ds:acpi_context,edi
    mov ds:acpi_context+4,es
;
    cmp al,2
    je liNmi
;
    mov ah,10h
    mov edi,cs
    mov es,edi
    mov edi,OFFSET IrqEntry
    RequestIrqHandler
    jmp liDone

liNmi:
    mov eax,cs
    mov es,eax
    mov edi,OFFSET IrqEntry
    SetupNmiHandler

liDone:
    pop edi
    pop es
    pop ds    
    ret
LinkIrq_    Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetTermalLimit
;
;       DESCRIPTION:    Get termal limit
;
;       RETURNS:        EAX     Termal limit in degrees
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetTermalLimit_

TermalLimit DB 'TERMAL.LIMIT', 0
    
GetTermalLimit_ Proc near
    push es
    push edi
;
    mov eax,cs
    mov es,eax
    mov edi,OFFSET TermalLimit
    call GetValue
    jnc gtlOk
;
    mov ax,115

gtlOk:
    movzx eax,ax
;
    pop edi
    pop es
    ret
GetTermalLimit_ Endp       


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
    mov ax,system_data_sel
    mov es,ax
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
    mov cx,40h

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
    mov cx,100h

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
    or ax,865h

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
;       PARAMETERS:     DX               Port
;                       CX               Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_enable_io_name DB 'uACPI Enable IO', 0

uacpi_enable_io   PROC far
    ret
uacpi_enable_io   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiDisableIo
;
;       DESCRIPTION:    Disable IO
;
;       PARAMETERS:     DX               Port
;                       CX               Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_disable_io_name DB 'uACPI Disable IO', 0

uacpi_disable_io   PROC far
    ret
uacpi_disable_io   Endp

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

    public LoadAcpiServer_

LoadAcpiServer_  Proc near
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
LoadAcpiServer_  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupServerGates
;
;       DESCRIPTION:    Setup server gates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupServerGates  Proc near
;
    mov esi,OFFSET uacpi_get_acpi
    mov edi,OFFSET uacpi_get_acpi_name
    xor cl,cl
    mov ax,uacpi_get_acpi_nr
    RegisterServGate
;
    mov esi,OFFSET uacpi_map
    mov edi,OFFSET uacpi_map_name
    xor cl,cl
    mov ax,uacpi_map_nr
    RegisterServGate
;
    mov esi,OFFSET uacpi_unmap
    mov edi,OFFSET uacpi_unmap_name
    xor cl,cl
    mov ax,uacpi_unmap_nr
    RegisterServGate
;
    mov esi,OFFSET uacpi_enable_io
    mov edi,OFFSET uacpi_enable_io_name
    xor cl,cl
    mov ax,uacpi_enable_io_nr
    RegisterServGate
;
    mov esi,OFFSET uacpi_disable_io
    mov edi,OFFSET uacpi_disable_io_name
    xor cl,cl
    mov ax,uacpi_disable_io_nr
    RegisterServGate
;
    ret
SetupServerGates  Endp

_TEXT    ENDS

    END
