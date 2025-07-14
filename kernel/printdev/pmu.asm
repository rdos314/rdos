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
; pmu.ASM
; Citizen pmu USB printer driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\os\printer.inc
INCLUDE ..\os\protseg.def
include ..\usbdev\usb.inc

        .386p

MAX_OUT_SIZE = 4096

FLAG_ATTACHED          = 1
FLAG_STARTED           = 2
FLAG_CLOSED            = 4
FLAG_INIT              = 8
FLAG_STATUS            = 10h

GS_CH                  = 1Dh

bitmap_sel       STRUC

bs_line_size     DW ?
bs_height        DW ?
bs_data          DB ?

bitmap_sel       ENDS

usb_printer_struc       STRUC

ups_base_struc  printer_struc <>

usb_printer_struc       ENDS

cmd_session_struc   STRUC

cs_next         DW ?

cs_req_size     DW ?

cs_reply_min    DW ?
cs_reply_size   DW ?
cs_reply_buf    DW ?      

cs_wait         DW ?

cmd_session_struc   ENDS


data    SEGMENT byte public 'DATA'

pmu_controller       DW ?
pmu_port             DB ?
pmu_flag             DB ?
pmu_status           DD ?

pmu_dev_handle       DW ?

pmu_max_in           DW ?
pmu_wait             DW ?

pmu_in_buffer        DW ?
pmu_out_buffer       DW ?

pmu_out_pipe         DB ?
pmu_in_pipe          DB ?

pmu_section          section_typ <>

pmu_server_thread    DW ?

pmu_bitmap           DW ?
pmu_pr_thread        DW ?

pmu_error_count      DB ?

pmu_model            DB 32 DUP(?)

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OpenPipes
;
;               DESCRIPTION:    Open USB pipes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPipes   Proc near
    push es
    movzx eax,ds:pmu_max_in
    AllocateSmallGlobalMem
    mov ds:pmu_in_buffer,es
    pop es
;
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_in_pipe
    mov cx,10
    OpenUsbPacketPipe
;
    push es
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_out_pipe
    mov cx,MAX_OUT_SIZE
    mov ax,25
    OpenUsbRawPipe
    mov ds:pmu_out_buffer,es
    pop es
;
    CreateWait
    mov ds:pmu_wait,bx
;
    mov ax,ds:pmu_dev_handle
    mov dl,ds:pmu_in_pipe
    mov ecx,ds
    AddWaitForUsbDevicePipe
    ret
OpenPipes   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               ClosePipes
;
;               DESCRIPTION:    Close pipes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePipes    Proc near
    mov ax,SEG data
    mov ds,ax
    xor ax,ax
    mov es,ax
    mov fs,ax
;
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_in_pipe
    CloseUsbPipe
;
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_out_pipe
    CloseUsbPipe
;
    mov bx,ds:pmu_wait
    CloseWait
;
    mov ds:pmu_out_buffer,0
;
    lock or ds:pmu_flag,FLAG_CLOSED
    ret
ClosePipes   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadAnswer
;
;       DESCRIPTION:    Check status
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CX          Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadAnswer    Proc near
    push es
    push edx
    push edi
    push ebp
;
    mov es,ds:pmu_in_buffer
    xor edi,edi
    mov bp,16

raWaitLoop:
    test ds:pmu_flag,FLAG_ATTACHED
    stc
    jz raDone
;
    mov bx,ds:pmu_wait
    WaitWithoutTimeout
;
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_in_pipe
    GetUsedUsbBuffers
    or cx,cx
    jz raNext
;
    mov es,ds:pmu_in_buffer
    xor edi,edi
    movzx ecx,ds:pmu_max_in
    GetUsbPacketPipe
    jc raDone
;
    or cx,cx
    jnz raHasData

raNext:
    sub bp,1
    jnz raWaitLoop
;
    stc
    jmp raDone
  
raHasData:
    add di,cx

raDataLoop:
    mov bx,ds:pmu_wait
    WaitWithoutTimeout
;
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_in_pipe
    GetUsedUsbBuffers
    or cx,cx
    clc
    jz raDone
;
    movzx ecx,ds:pmu_max_in
    GetUsbPacketPipe
    jc raDone
    or cx,cx
    clc
    jz raDone
;
    add di,cx
    jmp raDataLoop

raDone:
    mov cx,di
;
    pop ebp
    pop edi
    pop edx
    pop es
    ret
ReadAnswer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckStatus
;
;       DESCRIPTION:    Check status
;
;       DS              Printer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckStatus    Proc near
    push es
    pushad
;
    test ds:pmu_flag,FLAG_ATTACHED
    stc
    jz csDone
;
    mov es,ds:pmu_out_buffer
    xor edi,edi
;
    mov al,10h
    stosb
;
    mov al,4
    stosb
;
    mov al,1
    stosb
;
    mov al,10h
    stosb
;
    mov al,4
    stosb
;
    mov al,2
    stosb
;
    mov al,10h
    stosb
;
    mov al,4
    stosb
;
    mov al,3
    stosb
;
    mov al,10h
    stosb
;
    mov al,4
    stosb
;
    mov al,4
    stosb
;
    mov cx,di
;    
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_out_pipe
    PostUsbRawPipe
    jc csFail
;
    call ReadAnswer
    cmp cx,4
    jne csFail
;
    mov es,ds:pmu_in_buffer
    xor bx,bx
    mov eax,es:[bx]
    mov ds:pmu_status,eax
    mov ds:pmu_error_count,0
    jmp csDone

csFail:
    mov al,ds:pmu_error_count
    cmp al,10
    je csDone
;
    inc al
    mov ds:pmu_error_count,al

csDone:
    popad
    pop es
    ret
CheckStatus  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ClearBuffer
;
;       DESCRIPTION:    Clear buffer
;
;       DS              Printer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearBuffer    Proc near
    test ds:pmu_flag,FLAG_ATTACHED
    stc
    jz cbDone
;
    mov es,ds:pmu_out_buffer
    xor edi,edi
;
    mov al,10h
    stosb
;
    mov al,14h
    stosb
;
    mov al,8
    stosb
;
    mov al,1
    stosb
;
    mov al,3
    stosb
;
    mov al,20
    stosb
;
    mov al,1
    stosb
;
    mov al,6
    stosb
;
    mov al,2
    stosb
;
    mov al,8
    stosb
;
    mov cx,di
;    
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_out_pipe
    PostUsbRawPipe
    jc csDone
;
    call ReadAnswer

cbDone:
    ret
ClearBuffer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetPrinterModel
;
;       DESCRIPTION:    Get printer model
;
;       DS              Printer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

def_model DB 'PMU', 0

GetPrinterModel    Proc near
    push ds
    push es
;
    test ds:pmu_flag,FLAG_ATTACHED
    stc
    jz gpmDone
;
    mov es,ds:pmu_out_buffer
    xor edi,edi
;
    mov al,1Dh
    stosb
;
    mov al,49h
    stosb
;
    mov al,67
    stosb
;
    mov cx,di
;    
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_out_pipe
    PostUsbRawPipe
    jc gpmDone
;
    call ReadAnswer
    or cx,cx
    jz gpmFail
;
    mov ax,ds
    mov es,ax
    mov ds,ds:pmu_in_buffer
    mov esi,1
    mov edi,OFFSET pmu_model
    mov ecx,30

gpmCopyName:
    lodsb
    stosb
    or al,al
    jz gpmOk
;
    loop gpmCopyName
;
    xor al,al
    stosb

gpmOk:
    clc
    jmp gpmDone

gpmFail:
    mov ax,ds
    mov es,ax
    mov ax,cs
    mov ds,ax
;
    mov esi,OFFSET def_model
    mov edi,OFFSET pmu_model
    mov ecx,30

gpmDefName:
    lodsb
    stosb
    or al,al
    jz gpmOk
;
    loop gpmDefName
;
    xor al,al
    stosb
;
    stc

gpmDone:
    pop es
    pop ds
    ret
GetPrinterModel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetPrinterVersion
;
;       DESCRIPTION:    Get printer version
;
;       DS              Printer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPrinterVersion    Proc near
    push ds
    push es
;
    test ds:pmu_flag,FLAG_ATTACHED
    stc
    jz gpvDone
;
    mov es,ds:pmu_out_buffer
    xor edi,edi
;
    mov al,1Dh
    stosb
;
    mov al,49h
    stosb
;
    mov al,65
    stosb
;
    mov cx,di
;    
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_out_pipe
    PostUsbRawPipe
    jc gpvDone
;
    call ReadAnswer
    or cx,cx
    jz gpvDone
;
    mov ax,ds
    mov es,ax
    mov edi,OFFSET pmu_model
    mov ecx,30

gpvScanLoop:
    mov al,es:[edi]
    or al,al
    jz gpvScanOk
;
    inc edi
    loop gpvScanLoop

gpvScanOk:
    or ecx,ecx
    jz gpvDone
;
    mov al,' '
    stosb
    sub ecx,1
    jz gpvPad
;
    mov ds,ds:pmu_in_buffer
    mov esi,1

gpvCopyLoop:
    lodsb
    stosb
;
    or al,al
    jz gpvDone
;
    cmp al,0Ah
    jnz gpvNext
;
    dec edi
    xor al,al
    stosb
    jmp gpvDone

gpvNext:
    loop gpvCopyLoop

gpvPad:
    xor al,al
    stosb

gpvDone:
    pop es
    pop ds
    ret
GetPrinterVersion  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           EnterFunctionMode
;
;       DESCRIPTION:    Enter function setting mode
;
;       DS              Printer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnterFunctionMode    Proc near
    test ds:pmu_flag,FLAG_ATTACHED
    stc
    jz efmDone
;
    mov es,ds:pmu_out_buffer
    xor edi,edi
;
    mov al,1Dh
    stosb
;
    mov al,28h
    stosb
;
    mov al,45h
    stosb
;
    mov al,3
    stosb
;
    mov al,0
    stosb
;
    mov al,1
    stosb
;
    mov al,49h
    stosb
;
    mov al,4Eh
    stosb
;
    mov cx,di
;    
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_out_pipe
    PostUsbRawPipe

efmDone:
    ret
EnterFunctionMode  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LeaveFunctionMode
;
;       DESCRIPTION:    Leave function setting mode
;
;       DS              Printer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LeaveFunctionMode    Proc near
    test ds:pmu_flag,FLAG_ATTACHED
    stc
    jz lfmDone
;
    mov es,ds:pmu_out_buffer
    xor edi,edi
;
    mov al,1Dh
    stosb
;
    mov al,28h
    stosb
;
    mov al,45h
    stosb
;
    mov al,4
    stosb
;
    mov al,0
    stosb
;
    mov al,2
    stosb
;
    mov al,4Fh
    stosb
;
    mov al,55h
    stosb
;
    mov al,54h
    stosb
;
    mov cx,di
;    
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_out_pipe
    PostUsbRawPipe

lfmDone:
    ret
LeaveFunctionMode  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetFunctionSwitch
;
;       DESCRIPTION:    Get function switch
;
;       PARAMETERS:     DS         Printer sel
;                       BL         Setting
;
;       RETURNS:        AL         Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFunctionSwitch    Proc near
    test ds:pmu_flag,FLAG_ATTACHED
    stc
    jz gfsDone
;
    mov es,ds:pmu_out_buffer
    xor edi,edi
;
    mov al,1Dh
    stosb
;
    mov al,28h
    stosb
;
    mov al,45h
    stosb
;
    mov al,2
    stosb
;
    mov al,0
    stosb
;
    mov al,4
    stosb
;
    mov al,bl
    stosb
;
    mov cx,di
;    
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_out_pipe
    PostUsbRawPipe
    jc gfsDone
;
    call ReadAnswer
    cmp cx,8
    jb gfsDone
;
    mov es,ds:pmu_in_buffer
    xor di,di
    xor ah,ah

gfsSkip:
    mov al,es:[di]
    sub al,'0'
    jc gfsNext
;
    cmp al,2
    jc gfsDecode

gfsNext:
    inc di
    dec cx
    cmp cx,8
    jae gfsSkip
;
    stc 
    jmp gfsDone

gfsLoop:
    mov al,es:[di]
    or al,al
    jz gfsOk
;
    sub al,'0'
    jc gfsDone
;
    cmp al,2
    jb gfsDecode
;
    stc
    jmp gfsDone

gfsDecode:
    rcr al,1
    rcl ah,1
    inc di
    loop gfsLoop

gfsOk:
    mov al,ah
    clc

gfsDone:
    ret
GetFunctionSwitch  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetFunctionSwitch
;
;       DESCRIPTION:    Set function switch
;
;       PARAMETERS:     DS         Printer sel
;                       BL         Setting
;                       AL         Value
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetFunctionSwitch    Proc near
    test ds:pmu_flag,FLAG_ATTACHED
    stc
    jz sfsDone
;
    mov es,ds:pmu_out_buffer
    xor edi,edi
;
    push ax
;
    mov al,1Dh
    stosb
;
    mov al,28h
    stosb
;
    mov al,45h
    stosb
;
    mov al,0Ah
    stosb
;
    mov al,0
    stosb
;
    mov al,3
    stosb
;
    mov al,bl
    stosb
;
    pop ax
;
    mov ah,al
    mov cx,8

sfsLoop:
    mov al,'0'
    rcl ah,1
    adc al,0
    stosb
;
    loop sfsLoop
;
    mov cx,di
;    
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_out_pipe
    PostUsbRawPipe

sfsDone:
    ret
SetFunctionSwitch  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendLine
;
;       DESCRIPTION:    Send graphic line
;
;       PARAMETERS:     DS      Printer sel
;                       ES      Bitmap sel
;                       DX      Start height
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendLine    Proc near
    push es
    pushad
;
    push ds
    mov ax,es
    mov es,ds:pmu_out_buffer
    mov ds,ax
;
    xor edi,edi
;
    mov ecx,576
;
    mov al,1Bh
    stosb
;
    mov al,2Ah
    stosb
;
    mov al,21h
    stosb
;
    mov ax,cx
    stosw
;
    movzx edx,dx
    movzx eax,ds:bs_line_size
    mul edx
    add eax,OFFSET bs_data
    mov esi,eax
    xor cx,cx
    movzx edx,ds:bs_line_size

slLoop:
    push esi
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
    not al
    stosb
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
    not al
    stosb
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
;
    bt ds:[esi],cx
    rcl al,1    
    add esi,edx
    not al
    stosb
;
    pop esi
    inc cx
    cmp cx,576
    jne slLoop
;    
    mov cx,di
    pop ds
;    
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_out_pipe
    PostUsbRawPipe
;
    popad
    pop es
    ret
SendLine  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FinishLine
;
;       DESCRIPTION:    Finish line
;
;       PARAMETERS:     DS        Printer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FinishLine    Proc near
    push es
    pushad
;
    mov es,ds:pmu_out_buffer
    xor edi,edi
;
    mov al,1Bh
    stosb
;
    mov al,4Ah
    stosb
;
    xor al,al
    stosb
;
    mov cx,di
;    
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_out_pipe
    PostUsbRawPipe
;
    popad
    pop es
    ret
FinishLine  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendCut
;
;       DESCRIPTION:    Do a full cut + feed
;
;       PARAMETERS:     DS        Printer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCut    Proc near
    push es
    pushad
;
    mov es,ds:pmu_out_buffer
    xor edi,edi
;
    mov al,1Dh
    stosb
;
    mov al,56h
    stosb
;
    mov al,65
    stosb
;
    mov al,200
    stosb
;
    mov cx,di
;    
    mov bx,ds:pmu_dev_handle
    mov dl,ds:pmu_out_pipe
    PostUsbRawPipe
;
    popad
    pop es
    ret
SendCut  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendBitmap
;
;       DESCRIPTION:    Print bitmap
;
;       PARAMETERS:     DS      Printer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendBitmap    Proc near
    xor bp,bp
    xor bx,bx
    xchg bx,ds:pmu_bitmap
    or bx,bx
    jz sbDone
;
    push es
    mov es,bx
;
    xor dx,dx

ptLoop:
    call SendLine
    call FinishLine
;
    mov ax,5
    WaitMilliSec
;
    cmp bp,5
    jne ptNext
;
    xor bp,bp
;
    call CheckStatus
    mov eax,ds:pmu_status
    test eax,2000h
    jnz ptFinish
;
    test eax,20000000h
    jnz ptFinish
;
    mov eax,ds:pmu_status
    test al,8
    jnz ptFinish

ptNext:
    inc bp
;
    add dx,24
    cmp dx,es:bs_height
    jb ptLoop

ptFinish:
    call SendCut
    FreeMem
    pop es
;
    mov bx,ds:pmu_pr_thread
    Signal

sbDone:
    ret
SendBitmap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetPrinterName
;
;       DESCRIPTION:    Get printer name
;
;       PARAMETERS:     DS          Printer sel
;                       ES:EDI      Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


get_printer_name   Proc far
    push ds
    push esi
    push edi
;
    mov ax,SEG data
    mov ds,ax
    mov esi,OFFSET pmu_model

get_pr_name_loop:  
    lodsb  
    stosb
    or al,al
    jnz get_pr_name_loop
;
    pop edi
    pop esi
    pop ds    
    ret
get_printer_name   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsJammed
;
;       DESCRIPTION:    Check if printer is jammed
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Jammed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_jammed   Proc far
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:pmu_flag,FLAG_ATTACHED
    clc
    jz ijDone
;
    mov eax,ds:pmu_status
    test eax,40000h
    stc
    jnz ijDone
;
    clc

ijDone:
    pop eax
    pop ds
    ret
is_jammed   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsPaperLow
;
;       DESCRIPTION:    Check if paper is low
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Low
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_paper_low   Proc far
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:pmu_flag,FLAG_ATTACHED
    clc
    jz iplDone
;
    mov eax,ds:pmu_status
    test eax,0C000000h
    stc
    jnz iplDone
;
    clc

iplDone:
    pop eax
    pop ds
    ret
is_paper_low   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsPaperEnd
;
;       DESCRIPTION:    Check if paper is end
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          End
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_paper_end   Proc far
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:pmu_flag,FLAG_ATTACHED
    clc
    jz ipeDone
;
    mov eax,ds:pmu_status
    test eax,2000h
    stc
    jnz ipeDone
;
    test eax,20000000h
    stc
    jnz ipeDone
;
    mov eax,ds:pmu_status
    test al,8
    stc
    jnz ipeDone
;
    clc

ipeDone:
    pop eax
    pop ds
    ret
is_paper_end   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsCutterJammed
;
;       DESCRIPTION:    Check if cutter is jammed
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Cutter jammed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_cutter_jammed   Proc far
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:pmu_flag,FLAG_ATTACHED
    clc
    jz icjDone
;
    mov eax,ds:pmu_status
    test eax,80000h
    stc
    jnz icjDone
;
    clc

icjDone:
    pop eax
    pop ds
    ret
is_cutter_jammed   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsOk
;
;       DESCRIPTION:    Check if printer is ok (functional)
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        NC          OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_ok   Proc far
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:pmu_flag,FLAG_ATTACHED
    stc
    jz iokDone
;
    mov al,ds:pmu_error_count
    cmp al,10
    jb iokOk
;
    stc
    jmp iokDone

iokOk:
    clc

iokDone:
    pop eax
    pop ds
    ret
is_ok   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsHeadLifted
;
;       DESCRIPTION:    Check if printer head is lifted
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Head lifted
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_head_lifted   Proc far
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:pmu_flag,FLAG_ATTACHED
    clc
    jz ihlDone
;
    mov eax,ds:pmu_status
    test eax,400h
    stc
    jnz ihlDone
;
    clc

ihlDone:
    pop eax
    pop ds
    ret
is_head_lifted   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HasPaperInPresenter
;
;       DESCRIPTION:    Check if printer has paper in presenter
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Paper in presenter
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_paper_in_presenter   Proc far
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:pmu_flag,FLAG_ATTACHED
    clc
    jz hppDone
;
    mov eax,ds:pmu_status
    test eax,40000000h
    stc
    jz hppDone
;
    clc

hppDone:
    pop eax
    pop ds
    ret
has_paper_in_presenter   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HasTempError
;
;       DESCRIPTION:    Check for temperature error
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Temperature error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_temp_error   Proc far
    clc
    ret
has_temp_error   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HasFeedError
;
;       DESCRIPTION:    Check for feed error
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Feed error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_feed_error   Proc far
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:pmu_flag,FLAG_ATTACHED
    clc
    jz hfeDone
;
    mov eax,ds:pmu_status
    test eax,4000h
    stc
    jnz hfeDone
;
    clc

hfeDone:
    pop eax
    pop ds
    ret
has_feed_error   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           print_test
;
;       DESCRIPTION:    Print test page
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_test   Proc far
    ret
print_test    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           create_bitmap
;
;       DESCRIPTION:    Create printer bitmap
;
;       PARAMETERS:     DS      Data
;                       DX      Height
;
;       RETURNS:        BX      Bitmap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_bitmap   Proc far
    push ax
    push cx
    push dx
;
    mov ax,1
    mov cx,576
    CreateBitmap
    clc
;
    pop dx
    pop cx
    pop ax
    ret
create_bitmap    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           print_bitmap
;
;       DESCRIPTION:    Print bitmap
;
;       PARAMETERS:     DS      Data
;                       BX      Bitmap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_bitmap   Proc far
    push ds
    push es
    pushad
;
    GetBitmapInfo
    jc pbDone
;
    cmp al,1
    jne pbDone
;
    or dx,dx
    jz pbDone    
;    
    push edx
;
    mov ax,es
    mov ds,ax
;
    mov ax,dx
    dec ax
    xor dx,dx
    mov cx,24
    div cx
    inc ax
    mul cx
    mov bx,ax
;
    movzx ebp,si
    movzx eax,ax
    mul ebp
    add eax,OFFSET bs_data
;
    pop edx
;
    push eax
    push edx
    movzx eax,dx
    mul ebp
    mov ecx,eax
    pop edx
    pop eax
;
    mov esi,edi
    AllocateSmallGlobalMem
;
    mov es:bs_line_size,bp
    mov es:bs_height,bx
    mov edi,OFFSET bs_data
    rep movsb
;
    sub bx,dx
    jz pbWait
;
    movzx eax,bx
    mul ebp
    movzx ecx,ax
    mov al,-1
    rep stosb

pbWait:
    mov bx,es
;
    mov ax,SEG data
    mov ds,ax
    ClearSignal
    GetThread
    mov ds:pmu_pr_thread,ax
    mov ds:pmu_bitmap,bx
;
    mov bx,ds:pmu_server_thread
    signal
;
    WaitForSignal
    clc

pbDone:
    popad
    pop es
    pop ds
    ret
print_bitmap    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PresentMedia
;
;       DESCRIPTION:    Present media
;
;       PARAMETERS:     DS      Data
;                       AX      Amount in mm to present
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

present_media   Proc far
    ret
present_media    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           EjectMedia
;
;       DESCRIPTION:    Eject media
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eject_media   Proc far
    ret
eject_media    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitForPrint
;
;       DESCRIPTION:    Wait for print to complete
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_print   Proc far
    ret
wait_for_print    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ResetPrinter
;
;       DESCRIPTION:    Reset printer (USB)
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_printer   Proc far
    push ds
    push es
    push ax
    push cx
    push di
;
    mov ax,SEG data
    mov ds,ax
    test ds:pmu_flag,FLAG_ATTACHED
    stc
    jz reset_done
;    
    lock and ds:pmu_flag,NOT FLAG_ATTACHED
    mov bx,ds:pmu_dev_handle
    ResetUsbDevice
    clc

reset_done:    
    pop di
    pop cx
    pop ax
    pop es
    pop ds
    ret
reset_printer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PmuThread
;
;               DESCRIPTION:    Printer handler thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pmu_thread_name  DB 'PMU ', 0

pmu_thread:
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:pmu_server_thread,ax
;
    mov eax,SIZE usb_printer_struc
    AllocateSmallGlobalMem
    mov es:printer_device,0
;    
    mov ax,ds:pmu_controller
    movzx dx,ds:pmu_port
    push ds
    mov bx,es
    mov ds,bx
    AddPrinter
    pop ds
;
    mov es:pr_get_name_proc,OFFSET get_printer_name
    mov es:pr_get_name_proc+4,cs
;
    mov es:pr_jammed_proc,OFFSET is_jammed
    mov es:pr_jammed_proc+4,cs
;    
    mov es:pr_paper_low_proc,OFFSET is_paper_low
    mov es:pr_paper_low_proc+4,cs
;    
    mov es:pr_paper_end_proc,OFFSET is_paper_end
    mov es:pr_paper_end_proc+4,cs
;    
    mov es:pr_cutter_jammed_proc,OFFSET is_cutter_jammed
    mov es:pr_cutter_jammed_proc+4,cs
;    
    mov es:pr_ok_proc,OFFSET is_ok
    mov es:pr_ok_proc+4,cs
;    
    mov es:pr_head_lifted_proc,OFFSET is_head_lifted
    mov es:pr_head_lifted_proc+4,cs
;    
    mov es:pr_paper_in_presenter_proc,OFFSET has_paper_in_presenter
    mov es:pr_paper_in_presenter_proc+4,cs
;    
    mov es:pr_temp_error_proc,OFFSET has_temp_error
    mov es:pr_temp_error_proc+4,cs
;    
    mov es:pr_feed_error_proc,OFFSET has_feed_error
    mov es:pr_feed_error_proc+4,cs
;    
    mov es:pr_print_test_proc,OFFSET print_test
    mov es:pr_print_test_proc+4,cs
;    
    mov es:pr_create_bitmap_proc,OFFSET create_bitmap
    mov es:pr_create_bitmap_proc+4,cs
;    
    mov es:pr_print_bitmap_proc,OFFSET print_bitmap
    mov es:pr_print_bitmap_proc+4,cs
;    
    mov es:pr_present_media_proc,OFFSET present_media
    mov es:pr_present_media_proc+4,cs
;    
    mov es:pr_eject_media_proc,OFFSET eject_media
    mov es:pr_eject_media_proc+4,cs
;    
    mov es:pr_wait_for_print_proc,OFFSET wait_for_print
    mov es:pr_wait_for_print_proc+4,cs
;    
    mov es:pr_reset_proc,OFFSET reset_printer
    mov es:pr_reset_proc+4,cs    

pmuRestart:
    mov bx,ds:pmu_controller
    mov al,ds:pmu_port
    OpenUsbDevice
    mov ds:pmu_dev_handle,bx
    mov ds:pmu_status,0
;
    mov ax,250
    WaitMilliSec
;
    call OpenPipes
;
    call CheckStatus
    mov eax,ds:pmu_status
    test eax,2000h
    jz pmuBufferOk
;
    call ClearBuffer

pmuBufferOk:
    mov eax,ds:pmu_status
    test al,8
    jnz pmuStatusLoop
;
    call GetPrinterModel
    call GetPrinterVersion
;
    mov bl,6
    call GetFunctionSwitch
    jc pmuDetached
;
    cmp al,80h
    je pmuStatusLoop
;
    call EnterFunctionMode
    jc pmuDetached
;
    mov bl,6
    mov al,80h
    call SetFunctionSwitch
    jc pmuDetached

pmuLeaveFunc:
    call LeaveFunctionMode
    jc pmuDetached

pmuStatusLoop:
    mov bx,ds:pmu_dev_handle
    IsUsbDeviceConnected
    jc pmuDetached
;
    test ds:pmu_flag,FLAG_ATTACHED
    jz pmuDetached
;
    call SendBitmap
    call CheckStatus
;
    mov eax,ds:pmu_status
    test eax,2000h
    jz pmuStatusWait
;
    call ClearBuffer

pmuStatusWait:
    GetSystemTime
    add eax,250 * 1193
    adc edx,0
    WaitForSignalWithTimeout
    jmp pmuStatusLoop
        
pmuDetached:
    call ClosePipes
;
    xor bx,bx
    xchg bx,ds:pmu_dev_handle
    CloseUsbDevice

pmuWaitAttach:
    test ds:pmu_flag,FLAG_ATTACHED
    jnz pmuRestart
;
    WaitForSignal
    jmp pmuWaitAttach        
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HexToAscii
;
;   DESCRIPTION:    
;
;   PARAMETERS:     AL      Number to convert
;
;   RETURNS:        AX      Ascii result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HexToAscii      PROC near
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
;
    add al,7

ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
;
    add ah,7

ok_high1:
    add ah,30h
    ret
HexToAscii      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartThread
;
;       DESCRIPTION:    Start thread
;
;       PARAMETERS:     DS      Data seg
;                       AX      Prio
;                       ESI     Entry
;                       EDI     Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartThread Proc near
    push ds
    push es            
;
    push ax
    push esi
;
    mov esi,edi
    mov eax,100h
    AllocateSmallGlobalMem
    xor edi,edi

sfCopyLoop:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz sfCopyDone
;
    stosb
    jmp sfCopyLoop

sfCopyDone:
    mov ax,ds:pmu_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,ds:pmu_port
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;
    pop esi         
;
    mov ebx,ds
    xor edi,edi
    mov eax,cs
    mov ds,eax
    pop ax
    mov ecx,stack0_size
    CreateThread
;
    FreeMem
;
    pop es
    pop ds
    ret
StartThread Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenPrinterPipes
;
;       description:    Create printer pipes
;
;       PARAMETERS:     AL      Device address
;                       AH      Port #
;                       BX      Controller id
;                       DX      Device type
;                       ES:DI   Interface descriptor + endpoints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPrinterPipes Proc near
    push ds
    push es
    pushad
;    
    mov si,SEG data
    mov ds,si
;    
    mov ds:pmu_controller,bx
    mov ds:pmu_port,al
    mov ds:pmu_out_pipe,0
    mov ds:pmu_in_pipe,0
    mov ds:pmu_max_in,0
;
    lock or ds:pmu_flag,FLAG_ATTACHED
;
    movzx cx,es:[di].uid_len
    add di,cx

opDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne opDescrDone
;
    mov cl,es:[di].ued_attrib
    and cl,3
    cmp cl,2
    jne opDescrNext
;
    mov cl,es:[di].ued_address
    test cl,80h    
    jnz opBulkIn

opDescrBulkOut:
    and cl,0Fh
    mov ds:pmu_out_pipe,cl
    jmp opDescrNext

opBulkIn:
    and cl,8Fh
    mov ds:pmu_in_pipe,cl
    mov ax,es:[di].ued_maxsize
    mov ds:pmu_max_in,ax
    
opDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb opDescrLoop    
        
opDescrDone:
    mov al,ds:pmu_in_pipe
    or al,al
    jz opDone
;    
    mov al,ds:pmu_out_pipe
    or al,al
    jz opDone
;    
    test ds:pmu_flag,FLAG_STARTED
    jnz opSignal
;
    lock or ds:pmu_flag,FLAG_STARTED    
;
    mov esi,OFFSET pmu_thread
    mov edi,OFFSET pmu_thread_name
    mov ax,2
    call StartThread
    jmp opDone

opSignal:
    mov bx,ds:pmu_server_thread
    Signal
    
opDone:
    popad
    pop es
    pop ds
    ret
OpenPrinterPipes Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           usb_attach
;
;               description:    USB attach callback
;
;               Parameters:     BX      Controller #
;                               AL      Device port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

aTab:
a00     DW 1D90h,       211Bh   ; PMU

usb_attach  Proc far
    push es
;    
    push ax
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
    pop ax
    xor di,di
    push ax
    GetUsbDevice
    cmp ax,cx
    pop ax
    jne aDone
;
    mov si,es:udd_vendor
    mov di,es:udd_prod

    mov cx,1
    mov bp,OFFSET aTab

aLoop:
    cmp si,cs:[bp]
    jne aNext
;
    cmp di,cs:[bp+2]
    je aFound

aNext:
    add bp,4
    loop aLoop        
;
    jmp aDone    

aFound:
    xor dl,dl
    mov cx,1000h
    xor di,di
    push ax
    GetUsbConfig
    mov cx,ax
    pop ax
    or cx,cx
    jz aDone
;
    push ax
    mov dl,es:ucd_config_id
    ConfigUsbDevice
    pop ax
    jc aDone
;
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

aDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,4
    jne aDescrNext
; 
    call OpenPrinterPipes
    jmp aDone

aDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb aDescrLoop    
    
aDone:
    FreeMem
;
    pop es    
    ret
usb_attach  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           usb_detach
;
;               description:    USB detach callback
;
;               Parameters:     BX      Controller #
;                               AL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    mov si,SEG data
    mov ds,si
    test ds:pmu_flag,FLAG_ATTACHED
    jz udDone
;    
    cmp al,byte ptr ds:pmu_port
    jne udDone
;
    cmp bx,ds:pmu_controller
    jne udDone
;
    mov ax,5
    WaitMilliSec
;        
    mov cx,100
    lock and ds:pmu_flag,NOT FLAG_ATTACHED

udWaitLoop:    
    mov bx,ds:pmu_server_thread
    Signal
;
    mov ax,5
    WaitMilliSec
;
    test ds:pmu_flag,FLAG_CLOSED
    jnz udWaitDone
;
    loop udWaitLoop    

udWaitDone:
    lock and ds:pmu_flag,NOT FLAG_CLOSED
    mov ax,25
    WaitMilliSec

udDone:    
    ret
usb_detach  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   init
;
;               description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
;
    mov ax,SEG data
    mov ds,ax
    InitSection ds:pmu_section
    mov ds:pmu_flag,0
    mov ds:pmu_dev_handle,0
    mov ds:pmu_bitmap,0
    mov ds:pmu_pr_thread,0
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET usb_attach
    HookUsbAttach
;
    mov edi,OFFSET usb_detach
    HookUsbDetach
    clc
    ret
init    Endp


code    ENDS

        END init
