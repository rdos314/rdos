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
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def
INCLUDE ..\..\kernel\os\proc.inc
INCLUDE acpi.inc

    .386p

acpi_data_seg STRUC    

acpi_table_count    DW ?
acpi_table_arr      DD ?

acpi_data_seg ENDS

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CheckRsdp
;
;           DESCRIPTION:    Check for an RSDP
;
;       PARAMETERS:     DS:SI       Base address to check
;
;       RETURNS:    NC      OK
;               EAX     Physical address
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
;       NAME:           AcpiOsGetRootPointer
;
;       DESCRIPTION:    Get the RSDP
;
;       RETURNS:        EAX     Physical address or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AcpiOsGetRootPointer_
    
AcpiOsGetRootPointer_ Proc near
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
    SetPhysicalPage
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
    GetPhysicalPage
    and ax,0F000h
    or ax,si

os_get_rsdp_done:  
    push eax
    xor eax,eax
    mov ds,ax
    SetPhysicalPage
    mov ecx,1000h
    FreeLinear
    FreeGdt    
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
AcpiOsGetRootPointer_ Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetRsdp
;
;           DESCRIPTION:    Get the RSDP
;
;       RETURNS:    NC      OK
;               EAX     Physical address
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
;           NAME:           GetTable
;
;           DESCRIPTION:    Get a table
;
;       PARAMETERS:     EAX     Physical address
;
;       RETURNS:    NC      OK
;               ES      Table
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
    lods byte ptr ds:[si]
    add ah,al
    stos byte ptr es:[di]
    loop get_table_copy
;
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
    movzx eax,fs:ps_acpi
    call ImplEnterC3
;
    pop eax    
    pop fs
    ret
enter_c3    Endp

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
    lock or fs:ps_flags,PS_FLAG_P_STATE
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
    lock or fs:ps_flags,PS_FLAG_SHUTDOWN
;
    pop fs                
    ret
ReqShutdown_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetTimerCore
;
;           DESCRIPTION:    Set core that should receive timeout events
;
;           PARAMETERS:     EAX     Core #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetTimerCore_

SetTimerCore_    Proc near
    push fs
;    
    push eax
    mov ax,setup_timer_core_nr
    IsValidOsGate
    pop eax
    jc stcDone
;
    GetCoreNumber
    SetupTimerCore

stcDone:
    pop fs                
    ret
SetTimerCore_    Endp

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
    stos word ptr es:[di]
    loop acpi_load_loop
;    
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
    mov bx,OFFSET get_cpu_version16
    mov si,OFFSET get_cpu_version32
    mov edi,OFFSET get_cpu_version_name
    mov dx,virt_es_in
    mov ax,get_cpu_version_nr
    RegisterUserGate

acpi_fail:
    popad
    pop es
    pop ds
    ret
InitAcpiTables_    Endp

_TEXT    ENDS

    END
