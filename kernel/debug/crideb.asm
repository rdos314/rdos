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
; intdeb.asm
; Internal crash debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\core.inc
INCLUDE kdebug.inc
INCLUDE emseg.inc

    .386p

flat_sel = 20h

;
; status
;
status_key_req      EQU 1
status_key_ack      EQU 4
status_mode_change  EQU 8

;
; shift codes
;

ext_numpad_handled      EQU 800h
ext_numpad_active       EQU 400h
num_active                      EQU 200h
caps_active                     EQU 100h
print_pressed           EQU 20h
scroll_pressed          EQU 10h
pause_pressed           EQU 8
ctrl_pressed            EQU 4
alt_pressed                     EQU 2
shift_pressed           EQU 1

NO_KEY      = 0
SIMPLE_KEY  = 1
CAPS_KEY    = 2
STATE_KEY   = 3
NUM_KEY     = 4
DEL_KEY     = 5
FUNC_KEY    = 6
ESC_KEY     = 7


; offset in scan-code table
;
normal_code             EQU 0
shift_code              EQU 1
alt_code                EQU 2
ctrl_code               EQU 3
ext_code                EQU 4
vk_code         EQU 5
vk_num_code     EQU 6
key_type                EQU 7

exec_s  STRUC

exec_row         DW ?
exec_col         DW ?
exec_size        DW ?
exec_reg         DD ?
exec_inc_proc    DD ?
exec_dec_proc    DD ?
exec_set_proc    DD ?

exec_s  ENDS

code    SEGMENT byte public use32 'CODE'

    assume cs:code

    extrn font8x19:near
    extrn LocalCpuReset:near
    extrn IntDisAsmCode:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetSelectorBaseSizeType
;
;           DESCRIPTION:    
;
;           PARAMETERS:     BX          Selector
;
;           RETURNS:        NC
;                               EDX     Base
;                               ECX     Size
;                               AL      Type (+5)
;                               AH      Big (+6)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSelectorBaseSizeType   PROC near
    push ds
    push ebx
;
    movzx ebx,bx
    and bx,NOT 3
    or bx,bx
    jz get_info_fail
;
    test bx,4
    jnz get_info_fail
;
    cmp bx,800h
    jae get_info_fail
;
    mov ax,mon_gdt_sel
    mov ds,ax
    mov eax,ds:[bx]
    mov edx,ds:[bx+4]
;
    test dh,80h
    jz get_info_fail
;
    mov ecx,edx
    and ecx,0F0000h
    mov cx,ax
    test edx,800000h
    jz get_info_small
;
    shl ecx,12
    or cx,0FFFh

get_info_small:
    mov ebx,edx
    shr ebx,8
;    
    shr eax,16
    and eax,0FFFFh
;
    rol edx,8
    xchg dl,dh
    shl edx,16
    or edx,eax
    mov ax,bx
;
    cmp ecx,200000h
    jb get_info_limit_ok
;
    mov ecx,1FFFFFh

get_info_limit_ok:
    clc
    jmp get_info_done

get_info_fail:
    stc

get_info_done:
    pop ebx
    pop ds
    ret
GetSelectorBaseSizeType   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DX:EBX      Address
;
;           RETURNS:        NC
;                               AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadByte   PROC near
    push ds
    push ebx
    push ecx
    push edx
;    
    push ebx
    mov bx,dx
    call GetSelectorBaseSizeType
    pop ebx
    jc rbDone
;
    inc ecx
    cmp ecx,ebx
    jc rbDone
;
    add ebx,edx 
    mov ax,mon_flat_sel
    mov ds,ax
    mov al,ds:[ebx]
    clc

rbDone:    
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
ReadByte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DX:EBX      Address
;
;           RETURNS:        NC
;                               AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadWord   PROC near
    push ds
    push ebx
    push ecx
    push edx
;    
    push ebx
    mov bx,dx
    call GetSelectorBaseSizeType
    pop ebx
    jc rwDone
;
    add ecx,2
    cmp ecx,ebx
    jc rwDone
;
    add ebx,edx 
    mov ax,mon_flat_sel
    mov ds,ax
    mov ax,ds:[ebx]
    clc

rwDone:    
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
ReadWord   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DX:EBX      Address
;
;           RETURNS:        NC
;                               EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadDword   PROC near
    push ds
    push ebx
    push ecx
    push edx
;    
    push ebx
    mov bx,dx
    call GetSelectorBaseSizeType
    pop ebx
    jc rdDone
;
    add ecx,4
    cmp ecx,ebx
    jc rdDone
;
    add ebx,edx 
    mov ax,mon_flat_sel
    mov ds,ax
    mov eax,ds:[ebx]
    clc

rdDone:    
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
ReadDword   Endp

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
    push bx
;
    mov bx,mon_deb_sel
    mov ds,bx
    mov ds:int_key_code,ax
    mov ds:int_c_vk_code,dl
    mov ds:int_scan_code,dh
;
    pop bx
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
    or ds:mon_shift_states,shift_pressed
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
    and ds:mon_shift_states,NOT shift_pressed
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
    or ds:mon_shift_states,alt_pressed
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
    and ds:mon_shift_states,NOT alt_pressed
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
    or ds:mon_shift_states,ctrl_pressed
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
    and ds:mon_shift_states,NOT ctrl_pressed
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
    xor ds:mon_shift_states,caps_active
    or ds:mon_key_status,status_mode_change
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
    xor ds:mon_shift_states,num_active
    or ds:mon_key_status,status_mode_change
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
    or ds:mon_shift_states,print_pressed
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
    and ds:mon_shift_states,NOT print_pressed
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
    or ds:mon_shift_states,scroll_pressed
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
    and ds:mon_shift_states,NOT scroll_pressed
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
    or ds:mon_shift_states,pause_pressed
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
    and ds:mon_shift_states,NOT pause_pressed
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
p00     DD     OFFSET normal_scan
p01     DD      OFFSET normal_scan
p02     DD      OFFSET normal_scan
p03     DD      OFFSET normal_scan
p04     DD      OFFSET normal_scan
p05     DD      OFFSET normal_scan
p06     DD      OFFSET normal_scan
p07     DD      OFFSET normal_scan
p08     DD      OFFSET normal_scan
p09     DD      OFFSET normal_scan
p0A     DD      OFFSET normal_scan
p0B     DD      OFFSET normal_scan
p0C     DD      OFFSET normal_scan
p0D     DD      OFFSET normal_scan
p0E     DD      OFFSET normal_scan
p0F     DD      OFFSET normal_scan
p10     DD      OFFSET normal_scan
p11     DD      OFFSET normal_scan
p12     DD      OFFSET normal_scan
p13     DD      OFFSET normal_scan
p14     DD      OFFSET normal_scan
p15     DD      OFFSET normal_scan
p16     DD      OFFSET normal_scan
p17     DD      OFFSET normal_scan
p18     DD      OFFSET normal_scan
p19     DD      OFFSET normal_scan
p1A     DD      OFFSET normal_scan
p1B     DD      OFFSET normal_scan
p1C     DD      OFFSET normal_scan
p1D     DD      OFFSET ctrl_press_scan
p1E     DD      OFFSET normal_scan
p1F     DD      OFFSET normal_scan
p20     DD      OFFSET normal_scan
p21     DD      OFFSET normal_scan
p22     DD      OFFSET normal_scan
p23     DD      OFFSET normal_scan
p24     DD      OFFSET normal_scan
p25     DD      OFFSET normal_scan
p26     DD      OFFSET normal_scan
p27     DD      OFFSET normal_scan
p28     DD      OFFSET normal_scan
p29     DD      OFFSET normal_scan
p2A     DD      OFFSET shift_press_scan
p2B     DD      OFFSET normal_scan
p2C     DD      OFFSET normal_scan
p2D     DD      OFFSET normal_scan
p2E     DD      OFFSET normal_scan
p2F     DD      OFFSET normal_scan
p30     DD      OFFSET normal_scan
p31     DD      OFFSET normal_scan
p32     DD      OFFSET normal_scan
p33     DD      OFFSET normal_scan
p34     DD      OFFSET normal_scan
p35     DD      OFFSET normal_scan
p36     DD      OFFSET shift_press_scan
p37     DD      OFFSET print_press_scan
p38     DD      OFFSET alt_press_scan
p39     DD      OFFSET normal_scan
p3A     DD      OFFSET caps_press_scan
p3B     DD      OFFSET f_press_scan
p3C     DD      OFFSET f_press_scan
p3D     DD      OFFSET f_press_scan
p3E     DD      OFFSET f_press_scan
p3F     DD      OFFSET f_press_scan
p40     DD      OFFSET f_press_scan
p41     DD      OFFSET f_press_scan
p42     DD      OFFSET f_press_scan
p43     DD      OFFSET f_press_scan
p44     DD      OFFSET f_press_scan
p45     DD      OFFSET num_press_scan
p46     DD      OFFSET scroll_press_scan
p47     DD      OFFSET normal_scan
p48     DD      OFFSET normal_scan
p49     DD      OFFSET normal_scan
p4A     DD      OFFSET normal_scan
p4B     DD      OFFSET normal_scan
p4C     DD      OFFSET normal_scan
p4D     DD      OFFSET normal_scan
p4E     DD      OFFSET normal_scan
p4F     DD      OFFSET normal_scan
p50     DD      OFFSET normal_scan
p51     DD      OFFSET normal_scan
p52     DD      OFFSET normal_scan
p53     DD      OFFSET normal_scan
p54     DD      OFFSET normal_scan
p55     DD      OFFSET normal_scan
p56     DD      OFFSET normal_scan
p57     DD      OFFSET normal_scan
p58     DD      OFFSET normal_scan
p59     DD      OFFSET normal_scan
p5A     DD      OFFSET normal_scan
p5B     DD      OFFSET normal_scan
p5C     DD      OFFSET normal_scan
p5D     DD      OFFSET normal_scan
p5E     DD      OFFSET normal_scan
p5F     DD      OFFSET normal_scan
p60     DD      OFFSET normal_scan
p61     DD      OFFSET normal_scan
p62     DD      OFFSET normal_scan
p63     DD      OFFSET normal_scan
p64     DD      OFFSET normal_scan
p65     DD      OFFSET normal_scan
p66     DD      OFFSET normal_scan
p67     DD      OFFSET normal_scan
p68     DD      OFFSET normal_scan
p69     DD      OFFSET normal_scan
p6A     DD      OFFSET normal_scan
p6B     DD      OFFSET normal_scan
p6C     DD      OFFSET normal_scan
p6D     DD      OFFSET normal_scan
p6E     DD      OFFSET normal_scan
p6F     DD      OFFSET normal_scan
p70     DD      OFFSET normal_scan
p71     DD      OFFSET normal_scan
p72     DD      OFFSET normal_scan
p73     DD      OFFSET normal_scan
p74     DD      OFFSET normal_scan
p75     DD      OFFSET normal_scan
p76     DD      OFFSET normal_scan
p77     DD      OFFSET normal_scan
p78     DD      OFFSET normal_scan
p79     DD      OFFSET normal_scan
p7A     DD      OFFSET normal_scan
p7B     DD      OFFSET normal_scan
p7C     DD      OFFSET normal_scan
p7D     DD      OFFSET normal_scan
p7E     DD      OFFSET normal_scan
p7F     DD      OFFSET normal_scan
p80     DD      OFFSET normal_scan
p81     DD      OFFSET normal_scan
p82     DD      OFFSET normal_scan
p83     DD      OFFSET normal_scan
p84     DD      OFFSET normal_scan
p85     DD      OFFSET normal_scan
p86     DD      OFFSET normal_scan
p87     DD      OFFSET normal_scan
p88     DD      OFFSET normal_scan
p89     DD      OFFSET normal_scan
p8A     DD      OFFSET normal_scan
p8B     DD      OFFSET normal_scan
p8C     DD      OFFSET normal_scan
p8D     DD      OFFSET normal_scan
p8E     DD      OFFSET normal_scan
p8F     DD      OFFSET normal_scan
p90     DD      OFFSET normal_scan
p91     DD      OFFSET normal_scan
p92     DD      OFFSET normal_scan
p93     DD      OFFSET normal_scan
p94     DD      OFFSET normal_scan
p95     DD      OFFSET normal_scan
p96     DD      OFFSET normal_scan
p97     DD      OFFSET normal_scan
p98     DD      OFFSET normal_scan
p99     DD      OFFSET normal_scan
p9A     DD      OFFSET normal_scan
p9B     DD      OFFSET normal_scan
p9C     DD      OFFSET normal_scan
p9D     DD      OFFSET ctrl_rel_scan
p9E     DD      OFFSET normal_scan
p9F     DD      OFFSET normal_scan
pA0     DD      OFFSET normal_scan
pA1     DD      OFFSET normal_scan
pA2     DD      OFFSET normal_scan
pA3     DD      OFFSET normal_scan
pA4     DD      OFFSET normal_scan
pA5     DD      OFFSET normal_scan
pA6     DD      OFFSET normal_scan
pA7     DD      OFFSET normal_scan
pA8     DD      OFFSET normal_scan
pA9     DD      OFFSET normal_scan
pAA     DD      OFFSET shift_rel_scan
pAB     DD      OFFSET normal_scan
pAC     DD      OFFSET normal_scan
pAD     DD      OFFSET normal_scan
pAE     DD      OFFSET normal_scan
pAF     DD      OFFSET normal_scan
pB0     DD      OFFSET normal_scan
pB1     DD      OFFSET normal_scan
pB2     DD      OFFSET normal_scan
pB3     DD      OFFSET normal_scan
pB4     DD      OFFSET normal_scan
pB5     DD      OFFSET normal_scan
pB6     DD      OFFSET shift_rel_scan
pB7     DD      OFFSET print_rel_scan
pB8     DD      OFFSET alt_rel_scan
pB9     DD      OFFSET normal_scan
pBA     DD      OFFSET normal_scan
pBB     DD      OFFSET f_rel_scan
pBC     DD      OFFSET f_rel_scan
pBD     DD      OFFSET f_rel_scan
pBE     DD      OFFSET f_rel_scan
pBF     DD      OFFSET f_rel_scan
pC0     DD      OFFSET f_rel_scan
pC1     DD      OFFSET f_rel_scan
pC2     DD      OFFSET f_rel_scan
pC3     DD      OFFSET f_rel_scan
pC4     DD      OFFSET f_rel_scan
pC5     DD      OFFSET f_rel_scan
pC6     DD      OFFSET scroll_rel_scan
pC7     DD      OFFSET normal_scan
pC8     DD      OFFSET normal_scan
pC9     DD      OFFSET normal_scan
pCA     DD      OFFSET normal_scan
pCB     DD      OFFSET normal_scan
pCC     DD      OFFSET normal_scan
pCD     DD      OFFSET normal_scan
pCE     DD      OFFSET normal_scan
pCF     DD      OFFSET normal_scan
pD0     DD      OFFSET normal_scan
pD1     DD      OFFSET normal_scan
pD2     DD      OFFSET normal_scan
pD3     DD      OFFSET normal_scan
pD4     DD      OFFSET normal_scan
pD5     DD      OFFSET normal_scan
pD6     DD      OFFSET normal_scan
pD7     DD      OFFSET normal_scan
pD8     DD      OFFSET normal_scan
pD9     DD      OFFSET normal_scan
pDA     DD      OFFSET normal_scan
pDB     DD      OFFSET normal_scan
pDC     DD      OFFSET normal_scan
pDD     DD      OFFSET normal_scan
pDE     DD      OFFSET normal_scan
pDF     DD      OFFSET normal_scan
pE0     DD      OFFSET normal_scan
pE1     DD      OFFSET normal_scan
pE2     DD      OFFSET normal_scan
pE3     DD      OFFSET normal_scan
pE4     DD      OFFSET normal_scan
pE5     DD      OFFSET normal_scan
pE6     DD      OFFSET normal_scan
pE7     DD      OFFSET normal_scan
pE8     DD      OFFSET normal_scan
pE9     DD      OFFSET normal_scan
pEA     DD      OFFSET normal_scan
pEB     DD      OFFSET normal_scan
pEC     DD      OFFSET normal_scan
pED     DD      OFFSET normal_scan
pEE     DD      OFFSET normal_scan
pEF     DD      OFFSET normal_scan
pF0     DD      OFFSET normal_scan
pF1     DD      OFFSET normal_scan
pF2     DD      OFFSET normal_scan
pF3     DD      OFFSET normal_scan
pF4     DD      OFFSET normal_scan
pF5     DD      OFFSET normal_scan
pF6     DD      OFFSET normal_scan
pF7     DD      OFFSET normal_scan
pF8     DD      OFFSET normal_scan
pF9     DD      OFFSET normal_scan
pFA     DD      OFFSET normal_scan
pFB     DD      OFFSET normal_scan
pFC     DD      OFFSET normal_scan
pFD     DD      OFFSET normal_scan
pFE     DD      OFFSET normal_scan
pFF     DD      OFFSET normal_scan
    
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
    mov cx,ds:mon_shift_states
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
    mov ah,cs:[ebx].ctrl_code
    cmp ah,-1
    jne handle_check

handle_not_ctrl:
    test cx,alt_pressed
    jz handle_not_alt
;
    mov ah,cs:[ebx].alt_code
    cmp ah,-1
    jne handle_check

handle_not_alt:
    test cx,shift_pressed
    jz handle_not_shift
;
    mov ah,cs:[ebx].shift_code
    cmp ah,-1
    jne handle_check

handle_not_shift:
    mov ah,cs:[ebx].normal_code

handle_check:
    or ah,ah
    jne handle_no_ext
;
    mov cl,al
    movzx ax,byte ptr cs:[ebx].ext_code
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
    mov cx,ds:mon_shift_states
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
    mov cx,ds:mon_shift_states
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
    mov cx,ds:mon_shift_states
    and cx,205h
    shr ch,1
    xor cl,ch
    movzx ecx,cl
    add ebx,ecx
    cmp cx,1
    jne num_sc_no_num
;
    mov ah,cs:[ebx]
    jmp num_sc_end
    
num_sc_no_num:
    mov cl,al
    movzx ax,byte ptr cs:[ebx]
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
    mov cx,ds:mon_shift_states
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
kt00    DD OFFSET dummy_scan
kt01    DD OFFSET simple_scan
kt02    DD OFFSET caps_scan
kt03    DD OFFSET state_scan
kt04    DD OFFSET num_scan
kt05    DD OFFSET del_scan
kt06    DD OFFSET f_key_scan

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
    movzx ebx,al
    and bl,7Fh
    mov dh,al
    shl ebx,3
    add ebx,OFFSET scan_tab_sw
;
    xor edi,edi
    mov cx,ds:mon_shift_states
    test cx,ext_numpad_active
    jz proc_scan_get_vk
;
    inc edi
    
proc_scan_get_vk:
    mov dl,byte ptr cs:[ebx+edi].vk_code
;
    movzx edi,byte ptr cs:[ebx].key_type
    shl edi,2
    call dword ptr cs:[edi].key_type_tab
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
;           NAME:           InitKey
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitKey Proc near
    push ds
    push ax
;
    mov ax,mon_deb_sel
    mov ds,ax
;
    mov ds:int_key_code,0
    mov ds:int_c_vk_code,0
    mov ds:int_scan_code,0
;
    pop ax
    pop ds
    ret
InitKey Endp

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
;
    mov ax,mon_data_sel
    mov ds,ax
    
crash_key_loop:
    in al,64h
    cmp al,0FFh
    je crash_key_done
;
    test al,1
    jz crash_key_done
;
    in al,60h
    or al,al
    je crash_key_loop
;
    test ds:mon_key_status,status_key_req
    jz crash_key_not_resend
;
    cmp al,0FAh
    jnz crash_key_not_ack
;
    mov al,ds:mon_key_status
    or al,status_key_ack
    and al,NOT status_key_req
    mov ds:mon_key_status,al
    jmp crash_key_loop

crash_key_not_ack:
    cmp al,0FEh
    jnz crash_key_not_resend
;
    mov al,ds:mon_key_command
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
    mov ax,ds:mon_shift_states
    or ax,ext_numpad_active
    and ax, NOT ext_numpad_handled
    mov ds:mon_shift_states,ax
    pop ax
    jmp crash_key_loop       

crash_key_not_numpad:
    push ax
    mov ax,ds:mon_shift_states
    mov cx,ax
    pop ax
    test cx,ext_numpad_active
    jz crash_key_numpad_handled
;
    test cx, ext_numpad_handled
    jz crash_key_numpad_mark_handled
;
    and cx, NOT ext_numpad_active
    mov ds:mon_shift_states,cx
    jmp crash_key_numpad_handled

crash_key_numpad_mark_handled:
    or cx, ext_numpad_handled
    mov ds:mon_shift_states,cx

crash_key_numpad_handled:
    movzx ebx,al
    shl ebx,2
    call dword ptr cs:[ebx].handle_scan_code_tab
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
    mov ds:mon_key_command,al

send_check_ready:
    in al,64h
    test al,2
    jz send_command_do
;       
    jmp send_check_ready

send_command_do:
    mov al,ds:mon_key_status
    or al,status_key_req
    and al,NOT status_key_ack
    mov ds:mon_key_status,al
;
    mov al,ds:mon_key_command
    out 60h,al

send_command_wait:
    call UpdateKeyboard
;    
    test ds:mon_key_status, status_key_ack
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
    mov ax,mon_data_sel
    mov ds,ax
;    
    test ds:mon_key_status,status_mode_change
    jz umDone
;    
    and ds:mon_key_status,NOT status_mode_change
    mov al,0EDh
    call SendCommand
;
    mov dx,ds:mon_shift_states
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
;           NAME:           GetKey
;
;           DESCRIPTION:    Get key
;
;           RETURNS:        NC
;                               AH      Scan code
;                               AL      VK code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
GetKey      PROC near
    push ds
;    
    call UpdateKeyboard
    call UpdateMode
;
    mov ax,mon_deb_sel
    mov ds,ax
    mov ah,ds:int_scan_code
    or ah,ah
    stc
    jz get_key_done
;
    mov ds:int_scan_code,0
    xor al,al
    xchg al,ds:int_c_vk_code
    clc
        
get_key_done:
    pop ds
    ret
GetKey      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowChar
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowChar Proc near
    push ds
    push es
    push fs
    pushad
;   
    push eax
    mov ax,mon_system_data_sel
    mov ds,ax
    mov ax,mon_deb_sel
    mov fs,ax
    mov eax,ds:mon_fixed_lfb
    or eax,eax
    pop eax
    jnz scLfb

scText:
    push eax
    mov ax,mon_text_sel
    mov es,ax
;
    mov ax,fs:int_deb_row
    mov cx,80
    mul cx
    add ax,fs:int_deb_col
    add ax,ax
    movzx edi,ax
    pop eax
    mov ah,7
    stosw
    jmp scUpdate

scLfb:
    push eax
    mov ax,mon_flat_sel
    mov es,ax
; 
    mov ax,fs:int_deb_row
    mov cx,19
    mul cx
    movzx eax,ax
    movzx edx,fs:int_deb_col
    shl edx,3
    xchg eax,edx
;
    push eax
    mov eax,ds:efi_scan_size
    mul edx
    mov edi,ds:mon_fixed_lfb
    add edi,eax
    pop eax
    shl eax,2
    add edi,eax
    pop eax
;
    mov ah,19
    mul ah
    movzx ebx,ax
    add ebx,OFFSET font8x19
;
    mov ecx,19

scRowLoop:    
    push ecx
    push edi
    mov ecx,8
    mov al,cs:[ebx]

scLoop:
    test al,80h
    jz scBack

scFore:
    mov edx,dword ptr ds:efi_fore_col
    mov es:[edi],edx
    jmp scNext

scBack:
    mov edx,dword ptr ds:efi_back_col
    mov es:[edi],edx

scNext:
    add edi,4
    shl al,1
;
    loop scLoop    
;
    pop edi
    pop ecx
    add edi,ds:efi_scan_size
    inc ebx
;
    loop scRowLoop    

scUpdate:
    inc fs:int_deb_col
    mov ax,fs:int_deb_col
    cmp ax,80
    jne scDone
;
    mov fs:int_deb_col,0
    inc fs:int_deb_row    

scDone:
    popad        
    pop fs
    pop es
    pop ds
    ret
ShowChar Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InvertChar
;
;           DESCRIPTION:    CX  Col
;                           DX  Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
InvertChar Proc near
    push ds
    push es
    pushad
;   
    mov ax,mon_system_data_sel
    mov ds,ax
    mov eax,ds:mon_fixed_lfb
    or eax,eax
    jz icDone

icLfb:
    mov ax,mon_flat_sel
    mov es,ax
; 
    push cx
    mov ax,dx
    mov cx,19
    mul cx
    movzx eax,ax
    pop dx
    movzx edx,dx
    shl edx,3
    xchg eax,edx
;
    push eax
    mov eax,ds:efi_scan_size
    mul edx
    mov edi,ds:mon_fixed_lfb
    add edi,eax
    pop eax
    shl eax,2
    add edi,eax
;
    mov ecx,19

icRowLoop:    
    push ecx
    push edi
    mov ecx,8

icLoop:
    mov eax,es:[edi]
    not eax
    mov es:[edi],eax
    add edi,4
    loop icLoop    
;
    pop edi
    pop ecx
    add edi,ds:efi_scan_size
;
    loop icRowLoop    

icDone:
    popad        
    pop es
    pop ds
    ret
InvertChar Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowMarker
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowMarker Proc near
    push ds
    push es
    push eax
    push ecx
    push edx
    push edi
;
    mov ax,mon_system_data_sel
    mov ds,ax
    mov eax,ds:mon_fixed_lfb
    or eax,eax
    jnz smLfb

smText:
    mov ax,mon_text_sel
    mov es,ax
;    
    mov ax,mon_deb_sel
    mov ds,ax
;
    mov ax,ds:int_curr_row
    mov dx,80
    mul dx
    add ax,ds:int_curr_col
    add ax,ax
    movzx edi,ax
    inc edi
    mov al,70h
    stosb
    jmp smDone

smLfb:
    mov ax,mon_deb_sel
    mov ds,ax
    mov dx,ds:int_curr_row
    mov cx,ds:int_curr_col
    call InvertChar

smDone:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds    
    ret
ShowMarker Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HideMarker
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HideMarker Proc near
    push ds
    push es
    push eax
    push ecx
    push edx
    push edi
;
    mov ax,mon_system_data_sel
    mov ds,ax
    mov eax,ds:mon_fixed_lfb
    or eax,eax
    jnz hmLfb

hmText:
    mov ax,mon_text_sel
    mov es,ax
;    
    mov ax,mon_deb_sel
    mov ds,ax
;
    mov ax,ds:int_curr_row
    mov dx,80
    mul dx
    add ax,ds:int_curr_col
    add ax,ax
    movzx edi,ax
    inc edi
    mov al,7
    stosb
    jmp hmDone

hmLfb:
    mov ax,mon_deb_sel
    mov ds,ax
    mov dx,ds:int_curr_row
    mov cx,ds:int_curr_col
    call InvertChar

hmDone:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds    
    ret
HideMarker Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Clear
;
;           DESCRIPTION:    Clear screen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Clear Proc near
    push ds
    pushad
;    
    mov ax,mon_deb_sel
    mov ds,ax
    mov ds:int_deb_col,0
    mov ds:int_deb_row,14
;
    mov ecx,80
    mov al,'+'
    
cLoop:
    call ShowChar
    loop cLoop
;
    popad
    pop ds    
    ret
Clear Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Blank
;
;           DESCRIPTION:    
;
;           PARAMETERS:         ECX          Number of blanks to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Blank   Proc near
    push eax
    push ecx
    mov al,' '
    
blank_loop:
    call ShowChar
    loop blank_loop
    pop ecx
    pop eax
    ret
Blank   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NewLine
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NewLine Proc near
    push ds
    push ax
    push dx
;
    mov ax,mon_deb_sel
    mov ds,ax

nlRetry:    
    mov al,' '
    call ShowChar
;
    mov dx,ds:int_deb_col
    or dx,dx
    jnz nlRetry
;
    pop dx
    pop ax
    pop ds
    ret
NewLine Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowCodeAsciiz
;
;           DESCRIPTION:    Show asciiz string from code
;
;           PARAMETERS:     CS:ESI      String to add
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowCodeAsciiz   PROC near
    push ax

scaLoop:
    lods cs:[esi]
    or al,al
    jz scaDone
;
    call ShowChar
    jmp scaLoop    

scaDone:
    pop ax
    ret
ShowCodeAsciiz   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowCodeSizeString
;
;           DESCRIPTION:    
;
;           PARAMETERS:     CS:ESI       String
;                           ECX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowCodeSizeString Proc near
    push eax
    push ecx
    push esi
;
    or ecx,ecx
    jz scssDone

scssLoop:
    lods byte ptr cs:[esi]
    call ShowChar
    loop scssLoop    

scssDone:
    pop esi
    pop ecx
    pop eax    
    ret
ShowCodeSizeString Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AL          Byte to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    PROC near
    push ax
    mov ah,al
    and al,0F0h
    rol al,4
    cmp al,0Ah
    jb write_byte_low1
;    
    add al,7

write_byte_low1:
    add al,'0'
    call ShowChar
    mov al,ah
    and al,0Fh
    cmp al,0Ah
    jb write_byte_high1
;    
    add al,7

write_byte_high1:
    add al,'0'
    call ShowChar
    pop ax
    ret
WriteHexByte    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AX          Word to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord    PROC near
    xchg al,ah
    call WriteHexByte
    xchg al,ah
    call WriteHexByte
    ret
WriteHexWord    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:         EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword   PROC near
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    ret
WriteHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteFault
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_code_tab:
ke00    DB 'Divide error            '
ke01    DB 'Single step             '
ke02    DB 'NMI                     '
ke03    DB 'Breakpoint              '
ke04    DB 'Overflow                '
ke05    DB 'Array bounds error      '
ke06    DB 'Invalid OP-code         '
ke07    DB '80387 not present       '
ke08    DB 'Double fault            '
ke09    DB '80387 overrun           '
ke0A    DB 'Invalid TSS             '
ke0B    DB 'Segment not present     '
ke0C    DB 'Stack fault             '
ke0D    DB 'Protection fault        '
ke0E    DB 'Page fault              '
ke0F    DB '                        '
ke10    DB '80387 error             '
ke11    DB 'Cannot emulate          '
ke12    DB 'Cannot emulate 80387    '
ke13    DB 'Now in real mode        '
ke14    DB '----------------------- '
ke15    DB 'Illegal int request     '
ke16    DB 'Undefined method        '
ke17    DB 'Invalid handle          '
ke18    DB 'Invalid selector        '
ke19    DB 'NMI                     '
ke1A    DB 'Crash Gate              '

WriteFault    Proc near
    movzx edx,ds:[ebp].fault_vect
    cmp dl,1Ah
    jbe wfDo
;
    mov dl,14h    

wfDo:
    mov ebx,edx
    add ebx,ebx
    add ebx,ebx
    add ebx,ebx
    mov ecx,ebx
    add ecx,ecx
    add ebx,ecx
    mov esi,OFFSET error_code_tab
    add esi,ebx
    mov ecx,24
    call ShowCodeSizeString
    ret
WriteFault    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteErrorReason
;
;   DESCRIPTION:    Write error reason
;
;   PARAMETERS:     DS:EBP      Regs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ft_idt  DB 'Idt '
ft_ldt  DB 'Ldt '
ft_gdt  DB 'Gdt '

WriteErrorReason     PROC near
    mov eax,ds:[ebp].fault_error
    test ax,2
    jz werNotIdt
;    
    mov esi,OFFSET ft_idt
    jmp werDo
    
werNotIdt:
    mov esi,OFFSET ft_gdt
    test ax,4
    jz werDo
;    
    mov esi,OFFSET ft_ldt

werDo:
    mov ecx,4
    call ShowCodeSizeString
;
    mov eax,ds:[ebp].fault_error
    and ax,0FFF8h
    call WriteHexWord    
    ret
WriteErrorReason     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteEflags
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eflags_tab:
;
;           reset       set
et_cf   DB 'NC ',       'CY '
et_1    DB 0,0,0,       0,0,0
et_pf   DB 'PO ',       'PE '
et_3    DB 0,0,0,       0,0,0
et_af   DB 'NA ',       'AC '
et_5    DB 0,0,0,       0,0,0
et_zf   DB 'NZ ',       'ZR '
et_sf   DB 'PL ',       'NG '
et_tf   DB 0,0,0,       0,0,0
et_if   DB 'DI ',       'EI '
et_df   DB 'UP ',       'DN '
et_of   DB 'NV ',       'OV '
et_12   DB 0,0,0,       0,0,0
et_13   DB 0,0,0,       0,0,0
et_14   DB 'PR ' ,      'NT '
et_15   DB 0,0,0,       0,0,0
et_16   DB 0,0,0,       0,0,0
et_vm   DB 'PM ',       'VM '

WriteEflags     PROC near
    push eax
    push ecx
    push edx
    push esi
;    
    mov eax,dword ptr ds:[ebp].reg_eflags
    mov esi,OFFSET eflags_tab
    mov ecx,18
    
eflags_loop:
    push esi
;    
    mov dl,cs:[esi]
    or dl,dl
    je eflags_next
;
    test al,1
    jz eflags_write_one
;    
    add esi,3

eflags_write_one:
    push ecx
    mov ecx,3
    call ShowCodeSizeString
    pop ecx
    
eflags_next:
    pop esi
;
    shr eax,1
    add esi,6
;
    loop eflags_loop
;
    pop esi
    pop edx
    pop ecx
    pop eax    
    ret
WriteEflags     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteDwordRegs
;
;           DESCRIPTION:    Write 32-bit registers
;
;           PARAMETERS:     CS:ESI       Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fault_reg_tab1:
    DB ' EAX='
    DD OFFSET reg_eax
    DB ' EBX='
    DD OFFSET reg_ebx
    DB ' ECX='
    DD OFFSET reg_ecx
    DB ' EDX='
    DD OFFSET reg_edx
    DB 0
    
fault_reg_tab2:
    DB ' ESI='
    DD OFFSET reg_esi
    DB ' EDI='
    DD OFFSET reg_edi
    DB ' ESP='
    DD OFFSET reg_esp
    DB ' EBP='
    DD OFFSET reg_ebp
    DB 0

fault_reg_tab3:
    DB ' EPC='
    DD OFFSET reg_eip
    DB 0

WriteDwordRegs  PROC near

dword_write_loop:
    mov al,cs:[esi]
    or al,al
    je dword_write_end
;
    mov ecx,5
    call ShowCodeSizeString
    add esi,5
    mov ebx,cs:[esi]
    mov eax,ds:[ebx+ebp]
    call WriteHexDword
    add esi,4
    jmp dword_write_loop

dword_write_end:
    ret
WriteDwordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteWordRegs
;
;           DESCRIPTION:    Write 16-bit registers
;
;           PARAMETERS:     CS:ESI       Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fault_reg_tab:
    DB ' CS='
    DD OFFSET reg_cs.d_selector
    DB ' SS='
    DD OFFSET reg_ss.d_selector
    DB ' DS='
    DD OFFSET reg_ds.d_selector
    DB ' ES='
    DD OFFSET reg_es.d_selector
    DB ' FS='
    DD OFFSET reg_fs.d_selector
    DB ' GS='
    DD OFFSET reg_gs.d_selector
    DB 0

WriteWordRegs  PROC near

word_write_loop:
    mov al,cs:[esi]
    or al,al
    je word_write_end
;
    mov ecx,4
    call ShowCodeSizeString
    add esi,4
    mov ebx,cs:[esi]
    mov ax,ds:[ebx+ebp]
    call WriteHexWord
    add esi,4
    jmp word_write_loop

word_write_end:
    ret
WriteWordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteInstr
;
;       DESCRIPTION:    Write instruction
;
;       PARAMETERS:     DS:EBP      Cpu registers
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteInstr  Proc near
    push es
    push ecx
    push esi
    push edi
;    
    mov ax,mon_deb_sel
    mov es,ax
;
    mov ecx,40
    mov edi,OFFSET int_dis_buf
    call IntDisAsmCode
;
    mov esi,OFFSET int_dis_buf
    mov ecx,40

wiLoop:
    lods byte ptr es:[esi]
    call ShowChar
    loop wiLoop
;
    pop edi
    pop esi
    pop ecx
    pop es
    ret
WriteInstr      Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteDataRow
;
;       DESCRIPTION:    Write a data row
;
;       PARAMETERS:     DS:EBP      Cpu registers
;                       BX:EDX      Address
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDataRow    Proc near
    push es
    mov ax,mon_flat_sel
    mov es,ax
;
    mov ax,bx
    call WriteHexWord
    mov al,':'
    call ShowChar
    mov eax,edx
    call WriteHexDword
    mov al,' '
    call ShowChar
;    
    push edx
    call GetSelectorBaseSizeType
    mov ebx,edx    
    mov esi,ecx
    pop edx
;
    pushf
    add ebx,edx
    popf
;
    push ebx
    push edx
;    
    mov ecx,16    
    pushf

wrDataLoop:
    popf
    jc wrDataInv
;    
    cmp esi,edx
    jc wrDataInv 
;    
    mov al,es:[ebx]
    call WriteHexByte
    clc
    jmp wrDataNext

wrDataInv:
    mov al,'!'
    call ShowChar
    call ShowChar
    stc

wrDataNext:
    pushf
    mov al,' '
    call ShowChar
;   
    inc ebx
    inc edx
    loop wrDataLoop
;
    popf    
    pop edx
    pop ebx
;    
    mov ecx,16    
    pushf

wrCharLoop:
    popf
    jc wrCharInv
;    
    cmp esi,edx
    jc wrCharInv 
;    
    mov al,es:[ebx]
    call ShowChar
    clc
    jmp wrCharNext

wrCharInv:
    mov al,'!'
    call ShowChar
    stc

wrCharNext:
    pushf
    inc ebx
    inc edx
    loop wrCharLoop
;
    popf    
;
    pop es
    ret
WriteDataRow    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteRegs
;
;       DESCRIPTION:    Write registers
;
;       PARAMETERS:     DS:EBP      Cpu registers
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteRegs    Proc near
    call Clear
;    
    mov ax,mon_deb_sel
    mov ds,ax
    xor ebp,ebp    
;
    mov esi,OFFSET fault_reg_tab1
    call WriteDwordRegs
    call NewLine
;
    mov esi,OFFSET fault_reg_tab2
    call WriteDwordRegs
    call NewLine
;
    mov esi,OFFSET fault_reg_tab3
    call WriteDwordRegs
    mov al,' '
    call ShowChar
    call WriteFault
    call WriteErrorReason
    call NewLine
;
    mov esi,OFFSET fault_reg_tab
    call WriteWordRegs
    call NewLine
;
    call WriteEflags    
    call NewLine
;
    call WriteInstr
    call NewLine
;
    mov al,ds:[ebp].data_valid
    or al,al
    jz wcNoPtr
;
    mov ebx,ds:[ebp].data_sel
    mov edx,ds:[ebp].data_offset
    call WriteDataRow
    jmp wcPtrOk

wcNoPtr:
    mov ecx,79
    call Blank
    
wcPtrOk:    
    call NewLine    
;    
    mov bx,ds:[ebp].reg_cs.d_selector
    mov edx,ds:[ebp].reg_eip
    call WriteDataRow
    call NewLine    
;
    mov bx,ds:[ebp].reg_ss.d_selector
    mov edx,ds:[ebp].reg_esp
    call WriteDataRow
    call NewLine    
;    
    mov bx,ds:[ebp].reg_usel.d_selector
    mov edx,ds:[ebp].reg_uoffs
    call WriteDataRow
    call NewLine    
;
    ret
WriteRegs	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           error_sw
;
;           DESCRIPTION:    Error sw
;
;           PARAMETERS:     DS:EBP              Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pace_sw:
reg_sw:

error_sw Proc near
    ret
error_sw Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           trace_sw
;
;           DESCRIPTION:    Trace sw
;
;           PARAMETERS:     DS:EBP              Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trace_sw:
    mov ax,word ptr ds:[ebp].reg_eflags
    or ax,100h
    mov word ptr ds:[ebp].reg_eflags,ax
    jmp RestartFault

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           go_sw
;
;           DESCRIPTION:    Go sw
;
;           PARAMETERS:     DS:EBP              Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

go_sw:
    mov ax,word ptr ds:[ebp].reg_eflags
    and ax,NOT 100h
    mov word ptr ds:[ebp].reg_eflags,ax
    jmp RestartFault

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ignore
;
;           DESCRIPTION:    Ignore
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ignore  Proc near
    ret
ignore  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_reg_byte
;
;           DESCRIPTION:    Perform inc on byte in reg
;
;           PARAMETERS:     DS:EBP  Core registers
;                           ESI     Register offset
;                           EBX     Table entry
;                           CX      Digit #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_reg_byte    Proc near
    mov ax,cs:[ebx].exec_size
    sub ax,cx
    dec ax
    mov cl,al
    shl cl,2
    mov edx,0Fh
    shl edx,cl
;    
    mov eax,ds:[ebp+esi]
    and eax,edx
    shr eax,cl
    inc al
    and al,0Fh
    shl eax,cl
    not edx
    and edx,ds:[ebp+esi]
    or eax,edx
    mov ds:[ebp+esi],eax
    ret
inc_reg_byte  Endp

inc_sreg_byte  Proc near
    push esi
    add esi,d_selector
    call inc_reg_byte
    pop esi
    ret
inc_sreg_byte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_reg_byte
;
;           DESCRIPTION:    Perform dec on byte in reg
;
;           PARAMETERS:     DS:EBP  Core registers
;                           ESI     Register offset
;                           EBX     Table entry
;                           CX      Digit #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_reg_byte    Proc near
    mov ax,cs:[ebx].exec_size
    sub ax,cx
    dec ax
    mov cl,al
    shl cl,2
    mov edx,0Fh
    shl edx,cl
;    
    mov eax,ds:[ebp+esi]
    and eax,edx
    shr eax,cl
    dec al
    and al,0Fh
    shl eax,cl
    not edx
    and edx,ds:[ebp+esi]
    or eax,edx
    mov ds:[ebp+esi],eax
    ret
dec_reg_byte  Endp

dec_sreg_byte  Proc near
    push esi
    add esi,d_selector
    call dec_reg_byte
    pop esi
    ret
dec_sreg_byte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_reg4
;
;           DESCRIPTION:    Perform dword inc on reg
;
;           PARAMETERS:     DS:EBP  Core registers
;                           ESI     Register offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_reg4    Proc near
    inc dword ptr ds:[ebp+esi]
    ret
inc_reg4  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_reg4
;
;           DESCRIPTION:    Perform dword dec on reg
;
;           PARAMETERS:     DS:EBP  Core registers
;                           ESI     Register offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_reg4    Proc near
    dec dword ptr ds:[ebp+esi]
    ret
dec_reg4  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_reg8
;
;           DESCRIPTION:    Perform qword inc on reg
;
;           PARAMETERS:     DS:EBP  Core registers
;                           ESI     Register offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_reg8    Proc near
    add dword ptr ds:[ebp+esi],1
    adc dword ptr ds:[ebp+esi+4],0
    ret
inc_reg8  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_reg8
;
;           DESCRIPTION:    Perform qword dec on reg
;
;           PARAMETERS:     DS:EBP  Core registers
;                           ESI     Register offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_reg8    Proc near
    sub dword ptr ds:[ebp+esi],1
    sbb dword ptr ds:[ebp+esi+4],0
    ret
dec_reg8  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_reg_byte
;
;           DESCRIPTION:    Perform set on reg
;
;           PARAMETERS:     DS:EBP  Core regs
;                           ESI     Register offset
;                           EBX     Table entry
;                           AL      Value to set
;                           CX      Digit number
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_reg_byte    Proc near
    mov dx,cs:[ebx].exec_size
    sub dx,cx
    dec dx
    mov cl,dl
    shl cl,2
    mov edx,0Fh
    shl edx,cl
    not edx
    and edx,ds:[ebp+esi]
    movzx eax,al
    shl eax,cl
    or eax,edx
    mov ds:[ebp+esi],eax
;
    push ds
    mov ax,mon_deb_sel
    mov ds,ax
    inc ds:int_curr_col
    pop ds
    ret
set_reg_byte  Endp

set_sreg_byte  Proc near
    push esi
    add esi,d_selector
    call set_reg_byte
    pop esi
    ret
set_sreg_byte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Func
;
;           DESCRIPTION:    Function on regs
;
;           PARAMETERS:     DS:EBP              Registers
;                           EDI                 Function ptr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
exec_table:
meax32  exec_s <15, 1,  3, OFFSET reg_eax,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
deax32  exec_s <15, 5,  8, OFFSET reg_eax,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mebx32  exec_s <15, 14, 3, OFFSET reg_ebx,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
debx32  exec_s <15, 18, 8, OFFSET reg_ebx,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mecx32  exec_s <15, 27, 3, OFFSET reg_ecx,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
decx32  exec_s <15, 31, 8, OFFSET reg_ecx,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
medx32  exec_s <15, 40, 3, OFFSET reg_edx,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
dedx32  exec_s <15, 44, 8, OFFSET reg_edx,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mesi32  exec_s <16, 1,  3, OFFSET reg_esi,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
desi32  exec_s <16, 5,  8, OFFSET reg_esi,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
medi32  exec_s <16, 14, 3, OFFSET reg_edi,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
dedi32  exec_s <16, 18, 8, OFFSET reg_edi,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mesp32  exec_s <16, 27, 3, OFFSET reg_esp,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
desp32  exec_s <16, 31, 8, OFFSET reg_esp,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mebp32  exec_s <16, 40, 3, OFFSET reg_ebp,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
debp32  exec_s <16, 44, 8, OFFSET reg_ebp,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
meip32  exec_s <17, 1,  3, OFFSET reg_eip,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
deip32  exec_s <17, 5,  8, OFFSET reg_eip,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
dds32   exec_s <18, 20, 4, OFFSET reg_ds,       OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
des32   exec_s <18, 28, 4, OFFSET reg_es,       OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
dfs32   exec_s <18, 36, 4, OFFSET reg_fs,       OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
dgs32   exec_s <18, 44, 4, OFFSET reg_gs,       OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
duss32  exec_s <24, 0,  4, OFFSET reg_usel,     OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
duso32  exec_s <24, 5,  8, OFFSET reg_uoffs,    OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
dend32 DW     0FFFFh, 0FFFFh

Func  PROC near
    push es
    mov bx,mon_deb_sel
    mov es,bx
    mov ebx,OFFSET exec_table

fLoop:
    mov cx,cs:[ebx].exec_row
    cmp cx,0FFFFh
    je fDone
;    
    cmp cx,es:int_curr_row
    jne fNext
;
    mov cx,es:int_curr_col
    sub cx,cs:[ebx].exec_col
    jc fNext
;    
    cmp cx,cs:[ebx].exec_size
    jnc fNext
;    
    mov esi,cs:[ebx].exec_reg
    call dword ptr cs:[ebx+edi]
    jmp fDone
    
fNext:
    add ebx,SIZE exec_s
    jmp fLoop
    
fDone:
    pop es
    ret
Func  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_sw
;
;           DESCRIPTION:    Inc
;
;           PARAMETERS:     DS:EBP              Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_sw  PROC near
    pushad
    mov edi,exec_inc_proc
    call Func
    popad
    ret
inc_sw  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_sw
;
;           DESCRIPTION:    Dec
;
;           PARAMETERS:     DS:EBP              Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_sw  PROC near
    pushad
    mov edi,exec_dec_proc
    call Func
    popad
    ret
dec_sw  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_base_sw
;
;           DESCRIPTION:    Set
;
;           PARAMETERS:     DS:EBP              Registers
;                           CH                  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_base_sw   Proc near
    pushad
    mov edi,exec_set_proc
    call Func
    popad
    ret
set_base_sw   Endp

set0_sw:
    mov al,0
    jmp set_base_sw

set1_sw:
    mov al,1
    jmp set_base_sw

set2_sw:
    mov al,2
    jmp set_base_sw

set3_sw:
    mov al,3
    jmp set_base_sw

set4_sw:
    mov al,4
    jmp set_base_sw

set5_sw:
    mov al,5
    jmp set_base_sw

set6_sw:
    mov al,6
    jmp set_base_sw

set7_sw:
    mov al,7
    jmp set_base_sw

set8_sw:
    mov al,8
    jmp set_base_sw

set9_sw:
    mov al,9
    jmp set_base_sw

setA_sw:
    mov al,0Ah
    jmp set_base_sw

setB_sw:
    mov al,0Bh
    jmp set_base_sw

setC_sw:
    mov al,0Ch
    jmp set_base_sw

setD_sw:
    mov al,0Dh
    jmp set_base_sw

setE_sw:
    mov al,0Eh
    jmp set_base_sw

setF_sw:
    mov al,0Fh
    jmp set_base_sw

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoFunc
;
;           DESCRIPTION:    Do function
;
;           PARAMETERS:     AL          Key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
virt_sw_func_tab:
vs_00   DD OFFSET error_sw
vs_01   DD OFFSET error_sw
vs_02   DD OFFSET error_sw
vs_03   DD OFFSET error_sw
vs_04   DD OFFSET error_sw
vs_05   DD OFFSET error_sw
vs_06   DD OFFSET error_sw
vs_07   DD OFFSET error_sw
vs_08   DD OFFSET error_sw
vs_09   DD OFFSET error_sw
vs_0A   DD OFFSET error_sw
vs_0B   DD OFFSET error_sw
vs_0C   DD OFFSET error_sw
vs_0D   DD OFFSET error_sw
vs_0E   DD OFFSET error_sw
vs_0F   DD OFFSET error_sw
vs_10   DD OFFSET error_sw
vs_11   DD OFFSET error_sw
vs_12   DD OFFSET error_sw
vs_13   DD OFFSET error_sw
vs_14   DD OFFSET error_sw
vs_15   DD OFFSET error_sw
vs_16   DD OFFSET error_sw
vs_17   DD OFFSET error_sw
vs_18   DD OFFSET error_sw
vs_19   DD OFFSET error_sw
vs_1A   DD OFFSET error_sw
vs_1B   DD OFFSET error_sw
vs_1C   DD OFFSET error_sw
vs_1D   DD OFFSET error_sw
vs_1E   DD OFFSET error_sw
vs_1F   DD OFFSET error_sw
vs_20   DD OFFSET error_sw
vs_21   DD OFFSET error_sw
vs_22   DD OFFSET error_sw
vs_23   DD OFFSET error_sw
vs_24   DD OFFSET error_sw
vs_25   DD OFFSET error_sw
vs_26   DD OFFSET error_sw
vs_27   DD OFFSET error_sw
vs_28   DD OFFSET error_sw
vs_29   DD OFFSET error_sw
vs_2A   DD OFFSET error_sw
vs_2B   DD OFFSET inc_sw
vs_2C   DD OFFSET error_sw
vs_2D   DD OFFSET dec_sw
vs_2E   DD OFFSET error_sw
vs_2F   DD OFFSET error_sw
vs_30   DD OFFSET set0_sw
vs_31   DD OFFSET set1_sw
vs_32   DD OFFSET set2_sw
vs_33   DD OFFSET set3_sw
vs_34   DD OFFSET set4_sw
vs_35   DD OFFSET set5_sw
vs_36   DD OFFSET set6_sw
vs_37   DD OFFSET set7_sw
vs_38   DD OFFSET set8_sw
vs_39   DD OFFSET set9_sw
vs_3A   DD OFFSET error_sw
vs_3B   DD OFFSET error_sw
vs_3C   DD OFFSET error_sw
vs_3D   DD OFFSET error_sw
vs_3E   DD OFFSET error_sw
vs_3F   DD OFFSET error_sw
vs_40   DD OFFSET error_sw
vs_41   DD OFFSET setA_sw
vs_42   DD OFFSET setB_sw
vs_43   DD OFFSET setC_sw
vs_44   DD OFFSET setD_sw
vs_45   DD OFFSET setE_sw
vs_46   DD OFFSET setF_sw
vs_47   DD OFFSET go_sw
vs_48   DD OFFSET error_sw
vs_49   DD OFFSET error_sw
vs_4A   DD OFFSET error_sw
vs_4B   DD OFFSET error_sw
vs_4C   DD OFFSET error_sw
vs_4D   DD OFFSET error_sw
vs_4E   DD OFFSET error_sw
vs_4F   DD OFFSET error_sw
vs_50   DD OFFSET pace_sw
vs_51   DD OFFSET error_sw
vs_52   DD OFFSET error_sw
vs_53   DD OFFSET error_sw
vs_54   DD OFFSET trace_sw
vs_55   DD OFFSET error_sw
vs_56   DD OFFSET error_sw
vs_57   DD OFFSET error_sw
vs_58   DD OFFSET error_sw
vs_59   DD OFFSET error_sw
vs_5A   DD OFFSET error_sw
vs_5B   DD OFFSET error_sw
vs_5C   DD OFFSET error_sw
vs_5D   DD OFFSET error_sw
vs_5E   DD OFFSET error_sw
vs_5F   DD OFFSET error_sw
vs_60   DD OFFSET error_sw
vs_61   DD OFFSET setA_sw
vs_62   DD OFFSET setB_sw
vs_63   DD OFFSET setC_sw
vs_64   DD OFFSET setD_sw
vs_65   DD OFFSET setE_sw
vs_66   DD OFFSET setF_sw
vs_67   DD OFFSET go_sw
vs_68   DD OFFSET error_sw
vs_69   DD OFFSET error_sw
vs_6A   DD OFFSET error_sw
vs_6B   DD OFFSET inc_sw
vs_6C   DD OFFSET error_sw
vs_6D   DD OFFSET dec_sw
vs_6E   DD OFFSET error_sw
vs_6F   DD OFFSET error_sw
vs_70   DD OFFSET pace_sw
vs_71   DD OFFSET error_sw
vs_72   DD OFFSET error_sw
vs_73   DD OFFSET error_sw
vs_74   DD OFFSET trace_sw
vs_75   DD OFFSET error_sw
vs_76   DD OFFSET error_sw
vs_77   DD OFFSET error_sw
vs_78   DD OFFSET error_sw
vs_79   DD OFFSET error_sw
vs_7A   DD OFFSET error_sw
vs_7B   DD OFFSET error_sw
vs_7C   DD OFFSET error_sw
vs_7D   DD OFFSET error_sw
vs_7E   DD OFFSET error_sw
vs_7F   DD OFFSET error_sw
vs_80   DD OFFSET error_sw
vs_81   DD OFFSET error_sw
vs_82   DD OFFSET error_sw
vs_83   DD OFFSET error_sw
vs_84   DD OFFSET error_sw
vs_85   DD OFFSET error_sw
vs_86   DD OFFSET error_sw
vs_87   DD OFFSET error_sw
vs_88   DD OFFSET error_sw
vs_89   DD OFFSET error_sw
vs_8A   DD OFFSET error_sw
vs_8B   DD OFFSET error_sw
vs_8C   DD OFFSET error_sw
vs_8D   DD OFFSET error_sw
vs_8E   DD OFFSET error_sw
vs_8F   DD OFFSET error_sw
vs_90   DD OFFSET error_sw
vs_91   DD OFFSET error_sw
vs_92   DD OFFSET error_sw
vs_93   DD OFFSET error_sw
vs_94   DD OFFSET error_sw
vs_95   DD OFFSET error_sw
vs_96   DD OFFSET error_sw
vs_97   DD OFFSET error_sw
vs_98   DD OFFSET error_sw
vs_99   DD OFFSET error_sw
vs_9A   DD OFFSET error_sw
vs_9B   DD OFFSET error_sw
vs_9C   DD OFFSET error_sw
vs_9D   DD OFFSET error_sw
vs_9E   DD OFFSET error_sw
vs_9F   DD OFFSET error_sw
vs_A0   DD OFFSET error_sw
vs_A1   DD OFFSET error_sw
vs_A2   DD OFFSET error_sw
vs_A3   DD OFFSET error_sw
vs_A4   DD OFFSET error_sw
vs_A5   DD OFFSET error_sw
vs_A6   DD OFFSET error_sw
vs_A7   DD OFFSET error_sw
vs_A8   DD OFFSET error_sw
vs_A9   DD OFFSET error_sw
vs_AA   DD OFFSET error_sw
vs_AB   DD OFFSET error_sw
vs_AC   DD OFFSET error_sw
vs_AD   DD OFFSET error_sw
vs_AE   DD OFFSET error_sw
vs_AF   DD OFFSET error_sw
vs_B0   DD OFFSET error_sw
vs_B1   DD OFFSET error_sw
vs_B2   DD OFFSET error_sw
vs_B3   DD OFFSET error_sw
vs_B4   DD OFFSET error_sw
vs_B5   DD OFFSET error_sw
vs_B6   DD OFFSET error_sw
vs_B7   DD OFFSET error_sw
vs_B8   DD OFFSET error_sw
vs_B9   DD OFFSET error_sw
vs_BA   DD OFFSET error_sw
vs_BB   DD OFFSET error_sw
vs_BC   DD OFFSET error_sw
vs_BD   DD OFFSET error_sw
vs_BE   DD OFFSET error_sw
vs_BF   DD OFFSET error_sw
vs_C0   DD OFFSET error_sw
vs_C1   DD OFFSET error_sw
vs_C2   DD OFFSET error_sw
vs_C3   DD OFFSET error_sw
vs_C4   DD OFFSET error_sw
vs_C5   DD OFFSET error_sw
vs_C6   DD OFFSET error_sw
vs_C7   DD OFFSET error_sw
vs_C8   DD OFFSET error_sw
vs_C9   DD OFFSET error_sw
vs_CA   DD OFFSET error_sw
vs_CB   DD OFFSET error_sw
vs_CC   DD OFFSET error_sw
vs_CD   DD OFFSET error_sw
vs_CE   DD OFFSET error_sw
vs_CF   DD OFFSET error_sw
vs_D0   DD OFFSET error_sw
vs_D1   DD OFFSET error_sw
vs_D2   DD OFFSET error_sw
vs_D3   DD OFFSET error_sw
vs_D4   DD OFFSET error_sw
vs_D5   DD OFFSET error_sw
vs_D6   DD OFFSET error_sw
vs_D7   DD OFFSET error_sw
vs_D8   DD OFFSET error_sw
vs_D9   DD OFFSET error_sw
vs_DA   DD OFFSET error_sw
vs_DB   DD OFFSET error_sw
vs_DC   DD OFFSET error_sw
vs_DD   DD OFFSET error_sw
vs_DE   DD OFFSET error_sw
vs_DF   DD OFFSET error_sw
vs_E0   DD OFFSET error_sw
vs_E1   DD OFFSET error_sw
vs_E2   DD OFFSET error_sw
vs_E3   DD OFFSET error_sw
vs_E4   DD OFFSET error_sw
vs_E5   DD OFFSET error_sw
vs_E6   DD OFFSET error_sw
vs_E7   DD OFFSET error_sw
vs_E8   DD OFFSET error_sw
vs_E9   DD OFFSET error_sw
vs_EA   DD OFFSET error_sw
vs_EB   DD OFFSET error_sw
vs_EC   DD OFFSET error_sw
vs_ED   DD OFFSET error_sw
vs_EE   DD OFFSET error_sw
vs_EF   DD OFFSET error_sw
vs_F0   DD OFFSET error_sw
vs_F1   DD OFFSET error_sw
vs_F2   DD OFFSET error_sw
vs_F3   DD OFFSET error_sw
vs_F4   DD OFFSET error_sw
vs_F5   DD OFFSET error_sw
vs_F6   DD OFFSET error_sw
vs_F7   DD OFFSET error_sw
vs_F8   DD OFFSET error_sw
vs_F9   DD OFFSET error_sw
vs_FA   DD OFFSET error_sw
vs_FB   DD OFFSET error_sw
vs_FC   DD OFFSET error_sw
vs_FD   DD OFFSET error_sw
vs_FE   DD OFFSET error_sw
vs_FF   DD OFFSET error_sw

DoFunc   PROC near
    pushad
;    
    movzx ebx,al
    shl ebx,2
    call dword ptr cs:[ebx].virt_sw_func_tab
;
    call HideMarker
    call WriteRegs
    call ShowMarker

debug_end:
    popad
    ret
DoFunc   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DumpFault
;
;           DESCRIPTION:    Dump fault
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RestartFault:
    mov ax,mon_deb_sel
    mov ds,ax
    mov ds:int_count,0
;
    mov esp,ds:reg_esp
;
    mov eax,ds:reg_eflags
    push eax
;
    mov eax,cs
    push eax
;
    mov eax,ds:reg_eip
    push eax
;
    mov eax,ds:reg_eax
    mov ebx,ds:reg_ebx
    mov ecx,ds:reg_ecx
    mov edx,ds:reg_edx
    mov esi,ds:reg_esi
    mov edi,ds:reg_edi
    mov ebp,ds:reg_ebp
;
    mov es,ds:reg_es.d_selector
    mov fs,ds:reg_fs.d_selector
    mov gs,ds:reg_gs.d_selector
    mov ds,ds:reg_ds.d_selector
    iretd

DumpFault:
    push es
;
    mov ax,mon_deb_sel
    mov es,ax
;    
    mov al,byte ptr [ebp].trap_exc_nr
    mov es:fault_vect,al
;
    mov eax,[ebp].trap_err
    mov es:fault_error,eax
;
    mov eax,[ebp].trap_eip
    mov es:reg_eip,eax
;
    mov eax,[ebp].trap_eflags
    mov es:reg_eflags,eax
    mov eax,[ebp].trap_eax
    mov es:reg_eax,eax
    mov es:reg_ecx,ecx
    mov es:reg_edx,edx
    mov eax,[ebp].trap_ebx
    mov es:reg_ebx,eax
    mov eax,ebp
    add eax,20
    mov es:reg_esp,eax
    mov es:reg_esi,esi
    mov es:reg_edi,edi
    mov ax,[ebp].trap_cs
    mov es:reg_cs.d_selector,ax
    mov es:reg_ss.d_selector,ss
    mov ax,[ebp].trap_pds
    mov es:reg_ds.d_selector,ax
    pop ax
    mov es:reg_es.d_selector,ax
    mov es:reg_fs.d_selector,fs
    mov es:reg_gs.d_selector,gs
    mov ebp,[ebp].trap_ebp
    mov es:reg_ebp,ebp
    sldt ax
    mov es:reg_ldt.d_selector,ax       
;
    mov al,es:int_started
    or al,al
    jnz wcStarted
;
    mov es:int_started,1
    mov es:int_curr_row,15
    mov es:int_curr_col,0

wcStarted:
    call WriteRegs
;
    mov ax,mon_deb_sel
    mov ds,ax
    mov al,ds:int_count
    or al,al
    jz fdKey

fdStop:
    jmp fdStop
    
fdKey:
    mov ds:int_count,1
    call ShowMarker
    call InitKey
    
fdLoop:
    call GetKey
    jc fdLoop
;    
    test ah,80h
    jnz fdLoop
;    
    cmp al,25h
    je fdLeft
;
    cmp al,27h
    je fdRight
;        
    cmp al,26h
    je fdUp
;
    cmp al,28h
    je fdDown
;
    call DoFunc
    jmp fdLoop

fdUp:
    mov dx,ds:int_curr_row
    cmp dx,15
    jbe fdLoop
;    
    call HideMarker
    dec ds:int_curr_row
    call ShowMarker
    jmp fdLoop

fdDown:
    mov dx,ds:int_curr_row
    cmp dx,24
    je fdLoop
;
    call HideMarker
    inc ds:int_curr_row
    call ShowMarker
    jmp fdLoop

fdLeft:
    mov dx,ds:int_curr_col
    or dx,dx
    jz fdLoop
;
    call HideMarker
    dec ds:int_curr_col
    call ShowMarker
    jmp fdLoop    

fdRight:
    mov dx,ds:int_curr_col
    cmp dx,79
    je fdLoop
;
    call HideMarker
    inc ds:int_curr_col
    call ShowMarker
    jmp fdLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Fault handlers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cint0:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,0
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint1:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,1
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint3:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,3
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint4:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,4
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint5:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,5
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint6:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,6
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint7:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,7
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint8:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,8
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint9:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,9
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint10:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    push ds
    mov ax,10
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint11:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,11
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint12:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,12
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint13:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,13
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint14:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,14
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint16:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,16
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

chwint:
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupInt
;
;           DESCRIPTION:    Create int gate selector
;
;           PARAMETERS:     AL              Int #
;                           ESI             Entry point
;                           EDX             IDT base
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInt     PROC near
    push ds
    push eax
    push ebx
;   
    movzx ebx,al
    shl ebx,3
    add ebx,edx
;
    mov ax,flat_sel
    mov ds,ax    
;    
    mov ax,8E00h
    mov ds:[ebx+4],ax
    mov ds:[ebx],esi
    mov ax,mon_code_sel
    xchg ax,ds:[ebx+2]
    mov ds:[ebx+6],ax
;
    pop ebx
    pop eax
    pop ds
    ret
SetupInt     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          InitMonitorIdt
;
;           DESCRIPTION:   Init monitor IDT
;
;           PARAMETERS:    EDX          IDT base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crash_int_tab:
;
;               int #       Entry          
;
ci0     DD      0,          OFFSET cint0
ci1     DD      1,          OFFSET cint1
ci2     DD      2,          OFFSET chwint
ci3     DD      3,          OFFSET cint3
ci4     DD      4,          OFFSET cint4
ci5     DD      5,          OFFSET cint5
ci6     DD      6,          OFFSET cint6
ci7     DD      7,          OFFSET cint7
ci8     DD      8,          OFFSET cint8
ci9     DD      9,          OFFSET cint9
ci10    DD      10,         OFFSET cint10
ci11    DD      11,         OFFSET cint11
ci12    DD      12,         OFFSET cint12
ci13    DD      13,         OFFSET cint13
ci14    DD      14,         OFFSET cint14
ci16    DD      16,         OFFSET cint16
ci40    DD      40h,        OFFSET chwint
ci80    DD      80h,        OFFSET chwint
ci81    DD      81h,        OFFSET chwint
ci82    DD      82h,        OFFSET chwint
ci83    DD      83h,        OFFSET chwint
ci_end  DD      0FFFFFFFFh

    public InitMonitorIdt

InitMonitorIdt    Proc near
    mov edi,OFFSET crash_int_tab

imiLoop:
    mov ax,cs:[edi]
    cmp ax,0FFFFh
    jz imiDone
;
    xor bl,bl
    mov esi,dword ptr cs:[edi+4]
    call SetupInt
    add edi,8
    jmp imiLoop

imiDone:
    mov ax,mon_data_sel

    ret
InitMonitorIdt   Endp

code    ENDS

    END
