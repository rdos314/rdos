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
; LOG.ASM
; Kernel log support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc
INCLUDE ..\os\chandle.inc

data    SEGMENT byte public 'DATA'

log_section     section_typ <>

log_handle      DW ?
log_pos         DD ?

log_buf         DB 64 DUP(?)

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LogChar
;
;       Description:    Add char to log
;
;       Parameters:     AL      Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LogChar  proc near
    push es
    pushad
;
    mov di,SEG data
    mov es,di
    mov edi,OFFSET log_buf
    mov es:[di],al
;
    mov bx,es:log_handle
    mov edx,es:log_pos
    mov ecx,1
    WriteCFile
    mov es:log_pos,edx
;
    popad
    pop es
    ret    
LogChar  endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LogCodeText
;
;       Description:    Log code text
;
;       Parameters:     DI     Offset to text
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LogCodeText  proc near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:log_handle
    mov edx,ds:log_pos
;
    mov ax,cs
    mov es,ax
    mov si,di
    xor cx,cx

lctSizeLoop:
    lods byte ptr es:[si]
    or al,al
    jz lctSizeOk
;
    inc cx
    jmp lctSizeLoop

lctSizeOk:    
    WriteCFile
    mov ds:log_pos,edx
;
    popad
    pop es
    pop ds
    ret
LogCodeText  endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddHexDigit
;
;       Description:    Add hex digit
;
;       Parameters:     ES:DI   Buffer
;                       AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexDigit   Proc near
    push ax
;
    and al,0Fh
    cmp al,10
    jb ahdLow
;
    sub al,10
    add al,'A'        
    jmp ahdSave

ahdLow:
    add al,'0'

ahdSave:
    stosb
;
    pop ax
    ret
AddHexDigit endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddHexByte
;
;       Description:    Add hex byte to log
;
;       Parameters:     ES:DI   Buffer
;                       AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexByte  proc near
    push ax
    shr al,4
    call AddHexDigit
    pop ax
    call AddHexDigit
    ret    
AddHexByte  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddHexWord
;
;       Description:    Add hex word to log
;
;       Parameters:     ES:DI   Buffer
;                       AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexWord  proc near
    xchg al,ah
    call AddHexByte
    xchg al,ah
    call AddHexByte
    ret    
AddHexWord  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LogHexByte
;
;       Description:    Add hex byte to log
;
;       Parameters:     AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LogHexByte  proc near
    push es
    pushad
;
    mov di,SEG data
    mov es,di
    mov di,OFFSET log_buf
    call AddHexByte
;
    mov bx,es:log_handle
    mov edx,es:log_pos
    mov ecx,2
    mov edi,OFFSET log_buf
    WriteCFile
    mov es:log_pos,edx
;
    popad
    pop es
    ret    
LogHexByte  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LogHexWord
;
;       Description:    Add hex word to log
;
;       Parameters:     AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LogHexWord  proc near
    push es
    pushad
;
    mov di,SEG data
    mov es,di
    mov di,OFFSET log_buf
    call AddHexWord
;
    mov bx,es:log_handle
    mov edx,es:log_pos
    mov ecx,4
    mov edi,OFFSET log_buf
    WriteCFile
    mov es:log_pos,edx
;
    popad
    pop es
    ret    
LogHexWord  endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LogDec
;
;       Description:    Add decimal
;
;       Parameters:     AX    Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LogDec  proc near
    push es
    pushad
;
    mov di,SEG data
    mov es,di
    mov di,OFFSET log_buf + 10

ldLoop:
    cmp ax,10
    jb ldLast
;
    xor dx,dx
    mov cx,10
    div cx
;
    add dl,'0'
    mov es:[di],dl
    dec di
    jmp ldLoop

ldLast:
    add al,'0'
    mov es:[di],al
;
    mov cx,OFFSET log_buf + 10
    sub cx,di
    inc cx
;
    mov bx,es:log_handle
    mov edx,es:log_pos
    movzx ecx,cx
    movzx edi,di
    WriteCFile
    mov es:log_pos,edx
;
    popad
    pop es
    ret    
LogDec  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LogDecCount
;
;       Description:    Add decimal, specifying count
;
;       Parameters:     AX    Value
;                       CX    Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LogDecCount  proc near
    push es
    pushad
;
    mov di,SEG data
    mov es,di
    mov di,OFFSET log_buf
    add di,cx
    dec di
    push cx

ldcLoop:
    xor dx,dx
    mov bx,10
    div bx
;
    add dl,'0'
    mov es:[di],dl
    dec di
    loop ldcLoop
;
    pop cx
    movzx ecx,cx
;
    mov bx,es:log_handle
    mov edx,es:log_pos
    mov edi,OFFSET log_buf
    WriteCFile
    mov es:log_pos,edx
;
    popad
    pop es
    ret    
LogDecCount  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LogDec2
;
;       Description:    Add decimal, 2 digits
;
;       Parameters:     AX    Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LogDec2  proc near
    push cx
    mov cx,2
    call LogDecCount
    pop cx
    ret
LogDec2  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LogDec3
;
;       Description:    Add decimal, 3 digits
;
;       Parameters:     AX    Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LogDec3  proc near
    push cx
    mov cx,3
    call LogDecCount
    pop cx
    ret
LogDec3  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LogDec4
;
;       Description:    Add decimal, 4 digits
;
;       Parameters:     AX    Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LogDec4  proc near
    push cx
    mov cx,4
    call LogDecCount
    pop cx
    ret
LogDec4  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockLog
;
;           description:    Lock Log
;
;           Parameters:     ES:EDI    Log section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_log_name DB 'Lock Log', 0
log_name  DB 'z:/log.txt', 0

lock_log       Proc far
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:log_section
;
    mov bx,ds:log_handle
    or bx,bx
    jnz llOpen
;
    push es
    push edi
    mov ax,cs
    mov es,ax
    mov edi,OFFSET log_name
    mov cx,O_RDWR OR O_CREAT OR O_TRUNC
    OpenKernelFile
    pop edi
    pop es
    jc llOpen
;
    mov ds:log_handle,bx
    mov ds:log_pos,0

llOpen:
    GetTime
    push eax
    BinaryToTime
;
    mov ax,dx
    call LogDec4
;
    mov al,'-'
    call LogChar
;
    movzx ax,ch
    call LogDec2
;
    mov al,'-'
    call LogChar
;
    movzx ax,cl
    call LogDec2
;
    mov al,' '
    call LogChar
;
    movzx ax,bh
    call LogDec2
;
    mov al,'.'
    call LogChar
;
    pop eax
;
    mov edx,60
    mul edx
    push ax
    mov ax,dx
    call LogDec2
    mov al,'.'
    call LogChar
    pop ax
;
    mov edx,60
    mul edx
    push ax
    mov ax,dx
    call LogDec2
    mov al,','
    call LogChar
    pop ax
;
    mov edx,1000
    mul edx
    push ax
    mov ax,dx
    call LogDec3
    mov al,' '
    call LogChar
    pop ax
;
    mov edx,1000
    mul edx
    push ax
    mov ax,dx
    call LogDec3
    mov al,' '
    call LogChar
    pop ax
;
    mov esi,edi
    xor ecx,ecx

llSizeLoop:
    lods byte ptr es:[esi]
    or al,al
    jz llSizeOk
;
    inc ecx
    jmp llSizeLoop

llSizeOk:    
    mov bx,ds:log_handle
    mov edx,ds:log_pos
    WriteCFile
    mov ds:log_pos,edx
;
    mov al,' '
    call LogChar
;
    popad
    pop es
    pop ds
    retf32
lock_log    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockLog
;
;           description:    Unlock Log
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_log_name DB 'Unlock Log', 0
new_line_text   DB 0Dh, 0Ah

unlock_log       Proc far
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:log_handle
    mov edx,ds:log_pos
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET new_line_text
    mov ecx,2
    WriteCFile
    mov ds:log_pos,edx
    LeaveSection ds:log_section
;
    popad
    pop es
    pop ds
    retf32
unlock_log  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LogThread
;
;       Description:    Log thread name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

log_thread_name DB 'Log Thread', 0

log_thread  proc far
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:log_handle
    mov edx,ds:log_pos
    GetThread
    mov es,ax
    mov edi,OFFSET thread_name
    mov ecx,30
    WriteCFile
    mov ds:log_pos,edx
;
    popad
    pop es
    pop ds
    retf32
log_thread  endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LogMemory
;
;       Description:    Log memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

log_memory_name DB 'Log Thread', 0

gdt_text  DB 'GDT=', 0

log_memory  proc far
    push ds
    push es
    pushad
;
    mov di,OFFSET gdt_text
    call LogCodeText
;
    GetFreeGdt
    call LogDec
;
    popad
    pop es
    pop ds
    retf32
log_memory  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_log
;
;           DESCRIPTION:    Init log
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_log

init_log    Proc near
    mov ax,SEG data
    mov ds,ax
    InitSection ds:log_section
    mov ds:log_handle,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET lock_log
    mov edi,OFFSET lock_log_name
    xor cl,cl
    mov ax,lock_log_nr
    RegisterOsGate
;
    mov esi,OFFSET unlock_log
    mov edi,OFFSET unlock_log_name
    xor cl,cl
    mov ax,unlock_log_nr
    RegisterOsGate
;
    mov esi,OFFSET log_thread
    mov edi,OFFSET log_thread_name
    xor cl,cl
    mov ax,log_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET log_memory
    mov edi,OFFSET log_memory_name
    xor cl,cl
    mov ax,log_memory_nr
    RegisterOsGate
    clc
    ret
init_log    Endp

code    ENDS

END
