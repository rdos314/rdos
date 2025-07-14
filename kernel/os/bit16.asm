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
; BIT16.ASM
; Linear 16-bit graphics
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


curr_start  EQU -10
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
;                           ES:ESI      Current pos in bitmap
;                           ES:EDI      Current physical pos
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

phys_update Proc far
    rep movs word ptr es:[edi],es:[esi]
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
    movzx ecx,word ptr [ebp].curr_size
    mov esi,[ebp].curr_start
    mov edi,esi
    sub edi,ds:v_app_base
    add edi,ds:v_phys_base
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
    movzx ecx,word ptr [ebp].curr_size
    mov esi,[ebp].curr_start
    mov edi,esi
    sub edi,ds:v_app_base
    add edi,ds:v_phys_base
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
;           PARAMETERS:         AX              Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopNull    Proc near
    ret
LgopNull    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopNone
;
;           DESCRIPTION:    Set drawing color
;
;           PARAMETERS:         AX              Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopNone    Proc near
    mov es:[edi],ax
    ret
LgopNone    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopOr
;
;           DESCRIPTION:    Or draw
;
;           PARAMETERS:         AX              Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopOr  Proc near
    push dx
    mov dx,es:[edi]
    or dx,ax
    mov es:[edi],dx
    pop dx
    ret
LgopOr  Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopAnd
;
;           DESCRIPTION:    And draw
;
;           PARAMETERS:         AX              Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopAnd Proc near
    push dx
    mov dx,es:[edi]
    and dx,ax
    mov es:[edi],dx
    pop dx
    ret
LgopAnd Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopXor
;
;           DESCRIPTION:    Xor draw
;
;           PARAMETERS:         AX              Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopXor Proc near
    push dx
    mov dx,es:[edi]
    xor dx,ax
    mov es:[edi],dx
    pop dx
    ret
LgopXor Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopInvert
;
;           DESCRIPTION:    Invert draw
;
;           PARAMETERS:         AX              Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvert      Proc near
    push ax
    not ax
    mov es:[edi],ax
    pop ax
    ret
LgopInvert      Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopInvertOr
;
;           DESCRIPTION:    Invert or draw
;
;           PARAMETERS:         AX              Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertOr    Proc near
    push ax
    push dx
    not ax
    mov dx,es:[edi]
    or dx,ax
    mov es:[edi],dx
    pop dx
    pop ax
    ret
LgopInvertOr    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopInvertAnd
;
;           DESCRIPTION:    Invert and draw
;
;           PARAMETERS:         AX              Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertAnd   Proc near
    push ax
    push dx
    not ax
    mov dx,es:[edi]
    and dx,ax
    mov es:[edi],dx
    pop dx
    pop ax
    ret
LgopInvertAnd   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopInvertXor
;
;           DESCRIPTION:    Invert xor draw
;
;           PARAMETERS:         AX              Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertXor   Proc near
    push ax
    push dx
    not ax
    mov dx,es:[edi]
    xor dx,ax
    mov es:[edi],dx
    pop dx
    pop ax
    ret
LgopInvertXor   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopAdd
;
;           DESCRIPTION:    Add draw
;
;           PARAMETERS:         AX              Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopAdd Proc near
    push ax
    push bx
    push cx
    push dx
;
    mov dx,es:[edi]
;
    mov bh,ah
    mov bl,dh
    and bx,0F8F8h
    add bl,bh
    jnc lgop_add_ok1
;
    mov bl,0F8h

lgop_add_ok1:
    and dh,7
    or dh,bl
    rol ax,5
    rol dx,5
;
    mov bh,ah
    mov bl,dh
    and bx,0FCFCh
    add bl,bh
    jnc lgop_add_ok2
;
    mov bl,0FCh

lgop_add_ok2:
    and dh,3
    or dh,bl
    rol ax,6
    rol dx,6
;
    mov bh,ah
    mov bl,dh
    and bx,0F8F8h
    add bl,bh
    jnc lgop_add_ok3
;
    mov bl,0F8h

lgop_add_ok3:
    and dh,7
    or dh,bl
    rol dx,5
    mov es:[edi],dx
;
    pop dx
    pop cx
    pop bx
    pop ax
    ret
LgopAdd Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopSub
;
;           DESCRIPTION:    Sub draw
;
;           PARAMETERS:         AX              Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopSub Proc near
    push ax
    push bx
    push cx
    push dx
;
    mov dx,es:[edi]
;
    mov bh,ah
    mov bl,dh
    and bx,0F8F8h
    sub bl,bh
    jnc lgop_sub_ok1
;
    xor bl,bl

lgop_sub_ok1:
    and dh,7
    or dh,bl
    rol ax,5
    rol dx,5
;
    mov bh,ah
    mov bl,dh
    and bx,0FCFCh
    sub bl,bh
    jnc lgop_sub_ok2
;
    xor bl,bl

lgop_sub_ok2:
    and dh,3
    or dh,bl
    rol ax,6
    rol dx,6
;
    mov bh,ah
    mov bl,dh
    and bx,0F8F8h
    sub bl,bh
    jnc lgop_sub_ok3
;
    xor bl,bl

lgop_sub_ok3:
    and dh,7
    or dh,bl
    rol dx,5
    mov es:[edi],dx
;
    pop dx
    pop cx
    pop bx
    pop ax
    ret
LgopSub Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopMul
;
;           DESCRIPTION:    Mul draw
;
;           PARAMETERS:         AX              Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopMul Proc near
    push ax
    push dx
    push si
;
    push di
    mov si,ax
    mov di,es:[edi]
;
    mov ax,si
    mov dx,di
    and ax,0F800h
    shr ax,11
    and dx,0F800h
    shr dx,11
    mul dl
    mov al,ah
    shl ax,11
    and di,7FFh
    or di,ax
;
    mov ax,si
    mov dx,di
    and ax,7E0h
    shr ax,5
    and dx,7E0h
    shr dx,5
    mul dl
    mov al,ah
    shl ax,5
    and di,NOT 7E0h
    or di,ax
;
    mov ax,si
    mov dx,di
    and ax,1Fh
    and dx,1Fh
    mul dl
    mov al,ah
    and di,NOT 1Fh
    or di,ax
;
    mov dx,di
    pop di
    mov es:[edi],dx
;
    pop si
    pop dx
    pop ax
    ret
LgopMul Endp



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
lgt01   DD OFFSET LgopNone
lgt02   DD OFFSET LgopOr
lgt03   DD OFFSET LgopAnd
lgt04   DD OFFSET LgopXor
lgt05   DD OFFSET LgopInvert
lgt06   DD OFFSET LgopInvertOr
lgt07   DD OFFSET LgopInvertAnd
lgt08   DD OFFSET LgopInvertXor
lgt09   DD OFFSET LgopAdd
lgt0A   DD OFFSET LgopSub
lgt0B   DD OFFSET LgopMul
lgt0C   DD OFFSET LgopNull
lgt0D   DD OFFSET LgopNull


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
    push bx
    push edx
;
    mov edx,eax
    shr edx,8
    and dx,0F800h
    mov bx,dx
;
    mov dx,ax
    shr dx,5
    and dx,7E0h
    or bx,dx
;
    mov dx,ax
    shr dx,3
    and dx,1Fh
    or bx,dx
    movzx eax,bx
;
    pop edx
    pop bx
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
;           NAME:           Slab
;
;           DESCRIPTION:    Fill line
;
;           PARAMETERS:         AX              Color
;                           ES:EDI      Dest buffer
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

slab    Proc far
    push ebx
    push cx
    push dx
    push edi
;
    or cx,cx
    jz slab_done
;    
    movzx ebx,ds:v_lgop
    cmp bx,LGOP_NONE
    jne slab_lgop
;
    mov dx,ax
    shl eax,16
    mov ax,dx
;
    test di,2
    jz slab_lgop_none_double

slab_lgop_none_word:
    stos word ptr es:[edi]
    sub cx,1
    jz slab_done

slab_lgop_none_double:
    cmp cx,1
    je slab_lgop_none_word
;
    stos dword ptr es:[edi]
    sub cx,2
    jnz slab_lgop_none_double
;
    jmp slab_done

slab_lgop:
    shl ebx,2

slab_lgop_loop:
    call dword ptr cs:[ebx].LgopTab
    add edi,2
    inc word ptr [ebp].curr_x
    sub cx,1
    jnz slab_lgop_loop

slab_done:
    pop edi
    pop dx
    pop cx
    pop ebx
    ret
slab    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Copy
;
;           DESCRIPTION:    Copy line
;
;           PARAMETERS:         FS:ESI      Source pixels
;                           ES:EDI      Dest buffer
;                           CX              number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

copy    Proc far
    push ax
    push ebx
    push cx
    push esi
    push edi
;
    or cx,cx
    jz copy_done
;    
    movzx ebx,ds:v_lgop
    cmp bx,LGOP_NONE
    je copy_none
;
    shl ebx,2

copy_loop:
    lods word ptr fs:[esi]
    call dword ptr cs:[ebx].LgopTab
    add edi,2
    inc word ptr [ebp].curr_x
    sub cx,1
    jnz copy_loop
    jmp copy_done

copy_none:
    test di,2
    jz copy_double
;
    movs word ptr es:[edi],fs:[esi]
    sub cx,1
    jz copy_done

copy_double:
    push cx
    movzx ecx,cx
    shr ecx,1
    rep movs dword ptr es:[edi],fs:[esi]
    pop cx
    test cx,1
    jz copy_done
;       
    movs word ptr es:[edi],fs:[esi]

copy_done:
    pop edi
    pop esi
    pop cx
    pop ebx
    pop ax
    ret
copy    Endp



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
    push cx
    push dx
    push esi
    push edi
;
    or cx,cx
    jz mask_set_line_done
;    
    mov si,cx
    mov cl,dl    
        
mask_set_line_loop:
    mov ch,8
    mov dx,gs:[ebx]
    ror dx,cl

mask_set_bit_loop:
    rcr dl,1
    jnc mask_set_line_next
;
    push ebx
    movzx ebx,ds:v_lgop
    shl ebx,2
    call dword ptr cs:[ebx].LgopTab
    pop ebx

mask_set_line_next:
    add edi,2
    inc word ptr [ebp].curr_x
    sub si,1
    jz mask_set_line_done
;
    sub ch,1
    jnz mask_set_bit_loop
;
    inc ebx
    jmp mask_set_line_loop

mask_set_line_done:
    pop edi
    pop esi
    pop dx
    pop cx
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
    push ebx
    push cx
    push dx
    push esi
    push edi
;
    or cx,cx
    jz mask_copy_done
;    
    or dl,dl
    jz mask_copy_prep
;
    push cx
    mov cl,dl
    mov dl,gs:[ebx]
    rcr dl,cl
    mov dh,8
    sub dh,cl
    pop cx
    jmp mask_copy_loop

mask_copy_prep:
    mov dh,8
    mov dl,gs:[ebx]

mask_copy_loop:
    rcr dl,1
    jnc mask_copy_next
;
    mov ax,[ebp].curr_x
    cmp ax,ds:v_x_min
    jl mask_copy_next
;
    cmp ax,ds:v_x_max
    jg mask_copy_next
;
    mov ax,fs:[esi]
    push ebx
    movzx ebx,ds:v_lgop
    shl ebx,2
    call dword ptr cs:[ebx].LgopTab
    pop ebx

mask_copy_next:
    add esi,2
    add edi,2
    inc word ptr [ebp].curr_x
    sub cx,1
    jz mask_copy_done
;
    sub dh,1
    jnz mask_copy_loop
;
    inc ebx
    jmp mask_copy_prep

mask_copy_done:
    pop edi
    pop esi
    pop dx
    pop cx
    pop ebx
    ret
mask_copy    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:       AntiAliasSet
;
;       DESCRIPTION:    Set mask using 256-level anti-alias bitmap
;
;       PARAMETERS:     AX     Internal color
;               CX      number of pixels
;               GS:EBX      Antialias bitmap
;               ES:EDI      Dest buffer
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
    or dl,dl
    jz anti_alias_set_line_next
;
    cmp dl,0FFh
    jne anti_alias_mix
;    
    push ebx
    movzx ebx,ds:v_lgop
    shl ebx,2
    call dword ptr cs:[ebx].LgopTab
    pop ebx
    jmp anti_alias_set_line_next

anti_alias_mix:
    push ax
    push si
    mov cx,ax
    mov si,es:[edi]
;    
    shr ax,1
    and ax,1Fh
    mov dx,si
    shr dx,1
    and dx,1Fh
    sub ax,dx
    jz anti_alias_mix_b_ok    
;
    movzx dx,byte ptr gs:[ebx]
    imul dx
    mov dx,si
    shr dx,1
    and dx,1Fh
    add dl,ah
    shl dx,1
    and si,NOT 3Eh
    or si,dx

anti_alias_mix_b_ok:    
    mov ax,cx
    shr ax,6
    and ax,1Fh
    mov dx,si
    shr dx,6
    and dx,1Fh
    sub ax,dx
    jz anti_alias_mix_g_ok
;
    movzx dx,byte ptr gs:[ebx]
    imul dx
    mov dx,si
    shr dx,6
    and dl,1Fh
    add dl,ah
    shl dx,6
    and si,NOT 7C0h
    or si,dx

anti_alias_mix_g_ok:    
    mov ax,cx
    shr ax,11
    and ax,1Fh
    mov dx,es:[edi]
    shr dx,11
    and dx,1Fh
    sub ax,dx
    jz anti_alias_mix_r_ok
;
    movzx dx,byte ptr gs:[ebx]
    imul dx
    mov dx,si
    shr dx,11
    and dl,1Fh
    add dl,ah
    shl dx,11
    and si,07FFh
    or si,dx
    
anti_alias_mix_r_ok:    
    mov ax,si
    push ebx
    movzx ebx,ds:v_lgop
    shl ebx,2
    call dword ptr cs:[ebx].LgopTab
    pop ebx
;
    pop si
    pop ax    

anti_alias_set_line_next:
    pop cx
    add edi,2
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
;           NAME:       AntiAlias
;
;           DESCRIPTION:    Anti-alias line and process sprites & limits
;
;           PARAMETER:      CX      Number of pixels
;                   GS:EBX      Mask to process
;                   ES:EDI      line buffer
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
    add edi,2
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
    add eax,eax
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
    add edi,2
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
;           PARAMETER:          AX              line width
;                           CX              gap
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
    add edi,2
    sub cx,1
    jnz split_left_loop
;
    pop cx
    add [ebp].curr_x,cx
;
    movsx eax,cx
    add eax,eax
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
    add edi,2
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
;                           ES:EDI      line buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_native      Proc far
    push ds
    push eax
    push bx
    push ecx
    push edx
    push esi
    push edi
;
    push ax
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    imul edx
    mov edx,ecx
    add edx,edx
    add eax,edx
    add eax,ds:v_app_base
    mov esi,eax
    mov dx,flat_sel
    mov ds,dx
    pop cx
;
    or cx,cx
    jz get_native_done
;
    test si,2
    jz get_native_double
;
    movs word ptr es:[edi],ds:[esi]
    sub cx,1
    jz get_native_done

get_native_double:
    push cx
    movzx ecx,cx
    shr ecx,1
    rep movs dword ptr es:[edi],ds:[esi]
    pop cx
    test cx,1
    jz get_native_done
;       
    movs word ptr es:[edi],ds:[esi]

get_native_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop bx  
    pop eax
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
;           PARAMETER:      AX              number of pixels
;                           CX              x
;                           DX              y
;                           ES:EDI      line buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_rgb Proc far
    push ds
    push eax
    push bx
    push ecx
    push edx
    push esi
    push edi
;
    push ax
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    imul edx
    mov edx,ecx
    add edx,edx
    add eax,edx
    add eax,ds:v_app_base
    mov esi,eax
    mov dx,flat_sel
    mov ds,dx
    pop cx
;
    or cx,cx
    jz get_rgb_done

get_rgb_loop:
    lods word ptr [esi]
    mov bx,ax
    movzx eax,ax
    and ax,0F800h
    shl eax,8
    mov dx,bx
    and dx,7E0h
    shl dx,5
    or ax,dx
    and bx,1Fh
    shl bx,3
    or ax,bx
    stos dword ptr es:[edi]
    sub cx,1
    jnz get_rgb_loop       

get_rgb_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop bx  
    pop eax
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
    push eax
    push bx
    push ecx
    push edx
    push esi
    push edi
;
    push ax
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    imul edx
    mov edx,ecx
    add edx,edx
    add eax,edx
    add eax,ds:v_app_base
    mov esi,eax
    mov dx,flat_sel
    mov ds,dx
    pop cx
;
    or cx,cx
    jz get_rgba_done

get_rgba_loop:
    lods word ptr [esi]
    mov bx,ax
    movzx eax,ax
    and ax,0F800h
    shl eax,8
    mov dx,bx
    and dx,7E0h
    shl dx,5
    or ax,dx
    and bx,1Fh
    shl bx,3
    or ax,bx
    or eax,0FF000000h
    stos dword ptr es:[edi]
    sub cx,1
    jnz get_rgba_loop       

get_rgba_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop bx  
    pop eax
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
    push es
    push fs
    pushad
    mov ebp,esp
    sub esp,12
    mov [ebp].curr_x,cx
    mov [ebp].curr_y,dx
;
    cmp dx,ds:v_y_min
    jl set_native_done
;
    cmp dx,ds:v_y_max
    jg set_native_done

set_native_buf_loop:
    cmp cx,ds:v_x_min
    jge set_native_start_ok

set_native_adv_buf:
    inc cx
    add edi,2
    sub ax,1
    jnz set_native_buf_loop
    jmp set_native_done

set_native_start_ok:
    mov bx,ds:v_x_max
    sub bx,cx
    inc bx
    cmp ax,bx
    jc set_native_do
;
    mov ax,bx
    
set_native_do:
    or ax,ax
    jz set_native_done
;
    push ax
    mov esi,edi
    mov ax,es
    mov fs,ax
    mov ax,flat_sel
    mov es,ax
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    imul edx
    mov edx,ecx
    add edx,edx
    add eax,edx
    add eax,ds:v_app_base
    mov edi,eax
    pop cx
;
    or cx,cx
    jz set_native_done
;
    DrawStart cx
    call fword ptr ds:v_copy_proc
    call DrawDone

set_native_done:
    add esp,12
    popad
    pop fs
    pop es
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
    mov [ebp].curr_x,cx
    mov [ebp].curr_y,dx
;
    cmp dx,ds:v_y_min
    jl set_rgb_done
;
    cmp dx,ds:v_y_max
    jg set_rgb_done

set_rgb_buf_loop:
    cmp cx,ds:v_x_min
    jge set_rgb_start_ok

set_rgb_adv_buf:
    inc cx
    add edi,2
    sub ax,1
    jnz set_rgb_buf_loop
    jmp set_rgb_done

set_rgb_start_ok:
    mov bx,ds:v_x_max
    sub bx,cx
    inc bx
    cmp ax,bx
    jc set_rgb_do
;
    mov ax,bx
    
set_rgb_do:
    or ax,ax
    jz set_rgb_done
;
    push ax
    mov esi,edi
    mov ax,es
    mov fs,ax
    mov ax,flat_sel
    mov es,ax
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    imul edx
    mov edx,ecx
    add edx,edx
    add eax,edx
    add eax,ds:v_app_base
    mov edi,eax
    pop cx
;
    or cx,cx
    jz set_rgb_done
;
    DrawStart cx

set_rgb_loop:
    lods dword ptr fs:[esi]
    mov edx,eax
    shr edx,8
    and dx,0F800h
    push ebp
    mov bp,dx
    mov dx,ax
    shr dx,5
    and dx,7E0h
    or bp,dx
    mov dx,ax
    shr dx,3
    and dx,1Fh
    or bp,dx
    mov ax,bp
    pop ebp
    call fword ptr ds:v_set_proc
    add edi,2
    inc word ptr [ebp].curr_x
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
    mov [ebp].curr_x,cx
    mov [ebp].curr_y,dx
;
    cmp dx,ds:v_y_min
    jl set_rgba_done
;
    cmp dx,ds:v_y_max
    jg set_rgba_done

set_rgba_buf_loop:
    cmp cx,ds:v_x_min
    jge set_rgba_start_ok

set_rgba_adv_buf:
    inc cx
    add edi,2
    sub ax,1
    jnz set_rgba_buf_loop
    jmp set_rgba_done

set_rgba_start_ok:
    mov bx,ds:v_x_max
    sub bx,cx
    inc bx
    cmp ax,bx
    jc set_rgba_do
;
    mov ax,bx
    
set_rgba_do:
    or ax,ax
    jz set_rgba_done
;
    push ax
    mov esi,edi
    mov ax,es
    mov fs,ax
    mov ax,flat_sel
    mov es,ax
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    imul edx
    mov edx,ecx
    add edx,edx
    add eax,edx
    add eax,ds:v_app_base
    mov edi,eax
    pop cx
;
    or cx,cx
    jz set_rgba_done
;
    DrawStart cx

set_rgba_loop:
    push bx
    push cx
;
    mov bl,fs:[esi+3]
    or bl,bl
    jz set_rgba_next
;
    mov eax,fs:[esi]
    mov edx,eax
    shr edx,8
    and dx,0F800h
    mov bx,dx
    mov dx,ax
    shr dx,5
    and dx,7E0h
    or bx,dx
    mov dx,ax
    shr dx,3
    and dx,1Fh
    or bx,dx
    mov ax,bx
;
    mov bl,fs:[esi+3]
    cmp bl,0FFh
    jne set_rgba_mix
;    
    movzx ebx,ds:v_lgop
    shl ebx,2
    call dword ptr cs:[ebx].LgopTab
    jmp set_rgba_next

set_rgba_mix:
    push ax
    push si
;
    mov cx,ax
    mov si,es:[edi]
;    
    shr ax,1
    and ax,1Fh
    mov dx,si
    shr dx,1
    and dx,1Fh
    sub ax,dx
    jz set_rgba_b_ok    
;
    movzx dx,bl
    imul dx
    mov dx,si
    shr dx,1
    and dx,1Fh
    add dl,ah
    shl dx,1
    and si,NOT 3Eh
    or si,dx

set_rgba_b_ok:    
    mov ax,cx
    shr ax,6
    and ax,1Fh
    mov dx,si
    shr dx,6
    and dx,1Fh
    sub ax,dx
    jz set_rgba_g_ok
;
    movzx dx,bl
    imul dx
    mov dx,si
    shr dx,6
    and dl,1Fh
    add dl,ah
    shl dx,6
    and si,NOT 7C0h
    or si,dx

set_rgba_g_ok:    
    mov ax,cx
    shr ax,11
    and ax,1Fh
    mov dx,es:[edi]
    shr dx,11
    and dx,1Fh
    sub ax,dx
    jz set_rgba_r_ok
;
    movzx dx,bl
    imul dx
    mov dx,si
    shr dx,11
    and dl,1Fh
    add dl,ah
    shl dx,11
    and si,07FFh
    or si,dx
    
set_rgba_r_ok:    
    mov ax,si
    movzx ebx,ds:v_lgop
    shl ebx,2
    call dword ptr cs:[ebx].LgopTab
;
    pop si
    pop ax    

set_rgba_next:
    pop cx
    pop bx
;    
    add esi,4
    add edi,2
    inc word ptr [ebp].curr_x
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
;                           CX              x
;                           DX              y
;                           ES:EDI      line buffer
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
    add edi,2
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
    push ax
    mov esi,edi
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    imul edx
    mov edx,ecx
    add edx,edx
    add eax,edx
    add eax,ds:v_app_base
    mov edi,eax
    pop cx
;
    mov ax,es
    mov fs,ax
    mov ax,flat_sel
    mov es,ax
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
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_line    Proc far
    push ds
    push eax
    push ecx
    push edx
;
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    imul edx
    mov edx,ecx
    add edx,edx
    add eax,edx
    add eax,ds:v_app_base
    mov edi,eax
    mov ax,flat_sel
    mov es,ax
;
    pop edx
    pop ecx
    pop eax
    pop ds
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
    push ds
    push bx
    push edx
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    imul edx
    mov edx,ecx
    add edx,edx
    add eax,edx
    add eax,ds:v_app_base
    mov dx,flat_sel
    mov ds,dx
    mov ax,[eax]
    mov bx,ax
    movzx eax,bx
    and ax,0F800h
    shl eax,8
    mov dx,bx
    and dx,7E0h
    shl dx,5
    or ax,dx
    and bx,1Fh
    shl bx,3
    or ax,bx
;
    pop edx
    pop bx  
    pop ds
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
    mov edi,ecx
    add edi,edi
    add edi,eax
    add edi,ds:v_app_base
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
    push es
    push gs
    pushad
    mov ebp,esp
    sub esp,12    
    mov [ebp].curr_x,edx
;
    push ax
    mov ax,[ebp].curr_y
    cmp ax,ds:v_y_min
    jl draw_mask_pop_done
;
    cmp ax,ds:v_y_max
    jg draw_mask_pop_done

draw_mask_buf_loop:
    cmp dx,ds:v_x_min
    jge draw_mask_start_ok

draw_mask_adv_buf:
    inc cx
    inc dx
    sub si,1
    jnz draw_mask_buf_loop
    jmp draw_mask_pop_done

draw_mask_start_ok:
    mov ax,ds:v_x_max
    sub ax,dx
    inc ax
    cmp si,ax
    jc draw_mask_do
;
    mov ax,bx
    jmp draw_mask_do

draw_mask_pop_done:
    pop ax
    jmp draw_mask_line_done
    
draw_mask_do:
    pop ax
    or si,si
    jz draw_mask_line_done
;
    push ebp
    push ax
    push edx
    mov edx,ebx
    shr edx,8
    and dx,0F800h
    mov ax,dx
    mov dx,bx
    shr dx,5
    and dx,7E0h
    or ax,dx
    mov dx,bx
    shr dx,3
    and dx,1Fh
    or ax,dx
    mov bx,ax
    pop edx
    pop ax
    push bx
;
    xchg ecx,edx
    movsx ebx,dx
    ror edx,16
    movsx edx,dx
    movzx eax,ax
    imul edx
    shl eax,3
    add eax,ebx
    push eax
;
    movsx ebp,cx
    ror ecx,16
    movsx edx,cx
    movzx eax,ds:v_row_size
    imul edx
    mov edx,ebp
    add edx,edx
    add eax,edx
    add eax,ds:v_app_base
;
    pop ebp
    mov cl,bl
    and cl,7
    shr ebp,3
    add ebp,edi
;
    xchg esi,ebp
    mov edi,eax
;
    mov ax,es
    mov gs,ax
    mov ax,flat_sel
    mov es,ax
    pop ax
    mov bx,bp
    pop ebp
;
    mov dl,cl
    mov cx,bx
    mov ebx,esi
    DrawStart cx    
    call fword ptr ds:v_mask_set_proc
    call DrawDone

draw_mask_line_done:
    add esp,12
    popad
    pop gs
    pop es
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
    mov edx,ebx
    add edx,edx
    add eax,edx
    add eax,ds:v_app_base
    mov ebx,eax
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
;       NAME:       DrawString
;
;       DESCRIPTION:    Draw a string
; 
;       PARAMETER:      CX          x
;               DX          y
;               ES:EDI      string
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
    mov edx,esi
    add edx,edx
    add eax,edx
    add eax,ds:v_app_base
    mov edi,eax

draw_string_char_loop:
    push cx
    mov cx,[ebp].ds_width
    call AntiAlias
    pop cx
;
    inc word ptr [ebp].curr_y
    movzx eax,ds:v_row_size
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
    mov dword ptr [ebp].dl_phys_add_x,2
    jmp line_bresen_dy

line_bresen_dx_pos:
    add cx,cx
    mov [ebp].dl_dx,cx
    mov word ptr [ebp].dl_log_add_x,-1
    mov dword ptr [ebp].dl_phys_add_x,-2

line_bresen_dy:
    test dh,80h
    jz line_bresen_dy_pos

line_bresen_dy_neg:
    add dx,dx
    neg dx
    mov [ebp].dl_dy,dx
    mov word ptr [ebp].dl_log_add_y,1
    movzx ebx,ds:v_row_size
    mov [ebp].dl_phys_add_y,ebx
    jmp line_bresen_calc_inc

line_bresen_dy_pos:
    add dx,dx
    mov [ebp].dl_dy,dx
    mov word ptr [ebp].dl_log_add_y,-1
    movzx ebx,ds:v_row_size
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
    mov edi,ecx
    add edi,edi
    add edi,eax
    add edi,ds:v_app_base
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
    mov esi,eax
    imul edx
    mov edi,ecx
    add edi,edi
    add edi,eax
    add edi,ds:v_app_base
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
    mov edi,ecx
    add edi,edi
    add edi,eax
    add edi,ds:v_app_base
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
    mov esi,eax
    imul edx
    mov edi,ecx
    add edi,edi
    add edi,eax
    add edi,ds:v_app_base
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
;
    movsx ecx,word ptr [ebp].curr_x
    movsx edx,word ptr [ebp].de_y0
    mov eax,esi
    imul edx
    mov edi,ecx
    add edi,edi
    add edi,eax
    add edi,ds:v_app_base
    mov [ebp].de_p0,edi
;
    movsx ecx,word ptr [ebp].curr_x
    movsx edx,word ptr [ebp].de_y1
    mov eax,esi
    imul edx
    mov edi,ecx
    add edi,edi
    add edi,eax
    add edi,ds:v_app_base
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
    sub dword ptr [ebp].de_p0,2
    sub dword ptr [ebp].de_p1,2
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
    sub dword ptr [ebp].de_p0,2
    sub dword ptr [ebp].de_p1,2
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
    
    public BitmapTab16

BitmapTab16:
mt00 DD OFFSET translate_color,     SEG code
mt01 DD OFFSET set_base,            SEG code
mt02 DD OFFSET slab,                SEG code
mt03 DD OFFSET copy,                SEG code
mt04 DD OFFSET mask_set,        SEG code
mt05 DD OFFSET mask_copy,               SEG code
mt06 DD OFFSET get_line,            SEG code
mt07 DD OFFSET get_pixel,               SEG code
mt08 DD OFFSET set_pixel,               SEG code
mt09 DD OFFSET get_native,              SEG code
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
mt18 DD OFFSET get_alpha,           SEG code
mt19 DD OFFSET set_alpha,           SEG code
mt1A DD OFFSET errorp,              SEG code
mt1B DD OFFSET errorp,              SEG code
mt1C DD OFFSET errorp,              SEG code

code    ENDS

    END

