;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2010, Leif Ekblad
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
; KR203.ASM
; KR203 USB printer driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\os\printer.inc
INCLUDE ..\os\protseg.def
include usb.inc

MAX_OUT_SIZE = 260 * 16

FLAG_ATTACHED          = 1
FLAG_STARTED           = 2
FLAG_CLOSED            = 4
FLAG_WAS_LIFTED        = 8
FLAG_INIT              = 10h

STATUS_PAPER_JAM       = 1h
STATUS_CUTTER_JAM      = 2h
STATUS_NO_PAPER        = 4h
STATUS_HEAD_LIFTED     = 8h
STATUS_FEED_ERROR      = 10h
STATUS_TEMP_ERROR      = 20h
STATUS_PAPER_LOW       = 40h
STATUS_PAPER_PRESENTER = 80h
STATUS_OFFLINE         = 100h

ENQ = 5
ESC = 1Bh
RS = 1Eh
FF = 0Ch
ACK = 06h

cmd_session_struc   STRUC

cs_next         DW ?

cs_req_size     DW ?

cs_reply_min    DW ?
cs_reply_size   DW ?
cs_reply_buf    DW ?      

cs_wait         DW ?

cmd_session_struc   ENDS

usb_printer_struc       STRUC

ups_base_struc  printer_struc <>

usb_printer_struc       ENDS


data    SEGMENT byte public 'DATA'

kr_controller       DW ?
kr_device           DW ?

kr_max_in           DW ?

kr_in_buffer        DW ?
kr_out_buffer       DW ?

kr_in_handle        DW ?
kr_out_handle       DW ?

kr_in_req           DW ?
kr_out_req          DW ?

kr_out_pipe         DB ?
kr_in_pipe          DB ?

kr_section          section_typ <>

kr_temp_status      DW ?
kr_status           DW ?

kr_flag             DB ?

kr_session_thread   DW ?

kr_session_list     DW ?
kr_session_count    DW ?

kr_init_count       DW ?

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

        assume cs:code

        .386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateSessionSel
;
;       DESCRIPTION:    Create a session selector
;
;       PARAMETERS:     CX      Size of send buffer
;
;       RETURNS:        ES      Session sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSessionSel   Proc near
    push eax
    mov ax,SIZE cmd_session_struc
    add ax,cx
    movzx eax,ax
    AllocateSmallGlobalMem
    mov es:cs_next,0
    mov es:cs_req_size,cx
    mov es:cs_reply_min,0
    mov es:cs_reply_size,0
    mov es:cs_reply_buf,0
    mov es:cs_wait,0
    pop eax
    ret
CreateSessionSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeSessionSel
;
;       DESCRIPTION:    Free a session selector
;
;       PARAMETERS:     ES      Session sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeSessionSel   Proc near
    push ax
;    
    mov ax,es:cs_reply_size
    or ax,ax
    jz fssReplyOk
;
    push es
    mov es,es:cs_reply_buf
    FreeMem
    pop es 

fssReplyOk:
    FreeMem
;
    pop ax
    ret
FreeSessionSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateWaitSessionSel
;
;       DESCRIPTION:    Create a wait-for-answer session selector
;
;       PARAMETERS:     CX      Size of send buffer
;
;       RETURNS:        ES      Session sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateWaitSessionSel   Proc near
    push ax
    call CreateSessionSel
    GetThread
    mov es:cs_wait,ax
    pop ax
    ret
CreateWaitSessionSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InsertSessionSel
;
;       DESCRIPTION:    Insert session selector into session list
;
;       PARAMETERS:     DS      Data
;                       ES      Session sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertSessionSel   Proc near
    push bx
    EnterSection ds:kr_section
;    
    inc ds:kr_session_count
    mov bx,ds:kr_session_list
    or bx,bx
    jz issEmpty
;
    push fs

issNext:
    mov fs,bx
    mov bx,fs:cs_next
    or bx,bx
    jnz issNext
;
    mov es:cs_next,0
    mov fs:cs_next,es
    pop fs
    jmp issDone

issEmpty:
    mov es:cs_next,0
    mov ds:kr_session_list,es

issDone:
    LeaveSection ds:kr_section
    mov bx,ds:kr_session_thread
    Signal
    pop bx
    ret
InsertSessionSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetByteParameter
;
;       DESCRIPTION:    Set a byte parameter
;
;       PARAMETERS:     DS      Data
;                       BL      Parameter
;                       AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetByteParameter   Proc near
    push es
    push eax
    push bx
;
    mov bh,al
    mov cx,5
    call CreateSessionSel
;
    mov di,SIZE cmd_session_struc
    mov al,ESC
    stosb
;
    mov al,'&'
    stosb
;
    mov al,'P'
    stosb
;
    mov al,bl
    stosb
;
    mov al,bh
    stosb                
;
    call InsertSessionSel
;
    pop bx
    pop eax
    pop es
    ret
SetByteParameter    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetByteParameter
;
;       DESCRIPTION:    Get a byte parameter
;
;       PARAMETERS:     DS      Data
;                       BL      Parameter
;
;       RETURNS:        AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetByteParameter   Proc near
    push es
    push cx
    push di
;
    mov cx,4
    call CreateWaitSessionSel
    mov es:cs_reply_min,1
;    
    mov di,SIZE cmd_session_struc
    mov al,ESC
    stosb
;
    mov al,ENQ
    stosb
;
    mov al,'P'
    stosb
;
    mov al,bl
    stosb
;
    ClearSignal
    call InsertSessionSel
    WaitForSignal
;
    mov ax,es:cs_reply_size
    cmp ax,1
    stc
    jne gbpFree
;
    push es
    mov es,es:cs_reply_buf
    mov al,es:[0]
    pop es
    clc

gbpFree:
    pushf
    call FreeSessionSel
    popf
;    
    pop di
    pop cx
    pop es
    ret
GetByteParameter    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetWordParameter
;
;       DESCRIPTION:    Set a word parameter
;
;       PARAMETERS:     DS      Data
;                       BL      Parameter
;                       AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetWordParameter   Proc near
    push es
    push eax
    push bx
    push dx
;
    mov dx,ax
    xchg dl,dh
    mov cx,6
    call CreateSessionSel
;
    mov di,SIZE cmd_session_struc
    mov al,ESC
    stosb
;
    mov al,'&'
    stosb
;
    mov al,'P'
    stosb
;
    mov al,bl
    stosb
;
    mov ax,dx
    stosw
;
    call InsertSessionSel
;
    pop dx
    pop bx
    pop eax
    pop es
    ret
SetWordParameter    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetWordParameter
;
;       DESCRIPTION:    Get a word parameter
;
;       PARAMETERS:     DS      Data
;                       BL      Parameter
;
;       RETURNS:        AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetWordParameter   Proc near
    push es
    push cx
    push di
;
    mov cx,4
    call CreateWaitSessionSel
    mov es:cs_reply_min,2
;    
    mov di,SIZE cmd_session_struc
    mov al,ESC
    stosb
;
    mov al,ENQ
    stosb
;
    mov al,'P'
    stosb
;
    mov al,bl
    stosb
;
    ClearSignal
    call InsertSessionSel
    WaitForSignal
;
    mov ax,es:cs_reply_size
    cmp ax,2
    stc
    jne gwpFree
;
    push es
    mov es,es:cs_reply_buf
    mov ax,es:[0]
    xchg al,ah
    pop es
    clc

gwpFree:
    pushf
    call FreeSessionSel
    popf
;    
    pop di
    pop cx
    pop es
    ret
GetWordParameter    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ClearStatus
;
;       DESCRIPTION:    Clear status
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearStatus   Proc near
    mov ds:kr_temp_status,0
    ret
ClearStatus    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NotifyStatus
;
;       DESCRIPTION:    Notify status
;
;       PARAMETERS:     DS      Data
;                       ES      Status
;                       CX      Size of status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stab:
st00 DW 0
st01 DW STATUS_PAPER_JAM
st02 DW STATUS_CUTTER_JAM
st03 DW STATUS_NO_PAPER
st04 DW STATUS_HEAD_LIFTED
st05 DW STATUS_FEED_ERROR
st06 DW STATUS_TEMP_ERROR
st07 DW 0
st08 DW 0
st09 DW 0
st10 DW 0
st11 DW 0
st12 DW 0
st13 DW 0
st14 DW 0
st15 DW 0
st16 DW 0
st17 DW 0
st18 DW 0
st19 DW STATUS_PAPER_LOW
st20 DW STATUS_PAPER_PRESENTER

NotifyStatus   Proc near
    push ax
    push bx
    push di
;
    xor di,di
    or cx,cx
    jz nsDone
    
nsNext:
    mov al,es:[di]
    cmp al,15h
    jne nsDone
;
    sub cx,1
    jz nsDone
;
    inc di
    movzx bx,byte ptr es:[di]
    add bx,bx
    mov ax,word ptr cs:[bx].stab
    or ds:kr_temp_status,ax
;
    inc di    
    sub cx,1
    jnz nsNext

nsDone:
    pop di
    pop bx
    pop ax
    ret
NotifyStatus    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UpdateStatus
;
;       DESCRIPTION:    Update printer status
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateStatus   Proc near
    push es
    push cx
    push di
;
    call ClearStatus
;
    mov bx,ds:kr_out_req
    mov es,ds:kr_out_buffer
    xor di,di
;    
    mov al,ESC
    stosb
;
    mov al,ENQ
    stosb
;
    mov al,1
    stosb
;
    test ds:kr_flag,FLAG_ATTACHED
    jz dsOffline
;    
    mov cx,3
    StartUsbReq
;
    xor dx,dx
    mov bx,ds:kr_in_req
    IsUsbReqStarted
    jnc dsStatusLoop
;
    StartUsbReq

dsStatusLoop:
    mov ax,5
    WaitMilliSec
;
    test ds:kr_flag,FLAG_ATTACHED
    jz dsOffline
;
    mov bx,ds:kr_in_req
    IsUsbReqReady
    jc dsStatusDone
;
    GetUsbReqData
    mov es,ds:kr_in_buffer
    call NotifyStatus
;
    StartUsbReq
    mov dx,1
    jmp dsStatusLoop

dsStatusDone:    
    or dx,dx
    jnz dsStatusOk

dsOffline:    
    or ds:kr_temp_status,STATUS_OFFLINE

dsStatusOk:
    mov ax,ds:kr_temp_status
    mov ds:kr_status,ax
;    
    pop di
    pop cx
    pop es
    ret
UpdateStatus    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DoHardReset
;
;       DESCRIPTION:    Do hard RESET
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoHardReset   Proc near
    push es
    push cx
    push di
;
    mov bx,ds:kr_out_req
    mov es,ds:kr_out_buffer
    xor di,di
;    
    mov al,ESC
    stosb
;
    mov al,'?'
    stosb
;    
    mov cx,2
    StartUsbReq
;    
    mov ax,250
    WaitMilliSec
;    
    pop di
    pop cx
    pop es
    ret
DoHardReset    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DoSession
;
;       DESCRIPTION:    Perform session
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoSession   Proc near
    push es
    push ax

dsLoop:    
    mov ax,ds:kr_session_list
    or ax,ax
    jz dsDone
;
    EnterSection ds:kr_section
    mov es,ds:kr_session_list
    mov ax,es:cs_next
    mov ds:kr_session_list,ax
    dec ds:kr_session_count
    LeaveSection ds:kr_section
;
    test ds:kr_flag,FLAG_ATTACHED
    jz dsCheckRead
;    
    push ds
    push es
    pusha
;    
    mov cx,10
    mov bx,ds:kr_out_req
    IsUsbReqStarted
    jc dsWriteDo

dsWriteWait:    
    IsUsbReqReady
    jnc dsWriteDo
;
    test ds:kr_flag,FLAG_ATTACHED
    jz dsWritePop
;
    mov ax,5
    WaitMilliSec
    loop dsWriteWait
;
    jmp dsWritePop

dsWriteDo:
    mov ax,es
    mov es,ds:kr_out_buffer
    mov ds,ax
    mov si,SIZE cmd_session_struc
    xor di,di
    mov cx,ds:cs_req_size
    rep movsb
    mov cx,ds:cs_req_size
    StartUsbReq

dsWritePop:
    popa
    pop es
    pop ds    

dsCheckRead:
    mov ax,es:cs_wait
    or ax,ax
    jz dsFree
;
    push bx
    push cx
;
    test ds:kr_flag,FLAG_ATTACHED
    jz dsSignal
;
    mov cx,10

dsReadLoop:
    mov bx,ds:kr_in_req
    IsUsbReqStarted
    jnc dsReadStarted
;
    push es
    StartUsbReq
    pop es

dsReadStarted:    
    mov bx,ds:kr_in_req
    IsUsbReqReady
    jnc dsGetData
;
    test ds:kr_flag,FLAG_ATTACHED
    jz dsSignal
;
    mov ax,5
    WaitMilliSec
    loop dsReadLoop
;
    jmp dsSignal

dsGetData:
    push es
    GetUsbReqData
    pop es
    jc dsSignal
;
    push ds
    push es
    push cx
    push si
    push di
    mov ds,ds:kr_in_buffer
    xor si,si
    mov ax,cx
    cmp ax,es:cs_reply_min
    jae dsAllocReply
;
    mov ax,es:cs_reply_min

dsAllocReply:
    movzx eax,ax
    AllocateSmallGlobalMem
    xor di,di
    rep movsb
    mov ax,es
    pop di
    pop si
    pop cx
    pop es
    pop ds
;
    mov es:cs_reply_buf,ax
    mov es:cs_reply_size,cx

dsReadMore:
    test ds:kr_flag,FLAG_ATTACHED
    jz dsSignal
;
    cmp cx,es:cs_reply_min
    jae dsSignal
;
    mov bx,ds:kr_in_req
    push es
    StartUsbReq
    pop es
;    
    mov ax,5
    WaitMilliSec
;    
    IsUsbReqReady
    jc dsSignal
;
    push es
    GetUsbReqData
    pop es
    jc dsSignal
;
    push ds
    push es
    push cx
    push si
    push di
    mov ds,ds:kr_in_buffer
    xor si,si
    mov di,es:cs_reply_size
    mov ax,di
    add ax,cx
    cmp ax,es:cs_reply_min
    jbe dsCopyMore
;
    mov cx,es:cs_reply_min
    sub cx,di

dsCopyMore:    
    mov es,es:cs_reply_buf
    rep movsb
    pop di
    pop si
    pop cx
    pop es
    pop ds
;
    add es:cs_reply_size,cx
    mov cx,es:cs_reply_size
    jmp dsReadMore

dsSignal:
    mov bx,es:cs_wait
    Signal
    pop cx
    pop bx
    jmp dsLoop

dsFree:
    call FreeSessionSel
    jmp dsLoop

dsDone:
    pop ax
    pop es
    ret
DoSession   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NotifyUsbData
;
;       DESCRIPTION:    Handle incoming data
;
;       PARAMETERS:     DS      SEG data
;                       CX      Size
;                       ES      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyUsbData   Proc near
    int 3
    ret
NotifyUsbData   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ClearReceiver
;
;       DESCRIPTION:    Clear receiver
;
;       PARAMETERS:     DS      SEG data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearReceiver    Proc near
    mov bx,ds:kr_in_req
    IsUsbReqStarted
    jnc crLoop

    StartUsbReq
    mov ax,50
    WaitMilliSec

crLoop:
    IsUsbReqReady
    jc crDone
;
    push es
    GetUsbReqData
    pop es
    jc crDone
;
    StartUsbReq
;
    mov ax,50
    WaitMilliSec
    jmp crLoop

crDone:
    ret
ClearReceiver    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OpenPipes
;
;               DESCRIPTION:    Open USB pipes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPipes   Proc near
    movzx eax,ds:kr_max_in
    AllocateSmallGlobalMem
    mov ds:kr_in_buffer,es
;
    mov eax,MAX_OUT_SIZE
    AllocateSmallGlobalMem
    mov ds:kr_out_buffer,es
;
    mov bx,ds:kr_controller
    mov ax,ds:kr_device
    mov dl,ds:kr_in_pipe
    OpenUsbPipe
    mov ds:kr_in_handle,bx
;
    CreateUsbReq
    mov ds:kr_in_req,bx    
    mov cx,ds:kr_max_in
    mov es,ds:kr_in_buffer
    AddReadUsbDataReq
;
    mov bx,ds:kr_controller
    mov ax,ds:kr_device
    mov dl,ds:kr_out_pipe
    OpenUsbPipe    
    mov ds:kr_out_handle,bx
;
    CreateUsbReq
    mov ds:kr_out_req,bx
    mov cx,MAX_OUT_SIZE
    mov es,ds:kr_out_buffer
    AddWriteUsbDataReq
;
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
    mov bx,ds:kr_in_req
    CloseUsbReq
    mov ds:kr_in_req,0
;
    mov bx,ds:kr_in_handle
    CloseUsbPipe    
    mov ds:kr_in_handle,0
;
    mov bx,ds:kr_out_req
    CloseUsbReq
    mov ds:kr_out_req,0
;
    mov bx,ds:kr_out_handle
    CloseUsbPipe    
    mov ds:kr_out_handle,0
;
    mov es,ds:kr_in_buffer
    mov es,ds:kr_in_buffer
    FreeMem    
    mov ds:kr_in_buffer,0
;
    mov es,ds:kr_out_buffer
    FreeMem    
    mov ds:kr_out_buffer,0
;
    lock or ds:kr_flag,FLAG_CLOSED
    ret
ClosePipes   Endp

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
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:kr_flag,FLAG_ATTACHED
    clc
    jz ijDone
;    
    mov ax,ds:kr_session_thread
    or ax,ax
    clc
    jz ijDone
;
    mov ax,ds:kr_status
    test ax,STATUS_PAPER_JAM OR STATUS_CUTTER_JAM
    clc
    jz ijDone
;
    stc
    
ijDone:
    pop ax
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
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:kr_flag,FLAG_ATTACHED
    clc
    jz iplDone
;
    mov ax,ds:kr_session_thread
    or ax,ax
    clc
    jz iplDone
;
    mov ax,ds:kr_status
    test ax,STATUS_PAPER_LOW
    clc
    jz iplDone
;
    stc
    
iplDone:
    pop ax
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
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:kr_flag,FLAG_ATTACHED
    clc
    jz ipeDone
;    
    mov ax,ds:kr_session_thread
    or ax,ax
    clc
    jz ipeDone
;
    mov ax,ds:kr_status
    test ax,STATUS_NO_PAPER
    clc
    jz ipeDone
;
    stc
    
ipeDone:
    pop ax
    pop ds
    ret
is_paper_end   Endp

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
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz ioDone
;
    mov ax,ds:kr_session_thread
    or ax,ax
    stc
    jz ioDone
;
    mov ax,ds:kr_status
    test ax,STATUS_FEED_ERROR OR STATUS_TEMP_ERROR OR STATUS_OFFLINE
    clc
    jz ioDone
;
    stc
    
ioDone:
    pop ax
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
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:kr_flag,FLAG_ATTACHED
    clc
    jz ihlDone
;    
    mov ax,ds:kr_session_thread
    or ax,ax
    clc
    jz ihlDone
;
    mov ax,ds:kr_status
    test ax,STATUS_HEAD_LIFTED
    clc
    jz ihlDone
;
    stc
    
ihlDone:
    pop ax
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
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:kr_flag,FLAG_ATTACHED
    clc
    jz hppDone
;
    mov ax,ds:kr_session_thread
    or ax,ax
    clc
    jz hppDone
;
    mov ax,ds:kr_status
    test ax,STATUS_PAPER_PRESENTER
    clc
    jz hppDone
;
    stc
    
hppDone:
    pop ax
    pop ds
    ret
has_paper_in_presenter   Endp

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
    push ds
    push es
    push ax
    push cx
    push di
;
    mov ax,SEG data
    mov ds,ax
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz ptDone
;
    mov ax,ds:kr_session_thread
    or ax,ax
    stc
    jz ptDone
;    
    mov cx,3
    call CreateWaitSessionSel
;    
    mov di,SIZE cmd_session_struc
    mov al,ESC
    stosb
;
    mov al,'P'
    stosb
;
    mov al,0
    stosb
;
    call InsertSessionSel
    clc

ptDone:    
    pop di
    pop cx
    pop ax
    pop es
    pop ds
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
    push ds
    push ax
    push cx
;
    mov ax,SEG data
    mov ds,ax
;
    mov bl,69
    call GetByteParameter    
    jc create_bitmap_done
;
    mov cl,8
    mul cl
    mov cx,ax
    mov ax,1
    CreateBitmap
    clc

create_bitmap_done:    
    pop cx
    pop ax
    pop ds
    ret
create_bitmap    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PrintOneLine
;
;       DESCRIPTION:    Print a single line
;
;       PARAMETERS:     DS      Data
;                       FS:ESI  Bitmap data
;                       CX      Width in bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PrintOneLine   Proc near
    push ds
    push es
    pushad

poWait: 
    mov ax,ds:kr_session_count
    cmp ax,16
    jb poDo
;
    mov ax,5
    WaitMilliSec
;
    test ds:kr_flag,FLAG_ATTACHED
    jz poDone
;        
    jmp poWait

poDo:
    push cx
    add cx,5
    call CreateSessionSel
    pop cx
;
    mov edi,SIZE cmd_session_struc
    mov al,ESC
    stosb
;    
    mov al,'S'
    stosb
;    
    mov al,cl
    add al,2
    stosb
;
    mov al,0
    stosb
;
    mov al,80h
    stosb

poCopy:
    lods byte ptr fs:[esi]
    not al
    mov ah,al
    xor al,al
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    stosb
    loop poCopy
;        
    call InsertSessionSel

poDone:
    popad
    pop es
    pop ds    
    ret
PrintOneLine    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PrintLine16
;
;       DESCRIPTION:    Print 16 lines
;
;       PARAMETERS:     DS      Data
;                       FS:ESI  Bitmap data
;                       CX      Width in bytes (of single line)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PrintLine16   Proc near
    push ds
    push es
    pushad

p16Wait: 
    mov ax,ds:kr_session_count
    cmp ax,16
    jb p16Do
;
    mov ax,1
    WaitMilliSec
;
    test ds:kr_flag,FLAG_ATTACHED
    jz p16Done
;    
    jmp p16Wait

p16Do:
    push cx
    add cx,5
    shl cx,4
    call CreateSessionSel
    pop cx
;
    mov edi,SIZE cmd_session_struc
    mov dx,16

p16YCopy:    
    mov al,ESC
    stosb
;    
    mov al,'S'
    stosb
;    
    mov al,cl
    add al,2
    stosb
;
    mov al,0
    stosb
;
    mov al,80h
    stosb
;
    push cx    

p16Copy:
    lods byte ptr fs:[esi]
    not al
    mov ah,al
    xor al,al
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    stosb
    loop p16Copy
;
    pop cx    
;      
    sub dx,1
    jnz p16YCopy
;
    call InsertSessionSel

p16Done:
    popad
    pop es
    pop ds    
    ret
PrintLine16    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ForcePrint
;
;       DESCRIPTION:    Force printout
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ForcePrint   Proc near
    push es
    push ax
    push cx
    push di
;
    mov cx,2
    call CreateSessionSel
;
    mov di,SIZE cmd_session_struc
    mov al,ESC
    stosb
;    
    mov al,'p'
    stosb
;    
    call InsertSessionSel
;
    pop di
    pop cx
    pop ax
    pop es
    ret
ForcePrint    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendCut
;
;       DESCRIPTION:    Send cut command
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCut   Proc near
    push es
    push ax
    push cx
    push di
;
    mov cx,2
    call CreateSessionSel
;
    mov di,SIZE cmd_session_struc
    mov al,ESC
    stosb
;
    mov al,RS
    stosb
;    
    call InsertSessionSel
;
    pop di
    pop cx
    pop ax
    pop es
    ret
SendCut    Endp

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
    push fs
    pushad
;
    mov ax,SEG data
    mov ds,ax
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz print_bitmap_done
;
    mov ax,ds:kr_session_thread
    or ax,ax
    stc
    jz print_bitmap_done
;
    GetBitmapInfo
    jc print_bitmap_done
;
    cmp al,1
    jne print_bitmap_done
;
    or dx,dx
    jz print_bitmap_done    
;    
    mov ax,es
    mov fs,ax
    movzx ecx,si
    mov esi,edi
    xor bp,bp

print_bitmap_loop:
    cmp dx,16
    jb print_bitmap_one
;
    inc bp
    cmp bp,16
    jne print_bitmap16
;
    mov bl,8
    call GetByteParameter    
    jnc print_bitmap_wait
;
    mov al,50    

print_bitmap_wait:
    call ForcePrint
    push cx
    push dx
    movzx cx,al
    mov ax,32000
    xor dx,dx
    div cx
    pop dx
    pop cx
    add ax,10
    WaitMilliSec
    xor bp,bp
;
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz print_bitmap_done

print_bitmap16:
    call PrintLine16
    mov eax,ecx
    shl eax,4
    add esi,eax
    sub dx,16
    jnz print_bitmap_loop    
;
    jmp print_bitmap_cut

print_bitmap_one:
    call PrintOneLine
    add esi,ecx
    sub dx,1
    jnz print_bitmap_loop

print_bitmap_cut:
    call ForcePrint
;
    mov bl,8
    call GetByteParameter    
    jnc print_bitmap_fwait
;
    mov al,50    

print_bitmap_fwait:
    call ForcePrint
    call SendCut
        
print_bitmap_done:
    popad
    pop fs
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
    push ds
    push es
    push ax
    push bx
    push cx
    push di
;
    mov bl,al
    mov ax,SEG data
    mov ds,ax
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz present_media_done
;
    mov ax,ds:kr_session_thread
    or ax,ax
    stc
    jz present_media_done
;    
    mov cx,3
    call CreateWaitSessionSel
;    
    mov di,SIZE cmd_session_struc
    mov al,ESC
    stosb
;
    mov al,FF
    stosb
;
    mov al,bl
    stosb
;
    call InsertSessionSel
    clc

present_media_done:    
    pop di
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
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
    push ds
    push es
    push ax
    push cx
    push di
;
    mov ax,SEG data
    mov ds,ax
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz eject_media_done
;
    mov ax,ds:kr_session_thread
    or ax,ax
    stc
    jz eject_media_done
;    
    mov cx,1
    call CreateWaitSessionSel
;    
    mov di,SIZE cmd_session_struc
    mov al,ENQ
    stosb
;
    call InsertSessionSel
    clc

eject_media_done:    
    pop di
    pop cx
    pop ax
    pop es
    pop ds
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
    push ds
    push es
    push ax
    push cx
    push di
;
    mov ax,SEG data
    mov ds,ax
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz wait_for_print_done
;
    mov ax,ds:kr_session_thread
    or ax,ax
    stc
    jz wait_for_print_done
;    
    mov cx,3
    call CreateWaitSessionSel
;    
    mov di,SIZE cmd_session_struc
    mov al,ESC
    stosb
;    
    mov al,ACK
    stosb
;    
    mov al,0FEh
    stosb
;
    call InsertSessionSel
    clc
    
wait_for_print_done:
    pop di
    pop cx
    pop ax
    pop es
    pop ds
    ret
wait_for_print    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StatusTimeout
;
;       DESCRIPTION:    Timer that signals control thread in order to read status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StatusTimeout  Proc far
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:kr_session_thread
    or bx,bx
    jz stDone
;    
    Signal    
;    
    add eax,1193000 * 2 ; 2s to next call
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET StatusTimeout
    mov bx,ds:kr_session_thread
    StartTimer

stDone:    
    retf32
StatusTimeout  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           InitKrThread
;
;               DESCRIPTION:    Init KR203 printer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread_name  DB 'Init KR203', 0

init_thread Proc far
    mov ax,SEG data
    mov ds,ax
    mov ds:kr_init_count,0

init_thread_retry:
    mov ax,ds:kr_init_count
;    inc ax
    cmp ax,20
    jb init_thread_do
;
    call DoHardReset
    xor ax,ax    

init_thread_do:
    mov ds:kr_init_count,ax
;        
    mov ax,2500
    WaitMilliSec
;    
    mov bl,6
    mov ax,250
    call SetWordParameter
;    
    mov bl,7
    mov ax,1000
    call SetWordParameter
;    
    mov bl,8
    mov al,75
    call SetByteParameter
;    
    mov bl,65
    mov al,0
    call SetByteParameter
;
    mov bl,66
    mov al,0
    call SetByteParameter
;
    mov bl,65
    call GetByteParameter
    jc init_thread_retry
;
    or al,al
    jnz init_thread_retry
;
    mov bl,66
    call GetByteParameter
    jc init_thread_retry
;
    or al,al
    jnz init_thread_retry
;
    lock and ds:kr_flag, NOT FLAG_INIT
    ret
init_thread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           Kr203Thread
;
;               DESCRIPTION:    Printer handler thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kr203_thread_name  DB 'KR203', 0

kr203_thread:
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:kr_session_thread,ax
;
    mov eax,SIZE usb_printer_struc
    AllocateSmallGlobalMem
    mov es:printer_device,0
;    
    mov ax,ds:kr_controller
    mov dx,ds:kr_device
    push ds
    mov bx,es
    mov ds,bx
    AddPrinter
    pop ds
;
    mov word ptr es:pr_jammed_proc,OFFSET is_jammed
    mov word ptr es:pr_jammed_proc+2,cs
;    
    mov word ptr es:pr_paper_low_proc,OFFSET is_paper_low
    mov word ptr es:pr_paper_low_proc+2,cs
;    
    mov word ptr es:pr_paper_end_proc,OFFSET is_paper_end
    mov word ptr es:pr_paper_end_proc+2,cs
;    
    mov word ptr es:pr_ok_proc,OFFSET is_ok
    mov word ptr es:pr_ok_proc+2,cs
;    
    mov word ptr es:pr_head_lifted_proc,OFFSET is_head_lifted
    mov word ptr es:pr_head_lifted_proc+2,cs
;    
    mov word ptr es:pr_paper_in_presenter_proc,OFFSET has_paper_in_presenter
    mov word ptr es:pr_paper_in_presenter_proc+2,cs
;    
    mov word ptr es:pr_print_test_proc,OFFSET print_test
    mov word ptr es:pr_print_test_proc+2,cs
;    
    mov word ptr es:pr_create_bitmap_proc,OFFSET create_bitmap
    mov word ptr es:pr_create_bitmap_proc+2,cs
;    
    mov word ptr es:pr_print_bitmap_proc,OFFSET print_bitmap
    mov word ptr es:pr_print_bitmap_proc+2,cs
;    
    mov word ptr es:pr_present_media_proc,OFFSET present_media
    mov word ptr es:pr_present_media_proc+2,cs
;    
    mov word ptr es:pr_eject_media_proc,OFFSET eject_media
    mov word ptr es:pr_eject_media_proc+2,cs
;    
    mov word ptr es:pr_wait_for_print_proc,OFFSET wait_for_print
    mov word ptr es:pr_wait_for_print_proc+2,cs
;    
    GetSystemTime
    add eax,1193000 * 2  ; 2s
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET StatusTimeout
    mov bx,ds:kr_session_thread
    mov cx,ds       
    StartTimer

krRestart:
    mov ax,1000
    WaitMilliSec
;
    call OpenPipes
    call ClearReceiver
;    
    lock or ds:kr_flag, FLAG_INIT
    lock or ds:kr_status,STATUS_OFFLINE
;    
    mov dx,cs
    mov ds,dx
    mov es,dx
    mov di,OFFSET init_thread_name
    mov si,OFFSET init_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    mov ax,SEG data
    mov ds,ax
    
krLoop:
    test ds:kr_flag,FLAG_ATTACHED
    jz krDetached

krDoSession:
    call DoSession
;
    test ds:kr_flag,FLAG_INIT
    jz krDoStatus
;
    lock or ds:kr_status,STATUS_OFFLINE
;
    mov ax,50
    WaitMilliSec
    jmp krLoop        

krDoStatus:
    call UpdateStatus
;    
    test ds:kr_status,STATUS_CUTTER_JAM
    jz krClearCutter
;
    test ds:kr_status,STATUS_HEAD_LIFTED
    jnz krSetLifted
;
    test ds:kr_flag,FLAG_WAS_LIFTED
    jz krClearDone
;
    mov ax,1000
    WaitMilliSec
;    
    call DoHardReset
    jmp krClearCutter

krSetLifted:
    lock or ds:kr_flag,FLAG_WAS_LIFTED
    jmp krClearDone

krClearCutter:
    lock and ds:kr_flag,NOT FLAG_WAS_LIFTED

krClearDone:    
    mov bx,ds:kr_session_list
    or bx,bx
    jnz krLoop

krWait:    
    WaitForSignal
    jmp krLoop
        
krDetached:
    mov ax,ds:kr_session_list
    or ax,ax
    jz krDetachClose
;
    EnterSection ds:kr_section
    mov es,ds:kr_session_list
    mov ax,es:cs_next
    mov ds:kr_session_list,ax
    dec ds:kr_session_count
    LeaveSection ds:kr_section
;
    call FreeSessionSel
    xor ax,ax
    mov es,ax
    jmp krDetached

krDetachClose:
    call ClosePipes

krWaitAttach:
    test ds:kr_flag,FLAG_ATTACHED
    jnz krRestart
;
    WaitForSignal
    jmp krWaitAttach        
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenPrinterPipes
;
;       description:    Create printer pipes
;
;       PARAMETERS:     AL      Device address
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
    movzx ax,al
    mov ds:kr_controller,bx
    mov ds:kr_device,ax
    mov ds:kr_out_pipe,0
    mov ds:kr_in_pipe,0
    mov ds:kr_max_in,0
    mov ds:kr_session_list,0
    mov ds:kr_session_count,0
;
    lock or ds:kr_flag,FLAG_ATTACHED
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
    mov ds:kr_out_pipe,cl
    jmp opDescrNext

opBulkIn:
    and cl,8Fh
    mov ds:kr_in_pipe,cl
    mov ax,es:[di].ued_maxsize
    mov ds:kr_max_in,ax
    
opDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb opDescrLoop    
        
opDescrDone:
    mov al,ds:kr_in_pipe
    or al,al
    jz opDone
;    
    mov al,ds:kr_out_pipe
    or al,al
    jz opDone
;    
    test ds:kr_flag,FLAG_STARTED
    jnz opDone
;
    lock or ds:kr_flag,FLAG_STARTED    
;
    mov dx,cs
    mov ds,dx
    mov es,dx
    mov di,OFFSET kr203_thread_name
    mov si,OFFSET kr203_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
    
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
;                       AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

aTab:
a00     DW 0A5Fh,       00B3h   ; KR203, app mode

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
    mov dl,es:ucd_config_id
    ConfigUsbDevice
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
    retf32
usb_attach  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           usb_detach
;
;               description:    USB detach callback
;
;               Parameters:     BX      Controller #
;                       AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    mov si,SEG data
    mov ds,si
    test ds:kr_flag,FLAG_ATTACHED
    jz udDone
;    
    cmp al,byte ptr ds:kr_device
    jne udDone
;
    cmp bx,ds:kr_controller
    jne udDone
;
    mov ax,5
    WaitMilliSec
;        
    mov cx,100
    lock and ds:kr_flag,NOT FLAG_ATTACHED

udWaitLoop:
;    
    mov bx,ds:kr_session_thread
    Signal
;
    mov ax,5
    WaitMilliSec
;
    test ds:kr_flag,FLAG_CLOSED
    jnz udWaitDone
;
    loop udWaitLoop    

udWaitDone:
    lock and ds:kr_flag,NOT FLAG_CLOSED
    mov ax,25
    WaitMilliSec

udDone:    
    retf32
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
    InitSection ds:kr_section
    mov ds:kr_flag,0
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
