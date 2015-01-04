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

DiscBase    = 700h
TimerTics   = 46Ch

KeyHead     = 1Ah
KeyTail     = 1Ch
KeyBuf      = 1Eh

_TEXT segment byte public use16 'code'

.386

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           int8
;
;           DESCRIPTION:    PIT interrupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int8:
    push ds
    push ax
    push bx
;    
    xor ax,ax
    mov ds,ax
    mov bx,TimerTics
    add word ptr ds:[bx],1
    adc word ptr ds:[bx+2],0
    mov al,20h
    out 20h,al
;    
    pop bx
    pop ax
    pop ds
    iret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPic
;
;           DESCRIPTION:    Init interrupt controller
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPic     Proc near
    mov dx,20h
    mov al,11h
    out dx,al
;
    mov dx,0A0h
    mov al,11h
    out dx,al
;
    mov dx,21h
    mov al,8
    out dx,al
;
    mov dx,0A1h
    mov al,70h
    out dx,al
;
    mov dx,21h
    mov al,4
    out dx,al
;
    mov dx,0A1h
    mov al,2
    out dx,al
;
    mov al,1
    mov dx,21h
    out dx,al
    mov dx,0A1h
    out dx,al
;
    mov al,0FFh
    mov dx,21h
    out dx,al
    mov dx,0A1h
    out dx,al
;
    sti    
    ret
InitPic     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPit
;
;           DESCRIPTION:    Init interval timer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPit     Proc near
    mov dx,43h
    mov al,36h
    out dx,al
    mov al,0FFh
    mov dx,40h
    out dx,al
    out dx,al
;    
    mov bx,8 SHL 2
    mov word ptr ds:[bx],OFFSET int8
    mov ds:[bx+2],cs
;
    mov dx,21h
    in al,dx
    and al,NOT 1
    out dx,al
    ret
InitPit     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           int9
;
;           DESCRIPTION:    Keyboard interrupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int9:
    int 3
    push ds
    push ax
    push bx
;    
    mov ax,40h
    mov ds,ax
    in al,60h
;    
    mov bx,ds:KeyTail
    inc bx
;    
    cmp bx,KeyBuf + 32
    jne i9SavePtr
;
    mov bx,KeyBuf

i9SavePtr:    
    cmp bx,ds:KeyHead
    je i9Eoi
;    
    xchg bx,ds:KeyTail
    mov ds:[bx],al

i9Eoi:
    mov al,20h
    out 20h,al
;
    pop bx
    pop ax
    pop ds    
    iret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitKeyboard
;
;           DESCRIPTION:    Init keyboard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitKeyboard    Proc near
    mov ax,40h
    mov es,ax
    mov ax,KeyBuf
    mov es:KeyHead,ax
    mov es:KeyTail,ax
;    
    mov bx,9 SHL 2
    mov word ptr ds:[bx],OFFSET int9
    mov ds:[bx+2],cs
;    
    mov dx,21h
    in al,dx
    and al,NOT 2
    out dx,al
;
    mov dx,64h
    mov al,0AAh
    out dx,al
;
    mov cx,256

ikWait:
    mov bx,es:KeyHead
    cmp bx,es:KeyTail
    jne ikEnable
;
    loop ikWait

ikEnable:
    mov al,0AEh
    out dx,al    
;
    mov ax,KeyBuf
    mov es:KeyHead,ax
    mov es:KeyTail,ax    
    ret
InitKeyboard    Endp

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckDiscReady
;
;       DESCRIPTION:    Wait for ready
;
;       PARAMETERS:     DX      Io base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckDiscReady      PROC near
    push ax
    push cx
    push dx
;
    add dx,7
    mov cx,10000

CheckDiscBusyLoop:
    in al,dx
    test al,80h
    clc
    jz CheckDiscReadyDone
;       
    loop CheckDiscBusyLoop
    
    stc
    
CheckDiscReadyDone:
    pop dx
    pop cx
    pop ax
    ret
CheckDiscReady      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitDiscReady
;
;       DESCRIPTION:    Wait for DRDY signal
;
;       PARAMETERS:     DX      Io base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitDiscReady       PROC near
    push ax
    push cx
    push dx
;
    add dx,7
    mov cx,10000

WaitDiscReadyLoop:
    in al,dx
    test al,40h
    clc
    jnz WaitDiscReadyDone
;       
    loop WaitDiscReadyLoop
    
    stc
    
WaitDiscReadyDone:
    pop dx
    pop cx
    pop ax
    ret
WaitDiscReady       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckDiscStatus
;
;       DESCRIPTION:    Check transfer status
;
;       PARAMETERS:     DX      Disc io base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckDiscStatus     Proc near
    push ax
    push dx
;
    add dx,7
    in al,dx
    test al,80h
    jnz CheckDiscStatusFail
;    
    test al,20h
    jnz CheckDiscStatusFail

    test al,40h
    jz CheckDiscStatusFail
;
    test al,10h
    jz CheckDiscStatusFail
;
    test al,1
    clc
    jz CheckDiscStatusDone
;
    sub dx,6
    in al,dx
    
CheckDiscStatusFail:
    stc

CheckDiscStatusDone:
    pop dx
    pop ax
    ret
CheckDiscStatus     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupDisc
;
;       DESCRIPTION:    Setup LBA comp. task file
;
;       PARAMETERS:     CX      Number of sectors
;                       EDX     Sector #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupDisc    Proc near
    push ax
    push bx
    push dx
;
    push dx
    mov dx,ds:DiscBase
    add dx,7
    in al,dx
    clc
    test al,80h
    jz SetupDiscNotBusy
;
    sub dx,7
    call CheckDiscReady

SetupDiscNotBusy:    
    pop dx
    jc SetupDiscDone
;
    push edx
    mov dx,ds:DiscBase
    inc dx
;
    mov al,ah
    out dx,al
    inc dx
;
    mov al,cl
    out dx,al
    inc dx
;
    pop ax
    out dx,al
    inc dx
;
    mov al,ah
    out dx,al
    inc dx
;
    pop ax
    out dx,al
    inc dx
;
    mov bl,ah
    xor al,al
    shl al,4
    or al,bl
    or al,0E0h
    out dx,al
;
    mov dx,ds:DiscBase
    add dx,7
    in al,dx
    test al,40h
    clc
    jnz SetupDiscDone
;
    sub dx,7
    call WaitDiscReady
    
SetupDiscDone:
    pop dx
    pop bx
    pop ax
    ret
SetupDisc    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadDisc
;
;       DESCRIPTION:    Read data from device
;
;       PARAMETERS:     AL      Command code
;                       CX      Number of sectors
;                       ES:BX   Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadDisc    Proc near
    push cx
    push dx
    push di
;
    mov di,bx
    mov dx,ds:DiscBase
    add dx,7
    out dx,al
    sub dx,7
    
ReadDiscLoop:
    push cx
    mov cx,256
    rep ins word ptr es:[di],dx
    pop cx
;    
    call CheckDiscStatus
    jc ReadDiscDone
;
    loop ReadDiscLoop
;
    clc
    
ReadDiscDone:
    pop di
    pop dx
    pop cx
    ret
ReadDisc    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadSector
;
;           DESCRIPTION:    Read a sector
;
;           PARAMETERS:     EDX         Sector #
;                           ES:BX       Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector  Proc near
    push ds
    push ax
    push cx
;
    xor ax,ax
    mov ds,ax
;        
    mov cx,1
    call SetupDisc
    jc rsDone
;
    mov al,20h
    call ReadDisc

rsDone:    
    pop cx
    pop ax
    pop ds
    ret
ReadSector  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           int 13
;
;           DESCRIPTION:    Disc int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int13:
    push bp
    mov bp,sp
;    
    cmp ah,2
    jne i13NotRead
;
    cmp dl,80h
    jne i13Fail
;    
    or dh,dh
    jnz i13Fail
;
    push edx
;
    movzx edx,cx
    dec dx
    call ReadSector
;    
    pop edx
    jmp i13Ok    

i13NotRead:
    cmp ah,42h
    jne i13Fail
;
    push es
    push bx
    push cx
    push edx
;
    les bx,ds:[si+4]
    mov edx,ds:[si+8]
    mov cx,ds:[si+2]
    or cx,cx
    jz i13ExtReadOk

i13ExtReadLoop:
    call ReadSector
    inc edx
    add bx,200h
    loop i13ExtReadLoop    

i13ExtReadOk:
    pop edx
    pop cx
    pop bx
    pop es
    jmp i13Ok

i13Fail:
    int 3
    or byte ptr [bp+6],1
    jmp i13Done

i13Ok:    
    and byte ptr [bp+6],NOT 1

i13Done:
    pop bp
    iret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           int 15
;
;           DESCRIPTION:    BIOS int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int15:
    push bp
    mov bp,sp
;
    cmp ax,0E820h
    jne i15Fail
;
    cmp edx,534D4150h
    jne i15Fail
;
    or ebx,ebx
    jnz i15HiMem

i15LowMem:
    mov ebx,1
    xor eax,eax
    mov es:[di],eax
    mov es:[di+4],eax
    mov es:[di+12],eax
    mov eax,0A0000h
    mov es:[di+8],eax
    mov eax,1
    mov es:[di+16],eax
    mov eax,edx
    jmp i15Ok

i15HiMem:
    xor ebx,ebx
    xor eax,eax
    mov es:[di+4],eax
    mov es:[di+12],eax
    mov eax,100000h
    mov es:[di],eax
    mov eax,700000h
    mov es:[di+8],eax
    mov eax,1
    mov es:[di+16],eax
    mov eax,edx
    jmp i15Ok

i15Fail:
    int 3
    or byte ptr [bp+6],1
    jmp i13Done

i15Ok:    
    and byte ptr [bp+6],NOT 1
;
    pop bp
    iret    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           int 16
;
;           DESCRIPTION:    keyboard int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int16:
    int 3
    push bp
    mov bp,sp
;
    pop bp
    iret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           start
;
;           DESCRIPTION:    Startup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            
start:
    xor eax,eax
    xor ebx,ebx
    xor ecx,ecx
    xor edx,edx
    xor esi,esi
    xor edi,edi
    xor ebp,ebp
;    
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,7000h
;
    call InitPic    
    call InitPit
    call InitKeyboard
;
    sti

stl:
    hlt
    jmp stl    
;
    mov bx,15h SHL 2
    mov word ptr ds:[bx],OFFSET int15
    mov ds:[bx+2],cs
;
    mov bx,16h SHL 2
    mov word ptr ds:[bx],OFFSET int16
    mov ds:[bx+2],cs
;    
    mov bx,101h
    call FindPciClass
    jc disc_done
;
    mov cl,10h
    call ReadPciDword
    test al,1
    jz disc_done
;
    and al,0FCh
    mov ds:DiscBase,ax    
;
    mov bx,13h SHL 2
    mov word ptr ds:[bx],OFFSET int13
    mov ds:[bx+2],cs
;
    mov ax,201h
    mov cx,1
    xor dh,dh
    mov dl,80h
    mov bx,7C00h
    int 13h
;    
    mov ax,es:[bx+1FEh]
    cmp ax,0AA55h
    jne disc_done
;    
    db 0EAh
    dw 7C00h
    dw 0
            
disc_done:    

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
    
    
