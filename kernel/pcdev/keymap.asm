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
; KEYMAP.ASM
; Keyboard mapper module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\os\port.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE key.inc

scan_table_entry    STRUC

st_offs DW ?
st_sel  DW ?
st_next DW ?
st_name DB 3 DUP(?)

scan_table_entry    ENDS

data    SEGMENT byte public 'DATA'

curr_scan   DW ?
scan_list   DW ?

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           dummy_scan
;
;           DESCRIPTION:    Handle unsupported keys
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
dummy_scan      PROC near
    stc 
    ret
dummy_scan      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           state_scan
;
;           DESCRIPTION:    Handle state key
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
state_scan      PROC near
    and ax,80h
    clc
    ret
state_scan      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           del_scan
;
;           DESCRIPTION:    Handle DEL key
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
del_scan    PROC near
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
;
    and cx,alt_pressed OR ctrl_pressed
    cmp cx,alt_pressed OR ctrl_pressed
    jne num_scan
;
    SoftReset
    ret
del_scan    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:       esc_scan
;
;           DESCRIPTION:    Handle ESC key
;
;           PARAMETERS:     AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
esc_scan    PROC near
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
;
    and cx,alt_pressed OR ctrl_pressed
    cmp cx,alt_pressed OR ctrl_pressed
    jne simple_scan
;
    CrashGate
    ret
esc_scan    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           handle_scan
;
;           DESCRIPTION:    Handle a scan
;
;           PARAMETERS:         AL      scan code
;               CX      State
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_scan Proc near
    test cx,ctrl_pressed
    jz handle_not_ctrl
;
    mov ah,cs:[bx].ctrl_code
    cmp ah,-1
    jne handle_check

handle_not_ctrl:
    test cx,alt_pressed
    jz handle_not_alt
;
    mov ah,cs:[bx].alt_code
    cmp ah,-1
    jne handle_check

handle_not_alt:
    test cx,shift_pressed
    jz handle_not_shift
;
    mov ah,cs:[bx].shift_code
    cmp ah,-1
    jne handle_check

handle_not_shift:
    mov ah,cs:[bx].normal_code

handle_check:
    or ah,ah
    jne handle_no_ext
;
    mov cl,al
    movzx ax,byte ptr cs:[bx].ext_code
    and cl,80h
    or al,cl
    
handle_no_ext:
    clc
    ret
handle_scan Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           simple_scan
;
;           DESCRIPTION:    Handle normal keys
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
simple_scan     PROC near
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
    call handle_scan
    ret
simple_scan     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           caps_scan
;
;           DESCRIPTION:    Handle case sensitive keys
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
caps_scan       PROC near
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
;
    and cx,107h
    xor cl,ch
    and cx,7
    call handle_scan
    ret
caps_scan       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           num_scan
;
;           DESCRIPTION:    Handle numeric keys
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
num_scan    PROC near
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
;
    and cx,205h
    shr ch,1
    xor cl,ch
    xor ch,ch
    add bx,cx
    cmp cx,1
    jne num_sc_no_num
;
    mov ah,cs:[bx]
    jmp num_sc_end
    
num_sc_no_num:
    mov cl,al
    movzx ax,byte ptr cs:[bx]
    and cl,80h
    or al,cl

num_sc_end:
    clc
    ret
num_scan    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           f_key_scan
;
;           DESCRIPTION:    Handle function keys
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
f_key_scan      PROC near
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
    call handle_scan
    xor ah,ah
    ret
f_key_scan      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           decode_scan_code
;
;           DESCRIPTION:    Decode scan code
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

key_type_tab:
kt00    DW OFFSET dummy_scan
kt01    DW OFFSET simple_scan
kt02    DW OFFSET caps_scan
kt03    DW OFFSET state_scan
kt04    DW OFFSET num_scan
kt05    DW OFFSET del_scan
kt06    DW OFFSET f_key_scan
kt07    DW OFFSET esc_scan

process_key_scan_name   DB 'Process Key Scan', 0

process_key_scan   Proc far 
    push ds
    push es
    pusha
;
    mov bx,SEG data
    mov ds,bx
    mov ds,ds:curr_scan
    movzx bx,al
    and bl,7Fh
    mov dh,al
    shl bx,3
    add bx,ds:st_offs
    mov es,ds:st_sel
;
    xor di,di
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
    test cx,ext_numpad_active
    jz proc_scan_get_vk
;
    inc di
    
proc_scan_get_vk:
    mov dl,byte ptr es:[bx+di].vk_code
;
    movzx di,byte ptr es:[bx].key_type
    add di,di
    call word ptr es:[di].key_type_tab
    jc proc_scan_done
;
    PutKeyboardCode

proc_scan_done:
    popa
    pop es
    pop ds
    retf32
process_key_scan    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddScanTable
;
;           DESCRIPTION:    Adds new scan-table
;
;       PARAMETERS:     DS:BX      Table offset
;               ES:DI      Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddScanTable    Proc near
    push ds
    push es
    push fs
    push eax
    push si
    push di
;    
    mov ax,es
    mov fs,ax
    mov eax,SIZE scan_table_entry
    AllocateSmallGlobalMem
    mov es:st_offs,bx
    mov es:st_sel,ds
;
    mov ax,fs:[di]
    mov word ptr es:st_name,ax
    mov byte ptr es:st_name+2,0
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:scan_list    
    mov es:st_next,ax
    mov ds:scan_list,es
;
    pop di
    pop si
    pop eax
    pop fs
    pop es
    pop ds    
    ret
AddScanTable    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddInternal
;
;           DESCRIPTION:    Add internal scan-tables
;
;       PARAMETERS:     DS:BX      Table offset
;               ES:DI      Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn scan_tab_fr:near
    extrn scan_tab_sw:near
    extrn scan_tab_uk:near
    extrn scan_tab_us:near

name_fr DB 'fr', 0
name_sw DB 'sw', 0
name_uk DB 'uk', 0
name_us DB 'us', 0

AddInternal    Proc near
    push ds
    push es
    push bx
    push di
;
    mov bx,cs
    mov ds,bx
    mov es,bx
;    
    mov bx,OFFSET scan_tab_fr
    mov di,OFFSET name_fr
    call AddScanTable
;    
    mov bx,OFFSET scan_tab_sw
    mov di,OFFSET name_sw
    call AddScanTable
;    
    mov bx,OFFSET scan_tab_uk
    mov di,OFFSET name_uk
    call AddScanTable
;    
    mov bx,OFFSET scan_tab_us
    mov di,OFFSET name_us
    call AddScanTable
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:scan_list
    mov ds:curr_scan,ax    
;
    pop di
    pop bx
    pop es
    pop ds    
    ret
AddInternal    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Get keyboard layout
;
;           DESCRIPTION:    Get current keyboard layout
;
;       PARAMETERS:     ES:(E)DI      Buffer (must be at least 3 bytes)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_key_layout_name DB 'Get Keyboard Layout', 0

get_key_layout  Proc near
    push ds
    push ax
;    
    mov byte ptr es:[edi],0
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:curr_scan
    or ax,ax
    jz gklDone
;
    mov ds,ax
    mov ax,word ptr ds:st_name
    mov es:[edi],ax
    mov byte ptr es:[edi+2],0

gklDone:
    pop ax
    pop ds
    ret
get_key_layout  Endp

get_key_layout16    Proc far
    push edi
    movzx edi,di
    call get_key_layout
    pop edi
    retf32
get_key_layout16    Endp

get_key_layout32    Proc far
    call get_key_layout
    retf32
get_key_layout32    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Set keyboard layout
;
;           DESCRIPTION:    Set current keyboard layout
;
;       PARAMETERS:     ES:(E)DI      Requested layout name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_key_layout_name DB 'Set Keyboard Layout', 0

set_key_layout  Proc near
    push ds
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:scan_list

sklLoop:
    or ax,ax
    stc
    jz sklDone
;
    mov ds,ax
    mov ax,word ptr ds:st_name
    cmp ax,es:[edi]
    je sklSet
;
    mov ax,ds:st_next
    jmp sklLoop

sklSet:
    push ds
    mov ax,SEG data
    mov ds,ax
    pop ax
    mov ds:curr_scan,ax
    clc
    
sklDone:
    pop ax
    pop ds
    ret
set_key_layout  Endp

set_key_layout16    Proc far
    push edi
    movzx edi,di
    call set_key_layout
    pop edi
    retf32
set_key_layout16    Endp

set_key_layout32    Proc far
    call set_key_layout
    retf32
set_key_layout32    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init
;
;           DESCRIPTION:    Init device-driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    push es
    push edi
;    
    call AddInternal
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET process_key_scan
    mov edi,OFFSET process_key_scan_name
    xor cl,cl
    mov ax,process_key_scan_nr
    RegisterOsGate
;
    mov ebx,OFFSET get_key_layout16
    mov esi,OFFSET get_key_layout32
    mov edi,OFFSET get_key_layout_name
    mov dx,virt_es_in
    mov ax,get_key_layout_nr
    RegisterUserGate
;
    mov ebx,OFFSET set_key_layout16
    mov esi,OFFSET set_key_layout32
    mov edi,OFFSET set_key_layout_name
    mov dx,virt_es_in
    mov ax,set_key_layout_nr
    RegisterUserGate
;
    pop edi
    pop es
    call set_key_layout
    clc
    ret
init    ENDP

code    ENDS

    END init
