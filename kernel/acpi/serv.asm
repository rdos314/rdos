;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
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
; DEVSERV.ASM
; uACPI server part
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
include ..\fs.inc
include ..\os\exec.def
include acpi.def

    .386p

MAX_REQ_COUNT  = 16

REPLY_DEFAULT      = 0
REPLY_DATA         = 1

dev_cmd  STRUC

dev_req_section          section_typ <>
dev_cmd_thread           DW ?
dev_cmd_curr             DD ?

dev_cmd_unused_mask      DD ?
dev_cmd_free_mask        DD ?
dev_cmd_arr              DD 4 * 32 DUP(?)
dev_cmd_ring             DB 34 DUP(?)
dev_cmd_head             DB ?
dev_cmd_tail             DB ?

dev_req_arr              DW MAX_REQ_COUNT DUP(?)

dev_cmd  ENDS


; should be 16 bytes!

dev_server_msg  STRUC

devs_phys                  DD ?,?
devs_server_linear         DD ?
devs_sel                   DW ?
devs_thread                DW ?

dev_server_msg  ENDS

dev_reg      STRUC

reg_op              DD ?
reg_handle          DD ?
reg_buf             DD ?,?
reg_size            DD ?
reg_eflags          DD ?
reg_eax             DD ?
reg_ebx             DD ?
reg_ecx             DD ?
reg_edx             DD ?
reg_esi             DD ?
reg_edi             DD ?

dev_reg      ENDS

data    SEGMENT byte public 'DATA'

msg_sel        DW ?

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateMsgSel
;
;       DESCRIPTION:    Create msg sel
;
;       RETURNS:        AX     MSG sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateMsgSel  Proc near
    push es
    push ecx
    push edi
;
    mov eax,SIZE dev_cmd
    AllocateSmallGlobalMem
    mov ecx,eax
    xor edi,edi
    xor al,al
    rep stos byte ptr es:[edi]
    mov es:dev_cmd_unused_mask,-1
    InitSection es:dev_req_section
;
    mov eax,es
;
    pop edi
    pop ecx
    pop es
    ret
CreateMsgSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMsgSel
;
;       DESCRIPTION:    Get msg sel
;
;       RETURNS:        DS     MSG sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMsgSel  Proc near
    push eax
;
    mov eax,SEG data
    mov ds,eax
    mov ax,ds:msg_sel
    or ax,ax
    jnz gmsOk
;
    call CreateMsgSel
    mov ds:msg_sel,ax

gmsOk:
    mov ds,eax
;
    pop eax
    ret
GetMsgSel Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForDevCmd
;
;       DESCRIPTION:    Wait for dev cmd
;
;       PARAMETERS:     EBX        Dev handle
;
;       RETURNS:        EDX        Msg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_dev_cmd_name DB 'Wait For Dev Cmd', 0

wait_for_dev_cmd   Proc far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    call GetMsgSel
;
    GetThread
    mov ds:dev_cmd_thread,ax
    jmp wfcCheck

wfcRetry:
    WaitForSignal

wfcCheck:
    movzx ebx,ds:dev_cmd_head
    mov al,ds:[ebx].dev_cmd_ring
    cmp bl,ds:dev_cmd_tail
    je wfcRetry
;
    inc bl
    cmp bl,34
    jb wfcSaveHead
;
    xor bl,bl

wfcSaveHead:
    mov ds:dev_cmd_head,bl
;
    movzx ebx,al
    mov ds:dev_cmd_curr,ebx
    dec ebx
    shl ebx,4
    add ebx,OFFSET dev_cmd_arr
    mov edx,ds:[ebx].devs_server_linear
    or edx,edx
    jnz wfcMap
;
    mov eax,1000h
    AllocateLocalLinear
    mov ds:[ebx].devs_server_linear,edx

wfcMap:
    push ds
    push edx
;
    mov eax,[ebx].devs_phys
    mov ebx,[ebx].devs_phys+4
    or ax,867h
;
    mov cx,system_data_sel
    mov ds,cx
    add edx,ds:flat_base
    SetPageEntry
;
    pop edx
    pop ds
    clc

wfcDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
wait_for_dev_cmd  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMsgEntry
;
;       DESCRIPTION:    Get fs msg entry
;
;       PARAMETERS:     DS      Msg sel
;
;       RETURNS:        EBX     FS entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMsgEntry  Proc near
    push ecx

gmeRetry:
    mov ebx,ds:dev_cmd_free_mask
    or ebx,ebx
    jz gmeTryUnused
;
    bsf ecx,ebx
    lock btr ds:dev_cmd_free_mask,ecx
    jc gmeOk
    jmp gmeRetry

gmeTryUnused:
    mov ebx,ds:dev_cmd_unused_mask
    or ebx,ebx
    jz gmeBlock
;
    bsf ecx,ebx
    lock btr ds:dev_cmd_unused_mask,ecx
    jc gmeAlloc
    jmp gmeRetry

gmeBlock:
    int 3
    jmp gmeRetry

gmeAlloc:
    mov ebx,ecx
    shl ebx,4
    add ebx,OFFSET dev_cmd_arr
;
    push eax
    push ebx
    push edx
    push edi
;
    mov edi,ebx
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    mov ds:[edi].devs_phys,eax
    mov ds:[edi].devs_phys+4,ebx
;
    or al,63h
    SetPageEntry
;    
    mov ecx,1000h
    AllocateGdt
    mov ds:[edi].devs_sel,bx
    CreateDataSelector32
;
    mov ds:[edi].devs_server_linear,0
    mov ds:[edi].devs_thread,0
;
    pop edi
    pop edx
    pop ebx
    pop eax
;
    clc
    jmp gmeDone

gmeFailed:
    stc
    jmp gmeDone

gmeOk:
    mov ebx,ecx
    shl ebx,4
    add ebx,OFFSET dev_cmd_arr
    clc

gmeDone:
    pop ecx
    ret
GetMsgEntry  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateMsg
;
;       DESCRIPTION:    Allocate msg
;
;       RETURNS:        DS      Msg sel
;                       EBX     Msg entry
;                       ES      Msg buffer
;                       EDI     FS msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateMsg

AllocateMsg  Proc near
    push ebx
;
    call GetMsgSel
    call GetMsgEntry
    jnc amSave
;
    pop ebx
    xor ebx,ebx
    mov es,ebx
    stc
    jmp amDone

amSave:
    mov es,ds:[ebx].devs_sel
    mov es:reg_size,0
    pop es:reg_ebx
;
    stc
    pushfd
    pop es:reg_eflags
;
    mov es:reg_eax,eax
    mov es:reg_ecx,ecx
    mov es:reg_edx,edx
    mov es:reg_esi,esi
    mov es:reg_edi,edi
;
    mov edi,SIZE dev_reg
    clc

amDone:
    ret
AllocateMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddMsgBuffer
;
;       DESCRIPTION:    Add msg buffer
;
;       PARAMETERS:     DS      Msg sel
;                       ES      Msg buffer
;                       GS:EDI  Data buffer
;                       ECX     Size of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddMsgBuffer

AddMsgBuffer  Proc near
    mov es:reg_buf,edi
    mov es:reg_buf+4,gs
    mov es:reg_size,ecx
    ret
AddMsgBuffer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           no_reply
;
;       DESCRIPTION:    No reply processing
;
;       PARAMETERS:     ES      Msg buf
;
;       RETURNS:        EBP     Reply data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

no_reply   Proc near
    xor ebp,ebp
    clc
    ret
no_reply   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           data_reply
;
;       DESCRIPTION:    Data reply processing
;
;       PARAMETERS:     ES      Msg buf
;
;       RETURNS:        EBP     Reply data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

data_reply  Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    xor ebp,ebp
    mov eax,es
    mov ds,eax
    mov esi,SIZE dev_reg
    mov ecx,ds:reg_size
    or ecx,ecx
    jz drpDone
;
    lods dword ptr ds:[esi]
    or eax,eax
    jz drpDone
;
    cmp eax,ecx
    jae drpCopy
;
    mov ecx,eax

drpCopy:
    mov ebp,ecx
    les edi,ds:reg_buf
    rep movs byte ptr es:[edi],ds:[esi]

drpDone:
    clc
;
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
data_reply  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RunMsg
;
;       DESCRIPTION:    Run ssl msg
;
;       PARAMETERS:     DS      Msg sel
;                       ES      Msg buf
;                       EAX     Op
;                       EBX     Msg entry
;
;       RETURNS:        EBP     Reply data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public RunMsg

reply_tab:
r00 DD OFFSET no_reply
r01 DD OFFSET data_reply

RunMsg  Proc near
    mov esi,ebx
    mov es:reg_op,eax
;
    GetThread
    mov ds:[esi].devs_thread,ax
;
    sub ebx,OFFSET dev_cmd_arr
    shr ebx,4
    mov al,bl
    inc al
;
    movzx ebx,ds:dev_cmd_tail
    mov ds:[ebx].dev_cmd_ring,al
    inc bl
    cmp bl,34
    jb rmSaveTail
;
    xor bl,bl

rmSaveTail:
    mov ds:dev_cmd_tail,bl
;
    mov bx,ds:dev_cmd_thread
    Signal

rmWait:
    WaitForSignal
;
    mov bx,ds:[esi].devs_thread
    or bx,bx
    jnz rmWait
;
    mov ebp,es:reg_eax
    mov ebx,es:reg_ebx
    mov ecx,es:reg_ecx
    mov edx,es:reg_edx
    mov esi,es:reg_esi
    mov edi,es:reg_edi
;
    dec al
    movzx eax,al
    push es:reg_eflags
    push ebp
    push eax
;
    xor ebp,ebp
    push es:reg_eflags
    popfd
    jc rmFree
;
    push ebx
    mov ebx,es:reg_op
    shl ebx,2
    call dword ptr cs:[ebx].reply_tab
    pop ebx

rmFree:
    pop eax
    lock bts ds:dev_cmd_free_mask,eax
;
    pop eax
    popfd

rmDone:
    ret
RunMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReplyDevCmd
;
;       DESCRIPTION:    Reply on dev run cmd
;
;       PARAMETERS:     EBX        Server handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reply_dev_cmd_name DB 'Reply Dev Cmd', 0

reply_dev_cmd   Proc far
    push ds
    push es
    pushad
;
    mov es:[edi].reg_op,REPLY_DEFAULT
;
    call GetMsgSel
    mov esi,ds:dev_cmd_curr
    dec esi
    shl esi,4
    add esi,OFFSET dev_cmd_arr
    xor bx,bx
    xchg bx,ds:[esi].devs_thread
    Signal
;
    mov edx,ds:[esi].devs_server_linear
    mov eax,ds:[esi].devs_phys
    mov ebx,ds:[esi].devs_phys+4
    or ax,863h
    mov cx,system_data_sel
    mov es,cx
    add edx,es:flat_base
    SetPageEntry

rfcDone:
    popad
    pop es
    pop ds
    ret
reply_dev_cmd  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReplySslDataCmd
;
;       DESCRIPTION:    Reply on dev data cmd
;
;       PARAMETERS:     EBX        Server handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reply_dev_data_cmd_name DB 'Reply Dev Data Cmd', 0

reply_dev_data_cmd   Proc far
    push ds
    push es
    pushad
;
    mov es:[edi].reg_op,REPLY_DATA
;
    call GetMsgSel
    mov esi,ds:dev_cmd_curr
    dec esi
    shl esi,4
    add esi,OFFSET dev_cmd_arr
    xor bx,bx
    xchg bx,ds:[esi].devs_thread
    Signal
;
    mov edx,ds:[esi].devs_server_linear
    mov eax,ds:[esi].devs_phys
    mov ebx,ds:[esi].devs_phys+4
    or ax,863h
    mov cx,system_data_sel
    mov es,cx
    add edx,es:flat_base
    SetPageEntry
;
    popad
    pop es
    pop ds
    ret
reply_dev_data_cmd  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init_server
;
;       description:    Init server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_server

init_server    Proc near
    mov eax,SEG data
    mov es,eax
    mov es:msg_sel,0
    call GetMsgSel
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET wait_for_dev_cmd
    mov edi,OFFSET wait_for_dev_cmd_name
    xor cl,cl
    mov ax,uacpi_wait_for_cmd_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET reply_dev_cmd
    mov edi,OFFSET reply_dev_cmd_name
    xor cl,cl
    mov ax,uacpi_reply_cmd_nr
    RegisterPrivateServGate
;
    mov esi,OFFSET reply_dev_data_cmd
    mov edi,OFFSET reply_dev_data_cmd_name
    xor cl,cl
    mov ax,uacpi_reply_data_cmd_nr
    RegisterPrivateServGate
    ret
init_server    Endp

code    ENDS

    END
