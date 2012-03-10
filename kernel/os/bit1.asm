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
; BIT1.ASM
; Linear 1-bit graphics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\video.inc

    .386p

;
; reg = number of pixels
; EDI = line buffer
;

DrawStart MACRO reg
    local done
    
    EnterSection ds:v_sprite_section
    cmp ds:v_sprite_count,0
    jz done
;
    push ax
    push cx
    push dx
    mov ax,reg
    mov cx,[bp].curr_x
    mov dx,[bp].curr_y
    HideSpriteLine
    pop dx
    pop cx
    pop ax

done:
    mov [bp].curr_start,edi
    mov word ptr [bp].curr_size,reg
            ENDM

;
; reg = number of pixels
; EDI = line buffer
;

SpriteStart MACRO reg
    mov [bp].curr_start,edi
    mov word ptr [bp].curr_size,reg
            ENDM

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;               Global parameter usage
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


curr_start  EQU -8
curr_size   EQU -6
curr_x      EQU -4
curr_y      EQU -2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           PhysUpdate
;
;           DESCRIPTION:    Do a physical update on real hardware
;
;           PARAMETERS:     ECX         Pixels
;                           ES:ESI      Current pos in bitmap
;                           ES:EDI      Current physical pos
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

phys_update Proc far
    ret
phys_update Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawDone
;
;           DESCRIPTION:    Draw done notification
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawDone    Proc near
    cmp ds:v_has_focus,0
    jz draw_sprite
;    
    push ecx
    push esi
    push edi
;    
    movzx ecx,word ptr [bp].curr_size
    mov esi,[bp].curr_start
    mov edi,esi
    sub edi,ds:v_app_base
    add edi,ds:v_phys_base
    call ds:phys_update_proc
;
    pop edi
    pop esi
    pop ecx

draw_sprite:    
    cmp ds:v_sprite_count,0
    jz draw_unblock
;
    ShowSpriteLine

draw_unblock:
    LeaveSection ds:v_sprite_section
    ret
DrawDone    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SpriteDone
;
;           DESCRIPTION:    Sprite done notification
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SpriteDone    Proc near
    cmp ds:v_has_focus,0
    jz sprite_unblock
;    
    push ecx
    push esi
    push edi
;
    movzx ecx,word ptr [bp].curr_size
    mov esi,[bp].curr_start
    mov edi,esi
    sub edi,ds:v_app_base
    add edi,ds:v_phys_base
    call ds:phys_update_proc
;
    pop edi
    pop esi
    pop ecx

sprite_unblock:
    ret
SpriteDone    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopNull
;
;           DESCRIPTION:    Null draw
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopNull    Proc near
    ret
LgopNull    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopNorm
;
;           DESCRIPTION:    Lgop normal
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopNorm    Proc near
    push edx
;
    mov edx,ds:v_app_base
    or eax,eax
    jnz lgop_norm_set

lgop_norm_reset:
    btr es:[edx],edi
    jmp lgop_norm_done

lgop_norm_set:
    bts es:[edx],edi

lgop_norm_done:
    pop edx
    ret
LgopNorm    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopAnd
;
;           DESCRIPTION:    LGOP anding source & dest
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopAnd Proc near
    push edx
;
    mov edx,ds:v_app_base
    or eax,eax
    jnz lgop_and_done
;
    btr es:[edx],edi

lgop_and_done:
    pop edx
    ret
LgopAnd Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopOr
;
;           DESCRIPTION:    Lgop oring source & dest
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopOr  Proc near
    push edx
;
    mov edx,ds:v_app_base
    or eax,eax
    jz lgop_or_done

lgop_or_set:
    bts es:[edx],edi

lgop_or_done:
    pop edx
    ret
LgopOr  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopXor
;
;           DESCRIPTION:    LGOP xoring source & dest
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopXor Proc near
    push edx
;
    mov edx,ds:v_app_base
    or eax,eax
    jz lgop_xor_done
;
    btc es:[edx],edi

lgop_xor_done:
    pop edx
    ret
LgopXor Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopInvert
;
;           DESCRIPTION:    LGOP inverted
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvert      Proc near
    push edx
;
    mov edx,ds:v_app_base
    or eax,eax
    jnz lgop_inv_reset

lgop_inv_set:
    bts es:[edx],edi
    jmp lgop_inv_done

lgop_inv_reset:
    btr es:[edx],edi

lgop_inv_done:
    pop edx
    ret
LgopInvert      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopInvertAnd
;
;           DESCRIPTION:    LGOP inverting & anding source & dest
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertAnd   Proc near
    push edx
;
    mov edx,ds:v_app_base
    or eax,eax
    jz lgop_inv_done
;
    btr es:[edx],edi

lgop_inv_and_done:
    pop edx
    ret
LgopInvertAnd   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopInvertOr
;
;           DESCRIPTION:    LGOP inverting & oring source & dest
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertOr    Proc near
    push edx
;
    mov edx,ds:v_app_base
    or eax,eax
    jnz lgop_inv_or_done
;
    bts es:[edx],edi

lgop_inv_or_done:
    pop edx
    ret
LgopInvertOr    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopInvertXor
;
;           DESCRIPTION:    LGOP inverting & xoring source & dest
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertXor   Proc near
    push edx
;
    mov edx,ds:v_app_base
    or eax,eax
    jnz lgop_inv_xor_done
;
    btc es:[edx],edi

lgop_inv_xor_done:
    pop edx
    ret
LgopInvertXor   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopTab
;
;           DESCRIPTION:    LGOP table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopTab:
lgt00   DW OFFSET LgopNull
lgt01   DW OFFSET LgopNorm
lgt02   DW OFFSET LgopOr
lgt03   DW OFFSET LgopAnd
lgt04   DW OFFSET LgopXor
lgt05   DW OFFSET LgopInvert
lgt06   DW OFFSET LgopInvertOr
lgt07   DW OFFSET LgopInvertAnd
lgt08   DW OFFSET LgopInvertXor
lgt09   DW OFFSET LgopOr
lgt0A   DW OFFSET LgopAnd
lgt0B   DW OFFSET LgopAnd
lgt0C   DW OFFSET LgopNull
lgt0D   DW OFFSET LgopNull
lgt0E   DW OFFSET LgopNull
lgt0F   DW OFFSET LgopNull


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           TranslateColor
;
;           DESCRIPTION:    Translate color
;
;           PARAMETER:          EAX             RGB color
;
;       RETURNS:    EAX     Internal color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

translate_color Proc far
    push dx
;
    movzx dx,al
    shr eax,8
    add dl,al
    adc dh,0
    shr eax,8
    add dl,al
    adc dh,0
;
    cmp dx,3 * 128
    jc translate_zero
;
    mov eax,1
    jmp translate_done

translate_zero:
    xor eax,eax

translate_done:
    pop dx
    ret
translate_color Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetBase
;
;           DESCRIPTION:    Basic set pixel
;
;           PARAMETER:          EAX     Color
;                           EDI     Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_base    Proc far
    push bx
    mov bx,ds:v_lgop
    add bx,bx
    call word ptr cs:[bx].LgopTab
    pop bx
    ret
set_base    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SlabSet
;
;           DESCRIPTION:    Set line
;
;           PARAMETERS:         EDI         Position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

or_bit_tab:
bt00    DB 0FFh
bt01    DB 0FEh
bt02    DB 0FCh
bt03    DB 0F8h
bt04    DB 0F0h
bt05    DB 0E0h
bt06    DB 0C0h
bt07    DB 80h

SlabSet Proc near
    push eax
    push ebx
    push cx
    push edi
;
    or cx,cx
    jz slab_set_done
;
    mov eax,edi
    mov edi,ds:v_app_base
    movzx ebx,al
    shr eax,3
    add edi,eax
    and bl,7
    mov ax,cx
    add ax,bx
    cmp ax,8
    jc slab_set_last_loop
;
    mov al,byte ptr cs:[bx].or_bit_tab
    or es:[edi],al
    sub cx,8
    add cx,bx
    jz slab_set_done
;
    mov al,-1
    xor bl,bl

slab_set_loop:
    inc edi
    cmp cx,8
    jb slab_set_last_loop
;
    mov es:[edi],al
    sub cx,8
    jnz slab_set_loop
    jmp slab_set_done
    
slab_set_last_loop:
    bts es:[edi],ebx
    inc bl
    loop slab_set_last_loop

slab_set_done:
    pop edi
    pop cx
    pop ebx
    pop eax
    ret
SlabSet Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SlabReset
;
;           DESCRIPTION:    Reset line
;
;           PARAMETERS:         EDI         position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

and_bit_tab:
br00    DB 0
br01    DB 1
br02    DB 3
br03    DB 7
br04    DB 0Fh
br05    DB 1Fh
br06    DB 3Fh
br07    DB 7Fh

SlabReset       Proc near
    push eax
    push ebx
    push cx
    push edi
;
    or cx,cx
    jz slab_reset_done
;
    mov eax,edi
    mov edi,ds:v_app_base
    movzx ebx,al
    shr eax,3
    add edi,eax
    and bl,7
    mov ax,cx
    add ax,bx
    cmp ax,8
    jc slab_reset_last_loop
;
    mov al,byte ptr cs:[bx].and_bit_tab
    and es:[edi],al
    sub cx,8
    add cx,bx
    jz slab_reset_done
;
    xor al,al
    xor bl,bl

slab_reset_loop:
    inc edi
    cmp cx,8
    jb slab_reset_last_loop
;
    mov es:[edi],al
    sub cx,8
    jnz slab_reset_loop
    jmp slab_reset_done
    
slab_reset_last_loop:
    btr es:[edi],ebx
    inc bl
    loop slab_reset_last_loop

slab_reset_done:
    pop edi
    pop cx
    pop ebx
    pop eax
    ret
SlabReset       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SlabCompl
;
;           DESCRIPTION:    Compl line
;
;           PARAMETERS:         EDI         position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabCompl       Proc near
    push eax
    push ebx
    push cx
    push edi
;
    or cx,cx
    jz slab_compl_done
;
    mov eax,edi
    mov edi,ds:v_app_base
    movzx ebx,al
    shr eax,3
    add edi,eax
    and bl,7
    mov ax,cx
    add ax,bx
    cmp ax,8
    jc slab_compl_last_loop
;
    mov al,byte ptr cs:[bx].or_bit_tab
    xor es:[edi],al
    sub cx,8
    add cx,bx
    jz slab_compl_done
;
    mov al,-1
    xor bl,bl

slab_compl_loop:
    inc edi
    cmp cx,8
    jb slab_compl_last_loop
;
    xor es:[edi],al
    sub cx,8
    jnz slab_compl_loop
    jmp slab_compl_done
    
slab_compl_last_loop:
    btc es:[edi],ebx
    inc bl
    loop slab_compl_last_loop

slab_compl_done:
    pop edi
    pop cx
    pop ebx
    pop eax
    ret
SlabCompl       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SlabNull
;
;           DESCRIPTION:    Null slab
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabNull    Proc near
    ret
SlabNull    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SlabNorm
;
;           DESCRIPTION:    Slab normal
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabNorm    Proc near
    or eax,eax
    jz slab_norm_reset
;
    call SlabSet
    jmp slab_norm_done

slab_norm_reset:
    call SlabReset

slab_norm_done:
    ret
SlabNorm    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SlabAnd
;
;           DESCRIPTION:    Slab anding source & dest
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabAnd Proc near
    or eax,eax
    jnz slab_and_done
;
    call SlabReset

slab_and_done:
    ret
SlabAnd Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SlabOr
;
;           DESCRIPTION:    Slab oring source & dest
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabOr  Proc near
    or eax,eax
    jz slab_or_done
;
    call SlabSet

slab_or_done:
    ret
SlabOr  Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SlabXor
;
;           DESCRIPTION:    Slab xoring source & dest
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabXor Proc near
    or eax,eax
    jz slab_xor_done
;
    call SlabCompl

slab_xor_done:
    ret
SlabXor Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SlabInvert
;
;           DESCRIPTION:    Slab inverted
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabInvert      Proc near
    or eax,eax
    jnz slab_inv_reset

slab_inv_set:
    call SlabSet
    jmp slab_inv_done

slab_inv_reset:
    call SlabReset

slab_inv_done:
    ret
SlabInvert      Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SlabInvertAnd
;
;           DESCRIPTION:    Slab inverting & anding source & dest
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabInvertAnd   Proc near
    or eax,eax
    jz slab_inv_and_done
;
    call SlabReset

slab_inv_and_done:
    ret
SlabInvertAnd   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SlabInvertOr
;
;           DESCRIPTION:    Slab inverting & oring source & dest
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabInvertOr    Proc near
    or eax,eax
    jnz slab_inv_or_done
;
    call SlabSet

slab_inv_or_done:
    ret
SlabInvertOr    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SlabInvertXor
;
;           DESCRIPTION:    Slab inverting & xoring source & dest
;
;           PARAMETERS:         EAX             Color
;                           EDI         position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabInvertXor   Proc near
    or eax,eax
    jnz slab_inv_xor_done
;
    call SlabCompl

slab_inv_xor_done:
    ret
SlabInvertXor   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SlabTab
;
;           DESCRIPTION:    Slab LGOP table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabTab:
st00    DW OFFSET SlabNull
st01    DW OFFSET SlabNorm
st02    DW OFFSET SlabOr
st03    DW OFFSET SlabAnd
st04    DW OFFSET SlabXor
st05    DW OFFSET SlabInvert
st06    DW OFFSET SlabInvertOr
st07    DW OFFSET SlabInvertAnd
st08    DW OFFSET SlabInvertXor
st09    DW OFFSET SlabOr
st0A    DW OFFSET SlabAnd
st0B    DW OFFSET SlabAnd
st0C    DW OFFSET SlabNull
st0D    DW OFFSET SlabNull
st0E    DW OFFSET SlabNull
st0F    DW OFFSET SlabNull



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Slab
;
;           DESCRIPTION:    Fill line
;
;           PARAMETERS:         AX              Color
;                       EDI         position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

slab    Proc far
    push bx
    mov bx,ds:v_lgop
    add bx,bx
    call word ptr cs:[bx].SlabTab
    pop bx
    ret
slab    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyNull
;
;           DESCRIPTION:    Null copy
;
;           PARAMETERS:         FS:EAX      source bitmap
;               ESI     source position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyNull    Proc near
    ret
CopyNull    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyNorm
;
;           DESCRIPTION:    Copy normally
;
;           PARAMETERS:         FS:EAX      source bitmap
;               ESI     source position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyNorm    Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz copy_norm_done

copy_norm_loop:
    bt fs:[eax],esi
    jc copy_norm_set

copy_norm_reset:
    btr es:[edx],edi
    jmp copy_norm_next

copy_norm_set:
    bts es:[edx],edi

copy_norm_next:
    inc esi
    inc edi
    loop copy_norm_loop

copy_norm_done:
    pop edi
    pop esi
    pop cx
    ret
CopyNorm    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyAnd
;
;           DESCRIPTION:    Copy by anding source & dest
;
;           PARAMETERS:         FS:EAX      source bitmap
;               ESI     source position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyAnd Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz copy_and_done

copy_and_loop:
    bt fs:[eax],esi
    jc copy_and_next
;
    btr es:[edx],edi

copy_and_next:
    inc esi
    inc edi
    loop copy_and_loop

copy_and_done:
    pop edi
    pop esi
    pop cx
    ret
CopyAnd Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyOr
;
;           DESCRIPTION:    Copy by oring source & dest
;
;           PARAMETERS:         FS:EAX      source bitmap
;               ESI     source position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyOr  Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz copy_or_done

copy_or_loop:
    bt fs:[eax],esi
    jnc copy_or_next
;
    bts es:[edx],edi

copy_or_next:
    inc esi
    inc edi
    loop copy_or_loop

copy_or_done:
    pop edi
    pop esi
    pop cx
    ret
CopyOr  Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyXor
;
;           DESCRIPTION:    Copy by xoring source & dest
;
;           PARAMETERS:         FS:EAX      source bitmap
;               ESI     source position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyXor Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz copy_xor_done

copy_xor_loop:
    bt fs:[eax],esi
    jnc copy_xor_next
;
    btc es:[edx],edi

copy_xor_next:
    inc esi
    inc edi
    loop copy_xor_loop

copy_xor_done:
    pop edi
    pop esi
    pop cx
    ret
CopyXor Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyInvert
;
;           DESCRIPTION:    Copy inverted
;
;           PARAMETERS:         FS:EAX      source bitmap
;               ESI     source position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyInvert      Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz copy_inv_done

copy_inv_loop:
    bt fs:[eax],esi
    jc copy_inv_reset

copy_inv_set:
    bts es:[edx],edi
    jmp copy_inv_next

copy_inv_reset:
    btr es:[edx],edi

copy_inv_next:
    inc esi
    inc edi
    loop copy_inv_loop

copy_inv_done:
    pop edi
    pop esi
    pop cx
    ret
CopyInvert      Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyInvertAnd
;
;           DESCRIPTION:    Copy by inverting & anding source & dest
;
;           PARAMETERS:         FS:EAX      source bitmap
;               ESI     source position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyInvertAnd   Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz copy_inv_and_done

copy_inv_and_loop:
    bt fs:[eax],esi
    jnc copy_inv_and_next
;
    btr es:[edx],edi

copy_inv_and_next:
    inc esi
    inc edi
    loop copy_inv_and_loop

copy_inv_and_done:
    pop edi
    pop esi
    pop cx
    ret
CopyInvertAnd   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyInvertOr
;
;           DESCRIPTION:    Copy by inverting & oring source & dest
;
;           PARAMETERS:         FS:EAX      source bitmap
;               ESI     source position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyInvertOr    Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz copy_inv_or_done

copy_inv_or_loop:
    bt fs:[eax],esi
    jc copy_inv_or_next
;
    bts es:[edx],edi

copy_inv_or_next:
    inc esi
    inc edi
    loop copy_inv_or_loop

copy_inv_or_done:
    pop edi
    pop esi
    pop cx
    ret
CopyInvertOr    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyInvertXor
;
;           DESCRIPTION:    Copy by inverting & xoring source & dest
;
;           PARAMETERS:         FS:EAX      source bitmap
;               ESI     source position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyInvertXor   Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz copy_inv_xor_done

copy_inv_xor_loop:
    bt fs:[eax],esi
    jc copy_inv_xor_next
;
    btc es:[edx],edi

copy_inv_xor_next:
    inc esi
    inc edi
    loop copy_inv_xor_loop

copy_inv_xor_done:
    pop edi
    pop esi
    pop cx
    ret
CopyInvertXor   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyTab
;
;           DESCRIPTION:    Copy LGOP table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyTab:
ct00    DW OFFSET CopyNull
ct01    DW OFFSET CopyNorm
ct02    DW OFFSET CopyOr
ct03    DW OFFSET CopyAnd
ct04    DW OFFSET CopyXor
ct05    DW OFFSET CopyInvert
ct06    DW OFFSET CopyInvertOr
ct07    DW OFFSET CopyInvertAnd
ct08    DW OFFSET CopyInvertXor
ct09    DW OFFSET CopyOr
ct0A    DW OFFSET CopyAnd
ct0B    DW OFFSET CopyAnd
ct0C    DW OFFSET CopyNull
ct0D    DW OFFSET CopyNull
ct0E    DW OFFSET CopyNull
ct0F    DW OFFSET CopyNull



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Copy
;
;           DESCRIPTION:    Copy line
;
;           PARAMETERS:         EAX     Source base
;               FS:ESI      Source position
;                       EDI         Dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

copy    Proc far
    push bx
    push edx
;
    mov edx,ds:v_app_base
    mov bx,ds:v_lgop
    add bx,bx
    call word ptr cs:[bx].CopyTab
;
    pop edx
    pop bx
    ret
copy    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MaskSetNull
;
;           DESCRIPTION:    Null mask set
;
;           PARAMETERS:         EAX             color
;                           GS:EBP      mask
;               ESI     mask position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MaskSetNull     Proc near
    ret
MaskSetNull     Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MaskSetNorm
;
;           DESCRIPTION:    Mask set normally
;
;           PARAMETERS:         EAX             color
;                           GS:EBP      mask
;               ESI     mask position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MaskSetNorm     Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz mask_set_norm_done
;
    or eax,eax
    jz mask_set_norm_reset_loop

mask_set_norm_set_loop:
    bt gs:[ebp],esi
    jnc mask_set_norm_set_next
;
    bts es:[edx],edi

mask_set_norm_set_next:
    inc esi
    inc edi
    loop mask_set_norm_set_loop
    jmp mask_set_norm_done

mask_set_norm_reset_loop:
    bt gs:[ebp],esi
    jnc mask_set_norm_reset_next
;
    btr es:[edx],edi

mask_set_norm_reset_next:
    inc esi
    inc edi
    loop mask_set_norm_reset_loop

mask_set_norm_done:
    pop edi
    pop esi
    pop cx
    ret
MaskSetNorm     Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MaskSetAnd
;
;           DESCRIPTION:    Mask set by anding source & dest
;
;           PARAMETERS:         EAX             color
;                           GS:EBP      source bitmap
;               ESI     source position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MaskSetAnd      Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz mask_set_and_done
;
    or eax,eax
    jnz mask_set_and_done

mask_set_and_loop:
    bt gs:[ebp],esi
    jnc mask_set_and_next
;
    btr es:[edx],edi

mask_set_and_next:
    inc esi
    inc edi
    loop mask_set_and_loop

mask_set_and_done:
    pop edi
    pop esi
    pop cx
    ret
MaskSetAnd      Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MaskSetOr
;
;           DESCRIPTION:    Mask set by oring source & dest
;
;           PARAMETERS:         EAX             color
;                           GS:EBP      mask
;               ESI     mask position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MaskSetOr       Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz mask_set_or_done
;
    or eax,eax
    jz mask_set_or_done

mask_set_or_loop: 
    bt gs:[ebp],esi
    jnc mask_set_or_next
;
    bts es:[edx],edi

mask_set_or_next:
    inc esi
    inc edi
    loop mask_set_or_loop

mask_set_or_done:
    pop edi
    pop esi
    pop cx
    ret
MaskSetOr       Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MaskSetXor
;
;           DESCRIPTION:    Mask set by xoring source & dest
;
;           PARAMETERS:         EAX             color
;                           GS:EBP      mask
;               ESI     mask position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MaskSetXor      Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz mask_set_xor_done
;
    or eax,eax
    jz mask_set_xor_done

mask_set_xor_loop:
    bt gs:[ebp],esi
    jnc mask_set_xor_next
;
    btc es:[edx],edi

mask_set_xor_next:
    inc esi
    inc edi
    loop mask_set_xor_loop

mask_set_xor_done:
    pop edi
    pop esi
    pop cx
    ret
MaskSetXor      Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MaskSetInvert
;
;           DESCRIPTION:    Mask set inverted
;
;           PARAMETERS:         EAX             color
;                           GS:EBP      mask
;               ESI     mask position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MaskSetInvert   Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz mask_set_inv_done
;
    or eax,eax
    jnz mask_set_inv_reset_loop

mask_set_inv_set_loop:
    bt gs:[ebp],esi
    jnc mask_set_inv_set_next
;
    bts es:[edx],edi

mask_set_inv_set_next:
    inc esi
    inc edi
    loop mask_set_inv_set_loop
    jmp mask_set_inv_done

mask_set_inv_reset_loop:
    bt gs:[ebp],esi
    jnc mask_set_inv_reset_next
;
    btr es:[edx],edi

mask_set_inv_reset_next:
    inc esi
    inc edi
    loop mask_set_inv_reset_loop

mask_set_inv_done:
    pop edi
    pop esi
    pop cx
    ret
MaskSetInvert   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MaskSetInvertAnd
;
;           DESCRIPTION:    Mask set by inverting & anding source & dest
;
;           PARAMETERS:         EAX             color
;                           GS:EBP      mask
;               ESI     mask position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MaskSetInvertAnd    Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz mask_set_inv_and_done
;
    or eax,eax
    jz mask_set_inv_and_done

mask_set_inv_and_loop:
    bt gs:[ebp],esi
    jnc mask_set_inv_and_next
;
    btr es:[edx],edi

mask_set_inv_and_next:
    inc esi
    inc edi
    loop mask_set_inv_and_loop

mask_set_inv_and_done:
    pop edi
    pop esi
    pop cx
    ret
MaskSetInvertAnd    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MaskSetInvertOr
;
;           DESCRIPTION:    Mask set by inverting & oring source & dest
;
;           PARAMETERS:         EAX             color
;                           GS:EBP      mask
;               ESI     mask position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MaskSetInvertOr Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz mask_set_inv_or_done
;
    or eax,eax
    jnz mask_set_inv_or_done

mask_set_inv_or_loop: 
    bt gs:[ebp],esi
    jnc mask_set_inv_or_next
;
    bts es:[edx],edi

mask_set_inv_or_next:
    inc esi
    inc edi
    loop mask_set_inv_or_loop

mask_set_inv_or_done:
    pop edi
    pop esi
    pop cx
    ret
MaskSetInvertOr Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MaskSetInvertXor
;
;           DESCRIPTION:    Mask set by inverting & xoring source & dest
;
;           PARAMETERS:         EAX             color
;                           GS:EBP      mask
;               ESI     mask position
;               ES:EDX      dest bitmap
;               EDI         dest position
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MaskSetInvertXor    Proc near
    push cx
    push esi
    push edi
;
    or cx,cx
    jz mask_set_inv_xor_done
;
    or eax,eax
    jnz mask_set_inv_xor_done

mask_set_inv_xor_loop:
    bt gs:[ebp],esi
    jnc mask_set_inv_xor_next
;
    btc es:[edx],edi

mask_set_inv_xor_next:
    inc esi
    inc edi
    loop mask_set_inv_xor_loop

mask_set_inv_xor_done:
    pop edi
    pop esi
    pop cx
    ret
MaskSetInvertXor    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MaskSetTab
;
;           DESCRIPTION:    Mask set LGOP table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MaskSetTab:
mst00   DW OFFSET MaskSetNull
mst01   DW OFFSET MaskSetNorm
mst02   DW OFFSET MaskSetOr
mst03   DW OFFSET MaskSetAnd
mst04   DW OFFSET MaskSetXor
mst05   DW OFFSET MaskSetInvert
mst06   DW OFFSET MaskSetInvertOr
mst07   DW OFFSET MaskSetInvertAnd
mst08   DW OFFSET MaskSetInvertXor
mst09   DW OFFSET MaskSetOr
mst0A   DW OFFSET MaskSetAnd
mst0B   DW OFFSET MaskSetAnd
mst0C   DW OFFSET MaskSetNull
mst0D   DW OFFSET MaskSetNull
mst0E   DW OFFSET MaskSetNull
mst0F   DW OFFSET MaskSetNull



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MaskSet
;
;           DESCRIPTION:    Set mask line
;
;           PARAMETERS:         EAX     Color
;                           CX              number of pixels
;               DL      Start bit number
;               GS:EBX      Mask bits
;                           ES:EDI      Dest buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mask_set    Proc far
    push bx
    push edx
    push esi
    push ebp
;
    mov ebp,ebx
    movzx esi,dl
    mov edx,ds:v_app_base
;
    mov bx,ds:v_lgop
    add bx,bx
    call word ptr cs:[bx].MaskSetTab
;
    pop ebp
    pop esi
    pop edx
    pop bx
    ret
mask_set    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MaskCopy
;
;           DESCRIPTION:    Copy mask line
;
;           PARAMETERS:         CX              number of pixels
;               DL      Start bit number
;               FS:ESI      Source pixels
;               GS:EBX      Mask bits 
;                           ES:EDI      Dest buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mask_copy       Proc far
    pushad
;
    or cx,cx
    jz mask_copy_done
;
    mov ax,ds:v_lgop
    cmp ax,LGOP_NONE
    je mask_copy_none
;
    mov edx,ebx
    movzx ebx,dl
    
mask_copy_loop:
    bt gs:[edx],ebx
    jnc mask_copy_next
;
    push bx
;
    bt fs:[esi],ebx
    jc mask_copy_set
;
    xor eax,eax
    jmp mask_copy_do

mask_copy_set:
    mov eax,1

mask_copy_do:
    mov bx,ds:v_lgop
    add bx,bx
    call word ptr cs:[bx].LgopTab
;
    pop bx

mask_copy_next:
    inc ebx
    inc edi
    loop mask_copy_loop
    jmp mask_copy_done

mask_copy_none:
    mov ebp,ebx
    movzx ebx,dl
    mov edx,ds:v_app_base
    
mask_copy_none_loop:
    bt gs:[ebp],ebx
    jnc mask_copy_none_next
;
    bt fs:[esi],ebx
    jc mask_copy_none_set
;
    btr es:[edx],edi
    jmp mask_copy_none_next

mask_copy_none_set:
    bts es:[edx],edi

mask_copy_none_next:
    inc ebx
    inc edi
    loop mask_copy_none_loop

mask_copy_done:
    popad
    ret
mask_copy    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:       AntiAliasSet
;
;       DESCRIPTION:    Set mask using 256-level anti-alias bitmap
;
;       PARAMETERS:         AX          Internal color
;                           CX          number of pixels
;                           GS:EBX      Antialias bitmap
;                           EDI         position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

anti_alias_set  Proc far
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    or cx,cx
    jz anti_alias_set_line_done
    
anti_alias_set_line_loop:
    push cx
    mov dl,gs:[ebx]
    test dl,80h
    jz anti_alias_set_line_next
;    
    push bx
    mov bx,ds:v_lgop
    add bx,bx
    call word ptr cs:[bx].LgopTab
    pop bx

anti_alias_set_line_next:
    pop cx
    inc edi
    inc word ptr [bp].curr_x
    inc ebx
    sub cx,1
    jnz anti_alias_set_line_loop

anti_alias_set_line_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
anti_alias_set    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AntiAlias
;
;           DESCRIPTION:    Anti-alias line and process sprites & limits
;
;           PARAMETER:          DL      First bit
;                           CX              Number of pixels
;                           GS:EBX      Antialias bitmap
;                           EDI         position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AntiAlias Proc near
    push word ptr [bp].curr_x
    push ebx
    push cx
    push si
    push edi
;
    or cx,cx
    jz aa_done
;    
    mov ax,[bp].curr_y
    cmp ax,ds:v_y_min
    jl aa_done
;
    cmp ax,ds:v_y_max
    jg aa_done
;
    mov ax,[bp].curr_x
    cmp ax,ds:v_x_max
    jg aa_done
    
aa_buf_loop:
    cmp ax,ds:v_x_min
    jge aa_start_ok

aa_adv_buf:
    inc ax
    inc edi
    sub cx,1
    jnz aa_buf_loop
    jmp aa_done

aa_start_ok:
    mov si,ds:v_x_max
    sub si,ax
    inc si
    cmp cx,si
    jc aa_do
;
    mov cx,si
    
aa_do:
    DrawStart cx
    mov eax,ds:v_color
    call ds:anti_alias_proc
    call DrawDone

aa_done:
    pop edi
    pop si
    pop cx
    pop ebx
    pop word ptr [bp].curr_x
    ret
AntiAlias Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HollowLine
;
;           DESCRIPTION:    Draw a hollow line
; 
;           PARAMETER:          CX              width
;                           EDI             position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HollowLine      Proc near
    push word ptr [bp].curr_x
    push cx
    push edi
;
    mov ax,[bp].curr_y
    cmp ax,ds:v_y_min
    jl hollow_line_done
;
    cmp ax,ds:v_y_max
    jg hollow_line_done
;
    mov ax,[bp].curr_x
    cmp ax,ds:v_x_max
    jg hollow_line_done
;
    cmp ax,ds:v_x_min
    jl hollow_line_first_done
;
    DrawStart 1
    mov eax,ds:v_color
    call ds:set_proc
    call DrawDone

hollow_line_first_done:
    mov ax,cx
    dec ax
    movsx eax,ax
    add edi,eax
;
    mov ax,[bp].curr_x
    add ax,cx
    dec ax
    mov [bp].curr_x,ax
    cmp ax,ds:v_x_min
    jl hollow_line_done
;
    cmp ax,ds:v_x_max
    jg hollow_line_done
;
    DrawStart 1
    mov eax,ds:v_color
    call ds:set_proc
    call DrawDone

hollow_line_done:
    pop edi
    pop cx
    pop word ptr [bp].curr_x
    ret
HollowLine      Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FilledLine
;
;           DESCRIPTION:    Draw a filled line
; 
;           PARAMETER:          CX              width
;                           EDI             position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FilledLine      Proc near
    push word ptr [bp].curr_x
    push cx
    push edi
;
    mov ax,[bp].curr_y
    cmp ax,ds:v_y_min
    jl filled_line_done
;
    cmp ax,ds:v_y_max
    jg filled_line_done
;
    mov ax,[bp].curr_x
    cmp ax,ds:v_x_max
    jg filled_line_done
    
filled_line_buf_loop:
    cmp ax,ds:v_x_min
    jge filled_line_start_ok

filled_line_adv_buf:
    inc ax
    inc edi
    sub cx,1
    jnz filled_line_buf_loop
    jmp filled_line_done

filled_line_start_ok:
    mov bx,ds:v_x_max
    sub bx,ax
    inc bx
    cmp cx,bx
    jc filled_line_do
;
    mov cx,bx
    
filled_line_do:
    or cx,cx
    jz filled_line_done
;
    mov [bp].curr_x,ax
;    
    DrawStart cx
    mov eax,ds:v_color
    call ds:slab_proc
    call DrawDone

filled_line_done:
    pop edi
    pop cx
    pop word ptr [bp].curr_x
    ret
FilledLine      Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SplitLine
;
;           DESCRIPTION:    Draw a split line
; 
;           PARAMETER:          CX              gap
;                           DX              line width
;                           EDI             position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SplitLine       Proc near
    push word ptr [bp].curr_x
    push cx
    push dx
    push edi
;
    mov bx,[bp].curr_y
    cmp bx,ds:v_y_min
    jl split_line_done
;
    cmp bx,ds:v_y_max
    jg split_line_done
;
    mov bx,[bp].curr_x
    cmp bx,ds:v_x_max
    jg split_line_done
;
    sub cx,ax
    sub cx,ax
    mov dx,ax
;
    push cx
    mov cx,dx
;    
    DrawStart cx

split_left_loop:
    mov bx,[bp].curr_x
    cmp bx,ds:v_x_min
    jl split_left_next
;
    cmp bx,ds:v_x_max
    jg split_left_next
;
    mov eax,ds:v_color
    call ds:set_proc

split_left_next:
    inc word ptr [bp].curr_x
    inc edi
    loop split_left_loop
;
    call DrawDone
    pop cx
    add [bp].curr_x,cx
;
    movsx eax,cx
    add edi,eax
;
    mov cx,dx
    DrawStart cx

split_right_loop:
    mov bx,[bp].curr_x
    cmp bx,ds:v_x_min
    jl split_right_next
;
    cmp bx,ds:v_x_max
    jg split_right_next
;
    mov eax,ds:v_color
    call ds:set_proc

split_right_next:
    inc word ptr [bp].curr_x
    inc edi
    loop split_right_loop
;
    call DrawDone

split_line_done:
    pop edi
    pop dx
    pop cx
    pop word ptr [bp].curr_x
    ret
SplitLine       Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetNative
;
;           DESCRIPTION:    Get pixels in internal format
;
;           PARAMETER:          AX              number of pixels
;                           CX              x
;                           DX              y
;                           ES:EDI      buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_native      Proc far
    push ds
    pushad
;
    push ax
    movzx edx,dx
    movzx eax,ds:v_row_size
    mul edx
    add eax,ds:v_app_base
    mov esi,eax
    mov ax,flat_sel
    mov ds,ax
    movzx eax,cx
    shr eax,3
    add esi,eax
    and cl,7
    pop dx
;
    or dx,dx
    jz get_native_done
;
    xor ebx,ebx
    lods byte ptr [esi]
    shr al,cl
    mov ch,8
    sub ch,cl

get_native_loop:
    rcr al,1
    jc get_native_set

get_native_reset:
    btr es:[edi],ebx
    jmp get_native_next

get_native_set:
    bts es:[edi],ebx

get_native_next:
    inc ebx
    sub dx,1
    jz get_native_done
;
    sub ch,1
    jnz get_native_loop
;
    lods byte ptr [esi]
    mov ch,8
    jmp get_native_loop

get_native_done:
    popad
    pop ds
    ret
get_native      Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetRGB
;
;           DESCRIPTION:    Get pixels in RGB format
;
;           PARAMETER:          AX              number of pixels
;                           CX              x
;                           DX              y
;                           ES:EDI      line buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_rgb Proc far
    push ds
    pushad
;
    push ax
    movzx edx,dx
    movzx eax,ds:v_row_size
    mul edx
    add eax,ds:v_app_base
    mov esi,eax
    mov ax,flat_sel
    mov ds,ax
    movzx eax,cx
    shr eax,3
    add esi,eax
    and cl,7
    pop dx
;
    or dx,dx
    jz get_rgb_done
;
    lods byte ptr [esi]
    shr al,cl
    mov ch,8
    sub ch,cl

get_rgb_loop:
    rcr al,1
    jc get_rgb_set

get_rgb_reset:
    mov dword ptr es:[edi],0
    jmp get_rgb_next

get_rgb_set:
    mov dword ptr es:[edi],0FFFFFFh

get_rgb_next:
    add edi,4
    sub dx,1
    jz get_rgb_done
;
    sub ch,1
    jnz get_rgb_loop
;
    lods byte ptr [esi]
    mov ch,8
    jmp get_rgb_loop

get_rgb_done:
    popad
    pop ds
    ret
get_rgb Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetNative
;
;           DESCRIPTION:    Set pixels in internal format
;
;           PARAMETER:          AX              number of pixels
;                           CX              x
;                           DX              y
;                           ES:EDI      line buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_native      Proc far
    push ds
    push es
    push fs
    pushad
;
    push ax
    mov ax,es
    mov fs,ax
    mov ax,flat_sel
    mov es,ax
    mov esi,edi
;
    movzx edx,dx
    movzx eax,ds:v_row_size
    mul edx
    shl eax,3
    movzx ecx,cx
    add eax,ecx
    mov edi,eax
    pop cx
;
    or cx,cx
    jz set_native_done
;
    DrawStart cx
    xor ebx,ebx

set_native_loop:
    bt fs:[esi],ebx
    jnc set_native_zero
;
    mov eax,1
    jmp set_native_do

set_native_zero:
    xor eax,eax

set_native_do:
    call ds:set_proc
;
    inc ebx
    inc edi
    loop set_native_loop
;
    call DrawDone

set_native_done:
    popad
    pop fs
    pop es
    pop ds
    ret
set_native      Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetRGB
;
;           DESCRIPTION:    Set pixels in RGB format
;
;           PARAMETER:          AX              number of pixels
;                           CX              x
;                           DX              y
;                           ES:EDI      line buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_rgb Proc far
    push ds
    push es
    push fs
    pushad
;
    push ax
    mov ax,es
    mov fs,ax
    mov ax,flat_sel
    mov es,ax
    mov esi,edi
;
    movzx edx,dx
    movzx eax,ds:v_row_size
    mul edx
    shl eax,3
    movzx ecx,cx
    add eax,ecx
    mov edi,eax
    pop cx
;
    or cx,cx
    jz set_rgb_done
;
    DrawStart cx

set_rgb_loop:
    mov eax,fs:[esi]
    movzx dx,al
    shr eax,8
    add dl,al
    adc dh,0
    shr eax,8
    add dl,al
    adc dh,0
;
    cmp dx,3 * 128
    jc set_rgb_zero
;
    mov eax,1
    jmp set_rgb_do

set_rgb_zero:
    xor eax,eax

set_rgb_do:
    call ds:set_proc
;
    add esi,4
    inc edi
    loop set_rgb_loop
;
    call DrawDone

set_rgb_done:
    popad
    pop fs
    pop es
    pop ds
    ret
set_rgb Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetSprite
;
;           DESCRIPTION:    Set sprite in native format
;
;           PARAMETER:          AX              number of pixels
;               BL      first bit
;                           CX              x
;                           DX              y
;                       ES:EDI      buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_sprite      Proc far
    push es
    push fs
    pushad
    mov bp,sp
    sub sp,10
    mov [bp].curr_x,cx
    mov [bp].curr_y,dx
    movzx esi,bl
;
    cmp dx,ds:v_y_min
    jl set_sprite_done
;
    cmp dx,ds:v_y_max
    jg set_sprite_done

set_sprite_buf_loop:
    cmp cx,ds:v_x_min
    jge set_sprite_start_ok

set_sprite_adv_buf:
    inc cx
    inc esi
    sub ax,1
    jnz set_sprite_buf_loop
    jmp set_sprite_done

set_sprite_start_ok:
    mov bx,ds:v_x_max
    sub bx,cx
    inc bx
    cmp ax,bx
    jc set_sprite_do
;
    mov ax,bx
    
set_sprite_do:
    or ax,ax
    jz set_sprite_done
;
    push edi
    push ax
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    imul edx
    shl eax,3
    mov edi,eax
    add edi,ecx
    pop cx
;
    mov ax,es
    mov fs,ax
    mov ax,flat_sel
    mov es,ax
    pop eax
;
    SpriteStart cx
    call ds:copy_proc
    call SpriteDone

set_sprite_done:
    add sp,10
    popad
    pop fs
    pop es
    ret
set_sprite      Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetLine
;
;           DESCRIPTION:    Get line buffer ptr
;
;           PARAMETER:          CX              x
;                           DX              y
;
;           RETURNS:        ES:EDI      line buffer
;                           EAX             bit #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_line    Proc far
    push edx
    movzx edx,dx
    movzx eax,ds:v_row_size
    mul edx
    add eax,ds:v_app_base
    mov edi,eax
    movzx eax,cx
    shr eax,3
    add edi,eax
    mov ax,flat_sel
    mov es,ax
    movzx eax,cx
    and ax,7
    pop edx
    ret
get_line    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetPixel
;
;           DESCRIPTION:    Get pixel
;
;           PARAMETER:          CX              x
;                           DX              y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pixel       Proc far
    push es
    push edx
    movzx ecx,cx
    movzx edx,dx
    movzx eax,ds:v_row_size
    mul edx
    add eax,ds:v_app_base
    mov dx,flat_sel
    mov es,dx
    bt es:[eax],ecx
    jc get_pixel_set
;
    xor eax,eax
    jmp get_pixel_done

get_pixel_set:
    mov eax,0FFFFFFh

get_pixel_done:
    pop edx 
    pop es
    ret
get_pixel       Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetPixel
;
;           DESCRIPTION:    Set pixel
;
;           PARAMETER:          CX              x
;                           DX              y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_pixel       Proc far
    push ds
    push es
    push eax
    push bx
    push edx
    push edi
    push bp
    mov bp,sp
    sub sp,10
    mov [bp].curr_x,cx
    mov [bp].curr_y,dx
;
    cmp cx,ds:v_x_min
    jl set_pixel_done
;
    cmp dx,ds:v_y_min
    jl set_pixel_done
;
    cmp cx,ds:v_x_max
    jg set_pixel_done
;
    cmp dx,ds:v_y_max
    jg set_pixel_done
;
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    imul edx
    shl eax,3
    mov edi,eax
    add edi,ecx
;
    mov ax,flat_sel
    mov es,ax
;    
    DrawStart 1
    mov eax,ds:v_color
    call ds:set_proc
    call DrawDone

set_pixel_done:
    add sp,10
    pop bp
    pop edi
    pop edx
    pop bx
    pop eax
    pop es
    pop ds
    ret
set_pixel       Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawMask
;
;           DESCRIPTION:    Draw a mask
; 
;           PARAMETER:          AX              source row size
;                           EBX             color
;                           ECX             source x + y << 16
;                           EDX             dest x + y << 16
;                           SI              width
;                           ES:EDI      1-bit mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_mask_line  Proc far
    ret
draw_mask_line  Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawSprite
;
;           DESCRIPTION:    Draw a sprite
; 
;           PARAMETER:          AL      mask offset bit
;               ECX             x + y << 16
;                           DX              width
;                           ESI             sprite data
;                           ES:EDI      1-bit mask bits for row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_sprite_line    Proc far
    push es
    push fs
    push gs
    pushad
    mov bp,sp
    sub sp,10
    mov [bp].curr_x,ecx
;
    mov bx,[bp].curr_y
    cmp bx,ds:v_y_min
    jl draw_sprite_done
;
    cmp bx,ds:v_y_max
    jg draw_sprite_done
;
    push ax
    push dx
    movsx ebx,cx
    ror ecx,16
    movsx edx,cx
    movzx eax,ds:v_row_size
    imul edx
    shl eax,3
    add ebx,eax
    xchg ebx,edi
    pop cx
    pop dx
    and dl,7
;    
    mov ax,es
    mov gs,ax
    mov ax,flat_sel
    mov es,ax
    mov fs,ax
    SpriteStart cx
    call ds:mask_copy_proc
    call SpriteDone

draw_sprite_done:
    add sp,10
    popad
    pop gs
    pop fs
    pop es
    ret
draw_sprite_line    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawString
;
;           DESCRIPTION:    Draw a string
; 
;           PARAMETER:          CX              x
;                           DX              y
;                           ES:EDI      string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ds_dest_y           EQU -12
ds_dest_x           EQU -14
ds_str_sel          EQU -16
ds_width            EQU -18
ds_new_x            EQU -20
ds_new_y            EQU -22

draw_string     Proc far
    push es
    push gs
    pushad
    mov bp,sp
    sub sp,22
;
    mov [bp].ds_str_sel,es
    mov [bp].curr_x,cx
    mov [bp].curr_y,dx
    mov [bp].ds_dest_x,cx
    mov [bp].ds_dest_y,dx

draw_string_loop:
    mov al,es:[edi]
    or al,al
    jz draw_string_ok
;
    push edi
;
    mov bx,ds:v_font
    GetUtf8Bitmap
    jc draw_string_char_next
;
    add si,[bp].ds_dest_x
    mov [bp].ds_new_x,si
;
    mov si,[bp].ds_dest_y    
    mov [bp].ds_new_y,si
;
    add [bp].ds_dest_x,ax
    add [bp].ds_dest_y,bx
;
    mov [bp].ds_width,cx
;       
    mov ax,es
    mov gs,ax
    mov ebx,edi
    mov ax,flat_sel
    mov es,ax
;       
    mov cx,dx
    or cx,cx
    jz draw_string_char_done
;
    movsx esi,word ptr [bp].ds_dest_x
    mov [bp].curr_x,si
    movsx edx,word ptr [bp].ds_dest_y
    mov [bp].curr_y,dx
    movzx eax,word ptr ds:v_row_size
    imul edx
    shl eax,3
    add eax,esi
    mov edi,eax

draw_string_char_loop:
    push cx
    mov cx,[bp].ds_width
    call AntiAlias
    pop cx
;
    movzx eax,ds:v_row_size
    shl eax,3
    add edi,eax
    movzx eax,word ptr [bp].ds_width
    add ebx,eax
    sub cx,1
    jnz draw_string_char_loop

draw_string_char_done:
    mov ax,[bp].ds_new_x
    mov [bp].ds_dest_x,ax
;
    mov ax,[bp].ds_new_y
    mov [bp].ds_dest_y,ax

draw_string_char_next:
    pop edi
    mov es,[bp].ds_str_sel
    mov al,es:[edi]
    or al,al
    jz draw_string_ok
;    
    inc edi
    mov ah,es:[edi]
    or ah,ah
    jz draw_string_ok
;
    test al,80h
    jz draw_string_loop
;
    inc edi
    test al,20h
    jz draw_string_loop
;
    inc edi
    mov ah,es:[edi]
    or ah,ah
    jz draw_string_ok
;
    test al,10h
    jz draw_string_loop
;
    inc edi
    mov ah,es:[edi]
    or ah,ah
    jnz draw_string_loop

draw_string_ok:
    clc

draw_string_done:
    add sp,22
    popad
    pop gs
    pop es
    ret
draw_string     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Drawline
;
;           DESCRIPTION:    Draw a line
; 
;           PARAMETER:          CX              x1
;                           DX              y1
;                           SI              x2
;                           DI              y2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dl_phys_add_x   EQU -14
dl_phys_add_y   EQU -18
dl_log_add_x    EQU -20
dl_log_add_y    EQU -22
dl_dx           EQU -24
dl_dy           EQU -26
dl_inc_low      EQU -28
dl_x2           EQU -30
dl_y2           EQU -32

draw_line       Proc far
    push ds
    push es
    pushad
    mov bp,sp
    sub sp,32
;
    cmp di,dx
    je line_horiz

line_bresen:
    jg line_bresen_magn_ok
;
    xchg cx,si
    xchg dx,di

line_bresen_magn_ok:
    cmp si,cx
    je line_vert
;
    jg line_bresen_check_pos

line_bresen_check_neg:
    cmp si,ds:v_x_max
    jg line_done
;
    cmp dx,ds:v_y_max
    jg line_done
;
    cmp cx,ds:v_x_min
    jl line_done
;
    cmp di,ds:v_y_min
    jl line_done
;
    jmp line_bresen_check_done

line_bresen_check_pos:
    cmp cx,ds:v_x_max
    jg line_done
;
    cmp dx,ds:v_y_max
    jg line_done
;
    cmp si,ds:v_x_min
    jl line_done
;
    cmp di,ds:v_y_min
    jl line_done

line_bresen_check_done:
    mov [bp].curr_x,cx
    mov [bp].curr_y,dx
;
    sub cx,si
    sub dx,di
;
    test ch,80h
    jz line_bresen_dx_pos

line_bresen_dx_neg:
    add cx,cx
    neg cx
    mov [bp].dl_dx,cx
    mov word ptr [bp].dl_log_add_x,1
    mov dword ptr [bp].dl_phys_add_x,1
    jmp line_bresen_dy

line_bresen_dx_pos:
    add cx,cx
    mov [bp].dl_dx,cx
    mov word ptr [bp].dl_log_add_x,-1
    mov dword ptr [bp].dl_phys_add_x,-1

line_bresen_dy:
    test dh,80h
    jz line_bresen_dy_pos

line_bresen_dy_neg:
    add dx,dx
    neg dx
    mov [bp].dl_dy,dx
    mov word ptr [bp].dl_log_add_y,1
    movzx ebx,ds:v_row_size
    shl ebx,3
    mov [bp].dl_phys_add_y,ebx
    jmp line_bresen_calc_inc

line_bresen_dy_pos:
    add dx,dx
    mov [bp].dl_dy,dx
    mov word ptr [bp].dl_log_add_y,-1
    movzx ebx,ds:v_row_size
    shl ebx,3
    neg ebx
    mov [bp].dl_phys_add_y,ebx

line_bresen_calc_inc:
    cmp cx,dx
    jb line_bresen_calc_dy_inc

line_bresen_calc_dx_inc:
    mov ax,cx
    shr ax,1
    sub ax,dx
    jmp line_bresen_calc_save

line_bresen_calc_dy_inc:
    mov ax,dx
    shr ax,1
    sub ax,cx

line_bresen_calc_save:
    neg ax
    mov [bp].dl_inc_low,ax
;
    mov cx,[bp].curr_x
    mov dx,[bp].curr_y
;
    cmp cx,si
    jne line_more_low
;
    cmp dx,di
    je line_done

line_more_low:
    cmp cx,ds:v_x_min
    jl line_skip_low
;
    cmp cx,ds:v_x_max
    jg line_skip_low
;
    cmp dx,ds:v_y_min
    jl line_skip_low
;
    cmp dx,ds:v_y_max
    jg line_skip_low
;
    jmp line_inrange_bresen

line_skip_low:
    mov ax,[bp].dl_dx
    cmp ax,[bp].dl_dy
    jb line_skip_dy_low

line_skip_dx_low:
    mov ax,[bp].dl_inc_low
    test ah,80h
    jnz line_skip_dx_fract_neg_low

line_skip_dx_fract_pos_low:
    mov ax,[bp].dl_dy
    sub [bp].dl_inc_low,ax
    add cx,[bp].dl_log_add_x
    cmp cx,si
    jne line_more_low
    jmp line_done

line_skip_dx_fract_neg_low:
    mov ax,[bp].dl_dx
    add [bp].dl_inc_low,ax
    add dx,[bp].dl_log_add_y
    jmp line_more_low

line_skip_dy_low:
    mov ax,[bp].dl_inc_low
    test ah,80h
    jnz line_skip_dy_fract_neg_low

line_skip_dy_fract_pos_low:
    mov ax,[bp].dl_dx
    sub [bp].dl_inc_low,ax
    add dx,[bp].dl_log_add_y
    cmp dx,di
    jne line_more_low
    jmp line_done

line_skip_dy_fract_neg_low:
    mov ax,[bp].dl_dy
    add [bp].dl_inc_low,ax
    add cx,[bp].dl_log_add_x
    jmp line_more_low

line_inrange_bresen:    
    mov [bp].curr_x,cx
    mov [bp].curr_y,dx
    mov [bp].dl_x2,si
    mov [bp].dl_y2,di
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    imul edx
    shl eax,3
    mov edi,eax
    add edi,ecx
;
    mov ax,flat_sel
    mov es,ax
    mov ax,[bp].dl_inc_low
    mov dx,[bp].curr_y
    cmp ds:v_sprite_count,0
    je line_bresen_no_sprite

line_bresen_sprite:
    mov bx,[bp].dl_dx
    cmp bx,[bp].dl_dy
    jb line_bresen_dy_sprite_next
    jmp line_bresen_dx_sprite_next

line_bresen_dx_sprite_loop:
    push ax
    DrawStart 1
    mov eax,ds:v_color
    call ds:set_proc
    call DrawDone
    pop ax
;
    cmp cx,[bp].dl_x2
    je line_done
;
    test ah,80h
    jnz line_bresen_dx_sprite_fract_neg

line_bresen_dx_sprite_fract_pos:
    add edi,[bp].dl_phys_add_x
    add cx,[bp].dl_log_add_x
    mov [bp].curr_x,cx
    sub ax,[bp].dl_dy
    jmp line_bresen_dx_sprite_next

line_bresen_dx_sprite_fract_neg:
    add edi,[bp].dl_phys_add_y
    add dx,[bp].dl_log_add_y
    mov [bp].curr_y,dx
    add ax,[bp].dl_dx

line_bresen_dx_sprite_next:
    cmp cx,ds:v_x_max
    jg line_done
;
    cmp cx,ds:v_x_min
    jl line_done
;
    cmp dx,ds:v_y_max
    jg line_done
;
    cmp dx,ds:v_y_min
    jl line_done
    jmp line_bresen_dx_sprite_loop

line_bresen_dy_sprite_loop:
    push ax
    DrawStart 1
    mov eax,ds:v_color
    call ds:set_proc
    call DrawDone
    pop ax
;
    cmp dx,[bp].dl_y2
    je line_done
;
    test ah,80h
    jnz line_bresen_dy_sprite_fract_neg

line_bresen_dy_sprite_fract_pos:
    add edi,[bp].dl_phys_add_y
    add dx,[bp].dl_log_add_y
    mov [bp].curr_y,dx
    sub ax,[bp].dl_dx
    jmp line_bresen_dy_sprite_next

line_bresen_dy_sprite_fract_neg:
    add edi,[bp].dl_phys_add_x
    add cx,[bp].dl_log_add_x
    mov [bp].curr_x,cx
    add ax,[bp].dl_dy

line_bresen_dy_sprite_next:
    cmp cx,ds:v_x_max
    jg line_done
;
    cmp cx,ds:v_x_min
    jl line_done
;
    cmp dx,ds:v_y_max
    jg line_done
;
    cmp dx,ds:v_y_min
    jl line_done
    jmp line_bresen_dy_sprite_loop

line_bresen_no_sprite:
    mov bx,[bp].dl_dx
    cmp bx,[bp].dl_dy
    jb line_bresen_dy_next
    jmp line_bresen_dx_next

line_bresen_dx_loop:
    push ax
    DrawStart 1
    mov eax,ds:v_color
    call ds:set_proc
    call DrawDone
    pop ax
;
    cmp cx,[bp].dl_x2
    je line_done
;
    test ah,80h
    jnz line_bresen_dx_fract_neg

line_bresen_dx_fract_pos:
    add edi,[bp].dl_phys_add_x
    add cx,[bp].dl_log_add_x
    mov [bp].curr_x,cx
    sub ax,[bp].dl_dy
    jmp line_bresen_dx_next

line_bresen_dx_fract_neg:
    add edi,[bp].dl_phys_add_y
    add dx,[bp].dl_log_add_y
    mov [bp].curr_y,dx
    add ax,[bp].dl_dx

line_bresen_dx_next:
    cmp cx,ds:v_x_max
    jg line_done
;
    cmp cx,ds:v_x_min
    jl line_done
;
    cmp dx,ds:v_y_max
    jg line_done
;
    cmp dx,ds:v_y_min
    jl line_done
    jmp line_bresen_dx_loop

line_bresen_dy_loop:
    push ax
    DrawStart 1
    mov eax,ds:v_color
    call ds:set_proc
    call DrawDone
    pop ax
;
    cmp dx,[bp].dl_y2
    je line_done
;
    test ah,80h
    jnz line_bresen_dy_fract_neg

line_bresen_dy_fract_pos:
    add edi,[bp].dl_phys_add_y
    add dx,[bp].dl_log_add_y
    mov [bp].curr_y,dx
    sub ax,[bp].dl_dx
    jmp line_bresen_dy_next

line_bresen_dy_fract_neg:
    add edi,[bp].dl_phys_add_x
    add cx,[bp].dl_log_add_x
    mov [bp].curr_x,cx
    add ax,[bp].dl_dy

line_bresen_dy_next:
    cmp cx,ds:v_x_max
    jg line_done
;
    cmp cx,ds:v_x_min
    jl line_done
;
    cmp dx,ds:v_y_max
    jg line_done
;
    cmp dx,ds:v_y_min
    jl line_done
    jmp line_bresen_dy_loop

line_vert:
    mov bx,di
    cmp bx,dx
    jae line_vert_do
;
    xchg bx,dx

line_vert_do:
    mov [bp].curr_x,cx
    mov [bp].curr_y,dx
;
    cmp cx,ds:v_x_max
    jg line_done
;
    cmp cx,ds:v_x_min
    jl line_done
;
    movsx ecx,cx
    movsx edx,dx
    sub bx,dx
    movzx eax,ds:v_row_size
    shl eax,3
    mov esi,eax
    imul edx
    mov edi,eax
    add edi,ecx
    mov cx,bx
    inc cx
    mov dx,flat_sel
    mov es,dx
    mov eax,ds:v_color
    cmp ds:v_sprite_count,0
    je line_vert_loop

line_vert_sprite_loop:
    mov dx,[bp].curr_y
    cmp dx,ds:v_y_min
    jl line_vert_sprite_next
;
    cmp dx,ds:v_y_max
    jg line_vert_sprite_next
;
    DrawStart 1
    call ds:set_proc
    call DrawDone

line_vert_sprite_next:
    add edi,esi
    inc word ptr [bp].curr_y
    sub cx,1
    jnz line_vert_sprite_loop
    jmp line_done

line_vert_loop:
    mov dx,[bp].curr_y
    cmp dx,ds:v_y_min
    jl line_vert_next
;
    cmp dx,ds:v_y_max
    jg line_vert_next
;
    DrawStart 1
    call ds:set_proc
    call DrawDone

line_vert_next:
    add edi,esi
    inc word ptr [bp].curr_y
    sub cx,1
    jnz line_vert_loop
    jmp line_done

line_horiz:
    mov ax,si
    cmp ax,cx
    jae line_horiz_do
;
    xchg ax,cx

line_horiz_do:
    mov [bp].curr_x,cx
    mov [bp].curr_y,dx
    movsx ecx,cx
    movsx edx,dx
    movsx ebx,ax
    movzx eax,ds:v_row_size
    imul edx
    shl eax,3
    mov edi,eax
    add edi,ecx
    sub cx,bx
    neg cx
    inc cx
    mov dx,flat_sel
    mov es,dx
    call FilledLine

line_done:
    add sp,32
    popad
    pop es
    pop ds
    ret
draw_line       Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawRect
;
;           DESCRIPTION:    Draw a rect
; 
;           PARAMETER:          CX              x
;                           DX              y
;                           SI              w
;                           DI              h
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rect_border_style_tab:
rb00 DW OFFSET FilledLine
rb01 DW OFFSET FilledLine

rect_mid_style_tab:
rm00 DW OFFSET HollowLine
rm01 DW OFFSET FilledLine

draw_rect       Proc far
    push ds
    push es
    pushad
    mov bp,sp
    sub sp,10
    mov [bp].curr_x,cx
    mov [bp].curr_y,dx
;
    or si,si
    jz rect_done
;
    or di,di
    jz rect_done
;
    push si
    push di
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    shl eax,3
    mov esi,eax
    imul edx
    mov edi,eax
    add edi,ecx
    pop dx
    pop cx
;
    mov ax,flat_sel
    mov es,ax
;
    movzx bx,ds:v_style
    add bx,bx
    call word ptr cs:[bx].rect_border_style_tab
    inc word ptr [bp].curr_y
    add edi,esi
    sub dx,1
    jz rect_done

rect_mid_loop:
    cmp dx,1
    je rect_bottom
;
    movzx bx,ds:v_style
    add bx,bx
    call word ptr cs:[bx].rect_mid_style_tab
    inc word ptr [bp].curr_y
    add edi,esi
    dec dx
    jmp rect_mid_loop

rect_bottom:
    movzx bx,ds:v_style
    add bx,bx
    call word ptr cs:[bx].rect_border_style_tab

rect_done:
    add sp,10
    popad
    pop es
    pop ds
    ret
draw_rect       Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawEllipse
;
;           DESCRIPTION:    Draw a ellipse
; 
;           PARAMETER:          CX              x
;                           DX              y
;                           SI              w
;                           DI              h
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

de_h2       EQU -14
de_w2       EQU -18
de_m        EQU -24
de_S        EQU -30
de_T        EQU -36
de_dSx      EQU -42
de_dTx      EQU -48
de_dSy      EQU -54
de_dTy      EQU -60
de_ddx      EQU -66
de_ddy      EQU -72
de_cnt      EQU -74
de_w        EQU -76
de_h        EQU -78
de_p0       EQU -82
de_p1       EQU -86
de_width    EQU -88
de_size     EQU -90
de_y0       EQU -92
de_y1       EQU -94

draw_mid_ellipse_hollow Proc near
    mov ax,[bp].de_y0
    mov [bp].curr_y,ax
    mov edi,[bp].de_p0
    mov ax,[bp].de_width
    mov cx,[bp].de_size
    call SplitLine
;
    mov ax,[bp].de_y1
    mov [bp].curr_y,ax
    mov edi,[bp].de_p1
    mov ax,[bp].de_width
    mov cx,[bp].de_size
    call SplitLine
;
    mov word ptr [bp].de_width,1
    ret
draw_mid_ellipse_hollow Endp

draw_mid_ellipse_filled Proc near
    mov ax,[bp].de_y0
    mov [bp].curr_y,ax
    mov edi,[bp].de_p0
    mov cx,[bp].de_size
    call FilledLine
;
    mov ax,[bp].de_y1
    mov [bp].curr_y,ax
    mov edi,[bp].de_p1
    mov cx,[bp].de_size
    call FilledLine
;
    mov word ptr [bp].de_width,1
    ret
draw_mid_ellipse_filled Endp

draw_last_ellipse_hollow    Proc near
    mov ax,[bp].de_y0
    mov [bp].curr_y,ax
    mov edi,[bp].de_p0
    mov ax,[bp].de_width
    mov cx,[bp].de_size
    call SplitLine
    ret
draw_last_ellipse_hollow    Endp

draw_last_ellipse_filled    Proc near
    mov ax,[bp].de_y0
    mov [bp].curr_y,ax
    mov edi,[bp].de_p0
    mov cx,[bp].de_size
    call FilledLine
    ret
draw_last_ellipse_filled    Endp

ellipse_mid_style_tab:
em00 DW OFFSET draw_mid_ellipse_hollow
em01 DW OFFSET draw_mid_ellipse_filled

ellipse_last_style_tab:
el00 DW OFFSET draw_last_ellipse_hollow
el01 DW OFFSET draw_last_ellipse_filled

draw_ellipse    Proc far
    push ds
    push es
    pushad
    mov bp,sp
    sub sp,94
;
    cmp si,2
    jbe ellipse_end
;
    cmp di,2
    jbe ellipse_end
;
    dec si
    shr si,1
    mov [bp].de_w,si
    mov word ptr [bp].de_width,1
    mov word ptr [bp].de_size,2
;
    dec di
    shr di,1
    mov [bp].de_h,di
    mov [bp].de_cnt,di
;
    add cx,si
    mov [bp].curr_x,cx
    mov [bp].de_y0,dx
    add dx,di
    add dx,di
    mov [bp].de_y1,dx
;
    mov ax,di
    mul di
    mov [bp].de_h2,ax
    mov [bp+2].de_h2,dx
;
    mov ax,si
    mul si
    mov [bp].de_w2,ax
    mov [bp+2].de_w2,dx
;
    movzx eax,word ptr [bp].de_h
    shl eax,1
    neg eax
    inc eax
    imul dword ptr [bp].de_w2
    mov [bp].de_m,eax
    mov [bp+4].de_m,dx
;
    mov eax,[bp].de_h2
    xor dx,dx
    add eax,eax
    adc dx,dx
    mov esi,eax
    mov di,dx
    add eax,eax
    adc dx,dx
    mov [bp].de_dTx,eax
    mov [bp+4].de_dTx,dx 
;
    add eax,esi
    adc dx,di
    mov [bp].de_dSx,eax
    mov [bp+4].de_dSx,dx
;
    mov eax,[bp].de_m
    mov dx,[bp+4].de_m
    add eax,[bp].de_w2
    adc dx,0
    add eax,eax
    adc dx,dx
    mov [bp].de_dSy,eax
    mov [bp+4].de_dSy,dx
;
    mov eax,[bp].de_w2
    xor dx,dx
    add eax,eax
    adc dx,dx
    add eax,[bp].de_dSy
    adc dx,[bp+4].de_dSy
    mov [bp].de_dTy,eax
    mov [bp+4].de_dTy,dx
;
    mov eax,[bp].de_h2
    xor dx,dx
    add eax,eax
    adc dx,dx
    add eax,[bp].de_m
    adc dx,[bp+4].de_m
    mov [bp].de_S,eax
    mov [bp+4].de_S,dx
;
    mov eax,[bp].de_m
    mov dx,[bp+4].de_m
    add eax,eax
    adc dx,dx
    add eax,[bp].de_h2
    adc dx,0
    mov [bp].de_T,eax
    mov [bp+4].de_T,dx
;
    mov eax,[bp].de_h2
    xor dx,dx
    add eax,eax
    adc dx,dx
    add eax,eax
    adc dx,dx
    mov [bp].de_ddx,eax
    mov [bp+4].de_ddx,dx
;
    mov eax,[bp].de_w2
    xor dx,dx
    add eax,eax
    adc dx,dx
    add eax,eax
    adc dx,dx
    mov [bp].de_ddy,eax
    mov [bp+4].de_ddy,dx
;
    movzx esi,ds:v_row_size
    shl esi,3
;
    movsx ecx,word ptr [bp].curr_x
    movsx edx,word ptr [bp].de_y0
    mov eax,esi
    imul edx
    mov edi,eax
    add edi,ecx
    mov [bp].de_p0,edi
;
    movsx ecx,word ptr [bp].curr_x
    movsx edx,word ptr [bp].de_y1
    mov eax,esi
    imul edx
    mov edi,eax
    add edi,ecx
    mov [bp].de_p1,edi
;
    mov ax,flat_sel
    mov es,ax

ellipse_loop:
    mov eax,[bp].de_S
    mov bx,[bp+4].de_S
    mov ecx,[bp].de_T
    mov dx,[bp+4].de_T
    test bh,80h
    jz ellipse_s_pos

ellipse_s_neg:
    add eax,[bp].de_dSx
    adc bx,[bp+4].de_dSx
    mov [bp].de_S,eax
    mov [bp+4].de_S,bx
;
    add ecx,[bp].de_dTx
    adc dx,[bp+4].de_dTx
    mov [bp].de_T,ecx
    mov [bp+4].de_T,dx
;
    mov eax,[bp].de_ddx
    mov dx,[bp+4].de_ddx
    add [bp].de_dSx,eax
    adc [bp+4].de_dSx,dx
    add [bp].de_dTx,eax
    adc [bp+4].de_dTx,dx
;
    dec word ptr [bp].curr_x
    dec dword ptr [bp].de_p0
    dec dword ptr [bp].de_p1
    inc word ptr [bp].de_width
    add word ptr [bp].de_size,2
    jmp ellipse_loop

ellipse_s_pos:
    test dh,80h
    jz ellipse_t_pos

ellipse_t_neg:
    add eax,[bp].de_dSx
    adc bx,[bp+4].de_dSx
    add eax,[bp].de_dSy
    adc bx,[bp+4].de_dSy
    mov [bp].de_S,eax
    mov [bp+4].de_S,bx
;
    add ecx,[bp].de_dTx
    adc dx,[bp+4].de_dTx
    add ecx,[bp].de_dTy
    adc dx,[bp+4].de_dTy
    mov [bp].de_T,ecx
    mov [bp+4].de_T,dx
;
    mov eax,[bp].de_ddx
    mov dx,[bp+4].de_ddx
    add [bp].de_dSx,eax
    adc [bp+4].de_dSx,dx
    add [bp].de_dTx,eax
    adc [bp+4].de_dTx,dx
;
    mov eax,[bp].de_ddy
    mov dx,[bp+4].de_ddy
    add [bp].de_dSy,eax
    adc [bp+4].de_dSy,dx
    add [bp].de_dTy,eax
    adc [bp+4].de_dTy,dx
;
    dec word ptr [bp].curr_x
    dec dword ptr [bp].de_p0
    dec dword ptr [bp].de_p1
    inc word ptr [bp].de_width
    add word ptr [bp].de_size,2
;
    movzx bx,ds:v_style
    add bx,bx
    call word ptr cs:[bx].ellipse_mid_style_tab
    inc word ptr [bp].de_y0
    dec word ptr [bp].de_y1
    add [bp].de_p0,esi
    sub [bp].de_p1,esi
;
    sub word ptr [bp].de_cnt,1
    jz ellipse_done
    jmp ellipse_loop

ellipse_t_pos:
    add eax,[bp].de_dSy
    adc bx,[bp+4].de_dSy
    mov [bp].de_S,eax
    mov [bp+4].de_S,bx
;
    add ecx,[bp].de_dTy
    adc dx,[bp+4].de_dTy
    mov [bp].de_T,ecx
    mov [bp+4].de_T,dx
;
    mov eax,[bp].de_ddy
    mov dx,[bp+4].de_ddy
    add [bp].de_dSy,eax
    adc [bp+4].de_dSy,dx
    add [bp].de_dTy,eax
    adc [bp+4].de_dTy,dx
;
    movzx bx,ds:v_style
    add bx,bx
    call word ptr cs:[bx].ellipse_mid_style_tab
    inc word ptr [bp].de_y0
    dec word ptr [bp].de_y1
    add [bp].de_p0,esi
    sub [bp].de_p1,esi
;
    sub word ptr [bp].de_cnt,1
    jnz ellipse_loop

ellipse_done:
    movzx bx,ds:v_style
    add bx,bx
    call word ptr cs:[bx].ellipse_last_style_tab

ellipse_end:
    add sp,94
    popad
    pop es
    pop ds
    ret
draw_ellipse    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Attr_to_color
;
;           DESCRIPTION:    Convert attribute to color
; 
;           PARAMETER:          AL          VGA color
;
;           RETURNS:        EAX         Color
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AttribColorTab:
act00   DD 0
act01   DD 0
act02   DD 0
act03   DD 1
act04   DD 0
act05   DD 1
act06   DD 1
act07   DD 1
act08   DD 1
act09   DD 1
act0A   DD 1
act0B   DD 1
act0C   DD 1
act0D   DD 1
act0E   DD 1
act0F   DD 1

attr_to_color   Proc near
    push bx
    mov bl,al
    and bx,0Fh
    shl bx,2
    mov eax,dword ptr cs:[bx].AttribColorTab    
    pop bx
    ret
attr_to_color   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Clear
;
;           DESCRIPTION:    Clear an area on screen
; 
;           PARAMETER:          BL          Fore color
;                           DH          Back color
;                           CX          Upper column
;                           DX          Upper row
;                           SI          Lower column
;                           DI          Lower row
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear   Proc far
    clc
    ret
clear   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetCursorPos
;
;           DESCRIPTION:    Set cursor position
; 
;           PARAMETER:          CX          Column
;                           DX          Row
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cursor_pos  Proc far
    clc
    ret
set_cursor_pos  Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteChar
;
;           DESCRIPTION:    Write a character
; 
;           PARAMETER:          AL          Character
;                           BL          Fore color
;                           BH          Back color
;                           CX          Column
;                           DX          Row
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_char      Proc far
    push es
    pushad
    push ds:v_font
    push ds:v_color
    push ds:v_lgop
;
    push ax
    push dx
    movzx edx,dx
    movzx eax,ds:v_col_count
    mul edx
    movzx esi,cx
    add esi,eax
    add esi,esi
    mov es,ds:v_text
    pop dx  
    pop ax
;
    and bx,0F0Fh
    shl bh,4
    mov ah,bl
    or ah,bh
    cmp ax,es:[esi]
    je write_char_done
;
    mov es:[esi],ax
;
    mov ds:v_lgop, LGOP_NONE
    xor ah,ah
    push ax
;
    mov ax,dx
    mul ds:v_pixels_per_row
;
    push ax
    mov ax,cx
    mul ds:v_pixels_per_col
    mov cx,ax
    pop dx
;
    mov al,ds:v_style
    push ax
;
    mov ds:v_style,STYLE_FILLED
    mov al,bh
    shr al,4
    call attr_to_color
    mov ds:v_color,eax
;
    mov si,ds:v_pixels_per_col
    mov di,ds:v_pixels_per_row
    call ds:draw_rect_proc
;
    pop ax
    mov ds:v_style,al
;
    mov al,bl
    call attr_to_color
    mov ds:v_color,eax
    mov ax,ds:v_text_font
    mov ds:v_font,ax
    mov ax,ss
    mov es,ax
    movzx edi,sp
    call ds:draw_string_proc
;       
    add sp,2

write_char_done:
    pop ds:v_lgop
    pop ds:v_color
    pop ds:v_font
    popad
    pop es
    ret
write_char      Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReadChar
;
;           DESCRIPTION:    Read a character
; 
;           PARAMETER:          CX          Column
;                           DX          Row
;
;           RETURNS:        AL          Character
;                           BL          Fore color
;                           BH          Back color
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_char       Proc far
    push es
    push edx
    push esi
;
    movzx edx,dx
    movzx eax,ds:v_col_count
    mul edx
    movzx esi,cx
    add esi,eax
    add esi,esi
    mov es,ds:v_text
    mov ax,es:[esi]
    mov bl,ah
    mov bh,ah
    shr bh,4
    and bx,0F0Fh
    clc
;
    pop esi
    pop edx
    pop es
    ret
read_char       Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ScrollUp
;
;           DESCRIPTION:    Scroll screen area up
; 
;           PARAMETER:          AX          Number of lines
;                           BL          Blank for color
;                           BH          Blank back color
;                           CX          Upper column
;                           DX          Upper row
;                           SI          Lower column
;                           DI          Lower row
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

scroll_up       Proc far
    clc
    ret
scroll_up       Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ScrollDown
;
;           DESCRIPTION:    Scroll screen area down
; 
;           PARAMETER:          AX          Number of lines
;                           BL          Blank for color
;                           BH          Blank back color
;                           CX          Upper column
;                           DX          Upper row
;                           SI          Lower column
;                           DI          Lower row
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

scroll_down     Proc far
    clc
    ret
scroll_down     Endp

errorp  Proc far
    stc
    ret
errorp  Endp

    public BitmapTab1

BitmapTab1:
mt00 DW OFFSET errorp,              SEG code
mt01 DW OFFSET errorp,              SEG code
mt02 DW OFFSET errorp,              SEG code
mt03 DW OFFSET clear,               SEG code
mt04 DW OFFSET set_cursor_pos,      SEG code
mt05 DW OFFSET write_char,              SEG code
mt06 DW OFFSET read_char,               SEG code
mt07 DW OFFSET scroll_up,               SEG code
mt08 DW OFFSET scroll_down,             SEG code
mt09 DW OFFSET errorp,              SEG code
mt0A DW OFFSET errorp,              SEG code
mt0B DW OFFSET errorp,              SEG code
mt0C DW OFFSET errorp,              SEG code
mt0D DW OFFSET errorp,              SEG code
mt0E DW OFFSET errorp,              SEG code
mt0F DW OFFSET translate_color,     SEG code
mt10 DW OFFSET set_base,            SEG code
mt11 DW OFFSET slab,                SEG code
mt12 DW OFFSET copy,                SEG code
mt13 DW OFFSET mask_set,        SEG code
mt14 DW OFFSET mask_copy,               SEG code
mt15 DW OFFSET get_line,            SEG code
mt16 DW OFFSET get_pixel,               SEG code
mt17 DW OFFSET set_pixel,               SEG code
mt18 DW OFFSET get_native,          SEG code
mt19 DW OFFSET get_rgb,             SEG code
mt1A DW OFFSET set_native,              SEG code
mt1B DW OFFSET set_rgb,             SEG code
mt1C DW OFFSET draw_mask_line,      SEG code
mt1D DW OFFSET set_sprite,              SEG code
mt1E DW OFFSET draw_sprite_line,    SEG code
mt1F DW OFFSET draw_string,             SEG code
mt20 DW OFFSET draw_line,               SEG code
mt21 DW OFFSET draw_rect,               SEG code
mt22 DW OFFSET draw_ellipse,        SEG code
mt23 DW OFFSET anti_alias_set,      SEG code
mt24 DW OFFSET phys_update,         SEG code

code    ENDS

    END

