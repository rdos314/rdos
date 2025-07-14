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
; LON.ASM
; Lonworks (shortstack) module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE protseg.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE system.inc
INCLUDE ..\handle.inc
include ..\wait.inc
INCLUDE lon.inc

MAX_MODULES = 32

lon_handle_seg  STRUC

lon_handle_base  handle_header <>

lon_handle_sel   DW ?

lon_handle_seg  ENDS

lon_wait_header STRUC

lon_obj         wait_obj_header <>
lon_sel         DW ?

lon_wait_header ENDS

capture_block   STRUC

cb_prev     DD ?
cb_next     DD ?

cb_time     DD ?,?
cb_src      DB ?
cb_len      DB ?
cb_data     DB 118 DUP(?)

capture_block   ENDS


data    SEGMENT byte public 'DATA'

capture_section     section_typ <>
capture_handle      DW ?
capture_thread      DW ?
capture_list        DD ?

lon_module_count    DW ?
lon_module_arr      DW MAX_MODULES DUP(?)

data    ENDS

code    SEGMENT byte public use16 'CODE'
    
    .386

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendOne
;
;       description:    Send one msg
;
;       PARAMETERS:     DS              Lon dev
;                       ES:EDI          Buffer
;                       ECX             Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendOne  Proc near
    push es
    push fs
    push bx
    push ecx
    push esi
    push edi
;
    push ds
    push ax
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:capture_section
    mov ax,ds:capture_thread
    or ax,ax
    jz soLeave
;    
    push es
    pushad
;    
    mov ax,es
    mov ds,ax
    mov esi,edi
    mov bx,flat_sel
    mov es,bx
    mov eax,SIZE capture_block
    AllocateSmallLinear
    mov edi,edx
;    
    GetTime
    mov es:[edi].cb_time+4,edx
    mov es:[edi].cb_time,eax
    mov es:[edi].cb_src,'T'
    mov es:[edi].cb_len,cl
    cmp ecx,118
    jb soSizeOk
;
    mov ecx,118

soSizeOk:    
    mov edx,edi
    add edi,OFFSET cb_data
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov bx,SEG data
    mov ds,bx
;
    mov eax,ds:capture_list
    or eax,eax
    jne soQueue

soEmpty:
    mov es:[edx].cb_prev,edx
    mov es:[edx].cb_next,edx
    mov ds:capture_list,edx
    jmp soSignal

soQueue:
    mov ebx,es:[eax].cb_prev
    mov es:[eax].cb_prev,edx
    mov es:[ebx].cb_next,edx
    mov es:[edx].cb_prev,ebx
    mov es:[edx].cb_next,eax    

soSignal:
    mov bx,ds:capture_thread
    Signal
;
    popad
    pop es

soLeave:
    LeaveSection ds:capture_section
;    
    pop ax
    pop ds    
;
    mov fs,ds:lon_send_buf
    mov ax,ds:lon_send_count
    cmp ax,ds:lon_send_size
    je soDone
;    
    push ds
;
    push es
    mov eax,ecx
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax    
    pop ds
;
    mov esi,edi
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]
;
    pop ds    
    EnterSection ds:lon_section
;     
    mov bx,ds:lon_send_tail
    mov fs:[bx],es
    add bx,2
    mov cx,ds:lon_send_size
    shl cx,1
    cmp bx,cx
    jnz soNoWrap

    xor bx,bx

soNoWrap:
    mov ds:lon_send_tail,bx
;    
    mov cx,ds:lon_send_count
    or cx,cx
    jnz soStarted
;
    inc cx
    mov ds:lon_send_count,cx
    xor bx,bx
    mov es,bx
    LeaveSection ds:lon_section
;    
    call fword ptr ds:lon_start_send_proc
    jmp soDone
    
soStarted:
    inc cx
    mov ds:lon_send_count,cx
    xor bx,bx
    mov es,bx
    LeaveSection ds:lon_section

soDone:
    pop edi
    pop esi
    pop ecx
    pop bx
    pop fs
    pop es
    ret
SendOne Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendLonModuleMsg
;
;       description:    Send message to lon module
;
;       PARAMETERS:     BX              Lon handle
;                       ES:(E)DI        Buffer
;                       (E)CX           Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_lon_module_msg_name DB 'Send Lon Module Msg',0

send_lon_module_msg16       Proc far
    push ds
    push eax
    push ebx
    push edi
;
    mov ax,LON_HANDLE
    DerefHandle
    jc send_lon_msg_done16
;
    movzx ecx,cx
    movzx edi,di
    mov ds,[ebx].lon_handle_sel
    call SendOne

send_lon_msg_done16:
    pop edi
    pop ebx
    pop eax
    pop ds
    retf32
send_lon_module_msg16       Endp

send_lon_module_msg32       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,LON_HANDLE
    DerefHandle
    jc send_lon_done32
;
    mov ds,[ebx].lon_handle_sel
    call SendOne

send_lon_done32:
    pop ebx
    pop eax
    pop ds
    retf32
send_lon_module_msg32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HasLonModuleMsg
;
;       description:    Check if message is available
;
;       PARAMETERS:     BX              Lon handle
;
;       RETURNS:        CY              No msg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_lon_module_msg_name DB 'Has Lon Module Msg?',0

has_lon_module_msg       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,LON_HANDLE
    DerefHandle
    jc hlmDone
;
    mov ds,[ebx].lon_handle_sel
    mov ax,ds:lon_rec_count
    or ax,ax
    stc
    jz hlmDone
;
    clc

hlmDone:
    pop ebx
    pop eax
    pop ds
    retf32
has_lon_module_msg       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReceiveOne
;
;       description:    Receive one msg
;
;       PARAMETERS:     DS              Lon dev
;                       ES:EDI          Buffer
;                       ECX             Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveOne  Proc near
    push fs
    push bx
;    
    EnterSection ds:lon_section
    mov cx,ds:lon_rec_count
    or cx,cx
    jz roFail
;
    mov fs,ds:lon_rec_buf
    mov bx,ds:lon_rec_head
    xor ax,ax
    xchg ax,fs:[bx]
    dec cx
    mov ds:lon_rec_count,cx
;
    add bx,2
    mov cx,ds:lon_rec_size
    shl cx,1
    cmp bx,cx
    jnz roNoWrap
    xor bx,bx
    
roNoWrap:
    mov ds:lon_rec_head,bx
    clc
    jmp roLeave

roFail:
    stc

roLeave:
    LeaveSection ds:lon_section
    jc roDone
;
    mov bx,ax
    GetSelectorBaseSize
    jc roDone
;
    movzx ecx,cx
    push ds
    push es
    push ecx
    push esi
    push edi
;    
    mov ds,bx
    xor esi,esi
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov es,bx
    xor cx,cx
    mov ds,cx
    FreeMem
;
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds    
                
roDone:
    pop bx
    pop fs
    ret
ReceiveOne  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReceiveLonModuleMsg
;
;       description:    Receive message from lon module
;
;       PARAMETERS:     BX              Lon handle
;                       ES:(E)DI        Buffer
;
;       RETURNS:        ECX             Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

receive_lon_module_msg_name DB 'Receive Lon Module Msg',0

receive_lon_module_msg16       Proc far
    push ds
    push eax
    push ebx
    push edi
;
    mov ax,LON_HANDLE
    DerefHandle
    jc rec_lon_msg_done16
;
    movzx edi,di
    mov ds,[ebx].lon_handle_sel
    call ReceiveOne

rec_lon_msg_done16:
    pop edi
    pop ebx
    pop eax
    pop ds
    retf32
receive_lon_module_msg16       Endp

receive_lon_module_msg32       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,LON_HANDLE
    DerefHandle
    jc rec_lon_done32
;
    mov ds,[ebx].lon_handle_sel
    call ReceiveOne

rec_lon_done32:
    pop ebx
    pop eax
    pop ds
    retf32
receive_lon_module_msg32       Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForLon
;
;           DESCRIPTION:    Start a wait for lon msg
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_lon PROC far
    push ds
    push ax
    push bx
;
    mov ds,es:lon_sel
    mov ds:lon_avail_obj,es
;
    mov ax,ds:lon_rec_count
    or ax,ax
    jz start_wait_for_done
;
    mov ds:lon_avail_obj,0
    SignalWait

start_wait_for_done:
    pop bx
    pop ax
    pop ds
    retf32
start_wait_for_lon Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForLon
;
;           DESCRIPTION:    Stop a wait for lon
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_lon  PROC far
    push ds
;
    mov ds,es:lon_sel
    mov ds:lon_avail_obj,0
;
    pop ds
    retf32
stop_wait_for_lon Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsLonIdle
;
;           DESCRIPTION:    Check if lon is idle
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_lon_idle    PROC far
    push ds
    push ax
;
    mov ds,es:lon_sel
    mov ax,ds:lon_rec_count
    or ax,ax
    clc
    jz iliDone
;
    stc

iliDone:    
    pop ax
    pop ds
    retf32
is_lon_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearLon
;
;           DESCRIPTION:    Clear lon
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_lon  PROC far
    retf32
clear_lon Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForLonModule
;
;           DESCRIPTION:    Add a wait for lon msg
;
;           PARAMETERS:         BX      Wait handle
;               ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_lon_module_name      DB 'Add Wait For Lon Module',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_lon,      SEG code
aw1 DD OFFSET stop_wait_for_lon,       SEG code
aw2 DD OFFSET clear_lon,               SEG code
aw3 DD OFFSET is_lon_idle,             SEG code

add_wait_for_lon_module   PROC far
    push ds
    push es
    push ax
    push edi
;
    push ebx
    mov bx,ax
    mov ax,LON_HANDLE
    DerefHandle
    jc add_wait_pop
;    
    mov ax,ds:[ebx].lon_handle_sel
    pop ebx
;    
    push ax
    mov ax,cs
    mov es,ax
    mov edi,OFFSET add_wait_tab
    mov ax,SIZE lon_wait_header - SIZE wait_obj_header
    AddWait
    pop ax
    jc add_wait_done
;
    mov es:lon_sel,ax
    jmp add_wait_done

add_wait_pop:
    pop ebx

add_wait_done:
    pop edi
    pop ax
    pop es
    pop ds
    retf32
add_wait_for_lon_module   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetLonModules
;
;       description:    Get number of lon modules
;
;       RETURNS:        AL      Number of modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_lon_modules_name DB 'Get Lon Modules',0

get_lon_modules        Proc far
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:lon_module_count
    pop ds
    retf32
get_lon_modules    Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenLonModule
;
;       description:    Open lon module
;
;       PARAMETERS:     AL              Module #
;                       SI              Send buffers
;                       DI              Receive buffers
;
;       RETURNS:        BX              Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_lon_module_name DB 'Open Lon Module',0

open_lon_module       Proc far
    push ds
    push es
    push ax
    push cx
    push dx
;
    mov dx,SEG data
    mov ds,dx
    movzx dx,al
    cmp dx,ds:lon_module_count
    jae open_lon_fail
;    
    mov bx,dx
    add bx,bx
    mov es,ds:[bx].lon_module_arr
;
    mov ax,LON_HANDLE
    mov cx,SIZE lon_handle_seg
    AllocateHandle
    mov [ebx].lon_handle_sel,es
    mov [ebx].hh_sign,LON_HANDLE
    mov bx,[ebx].hh_handle
;
    mov ax,es
    mov ds,ax
;
    movzx eax,si
    mov ds:lon_send_size,ax
    shl eax,1
    AllocateSmallGlobalMem
    mov ds:lon_send_buf,es
    mov ds:lon_send_count,0
    mov ds:lon_send_head,0
    mov ds:lon_send_tail,0
;    
    push di
    mov cx,ds:lon_send_size
    xor di,di
    xor ax,ax
    rep stosw
    pop di
;
    movzx eax,di
    mov ds:lon_rec_size,ax
    shl eax,1
    AllocateSmallGlobalMem
    mov ds:lon_rec_buf,es
    mov ds:lon_rec_count,0
    mov ds:lon_rec_head,0
    mov ds:lon_rec_tail,0
;    
    push di
    mov cx,ds:lon_rec_size
    xor di,di
    xor ax,ax
    rep stosw
    pop di
;    
    call fword ptr ds:lon_open_proc    
    clc
    jmp open_lon_done
    
open_lon_fail:
    xor bx,bx
    stc

open_lon_done:
    pop dx
    pop cx
    pop ax
    pop es
    pop ds
    retf32 
open_lon_module       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ResetLonModule
;
;       description:    Reset lon module
;
;       PARAMETERS:     AL      Module #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_lon_module_name DB 'Reset Lon Module',0

reset_lon_module       Proc far
    push ds
    push ax
    push bx
    push dx
;
    mov dx,SEG data
    mov ds,dx
    movzx dx,al
    cmp dx,ds:lon_module_count
    jae reset_lon_done
;    
    mov bx,dx
    add bx,bx
    mov ds,ds:[bx].lon_module_arr
    call fword ptr ds:lon_reset_proc    

reset_lon_done:
    pop dx
    pop bx
    pop ax
    pop ds
    retf32
reset_lon_module       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CloseLonModule
;
;       description:    Close lon module
;
;       PARAMETERS:     BX              Lon handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_lon_module_name DB 'Close Lon Module',0

close_lon_module       Proc far
    push ds
    push ax
    push dx
;
    mov ax,LON_HANDLE
    DerefHandle
    jc close_lon_done
;
    push ds
    push es
    push fs
    push ebx
    push cx
    push si
;    
    mov ds,ds:[ebx].lon_handle_sel
    call fword ptr ds:lon_close_proc    
;
    mov fs,ds:lon_send_buf
    mov cx,ds:lon_send_size
    xor si,si

close_free_send_loop:
    mov ax,fs:[si]
    or ax,ax
    jz close_free_send_next
;
    mov es,ax
    FreeMem

close_free_send_next:
    add si,2
    loop close_free_send_loop
;
    mov fs,ds:lon_rec_buf
    mov cx,ds:lon_rec_size
    xor si,si

close_free_rec_loop:
    mov ax,fs:[si]
    or ax,ax
    jz close_free_rec_next
;
    mov es,ax
    FreeMem

close_free_rec_next:
    add si,2
    loop close_free_rec_loop
;
    xor ax,ax
    mov fs,ax
;    
    mov es,ds:lon_send_buf
    FreeMem
;
    mov es,ds:lon_rec_buf
    FreeMem
;
    pop si
    pop cx
    pop ebx
    pop fs
    pop es
    pop ds
    FreeHandle

close_lon_done:
    pop dx
    pop ax
    pop ds
    retf32
close_lon_module       Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddLonModule
;
;           DESCRIPTION:    Add lon module
;
;           PARAMETERS:     DS      Lon device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_lon_module_name    DB 'Add Lon Module',0

add_lon_module     PROC far
    push ds
    push bx
    push dx
;
    mov ds:lon_avail_obj,0
    InitSection ds:lon_section
;
    mov dx,ds
    mov bx,SEG data
    mov ds,bx
;
    mov bx,ds:lon_module_count
    add bx,bx
    mov ds:[bx].lon_module_arr,dx
    inc ds:lon_module_count
;
    pop dx
    pop bx
    pop ds    
    retf32
add_lon_module     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_lon_handle
;
;           DESCRIPTION:    BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_lon_handle       Proc far
    push ds
    push ax
    push ebx
;
    mov ax,LON_HANDLE
    DerefHandle
    jc delete_lon_handle_done
;
    FreeHandle

delete_lon_handle_done:
    pop ebx
    pop ax
    pop ds
    retf32
delete_lon_handle       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyLonData
;
;           description:    Notify reception of Lon data
;
;       parameters:         ES      Lon data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_lon_data_name DB 'Notify Lon Data', 0

notify_lon_data  Proc far
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:capture_section
    mov ax,ds:capture_thread
    or ax,ax
    jz nldLeave
;    
    push es
    pushad
;    
    mov bx,es
    GetSelectorBaseSize
;    
    mov ax,es
    mov ds,ax
    xor esi,esi
    mov bx,flat_sel
    mov es,bx
    mov eax,SIZE capture_block
    AllocateSmallLinear
    mov edi,edx
;    
    GetTime
    mov es:[edi].cb_time+4,edx
    mov es:[edi].cb_time,eax
    mov es:[edi].cb_src,'R'
    mov es:[edi].cb_len,cl
    cmp ecx,118
    jb nldSizeOk
;
    mov ecx,118

nldSizeOk:    
    mov edx,edi
    add edi,OFFSET cb_data
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov bx,SEG data
    mov ds,bx
;
    mov eax,ds:capture_list
    or eax,eax
    jne nldQueue

nldEmpty:
    mov es:[edx].cb_prev,edx
    mov es:[edx].cb_next,edx
    mov ds:capture_list,edx
    jmp nldSignal

nldQueue:
    mov ebx,es:[eax].cb_prev
    mov es:[eax].cb_prev,edx
    mov es:[ebx].cb_next,edx
    mov es:[edx].cb_prev,ebx
    mov es:[edx].cb_next,eax    

nldSignal:
    mov bx,ds:capture_thread
    Signal
;
    popad
    pop es

nldLeave:
    LeaveSection ds:capture_section
;    
    pop ax
    pop ds    
    retf32
notify_lon_data  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CaptureThread
;
;           description:    Capture thread
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

capture_thread_name DB 'Lon Capture', 0

capture_thread_pr:
    mov bx,SEG data
    mov ds,bx
    mov bx,flat_sel
    mov es,bx
    GetThread
    mov ds:capture_thread,ax
    LeaveSection ds:capture_section
;    
    mov bx,ds:capture_handle
    GetFileSize32
    SetFilePos32

ctpLoop:
    WaitForSignal

ctpMore:
    EnterSection ds:capture_section    
    mov ax,ds:capture_thread
    or ax,ax
    jz ctpExit
;
    mov edx,ds:capture_list
    or edx,edx
    jz ctpNext
;
    push ebx
    mov eax,es:[edx].cb_next
    mov ebx,es:[edx].cb_prev
    mov es:[ebx].cb_next,eax
    mov es:[eax].cb_prev,ebx
    pop ebx
    cmp eax,edx
    jne ctpUnlink
;
    mov ds:capture_list,0
    jmp ctpWrite

ctpUnlink:
    mov ds:capture_list,eax

ctpWrite:       
    LeaveSection ds:capture_section
;    
    mov edi,edx
    mov ecx,128
    add edi,8
    UserGateForce32 write_file_nr
;
    add ecx,8
    FreeLinear    
    jmp ctpMore
    
ctpNext:
    LeaveSection ds:capture_section
    jmp ctpLoop

ctpExit:  
    mov ds:capture_thread,0
    LeaveSection ds:capture_section
    retf    
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartLonCapture
;
;           description:    Start capturing lon-packets
;
;       parameters:     BX      File handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_lon_capture_name DB 'Start Lon Capture', 0

start_lon_capture       Proc far
    push ds
    push es
    push ax
    push bx
    push cx
    push si
    push di
;    
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:capture_section
;
    mov ds:capture_handle,bx
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET capture_thread_pr
    mov di,OFFSET capture_thread_name
    mov ax,3
    mov cx,stack0_size
    CreateThread
;       
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
    retf32
start_lon_capture       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StopLonCapture
;
;           description:    Stop capturing lon-packets
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_lon_capture_name DB 'Stop Lon Capture', 0

stop_lon_capture    Proc far
    push ds
    push bx
;    
    mov bx,SEG data
    mov ds,bx
    EnterSection ds:capture_section
    xor bx,bx
    xchg bx,ds:capture_thread
    or bx,bx
    jz sncThreadDone
;    
    Signal
    mov bx,ds:capture_handle
    CloseFile

sncThreadDone:
    mov ds:capture_handle,0
    LeaveSection ds:capture_section    
;
    pop bx
    pop ds    
    retf32
stop_lon_capture    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
;    
    mov ax,LON_HANDLE
    mov edi,OFFSET delete_lon_handle
    RegisterHandle
;
    mov esi,OFFSET add_lon_module
    mov edi,OFFSET add_lon_module_name
    xor cl,cl
    mov ax,add_lon_module_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_lon_data
    mov edi,OFFSET notify_lon_data_name
    xor cl,cl
    mov ax,notify_lon_data_nr
    RegisterOsGate
;
    mov esi,OFFSET get_lon_modules
    mov edi,OFFSET get_lon_modules_name
    xor dx,dx
    mov ax,get_lon_modules_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET open_lon_module
    mov edi,OFFSET open_lon_module_name
    xor dx,dx
    mov ax,open_lon_module_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET reset_lon_module
    mov edi,OFFSET reset_lon_module_name
    xor dx,dx
    mov ax,reset_lon_module_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_lon_module
    mov edi,OFFSET close_lon_module_name
    xor dx,dx
    mov ax,close_lon_module_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_lon_module
    mov edi,OFFSET add_wait_for_lon_module_name
    xor dx,dx
    mov ax,add_wait_for_lon_module_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET send_lon_module_msg16
    mov esi,OFFSET send_lon_module_msg32
    mov edi,OFFSET send_lon_module_msg_name
    mov dx,virt_es_in
    mov ax,send_lon_module_msg_nr
    RegisterUserGate
;
    mov esi,OFFSET has_lon_module_msg
    mov edi,OFFSET has_lon_module_msg_name
    xor dx,dx
    mov ax,has_lon_module_msg_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET receive_lon_module_msg16
    mov esi,OFFSET receive_lon_module_msg32
    mov edi,OFFSET receive_lon_module_msg_name
    mov dx,virt_es_in
    mov ax,receive_lon_module_msg_nr
    RegisterUserGate
;
    mov esi,OFFSET start_lon_capture
    mov edi,OFFSET start_lon_capture_name
    xor dx,dx
    mov ax,start_lon_capture_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET stop_lon_capture
    mov edi,OFFSET stop_lon_capture_name
    xor dx,dx
    mov ax,stop_lon_capture_nr
    RegisterBimodalUserGate
;
    mov ax,SEG data
    mov ds,ax
    mov ds:lon_module_count,0    
    InitSection ds:capture_section
    mov ds:capture_handle,0
    mov ds:capture_thread,0
    mov ds:capture_list,0
    ret
init    ENDP

code    ENDS

    END init
