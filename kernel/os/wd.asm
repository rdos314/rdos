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
; WD.ASM
; Software watchdog support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def
INCLUDE ..\..\kernel\os\state.def
INCLUDE ..\..\kernel\os\protseg.def

FAULT_SIGN  EQU 0AC92BE63h

fault_sector_seg STRUC

fss_sign        DD ?
fss_state       action_state_struc <>
fss_tss         DD ?

fault_sector_seg ENDS


data    SEGMENT byte public 'DATA'

wd_tics             DD ?

debug_tics          DD ?
debug_timeout       DD ?,?
debug_active        DB ?

fault_disc          DB ?
fault_start_sector  DD ?
fault_sectors       DD ?

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckDebugger
;
;           DESCRIPTION:    Check debugger
;
;           RETURNS:        NC       Debugger active and ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckDebugger Proc near
    push ds
    push eax
    push edx
;
    mov ax,SEG data
    mov ds,ax
    mov al,ds:debug_active
    or al,al
    stc
    jz cdDone
;
    GetSystemTime
    sub eax,ds:debug_timeout
    sbb edx,ds:debug_timeout+4
    cmc

cdDone:
    pop edx
    pop eax
    pop ds
    ret
CheckDebugger Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WdTimeout
;
;           DESCRIPTION:    Watchdog timeout - do reset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WdTimeout:
    SoftReset
    jmp WdTimeout

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartWatchdog
;
;           DESCRIPTION:    Start watchdog
;
;       PARAMETERS:     EAX      Timeout in milliseconds 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_watchdog_name DB 'Start Watchdog', 0

start_watchdog   Proc far
    push es
    pushad
;   
    mov bx,SEG data
    mov es,bx
    mov edx,1193
    mul edx
    mov es:wd_tics,eax
;       
    GetSystemTime
    add eax,es:wd_tics
    adc edx,0
;
    mov bx,cs
    mov es,bx
    mov edi,OFFSET WdTimeout
    mov bx,SEG data
    StartTimer
;
    popad
    pop es      
    retf32
start_watchdog   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           ReadFlatAppDword
;
;   DESCRIPTION:    Read flat app dword
;
;   PARAMETERS:     DS  Thread
;                   ESI Offset
;
;   RETURNS:        NC
;                       EAX Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadFlatAppDword    Proc near
    push ebx
    push ecx
    push edx
    push esi
;
    add esi,3
    xor ecx,ecx
    mov edx,flat_data_sel
    mov bx,ds
    ReadThreadSelector
    jc rfadDone
;
    dec esi
    mov cl,al
    ReadThreadSelector
    jc rfadDone
;
    shl ecx,8
    mov cl,al
;
    dec esi
    mov cl,al
    ReadThreadSelector
    jc rfadDone
;
    shl ecx,8
    mov cl,al
;
    dec esi
    mov cl,al
    ReadThreadSelector
    jc rfadDone
;
    shl ecx,8
    mov cl,al
    mov eax,ecx
    clc

rfadDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
ReadFlatAppDword    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           ProbeFlatAppCode
;
;   DESCRIPTION:    Proble flat app code
;
;   PARAMETERS:     DS  Thread
;                   ESI Offset
;
;   RETURNS:        NC   OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProbeFlatAppCode    Proc near
    push eax
    push ebx
    push edx
;
    mov edx,flat_data_sel
    mov bx,ds
    ReadThreadSelector
    jc pfacDone
;    
    GetThreadSelectorPage
    jc pfacDone
;
    test al,2
    jz pfacDone
;
    stc

pfacDone:
    pop edx
    pop ebx
    pop eax
    ret
ProbeFlatAppCode    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           KickWatchdog
;
;           DESCRIPTION:    Kick watchdog
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kick_watchdog_name DB 'Kick Watchdog', 0

kick_watchdog   Proc far
    push ds
    push es
    push fs
    pushad
;    
    GetDebugThreadSel
    or ax,ax
    jz kw_kick
;
    call CheckDebugger
    jnc kw_kick
;
    mov bp,ax
    mov bx,SEG data
    mov fs,bx
    mov ecx,fs:fault_sectors
    or ecx,ecx
    jz kw_done
;    
    mov fs:fault_sectors,0
    mov edx,fs:fault_start_sector
;
    mov bx,fault_sector_sel
    mov es,bx
    GetDebugThreadSel

kw_save_loop:
    mov ds,ax
    mov bx,ds:p_id
    mov di,OFFSET fss_tss
    GetThreadTss
;
    mov es:fss_sign,FAULT_SIGN
    mov ax,ds:p_id
    mov es:fss_state.ast_id,ax
;
    push cx
    mov si,OFFSET thread_name
    mov cx,32
    mov di,OFFSET fss_state.ast_name
    rep movsb
;
    mov cx,32
    mov di,OFFSET fss_state.ast_list
    mov al,' '
    rep stosb   
    pop cx
;    
    push cx
    mov si,OFFSET p_action_text
    mov cx,32
    mov di,OFFSET ast_action
    rep movsb
    pop cx
;       
    mov eax,ds:p_msb_tics
    mov es:fss_state.ast_time,eax
    mov eax,ds:p_lsb_tics
    mov es:fss_state.ast_time+4,eax
;
    mov dword ptr es:fss_state.ast_pos.sep_offs,0
    mov dword ptr es:fss_state.ast_pos.sep_offs+4,0
    mov es:fss_state.ast_pos.sep_sel,0
    mov es:fss_state.ast_count,0
;
    push fs
    push ecx
    push edx
;        
    test word ptr ds:p_rflags+2,2
    jnz kw_user_done
;
    mov ax,ds:p_cs
    cmp ax,flat_code_sel
    jne kw_not_app
;   
    mov edx,OFFSET fss_state.ast_user
    mov eax,dword ptr ds:p_rbp    
    jmp kw_user_loop

kw_not_app:    
    test ax,7
    jnz kw_user_done
;
    mov ax,ds:p_ss
    mov fs,ax
    mov ecx,dword ptr ds:p_rsp
    cmp ecx,stack0_size
    jae kw_user_done
;
    mov ecx,stack0_size
    mov eax,fs:[ecx-4]
    cmp eax,flat_data_sel    
    jne kw_user_done
;    
    mov eax,fs:[ecx-12]
    cmp eax,flat_code_sel
    jne kw_user_done
;
    mov edx,OFFSET fss_state.ast_user
    mov eax,fs:[ecx-12]
    mov es:[edx].sep_sel,ax
    mov eax,fs:[ecx-16]
    mov dword ptr es:[edx].sep_offs,eax
    mov dword ptr es:[edx].sep_offs+4,0
    add edx,SIZE state_ep
    inc es:fss_state.ast_count
;
    mov esi,fs:[ecx-8]
    call ReadFlatAppDword
    jc kw_user_done

kw_user_loop:
    mov esi,eax
    push esi
    add esi,24
    call ReadFlatAppDword
    pop esi
    jc kw_user_done
;
    push esi
    mov esi,eax
    call ProbeFlatAppCode
    pop esi
    jnc kw_user_save
;    
    push esi
    add esi,20
    call ReadFlatAppDword
    pop esi
    jc kw_user_done
;
    push esi
    mov esi,eax
    call ProbeFlatAppCode
    pop esi
    jnc kw_user_save
;
    xor eax,eax
    
kw_user_save:    
    mov es:[edx].sep_sel,flat_code_sel
    mov dword ptr es:[edx].sep_offs,eax
    mov dword ptr es:[edx].sep_offs+4,0
    add edx,SIZE state_ep
    mov ax,es:fss_state.ast_count
    inc ax
    mov es:fss_state.ast_count,ax
    cmp ax,64
    jae kw_user_done
;
    call ReadFlatAppDword
    or eax,eax
    jnz kw_user_loop
        
kw_user_done:    
    mov ax,es:fss_state.ast_count
    cmp ax,2
    jb kw_user_ok
;
    sub edx,SIZE state_ep
    mov eax,dword ptr es:[edx].sep_offs
    or eax,dword ptr es:[edx].sep_offs+4
    jnz kw_user_ok
;
    dec es:fss_state.ast_count        

kw_user_ok:    
    pop edx
    pop ecx
    pop fs
;
    push cx
    mov al,fs:fault_disc
    mov cx,512
    xor di,di       
    WriteShortDisc
    inc edx
;    
    mov al,fs:fault_disc
    mov cx,512
    mov di,200h
    WriteShortDisc
    inc edx
;    
    pop cx
;
    DebugNext    
    GetDebugThreadSel
    cmp ax,bp
    je kw_done
;
    sub ecx,2
    jnz kw_save_loop    
;
    jmp kw_done    
    
kw_kick:
    GetSystemTime
    mov bx,SEG data
    mov es,bx
    add eax,es:wd_tics
    adc edx,0
;
    mov bx,cs
    mov es,bx
    mov edi,OFFSET WdTimeout
    mov bx,SEG data
    StopTimer
    StartTimer

kw_done:
    popad       
    pop fs
    pop es
    pop ds
    retf32
kick_watchdog   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StopWatchdog
;
;           DESCRIPTION:    Stop watchdog
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_watchdog_name DB 'Stop Watchdog', 0

stop_watchdog   Proc far
    push es
    push bx    
;    
    mov bx,SEG data
    mov es,bx
    StopTimer
    mov es:wd_tics,0    
;
    pop bx
    pop es
    retf32
stop_watchdog   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetWatchdogTics
;
;           DESCRIPTION:    Get watchdog tics
;
;       RETURNS:    EAX == 0 not running
;               EAX != 0, EAX tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_watchdog_tics_name DB 'Get Watchdog Tics', 0

get_watchdog_tics   Proc far
    push es
    push bx    
;    
    mov bx,SEG data
    mov es,bx
    mov eax,es:wd_tics
;
    pop bx
    pop es
    retf32
get_watchdog_tics   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartDebugger
;
;           DESCRIPTION:    Start debugger
;
;       PARAMETERS:     EAX      Timeout in milliseconds 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_debugger_name DB 'Start Debugger', 0

start_debugger   Proc far
    push es
    pushad
;   
    mov bx,SEG data
    mov es,bx
    mov edx,1193
    mul edx
    mov es:debug_tics,eax
;       
    GetSystemTime
    add eax,es:debug_tics
    adc edx,0
    mov es:debug_timeout,eax
    mov es:debug_timeout+4,edx
    mov es:debug_active,1
;
    popad
    pop es      
    retf32
start_debugger   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           KickDebugger
;
;           DESCRIPTION:    Kick debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kick_debugger_name DB 'Kick Debugger', 0

kick_debugger   Proc far
    push es
    pushad
;   
    mov bx,SEG data
    mov es,bx
;       
    GetSystemTime
    add eax,es:debug_tics
    adc edx,0
    mov es:debug_timeout,eax
    mov es:debug_timeout+4,edx
;
    popad
    pop es      
    retf32
kick_debugger   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StopDebugger
;
;           DESCRIPTION:    Stop debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_debugger_name DB 'Stop Debugger', 0

stop_debugger   Proc far
    push es
    push ebx
;   
    mov bx,SEG data
    mov es,bx
    mov es:debug_active,0
;
    pop ebx
    pop es      
    retf32
stop_debugger   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DefineFaultSave
;
;           DESCRIPTION:    Define fault save position on disc
;
;       PARAMETERS:     AL      Disc #
;               EDX     Start sector #
;               ECX     Number of available sectors
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define_fault_save_name  DB 'Define Fault Save',0

define_fault_save       PROC far
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
    mov ds:fault_disc,al
    mov ds:fault_start_sector,edx
    mov ds:fault_sectors,ecx
;    
    pop bx
    pop ds
    retf32
define_fault_save   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClearFaultSave
;
;           DESCRIPTION:    Clear fault save data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_fault_save_name   DB 'Clear Fault Save',0

clear_fault_save    PROC far
    push ds
    push es
    pushad
;    
    mov ax,SEG data
    mov ds,ax
    mov ax,fault_sector_sel
    mov es,ax
    xor di,di
    mov cx,512
    xor al,al
    rep stosb
;
    mov ecx,ds:fault_sectors
    mov edx,ds:fault_start_sector

cfsLoop:
    or ecx,ecx
    jz cfsDone
;
    push cx
    mov al,ds:fault_disc
    mov cx,512
    xor di,di
    WriteShortDisc
    pop cx
;
    inc edx
    dec ecx
    jmp cfsLoop 

cfsDone:   
    popad
    pop es
    pop ds
    retf32
clear_fault_save   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetFaultThreadState
;
;           DESCRIPTION:    Get fault thread state
;
;       PARAMETERS:     AX      Thread #
;               ES:E(DI)    State buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_fault_thread_state_name     DB 'Get Fault Thread State',0

get_fault_thread_state  PROC near
    push ds
    push es
    push fs
    pushad
;   
    mov bp,es
    mov fs,bp
    mov ebp,edi
;    
    movzx eax,ax
    mov bx,SEG data
    mov ds,bx
    mov bx,fault_sector_sel
    mov es,bx
;
    mov ecx,ds:fault_sectors
    cmp eax,ecx
    jae gfsFail
;
    mov edx,ds:fault_start_sector
    add edx,eax
    add edx,eax
;    
    mov al,ds:fault_disc
    mov cx,512
    xor di,di
    ReadShortDisc
;    
    mov al,ds:fault_disc
    mov cx,512
    mov di,200h
    inc edx
    ReadShortDisc
;    
    mov eax,es:fss_sign
    cmp eax,FAULT_SIGN
    jne gfsFail
;
    mov ax,es
    mov ds,ax
    mov esi,OFFSET fss_state
    mov ax,fs
    mov es,ax
    mov edi,ebp
    mov ecx,SIZE action_state_struc
    rep movs byte ptr es:[edi],ds:[esi]
    clc
    jmp gfsEnd    
    
gfsFail:
    stc

gfsEnd:
    popad
    pop fs
    pop es
    pop ds
    ret
get_fault_thread_state   Endp

get_fault_thread_state16    Proc far
    push edi
    movzx edi,di
    call get_fault_thread_state
    pop edi
    retf32
get_fault_thread_state16    Endp

get_fault_thread_state32    Proc far
    call get_fault_thread_state
    Retf32
get_fault_thread_state32    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetFaultThreadTss
;
;           DESCRIPTION:    Get fault thread tss
;
;       PARAMETERS:     AX      Thread #
;               ES:E(DI)    Tss buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_fault_thread_tss_name       DB 'Get Fault Thread Tss',0

get_fault_thread_tss    PROC near
    push ds
    push es
    push fs
    pushad
;   
    mov bp,es
    mov fs,bp
    mov ebp,edi
;    
    movzx eax,ax
    mov bx,SEG data
    mov ds,bx
    mov bx,fault_sector_sel
    mov es,bx
;
    mov ecx,ds:fault_sectors
    cmp eax,ecx
    jae gftFail
;
    mov edx,ds:fault_start_sector
    add edx,eax
    add edx,eax
;    
    mov al,ds:fault_disc
    mov cx,512
    xor di,di
    ReadShortDisc
;    
    inc edx
    mov al,ds:fault_disc
    mov cx,512
    mov di,200h
    ReadShortDisc
;    
    mov eax,es:fss_sign
    cmp eax,FAULT_SIGN
    jne gftFail
;
    mov ax,es
    mov ds,ax
    mov esi,OFFSET fss_tss
    mov ax,fs
    mov es,ax
    mov edi,ebp
    mov ecx,SIZE user_tss_struc
    rep movs byte ptr es:[edi],ds:[esi]
    clc
    jmp gftEnd    
    
gftFail:
    stc

gftEnd:
    popad
    pop fs
    pop es
    pop ds
    ret
get_fault_thread_tss   Endp

get_fault_thread_tss16  Proc far
    push edi
    movzx edi,di
    call get_fault_thread_tss
    pop edi
    retf32
get_fault_thread_tss16  Endp

get_fault_thread_tss32  Proc far
    call get_fault_thread_tss
    Retf32
get_fault_thread_tss32  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    Initialize module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov bx,SEG data
    mov es,bx
    mov es:wd_tics,0
    mov es:fault_sectors,0
    mov es:debug_active,0
;
    mov eax,1024
    mov bx,fault_sector_sel
    AllocateFixedSystemMem
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET start_watchdog
    mov edi,OFFSET start_watchdog_name
    xor dx,dx
    mov ax,start_watchdog_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET kick_watchdog
    mov edi,OFFSET kick_watchdog_name
    xor dx,dx
    mov ax,kick_watchdog_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET stop_watchdog
    mov edi,OFFSET stop_watchdog_name
    xor dx,dx
    mov ax,stop_watchdog_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_watchdog_tics
    mov edi,OFFSET get_watchdog_tics_name
    xor dx,dx
    mov ax,get_watchdog_tics_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET start_debugger
    mov edi,OFFSET start_debugger_name
    xor dx,dx
    mov ax,start_debugger_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET stop_debugger
    mov edi,OFFSET stop_debugger_name
    xor dx,dx
    mov ax,stop_debugger_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET kick_debugger
    mov edi,OFFSET kick_debugger_name
    xor dx,dx
    mov ax,kick_debugger_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET define_fault_save
    mov edi,OFFSET define_fault_save_name
    xor dx,dx
    mov ax,define_fault_save_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET clear_fault_save
    mov edi,OFFSET clear_fault_save_name
    xor dx,dx
    mov ax,clear_fault_save_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_fault_thread_state16
    mov esi,OFFSET get_fault_thread_state32
    mov edi,OFFSET get_fault_thread_state_name
    mov dx,virt_es_in
    mov ax,get_fault_thread_state_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_fault_thread_tss16
    mov esi,OFFSET get_fault_thread_tss32
    mov edi,OFFSET get_fault_thread_tss_name
    mov dx,virt_es_in
    mov ax,get_fault_thread_tss_nr
    RegisterUserGate
    ret
init    Endp

code    ENDS

    END init
