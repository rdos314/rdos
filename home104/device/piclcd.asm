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

DQE_STAT_DONE       = 1
DQE_STAT_TIMEOUT    = 2
DQE_STAT_SUCCESS    = 4
DQE_STAT_COMPLETE   = 8

digio_queue_entry   STRUC

dqe_prev    DW ?
dqe_next    DW ?

dqe_stat    DB ?
dqe_device  DB ?
dqe_val     DB ?
dqe_node    DB ?
dqe_cmd     DB ?
dqe_line    DB ?
dqe_timeout DD ?
dqe_data    DD ?
dqe_proc    DW ?
dqe_action  DW ?
dqe_thread  DW ?

digio_queue_entry   ENDS

data_seg    STRUC

DcfThread   DW ?
DcfVal      DB ?

PicThread   DW ?
PicStatus   DB ?

PicOut      DB ?

Data0       DB ?
Data1       DB ?

PrevStat    DB ?

ListSection section_typ <>

DioQueue    DW ?,?,?
DioCurr     DW ?,?,?

NodeArr     DB NODE_CNT DUP(?)

data_seg    ENDS

    LCD_WIDTH = 240
    LCD_HEIGHT = 128

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
    mov dx,IO_BASE
    in al,dx
    mov ds:Data0,al
    mov bx,ds:PicThread
    Signal

pic_int_not_req1:
    mov dx,IO_BASE + 10
    in al,dx
    test al,10h
    jz pic_int_not_req2

pic_int_req2:
    mov dx,IO_BASE + 2
    in al,dx
    mov ds:Data1,al
    mov bx,ds:PicThread
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
;		NAME:			DioTimeout
;
;		description:	Sends a signal when a timeout expires
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioTimeout	Proc far
    push es
;    
    mov es,cx
    or es:dqe_stat,DQE_STAT_TIMEOUT
;
	mov bx,piclcd_data_sel
	mov ds,bx
    mov bx,ds:PicThread
    Signal
;
    pop es    
    ret
DioTimeout  Endp
    
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DioRun
;
;		description:	Run dio-command
;
;       PARAMETERS:     ES      Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioRun  Proc near 
    push es
    pushad
;
    movzx ax,es:dqe_device
   
drClearLoop:
    push ax
    mov cl,al
    mov ah,2
    shl ah,cl
;    
    mov dx,IO_BASE + 2
    in al,dx
    test al,ah
    pop ax
    jnz drDo
;
    mov dx,IO_BASE + 0Ah
    add dx,ax
    add dx,ax
    push ax
    in al,dx
    pop ax
    jmp drClearLoop

drDo:
    and es:dqe_stat,NOT (DQE_STAT_DONE OR DQE_STAT_TIMEOUT)
    mov di,ax
    add di,di
    add di,OFFSET DioCurr
    mov [di],es
;   
    mov dx,IO_BASE + 0Ah
    add dx,ax
    add dx,ax
    mov al,es:dqe_val
    out dx,al
;
    mov cx,es
	GetSystemTime
	add eax,es:dqe_timeout
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET DioTimeout
	mov bx,cx
	StartTimer
;
    popad
    pop es
    ret
DioRun  Endp
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioStartReq
;
;		description:	Start a request
;
;       PARAMETERS:     AX      Queue #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioStartReq Proc near
    push es
    push si
    push di
;    
    mov si,ax
    add si,si
    add si,OFFSET DioQueue
    mov di,[si]
    or di,di
    jz dsrDone
;
    call DioRemove
    call DioRun

dsrDone:
    pop di
    pop si
    pop es
    ret
DioStartReq Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioCheckReq
;
;		description:	Check current req
;
;       PARAMETERS:     AX      Queue #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioCheckReq Proc near
    push es
    pushad
;    
    mov si,ax
    add si,si
    add si,OFFSET DioCurr
    mov es,[si]
;
    test es:dqe_stat,DQE_STAT_DONE
    jnz dcrRemove
;
    test es:dqe_stat,DQE_STAT_TIMEOUT
    jz dcrDone
;
    push ax
    mov cl,al
    mov ah,2
    shl ah,cl
;    
    mov dx,IO_BASE + 2
    in al,dx
    test al,ah
    pop ax
    jnz dcrRemove
;
    mov dx,IO_BASE + 0Ah
    add dx,ax
    add dx,ax
    in al,dx
    and al,3Fh
    mov es:dqe_val,al
    or es:dqe_stat,DQE_STAT_DONE

dcrRemove:
    mov word ptr [si],0
    mov bx,es
    StopTimer
    call es:dqe_proc
    jc dcrFree
;
    mov ds:[si],es
    call DioRun
    jmp dcrDone

dcrFree:
    or es:dqe_stat,DQE_STAT_COMPLETE
    mov bx,es:dqe_thread
    Signal

dcrDone:
    popad
    pop es
    ret
DioCheckReq Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioUpdate
;
;		description:	Dio Update
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioUpdate   Proc near
    push ax
    push cx
    push dx
    push si
;    
    mov cx,3
    xor ax,ax
    mov si,OFFSET DioCurr
    
duLoop:
    mov dx,[si]
    or dx,dx
    jz duFree
;
    call DioCheckReq
    mov dx,[si]
    or dx,dx
    jnz duNext

duFree:
    call DioStartReq

duNext:   
    add si,2
    inc ax
    loop duLoop
;
    pop si
    pop dx
    pop cx
    pop ax
    ret
DioUpdate   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioOneReq
;
;		description:	Dio req, specified queue
;
;       PARAMETERS:     AX      Queue #
;                       EDX     Timeout in tics
;                       EBP     Data
;                       BL      Cmd #
;                       CL      Line #
;                       CH      Node #
;                       DI      Action proc
;
;       RETURNS:        EAX     Data returned
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioOneReq   Proc near
    push ds
    push es
    push bx
    push di
;    
    ClearSignal
    push ax
    mov ax,piclcd_data_sel
    mov ds,ax    
    mov eax,SIZE digio_queue_entry
    AllocateSmallGlobalMem
    GetThread
    mov es:dqe_thread,ax
    pop ax
    mov es:dqe_device,al
    mov es:dqe_stat,0
    mov es:dqe_timeout,edx
    mov es:dqe_proc,OFFSET node_proc
    mov es:dqe_node,ch
    mov es:dqe_line,cl
    mov es:dqe_cmd,bl
    mov es:dqe_data,ebp
    mov es:dqe_action,di
    EnterSection ds:ListSection
    push ax
    call es:dqe_proc
    pop ax
;
    mov di,OFFSET DioQueue
    add di,ax
    add di,ax
    call DioInsert
    LeaveSection ds:ListSection
;
    mov bx,ds:PicThread
    Signal    
    WaitForSignal
;
    mov eax,es:dqe_data
    mov bl,es:dqe_stat
    FreeMem
    test bl,DQE_STAT_SUCCESS
    stc
    jz dorDone
;
    clc

dorDone:
    pop di
    pop bx
    pop es
    pop ds
    ret
DioOneReq    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioAllReq
;
;		description:	Broadcase dio req
;
;       PARAMETERS:     EDX     Timeout in tics
;                       EBP     Data
;                       BL      Cmd #
;                       CL      Line #
;                       CH      Node #
;                       DI      Action proc
;
;       RETURNS:        EAX     Data returned
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioAllReq   Proc near
    push ds
    push es
    push fs
    push bx
    push si
    push di
;    
    ClearSignal
    mov ax,piclcd_data_sel
    mov ds,ax    
    mov eax,6
    AllocateSmallGlobalMem
    mov ax,es
    mov fs,ax
    xor si,si
;
    xor ax,ax    

darAllocLoop:
    push ax
    mov eax,SIZE digio_queue_entry
    AllocateSmallGlobalMem
    GetThread
    mov fs:[si],es
    mov es:dqe_thread,ax
    pop ax
    mov es:dqe_device,al
    mov es:dqe_stat,0
    mov es:dqe_timeout,edx
    mov es:dqe_proc,OFFSET node_proc
    mov es:dqe_node,ch
    mov es:dqe_line,cl
    mov es:dqe_cmd,bl
    mov es:dqe_data,ebp
    mov es:dqe_action,di
    EnterSection ds:ListSection
    push ax
    call es:dqe_proc
    pop ax
;
    push di
    mov di,OFFSET DioQueue
    add di,ax
    add di,ax
    call DioInsert
    pop di
    LeaveSection ds:ListSection
;    
    add si,2
    inc ax
    cmp ax,3
    jne darAllocLoop    
;
    mov bx,ds:PicThread
    Signal

darSignalLoop:
    WaitForSignal
;   
    mov cx,3
    xor si,si

darCheckLoop:
    mov es,fs:[si]
    test es:dqe_stat, DQE_STAT_COMPLETE
    jz darSignalLoop
;
    add si,2
    loop darCheckLoop    
; 
    mov cx,3
    xor si,si

darFreeLoop:
    mov es,fs:[si]
    mov eax,es:dqe_data
    mov bl,es:dqe_stat
    test bl,DQE_STAT_SUCCESS
    jnz darOk
;
    FreeMem
    add si,2
    loop darFreeLoop    
;
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
    stc
    jmp darDone

darOk:
    movzx bx,es:dqe_node
    push ax
    mov ax,si
    shr ax,1
    mov ds:[bx].NodeArr,al
    pop ax
    FreeMem
    add si,2
    sub cx,1
    jz darOkDone

darOkLoop:
    mov es,fs:[si]
    FreeMem
    add si,2
    loop darOkLoop

darOkDone:
    mov dx,fs
    mov es,dx
    xor dx,dx
    mov fs,dx
    FreeMem
    clc    

darDone:
    pop di
    pop si
    pop bx
    pop fs
    pop es
    pop ds
    ret
DioAllReq    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioReq
;
;		description:    Dio req
;
;       PARAMETERS:     EDX     Timeout in tics
;                       EBP     Data
;                       BL      Cmd #
;                       CL      Line #
;                       CH      Node #
;                       DI      Action proc
;
;       RETURNS:        EAX     Data returned
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioReq  Proc near
    push ds
;    
    mov ax,piclcd_data_sel
    mov ds,ax
    push bx
    movzx bx,ch
    mov al,ds:[bx].NodeArr
    pop bx
    cmp al,-1
    je drAll
;
    movzx ax,al
    call DioOneReq
    jnc drDone
;
    push bx
    movzx bx,ch
    mov byte ptr ds:[bx].NodeArr,-1
    pop bx
    stc
    jmp drDone
    
drAll:
    call DioAllReq 

drDone:   
    pop ds
    ret
DioReq  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			node_proc
;
;       PARAMETERS:     ES      Req block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

node_proc   Proc near
    mov al,es:dqe_node
    mov es:dqe_val,al
    mov es:dqe_proc, OFFSET cmd_proc
    clc
    ret
node_proc   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			cmd_proc
;
;       PARAMETERS:     ES      Req block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cmd_proc   Proc near
    mov al,es:dqe_val
    and al,3Fh
    cmp al,1Ah
    stc
    jnz cmd_done
;    
    mov ah,es:dqe_cmd
    mov al,es:dqe_line
    shl al,3
    or al,ah
    mov es:dqe_val,al
    mov ax,es:dqe_action
    mov es:dqe_proc,ax
    clc

cmd_done:
    ret
cmd_proc   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			PIC thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pic_name	DB 'PICLCD',0

cmd DB 0E6h, 0Ah

pic_thread:
    mov ax,piclcd_data_sel
    mov ds,ax    
;    
    mov dx,IO_BASE + 8
    mov al,ds:PicOut
    and al,NOT (OUT_MCLR_0 OR OUT_MCLR_1)
    out dx,al
    mov ds:PicOut,al
;
    mov ax,250
    WaitMilliSec
;
    mov dx,IO_BASE + 8
    mov al,ds:PicOut
    or al,OUT_MCLR_0 OR OUT_MCLR_1
    out dx,al
    mov ds:PicOut,al
;        
    mov ax,piclcd_data_sel
    mov ds,ax    
    GetThread
    mov ds:PicThread,ax    
    ClearSignal
;
    int 3
    mov bx,OFFSET cmd
    mov cx,2
    mov dx,IO_BASE

OutputLoop:
    mov al,cs:[bx]
    out dx,al
    inc bx
    loop OutputLoop
;    
    mov al,-1
    out dx,al
;
    int 3
    WaitForSignal
    mov al,ds:Data0
;
    movzx cx,al
    and cx,0Fh
    or cx,cx
    jz InputDone
;

InputLoop:
    mov dx,IO_BASE
    in al,dx
    loop InputLoop

InputDone:    
    int 3    

pic_thread_loop: 
    EnterSection ds:ListSection
    call DioUpdate   
    LeaveSection ds:ListSection
	WaitForSignal
    jmp pic_thread_loop

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

toggle_proc    Proc near
    or es:dqe_stat,DQE_STAT_SUCCESS
    stc
    ret
toggle_proc    Endp

toggle_serial_line	Proc far
	push bx
	push cx
    push edx
    push di
;
    stc
    jmp tslDone
    
    push ebp
    mov ebp,5000
    mov cx,dx
    mov edx,1193 * 100
    mov di,OFFSET toggle_proc
    mov bl,4
    call DioReq
    pop ebp

tslDone:
	pop di
	pop edx
	pop cx
	pop bx
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

rl0_proc    Proc near
    mov al,es:dqe_val
    or al,al
    stc
    jz rl0_done
;    
    mov es:dqe_data,0
    mov es:dqe_val,1
    mov es:dqe_proc,OFFSET rl1_proc
    clc

rl0_done:
    ret
rl0_proc    Endp

rl1_proc    Proc near
    mov al,es:dqe_val
    test al,30h
    stc
    jz rl1_done
;    
    and eax,0Fh
    or es:dqe_data,eax
    mov es:dqe_val,2
    mov es:dqe_proc,OFFSET rl2_proc
    clc

rl1_done:
    ret
rl1_proc    Endp

rl2_proc    Proc near
    mov al,es:dqe_val
    test al,30h
    stc
    jz rl2_done
;    
    and eax,0Fh
    shl eax,4
    or es:dqe_data,eax
    mov es:dqe_val,3
    or es:dqe_stat,DQE_STAT_SUCCESS

rl2_done:
    stc
    ret
rl2_proc    Endp

read_serial_lines	Proc far
	push bx
	push cx
    push edx
    push di
;
    stc
    jmp rslDone
    
    push ebp
    mov ebp,5000
    mov ch,dh
    xor cl,cl
    mov edx,1193 * 100
    mov di,OFFSET rl0_proc
    mov bl,5
    call DioReq
    pop ebp

rslDone:
	pop di
	pop edx
	pop cx
	pop bx
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

wr0_proc    Proc near
    mov al,es:dqe_val
    or al,al
    stc
    jz wr0_done
;    
    mov eax,es:dqe_data
    and al,3Fh
    mov es:dqe_val,al
    mov es:dqe_proc,OFFSET wr1_proc
    clc

wr0_done:
    ret
wr0_proc    Endp

wr1_proc    Proc near
    mov al,es:dqe_val
    or al,al
    stc
    jz wr1_done
;    
    mov eax,es:dqe_data
    shr eax,6
    and al,3Fh
    mov es:dqe_val,al
    mov es:dqe_proc,OFFSET wr2_proc
    clc

wr1_done:
    ret
wr1_proc    Endp

wr2_proc    Proc near
    mov al,es:dqe_val
    or al,al
    stc
    jz wr1_done
;    
    mov eax,es:dqe_data
    shr eax,12
    and al,3Fh
    mov es:dqe_val,al
    mov es:dqe_proc,OFFSET wr3_proc
    clc

wr2_done:
    ret
wr2_proc    Endp

wr3_proc    Proc near
    mov al,es:dqe_val
    or al,al
    stc
    jz wr3_done
;    
    mov eax,es:dqe_data
    shr eax,18
    and al,3Fh
    mov es:dqe_val,al
    mov es:dqe_proc,OFFSET wr_check_proc
    clc

wr3_done:
    ret
wr3_proc    Endp

wr_check_proc    Proc near
    mov al,es:dqe_val
    or al,al
    jz wr_check_done
;    
    or es:dqe_stat,DQE_STAT_SUCCESS

wr_check_done:    
    stc
    ret
wr_check_proc    Endp

write_serial_val	Proc far
	push eax
	push bx
	push cx
    push edx
    push di
    push ebp
;
    stc
    jmp wsvDone
    
    mov ebp,eax
    mov cx,dx
    mov edx,1193 * 100
    mov di,OFFSET wr0_proc
    mov bl,3
    call DioReq

wsvDone:
	pop ebp
	pop di
	pop edx
	pop cx
	pop bx
	pop eax
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

rd0_proc    Proc near
    mov al,es:dqe_val
    or al,al
    stc
    jz rd0_done
;    
    mov es:dqe_data,0
    mov es:dqe_val,1
    mov es:dqe_proc,OFFSET rd1_proc
    clc

rd0_done:
    ret
rd0_proc    Endp

rd1_proc    Proc near
    mov al,es:dqe_val
    and eax,3Fh
    or es:dqe_data,eax
    mov es:dqe_val,2
    mov es:dqe_proc,OFFSET rd2_proc
    clc
    ret
rd1_proc    Endp

rd2_proc    Proc near
    mov al,es:dqe_val
    and eax,3Fh
    shl eax,6    
    or es:dqe_data,eax
    mov es:dqe_val,3
    mov es:dqe_proc,OFFSET rd3_proc
    clc
    ret
rd2_proc    Endp

rd3_proc    Proc near
    mov al,es:dqe_val
    and eax,3Fh
    shl eax,12  
    or es:dqe_data,eax
    mov es:dqe_val,4
    mov es:dqe_proc,OFFSET rd4_proc
    clc
    ret
rd3_proc    Endp

rd4_proc    Proc near
    mov al,es:dqe_val
    and eax,3Fh
    shl eax,18  
    or es:dqe_data,eax
    mov es:dqe_val,5
    mov es:dqe_proc,OFFSET rd_check_proc
    clc
    ret
rd4_proc    Endp

rd_check_proc    Proc near
    mov al,es:dqe_val
    or al,al
    jz rd_check_done
;    
    or es:dqe_stat,DQE_STAT_SUCCESS

rd_check_done:
    stc
    ret
rd_check_proc    Endp

read_serial_val	Proc far
	push bx
	push cx
    push edx
    push di
;
    stc
    jmp rsvDone

    push ebp
    mov ebp,5000
    mov cx,dx
    mov edx,1193 * 100
    mov di,OFFSET rd0_proc
    mov bl,2
    call DioReq
    pop ebp

rsvDone:
	pop di
	pop edx
	pop cx
	pop bx
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
	mov di,OFFSET pic_name
	mov si,OFFSET pic_thread
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
	mov es:PicThread,0
	mov es:DioQueue,0
	mov es:DioQueue+2,0
	mov es:DioQueue+4,0
	mov es:DioCurr,0
	mov es:DioCurr+2,0
	mov es:DioCurr+4,0
;
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

