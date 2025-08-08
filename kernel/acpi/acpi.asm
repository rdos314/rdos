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

data    SEGMENT byte public 'DATA'

pci_init_hooks          DW ?
pci_init_hook_arr       DD 64 DUP(?,?)

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
    extern RequestMsiHandler:near

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
;           NAME:           GetPciParam
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

get_pci_param_name      DB 'Get PCI Param',0

get_pci_param   Proc far
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
get_pci_param   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciIrq
;
;           DESCRIPTION:    Find PCI IRQ
;
;           PARAMETERS:     BX      Handle
;                           AX      Index
;
;           RETURNS:        AL      Irq
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_irq_name      DB 'Get PCI IRQ',0

get_pci_irq   Proc far
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
get_pci_irq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciMsiInts
;
;           DESCRIPTION:    Get PCI MSI IRQs
;
;           PARAMETERS:     BX      Handle
;
;           RETURNS:        AL      Vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_msi_irqs_name      DB 'Get PCI MSI IRQs',0

get_pci_msi_irqs   Proc far
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
get_pci_msi_irqs   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciMsiXIrqs
;
;           DESCRIPTION:    Get PCI MSI-X IRQs
;
;           PARAMETERS:     BX      Handle
;
;           RETURNS:        AL      Vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_msix_irqs_name      DB 'Get PCI MSI-X IRQs',0

get_pci_msix_irqs   Proc far
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
get_pci_msix_irqs   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupPciIrq
;
;           DESCRIPTION:    Setup for single IRQ
;
;           PARAMETERS:     AH      Priority
;                           BX      Handle
;                           DS      Data passed to handler
;                           ES:EDI  Handler address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_pci_irq_name      DB 'Setup PCI IRQ',0

setup_pci_irq   Proc far
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
    call RequestMsiHandler
;
    push ds
    push es
    push ecx
    push edx
    push edi
    push ebp
;
    xor al,al
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
setup_pci_irq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReqPciMsi
;
;           DESCRIPTION:    Req MSI vectors
;
;           PARAMETERS:     AH      Priority
;                           BX      Handle
;                           CL      Requested vectors
;
;           RETURNS:        CX      Setup vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_pci_msi_name      DB 'Req PCI MSI',0

default_int	Proc far
    ret
default_int     Endp

req_pci_msi   Proc far
    push eax
;
    push ds
    push es
    push edx
    push esi
    push edi
    push ebp
;
    push eax
    GetCoreId
    movzx esi,ax
    pop eax
;
    mov edx,[esp+32]
;
    call AllocateMsg
;    
    mov eax,REQ_PCI_MSI_CMD
    call RunMsg
;    
    pop ebp
    pop edi
    pop esi
    pop edx
    pop es
    pop ds
;
    or al,al
    stc
    jz rpmDone
;
    or cl,cl
    jne rpmMsi

rpmMsiX:
    movzx cx,al
    clc
    jmp rpmDone

rpmMsi:
    xchg al,cl
    movzx ecx,cl
;
    push ds
    push es
    push ecx
    push edi
;
    xor edi,edi
    mov ds,edi
    mov edi,cs
    mov es,edi
    mov edi,OFFSET default_int

rpmDefaultLoop:
    call RequestMsiHandler
    inc al
    loop rpmDefaultLoop
;
    pop edi
    pop ecx
    pop es
    pop ds
;
    clc

rpmDone:
    pop eax
    ret
req_pci_msi   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupPciMsi
;
;           DESCRIPTION:    Setup MSI IRQ
;
;           PARAMETERS:     AH      Prio
;                           BX      Handle
;                           AL      Entry
;                           DS      Data passed to handler
;                           ES:EDI  Handler address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_pci_msi_name      DB 'Setup PCI MSI',0

setup_pci_msi   Proc far
    push eax
;
    push ds
    push es
    push edx
    push esi
    push edi
    push ebp
;
    push eax
    GetCoreId
    movzx esi,ax
    pop eax
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
    pop es
    pop ds
    jc sphmDone
;
    or al,al
    stc
    jz sphmDone
;
    call RequestMsiHandler
;
    pop eax
    push eax
;
    push ds
    push es
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
    pop es
    pop ds
    clc

sphmDone:    
    pop eax
    ret
setup_pci_msi   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EnablePciMsi
;
;           DESCRIPTION:    Enable PCI MSI handlers
;
;           PARAMETERS:     BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_pci_msi_name      DB 'Enable PCI MSI',0

enable_pci_msi   Proc far
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
enable_pci_msi   Endp

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

eval_pci_int_arr  Proc near
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
eval_pci_int_arr   Endp

eval_pci_int_arr16  Proc far
    push ecx
    push esi
    push edi
;
    movzx ecx,cx
    movzx esi,si
    movzx edi,di
    call eval_pci_int_arr
;    
    pop edi
    pop esi
    pop ecx
    ret
eval_pci_int_arr16  Endp

eval_pci_int_arr32  Proc far
    call eval_pci_int_arr
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
;    NAME:           LockPci16/32
;
;    DESCRIPTION:    Lock PCI
;
;    PARAMETERS:     BX          Handle
;                    ES:(E)DI    Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_pci_name DB 'Lock PCI', 0

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

lock_pci16  Proc far
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
lock_pci16  Endp

lock_pci32  Proc far
    push edx
    mov edx,[esp+8]
;
    call LockHandle
;
    pop edx    
    ret
lock_pci32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockPci
;
;           DESCRIPTION:    Unlock PCI
;
;           PARAMETERS:     BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_pci_name      DB 'Unlock PCI',0

unlock_pci   Proc far
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
unlock_pci   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsPciLocked
;
;           DESCRIPTION:    Check if PCI is locked
;
;           PARAMETERS:     BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_pci_locked_name      DB 'Is PCI Locked',0

is_pci_locked   Proc far
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
is_pci_locked   Endp
        
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
;           NAME:           init
;
;           DESCRIPTION:    INIT PCI DEVICE
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern init_task:near
    extern init_irq:near
    extern init_uacpi:near
    extern init_apic:near
    extern init_smp:near
    extern init_timer:near
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
    call init_task
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
    mov esi,OFFSET setup_pci_irq
    mov edi,OFFSET setup_pci_irq_name
    xor cl,cl
    mov ax,setup_pci_irq_nr
    RegisterOsGate
;
    mov esi,OFFSET req_pci_msi
    mov edi,OFFSET req_pci_msi_name
    xor cl,cl
    mov ax,req_pci_msi_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_pci_msi
    mov edi,OFFSET setup_pci_msi_name
    xor cl,cl
    mov ax,setup_pci_msi_nr
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
    mov esi,OFFSET get_pci_param
    mov edi,OFFSET get_pci_param_name
    xor dx,dx
    mov ax,get_pci_param_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_irq
    mov edi,OFFSET get_pci_irq_name
    xor dx,dx
    mov ax,get_pci_irq_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_msi_irqs
    mov edi,OFFSET get_pci_msi_irqs_name
    xor dx,dx
    mov ax,get_pci_msi_irqs_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_msix_irqs
    mov edi,OFFSET get_pci_msix_irqs_name
    xor dx,dx
    mov ax,get_pci_msix_irqs_nr
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
    mov ebx,OFFSET lock_pci16
    mov esi,OFFSET lock_pci32
    mov edi,OFFSET lock_pci_name
    mov dx,virt_es_in
    mov ax,lock_pci_nr
    RegisterUserGate
;
    mov esi,OFFSET unlock_pci
    mov edi,OFFSET unlock_pci_name
    xor dx,dx
    mov ax,unlock_pci_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_pci_locked
    mov edi,OFFSET is_pci_locked_name
    xor dx,dx
    mov ax,is_pci_locked_nr
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
    call init_smp
    call init_timer
    call init_apic
    call start_timer
    call start_smp
    jmp init_done

use_pic:
    call init_pic
 
init_done:
    clc
;
    popad
    pop es
    pop ds
    ret
init    Endp

code    ENDS

    END init
