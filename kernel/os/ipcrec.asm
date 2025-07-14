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
; IPCREC.ASM
; Receiver part of local IPC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE int.def
INCLUDE system.inc
INCLUDE ip.inc
INCLUDE ipc.inc

code    SEGMENT byte public 'CODE'

.386p
        
        assume cs:code

        extrn SelectorToLinear:near

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ReplyLocal
;
;               DESCRIPTION:    Reply
;
;               PARAMETERS:             DS                      Mailslot
;                                               ES:EDI          Message buffer
;                                               ECX                     Message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ReplyLocal 

ReplyLocal      Proc near
        push ds
        push es
        push ax
        push bx
        push ecx
        push esi
        push edi
;
        cmp ecx,ds:m_send_max_size
        jbe do_reply_inrange
;
        mov ecx,ds:m_send_max_size

do_reply_inrange:
        mov ds:m_send_size,ecx
        push ds
        mov ax,es
        mov es,ds:m_send_glob_sel
        mov ds,ax
        mov esi,edi     
        xor edi,edi
        rep movs byte ptr es:[edi],ds:[esi]
        xor ax,ax
        mov es,ax
        pop ds
;
        mov bx,ds:m_send_glob_sel
        FreeGdt
;
        xor bx,bx
        xchg bx,ds:m_send_thread
        mov es,bx
        mov eax,ds:m_send_size
;
        mov es:p_data,eax
        xor ax,ax
        mov es,ax
        Signal
;
        pop edi
        pop esi
        pop ecx
        pop bx
        pop ax
        pop es
        pop ds
        ret
ReplyLocal      Endp

code    ENDS

        END
