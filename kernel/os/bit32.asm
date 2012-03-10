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
; BIT32.ASM
; Linear 32-bit graphics
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
; block buffer
; reg = number of pixels
; EDI = line buffer
;

DrawStart MACRO reg
    local done
    
    EnterSection ds:v_sprite_section
    mov [bp].curr_start,edi
    mov word ptr [bp].curr_size,reg
;
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
;           NAME:           DrawDone
;
;           DESCRIPTION:    Draw done notification
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawDone    Proc near
    cmp ds:v_sprite_count,0
    jz draw_sprite_ok
;
    ShowSpriteLine

draw_sprite_ok:
    cmp ds:v_has_focus,0
    jz draw_unblock
;    
    push cx
    push edi
;
    mov cx,[bp].curr_size
    mov edi,[bp].curr_start
    call ds:phys_update_proc
;
    pop edi
    pop cx

draw_unblock:
    LeaveSection ds:v_sprite_section
    ret
DrawDone    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopNull
;
;           DESCRIPTION:    Null draw
;
;           PARAMETERS:         EAX             Color
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
;           PARAMETERS:         EAX             Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopNone    Proc near
    mov es:[edi],eax
    ret
LgopNone    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopOr
;
;           DESCRIPTION:    Or draw
;
;           PARAMETERS:         EAX             Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopOr  Proc near
    push edx
    mov edx,es:[edi]
    or edx,eax
    mov es:[edi],edx
    pop edx
    ret
LgopOr  Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopAnd
;
;           DESCRIPTION:    And draw
;
;           PARAMETERS:         EAX             Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopAnd Proc near
    push edx
    mov edx,es:[edi]
    and edx,eax
    mov es:[edi],edx
    pop edx
    ret
LgopAnd Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopXor
;
;           DESCRIPTION:    Xor draw
;
;           PARAMETERS:         EAX             Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopXor Proc near
    push edx
    mov edx,es:[edi]
    xor edx,eax
    mov es:[edi],edx
    pop edx
    ret
LgopXor Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopInvert
;
;           DESCRIPTION:    Invert draw
;
;           PARAMETERS:         EAX             Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvert      Proc near
    push eax
    not eax
    mov es:[edi],eax
    pop eax
    ret
LgopInvert      Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopInvertOr
;
;           DESCRIPTION:    Invert or draw
;
;           PARAMETERS:         EAX             Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertOr    Proc near
    push eax
    push edx
    not eax
    mov edx,es:[edi]
    or edx,eax
    mov es:[edi],edx
    pop edx
    pop eax
    ret
LgopInvertOr    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopInvertAnd
;
;           DESCRIPTION:    Invert and draw
;
;           PARAMETERS:         EAX             Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertAnd   Proc near
    push eax
    push edx
    not eax
    mov edx,es:[edi]
    and edx,eax
    mov es:[edi],edx
    pop edx
    pop eax
    ret
LgopInvertAnd   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopInvertXor
;
;           DESCRIPTION:    Invert xor draw
;
;           PARAMETERS:         EAX             Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertXor   Proc near
    push eax
    push edx
    not eax
    mov edx,es:[edi]
    xor edx,eax
    mov es:[edi],edx
    pop edx
    pop eax
    ret
LgopInvertXor   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopAdd
;
;           DESCRIPTION:    Add draw
;
;           PARAMETERS:         EAX             Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopAdd Proc near
    push eax
    push edx
    mov edx,es:[edi]
;
    add dl,al
    jnc lgop_add_ok1
    mov dl,0FFh
lgop_add_ok1:
    ror eax,8
    ror edx,8
;
    add dl,al
    jnc lgop_add_ok2
    mov dl,0FFh
lgop_add_ok2:
    ror eax,8
    ror edx,8
;
    add dl,al
    jnc lgop_add_ok3
    mov dl,0FFh
lgop_add_ok3:
    rol edx,16
    mov es:[edi],edx
    pop edx
    pop eax
    ret
LgopAdd Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopSub
;
;           DESCRIPTION:    Sub draw
;
;           PARAMETERS:         EAX             Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopSub Proc near
    push eax
    push edx
    mov edx,es:[edi]
;
    sub dl,al
    jnc lgop_sub_ok1
    xor dl,dl
lgop_sub_ok1:
    ror eax,8
    ror edx,8
;
    sub dl,al
    jnc lgop_sub_ok2
    xor dl,dl
lgop_sub_ok2:
    ror eax,8
    ror edx,8
;
    sub dl,al
    jnc lgop_sub_ok3
    xor dl,dl
lgop_sub_ok3:
    rol edx,16
    mov es:[edi],edx
;
    pop edx
    pop eax
    ret
LgopSub Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopMul
;
;           DESCRIPTION:    Mul draw
;
;           PARAMETERS:         EAX             Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopMul Proc near
    push eax
    push ebx
    push ecx
    mov ebx,eax
    mov ecx,es:[edi]
;
    mul cl
    mov cl,ah
    ror ebx,8
    ror ecx,8
;
    mov al,bl
    mul cl
    mov cl,ah
    ror ebx,8
    ror ecx,8
;
    mov al,bl
    mul cl
    mov cl,ah
    rol ecx,16
;
    mov es:[edi],ecx
    pop ecx
    pop ebx
    pop eax
    ret
LgopMul Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopStipple
;
;           DESCRIPTION:    Stipple draw
;
;           PARAMETERS:         EAX             Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopStipple     Proc near
    ret
LgopStipple     Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LgopAlpha
;
;           DESCRIPTION:    Alpha draw
;
;           PARAMETERS:         EAX             Color
;                           ES:EDI      Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopAlpha       Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    mov ebx,eax
    mov ecx,es:[edi]
    mov edx,eax
    rol edx,8
    sub dl,80h
    neg dl
;
    mov al,cl
    mul dl
    ror ax,7
    add al,bl
    mov cl,al
    ror ebx,8
    ror ecx,8
;
    mov al,cl
    mul dl
    ror ax,7
    add al,bl
    mov cl,al
    ror ebx,8
    ror ecx,8
;
    mov al,cl
    mul dl
    ror ax,7
    add al,bl
    mov cl,al
    rol ecx,16
;
    mov es:[edi],ecx
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
LgopAlpha       Endp



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
lgt01   DW OFFSET LgopNone
lgt02   DW OFFSET LgopOr
lgt03   DW OFFSET LgopAnd
lgt04   DW OFFSET LgopXor
lgt05   DW OFFSET LgopInvert
lgt06   DW OFFSET LgopInvertOr
lgt07   DW OFFSET LgopInvertAnd
lgt08   DW OFFSET LgopInvertXor
lgt09   DW OFFSET LgopAdd
lgt0A   DW OFFSET LgopSub
lgt0B   DW OFFSET LgopMul
lgt0C   DW OFFSET LgopStipple
lgt0D   DW OFFSET LgopAlpha



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
    push bx
    push ecx
    push edi
;
    or cx,cx
    jz slab_done
;    
    mov bx,ds:v_lgop
    cmp bx,LGOP_NONE
    jne slab_lgop
;
    movzx ecx,cx
    rep stos dword ptr es:[edi]
    jmp slab_done

slab_lgop:
    add bx,bx

slab_lgop_loop:
    call word ptr cs:[bx].LgopTab
    add edi,4
    inc word ptr [bp].curr_x
    loop slab_lgop_loop

slab_done:
    pop edi
    pop ecx
    pop bx
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
    push eax
    push bx
    push ecx
    push esi
    push edi
;
    or cx,cx
    jz copy_done
;
    mov bx,ds:v_lgop
    cmp bx,LGOP_NONE
    je copy_none
;
    add bx,bx

copy_loop:
    lods dword ptr fs:[esi]
    call word ptr cs:[bx].LgopTab
    add edi,4
    inc word ptr [bp].curr_x
    loop copy_loop
    jmp copy_done

copy_none:
    movzx ecx,cx
    rep movs dword ptr es:[edi],fs:[esi]

copy_done:
    pop edi
    pop esi
    pop ecx
    pop bx
    pop eax
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
    push bx
    mov bx,ds:v_lgop
    add bx,bx
    call word ptr cs:[bx].LgopTab
    pop bx

mask_set_line_next:
    add edi,4
    inc word ptr [bp].curr_x
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
    mov ax,[bp].curr_x
    cmp ax,ds:v_x_min
    jl mask_copy_next
;
    cmp ax,ds:v_x_max
    jg mask_copy_next
;
    mov eax,fs:[esi]
    push bx
    mov bx,ds:v_lgop
    add bx,bx
    call word ptr cs:[bx].LgopTab
    pop bx

mask_copy_next:
    add esi,4
    add edi,4
    inc word ptr [bp].curr_x
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
;           NAME:           AntiAliasSet
;
;           DESCRIPTION:    Set mask using 256-level anti-alias bitmap
;
;           PARAMETERS:     EAX     Color
;                           CX              number of pixels
;                           GS:EBX      Antialias bitmap
;                           ES:EDI      Dest buffer
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
    push bx
    mov bx,ds:v_lgop
    add bx,bx
    call word ptr cs:[bx].LgopTab
    pop bx
    jmp anti_alias_set_line_next

anti_alias_mix:
    push eax
    mov ecx,eax
;    
    movzx ax,cl
    movzx dx,byte ptr es:[edi]
    sub ax,dx
    jz anti_alias_mix_b_ok    
;
    movzx dx,byte ptr gs:[ebx]
    imul dx
    mov cl,ah
    add cl,es:[edi]

anti_alias_mix_b_ok:    
    movzx ax,ch
    movzx dx,byte ptr es:[edi+1]
    sub ax,dx
    jz anti_alias_mix_g_ok
;
    movzx dx,byte ptr gs:[ebx]
    imul dx
    mov ch,ah
    add ch,es:[edi+1]

anti_alias_mix_g_ok:    
    mov eax,ecx
    shr eax,16
    movzx ax,al
    movzx dx,byte ptr es:[edi+2]
    sub ax,dx
    jz anti_alias_mix_r_ok
;
    movzx dx,byte ptr gs:[ebx]
    imul dx
    xchg ax,cx
    add ch,es:[edi+2]
    shl ecx,8
    xchg ax,cx
    
anti_alias_mix_r_ok:    
    mov eax,ecx    
    and eax,0FFFFFFh
    push bx
    mov bx,ds:v_lgop
    add bx,bx
    call word ptr cs:[bx].LgopTab
    pop bx
;
    pop eax    

anti_alias_set_line_next:
    pop cx
    add edi,4
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
;           PARAMETER:      CX          Number of pixels
;                           GS:EBX      Anti-alias buffer
;                           ES:EDI      line buffer
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
    add edi,4
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
    shl eax,2
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
    add edi,4
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
;           PARAMETER:          AX              line width
;                           CX              gap
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
    add edi,4
    loop split_left_loop
;
    call DrawDone
    pop cx
    add [bp].curr_x,cx
;
    movsx eax,cx
    shl eax,2
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
    add edi,4
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
    shl edx,2
    add eax,edx
    add eax,ds:v_app_base
    mov esi,eax
    mov dx,flat_sel
    mov ds,dx
    pop cx
;
    rep movs dword ptr es:[edi],ds:[esi]

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
    mov bp,sp
    sub sp,10
    mov [bp].curr_x,cx
    mov [bp].curr_y,dx
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
    add edi,4
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
    shl edx,2
    add eax,edx
    add eax,ds:v_app_base
    mov edi,eax
    pop cx
;
    or cx,cx
    jz set_native_done
;
    DrawStart cx
    call ds:copy_proc
    call DrawDone

set_native_done:
    add sp,10
    popad
    pop fs
    pop es
    ret
set_native      Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetSprite
;
;           DESCRIPTION:    Set sprite pixels in internal format
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
    mov bp,sp
    sub sp,10
    mov [bp].curr_x,cx
    mov [bp].curr_y,dx
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
    add edi,4
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
    shl edx,2
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
    call ds:copy_proc

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
    shl edx,2
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
    push edx
    movsx ecx,cx
    movsx edx,dx
    movzx eax,ds:v_row_size
    imul edx
    mov edx,ecx
    shl edx,2
    add eax,edx
    add eax,ds:v_app_base
    mov dx,flat_sel
    mov ds,dx
    mov eax,[eax]
    and eax,0FFFFFFh
    pop edx 
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
    mov edi,ecx
    shl edi,2
    add edi,eax
    add edi,ds:v_app_base
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
    push es
    push gs
    pushad
    mov bp,sp
    sub sp,10
    mov [bp].curr_x,edx
;
    push ax
    mov ax,[bp].curr_y
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
    push bp
    push ebx
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
    pop eax
    mov bx,bp
    pop bp
;
    mov dl,cl
    mov cx,bx
    mov ebx,esi
    DrawStart cx
    call ds:mask_set_proc
    call DrawDone

draw_mask_line_done:
    add sp,10
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
;                           ES:EDI      1-bit mask bits
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
    mov edx,ebx
    shl edx,2
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
    call ds:mask_copy_proc

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
    mov edx,esi
    shl edx,2
    add eax,edx
    add eax,ds:v_app_base
    mov edi,eax

draw_string_char_loop:
    push cx
    mov cx,[bp].ds_width
    call AntiAlias
    pop cx
;
    inc word ptr [bp].curr_y
    movzx eax,ds:v_row_size
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
    mov dword ptr [bp].dl_phys_add_x,4
    jmp line_bresen_dy

line_bresen_dx_pos:
    add cx,cx
    mov [bp].dl_dx,cx
    mov word ptr [bp].dl_log_add_x,-1
    mov dword ptr [bp].dl_phys_add_x,-4

line_bresen_dy:
    test dh,80h
    jz line_bresen_dy_pos

line_bresen_dy_neg:
    add dx,dx
    neg dx
    mov [bp].dl_dy,dx
    mov word ptr [bp].dl_log_add_y,1
    movzx ebx,ds:v_row_size
    mov [bp].dl_phys_add_y,ebx
    jmp line_bresen_calc_inc

line_bresen_dy_pos:
    add dx,dx
    mov [bp].dl_dy,dx
    mov word ptr [bp].dl_log_add_y,-1
    movzx ebx,ds:v_row_size
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
    mov edi,ecx
    shl edi,2
    add edi,eax
    add edi,ds:v_app_base
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
    mov esi,eax
    imul edx
    mov edi,ecx
    shl edi,2
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
    mov dx,[bp].curr_y
    cmp dx,ds:v_y_min
    jl line_vert_sprite_next
;
    cmp dx,ds:v_y_max
    jg line_vert_sprite_next
;    
    push ax
    DrawStart 1
    mov eax,ds:v_color
    call ds:set_proc
    call DrawDone
    pop ax

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
    mov edi,ecx
    shl edi,2
    add edi,eax
    add edi,ds:v_app_base
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
    mov esi,eax
    imul edx
    mov edi,ecx
    shl edi,2
    add edi,eax
    add edi,ds:v_app_base
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
;
    movsx ecx,word ptr [bp].curr_x
    movsx edx,word ptr [bp].de_y0
    mov eax,esi
    imul edx
    mov edi,ecx
    shl edi,2
    add edi,eax
    add edi,ds:v_app_base
    mov [bp].de_p0,edi
;
    movsx ecx,word ptr [bp].curr_x
    movsx edx,word ptr [bp].de_y1
    mov eax,esi
    imul edx
    mov edi,ecx
    shl edi,2
    add edi,eax
    add edi,ds:v_app_base
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
    sub dword ptr [bp].de_p0,4
    sub dword ptr [bp].de_p1,4
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
    sub dword ptr [bp].de_p0,4
    sub dword ptr [bp].de_p1,4
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
act00   DD 00000000h
act01   DD 00990000h
act02   DD 00009900h
act03   DD 00CC6600h
act04   DD 00000099h
act05   DD 00990099h
act06   DD 00009999h
act07   DD 00CCCCCCh
act08   DD 00666666h
act09   DD 00FF6666h
act0A   DD 0066FF66h
act0B   DD 00FFFF66h
act0C   DD 006666FFh
act0D   DD 00FF66FFh
act0E   DD 0066FFFFh
act0F   DD 00FFFFFFh

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
    mov ds:v_lgop, LGOP_NONE
    xor ah,ah
    push ax
;
    mov ax,cx
    mul ds:v_pixels_per_col
    mov cx,ax
;
    mov ax,dx
    mul ds:v_pixels_per_row
    mov dx,ax
;
    mov al,ds:v_style
    push ax
;
    mov ds:v_style,STYLE_FILLED
    mov al,bh
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
    clc
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


phys_update:
    retf

    public BitmapTab32

BitmapTab32:
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
mt18 DW OFFSET get_native,              SEG code
mt19 DW OFFSET get_native,              SEG code
mt1A DW OFFSET set_native,              SEG code
mt1B DW OFFSET set_native,              SEG code
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

