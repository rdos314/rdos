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
; IPCSEND.ASM
; Sender part of local IPC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.inc
INCLUDE ip.inc
INCLUDE ipc.inc

ipc_list_data   STRUC

il_ml_list                      mailslot_list_data <>
il_send_base            DD ?
il_send_size            DD ?
il_send_glob_base       DD ?
il_send_glob_size       DD ?
il_send_glob_sel        DW ?
il_send_thread          DW ?
il_reply_max_size       DD ?
il_reply_base           DD ?
il_reply_glob_base      DD ?
il_reply_glob_size      DD ?
il_reply_glob_sel       DW ?
il_reply_thread         DW ?

ipc_list_data   ENDS


code    SEGMENT byte public 'CODE'

.386p
        
        assume cs:code

        extrn SelectorToLinear:near
        extrn ReplyLocal:near
        extrn QueueReceiveRequest:near
        extrn CopyToReceiver:near

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CopyFromSender
;
;               DESCRIPTION:    Copy message from sender
;
;               PARAMETERS:             DS                      Mailslot
;                                               ES                      SMP list entry
;                                               FS:ESI          Message buffer
;
;               RETURNS:                ECX                     Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyFromSender  Proc near
        push eax
        push bx
        push edx
        push esi
        push edi
;
        push ds
        push es
        mov ecx,es:il_send_size
        mov ds,es:il_send_glob_sel
        mov ax,fs
        mov es,ax
        mov edi,esi
        xor esi,esi
        rep movs byte ptr es:[edi],ds:[esi]
        pop es
        pop ds
;
        mov ecx,es:il_send_glob_size
        shr ecx,12
        mov edx,es:il_send_glob_base
;
    xor ebx,ebx
    mov eax,2

do_rec_zero:
    SetPageEntry
        add edx,1000h
        sub ecx,1
        jnz do_rec_zero
;
        mov bx,es:il_send_glob_sel
        FreeGdt
;
        mov edx,es:il_send_glob_base
        mov ecx,es:il_send_glob_size
        FreeLinear
;
        mov eax,es:il_reply_max_size
        mov ds:m_send_max_size,eax
        mov eax,es:il_reply_base
        mov ds:m_send_base,eax
        mov eax,es:il_reply_glob_base
        mov ds:m_send_glob_base,eax
        mov eax,es:il_reply_glob_size
        mov ds:m_send_glob_size,eax
        mov ax,es:il_reply_glob_sel
        mov ds:m_send_glob_sel,ax
        mov ax,es:il_reply_thread
        mov ds:m_send_thread,ax
        mov ecx,es:il_send_size
        FreeMem
        LeaveSection ds:m_section
;
        pop edi
        pop esi
        pop edx
        pop bx
        pop eax
        ret
CopyFromSender  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   InsertSend
;
;               DESCRIPTION:    Insert send request
;
;               PARAMETERS:             DS                      Mailslot
;                                               ES:EDI          Reply buffer
;                                               ECX                     Max reply size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertSend      Proc near
        pushad
;
        call SelectorToLinear
        mov al,es:[edi]
        mov al,es:[edi+ecx-1]
;
        mov ds:m_reply_callb,OFFSET ReplyLocal
        GetThread
        mov ds:m_send_thread,ax
        mov ds:m_send_base,edx
        mov ds:m_send_max_size,ecx
        mov eax,edx
        add eax,ecx
        dec eax
        and ax,0F000h
        add eax,1000h
        and dx,0F000h
        sub eax,edx
        mov ds:m_send_glob_size,eax
        AllocateBigLinear
        mov ds:m_send_glob_base,edx
        mov ax,word ptr ds:m_send_base
        and ax,0FFFh
        or dx,ax
        AllocateGdt
        mov ecx,ds:m_send_max_size
        CreateDataSelector32
        mov ds:m_send_glob_sel,bx
        mov ecx,ds:m_send_glob_size
        shr ecx,12
        mov esi,ds:m_send_base
        and si,0F000h
        mov edi,ds:m_send_glob_base
        CopyPageEntries
;
        popad
        ret
InsertSend      Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   QueueSend
;
;               DESCRIPTION:    Queue a send
;
;               PARAMETERS:             DS                      Mailslot
;                                               FS:ESI          Send buffer
;                                               ECX                     Send size
;                                               ES:EDI          Reply buffer
;                                               EAX                     Max reply size
;
;               RETURNS:                GS                      SMP list entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

QueueSend       Proc near
        push es
        pushad
;
        mov ebp,ecx
        mov ecx,eax
        push es
        mov eax,SIZE ipc_list_data
        AllocateSmallGlobalMem
        mov ax,es
        mov gs,ax
        pop es
;
        call SelectorToLinear
        mov al,es:[edi]
        mov al,es:[edi+ecx-1]
;
        mov gs:ml_rec_callb,OFFSET CopyFromSender
        mov gs:ml_reply_callb,OFFSET ReplyLocal
        GetThread
        mov gs:il_reply_thread,ax
        mov gs:il_reply_base,edx
        mov gs:il_reply_max_size,ecx
        mov eax,edx
        add eax,ecx
        dec eax
        and ax,0F000h
        add eax,1000h
        and dx,0F000h
        sub eax,edx
        mov gs:il_reply_glob_size,eax
        AllocateBigLinear
        mov gs:il_reply_glob_base,edx
        mov ax,word ptr gs:il_reply_base
        and ax,0FFFh
        or dx,ax
        AllocateGdt
        mov ecx,gs:il_reply_max_size
        CreateDataSelector32
        mov gs:il_reply_glob_sel,bx
;
        mov edx,esi
        mov ecx,gs:il_reply_glob_size
        shr ecx,12
        mov esi,gs:il_reply_base
        and si,0F000h
        mov edi,gs:il_reply_glob_base
        CopyPageEntries
;
        mov edi,edx
        mov ecx,ebp
        mov ax,fs
        mov es,ax
        call SelectorToLinear
        mov al,es:[edi]
        mov al,es:[edi+ecx-1]
;
        GetThread
        mov gs:il_send_thread,ax
        mov gs:il_send_base,edx
        mov gs:il_send_size,ecx
        mov eax,edx
        add eax,ecx
        dec eax
        and ax,0F000h
        add eax,1000h
        and dx,0F000h
        sub eax,edx
        mov gs:il_send_glob_size,eax
        AllocateBigLinear
        mov gs:il_send_glob_base,edx
        mov ax,word ptr gs:il_send_base
        and ax,0FFFh
        or dx,ax
        AllocateGdt
        mov ecx,gs:il_send_size
        CreateDataSelector32
        mov gs:il_send_glob_sel,bx
        mov ecx,gs:il_send_glob_size
        shr ecx,12
        mov esi,gs:il_send_base
        and si,0F000h
        mov edi,gs:il_send_glob_base
        CopyPageEntries
;
        mov ax,gs
        mov es,ax
        call QueueReceiveRequest
;
        popad
        pop es
        ret
QueueSend       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   RemoveSend
;
;               DESCRIPTION:    Remove send request
;
;               PARAMETERS:             ECX             Size of reply buffer
;                                               ESI             Global base
;                                               EDI             Local base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveSend      Proc near
        pushad
;
        mov edx,esi
        shr ecx,12
        push ecx
        and di,0F000h
        MovePageEntries
;
        pop ecx
        shl ecx,12
        FreeLinear
;
        popad
        ret
RemoveSend      Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendLocal
;
;               DESCRIPTION:    Send a local message
;
;               PARAMETERS:             DS                      Mailslot selector
;                                               FS:ESI          Message buffer
;                                               ECX                     Message size
;                                               ES:EDI          Reply buffer
;                                               EBP                     Max reply size
;
;               RETURNS:                ECX                     Reply size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SendLocal

SendLocal       Proc near
        push fs
        push gs
        push eax
        push esi
        push edi
;
        EnterSection ds:m_section
        ClearSignal
        mov ax,ds:m_rec_thread
        or ax,ax
        jz send_local_busy
;
        mov ax,ds:m_send_thread
        or ax,ax
        jz send_local_idle

send_local_busy:
        mov eax,ebp
        call QueueSend
        mov ecx,gs:il_reply_glob_size
        mov esi,gs:il_reply_glob_base
        mov edi,gs:il_reply_base
        xor ax,ax
        mov gs,ax
        LeaveSection ds:m_section
        jmp send_local_wait

send_local_idle:
        push ecx
        mov ecx,ebp
        call InsertSend
        pop ecx
        push ds:m_send_glob_size
        push ds:m_send_glob_base
        push ds:m_send_base
        call CopyToReceiver
        pop edi
        pop esi
        pop ecx

send_local_wait:
        WaitForSignal
        call RemoveSend
        push ds
        GetThread
        mov ds,ax
        mov ecx,ds:p_data
        pop ds
        clc
;
        pop edi
        pop esi
        pop eax
        pop fs
        pop gs
        ret
SendLocal       Endp

code    ENDS

        END
