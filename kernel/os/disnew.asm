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
; DISNEW.ASM
; Disassembler tables for kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        assume cs:code

code    SEGMENT byte public 'CODE'

        public mod_rm_tab

mod_rm_tab:
mem8d_16a       DW OFFSET mem8d_16a_tab
mem16d_16a      DW OFFSET mem16d_16a_tab
mem32d_16a      DW OFFSET mem32d_16a_tab
mem8d_32a       DW OFFSET mem8d_32a_tab
mem16d_32a      DW OFFSET mem16d_32a_tab
mem32d_32a      DW OFFSET mem32d_32a_tab

        public reg_tab

reg_tab:
reg8d   DW OFFSET mod8d_16a_rm11000
reg16d  DW OFFSET mod16d_16a_rm11000
reg32d  DW OFFSET mod32d_16a_rm11000


        public mem_sib0_tab

        public sib_scale_tab
        public sib_index_tab

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

        public sep_tab

sep_tab:
        DB ' ',0
        DB ',',0
        DB ':',0
        DB '(',0
        DB ')',0
        DB '[',0
        DB ']',0
        DB '+',0
        DB '-',0
        DB ':['
        DB '],'
        DB 0,0

        public mne_tab

        public cr_txt
        public dr_txt
        public tr_txt
        public word_ptr_txt
        public dword_ptr_txt
        public txt_noth
        public st_txt

        public txt_16
        public txt_32
        public b_txt
        public w_txt
        public d_txt

        public ax_txt
        public eax_txt
        public bx_txt
        public ebx_txt
        public cx_txt
        public ecx_txt
        public dx_txt
        public edx_txt
        public sp_txt
        public esp_txt
        public bp_txt
        public ebp_txt
        public si_txt
        public esi_txt
        public di_txt
        public edi_txt

        public cs_txt
        public ds_txt
        public ss_txt
        public es_txt
        public fs_txt
        public gs_txt

mne_tab:

txt_0                           DB '0',0
txt_1                           DB '1',0
txt_2                           DB '2',0
txt_3                           DB '3',0
txt_4                           DB '4',0
txt_5                           DB '5',0
txt_6                           DB '6',0
txt_7                           DB '7',0
txt_8                           DB '8',0
txt_9                           DB '9',0
txt_A                           DB 'A',0
txt_B                           DB 'B',0
txt_C                           DB 'C',0
txt_D                           DB 'D',0
txt_E                           DB 'E',0
txt_F                           DB 'F',0
txt_noth                        DB 0
star1                           DB '*1',0
star2                           DB '*2',0
star4                           DB '*4',0
star8                           DB '*8',0
txt_16                          DB '16',0
txt_32                          DB '32',0
aaa_txt                         DB 'aaa',0
aad_txt                         DB 'aad',0
aam_txt                         DB 'aam',0
aas_txt                         DB 'aas',0
adc_txt                         DB 'adc',0
add_txt                         DB 'add',0
ah_txt                          DB 'ah',0
al_txt                          DB 'al',0
and_txt                         DB 'and',0
arpl_txt                        DB 'arpl',0
ax_txt                          DB 'ax',0
b_txt                           DB 'b',0
bh_txt                          DB 'bh',0
bl_txt                          DB 'bl',0
bound_txt                       DB 'bound',0
bp_txt                          DB 'bp',0
bsf_txt                         DB 'bsf',0
bsr_txt                         DB 'bsr',0
bt_txt                          DB 'bt',0
btc_txt                         DB 'btc',0
btr_txt                         DB 'btr',0
bts_txt                         DB 'bts',0
bx_txt                          DB 'bx',0
byte_txt                        DB 'byte',0
byte_ptr_txt            DB 'byte ptr',0
call_txt                        DB 'call',0
cbw_txt                         DB 'cbw',0
ch_txt                          DB 'ch',0
cl_txt                          DB 'cl',0
clc_txt                         DB 'clc',0
cld_txt                         DB 'cld',0
cli_txt                         DB 'cli',0
clts_txt                        DB 'clts',0
cmc_txt                         DB 'cmc',0
cmp_txt                         DB 'cmp',0
cmps_txt                        DB 'cmps',0
cpuid_txt                       DB 'cpuid',0
cr_txt                          DB 'cr',0
cs_txt                          DB 'cs',0
cwd_txt                         DB 'cwd',0
cx_txt                          DB 'cx',0
d_txt                           DB 'd',0
daa_txt                         DB 'daa',0
das_txt                         DB 'das',0
dec_txt                         DB 'dec',0
dh_txt                          DB 'dh',0
di_txt                          DB 'di',0
div_txt                         DB 'div',0
dl_txt                          DB 'dl',0
dr_txt                          DB 'dr',0
ds_txt                          DB 'ds',0
dword_txt                       DB 'dword',0
dword_ptr_txt           DB 'dword ptr',0
dx_txt                          DB 'dx',0
eax_txt                         DB 'eax',0
ebp_txt                         DB 'ebp',0
ebx_txt                         DB 'ebx',0
ecx_txt                         DB 'ecx',0
edi_txt                         DB 'edi',0
edx_txt                         DB 'edx',0
enter_txt                       DB 'enter',0
es_txt                          DB 'es',0
esi_txt                         DB 'esi',0
esp_txt                         DB 'esp',0
f2xm1_txt                       DB 'f2xm1',0
fabs_txt                        DB 'fabs',0
fadd_txt                        DB 'fadd',0
far_txt                         DB 'far',0
fbld_txt                        DB 'fbld',0
fbstp_txt                       DB 'fbstp',0
fchs_txt                        DB 'fchs',0
fclex_txt                       DB 'fclex',0
fcom_txt                        DB 'fcom',0
fcomp_txt                       DB 'fcomp',0
fcompp_txt                      DB 'fcompp',0
fcos_txt                        DB 'fcos',0
fdecstp_txt                     DB 'fdecstp',0
fdisi_txt                       DB 'fdisi',0
fdiv_txt                        DB 'fdiv',0
fdivr_txt                       DB 'fdivr',0
feni_txt                        DB 'feni',0
ffree_txt                       DB 'ffree',0
fiadd_txt                       DB 'fiadd',0
ficom_txt                       DB 'ficom',0
ficomp_txt                      DB 'ficomp',0
fidiv_txt                       DB 'fidiv',0
fidivr_txt                      DB 'fidivr',0
fild_txt                        DB 'fild',0
fimul_txt                       DB 'fimul',0
fincstp_txt                     DB 'fincstp',0
finit_txt                       DB 'finit',0
fist_txt                        DB 'fist',0
fistp_txt                       DB 'fistp',0
fisub_txt                       DB 'fisub',0
fisubr_txt                      DB 'fisubr',0
fld_txt                         DB 'fld',0
fld1_txt                        DB 'fld1',0
fldcw_txt                       DB 'fldcw',0
fldenv_txt                      DB 'fldenv',0
fldl2e_txt                      DB 'fldl2e',0
fldl2t_txt                      DB 'fldl2t',0
fldlg2_txt                      DB 'fldlg2',0
fldln2_txt                      DB 'fldln2',0
fldpi_txt                       DB 'fldpi',0
fldz_txt                        DB 'fldz',0
fmul_txt                        DB 'fmul',0
fpatan_txt                      DB 'fpatan',0
fprem_txt                       DB 'fprem',0
fprem1_txt                      DB 'fprem1',0
fptan_txt                       DB 'fptan',0
frndint_txt                     DB 'frndint',0
frstor_txt                      DB 'frstor',0
fs_txt                          DB 'fs',0
fsave_txt                       DB 'fsave',0
fscale_txt                      DB 'fscale',0
fsin_txt                        DB 'fsin',0
fsincos_txt                     DB 'fsincos',0
fsqrt_txt                       DB 'fsqrt',0
fst_txt                         DB 'fst',0
fstcw_txt                       DB 'fstcw',0
fstenv_txt                      DB 'fstenv',0
fstp_txt                        DB 'fstp',0
fstsw_txt                       DB 'fstsw',0
fsub_txt                        DB 'fsub',0
fsubr_txt                       DB 'fsubr',0
ftst_txt                        DB 'ftst',0
fucom_txt                       DB 'fucom',0
fucomp_txt                      DB 'fucomp',0
fucompp_txt                     DB 'fucompp',0
fxam_txt                        DB 'fxam',0
fxch_txt                        DB 'fxch',0
fxtract_txt                     DB 'fxtract',0
fyl2x_txt                       DB 'fyl2x',0
fyl2xp1_txt                     DB 'fyl2xp1',0
gs_txt                          DB 'gs',0
hlt_txt                         DB 'hlt',0
idiv_txt                        DB 'idiv',0
imul_txt                        DB 'imul',0
in_txt                          DB 'in',0
inc_txt                         DB 'inc',0
ins_txt                         DB 'ins',0
int_txt                         DB 'int',0
into_txt                        DB 'into',0
iret_txt                        DB 'iret',0
ja_txt                          DB 'ja',0
jb_txt                          DB 'jb',0
jbe_txt                         DB 'jbe',0
jcxz_txt                        DB 'jcxz',0
jg_txt                          DB 'jg',0
jge_txt                         DB 'jge',0
jl_txt                          DB 'jl',0
jle_txt                         DB 'jle',0
jmp_txt                         DB 'jmp',0
jnb_txt                         DB 'jnb',0
jno_txt                         DB 'jno',0
jns_txt                         DB 'jns',0
jnz_txt                         DB 'jnz',0
jo_txt                          DB 'jo',0
jpe_txt                         DB 'jpe',0
jpo_txt                         DB 'jpo',0
js_txt                          DB 'js',0
jz_txt                          DB 'jz',0
lahf_txt                        DB 'lahf',0
lar_txt                         DB 'lar',0
lds_txt                         DB 'lds',0
lea_txt                         DB 'lea',0
leave_txt                       DB 'leave',0
les_txt                         DB 'les',0
lfs_txt                         DB 'lfs',0
lgdt_txt                        DB 'lgdt',0
lgs_txt                         DB 'lgs',0
lidt_txt                        DB 'lidt',0
lldt_txt                        DB 'lldt',0
lmsw_txt                        DB 'lmsw',0
lock_txt                        DB 'lock',0
lods_txt                        DB 'lods',0
loop_txt                        DB 'loop',0
loopnz_txt                      DB 'loopnz',0
loopz_txt                       DB 'loopz',0
lsl_txt                         DB 'lsl',0
lss_txt                         DB 'lss',0
ltr_txt                         DB 'ltr',0
mov_txt                         DB 'mov',0
move_txt                        DB 'move',0
movs_txt                        DB 'movs',0
movsx_txt                       DB 'movsx',0
movzx_txt                       DB 'movzx',0
mul_txt                         DB 'mul',0
near_txt                        DB 'near',0
neg_txt                         DB 'neg',0
nop_txt                         DB 'nop',0
not_txt                         DB 'not',0
or_txt                          DB 'or',0
out_txt                         DB 'out',0
outs_txt                        DB 'outs',0
pop_txt                         DB 'pop',0
popa_txt                        DB 'popa',0
popf_txt                        DB 'popf',0
ptr_txt                         DB 'ptr',0
push_txt                        DB 'push',0
pusha_txt                       DB 'pusha',0
pushf_txt                       DB 'pushf',0
qword_txt                       DB 'qword',0
qword_ptr_txt           DB 'qword ptr',0
rcl_txt                         DB 'rcl',0
rcr_txt                         DB 'rcr',0
rdmsr_txt                       DB 'rdmsr',0
rdtsc_txt                       DB 'rdtsc',0
repnz_txt                       DB 'repnz',0
repz_txt                        DB 'repz',0
retf_txt                        DB 'retf',0
retn_txt                        DB 'retn',0
rol_txt                         DB 'rol',0
ror_txt                         DB 'ror',0
sahf_txt                        DB 'sahf',0
sar_txt                         DB 'sar',0
sbb_txt                         DB 'sbb',0
scas_txt                        DB 'scas',0
seta_txt                        DB 'seta',0
setb_txt                        DB 'setb',0
setbe_txt                       DB 'setbe',0
setg_txt                        DB 'setg',0
setge_txt                       DB 'setge',0
setl_txt                        DB 'setl',0
setle_txt                       DB 'setle',0
setnb_txt                       DB 'setnb',0
setno_txt                       DB 'setno',0
setns_txt                       DB 'setns',0
setnz_txt                       DB 'setnz',0
seto_txt                        DB 'seto',0
setpe_txt                       DB 'setpe',0
setpo_txt                       DB 'setpo',0
sets_txt                        DB 'sets',0
setz_txt                        DB 'setz',0
sgdt_txt                        DB 'sgdt',0
shl_txt                         DB 'shl',0
shld_txt                        DB 'shld',0
shr_txt                         DB 'shr',0
shrd_txt                        DB 'shrd',0
si_txt                          DB 'si',0
sidt_txt                        DB 'sidt',0
sldt_txt                        DB 'sldt',0
smsw_txt                        DB 'smsw',0
sp_txt                          DB 'sp',0
ss_txt                          DB 'ss',0
st_txt                          DB 'st',0
stc_txt                         DB 'stc',0
std_txt                         DB 'std',0
sti_txt                         DB 'sti',0
stos_txt                        DB 'stos',0
str_txt                         DB 'str',0
sub_txt                         DB 'sub',0
tbyte_txt                       DB 'tbyte',0
tbyte_ptr_txt           DB 'tbyte ptr',0
test_txt                        DB 'test',0
tr_txt                          DB 'tr',0
verr_txt                        DB 'verr',0
verw_txt                        DB 'verw',0
w_txt                           DB 'w',0
wait_txt                        DB 'wait',0
word_txt                        DB 'word',0
word_ptr_txt            DB 'word ptr',0
wrmsr_txt                       DB 'wrmsr',0
xchg_txt                        DB 'xchg',0
xlat_txt                        DB 'xlat',0
xor_txt                         DB 'xor',0
xyz_txt                         DB 'xyz',0

ax_tab                          EQU 0FE8h
cx_tab                          EQU 0FE9h
dx_tab                          EQU 0FEAh
bx_tab                          EQU 0FEBh
sp_tab                          EQU 0FECh
bp_tab                          EQU 0FEDh
si_tab                          EQU 0FEEh
di_tab                          EQU 0FEFh
null_tab                        EQU 0FF0h
op_math_one_tab         EQU 0FF1h
op_math2_tab            EQU 0FF2h
op_math_reg_tab         EQU 0FF3h
op_mem_reg_tab          EQU 0FF4h
op_protect_tab          EQU 0FF5h
op_prot2_tab            EQU 0FF6h
op_cdt_tab                      EQU 0FF7h

;
        extrn op_illegal:near
        extrn op_math:near
        extrn op_math_reg:near
        extrn opmr_mem8:near
        extrn opmr_mem16:near
        extrn opmr_mem_im8:near
        extrn opmr_mem_im16:near
        extrn opmr_mem_extend_im16:near
        extrn op_data_size:near
        extrn op_address_size:near
        extrn op_wait:near
        extrn op_one:near
        extrn op_byte:near
        extrn op_word:near
        extrn op_word16:near
        extrn op_word_mem:near
        extrn op_short:near
        extrn op_near:near
        extrn op_far:near
        extrn op_reg_mem_byte:near
        extrn op_reg_mem_word:near
        extrn op_mem_reg_byte:near
        extrn op_mem_reg_word:near
        extrn op_enter:near
        extrn op_reg_mem2_byte:near
        extrn op_reg_mem2_word:near
        extrn op_near2:near
        extrn opmr_mem2:near
        extrn op_mem_reg2:near
        extrn op_reg_mem_byte2:near
        extrn op_reg_cr:near
        extrn op_cr_reg:near
        extrn op_reg_dr:near
        extrn op_dr_reg:near
        extrn op_reg_tr:near
        extrn op_tr_reg:near
        extrn opmr_mem3:near
        extrn op_mem_byte3:near
        extrn mem_im8:near
        extrn mem_im16:near
        extrn mem_im32:near
        extrn mem_sib:near

        extrn override_cs:near
        extrn override_ds:near
        extrn override_ss:near
        extrn override_es:near
        extrn override_fs:near
        extrn override_gs:near
        extrn op_rep:near

        extrn op_string1b:near
        extrn op_string1w:near
        extrn op_string2b:near
        extrn op_string2w:near

        extrn op_add_opsize:near

;;;;;;;;;;;;;;;;;
; OP_MATH_ONE_TAB
; MASKAD TILL 0007
;;;;;;;;;;;;;;;;;
;
opmsD9C8:
                        DW OFFSET op_math
                        DW OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_0 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsD9C9:
                        DW OFFSET op_math
                        DW OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsD9CA:
                        DW OFFSET op_math
                        DW OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_2 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsD9CB:
                        DW OFFSET op_math
                        DW OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_3 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsD9CC:
                        DW OFFSET op_math
                        DW OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_4 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsD9CD:
                        DW OFFSET op_math
                        DW OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_5 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsD9CE:
                        DW OFFSET op_math
                        DW OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_6 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsD9CF:
                        DW OFFSET op_math
                        DW OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_7 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh


opmsD9E0:
                        DW OFFSET op_math
                        DW OFFSET fchs_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9E1:
                        DW OFFSET op_math
                        DW OFFSET fabs_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9E2:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9E3:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9E4:
                        DW OFFSET op_math
                        DW OFFSET ftst_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9E5:
                        DW OFFSET op_math
                        DW OFFSET fxam_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9E6:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9E7:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


opmsD9E8:
                        DW OFFSET op_math
                        DW OFFSET fld1_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9E9:
                        DW OFFSET op_math
                        DW OFFSET fldl2t_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9EA:
                        DW OFFSET op_math
                        DW OFFSET fldl2e_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9EB:
                        DW OFFSET op_math
                        DW OFFSET fldpi_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9EC:
                        DW OFFSET op_math
                        DW OFFSET fldlg2_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9ED:
                        DW OFFSET op_math
                        DW OFFSET fldln2_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9EE:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9EF:
                        DW OFFSET op_math
                        DW OFFSET fldz_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


opmsD9F0:
                        DW OFFSET op_math
                        DW OFFSET f2xm1_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9F1:
                        DW OFFSET op_math
                        DW OFFSET fyl2x_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9F2:
                        DW OFFSET op_math
                        DW OFFSET fptan_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9F3:
                        DW OFFSET op_math
                        DW OFFSET fpatan_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9F4:
                        DW OFFSET op_math
                        DW OFFSET fxtract_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9F5:
                        DW OFFSET op_math
                        DW OFFSET fprem1_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9F6:
                        DW OFFSET op_math
                        DW OFFSET fdecstp_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9F7:
                        DW OFFSET op_math
                        DW OFFSET fincstp_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


opmsD9F8:
                        DW OFFSET op_math
                        DW OFFSET fprem_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9F9:
                        DW OFFSET op_math
                        DW OFFSET fyl2xp1_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9FA:
                        DW OFFSET op_math
                        DW OFFSET fsqrt_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9FB:
                        DW OFFSET op_math
                        DW OFFSET fsincos_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9FC:
                        DW OFFSET op_math
                        DW OFFSET frndint_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9FD:
                        DW OFFSET op_math
                        DW OFFSET fscale_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9FE:
                        DW OFFSET op_math
                        DW OFFSET fsin_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsD9FF:
                        DW OFFSET op_math
                        DW OFFSET fcos_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


opmsDBE0:
                        DW OFFSET op_math
                        DW OFFSET feni_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDBE1:
                        DW OFFSET op_math
                        DW OFFSET fdisi_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDBE2:
                        DW OFFSET op_math
                        DW OFFSET fclex_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDBE3:
                        DW OFFSET op_math
                        DW OFFSET finit_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDBE4:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDBE5:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDBE6:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDBE7:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


opmsDAE8:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDAE9:
                        DW OFFSET op_math
                        DW OFFSET fucompp_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDAEA:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDAEB:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDAEC:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDAED:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDAEE:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDAEF:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


opmsDDC0:
                        DW OFFSET op_math
                        DW OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_0 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDC1:
                        DW OFFSET op_math
                        DW OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDC2:
                        DW OFFSET op_math
                        DW OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_2 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDC3:
                        DW OFFSET op_math
                        DW OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_3 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDC4:
                        DW OFFSET op_math
                        DW OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_4 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDC5:
                        DW OFFSET op_math
                        DW OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_5 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDC6:
                        DW OFFSET op_math
                        DW OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_6 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDC7:
                        DW OFFSET op_math
                        DW OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_7 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh


opmsDDE0:
                        DW OFFSET op_math
                        DW OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_0 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDE1:
                        DW OFFSET op_math
                        DW OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDE2:
                        DW OFFSET op_math
                        DW OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_2 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDE3:
                        DW OFFSET op_math
                        DW OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_3 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDE4:
                        DW OFFSET op_math
                        DW OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_4 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDE5:
                        DW OFFSET op_math
                        DW OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_5 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDE6:
                        DW OFFSET op_math
                        DW OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_6 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDE7:
                        DW OFFSET op_math
                        DW OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_7 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh


opmsDDE8:
                        DW OFFSET op_math
                        DW OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_0 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDE9:
                        DW OFFSET op_math
                        DW OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDEA:
                        DW OFFSET op_math
                        DW OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_2 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDEB:
                        DW OFFSET op_math
                        DW OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_3 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDEC:
                        DW OFFSET op_math
                        DW OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_4 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDED:
                        DW OFFSET op_math
                        DW OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_5 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDEE:
                        DW OFFSET op_math
                        DW OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_6 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

opmsDDEF:
                        DW OFFSET op_math
                        DW OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DW OFFSET txt_7 - OFFSET mne_tab + rpar_sep
                        DW 0FFFFh

;
opmsDED8:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDED9:
                        DW OFFSET op_math
                        DW OFFSET fcompp_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDEDA:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDEDB:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDEDC:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDEDD:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDEDE:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDEDF:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmsDFE0:
                        DW OFFSET op_math
                        DW OFFSET fstsw_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmsDFE1:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDFE2:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDFE3:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDFE4:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDFE5:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDFE6:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmsDFE7:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


;;;;;;;;;;;;;;;;;;;
; OP_MATH2_TAB
; MASKAD TILL 00FE
;;;;;;;;;;;;;;;;;;;

opmaD800:
                        DW OFFSET op_math
                        DW OFFSET fadd_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD840:
                        DW OFFSET op_math
                        DW OFFSET fadd_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD880:
                        DW OFFSET op_math
                        DW OFFSET fadd_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD8C0:
                        DW OFFSET op_math_reg
                        DW OFFSET fadd_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaD808:
                        DW OFFSET op_math
                        DW OFFSET fmul_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD848:
                        DW OFFSET op_math
                        DW OFFSET fmul_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD888:
                        DW OFFSET op_math
                        DW OFFSET fmul_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD8C8:
                        DW OFFSET op_math_reg
                        DW OFFSET fmul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaD810:
                        DW OFFSET op_math
                        DW OFFSET fcom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD850:
                        DW OFFSET op_math
                        DW OFFSET fcom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD890:
                        DW OFFSET op_math
                        DW OFFSET fcom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD8D0:
                        DW OFFSET op_math_reg
                        DW OFFSET fcom_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaD820:
                        DW OFFSET op_math
                        DW OFFSET fsub_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD860:
                        DW OFFSET op_math
                        DW OFFSET fsub_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD8A0:
                        DW OFFSET op_math
                        DW OFFSET fsub_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD8E0:
                        DW OFFSET op_math_reg
                        DW OFFSET fsub_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaD830:
                        DW OFFSET op_math
                        DW OFFSET fdiv_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD870:
                        DW OFFSET op_math
                        DW OFFSET fdiv_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD8B0:
                        DW OFFSET op_math
                        DW OFFSET fdiv_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD8F0:
                        DW OFFSET op_math_reg
                        DW OFFSET fdiv_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaD900:
                        DW OFFSET op_math
                        DW OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD940:
                        DW OFFSET op_math
                        DW OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD980:
                        DW OFFSET op_math
                        DW OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD9C0:
                        DW OFFSET op_math_reg
                        DW OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaD908:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmaD948:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmaD988:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmaD9C8:
                        DW OFFSET opmsD9C8
                        DW op_math_one_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaD910:
                        DW OFFSET op_math
                        DW OFFSET fst_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD950:
                        DW OFFSET op_math
                        DW OFFSET fst_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD990:
                        DW OFFSET op_math
                        DW OFFSET fst_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD9D0:
                        DW OFFSET op_math_reg
                        DW OFFSET fst_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaD918:
                        DW OFFSET op_math
                        DW OFFSET fstp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD958:
                        DW OFFSET op_math
                        DW OFFSET fstp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD998:
                        DW OFFSET op_math
                        DW OFFSET fstp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaD9D8:
                        DW OFFSET op_math_reg
                        DW OFFSET fstp_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaD920:
                        DW OFFSET op_math
                        DW OFFSET fldenv_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaD960:
                        DW OFFSET op_math
                        DW OFFSET fldenv_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaD9A0:
                        DW OFFSET op_math
                        DW OFFSET fldenv_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaD9E0:
                        DW OFFSET opmsD9E0
                        DW op_math_one_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaD928:
                        DW OFFSET op_math
                        DW OFFSET fldcw_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaD968:
                        DW OFFSET op_math
                        DW OFFSET fldcw_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaD9A8:
                        DW OFFSET op_math
                        DW OFFSET fldcw_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaD9E8:
                        DW OFFSET opmsD9E8
                        DW op_math_one_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaD930:
                        DW OFFSET op_math
                        DW OFFSET fstenv_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaD970:
                        DW OFFSET op_math
                        DW OFFSET fstenv_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaD9B0:
                        DW OFFSET op_math
                        DW OFFSET fstenv_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaD9F0:
                        DW OFFSET opmsD9F0
                        DW op_math_one_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaD938:
                        DW OFFSET op_math
                        DW OFFSET fstcw_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaD978:
                        DW OFFSET op_math
                        DW OFFSET fstcw_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaD9B8:
                        DW OFFSET op_math
                        DW OFFSET fstcw_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaD9F8:
                        DW OFFSET opmsD9F8
                        DW op_math_one_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaDB20:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmaDB60:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmaDBA0:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmaDBE0:
                        DW OFFSET opmsDBE0
                        DW op_math_one_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaDA28:
                        DW OFFSET opmr_mem16
                        DW OFFSET fisubr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaDA68:
                        DW OFFSET opmr_mem16
                        DW OFFSET fisubr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaDAA8:
                        DW OFFSET opmr_mem16
                        DW OFFSET fisubr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaDAE8:
                        DW OFFSET opmsDAE8
                        DW op_math_one_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaDD00:
                        DW OFFSET opmr_mem16
                        DW OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaDD40:
                        DW OFFSET opmr_mem16
                        DW OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaDD80:
                        DW OFFSET opmr_mem16
                        DW OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaDDC0:
                        DW OFFSET opmsDDC0
                        DW op_math_one_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaDD20:
                        DW OFFSET opmr_mem16
                        DW OFFSET frstor_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaDD60:
                        DW OFFSET opmr_mem16
                        DW OFFSET frstor_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaDDA0:
                        DW OFFSET opmr_mem16
                        DW OFFSET frstor_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmaDDE0:
                        DW OFFSET opmsDDE0
                        DW op_math_one_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaDD28:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmaDD68:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmaDDA8:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmaDDE8:
                        DW OFFSET opmsDDE8
                        DW op_math_one_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaDE18:
                        DW OFFSET opmr_mem16
                        DW OFFSET ficomp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaDE58:
                        DW OFFSET opmr_mem16
                        DW OFFSET ficomp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaDE98:
                        DW OFFSET opmr_mem16
                        DW OFFSET ficomp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaDED8:
                        DW OFFSET opmsDED8
                        DW op_math_one_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmaDF20:
                        DW OFFSET opmr_mem16
                        DW OFFSET fbld_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaDF60:
                        DW OFFSET opmr_mem16
                        DW OFFSET fbld_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaDFA0:
                        DW OFFSET opmr_mem16
                        DW OFFSET fbld_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmaDFE0:
                        DW OFFSET opmsDFE0
                        DW OFFSET fbld_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW op_math_one_tab + blank_sep
                        DW 0FFFFh


;;;;;;;;;;;;;;;;;;;;
; OP_MATH_REG_TAB
; MASKAD TILL 0038
;;;;;;;;;;;;;;;;;;;;

opmrD800:
                        DW OFFSET opmaD800
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD808:
                        DW OFFSET opmaD808
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD810:
                        DW OFFSET opmaD810
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD818:
                        DW OFFSET opmr_mem16
                        DW OFFSET fcomp_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmrD820:
                        DW OFFSET opmaD820
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD828:
                        DW OFFSET opmr_mem16
                        DW OFFSET fsubr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrD830:
                        DW OFFSET opmaD830
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD838:
                        DW OFFSET opmr_mem16
                        DW OFFSET fdivr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

;
opmrD900:
                        DW OFFSET opmaD900
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD908:
                        DW OFFSET opmaD908
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD910:
                        DW OFFSET opmaD910
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD918:
                        DW OFFSET opmaD918
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD920:
                        DW OFFSET opmaD920
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD928:
                        DW OFFSET opmaD928
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD930:
                        DW OFFSET opmaD930
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD938:
                        DW OFFSET opmaD938
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmrDA00:
                        DW OFFSET opmr_mem16
                        DW OFFSET fiadd_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDA08:
                        DW OFFSET opmr_mem16
                        DW OFFSET fimul_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDA10:
                        DW OFFSET opmr_mem16
                        DW OFFSET ficom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDA18:
                        DW OFFSET opmr_mem16
                        DW OFFSET ficomp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDA20:
                        DW OFFSET opmr_mem16
                        DW OFFSET fisub_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDA28:
                        DW OFFSET opmaDA28
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrDA30:
                        DW OFFSET opmr_mem16
                        DW OFFSET fidiv_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDA38:
                        DW OFFSET opmr_mem16
                        DW OFFSET fidivr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

;
opmrDB00:
                        DW OFFSET opmr_mem16
                        DW OFFSET fild_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDB08:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrDB10:
                        DW OFFSET opmr_mem16
                        DW OFFSET fist_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDB18:
                        DW OFFSET opmr_mem16
                        DW OFFSET fistp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDB20:
                        DW OFFSET opmaDB20
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrDB28:
                        DW OFFSET opmr_mem16
                        DW OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDB30:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrDB38:
                        DW OFFSET opmr_mem16
                        DW OFFSET fstp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

;
opmrDC00:
                        DW OFFSET opmr_mem16
                        DW OFFSET fadd_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDC08:
                        DW OFFSET opmr_mem16
                        DW OFFSET fmul_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDC10:
                        DW OFFSET opmr_mem16
                        DW OFFSET fcom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDC18:
                        DW OFFSET opmr_mem16
                        DW OFFSET fcomp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDC20:
                        DW OFFSET opmr_mem16
                        DW OFFSET fsub_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDC28:
                        DW OFFSET opmr_mem16
                        DW OFFSET fsubr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDC30:
                        DW OFFSET opmr_mem16
                        DW OFFSET fdiv_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDC38:
                        DW OFFSET opmr_mem16
                        DW OFFSET fdivr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

;
opmrDD00:
                        DW OFFSET opmr_mem16
                        DW OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDD08:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrDD10:
                        DW OFFSET opmr_mem16
                        DW OFFSET fst_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDD18:
                        DW OFFSET opmr_mem16
                        DW OFFSET fstp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDD20:
                        DW OFFSET opmaDD20
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrDD28:
                        DW OFFSET opmaDD28
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrDD30:
                        DW OFFSET opmr_mem16
                        DW OFFSET fsave_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmrDD38:
                        DW OFFSET opmr_mem16
                        DW OFFSET fstsw_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

;
opmrDE00:
                        DW OFFSET opmr_mem16
                        DW OFFSET fiadd_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDE08:
                        DW OFFSET opmr_mem16
                        DW OFFSET fimul_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDE10:
                        DW OFFSET opmr_mem16
                        DW OFFSET ficom_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDE18:
                        DW OFFSET opmaDE18
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrDE20:
                        DW OFFSET opmr_mem16
                        DW OFFSET fisub_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDE28:
                        DW OFFSET opmr_mem16
                        DW OFFSET fisubr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDE30:
                        DW OFFSET opmr_mem16
                        DW OFFSET fidiv_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDE38:
                        DW OFFSET opmr_mem16
                        DW OFFSET fidivr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

;
opmrDF00:
                        DW OFFSET opmr_mem16
                        DW OFFSET fild_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDF08:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrDF10:
                        DW OFFSET opmr_mem16
                        DW OFFSET fist_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDF18:
                        DW OFFSET opmr_mem16
                        DW OFFSET fistp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDF20:
                        DW OFFSET opmaDF20
                        DW op_math2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrDF28:
                        DW OFFSET opmr_mem16
                        DW OFFSET fild_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDF30:
                        DW OFFSET opmr_mem16
                        DW OFFSET fbstp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrDF38:
                        DW OFFSET opmr_mem16
                        DW OFFSET fistp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh



;;;;;;;;;;;;;;;;;;;;;
; OP_MEM_REG_TAB
; MASKAD TILL 0038
;;;;;;;;;;;;;;;;;;;;;

opmr6900:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6908:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6910:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6918:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6920:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6928:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6930:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6938:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

;
opmr6B00:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6B08:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6B10:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6B18:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6B20:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6B28:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6B30:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr6B38:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

;
opmr8000:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8008:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8010:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8018:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8020:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8028:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8030:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8038:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

;
opmr8100:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8108:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8110:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8118:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8120:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8128:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8130:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8138:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

;
opmr8200:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8208:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8210:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8218:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8220:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8228:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8230:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8238:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

;
opmr8300:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8308:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8310:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8318:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8320:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8328:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8330:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8338:
                        DW OFFSET opmr_mem_extend_im16
                        DW OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

;
opmr8C00:
                        DW OFFSET opmr_mem16
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET es_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh

opmr8C08:
                        DW OFFSET opmr_mem16
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cs_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh

opmr8C10:
                        DW OFFSET opmr_mem16
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET ss_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh

opmr8C18:
                        DW OFFSET opmr_mem16
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET ds_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh

opmr8C20:
                        DW OFFSET opmr_mem16
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET fs_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh

opmr8C28:
                        DW OFFSET opmr_mem16
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET gs_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh

opmr8C30:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmr8C38:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmr8E00:
                        DW OFFSET opmr_mem16
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET es_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8E08:
                        DW OFFSET opmr_mem16
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET cs_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8E10:
                        DW OFFSET opmr_mem16
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET ss_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8E18:
                        DW OFFSET opmr_mem16
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET ds_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8E20:
                        DW OFFSET opmr_mem16
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET fs_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8E28:
                        DW OFFSET opmr_mem16
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET gs_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmr8E30:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmr8E38:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmr8F00:
                        DW OFFSET opmr_mem16
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmr8F08:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmr8F10:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmr8F18:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmr8F20:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmr8F28:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmr8F30:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmr8F38:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmrC000:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET rol_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC008:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET ror_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC010:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET rcl_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC018:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET rcr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC020:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET shl_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC028:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET shr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC030:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC038:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET sar_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

;
opmrC100:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET rol_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC108:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET ror_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC110:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET rcl_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC118:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET rcr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC120:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET shl_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC128:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET shr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC130:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC138:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET sar_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

;
opmrC600:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET move_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC608:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC610:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC618:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC620:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC628:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC630:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC638:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmrC700:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET move_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrC708:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC710:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC718:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC720:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC728:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC730:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrC738:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmrD000:
                        DW OFFSET opmr_mem8
                        DW OFFSET rol_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD008:
                        DW OFFSET opmr_mem8
                        DW OFFSET ror_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD010:
                        DW OFFSET opmr_mem8
                        DW OFFSET rcl_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD018:
                        DW OFFSET opmr_mem8
                        DW OFFSET rcr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD020:
                        DW OFFSET opmr_mem8
                        DW OFFSET shl_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD028:
                        DW OFFSET opmr_mem8
                        DW OFFSET shr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD030:
                        DW OFFSET opmr_mem8
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD038:
                        DW OFFSET opmr_mem8
                        DW OFFSET sar_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

;
opmrD100:
                        DW OFFSET opmr_mem16
                        DW OFFSET rol_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD108:
                        DW OFFSET opmr_mem16
                        DW OFFSET ror_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD110:
                        DW OFFSET opmr_mem16
                        DW OFFSET rcl_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD118:
                        DW OFFSET opmr_mem16
                        DW OFFSET rcr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD120:
                        DW OFFSET opmr_mem16
                        DW OFFSET shl_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD128:
                        DW OFFSET opmr_mem16
                        DW OFFSET shr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD130:
                        DW OFFSET opmr_mem16
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD138:
                        DW OFFSET opmr_mem16
                        DW OFFSET sar_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET txt_1 - OFFSET mne_tab + blank_sep

;
opmrD200:
                        DW OFFSET opmr_mem8
                        DW OFFSET rol_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD208:
                        DW OFFSET opmr_mem8
                        DW OFFSET ror_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD210:
                        DW OFFSET opmr_mem8
                        DW OFFSET rcl_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD218:
                        DW OFFSET opmr_mem8
                        DW OFFSET rcr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD220:
                        DW OFFSET opmr_mem8
                        DW OFFSET shl_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD228:
                        DW OFFSET opmr_mem8
                        DW OFFSET shr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD230:
                        DW OFFSET opmr_mem8
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD238:
                        DW OFFSET opmr_mem8
                        DW OFFSET sar_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

;
opmrD300:
                        DW OFFSET opmr_mem16
                        DW OFFSET rol_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD308:
                        DW OFFSET opmr_mem16
                        DW OFFSET ror_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD310:
                        DW OFFSET opmr_mem16
                        DW OFFSET rcl_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD318:
                        DW OFFSET opmr_mem16
                        DW OFFSET rcr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD320:
                        DW OFFSET opmr_mem16
                        DW OFFSET shl_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD328:
                        DW OFFSET opmr_mem16
                        DW OFFSET shr_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD330:
                        DW OFFSET opmr_mem16
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrD338:
                        DW OFFSET opmr_mem16
                        DW OFFSET sar_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep

;
opmrF600:
                        DW OFFSET opmr_mem_im8
                        DW OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrF608:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrF610:
                        DW OFFSET opmr_mem8
                        DW OFFSET not_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrF618:
                        DW OFFSET opmr_mem8
                        DW OFFSET neg_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrF620:
                        DW OFFSET opmr_mem8
                        DW OFFSET mul_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrF628:
                        DW OFFSET opmr_mem8
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrF630:
                        DW OFFSET opmr_mem8
                        DW OFFSET div_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrF638:
                        DW OFFSET opmr_mem8
                        DW OFFSET idiv_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

;
opmrF700:
                        DW OFFSET opmr_mem_im16
                        DW OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrF708:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrF710:
                        DW OFFSET opmr_mem16
                        DW OFFSET not_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrF718:
                        DW OFFSET opmr_mem16
                        DW OFFSET neg_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrF720:
                        DW OFFSET opmr_mem16
                        DW OFFSET mul_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrF728:
                        DW OFFSET opmr_mem16
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrF730:
                        DW OFFSET opmr_mem16
                        DW OFFSET div_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrF738:
                        DW OFFSET opmr_mem16
                        DW OFFSET idiv_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

;
opmrFE00:
                        DW OFFSET opmr_mem8
                        DW OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrFE08:
                        DW OFFSET opmr_mem8
                        DW OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrFE10:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrFE18:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrFE20:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrFE28:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrFE30:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opmrFE38:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

;
opmrFF00:
                        DW OFFSET opmr_mem16
                        DW OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrFF08:
                        DW OFFSET opmr_mem16
                        DW OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrFF10:
                        DW OFFSET opmr_mem16
                        DW OFFSET call_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET near_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrFF18:
                        DW OFFSET opmr_mem16
                        DW OFFSET call_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET far_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrFF20:
                        DW OFFSET opmr_mem16
                        DW OFFSET jmp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET near_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrFF28:
                        DW OFFSET opmr_mem16
                        DW OFFSET jmp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET far_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opmrFF30:
                        DW OFFSET opmr_mem16
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opmrFF38:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


;;;;;;;;;;;;;;;;;;;;;;
; OP_CDT_TAB
;;;;;;;;;;;;;;;;;;;;;;

opcdt0F2000:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F2040:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F2080:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F20C0:
                        DW OFFSET op_reg_cr
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


opcdt0F2100:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F2140:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F2180:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F21C0:
                        DW OFFSET op_reg_dr
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


opcdt0F2200:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F2240:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F2280:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F22C0:
                        DW OFFSET op_cr_reg
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


opcdt0F2300:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F2340:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F2380:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F23C0:
                        DW OFFSET op_dr_reg
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


opcdt0F2400:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F2440:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F2480:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F24C0:
                        DW OFFSET op_reg_tr
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


opcdt0F2600:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F2640:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F2680:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opcdt0F26C0:
                        DW OFFSET op_tr_reg
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh



;;;;;;;;;;;;;;;;;;;;;;
; OP_PROT2_TAB
;;;;;;;;;;;;;;;;;;;;;;

opp0F0000:
                        DW OFFSET opmr_mem3
                        DW OFFSET sldt_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0008:
                        DW OFFSET opmr_mem3
                        DW OFFSET str_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0010:
                        DW OFFSET opmr_mem3
                        DW OFFSET lldt_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0018:
                        DW OFFSET opmr_mem3
                        DW OFFSET ltr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0020:
                        DW OFFSET opmr_mem3
                        DW OFFSET verr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0028:
                        DW OFFSET opmr_mem3
                        DW OFFSET verw_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0030:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0038:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


opp0F0100:
                        DW OFFSET opmr_mem3
                        DW OFFSET sgdt_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0108:
                        DW OFFSET opmr_mem3
                        DW OFFSET sidt_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0110:
                        DW OFFSET opmr_mem3
                        DW OFFSET lgdt_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0118:
                        DW OFFSET opmr_mem3
                        DW OFFSET lidt_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0120:
                        DW OFFSET opmr_mem3
                        DW OFFSET lmsw_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0128:
                        DW OFFSET opmr_mem3
                        DW OFFSET smsw_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0130:
                        DW OFFSET opmr_mem3
                        DW OFFSET lmsw_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0F0138:
                        DW OFFSET opmr_mem3
                        DW OFFSET smsw_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


opp0FBA00:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opp0FBA08:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opp0FBA10:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opp0FBA18:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opp0FBA20:
                        DW OFFSET op_mem_byte3
                        DW OFFSET bt_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0FBA28:
                        DW OFFSET op_mem_byte3
                        DW OFFSET bts_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0FBA30:
                        DW OFFSET op_mem_byte3
                        DW OFFSET btr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opp0FBA38:
                        DW OFFSET op_mem_byte3
                        DW OFFSET btc_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


;;;;;;;;;;;;;;;;;;;;;;
; OP_PROTECT_TAB
;;;;;;;;;;;;;;;;;;;;;;

oppr0F00:
                        DW OFFSET opp0F0000
                        DW op_prot2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F01:
                        DW OFFSET opp0F0100
                        DW op_prot2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F02:
                        DW OFFSET op_reg_mem2_word
                        DW OFFSET lar_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F03:
                        DW OFFSET op_reg_mem2_word
                        DW OFFSET lsl_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F04:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F05:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F06:
                        DW OFFSET op_one
                        DW OFFSET clts_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F07:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F08:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F09:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F0A:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F0B:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F0C:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F0D:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F0E:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F0F:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F10:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F11:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F12:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F13:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F14:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F15:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F16:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F17:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F18:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F19:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F1A:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F1B:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F1C:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F1D:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F1E:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F1F:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F20:
                        DW OFFSET opcdt0F2000
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW op_cdt_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F21:
                        DW OFFSET opcdt0F2100
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW op_cdt_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F22:
                        DW OFFSET opcdt0F2200
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW op_cdt_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F23:
                        DW OFFSET opcdt0F2300
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW op_cdt_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F24:
                        DW OFFSET opcdt0F2400
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW op_cdt_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F25:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F26:
                        DW OFFSET opcdt0F2600
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW op_cdt_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F27:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F28:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F29:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F2A:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F2B:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F2C:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F2D:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F2E:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F2F:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F30:
                        DW OFFSET op_one
                        DW OFFSET wrmsr_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F31:
                        DW OFFSET op_one
                        DW OFFSET rdtsc_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F32:
                        DW OFFSET op_one
                        DW OFFSET rdmsr_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F33:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F34:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F35:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F36:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F37:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F38:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F39:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F3A:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F3B:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F3C:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F3D:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F3E:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F3F:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F40:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F41:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F42:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F43:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F44:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F45:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F46:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F47:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F48:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F49:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F4A:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F4B:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F4C:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F4D:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F4E:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F4F:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F50:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F51:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F52:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F53:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F54:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F55:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F56:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F57:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F58:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F59:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F5A:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F5B:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F5C:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F5D:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F5E:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F5F:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F60:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F61:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F62:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F63:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F64:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F65:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F66:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F67:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F68:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F69:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F6A:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F6B:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F6C:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F6D:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F6E:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F6F:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F70:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F71:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F72:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F73:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F74:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F75:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F76:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F77:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F78:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F79:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F7A:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F7B:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F7C:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F7D:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F7E:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F7F:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F80:
                        DW OFFSET op_near2
                        DW OFFSET jo_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F81:
                        DW OFFSET op_near2
                        DW OFFSET jno_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F82:
                        DW OFFSET op_near2
                        DW OFFSET jb_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F83:
                        DW OFFSET op_near2
                        DW OFFSET jnb_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F84:
                        DW OFFSET op_near2
                        DW OFFSET jz_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F85:
                        DW OFFSET op_near2
                        DW OFFSET jnz_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F86:
                        DW OFFSET op_near2
                        DW OFFSET jbe_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F87:
                        DW OFFSET op_near2
                        DW OFFSET ja_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F88:
                        DW OFFSET op_near2
                        DW OFFSET js_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F89:
                        DW OFFSET op_near2
                        DW OFFSET jns_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F8A:
                        DW OFFSET op_near2
                        DW OFFSET jpe_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F8B:
                        DW OFFSET op_near2
                        DW OFFSET jpo_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F8C:
                        DW OFFSET op_near2
                        DW OFFSET jl_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F8D:
                        DW OFFSET op_near2
                        DW OFFSET jge_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F8E:
                        DW OFFSET op_near2
                        DW OFFSET jle_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F8F:
                        DW OFFSET op_near2
                        DW OFFSET jg_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F90:
                        DW OFFSET opmr_mem2
                        DW OFFSET seto_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F91:
                        DW OFFSET opmr_mem2
                        DW OFFSET setno_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F92:
                        DW OFFSET opmr_mem2
                        DW OFFSET setb_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F93:
                        DW OFFSET opmr_mem2
                        DW OFFSET setnb_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F94:
                        DW OFFSET opmr_mem2
                        DW OFFSET setz_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F95:
                        DW OFFSET opmr_mem2
                        DW OFFSET setnz_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F96:
                        DW OFFSET opmr_mem2
                        DW OFFSET setbe_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F97:
                        DW OFFSET opmr_mem2
                        DW OFFSET seta_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F98:
                        DW OFFSET opmr_mem2
                        DW OFFSET sets_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F99:
                        DW OFFSET opmr_mem2
                        DW OFFSET setns_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F9A:
                        DW OFFSET opmr_mem2
                        DW OFFSET setpe_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F9B:
                        DW OFFSET opmr_mem2
                        DW OFFSET setpo_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F9C:
                        DW OFFSET opmr_mem2
                        DW OFFSET setl_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F9D:
                        DW OFFSET opmr_mem2
                        DW OFFSET setge_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F9E:
                        DW OFFSET opmr_mem2
                        DW OFFSET setle_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0F9F:
                        DW OFFSET opmr_mem2
                        DW OFFSET setg_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FA0:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET fs_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FA1:
                        DW OFFSET op_one
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET fs_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FA2:
                        DW OFFSET op_one
                        DW OFFSET cpuid_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FA3:
                        DW OFFSET op_mem_reg2
                        DW OFFSET bt_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FA4:
                        DW OFFSET op_reg_mem_byte2
                        DW OFFSET shld_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FA5:
                        DW OFFSET op_reg_mem2_word
                        DW OFFSET shld_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh

oppr0FA6:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FA7:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FA8:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET gs_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FA9:
                        DW OFFSET op_one
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET gs_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FAA:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FAB:
                        DW OFFSET op_mem_reg2
                        DW OFFSET bts_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FAC:
                        DW OFFSET op_reg_mem_byte2
                        DW OFFSET shrd_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FAD:
                        DW OFFSET op_reg_mem2_word
                        DW OFFSET shrd_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh

oppr0FAE:
                        DW OFFSET op_reg_mem2_byte
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FAF:
                        DW OFFSET op_reg_mem2_word
                        DW OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FB0:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FB1:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FB2:
                        DW OFFSET op_reg_mem2_word
                        DW OFFSET lss_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FB3:
                        DW OFFSET op_mem_reg2
                        DW OFFSET btr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FB4:
                        DW OFFSET op_reg_mem2_word
                        DW OFFSET lfs_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FB5:
                        DW OFFSET op_reg_mem2_word
                        DW OFFSET lgs_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FB6:
                        DW OFFSET op_reg_mem2_byte
                        DW OFFSET movzx_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FB7:
                        DW OFFSET op_reg_mem2_word
                        DW OFFSET movzx_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FB8:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FB9:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FBA:
                        DW OFFSET opp0FBA00
                        DW op_prot2_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FBB:
                        DW OFFSET op_mem_reg2
                        DW OFFSET btc_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FBC:
                        DW OFFSET op_mem_reg2
                        DW OFFSET bsf_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FBD:
                        DW OFFSET op_mem_reg2
                        DW OFFSET bsr_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FBE:
                        DW OFFSET op_reg_mem2_byte
                        DW OFFSET movsx_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FBF:
                        DW OFFSET op_reg_mem2_word
                        DW OFFSET movsx_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FC0:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FC1:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FC2:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FC3:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FC4:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FC5:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FC6:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FC7:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FC8:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FC9:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FCA:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FCB:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FCC:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FCD:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FCE:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FCF:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FD0:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FD1:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FD2:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FD3:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FD4:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FD5:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FD6:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FD7:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FD8:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FD9:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FDA:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FDB:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FDC:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FDD:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FDE:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FDF:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FE0:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FE1:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FE2:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FE3:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FE4:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FE5:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FE6:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FE7:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FE8:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FE9:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FEA:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FEB:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FEC:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FED:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FEE:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FEF:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FF0:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FF1:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FF2:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FF3:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FF4:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FF5:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FF6:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FF7:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FF8:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FF9:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FFA:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FFB:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FFC:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FFD:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FFE:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

oppr0FFF:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh




;;;;;;;;;;;;;;;;;;;;;;
; MAIN_OP_TAB
;;;;;;;;;;;;;;;;;;;;;;

        public main_tab

main_tab:

op00:
                        DW OFFSET op_mem_reg_byte
                        DW OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op01:
                        DW OFFSET op_mem_reg_word
                        DW OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op02:
                        DW OFFSET op_reg_mem_byte
                        DW OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op03:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op04:
                        DW OFFSET op_byte
                        DW OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op05:
                        DW OFFSET op_word
                        DW OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op06:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET es_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op07:
                        DW OFFSET op_one
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET es_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op08:
                        DW OFFSET op_mem_reg_byte
                        DW OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op09:
                        DW OFFSET op_mem_reg_word
                        DW OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op0A:
                        DW OFFSET op_reg_mem_byte
                        DW OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op0B:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op0C:
                        DW OFFSET op_byte
                        DW OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op0D:
                        DW OFFSET op_word
                        DW OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op0E:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET cs_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op0F:
                        DW OFFSET oppr0F00
                        DW op_protect_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


op10:
                        DW OFFSET op_mem_reg_byte
                        DW OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op11:
                        DW OFFSET op_mem_reg_word
                        DW OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op12:
                        DW OFFSET op_reg_mem_byte
                        DW OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op13:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op14:
                        DW OFFSET op_byte
                        DW OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op15:
                        DW OFFSET op_word
                        DW OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op16:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET ss_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op17:
                        DW OFFSET op_one
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET ss_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op18:
                        DW OFFSET op_mem_reg_byte
                        DW OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op19:
                        DW OFFSET op_mem_reg_word
                        DW OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op1A:
                        DW OFFSET op_reg_mem_byte
                        DW OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op1B:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op1C:
                        DW OFFSET op_byte
                        DW OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op1D:
                        DW OFFSET op_word
                        DW OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op1E:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET ds_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op1F:
                        DW OFFSET op_one
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET ds_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op20:
                        DW OFFSET op_mem_reg_byte
                        DW OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op21:
                        DW OFFSET op_mem_reg_word
                        DW OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op22:
                        DW OFFSET op_reg_mem_byte
                        DW OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op23:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op24:
                        DW OFFSET op_byte
                        DW OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op25:
                        DW OFFSET op_word
                        DW OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op26:
                        DW OFFSET override_es
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op27:
                        DW OFFSET op_one
                        DW OFFSET daa_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op28:
                        DW OFFSET op_mem_reg_byte
                        DW OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op29:
                        DW OFFSET op_mem_reg_word
                        DW OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op2A:
                        DW OFFSET op_reg_mem_byte
                        DW OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op2B:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op2C:
                        DW OFFSET op_byte
                        DW OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op2D:
                        DW OFFSET op_word
                        DW OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op2E:
                        DW OFFSET override_cs
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op2F:
                        DW OFFSET op_one
                        DW OFFSET das_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op30:
                        DW OFFSET op_mem_reg_byte
                        DW OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op31:
                        DW OFFSET op_mem_reg_word
                        DW OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op32:
                        DW OFFSET op_reg_mem_byte
                        DW OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op33:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op34:
                        DW OFFSET op_byte
                        DW OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op35:
                        DW OFFSET op_word
                        DW OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op36:
                        DW OFFSET override_ss
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op37:
                        DW OFFSET op_one
                        DW OFFSET aaa_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op38:
                        DW OFFSET op_mem_reg_byte
                        DW OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op39:
                        DW OFFSET op_mem_reg_word
                        DW OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op3A:
                        DW OFFSET op_reg_mem_byte
                        DW OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op3B:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op3C:
                        DW OFFSET op_byte
                        DW OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op3D:
                        DW OFFSET op_word
                        DW OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

op3E:
                        DW OFFSET override_ds
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op3F:
                        DW OFFSET op_one
                        DW OFFSET aas_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op40:
                        DW OFFSET op_one
                        DW OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op41:
                        DW OFFSET op_one
                        DW OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DW cx_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op42:
                        DW OFFSET op_one
                        DW OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DW dx_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op43:
                        DW OFFSET op_one
                        DW OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DW bx_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op44:
                        DW OFFSET op_one
                        DW OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DW sp_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op45:
                        DW OFFSET op_one
                        DW OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DW bp_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op46:
                        DW OFFSET op_one
                        DW OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DW si_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op47:
                        DW OFFSET op_one
                        DW OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DW di_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op48:
                        DW OFFSET op_one
                        DW OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op49:
                        DW OFFSET op_one
                        DW OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DW cx_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op4A:
                        DW OFFSET op_one
                        DW OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DW dx_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op4B:
                        DW OFFSET op_one
                        DW OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DW bx_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op4C:
                        DW OFFSET op_one
                        DW OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DW sp_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op4D:
                        DW OFFSET op_one
                        DW OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DW bp_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op4E:
                        DW OFFSET op_one
                        DW OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DW si_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op4F:
                        DW OFFSET op_one
                        DW OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DW di_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op50:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op51:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW cx_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op52:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW dx_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op53:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW bx_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op54:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW sp_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op55:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW bp_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op56:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW si_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op57:
                        DW OFFSET op_one
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW di_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op58:
                        DW OFFSET op_one
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op59:
                        DW OFFSET op_one
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW cx_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op5A:
                        DW OFFSET op_one
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW dx_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op5B:
                        DW OFFSET op_one
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW bx_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op5C:
                        DW OFFSET op_one
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW sp_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op5D:
                        DW OFFSET op_one
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW bp_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op5E:
                        DW OFFSET op_one
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW si_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op5F:
                        DW OFFSET op_one
                        DW OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DW di_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op60:
                        DW OFFSET op_one
                        DW OFFSET pusha_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op61:
                        DW OFFSET op_one
                        DW OFFSET popa_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op62:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET bound_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op63:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET arpl_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op64:
                        DW OFFSET override_fs
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op65:
                        DW OFFSET override_gs
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op66:
                        DW OFFSET op_data_size
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op67:
                        DW OFFSET op_address_size
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op68:
                        DW OFFSET op_word
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op69:
                        DW OFFSET opmr6900
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op6A:
                        DW OFFSET op_byte
                        DW OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op6B:
                        DW OFFSET opmr6B00
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op6C:
                        DW OFFSET op_string1b
                        DW OFFSET ins_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

op6D:
                        DW OFFSET op_string1w
                        DW OFFSET ins_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

op6E:
                        DW OFFSET op_string1b
                        DW OFFSET outs_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

op6F:
                        DW OFFSET op_string1w
                        DW OFFSET outs_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

op70:
                        DW OFFSET op_short
                        DW OFFSET jo_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op71:
                        DW OFFSET op_short
                        DW OFFSET jno_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op72:
                        DW OFFSET op_short
                        DW OFFSET jb_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op73:
                        DW OFFSET op_short
                        DW OFFSET jnb_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op74:
                        DW OFFSET op_short
                        DW OFFSET jz_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op75:
                        DW OFFSET op_short
                        DW OFFSET jnz_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op76:
                        DW OFFSET op_short
                        DW OFFSET jbe_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op77:
                        DW OFFSET op_short
                        DW OFFSET ja_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op78:
                        DW OFFSET op_short
                        DW OFFSET js_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op79:
                        DW OFFSET op_short
                        DW OFFSET jns_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op7A:
                        DW OFFSET op_short
                        DW OFFSET jpe_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op7B:
                        DW OFFSET op_short
                        DW OFFSET jpo_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op7C:
                        DW OFFSET op_short
                        DW OFFSET jl_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op7D:
                        DW OFFSET op_short
                        DW OFFSET jge_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op7E:
                        DW OFFSET op_short
                        DW OFFSET jle_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op7F:
                        DW OFFSET op_short
                        DW OFFSET jg_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op80:
                        DW OFFSET opmr8000
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op81:
                        DW OFFSET opmr8100
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op82:
                        DW OFFSET opmr8200
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op83:
                        DW OFFSET opmr8300
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op84:
                        DW OFFSET op_mem_reg_byte
                        DW OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op85:
                        DW OFFSET op_mem_reg_word
                        DW OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op86:
                        DW OFFSET op_reg_mem_byte
                        DW OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op87:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op88:
                        DW OFFSET op_mem_reg_byte
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op89:
                        DW OFFSET op_mem_reg_word
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op8A:
                        DW OFFSET op_reg_mem_byte
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op8B:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op8C:
                        DW OFFSET opmr8C00
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op8D:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET lea_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op8E:
                        DW OFFSET opmr8E00
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op8F:
                        DW OFFSET opmr8F00
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op90:
                        DW OFFSET op_one
                        DW OFFSET nop_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op91:
                        DW OFFSET op_one
                        DW OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW cx_tab + blank_sep
                        DW 0FFFFh

op92:
                        DW OFFSET op_one
                        DW OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW dx_tab + blank_sep
                        DW 0FFFFh

op93:
                        DW OFFSET op_one
                        DW OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW bx_tab + blank_sep
                        DW 0FFFFh

op94:
                        DW OFFSET op_one
                        DW OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW sp_tab + blank_sep
                        DW 0FFFFh

op95:
                        DW OFFSET op_one
                        DW OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW bp_tab + blank_sep
                        DW 0FFFFh

op96:
                        DW OFFSET op_one
                        DW OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW si_tab + blank_sep
                        DW 0FFFFh

op97:
                        DW OFFSET op_one
                        DW OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW di_tab + blank_sep
                        DW 0FFFFh

op98:
                        DW OFFSET op_one
                        DW OFFSET cbw_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op99:
                        DW OFFSET op_one
                        DW OFFSET cwd_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op9A:
                        DW OFFSET op_far
                        DW OFFSET call_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


op9B:
                        DW OFFSET op_wait
                        DW OFFSET wait_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

op9C:
                        DW OFFSET op_one
                        DW OFFSET pushf_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op9D:
                        DW OFFSET op_one
                        DW OFFSET popf_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op9E:
                        DW OFFSET op_one
                        DW OFFSET sahf_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

op9F:
                        DW OFFSET op_one
                        DW OFFSET lahf_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opA0:
                        DW OFFSET op_word_mem
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW null_tab + rhak_sep

opA1:
                        DW OFFSET op_word_mem
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET ax_txt - OFFSET mne_tab + komma_sep
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW null_tab + rhak_sep

opA2:
                        DW OFFSET op_word_mem
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW null_tab + par_komma_sep
                        DW OFFSET al_txt - OFFSET mne_tab + blank_sep

opA3:
                        DW OFFSET op_word_mem
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW null_tab + par_komma_sep
                        DW OFFSET ax_txt - OFFSET mne_tab + blank_sep

opA4:
                        DW OFFSET op_string2b
                        DW OFFSET movs_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

opA5:
                        DW OFFSET op_string2w
                        DW OFFSET movs_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

opA6:
                        DW OFFSET op_string2b
                        DW OFFSET cmps_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

opA7:
                        DW OFFSET op_string2w
                        DW OFFSET cmps_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

opA8:
                        DW OFFSET op_byte
                        DW OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opA9:
                        DW OFFSET op_word
                        DW OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opAA:
                        DW OFFSET op_string1b
                        DW OFFSET stos_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

opAB:
                        DW OFFSET op_string1w
                        DW OFFSET stos_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

opAC:
                        DW OFFSET op_string1b
                        DW OFFSET lods_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

opAD:
                        DW OFFSET op_string1w
                        DW OFFSET lods_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

opAE:
                        DW OFFSET op_string1b
                        DW OFFSET scas_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

opAF:
                        DW OFFSET op_string1w
                        DW OFFSET scas_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

opB0:
                        DW OFFSET op_byte
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opB1:
                        DW OFFSET op_byte
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET cl_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opB2:
                        DW OFFSET op_byte
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dl_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opB3:
                        DW OFFSET op_byte
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET bl_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opB4:
                        DW OFFSET op_byte
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET ah_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opB5:
                        DW OFFSET op_byte
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET ch_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opB6:
                        DW OFFSET op_byte
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dh_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opB7:
                        DW OFFSET op_byte
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET bh_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opB8:
                        DW OFFSET op_word
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opB9:
                        DW OFFSET op_word
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW cx_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opBA:
                        DW OFFSET op_word
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW dx_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opBB:
                        DW OFFSET op_word
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW bx_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opBC:
                        DW OFFSET op_word
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW sp_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opBD:
                        DW OFFSET op_word
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW bp_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opBE:
                        DW OFFSET op_word
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW si_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opBF:
                        DW OFFSET op_word
                        DW OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DW di_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opC0:
                        DW OFFSET opmrC000
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opC1:
                        DW OFFSET opmrC100
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opC2:
                        DW OFFSET op_word16
                        DW OFFSET retn_txt - OFFSET mne_tab + no_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opC3:
                        DW OFFSET op_add_opsize
                        DW OFFSET retn_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

opC4:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET les_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opC5:
                        DW OFFSET op_reg_mem_word
                        DW OFFSET lds_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opC6:
                        DW OFFSET opmrC600
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opC7:
                        DW OFFSET opmrC700
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opC8:
                        DW OFFSET op_enter
                        DW OFFSET enter_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


opC9:
                        DW OFFSET op_one
                        DW OFFSET leave_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opCA:
                        DW OFFSET op_word16
                        DW OFFSET retf_txt - OFFSET mne_tab + no_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opCB:
                        DW OFFSET op_add_opsize
                        DW OFFSET retf_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

opCC:
                        DW OFFSET op_one
                        DW OFFSET int_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET txt_3 - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opCD:
                        DW OFFSET op_byte
                        DW OFFSET int_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opCE:
                        DW OFFSET op_one
                        DW OFFSET into_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opCF:
                        DW OFFSET op_add_opsize
                        DW OFFSET iret_txt - OFFSET mne_tab + no_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

opD0:
                        DW OFFSET opmrD000
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opD1:
                        DW OFFSET opmrD100
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opD2:
                        DW OFFSET opmrD200
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opD3:
                        DW OFFSET opmrD300
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opD4:
                        DW OFFSET op_byte
                        DW OFFSET aam_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opD5:
                        DW OFFSET op_byte
                        DW OFFSET aad_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opD6:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opD7:
                        DW OFFSET op_one
                        DW OFFSET xlat_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opD8:
                        DW OFFSET opmrD800
                        DW op_math_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opD9:
                        DW OFFSET opmrD900
                        DW op_math_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opDA:
                        DW OFFSET opmrDA00
                        DW op_math_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opDB:
                        DW OFFSET opmrDB00
                        DW op_math_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opDC:
                        DW OFFSET opmrDC00
                        DW op_math_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opDD:
                        DW OFFSET opmrDD00
                        DW op_math_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opDE:
                        DW OFFSET opmrDE00
                        DW op_math_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opDF:
                        DW OFFSET opmrDF00
                        DW op_math_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opE0:
                        DW OFFSET op_short
                        DW OFFSET loopnz_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


opE1:
                        DW OFFSET op_short
                        DW OFFSET loopz_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


opE2:
                        DW OFFSET op_short
                        DW OFFSET loop_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


opE3:
                        DW OFFSET op_short
                        DW OFFSET jcxz_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


opE4:
                        DW OFFSET op_byte
                        DW OFFSET in_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opE5:
                        DW OFFSET op_byte
                        DW OFFSET in_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh

opE6:
                        DW OFFSET op_byte
                        DW OFFSET out_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW OFFSET al_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh

opE7:
                        DW OFFSET op_byte
                        DW OFFSET out_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + komma_sep
                        DW ax_tab + blank_sep
                        DW 0FFFFh

opE8:
                        DW OFFSET op_near
                        DW OFFSET call_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opE9:
                        DW OFFSET op_near
                        DW OFFSET jmp_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opEA:
                        DW OFFSET op_far
                        DW OFFSET jmp_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


opEB:
                        DW OFFSET op_short
                        DW OFFSET jmp_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh


opEC:
                        DW OFFSET op_one
                        DW OFFSET in_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DW OFFSET dx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh

opED:
                        DW OFFSET op_one
                        DW OFFSET in_txt - OFFSET mne_tab + blank_sep
                        DW ax_tab + komma_sep
                        DW OFFSET dx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh

opEE:
                        DW OFFSET op_one
                        DW OFFSET out_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dx_txt - OFFSET mne_tab + komma_sep
                        DW OFFSET al_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh

opEF:
                        DW OFFSET op_one
                        DW OFFSET out_txt - OFFSET mne_tab + blank_sep
                        DW OFFSET dx_txt - OFFSET mne_tab + komma_sep
                        DW ax_tab + blank_sep
                        DW 0FFFFh

opF0:
                        DW OFFSET op_one
                        DW OFFSET lock_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opF1:
                        DW OFFSET op_illegal
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opF2:
                        DW OFFSET op_rep
                        DW OFFSET repnz_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opF3:
                        DW OFFSET op_rep
                        DW OFFSET repz_txt - OFFSET mne_tab + blank_sep
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh

opF4:
                        DW OFFSET op_one
                        DW OFFSET hlt_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opF5:
                        DW OFFSET op_one
                        DW OFFSET cmc_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opF6:
                        DW OFFSET opmrF600
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opF7:
                        DW OFFSET opmrF700
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opF8:
                        DW OFFSET op_one
                        DW OFFSET clc_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opF9:
                        DW OFFSET op_one
                        DW OFFSET stc_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opFA:
                        DW OFFSET op_one
                        DW OFFSET cli_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opFB:
                        DW OFFSET op_one
                        DW OFFSET sti_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opFC:
                        DW OFFSET op_one
                        DW OFFSET cld_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opFD:
                        DW OFFSET op_one
                        DW OFFSET std_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opFE:
                        DW OFFSET opmrFE00
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

opFF:
                        DW OFFSET opmrFF00
                        DW op_mem_reg_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


mem8d_16a_tab:
mod8d_16a_rm00000:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh

mod8d_16a_rm00001:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET dx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh

mod8d_16a_rm00010:
                        DW OFFSET op_one
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh

mod8d_16a_rm00011:
                        DW OFFSET op_one
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh

mod8d_16a_rm00100:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_16a_rm00101:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_16a_rm00110:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_16a_rm00111:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_16a_rm01000:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod8d_16a_rm01001:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod8d_16a_rm01010:
                        DW OFFSET mem_im8
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod8d_16a_rm01011:
                        DW OFFSET mem_im8
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod8d_16a_rm01100:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_16a_rm01101:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_16a_rm01110:
                        DW OFFSET mem_im8
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_16a_rm01111:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_16a_rm10000:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod8d_16a_rm10001:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod8d_16a_rm10010:
                        DW OFFSET mem_im16
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod8d_16a_rm10011:
                        DW OFFSET mem_im16
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod8d_16a_rm10100:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_16a_rm10101:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_16a_rm10110:
                        DW OFFSET mem_im16
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_16a_rm10111:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_16a_rm11000:
                        DW OFFSET op_one
                        DW OFFSET al_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_16a_rm11001:
                        DW OFFSET op_one
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_16a_rm11010:
                        DW OFFSET op_one
                        DW OFFSET dl_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_16a_rm11011:
                        DW OFFSET op_one
                        DW OFFSET bl_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_16a_rm11100:
                        DW OFFSET op_one
                        DW OFFSET ah_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_16a_rm11101:
                        DW OFFSET op_one
                        DW OFFSET ch_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_16a_rm11110:
                        DW OFFSET op_one
                        DW OFFSET dh_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_16a_rm11111:
                        DW OFFSET op_one
                        DW OFFSET bh_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh



mem16d_16a_tab:
mod16d_16a_rm00000:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh

mod16d_16a_rm00001:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET dx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh

mod16d_16a_rm00010:
                        DW OFFSET op_one
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh

mod16d_16a_rm00011:
                        DW OFFSET op_one
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh

mod16d_16a_rm00100:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_16a_rm00101:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_16a_rm00110:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_16a_rm00111:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_16a_rm01000:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod16d_16a_rm01001:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod16d_16a_rm01010:
                        DW OFFSET mem_im8
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod16d_16a_rm01011:
                        DW OFFSET mem_im8
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod16d_16a_rm01100:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_16a_rm01101:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_16a_rm01110:
                        DW OFFSET mem_im8
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_16a_rm01111:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_16a_rm10000:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod16d_16a_rm10001:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod16d_16a_rm10010:
                        DW OFFSET mem_im16
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod16d_16a_rm10011:
                        DW OFFSET mem_im16
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod16d_16a_rm10100:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_16a_rm10101:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_16a_rm10110:
                        DW OFFSET mem_im16
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_16a_rm10111:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_16a_rm11000:
                        DW OFFSET op_one
                        DW OFFSET ax_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_16a_rm11001:
                        DW OFFSET op_one
                        DW OFFSET cx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_16a_rm11010:
                        DW OFFSET op_one
                        DW OFFSET dx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_16a_rm11011:
                        DW OFFSET op_one
                        DW OFFSET bx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_16a_rm11100:
                        DW OFFSET op_one
                        DW OFFSET sp_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_16a_rm11101:
                        DW OFFSET op_one
                        DW OFFSET bp_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_16a_rm11110:
                        DW OFFSET op_one
                        DW OFFSET si_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_16a_rm11111:
                        DW OFFSET op_one
                        DW OFFSET di_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh



mem32d_16a_tab:
mod32d_16a_rm00000:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh

mod32d_16a_rm00001:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET dx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh

mod32d_16a_rm00010:
                        DW OFFSET op_one
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh

mod32d_16a_rm00011:
                        DW OFFSET op_one
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh

mod32d_16a_rm00100:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_16a_rm00101:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_16a_rm00110:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_16a_rm00111:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_16a_rm01000:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod32d_16a_rm01001:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod32d_16a_rm01010:
                        DW OFFSET mem_im8
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod32d_16a_rm01011:
                        DW OFFSET mem_im8
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod32d_16a_rm01100:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_16a_rm01101:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_16a_rm01110:
                        DW OFFSET mem_im8
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_16a_rm01111:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_16a_rm10000:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod32d_16a_rm10001:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod32d_16a_rm10010:
                        DW OFFSET mem_im16
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod32d_16a_rm10011:
                        DW OFFSET mem_im16
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep

mod32d_16a_rm10100:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_16a_rm10101:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_16a_rm10110:
                        DW OFFSET mem_im16
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_16a_rm10111:
                        DW OFFSET mem_im16
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_16a_rm11000:
                        DW OFFSET op_one
                        DW OFFSET eax_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_16a_rm11001:
                        DW OFFSET op_one
                        DW OFFSET ecx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_16a_rm11010:
                        DW OFFSET op_one
                        DW OFFSET edx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_16a_rm11011:
                        DW OFFSET op_one
                        DW OFFSET ebx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_16a_rm11100:
                        DW OFFSET op_one
                        DW OFFSET esp_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_16a_rm11101:
                        DW OFFSET op_one
                        DW OFFSET ebp_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_16a_rm11110:
                        DW OFFSET op_one
                        DW OFFSET esi_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_16a_rm11111:
                        DW OFFSET op_one
                        DW OFFSET edi_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


mem8d_32a_tab:
mod8d_32a_rm00000:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET eax_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm00001:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ecx_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm00010:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edx_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm00011:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebx_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm00100:
                        DW OFFSET mem_sib
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm00101:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm00110:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esi_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm00111:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edi_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm01000:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm01001:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm01010:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm01011:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm01100:
                        DW OFFSET mem_sib
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm01101:
                        DW OFFSET mem_im8
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm01110:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm01111:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm10000:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm10001:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm10010:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm10011:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm10100:
                        DW OFFSET mem_sib
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm10101:
                        DW OFFSET mem_im32
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm10110:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm10111:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod8d_32a_rm11000:
                        DW OFFSET op_one
                        DW OFFSET al_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm11001:
                        DW OFFSET op_one
                        DW OFFSET cl_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm11010:
                        DW OFFSET op_one
                        DW OFFSET dl_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm11011:
                        DW OFFSET op_one
                        DW OFFSET bl_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm11100:
                        DW OFFSET op_one
                        DW OFFSET ah_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm11101:
                        DW OFFSET op_one
                        DW OFFSET ch_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm11110:
                        DW OFFSET op_one
                        DW OFFSET dh_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod8d_32a_rm11111:
                        DW OFFSET op_one
                        DW OFFSET bh_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


mem16d_32a_tab:
mod16d_32a_rm00000:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET eax_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm00001:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ecx_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm00010:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edx_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm00011:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebx_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm00100:
                        DW OFFSET mem_sib
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm00101:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm00110:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esi_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm00111:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edi_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm01000:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm01001:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm01010:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm01011:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm01100:
                        DW OFFSET mem_sib
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm01101:
                        DW OFFSET mem_im8
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm01110:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm01111:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm10000:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm10001:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm10010:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm10011:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm10100:
                        DW OFFSET mem_sib
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm10101:
                        DW OFFSET mem_im32
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm10110:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm10111:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod16d_32a_rm11000:
                        DW OFFSET op_one
                        DW OFFSET ax_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm11001:
                        DW OFFSET op_one
                        DW OFFSET cx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm11010:
                        DW OFFSET op_one
                        DW OFFSET dx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm11011:
                        DW OFFSET op_one
                        DW OFFSET bx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm11100:
                        DW OFFSET op_one
                        DW OFFSET sp_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm11101:
                        DW OFFSET op_one
                        DW OFFSET bp_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm11110:
                        DW OFFSET op_one
                        DW OFFSET si_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod16d_32a_rm11111:
                        DW OFFSET op_one
                        DW OFFSET di_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


mem32d_32a_tab:
mod32d_32a_rm00000:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET eax_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm00001:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ecx_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm00010:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edx_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm00011:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebx_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm00100:
                        DW OFFSET mem_sib
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm00101:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm00110:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esi_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm00111:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edi_txt - OFFSET mne_tab + rhak_sep
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm01000:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm01001:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm01010:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm01011:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm01100:
                        DW OFFSET mem_sib
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm01101:
                        DW OFFSET mem_im8
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm01110:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm01111:
                        DW OFFSET mem_im8
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm10000:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm10001:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm10010:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm10011:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm10100:
                        DW OFFSET mem_sib
                        DW null_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm10101:
                        DW OFFSET mem_im32
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm10110:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm10111:
                        DW OFFSET mem_im32
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + rhak_sep
                        DW 0FFFFh

mod32d_32a_rm11000:
                        DW OFFSET op_one
                        DW OFFSET eax_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm11001:
                        DW OFFSET op_one
                        DW OFFSET ecx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm11010:
                        DW OFFSET op_one
                        DW OFFSET edx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm11011:
                        DW OFFSET op_one
                        DW OFFSET ebx_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm11100:
                        DW OFFSET op_one
                        DW OFFSET esp_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm11101:
                        DW OFFSET op_one
                        DW OFFSET ebp_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm11110:
                        DW OFFSET op_one
                        DW OFFSET esi_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

mod32d_32a_rm11111:
                        DW OFFSET op_one
                        DW OFFSET edi_txt - OFFSET mne_tab + blank_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


mem_sib0_tab:
sib0_000:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib0_001:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib0_010:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib0_011:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib0_100:
                        DW OFFSET op_one
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib0_101:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW null_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh

sib0_110:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib0_111:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh


mem_sib1_tab:
sib1_000:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib1_001:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib1_010:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib1_011:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib1_100:
                        DW OFFSET op_one
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib1_101:
                        DW OFFSET op_one
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib1_110:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib1_111:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh


mem_sib2_tab:
sib2_000:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib2_001:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib2_010:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib2_011:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib2_100:
                        DW OFFSET op_one
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib2_101:
                        DW OFFSET op_one
                        DW OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib2_110:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh

sib2_111:
                        DW OFFSET op_one
                        DW OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DW OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DW null_tab + no_sep
                        DW 0FFFFh


sib_index_tab:
sibi_000:
                        DW OFFSET op_one
                        DW OFFSET eax_txt - OFFSET mne_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

sibi_001:
                        DW OFFSET op_one
                        DW OFFSET ecx_txt - OFFSET mne_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

sibi_010:
                        DW OFFSET op_one
                        DW OFFSET edx_txt - OFFSET mne_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

sibi_011:
                        DW OFFSET op_one
                        DW OFFSET ebx_txt - OFFSET mne_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

sibi_100:
                        DW OFFSET op_one
                        DW OFFSET txt_0 - OFFSET mne_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

sibi_101:
                        DW OFFSET op_one
                        DW OFFSET ebp_txt - OFFSET mne_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

sibi_110:
                        DW OFFSET op_one
                        DW OFFSET esi_txt - OFFSET mne_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

sibi_111:
                        DW OFFSET op_one
                        DW OFFSET edi_txt - OFFSET mne_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


sib_scale_tab:
sibc_00:
                        DW OFFSET op_one
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

sibc_01:
                        DW OFFSET op_one
                        DW OFFSET star2 - OFFSET mne_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

sibc_10:
                        DW OFFSET op_one
                        DW OFFSET star4 - OFFSET mne_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh

sibc_11:
                        DW OFFSET op_one
                        DW OFFSET star8 - OFFSET mne_tab + no_sep
                        DW 0FFFFh
                        DW 0FFFFh
                        DW 0FFFFh


        public adr_16a_tab
        public adr_32a_tab
        public adr_sib_tab
        public adr_sib_index_tab

        extrn no_adr:near
        extrn bx_adr:near
        extrn bp_adr:near
        extrn si_adr:near
        extrn di_adr:near
        extrn eax_adr:near
        extrn ebx_adr:near
        extrn ecx_adr:near
        extrn edx_adr:near
        extrn esi_adr:near
        extrn edi_adr:near
        extrn ebp_adr:near
        extrn esp_adr:near

adr_16a_tab:
adr_16a_rm00000:
                        DW OFFSET bx_adr
                        DW OFFSET si_adr

adr_16a_rm00001:
                        DW OFFSET bx_adr
                        DW OFFSET di_adr

adr_16a_rm00010:
                        DW OFFSET bp_adr
                        DW OFFSET si_adr

adr_16a_rm00011:
                        DW OFFSET bp_adr
                        DW OFFSET di_adr

adr_16a_rm00100:
                        DW OFFSET si_adr
                        DW OFFSET no_adr

adr_16a_rm00101:
                        DW OFFSET di_adr
                        DW OFFSET no_adr

adr_16a_rm00110:
                        DW OFFSET no_adr
                        DW OFFSET no_adr

adr_16a_rm00111:
                        DW OFFSET bx_adr
                        DW OFFSET no_adr

adr_16a_rm01000:
                        DW OFFSET bx_adr
                        DW OFFSET si_adr

adr_16a_rm01001:
                        DW OFFSET bx_adr
                        DW OFFSET di_adr

adr_16a_rm01010:
                        DW OFFSET bp_adr
                        DW OFFSET si_adr

adr_16a_rm01011:
                        DW OFFSET bp_adr
                        DW OFFSET di_adr

adr_16a_rm01100:
                        DW OFFSET si_adr
                        DW OFFSET no_adr

adr_16a_rm01101:
                        DW OFFSET di_adr
                        DW OFFSET no_adr

adr_16a_rm01110:
                        DW OFFSET bp_adr
                        DW OFFSET no_adr

adr_16a_rm01111:
                        DW OFFSET bx_adr
                        DW OFFSET no_adr

adr_16a_rm10000:
                        DW OFFSET bx_adr
                        DW OFFSET si_adr

adr_16a_rm10001:
                        DW OFFSET bx_adr
                        DW OFFSET di_adr

adr_16a_rm10010:
                        DW OFFSET bp_adr
                        DW OFFSET si_adr

adr_16a_rm10011:
                        DW OFFSET bp_adr
                        DW OFFSET di_adr

adr_16a_rm10100:
                        DW OFFSET si_adr
                        DW OFFSET no_adr

adr_16a_rm10101:
                        DW OFFSET di_adr
                        DW OFFSET no_adr

adr_16a_rm10110:
                        DW OFFSET bp_adr
                        DW OFFSET no_adr

adr_16a_rm10111:
                        DW OFFSET bx_adr
                        DW OFFSET no_adr

adr_32a_tab:
adr_32a_rm00000:
                        DW OFFSET eax_adr
                        DW OFFSET no_adr

adr_32a_rm00001:
                        DW OFFSET ecx_adr
                        DW OFFSET no_adr

adr_32a_rm00010:
                        DW OFFSET edx_adr
                        DW OFFSET no_adr

adr_32a_rm00011:
                        DW OFFSET ebx_adr
                        DW OFFSET no_adr

adr_32a_rm00100:
                        DW OFFSET no_adr
                        DW OFFSET no_adr

adr_32a_rm00101:
                        DW OFFSET no_adr
                        DW OFFSET no_adr

adr_32a_rm00110:
                        DW OFFSET esi_adr
                        DW OFFSET no_adr

adr_32a_rm00111:
                        DW OFFSET edi_adr
                        DW OFFSET no_adr

adr_32a_rm01000:
                        DW OFFSET eax_adr
                        DW OFFSET no_adr

adr_32a_rm01001:
                        DW OFFSET ecx_adr
                        DW OFFSET no_adr

adr_32a_rm01010:
                        DW OFFSET edx_adr
                        DW OFFSET no_adr

adr_32a_rm01011:
                        DW OFFSET ebx_adr
                        DW OFFSET no_adr

adr_32a_rm01100:
                        DW OFFSET no_adr
                        DW OFFSET no_adr

adr_32a_rm01101:
                        DW OFFSET ebp_adr
                        DW OFFSET no_adr

adr_32a_rm01110:
                        DW OFFSET esi_adr
                        DW OFFSET no_adr

adr_32a_rm01111:
                        DW OFFSET edi_adr
                        DW OFFSET no_adr

adr_32a_rm10000:
                        DW OFFSET eax_adr
                        DW OFFSET no_adr

adr_32a_rm10001:
                        DW OFFSET ecx_adr
                        DW OFFSET no_adr

adr_32a_rm10010:
                        DW OFFSET edx_adr
                        DW OFFSET no_adr

adr_32a_rm10011:
                        DW OFFSET ebx_adr
                        DW OFFSET no_adr

adr_32a_rm10100:
                        DW OFFSET no_adr
                        DW OFFSET no_adr

adr_32a_rm10101:
                        DW OFFSET ebp_adr
                        DW OFFSET no_adr

adr_32a_rm10110:
                        DW OFFSET esi_adr
                        DW OFFSET no_adr

adr_32a_rm10111:
                        DW OFFSET edi_adr
                        DW OFFSET no_adr

adr_sib_tab:
adr_sib0_000:
                        DW OFFSET eax_adr
                        DW OFFSET no_adr

adr_sib0_001:
                        DW OFFSET ecx_adr
                        DW OFFSET no_adr

adr_sib0_010:
                        DW OFFSET edx_adr
                        DW OFFSET no_adr

adr_sib0_011:
                        DW OFFSET ebx_adr
                        DW OFFSET no_adr

adr_sib0_100:
                        DW OFFSET esp_adr
                        DW OFFSET no_adr

adr_sib0_101:
                        DW OFFSET no_adr
                        DW OFFSET no_adr

adr_sib0_110:
                        DW OFFSET esi_adr
                        DW OFFSET no_adr

adr_sib0_111:
                        DW OFFSET edi_adr
                        DW OFFSET no_adr


adr_sib1_000:
                        DW OFFSET eax_adr
                        DW OFFSET no_adr

adr_sib1_001:
                        DW OFFSET ecx_adr
                        DW OFFSET no_adr

adr_sib1_010:
                        DW OFFSET edx_adr
                        DW OFFSET no_adr

adr_sib1_011:
                        DW OFFSET ebx_adr
                        DW OFFSET no_adr

adr_sib1_100:
                        DW OFFSET esp_adr
                        DW OFFSET no_adr

adr_sib1_101:
                        DW OFFSET ebp_adr
                        DW OFFSET no_adr

adr_sib1_110:
                        DW OFFSET esi_adr
                        DW OFFSET no_adr

adr_sib1_111:
                        DW OFFSET edi_adr
                        DW OFFSET no_adr


adr_sib2_000:
                        DW OFFSET eax_adr
                        DW OFFSET no_adr

adr_sib2_001:
                        DW OFFSET ecx_adr
                        DW OFFSET no_adr

adr_sib2_010:
                        DW OFFSET edx_adr
                        DW OFFSET no_adr

adr_sib2_011:
                        DW OFFSET ebx_adr
                        DW OFFSET no_adr

adr_sib2_100:
                        DW OFFSET esp_adr
                        DW OFFSET no_adr

adr_sib2_101:
                        DW OFFSET ebp_adr
                        DW OFFSET no_adr

adr_sib2_110:
                        DW OFFSET esi_adr
                        DW OFFSET no_adr

adr_sib2_111:
                        DW OFFSET edi_adr
                        DW OFFSET no_adr

adr_sib_index_tab:
adr_sibi_000:
                        DW OFFSET eax_adr
                        DW OFFSET no_adr

adr_sibi_001:
                        DW OFFSET ecx_adr
                        DW OFFSET no_adr

adr_sibi_010:
                        DW OFFSET edx_adr
                        DW OFFSET no_adr

adr_sibi_011:
                        DW OFFSET ebx_adr
                        DW OFFSET no_adr

adr_sibi_100:
                        DW OFFSET no_adr
                        DW OFFSET no_adr

adr_sibi_101:
                        DW OFFSET ebp_adr
                        DW OFFSET no_adr

adr_sibi_110:
                        DW OFFSET esi_adr
                        DW OFFSET no_adr

adr_sibi_111:
                        DW OFFSET edi_adr
                        DW OFFSET no_adr

;                                                                       ##GIL##

                public  cr_tab
                
;Control register format

cr_tab:

tcr0:
                        DD OFFSET op_one
                        DD OFFSET cr_txt - OFFSET mne_tab + no_sep
                        DD OFFSET txt_0 - OFFSET mne_tab 
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tcr1:
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tcr2:
                        DD OFFSET op_one
                        DD OFFSET cr_txt - OFFSET mne_tab + no_sep
                        DD OFFSET txt_2 - OFFSET mne_tab 
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tcr3:
                        DD OFFSET op_one
                        DD OFFSET cr_txt - OFFSET mne_tab + no_sep
                        DD OFFSET txt_3 - OFFSET mne_tab 
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tcr4:
                        DD OFFSET op_one
                        DD OFFSET cr_txt - OFFSET mne_tab + no_sep
                        DD OFFSET txt_4 - OFFSET mne_tab 
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tcr5:
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tcr6:
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tcr7:
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

                public  dr_tab
                
;Debug register format

dr_tab:

tdr0:
                        DD OFFSET op_one
                        DD OFFSET dr_txt - OFFSET mne_tab + no_sep
                        DD OFFSET txt_0 - OFFSET mne_tab 
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tdr1:
                        DD OFFSET op_one
                        DD OFFSET dr_txt - OFFSET mne_tab + no_sep
                        DD OFFSET txt_1 - OFFSET mne_tab 
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tdr2:
                        DD OFFSET op_one
                        DD OFFSET dr_txt - OFFSET mne_tab + no_sep
                        DD OFFSET txt_2 - OFFSET mne_tab 
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tdr3:
                        DD OFFSET op_one
                        DD OFFSET dr_txt - OFFSET mne_tab + no_sep
                        DD OFFSET txt_3 - OFFSET mne_tab 
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tdr4:
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tdr5:
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tdr6:
                        DD OFFSET op_one
                        DD OFFSET dr_txt - OFFSET mne_tab + no_sep
                        DD OFFSET txt_6 - OFFSET mne_tab 
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
tdr7:
                        DD OFFSET op_one
                        DD OFFSET dr_txt - OFFSET mne_tab + no_sep
                        DD OFFSET txt_7 - OFFSET mne_tab 
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;                                       ##GIL END##     

code    ENDS
        END
