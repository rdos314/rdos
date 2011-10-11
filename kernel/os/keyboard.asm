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

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE port.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
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
extend_key              DB ?

key_section     section_typ <>

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

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

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
;           NAME:           Keyboard software int
;
;           DESCRIPTION:    Emulates int 16
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;       ds          key_local_sel

keyb_io_read    PROC far
keyb_io_wait:
    EnterSection ds:key_section
    call remove_non_key
    mov bx,ds:key_buffer_head
    cmp bx,ds:key_buffer_tail
    jne keyb_io_get_ch
;
    LeaveSection ds:key_section
    push di
    mov di,OFFSET key_proc_wait
    Sleep
    pop di
    jmp keyb_io_wait

keyb_io_get_ch:
    mov ax,[bx]
    add bx,SIZE key_buf_struc
    cmp bx,OFFSET key_buffer_end
    jne kr_no_circ_buff
;
    mov bx,OFFSET key_buffer_start
    
kr_no_circ_buff:
    mov ds:key_buffer_head,bx
    LeaveSection ds:key_section
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    retf32
keyb_io_read    ENDP

keyb_io_poll    PROC far
    EnterSection ds:key_section
    call remove_non_key
    mov bx,ds:key_buffer_head
    cmp bx,ds:key_buffer_tail
    je keyb_p_empty
;
    and word ptr [bp].vm_eflags,NOT 40h
    mov ax,[bx]
    LeaveSection ds:key_section
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    retf32
    
keyb_p_empty:
    LeaveSection ds:key_section
    or word ptr [bp].vm_eflags,40h
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    retf32
keyb_io_poll    ENDP

keyb_io_state   PROC far
    xor ax,ax
    mov ds,[bp].pm_ds
    retf32
keyb_io_state   ENDP

keyb_error:
    int 3
    mov ds,[bp].pm_ds
    ReflectPmToVm

keyb_write      PROC far
    mov al,1
    mov ds,[bp].pm_ds
    retf32
keyb_write      ENDP

keyb_io_tab:
k00         DW OFFSET keyb_io_read
k01         DW OFFSET keyb_io_poll
k02         DW OFFSET keyb_io_state
k03         DW OFFSET keyb_error
k04         DW OFFSET keyb_error
k05         DW OFFSET keyb_write
k06         DW OFFSET keyb_error
k07         DW OFFSET keyb_error
k08         DW OFFSET keyb_error
k09         DW OFFSET keyb_error
k0A         DW OFFSET keyb_error
k0B         DW OFFSET keyb_error
k0C         DW OFFSET keyb_error
k0D         DW OFFSET keyb_error
k0E         DW OFFSET keyb_error
k0F         DW OFFSET keyb_error
k10         DW OFFSET keyb_io_read
k11         DW OFFSET keyb_io_poll
k12         DW OFFSET keyb_io_state
k13         DW OFFSET keyb_error

int16:
    SimSti
    mov bx,key_local_sel
    mov ds,bx
    mov bl,ah
    xor bh,bh
    add bx,bx
    cmp bx,26h
    jc key_call_do
    mov bx,26h
key_call_do:
    push word ptr cs:[bx].keyb_io_tab
    mov bx,[bp].vm_ebx
    retn


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
    retf32
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
    retf32
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
    retf32
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
    retf32
    
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
    retf32
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
    retf32
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
    retf32
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
    retf32
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
    retf32
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
    retf32
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
    retf32
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
    retf32
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
    retf32
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
    retf32
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
    retf32
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
    retf32
set_keyboard_state      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           KEYBOARD EMULATOR FOR BAD DOS APPS
;
;           DESCRIPTION:    EMULATES KEYBOARD TO ILL BEHAVED DOS APPS
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

keyboard_emul_name      DB 'Keyboard Emulator',0

keyboard_emul_pr:
    mov ax,key_local_sel
    mov ds,ax
    GetThread
    mov ds:key_emul_thread,ax
    mov eax,110h
    AllocateVMLinear
    add edx,10h
    shr edx,4
; gs
    push 0
    push 0F000h
; fs
    push 0
    push 0F000h
; ds
    push 0
    push 0F000h
; es
    push 0
    push 0F000h
; ss
    push edx
; esp
    push 0
    push 0FAh
; eflags
    push 2
    push 200h
; cs
    push 0
    push 0
; eip
    push 0
    push 0
;
    sub sp,4
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    sub sp,6
key_emul_loop:
    sti
    mov ax,key_local_sel
    mov ds,ax
    GetThread
    cmp ds:key_int_seg,0E000h
    jnz key_wait_loop
    mov ds:key_emul_thread,0
    TerminateThread
key_wait_loop:
    WaitForSignal
;
    mov ax,ds:key_int_seg
    cmp ax,0E000h
    jnz key_emul_start
;
    mov bx,key_focus_sel
    mov ds,bx
;
    EnterSection ds:key_section
    call remove_non_key
    mov bx,ds:key_buffer_tail
    mov si,bx
    add bx,SIZE key_buf_struc
    cmp bx,OFFSET key_buffer_end
    jne key_emul_no_circ
;       
    mov bx,OFFSET key_buffer_start

key_emul_no_circ:
    mov [si],ax
    mov ds:key_buffer_tail,bx
    LeaveSection ds:key_section
;
    mov si,OFFSET key_proc_wait
    mov ax,[si]
    or ax,ax
    jz key_emul_loop
;
    LeaveSection ds:key_section
    Wake
    jmp key_emul_loop

key_emul_start:
    int 3
    mov [bp].vm_cs,ax
    mov ax,ds:key_int_offs
    mov [bp].vm_eip,ax
;
    mov ax,flat_sel
    mov ds,ax
    movzx edx,word ptr [bp].vm_ss
    shl edx,4
    mov word ptr [edx+0FAh],8*4
    mov word ptr [edx+0FCh],0E000h
    mov word ptr [edx+0FEh],200h
    mov word ptr [bp].vm_esp,0FAh
    add sp,6
    pop ds
    pop ebx
    pop eax
    pop bp
    add sp,4
    iretd
;
    jmp key_emul_loop

check_key_state PROC near
    cli
    cmp ds:key_int_seg,0E000h
    je check_key_done
    cmp ds:key_emul_thread,0
    jne check_key_done
    sti
    dec ds:key_emul_thread
    push ds
    push es
    pusha
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET keyboard_emul_pr
    mov di,OFFSET keyboard_emul_name
    mov cx,stack0_size
    mov ax,3
    CreateThread
    popa
    pop es
    pop ds
check_key_done:
    sti
    ret
check_key_state ENDP

get_vm_key      PROC far
    mov bx,key_local_sel
    mov ds,bx
    mov bx,ds:key_int_offs
    mov dx,ds:key_int_seg
    retf32
get_vm_key      ENDP

set_vm_key      PROC far
    push ax
    mov ax,key_local_sel
    mov ds,ax
    pop ax
    mov ds:key_int_offs,bx
    mov ds:key_int_seg,dx
    call check_key_state
    retf32
set_vm_key      ENDP

    
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
    retf32
check_list      Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           get_status1
;
;           DESCRIPTION:    Get keyboard status 1
;
;           RETURNS:        AL      status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_status1     Proc far
    push ds
    push bx
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:shift_states
    xor al,al
    test bx,shift_pressed
    jz get1_not_shift
;
    or al,1

get1_not_shift:
    test bx,ctrl_pressed
    jz get1_not_ctrl
;
    or al,4

get1_not_ctrl:
    test bx,alt_pressed
    jz get1_not_alt
;
    or al,8

get1_not_alt:
    test bx,num_active
    jz get1_not_num
;
    or al,20h       

get1_not_num:
    test bx,caps_active
    jz get1_not_caps
;
    or al,40h

get1_not_caps:  
    pop bx
    pop ds
    ret
get_status1     Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           get_status2
;
;           DESCRIPTION:    Get keyboard status 2
;
;           RETURNS:        AL      status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_status2     Proc far
    push ds
    push bx
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:shift_states
    xor al,al
;
    test bx,print_pressed
    jz get2_not_print
;
    or al,4

get2_not_print:
    test bx,scroll_pressed
    jz get2_not_scroll
;
    or al,10h

get2_not_scroll:
    pop bx
    pop ds
    ret
get_status2     Endp

    
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
    mov ax,OFFSET key_buffer_start
    mov ds:key_buffer_head,ax
    mov ds:key_buffer_tail,ax
    mov ds:key_proc_wait,0
    mov ds:key_avail_obj,0
    mov ds:key_emul_thread,0
    mov ds:key_int_seg,0E000h
    mov ds:key_int_offs,9*4
    retf32
init_local_sel  ENDP

    
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
    retf32
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
    mov edi,OFFSET get_vm_key
    mov al,9
    HookGetVMInt
;
    mov edi,OFFSET set_vm_key
    mov al,9
    HookSetVMInt
;
    mov di,OFFSET get_status1
    mov bx,17h
    HookGetBiosData
;
    mov di,OFFSET get_status2
    mov bx,18h
    HookGetBiosData
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
;
    mov ax,cs
    mov ds,ax
    mov al,16h
    mov edi,OFFSET int16
    HookVMInt
;
    mov al,16h
    mov edi,OFFSET int16
    HookProt16Int
    ret
init_keyboard   ENDP

code    ENDS

    END
