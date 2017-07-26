;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2017, Leif Ekblad
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

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

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
    stc
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
    stc
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
    stc
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
    stc
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
    pushad
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
    pop ds
    ret
init_ser_io ENDP

code    ENDS

.186

END
