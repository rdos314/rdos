;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2012, Leif Ekblad
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
; TYPEBASE.ASM
; Basic freetype support functions not available from RDOS device-driver interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def
INCLUDE ..\..\kernel\os\proc.inc

    .386p

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

    extrn InstallFont:far

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           load_adapter_fonts
;
;           DESCRIPTION:    install all fonts in adapter
;
;           PARAMETERS:         edx         base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_adapter_fonts      Proc near
    push ds
    push ax
    push bx
    push edx
;    
    mov ax,flat_sel
    mov ds,ax

load_adapter_fonts_loop:
    mov ax,[edx].typ
    cmp ax,RdosFont
    jne not_install_font
;
    push ds
    push es
    push ecx
    mov ecx,[edx].len
    mov ax,ds
    mov es,ax
    mov edi,edx
    add edi,SIZE rdos_header
    sub ecx,SIZE rdos_header
    call InstallFont
    pop ecx
    pop es
    pop ds
    jmp load_adapter_fonts_next

not_install_font:
    cmp ax,RdosEnd
    je load_adapter_fonts_done

load_adapter_fonts_next:
    add edx,[edx].len
    jmp load_adapter_fonts_loop

load_adapter_fonts_done:
    pop edx
    pop bx
    pop ax
    pop ds
    ret
load_adapter_fonts      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitFonts
;
;           DESCRIPTION:    Initialize freetype fonts
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitFonts_

InitFonts_    Proc near
    push ds
    push es
    pushad
;
    mov ax,system_data_sel
    mov ds,ax
    movzx ecx,ds:rom_modules
    mov bx,OFFSET rom_adapters

init_font_loop:
    mov edx,[bx].adapter_base
    call load_adapter_fonts
    add bx,SIZE adapter_typ
    loop init_font_loop     
;    
    popad
    pop es
    pop ds
    ret
InitFonts_    Endp

_TEXT    ENDS

    END
