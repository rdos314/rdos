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
; Support for AC97 Audio using Geod companion chip CS5536
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
ACC_BM0 = 20h
ACC_BM1 = 28h
ACC_BM2 = 30h
ACC_BM3 = 38h
ACC_BM4 = 40h
ACC_BM5 = 48h
ACC_BM6 = 50h
ACC_BM7 = 58h

ACC_BM_CMD = 0
ACC_BM_STATUS = 1
ACC_BM_PRD = 4

audio_channel_struc STRUC

AcCmdIo         DW ?
AcStatusIo      DW ?       
AcPrdIo         DW ?
AcPrdPhys       DD ?
AcPrd1Phys      DD ?
AcPrd2Phys      DD ?
AcPrdLinear     DD ?
AcPrd1Linear    DD ?
AcPrd2Linear    DD ?
AcCurrPrd       DD ?
AcNotify        DW ?
AcIrqStatus     DB ?

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
;		NAME:			AudioInt
;
;		DESCRIPTION:    Audio controller interrupt
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AudioInt	Proc far

aiLoop:
   	mov dx,ds:IoBase
    add dx,ACC_IRQ_STATUS
    in ax,dx
    test ax,4
    jz aiNot0
;    
    push ax
    mov dx,ds:Ac0.AcStatusIo
    in al,dx
    or ds:Ac0.AcIrqStatus,al
    mov bx,ds:Ac0.AcNotify
    Signal
    pop ax

aiNot0:
    test ax,8
    jz aiNot1
;    
    push ax
    mov dx,ds:Ac1.AcStatusIo
    in al,dx
    or ds:Ac1.AcIrqStatus,al
    mov bx,ds:Ac1.AcNotify
    Signal
    pop ax

aiNot1:
    test ax,10h
    jz aiNot2
;    
    push ax
    mov dx,ds:Ac2.AcStatusIo
    in al,dx
    or ds:Ac2.AcIrqStatus,al
    mov bx,ds:Ac2.AcNotify
    Signal
    pop ax

aiNot2:
    test ax,20h
    jz aiNot3
;    
    push ax
    mov dx,ds:Ac3.AcStatusIo
    in al,dx
    or ds:Ac3.AcIrqStatus,al
    mov bx,ds:Ac3.AcNotify
    Signal
    pop ax

aiNot3:
    test ax,40h
    jz aiNot4
;    
    push ax
    mov dx,ds:Ac4.AcStatusIo
    in al,dx
    or ds:Ac4.AcIrqStatus,al
    mov bx,ds:Ac4.AcNotify
    Signal
    pop ax

aiNot4:
    test ax,80h
    jz aiNot5
;    
    push ax
    mov dx,ds:Ac5.AcStatusIo
    in al,dx
    or ds:Ac5.AcIrqStatus,al
    mov bx,ds:Ac5.AcNotify
    Signal
    pop ax

aiNot5:
    test ax,100h
    jz aiNot6
;    
    push ax
    mov dx,ds:Ac6.AcStatusIo
    in al,dx
    or ds:Ac6.AcIrqStatus,al
    mov bx,ds:Ac6.AcNotify
    Signal
    pop ax

aiNot6:
    test ax,200h
    jz aiNot7
;    
    push ax
    mov dx,ds:Ac7.AcStatusIo
    in al,dx
    or ds:Ac7.AcIrqStatus,al
    mov bx,ds:Ac7.AcNotify
    Signal
    pop ax

aiNot7:
	ret
AudioInt	Endp

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
;		NAME:		    CreatePrdTable
;
;		DESCRIPTION:    Create a PRD table
;
;       PARAMETERS:     DS:BX       Ac entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePrdTable  Proc near    
    push es
    push eax
    push ecx
    push edx
    push edi
;    
	mov ecx,20h
	AllocateMultiplePhysical
	jc cptDone
;
    mov ds:[bx].AcPrd1Phys,eax
    add eax,10000h
    mov ds:[bx].AcPrd2Phys,eax
;
    mov eax,10000h
    AllocateBigLinear
    mov ds:[bx].AcPrd1Linear,edx
    mov ds:[bx].AcCurrPrd,edx
;    
    mov eax,10000h
    AllocateBigLinear
    mov ds:[bx].AcPrd2Linear,edx
;
	mov eax,ds:[bx].AcPrd1Phys
	mov edx,ds:[bx].AcPrd1Linear
	or al,7
    mov cx,10h

cptPrd1Loop:
	SetPhysicalPage
	add eax,1000h
	add edx,1000h
	loop cptPrd1Loop
;
	mov eax,ds:[bx].AcPrd2Phys
	mov edx,ds:[bx].AcPrd2Linear
	or al,7
    mov cx,10h

cptPrd2Loop:
	SetPhysicalPage
	add eax,1000h
	add edx,1000h
	loop cptPrd2Loop
;
    AllocatePhysical
    mov ds:[bx].AcPrdPhys,eax    
;    
    mov eax,1000h
    AllocateBigLinear
    mov ds:[bx].AcPrdLinear,edx
;	
	mov eax,ds:[bx].AcPrdPhys
	mov edx,ds:[bx].AcPrdLinear
	or al,7
	SetPhysicalPage
;
    mov	ax,flat_sel
    mov es,ax
    mov edi,ds:[bx].AcPrdLinear
;
    mov eax,ds:[bx].AcPrd1Phys
    stos dword ptr es:[edi]
    mov eax,40000000h
    stos dword ptr es:[edi]
;
    mov eax,ds:[bx].AcPrd2Phys
    stos dword ptr es:[edi]
    mov eax,40000000h
    stos dword ptr es:[edi]
;
    mov eax,ds:[bx].AcPrdPhys
    stos dword ptr es:[edi]
    mov eax,20000000h
    stos dword ptr es:[edi]                    

cptDone:    
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    ret
CreatePrdTable  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    FreePrdTable
;
;		DESCRIPTION:    Free PRD table
;
;       PARAMETERS:     DS:BX       Ac entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreePrdTable  Proc near    
    push ecx
    push edx
;
    mov edx,ds:[bx].AcPrdLinear
    or edx,edx
    jz fptDone
;    
    mov ecx,10000h
    mov edx,ds:[bx].AcPrd1Linear
    FreeLinear
    mov ds:[bx].AcPrd1Phys,0
    mov ds:[bx].AcPrd1Linear,0
;
    mov ecx,10000h
    mov edx,ds:[bx].AcPrd2Linear
    FreeLinear
    mov ds:[bx].AcPrd2Phys,0
    mov ds:[bx].AcPrd2Linear,0
;
    mov ecx,1000h
    mov edx,ds:[bx].AcPrdLinear
    FreeLinear
    mov ds:[bx].AcPrdPhys,0
    mov ds:[bx].AcPrdLinear,0

fptDone:
    pop edx
    pop ecx
    ret
FreePrdTable  Endp

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
    push ds
    push eax
    push bx
    push dx
;
    mov ax,audio_dev_data_sel
    mov ds,ax
    mov dx,ds:IoBase
    add dx,ACC_BM0 + ACC_BM_PRD
    mov eax,ds:Ac0.AcPrdPhys
    out dx,eax
;
    pop dx
    pop bx
    pop eax
    pop ds
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
    push ds
    push ax
    push bx
    push dx
;
    mov ax,audio_dev_data_sel
    mov ds,ax
;
    mov dx,ds:Ac0.AcCmdIo
    xor al,al
    out dx,al
;
    pop dx
    pop bx
    pop ax
    pop ds
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
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ax,ds
    mov fs,ax
    mov ax,es
    mov gs,ax
    mov ax,audio_dev_data_sel
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;
    mov esi,2
    push cx
    mov edi,ds:Ac0.AcCurrPrd

saoDataLoop:    
    mov ax,fs:[esi]
    stos word ptr es:[edi]
    mov ax,gs:[esi]
    stos word ptr es:[edi]
    add esi,4
    loop saoDataLoop
;
    pop cx
;    
    mov dx,ds:IoBase
    add dx,ACC_BM0 + ACC_BM_PRD
    in eax,dx
    mov bp,ax
;    
    mov ax,cx
    shl ax,2
    mov edx,ds:Ac0.AcPrdLinear
    mov edi,ds:Ac0.AcCurrPrd
    cmp edi,ds:Ac0.AcPrd1Linear
    je saoPrd1

saoPrd2:
    test bp,8
    jz saoPrd2Ok
;
;    int 3
;    jmp saoPrd1Ok    

saoPrd2Ok:
    add edx,8
    mov es:[edx+4],ax
    mov edi,ds:Ac0.AcPrd1Linear
    mov ds:Ac0.AcCurrPrd,edi
    jmp saoPrdOk

saoPrd1:
    test bp,10h
    jz saoPrd1Ok
;    
    test bp,8
    jnz saoPrd1Ok
;
;    int 3
;    jmp saoPrd2Ok

saoPrd1Ok:
    mov es:[edx+4],ax
    mov edi,ds:Ac0.AcPrd2Linear
    mov ds:Ac0.AcCurrPrd,edi
    add edx,8
    mov ax,es:[edx+4]
    or ax,ax
    jz saoDone

saoPrdOk:
    GetThread
    mov ds:Ac0.AcNotify,ax
;    
    mov dx,ds:Ac0.AcCmdIo
    in al,dx
    and al,3
    cmp al,1
    je saoRunning
;
    and al,NOT 7
    or al,1
    out dx,al

saoRunning:
    WaitForSignal
    mov al,ds:Ac0.AcIrqStatus
    test al,1
    jz saoRunning
;
    mov ds:Ac0.AcIrqStatus,0
            
saoDone:            
    popad
    pop gs
    pop fs
    pop es
    pop ds    
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
	mov bx,cs
	mov es,bx
	mov di,OFFSET AudioInt
	RequestSharedIrqHandler
;
    mov dx,ds:IoBase
    mov cx,8
    mov bx,OFFSET Ac0
    mov ax,ACC_BM0

init_ch_loop:
    mov si,ax
    add si,dx
    mov ds:[bx].AcCmdIo,si
    inc si
    mov ds:[bx].AcStatusIo,si
    add si,3
    mov ds:[bx].AcPrdIo,si
;
    mov ds:[bx].AcPrdPhys,0
    mov ds:[bx].AcPrd1Phys,0
    mov ds:[bx].AcPrd2Phys,0
    mov ds:[bx].AcPrdLinear,0
    mov ds:[bx].AcPrd1Linear,0
    mov ds:[bx].AcPrd2Linear,0
    mov ds:[bx].AcIrqStatus,0
    mov ds:[bx].AcNotify,0
;
    add bx,SIZE audio_channel_struc
    add ax,8
    loop init_ch_loop
;
;    mov dx,ds:IoBase
;    add dx,ACC_CODEC_CONTROL
;    mov eax,20000h
;    out dx,eax
;    
;    mov dx,ds:IoBase
;    add dx,ACC_CODEC_STATUS
;    in eax,dx
;
;    mov bx,0
;    WriteCodec
;
    mov ax,audio_dev_data_sel
    mov ds,ax
    mov bx,OFFSET Ac0
    call CreatePrdTable

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
