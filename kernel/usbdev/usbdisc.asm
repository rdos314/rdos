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
; usbdisc.ASM
; Implements mass storage class for USB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\drive.inc
include ..\usbdev\usb.inc

MAX_DISCS   = 16

drive_struc STRUC

drive_nr                DB ?

drive_struc ENDS

cbw_struc   STRUC

disc_cbw_sign           DD ?
disc_cbw_tag            DD ?
disc_cbw_transfer_len   DD ?
disc_cbw_flags          DB ?
disc_cbw_lun            DB ?
disc_cbw_cmd_len        DB ?
disc_cbw_cmd_data       DB 16 DUP(?)

cbw_struc  ENDS

csw_struc  STRUC

disc_csw_sign           DD ?
disc_csw_tag            DD ?
disc_csw_residue        DD ?
disc_csw_status         DB ?

csw_struc  ENDS

disc_struc   STRUC

disc_dev_handle         DW ?

disc_bulk_in_pipe       DB ?
disc_bulk_out_pipe      DB ?

disc_bulk_in_maxsize    DW ?
disc_bulk_out_maxsize   DW ?

disc_bulk_in_buf        DW ?
disc_bulk_out_buf       DW ?

disc_controller         DW ?
disc_port               DB ?

disc_nr                 DB ?
disc_handle             DW ?

disc_sectors            DD ?
disc_sectors_per_unit   DW ?

disc_drive_arr          DW 4 DUP(?)

disc_serial             DB ?
disc_vendor             DW ?
disc_prod               DW ?

disc_exp_tag            DD ?
;
; do not reorganize, connected to responses
;

; capacity
disc_cap                DD ?,?

; inquiry
disc_peri               DB ?
disc_removable          DB ?
disc_ver                DB ?
disc_resp_form          DB ?
disc_intq_resv          DB 4 DUP(?)
disc_vendor_str         DB 8 DUP(?)
disc_prod_str           DB 16 DUP(?)
disc_rev_str            DB 4 DUP(?)

; request sense
disc_sense_data         DB 18 DUP(?)
   
disc_struc  ENDS

data    SEGMENT byte public 'DATA'

disc_device_arr     DW MAX_DISCS DUP(?)

fs_name             DB 10 DUP(?)

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    .386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SendCbw
;
;   DESCRIPTION:    Send CBW
;
;   PARAMETERS:     FS      Disc sel
;                   ES      Bulk out sel
;                   EAX     Tag
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCbw Proc near
    pushad
;
    mov es:disc_cbw_lun,0
    mov es:disc_cbw_sign,43425355h
    mov es:disc_cbw_tag,eax
    mov fs:disc_exp_tag,eax
;
    mov ecx,31
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_out_pipe
    PostUsbRawPipe
    jc scbwDone
;
    cmp cx,31
    stc
    jnz scbwDone
;
    clc

scbwDone:
    popad
    ret
SendCbw Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ReceiveCsw
;
;   DESCRIPTION:    Receive CSW
;
;   PARAMETERS:     FS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveCsw Proc near
    push es
    pushad
;
    mov ecx,13
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    PostUsbRawPipe
    jc rcswDone
    
rcswOk:
    cmp cx,13
    stc
    jnz rcswDone
;
    mov es,fs:disc_bulk_in_buf
    mov eax,es:disc_csw_sign
    cmp eax,53425355h
    stc
    jne rcswDone
;
    mov eax,es:disc_csw_tag
    cmp eax,fs:disc_exp_tag
    stc
    jne rcswDone
;
    mov al,es:disc_csw_status
    or al,al    
    stc
    jnz rcswDone
;    
    clc

rcswDone:     
    popad   
    pop es    
    ret
ReceiveCsw Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ResetDevice
;
;   DESCRIPTION:    Reset device
;
;   PARAMETERS:     FS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetDevice Proc near
    pushad
;
    mov bx,fs:disc_dev_handle
    mov al,0FFh
    mov ah,21h
    xor dx,dx
    xor si,si
    xor cx,cx
    SendUsbDeviceControlMsg
;
    popad
    ret
ResetDevice     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           Inquiry
;
;   DESCRIPTION:    Send inquiry
;
;   PARAMETERS:     FS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Inquiry Proc near
    push ds
    push es
;
    mov es,fs:disc_bulk_out_buf
    mov es:disc_cbw_transfer_len,36
    mov es:disc_cbw_flags,80h
    mov es:disc_cbw_cmd_len,6
    mov es:disc_cbw_cmd_data,12h
    mov es:disc_cbw_cmd_data+1,0
    mov es:disc_cbw_cmd_data+2,0
    mov es:disc_cbw_cmd_data+3,0
    mov es:disc_cbw_cmd_data+4,36
    mov es:disc_cbw_cmd_data+5,0
    mov eax,0F000FFFFh
    call SendCbw
;    
    mov es,fs:disc_bulk_in_buf
    mov ecx,36
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    PostUsbRawPipe
    jc inqDone
;    
    cmp cx,36
    jb inqDone
;
    mov ds,fs:disc_bulk_in_buf
    mov ax,fs
    mov es,ax
    xor esi,esi
    mov edi,OFFSET disc_peri
    mov ecx,36
    rep movsb
;
    call ReceiveCsw

inqDone:
    pop es
    pop ds
    ret
Inquiry Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           RequestSense
;
;   DESCRIPTION:    Request sense data
;
;   PARAMETERS:     FS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RequestSense Proc near
    push ds
    push es
;
    mov es,fs:disc_bulk_out_buf
    mov es:disc_cbw_transfer_len,18
    mov es:disc_cbw_flags,80h
    mov es:disc_cbw_cmd_len,12
    mov es:disc_cbw_cmd_data,3
    mov es:disc_cbw_cmd_data+1,0
    mov es:disc_cbw_cmd_data+2,0
    mov es:disc_cbw_cmd_data+3,0
    mov es:disc_cbw_cmd_data+4,18
    mov es:disc_cbw_cmd_data+5,0
    mov es:disc_cbw_cmd_data+6,0
    mov es:disc_cbw_cmd_data+7,0
    mov es:disc_cbw_cmd_data+8,0
    mov es:disc_cbw_cmd_data+9,0
    mov es:disc_cbw_cmd_data+10,0
    mov es:disc_cbw_cmd_data+11,0
    mov es:disc_cbw_cmd_data+12,0
    mov es:disc_cbw_cmd_data+13,0
    mov es:disc_cbw_cmd_data+14,0
    mov es:disc_cbw_cmd_data+15,0
;
    mov eax,2
    call SendCbw
    jc reqsDone
;    
    mov es,fs:disc_bulk_in_buf
    mov ecx,18
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    PostUsbRawPipe
    jc reqsDone
;
    cmp cx,18
    jb reqsDone
;
    mov ds,fs:disc_bulk_in_buf
    mov ax,fs
    mov es,ax
    xor esi,esi
    mov edi,OFFSET disc_sense_data
    mov ecx,18
    rep movsb
;    
    call ReceiveCsw

reqsDone:
    pop es
    pop ds
    ret
RequestSense Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ReadCapacity
;
;   DESCRIPTION:    Read capacity data
;
;   PARAMETERS:     FS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCapacity Proc near
    push ds
    push es
;
    mov es,fs:disc_bulk_out_buf
    mov es:disc_cbw_transfer_len,8
    mov es:disc_cbw_flags,80h
    mov es:disc_cbw_cmd_len,10
    mov es:disc_cbw_cmd_data,25h
    mov es:disc_cbw_cmd_data+1,0
    mov es:disc_cbw_cmd_data+2,0
    mov es:disc_cbw_cmd_data+3,0
    mov es:disc_cbw_cmd_data+4,0
    mov es:disc_cbw_cmd_data+5,0
    mov es:disc_cbw_cmd_data+6,0
    mov es:disc_cbw_cmd_data+7,0
    mov es:disc_cbw_cmd_data+8,0
    mov es:disc_cbw_cmd_data+9,0
;
    mov eax,0D000DDDDh
    call SendCbw
    jc rcDone
;    
    mov es,fs:disc_bulk_in_buf
    mov ecx,8
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    PostUsbRawPipe
    jc rcDone
;
    xor di,di
    mov eax,es:[di]
    mov edx,es:[di+4]
;    
    call ReceiveCsw
    jc rcDone
;
    xchg dl,dh
    rol edx,16
    xchg dl,dh
    cmp edx,200h
    stc
    jne rcDone
;
    xchg al,ah
    rol eax,16
    xchg al,ah
    inc eax
    mov fs:disc_sectors,eax
    clc

rcDone:
    pop es
    pop ds
    ret
ReadCapacity Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadRaw
;
;       DESCRIPTION:    Read using raw interface
;
;       PARAMETERS:     FS      Disc selector
;                       ESI     Disc handle array
;                       EBP     Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadRaw      Proc near
    push ebp
    push esi

rwBufLoop:  
    cmp ebp,8
    ja rwBufWhole
;
    mov eax,200h
    mul ebp
    mov ecx,eax
    jmp rwBufDo

rwBufWhole:
    mov ecx,1000h

rwBufDo:
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    PostUsbRawPipe
    jc rwBufReadDone
;
    xor edx,edx

rwBufCopy:
    push es
    push ecx
    push esi
;
    mov edi,es:[esi]
    mov edi,es:[edi].dh_data
    mov ecx,80h
    mov ds,fs:disc_bulk_in_buf
    mov esi,edx
    rep movs dword ptr es:[edi],ds:[esi]
    mov edx,esi
;
    pop esi
    pop ecx
    pop ds
;
    add esi,4
    sub ebp,1
    clc
    jz rwBufReadDone
;
    sub ecx,200h
    jnz rwBufCopy
    jmp rwBufLoop

rwBufReadDone:
    pop esi
    pop ebp
    ret
ReadRaw  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       read_drive
;
;       DESCRIPTION:    Read drive
;
;       PARAMETERS:     FS      Disc selector
;               ESI     Disc handle array
;               ECX     Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_drive      Proc near

rdLoop:    
    push ecx
    mov edi,es:[esi]
;
    mov edx,es:[edi].dh_unit
    movzx eax,fs:disc_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
    mov ebx,edx
    mov ebp,1
;
    push esi    

rdSizeLoop:
    cmp ecx,ebp
    jbe rdDoTrans
;
    add esi,4
    mov edi,es:[esi]
;
    push ebx
    mov edx,es:[edi].dh_unit
    movzx eax,fs:disc_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
    pop ebx
;
    inc ebx
    cmp ebx,edx
    jne rdDoTrans
;
    inc ebp
    jmp rdSizeLoop            

rdDoTrans:
    pop esi
;    
    mov edi,es:[esi]
    mov edx,es:[edi].dh_unit
    movzx eax,fs:disc_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
;    
    shl ebp,9

rdRetry:
    push es
    mov es,fs:disc_bulk_out_buf    
    mov es:disc_cbw_tag,edx
    mov es:disc_cbw_transfer_len,ebp
    mov es:disc_cbw_flags,80h
    mov es:disc_cbw_cmd_len,10
    mov es:disc_cbw_cmd_data,28h
    mov es:disc_cbw_cmd_data+1,0
;
    mov eax,edx
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov dword ptr es:disc_cbw_cmd_data+2,eax
;
    mov es:disc_cbw_cmd_data+6,0
;
    shr ebp,9
    mov ax,bp
    xchg al,ah    
    mov word ptr es:disc_cbw_cmd_data+7,ax
    mov es:disc_cbw_cmd_data+9,0
;
    mov eax,edx
    call SendCbw
    pop es
    jc rdFail
;    
    call ReadRaw
    jc rdFail
;    
    call ReceiveCsw
    jnc rdOk
    
rdFail:
    call ResetDevice
    jmp rdRetry

rdFailLoop:    
    pop ecx
;
    mov edi,es:[esi]
    mov eax,es:[edi].dh_data
    mov es:[eax].dh_state,STATE_BAD
    mov bx,fs:disc_handle
    DiscRequestCompleted
    add esi,4
    sub ecx,1
    sub ebp,1
    jnz rdFailLoop
;    
    jmp rdNext

rdOk:
    pop ecx

rdOkLoop:
    mov edi,es:[esi]
    mov eax,es:[edi].dh_data
    mov es:[edi].dh_state,STATE_USED
    mov bx,fs:disc_handle
    DiscRequestCompleted
    add esi,4
    sub ecx,1
    sub ebp,1
    jnz rdOkLoop

rdNext:
    or ecx,ecx
    jnz rdLoop
;
    ret
read_drive      Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteRaw
;
;       DESCRIPTION:    Write using raw interface
;
;       PARAMETERS:     FS      Disc selector
;                       ESI     Disc handle array
;                       EBP     Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteRaw      Proc near
    push ebp
    push esi

wrBufLoop:  
    cmp ebp,8
    ja wrBufWhole
;
    mov eax,200h
    mul ebp
    mov ecx,eax
    jmp wrBufDo

wrBufWhole:
    mov ecx,1000h

wrBufDo:
    push ecx
    xor edx,edx

wrBufCopy:
    push ds
    push es
    push ecx
    push esi
;
    mov esi,es:[esi]
    mov esi,es:[esi].dh_data
    mov ax,es
    mov ds,ax
    mov ecx,80h
    mov es,fs:disc_bulk_out_buf
    mov edi,edx
    rep movs dword ptr es:[edi],ds:[esi]
    mov edx,edi
;
    pop esi
    pop ecx
    pop es
    pop ds
;
    add esi,4
    sub ebp,1
    jz wrBufWrite
;
    sub ecx,200h
    jnz wrBufCopy

wrBufWrite:
    pop ecx
;
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_out_pipe
    PostUsbRawPipe
    jc wrBufWriteDone
;
    or ebp,ebp
    jnz wrBufLoop
;
    clc

wrBufWriteDone:
    pop esi
    pop ebp
    ret
WriteRaw  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       write_drive
;
;       DESCRIPTION:    Perform a write request
;
;       PARAMETERS:     FS      Disc selector
;               ESI     Disc handle array
;               ECX     Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_drive     Proc near

wdLoop:    
    push ecx
    mov edi,es:[esi]
;
    mov edx,es:[edi].dh_unit
    movzx eax,fs:disc_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
    mov ebx,edx
    mov ebp,1
;
    push esi    

wdSizeLoop:
    cmp ecx,ebp
    jbe wdDoTrans
;
    add esi,4
    mov edi,es:[esi]
;
    push ebx
    mov edx,es:[edi].dh_unit
    movzx eax,fs:disc_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
    pop ebx
;
    inc ebx
    cmp ebx,edx
    jne wdDoTrans
;
    inc ebp
    jmp wdSizeLoop            

wdDoTrans:
    pop esi
;    
    mov edi,es:[esi]
    mov edx,es:[edi].dh_unit
    movzx eax,fs:disc_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
;
    shl ebp,9

wdRetry:
    push es
    mov es,fs:disc_bulk_out_buf    
    mov es:disc_cbw_tag,edx
    mov es:disc_cbw_transfer_len,ebp
    mov es:disc_cbw_flags,0
    mov es:disc_cbw_cmd_len,10
    mov es:disc_cbw_cmd_data,2Ah
    mov es:disc_cbw_cmd_data+1,0
;    
    mov eax,edx
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov dword ptr es:disc_cbw_cmd_data+2,eax
;
    mov es:disc_cbw_cmd_data+6,0
;
    shr ebp,9
    mov ax,bp
    xchg al,ah    
    mov word ptr es:disc_cbw_cmd_data+7,ax
    mov es:disc_cbw_cmd_data+9,0
;
    mov eax,edx
    call SendCbw
    pop es
    jc wdFail
;    
    call WriteRaw
    jc wdFail
;    
    call ReceiveCsw
    jnc wdOk
    
wdFail:
    call ResetDevice
    jmp wdRetry

wdFailLoop:    
    mov edi,es:[esi]
    mov eax,es:[edi].dh_data
    mov es:[eax].dh_state,STATE_BAD
    mov bx,fs:disc_handle
    DiscRequestCompleted
    add esi,4
    sub ecx,1
    sub ebp,1
    jnz wdFailLoop
;    
    jmp wdNext

wdOk:
    pop ecx

wdOkLoop:
    mov edi,es:[esi]
    mov eax,es:[edi].dh_data
    mov es:[edi].dh_state,STATE_USED
    mov bx,fs:disc_handle
    DiscRequestCompleted
    add esi,4
    sub ecx,1
    sub ebp,1
    jnz wdOkLoop

wdNext:
    or ecx,ecx
    jnz wdLoop
;
    ret
write_drive     Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       perform_one
;
;       DESCRIPTION:    Perform one request
;
;       PARAMETERS:     FS      Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

perform_one     Proc near

perform_one_loop:
    mov ecx,128
    mov bx,fs:disc_handle
    GetDiscRequestArray
    jc perform_one_done
;
    mov edi,es:[esi]
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    je perform_one_read
;
    cmp al,STATE_DIRTY
    je perform_one_write
;
    cmp al,STATE_SEQ
    jne perform_one_done

perform_one_write:
    call write_drive
    jmp perform_one_loop

perform_one_read:
    call read_drive
    jmp perform_one_loop

perform_one_done:
    ret
perform_one     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Disc thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_thread:
    BeginDiscHandler
;
    xor ax,ax
    mov es,ax
;
    mov ax,SEG data
    mov ds,ax
;
    mov si,OFFSET disc_device_arr
    mov cx,MAX_DISCS

dtInsDiscLoop:
    mov ax,ds:[si]
    or ax,ax
    jz dtInsDo
;
    add si,2
    loop dtInsDiscLoop
;
    int 3
    jmp dtDelDone

dtInsDo:
    mov ds:[si],bx
;
    mov fs,bx
;
    mov bx,fs:disc_controller
    mov al,fs:disc_port
    OpenUsbDevice
    mov fs:disc_dev_handle,bx
;
    push es
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_out_pipe
    mov cx,1000h
    mov ax,500
    OpenUsbRawPipe
    mov fs:disc_bulk_out_buf,es
    pop es
;
    push es
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    mov cx,1000h
    mov ax,1500
    OpenUsbRawPipe
    mov fs:disc_bulk_in_buf,es
    pop es
;
    mov cx,32

dtRetryLoop:
    push cx
;    
    call RequestSense
    jc dtRetry
;    
    call Inquiry    
    jc dtRetry
;
    call ReadCapacity
    jnc dtOk

dtRetry:
    pop cx
    sub cx,1
    jz dtFailed
;
    call ResetDevice
;
    mov ax,100
    WaitMilliSec
    jmp dtRetryLoop

dtOk:
    pop cx
;
    mov bx,fs
    mov ecx,10000h
    InstallDynamicDisc
    mov fs:disc_nr,al
    mov fs:disc_handle,bx
;
    xor edx,edx
    mov eax,fs:disc_sectors
    mov cx,512
    SetDiscLbaParam
    mov fs:disc_sectors_per_unit,ax
;
    push es
    push cx
    push si
    push edi
;
    GetDiscVendorInfoBuf
;
    mov al,'U'
    stosb
    mov al,'S'
    stosb
    mov al,'B'
    stosb
    mov al,':'
    stosb
;
    mov cx,(16+8+4) SHR 2
    mov si,OFFSET disc_vendor_str
    rep movs dword ptr es:[di],fs:[si]    
;
    xor al,al
    stosb
;
    pop edi
    pop si
    pop cx
    pop es
;
    EndDiscHandler
;
    mov ax,flat_sel
    mov es,ax
    mov bx,fs:disc_handle

discbuf_thread_loop:
    WaitForDiscRequest
    jc dtEnd
;    
    call perform_one
    jmp discbuf_thread_loop

dtFailed:
    EndDiscHandler    
    
dtEnd: 
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    CloseUsbPipe
;
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_out_pipe
    CloseUsbPipe
;
    mov bx,fs:disc_dev_handle
    CloseUsbDevice
;
    mov al,fs:disc_nr
    ResetDisc
;
    mov bx,fs:disc_handle
    StopDisc    
;    
    mov bx,fs
    mov es,bx
    xor ax,ax
    mov fs,ax
    mov ax,SEG data
    mov ds,ax
;    
    mov si,OFFSET disc_device_arr
    mov cx,MAX_DISCS

dtDelDiscLoop:
    cmp bx,ds:[si]
    je dtDelDo
;
    add si,2
    loop dtDelDiscLoop
;
    jmp dtDelDone

dtDelDo:
    mov word ptr ds:[si],0

dtDelDone:
    mov es,bx
    FreeMem        
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
;   NAME:           usb_attach
;
;   description:    USB attach callback
;
;   Parameters:     BX      Controller #
;                   AL      Port #
;                   DS      USB device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_name    DB 'Usb Disc ', 0

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
    jne uaFail
;
    mov cx,es:udd_vendor
    push cx
    mov cx,es:udd_prod
    push cx
    movzx cx,es:udd_num
    push cx
;    
    mov cl,es:udd_class
    or cl,cl
    je uaPossible
;    
    cmp cl,8
    jne uaFailPop

uaPossible:
    xor dl,dl
    mov cx,1000h
    xor di,di
    push ax
    GetUsbConfig
    mov cx,ax
    pop ax
    or cx,cx
    jz uaFailPop
;
    mov dl,es:ucd_config_id
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

uaCheckLoop:
    mov cl,es:[di].ucd_type
    cmp cl,4
    jne uaCheckNext
;    
    mov cl,es:[di].uid_class
    cmp cl,8
    je uaFound

uaCheckNext:
    movzx cx,es:[di].ucd_len
    or cx,cx
    jz uaFailPop
;    
    add di,cx
    cmp di,es:ucd_size
    jb uaCheckLoop

uaFailPop:
    pop cx    
    pop cx    
    pop cx    

uaFail:
    FreeMem    
    jmp uaDone

uaFound:
    mov cl,es:[di].uid_sub_class
    cmp cl,6
    jne uaFail
;
    mov cl,es:[di].uid_proto
    cmp cl,50h
    jne uaFail
;        
    push ax
    ConfigUsbDevice
    pop ax
;
    push es
    push eax
    mov eax,SIZE disc_struc
    AllocateSmallGlobalMem
    pop eax
    mov es:disc_controller,bx
    mov es:disc_port,al
    mov ax,es
    mov gs,ax
    pop es
;
    pop cx
    mov gs:disc_serial,cl
;
    pop cx
    mov gs:disc_prod,cx
;
    pop cx
    mov gs:disc_vendor,cx
;        
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

uaDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne uaDescrNext
;
    mov cl,es:[di].ued_address
    test cl,80h    
    jnz uaBulkIn

uaDescrBulkOut:
    and cl,0Fh
    mov gs:disc_bulk_out_pipe,cl
    mov bx,es:[di].ued_maxsize
    mov gs:disc_bulk_out_maxsize,bx
    jmp uaDescrNext

uaBulkIn:
    and cl,8Fh
    mov gs:disc_bulk_in_pipe,cl
    mov bx,es:[di].ued_maxsize
    mov gs:disc_bulk_in_maxsize,bx
    
uaDescrNext:    
    movzx cx,es:[di].ucd_len
    or cx,cx
    jz uaDescrDone
;
    add di,cx
    cmp di,es:ucd_size
    jb uaDescrLoop    

uaDescrDone:
    xor di,di
    mov si,OFFSET disc_name

uaCopyDev:
    mov al,cs:[si]
    inc si
    or al,al
    jz uaCopyDone
;
    stosb
    jmp uaCopyDev

uaCopyDone:
    mov ax,gs:disc_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,gs:disc_port
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;    
    mov bx,gs
    xor di,di
;    
    mov dx,cs
    mov ds,dx
    mov esi,OFFSET disc_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    FreeMem

uaDone:    
    popad
    pop es
    pop ds
    retf32
usb_attach  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           usb_detach
;
;   description:    USB detach callback
;
;   Parameters:     BX      Controller #
;                   AL      Port #
;                   DS      USB device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    push gs
    pushad
;
    mov dx,SEG data
    mov ds,dx
    mov si,OFFSET disc_device_arr
    mov cx,MAX_DISCS

udCheckLoop:
    mov dx,[si]
    or dx,dx
    jz udCheckNext
;
    mov es,dx
    cmp bx,es:disc_controller
    jne udCheckNext
;
    cmp al,es:disc_port
    jne udCheckNext
;
    mov bx,es:disc_handle
    StopDiscRequest

udCheckNext:
    add si,2    
    sub cx,1
    jnz udCheckLoop
    
udDone:    
    popad
    pop gs
    pop es
    pop ds
    retf32
usb_detach  Endp

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
    mov ds,bx
    mov cx,MAX_DISCS
    mov si,OFFSET disc_device_arr
    xor ax,ax

iArrLoop:
    mov ds:[si],ax
    add si,2
    loop iArrLoop   
;       
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET usb_attach
    HookUsbAttach
;
    mov edi,OFFSET usb_detach
    HookUsbDetach
    clc
    ret
init    Endp

code    ENDS

    END init
