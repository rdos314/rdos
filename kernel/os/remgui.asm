;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; REMGUI.ASM
; Remote GUI interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\user.def
INCLUDE ..\os.inc
INCLUDE ..\user.inc
INCLUDE system.def
INCLUDE ipcgui.inc

    .386p

data    SEGMENT byte public 'DATA'

CurrMode                DW ?
CurrWidth               DW ?
CurrHeight              DW ?
CurrRowSize             DW ?
CurrBpp                 DB ?

MailslotHandle          DW ?
ReqBuf                  DB 16 DUP(?)
ReplyBuf                DB 1000h DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           UpdateMode
;
;               DESCRIPTION:    update video mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMode  Proc near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov es,ax 
;       
    mov bx,ds:MailslotHandle
    mov esi,OFFSET ReqBuf
    mov ecx,SIZE gen_req_struc
    mov edi,OFFSET ReplyBuf
    mov eax,1000h
    mov ds:[esi].gr_op,GUI_REQ_MODE    
    SendMailslot
;
    mov ax,es:[edi].grm_mode
    cmp ax,ds:CurrMode
    je umDone
;
    cmp ax,3
    je umText

umGraphic:
    mov ds:CurrMode,ax 
    mov ax,[edi].grm_row_size
    mov ds:CurrRowSize,ax
;    
    movzx ax,[edi].grm_bpp
    mov ds:CurrBpp,al
;
    mov cx,[edi].grm_width
    mov ds:CurrWidth,cx
;    
    mov dx,[edi].grm_height
    mov ds:CurrHeight,dx
;    
    GetVideoMode
    SetVideoMode
    jmp umDone

umText:
    mov ds:CurrRowSize,2 * 80
    mov ds:CurrWidth,80
    mov ds:CurrHeight,25
    mov ds:CurrMode,ax 
    SetVideoMode

umDone:
    popad
    pop es
    pop ds
    ret
UpdateMode  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           UpdateVideo
;
;               DESCRIPTION:    update video data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateVideo  Proc near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov es,ax 
    mov esi,OFFSET ReqBuf
    mov ds:[esi].vr_row,0
    mov ds:[esi].vr_op,GUI_REQ_VIDEO

uvLoop:
    mov bx,ds:MailslotHandle
    mov esi,OFFSET ReqBuf
    mov ecx,SIZE video_req_struc
    mov edi,OFFSET ReplyBuf
    mov eax,1000h
    SendMailslot
;
    mov ax,ds:CurrMode
    cmp ax,3
    jne uvGraph

uvText:    
    shr cx,1
    xor ax,ax
    mov dx,ds:[esi].vr_row
    WriteAttributeString
    jmp uvNext

uvGraph:
    int 3 

uvNext:  
    inc ds:[esi].vr_row
    mov ax,ds:[esi].vr_row    
    cmp ax,ds:CurrHeight
    je uvDone
;
    jmp uvLoop

uvDone:
    popad
    pop es
    pop ds
    ret
UpdateVideo Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           UpdateKeyboard
;
;               DESCRIPTION:    update keyboard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateKeyboard  Proc near
    push ds
    push es
    pushad
;    
    mov ax,SEG data
    mov ds,ax
    mov es,ax 
;
    ReadKeyEvent
    jc ukDone
;    
    mov edi,OFFSET ReplyBuf
    mov ds:[edi].kr_op,GUI_REQ_KEY
    mov ds:[edi].kr_char,ax
    mov ds:[edi].kr_state,cx
    mov ds:[edi].kr_virtual,dl
    mov ds:[edi].kr_scan,dh
;    
    mov bx,ds:MailslotHandle
    mov esi,OFFSET ReqBuf
    mov ecx,SIZE key_req_struc
    mov eax,10h    
    SendMailslot
    clc

ukDone:
    popad
    pop es
    pop ds
    ret
UpdateKeyboard  Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           DebugThread
;
;               DESCRIPTION:    Debug thread
;
;               PARAMETERS:     EDX     IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rem_gui_name   DB 'Remote GUI', 0
mailslot_name       DB 'GUI',0

rem_gui_process:
    mov ax,44h
    EnableFocus
    SetFocus
;    
    mov ax,SEG data
    mov ds,ax
    mov ds:CurrMode,3
    mov ds:CurrRowSize,2 * 80
    mov ds:CurrWidth,80
    mov ds:CurrHeight,25
;
    or edx,edx
    jz rem_gui_local
;    
    mov ax,cs
    mov es,ax
    mov di,OFFSET mailslot_name
    GetRemoteMailslot
    mov ds:MailslotHandle,bx
    jmp rem_gui_init

rem_gui_local:
    mov ax,cs
    mov es,ax
    mov di,OFFSET mailslot_name
    GetLocalMailslot
    mov ds:MailslotHandle,bx

rem_gui_init: 
    mov ax,SEG data
    mov ds,ax
    mov es,ax

rem_gui_loop:    
    call UpdateMode
    call UpdateVideo
    call UpdateKeyboard
    jnc rem_gui_loop
;
    mov ax,100
    WaitMilliSec
    jmp rem_gui_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           RemoteGui
;
;               DESCRIPTION:    Remote GUI task
;
;               PARAMETERS:     EDX     IP address to debug
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remote_gui_name   DB 'Remote Gui', 0

remote_gui    Proc far
    push ds
    push es
    pusha
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET rem_gui_process
    mov edi,OFFSET rem_gui_name
    mov ecx,stack0_size
    mov ax,5
    CreateProcess
    popa
    pop es
    pop ds
    ret
remote_gui    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_remote
;
;           DESCRIPTION:    Init remote GUI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_remote

init_remote Proc near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET remote_gui
    mov edi,OFFSET remote_gui_name
    xor dx,dx
    mov ax,remote_gui_nr
    RegisterBimodalUserGate
    ret
init_remote    Endp

code    ENDS

    END
