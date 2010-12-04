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
; PIC.ASM
; Legacy PIC module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\os\port.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\int.def
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\irq.inc
        
    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

irqmac  MACRO nr

irq&nr:
    push bp
    mov bp,sp
    push ds
    push es
    push fs
    pushad
;

    EnterInt
    sti
;       
    mov ax,irq_sys_sel
    mov es,ax
    mov bx,OFFSET irq_arr + nr * SIZE irq_struc
    mov eax,es:[bx].user_handler
    or eax,eax
    jz irq_default_error&nr
;
    mov ds,es:[bx].user_data
    push cs
    push OFFSET irq_handle_done&nr
    push es:[bx].user_handler
    xor ax,ax
    mov es,ax
    retf

irq_default_error&nr:
IF nr GT 7
    in al,INT1_MASK
    or al,1 SHL (nr-8)
    out INT1_MASK,al
ELSE
    in al,INT0_MASK
    or al,1 SHL nr
    out INT0_MASK,al
ENDIF
    or es:bad_irqs, 1 SHL nr

irq_handle_done&nr:
    cli
IF nr GT 7
    mov al,62h
    out INT0_CONTROL,al
    jmp short $+2
    mov al,60h + nr - 8
    out INT1_CONTROL,al
ELSE
    mov al,60h + nr
    out INT0_CONTROL,al
ENDIF       
    LeaveInt
irq_unmask_done&nr:
    popad
    pop fs
    pop es
    pop ds
    pop bp
    iretd

    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IN_CONTROL0
;
;           DESCRIPTION:    Virtualize PIC0 control port
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

in_control0     PROC far
    in al,20h
    ret
in_control0     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OUT_CONTROL0
;
;           DESCRIPTION:    Virtualize PIC0 control port
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

out_control0    PROC far
    cmp al,20h
    jne out_control0_done
    out dx,al
out_control0_done:
    ret
out_control0    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IN_MASK0
;
;           DESCRIPTION:    Virtualize PIC0 mask
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

in_mask0    PROC far
    mov bx,irq_proc_sel
    mov ds,bx
    mov al,ds:mask0
    ret
in_mask0    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OUT_MASK0
;
;           DESCRIPTION:    Virtualize PIC0 mask
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

out_mask0       PROC far
    mov bx,irq_proc_sel
    mov ds,bx
    push ax
    mov ah,al
    in al,21h
    and al,ah
    out 21h,al
    pop ax
    mov ds:mask0,al
    ret
out_mask0       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IN_CONTROL1
;
;           DESCRIPTION:    Virtualize PIC1 control port
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

in_control1     PROC far
    in al,0A0h
    ret
in_control1     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OUT_CONTROL1
;
;           DESCRIPTION:    Virtualize PIC1 control port
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

out_control1    PROC far
    cmp al,20h
    jne out_control1_done
    out dx,al
out_control1_done:
    ret
out_control1    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IN_MASK1
;
;           DESCRIPTION:    Virtualize PIC1 mask
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

in_mask1    PROC far
    mov bx,irq_proc_sel
    mov ds,bx
    mov al,ds:mask1
    ret
in_mask1    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OUT_MASK1
;
;           DESCRIPTION:    Virtualize PIC1 mask
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

out_mask1       PROC far
    mov bx,irq_proc_sel
    mov ds,bx
    push ax
    mov ah,al
    in al,0A1h
    and al,ah
    out 0A1h,al
    pop ax
    mov ds:mask1,al
    ret
out_mask1       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_PROCESS
;
;           DESCRIPTION:    Initialize per-process data
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process    PROC far
    push ds
    push ax
    mov ax,irq_proc_sel
    mov ds,ax
    mov ds:mask0,0FFh
    mov ds:mask1,0FFh
    pop ax
    pop ds
    ret
init_process    ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IRQx
;
;           DESCRIPTION:    IRQ handlers
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    irqmac 1
    irqmac 3
    irqmac 4
    irqmac 5
    irqmac 6
    irqmac 7
    irqmac 8
    irqmac 9
    irqmac 10
    irqmac 11
    irqmac 12
    irqmac 13
    irqmac 14
    irqmac 15


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EnableIrq
;
;           description:    Enable IRQ in PIC controller
;
;           PARAMETERS:         AL              irq nr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_irq  Proc far
    push ax
    push cx
;    
    test al,8
    jz set_pic1
set_pic2:
    sub al,8
    mov cl,al
    mov ah,1
    rol ah,cl
    not ah
    cli
    in al,0A1h
    jmp short $+2
    and al,ah
    out 0A1h,al
    sti
    jmp set_pic_done
    
set_pic1:
    mov cl,al
    mov ah,1
    rol ah,cl
    not ah
    cli
    in al,21h
    jmp short $+2
    and al,ah
    out 21h,al
    sti

set_pic_done:
    pop cx
    pop ax
    ret
enable_irq  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DisableIrq
;
;           description:    Disable IRQ in PIC controller
;
;           PARAMETERS:         AL              irq nr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_irq  Proc far
    push ax
    push cx    
;
    test al,8
    jz remove_pic1

remove_pic2:
    sub al,8
    mov cl,al
    mov ah,1
    rol ah,cl
    cli
    in al,0A1h
    or al,ah
    out 0A1h,al
    sti
    jmp remove_pic_done

remove_pic1:
    mov cl,al
    mov ah,1
    rol ah,cl
    cli
    in al,21h
    or al,ah
    out 21h,al
    sti
remove_pic_done:
    pop cx
    pop ax
    ret
disable_irq Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EnableIrqDetect
;
;           description:    Enable IRQ detect in PIC controller
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_irq_detect  Proc far
    push ax
;    
    xor al,al
    out 21h,al
    jmp short $+2
;       
    xor al,al
    out 0A1h,al
;
    pop ax
    ret
enable_irq_detect   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendEoi
;
;           description:    Send EOI (for custom ISRs only)
;
;           PARAMETERS:     AL      Int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_eoi_name   DB 'Send EOI', 0

send_eoi   Proc far
    push ax
;
    mov ah,al
;    
    cmp al,7
    ja sePic1
;
    mov al,62h
    out INT0_CONTROL,al
    jmp short $+2

    mov al,60h - 8
    add al,ah
    out INT1_CONTROL,al
    je seDone

sePic1:
    mov al,60h
    add al,ah
    out INT0_CONTROL,al

seDone:
    pop ax
    ret
send_eoi    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PIC init
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET send_eoi
    mov di,OFFSET send_eoi_name
    xor cl,cl
    mov ax,send_eoi_nr
    RegisterOsGate
;
    mov di,OFFSET init_process
    HookCreateProcess
;
    mov di,OFFSET in_control0
    mov dx,20h
    HookIn
;
    mov di,OFFSET out_control0
    mov dx,20h
    HookOut
;
    mov di,OFFSET in_mask0
    mov dx,21h
    HookIn
;
    mov di,OFFSET out_mask0
    mov dx,21h
    HookOut
;
    mov di,OFFSET in_control1
    mov dx,0A0h
    HookIn
;
    mov di,OFFSET out_control1
    mov dx,0A0h
    HookOut
;
    mov di,OFFSET in_mask1
    mov dx,0A1h
    HookIn
;
    mov di,OFFSET out_mask1
    mov dx,0A1h
    HookOut
;
    mov ax,cs
    mov ds,ax
    xor bl,bl
;
    mov al,29h
    mov esi,OFFSET irq1
    CreateIntGateSelector
;
    mov al,2Bh
    mov esi,OFFSET irq3
    CreateIntGateSelector
;
    mov al,2Ch
    mov esi,OFFSET irq4
    CreateIntGateSelector
;
    mov al,2Dh
    mov esi,OFFSET irq5
    CreateIntGateSelector
;
    mov al,2Eh
    mov esi,OFFSET irq6
    CreateIntGateSelector
;
    mov al,2Fh
    mov esi,OFFSET irq7
    CreateIntGateSelector
;
    mov al,38h
    mov esi,OFFSET irq8
    CreateIntGateSelector
;
    mov al,39h
    mov esi,OFFSET irq9
    CreateIntGateSelector
;
    mov al,3Ah
    mov esi,OFFSET irq10
    CreateIntGateSelector
;
    mov al,3Bh
    mov esi,OFFSET irq11
    CreateIntGateSelector
;
    mov al,3Ch
    mov esi,OFFSET irq12
    CreateIntGateSelector
;
    mov al,3Dh
    mov esi,OFFSET irq13
    CreateIntGateSelector
;
    mov al,3Eh
    mov esi,OFFSET irq14
    CreateIntGateSelector
;
    mov al,3Fh
    mov esi,OFFSET irq15
    CreateIntGateSelector
;
    mov al,11h
    out INT0_CONTROL,al
    jmp short $+2
;
    mov al,28h
    out INT0_MASK,al
    jmp short $+2
;
    mov al,04h
    out INT0_MASK,al
    jmp short $+2
;
    mov al,0C1h
    out INT0_CONTROL,AL
    jmp short $+2
;
    mov al,1
    out INT0_MASK,al
    jmp short $+2
;
    mov al,NOT 4
    out INT0_MASK,al
;
    mov al,11h
    out INT1_CONTROL,al
    jmp short $+2
;
    mov al,38h
    out INT1_MASK,al
    jmp short $+2
;
    mov al,2
    jmp short $+2
    out INT1_MASK,al
    jmp short $+2
;
    mov al,1
    out INT1_MASK,al
    jmp short $+2
;
    mov al,-1
    out INT1_MASK,al
    jmp short $+2
;
    mov bx,irq_sys_sel
    mov ds,bx
;       
    mov word ptr ds:irq_detect_proc,OFFSET enable_irq_detect
    mov word ptr ds:irq_detect_proc+2,cs
;    
    mov cx,16
    mov bx,OFFSET irq_arr
    xor eax,eax

init_irq_loop:
    mov word ptr ds:[bx].irq_enable_proc,OFFSET enable_irq
    mov word ptr ds:[bx].irq_enable_proc+2,cs
;
    mov word ptr ds:[bx].irq_disable_proc,OFFSET disable_irq
    mov word ptr ds:[bx].irq_disable_proc+2,cs
;
    add bx,SIZE irq_struc
    loop init_irq_loop
    ret
init    ENDP

code    ENDS

    END init

