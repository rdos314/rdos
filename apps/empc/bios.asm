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
; BIOS.ASM
; Emulated BIOS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

boot_struc      STRUC

boot_bytes_per_sector       DW 512
boot_default_entry          DB 0
boot_mapping_sectors        DW 1
boot_resv3                  DB ?
boot_resv4                  DW ?
boot_small_sectors          DW 2884
boot_media                  DB ?
boot_resv6                  DW ?
boot_sectors_per_cyl        DW 15
boot_heads                  DW 2
boot_hidden_sectors         DD 16
boot_sectors                DD 2884
boot_drive_nr               DB 0,0
boot_signature              DB ?
boot_serial                 DD ?
boot_volume                 DB 11 DUP(?)
boot_fs                     DB 8 DUP(?)

boot_struc          ENDS

_TEXT segment byte public use16 'code'

.386

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPciByte
;
;           DESCRIPTION:    Read a 8-bit register
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          Register
;
;           RETURNS:        AL          Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPciByte   Proc near
    push bx
    push cx
    push dx
;    
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    mov al,cl
;
    and al,0FCh
    mov dx,0CF8h
    out dx,eax
    mov dx,0CFCh
    and cl,3
    or dl,cl
    in al,dx
;
    pop dx
    pop cx
    pop bx
    ret
ReadPciByte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePciByte
;
;           DESCRIPTION:    Write a 8-bit register
;
;           PARAMETERS:     AL          Data
;                           BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePciByte  Proc near
    push ax
    push bx
    push cx
    push dx
;
    push ax
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    mov al,cl
;
    and al,0FCh
    mov dx,0CF8h
    out dx,eax
    mov dx,0CFCh
    and cl,3
    or dl,cl
    pop ax
    out dx,al
;
    pop dx
    pop cx
    pop bx
    pop ax
    ret
WritePciByte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPciWord
;
;           DESCRIPTION:    Read a 16-bit register
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          Register
;
;           RETURNS:        AX          Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPciWord   Proc near
    push bx
    push cx
    push dx
;
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    mov al,cl
;
    and al,0FCh
    mov dx,0CF8h
    out dx,eax
    mov dx,0CFCh
    and cl,2
    or dl,cl
    in ax,dx
;
    pop dx
    pop cx
    pop bx
    ret
ReadPciWord   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePciWord
;
;           DESCRIPTION:    Write a 16-bit register
;
;           PARAMETERS:     AX          Data
;                           BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePciWord  Proc near
    push ax
    push bx
    push cx
    push dx
;
    push ax
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    mov al,cl
;
    mov dx,0CF8h
    and al,0FCh
    out dx,eax
    mov dx,0CFCh
    and cl,2
    or dl,cl
    pop ax
    out dx,ax
;
    pop dx
    pop cx
    pop bx
    pop ax
    ret
WritePciWord  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPciDword
;
;           DESCRIPTION:    Read a 32-bit register
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          Register
;
;           RETURNS:        EAX         Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPciDword  Proc near
    push bx
    push cx
    push dx
;
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    mov al,cl
;
    mov dx,0CF8h
    out dx,eax
    mov dx,0CFCh
    in eax,dx
;
    pop dx
    pop cx
    pop bx
    ret
ReadPciDword  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePciDword
;
;           DESCRIPTION:    Write a 32-bit register
;
;           PARAMETERS:     EAX         Data
;                           BH          Bus
;                           BL          Device
;                           CH          Function
;                           CL          Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePciDword Proc near
    push ax
    push bx
    push cx
    push dx
;
    push eax
    mov al,bh
    mov ah,80h
    shl eax,16
    mov ah,bl
    shl ah,3
    or ah,ch
    mov al,cl
;
    mov dx,0CF8h
    out dx,eax
    mov dx,0CFCh
    pop eax
    out dx,eax
;
    pop dx
    pop cx
    pop bx
    pop ax
    ret
WritePciDword Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindPciClass
;
;           DESCRIPTION:    Find PCI class
;
;           PARAMETERS:     BH          Class
;                           BL          Sub class
;
;           RETURNS:        NC          Success
;                           BH          Bus
;                           BL          Device
;                           CH          Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindPciClass      Proc near
    push ax
    push dx
    push si
;
    mov si,bx
    xor bx,bx
    mov cx,8

fpcLoop:
    call ReadPciDword
;    
    shr eax,16
    cmp ax,si
    jne fpcNext
;
    clc
    jmp fpcDone

fpcNext:
    inc bl
    cmp bl,32
    jne fpcLoop
;
    stc
    jmp fpcDone

fpcDone:
    pop si
    pop dx
    pop ax
    ret
FindPciClass      Endp

start:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,7000h
    mov bx,101h
    mov cx,8
    call FindPciClass
    int 3

    org 0FFF0h

init:
    db 0EAh
    dw OFFSET start
    dw 0F000h    

    db 0FFh
    dw 0FFFFh
    dw 4 DUP(0FFFFh)

_TEXT    ENDS

    END 
    
    
