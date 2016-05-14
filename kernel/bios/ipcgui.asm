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
; IPCGUI.ASM
; IPC based GUI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\video.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ipcgui.inc

.386p

video_focus_seg STRUC

v_handle        DW ?

video_focus_seg ENDS

data    SEGMENT byte public 'DATA'

ReplyBuf                DB 1000h DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleInvalid
;
;           DESCRIPTION:    Handle unknown function
;
;           PARAMETERS:     ES:EDI      Msg
;                           ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_invalid  Proc near
    xor ecx,ecx
    ReplyMailslot
    ret
handle_invalid  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleMode
;
;           DESCRIPTION:    Handle video mode function
;
;           PARAMETERS:     ES:EDI      Msg
;                           ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_mode  Proc near
    push ds
    push es
    push edi
    push ecx
;    
    mov ax,video_focus_sel
    mov ds,ax
    mov ds,ds:v_handle
;
    mov cx,SEG data
    mov es,cx
    mov edi,OFFSET ReplyBuf
    mov ecx,SIZE mode_reply_struc
;    
    mov ax,ds:v_mode
    mov es:[edi].grm_mode,ax
    mov ax,ds:v_width
    mov es:[edi].grm_width,ax
    mov ax,ds:v_height
    mov es:[edi].grm_height,ax
    mov ax,ds:v_row_size
    mov es:[edi].grm_row_size,ax
    mov al,ds:v_bpp
    mov es:[edi].grm_bpp,al
    ReplyMailslot
;
    pop ecx
    pop edi
    pop es    
    pop ds
    ret
handle_mode  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleVideo
;
;           DESCRIPTION:    Handle video data function
;
;           PARAMETERS:     ES:EDI      Msg
;                           ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_video  Proc near
    push ds
    push es
    push edi
    push ecx
;    
    mov ax,video_focus_sel
    mov ds,ax
    mov ds,ds:v_handle
;
    movzx ecx,ds:v_row_size
;
    mov ax,ds:v_mode
    cmp ax,3
    je handle_text_video

handle_graph_video:
    mov esi,ds:v_phys_base
    movzx eax,ds:v_row_size
    movzx edx,es:[edi].vr_row
    mul edx
    add esi,eax
    movzx eax,es:[edi].vr_offset
    add esi,eax
    movzx ecx,es:[edi].vr_size
;
    mov ax,flat_sel
    mov ds,ax
    mov ax,SEG data
    mov es,ax
    mov edi,OFFSET ReplyBuf
;
    push ecx
    push edi
    rep movs es:[edi],ds:[esi]        
    pop edi
    pop ecx
;    
    ReplyMailslot
    jmp handle_video_end
    
handle_text_video:    
    mov ecx,2 * 80
    mov ax,real_text_sel
    mov ds,ax
    movzx eax,es:[edi].vr_row
    mul ecx
    mov esi,eax
;
    mov ax,SEG data
    mov es,ax
    mov edi,OFFSET ReplyBuf
;
    push ecx
    push edi
    rep movs es:[edi],ds:[esi]        
    pop edi
    pop ecx
;    
    ReplyMailslot

handle_video_end:
    pop ecx
    pop edi
    pop es    
    pop ds
    ret
handle_video  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleKey
;
;           DESCRIPTION:    Handle keyboard data
;
;           PARAMETERS:     ES:EDI      Msg
;                           ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_key  Proc near
    push ds
    push es
    push edi
    push ecx
;    
    mov ax,es:[edi].kr_state
    SetKeyboardState
;    
    mov ax,es:[edi].kr_char
    xchg al,ah
    mov dl,es:[edi].kr_virtual
    mov dh,es:[edi].kr_scan
    PutKeyboardCode
;    
    xor ecx,ecx
    ReplyMailslot
;
    pop ecx
    pop edi
    pop es    
    pop ds
    ret
handle_key  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleFocus
;
;           DESCRIPTION:    Handle focus data
;
;           PARAMETERS:     ES:EDI      Msg
;                           ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_focus  Proc near
    push ds
    push es
    push edi
    push ecx
;    
    mov al,es:[edi].fr_key
    SetFocus
;    
    xor ecx,ecx
    ReplyMailslot
;
    pop ecx
    pop edi
    pop es    
    pop ds
    ret
handle_focus  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleReset
;
;           DESCRIPTION:    Handle reset data
;
;           PARAMETERS:     ES:EDI      Msg
;                           ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_reset  Proc near
    push ds
    push es
    push edi
    push ecx
;    
    xor ecx,ecx
    ReplyMailslot
;
    mov ax,250
    WaitMilliSec
    SoftReset    
;
    pop ecx
    pop edi
    pop es    
    pop ds
    ret
handle_reset  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IPC thread
;
;           DESCRIPTION:    IPC thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ipc_thread_name           DB 'IPC GUI',0
mailslot_name               DB 'GUI',0

ipc_tab:
it00    DD OFFSET handle_invalid
it01    DD OFFSET handle_mode
it02    DD OFFSET handle_video
it03    DD OFFSET handle_key
it04    DD OFFSET handle_focus
it05    DD OFFSET handle_reset
it06    DD OFFSET handle_invalid
it07    DD OFFSET handle_invalid
it08    DD OFFSET handle_invalid
it09    DD OFFSET handle_invalid
it0A    DD OFFSET handle_invalid
it0B    DD OFFSET handle_invalid
it0C    DD OFFSET handle_invalid
it0D    DD OFFSET handle_invalid
it0E    DD OFFSET handle_invalid
it0F    DD OFFSET handle_invalid

ipc_thread:
    mov ax,define_mailslot_nr
    IsValidUserGate
    jc ipc_term
;    
    mov ax,cs
    mov es,ax
    mov di,OFFSET mailslot_name
    mov cx,1000h
    DefineMailslot
;
    movzx eax,cx
    AllocateGlobalMem

ipc_thread_loop:
    xor di,di
    ReceiveMailslot
    movzx ebx,es:[edi].gr_op
    cmp ebx,10h
    jb ipc_in_range
;
    xor ebx,ebx

ipc_in_range:
    call cs:[4*ebx].ipc_tab        
    jmp ipc_thread_loop

ipc_term:
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_ipc_system
;
;           DESCRIPTION:    Init IPC system
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_ipc_system     PROC far
    push ds
    push es
    pusha
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET ipc_thread
    mov di,OFFSET ipc_thread_name
    mov cx,stack0_size
    mov ax,10
    CreateThread
    popa
    pop es
    pop ds
    ret
init_ipc_system     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_ipc
;
;           DESCRIPTION:    Init IPC GUI
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_ipc
    
init_ipc  PROC near
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_ipc_system
    HookInitTasking
;
    mov eax,8000h
    AllocateBigLinear
    mov bx,real_text_sel
    mov ecx,eax
    CreateDataSelector16
;
    mov cx,8        
    xor ebx,ebx
    mov eax,0B8063h

init_text_loop:    
    SetPageEntry
    add edx,1000h
    add eax,1000h    
    loop init_text_loop
;    
    ret
init_ipc    ENDP

code    ENDS

    END
