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
; BIT1.ASM
; Linear 1-bit graphics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE video.inc

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
    mov cx,[ebp].curr_x
    mov dx,[ebp].curr_y
    HideSpriteLine
    pop dx
    pop cx
    pop ax

done:
    mov [ebp].curr_start,edi
    mov word ptr [ebp].curr_size,reg
            ENDM

;
; reg = number of pixels
; EDI = line buffer
;

SpriteStart MACRO reg
    mov [ebp].curr_start,edi
    mov word ptr [ebp].curr_size,reg
            ENDM

code    SEGMENT byte public 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;               Global parameter usage
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


curr_start  EQU -12
curr_size   EQU -8
curr_x      EQU -6
curr_y      EQU -4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           PhysUpdate
;
;           DESCRIPTION:    Do a physical update on real hardware
;
;           PARAMETERS:     ECX         Pixels
;                           EDI         Pixel #
;                           ES:ESI      Bitmap
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
    mov esi,ds:v_phys_base
    movzx ecx,word ptr [ebp].curr_size
    mov edi,[ebp].curr_start
    call fword ptr ds:v_phys_update_proc
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
    mov esi,ds:v_phys_base
    movzx ecx,word ptr [ebp].curr_size
    mov edi,[ebp].curr_start
    call fword ptr ds:v_phys_update_proc
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
lgt00   DD OFFSET LgopNull
lgt01   DD OFFSET LgopNorm
lgt02   DD OFFSET LgopOr
lgt03   DD OFFSET LgopAnd
lgt04   DD OFFSET LgopXor
lgt05   DD OFFSET LgopInvert
lgt06   DD OFFSET LgopInvertOr
lgt07   DD OFFSET LgopInvertAnd
lgt08   DD OFFSET LgopInvertXor
lgt09   DD OFFSET LgopOr
lgt0A   DD OFFSET LgopAnd
lgt0B   DD OFFSET LgopAnd
lgt0C   DD OFFSET LgopNull
lgt0D   DD OFFSET LgopNull
lgt0E   DD OFFSET LgopNull
lgt0F   DD OFFSET LgopNull


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
    push ebx
    movzx ebx,ds:v_lgop
    shl ebx,2
    call dword ptr cs:[ebx].LgopTab
    pop ebx
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
    mov al,byte ptr cs:[ebx].or_bit_tab
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
    sub cx,1
    jnz slab_set_last_loop

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
    mov al,byte ptr cs:[ebx].and_bit_tab
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
    sub cx,1
    jnz slab_reset_last_loop

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
    mov al,byte ptr cs:[ebx].or_bit_tab
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
    sub cx,1
    jnz slab_compl_last_loop

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
st00    DD OFFSET SlabNull
st01    DD OFFSET SlabNorm
st02    DD OFFSET SlabOr
st03    DD OFFSET SlabAnd
st04    DD OFFSET SlabXor
st05    DD OFFSET SlabInvert
st06    DD OFFSET SlabInvertOr
st07    DD OFFSET SlabInvertAnd
st08    DD OFFSET SlabInvertXor
st09    DD OFFSET SlabOr
st0A    DD OFFSET SlabAnd
st0B    DD OFFSET SlabAnd
st0C    DD OFFSET SlabNull
st0D    DD OFFSET SlabNull
st0E    DD OFFSET SlabNull
st0F    DD OFFSET SlabNull



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
    push ebx
    movzx ebx,ds:v_lgop
    shl ebx,2
    call dword ptr cs:[ebx].SlabTab
    pop ebx
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
    sub cx,1
    jnz copy_norm_loop

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
    sub cx,1
    jnz copy_and_loop

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
    sub cx,1
    jnz copy_or_loop

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
    sub cx,1
    jnz copy_xor_loop

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
    sub cx,1
    jnz copy_inv_loop

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
    sub cx,1
    jnz copy_inv_and_loop

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
    sub cx,1
    jnz copy_inv_or_loop

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
    sub cx,1
    jnz copy_inv_xor_loop

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
ct00    DD OFFSET CopyNull
ct01    DD OFFSET CopyNorm
ct02    DD OFFSET CopyOr
ct03    DD OFFSET CopyAnd
ct04    DD OFFSET CopyXor
ct05    DD OFFSET CopyInvert
ct06    DD OFFSET CopyInvertOr
ct07    DD OFFSET CopyInvertAnd
ct08    DD OFFSET CopyInvertXor
ct09    DD OFFSET CopyOr
ct0A    DD OFFSET CopyAnd
ct0B    DD OFFSET CopyAnd
ct0C    DD OFFSET CopyNull
ct0D    DD OFFSET CopyNull
ct0E    DD OFFSET CopyNull
ct0F    DD OFFSET CopyNull



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
    push ebx
    push edx
;
    mov edx,ds:v_app_base
    movzx ebx,ds:v_lgop
    shl ebx,2
    call dword ptr cs:[ebx].CopyTab
;
    pop edx
    pop ebx
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
    sub cx,1
    jnz mask_set_norm_set_loop
    jmp mask_set_norm_done

mask_set_norm_reset_loop:
    bt gs:[ebp],esi
    jnc mask_set_norm_reset_next
;
    btr es:[edx],edi

mask_set_norm_reset_next:
    inc esi
    inc edi
    sub cx,1
    jnz mask_set_norm_reset_loop

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
    sub cx,1
    jnz mask_set_and_loop

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
    sub cx,1
    jnz mask_set_or_loop

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
    sub cx,1
    jnz mask_set_xor_loop

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
    sub cx,1
    jnz mask_set_inv_set_loop
    jmp mask_set_inv_done

mask_set_inv_reset_loop:
    bt gs:[ebp],esi
    jnc mask_set_inv_reset_next
;
    btr es:[edx],edi

mask_set_inv_reset_next:
    inc esi
    inc edi
    sub cx,1
    jnz mask_set_inv_reset_loop

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
    sub cx,1
    jnz mask_set_inv_and_loop

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
    sub cx,1
    jnz mask_set_inv_or_loop

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
    sub cx,1
    jnz mask_set_inv_xor_loop

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
mst00   DD OFFSET MaskSetNull
mst01   DD OFFSET MaskSetNorm
mst02   DD OFFSET MaskSetOr
mst03   DD OFFSET MaskSetAnd
mst04   DD OFFSET MaskSetXor
mst05   DD OFFSET MaskSetInvert
mst06   DD OFFSET MaskSetInvertOr
mst07   DD OFFSET MaskSetInvertAnd
mst08   DD OFFSET MaskSetInvertXor
mst09   DD OFFSET MaskSetOr
mst0A   DD OFFSET MaskSetAnd
mst0B   DD OFFSET MaskSetAnd
mst0C   DD OFFSET MaskSetNull
mst0D   DD OFFSET MaskSetNull
mst0E   DD OFFSET MaskSetNull
mst0F   DD OFFSET MaskSetNull



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
    push ebx
    push edx
    push esi
    push ebp
;
    mov ebp,ebx
    movzx esi,dl
    mov edx,ds:v_app_base
;
    movzx ebx,ds:v_lgop
    shl ebx,2
    call dword ptr cs:[ebx].MaskSetTab
;
    pop ebp
    pop esi
    pop edx
    pop ebx
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
    push ebx
;
    bt fs:[esi],ebx
    jc mask_copy_set
;
    xor eax,eax
    jmp mask_copy_do

mask_copy_set:
    mov eax,1

mask_copy_do:
    movzx ebx,ds:v_lgop
    shl ebx,2
    call dword ptr cs:[ebx].LgopTab
;
    pop ebx

mask_copy_next:
    inc ebx
    inc edi
    sub cx,1
    jnz mask_copy_loop
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
    sub cx,1
    jnz mask_copy_none_loop

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
    push ebx
    movzx ebx,ds:v_lgop
    shl ebx,2
    call dword ptr cs:[ebx].LgopTab
    pop ebx

anti_alias_set_line_next:
    pop cx
    inc edi
    inc word ptr [ebp].curr_x
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
    push word ptr [ebp].curr_x
    push ebx
    push cx
    push si
    push edi
;
    or cx,cx
    jz aa_done
;    
    mov ax,[ebp].curr_y
    cmp ax,ds:v_y_min
    jl aa_done
;
    cmp ax,ds:v_y_max
    jg aa_done
;
    mov ax,[ebp].curr_x
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
    call fword ptr ds:v_anti_alias_proc
    call DrawDone

aa_done:
    pop edi
    pop si
    pop cx
    pop ebx
    pop word ptr [ebp].curr_x
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
    push word ptr [ebp].curr_x
    push cx
    push edi
;
    mov ax,[ebp].curr_y
    cmp ax,ds:v_y_min
    jl hollow_line_done
;
    cmp ax,ds:v_y_max
    jg hollow_line_done
;
    mov ax,[ebp].curr_x
    cmp ax,ds:v_x_max
    jg hollow_line_done
;
    cmp ax,ds:v_x_min
    jl hollow_line_first_done
;
    DrawStart 1
    mov eax,ds:v_color
    call fword ptr ds:v_set_proc
    call DrawDone

hollow_line_first_done:
    mov ax,cx
    dec ax
    movsx eax,ax
    add edi,eax
;
    mov ax,[ebp].curr_x
    add ax,cx
    dec ax
    mov [ebp].curr_x,ax
    cmp ax,ds:v_x_min
    jl hollow_line_done
;
    cmp ax,ds:v_x_max
    jg hollow_line_done
;
    DrawStart 1
    mov eax,ds:v_color
    call fword ptr ds:v_set_proc
    call DrawDone

hollow_line_done:
    pop edi
    pop cx
    pop word ptr [ebp].curr_x
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
    push word ptr [ebp].curr_x
    push cx
    push edi
;
    mov ax,[ebp].curr_y
    cmp ax,ds:v_y_min
    jl filled_line_done
;
    cmp ax,ds:v_y_max
    jg filled_line_done
;
    mov ax,[ebp].curr_x
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
    mov [ebp].curr_x,ax
;    
    DrawStart cx
    mov eax,ds:v_color
    call fword ptr ds:v_slab_proc
    call DrawDone

filled_line_done:
    pop edi
    pop cx
    pop word ptr [ebp].curr_x
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
    push word ptr [ebp].curr_x
    push cx
    push dx
    push edi
;
    mov bx,[ebp].curr_y
    cmp bx,ds:v_y_min
    jl split_line_done
;
    cmp bx,ds:v_y_max
    jg split_line_done
;
    mov bx,[ebp].curr_x
    cmp bx,ds:v_x_max
    jg split_line_done
;
    sub cx,ax
    sub cx,ax
    mov dx,ax
;
    push cx
    mov cx,dx

split_left_loop:
    mov bx,[ebp].curr_x
    cmp bx,ds:v_x_min
    jl split_left_next
;
    cmp bx,ds:v_x_max
    jg split_left_next
;
    DrawStart 1
    mov eax,ds:v_color
    call fword ptr ds:v_set_proc
    call DrawDone

split_left_next:
    inc word ptr [ebp].curr_x
    inc edi
    sub cx,1
    jnz split_left_loop
;
    pop cx
    add [ebp].curr_x,cx
;
    movsx eax,cx
    add edi,eax
;
    mov cx,dx

split_right_loop:
    mov bx,[ebp].curr_x
    cmp bx,ds:v_x_min
    jl split_right_next
;
    cmp bx,ds:v_x_max
    jg split_right_next
;
    DrawStart 1
    mov eax,ds:v_color
    call fword ptr ds:v_set_proc
    call DrawDone

split_right_next:
    inc word ptr [ebp].curr_x
    inc edi
    sub cx,1
    jnz split_right_loop

split_line_done:
    pop edi
    pop dx
    pop cx
    pop word ptr [ebp].curr_x
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
;           NAME:           GetAlpha
;
;           DESCRIPTION:    Get pixels in RGBA format
;
;           PARAMETER:      AX              number of pixels
;                           CX              x
;                           DX              y
;                           ES:EDI      line buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_alpha Proc far
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
    jz get_rgba_done
;
    lods byte ptr [esi]
    shr al,cl
    mov ch,8
    sub ch,cl

get_rgba_loop:
    rcr al,1
    jc get_rgba_set

get_rgba_reset:
    mov dword ptr es:[edi],0FF000000h
    jmp get_rgba_next

get_rgba_set:
    mov dword ptr es:[edi],0FFFFFFFFh

get_rgba_next:
    add edi,4
    sub dx,1
    jz get_rgba_done
;
    sub ch,1
    jnz get_rgba_loop
;
    lods byte ptr [esi]
    mov ch,8
    jmp get_rgba_loop

get_rgba_done:
    popad
    pop ds
    ret
get_alpha Endp



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
    mov ebp,esp
    sub esp,12
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
    call fword ptr ds:v_set_proc
;
    inc ebx
    inc edi
    sub cx,1
    jnz set_native_loop
;
    call DrawDone

set_native_done:
    add esp,12
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
    mov ebp,esp
    sub esp,12
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
    call fword ptr ds:v_set_proc
;
    add esi,4
    inc edi
    sub cx,1
    jnz set_rgb_loop
;
    call DrawDone

set_rgb_done:
    add esp,12
    popad
    pop fs
    pop es
    pop ds
    ret
set_rgb Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetAlpha
;
;           DESCRIPTION:    Set pixels in RGBA format
;
;           PARAMETER:      AX              number of pixels
;                           CX              x
;                           DX              y
;                           ES:EDI      line buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_alpha Proc far
    push ds
    push es
    push fs
    pushad
    mov ebp,esp
    sub esp,12
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
    jz set_rgba_done
;
    DrawStart cx

set_rgba_loop:
    mov eax,fs:[esi]
    movzx dx,al
    shr eax,8
    add dl,al
    adc dh,0
    shr eax,8
    add dl,al
    adc dh,0
    shr eax,8
    cmp al,80h
    jb set_rgba_zero
;
    cmp dx,3 * 128
    jc set_rgba_zero
;
    mov eax,1
    jmp set_rgba_do

set_rgba_zero:
    xor eax,eax

set_rgba_do:
    call fword ptr ds:v_set_proc
;
    add esi,4
    inc edi
    sub cx,1
    jnz set_rgba_loop
;
    call DrawDone

set_rgba_done:
    add esp,12
    popad
    pop fs
    pop es
    pop ds
    ret
set_alpha Endp



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
    mov ebp,esp
    sub esp,12
    mov [ebp].curr_x,cx
    mov [ebp].curr_y,dx
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
    call fword ptr ds:v_copy_proc
    call SpriteDone

set_sprite_done:
    add esp,12
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
    push ebp
    mov ebp,esp
    sub esp,12
    mov [ebp].curr_x,cx
    mov [ebp].curr_y,dx
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
    call fword ptr ds:v_set_proc
    call DrawDone

set_pixel_done:
    add esp,12
    pop ebp
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
    mov ebp,esp
    sub esp,12
    mov [ebp].curr_x,ecx
;
    mov bx,[ebp].curr_y
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
    call fword ptr ds:v_mask_copy_proc
    call SpriteDone

draw_sprite_done:
    add esp,12
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


ds_dest_y           EQU -14
ds_dest_x           EQU -16
ds_str_sel          EQU -18
ds_width            EQU -20
ds_new_x            EQU -22
ds_new_y            EQU -24

draw_string     Proc far
    push es
    push gs
    pushad
    mov ebp,esp
    sub esp,24
;
    mov [ebp].ds_str_sel,es
    mov [ebp].curr_x,cx
    mov [ebp].curr_y,dx
    mov [ebp].ds_dest_x,cx
    mov [ebp].ds_dest_y,dx

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
    add si,[ebp].ds_dest_x
    mov [ebp].ds_new_x,si
;
    mov si,[ebp].ds_dest_y    
    mov [ebp].ds_new_y,si
;
    add [ebp].ds_dest_x,ax
    add [ebp].ds_dest_y,bx
;
    mov [ebp].ds_width,cx
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
    movsx esi,word ptr [ebp].ds_dest_x
    mov [ebp].curr_x,si
    movsx edx,word ptr [ebp].ds_dest_y
    mov [ebp].curr_y,dx
    movzx eax,word ptr ds:v_row_size
    imul edx
    shl eax,3
    add eax,esi
    mov edi,eax

draw_string_char_loop:
    push cx
    mov cx,[ebp].ds_width
    call AntiAlias
    pop cx
;
    inc word ptr [ebp].curr_y
    movzx eax,ds:v_row_size
    shl eax,3
    add edi,eax
    movzx eax,word ptr [ebp].ds_width
    add ebx,eax
    sub cx,1
    jnz draw_string_char_loop

draw_string_char_done:
    mov ax,[ebp].ds_new_x
    mov [ebp].ds_dest_x,ax
;
    mov ax,[ebp].ds_new_y
    mov [ebp].ds_dest_y,ax

draw_string_char_next:
    pop edi
    mov es,[ebp].ds_str_sel
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
    add esp,24
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

dl_phys_add_x   EQU -16
dl_phys_add_y   EQU -20
dl_log_add_x    EQU -22
dl_log_add_y    EQU -24
dl_dx           EQU -26
dl_dy           EQU -28
dl_inc_low      EQU -30
dl_x2           EQU -32
dl_y2           EQU -34

draw_line       Proc far
    push ds
    push es
    pushad
    mov ebp,esp
    sub esp,36
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
    mov [ebp].curr_x,cx
    mov [ebp].curr_y,dx
;
    sub cx,si
    sub dx,di
;
    test ch,80h
    jz line_bresen_dx_pos

line_bresen_dx_neg:
    add cx,cx
    neg cx
    mov [ebp].dl_dx,cx
    mov word ptr [ebp].dl_log_add_x,1
    mov dword ptr [ebp].dl_phys_add_x,1
    jmp line_bresen_dy

line_bresen_dx_pos:
    add cx,cx
    mov [ebp].dl_dx,cx
    mov word ptr [ebp].dl_log_add_x,-1
    mov dword ptr [ebp].dl_phys_add_x,-1

line_bresen_dy:
    test dh,80h
    jz line_bresen_dy_pos

line_bresen_dy_neg:
    add dx,dx
    neg dx
    mov [ebp].dl_dy,dx
    mov word ptr [ebp].dl_log_add_y,1
    movzx ebx,ds:v_row_size
    shl ebx,3
    mov [ebp].dl_phys_add_y,ebx
    jmp line_bresen_calc_inc

line_bresen_dy_pos:
    add dx,dx
    mov [ebp].dl_dy,dx
    mov word ptr [ebp].dl_log_add_y,-1
    movzx ebx,ds:v_row_size
    shl ebx,3
    neg ebx
    mov [ebp].dl_phys_add_y,ebx

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
    mov [ebp].dl_inc_low,ax
;
    mov cx,[ebp].curr_x
    mov dx,[ebp].curr_y
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
    mov ax,[ebp].dl_dx
    cmp ax,[ebp].dl_dy
    jb line_skip_dy_low

line_skip_dx_low:
    mov ax,[ebp].dl_inc_low
    test ah,80h
    jnz line_skip_dx_fract_neg_low

line_skip_dx_fract_pos_low:
    mov ax,[ebp].dl_dy
    sub [ebp].dl_inc_low,ax
    add cx,[ebp].dl_log_add_x
    cmp cx,si
    jne line_more_low
    jmp line_done

line_skip_dx_fract_neg_low:
    mov ax,[ebp].dl_dx
    add [ebp].dl_inc_low,ax
    add dx,[ebp].dl_log_add_y
    jmp line_more_low

line_skip_dy_low:
    mov ax,[ebp].dl_inc_low
    test ah,80h
    jnz line_skip_dy_fract_neg_low

line_skip_dy_fract_pos_low:
    mov ax,[ebp].dl_dx
    sub [ebp].dl_inc_low,ax
    add dx,[ebp].dl_log_add_y
    cmp dx,di
    jne line_more_low
    jmp line_done

line_skip_dy_fract_neg_low:
    mov ax,[ebp].dl_dy
    add [ebp].dl_inc_low,ax
    add cx,[ebp].dl_log_add_x
    jmp line_more_low

line_inrange_bresen:    
    mov [ebp].curr_x,cx
    mov [ebp].curr_y,dx
    mov [ebp].dl_x2,si
    mov [ebp].dl_y2,di
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
    mov ax,[ebp].dl_inc_low
    mov dx,[ebp].curr_y
    cmp ds:v_sprite_count,0
    je line_bresen_no_sprite

line_bresen_sprite:
    mov bx,[ebp].dl_dx
    cmp bx,[ebp].dl_dy
    jb line_bresen_dy_sprite_next
    jmp line_bresen_dx_sprite_next

line_bresen_dx_sprite_loop:
    push ax
    DrawStart 1
    mov eax,ds:v_color
    call fword ptr ds:v_set_proc
    call DrawDone
    pop ax
;
    cmp cx,[ebp].dl_x2
    je line_done
;
    test ah,80h
    jnz line_bresen_dx_sprite_fract_neg

line_bresen_dx_sprite_fract_pos:
    add edi,[ebp].dl_phys_add_x
    add cx,[ebp].dl_log_add_x
    mov [ebp].curr_x,cx
    sub ax,[ebp].dl_dy
    jmp line_bresen_dx_sprite_next

line_bresen_dx_sprite_fract_neg:
    add edi,[ebp].dl_phys_add_y
    add dx,[ebp].dl_log_add_y
    mov [ebp].curr_y,dx
    add ax,[ebp].dl_dx

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
    call fword ptr ds:v_set_proc
    call DrawDone
    pop ax
;
    cmp dx,[ebp].dl_y2
    je line_done
;
    test ah,80h
    jnz line_bresen_dy_sprite_fract_neg

line_bresen_dy_sprite_fract_pos:
    add edi,[ebp].dl_phys_add_y
    add dx,[ebp].dl_log_add_y
    mov [ebp].curr_y,dx
    sub ax,[ebp].dl_dx
    jmp line_bresen_dy_sprite_next

line_bresen_dy_sprite_fract_neg:
    add edi,[ebp].dl_phys_add_x
    add cx,[ebp].dl_log_add_x
    mov [ebp].curr_x,cx
    add ax,[ebp].dl_dy

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
    mov bx,[ebp].dl_dx
    cmp bx,[ebp].dl_dy
    jb line_bresen_dy_next
    jmp line_bresen_dx_next

line_bresen_dx_loop:
    push ax
    DrawStart 1
    mov eax,ds:v_color
    call fword ptr ds:v_set_proc
    call DrawDone
    pop ax
;
    cmp cx,[ebp].dl_x2
    je line_done
;
    test ah,80h
    jnz line_bresen_dx_fract_neg

line_bresen_dx_fract_pos:
    add edi,[ebp].dl_phys_add_x
    add cx,[ebp].dl_log_add_x
    mov [ebp].curr_x,cx
    sub ax,[ebp].dl_dy
    jmp line_bresen_dx_next

line_bresen_dx_fract_neg:
    add edi,[ebp].dl_phys_add_y
    add dx,[ebp].dl_log_add_y
    mov [ebp].curr_y,dx
    add ax,[ebp].dl_dx

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
    call fword ptr ds:v_set_proc
    call DrawDone
    pop ax
;
    cmp dx,[ebp].dl_y2
    je line_done
;
    test ah,80h
    jnz line_bresen_dy_fract_neg

line_bresen_dy_fract_pos:
    add edi,[ebp].dl_phys_add_y
    add dx,[ebp].dl_log_add_y
    mov [ebp].curr_y,dx
    sub ax,[ebp].dl_dx
    jmp line_bresen_dy_next

line_bresen_dy_fract_neg:
    add edi,[ebp].dl_phys_add_x
    add cx,[ebp].dl_log_add_x
    mov [ebp].curr_x,cx
    add ax,[ebp].dl_dy

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
    mov [ebp].curr_x,cx
    mov [ebp].curr_y,dx
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
    mov dx,[ebp].curr_y
    cmp dx,ds:v_y_min
    jl line_vert_sprite_next
;
    cmp dx,ds:v_y_max
    jg line_vert_sprite_next
;
    DrawStart 1
    call fword ptr ds:v_set_proc
    call DrawDone

line_vert_sprite_next:
    add edi,esi
    inc word ptr [ebp].curr_y
    sub cx,1
    jnz line_vert_sprite_loop
    jmp line_done

line_vert_loop:
    mov dx,[ebp].curr_y
    cmp dx,ds:v_y_min
    jl line_vert_next
;
    cmp dx,ds:v_y_max
    jg line_vert_next
;
    DrawStart 1
    call fword ptr ds:v_set_proc
    call DrawDone

line_vert_next:
    add edi,esi
    inc word ptr [ebp].curr_y
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
    mov [ebp].curr_x,cx
    mov [ebp].curr_y,dx
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
    add esp,36
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
rb00 DD OFFSET FilledLine
rb01 DD OFFSET FilledLine

rect_mid_style_tab:
rm00 DD OFFSET HollowLine
rm01 DD OFFSET FilledLine

draw_rect       Proc far
    push ds
    push es
    pushad
    mov ebp,esp
    sub esp,12
    mov [ebp].curr_x,cx
    mov [ebp].curr_y,dx
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
    movzx ebx,ds:v_style
    shl ebx,2
    call dword ptr cs:[ebx].rect_border_style_tab
    inc word ptr [ebp].curr_y
    add edi,esi
    sub dx,1
    jz rect_done

rect_mid_loop:
    cmp dx,1
    je rect_bottom
;
    movzx ebx,ds:v_style
    shl ebx,2
    call dword ptr cs:[ebx].rect_mid_style_tab
    inc word ptr [ebp].curr_y
    add edi,esi
    dec dx
    jmp rect_mid_loop

rect_bottom:
    movzx ebx,ds:v_style
    shl ebx,2
    call dword ptr cs:[ebx].rect_border_style_tab

rect_done:
    add esp,12
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

de_h2       EQU -16
de_w2       EQU -20
de_m        EQU -26
de_S        EQU -32
de_T        EQU -38
de_dSx      EQU -44
de_dTx      EQU -50
de_dSy      EQU -56
de_dTy      EQU -62
de_ddx      EQU -68
de_ddy      EQU -74
de_cnt      EQU -76
de_w        EQU -78
de_h        EQU -80
de_p0       EQU -84
de_p1       EQU -88
de_width    EQU -90
de_size     EQU -92
de_y0       EQU -94
de_y1       EQU -96

draw_mid_ellipse_hollow Proc near
    mov ax,[ebp].de_y0
    mov [ebp].curr_y,ax
    mov edi,[ebp].de_p0
    mov ax,[ebp].de_width
    mov cx,[ebp].de_size
    call SplitLine
;
    mov ax,[ebp].de_y1
    mov [ebp].curr_y,ax
    mov edi,[ebp].de_p1
    mov ax,[ebp].de_width
    mov cx,[ebp].de_size
    call SplitLine
;
    mov word ptr [ebp].de_width,1
    ret
draw_mid_ellipse_hollow Endp

draw_mid_ellipse_filled Proc near
    mov ax,[ebp].de_y0
    mov [ebp].curr_y,ax
    mov edi,[ebp].de_p0
    mov cx,[ebp].de_size
    call FilledLine
;
    mov ax,[ebp].de_y1
    mov [ebp].curr_y,ax
    mov edi,[ebp].de_p1
    mov cx,[ebp].de_size
    call FilledLine
;
    mov word ptr [ebp].de_width,1
    ret
draw_mid_ellipse_filled Endp

draw_last_ellipse_hollow    Proc near
    mov ax,[ebp].de_y0
    mov [ebp].curr_y,ax
    mov edi,[ebp].de_p0
    mov ax,[ebp].de_width
    mov cx,[ebp].de_size
    call SplitLine
    ret
draw_last_ellipse_hollow    Endp

draw_last_ellipse_filled    Proc near
    mov ax,[ebp].de_y0
    mov [ebp].curr_y,ax
    mov edi,[ebp].de_p0
    mov cx,[ebp].de_size
    call FilledLine
    ret
draw_last_ellipse_filled    Endp

ellipse_mid_style_tab:
em00 DD OFFSET draw_mid_ellipse_hollow
em01 DD OFFSET draw_mid_ellipse_filled

ellipse_last_style_tab:
el00 DD OFFSET draw_last_ellipse_hollow
el01 DD OFFSET draw_last_ellipse_filled

draw_ellipse    Proc far
    push ds
    push es
    pushad
    mov ebp,esp
    sub esp,96
;
    cmp si,2
    jbe ellipse_end
;
    cmp di,2
    jbe ellipse_end
;
    dec si
    shr si,1
    mov [ebp].de_w,si
    mov word ptr [ebp].de_width,1
    mov word ptr [ebp].de_size,2
;
    dec di
    shr di,1
    mov [ebp].de_h,di
    mov [ebp].de_cnt,di
;
    add cx,si
    mov [ebp].curr_x,cx
    mov [ebp].de_y0,dx
    add dx,di
    add dx,di
    mov [ebp].de_y1,dx
;
    mov ax,di
    mul di
    mov [ebp].de_h2,ax
    mov [ebp+2].de_h2,dx
;
    mov ax,si
    mul si
    mov [ebp].de_w2,ax
    mov [ebp+2].de_w2,dx
;
    movzx eax,word ptr [ebp].de_h
    shl eax,1
    neg eax
    inc eax
    imul dword ptr [ebp].de_w2
    mov [ebp].de_m,eax
    mov [ebp+4].de_m,dx
;
    mov eax,[ebp].de_h2
    xor dx,dx
    add eax,eax
    adc dx,dx
    mov esi,eax
    mov di,dx
    add eax,eax
    adc dx,dx
    mov [ebp].de_dTx,eax
    mov [ebp+4].de_dTx,dx 
;
    add eax,esi
    adc dx,di
    mov [ebp].de_dSx,eax
    mov [ebp+4].de_dSx,dx
;
    mov eax,[ebp].de_m
    mov dx,[ebp+4].de_m
    add eax,[ebp].de_w2
    adc dx,0
    add eax,eax
    adc dx,dx
    mov [ebp].de_dSy,eax
    mov [ebp+4].de_dSy,dx
;
    mov eax,[ebp].de_w2
    xor dx,dx
    add eax,eax
    adc dx,dx
    add eax,[ebp].de_dSy
    adc dx,[ebp+4].de_dSy
    mov [ebp].de_dTy,eax
    mov [ebp+4].de_dTy,dx
;
    mov eax,[ebp].de_h2
    xor dx,dx
    add eax,eax
    adc dx,dx
    add eax,[ebp].de_m
    adc dx,[ebp+4].de_m
    mov [ebp].de_S,eax
    mov [ebp+4].de_S,dx
;
    mov eax,[ebp].de_m
    mov dx,[ebp+4].de_m
    add eax,eax
    adc dx,dx
    add eax,[ebp].de_h2
    adc dx,0
    mov [ebp].de_T,eax
    mov [ebp+4].de_T,dx
;
    mov eax,[ebp].de_h2
    xor dx,dx
    add eax,eax
    adc dx,dx
    add eax,eax
    adc dx,dx
    mov [ebp].de_ddx,eax
    mov [ebp+4].de_ddx,dx
;
    mov eax,[ebp].de_w2
    xor dx,dx
    add eax,eax
    adc dx,dx
    add eax,eax
    adc dx,dx
    mov [ebp].de_ddy,eax
    mov [ebp+4].de_ddy,dx
;
    movzx esi,ds:v_row_size
    shl esi,3
;
    movsx ecx,word ptr [ebp].curr_x
    movsx edx,word ptr [ebp].de_y0
    mov eax,esi
    imul edx
    mov edi,eax
    add edi,ecx
    mov [ebp].de_p0,edi
;
    movsx ecx,word ptr [ebp].curr_x
    movsx edx,word ptr [ebp].de_y1
    mov eax,esi
    imul edx
    mov edi,eax
    add edi,ecx
    mov [ebp].de_p1,edi
;
    mov ax,flat_sel
    mov es,ax

ellipse_loop:
    mov eax,[ebp].de_S
    mov bx,[ebp+4].de_S
    mov ecx,[ebp].de_T
    mov dx,[ebp+4].de_T
    test bh,80h
    jz ellipse_s_pos

ellipse_s_neg:
    add eax,[ebp].de_dSx
    adc bx,[ebp+4].de_dSx
    mov [ebp].de_S,eax
    mov [ebp+4].de_S,bx
;
    add ecx,[ebp].de_dTx
    adc dx,[ebp+4].de_dTx
    mov [ebp].de_T,ecx
    mov [ebp+4].de_T,dx
;
    mov eax,[ebp].de_ddx
    mov dx,[ebp+4].de_ddx
    add [ebp].de_dSx,eax
    adc [ebp+4].de_dSx,dx
    add [ebp].de_dTx,eax
    adc [ebp+4].de_dTx,dx
;
    dec word ptr [ebp].curr_x
    dec dword ptr [ebp].de_p0
    dec dword ptr [ebp].de_p1
    inc word ptr [ebp].de_width
    add word ptr [ebp].de_size,2
    jmp ellipse_loop

ellipse_s_pos:
    test dh,80h
    jz ellipse_t_pos

ellipse_t_neg:
    add eax,[ebp].de_dSx
    adc bx,[ebp+4].de_dSx
    add eax,[ebp].de_dSy
    adc bx,[ebp+4].de_dSy
    mov [ebp].de_S,eax
    mov [ebp+4].de_S,bx
;
    add ecx,[ebp].de_dTx
    adc dx,[ebp+4].de_dTx
    add ecx,[ebp].de_dTy
    adc dx,[ebp+4].de_dTy
    mov [ebp].de_T,ecx
    mov [ebp+4].de_T,dx
;
    mov eax,[ebp].de_ddx
    mov dx,[ebp+4].de_ddx
    add [ebp].de_dSx,eax
    adc [ebp+4].de_dSx,dx
    add [ebp].de_dTx,eax
    adc [ebp+4].de_dTx,dx
;
    mov eax,[ebp].de_ddy
    mov dx,[ebp+4].de_ddy
    add [ebp].de_dSy,eax
    adc [ebp+4].de_dSy,dx
    add [ebp].de_dTy,eax
    adc [ebp+4].de_dTy,dx
;
    dec word ptr [ebp].curr_x
    dec dword ptr [ebp].de_p0
    dec dword ptr [ebp].de_p1
    inc word ptr [ebp].de_width
    add word ptr [ebp].de_size,2
;
    movzx ebx,ds:v_style
    shl ebx,2
    call dword ptr cs:[ebx].ellipse_mid_style_tab
    inc word ptr [ebp].de_y0
    dec word ptr [ebp].de_y1
    add [ebp].de_p0,esi
    sub [ebp].de_p1,esi
;
    sub word ptr [ebp].de_cnt,1
    jz ellipse_done
    jmp ellipse_loop

ellipse_t_pos:
    add eax,[ebp].de_dSy
    adc bx,[ebp+4].de_dSy
    mov [ebp].de_S,eax
    mov [ebp+4].de_S,bx
;
    add ecx,[ebp].de_dTy
    adc dx,[ebp+4].de_dTy
    mov [ebp].de_T,ecx
    mov [ebp+4].de_T,dx
;
    mov eax,[ebp].de_ddy
    mov dx,[ebp+4].de_ddy
    add [ebp].de_dSy,eax
    adc [ebp+4].de_dSy,dx
    add [ebp].de_dTy,eax
    adc [ebp+4].de_dTy,dx
;
    movzx ebx,ds:v_style
    shl ebx,2
    call dword ptr cs:[ebx].ellipse_mid_style_tab
    inc word ptr [ebp].de_y0
    dec word ptr [ebp].de_y1
    add [ebp].de_p0,esi
    sub [ebp].de_p1,esi
;
    sub word ptr [ebp].de_cnt,1
    jnz ellipse_loop

ellipse_done:
    movzx ebx,ds:v_style
    shl ebx,2
    call dword ptr cs:[ebx].ellipse_last_style_tab

ellipse_end:
    add esp,96
    popad
    pop es
    pop ds
    ret
draw_ellipse    Endp

errorp  Proc far
    ret
errorp  Endp

    public BitmapTab1

BitmapTab1:
mt00 DD OFFSET translate_color,     SEG code
mt01 DD OFFSET set_base,            SEG code
mt02 DD OFFSET slab,                SEG code
mt03 DD OFFSET copy,                SEG code
mt04 DD OFFSET mask_set,        SEG code
mt05 DD OFFSET mask_copy,               SEG code
mt06 DD OFFSET get_line,            SEG code
mt07 DD OFFSET get_pixel,               SEG code
mt08 DD OFFSET set_pixel,               SEG code
mt09 DD OFFSET get_native,          SEG code
mt0A DD OFFSET get_rgb,             SEG code
mt0B DD OFFSET set_native,              SEG code
mt0C DD OFFSET set_rgb,             SEG code
mt0D DD OFFSET draw_mask_line,      SEG code
mt0E DD OFFSET set_sprite,              SEG code
mt0F DD OFFSET draw_sprite_line,    SEG code
mt10 DD OFFSET draw_string,             SEG code
mt11 DD OFFSET draw_line,               SEG code
mt12 DD OFFSET draw_rect,               SEG code
mt13 DD OFFSET draw_ellipse,        SEG code
mt14 DD OFFSET anti_alias_set,      SEG code
mt15 DD OFFSET phys_update,         SEG code
mt16 DD OFFSET errorp,              SEG code
mt17 DD OFFSET errorp,              SEG code
mt18 DD OFFSET get_alpha,             SEG code
mt19 DD OFFSET set_alpha,             SEG code
mt1A DD OFFSET errorp,              SEG code
mt1B DD OFFSET errorp,              SEG code
mt1C DD OFFSET errorp,              SEG code

code    ENDS

    END

