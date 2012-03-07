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


size_cache_entry    STRUC

sce_usage       DD ?
sce_ptr_arr     DD 256 DUP(?)

size_cache_entry    ENDS

    .386p

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

    extrn InstallFont:far
    extrn LoadGlyph:near

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateSizeCacheEntry
;
;           DESCRIPTION:    Create and initialize size cache entry
;
;           PARAMETERS:         
;
;           RETURNS:        EAX      Cache entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateSizeCacheEntry_

CreateSizeCacheEntry_   Proc near
    push es
    push ecx
    push edx
    push edi
;    
    mov eax,SIZE size_cache_entry
    AllocateSmallLinear
;
    mov ax,flat_sel
    mov es,ax
    mov edi,edx
    mov es:[edi].sce_usage,0
    add edi, OFFSET sce_ptr_arr
    mov ecx,256
    xor eax,eax
    rep stosd
    mov eax,edx
;
    pop edi
    pop edx
    pop ecx
    pop es
    ret
CreateSizeCacheEntry_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateLink
;
;           DESCRIPTION:    Create a link block of 2 ^ 6 entries
;
;           PARAMETERS:     FS      Flat sel
;
;           RETURNS:        EAX     Link logical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateLink   Proc near
    push es
    push ecx
    push edx
    push edi
;    
    mov ax,flat_sel
    mov es,ax
;
    mov eax,4 * 64
    AllocateSmallLinear
;
    mov edi,edx
    mov ecx,64
    xor eax,eax
    rep stosd
    mov eax,edx
;
    pop edi
    pop edx
    pop ecx
    pop es
    ret
CreateLink   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetGlyphEntry
;
;           DESCRIPTION:    Get a glyph
;
;           PARAMETERS:     GS:ESI      Face
;                           EAX         Cache size entry
;                           ES:EDI      UTF-8 string
;
;           RETURNS:        EAX         Glyph linear address (or 0 for failure)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetGlyphEntry_

GetGlyphEntry_   Proc near
    push es
    push fs
    push ebx
    push ecx
    push edx
    push edi
;   
    push esi
;    
    mov esi,eax
    mov eax,flat_sel
    mov fs,ax
;    
    mov al,es:[edi]
    test al,80h
    jz ggeOneByte
;
    test al,40h
    jz ggeFail
;
    test al,20h
    jz ggeTwoByte
;
    test al,10h
    jz ggeThreeByte
;
    test al,8
    jnz ggeFail
;        
    jmp ggeFourByte        

ggeOneByte:
    movzx edx,al
    movzx ebx,al
    shl ebx,2
    jmp ggeLoad

ggeTwoByte:
    mov ah,es:[edi+1]
    test ah,80h
    jz ggeFail
;
    test ah,40h
    jnz ggeFail
;
    and ax,3F1Fh
    movzx edx,al
    shl edx,6
    or dl,ah
;
    movzx ebx,ah
    shl ebx,2
    push ebx
;    
    movzx ebx,al
    or bl,80h
    shl ebx,2
    mov eax,fs:[ebx+esi]
    or eax,eax
    jnz ggeTwoLink1Ok
;    
    call CreateLink
    mov fs:[ebx+esi],eax

ggeTwoLink1Ok:
    mov esi,eax
    pop ebx
    jmp ggeLoad

ggeThreeByte:
    mov ah,es:[edi+1]
    test ah,80h
    jz ggeFail
;
    test ah,40h
    jnz ggeFail
;
    mov cl,es:[edi+2]
    test cl,80h
    jz ggeFail
;
    test cl,40h
    jnz ggeFail
;        
    and ax,3F0Fh
    and cl,3Fh
    movzx edx,al
    shl edx,6
    or dl,ah
    shl edx,6
    or dl,cl
;    
    movzx ebx,cl
    shl ebx,2
    push ebx
;
    movzx ebx,ah
    shl ebx,2
    push ebx
;    
    movzx ebx,al
    or bl,0C0h
    shl ebx,2
    mov eax,fs:[ebx+esi]
    or eax,eax
    jnz ggeThreeLink1Ok
;    
    call CreateLink
    mov fs:[ebx+esi],eax

ggeThreeLink1Ok:
    mov esi,eax
    pop ebx
    mov eax,fs:[ebx+esi]
    or eax,eax
    jnz ggeThreeLink2Ok
;    
    call CreateLink
    mov fs:[ebx+esi],eax

ggeThreeLink2Ok:
    mov esi,eax
    pop ebx
    jmp ggeLoad

ggeFourByte:
    mov ah,es:[edi+1]
    test ah,80h
    jz ggeFail
;
    test ah,40h
    jnz ggeFail
;
    mov cl,es:[edi+2]
    test cl,80h
    jz ggeFail
;
    test cl,40h
    jnz ggeFail
;
    mov ch,es:[edi+2]
    test ch,80h
    jz ggeFail
;
    test ch,40h
    jnz ggeFail
;        
    and ax,3F07h
    and cx,3F3Fh
    movzx edx,al
    shl edx,6
    or dl,ah
    shl edx,6
    or dl,cl
    shl edx,6
    or dl,ch
;    
    movzx ebx,ch
    shl ebx,2
    push ebx
;    
    movzx ebx,cl
    shl ebx,2
    push ebx
;    
    movzx ebx,ah
    shl ebx,2
    push ebx
;
    movzx ebx,al
    or bl,0E0h
    shl ebx,2
    mov eax,fs:[ebx+esi]
    or eax,eax
    jnz ggeFourLink1Ok
;    
    call CreateLink
    mov fs:[ebx+esi],eax

ggeFourLink1Ok:
    mov esi,eax
    pop ebx
    mov eax,fs:[ebx+esi]
    or eax,eax
    jnz ggeFourLink2Ok
;    
    call CreateLink
    mov fs:[ebx+esi],eax

ggeFourLink2Ok:
    mov esi,eax
    pop ebx
    mov eax,fs:[ebx+esi]
    or eax,eax
    jnz ggeFourLink3Ok
;    
    call CreateLink
    mov fs:[ebx+esi],eax

ggeFourLink3Ok:
    mov esi,eax
    pop ebx
    jmp ggeLoad

ggeFail:
    pop esi
    xor eax,eax
    jmp ggeDone

ggeLoad:    
    add ebx,esi
    pop esi
    mov eax,fs:[ebx]
    or eax,eax
    jnz ggeDone

ggeLoadIt:
    call LoadGlyph
    mov fs:[ebx],eax

ggeDone:  
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
    ret
GetGlyphEntry_   Endp

_TEXT    ENDS

    END
