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
; KEYBOARD.ASM
; Keyboard module. Hardware independent
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\os\port.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\wait.inc
INCLUDE ..\apicheck.inc

key_buf_struc   STRUC

kb_code     DW ?
kb_vk_code      DB ?
kb_scan_code    DB ?
kb_state    DW ?

key_buf_struc   ENDS

key_proc_seg    STRUC

key_proc_wait       DW ?
extend_key          DB ?

key_spinlock        spinlock_typ <>
key_section         section_typ <>

key_buffer_head     DW ?
key_buffer_tail     DW ?
key_buffer_start    DW 3 * 256 DUP(?)
key_buffer_end      DW ?

key_emul_thread     DW ?
key_int_seg             DW ?
key_int_offs        DW ?

key_notify_thread       DW ?
key_notify_sel      DW ?
key_notify_offs     DD ?

key_avail_obj       DW ?

key_proc_seg    ENDS

data    SEGMENT byte public 'DATA'

shift_states    DW ?
keyboard_thread DW ?
key_code    DW ?
vk_code     DB ?
scan_code       DB ?

has_focus   DB ?

data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           remove_non_keys
;
;           DESCRIPTION:    Remove non-standard keys from buffer head
;
;       PARAMETERS:     DS      key local sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_non_key Proc near
    push ax
    push bx
;    
    mov bx,ds:key_buffer_head

remove_nk_loop:
    cmp bx,ds:key_buffer_tail
    je remove_nk_done
;    
    mov al,[bx].kb_scan_code
    test al,80h
    jnz remove_nk_do
;
    mov ax,[bx].kb_code
    and ax,NOT 80h
    jnz remove_nk_done

remove_nk_do:
    add bx,SIZE key_buf_struc
    cmp bx,OFFSET key_buffer_end
    jne remove_nk_loop
;
    mov bx,OFFSET key_buffer_start
    jmp remove_nk_loop

remove_nk_done:
    mov ds:key_buffer_head,bx
;
    pop bx
    pop ax    
    ret
remove_non_key Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           keyboard_pr
;
;           DESCRIPTION:    Keyboard handling thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

keyboard_name   DB 'Keyboard',0

keyboard_pr:
    AddThreadInt
    sti
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:keyboard_thread,ax
    
keyboard_thread_loop:
    WaitForSignal
    mov ax,SEG data
    mov es,ax
    mov ax,es:key_code
    cmp al,-1
    je keyboard_thread_loop
;
    cmp ah,-1
    je keyboard_thread_loop
;
    mov bl,es:has_focus
    or bl,bl
    jz keyboard_thread_loop
;    
    mov bx,key_focus_sel
    mov ds,bx
;
    EnterSection ds:key_section
    mov bx,ds:key_buffer_tail
    mov si,bx
    add bx,SIZE key_buf_struc
    cmp bx,OFFSET key_buffer_end
    jne keyboard_thread_no_circ
;       
    mov bx,OFFSET key_buffer_start

keyboard_thread_no_circ:
    mov ax,es:key_code
    xchg ah,al
    mov ds:[si].kb_code,ax
    mov al,es:vk_code
    mov ds:[si].kb_vk_code,al
    mov al,es:scan_code
    mov ds:[si].kb_scan_code,al
    mov ax,es:shift_states
    mov ds:[si].kb_state,ax
;       
    mov ds:key_buffer_tail,bx
    LeaveSection ds:key_section
;
    mov bx,ds:key_avail_obj
    or bx,bx
    jz keyboard_wake
;
    mov es,bx
    SignalWait

keyboard_wake:
    mov si,OFFSET key_proc_wait
    mov ax,[si]
    or ax,ax
    jz keyboard_thread_loop
;
    Wake
    jmp keyboard_thread_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           PutKeyboardCode
;
;           DESCRIPTION:    Put a scan-code + VK key code in buffer
;
;           PARAMETERS:         AX      Key code
;               DL      Virtual key code
;               DH      Scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

put_keyboard_code_name  DB 'Put Keyboard Code',0

put_keyboard_code       PROC far
    push ds
    push ax
    push bx
;
    mov bx,SEG data
    mov ds,bx
;
    mov ds:key_code,ax
    mov ds:vk_code,dl
    mov ds:scan_code,dh
    mov bx,ds:keyboard_thread
    Signal
;
    pop bx
    pop ax
    pop ds
    ret
put_keyboard_code   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           PollKeyboardSerial
;
;           DESCRIPTION:    Fix for DOS
;
;           PARAMETERS:         NC          Char available
;                           CY          Buffer empty
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_keyboard_serial_name       DB 'Poll Keyboard Serial',0

poll_keyboard_serial    PROC far
    push ds
    push ax
    sti
    mov ax,key_local_sel
    mov ds,ax
    mov al,ds:extend_key
    or al,al
    clc
    jnz poll_key_serial_end
    PollKeyboard
poll_key_serial_end:
    pop ax
    pop ds
    ret
poll_keyboard_serial    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReadKeyboardSerial
;
;           DESCRIPTION:    Special fix for DOS
;
;           PARAMETERS:         AL              Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_keyboard_serial_name       DB 'Read Keyboard Serial',0

read_keyboard_serial    PROC far
    push ds
    push bx
    sti
    mov bx,key_local_sel
    mov ds,bx
    mov al,ds:extend_key
    or al,al
    jz key_serial_wait
    mov ds:extend_key,0
    jmp key_serial_end
key_serial_wait:
    ReadKeyboard
    or al,al
    jnz key_serial_end
    mov ds:extend_key,ah
key_serial_end:
    pop bx
    pop ds
    ret
read_keyboard_serial    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           PollKeyboard
;
;           DESCRIPTION:    Poll keyboard
;
;           PARAMETERS:         NC          Char available
;                           CY          Buffer empty
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_keyboard_name      DB 'Poll Keyboard',0

poll_keyboard   PROC far
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push bx
    sti
    mov bx,key_local_sel
    mov ds,bx
;
    EnterSection ds:key_section
    call remove_non_key
;
    mov bx,ds:key_buffer_head
    cmp bx,ds:key_buffer_tail
    je poll_key_empty
    
poll_key_avail:
    LeaveSection ds:key_section
    clc
    pop bx
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    ret
    
poll_key_empty:
    LeaveSection ds:key_section
    stc
    pop bx
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    ret
poll_keyboard   ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForKeyboard
;
;           DESCRIPTION:    Start a wait for keyboard
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_keyboard PROC far
    push ds
    push ax
    push bx
;
    mov ax,key_local_sel
    mov ds,ax
    mov ds:key_avail_obj,es
;
    mov bx,ds:key_buffer_head
    cmp bx,ds:key_buffer_tail
    je start_wait_for_done
;
    mov ds:key_avail_obj,0
    SignalWait

start_wait_for_done:
    pop bx
    pop ax
    pop ds
    ret
start_wait_for_keyboard Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForKeyboard
;
;           DESCRIPTION:    Stop a wait for keyboard
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_keyboard  PROC far
    push ds
    push ax
;
    mov ax,key_local_sel
    mov ds,ax
    mov ds:key_avail_obj,0
;
    pop ax
    pop ds
    ret
stop_wait_for_keyboard Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsKeyboardIdle
;
;           DESCRIPTION:    Check if keyboard is idle
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_keyboard_idle    PROC far
    push ds
    push ax
    push bx
;
    mov ax,key_local_sel
    mov ds,ax
;
    mov bx,ds:key_buffer_head
    cmp bx,ds:key_buffer_tail
    clc
    je check_idle_done
;
    stc

check_idle_done:
    pop bx
    pop ax
    pop ds
    ret
is_keyboard_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearKeyboard
;
;           DESCRIPTION:    Clear keyboard
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_keyboard  PROC far
    ret
clear_keyboard Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForKeyboard
;
;           DESCRIPTION:    Add a wait for keyboard
;
;           PARAMETERS:         BX      Wait handle
;               ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_keyboard_name      DB 'Add Wait For Keyboard',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_keyboard,      SEG code
aw1 DD OFFSET stop_wait_for_keyboard,       SEG code
aw2 DD OFFSET clear_keyboard,               SEG code
aw3 DD OFFSET is_keyboard_idle,             SEG code

add_wait_for_keyboard   PROC far
    push es
    push ax
    push edi
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET add_wait_tab
    xor ax,ax
    AddWait
;
    pop edi
    pop ax
    pop es
    ret
add_wait_for_keyboard   ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReadKeyboard
;
;           DESCRIPTION:    Read a char from keyboard
;
;           RETURNS:        AX              Char read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_keyboard_name      DB 'Read Keyboard',0

read_keyboard   PROC far
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push bx
    sti
    mov bx,key_local_sel    
    mov ds,bx

read_key_wait:
    EnterSection ds:key_section
    call remove_non_key
    mov bx,ds:key_buffer_head
    cmp bx,ds:key_buffer_tail
    jne read_key_get
;
    LeaveSection ds:key_section
    push di
    mov di,OFFSET key_proc_wait
    Sleep
    pop di
    jmp read_key_wait
    
read_key_get:
    mov ax,[bx]
    add bx,SIZE key_buf_struc
    cmp bx,OFFSET key_buffer_end
    jne read_key_no_circ_buff
;
    mov bx,OFFSET key_buffer_start

read_key_no_circ_buff:
    mov ds:key_buffer_head,bx
    LeaveSection ds:key_section
;
    pop bx
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ret
read_keyboard   ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           PeekKeyEvent
;
;           DESCRIPTION:    Peek a key event
;
;           RETURNS:        AX              Char read
;               CX      Key state
;               DL      Virtual key code
;               DH      Scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

peek_key_event_name     DB 'Peek Key Event',0

peek_key_event  PROC far
    ApiSaveEbx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push bx
    sti
    mov bx,key_local_sel
    mov ds,bx
;
    EnterSection ds:key_section
    mov bx,ds:key_buffer_head
    cmp bx,ds:key_buffer_tail
    jne peek_key_event_get
;
    LeaveSection ds:key_section
    stc
    jmp peek_key_event_done
    
peek_key_event_get:
    mov ax,[bx].kb_code
    mov cx,[bx].kb_state
    mov dl,[bx].kb_vk_code
    mov dh,[bx].kb_scan_code
    LeaveSection ds:key_section
    clc

peek_key_event_done:
    pop bx
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEbx
    ret
peek_key_event  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReadKeyEvent
;
;           DESCRIPTION:    Read a key event
;
;           RETURNS:        AX              Char read
;               CX      Key state
;               DL      Virtual key code
;               DH      Scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_key_event_name     DB 'Read Key Event',0

read_key_event  PROC far
    ApiSaveEbx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push bx
    sti
    mov bx,key_local_sel
    mov ds,bx
;
    EnterSection ds:key_section
    mov bx,ds:key_buffer_head
    cmp bx,ds:key_buffer_tail
    jne read_key_event_get
;
    LeaveSection ds:key_section
    stc
    jmp read_key_event_done
    
read_key_event_get:
    mov ax,[bx].kb_code
    mov cx,[bx].kb_state
    mov dl,[bx].kb_vk_code
    mov dh,[bx].kb_scan_code
;
    add bx,SIZE key_buf_struc
    cmp bx,OFFSET key_buffer_end
    jne read_key_event_no_circ
;
    mov bx,OFFSET key_buffer_start

read_key_event_no_circ:
    mov ds:key_buffer_head,bx
    LeaveSection ds:key_section
    clc

read_key_event_done:
    pop bx
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEbx
    ret
read_key_event  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FlushKeyboard
;
;           DESCRIPTION:    Flush keyboard buffer
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_keyboard_name     DB 'Flush Keyboard',0

flush_keyboard  PROC far
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push bx
    mov bx,key_local_sel
    mov ds,bx
    EnterSection ds:key_section
    mov bx,ds:key_buffer_head
    mov ds:key_buffer_tail,bx
    LeaveSection ds:key_section
    pop bx
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    ret
flush_keyboard  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetKeyboardState
;
;           DESCRIPTION:    Get state of keyboard
;
;           RETURNS:        AX          Keyboard state      
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_keyboard_state_name DB 'Get Keyboard State',0

get_keyboard_state      PROC far
    push ds
    push bx
    mov bx,SEG data
    mov ds,bx
    mov ax,ds:shift_states
    pop bx
    pop ds
    ret
get_keyboard_state      ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetKeyboardState
;
;           DESCRIPTION:    Set state of keyboard
;
;           PARAMETERS:         AX          Keyboard state      
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_keyboard_state_name DB 'Set keyboard State',0

set_keyboard_state      PROC far
    push ds
    push bx
    push cx
;       
    mov bx,SEG data
    mov ds,bx
    mov ds:shift_states,ax
;
    pop cx
    pop bx
    pop ds
    ret
set_keyboard_state      ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CHECK_LIST
;
;           DESCRIPTION:    Check if thread is in a keyboard list
;
;           PARAMETERS:         BX      Thread selector
;               ES:EDI      Buffer
;
;       RETURNS:        NC          processed
;               CX:EDX      List
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Key_state DB 'Keyboard',0

check_list      Proc far
    push fs
    push ax
    push si
;    
    mov fs,bx
    mov cx,fs:p_sleep_sel
    mov edx,fs:p_sleep_offset
    cmp ax,key_local_sel
    jne check_not_local
;
    mov si,OFFSET Key_state

check_copy:
    mov al,cs:[si]
    or al,al
    jz check_copy_done
;
    inc si
    stos byte ptr es:[edi]
    jmp check_copy

check_copy_done:
    xor al,al
    stos byte ptr es:[edi]
    clc
    jmp check_done
    
check_not_local:
    stc

check_done:
    pop si
    pop ax
    pop fs
    ret
check_list      Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_local_sel
;
;           DESCRIPTION:    Init local selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


init_local_sel  PROC far
    mov ax,key_local_sel
    mov ds,ax
    InitSection ds:key_section
    InitSpinlock ds:key_spinlock
    mov ax,OFFSET key_buffer_start
    mov ds:key_buffer_head,ax
    mov ds:key_buffer_tail,ax
    mov ds:key_proc_wait,0
    mov ds:key_avail_obj,0
    mov ds:key_emul_thread,0
    mov ds:key_int_seg,0E000h
    mov ds:key_int_offs,9*4
    ret
init_local_sel  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           got_focus
;
;           DESCRIPTION:    Got focus hook
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

got_focus  PROC far
    push ds
    push ax
    mov ax,SEG data
    mov ds,ax
    mov ds:has_focus,1
    pop ax
    pop ds
    ret
got_focus  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_keyb_thread
;
;           DESCRIPTION:    Init keyboard threads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_keyb_thread    PROC far
    push ds
    push es
    pusha
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET keyboard_pr
    mov di,OFFSET keyboard_name
    mov cx,stack0_size
    mov ax,4
    CreateThread
;
    popa
    pop es
    pop ds
    ret
init_keyb_thread    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init
;
;           DESCRIPTION:    Init device-driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_keyboard
    
init_keyboard   PROC near
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_keyb_thread
    HookInitTasking
;
    mov edi,OFFSET init_local_sel
    HookEnableFocus
;
    mov edi,OFFSET got_focus
    HookGotFocus
;
    mov bx,key_local_sel
    mov dx,key_focus_sel
    mov eax,SIZE key_proc_seg
    AllocateFixedFocusMem
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET check_list
    HookState
;
    mov esi,OFFSET add_wait_for_keyboard
    mov edi,OFFSET add_wait_for_keyboard_name
    xor dx,dx
    mov ax,add_wait_for_keyboard_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET read_keyboard
    mov edi,OFFSET read_keyboard_name
    xor dx,dx
    mov ax,read_keyboard_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET poll_keyboard
    mov edi,OFFSET poll_keyboard_name
    xor dx,dx
    mov ax,poll_keyboard_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET flush_keyboard
    mov edi,OFFSET flush_keyboard_name
    xor dx,dx
    mov ax,flush_keyboard_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_keyboard_state
    mov edi,OFFSET get_keyboard_state_name
    xor dx,dx
    mov ax,get_keyboard_state_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET peek_key_event
    mov edi,OFFSET peek_key_event_name
    xor dx,dx
    mov ax,peek_key_event_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET read_key_event
    mov edi,OFFSET read_key_event_name
    xor dx,dx
    mov ax,read_key_event_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET put_keyboard_code
    mov edi,OFFSET put_keyboard_code_name
    xor cl,cl
    mov ax,put_keyboard_code_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET read_keyboard_serial
    mov edi,OFFSET read_keyboard_serial_name
    xor cl,cl
    mov ax,read_keyboard_serial_nr
    RegisterOsGate
;
    mov esi,OFFSET poll_keyboard_serial
    mov edi,OFFSET poll_keyboard_serial_name
    xor cl,cl
    mov ax,poll_keyboard_serial_nr
    RegisterOsGate
;
    mov esi,OFFSET set_keyboard_state
    mov edi,OFFSET set_keyboard_state_name
    xor cl,cl
    mov ax,set_keyboard_state_nr
    RegisterOsGate
;
    mov ax,SEG data
    mov ds,ax
    xor ax,ax
    mov ds:shift_states,ax
    mov ds:keyboard_thread,ax
    mov ds:has_focus,0
    ret
init_keyboard   ENDP

code    ENDS

    END
