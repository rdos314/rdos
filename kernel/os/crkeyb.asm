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
; SMPKEYB.ASM
; SMP keyboard module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\pcdev\key.inc
INCLUDE ..\pcdev\apic.inc

;
; status
;
status_key_req      EQU 1
status_key_ack      EQU 4
status_mode_change  EQU 8

data    SEGMENT byte public 'DATA'

status      DB ?
command     DB ?
shift_states    DW ?
key_code    DW ?
c_vk_code     DB ?
scan_code       DB ?

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn LocalCpuReset:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SaveKeyboardCode
;
;           DESCRIPTION:    Put a scan-code + VK key code in buffer
;
;           PARAMETERS:         AX      Key code
;           DL      Virtual key code
;           DH      Scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveKeyboardCode    PROC near
    push ds
    push ax
    push bx
;
    mov bx,SEG data
    mov ds,bx
;
    mov ds:key_code,ax
    mov ds:c_vk_code,dl
    mov ds:scan_code,dh
;
    pop bx
    pop ax
    pop ds
    ret
SaveKeyboardCode   ENDP

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
    or ds:shift_states,shift_pressed
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
    and ds:shift_states,NOT shift_pressed
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
    or ds:shift_states,alt_pressed
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
    and ds:shift_states,NOT alt_pressed
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
    or ds:shift_states,ctrl_pressed
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
    and ds:shift_states,NOT ctrl_pressed
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
    xor ds:shift_states,caps_active
    or ds:status,status_mode_change
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
    xor ds:shift_states,num_active
    or ds:status,status_mode_change
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
    or ds:shift_states,print_pressed
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
    and ds:shift_states,NOT print_pressed
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
    or ds:shift_states,scroll_pressed
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
    and ds:shift_states,NOT scroll_pressed
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
    or ds:shift_states,pause_pressed
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
    and ds:shift_states,NOT pause_pressed
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
;       NAME:       dummy_scan
;
;       DESCRIPTION:    Handle unsupported keys
;
;       PARAMETERS:     AL      scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
dummy_scan      PROC near
    stc 
    ret
dummy_scan      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:       state_scan
;
;       DESCRIPTION:    Handle state key
;
;       PARAMETERS:     AL      scan code
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
;       NAME:       del_scan
;
;       DESCRIPTION:    Handle DEL key
;
;       PARAMETERS:     AL      scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
del_scan    PROC near
    mov cx,ds:shift_states
    and cx,alt_pressed OR ctrl_pressed
    cmp cx,alt_pressed OR ctrl_pressed
    jne num_scan
;
    call LocalCpuReset
    ret
del_scan    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:       handle_scan
;
;       DESCRIPTION:    Handle a scan
;
;       PARAMETERS:     AL      scan code
;           CX      State
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
;       NAME:       simple_scan
;
;       DESCRIPTION:    Handle normal keys
;
;       PARAMETERS:     AL      scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
simple_scan     PROC near
    mov cx,ds:shift_states
    call handle_scan
    ret
simple_scan     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:       caps_scan
;
;       DESCRIPTION:    Handle case sensitive keys
;
;       PARAMETERS:     AL      scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
caps_scan       PROC near
    mov cx,ds:shift_states
    and cx,107h
    xor cl,ch
    and cx,7
    call handle_scan
    ret
caps_scan       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:       num_scan
;
;       DESCRIPTION:    Handle numeric keys
;
;       PARAMETERS:     AL      scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
num_scan    PROC near
    mov cx,ds:shift_states
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
;       NAME:       f_key_scan
;
;       DESCRIPTION:    Handle function keys
;
;       PARAMETERS:     AL      scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
f_key_scan      PROC near
    mov cx,ds:shift_states
    call handle_scan
    xor ah,ah
    ret
f_key_scan      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:       DecodeScanCode
;
;       DESCRIPTION:    Decode scan code
;
;       PARAMETERS:     AL      scan code
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

scan_tab_sw:
;
;           normal  shift   alt         ctrl    extend  vk      vk-num  type
;
c00     DB      -1,         -1,         -1,         -1,         -1,     0,      0,      NO_KEY
c01     DB      1Bh,    1Bh,    1Bh,    1Bh,    -1,     1Bh,    1Bh,    SIMPLE_KEY
c02     DB      '1',    '!',    -1,         -1,         78h,    '1',    '1',    SIMPLE_KEY
c03     DB      '2',    '"',    '@',    -1,         79h,    '2',    '2',    SIMPLE_KEY
c04     DB      '3',    '#',    'ú',    -1,         7Ah,    '3',    '3',    SIMPLE_KEY
c05     DB      '4',    '$',    '$',    -1,         7Bh,    '4',    '4',    SIMPLE_KEY
c06     DB      '5',    '%',    -1,         -1,         7Ch,    '5',    '5',    SIMPLE_KEY
c07     DB      '6',    '&',    -1,         -1,         7Dh,    '6',    '6',    SIMPLE_KEY
c08     DB      '7',    '/',    '{',    -1,         7Eh,    '7',    '7',    SIMPLE_KEY
c09     DB      '8',    '(',    '[',    -1,         7Fh,    '8',    '8',    SIMPLE_KEY
c0A     DB      '9',    ')',    ']',    -1,         80h,    '9',    '9',    SIMPLE_KEY
c0B     DB      '0',    '=',    '}',    -1,         81h,    '0',    '0',    SIMPLE_KEY
c0C     DB      '+',    '?',    '\',    -1,         -1,     0BBh,   0BBh,   SIMPLE_KEY
c0D     DB      27h,    60h,    -1,         -1,         -1,     0DBh,   0DBh,   SIMPLE_KEY
c0E     DB      8,          8,          8,          8,          -1,     8,          8,      SIMPLE_KEY
c0F     DB      9,      0,          9,      9,      0Fh,    9,          9,      SIMPLE_KEY
c10     DB      'q',    'Q',    0,          11h,    10h,    'Q',    'Q',    CAPS_KEY
c11     DB      'w',    'W',    0,          17h,    11h,    'W',    'W',    CAPS_KEY
c12     DB      'e',    'E',    0,          5,          12h,    'E',    'E',    CAPS_KEY
c13     DB      'r',    'R',    0,          12h,    13h,    'R',    'R',    CAPS_KEY
c14     DB      't',    'T',    0,          14h,    14h,    'T',    'T',    CAPS_KEY
c15     DB      'y',    'Y',    0,          19h,    15h,    'Y',    'Y',    CAPS_KEY
c16     DB      'u',    'U',    0,      15h,    16h,    'U',    'U',    CAPS_KEY
c17     DB      'i',    'I',    0,          9,          17h,    'I',    'I',    CAPS_KEY
c18     DB      'o',    'O',    0,          0Fh,    18h,    'O',    'O',    CAPS_KEY
c19     DB      'p',    'P',    0,          10h,    19h,    'P',    'P',    CAPS_KEY
c1A     DB      'Ü',    'è',    0,          -1,         1Ah,    0DDh,   0DDh,   CAPS_KEY
c1B     DB      '\',    '^',    '~',    -1,         -1,     0BAh,   0BAh,   SIMPLE_KEY
c1C     DB      0Dh,    0Dh,    0Dh,    0Ah,    -1,     0Dh,    0Dh,    SIMPLE_KEY
c1D     DB      0,          0,          0,          0,          0,      11h,    11h,    STATE_KEY
c1E     DB      'a',    'A',    0,          -1,         1Eh,    'A',    'A',    CAPS_KEY
c1F     DB      's',    'S',    0,          13h,    1Fh,    'S',    'S',    CAPS_KEY
c20     DB      'd',    'D',    0,          4,          20h,    'D',    'D',    CAPS_KEY
c21     DB      'f',    'F',    0,          6,          21h,    'F',    'F',    CAPS_KEY
c22     DB      'g',    'G',    0,          7,          22h,    'G',    'G',    CAPS_KEY
c23     DB      'h',    'H',    0,          8,          23h,    'H',    'H',    CAPS_KEY
c24     DB      'j',    'J',    0,      0Ah,    24h,    'J',    'J',    CAPS_KEY
c25     DB      'k',    'K',    0,          0Bh,    25h,    'K',    'K',    CAPS_KEY
c26     DB      'l',    'L',    0,          0Ch,    26h,    'L',    'L',    CAPS_KEY
c27     DB      'î',    'ô',    0,          -1,         27h,    0C0h,   0C0h,   CAPS_KEY
c28     DB      'Ñ',    'é',    0,          -1,         28h,    0DEh,   0DEh,   CAPS_KEY
c29     DB      '¯',    '´',    -1,         -1,         -1,     0DCh,   0DCh,   SIMPLE_KEY
c2A     DB      0,          0,          0,          0,          0,      10h,    10h,    STATE_KEY
c2B     DB      27h,    '*',    -1,         -1,         -1,     0BFh,   0BFh,   SIMPLE_KEY
c2C     DB      'z',    'Z',    0,          1Ah,    2Ch,    'Z',    'Z',    CAPS_KEY
c2D     DB      'x',    'X',    0,          18h,    2Dh,    'X',    'X',    CAPS_KEY
c2E     DB      'c',    'C',    0,          3,          2Eh,    'C',    'C',    CAPS_KEY
c2F     DB      'v',    'V',    0,          16h,    2Fh,    'V',    'V',    CAPS_KEY
c30     DB      'b',    'B',    0,          2,          30h,    'B',    'B',    CAPS_KEY
c31     DB      'n',    'N',    0,          0Eh,    31h,    'N',    'N',    CAPS_KEY
c32     DB      'm',    'M',    0,          0Dh,    32h,    'M',    'M',    CAPS_KEY
c33     DB      ',',    ';',    -1,         -1,         -1,     0BCh,   0BCh,   SIMPLE_KEY
c34     DB      '.',    ':',    -1,         -1,         -1,     0BEh,   0BEh,   SIMPLE_KEY
c35     DB      '-',    '_',    -1,         -1,         -1,     0BDh,   6Fh,    SIMPLE_KEY
c36     DB      0,          0,          0,          0,          0,      10h,    10h,    STATE_KEY
c37     DB      '*',    '*',    -1,         -1,         -1,     2Ch,    6Ah,    SIMPLE_KEY
c38     DB      0,          0,          0,          0,          0,      12h,    12h,    STATE_KEY
c39     DB      ' ',    ' ',    ' ',    ' ',    -1,     20h,    20h,    SIMPLE_KEY
c3A     DB      0,          0,          0,          0,          0,      14h,    14h,    STATE_KEY
c3B     DB      3Bh,    54h,    68h,    5Eh,    0,      70h,    70h,    FUNC_KEY
c3C     DB      3Ch,    55h,    69h,    5Fh,    0,      71h,    71h,    FUNC_KEY
c3D     DB      3Dh,    56h,    6Ah,    60h,    0,      72h,    72h,    FUNC_KEY
c3E     DB      3Eh,    57h,    6Bh,    61h,    0,      73h,    73h,    FUNC_KEY
c3F     DB      3Fh,    58h,    6Ch,    62h,    0,      74h,    74h,    FUNC_KEY
c40     DB      40h,    59h,    6Dh,    63h,    0,      75h,    75h,    FUNC_KEY
c41     DB      41h,    5Ah,    6Eh,    64h,    0,      76h,    76h,    FUNC_KEY
c42     DB      42h,    5Bh,    6Fh,    65h,    0,      77h,    77h,    FUNC_KEY
c43     DB      43h,    5Ch,    70h,    66h,    0,      78h,    78h,    FUNC_KEY
c44     DB      44h,    5Dh,    71h,    67h,    0,      79h,    79h,    FUNC_KEY
c45     DB      0,          0,          0,          0,          0,      90h,    90h,    STATE_KEY
c46     DB      0,          0,          0,          0,          0,      91h,    91h,    STATE_KEY
c47     DB      47h,    '7',    -1,         77h,    -1,     67h,    24h,    NUM_KEY
c48     DB      48h,    '8',    -1,         -1,         -1,     68h,    26h,    NUM_KEY
c49     DB      49h,    '9',    -1,         84h,    -1,     69h,    21h,    NUM_KEY
c4A     DB      '-',    -1,         -1,         -1,         -1,     6Dh,    6Dh,    SIMPLE_KEY
c4B     DB      4Bh,    '4',    -1,         73h,    -1,     64h,    25h,    NUM_KEY
c4C     DB      '5',    '5',    -1,         -1,         -1,     65h,    65h,    SIMPLE_KEY
c4D     DB      4Dh,    '6',    -1,         74h,    -1,     66h,    27h,    NUM_KEY
c4E     DB      '+',    -1,         -1,         -1,         -1,     6Bh,    6Bh,    SIMPLE_KEY
c4F     DB      4Fh,    '1',    -1,         75h,    -1,     61h,    23h,    NUM_KEY
c50     DB      50h,    '2',    -1,         -1,         -1,     62h,    28h,    NUM_KEY
c51     DB      51h,    '3',    -1,         76h,    -1,     63h,    22h,    NUM_KEY
c52     DB      52h,    '0',    -1,         -1,         -1,     60h,    2Dh,    NUM_KEY
c53     DB      53h,    ',',    -1,         -1,         -1,     6Ch,    2Eh,    DEL_KEY
c54     DB      0,          0,          0,          0,          0,      6Eh,    6Eh,    SIMPLE_KEY
c55     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c56     DB      '<',    '>',    '|',    -1,         -1,     0E2h,   0E2h,   SIMPLE_KEY
c57     DB      57h,    5Eh,    8Bh,    89h,    -1,     7Ah,    7Ah,    FUNC_KEY
c58     DB      58h,    5Fh,    8Ch,    8Ah,    -1,     7Bh,    7Bh,    FUNC_KEY
c59     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c5A     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c5B     DB      0,          0,          0,          0,          0,      5Bh,    5Bh,    STATE_KEY
c5C     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c5D     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c5E     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c5F     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c60     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c61     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c62     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c63     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c64     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c65     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c66     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c67     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c68     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c69     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c6A     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c6B     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c6C     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c6D     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c6E     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c6F     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c70     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c71     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c72     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c73     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c74     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c75     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c76     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c77     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c78     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c79     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c7A     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c7B     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c7C     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c7D     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c7E     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY
c7F     DB      -1,         -1,         -1,         -1,         -1,     0,          0,      NO_KEY

DecodeScanCode   Proc near
    push ds
    push es
    pusha
;
    movzx bx,al
    and bl,7Fh
    mov dh,al
    shl bx,3
    add bx,OFFSET scan_tab_sw
;
    xor di,di
    mov cx,ds:shift_states
    test cx,ext_numpad_active
    jz proc_scan_get_vk
;
    inc di
    
proc_scan_get_vk:
    mov dl,byte ptr cs:[bx+di].vk_code
;
    movzx di,byte ptr cs:[bx].key_type
    add di,di
    call word ptr cs:[di].key_type_tab
    jc proc_scan_done
;
    call SaveKeyboardCode

proc_scan_done:
    popa
    pop es
    pop ds
    ret
DecodeScanCode    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       InitKeyboard
;
;       DESCRIPTION:    Init keyboard
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitCrashKeyboard
    
InitCrashKeyboard Proc near
    push ds
;
    mov ax,SEG data
    mov ds,ax
    mov ds:status,0
    mov ds:shift_states,0
    mov ds:key_code,0
    mov ds:c_vk_code,0
    mov ds:scan_code,0
;
    pop ds
    ret
InitCrashKeyboard Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           UpdateKeyboard
;
;           DESCRIPTION:    Update keyboard state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateKeyboard  Proc near
    push ds
    push ax
    push bx
    push cx
    mov ax,SEG data
    mov ds,ax
    
crash_key_loop:
    in al,64h
    test al,1
    jz crash_key_done
;
    in al,60h
    or al,al
    je crash_key_loop
;
    test ds:status,status_key_req
    jz crash_key_not_resend
;
    cmp al,0FAh
    jnz crash_key_not_ack
;
    mov al,ds:status
    or al,status_key_ack
    and al,NOT status_key_req
    mov ds:status,al
    jmp crash_key_loop

crash_key_not_ack:
    cmp al,0FEh
    jnz crash_key_not_resend
;
    mov al,ds:command
    out 60h,al
    jmp crash_key_loop

crash_key_not_resend:
    cmp al,0FFh
    je crash_key_loop
;
    cmp al,0E0h
    jnz crash_key_not_numpad
;
    push ax
    mov ax,ds:shift_states
    or ax,ext_numpad_active
    and ax, NOT ext_numpad_handled
    mov ds:shift_states,ax
    pop ax
    jmp crash_key_loop       

crash_key_not_numpad:
    push ax
    mov ax,ds:shift_states
    mov cx,ax
    pop ax
    test cx,ext_numpad_active
    jz crash_key_numpad_handled
;
    test cx, ext_numpad_handled
    jz crash_key_numpad_mark_handled
;
    and cx, NOT ext_numpad_active
    mov ds:shift_states,cx
    jmp crash_key_numpad_handled

crash_key_numpad_mark_handled:
    or cx, ext_numpad_handled
    mov ds:shift_states,cx

crash_key_numpad_handled:
    movzx bx,al
    add bx,bx
    call word ptr cs:[bx].handle_scan_code_tab
    jc crash_key_done
;
    call DecodeScanCode

crash_key_done:
    pop cx
    pop bx
    pop ax
    pop ds
    ret
UpdateKeyboard  Endp

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

SendCommand     proc near
    mov ds:command,al

send_check_ready:
    in al,64h
    test al,2
    jz send_command_do
;       
    jmp send_check_ready

send_command_do:
    mov al,ds:status
    or al,status_key_req
    and al,NOT status_key_ack
    mov ds:status,al
;
    mov al,ds:command
    out 60h,al

send_command_wait:
    call UpdateKeyboard
;    
    test ds:status, status_key_ack
    jz send_command_wait
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
    push ds
;
    mov ax,SEG data
    mov ds,ax
;    
    test ds:status,status_mode_change
    jz umDone
;    
    and ds:status,NOT status_mode_change
    mov al,0EDh
    call SendCommand
;
    mov dx,ds:shift_states
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

umDone:
    pop ds
    ret
UpdateMode      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetCrashKey
;
;           DESCRIPTION:    Get key
;
;           RETURNS:        NC
;                               AH      Scan code
;                               AL      VK code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetCrashKey
    
GetCrashKey      PROC near
    push ds
;    
    mov ax,SEG data
    mov ds,ax
    call UpdateKeyboard
    call UpdateMode
;
    mov ah,ds:scan_code
    or ah,ah
    stc
    jz get_key_done
;
    mov ds:scan_code,0
    xor al,al
    xchg al,ds:c_vk_code
    clc
        
get_key_done:
    pop ds
    ret
GetCrashKey      ENDP

code    ENDS

    END
