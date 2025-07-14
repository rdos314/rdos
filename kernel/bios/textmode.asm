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
; TEXTMODE.ASM
; PC based text-mode support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE video.inc

video_object    STRUC

v_base      video_api_struc <>
v_buf_sel       DW ?
v_buf_base      DD ?
v_mem_base      DD ?
v_has_focus     DB ?

video_object    ENDS

    extrn ClearVideoObj:near
    extrn GetVideoObj:near
    extrn SetVideoObj:near

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetCursorPhysical
;
;           DESCRIPTION:    Set cursor position
;
;           PARAMETERS:         DS          Object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetCursorPhysical       Proc near
    push ax
    push bx
    push edx
;
    mov ax,80
    mul ds:v_row
    add ax,ds:v_col
    mov bx,ax
;
    mov edx,ds:v_mem_base
    cmp edx,0B0000h
    mov dx,3B4h
    je set_curs_phys_do
    mov dx,3D4h

set_curs_phys_do:
    mov al,0Eh
    out dx,al
;
    inc dx
    mov al,bh
    out dx,al
;
    dec dx
    mov al,0Fh
    out dx,al
;
    inc dx
    mov al,bl
    out dx,al
;
    pop edx
    pop bx
    pop ax
    ret
SetCursorPhysical       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           switch_to
;
;           DESCRIPTION:    Enter focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

switch_to       Proc far
    push es
    pushad
;
    call GetVideoObj
    or ax,ax
    jnz switch_check_mode
;
    mov ax,ds:v_mode
    cmp ax,3
    je switch_mode_done
    jmp switch_set_mode

switch_check_mode:
    cmp ax,-1
    je switch_set_mode
;
    mov es,ax
    mov ax,es:v_mode
    cmp ax,ds:v_mode
    je switch_mode_done

switch_set_mode:
    push ds
    mov ax,ds:v_mode
    xor bx,bx
    mov ds,bx
    mov es,bx
    push 10h
    V86BiosInt
    pop ds

switch_mode_done:
    mov ax,ds
    call SetVideoObj
    call SetCursorPhysical
;
    mov edx,ds:v_mem_base
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,edx
    or ax,80Bh
    SetPageEntry
;
    EnterSection ds:v_section
    push ds
    push ebx
    GetFocusThread
    mov bp,ax
    mov edx,ds:v_mem_base
    xor cx,cx
    mov eax,edx
    xor ebx,ebx
    or ax,807h
    SetThreadPageEntry
    pop ebx
;
    mov ds:v_has_focus,1
    mov ds,ds:v_buf_sel
    xor si,si
    mov cx,dosB800
    mov es,cx
    xor di,di
    mov cx,400h
    rep movsd
;
    pop ds
    LeaveSection ds:v_section
;
    pop ebx
    pop eax
;    
    push ax
    GetFocusThread
    mov es,ax
    mov edx,es:p_cr3
    GetThread
    mov es,ax
    pop ax
    cmp edx,es:p_cr3
    je switch_to_done
;
    or ax,80Bh
    mov edx,ds:v_mem_base
    SetPageEntry

switch_to_done:
    popad
    pop es
    retf32
switch_to       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SwitchFrom
;
;           DESCRIPTION:    Leave focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

switch_from     Proc far
    push es
    pushad
;
    call GetVideoObj
    or ax,ax
    jz switch_from_done
;
    mov edx,ds:v_mem_base
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,edx
    xor ebx,ebx
    or ax,80Bh
    SetPageEntry
;
    EnterSection ds:v_section
    push ds
    mov ds:v_has_focus,0
    mov es,ds:v_buf_sel
    xor di,di
    mov cx,dosB800
    mov ds,cx
    xor si,si
    mov cx,400h
    rep movsd
    pop ds
;
    GetFocusThread
    mov bp,ax
    mov es,bp
    mov edx,ds:v_buf_base
    GetPageEntry
    or ax,807h
    xor cx,cx
    mov edx,ds:v_mem_base
    SetThreadPageEntry
    LeaveSection ds:v_section

    mov edx,es:p_cr3
    GetThread
    mov es,ax
;
    pop ebx
    pop eax    
;    
    cmp edx,es:p_cr3
    je switch_from_done
;
    mov edx,ds:v_mem_base
    or ax,80Bh
    SetPageEntry

switch_from_done:
    popad
    pop es
    retf32
switch_from     Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetCursorPos
;
;           DESCRIPTION:    Set cursor position
;
;           PARAMETERS:         DX              ROW
;                           CX              COL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cursor_pos  PROC far
    push ax
    push bx
    push dx
;
    EnterSection ds:v_section
    mov ds:v_row,dx
    mov ds:v_col,cx
    mov al,ds:v_has_focus
    or al,al
    jz set_cursor_done
;
    call SetCursorPhysical

set_cursor_done:
    LeaveSection ds:v_section
;
    pop dx
    pop bx
    pop ax
    retf32
set_cursor_pos  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteChar
;
;           DESCRIPTION:    Write a char
;
;           PARAMETERS:         AL          Char
;                           BL          Fore color
;                           BH          Back color
;                           CX          Column
;                           DX          Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_char      Proc far
    push ax
    push edi
;
    EnterSection ds:v_section
    push ds
    mov ah,bh
    shl ah,4
    or ah,bl
    push ax
    push dx
;
    mov ds:v_col,cx
    mov ds:v_row,dx
    mov ax,80
    mul dx
    add ax,cx
    add ax,ax
    mov di,ax
    mov ax,dosB800
    mov ds,ax
    pop dx
    pop ax
    mov [di],ax
    pop ds
    LeaveSection ds:v_section
;
    pop edi
    pop ax
    retf32
write_char      Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReadChar
;
;           DESCRIPTION:    Read a char
;
;           PARAMETERS:         CX          Column
;                           DX          Row
;
;           RETURNS:        AL          Char
;                           BL          Fore color
;                           BH          Back color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_char       Proc far
    push ds
    push dx
    push edi
;
    mov ax,80
    mul dx
    add ax,cx
    add ax,ax
    mov di,ax
    mov ax,dosB800
    mov ds,ax
    mov ax,[di]
    mov bh,ah
    mov bl,ah
    shr bh,4
    and bl,0Fh
;
    pop edi
    pop dx
    pop ds
    retf32
read_char       Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           clear
;
;           DESCRIPTION:    Clear display region
;
;           PARAMETERS:         BL          Blank fore color
;                           BH          Blank back color
;                           CX          Upper Column
;                           DX          Upper Row
;                           SI          Lower Column
;                           DI          Lower Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear   Proc far
    push ax
    push dx
;
    EnterSection ds:v_section
    push ds
    push es
    mov ax,dosB800
    mov ds,ax
    mov es,ax
;
    mov ah,bh
    shl ah,4
    or ah,bl
    mov al,' '

clear_row_loop:
    push di
    push ax
    push dx
    mov ax,80
    mul dx
    mov di,ax
    add di,cx
    add di,di
    pop dx
    pop ax

    push cx
    sub cx,si
    neg cx
    stosw
    rep stosw
    pop cx
    pop di
;
    inc dx
    cmp di,dx
    jae clear_row_loop

clear_done:
    pop es
    pop ds
    LeaveSection ds:v_section
;
    pop dx
    pop ax
    retf32
clear   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           scroll_up
;
;           DESCRIPTION:    Scroll display up
;
;           PARAMETERS:         AX          Number of rows
;                           BL          Blank fore color
;                           BH          Blank back color
;                           CX          Upper Column
;                           DX          Upper Row
;                           SI          Lower Column
;                           DI          Lower Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

suLowerRow      EQU 0
suLowerCol      EQU 2
suRows      EQU 4

scroll_up       Proc far
    push ebp
    sub esp,6
    mov ebp,esp
;
    push ax
    push dx
    push si
    push di
    EnterSection ds:v_section
    push ds
    push es
;
    mov [ebp].suLowerRow,di
    mov [ebp].suLowerCol,si
    mov [ebp].suRows,ax
;
    mov ax,dosB800
    mov ds,ax
    mov es,ax

scroll_up_row_loop:
    push dx
    mov ax,80
    mul dx
    mov di,ax
    add di,cx
;
    mov ax,80
    mul word ptr [ebp].suRows
    mov si,ax
    add si,di
    add si,si
    add di,di
    pop dx
;
    mov ax,[ebp].suRows
    add ax,dx
    cmp ax,[ebp].suLowerRow
    ja scroll_up_clear
;
    push cx
    sub cx,[ebp].suLowerCol
    neg cx
    movsw
    rep movsw
    pop cx
;
    cmp dx,[ebp].suLowerRow
    jae scroll_up_done
;
    inc dx
    jmp scroll_up_row_loop

scroll_up_clear:
    mov ah,bh
    shl ah,4
    or ah,bl
    mov al,' '

scroll_up_clear_row_loop:
    push ax
    push dx
    mov ax,80
    mul dx
    mov di,ax
    add di,cx
    add di,di
    pop dx
    pop ax
;
    push cx
    sub cx,[ebp].suLowerCol
    neg cx
    stosw
    rep stosw
    pop cx
;
    cmp dx,[ebp].suLowerRow
    jae scroll_up_done
;
    inc dx
    jmp scroll_up_clear_row_loop

scroll_up_done:
    pop es
    pop ds
    LeaveSection ds:v_section
;
    pop di
    pop si
    pop dx
    pop ax
    add esp,6
    pop ebp
    retf32
scroll_up       Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           scroll_down
;
;           DESCRIPTION:    Scroll display down
;
;           PARAMETERS:         BL          Blank fore color
;                           BH          Blank back color
;                           CX          Upper Column
;                           DX          Upper Row
;                           SI          Lower Column
;                           DI          Lower Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sdUpperRow      EQU 0
sdLowerCol      EQU 2
sdRows      EQU 4

scroll_down     Proc far
    push ebp
    sub esp,6
    mov ebp,esp
;
    push ax
    push dx
    push si
    push di
    EnterSection ds:v_section
    push ds
    push es
;
    mov [ebp].sdUpperRow,dx
    mov [ebp].sdLowerCol,si
    mov [ebp].sdRows,ax
    mov dx,di
;
    mov ax,dosB800
    mov ds,ax
    mov es,ax

scroll_down_row_loop:
    push dx
    mov ax,80
    mul dx
    mov di,ax
    add di,cx
;
    mov ax,80
    mul word ptr [ebp].sdRows
    mov si,di
    sub si,ax
    add si,si
    add di,di
    pop dx
;
    mov ax,dx
    sub ax,[ebp].sdRows
    jc scroll_down_clear
    cmp ax,[ebp].sdUpperRow
    jb scroll_down_clear
;
    push cx
    sub cx,[ebp].sdLowerCol
    neg cx
    movsw
    rep movsw
    pop cx
;
    cmp dx,[ebp].sdUpperRow
    jbe scroll_down_done
;
    dec dx
    jmp scroll_down_row_loop

scroll_down_clear:
    mov ah,bh
    shl ah,4
    or ah,bl
    mov al,' '

scroll_down_clear_row_loop:
    push ax
    push dx
    mov ax,80
    mul dx
    mov di,ax
    add di,cx
    add di,di
    pop dx
    pop ax
;
    push cx
    sub cx,[ebp].sdLowerCol
    neg cx
    stosw
    rep stosw
    pop cx
;
    cmp dx,[ebp].sdUpperRow
    jbe scroll_down_done
;
    dec dx
    jmp scroll_down_clear_row_loop

scroll_down_done:
    pop es
    pop ds
    LeaveSection ds:v_section
;
    pop di
    pop si
    pop dx
    pop ax
    add esp,6
    pop ebp
    retf32
scroll_down     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_mode3
;
;           DESCRIPTION:    Init video-mode 3
;
;           RETURNS:        AX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_mode3      Proc far
    push ds
    push es
    push ebx
    push cx
    push si
    push di
;
    mov eax,SIZE video_object
    AllocateSmallGlobalMem
    mov cx,35
    mov ax,cs
    mov ds,ax
    mov si,OFFSET ModeTab
    xor di,di
    rep movsd
;
    push es
    mov eax,1000h
    AllocateBigLinear
    AllocateGdt
    mov ecx,eax
    CreateDataSelector16
    mov es,bx
    mov ax,0720h
    xor di,di
    mov cx,800h
    rep stosw
    pop ax
;
    mov ds,ax
    mov ds:v_mode,3
    mov ds:v_buf_base,edx
    mov ds:v_app_base,edx
    mov ds:v_buf_sel,es
    mov ds:v_has_focus,0
    mov ds:v_row,0
    mov ds:v_col,0
    mov ds:v_width,80
    mov ds:v_height,25
    mov ds:v_bitmap,0
    mov ds:v_row_size,50
    mov ds:v_bpp,0 
       
    InitSection ds:v_section
;
    mov bx,gdt_sel
    mov es,bx
    mov bx,DosB800
    mov edx,es:[bx+2]
    rol edx,8
    mov dl,es:[bx+7]
    ror edx,8
    mov ds:v_mem_base,edx
;
    push ax
    mov edx,0B0000h
    xor eax,eax
    xor ebx,ebx

init_mono_loop:
    SetPageEntry
    add edx,1000h
    cmp edx,0C0000h
    jne init_mono_loop
;
    mov edx,ds:v_buf_base
    GetPageEntry
    or ax,80Bh
    mov edx,ds:v_mem_base
    SetPageEntry
    pop ax
    clc
;
    pop di
    pop si
    pop cx
    pop ebx
    pop es
    pop ds
    retf32
init_mode3      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_mode3
;
;           DESCRIPTION:    Delete video-mode 3
;
;           RETURNS:        DS          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_mode3    Proc far
    push ax
    push bx
    push ecx
    push edx
;
    call ClearVideoObj
;
    mov bx,ds:v_buf_sel
    FreeGdt
    mov edx,ds:v_buf_base
    mov ecx,1000h
    FreeLinear
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem
;
    pop edx
    pop ecx
    pop bx
    pop ax
    retf32
delete_mode3    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ModeTab
;
;           DESCRIPTION:    Dispatch table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error   Proc far
    stc
    retf32
error   Endp

ModeTab:
mt00 DD OFFSET delete_mode3,    SEG code
mt01 DD OFFSET switch_to,           SEG code
mt02 DD OFFSET switch_from,         SEG code
mt03 DD OFFSET clear,           SEG code
mt04 DD OFFSET set_cursor_pos,  SEG code
mt05 DD OFFSET write_char,          SEG code
mt06 DD OFFSET read_char,           SEG code
mt07 DD OFFSET scroll_up,           SEG code
mt08 DD OFFSET scroll_down,         SEG code
mt09 DD OFFSET error,           SEG code
mt0A DD OFFSET error,           SEG code
mt0B DD OFFSET error,           SEG code
mt0C DD OFFSET error,           SEG code
mt0D DD OFFSET error,           SEG code
mt0E DD OFFSET error,           SEG code
mt0F DD OFFSET error,           SEG code
mt10 DD OFFSET error,           SEG code
mt11 DD OFFSET error,           SEG code
mt12 DD OFFSET error,           SEG code
mt13 DD OFFSET error,           SEG code
mt14 DD OFFSET error,           SEG code
mt15 DD OFFSET error,           SEG code
mt16 DD OFFSET error,           SEG code
mt17 DD OFFSET error,           SEG code
mt18 DD OFFSET error,           SEG code
mt19 DD OFFSET error,           SEG code
mt1A DD OFFSET error,           SEG code
mt1B DD OFFSET error,           SEG code
mt1C DD OFFSET error,           SEG code
mt1D DD OFFSET error,           SEG code
mt1E DD OFFSET error,           SEG code
mt1F DD OFFSET error,           SEG code
mt20 DD OFFSET error,           SEG code
mt21 DD OFFSET error,           SEG code
mt22 DD OFFSET error,           SEG code
mt23 DD OFFSET error,           SEG code
mt24 DD OFFSET error,           SEG code
mt25 DD OFFSET error,           SEG code
mt26 DD OFFSET error,           SEG code
mt27 DD OFFSET error,           SEG code
mt28 DD OFFSET error,           SEG code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_text_mode
;
;           DESCRIPTION:    Init text-mode support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_text_mode

init_text_mode  Proc near       
    mov ax,cs
    mov es,ax       
    mov ax,3
    xor bl,bl
    mov cx,80
    mov dx,25
    mov edi,OFFSET init_mode3
    RegisterVideoMode
    ret
init_text_mode  Endp

code    ENDS

    END

