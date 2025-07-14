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
; FONT.ASM
; Font handling
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\handle.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\apicheck.inc

font_handle_struc       STRUC

fh_base         handle_header <>
fh_org_sel          DW ?
fh_buf_sel          DW ?

font_handle_struc       ENDS

font_buf_header STRUC

fh_height           DW ?

fh_widths           DW 256 DUP(?)
fh_bitmaps          DD 256 DUP(?)

font_buf_header ENDS
        
data    SEGMENT byte public 'DATA'

font_id                 DW ?
font_point_size         DW ?
font_name                   DB 32 DUP(?)
font_minch                  DW ?
font_maxch                  DW ? 
font_topline            DW ?
font_ascent                 DW ?
font_halfline           DW ?
font_descent            DW ?
font_botline            DW ?
font_maxwidth           DW ?
font_cellsize           DW ?
font_leftofs            DW ?
font_right_ofs          DW ?
font_thicken            DW ?
font_ulwidth            DW ?
font_lightmask          DW ?
font_skewmask           DW ?
font_flags                  DW ?
font_hotptr                 DD ?
font_cotptr                 DD ?
font_bufptr                 DD ?
font_fwidth                 DW ?
font_fheight            DW ?

font_org_data           DB ?

fsp                         DB 8Bh DUP(?)

; this should be offset E0

font_next                   DD ?
font_type                   DW ?

font_data                   DB 512 DUP(?)
        
data    ENDS
        
code    SEGMENT byte use16 public 'CODE'

        assume cs:code

    .386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INSTALL_FONT
;
;           DESCRIPTION:    Install a font
;
;           PARAMETERS:         DS:EDX  font header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_font    PROC near
    push ds
    push ax
    push bx
    push ecx
    push edx
    push si
;
    mov ecx,[edx].len
    sub ecx,SIZE rdos_header
    add edx,SIZE rdos_header
    AllocateGdt
    CreateDataSelector16
;
    mov ds,bx
    mov si,ds:font_fheight
    add si,si
    mov ax,SEG data
    mov ds,ax
    mov [si],bx
    mov cx,200h
    sub cx,si
    shr cx,1
    dec cx
    mov dx,si
fill_font_loop:
    add si,2
    mov ax,[si]
    or ax,ax
    jz fill_font_do
    push ds
    mov ds,ax
    mov ax,ds:font_fheight
    add ax,ax
    pop ds
    cmp ax,dx
    ja fill_font_next
fill_font_do:
    mov [si],bx
fill_font_next:
    loop fill_font_loop
    pop si
    pop edx
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
install_font    ENDP


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
    mov ax,flat_sel
    mov ds,ax
load_adapter_fonts_loop:
    mov ax,[edx].typ
    cmp ax,RdosFont
    jne not_install_font
    call install_font
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
;           NAME:           OpenFont
;
;           DESCRIPTION:    Open a font and return handle
;
;           PARAMETERS:         AX          Font height
;
;           RETURNS:        BX          Font handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_font_name  DB 'Open Font',0

bit_rev_tab:
brt00   DB      00000000b
brt01   DB      10000000b
brt02   DB      01000000b
brt03   DB      11000000b
brt04   DB      00100000b
brt05   DB      10100000b
brt06   DB      01100000b
brt07   DB      11100000b
brt08   DB      00010000b
brt09   DB      10010000b
brt0A   DB      01010000b
brt0B   DB      11010000b
brt0C   DB      00110000b
brt0D   DB      10110000b
brt0E   DB      01110000b
brt0F   DB      11110000b
brt10   DB      00001000b
brt11   DB      10001000b
brt12   DB      01001000b
brt13   DB      11001000b
brt14   DB      00101000b
brt15   DB      10101000b
brt16   DB      01101000b
brt17   DB      11101000b
brt18   DB      00011000b
brt19   DB      10011000b
brt1A   DB      01011000b
brt1B   DB      11011000b
brt1C   DB      00111000b
brt1D   DB      10111000b
brt1E   DB      01111000b
brt1F   DB      11111000b
brt20   DB      00000100b
brt21   DB      10000100b
brt22   DB      01000100b
brt23   DB      11000100b
brt24   DB      00100100b
brt25   DB      10100100b
brt26   DB      01100100b
brt27   DB      11100100b
brt28   DB      00010100b
brt29   DB      10010100b
brt2A   DB      01010100b
brt2B   DB      11010100b
brt2C   DB      00110100b
brt2D   DB      10110100b
brt2E   DB      01110100b
brt2F   DB      11110100b
brt30   DB      00001100b
brt31   DB      10001100b
brt32   DB      01001100b
brt33   DB      11001100b
brt34   DB      00101100b
brt35   DB      10101100b
brt36   DB      01101100b
brt37   DB      11101100b
brt38   DB      00011100b
brt39   DB      10011100b
brt3A   DB      01011100b
brt3B   DB      11011100b
brt3C   DB      00111100b
brt3D   DB      10111100b
brt3E   DB      01111100b
brt3F   DB      11111100b
brt40   DB      00000010b
brt41   DB      10000010b
brt42   DB      01000010b
brt43   DB      11000010b
brt44   DB      00100010b
brt45   DB      10100010b
brt46   DB      01100010b
brt47   DB      11100010b
brt48   DB      00010010b
brt49   DB      10010010b
brt4A   DB      01010010b
brt4B   DB      11010010b
brt4C   DB      00110010b
brt4D   DB      10110010b
brt4E   DB      01110010b
brt4F   DB      11110010b
brt50   DB      00001010b
brt51   DB      10001010b
brt52   DB      01001010b
brt53   DB      11001010b
brt54   DB      00101010b
brt55   DB      10101010b
brt56   DB      01101010b
brt57   DB      11101010b
brt58   DB      00011010b
brt59   DB      10011010b
brt5A   DB      01011010b
brt5B   DB      11011010b
brt5C   DB      00111010b
brt5D   DB      10111010b
brt5E   DB      01111010b
brt5F   DB      11111010b
brt60   DB      00000110b
brt61   DB      10000110b
brt62   DB      01000110b
brt63   DB      11000110b
brt64   DB      00100110b
brt65   DB      10100110b
brt66   DB      01100110b
brt67   DB      11100110b
brt68   DB      00010110b
brt69   DB      10010110b
brt6A   DB      01010110b
brt6B   DB      11010110b
brt6C   DB      00110110b
brt6D   DB      10110110b
brt6E   DB      01110110b
brt6F   DB      11110110b
brt70   DB      00001110b
brt71   DB      10001110b
brt72   DB      01001110b
brt73   DB      11001110b
brt74   DB      00101110b
brt75   DB      10101110b
brt76   DB      01101110b
brt77   DB      11101110b
brt78   DB      00011110b
brt79   DB      10011110b
brt7A   DB      01011110b
brt7B   DB      11011110b
brt7C   DB      00111110b
brt7D   DB      10111110b
brt7E   DB      01111110b
brt7F   DB      11111110b
brt80   DB      00000001b
brt81   DB      10000001b
brt82   DB      01000001b
brt83   DB      11000001b
brt84   DB      00100001b
brt85   DB      10100001b
brt86   DB      01100001b
brt87   DB      11100001b
brt88   DB      00010001b
brt89   DB      10010001b
brt8A   DB      01010001b
brt8B   DB      11010001b
brt8C   DB      00110001b
brt8D   DB      10110001b
brt8E   DB      01110001b
brt8F   DB      11110001b
brt90   DB      00001001b
brt91   DB      10001001b
brt92   DB      01001001b
brt93   DB      11001001b
brt94   DB      00101001b
brt95   DB      10101001b
brt96   DB      01101001b
brt97   DB      11101001b
brt98   DB      00011001b
brt99   DB      10011001b
brt9A   DB      01011001b
brt9B   DB      11011001b
brt9C   DB      00111001b
brt9D   DB      10111001b
brt9E   DB      01111001b
brt9F   DB      11111001b
brtA0   DB      00000101b
brtA1   DB      10000101b
brtA2   DB      01000101b
brtA3   DB      11000101b
brtA4   DB      00100101b
brtA5   DB      10100101b
brtA6   DB      01100101b
brtA7   DB      11100101b
brtA8   DB      00010101b
brtA9   DB      10010101b
brtAA   DB      01010101b
brtAB   DB      11010101b
brtAC   DB      00110101b
brtAD   DB      10110101b
brtAE   DB      01110101b
brtAF   DB      11110101b
brtB0   DB      00001101b
brtB1   DB      10001101b
brtB2   DB      01001101b
brtB3   DB      11001101b
brtB4   DB      00101101b
brtB5   DB      10101101b
brtB6   DB      01101101b
brtB7   DB      11101101b
brtB8   DB      00011101b
brtB9   DB      10011101b
brtBA   DB      01011101b
brtBB   DB      11011101b
brtBC   DB      00111101b
brtBD   DB      10111101b
brtBE   DB      01111101b
brtBF   DB      11111101b
brtC0   DB      00000011b
brtC1   DB      10000011b
brtC2   DB      01000011b
brtC3   DB      11000011b
brtC4   DB      00100011b
brtC5   DB      10100011b
brtC6   DB      01100011b
brtC7   DB      11100011b
brtC8   DB      00010011b
brtC9   DB      10010011b
brtCA   DB      01010011b
brtCB   DB      11010011b
brtCC   DB      00110011b
brtCD   DB      10110011b
brtCE   DB      01110011b
brtCF   DB      11110011b
brtD0   DB      00001011b
brtD1   DB      10001011b
brtD2   DB      01001011b
brtD3   DB      11001011b
brtD4   DB      00101011b
brtD5   DB      10101011b
brtD6   DB      01101011b
brtD7   DB      11101011b
brtD8   DB      00011011b
brtD9   DB      10011011b
brtDA   DB      01011011b
brtDB   DB      11011011b
brtDC   DB      00111011b
brtDD   DB      10111011b
brtDE   DB      01111011b
brtDF   DB      11111011b
brtE0   DB      00000111b
brtE1   DB      10000111b
brtE2   DB      01000111b
brtE3   DB      11000111b
brtE4   DB      00100111b
brtE5   DB      10100111b
brtE6   DB      01100111b
brtE7   DB      11100111b
brtE8   DB      00010111b
brtE9   DB      10010111b
brtEA   DB      01010111b
brtEB   DB      11010111b
brtEC   DB      00110111b
brtED   DB      10110111b
brtEE   DB      01110111b
brtEF   DB      11110111b
brtF0   DB      00001111b
brtF1   DB      10001111b
brtF2   DB      01001111b
brtF3   DB      11001111b
brtF4   DB      00101111b
brtF5   DB      10101111b
brtF6   DB      01101111b
brtF7   DB      11101111b
brtF8   DB      00011111b
brtF9   DB      10011111b
brtFA   DB      01011111b
brtFB   DB      11011111b
brtFC   DB      00111111b
brtFD   DB      10111111b
brtFE   DB      01111111b
brtFF   DB      11111111b

last_bit_tab:
lbt0    DB 0FFh
lbt1    DB 1
lbt2    DB 3
lbt3    DB 7
lbt4    DB 0Fh
lbt5    DB 1Fh
lbt6    DB 3Fh
lbt7    DB 7Fh

open_font       Proc far
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
    push bp
;
    mov si,ax
    add si,si
    mov ax,SEG data
    mov ds,ax
open_font_down_loop:
    mov ax,[si]
    or ax,ax
    jnz open_font_found
    sub si,2
    jnc open_font_down_loop
;
    mov si,2

open_font_up_loop:
    mov ax,[si]
    or ax,ax
    jnz open_font_found
;
    add si,2
    jnc open_font_up_loop   
;
    jmp open_font_end

open_font_found:
    mov ds,ax
    xor ecx,ecx
    xor edx,edx
    mov ax,ds:font_minch
    mov ebx,ds:font_cotptr

open_font_size_loop:
    mov cx,[ebx+2]
    or cx,cx
    jz open_font_size_next
;
    sub cx,[ebx]
    jbe open_font_size_next
;
    dec cx
    shr cx,3
    inc cx
    add edx,ecx

open_font_size_next:
    add ebx,2
    inc ax
    cmp ax,ds:font_maxch
    jne open_font_size_loop
;
    movzx eax,ds:font_fheight
    mul edx
    add eax,SIZE font_buf_header + 2
    AllocateSmallGlobalMem
    mov dx,ds:font_fheight
    mov es:fh_height,dx
;
    mov edi,SIZE font_buf_header
    mov ecx,eax
    sub ecx,edi
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov di,OFFSET fh_widths
    xor ax,ax
    mov cx,100h
    rep stosw
;
    mov di,OFFSET fh_bitmaps
    xor eax,eax
    mov cx,100h
    rep stosd
;
    mov edx,SIZE font_buf_header
    mov esi,OFFSET fh_widths
    mov edi,OFFSET fh_bitmaps
    mov cx,ds:font_minch
    movzx eax,cx
    add eax,eax
    add esi,eax
    add eax,eax
    add edi,eax
    mov ebx,ds:font_cotptr

open_font_ptr_loop:
    mov ax,[ebx+2]
    or ax,ax
    jz open_font_ptr_next
;
    sub ax,[ebx]
    jbe open_font_ptr_next
;
    mov es:[esi],ax
    mov es:[edi],edx
    dec ax
    shr ax,3
    inc ax
    push dx
    mul es:fh_height
    pop dx
    movzx eax,ax
    add edx,eax

open_font_ptr_next:
    inc cx
    add ebx,2
    add esi,2
    add edi,4
    cmp cx,ds:font_maxch
    jne open_font_ptr_loop
;
    mov ebx,ds:font_cotptr
    mov esi,OFFSET fh_widths
    mov edi,OFFSET fh_bitmaps
    mov cx,ds:font_minch
    movzx eax,cx
    add eax,eax
    add esi,eax
    add eax,eax
    add edi,eax

open_font_char_loop:
    push ebx
    push cx
    push esi
    push edi
;
    mov cx,es:[esi]
    or cx,cx
    jz open_font_char_next
;
    mov bp,cx
    and bp,7
    mov al,byte ptr cs:[bp].last_bit_tab
    mov bp,ax
;
    mov edi,es:[edi]
    dec cx
    shr cx,3
    inc cx
    mov dx,ds:font_fheight
    movzx esi,word ptr [ebx]
    mov ax,si
    shr si,3
    and al,7
    mov ch,cl
    mov cl,al
    add esi,ds:font_bufptr
    mov bx, OFFSET bit_rev_tab

open_font_data_loop:
    push cx
    push esi

open_font_row_loop:
    mov ax,[esi]
    xchg al,ah
    shl ax,cl 
    mov al,ah
    xlat byte ptr cs:bit_rev_tab
    cmp ch,1
    jne open_font_row_save
;
    and ax,bp

open_font_row_save:
    stos byte ptr es:[edi]
    inc esi
    sub ch,1
    jnz open_font_row_loop  
;
    pop esi
    pop cx
;
    movzx eax,ds:font_fwidth
    add esi,eax
    sub dx,1
    jnz open_font_data_loop

open_font_char_next:
    pop edi
    pop esi
    pop cx
    pop ebx
;
    inc cx
    add ebx,2
    add esi,2
    add edi,4
    cmp cx,ds:font_maxch
    jne open_font_char_loop
;
    mov ax,ds
    mov cx,SIZE font_handle_struc
    AllocateHandle
    mov [ebx].fh_org_sel,ax
    mov [ebx].fh_buf_sel,es
    mov [ebx].hh_sign,FONT_HANDLE
    mov bx,[ebx].hh_handle
    clc

open_font_end:
    pop bp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    retf32
open_font       Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloseFont
;
;           DESCRIPTION:    Close a font handle
;
;           PARAMETERS:         BX          Font handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_font_name DB 'Close Font',0

close_font      Proc far
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push es
    push ax
    push ebx
;
    mov ax,FONT_HANDLE
    DerefHandle
    jc cl_font_done
;
    mov es,[ebx].fh_buf_sel
    FreeMem
    FreeHandle
    clc

cl_font_done:
    pop ebx
    pop ax
    pop es
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    retf32
close_font      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetStringMetrics
;
;           DESCRIPTION:    Get width & height of string
;
;           PARAMETERS:         ES:(E)DI    String 
;
;           RETURNS:        CX              Width
;                           DX              Height
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_string_metrics_name DB 'Get String Metrics',0

get_string_metrics      Proc near
    ApiSaveEax
    ApiSaveEsi

    push ds
    push ax
    push ebx
    push edi
;
    mov ax,FONT_HANDLE
    DerefHandle
    jc get_string_metr_fail
;
    mov ds,[ebx].fh_org_sel
    xor cx,cx
    mov dx,ds:font_fheight

get_string_metr_loop:
    xor ah,ah
    mov al,es:[edi]
    inc edi
    or al,al
    clc
    jz get_string_metr_done
;
    cmp ax,ds:font_maxch
    ja get_string_metr_loop
;
    sub ax,ds:font_minch
    jb get_string_metr_loop
;
    movzx ebx,al
    add ebx,ebx
    add ebx,ds:font_cotptr
    add cx,[ebx+2]
    sub cx,[ebx]
    jmp get_string_metr_loop

get_string_metr_fail:
    xor cx,cx
    stc

get_string_metr_done:
    pop edi
    pop ebx
    pop ax
    pop ds

    ApiCheckEsi
    ApiCheckEax
    ret
get_string_metrics      Endp

get_string_metrics32    Proc far
    call get_string_metrics
    retf32
get_string_metrics32    Endp

get_string_metrics16    Proc far
    push edi
    movzx edi,di
    call get_string_metrics
    pop edi
    retf32
get_string_metrics16    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetCharMask
;
;           DESCRIPTION:    Get mask for string
;
;           PARAMETERS:     AL              char
;                           BX              font handle
;
;           RETURNS:        CX              width
;                           DX              height
;                           SI              row size
;                           ES:EDI      1-bit string bitmap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_char_mask_name      DB 'Get Char Mask',0

get_char_mask   Proc far
    push ds
    push ebx
;
    push ax
    mov ax,FONT_HANDLE
    DerefHandle
    pop ax
    jc get_char_mask_done
;
    mov es,[ebx].fh_buf_sel
    movzx ebx,al
    mov dx,es:fh_height
    mov cx,es:[2*ebx].fh_widths
    mov si,cx
    dec si
    shr si,3
    inc si
    mov edi,es:[4*ebx].fh_bitmaps
    clc

get_char_mask_done:
    pop ebx
    pop ds
    retf32
get_char_mask   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_handle
;
;           DESCRIPTION:    BX              Font handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push es
    push ax
    push ebx
;
    mov ax,FONT_HANDLE
    DerefHandle
    jc delete_handle_done
;
    mov es,[ebx].fh_buf_sel
    FreeMem
    FreeHandle
    clc

delete_handle_done:
    pop ebx
    pop ax
    pop es
    pop ds
    retf32
delete_handle   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init device
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,SEG code
    mov ax,SEG data
;
    xor bx,bx
    mov cx,256
    xor ax,ax
init_system_font_loop:
    mov [bx],ax
    add bx,2
    loop init_system_font_loop
;
    mov ax,system_data_sel
    mov ds,ax
    mov cx,ds:rom_modules
    mov bx,OFFSET rom_adapters
init_font_loop:
    mov edx,[bx].adapter_base
    call load_adapter_fonts
    add bx,SIZE adapter_typ
    loop init_font_loop     
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ax,FONT_HANDLE
    mov edi,OFFSET delete_handle
    RegisterHandle
;
    mov esi,OFFSET get_char_mask
    mov edi,OFFSET get_char_mask_name
    xor cl,cl
    mov ax,get_char_mask_nr
    RegisterOsGate
;
    mov esi,OFFSET open_font
    mov edi,OFFSET open_font_name
    xor dx,dx
    mov ax,open_font_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_font
    mov edi,OFFSET close_font_name
    xor dx,dx
    mov ax,close_font_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_string_metrics16
    mov esi,OFFSET get_string_metrics32
    mov edi,OFFSET get_string_metrics_name
    mov dx,virt_es_in
    mov ax,get_string_metrics_nr
    RegisterUserGate
    ret
init    ENDP
        
code    ENDS


    END init

