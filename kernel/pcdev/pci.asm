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
; PCI.ASM
; PCI support
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
include ..\acpi.def
include ..\acpi.inc
INCLUDE pci.inc
INCLUDE ..\os\core.inc

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

data    SEGMENT byte public 'DATA'

pci_spinlock            spinlock_typ <>

pci_init_hooks          DW ?
pci_init_hook_arr       DD 32 DUP(?,?)

pci_bus_arr             DW 256 DUP(?)

data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use16 'CODE'

    assume cs:code

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
    push ax
    push bx
;    
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:pci_init_hooks
    mov bx,ax
    shl bx,3
    add bx,OFFSET pci_init_hook_arr
    mov [bx],edi
    mov [bx+4],es
    inc ax
    mov ds:pci_init_hooks,ax
;
    pop bx
    pop ax
    pop ds
    retf32
hook_init_pci   Endp

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

GetPciBusCount  Proc near
    push ds
    push ebx
    push ecx
    push dx
;
    mov ax,SEG data
    mov ds,ax
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
    pop dx
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
    push bx
    push ecx
    push dx
;
    mov ax,SEG data
    mov ds,ax
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
    pop dx
    pop ecx
    pop bx
    pop ds
    retf32
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
    push bx
    push ecx
    push dx
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
    pop dx
    pop ecx
    pop bx
    pop eax
    pop ds
    retf32
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
    push bx
    push ecx
    push dx
;
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
    and cl,2
    or dl,cl
    in ax,dx
    ReleaseSpinlock ds:pci_spinlock
;
    pop dx
    pop ecx
    pop bx
    pop ds
    retf32
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
    push bx
    push ecx
    push dx
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
    pop dx
    pop ecx
    pop bx
    pop eax
    pop ds
    retf32
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
    push bx
    push ecx
    push dx
;
    mov ax,SEG data
    mov ds,ax
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
    pop dx
    pop ecx
    pop bx
    pop ds
    retf32
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
    push bx
    push ecx
    push dx
;
    push eax
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
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    pop eax
    out dx,eax
    ReleaseSpinlock ds:pci_spinlock
;
    pop dx
    pop ecx
    pop bx
    pop eax
    pop ds
    retf32
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
    mov ax,SEG data    
    mov ds,ax
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
    retf32
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
    mov ax,SEG data    
    mov ds,ax
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
    retf32
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
    push cx
    mov cl,PCI_interrupt_pin
    ReadPciByte
    pop cx
    retf32
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
    mov ax,SEG data    
    mov ds,ax
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
    retf32
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
    mov ax,SEG data    
    mov ds,ax
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
    retf32
get_pci_interface   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           GetPciDeviceName16/32
;
;    DESCRIPTION:    Get PCI device name
;
;    PARAMETERS:     BH          Bus
;                    BL          Device
;                    CH          Function
;                    ES:(E)DI    Name buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_device_name DB 'Get PCI Device Name', 0

GetDevName  Proc near
    push ds
    push eax
    push esi
;
    mov ax,SEG data    
    mov ds,ax
;
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz gpdnFail
;
    mov ds,ax
    movzx esi,bl
    mov ax,ds:[2*esi].pcib_device_arr
    or ax,ax
    jz gpdnFail
;
    mov ds,ax
    movzx esi,ch
    shl esi,7
    add esi,OFFSET pcif_acpi_name

gpdnLoop:
    lods byte ptr ds:[esi]
    stos byte ptr es:[edi]
    or al,al
    jnz gpdnLoop
;
    clc
    jmp gpdnDone

gpdnFail:
    stc

gpdnDone:
    pop esi
    pop eax
    pop ds
    ret
GetDevName   Endp

get_pci_device_name16  Proc far
    push edi
    movzx edi,di
    call GetDevName
    pop edi
    retf32
get_pci_device_name16  Endp

get_pci_device_name32  Proc far
    call GetDevName
    retf32
get_pci_device_name32  Endp

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
    mov ax,SEG data    
    mov ds,ax
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
    retf32
get_pci_device_vendor  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindPciDevice
;
;           DESCRIPTION:    Find a PCI device
;
;           PARAMETERS:     CX          Device ID
;                           DX          Vendor ID
;                           AH:AL       Bus & device to start scanning
;
;           RETURNS:        NC          Success
;                           BH          Bus
;                           BL          Device
;                           CH          Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_pci_device_name    DB 'Find PCI Device',0

find_pci_device Proc far
    push ds
    push es
    push fs
    push esi
;
    mov bx,SEG data
    mov ds,bx
;
    mov bx,ax

fpdBusLoop:
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz fpdBusNext
;
    mov es,ax

fpdDevLoop:
    movzx esi,bl
    mov ax,es:[2*esi].pcib_device_arr
    or ax,ax
    jz fpdDevNext
;
    mov fs,ax
    xor al,al

fpdFuncLoop:
    movzx esi,al
    shl esi,7
    add esi,OFFSET pcid_func_arr
;
    cmp dx,word ptr fs:[esi].pcif_vendor_dev
    jne fpdFuncNext
;
    cmp cx,word ptr fs:[esi].pcif_vendor_dev+2
    jne fpdFuncNext
;
    mov ch,al
    clc
    jmp fpdDone

fpdFuncNext:
    inc al
    cmp al,8
    jne fpdFuncLoop

fpdDevNext:
    inc bl
    cmp bl,20h
    jne fpdDevLoop

fpdBusNext:
    xor bl,bl
    inc bh
    or bh,bh
    jnz fpdBusLoop
;
    stc

fpdDone:
    pop esi
    pop fs
    pop es
    pop ds
    retf32
find_pci_device Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindPciClassInterface
;
;           DESCRIPTION:    Find PCI class
;
;           PARAMETERS:     BH          Class
;                           BL          Sub class
;                           CH          Interface
;                           AX          Entry #
;
;           RETURNS:        NC          Success
;                           BH          Bus
;                           BL          Device
;                           CH          Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_pci_class_interface_name     DB 'Find PCI Class Interface',0

find_pci_class_interface  Proc far
    push ds
    push es
    push fs
    push edx
    push esi
    push edi
    push ebp
;
    mov bp,ax
    mov dx,SEG data
    mov ds,dx
;
    mov dl,ch
    mov di,bx
    xor bx,bx

fpciBusLoop:
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz fpciBusNext
;
    mov es,ax
    xor bl,bl

fpciDevLoop:
    movzx esi,bl
    mov ax,es:[2*esi].pcib_device_arr
    or ax,ax
    jz fpciDevNext
;
    mov fs,ax
    xor ch,ch

fpciFuncLoop:
    movzx esi,ch
    shl esi,7
    add esi,OFFSET pcid_func_arr
;
    cmp di,fs:[esi].pcif_class
    jne fpciFuncNext
;
    cmp dl,fs:[esi].pcif_interface
    jne fpciFuncNext
;
    or bp,bp
    clc
    je fpciDone
;
    dec bp

fpciFuncNext:
    inc ch
    cmp ch,8
    jne fpciFuncLoop

fpciDevNext:
    inc bl
    cmp bl,20h
    jne fpciDevLoop

fpciBusNext:
    inc bh
    or bh,bh
    jnz fpciBusLoop
;
    stc

fpciDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop fs
    pop es
    pop ds
    retf32
find_pci_class_interface  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindPciClass
;
;           DESCRIPTION:    Find PCI class, ignore interface
;
;           PARAMETERS:     BH          Class
;                           BL          Sub class
;                           AX          Entry #
;
;           RETURNS:        NC          Success
;                           BH          Bus
;                           BL          Device
;                           CH      Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_pci_class_name DB 'Find PCI Class',0

find_pci_class      Proc far
    push ds
    push es
    push fs
    push edx
    push esi
    push edi
    push ebp
;
    mov bp,ax
    mov dx,SEG data
    mov ds,dx
;
    mov di,bx
    xor bx,bx

fpcoBusLoop:
    movzx esi,bh
    mov ax,ds:[2*esi].pci_bus_arr
    or ax,ax
    jz fpcoBusNext
;
    mov es,ax
    xor bl,bl

fpcoDevLoop:
    movzx esi,bl
    mov ax,es:[2*esi].pcib_device_arr
    or ax,ax
    jz fpcoDevNext
;
    mov fs,ax
    xor ch,ch

fpcoFuncLoop:
    movzx esi,ch
    shl esi,7
    add esi,OFFSET pcid_func_arr
;
    cmp di,fs:[esi].pcif_class
    jne fpcoFuncNext
;
    or bp,bp
    clc
    je fpcoDone
;
    dec bp

fpcoFuncNext:
    inc ch
    cmp ch,8
    jne fpcoFuncLoop

fpcoDevNext:
    inc bl
    cmp bl,20h
    jne fpcoDevLoop

fpcoBusNext:
    inc bh
    or bh,bh
    jnz fpcoBusLoop
;
    stc

fpcoDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop fs
    pop es
    pop ds
    retf32
find_pci_class      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindPciCapability
;
;           DESCRIPTION:    Find a PCI capability
;
;           PARAMETERS:         BH          Bus
;                           BL          Device
;                           CH          Function
;               AL      Capability
;
;           RETURNS:        AL      Index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_pci_cap_name       DB 'Find PCI Capability',0

find_pci_cap    Proc far
    push dx
;
    mov dl,al
    mov cl,6
    ReadPciWord
    test al,10h
    stc
    jz fpcDone
;
    mov cl,34h
    ReadPciByte
;
    mov cl,al
    mov dh,48

fpcLoop:
    and cl,NOT 3
    cmp cl,40h
    jc fpcDone
;
    ReadPciByte
    cmp al,-1
    stc
    jz fpcDone
;
    cmp al,dl
    je fpcOk
;
    inc cl
    ReadPciByte
    mov cl,al
;
    sub dh,1    
    jnz fpcLoop            
;
    stc
    jmp fpcDone    

fpcOk:
    mov al,cl
    clc

fpcDone:    
    pop dx
    retf32
find_pci_cap    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetPciDeviceName
;
;           DESCRIPTION:    Set PCI device name
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;                           ES:EDI      Device name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_pci_device_name_name       DB 'Set PCI Device Name',0

set_pci_device_name    Proc far
    push ds
    push es
    pushad
;
    mov ax,es
    mov ds,ax
    mov esi,edi
;
    mov ax,SEG data    
    mov es,ax
;
    movzx edi,bh
    mov ax,es:[2*edi].pci_bus_arr
    or ax,ax
    jz spdnDone
;
    mov es,ax
    movzx edi,bl
    mov ax,es:[2*edi].pcib_device_arr
    or ax,ax
    jz spdnDone
;
    mov es,ax
    movzx edi,ch
    shl edi,7
    add edi,OFFSET pcif_acpi_name

spdnCopyName:
    lods byte ptr ds:[esi]
    stos byte ptr es:[edi]
    or al,al
    jnz spdnCopyName

spdnDone:
    popad
    pop es
    pop ds
    retf32
set_pci_device_name    Endp

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
    retf32
get_pci_dsd_config   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PciPowerOn
;
;           DESCRIPTION:    Set PCI device to D0 power state
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;                           ES:EDI      Device name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pci_power_on_name       DB 'PCI Power On',0

pci_power_on    Proc far
    push ds
    push es
    pushad
;
    mov ax,es
    mov ds,ax
    mov esi,edi
;
    mov ax,SEG data    
    mov es,ax
;
    movzx edi,bh
    mov ax,es:[2*edi].pci_bus_arr
    or ax,ax
    jz ppoStart
;
    mov es,ax
    movzx edi,bl
    mov ax,es:[2*edi].pcib_device_arr
    or ax,ax
    jz ppoStart
;
    mov es,ax
    movzx edi,ch
    shl edi,7
    mov es:[di].pcif_used,1
    add edi,OFFSET pcif_acpi_name

ppoCopyName:
    lods byte ptr ds:[esi]
    stos byte ptr es:[edi]
    or al,al
    jnz ppoCopyName

ppoStart:
    mov al,1
    FindPciCapability
    jc ppoDone
;
    mov cl,al
    add cl,4
    ReadPciWord
    and al,3
    jz ppoInD0
;
    mov ax,8000h
    WritePciWord
;
    mov ax,10
    WaitMilliSec
    jmp ppoDone

ppoInD0:
    mov ax,8000h
    WritePciWord

ppoDone:
    popad
    pop es
    pop ds
    retf32
pci_power_on    Endp
        
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
    mov ax,SEG data    
    mov ds,ax
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
    retf32
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
SetupMsiVector	Endp

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
    mov dx,SEG data
    mov ds,dx
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
    mov ax,SEG data
    mov ds,ax
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
    retf32
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
    retf32
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
    retf32
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
    mov ax,SEG data    
    mov ds,ax
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
    retf32
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
    xor di,di
    xor al,al
    rep stos byte ptr es:[di]
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
    retf32
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
    mov ax,SEG data    
    mov ds,ax
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
    retf32
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
    mov ax,SEG data    
    mov ds,ax
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
    movzx si,dl
    shl si,4
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
    clc
    jmp spmxDone

spmxFail:
    stc

spmxDone:
    popad
    pop fs
    pop es
    pop ds
    retf32
setup_pci_msix_entry    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           bios_pci_int
;
;           DESCRIPTION:    Handling BIOS PCI int (0B1h, int 1Ah)
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bios_pci_int_name DB 'BIOS PCI int',0

pci_error       Proc near
    int 3
    or byte ptr [ebp].trap_eflags,1
    ret
pci_error       Endp

pci_inst_check  Proc near
    mov edx,20494350h
    xor edi,edi
    call GetPciBusCount
    mov cl,al
    mov eax,[ebp].trap_eax
    xor ax,ax
    mov word ptr [ebp].trap_ebx,210h
    and byte ptr [ebp].trap_eflags,NOT 1
    ret
pci_inst_check  Endp

pci_find_device Proc near
    mov ax,si
    FindPciDevice
    jc pci_find_device_fail
;
    shl bl,3
    xor ax,ax
    mov [ebp].trap_ebx,bx
    and byte ptr [ebp].trap_eflags,NOT 1
    ret

pci_find_device_fail:
    or byte ptr [ebp].trap_eflags,1    
    mov ax,8600h
    ret
pci_find_device Endp

pci_find_class  Proc near
    mov eax,ecx
    mov cx,si
    mov ch,al
    mov bl,ah
    shr eax,16
    mov bh,al
    FindPciClassInterface
    jc pci_find_fail
;
    shl bl,3
    xor ax,ax
    mov [ebp].trap_ebx,bx
    and byte ptr [ebp].trap_eflags,NOT 1
    ret

pci_find_fail:
    or byte ptr [ebp].trap_eflags,1    
    mov ax,8600h
    ret
pci_find_class  Endp

pci_read_byte   Proc near
    mov cx,di
    mov bx,[ebp].trap_ebx
    mov ch,bl
    and ch,7
    shr bl,3
    ReadPciByte
    mov cl,al
    xor ax,ax
    and byte ptr [ebp].trap_eflags,NOT 1
    ret
pci_read_byte   Endp

pci_write_byte  Proc near
    mov al,cl
    mov cx,di
    mov bx,[ebp].trap_ebx
    mov ch,bl
    and ch,7
    shr bl,3
    WritePciByte
    xor ax,ax
    and byte ptr [ebp].trap_eflags,NOT 1
    ret
pci_write_byte  Endp

pci_read_word   Proc near
    mov cx,di
    mov bx,[ebp].trap_ebx
    mov ch,bl
    and ch,7
    shr bl,3
    ReadPciWord
    mov cx,ax
    xor ax,ax
    and byte ptr [ebp].trap_eflags,NOT 1
    ret
pci_read_word   Endp

pci_write_word  Proc near
    mov ax,cx
    mov cx,di
    mov bx,[ebp].trap_ebx
    mov ch,bl
    and ch,7
    shr bl,3
    WritePciWord
    xor ax,ax
    and byte ptr [ebp].trap_eflags,NOT 1
    ret
pci_write_word  Endp

pci_read_dword  Proc near
    mov cx,di
    mov bx,[ebp].trap_ebx
    mov ch,bl
    and ch,7
    shr bl,3
    ReadPciDword
    mov ecx,eax
    xor ax,ax
    and byte ptr [ebp].trap_eflags,NOT 1
    ret
pci_read_dword  Endp

pci_write_dword Proc near
    mov eax,ecx
    mov cx,di
    mov bx,[ebp].trap_ebx
    mov ch,bl
    and ch,7
    shr bl,3
    WritePciDword
    xor ax,ax
    and byte ptr [ebp].trap_eflags,NOT 1
    ret
pci_write_dword Endp

pci_int_tab:
pci00   DW OFFSET pci_error
pci01   DW OFFSET pci_inst_check
pci02   DW OFFSET pci_find_device
pci03   DW OFFSET pci_find_class
pci04   DW OFFSET pci_error
pci05   DW OFFSET pci_error
pci06   DW OFFSET pci_error
pci07   DW OFFSET pci_error
pci08   DW OFFSET pci_read_byte
pci09   DW OFFSET pci_read_word
pci0A   DW OFFSET pci_read_dword
pci0B   DW OFFSET pci_write_byte
pci0C   DW OFFSET pci_write_word
pci0D   DW OFFSET pci_write_dword
pci0E   DW OFFSET pci_error
pci0F   DW OFFSET pci_error

bios_pci_int    Proc far
    movzx bx,al
    cmp bx,10h
    jnc bios_pci_failed
;
    add bx,bx
    call word ptr cs:[bx].pci_int_tab
    retf32

bios_pci_failed:
    or byte ptr [ebp].trap_eflags,1
    retf32
bios_pci_int    Endp    

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
    mov di,OFFSET pcid_func_arr
    mov cx,8

spdInitFunc:
    mov es:[di].pcif_vendor_dev,-1
    mov es:[di].pcif_bridge,0
    mov es:[di].pcif_class,0
    mov es:[di].pcif_interface,0
    mov es:[di].pcif_used,0
    mov es:[di].pcif_pin,0
    mov es:[di].pcif_irq,0
    mov es:[di].pcif_msi,0
    mov es:[di].pcif_msi_core,0
    mov es:[di].pcif_msix,0
    mov es:[di].pcif_msi_count,0
    mov es:[di].pcif_msix_irq_sel,0
    mov es:[di].pcif_msix_data_sel,0
    mov es:[di].pcif_msix_count,0
    mov es:[di].pcif_acpi_index,-1
    mov es:[di].pcif_acpi_name,0
    add di,SIZE pci_func_struc    
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
    mov es:[di].pcif_class,ax
;
    mov cl,PCI_progIF
    ReadPciByte
    mov es:[di].pcif_interface,al
;
    mov cl,PCI_interrupt_pin
    ReadPciByte
    mov es:[di].pcif_pin,al
;
    mov cl,PCI_interrupt_line
    ReadPciByte
    mov es:[di].pcif_irq,al
;
    mov al,5
    FindPciCapability
    jc spMsiDone
;
    add al,2
    mov es:[di].pcif_msi,al
;
    mov cl,al
    ReadPciWord
;
    mov cl,al
    shr cl,1
    and cl,3
    mov al,1
    shl al,cl
    mov es:[di].pcif_msi_count,al

spMsiDone:
    mov al,11h
    FindPciCapability
    jc spMsiXDone
;
    add al,2
    mov es:[di].pcif_msix,al
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
    mov es:[di].pcif_msix_count,ax
;
    push es
    push bx
    push cx
;
    mov cx,ax
    movzx eax,ax
    shl eax,2
    AllocateSmallGlobalMem
;
    xor bx,bx

spMsiXInit:
    mov ax,-1
    mov es:[bx],ax
    xor ax,ax
    mov es:[bx+2],ax
;
    add bx,2
    sub cx,1
    jnz spMsiXInit
;
    mov ax,es
;
    pop cx
    pop bx
    pop es
    mov es:[di].pcif_msix_irq_sel,ax

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
    mov es:[di].pcif_bridge,si
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
    xor si,si
    mov es,si
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
    mov di,OFFSET pcib_device_arr
    mov cx,32
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
    mov ax,SEG data
    mov ds,ax
;
    xor bh,bh
    call ScanPciBus
;
    ret
DetectDevices  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckAcpiBuses
;
;           DESCRIPTION:    Check for additional ACPI buses
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckAcpiBuses    Proc near
    mov ax,SEG data
    mov ds,ax  
    mov ax,acpi_code_sel
    verr ax
    jnz cabDone
;
    xor bp,bp
    xor bl,bl

cabRetry:    
    xor eax,eax

cabLoop:
    GetAcpiPciDeviceInfo
    jc cabCheck
;
    movzx esi,bh
    mov dx,ds:[2*esi].pci_bus_arr
    or dx,dx
    jnz cabNext
;
    cmp bx,bp
    jbe cabNext
;
    mov ds:[2*esi].pci_bus_arr,-1
    
cabNext:
    inc eax
    jmp cabLoop

cabCheck:
    mov bx,bp

cabCheckLoop:
    movzx esi,bh
    mov dx,ds:[2*esi].pci_bus_arr
    cmp dx,-1
    jne cabCheckNext
;
    mov bp,bx

cabClearLoop:
    movzx esi,bh
    mov dx,ds:[2*esi].pci_bus_arr
    cmp dx,-1
    jne cabClearNext
;
    mov ds:[2*esi].pci_bus_arr,0

cabClearNext:
    inc bh
    or bh,bh
    jnz cabClearLoop
;
    mov bx,bp
    call ScanPciBus
    inc bp
    jmp cabRetry

cabCheckNext:
    inc bh
    or bh,bh
    jnz cabCheckLoop
    
cabDone:
    ret
CheckAcpiBuses   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateAcpi
;
;           DESCRIPTION:    Update device with ACPI info
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateAcpi    Proc near
    mov ax,SEG data
    mov ds,ax  
    mov ax,acpi_code_sel
    verr ax
    jnz uaDone
;    
    xor eax,eax

uaLoop:
    GetAcpiPciDeviceInfo
    jc uaDone
;
    movzx esi,bh
    mov dx,ds:[2*esi].pci_bus_arr
    or dx,dx
    jz uaNext
;
    mov es,dx
    cmp bl,20h
    jae uaNext
;
    movzx esi,bl
    mov dx,es:[2*esi].pcib_device_arr
    or dx,dx
    jz uaNext
;
    mov es,dx
    cmp ch,8
    jae uaNext
;
    movzx esi,ch
    shl esi,7
    mov edx,es:[esi].pcif_acpi_index
    cmp edx,-1
    jz uaFirst
;
    mov dl,es:[esi].pcif_acpi_name
    or dl,dl
    jnz uaNext

uaFirst:
    mov es:[esi].pcif_acpi_index,eax 
;
    lea edi,[esi].pcif_acpi_name
    GetAcpiPciDeviceName
;
    push eax
    movzx edx,es:[esi].pcif_pin
    or dl,dl
    jz uaIrqDone
;
    dec edx
    GetAcpiPciDeviceIrq
    mov es:[esi].pcif_irq,al

uaIrqDone:
    pop eax
    
uaNext:
    inc eax
    jmp uaLoop
    
uaDone:
    ret
UpdateAcpi   Endp

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

init_pci_thread_name DB 'Init PCI', 0

init_pci_thread Proc far
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:pci_init_hooks
    or cx,cx
    je hook_thread_done
;
    mov bx,OFFSET pci_init_hook_arr

hook_thread_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    loop hook_thread_loop

hook_thread_done:
    ret
init_pci_thread Endp
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
    mov cx,20

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
    retf32
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
    retf32
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
    retf32
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
    retf32
uacpi_enable_io   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiReadPciByte
;
;       DESCRIPTION:    Read PCI byte
;
;       PARAMETERS:     EBX 			Register
;
;       RETURNS:        AL			Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_read_pci_byte_name DB 'uACPI Read PCI Byte', 0

uacpi_read_pci_byte   PROC far
    push ds
    push ebx
    push edx
;
    mov ax,SEG data
    mov ds,ax
;    
    mov eax,ebx
    and al,0FCh
    mov dx,0CF8h
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    and bl,3
    or dl,bl
    in al,dx
    ReleaseSpinlock ds:pci_spinlock
;
    pop edx
    pop ebx
    pop ds
    retf32
uacpi_read_pci_byte    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiReadPciWord
;
;       DESCRIPTION:    Read PCI word
;
;       PARAMETERS:     EBX 			Register
;
;       RETURNS:        AX			Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_read_pci_word_name DB 'uACPI Read PCI Word', 0

uacpi_read_pci_word   PROC far
    push ds
    push ebx
    push edx
;
    mov ax,SEG data
    mov ds,ax
;
    mov eax,ebx
    and al,0FCh
    mov dx,0CF8h
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    and bl,2
    or dl,bl
    in ax,dx
    ReleaseSpinlock ds:pci_spinlock
;
    pop edx
    pop ebx
    pop ds
    retf32
uacpi_read_pci_word    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiReadPciDword
;
;       DESCRIPTION:    Read PCI dword
;
;       PARAMETERS:     EBX 			Register
;
;       RETURNS:        EAX			Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_read_pci_dword_name DB 'uACPI Read PCI Dword', 0

uacpi_read_pci_dword   PROC far
    push ds
    push edx
;
    mov ax,SEG data
    mov ds,ax
;
    mov eax,ebx
    and al,0FCh
    mov dx,0CF8h
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    in eax,dx
    ReleaseSpinlock ds:pci_spinlock
;
    pop edx
    pop ds
    retf32
uacpi_read_pci_dword    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiWritePciByte
;
;       DESCRIPTION:    Read PCI byte
;
;       PARAMETERS:     EBX 			Register
;		        AL			Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_write_pci_byte_name DB 'uACPI Write PCI Byte', 0

uacpi_write_pci_byte   PROC far
    push ds
    push ebx
    push edx
;
    mov dx,SEG data
    mov ds,dx
;
    push eax
    mov eax,ebx
    and al,0FCh
    mov dx,0CF8h
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    pop eax
;
    mov dx,0CFCh
    and bl,3
    or dl,bl
    out dx,al
    ReleaseSpinlock ds:pci_spinlock
;
    pop edx
    pop ebx
    pop ds
    retf32
uacpi_write_pci_byte    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiWritePciWord
;
;       DESCRIPTION:    Read PCI word
;
;       PARAMETERS:     EBX 			Register
;		        AX			Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_write_pci_word_name DB 'uACPI Write PCI Word', 0

uacpi_write_pci_word   PROC far
    push ds
    push ebx
    push edx
;
    mov dx,SEG data
    mov ds,dx
;
    push eax
    mov eax,ebx
    and al,0FCh
    mov dx,0CF8h
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    pop eax
;
    mov dx,0CFCh
    and bl,2
    or dl,bl
    out dx,ax
    ReleaseSpinlock ds:pci_spinlock
;
    pop edx
    pop ebx
    pop ds
    retf32
uacpi_write_pci_word    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UacpiWritePciDword
;
;       DESCRIPTION:    Read PCI dword
;
;       PARAMETERS:     EBX 			Register
;			EAX			Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uacpi_write_pci_dword_name DB 'uACPI Write PCI Dword', 0

uacpi_write_pci_dword   PROC far
    push ds
    push ebx
    push edx
;
    mov dx,SEG data
    mov ds,dx
;
    push eax
    mov eax,ebx
    and al,0FCh
    mov dx,0CF8h
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    pop eax
;
    mov dx,0CFCh
    out dx,eax
    ReleaseSpinlock ds:pci_spinlock
;
    pop edx
    pop ebx
    pop ds
    retf32
uacpi_write_pci_dword    Endp

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
    mov esi,OFFSET uacpi_read_pci_byte
    mov edi,OFFSET uacpi_read_pci_byte_name
    xor cl,cl
    mov ax,uacpi_read_pci_byte_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET uacpi_read_pci_word
    mov edi,OFFSET uacpi_read_pci_word_name
    xor cl,cl
    mov ax,uacpi_read_pci_word_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET uacpi_read_pci_dword
    mov edi,OFFSET uacpi_read_pci_dword_name
    xor cl,cl
    mov ax,uacpi_read_pci_dword_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET uacpi_write_pci_byte
    mov edi,OFFSET uacpi_write_pci_byte_name
    xor cl,cl
    mov ax,uacpi_write_pci_byte_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET uacpi_write_pci_word
    mov edi,OFFSET uacpi_write_pci_word_name
    xor cl,cl
    mov ax,uacpi_write_pci_word_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET uacpi_write_pci_dword
    mov edi,OFFSET uacpi_write_pci_dword_name
    xor cl,cl
    mov ax,uacpi_write_pci_dword_nr
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
    mov ax,3Eh
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
    CreateIoServerProcess
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
    call CheckAcpiBuses
    call UpdateAcpi
    call LoadAcpiServer
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET init_pci_thread
    mov di,OFFSET init_pci_thread_name
    mov ax,3
    mov cx,stack0_size
    CreateThread
;
    popad
    pop es
    pop ds
    retf32
init_pci    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciBus
;
;           DESCRIPTION:    Get PCI bus
;
;           PARAMETERS:     BH          Bus
;
;           RETURNS:        BH          Bus
;                           BL          Device
;                           CH          Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_bus_name DB 'Get Pci Bus',0

get_pci_bus     Proc far    
    push ds
    push esi
;
    mov si,SEG data
    mov ds,si
    movzx esi,bh
    mov si,ds:[2*esi].pci_bus_arr
    or si,si
    stc
    jz gpbDone
;
    mov ds,si
    mov bh,ds:pcib_owner_bus
    mov bl,ds:pcib_owner_dev
    mov ch,ds:pcib_owner_func
    clc
    
gpbDone:
    pop esi
    pop ds
    retf32
get_pci_bus     Endp
      
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

init    Proc far
    mov bx,SEG data
    mov ds,bx
    mov es,bx
;
    mov ds:pci_init_hooks,0
    InitSpinlock ds:pci_spinlock
;
    mov di,OFFSET pci_bus_arr
    mov cx,256
    xor ax,ax
    rep stosw
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET init_pci
    HookInitTasking
;
    mov esi,OFFSET hook_init_pci
    mov edi,OFFSET hook_init_pci_name
    mov ax,hook_init_pci_nr
    RegisterOsGate
;
    mov esi,OFFSET bios_pci_int
    mov edi,OFFSET bios_pci_int_name
    xor cl,cl
    mov ax,bios_pci_int_nr
    RegisterOsGate
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
    mov esi,OFFSET find_pci_class_interface
    mov edi,OFFSET find_pci_class_interface_name
    xor cl,cl
    mov ax,find_pci_class_interface_nr
    RegisterOsGate
;
    mov esi,OFFSET find_pci_class
    mov edi,OFFSET find_pci_class_name
    xor cl,cl
    mov ax,find_pci_class_nr
    RegisterOsGate
;
    mov esi,OFFSET find_pci_device
    mov edi,OFFSET find_pci_device_name
    xor cl,cl
    mov ax,find_pci_device_nr
    RegisterOsGate
;
    mov esi,OFFSET find_pci_cap
    mov edi,OFFSET find_pci_cap_name
    xor cl,cl
    mov ax,find_pci_cap_nr
    RegisterOsGate
;
    mov esi,OFFSET pci_power_on
    mov edi,OFFSET pci_power_on_name
    xor cl,cl
    mov ax,pci_power_on_nr
    RegisterOsGate
;
    mov esi,OFFSET set_pci_device_name
    mov edi,OFFSET set_pci_device_name_name
    xor cl,cl
    mov ax,set_pci_device_name_nr
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
    mov esi,OFFSET get_pci_bus
    mov edi,OFFSET get_pci_bus_name
    xor dx,dx
    mov ax,get_pci_bus_nr
    RegisterBimodalUserGate
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
    mov ebx,OFFSET get_pci_device_name16
    mov esi,OFFSET get_pci_device_name32
    mov edi,OFFSET get_pci_device_name
    mov dx,virt_es_in
    mov ax,get_pci_device_name_nr
    RegisterUserGate
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
    call DetectDevices
    clc
    ret
init    Endp

code    ENDS

    END init
