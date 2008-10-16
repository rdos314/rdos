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
; CS5536A.ASM
; Support for AC97 Audio using Geo companion chip CS5536
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME cs5536a

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\pci.inc

ACC_GPIO_STATUS = 0
ACC_GPIO_CONTROL = 4
ACC_CODEC_STATUS = 8
ACC_CODEC_CONTROL = 0Ch
ACC_IRQ_STATUS = 12h
ACC_ENGINE_CONTROL = 14h
ACC_BM_CMD0 = 20h
ACC_BM_PRD0 = 24h
ACC_BM_CMD1 = 28h
ACC_BM_PRD1 = 2Ch
ACC_BM_CMD2 = 30h
ACC_BM_PRD2 = 34h
ACC_BM_CMD3 = 38h
ACC_BM_PRD3 = 3Ch
ACC_BM_CMD4 = 40h
ACC_BM_PRD4 = 44h
ACC_BM_CMD5 = 48h
ACC_BM_PRD5 = 4Ch
ACC_BM_CMD6 = 50h
ACC_BM_PRD6 = 54h
ACC_BM_CMD7 = 58h
ACC_BM_PRD7 = 5Ch

audio_channel_struc STRUC

AcCmdIo         DW ?
AcStatusIo      DW ?       
AcPrdIo         DW ?

audio_channel_struc ENDS

audio_dev_data_seg	SEGMENT AT 0

IoBase      DW ?

Ac0         audio_channel_struc <>
Ac1         audio_channel_struc <>
Ac2         audio_channel_struc <>
Ac3         audio_channel_struc <>
Ac4         audio_channel_struc <>
Ac5         audio_channel_struc <>
Ac6         audio_channel_struc <>
Ac7         audio_channel_struc <>

audio_dev_data_seg  ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadCodec
;
;		DESCRIPTION:    Read CODEC register
;
;       PARAMETERS:     BX      Register
;
;		RETURNS:		AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_codec_name DB 'Read CODEC',0

read_codec	Proc far
    push ds
    push cx
    push dx
;
    mov dx,audio_dev_data_sel
    mov ds,dx
    mov cx,100

rcCheckBusy:        
    mov dx,ds:IoBase
    add dx,ACC_CODEC_CONTROL
    in eax,dx
    test eax,10000h
    jz rcNotBusy
;
    mov ax,10
    WaitMilliSec
    loop rcCheckBusy
;
    stc
    jmp rcDone

rcNotBusy:
    movzx eax,bx
    ror eax,8
    or eax,80010000h
    out dx,eax
;
    mov cx, 100    

rcDataLoop:
    mov dx,ds:IoBase
    add dx,ACC_CODEC_STATUS
    in eax,dx
    test eax,20000h
    jnz rcDataOk
;
    mov ax,10
    WaitMilliSec    
    loop rcDataLoop

rcFail:
    stc
    jmp rcDone    

rcDataOk:
    mov edx,eax
    rol edx,8
    cmp dl,bl
    jne rcFail
;    
    clc

rcDone:    
    pop dx
    pop cx
    pop ds
    ret
read_codec  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteCodec
;
;		DESCRIPTION:    Write CODEC register
;
;       PARAMETERS:     BX      Register
;		        		AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_codec_name DB 'Write CODEC',0

write_codec	Proc far
    push ds
    push eax
    push cx
    push dx
    push si
;
    mov si,ax
    mov dx,audio_dev_data_sel
    mov ds,dx
    mov cx,100

wcCheckBusy:        
    mov dx,ds:IoBase
    add dx,ACC_CODEC_CONTROL
    in eax,dx
    test eax,10000h
    jz wcNotBusy
;
    mov ax,10
    WaitMilliSec
    loop wcCheckBusy
;
    stc
    jmp wcDone

wcNotBusy:
    movzx eax,bx
    ror eax,8
    or eax,10000h
    mov ax,si
    out dx,eax
    clc

wcDone:    
    pop si
    pop dx
    pop cx
    pop eax
    pop ds
    ret
write_codec  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init_dev
;
;		DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PciVendorTab:
pci00	DW 1022h, 2093h
pci01 	DW 0,	  0

detect_name	DB 'CS5536-AC97',0

detect_thread	proc far
	mov ax,audio_dev_data_sel
	mov ds,ax
	mov si,OFFSET PciVendorTab
	xor ax,ax
init_pci_loop:
	mov dx,cs:[si]
	mov cx,cs:[si+2]
	or dx,dx
	stc
	jz init_pci_done
;
	FindPciDevice
	jnc init_pci_found
;
	add si,4
	jmp init_pci_loop

init_pci_found:
	mov cl,PCI_card_ExCa_base
	ReadPciDword
	mov dx,ax
	and dx,0FFE0h
	mov ds:IoBase,dx
;
	mov cl,PCI_interrupt_line
	ReadPciByte
;	mov bx,cs
;	mov es,bx
;	mov di,OFFSET NetInt	
;	RequestSharedIrqHandler
;	
;
    mov cx,8
    mov bx,OFFSET Ac0
    mov ax,ACC_BM_CMD0

init_ch_loop:
    mov si,ax
    add si,dx
    mov ds:[bx].AcCmdIo,si
    inc si
    mov ds:[bx].AcStatusIo,si
    add si,3
    mov ds:[bx].AcPrdIo,si
;
    add bx,SIZE audio_channel_struc
    add ax,8
    loop init_ch_loop
;
    mov dx,ds:IoBase
    add dx,ACC_CODEC_CONTROL
    mov eax,20000h
    out dx,eax
;    
    mov dx,ds:IoBase
    add dx,ACC_CODEC_STATUS
    in eax,dx
;
    int 3        
    mov bx,2
    ReadCodec
;
    mov ax,3F3Fh
    WriteCodec
;
    ReadCodec        
;
    mov dx,ds:Ac0.AcStatusIo
    in al,dx
;
    mov dx,ds:Ac0.AcPrdIo
    in eax,dx

init_pci_done:
	ret
detect_thread	endp
	
init_dev	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET detect_name
	mov si,OFFSET detect_thread
	mov ax,4
	mov cx,100h
	CreateThread
;
	popa
	pop es
	pop ds
	ret
init_dev	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init AC97 on chipset
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	pusha
	push ds
;
	mov bx,audio_dev_code_sel
	InitDevice
;
	mov eax,SIZE audio_dev_data_seg
	mov bx,audio_dev_data_sel
	AllocateFixedSystemMem
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET init_dev
	HookInitTasking
;
	mov si,OFFSET read_codec
	mov di,OFFSET read_codec_name
	xor cl,cl
	mov ax,read_codec_nr
	RegisterOsGate
;
	mov si,OFFSET write_codec
	mov di,OFFSET write_codec_name
	xor cl,cl
	mov ax,write_codec_nr
	RegisterOsGate
;
	pop ds
	popa
	ret
init	ENDP

code	ENDS

	END init
