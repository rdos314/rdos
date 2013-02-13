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
; HDA.ASM
; HD Audio driver (Intel compatible)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\pcdev\pci.inc

REQ_RESET   = 1

MAX_INPUT_STREAMS   = 15
MAX_OUTPUT_STREAMS  = 15

OUTPUT_STREAM_ID    = 1

STREAM_FLAG_RUNNING = 1
STREAM_FLAG_IOC     = 2
STREAM_FLAG_OF      = 4

widget_base STRUC

wb_type     DD ?
wb_id       DD ?
wb_address  DD ?
wb_node     DD ?
wb_channels DD ?

widget_base ENDS

hda_reg STRUC

HdaGcap         DW ?
HdaVmin         DB ?
HdaVmax         DB ?
HdaOutPay       DW ?
HdaInPay        DW ?
HdaGctl         DD ?
HdaWakeEn       DW ?
HdaStateSts     DW ?
HhaGsts         DW ?,?,?,?
HdaOutStrmPay   DW ?
HdaInStrmPay    DW ?,?,?
HdaIntCtl       DD ?
HdaIntSts       DD ?,?,?
HdaClock        DD ?,?
HdaSSync        DD ?,?
HdaCorb         DD ?,?
HdaCorbWp       DW ?
HdaCorbRp       DW ?
HdaCorbCtl      DB ?
HdaCorbSts      DB ?
HdaCorbSize     DB ?,?
HdaRirb         DD ?,?
HdaRirbWp       DW ?
HdaRintCnt      DW ?
HdaRirbCtl      DB ?
HdaRirbSts      DB ?
HdaRirbSize     DB ?,?
HdaResv60       DD ?,?,?,?
HdaDplBase      DD ?,?,?,?

hda_reg Ends

stream_reg    STRUC

srControl        DB ?
srConfig         DW ?
srStatus         DB ?
srLinkPos        DD ?
srBufLen         DD ?
srLvi            DW ?,?
srFifoSize       DW ?
srFormat         DW ?,?,?
srBdl            DD ?,?

stream_reg    ENDS

; must be less than 64 bytes

stream_data STRUC

sdSel           DW ?
sdThread        DW ?
sdPrdPhys       DD ?
sdPrd1Phys      DD ?
sdPrd2Phys      DD ?
sdPrdLinear     DD ?
sdPrd1Linear    DD ?
sdPrd2Linear    DD ?
sdCurrPrd       DD ?
sdWidth         DW ?
sdFlags         DW ?
sdStatus        DB ?

stream_data ENDS


hda_seg STRUC

HdaSel          DW 0
HdaLinear       DD 0
CodecPhys       DD 0

CorbSize        DW 0
CorbSel         DW 0

RirbSize        DW 0
RirbSel         DW 0
RirbRp          DW 0

CodecChange     DW 0
CodecThread     DW 0

Req             DB 0,0

StreamCnt       DW 0
StreamArr       DB 30 * 64 DUP(0)      ; stream data structs

InStreamCnt     DW 0
OutStreamCnt    DW 0
InStreamArr     DW MAX_INPUT_STREAMS DUP(0) 
OutStreamArr    DW MAX_OUTPUT_STREAMS DUP(0) 

hda_seg ENDS


data    SEGMENT byte public 'DATA'

OutputFunction  DD ?
OutputCodec     DD ?
OutputFormat    DW ?
OutputWidth     DW ?

HdaCount        DW ?
HdaArr          DW 16 DUP(?)

data    ENDS

    .386p

code    SEGMENT byte public 'CODE'

    assume cs:code

    extrn GetFixedOutput:near
    extrn GetOutputJack:near
    extrn GetInputJack:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetFixedOutput
;
;           DESCRIPTION:    Get fixed output
;
;           RETURNS:        NC      Available
;                           EAX     Function
;                           EDX     Codec
;                           ECX     Node
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_fixed_output_name DB 'Get Fixed Audio Output',0

get_fixed_output      Proc far
    push es
    push edi
;    
    call GetFixedOutput
    or dx,dx
    stc
    jz gfoDone
;
    mov es,dx
    mov edi,eax
    mov eax,es:[edi].wb_id
    mov edx,es:[edi].wb_address
    mov ecx,es:[edi].wb_node
    clc

gfoDone:
    pop edi
    pop es
    ret    
get_fixed_output  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetJackOutput
;
;           DESCRIPTION:    Get jack output
;
;           PARAMETERS:     EBX     Jack #
;
;           RETURNS:        NC      Available
;                           EAX     Function
;                           EDX     Codec
;                           ECX     Node
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_jack_output_name DB 'Get Jack Audio Output',0

get_jack_output      Proc far
    push es
    push edi
;    
    call GetOutputJack
    or dx,dx
    stc
    jz gjoDone
;
    mov es,dx
    mov edi,eax
    mov eax,es:[edi].wb_id
    mov edx,es:[edi].wb_address
    mov ecx,es:[edi].wb_node
    clc

gjoDone:
    pop edi
    pop es
    ret    
get_jack_output  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetJackInput
;
;           DESCRIPTION:    Get jack input
;
;           PARAMETERS:     EBX     Jack #
;
;           RETURNS:        NC      Available
;                           EAX     Function
;                           EDX     Codec
;                           ECX     Node
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_jack_input_name DB 'Get Jack Audio Input',0

get_jack_input      Proc far
    push es
    push edi
;    
    call GetInputJack
    or dx,dx
    stc
    jz gjiDone
;
    mov es,dx
    mov edi,eax
    mov eax,es:[edi].wb_id
    mov edx,es:[edi].wb_address
    mov ecx,es:[edi].wb_node
    clc

gjiDone:
    pop edi
    pop es
    ret    
get_jack_input  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HdaInt
;
;       DESCRIPTION:    HDA interrupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HdaInt  Proc far

hdiLoop:
    mov es,ds:HdaSel
    mov eax,es:HdaIntSts
    test eax,80000000h
    jz hdiDone
;
    test eax,40000000h
    jz hdiStream
;
    mov ax,es:HdaStateSts
    or ax,ax
    jz hdiNotCodecChange
;    
    lock or ds:CodecChange,ax
    mov es:HdaStateSts,ax
    mov bx,ds:CodecThread
    Signal    

hdiNotCodecChange:
    mov al,es:HdaCorbSts
    test al,1
    jz hdiNotCorb
;
    mov al,1
    mov es:HdaCorbSts,al
    lock or ds:Req,REQ_RESET

hdiNotCorb:
    mov al,es:HdaRirbSts
    test al,4
    jz hdiNotRirbOverrun
;
    mov al,4
    mov es:HdaRirbSts,al
    lock or ds:Req,REQ_RESET

hdiNotRirbOverrun:
    mov al,es:HdaRirbSts
    test al,1
    jz hdiNotResp
;    
    mov al,1
    mov es:HdaRirbSts,al
    mov bx,ds:CodecThread
    Signal

hdiNotResp:
    jmp hdiLoop

hdiStream:
    movzx ecx,ds:StreamCnt
    mov ebx,OFFSET StreamArr

hdiStreamLoop:    
    test al,1
    jz hdiNextStream
;
    mov es,ds:[ebx].sdSel
    test ds:[ebx].sdFlags,STREAM_FLAG_IOC
    jz hdiStreamFirst
;
    lock or ds:[ebx].sdFlags,STREAM_FLAG_OF
    and es:srControl,NOT 2
    lock and ds:[ebx].sdFlags,NOT STREAM_FLAG_RUNNING
        
hdiStreamFirst:
    lock or ds:[ebx].sdFlags,STREAM_FLAG_IOC
;
    push ax
    push bx
;
    mov al,es:srStatus
    or ds:[ebx].sdStatus,al
    mov es:srStatus,al
;    
    mov bx,ds:[ebx].sdThread
    Signal
;    
    pop bx
    pop ax

hdiNextStream:
    shr eax,1
    add ebx,64
    loop hdiStreamLoop        
;
    jmp hdiLoop    

hdiDone:           
    ret
HdaInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetCorbSize
;
;       DESCRIPTION:    Determine (and configure) corb size
;
;       PARAMETERS:     DS      HDA sel
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetCorbSize Proc near
    mov al,es:HdaCorbSize
    mov cx,1024
    mov ah,2
    test al,40h
    jnz gcsOk
;
    mov cx,64
    mov ah,1
    test al,20h
    jnz gcsOk
;
    mov cx,8
    mov ah,0

gcsOk:
    and al,0FCh
    or al,ah
    mov es:HdaCorbSize,al
    mov ds:CorbSize,cx
    ret
GetCorbSize Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetRirbSize
;
;       DESCRIPTION:    Determine (and configure) rirb size
;
;       PARAMETERS:     DS      HDA sel
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRirbSize Proc near
    mov al,es:HdaRirbSize
    mov cx,2048
    mov ah,2
    test al,40h
    jnz grsOk
;
    mov cx,128
    mov ah,1
    test al,20h
    jnz grsOk
;
    mov cx,16
    mov ah,0

grsOk:
    and al,0FCh
    or al,ah
    mov es:HdaRirbSize,al
    mov ds:RirbSize,cx
    ret
GetRirbSize Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitCorbBuf
;
;       DESCRIPTION:    Init corb buffer
;
;       PARAMETERS:     DS      HDA sel
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitCorbBuf   Proc near
    push es
    push ecx
    push edi
;    
    mov es,ds:CorbSel
    movzx ecx,ds:CorbSize
    shr ecx,2
    xor eax,eax
    xor edi,edi
    rep stosd
;
    pop edi
    pop ecx
    pop es
    ret
InitCorbBuf Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitRirbBuf
;
;       DESCRIPTION:    Init rirb buffer
;
;       PARAMETERS:     DS      HDA sel
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitRirbBuf   Proc near
    push es
    push ecx
    push edi
;    
    mov es,ds:RirbSel
    movzx ecx,ds:RirbSize
    shr ecx,2
    xor eax,eax
    xor edi,edi
    rep stosd
;
    pop edi
    pop ecx
    pop es
    ret
InitRirbBuf Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartCorb
;
;       DESCRIPTION:    Start corb
;
;       PARAMETERS:     DS      HDA sel
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartCorb   Proc near
    mov ax,8000h
    mov es:HdaCorbRp,ax

scWaitReset:
    mov ax,es:HdaCorbRp    
    test ax,8000h
    jnz scResetOk
;
    mov ax,10
    WaitMilliSec
    jmp scWaitReset

scResetOk:
    xor ax,ax
    mov es:HdaCorbRp,ax

scWaitComplete:
    mov ax,es:HdaCorbRp
    test ax,8000h
    jz scCompleteOk
;
    mov ax,10
    WaitMilliSec
    jmp scWaitComplete

scCompleteOk:
    mov al,3
    mov es:HdaCorbCtl,al
    ret
StartCorb Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartRirb
;
;       DESCRIPTION:    Start rirb
;
;       PARAMETERS:     DS      HDA sel
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartRirb   Proc near
    mov ax,8000h
    mov es:HdaRirbWp,ax
;
    mov ax,1
    mov es:HdaRintCnt,ax
;       
    mov al,7
    mov es:HdaRirbCtl,al
;
    xor ax,ax
    mov ds:RirbRp,ax    
    ret
StartRirb Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupCodecBuf
;
;       DESCRIPTION:    Setup codec corb and rirb buffers
;
;       PARAMETERS:     DS      HDA sel
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupCodecBuf   Proc near
    AllocatePhysical32
    mov ds:CodecPhys,eax
    mov es:HdaCorb,eax
    add eax,800h
    mov es:HdaRirb,eax
;    
    mov eax,1000h
    AllocateBigLinear
;
    AllocateGdt
    movzx ecx,ds:CorbSize
    CreateDataSelector16
    mov ds:CorbSel,bx
;
    add edx,800h
    AllocateGdt
    movzx ecx,ds:RirbSize
    CreateDataSelector16
    mov ds:RirbSel,bx
;
    sub edx,800h
    mov eax,ds:CodecPhys
    xor ebx,ebx
    or ax,803h
    SetPageEntry
;              
    call InitCorbBuf
    call InitRirbBuf
;
    call StartCorb    
    call StartRirb
    ret
SetupCodecBuf   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupInts
;
;           DESCRIPTION:    Setup PCI or MSI IRQ
;
;       PARAMETERS:         BH    Bus
;                           BL    Device
;                           CH    Function
;                           DS    Hda sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInts   Proc near
    push ax
    push bx
    push cx
    push edx
    push edi
;    
    GetPciMsi
    jc siIrq

siMsi:
    push cx
    mov cx,1
    mov al,12h
    AllocateInts
    pop cx
    jc siIrq
;    
    mov dl,1
    SetupPciMsi
;    
    mov di,cs
    mov es,di
    mov edi,OFFSET HdaInt
    RequestMsiHandler
    jmp siDone

siIrq:
    GetPciIrqNr
    mov ah,12h
    mov bx,cs
    mov es,bx
    mov edi,OFFSET HdaInt    
    RequestIrqHandler

siDone:
    pop edi
    pop edx
    pop cx
    pop bx
    pop ax
    ret
SetupInts    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Reset
;
;       DESCRIPTION:    Reset controller
;
;       PARAMETERS:     DS      HDA sel
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Reset   Proc near
    mov ds:CodecChange,0
;
    mov ax,7FFFh
    mov es:HdaWakeEn,ax
    mov es:HdaStateSts,ax

rCorbCheckStopped:
    mov al,es:HdaCorbCtl
    test al,2
    jz rRirbCheckStopped
;
    and al,NOT 2
    mov es:HdaCorbCtl,al
    mov ax,10
    WaitMilliSec
    jmp rCorbCheckStopped

rRirbCheckStopped:
    mov al,es:HdaRirbCtl
    test al,2
    jz rCodecIsStopped
;
    and al,NOT 2
    mov es:HdaRirbCtl,al
    mov ax,10
    WaitMilliSec
    jmp rRirbCheckStopped

rCodecIsStopped:    
    mov eax,es:HdaGctl
    and al,NOT 1
    mov es:HdaGctl,eax

rWaitForReset:    
    mov ax,10
    WaitMilliSec
    mov eax,es:HdaGctl
    test al,1
    jnz rWaitForReset
;
    or al,1
    mov es:HdaGctl,eax

rWaitForRunning:
    mov ax,10
    WaitMilliSec
    mov eax,es:HdaGctl
    test al,1
    jz rWaitForRunning
;
    mov ax,10
    WaitMilliSec
;
    mov eax,0C0000000h
    mov es:HdaIntCtl,eax        
    ret
Reset   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreatePrdTable
;
;       DESCRIPTION:    Create a PRD table
;
;       PARAMETERS:     DS:EBX       Stream
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePrdTable  Proc near    
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;    
    mov esi,ebx
;    
    mov ecx,20h
    AllocateMultiplePhysical32
    jc cptDone
;
    mov ds:[esi].sdPrd1Phys,eax
    add eax,10000h
    mov ds:[esi].sdPrd2Phys,eax
;
    mov eax,10000h
    AllocateBigLinear
    mov ds:[esi].sdPrd1Linear,edx
    mov ds:[esi].sdCurrPrd,edx
;    
    mov eax,10000h
    AllocateBigLinear
    mov ds:[esi].sdPrd2Linear,edx
;
    mov eax,ds:[esi].sdPrd1Phys
    mov edx,ds:[esi].sdPrd1Linear
    or al,7
    mov cx,10h

cptPrd1Loop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop cptPrd1Loop
;
    mov eax,ds:[esi].sdPrd2Phys
    mov edx,ds:[esi].sdPrd2Linear
    or al,7
    mov cx,10h

cptPrd2Loop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop cptPrd2Loop
;
    AllocatePhysical32
    mov ds:[esi].sdPrdPhys,eax    
;    
    mov eax,1000h
    AllocateBigLinear
    mov ds:[esi].sdPrdLinear,edx
;       
    mov eax,ds:[esi].sdPrdPhys
    mov edx,ds:[esi].sdPrdLinear
    or al,7
    SetPageEntry
;
    mov ax,flat_sel
    mov es,ax
    mov edi,ds:[si].sdPrdLinear
;
    mov eax,ds:[si].sdPrd1Phys
    stosd
    xor eax,eax
    stosd
    stosd
    mov eax,1
    stosd        
;    
    mov eax,ds:[si].sdPrd2Phys
    stosd
    xor eax,eax
    stosd
    stosd
    mov eax,1
    stosd        

cptDone:    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    ret
CreatePrdTable  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreePrdTable
;
;       DESCRIPTION:    Free PRD table
;
;       PARAMETERS:     DS:EBX       Stream entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreePrdTable  Proc near    
    push ecx
    push edx
;
    mov edx,ds:[bx].sdPrdLinear
    or edx,edx
    jz fptDone
;    
    mov ecx,10000h
    mov edx,ds:[ebx].sdPrd1Linear
    FreeLinear
    mov ds:[ebx].sdPrd1Phys,0
    mov ds:[ebx].sdPrd1Linear,0
;
    mov ecx,10000h
    mov edx,ds:[ebx].sdPrd2Linear
    FreeLinear
    mov ds:[ebx].sdPrd2Phys,0
    mov ds:[ebx].sdPrd2Linear,0
;
    mov ecx,1000h
    mov edx,ds:[ebx].sdPrdLinear
    FreeLinear
    mov ds:[ebx].sdPrdPhys,0
    mov ds:[ebx].sdPrdLinear,0

fptDone:
    pop edx
    pop ecx
    ret
FreePrdTable  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitStreams
;
;       DESCRIPTION:    Init stream interface
;
;       PARAMETERS:     DS      HDA sel
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitStreams     Proc near
    pushad
;
    mov ax,es:HdaGcap
    mov al,ah
    and al,0Fh
    movzx ecx,al
    mov ds:InStreamCnt,cx
    mov ds:StreamCnt,cx
    mov esi,OFFSET StreamArr
    mov edi,OFFSET InStreamArr
;
    mov edx,ds:HdaLinear
    add edx,80h
;
    or ecx,ecx
    jz isInDone    

isInLoop:    
    push ecx
    AllocateGdt
    mov ecx,20h
    CreateDataSelector32
    pop ecx
;
    mov ds:[esi].sdSel,bx
    mov ds:[esi].sdThread,0
    add esi,64
;    
    mov ds:[edi],bx
    add edi,2
    add edx,20h
    loop isInLoop

isInDone:
    mov ax,es:HdaGcap
    mov al,ah
    shr al,4
    and al,0Fh
    movzx ecx,al
    mov ds:OutStreamCnt,cx
    add ds:StreamCnt,cx
    mov edi,OFFSET OutStreamArr
    or ecx,ecx
    jz isOutDone
    
isOutLoop:    
    push ecx
    AllocateGdt
    mov ecx,20h
    CreateDataSelector32
    pop ecx
;
    mov ds:[esi].sdSel,bx
    mov ds:[esi].sdThread,0
    add esi,64
;
    mov ds:[edi],bx
    add edi,2
    add edx,20h
    loop isOutLoop

isOutDone:    
;    
; init default output stream
;
    movzx ebx,ds:InStreamCnt
    shl ebx,6
    add ebx,OFFSET StreamArr
    call CreatePrdTable
;
    popad    
    ret
InitStreams     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetFunctionCount
;
;       DESCRIPTION:    Get HDA function block count
;
;       RETURNS:        EAX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetFunctionCount_
    
GetFunctionCount_  Proc near    
    movzx eax,ds:HdaCount
    ret
GetFunctionCount_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Start function
;
;       DESCRIPTION:    Start HDA function
;
;       PARAMETERS:     EBX      Function #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public StartFunction_
    
StartFunction_  Proc near    
    push ds
    push es
    pushad
;    
    cmp bx,ds:HdaCount
    jae sfDone
;    
    shl ebx,1
    mov ds,ds:[ebx].HdaArr    
    mov es,ds:HdaSel
;    
    call InitStreams
    call Reset
    call GetCorbSize
    call GetRirbSize            
    call SetupCodecBuf

sfDone:
    popad
    pop es
    pop ds
    ret
StartFunction_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetCodecMask
;
;       DESCRIPTION:    Get HDA codec mask
;
;       PARAMETERS:     EBX     Function #
;
;       RETURNS:        EAX     Mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetCodecMask_
    
GetCodecMask_  Proc near    
    xor eax,eax
    cmp bx,ds:HdaCount
    jae cdmDone
;    
    push ds
    mov eax,ebx
    shl eax,1
    mov ds,ds:[eax].HdaArr    
    movzx eax,ds:CodecChange
    pop ds

cdmDone:
    ret
GetCodecMask_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           QueryCodec
;
;       DESCRIPTION:    Query codec
;
;       PARAMETERS:     EBX     Function #
;                       ESI     Codec
;                       EDI     Node
;                       EDX     Data
;
;       RETURNS:        EAX     Response
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public QueryCodec_
    
QueryCodec_  Proc near    
    cmp bx,ds:HdaCount
    jae qcDone
;    
    push ds
    push es
    push fs
    push esi
    push edi
;
    shl esi,28
    shl edi,20    
;    
    mov eax,ebx
    shl eax,1
    mov ds,ds:[eax].HdaArr    
    mov es,ds:HdaSel
    mov fs,ds:CorbSel
;
    GetThread
    mov ds:CodecThread,ax
    ClearSignal
;    
    mov eax,edx
    or eax,esi
    or eax,edi
;
    mov bx,es:HdaCorbWp
    inc bx
    shl bx,2
    cmp bx,ds:CorbSize
    jne qcUpdateCorb
;
    xor bx,bx

qcUpdateCorb:
    mov fs:[bx],eax
    shr bx,2
    mov es:HdaCorbWp,bx

qcWait:    
    WaitForSignal

qcRetry:
    mov bx,es:HdaRirbWp
    cmp bx,ds:RirbRp
    je qcWait
;        
    mov bx,ds:RirbRp
    inc bx
    shl bx,3
    cmp bx,ds:RirbSize
    jne qcRirpPosOk
;
    xor bx,bx

qcRirpPosOk:
    mov fs,ds:RirbSel
    mov eax,fs:[bx+4]
    test ax,10h
    jz qcRespOk
;
    shr bx,3
    mov ds:RirbRp,bx
    jmp qcRetry

qcRespOk:
    mov eax,fs:[bx]
    shr bx,3
    mov ds:RirbRp,bx
;    
    pop edi
    pop esi
    pop fs
    pop es    
    pop ds

qcDone:
    ret
QueryCodec_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetOutputFormat
;
;       DESCRIPTION:    Set output format
;
;       PARAMETERS:     EBX     Function #
;                       ESI     Codec #
;                       AX      Format parameter
;                       CX      Channel width
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetOutputFormat_
    
SetOutputFormat_  Proc near    
    mov ds:OutputFunction,ebx
    mov ds:OutputCodec,esi
    mov ds:OutputFormat,ax
    mov ds:OutputWidth,cx
    ret
SetOutputFormat_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenAudioOut
;
;       DESCRIPTION:    Open audio out
;
;       PARAMETERS:     AX      Sample rate
;                       CX      Number of samples in buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_audio_out_name DB 'Open Audio Out',0

open_audio_out  Proc far
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov ebx,ds:OutputFunction    
    cmp bx,ds:HdaCount
    jae oaoDone
;    
    mov si,ds:OutputWidth
    movzx ecx,cx
    movzx eax,si
    mul ecx
    shl eax,2
    mov ecx,eax    
    mov ax,ds:OutputFormat
;    
    shl ebx,1
    mov ds,ds:[ebx].HdaArr
;
    mov bx,ds:InStreamCnt
    movzx ebx,bx
    shl ebx,6
    add ebx,OFFSET StreamArr
    mov ds:[ebx].sdWidth,si
    mov es,ds:[ebx].sdSel
;
    mov es:srFormat,ax
    mov eax,OUTPUT_STREAM_ID SHL 20
    or al,4
    or eax,1C000000h
    mov dword ptr es:[0],eax
;    
    mov es:srBufLen,ecx
    mov es:srLvi,2
    mov eax,ds:[ebx].sdPrdPhys
    mov es:srBdl,eax
    xor eax,eax
    mov es:srBdl+4,eax
    mov ds:[ebx].sdFlags,ax
    mov ds:[ebx].sdStatus,al
;
    mov es,ds:HdaSel
    mov cx,ds:InStreamCnt
    mov eax,1
    shl eax,cl
    or es:HdaIntCtl,eax
    clc

oaoDone:
    popad
    pop es
    pop ds    
    ret
open_audio_out  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseAudioOut
;
;           DESCRIPTION:    Close audio out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_audio_out_name DB 'Close Audio Out',0

close_audio_out Proc far
    int 3
    ret
close_audio_out  Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendAudioOut
;
;           DESCRIPTION:    Send audio out
;
;       PARAMETERS:     DS      Left channel 32-bit sample data
;               ES      Right channel
;               CX      Number of samples
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_audio_out_name DB 'Send Audio Out',0

send_audio_out  Proc far
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
    mov ax,SEG data
    mov ds,ax
    mov ebx,ds:OutputFunction
    shl ebx,1
    mov ds,ds:[ebx].HdaArr
;
    mov bx,ds:InStreamCnt
    movzx ebx,bx
    shl ebx,6
    add ebx,OFFSET StreamArr
    mov es,ds:[ebx].sdSel
;
    test ds:[ebx].sdFlags, STREAM_FLAG_RUNNING
    jnz saoWait
;
    lock or ds:[ebx].sdFlags, STREAM_FLAG_RUNNING
    mov ds:[ebx].sdThread,0
    jmp saoBuffer

saoWait:    
    mov al,es:srControl
    test al,2
    jnz saoWaitLoop
;
    or al,2
    mov es:srControl,al
    jmp saoBuffer

saoWaitLoop:
    GetThread
    mov ds:[ebx].sdThread,ax
    WaitForSignal
    test ds:[ebx].sdFlags,STREAM_FLAG_IOC
    jz saoWaitLoop
;
    lock and ds:[ebx].sdFlags,NOT STREAM_FLAG_IOC
;        
    test ds:[ebx].sdFlags,STREAM_FLAG_OF
    jz saoWaitDone
;
    int 3
    lock and ds:[ebx].sdFlags,NOT (STREAM_FLAG_RUNNING OR STREAM_FLAG_OF)

saoWaitDone:    
    mov ds:[ebx].sdThread,0

saoBuffer:
    or cx,cx
    jz saoStop
;    
    mov ax,flat_sel
    mov es,ax
    xor esi,esi
    push cx
    mov edi,ds:[ebx].sdCurrPrd

saoDataLoop:    
    mov eax,fs:[esi]
    stosd
    mov eax,gs:[esi]
    stosd
    add esi,4
    loop saoDataLoop
;
    pop cx
;    
    movzx eax,cx
    shl eax,3
    mov edx,ds:[ebx].sdPrdLinear
    mov edi,ds:[ebx].sdCurrPrd
    cmp edi,ds:[ebx].sdPrd1Linear
    je saoPrd1

saoPrd2:
    mov edi,ds:[ebx].sdPrdLinear
    mov es:[edi+18h],eax
;
    mov edi,ds:[ebx].sdPrd1Linear
    mov ds:[ebx].sdCurrPrd,edi
    jmp saoDone

saoPrd1:
    mov edi,ds:[ebx].sdPrdLinear
    mov es:[edi+8h],eax
;
    mov edi,ds:[ebx].sdPrd2Linear
    mov ds:[ebx].sdCurrPrd,edi
    jmp saoDone

saoStop:
    mov al,es:srControl
    and al,NOT 2
    mov es:srControl,al
    and ds:[ebx].sdFlags,NOT STREAM_FLAG_RUNNING
        
saoDone:        
    popad
    pop gs
    pop fs
    pop es
    pop ds    
    ret
send_audio_out  Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugStream
;
;           DESCRIPTION:    Debug stream
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DebugStream_

DebugStream_    Proc near
    int 3
    mov ax,SEG data
    mov ds,ax
    mov ebx,ds:OutputFunction
    shl ebx,1
    mov ds,ds:[ebx].HdaArr
;
    mov bx,ds:InStreamCnt
    movzx ebx,bx
    shl ebx,6
    add ebx,OFFSET StreamArr
    mov es,ds:[ebx].sdSel
    mov fs,ds:HdaSel
    int 3    
    ret
DebugStream_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddFunction
;
;       DESCRIPTION:    Add HDA function
;
;       PARAMETERS:     BX      Bus/device
;                       CH      Function
;                       EAX     Register base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddFunction  Proc near
    push ds
    push es
    pushad
;    
    push eax
    mov eax,SIZE hda_seg
    AllocateSmallGlobalMem
    movzx eax,ds:HdaCount
    shl eax,1
    mov ds:[eax].HdaArr,es
    inc ds:HdaCount
    mov ax,es
    mov ds,ax
;    
    mov ds:HdaSel,0
    mov ds:Req,0
    mov ds:CodecThread,0
;
    call SetupInts
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    xor ebx,ebx
    or ax,803h
    SetPageEntry
;
    push ecx
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    pop ecx
    mov ds:HdaLinear,edx
    mov ds:HdaSel,bx
;
    popad
    pop es
    pop ds
    ret
AddFunction Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPciAdapter
;
;           DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:     
;
;           RETURNS:        NC          Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPciAdapter  Proc near
    mov ax,SEG data
    mov ds,ax
    mov ds:HdaCount,0
;    
    xor ax,ax
    mov bh,4
    mov bl,3
    xor ch,ch
    FindPciClass
    jc init_pci_done
;
    mov cl,10h
    ReadPciDword
    test al,1
    jnz init_pci_more
;    
    and ax,0FFF0h
    mov ebp,eax
    call AddFunction

init_pci_more:       
    mov dx,1

init_pci_loop:
    mov ax,dx
    mov bh,4
    mov bl,3
    xor ch,ch
    FindPciClass
    jc init_pci_done
;       
    mov cl,10h
    ReadPciDword
    test al,1
    jnz init_pci_next
;    
    and ax,0FFF0h
    cmp eax,ebp
    je init_pci_done
;       
    call AddFunction

init_pci_next:
    inc dx
    jmp init_pci_loop
    
init_pci_done:
    ret
InitPciAdapter  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InitPciHda
;
;           DESCRIPTION:    Init PCI HDA
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitPciHda_

InitPciHda_    Proc near
    push ds
    push es
    pushad
;
    call InitPciAdapter
;
    popad
    pop es
    pop ds
    ret
InitPciHda_       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InitHda
;
;           DESCRIPTION:    Init HDA
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitHda_

InitHda_    PROC near
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET open_audio_out
    mov edi,OFFSET open_audio_out_name
    xor cl,cl
    mov ax,open_audio_out_nr
    RegisterOsGate
;
    mov esi,OFFSET close_audio_out
    mov edi,OFFSET close_audio_out_name
    xor cl,cl
    mov ax,close_audio_out_nr
    RegisterOsGate
;
    mov esi,OFFSET send_audio_out
    mov edi,OFFSET send_audio_out_name
    xor cl,cl
    mov ax,send_audio_out_nr
    RegisterOsGate
;
    mov esi,OFFSET get_fixed_output
    mov edi,OFFSET get_fixed_output_name
    xor dx,dx
    mov ax,get_fixed_audio_output_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_jack_output
    mov edi,OFFSET get_jack_output_name
    xor dx,dx
    mov ax,get_jack_audio_output_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_jack_input
    mov edi,OFFSET get_jack_input_name
    xor dx,dx
    mov ax,get_jack_audio_input_nr
    RegisterBimodalUserGate
;
    popad
    pop es
    pop ds    
    ret
InitHda_    ENDP

code    ENDS

    END
