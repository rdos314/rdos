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
CurrVideoHandle         DW ?
CurrBitmapHandle        DW ?
CurrBitmapOffset        DD ?
CurrBitmapSel           DW ?
CurrBufSize             DW ?
CurrX                   DW ?
CurrPixels              DW ?

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

umRetry:
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
    cmp ecx,SIZE mode_reply_struc
    je umAnswOk
;
    mov ax,25
    WaitMilliSec
    jmp umRetry    

umAnswOk:    
    mov ax,ds:[edi].grm_mode
    cmp ax,ds:CurrMode
    je umDone
;    
    mov bx,ds:CurrVideoHandle
    or bx,bx
    jz umCloseOk
;
    mov ds:CurrVideoHandle,0
;
    mov bx,ds:CurrBitmapHandle
    or bx,bx
    jz umCloseOk
;
    CloseBitmap
    mov ds:CurrBitmapHandle,0        

umCloseOk:
    cmp ax,3
    je umText

umGraphic:
    mov ds:CurrMode,ax 
    mov ax,[edi].grm_row_size
    mov ds:CurrRowSize,ax
;
    xor dx,dx
    mov cx,200h
    div cx
    or dx,dx
    jz umGraphicIncOK
;
    inc ax

umGraphicIncOk:
    mov cx,ax
    mov ax,[edi].grm_row_size
    xor dx,dx
    div cx    
    mov ds:CurrBufSize,ax
;
    shl ax,3
    movzx cx,[edi].grm_bpp
    xor dx,dx
    div cx
    dec ax
    and al,NOT 7
    add ax,8
    mov ds:CurrPixels,ax
;
    mov ax,ds:CurrPixels
    mul cx
    shr ax,3
    mov ds:CurrBufSize,ax        
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
    mov ds:CurrVideoHandle,bx
;
    movzx ax,ds:CurrBpp
    mov cx,ds:CurrPixels
    mov dx,1
    CreateBitmap
    mov ds:CurrBitmapHandle,bx
;
    GetBitmapInfo
    mov ds:CurrBitmapSel,es
    mov ds:CurrBitmapOffset,edi
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
    mov ax,ds:CurrHeight
    or ax,ax
    jz uvDone

uvLoop:
    mov ds:[esi].vr_offset,0
    mov ds:CurrX,0
;    
    mov ax,ds:CurrMode
    cmp ax,3
    jne uvGraph

uvText:    
    mov ds:[esi].vr_size,2 * 80
    mov bx,ds:MailslotHandle
    mov esi,OFFSET ReqBuf
    mov ecx,SIZE video_req_struc
    mov edi,OFFSET ReplyBuf
    mov eax,1000h
    SendMailslot
;
    shr cx,1
    xor ax,ax
    mov dx,ds:[esi].vr_row
    WriteAttributeString
    jmp uvNext

uvGraph:
    mov ax,ds:CurrRowSize
    sub ax,ds:[esi].vr_offset
    or ax,ax
    jz uvNext
;
    cmp ax,ds:CurrBufSize
    jbe uvSizeOk
;
    mov ax,ds:CurrBufSize

uvSizeOk:
    mov ds:[esi].vr_size,ax
;    
    mov bx,ds:MailslotHandle
    mov esi,OFFSET ReqBuf
    mov ecx,SIZE video_req_struc
    mov es,ds:CurrBitmapSel
    mov edi,ds:CurrBitmapOffset
    mov eax,1000h
    SendMailslot
;
    mov di,ds:[esi].vr_row
    shl edi,16
    mov di,ds:CurrX
    mov ax,ds:CurrBitmapHandle
    mov bx,ds:CurrVideoHandle
    mov cx,ds:CurrPixels
    mov dx,1
    xor esi,esi
    Blit
;
    mov esi,OFFSET ReqBuf
    mov ax,ds:[esi].vr_size
    add ds:[esi].vr_offset,ax
    mov ax,ds:CurrPixels
    add ds:CurrX,ax
    jmp uvGraph
            
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
    test cx,alt_pressed
    jz ukNotFunc
;    
    cmp dh,53h
    je ukDel
;    
    cmp dh,3Bh
    jb ukNotFunc
;
    cmp dh,44h
    ja ukNotFunc
;    
    mov esi,OFFSET ReqBuf
    mov ds:[esi].fr_op,GUI_REQ_FOCUS
    mov ds:[esi].fr_key,dh
;    
    mov bx,ds:MailslotHandle
    mov edi,OFFSET ReplyBuf
    mov ecx,SIZE focus_req_struc
    mov eax,1000h    
    SendMailslot
    clc
    jmp ukDone

ukDel:
    mov esi,OFFSET ReqBuf
    mov ds:[esi].gr_op,GUI_REQ_RESET
;    
    mov bx,ds:MailslotHandle
    mov edi,OFFSET ReplyBuf
    mov ecx,SIZE gen_req_struc
    mov eax,1000h    
    SendMailslot
    clc
    jmp ukDone

ukNotFunc:        
    mov esi,OFFSET ReqBuf
    mov ds:[esi].kr_op,GUI_REQ_KEY
    mov ds:[esi].kr_char,ax
    mov ds:[esi].kr_state,cx
    mov ds:[esi].kr_virtual,dl
    mov ds:[esi].kr_scan,dh
;    
    mov bx,ds:MailslotHandle
    mov edi,OFFSET ReplyBuf
    mov ecx,SIZE key_req_struc
    mov eax,1000h    
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
    mov ds:CurrMode,0
    mov ds:CurrRowSize,0
    mov ds:CurrWidth,0
    mov ds:CurrHeight,0
    mov ds:CurrVideoHandle,0
    mov ds:CurrBitmapHandle,0
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
