;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2000, Leif Ekblad
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
; PICLCD.ASM
; PIC LCD driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME piclcd

GateSize = 16

INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\video.inc

	.386p

IO_BASE = 3A0h

OUT_MCLR_0       = 1
OUT_MCLR_1       = 2
OUT_PGM_0        = 4
OUT_PGM_1        = 8
OUT_PGC          = 10h
OUT_PGD          = 20h

NODE_CNT            = 40h

digio_queue_entry   STRUC

dqe_prev        DW ?
dqe_next        DW ?

dqe_out_size    DB ?
dqe_out_buf     DB 8 DUP(?)

dqe_in_size     DB ?
dqe_in_buf      DB 8 DUP(?)

dqe_queue       DB ?
dqe_result      DB ?
dqe_thread      DW ?

digio_queue_entry   ENDS

data_seg    STRUC

DcfThread   DW ?
DcfVal      DB ?

PicThread0  DW ?
PicThread1  DW ?

PicOut      DB ?

Data0       DB ?
Data1       DB ?

IntFlag     DB ?
ResetFlag   DB ?
IcspFlag    DB ?

IcspThread0 DW ?
IcspThread1 DW ?

PrevStat    DB ?

ListSection section_typ <>

DioQueue0   DW ?
DioQueue1   DW ?
DioCurr0    DW ?
DioCurr1    DW ?

AsyncList0  DB 256 DUP(?)

NodeArr     DB NODE_CNT DUP(?)

data_seg    ENDS

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			pic_int
;
;		DESCRIPTION:	PIC interrupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pic_int Proc far
    mov dx,IO_BASE + 10
    in al,dx
;    
    test al,8
    jz pic_int_power_done
;
    test al,80h
    jz pic_int_power_fail

pic_int_power_ok:
    mov dx,IO_BASE + 8
    mov al,ds:PicOut
    or al,0C0h
    out dx,al
     
    mov dx,IO_BASE + 14
    out dx,al
;
    mov dx,IO_BASE + 8
    and al,NOT 80h
    out dx,al
    mov ds:PicOut,al
    jmp pic_int_power_done
        
pic_int_power_fail:
    mov dx,IO_BASE + 8
    mov al,ds:PicOut
    or al,0C0h
    out dx,al
;    
    mov dx,IO_BASE + 14
    out dx,al
;
    mov dx,IO_BASE + 8
    and al,NOT 40h
    out dx,al
    mov ds:PicOut,al

pic_int_power_done:
    mov dx,IO_BASE + 10
    in al,dx
    test al,1
    jz pic_int_not_req1

pic_int_req1:
    or ds:IntFlag,1
    mov dx,IO_BASE
    in al,dx
    mov ds:Data0,al
    mov bx,ds:PicThread0
    Signal

pic_int_not_req1:
    mov dx,IO_BASE + 10
    in al,dx
    test al,10h
    jz pic_int_not_req2

pic_int_req2:
    or ds:IntFlag,2
    mov dx,IO_BASE + 2
    in al,dx
    mov ds:Data1,al
    mov bx,ds:PicThread1
    Signal
    
pic_int_not_req2:    
    ret
pic_int Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DioInsert
;
;		DESCRIPTION:	Insert entry into digital-io queue
;
;       PARAMETERS:     DS:DI       Queue
;                       ES          Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioInsert	Proc near
	push di
	mov di,[di]
	or di,di
	je ins_empty
;	
	push ds
	push si
	mov ds,di
	mov si,ds:dqe_prev
	mov ds:dqe_prev,es
	mov ds,si
	mov ds:dqe_next,es
	mov es:dqe_next,di
	mov es:dqe_prev,si
	pop si
	pop ds
	pop di
	jmp ins_done
	
ins_empty:
	mov es:dqe_next,es
	mov es:dqe_prev,es
	pop di
	mov [di],es

ins_done:
    ret
DioInsert   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DioRemove
;
;		DESCRIPTION:	Remove head entry from digital-io queue
;
;       PARAMETERS:     DS:SI       Queue
;
;       RETURNS:        ES          Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioRemove	Proc near
	push si
	mov es,[si]
	push di
	push ds
	mov di,es:dqe_next
	cmp di,[si]
	mov [si],di
	mov si,es:dqe_prev
	mov ds,di
	mov ds:dqe_prev,si
	mov ds,si
	mov ds:dqe_next,di
	pop ds
	pop di
	pop si
	jne rem_done
	
	mov word ptr [si],0

rem_done:
    ret
DioRemove   Endp
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioCheckReady1
;
;		description:	Check current reqs for ready state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioCheckReady1 Proc near
    push es
    push ax
    push bx
    push cx
    push dx
    push di
;    
    mov al,ds:IntFlag
    test al,1
    jz dcrDone1
;
    and ds:IntFlag, NOT 1
    mov al,ds:Data0
    test al,20h
    jz dcrQueue1
;
    movzx cx,al
    and cx,7
    or cx,cx
    push cx
    jz dcrAsyncOk1
;
    mov ax,ds
    mov es,ax
    mov di,OFFSET AsyncList0

dcrAsyncLoop1:
    Swap
    mov dx,IO_BASE
    in al,dx
    stosb    
    Swap
    loop dcrAsyncLoop1

dcrAsyncOk1:    
    pop cx
    jmp dcrDone1
    
dcrQueue1:
    mov ax,ds:DioCurr0
    or ax,ax
    jz dcrDone1
;
    mov es,ax
    mov al,ds:Data0
    mov es:dqe_result,al
;
    movzx cx,al
    mov es:dqe_in_size,cl
    and cx,7
    or cx,cx
    jz dcrInputOk1
;
    mov di,OFFSET dqe_in_buf

dcrInputLoop1:
    Swap
    mov dx,IO_BASE
    in al,dx
    stosb    
    Swap
    loop dcrInputLoop1

dcrInputOk1:    
    mov ds:DioCurr0,0
    mov bx,es:dqe_thread
    Signal

dcrDone1: 
    pop di
    pop dx
    pop cx
    pop bx    
    pop ax
    pop es
    ret
DioCheckReady1 Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioCheckReady2
;
;		description:	Check current reqs for ready state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioCheckReady2 Proc near
    push es
    push ax
    push bx
    push cx
    push dx
    push di
;    
    mov al,ds:IntFlag
    test al,2
    jz dcrDone2
;
    and ds:IntFlag, NOT 2
    mov al,ds:Data1
    test al,20h
    jz dcrQueue2
;
;    jmp dcrDone2
    
dcrQueue2:
    mov ax,ds:DioCurr1
    or ax,ax
    jz dcrDone2
;
    mov es,ax
    mov al,ds:Data1
    mov es:dqe_result,al
;
    movzx cx,al
    mov es:dqe_in_size,cl
    and cx,7
    or cx,cx
    jz dcrInputOk2
;
    mov di,OFFSET dqe_in_buf

dcrInputLoop2:
    Swap
    mov dx,IO_BASE + 2
    in al,dx
    stosb    
    Swap
    loop dcrInputLoop2

dcrInputOk2:    
    mov ds:DioCurr1,0
    mov bx,es:dqe_thread
    Signal

dcrDone2:
    pop di
    pop dx
    pop cx
    pop bx    
    pop ax
    pop es
    ret
DioCheckReady2 Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioCheckIdle1
;
;		description:	Dio check idle channels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioCheckIdle1   Proc near
    push es
    push ax
    push cx
    push dx
    push si
;
    mov ax,ds:DioCurr0
    or ax,ax
    jnz dciDone1
;
    test ds:IcspFlag,1
    jz dciNoIcsp1
;
    xor bx,bx
    xchg bx,ds:IcspThread0
    or bx,bx
    jz dciDone1
;
    Signal
    jmp dciDone1    

dciNoIcsp1:    
    mov si,OFFSET DioQueue0
    mov ax,[si]
    or ax,ax
    jz dciDone1
;
    call DioRemove
    mov ds:DioCurr0,es
;
    mov si,OFFSET dqe_out_buf
    movzx cx,es:dqe_out_size
    mov dx,IO_BASE

dciOutputLoop1:
    mov al,es:[si]
    out dx,al
    inc si
    Swap
    loop dciOutputLoop1
;    
    mov al,-1
    out dx,al

dciDone1:
    pop si
    pop dx
    pop cx
    pop ax
    pop es
    ret
DioCheckIdle1  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioCheckIdle2
;
;		description:	Dio check idle channels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioCheckIdle2   Proc near
    push es
    push ax
    push cx
    push dx
    push si
;    
    mov ax,ds:DioCurr1
    or ax,ax
    jnz dciDone2
;
    test ds:IcspFlag,2
    jz dciNoIcsp2
;
    xor bx,bx
    xchg bx,ds:IcspThread1
    or bx,bx
    jz dciDone2
;
    Signal
    jmp dciDone2

dciNoIcsp2:    
    mov si,OFFSET DioQueue1
    mov ax,[si]
    or ax,ax
    jz dciDone2
;
    call DioRemove
    mov ds:DioCurr1,es
;
    mov si,OFFSET dqe_out_buf
    movzx cx,es:dqe_out_size
    mov dx,IO_BASE + 2

dciOutputLoop2:
    mov al,es:[si]
    out dx,al
    inc si
    Swap
    loop dciOutputLoop2
;   
    mov al,-1
    out dx,al

dciDone2:
    pop si
    pop dx
    pop cx
    pop ax
    pop es
    ret
DioCheckIdle2   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateDirectReq
;
;		description:	Create dio req, specified queue
;
;       PARAMETERS:     AL      Device # (bit 1) + Line # (bit 0)
;                       BL      Cmd #
;                       DL      Line #
;                       DH      Node #
;                       CX      Data size
;                       FS:SI   Data buffer
;
;       RETURNS:        ES      Cmd block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDirectReq   Proc near
    push cx
    push si
    push di
;    
    push ax
    mov eax,SIZE digio_queue_entry
    AllocateSmallGlobalMem
    pop ax
    mov es:dqe_queue,al
    mov es:dqe_result,-1
;
    test al,1
    jz cdrUnit0

cdrUnit1:
    mov al,80h
    jmp cdrUnitOk

cdrUnit0:
    mov al,40h

cdrUnitOk:
    or al,dh
    mov es:dqe_out_buf,al
;    
    mov al,dl
    shl al,3
    or al,bl
    mov es:dqe_out_buf+1,al
    mov es:dqe_out_size,2
;
    or cx,cx
    jz cdrDone
;
    add es:dqe_out_size,cl
    mov di,2    

cdrDataLoop:
    lods byte ptr fs:[si]
    mov es:[di].dqe_out_buf,al
    inc di
    loop cdrDataLoop

cdrDone:
    pop di
    pop si
    pop cx       
    ret
CreateDirectReq    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateBroadcastReq
;
;		description:	Create dio req, broadcast mode
;
;       PARAMETERS:     AL      Device # (bit 1)
;                       BL      Cmd #
;                       DL      Line #
;                       DH      Node #
;                       CX      Data size
;                       FS:SI   Data buffer
;
;       RETURNS:        ES      Cmd block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBroadcastReq   Proc near
    push cx
    push si
    push di
;    
    push ax
    mov eax,SIZE digio_queue_entry
    AllocateSmallGlobalMem
    pop ax
    mov es:dqe_queue,al
    mov es:dqe_result,-1
;
    mov al,0C0h
    or al,dh
    mov es:dqe_out_buf,al
;    
    mov al,dl
    shl al,3
    or al,bl
    mov es:dqe_out_buf+1,al
    mov es:dqe_out_size,2
;
    or cx,cx
    jz cdbDone
;
    add es:dqe_out_size,cl
    mov di,2    

cdbDataLoop:
    lods byte ptr fs:[si]
    mov es:[di].dqe_out_buf,al
    inc di
    loop cdbDataLoop    

cdbDone:
    pop di
    pop si
    pop cx       
    ret
CreateBroadcastReq    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateAdcReq
;
;		description:	Create ADC dio req
;
;       PARAMETERS:     DL      Line #
;                       DH      Node #
;
;       RETURNS:        ES      Cmd block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateAdcReq   Proc near
    push ax
    mov eax,SIZE digio_queue_entry
    AllocateSmallGlobalMem
    pop ax
    mov es:dqe_queue,0
    mov es:dqe_result,-1
    mov es:dqe_out_buf,dh
;    
    mov al,dl
    shl al,3
    or al,2
    mov es:dqe_out_buf+1,al
    mov es:dqe_out_size,2
    ret
CreateAdcReq    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    QueueReq
;
;		description:	Queue dio req
;
;       PARAMETERS:     ES      Cmd block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

QueueReq   Proc near
    push ds
    push ax
    push bx
    push di
;   
    mov ax,piclcd_data_sel
    mov ds,ax    
    ClearSignal
    GetThread
    mov es:dqe_thread,ax
;    
    EnterSection ds:ListSection
;
    movzx ax,es:dqe_queue
    and al,2    
    mov di,OFFSET DioQueue0
    add di,ax
    call DioInsert
;    
    LeaveSection ds:ListSection
;
    movzx ax,es:dqe_queue
    and al,2    
    mov bx,OFFSET PicThread0
    add bx,ax
    mov bx,ds:[bx]
    Signal    
;
    pop di
    pop bx
    pop ax
    pop ds 
    ret
QueueReq    Endp    
       
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioReq
;
;		description:    Dio req
;
;       PARAMETERS:     BL      Cmd #
;                       DL      Line #
;                       DH      Node #
;                       CX      Data size
;                       FS:SI   Data buffer   
;
;       Returns:        ES      Cmd block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioReq  Proc near
    push bp
    sub sp,4
    mov bp,sp
;    
    push ds
    push ax
;    
    mov ax,piclcd_data_sel
    mov ds,ax
    push bx
    movzx bx,dh
    mov al,ds:[bx].NodeArr
    pop bx
    cmp al,-1
    je drAll
;
    movzx ax,al
    call CreateDirectReq
    call QueueReq

drWaitOne:
    WaitForSignal
;
    mov al,es:dqe_result
    cmp al,-1
    je drWaitOne
;    
    test al,0C0h
    clc
    jnz drDone
;
    FreeMem
    push bx
    movzx bx,dh
    mov byte ptr ds:[bx].NodeArr,-1
    pop bx
    stc
    jmp drDone
    
drAll:
    xor al,al
    call CreateBroadcastReq
    call QueueReq
    mov [bp],es
;
    mov al,2
    call CreateBroadcastReq
    call QueueReq
    mov [bp+2],es

drWaitAll:    
    WaitForSignal
    mov es,[bp]
    mov al,es:dqe_result
    cmp al,-1
    je drWaitAll
;
    mov es,[bp+2]
    mov al,es:dqe_result
    cmp al,-1
    je drWaitAll
;
    mov es,[bp]
    mov al,es:dqe_result
    test al,0C0h
    jz drDel1
;
    mov es,[bp+2]
    FreeMem
;    
    mov es,[bp]
    mov al,es:dqe_result
    test al,80h
    jnz drCh11

drCh10:
    xor al,al
    jmp drInsertNode 

drCh11:
    mov al,1
    jmp drInsertNode              

drDel1:
    FreeMem
    mov word ptr [bp],0
;
    mov es,[bp+2]
    mov al,es:dqe_result
    test al,0C0h
    jz drDel2
;
    test al,80h
    jnz drCh21

drCh20:
    mov al,2
    jmp drInsertNode
    
drCh21:
    mov al,3
    jmp drInsertNode

drDel2:
    FreeMem
    stc
    jmp drDone

drInsertNode:
    push bx
    movzx bx,dh
    mov ds:[bx].NodeArr,al
    pop bx
    clc
        
drDone:   
    pop ax
    pop ds
    add sp,4
    pop bp
    ret
DioReq  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AdcReq
;
;		description:    Adc req
;
;       PARAMETERS:     DL      Line #
;                       DH      Node #
;
;       Returns:        ES      Cmd block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AdcReq  Proc near
    push ax
;
    call CreateAdcReq
    call QueueReq

adcWaitOne:
    WaitForSignal
;
    mov al,es:dqe_result
    cmp al,-1
    je adcWaitOne
;    
    test al,0C0h
    clc
    jnz adcDone
;
    FreeMem
    stc
    jmp adcDone
    
        
adcDone:   
    pop ax
    ret
AdcReq  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PicTimeout1
;
;		description:	Supervises PIC chip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PicTimeout1	Proc far
    mov ax,piclcd_data_sel
    mov ds,ax    
    or ds:ResetFlag,1
    mov bx,ds:PicThread0
	Signal
	ret
PicTimeout1	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			PIC thread 1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pic1_name	DB 'DIO 1',0

pic_thread1:
    mov ax,piclcd_data_sel
    mov ds,ax    
    or ds:ResetFlag,1
;        
    mov ax,piclcd_data_sel
    mov ds,ax    
    GetThread
    mov ds:PicThread0,ax    
    ClearSignal

ptLoop1: 
    test ds:ResetFlag,1
    jz ptNoReset1
;        
    mov dx,IO_BASE + 8
    cli
    mov al,ds:PicOut
    and al,NOT OUT_MCLR_0
    out dx,al
    mov ds:PicOut,al
    sti
;
    mov ax,250
    WaitMilliSec
;
    mov dx,IO_BASE + 8
    cli
    mov al,ds:PicOut
    or al,OUT_MCLR_0
    out dx,al
    mov ds:PicOut,al
    sti
    and ds:ResetFlag,NOT 1
;
    mov ax,ds:DioCurr0
    or ax,ax
    jz ptNoReset1
;
    mov es,ax
    mov es:dqe_result,0
    mov ds:DioCurr0,0
    mov bx,es:dqe_thread
    Signal
    
ptNoReset1:
    EnterSection ds:ListSection
    call DioCheckReady1
    call DioCheckIdle1
    LeaveSection ds:ListSection
;
	GetSystemTime
	add eax,5 * 1193000
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET PicTimeout1
	mov bx,ds:PicThread0
	StopTimer
	StartTimer
;
	WaitForSignal
    jmp ptLoop1

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PicTimeout2
;
;		description:	Supervises PIC chip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PicTimeout2	Proc far
    mov ax,piclcd_data_sel
    mov ds,ax    
    or ds:ResetFlag,2
    mov bx,ds:PicThread1
	Signal
	ret
PicTimeout2	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			PIC thread 2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pic2_name	DB 'DIO 2',0

pic_thread2:
    mov ax,piclcd_data_sel
    mov ds,ax    
    or ds:ResetFlag,2
;        
    mov ax,piclcd_data_sel
    mov ds,ax    
    GetThread
    mov ds:PicThread1,ax    
    ClearSignal

ptLoop2: 
    test ds:ResetFlag,2
    jz ptNoReset2
;    
    mov dx,IO_BASE + 8
    cli
    mov al,ds:PicOut
    and al,NOT OUT_MCLR_1
    out dx,al
    mov ds:PicOut,al
    sti
;
    mov ax,250
    WaitMilliSec
;
    mov dx,IO_BASE + 8
    cli
    mov al,ds:PicOut
    or al,OUT_MCLR_1
    out dx,al
    mov ds:PicOut,al
    sti
    and ds:ResetFlag,NOT 2
;
    mov ax,ds:DioCurr1
    or ax,ax
    jz ptNoReset2
;
    mov es,ax
    mov es:dqe_result,0
    mov ds:DioCurr1,0
    mov bx,es:dqe_thread
    Signal
    
ptNoReset2:
    EnterSection ds:ListSection
    call DioCheckReady2
    call DioCheckIdle2
    LeaveSection ds:ListSection
;
	GetSystemTime
	add eax,5 * 1193000
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET PicTimeout2
	mov bx,ds:PicThread1
	StopTimer
	StartTimer
;    
	WaitForSignal
    jmp ptLoop2

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			OpenICSP
;
;		DESCRIPTION:	Open ICSP handle
;
;		PARAMETERS:		AL		Device #
;
;       RETURNS:        BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_icsp_name	DB 'Open ICSP', 0

open_icsp    Proc far
    push ds
    push dx
;    
    cmp al,1
    je oicsp1
;
    cmp al,2
    je oicsp2
    jmp oicspFail

oicsp1:
	mov bx,piclcd_data_sel
	mov ds,bx
;	
    ClearSignal
    GetThread
    mov ds:IcspThread0,ax
    or ds:IcspFlag,1
    mov bx,ds:PicThread0
    Signal
    WaitForSignal
;    
	mov dx,IO_BASE + 8
;	
    cli
	mov al,ds:PicOut
	and al,NOT (OUT_MCLR_0 OR OUT_PGM_0 OR OUT_PGC OR OUT_PGD)
    out dx,al
	mov ds:PicOut,al
	sti
;
    mov ax,25
    WaitMilliSec
;
    cli
    mov al,ds:PicOut
    or al,OUT_PGM_0
    out dx,al
    mov ds:PicOut,al
    sti
;
    cli
    mov al,ds:PicOut
    or al,OUT_MCLR_0
    out dx,al
    mov ds:PicOut,al
    sti
;
    mov ax,8
    WaitMilliSec
;        
    mov bx,6DA0h
    clc
    jmp oicspDone

oicsp2:
	mov bx,piclcd_data_sel
	mov ds,bx
;	
    ClearSignal
    GetThread
    mov ds:IcspThread1,ax
    or ds:IcspFlag,2
    mov bx,ds:PicThread1
    Signal
    WaitForSignal
;    
	mov dx,IO_BASE + 8
;	
    cli
	mov al,ds:PicOut
	and al,NOT (OUT_MCLR_1 OR OUT_PGM_1 OR OUT_PGC OR OUT_PGD)
    out dx,al
	mov ds:PicOut,al
	sti
;
    mov ax,25
    WaitMilliSec
;
    cli
    mov al,ds:PicOut
    or al,OUT_PGM_1
    out dx,al
    mov ds:PicOut,al
    sti
;
    cli
    mov al,ds:PicOut
    or al,OUT_MCLR_1
    out dx,al
    mov ds:PicOut,al
    sti
;
    mov ax,8
    WaitMilliSec
;        
    mov bx,6DA1h
    clc
    jmp oicspDone

oicspFail:
    xor bx,bx
    stc

oicspDone:            
    pop dx
    pop ds
    retf32
open_icsp   Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CloseICSP
;
;		DESCRIPTION:	Close ICSP handle
;
;		PARAMETERS:		BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_icsp_name	DB 'Close ICSP', 0

close_icsp    Proc far
    push ds
    push ax
    push dx
;    
    mov ax,bx
    and ax,NOT 1
    cmp ax,6DA0h
    jne ciFail
;    
    mov al,bl
    and al,1
    cmp al,1
    je ci2

ci1:
	mov bx,piclcd_data_sel
	mov ds,bx
	mov dx,IO_BASE + 8
;	
    cli
	mov al,ds:PicOut
	and al,NOT (OUT_MCLR_0 OR OUT_PGM_0 OR OUT_PGC OR OUT_PGD)
    out dx,al
	mov ds:PicOut,al
	sti
;
    mov ax,10
    WaitMilliSec
;    
    cli
    mov al,ds:PicOut
    or al,OUT_MCLR_0
    out dx,al
    mov ds:PicOut,al
    sti
;
    and ds:IcspFlag,NOT 1
    mov ds:IcspThread0,0
    mov bx,ds:PicThread0
    Signal
;	
    clc    	
    jmp ciDone

ci2:
	mov bx,piclcd_data_sel
	mov ds,bx
	mov dx,IO_BASE + 8
;	
    cli
	mov al,ds:PicOut
	and al,NOT (OUT_MCLR_1 OR OUT_PGM_1 OR OUT_PGC OR OUT_PGD)
    out dx,al
	mov ds:PicOut,al
	sti
;
    mov ax,10
    WaitMilliSec
;    
    cli
    mov al,ds:PicOut
    or al,OUT_MCLR_1
    out dx,al
    mov ds:PicOut,al
    sti    	
;
    and ds:IcspFlag,NOT 2
    mov ds:IcspThread1,0
    mov bx,ds:PicThread1
    Signal
;    
    clc
    jmp ciDone

ciFail:
    stc

ciDone:
    pop dx
    pop ax
    pop ds
    retf32
close_icsp   Endp


PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteICSPCommand
;
;		DESCRIPTION:	Write ICSP command
;
;		PARAMETERS:		BX      Handle
;                       EAX     Command
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_icsp_cmd_name	DB 'Write ICSP Cmd', 0

write_icsp_cmd    Proc far
    push ds
    push ax
    push bx
    push dx
;
    and bx,NOT 1
    cmp bx,6DA0h
    jne wicFail
;    
	mov bx,piclcd_data_sel
	mov ds,bx
	mov dx,IO_BASE + 8
;
    mov ah,al
    mov cx,6

wicLoop:
    mov al,ah
    and al,1
    shl al,5
    or al,ds:PicOut
    or al,OUT_PGC
    out dx,al
    and al,NOT OUT_PGC
    out dx,al
;        
    shr ah,1
    loop wicLoop
;
    clc
    jmp wicDone

wicFail:
    stc

wicDone:
    pop dx
    pop bx
    pop ax
    pop ds        
    retf32
write_icsp_cmd   Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteICSPData
;
;		DESCRIPTION:	Write ICSP data
;
;		PARAMETERS:		BX      Handle
;                       EAX     Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_icsp_data_name	DB 'Write ICSP Data', 0

write_icsp_data    Proc far
    push ds
    push ax
    push bx
    push dx
;
    and bx,NOT 1
    cmp bx,6DA0h
    jne widFail
;    
	mov bx,piclcd_data_sel
	mov ds,bx
	mov dx,IO_BASE + 8
;
    mov bx,ax
    shl bx,1
    and bx,7FFEh
    mov cx,16

widLoop:
    mov al,bl
    and al,1
    shl al,5
    or al,ds:PicOut
    or al,OUT_PGC
    out dx,al
    and al,NOT OUT_PGC
    out dx,al
;        
    shr bx,1
    loop widLoop
;
    clc
    jmp widDone

widFail:
    stc

widDone:
    pop dx
    pop bx
    pop ax
    pop ds        
    retf32
write_icsp_data   Endp


PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadICSPData
;
;		DESCRIPTION:	Read ICSP data
;
;		PARAMETERS:		BX      Handle
;                       
;       RETURNS:        EAX     Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_icsp_data_name	DB 'Read ICSP Data', 0

read_icsp_data    Proc far
    stc
    retf32
read_icsp_data   Endp


PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ToggleSerialLine
;
;		DESCRIPTION:	Toggle serial input line
;
;		PARAMETERS:		DL		Line #
;						DH		Device #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_serial_line_name	DB 'Toggle Serial Line', 0

toggle_serial_line	Proc far
    push es
    push bx
    push cx
;    
    mov bl,4
    xor cx,cx
    call DioReq
    mov ax,es
    or ax,ax
    stc
    jz tslDone
;    
    FreeMem   
    clc

tslDone:
    pop cx
    pop bx 
    pop es   
	retf32
toggle_serial_line  Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadSerialLines
;
;		DESCRIPTION:	Read serial lines
;
;		PARAMETERS:		DH		Device #
;
;		RETURNS:		AL		State
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_serial_lines_name	DB 'Read Serial Lines', 0

read_serial_lines	Proc far
    push es
	push bx
	push cx
	push dx
;
    mov bl,5
    xor dl,dl
    xor cx,cx
    call DioReq
    mov ax,es
    or ax,ax
    stc
    jz rslDone
;    
    mov al,es:dqe_in_buf
    FreeMem
    clc

rslDone:    
    pop dx
	pop cx
	pop bx
	pop es
	retf32
read_serial_lines	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteSerialVal
;
;		DESCRIPTION:	Write serial value
;
;		PARAMETERS:		DL		Line #
;						DH		Device #
;						EAX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_serial_val_name	DB 'Write Serial Value', 0

write_serial_val	Proc far
    push bp
    sub sp,4
    mov bp,sp
    push es
    push fs
    push eax
    push bx
    push cx
    push si
;
    mov bl,al
    and bl,3Fh
    mov [bp],bl
;    
    shr eax,6
    mov bl,al
    and bl,3Fh
    mov [bp+1],bl
;    
    shr eax,6
    mov bl,al
    and bl,3Fh
    mov [bp+2],bl
;    
    shr eax,6
    mov bl,al
    and bl,3Fh
    mov [bp+3],bl
;    
    mov ax,ss
    mov fs,ax
    mov si,bp
    mov cx,4
;
    mov bl,3
    call DioReq
    mov ax,es
    or ax,ax
    stc
    jz wsvDone
;    
    FreeMem
    clc

wsvDone:
    pop si
    pop cx
    pop bx
    pop eax
    pop fs
    pop es
    add sp,4
    pop bp    
	retf32
write_serial_val	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadSerialVal
;
;		DESCRIPTION:	Read serial val
;
;		PARAMETERS:		DL		Line #
;						DH		Device #
;
;		RETURNS:		EAX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_serial_val_name	DB 'Read Serial Value', 0

read_serial_val	Proc far
    push es
	push bx
	push cx
	push dx
;
    test dh,0C0h
    jz rsvSerial
;
    and dh,3Fh
    call AdcReq
    mov ax,es
    or ax,ax
    stc
    jz rsvDone
;    
    xor eax,eax
    mov al,es:dqe_in_buf+1
    shl eax,6
    or al,es:dqe_in_buf
;    
    FreeMem
    clc
    jmp rsvDone

rsvSerial:
    mov bl,2
    xor cx,cx
    call DioReq
    mov ax,es
    or ax,ax
    stc
    jz rsvDone
;
    xor eax,eax
    mov bx,OFFSET dqe_in_buf + 3
    mov al,es:[bx]
    and al,3Fh
    dec bx
;
    shl eax,6
    mov dl,es:[bx]
    and dl,3Fh
    or al,dl
    dec bx
;
    shl eax,6
    mov dl,es:[bx]
    and dl,3Fh
    or al,dl
    dec bx
;
    shl eax,6
    mov dl,es:[bx]
    and dl,3Fh
    or al,dl
    FreeMem
    clc

rsvDone:    
    pop dx
	pop cx
	pop bx
	pop es
	retf32
read_serial_val	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			DCF thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dcf_name	DB 'DCF',0

dcf_thread:
	mov ax,43h
	EnableFocus
;
    mov ax,piclcd_data_sel
    mov ds,ax    
    GetThread
    mov ds:DcfThread,ax    
    ClearSignal

dcf_thread_loop: 
	WaitForSignal
	mov al,ds:DcfVal
	WriteChar
    jmp dcf_thread_loop

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitDriver
;
;		DESCRIPTION:	Init Driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitDriver  Proc far
    push ds
    push es
    pushad
;    
	mov al,10
	mov bx,piclcd_data_sel
	mov ds,bx
	mov bx,cs
	mov es,bx
	mov di,OFFSET pic_int
	RequestPrivateIrqHandler
;
    cli
    mov dx,IO_BASE + 8
    mov al,ds:PicOut
    or al,0C0h
    out dx,al
    mov ds:PicOut,al
    sti
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET pic1_name
	mov si,OFFSET pic_thread1
	mov ax,4
	mov cx,100h
	CreateThread
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET pic2_name
	mov si,OFFSET pic_thread2
	mov ax,4
	mov cx,100h
	CreateThread
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET dcf_name
	mov si,OFFSET dcf_thread
	mov ax,4
	mov cx,100h
;	CreateProcess
;
    popad
    pop es
    pop ds
    ret
InitDriver  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init device
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
init	PROC far
	push ds
	pusha
;
	mov bx,piclcd_code_sel
	InitDevice
;
	mov eax,SIZE data_seg
	mov bx,piclcd_data_sel
	AllocateFixedSystemMem
;	
    mov es:DcfThread,0
	mov es:PicThread0,0
	mov es:PicThread1,0
	mov es:DioQueue0,0
	mov es:DioQueue1,0
	mov es:DioCurr0,0
	mov es:DioCurr1,0
	mov es:IntFlag,0
	mov es:ResetFlag,0
	mov es:IcspFlag,0
	mov es:IcspThread0,0
	mov es:IcspThread1,0	
    xor al,al
	mov es:PicOut,al
	mov dx,IO_BASE + 8
	out dx,al
	InitSection es:ListSection
;
    mov di,NodeArr
    mov cx,NODE_CNT
    mov al,-1
    rep stosb
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
;	mov dx,IO_BASE + 3
;	xor al,al
;	out dx,al
;	
;    mov dx,IO_BASE + 6
;    out dx,al
;    
;    mov al,0
;    mov dx,IO_BASE + 2
;    out dx,al
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET InitDriver
	HookInitTasking
;
	mov si,OFFSET open_icsp
	mov di,OFFSET open_icsp_name
	mov ax,open_icsp_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET close_icsp
	mov di,OFFSET close_icsp_name
	mov ax,close_icsp_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET write_icsp_cmd
	mov di,OFFSET write_icsp_cmd_name
	mov ax,write_icsp_cmd_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET write_icsp_data
	mov di,OFFSET write_icsp_data_name
	mov ax,write_icsp_data_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET read_icsp_data
	mov di,OFFSET read_icsp_data_name
	mov ax,read_icsp_data_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET read_serial_lines
	mov di,OFFSET read_serial_lines_name
	mov ax,read_serial_lines_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET toggle_serial_line
	mov di,OFFSET toggle_serial_line_name
	mov ax,toggle_serial_line_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET write_serial_val
	mov di,OFFSET write_serial_val_name
	mov ax,write_serial_val_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET read_serial_val
	mov di,OFFSET read_serial_val_name
	mov ax,read_serial_val_nr
	RegisterBimodalUserGate
;
	popa
	pop ds
	ret
init	ENDP

code	ENDS

	END init

