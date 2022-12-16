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
INCLUDE pci.inc
INCLUDE ..\os\core.inc

MAX_PCI_DEVICES = 256


; this structure should be 128 bytes!

pci_func_struc   STRUC

pcif_vendor_dev DD ?
pcif_bridge     DW ?
pcif_class      DW ?
pcif_pin        DB ?
pcif_irq        DB ?
pcif_acpi_index DD ?
pcif_acpi_name  DB 114 DUP(?)

pci_func_struc   ENDS

pci_device_struc   STRUC

pcid_func_arr       DB 8*128 DUP(?)

pcid_dev_id         DB ?
pcid_bus_id         DB ?

pci_device_struc   ENDS

pci_bus_struc  STRUC

pcib_device_arr    DW 32 DUP(?)

pcib_bus_id        DB ?

pci_bus_struc  ENDS

msi_struc       STRUC

msi_bus         DB ?
msi_device      DB ?
msi_function    DB ?
msi_reg         DB ?
msi_int_base    DB ?
msi_int_count   DB ?
msi_core        DW ?

msi_struc       ENDS

data    SEGMENT byte public 'DATA'

pci_spinlock            spinlock_typ <>

pci_msi_arr             DD 256 DUP(?,?)

pci_init_hooks          DW ?
pci_init_hook_arr       DD 32 DUP(?,?)

pci_device_arr          DD MAX_PCI_DEVICES DUP(?,?)

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
    push es
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
    mov es,ax
    movzx esi,bl
    mov ax,es:[2*esi].pcib_device_arr
    or ax,ax
    jz gpiFail
;
    mov es,ax
    movzx esi,ch
    shl esi,7
    movzx ax,es:[esi].pcif_irq
    or al,al
    jz gpiFail
;
    clc
    jmp gpiDone

gpiFail:
    xor ax,ax
    stc

gpiDone:
    pop esi
    pop es
    pop ds
    retf32
get_pci_irq  Endp

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
;           NAME:           FindPciClass
;
;           DESCRIPTION:    Find PCI class
;
;           PARAMETERS:         BH          Class
;                           BL          Sub class
;                           CH          Interface
;                           AX          Device number
;
;           RETURNS:        NC          Success
;                           BH          Bus
;                           BL          Device
;               CH      Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_pci_class_name     DB 'Find PCI Class',0

find_pci_class  Proc far
    push ds
    push eax
    push dx
    push si
    push di
;
    mov di,ax
    movzx eax,bx
    shl eax,16
    mov ah,ch
    mov ebx,eax
;
    mov si,SEG data
    mov ds,si
    mov si,OFFSET pci_device_arr
    mov cx,MAX_PCI_DEVICES - 1

find_pci_class_loop:
    mov eax,ds:[si+4]
    mov dx,0CF8h
    mov al,8
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    in eax,dx
    ReleaseSpinlock ds:pci_spinlock
    xor al,al
    cmp eax,ebx
    jne find_pci_class_next 
;
    or di,di
    jz find_pci_class_ok
;
    sub di,1

find_pci_class_next:
    add si,8
    loop find_pci_class_loop
;
    stc
    jmp find_pci_class_done

find_pci_class_ok:
    mov ebx,ds:[si+5]
    shr bl,3
;
    mov cx,ds:[si+4]
    and cx,700h
    clc

find_pci_class_done:
    pop di
    pop si
    pop dx
    pop eax
    pop ds
    retf32
find_pci_class  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindPciClassAll
;
;           DESCRIPTION:    Find PCI class, ignore interface
;
;           PARAMETERS:         BH          Class
;                           BL          Sub class
;                           AX          Device number
;
;           RETURNS:        NC          Success
;                           BH          Bus
;                           BL          Device
;               CH      Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_pci_class_all_name DB 'Find PCI Class All',0

find_pci_class_all      Proc far
    push ds
    push eax
    push dx
    push si
    push di
;
    mov di,ax
;
    mov si,SEG data
    mov ds,si
    mov si,OFFSET pci_device_arr
    mov cx,MAX_PCI_DEVICES - 1

find_pci_class_all_loop:
    mov eax,ds:[si+4]
    mov dx,0CF8h
    mov al,8
    RequestSpinlock ds:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    in eax,dx
    ReleaseSpinlock ds:pci_spinlock
    shr eax,16
    cmp ax,bx
    jne find_pci_class_all_next     
;
    or di,di
    jz find_pci_class_all_ok
;
    sub di,1

find_pci_class_all_next:
    add si,8
    loop find_pci_class_all_loop
;
    stc
    jmp find_pci_class_all_done

find_pci_class_all_ok:
    mov ebx,ds:[si+5]
    shr bl,3
;
    mov cx,ds:[si+4]
    and cx,700h
    clc

find_pci_class_all_done:
    pop di
    pop si
    pop dx
    pop eax
    pop ds
    retf32
find_pci_class_all      Endp

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
    retf32
find_pci_cap    Endp

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
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pci_power_on_name       DB 'PCI Power On',0

pci_power_on    Proc far
    push eax
    push edx
;
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
    pop edx
    pop eax
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
    push ax
;    
    mov al,5
    FindPciCapability
    jc gpmDone
;
    mov cl,al
    add cl,2
    ReadPciWord
;
    push cx
    mov cl,al
    shr cl,1
    and cl,3
    mov dl,1
    shl dl,cl
    pop cx
    clc

gpmDone:       
    pop ax 
    retf32
get_pci_msi     Endp

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
    push ax
    push cx
    push edx
    push si
;    
    mov si,SEG data
    mov ds,si
    movzx si,al
    shl si,3
    add si,OFFSET pci_msi_arr
    mov dh,dl

spmEntryLoop:
    mov ds:[si].msi_bus,bh
    mov ds:[si].msi_device,bl
    mov ds:[si].msi_function,ch
    mov ds:[si].msi_reg,cl
    mov ds:[si].msi_int_base,al
    mov ds:[si].msi_int_count,dl
    mov ds:[si].msi_core,0
    add si,8
    sub dh,1
    jnz spmEntryLoop
;
    mov dh,al
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
;
    ReadPciWord
    and al,NOT 70h
    or al,dl
    or al,1
    WritePciWord
;
    test ax,100h
    jnz spmVector
;
    test ax,80h
    jnz spm64

spm32:
    mov al,dh
    add cl,2
;
    RegisterMsi
    push ax
; 
    mov eax,edx
    WritePciDword
;
    pop ax
    add cl,4    
    WritePciWord
    jmp spmDone

spm64:
    mov al,dh
    add cl,2
;    
    RegisterMsi
    push ax
;
    mov eax,edx
    WritePciDword
;
    add cl,4
    xor eax,eax
    WritePciDword
;    
    pop ax
    add cl,4    
    WritePciWord
    jmp spmDone

spmVector:
    mov al,dh
    add cl,2
;    
    RegisterMsi
    push ax
;
    mov eax,edx
    WritePciDword
;
    add cl,4
    xor eax,eax
    WritePciDword
;    
    pop ax
    add cl,4    
    WritePciWord

spmDone:
    pop si
    pop edx
    pop cx
    pop ax
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
;                           FS		Core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_pci_msi_name DB 'Move PCI MSI',0

move_pci_msi     Proc far    
    push ds
    pushad
;    
    mov si,SEG data
    mov ds,si
    movzx si,al
    shl si,3
    add si,OFFSET pci_msi_arr
;
    mov bh,ds:[si].msi_bus
    mov bl,ds:[si].msi_device
    mov ch,ds:[si].msi_function
    mov cl,ds:[si].msi_reg
    or cl,cl
    jz mpmDone
;
    mov ax,fs:cs_id
    mov ds:[si].msi_core,ax
    mov edx,fs:cs_apic
    shl edx,12
;
    ReadPciWord
    WritePciWord
;
    add cl,2
    ReadPciDword
    and eax,0FFF00000h
    or eax,edx
    WritePciDword

mpmDone:
    popad
    pop ds
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
;           RETURNS:        CL          Int count
;                           AL          Base int
;                           DX          Core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_msi_info_name DB 'Get PCI MSI Info',0

get_pci_msi_info     Proc far    
    push ds
    push si
;    
    mov si,SEG data
    mov ds,si
    movzx si,al
    shl si,3
    add si,OFFSET pci_msi_arr
    mov al,ds:[si].msi_reg
    or al,al
    stc
    jz gpmiDone
;
    mov al,ds:[si].msi_int_base
    mov cl,ds:[si].msi_int_count
    mov dx,ds:[si].msi_core
    clc

gpmiDone:
    pop si
    pop ds
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
;                           CL          MSI register base
;                           DL          Requested vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_msix_name DB 'Get PCI MSI-X',0

get_pci_msix     Proc far    
    push ax
;    
    mov al,11h
    FindPciCapability
    jc gpmxDone
;
    mov cl,al
    add cl,2
    ReadPciWord
    mov dl,al
    inc dl
    clc

gpmxDone:       
    pop ax 
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
;                           CL          MSI register base
;
;           RETURNS:        ES          Selector for message entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_pci_msix_name DB 'Enable PCI MSI-X',0

enable_pci_msix     Proc far    
    push eax
    push ebx
    push cx
    push edx
    push si
    push edi
;
    push cx
    mov eax,1000h
    AllocateBigLinear
    pop cx
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
    and eax,0E00h
    add edx,eax
;    
    AllocateGdt
    mov cx,si
    and cx,1FFh
    inc cx
    shl cx,3
    CreateDataSelector16
    mov es,bx
;
    pop edi
    pop si
    pop edx
    pop cx
    pop ebx
    pop eax
    retf32
enable_pci_msix     Endp

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
;                           ES          Selector for message entries
;                           DL          Entry #
;                           AL          Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_pci_msix_entry_name DB 'Setup PCI MSI-X Entry',0

setup_pci_msix_entry     Proc far    
    push eax
    push edx
    push esi
;    
    movzx si,dl
    shl si,4
;
    RegisterMsi
    mov es:[si],edx
    movzx eax,ax
    mov es:[si+8],eax
;
    xor eax,eax
    mov es:[si+4],eax
    mov es:[si+12],eax    
;
    pop esi
    pop edx
    pop eax
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
    FindPciClass
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
;           PARAMETERS:     BH		Bus #
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
    mov es:[di].pcif_pin,0
    mov es:[di].pcif_irq,0
    mov es:[di].pcif_acpi_index,0
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
    mov cl,PCI_interrupt_pin
    ReadPciByte
    mov es:[di].pcif_pin,al
;
    mov cl,PCI_interrupt_line
    ReadPciByte
    mov es:[di].pcif_irq,al
;
    mov cl,PCI_header_type
    ReadPciByte
    mov ah,al
    and al,7Fh
    cmp al,1
    jne spdFuncNext
;
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
    popad

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
;           PARAMETERS:     BH		Bus #
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
    mov es,ax
;
    mov di,OFFSET pci_bus_arr
    mov cx,256
    xor ax,ax
    rep stosw
;
    xor bh,bh
    call ScanPciBus
;
    ret
DetectDevices  Endp

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
    mov es:[esi].pcif_acpi_index,eax 
;
    lea edi,[esi].pcif_acpi_name
    GetAcpiPciDeviceName
;
    push eax
    movzx edx,es:[esi].pcif_pin
    dec edx
    GetAcpiPciDeviceIrq
    mov es:[esi].pcif_irq,al
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
;           NAME:           CopyLegacy
;
;           DESCRIPTION:    Copy to legacy struc (should be removed)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyLegacy Proc near
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    mov di,OFFSET pci_device_arr
    xor bh,bh

clBusloop:
    movzx si,bh
    add si,si
    mov ax,ds:[si].pci_bus_arr
    or ax,ax
    jz clBusNext
;
    push si
    xor bl,bl
    mov es,ax

clDevLoop:
    movzx si,bl
    add si,si
    mov ax,es:[si].pcib_device_arr
    or ax,ax
    jz clDevNext
;
    push si
    xor ch,ch
    mov fs,ax
    mov si,OFFSET pcid_func_arr

clFuncLoop:
    mov eax,fs:[si].pcif_vendor_dev
    cmp eax,-1
    je clFuncNext
;
    mov ds:[edi],eax
    add edi,4
;
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    xor al,al
    mov ds:[edi],eax
    add edi,4

clFuncNext:
    add si,SIZE pci_func_struc
    inc ch
    cmp ch,8
    jne clFuncLoop
;
    pop si

clDevNext:
    inc bl
    cmp bl,32
    jne clDevLoop    
;
    pop si

clBusNext:
    inc bh
    or bh,bh
    jnz clBusLoop
;
    ret
CopyLegacy Endp

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
    call UpdateAcpi
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
    mov cx,2 * MAX_PCI_DEVICES
    mov eax,-1
    mov di,OFFSET pci_device_arr
    rep stosd
;
    mov di,OFFSET pci_msi_arr
    xor eax,eax
    mov cx,2 * 256
    rep stosd
;
    mov ds:pci_init_hooks,0
    InitSpinlock ds:pci_spinlock
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
    mov esi,OFFSET find_pci_class
    mov edi,OFFSET find_pci_class_name
    xor cl,cl
    mov ax,find_pci_class_nr
    RegisterOsGate
;
    mov esi,OFFSET find_pci_class_all
    mov edi,OFFSET find_pci_class_all_name
    xor cl,cl
    mov ax,find_pci_class_all_nr
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
    mov esi,OFFSET get_pci_msi
    mov edi,OFFSET get_pci_msi_name
    xor cl,cl
    mov ax,get_pci_msi_nr
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
    mov esi,OFFSET get_pci_msix
    mov edi,OFFSET get_pci_msix_name
    xor cl,cl
    mov ax,get_pci_msix_nr
    RegisterOsGate
;
    mov esi,OFFSET enable_pci_msix
    mov edi,OFFSET enable_pci_msix_name
    xor cl,cl
    mov ax,enable_pci_msix_nr
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
    xor cl,cl
    mov ax,get_pci_irq_nr
    RegisterOsGate
;
    call DetectDevices
    call CopyLegacy
    clc
    ret
init    Endp

code    ENDS

    END init
