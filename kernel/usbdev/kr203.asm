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
include usb.inc

MAX_OUT_SIZE = 260

STATUS_PAPER_JAM       = 1h
STATUS_CUTTER_JAM      = 2h
STATUS_NO_PAPER        = 4h
STATUS_HEAD_LIFTED     = 8h
STATUS_FEED_ERROR      = 10h
STATUS_TEMP_ERROR      = 20h
STATUS_PAPER_LOW       = 40h
STATUS_PAPER_PRESENTER = 80h

ENQ = 5
ESC = 1Bh

cmd_session_struc   STRUC

cs_next         DW ?

cs_req_size     DW ?

cs_reply_min    DW ?
cs_reply_size   DW ?
cs_reply_buf    DW ?      

cs_wait         DW ?

cmd_session_struc   ENDS

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

kr_status           DW ?

kr_status_section   section_typ <>

kr_session_thread   DW ?

kr_session_list     DW ?

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
    mov ds:kr_status,0
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
    or ds:kr_status,ax
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
    EnterSection ds:kr_status_section    
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
    mov cx,3
    StartUsbReq
;
    mov bx,ds:kr_in_req
    IsUsbReqStarted
    jnc dsStatusLoop
;
    StartUsbReq

dsStatusLoop:
    mov ax,5
    WaitMilliSec
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
    jmp dsStatusLoop

dsStatusDone:    
    LeaveSection ds:kr_status_section    
;    
    pop di
    pop cx
    pop es
    ret
UpdateStatus    Endp

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
    LeaveSection ds:kr_section
;
    push ds
    push es
    pusha
;    
    mov bx,ds:kr_out_req
    mov ax,es
    mov es,ds:kr_out_buffer
    mov ds,ax
    mov si,SIZE cmd_session_struc
    xor di,di
    mov cx,ds:cs_req_size
    rep movsb
    mov cx,ds:cs_req_size
    StartUsbReq
;
    popa
    pop es
    pop ds    
;
    mov ax,es:cs_wait
    or ax,ax
    jz dsFree
;
    push bx
    push cx
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
;   NAME:           Test thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_thread_name  DB 'KR test', 0

test_thread:
    int 3
    mov ax,SEG data
    mov ds,ax

test_loop:
    mov bl,67
    call GetByteParameter  
;
    mov bl,65
    call GetByteParameter  
;
    mov bl,84
    call GetWordParameter  
    jmp test_loop
;
    int 3      

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
    mov ds:kr_session_list,0
;
    mov bl,65
    mov al,0
    call SetByteParameter
;
    mov bl,66
    mov al,0
    call SetByteParameter
;
    ret
OpenPipes   Endp    

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
;
    mov bx,ds:kr_session_thread
    Signal    
;    
    add eax,1193000 * 2 ; 2s to next call
    adc edx,0
    mov bx,cs
    mov es,bx
    mov di,OFFSET StatusTimeout
	mov bx,ds:kr_session_thread
    StartTimer
    ret
StatusTimeout  Endp

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
    GetSystemTime
    add eax,1193000 * 2  ; 2s
    adc edx,0
    mov bx,cs
    mov es,bx
    mov di,OFFSET StatusTimeout
	mov bx,ds:kr_session_thread
	mov cx,ds	
	StartTimer
;
    push ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET test_thread_name
    mov si,OFFSET test_thread
    mov ax,2
    mov cx,100h
    CreateThread
    pop ds
;
    call OpenPipes
    call ClearReceiver

krLoop:
    call DoSession
    call UpdateStatus
;    
    mov bx,ds:kr_session_list
    or bx,bx
    jnz krLoop
;    
    WaitForSignal
    jmp krLoop
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenPrinter
;
;       description:    Create printer pipes
;
;       PARAMETERS:     AL      Device address
;                       BX      Controller id
;                       DX      Device type
;                       ES:DI   Interface descriptor + endpoints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPrinter Proc near
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
    mov dx,cs
    mov ds,dx
    mov es,dx
    mov di,OFFSET kr203_thread_name
    mov si,OFFSET kr203_thread
    mov ax,2
    mov cx,100h
    CreateThread
    
opDone:
    popad
    pop es
    pop ds
    ret
OpenPrinter Endp    

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
    call OpenPrinter
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
;                       AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    int 3
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
    InitSection ds:kr_section
    InitSection ds:kr_status_section
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov di,OFFSET usb_attach
    HookUsbAttach
;
    mov di,OFFSET usb_detach
    HookUsbDetach
    clc
    ret
init    Endp

code    ENDS

        END init
