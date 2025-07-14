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
; PROTSEG.ASM
; Selector management module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386p

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE system.def

code    SEGMENT byte use16 public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_selector_base_size
;
;           DESCRIPTION:    Get selector base + size
;
;           PARAMETERS:     BX              Selector
;
;           RETURNS:        EDX             Base
;                           ECX             Size
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public local_get_selector_base_size

local_get_selector_base_size  PROC near
    push ds
    push ax
    push bx
;
    test bx,4
    jz get_selector_gdt

get_selector_ldt:
    GetThread
    mov ds,ax
    push bx
    mov dx,bx
    mov bx,ds:p_ldt_sel
    mov ax,gdt_sel
    mov ds,ax
    cmp dx,ds:[bx]
    mov ds,bx
    pop bx
    jb get_selector_check
    jmp get_selector_error

get_selector_gdt:
    mov ax,gdt_sel
    mov ds,ax

get_selector_check:
    and bx,0FFF8h
    jz get_selector_error
;
    mov al,[bx+5]
    test al,80h
    jz get_selector_error
;
    test al,10h
    jz get_selector_error
;
    xor ecx,ecx
    mov cl,[bx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[bx]
    test byte ptr [bx+6],80h
    jz get_selector_small
;
    shl ecx,12
    or cx,0FFFh

get_selector_small:
    inc ecx
    mov edx,[bx+2]
    rol edx,8
    mov dl,[bx+7]
    ror edx,8
;
    test al,4
    jz get_selector_dir_ok
;
    neg ecx
    sub edx,ecx

get_selector_dir_ok:    
    clc
    jmp get_selector_done

get_selector_error:
    stc

get_selector_done:
    pop bx
    pop ax
    pop ds
    ret
local_get_selector_base_size  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetSelectorBaseSize
;
;           DESCRIPTION:    Get selector base + size
;
;           PARAMETERS:         BX              Selector
;
;           RETURNS:        EDX             Base
;                           ECX             Limit
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_selector_base_size_name DB 'Get selector base & size',0

get_selector_base_size  PROC far
    call local_get_selector_base_size
    retf32
get_selector_base_size  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_create_data_sel16
;
;           DESCRIPTION:    Create 16-bit data selector
;
;           PARAMETERS:     BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public local_create_data_sel16

local_create_data_sel16       PROC near
    push ds
    push ax
    push bx
    push ecx
;
    test bx,4
    jz create_data16_gdt

create_data16_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp create_data16_dt_ok

create_data16_gdt:
    mov ax,gdt_sel
    mov ds,ax

create_data16_dt_ok:
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae create_data16_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    mov [bx+6],cx
    jmp create_data16_done

create_data16_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,80h
    mov [bx+6],cx

create_data16_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
local_create_data_sel16       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateDataSelector16
;
;           DESCRIPTION:    Create 16-bit data selector
;
;           PARAMETERS:         BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_data_sel16_name DB 'Create 16-bit Data Selector',0

create_data_sel16       PROC far
    call local_create_data_sel16
    retf32
create_data_sel16       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateDataSelector32
;
;           DESCRIPTION:    Create 32-bit data selector
;
;           PARAMETERS:         BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_data_sel32_name DB 'Create 32-bit Data Selector',0

create_data_sel32       PROC far
    push ds
    push ax
    push bx
    push ecx
;
    test bx,4
    jz create_data32_gdt

create_data32_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp create_data32_dt_ok

create_data32_gdt:
    mov ax,gdt_sel
    mov ds,ax

create_data32_dt_ok:
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae create_data32_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,40h
    mov [bx+6],cx
    jmp create_data32_done

create_data32_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,0C0h
    mov [bx+6],cx

create_data32_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    retf32
create_data_sel32       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateDownSelector32
;
;           DESCRIPTION:    Create 32-bit expand-down data selector
;
;           PARAMETERS:     BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             SIZE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_down_sel32_name DB 'Create 32-bit Expand Down Selector',0

create_down_sel32       PROC far
    push ds
    push ax
    push bx
    push ecx
    push edx
;
    test bx,4
    jz create_down32_gdt

create_down32_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp create_down32_dt_ok

create_down32_gdt:
    mov ax,gdt_sel
    mov ds,ax

create_down32_dt_ok:
    mov al,bl
    and bx,0FFF8h
;
    add edx,ecx
    not ecx
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,96h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,0C0h
    mov [bx+6],cx

create_down32_done:
    pop edx
    pop ecx
    pop bx
    pop ax
    pop ds
    retf32
create_down_sel32       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateAliasSelector16
;
;           DESCRIPTION:    Create a 16-bit aliased data selector
;
;           PARAMETERS:         BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_alias_sel16_name DB 'Create 16-bit Alias Selector',0

create_alias_sel16      PROC far
    push ds
    push ax
    push bx
    push ecx
;
    test bx,4
    jz create_alias16_gdt

create_alias16_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp create_alias16_dt_ok

create_alias16_gdt:
    mov ax,gdt_sel
    mov ds,ax

create_alias16_dt_ok:
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae create_alias16_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,10h
    mov [bx+6],cx
    jmp create_alias16_done

create_alias16_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,90h
    mov [bx+6],cx

create_alias16_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    retf32
create_alias_sel16      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCodeSelector16
;
;           DESCRIPTION:    Create 16-bit code selector
;
;           PARAMETERS:         BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_code_sel16_name DB 'Create 16-bit Code Selector',0

create_code_sel16       PROC far
    push ds
    push ax
    push bx
    push ecx
;
    test bx,4
    jz create_code16_gdt

create_code16_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp create_code16_dt_ok

create_code16_gdt:
    mov ax,gdt_sel
    mov ds,ax

create_code16_dt_ok:
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae create_code16_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Ah
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    mov [bx+6],cx
    jmp create_code16_done

create_code16_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Ah
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,80h
    mov [bx+6],cx

create_code16_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    retf32
create_code_sel16       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCodeSelector32
;
;           DESCRIPTION:    Create 32-bit code selector
;
;           PARAMETERS:         BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_code_sel32_name DB 'Create 32-bit Code Selector',0

create_code_sel32       PROC far
    push ds
    push ax
    push bx
    push ecx
;
    test bx,4
    jz create_code32_gdt

create_code32_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp create_code32_dt_ok

create_code32_gdt:
    mov ax,gdt_sel
    mov ds,ax

create_code32_dt_ok:
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae create_code32_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Ah
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,40h
    mov [bx+6],cx
    jmp create_code32_done

create_code32_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Ah
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,0C0h
    mov [bx+6],cx

create_code32_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    retf32
create_code_sel32       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetSelectorBitness
;
;           DESCRIPTION:    Get selector bitness
;
;           PARAMETERS:     BX      DESCRIPTOR
;
;           RETURNS:        AL      Bitness (16, 32 or 64)
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_sel_bitness_name DB 'Get Selector Bitness',0

get_sel_bitness       PROC far
    push ds
    push bx
;
    test bx,4
    jz get_bitness_gdt

get_bitness_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp get_bitness_dt_ok

get_bitness_gdt:
    mov ax,gdt_sel
    mov ds,ax

get_bitness_dt_ok:
    and bx,0FFF8h
    mov bl,[bx+6]
    mov al,64
    test bl,20h
    jnz get_bitness_ok
;
    mov al,32
    test bl,40h
    jnz get_bitness_ok
;
    mov al,16

get_bitness_ok:        
    pop bx
    pop ds
    retf32
get_sel_bitness       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateLongCodeSelector
;
;           DESCRIPTION:    Create long mode code selector
;
;           PARAMETERS:     BX              DESCRIPTOR
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_long_code_sel_name DB 'Create Long Mode Code Selector',0

create_long_code_sel       PROC far
    push ds
    push eax
    push bx
;
    test bx,4
    jz create_long_code_gdt

create_long_code_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp create_long_code_dt_ok

create_long_code_gdt:
    mov ax,gdt_sel
    mov ds,ax

create_long_code_dt_ok:
    mov al,bl
    and bx,0FFF8h
;
    shl al,5
    or al,9Ah
    mov [bx+5],al
;
    mov al,0AFh
    mov [bx+6],al    
;
    xor ax,ax
    mov [bx+2],ax
    mov [bx+4],al
;
    mov ax,-1    
    mov [bx],ax
    xor al,al
    mov [bx+7],al
;
    pop bx
    pop eax
    pop ds
    retf32
create_long_code_sel       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsLongCodeSelector
;
;           DESCRIPTION:    Is long mode code selector
;
;           PARAMETERS:     BX              DESCRIPTOR
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_long_code_sel_name DB 'Is Long Mode Code Selector',0

is_long_code_sel       PROC far
    push ds
    push ax
    push bx
;
    test bx,4
    jz is_long_code_gdt

is_long_code_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp is_long_code_dt_ok

is_long_code_gdt:
    mov ax,gdt_sel
    mov ds,ax

is_long_code_dt_ok:
    and bx,0FFF8h
    mov al,[bx+6]
    test al,20h
    clc
    jnz is_long_code_done
;
    stc

is_long_code_done:
    pop bx
    pop ax
    pop ds
    retf32
is_long_code_sel       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateConformSelector16
;
;           DESCRIPTION:    Create 16-bit conforming code selector
;
;           PARAMETERS:         BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_conform_sel16_name DB 'Create 16-bit Conforming Selector',0

create_conform_sel16    PROC far
    push ds
    push ax
    push bx
    push ecx
;
    test bx,4
    jz create_conform16_gdt

create_conform16_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp create_conform16_dt_ok

create_conform16_gdt:
    mov ax,gdt_sel
    mov ds,ax

create_conform16_dt_ok:
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae create_conform16_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Eh
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    mov [bx+6],cx
    jmp create_conform16_done

create_conform16_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Eh
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,80h
    mov [bx+6],cx

create_conform16_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    retf32
create_conform_sel16    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateConformSelector32
;
;           DESCRIPTION:    Create 32-bit conforming code selector
;
;           PARAMETERS:         BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_conform_sel32_name DB 'Create 32-bit Conforming Selector',0

create_conform_sel32    PROC far
    push ds
    push ax
    push bx
    push ecx
;
    test bx,4
    jz create_conform32_gdt

create_conform32_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp create_conform32_dt_ok

create_conform32_gdt:
    mov ax,gdt_sel
    mov ds,ax

create_conform32_dt_ok:
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae create_conform32_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Eh
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,40h
    mov [bx+6],cx
    jmp create_conform32_done

create_conform32_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Eh
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,0C0h
    mov [bx+6],cx

create_conform32_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    retf32
create_conform_sel32    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateLdtSelector
;
;           DESCRIPTION:    Create LDT selector
;
;           PARAMETERS:         BX              DESCRIPTOR
;                           EDX             BASE
;                           CX              LIMIT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_ldt_sel_name DB 'Create LDT Selector',0

create_ldt_sel  PROC far
    push ds
    push ax
    push bx
    push cx
;
    test bx,4
    jnz create_ldt_done
;
    mov ax,gdt_sel
    mov ds,ax
;
    mov ah,bl
    and bx,0FFF8h
    dec cx
;
    mov [bx],cx
    mov [bx+2],edx
    shl ah,5
    or ah,82h
    xchg ah,[bx+5]
    xor al,al
    mov [bx+6],ax

create_ldt_done:
    pop cx
    pop bx
    pop ax
    pop ds
    retf32
create_ldt_sel  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_create_tss_sel
;
;           DESCRIPTION:    Create TSS selector
;
;           PARAMETERS:         BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public local_create_tss_sel

local_create_tss_sel  PROC near
    push ds
    push ax
    push bx
    push ecx
;
    test bx,4
    jnz create_tss_done
;
    mov ax,gdt_sel
    mov ds,ax
;
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae create_tss_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,89h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    mov [bx+6],cx
    jmp create_tss_done

create_tss_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,89h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,80h
    mov [bx+6],cx

create_tss_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
local_create_tss_sel  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateTssSelector
;
;           DESCRIPTION:    Create TSS selector
;
;           PARAMETERS:         BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_tss_sel_name DB 'Create TSS Selector',0

create_tss_sel  PROC far
    call local_create_tss_sel
    retf32
create_tss_sel  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCallGateSelector16
;
;           DESCRIPTION:    Create 16-bit call gate selector
;
;           PARAMETERS:         BX              DESCRIPTOR
;                           DS:SI       ENTRY POINT
;                           CL              16-BIT WORDS TO MOVE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_call_gate_sel16_name DB 'Create 16-bit Call Gate Selector',0

create_call_gate_sel16  PROC far
    push es
    push ax
    push bx
;
    test bx,4
    jz create_call_gate16_gdt

create_call_gate16_ldt:
    GetThread
    mov es,ax
    mov es,es:p_ldt_sel
    jmp create_call_gate16_dt_ok

create_call_gate16_gdt:
    mov ax,gdt_sel
    mov es,ax

create_call_gate16_dt_ok:
    mov ah,bl
    and bx,0FFF8h
    mov es:[bx],si
    mov es:[bx+2],ds
    mov al,cl
    and al,0Fh
    shl ah,5
    or ah,84h
    mov es:[bx+4],ax
    xor ax,ax
    mov es:[bx+6],ax    
;
    pop bx
    pop ax
    pop es
    retf32
create_call_gate_sel16  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCallGateSelector32
;
;           DESCRIPTION:    Create 32-bit call gate selector
;
;           PARAMETERS:         BX              DESCRIPTOR
;                           DS:ESI      ENTRY POINT
;                           CL              32-BIT WORDS TO MOVE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_call_gate_sel32_name DB 'Create 32-bit Call Gate Selector',0

create_call_gate_sel32  PROC far
    push es
    push ax
    push bx
;
    test bx,4
    jz create_call_gate32_gdt

create_call_gate32_ldt:
    GetThread
    mov es,ax
    mov es,es:p_ldt_sel
    jmp create_call_gate32_dt_ok

create_call_gate32_gdt:
    mov ax,gdt_sel
    mov es,ax

create_call_gate32_dt_ok:
    mov ah,bl
    and bx,0FFF8h
    mov al,cl
    and al,0Fh
    shl ah,5
    or ah,8Ch
    mov es:[bx+4],ax
    mov es:[bx],esi
    mov ax,ds
    xchg ax,es:[bx+2]
    mov es:[bx+6],ax
;
    pop bx
    pop ax
    pop es
    retf32
create_call_gate_sel32  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateTaskGateSelector
;
;           DESCRIPTION:    Create task gate selector
;
;           PARAMETERS:         BX              DESCRIPTOR
;                           DX              TSS SELECTOR
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_task_gate_sel_name DB 'Create Task Gate Selector',0

create_task_gate_sel    PROC far
    push ds
    push ax
    push bx
;
    test bx,4
    jz create_task_gate_gdt

create_task_gate_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp create_task_gate_dt_ok

create_task_gate_gdt:
    mov ax,gdt_sel
    mov ds,ax

create_task_gate_dt_ok:
    mov ah,bl
    and bx,0FFF8h
    mov [bx+2],dx
    xor al,al
    shl ah,5
    or ah,85h
    mov [bx+4],ax
    xor ax,ax
    mov [bx+6],ax   
    mov [bx],ax
;
    pop bx
    pop ax
    pop ds
    retf32
create_task_gate_sel    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_create_int_gate_sel
;
;           DESCRIPTION:    Create int gate selector
;
;           PARAMETERS:         AL              INT #
;                           BL              DPL
;                           DS:ESI      ENTRY POINT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public local_create_int_gate_sel

local_create_int_gate_sel     PROC near
    push es
    push ax
    push bx
    push dx
;
    mov dx,idt_sel
    mov es,dx
;
    mov ah,bl
    movzx bx,al
    shl bx,3
    xor al,al
    shl ah,5
    or ah,8Eh
    mov es:[bx+4],ax
    mov es:[bx],esi
    mov ax,ds
    xchg ax,es:[bx+2]
    mov es:[bx+6],ax
;
    pop dx
    pop bx
    pop ax
    pop es
    ret
local_create_int_gate_sel     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_create_trap_gate_sel
;
;           DESCRIPTION:    Create trap gate selector
;
;           PARAMETERS:         AL              INTERRUPT #
;                           BL              DPL
;                           DS:ESI      ENTRY POINT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public local_create_trap_gate_sel
    
local_create_trap_gate_sel    PROC near
    push es
    push ax
    push bx
    push dx
;
    mov dx,idt_sel
    mov es,dx
;
    mov ah,bl
    movzx bx,al
    shl bx,3
    xor al,al
    shl ah,5
    or ah,8Fh
    mov es:[bx+4],ax
    mov es:[bx],esi
    mov ax,ds
    xchg ax,es:[bx+2]
    mov es:[bx+6],ax
;
    pop dx
    pop bx
    pop ax
    pop es
    ret
local_create_trap_gate_sel    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetSelectorInfo
;
;           DESCRIPTION:    Get selector size and bitness
;
;           PARAMETERS:         BX              Selector
;
;           RETURNS:        ECX             Limit
;               AL      Bitness (16 or 32)
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_selector_info_name DB 'Get Selector Info',0

get_selector_info       PROC far
    push ds
    push bx
;
    test bx,4
    jz get_selector_info_gdt

get_selector_info_ldt:
    GetThread
    mov ds,ax
    mov ax,ds:p_ldt_sel
    lsl ecx,eax
    jnz get_selector_info_error
;    
    mov ds,ax    
    jmp get_selector_info_check

get_selector_info_gdt:
    mov ax,gdt_sel
    mov ds,ax
    mov cx,0EFFFh

get_selector_info_check:
    and bx,0FFF8h
    jz get_selector_info_error
;
    cmp bx,cx
    jae get_selector_info_error
;    
    mov al,[bx+5]
    test al,80h
    jz get_selector_info_error
;
    test al,10h
    jz get_selector_info_error
;
    xor ecx,ecx
    mov cl,[bx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[bx]
    mov al,16
    test byte ptr [bx+6],40h
    jz get_selector_info_small
;
    mov al,32
    shl ecx,12
    or cx,0FFFh

get_selector_info_small:
    clc
    jmp get_selector_info_done

get_selector_info_error:
    stc

get_selector_info_done:
    pop bx
    pop ds
    retf32
get_selector_info       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_protseg
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_os_protseg

init_os_protseg PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_selector_base_size
    mov edi,OFFSET get_selector_base_size_name
    xor cl,cl
    mov ax,get_selector_base_size_nr
    RegisterOsGate
;
    mov esi,OFFSET create_data_sel16
    mov edi,OFFSET create_data_sel16_name
    xor cl,cl
    mov ax,create_data_sel16_nr
    RegisterOsGate
;
    mov esi,OFFSET create_alias_sel16
    mov edi,OFFSET create_alias_sel16_name
    xor cl,cl
    mov ax,create_alias_sel16_nr
    RegisterOsGate
;
    mov esi,OFFSET create_data_sel32
    mov edi,OFFSET create_data_sel32_name
    xor cl,cl
    mov ax,create_data_sel32_nr
    RegisterOsGate
;
    mov esi,OFFSET create_down_sel32
    mov edi,OFFSET create_down_sel32_name
    xor cl,cl
    mov ax,create_down_sel32_nr
    RegisterOsGate
;
    mov esi,OFFSET create_code_sel16
    mov edi,OFFSET create_code_sel16_name
    xor cl,cl
    mov ax,create_code_sel16_nr
    RegisterOsGate
;
    mov esi,OFFSET create_code_sel32
    mov edi,OFFSET create_code_sel32_name
    xor cl,cl
    mov ax,create_code_sel32_nr
    RegisterOsGate
;
    mov esi,OFFSET create_long_code_sel
    mov edi,OFFSET create_long_code_sel_name
    xor cl,cl
    mov ax,create_long_code_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET is_long_code_sel
    mov edi,OFFSET is_long_code_sel_name
    xor cl,cl
    mov ax,is_long_code_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET create_conform_sel16
    mov edi,OFFSET create_conform_sel16_name
    xor cl,cl
    mov ax,create_conform_sel16_nr
    RegisterOsGate
;
    mov esi,OFFSET create_conform_sel32
    mov edi,OFFSET create_conform_sel32_name
    xor cl,cl
    mov ax,create_conform_sel32_nr
    RegisterOsGate
;
    mov esi,OFFSET create_ldt_sel
    mov edi,OFFSET create_ldt_sel_name
    xor cl,cl
    mov ax,create_ldt_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET create_tss_sel
    mov edi,OFFSET create_tss_sel_name
    xor cl,cl
    mov ax,create_tss_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET create_call_gate_sel16
    mov edi,OFFSET create_call_gate_sel16_name
    xor cl,cl
    mov ax,create_call_gate_sel16_nr
    RegisterOsGate
;
    mov esi,OFFSET create_call_gate_sel32
    mov edi,OFFSET create_call_gate_sel32_name
    xor cl,cl
    mov ax,create_call_gate_sel32_nr
    RegisterOsGate
;
    mov esi,OFFSET create_task_gate_sel
    mov edi,OFFSET create_task_gate_sel_name
    xor cl,cl
    mov ax,create_task_gate_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET get_sel_bitness
    mov edi,OFFSET get_sel_bitness_name
    xor cl,cl
    mov ax,get_sel_bitness_nr
    RegisterOsGate
;
    ret
init_os_protseg ENDP

    public init_user_protseg

init_user_protseg       PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_selector_info
    mov edi,OFFSET get_selector_info_name
    xor dx,dx
    mov ax,get_selector_info_nr
    RegisterBimodalUserGate
;
    ret
init_user_protseg       ENDP

code    ENDS

    END
