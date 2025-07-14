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
; MOUSE.ASM
; Basic mouse support module.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.inc
INCLUDE ..\wait.inc
INCLUDE video.inc

mouse_wait_header       STRUC

mw_obj          wait_obj_header <>
mw_counter          DD ?

mouse_wait_header       ENDS

data    SEGMENT byte public 'DATA'

md_buttons          DW ?
md_dx           DW ?
md_dy           DW ?
md_x        DW ?
md_y        DW ?
md_mouse_thread DW ?

md_swap_xy      DB ?
md_swap_x       DB ?
md_swap_y       DB ?
md_area_x       DW ?
md_area_y       DW ?
md_space_x       DW ?
md_space_y       DW ?

md_div          DD ?
md_xx           DD ?
md_xy           DD ?
md_xo           DD ?
md_yx           DD ?
md_yy           DD ?
md_yo           DD ?

data    ENDS

    .386p

code    SEGMENT byte public 'CODE'

    assume cs:code

    extrn GetLocalConsole:near

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetValue
;
;       Purpose:        Get value from environment
;
;       Parameters:     ES:DI   Name
;
;       Returns:        NC      Found
;                       AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
GetValue    Proc near
    push ds
    push bx
    push cx
    push si
;
    LockSysEnv
    mov ds,bx
    xor si,si
    
find_val:
    push di

find_val_loop:
    cmpsb
    jnz find_val_next
;       
    mov al,es:[di]
    or al,al
    jnz find_val_loop
    mov al,[si]
    cmp al,'='
    je find_val_found

find_val_next:
    pop di

find_val_next_bp:
    lodsb
    or al,al
    jnz find_val_next_bp
;
    mov al,[si]
    or al,al
    jne find_val
;
    xor ax,ax
    stc
    jmp find_val_done

find_val_found:
    pop di
    inc si  
    xor ax,ax

find_val_digit:
    mov bl,[si]
    inc si
    sub bl,'0'
    jc find_val_save
;
    cmp bl,10
    jnc find_val_save
;       
    mov cx,10
    mul cx
    add al,bl
    adc ah,0
    jmp find_val_digit

find_val_save:
    clc

find_val_done:
    pushf
    UnlockSysEnv
    popf
;
    pop si
    pop cx
    pop bx
    pop ds
    ret
GetValue    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           RecalcX
;
;   DESCRIPTION:    Recalc X
;
;   PARAMETERS:     AX     Value (0..32767)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecalcX   Proc near
    push ecx
    push edx
    push esi
    push edi
;
    movzx eax,ax
    cmp ds:md_swap_x,0
    je rSwapXOk
;
    mov edx,eax
    mov eax,32767
    sub eax,edx

rSwapXOk:
    movzx edx,ds:md_space_x
    or edx,edx
    jz rAreaX
;
    sub ax,dx
    jnc rSpaceXOk
;
    xor ax,ax

rSpaceXOk:
    shl edx,1
    mov ecx,7FFFh
    sub ecx,edx
    movzx eax,ax
    shl eax,16
    xor edx,edx
    div ecx
    shr eax,1
    cmp ax,7FFFh
    jbe rAreaX
;
    mov ax,7FFFh

rAreaX:
    movzx edx,ds:md_area_x
    or edx,edx
    jz rDoneX
;
    push eax
    movzx eax,dx
    shl eax,16
    xor edx,edx
;
    mov ecx,100
    div ecx
    mov esi,eax
;
    pop eax
    shl eax,16
    xor edx,edx
    div esi
    mov edi,eax
;
    mov eax,10000h
    sub eax,esi
    shr eax,2
    shl eax,16
    xor edx,edx
    div esi
;
    sub edi,eax
    mov eax,edi    
    test eax,80000000h
    jz rPosX
;
    xor eax,eax

rPosX:
    cmp eax,32767
    jb rDoneX
;
    mov eax,32767    

rDoneX:    
    pop edi
    pop esi
    pop edx
    pop ecx
    ret
RecalcX  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           RecalcY
;
;   DESCRIPTION:    Recalc Y
;
;   PARAMETERS:     AX     Value (0..32767)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecalcY   Proc near
    push ecx
    push edx
    push esi
    push edi
;
    movzx eax,ax
    cmp ds:md_swap_y,0
    je rSwapYOk
;
    mov edx,eax
    mov eax,32767
    sub eax,edx

rSwapYOk:
    movzx edx,ds:md_space_y
    or edx,edx
    jz rAreaY
;
    sub ax,dx
    jnc rSpaceYOk
;
    xor ax,ax

rSpaceYOk:
    shl edx,1
    mov ecx,7FFFh
    sub ecx,edx
    movzx eax,ax
    shl eax,16
    xor edx,edx
    div ecx
    shr eax,1
    cmp ax,7FFFh
    jbe rAreaY
;
    mov ax,7FFFh

rAreaY:
    movzx edx,ds:md_area_y
    or edx,edx
    jz rDoneY
;
    push eax
    movzx eax,dx
    shl eax,16
    xor edx,edx
;
    mov ecx,100
    div ecx
    mov esi,eax
;
    pop eax
    shl eax,16
    xor edx,edx
    div esi
    mov edi,eax
;
    mov eax,10000h
    sub eax,esi
    shr eax,2
    shl eax,16
    xor edx,edx
    div esi
;
    sub edi,eax
    mov eax,edi    
    test eax,80000000h
    jz rPosY
;
    xor eax,eax

rPosY:
    cmp eax,32767
    jb rDoneY
;
    mov eax,32767    

rDoneY:    
    pop edi
    pop esi
    pop edx
    pop ecx
    ret
RecalcY  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           hide_marker
;
;           DESCRIPTION:    hide marker
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hide_marker     PROC near
    push ds
    push ax
    push bx
    push cx
    push dx
;
    mov ax,ds:c_m_cursor_flag
    or ax,ax
    jz hide_marker_done
;
    test ah,80h
    jnz hide_marker_done
;
    mov cx,ds:c_m_marker_x
    mov dx,ds:c_m_marker_y
    InvertMouse

hide_marker_done:
    pop dx
    pop cx
    pop bx
    pop ax
    pop ds
    ret
hide_marker     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           show_marker
;
;           DESCRIPTION:    show marker
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show_marker     PROC near
    push ds
    push ax
    push bx
    push cx
    push dx
;
    mov ax,ds:c_m_cursor_flag
    or ax,ax
    jz show_marker_done
;
    test ah,80h
    jnz show_marker_done
;
    mov ax,ds:c_m_horiz_pos
    xor dx,dx
    div ds:c_m_horiz_mickey
    mov cx,ax
;
    mov ax,ds:c_m_vert_pos
    xor dx,dx
    div ds:c_m_vert_mickey
    mov dx,ax
;
    mov ds:c_m_marker_x,cx
    mov ds:c_m_marker_y,dx
    InvertMouse

show_marker_done:
    pop dx
    pop cx
    pop bx
    pop ax
    pop ds
    ret
show_marker     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetMouseLimit
;
;           DESCRIPTION:    Set mouse limits for touch-screens
;
;           PARAMETERS:         CX          MaxX
;                               DX      MaxY
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_mouse_limit_name    DB 'Set Mouse Limit',0

set_mouse_limit PROC far
    push ds
;       
    call GetLocalConsole
    mov ds:c_m_horiz_limit,cx
    mov ds:c_m_vert_limit,dx
;       
    pop ds
    ret
set_mouse_limit ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           update_mouse
;
;           DESCRIPTION:    update mouse from IRQ
;
;           PARAMETERS:         AX          Buttons
;                               CX          Dx
;                               DX      Dy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_mouse_name       DB 'Update Mouse',0

update_mouse    PROC far
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
    mov ds:md_buttons,ax
    add ds:md_dx,cx
    neg dx
    add ds:md_dy,dx
    mov bx,ds:md_mouse_thread
;
    push bx
    GetFocusConsole
    mov ds,ebx
    or bx,bx
    pop bx
    jz update_mouse_done
;
    inc ds:c_m_counter
    mov ax,ds:c_m_notify_thread
    or ax,ax
    jz mouse_int_signal
;
    mov bx,ax

mouse_int_signal:
    Signal
;
    xor bx,bx
    xchg bx,ds:c_m_avail_obj
    or bx,bx
    jz update_mouse_done
;
    mov es,bx
    SignalWait

update_mouse_done:
    pop bx
    pop ds
    ret
update_mouse    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           set_mouse
;
;           DESCRIPTION:    Set mouse from IRQ
;
;           PARAMETERS:     AX          Buttons
;                           CX          AbsX
;                           DX      AbsY
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_mouse_name  DB 'Set Mouse',0

set_mouse       PROC far
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
    mov ds:md_buttons,ax
;
    mov eax,ds:md_div
    or eax,eax
    jz set_mouse_not_cal
;
    pushad
;
    mov ds:md_x,cx
    mov ds:md_y,dx
    mov ecx,ds:md_div
;
    mov eax,ds:md_xo
    cdq
    mov esi,eax
    mov edi,edx
;
    movzx eax,ds:md_x
    imul ds:md_xx
    add esi,eax
    adc edi,edx
;
    movzx eax,ds:md_y
    imul ds:md_xy
    add eax,esi
    adc edx,edi
;
    idiv ecx
    mov ebx,eax
;
    test ebx,80000000h
    jnz set_mouse_x_ok
;
    cmp ebx,8000h
    jb set_mouse_x_ok
;
    mov bx,7FFFh

set_mouse_x_ok:
    mov eax,ds:md_yo
    cdq
    mov esi,eax
    mov edi,edx
;
    movzx eax,ds:md_x
    imul ds:md_yx
    add esi,eax
    adc edi,edx
;
    movzx eax,ds:md_y
    imul ds:md_yy
    add eax,esi
    adc edx,edi
;
    idiv ecx
;
    test eax,80000000h
    jnz set_mouse_y_ok
;
    cmp eax,8000h
    jb set_mouse_y_ok
;
    mov ax,7FFFh

set_mouse_y_ok:
    mov ds:md_x,bx
    mov ds:md_y,ax
;
    popad
    jmp set_mouse_saved

set_mouse_not_cal:
    cmp ds:md_swap_xy,0
    je set_mouse_not_xy_swap

set_mouse_xy_swap:
    mov ax,dx
    call RecalcX
    mov ds:md_x,ax
;
    mov ax,cx
    call RecalcY
    mov ds:md_y,ax
    jmp set_mouse_saved

set_mouse_not_xy_swap:
    mov ax,cx
    call RecalcX
    mov ds:md_x,ax
;
    mov ax,dx
    call RecalcY
    mov ds:md_y,ax

set_mouse_saved:       
    mov bx,ds:md_mouse_thread
;
    push bx
    GetFocusConsole
    mov ds,ebx
    pop bx
;
    inc ds:c_m_counter
    mov ax,ds:c_m_notify_thread
    or ax,ax
    jz set_mouse_int_signal
;
    mov bx,ax

set_mouse_int_signal:
    Signal
;
    xor bx,bx
    xchg bx,ds:c_m_avail_obj
    or bx,bx
    jz set_mouse_done
;
    verr bx
    jnz set_mouse_done
;    
    mov es,bx
    SignalWait

set_mouse_done:
    pop bx
    pop ds
    ret
set_mouse       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           check_horiz_position
;
;           DESCRIPTION:    check horizontal position
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
check_horiz_position    PROC near
    push ax
    mov ax,ds:c_m_horiz_pos
    cmp ax,ds:c_m_horiz_min
    jge set_horiz_min_ok
    mov ax,ds:c_m_horiz_min
set_horiz_min_ok:
    cmp ax,ds:c_m_horiz_max
    jle set_horiz_max_ok
    mov ax,ds:c_m_horiz_max
set_horiz_max_ok:
    mov ds:c_m_horiz_pos,ax
    pop ax
    ret
check_horiz_position    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           check_vert_position
;
;           DESCRIPTION:    check vertical position
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_vert_position     PROC near
    push ax
    mov ax,ds:c_m_vert_pos
    cmp ax,ds:c_m_vert_min
    jge set_vert_min_ok
    mov ax,ds:c_m_vert_min
set_vert_min_ok:
    cmp ax,ds:c_m_vert_max
    jle set_vert_max_ok
    mov ax,ds:c_m_vert_max
set_vert_max_ok:
    mov ds:c_m_vert_pos,ax
    pop ax
    ret
check_vert_position     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           refresh_mouse
;
;           DESCRIPTION:    refresh mouse parameters
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

refresh_mouse   Proc near
    mov cx,0FFFFh
    xchg cx,es:md_x
    cmp cx,0FFFFh
    je update_abs_horiz_done
;
    shl cx,1
    mov ax,ds:c_m_horiz_limit
    mul cx
    mov ds:c_m_horiz_pos,dx
    
update_abs_horiz_done:
    mov cx,0FFFFh
    xchg cx,es:md_y
    cmp cx,0FFFFh
    je update_abs_vert_done
;
    shl cx,1
    mov ax,ds:c_m_vert_limit
    mul cx
    mov ds:c_m_vert_pos,dx

update_abs_vert_done:
    mov ax,es:md_buttons
    mov dx,ds:c_m_botton_status
    mov dh,al
    xor dl,al
    jz mouse_buttons_done
;
    mov ds:c_m_botton_status,ax
    test dl,1
    jz mouse_button1_handled
;
    test dh,1
    jz mouse_button1_released
mouse_button1_pressed:
    mov ax,ds:c_m_horiz_pos
    mov ds:c_m_horiz_press0,ax
    mov ax,ds:c_m_vert_pos
    mov ds:c_m_vert_press0,ax
    jmp mouse_button1_handled

mouse_button1_released: 
    mov ax,ds:c_m_horiz_pos
    mov ds:c_m_horiz_rel0,ax
    mov ax,ds:c_m_vert_pos
    mov ds:c_m_vert_rel0,ax

mouse_button1_handled:
    test dl,2
    jz mouse_buttons_done
;
    test dh,2
    jz mouse_button2_released

mouse_button2_pressed:
    mov ax,ds:c_m_horiz_pos
    mov ds:c_m_horiz_press1,ax
    mov ax,ds:c_m_vert_pos
    mov ds:c_m_vert_press1,ax
    jmp mouse_buttons_done

mouse_button2_released: 
    mov ax,ds:c_m_horiz_pos
    mov ds:c_m_horiz_rel1,ax
    mov ax,ds:c_m_vert_pos
    mov ds:c_m_vert_rel1,ax

mouse_buttons_done:
    xor cx,cx
    xchg cx,es:md_dx
    or cx,cx
    jz update_rel_horiz_done
;
    add ds:c_m_horiz_motion,cx
    add ds:c_m_horiz_pos,cx
    call check_horiz_position
    
update_rel_horiz_done:
    xor dx,dx
    xchg dx,es:md_dy
    or dx,dx
    jz update_rel_vert_done
;
    add ds:c_m_vert_motion,dx
    add ds:c_m_vert_pos,dx
    call check_vert_position

update_rel_vert_done:
    ret
refresh_mouse   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           reset
;
;           DESCRIPTION:    reset mouse params
;
;           PARAMETERS:      DS         Console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset   PROC near
    push ax
;
    xor ax,ax
    mov ds:c_m_notify_thread,ax
    mov ds:c_m_cursor_flag,ax
    mov ds:c_m_horiz_pos,ax
    mov ds:c_m_vert_pos,ax
    mov ds:c_m_marker_x,ax
    mov ds:c_m_marker_y,ax
    mov ds:c_m_botton_status,ax
    mov ds:c_m_horiz_motion,ax
    mov ds:c_m_vert_motion,ax
;
    mov ds:c_m_horiz_mickey,8
    mov ds:c_m_vert_mickey,8
;
    mov ds:c_m_horiz_min,ax
    mov ds:c_m_horiz_max,639
    mov ds:c_m_horiz_limit,640
    mov ds:c_m_vert_min,ax
    mov ds:c_m_vert_max,199
    mov ds:c_m_vert_limit,480
;
    mov ds:c_m_horiz_press0,ax
    mov ds:c_m_vert_press0,ax
    mov ds:c_m_count_press0,ax
;
    mov ds:c_m_horiz_press1,ax
    mov ds:c_m_vert_press1,ax
    mov ds:c_m_count_press1,ax
;
    mov ds:c_m_horiz_rel0,ax
    mov ds:c_m_vert_rel0,ax
    mov ds:c_m_count_rel0,ax
;
    mov ds:c_m_horiz_rel1,ax
    mov ds:c_m_vert_rel1,ax
    mov ds:c_m_count_rel1,ax
;
    pop ax
    ret
reset   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsMarkerVisible
;
;           DESCRIPTION:    Check for visible marker
;
;           RETURNS:        NC   Visible    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public IsMarkerVisible
    
IsMarkerVisible     PROC near
    push ds
    push ax
    push bx
;
    GetFocusConsole
    mov ds,ebx
    mov ax,ds:c_m_cursor_flag
    or ax,ax
    jz imvHidden

imvShown:
    clc
    jmp imvDone

imvHidden:
    stc

imvDone:
    pop bx
    pop ax
    pop ds
    ret
IsMarkerVisible     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           show_mouse
;
;           DESCRIPTION:    show mouse
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show_mouse_name DB 'Show Mouse',0

show_mouse      PROC far
    push ds
    push ax
;
    call GetLocalConsole
    call hide_marker
    inc ds:c_m_cursor_flag
    call show_marker
;
    pop ax
    pop ds
    ret
show_mouse      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           hide_mouse
;
;           DESCRIPTION:    hide mouse
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hide_mouse_name DB 'Hide Mouse',0

hide_mouse      PROC far
    push ds
    push ax
;
    call GetLocalConsole
    call hide_marker
    dec ds:c_m_cursor_flag
    call show_marker
;
    pop ax
    pop ds
    ret
hide_mouse      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           get_mouse_position
;
;           DESCRIPTION:    get position
;
;           RETURNS:        CX          X
;                           DX          Y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_mouse_position_name DB 'Get Mouse Position',0

get_mouse_position      PROC far
    push ds
;
    call GetLocalConsole
    mov cx,ds:c_m_horiz_pos
    mov dx,ds:c_m_vert_pos    
;
    pop ds
    ret
get_mouse_position      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           set_position
;
;           DESCRIPTION:    set position
;
;           PARAMETERS:         CX          X
;                           DX          Y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_mouse_position_name DB 'Set Mouse Position',0

set_mouse_position      PROC far
    push ds
    push ax
;
    call GetLocalConsole
    call hide_marker
    mov ds:c_m_horiz_pos,cx
    mov ds:c_m_vert_pos,dx
    call check_horiz_position
    call check_vert_position
    call show_marker
;
    pop ax
    pop ds
    ret
set_mouse_position      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           get_left_button
;
;           DESCRIPTION:    check if left mouse button is pressed
;
;           RETURNS:        NC          pressed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_left_button_name    DB 'Get Left Button',0

get_left_button PROC far
    push ds
    push ax
;
    call GetLocalConsole
    mov ax,ds:c_m_botton_status
    rcr al,1
    cmc
;
    pop ax
    pop ds
    ret
get_left_button ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           get_right_button
;
;           DESCRIPTION:    check if right mouse button is pressed
;
;           RETURNS:        NC          pressed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_right_button_name   DB 'Get Right Button',0

get_right_button    PROC far
    push ds
    push ax
;
    call GetLocalConsole
    mov ax,ds:c_m_botton_status
    rcr al,2
    cmc
;
    pop ax
    pop ds
    ret
get_right_button    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           get_left_button_press_position
;
;           DESCRIPTION:    get position of last left button press
;
;           RETURNS:        CX          x
;                           DX          y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_left_button_press_position_name     DB 'Get Left Button Press Position',0

get_left_button_press_position  PROC far
    push ds
    push ax
;
    call GetLocalConsole
    mov cx,ds:c_m_horiz_press0
    mov dx,ds:c_m_vert_press0
;
    pop ax
    pop ds
    ret
get_left_button_press_position  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           get_right_button_press_position
;
;           DESCRIPTION:    get position of last right button press
;
;           RETURNS:        CX          x
;                           DX          y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_right_button_press_position_name    DB 'Get Right Button Press Position',0

get_right_button_press_position PROC far
    push ds
    push ax
;
    call GetLocalConsole
    mov cx,ds:c_m_horiz_press1
    mov dx,ds:c_m_vert_press1
;
    pop ax
    pop ds
    ret
get_right_button_press_position ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           get_left_button_release_position
;
;           DESCRIPTION:    get position of last left button release
;
;           RETURNS:        CX          x
;                           DX          y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_left_button_release_position_name   DB 'Get Left Button Release Position',0

get_left_button_release_position    PROC far
    push ds
    push ax
;
    call GetLocalConsole
    mov cx,ds:c_m_horiz_rel0
    mov dx,ds:c_m_vert_rel0
;
    pop ax
    pop ds
    ret
get_left_button_release_position    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           get_right_button_release_position
;
;           DESCRIPTION:    get position of last right button release
;
;           RETURNS:        CX          x
;                           DX          y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_right_button_release_position_name  DB 'Get Right Button Release Position',0

get_right_button_release_position       PROC far
    push ds
    push ax
;
    call GetLocalConsole
    mov cx,ds:c_m_horiz_rel1
    mov dx,ds:c_m_vert_rel1
;
    pop ax
    pop ds
    ret
get_right_button_release_position       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           set_mouse_window
;
;           DESCRIPTION:    set window of mouse movement
;
;           PARAMETERS:         AX          start x
;                           BX          start y
;                           CX          end x
;                           DX          end y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_mouse_window_name   DB 'Set Mouse Window',0

set_mouse_window    PROC far
    push ds
;
    call GetLocalConsole
    call hide_marker
    mov ds:c_m_horiz_min,ax
    mov ds:c_m_horiz_max,cx
    mov ds:c_m_vert_min,bx
    mov ds:c_m_vert_max,dx
;
    call check_horiz_position
    call check_vert_position
    call show_marker
;
    pop ds
    ret
set_mouse_window    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           set_mouse_mickey
;
;           DESCRIPTION:    set mouse mickeys
;
;           PARAMETERS:         CX          mickeys in x-direction
;                           DX          mickeys in y-direction
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_mouse_mickey_name   DB 'Set Mouse Mickey',0

set_mouse_mickey    PROC far
    push ds
;
    call GetLocalConsole
    mov ds:c_m_horiz_mickey,cx
    mov ds:c_m_vert_mickey,dx
;
    pop ds
    ret
set_mouse_mickey    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForMouse
;
;           DESCRIPTION:    Start a wait for mouse
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_mouse    PROC far
    push ds
    push ax
    push bx
;
    call GetLocalConsole
    mov ds:c_m_avail_obj,es
    mov eax,ds:c_m_counter
    cmp eax,es:mw_counter
    je start_wait_for_done
;
    mov ds:c_m_avail_obj,0
    SignalWait

start_wait_for_done:
    pop bx
    pop ax
    pop ds
    ret
start_wait_for_mouse Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForMouse
;
;           DESCRIPTION:    Stop a wait for mouse
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_mouse     PROC far
    push ds
;
    call GetLocalConsole
    mov ds:c_m_avail_obj,0
;
    pop ds
    ret
stop_wait_for_mouse Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearMouse
;
;           DESCRIPTION:    Clear mouse
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_mouse     PROC far
    push ds
    push eax
;
    call GetLocalConsole
    mov eax,ds:c_m_counter
    mov es:mw_counter,eax
;
    pop eax
    pop ds
    ret
clear_mouse Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsMouseIdle
;
;           DESCRIPTION:    Check if mouse is idle
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_mouse_idle   PROC far
    push ds
    push ax
    push bx
;
    call GetLocalConsole
    mov eax,ds:c_m_counter
    cmp eax,es:mw_counter
    clc
    je is_idle_done
;
    stc

is_idle_done:
    pop bx
    pop ax
    pop ds
    ret
is_mouse_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForMouse
;
;           DESCRIPTION:    Add a wait for mouse
;
;           PARAMETERS:         BX      Wait handle
;               ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_mouse_name DB 'Add Wait For Mouse',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_mouse,     SEG code
aw1 DD OFFSET stop_wait_for_mouse,      SEG code
aw2 DD OFFSET clear_mouse,              SEG code
aw3 DD OFFSET is_mouse_idle,            SEG code

add_wait_for_mouse      PROC far
    push ds
    push es
    push eax
    push edi
;
    mov ax,cs
    mov es,ax
    mov ax,SIZE mouse_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWait
    jc add_wait_done
;
    call GetLocalConsole
    mov eax,ds:c_m_counter
    mov es:mw_counter,eax

add_wait_done:
    pop edi
    pop eax
    pop es
    pop ds
    ret
add_wait_for_mouse      ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ResetTouchCalibrate
;
;           DESCRIPTION:    Reset touch calibration
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_touch_cal_name DB 'Reset Touch Calibrate',0

reset_touch_cal	Proc far
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    mov ds:md_div,1
    mov ds:md_xx,1
    mov ds:md_xy,0
    mov ds:md_xo,0
    mov ds:md_yx,0
    mov ds:md_yy,1
    mov ds:md_yo,0
;
    pop ax
    pop ds
    ret
reset_touch_cal	Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetTouchCalibrateDividend
;
;           DESCRIPTION:    Set touch calibration dividend
;
;           PARAMETERS:     EDX		Dividend
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_touch_cal_dividend_name DB 'Set Touch Calibrate Dividend',0

set_touch_cal_dividend	Proc far
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    mov ds:md_div,edx
;
    pop ax
    pop ds
    ret
set_touch_cal_dividend   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetTouchCalibrateX
;
;           DESCRIPTION:    Set touch calibration X factors
;
;           PARAMETERS:     ESI         xx factor
;                           EDI         xy factor
;                           EDX         x offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_touch_cal_x_name DB 'Set Touch Calibrate X',0

set_touch_cal_x	Proc far
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    mov ds:md_xx,esi
    mov ds:md_xy,edi
    mov ds:md_xo,edx
;
    pop ax
    pop ds
    ret
set_touch_cal_x   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetTouchCalibrateY
;
;           DESCRIPTION:    Set touch calibration Y factors
;
;           PARAMETERS:     ESI         yx factor
;                           EDI         yy factor
;                           EDX         y offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_touch_cal_y_name DB 'Set Touch Calibrate Y',0

set_touch_cal_y	Proc far
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    mov ds:md_yx,esi
    mov ds:md_yy,edi
    mov ds:md_yo,edx
;
    pop ax
    pop ds
    ret
set_touch_cal_y   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           mouse_thread
;
;           DESCRIPTION:    Mouse handling thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mouse_thread_name       DB 'Mouse' ,0

mouse_thread    Proc far
    mov ax,init_mouse_nr
    IsValidOsGate
    jc mouse_init_ok
;
    InitMouse

mouse_init_ok:
    mov ax,SEG data
    mov es,ax
    GetThread
    mov es:md_mouse_thread,ax

mouse_thread_loop:
    mov ax,SEG data
    mov es,ax
;
    WaitForSignal
    GetFocusConsole
    jc mouse_thread_loop
;
    mov ds,ebx
    call refresh_mouse
    jmp mouse_thread_loop
    ret
mouse_thread    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InitMouseConsole
;
;           DESCRIPTION:    focus init of mouse
;
;           PARAMETERS:     ES          Console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitMouseConsole

InitMouseConsole     PROC near
    push ds
    push ax
;    
    mov ax,es
    mov ds,ax
    call reset
    mov ds:c_m_counter,0
    mov ds:c_m_avail_obj,0
;
    pop ax
    pop ds    
    ret
InitMouseConsole     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_MOUSE_THREAD
;
;           DESCRIPTION:    focus init of mouse
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

swap_xy_name      DB 'TOUCH.SWAP.XY', 0
swap_x_name       DB 'TOUCH.SWAP.X', 0
swap_y_name       DB 'TOUCH.SWAP.Y', 0
area_x_name       DB 'TOUCH.AREA.X', 0
area_y_name       DB 'TOUCH.AREA.Y', 0
space_x_name      DB 'TOUCH.SPACE.X', 0
space_y_name      DB 'TOUCH.SPACE.Y', 0

init_mouse_thread       PROC far
    push ds
    push es
    pusha
;
    mov ax,SEG data
    mov ds,ax
    mov ds:md_buttons,0
    mov ds:md_dx,0
    mov ds:md_dy,0
    mov ds:md_x,0FFFFh
    mov ds:md_y,0FFFFh
    mov ds:md_mouse_thread,0
    mov ds:md_div,0
    mov ds:md_xx,1
    mov ds:md_xy,0
    mov ds:md_xo,0
    mov ds:md_yx,0
    mov ds:md_yy,1
    mov ds:md_yo,0
;
    mov ax,SEG code
    mov es,ax
    mov di,OFFSET swap_xy_name
    mov ds:md_swap_xy,0
    call GetValue       
    jc itSwapXYOk
;
    mov ds:md_swap_xy,al

itSwapXYOk:
    mov di,OFFSET swap_x_name
    mov ds:md_swap_x,0
    call GetValue       
    jc itSwapXOk
;
    mov ds:md_swap_x,al

itSwapXOk:
    mov di,OFFSET swap_y_name
    mov ds:md_swap_y,0
    call GetValue       
    jc itSwapYOk
;
    mov ds:md_swap_y,al

itSwapYOk:
    mov di,OFFSET area_x_name
    mov ds:md_area_x,0
    call GetValue       
    jc itAreaXOk
;
    mov ds:md_area_x,ax

itAreaXOk:
    mov di,OFFSET area_y_name
    mov ds:md_area_y,0
    call GetValue       
    jc itAreaYOk
;
    mov ds:md_area_y,ax

itAreaYOk:
    mov di,OFFSET space_x_name
    mov ds:md_space_x,0
    call GetValue       
    jc itSpaceXOk
;
    mov ds:md_space_x,ax

itSpaceXOk:
    mov di,OFFSET space_y_name
    mov ds:md_space_y,0
    call GetValue       
    jc itSpaceYOk
;
    mov ds:md_space_y,ax

itSpaceYOk:
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET mouse_thread
    mov di,OFFSET mouse_thread_name
    mov ax,3
    mov cx,stack0_size
    CreateThread

init_mouse_done:
    popa
    pop es
    pop ds
    ret
init_mouse_thread       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT
;
;           DESCRIPTION:    INITIERA driver
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_mouse

init_mouse      PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET init_mouse_thread
    HookInitTasking
;
    mov esi,OFFSET add_wait_for_mouse
    mov edi,OFFSET add_wait_for_mouse_name
    xor dx,dx
    mov ax,add_wait_for_mouse_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_mouse_limit
    mov edi,OFFSET set_mouse_limit_name
    xor cl,cl
    mov ax,set_mouse_limit_nr
    RegisterOsGate
;
    mov esi,OFFSET update_mouse
    mov edi,OFFSET update_mouse_name
    xor cl,cl
    mov ax,update_mouse_nr
    RegisterOsGate
;
    mov esi,OFFSET set_mouse
    mov edi,OFFSET set_mouse_name
    xor cl,cl
    mov ax,set_mouse_nr
    RegisterOsGate
;
    mov esi,OFFSET show_mouse
    mov edi,OFFSET show_mouse_name
    xor dx,dx
    mov ax,show_mouse_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET hide_mouse
    mov edi,OFFSET hide_mouse_name
    xor dx,dx
    mov ax,hide_mouse_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_mouse_position
    mov edi,OFFSET get_mouse_position_name
    xor dx,dx
    mov ax,get_mouse_position_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_mouse_position
    mov edi,OFFSET set_mouse_position_name
    xor dx,dx
    mov ax,set_mouse_position_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_mouse_window
    mov edi,OFFSET set_mouse_window_name
    xor dx,dx
    mov ax,set_mouse_window_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_mouse_mickey
    mov edi,OFFSET set_mouse_mickey_name
    xor dx,dx
    mov ax,set_mouse_mickey_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_left_button
    mov edi,OFFSET get_left_button_name
    xor dx,dx
    mov ax,get_left_button_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_right_button
    mov edi,OFFSET get_right_button_name
    xor dx,dx
    mov ax,get_right_button_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_left_button_press_position
    mov edi,OFFSET get_left_button_press_position_name
    xor dx,dx
    mov ax,get_left_button_press_position_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_right_button_press_position
    mov edi,OFFSET get_right_button_press_position_name
    xor dx,dx
    mov ax,get_right_button_press_position_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_left_button_release_position
    mov edi,OFFSET get_left_button_release_position_name
    xor dx,dx
    mov ax,get_left_button_release_position_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_right_button_release_position
    mov edi,OFFSET get_right_button_release_position_name
    xor dx,dx
    mov ax,get_right_button_release_position_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET reset_touch_cal
    mov edi,OFFSET reset_touch_cal_name
    xor dx,dx
    mov ax,reset_touch_cal_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_touch_cal_dividend
    mov edi,OFFSET set_touch_cal_dividend_name
    xor dx,dx
    mov ax,set_touch_cal_dividend_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_touch_cal_x
    mov edi,OFFSET set_touch_cal_x_name
    xor dx,dx
    mov ax,set_touch_cal_x_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_touch_cal_y
    mov edi,OFFSET set_touch_cal_y_name
    xor dx,dx
    mov ax,set_touch_cal_y_nr
    RegisterBimodalUserGate
    ret
init_mouse      ENDP

code    ENDS

    END
