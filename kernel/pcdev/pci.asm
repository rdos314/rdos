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

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE pci.inc

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

MAX_PCI_DEVICES = 256

pci_struc   STRUC

pci_vendor    DW ?
pci_device    DW ?
pci_id        DD ?

pci_struc   ENDS

ext_pci_struc  STRUC

epci_vendor_id  DW ?
epci_device_id  DW ?
epci_class      DW ?
epci_bus        DB ?
epci_device     DB ?
epci_function   DB ?
epci_pin        DB ?
epci_irq        DB ?

epci_acpi_index DD ?
epci_acpi_name  DB 128 DUP(?)

ext_pci_struc  ENDS

data    SEGMENT byte public 'DATA'

pci_spinlock        spinlock_typ <>

pci_init_hooks          DW ?
pci_init_hook_arr       DD 32 DUP(?,?)

pci_device_arr      DD MAX_PCI_DEVICES DUP(?,?)

ext_pci_dev_count   DW ?    
ext_pci_dev_arr     DW MAX_PCI_DEVICES DUP(?)

data    ENDS

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
    push dx
    push si
;
    mov dx,SEG data    
    mov ds,dx
    mov si,OFFSET ext_pci_dev_arr
    mov dx,ds:ext_pci_dev_count
    or dx,dx    
    jz gpiNoAcpi

gpiLoop:
    mov es,ds:[si]
    cmp bh,es:epci_bus
    jne gpiNext
;
    cmp bl,es:epci_device
    jne gpiNext
;
    cmp ch,es:epci_function
    je gpiOk

gpiNext:
    add si,2
    sub dx,1
    jnz gpiLoop

gpiFail:
    stc
    jmp gpiDone

gpiNoAcpi:
    mov cl,PCI_interrupt_line
    ReadPciByte
    clc
    jmp gpiDone

gpiOk:
    mov al,es:epci_pin
    or al,al
    jz gpiFail
;        
    mov al,es:epci_irq
    clc

gpiDone:
    pop si
    pop dx
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
;           PARAMETERS:         CX          Device ID
;                           DX          Vendor ID
;                           AX          Device number
;
;           RETURNS:        NC          Success
;                           BH          Bus
;               CH      Function
;                           BL          Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_pci_device_name    DB 'Find PCI Device',0

find_pci_device Proc far
    push ds
    push eax
    push dx
    push si
    push di
;       
    push ecx
;
    mov di,SEG data
    mov ds,di
    mov si,OFFSET pci_device_arr
;
    mov di,ax
    mov bx,cx
    shl ebx,16
    mov bx,dx

    mov cx,MAX_PCI_DEVICES - 1
    
find_pci_device_loop:
    lodsd
    cmp eax,ebx
    jne find_pci_device_next    
;
    mov eax,ds:[si+1]
    shr al,3
    cmp ax,di
    jae find_pci_device_ok

find_pci_device_next:
    add esi,4
    loop find_pci_device_loop
;
    stc
    pop ecx
    jmp find_pci_device_done

find_pci_device_ok:
    mov ebx,ds:[si+1]
    shr bl,3
;
    mov cx,ds:[si]
    and cx,700h
    add sp,4
    clc

find_pci_device_done:
    pop di
    pop si
    pop dx
    pop eax
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
;           NAME:           bios_pci_int
;
;           DESCRIPTION:    Handling BIOS PCI int (0B1h, int 1Ah)
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bios_pci_int_name DB 'BIOS PCI int',0

pci_error       Proc near
    int 3
    or byte ptr [bp].vm_eflags,1
    ret
pci_error       Endp

pci_inst_check  Proc near
    mov edx,20494350h
    xor edi,edi
    call GetPciBusCount
    mov cl,al
    mov eax,[bp].vm_eax
    xor ax,ax
    mov word ptr [bp].vm_ebx,210h
    and byte ptr [bp].vm_eflags,NOT 1
    ret
pci_inst_check  Endp

pci_find_device Proc near
    mov ax,si
    FindPciDevice
    jc pci_find_device_fail
;
    shl bl,3
    xor ax,ax
    mov [bp].vm_ebx,bx
    and byte ptr [bp].vm_eflags,NOT 1
    ret

pci_find_device_fail:
    or byte ptr [bp].vm_eflags,1    
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
    mov [bp].vm_ebx,bx
    and byte ptr [bp].vm_eflags,NOT 1
    ret

pci_find_fail:
    or byte ptr [bp].vm_eflags,1    
    mov ax,8600h
    ret
pci_find_class  Endp

pci_read_byte   Proc near
    mov cx,di
    mov bx,[bp].vm_ebx
    mov ch,bl
    and ch,7
    shr bl,3
    ReadPciByte
    mov cl,al
    xor ax,ax
    and byte ptr [bp].vm_eflags,NOT 1
    ret
pci_read_byte   Endp

pci_write_byte  Proc near
    mov al,cl
    mov cx,di
    mov bx,[bp].vm_ebx
    mov ch,bl
    and ch,7
    shr bl,3
    WritePciByte
    xor ax,ax
    and byte ptr [bp].vm_eflags,NOT 1
    ret
pci_write_byte  Endp

pci_read_word   Proc near
    mov cx,di
    mov bx,[bp].vm_ebx
    mov ch,bl
    and ch,7
    shr bl,3
    ReadPciWord
    mov cx,ax
    xor ax,ax
    and byte ptr [bp].vm_eflags,NOT 1
    ret
pci_read_word   Endp

pci_write_word  Proc near
    mov ax,cx
    mov cx,di
    mov bx,[bp].vm_ebx
    mov ch,bl
    and ch,7
    shr bl,3
    WritePciWord
    xor ax,ax
    and byte ptr [bp].vm_eflags,NOT 1
    ret
pci_write_word  Endp

pci_read_dword  Proc near
    mov cx,di
    mov bx,[bp].vm_ebx
    mov ch,bl
    and ch,7
    shr bl,3
    ReadPciDword
    mov ecx,eax
    xor ax,ax
    and byte ptr [bp].vm_eflags,NOT 1
    ret
pci_read_dword  Endp

pci_write_dword Proc near
    mov eax,ecx
    mov cx,di
    mov bx,[bp].vm_ebx
    mov ch,bl
    and ch,7
    shr bl,3
    WritePciDword
    xor ax,ax
    and byte ptr [bp].vm_eflags,NOT 1
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
    or byte ptr [bp].vm_eflags,1
    retf32
bios_pci_int    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_pci_devices
;
;           DESCRIPTION:    Init PCI devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_pci_devices    Proc near
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET pci_device_arr

    mov ecx,80000000h

init_pci_device_loop:
    mov eax,ecx
    mov dx,0CF8h
    and al,0FCh
    RequestSpinlock es:pci_spinlock
    out dx,eax
    mov dx,0CFCh
    in eax,dx
    ReleaseSpinlock es:pci_spinlock
;       
    or eax,eax
    jz init_pci_next
;   
    cmp eax,-1
    je init_pci_next
;   
    stosd
    mov eax,ecx
    stosd

init_pci_next:
    cmp di,8 * MAX_PCI_DEVICES
    je init_pci_device_done
;
    add ecx,100h
    cmp ecx,81000000h
    jne init_pci_device_loop

init_pci_device_done:   
    ret
init_pci_devices    Endp

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
;           NAME:           AddPciDevice
;
;           DESCRIPTION:    Add PCI device from ACPI
;
;           PARAMETERS:     EAX         ACPI index
;                           BH          Bus
;                           BL          Device
;                           CH          Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPciDevice    Proc near
    push bx
    push cx
    push eax
;    
    mov bp,cx
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    xor al,al
;
    mov si,OFFSET pci_device_arr
    mov di,MAX_PCI_DEVICES

apdLoop:
    mov edx,[si+4]
    cmp eax,edx
    jne apdNext
;
    mov eax,SIZE ext_pci_struc
    AllocateSmallGlobalMem
    mov ax,[si]
    mov es:epci_vendor_id,ax
    mov ax,[si+2]
    mov es:epci_device_id,ax
    mov es:epci_bus,bh
    mov es:epci_device,bl
    mov ax,bp
    mov es:epci_function,ah
    pop eax
;
    push eax    
    mov es:epci_acpi_index,eax    
    mov edi,OFFSET epci_acpi_name
    GetAcpiPciDeviceName
;    
    mov cl,PCI_subclass
    ReadPciByte
    mov dl,al
    mov cl,PCI_classcode
    ReadPciByte
    mov ah,al
    mov al,dl
    mov es:epci_class,ax
;    
    mov cl,PCI_interrupt_pin
    ReadPciByte
    mov es:epci_pin,al
    mov es:epci_irq,0
    or al,al
    jz apdNoInt
;
    pop eax
    push eax
    movzx edx,es:epci_pin
    dec edx
    GetAcpiPciDeviceIrq
    mov es:epci_irq,al

apdNoInt:    
    mov si,OFFSET ext_pci_dev_arr
    mov ax,ds:ext_pci_dev_count
    add ax,ax
    add si,ax
    mov ds:[si],es
    inc ds:ext_pci_dev_count
    jmp apdDone

apdNext: 
    add si,8
    sub di,1
    jnz apdLoop   

apdDone:    
    pop eax
    pop cx
    pop bx
    ret
AddPciDevice    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckPciDevice
;
;           DESCRIPTION:    Check if PCI-device is part of extended struc
;
;           PARAMETERS:     DS:SI       Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckPciDevice    Proc near
    push es
    pushad
;    
    mov bh,ds:[si+2]
    mov ch,ds:[si+1]
    mov bl,ch
    shr bl,3
    and bl,01Fh
    and ch,7    
;
    mov di,OFFSET ext_pci_dev_arr
    mov bp,ds:ext_pci_dev_count
    or bp,bp
    jz cpdDone

cpdLoop:
    mov es,ds:[di]
    cmp bh,es:epci_bus
    jne cpdNext
;
    cmp bl,es:epci_device
    jne cpdNext
;
    cmp ch,es:epci_function
    je cpdDone

cpdNext:
    add di,2
    sub bp,1
    jnz cpdLoop
;    
    mov eax,SIZE ext_pci_struc
    AllocateSmallGlobalMem
    mov ax,[si-4]
    mov es:epci_vendor_id,ax
    mov ax,[si-2]
    mov es:epci_device_id,ax
    mov es:epci_bus,bh
    mov es:epci_device,bl
    mov es:epci_function,ch
    mov es:epci_acpi_index,-1
    mov es:epci_acpi_name,0
;    
    mov cl,PCI_subclass
    ReadPciByte
    mov dl,al
    mov cl,PCI_classcode
    ReadPciByte
    mov ah,al
    mov al,dl
    mov es:epci_class,ax
;    
    mov cl,PCI_interrupt_pin
    ReadPciByte
    mov es:epci_pin,al
    mov es:epci_irq,0
    or al,al
    jz cpdNoInt
;
; should not happen, but fix this later!
;
    mov es:epci_irq,1

cpdNoInt:    
    mov si,OFFSET ext_pci_dev_arr
    mov ax,ds:ext_pci_dev_count
    add ax,ax
    add si,ax
    mov ds:[si],es
    inc ds:ext_pci_dev_count

cpdDone:                
    popad   
    pop es
    ret
CheckPciDevice    Endp    

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
    mov ax,SEG data
    mov ds,ax  
    mov ax,acpi_code_sel
    verr ax
    jnz get_pci_device_done
;    
    xor eax,eax

get_pci_device_loop:
    GetAcpiPciDeviceInfo
    jc get_pci_device_done
;
    call AddPciDevice
    or bh,bh
    jz get_pci_device_next

get_pci_device_bus_loop:
    inc ch
    call AddPciDevice
    cmp ch,7
    jne get_pci_device_bus_loop
    
get_pci_device_next:
    inc eax
    jmp get_pci_device_loop
    
get_pci_device_done:
    mov si,OFFSET pci_device_arr
    mov cx,MAX_PCI_DEVICES    

check_dev_loop:    
    add si,4
    mov eax,ds:[si]
    cmp eax,-1
    je check_dev_done
;
    call CheckPciDevice
    add si,4
    loop check_dev_loop    

check_dev_done:    
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
;           NAME:           GetPciDevName16/32
;
;           DESCRIPTION:    Get PCI device name
;
;           PARAMETERS:     AX          Index
;                           ES:(E)DI    Name buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_dev_name DB 'Get PCI Device Name', 0

get_pci_dev_name16  Proc far
    push ds
    push ax
    push si
    push di
;   
    mov si,SEG data
    mov ds,si
    cmp ax,ds:ext_pci_dev_count
    cmc
    jc gpdn16_done
;
    mov si,ax
    add si,si
    mov ds,ds:[si].ext_pci_dev_arr
    mov si,OFFSET epci_acpi_name

gpdn16_loop:
    lodsb
    stosb
    or al,al
    jnz gpdn16_loop
;
    clc
    
gpdn16_done:
    pop di
    pop si
    pop ax
    pop ds
    retf32
get_pci_dev_name16  Endp

get_pci_dev_name32  Proc far
    push ds
    push ax
    push si
    push edi
;   
    mov si,SEG data
    mov ds,si
    cmp ax,ds:ext_pci_dev_count
    cmc
    jc gpdn32_done
;
    mov si,ax
    add si,si
    mov ds,ds:[si].ext_pci_dev_arr
    mov si,OFFSET epci_acpi_name

gpdn32_loop:
    lodsb
    stos byte ptr es:[edi]
    or al,al
    jnz gpdn32_loop
;
    clc
    
gpdn32_done:
    pop edi
    pop si
    pop ax
    pop ds
    retf32
get_pci_dev_name32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciDevInfo
;
;           DESCRIPTION:    Get PCI device info
;
;           PARAMETERS:     AX          Index
;
;           RETURNS:        BH          Bus
;                           BL          Device
;                           CH          Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_dev_info_name DB 'Get PCI Device Info', 0

get_pci_dev_info    Proc far
    push ds
    push si
;   
    mov si,SEG data
    mov ds,si
    cmp ax,ds:ext_pci_dev_count
    cmc
    jc gpdi_done
;
    mov si,ax
    add si,si
    mov ds,ds:[si].ext_pci_dev_arr
    mov bh,ds:epci_bus
    mov bl,ds:epci_device
    mov ch,ds:epci_function
    clc

gpdi_done:
    pop si
    pop ds    
    retf32
get_pci_dev_info    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciDevVendor
;
;           DESCRIPTION:    Get PCI device vendor & device
;
;           PARAMETERS:     AX          Index
;
;           RETURNS:        AX          Vendor ID
;                           DX          Device ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_dev_vendor_name DB 'Get PCI Device Vendor', 0

get_pci_dev_vendor    Proc far
    push ds
    push si
;   
    mov si,SEG data
    mov ds,si
    cmp ax,ds:ext_pci_dev_count
    cmc
    jc gpdv_done
;
    mov si,ax
    add si,si
    mov ds,ds:[si].ext_pci_dev_arr
    mov ax,ds:epci_vendor_id
    mov dx,ds:epci_device_id
    clc

gpdv_done:
    pop si
    pop ds    
    retf32
get_pci_dev_vendor    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciDevClass
;
;           DESCRIPTION:    Get PCI device class
;
;           PARAMETERS:     AX          Index
;
;           RETURNS:        AH          Class
;                           AL          Sub-class
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_dev_class_name DB 'Get PCI Device Class', 0

get_pci_dev_class    Proc far
    push ds
    push si
;   
    mov si,SEG data
    mov ds,si
    cmp ax,ds:ext_pci_dev_count
    cmc
    jc gpdc_done
;
    mov si,ax
    add si,si
    mov ds,ds:[si].ext_pci_dev_arr
    mov ax,ds:epci_class
    clc

gpdc_done:
    pop si
    pop ds    
    retf32
get_pci_dev_class    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPciDevIrq
;
;           DESCRIPTION:    Get PCI device IRQ
;
;           PARAMETERS:     AX          Index
;
;           RETURNS:        AL          IRQ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_dev_irq_name DB 'Get PCI Device IRQ', 0

get_pci_dev_irq    Proc far
    push ds
    push si
;   
    mov si,SEG data
    mov ds,si
    cmp ax,ds:ext_pci_dev_count
    cmc
    jc gpdirq_done
;
    mov si,ax
    add si,si
    mov ds,ds:[si].ext_pci_dev_arr
    mov al,ds:epci_irq
    clc

gpdirq_done:
    pop si
    pop ds    
    retf32
get_pci_dev_irq    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Test gate
;
;           DESCRIPTION:    Test gate
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_pr_name DB 'Test Gate', 0

test_pr    Proc far
    mov bh,2
    mov bl,0
    mov ch,0
    retf32 
test_pr Endp   

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
    mov ds:pci_init_hooks,0
    mov ds:ext_pci_dev_count,0
    InitSpinlock ds:pci_spinlock
;
    call init_pci_devices
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
    mov ebx,OFFSET get_pci_dev_name16
    mov esi,OFFSET get_pci_dev_name32
    mov edi,OFFSET get_pci_dev_name
    mov dx,virt_es_in
    mov ax,get_pci_device_name_nr
    RegisterUserGate
;
    mov esi,OFFSET get_pci_dev_info
    mov edi,OFFSET get_pci_dev_info_name
    xor dx,dx
    mov ax,get_pci_device_info_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_dev_vendor
    mov edi,OFFSET get_pci_dev_vendor_name
    xor dx,dx
    mov ax,get_pci_device_vendor_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_dev_class
    mov edi,OFFSET get_pci_dev_class_name
    xor dx,dx
    mov ax,get_pci_device_class_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_dev_irq
    mov edi,OFFSET get_pci_dev_irq_name
    xor dx,dx
    mov ax,get_pci_device_irq_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET test_pr
    mov edi,OFFSET test_pr_name
    xor dx,dx
    mov ax,test_gate_nr
;    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pci_irq
    mov edi,OFFSET get_pci_irq_name
    xor cl,cl
    mov ax,get_pci_irq_nr
    RegisterOsGate

init_pci_done:
    clc
    ret
init    Endp

code    ENDS

    END init
