;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; VIDEO.ASM
; Emulated video BIOS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

CursorPos   = 450H

_TEXT segment byte public use16 'code'

.386

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           int 10
;
;           DESCRIPTION:    Video int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int10:
    push ds
    push ax
    push bx
    push cx
    push dx
;
    xor cx,cx
    mov ds,cx
;        
    cmp ah,0Eh
    jne i10Done
;
    mov cx,ds:CursorPos
    cmp al,0Dh
    jne i10NotCr
;    
    inc ch
    mov ds:CursorPos,cx
    jmp i10Done

i10NotCr:
    cmp al,0Ah    
    jne i10NotLf
;
    xor cl,cl
    mov ds:CursorPos,cx
    jmp i10Done

i10NotLf:   
    mov ah,bl
    inc word ptr ds:CursorPos
;    
    push ax
    mov al,ch
    mov dl,80
    mul dl
    add al,cl
    adc ah,0
    shl ax,1
    mov bx,ax
    pop ax
    mov cx,0B800h
    mov ds,cx
    mov ds:[bx],ax
    
i10Done:  
    pop dx 
    pop cx 
    pop bx
    pop ax
    pop ds
    iret

_TEXT    ENDS

    END 
    
    
