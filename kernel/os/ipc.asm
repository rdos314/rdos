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
; IPC.ASM
; IPC for local & IP based messaging
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE int.def
INCLUDE system.inc
INCLUDE ip.inc
INCLUDE ipc.inc
INCLUDE ..\handle.inc

ipc_handle_seg  STRUC

ipc_handle_base     handle_header <>
ipc_handle_next     DW ?
ipc_handle_sel      DW ?

ipc_handle_seg  ENDS

data    SEGMENT byte public 'DATA'

ipc_section             section_typ <>
ipc_mailslot_list       DW ?
super_host_list     DW ?

data    ENDS

code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code

    extrn SendLocal:near
    extrn init_smp:near


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SelectorToLinear
;
;           DESCRIPTION:    Convert selector:offset pair into linear address & size
;
;           PARAMETERS:         ES:EDI  Selector:offset
;                           ECX         Wanted size
;
;           RETURNS:        EDX         Linear address
;                           ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SelectorToLinear

SelectorToLinear    PROC near
    push ds
    push eax
    push si
;
    mov si,es
    test si,4
    jz selector_to_linear_gdt

selector_to_linear_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp selector_to_linear_check_selector

selector_to_linear_gdt:
    mov ax,gdt_sel
    mov ds,ax

selector_to_linear_check_selector:
    and si,0FFF8h
    xor ah,ah
    mov al,[si+6]
    and al,0Fh
    shl eax,16
    mov ax,[si]
    test byte ptr [si+6],80h
    jz selector_to_linear_small
;
    shl eax,12
    or ax,0FFFh

selector_to_linear_small:
    sub eax,edi
    jnc selector_to_linear_valid
;
    mov eax,-1

selector_to_linear_valid:
    inc eax
    cmp ecx,eax
    jb selector_to_linear_base
    mov ecx,eax
selector_to_linear_base:
    mov edx,[si+2]
    rol edx,8
    mov dl,[si+7]
    ror edx,8
    add edx,edi
;
    pop si
    pop eax
    pop ds
    ret
SelectorToLinear    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateIpcHandle
;
;           DESCRIPTION:    Allocate a mailslot handle
;
;           PARAMETERS:         BX          Mailslot
;
;           RETURNS:        BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateIpcHandle

AllocateIpcHandle       Proc near
    push ds
    push ax
    push cx
    push dx
;
    mov dx,bx
    mov cx,SIZE ipc_handle_seg
    AllocateHandle
    mov [ebx].ipc_handle_sel,dx
    mov [ebx].hh_sign,IPC_HANDLE
    mov bx,[ebx].hh_handle
;
    pop dx
    pop cx
    pop ax
    pop ds
    ret
AllocateIpcHandle       Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           EnterIpcSection
;
;       DESCRIPTION:    Enter IPC section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public EnterIpcSection

EnterIpcSection Proc near
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:ipc_section
;
    pop ax
    pop ds
    ret
EnterIpcSection Endp 
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LeaveIpcSection
;
;       DESCRIPTION:    Leave IPC section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LeaveIpcSection

LeaveIpcSection Proc near
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:ipc_section
;
    pop ax
    pop ds
    ret
LeaveIpcSection Endp 
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetIpcMailslotList
;
;       DESCRIPTION:    Get head of mailslot list
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetIpcMailslotList

GetIpcMailslotList Proc near
    push ds
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:ipc_mailslot_list
;
    pop ds
    ret
GetIpcMailslotList Endp 
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetLocalMailslot
;
;           DESCRIPTION:    Get local mailslot from name
;
;           PARAMETERS:         ES:(E)DI    Mailslot name
;
;           RETURNS:        BX              Mailslot handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_local_mailslot_name DB 'Get Local Mailslot',0

get_local_mailslot      Proc near
    push ds
    push ax
    push dx
    push si
;
    mov ax,SEG data
    mov ds,ax
    call EnterIpcSection
    mov bx,ds:ipc_mailslot_list
    or bx,bx
    jz get_local_fail

get_local_loop:
    mov ds,bx
    mov si,OFFSET m_name
;
    push edi

get_local_comp:
    mov al,[si]
    cmp al,es:[edi]
    jne get_local_next
;
    or al,al
    jz get_local_ok
;
    inc si
    inc edi
    jmp get_local_comp

get_local_next:
    pop edi
    mov bx,ds:m_link
    or bx,bx
    jnz get_local_loop      

get_local_fail: 
    call LeaveIpcSection
    stc
    jmp get_local_done

get_local_ok:
    inc ds:m_usage
    call LeaveIpcSection
    call AllocateIpcHandle
    pop edi
    clc

get_local_done:
    pop si
    pop dx
    pop ax
    pop ds
    ret
get_local_mailslot      Endp

get_local_mailslot32    Proc far
    call get_local_mailslot
    retf32
get_local_mailslot32    Endp

get_local_mailslot16    Proc far
    push edi
    movzx edi,di
    call get_local_mailslot
    pop edi
    retf32
get_local_mailslot16    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeMailslot
;
;           DESCRIPTION:    Free mailslot handle
;
;           PARAMETERS:         BX              Mailslot handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_mailslot_name      DB 'Free Mailslot',0

free_mailslot   Proc far
    push ds
    push ax
;
    mov ax,IPC_HANDLE
    DerefHandle
    jc free_mailslot_done
;
    mov ax,[ebx].ipc_handle_sel
    or ax,ax
    stc
    jz free_mailslot_done
;
    mov ds,ax
    sub ds:m_usage,1
    clc
    jnz free_mailslot_done
;
    FreeHandle
    clc

free_mailslot_done:
    pop ax
    pop ds
    retf32
free_mailslot   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SendMailslot
;
;           DESCRIPTION:    Send message to mailslot
;
;           PARAMETERS:         BX              Mailslot handle
;                           DS:(E)SI    Message buffer
;                           (E)CX       Message size
;                           ES:(E)DI    Reply buffer
;                           (E)AX       Max reply size
;
;           RETURNS:        (E)CX       Reply size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_mailslot_name      DB 'Send Mailslot',0

send_mailslot   Proc near
    push ds
    push fs
    push gs
    push ax
    push ebx
    push ebp
;
    mov ebp,eax
    mov ax,ds
    mov fs,ax
    mov ax,IPC_HANDLE
    DerefHandle
    jc send_mailslot_done
;
    mov ax,[ebx].ipc_handle_sel
    or ax,ax
    stc
    jz send_mailslot_done
;
    mov ds,ax
    cmp ecx,ds:m_rec_max_size
    jbe send_mailslot_ok
;
    stc
    jmp send_mailslot_done

send_mailslot_ok:
    call ds:m_send_callb

send_mailslot_done:
    pop ebp
    pop ebx
    pop ax
    pop gs
    pop fs
    pop ds
    ret
send_mailslot   Endp

send_mailslot32 Proc far
    call send_mailslot
    retf32
send_mailslot32 Endp

send_mailslot16 Proc far
    push eax
    push esi
    push edi
    movzx eax,ax
    movzx ecx,cx
    movzx esi,si
    movzx edi,di
    call send_mailslot
    pop edi
    pop esi
    pop eax
    retf32
send_mailslot16 Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DefineMailslot
;
;           DESCRIPTION:    Define a mailslot for the current thread
;
;           PARAMETERS:         ES:(E)DI    Mailslot name
;                           E(CX)       Max message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define_mailslot_name    DB 'Define Mailslot',0

define_mailslot Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    mov ebx,ecx
    push es
    push edi
    mov ecx,10000h
    xor al,al
    repne scas byte ptr es:[edi]
    neg cx
    movzx ecx,cx
;
    mov eax,OFFSET m_name
    add eax,ecx
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
    mov ds:m_rec_max_size,ebx
    mov ds:m_link,0
    mov ds:m_usage,0
    mov ds:m_rec_thread,0
    mov ds:m_send_thread,0
    mov ds:m_req_list,0
    mov ds:m_host_list,0
    mov ds:m_rec_callb,0
    mov ds:m_reply_callb,0
    mov ds:m_send_callb,OFFSET SendLocal
    InitSection ds:m_section
    InitSection ds:m_host_section
;    
    pop esi
    pop ds
    mov edi,OFFSET m_name
    rep movs byte ptr es:[edi],ds:[esi]
;
    GetThread
    mov ds,ax
    mov ds:p_mailslot_sel,es
;
    mov ax,SEG data
    mov ds,ax
    call EnterIpcSection
    mov ax,ds:ipc_mailslot_list
    mov ds:ipc_mailslot_list,es
    mov es:m_link,ax
    call LeaveIpcSection
;
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
define_mailslot Endp

define_mailslot32       Proc far
    call define_mailslot
    retf32
define_mailslot32       Endp

define_mailslot16       Proc far
    push ecx
    push edi
    movzx ecx,cx
    movzx edi,di
    call define_mailslot
    pop edi
    pop ecx
    retf32
define_mailslot16       Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           QueueReceiveRequest
;
;           DESCRIPTION:    Queue request on receiver
;
;           PARAMETERS:         DS              Mailslot
;                           ES              Request to queue
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public QueueReceiveRequest

QueueReceiveRequest     Proc near
    push di
;
    mov di,ds:m_req_list
    or di,di
    je queue_send_empty
;
    push ds
    push si
    mov ds,di
    mov si,ds:ml_prev
    mov ds:ml_prev,es
    mov ds,si
    mov ds:ml_next,es
    mov es:ml_next,di
    mov es:ml_prev,si
    pop si
    pop ds
    jmp queue_send_done

queue_send_empty:
    mov es:ml_next,es
    mov es:ml_prev,es
    mov ds:m_req_list,es

queue_send_done:
    pop di
    ret
QueueReceiveRequest     Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DequeueReceiveRequest
;
;           DESCRIPTION:    Dequeue request on receiver
;
;           PARAMETERS:         DS              Mailslot
;                           ES              Request to dequeue
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DequeueReceiveRequest   Proc near
    push ax
    push di
;
    push ds
    mov di,es:ml_next
    mov ax,es
    cmp ax,di
    mov ax,es:ml_prev
    mov ds,ax
    mov ds:ml_next,di
    mov ds,di
    mov ds:ml_prev,ax
    pop ds
    jne do_rec_more
;
    mov ds:m_req_list,0
    jmp do_rec_removed

do_rec_more:
    mov ax,es:ml_next
    mov ds:m_req_list,ax

do_rec_removed:
    pop di
    pop ax
    ret
DequeueReceiveRequest   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyToReceiver
;
;           DESCRIPTION:    Copy message to receiver
;
;           PARAMETERS:         DS              Mailslot
;                           FS:ESI      Message buffer
;                           ECX             Message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CopyToReceiver

CopyToReceiver  Proc near
    push es
    push bx
    push ecx
    push esi
    push edi
;
    mov ds:m_rec_size,ecx
    mov es,ds:m_rec_glob_sel
    xor edi,edi
    rep movs byte ptr es:[edi],fs:[esi]
;
    xor bx,bx
    mov es,bx
    mov fs,bx
    xchg bx,ds:m_rec_thread
    LeaveSection ds:m_section
    Signal
;
    pop edi
    pop esi
    pop ecx
    pop bx
    pop es
    ret
CopyToReceiver  Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InsertReceive
;
;           DESCRIPTION:    Insert receive request
;
;           PARAMETERS:         DS              Mailslot
;                           ES:EDI      Message buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertReceive   Proc near
    pushad
;
    mov ecx,ds:m_rec_max_size
    call SelectorToLinear
    mov ds:m_rec_max_size,ecx
    mov al,es:[edi]
    mov al,es:[edi+ecx-1]
;
    mov ds:m_rec_base,edx
    mov ds:m_rec_size,ecx
    mov eax,edx
    add eax,ecx
    dec eax
    and ax,0F000h
    add eax,1000h
    and dx,0F000h
    sub eax,edx
    mov ds:m_rec_glob_size,eax
    AllocateBigLinear
    mov ds:m_rec_glob_base,edx
    mov ax,word ptr ds:m_rec_base
    and ax,0FFFh
    or dx,ax
    AllocateGdt
    mov ecx,ds:m_rec_size
    CreateDataSelector32
    mov ds:m_rec_glob_sel,bx
    mov ecx,ds:m_rec_glob_size
    shr ecx,12
    mov esi,ds:m_rec_base
    and si,0F000h
    mov edi,ds:m_rec_glob_base
    CopyPageEntries
;
    popad
    ret
InsertReceive   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RemoveReceive
;
;           DESCRIPTION:    Remove receive request
;
;           PARAMETERS:         DS              Mailslot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveReceive   Proc near
    pushad
;
    mov ecx,ds:m_rec_glob_size
    shr ecx,12
    mov esi,ds:m_rec_glob_base
    mov edi,ds:m_rec_base
    and di,0F000h
    MovePageEntries
;
    mov bx,ds:m_rec_glob_sel
    FreeGdt
;
    mov edx,ds:m_rec_glob_base
    mov ecx,ds:m_rec_glob_size
    FreeLinear
;       
    mov ds:m_rec_glob_sel,0
;
    popad
    ret
RemoveReceive   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReceiveMailslot
;
;           DESCRIPTION:    Receive from mailslot
;
;           PARAMETERS:         ES:(E)DI    Message buffer
;
;           RETURNS:        ECX             Message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

receive_mailslot_name   DB 'Receive Mailslot',0

receive_mailslot    Proc near
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov ax,ds:p_mailslot_sel
    or ax,ax
    stc
    jz receive_mailslot_done
;
    mov ds,ax
    EnterSection ds:m_section
    mov ax,ds:m_req_list
    or ax,ax
    jz rec_empty
;
    push es
    push fs
    push dx
    push esi
;
    mov dx,es
    mov fs,dx
    mov es,ax
    mov esi,edi
    mov ax,es:ml_rec_callb
    mov ds:m_rec_callb,ax
    mov ax,es:ml_reply_callb
    mov ds:m_reply_callb,ax
    call DequeueReceiveRequest
    call ds:m_rec_callb
;
    pop esi
    pop dx
    pop fs
    pop es
    jmp receive_mailslot_done

rec_empty:
    ClearSignal
    GetThread
    mov ds:m_rec_thread,ax
    call InsertReceive
    LeaveSection ds:m_section
    WaitForSignal
;
    EnterSection ds:m_section
    call RemoveReceive
    mov ecx,ds:m_rec_size
    LeaveSection ds:m_section
    clc

receive_mailslot_done:
    pop ax
    pop ds
    ret
receive_mailslot    Endp

receive_mailslot32      Proc far
    call receive_mailslot
    retf32
receive_mailslot32      Endp

receive_mailslot16      Proc far
    push edi
    movzx ecx,cx
    movzx edi,di
    call receive_mailslot
    pop edi
    retf32
receive_mailslot16      Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReplyMailslot
;
;           DESCRIPTION:    Reply to mailslot
;
;           PARAMETERS:         ES:(E)DI    Reply buffer
;                           (E)CX       Reply size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reply_mailslot_name     DB 'Reply Mailslot',0

reply_mailslot  Proc near
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov ax,ds:p_mailslot_sel
    or ax,ax
    stc
    jz reply_mailslot_done
;
    mov ds,ax
    call ds:m_reply_callb

reply_mailslot_done:
    pop ax
    pop ds
    ret
reply_mailslot  Endp

reply_mailslot32    Proc far
    call reply_mailslot
    retf32
reply_mailslot32    Endp

reply_mailslot16    Proc far
    push ecx
    push edi
    movzx ecx,cx
    movzx edi,di
    call reply_mailslot
    pop edi
    pop ecx
    retf32
reply_mailslot16    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_handle
;
;           DESCRIPTION:    Delete handle (called from handle module)
;
;           PARAMETERS:         BX              Mailslot handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push ax
;
    mov ax,IPC_HANDLE
    DerefHandle
    jc delete_handle_done
;
    mov ax,[ebx].ipc_handle_sel
    or ax,ax
    stc
    jz delete_handle_done
;
    mov ds,ax
    sub ds:m_usage,1
    clc
    jnz delete_handle_done
;
    FreeHandle
    clc

delete_handle_done:
    pop ax
    pop ds
    retf32
delete_handle   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_thread
;
;           DESCRIPTION:    Init thread mailslot
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread     PROC far
    GetThread
    mov ds,ax
    mov ds:p_mailslot_sel,0
    retf32
init_thread     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           free_thread
;
;           DESCRIPTION:    Free thread mailslot
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_thread     PROC far
    GetThread
    mov ds,ax
    mov ax,ds:p_mailslot_sel
    or ax,ax
    jz free_thread_done
;
    mov es,ax
    FreeMem

free_thread_done:
    retf32
free_thread     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    Init IPC driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov bx,SEG data
    mov ds,bx
    mov es,bx
    InitSection ds:ipc_section
    mov ds:ipc_mailslot_list,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov ax,IPC_HANDLE
    mov edi,OFFSET delete_handle
    RegisterHandle
;
    mov ebx,OFFSET get_local_mailslot16
    mov esi,OFFSET get_local_mailslot32
    mov edi,OFFSET get_local_mailslot_name
    mov dx,virt_es_in
    mov ax,get_local_mailslot_nr
    RegisterUserGate
;
    mov esi,OFFSET free_mailslot
    mov edi,OFFSET free_mailslot_name
    xor dx,dx
    mov ax,free_mailslot_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET send_mailslot16
    mov esi,OFFSET send_mailslot32
    mov edi,OFFSET send_mailslot_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,send_mailslot_nr
    RegisterUserGate
;
    mov ebx,OFFSET define_mailslot16
    mov esi,OFFSET define_mailslot32
    mov edi,OFFSET define_mailslot_name
    mov dx,virt_es_in
    mov ax,define_mailslot_nr
    RegisterUserGate
;
    mov ebx,OFFSET receive_mailslot16
    mov esi,OFFSET receive_mailslot32
    mov edi,OFFSET receive_mailslot_name
    mov dx,virt_es_in
    mov ax,receive_mailslot_nr
    RegisterUserGate
;
    mov ebx,OFFSET reply_mailslot16
    mov esi,OFFSET reply_mailslot32
    mov edi,OFFSET reply_mailslot_name
    mov dx,virt_es_in
    mov ax,reply_mailslot_nr
    RegisterUserGate
;
    mov edi,OFFSET init_thread
    HookCreateThread
;
    mov edi,OFFSET free_thread
    HookTerminateThread
;
    call init_smp
    clc
    ret
init    ENDP

code    ENDS

    END init
