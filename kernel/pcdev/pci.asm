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

GateSize = 16

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc

	.386p

MAX_PCI_DEVICES = 256

data    SEGMENT byte public 'DATA'

pci_device_arr      DD MAX_PCI_DEVICES DUP(?,?)

data    ENDS

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetPciBusCount
;
;		DESCRIPTION:	Determine number of PCI buses
;
;		RETURNS:		AL		Number of buses
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPciBusCount	Proc near
	push ebx
	push ecx
	push dx
;
	mov ebx,80000000h
	mov ecx,80000000h

get_pci_bus_count_loop:
	mov eax,ecx
	mov dx,0CF8h
	and al,0FCh
	cli
	out dx,eax
	mov dx,0CFCh
	in eax,dx
	sti
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
	ret
GetPciBusCount	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadPciByte
;
;		DESCRIPTION:	Read a 8-bit register
;
;		PARAMETERS:		BH		Bus
;						BL 		Device
;						CH		Function
;						CL		Register
;
;		RETURNS:		AL		Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_pci_byte_name	DB 'Read PCI byte',0

read_pci_byte	Proc far
	push bx
	push ecx
	push dx
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
	cli
	out dx,eax
	mov dx,0CFCh
	and cl,3
	or dl,cl
	in al,dx
	sti
;
	pop dx
	pop ecx
	pop bx
	ret
read_pci_byte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			write_pci_byte
;
;		DESCRIPTION:	Write a 8-bit register
;
;		PARAMETERS:		AL		Data
;						BH		Bus
;						BL 		Device
;						CH		Function
;						CL		Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_pci_byte_name	DB 'Write PCI byte',0

write_pci_byte	Proc far
	push eax
	push bx
	push ecx
	push dx
;
	push ax
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
	cli
	out dx,eax
	mov dx,0CFCh
	and cl,3
	or dl,cl
	pop ax
	out dx,al
	sti
;
	pop dx
	pop ecx
	pop bx
	pop eax
	ret
write_pci_byte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadPciWord
;
;		DESCRIPTION:	Read a 16-bit register
;
;		PARAMETERS:		BH		Bus
;						BL 		Device
;						CH		Function
;						CL		Register
;
;		RETURNS:		AX		Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_pci_word_name	DB 'Read PCI word',0

read_pci_word	Proc far
	push bx
	push ecx
	push dx
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
	cli
	out dx,eax
	mov dx,0CFCh
	and cl,2
	or dl,cl
	in ax,dx
	sti
;
	pop dx
	pop ecx
	pop bx
	ret
read_pci_word	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WritePciWord
;
;		DESCRIPTION:	Write a 16-bit register
;
;		PARAMETERS:		AX		Data
;						BH		Bus
;						BL 		Device
;						CH		Function
;						CL		Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_pci_word_name	DB 'Write PCI word',0

write_pci_word	Proc far
	push eax
	push bx
	push ecx
	push dx
;
	push ax
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
	cli
	out dx,eax
	mov dx,0CFCh
	and cl,2
	or dl,cl
	pop ax
	out dx,ax
	sti
;
	pop dx
	pop ecx
	pop bx
	pop eax
	ret
write_pci_word	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadPciDword
;
;		DESCRIPTION:	Read a 32-bit register
;
;		PARAMETERS:		BH		Bus
;						BL 		Device
;						CH		Function
;						CL		Register
;
;		RETURNS:		EAX		Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_pci_dword_name	DB 'Read PCI dword',0

read_pci_dword	Proc far
	push bx
	push ecx
	push dx
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
	cli
	out dx,eax
	mov dx,0CFCh
	in eax,dx
	sti
;
	pop dx
	pop ecx
	pop bx
	ret
read_pci_dword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WritePciDword
;
;		DESCRIPTION:	Write a 32-bit register
;
;		PARAMETERS:		EAX		Data
;						BH		Bus
;						BL 		Device
;						CH		Function
;						CL		Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_pci_dword_name	DB 'Write PCI dword',0

write_pci_dword	Proc far
	push eax
	push bx
	push ecx
	push dx
;
	push eax
	mov al,bh
	mov ah,80h
	shl eax,16
	mov ah,bl
	shl ah,3
	or ah,ch
	mov al,cl
;
	mov dx,0CF8h
	cli
	out dx,eax
	mov dx,0CFCh
	pop eax
	out dx,eax
	sti
;
	pop dx
	pop ecx
	pop bx
	pop eax
	ret
write_pci_dword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindPciDevice
;
;		DESCRIPTION:	Find a PCI device
;
;		PARAMETERS:		CX		Device ID
;						DX		Vendor ID
;						AX		Device number
;
;		RETURNS:		NC		Success
;						BH		Bus
;                       CH      Function
;						BL 		Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_pci_device_name	DB 'Find PCI Device',0

find_pci_device	Proc far
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
    xor si,si
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
	ret
find_pci_device	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindPciClass
;
;		DESCRIPTION:	Find PCI class
;
;		PARAMETERS:		BH		Class
;						BL 		Sub class
;						CH		Interface
;						AX		Device number
;
;		RETURNS:		NC		Success
;						BH		Bus
;						BL 		Device
;                       CH      Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_pci_class_name	DB 'Find PCI Class',0

find_pci_class	Proc far
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
	cli
	out dx,eax
	mov dx,0CFCh
	in eax,dx
	sti
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
	ret
find_pci_class	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindPciCapability
;
;		DESCRIPTION:	Find a PCI capability
;
;		PARAMETERS:		BH		Bus
;						BL 		Device
;						CH		Function
;                       AL      Capability
;
;		RETURNS:		AL      Index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_pci_cap_name	DB 'Find PCI Capability',0

find_pci_cap	Proc far
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
	ret
find_pci_cap	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			bios_pci_int
;
;		DESCRIPTION:	Handling BIOS PCI int (0B1h, int 1Ah)
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bios_pci_int_name DB 'BIOS PCI int',0

pci_error	Proc near
	int 3
	or byte ptr [bp].vm_eflags,1
	ret
pci_error	Endp

pci_inst_check	Proc near
	mov edx,20494350h
	xor edi,edi
	call GetPciBusCount
	mov cl,al
	mov eax,[bp].vm_eax
	xor ax,ax
	mov word ptr [bp].vm_ebx,210h
	and byte ptr [bp].vm_eflags,NOT 1
	ret
pci_inst_check	Endp

pci_find_device	Proc near
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
pci_find_device	Endp

pci_find_class	Proc near
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
pci_find_class	Endp

pci_read_byte	Proc near
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
pci_read_byte	Endp

pci_write_byte	Proc near
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
pci_write_byte	Endp

pci_read_word	Proc near
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
pci_read_word	Endp

pci_write_word	Proc near
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
pci_write_word	Endp

pci_read_dword	Proc near
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
pci_read_dword	Endp

pci_write_dword	Proc near
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
pci_write_dword	Endp

pci_int_tab:
pci00	DW OFFSET pci_error
pci01	DW OFFSET pci_inst_check
pci02	DW OFFSET pci_find_device
pci03	DW OFFSET pci_find_class
pci04	DW OFFSET pci_error
pci05	DW OFFSET pci_error
pci06	DW OFFSET pci_error
pci07	DW OFFSET pci_error
pci08	DW OFFSET pci_read_byte
pci09	DW OFFSET pci_read_word
pci0A	DW OFFSET pci_read_dword
pci0B	DW OFFSET pci_write_byte
pci0C	DW OFFSET pci_write_word
pci0D	DW OFFSET pci_write_dword
pci0E	DW OFFSET pci_error
pci0F	DW OFFSET pci_error

bios_pci_int	Proc far
	movzx bx,al
	cmp bx,10h
	jnc bios_pci_failed
;
	add bx,bx
	call word ptr cs:[bx].pci_int_tab
	ret

bios_pci_failed:
	or byte ptr [bp].vm_eflags,1
	ret
bios_pci_int	Endp	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_pci_devices
;
;		DESCRIPTION:	Init PCI devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_pci_devices	Proc near
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET pci_device_arr

	mov ecx,80000000h

init_pci_device_loop:
	mov eax,ecx
	mov dx,0CF8h
	and al,0FCh
	cli
	out dx,eax
	mov dx,0CFCh
	in eax,dx
	sti
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
init_pci_devices	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init
;
;		DESCRIPTION:	INIT PCI DEVICE
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	mov bx,SEG data
	mov ds,bx
	mov es,bx
	mov cx,2 * MAX_PCI_DEVICES
	mov eax,-1
	mov di,OFFSET pci_device_arr
	rep stosd
;
    call init_pci_devices
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET bios_pci_int
	mov di,OFFSET bios_pci_int_name
	xor cl,cl
	mov ax,bios_pci_int_nr
	RegisterOsGate
;
	mov si,OFFSET read_pci_byte
	mov di,OFFSET read_pci_byte_name
	xor cl,cl
	mov ax,read_pci_byte_nr
	RegisterOsGate
;
	mov si,OFFSET read_pci_word
	mov di,OFFSET read_pci_word_name
	xor cl,cl
	mov ax,read_pci_word_nr
	RegisterOsGate
;
	mov si,OFFSET read_pci_dword
	mov di,OFFSET read_pci_dword_name
	xor cl,cl
	mov ax,read_pci_dword_nr
	RegisterOsGate
;
	mov si,OFFSET write_pci_byte
	mov di,OFFSET write_pci_byte_name
	xor cl,cl
	mov ax,write_pci_byte_nr
	RegisterOsGate
;
	mov si,OFFSET write_pci_word
	mov di,OFFSET write_pci_word_name
	xor cl,cl
	mov ax,write_pci_word_nr
	RegisterOsGate
;
	mov si,OFFSET write_pci_dword
	mov di,OFFSET write_pci_dword_name
	xor cl,cl
	mov ax,write_pci_dword_nr
	RegisterOsGate
;
	mov si,OFFSET find_pci_class
	mov di,OFFSET find_pci_class_name
	xor cl,cl
	mov ax,find_pci_class_nr
	RegisterOsGate
;
	mov si,OFFSET find_pci_device
	mov di,OFFSET find_pci_device_name
	xor cl,cl
	mov ax,find_pci_device_nr
	RegisterOsGate
;
	mov si,OFFSET find_pci_cap
	mov di,OFFSET find_pci_cap_name
	xor cl,cl
	mov ax,find_pci_cap_nr
	RegisterOsGate
	clc
	ret
init	Endp

code	ENDS

	END init
