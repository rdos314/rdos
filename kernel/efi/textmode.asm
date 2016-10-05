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
; TEXTMODE.ASM
; Textmode device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE video.inc

    .386p

code    SEGMENT byte public 'CODE'

    assume cs:code
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           write_text_char
;
;           DESCRIPTION:    Write text char
;
;           PARAMETERS:     DS    Video sel
;                           AL    Char
;                           BL    Fore color
;                           BH    Back color
;                           CX    Col
;                           DX    Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_text_char     PROC far
    push es
    push ax
    push dx
    push di
;
    push ax
    mov ax,dosB800
    mov es,ax    
    mov ax,80
    mul dx
    add ax,cx
    mov di,ax
    add di,di
    pop ax    
;
    mov ah,bh
    shl ah,4
    or ah,bl
    mov es:[di],ax
;
    pop di
    pop dx
    pop ax
    pop es            
    ret
write_text_char Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           toggle_marer
;
;           DESCRIPTION:    Invert marker
;
;           PARAMETERS:     DS          Video sel
;                           CX          COL (x)
;                           DX          ROW (y)
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_marker    PROC far
   ret
toggle_marker   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           update_cursor_pos
;
;           DESCRIPTION:    Update cursor position
;
;           PARAMETERS:     DS          Video sel
;                           CX          COL (x)
;                           DX          ROW (y)
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_cursor_pos    PROC far
    pusha
;
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz ucpbDone
;
    mov ax,80
    mul dx
    add ax,cx
    mov bx,ax
;
    mov dx,3D4h
;
    mov al,0Eh
    out dx,al
;
    inc dx
    mov al,bh
    out dx,al
;
    dec dx
    mov al,0Fh
    out dx,al
;
    inc dx
    mov al,bl
    out dx,al

ucpbDone:
    popa 
    ret
update_cursor_pos        Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   Mdoe table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

errorp  Proc far
    ret
errorp  Endp

    public TextModeTab

TextModeTab:
mt00 DD OFFSET errorp,             SEG code
mt01 DD OFFSET errorp,             SEG code
mt02 DD OFFSET errorp,             SEG code
mt03 DD OFFSET errorp,             SEG code
mt04 DD OFFSET errorp,             SEG code
mt05 DD OFFSET errorp,             SEG code
mt06 DD OFFSET errorp,             SEG code
mt07 DD OFFSET errorp,             SEG code
mt08 DD OFFSET errorp,             SEG code
mt09 DD OFFSET errorp,             SEG code
mt0A DD OFFSET errorp,             SEG code
mt0B DD OFFSET errorp,             SEG code
mt0C DD OFFSET errorp,             SEG code
mt0D DD OFFSET errorp,             SEG code
mt0E DD OFFSET errorp,             SEG code
mt0F DD OFFSET errorp,             SEG code
mt10 DD OFFSET errorp,             SEG code
mt11 DD OFFSET errorp,             SEG code
mt12 DD OFFSET errorp,             SEG code
mt13 DD OFFSET errorp,             SEG code
mt14 DD OFFSET errorp,             SEG code
mt15 DD OFFSET errorp,             SEG code
mt16 DD OFFSET errorp,             SEG code
mt17 DD OFFSET errorp,             SEG code
mt18 DD OFFSET errorp,             SEG code
mt19 DD OFFSET errorp,             SEG code
mt1A DD OFFSET write_text_char,    SEG code
mt1B DD OFFSET toggle_marker,      SEG code
mt1C DD OFFSET update_cursor_pos,  SEG code

code    ENDS

    END

