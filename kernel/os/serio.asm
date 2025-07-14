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
; SERIO.ASM
; Serial I/O module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE serio.inc
    
data    SEGMENT byte public 'DATA'

dev_arr DW 256 DUP (?)

data  ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddSerIoDevice
;
;       DESCRIPTION:    Add serial IO device
;
;       PARAMETERS:     ES              Ser IO sel
;                       DH              Device #
;               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_ser_io_device_name    DB 'Add Serial IO Device',0

add_ser_io_device Proc far
    push ds
    push es
    pushad
;    
    mov ax,SEG data
    mov ds,ax
    movzx bx,dh
    add bx,bx
    mov ax,ds:[bx].dev_arr
    or ax,ax
    jz asiSave
;
    push es
    mov es,ax
    FreeMem
    pop es

asiSave:
    mov ds:[bx].dev_arr,es
;
    popad
    pop es
    pop ds    
    retf32
add_ser_io_device Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;     NAME:           ToggleSerialLine
;
;     DESCRIPTION:    Toggle serial input line
;
;     PARAMETERS:     DL              Line #
;                     DH              Device #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_serial_line_name DB 'Toggle Serial Line', 0

toggle_serial_line      Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,dh
    add bx,bx
    mov bx,ds:[bx].dev_arr
    or bx,bx
    jz tslFail
;
    mov ds,bx
    call fword ptr ds:siot_toggle_proc
    jmp tslDone

tslFail:    
    stc

tslDone:
    pop ebx
    pop ds
    retf32
toggle_serial_line  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;     NAME:           ResetSerialLine
;
;     DESCRIPTION:    Reset serial input line
;
;     PARAMETERS:     DL              Line #
;                     DH              Device #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_serial_line_name DB 'Reset Serial Line', 0

reset_serial_line      Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,dh
    add bx,bx
    mov bx,ds:[bx].dev_arr
    or bx,bx
    jz rslFail
;
    mov ds,bx
    call fword ptr ds:siot_reset_proc
    jmp rslDone

rslFail:    
    stc

rslDone:
    pop ebx
    pop ds
    retf32
reset_serial_line  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;     NAME:           SetSerialLine
;
;     DESCRIPTION:    Set serial input line
;
;     PARAMETERS:     DL              Line #
;                     DH              Device #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_serial_line_name DB 'Set Serial Line', 0

set_serial_line      Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,dh
    add bx,bx
    mov bx,ds:[bx].dev_arr
    or bx,bx
    jz sslFail
;
    mov ds,bx
    call fword ptr ds:siot_set_proc
    jmp sslDone

sslFail:    
    stc

sslDone:
    pop ebx
    pop ds
    retf32
set_serial_line  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;     NAME:           ReadSerialLines
;
;     DESCRIPTION:    Read serial lines
;
;     PARAMETERS:     DH              Device #
;
;     RETURNS:        AL              State
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_serial_lines_name  DB 'Read Serial Lines', 0

read_serial_lines       Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,dh
    add bx,bx
    mov bx,ds:[bx].dev_arr
    or bx,bx
    jz gslFail
;
    mov ds,bx
    call fword ptr ds:siot_get_proc
    jmp gslDone

gslFail:    
    stc

gslDone:
    pop ebx
    pop ds
    retf32
read_serial_lines       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;     NAME:           WriteSerialVal
;
;     DESCRIPTION:    Write serial value
;
;     PARAMETERS:     DL              Line #
;                     DH              Device #
;                     EAX             Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_serial_val_name   DB 'Write Serial Value', 0

write_serial_val        Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,dh
    add bx,bx
    mov bx,ds:[bx].dev_arr
    or bx,bx
    jz wvslFail
;
    mov ds,bx
    call fword ptr ds:siot_write_proc
    jmp wvslDone

wvslFail:    
    stc

wvslDone:
    pop ebx
    pop ds
    retf32
write_serial_val        Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;     NAME:           ReadSerialVal
;
;     DESCRIPTION:    Read serial val
;
;     PARAMETERS:     DL              Line #
;                     DH              Device #
;
;     RETURNS:        EAX             Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_serial_val_name    DB 'Read Serial Value', 0

read_serial_val Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,dh
    add bx,bx
    mov bx,ds:[bx].dev_arr
    or bx,bx
    jz rvslFail
;
    mov ds,bx
    call fword ptr ds:siot_read_proc
    jmp rvslDone

rvslFail:    
    stc

rvslDone:
    pop ebx
    pop ds
    retf32
read_serial_val Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_SER_IO
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_ser_io

init_ser_io PROC near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov es,ax
    mov edi,OFFSET dev_arr
    mov ecx,256
    xor ax,ax
    rep stosw
;
    mov ax,cs
    mov ds,ax
    mov es,ax    
;
    mov esi,OFFSET add_ser_io_device
    mov edi,OFFSET add_ser_io_device_name
    mov ax,add_serio_device_nr
    RegisterOsGate
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
    mov esi,OFFSET reset_serial_line
    mov edi,OFFSET reset_serial_line_name
    mov ax,reset_serial_line_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_serial_line
    mov edi,OFFSET set_serial_line_name
    mov ax,set_serial_line_nr
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
;
    popad
    pop es
    pop ds
    ret
init_ser_io ENDP

code    ENDS

.186

END
