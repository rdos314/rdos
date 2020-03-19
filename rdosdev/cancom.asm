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
; canser.asm
; CAN to serial interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\..\..\rdos\kernel\os\system.def
INCLUDE ..\..\..\rdos\kernel\user.def
INCLUDE ..\..\..\rdos\kernel\os.def
INCLUDE ..\..\..\rdos\kernel\user.inc
INCLUDE ..\..\..\rdos\kernel\os.inc
INCLUDE ..\..\..\rdos\kernel\driver.def
INCLUDE ..\..\..\rdos\kernel\os\com.inc
INCLUDE ..\..\..\rdos\kernel\os\lon.inc
INCLUDE ..\..\..\rdos\kernel\os\serio.inc

MAX_CAN_MODULES     = 15
MAX_MODULE_PORTS    = 16
MAX_NAME_SIZE       = 16

PORT_FLAG_OPEN      = 1

can_port_struc    STRUC

cp_base_struc       com_port_struc <>

cp_dev              DW ?
cp_module           DW ?
cp_port             DB ?
cp_flags            DB ?
cp_timer_active     DB ?
cp_setup1           DD ?
cp_setup2           DD ?

cp_rd_buf           DD ?,?
cp_wr_buf           DD ?,?

can_port_struc    ENDS

can_device_struc   STRUC

cd_base_struc       com_device_struc <>
cd_module           DW ?
cd_mod_port         DW ?

can_device_struc    ENDS

can_lon_struc   STRUC

cl_base_struc       lon_struc <>

cl_module           DW ?

cl_thread           DW ?
cl_id               DD ?

cl_port             DB ?
cl_open             DB ?
cl_reset            DB ?
cl_restart           DB ?

cl_rec_len          DB ?
cl_rec_size         DB ?
cl_rec_cmd          DB ?
cl_rec_buf          DB 256 DUP(?)

cl_send_pend        DB ?
cl_send_len         DB ?
cl_send_size        DB ?
cl_send_buf         DB 256 DUP(?)

can_lon_struc    ENDS

can_serio_device_struc  STRUC

csio_base           serio_struc <>

csio_module         DW ?

can_serio_device_struc  ENDS

can_module_struc    STRUC

cms_id              DD ?
cms_buffer          DW ?

cms_section         section_typ <>
cms_server_thread   DW ?
cms_session_thread  DW ?
cms_prog_thread     DW ?

cms_active_ports    DB ?
cms_online          DB ?
cms_restarted       DB ?

cms_loader_major_ver   DB ?
cms_loader_minor_ver   DB ?
cms_loader_sub_ver     DB ?

cms_major_ver       DB ?
cms_minor_ver       DB ?
cms_sub_ver         DB ?
cms_hw_id           DB ?
cms_port_count      DB ?

cms_io_in           DB ?
cms_io_out          DB ?

cms_module_id       DB 10 DUP(?)

cms_prog_sel        DW ?
cms_prog_size       DD ?

cms_prog_status     DW ?
cms_prog_return     DW ?
cms_prog_position   DD ?
cms_prog_wait_thread    DW ?

cms_dev_arr         DW MAX_MODULE_PORTS DUP(?)
cms_port_arr        DW MAX_MODULE_PORTS DUP(?)

cms_data_id         DD ?
cms_data_buf        DD ?,?
cms_data_size       DB ?
cms_has_data        DB ?

cms_prog_res        DB ?

can_module_struc    ENDS

data    SEGMENT byte public 'DATA'

com_thread          DW ?
restart_section     section_typ <>

io_dev_count        DB ?

pend_restart        DB ?
init_done           DB ?
prog_active         DB ?
prog_count          DW ?
module_count        DW ?
module_arr          DW MAX_CAN_MODULES DUP(?)

thread_name_ptr     DW ?
thread_name_str     DB MAX_NAME_SIZE DUP(?)

thread_io_name_ptr  DW ?
thread_io_name_str  DB MAX_NAME_SIZE DUP(?)

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
;   NAME:           IntReceive
;
;   DESCRIPTION:    Received interrupt data from module
;
;   PARAMETERS:     DS      SEG data
;                   EDX:EAX Data
;                   CL      Size
;                   EBX     ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IntReceive   Proc far
    cmp ebx,780000h
    jne irDone
;
    cmp cl,1
    jne irDone
;
    cmp al,0FFh
    jne irDone
;   
    push bx 
    mov bl,ds:prog_active
    or bl,bl
    jnz irNoSignal
;    
    ResetCanBuffers
    RestartCanModules

irNoSignal:    
    pop bx

irDone:    
    retf32
IntReceive  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateIntHook
;
;   DESCRIPTION:    Create a interrupt hook
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntHook    Proc near
    push ds
    push es
    pushad
;
    xor eax,eax
    mov edx,3Fh SHL 23
;
    mov di,SEG data
    mov ds,di
    mov di,cs
    mov es,di
    mov edi,OFFSET IntReceive
    CreateCanIdHook
;
    popad
    pop es
    pop ds            
    ret
CreateIntHook    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           InsertLonMsg
;
;   DESCRIPTION:    Insert Lon msg into receive queue
;   
;   PARAMETERS:     DS      lon device
;                   ES      Msg bufffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertLonMsg   Proc near
    push fs
    push bx
    push cx
;
    NotifyLonData    
    EnterSection ds:lon_section
;    
    mov fs,ds:lon_rec_buf
    mov cx,ds:lon_rec_count
    cmp cx,ds:lon_rec_size
    je ilmFree
;    
    inc cx
    mov ds:lon_rec_count,cx
    mov bx,ds:lon_rec_tail
;
    mov fs:[bx],es
    add bx,2
    mov cx,ds:lon_rec_size
    shl cx,1
    cmp bx,cx
    jnz ilmNoWrap
;
    xor bx,bx
    
ilmNoWrap:
    mov ds:lon_rec_tail,bx
    xor bx,bx
    mov es,bx
;
    mov bx,ds:lon_avail_obj
    or bx,bx
    jz ilmLonLeave
;
    mov es,bx
    SignalWait
    mov ds:lon_avail_obj,0
;
    xor ax,ax
    mov es,ax
    jmp ilmLonLeave

ilmFree:
    FreeMem

ilmLonLeave:
    LeaveSection ds:lon_section

ilmEnd:
    pop cx
    pop bx
    pop fs
    ret
InsertLonMsg   Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           ModuleReceive
;
;   DESCRIPTION:    Received data from module
;
;   PARAMETERS:     DS      Selector
;                   EDX:EAX Data
;                   CL      Size
;                   EBX     ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ModuleReceive   Proc far
    push ds
    push bx
    push ebp
;
    mov ebp,ebx
    shr ebp,18
    and bp,3

mrNormal:    
    or bp,bp
    jz mrData
;    
    cmp bp,1
    je mrSetup
;
    cmp bp,2
    je mrInt 
;
    jmp mrDone

mrInt:
    or cl,cl
    jz mrSetup
;
    cmp al,0FEh
    je mrUninit
;    
    cmp al,0FDh
    je mrProgram
;
    cmp al,0FCh    
    jne mrSetup
;
    mov al,ds:cms_hw_id
    cmp al,5
    jne mrSetup
;
    cmp cl,4
    jb mrSetup
;    
    shr ebx,20
    and bx,7
;    
    cmp bx,7
    jne mrDone
;    
    mov ebx,eax
    shr ebx,24
    xor bh,bh
    dec bx
    shl bx,1
    mov bx,ds:[bx].cms_dev_arr
    or bx,bx
    jz mrDone
;
    mov ds,bx
    shr eax,8
    mov ds:cl_rec_size,al
    mov ds:cl_rec_len,0
    mov ds:cl_rec_cmd,ah
    jmp mrLonCheck

mrUninit:
    push ds
    mov ax,SEG data
    mov ds,ax
    mov al,ds:prog_active
    mov bx,ds:com_thread
    pop ds
    or al,al
    jnz mrDone
;    
    ResetCanBuffers
    RestartCanModules
    jmp mrDone

mrProgram:
    cmp cl,2
    jne mrDone
;    
    mov ds:cms_prog_res,ah
    mov bx,ds:cms_prog_thread
    Signal
    jmp mrDone

mrSetup:    
    mov ds:cms_data_id,ebx
    mov ds:cms_data_buf,eax
    mov ds:cms_data_buf+4,edx
    mov ds:cms_data_size,cl
    mov ds:cms_has_data,1
;
    mov bx,ds:cms_session_thread
    Signal   
    jmp mrDone

mrData:
    cmp ds:cms_hw_id,5
    je mrLonData
;
    cmp ds:cms_hw_id,8
    je mrIoData
    jmp mrSerialData

mrIoData:
    shr ebx,20
    and bx,7
;    
    or bx,bx
    jnz mrDone   ; check for port 0 for now
;
    cmp cl,1
    jne mrDone
;
    mov ds:cms_io_in,al
    jmp mrDone

mrLonData:
    shr ebx,20
    and bx,7
;    
    or bx,bx
    jnz mrDone   ; check for port 0 for now
;    
    shl bx,1
    mov bx,ds:[bx].cms_dev_arr
    or bx,bx
    jz mrDone
;
    mov ds,bx
    movzx bx,ds:cl_rec_len
    mov dword ptr ds:[bx].cl_rec_buf,eax
    mov dword ptr ds:[bx].cl_rec_buf+4,edx
    add ds:cl_rec_len,cl

mrLonCheck:    
    mov cl,ds:cl_rec_len
    cmp cl,ds:cl_rec_size
    jne mrDone  
;
    mov ds:cl_rec_len,0
    mov ds:cl_rec_size,0
;    
    movzx ecx,cl
    mov eax,ecx
    inc eax
    AllocateSmallGlobalMem
    mov si,OFFSET cl_rec_buf
    xor di,di
    mov al,ds:cl_rec_cmd
    stosb
    push cx
    rep movsb
    pop cx
;    
    call InsertLonMsg
    jmp mrDone

mrSerialData:
    shr ebx,20
    and bx,7
    cmp bl,ds:cms_port_count
    jae mrDone
;    
    shl bx,1
    mov bx,ds:[bx].cms_port_arr
    or bx,bx
    jz mrDone
;
    mov ds,bx
    test ds:cp_flags,PORT_FLAG_OPEN
    jz mrDone
;
    movzx cx,cl
    or cx,cx
    jz mrDone    
;
    mov ds:cp_rd_buf,eax
    mov ds:cp_rd_buf+4,edx
    mov si,OFFSET cp_rd_buf
    mov es,ds:rec_buf
    
mrGetLoop:
    lods byte ptr ds:[si]
    RequestSpinlock ds:com_spinlock
    mov dx,ds:rec_count
    cmp dx,ds:rec_size
    je mrSignal
;       
    inc dx
    mov ds:rec_count,dx
    mov bx,ds:rec_tail
    mov es:[bx],al
    inc bx
    cmp bx,ds:rec_size
    jnz mrWrapOk
;
    xor bx,bx
    
mrWrapOk:
    mov ds:rec_tail,bx
    ReleaseSpinlock ds:com_spinlock
    loop mrGetLoop
;
    jmp mrSigRel

mrSignal:
    ReleaseSpinlock ds:com_spinlock

mrSigRel:
    mov bx,ds:avail_obj
    or bx,bx
    jz mrDone
;
    mov ds:avail_obj,0
    mov es,bx
    SignalWait
    
mrDone:
    pop ebp
    pop bx
    pop ds
    retf32
ModuleReceive   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           SetupModule
;
;   DESCRIPTION:    Setup module session
;
;   PARAMETERS:     DS      Module
;                   EDX:EAX Data
;                   CL      Size
;
;   RETURNS:        EDX:EAX Module data
;                   CL      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupModule    Proc near
    EnterSection ds:cms_section
    push ax
    GetThread
    mov ds:cms_session_thread,ax
    mov ds:cms_has_data,0
    mov ds:cms_server_thread,0
    pop ax
    ClearSignal
;
    push ebx
    mov ebx,ds:cms_id
    or ebx,41Eh SHL 18
    SendCanBusMsg
    pop ebx    
;    
    GetSystemTime
    add eax,1193 * 100
    adc edx,0
    WaitForSignalWithTimeout    
;    
    mov cl,ds:cms_has_data
    or cl,cl
    stc
    jz smLeave
;
    mov eax,ds:cms_data_buf
    mov edx,ds:cms_data_buf+4
    mov cl,ds:cms_data_size
    clc

smLeave:    
    mov ds:cms_session_thread,0
    LeaveSection ds:cms_section
    ret
SetupModule    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           SetupPrograming
;
;   DESCRIPTION:    Setup module programming
;
;   PARAMETERS:     DS      Module
;                   EDX:EAX Data
;                   CL      Size
;
;   RETURNS:        EDX:EAX Module data
;                   CL      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupProgramming    Proc near
    push ax
    GetThread
    mov ds:cms_session_thread,ax
    mov ds:cms_has_data,0
    pop ax
    ClearSignal
;
    push ebx
    mov ebx,ds:cms_id
    or ebx,41Eh SHL 18
    SendCanBusMsg
    pop ebx    
;    
    GetSystemTime
    add eax,1193 * 100
    adc edx,0
    WaitForSignalWithTimeout    
;    
    mov cl,ds:cms_has_data
    or cl,cl
    stc
    jz spDone
;
    mov eax,ds:cms_data_buf
    mov edx,ds:cms_data_buf+4
    mov cl,ds:cms_data_size
    clc

spDone:    
    ret
SetupProgramming    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           SendProgData
;
;   DESCRIPTION:    Send program data
;
;   PARAMETERS:     DS      Module
;                   EDX:EAX Data
;                   CL      Size
;
;   RETURNS:        AL      Programming result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendProgData    Proc near
    push bx
    push si
;
    mov si,10

spdLoop:
    push eax
    push ecx
    push edx
;
    push ax
    GetThread
    mov ds:cms_prog_thread,ax
    mov ds:cms_prog_res,-1
    pop ax
    ClearSignal
;
    mov ebx,ds:cms_id
    or ebx,41Fh SHL 18
    SendCanBusMsg
;    
    push esi
    push edi
;
    GetSystemTime
    add eax,1193 * 500
    adc edx,0
    mov esi,eax
    mov edi,edx

spdWait:
    WaitForSignalWithTimeout    
;
    mov bl,ds:cms_prog_res
    cmp bl,-1
    jne spdHasAnswer
;
    GetSystemTime
    sub eax,esi
    sbb edx,edi
    jnc spdHasAnswer
;
    mov eax,esi
    mov edx,edi
    jmp spdWait

spdHasAnswer:
    pop edi
    pop esi
;
    cmp bl,-1
;
    pop edx
    pop ecx
    pop eax
    jne spdDone
;
    sub si,1
    jnz spdLoop

spdDone:
    mov al,bl
    pop si
    pop bx
    ret
SendProgData    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           SetupPort
;
;   DESCRIPTION:    Setup port session
;
;   PARAMETERS:     DS      Module
;                   BL      Port
;                   EDX:EAX Setup data
;                   CL      Size
;
;   RETURNS:        EDX:EAX Module data
;                   CL      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupPort    Proc near
    EnterSection ds:cms_section
    push ax
    GetThread
    mov ds:cms_session_thread,ax
    mov ds:cms_has_data,0
    pop ax
    ClearSignal
;
    push ebx
    movzx ebx,bl
    shl ebx,20
    or ebx,ds:cms_id
    or ebx,401h SHL 18
    SendCanBusMsg
    pop ebx
;    
    GetSystemTime
    add eax,1193 * 100
    adc edx,0
    WaitForSignalWithTimeout    
;    
    mov cl,ds:cms_has_data
    or cl,cl
    stc
    jz spLeave
;
    mov eax,ds:cms_data_buf
    mov edx,ds:cms_data_buf+4
    mov cl,ds:cms_data_size
    clc

spLeave:    
    mov ds:cms_session_thread,0
    LeaveSection ds:cms_section
    ret
SetupPort    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           RestartModule
;
;   DESCRIPTION:    Restart module
;
;   PARAMETERS:     DS      Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RestartModule  Proc near
    pushad
;    
    mov bx,OFFSET cms_port_arr
    movzx cx,ds:cms_port_count

rmLoop:
    push ds
    push bx
    push cx
;
    mov ax,ds:[bx]
    or ax,ax
    jz rmNext
;    
    mov ds,ax
    test ds:cp_flags,PORT_FLAG_OPEN
    jz rmNext
;    
    mov eax,ds:cp_setup1
    mov edx,ds:cp_setup2
    movzx bx,ds:cp_port
    mov ds,ds:cp_module
    mov cl,6
    call SetupPort

rmNext:    
    pop cx
    pop bx
    pop ds    
    add bx,2
    loop rmLoop    
;
    popad
    ret
RestartModule  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           RestartIo
;
;   DESCRIPTION:    Restart IO
;
;   PARAMETERS:     DS      Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RestartIo  Proc near
    pushad
;    
    mov ds:cms_io_out,0
    mov ds:cms_io_in,0
;    
    mov ax,50
    shl eax,24
    or eax,0FFFFA4h
    mov cl,4
    xor bl,bl
    call SetupPort
;
    popad
    ret
RestartIo  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateCanModule
;
;   DESCRIPTION:    Create new CAN module
;
;   PARAMETERS:     EAX     ID
;                   EDX     Mask
;
;   RETURNS:        BX      Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateCanModule    Proc near
    push ds
    push es
    push cx
    push esi
    push edi
;    
    push eax
    mov eax,SIZE can_module_struc
    AllocateSmallGlobalMem
    xor di,di
    xor al,al
    mov cx,SIZE can_module_struc
    rep stosb
    pop eax
;
    mov di,es
    mov ds,di
    mov ds:cms_id,eax
    mov di,cs
    mov es,di
    mov edi,OFFSET ModuleReceive
    CreateCanIdHook
    mov ds:cms_buffer,bx
    InitSection ds:cms_section
    mov ds:cms_active_ports,0
    mov ds:cms_online,0
    mov ds:cms_server_thread,0
    mov ds:cms_prog_sel,0
    mov ds:cms_prog_size,0
    mov ds:cms_prog_wait_thread,0
    mov bx,ds
;
    pop edi
    pop esi
    pop cx
    pop es
    pop ds            
    ret
CreateCanModule    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SendSignal
;
;   description:    Sends signal to CAN module thread
;
;   Parameters:     CX      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendSignal  Proc far
    push ds
    push ax
    push bx
;    
    verw cx
    jnz ssiDone
;    
    mov ds,cx
    mov ds:cp_timer_active,0
;    
    mov ds,ds:cp_module
    mov bx,ds:cms_server_thread
    Signal    

ssiDone:
    pop bx
    pop ax
    pop ds
    retf32
SendSignal  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           StartSendTimer
;
;   description:    Starts send timeout
;
;   Parameters:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartSendTimer Proc near
    push es
    pushad
;   
    mov al,1    
    xchg al,ds:cp_timer_active
    or al,al
    jnz sstDone
;
    GetSystemTime
;    add eax,11930
    add eax,1193
    adc edx,0
;       
    mov bx,cs
    mov es,bx
    mov edi,OFFSET SendSignal
    mov bx,ds
    mov cx,bx
    StartTimer

sstDone:
    popad
    pop es
    ret
StartSendTimer Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           open_com
;
;   description:    Open a serial port
;
;   PARAMETERS:     DS      Port selector
;                   ES          Device selector
;                   AH          # of data bits
;                   BL          # of stop bits
;                   BH          parity
;                   ECX         baudrate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com    Proc far
    pushad
    push ds
;    
    test ds:cp_flags,PORT_FLAG_OPEN
    jnz ocDone
;    
    movzx di,ds:cp_port
    mov ds,ds:cp_module
;
;    pushad
;    mov cx,di
;    mov al,1
;    shl al,cl
;    or ds:cms_active_ports,al
;    mov ah,ds:cms_active_ports
;    mov al,10h
;    mov cl,2
;    call SetupModule
;    popad        
;    
    cmp ah,7
    jne ocBit8

ocBit7:
    mov eax,00280h
    xor edx,edx
    jmp ocBaud

ocBit8:
    mov eax,10280h
    xor edx,edx

ocBaud:
    cmp ecx,2400
    je oc2400
;
    cmp ecx,4800
    je oc4800
;
    cmp ecx,5787
    je oc5787
;
    cmp ecx,1200
    je oc1200
;
    cmp ecx,38400
    je oc38400
;    
    cmp ecx,19200
    jne ocBaudOk

oc19200:
    mov ah,3
    jmp ocBaudOk

oc5787:
    mov ah,4
    jmp ocBaudOk

oc4800:
    mov ah,1
    jmp ocBaudOk

oc1200:
    mov ah,5
    jmp ocBaudOk

oc38400:
    mov ah,6
    jmp ocBaudOk

oc2400:
    mov ah,0

ocBaudOk:        
    cmp bh,'E'
    je ocEven
;
    cmp bh,'O'
    je ocOdd
    jmp ocParOk

ocEven:
    or eax,2000000h
    jmp ocParOk

ocOdd:    
    or eax,1000000h

ocParOk:
    cmp bl,2
    jne ocStopOk
;
    mov dl,1

ocStopOk:
    mov dh,1
;
    IsCanOnline
    jc upSetupDone
;
    int 3
    push eax
    push edx
    mov bx,di 
    mov cl,6
    call SetupPort
;
    pop edx
    pop eax

upSetupDone:
    pop ds    
    mov ds:cp_setup1,eax
    mov ds:cp_setup2,edx
;    
    popad
;    
    lock or ds:cp_flags,PORT_FLAG_OPEN

ocDone:    
    retf32
open_com Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           close_com
;
;   description:    Close serial port
;
;   PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_com   Proc far
    push ds
    push ax
    push bx
;    
    lock and ds:cp_flags,NOT PORT_FLAG_OPEN
    mov ax,5
    WaitMilliSec
;
    movzx bx,ds:cp_port
    mov ds,ds:cp_module
    shl bx,1
    mov ds:[bx].cms_port_arr,0
;
    pop bx
    pop ax
    pop ds    
    retf32
close_com   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           enable_cts
;
;   DESCRIPTION:    Enable CTS signal
;
;   PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_cts  PROC far
    retf32
enable_cts Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           disable_cts
;
;   DESCRIPTION:    Disable CTS signal
;
;   PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_cts PROC far
    retf32
disable_cts Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           set_dtr
;
;   description:    Set DTR signal
;
;   PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dtr     Proc far
    retf32
set_dtr     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           reset_dtr
;
;   description:    Reset DTR signal
;
;   PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_dtr   Proc far
    retf32
reset_dtr   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           set_rts
;
;   description:    Set RTS signal
;
;   PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_rts     Proc far
    retf32
set_rts     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           reset_rts
;
;   description:    Reset RTS signal
;
;   PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_rts   Proc far
    retf32
reset_rts   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           EnableAutoRts
;
;   DESCRIPTION:    Enable automatic RTS on send
;
;   PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_auto_rts PROC far
    retf32
enable_auto_rts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           DisableAutoRts
;
;   DESCRIPTION:    Disable automatic RTS on send
;
;   PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_auto_rts    PROC far
    retf32
disable_auto_rts Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FullDuplex
;
;   DESCRIPTION:    Check for full duplex 
;
;   PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

full_duplex       PROC far
    stc
    retf32
full_duplex Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FlushCom
;
;   DESCRIPTION:    Flush com
;
;   PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_com       PROC far
    retf32
flush_com Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           ResetPort
;
;   DESCRIPTION:    Reset com
;
;   PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_port       PROC far
    push ds
    push bx
;    
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:com_thread
;    Signal
;
    pop bx
    pop ds    
    retf32
reset_port Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           start_send
;
;   description:    Start send
;
;   PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_send      PROC far
    test ds:cp_flags,PORT_FLAG_OPEN
    jz ssDone
;    
    call StartSendTimer

ssDone:
    retf32
start_send      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetComLineState
;
;       description:    Get current line-state change
;
;       PARAMETERS:     DS      Com device selector
;
;       RETURNS:        AL      Line-state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetComLineState  Proc far
    push ds
    push bx
    push cx
    push edx
    push si
;    
    mov bx,ds:cd_device
    mov si,ds:cd_module
    mov ax,SEG data
    mov ds,ax
    shl si,1
    add si,OFFSET module_arr
    mov ds,ds:[si]
;
    mov al,0A0h
    mov cl,1
    call SetupPort
    jc glsFail
;
    cmp cl,2
    jne glsFail
;
    cmp al,0A0h
    jne glsFail
;
    mov al,ah
    and al,0Fh
    jmp glsDone

glsFail:
    xor al,al

glsDone:
    pop si
    pop edx
    pop cx
    pop bx
    pop ds
    retf32
GetComLineState  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateComPort
;
;   DESCRIPTION:    Create com port
;
;   PARAMETERS:     DS      Selector
;                   DL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

com_port_tab:
cct00 DD OFFSET open_com,           SEG code
cct01 DD OFFSET close_com,          SEG code
cct02 DD OFFSET enable_cts,         SEG code
cct03 DD OFFSET disable_cts,        SEG code
cct04 DD OFFSET set_dtr,            SEG code
cct05 DD OFFSET reset_dtr,          SEG code
cct06 DD OFFSET set_rts,            SEG code
cct07 DD OFFSET reset_rts,          SEG code
cct08 DD OFFSET enable_auto_rts,    SEG code
cct09 DD OFFSET disable_auto_rts,   SEG code
cct10 DD OFFSET flush_com,          SEG code
cct11 DD OFFSET start_send,         SEG code
cct12 DD OFFSET reset_port,         SEG code
cct13 DD OFFSET full_duplex,        SEG code

CreateComPort   Proc far
    push ds
    pushad
;    
    mov eax,SIZE can_port_struc
    AllocateSmallGlobalMem
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
;
    mov si,OFFSET com_port_tab
    xor di,di
    mov cx,2 * 14
    rep movs dword ptr es:[di],cs:[si]
;
    mov es:cp_dev,ds
    mov dx,ds:cd_device
    mov es:cp_port,dl
    mov bx,ds:cd_module
    mov es:cp_timer_active,0
;
    mov ax,SEG data
    mov ds,ax
    shl bx,1
    add bx,OFFSET module_arr
    mov ax,ds:[bx]
    mov es:cp_module,ax
;    
    mov ds,ax
    movzx bx,dl
    shl bx,1
    mov ds:[bx].cms_port_arr,es    
;    
    popad
    pop ds
    retf32
CreateComPort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AddPort
;
;   DESCRIPTION:    Add com port
;
;   PARAMETERS:     AX      Module #
;                   DX      Device #
;                   DS:BX   Device entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPort Proc near
    push ds
    push es
;    
    push eax
    mov eax,SIZE can_device_struc
    AllocateSmallGlobalMem
    mov ds:[bx],es
    mov ax,es
    mov ds,ax
    pop eax
    mov ds:cd_module,ax
    mov ds:cd_mod_port,dx
    push ax
    AddComPort
    pop ax
;    
    mov dword ptr ds:cd_create_proc,OFFSET CreateComPort
    mov dword ptr ds:cd_create_proc+4,cs
    mov dword ptr ds:cd_get_line_state_proc,OFFSET GetComLineState
    mov dword ptr ds:cd_get_line_state_proc+4,cs
;
    pop es
    pop ds
    ret
AddPort Endp 
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           UpdatePort
;
;   DESCRIPTION:    Update port (send buffer)
;   
;   PARAMETERS:     DS      Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePort  Proc near
    HasCanSendBuf
    jc upDone
;    
    mov al,ds:cp_timer_active
    or al,al
    jnz upDone
;
    xor cx,cx    
    mov di,OFFSET cp_wr_buf
    mov es,ds:send_buf
    mov dx,ds:send_count
    or dx,dx
    jz upDone
;
    IsCanOnline
    jnc upLoop
;
    RequestSpinlock ds:com_spinlock
    mov ds:send_count,0
    mov ds:send_head,0
    mov ds:send_tail,0
    ReleaseSpinlock ds:com_spinlock
    jmp upDone

upLoop:
    RequestSpinlock ds:com_spinlock
    test ds:cp_flags,PORT_FLAG_OPEN
    jz upSend
;
    mov dx,ds:send_count
    or dx,dx
    jz upSend
;       
    dec dx

    mov ds:send_count,dx
    mov bx,ds:send_head
    mov al,es:[bx]
    mov ds:[di],al
    inc bx
    cmp bx,ds:send_size
    jnz upWrapOk
;       
    xor bx,bx

upWrapOk:
    mov ds:send_head,bx
    ReleaseSpinlock ds:com_spinlock
;
    inc di
    inc cx
    cmp cx,8
    jb upLoop
    jmp upSendRel

upSend:
    ReleaseSpinlock ds:com_spinlock

upSendRel:
    mov bx,ds:send_wait
    or bx,bx
    jz upSendSignalled
;
    Signal

upSendSignalled:
    test ds:cp_flags,PORT_FLAG_OPEN
    jz upDone
;
    or cx,cx
    jz upDone
;    
    mov eax,ds:cp_wr_buf
    mov edx,ds:cp_wr_buf+4
;
    movzx ebx,ds:cp_port
    push ds
    push ebx
    push ecx
    shl ebx,20
    mov ds,ds:cp_module
    or ebx,ds:cms_id
    or ebx,400h SHL 18
    SendCanBusBlock
    pop ecx
    pop ebx
    pop ds
    jc upReset
;    
    mov ax,ds:send_count
    or ax,ax
    jz upDone
;
    call StartSendTimer    
    jmp upDone

upReset:
    mov ds:send_count,0

upDone:    
    xor ax,ax
    mov es,ax
    ret
UpdatePort  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           can_module_thread
;
;   DESCRIPTION:    CAN module thread
;   
;   PARAMETERS:     BX      Module entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


can_module_thread:
    AddThreadInt
    mov ax,SEG data
    mov ds,ax
    mov ds,ds:[bx]
    GetThread
    mov ds:cms_server_thread,ax
;
    mov ax,bx
    sub ax,OFFSET module_arr
    shr ax,1
    movzx cx,ds:cms_port_count
    or cx,cx
    jz cmtTerm
;
    xor dx,dx
    mov bx,OFFSET cms_dev_arr
    or cx,cx
    jz cmtWait

cmtpLoop:
    call AddPort
    add bx,2
    inc dx
    loop cmtpLoop    

cmtWait:    
    GetSystemTime
    add eax,1193000
    adc edx,0
    WaitForSignalWithTimeout
;
    push ds
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:restart_section
    xor al,al
    pop ds    
;
    xor al,al
    xchg al,ds:cms_restarted
    or al,al
    jz cmtRestartedOk
;
    GetThread
    mov ds:cms_server_thread,ax
    call RestartModule

cmtRestartedOk:    
    mov bx,OFFSET cms_port_arr    
    movzx cx,ds:cms_port_count

cmtHandlePortLoop:
    push ds
    push bx
    push cx
;    
    mov ax,ds:[bx]
    or ax,ax
    jz cmtHandleNext
;    
    mov ds,ax
    test ds:cp_flags,PORT_FLAG_OPEN
    jz cmtHandleNext
;    
    call UpdatePort

cmtHandleNext:
    pop cx
    pop bx
    pop ds
;
    add bx,2
    loop cmtHandlePortLoop 
;
    push ds
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:restart_section
    pop ds    
    jmp  cmtWait

cmtTerm:
    TerminateThread       

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetInSerIo
;
;       DESCRIPTION:    Read serial lines for input
;
;       PARAMETERS:     DS  Ser IO sel
;                       DH  Device
;
;       RETURNS:        AL  Lines   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetInSerIo       Proc far
    mov ds,ds:csio_module
    mov al,ds:cms_io_in
    clc
    retf32
GetInSerIo Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetOutSerIo
;
;       DESCRIPTION:    Read serial lines for output
;
;       PARAMETERS:     DS  Ser IO sel
;                       DH  Device
;
;       RETURNS:        AL  Lines   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetOutSerIo       Proc far
    mov ds,ds:csio_module
    mov al,ds:cms_io_out
    clc
    retf32
GetOutSerIo Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ToggleSerIo
;
;       DESCRIPTION:    Toggle serial line for output
;
;       PARAMETERS:     DS  Ser IO sel
;                       DH  Device
;                       DL Line #    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ToggleSerIo      Proc far
    push ax
    push bx
    push cx
;    
    mov ds,ds:csio_module
    mov cl,dl
    mov al,1
    shl al,cl
    xor ds:cms_io_out,al
;    
    mov bx,ds:cms_server_thread
    Signal    
    clc
;    
    pop cx
    pop bx
    pop ax
    retf32
ToggleSerIo Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DummyToggleSerIo
;
;       DESCRIPTION:    Toggle serial line for input
;
;       PARAMETERS:     DS  Ser IO sel
;                       DH  Device
;                       DL Line #    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DummyToggleSerIo      Proc far
    stc
    retf32
DummyToggleSerIo Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetSerIo
;
;       DESCRIPTION:    Set serial line for output
;
;       PARAMETERS:     DS  Ser IO sel
;                       DH  Device
;                       DL Line #    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSerIo      Proc far
    push ax
    push bx
    push cx
;    
    mov ds,ds:csio_module
    mov cl,dl
    mov al,1
    shl al,cl
    or ds:cms_io_out,al
;    
    mov bx,ds:cms_server_thread
    Signal    
    clc
;    
    pop cx
    pop bx
    pop ax
    retf32
SetSerIo Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DummySetSerIo
;
;       DESCRIPTION:    Set serial line for input
;
;       PARAMETERS:     DS  Ser IO sel
;                       DH  Device
;                       DL Line #    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DummySetSerIo      Proc far
    stc
    retf32
DummySetSerIo Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ResetSerIo
;
;       DESCRIPTION:    Set serial line for output
;
;       PARAMETERS:     DS  Ser IO sel
;                       DH  Device
;                       DL Line #    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetSerIo      Proc far
    push ax
    push bx
    push cx
;    
    mov ds,ds:csio_module
    mov cl,dl
    mov al,1
    shl al,cl
    not al
    and ds:cms_io_out,al
;    
    mov bx,ds:cms_server_thread
    Signal    
    clc
;    
    pop cx
    pop bx
    pop ax
    retf32
ResetSerIo Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DummyResetSerIo
;
;       DESCRIPTION:    Reset serial line for input
;
;       PARAMETERS:     DS  Ser IO sel
;                       DH  Device
;                       DL Line #    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DummyResetSerIo      Proc far
    stc
    retf32
DummyResetSerIo Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DummyReadSerIo
;
;       DESCRIPTION:    Read serial ADC value
;
;       PARAMETERS:     DS  Ser IO sel
;                       DH  Device
;                       DL Line #    
;
;       RETURNS:        EAX Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DummyReadSerIo Proc far
    stc
    retf32
DummyReadSerIo Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DummyWriteSerIo
;
;       DESCRIPTION:    Read serial ADC value
;
;       PARAMETERS:     DS  Ser IO sel
;                       DH  Device
;                       DL Line #    
;                       EAX Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DummyWriteSerIo Proc far
    stc
    retf32
DummyWriteSerIo Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AddSerIo
;
;   DESCRIPTION:    Add serial IO
;
;   PARAMETERS:     BX      Module #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddSerIo Proc near
    push ds
    push es
;    
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:[bx]
;
    mov eax,SIZE can_serio_device_struc
    AllocateSmallGlobalMem
    mov es:csio_module,bx
;    
    mov dword ptr es:siot_get_proc,OFFSET GetInSerIo
    mov dword ptr es:siot_get_proc+4,cs
    mov dword ptr es:siot_toggle_proc,OFFSET DummyToggleSerIo
    mov dword ptr es:siot_toggle_proc+4,cs
    mov dword ptr es:siot_reset_proc,OFFSET DummyResetSerIo
    mov dword ptr es:siot_reset_proc+4,cs
    mov dword ptr es:siot_set_proc,OFFSET DummySetSerIo
    mov dword ptr es:siot_set_proc+4,cs
    mov dword ptr es:siot_read_proc,OFFSET DummyReadSerIo
    mov dword ptr es:siot_read_proc+4,cs
    mov dword ptr es:siot_write_proc,OFFSET DummyWriteSerIo
    mov dword ptr es:siot_write_proc+4,cs
    mov dh,ds:io_dev_count
    add dh,40h
    AddSerIoDevice
;
    mov eax,SIZE can_serio_device_struc
    AllocateSmallGlobalMem
    mov es:csio_module,bx
;    
    mov dword ptr es:siot_get_proc,OFFSET GetOutSerIo
    mov dword ptr es:siot_get_proc+4,cs
    mov dword ptr es:siot_toggle_proc,OFFSET ToggleSerIo
    mov dword ptr es:siot_toggle_proc+4,cs
    mov dword ptr es:siot_reset_proc,OFFSET ResetSerIo
    mov dword ptr es:siot_reset_proc+4,cs
    mov dword ptr es:siot_set_proc,OFFSET SetSerIo
    mov dword ptr es:siot_set_proc+4,cs
    mov dword ptr es:siot_read_proc,OFFSET DummyReadSerIo
    mov dword ptr es:siot_read_proc+4,cs
    mov dword ptr es:siot_write_proc,OFFSET DummyWriteSerIo
    mov dword ptr es:siot_write_proc+4,cs
    mov dh,ds:io_dev_count
    add dh,80h
    AddSerIoDevice
;    
    inc ds:io_dev_count
;
    pop es
    pop ds
    ret
AddSerIo Endp 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           UpdateIo
;
;   DESCRIPTION:    Update IO
;
;   PARAMETERS:     DS          Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateIo Proc near
    mov al,ds:cms_io_out
    mov ecx,1
    mov ebx,ds:cms_id
    or ebx,400h SHL 18
    SendCanBusBlock
    ret
UpdateIo Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           can_io_thread
;
;   DESCRIPTION:    CAN IO thread
;   
;   PARAMETERS:     BX      Module entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


can_io_thread:
    AddThreadInt
    mov ax,SEG data
    mov ds,ax
    mov ds,ds:[bx]
    GetThread
    mov ds:cms_server_thread,ax
;
    call AddSerIo

citWait:    
    GetSystemTime
    add eax,1193000
    adc edx,0
    WaitForSignalWithTimeout
;
    push ds
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:restart_section
    xor al,al
    pop ds    
;
    xor al,al
    xchg al,ds:cms_restarted
    or al,al
    jz citRestartedOk
;
    GetThread
    mov ds:cms_server_thread,ax
    call RestartIo

citRestartedOk:    
    call UpdateIo
;
    push ds
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:restart_section
    pop ds    
    jmp  citWait

citTerm:
    TerminateThread       
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CheckSendBuf
;
;   DESCRIPTION:    Check send buffer for new messages
;   
;   PARAMETERS:     DS      lon port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckSendBuf   Proc near
    push es
    push fs
    push bx
    push cx
    push dx
;    
    EnterSection ds:lon_section
    mov cx,ds:lon_send_count
    or cx,cx
    jnz csbHasData
;
    LeaveSection ds:lon_section
    mov ds:cl_send_pend,0
    jmp csbEnd

csbHasData:
    HasCanSendBuf
    jc csbLeave
;    
    mov fs,ds:lon_send_buf
    mov bx,ds:lon_send_head
    xor ax,ax
    xchg ax,fs:[bx]
    dec cx
    mov ds:lon_send_count,cx
;
    add bx,2
    mov cx,ds:lon_send_size
    shl cx,1
    cmp bx,cx
    jnz csbNoWrap
    xor bx,bx
    
csbNoWrap:
    mov ds:lon_send_head,bx
    clc
    LeaveSection ds:lon_section
;
    mov bx,ax
    GetSelectorBaseSize
    jc csbEnd
;
    dec cx
    mov ds:cl_send_size,cl
    mov ds:cl_send_len,0
;    
    xor eax,eax
    mov es,bx
    mov ah,es:[0]
    mov al,cl
    shl eax,8
    mov al,92h
    xor edx,edx
    mov cl,3
    mov ebx,ds:cl_id
    or ebx,401h SHL 18
    SendCanBusBlock
    jc csbFree
;    
    movzx cx,ds:cl_send_size
    or cx,cx
    jz csbFree
;
    push ds
    push es
    push ecx
    push esi
    push edi
;    
    mov bx,es
    mov ax,ds
    mov es,ax
    mov ds,bx
    mov si,1
    mov di,OFFSET cl_send_buf
    rep movsb
;
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds    

csbFree:
    FreeMem
    jmp csbEnd
        
csbLeave:
    LeaveSection ds:lon_section

csbEnd:
    pop dx
    pop cx
    pop bx
    pop fs
    pop es
    ret
CheckSendBuf   Endp        
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           DoLonReset
;
;   DESCRIPTION:    Reset EE in LON processor
;   
;   PARAMETERS:     DS      Lon selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoLonReset   Proc near
    push ds
    mov bl,ds:cl_port
    mov cl,1
    mov eax,93h
    xor edx,edx
    mov ds,ds:cl_module
    call SetupPort
    pop ds
;
    mov ds:cl_reset,0
;    
    mov ax,5000
    WaitMilliSec
;
    ResetCanBuffers
    RestartCanModules
    ret
DoLonReset  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           lon_module_thread
;
;   DESCRIPTION:    Lon module thread
;   
;   PARAMETERS:     BX      Lon port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lon_module_thread:
    AddThreadInt
    mov ds,bx
    GetThread
    mov ds:cl_thread,ax

lmtWait:
    WaitForSignal
    mov al,ds:cl_reset
    or al,al
    jz lmtNotReset
;
    call DoLonReset    
    jmp lmtWait

lmtNotReset:    
    mov al,ds:cl_open
    or al,al
    jz lmtWait
;
    mov ds:cl_rec_size,0
    mov ds:cl_send_len,0
    mov ds:cl_send_size,0
    mov ds:cl_send_pend,0

lmtRetry:
    mov ds:cl_restart,0
    mov al,ds:cl_open
    or al,al
    jz lmtWait
;    
    push ds
    mov bl,ds:cl_port
    mov cl,1
    mov eax,90h
    xor edx,edx
    mov ds,ds:cl_module
    call SetupPort
    pop ds
    jc lmtRetry
;
    cmp cl,2
    jne lmtRetry
;
    cmp ax,0190h
    je lmtMsgLoop
;
    mov eax,91h
    xor edx,edx
    mov cl,1
    mov ebx,ds:cl_id
    or ebx,401h SHL 18
    SendCanBusMsg

lmtWaitInit: 
    mov ax,250
    WaitMilliSec
;    
    mov bp,4 * 30
;    mov bp,4 * 3600

lmtWaitInitLoop:
    push ds
    mov bl,ds:cl_port
    mov cl,1
    mov eax,90h
    xor edx,edx
    mov ds,ds:cl_module
    call SetupPort
    pop ds
;
    cmp ax,0190h
    je lmtMsgLoop
;
    mov ax,250
    WaitMilliSec
    sub bp,1
    jne lmtWaitInitLoop
;    
    call DoLonReset    
    jmp lmtWait
            
lmtMsgLoop:
    mov al,ds:cl_open
    or al,al
    jz lmtWait
;
    mov al,ds:cl_send_pend
    or al,al
    jz lmtMsgSignal
;
    HasCanSendBuf
    jnc lmtCheckSend
;
    mov ax,1
    WaitMilliSec
    jmp lmtCheckSend

lmtMsgSignal:    
    WaitForSignal
    mov al,ds:cl_reset
    or al,al
    jz lmtNoActiveReset
;
    call DoLonReset
    
lmtNoActiveReset:     
    mov al,ds:cl_restart
    or al,al
    jnz lmtRetry

lmtCheckSend:
    mov al,ds:cl_send_size
    or al,al
    jnz lmtContSend
;    
    call CheckSendBuf
    jmp lmtMsgLoop

lmtContSend:  
    mov cl,ds:cl_send_size
    sub cl,ds:cl_send_len
    cmp cl,8
    jbe lmtSendSizeOk
;
    mov cl,8

lmtSendSizeOk:
    movzx bx,ds:cl_send_len
    mov eax,dword ptr ds:[bx].cl_send_buf
    mov edx,dword ptr ds:[bx].cl_send_buf+4
    add ds:cl_send_len,cl    
;    
    mov ebx,ds:cl_id
    or ebx,400h SHL 18
    SendCanBusMsg
;
    mov al,ds:cl_send_len
    cmp al,ds:cl_send_size
    jne lmtMsgLoop
;
    mov ds:cl_send_len,0
    mov ds:cl_send_size,0    
    jmp lmtMsgLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           OpenLon
;
;   DESCRIPTION:    Open Lon interface
;
;   PARAMETERS:     DS      Lon selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_lon Proc far
    push bx
;
    mov ds:cl_open,1
    mov bx,ds:cl_thread
    Signal    
;
    pop bx
    retf32
open_lon Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CloseLon
;
;   DESCRIPTION:    Close Lon interface
;
;   PARAMETERS:     DS      Lon selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_lon Proc far
    push bx
;
    mov ds:cl_open,0
;    
    mov bx,ds:cl_thread
    Signal    
;
    pop bx
    retf32
close_lon Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           ResetLon
;
;   DESCRIPTION:    Reset Lon interface
;
;   PARAMETERS:     DS      Lon selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_lon Proc far
    push bx
;
    mov ds:cl_reset,1
;    
    mov bx,ds:cl_thread
    Signal    
;
    pop bx
    retf32
reset_lon Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           StartSendLon
;
;   DESCRIPTION:    Notify new msg
;
;   PARAMETERS:     DS      Lon selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_send_lon Proc far
    push bx
;
    mov ds:cl_send_pend,1
    mov bx,ds:cl_thread
    Signal    
;
    pop bx
    retf32
start_send_lon Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AddLonPort
;
;   DESCRIPTION:    Add Lon interface port
;
;   PARAMETERS:     DS      Module selector
;                   BX      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lon_module_name   DB 'Lon Module', 0

AddLonPort Proc near
    push ds
    push es
    pushad
;
    mov eax,SIZE can_lon_struc
    AllocateSmallGlobalMem
;
    mov ds:[2*ebx].cms_dev_arr,es
    mov es:cl_module,ds
;
    movzx edx,bl
    shl edx,20
    or edx,ds:cms_id
;
    mov ax,es
    mov ds,ax
    mov ds:cl_id,edx
    mov ds:cl_port,bl
    mov ds:cl_open,0
    mov ds:cl_reset,0
    mov ds:cl_restart,0
;    
    mov dword ptr ds:lon_open_proc,OFFSET open_lon
    mov dword ptr ds:lon_open_proc+4,cs
    mov dword ptr ds:lon_close_proc,OFFSET close_lon
    mov dword ptr ds:lon_close_proc+4,cs
    mov dword ptr ds:lon_reset_proc,OFFSET reset_lon
    mov dword ptr ds:lon_reset_proc+4,cs
    mov dword ptr ds:lon_start_send_proc,OFFSET start_send_lon
    mov dword ptr ds:lon_start_send_proc+4,cs
    AddLonModule
;    
    mov ds:cl_rec_size,0
    mov ds:cl_send_len,0
    mov ds:cl_send_size,0
    mov ds:cl_send_pend,0
;    
    mov bx,ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET lon_module_thread
    mov edi,OFFSET lon_module_name
    mov ecx,1000h
    mov ax,4
    CreateThread
;
    popad
    pop es
    pop ds
    ret
AddLonPort Endp 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AddLonPorts
;
;   DESCRIPTION:    Add Lon interface ports
;
;   PARAMETERS:     DS      Module selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddLonPorts Proc near
    push cx
    push ebx
;    
    mov cx,1
    xor ebx,ebx

alpLoop:
    call AddLonPort
    inc bx
    loop alpLoop
;
    pop ebx
    pop cx    
    ret
AddLonPorts Endp 
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InitCanModules
;
;           DESCRIPTION:    Init all CAN modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitCanModules  Proc near
    mov ax,SEG data
    mov ds,ax
    mov es,ax
;
    call CreateIntHook    
;
    mov cx,MAX_CAN_MODULES
    mov si,OFFSET module_arr
    mov eax,1 SHL 23
    mov edx,3Fh SHL 23
    
icmHookLoop:
    call CreateCanModule
    mov ds:[si],bx
    add si,2
    add eax,1 SHL 23
    loop icmHookLoop
;
    ret
InitCanModules  Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetupCanModules
;
;           DESCRIPTION:    Setup all CAN modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupCanModules  Proc near
    push ds
;
    mov ax,SEG data
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET module_arr
    mov eax,1 SHL 23
    mov edx,3Fh SHL 23
;
    mov ebx,7FEh SHL 18
    mov eax,2
    mov cl,1
    SendCanBusMsg
;
    xor bp,bp
    mov bx,OFFSET module_arr
    mov ds:module_count,0
    mov ds:io_dev_count,0
    mov cx,MAX_CAN_MODULES
    
rcmAddLoop:
    push ds
    push bx
    push cx
;    
    mov ds,ds:[bx]
    mov al,18h
    mov cl,1
    call SetupModule
    jc rcmAddNext
;
    cmp al,18h
    jne rcmAddNext
;
    shr eax,8
    mov ds:cms_major_ver,al
    shr eax,8
    mov ds:cms_minor_ver,al
    shr eax,8
    mov ds:cms_sub_ver,al
;
    shr edx,8
    mov al,ds:cms_hw_id
    or al,al
    jz rcmIdOk
;
    cmp al,dl
    je rcmIdOk
;
    int 3

rcmIdOk:        
    mov ds:cms_hw_id,dl
    shr edx,8
    mov ds:cms_port_count,dl
;    
    mov ax,bp
    inc ax
    mov es:module_count,ax
;    
    mov al,19h
    mov cl,1
    call SetupModule
    jc rcmAdd
;
    cmp al,19h
    jne rcmAdd
;
    shr eax,8
    mov ds:cms_loader_major_ver,al
    shr eax,8
    mov ds:cms_loader_minor_ver,al
    shr eax,8
    mov ds:cms_loader_sub_ver,al
;    
    mov al,40h
    mov cl,1
    call SetupModule
    jc rcmAdd
;
    cmp al,40h
    jne rcmAdd
;
    shr eax,8
    mov ds:cms_module_id,al
;    
    mov al,ah
    shr al,4
    and al,0Fh
    add al,30h
    mov ds:cms_module_id+1,al
    mov al,ah
    and al,0Fh
    add al,30h
    mov ds:cms_module_id+2,al
;
    shr eax,8
    mov al,ah
    shr al,4
    and al,0Fh
    add al,30h
    mov ds:cms_module_id+3,al
    mov al,ah
    and al,0Fh
    add al,30h
    mov ds:cms_module_id+4,al
;
    mov al,dl
    shr al,4
    and al,0Fh
    add al,30h
    mov ds:cms_module_id+5,al
    mov al,dl
    and al,0Fh
    add al,30h
    mov ds:cms_module_id+6,al
;
    mov al,dh
    shr al,4
    and al,0Fh
    add al,30h
    mov ds:cms_module_id+7,al
    mov al,dh
    and al,0Fh
    add al,30h
    mov ds:cms_module_id+8,al
;
    mov ds:cms_module_id+9,0

rcmAdd:
    mov ds:cms_restarted,1    
    mov al,ds:cms_hw_id
    cmp al,8
    je rcmIo
;    
    cmp al,5
    jne rcmNotLon
;
    mov al,ds:cms_online
    or al,al
    jz rcmAddLon
;
    push ds
    mov ds,ds:cms_dev_arr
    mov ds:cl_restart,1
    mov bx,ds:cl_thread
    Signal
    pop ds
    jmp rcmAddNext

rcmIo:
    mov al,ds:cms_online
    or al,al
    jnz rcmAddNext
;
    mov ds:cms_online,1
        
rcmAddIo:
    push ds
    push es
;
    mov ax,SEG data
    mov es,ax
    mov ax,bx
    sub ax,OFFSET module_arr
    shr al,1
    add al,'1'
    mov si,es:thread_io_name_ptr
    mov es:[si],al
;
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET can_io_thread
    mov edi,OFFSET thread_io_name_str
    mov ecx,1000h
    mov ax,4
    CreateThread
;    
    pop es
    pop ds
    jmp rcmAddNext

rcmAddLon:
    mov ds:cms_online,1
    call AddLonPorts
    jmp rcmAddNext

rcmNotLon:    
    mov al,ds:cms_online
    or al,al
    jnz rcmAddNext
;
    mov ds:cms_online,1
        
rcmAddNorm:
    push ds
    push es
;
    mov ax,SEG data
    mov es,ax
    mov ax,bx
    sub ax,OFFSET module_arr
    shr al,1
    add al,'1'
    mov si,es:thread_name_ptr
    mov es:[si],al
;
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET can_module_thread
    mov edi,OFFSET thread_name_str
    mov ecx,1000h
    mov ax,4
    CreateThread
;    
    pop es
    pop ds
    
rcmAddNext:
    pop cx
    pop bx
    pop ds
;
    inc bp
    add bx,2
    sub cx,1
    jnz rcmAddLoop
;
    pop ds
    ret
SetupCanModules   Endp    

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ProgramOneCanModule
;
;           DESCRIPTION:    Program one CAN module
;
;            PARAMETERS:     DS      Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SETUP_ERROR = 1
SETUP_ERROR_SIZE = 2
SETUP_ERROR_RESPONSE = 3
DATA_ERROR_RESPONSE = 4
PROG_ERROR = 5
PROG_ERROR_SIZE = 6
PROG_ERROR_RESPONSE = 7

ProgramOneCanModule  Proc near
    push es
;    
    mov es,ds:cms_prog_sel
    xor edi,edi
    mov ebp,ds:cms_prog_size
;    
    mov si,SETUP_ERROR
    mov al,20h
    mov cl,1
    call SetupProgramming
    jc pocFail
;
    mov si,SETUP_ERROR_SIZE
    cmp cl,1
    jne pocFail
;
    mov si,SETUP_ERROR_RESPONSE
    cmp al,20h
    jne pocFail

pocProgMore:    
    mov ecx,ebp
    sub ecx,edi
    jz pocDataOk
;    
    cmp ecx,8
    jbe pocProgOne
;
    mov ecx,8

pocProgOne:    
    mov eax,es:[edi]
    mov edx,es:[edi+4]
    add edi,ecx
;
    call SendProgData    
    or al,al
    jz pocProgMore
;
    cmp al,-1
    je pocRetryLater
;
    mov si,DATA_ERROR_RESPONSE
    cmp al,10h
    jne pocFail

pocDataOk:            
    mov si,PROG_ERROR
    mov al,21h
    mov cl,1
    call SetupProgramming
    jc pocFail
;
    mov si,PROG_ERROR_SIZE
    cmp cl,2
    jne pocFail
;
    mov si,PROG_ERROR_RESPONSE
    cmp al,21h
    jne pocFail
;
    mov al,ah
    xor si,si
    push ax
    mov ax,3000
    WaitMilliSec
    pop ax
    jmp pocDone

pocRetryLater:
    stc
    jmp pocEnd   

pocFail:
    
pocDone:
    mov ds:cms_prog_status,si
    movzx ax,al
    mov ds:cms_prog_return,ax
    mov ds:cms_prog_position,edi
;    
    FreeMem
    mov ds:cms_prog_sel,0
    mov ds:cms_prog_size,0
;
    mov bx,ds:cms_prog_wait_thread
    Signal
    clc

pocEnd:        
    pop es
    ret
ProgramOneCanModule Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ProgramAllCanModules
;
;           DESCRIPTION:    Program all CAN modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProgramAllCanModules  Proc near
    mov ax,SEG data
    mov ds,ax
    mov es,ax
;
    mov ds:prog_active,1
;
    mov ax,1000
    WaitMilliSec
    ClearSignal
;    
    mov bx,OFFSET module_arr
    mov cx,ds:module_count
    
pacmLoop:
    push ds
    push bx
    push cx
;    
    mov ds,ds:[bx]
    mov ax,ds:cms_prog_sel
    or ax,ax
    jz pacmNext
;
    call ProgramOneCanModule    
    jc pacmNext
;    
    dec es:prog_count

pacmNext:    
    pop cx
    pop bx
    pop ds
;
    add bx,2
    sub cx,1
    jnz pacmLoop

pacmDone:
    mov ds:prog_active,0
;
    mov ax,2500
    WaitMilliSec
;    
    GetSystemTime
    add eax,5000 * 1193
    adc edx,0    
    WaitForSignalWithTimeout
;    
    ret
ProgramAllCanModules    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           can_com_thread
;
;           DESCRIPTION:    CAN to serial thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

can_com_name      DB 'CAN Com',0
can_module_name   DB 'CAN Module ', 0
can_io_name       DB 'CAN IO ', 0

can_com_thread:
    AddThreadInt
    mov ax,SEG data
    mov ds,ax
    mov es,ax
;    
    GetThread
    mov ds:com_thread,ax
;
    mov di,OFFSET thread_name_str
    mov si,OFFSET can_module_name

can_module_name_loop:    
    lods byte ptr cs:[si]
    stosb
    or al,al
    jnz can_module_name_loop
;
    dec di
    mov ds:thread_name_ptr,di
    mov al,'0'
    stosb
    xor al,al
    stosb
;
    mov di,OFFSET thread_io_name_str
    mov si,OFFSET can_io_name

can_io_name_loop:    
    lods byte ptr cs:[si]
    stosb
    or al,al
    jnz can_io_name_loop
;
    dec di
    mov ds:thread_io_name_ptr,di
    mov al,'0'
    stosb
    xor al,al
    stosb

cctStartWait:
    call InitCanModules

cctLoop:
    mov ax,ds:prog_count
    or ax,ax
    jnz cctHandle
;
    mov ds:init_done,1    
    WaitForSignal

cctHandle:
    EnterSection ds:restart_section
    mov al,ds:pend_restart
    or al,al
    jz cctNotRestart
;
    mov ax,250
    WaitMilliSec
;
    mov ds:pend_restart,0
    call SetupCanModules

cctNotRestart:
    mov ax,ds:prog_count
    or ax,ax
    jz cctLeave
;
    call ProgramAllCanModules
    ResetCanBuffers
    RestartCanModules

cctLeave:
    LeaveSection ds:restart_section
    jmp cctLoop
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetCanModuleInfo
;
;   DESCRIPTION:    Get can module info
;
;   PARAMETERS:     EAX     Module #
;
;   RETURNS:        CX      Number of COM ports
;                   DX      Module type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_info_name  DB 'Get CAN Module Info', 0

get_module_info Proc far
    push ds
;
    mov cx,SEG data
    mov ds,cx

gmiInitWait:    
    mov cl,ds:init_done
    or cl,cl
    jnz gmiInitDone
;
    push ax
    mov ax,100
    WaitMilliSec
    pop ax
    jmp gmiInitWait
    
gmiInitDone:
    cmp ax,ds:module_count
    ja gmiFail
;
    push bx
    mov bx,ax
    dec bx
    shl bx,1
    mov ds,ds:[bx].module_arr
    movzx cx,ds:cms_port_count
    movzx dx,ds:cms_hw_id
    pop bx
    clc
    jmp gmiDone

gmiFail:
    stc    

gmiDone:    
    pop ds
    retf32
get_module_info Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetCanLoaderVersion
;
;   DESCRIPTION:    Get can loader version
;
;   PARAMETERS:     EAX     Module #
;
;   RETURNS:        AL      Minor version
;                   AH      Major version
;                   DL      Sub version
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_loader_version_name  DB 'Get CAN Loader Version', 0

get_loader_version Proc far
    push ds
;
    mov cx,SEG data
    mov ds,cx
    cmp ax,ds:module_count
    ja glvFail
;
    push bx
    mov bx,ax
    dec bx
    shl bx,1
    mov ds,ds:[bx].module_arr
    mov dl,ds:cms_loader_sub_ver
    mov al,ds:cms_loader_minor_ver
    mov ah,ds:cms_loader_major_ver
    pop bx
    clc
    jmp glvDone

glvFail:
    stc    

glvDone:    
    pop ds
    retf32
get_loader_version Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetCanModuleVersion
;
;   DESCRIPTION:    Get can module version
;
;   PARAMETERS:     EAX     Module #
;
;   RETURNS:        AL      Minor version
;                   AH      Major version
;                   DL      Sub version
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_version_name  DB 'Get CAN Module Version', 0

get_module_version Proc far
    push ds
;
    mov cx,SEG data
    mov ds,cx
    cmp ax,ds:module_count
    ja gmvFail
;
    push bx
    mov bx,ax
    dec bx
    shl bx,1
    mov ds,ds:[bx].module_arr
    mov dl,ds:cms_sub_ver
    mov al,ds:cms_minor_ver
    mov ah,ds:cms_major_ver
    pop bx
    clc
    jmp gmvDone

gmvFail:
    stc    

gmvDone:    
    pop ds
    retf32
get_module_version Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetSerialNumber
;
;   DESCRIPTION:    Get module serial number
;
;   PARAMETERS:     EAX         Module #
;                   ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_serial_number_name  DB 'Get CAN Module Serial Number', 0

get_serial_number Proc near
    push ds
    push ebx    
    push esi
    push edi
;
    mov bx,SEG data
    mov ds,bx
    cmp ax,ds:module_count
    ja gsnFail
;
    mov bx,ax
    dec bx
    shl bx,1
    mov ds,ds:[bx].module_arr
    mov esi,OFFSET cms_module_id
    movs dword ptr es:[edi],ds:[esi]
    movs dword ptr es:[edi],ds:[esi]
    movs word ptr es:[edi],ds:[esi]
    
gsnFail:
    stc    

gsnDone:    
    pop edi
    pop esi
    pop ebx
    pop ds
    ret
get_serial_number Endp

get_serial_number16    Proc far
    push edi
    movzx edi,di
    call get_serial_number
    pop edi
    retf32
get_serial_number16    Endp

get_serial_number32    Proc far
    call get_serial_number
    retf32
get_serial_number32    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CheckCanSerialPort
;
;   DESCRIPTION:    Check CAN serial port
;
;   PARAMETERS:     AL      Serial port
;
;   RETURNS:        EAX     Module #
;                   EDX     Module port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_serial_port_name  DB 'Check CAN Serial Port', 0

check_serial_port Proc far
    push ds
    push es
    push fs
    push bx
    push cx
    push si
;
    mov si,1
;    
    mov bx,SEG data
    mov ds,bx

cspInitWait:    
    IsCanOnline
    jc cspFail
;
    mov bl,ds:init_done
    or bl,bl
    jnz cspInitDone
;
    push ax
    mov ax,100
    WaitMilliSec
    pop ax
    jmp cspInitWait
    
cspInitDone:    
    mov bx,OFFSET module_arr
    mov cx,ds:module_count
    or cx,cx
    jz cspFail

cspModuleLoop:
    push bx
    push cx
    push si
;
    mov es,ds:[bx]
    movzx cx,es:cms_port_count
    or cx,cx
    jz cspModuleNext
;
    mov bx,OFFSET cms_dev_arr
    xor dx,dx

cspPortLoop:
    mov si,es:[bx]
    or si,si
    jz cspModuleNext
;
    mov fs,si
    cmp al,fs:cd_com_port
    je cspFound
;
    inc dx
    add bx,2
    loop cspPortLoop    

cspModuleNext:
    pop si
    pop cx
    pop bx
;
    inc si
    add bx,2
    loop cspModuleLoop 
    jmp cspFail       

cspFound:    
    pop si
    pop cx
    pop bx
;    
    movzx eax,si
    movzx edx,dx
    clc
    jmp cspDone

cspFail:
    stc
    
cspDone:
    pop si
    pop cx
    pop bx    
    pop fs
    pop es
    pop ds
    retf32
check_serial_port Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           ProgramCanModule
;
;   DESCRIPTION:    Program can module
;
;   PARAMETERS:     EAX         Module #
;                   ES:(E)DI    Filename
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

program_module_name  DB 'Program CAN Module', 0

program_module Proc near
    push ds
    push es
    push bx
    push ecx
    push edi
;
    mov cx,SEG data
    mov ds,cx
    cmp ax,ds:module_count
    ja pmFail
;
    mov bx,ax
    dec bx
    shl bx,1
    mov ds,ds:[bx].module_arr
;
    xor cl,cl
    UserGateForce32 open_file_nr
    jc pmFail
;
    GetFileSize
    mov ds:cms_prog_size,eax
    mov ecx,eax
    add eax,8
    AllocateGlobalMem
;    
    xor edi,edi
    UserGateForce32 read_file_nr
    jc pmFailFree
;
    CloseFile
    mov ds:cms_prog_sel,es
;
    mov ax,SEG data
    mov ds,ax
    inc ds:prog_count
;    
    mov bx,ds:com_thread
    Signal   
    clc
    jmp pmDone

pmFailFree:
    FreeMem
    CloseFile

pmFail:
    stc

pmDone:    
    pop edi
    pop ecx
    pop bx
    pop es
    pop ds
    ret
program_module Endp

program_module16    Proc far
    push edi
    movzx edi,di
    call program_module
    pop edi
    retf32
program_module16    Endp

program_module32    Proc far
    call program_module
    retf32
program_module32    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           WaitForCanModuleProgramming
;
;   DESCRIPTION:    Wait for can module programming and return completion status
;
;   PARAMETERS:     EAX         Module #
;
;   RETURNS:        AX          Status (0 = ok)
;                   DX          Return code
;                   ECX         Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_programming_name  DB 'Wait For CAN Module Programming', 0

wait_for_programming Proc far
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
    cmp ax,ds:module_count
    ja wfpFail
;
    mov bx,ax
    dec bx
    shl bx,1
    mov ds,ds:[bx].module_arr
;
    GetThread
    mov ds:cms_prog_wait_thread,ax

wfpRetry:    
    mov ax,ds:cms_prog_sel
    or ax,ax
    jz wfpCompleted
;
    WaitForSignal
    jmp wfpRetry

wfpCompleted:
    mov ds:cms_prog_wait_thread,0            
;
    mov ax,ds:cms_prog_status
    mov dx,ds:cms_prog_return
    mov ecx,ds:cms_prog_position
    jmp wfpDone

wfpFail:
    xor ax,ax
    xor dx,dx
    xor ecx,ecx

wfpDone:
    pop bx
    pop ds        
    retf32
wait_for_programming    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           NotifyCanOffline
;
;   DESCRIPTION:    Notify can offline
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_can_offline_name DB 'Notify Can Offline', 0

notify_can_offline  Proc far
    retf32
notify_can_offline  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyCanOnline
;
;       DESCRIPTION:    Notify CAN online
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_can_online_name DB 'Notify Can Online', 0

notify_can_online    PROC far
    push ds
    push es
    pusha
;
    mov ax,SEG data
    mov ds,ax
;
    mov bx,ds:com_thread
    or bx,bx
    jz ncoStart
;
    Signal
    jmp ncoDone

ncoStart:
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET can_com_thread
    mov edi,OFFSET can_com_name
    mov ecx,1000h
    mov ax,4
    CreateThread

ncoDone:
    ResetCanBuffers
    RestartCanModules
;
    popa
    pop es
    pop ds
    retf32
notify_can_online    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           NotifyCanModulesUp
;
;   DESCRIPTION:    Notify can modules up
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_can_modules_up_name DB 'Notify Can Modules Up', 0

notify_can_modules_up  Proc far
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
;
    mov ds:pend_restart,1
    mov bx,ds:com_thread
    Signal
;
    pop bx
    pop ds
    retf32
notify_can_modules_up  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:       Init
;
;       DESCRIPTION:    Device-driver load-point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,SEG data
    mov ds,ax
    InitSection ds:restart_section
    mov ds:com_thread,0
    mov ds:module_count,0
    mov ds:prog_count,0
    mov ds:prog_active,0
    mov ds:init_done,0
    mov ds:pend_restart,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax    
;
    mov esi,OFFSET notify_can_offline
    mov edi,OFFSET notify_can_offline_name
    mov ax,notify_can_offline_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_can_online
    mov edi,OFFSET notify_can_online_name
    mov ax,notify_can_online_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_can_modules_up
    mov edi,OFFSET notify_can_modules_up_name
    mov ax,notify_can_modules_up_nr
    RegisterOsGate
;
    mov esi,OFFSET get_module_info
    mov edi,OFFSET get_module_info_name
    mov ax,get_can_module_info_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET check_serial_port
    mov edi,OFFSET check_serial_port_name
    mov ax,check_can_serial_port_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_loader_version
    mov edi,OFFSET get_loader_version_name
    mov ax,get_can_loader_version_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_module_version
    mov edi,OFFSET get_module_version_name
    mov ax,get_can_module_version_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_serial_number16
    mov esi,OFFSET get_serial_number32
    mov edi,OFFSET get_serial_number_name
    mov dx,virt_es_in
    mov ax,get_can_serial_number_nr
    RegisterUserGate
;
    mov ebx,OFFSET program_module16
    mov esi,OFFSET program_module32
    mov edi,OFFSET program_module_name
    mov dx,virt_es_in
    mov ax,program_can_module_nr
    RegisterUserGate
;
    mov esi,OFFSET wait_for_programming
    mov edi,OFFSET wait_for_programming_name
    mov ax,wait_for_can_module_programming_nr
    RegisterBimodalUserGate
    clc
    ret
init    ENDP

code    ENDS

    END init
