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
; GPTBOOT.ASM
; Bootsector for disk / diskette
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

BootSectInit:
    jmp StartBoot
    nop

    db 'Rdos    '

BootMedia       boot_struc      <>

StartBoot:
    db 0EAh
    dw OFFSET JmpBootCode
    dw 07C0h

JmpBootCode:
    mov cs:BootMedia.boot_drive_nr,dl
    cli
    mov bx,5000h
    mov ss,bx
    mov sp,100h
    sti
    mov bx,7000h
    mov es,bx
    xor bx,bx
    mov ecx,20h
    xor dx,dx
    mov ax,22h
LoadBootNext:
    push cx
    mov cx,3
LoadBootRetry:
    call ReadSector
    jnc BootSectorOk
    push ax
    mov ax,0
    int 13h
    pop ax
    loop LoadBootRetry      
    stc
BootSectorOk:
    pop cx
    jc BootFail
    add ax,1
    adc dx,0
    add bx,512
    loop LoadBootNext
;
    mov dl,cs:BootMedia.boot_drive_nr
    mov ax,cs
    mov es,ax
    mov al,cs:BootMedia.boot_default_entry
    
    db 0EAh

    public BootLoadOffset

BootLoadOffset:

    dw 0
    dw 7000h

BootFail:
    mov si,OFFSET DiskError
    call WriteAsciiz
BootStop:
    jmp BootStop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteAsciiz
;
;           DESCRIPTION:    Write a message
;
;           PARAMETERS:         CS:SI   Message to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteAsciiz     Proc near
    lods byte ptr cs:[si]
    or al,al
    jz WriteAsciizDone
    mov ah,0Eh
    mov bx,7
    int 10h
    jmp WriteAsciiz
WriteAsciizDone:
    ret
WriteAsciiz     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadSector
;
;           DESCRIPTION:    Read a sector
;
;           PARAMETERS:         DX:AX   Sector #
;                           ES:BX   Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector      Proc near
    push ax
    push cx
    push dx
    push bx
    div cs:BootMedia.boot_sectors_per_cyl
    inc dl
    mov bl,dl
    xor dx,dx
    div cs:BootMedia.boot_heads
    mov bh,dl
    mov dx,ax
    mov ax,201h
    mov cl,6
    shl dh,cl
    or dh,bl
    mov cx,dx
    xchg ch,cl
    mov dl,cs:BootMedia.boot_drive_nr
    and dl,80h
    mov dh,bh
    pop bx
    int 13h
    pop dx
    pop cx
    pop ax
    ret
ReadSector      Endp

DiskError:
        db 'Diskette error',0Dh,0Ah,0

Pad     db 263 dup(0)
        db 55h
        db 0AAh

_TEXT    ENDS

    END BootSectInit
    
