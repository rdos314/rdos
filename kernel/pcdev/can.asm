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
; CAN.ASM
; CAN-bus driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\drive.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\os\core.inc
INCLUDE ..\acpi\pci.inc

MAX_GEN_HOOK_COUNT  = 16

CAN_CONT     = 0
CAN_STAT     = 4
CAN_BITT     = 0Ch
CAN_INT      = 10h
CAN_OPT      = 14h
CAN_BRPE     = 18h

IF1_CREQ    = 20h
IF1_CMASK   = 24h
IF1_MASK1   = 28h
IF1_MASK2   = 2Ch
IF1_ID1     = 30h
IF1_ID2     = 34h
IF1_MCONT   = 38h
IF1_DATA1   = 3Ch
IF1_DATA2   = 40h
IF1_DATA3   = 44h
IF1_DATA4   = 48h

IF2_CREQ    = 80h
IF2_CMASK   = 84h
IF2_MASK1   = 88h
IF2_MASK2   = 8Ch
IF2_ID1     = 90h
IF2_ID2     = 94h
IF2_MCONT   = 98h
IF2_DATA1   = 9Ch
IF2_DATA2   = 0A0h
IF2_DATA3   = 0A4h
IF2_DATA4   = 0A8h

CAN_TREQ1   = 100h
CAN_TREQ2   = 104h

CAN_NDATA1  = 120h
CAN_NDATA2  = 124h

CAN_IPEND1  = 140h
CAN_IPEND2  = 144h

CAN_MVAL1   = 160h
CAN_MVAL2   = 164h


capture_block   STRUC

cc_prev     DD ?
cc_next     DD ?
cc_time     DD ?,?
cc_id       DD ?
cc_data     DD ?,?
cc_size     DB ?

capture_block   ENDS


can_msg_struc   STRUC

cm_id       DD ?
cm_data     DD ?,?
cm_size     DW ?
cm_msg      DW ?
cm_signal   DW ?

can_msg_struc   ENDS

id_hook_struc   STRUC

ih_id       DD ?
ih_mask     DD ?
ih_offset   DD ?
ih_sel      DW ?
ih_param    DW ?

id_hook_struc   ENDS

data    SEGMENT byte public 'DATA'

can_sel                 DW ?

can_thread              DW ?
can_int_reg             DW ?

can_reset               DW ?

capture_handle          DW ?
capture_thread          DW ?
capture_list            DD ?
capture_section         section_typ <>

can_send_section        section_typ <>
can_rec_section         section_typ <>

can_send_clear          DD ?
can_send_pend           DD ?
can_send_used           DD ?
can_send_arr            DB 16 * 32 DUP(?)

can_rec_insert          DB ?
can_rec_remove          DB ?
can_rec_arr             DB 32 * 32 DUP(?)

can_id_hook_arr         DD 15 * 4 DUP(?)

can_gen_hook_count      DW ?
can_gen_hook_arr        DD MAX_GEN_HOOK_COUNT DUP(?,?)

data    ENDS


IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WaitForIf2
;
;   DESCRIPTION:    Wait for IF2 to become ready
;
;   PARAMETERS:     ES      Can sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForIf2  Proc near
    test word ptr es:IF2_CREQ,8000h
    jz wf2Done
;
    pause
    jmp WaitForIf2

wf2Done:
    ret
WaitForIf2  Endp 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ClearTxMsg
;
;   DESCRIPTION:    Clear TX buf
;
;   PARAMETERS:     ES      Can sel
;                   BX      Message #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearTxMsg  Proc near
    call WaitForIf2    
;
    mov eax,0B8h
    mov es:IF2_CMASK,eax
;
    mov eax,0
    mov es:IF2_ID1,eax
;
    mov eax,0
    mov es:IF2_ID2,eax
;
    mov eax,0
    mov es:IF2_MCONT,eax
;
    movzx eax,bx
    mov es:IF2_CREQ,eax
;
    call WaitForIf2    
    ret
ClearTxMsg    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ReadTxMsg
;
;   DESCRIPTION:    Read message into IF2
;
;   PARAMETERS:     ES      Can sel
;                   BX      Message #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadTxMsg  Proc near
    push eax
    call WaitForIf2    
;
    mov eax,7Fh
    mov es:IF2_CMASK,eax
;
    movzx eax,bx
    mov es:IF2_CREQ,eax
;
    call WaitForIf2
;    
    pop eax
    ret
ReadTxMsg  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ReadRxMsg
;
;   DESCRIPTION:    Read rx Msg into buffer
;
;   PARAMETERS:     ES      Can sel
;                   BX      Message #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadRxMsg  Proc near
    call WaitForIf2    
;
    mov eax,7Fh
    mov es:IF2_CMASK,eax
;
    movzx eax,bx
    mov dx,bx
    mov es:IF2_CREQ,eax
;
    call WaitForIf2

rmRetry:
    movzx bx,ds:can_rec_insert
    mov al,bl
    inc al
    and al,1Fh
    cmp al,ds:can_rec_remove
    je rmDone
;
    mov ds:can_rec_insert,al
;
    shl bx,5
    add bx,OFFSET can_rec_arr
    mov ds:[bx].cm_msg,dx
;
    mov ax,es:IF2_ID2
    and ax,1FFFh
    shl eax,16
    mov ax,es:IF2_ID1
    mov ds:[bx].cm_id,eax
;
    mov ax,es:IF2_DATA2
    shl eax,16
    mov ax,es:IF2_DATA1
    mov ds:[bx].cm_data,eax
;
    mov ax,es:IF2_DATA4
    shl eax,16
    mov ax,es:IF2_DATA3
    mov ds:[bx].cm_data+4,eax
;    
    mov ax,es:IF2_MCONT
    and al,0Fh
    test al,8
    jz rmLenOk
;
    mov al,8

rmLenOk:
    movzx ax,al
    mov ds:[bx].cm_size,ax   

rmDone:    
    ret
ReadRxMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CanInt
;
;           DESCRIPTION:    CAN-bus interrupt
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CanInt  Proc far
    mov es,ds:can_sel

ciReadLoop:
    mov ax,es:CAN_NDATA1
    or ax,ax
    jz ciWriteLoop    
;
    mov cx,16
    mov bx,1
    mov dx,1

ciReadCheck:    
    test dx,es:CAN_NDATA1
    jz ciReadNext
;    
    push bx
    push cx
    push dx
    call ReadRxMsg
    pop dx
    pop cx
    pop bx

ciReadNext:
    shl dx,1
    inc bx
    loop ciReadCheck
;
    mov bx,ds:can_thread
    Signal
    jmp ciReadLoop    
    
ciWriteLoop:    
    mov eax,es:CAN_INT
    test ax,8000h
    jz ciReg

ciStatus:
    mov eax,es:CAN_STAT
    test ax,20h
    jnz ciSignal    
;
    jmp ciWriteLoop
    
ciReg:
    or eax,eax
    jz ciDone
;    
    mov ebx,eax
    cmp ebx,10h
    jbe ciReadLoop
;
    call ClearTxMsg
    sub ebx,11h
    lock bts ds:can_send_clear,ebx
;
    mov edi,ebx
    shl edi,5
    add edi,OFFSET can_send_arr
    xor bx,bx
    xchg bx,ds:[edi].cm_signal
    or bx,bx
    jz ciNotifyOk
;
    Signal

ciNotifyOk:    
    mov bx,ds:can_thread
    Signal
    jmp ciWriteLoop

ciSignal:
    mov bx,ds:can_thread
    Signal

ciDone:    
    retf32
CanInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupBitTiming
;
;   DESCRIPTION:    Setup bit timing
;
;   PARAMETERS:     ES      CAN sel
;                   AL      TSEG1
;                   AH      TSEG2
;                   CL      Baud divisor
;                   BL      SJW
;
;   RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupBitTiming  Proc near
    pushad
;    
    xor edx,edx
    dec cl
    mov dl,cl
    dec bl
    shl bl,6
    or dl,bl
    dec al
    mov dh,al
    dec ah
    shl ah,4
    or dh,ah
;
    mov eax,41h
    mov es:CAN_CONT,eax
    mov es:CAN_BITT,edx
;
    mov eax,0
    mov es:CAN_BRPE,eax
;
    mov eax,1
    mov es:CAN_CONT,eax        
;
    popad  
    ret
SetupBitTiming  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WaitForIf1
;
;   DESCRIPTION:    Wait for IF1 to become ready
;
;   PARAMETERS:     ES      Can sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForIf1  Proc near
    test word ptr es:IF1_CREQ,8000h
    jz wf1Done
;
    pause
    jmp WaitForIf1   

wf1Done:
    ret
WaitForIf1  Endp 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ClearIdFilter
;
;   DESCRIPTION:    Clear ID filter (empty msg)
;
;   PARAMETERS:     ES      Can sel
;                   BX      Message #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearIdFilter  Proc near
    push eax
;
    call WaitForIf1
;
    mov eax,0B8h
    mov es:IF1_CMASK,eax
;
    mov eax,0
    mov es:IF1_ID1,eax
;
    mov eax,0
    mov es:IF1_ID2,eax
;
    mov eax,0
    mov es:IF1_MCONT,eax
;
    movzx eax,bx
    mov es:IF1_CREQ,eax
;
    pop eax
    ret
ClearIdFilter    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupIdFilter
;
;   DESCRIPTION:    Setup ID filter
;
;   PARAMETERS:     ES      Can sel
;                   BX      Message #
;                   EAX     ID
;                   EDX     Mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupIdFilter  Proc near
    push eax
    push esi
    push edi
;
    mov esi,eax
    mov edi,edx
    call WaitForIf1
;    
    mov eax,1480h
    mov es:IF1_MCONT,eax
;
    mov eax,0F8h
    mov es:IF1_CMASK,eax
;
    movzx eax,di
    mov es:IF1_MASK1,eax
;
    mov eax,edi
    shr eax,16
    and eax,1FFFh
    mov es:IF1_MASK2,eax
;
    movzx eax,si
    mov es:IF1_ID1,eax
;
    mov eax,esi
    shr eax,16
    and eax,1FFFh
    or ax,8000h
    mov es:IF1_ID2,eax
;
    movzx eax,bx
    mov es:IF1_CREQ,eax
;    
    pop edi
    pop esi
    pop eax
    ret
SetupIdFilter    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InitReceiveMsg
;
;   DESCRIPTION:    Init receive msg
;
;   PARAMETERS:     ES      Can sel
;                   BX      Message #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitReceiveMsg  Proc near
    push eax
;
    call WaitForIf1
;    
    mov eax,1480h
    mov es:IF1_MCONT,eax
;
    mov eax,0F8h
    mov es:IF1_CMASK,eax
;
    mov eax,0
    mov es:IF1_MASK1,eax
;
    mov eax,0
    mov es:IF1_MASK2,eax
;
    mov eax,0
    mov es:IF1_ID1,eax
;
    mov eax,8000h    
    mov es:IF1_ID2,eax
;
    movzx eax,bx
    mov es:IF1_CREQ,eax
;    
    pop eax
    ret
InitReceiveMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InitMsg
;
;   DESCRIPTION:    Init msg buffers
;
;   PARAMETERS:     ES      CAN sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitMsg  Proc near
    push bx
;
    mov bx,1

init_id_msg:
    call ClearIdFilter
    inc bx
    cmp bx,10h
    jb init_id_msg
;        
    call InitReceiveMsg
    inc bx
;

init_tx_msg:
    call ClearIdFilter
    inc bx
    cmp bx,20h
    jbe init_tx_msg
;
    call WaitForIf1
;
    pop bx
    ret
InitMsg Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupDevice
;
;   DESCRIPTION:    Setup device
;
;   RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DevName DB 'CAN', 0

SetupDevice  Proc near
    xor bx,bx
    mov ah,0Ch
    mov al,9
    FindPciClassHandle
    jc sdDone
;
    mov al,1
    GetPciBarPhys
    jc sdDone
;
    push ebx
;
    push edx
    push eax
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET DevName
    LockPciHandle
;
    mov eax,1000h    
    AllocateBigLinear
;
    pop eax
    pop ebx
;
    mov si,ax
    and si,0E00h
    and ax,0F000h
    mov al,13h
    SetPageEntry
;
    AllocateGdt
    or dx,si
    mov ecx,200h
    CreateDataSelector16
    mov es,bx
    mov bx,SEG data
    mov ds,bx
    mov ds:can_sel,es
;    
    pop ebx
;
    mov al,12h
    mov di,cs
    mov es,di
    mov edi,OFFSET CanInt
    SetupPciHandleIrq
;
    mov es,ds:can_sel
;
    mov al,16    ; TSEG 1
    mov ah,7    ; TSEG 2
    mov bl,4    ; SJW
    mov cl,1    ; Divisor
    call SetupBitTiming
    call InitMsg
;    
    mov eax,0Eh
    mov es:CAN_CONT,eax        
    clc

sdDone:
    ret
SetupDevice Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ResetDevice
;
;   DESCRIPTION:    Reset device
;
;   RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetDevice  Proc near
    mov ax,250
    WaitMilliSec
;    
    mov es,ds:can_sel
;
    mov al,16    ; TSEG 1
    mov ah,7    ; TSEG 2
    mov bl,4    ; SJW
    mov cl,1    ; Divisor
    call SetupBitTiming
;    
    mov eax,0Eh
    mov es:CAN_CONT,eax        
;
    xor eax,eax
    mov ds:can_send_clear,eax
    mov ds:can_send_used,eax
    mov ds:can_send_pend,eax
;    
    mov ax,250
    WaitMilliSec
    ret
ResetDevice Endp   
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           StartSend
;
;   DESCRIPTION:    Start send on IF1
;
;   PARAMETERS:     ES      Can sel
;                   BX      Message #
;                   DS:SI   Message struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartSend  Proc near
    push eax
;
    call WaitForIf1
;
    mov eax,0BFh
    mov es:IF1_CMASK,eax
;    
    mov eax,880h
    add ax,ds:[si].cm_size
    mov es:IF1_MCONT,eax
;
    mov eax,ds:[si].cm_id
    movzx eax,ax
    mov es:IF1_ID1,eax
;
    mov eax,ds:[si].cm_id
    shr eax,16
    or ax,0A000h
    mov es:IF1_ID2,eax
;
    movzx eax,word ptr ds:[si].cm_data
    mov es:IF1_DATA1,eax
;
    movzx eax,word ptr ds:[si+2].cm_data
    mov es:IF1_DATA2,eax
;
    movzx eax,word ptr ds:[si+4].cm_data
    mov es:IF1_DATA3,eax
;
    movzx eax,word ptr ds:[si+6].cm_data
    mov es:IF1_DATA4,eax
;
    movzx eax,bx
    mov es:IF1_CREQ,eax
;    
    pop eax
    ret
StartSend  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleReceive
;
;   DESCRIPTION:    Handle receive
;
;   PARAMETERS:     ES      Can sel
;                   DS:SI   Message struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleReceive   Proc near
    push eax
    push di
;    
    mov di,ds:[si].cm_msg
    dec di    
    shl di,4
    add di,OFFSET can_id_hook_arr
    mov ax,ds:[di].ih_sel
    or ax,ax
    jz hrDone
;      
    push ds
    push es 
    push ebx     
    push ecx
    push edx
    push si
;    
    mov ax,ds
    mov es,ax
    mov ds,es:[di].ih_param
    mov eax,es:[si].cm_data
    mov edx,es:[si].cm_data+4
    movzx ecx,es:[si].cm_size
    mov ebx,es:[si].cm_id
    call NotifyMsg
    call fword ptr es:[di].ih_offset
;
    pop si
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds

hrDone:    
    pop di
    pop eax
    ret
HandleReceive   Endp    
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CanThread
;
;           DESCRIPTION:    CAN thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

can_thread_name DB 'CAN-bus', 0

can_thread_pr:
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:can_thread,ax
    mov ds:can_reset,0
;
    mov es,ds:can_sel    

ctLoop:
    WaitForSignal
;
    mov eax,es:CAN_STAT
    test ax,20h
    jz ctNotError
;
    mov ds:can_reset,1

ctNotError:
    xor ax,ax
    xchg ax,ds:can_reset
    or ax,ax
    jz ctRecRetry
;
    EnterSection ds:can_send_section
    mov ds:can_rec_insert,0
    mov ds:can_rec_remove,0
    call ResetDevice
    LeaveSection ds:can_send_section

ctRecRetry:
    mov bl,ds:can_rec_remove

ctRecLoop:
    cmp bl,ds:can_rec_insert
    jz ctTx
;
    movzx si,bl
    shl si,5
    add si,OFFSET can_rec_arr
    call HandleReceive    
;
    inc bl
    and bl,1Fh
    mov ds:can_rec_remove,bl
    jmp ctRecLoop

ctTx:
    EnterSection ds:can_send_section
    xor eax,eax
    xchg eax,ds:can_send_clear
    not eax
    and ds:can_send_used,eax
;
    xor eax,eax
    xchg eax,ds:can_send_pend
;
    mov cx,10h
    mov bx,11h
    mov si,OFFSET can_send_arr

ctSendLoop:
    or eax,eax
    jz ctSendOk
;    
    test eax,1
    jz ctSendNext
;
    call StartSend

ctSendNext:
    shr eax,1
    add si,32
    inc bx
    sub cx,1
    jnz ctSendLoop    
    
ctSendOk:     
    LeaveSection ds:can_send_section
;    
    mov bl,ds:can_rec_remove
    cmp bl,ds:can_rec_insert
    jne ctRecRetry
;
    jmp ctLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ResetCanBuffers
;
;   DESCRIPTION:    Reset CAN 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_can_buffers_name   DB 'Reset CAN Buffers', 0

reset_can_buffers    Proc far
    push ds
    push bx
;    
    mov bx,SEG data
    mov ds,bx
    mov ds:can_reset,1
    mov bx,ds:can_thread
    Signal
;
    pop bx
    pop ds    
    retf32
reset_can_buffers    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SendCanBusMsg
;
;   DESCRIPTION:    Send CAN bus message
;
;   PARAMETERS:     EDX:EAX     Data
;                   CL          Size (0..8)
;                   EBX         Identifier
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_can_bus_msg_name   DB 'Send CAN Bus Message', 0

send_can_bus_msg    Proc far
    push ds
    push ebx
    push ecx
    push esi
    push edi
    push bp
;    
    call NotifyMsg    
    mov bp,2000
    mov si,SEG data
    mov ds,si

scRetry:    
    EnterSection ds:can_send_section
;    
    mov esi,ds:can_send_used
    not esi
    bsf edi,esi
;
    cmp edi,10h
    jb scDo
;
    LeaveSection ds:can_send_section
;
    push ax
    mov ax,1
    WaitMilliSec
    pop ax
;
    sub bp,1
    jnz scRetry
;
    int 3        
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
    mov ds:can_reset,1
    mov bx,ds:can_thread
    Signal
;
    pop bx
    pop ds  
;
    mov bp,2000          
    jmp scRetry

scDo:    
    bts ds:can_send_used,edi
    bts ds:can_send_pend,edi
    shl edi,5
    add edi,OFFSET can_send_arr
;
    movzx cx,cl
    mov ds:[edi].cm_id,ebx
    mov ds:[edi].cm_data,eax
    mov ds:[edi].cm_data+4,edx
    mov ds:[edi].cm_size,cx
    mov ds:[edi].cm_signal,0
;
    LeaveSection ds:can_send_section
    mov bx,ds:can_thread
    Signal
;
    pop bp
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop ds    
    retf32
send_can_bus_msg    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SendCanBusBlock
;
;   DESCRIPTION:    Send CAN bus message, wait for completion
;
;   PARAMETERS:     EDX:EAX     Data
;                   CL          Size (0..8)
;                   EBX         Identifier
;
;   RETURNS:        NC          Successfully transmitted
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_can_bus_block_name   DB 'Send CAN Bus Message Block', 0

send_can_bus_block    Proc far
    push ds
    push ebx
    push ecx
    push esi
    push edi
    push bp
;    
    call NotifyMsg
    mov bp,2000
    mov si,SEG data
    mov ds,si

scbRetry:    
    EnterSection ds:can_send_section
;    
    mov esi,ds:can_send_used
    not esi
    bsf edi,esi
;
    cmp edi,10h
    jb scbDo
;
    LeaveSection ds:can_send_section
;
    mov ax,1
    WaitMilliSec
;
    sub bp,1
    jnz scbRetry
;
    int 3        
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
    mov ds:can_reset,1
    mov bx,ds:can_thread
    Signal
;
    pop bx
    pop ds  
;
    mov bp,2000          
    jmp scbRetry

scbDo:    
    bts ds:can_send_used,edi
    bts ds:can_send_pend,edi
    shl edi,5
    add edi,OFFSET can_send_arr
;
    movzx cx,cl
    mov ds:[edi].cm_id,ebx
    mov ds:[edi].cm_data,eax
    mov ds:[edi].cm_data+4,edx
    mov ds:[edi].cm_size,cx
    GetThread
    mov ds:[edi].cm_signal,ax
;
    LeaveSection ds:can_send_section
    mov bx,ds:can_thread
    Signal
;
    mov bp,200

scbWait:
    GetSystemTime
    add eax,11930
    adc edx,0
    WaitForSignalWithTimeout
;
    mov ax,ds:[edi].cm_signal
    or ax,ax
    clc
    jz scbCompleted
;
    sub bp,1
    jnz scbWait
;
    stc    

scbCompleted:
    mov ds:[edi].cm_signal,0
;
    pop bp
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop ds    
    retf32
send_can_bus_block    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HasCanSendBuf
;
;   DESCRIPTION:    Check if there is a free send buffer
;
;   RETURNS:        NC      Has buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_can_send_buf_name   DB 'Has CAN Send Buf', 0

has_can_send_buf    Proc far
    push ds
    push esi
    push edi
;    
    mov si,SEG data
    mov ds,si

    mov esi,ds:can_send_used
    not esi
    bsf edi,esi
;
    cmp edi,10h
    cmc
;
    pop edi
    pop esi
    pop ds    
    retf32
has_can_send_buf    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HookCanBusMsg
;
;   DESCRIPTION:    Register callback for received CAN bus messages
;
;   PARAMETERS:     ES:EDI      Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_gen_bus_msg_name   DB 'Hook General CAN Bus Message', 0

hook_gen_bus_msg    Proc far
    push ds
    push bx
;    
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:can_gen_hook_count
    shl bx,3
    add bx,OFFSET can_gen_hook_arr
    mov ds:[bx],edi
    mov ds:[bx+4],es
    inc ds:can_gen_hook_count
;
    pop bx
    pop ds    
    retf32
hook_gen_bus_msg    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateCanIdHook
;
;   DESCRIPTION:    Create an id-based filter hook
;
;   PARAMETERS:     EAX       Identifier 
;                   EDX       Identifier mask
;                   DS        Param
;                   ES:EDI    Hook callback
;                       DS        Param
;                       EDX:EAX   Data
;                       CL        Size (0..8)
;                       EBX       Identifier
;
;   RETURNS:        BX        Buffer #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_id_hook_name   DB 'Create CAN ID Hook', 0

create_id_hook    Proc far
    push ds
    push es
    push cx
    push esi
    push bp
;    
    mov bp,ds
    mov bx,SEG data
    mov ds,bx
;
    mov bx,OFFSET can_id_hook_arr
    mov cx,15

cihLoop:
    mov si,ds:[bx].ih_sel
    or si,si
    jz cihFound
;
    add bx,16        
    loop cihLoop
;
    stc
    jmp cihDone

cihFound:
    EnterSection ds:can_rec_section
    mov ds:[bx].ih_id,eax
    mov ds:[bx].ih_mask,edx
    mov ds:[bx].ih_param,bp
    mov ds:[bx].ih_offset,edi
    mov ds:[bx].ih_sel,es
;            
    sub bx,OFFSET can_id_hook_arr
    shr bx,4
    inc bx
;
    mov es,ds:can_sel
    call SetupIdFilter
    LeaveSection ds:can_rec_section    
    clc
    
cihDone:
    pop bp
    pop esi
    pop cx
    pop es
    pop ds    
    retf32
create_id_hook    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           DeleteCanIdHook
;
;   DESCRIPTION:    Delete an id-based filter hook
;
;   PARAMETERS:     BX        Buffer #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_id_hook_name   DB 'Delete CAN ID Hook', 0

delete_id_hook    Proc far    
    or bx,bx
    jz dihDone
;
    cmp bx,15
    jae dihDone
;        
    push ds
    push es
    push ax
    push bx
;    
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:can_rec_section
    mov es,ds:can_sel
    call ClearIdFilter
;    
    dec bx
    shl bx,4
    add bx,OFFSET can_id_hook_arr
    mov ds:[bx].ih_id,0
    mov ds:[bx].ih_mask,0
    mov ds:[bx].ih_param,0
    mov ds:[bx].ih_offset,0
    mov ds:[bx].ih_sel,0
;
    LeaveSection ds:can_rec_section    
;    
    pop bx
    pop ax
    pop es
    pop ds    
    
dihDone:
    clc
    retf32
delete_id_hook    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CaptureThread
;
;           description:    Capture thread
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

capture_thread_name DB 'Can Capture', 0

capture_thread_pr:
    mov bx,SEG data
    mov ds,bx
    GetThread
    mov ds:capture_thread,ax
    LeaveSection ds:capture_section
;    
    mov ax,flat_sel
    mov es,ax
;    
    mov bx,ds:capture_handle
    xor eax,eax
    SetFilePos32
    SetFileSize32

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
    mov eax,es:[edx].cc_next
    mov ebx,es:[edx].cc_prev
    mov es:[ebx].cc_next,eax
    mov es:[eax].cc_prev,ebx
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
    add edi,OFFSET cc_time
    mov ecx,SIZE capture_block - OFFSET cc_time
    UserGateForce32 write_file_nr
;
    mov ecx,SIZE capture_block
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
;   NAME:           NotifyMsg
;
;   Description:    Notify reception of ethernet packet
;
;   PARAMETERS:     EDX:EAX     Data
;                   CL          Size (0..8)
;                   EBX         Identifier
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyMsg  Proc near
    push ds
    push si
;
    mov si,SEG data
    mov ds,si
    EnterSection ds:capture_section
    mov si,ds:capture_thread
    or si,si
    jz nmLeave
;    
    push es
    pushad
;    
    push eax
    push edx
    mov dx,flat_sel
    mov es,dx
    mov eax,SIZE capture_block
    AllocateSmallLinear
    mov edi,edx
    GetTime
    mov es:[edi].cc_time,eax
    mov es:[edi].cc_time+4,edx
    pop edx
    pop eax
;    
    mov es:[edi].cc_id,ebx
    mov es:[edi].cc_data,eax
    mov es:[edi].cc_data+4,edx
    mov es:[edi].cc_size,cl
    mov edx,edi
;
    mov bx,SEG data
    mov ds,bx
;
    mov eax,ds:capture_list
    or eax,eax
    jne nmQueue

nmEmpty:
    mov es:[edx].cc_prev,edx
    mov es:[edx].cc_next,edx
    mov ds:capture_list,edx
    jmp nmSignal

nmQueue:
    mov ebx,es:[eax].cc_prev
    mov es:[eax].cc_prev,edx
    mov es:[ebx].cc_next,edx
    mov es:[edx].cc_prev,ebx
    mov es:[edx].cc_next,eax    

nmSignal:
    mov bx,ds:capture_thread
    Signal
;
    popad
    pop es

nmLeave:
    LeaveSection ds:capture_section
;    
    pop si
    pop ds    
    ret
NotifyMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartCanCapture
;
;           description:    Start capturing CAN-packets
;
;       parameters:     BX      File handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_can_capture_name DB 'Start Can Capture', 0

start_can_capture       Proc
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
start_can_capture       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StopCanCapture
;
;           description:    Stop capturing can-packets
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_can_capture_name DB 'Stop Can Capture', 0

stop_can_capture    Proc
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
stop_can_capture    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_can
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_can    Proc far
    push ds
    push es
    pusha
;
    call SetupDevice
    jc icDone
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET can_thread_name
    mov esi,OFFSET can_thread_pr
    mov ax,4
    mov cx,stack0_size
    CreateThread

icDone:
    popa
    pop es
    pop ds
    retf32
init_can    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_net
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    mov ds:can_gen_hook_count,0
    InitSection ds:can_rec_section
    InitSection ds:can_send_section
    InitSection ds:capture_section
    mov ds:capture_handle,0
    mov ds:capture_thread,0
    mov ds:capture_list,0
    mov ds:can_send_used,0
    mov ds:can_send_clear,0
    mov ds:can_send_pend,0
    mov ds:can_rec_insert,0
    mov ds:can_rec_remove,0
;
    mov di,OFFSET can_id_hook_arr
    mov cx,4 * 15
    xor eax,eax
    rep stosd
;
    mov ax,cs
    mov es,ax
    mov ds,ax
    mov edi,OFFSET init_can
    HookInitPci
;
    mov esi,OFFSET reset_can_buffers
    mov edi,OFFSET reset_can_buffers_name
    mov ax,reset_can_buffers_nr
    RegisterOsGate
;
    mov esi,OFFSET send_can_bus_msg
    mov edi,OFFSET send_can_bus_msg_name
    mov ax,send_can_bus_msg_nr
    RegisterOsGate
;
    mov esi,OFFSET send_can_bus_block
    mov edi,OFFSET send_can_bus_block_name
    mov ax,send_can_bus_block_nr
    RegisterOsGate
;
    mov esi,OFFSET has_can_send_buf
    mov edi,OFFSET has_can_send_buf_name
    mov ax,has_can_send_buf_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_gen_bus_msg
    mov edi,OFFSET hook_gen_bus_msg_name
    mov ax,hook_can_gen_bus_msg_nr
    RegisterOsGate
;
    mov esi,OFFSET create_id_hook
    mov edi,OFFSET create_id_hook_name
    mov ax,create_can_id_hook_nr
    RegisterOsGate
;
    mov esi,OFFSET delete_id_hook
    mov edi,OFFSET delete_id_hook_name
    mov ax,delete_can_id_hook_nr
    RegisterOsGate
;
    mov esi,OFFSET start_can_capture
    mov edi,OFFSET start_can_capture_name
    xor dx,dx
    mov ax,start_can_capture_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET stop_can_capture
    mov edi,OFFSET stop_can_capture_name
    xor dx,dx
    mov ax,stop_can_capture_nr
    RegisterBimodalUserGate
;    
    clc
    ret
init    ENDP

code    ENDS

    END init
