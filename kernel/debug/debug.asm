;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
; KDEBUG.ASM
; Kernel part kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE dis.inc

.386p
.387

data    SEGMENT byte public 'DATA'

buf    DB 4096 DUP(?)

cpu cpu_struc <>

data    ENDS

code    SEGMENT byte use32 public 'CODE'

    extrn DisAsmCode:near


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddNewLine
;
;           DESCRIPTION:    ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddNewLine Proc near
    push eax
;    
    mov al,13
    stosb
;    
    mov al,10
    stosb
;
    pop ax
    ret
AddNewLine Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddBlank
;
;           DESCRIPTION:    Add blanks
;
;           PARAMETERS:     ES:EDI       Buffer
;                           ECX          Number of blanks to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddBlanks   Proc near
    push eax
    push ecx
;
    mov al,' '
    rep stosb
;
    pop ecx
    pop eax
    ret
AddBlanks   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddDelimiter
;
;           DESCRIPTION:    Add delimiter
;  
;           PARAMETERS:     ES:EDI       Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDelimiter       Proc near
    push eax
    push ecx
;    
    mov ecx,60
    mov al,'-'
    rep stosb
;
    mov ecx,19
    call AddBlanks
;
    call AddNewLine    
; 
    pop ecx   
    pop eax
    ret
AddDelimiter       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ToHex
;
;           DESCRIPTION:    
;
;           PARAMETERS:     AL          Number
;
;           RETURNS:        AX          Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ToHex      PROC near

hex_conv_low:
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
;
    add al,7

ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
;    
    add ah,7

ok_high1:
    add ah,30h
    ret
ToHex      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI       Buffer
;                           AL          Byte to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexByte    PROC near
    push eax
;    
    mov ah,al
    and al,0F0h
    rol al,4
    cmp al,0Ah
    jb add_byte_low1
;    
    add al,7

add_byte_low1:
    add al,'0'
    stosb
;
    mov al,ah
    and al,0Fh
    cmp al,0Ah
    jb add_byte_high1
;
    add al,7

add_byte_high1:
    add al,'0'
    stosb
;
    pop eax
    ret
AddHexByte    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI       Buffer
;                           AX           Word to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexWord    PROC near
    xchg al,ah
    call AddHexByte
    xchg al,ah
    call AddHexByte
    ret
AddHexWord    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI      Buffer
;                           EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexDword   PROC near
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    ret
AddHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexQword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI      Buffer
;                           EDX:EAX     Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexQword   PROC near
    push eax
;    
    push eax
    mov eax,edx
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
;
    mov al,'_'
    stosb
;
    pop eax
;    
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
;
    pop eax    
    ret
AddHexQword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexPtr16
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI      Buffer
;                           DX          Segment
;                           BX          Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexPtr16   PROC near
    push ax
    mov ax,dx
    call AddHexWord
;    
    mov al,':'
    stosb
;
    mov ax,bx
    call AddHexWord
    pop ax
    ret
AddHexPtr16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexPtr32
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI      Buffer
;                           DX          Segment
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexPtr32   PROC near
    push eax
    mov ax,dx
    call AddHexWord
;    
    mov al,':'
    stosb
;
    mov eax,ebx
    call AddHexDword
    pop eax
    ret
AddHexPtr32   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexPtr64
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DX          High offset
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexPtr64   PROC near
    push eax
;    
    mov ax,dx
    call AddHexWord
;
    mov al,'_'
    stosb
;    
    mov eax,ebx
    call AddHexDword
;
    pop eax
    ret
AddHexPtr64   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Read_mem
;
;           DESCRIPTION:    Read memory in process
;
;           PARAMETERS:     DX:ESI      Sel:offset
;                           DS:EBP      Cpu
;
;           RETURNS:        NC  AL  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_mem    Proc near
    push bx
;
    mov bx,ds:[ebp].cpu_thread        
    test word ptr ds:[ebp].reg_eflags+2,2
    jz rdmProt

rdmV86:
    ReadThreadSegment
    jmp rdmDone
    
rdmProt:
    test ds:[ebp].reg_cs.d_access,ACCESS_64
    jnz rdm64

rdm32:    
    ReadThreadSelector
    jmp rdmDone

rdm64:
    ReadThread64

rdmDone:
    pop bx
    ret
read_mem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Write_mem
;
;           DESCRIPTION:    Write memory in process
;
;           PARAMETERS:     DX:ESI      Sel:offset
;                           BX          Thread
;                           DS:EBP      Cpu
;                           AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_mem    Proc near
    push bx
;
    mov bx,ds:[ebp].cpu_thread        
    test word ptr ds:[ebp].reg_eflags+2,2
    jz wrmProt

wrmV86:
    WriteThreadSegment
    jmp wrmDone
    
wrmProt:
    test ds:[ebp].reg_cs.d_access,ACCESS_64
    jnz wrm64
    
wrm32:    
    WriteThreadSelector
    jmp wrmDone

wrm64:
    WriteThread64

wrmDone:
    pop bx
    ret
write_mem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Debug process
;
;           DESCRIPTION:    Debug process
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_name          DB 'New Debug',0

debug_process:
    sti
    mov ax,41h
    EnableFocus
    int 3
;
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    mov ebp,OFFSET cpu
;
    GetThread
    mov ds:[ebp].cpu_thread,ax
    mov ds:[ebp].cpu_read_mem,OFFSET read_mem
    mov ds:[ebp].cpu_write_mem,OFFSET write_mem
;    
    mov bx,cs
    mov ds:[ebp].reg_eip,OFFSET debug_process
    mov ds:[ebp].reg_eip+4,0
    mov ds:[ebp].reg_cs.d_selector,bx
    GetSelectorBitness
    cmp al,16
    je dis16
;
    cmp al,32
    je dis32

dis64:
    mov ds:[ebp].reg_cs.d_access,ACCESS_READ OR ACCESS_64
    jmp disdo

dis32:
    mov ds:[ebp].reg_cs.d_access,ACCESS_READ OR ACCESS_32
    jmp disdo

dis16:
    mov ds:[ebp].reg_cs.d_access,ACCESS_READ

disdo:    
    mov edi,OFFSET buf
    mov ecx,40

dis_next:    
    call DisAsmCode
    add ds:[ebp].reg_eip,eax
    jmp dis_next

marker_loop:
    mov ax,250
    WaitMilliSec
    jmp marker_loop    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_debug_process
;
;           DESCRIPTION:    Create kernel debugger process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_debug_process      PROC far
    push ds
    push es
    pushad
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET debug_process
    mov edi,OFFSET debug_name
    mov ecx,stack0_size
    mov ax,26
    CreateProcess
    popad
    pop es
    pop ds
    ret
init_debug_process      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    Init kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov eax,cs
    mov ds,eax
    mov es,eax  
    mov edi,OFFSET init_debug_process
    HookInitTasking
    clc
    ret
init    Endp
    
code    ENDS

    END init
