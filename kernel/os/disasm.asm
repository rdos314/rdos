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
; DISASM.ASM
; Disassembler part kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

blank_sep                       EQU 0
komma_sep                       EQU 1000h
kolon_sep                       EQU 2000h
lpar_sep                        EQU 3000h
rpar_sep                        EQU 4000h
lhak_sep                        EQU 5000h
rhak_sep                        EQU 6000h
plus_sep                        EQU 7000h
minus_sep                       EQU 8000h
kolon_par_sep           EQU 9000h
par_komma_sep           EQU 0A000h
no_sep                          EQU 0B000h

data_8          EQU 0
data_16         EQU 1
data_32         EQU 2
data_48         EQU 3

addr_16         EQU 0
addr_32         EQU 1

data    SEGMENT byte public 'DATA'

op_syntax       DW ?
override        DW ?
op_ads          DW ?,?
data_sel        DW ?
data_off        DD ?
data_good       DB ?
data_mode       DB ?
gaddr_mode      DB ?
gdata_mode      DB ?
edata_mode      DB ?
ignore_ptr      DB ?

op_in_code      DB 50 DUP(?)
op_codes        DW 100 DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'

.386p

        assume cs:code

        extrn main_tab:near
        extrn mne_tab:near
        extrn sep_tab:near
        extrn txt_noth:near
        extrn cr_tab:near
        extrn dr_tab:near


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   SetIpAds
;
;               DESCRIPTION:    Set address
;
;       PARAMETERS:     EBX     EIP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetIpAds
    
SetIpAds        PROC near
    push ds
    push ax
    mov ax,SEG data
    mov ds,ax
    mov dword ptr ds:op_ads,ebx
    pop ax
    pop ds
    ret
SetIpAds  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetDataGood
;
;               DESCRIPTION:    Get data selector
;
;       RETURNS:        AL      data good ( = 1 )
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetDataGood
    
GetDataGood     PROC near
    push ds
    mov ax,SEG data
    mov ds,ax
    mov al,ds:data_good
    pop ds
    ret
GetDataGood  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetDataSel
;
;               DESCRIPTION:    Get data selector
;
;       RETURNS:        AX      Data selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetDataSel
    
GetDataSel      PROC near
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:data_sel
    pop ds
    ret
GetDataSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   SetDataSel
;
;               DESCRIPTION:    Set data selector
;
;       PARAMETERS:     AX      Data selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetDataSel
    
SetDataSel      PROC near
    push ds
    push bx
    mov bx,SEG data
    mov ds,bx
    mov ds:data_sel,ax
    pop bx
    pop ds
    ret
SetDataSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetDataOffset
;
;               DESCRIPTION:    Get data offset
;
;       RETURNS:        EBX      Data offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetDataOffset
    
GetDataOffset   PROC near
    push ds
    push ax
    mov ax,SEG data
    mov ds,ax
    mov ebx,ds:data_off
    pop ax
    pop ds
    ret
GetDataOffset  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetOpBuf
;
;               DESCRIPTION:    Get decoded operand buffer
;
;       RETURNS:        SI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetOpBuf
    
GetOpBuf        PROC near
    push ds
    push ax
    mov ax,SEG data
    mov ds,ax
    mov si,OFFSET op_in_code
    pop ax
    pop ds
    ret
GetOpBuf  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   PUT_HEX_CODE
;
;               DESCRIPTION:    HJŽLPPROCEDUR
;
;               PARAMETERS:             AL      Number
;                                               DI      OP codes
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

put_hex_code    PROC near
        push bx
        xor bh,bh
        mov bl,al
        and bl,0F0h
        shr bl,4
        add bx,bx       
        add bx,no_sep
        mov [di],bx
        xor bh,bh
        mov bl,al
        and bl,0Fh
        add bx,bx
        add bx,no_sep
        mov [di+2],bx
        add di,4
        pop bx
        ret
put_hex_code    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ADD_HEX_BYTE
;
;               DESCRIPTION:    Add hex byte to output
;
;               PARAMETERS:             AL              Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_hex_byte    PROC near
        call put_hex_code
        ret
add_hex_byte    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ADD_HEX_WORD
;
;               DESCRIPTION:    Add hex word to output
;
;               PARAMETERS:             AX              Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_hex_word    PROC near
        push ax
        mov al,ah
        call put_hex_code
        pop ax
        call put_hex_code
        ret
add_hex_word    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ADD_HEX_DWORD
;
;               DESCRIPTION:    Add hex dword to output
;
;               PARAMETERS:             EAX             Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_hex_dword   PROC near
        push eax
        push dx
;
        push eax
        pop dx
        pop ax
        xchg al,ah
        call put_hex_code
        xchg al,ah
        call put_hex_code
        mov al,dh
        call put_hex_code
        mov al,dl
        call put_hex_code
;
        pop dx
        pop eax
        ret
add_hex_dword   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CALC_ADS_OFFSET
;
;               DESCRIPTION:    Calculate offset
;
;               PARAMETERS:             AX              Table index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extrn adr_16a_tab:near
        extrn adr_32a_tab:near

calc_ads_offset PROC near
        push ax
        mov bl,ds:gaddr_mode
        cmp bl,addr_32
        je c_a_ad32
c_a_ad16:
        mov bx,OFFSET adr_16a_tab
        cmp ax,18h
        jae calc_out_o_r
        mov ds:data_good,1
        add ax,ax
        add ax,ax
        add bx,ax
        call word ptr cs:[bx]
        add ds:data_off,eax
        call word ptr cs:[bx+2]
        add ds:data_off,eax
        mov word ptr ds:data_off+2,0
        jmp calc_out_o_r
c_a_ad32:
        mov bx,OFFSET adr_32a_tab
        cmp ax,18h
        jae calc_out_o_r
        mov ds:data_good,1
        add ax,ax
        add ax,ax
        add bx,ax
        call word ptr cs:[bx]
        add ds:data_off,eax
        call word ptr cs:[bx+2]
        add ds:data_off,eax
calc_out_o_r:
        pop ax
        ret
calc_ads_offset ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DECODE_MEM_MODE
;
;               DESCRIPTION:    Decode memory mode
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extrn mod_rm_tab:near

decode_mem_mode PROC near
        mov bl,ds:gaddr_mode
        mov bh,bl
        add bl,bl
        add bl,bh
        mov al,ds:data_mode
        or al,al
        je data_8_sel
        add al,ds:gdata_mode
data_8_sel:
        mov ds:edata_mode,al
        add bl,al
        xor bh,bh
        add bx,bx
        add bx,OFFSET mod_rm_tab
        mov ax,cs:[bx]
        mov ds:op_syntax,ax
        mov al,[si+1]
        mov ah,al
        and al,7
        and ah,0C0h
        cmp ah,0C0h
        jne dec_mem_no_ignore
        mov ds:ignore_ptr,1
dec_mem_no_ignore:
        shr ah,3
        or al,ah
        xor ah,ah
        call calc_ads_offset
        inc si
        call decode_opcode
        ret
decode_mem_mode ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DECODE_MATH_MEM
;
;               DESCRIPTION:    Decode math memory
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extrn st_txt:near

decode_math_mem PROC near
        mov bl,ds:gaddr_mode
        mov bh,bl
        add bl,bl
        add bl,bh
        mov al,ds:data_mode
        or al,al
        je mdata_8_sel
        add al,ds:gdata_mode
mdata_8_sel:
        mov ds:edata_mode,al
        add bl,al
        xor bh,bh
        add bx,bx
        add bx,OFFSET mod_rm_tab
        mov ax,cs:[bx]
        mov ds:op_syntax,ax
        mov al,[si+1]
        mov ah,al
        and al,7
        and ah,0C0h
        cmp ah,0C0h
        jne no_math_reg
        mov bx,OFFSET st_txt
        sub bx,OFFSET mne_tab
        or bx,lpar_sep
        mov [di],bx
        add di,2
        mov bl,al
        xor bh,bh
        add bx,bx
        or bx,rpar_sep
        mov [di],bx     
        add di,2
        ret
no_math_reg:
        shr ah,3
        or al,ah
        xor ah,ah
        call calc_ads_offset
        inc si
        call decode_opcode
        ret
decode_math_mem ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DECODE_REG
;
;               DESCRIPTION:    Decode register field
;
;               PARAMETERS:             AL              Register entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extrn reg_tab:near

decode_reg      PROC near
        mov bl,ds:data_mode
        or bl,bl
        je rdata_8_sel
        add bl,ds:gdata_mode
rdata_8_sel:
        xor bh,bh
        add bx,bx
        add bx,OFFSET reg_tab
        mov cx,cs:[bx]
        mov ds:op_syntax,cx
        and ax,38h
        shr ax,3
        mov ds:ignore_ptr,1
        call decode_opcode
        ret
decode_reg      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ADD_KOMMA_TO_MEM
;
;               DESCRIPTION:    Add , to memory operand
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_komma_to_mem        PROC near
        mov ax,OFFSET txt_noth
        sub ax,OFFSET mne_tab
        or ax,komma_sep
        mov [di],ax
        add di,2
        ret
add_komma_to_mem        ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   
;
;               DESCRIPTION:    Syntax procedures
;
;               PARAMETERS:             SI      OP codes in
;                                               DI      OP codes out in binary
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


        public override_cs
        extrn cs_txt:near

override_cs     PROC near
        mov ax,OFFSET cs_txt
        mov ds:override,ax
        mov bx,OFFSET main_tab
        mov ds:op_syntax,bx
        inc si
        mov al,[si]
        xor ah,ah
        call decode_opcode
        ret
override_cs     ENDP

        public override_ds
        extrn ds_txt:near

override_ds     PROC near
        mov ax,OFFSET ds_txt
        mov ds:override,ax
        mov bx,OFFSET main_tab
        mov ds:op_syntax,bx
        inc si
        mov al,[si]
        xor ah,ah
        call decode_opcode
        ret
override_ds     ENDP

        public override_ss
        extrn ss_txt:near

override_ss     PROC near
        mov ax,OFFSET ss_txt
        mov ds:override,ax
        mov bx,OFFSET main_tab
        mov ds:op_syntax,bx
        inc si
        mov al,[si]
        xor ah,ah
        call decode_opcode
        ret
override_ss     ENDP

        public override_es
        extrn es_txt:near

override_es     PROC near
        mov ax,OFFSET es_txt
        mov ds:override,ax
        mov bx,OFFSET main_tab
        mov ds:op_syntax,bx
        inc si
        mov al,[si]
        xor ah,ah
        call decode_opcode
        ret
override_es     ENDP

        public override_fs
        extrn fs_txt:near

override_fs     PROC near
        mov ax,OFFSET fs_txt
        mov ds:override,ax
        mov bx,OFFSET main_tab
        mov ds:op_syntax,bx
        inc si
        mov al,[si]
        xor ah,ah
        call decode_opcode
        ret
override_fs     ENDP

        public override_gs
        extrn gs_txt:near

override_gs     PROC near
        mov ax,OFFSET gs_txt
        mov ds:override,ax
        mov bx,OFFSET main_tab
        mov ds:op_syntax,bx
        inc si
        mov al,[si]
        xor ah,ah
        call decode_opcode
        ret
override_gs     ENDP

        public op_byte

op_byte PROC near
        mov al,[si+1]
        call add_hex_byte
        inc si
        ret
op_byte ENDP

        public op_word

op_word PROC near
        mov al,ds:gdata_mode
        or al,al
        jz op_w16
op_w32:
        mov eax,[si+1]
        call add_hex_dword
        add si,4
        ret
op_w16: 
        mov ax,[si+1]
        call add_hex_word
        add si,2
        ret
op_word ENDP

        public op_word_mem

op_word_mem     PROC near
        mov al,ds:gdata_mode
        or al,al
        jz op_wm16
op_wm32:
        mov eax,[si+1]
        mov ds:data_good,1
        mov ds:data_off,eax
        call add_hex_dword
        add si,4
        ret
op_wm16:        
        movzx eax,word ptr [si+1]
        mov ds:data_good,1
        mov ds:data_off,eax
        call add_hex_word
        add si,2
        ret
op_word_mem     ENDP

        public op_short

op_short        PROC near
        xor ah,ah
        mov al,[si+1]
        test al,80h
        jz not_op_back
        mov ah,0FFh
not_op_back:
        add ax,2
        add ax,ds:op_ads
        call add_hex_word
        add si,2
        ret
op_short        ENDP

        public op_near

op_near PROC near
        mov al,ds:gdata_mode
        or al,al
        jz op_near16
op_near32:
        mov eax,[si+1]
        add eax,3
        add eax,dword ptr ds:op_ads
        call add_hex_dword
        add si,4
        ret
op_near16:      
        mov ax,[si+1]
        add ax,3
        add ax,ds:op_ads
        call add_hex_word
        add si,2
        ret
op_near ENDP

        public op_near2

op_near2        PROC near
        mov al,ds:gdata_mode
        or al,al
        jz op_near16_2
op_near32_2:
        mov eax,[si+2]
        add eax,4
        add eax,dword ptr ds:op_ads
        call add_hex_dword
        add si,5
        ret
op_near16_2:    
        mov ax,[si+2]
        add ax,4
        add ax,ds:op_ads
        call add_hex_word
        add si,3
        ret
op_near2        ENDP

        public op_far

op_far  PROC near
        mov al,ds:gdata_mode
        or al,al
        jz op_far16
op_far32:
        mov ax,[si+5]
        call add_hex_word
        mov ax,[di-2]
        and ax,0FFFh
        add ax,kolon_sep
        mov [di-2],ax
        mov eax,[si+1]
        add eax,dword ptr ds:op_ads
        call add_hex_dword
        add si,6
        ret
op_far16:       
        mov ax,[si+3]
        call add_hex_word
        mov ax,[di-2]
        and ax,0FFFh
        add ax,kolon_sep
        mov [di-2],ax
        mov ax,[si+1]
        call add_hex_word
        add si,4
        ret
op_far  ENDP

        public op_enter

op_enter        PROC near
        mov ax,[si+1]
        call add_hex_word
        mov ax,[di-2]
        and ax,0FFFh
        add ax,komma_sep
        mov [di-2],ax
        mov al,[si+3]
        call add_hex_byte
        add si,3
        ret
op_enter        ENDP

        public op_address_size

op_address_size PROC near
        mov bx,OFFSET main_tab
        mov ds:op_syntax,bx
        xor ds:gaddr_mode,1
        inc si
        mov al,[si]
        xor ah,ah
        call decode_opcode
        ret
op_address_size ENDP

        public op_data_size

op_data_size    PROC near
        mov bx,OFFSET main_tab
        mov ds:op_syntax,bx
        xor ds:gdata_mode,1
        inc si
        mov al,[si]
        xor ah,ah
        call decode_opcode
        ret
op_data_size    ENDP

        public op_wait

op_wait PROC near
        mov bx,OFFSET main_tab
        mov ds:op_syntax,bx
        inc si
        mov al,[si]
        xor ah,ah
        call decode_opcode
        ret
op_wait ENDP

        public op_rep

op_rep  PROC near
        mov bx,OFFSET main_tab
        mov ds:op_syntax,bx
        inc si
        mov al,[si]
        xor ah,ah
        call decode_opcode
        ret
op_rep  ENDP

add_mne MACRO com_txt, sep
        mov ax,OFFSET com_txt
        sub ax,OFFSET mne_tab
        add ax,sep
        mov [di],ax
        add di,2
                ENDM

        extrn b_txt:near
        extrn w_txt:near
        extrn d_txt:near

        public op_string2b

op_string2b     PROC near
        mov al,ds:gaddr_mode
        or al,al
        jz op_stringb16
op_stringb32:
        mov ax,6
        call calc_ads_offset
        mov ds:data_sel,OFFSET ds_txt
        add_mne b_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne edi_txt, par_komma_sep
        add_mne ds_txt, kolon_par_sep
        add_mne esi_txt, rhak_sep
        ret
op_stringb16:
        mov ax,4
        call calc_ads_offset
        mov ds:data_sel,OFFSET ds_txt
        add_mne b_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne di_txt, par_komma_sep
        add_mne ds_txt, kolon_par_sep
        add_mne si_txt, rhak_sep
        ret     
op_string2b     ENDP

        public op_string2w

op_string2w     PROC near
        mov al,ds:gdata_mode
        or al,al
        jnz op_string2d
        mov al,ds:gaddr_mode
        or al,al
        jz op_string2w16
op_string2w32:
        mov ax,6
        call calc_ads_offset
        mov ds:data_sel,OFFSET ds_txt
        add_mne w_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne edi_txt, par_komma_sep
        add_mne ds_txt, kolon_par_sep
        add_mne esi_txt, rhak_sep
        ret
op_string2w16:
        mov ax,4
        call calc_ads_offset
        mov ds:data_sel,OFFSET ds_txt
        add_mne w_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne di_txt, par_komma_sep
        add_mne ds_txt, kolon_par_sep
        add_mne si_txt, rhak_sep
        ret
op_string2d:
        mov al,ds:gaddr_mode
        or al,al
        jz op_string2d16
op_string2d32:
        mov ax,6
        call calc_ads_offset
        mov ds:data_sel,OFFSET ds_txt
        add_mne d_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne edi_txt, par_komma_sep
        add_mne ds_txt, kolon_par_sep
        add_mne esi_txt, rhak_sep
        ret
op_string2d16:
        mov ax,4
        call calc_ads_offset
        mov ds:data_sel,OFFSET ds_txt
        add_mne d_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne di_txt, par_komma_sep
        add_mne ds_txt, kolon_par_sep
        add_mne si_txt, rhak_sep
        ret     
op_string2w     ENDP


        public op_string1b

op_string1b     PROC near
        mov al,ds:gaddr_mode
        or al,al
        jz op_string1b16
op_string1b32:
        mov ax,7
        call calc_ads_offset
        mov ds:data_sel,OFFSET es_txt
        add_mne b_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne edi_txt, rhak_sep
        ret
op_string1b16:
        mov ax,5
        call calc_ads_offset
        mov ds:data_sel,OFFSET es_txt
        add_mne b_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne di_txt, rhak_sep
        ret     
op_string1b     ENDP

        public op_string1w

op_string1w     PROC near
        mov al,ds:gdata_mode
        or al,al
        jnz op_string1d
        mov al,ds:gaddr_mode
        or al,al
        jz op_string1w16
op_string1w32:
        mov ax,7
        call calc_ads_offset
        mov ds:data_sel,OFFSET es_txt
        add_mne w_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne edi_txt, rhak_sep
        ret
op_string1w16:
        mov ax,5
        call calc_ads_offset
        mov ds:data_sel,OFFSET es_txt
        add_mne w_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne di_txt, rhak_sep
        ret
op_string1d:
        mov al,ds:gaddr_mode
        or al,al
        jz op_string1d16
op_string1d32:
        mov ax,7
        call calc_ads_offset
        mov ds:data_sel,OFFSET es_txt
        add_mne d_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne edi_txt, rhak_sep
        ret
op_string1d16:
        mov ax,5
        call calc_ads_offset
        mov ds:data_sel,OFFSET es_txt
        add_mne d_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne di_txt, rhak_sep
        ret     
op_string1w     ENDP

        extrn txt_16:near
        extrn txt_32:near

        public op_add_opsize

op_add_opsize   PROC near
        mov al,ds:gdata_mode
        or al,al
        jz op_add16
op_add32:
        add_mne txt_32, blank_sep
        ret
op_add16:
        add_mne txt_16, blank_sep
        ret
op_add_opsize   ENDP

        public op_word16

op_word16       PROC near
        call op_add_opsize
        mov ax,[si+1]
        call add_hex_word
        add si,2
        ret
op_word16       ENDP

        public op_math_reg

op_math_reg     PROC near
        mov ds:data_mode,data_16
        call decode_math_mem
        ret
op_math_reg     ENDP

        public opmr_mem8

opmr_mem8       PROC near
        mov ds:data_mode,data_8
        call decode_mem_mode
        ret
opmr_mem8       ENDP

        public opmr_mem16

opmr_mem16      PROC near
        mov ds:data_mode,data_16
        call decode_mem_mode
        ret
opmr_mem16      ENDP

        public opmr_mem2

opmr_mem2       PROC near
        mov ds:data_mode,data_8
        inc si
        call decode_mem_mode
        ret
opmr_mem2       ENDP

        public opmr_mem3

opmr_mem3       PROC near
        mov ds:data_mode,data_8
        inc si
        call decode_mem_mode
        mov ds:edata_mode,data_48
        ret
opmr_mem3       ENDP

        public op_mem_byte3

op_mem_byte3    PROC near
        inc si
        call opmr_mem_im8
        ret
op_mem_byte3    ENDP

        public opmr_mem_im8

opmr_mem_im8    PROC near
        mov ds:data_mode,data_8
        call decode_mem_mode
        call add_komma_to_mem
        mov al,[si+1]
        call add_hex_byte
        inc si
        ret
opmr_mem_im8    ENDP

        public opmr_mem_im16

opmr_mem_im16   PROC near
        mov ds:data_mode,data_16
        call decode_mem_mode
        call add_komma_to_mem
        mov al,ds:edata_mode
        cmp al,data_32
        jne not_opmr32
        mov eax,[si+1]
        call add_hex_dword
        add si,4
        ret
not_opmr32:
        mov ax,[si+1]
        call add_hex_word
        add si,2
        ret
opmr_mem_im16   ENDP

        public opmr_mem_extend_im16

opmr_mem_extend_im16    PROC near
        mov ds:data_mode,data_16
        call decode_mem_mode
        call add_komma_to_mem
        mov al,ds:edata_mode
        cmp al,data_32
        jne not_eopmr32
        movzx eax,byte ptr [si+1]
        call add_hex_dword
        inc si
        ret
not_eopmr32:
        movzx ax,byte ptr [si+1]
        call add_hex_word
        inc si
        ret
opmr_mem_extend_im16    ENDP

        public op_reg_mem_byte

op_reg_mem_byte PROC near
        mov ds:data_mode,data_8
        mov al,[si+1]
        call decode_reg
        mov ax,[di-2]
        and ax,0FFFh
        or ax,komma_sep
        mov [di-2],ax
        call decode_mem_mode
        inc si
        ret
op_reg_mem_byte ENDP

        public op_reg_mem_byte2

op_reg_mem_byte2        PROC near
        inc si
        call op_reg_mem_byte
        ret
op_reg_mem_byte2        ENDP

        public op_reg_mem_word

op_reg_mem_word PROC near
        mov ds:data_mode,data_16
        mov al,[si+1]
        call decode_reg
        mov ax,[di-2]
        and ax,0FFFh
        or ax,komma_sep
        mov [di-2],ax
        call decode_mem_mode
        inc si
        ret
op_reg_mem_word ENDP

        public op_reg_mem2_byte

op_reg_mem2_byte        PROC near
        inc si
        call op_reg_mem_byte
        ret
op_reg_mem2_byte        ENDP

        public op_reg_mem2_word

op_reg_mem2_word        PROC near
        inc si
        call op_reg_mem_word
        ret
op_reg_mem2_word        ENDP

        public op_mem_reg_byte

op_mem_reg_byte PROC near
        mov ds:data_mode,data_8
        mov al,[si+1]
        push ax
        call decode_mem_mode
        call add_komma_to_mem
        pop ax
        call decode_reg
        ret
op_mem_reg_byte ENDP

        public op_mem_reg_word

op_mem_reg_word PROC near
        mov ds:data_mode,data_16
        mov al,[si+1]
        push ax
        call decode_mem_mode
        call add_komma_to_mem
        pop ax
        call decode_reg
        ret
op_mem_reg_word ENDP

        public op_mem_reg2

op_mem_reg2     PROC near
        inc si
        call op_mem_reg_word
        ret
op_mem_reg2     ENDP

        public mem_im8

mem_im8 PROC near
        movsx eax,byte ptr [si+1]
        add ds:data_off,eax
        test al,80h
        je mem_im8_pos
        neg eax
        push ax
        mov ax,[di-2]
        and ax,0FFFh
        or ax,minus_sep
        mov [di-2],ax
        pop ax
        jmp mem_im8_j
mem_im8_pos:
        push ax
        mov ax,[di-2]
        and ax,0FFFh
        or ax,plus_sep
        mov [di-2],ax
        pop ax
mem_im8_j:
        call add_hex_byte
        inc si  
        ret
mem_im8 ENDP

        public mem_im16

mem_im16        PROC near
        movsx eax,word ptr [si+1]
        add ds:data_off,eax
        test ax,8000h
        je mem_im16_pos
        neg eax
        push ax
        mov ax,[di-2]
        and ax,0FFFh
        or ax,minus_sep
        mov [di-2],ax
        pop ax
        jmp mem_im16_j
mem_im16_pos:
        push ax
        mov ax,[di-2]
        and ax,0FFFh
        or ax,plus_sep
        mov [di-2],ax
        pop ax
mem_im16_j:
        call add_hex_word
        add si,2
        ret
mem_im16        ENDP

        public mem_im32

mem_im32        PROC near
        mov eax,[si+1]
        add ds:data_off,eax
        test eax,80000000h
        jz mem_im32_pos
        neg eax
        push ax
        mov ax,[di-2]
        and ax,0FFFh
        or ax,minus_sep
        mov [di-2],ax
        pop ax
        jmp mem_im32_save
mem_im32_pos:   
        push ax
        mov ax,[di-2]
        and ax,0FFFh
        or ax,plus_sep
        mov [di-2],ax
        pop ax
mem_im32_save:
        call add_hex_dword
        add si,4
        ret
mem_im32        ENDP

sib_im8 PROC near
        call mem_im8
        mov ax,[di-2]
        and ax,0FFFh
        or ax,rhak_sep
        mov [di-2],ax
        ret
sib_im8 ENDP

sib_im32        PROC near
        call mem_im32
        mov ax,[di-2]
        and ax,0FFFh
        or ax,rhak_sep
        mov [di-2],ax
        ret
sib_im32        ENDP

        extrn adr_sib_tab:near
        extrn adr_sib_index_tab:near

add_sib_ads     PROC near
        mov ah,[si-1]
        and ah,0C0h
        mov al,[si]
        and al,7
        shr ah,3
        or al,ah
        xor ah,ah
        shl ax,2
        mov bx,ax
        call cs:word ptr [bx].adr_sib_tab
        add ds:data_off,eax
        mov al,[si]
        and al,38h
        shr al,3
        xor ah,ah
        shl ax,2
        mov bx,ax
        call cs:word ptr [bx].adr_sib_index_tab
        mov cl,[si]
        and cl,0C0h
        shr cl,6
        shl eax,cl
        add ds:data_off,eax
        ret
add_sib_ads     ENDP

        public mem_sib

        extrn mem_sib0_tab:near
        extrn sib_scale_tab:near
        extrn sib_index_tab:near

sib_d_none      PROC near
        mov al,[si]
        and al,7
        cmp al,5
        je sib_im32
        mov ax,[di-2]
        and ax,0FFFh
        or ax,rhak_sep
        mov [di-2],ax
        ret
sib_d_none      ENDP

mem_disp_tab:
sib_dn  DW OFFSET sib_d_none
sib_d8  DW OFFSET sib_im8
sib_d32 DW OFFSET sib_im32

mem_sib PROC near
        mov ax,OFFSET mem_sib0_tab
        mov ds:op_syntax,ax
        mov ax,[si]
; al = mod
; ah = sib-byte
        and ah,7
        and al,0C0h     
        shr al,3
        or al,ah
        xor ah,ah
        inc si
        call decode_opcode
        mov ax,OFFSET sib_index_tab
        mov ds:op_syntax,ax
        mov al,[si]
        and ax,38h
        shr ax,3
        call decode_opcode      
        mov ax,OFFSET sib_scale_tab
        mov ds:op_syntax,ax
        mov al,[si]
        and ax,0C0h
        shr ax,6
        call decode_opcode
        call add_sib_ads
        mov bl,[si-1]
        and bx,0C0h
        shr bx,5
        add bx,OFFSET mem_disp_tab
        call word ptr cs:[bx]
        ret
mem_sib ENDP

        public op_illegal

op_illegal      PROC near
        ret
op_illegal      ENDP

        public op_math

op_math PROC near
        ret
op_math ENDP

        public op_one

op_one  PROC near
        ret
op_one  ENDP

        public op_reg_cr

op_reg_cr       PROC near       
        ret
op_reg_cr       ENDP

        public op_cr_reg

op_cr_reg       PROC near
        ret
op_cr_reg       ENDP

        public op_reg_dr

op_reg_dr       PROC near
        ret
op_reg_dr       ENDP

        public op_dr_reg

op_dr_reg       PROC near
        ret
op_dr_reg       ENDP

        public op_reg_tr

op_reg_tr       PROC near
        ret
op_reg_tr       ENDP

        public op_tr_reg

op_tr_reg       PROC near
        ret
op_tr_reg       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   
;
;               DESCRIPTION:    Next table procedures
;
;               PARAMETERS:             DI              OP codes out in binary
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_next      PROC near
        ret
error_next      ENDP

null_next       PROC near
        call word ptr ds:op_syntax
        ret
null_next       ENDP

math_one_next   PROC near
        mov al,[si+1]
        and ax,7
        call decode_opcode
        ret
math_one_next   ENDP

math2_next      PROC near
        mov al,[si+1]
        and ax,0C0h
        shr ax,6
        call decode_opcode
        ret
math2_next      ENDP

math_reg_next   PROC near
        mov al,[si+1]
        and ax,38h
        shr ax,3
        call decode_opcode
        ret
math_reg_next   ENDP

mem_reg_next    PROC near
        mov al,[si+1]
        and ax,38h
        shr ax,3
        call decode_opcode
        ret
mem_reg_next    ENDP

protect_next    PROC near
        mov al,[si+1]
        xor ah,ah
        call decode_opcode
        ret
protect_next    ENDP

prot2_next              PROC near
        mov al,[si+2]
        and ax,38h
        shr ax,3
        call decode_opcode
        ret
prot2_next              ENDP

cdt_next                PROC near
        mov al,[si+2]
        and ax,0C0h
        shr ax,6
        call decode_opcode
        ret
cdt_next                ENDP

mem_op_next             PROC near
        ret
mem_op_next             ENDP

        extrn ax_txt:near
        extrn eax_txt:near
        extrn bx_txt:near
        extrn ebx_txt:near
        extrn cx_txt:near
        extrn ecx_txt:near
        extrn dx_txt:near
        extrn edx_txt:near
        extrn sp_txt:near
        extrn esp_txt:near
        extrn bp_txt:near
        extrn ebp_txt:near
        extrn si_txt:near
        extrn esi_txt:near
        extrn di_txt:near
        extrn edi_txt:near

ax_next PROC near
        mov al,ds:gdata_mode
        or al,al
        jnz op_eax
op_ax:
        mov ax,OFFSET ax_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
op_eax:
        mov ax,OFFSET eax_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
ax_next ENDP

bx_next PROC near
        mov al,ds:gdata_mode
        or al,al
        jnz op_ebx
op_bx:
        mov ax,OFFSET bx_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
op_ebx:
        mov ax,OFFSET ebx_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
bx_next ENDP

cx_next PROC near
        mov al,ds:gdata_mode
        or al,al
        jnz op_ecx
op_cx:
        mov ax,OFFSET cx_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
op_ecx:
        mov ax,OFFSET ecx_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
cx_next ENDP

dx_next PROC near
        mov al,ds:gdata_mode
        or al,al
        jnz op_edx
op_dx:
        mov ax,OFFSET dx_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
op_edx:
        mov ax,OFFSET edx_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
dx_next ENDP

sp_next PROC near
        mov al,ds:gdata_mode
        or al,al
        jnz op_esp
op_sp:
        mov ax,OFFSET sp_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
op_esp:
        mov ax,OFFSET esp_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
sp_next ENDP

bp_next PROC near
        mov al,ds:gdata_mode
        or al,al
        jnz op_ebp
op_bp:
        mov ax,OFFSET bp_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
op_ebp:
        mov ax,OFFSET ebp_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
bp_next ENDP

si_next PROC near
        mov al,ds:gdata_mode
        or al,al
        jnz op_esi
op_si:
        mov ax,OFFSET si_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
op_esi:
        mov ax,OFFSET esi_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
si_next ENDP

di_next PROC near
        mov al,ds:gdata_mode
        or al,al
        jnz op_edi
op_di:
        mov ax,OFFSET di_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
op_edi:
        mov ax,OFFSET edi_txt
        sub ax,OFFSET mne_tab
        add ax,blank_sep
        mov [di],ax
        add di,2
        ret
di_next ENDP
        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   TEST_FOR_TAB
;
;               DESCRIPTION:    Test for table 
;
;               PARAMETERS:             DI              OP code out in binary
;                                               BX              OP code
;                                               AX              Table entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

next_tab:
nt00    DW OFFSET error_next
nt01    DW OFFSET error_next
nt02    DW OFFSET error_next
nt03    DW OFFSET error_next
nt04    DW OFFSET error_next
nt05    DW OFFSET error_next
nt06    DW OFFSET error_next
nt07    DW OFFSET error_next
nt08    DW OFFSET ax_next
nt09    DW OFFSET cx_next
nt0A    DW OFFSET dx_next
nt0B    DW OFFSET bx_next
nt0C    DW OFFSET sp_next
nt0D    DW OFFSET bp_next
nt0E    DW OFFSET si_next
nt0F    DW OFFSET di_next
nt10    DW OFFSET null_next
nt11    DW OFFSET math_one_next
nt12    DW OFFSET math2_next
nt13    DW OFFSET math_reg_next
nt14    DW OFFSET mem_reg_next
nt15    DW OFFSET protect_next
nt16    DW OFFSET prot2_next
nt17    DW OFFSET cdt_next
nt18    DW OFFSET error_next
nt19    DW OFFSET error_next
nt1A    DW OFFSET error_next
nt1B    DW OFFSET error_next
nt1C    DW OFFSET error_next
nt1D    DW OFFSET error_next
nt1E    DW OFFSET error_next
nt1F    DW OFFSET error_next

        
test_for_tab    PROC near
        add di,2
        add bx,2
        push bx
        mov bx,ax
        and ax,0FE0h
        cmp ax,0FE0h
        jne not_tab_n
        push bx
        sub di,2
        and bx,1Fh
        cmp bx,1Fh
        je no_add_kom
        add bx,bx
        call word ptr cs:[bx].next_tab
        pop ax
        and ax,0F000h
        jz no_add_kom
        add ax,OFFSET txt_noth
        sub ax,OFFSET mne_tab
        mov [di],ax
        add di,2
        jmp not_tab_n
no_add_kom:
        pop ax
not_tab_n:
        pop bx
        ret
test_for_tab    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DECODE_OPCODE
;
;               DESCRIPTION:    Decode OP code
;
;               PARAMETERS:             DI              OP code out in binary
;                                               AX              Table index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
decode_opcode   PROC near
        mov bx,ax
        add bx,bx
        add bx,bx
        add bx,ax
        add bx,bx
        add bx,ds:op_syntax
        mov ax,cs:[bx]
        mov ds:op_syntax,ax
        add bx,2
        mov ax,cs:[bx]
        mov [di],ax
        call test_for_tab
        mov ax,cs:[bx]
        mov [di],ax
        call test_for_tab
        mov ax,cs:[bx]
        mov [di],ax
        call test_for_tab
        mov ax,cs:[bx]
        mov [di],ax
        call test_for_tab
        ret
decode_opcode   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   MOVE_MNE_TO_BUF
;
;               DESCRIPTION:    Move binary OP codes to text buffer
;
;               PARAMETERS:             CS:BX           OP code in
;                                               DI                      OP code in (binary) and out (text)
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_mne_to_buf PROC near
        push ax
        push di
move_mne_loop:
        mov al,cs:[bx]
        inc bx
        or al,al
        jne move_mne_not_end
        pop ax
        jmp move_mne_end
move_mne_not_end:
        cmp al,' '
        jne move_mne_ok
        mov ah,ds:ignore_ptr
        or ah,ah
        je move_mne_ok
        mov ah,cs:[bx]
        cmp ah,'p'
        jne move_mne_ok
        pop di
        dec di
        jmp move_mne_end
move_mne_ok:
        stosb
        jmp move_mne_loop
move_mne_end:
        pop ax
        ret
move_mne_to_buf ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   PUT_OPCODE_IN_TEXT
;
;               DESCRIPTION:    Convert OP code to text form
;
;               PARAMETERS:             DI      Opcode buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extrn word_ptr_txt:near
        extrn dword_ptr_txt:near

put_opcode_in_text      PROC near
        mov si,OFFSET op_codes
wr_op_next:
        mov ax,[si]
        cmp ax,0FFFFh
        je wr_op_end
        mov bx,ax
        and bx,0FFFh
        add bx,OFFSET mne_tab
        cmp bx,OFFSET word_ptr_txt
        jne not_put_dwptr
        mov al,ds:edata_mode
        cmp al,data_32
        jne not_put_dwptr
        mov bx,OFFSET dword_ptr_txt
not_put_dwptr:
        cmp bx,OFFSET ds_txt
        je seg_reg_ov
        cmp bx,OFFSET ss_txt
        jne not_seg_reg
seg_reg_ov:
        mov ds:data_sel,bx
        mov cx,ds:override
        or cx,cx
        jz not_seg_reg
        cmp cx,0FFFFh
        jz not_seg_reg
        mov bx,cx
        mov ds:override,0FFFFh
        mov ds:data_sel,bx
not_seg_reg:
        call move_mne_to_buf
        add si,2
        and ax,0F000h
        rol ax,5
        mov bx,ax
        add bx,OFFSET sep_tab
        mov ax,cs:[bx]
        cmp al,0
        je wr_op_sep_empt
        mov [di],al
        inc di
wr_op_sep_empt:
        cmp ah,0
        je wr_op_sep_null
        mov [di],ah
        inc di
wr_op_sep_null:
        jmp wr_op_next
wr_op_end:
        mov ax,ds:override
        or ax,ax
        je wr_ov_klar
        cmp ax,0FFFFh
        je wr_ov_klar
        mov bx,ax
        mov al,[di-1]
        cmp al,20h
        je wr_ov_space
        mov al,20h
        mov [di],al
        inc al
wr_ov_space:
        call move_mne_to_buf
        mov al,':'
        mov [di],al
        inc di
wr_ov_klar:
        ret
put_opcode_in_text      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DECODE_DATA_SEL
;
;               DESCRIPTION:    Get data selector
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extrn ds_sel:near
        extrn ss_sel:near
        extrn cs_sel:near
        extrn es_sel:near
        extrn fs_sel:near
        extrn gs_sel:near

decode_data_sel PROC near
        mov ax,ds:data_sel
        cmp ax,OFFSET ds_txt
        jnz not_ds_ads
        call ds_sel
        ret
not_ds_ads:
        cmp ax,OFFSET ss_txt
        jnz not_ss_ads
        call ss_sel
        ret
not_ss_ads:
        cmp ax,OFFSET cs_txt
        jnz not_cs_ads
        call cs_sel
        ret
not_cs_ads:
        cmp ax,OFFSET es_txt
        jnz not_es_ads
        call es_sel
        ret
not_es_ads:
        cmp ax,OFFSET fs_txt
        jnz not_fs_ads
        call fs_sel
        ret
not_fs_ads:
        cmp ax,OFFSET gs_txt
        jnz not_gs_ads
        call gs_sel
        ret
not_gs_ads:
        ret
decode_data_sel ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DIS_ASS_ONE
;
;               DESCRIPTION:    Disassembler on instruction
;
;               PARAMETERS:             DS              Data segment
;                                               DX = 0  16 bit segment
;                                               DX = 1  32 bit segment
;                       DI      Data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public dis_ass_one

dis_ass_one     PROC near
        push ds
        push es
        push ax
        push bx
        push dx
        push si
        push di
;
    push di
        mov ax,ds
        mov es,ax
        mov si,OFFSET op_in_code
        mov al,[si]
        xor ah,ah
        mov bx,OFFSET main_tab
        mov ds:op_syntax,bx
        mov di,OFFSET op_codes
        mov ds:gaddr_mode,dl
        mov ds:gdata_mode,dl
        mov ds:ignore_ptr,0
        mov ds:override,0
        mov ds:data_sel,0
        mov ds:data_off,0
        mov ds:data_good,0
;
; si = opcode
; di = resultat
; ax = index i tabell
;
        call decode_opcode
        mov word ptr [di],0FFFFh
    pop di      
        push si
;       
    push di
        call put_opcode_in_text
        call decode_data_sel
        mov cx,di
        pop ax
        sub cx,ax
        sub cx,80
        neg cx
        mov al,20h
        rep stosb
        pop cx
        sub cx,OFFSET op_in_code
        inc cx
        pop di
        add di,cx
        pop si
        pop dx
        pop bx
        pop ax
        pop es
        pop ds
        ret
dis_ass_one     ENDP
        

code    ENDS

        END 
