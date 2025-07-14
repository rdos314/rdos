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
; DEBIPC.ASM
; IPC remote debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE kdebug.inc
INCLUDE ipcdebug.inc

.386p
.387

debug_row       EQU 0
debug_col       EQU 4
debug_ant       EQU 8
debug_call      EQU 12
debug_size      EQU 16

data    SEGMENT byte public 'DATA'

cpu    cpu_struc <>

data    ENDS

code    SEGMENT byte use32 public 'CODE'

    extrn GetDebugThreadData:near
    extrn DisAsmCode:near
    extrn set_os_pos:near
    extrn get_os_pos:near

    extrn interact_incr:near
    extrn interact_decr:near
    extrn interact_set:near

    extrn incdec_eax:near
    extrn incdec_ebx:near
    extrn incdec_ecx:near
    extrn incdec_edx:near
    extrn incdec_esi:near
    extrn incdec_edi:near
    extrn incdec_esp:near
    extrn incdec_ebp:near
    extrn incdec_epc:near

    extrn incdec_rip:near
    extrn incdec_rax:near
    extrn incdec_rbx:near
    extrn incdec_rcx:near
    extrn incdec_rdx:near
    extrn incdec_rsi:near
    extrn incdec_rdi:near
    extrn incdec_r8:near
    extrn incdec_r9:near
    extrn incdec_r10:near
    extrn incdec_r11:near
    extrn incdec_r12:near
    extrn incdec_r13:near
    extrn incdec_r14:near
    extrn incdec_r15:near
    extrn incdec_rbp:near
    extrn incdec_rsp:near

    extrn incdec_cs:near
    extrn incdec_ds:near
    extrn incdec_es:near
    extrn incdec_fs:near
    extrn incdec_gs:near
    extrn incdec_ss:near

    extrn change_eax:near
    extrn change_ebx:near
    extrn change_ecx:near
    extrn change_edx:near
    extrn change_esi:near
    extrn change_edi:near
    extrn change_esp:near
    extrn change_ebp:near
    extrn change_epc:near

    extrn change_raxl:near
    extrn change_raxh:near
    extrn change_rbxl:near
    extrn change_rbxh:near
    extrn change_rcxl:near
    extrn change_rcxh:near
    extrn change_rdxl:near
    extrn change_rdxh:near
    extrn change_rsil:near
    extrn change_rsih:near
    extrn change_rdil:near
    extrn change_rdih:near
    extrn change_r8l:near
    extrn change_r8h:near
    extrn change_r9l:near
    extrn change_r9h:near
    extrn change_r10l:near
    extrn change_r10h:near
    extrn change_r11l:near
    extrn change_r11h:near
    extrn change_r12l:near
    extrn change_r12h:near
    extrn change_r13l:near
    extrn change_r13h:near
    extrn change_r14l:near
    extrn change_r14h:near
    extrn change_r15l:near
    extrn change_r15h:near
    extrn change_ripl:near
    extrn change_riph:near
    extrn change_rspl:near
    extrn change_rsph:near
    extrn change_rbpl:near
    extrn change_rbph:near

    extrn change_cs:near
    extrn change_ds:near
    extrn change_es:near
    extrn change_fs:near
    extrn change_gs:near
    extrn change_ss:near

    extrn toggle_cy:near
    extrn toggle_pa:near
    extrn toggle_ac:near
    extrn toggle_zr:near
    extrn toggle_pl:near
    extrn toggle_im:near
    extrn toggle_dir:near
    extrn toggle_ov:near
    extrn toggle_nt:near

    extrn mem_ads:near
    extrn mem_cs:near
    extrn mem_ss:near
    extrn mem_es:near
    extrn mem_pm:near
    extrn mem_phys:near

    extrn change_pm_sel:near
    extrn change_pm_offs:near
    extrn change_phys_high:near
    extrn change_phys_low:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           req_thread
;
;           DESCRIPTION:    Request current thread control block
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_thread      PROC near
    mov ecx,SIZE thread_seg
    xor edi,edi
    xor esi,esi
    rep movs byte ptr es:[edi],gs:[esi]
;
    xor edi,edi
    mov ecx,SIZE thread_seg
    ReplyMailslot
    ret
req_thread      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           req_info
;
;           DESCRIPTION:    Request info
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_info    PROC near
    GetFreePhysical
    mov es:di_free_physical,eax
    UsedBigLinear
    mov es:di_used_big,eax
    UsedSmallLinear
    mov es:di_used_small,eax
    mov bx,gs
    UsedLocalLinearThread
    mov es:di_used_local,eax
;
    xor bx,bx
    mov ax,gs:p_tss_sel
    or ax,ax
    jnz riSaveMode
;
    mov bx,gs:p_cs
    IsLongCodeSelector
    jc ri32

ri64:
    mov bx,2
    jmp riSaveMode

ri32:
    mov bx,1    
        
riSaveMode:
    mov es:di_mode,bx
;
    mov ecx,SIZE debug_req_info_struc
    xor edi,edi
    ReplyMailslot
    ret
req_info    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           req_data
;
;           DESCRIPTION:    
;
;           PARAMETERS:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_data    Proc near
    mov dx,es:dd_sel
    mov esi,es:dd_offset
    mov bx,gs
    movzx ecx,es:dd_count
    mov edi,SIZE debug_req_data_struc
    mov al,es:dd_vm
    or al,al
    jz req_pm_data
;    
    cmp al,1
    je req_vm_data
;
    jmp req_long_data

req_pm_data:
    or ecx,ecx
    jz req_data_reply

req_pm_data_loop:
    ReadThreadSelector
    stosb
    mov al,0
    jc req_pm_save
;
    inc al

req_pm_save:
    stosb
    inc esi
    loop req_pm_data_loop
    jmp req_data_reply

req_vm_data:
    or ecx,ecx
    jz req_data_reply

req_vm_data_loop:
    ReadThreadSegment
    stosb
    mov al,0
    jc req_vm_save
;
    inc al

req_vm_save:
    stosb
    inc esi
    loop req_vm_data_loop
    jmp req_data_reply

req_long_data:
    or ecx,ecx
    jz req_data_reply

req_long_data_loop:
    ReadThread64
    stosb
    mov al,0
    jc req_long_save
;
    inc al

req_long_save:
    stosb
    inc esi
    loop req_long_data_loop

req_data_reply:
    mov ecx,edi
    xor edi,edi
    ReplyMailslot
    ret
req_data    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           req_instr
;
;           DESCRIPTION:    Request instruction
;
;           PARAMETERS:     GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_instr       PROC near
    call GetDebugThreadData
;    
    mov ecx,40
    mov edi,OFFSET ddi_mne
    call DisAsmCode
;
    lea esi,[ebp].code_cache
    mov edi,OFFSET ddi_code
    mov ecx,8
    rep movsw
;
    mov al,ds:[ebp].data_valid
    mov es:ddi_data_good,al
;
    mov eax,ds:[ebp].data_offset
    mov es:ddi_data_offset,eax
;
    mov eax,ds:[ebp].data_sel    
    mov es:ddi_data_sel,ax
;
    mov ecx,SIZE debug_req_instr_struc
    xor edi,edi
    ReplyMailslot
    ret
req_instr       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DefaultReply
;
;           DESCRIPTION:    Default reply
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DefaultReply    Proc near
    call get_os_pos    
    mov es:db_x,dl
    mov es:db_y,dh
;
    mov ecx,SIZE debug_req_struc
    xor edi,edi
    ReplyMailslot
    ret
DefaultReply    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugCall32
;
;           DESCRIPTION:    Modify registers, 32-bit version
;
;           PARAMETERS:     GS              Thread
;                           DI              Address to debug-function
;                           CH              digit / param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
debug_table32:
;
;           rad     kolumn  antal   action
;
meax32 DD 9,          1,          3,          OFFSET incdec_eax
deax32 DD 9,          5,          8,          OFFSET change_eax
mebx32 DD 9,          14,         3,          OFFSET incdec_ebx
debx32 DD 9,          18,         8,          OFFSET change_ebx
mecx32 DD 9,          27,         3,          OFFSET incdec_ecx
decx32 DD 9,          31,         8,          OFFSET change_ecx
medx32 DD 9,          40,         3,          OFFSET incdec_edx
dedx32 DD 9,          44,         8,          OFFSET change_edx
mesi32 DD 10,         1,          3,          OFFSET incdec_esi
odesi32 DD 10,         5,          8,          OFFSET change_esi
medi32 DD 10,         14,         3,          OFFSET incdec_edi
dedi32 DD 10,         18,         8,          OFFSET change_edi
mesp32 DD 10,         27,         3,          OFFSET incdec_esp
desp32 DD 10,         31,         8,          OFFSET change_esp
mebp32 DD 10,         40,         3,          OFFSET incdec_ebp
debp32 DD 10,         44,         8,          OFFSET change_ebp
mepc32 DD 11,         1,          3,          OFFSET incdec_epc
depc32 DD 11,         5,          8,          OFFSET change_epc
mcs32  DD 12,         1,          2,          OFFSET incdec_cs
dcs32  DD 12,         4,          4,          OFFSET change_cs
mds32  DD 12,         9,          2,          OFFSET incdec_ds
dds32  DD 12,         12,         4,          OFFSET change_ds
mes32  DD 12,         17,         2,          OFFSET incdec_es
des32  DD 12,         20,         4,          OFFSET change_es
mfs32  DD 12,         25,         2,          OFFSET incdec_fs
dfs32  DD 12,         28,         4,          OFFSET change_fs
mgs32  DD 12,         33,         2,          OFFSET incdec_gs
dgs32  DD 12,         36,         4,          OFFSET change_gs
mss32  DD 12,         41,         2,          OFFSET incdec_ss
dss32  DD 12,         44,         4,          OFFSET change_ss
dcy32  DD 13,         0,          2,          OFFSET toggle_cy
dpa32  DD 13,         3,          2,          OFFSET toggle_pa
dac32  DD 13,         6,          2,          OFFSET toggle_ac
dzr32  DD 13,         9,          2,          OFFSET toggle_zr
dplc32 DD 13,         12,         2,          OFFSET toggle_pl
disf32 DD 13,         15,         2,          OFFSET toggle_im
ddir32 DD 13,         18,         2,          OFFSET toggle_dir
dov32  DD 13,         21,         2,          OFFSET toggle_ov
dnt32  DD 13,         24,         2,          OFFSET toggle_nt
mdad32 DD 19,         14,         47,         OFFSET mem_ads
mdcs32 DD 20,         14,         47,         OFFSET mem_cs
mdss32 DD 21,         14,         47,         OFFSET mem_ss
mdes32 DD 22,         14,         47,         OFFSET mem_es
pms32  DD 23,         0,          4,          OFFSET change_pm_sel
pmo32  DD 23,         5,          8,          OFFSET change_pm_offs
pdat32 DD 23,         14,         47,         OFFSET mem_pm
vms32  DD 24,         0,          4,          OFFSET change_phys_high
vmo32  DD 24,         5,          8,          OFFSET change_phys_low
vdat32 DD 24,         14,         47,         OFFSET mem_phys
dend32 DD 0FFFFFFFFh, 0FFFFFFFFh

DebugCallDo32     PROC near
    mov al,es:db_x
    mov ah,es:db_y
    mov ebx,OFFSET debug_table32

d_c_loop32:
    mov cl,cs:[ebx+debug_row]
    cmp cl,0FFh
    je d_c_end32
;
    cmp cl,ah
    jne not_this_entry32
;
    mov cl,al
    sub cl,cs:[ebx+debug_col]
    cmp cl,cs:[ebx+debug_ant]
    jnc not_this_entry32
;
    xor cl,7
    and cl,7
    mov al,es:db_op
    call dword ptr cs:[ebx+debug_call]
    jmp d_c_end32

not_this_entry32:
    add ebx,debug_size
    jmp d_c_loop32

d_c_end32:
    call DefaultReply
    ret
DebugCallDo32     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_sw32
;
;           DESCRIPTION:    Inc 
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_sw32  PROC near
    mov edi,OFFSET interact_incr
    call DebugCallDo32
    ret
inc_sw32  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_sw32
;
;           DESCRIPTION:    Dec 
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_sw32  PROC near
    mov edi,OFFSET interact_decr
    call DebugCallDo32
    ret
dec_sw32  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           setx_sw32
;
;           DESCRIPTION:    Set 
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_base_sw32     PROC near
    mov edi,OFFSET interact_set
    call DebugCallDo32
    ret
set_base_sw32     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugCall64
;
;           DESCRIPTION:    Modify registers, 64-bit version
;
;           PARAMETERS:     GS              Thread
;                           EDI             address to debug-function
;                           ch              digit / param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
debug_table64:
;
;           rad     kolumn  antal   action
;
mrax   DD 6,          1,          3,          OFFSET incdec_rax
draxh  DD 6,          5,          8,          OFFSET change_raxh
draxl  DD 6,          14,         8,          OFFSET change_raxl
mrbx   DD 6,          23,         3,          OFFSET incdec_rbx
drbxh  DD 6,          27,         8,          OFFSET change_rbxh
drbxl  DD 6,          36,         8,          OFFSET change_rbxl
mrcx   DD 6,          45,         3,          OFFSET incdec_rcx
drcxh  DD 6,          49,         8,          OFFSET change_rcxh
drcxl  DD 6,          58,         8,          OFFSET change_rcxl
mrdx   DD 7,          1,          3,          OFFSET incdec_rdx
drdxh  DD 7,          5,          8,          OFFSET change_rdxh
drdxl  DD 7,          14,         8,          OFFSET change_rdxl
mrsi   DD 7,          23,         3,          OFFSET incdec_rsi
drsih  DD 7,          27,         8,          OFFSET change_rsih
drsil  DD 7,          36,         8,          OFFSET change_rsil
mrdi   DD 7,          45,         3,          OFFSET incdec_rdi
drdih  DD 7,          49,         8,          OFFSET change_rdih
drdil  DD 7,          58,         8,          OFFSET change_rdil
mr8    DD 8,          2,          2,          OFFSET incdec_r8
dr8h   DD 8,          5,          8,          OFFSET change_r8h
dr8l   DD 8,          14,         8,          OFFSET change_r8l
mr9    DD 8,          24,         2,          OFFSET incdec_r9
dr9h   DD 8,          27,         8,          OFFSET change_r9h
dr9l   DD 8,          36,         8,          OFFSET change_r9l
mr10   DD 8,          45,         3,          OFFSET incdec_r10
dr10h  DD 8,          49,         8,          OFFSET change_r10h
dr10l  DD 8,          58,         8,          OFFSET change_r10l
mr11   DD 9,          1,          3,          OFFSET incdec_r11
dr11h  DD 9,          5,          8,          OFFSET change_r11h
dr11l  DD 9,          14,         8,          OFFSET change_r11l
mr12   DD 9,          23,         3,          OFFSET incdec_r12
dr12h  DD 9,          27,         8,          OFFSET change_r12h
dr12l  DD 9,          36,         8,          OFFSET change_r12l
mr13   DD 9,          45,         3,          OFFSET incdec_r13
dr13h  DD 9,          49,         8,          OFFSET change_r13h
dr13l  DD 9,          58,         8,          OFFSET change_r13l
mr14   DD 10,         1,          3,          OFFSET incdec_r14
dr14h  DD 10,         5,          8,          OFFSET change_r14h
dr14l  DD 10,         14,         8,          OFFSET change_r14l
mr15   DD 10,         23,         3,          OFFSET incdec_r15
dr15h  DD 10,         27,         8,          OFFSET change_r15h
dr15l  DD 10,         36,         8,          OFFSET change_r15l
mrip64 DD 11,         1,          3,          OFFSET incdec_rip
driph  DD 11,         5,          8,          OFFSET change_riph
dripl  DD 11,         14,         8,          OFFSET change_ripl
mrsp64 DD 11,         23,         3,          OFFSET incdec_rsp
drsph  DD 11,         27,         8,          OFFSET change_rsph
drspl  DD 11,         36,         8,          OFFSET change_rspl
mrsb64 DD 11,         45,         3,          OFFSET incdec_rbp
drbph  DD 11,         49,         8,          OFFSET change_rbph
drbpl  DD 11,         58,         8,          OFFSET change_rbpl
mcs64  DD 12,         1,          2,          OFFSET incdec_cs
dcs64  DD 12,         4,          4,          OFFSET change_cs
mds64  DD 12,         9,          2,          OFFSET incdec_ds
dds64  DD 12,         12,         4,          OFFSET change_ds
mes64  DD 12,         17,         2,          OFFSET incdec_es
des64  DD 12,         20,         4,          OFFSET change_es
mfs64  DD 12,         25,         2,          OFFSET incdec_fs
dfs64  DD 12,         28,         4,          OFFSET change_fs
mgs64  DD 12,         33,         2,          OFFSET incdec_gs
dgs64  DD 12,         36,         4,          OFFSET change_gs
mss64  DD 12,         41,         2,          OFFSET incdec_ss
dss64  DD 12,         44,         4,          OFFSET change_ss
dcy64  DD 13,         0,          2,          OFFSET toggle_cy
dpa64  DD 13,         3,          2,          OFFSET toggle_pa
dac64  DD 13,         6,          2,          OFFSET toggle_ac
dzr64  DD 13,         9,          2,          OFFSET toggle_zr
dplc64 DD 13,         12,         2,          OFFSET toggle_pl
disf64 DD 13,         15,         2,          OFFSET toggle_im
ddir64 DD 13,         18,         2,          OFFSET toggle_dir
dov64  DD 13,         21,         2,          OFFSET toggle_ov
dnt64  DD 13,         24,         2,          OFFSET toggle_nt
mdad64 DD 19,         14,         47,         OFFSET mem_ads
mdcs64 DD 20,         14,         47,         OFFSET mem_cs
mdss64 DD 21,         14,         47,         OFFSET mem_ss
mdes64 DD 22,         14,         47,         OFFSET mem_es
pms64  DD 23,         0,          4,          OFFSET change_pm_sel
pmo64  DD 23,         5,          8,          OFFSET change_pm_offs
pdat64 DD 23,         14,         47,         OFFSET mem_pm
vms64  DD 24,         0,          4,          OFFSET change_phys_high
vmo64  DD 24,         5,          8,          OFFSET change_phys_low
vdat64 DD 24,         14,         47,         OFFSET mem_phys
dend64 DD 0FFFFFFFFh, 0FFFFFFFFh

DebugCallDo64     PROC near
    mov al,es:db_x
    mov ah,es:db_y
    mov ebx,OFFSET debug_table64

d_c_loop64:
    mov cl,cs:[ebx+debug_row]
    cmp cl,0FFh
    je d_c_end64
;
    cmp cl,ah
    jne not_this_entry64
;    
    mov cl,al
    sub cl,cs:[ebx+debug_col]
    cmp cl,cs:[ebx+debug_ant]
    jnc not_this_entry64
;
    xor cl,7
    and cl,7
    mov al,es:db_op
    call dword ptr cs:[ebx+debug_call]
    jmp d_c_end64

not_this_entry64:
    add ebx,debug_size
    jmp d_c_loop64

d_c_end64:
    call DefaultReply
    ret
DebugCallDo64     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_sw64
;
;           DESCRIPTION:    Inc 
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_sw64  PROC near
    mov edi,OFFSET interact_incr
    call DebugCallDo64
    ret
inc_sw64  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_sw64
;
;           DESCRIPTION:    Dec 
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_sw64  PROC near
    mov edi,OFFSET interact_decr
    call DebugCallDo64
    ret
dec_sw64  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           setx_sw64
;
;           DESCRIPTION:    Set 
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_base_sw64     PROC near
    mov edi,OFFSET interact_set
    call DebugCallDo64
    ret
set_base_sw64     ENDP

inc_sw  PROC near
    mov ax,gs:p_tss_sel
    or ax,ax
    jz inc_sw64
    jmp inc_sw32
inc_sw  ENDP

dec_sw  PROC near
    mov ax,gs:p_tss_sel
    or ax,ax
    jz dec_sw64
    jmp dec_sw32
dec_sw  ENDP

set0_sw PROC near
    mov ch,0
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
set0_sw ENDP

set1_sw PROC near
    mov ch,1
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
set1_sw ENDP

set2_sw PROC near
    mov ch,2
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
set2_sw ENDP

set3_sw PROC near
    mov ch,3
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
set3_sw ENDP

set4_sw PROC near
    mov ch,4
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
set4_sw ENDP

set5_sw PROC near
    mov ch,5
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
set5_sw ENDP

set6_sw PROC near
    mov ch,6
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
set6_sw ENDP

set7_sw PROC near
    mov ch,7
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
set7_sw ENDP

set8_sw PROC near
    mov ch,8
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
set8_sw ENDP

set9_sw PROC near
    mov ch,9
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
set9_sw ENDP

setA_sw PROC near
    mov ch,0Ah
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
setA_sw ENDP

setB_sw PROC near
    mov ch,0Bh
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
setB_sw ENDP

setC_sw PROC near
    mov ch,0Ch
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
setC_sw ENDP

setD_sw PROC near
    mov ch,0Dh
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
setD_sw ENDP

setE_sw PROC near
    mov ch,0Eh
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
setE_sw ENDP

setF_sw PROC near
    mov ch,0Fh
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32
setF_sw ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           go_sw
;
;           DESCRIPTION:    Go
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

go_sw   PROC near
    DebugGo
    call DefaultReply
    ret
go_sw   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           trace_sw
;
;           DESCRIPTION:    Trace
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trace_sw    PROC near
    DebugTrace
    call DefaultReply
    ret
trace_sw    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           pace_sw
;
;           DESCRIPTION:    Pace 
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pace_sw PROC near
    DebugPace
    call DefaultReply
    ret
pace_sw ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           reg_sw
;
;           DESCRIPTION:    Return registers switch
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reg_sw  PROC near
    call DefaultReply
    ret
reg_sw  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           next_sw
;
;           DESCRIPTION:    Next thread switch
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

next_sw PROC near
    DebugNext
    call DefaultReply
    ret
next_sw ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           error_sw
;
;           DESCRIPTION:    Undefined switch
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_sw    PROC near
    call DefaultReply
    ret
error_sw    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugFunc
;
;           DESCRIPTION:    Handle a message
;
;           PARAMETERS:     ES          Message buffer
;                           ECX         Message size
;
;           RETURNS:        ECX         Reply size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
virt_sw_func_tab:
vs_00   DD OFFSET error_sw
vs_01   DD OFFSET req_thread
vs_02   DD OFFSET req_data
vs_03   DD OFFSET req_info
vs_04   DD OFFSET req_instr
vs_05   DD OFFSET error_sw
vs_06   DD OFFSET error_sw
vs_07   DD OFFSET error_sw
vs_08   DD OFFSET error_sw
vs_09   DD OFFSET error_sw
vs_0A   DD OFFSET error_sw
vs_0B   DD OFFSET error_sw
vs_0C   DD OFFSET error_sw
vs_0D   DD OFFSET error_sw
vs_0E   DD OFFSET error_sw
vs_0F   DD OFFSET error_sw
vs_10   DD OFFSET error_sw
vs_11   DD OFFSET error_sw
vs_12   DD OFFSET error_sw
vs_13   DD OFFSET error_sw
vs_14   DD OFFSET error_sw
vs_15   DD OFFSET error_sw
vs_16   DD OFFSET error_sw
vs_17   DD OFFSET error_sw
vs_18   DD OFFSET error_sw
vs_19   DD OFFSET error_sw
vs_1A   DD OFFSET error_sw
vs_1B   DD OFFSET error_sw
vs_1C   DD OFFSET error_sw
vs_1D   DD OFFSET error_sw
vs_1E   DD OFFSET error_sw
vs_1F   DD OFFSET error_sw
vs_20   DD OFFSET error_sw
vs_21   DD OFFSET error_sw
vs_22   DD OFFSET error_sw
vs_23   DD OFFSET error_sw
vs_24   DD OFFSET error_sw
vs_25   DD OFFSET error_sw
vs_26   DD OFFSET error_sw
vs_27   DD OFFSET error_sw
vs_28   DD OFFSET error_sw
vs_29   DD OFFSET error_sw
vs_2A   DD OFFSET error_sw
vs_2B   DD OFFSET inc_sw
vs_2C   DD OFFSET error_sw
vs_2D   DD OFFSET dec_sw
vs_2E   DD OFFSET error_sw
vs_2F   DD OFFSET error_sw
vs_30   DD OFFSET set0_sw
vs_31   DD OFFSET set1_sw
vs_32   DD OFFSET set2_sw
vs_33   DD OFFSET set3_sw
vs_34   DD OFFSET set4_sw
vs_35   DD OFFSET set5_sw
vs_36   DD OFFSET set6_sw
vs_37   DD OFFSET set7_sw
vs_38   DD OFFSET set8_sw
vs_39   DD OFFSET set9_sw
vs_3A   DD OFFSET error_sw
vs_3B   DD OFFSET error_sw
vs_3C   DD OFFSET error_sw
vs_3D   DD OFFSET error_sw
vs_3E   DD OFFSET error_sw
vs_3F   DD OFFSET error_sw
vs_40   DD OFFSET error_sw
vs_41   DD OFFSET setA_sw
vs_42   DD OFFSET setB_sw
vs_43   DD OFFSET setC_sw
vs_44   DD OFFSET setD_sw
vs_45   DD OFFSET setE_sw
vs_46   DD OFFSET setF_sw
vs_47   DD OFFSET go_sw
vs_48   DD OFFSET error_sw
vs_49   DD OFFSET error_sw
vs_4A   DD OFFSET error_sw
vs_4B   DD OFFSET error_sw
vs_4C   DD OFFSET error_sw
vs_4D   DD OFFSET error_sw
vs_4E   DD OFFSET next_sw
vs_4F   DD OFFSET error_sw
vs_50   DD OFFSET pace_sw
vs_51   DD OFFSET error_sw
vs_52   DD OFFSET reg_sw
vs_53   DD OFFSET error_sw
vs_54   DD OFFSET trace_sw
vs_55   DD OFFSET error_sw
vs_56   DD OFFSET error_sw
vs_57   DD OFFSET error_sw
vs_58   DD OFFSET error_sw
vs_59   DD OFFSET error_sw
vs_5A   DD OFFSET error_sw
vs_5B   DD OFFSET error_sw
vs_5C   DD OFFSET error_sw
vs_5D   DD OFFSET error_sw
vs_5E   DD OFFSET error_sw
vs_5F   DD OFFSET error_sw
vs_60   DD OFFSET error_sw
vs_61   DD OFFSET setA_sw
vs_62   DD OFFSET setB_sw
vs_63   DD OFFSET setC_sw
vs_64   DD OFFSET setD_sw
vs_65   DD OFFSET setE_sw
vs_66   DD OFFSET setF_sw
vs_67   DD OFFSET go_sw
vs_68   DD OFFSET error_sw
vs_69   DD OFFSET error_sw
vs_6A   DD OFFSET error_sw
vs_6B   DD OFFSET error_sw
vs_6C   DD OFFSET error_sw
vs_6D   DD OFFSET error_sw
vs_6E   DD OFFSET next_sw
vs_6F   DD OFFSET error_sw
vs_70   DD OFFSET pace_sw
vs_71   DD OFFSET error_sw
vs_72   DD OFFSET reg_sw
vs_73   DD OFFSET error_sw
vs_74   DD OFFSET trace_sw
vs_75   DD OFFSET error_sw
vs_76   DD OFFSET error_sw
vs_77   DD OFFSET error_sw
vs_78   DD OFFSET error_sw
vs_79   DD OFFSET error_sw
vs_7A   DD OFFSET error_sw
vs_7B   DD OFFSET error_sw
vs_7C   DD OFFSET error_sw
vs_7D   DD OFFSET error_sw
vs_7E   DD OFFSET error_sw
vs_7F   DD OFFSET error_sw
vs_80   DD OFFSET error_sw
vs_81   DD OFFSET error_sw
vs_82   DD OFFSET error_sw
vs_83   DD OFFSET error_sw
vs_84   DD OFFSET error_sw
vs_85   DD OFFSET error_sw
vs_86   DD OFFSET error_sw
vs_87   DD OFFSET error_sw
vs_88   DD OFFSET error_sw
vs_89   DD OFFSET error_sw
vs_8A   DD OFFSET error_sw
vs_8B   DD OFFSET error_sw
vs_8C   DD OFFSET error_sw
vs_8D   DD OFFSET error_sw
vs_8E   DD OFFSET error_sw
vs_8F   DD OFFSET error_sw
vs_90   DD OFFSET error_sw
vs_91   DD OFFSET error_sw
vs_92   DD OFFSET error_sw
vs_93   DD OFFSET error_sw
vs_94   DD OFFSET error_sw
vs_95   DD OFFSET error_sw
vs_96   DD OFFSET error_sw
vs_97   DD OFFSET error_sw
vs_98   DD OFFSET error_sw
vs_99   DD OFFSET error_sw
vs_9A   DD OFFSET error_sw
vs_9B   DD OFFSET error_sw
vs_9C   DD OFFSET error_sw
vs_9D   DD OFFSET error_sw
vs_9E   DD OFFSET error_sw
vs_9F   DD OFFSET error_sw
vs_A0   DD OFFSET error_sw
vs_A1   DD OFFSET error_sw
vs_A2   DD OFFSET error_sw
vs_A3   DD OFFSET error_sw
vs_A4   DD OFFSET error_sw
vs_A5   DD OFFSET error_sw
vs_A6   DD OFFSET error_sw
vs_A7   DD OFFSET error_sw
vs_A8   DD OFFSET error_sw
vs_A9   DD OFFSET error_sw
vs_AA   DD OFFSET error_sw
vs_AB   DD OFFSET error_sw
vs_AC   DD OFFSET error_sw
vs_AD   DD OFFSET error_sw
vs_AE   DD OFFSET error_sw
vs_AF   DD OFFSET error_sw
vs_B0   DD OFFSET error_sw
vs_B1   DD OFFSET error_sw
vs_B2   DD OFFSET error_sw
vs_B3   DD OFFSET error_sw
vs_B4   DD OFFSET error_sw
vs_B5   DD OFFSET error_sw
vs_B6   DD OFFSET error_sw
vs_B7   DD OFFSET error_sw
vs_B8   DD OFFSET error_sw
vs_B9   DD OFFSET error_sw
vs_BA   DD OFFSET error_sw
vs_BB   DD OFFSET error_sw
vs_BC   DD OFFSET error_sw
vs_BD   DD OFFSET error_sw
vs_BE   DD OFFSET error_sw
vs_BF   DD OFFSET error_sw
vs_C0   DD OFFSET error_sw
vs_C1   DD OFFSET error_sw
vs_C2   DD OFFSET error_sw
vs_C3   DD OFFSET error_sw
vs_C4   DD OFFSET error_sw
vs_C5   DD OFFSET error_sw
vs_C6   DD OFFSET error_sw
vs_C7   DD OFFSET error_sw
vs_C8   DD OFFSET error_sw
vs_C9   DD OFFSET error_sw
vs_CA   DD OFFSET error_sw
vs_CB   DD OFFSET error_sw
vs_CC   DD OFFSET error_sw
vs_CD   DD OFFSET error_sw
vs_CE   DD OFFSET error_sw
vs_CF   DD OFFSET error_sw
vs_D0   DD OFFSET error_sw
vs_D1   DD OFFSET error_sw
vs_D2   DD OFFSET error_sw
vs_D3   DD OFFSET error_sw
vs_D4   DD OFFSET error_sw
vs_D5   DD OFFSET error_sw
vs_D6   DD OFFSET error_sw
vs_D7   DD OFFSET error_sw
vs_D8   DD OFFSET error_sw
vs_D9   DD OFFSET error_sw
vs_DA   DD OFFSET error_sw
vs_DB   DD OFFSET error_sw
vs_DC   DD OFFSET error_sw
vs_DD   DD OFFSET error_sw
vs_DE   DD OFFSET error_sw
vs_DF   DD OFFSET error_sw
vs_E0   DD OFFSET error_sw
vs_E1   DD OFFSET error_sw
vs_E2   DD OFFSET error_sw
vs_E3   DD OFFSET error_sw
vs_E4   DD OFFSET error_sw
vs_E5   DD OFFSET error_sw
vs_E6   DD OFFSET error_sw
vs_E7   DD OFFSET error_sw
vs_E8   DD OFFSET error_sw
vs_E9   DD OFFSET error_sw
vs_EA   DD OFFSET error_sw
vs_EB   DD OFFSET error_sw
vs_EC   DD OFFSET error_sw
vs_ED   DD OFFSET error_sw
vs_EE   DD OFFSET error_sw
vs_EF   DD OFFSET error_sw
vs_F0   DD OFFSET error_sw
vs_F1   DD OFFSET error_sw
vs_F2   DD OFFSET error_sw
vs_F3   DD OFFSET error_sw
vs_F4   DD OFFSET error_sw
vs_F5   DD OFFSET error_sw
vs_F6   DD OFFSET error_sw
vs_F7   DD OFFSET error_sw
vs_F8   DD OFFSET error_sw
vs_F9   DD OFFSET error_sw
vs_FA   DD OFFSET error_sw
vs_FB   DD OFFSET error_sw
vs_FC   DD OFFSET error_sw
vs_FD   DD OFFSET error_sw
vs_FE   DD OFFSET error_sw
vs_FF   DD OFFSET error_sw

DebugFunc       Proc near
    push gs
    push edi
;    
    mov al,es:db_op
    cmp al,'n'
    je debug_next
;
    cmp al,'N'
    je debug_next 
;
    push ax
    GetDebugThreadSel
    mov bx,ax
    pop ax

debug_do:
    or bx,bx
    jz debug_err
;
    mov gs,bx

debug_next:
    movzx ax,al
    mov dl,es:db_x
    mov dh,es:db_y
    call set_os_pos
;
    movzx ebx,al
    shl ebx,2
    call dword ptr cs:[ebx].virt_sw_func_tab
    jmp debug_end

debug_err:
    call DefaultReply

debug_end:
    pop edi
    pop gs
    ret
DebugFunc       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugThread
;
;           DESCRIPTION:    IPC Debug thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_thread_name       DB 'IPC Debug',0
mailslot_name           DB 'Debug',0

debug_thread_pr:
    mov ax,SEG data
    mov ds,ax
    mov ebp,OFFSET cpu
;        
    mov ax,cs
    mov es,ax
    mov edi,OFFSET mailslot_name
    mov ecx,1000h
    DefineMailslot
;
    mov eax,ecx
    AllocateGlobalMem

debug_thread_loop:
    xor edi,edi
    ReceiveMailslot
    call DebugFunc
    jmp debug_thread_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_ipc_debug
;
;           DESCRIPTION:    Create IPC debugger thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_ipc_debug

init_ipc_debug      PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET debug_thread_pr
    mov di,OFFSET debug_thread_name
    mov cx,stack0_size
    mov ax,26
    CreateThread
    ret
init_ipc_debug      ENDP
    
code    ENDS

    END
