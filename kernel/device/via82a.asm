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
; VIA82A.ASM
; Support for AC97 Audio using VT82Cxxx chip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME via82a

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\pci.inc

audio_channel_struc STRUC

AcCmdIo         DW ?

audio_channel_struc ENDS

audio_dev_data_seg	SEGMENT AT 0

IoBase      DW ?

Ac0         audio_channel_struc <>
Ac1         audio_channel_struc <>
Ac2         audio_channel_struc <>

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
    int 3
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
    int 3
    ret
write_codec  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenAudioOut
;
;		DESCRIPTION:    Open audio out
;
;       PARAMETERS:     AX      Sample rate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_audio_out_name DB 'Open Audio Out',0

open_audio_out	Proc far
    int 3
    ret
open_audio_out  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CloseAudioOut
;
;		DESCRIPTION:    Close audio out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_audio_out_name DB 'Close Audio Out',0

close_audio_out	Proc far
    int 3
    ret
close_audio_out  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendAudioOut
;
;		DESCRIPTION:    Send audio out
;
;       PARAMETERS:     DS      Left channel 32-bit sample data
;                       ES      Right channel
;                       CX      Number of samples
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_audio_out_name DB 'Send Audio Out',0

send_audio_out	Proc far
    int 3
    ret
send_audio_out  Endp

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

detect_name	DB 'VT82C-AC97',0

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
    int 3
	mov cl,PCI_card_ExCa_base
	ReadPciDword
	mov dx,ax
	and dx,0FFE0h
	mov ds:IoBase,dx
;
	mov cl,PCI_interrupt_line
	ReadPciByte
	mov bx,cs
	mov es,bx
;	mov di,OFFSET AudioInt
;	RequestSharedIrqHandler

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
	mov si,OFFSET open_audio_out
	mov di,OFFSET open_audio_out_name
	xor cl,cl
	mov ax,open_audio_out_nr
	RegisterOsGate
;
	mov si,OFFSET close_audio_out
	mov di,OFFSET close_audio_out_name
	xor cl,cl
	mov ax,close_audio_out_nr
	RegisterOsGate
;
	mov si,OFFSET send_audio_out
	mov di,OFFSET send_audio_out_name
	xor cl,cl
	mov ax,send_audio_out_nr
	RegisterOsGate
;
	pop ds
	popa
	ret
init	ENDP

code	ENDS

	END init
