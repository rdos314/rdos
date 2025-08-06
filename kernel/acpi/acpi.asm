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
; acpi.ASM
; ACPI support
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
INCLUDE msg.inc

tib_data        STRUC

pvFirstExcept           DD ?
pvStackUserTop          DD ?
pvStackUserBottom       DD ?
pvLastError                     DD ?
pvStackUserSize         DD ?
pvArbitrary                     DD ?
pvTEB                           DD ?
pvProcessHandle         DD ?
pvThreadHandle          DD ?
pvModuleHandle          DD ?
pvTLSBitmap                     DD ?
pvTLSArray                      DD ?
pvBase                          DD ?

tib_data        ENDS

; this structure should be 128 bytes!

pci_func_struc   STRUC

pcif_vendor_dev     DD ?
pcif_bridge         DW ?
pcif_class          DW ?
pcif_interface      DB ?
pcif_pin            DB ?
pcif_irq            DB ?
pcif_msi            DB ?
pcif_msi_core       DW ?
pcif_msi_count      DB ?
pcif_msix           DB ?
pcif_msix_count     DW ?
pcif_msix_irq_sel   DW ?
pcif_msix_data_sel  DW ?
pcif_used           DW ?
pcif_acpi_index     DD ?
pcif_acpi_name      DB 100 DUP(?)

pci_func_struc   ENDS

pci_device_struc   STRUC

pcid_func_arr       DB 8*128 DUP(?)

pcid_dev_id         DB ?
pcid_bus_id         DB ?

pci_device_struc   ENDS

pci_bus_struc  STRUC

pcib_device_arr    DW 32 DUP(?)

pcib_bus_id        DB ?
pcib_owner_bus     DB ?
pcib_owner_dev     DB ?
pcib_owner_func    DB ?

pci_bus_struc  ENDS


; should be moved from ACPI!

acpi_header STRUC

acpi_sign       DD ?
acpi_size       DD ?

acpi_rev        DB ?
acpi_sum        DB ?

acpi_oem        DB 6 DUP(?)
acpi_oem_id     DD ?, ?
acpi_oem_rev    DD ?
acpi_cr_id      DD ?
acpi_cr_rev     DD ?

acpi_header ENDS

acpi_table  STRUC

act_next        DW ?
act_size        DW ?
act_sign        DD ?
act_oem_id      DD ?, ?

acpi_table  ENDS

data    SEGMENT byte public 'DATA'

pci_spinlock            spinlock_typ <>

pci_init_hooks          DW ?
pci_init_hook_arr       DD 64 DUP(?,?)

pci_bus_arr             DW 256 DUP(?)

data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use32 'CODE'

    assume cs:code
    
    extern AllocateMsg:near
    extern AddMsgBuffer:near
    extern RunMsg:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HookInitPci
;
;           DESCRIPTION:    Hook init PCI
;
;           PARAMETERS:     ES:EDI       CALLBACK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_init_pci_name      DB 'Hook Init PCI',0

hook_init_pci   Proc far
    push ds
    push eax
    push ebx
;    
    mov eax,SEG data
    mov ds,eax
    mov ax,ds:pci_init_hooks
    mov bx,ax
    shl bx,3
    add bx,OFFSET pci_init_hook_arr
    mov [bx],edi
    mov [bx+4],es
    inc ax
    mov ds:pci_init_hooks,ax
;
    pop ebx
    pop eax
    pop ds
    ret
hook_init_pci   Endp
                
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SoftReset
;
;           DESCRIPTION:    Soft reset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

soft_reset_name      DB 'Soft Reset',0

MemReset   Proc near
    CrashGate
    ret
MemReset   Endp

IoReset   Proc near
    mov edx,ds:acpi_reset_addr
    mov al,ds:acpi_reset_data
    out dx,al
    ret
IoReset   Endp

PciReset   Proc near
    CrashGate
    ret
PciReset   Endp

reset_tab:
rt00 DD OFFSET MemReset
rt01 DD OFFSET IoReset
rt02 DD OFFSET PciReset

soft_reset:
    mov eax,system_data_sel
    mov ds,eax
    mov al,ds:acpi_reset_method
    cmp al,3
    jae legacy_reset
;
    movzx ebx,al
    call dword ptr cs:[4*ebx].reset_tab
    jmp tripple_fault

legacy_reset:
    mov ecx,500    

wait_gate1:
    in al,64h
    and al,2
    jz wait_gate_done1
;
    loop wait_gate1    

wait_gate_done1:
    mov al,0D1h
    out 64h,al
;    
    mov ecx,500    

wait_gate2:
    in al,64h
    and al,2
    jz wait_gate_done2
;
    loop wait_gate2    
    
wait_gate_done2:    
    mov al,0FEh
    out 60h,al

tripple_fault:
    mov ax,idt_sel
    mov ds,ax
;    
    mov bx,13 * 8
    xor eax,eax
    mov [bx],eax
    mov [bx+4],eax
;
    mov bx,8 * 8
    mov [bx],eax
    mov [bx+4],eax
;
    mov ax,-1
    mov ds,ax

reset_wait:
    jmp reset_wait
     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindPciDevice
;
;           DESCRIPTION:    Find PCI device
;
;           PARAMETERS:     CX      Device
;                           DX      Vendor
;                           BX      Start handle
;
;           RETURNS:        BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_pci_device_name      DB 'Find PCI Device',0

find_pci_device   Proc far
    push ds
    push es
    push edi
    push ebp
;
    call AllocateMsg
;    
    mov eax,FIND_PCI_DEVICE_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop es
    pop ds
    ret
find_pci_device   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindPciClass
;
;           DESCRIPTION:    Find PCI class
;
;           PARAMETERS:     AH      Class
;                           AL      Subclass
;                           BX      Start handle
;
;           RETURNS:        BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_pci_class_name      DB 'Find PCI Class',0

find_pci_class   Proc far
    push ds
    push es
    push edi
    push ebp
;
    call AllocateMsg
;    
    mov eax,FIND_PCI_CLASS_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop es
    pop ds
    ret
find_pci_class   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindPciProtocol
;
;           DESCRIPTION:    Find PCI protocol
;
;           PARAMETERS:     AH      Class
;                           AL      Subclass
;                           DL      Protocol
;                           BX      Start handle
;
;           RETURNS:        BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_pci_prot_name      DB 'Find PCI Protocol',0

find_pci_prot   Proc far
    push ds
    push es
    push edi
    push ebp
;
    call AllocateMsg
;    
    mov eax,FIND_PCI_PROTOCOL_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop es
    pop ds
    ret
find_pci_prot   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciHandle
;
;           DESCRIPTION:    Get PCI handle
;
;           PARAMETERS:     DH      Segment
;                           DL      Bus
;                           AH      Device
;                           AL      Function
;
;           RETURNS:        BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_handle_name      DB 'Get PCI Handle',0

get_pci_handle   Proc far
    push ds
    push es
    push edi
    push ebp
;
    call AllocateMsg
;    
    mov eax,GET_PCI_HANDLE_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop es
    pop ds
    ret
get_pci_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciBus
;
;           DESCRIPTION:    Get PCI bus
;
;           PARAMETERS:     DH          Segment
;                           DL          Bus
;
;           RETURNS:        DL          Bus
;                           AH          Device
;                           AL          Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_bus_name DB 'Get Pci Bus',0

get_pci_bus     Proc far    
    push ds
    push es
    push edi
    push ebp
;
    call AllocateMsg
;    
    mov eax,GET_PCI_BUS_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop es
    pop ds
    ret
get_pci_bus     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciHandleParam
;
;           DESCRIPTION:    Find PCI handle param
;
;           PARAMETERS:     BX      Handle
;
;           RETURNS:        DH      Segment
;                           DL      Bus
;                           AH      Device
;                           AL      Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_handle_param_name      DB 'Get PCI Handle Param',0

get_pci_handle_param   Proc far
    push ds
    push es
    push edi
    push ebp
;
    call AllocateMsg
;    
    mov eax,GET_PCI_PARAM_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop es
    pop ds
    ret
get_pci_handle_param   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciHandleIrq
;
;           DESCRIPTION:    Find PCI handle IRQ
;
;           PARAMETERS:     BX      Handle
;                           AX      Index
;
;           RETURNS:        AL      Irq
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_handle_irq_name      DB 'Get PCI Handle IRQ',0

get_pci_handle_irq   Proc far
    push ds
    push es
    push edi
    push ebp
;
    call AllocateMsg
;    
    mov eax,GET_PCI_IRQ_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop es
    pop ds
    ret
get_pci_handle_irq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciHandleMsi
;
;           DESCRIPTION:    Get PCI MSI vectors
;
;           PARAMETERS:     BX      Handle
;
;           RETURNS:        AL      Vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_handle_msi_name      DB 'Get PCI Handle MSI',0

get_pci_handle_msi   Proc far
    push ds
    push es
    push edi
    push ebp
;
    call AllocateMsg
;    
    mov eax,GET_PCI_MSI_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop es
    pop ds
    ret
get_pci_handle_msi   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciHandleMsiX
;
;           DESCRIPTION:    Get PCI MSI-X vectors
;
;           PARAMETERS:     BX      Handle
;
;           RETURNS:        AL      Vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_handle_msix_name      DB 'Get PCI Handle MSI-X',0

get_pci_handle_msix   Proc far
    push ds
    push es
    push edi
    push ebp
;
    call AllocateMsg
;    
    mov eax,GET_PCI_MSIX_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop es
    pop ds
    ret
get_pci_handle_msix   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupPciHandleIrq
;
;           DESCRIPTION:    Setup for single IRQ
;
;           PARAMETERS:     AH      Priority
;                           BX      Handle
;                           DS      Data passed to handler
;                           ES:EDI  Handler address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_pci_handle_irq_name      DB 'Setup PCI Handle IRQ',0

setup_pci_handle_irq   Proc far
    push ecx
;
    push ds
    push es
    push edx
    push esi
    push edi
    push ebp
;
    mov edx,[esp+32]
;
    push eax
    GetCoreId
    movzx esi,ax
    pop eax
;
    call AllocateMsg
;    
    mov eax,SETUP_PCI_IRQ_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop esi
    pop edx
    pop es
    pop ds
;
    or cl,cl
    jz sphiFail
;
    cmp cl,1
    je sphiIrq

sphiMsi:
    pop ecx
    RequestMsiHandler
;
    push ds
    push es
    push ecx
    push edx
    push edi
    push ebp
;
    mov edx,[esp+28]
;
    call AllocateMsg
;    
    mov eax,ENABLE_PCI_MSI_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop edx
    pop ecx
    pop es
    pop ds
;
    clc
    jmp sphiDone

sphiFail:
    pop ecx
    stc
    jmp sphiDone

sphiIrq:
    pop ecx
    RequestIrqHandler
    clc

sphiDone:
    ret
setup_pci_handle_irq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReqPciHandleMsi
;
;           DESCRIPTION:    Req MSI vectors
;
;           PARAMETERS:     AH      Priority
;                           BX      Handle
;                           CX      Requested vectors
;
;           RETURNS:        CX      Setup vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_pci_handle_msi_name      DB 'Req PCI Handle MSI',0

req_pci_handle_msi   Proc far
    push ds
    push es
    push fs
    push edx
    push esi
    push edi
    push ebp
;
    GetCore
    mov si,fs:cs_id
;
    mov edx,[esp+32]
;
    call AllocateMsg
;    
    mov eax,SETUP_PCI_MSI_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop esi
    pop edx
    pop fs
    pop es
    pop ds
    ret
req_pci_handle_msi   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupPciHandleMsi
;
;           DESCRIPTION:    Setup MSI IRQ
;
;           PARAMETERS:     BX      Handle
;                           DX      Entry
;                           DS      Data passed to handler
;                           ES:EDI  Handler address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_pci_handle_msi_name      DB 'Setup PCI Handle MSI',0

setup_pci_handle_msi   Proc far
    push eax
;
    push ds
    push es
    push edi
    push ebp
;
    mov ax,dx
    call AllocateMsg
;    
    mov eax,GET_PCI_IRQ_CMD
    call RunMsg
;
    pop ebp
    pop edi
    pop es
    pop ds
    jc sphmDone
;
    or al,al
    stc
    jz sphmDone
;
    RequestMsiHandler
    clc

sphmDone:    
    pop eax
    ret
setup_pci_handle_msi   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EnablePciHandleMsi
;
;           DESCRIPTION:    Enable PCI MSI handlers
;
;           PARAMETERS:     BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_pci_handle_msi_name      DB 'Enable PCI Handle MSI',0

enable_pci_handle_msi   Proc far
    push ds
    push es
    push edx
    push edi
    push ebp
;
    mov edx,[esp+24]
;
    call AllocateMsg
;    
    mov eax,ENABLE_PCI_MSI_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop edx
    pop es
    pop ds
    ret
enable_pci_handle_msi   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciBarPhys
;
;           DESCRIPTION:    Get physical address for PCI BAR
;
;           PARAMETERS:     AL      Bar #
;                           BX      Handle
;
;           RETURNS:        EDX:EAX Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_bar_phys_name      DB 'Get PCI Bar Phys',0

get_pci_bar_phys   Proc far
    push ds
    push es
    push edi
    push ebp
;
    call AllocateMsg
;    
    mov eax,GET_PCI_BAR_PHYS_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop es
    pop ds
    ret
get_pci_bar_phys   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciBarIo
;
;           DESCRIPTION:    Get IO port for PCI BAR
;
;           PARAMETERS:     AL      Bar #
;                           BX      Handle
;
;           RETURNS:        DX      IO port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_bar_io_name      DB 'Get PCI Bar IO',0

get_pci_bar_io   Proc far
    push ds
    push es
    push edi
    push ebp
;
    call AllocateMsg
;    
    mov eax,GET_PCI_BAR_IO_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop es
    pop ds
    ret
get_pci_bar_io   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciCapability
;
;           DESCRIPTION:    Find PCI capability
;
;           PARAMETERS:     BX      Handle
;                           AL      Capability
;
;           RETURNS:        AX      Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_cap_name      DB 'Get PCI Capability',0

get_pci_cap   Proc far
    push ds
    push es
    push edi
    push ebp
;
    call AllocateMsg
;    
    mov eax,GET_PCI_CAP_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop es
    pop ds
    ret
get_pci_cap   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           EvalPciIntArr16/32
;
;    DESCRIPTION:    Evaluate int array
;
;    PARAMETERS:     BX          PCI Handle
;                    DS:(E)SI    ACPI name + config name
;                    ES:(E)DI    Int array
;                    (E)CX       Size of buffer
;
;    RETURNS:        EAX         Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eval_pci_int_arr_name DB 'Eval PCI Int Arr', 0

EvalPciIntArr  Proc near
    push ds
    push es
    push fs
    push gs
    push esi
    push edi
    push ebp
;
    mov eax,es
    mov gs,eax
    mov ebp,edi
    mov eax,ds
    mov fs,eax
    call AllocateMsg

eiaInCopy:
    lods byte ptr fs:[esi]
    stosb
    or al,al
    jnz eiaInCopy
;
    push ecx
    shl ecx,2
    mov edi,ebp
    call AddMsgBuffer
    pop ecx
;    
    mov eax,EVAL_INT_ARR_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop esi
    pop gs
    pop fs
    pop es
    pop ds
    ret
EvalPciIntArr   Endp

eval_pci_int_arr16  Proc far
    push ecx
    push esi
    push edi
;
    movzx ecx,cx
    movzx esi,si
    movzx edi,di
    call EvalPciIntArr
;    
    pop edi
    pop esi
    pop ecx
    ret
eval_pci_int_arr16  Endp

eval_pci_int_arr32  Proc far
    call EvalPciIntArr
    ret
eval_pci_int_arr32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           GetPciDeviceName16/32
;
;    DESCRIPTION:    Get PCI device name
;
;    PARAMETERS:     BX          Handle
;                    ES:(E)DI    Name buffer
;                    (E)CX       Size of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_device_name DB 'Get PCI Device Name', 0

GetDevName  Proc near
    push ds
    push es
    push gs
    push edi
    push ebp
;
    mov eax,es
    mov gs,eax
;
    push edi
    call AllocateMsg
    pop edi
    jc gdnDone
;
    call AddMsgBuffer
;    
    mov eax,GET_PCI_NAME_CMD
    call RunMsg

gdnDone:    
    pop ebp
    pop edi
    pop gs
    pop es
    pop ds
    ret
GetDevName   Endp

get_pci_device_name16  Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call GetDevName
;    
    pop edi
    pop ecx
    ret
get_pci_device_name16  Endp

get_pci_device_name32  Proc far
    call GetDevName
    ret
get_pci_device_name32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPciConfigByte
;
;           DESCRIPTION:    Read PCI config byte
;
;           PARAMETERS:     BX      Handle
;                           CX      Register
;
;           RETURNS:        AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_pci_config_byte_name      DB 'Read PCI Config Byte',0

read_pci_config_byte   Proc far
    push ds
    push es
    push edx
    push edi
    push ebp
;
    mov edx,[esp+24]
;
    call AllocateMsg
;    
    mov eax,READ_PCI_CONFIG_BYTE_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop edx
    pop es
    pop ds
    ret
read_pci_config_byte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPciConfigWord
;
;           DESCRIPTION:    Read PCI config word
;
;           PARAMETERS:     BX      Handle
;                           CX      Register
;
;           RETURNS:        AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_pci_config_word_name      DB 'Read PCI Config Word',0

read_pci_config_word   Proc far
    push ds
    push es
    push edx
    push edi
    push ebp
;
    mov edx,[esp+24]
;
    call AllocateMsg
;    
    mov eax,READ_PCI_CONFIG_WORD_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop edx
    pop es
    pop ds
    ret
read_pci_config_word   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPciConfigDword
;
;           DESCRIPTION:    Read PCI config dword
;
;           PARAMETERS:     BX      Handle
;                           CX      Register
;
;           RETURNS:        EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_pci_config_dword_name      DB 'Read PCI Config Dword',0

read_pci_config_dword   Proc far
    push ds
    push es
    push edx
    push edi
    push ebp
;
    mov edx,[esp+24]
;
    call AllocateMsg
;    
    mov eax,READ_PCI_CONFIG_DWORD_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop edx
    pop es
    pop ds
    ret
read_pci_config_dword   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePciConfigByte
;
;           DESCRIPTION:    Write PCI config byte
;
;           PARAMETERS:     BX      Handle
;                           CX      Register
;                           AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_pci_config_byte_name      DB 'Write PCI Config Byte',0

write_pci_config_byte   Proc far
    push ds
    push es
    push edx
    push edi
    push ebp
;
    mov edx,[esp+24]
;
    call AllocateMsg
;    
    mov eax,WRITE_PCI_CONFIG_BYTE_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop edx
    pop es
    pop ds
    ret
write_pci_config_byte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePciConfigWord
;
;           DESCRIPTION:    Write PCI config word
;
;           PARAMETERS:     BX      Handle
;                           CX      Register
;                           AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_pci_config_word_name      DB 'Write PCI Config Word',0

write_pci_config_word   Proc far
    push ds
    push es
    push edx
    push edi
    push ebp
;
    mov edx,[esp+24]
;
    call AllocateMsg
;    
    mov eax,WRITE_PCI_CONFIG_WORD_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop edx
    pop es
    pop ds
    ret
write_pci_config_word   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePciConfigDword
;
;           DESCRIPTION:    Write PCI config dword
;
;           PARAMETERS:     BX      Handle
;                           CX      Register
;                           EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_pci_config_dword_name      DB 'Write PCI Config Dword',0

write_pci_config_dword   Proc far
    push ds
    push es
    push edx
    push edi
    push ebp
;
    mov edx,[esp+24]
;
    call AllocateMsg
;    
    mov eax,WRITE_PCI_CONFIG_DWORD_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop edx
    pop es
    pop ds
    ret
write_pci_config_dword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           LockPciHandle16/32
;
;    DESCRIPTION:    Lock PCI handle
;
;    PARAMETERS:     BX          Handle
;                    ES:(E)DI    Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_pci_handle_name DB 'Lock PCI Handle', 0

LockHandle  Proc near
    push ds
    push es
    push fs
    push esi
    push edi
    push ebp
;
    mov esi,es
    mov fs,esi
    mov esi,edi
    call AllocateMsg

lhCopy:
    lods byte ptr fs:[esi]
    stosb
    or al,al
    jnz lhCopy
;    
    mov eax,LOCK_PCI_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop esi
    pop fs
    pop es
    pop ds
    ret
LockHandle   Endp

lock_pci_handle16  Proc far
    push edx
    mov edx,[esp+8]
;    
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call LockHandle
;    
    pop edi
    pop ecx
    pop edx
    ret
lock_pci_handle16  Endp

lock_pci_handle32  Proc far
    push edx
    mov edx,[esp+8]
;
    call LockHandle
;
    pop edx    
    ret
lock_pci_handle32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockPciHandle
;
;           DESCRIPTION:    Unlock PCI handle
;
;           PARAMETERS:     BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_pci_handle_name      DB 'Unlock PCI Handle',0

unlock_pci_handle   Proc far
    push ds
    push es
    push edx
    push edi
    push ebp
;
    mov edx,[esp+24]
;
    call AllocateMsg
;    
    mov eax,UNLOCK_PCI_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop edx
    pop es
    pop ds
    ret
unlock_pci_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsPciHandleLocked
;
;           DESCRIPTION:    Check if PCI handle is locked
;
;           PARAMETERS:     BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_pci_handle_locked_name      DB 'Is PCI Handle Locked',0

is_pci_handle_locked   Proc far
    push ds
    push es
    push edi
    push ebp
;
    call AllocateMsg
;    
    mov eax,IS_PCI_LOCKED_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop es
    pop ds
    ret
is_pci_handle_locked   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Name:           GetValue
;
;   Purpose:        Get value from environment
;
;   Parameters:     ES:EDI   Name
;
;   Returns:        NC      Found
;                   AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
        public GetValue
        
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
;           NAME:           GetPciBusCount
;
;           DESCRIPTION:    Determine number of PCI buses
;
;           RETURNS:        AL          Number of buses
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetPciBusCount
    
GetPciBusCount  Proc near
    push ds
    push ebx
    push ecx
    push edx
;
    mov eax,SEG data
    mov ds,eax
;    
    mov ebx,80000000h
    mov ecx,80000000h

get_pci_bus_count_loop:
    mov eax,ecx
    mov dx,0CF8h
    and al,0FCh
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    in eax,dx
    ReleaseSpinlock ds:pci_spinlock
    cmp ax,-1
    je get_pci_bus_count_next
    shr eax,16
    cmp ax,-1
    je get_pci_bus_count_next
;
    mov ebx,ecx
get_pci_bus_count_next:
    add ecx,800h
    cmp ecx,81000000h
    jne get_pci_bus_count_loop
;
    shr ebx,16
    mov al,bl
;
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
GetPciBusCount  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPciByte
;
;           DESCRIPTION:    Read a 8-bit register
;
;           PARAMETERS:         BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          Register
;
;           RETURNS:        AL          Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_pci_byte_name      DB 'Read PCI byte',0

read_pci_byte   Proc far
    push ds
    push ebx
    push ecx
    push edx
;
    mov eax,SEG data
    mov ds,eax
;    
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    mov al,cl
;
    and al,0FCh
    mov dx,0CF8h
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    and cl,3
    or dl,cl
    in al,dx
    ReleaseSpinlock ds:pci_spinlock
;
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
read_pci_byte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           write_pci_byte
;
;           DESCRIPTION:    Write a 8-bit register
;
;           PARAMETERS:         AL          Data
;                           BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_pci_byte_name     DB 'Write PCI byte',0

write_pci_byte  Proc far
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    push ax
    mov ax,SEG data
    mov ds,ax
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    mov al,cl
;
    and al,0FCh
    mov dx,0CF8h
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    and cl,3
    or dl,cl
    pop ax
    out dx,al
    ReleaseSpinlock ds:pci_spinlock
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
write_pci_byte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPciWord
;
;           DESCRIPTION:    Read a 16-bit register
;
;           PARAMETERS:         BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          Register
;
;           RETURNS:        AX          Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_pci_word_name      DB 'Read PCI word',0

read_pci_word   Proc far
    push ds
    push ebx
    push ecx
    push edx
;
    mov eax,SEG data
    mov ds,eax
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    mov al,cl
;
    and al,0FCh
    mov dx,0CF8h
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    and cl,2
    or dl,cl
    in ax,dx
    ReleaseSpinlock ds:pci_spinlock
;
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
read_pci_word   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePciWord
;
;           DESCRIPTION:    Write a 16-bit register
;
;           PARAMETERS:         AX          Data
;                           BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_pci_word_name     DB 'Write PCI word',0

write_pci_word  Proc far
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    push ax
    mov ax,SEG data
    mov ds,ax
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    mov al,cl
;
    mov dx,0CF8h
    and al,0FCh
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    and cl,2
    or dl,cl
    pop ax
    out dx,ax
    ReleaseSpinlock ds:pci_spinlock
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
write_pci_word  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPciDword
;
;           DESCRIPTION:    Read a 32-bit register
;
;           PARAMETERS:         BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          Register
;
;           RETURNS:        EAX         Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_pci_dword_name     DB 'Read PCI dword',0

read_pci_dword  Proc far
    push ds
    push ebx
    push ecx
    push edx
;
    mov eax,SEG data
    mov ds,eax
;
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    mov al,cl
;
    mov dx,0CF8h
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    in eax,dx
    ReleaseSpinlock ds:pci_spinlock
;
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
read_pci_dword  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePciDword
;
;           DESCRIPTION:    Write a 32-bit register
;
;           PARAMETERS:         EAX         Data
;                           BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_pci_dword_name    DB 'Write PCI dword',0

write_pci_dword Proc far
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    push eax
    mov eax,SEG data
    mov ds,eax
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    mov al,cl
;
    mov dx,0CF8h
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    pop eax
    out dx,eax
    ReleaseSpinlock ds:pci_spinlock
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
write_pci_dword Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           IsPciFunctionUsed
;
;   DESCRIPTION:    Check if function is used
;
;   PARAMETERS:     BH          Bus
;                   BL          Device
;                   CH          Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_pci_function_used_name    DB 'Is Pci Function Used',0

is_pci_function_used  Proc far
    push ds
    push esi
;
    mov eax,SEG data    
    mov ds,eax
;
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz ipfuFail
;
    mov ds,ax
    movzx esi,bl
    mov ax,ds:[2*esi].pcib_device_arr
    or ax,ax
    jz ipfuFail
;
    mov ds,ax
    movzx esi,ch
    shl esi,7
    mov ax,ds:[esi].pcif_used
    or al,al
    clc
    jnz ipfuDone

ipfuFail:
    stc

ipfuDone:
    pop esi
    pop ds
    ret
is_pci_function_used  Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:       GetPciIrq
;
;   DESCRIPTION:    Convert PCI int pin to int line
;
;   PARAMETERS:     BH          Bus
;                   BL          Device
;                   CH          Function
;
;   RETURNS:        AL      Line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_irq_name    DB 'Get Pci IRQ',0

get_pci_irq  Proc far
    push ds
    push esi
;
    mov eax,SEG data    
    mov ds,eax
;
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz gpiFail
;
    mov ds,ax
    movzx esi,bl
    mov ax,ds:[2*esi].pcib_device_arr
    or ax,ax
    jz gpiFail
;
    mov ds,ax
    movzx esi,ch
    shl esi,7
    movzx ax,ds:[esi].pcif_irq
    or al,al
    jz gpiFail
;
    cmp al,-1
    jz gpiFail
;
    clc
    jmp gpiDone

gpiFail:
    xor ax,ax
    stc

gpiDone:
    pop esi
    pop ds
    ret
get_pci_irq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetPciIrqPin
;
;   DESCRIPTION:    Get PCI IRQ pin
;
;   PARAMETERS:     BH          Bus
;                   BL          Device
;                   CH          Function
;
;   RETURNS:        AL          Pin #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_irq_pin_name    DB 'Get Pci IRQ Pin',0

get_pci_irq_pin  Proc far
    push ecx
    mov cl,PCI_interrupt_pin
    ReadPciByte
    pop ecx
    ret
get_pci_irq_pin  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           GetPciClass
;
;    DESCRIPTION:    Get PCI class
;
;    PARAMETERS:     BH          Bus
;                    BL          Device
;                    CH          Function
;
;    RETURNS:        AH          Class
;                    AL          Sub-class
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_class_name DB 'Get PCI Class', 0

get_pci_class   Proc far
    push ds
    push esi
;
    mov eax,SEG data    
    mov ds,eax
;
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz gpcFail
;
    mov ds,ax
    movzx esi,bl
    mov ax,ds:[2*esi].pcib_device_arr
    or ax,ax
    jz gpcFail
;
    mov ds,ax
    movzx esi,ch
    shl esi,7
    mov ax,ds:[esi].pcif_class
    clc
    jmp gpcDone

gpcFail:
    xor ax,ax
    stc

gpcDone:
    pop esi
    pop ds
    ret
get_pci_class   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           GetPciInterface
;
;    DESCRIPTION:    Get PCI interface
;
;    PARAMETERS:     BH          Bus
;                    BL          Device
;                    CH          Function
;
;    RETURNS:        AL          Interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_interface_name DB 'Get PCI Interface', 0

get_pci_interface   Proc far
    push ds
    push esi
;
    mov eax,SEG data    
    mov ds,eax
;
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz gpinFail
;
    mov ds,ax
    movzx esi,bl
    mov ax,ds:[2*esi].pcib_device_arr
    or ax,ax
    jz gpinFail
;
    mov ds,ax
    movzx esi,ch
    shl esi,7
    mov al,ds:[esi].pcif_interface
    clc
    jmp gpinDone

gpinFail:
    xor ax,ax
    stc

gpinDone:
    pop esi
    pop ds
    ret
get_pci_interface   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciDeviceVendor
;
;           DESCRIPTION:    Get PCI device vendor & device
;
;           PARAMETERS:     AX          Index
;
;           RETURNS:        AX          Vendor ID
;                           DX          Device ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_device_vendor_name DB 'Get PCI Device Vendor', 0

get_pci_device_vendor  Proc far
    push ds
    push esi
;
    mov eax,SEG data    
    mov ds,eax
;
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz gpdvFail
;
    mov ds,ax
    movzx esi,bl
    mov ax,ds:[2*esi].pcib_device_arr
    or ax,ax
    jz gpdvFail
;
    mov ds,ax
    movzx esi,ch
    shl esi,7
    mov ax,word ptr ds:[esi].pcif_vendor_dev
    mov dx,word ptr ds:[esi].pcif_vendor_dev+2
    cmp ax,-1
    je gpdvFail
;
    clc
    jmp gpdvDone

gpdvFail:
    xor ax,ax
    xor dx,dx
    stc

gpdvDone:
    pop esi
    pop ds
    ret
get_pci_device_vendor  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciDsdConfig
;
;           DESCRIPTION:    Get PCI DSD config
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;                           ES:ESI      Config name
;                           FS:EDI      Config array
;                           EAX         Max config entries
;
;           RETURNS:        EAX         Entry count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_dsd_config_name       DB 'Get PCI Device DSD Config',0

get_pci_dsd_config    Proc far
    push ds
    push gs
    push ebp
;
    mov ebp,eax
    mov ax,SEG data    
    mov gs,ax
;
    movzx eax,bh
    mov ax,gs:[2*eax].pci_bus_arr
    or ax,ax
    jz gpdcDone
;
    mov gs,ax
    movzx eax,bl
    movzx eax,gs:[2*eax].pcib_device_arr
    or eax,eax
    jz gpdcDone
;
    mov gs,ax
    movzx eax,ch
    shl eax,7
    mov eax,gs:[eax].pcif_acpi_index
    mov ecx,ebp
    GetAcpiPciDsd

gpdcDone:
    pop ebp
    pop gs
    pop ds
    ret
get_pci_dsd_config   ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciMsi
;
;           DESCRIPTION:    Get PCI MSI interface
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;
;           RETURNS:        NC          Success
;                           CL          MSI register base
;                           DL          Requested vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_msi_name DB 'Get PCI MSI',0

get_pci_msi     Proc far    
    push ds
    push eax
    push esi
;
    mov eax,SEG data    
    mov ds,eax
;
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz gpmFail
;
    mov ds,ax
    movzx esi,bl
    mov ax,ds:[2*esi].pcib_device_arr
    or ax,ax
    jz gpmFail
;
    mov ds,ax
    movzx esi,ch
    shl esi,7
    mov cl,ds:[esi].pcif_msi
    mov dl,ds:[esi].pcif_msi_count
    or cl,cl
    jz gpmFail
;
    clc
    jmp gpmDone

gpmFail:
    stc

gpmDone:
    pop esi
    pop eax
    pop ds
    ret
get_pci_msi     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupMsiVector
;
;           DESCRIPTION:    Setup MSI vector
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          MSI register base
;                           AL          IRQ
;                           FS          Core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupMsiVector     Proc near
    push eax
    push ecx
    push edx
    push esi
;
    mov si,ax
;
    ReadPciWord
    add cl,2
;
    test ax,100h
    jnz smvVector
;
    test ax,80h
    jnz smv64

smv32:
    mov ax,si
    GetMsiVector
; 
    push ax
    mov eax,edx
    WritePciDword
    pop ax
;
    add cl,4    
    WritePciWord
    jmp smvDone

smv64:
    mov ax,si
    GetMsiVector
;
    push ax
    mov eax,edx
    WritePciDword
;
    add cl,4
    xor eax,eax
    WritePciDword
    pop ax
;    
    add cl,4    
    WritePciWord
    jmp smvDone

smvVector:
    mov ax,si
    GetMsiVector
;
    push ax
    mov eax,edx
    WritePciDword
;
    add cl,4
    xor eax,eax
    WritePciDword
    pop ax
;    
    add cl,4    
    WritePciWord

smvDone:
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
SetupMsiVector  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindIrq
;
;           DESCRIPTION:    Find IRQ
;
;           PARAMETERS:     AL          IRQ
;
;           RETURNS:        BH          Bus
;                           BL          Device
;                           CH          Function
;                           ES:EDI      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindIrq     Proc near
    push ds
    push fs
    push gs
    push edx
;
    mov edx,SEG data
    mov ds,edx
;
    xor bx,bx

fiBusLoop:
    movzx esi,bh
    mov dx,ds:[2*esi].pci_bus_arr
    or dx,dx
    jz fiBusNext
;
    mov fs,dx
    xor bl,bl

fiDevLoop:
    movzx edi,bl
    mov dx,fs:[2*edi].pcib_device_arr
    or dx,dx
    jz fiDevNext
;
    mov es,dx
    xor ch,ch

fiFuncLoop:
    movzx edi,ch
    shl edi,7
    add edi,OFFSET pcid_func_arr
;
    mov cl,byte ptr es:[edi].pcif_used
    or cl,cl
    jz fiFuncNext
;
    mov cl,es:[edi].pcif_msi
    or cl,cl
    jz fiFuncCheckMsiX
;
    mov ah,al
    sub ah,es:[edi].pcif_irq
    jb fiFuncNext
;
    cmp ah,es:[edi].pcif_msi_count
    jae fiFuncNext
;
    clc
    jmp fiDone

fiFuncCheckMsiX:
    mov cl,es:[edi].pcif_msix
    or cl,cl
    jz fiFuncNext
;
    mov cl,byte ptr es:[edi].pcif_msix_count
    mov gs,es:[edi].pcif_msix_irq_sel
;
    push bx
;
    xor bx,bx

fiCheckMsixLoop:
    cmp al,gs:[bx]
    clc
    je fiCheckMsixPop
;
    add bx,4
    sub cl,1
    jnz fiCheckMsixLoop
;
    stc

fiCheckMsixPop:
    pop bx
    jnc fiDone

fiFuncNext:
    inc ch
    cmp ch,8
    jne fiFuncLoop

fiDevNext:
    inc bl
    cmp bl,20h
    jne fiDevLoop

fiBusNext:
    inc bh
    or bh,bh
    jnz fiBusLoop
;
    stc

fiDone:
    pop edx
    pop gs
    pop fs
    pop ds
    ret
FindIrq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupPciMsi
;
;           DESCRIPTION:    Setup PCI MSI interface
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          MSI register base
;                           AL          Int base
;                           DL          Allocated ints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_pci_msi_name DB 'Setup PCI MSI',0

setup_pci_msi     Proc far    
    push ds
    push es
    push fs
    pushad
;
    mov di,ax
    mov eax,SEG data
    mov ds,eax
;
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz spmDone
;
    mov es,ax
    movzx esi,bl
    mov ax,es:[2*esi].pcib_device_arr
    or ax,ax
    jz spmDone
;
    mov es,ax
    movzx esi,ch
    shl esi,7
    mov ax,di
    mov es:[esi].pcif_irq,al
;
    cmp dl,es:[esi].pcif_msi_count
    jbe spmCountOk
;
    mov dl,es:[esi].pcif_msi_count

spmCountOk:
    mov es:[esi].pcif_msi_count,dl
;
    xor ah,ah

spmAllocLoop:
    shr dl,1
    jc spmAllocDone
;
    inc ah
    jmp spmAllocLoop

spmAllocDone:
    mov dl,ah
    shl dl,4
    ReadPciWord
    and al,NOT 70h
    or al,dl
    or al,1
    WritePciWord
;
    GetCore
    mov es:[esi].pcif_msi_core,fs
;
    mov al,es:[esi].pcif_irq
    call SetupMsiVector

spmDone:
    popad
    pop fs
    pop es
    pop ds
    ret
setup_pci_msi     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MovePciMsi
;
;           DESCRIPTION:    Move MSI to new core
;
;           PARAMETERS:     AL          Int base
;                           FS          Core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_pci_msi_name DB 'Move PCI MSI',0

move_pci_msi     Proc far    
    push es
    pushad
;    
    call FindIrq
    jc mpmDone
;
    mov cl,es:[edi].pcif_msi
    or cl,cl
    jz mpmMsix
;
    mov es:[edi].pcif_msi_core,fs
;
    mov al,es:[edi].pcif_irq
    call SetupMsiVector
    clc
    jmp mpmDone

mpmMsix:
    mov cl,es:[edi].pcif_msix
    or cl,cl
    jz mpmDone
;    
    push ds
;
    mov ds,es:[edi].pcif_msix_irq_sel
    xor si,si
    mov cx,es:[edi].pcif_msix_count

mpmMsixIrq:
    cmp al,ds:[si]
    je mpmMsixFound
;
    add si,4
    sub cx,1
    jnz mpmMsixIrq
;
    int 3

mpmMsixFound:
    mov ds:[si+2],fs
    shl si,2
    mov es,es:[edi].pcif_msix_data_sel
;
    GetMsiVector
;
    mov es:[si],edx
    movzx eax,ax
    mov es:[si+8],eax
;
    xor eax,eax
    mov es:[si+4],eax
    mov es:[si+12],eax    
;
    pop ds

mpmDone:
    popad
    pop es
    ret
move_pci_msi     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciMsiInfo
;
;           DESCRIPTION:    Get PCI MSI info
;
;           PARAMETERS:     AL          Irq #
;
;           RETURNS:        AL          Base int
;                           DX          Core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_msi_info_name DB 'Get PCI MSI Info',0

get_pci_msi_info     Proc far    
    push es
    push ebx
    push ecx
    push edi
;
    call FindIrq
    jc gpmiDone
;
    mov bl,es:[edi].pcif_msi
    or bl,bl
    jz gpmiMsix
;
    mov al,es:[edi].pcif_irq
    mov dx,es:[edi].pcif_msi_core
    or dx,dx
    stc
    jz gpmiDone
;
    mov es,dx
    mov dx,es:cs_id
    clc
    jmp gpmiDone

gpmiMsix:
    mov bl,es:[edi].pcif_msix
    or bl,bl
    stc
    jz gpmiDone
;
    mov cx,es:[edi].pcif_msix_count
    mov es,es:[edi].pcif_msix_irq_sel
    xor di,di

gpmiMsixLoop:
    cmp al,es:[di]
    je gpmiMsixFound
;
    add di,4
    sub cx,1
    jnz gpmiMsixLoop
;
    stc
    jmp gpmiDone

gpmiMsixFound:
    mov dx,es:[di+2]
    or dx,dx
    stc
    jz gpmiDone
;
    mov es,dx
    mov dx,es:cs_id
    clc

gpmiDone:
    pop edi
    pop ecx
    pop ebx
    pop es
    ret
get_pci_msi_info      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciMsiX
;
;           DESCRIPTION:    Get PCI MSI-X interface
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;
;           RETURNS:        NC          Success
;                           DL          Requested vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_msix_name DB 'Get PCI MSI-X',0

get_pci_msix     Proc far    
    push ds
    push eax
    push esi
;
    mov eax,SEG data    
    mov ds,eax
;
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz gpmxFail
;
    mov ds,ax
    movzx esi,bl
    mov ax,ds:[2*esi].pcib_device_arr
    or ax,ax
    jz gpmxFail
;
    mov ds,ax
    movzx esi,ch
    shl esi,7
    mov al,ds:[esi].pcif_msix
    mov dl,byte ptr ds:[esi].pcif_msix_count
    or al,al
    jz gpmxFail
;
    clc
    jmp gpmxDone

gpmxFail:
    stc

gpmxDone:
    pop esi
    pop eax
    pop ds
    ret
get_pci_msix     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EnablePciMsiX
;
;           DESCRIPTION:    Enable PCI MSI-X function
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_pci_msix_name DB 'Enable PCI MSI-X',0

enable_pci_msix     Proc far    
    push ds
    pushad
;
    mov ax,SEG data    
    mov ds,ax
;
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz epmxFail
;
    mov ds,ax
    movzx esi,bl
    mov ax,ds:[2*esi].pcib_device_arr
    or ax,ax
    jz epmxFail
;
    mov ds,ax
    movzx esi,ch
    shl esi,7
    mov al,ds:[esi].pcif_msix
    or al,al
    jz epmxFail

epmxOk:
    mov eax,1000h
    AllocateBigLinear
;    
    mov cl,ds:[esi].pcif_msix
    push esi
;
    ReadPciWord
    or ax,8000h
    WritePciWord
    mov si,ax
;
    add cl,2
    ReadPciDword
    mov edi,eax
    and di,0FFF8h
;
    mov cl,al
    and cl,7
    shl cl,2
    add cl,10h
    ReadPciDword
    and al,0F0h
    add eax,edi
;
    push eax
    and ax,0F000h
    push ebx
    xor ebx,ebx
    mov al,13h
    SetPageEntry
    pop ebx
    pop eax
;
    and eax,0FFFh
    add edx,eax
;    
    AllocateGdt
    mov cx,si
    and cx,1FFh
    inc cx
    shl cx,4
    CreateDataSelector16
    mov es,bx
;
    xor edi,edi
    xor al,al
    rep stos byte ptr es:[edi]
;
    pop esi
    mov ds:[esi].pcif_msix_data_sel,bx
    clc
    jmp epmxDone

epmxFail:
    stc
    xor bx,bx
    mov es,bx    

epmxDone:
    popad
    pop ds
    ret
enable_pci_msix     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPciMsiXEntry
;
;           DESCRIPTION:    Init PCI MSI-X entry
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;                           DL          Entry #
;                           AL          Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_pci_msix_entry_name DB 'Init PCI MSI-X Entry',0

init_pci_msix_entry     Proc far    
    push ds
    push es
    push fs
    pushad
;
    mov bp,ax
    mov eax,SEG data    
    mov ds,eax
;
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz ipmxFail
;
    mov ds,ax
    movzx esi,bl
    mov ax,ds:[2*esi].pcib_device_arr
    or ax,ax
    jz ipmxFail
;
    mov ds,ax
    movzx esi,ch
    shl esi,7
    cmp dl,byte ptr ds:[esi].pcif_msix_count
    jae ipmxFail
;
    mov ax,bp
    mov es,ds:[esi].pcif_msix_irq_sel
    movzx di,dl
    shl di,2
    mov es:[di],al
;
    GetCore
    mov es:[di+2],fs
    clc
    jmp ipmxDone

ipmxFail:
    stc

ipmxDone:
    popad
    pop fs
    pop es
    pop ds
    ret
init_pci_msix_entry    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupPciMsiXEntry
;
;           DESCRIPTION:    Setup PCI MSI-X entry
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;                           DL          Entry #
;                           AL          Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_pci_msix_entry_name DB 'Setup PCI MSI-X Entry',0

setup_pci_msix_entry     Proc far    
    push ds
    push es
    push fs
    pushad
;
    mov bp,ax
    mov eax,SEG data    
    mov ds,eax
;
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz spmxFail
;
    mov ds,ax
    movzx esi,bl
    mov ax,ds:[2*esi].pcib_device_arr
    or ax,ax
    jz spmxFail
;
    mov ds,ax
    movzx esi,ch
    shl esi,7
    cmp dl,byte ptr ds:[esi].pcif_msix_count
    jae spmxFail
;
    mov ax,bp
    mov es,ds:[esi].pcif_msix_irq_sel
    movzx di,dl
    shl di,2
    mov es:[di],al
;
    GetCore
    mov es:[di+2],fs
;    
    mov es,ds:[esi].pcif_msix_data_sel
;    
    movzx esi,dl
    shl esi,4
;
    GetMsiVector
;
    mov es:[esi],edx
    movzx eax,ax
    mov es:[esi+8],eax
;
    xor eax,eax
    mov es:[esi+4],eax
    mov es:[esi+12],eax    
    clc
    jmp spmxDone

spmxFail:
    stc

spmxDone:
    popad
    pop fs
    pop es
    pop ds
    ret
setup_pci_msix_entry    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ScanPciDevice
;
;           DESCRIPTION:    Scan PCI device
;
;           PARAMETERS:     BH          Bus #
;                           BL          Device #
;
;           RETURNS:        DX          Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ScanPciDevice Proc near
    push es
;
    xor dx,dx
    mov es,dx
;
    xor ch,ch

spdFuncLoop:
    xor cl,cl
    ReadPciDword
    cmp ax,-1
    je spdNext
;
    or dx,dx
    jnz spdAdd
;
    push eax
    mov eax,SIZE pci_device_struc
    AllocateSmallGlobalMem
;
    mov edi,OFFSET pcid_func_arr
    mov ecx,8

spdInitFunc:
    mov es:[edi].pcif_vendor_dev,-1
    mov es:[edi].pcif_bridge,0
    mov es:[edi].pcif_class,0
    mov es:[edi].pcif_interface,0
    mov es:[edi].pcif_used,0
    mov es:[edi].pcif_pin,0
    mov es:[edi].pcif_irq,0
    mov es:[edi].pcif_msi,0
    mov es:[edi].pcif_msi_core,0
    mov es:[edi].pcif_msix,0
    mov es:[edi].pcif_msi_count,0
    mov es:[edi].pcif_msix_irq_sel,0
    mov es:[edi].pcif_msix_data_sel,0
    mov es:[edi].pcif_msix_count,0
    mov es:[edi].pcif_acpi_index,-1
    mov es:[edi].pcif_acpi_name,0
    add edi,SIZE pci_func_struc    
    loop spdInitFunc
;
    mov es:pcid_dev_id,bl
    mov es:pcid_bus_id,bh
    mov dx,es
    pop eax

spdAdd:
    movzx di,ch
    shl di,7
    add di,OFFSET pcid_func_arr
    mov es:[di].pcif_vendor_dev,eax
;
    mov cl,PCI_subclass
    ReadPciWord
    mov es:[edi].pcif_class,ax
;
    mov cl,PCI_progIF
    ReadPciByte
    mov es:[edi].pcif_interface,al
;
    mov cl,PCI_interrupt_pin
    ReadPciByte
    mov es:[edi].pcif_pin,al
;
    mov cl,PCI_interrupt_line
    ReadPciByte
    mov es:[edi].pcif_irq,al
;
    mov al,5
;    FindPciCapability
    jmp spMsiDone
;
    add al,2
    mov es:[edi].pcif_msi,al
;
    mov cl,al
    ReadPciWord
;
    mov cl,al
    shr cl,1
    and cl,3
    mov al,1
    shl al,cl
    mov es:[edi].pcif_msi_count,al

spMsiDone:
    mov al,11h
;    FindPciCapability
    jmp spMsiXDone
;
    add al,2
    mov es:[edi].pcif_msix,al
;
    mov cl,al
    ReadPciWord
    and ax,7FFh
    inc ax
    cmp ax,32
    jbe spMsiXCountOk
;
    mov ax,32

spMsiXCountOk:
    mov es:[edi].pcif_msix_count,ax
;
    push es
    push ebx
    push ecx
;
    mov cx,ax
    movzx eax,ax
    shl eax,2
    AllocateSmallGlobalMem
;
    xor ebx,ebx

spMsiXInit:
    mov ax,-1
    mov es:[ebx],ax
    xor ax,ax
    mov es:[ebx+2],ax
;
    add ebx,2
    sub cx,1
    jnz spMsiXInit
;
    mov ax,es
;
    pop ecx
    pop ebx
    pop es
    mov es:[edi].pcif_msix_irq_sel,ax

spMsiXDone:
    mov cl,PCI_header_type
    ReadPciByte
    mov ah,al
    and al,7Fh
    cmp al,1
    jne spdFuncNext
;
    push es
    pushad
;
    mov cl,PCI_br_secondary_bus
    ReadPciByte
    mov bh,al

    push edi    
    call ScanPciBus
    pop edi
    mov es:[edi].pcif_bridge,si
;
    or si,si
    jz spdEmptyBus
;
    mov es,si
    popad
;
    mov es:pcib_owner_bus,bh
    mov es:pcib_owner_dev,bl
    mov es:pcib_owner_func,ch
;
    pop es
    jmp spdFuncNext

spdEmptyBus:
    popad
    pop es

spdFuncNext:    
    or ch,ch
    jnz spdNext
;
    test ah,80h
    jz spdDone

spdNext:
    inc ch
    cmp ch,8
    jne spdFuncLoop

spdDone:
    pop es
    ret
ScanPciDevice Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ScanPciBus
;
;           DESCRIPTION:    Scan PCI bus
;
;           PARAMETERS:     BH          Bus #
;
;           RETURNS:        SI          Bus selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ScanPciBus Proc near
    push es
;
    xor esi,esi
    mov es,esi
;
    xor bl,bl

spbDeviceLoop:
    call ScanPciDevice
    or dx,dx
    jz spbNext
;
    or si,si
    jnz spbAdd
;
    mov eax,SIZE pci_bus_struc
    AllocateSmallGlobalMem
;
    mov edi,OFFSET pcib_device_arr
    mov ecx,32
    xor ax,ax
    rep stosw
;
    mov es:pcib_bus_id,bh
    mov es:pcib_owner_bus,0
    mov es:pcib_owner_dev,0
    mov es:pcib_owner_func,0
    mov si,es

spbAdd:
    movzx edi,bl
    mov es:[2*edi].pcib_device_arr,dx

spbNext:
    inc bl
    cmp bl,32
    jne spbDeviceLoop
;
    movzx edi,bh
    mov ds:[2*edi].pci_bus_arr,si
    pop es
    ret
ScanPciBus Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DetectDevices
;
;           DESCRIPTION:    Detect devices
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DetectDevices Proc near
    mov eax,SEG data
    mov ds,eax
;
    xor bh,bh
    call ScanPciBus
;
    ret
DetectDevices  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetApicTable
;
;           DESCRIPTION:    Get APIC table
;
;           RETURNS:        ES      APIC table        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetApicTable
    
GetApicTable Proc near
    push eax
;
    mov eax,system_data_sel
    mov es,eax
    mov es,es:acpi_apic_table
;
    pop eax
    ret
GetApicTable  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HasApic
;
;           DESCRIPTION:    Has APIC?
;
;           RETURNS:        NC      APIC available
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HasApic
    
HasApic Proc near
    push ds
    push eax
;
    mov eax,system_data_sel
    mov ds,eax
    mov ax,ds:acpi_apic_table
    or ax,ax
    stc
    jz haDone
;
    clc

haDone:
    pop eax
    pop ds
    ret
HasApic  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_pci_thread
;
;           DESCRIPTION:    Init_pci_thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_pci_thread

init_pci_thread:
    mov eax,SEG data
    mov ds,eax
    movzx ecx,ds:pci_init_hooks
    or ecx,ecx
    je hook_thread_done
;
    mov ebx,OFFSET pci_init_hook_arr

hook_thread_loop:
    push ds
    push ebx
    push ecx
    call fword ptr [ebx]
    pop ecx
    pop ebx
    pop ds
    add ebx,8
    loop hook_thread_loop

hook_thread_done:
    TerminateThread
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Test gate
;
;       DESCRIPTION:    Test
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_gate_name  DB 'Test', 0


test_gate    Proc far
    push ds
    push es
    pushad
;
    mov eax,system_data_sel
    mov ds,eax
    mov ax,ds:acpi_apic_table
    mov ax,ds:acpi_hpet_table
    mov al,ds:acpi_reset_method
    mov eax,ds:acpi_reset_addr
    mov al,ds:acpi_reset_data

tgDone:
    popad
    pop es
    pop ds
    ret
test_gate    Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init
;
;           DESCRIPTION:    INIT PCI DEVICE
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern init_irq:near
    extern init_uacpi:near
    extern init_apic:near
    extern init_smp:near
    extern init_timer:near
    extern init_msi:near
    extern start_timer:near
    extern start_smp:near
    extern init_pic:near
    
init    Proc far
    push ds
    push es
    pushad
;
    mov ebx,SEG data
    mov ds,ebx
    mov es,ebx
;
    mov ds:pci_init_hooks,0
    InitSpinlock ds:pci_spinlock
;
    mov edi,OFFSET pci_bus_arr
    mov ecx,256
    xor ax,ax
    rep stosw
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET hook_init_pci
    mov edi,OFFSET hook_init_pci_name
    mov ax,hook_init_pci_nr
    RegisterOsGate
;
    mov esi,OFFSET test_gate
    mov edi,OFFSET test_gate_name
    xor dx,dx
    mov ax,test_gate_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET soft_reset
    mov edi,OFFSET soft_reset_name
    xor dx,dx
    mov ax,fault_reset_nr
    RegisterOsGate
;
    mov esi,OFFSET get_pci_bar_phys
    mov edi,OFFSET get_pci_bar_phys_name
    xor cl,cl
    mov ax,get_pci_bar_phys_nr
    RegisterOsGate
;
    mov esi,OFFSET get_pci_bar_io
    mov edi,OFFSET get_pci_bar_io_name
    xor cl,cl
    mov ax,get_pci_bar_io_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_pci_handle_irq
    mov edi,OFFSET setup_pci_handle_irq_name
    xor cl,cl
    mov ax,setup_pci_handle_irq_nr
    RegisterOsGate
;
    mov esi,OFFSET req_pci_handle_msi
    mov edi,OFFSET req_pci_handle_msi_name
    xor cl,cl
    mov ax,req_pci_handle_msi_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_pci_handle_msi
    mov edi,OFFSET setup_pci_handle_msi_name
    xor cl,cl
    mov ax,setup_pci_handle_msi_nr
    RegisterOsGate
;
    mov esi,OFFSET enable_pci_handle_msi
    mov edi,OFFSET enable_pci_handle_msi_name
    xor cl,cl
    mov ax,enable_pci_handle_msi_nr
    RegisterOsGate
;
    mov esi,OFFSET soft_reset
    mov edi,OFFSET soft_reset_name
    xor dx,dx
    mov ax,soft_reset_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET find_pci_device
    mov edi,OFFSET find_pci_device_name
    xor dx,dx
    mov ax,find_pci_device_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET find_pci_class
    mov edi,OFFSET find_pci_class_name
    xor dx,dx
    mov ax,find_pci_class_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET find_pci_prot
    mov edi,OFFSET find_pci_prot_name
    xor dx,dx
    mov ax,find_pci_prot_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_handle
    mov edi,OFFSET get_pci_handle_name
    xor dx,dx
    mov ax,get_pci_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_handle_param
    mov edi,OFFSET get_pci_handle_param_name
    xor dx,dx
    mov ax,get_pci_handle_param_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_handle_irq
    mov edi,OFFSET get_pci_handle_irq_name
    xor dx,dx
    mov ax,get_pci_handle_irq_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_handle_msi
    mov edi,OFFSET get_pci_handle_msi_name
    xor dx,dx
    mov ax,get_pci_handle_msi_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_handle_msix
    mov edi,OFFSET get_pci_handle_msix_name
    xor dx,dx
    mov ax,get_pci_handle_msix_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET eval_pci_int_arr16
    mov esi,OFFSET eval_pci_int_arr32
    mov edi,OFFSET eval_pci_int_arr_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,eval_pci_int_arr_nr
    RegisterUserGate
;
    mov esi,OFFSET get_pci_cap
    mov edi,OFFSET get_pci_cap_name
    xor dx,dx
    mov ax,get_pci_cap_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_pci_device_name16
    mov esi,OFFSET get_pci_device_name32
    mov edi,OFFSET get_pci_device_name
    mov dx,virt_es_in
    mov ax,get_pci_device_name_nr
    RegisterUserGate
;
    mov esi,OFFSET read_pci_config_byte
    mov edi,OFFSET read_pci_config_byte_name
    xor dx,dx
    mov ax,read_pci_config_byte_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET read_pci_config_word
    mov edi,OFFSET read_pci_config_word_name
    xor dx,dx
    mov ax,read_pci_config_word_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET read_pci_config_dword
    mov edi,OFFSET read_pci_config_dword_name
    xor dx,dx
    mov ax,read_pci_config_dword_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_pci_config_byte
    mov edi,OFFSET write_pci_config_byte_name
    xor dx,dx
    mov ax,write_pci_config_byte_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_pci_config_word
    mov edi,OFFSET write_pci_config_word_name
    xor dx,dx
    mov ax,write_pci_config_word_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_pci_config_dword
    mov edi,OFFSET write_pci_config_dword_name
    xor dx,dx
    mov ax,write_pci_config_dword_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_bus
    mov edi,OFFSET get_pci_bus_name
    xor dx,dx
    mov ax,get_pci_bus_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET lock_pci_handle16
    mov esi,OFFSET lock_pci_handle32
    mov edi,OFFSET lock_pci_handle_name
    mov dx,virt_es_in
    mov ax,lock_pci_handle_nr
    RegisterUserGate
;
    mov esi,OFFSET unlock_pci_handle
    mov edi,OFFSET unlock_pci_handle_name
    xor dx,dx
    mov ax,unlock_pci_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_pci_handle_locked
    mov edi,OFFSET is_pci_handle_locked_name
    xor dx,dx
    mov ax,is_pci_handle_locked_nr
    RegisterBimodalUserGate
;
; legacy
;
    mov esi,OFFSET read_pci_byte
    mov edi,OFFSET read_pci_byte_name
    xor cl,cl
    mov ax,read_pci_byte_nr
    RegisterOsGate
;
    mov esi,OFFSET read_pci_word
    mov edi,OFFSET read_pci_word_name
    xor cl,cl
    mov ax,read_pci_word_nr
    RegisterOsGate
;
    mov esi,OFFSET read_pci_dword
    mov edi,OFFSET read_pci_dword_name
    xor cl,cl
    mov ax,read_pci_dword_nr
    RegisterOsGate
;
    mov esi,OFFSET write_pci_byte
    mov edi,OFFSET write_pci_byte_name
    xor cl,cl
    mov ax,write_pci_byte_nr
    RegisterOsGate
;
    mov esi,OFFSET write_pci_word
    mov edi,OFFSET write_pci_word_name
    xor cl,cl
    mov ax,write_pci_word_nr
    RegisterOsGate
;
    mov esi,OFFSET write_pci_dword
    mov edi,OFFSET write_pci_dword_name
    xor cl,cl
    mov ax,write_pci_dword_nr
    RegisterOsGate
;
    mov esi,OFFSET get_pci_dsd_config
    mov edi,OFFSET get_pci_dsd_config_name
    xor cl,cl
    mov ax,get_pci_dsd_config_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_pci_msi
    mov edi,OFFSET setup_pci_msi_name
    xor cl,cl
    mov ax,setup_pci_msi_nr
    RegisterOsGate
;
    mov esi,OFFSET get_pci_msi_info
    mov edi,OFFSET get_pci_msi_info_name
    xor cl,cl
    mov ax,get_pci_msi_info_nr
    RegisterOsGate
;
    mov esi,OFFSET move_pci_msi
    mov edi,OFFSET move_pci_msi_name
    xor cl,cl
    mov ax,move_pci_msi_nr
    RegisterOsGate
;
    mov esi,OFFSET enable_pci_msix
    mov edi,OFFSET enable_pci_msix_name
    xor cl,cl
    mov ax,enable_pci_msix_nr
    RegisterOsGate
;
    mov esi,OFFSET init_pci_msix_entry
    mov edi,OFFSET init_pci_msix_entry_name
    xor cl,cl
    mov ax,init_pci_msix_entry_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_pci_msix_entry
    mov edi,OFFSET setup_pci_msix_entry_name
    xor cl,cl
    mov ax,setup_pci_msix_entry_nr
    RegisterOsGate
;
    mov esi,OFFSET get_pci_irq
    mov edi,OFFSET get_pci_irq_name
    xor dx,dx
    mov ax,get_pci_irq_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_irq_pin
    mov edi,OFFSET get_pci_irq_pin_name
    xor dx,dx
    mov ax,get_pci_irq_pin_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_class
    mov edi,OFFSET get_pci_class_name
    xor dx,dx
    mov ax,get_pci_class_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_interface
    mov edi,OFFSET get_pci_interface_name
    xor dx,dx
    mov ax,get_pci_interface_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_device_vendor
    mov edi,OFFSET get_pci_device_vendor_name
    xor dx,dx
    mov ax,get_pci_device_vendor_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_pci_function_used
    mov edi,OFFSET is_pci_function_used_name
    xor dx,dx
    mov ax,is_pci_function_used_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_msi
    mov edi,OFFSET get_pci_msi_name
    xor dx,dx
    mov ax,get_pci_msi_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_msix
    mov edi,OFFSET get_pci_msix_name
    xor dx,dx
    mov ax,get_pci_msix_nr
    RegisterBimodalUserGate
;
    call init_uacpi
;
    mov eax,system_data_sel
    mov ds,eax
    mov ax,ds:acpi_apic_table
    or ax,ax
    jz use_pic
;
    call init_irq
    call init_msi
    call init_smp
    call init_timer
    call init_apic
    call start_timer
    call start_smp
    jmp init_done

use_pic:
    call init_pic
 
init_done:
    call DetectDevices
    clc
;
    popad
    pop es
    pop ds
    ret
init    Endp

code    ENDS

    END init
