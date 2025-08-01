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
; crkey.ASM
; Crash debugger keyboard module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE kdebug.inc

PORT_BASE    = 3F8h
BAUD_DIVISOR = 12

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

    .386p

code    SEGMENT byte public use32 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalCpuReset
;
;           DESCRIPTION:    Trigger a CPU reset
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LocalCpuReset

fake_idt  DD 0, 0

MemReset   Proc near
    ret
MemReset   Endp

IoReset   Proc near
    mov edx,ds:acpi_reset_addr
    mov al,ds:acpi_reset_data
    out dx,al
    ret
IoReset   Endp

PciReset   Proc near
    ret
PciReset   Endp

reset_tab:
rt00 DD OFFSET MemReset
rt01 DD OFFSET IoReset
rt02 DD OFFSET PciReset

LocalCpuReset   Proc near
    cli
    mov ax,mon_system_data_sel
    mov ds,eax
    mov al,ds:acpi_reset_method
    cmp al,3
    jae legacy_reset
;
    movzx ebx,al
    call dword ptr cs:[4*ebx].reset_tab
    jmp tripple_fault

legacy_reset:
    mov ecx,10000h

wait_gate1:
    in al,64h
    and al,2
    jz done_gate1
;
    loop wait_gate1

done_gate1:
    mov al,0D1h
    out 64h,al
    mov ecx,10000h

wait_gate2:
    in al,64h
    and al,2
    jz done_gate2
;
    loop wait_gate2

done_gate2:
    mov al,0FEh
    out 60h,al

tripple_fault:
    mov ebx,OFFSET fake_idt
    lidt fword ptr cs:[ebx]
;
    xor eax,eax
    mov cr3,eax
    
    ret
LocalCpuReset   ENDP

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

    public SaveKeyboardCode

SaveKeyboardCode    PROC near
    push ds
    push ax
    push bx
;
    mov bx,mon_data_sel
    mov ds,bx
;
    mov ds:mon_key_code,ax
    mov ds:mon_c_vk_code,dl
    mov ds:mon_scan_code,dh
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
    mov ax,mon_data_sel
    mov ds,ax
    mov ds:mon_key_status,0
    mov ds:mon_shift_states,0
    mov ds:mon_key_code,0
    mov ds:mon_c_vk_code,0
    mov ds:mon_scan_code,0
    mov ds:mon_usb_shift,0
    mov ds:mon_usb_keys,0
;
    mov al,83h
    mov dx,PORT_BASE + 3
    out dx,al           ; set line control to divisor access
;
    mov dx,PORT_BASE
    mov ax,BAUD_DIVISOR
    out dx,al           ; output LSB divisor latch
;
    mov dx,PORT_BASE + 1
    mov al,ah
    out dx,al           ; output MSB divisor latch
;
    mov dx,PORT_BASE + 2
    mov al,1
    out dx,al           ; enable FIFOs if present
;
    mov dx,PORT_BASE + 3
    mov al,3
    out dx,al           ; set line control 
;
    mov dx,PORT_BASE + 1
    xor al,al
    out dx,al           ; no ints
;
    mov dx,PORT_BASE + 4
    in al,dx
    or al,0Bh
    out dx,al           ; modem control, DTR = high, RTS = high
;
    mov dx,PORT_BASE
    in al,dx
;
    mov dx,PORT_BASE + 5
    in al,dx
;
    mov dx,PORT_BASE + 6
    in al,dx
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
;       NAME:           PollCom
;
;       DESCRIPTION:    Poll com port
;
;       RETURNS:        NC
;                           AL    Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollCom  Proc near
    push dx
;
    mov dx,PORT_BASE + 5
    in al,dx
    test al,1
    stc
    jz ppDone
;
    mov dx,PORT_BASE
    in al,dx
    clc

ppDone:    
    pop dx
    ret
PollCom  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadCom
;
;       DESCRIPTION:    Read com port
;
;       RETURNS:        NC
;                           AL    Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCom  Proc near
    call PollCom
    jc ReadCom
    ret
ReadCom  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMsg
;
;       DESCRIPTION:    Get complete message
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMsg  Proc near
    mov bx,OFFSET mon_com_buf
    mov cx,13

gmLoop:
    call ReadCom
    cmp al,0Dh
    je gmWaitLf
;
    mov ds:[bx],al
    inc bx
    loop gmLoop
;
    stc
    jmp gmDone

gmWaitLf:
    call ReadCom
    cmp al,0Ah
    stc
    jne gmDone
;
    cmp cx,1
    stc
    jne gmDone
;
    xor al,al
    mov ds:[bx],al
    clc

gmDone:
    ret
GetMsg   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DecodeHexByte
;
;       Purpose:        Get hex byte from string
;
;       Parameters:     DS:SI       String in
;
;       Returns:        DS:SI       String out
;                       NC          OK
;                           AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeHexByte Proc near
    push dx
;
    xor dl,dl
    lodsb
    sub al,'0'
    jc dbFail
;
    cmp al,10
    jb dbSave1
;
    sub al,7
    jc dbFail
;
    cmp al,10h
    jae dbFail

dbSave1:
    shl al,4
    mov dl,al
;
    lodsb
    sub al,'0'
    jc dbFail
;
    cmp al,10
    jb dbSave2
;
    sub al,7
    jc dbFail
;
    cmp al,10h
    jae dbFail

dbSave2:
    or al,dl
    clc
    jmp dbDone

dbFail:
    stc

dbDone:
    pop dx    
    ret
DecodeHexByte    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DecodeHexWord
;
;       Purpose:        Get hex word from string
;
;       Parameters:     DS:SI       String in
;
;       Returns:        DS:SI       String out
;                       NC          OK
;                           AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeHexWord Proc near
    push dx
;
    call DecodeHexByte
    jc dhwDone
;
    mov dl,al
    call DecodeHexByte
    jc dhwDone
;
    mov ah,dl
    clc

dhwDone:
    pop dx
    ret
DecodeHexWord Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UpdateCom
;
;       DESCRIPTION:    Update com port
;
;       RETURNS:        NC
;                           AL    Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateCom  Proc near
    call PollCom
    jc ucDone
;
    cmp al,'P'
    je ucPress
;
    cmp al,'R'
    jne ucDone

ucRel:
    call GetMsg
    jmp ucDone

ucPress:
    call GetMsg
    jc ucDone
;
    mov si,OFFSET mon_com_buf
;
    call DecodeHexWord   
    jc ucDone
;
    call DecodeHexWord
    jc ucDone
;
    call DecodeHexByte
    jc ucDone
;
    mov ds:mon_c_vk_code,al
;
    call DecodeHexByte
    jc ucDone
;
    mov ds:mon_scan_code,al

ucDone:
    ret
UpdateCom  Endp

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
    mov ax,mon_data_sel
    mov ds,ax
    call UpdateKeyboard
    call UpdateMode
    call UpdateCom
;
    mov ah,ds:mon_scan_code
    or ah,ah
    stc
    jz get_key_done
;
    mov ds:mon_scan_code,0
    xor al,al
    xchg al,ds:mon_c_vk_code
    clc
        
get_key_done:
    pop ds
    ret
GetCrashKey      ENDP

code    ENDS

    END
