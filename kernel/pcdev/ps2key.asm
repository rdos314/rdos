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
; PS2KEY.ASM
; PS2 keyboard only support module.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\os\port.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\core.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE key.inc


;
; ctrl_func data types
;
ctrl_F1     EQU 0
ctrl_F2     EQU 1
ctrl_F3     EQU 2
ctrl_F4     EQU 3
ctrl_F5     EQU 4
ctrl_F6     EQU 5
ctrl_F7     EQU 6
ctrl_F8     EQU 7
ctrl_F9     EQU 8
ctrl_F10    EQU 9

;
; status
;
status_key_req      EQU 1
status_key_ack      EQU 4

data    SEGMENT byte public 'DATA'

hw_spinlock         spinlock_typ <>

mode_thread         DW ?
command             DB ?
status              DB ?
focus_req           DB ?

data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           normal_scan
;
;           DESCRIPTION:    Handle normal key  pressed / release
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

normal_scan     PROC near
    clc
    ret
normal_scan  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           shift_press_scan
;
;           DESCRIPTION:    Handle Shift pressed
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

shift_press_scan    PROC near
    push ax
    GetKeyboardState
    or ax,shift_pressed
    SetKeyboardState
    pop ax
    clc
    ret
shift_press_scan    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           shift_rel_scan
;
;           DESCRIPTION:    Handle Shift released
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

shift_rel_scan  PROC near
    push ax
    GetKeyboardState
    and ax,NOT shift_pressed
    SetKeyboardState
    pop ax
    clc
    ret
shift_rel_scan  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           alt_press_scan
;
;           DESCRIPTION:    Handle Alt pressed
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

alt_press_scan  PROC near
    push ax
    GetKeyboardState
    or ax,alt_pressed
    SetKeyboardState
    pop ax
    clc
    ret
alt_press_scan  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           alt_rel_scan
;
;           DESCRIPTION:    Handle Alt released
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

alt_rel_scan    PROC near
    push ax
    GetKeyboardState
    and ax,NOT alt_pressed
    SetKeyboardState
    pop ax
    clc
    ret
alt_rel_scan    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ctrl_press_scan
;
;           DESCRIPTION:    Handle Ctrl pressed
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ctrl_press_scan PROC near
    push ax
    GetKeyboardState
    or ax,ctrl_pressed
    SetKeyboardState
    pop ax
    clc
    ret
ctrl_press_scan ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ctrl_rel_scan
;
;           DESCRIPTION:    Handle Ctrl released
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ctrl_rel_scan   PROC near
    push ax
    GetKeyboardState
    and ax,NOT ctrl_pressed
    SetKeyboardState
    pop ax
    clc
    ret
ctrl_rel_scan   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           caps_press_scan
;
;           DESCRIPTION:    Handle Caps Lock
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

caps_press_scan PROC near
    push ax
    GetKeyboardState
    xor ax,caps_active
    SetKeyboardState
    pop ax
;
    mov bx,ds:mode_thread
    Signal
    clc
    ret
caps_press_scan ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           num_press_scan
;
;           DESCRIPTION:    Handle Num Lock
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

num_press_scan  PROC near
    push ax
    GetKeyboardState
    xor ax,num_active
    SetKeyboardState
    pop ax
;
    mov bx,ds:mode_thread
    Signal
    clc
    ret
num_press_scan  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           print_press_scan
;
;           DESCRIPTION:    Handle print press
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_press_scan    PROC near
    push ax
    GetKeyboardState
    or ax,print_pressed
    SetKeyboardState
    pop ax
    clc
    ret
print_press_scan    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           print_rel_scan
;
;           DESCRIPTION:    Handle print released
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_rel_scan  PROC near
    push ax
    GetKeyboardState
    and ax,NOT print_pressed
    SetKeyboardState
    pop ax
    clc
    ret
print_rel_scan  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           scroll_press_scan
;
;           DESCRIPTION:    Handle scroll press
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

scroll_press_scan       PROC near
    push ax
    GetKeyboardState
    or ax,scroll_pressed
    SetKeyboardState
    pop ax
    clc
    ret
scroll_press_scan       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           scroll_rel_scan
;
;           DESCRIPTION:    Handle scroll release
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

scroll_rel_scan PROC near
    push ax
    GetKeyboardState
    and ax,NOT scroll_pressed
    SetKeyboardState
    pop ax
    clc
    ret
scroll_rel_scan ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           pause_break_press_scan
;
;           DESCRIPTION:    Pause / break press
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pause_break_press_scan  PROC near
    push ax
    GetKeyboardState
    or ax,pause_pressed
    SetKeyboardState
    pop ax
    clc
    ret
pause_break_press_scan  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           pause_break_rel_scan
;
;           DESCRIPTION:    Pause / break rel
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pause_break_rel_scan    PROC near
    push ax
    GetKeyboardState
    and ax,NOT pause_pressed
    SetKeyboardState
    pop ax
    int 4Ah
    clc
    ret
pause_break_rel_scan    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           f_press_scan
;
;           DESCRIPTION:    Function key press scan
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

f_press_scan    PROC near
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
;
    test cx,ctrl_pressed
    jz f_press_norm
;
    mov ds:focus_req,al
    mov bx,ds:mode_thread
    Signal
    stc
    ret

f_press_norm:
    clc
    ret
f_press_scan    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           f_rel_scan
;
;           DESCRIPTION:    Function key release scan
;
;           PARAMETERS:         AL          scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

f_rel_scan      PROC near
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
;
    test cx,ctrl_pressed
    jz f_rel_norm
;
    stc
    ret

f_rel_norm:
    clc
    ret
f_rel_scan    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           handle_scan_code_tab
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_scan_code_tab:
p00     DW      OFFSET normal_scan
p01     DW      OFFSET normal_scan
p02     DW      OFFSET normal_scan
p03     DW      OFFSET normal_scan
p04     DW      OFFSET normal_scan
p05     DW      OFFSET normal_scan
p06     DW      OFFSET normal_scan
p07     DW      OFFSET normal_scan
p08     DW      OFFSET normal_scan
p09     DW      OFFSET normal_scan
p0A     DW      OFFSET normal_scan
p0B     DW      OFFSET normal_scan
p0C     DW      OFFSET normal_scan
p0D     DW      OFFSET normal_scan
p0E     DW      OFFSET normal_scan
p0F     DW      OFFSET normal_scan
p10     DW      OFFSET normal_scan
p11     DW      OFFSET normal_scan
p12     DW      OFFSET normal_scan
p13     DW      OFFSET normal_scan
p14     DW      OFFSET normal_scan
p15     DW      OFFSET normal_scan
p16     DW      OFFSET normal_scan
p17     DW      OFFSET normal_scan
p18     DW      OFFSET normal_scan
p19     DW      OFFSET normal_scan
p1A     DW      OFFSET normal_scan
p1B     DW      OFFSET normal_scan
p1C     DW      OFFSET normal_scan
p1D     DW      OFFSET ctrl_press_scan
p1E     DW      OFFSET normal_scan
p1F     DW      OFFSET normal_scan
p20     DW      OFFSET normal_scan
p21     DW      OFFSET normal_scan
p22     DW      OFFSET normal_scan
p23     DW      OFFSET normal_scan
p24     DW      OFFSET normal_scan
p25     DW      OFFSET normal_scan
p26     DW      OFFSET normal_scan
p27     DW      OFFSET normal_scan
p28     DW      OFFSET normal_scan
p29     DW      OFFSET normal_scan
p2A     DW      OFFSET shift_press_scan
p2B     DW      OFFSET normal_scan
p2C     DW      OFFSET normal_scan
p2D     DW      OFFSET normal_scan
p2E     DW      OFFSET normal_scan
p2F     DW      OFFSET normal_scan
p30     DW      OFFSET normal_scan
p31     DW      OFFSET normal_scan
p32     DW      OFFSET normal_scan
p33     DW      OFFSET normal_scan
p34     DW      OFFSET normal_scan
p35     DW      OFFSET normal_scan
p36     DW      OFFSET shift_press_scan
p37     DW      OFFSET print_press_scan
p38     DW      OFFSET alt_press_scan
p39     DW      OFFSET normal_scan
p3A     DW      OFFSET caps_press_scan
p3B     DW      OFFSET f_press_scan
p3C     DW      OFFSET f_press_scan
p3D     DW      OFFSET f_press_scan
p3E     DW      OFFSET f_press_scan
p3F     DW      OFFSET f_press_scan
p40     DW      OFFSET f_press_scan
p41     DW      OFFSET f_press_scan
p42     DW      OFFSET f_press_scan
p43     DW      OFFSET f_press_scan
p44     DW      OFFSET f_press_scan
p45     DW      OFFSET num_press_scan
p46     DW      OFFSET scroll_press_scan
p47     DW      OFFSET normal_scan
p48     DW      OFFSET normal_scan
p49     DW      OFFSET normal_scan
p4A     DW      OFFSET normal_scan
p4B     DW      OFFSET normal_scan
p4C     DW      OFFSET normal_scan
p4D     DW      OFFSET normal_scan
p4E     DW      OFFSET normal_scan
p4F     DW      OFFSET normal_scan
p50     DW      OFFSET normal_scan
p51     DW      OFFSET normal_scan
p52     DW      OFFSET normal_scan
p53     DW      OFFSET normal_scan
p54     DW      OFFSET normal_scan
p55     DW      OFFSET normal_scan
p56     DW      OFFSET normal_scan
p57     DW      OFFSET normal_scan
p58     DW      OFFSET normal_scan
p59     DW      OFFSET normal_scan
p5A     DW      OFFSET normal_scan
p5B     DW      OFFSET normal_scan
p5C     DW      OFFSET normal_scan
p5D     DW      OFFSET normal_scan
p5E     DW      OFFSET normal_scan
p5F     DW      OFFSET normal_scan
p60     DW      OFFSET normal_scan
p61     DW      OFFSET normal_scan
p62     DW      OFFSET normal_scan
p63     DW      OFFSET normal_scan
p64     DW      OFFSET normal_scan
p65     DW      OFFSET normal_scan
p66     DW      OFFSET normal_scan
p67     DW      OFFSET normal_scan
p68     DW      OFFSET normal_scan
p69     DW      OFFSET normal_scan
p6A     DW      OFFSET normal_scan
p6B     DW      OFFSET normal_scan
p6C     DW      OFFSET normal_scan
p6D     DW      OFFSET normal_scan
p6E     DW      OFFSET normal_scan
p6F     DW      OFFSET normal_scan
p70     DW      OFFSET normal_scan
p71     DW      OFFSET normal_scan
p72     DW      OFFSET normal_scan
p73     DW      OFFSET normal_scan
p74     DW      OFFSET normal_scan
p75     DW      OFFSET normal_scan
p76     DW      OFFSET normal_scan
p77     DW      OFFSET normal_scan
p78     DW      OFFSET normal_scan
p79     DW      OFFSET normal_scan
p7A     DW      OFFSET normal_scan
p7B     DW      OFFSET normal_scan
p7C     DW      OFFSET normal_scan
p7D     DW      OFFSET normal_scan
p7E     DW      OFFSET normal_scan
p7F     DW      OFFSET normal_scan
p80     DW      OFFSET normal_scan
p81     DW      OFFSET normal_scan
p82     DW      OFFSET normal_scan
p83     DW      OFFSET normal_scan
p84     DW      OFFSET normal_scan
p85     DW      OFFSET normal_scan
p86     DW      OFFSET normal_scan
p87     DW      OFFSET normal_scan
p88     DW      OFFSET normal_scan
p89     DW      OFFSET normal_scan
p8A     DW      OFFSET normal_scan
p8B     DW      OFFSET normal_scan
p8C     DW      OFFSET normal_scan
p8D     DW      OFFSET normal_scan
p8E     DW      OFFSET normal_scan
p8F     DW      OFFSET normal_scan
p90     DW      OFFSET normal_scan
p91     DW      OFFSET normal_scan
p92     DW      OFFSET normal_scan
p93     DW      OFFSET normal_scan
p94     DW      OFFSET normal_scan
p95     DW      OFFSET normal_scan
p96     DW      OFFSET normal_scan
p97     DW      OFFSET normal_scan
p98     DW      OFFSET normal_scan
p99     DW      OFFSET normal_scan
p9A     DW      OFFSET normal_scan
p9B     DW      OFFSET normal_scan
p9C     DW      OFFSET normal_scan
p9D     DW      OFFSET ctrl_rel_scan
p9E     DW      OFFSET normal_scan
p9F     DW      OFFSET normal_scan
pA0     DW      OFFSET normal_scan
pA1     DW      OFFSET normal_scan
pA2     DW      OFFSET normal_scan
pA3     DW      OFFSET normal_scan
pA4     DW      OFFSET normal_scan
pA5     DW      OFFSET normal_scan
pA6     DW      OFFSET normal_scan
pA7     DW      OFFSET normal_scan
pA8     DW      OFFSET normal_scan
pA9     DW      OFFSET normal_scan
pAA     DW      OFFSET shift_rel_scan
pAB     DW      OFFSET normal_scan
pAC     DW      OFFSET normal_scan
pAD     DW      OFFSET normal_scan
pAE     DW      OFFSET normal_scan
pAF     DW      OFFSET normal_scan
pB0     DW      OFFSET normal_scan
pB1     DW      OFFSET normal_scan
pB2     DW      OFFSET normal_scan
pB3     DW      OFFSET normal_scan
pB4     DW      OFFSET normal_scan
pB5     DW      OFFSET normal_scan
pB6     DW      OFFSET shift_rel_scan
pB7     DW      OFFSET print_rel_scan
pB8     DW      OFFSET alt_rel_scan
pB9     DW      OFFSET normal_scan
pBA     DW      OFFSET normal_scan
pBB     DW      OFFSET f_rel_scan
pBC     DW      OFFSET f_rel_scan
pBD     DW      OFFSET f_rel_scan
pBE     DW      OFFSET f_rel_scan
pBF     DW      OFFSET f_rel_scan
pC0     DW      OFFSET f_rel_scan
pC1     DW      OFFSET f_rel_scan
pC2     DW      OFFSET f_rel_scan
pC3     DW      OFFSET f_rel_scan
pC4     DW      OFFSET f_rel_scan
pC5     DW      OFFSET f_rel_scan
pC6     DW      OFFSET scroll_rel_scan
pC7     DW      OFFSET normal_scan
pC8     DW      OFFSET normal_scan
pC9     DW      OFFSET normal_scan
pCA     DW      OFFSET normal_scan
pCB     DW      OFFSET normal_scan
pCC     DW      OFFSET normal_scan
pCD     DW      OFFSET normal_scan
pCE     DW      OFFSET normal_scan
pCF     DW      OFFSET normal_scan
pD0     DW      OFFSET normal_scan
pD1     DW      OFFSET normal_scan
pD2     DW      OFFSET normal_scan
pD3     DW      OFFSET normal_scan
pD4     DW      OFFSET normal_scan
pD5     DW      OFFSET normal_scan
pD6     DW      OFFSET normal_scan
pD7     DW      OFFSET normal_scan
pD8     DW      OFFSET normal_scan
pD9     DW      OFFSET normal_scan
pDA     DW      OFFSET normal_scan
pDB     DW      OFFSET normal_scan
pDC     DW      OFFSET normal_scan
pDD     DW      OFFSET normal_scan
pDE     DW      OFFSET normal_scan
pDF     DW      OFFSET normal_scan
pE0     DW      OFFSET normal_scan
pE1     DW      OFFSET normal_scan
pE2     DW      OFFSET normal_scan
pE3     DW      OFFSET normal_scan
pE4     DW      OFFSET normal_scan
pE5     DW      OFFSET normal_scan
pE6     DW      OFFSET normal_scan
pE7     DW      OFFSET normal_scan
pE8     DW      OFFSET normal_scan
pE9     DW      OFFSET normal_scan
pEA     DW      OFFSET normal_scan
pEB     DW      OFFSET normal_scan
pEC     DW      OFFSET normal_scan
pED     DW      OFFSET normal_scan
pEE     DW      OFFSET normal_scan
pEF     DW      OFFSET normal_scan
pF0     DW      OFFSET normal_scan
pF1     DW      OFFSET normal_scan
pF2     DW      OFFSET normal_scan
pF3     DW      OFFSET normal_scan
pF4     DW      OFFSET normal_scan
pF5     DW      OFFSET normal_scan
pF6     DW      OFFSET normal_scan
pF7     DW      OFFSET normal_scan
pF8     DW      OFFSET normal_scan
pF9     DW      OFFSET normal_scan
pFA     DW      OFFSET normal_scan
pFB     DW      OFFSET normal_scan
pFC     DW      OFFSET normal_scan
pFD     DW      OFFSET normal_scan
pFE     DW      OFFSET normal_scan
pFF     DW      OFFSET normal_scan

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SendCommand
;
;           DESCRIPTION:    Send a command to keyboard port
;
;           PARAMETERS:         AL          command
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TimeoutCommand  Proc far
    mov ax,SEG data
    mov ds,ax
    in al,64h
    test al,2
    jnz timeout_command_retry
    mov al,ds:command
    out 60h,al
    jmp timeout_command_done

timeout_command_retry:
    mov ax,cs
    mov es,ax
    GetSystemTime
    add eax,1193*30
    adc edx,0
    mov bx,ds:mode_thread
    mov edi,OFFSET TimeoutCommand
    StartTimer

timeout_command_done:
    retf32
TimeoutCommand  Endp

SendCommand     proc near
    mov ds:command,al
send_check_ready:
    in al,64h
    test al,2
    jz send_command_do
    mov eax,10
    WaitMilliSec
    jmp send_check_ready

send_command_do:
    RequestSpinlock ds:hw_spinlock
    mov al,ds:status
    or al,status_key_req
    and al,NOT status_key_ack
    mov ds:status,al
    ReleaseSpinlock ds:hw_spinlock
;
    mov ax,cs
    mov es,ax
    GetSystemTime
    add eax,1193*30
    adc edx,0
    mov bx,ds:mode_thread
    mov edi,OFFSET TimeoutCommand
    StopTimer
    StartTimer
    mov al,ds:command
    out 60h,al
send_command_wait:
    WaitForSignal
    test ds:status, status_key_ack
    jz send_command_wait
;
    mov bx,ds:mode_thread
    StopTimer
    ret
SendCommand     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           UpdateMode
;
;           DESCRIPTION:    Update mode indicators
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMode      PROC near
    mov al,0EDh
    call SendCommand
;
    GetKeyboardState
    mov dx,ax
    xor al,al
    test dx,num_active
    jz num_off
    or al,2
num_off:
    test dx,caps_active
    jz caps_off
    or al,4
caps_off:
    call SendCommand
    ret
UpdateMode      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           mode_pr
;
;           DESCRIPTION:    Keyboard LED thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mode_name       DB 'Keyboard LEDs',0

mode_pr:
    mov ax,SEG data
    mov ds,ax
;
    GetThread
    mov ds:mode_thread,ax
;    
    mov eax,250
    WaitMilliSec
;
    in al,60h

mode_thread_loop:
    WaitForSignal
    mov al,ds:focus_req
    or al,al
    jz mode_thread_mode
;
    mov ds:focus_req,0
    SetFocus
    jmp mode_thread_loop

mode_thread_mode:
    call UpdateMode
    jmp mode_thread_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           keyb_int
;
;           DESCRIPTION:    Keyboard hardware int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

keyb_int    Proc far
    cld
keyb_int_loop:
    RequestSpinlock ds:hw_spinlock
    in al,64h
    test al,1
    jnz keyb_int_get_cmd
;    
    ReleaseSpinlock ds:hw_spinlock
    jmp keyb_int_done

keyb_int_get_cmd:
    NotifyIrqActivity
    test al,20h
    jz keyb_int_keyboard

keyb_int_mouse:
    in al,60h
    ReleaseSpinlock ds:hw_spinlock
    jmp keyb_int_loop

keyb_int_keyboard:
    NotifyIrqActivity
    in al,60h
    ReleaseSpinlock ds:hw_spinlock
;
    or al,al
    je keyb_int_loop
;
    test ds:status,status_key_req
    jz keyb_int_not_resend
;
    cmp al,0FAh
    jnz keyb_int_not_ack
;
    RequestSpinlock ds:hw_spinlock
    mov al,ds:status
    or al,status_key_ack
    and al,NOT status_key_req
    mov ds:status,al
    ReleaseSpinlock ds:hw_spinlock
;
    mov bx,ds:mode_thread
    Signal
    jmp keyb_int_loop

keyb_int_not_ack:
    cmp al,0FEh
    jnz keyb_int_not_resend
;
    mov al,ds:command
    out 60h,al
    jmp keyb_int_loop

keyb_int_not_resend:
    cmp al,0FFh
    je keyb_int_loop
;
    cmp al,0E0h
    jnz keyb_int_not_numpad
;
    push ax
    GetKeyboardState
    or ax,ext_numpad_active
    and ax, NOT ext_numpad_handled
    SetKeyboardState
    pop ax
    jmp keyb_int_loop       

keyb_int_not_numpad:
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
    test cx,ext_numpad_active
    jz keyb_int_numpad_handled
;
    test cx, ext_numpad_handled
    jz keyb_int_numpad_mark_handled
;
    and cx, NOT ext_numpad_active
    push ax
    mov ax,cx
    SetKeyboardState
    pop ax
    jmp keyb_int_numpad_handled

keyb_int_numpad_mark_handled:
    or cx, ext_numpad_handled
    push ax
    mov ax,cx
    SetKeyboardState
    pop ax

keyb_int_numpad_handled:
    movzx bx,al
    add bx,bx
    call word ptr cs:[bx].handle_scan_code_tab
    jc keyb_int_done
;
    ProcessKeyScan

keyb_int_done:
    retf32
keyb_int    Endp

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
    mov si,OFFSET mode_pr
    mov di,OFFSET mode_name
    mov cx,stack0_size
    mov ax,4
    CreateThread
;
    mov bx,SEG data
    mov ds,bx
    mov al,1
    mov ah,8
    mov bx,cs
    mov es,bx
    mov edi,OFFSET keyb_int
    RequestIrqHandler
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

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET init_keyb_thread
    HookInitTasking
;
    mov ax,SEG data
    mov ds,ax
    xor ax,ax
    mov ds:mode_thread,ax
    mov ds:status,0
    mov ds:focus_req,0
    InitSpinlock ds:hw_spinlock
    ret
init    ENDP

code    ENDS

    END init
