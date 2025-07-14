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
; SYSLOG.ASM
; Syslog protocol
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.inc
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc

LOG_BUF_COUNT   = 20h

log_buf_entry   STRUC

log_facility        DB ?
log_severity        DB ?

log_time            DD ?,?

log_size            DD ?

log_msg_buf         DB ?

log_buf_entry   ENDS

syslog_wait_header STRUC

sw_obj          wait_obj_header <>
sw_handle       DW ?

syslog_wait_header ENDS

syslog_handle_seg          STRUC

sl_base         handle_header <>

sl_curr_id      DD ?

syslog_handle_seg          ENDS

data    SEGMENT byte public 'DATA'

log_section         section_typ <>

log_obj_list        DW ?

log_head_id         DD ?
log_head_entry      DW ?
log_buf_arr         DW LOG_BUF_COUNT DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetInt
;
;       Purpose:        Get integer from text
;
;       Parameters:     CX      Buffer size
;                       ES:EDI  Buffer Data
;
;       Returns:        AX      Value
;                       CX      Returned buffer size
;                       ES:EDI  Returned buffer data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetInt  Proc near
    push dx
;    
    xor dx,dx

giSpaceLoop:
    or cx,cx
    jz giOk
;
    mov al,es:[edi]
    cmp al,' '
    jne giLoop
;
    sub cx,1
    inc edi
    jmp giSpaceLoop

giLoop:
    sub cx,1
    jz giOk
;
    inc edi
    mov al,es:[edi]
;    
    sub al,'0'
    jc giOk
;
    cmp al,9
    ja giOk
;
    movzx ax,al
    push ax
    mov ax,10
    mul dx
    mov dx,ax
    pop ax                
    add dx,ax
    jmp giLoop

giOk:
    mov ax,dx
    pop dx
    ret
GetInt  Endp    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetMonth
;
;       Purpose:        Get month from text
;
;       Parameters:     CX      Buffer size
;                       ES:EDI  Buffer Data
;
;       Returns:        AX      Month
;                       CX      Returned buffer size
;                       ES:EDI  Returned buffer data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MonthTab:
mt01 DB   'Jan', 0
mt02 DB   'Feb', 0
mt03 DB   'Mar', 0
mt04 DB   'Apr', 0
mt05 DB   'May', 0
mt06 DB   'Jun', 0
mt07 DB   'Jul', 0
mt08 DB   'Aug', 0
mt09 DB   'Sep', 0
mt10 DB   'Oct', 0
mt11 DB   'Nov', 0
mt12 DB   'Dec', 0

GetMonth  Proc near
    push dx
    push si
;
    cmp cx,3
    jae gmSizeOk
;
    xor cx,cx
    xor ax,ax
    jmp gmDone

gmSizeOk:
    push cx
    mov cx,12
    mov dx,1
    mov si,OFFSET MonthTab

gmLoop:
    mov eax,es:[edi]
    xor eax,cs:[si]
    and eax,0FFFFFFh
    jz gmFound
;
    inc dx
    add si,4
    loop gmLoop
;    
    xor ax,ax
    pop cx
    jmp gmDone

gmFound:
    pop cx
    add edi,3
    sub ecx,3
    mov ax,dx

gmDone:    
    pop si
    pop dx
    ret
GetMonth    Endp    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateEntry
;
;       Purpose:        Create entry
;
;       Parameters:     ECX     Msg size
;                       ES:EDI  Msg data
;                       EDX:EAX Time
;                       SI      Facility (MSB) + severity (LSB)
;
;       Returns:        BX      Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateEntry Proc near
    push ds
    push es
    push esi
    push edi
;
    push eax
    push edx
;    
    push si
    mov ax,es
    mov ds,ax
    mov esi,edi
;
    or ecx,ecx
    jz ceAlloc
    
ceBufLoop:            
    mov al,[esi+ecx-1]
    cmp al,0Ah
    je ceBufNext
;
    cmp al,0Dh
    jne ceAlloc

ceBufNext:
    sub ecx,1
    jnz ceBufLoop

ceAlloc:    
    mov eax,OFFSET log_msg_buf
    add ax,cx
    AllocateSmallGlobalMem
    pop ax
;    
    mov es:log_facility,ah
    mov es:log_severity,al
    mov es:log_size,ecx
;
    pop edx
    pop eax
    mov es:log_time,eax
    mov es:log_time+4,edx
;
    mov edi,OFFSET log_msg_buf
    rep movs byte ptr es:[edi],ds:[esi]    
;
    mov bx,es
    pop edi
    pop esi
    pop es
    pop ds        
    ret
CreateEntry Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           AddEntry
;
;       Purpose:        Add entry
;
;       Parameters:     BX      Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddEntry Proc near
    push ds
    push es
    push ax
    push si
;    
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:log_section
;
    mov si,ds:log_head_entry
    inc si
    cmp si,LOG_BUF_COUNT
    jb aeHeadOk
;
    xor si,si

aeHeadOk:
    mov ds:log_head_entry,si
    inc ds:log_head_id
    add si,si
    add si,OFFSET log_buf_arr
    mov ax,[si]
    or ax,ax
    jz aeEmptyOk
;
    mov es,ax
    FreeMem

aeEmptyOk:
    mov [si],bx
;
    mov ax,ds:log_obj_list
    or ax,ax
    jz aeSignalDone

aeSignalLoop:    
    mov es,ax
    mov ax,es:wo_list
    SignalWait
    or ax,ax
    jnz aeSignalLoop

aeSignalDone:
    LeaveSection ds:log_section
;
    pop si
    pop ax
    pop es
    pop ds    
    ret
AddEntry Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           AddSyslog
;
;       Purpose:        Add to syslog
;
;       Parameters:     (E)CX       Msg size
;                       ES:(E)DI    Msg data
;                       EDX:EAX     Time
;                       SI          Facility (MSB) + severity (LSB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_syslog_name       DB 'Add To Syslog',0

add_syslog16    Proc far
    push bx
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call CreateEntry
    call AddEntry
;
    pop edi
    pop ecx
    pop bx        
    retf32
add_syslog16    Endp

add_syslog32    Proc far
    push bx
    call CreateEntry
    call AddEntry
    pop bx        
    retf32
add_syslog32    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           syslog_receive
;
;       Purpose:        Syslog receive callback
;
;       Parameters:     CX      UDP request size
;                       ES:EDI  UDP request data
;
;       Returns:        CX      UDP reply size (or 0)
;                       ES:EDI  UDP reply data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

syslog_receive  Proc far
    push bx
    push dx
    push si
;    
    or cx,cx
    jz syslog_done
;    
    mov dl,es:[edi]
    cmp dl,'<'
    jne syslog_done
;
    call GetInt
    or cx,cx
    jz syslog_done
;    
    mov dl,es:[edi]
    cmp dl,'>'
    jne syslog_done
;
    inc edi
    sub cx,1
;    
    mov dx,ax
    and al,7
    shr dx,3
    mov ah,dl
    mov si,ax
;
    call GetMonth
    or al,al
    jnz syslog_text_date
;
    call GetInt
    mov al,es:[edi]
    cmp al,'-'
    jne syslog_done
;
    sub cx,1
    jbe syslog_done
;
    inc edi
    call GetInt
    mov al,es:[edi]
    cmp al,'-'
    jne syslog_done
;
    sub cx,1
    jbe syslog_done
;
    inc edi
    call GetInt
    mov al,es:[edi]
    cmp al,'T'
    jne syslog_done
;
    sub cx,1
    jbe syslog_done
;
    inc edi
    call GetInt
    mov al,es:[edi]
    cmp al,':'
    jne syslog_done
;
    sub cx,1
    jbe syslog_done
;
    inc edi
    call GetInt
    mov al,es:[edi]
    cmp al,':'
    jne syslog_done
;
    sub cx,1
    jbe syslog_done
;
    inc edi
    call GetInt
;
    GetTime
    jmp syslog_msg_loop

syslog_text_date:
    mov dh,al
    call GetInt
    mov dl,al
    call GetInt
    mov bh,al
;
    mov al,es:[edi]
    cmp al,':'
    jne syslog_done
;
    sub cx,1
    jbe syslog_done
;
    inc edi
    call GetInt
    mov bl,al
;
    mov al,es:[edi]
    cmp al,':'
    jne syslog_done
;
    sub cx,1
    jbe syslog_done
;
    inc edi
    call GetInt
    mov ah,al
;
    GetTime

syslog_msg_loop:
    or cx,cx
    jz syslog_done
;
    mov al,es:[edi]
    cmp al,' '
    jne syslog_msg_ok
;
    sub cx,1
    inc edi
    jmp syslog_msg_loop

syslog_msg_ok:
    call CreateEntry
    call AddEntry
                        
syslog_done:
    xor cx,cx    
    pop si
    pop dx
    pop bx
    retf32
syslog_receive  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           OpenSyslog
;
;           DESCRIPTION:    Open syslog
;
;           RETURNS:        BX          Syslog handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_syslog_name    DB 'Open Syslog',0

open_syslog     PROC far
    push ds
    push es
    push eax
    push cx
;
    mov cx,SIZE syslog_handle_seg
    AllocateHandle
    mov ds:[ebx].sl_curr_id,0
    mov [ebx].hh_sign,SYSLOG_HANDLE
    mov bx,[ebx].hh_handle
    clc
;
    pop cx
    pop eax
    pop es
    pop ds
    retf32
open_syslog     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloseSyslog
;
;           DESCRIPTION:    Close syslog
;
;           PARAMETERS:     BX          Syslog handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_syslog_name    DB 'Close Syslog',0

close_syslog     PROC far
    push ds
    push ebx
;
    mov ax,SYSLOG_HANDLE
    DerefHandle
    jc csDone
;
    FreeHandle
    clc

csDone:
    pop ebx
    pop ds
    retf32
close_syslog     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_handle
;
;           DESCRIPTION:    Delete syslog handle
;
;           PARAMETERS:     BX          Syslog handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle     PROC far
    push ds
    push ebx
;
    mov ax,SYSLOG_HANDLE
    DerefHandle
    jc dsDone
;
    FreeHandle
    clc

dsDone:
    pop ebx
    pop ds
    retf32
delete_handle     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForSyslog
;
;           DESCRIPTION:    Start a wait for syslog
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_syslog PROC far
    push ds
    push eax
    push bx
    push dx
;
    mov bx,es:sw_handle
    mov ax,SYSLOG_HANDLE
    DerefHandle
    jc start_wait_done
;
    mov eax,[ebx].sl_curr_id
;
    push fs
    mov dx,SEG data
    mov ds,dx
    EnterSection ds:log_section
;
    cmp eax,ds:log_head_id
    jne start_wait_ready
;   
    xor dx,dx
    mov bx,es
    mov ax,ds:log_obj_list

start_wait_check_loop:
    or ax,ax
    jz start_wait_insert
;
    cmp ax,bx
    je start_wait_leave
;
    mov dx,ax
    mov fs,ax
    mov ax,fs:wo_list
    jmp start_wait_check_loop

start_wait_insert:
    mov es:wo_list,0
;    
    or dx,dx
    jz start_wait_head
;
    mov fs:wo_list,es
    jmp start_wait_leave

start_wait_head:    
    mov ds:log_obj_list,es
    jmp start_wait_leave

start_wait_ready:
    SignalWait

start_wait_leave:    
    pop fs
    LeaveSection ds:log_section

start_wait_done:
    pop dx
    pop bx
    pop eax
    pop ds
    retf32
start_wait_for_syslog Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForSyslog
;
;           DESCRIPTION:    Stop a wait for syslog
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_syslog  PROC far
    push ds
    push fs
    push eax
    push bx
    push dx
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:log_section
;    
    xor dx,dx
    mov bx,es
    mov ax,ds:log_obj_list

stop_wait_loop:
    cmp ax,bx
    je stop_wait_unlink
;
    or ax,ax
    jz stop_wait_leave    
;
    mov dx,ax
    mov fs,ax
    mov ax,fs:wo_list
    jmp stop_wait_loop

stop_wait_unlink:
    or dx,dx
    jz stop_wait_head
;
    mov ax,es:wo_list
    mov fs,dx
    mov fs:wo_list,ax
    jmp stop_wait_leave

stop_wait_head:
    mov ax,es:wo_list
    mov ds:log_obj_list,ax

stop_wait_leave:
    xor ax,ax
    mov fs,ax
    LeaveSection ds:log_section
;
    pop dx
    pop bx
    pop eax
    pop fs
    pop ds
    retf32
stop_wait_for_syslog Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsSyslogIdle
;
;           DESCRIPTION:    Check if syslog is idle
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_syslog_idle    PROC far
    push ds
    push eax
    push bx
    push dx
;
    mov bx,es:sw_handle
    mov ax,SYSLOG_HANDLE
    DerefHandle
    jc is_idle_done
;
    mov eax,[ebx].sl_curr_id
    mov dx,SEG data
    mov ds,dx
    cmp eax,ds:log_head_id
    clc
    je is_idle_done
;
    stc

is_idle_done:
    pop dx
    pop bx
    pop eax
    pop ds
    retf32
is_syslog_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearSyslog
;
;           DESCRIPTION:    Clear syslog
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_syslog  PROC far
    push ds
    push fs
    push eax
    push bx
    push dx
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:log_section
;    
    xor dx,dx
    mov bx,es
    mov ax,ds:log_obj_list

clear_wait_loop:
    cmp ax,bx
    je clear_wait_unlink
;
    or ax,ax
    jz clear_wait_leave    
;
    mov dx,ax
    mov fs,ax
    mov ax,fs:wo_list
    jmp clear_wait_loop

clear_wait_unlink:
    or dx,dx
    jz clear_wait_head
;
    mov ax,es:wo_list
    mov fs,dx
    mov fs:wo_list,ax
    jmp clear_wait_leave

clear_wait_head:
    mov ax,es:wo_list
    mov ds:log_obj_list,ax

clear_wait_leave:
    xor ax,ax
    mov fs,ax
    LeaveSection ds:log_section
;
    pop dx
    pop bx
    pop eax
    pop fs
    pop ds
    retf32
clear_syslog Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForSyslog
;
;           DESCRIPTION:    Add a wait for syslog
;
;           PARAMETERS:     AX      Syslog handle
;                           BX      Wait handle
;                           ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_syslog_name      DB 'Add Wait For Syslog',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_syslog,        SEG code
aw1 DD OFFSET stop_wait_for_syslog,         SEG code
aw2 DD OFFSET clear_syslog,                 SEG code
aw3 DD OFFSET is_syslog_idle,               SEG code

add_wait_for_syslog   PROC far
    push ds
    push es
    push eax
    push edi
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE syslog_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWait
    pop ax
    jc add_wait_done
;
    mov es:sw_handle,ax

add_wait_done:
    pop edi
    pop eax
    pop es
    pop ds
    retf32
add_wait_for_syslog   ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetSyslog
;
;           DESCRIPTION:    Get syslog
;
;           PARAMETERS:     BX          Syslog handle
;                           (E)CX       Buf size
;                           ES:(E)DI    Msg buf
;
;           RETURNS:        SI          Severity (LSB), Facility (MSB)
;                           EDX:EAX     Time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_syslog_name    DB 'Get Syslog',0

get_syslog     PROC near
    push ds
    push ebx
    push ecx
    push edi
;
    mov ax,SYSLOG_HANDLE
    DerefHandle
    jc gsFail
;
    push ds
    mov edx,[ebx].sl_curr_id
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:log_section
    mov eax,ds:log_head_id
    sub eax,edx
    jz gsLeaveFail
;
    cmp eax,LOG_BUF_COUNT
    jb gsIdOk
;
    mov eax,LOG_BUF_COUNT - 1

gsIdOk:
    mov si,ds:log_head_entry
    inc si
    sub si,ax
    jnc gsEntryOk
;
    add si,LOG_BUF_COUNT

gsEntryOk:    
    add si,si
    mov edx,eax
    mov eax,ds:log_head_id
    sub eax,edx
    inc eax
    mov dx,ds:[si].log_buf_arr
    pop ds
    mov [ebx].sl_curr_id,eax
;
    dec ecx
    mov ds,dx
    mov eax,ds:log_size
    cmp eax,ecx
    jae gsSizeOk
;
    mov ecx,eax

gsSizeOk:
    mov esi,OFFSET log_msg_buf
    rep movs byte ptr es:[edi],ds:[esi]
    mov byte ptr es:[edi],0
;    
    mov al,ds:log_severity
    mov ah,ds:log_facility
    mov si,ax
    mov eax,ds:log_time
    mov edx,ds:log_time+4        
;
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:log_section
    jmp gsDone

gsLeaveFail:
    LeaveSection ds:log_section
    pop ax

gsFail:
    xor si,si
    xor eax,eax
    xor edx,edx
    mov byte ptr es:[edi],0
    
gsDone:
    pop edi
    pop ecx
    pop ebx
    pop ds
    ret
get_syslog     ENDP

get_syslog16    Proc far
    push ecx
    push esi
    push edi
;
    movzx ecx,cx
    movzx esi,si
    movzx edi,di
    call get_syslog
;
    pop edi
    pop esi
    pop ecx 
    retf32
get_syslog16    Endp 

get_syslog32    Proc far
    call get_syslog
    retf32
get_syslog32    Endp
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_task_syslog
;
;           DESCRIPTION:    Init syslog driver, tasking part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_task_syslog

init_task_syslog    PROC near
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    mov ds:log_head_id,0
    mov ds:log_obj_list,0
    mov ds:log_head_entry,LOG_BUF_COUNT - 1
    mov cx,LOG_BUF_COUNT
    mov di,OFFSET log_buf_arr
    xor ax,ax
    rep stosw
    InitSection ds:log_section
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET delete_handle
    mov ax,SYSLOG_HANDLE
    RegisterHandle
;
    mov si,514
    mov edi,OFFSET syslog_receive
    ListenUdpPort
;
    mov ebx,OFFSET add_syslog16
    mov esi,OFFSET add_syslog32
    mov edi,OFFSET add_syslog_name
    mov dx,virt_es_in
    mov ax,add_syslog_nr
    RegisterUserGate
;
    mov esi,OFFSET open_syslog
    mov edi,OFFSET open_syslog_name
    xor dx,dx
    mov ax,open_syslog_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_syslog
    mov edi,OFFSET close_syslog_name
    xor dx,dx
    mov ax,close_syslog_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_syslog
    mov edi,OFFSET add_wait_for_syslog_name
    xor dx,dx
    mov ax,add_wait_for_syslog_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_syslog16
    mov esi,OFFSET get_syslog32
    mov edi,OFFSET get_syslog_name
    mov dx,virt_es_in
    mov ax,get_syslog_nr
    RegisterUserGate
;
    ret
init_task_syslog    ENDP

code    ENDS

    END
