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
; DEBPROC.ASM
; Debug process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.def

.386p
.387

data    SEGMENT byte public 'DATA'

buf    DB 4096 DUP(?)

data    ENDS

code    SEGMENT byte use32 public 'CODE'

    extrn GetCpu:near
    extrn set_os_pos:near
    extrn get_os_pos:near
    extrn set0_sw:near
    extrn set1_sw:near
    extrn set2_sw:near
    extrn set3_sw:near
    extrn set4_sw:near
    extrn set5_sw:near
    extrn set6_sw:near
    extrn set7_sw:near
    extrn set8_sw:near
    extrn set9_sw:near
    extrn setA_sw:near
    extrn setB_sw:near
    extrn setC_sw:near
    extrn setD_sw:near
    extrn setE_sw:near
    extrn setF_sw:near
    extrn inc_sw:near
    extrn dec_sw:near

    extrn do_trace:near
    extrn do_pace:near
    extrn do_go:near
    extrn do_run:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   sw functions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

go_sw   PROC near
    DebugGo
    ret
go_sw   ENDP

trace_sw    PROC near
    DebugTrace
    ret
trace_sw    ENDP

pace_sw PROC near
    DebugPace
    ret
pace_sw ENDP

reg_sw  PROC near
    push es
    push edi
;
    mov ax,SEG data
    mov es,ax
    mov edi,OFFSET buf
    call GetCpu
;
    ClearText
    mov edi,OFFSET buf
    WriteAsciiz
    xor dx,dx
    xor cx,cx
    SetCursorPosition
;
    pop edi
    pop es
    ret
reg_sw  ENDP

next_sw PROC near
    DebugNext
    ret
next_sw ENDP

error_sw    PROC near
    ret
error_sw    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           debug_call_pr
;
;           DESCRIPTION:    Main debug entry
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
vs_4E   DD OFFSET next_sw
vs_4F   DD OFFSET error_sw
vs_50   DD OFFSET pace_sw
vs_51   DD OFFSET error_sw
vs_52   DD OFFSET reg_sw
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
vs_6B   DD OFFSET error_sw
vs_6C   DD OFFSET error_sw
vs_6D   DD OFFSET error_sw
vs_6E   DD OFFSET next_sw
vs_6F   DD OFFSET error_sw
vs_70   DD OFFSET pace_sw
vs_71   DD OFFSET error_sw
vs_72   DD OFFSET reg_sw
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

debug_call_pr   PROC near
    push ebx
;
    call set_os_pos
;
    cmp al,'r'
    jz wait_regs
    cmp al,'R'
    jnz no_wait_debug

wait_regs:
    push eax
    mov ax,10
    WaitMilliSec
    pop eax

no_wait_debug:
    cmp al,'n'
    je debug_do
;
    cmp al,'N'
    je debug_do
;
    push ax
    GetDebugThreadSel
    mov gs,ax
    or ax,ax
    pop ax
    jz debug_end

debug_do:
    movzx ebx,al
    shl ebx,2
    call dword ptr cs:[ebx].virt_sw_func_tab

debug_end:
    xor bx,bx
    mov es,bx
    mov fs,bx
    mov gs,bx
;
    call get_os_pos
;    
    pop ebx
    ret
debug_call_pr   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoFunc
;
;           DESCRIPTION:    Do function
;
;           PARAMETERS:     CX          X
;                           DX          Y
;                           AL          CHAR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoFunc  PROC near
    HideMouse
    shr cx,3
    shr dx,3
    mov dh,dl
    mov dl,cl
    call debug_call_pr
    mov al,'r'
    call debug_call_pr
    movzx cx,dl
    movzx dx,dh
    shl cx,3
    shl dx,3
    SetMousePosition
    ShowMouse
    ret
DoFunc  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleKeyboard
;
;           DESCRIPTION:    Keyboard
;
;           PARAMETERS:     EDI	Func    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleKeyboard  Proc near
    push edi
;
    mov eax,25
    WaitMilliSec
;
    PollKeyboard
    jc handle_key_end
;
    ReadKeyboard
    or al,al
    jz handle_key_special
;
    call near ptr cs:[edi]
    jmp handle_key_end

handle_key_special:  
    cmp ah,72
    jnz no_up_arrow

up_arrow:
    GetMousePosition
    sub dx,8
    SetMousePosition
    jmp handle_key_end

no_up_arrow:
    cmp ah,80
    jnz no_down_arrow

down_arrow:
    GetMousePosition
    add dx,8
    SetMousePosition
    jmp handle_key_end

no_down_arrow:
    cmp ah,75
    jnz no_left_arrow

left_arrow:
    GetMousePosition
    sub cx,8
    SetMousePosition
    jmp handle_key_end

no_left_arrow:
    cmp ah,77
    jnz handle_key_end

right_arrow:
    GetMousePosition
    add cx,8
    SetMousePosition

handle_key_end:
    pop edi
    ret
HandleKeyboard  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleMouse
;
;           DESCRIPTION:    Mouse handler
;
;           PARAMETERS:     EDI	Func    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleMouse     Proc near
    push edi
;
    GetLeftButton
    jc handle_not_left

left_button:
    GetLeftButtonPressPosition
    mov al,'+'
    call near ptr cs:[edi]

left_rel_loop:
    call HandleKeyboard
    GetLeftButton
    jnc left_rel_loop

handle_not_left:
    GetRightButton
    jc handle_mouse_done

right_button:
    GetRightButtonPressPosition
    mov al,'-'
    call near ptr cs:[edi]

right_rel_loop:
    call HandleKeyboard
    GetRightButton
    jnc right_rel_loop

handle_mouse_done:
    pop edi
    ret
HandleMouse     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Debug process
;
;           DESCRIPTION:    Debug process
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_name          DB 'Debug',0

do_func	DD OFFSET DoFunc

debug_process:
    sti
    mov ax,42h
    EnableFocus
;
    mov ax,250
    WaitMilliSec
;   
    mov ax,SEG data
    mov ds,ax
;     
    xor ax,ax
    xor bx,bx
    mov cx,639
    mov dx,199
    SetMouseWindow
    mov cx,8
    mov dx,8
    SetMouseMickey
;       
    ShowMouse

marker_loop:
    mov edi,OFFSET do_func
    call HandleKeyboard
    call HandleMouse
    GetMousePosition
    SetMousePosition
    jmp marker_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEBUG_TRACE
;
;           DESCRIPTION:    Trace one instruction in debugged thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_trace_name    DB 'Debug Trace',0

debug_trace     PROC far
    push gs
    push eax
;
    GetDebugThreadSel
    or ax,ax
    jz debug_trace_done
;    
    mov gs,eax
    call do_trace

debug_trace_done:
    pop eax
    pop gs
    ret
debug_trace	Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEBUG_PACE
;
;           DESCRIPTION:    Pace one instruction in debugged thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_pace_name    DB 'Debug Pace',0

debug_pace     PROC far
    push gs
    push eax
;
    GetDebugThreadSel
    or ax,ax
    jz debug_pace_done
;    
    mov gs,eax
    call do_pace

debug_pace_done:
    pop eax
    pop gs
    ret
debug_pace	Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEBUG_GO
;
;           DESCRIPTION:    Run currently debugged thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_go_name   DB 'Debug Go',0

debug_go    PROC far
    push gs
    push eax
;
    GetDebugThreadSel
    or ax,ax
    jz debug_go_done
;    
    mov gs,eax
    call do_go

debug_go_done:
    pop eax
    pop gs
    ret
debug_go	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DebugRun
;
;           DESCRIPTION:    Run currently debugged thread with current DR-settings
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_run_name   DB 'Debug Run',0

debug_run    PROC far
    push gs
    push eax
;
    GetDebugThreadSel
    or ax,ax
    jz debug_run_done
;    
    mov gs,eax
    call do_run

debug_run_done:
    pop eax
    pop gs
    ret
debug_run    ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_DEBUG_THREAD_SEL
;
;           DESCRIPTION:    Get currently debugged thread selector
;
;           PARAMETERS:         AX          DEBUG THREAD OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_thread_sel_name   DB 'Get Debug Thread Sel', 0

get_debug_thread_sel    PROC far
    push ds
    push es
    push cx
    push dx
    push si
;
    mov ax,system_data_sel
    mov ds,ax
    mov cx,ds:debug_thread
    mov si,OFFSET debug_list
    mov ax,[si]
    or ax,ax
    jz get_debug_sel_done

    mov dx,ax

get_debug_sel_try_next:
    cmp ax,cx
    je get_debug_sel_default
    mov es,ax
    mov ax,es:p_next
    cmp dx,ax
    je get_debug_sel_new
    jmp get_debug_sel_try_next

get_debug_sel_new:
    mov cx,[si]

get_debug_sel_default:
    mov ds:debug_thread,cx
    mov ax,cx

get_debug_sel_done:
    pop si
    pop dx
    pop cx
    pop es
    pop ds
    ret
get_debug_thread_sel    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_DEBUG_THREAD
;
;           DESCRIPTION:    Get currently debugged thread ID
;
;           PARAMETERS:     AX         DEBUG THREAD ID OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_thread_name   DB 'Get Debug Thread', 0

get_debug_thread    PROC far
    push es
    GetDebugThreadSel
    or ax,ax
    jz get_debug_done
;
    mov es,ax
    mov ax,es:p_id

get_debug_done:
    pop es
    ret
get_debug_thread    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEBUG_NEXT
;
;           DESCRIPTION:    Select next thread as currently debugged
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_next_name DB 'Debug Next',0

debug_next      PROC far
    push ds
    push es
    push ax
    push si
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov ax,[si]
    or ax,ax
    je debug_next_end
    mov es,ax
    mov es,es:p_next
    mov [si],es
    mov ds:debug_thread,es
debug_next_end:
    pop si
    pop ax
    pop es
    pop ds
    ret
debug_next      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ConvBreakThread
;
;           DESCRIPTION:    Convert thread into selector
;
;           PARAMETERS:     BX          Thread ID
;
;           RETURNS:        ES          Thread selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvBreakThread PROC near
    push ax
    push bx
;    
    or bx,bx
    jnz cbtDo
;
    GetThread
    mov es,ax
    clc
    jmp cbtDone

cbtDo:
    ThreadToSel
    jc cbtDone
;    
    mov es,bx

cbtDone:
    pop bx
    pop ax
    ret
ConvBreakThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           BreakToLinear
;
;           DESCRIPTION:    Convert break address to linear address
;
;           PARAMETERS:     SI:(E)DI        Address
;
;           RETURNS:        EDX             Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BreakToLinear PROC near
    push bx
    push ecx
;
    mov bx,si
    GetSelectorBaseSize
    jc btlDone
;
    or ecx,ecx
    jz btlAdd
;    
    cmp edi,ecx
    jae btlFail

btlAdd:
    add edx,edi
    clc
    jmp btlDone

btlFail:
    stc

btlDone:
    pop ecx
    pop bx    
    ret
BreakToLinear ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddBreak
;
;           DESCRIPTION:    Add a local breakpoint
;
;           PARAMETERS:     EDX     Linear address
;                           ES      Thread sel
;                           AL      Debug register
;                           AH      Type coding
;                           CL      Size of region
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

abSizeTab:
ast00  DB 0
ast01  DB 0
ast02  DB 1
ast03  DB 3
ast04  DB 3
ast05  DB 2
ast06  DB 2
ast07  DB 2

AddBreak PROC near
    push bx
    push cx
    push edx
    push esi
;
    cmp al,4
    jae abFail
;   
    mov ch,1
    mov esi,edx

abFixSizeLoop:
    test esi,1
    jnz abFixSizeFix
;
    cmp ch,cl
    jae abFixSizeOk
;
    shl ch,1
    shr esi,1
    jmp abFixSizeLoop

abFixSizeFix:
    mov cl,ch

abFixSizeOk:
    movzx bx,al
    shl bx,3
    add bx,OFFSET p_dr0
    mov es:[bx],edx
    mov word ptr es:[bx+4],0
;
    cmp cl,7
    jbe abSizeOk
;
    mov cl,7

abSizeOk:
    movzx bx,cl
;    
    mov esi,0Fh
    mov cl,al
    shl cl,2
    add cl,16
    shl esi,cl
;    
    mov si,3
    mov cl,al
    shl cl,1
    shl si,cl
;    
    not esi
;    
    push eax
    mov cl,al
    shl cl,2
    add cl,16
    movzx eax,ah
    shl eax,cl
    movzx edx,byte ptr cs:[bx].abSizeTab
    add cl,2
    shl edx,cl
    or edx,eax
    pop eax
;
    mov cl,al
    shl cl,1
    mov dx,1
    shl dx,cl
    and dword ptr es:p_dr7,esi
    or dword ptr es:p_dr7,edx
    or es:p_flags,THREAD_FLAG_BP
    clc
    jmp abDone

abFail:
    stc

abDone:   
    pop esi
    pop edx
    pop cx
    pop bx
    ret
AddBreak ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RemoveBreak
;
;           DESCRIPTION:    Remove a local breakpoint
;
;           PARAMETERS:     ES      Thread sel
;                           AL      Debug register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveBreak PROC near
    push cx
    push edx
;
    cmp al,4
    jae rbFail
;    
    mov edx,0Fh
    mov cl,al
    shl cl,2
    add cl,16
    shl edx,cl
;    
    mov dx,3
    mov cl,al
    shl cl,1
    shl dx,cl
;    
    not edx
    and dword ptr es:p_dr7,edx
    clc
    jmp rbDone

rbFail:
    stc

rbDone:   
    pop edx
    pop cx
    ret
RemoveBreak ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetCodeBreak
;
;           DESCRIPTION:    Set a code breakpoint
;
;           PARAMETERS:     BX              Thread ID
;                           SI:(E)DI        Address
;                           AL              Debug register (0..3)    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_code_break_name DB 'Set Code Break',0

set_code_break PROC near
    push es
    push ax
    push bx
    push cx
    push edx
;    
    call BreakToLinear
    jc scbDone
;
    call ConvBreakThread
    jc scbDone
;
    xor ah,ah
    mov cl,1
    call AddBreak

scbDone:
    pop edx
    pop cx
    pop bx
    pop ax
    pop es
    ret
set_code_break ENDP

set_code_break16  Proc far
    push edi
    movzx edi,di
    call set_code_break
    pop edi
    ret
set_code_break16  Endp

set_code_break32  Proc far
    call set_code_break
    ret
set_code_break32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetReadDataBreak
;
;           DESCRIPTION:    Set a read-data breakpoint
;
;           PARAMETERS:     BX              Thread ID
;                           SI:(E)DI        Address
;                           AL              Debug register (1..3)    
;                           CL              Size of region (1,2,4 or 8)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_read_data_break_name DB 'Set Read Data Break',0

set_read_data_break PROC near
    push es
    push ax
    push bx
    push edx
;    
    call BreakToLinear
    jc srdDone
;
    call ConvBreakThread
    jc srdDone
;
    mov ah,3
    call AddBreak

srdDone:
    pop edx
    pop bx
    pop ax
    pop es
    ret
set_read_data_break ENDP

set_read_data_break16  Proc far
    push edi
    movzx edi,di
    call set_read_data_break
    pop edi
    ret
set_read_data_break16  Endp

set_read_data_break32  Proc far
    call set_read_data_break
    ret
set_read_data_break32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetWriteDataBreak
;
;           DESCRIPTION:    Set a write-data breakpoint
;
;           PARAMETERS:     BX              Thread ID
;                           SI:(E)DI        Address
;                           AL              Debug register (1..3)    
;                           CL              Size of region (1,2,4 or 8)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_write_data_break_name DB 'Set Write Data Break',0

set_write_data_break PROC near
    push es
    push ax
    push bx
    push edx
;    
    call BreakToLinear
    jc swdDone
;
    call ConvBreakThread
    jc swdDone
;
    mov ah,1
    call AddBreak

swdDone:
    pop edx
    pop bx
    pop ax
    pop es
    ret
set_write_data_break ENDP

set_write_data_break16  Proc far
    push edi
    movzx edi,di
    call set_write_data_break
    pop edi
    ret
set_write_data_break16  Endp

set_write_data_break32  Proc far
    call set_write_data_break
    ret
set_write_data_break32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearBreak
;
;           DESCRIPTION:    Clear a breakpoint
;
;           PARAMETERS:     BX              Thread ID
;                           AL              Debug register (0..3)    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_break_name DB 'Clear Break',0

clear_break PROC far
    push es
    push ax
    push bx
;
    call ConvBreakThread
    jc cbDone
;    
    call RemoveBreak

cbDone:
    pop bx
    pop ax
    pop es
    ret
clear_break ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_local_debug
;
;           DESCRIPTION:    Create local debugger process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_local_debug

init_local_debug      PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET debug_process
    mov edi,OFFSET debug_name
    mov ecx,stack0_size
    mov ax,26
    mov bx,1
    CreateProcess
;
    mov esi,OFFSET get_debug_thread_sel
    mov edi,OFFSET get_debug_thread_sel_name
    xor cl,cl
    mov ax,get_debug_thread_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET debug_trace
    mov edi,OFFSET debug_trace_name
    xor dx,dx
    mov ax,debug_trace_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET debug_pace
    mov edi,OFFSET debug_pace_name
    xor dx,dx
    mov ax,debug_pace_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET debug_go
    mov edi,OFFSET debug_go_name
    xor dx,dx
    mov ax,debug_go_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET debug_run
    mov edi,OFFSET debug_run_name
    xor dx,dx
    mov ax,debug_run_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_debug_thread
    mov edi,OFFSET get_debug_thread_name
    xor dx,dx
    mov ax,get_debug_thread_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET debug_next
    mov edi,OFFSET debug_next_name
    xor dx,dx
    mov ax,debug_next_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET set_code_break16
    mov esi,OFFSET set_code_break32
    mov edi,OFFSET set_code_break_name
    mov dx,virt_es_in
    mov ax,set_code_break_nr
    RegisterUserGate
;
    mov ebx,OFFSET set_read_data_break16
    mov esi,OFFSET set_read_data_break32
    mov edi,OFFSET set_read_data_break_name
    mov dx,virt_es_in
    mov ax,set_read_data_break_nr
    RegisterUserGate
;
    mov ebx,OFFSET set_write_data_break16
    mov esi,OFFSET set_write_data_break32
    mov edi,OFFSET set_write_data_break_name
    mov dx,virt_es_in
    mov ax,set_write_data_break_nr
    RegisterUserGate
;
    mov esi,OFFSET clear_break
    mov edi,OFFSET clear_break_name
    xor dx,dx
    mov ax,clear_break_nr
    RegisterBimodalUserGate
    ret
init_local_debug      ENDP
    
code    ENDS

    END
