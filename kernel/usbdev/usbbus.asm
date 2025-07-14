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
; USBBUS.ASM
; Implements USB bus class
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
include ..\os\com.inc

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

FLAG_UDS_DISCONNECT = 2
FLAG_UDS_REINIT = 4

SET_BAUD      = 1
SET_DATA_BITS = 2
SET_PARITY    = 3
START_SERIAL  = 4
STOP_SERIAL   = 5

usbcom_port_struc       STRUC

ups_base_struc  com_port_struc <>

ups_device_sel      DW ?
ups_index           DW ?
ups_divisor         DW ?
ups_timer_active    DB ?
ups_data_bits       DB ?
ups_stop_bits       DB ?
ups_parity          DB ?
ups_control         DB ?

usbcom_port_struc       ENDS

usbcom_device_struc   STRUC

uds_base_struc      com_device_struc <>

uds_section         section_typ <>
uds_port_sel        DW ?
uds_in_size         DW ?
uds_out_size        DW ?
uds_interface       DB ?
uds_bulk_in         DB ?
uds_bulk_out        DB ?
uds_in_handle       DW ?
uds_out_handle      DW ?
uds_in_buffer       DW ?
uds_out_buffer      DW ?
uds_in_req          DW ?
uds_out_req         DW ?
uds_link            DW ?
uds_flag            DB ?
uds_port_nr         DW ?

usbcom_device_struc   ENDS

io_entry        STRUC

io_id               DB ?
io_status           DB ?
io_adr              DB ?
io_cmd              DB ?
io_val              DB 4 DUP(?)

io_wait_thread      DW ?

io_entry        ENDS

io_seg  STRUC

io_serv_thread      DW ?
io_controller       DW ?
io_address          DB ?
io_port             DB ?

io_section          section_typ <>

io_in_size          DW ?
io_out_size         DW ?
io_intr_in          DB ?
io_bulk_out         DB ?
io_dev_handle       DW ?
io_in_buffer        DW ?
io_out_buffer       DW ?
io_wait             DW ?

io_insert_id        DB ?
io_process_id       DB ?

io_entry_arr        DB 16 * 256 DUP (?)

io_seg  ENDS

data    SEGMENT byte public 'DATA'

sd_thread       DW ?
sd_dead         DW ?
sd_spinlock     spinlock_typ <>
sd_port         DW ?
sd_dev_handle   DW ?

io_sel          DW ?

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AllocateBusReq
;
;   DESCRIPTION:    Allocate bus req entry
;
;   PARAMETERS:     DS  IO bus sel
;
;   RETURNS:        BX  Entry offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBusReq Proc near
    push eax
    push ecx
;
    mov cl,ds:io_insert_id
    movzx bx,cl
    shl bx,4
    add bx,OFFSET io_entry_arr
    mov ax,ds:[bx].io_wait_thread
    or ax,ax
    stc
    jnz abrDone
;
    GetThread
    mov ds:[bx].io_wait_thread,ax
    mov ds:[bx].io_id,cl
    mov ds:[bx].io_status,-1
;
    inc cl
    or cl,cl
    jnz abrSave
;
    inc cl

abrSave:
    mov ds:io_insert_id,cl
    clc

abrDone:
    pop ecx
    pop eax
    ret
AllocateBusReq Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleReply
;
;   DESCRIPTION:    Handle USB reply
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleReply     Proc near
    push ds
    push es
    pushad
;
    mov eax,ds
    mov es,eax
;
    mov ds,ds:io_in_buffer
    mov cl,ds:io_id
    movzx ebx,cl
    shl ebx,4
    add ebx,OFFSET io_entry_arr
;
    xor esi,esi
    mov edi,ebx
    movsd
    movsd
;
    mov edi,ebx
    xor bx,bx
    xchg bx,es:[edi].io_wait_thread
    Signal    
;
    popad
    pop es
    pop ds
    ret
HandleReply     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           BusThread
;
;   DESCRIPTION:    Bus thread
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bus_thread_name  DB 'USB Bus IO', 0

bus_thread:
    mov eax, SIZE io_seg
    mov ecx,eax
    AllocateSmallGlobalMem
;
    xor edi,edi
    xor al,al
    rep stosb
;
    mov eax,SEG data
    mov ds,eax
    mov ds:io_sel,es
;
    mov eax,es
    mov ds,eax
    InitSection ds:io_section
    mov ds:io_insert_id,1
    mov ds:io_process_id,1
;
    GetThread
    mov ds:io_serv_thread,ax

btOff:
    WaitForSignal
;
    mov al,ds:io_bulk_out
    or al,al
    jz btOff

btCreate:
    mov bx,ds:io_controller
    movzx ax,ds:io_address
    OpenUsbDevice
    mov ds:io_dev_handle,bx
;
    push es
    movzx eax,ds:io_in_size
    AllocateSmallGlobalMem
    mov ds:io_in_buffer,es
    pop es
;
    mov bx,ds:io_dev_handle
    mov dl,ds:io_intr_in
    mov cx,10
    mov ax,2
    OpenUsbPacketPipe
;
    mov bx,ds:io_dev_handle
    mov dl,ds:io_bulk_out
    mov cx,ds:io_out_size
    shl cx,2
    mov ax,5
    OpenUsbRawPipe
    mov ds:io_out_buffer,es
;
    CreateWait
    mov ds:io_wait,bx
;
    mov ax,ds:io_dev_handle
    mov dl,ds:io_intr_in
    mov ecx,ds
    AddWaitForUsbDevicePipe

btRestart:
    EnterSection ds:io_section
    mov al,ds:io_insert_id
    inc al
    mov ds:io_process_id,al
    LeaveSection ds:io_section

btOn:
    mov bx,ds:io_dev_handle
    mov dl,ds:io_intr_in
    mov es,ds:io_in_buffer
    xor edi,edi
    movzx ecx,ds:io_in_size
    GetUsbPacketPipe
    jc btCheckReq
;
    call HandleReply

btCheckReq:
    EnterSection ds:io_section
;
    mov cl,ds:io_process_id
    cmp cl,ds:io_insert_id
    je btWaitLeave
;
    movzx bx,cl
    shl bx,4
    add bx,OFFSET io_entry_arr
    mov ax,ds:[bx].io_wait_thread
    or ax,ax
    jz btReadNext
;
    push es
    pushad
;
    mov es,ds:io_out_buffer
    xor edi,edi
    movzx esi,bx
    movsd
    movsd
;
    mov ecx,8
    mov bx,ds:io_dev_handle
    mov dl,ds:io_bulk_out
    PostUsbRawPipe
;
    popad
    pop es

btReadNext:
    inc cl
    or cl,cl
    jnz btReadSave
;
    inc cl

btReadSave:
    mov ds:io_process_id,cl
    LeaveSection ds:io_section
    jmp btCheckOn

btWaitLeave:
    LeaveSection ds:io_section
;
    mov cl,ds:io_process_id
    cmp cl,ds:io_insert_id
    jne btCheckReq

btWaitOn:
    mov bx,ds:io_wait
    WaitWithoutTimeout

btCheckOn:
    mov al,ds:io_bulk_out
    or al,al
    jnz btOn
;
    mov bx,ds:io_dev_handle
    mov dl,ds:io_intr_in
    CloseUsbPipe
;
    mov bx,ds:io_dev_handle
    mov dl,ds:io_bulk_out
    CloseUsbPipe
;
    mov bx,ds:io_dev_handle
    CloseUsbDevice
;    
    push es
    mov es,ds:io_in_buffer
    FreeMem
    pop es
;
    mov bx,ds:io_wait
    CloseWait
    jmp btOff

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AttachBus
;
;   DESCRIPTION:    Attach bus
;
;   PARAMETERS:     AL      Device address
;                   AH      Port
;                   BX      Controller id
;                   ES:DI   Interface descriptor + endpoints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AttachBus Proc near
    push ds
    push es
    push fs
    pushad
;
    mov edx,SEG data
    mov ds,edx
    mov dx,ds:io_sel
    or dx,dx
    jz abDone
;
    mov fs,edx
    mov fs:io_controller,bx
    mov fs:io_address,al
    mov fs:io_port,ah
;
    mov fs:io_bulk_out,0
    mov fs:io_intr_in,0
;
    xor dx,dx
    movzx cx,es:[di].uid_len
    add di,cx

abDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne abDescrDone
;
    mov cl,es:[di].ued_attrib
    and cl,3
    cmp cl,2
    je abBulk
;
    cmp cl,3
    jne abDescrNext

abIntr:
    inc dh
    mov cl,es:[di].ued_address
    and cl,8Fh
    mov fs:io_intr_in,cl
;
    mov cx,es:[di].ued_maxsize
    mov fs:io_in_size,cx
    jmp abDescrNext

abBulk:
    mov cl,es:[di].ued_address
    test cl,80h    
    jnz abDescrNext

abBulkOut:
    inc dl
    cmp dl,1
    je abDescrNext
;
    and cl,0Fh
    mov fs:io_bulk_out,cl
;
    mov cx,es:[di].ued_maxsize
    mov fs:io_out_size,cx
    jmp abDescrNext
    
abDescrNext:    
    cmp dx,102h
    je abDescrDone
;
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb abDescrLoop    
;
    jmp abDone
    
abDescrDone:
    mov bx,fs:io_serv_thread
    Signal

abDone:
    popad
    pop fs
    pop es
    pop ds
    ret
AttachBus Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           DetachBus
;
;   DESCRIPTION:    Detach bus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DetachBus Proc near
    push ds
    push es
    push fs
    pushad
;
    mov edx,SEG data
    mov ds,edx
    mov dx,ds:io_sel
    or dx,dx
    jz dbDone
;
    mov fs:io_intr_in,0
    mov fs:io_bulk_out,0
;
    mov bx,fs:io_serv_thread
    Signal

dbDone:
    popad
    pop fs
    pop es
    pop ds
    ret
DetachBus Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:               ToggleSerialLine
;
;       DESCRIPTION:        Toggle serial input line
;
;       PARAMETERS:         DH              Device #
;                           DL              Line #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_serial_line_name DB 'Toggle Serial Line', 0

toggle_serial_line      Proc far
    push ds
    push eax
    push ebx
    push ecx
;
    mov ebx,SEG data
    mov ds,ebx
    mov bx,ds:io_sel
    or bx,bx
    stc
    jz tslDone
;
    mov ds,bx
    EnterSection ds:io_section
    call AllocateBusReq
    jc tslFail
;
    mov ds:[bx].io_adr,dh
;
    mov al,dl
    shl al,3
    or al,4
    mov ds:[bx].io_cmd,al
    LeaveSection ds:io_section
;
    push bx
    mov bx,ds:io_serv_thread
    Signal
    pop bx
;
    WaitForSignal
    mov al,ds:[bx].io_status
    cmp al,-1
    stc
    je tslDone
;
    clc
    jmp tslDone

tslFail:
    LeaveSection ds:io_section
    stc

tslDone:
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
toggle_serial_line  Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:               ReadSerialLines
;
;       DESCRIPTION:        Read serial lines
;
;       PARAMETERS:         DH              Device #
;
;       RETURNS:            AL              State
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_serial_lines_name  DB 'Read Serial Lines', 0

read_serial_lines       Proc far
    push ds
    push ebx
    push ecx
;
    mov ebx,SEG data
    mov ds,ebx
    mov bx,ds:io_sel
    or bx,bx
    stc
    jz rslDone
;
    mov ds,bx
    EnterSection ds:io_section
    call AllocateBusReq
    jc rslFail
;
    mov ds:[bx].io_adr,dh
;
    mov al,dl
    shl al,3
    or al,5
    mov ds:[bx].io_cmd,al
    LeaveSection ds:io_section
;
    push bx
    mov bx,ds:io_serv_thread
    Signal
    pop bx
;
    WaitForSignal
    mov al,ds:[bx].io_status
    cmp al,-1
    stc
    je rslDone
;
    mov al,ds:[bx].io_val
    clc
    jmp rslDone

rslFail:
    LeaveSection ds:io_section
    stc

rslDone:
    pop ecx
    pop ebx
    pop ds
    ret
read_serial_lines       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:               WriteSerialVal
;
;       DESCRIPTION:        Write serial value
;
;       PARAMETERS:         DL              Line #
;                           DH              Device #
;                           EAX             Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_serial_val_name   DB 'Write Serial Value', 0

write_serial_val        Proc far
    push ds
    push eax
    push ebx
    push ecx
;
    mov ebx,SEG data
    mov ds,ebx
    mov bx,ds:io_sel
    or bx,bx
    stc
    jz wsvDone
;
    mov ds,bx
    EnterSection ds:io_section
    call AllocateBusReq
    jc wsvFail
;
    mov ds:[bx].io_adr,dh
;
    mov cl,al
    and cl,3Fh
    mov ds:[bx].io_val,cl
;
    shr eax,6
    and cl,3Fh
    mov ds:[bx].io_val+1,cl
;
    shr eax,6
    and cl,3Fh
    mov ds:[bx].io_val+2,cl
;
    shr eax,6
    and cl,3Fh
    mov ds:[bx].io_val+3,cl
;
    mov al,dl
    shl al,3
    or al,3
    mov ds:[bx].io_cmd,al
    LeaveSection ds:io_section
;
    push bx
    mov bx,ds:io_serv_thread
    Signal
    pop bx
;
    WaitForSignal
    mov al,ds:[bx].io_status
    cmp al,-1
    stc
    je wsvDone
;
    clc
    jmp wsvDone

wsvFail:
    LeaveSection ds:io_section
    stc

wsvDone:
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
write_serial_val        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:               ReadSerialVal
;
;       DESCRIPTION:        Read serial val
;
;       PARAMETERS:         DL              Line #
;                           DH              Device #
;
;       RETURNS:            EAX             Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_serial_val_name    DB 'Read Serial Value', 0

read_serial_val Proc far
    push ds
    push ebx
    push ecx
;
    mov ebx,SEG data
    mov ds,ebx
    mov bx,ds:io_sel
    or bx,bx
    stc
    jz rsvDone
;
    mov ds,bx
    EnterSection ds:io_section
    call AllocateBusReq
    jc rsvFail
;
    mov ds:[bx].io_adr,dh
;
    mov al,dl
    shl al,3
    or al,2
    mov ds:[bx].io_cmd,al
    LeaveSection ds:io_section
;
    push bx
    mov bx,ds:io_serv_thread
    Signal
    pop bx
;
    WaitForSignal
    mov al,ds:[bx].io_status
    cmp al,-1
    stc
    je rsvDone
;
    movzx eax,ds:[bx].io_val
;
    movzx ecx,ds:[bx].io_val+1
    shl ecx,6
    add eax,ecx
;
    movzx ecx,ds:[bx].io_val+2
    shl ecx,12
    add eax,ecx
;
    movzx ecx,ds:[bx].io_val+3
    shl ecx,18
    add eax,ecx

    cmp eax,920797h
    jne rsvNotErr
;
    mov eax,dword ptr ds:[bx].io_val
    int 3

rsvNotErr:
    clc
    jmp rsvDone

rsvFail:
    LeaveSection ds:io_section
    stc

rsvDone:
    pop ecx
    pop ebx
    pop ds
    ret
read_serial_val Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitCom
;
;           description:    Init com port
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitCom   Proc near
    push es
    pushad
;
    push ds
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:sd_dev_handle
    pop ds
;
    mov ah,40h
    mov al,SET_DATA_BITS
    xor si,si
    movzx dx,ds:ups_data_bits
    xor cx,cx
    SendUsbDeviceControlMsg
    jc icDone
;
    mov ah,40h
    mov al,SET_PARITY
    xor si,si
    movzx dx,ds:ups_parity
    xor cx,cx
    SendUsbDeviceControlMsg
    jc icDone
;
    mov ah,40h
    mov al,SET_BAUD
    xor si,si
    mov dx,ds:ups_divisor
    xor cx,cx
    SendUsbDeviceControlMsg
    jc icDone
;
    mov ah,40h
    mov al,START_SERIAL
    xor si,si
    xor dx,dx
    xor cx,cx
    SendUsbDeviceControlMsg

icDone:
    popad
    pop es
    ret
InitCom   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetBaudDivisor
;
;           description:    Get baud-rate divisor
;
;           PARAMETERS:     DS      Port selector
;                           ECX     baudrate
;
;       RETURNS:            AX      Divisor to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBaudDivisor Proc near
    push ecx
    push edx
;    
    cmp ecx,300
    jb gbdFail
;
    xor edx,edx
    mov eax,8000000
    div ecx
    test eax,0FFFF0000h
    jnz gbdFail
;
    or ax,ax
    jz gbdFail
;
    dec ax
    clc
    jmp gbdDone

gbdFail:
    stc

gbdDone:    
    pop edx
    pop ecx    
    ret
GetBaudDivisor Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           open_com
;
;           description:    Open a serial port
;
;           PARAMETERS:         DS      Port selector
;                       ES          Device selector
;                           AH          # of data bits
;                           BL          # of stop bits
;                           BH          parity
;                           ECX         baudrate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com    Proc far
    push ds
    pushad
;
    mov ds:ups_timer_active,0
    mov ds:ups_data_bits,ah
    mov ds:ups_stop_bits,bl
    mov ds:ups_parity,bh
;
    call GetBaudDivisor
    jc ocDone
;
    mov ds:ups_divisor,ax    
    call InitCom
;    
    mov ds:ups_device_sel,es
    mov dx,ds
    mov ax,es
    mov ds,ax
    EnterSection ds:uds_section
    mov ds:uds_port_sel,dx
    LeaveSection ds:uds_section       
;
    mov ax,SEG data
    mov ds,ax    
    mov bx,ds:sd_thread
    Signal    
    clc

ocDone:
    popad
    pop ds
    ret
open_com Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           close_com
;
;           description:    Close serial port
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_com   Proc far
    push ds
    pushad
;    

;
    push ds
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:sd_dev_handle
    pop ds
;
    mov ah,40h
    mov al,STOP_SERIAL
    xor si,si
    xor dx,dx
    xor cx,cx
    SendUsbDeviceControlMsg
;    
    mov ax,ds
    mov bx,ds:ups_device_sel
    or bx,bx
    jz ccfNoDevice
;
    mov ds,bx    
    EnterSection ds:uds_section
    mov ds:uds_port_sel,0
    LeaveSection ds:uds_section       

ccfNoDevice:    
    mov ds,ax
    mov ds:ups_device_sel,0
;
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:sd_thread
    Signal    
;
    mov ax,150
    WaitMilliSec    
;
    popad
    pop ds    
    ret
close_com   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ResetPort
;
;           DESCRIPTION:    Reset com
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_port       PROC far
    ret
reset_port Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           start_send
;
;           description:    Start send
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_send      PROC far
    push es
    push ax
;    
    mov ax,ds:ups_device_sel
    or ax,ax
    jz ssDone
;    
    mov es,ax
    test es:uds_flag,FLAG_UDS_DISCONNECT
    jz ssOk
;
    mov ds:send_count,0
    jmp ssDone

ssOk:    
    call StartSendTimer

ssDone:
    pop ax
    pop es    
    ret
start_send      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       CreatePort
;
;           description:    Create port selector
;
;           RETURNS:        ES      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_req       Proc far
    ret
error_req       Endp

port_tab:
pt00 DD OFFSET open_com,               SEG code
pt01 DD OFFSET close_com,              SEG code
pt02 DD OFFSET error_req,              SEG code
pt03 DD OFFSET error_req,              SEG code
pt04 DD OFFSET error_req,              SEG code
pt05 DD OFFSET error_req,              SEG code
pt06 DD OFFSET error_req,              SEG code
pt07 DD OFFSET error_req,              SEG code
pt08 DD OFFSET error_req,              SEG code
pt09 DD OFFSET error_req,              SEG code
pt10 DD OFFSET error_req,              SEG code
pt11 DD OFFSET start_send,             SEG code
pt12 DD OFFSET reset_port,             SEG code
pt13 DD OFFSET error_req,              SEG code
pt14 DD OFFSET error_req,              SEG code
pt15 DD OFFSET error_req,              SEG code

CreatePort  Proc far
    pushad
;
    mov eax,SIZE usbcom_port_struc
    AllocateSmallGlobalMem
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
;
    mov si,OFFSET port_tab
    xor di,di
    mov cx,2 * 16
    rep movs dword ptr es:[di],cs:[si]
;
    movzx ax,ds:uds_interface
    mov es:ups_index,ax    
;    
    popad
    ret
CreatePort  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       OpenPort
;
;           description:    Open port selector
;
;           RETURNS:        ES      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPort Proc far
    mov bx,ds:cd_controller
;    mov ax,ds:cd_device
    mov dl,ds:uds_bulk_in
;    OpenUsbPipe
    mov ds:uds_in_handle,bx
;
;    CreateUsbReq
    mov ds:uds_in_req,bx    
;    
    mov cx,ds:uds_in_size
    xor ax,ax
;    AddReadUsbDataReq
    mov ds:uds_in_buffer,es
;
    mov bx,ds:cd_controller
;    mov ax,ds:cd_device
    mov dl,ds:uds_bulk_out
;    OpenUsbPipe    
    mov ds:uds_out_handle,bx
;
;    CreateUsbReq
    mov ds:uds_out_req,bx
;    
    mov cx,ds:uds_out_size
    xor ax,ax
;    AddWriteUsbDataReq
    mov ds:uds_out_buffer,es
    ret
OpenPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClosePort
;
;           DESCRIPTION:    Close port
;
;       PARAMETERS:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePort    Proc near
    mov ax,50
    WaitMilliSec
;    
    xor ax,ax
    mov es,ax
;    
    mov bx,ds:uds_in_req
;    CloseUsbReq
    mov ds:uds_in_req,0
;
    mov bx,ds:uds_in_handle
;    CloseUsbPipe    
    mov ds:uds_in_handle,0
;
    mov bx,ds:uds_out_req
;    CloseUsbReq
    mov ds:uds_out_req,0
;
    mov bx,ds:uds_out_handle
;    CloseUsbPipe    
    mov ds:uds_out_handle,0
    mov ds:uds_in_buffer,0
    mov ds:uds_out_buffer,0
    ret
ClosePort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReInit
;
;           DESCRIPTION:    Reinit port
;
;       PARAMETERS:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReInit    Proc near
    push ds
    push es
    push cx
    push di
;    
    mov ax,ds
    mov es,ax
    mov ds,es:uds_port_sel
    call InitCom
;
    pop di
    pop cx
    pop es
    pop ds
    ret
ReInit  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendSignal
;
;           description:    Sends signal to USB-handler thread
;
;       Parameters:     CX      Port selector
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
    mov ds:ups_timer_active,0
;    
    mov ax,SEG data
    mov ds,ax    
    mov bx,ds:sd_thread
    Signal    

ssiDone:
    pop bx
    pop ax
    pop ds
    ret
SendSignal  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartSendTimer
;
;           description:    Starts send timeout
;
;       Parameters:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartSendTimer Proc near
    push es
    pushad
;       
    mov al,1    
    xchg al,ds:ups_timer_active
    or al,al
    jnz sstDone
;
    GetSystemTime
    add eax,11930
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
;           NAME:           PollRead
;
;           DESCRIPTION:    Poll input-buffer
;
;       PARAMETERS:     FS      SEG data
;               DS      Function sel
;               SI      Buffer offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollRead    Proc near
    push ds
    push fs
    mov fs,ds:uds_in_buffer
    mov ds,ds:uds_port_sel
    mov es,ds:rec_buf

prGetLoop:
    lods byte ptr fs:[si]
    RequestSpinlock ds:com_spinlock
    mov dx,ds:rec_count
    cmp dx,ds:rec_size
    je prSignal
;       
    inc dx
    mov ds:rec_count,dx
    mov bx,ds:rec_tail
    mov es:[bx],al
    inc bx
    cmp bx,ds:rec_size
    jnz prWrapOk
;
    xor bx,bx
    
prWrapOk:
    mov ds:rec_tail,bx
    ReleaseSpinlock ds:com_spinlock
    loop prGetLoop
    jmp prSigRel

prSignal:
    ReleaseSpinlock ds:com_spinlock

prSigRel:
    xor bx,bx
    xchg bx,ds:avail_obj
    or bx,bx
    jz prDone
;
    mov es,bx
    SignalWait
    
prDone:
    pop fs
    pop ds
    ret
PollRead    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PollWrite
;
;           DESCRIPTION:    Poll output-buffer
;
;       PARAMETERS:     FS      SEG data
;               DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollWrite    Proc near
    push ds
    push fs
;   
    xor cx,cx
    mov bp,ds:uds_out_size
    mov ax,ds:uds_out_buffer
    or ax,ax
    jz pwDone
;    
    mov es,ax
    mov ds,ds:uds_port_sel
    mov al,ds:ups_timer_active
    or al,al
    jnz pwDone
;    
    xor di,di
    mov fs,ds:send_buf
    mov dx,ds:send_count
    or dx,dx
    jz pwDone

pwLoop:
    RequestSpinlock ds:com_spinlock
    mov dx,ds:send_count
    or dx,dx
    jz pwSend
;       
    dec dx
    mov ds:send_count,dx
    mov bx,ds:send_head
    mov al,fs:[bx]
    stosb
    inc bx
    cmp bx,ds:send_size
    jnz pwWrapOk
;       
    xor bx,bx

pwWrapOk:
    mov ds:send_head,bx
    ReleaseSpinlock ds:com_spinlock
;
    inc cx
    cmp cx,bp
    jb pwLoop
    jmp pwSendRel

pwSend:
    ReleaseSpinlock ds:com_spinlock

pwSendRel:
    mov ax,ds:send_size    
    or ax,ax
    jz pwDone
;
    call StartSendTimer    

pwDone:
    pop fs
    pop ds    
    ret
PollWrite   Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleDevice
;
;           DESCRIPTION:    Handle device
;
;       PARAMETERS:     FS      SEG data
;               DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleDevice    Proc near
    push ds
;
    test ds:uds_flag,FLAG_UDS_DISCONNECT
    jnz hdDone

hdConn:
    mov ax,ds:uds_port_sel
    or ax,ax
    jz hdClosed

hdOpen:
    mov bx,ds:uds_in_req
    or bx,bx
    jnz hdIsOpen
;
    call OpenPort    
;
    test ds:uds_flag,FLAG_UDS_REINIT
    jz hdIsOpen    
;
    call ReInit
    and ds:uds_flag,NOT FLAG_UDS_REINIT

hdIsOpen:    
    mov bx,ds:uds_in_req
;    IsUsbReqStarted
    jnc hdOpenOk
;
;    StartUsbReq

hdOpenOk:    
    mov bx,ds:uds_in_req
;    IsUsbReqReady
    jc hdReadDone
;
;    GetUsbReqData
    jc hdReadRestart
;    
    xor si,si
    or cx,cx
    jz hdReadRestart
;    
    call PollRead

hdReadRestart:
    mov bx,ds:uds_in_req
;    StartUsbReq

hdReadDone:
    mov bx,ds:uds_out_req
;    IsUsbReqStarted
    jc hdCheckWrite
;    
;    IsUsbReqReady
    jc hdDone
;
    push ds
    mov ds,ds:uds_port_sel
    mov bx,ds:send_wait
    pop ds
    or bx,bx
    jz hdCheckWrite
;    
    Signal

hdCheckWrite:
    call PollWrite
    or cx,cx
    jz hdDone
;
    mov bx,ds:uds_out_req
;    StartUsbReq
    jmp hdDone

hdClosed:
    and ds:uds_flag,NOT FLAG_UDS_REINIT
;
    mov bx,ds:uds_in_req
    or bx,bx
    jz hdDone

hdIsClosed:
    call ClosePort
    
hdDone:
    xor ax,ax
    mov es,ax
    pop ds
    ret
HandleDevice    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UsbComThread
;
;           DESCRIPTION:    Com-port handler thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usbcom_thread_name  DB 'USB Bus Com', 0

usbcom_thread:
    mov ax,SEG data
    mov fs,ax
    GetThread
    mov fs:sd_thread,ax

utLoop:
    WaitForSignal
;
    mov ax,fs:sd_port
    or ax,ax
    jz utLoop
;
    mov ds,ax
    push cx
    push si
;
    EnterSection ds:uds_section
    call HandleDevice
    LeaveSection ds:uds_section
;
    pop si
    pop cx
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:sd_dev_handle
    CloseUsbDevice
    jmp utLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateDevice
;
;   DESCRIPTION:    Handle device attach
;
;   PARAMETERS:     AL      Device address
;                   AH      Device port
;                   BX      Controller id
;                   ES:DI   Interface descriptor + endpoints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDevice Proc near
    push ds
    push es
    pushad
;    
    push dx
    push di
    mov dx,SEG data
    mov ds,dx
;
    push ax
    mov al,ah
    OpenUsbDevice
    pop ax
    mov ds:sd_dev_handle,bx
;
    mov dx,ds:sd_thread
    or dx,dx
    jnz cdThreadStarted
;
    mov ds:sd_thread,-1
    push ds
    push es
    push ax
    push si
    push di    
;    
    mov dx,cs
    mov ds,dx
    mov es,dx
    mov di,OFFSET usbcom_thread_name
    mov si,OFFSET usbcom_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    pop di
    pop si
    pop ax
    pop es
    pop ds
        
cdThreadStarted:
    push bx
    xor bx,bx
    xor bp,bp
    xor dx,dx
    xor si,si
    movzx cx,es:[di].uid_len
    add di,cx

cdDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne cdDescrDone
;
    mov cl,es:[di].ued_attrib
    and cl,3
    cmp cl,2
    jne cdDescrNext
;
    mov cl,es:[di].ued_address
    test cl,80h    
    jnz cdBulkIn

cdBulkOut:
    inc si
    and cl,0Fh
    mov dl,cl
    mov bx,es:[di].ued_maxsize
    jmp cdDescrNext

cdBulkIn:
    inc si
    and cl,8Fh
    mov dh,cl
    mov bp,es:[di].ued_maxsize
    
cdDescrNext:    
    cmp si,2
    je cdDescrDone
;
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb cdDescrLoop    
    
cdDescrDone:
    shl ebp,16
    mov bp,bx    
    pop bx
;    
    mov cx,dx
    pop di
    pop dx
;    
    or cl,cl
    jz cdDone
;
    or ch,ch
    jz cdDone
;    
    mov dx,ds:sd_dead
    or dx,dx
    jz cdNoRecover
;
    mov ds:sd_dead,0
    mov ds,dx
    EnterSection ds:uds_section
    mov al,ds:uds_flag
    or al,FLAG_UDS_REINIT
    and al,NOT FLAG_UDS_DISCONNECT
    mov ds:uds_flag,al
;    
    mov ax,SEG data
    mov ds,ax
    mov ds:sd_port,dx
;
    mov ds,dx    
    LeaveSection ds:uds_section
;    
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:sd_thread
    Signal    
    jmp cdDone
    
cdNoRecover:
    push cx
    mov cl,es:[di].uid_id
    push ax
    mov eax,SIZE usbcom_device_struc
    AllocateSmallGlobalMem
    pop ax
    mov es:uds_interface,cl
    pop dx
    mov es:uds_port_sel,0
    mov es:uds_bulk_in,dh
    mov es:uds_bulk_out,dl
;       
    mov es:uds_out_size,bp
    shr ebp,16
    mov es:uds_in_size,bp
    mov es:uds_in_handle,0
    mov es:uds_in_req,0
    mov es:uds_in_buffer,0
    mov es:uds_out_handle,0
    mov es:uds_out_req,0
    mov es:uds_out_buffer,0
    mov es:uds_flag,0
;
    push ds
    mov si,es
    mov ds,si
    InitSection ds:uds_section
    pop ds
;
    mov ds:sd_port,es
    mov dx,es
    mov ds,dx
    mov dword ptr ds:cd_create_proc,OFFSET CreatePort
    mov dword ptr ds:cd_create_proc+4,cs
;    
    movzx dx,al
    mov ax,bx
    AddComPort
    mov ds:uds_port_nr,ax

cdDone:
    popad
    pop es
    pop ds      
    ret
CreateDevice Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       usb_attach
;
;           description:    USB attach callback
;
;           Parameters:     BX      Controller #
;                           AL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

devTab:
dt00    DW 054Dh,       1001h

usb_attach  Proc far
    push ds
    push es
    pushad
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
    mov bp,OFFSET devTab

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
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

uaDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,4
    jne uaDescrNext
; 
    call AttachBus
    call CreateDevice
    jmp uaDone

uaDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb uaDescrLoop    

uaDone:
    FreeMem
;
    popad
    pop es
    pop ds
    ret
usb_attach  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       usb_detach
;
;           description:    USB detach callback
;
;           Parameters:     BX      Controller #
;                           AL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    pushad
;    
    mov dx,SEG data
    mov ds,dx
    mov dx,ds:sd_port
    or dx,dx
    jz udDone
;
    mov es,dx
    cmp bx,es:cd_controller
    jne udDone
;
    movzx ax,al
    cmp ax,es:cd_device
    jne udDone
;
    mov ds,dx
    EnterSection ds:uds_section
    or ds:uds_flag,FLAG_UDS_DISCONNECT
;    
    mov dx,SEG data
    mov ds,dx
    mov ds:sd_port,0
    mov ds:sd_dead,es
;
    mov ax,es
    mov ds,ax
    call ClosePort
    call DetachBus
;
    mov ax,ds:uds_port_sel
    or ax,ax
    jz udPortHandleOk
;
    push es
    mov es,ax
    mov es:send_count,0
    mov bx,es:send_wait
    or bx,bx
    jz udPortSendOk
;
    Signal    

udPortSendOk:
    pop es

udPortHandleOk:    
    LeaveSection ds:uds_section    

udDone:
    popad
    pop es
    pop ds
    ret
usb_detach  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetComPar
;
;   DESCRIPTION:    Get com param
;
;   PARAMETERS:     AL      Port #
;
;   RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_com_par_name    DB 'Get USB Bus Param', 0

get_com_par Proc far
    push ds
    push es
    push bx
;
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:sd_port
    or bx,bx
    jz gcpFail
;
    mov es,bx
    cmp ax,es:uds_port_nr
    je gcpFound

gcpFail:
    stc
    jmp gcpDone

gcpFound:
    clc

gcpDone:
    pop bx
    pop es
    pop ds
    ret
get_com_par     ENDP    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_pci
;
;           DESCRIPTION:    Create hook thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_bus    Proc far
    push ds
    push es
    pushad
;
    mov edx,cs
    mov ds,edx
    mov es,edx
    mov edi,OFFSET bus_thread_name
    mov esi,OFFSET bus_thread
    mov ax,2
    mov ecx,stack0_size
    CreateThread
;
    popad
    pop es
    pop ds
    ret
init_bus    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init    Proc far
    mov ax,SEG data
    mov ds,eax
    mov ds:sd_thread,0
    mov ds:sd_port,0
    mov ds:sd_dead,0
    InitSpinlock ds:sd_spinlock
    mov ds:io_sel,0
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov edi,OFFSET init_bus
    HookInitTasking
;
    mov edi,OFFSET usb_attach
    HookUsbAttach
;
    mov edi,OFFSET usb_detach
    HookUsbDetach
;
    mov esi,OFFSET get_com_par
    mov edi,OFFSET get_com_par_name
    xor dx,dx
    mov ax,get_usb_bus_par_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET read_serial_lines
    mov edi,OFFSET read_serial_lines_name
    mov ax,read_serial_lines_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET toggle_serial_line
    mov edi,OFFSET toggle_serial_line_name
    mov ax,toggle_serial_line_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_serial_val
    mov edi,OFFSET write_serial_val_name
    mov ax,write_serial_val_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET read_serial_val
    mov edi,OFFSET read_serial_val_name
    mov ax,read_serial_val_nr
    RegisterBimodalUserGate
    clc
    ret
Init    Endp
        
code    ENDS

    END Init
