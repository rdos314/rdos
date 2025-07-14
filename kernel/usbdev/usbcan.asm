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
; USBCAN.ASM
; USB can driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include usb.inc
INCLUDE ..\os\protseg.def

REC_BUF_COUNT = 80h

id_hook_struc   STRUC

ih_id       DD ?
ih_mask     DD ?
ih_offset   DD ?
ih_sel      DW ?
ih_param    DW ?

id_hook_struc   ENDS


capture_block   STRUC

cc_prev     DD ?
cc_next     DD ?
cc_time     DD ?,?
cc_id       DD ?
cc_data     DD ?,?
cc_size     DB ?

capture_block   ENDS

data_block   STRUC

db_data     DB 10 DUP(?)
db_prev     DW ?
db_next     DW ?

data_block   ENDS


data    SEGMENT byte public 'DATA'

cd_server_thread DW ?
cd_controller    DW ?
cd_in_wait       DW ?
cd_dev_handle    DW ?
cd_in_buffer     DW ?
cd_out_buffer    DW ?
cd_port          DB ?
cd_active        DB ?

in_buf           DB 10 DUP(?)

can_active       DB ?
can_restart      DB ?

can_prog_sel     DW ?
can_prog_size    DD ?

hw_id            DB ?
hw_major         DB ?
hw_minor         DB ?
ver_major        DB ?
ver_minor        DB ?
ver_sub          DB ?

prog_state       DB ?

send_sel         DW ?
send_count       DW ?
send_head        DW ?
send_tail        DW ?

send_section     section_typ <>

can_id_hook_arr  DD 15 * 4 DUP(?)

capture_handle          DW ?
capture_thread          DW ?
capture_list            DD ?
capture_section         section_typ <>

cd_data          DB 8 DUP(?)

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateSendBuf
;
;       DESCRIPTION:    Create a send buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSendBuf   Proc near
    push es
    push ebx
    push ecx
    push edx
;
    mov ax,SEG data
    mov ds,ax
;
    mov eax,1000h
    AllocateGlobalMem
;
    mov ds:send_sel,es
    mov ds:send_count,0
    mov ds:send_head,0
    mov ds:send_tail,0
    InitSection ds:send_section
;
    pop edx
    pop ecx
    pop ebx
    pop es
    ret
CreateSendBuf   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InsertSend
;
;   DESCRIPTION:    Insert send
;
;   PARAMETERS:     EDX:EAX     Data
;                   CL          Size (0..8)
;                   EBX         Identifier
;       
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertSend   Proc near
    push es
    push si
    push di
;
    EnterSection ds:send_section
    mov di,ds:send_count
    cmp di,100h
    je isDone
;       
    mov es,ds:send_sel
    inc di
    mov ds:send_count,di
;
    mov di,ds:send_tail
    shl di,4
    mov byte ptr es:[di],0
    mov es:[di+1],cl
    shr ebx,14
    xchg bl,bh
    or es:[di],bx
    mov es:[di+2],eax
    mov es:[di+6],edx
;
    shr di,4
    inc di
    cmp di,100h
    jnz isWrapOk
;
    xor di,di
    
isWrapOk:
    mov ds:send_tail,di

isDone:
    LeaveSection ds:send_section
;
    push bx
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:cd_server_thread
    Signal
    pop bx
;
    pop di
    pop si
    pop es
    ret
InsertSend   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetSendBuffer
;
;   DESCRIPTION:    Get send buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSendBuffer   Proc near
    push bx
    push dx
;
    EnterSection ds:send_section
    mov dx,ds:send_count
    or dx,dx
    stc
    jz gsbDone
;
    dec dx
    mov ds:send_count,dx
;
    push ds
    push es
    push si
    push di
;
    mov es,ds:cd_out_buffer
    mov si,ds:send_head
    shl si,4
    mov ds,ds:send_sel
    xor di,di
    movsd
    movsd
    movsw
;
    pop di
    pop si
    pop es
    pop ds
;
    mov bx,ds:send_head
    inc bx
    cmp bx,100h
    jnz gsbWrapOk
;       
    xor bx,bx

gsbWrapOk:
    mov ds:send_head,bx
    clc

gsbDone:
    LeaveSection ds:send_section
;
    pop dx
    pop bx
    ret
GetSendBuffer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetSoftwareVersion
;
;       DESCRIPTION:    Get software version
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSoftwareVersion   Proc near
    push es
    pushad
;
    mov ax,ds
    mov es,ax
    mov bx,ds:cd_dev_handle
    mov ah,0C1h
    mov al,92h
    xor dx,dx
    xor si,si
    mov cx,6
    mov di,OFFSET cd_data
    SendUsbDeviceControlMsg
    jc gsvDone
;
    mov bx,OFFSET cd_data
    mov al,[bx]
    mov ds:hw_id,al
    mov al,[bx+1]
    mov ds:hw_major,al
    mov al,[bx+2]
    mov ds:hw_minor,al
    mov al,[bx+3]
    mov ds:ver_major,al
    mov al,[bx+4]
    mov ds:ver_minor,al
    mov al,[bx+5]
    mov ds:ver_sub,al

gsvDone:
    popad
    pop es
    ret
GetSoftwareVersion  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PowerUpModules
;
;       DESCRIPTION:    Power up modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PowerUpModules   Proc near
    pushad
;
    mov bx,ds:cd_dev_handle
    mov ah,41h
    mov al,93h
    mov dx,101h
    xor si,si
    xor cx,cx
    SendUsbDeviceControlMsg
;
    popad
    ret
PowerUpModules  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PowerDownModules
;
;       DESCRIPTION:    Power down modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PowerDownModules   Proc near
    pushad
;
    mov bx,ds:cd_dev_handle
    mov ah,41h
    mov al,93h
    mov dx,100h
    xor si,si
    xor cx,cx
    SendUsbDeviceControlMsg
;
    popad
    ret
PowerDownModules  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartModules
;
;       DESCRIPTION:    Start modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartModules   Proc near
    pushad
;
    mov bx,ds:cd_dev_handle
    mov ah,41h
    mov al,91h
    xor dx,dx
    xor si,si
    xor cx,cx
    SendUsbDeviceControlMsg
;
    popad
    ret
StartModules  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartDownload
;
;       DESCRIPTION:    Start download
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartDownload   Proc near
    pushad
;
    mov bx,ds:cd_dev_handle
    mov ah,41h
    mov al,90h
    mov dx,1
    xor si,si
    xor cx,cx
    SendUsbDeviceControlMsg
;
    popad
    ret
StartDownload  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetDownloadStatus
;
;       DESCRIPTION:    Get download status
;
;       RETURNS:        AL         Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDownloadStatus   Proc near
    push es
    push cx
    push dx
    push si
    push di
;
    mov ax,SEG data
    mov es,ax
    mov bx,ds:cd_dev_handle
    mov ah,0C1h
    mov al,96h
    xor dx,dx
    xor si,si
    mov cx,1
    mov di,OFFSET cd_data
    SendUsbDeviceControlMsg
    jc gdsDone
;
    mov al,[di]
    clc

gdsDone:
    pop di
    pop si
    pop dx
    pop cx
    pop es
    ret
GetDownloadStatus  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsCanOnline
;
;       DESCRIPTION:    Check is can bus is online
;
;       RETURNS:        NC      Online
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_can_online_name    DB 'Is Can Online', 0

is_can_online   Proc far
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
;
    mov ax,ds:cd_controller
    cmp ax,-1
    jz icoFail
;
    mov ax,ds:cd_in_wait
    or ax,ax
    jz icoFail
;
    clc
    jmp icoDone

icoFail:
    stc

icoDone:
    pop ax
    pop ds
    retf32
is_can_online   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ResetCanModules
;
;       DESCRIPTION:    Reset can communication
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_can_modules_name    DB 'Reset Can Modules', 0

reset_can_modules   Proc far
    push ds
    push bx
;
    mov ax,SEG data
    mov ds,ax
    mov ds:can_active,0
;
    mov bx,ds:cd_dev_handle
    ResetUsbDevice
;
    pop bx
    pop ds
    retf32
reset_can_modules  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RestartCanModules
;
;       DESCRIPTION:    Restart can communication
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

restart_can_modules_name    DB 'Retart Can Modules', 0

restart_can_modules   Proc far
    push ds
;
    mov ax,SEG data
    mov ds,ax
    mov ds:can_active,0
    mov ds:can_restart,1
;
    pop ds
    retf32
restart_can_modules  Endp

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
;   Description:    Notify reception of CAN packet
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
;   NAME:           HandleMsg
;
;   DESCRIPTION:    Notify CAN message
;
;   PARAMETERS:     EDX:EAX     Data
;                   CL          Size (0..8)
;                   EBX         Identifier
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleMsg   Proc near
    push ds
    push es
    push di
;
    call NotifyMsg
;
    push eax
    push ecx
;
    mov si,OFFSET can_id_hook_arr
    mov cx,15

hmIdLoop:
    mov di,ds:[si].ih_sel
    or di,di
    jz hmIdNext
;
    mov eax,ds:[si].ih_mask
    and eax,ebx
    cmp eax,ds:[si].ih_id
    je hmIdOk

hmIdNext:
    add si,16
    loop hmIdLoop
;
    pop ecx
    pop eax
    jmp hmDone

hmIdOk:
    mov ax,ds
    mov es,ax
;
    pop ecx
    pop eax
;
    mov ds,es:[si].ih_param
    call fword ptr es:[si].ih_offset

hmDone:
    pop di
    pop es
    pop ds
    ret
HandleMsg   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           USB CAN thread
;
;       DESCRIPTION:    USB can thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usbcan_thread_name DB 'USB Can ', 0

usbcan_thread:
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    GetThread
    mov ds:cd_server_thread,ax
;
    NotifyCanOnline
;
    call GetSoftwareVersion

ustLoop:
    mov al,ds:cd_active
    or al,al
    jz ustEnd

ustPipeOk:
    mov ax,ds:can_prog_sel
    or ax,ax
    jnz ustProg
;
    mov al,ds:cd_active
    or al,al
    jz ustEnd
;
    mov ax,ds:cd_in_wait
    or ax,ax
    jz ustRestart
;
    mov al,ds:can_restart
    or al,al
    jz ustMsgWait

ustRestart:
    call PowerDownModules
    jc ustReset
;
    mov ax,500
    WaitMilliSec
;
    call PowerUpModules
    jc ustReset
;
    mov ax,4000
    WaitMilliSec
;
    call StartModules
    jc ustReset
;
    mov ds:can_restart,0
;
    mov ax,ds:cd_in_wait
    or ax,ax
    jnz ustRestartWait
;
    push es
    mov eax,10
    AllocateSmallGlobalMem
    mov ds:cd_in_buffer,es
    pop es
;
    mov bx,ds:cd_dev_handle
    mov dl,81h
    mov cx,20
    mov ax,2
    OpenUsbPacketPipe
;
    push es
    mov bx,ds:cd_dev_handle
    mov dl,2
    mov cx,10
    mov ax,5
    OpenUsbRawPipe
    mov ds:cd_out_buffer,es
    pop es
;
    CreateWait
    mov ds:cd_in_wait,bx
;
    mov ax,ds:cd_dev_handle
    mov dl,81h
    mov ecx,ds
    AddWaitForUsbDevicePipe

ustRestartWait:
    mov ds:can_active,1
    NotifyCanModulesUp

ustMsgWait:
    mov bx,ds:cd_dev_handle
    IsUsbDeviceConnected
    jc ustEnd
;
    mov bx,ds:cd_in_wait
    WaitWithoutTimeout
;
    mov ax,ds:can_prog_sel
    or ax,ax
    jnz ustProg

ustMsgLoop:
    mov bx,ds:cd_dev_handle
    IsUsbDeviceConnected
    jc ustEnd
;
    mov es,ds:cd_in_buffer
    xor edi,edi
    mov ecx,10
    mov dl,81h
    GetUsbPacketPipe
    jc ustNoRec
;
    mov cl,es:[di+1]
    and cl,0Fh
    movzx ebx,word ptr es:[di]
    xchg bl,bh
    and bl,0F0h
    shl ebx,14
    mov eax,es:[di+2]
    mov edx,es:[di+6]
    call HandleMsg

ustNoRec:
    call GetSendBuffer
    jc ustMsgWait
;
    mov bx,ds:cd_dev_handle
    mov dl,2
    mov ecx,10
    PostUsbRawPipe
    jmp ustMsgLoop

ustProg:
    mov fs,ds:can_prog_sel
    xor esi,esi
;
    mov ds:prog_state,0
    mov ds:cd_active,0
;
    mov bx,ds:cd_dev_handle
    mov dl,81h
    CloseUsbPipe
;
    xor bx,bx
    xchg bx,ds:cd_in_wait
    CloseWait
;
    mov ax,100
    WaitMilliSec
;
    call StartDownload
    jc ustProgFail

ustProgLoop:
    call GetDownloadStatus    
    jc ustProgFail
;
    mov ds:prog_state,al
    or al,al
    jz ustSendNext
;
    cmp al,10h
    je ustProgDone
;
    cmp al,11h
    jne ustProgDone
;
    mov ax,5
    WaitMilliSec
    jmp ustProgLoop

ustSendNext:
    mov ecx,ds:can_prog_size
    or ecx,ecx
    clc
    jz ustProgDone
;
    cmp ecx,10
    jbe ustSendDo
;
    mov ecx,10

ustSendDo:    
    mov es,ds:cd_out_buffer
    xor edi,edi
    sub ds:can_prog_size,ecx
    rep movs byte ptr es:[edi],fs:[esi]    
;
    mov ecx,10
    mov bx,ds:cd_dev_handle
    mov dl,2
    PostUsbRawPipe
    jnc ustProgLoop

ustProgFail:
    mov ds:prog_state,12h

ustProgDone:
    xor ax,ax
    xchg ax,ds:can_prog_sel
    mov es,ax
    FreeMem

ustReset:
    mov bx,ds:cd_dev_handle
    ResetUsbDevice

ustEnd:
    mov bx,ds:cd_dev_handle
    mov dl,81h
    CloseUsbPipe
;
    mov bx,ds:cd_dev_handle
    mov dl,2
    CloseUsbPipe
;    
    push es
    mov es,ds:cd_in_buffer
    FreeMem
    pop es
;
    xor bx,bx
    xchg bx,ds:cd_in_wait
    CloseWait
;
    mov ds:cd_in_buffer,0    
    mov ds:cd_out_buffer,0    
;
    mov bx,ds:cd_dev_handle
    CloseUsbDevice
;
    mov ds:can_active,0
    mov ds:cd_active,0
    mov ds:cd_server_thread,0
    TerminateThread
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HexToAscii
;
;   DESCRIPTION:    
;
;   PARAMETERS:     AL      Number to convert
;
;   RETURNS:        AX      Ascii result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HexToAscii      PROC near
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
;
    add al,7

ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
;
    add ah,7

ok_high1:
    add ah,30h
    ret
HexToAscii      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartThread
;
;       DESCRIPTION:    Start thread
;
;       PARAMETERS:     DS      Data
;                       AX      Prio
;                       ESI     Entry
;                       EDI     Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartThread Proc near
    push ds
    push es            
;
    push ax
    push esi
;
    mov esi,edi
    mov eax,100h
    AllocateSmallGlobalMem
    xor edi,edi

sfCopyLoop:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz sfCopyDone
;
    stosb
    jmp sfCopyLoop

sfCopyDone:
    mov ax,ds:cd_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,ds:cd_port
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;
    pop esi         
;
    xor edi,edi
    mov ax,cs
    mov ds,ax
    pop ax
    mov ecx,stack0_size
    CreateThread
;
    FreeMem
;
    pop es
    pop ds
    ret
StartThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddDevice
;
;       DESCRIPTION:    Add device
;
;       PARAMETERS:     AL      Port #
;                       BX      Controller id
;                       ES:DI   Interface descriptor + endpoints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDevice Proc near
    push ds
    push es
    pushad
;
    mov dx,SEG data
    mov ds,dx
    mov ds:cd_port,al
    mov ds:cd_controller,bx
    mov ds:cd_active,1
;
    OpenUsbDevice
    mov ds:cd_dev_handle,bx
;
    mov dx,ds:cd_server_thread
    or dx,dx
    jnz adThreadStarted
;
    mov ds:can_restart,1
    mov ds:cd_server_thread,-1    
;
    mov esi,OFFSET usbcan_thread
    mov edi,OFFSET usbcan_thread_name
    mov ax,2
    call StartThread
        
adThreadStarted:
    popad
    pop es
    pop ds      
    ret
AddDevice Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           usb_attach
;
;       description:    USB attach callback
;
;       Parameters:     BX      Controller #
;                       AL      Device port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

canTab:
cc00    DW 06F9h,       5555h
 
usb_attach  Proc far
    push es
;    
    push ax
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
    pop ax
    xor di,di
    push ax
    GetUsbDevice
    cmp ax,cx
    pop ax
    jne uaDone
;
    mov si,es:udd_vendor
    mov di,es:udd_prod

    mov cx,1
    mov bp,OFFSET canTab

uaLoop:
    cmp si,cs:[bp]
    jne uaNext
;
    cmp di,cs:[bp+2]
    je uaFound

uaNext:
    add bp,4
    loop uaLoop    
;
    jmp uaDone    

uaFound:
    xor dl,dl
    mov cx,1000h
    xor di,di
    push ax
    GetUsbConfig
    mov cx,ax
    pop ax
    or cx,cx
    jz uaDone
;
    push ax
    mov dl,es:ucd_config_id
    ConfigUsbDevice
    pop ax
    jc uaDone
;
    call AddDevice
    jmp uaDone
    
uaDone:
    FreeMem
;
    pop es    
    retf32
usb_attach  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       usb_detach
;
;           description:    USB detach callback
;
;           Parameters:     BX      Controller #
;                           AL      Device port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    pushad
;    
    mov dx,SEG data
    mov ds,dx
    cmp bx,ds:cd_controller
    jne udDone
;
    cmp ah,ds:cd_port
    jne udDone
;
    mov ds:can_active,0
    mov ds:cd_controller,-1
    mov ds:cd_active,0
    mov ds:can_restart,1
;
    mov bx,ds:cd_server_thread
    Signal
;
    mov ax,100
    WaitMilliSec
;
    NotifyCanOffline

udDone:
    popad
    pop es
    pop ds
    retf32
usb_detach  Endp


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
    xor ax,ax
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
    mov ds:[bx].ih_id,eax
    mov ds:[bx].ih_mask,edx
    mov ds:[bx].ih_param,bp
    mov ds:[bx].ih_offset,edi
    mov ds:[bx].ih_sel,es
;            
    sub bx,OFFSET can_id_hook_arr
    shr bx,4
    inc bx
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
    push ax
;    
    mov ax,SEG data
    mov ds,ax
;
    mov ax,ds:send_count
    cmp ax,100h
    stc
    je hcsbDone
;
    clc

hcsbDone:
    pop ax
    pop ds    
    retf32
has_can_send_buf    Endp    

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
    push bp
;
    mov bp,SEG data
    mov ds,bp
    mov bp,ds:cd_server_thread
    or bp,bp
    jz scbDone
;
    cmp bp,-1
    jz scbDone
;
    call NotifyMsg
    call InsertSend

scbDone:
    pop bp
    pop ds
    retf32
send_can_bus_msg    Endp    

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
;   NAME:           GetCanBridgeVersion
;
;   DESCRIPTION:    Get can bridge version
;
;   RETURNS:        AL      Minor version
;                   AH      Major version
;                   DL      Sub version
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_can_bridge_version_name  DB 'Get CAN Bridge Version', 0

get_can_bridge_version Proc far
    push ds
;
    mov ax,SEG data
    mov ds,ax
    mov al,ds:can_active
    or al,al
    jz gcbvFail
;
    mov al,ds:ver_minor
    mov ah,ds:ver_major
    mov dl,ds:ver_sub
    clc
    jmp gcbvDone

gcbvFail:
    stc    

gcbvDone:    
    pop ds
    retf32
get_can_bridge_version Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           ProgramCanBridge
;
;   DESCRIPTION:    Program can bridge
;
;   PARAMETERS:     ES:(E)DI    Filename
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

program_can_bridge_name  DB 'Program CAN Bridge', 0

program_can_bridge Proc near
    push ds
    push es
    push bx
    push ecx
    push edi
;
    mov ax,SEG data
    mov ds,ax
    mov al,ds:can_active
    or al,al
    jz pcbFail
;
    xor cl,cl
    UserGateForce32 open_file_nr
    jc pcbFail
;
    GetFileSize32
    mov ds:can_prog_size,eax
    mov ecx,eax
    add eax,8
    AllocateGlobalMem
;    
    xor edi,edi
    UserGateForce32 read_file_nr
    jc pcbFailFree
;
    CloseFile
    mov ds:can_prog_sel,es
;    
    mov bx,ds:cd_server_thread
    Signal   
    clc
    jmp pcbDone

pcbFailFree:
    FreeMem
    CloseFile

pcbFail:
    stc

pcbDone:    
    pop edi
    pop ecx
    pop bx
    pop es
    pop ds
    ret
program_can_bridge Endp

program_can_bridge16    Proc far
    push edi
    movzx edi,di
    call program_can_bridge
    pop edi
    retf32
program_can_bridge16    Endp

program_can_bridge32    Proc far
    call program_can_bridge
    retf32
program_can_bridge32    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           WaitForCanBridgeProgramming
;
;   DESCRIPTION:    Wait for can bridge programming
;
;   RETURNS:        AX      Result
;                   DX      Error code
;                   ECX     Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_can_bridge_programming_name  DB 'Wait For CAN Bridge Programming', 0

wait_for_can_bridge_programming Proc far
    push ds
;
    mov ax,SEG data
    mov ds,ax

wfcbpLoop:
    mov ax,ds:can_prog_sel
    or ax,ax
    jz wfcbpOk
;
    mov ax,200
    WaitMilliSec
    jmp wfcbpLoop

wfcbpOk:    
    mov al,ds:prog_state
    cmp al,10h
    jne wfcbFail
;
    xor ax,ax
    xor dx,dx
    xor ecx,ecx
    jmp wfcbDone

wfcbFail:
    movzx dx,al
    mov ax,-1
    mov ecx,ds:can_prog_size

wfcbDone:
    pop ds
    retf32
wait_for_can_bridge_programming Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov bx,SEG data
    mov es,bx
    mov es:cd_server_thread,0
    mov es:cd_controller,-1
    mov es:cd_active,0
    mov es:cd_dev_handle,0
    mov es:cd_in_buffer,0
    mov es:cd_out_buffer,0
    mov es:can_active,0
    mov es:can_restart,0
    InitSection es:capture_section
    mov es:capture_handle,0
    mov es:capture_thread,0
    mov es:capture_list,0
    mov ds:can_prog_sel,0
    mov ds:can_prog_size,0
;
    mov di,OFFSET can_id_hook_arr
    mov cx,4 * 15
    xor eax,eax
    rep stosd
;       
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET reset_can_modules
    mov edi,OFFSET reset_can_modules_name
    mov ax,reset_can_modules_nr
    RegisterOsGate
;
    mov esi,OFFSET restart_can_modules
    mov edi,OFFSET restart_can_modules_name
    mov ax,restart_can_modules_nr
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
    mov esi,OFFSET has_can_send_buf
    mov edi,OFFSET has_can_send_buf_name
    mov ax,has_can_send_buf_nr
    RegisterOsGate
;
    mov esi,OFFSET send_can_bus_msg
    mov edi,OFFSET send_can_bus_msg_name
    mov ax,send_can_bus_msg_nr
    RegisterOsGate
;
    mov esi,OFFSET send_can_bus_msg
    mov edi,OFFSET send_can_bus_msg_name
    mov ax,send_can_bus_block_nr
    RegisterOsGate
;
    mov esi,OFFSET is_can_online
    mov edi,OFFSET is_can_online_name
    xor dx,dx
    mov ax,is_can_online_nr
    RegisterBimodalUserGate
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
    mov esi,OFFSET get_can_bridge_version
    mov edi,OFFSET get_can_bridge_version_name
    mov ax,get_can_bridge_version_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET program_can_bridge16
    mov esi,OFFSET program_can_bridge32
    mov edi,OFFSET program_can_bridge_name
    mov dx,virt_es_in
    mov ax,program_can_bridge_nr
    RegisterUserGate
;
    mov esi,OFFSET wait_for_can_bridge_programming
    mov edi,OFFSET wait_for_can_bridge_programming_name
    mov ax,wait_for_can_bridge_programming_nr
    RegisterBimodalUserGate
;
    mov edi,OFFSET usb_attach
    HookUsbAttach
;
    mov edi,OFFSET usb_detach
    HookUsbDetach
;
    call CreateSendBuf
    clc
    ret
init    Endp

code    ENDS

    END init
