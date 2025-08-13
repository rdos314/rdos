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


    .386p

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

data    SEGMENT byte public 'DATA'

tarr_size          DD ?
tarr_count         DD ?
tarr_section       section_typ <>

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
;           NAME:           CreateThread
;
;           DESCRIPTION:    Create thread callback
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_thread    Proc far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push edx
;    
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:tarr_section
    mov eax,ds:tarr_size
    mov ebx,ds:tarr_count
    cmp eax,ebx
    jne ctScan
;
    call GrowThreadArr

ctScan:
    mov eax,thread_arr_sel
    mov es,eax
    mov ecx,ds:tarr_size
    sub ecx,ebx
    
ctLoop1:
    mov ax,es:[2*ebx]
    or ax,ax
    jz ctOk
;
    inc ebx
    loop ctLoop1
;
    xor ebx,ebx
    mov ecx,ds:tarr_count

ctLoop2:
    mov ax,es:[2*ebx]
    or ax,ax
    jz ctOk
;
    inc ebx
    loop ctLoop2
;
    int 3

ctOk:
    GetThread
    mov es:[2*ebx],ax
;
    inc ds:tarr_count
    LeaveSection ds:tarr_section
;
    mov es,eax
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
    pop es    
    pop ds
    ret
create_thread    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TerminateThread
;
;           DESCRIPTION:    Terminate thread callback
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

terminate_thread    Proc far
    push ds
    push es
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
    GetThread
    mov es,eax
    movzx ebx,es:p_index
    xor dx,dx
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
    pop es    
    pop ds
    ret
terminate_thread    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetThreadState
;
;       DESCRIPTION:    Get thread state
;
;       PARAMETERS:     EBX            Handle
;                       ES:EDI         State buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_state_name DB 'Get Thread State', 0

get_thread_state   Proc far
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
    jae gtsFail
;
    mov ax,fs:[2*esi]
    or ax,ax
    jz gtsFail
;
    mov fs,eax
    mov ax,fs:p_id
    cmp ax,bx
    jne gtsFail
;
    mov ax,fs:p_prio
    shr ax,1
    mov es:[edi].ths_prio,ax
;
    mov al,fs:p_irq
    mov es:[edi].ths_irq,al

gtsRetry:
    mov ebx,fs:p_msb_tics
    mov eax,fs:p_lsb_tics
    cmp ebx,fs:p_msb_tics
    jne gtsRetry
;
    mov es:[edi].ths_tics,eax
    mov es:[edi].ths_tics+4,ebx
;
    mov ax,fs:p_core
    or ax,ax
    jz gtsNoCore
;
    mov fs,eax
    mov ax,fs:cs_id

gtsNoCore:
    mov es:[edi].ths_core,ax
;
    LeaveSection ds:tarr_section
    clc
    jmp gtsDone

gtsFail:
    LeaveSection ds:tarr_section
    stc

gtsDone:
    pop esi
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
get_thread_state  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetThreadName
;
;       DESCRIPTION:    Get thread name
;
;       PARAMETERS:     EBX            Thread ID
;                       ES:EDI         Name buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_name_name DB 'Get Thread Name', 0

get_thread_name   Proc far
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
get_thread_name  Endp

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
    mov ds:task_wr_ptr,0
    mov ds:task_wait_thread,0
    InitSection ds:task_section
;
    mov ds:tarr_size,0
    mov ds:tarr_count,0
    InitSection ds:tarr_section
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
    mov edi,OFFSET create_thread
    HookCreateThread
;
    mov edi,OFFSET terminate_thread
    HookTerminateThread
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
    mov esi,OFFSET get_thread_state
    mov edi,OFFSET get_thread_state_name
    xor cl,cl
    mov ax,uacpi_get_thread_state_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET get_thread_name
    mov edi,OFFSET get_thread_name_name
    xor cl,cl
    mov ax,uacpi_get_thread_name_nr
    RegisterPrivateServGate
    ret
init_task_server    Endp

code    ENDS

    END
