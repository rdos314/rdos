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

data    SEGMENT byte public 'DATA'

kr_controller   DW ?
kr_device       DW ?

kr_max_out      DW ?
kr_max_in       DW ?

kr_in_buffer    DW ?
kr_out_buffer   DW ?

kr_in_handle    DW ?
kr_out_handle   DW ?

kr_in_req       DW ?
kr_out_req      DW ?

kr_out_pipe     DB ?
kr_in_pipe      DB ?

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

        assume cs:code

        .386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               HandleDevice
;
;               DESCRIPTION:    Handle device
;
;       PARAMETERS:     DS      SEG data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleDevice    Proc near
    mov bx,ds:kr_in_req
    IsUsbReqStarted
    jnc hdReadStarted
;
    StartUsbReq

hdReadStarted:    
    mov bx,ds:kr_in_req
    IsUsbReqReady
    jc hdReadDone
;
    GetUsbReqData
    jc hdReadRestart

hdReadRestart:
    mov bx,ds:kr_in_req
    StartUsbReq

hdReadDone:
    mov bx,ds:kr_out_req
    IsUsbReqStarted
    jc hdCheckWrite
;    
    IsUsbReqReady
    jc hdDone

hdCheckWrite:
    
hdDone:
    xor ax,ax
    mov es,ax
    pop ds
    ret
HandleDevice    Endp

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
    movzx eax,ds:kr_max_out
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
    mov cx,ds:kr_max_out
    mov es,ds:kr_out_buffer
    AddWriteUsbDataReq
;
    ret
OpenPipes   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Kr203Thread
;
;               DESCRIPTION:    Printer handler thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kr203_thread_name  DB 'KR203', 0

kr203_thread:
    int 3
    mov ax,SEG data
    mov ds,ax
    call OpenPipes

krLoop:
    call HandleDevice
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
    mov ds:kr_max_out,0
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
    mov ax,es:[di].ued_maxsize
    mov ds:kr_max_out,ax
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
