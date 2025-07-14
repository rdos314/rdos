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

data    SEGMENT byte public 'DATA'

log_section     section_typ <>

log_handle      DW ?
log_pos         DD ?

buf_sel         DW ?
buf_size        DD ?

logger_thread   DW ?

log_buf         DB 64 DUP(?)


data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Log thread
;
;       Description:    Logger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

log_name  DB 'z:/log.txt', 0

logger:
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:logger_thread,ax
    mov ds:buf_sel,0
;
    WaitForSignal
;
    mov eax,100000h
    AllocateGlobalMem
;
    mov ecx,eax
    xor edi,edi
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov ds:buf_size,0
    mov ds:buf_sel,es
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET log_name
    mov cx,O_RDWR OR O_CREAT OR O_TRUNC
    OpenKernelHandle

logger_loop:
    int 3
    xor edx,edx
    xor edi,edi
    mov ecx,ds:buf_size   
    mov es,ds:buf_sel
    WriteKernelHandle
    mov ds:buf_size,0
    jmp logger_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Log
;
;       Description:    Log
;
;       Parameters:     ES:EDI   Buffer
;                       ECX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Log Proc near
    push ds
    push es
    pushad
;
    mov ax,es
    mov ds,ax
    mov esi,edi
    mov ax,SEG data
    mov es,ax
    mov edi,es:buf_size
    add es:buf_size,ecx
    mov es,es:buf_sel
    rep movs byte ptr es:[edi],ds:[esi]
;
    popad
    pop es
    pop ds
    ret
Log Endp

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
    mov ecx,1
;
    call Log
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
;
    movzx edi,di
    mov ax,cs
    mov es,ax
    mov si,di
    xor ecx,ecx

lctSizeLoop:
    lods byte ptr es:[si]
    or al,al
    jz lctSizeOk
;
    inc cx
    jmp lctSizeLoop

lctSizeOk:    
    call Log
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
;       NAME:           AddHexDword
;
;       Description:    Add hex dword to log
;
;       Parameters:     ES:DI   Buffer
;                       EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexDword  proc near
    push eax
    shr eax,16
    xchg al,ah
    call AddHexByte
    xchg al,ah
    call AddHexByte
    pop eax
    xchg al,ah
    call AddHexByte
    xchg al,ah
    call AddHexByte
    ret    
AddHexDword  endp

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
    movzx ecx,cx
    movzx edi,di
    call Log
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
    mov edi,OFFSET log_buf
    call Log
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

lock_log       Proc far
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:log_section

llCheck:
    mov ax,ds:buf_sel
    or ax,ax
    jnz llOpen
;
    mov bx,ds:logger_thread
    Signal
;
    mov ax,10
    WaitMilliSec
    jmp llCheck

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
    call Log
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
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET new_line_text
    mov ecx,2
    call Log
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
    GetThread
    mov es,ax
    mov edi,OFFSET thread_name
    mov ecx,30
    call Log
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
;       NAME:           LogText
;
;       Description:    Log text
;
;       Parameters:     ES:EDI     Offset to text
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

log_text_name DB 'Log Text', 0

log_text  proc far
    push ds
    pushad
;
    mov ax,SEG data
    mov ds,ax
;
    mov esi,edi
    xor ecx,ecx

ltSizeLoop:
    lods byte ptr es:[esi]
    or al,al
    jz ltSizeOk
;
    inc cx
    jmp ltSizeLoop

ltSizeOk:    
    call Log
;
    popad
    pop ds
    retf32
log_text  endp

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

log_hex_byte_name DB 'Log Hex Byte', 0

log_hex_byte  proc far
    push es
    pushad
;
    mov di,SEG data
    mov es,di
    mov di,OFFSET log_buf
    call AddHexByte
;
    mov ecx,2
    mov edi,OFFSET log_buf
    call Log
;
    popad
    pop es
    retf32
log_hex_byte  endp

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

log_hex_word_name DB 'Log Hex Word', 0

log_hex_word  proc far
    push es
    pushad
;
    mov di,SEG data
    mov es,di
    mov di,OFFSET log_buf
    call AddHexWord
;
    mov ecx,4
    mov edi,OFFSET log_buf
    call Log
;
    popad
    pop es
    retf32
log_hex_word  endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LogHexDword
;
;       Description:    Add hex dword to log
;
;       Parameters:     EAX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

log_hex_dword_name DB 'Log Hex Dword', 0

log_hex_dword  proc far
    push es
    pushad
;
    mov di,SEG data
    mov es,di
    mov di,OFFSET log_buf
    call AddHexDword
;
    mov ecx,8
    mov edi,OFFSET log_buf
    call Log
;
    popad
    pop es
    retf32
log_hex_dword  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           create_log_thread
;
;           DESCRIPTION:    Create log thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
logger_name  DB 'Logger', 0
   
create_log_thread      Proc far
    push ds
    push es
    pusha
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET logger_name
    mov si,OFFSET logger
    mov ax,4
    mov cx,stack0_size
    CreateThread
;       
    popa
    pop es
    pop ds
    retf32
create_log_thread     Endp

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
    mov edi,OFFSET create_log_thread
    HookInitTasking
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
;
    mov esi,OFFSET log_text
    mov edi,OFFSET log_text_name
    xor cl,cl
    mov ax,log_text_nr
    RegisterOsGate
;
    mov esi,OFFSET log_hex_byte
    mov edi,OFFSET log_hex_byte_name
    xor cl,cl
    mov ax,log_hex_byte_nr
    RegisterOsGate
;
    mov esi,OFFSET log_hex_word
    mov edi,OFFSET log_hex_word_name
    xor cl,cl
    mov ax,log_hex_word_nr
    RegisterOsGate
;
    mov esi,OFFSET log_hex_dword
    mov edi,OFFSET log_hex_dword_name
    xor cl,cl
    mov ax,log_hex_dword_nr
    RegisterOsGate
    clc
    ret
init_log    Endp

code    ENDS

END
