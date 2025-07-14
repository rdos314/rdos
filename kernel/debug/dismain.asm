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
; DISMAIN.ASM
; Main disassembler module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386

include kdebug.inc
include ..\os\gate.def
include ..\driver.def
include ..\os.def
include ..\serv.def
include ..\user.def

code    SEGMENT byte use32 public 'CODE'

        extrn main_tab:near
        extrn long_main_tab:near
        extrn mne_tab:near
        extrn sep_tab:near
        extrn txt_noth:near
        extrn cr_tab:near
        extrn dr_tab:near

    
    assume cs:code

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
addr_64         EQU 2

;ceci pour garder la taille de l'instruction decodée

op_code_size            DD ?    ;ceci represente la somme de :
;                                       - la taille du code de l'instruction
;                                          COMMENT LA TROUVER :
;                                               * nous pouvons avoir soit un prefixe
;                                               * les instructions c'est 1 ou 2 byte pas plus
;                                                 - les instructions commencant par 0x0F (protected instructions)
;                                                   Nous allons pister ces instructions         
;                                                 - Certaine du co-processeur
;
;                                       - la taille des membres de l'instruction
;                                          (ESI est incrementé de cette valeur après 
;                                        l'interprétation de la synthaxe)
;

add_mne MACRO com_txt, sep
        mov eax,OFFSET com_txt
        sub eax,OFFSET mne_tab
        add eax,sep
        mov [edi],eax
        add edi,4
                ENDM
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   no_adr
;
;               DESCRIPTION:    no address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public no_adr

no_adr  PROC near
        xor eax,eax
        xor ebx,ebx
        ret
no_adr  ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   bx_adr
;
;               DESCRIPTION:    BX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public bx_adr

bx_adr  PROC near
        movzx eax,word ptr ds:[ebp].reg_ebx
        xor ebx,ebx
        ret
bx_adr  ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   bp_adr
;
;               DESCRIPTION:    BP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public bp_adr

bp_adr  PROC near
        movzx eax,word ptr ds:[ebp].reg_ebp
        xor ebx,ebx
        ret
bp_adr  ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   si_adr
;
;               DESCRIPTION:    SI address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public si_adr

si_adr  PROC near
        movzx eax,word ptr ds:[ebp].reg_esi
        xor ebx,ebx
        ret
si_adr  ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   di_adr
;
;               DESCRIPTION:    DI address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public di_adr

di_adr  PROC near
        movzx eax,word ptr ds:[ebp].reg_edi
        xor ebx,ebx
        ret
di_adr  ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   eax_adr
;
;               DESCRIPTION:    EAX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public eax_adr

eax_adr PROC near
        mov eax,ds:[ebp].reg_eax
        xor ebx,ebx
        ret
eax_adr ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ebx_adr
;
;               DESCRIPTION:    EBX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ebx_adr

ebx_adr PROC near
        mov eax,ds:[ebp].reg_ebx
        xor ebx,ebx
        ret
ebx_adr ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ecx_adr
;
;               DESCRIPTION:    ECX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ecx_adr

ecx_adr PROC near
        mov eax,ds:[ebp].reg_ecx
        xor ebx,ebx
        ret
ecx_adr ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   edx_adr
;
;               DESCRIPTION:    EDX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public edx_adr

edx_adr PROC near
        mov eax,ds:[ebp].reg_edx
        xor ebx,ebx
        ret
edx_adr ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   esi_adr
;
;               DESCRIPTION:    ESI address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public esi_adr

esi_adr PROC near
        mov eax,ds:[ebp].reg_esi
        xor ebx,ebx
        ret
esi_adr ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   edi_adr
;
;               DESCRIPTION:    EDI address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public edi_adr

edi_adr PROC near
        mov eax,ds:[ebp].reg_edi
        xor ebx,ebx
        ret
edi_adr ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ebp_adr
;
;               DESCRIPTION:    EBP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ebp_adr

ebp_adr PROC near
        mov eax,ds:[ebp].reg_ebp
        xor ebx,ebx
        ret
ebp_adr ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   esp_adr
;
;               DESCRIPTION:    ESP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public esp_adr

esp_adr PROC near
        mov eax,ds:[ebp].reg_esp
        xor ebx,ebx
        ret
esp_adr ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   eip_adr
;
;               DESCRIPTION:    EIP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public eip_adr

eip_adr PROC near
        mov eax,ds:[ebp].reg_eip
        add eax,esi
        lea ebx,ds:[ebp].code_cache        
        sub eax,ebx
        add eax,5
        xor ebx,ebx
        ret
eip_adr ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   rax_adr
;
;               DESCRIPTION:    RAX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public rax_adr

rax_adr PROC near
        mov eax,ds:[ebp].reg_eax
        mov ebx,ds:[ebp].reg_eax+4
        ret
rax_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   rbx_adr
;
;               DESCRIPTION:    RBX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public rbx_adr

rbx_adr PROC near
        mov eax,ds:[ebp].reg_ebx
        mov ebx,ds:[ebp].reg_ebx+4
        ret
rbx_adr ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   rcx_adr
;
;               DESCRIPTION:    RCX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public rcx_adr

rcx_adr PROC near
        mov eax,ds:[ebp].reg_ecx
        mov ebx,ds:[ebp].reg_ecx+4
        ret
rcx_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   rdx_adr
;
;               DESCRIPTION:    RDX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public rdx_adr

rdx_adr PROC near
        mov eax,ds:[ebp].reg_edx
        mov ebx,ds:[ebp].reg_edx+4
        ret
rdx_adr ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   rsi_adr
;
;               DESCRIPTION:    RSI address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public rsi_adr

rsi_adr PROC near
        mov eax,ds:[ebp].reg_esi
        mov ebx,ds:[ebp].reg_esi+4
        ret
rsi_adr ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   rdi_adr
;
;               DESCRIPTION:    RDI address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public rdi_adr

rdi_adr PROC near
        mov eax,ds:[ebp].reg_edi
        mov ebx,ds:[ebp].reg_edi+4
        ret
rdi_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   rbp_adr
;
;               DESCRIPTION:    RBP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public rbp_adr

rbp_adr PROC near
        mov eax,ds:[ebp].reg_ebp
        mov ebx,ds:[ebp].reg_ebp+4
        ret
rbp_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   rsp_adr
;
;               DESCRIPTION:    RSP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public rsp_adr

rsp_adr PROC near
        mov eax,ds:[ebp].reg_esp
        mov ebx,ds:[ebp].reg_esp+4
        ret
rsp_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   rip_adr
;
;               DESCRIPTION:    RIP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public rip_adr

rip_adr PROC near
        mov eax,ds:[ebp].reg_eip
        add eax,esi
        lea ebx,ds:[ebp].code_cache        
        sub eax,ebx
        add eax,5
        mov ebx,ds:[ebp].reg_eip+4
        ret
rip_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r8_adr
;
;               DESCRIPTION:    R8 address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r8_adr

r8_adr PROC near
        mov eax,ds:[ebp].reg_r8
        mov ebx,ds:[ebp].reg_r8+4
        ret
r8_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r9_adr
;
;               DESCRIPTION:    R9 address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r9_adr

r9_adr PROC near
        mov eax,ds:[ebp].reg_r9
        mov ebx,ds:[ebp].reg_r9+4
        ret
r9_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r10_adr
;
;               DESCRIPTION:    R10 address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r10_adr

r10_adr PROC near
        mov eax,ds:[ebp].reg_r10
        mov ebx,ds:[ebp].reg_r10+4
        ret
r10_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r11_adr
;
;               DESCRIPTION:    R11 address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r11_adr

r11_adr PROC near
        mov eax,ds:[ebp].reg_r11
        mov ebx,ds:[ebp].reg_r11+4
        ret
r11_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r12_adr
;
;               DESCRIPTION:    R12 address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r12_adr

r12_adr PROC near
        mov eax,ds:[ebp].reg_r12
        mov ebx,ds:[ebp].reg_r12+4
        ret
r12_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r13_adr
;
;               DESCRIPTION:    R13 address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r13_adr

r13_adr PROC near
        mov eax,ds:[ebp].reg_r13
        mov ebx,ds:[ebp].reg_r13+4
        ret
r13_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r14_adr
;
;               DESCRIPTION:    R14 address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r14_adr

r14_adr PROC near
        mov eax,ds:[ebp].reg_r14
        mov ebx,ds:[ebp].reg_r14+4
        ret
r14_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r15_adr
;
;               DESCRIPTION:    R15 address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r15_adr

r15_adr PROC near
        mov eax,ds:[ebp].reg_r15
        mov ebx,ds:[ebp].reg_r15+4
        ret
r15_adr ENDP


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r8d_adr
;
;               DESCRIPTION:    R8d address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r8d_adr

r8d_adr PROC near
        mov eax,ds:[ebp].reg_r8
        ret
r8d_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r9d_adr
;
;               DESCRIPTION:    R9d address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r9d_adr

r9d_adr PROC near
        mov eax,ds:[ebp].reg_r9
        ret
r9d_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r10d_adr
;
;               DESCRIPTION:    R10d address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r10d_adr

r10d_adr PROC near
        mov eax,ds:[ebp].reg_r10
        ret
r10d_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r11d_adr
;
;               DESCRIPTION:    R11d address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r11d_adr

r11d_adr PROC near
        mov eax,ds:[ebp].reg_r11
        ret
r11d_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r12d_adr
;
;               DESCRIPTION:    R12d address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r12d_adr

r12d_adr PROC near
        mov eax,ds:[ebp].reg_r12
        ret
r12d_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r13d_adr
;
;               DESCRIPTION:    R13d address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r13d_adr

r13d_adr PROC near
        mov eax,ds:[ebp].reg_r13
        ret
r13d_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r14d_adr
;
;               DESCRIPTION:    R14d address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r14d_adr

r14d_adr PROC near
        mov eax,ds:[ebp].reg_r14
        ret
r14d_adr ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   r15d_adr
;
;               DESCRIPTION:    R15d address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public r15d_adr

r15d_adr PROC near
        mov eax,ds:[ebp].reg_r15
        ret
r15d_adr ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   PUT_HEX_CODE
;
;               DESCRIPTION:    Put hex code
;
;               PARAMETERS:             AL      Value
;                                               EDI     OP_CODES
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

put_hex_code    PROC near
        push ebx
        xor bh,bh
        mov bl,al
        and bl,0F0h
        shr bl,4
        add ebx,ebx     
        add ebx,no_sep
        movzx ebx,bx
        mov [edi],ebx
        movzx ebx,al
        and bl,0Fh
        add ebx,ebx
        add ebx,no_sep
        mov [edi+4],ebx
        add edi,8
        pop ebx
        ret
put_hex_code    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ADD_HEX_BYTE
;
;               DESCRIPTION:    Add hex byte
;
;               PARAMETERS:             AL       Value
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
;               DESCRIPTION:    Add hex word
;
;               PARAMETERS:             AX      Value
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
;               DESCRIPTION:    Add hex dword
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
;               NAME:                   ADD_HEX_QWORD
;
;               DESCRIPTION:    Add hex qword
;
;               PARAMETERS:             EDX:EAX             Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn uscore_txt:near

add_hex_qword   PROC near
        push eax
        push edx
;
        push eax
;
        push edx        
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
        add_mne uscore_txt, no_sep
;
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
        pop edx
        pop eax
        ret
add_hex_qword   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CALC_ADS_OFFSET
;
;               DESCRIPTION:    Calculate adress offset
;
;               PARAMETERS:             EAX             Table index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extrn adr_16a_tab:near
        extrn adr_32a_tab:near

calc_ads_offset PROC near
        push eax
        test ds:[ebp].em_flags,a32
        jnz c_a_ad32

c_a_ad16:
        mov ebx,OFFSET adr_16a_tab
        cmp eax,18h
        jae calc_out_o_r
        mov ds:[ebp].data_valid,1
        shl eax,3
        add ebx,eax
        push ebx
        call dword ptr cs:[ebx]
        pop ebx
        add ds:[ebp].data_offset,eax
        call dword ptr cs:[ebx+4]
        add ds:[ebp].data_offset,eax
        mov word ptr ds:[ebp].data_offset+2,0
        jmp calc_out_o_r
c_a_ad32:
        mov ebx,OFFSET adr_32a_tab
        cmp eax,18h
        jae calc_out_o_r
        mov ds:[ebp].data_valid,1
        shl eax,3
        add ebx,eax
        push ebx
        call dword ptr cs:[ebx]
        pop ebx
        add ds:[ebp].data_offset,eax
        call dword ptr cs:[ebx+4]
        add ds:[ebp].data_offset,eax
calc_out_o_r:
        pop eax
        ret
calc_ads_offset ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LONG_CALC_ADS_OFFSET
;
;               DESCRIPTION:    Calculate long adress offset
;
;               PARAMETERS:             EAX             Table index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extrn long_adr_32a_tab:near
        extrn long_adr_64a_tab:near

long_calc_ads_offset PROC near
        push eax
;        
        test bl,1
        je lc_a_ad64_64

lc_a_ad64_32:
        mov ebx,OFFSET long_adr_32a_tab
        cmp ax,30h
        jae lcalc_out_o_r
;
        mov ds:[ebp].data_valid,1
        shl eax,3
        add ebx,eax
        push ebx        
        call dword ptr cs:[ebx]
        add ds:[ebp].data_offset,eax
        adc ds:[ebp].data_offset+4,ebx
        pop ebx
        call dword ptr cs:[ebx+4]
        add ds:[ebp].data_offset,eax
        adc ds:[ebp].data_offset+4,ebx
        jmp lcalc_out_o_r

lc_a_ad64_64:
        mov ebx,OFFSET long_adr_64a_tab
        cmp ax,30h
        jae lcalc_out_o_r
;
        mov ds:[ebp].data_valid,1
        shl eax,3
        add ebx,eax
        push ebx
        call dword ptr cs:[ebx]
        add ds:[ebp].data_offset,eax
        adc ds:[ebp].data_offset+4,ebx
        pop ebx
        call dword ptr cs:[ebx+4]
        add ds:[ebp].data_offset,eax
        adc ds:[ebp].data_offset+4,ebx
        
lcalc_out_o_r:
        pop eax
    ret
long_calc_ads_offset    Endp

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
        extrn long_mod_rm_tab:near

decode_mem_mode PROC near
        test ds:[ebp].em_flags,l64
        jnz decode_mem64
;        
        mov bx,ds:[ebp].em_flags
        and bx,a32
        mov bh,bl
        add bl,bl
        add bl,bh
        mov al,ds:[ebp].data_mode
        or al,al
        je data_8_sel
        test ds:[ebp].em_flags,d32
        jz data_8_sel
        inc al
data_8_sel:
        mov ds:[ebp].edata_mode,al
        add bl,al
        movzx ebx,bl
        mov eax,dword ptr cs:[4*ebx].mod_rm_tab
        mov ds:[ebp].op_syntax,eax
        inc esi
        mov al,[esi]
        mov ah,al
        and al,7
        and ah,0C0h
        cmp ah,0C0h
        jne dec_mem_no_ignore
        mov ds:[ebp].ignore_ptr,1
dec_mem_no_ignore:
        shr ah,3
        or al,ah
        movzx eax,al
        call calc_ads_offset
        call decode_opcode
        ret

decode_mem64:
        xor bl,bl
        test ds:[ebp].op_rex,8
        jz decode_mem64_op_ok
;
        mov bl,1

decode_mem64_op_ok:        
        mov bh,bl
        add bl,bl
        add bl,bh
        mov al,ds:[ebp].data_mode
        or al,al
        je dec64_data_8_sel
;        
        test ds:[ebp].em_flags,d32
        jz dec64_data_8_sel
;
        inc al

dec64_data_8_sel:
        mov ds:[ebp].edata_mode,al
;
        add bl,al
        movzx ebx,bl
        mov eax,dword ptr cs:[4*ebx].long_mod_rm_tab
        mov ds:[ebp].op_syntax,eax
;        
        inc esi
        mov al,[esi]
        mov ah,al
        and al,7
        test ds:[ebp].op_rex,1
        jz dec64_op_reg_ok
;
        or ax,8        

dec64_op_reg_ok:       
        and ah,0C0h
        cmp ah,0C0h
        jne dec64_mem_no_ignore
;        
        mov ds:[ebp].ignore_ptr,1

dec64_mem_no_ignore:
        shr ah,2
        or al,ah
        movzx eax,al
        call long_calc_ads_offset
        call decode_opcode
        ret
decode_mem_mode ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DECODE_MATH_MEM
;
;               DESCRIPTION:    Decode FPU memory
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extrn st_txt:near

decode_math_mem PROC near
        mov bx,ds:[ebp].em_flags
        and bx,a32
        mov bh,bl
        add bl,bl
        add bl,bh
        mov al,ds:[ebp].data_mode
        or al,al
        je mdata_8_sel
        test ds:[ebp].em_flags,d32
        jz mdata_8_sel
        inc al
mdata_8_sel:
        mov ds:[ebp].edata_mode,al
        add bl,al
        movzx ebx,bl
        mov eax,dword ptr cs:[4*ebx].mod_rm_tab
        mov ds:[ebp].op_syntax,eax
        inc esi
        mov al,[esi]
        mov ah,al
        and al,7
        and ah,0C0h
        cmp ah,0C0h
        jne no_math_reg
        mov ebx,OFFSET st_txt
        sub ebx,OFFSET mne_tab
        or bx,lpar_sep
        mov [edi],ebx
        add edi,4
        mov bl,al
        xor bh,bh
        add ebx,ebx
        or bx,rpar_sep
        mov [edi],ebx   
        add edi,4
        ret
no_math_reg:
        shr ah,3
        or al,ah
        movzx eax,al
        call calc_ads_offset
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
;               PARAMETERS:             AL              Register code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extrn reg_tab:near
        extrn long_reg_tab:near

decode_reg      PROC near
        test ds:[ebp].em_flags,l64
        jnz decode_reg64
;        
        mov bl,ds:[ebp].data_mode
        or bl,bl
        je rdata_8_sel
        test ds:[ebp].em_flags,d32
        jz rdata_8_sel
        inc bl
rdata_8_sel:
        movzx ebx,bl
        mov ecx,dword ptr cs:[4*ebx].reg_tab
        mov ds:[ebp].op_syntax,ecx
        and eax,38h
        shr eax,3
        mov ds:[ebp].ignore_ptr,1
        call decode_opcode
        ret

decode_reg64:
        mov bl,3
        test ds:[ebp].op_rex,8
        jnz rdata_64_8_sel
;
        mov bl,ds:[ebp].data_mode
        or bl,bl
        je rdata_64_8_sel
;
        test ds:[ebp].em_flags,d32
        jz rdata_64_8_sel
;
        inc bl        

rdata_64_8_sel:
        movzx ebx,bl
        mov ecx,dword ptr cs:[4*ebx].long_reg_tab
        mov ds:[ebp].op_syntax,ecx
        and eax,38h
        shr eax,3
        test ds:[ebp].op_rex,4
        jz rdata_64_do
;
        or ax,8        

rdata_64_do:        
        mov ds:[ebp].ignore_ptr,1
        call decode_opcode
        ret
decode_reg      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ADD_KOMMA_TO_MEM
;
;               DESCRIPTION:    Add dot to memory operand
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_komma_to_mem        PROC near
        mov eax,OFFSET txt_noth
        sub eax,OFFSET mne_tab
        or eax,komma_sep
        mov [edi],eax
        add edi,4
        ret
add_komma_to_mem        ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   
;
;               DESCRIPTION:    Syntax procedures
;
;               PARAMETERS:             SI      OP_CODE IN
;                                               DI      OP_CODES out in code form
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extrn noseg_txt:near
        
        public override_rex

override_rex     PROC near
        mov al,[esi]
        and al,0Fh
        mov ds:[ebp].op_rex,al
;
        mov ebx,ds:[ebp].root_tab
        mov ds:[ebp].op_syntax,ebx
        inc esi
        mov al,[esi]
        movzx eax,al
        call decode_opcode
        ret
override_rex     ENDP
        
        public override_noseg

override_noseg     PROC near
        mov ebx,ds:[ebp].root_tab
        mov ds:[ebp].op_syntax,ebx
        inc esi
        mov al,[esi]
        movzx eax,al
        call decode_opcode
        ret
override_noseg     ENDP


        public override_cs
        extrn cs_txt:near

override_cs     PROC near
        mov eax,OFFSET cs_txt
        mov ds:[ebp].override,eax
        mov ebx,ds:[ebp].root_tab
        mov ds:[ebp].op_syntax,ebx
        inc esi
        mov al,[esi]
        movzx eax,al
        call decode_opcode
        ret
override_cs     ENDP

        public override_ds
        extrn ds_txt:near

override_ds     PROC near
        mov eax,OFFSET ds_txt
        mov ds:[ebp].override,eax
        mov ebx,ds:[ebp].root_tab
        mov ds:[ebp].op_syntax,ebx
        inc esi
        mov al,[esi]
        movzx eax,al
        call decode_opcode
        ret
override_ds     ENDP

        public override_ss
        extrn ss_txt:near

override_ss     PROC near
        mov eax,OFFSET ss_txt
        mov ds:[ebp].override,eax
        mov ebx,ds:[ebp].root_tab
        mov ds:[ebp].op_syntax,ebx
        inc esi
        mov al,[esi]
        movzx eax,al
        call decode_opcode
        ret
override_ss     ENDP

        public override_es
        extrn es_txt:near

override_es     PROC near
        mov eax,OFFSET es_txt
        mov ds:[ebp].override,eax
        mov ebx,ds:[ebp].root_tab
        mov ds:[ebp].op_syntax,ebx
        inc esi
        mov al,[esi]
        movzx eax,al
        call decode_opcode
        ret
override_es     ENDP

        public override_fs
        extrn fs_txt:near

override_fs     PROC near
        mov eax,OFFSET fs_txt
        mov ds:[ebp].override,eax
        mov ebx,ds:[ebp].root_tab
        mov ds:[ebp].op_syntax,ebx
        inc esi
        mov al,[esi]
        movzx eax,al
        call decode_opcode
        ret
override_fs     ENDP

        public override_gs
        extrn gs_txt:near

override_gs     PROC near
        mov eax,OFFSET gs_txt
        mov ds:[ebp].override,eax
        mov ebx,ds:[ebp].root_tab
        mov ds:[ebp].op_syntax,ebx
        inc esi
        mov al,[esi]
        movzx eax,al
        call decode_opcode
        ret
override_gs     ENDP

        public op_byte

op_byte PROC near
        mov al,[esi+1]
        call add_hex_byte
        inc esi
        ret
op_byte ENDP

        public op_word

op_word PROC near
        test ds:[ebp].em_flags,l64
        jnz op_w64

op_wp:
        test ds:[ebp].em_flags,d32
        jz op_w16
op_w32:
        mov eax,[esi+1]
        call add_hex_dword
        add esi,4
        ret
op_w16: 
        mov ax,[esi+1]
        call add_hex_word
        add esi,2
        ret

op_w64:
        test ds:[ebp].op_rex,8
        jz op_wp        

opw64_64:
        mov eax,[esi+1]
        mov edx,[esi+5]
        add esi,8
        call add_hex_qword 
        ret       
op_word ENDP

        public op_word_mem

op_word_mem     PROC near
        test ds:[ebp].em_flags,d32
        jz op_wm16
op_wm32:
        mov eax,[esi+1]
        mov ds:[ebp].data_valid,1
        mov ds:[ebp].data_offset,eax
        call add_hex_dword
        add esi,4
        ret
op_wm16:        
        movzx eax,word ptr [esi+1]
        mov ds:[ebp].data_valid,1
        mov ds:[ebp].data_offset,eax
        call add_hex_word
        add esi,2
        ret
op_word_mem     ENDP

        public op_short

op_short        PROC near
        xor eax,eax
        xor edx,edx
        mov al,[esi+1]
        test al,80h
        jz not_op_back
;
        movsx eax,al
        mov edx,-1

not_op_back:
        inc esi
        add eax,esi
        push ebx
        lea ebx,ds:[ebp].code_cache        
        sub eax,ebx
        pop ebx
        inc eax
;        
        adc edx,0
        add eax,ds:[ebp].reg_eip
        adc edx,ds:[ebp].reg_eip+4
;        
        test ds:[ebp].em_flags,l64
        jnz op_sw64
;
        test ds:[ebp].em_flags,d32
        jz op_sw16

op_sw32:                
        call add_hex_dword
        ret

op_sw16:
        call add_hex_word
        ret

op_sw64:
        call add_hex_qword
        ret
op_short        ENDP

        public op_near

op_near PROC near
        test ds:[ebp].em_flags,d32
        jz op_near16
op_near32:
        mov eax,[esi+1]
        add esi,4
        add eax,esi
        push ebx
        lea ebx,ds:[ebp].code_cache        
        sub eax,ebx
        pop ebx
        inc eax
        add eax,ds:[ebp].reg_eip
        call add_hex_dword
        ret
op_near16:      
        mov ax,[esi+1]
        add esi,2
        add eax,esi
        push ebx
        lea ebx,ds:[ebp].code_cache        
        sub eax,ebx
        pop ebx
        inc eax
        add ax,word ptr ds:[ebp].reg_eip
        call add_hex_word
        ret
op_near ENDP

        public op_near2

op_near2        PROC near
        test ds:[ebp].em_flags,d32
        jz op_near16_2
op_near32_2:
        mov eax,[esi+2]
        add esi,5
        add eax,esi
        push ebx
        lea ebx,ds:[ebp].code_cache        
        sub eax,ebx
        pop ebx
        inc eax
        add eax,ds:[ebp].reg_eip
        call add_hex_dword
        ret
op_near16_2:    
        mov ax,[esi+2]
        add esi,3
        add eax,esi
        push ebx
        lea ebx,ds:[ebp].code_cache        
        sub eax,ebx
        pop ebx
        inc eax
        add ax,word ptr ds:[ebp].reg_eip
        call add_hex_word
        ret
op_near2        ENDP

        public op_far

op_far  PROC near
        test ds:[ebp].em_flags,d32
        jz op_far16
op_far32:
        mov ax,[esi+5]
        call add_hex_word
        mov eax,[edi-4]
        and eax,0FFFh
        add eax,kolon_sep
        mov [edi-4],eax
        mov eax,[esi+1]
        add esi,6
        call add_hex_dword
        ret
op_far16:       
        mov ax,[esi+3]
        call add_hex_word
        mov eax,[edi-4]
        and eax,0FFFh
        add eax,kolon_sep
        mov [edi-4],eax
        mov ax,[esi+1]
        call add_hex_word
        add esi,4
        ret
op_far  ENDP

        public op_enter

op_enter        PROC near
        mov ax,[esi+1]
        call add_hex_word
        mov eax,[edi-4]
        and eax,0FFFh
        add eax,komma_sep
        mov [edi-4],eax
        mov al,[esi+3]
        call add_hex_byte
        add esi,3
        ret
op_enter        ENDP

        public op_address_size

op_address_size PROC near
        mov ebx,ds:[ebp].root_tab
        mov ds:[ebp].op_syntax,ebx
        xor ds:[ebp].em_flags,a32
        inc esi
        mov al,[esi]
        movzx eax,al
        call decode_opcode
        ret
op_address_size ENDP

        public op_data_size

op_data_size    PROC near
        mov ebx,ds:[ebp].root_tab
        mov ds:[ebp].op_syntax,ebx
        xor ds:[ebp].em_flags,d32
        inc esi
        mov al,[esi]
        movzx eax,al
        call decode_opcode
        ret
op_data_size    ENDP

        public op_wait

op_wait PROC near
        mov ebx,ds:[ebp].root_tab
        mov ds:[ebp].op_syntax,ebx
        inc esi
        mov al,[esi]
        movzx eax,al
        call decode_opcode
        ret
op_wait ENDP

        public op_rep

op_rep  PROC near
        mov ebx,ds:[ebp].root_tab
        mov ds:[ebp].op_syntax,ebx
        inc esi
        mov al,[esi]
        movzx eax,al
        call decode_opcode
        ret
op_rep  ENDP

        extrn b_txt:near
        extrn w_txt:near
        extrn d_txt:near
        extrn q_txt:near

        public op_string2b

op_string2b     PROC near
        test ds:[ebp].em_flags,l64
        jnz op_stringb64
;        
        test ds:[ebp].em_flags,a32
        jz op_stringb16

op_stringb32:
        mov eax,6
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET ds_txt
        add_mne b_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne edi_txt, par_komma_sep
        add_mne ds_txt, kolon_par_sep
        add_mne esi_txt, rhak_sep
        ret

op_stringb16:
        mov eax,4
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET ds_txt
        add_mne b_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne di_txt, par_komma_sep
        add_mne ds_txt, kolon_par_sep
        add_mne si_txt, rhak_sep
        ret     

op_stringb64:
        mov eax,6
        call long_calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET noseg_txt
        add_mne b_txt, blank_sep
        add_mne noseg_txt, lhak_sep
        add_mne rdi_txt, par_komma_sep
        add_mne noseg_txt, lhak_sep
        add_mne rsi_txt, rhak_sep
        ret
op_string2b     ENDP

        public op_string2w

op_string2w     PROC near
        test ds:[ebp].em_flags,d32
        jnz op_string2d
;
        test ds:[ebp].em_flags,l64
        jnz op_string2w64
;        
        test ds:[ebp].em_flags,a32
        jz op_string2w16

op_string2w32:
        mov eax,6
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET ds_txt
        add_mne w_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne edi_txt, par_komma_sep
        add_mne ds_txt, kolon_par_sep
        add_mne esi_txt, rhak_sep
        ret

op_string2w16:
        mov eax,4
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET ds_txt
        add_mne w_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne di_txt, par_komma_sep
        add_mne ds_txt, kolon_par_sep
        add_mne si_txt, rhak_sep
        ret

op_string2w64:
        mov eax,6
        call long_calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET noseg_txt
        add_mne w_txt, blank_sep
        add_mne noseg_txt, lhak_sep
        add_mne rdi_txt, par_komma_sep
        add_mne noseg_txt, lhak_sep
        add_mne rsi_txt, rhak_sep
        ret

op_string2d:
        test ds:[ebp].em_flags,l64
        jnz op_string2d64
;
        test ds:[ebp].em_flags,a32
        jz op_string2d16

op_string2d32:
        mov eax,6
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET ds_txt
        add_mne d_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne edi_txt, par_komma_sep
        add_mne ds_txt, kolon_par_sep
        add_mne esi_txt, rhak_sep
        ret

op_string2d16:
        mov eax,4
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET ds_txt
        add_mne d_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne di_txt, par_komma_sep
        add_mne ds_txt, kolon_par_sep
        add_mne si_txt, rhak_sep
        ret     

op_string2d64:
        mov eax,6
        call long_calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET noseg_txt
        add_mne d_txt, blank_sep
        add_mne noseg_txt, rhak_sep
        add_mne rdi_txt, par_komma_sep
        add_mne noseg_txt, rhak_sep
        add_mne rsi_txt, rhak_sep
        ret
op_string2w     ENDP

        public op_lodsb

op_lodsb     PROC near
        test ds:[ebp].em_flags,l64
        jnz op_lodsb64
;
        test al,1
        jz op_lodsb16

op_lodsb32:
        mov eax,6
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET ds_txt
        add_mne b_txt, blank_sep
        add_mne ds_txt, kolon_par_sep
        add_mne esi_txt, rhak_sep
        ret

op_lodsb16:
        mov eax,4
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET ds_txt
        add_mne b_txt, blank_sep
        add_mne ds_txt, kolon_par_sep
        add_mne si_txt, rhak_sep
        ret     

op_lodsb64:
        mov eax,6
        call long_calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET noseg_txt
        add_mne b_txt, blank_sep
        add_mne noseg_txt, lhak_sep
        add_mne rsi_txt, rhak_sep
        ret
op_lodsb     ENDP

        public op_lodsw

op_lodsw     PROC near
        test ds:[ebp].em_flags,a32
        jnz op_lodsd
;
        test ds:[ebp].em_flags,l64
        jnz op_lodsw64
;        
        test al,1
        jz op_lodsw16

op_lodsw32:
        mov eax,6
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET ds_txt
        add_mne w_txt, blank_sep
        add_mne ds_txt, kolon_par_sep
        add_mne esi_txt, rhak_sep
        ret

op_lodsw16:
        mov eax,4
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET ds_txt
        add_mne w_txt, blank_sep
        add_mne ds_txt, kolon_par_sep
        add_mne si_txt, rhak_sep
        ret

op_lodsw64:
        mov eax,6
        call long_calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET noseg_txt
        add_mne w_txt, blank_sep
        add_mne noseg_txt, rhak_sep
        add_mne rsi_txt, rhak_sep
        ret

op_lodsd:
        test ds:[ebp].em_flags,l64
        jnz op_lodsd64
;
        test al,1
        jz op_lodsd16

op_lodsd32:
        mov eax,6
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET ds_txt
        add_mne d_txt, blank_sep
        add_mne ds_txt, kolon_par_sep
        add_mne esi_txt, rhak_sep
        ret

op_lodsd16:
        mov eax,6
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET ds_txt
        add_mne d_txt, blank_sep
        add_mne ds_txt, kolon_par_sep
        add_mne si_txt, rhak_sep
        ret     

op_lodsd64:
        test ds:[ebp].op_rex,8
        jnz op_lodsq64
;        
        mov eax,6
        call long_calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET noseg_txt
        add_mne d_txt, blank_sep
        add_mne noseg_txt, lhak_sep
        add_mne rsi_txt, rhak_sep
        ret

op_lodsq64:        
        mov eax,6
        call long_calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET noseg_txt
        add_mne q_txt, blank_sep
        add_mne noseg_txt, lhak_sep
        add_mne rsi_txt, rhak_sep
        ret
op_lodsw     ENDP

        public op_string1b

op_string1b     PROC near
        test ds:[ebp].em_flags,l64
        jnz op_string1b64
;        
        test ds:[ebp].em_flags,a32
        jz op_string1b16

op_string1b32:
        mov eax,7
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET es_txt
        add_mne b_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne edi_txt, rhak_sep
        ret

op_string1b16:
        mov eax,5
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET es_txt
        add_mne b_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne di_txt, rhak_sep
        ret     

op_string1b64:
        mov eax,7
        call long_calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET noseg_txt
        add_mne b_txt, blank_sep
        add_mne noseg_txt,lhak_sep
        add_mne rdi_txt, rhak_sep
        ret
op_string1b     ENDP

        public op_string1w

op_string1w     PROC near
        test ds:[ebp].em_flags,d32
        jnz op_string1d
;
        test ds:[ebp].em_flags,l64
        jnz op_string1w64
;        
        test ds:[ebp].em_flags,a32
        jz op_string1w16

op_string1w32:
        mov eax,7
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET es_txt
        add_mne w_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne edi_txt, rhak_sep
        ret

op_string1w16:
        mov eax,5
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET es_txt
        add_mne w_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne di_txt, rhak_sep
        ret

op_string1w64:
        mov eax,7
        call long_calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET noseg_txt
        add_mne w_txt, blank_sep
        add_mne noseg_txt, lhak_sep
        add_mne rdi_txt, rhak_sep
        ret
        
op_string1d:
        test ds:[ebp].em_flags,l64
        jnz op_string1d64
;
        test ds:[ebp].em_flags,a32
        jz op_string1d16

op_string1d32:
        mov eax,7
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET es_txt
        add_mne d_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne edi_txt, rhak_sep
        ret

op_string1d16:
        mov eax,5
        call calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET es_txt
        add_mne d_txt, blank_sep
        add_mne es_txt, kolon_par_sep
        add_mne di_txt, rhak_sep
        ret     

op_string1d64:
        mov eax,7
        call long_calc_ads_offset
        mov ds:[ebp].data_sel,OFFSET noseg_txt
        add_mne d_txt, blank_sep
        add_mne noseg_txt, lhak_sep
        add_mne rdi_txt, rhak_sep
        ret
        
op_string1w     ENDP

        extrn txt_16:near
        extrn txt_32:near
        extrn txt_64:near

        public op_add_opsize

op_add_opsize   PROC near
        test ds:[ebp].em_flags,d32
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
        mov ax,[esi+1]
        call add_hex_word
        add esi,2
        ret
op_word16       ENDP

        public op_math_reg

op_math_reg     PROC near
        mov ds:[ebp].data_mode,data_16
        call decode_math_mem
        ret
op_math_reg     ENDP

        public opmr_mem8

opmr_mem8       PROC near
        mov ds:[ebp].data_mode,data_8
        call decode_mem_mode
        ret
opmr_mem8       ENDP

        public opmr_mem16

opmr_mem16      PROC near
        mov ds:[ebp].data_mode,data_16
        call decode_mem_mode
        ret
opmr_mem16      ENDP

        public opmr_mem2

opmr_mem2       PROC near
        mov ds:[ebp].data_mode,data_8
        inc esi
        call decode_mem_mode
        ret
opmr_mem2       ENDP

        public opmr_mem3

opmr_mem3       PROC near
        mov ds:[ebp].data_mode,data_8
        inc esi
        call decode_mem_mode
        mov ds:[ebp].edata_mode,data_48
        ret
opmr_mem3       ENDP

        public op_mem_byte3

op_mem_byte3    PROC near
        inc esi
        call opmr_mem_im8
        ret
op_mem_byte3    ENDP

        public opmr_mem_im8

opmr_mem_im8    PROC near
        mov ds:[ebp].data_mode,data_8
        call decode_mem_mode
        call add_komma_to_mem
        mov al,[esi+1]
        call add_hex_byte
        inc esi
        ret
opmr_mem_im8    ENDP

        public opmr_mem_im16

opmr_mem_im16   PROC near
        mov ds:[ebp].data_mode,data_16
        call decode_mem_mode
        call add_komma_to_mem
        mov al,ds:[ebp].edata_mode
        cmp al,data_32
        jne not_opmr32
        mov eax,[esi+1]
        call add_hex_dword
        add esi,4
        ret
not_opmr32:
        mov ax,[esi+1]
        call add_hex_word
        add esi,2
        ret
opmr_mem_im16   ENDP

        public opmr_mem_extend_im16

opmr_mem_extend_im16    PROC near
        mov ds:[ebp].data_mode,data_16
        call decode_mem_mode
        call add_komma_to_mem
        mov al,ds:[ebp].edata_mode
        cmp al,data_32
        jne not_eopmr32
        movzx eax,byte ptr [esi+1]
        call add_hex_dword
        inc esi
        ret
not_eopmr32:
        movzx ax,byte ptr [esi+1]
        call add_hex_word
        inc esi
        ret
opmr_mem_extend_im16    ENDP

        public op_reg_mem_byte

op_reg_mem_byte PROC near
        mov ds:[ebp].data_mode,data_8
        mov al,[esi+1]
        call decode_reg
        mov eax,[edi-4]
        and eax,0FFFh
        or eax,komma_sep
        mov [edi-4],eax
        call decode_mem_mode
        ret
op_reg_mem_byte ENDP

        public op_reg_mem_byte2

op_reg_mem_byte2        PROC near
        inc esi
        call op_reg_mem_byte
        ret
op_reg_mem_byte2        ENDP

        public op_reg_mem_word

op_reg_mem_word PROC near
        mov ds:[ebp].data_mode,data_16
        mov al,[esi+1]
        call decode_reg
        mov eax,[edi-4]
        and eax,0FFFh
        or eax,komma_sep
        mov [edi-4],eax
        call decode_mem_mode
        ret
op_reg_mem_word ENDP

        public op_reg_mem2_byte

op_reg_mem2_byte        PROC near
        inc esi
        call op_reg_mem_byte
        ret
op_reg_mem2_byte        ENDP

        public op_reg_mem2_word

op_reg_mem2_word        PROC near
        inc esi
        call op_reg_mem_word
        ret
op_reg_mem2_word        ENDP

        public op_mem_reg_byte

op_mem_reg_byte PROC near
        mov ds:[ebp].data_mode,data_8
        mov al,[esi+1]
        push ax
        call decode_mem_mode
        call add_komma_to_mem
        pop ax
        call decode_reg
        ret
op_mem_reg_byte ENDP

        public op_mem_reg_word

op_mem_reg_word PROC near
        mov ds:[ebp].data_mode,data_16
        mov al,[esi+1]
        push ax
        call decode_mem_mode
        call add_komma_to_mem
        pop ax
        call decode_reg
        ret
op_mem_reg_word ENDP

        public op_mem_reg2

op_mem_reg2     PROC near
        inc esi
        call op_mem_reg_word
        ret
op_mem_reg2     ENDP

        public mem_im8

mem_im8 PROC near
        movsx eax,byte ptr [esi+1]
        add ds:[ebp].data_offset,eax
        test al,80h
        je mem_im8_pos
        neg eax
        push eax
        mov eax,[edi-4]
        and eax,0FFFh
        or eax,minus_sep
        mov [edi-4],eax
        pop eax
        jmp mem_im8_j
mem_im8_pos:
        push eax
        mov eax,[edi-4]
        and eax,0FFFh
        or eax,plus_sep
        mov [edi-4],eax
        pop eax
mem_im8_j:
        call add_hex_byte
        inc esi 
        ret
mem_im8 ENDP

        public mem_im16

mem_im16        PROC near
        movsx eax,word ptr [esi+1]
        add ds:[ebp].data_offset,eax
        test ax,8000h
        je mem_im16_pos
        neg eax
        push eax
        mov eax,[edi-4]
        and eax,0FFFh
        or eax,minus_sep
        mov [edi-4],eax
        pop eax
        jmp mem_im16_j
mem_im16_pos:
        push eax
        mov eax,[edi-4]
        and eax,0FFFh
        or eax,plus_sep
        mov [edi-4],eax
        pop eax
mem_im16_j:
        call add_hex_word
        add esi,2
        ret
mem_im16        ENDP

        public mem_im32

mem_im32        PROC near
        mov eax,[esi+1]
        add ds:[ebp].data_offset,eax
        test eax,80000000h
        jz mem_im32_pos
        neg eax
        push eax
        mov eax,[edi-4]
        and eax,0FFFh
        or eax,minus_sep
        mov [edi-4],eax
        pop eax
        jmp mem_im32_save
mem_im32_pos:   
        push eax
        mov eax,[edi-4]
        and eax,0FFFh
        or eax,plus_sep
        mov [edi-4],eax
        pop eax
mem_im32_save:
        call add_hex_dword
        add esi,4
        ret
mem_im32        ENDP

sib_im8 PROC near
        call mem_im8
        mov eax,[edi-4]
        and eax,0FFFh
        or eax,rhak_sep
        mov [edi-4],eax
        ret
sib_im8 ENDP

sib_im32        PROC near
        call mem_im32
        mov eax,[edi-4]
        and eax,0FFFh
        or eax,rhak_sep
        mov [edi-4],eax
        ret
sib_im32        ENDP

        extrn adr_sib_tab:near
        extrn adr_sib_index_tab:near

add_sib_ads     PROC near
        mov ah,[esi-1]
        and ah,0C0h
        mov al,[esi]
        and al,7
        shr ah,3
        or al,ah
        movzx eax,al
        shl eax,3
        mov ebx,eax
        call dword ptr cs:[ebx].adr_sib_tab
        add ds:[ebp].data_offset,eax
        mov al,[esi]
        and al,38h
        shr al,3
        movzx eax,al
        shl ax,3
        mov ebx,eax
        call dword ptr cs:[ebx].adr_sib_index_tab
        mov cl,[esi]
        and cl,0C0h
        shr cl,6
        shl eax,cl
        add ds:[ebp].data_offset,eax
        ret
add_sib_ads     ENDP

        public mem_sib

        extrn mem_sib0_tab:near
        extrn sib_scale_tab:near
        extrn sib_index_tab:near

sib_d_none      PROC near
        mov al,[esi]
        and al,7
        cmp al,5
        je sib_im32
        mov eax,[edi-4]
        and eax,0FFFh
        or eax,rhak_sep
        mov [edi-4],eax
        ret
sib_d_none      ENDP

mem_disp_tab:
sib_dn  DD OFFSET sib_d_none
sib_d8  DD OFFSET sib_im8
sib_d32 DD OFFSET sib_im32
sib_n   DD OFFSET sib_d_none

mem_sib PROC near
        mov eax,OFFSET mem_sib0_tab
        mov ds:[ebp].op_syntax,eax
        mov ax,[esi]
; al = mod
; ah = sib-byte
        and ah,7
        and al,0C0h     
        shr al,3
        or al,ah
        movzx eax,al
        inc esi
        call decode_opcode
        mov eax,OFFSET sib_index_tab
        mov ds:[ebp].op_syntax,eax
        mov al,[esi]
        and eax,38h
        shr eax,3
        call decode_opcode      
        mov eax,OFFSET sib_scale_tab
        mov ds:[ebp].op_syntax,eax
        mov al,[esi]
        and eax,0C0h
        shr eax,6
        call decode_opcode
        call add_sib_ads
        mov bl,[esi-1]
        and bx,0C0h
        movzx ebx,bx
        shr ebx,5
        call dword ptr cs:[4*ebx].mem_disp_tab
        ret
mem_sib ENDP

        public long_mem_sib
        extrn long_adr_sib_tab:near
        extrn long_adr_sib_index_tab:near

long_add_sib_ads     PROC near
        mov ah,[esi-1]
        and ah,0C0h
        mov al,[esi]
        and al,7
        shr ah,2
        or al,ah
;
        test ds:[ebp].op_rex,1
        jz long_sib0_ads_ok
;
        or ax,8        

long_sib0_ads_ok:               
        movzx eax,al
        shl ax,3
        mov ebx,eax
        call dword ptr cs:[ebx].long_adr_sib_tab
        add ds:[ebp].data_offset,eax
        adc ds:[ebp].data_offset+4,ebx
;
        mov al,[esi]
        and al,38h
        shr al,3
;
        test ds:[ebp].op_rex,2
        jz long_sibi_ads_ok
;
        or ax,8        

long_sibi_ads_ok:               
        movzx eax,al
        shl ax,3
        mov ebx,eax
        call dword ptr cs:[ebx].long_adr_sib_index_tab
        mov cl,[esi]
        and cl,0C0h
        shr cl,6
        shl eax,cl
        add ds:[ebp].data_offset,eax
        adc ds:[ebp].data_offset+4,ebx
        ret
long_add_sib_ads     ENDP

        public long_mem_sib
        extrn long_mem_sib0_tab:near
        extrn long_sib_index_tab:near

long_mem_sib PROC near
        mov eax,OFFSET long_mem_sib0_tab
        mov ds:[ebp].op_syntax,eax
        mov ax,[esi]
; al = mod
; ah = sib-byte
        and ah,7
        and al,0C0h     
        shr al,2
        or al,ah
;
        test ds:[ebp].op_rex,1
        jz long_sib0_ok
;
        or ax,8        

long_sib0_ok:               
        movzx eax,al
        inc esi
        call decode_opcode
;
        mov eax,OFFSET long_sib_index_tab
        mov ds:[ebp].op_syntax,eax
        mov al,[esi]
        and eax,38h
        shr eax,3
;
        test ds:[ebp].op_rex,2
        jz long_sibi_ok
;
        or ax,8        

long_sibi_ok:               
        call decode_opcode      
        mov eax,OFFSET sib_scale_tab
        mov ds:[ebp].op_syntax,eax
        mov al,[esi]
        and eax,0C0h
        shr eax,6
        call decode_opcode
        call long_add_sib_ads
        mov bl,[esi-1]
        and ebx,0C0h
        shr ebx,4
        add ebx,OFFSET mem_disp_tab
        call dword ptr cs:[ebx]
        ret
long_mem_sib ENDP

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
;               PARAMETERS:             DI                      Instruction buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_next      PROC near
        ret
error_next      ENDP

null_next       PROC near
        call dword ptr ds:[ebp].op_syntax
        ret
null_next       ENDP

math_one_next   PROC near
        mov al,[esi+1]
        and eax,7
        call decode_opcode
        ret
math_one_next   ENDP

math2_next      PROC near
        mov al,[esi+1]
        and eax,0C0h
        shr eax,6
        call decode_opcode
        ret
math2_next      ENDP

math_reg_next   PROC near
        mov al,[esi+1]
        and eax,38h
        shr eax,3
        call decode_opcode
        ret
math_reg_next   ENDP

mem_reg_next    PROC near
        mov al,[esi+1]
        and eax,38h
        shr eax,3
        call decode_opcode
        ret
mem_reg_next    ENDP

protect_next    PROC near
        mov al,[esi+1]
        movzx eax,al
        call decode_opcode
        ret
protect_next    ENDP

prot2_next              PROC near
        mov al,[esi+2]
        and eax,38h
        shr eax,3
        call decode_opcode
        ret
prot2_next              ENDP

cdt_next                PROC near
        mov al,[esi+2]
        and eax,0C0h
        shr eax,6
        call decode_opcode
        ret
cdt_next                ENDP

mem_op_next             PROC near
        ret
mem_op_next             ENDP

        extrn ax_txt:near
        extrn eax_txt:near
        extrn rax_txt:near
        extrn bx_txt:near
        extrn ebx_txt:near
        extrn rbx_txt:near
        extrn cx_txt:near
        extrn ecx_txt:near
        extrn rcx_txt:near
        extrn dx_txt:near
        extrn edx_txt:near
        extrn rdx_txt:near
        extrn sp_txt:near
        extrn esp_txt:near
        extrn rsp_txt:near
        extrn bp_txt:near
        extrn ebp_txt:near
        extrn rbp_txt:near
        extrn si_txt:near
        extrn esi_txt:near
        extrn rsi_txt:near
        extrn di_txt:near
        extrn edi_txt:near
        extrn rdi_txt:near
        extrn r8_txt:near
        extrn r9_txt:near
        extrn r10_txt:near
        extrn r11_txt:near
        extrn r12_txt:near
        extrn r13_txt:near
        extrn r14_txt:near
        extrn r15_txt:near

ax_next PROC near
        test ds:[ebp].em_flags,l64
        jnz op_r08

op_axp:                
        test ds:[ebp].em_flags,d32
        jnz op_eax
op_ax:
        mov eax,OFFSET ax_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
op_eax:
        mov eax,OFFSET eax_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret

op_r08:
        test ds:[ebp].op_rex,1
        jnz op_r8
;        
        test ds:[ebp].op_rex,8
        jz op_axp
        
op_rax:
        mov eax,OFFSET rax_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
        
op_r8:        
        mov eax,OFFSET r8_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
ax_next ENDP

bx_next PROC near
        test ds:[ebp].em_flags,l64
        jnz op_r19

op_bxp:        
        test ds:[ebp].em_flags,d32
        jnz op_ebx
op_bx:
        mov eax,OFFSET bx_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
op_ebx:
        mov eax,OFFSET ebx_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret

op_r19:
        test ds:[ebp].op_rex,1
        jnz op_r9
;        
        test ds:[ebp].op_rex,8
        jz op_bxp
        
op_rbx:
        mov eax,OFFSET rbx_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret

op_r9:
        mov eax,OFFSET r9_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
bx_next ENDP

cx_next PROC near
        test ds:[ebp].em_flags,l64
        jnz op_r210

op_cxp:        
        test ds:[ebp].em_flags,d32
        jnz op_ecx
op_cx:
        mov eax,OFFSET cx_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
op_ecx:
        mov eax,OFFSET ecx_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret

op_r210:
        test ds:[ebp].op_rex,1
        jnz op_r10
;        
        test ds:[ebp].op_rex,8
        jz op_cxp
        
op_rcx:
        mov eax,OFFSET rcx_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
        
op_r10:
        mov eax,OFFSET r10_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
cx_next ENDP

dx_next PROC near
        test ds:[ebp].em_flags,l64
        jnz op_r311

op_dxp:        
        test ds:[ebp].em_flags,d32
        jnz op_edx
op_dx:
        mov eax,OFFSET dx_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
op_edx:
        mov eax,OFFSET edx_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret

op_r311:
        test ds:[ebp].op_rex,1
        jnz op_r11
;
        test ds:[ebp].op_rex,8
        jz op_dxp        
        
op_rdx:
        mov eax,OFFSET rdx_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
        
op_r11:
        mov eax,OFFSET r11_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
dx_next ENDP

sp_next PROC near
        test ds:[ebp].em_flags,l64
        jnz op_r412

op_spp:        
        test ds:[ebp].em_flags,d32
        jnz op_esp
op_sp:
        mov eax,OFFSET sp_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
op_esp:
        mov eax,OFFSET esp_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret

op_r412:
        test ds:[ebp].op_rex,1
        jnz op_r12
;
        test ds:[ebp].op_rex,8
        jz op_spp        

op_rsp:
        mov eax,OFFSET rsp_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
        
op_r12:
        mov eax,OFFSET r12_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
sp_next ENDP

bp_next PROC near
        test ds:[ebp].em_flags,l64
        jnz op_r513

op_bpp:        
        test ds:[ebp].em_flags,d32
        jnz op_ebp
op_bp:
        mov eax,OFFSET bp_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
op_ebp:
        mov eax,OFFSET ebp_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret

op_r513:
        test ds:[ebp].op_rex,1
        jnz op_r13
;
        test ds:[ebp].op_rex,8
        jz op_bpp        
        
op_rbp:
        mov eax,OFFSET rbp_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
        
op_r13:
        mov eax,OFFSET r13_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
bp_next ENDP

si_next PROC near
        test ds:[ebp].em_flags,l64
        jnz op_r614

op_sip:        
        test ds:[ebp].em_flags,d32
        jnz op_esi
op_si:
        mov eax,OFFSET si_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
op_esi:
        mov eax,OFFSET esi_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret

op_r614:
        test ds:[ebp].op_rex,1
        jnz op_r14
;
        test ds:[ebp].op_rex,8
        jz op_sip        
        
op_rsi:
        mov eax,OFFSET rsi_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
        
op_r14:
        mov eax,OFFSET r14_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
si_next ENDP

di_next PROC near
        test ds:[ebp].em_flags,l64
        jnz op_r715

op_dip:        
        test ds:[ebp].em_flags,d32
        jnz op_edi
op_di:
        mov eax,OFFSET di_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
op_edi:
        mov eax,OFFSET edi_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret

op_r715:
        test ds:[ebp].op_rex,1
        jnz op_r15
;
        test ds:[ebp].op_rex,8
        jz op_dip

op_rdi:
        mov eax,OFFSET rdi_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret

op_r15:
        mov eax,OFFSET r15_txt
        sub eax,OFFSET mne_tab
        add eax,blank_sep
        mov [edi],eax
        add edi,4
        ret
di_next ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   TEST_FOR_TAB
;
;               DESCRIPTION:    Test for more tables, and execute
;
;               PARAMETERS:             EDI             Code buffer
;                                               EBX             opcode
;                                               EAX             Table code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

next_tab:
nt00    DD OFFSET error_next
nt01    DD OFFSET error_next
nt02    DD OFFSET error_next
nt03    DD OFFSET error_next
nt04    DD OFFSET error_next
nt05    DD OFFSET error_next
nt06    DD OFFSET error_next
nt07    DD OFFSET error_next
nt08    DD OFFSET ax_next
nt09    DD OFFSET cx_next
nt0A    DD OFFSET dx_next
nt0B    DD OFFSET bx_next
nt0C    DD OFFSET sp_next
nt0D    DD OFFSET bp_next
nt0E    DD OFFSET si_next
nt0F    DD OFFSET di_next
nt10    DD OFFSET null_next
nt11    DD OFFSET math_one_next
nt12    DD OFFSET math2_next
nt13    DD OFFSET math_reg_next
nt14    DD OFFSET mem_reg_next
nt15    DD OFFSET protect_next
nt16    DD OFFSET prot2_next
nt17    DD OFFSET cdt_next
nt18    DD OFFSET error_next
nt19    DD OFFSET error_next
nt1A    DD OFFSET error_next
nt1B    DD OFFSET error_next
nt1C    DD OFFSET error_next
nt1D    DD OFFSET error_next
nt1E    DD OFFSET error_next
nt1F    DD OFFSET error_next
        
test_for_tab    PROC near
        add edi,4
        add ebx,4
        push ebx
        mov ebx,eax
        and eax,0FE0h
        cmp eax,0FE0h
        jne not_tab_n
        push ebx
        sub edi,4
        and ebx,1Fh
        cmp ebx,1Fh
        je no_add_kom
        shl ebx,2
        call dword ptr cs:[ebx].next_tab
        pop eax
        and ax,0F000h
        jz no_add_kom
        add eax,OFFSET txt_noth
        sub eax,OFFSET mne_tab
        mov [edi],eax
        add edi,4
        jmp not_tab_n
no_add_kom:
        pop eax
not_tab_n:
        pop ebx
        ret
test_for_tab    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DECODE_OPCODE
;
;               DESCRIPTION:    Decode opcode
;
;               PARAMETERS:             EDI             Coded buffer
;                                               EAX             Table index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
decode_opcode   PROC near
        mov ebx,eax
        add ebx,ebx
        add ebx,ebx
        add ebx,eax
        add ebx,ebx
        add ebx,ebx
        add ebx,ds:[ebp].op_syntax
        mov eax,cs:[ebx]
        mov ds:[ebp].op_syntax,eax
        add ebx,4
        mov eax,cs:[ebx]
        mov [edi],eax
        call test_for_tab
        mov eax,cs:[ebx]
        mov [edi],eax
        call test_for_tab
        mov eax,cs:[ebx]
        mov [edi],eax
        call test_for_tab
        mov eax,cs:[ebx]
        mov [edi],eax
        call test_for_tab
        ret
decode_opcode   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   MOVE_MNE_TO_BUF
;
;               DESCRIPTION:    Move mnemonic to buffer
;
;               PARAMETERS:             EBX             MNE IN
;                                               EDI             Coded buffer
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_mne_to_buf PROC near
        push eax
        push edi
move_mne_loop:
        mov al,cs:[ebx]
        inc ebx
        or al,al
        jne move_mne_not_end
        pop eax
        jmp move_mne_end
move_mne_not_end:
        cmp al,' '
        jne move_mne_ok
        mov ah,ds:[ebp].ignore_ptr
        or ah,ah
        je move_mne_ok
        mov ah,cs:[ebx]
        cmp ah,'p'
        jne move_mne_ok
        pop edi
        dec edi
        jmp move_mne_end
move_mne_ok:
        mov [edi],al
        inc edi
        jmp move_mne_loop
move_mne_end:
        pop eax
        ret
move_mne_to_buf ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   PUT_OPCODE_IN_TEXT
;
;               DESCRIPTION:    Put opcodes in text form
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extrn word_ptr_txt:near
        extrn dword_ptr_txt:near

put_opcode_in_text      PROC near
        lea esi,ds:[ebp].op_codes
        lea edi,ds:[ebp].opcode_text
wr_op_next:
        mov eax,[esi]
        cmp eax,0FFFFFFFFh
        je wr_op_end
        mov ebx,eax
        and ebx,0FFFh
        add ebx,OFFSET mne_tab
        cmp ebx,OFFSET word_ptr_txt
        jne not_put_dwptr
        mov al,ds:[ebp].edata_mode
        cmp al,data_32
        jne not_put_dwptr
        mov ebx,OFFSET dword_ptr_txt
not_put_dwptr:
        cmp ebx,OFFSET ds_txt
        je seg_reg_ov
        cmp ebx,OFFSET ss_txt
        jne not_seg_reg
seg_reg_ov:
        mov ds:[ebp].data_sel,ebx
        mov ecx,ds:[ebp].override
        or ecx,ecx
        jz not_seg_reg
        cmp ecx,0FFFFFFFFh
        jz not_seg_reg
        mov ebx,ecx
        mov ds:[ebp].override,0FFFFFFFFh
        mov ds:[ebp].data_sel,ebx
not_seg_reg:
        call move_mne_to_buf
        add esi,4
        and ax,0F000h
        rol ax,5
        mov ebx,eax
        add ebx,OFFSET sep_tab
        mov ax,cs:[ebx]
        cmp al,0
        je wr_op_sep_empt
        mov [edi],al
        inc edi
wr_op_sep_empt:
        cmp ah,0
        je wr_op_sep_null
        mov [edi],ah
        inc edi
wr_op_sep_null:
        jmp wr_op_next
wr_op_end:
        mov eax,ds:[ebp].override
        or eax,eax
        je wr_ov_klar
        cmp eax,0FFFFFFFFh
        je wr_ov_klar
        mov ebx,eax
        mov al,[edi-1]
        cmp al,20h
        je wr_ov_space
        mov al,20h
        mov [edi],al
        inc al
wr_ov_space:
        call move_mne_to_buf
        mov al,':'
        mov [edi],al
        inc edi
wr_ov_klar:
        mov byte ptr [edi],0
        ret
put_opcode_in_text      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DECODE_DATA_SEL
;
;               DESCRIPTION:    Get data selector for addressing
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


decode_data_sel PROC near
        mov eax,ds:[ebp].data_sel
        cmp eax,OFFSET ds_txt
        jnz not_ds_ads
        movzx eax,ds:[ebp].reg_ds.d_selector
        mov ds:[ebp].data_sel,eax
        ret
not_ds_ads:[ebp].
        cmp eax,OFFSET ss_txt
        jnz not_ss_ads
        movzx eax,ds:[ebp].reg_ss.d_selector
        mov ds:[ebp].data_sel,eax
        ret
not_ss_ads:[ebp].
        cmp eax,OFFSET cs_txt
        jnz not_cs_ads
        movzx eax,ds:[ebp].reg_cs.d_selector
        mov ds:[ebp].data_sel,eax
        ret
not_cs_ads:[ebp].
        cmp eax,OFFSET es_txt
        jnz not_es_ads
        movzx eax,ds:[ebp].reg_es.d_selector
        mov ds:[ebp].data_sel,eax
        ret
not_es_ads:[ebp].
        cmp eax,OFFSET fs_txt
        jnz not_fs_ads
        movzx eax,ds:[ebp].reg_fs.d_selector
        mov ds:[ebp].data_sel,eax
        ret
not_fs_ads:[ebp].
        cmp eax,OFFSET gs_txt
        jnz not_gs_ads
        movzx eax,ds:[ebp].reg_gs.d_selector
        mov ds:[ebp].data_sel,eax
        ret
not_gs_ads:[ebp].
        ret
decode_data_sel ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       GetIllegalOsGate
;
;       DESCRIPTION:    Get illegal OS gate name
;
;       PARAMETERS:     ES:EDI       Name buffer
;                       ECX          Buffer size
;                       BX           Gate #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
GetIllegalOsGate    PROC near
    push ds
    push fs
    push esi
;    
    mov ax,osgate_sel
    mov ds,ax
    mov fs,[bx].os_gate_name_sel
    mov esi,[bx].os_gate_name_offset

illegal_out_os_loop:
    mov al,fs:[esi]
    or al,al
    je illegal_out_os_ok
;
    stosb
    inc esi
    loop illegal_out_os_loop

illegal_out_os_ok:
    xor al,al
    stosb
;    
    pop esi
    pop fs
    pop ds
    ret
GetIllegalOsGate    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       GetIllegalServGate
;
;       DESCRIPTION:    Get illegal server gate name
;
;       PARAMETERS:     ES:EDI       Name buffer
;                       ECX          Buffer size
;                       BX           Gate #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
GetIllegalServGate    PROC near
    push ds
    push fs
    push esi
;    
    mov ax,serv_gate_sel
    mov ds,ax
    mov fs,[bx].serv_gate_name_sel
    mov esi,[bx].serv_gate_name_offset

illegal_out_serv_loop:
    mov al,fs:[esi]
    or al,al
    je illegal_out_serv_ok
;
    stosb
    inc esi
    loop illegal_out_serv_loop

illegal_out_serv_ok:
    xor al,al
    stosb
;    
    pop esi
    pop fs
    pop ds
    ret
GetIllegalServGate    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetIllegalUserGate
;
;       DESCRIPTION:    Get illegal user gate name
;
;       PARAMETERS:     ES:EDI       Name buffer
;                       ECX          Buffer size
;                       BX           Gate #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
GetIllegalUserGate      PROC near
    push ds
    push fs
    push esi
;    
    mov ax,usergate_sel
    mov ds,ax
    mov fs,[bx].user_gate_name_sel
    mov esi,[bx].user_gate_name_offset
    
illegal_out_user_loop:
    mov al,fs:[esi]
    or al,al
    je illegal_out_user_ok
;
    stosb
    inc esi
    loop illegal_out_user_loop

illegal_out_user_ok:
    xor al,al
    stosb
;
    pop esi
    pop fs
    pop ds
    ret
GetIllegalUserGate      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       GetOsCall
;
;       DESCRIPTION:    Get OS call gate name
;
;       PARAMETERS:     ES:EDI       Name buffer
;                       ECX          Buffer size
;                       DX:EBX       Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
GetOsCall       PROC near
    push ds
    push fs
    push esi
;
    push ecx
    mov ax,osgate_sel
    mov ds,ax
    xor esi,esi
    mov ecx,osgate_entries

get_oscall_scan_loop:
    cmp dx,ds:[esi].os_gate_sel
    jne get_oscall_scan_next
;
    cmp ebx,ds:[esi].os_gate_offset
    je get_oscall_found

get_oscall_scan_next:
    add esi,1 SHL OS_GATE_SHIFT
    loop get_oscall_scan_loop
;
    pop ecx
    jmp get_oscall_error

get_oscall_found:
    pop ecx
    mov fs,[esi].os_gate_name_sel
    mov esi,[esi].os_gate_name_offset

get_oscall_out_loop:
    mov al,fs:[esi]
    or al,al
    je get_oscall_out_ok
;
    stosb
    inc esi
    loop get_oscall_out_loop

get_oscall_out_ok:
    xor al,al
    stosb
    clc
    jmp get_oscall_end

get_oscall_error:
    stc

get_oscall_end:
    pop esi
    pop fs
    pop ds
    ret
GetOsCall       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       GetServCall
;
;       DESCRIPTION:    Get server call gate name
;
;       PARAMETERS:     ES:EDI       Name buffer
;                       ECX          Buffer size
;                       DX:EBX       Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
GetServCall       PROC near
    push ds
    push fs
    push esi
;
    push ecx
    mov ax,serv_gate_sel
    mov ds,ax
    xor esi,esi
    mov ecx,serv_gate_entries

get_serv_call_scan_loop:
    cmp dx,ds:[esi].serv_gate_proc_sel
    jne get_serv_call_scan_next
;
    cmp ebx,ds:[esi].serv_gate_proc_offset
    je get_serv_call_found

get_serv_call_scan_next:
    add esi,1 SHL SERV_GATE_SHIFT
    loop get_serv_call_scan_loop
;
    pop ecx
    jmp get_serv_call_error

get_serv_call_found:
    pop ecx
    mov fs,[esi].serv_gate_name_sel
    mov esi,[esi].serv_gate_name_offset

get_serv_call_out_loop:
    mov al,fs:[esi]
    or al,al
    je get_serv_call_out_ok
;
    stosb
    inc esi
    loop get_serv_call_out_loop

get_serv_call_out_ok:
    xor al,al
    stosb
    clc
    jmp get_serv_call_end

get_serv_call_error:
    stc

get_serv_call_end:
    pop esi
    pop fs
    pop ds
    ret
GetServCall       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       GetUserCall
;
;       DESCRIPTION:    Get user gate name
;
;       PARAMETERS:     ES:EDI       Name buffer
;                       ECX          Buffer size
;                       DX:EBX       Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
GetUserCall     PROC near
    push ds
    push fs
    push esi
;
    push ecx
    mov ax,usergate_sel
    mov ds,ax
    xor esi,esi
    mov ecx,usergate_entries

get_usercall_scan_loop:
    cmp dx,ds:[esi].user_gate_entry_sel16
    jne get_usercall_not_entry16
;
    cmp ebx,ds:[esi].user_gate_entry_offset16
    je get_usercall_found

get_usercall_not_entry16:
    cmp dx,ds:[esi].user_gate_entry_sel32
    jne get_usercall_not_entry32
;
    cmp ebx,ds:[esi].user_gate_entry_offset32
    je get_usercall_found

get_usercall_not_entry32:
    cmp dx,ds:[esi].user_gate_sel16
    je get_usercall_found
;
    cmp dx,ds:[esi].user_gate_sel32
    je get_usercall_found
;
    add esi,1 SHL USER_GATE_SHIFT
    loop get_usercall_scan_loop
;
    pop ecx
    jmp short get_usercall_error

get_usercall_found:
    pop ecx
    mov fs,[esi].user_gate_name_sel
    mov esi,[esi].user_gate_name_offset

get_usercall_out_loop:
    mov al,fs:[esi]
    or al,al
    je get_usercall_out_ok
;
    stosb
    inc esi
    loop get_usercall_out_loop

get_usercall_out_ok:
    xor al,al
    stosb
    clc
    jmp get_usercall_end

get_usercall_error:
    stc

get_usercall_end:
    pop esi
    pop fs
    pop ds
    ret
GetUserCall     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CheckGate
;
;               DESCRIPTION:    Check for call gate
;
;               PARAMETERS:     DS:EBP    Cpu
;                               ESI       Instruction data
;
;               RETURNS:        EAX       Instruction size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckGate   Proc near
    push es
    push ebx
    push ecx
    push edx
    push edi
;    
    push esi
;    
    mov ax,ds
    mov es,ax
;    
    test word ptr ds:[ebp].reg_eflags+2,2
    jnz check_fail
;
    test ds:[ebp].reg_cs.d_access,ACCESS_64
    jnz check_fail
;
    xor edx,edx
    test ds:[ebp].reg_cs.d_access,ACCESS_32
    jz check_size_ok
;    
    mov dl,1

check_size_ok:

remove_ov_loop:
    mov al,[esi]
    cmp al,66h
    je remove_ads16
;
    cmp al,3Eh
    je remove_ov_one
;
    cmp al,67h
    jne remove_ov_done

remove_ov_one:    
    inc dh
    inc esi
    jmp remove_ov_loop

remove_ads16:
    inc dh
    inc esi
    xor dl,1
    jmp remove_ov_loop

remove_ov_done:
    mov al,[esi]
    cmp al,9Ah
    jne not_call_far
;
    test dl,1
    jz write_call_far16
;
    mov dx,[esi+5]
    cmp dx,2
    je oscall
;
    mov dx,[esi+5]
    cmp dx,4
    je servcall
;        
    cmp dx,3
    je usercall_32
;
    cmp dx,1
    jne not_call32

usercall_32:
    mov eax,[esi+1]
    cmp eax,usergate_entries
    jnc check_fail
;
    add esi,7
    shl eax,USER_GATE_SHIFT
    mov ebx,eax
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetIllegalUserGate
    clc
    jmp check_done

oscall:
    mov eax,[esi+1]
    cmp eax,osgate_entries
    jnc check_fail
;
    add esi,7
    shl eax,OS_GATE_SHIFT
    mov ebx,eax
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetIllegalOsGate
    clc
    jmp check_done

servcall:
    mov eax,[esi+1]
    cmp eax,serv_gate_entries
    jnc check_fail
;
    add esi,7
    shl eax,SERV_GATE_SHIFT
    mov ebx,eax
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetIllegalServGate
    clc
    jmp check_done
    
not_call32:
    mov ebx,[esi+1]
    mov dx,[esi+5]
    add esi,7    
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetOsCall
    jnc check_done
;
    sub esi,7
    mov ebx,[esi+1]
    mov dx,[esi+5]
    add esi,7    
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetServCall
    jnc check_done

not_call32_user:
    sub esi,7
    mov ebx,[esi+1]
    mov dx,[esi+5]
    add esi,7
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetUserCall
    jmp check_done

write_call_far16:
    movzx ebx,word ptr [esi+1]
    mov dx,[esi+3]
    add esi,5
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetOsCall
    jnc check_done
;
    sub esi,5
    movzx ebx,word ptr [esi+1]
    mov dx,[esi+3]
    add esi,5
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetServCall
    jnc check_done

call_far16_user:
    sub esi,5
    movzx ebx,word ptr [esi+1]
    mov dx,[esi+3]
    add esi,5
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetUserCall
    jmp check_done

not_call_far:
    cmp al,0E8h
    jne check_fail
;
    test dl,1
    jz write_call_near16
;
    inc esi
    inc dh    
    movzx ebx,dh
    add ebx,[esi]
    add ebx,ds:[ebp].reg_eip
    add ebx,4
;
    add esi,4
    push ebx
    mov dx,ds:[ebp].reg_cs.d_selector
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetOsCall
    pop ebx
    jnc check_done
;
    push ebx
    mov dx,ds:[ebp].reg_cs.d_selector
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetServCall
    pop ebx
    jnc check_done
;
    mov dx,ds:[ebp].reg_cs.d_selector
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetUserCall
    jmp check_done
    
write_call_near16:
    inc esi
    inc dh
    movzx ebx,dh
    add bx,[esi]
    add bx,word ptr ds:[ebp].reg_eip
    add bx,2
    add esi,4
;    
    push ebx
    mov dx,ds:[ebp].reg_cs.d_selector
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetOsCall
    pop ebx
    jnc check_done
;
    push ebx
    mov dx,ds:[ebp].reg_cs.d_selector
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetServCall
    pop ebx
    jnc check_done
;
    mov dx,ds:[ebp].reg_cs.d_selector
    lea edi,[ebp].opcode_text
    mov ecx,40
    call GetUserCall

check_done:    
    mov eax,esi
    pop esi
    pushf
    sub eax,esi
    popf
    jmp check_ret

check_fail:
    stc
    pop esi

check_ret:
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop es
    ret
CheckGate  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           DisAsmCode
;
;               DESCRIPTION:    Disassemble code
;
;               PARAMETERS:     DS:EBP    Cpu
;                               ES:EDI    Decoded instruction buffer
;                               ECX       Buffer size
;
;               RETURNS:        EAX       Instruction size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public DisAsmCode

DisAsmCode     PROC near
    push ebx
    push edx
    push esi
;    
    push ecx
    push edi
;
    mov ax,cs
    cmp ax,SEG code
    je dacNorm

    test ds:[ebp].reg_cs.d_access,ACCESS_64
    jnz dac64
;
    test ds:[ebp].reg_cs.d_access,ACCESS_32
    jnz dacc32

dacc16:    
    movzx esi,word ptr ds:[ebp].reg_eip
    add esi,ds:[ebp].reg_cs.d_base
    xor dx,dx
    mov ds:[ebp].em_flags,0
    jmp dacProt

dacc32: 
    mov esi,ds:[ebp].reg_eip
    add esi,ds:[ebp].reg_cs.d_base
    xor dx,dx
    mov ds:[ebp].em_flags,a32 OR d32
    jmp dacProt

dacNorm:
    test ds:[ebp].reg_cs.d_access,ACCESS_64
    jnz dac64
;
    test ds:[ebp].reg_cs.d_access,ACCESS_32
    jnz dacn32

dacn16:    
    mov dx,ds:[ebp].reg_cs.d_selector
    movzx esi,word ptr ds:[ebp].reg_eip
    mov ds:[ebp].em_flags,0
    jmp dacProt

dacn32: 
    mov dx,ds:[ebp].reg_cs.d_selector
    mov esi,ds:[ebp].reg_eip
    mov ds:[ebp].em_flags,a32 OR d32

dacProt:
    mov ecx,32
    lea ebx,ds:[ebp].code_cache

dacProtRead:
    call ds:[ebp].cpu_read_mem
    mov ds:[ebx],al
    inc esi
    inc ebx
    loop dacProtRead
;       
    mov ebx,OFFSET main_tab
    lea esi,ds:[ebp].code_cache
    jmp dacStart

dac64:
    mov ds:[ebp].op_rex,0
    mov ds:[ebp].em_flags,l64 OR d32
;
    mov edx,ds:[ebp].reg_eip+4
    mov esi,ds:[ebp].reg_eip
    mov ecx,32
    lea ebx,ds:[ebp].code_cache

dacLongRead:
    call ds:[ebp].cpu_read_mem
    mov ds:[ebx],al
    inc esi
    inc ebx
    loop dacLongRead
;
    mov ebx,OFFSET long_main_tab
    lea esi,ds:[ebp].code_cache
;
    mov al,[esi]
    cmp al,50h
    jb dacStart
;
    cmp al,60h
    jae dacStart
;
    mov ds:[ebp].op_rex,8

dacStart:                
    mov ax,osgate_sel
    verr ax
    jnz dacDis
;
    call CheckGate
    jnc dacMove

dacDis:    
    mov al,[esi]
    movzx eax,al
    lea edi,[ebp].op_codes
;
    mov ds:[ebp].op_syntax,ebx
    mov ds:[ebp].root_tab,ebx
;
    mov ds:[ebp].ignore_ptr,0
    mov ds:[ebp].override,0
    mov ds:[ebp].data_sel,0
    mov ds:[ebp].data_offset,0
    mov ds:[ebp].data_offset+4,0
    mov ds:[ebp].data_valid,0
;
; esi = opcode
; edi = result
; eax = index in table
;
    call decode_opcode
    push esi
    mov dword ptr [edi],0FFFFFFFFh
    call put_opcode_in_text
    call decode_data_sel
    pop ecx
    lea eax,ds:[ebp].code_cache        
    sub ecx,eax
    inc ecx
    mov eax,ecx

dacMove:        
    pop edi
    pop ecx
;
    push eax
    push ecx
;    
    lea esi,[ebp].opcode_text

dacMoveLoop:
    lodsb
    or al,al
    jz dacPad
;
    stosb
    loop dacMoveLoop
    jmp dacDone

dacPad:
    mov al,' '
    rep stosb

dacDone:
    pop ecx    
    pop eax
;
    pop esi
    pop edx
    pop ebx
    ret
DisAsmCode     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           IntDisAsmCode
;
;               DESCRIPTION:    Disassemble code.
;
;               PARAMETERS:     DS:EBP    Cpu
;                               ES:EDI    Decoded instruction buffer
;                               ECX       Buffer size
;
;               RETURNS:        EAX       Instruction size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public IntDisAsmCode

IntDisAsmCode     PROC near
    push ebx
    push edx
    push esi
;    
    push es
    push ecx
    push edi
;
    mov dx,ds:[ebp].reg_cs.d_selector
    lsl ecx,edx
    jnz idacFail
;
    mov esi,ds:[ebp].reg_eip
    mov ds:[ebp].em_flags,a32 OR d32
    sub ecx,esi
    jbe idacFail
;
    cmp ecx,32
    jb idacRead
;
    mov es,dx
    mov ecx,32
    lea ebx,ds:[ebp].code_cache

idacRead:
    mov al,es:[esi]
    mov ds:[ebx],al
    inc esi
    inc ebx
    loop idacRead
;       
    mov ebx,OFFSET main_tab
    lea esi,ds:[ebp].code_cache
    mov al,[esi]
    movzx eax,al
    lea edi,[ebp].op_codes
;
    mov ds:[ebp].op_syntax,ebx
    mov ds:[ebp].root_tab,ebx
;
    mov ds:[ebp].ignore_ptr,0
    mov ds:[ebp].override,0
    mov ds:[ebp].data_sel,0
    mov ds:[ebp].data_offset,0
    mov ds:[ebp].data_offset+4,0
    mov ds:[ebp].data_valid,0
;
; esi = opcode
; edi = result
; eax = index in table
;
    call decode_opcode
    push esi
    mov dword ptr [edi],0FFFFFFFFh
    call put_opcode_in_text
    call decode_data_sel
    pop ecx
    lea eax,ds:[ebp].code_cache        
    sub ecx,eax
    inc ecx
    mov eax,ecx
;
    pop edi
    pop ecx
    pop es
;
    push eax
    push ecx
;    
    lea esi,[ebp].opcode_text

idacMoveLoop:
    lodsb
    or al,al
    jz idacPad
;
    stosb
    loop idacMoveLoop
    jmp idacDone

idacFail:
    pop edi
    pop ecx
    pop es
;
    push eax
    push ecx

idacPad:
    mov al,' '
    rep stosb

idacDone:
    pop ecx    
    pop eax
;
    pop esi
    pop edx
    pop ebx
    ret
IntDisAsmCode     ENDP

code ENDS

        END 
