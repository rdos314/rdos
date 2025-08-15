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
; task.ASM
; uACPI task server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os\system.def
INCLUDE ..\os\state.def
INCLUDE ..\os\exec.def
include ..\os.def
include ..\os.inc
include ..\serv.def
include ..\serv.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\handle.inc
include ..\wait.inc
include ..\os\protseg.def
include ..\os\core.inc
include acpi.def

REQ_CREATE_THREAD     = 1
REQ_TERMINATE_THREAD  = 2
REQ_CREATE_PROCESS    = 3
REQ_TERMINATE_PROCESS = 4
REQ_CREATE_PROGRAM    = 5
REQ_TERMINATE_PROGRAM = 6

task_queue_struc    STRUC

tqs_op        DW ?
tqs_spare     DW ?
tqs_id        DD ?

task_queue_struc    ENDS

thread_state_struc  STRUC

ths_core      DW ?
ths_prio      DW ?
ths_irq       DB ?
ths_pad       DB ?
ths_tics      DD ?,?

thread_state_struc  ENDS

proc_end_wait_header    STRUC

pew_obj             wait_obj_header <>
pew_proc_id         DW ?

proc_end_wait_header    ENDS

    .386p

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

data    SEGMENT byte public 'DATA'

task_id            DW ?
tarr_size          DD ?
tarr_count         DD ?
tarr_section       section_typ <>

proc_id            DW ?
parr_size          DD ?
parr_count         DD ?
parr_section       section_typ <>

prog_id            DW ?
aarr_size          DD ?
aarr_count         DD ?
aarr_section       section_typ <>

module_id          DW ?
marr_size          DD ?
marr_count         DD ?
marr_section       section_typ <>

task_linear        DD ?
task_phys          DD ?,?
task_sel           DW ?
task_wr_ptr        DW ?
task_wait_thread   DW ?
task_section       section_typ <>

data    ENDS

code    SEGMENT byte public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetTaskQueue
;
;       DESCRIPTION:    Get task queue
;
;       RETURNS:        EAX                Linear address of task queue
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_task_queue_name DB 'Get Task Queue', 0

get_task_queue   Proc far
    push ds
    push ebx
    push edx
;
    mov eax,SEG data
    mov ds,eax
;
    mov eax,1000h
    AllocateLocalLinear
;
    mov eax,ds:task_phys
    mov ebx,ds:task_phys+4
    or ax,867h
    SetPageEntry
;
    mov eax,edx
    clc
;
    pop edx
    pop ebx
    pop ds
    ret
get_task_queue  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitTaskQueue
;
;       DESCRIPTION:    Wait task queue
;
;       PARAMETERS:     EAX               Current index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_task_queue_name DB 'Wait Task Queue', 0

wait_task_queue   Proc far
    push ds
    push eax
    push ebx
    push edx
;
    mov edx,eax
    ClearSignal
;
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:task_section
;
    GetThread
    mov ds:task_wait_thread,ax
;
    shl edx,3
    movzx ebx,ds:task_wr_ptr
    cmp ebx,edx
    LeaveSection ds:task_section
    jne wtqDone
;
    WaitForSignal

wtqClear:
    mov ds:task_wait_thread,0

wtqDone:
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
wait_task_queue  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddEntry
;
;           DESCRIPTION:    Add task entry
;
;           PARAMETERS:     EBX    ID
;                           DX     Op
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddEntry   Proc near
    push es
    push ecx
    push esi
;
    mov es,ds:task_sel

aeRetry:
    EnterSection ds:task_section
;
    movzx esi,ds:task_wr_ptr
    mov ax,es:[esi].tqs_op
    or ax,ax
    jz aeRoom
;
    LeaveSection ds:task_section
;
    mov ax,25
    WaitMilliSec
    jmp aeRetry
 
aeRoom:
    mov es:[esi].tqs_op,dx
    mov es:[esi].tqs_id,ebx
    add si,8
    and si,0FFFh
    mov ds:task_wr_ptr,si
;
    mov bx,ds:task_wait_thread
    or bx,bx
    jz aeDone
;
    Signal

aeDone:
    LeaveSection ds:task_section
;
    pop esi
    pop ecx
    pop es
    ret
AddEntry   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GrowThreadArr
;
;           DESCRIPTION:    Grow thread array
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowThreadArr   Proc near
    push es
    pushad
;
    mov eax,flat_sel
    mov es,eax
;
    mov ecx,ds:tarr_size
    mov ebp,ecx
    inc ecx
    shl ecx,1
    mov ds:tarr_size,ecx
;
    mov eax,ecx
    shl eax,1
    AllocateSmallLinear
    mov edi,edx
;
    or ebx,ebx
    jz gtaCopied
;
    push ecx
    push edx
;
    mov ebx,thread_arr_sel
    GetSelectorBaseSize
    mov esi,edx
    mov ecx,ebp
    rep movs word ptr es:[edi],es:[esi]
;
    FreeLinear
;
    pop edx
    pop ecx

gtaCopied:
    push ecx
    sub ecx,ebp
    xor ax,ax
    rep stosw
    pop ecx
;
    mov bx,thread_arr_sel
    shl ecx,1
    CreateDataSelector32
;
    popad
    pop es
    ret
GrowThreadArr   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServGetThreadState
;
;       DESCRIPTION:    Get thread state
;
;       PARAMETERS:     EBX            Handle
;                       ES:EDI         State buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_thread_state_name DB 'Get Thread State', 0

serv_thread_state   Proc far
    push ds
    push fs
    push eax
    push ebx
    push esi
;
    mov eax,SEG data
    mov ds,eax
    mov eax,thread_arr_sel
    mov fs,eax
    EnterSection ds:tarr_section
;
    mov esi,ebx
    shr esi,16
    cmp esi,ds:tarr_size
    jae stsFail
;
    mov ax,fs:[2*esi]
    or ax,ax
    jz stsFail
;
    mov fs,eax
    mov ax,fs:p_id
    cmp ax,bx
    jne stsFail
;
    mov ax,fs:p_prio
    shr ax,1
    mov es:[edi].ths_prio,ax
;
    mov al,fs:p_irq
    mov es:[edi].ths_irq,al

stsRetry:
    mov ebx,fs:p_msb_tics
    mov eax,fs:p_lsb_tics
    cmp ebx,fs:p_msb_tics
    jne stsRetry
;
    mov es:[edi].ths_tics,eax
    mov es:[edi].ths_tics+4,ebx
;
    mov ax,fs:p_core
    or ax,ax
    jz stsNoCore
;
    mov fs,eax
    mov ax,fs:cs_id

stsNoCore:
    mov es:[edi].ths_core,ax
;
    LeaveSection ds:tarr_section
    clc
    jmp stsDone

stsFail:
    LeaveSection ds:tarr_section
    stc

stsDone:
    pop esi
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
serv_thread_state  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServGetThreadName
;
;       DESCRIPTION:    Get thread name
;
;       PARAMETERS:     EBX            Thread ID
;                       ES:EDI         Name buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_get_thread_name_name DB 'Get Thread Name', 0

serv_get_thread_name   Proc far
    push ds
    push fs
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    mov eax,SEG data
    mov ds,eax
    mov eax,thread_arr_sel
    mov fs,eax
    EnterSection ds:tarr_section
;
    mov esi,ebx
    shr esi,16
    cmp esi,ds:tarr_size
    jae gtnFail
;
    mov ax,fs:[2*esi]
    or ax,ax
    jz gtnFail
;
    mov fs,eax
    mov ax,fs:p_id
    cmp ax,bx
    jne gtnFail
;
    mov esi,OFFSET thread_name
    mov ecx,30
    rep movs byte ptr es:[edi],fs:[esi]
;
    dec edi

gtnLoop:
    mov al,es:[edi]
    cmp al,' '
    jne gtnOk
;
    dec edi
    jmp gtnLoop

gtnOk:
    inc edi
    xor al,al
    stosb
;
    LeaveSection ds:tarr_section
    clc
    jmp gtnDone

gtnFail:
    LeaveSection ds:tarr_section
    stc

gtnDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
serv_get_thread_name  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GrowProcArr
;
;           DESCRIPTION:    Grow process array
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowProcArr   Proc near
    push es
    pushad
;
    mov eax,flat_sel
    mov es,eax
;
    mov ecx,ds:parr_size
    mov ebp,ecx
    inc ecx
    shl ecx,1
    mov ds:parr_size,ecx
;
    mov eax,ecx
    shl eax,1
    AllocateSmallLinear
    mov edi,edx
;
    or ebx,ebx
    jz gpraCopied
;
    push ecx
    push edx
;
    mov ebx,proc_arr_sel
    GetSelectorBaseSize
    mov esi,edx
    mov ecx,ebp
    rep movs word ptr es:[edi],es:[esi]
;
    FreeLinear
;
    pop edx
    pop ecx

gpraCopied:
    push ecx
    sub ecx,ebp
    xor ax,ax
    rep stosw
    pop ecx
;
    mov bx,proc_arr_sel
    shl ecx,1
    CreateDataSelector32
;
    popad
    pop es
    ret
GrowProcArr   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GrowProgArr
;
;           DESCRIPTION:    Grow program array
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowProgArr   Proc near
    push es
    pushad
;
    mov eax,flat_sel
    mov es,eax
;
    mov ecx,ds:aarr_size
    mov ebp,ecx
    inc ecx
    shl ecx,1
    mov ds:aarr_size,ecx
;
    mov eax,ecx
    shl eax,1
    AllocateSmallLinear
    mov edi,edx
;
    or ebx,ebx
    jz gpaCopied
;
    push ecx
    push edx
;
    mov ebx,prog_arr_sel
    GetSelectorBaseSize
    mov esi,edx
    mov ecx,ebp
    rep movs word ptr es:[edi],es:[esi]
;
    FreeLinear
;
    pop edx
    pop ecx

gpaCopied:
    push ecx
    sub ecx,ebp
    xor ax,ax
    rep stosw
    pop ecx
;
    mov bx,prog_arr_sel
    shl ecx,1
    CreateDataSelector32
;
    popad
    pop es
    ret
GrowProgArr   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GrowModArr
;
;           DESCRIPTION:    Grow module array
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowModArr   Proc near
    push es
    pushad
;
    mov eax,flat_sel
    mov es,eax
;
    mov ecx,ds:marr_size
    mov ebp,ecx
    inc ecx
    shl ecx,1
    mov ds:marr_size,ecx
;
    mov eax,ecx
    shl eax,1
    AllocateSmallLinear
    mov edi,edx
;
    or ebx,ebx
    jz gmaCopied
;
    push ecx
    push edx
;
    mov ebx,mod_arr_sel
    GetSelectorBaseSize
    mov esi,edx
    mov ecx,ebp
    rep movs word ptr es:[edi],es:[esi]
;
    FreeLinear
;
    pop edx
    pop ecx

gmaCopied:
    push ecx
    sub ecx,ebp
    xor ax,ax
    rep stosw
    pop ecx
;
    mov bx,mod_arr_sel
    shl ecx,1
    CreateDataSelector32
;
    popad
    pop es
    ret
GrowModArr   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetThreadCount
;
;           DESCRIPTION:    Get thread count
;
;           RETURNS:        EAX            Thread count      
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_count_name DB 'Get Thread Count',0

get_thread_count    Proc far
    push ds
;
    mov eax,SEG data
    mov ds,eax
    mov eax,ds:tarr_count
;
    pop ds
    ret
get_thread_count    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateThreadId
;
;           DESCRIPTION:    Create thread ID
;
;           PARAMETERS:     ES       Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_thread_id_name DB 'Create Thread Id', 0

create_thread_id    Proc far
    push ds
    push fs
    push gs
    pushad
;    
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:tarr_section
;
    mov ax,ds:task_id
;
    mov ecx,ds:tarr_size
    or ecx,ecx
    stc
    jz ctidSave
;
    mov edx,thread_arr_sel
    mov fs,edx

ctidRetry:
    xor ebx,ebx

ctidLoop:
    mov dx,fs:[ebx]
    or dx,dx
    jz ctidNext
;
    mov gs,edx
    cmp ax,gs:p_id
    jne ctidNext
;
    inc ax
    and ax,7FFFh
    jnz ctidRetry
;
    inc ax
    jmp ctidRetry

ctidNext:
    add ebx,2
    loop ctidLoop

ctidSave:
    mov es:p_id,ax
    inc ax
    and ax,7FFFh
    jnz ctidNextOk
;
    inc ax

ctidNextOk:
    mov ds:task_id,ax
;
    LeaveSection ds:tarr_section
;
    popad
    pop gs
    pop fs
    pop ds
    ret
create_thread_id    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyCreateThread
;
;           DESCRIPTION:    Notify create thread
;
;           PARAMETERS:     ES       Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_create_thread_name DB 'Notify Create Thread', 0

notify_create_thread    Proc far
    push ds
    push fs
    push eax
    push ebx
    push ecx
    push edx
;    
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:tarr_section
;
    mov eax,ds:tarr_size
    mov ebx,ds:tarr_count
    cmp eax,ebx
    jne ctScan
;
    call GrowThreadArr

ctScan:
    mov eax,thread_arr_sel
    mov fs,eax
    mov ecx,ds:tarr_size
    sub ecx,ebx
    
ctLoop1:
    mov ax,fs:[2*ebx]
    or ax,ax
    jz ctOk
;
    inc ebx
    loop ctLoop1
;
    xor ebx,ebx
    mov ecx,ds:tarr_count

ctLoop2:
    mov ax,fs:[2*ebx]
    or ax,ax
    jz ctOk
;
    inc ebx
    loop ctLoop2
;
    int 3

ctOk:
    mov fs:[2*ebx],es
;
    inc ds:tarr_count
    LeaveSection ds:tarr_section
;
    mov es:p_index,bx
    shl ebx,16
    mov bx,es:p_id
    mov dx,REQ_CREATE_THREAD
    call AddEntry
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
notify_create_thread    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyTerminateThread
;
;           DESCRIPTION:    Terminate thread callback
;
;           PARAMETERS:     ES     Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_terminate_thread_name DB 'Notify Terminate Thread', 0

notify_terminate_thread    Proc far
    push ds
    push fs
    push eax
    push ebx
    push edx
;
    mov eax,SEG data
    mov ds,eax
    mov eax,thread_arr_sel
    mov fs,eax
;
    movzx ebx,es:p_index
    xor dx,dx
    mov eax,es
;    
    EnterSection ds:tarr_section
    xchg dx,fs:[2*ebx]
    dec ds:tarr_count
    LeaveSection ds:tarr_section
;
    cmp ax,dx
    je ttOk
;
    int 3

ttOk:
    shl ebx,16
    mov bx,es:p_id
    mov dx,REQ_TERMINATE_THREAD
    call AddEntry
;
    pop edx
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
notify_terminate_thread    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ThreadIndexToSel
;
;           DESCRIPTION:    Convert thread number to thread selector
;
;           PARAMETERS:     AX              THREAD #
;
;           RETURNS:        NC              THREAD EXISTS
;                               AX          Thread sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ThreadIndexToSel    Proc near
    push ds
    push es
    push ebx
    push ecx
    push edx
;
    movzx edx,ax
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:tarr_section
;
    mov ecx,ds:tarr_size
    or ecx,ecx
    stc
    jz titsDone
;
    mov eax,thread_arr_sel
    mov es,eax
    xor ebx,ebx

titsLoop:
    mov ax,es:[ebx]
    or ax,ax
    jz titsNext
;
    or edx,edx
    clc
    jz titsDone
;
    dec edx

titsNext:
    add ebx,2
    loop titsLoop
;
    stc

titsDone:
    LeaveSection ds:tarr_section
;
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
ThreadIndexToSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ThreadIdToSel
;
;           DESCRIPTION:    Convert thread id to thread selector
;
;           PARAMETERS:     AX              Thread ID
;
;           RETURNS:        NC              THREAD EXISTS
;                               AX          Thread sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ThreadIdToSel    Proc near
    push ds
    push es
    push fs
    push ebx
    push ecx
    push edx
;
    mov dx,ax
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:tarr_section
;
    mov ecx,ds:tarr_size
    or ecx,ecx
    stc
    jz tidtsDone
;
    mov eax,thread_arr_sel
    mov es,eax
    xor ebx,ebx

tidtsLoop:
    mov ax,es:[ebx]
    or ax,ax
    jz tidtsNext
;
    mov fs,eax
    cmp dx,fs:p_id
    clc
    je tidtsDone

tidtsNext:
    add ebx,2
    loop tidtsLoop
;
    stc

tidtsDone:
    LeaveSection ds:tarr_section
;
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
    pop ds
    ret
ThreadIdToSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProcessCount
;
;           DESCRIPTION:    Get process count
;
;           RETURNS:        EAX            Process count      
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_process_count_name DB 'Get Process Count',0

get_process_count    Proc far
    push ds
;
    mov eax,SEG data
    mov ds,eax
    mov eax,ds:parr_count
;
    pop ds
    ret
get_process_count    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ProcessCreated
;
;           DESCRIPTION:    Notify create process
;
;           PARAMETERS:     BX         Process sel
;
;           RETURNS:        AX         PID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_created_name DB 'Notify Create Process', 0

process_created    Proc far
    push ds
    push es
    push fs
    push gs
    push ebx
    push ecx
    push edx
    push edi
;    
    mov es,ebx
    mov edi,OFFSET pf_wait_arr
    mov ecx,MAX_PROCESS_WAITS
    xor ax,ax
    rep stosw
;
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:parr_section
;
    mov ax,ds:proc_id
;
    mov ecx,ds:parr_size
    or ecx,ecx
    stc
    jz cpridSave
;
    mov edx,proc_arr_sel
    mov fs,edx

cpridRetry:
    xor ebx,ebx

cpridLoop:
    mov dx,fs:[ebx]
    or dx,dx
    jz cpridNext
;
    mov gs,edx
    cmp ax,gs:pf_id
    jne cpridNext
;
    inc ax
    and ax,7FFFh
    jnz cpridRetry
;
    inc ax
    jmp cpridRetry

cpridNext:
    add ebx,2
    loop cpridLoop

cpridSave:
    mov es:pf_id,ax
    inc ax
    and ax,7FFFh
    jnz cpridNextOk
;
    inc ax

cpridNextOk:
    mov ds:proc_id,ax
;
    mov eax,ds:parr_size
    mov ebx,ds:parr_count
    cmp eax,ebx
    jne cprScan
;
    call GrowProcArr

cprScan:
    mov eax,proc_arr_sel
    mov fs,eax
    mov ecx,ds:parr_size
    sub ecx,ebx
    
cprLoop1:
    mov ax,fs:[2*ebx]
    or ax,ax
    jz cprOk
;
    inc ebx
    loop cprLoop1
;
    xor ebx,ebx
    mov ecx,ds:parr_count

cprLoop2:
    mov ax,fs:[2*ebx]
    or ax,ax
    jz cprOk
;
    inc ebx
    loop cprLoop2
;
    int 3

cprOk:
    mov fs:[2*ebx],es
;
    inc ds:parr_count
    LeaveSection ds:parr_section
;
    mov es:pf_index,bx
    shl ebx,16
    mov bx,es:pf_id
    mov dx,REQ_CREATE_PROCESS
    call AddEntry
;
    mov ax,es:pf_id
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop gs
    pop fs
    pop es
    pop ds
    ret
process_created    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ProcessTerminated
;
;           DESCRIPTION:    Terminate process callback
;
;           PARAMETERS:     BX         Process sel
;                           AX         Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_terminated_name DB 'Notify Terminate Process', 0

process_terminated    Proc far
    push ds
    push es
    push fs
    push eax
    push ebx
    push ecx
    push edx
    push edi
;
    mov es,ebx
    mov eax,SEG data
    mov ds,eax
    mov eax,proc_arr_sel
    mov fs,eax
;
    movzx ebx,es:pf_index
    xor dx,dx
    mov eax,es
;    
    EnterSection ds:parr_section
    xchg dx,fs:[2*ebx]
    dec ds:parr_count
;
    mov ecx,MAX_PROCESS_WAITS
    mov edi,OFFSET pf_wait_arr

ptWaitLoop:
    mov bx,es:[edi]
    or bx,bx
    jz ptWaitNext
;
    push es
    mov es,ebx
    SignalWait
    pop es

ptWaitNext:
    add edi,2
    loop ptWaitLoop
;
    LeaveSection ds:parr_section
;
    cmp ax,dx
    je tprOk
;
    int 3

tprOk:
    movzx ebx,es:pf_index
    shl ebx,16
    mov bx,es:pf_id
    mov dx,REQ_TERMINATE_PROCESS
    call AddEntry
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop fs
    pop es
    pop ds
    ret
process_terminated    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetProcessId
;
;           DESCRIPTION:    Convert process # to process Id
;
;           PARAMETERS:     EAX              Process #
;
;           RETURNS:        NC              Process exists
;                               EAX          Id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_process_id_name DB 'Get Process Id', 0

get_process_id    Proc far
    push ds
    push es
    push ebx
    push ecx
    push edx
;
    mov edx,eax
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:parr_section
;
    mov ecx,ds:parr_size
    or ecx,ecx
    stc
    jz gpriDone
;
    mov eax,proc_arr_sel
    mov es,eax
    xor ebx,ebx

gpriLoop:
    mov ax,es:[ebx]
    or ax,ax
    jz gpriNext
;
    or edx,edx
    jz gpriok
;
    dec edx

gpriNext:
    add ebx,2
    loop gpriLoop
;
    stc
    jmp gpriDone

gpriOk:
    mov es,ax
    movzx eax,es:pf_id
    clc

gpriDone:
    LeaveSection ds:parr_section
;
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
get_process_id    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LockedGetProcSel
;
;           DESCRIPTION:    Get process sel from ID
;
;           PARAMETERS:     EBX             Process ID
;                           DS              Data sel
;
;           RETURNS:        NC              Process Id found
;                               EBX         Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockedGetProcSel    Proc near
    push es
    push fs
    push eax
    push ecx
    push edx
;
    mov dx,bx
    mov ecx,ds:parr_size
    or ecx,ecx
    stc
    jz lgprsDone
;
    mov eax,proc_arr_sel
    mov es,eax
    xor ebx,ebx

lgprsLoop:
    mov ax,es:[ebx]
    or ax,ax
    jz lgprsNext
;
    mov fs,eax
    cmp dx,fs:pf_id
    jne lgprsNext
;
    mov ebx,fs
    clc
    jmp lgprsDone

lgprsNext:
    add ebx,2
    loop lgprsLoop
;
    stc

lgprsDone:
    pop edx
    pop ecx
    pop eax
    pop fs
    pop es
    ret
LockedGetProcSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ProcessIdToSel
;
;           DESCRIPTION:    Convert process id to process selector
;
;           PARAMETERS:     EBX             Process ID
;
;           RETURNS:        NC              Process Id found
;                               EBX         Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_id_to_sel_name DB 'Process Id To Sel', 0

process_id_to_sel    Proc far
    push ds
    push eax
;
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:parr_section
    call LockedGetProcSel
    LeaveSection ds:parr_section
;
    pop eax
    pop ds
    ret
process_id_to_sel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForProcEnd
;
;           DESCRIPTION:    Start a wait for process end event
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_proc_end PROC far
    push ds
    push fs
    push eax
    push ebx
    push ecx
;
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:parr_section
;
    movzx ebx,es:pew_proc_id
    call LockedGetProcSel
    jnc bwpeWait
;
    SignalWait
    jmp bwpeDone

bwpeWait:
    mov fs,ebx
    mov ecx,MAX_PROCESS_WAITS
    mov ebx,OFFSET pf_wait_arr

bwpeLoop:
    mov ax,fs:[ebx]
    or ax,ax
    jnz bwpeNext
;
    mov fs:[ebx],es
    jmp bwpeDone

bwpeNext:
    add ebx,2
    loop bwpeLoop
;
    SignalWait

bwpeDone:
    LeaveSection ds:parr_section
;
    pop ecx
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
start_wait_for_proc_end Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForProcEnd
;
;           DESCRIPTION:    Stop a wait for process end event
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_proc_end  PROC far
    push ds
    push fs
    push eax
    push ebx
    push ecx
;
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:parr_section
;
    movzx ebx,es:pew_proc_id
    call LockedGetProcSel
    jc ewpeDone
;
    mov fs,ebx
    mov ecx,MAX_PROCESS_WAITS
    mov ebx,OFFSET pf_wait_arr

ewpeLoop:
    cmp ax,fs:[ebx]
    jne ewpeNext
;
    xor ax,ax
    mov fs:[ebx],ax
    jmp ewpeDone

ewpeNext:
    add ebx,2
    loop ewpeLoop

ewpeDone:
    LeaveSection ds:parr_section
;
    pop ecx
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
stop_wait_for_proc_end Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DummyClearProcEnd
;
;           DESCRIPTION:    Clear process end event
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy_clear_proc_end    PROC far
    ret
dummy_clear_proc_end Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsProcEndIdle
;
;           DESCRIPTION:    Check if proc end is idle
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_proc_end_idle    PROC far
    push eax
    push ebx
;
    movzx ebx,es:pew_proc_id
    IsProcessRunning
;
    pop ebx
    pop eax
    ret
is_proc_end_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AddWaitForProcEnd
;
;   DESCRIPTION:    Add a wait for process end
;
;   PARAMETERS:     AX      Process handle
;                   BX      Wait handle
;                   ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_proc_end_name      DB 'Add Wait For Process End',0

add_wait_proc_tab:
awp0 DD OFFSET start_wait_for_proc_end,      SEG code
awp1 DD OFFSET stop_wait_for_proc_end,       SEG code
awp2 DD OFFSET dummy_clear_proc_end,         SEG code
awp3 DD OFFSET is_proc_end_idle,             SEG code

add_wait_for_proc_end   PROC far
    push ds
    push es
    push eax
    push dx
    push edi
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE proc_end_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_proc_tab
    AddWait
    pop ax
    jc awpeDone
;    
    mov es:pew_proc_id,ax

awpeDone:
    pop edi
    pop dx
    pop eax
    pop es
    pop ds
    ret
add_wait_for_proc_end   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProgramCount
;
;           DESCRIPTION:    Get program count
;
;           RETURNS:        EAX            Program count      
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_program_count_name DB 'Get Program Count',0

get_program_count    Proc far
    push ds
;
    mov eax,SEG data
    mov ds,eax
    mov eax,ds:aarr_count
;
    pop ds
    ret
get_program_count    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ProgramCreated
;
;           DESCRIPTION:    Notify create program
;
;           PARAMETERS:     BX         Program sel
;
;           RETURNS:        AX         PID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

program_created_name DB 'Notify Create Program', 0

program_created    Proc far
    push ds
    push es
    push fs
    push gs
    push ebx
    push ecx
    push edx
;    
    mov es,ebx
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:aarr_section
;
    mov ax,ds:prog_id
;
    mov ecx,ds:aarr_size
    or ecx,ecx
    stc
    jz cpidSave
;
    mov edx,prog_arr_sel
    mov fs,edx

cpidRetry:
    xor ebx,ebx

cpidLoop:
    mov dx,fs:[ebx]
    or dx,dx
    jz cpidNext
;
    mov gs,edx
    cmp ax,gs:pr_id
    jne cpidNext
;
    inc ax
    and ax,7FFFh
    jnz cpidRetry
;
    inc ax
    jmp cpidRetry

cpidNext:
    add ebx,2
    loop cpidLoop

cpidSave:
    mov es:pr_id,ax
    inc ax
    and ax,7FFFh
    jnz cpidNextOk
;
    inc ax

cpidNextOk:
    mov ds:prog_id,ax
;
    mov eax,ds:aarr_size
    mov ebx,ds:aarr_count
    cmp eax,ebx
    jne cpScan
;
    call GrowProgArr

cpScan:
    mov eax,prog_arr_sel
    mov fs,eax
    mov ecx,ds:aarr_size
    sub ecx,ebx
    
cpLoop1:
    mov ax,fs:[2*ebx]
    or ax,ax
    jz cpOk
;
    inc ebx
    loop cpLoop1
;
    xor ebx,ebx
    mov ecx,ds:aarr_count

cpLoop2:
    mov ax,fs:[2*ebx]
    or ax,ax
    jz cpOk
;
    inc ebx
    loop cpLoop2
;
    int 3

cpOk:
    mov fs:[2*ebx],es
;
    inc ds:aarr_count
    LeaveSection ds:aarr_section
;
    mov es:pr_index,bx
    shl ebx,16
    mov bx,es:pr_id
    mov dx,REQ_CREATE_PROGRAM
    call AddEntry
;
    mov ax,es:pr_id
;
    pop edx
    pop ecx
    pop ebx
    pop gs
    pop fs
    pop es
    pop ds
    ret
program_created    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ProgramTerminated
;
;           DESCRIPTION:    Terminate program callback
;
;           PARAMETERS:     BX         Program sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

program_terminated_name DB 'Notify Terminate Program', 0

program_terminated    Proc far
    push ds
    push es
    push fs
    push eax
    push ebx
    push edx
;
    mov es,ebx
    mov eax,SEG data
    mov ds,eax
    mov eax,prog_arr_sel
    mov fs,eax
;
    movzx ebx,es:pr_index
    xor dx,dx
    mov eax,es
;    
    EnterSection ds:aarr_section
    xchg dx,fs:[2*ebx]
    dec ds:aarr_count
    LeaveSection ds:aarr_section
;
    cmp ax,dx
    je tpOk
;
    int 3

tpOk:
    shl ebx,16
    mov bx,es:pr_id
    mov dx,REQ_TERMINATE_PROGRAM
    call AddEntry
;
    pop edx
    pop ebx
    pop eax
    pop fs
    pop es
    pop ds
    ret
program_terminated    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetProgramId
;
;           DESCRIPTION:    Convert program # to program Id
;
;           PARAMETERS:     EAX              Program #
;
;           RETURNS:        NC              Program exists
;                               AX          Id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_program_id_name DB 'Get Program Id', 0

get_program_id    Proc far
    push ds
    push es
    push ebx
    push ecx
    push edx
;
    mov edx,eax
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:aarr_section
;
    mov ecx,ds:aarr_size
    or ecx,ecx
    stc
    jz gpiDone
;
    mov eax,prog_arr_sel
    mov es,eax
    xor ebx,ebx

gpiLoop:
    mov ax,es:[ebx]
    or ax,ax
    jz gpiNext
;
    or edx,edx
    jz gpiok
;
    dec edx

gpiNext:
    add ebx,2
    loop gpiLoop
;
    stc
    jmp gpiDone

gpiOk:
    mov es,ax
    mov ax,es:pr_id
    clc

gpiDone:
    LeaveSection ds:aarr_section
;
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
get_program_id    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetProgramSel
;
;           DESCRIPTION:    Convert program id to program selector
;
;           PARAMETERS:     EBX             Program ID
;
;           RETURNS:        NC              Program Id
;                               AX          Program sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


get_program_sel_name DB 'Get Program Sel', 0

get_program_sel    Proc far
    push ds
    push es
    push fs
    push ebx
    push ecx
    push edx
;
    mov dx,bx
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:aarr_section
;
    mov ecx,ds:aarr_size
    or ecx,ecx
    stc
    jz gpsDone
;
    mov eax,prog_arr_sel
    mov es,eax
    xor ebx,ebx

gpsLoop:
    mov ax,es:[ebx]
    or ax,ax
    jz gpsNext
;
    mov fs,eax
    cmp dx,fs:pr_id
    clc
    je gpsDone

gpsNext:
    add ebx,2
    loop gpsLoop
;
    stc

gpsDone:
    LeaveSection ds:aarr_section
;
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
    pop ds
    ret
get_program_sel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleCount
;
;           DESCRIPTION:    Get module count
;
;           RETURNS:        EAX            Module count      
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_count_name DB 'Get Module Count',0

get_module_count    Proc far
    push ds
;
    mov eax,SEG data
    mov ds,eax
    mov eax,ds:marr_count
;
    pop ds
    ret
get_module_count    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ModuleLoaded
;
;           DESCRIPTION:    Notify module loaded
;
;           PARAMETERS:     BX         Module sel
;
;           RETURNS:        AX         ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

module_loaded_name DB 'Notify Module Loaded', 0

module_loaded    Proc far
    push ds
    push es
    push fs
    push gs
    push ebx
    push ecx
    push edx
;    
    mov es,ebx
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:marr_section
;
    mov ax,ds:module_id
;
    mov ecx,ds:marr_size
    or ecx,ecx
    stc
    jz mlSave
;
    mov edx,mod_arr_sel
    mov fs,edx

mlRetry:
    xor ebx,ebx

mlLoop:
    mov dx,fs:[ebx]
    or dx,dx
    jz mlNext
;
    mov gs,edx
    cmp ax,gs:mod_id
    jne mlNext
;
    inc ax
    and ax,7FFFh
    jnz mlRetry
;
    inc ax
    jmp mlRetry

mlNext:
    add ebx,2
    loop mlLoop

mlSave:
    mov es:mod_id,ax
    inc ax
    and ax,7FFFh
    jnz mlNextOk
;
    inc ax

mlNextOk:
    mov ds:module_id,ax
;
    mov eax,ds:marr_size
    mov ebx,ds:marr_count
    cmp eax,ebx
    jne mlScan
;
    call GrowModArr

mlScan:
    mov eax,mod_arr_sel
    mov fs,eax
    mov ecx,ds:marr_size
    sub ecx,ebx
    
mlLoop1:
    mov ax,fs:[2*ebx]
    or ax,ax
    jz mlOk
;
    inc ebx
    loop mlLoop1
;
    xor ebx,ebx
    mov ecx,ds:marr_count

mlLoop2:
    mov ax,fs:[2*ebx]
    or ax,ax
    jz mlOk
;
    inc ebx
    loop mlLoop2
;
    int 3

mlOk:
    mov fs:[2*ebx],es
;
    inc ds:marr_count
    LeaveSection ds:marr_section
;
    mov es:mod_index,bx
    shl ebx,16
    mov bx,es:mod_id
;    mov dx,REQ_CREATE_PROCESS
;    call AddEntry
;
    mov ax,es:mod_id
;
    pop edx
    pop ecx
    pop ebx
    pop gs
    pop fs
    pop es
    pop ds
    ret
module_loaded    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ModuleUnloaded
;
;           DESCRIPTION:    Module unloaded callback
;
;           PARAMETERS:     BX         Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

module_unloaded_name DB 'Notify Module Unloaded', 0

module_unloaded    Proc far
    push ds
    push es
    push fs
    push eax
    push ebx
    push edx
;
    mov es,ebx
    mov eax,SEG data
    mov ds,eax
    mov eax,mod_arr_sel
    mov fs,eax
;
    movzx ebx,es:mod_index
    xor dx,dx
    mov eax,es
;    
    EnterSection ds:marr_section
    xchg dx,fs:[2*ebx]
    dec ds:marr_count
    LeaveSection ds:marr_section
;
    cmp ax,dx
    je muOk
;
    int 3

muOk:
    movzx ebx,es:mod_index
    shl ebx,16
    mov bx,es:mod_id
;    mov dx,REQ_TERMINATE_PROCESS
;    call AddEntry
;
    pop edx
    pop ebx
    pop eax
    pop fs
    pop es
    pop ds
    ret
module_unloaded    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetModuleId
;
;           DESCRIPTION:    Convert module # to module Id
;
;           PARAMETERS:     EAX             Module #
;
;           RETURNS:        NC              Module exists
;                               EAX          Id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_id_name DB 'Get Module Id', 0

get_module_id    Proc far
    push ds
    push es
    push ebx
    push ecx
    push edx
;
    mov edx,eax
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:marr_section
;
    mov ecx,ds:marr_size
    or ecx,ecx
    stc
    jz gmiDone
;
    mov eax,mod_arr_sel
    mov es,eax
    xor ebx,ebx

gmiLoop:
    mov ax,es:[ebx]
    or ax,ax
    jz gmiNext
;
    or edx,edx
    jz gmiok
;
    dec edx

gmiNext:
    add ebx,2
    loop gmiLoop
;
    stc
    jmp gmiDone

gmiOk:
    mov es,ax
    movzx eax,es:mod_id
    clc

gmiDone:
    LeaveSection ds:marr_section
;
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
get_module_id    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LockedGetModSel
;
;           DESCRIPTION:    Get module sel from ID
;
;           PARAMETERS:     EBX             Module ID
;                           DS              Data sel
;
;           RETURNS:        NC              Module Id found
;                               EBX         Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockedGetModSel    Proc near
    push es
    push fs
    push eax
    push ecx
    push edx
;
    mov dx,bx
    mov ecx,ds:marr_size
    or ecx,ecx
    stc
    jz lgprsDone
;
    mov eax,mod_arr_sel
    mov es,eax
    xor ebx,ebx

lgmsLoop:
    mov ax,es:[ebx]
    or ax,ax
    jz lgmsNext
;
    mov fs,eax
    cmp dx,fs:mod_id
    jne lgmsNext
;
    mov ebx,fs
    clc
    jmp lgmsDone

lgmsNext:
    add ebx,2
    loop lgmsLoop
;
    stc

lgmsDone:
    pop edx
    pop ecx
    pop eax
    pop fs
    pop es
    ret
LockedGetModSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ProcessIdToSel
;
;           DESCRIPTION:    Convert process id to process selector
;
;           PARAMETERS:     EBX             Module ID
;
;           RETURNS:        NC              Module Id found
;                               EBX         Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

module_id_to_sel_name DB 'Module Id To Sel', 0

module_id_to_sel    Proc far
    push ds
    push eax
;
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:marr_section
    call LockedGetModSel
    LeaveSection ds:marr_section
;
    pop eax
    pop ds
    ret
module_id_to_sel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ThreadToSel
;
;           DESCRIPTION:    Convert thread # (p_id) to selector
;
;           PARAMETERS:     BX      Thread #
;
;           RETURNS:        BX      Thread sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

thread_to_sel_name DB 'Thread To Sel',0

thread_to_sel   Proc far
    push eax
;
    mov ax,bx
    call ThreadIdToSel
    mov bx,ax
;
    pop eax
    ret
thread_to_sel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetThreadHandle
;
;           DESCRIPTION:    Get current thread handle
;
;           RETURNS:        EAX         Thread handle         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_handle_name  DB 'Get Thread Handle', 0

get_thread_handle    Proc far
    push es
;    
    GetThread
    mov es,eax
    movzx eax,es:p_id
;
    pop es
    ret
get_thread_handle       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetThreadState
;
;           DESCRIPTION:    Get state of a thread
;
;           PARAMETERS:     ES:(E)DI        BUFFER TO PUT STATE IN
;                           AX              THREAD #
;                           NC              THREAD EXISTS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_state_name DB 'Get Thread State',0

get_thread_state    Proc near
    push ds
    pushad
;    
    call ThreadIndexToSel
    jc get_state_done
;    
    mov ds,ax
    mov ax,ds:p_id
    mov es:[edi].st_id,ax
    mov esi,OFFSET thread_name
    mov ecx,32
    push edi
    add edi,OFFSET st_name
    rep movs byte ptr es:[edi],ds:[esi]
    pop edi
;       
    mov eax,ds:p_msb_tics
    mov es:[edi].st_time,eax
    mov eax,ds:p_lsb_tics
    mov es:[edi].st_time+4,eax
;
    push edi
    add edi,OFFSET st_list
    mov bx,ds    
    AddThreadState
    pop edi
;
    mov es:[edi].st_sel,cx
    mov es:[edi].st_offs,edx
    clc

get_state_done:
    popad
    pop ds
    ret
get_thread_state    Endp

get_thread_state16      Proc far
    push edi
    movzx edi,di
    call get_thread_state
    pop edi
    ret
get_thread_state16      Endp

get_thread_state32      Proc far
    call get_thread_state
    ret
get_thread_state32      Endp

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
;           NAME:           GetThreadActionState
;
;           DESCRIPTION:    Get action state of a thread
;
;           PARAMETERS:     ES:(E)DI        BUFFER TO PUT STATE IN
;                           AX              THREAD #
;                           NC              THREAD EXISTS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_action_state_name DB 'Get Thread Action State',0

get_thread_action_state    Proc near
    push ds
    push fs
    pushad
;    
    call ThreadIndexToSel
    jc get_action_state_done
;    
    mov ds,ax
    mov ax,ds:p_id
    mov es:[edi].ast_id,ax
    mov esi,OFFSET thread_name
    mov ecx,32
    push edi
    add edi,OFFSET ast_name
    rep movs byte ptr es:[edi],ds:[esi]
    pop edi
;    
    mov esi,OFFSET p_action_text
    mov ecx,32
    push edi
    add edi,OFFSET ast_action
    rep movs byte ptr es:[edi],ds:[esi]
    pop edi
;       
    mov eax,ds:p_msb_tics
    mov es:[edi].ast_time,eax
    mov eax,ds:p_lsb_tics
    mov es:[edi].ast_time+4,eax
;
    push edi
    add edi,OFFSET ast_list
    mov bx,ds
    AddThreadState
    pop edi
;
    mov es:[edi].ast_pos.sep_sel,cx
    mov dword ptr es:[edi].ast_pos.sep_offs,edx
    mov dword ptr es:[edi].ast_pos.sep_offs+4,0
    mov es:[edi].ast_count,0
;
    mov ds,ebx
    test word ptr ds:p_rflags+2,2
    jnz get_action_user_done
;
    mov ax,ds:p_cs
    cmp ax,flat_code_sel
    je get_action_app
;
    cmp ax,serv_code_sel
    jne get_action_not_app

get_action_app:   
    mov edx,edi
    add edx,OFFSET ast_user
    mov eax,dword ptr ds:p_rbp    
    jmp get_action_user_loop

get_action_not_app:    
    test ax,7
    jnz get_action_user_done
;
    mov ax,ds:p_ss
    mov fs,ax
    mov ecx,dword ptr ds:p_rsp
    cmp ecx,stack0_size
    jae get_action_user_done
;
    mov ecx,stack0_size
    mov eax,fs:[ecx-4]
    cmp eax,flat_data_sel    
    je get_action_user_cs
;
    cmp eax,serv_data_sel
    jne get_action_user_done

get_action_user_cs:    
    mov eax,fs:[ecx-12]
    cmp eax,flat_code_sel
    je get_action_user
;
    cmp eax,serv_code_sel
    jne get_action_user_done

get_action_user:
    mov edx,edi
    add edx,OFFSET ast_user
    mov eax,fs:[ecx-12]
    mov es:[edx].sep_sel,ax
    mov eax,fs:[ecx-16]
    mov dword ptr es:[edx].sep_offs,eax
    mov dword ptr es:[edx].sep_offs+4,0
    add edx,SIZE state_ep
    inc es:[edi].ast_count
;
    mov esi,fs:[ecx-8]
    call ReadFlatAppDword
    jc get_action_user_done

get_action_user_loop:
    mov esi,eax
    push esi
    add esi,24
    call ReadFlatAppDword
    pop esi
    jc get_action_user_done
;
    push esi
    mov esi,eax
    call ProbeFlatAppCode
    pop esi
    jnc get_action_user_save
;    
    push esi
    add esi,20
    call ReadFlatAppDword
    pop esi
    jc get_action_user_done
;
    push esi
    mov esi,eax
    call ProbeFlatAppCode
    pop esi
    jnc get_action_user_save
;
    xor eax,eax
    
get_action_user_save:    
    mov es:[edx].sep_sel,flat_code_sel
    mov dword ptr es:[edx].sep_offs,eax
    mov dword ptr es:[edx].sep_offs+4,0
    add edx,SIZE state_ep
    mov ax,es:[edi].ast_count
    inc ax
    mov es:[edi].ast_count,ax
    cmp ax,64
    jae get_action_user_done
;
    call ReadFlatAppDword
    or eax,eax
    jnz get_action_user_loop
        
get_action_user_done:    
    mov ax,es:[edi].ast_count
    cmp ax,2
    jb get_action_user_ok
;
    sub edx,SIZE state_ep
    mov eax,dword ptr es:[edx].sep_offs
    or eax,dword ptr es:[edx].sep_offs+4
    jnz get_action_user_ok
;
    dec es:[edi].ast_count        

get_action_user_ok:    
    clc

get_action_state_done:
    popad
    pop fs
    pop ds
    ret
get_thread_action_state    Endp

get_thread_action_state16      Proc far
    push edi
    movzx edi,di
    call get_thread_action_state
    pop edi
    ret
get_thread_action_state16      Endp

get_thread_action_state32      Proc far
    call get_thread_action_state
    ret
get_thread_action_state32      Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SuspendThread
;
;           DESCRIPTION:    Suspend thread (put it in debugger)
;
;           PARAMETER:          AX          Thread ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

suspend_thread_name     DB 'Suspend Thread',0

suspend_thread  PROC far
    push ds
    push es
    pushad
;
    call ThreadIdToSel
    jc suspend_thread_done
;    
    mov es,ax
    or es:p_flags,THREAD_FLAG_SUSPEND
    clc

suspend_thread_done:
    popad
    pop es
    pop ds
    ret
suspend_thread  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SuspendAndSignalThread
;
;           DESCRIPTION:    Suspend and signal thread (put it in debugger)
;
;           PARAMETER:          AX          Thread #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

suspend_and_signal_thread_name  DB 'Suspend and Signal Thread',0

suspend_and_signal_thread       PROC far
    push ds
    push es
    pushad
;
    call ThreadIdToSel
    jc suspend_signal_done
;
    mov bx,ax
    mov es,ax
    or es:p_flags,THREAD_FLAG_SUSPEND
    Signal
    clc

suspend_signal_done:
    popad
    pop es
    pop ds
    ret
suspend_and_signal_thread       ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Test gate
;
;           DESCRIPTION:    Test gate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_pr_name  DB 'Test Gate',0

test_pr       PROC far
    push eax
    mov eax,SIZE process_struc + 4
    AllocateSmallGlobalMem
;
    mov bx,es
    movzx ebx,bx
    call process_created
    ret
test_pr      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init_task
;
;       description:    Init task
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_task

init_task    Proc near
    push ds
    push es
    pushad
;
    mov eax,SEG data
    mov ds,eax
    mov ds:task_id,1
    mov ds:proc_id,1
    mov ds:prog_id,1
    mov ds:module_id,1
;
    mov ds:task_wr_ptr,0
    mov ds:task_wait_thread,0
    InitSection ds:task_section
;
    mov ds:tarr_size,0
    mov ds:tarr_count,0
    InitSection ds:tarr_section
;
    mov ds:parr_size,0
    mov ds:parr_count,0
    InitSection ds:parr_section
;
    mov ds:aarr_size,0
    mov ds:aarr_count,0
    InitSection ds:aarr_section
;
    mov ds:marr_size,0
    mov ds:marr_count,0
    InitSection ds:marr_section
;
    mov eax,1000h
    AllocateBigLinear
    mov ds:task_linear,edx
;
    AllocatePhysical64
    mov ds:task_phys,eax
    mov ds:task_phys+4,ebx
;
    or ax,867h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector32
    mov ds:task_sel,bx
;
    mov es,ebx
    xor edi,edi
    xor eax,eax
    mov ecx,400h
    rep stosd
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET create_thread_id
    mov edi,OFFSET create_thread_id_name
    xor cl,cl
    mov ax,create_thread_id_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_create_thread
    mov edi,OFFSET notify_create_thread_name
    xor cl,cl
    mov ax,notify_create_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_terminate_thread
    mov edi,OFFSET notify_terminate_thread_name
    xor cl,cl
    mov ax,notify_terminate_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET thread_to_sel
    mov edi,OFFSET thread_to_sel_name
    xor cl,cl
    mov ax,thread_to_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET process_created
    mov edi,OFFSET process_created_name
    xor cl,cl
    mov ax,process_created_nr
    RegisterOsGate
;
    mov esi,OFFSET process_terminated
    mov edi,OFFSET process_terminated_name
    xor cl,cl
    mov ax,process_terminated_nr
    RegisterOsGate
;
    mov esi,OFFSET process_id_to_sel
    mov edi,OFFSET process_id_to_sel_name
    xor cl,cl
    mov ax,process_id_to_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET get_process_id
    mov edi,OFFSET get_process_id_name
    xor cl,cl
    mov ax,get_process_id_nr
    RegisterOsGate
;
    mov esi,OFFSET program_created
    mov edi,OFFSET program_created_name
    xor cl,cl
    mov ax,program_created_nr
    RegisterOsGate
;
    mov esi,OFFSET program_terminated
    mov edi,OFFSET program_terminated_name
    xor cl,cl
    mov ax,program_terminated_nr
    RegisterOsGate
;
    mov esi,OFFSET get_program_sel
    mov edi,OFFSET get_program_sel_name
    xor cl,cl
    mov ax,get_program_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET get_program_id
    mov edi,OFFSET get_program_id_name
    xor cl,cl
    mov ax,get_program_id_nr
    RegisterOsGate
;
    mov esi,OFFSET module_loaded
    mov edi,OFFSET module_loaded_name
    xor cl,cl
    mov ax,module_loaded_nr
    RegisterOsGate
;
    mov esi,OFFSET module_unloaded
    mov edi,OFFSET module_unloaded_name
    xor cl,cl
    mov ax,module_unloaded_nr
    RegisterOsGate
;
    mov esi,OFFSET module_id_to_sel
    mov edi,OFFSET module_id_to_sel_name
    xor cl,cl
    mov ax,module_id_to_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET get_module_id
    mov edi,OFFSET get_module_id_name
    xor cl,cl
    mov ax,get_module_id_nr
    RegisterOsGate
;
    mov esi,OFFSET test_pr
    mov edi,OFFSET test_pr_name
    xor dx,dx
    mov ax,test_gate_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_thread_count
    mov edi,OFFSET get_thread_count_name
    xor dx,dx
    mov ax,get_thread_count_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_thread_handle
    mov edi,OFFSET get_thread_handle_name
    xor dx,dx
    mov ax,get_thread_handle_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_thread_state16
    mov esi,OFFSET get_thread_state32
    mov edi,OFFSET get_thread_state_name
    mov dx,virt_es_in
    mov ax,get_thread_state_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_thread_action_state16
    mov esi,OFFSET get_thread_action_state32
    mov edi,OFFSET get_thread_action_state_name
    mov dx,virt_es_in
    mov ax,get_thread_action_state_nr
    RegisterUserGate
;
    mov esi,OFFSET suspend_thread
    mov edi,OFFSET suspend_thread_name
    xor dx,dx
    mov ax,suspend_thread_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET suspend_and_signal_thread
    mov edi,OFFSET suspend_and_signal_thread_name
    xor dx,dx
    mov ax,suspend_and_signal_thread_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_process_count
    mov edi,OFFSET get_process_count_name
    xor dx,dx
    mov ax,get_process_count_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_proc_end
    mov edi,OFFSET add_wait_for_proc_end_name
    xor dx,dx
    mov ax,add_wait_for_proc_end_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_program_count
    mov edi,OFFSET get_program_count_name
    xor dx,dx
    mov ax,get_program_count_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_module_count
    mov edi,OFFSET get_module_count_name
    xor dx,dx
    mov ax,get_module_count_nr
    RegisterBimodalUserGate
;
    popad
    pop es
    pop ds
    ret
init_task    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init_task_server
;
;       description:    Init task server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_task_server

init_task_server    Proc near
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET get_task_queue
    mov edi,OFFSET get_task_queue_name
    xor cl,cl
    mov ax,uacpi_get_task_queue_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET wait_task_queue
    mov edi,OFFSET wait_task_queue_name
    xor cl,cl
    mov ax,uacpi_wait_task_queue_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET serv_thread_state
    mov edi,OFFSET serv_thread_state_name
    xor cl,cl
    mov ax,uacpi_get_thread_state_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET serv_get_thread_name
    mov edi,OFFSET serv_get_thread_name_name
    xor cl,cl
    mov ax,uacpi_get_thread_name_nr
    RegisterPrivateServGate
    ret
init_task_server    Endp

code    ENDS

    END
