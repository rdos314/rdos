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
; bios.ASM
; PCI BIOS support
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

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use32 'CODE'

    assume cs:code

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

    extern GetPciBusCount:near

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
pci00   DD OFFSET pci_error
pci01   DD OFFSET pci_inst_check
pci02   DD OFFSET pci_find_device
pci03   DD OFFSET pci_find_class
pci04   DD OFFSET pci_error
pci05   DD OFFSET pci_error
pci06   DD OFFSET pci_error
pci07   DD OFFSET pci_error
pci08   DD OFFSET pci_read_byte
pci09   DD OFFSET pci_read_word
pci0A   DD OFFSET pci_read_dword
pci0B   DD OFFSET pci_write_byte
pci0C   DD OFFSET pci_write_word
pci0D   DD OFFSET pci_write_dword
pci0E   DD OFFSET pci_error
pci0F   DD OFFSET pci_error

bios_pci_int    Proc far
    movzx bx,al
    cmp bx,10h
    jnc bios_pci_failed
;
    call dword ptr cs:[4*ebx].pci_int_tab
    ret

bios_pci_failed:
    or byte ptr [ebp].trap_eflags,1
    ret
bios_pci_int    Endp    
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_bios
;
;           DESCRIPTION:    INIT PCI BIOS 
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_bios
    
init_bios    Proc near
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET bios_pci_int
    mov edi,OFFSET bios_pci_int_name
    xor cl,cl
    mov ax,bios_pci_int_nr
    RegisterOsGate
    ret
init_bios    Endp

code    ENDS

    END
