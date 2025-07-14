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
; DISTAB.ASM
; Disassembler tables
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386

code    SEGMENT byte use32 public 'CODE'
    
    assume cs:code

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   
;
;               DESCRIPTION:    
;
;               PARAMETERS:             
;
;               PASCAL-CALL:    
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public mod_rm_tab

mod_rm_tab:
mem8d_16a       DD OFFSET mem8d_16a_tab
mem16d_16a      DD OFFSET mem16d_16a_tab
mem32d_16a      DD OFFSET mem32d_16a_tab
mem8d_32a       DD OFFSET mem8d_32a_tab
mem16d_32a      DD OFFSET mem16d_32a_tab
mem32d_32a      DD OFFSET mem32d_32a_tab

        public long_mod_rm_tab

long_mod_rm_tab:
mem64_8d_32a       DD OFFSET mem64_8d_32a_tab
mem64_16d_32a      DD OFFSET mem64_16d_32a_tab
mem64_32d_32a      DD OFFSET mem64_32d_32a_tab
mem64_8d_64a       DD OFFSET mem64_8d_64a_tab
mem64_16d_64a      DD OFFSET mem64_16d_64a_tab
mem64_32d_64a      DD OFFSET mem64_32d_64a_tab

        public reg_tab

reg_tab:
reg8d   DD OFFSET mod8d_16a_rm11000
reg16d  DD OFFSET mod16d_16a_rm11000
reg32d  DD OFFSET mod32d_16a_rm11000


    public long_reg_tab

long_reg_tab:
lreg8   DD OFFSET mod64_8d_32a_rm110000
lreg16  DD OFFSET mod64_16d_32a_rm110000
lreg32  DD OFFSET mod64_32d_32a_rm110000
lreg64  DD OFFSET mod64_32d_64a_rm110000

        public mem_sib0_tab
        public long_mem_sib0_tab

        public sib_scale_tab
        public sib_index_tab
        public long_sib_index_tab

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
        public txt_64
        public b_txt
        public w_txt
        public d_txt
        public q_txt

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

        public rax_txt
        public rbx_txt
        public rcx_txt
        public rdx_txt
        public rsi_txt
        public rdi_txt
        public rsp_txt
        public rbp_txt

        public r8_txt
        public r9_txt
        public r10_txt
        public r11_txt
        public r12_txt
        public r13_txt
        public r14_txt
        public r15_txt

        public r8d_txt
        public r9d_txt
        public r10d_txt
        public r11d_txt
        public r12d_txt
        public r13d_txt
        public r14d_txt
        public r15d_txt

        public uscore_txt
        public noseg_txt

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
noseg_txt                       DB 0
txt_noth                        DB 0
uscore_txt                      DB '_',0
star1                           DB '*1',0
star2                           DB '*2',0
star4                           DB '*4',0
star8                           DB '*8',0
txt_16                          DB '16',0
txt_32                          DB '32',0
txt_64                          DB '64',0
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
eip_txt                         DB 'eip',0
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
invlpg_txt                      DB 'invlpg',0
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
q_txt                           DB 'q',0
qword_txt                       DB 'qword',0
qword_ptr_txt           DB 'qword ptr',0
r10_txt                         DB 'r10',0
r10d_txt                        DB 'r10d',0
r10l_txt                        DB 'r10l',0
r10w_txt                        DB 'r10w',0
r11_txt                         DB 'r11',0
r11d_txt                        DB 'r11d',0
r11l_txt                        DB 'r11l',0
r11w_txt                        DB 'r11w',0
r12_txt                         DB 'r12',0
r12d_txt                        DB 'r12d',0
r12l_txt                        DB 'r12l',0
r12w_txt                        DB 'r12w',0
r13_txt                         DB 'r13',0
r13d_txt                        DB 'r13d',0
r13l_txt                        DB 'r13l',0
r13w_txt                        DB 'r13w',0
r14_txt                         DB 'r14',0
r14d_txt                        DB 'r14d',0
r14l_txt                        DB 'r14l',0
r14w_txt                        DB 'r14w',0
r15_txt                         DB 'r15',0
r15d_txt                        DB 'r15d',0
r15l_txt                        DB 'r15l',0
r15w_txt                        DB 'r15w',0
r8_txt                          DB 'r8',0
r8d_txt                         DB 'r8d',0
r8l_txt                         DB 'r8l',0
r8w_txt                         DB 'r8w',0
r9_txt                          DB 'r9',0
r9d_txt                         DB 'r9d',0
r9l_txt                         DB 'r9l',0
r9w_txt                         DB 'r9w',0
rip_txt                         DB 'rip',0
rax_txt                         DB 'rax',0
rbp_txt                         DB 'rbp',0
rbx_txt                         DB 'rbx',0
rcx_txt                         DB 'rcx',0
rdi_txt                         DB 'rdi',0
rdx_txt                         DB 'rdx',0
rsi_txt                         DB 'rsi',0
rsp_txt                         DB 'rsp',0
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
syscall_txt                     DB 'syscall',0
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
        extrn long_mem_sib:near

        extrn override_rex:near
        extrn override_noseg:near
        extrn override_cs:near
        extrn override_ds:near
        extrn override_ss:near
        extrn override_es:near
        extrn override_fs:near
        extrn override_gs:near
        extrn op_rep:near

        extrn op_lodsb:near
        extrn op_lodsw:near
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
                        DD OFFSET op_math
                        DD OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_0 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsD9C9:
                        DD OFFSET op_math
                        DD OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsD9CA:
                        DD OFFSET op_math
                        DD OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_2 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsD9CB:
                        DD OFFSET op_math
                        DD OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_3 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsD9CC:
                        DD OFFSET op_math
                        DD OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_4 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsD9CD:
                        DD OFFSET op_math
                        DD OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_5 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsD9CE:
                        DD OFFSET op_math
                        DD OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_6 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsD9CF:
                        DD OFFSET op_math
                        DD OFFSET fxch_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_7 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh


opmsD9E0:
                        DD OFFSET op_math
                        DD OFFSET fchs_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9E1:
                        DD OFFSET op_math
                        DD OFFSET fabs_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9E2:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9E3:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9E4:
                        DD OFFSET op_math
                        DD OFFSET ftst_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9E5:
                        DD OFFSET op_math
                        DD OFFSET fxam_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9E6:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9E7:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opmsD9E8:
                        DD OFFSET op_math
                        DD OFFSET fld1_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9E9:
                        DD OFFSET op_math
                        DD OFFSET fldl2t_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9EA:
                        DD OFFSET op_math
                        DD OFFSET fldl2e_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9EB:
                        DD OFFSET op_math
                        DD OFFSET fldpi_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9EC:
                        DD OFFSET op_math
                        DD OFFSET fldlg2_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9ED:
                        DD OFFSET op_math
                        DD OFFSET fldln2_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9EE:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9EF:
                        DD OFFSET op_math
                        DD OFFSET fldz_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opmsD9F0:
                        DD OFFSET op_math
                        DD OFFSET f2xm1_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9F1:
                        DD OFFSET op_math
                        DD OFFSET fyl2x_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9F2:
                        DD OFFSET op_math
                        DD OFFSET fptan_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9F3:
                        DD OFFSET op_math
                        DD OFFSET fpatan_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9F4:
                        DD OFFSET op_math
                        DD OFFSET fxtract_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9F5:
                        DD OFFSET op_math
                        DD OFFSET fprem1_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9F6:
                        DD OFFSET op_math
                        DD OFFSET fdecstp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9F7:
                        DD OFFSET op_math
                        DD OFFSET fincstp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opmsD9F8:
                        DD OFFSET op_math
                        DD OFFSET fprem_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9F9:
                        DD OFFSET op_math
                        DD OFFSET fyl2xp1_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9FA:
                        DD OFFSET op_math
                        DD OFFSET fsqrt_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9FB:
                        DD OFFSET op_math
                        DD OFFSET fsincos_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9FC:
                        DD OFFSET op_math
                        DD OFFSET frndint_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9FD:
                        DD OFFSET op_math
                        DD OFFSET fscale_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9FE:
                        DD OFFSET op_math
                        DD OFFSET fsin_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsD9FF:
                        DD OFFSET op_math
                        DD OFFSET fcos_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opmsDBE0:
                        DD OFFSET op_math
                        DD OFFSET feni_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDBE1:
                        DD OFFSET op_math
                        DD OFFSET fdisi_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDBE2:
                        DD OFFSET op_math
                        DD OFFSET fclex_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDBE3:
                        DD OFFSET op_math
                        DD OFFSET finit_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDBE4:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDBE5:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDBE6:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDBE7:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opmsDAE8:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDAE9:
                        DD OFFSET op_math
                        DD OFFSET fucompp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDAEA:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDAEB:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDAEC:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDAED:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDAEE:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDAEF:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opmsDDC0:
                        DD OFFSET op_math
                        DD OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_0 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDC1:
                        DD OFFSET op_math
                        DD OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDC2:
                        DD OFFSET op_math
                        DD OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_2 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDC3:
                        DD OFFSET op_math
                        DD OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_3 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDC4:
                        DD OFFSET op_math
                        DD OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_4 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDC5:
                        DD OFFSET op_math
                        DD OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_5 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDC6:
                        DD OFFSET op_math
                        DD OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_6 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDC7:
                        DD OFFSET op_math
                        DD OFFSET ffree_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_7 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh


opmsDDE0:
                        DD OFFSET op_math
                        DD OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_0 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDE1:
                        DD OFFSET op_math
                        DD OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDE2:
                        DD OFFSET op_math
                        DD OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_2 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDE3:
                        DD OFFSET op_math
                        DD OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_3 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDE4:
                        DD OFFSET op_math
                        DD OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_4 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDE5:
                        DD OFFSET op_math
                        DD OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_5 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDE6:
                        DD OFFSET op_math
                        DD OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_6 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDE7:
                        DD OFFSET op_math
                        DD OFFSET fucom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_7 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh


opmsDDE8:
                        DD OFFSET op_math
                        DD OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_0 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDE9:
                        DD OFFSET op_math
                        DD OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDEA:
                        DD OFFSET op_math
                        DD OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_2 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDEB:
                        DD OFFSET op_math
                        DD OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_3 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDEC:
                        DD OFFSET op_math
                        DD OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_4 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDED:
                        DD OFFSET op_math
                        DD OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_5 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDEE:
                        DD OFFSET op_math
                        DD OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_6 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

opmsDDEF:
                        DD OFFSET op_math
                        DD OFFSET fucomp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET st_txt - OFFSET mne_tab + lpar_sep
                        DD OFFSET txt_7 - OFFSET mne_tab + rpar_sep
                        DD 0FFFFFFFFh

;
opmsDED8:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDED9:
                        DD OFFSET op_math
                        DD OFFSET fcompp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDEDA:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDEDB:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDEDC:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDEDD:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDEDE:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDEDF:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmsDFE0:
                        DD OFFSET op_math
                        DD OFFSET fstsw_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDFE1:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDFE2:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDFE3:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDFE4:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDFE5:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDFE6:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmsDFE7:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


;;;;;;;;;;;;;;;;;;;
; OP_MATH2_TAB
; MASKAD TILL 00FE
;;;;;;;;;;;;;;;;;;;

opmaD800:
                        DD OFFSET op_math
                        DD OFFSET fadd_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD840:
                        DD OFFSET op_math
                        DD OFFSET fadd_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD880:
                        DD OFFSET op_math
                        DD OFFSET fadd_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD8C0:
                        DD OFFSET op_math_reg
                        DD OFFSET fadd_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaD808:
                        DD OFFSET op_math
                        DD OFFSET fmul_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD848:
                        DD OFFSET op_math
                        DD OFFSET fmul_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD888:
                        DD OFFSET op_math
                        DD OFFSET fmul_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD8C8:
                        DD OFFSET op_math_reg
                        DD OFFSET fmul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaD810:
                        DD OFFSET op_math
                        DD OFFSET fcom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD850:
                        DD OFFSET op_math
                        DD OFFSET fcom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD890:
                        DD OFFSET op_math
                        DD OFFSET fcom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD8D0:
                        DD OFFSET op_math_reg
                        DD OFFSET fcom_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaD820:
                        DD OFFSET op_math
                        DD OFFSET fsub_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD860:
                        DD OFFSET op_math
                        DD OFFSET fsub_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD8A0:
                        DD OFFSET op_math
                        DD OFFSET fsub_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD8E0:
                        DD OFFSET op_math_reg
                        DD OFFSET fsub_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaD830:
                        DD OFFSET op_math
                        DD OFFSET fdiv_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD870:
                        DD OFFSET op_math
                        DD OFFSET fdiv_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD8B0:
                        DD OFFSET op_math
                        DD OFFSET fdiv_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD8F0:
                        DD OFFSET op_math_reg
                        DD OFFSET fdiv_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaD900:
                        DD OFFSET op_math
                        DD OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD940:
                        DD OFFSET op_math
                        DD OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD980:
                        DD OFFSET op_math
                        DD OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD9C0:
                        DD OFFSET op_math_reg
                        DD OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaD908:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD948:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD988:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD9C8:
                        DD OFFSET opmsD9C8
                        DD op_math_one_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaD910:
                        DD OFFSET op_math
                        DD OFFSET fst_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD950:
                        DD OFFSET op_math
                        DD OFFSET fst_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD990:
                        DD OFFSET op_math
                        DD OFFSET fst_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD9D0:
                        DD OFFSET op_math_reg
                        DD OFFSET fst_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaD918:
                        DD OFFSET op_math
                        DD OFFSET fstp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD958:
                        DD OFFSET op_math
                        DD OFFSET fstp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD998:
                        DD OFFSET op_math
                        DD OFFSET fstp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaD9D8:
                        DD OFFSET op_math_reg
                        DD OFFSET fstp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaD920:
                        DD OFFSET op_math
                        DD OFFSET fldenv_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD960:
                        DD OFFSET op_math
                        DD OFFSET fldenv_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD9A0:
                        DD OFFSET op_math
                        DD OFFSET fldenv_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD9E0:
                        DD OFFSET opmsD9E0
                        DD op_math_one_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaD928:
                        DD OFFSET op_math
                        DD OFFSET fldcw_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD968:
                        DD OFFSET op_math
                        DD OFFSET fldcw_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD9A8:
                        DD OFFSET op_math
                        DD OFFSET fldcw_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD9E8:
                        DD OFFSET opmsD9E8
                        DD op_math_one_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaD930:
                        DD OFFSET op_math
                        DD OFFSET fstenv_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD970:
                        DD OFFSET op_math
                        DD OFFSET fstenv_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD9B0:
                        DD OFFSET op_math
                        DD OFFSET fstenv_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD9F0:
                        DD OFFSET opmsD9F0
                        DD op_math_one_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaD938:
                        DD OFFSET op_math
                        DD OFFSET fstcw_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD978:
                        DD OFFSET op_math
                        DD OFFSET fstcw_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD9B8:
                        DD OFFSET op_math
                        DD OFFSET fstcw_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaD9F8:
                        DD OFFSET opmsD9F8
                        DD op_math_one_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaDB20:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaDB60:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaDBA0:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaDBE0:
                        DD OFFSET opmsDBE0
                        DD op_math_one_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaDA28:
                        DD OFFSET opmr_mem16
                        DD OFFSET fisubr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaDA68:
                        DD OFFSET opmr_mem16
                        DD OFFSET fisubr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaDAA8:
                        DD OFFSET opmr_mem16
                        DD OFFSET fisubr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaDAE8:
                        DD OFFSET opmsDAE8
                        DD op_math_one_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaDD00:
                        DD OFFSET opmr_mem16
                        DD OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaDD40:
                        DD OFFSET opmr_mem16
                        DD OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaDD80:
                        DD OFFSET opmr_mem16
                        DD OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaDDC0:
                        DD OFFSET opmsDDC0
                        DD op_math_one_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaDD20:
                        DD OFFSET opmr_mem16
                        DD OFFSET frstor_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaDD60:
                        DD OFFSET opmr_mem16
                        DD OFFSET frstor_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaDDA0:
                        DD OFFSET opmr_mem16
                        DD OFFSET frstor_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaDDE0:
                        DD OFFSET opmsDDE0
                        DD op_math_one_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaDD28:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaDD68:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaDDA8:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmaDDE8:
                        DD OFFSET opmsDDE8
                        DD op_math_one_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaDE18:
                        DD OFFSET opmr_mem16
                        DD OFFSET ficomp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaDE58:
                        DD OFFSET opmr_mem16
                        DD OFFSET ficomp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaDE98:
                        DD OFFSET opmr_mem16
                        DD OFFSET ficomp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaDED8:
                        DD OFFSET opmsDED8
                        DD op_math_one_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmaDF20:
                        DD OFFSET opmr_mem16
                        DD OFFSET fbld_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaDF60:
                        DD OFFSET opmr_mem16
                        DD OFFSET fbld_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaDFA0:
                        DD OFFSET opmr_mem16
                        DD OFFSET fbld_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmaDFE0:
                        DD OFFSET opmsDFE0
                        DD OFFSET fbld_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD op_math_one_tab + blank_sep
                        DD 0FFFFFFFFh


;;;;;;;;;;;;;;;;;;;;
; OP_MATH_REG_TAB
; MASKAD TILL 0038
;;;;;;;;;;;;;;;;;;;;

opmrD800:
                        DD OFFSET opmaD800
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD808:
                        DD OFFSET opmaD808
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD810:
                        DD OFFSET opmaD810
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD818:
                        DD OFFSET opmr_mem16
                        DD OFFSET fcomp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD820:
                        DD OFFSET opmaD820
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD828:
                        DD OFFSET opmr_mem16
                        DD OFFSET fsubr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrD830:
                        DD OFFSET opmaD830
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD838:
                        DD OFFSET opmr_mem16
                        DD OFFSET fdivr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

;
opmrD900:
                        DD OFFSET opmaD900
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD908:
                        DD OFFSET opmaD908
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD910:
                        DD OFFSET opmaD910
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD918:
                        DD OFFSET opmaD918
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD920:
                        DD OFFSET opmaD920
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD928:
                        DD OFFSET opmaD928
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD930:
                        DD OFFSET opmaD930
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD938:
                        DD OFFSET opmaD938
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmrDA00:
                        DD OFFSET opmr_mem16
                        DD OFFSET fiadd_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDA08:
                        DD OFFSET opmr_mem16
                        DD OFFSET fimul_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDA10:
                        DD OFFSET opmr_mem16
                        DD OFFSET ficom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDA18:
                        DD OFFSET opmr_mem16
                        DD OFFSET ficomp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDA20:
                        DD OFFSET opmr_mem16
                        DD OFFSET fisub_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDA28:
                        DD OFFSET opmaDA28
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrDA30:
                        DD OFFSET opmr_mem16
                        DD OFFSET fidiv_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDA38:
                        DD OFFSET opmr_mem16
                        DD OFFSET fidivr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

;
opmrDB00:
                        DD OFFSET opmr_mem16
                        DD OFFSET fild_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDB08:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrDB10:
                        DD OFFSET opmr_mem16
                        DD OFFSET fist_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDB18:
                        DD OFFSET opmr_mem16
                        DD OFFSET fistp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDB20:
                        DD OFFSET opmaDB20
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrDB28:
                        DD OFFSET opmr_mem16
                        DD OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDB30:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrDB38:
                        DD OFFSET opmr_mem16
                        DD OFFSET fstp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

;
opmrDC00:
                        DD OFFSET opmr_mem16
                        DD OFFSET fadd_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDC08:
                        DD OFFSET opmr_mem16
                        DD OFFSET fmul_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDC10:
                        DD OFFSET opmr_mem16
                        DD OFFSET fcom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDC18:
                        DD OFFSET opmr_mem16
                        DD OFFSET fcomp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDC20:
                        DD OFFSET opmr_mem16
                        DD OFFSET fsub_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDC28:
                        DD OFFSET opmr_mem16
                        DD OFFSET fsubr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDC30:
                        DD OFFSET opmr_mem16
                        DD OFFSET fdiv_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDC38:
                        DD OFFSET opmr_mem16
                        DD OFFSET fdivr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

;
opmrDD00:
                        DD OFFSET opmr_mem16
                        DD OFFSET fld_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDD08:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrDD10:
                        DD OFFSET opmr_mem16
                        DD OFFSET fst_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDD18:
                        DD OFFSET opmr_mem16
                        DD OFFSET fstp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDD20:
                        DD OFFSET opmaDD20
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrDD28:
                        DD OFFSET opmaDD28
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrDD30:
                        DD OFFSET opmr_mem16
                        DD OFFSET fsave_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrDD38:
                        DD OFFSET opmr_mem16
                        DD OFFSET fstsw_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmrDE00:
                        DD OFFSET opmr_mem16
                        DD OFFSET fiadd_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDE08:
                        DD OFFSET opmr_mem16
                        DD OFFSET fimul_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDE10:
                        DD OFFSET opmr_mem16
                        DD OFFSET ficom_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDE18:
                        DD OFFSET opmaDE18
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrDE20:
                        DD OFFSET opmr_mem16
                        DD OFFSET fisub_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDE28:
                        DD OFFSET opmr_mem16
                        DD OFFSET fisubr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDE30:
                        DD OFFSET opmr_mem16
                        DD OFFSET fidiv_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDE38:
                        DD OFFSET opmr_mem16
                        DD OFFSET fidivr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

;
opmrDF00:
                        DD OFFSET opmr_mem16
                        DD OFFSET fild_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDF08:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrDF10:
                        DD OFFSET opmr_mem16
                        DD OFFSET fist_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDF18:
                        DD OFFSET opmr_mem16
                        DD OFFSET fistp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDF20:
                        DD OFFSET opmaDF20
                        DD op_math2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrDF28:
                        DD OFFSET opmr_mem16
                        DD OFFSET fild_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDF30:
                        DD OFFSET opmr_mem16
                        DD OFFSET fbstp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET tbyte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrDF38:
                        DD OFFSET opmr_mem16
                        DD OFFSET fistp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET qword_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh



;;;;;;;;;;;;;;;;;;;;;
; OP_MEM_REG_TAB
; MASKAD TILL 0038
;;;;;;;;;;;;;;;;;;;;;

opmr6900:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6908:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6910:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6918:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6920:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6928:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6930:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6938:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmr6B00:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6B08:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6B10:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6B18:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6B20:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6B28:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6B30:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr6B38:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmr8000:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8008:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8010:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8018:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8020:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8028:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8030:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8038:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

;
opmr8100:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8108:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8110:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8118:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8120:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8128:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8130:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8138:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

;
opmr8200:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8208:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8210:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8218:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8220:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8228:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8230:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8238:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

;
opmr8300:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8308:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8310:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8318:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8320:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8328:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8330:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8338:
                        DD OFFSET opmr_mem_extend_im16
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

;
opmr8C00:
                        DD OFFSET opmr_mem16
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET es_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8C08:
                        DD OFFSET opmr_mem16
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cs_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8C10:
                        DD OFFSET opmr_mem16
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET ss_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8C18:
                        DD OFFSET opmr_mem16
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8C20:
                        DD OFFSET opmr_mem16
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET fs_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8C28:
                        DD OFFSET opmr_mem16
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET gs_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8C30:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr8C38:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmr8E00:
                        DD OFFSET opmr_mem16
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET es_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8E08:
                        DD OFFSET opmr_mem16
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET cs_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8E10:
                        DD OFFSET opmr_mem16
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ss_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8E18:
                        DD OFFSET opmr_mem16
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8E20:
                        DD OFFSET opmr_mem16
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET fs_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8E28:
                        DD OFFSET opmr_mem16
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET gs_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmr8E30:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr8E38:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmr8F00:
                        DD OFFSET opmr_mem16
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr8F08:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr8F10:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr8F18:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr8F20:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr8F28:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr8F30:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmr8F38:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmrC000:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET rol_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC008:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET ror_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC010:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET rcl_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC018:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET rcr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC020:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET shl_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC028:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET shr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC030:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC038:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET sar_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

;
opmrC100:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET rol_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC108:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET ror_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC110:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET rcl_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC118:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET rcr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC120:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET shl_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC128:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET shr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC130:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC138:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET sar_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

;
opmrC600:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET move_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC608:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC610:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC618:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC620:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC628:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC630:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC638:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmrC700:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET move_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrC708:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC710:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC718:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC720:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC728:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC730:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrC738:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmrD000:
                        DD OFFSET opmr_mem8
                        DD OFFSET rol_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD008:
                        DD OFFSET opmr_mem8
                        DD OFFSET ror_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD010:
                        DD OFFSET opmr_mem8
                        DD OFFSET rcl_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD018:
                        DD OFFSET opmr_mem8
                        DD OFFSET rcr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD020:
                        DD OFFSET opmr_mem8
                        DD OFFSET shl_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD028:
                        DD OFFSET opmr_mem8
                        DD OFFSET shr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD030:
                        DD OFFSET opmr_mem8
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD038:
                        DD OFFSET opmr_mem8
                        DD OFFSET sar_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

;
opmrD100:
                        DD OFFSET opmr_mem16
                        DD OFFSET rol_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD108:
                        DD OFFSET opmr_mem16
                        DD OFFSET ror_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD110:
                        DD OFFSET opmr_mem16
                        DD OFFSET rcl_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD118:
                        DD OFFSET opmr_mem16
                        DD OFFSET rcr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD120:
                        DD OFFSET opmr_mem16
                        DD OFFSET shl_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD128:
                        DD OFFSET opmr_mem16
                        DD OFFSET shr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

opmrD130:
                        DD OFFSET opmr_mem16
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD138:
                        DD OFFSET opmr_mem16
                        DD OFFSET sar_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET txt_1 - OFFSET mne_tab + blank_sep

;
opmrD200:
                        DD OFFSET opmr_mem8
                        DD OFFSET rol_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD208:
                        DD OFFSET opmr_mem8
                        DD OFFSET ror_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD210:
                        DD OFFSET opmr_mem8
                        DD OFFSET rcl_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD218:
                        DD OFFSET opmr_mem8
                        DD OFFSET rcr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD220:
                        DD OFFSET opmr_mem8
                        DD OFFSET shl_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD228:
                        DD OFFSET opmr_mem8
                        DD OFFSET shr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD230:
                        DD OFFSET opmr_mem8
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD238:
                        DD OFFSET opmr_mem8
                        DD OFFSET sar_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

;
opmrD300:
                        DD OFFSET opmr_mem16
                        DD OFFSET rol_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD308:
                        DD OFFSET opmr_mem16
                        DD OFFSET ror_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD310:
                        DD OFFSET opmr_mem16
                        DD OFFSET rcl_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD318:
                        DD OFFSET opmr_mem16
                        DD OFFSET rcr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD320:
                        DD OFFSET opmr_mem16
                        DD OFFSET shl_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD328:
                        DD OFFSET opmr_mem16
                        DD OFFSET shr_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

opmrD330:
                        DD OFFSET opmr_mem16
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrD338:
                        DD OFFSET opmr_mem16
                        DD OFFSET sar_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep

;
opmrF600:
                        DD OFFSET opmr_mem_im8
                        DD OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrF608:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrF610:
                        DD OFFSET opmr_mem8
                        DD OFFSET not_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrF618:
                        DD OFFSET opmr_mem8
                        DD OFFSET neg_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrF620:
                        DD OFFSET opmr_mem8
                        DD OFFSET mul_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrF628:
                        DD OFFSET opmr_mem8
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrF630:
                        DD OFFSET opmr_mem8
                        DD OFFSET div_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrF638:
                        DD OFFSET opmr_mem8
                        DD OFFSET idiv_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

;
opmrF700:
                        DD OFFSET opmr_mem_im16
                        DD OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrF708:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrF710:
                        DD OFFSET opmr_mem16
                        DD OFFSET not_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrF718:
                        DD OFFSET opmr_mem16
                        DD OFFSET neg_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrF720:
                        DD OFFSET opmr_mem16
                        DD OFFSET mul_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrF728:
                        DD OFFSET opmr_mem16
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrF730:
                        DD OFFSET opmr_mem16
                        DD OFFSET div_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrF738:
                        DD OFFSET opmr_mem16
                        DD OFFSET idiv_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

;
opmrFE00:
                        DD OFFSET opmr_mem8
                        DD OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrFE08:
                        DD OFFSET opmr_mem8
                        DD OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET byte_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrFE10:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrFE18:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrFE20:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrFE28:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrFE30:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrFE38:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;
opmrFF00:
                        DD OFFSET opmr_mem16
                        DD OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrFF08:
                        DD OFFSET opmr_mem16
                        DD OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET word_ptr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrFF10:
                        DD OFFSET opmr_mem16
                        DD OFFSET call_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET near_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrFF18:
                        DD OFFSET opmr_mem16
                        DD OFFSET call_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET far_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrFF20:
                        DD OFFSET opmr_mem16
                        DD OFFSET jmp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET near_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrFF28:
                        DD OFFSET opmr_mem16
                        DD OFFSET jmp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET far_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opmrFF30:
                        DD OFFSET opmr_mem16
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opmrFF38:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


;;;;;;;;;;;;;;;;;;;;;;
; OP_CDT_TAB
;;;;;;;;;;;;;;;;;;;;;;

opcdt0F2000:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F2040:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F2080:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F20C0:
                        DD OFFSET op_reg_cr
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opcdt0F2100:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F2140:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F2180:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F21C0:
                        DD OFFSET op_reg_dr
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opcdt0F2200:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F2240:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F2280:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F22C0:
                        DD OFFSET op_cr_reg
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opcdt0F2300:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F2340:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F2380:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F23C0:
                        DD OFFSET op_dr_reg
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opcdt0F2400:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F2440:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F2480:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F24C0:
                        DD OFFSET op_reg_tr
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opcdt0F2600:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F2640:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F2680:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opcdt0F26C0:
                        DD OFFSET op_tr_reg
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh



;;;;;;;;;;;;;;;;;;;;;;
; OP_PROT2_TAB
;;;;;;;;;;;;;;;;;;;;;;

opp0F0000:
                        DD OFFSET opmr_mem3
                        DD OFFSET sldt_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0008:
                        DD OFFSET opmr_mem3
                        DD OFFSET str_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0010:
                        DD OFFSET opmr_mem3
                        DD OFFSET lldt_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0018:
                        DD OFFSET opmr_mem3
                        DD OFFSET ltr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0020:
                        DD OFFSET opmr_mem3
                        DD OFFSET verr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0028:
                        DD OFFSET opmr_mem3
                        DD OFFSET verw_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0030:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0038:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opp0F0100:
                        DD OFFSET opmr_mem3
                        DD OFFSET sgdt_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0108:
                        DD OFFSET opmr_mem3
                        DD OFFSET sidt_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0110:
                        DD OFFSET opmr_mem3
                        DD OFFSET lgdt_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0118:
                        DD OFFSET opmr_mem3
                        DD OFFSET lidt_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0120:
                        DD OFFSET opmr_mem3
                        DD OFFSET lmsw_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0128:
                        DD OFFSET opmr_mem3
                        DD OFFSET smsw_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0130:
                        DD OFFSET opmr_mem3
                        DD OFFSET lmsw_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0F0138:
                        DD OFFSET opmr_mem3
                        DD OFFSET invlpg_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opp0FBA00:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0FBA08:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0FBA10:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0FBA18:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0FBA20:
                        DD OFFSET op_mem_byte3
                        DD OFFSET bt_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0FBA28:
                        DD OFFSET op_mem_byte3
                        DD OFFSET bts_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0FBA30:
                        DD OFFSET op_mem_byte3
                        DD OFFSET btr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opp0FBA38:
                        DD OFFSET op_mem_byte3
                        DD OFFSET btc_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


;;;;;;;;;;;;;;;;;;;;;;
; OP_PROTECT_TAB
;;;;;;;;;;;;;;;;;;;;;;

oppr0F00:
                        DD OFFSET opp0F0000
                        DD op_prot2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F01:
                        DD OFFSET opp0F0100
                        DD op_prot2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F02:
                        DD OFFSET op_reg_mem2_word
                        DD OFFSET lar_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F03:
                        DD OFFSET op_reg_mem2_word
                        DD OFFSET lsl_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F04:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F05:
                        DD OFFSET op_one
                        DD OFFSET syscall_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F06:
                        DD OFFSET op_one
                        DD OFFSET clts_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F07:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F08:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F09:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F0A:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F0B:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F0C:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F0D:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F0E:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F0F:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F10:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F11:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F12:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F13:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F14:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F15:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F16:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F17:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F18:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F19:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F1A:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F1B:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F1C:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F1D:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F1E:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F1F:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F20:
                        DD OFFSET opcdt0F2000
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD op_cdt_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F21:
                        DD OFFSET opcdt0F2100
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD op_cdt_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F22:
                        DD OFFSET opcdt0F2200
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD op_cdt_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F23:
                        DD OFFSET opcdt0F2300
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD op_cdt_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F24:
                        DD OFFSET opcdt0F2400
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD op_cdt_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F25:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F26:
                        DD OFFSET opcdt0F2600
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD op_cdt_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F27:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F28:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F29:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F2A:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F2B:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F2C:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F2D:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F2E:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F2F:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F30:
                        DD OFFSET op_one
                        DD OFFSET wrmsr_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F31:
                        DD OFFSET op_one
                        DD OFFSET rdtsc_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F32:
                        DD OFFSET op_one
                        DD OFFSET rdmsr_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F33:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F34:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F35:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F36:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F37:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F38:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F39:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F3A:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F3B:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F3C:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F3D:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F3E:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F3F:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F40:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F41:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F42:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F43:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F44:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F45:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F46:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F47:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F48:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F49:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F4A:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F4B:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F4C:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F4D:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F4E:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F4F:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F50:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F51:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F52:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F53:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F54:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F55:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F56:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F57:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F58:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F59:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F5A:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F5B:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F5C:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F5D:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F5E:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F5F:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F60:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F61:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F62:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F63:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F64:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F65:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F66:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F67:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F68:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F69:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F6A:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F6B:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F6C:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F6D:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F6E:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F6F:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F70:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F71:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F72:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F73:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F74:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F75:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F76:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F77:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F78:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F79:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F7A:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F7B:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F7C:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F7D:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F7E:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F7F:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F80:
                        DD OFFSET op_near2
                        DD OFFSET jo_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F81:
                        DD OFFSET op_near2
                        DD OFFSET jno_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F82:
                        DD OFFSET op_near2
                        DD OFFSET jb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F83:
                        DD OFFSET op_near2
                        DD OFFSET jnb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F84:
                        DD OFFSET op_near2
                        DD OFFSET jz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F85:
                        DD OFFSET op_near2
                        DD OFFSET jnz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F86:
                        DD OFFSET op_near2
                        DD OFFSET jbe_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F87:
                        DD OFFSET op_near2
                        DD OFFSET ja_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F88:
                        DD OFFSET op_near2
                        DD OFFSET js_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F89:
                        DD OFFSET op_near2
                        DD OFFSET jns_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F8A:
                        DD OFFSET op_near2
                        DD OFFSET jpe_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F8B:
                        DD OFFSET op_near2
                        DD OFFSET jpo_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F8C:
                        DD OFFSET op_near2
                        DD OFFSET jl_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F8D:
                        DD OFFSET op_near2
                        DD OFFSET jge_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F8E:
                        DD OFFSET op_near2
                        DD OFFSET jle_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F8F:
                        DD OFFSET op_near2
                        DD OFFSET jg_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F90:
                        DD OFFSET opmr_mem2
                        DD OFFSET seto_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F91:
                        DD OFFSET opmr_mem2
                        DD OFFSET setno_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F92:
                        DD OFFSET opmr_mem2
                        DD OFFSET setb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F93:
                        DD OFFSET opmr_mem2
                        DD OFFSET setnb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F94:
                        DD OFFSET opmr_mem2
                        DD OFFSET setz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F95:
                        DD OFFSET opmr_mem2
                        DD OFFSET setnz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F96:
                        DD OFFSET opmr_mem2
                        DD OFFSET setbe_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F97:
                        DD OFFSET opmr_mem2
                        DD OFFSET seta_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F98:
                        DD OFFSET opmr_mem2
                        DD OFFSET sets_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F99:
                        DD OFFSET opmr_mem2
                        DD OFFSET setns_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F9A:
                        DD OFFSET opmr_mem2
                        DD OFFSET setpe_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F9B:
                        DD OFFSET opmr_mem2
                        DD OFFSET setpo_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F9C:
                        DD OFFSET opmr_mem2
                        DD OFFSET setl_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F9D:
                        DD OFFSET opmr_mem2
                        DD OFFSET setge_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F9E:
                        DD OFFSET opmr_mem2
                        DD OFFSET setle_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0F9F:
                        DD OFFSET opmr_mem2
                        DD OFFSET setg_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FA0:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET fs_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FA1:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET fs_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FA2:
                        DD OFFSET op_one
                        DD OFFSET cpuid_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FA3:
                        DD OFFSET op_mem_reg2
                        DD OFFSET bt_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FA4:
                        DD OFFSET op_reg_mem_byte2
                        DD OFFSET shld_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FA5:
                        DD OFFSET op_reg_mem2_word
                        DD OFFSET shld_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

oppr0FA6:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FA7:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FA8:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET gs_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FA9:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET gs_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FAA:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FAB:
                        DD OFFSET op_mem_reg2
                        DD OFFSET bts_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FAC:
                        DD OFFSET op_reg_mem_byte2
                        DD OFFSET shrd_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FAD:
                        DD OFFSET op_reg_mem2_word
                        DD OFFSET shrd_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

oppr0FAE:
                        DD OFFSET op_reg_mem2_byte
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FAF:
                        DD OFFSET op_reg_mem2_word
                        DD OFFSET imul_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FB0:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FB1:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FB2:
                        DD OFFSET op_reg_mem2_word
                        DD OFFSET lss_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FB3:
                        DD OFFSET op_mem_reg2
                        DD OFFSET btr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FB4:
                        DD OFFSET op_reg_mem2_word
                        DD OFFSET lfs_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FB5:
                        DD OFFSET op_reg_mem2_word
                        DD OFFSET lgs_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FB6:
                        DD OFFSET op_reg_mem2_byte
                        DD OFFSET movzx_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FB7:
                        DD OFFSET op_reg_mem2_word
                        DD OFFSET movzx_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FB8:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FB9:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FBA:
                        DD OFFSET opp0FBA00
                        DD op_prot2_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FBB:
                        DD OFFSET op_mem_reg2
                        DD OFFSET btc_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FBC:
                        DD OFFSET op_mem_reg2
                        DD OFFSET bsf_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FBD:
                        DD OFFSET op_mem_reg2
                        DD OFFSET bsr_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FBE:
                        DD OFFSET op_reg_mem2_byte
                        DD OFFSET movsx_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FBF:
                        DD OFFSET op_reg_mem2_word
                        DD OFFSET movsx_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FC0:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FC1:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FC2:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FC3:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FC4:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FC5:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FC6:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FC7:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FC8:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FC9:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FCA:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FCB:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FCC:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FCD:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FCE:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FCF:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FD0:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FD1:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FD2:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FD3:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FD4:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FD5:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FD6:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FD7:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FD8:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FD9:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FDA:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FDB:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FDC:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FDD:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FDE:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FDF:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FE0:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FE1:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FE2:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FE3:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FE4:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FE5:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FE6:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FE7:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FE8:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FE9:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FEA:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FEB:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FEC:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FED:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FEE:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FEF:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FF0:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FF1:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FF2:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FF3:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FF4:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FF5:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FF6:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FF7:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FF8:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FF9:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FFA:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FFB:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FFC:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FFD:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FFE:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

oppr0FFF:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh




;;;;;;;;;;;;;;;;;;;;;;
; MAIN_OP_TAB
;;;;;;;;;;;;;;;;;;;;;;

        public main_tab

main_tab:

op00:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op01:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op02:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op03:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op04:
                        DD OFFSET op_byte
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op05:
                        DD OFFSET op_word
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op06:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET es_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op07:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET es_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op08:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op09:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op0A:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op0B:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op0C:
                        DD OFFSET op_byte
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op0D:
                        DD OFFSET op_word
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op0E:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET cs_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op0F:
                        DD OFFSET oppr0F00
                        DD op_protect_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op10:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op11:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op12:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op13:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op14:
                        DD OFFSET op_byte
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op15:
                        DD OFFSET op_word
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op16:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ss_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op17:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ss_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op18:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op19:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op1A:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op1B:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op1C:
                        DD OFFSET op_byte
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op1D:
                        DD OFFSET op_word
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op1E:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op1F:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op20:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op21:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op22:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op23:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op24:
                        DD OFFSET op_byte
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op25:
                        DD OFFSET op_word
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op26:
                        DD OFFSET override_es
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op27:
                        DD OFFSET op_one
                        DD OFFSET daa_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op28:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op29:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op2A:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op2B:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op2C:
                        DD OFFSET op_byte
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op2D:
                        DD OFFSET op_word
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op2E:
                        DD OFFSET override_cs
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op2F:
                        DD OFFSET op_one
                        DD OFFSET das_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op30:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op31:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op32:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op33:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op34:
                        DD OFFSET op_byte
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op35:
                        DD OFFSET op_word
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op36:
                        DD OFFSET override_ss
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op37:
                        DD OFFSET op_one
                        DD OFFSET aaa_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op38:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op39:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op3A:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op3B:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op3C:
                        DD OFFSET op_byte
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op3D:
                        DD OFFSET op_word
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

op3E:
                        DD OFFSET override_ds
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op3F:
                        DD OFFSET op_one
                        DD OFFSET aas_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op40:
                        DD OFFSET op_one
                        DD OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op41:
                        DD OFFSET op_one
                        DD OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DD cx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op42:
                        DD OFFSET op_one
                        DD OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DD dx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op43:
                        DD OFFSET op_one
                        DD OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DD bx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op44:
                        DD OFFSET op_one
                        DD OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DD sp_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op45:
                        DD OFFSET op_one
                        DD OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DD bp_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op46:
                        DD OFFSET op_one
                        DD OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DD si_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op47:
                        DD OFFSET op_one
                        DD OFFSET inc_txt - OFFSET mne_tab + blank_sep
                        DD di_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op48:
                        DD OFFSET op_one
                        DD OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op49:
                        DD OFFSET op_one
                        DD OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DD cx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op4A:
                        DD OFFSET op_one
                        DD OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DD dx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op4B:
                        DD OFFSET op_one
                        DD OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DD bx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op4C:
                        DD OFFSET op_one
                        DD OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DD sp_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op4D:
                        DD OFFSET op_one
                        DD OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DD bp_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op4E:
                        DD OFFSET op_one
                        DD OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DD si_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op4F:
                        DD OFFSET op_one
                        DD OFFSET dec_txt - OFFSET mne_tab + blank_sep
                        DD di_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op50:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op51:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD cx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op52:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD dx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op53:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD bx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op54:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD sp_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op55:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD bp_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op56:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD si_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op57:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD di_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op58:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op59:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD cx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op5A:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD dx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op5B:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD bx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op5C:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD sp_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op5D:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD bp_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op5E:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD si_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op5F:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD di_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op60:
                        DD OFFSET op_one
                        DD OFFSET pusha_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op61:
                        DD OFFSET op_one
                        DD OFFSET popa_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op62:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET bound_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op63:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET arpl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op64:
                        DD OFFSET override_fs
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op65:
                        DD OFFSET override_gs
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op66:
                        DD OFFSET op_data_size
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op67:
                        DD OFFSET op_address_size
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op68:
                        DD OFFSET op_word
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op69:
                        DD OFFSET opmr6900
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op6A:
                        DD OFFSET op_byte
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op6B:
                        DD OFFSET opmr6B00
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op6C:
                        DD OFFSET op_string1b
                        DD OFFSET ins_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op6D:
                        DD OFFSET op_string1w
                        DD OFFSET ins_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op6E:
                        DD OFFSET op_string1b
                        DD OFFSET outs_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op6F:
                        DD OFFSET op_string1w
                        DD OFFSET outs_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op70:
                        DD OFFSET op_short
                        DD OFFSET jo_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op71:
                        DD OFFSET op_short
                        DD OFFSET jno_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op72:
                        DD OFFSET op_short
                        DD OFFSET jb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op73:
                        DD OFFSET op_short
                        DD OFFSET jnb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op74:
                        DD OFFSET op_short
                        DD OFFSET jz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op75:
                        DD OFFSET op_short
                        DD OFFSET jnz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op76:
                        DD OFFSET op_short
                        DD OFFSET jbe_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op77:
                        DD OFFSET op_short
                        DD OFFSET ja_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op78:
                        DD OFFSET op_short
                        DD OFFSET js_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op79:
                        DD OFFSET op_short
                        DD OFFSET jns_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op7A:
                        DD OFFSET op_short
                        DD OFFSET jpe_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op7B:
                        DD OFFSET op_short
                        DD OFFSET jpo_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op7C:
                        DD OFFSET op_short
                        DD OFFSET jl_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op7D:
                        DD OFFSET op_short
                        DD OFFSET jge_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op7E:
                        DD OFFSET op_short
                        DD OFFSET jle_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op7F:
                        DD OFFSET op_short
                        DD OFFSET jg_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op80:
                        DD OFFSET opmr8000
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op81:
                        DD OFFSET opmr8100
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op82:
                        DD OFFSET opmr8200
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op83:
                        DD OFFSET opmr8300
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op84:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op85:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op86:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op87:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op88:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op89:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op8A:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op8B:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op8C:
                        DD OFFSET opmr8C00
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op8D:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET lea_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op8E:
                        DD OFFSET opmr8E00
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op8F:
                        DD OFFSET opmr8F00
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op90:
                        DD OFFSET op_one
                        DD OFFSET nop_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op91:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD cx_tab + blank_sep
                        DD 0FFFFFFFFh

op92:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD dx_tab + blank_sep
                        DD 0FFFFFFFFh

op93:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD bx_tab + blank_sep
                        DD 0FFFFFFFFh

op94:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD sp_tab + blank_sep
                        DD 0FFFFFFFFh

op95:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD bp_tab + blank_sep
                        DD 0FFFFFFFFh

op96:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD si_tab + blank_sep
                        DD 0FFFFFFFFh

op97:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD di_tab + blank_sep
                        DD 0FFFFFFFFh

op98:
                        DD OFFSET op_one
                        DD OFFSET cbw_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op99:
                        DD OFFSET op_one
                        DD OFFSET cwd_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op9A:
                        DD OFFSET op_far
                        DD OFFSET call_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


op9B:
                        DD OFFSET op_wait
                        DD OFFSET wait_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op9C:
                        DD OFFSET op_one
                        DD OFFSET pushf_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op9D:
                        DD OFFSET op_one
                        DD OFFSET popf_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op9E:
                        DD OFFSET op_one
                        DD OFFSET sahf_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

op9F:
                        DD OFFSET op_one
                        DD OFFSET lahf_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opA0:
                        DD OFFSET op_word_mem
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + rhak_sep

opA1:
                        DD OFFSET op_word_mem
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ax_txt - OFFSET mne_tab + komma_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + rhak_sep

opA2:
                        DD OFFSET op_word_mem
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + par_komma_sep
                        DD OFFSET al_txt - OFFSET mne_tab + blank_sep

opA3:
                        DD OFFSET op_word_mem
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + par_komma_sep
                        DD OFFSET ax_txt - OFFSET mne_tab + blank_sep

opA4:
                        DD OFFSET op_string2b
                        DD OFFSET movs_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opA5:
                        DD OFFSET op_string2w
                        DD OFFSET movs_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opA6:
                        DD OFFSET op_string2b
                        DD OFFSET cmps_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opA7:
                        DD OFFSET op_string2w
                        DD OFFSET cmps_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opA8:
                        DD OFFSET op_byte
                        DD OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opA9:
                        DD OFFSET op_word
                        DD OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opAA:
                        DD OFFSET op_string1b
                        DD OFFSET stos_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opAB:
                        DD OFFSET op_string1w
                        DD OFFSET stos_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opAC:
                        DD OFFSET op_lodsb
                        DD OFFSET lods_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opAD:
                        DD OFFSET op_lodsw
                        DD OFFSET lods_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opAE:
                        DD OFFSET op_string1b
                        DD OFFSET scas_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opAF:
                        DD OFFSET op_string1w
                        DD OFFSET scas_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opB0:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opB1:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opB2:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dl_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opB3:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET bl_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opB4:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ah_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opB5:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ch_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opB6:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dh_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opB7:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET bh_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opB8:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opB9:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD cx_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opBA:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD dx_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opBB:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD bx_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opBC:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD sp_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opBD:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD bp_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opBE:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD si_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opBF:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD di_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opC0:
                        DD OFFSET opmrC000
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opC1:
                        DD OFFSET opmrC100
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opC2:
                        DD OFFSET op_word16
                        DD OFFSET retn_txt - OFFSET mne_tab + no_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opC3:
                        DD OFFSET op_add_opsize
                        DD OFFSET retn_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opC4:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET les_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opC5:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET lds_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opC6:
                        DD OFFSET opmrC600
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opC7:
                        DD OFFSET opmrC700
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opC8:
                        DD OFFSET op_enter
                        DD OFFSET enter_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opC9:
                        DD OFFSET op_one
                        DD OFFSET leave_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opCA:
                        DD OFFSET op_word16
                        DD OFFSET retf_txt - OFFSET mne_tab + no_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opCB:
                        DD OFFSET op_add_opsize
                        DD OFFSET retf_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opCC:
                        DD OFFSET op_one
                        DD OFFSET int_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET txt_3 - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opCD:
                        DD OFFSET op_byte
                        DD OFFSET int_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opCE:
                        DD OFFSET op_one
                        DD OFFSET into_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opCF:
                        DD OFFSET op_add_opsize
                        DD OFFSET iret_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opD0:
                        DD OFFSET opmrD000
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opD1:
                        DD OFFSET opmrD100
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opD2:
                        DD OFFSET opmrD200
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opD3:
                        DD OFFSET opmrD300
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opD4:
                        DD OFFSET op_byte
                        DD OFFSET aam_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opD5:
                        DD OFFSET op_byte
                        DD OFFSET aad_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opD6:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opD7:
                        DD OFFSET op_one
                        DD OFFSET xlat_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opD8:
                        DD OFFSET opmrD800
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opD9:
                        DD OFFSET opmrD900
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opDA:
                        DD OFFSET opmrDA00
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opDB:
                        DD OFFSET opmrDB00
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opDC:
                        DD OFFSET opmrDC00
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opDD:
                        DD OFFSET opmrDD00
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opDE:
                        DD OFFSET opmrDE00
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opDF:
                        DD OFFSET opmrDF00
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opE0:
                        DD OFFSET op_short
                        DD OFFSET loopnz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opE1:
                        DD OFFSET op_short
                        DD OFFSET loopz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opE2:
                        DD OFFSET op_short
                        DD OFFSET loop_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opE3:
                        DD OFFSET op_short
                        DD OFFSET jcxz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opE4:
                        DD OFFSET op_byte
                        DD OFFSET in_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opE5:
                        DD OFFSET op_byte
                        DD OFFSET in_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

opE6:
                        DD OFFSET op_byte
                        DD OFFSET out_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET al_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

opE7:
                        DD OFFSET op_byte
                        DD OFFSET out_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD ax_tab + blank_sep
                        DD 0FFFFFFFFh

opE8:
                        DD OFFSET op_near
                        DD OFFSET call_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opE9:
                        DD OFFSET op_near
                        DD OFFSET jmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opEA:
                        DD OFFSET op_far
                        DD OFFSET jmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opEB:
                        DD OFFSET op_short
                        DD OFFSET jmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


opEC:
                        DD OFFSET op_one
                        DD OFFSET in_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD OFFSET dx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

opED:
                        DD OFFSET op_one
                        DD OFFSET in_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD OFFSET dx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

opEE:
                        DD OFFSET op_one
                        DD OFFSET out_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dx_txt - OFFSET mne_tab + komma_sep
                        DD OFFSET al_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

opEF:
                        DD OFFSET op_one
                        DD OFFSET out_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dx_txt - OFFSET mne_tab + komma_sep
                        DD ax_tab + blank_sep
                        DD 0FFFFFFFFh

opF0:
                        DD OFFSET op_rep
                        DD OFFSET lock_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opF1:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opF2:
                        DD OFFSET op_rep
                        DD OFFSET repnz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opF3:
                        DD OFFSET op_rep
                        DD OFFSET repz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opF4:
                        DD OFFSET op_one
                        DD OFFSET hlt_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opF5:
                        DD OFFSET op_one
                        DD OFFSET cmc_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opF6:
                        DD OFFSET opmrF600
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opF7:
                        DD OFFSET opmrF700
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opF8:
                        DD OFFSET op_one
                        DD OFFSET clc_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opF9:
                        DD OFFSET op_one
                        DD OFFSET stc_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opFA:
                        DD OFFSET op_one
                        DD OFFSET cli_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opFB:
                        DD OFFSET op_one
                        DD OFFSET sti_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opFC:
                        DD OFFSET op_one
                        DD OFFSET cld_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opFD:
                        DD OFFSET op_one
                        DD OFFSET std_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opFE:
                        DD OFFSET opmrFE00
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

opFF:
                        DD OFFSET opmrFF00
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

;;;;;;;;;;;;;;;;;;;;;;
; LONG MAIN_OP_TAB
;;;;;;;;;;;;;;;;;;;;;;

        public long_main_tab

long_main_tab:

lop00:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop01:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop02:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop03:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop04:
                        DD OFFSET op_byte
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop05:
                        DD OFFSET op_word
                        DD OFFSET add_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop06:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET es_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop07:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET es_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop08:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop09:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop0A:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop0B:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop0C:
                        DD OFFSET op_byte
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop0D:
                        DD OFFSET op_word
                        DD OFFSET or_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop0E:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET cs_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop0F:
                        DD OFFSET oppr0F00
                        DD op_protect_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop10:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop11:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop12:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop13:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop14:
                        DD OFFSET op_byte
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop15:
                        DD OFFSET op_word
                        DD OFFSET adc_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop16:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ss_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop17:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ss_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop18:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop19:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop1A:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop1B:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop1C:
                        DD OFFSET op_byte
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop1D:
                        DD OFFSET op_word
                        DD OFFSET sbb_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop1E:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop1F:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop20:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop21:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop22:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop23:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop24:
                        DD OFFSET op_byte
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop25:
                        DD OFFSET op_word
                        DD OFFSET and_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop26:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop27:
                        DD OFFSET op_one
                        DD OFFSET daa_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop28:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop29:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop2A:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop2B:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop2C:
                        DD OFFSET op_byte
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop2D:
                        DD OFFSET op_word
                        DD OFFSET sub_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop2E:
                        DD OFFSET override_noseg
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop2F:
                        DD OFFSET op_one
                        DD OFFSET das_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop30:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop31:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop32:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop33:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop34:
                        DD OFFSET op_byte
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop35:
                        DD OFFSET op_word
                        DD OFFSET xor_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop36:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop37:
                        DD OFFSET op_one
                        DD OFFSET aaa_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop38:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop39:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop3A:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop3B:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop3C:
                        DD OFFSET op_byte
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop3D:
                        DD OFFSET op_word
                        DD OFFSET cmp_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lop3E:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop3F:
                        DD OFFSET op_one
                        DD OFFSET aas_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop40:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop41:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop42:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop43:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop44:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop45:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop46:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop47:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop48:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop49:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop4A:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop4B:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop4C:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop4D:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop4E:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop4F:
                        DD OFFSET override_rex
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop50:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop51:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD cx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop52:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD dx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop53:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD bx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop54:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD sp_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop55:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD bp_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop56:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD si_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop57:
                        DD OFFSET op_one
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD di_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop58:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop59:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD cx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop5A:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD dx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop5B:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD bx_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop5C:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD sp_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop5D:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD bp_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop5E:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD si_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop5F:
                        DD OFFSET op_one
                        DD OFFSET pop_txt - OFFSET mne_tab + blank_sep
                        DD di_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop60:
                        DD OFFSET op_one
                        DD OFFSET pusha_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop61:
                        DD OFFSET op_one
                        DD OFFSET popa_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop62:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET bound_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop63:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET arpl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop64:
                        DD OFFSET override_fs
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop65:
                        DD OFFSET override_gs
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop66:
                        DD OFFSET op_data_size
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop67:
                        DD OFFSET op_address_size
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop68:
                        DD OFFSET op_word
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop69:
                        DD OFFSET opmr6900
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop6A:
                        DD OFFSET op_byte
                        DD OFFSET push_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop6B:
                        DD OFFSET opmr6B00
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop6C:
                        DD OFFSET op_string1b
                        DD OFFSET ins_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop6D:
                        DD OFFSET op_string1w
                        DD OFFSET ins_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop6E:
                        DD OFFSET op_string1b
                        DD OFFSET outs_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop6F:
                        DD OFFSET op_string1w
                        DD OFFSET outs_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop70:
                        DD OFFSET op_short
                        DD OFFSET jo_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop71:
                        DD OFFSET op_short
                        DD OFFSET jno_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop72:
                        DD OFFSET op_short
                        DD OFFSET jb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop73:
                        DD OFFSET op_short
                        DD OFFSET jnb_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop74:
                        DD OFFSET op_short
                        DD OFFSET jz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop75:
                        DD OFFSET op_short
                        DD OFFSET jnz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop76:
                        DD OFFSET op_short
                        DD OFFSET jbe_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop77:
                        DD OFFSET op_short
                        DD OFFSET ja_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop78:
                        DD OFFSET op_short
                        DD OFFSET js_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop79:
                        DD OFFSET op_short
                        DD OFFSET jns_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop7A:
                        DD OFFSET op_short
                        DD OFFSET jpe_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop7B:
                        DD OFFSET op_short
                        DD OFFSET jpo_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop7C:
                        DD OFFSET op_short
                        DD OFFSET jl_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop7D:
                        DD OFFSET op_short
                        DD OFFSET jge_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop7E:
                        DD OFFSET op_short
                        DD OFFSET jle_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop7F:
                        DD OFFSET op_short
                        DD OFFSET jg_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop80:
                        DD OFFSET opmr8000
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop81:
                        DD OFFSET opmr8100
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop82:
                        DD OFFSET opmr8200
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop83:
                        DD OFFSET opmr8300
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop84:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop85:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop86:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop87:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop88:
                        DD OFFSET op_mem_reg_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop89:
                        DD OFFSET op_mem_reg_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop8A:
                        DD OFFSET op_reg_mem_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop8B:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop8C:
                        DD OFFSET opmr8C00
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop8D:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET lea_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop8E:
                        DD OFFSET opmr8E00
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop8F:
                        DD OFFSET opmr8F00
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop90:
                        DD OFFSET op_one
                        DD OFFSET nop_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop91:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD cx_tab + blank_sep
                        DD 0FFFFFFFFh

lop92:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD dx_tab + blank_sep
                        DD 0FFFFFFFFh

lop93:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD bx_tab + blank_sep
                        DD 0FFFFFFFFh

lop94:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD sp_tab + blank_sep
                        DD 0FFFFFFFFh

lop95:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD bp_tab + blank_sep
                        DD 0FFFFFFFFh

lop96:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD si_tab + blank_sep
                        DD 0FFFFFFFFh

lop97:
                        DD OFFSET op_one
                        DD OFFSET xchg_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD di_tab + blank_sep
                        DD 0FFFFFFFFh

lop98:
                        DD OFFSET op_one
                        DD OFFSET cbw_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop99:
                        DD OFFSET op_one
                        DD OFFSET cwd_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop9A:
                        DD OFFSET op_far
                        DD OFFSET call_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lop9B:
                        DD OFFSET op_wait
                        DD OFFSET wait_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop9C:
                        DD OFFSET op_one
                        DD OFFSET pushf_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop9D:
                        DD OFFSET op_one
                        DD OFFSET popf_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop9E:
                        DD OFFSET op_one
                        DD OFFSET sahf_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lop9F:
                        DD OFFSET op_one
                        DD OFFSET lahf_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopA0:
                        DD OFFSET op_word_mem
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + rhak_sep

lopA1:
                        DD OFFSET op_word_mem
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ax_txt - OFFSET mne_tab + komma_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + rhak_sep

lopA2:
                        DD OFFSET op_word_mem
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + par_komma_sep
                        DD OFFSET al_txt - OFFSET mne_tab + blank_sep

lopA3:
                        DD OFFSET op_word_mem
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + par_komma_sep
                        DD OFFSET ax_txt - OFFSET mne_tab + blank_sep

lopA4:
                        DD OFFSET op_string2b
                        DD OFFSET movs_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopA5:
                        DD OFFSET op_string2w
                        DD OFFSET movs_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopA6:
                        DD OFFSET op_string2b
                        DD OFFSET cmps_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopA7:
                        DD OFFSET op_string2w
                        DD OFFSET cmps_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopA8:
                        DD OFFSET op_byte
                        DD OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopA9:
                        DD OFFSET op_word
                        DD OFFSET test_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopAA:
                        DD OFFSET op_string1b
                        DD OFFSET stos_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopAB:
                        DD OFFSET op_string1w
                        DD OFFSET stos_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopAC:
                        DD OFFSET op_lodsb
                        DD OFFSET lods_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopAD:
                        DD OFFSET op_lodsw
                        DD OFFSET lods_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopAE:
                        DD OFFSET op_string1b
                        DD OFFSET scas_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopAF:
                        DD OFFSET op_string1w
                        DD OFFSET scas_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopB0:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopB1:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET cl_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopB2:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dl_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopB3:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET bl_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopB4:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ah_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopB5:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET ch_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopB6:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dh_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopB7:
                        DD OFFSET op_byte
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET bh_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopB8:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopB9:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD cx_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopBA:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD dx_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopBB:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD bx_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopBC:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD sp_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopBD:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD bp_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopBE:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD si_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopBF:
                        DD OFFSET op_word
                        DD OFFSET mov_txt - OFFSET mne_tab + blank_sep
                        DD di_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopC0:
                        DD OFFSET opmrC000
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopC1:
                        DD OFFSET opmrC100
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopC2:
                        DD OFFSET op_word16
                        DD OFFSET retn_txt - OFFSET mne_tab + no_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopC3:
                        DD OFFSET op_add_opsize
                        DD OFFSET retn_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopC4:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET les_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopC5:
                        DD OFFSET op_reg_mem_word
                        DD OFFSET lds_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopC6:
                        DD OFFSET opmrC600
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopC7:
                        DD OFFSET opmrC700
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopC8:
                        DD OFFSET op_enter
                        DD OFFSET enter_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lopC9:
                        DD OFFSET op_one
                        DD OFFSET leave_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopCA:
                        DD OFFSET op_word16
                        DD OFFSET retf_txt - OFFSET mne_tab + no_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopCB:
                        DD OFFSET op_add_opsize
                        DD OFFSET retf_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopCC:
                        DD OFFSET op_one
                        DD OFFSET int_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET txt_3 - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopCD:
                        DD OFFSET op_byte
                        DD OFFSET int_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopCE:
                        DD OFFSET op_one
                        DD OFFSET into_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopCF:
                        DD OFFSET op_add_opsize
                        DD OFFSET iret_txt - OFFSET mne_tab + no_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopD0:
                        DD OFFSET opmrD000
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopD1:
                        DD OFFSET opmrD100
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopD2:
                        DD OFFSET opmrD200
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopD3:
                        DD OFFSET opmrD300
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopD4:
                        DD OFFSET op_byte
                        DD OFFSET aam_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopD5:
                        DD OFFSET op_byte
                        DD OFFSET aad_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopD6:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopD7:
                        DD OFFSET op_one
                        DD OFFSET xlat_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopD8:
                        DD OFFSET opmrD800
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopD9:
                        DD OFFSET opmrD900
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopDA:
                        DD OFFSET opmrDA00
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopDB:
                        DD OFFSET opmrDB00
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopDC:
                        DD OFFSET opmrDC00
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopDD:
                        DD OFFSET opmrDD00
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopDE:
                        DD OFFSET opmrDE00
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopDF:
                        DD OFFSET opmrDF00
                        DD op_math_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopE0:
                        DD OFFSET op_short
                        DD OFFSET loopnz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lopE1:
                        DD OFFSET op_short
                        DD OFFSET loopz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lopE2:
                        DD OFFSET op_short
                        DD OFFSET loop_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lopE3:
                        DD OFFSET op_short
                        DD OFFSET jcxz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lopE4:
                        DD OFFSET op_byte
                        DD OFFSET in_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopE5:
                        DD OFFSET op_byte
                        DD OFFSET in_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh

lopE6:
                        DD OFFSET op_byte
                        DD OFFSET out_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD OFFSET al_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

lopE7:
                        DD OFFSET op_byte
                        DD OFFSET out_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + komma_sep
                        DD ax_tab + blank_sep
                        DD 0FFFFFFFFh

lopE8:
                        DD OFFSET op_near
                        DD OFFSET call_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopE9:
                        DD OFFSET op_near
                        DD OFFSET jmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopEA:
                        DD OFFSET op_far
                        DD OFFSET jmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lopEB:
                        DD OFFSET op_short
                        DD OFFSET jmp_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


lopEC:
                        DD OFFSET op_one
                        DD OFFSET in_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET al_txt - OFFSET mne_tab + komma_sep
                        DD OFFSET dx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

lopED:
                        DD OFFSET op_one
                        DD OFFSET in_txt - OFFSET mne_tab + blank_sep
                        DD ax_tab + komma_sep
                        DD OFFSET dx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

lopEE:
                        DD OFFSET op_one
                        DD OFFSET out_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dx_txt - OFFSET mne_tab + komma_sep
                        DD OFFSET al_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh

lopEF:
                        DD OFFSET op_one
                        DD OFFSET out_txt - OFFSET mne_tab + blank_sep
                        DD OFFSET dx_txt - OFFSET mne_tab + komma_sep
                        DD ax_tab + blank_sep
                        DD 0FFFFFFFFh

lopF0:
                        DD OFFSET op_rep
                        DD OFFSET lock_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopF1:
                        DD OFFSET op_illegal
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopF2:
                        DD OFFSET op_rep
                        DD OFFSET repnz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopF3:
                        DD OFFSET op_rep
                        DD OFFSET repz_txt - OFFSET mne_tab + blank_sep
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopF4:
                        DD OFFSET op_one
                        DD OFFSET hlt_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopF5:
                        DD OFFSET op_one
                        DD OFFSET cmc_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopF6:
                        DD OFFSET opmrF600
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopF7:
                        DD OFFSET opmrF700
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopF8:
                        DD OFFSET op_one
                        DD OFFSET clc_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopF9:
                        DD OFFSET op_one
                        DD OFFSET stc_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopFA:
                        DD OFFSET op_one
                        DD OFFSET cli_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopFB:
                        DD OFFSET op_one
                        DD OFFSET sti_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopFC:
                        DD OFFSET op_one
                        DD OFFSET cld_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopFD:
                        DD OFFSET op_one
                        DD OFFSET std_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopFE:
                        DD OFFSET opmrFE00
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lopFF:
                        DD OFFSET opmrFF00
                        DD op_mem_reg_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


mem8d_16a_tab:
mod8d_16a_rm00000:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_16a_rm00001:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET dx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_16a_rm00010:
                        DD OFFSET op_one
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_16a_rm00011:
                        DD OFFSET op_one
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_16a_rm00100:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_16a_rm00101:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_16a_rm00110:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_16a_rm00111:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_16a_rm01000:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod8d_16a_rm01001:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod8d_16a_rm01010:
                        DD OFFSET mem_im8
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod8d_16a_rm01011:
                        DD OFFSET mem_im8
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod8d_16a_rm01100:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_16a_rm01101:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_16a_rm01110:
                        DD OFFSET mem_im8
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_16a_rm01111:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_16a_rm10000:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod8d_16a_rm10001:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod8d_16a_rm10010:
                        DD OFFSET mem_im16
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod8d_16a_rm10011:
                        DD OFFSET mem_im16
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod8d_16a_rm10100:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_16a_rm10101:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_16a_rm10110:
                        DD OFFSET mem_im16
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_16a_rm10111:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_16a_rm11000:
                        DD OFFSET op_one
                        DD OFFSET al_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_16a_rm11001:
                        DD OFFSET op_one
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_16a_rm11010:
                        DD OFFSET op_one
                        DD OFFSET dl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_16a_rm11011:
                        DD OFFSET op_one
                        DD OFFSET bl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_16a_rm11100:
                        DD OFFSET op_one
                        DD OFFSET ah_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_16a_rm11101:
                        DD OFFSET op_one
                        DD OFFSET ch_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_16a_rm11110:
                        DD OFFSET op_one
                        DD OFFSET dh_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_16a_rm11111:
                        DD OFFSET op_one
                        DD OFFSET bh_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh



mem16d_16a_tab:
mod16d_16a_rm00000:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_16a_rm00001:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET dx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_16a_rm00010:
                        DD OFFSET op_one
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_16a_rm00011:
                        DD OFFSET op_one
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_16a_rm00100:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_16a_rm00101:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_16a_rm00110:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_16a_rm00111:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_16a_rm01000:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod16d_16a_rm01001:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod16d_16a_rm01010:
                        DD OFFSET mem_im8
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod16d_16a_rm01011:
                        DD OFFSET mem_im8
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod16d_16a_rm01100:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_16a_rm01101:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_16a_rm01110:
                        DD OFFSET mem_im8
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_16a_rm01111:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_16a_rm10000:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod16d_16a_rm10001:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod16d_16a_rm10010:
                        DD OFFSET mem_im16
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod16d_16a_rm10011:
                        DD OFFSET mem_im16
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod16d_16a_rm10100:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_16a_rm10101:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_16a_rm10110:
                        DD OFFSET mem_im16
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_16a_rm10111:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_16a_rm11000:
                        DD OFFSET op_one
                        DD OFFSET ax_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_16a_rm11001:
                        DD OFFSET op_one
                        DD OFFSET cx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_16a_rm11010:
                        DD OFFSET op_one
                        DD OFFSET dx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_16a_rm11011:
                        DD OFFSET op_one
                        DD OFFSET bx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_16a_rm11100:
                        DD OFFSET op_one
                        DD OFFSET sp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_16a_rm11101:
                        DD OFFSET op_one
                        DD OFFSET bp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_16a_rm11110:
                        DD OFFSET op_one
                        DD OFFSET si_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_16a_rm11111:
                        DD OFFSET op_one
                        DD OFFSET di_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh



mem32d_16a_tab:
mod32d_16a_rm00000:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_16a_rm00001:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET dx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_16a_rm00010:
                        DD OFFSET op_one
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_16a_rm00011:
                        DD OFFSET op_one
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_16a_rm00100:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET si_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_16a_rm00101:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET di_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_16a_rm00110:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_16a_rm00111:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_16a_rm01000:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod32d_16a_rm01001:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod32d_16a_rm01010:
                        DD OFFSET mem_im8
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod32d_16a_rm01011:
                        DD OFFSET mem_im8
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod32d_16a_rm01100:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_16a_rm01101:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_16a_rm01110:
                        DD OFFSET mem_im8
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_16a_rm01111:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_16a_rm10000:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod32d_16a_rm10001:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod32d_16a_rm10010:
                        DD OFFSET mem_im16
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod32d_16a_rm10011:
                        DD OFFSET mem_im16
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep

mod32d_16a_rm10100:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET si_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_16a_rm10101:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET di_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_16a_rm10110:
                        DD OFFSET mem_im16
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_16a_rm10111:
                        DD OFFSET mem_im16
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET bx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_16a_rm11000:
                        DD OFFSET op_one
                        DD OFFSET eax_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_16a_rm11001:
                        DD OFFSET op_one
                        DD OFFSET ecx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_16a_rm11010:
                        DD OFFSET op_one
                        DD OFFSET edx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_16a_rm11011:
                        DD OFFSET op_one
                        DD OFFSET ebx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_16a_rm11100:
                        DD OFFSET op_one
                        DD OFFSET esp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_16a_rm11101:
                        DD OFFSET op_one
                        DD OFFSET ebp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_16a_rm11110:
                        DD OFFSET op_one
                        DD OFFSET esi_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_16a_rm11111:
                        DD OFFSET op_one
                        DD OFFSET edi_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


mem8d_32a_tab:
mod8d_32a_rm00000:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm00001:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm00010:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm00011:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm00100:
                        DD OFFSET mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm00101:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm00110:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm00111:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm01000:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm01001:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm01010:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm01011:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm01100:
                        DD OFFSET mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm01101:
                        DD OFFSET mem_im8
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm01110:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm01111:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm10000:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm10001:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm10010:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm10011:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm10100:
                        DD OFFSET mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm10101:
                        DD OFFSET mem_im32
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm10110:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm10111:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod8d_32a_rm11000:
                        DD OFFSET op_one
                        DD OFFSET al_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm11001:
                        DD OFFSET op_one
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm11010:
                        DD OFFSET op_one
                        DD OFFSET dl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm11011:
                        DD OFFSET op_one
                        DD OFFSET bl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm11100:
                        DD OFFSET op_one
                        DD OFFSET ah_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm11101:
                        DD OFFSET op_one
                        DD OFFSET ch_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm11110:
                        DD OFFSET op_one
                        DD OFFSET dh_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod8d_32a_rm11111:
                        DD OFFSET op_one
                        DD OFFSET bh_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


mem16d_32a_tab:
mod16d_32a_rm00000:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm00001:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm00010:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm00011:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm00100:
                        DD OFFSET mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm00101:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm00110:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm00111:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm01000:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm01001:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm01010:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm01011:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm01100:
                        DD OFFSET mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm01101:
                        DD OFFSET mem_im8
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm01110:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm01111:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm10000:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm10001:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm10010:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm10011:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm10100:
                        DD OFFSET mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm10101:
                        DD OFFSET mem_im32
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm10110:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm10111:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod16d_32a_rm11000:
                        DD OFFSET op_one
                        DD OFFSET ax_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm11001:
                        DD OFFSET op_one
                        DD OFFSET cx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm11010:
                        DD OFFSET op_one
                        DD OFFSET dx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm11011:
                        DD OFFSET op_one
                        DD OFFSET bx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm11100:
                        DD OFFSET op_one
                        DD OFFSET sp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm11101:
                        DD OFFSET op_one
                        DD OFFSET bp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm11110:
                        DD OFFSET op_one
                        DD OFFSET si_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod16d_32a_rm11111:
                        DD OFFSET op_one
                        DD OFFSET di_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


mem32d_32a_tab:
mod32d_32a_rm00000:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm00001:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm00010:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm00011:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm00100:
                        DD OFFSET mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm00101:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm00110:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm00111:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm01000:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm01001:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm01010:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm01011:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm01100:
                        DD OFFSET mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm01101:
                        DD OFFSET mem_im8
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm01110:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm01111:
                        DD OFFSET mem_im8
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm10000:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm10001:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm10010:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm10011:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm10100:
                        DD OFFSET mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm10101:
                        DD OFFSET mem_im32
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm10110:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm10111:
                        DD OFFSET mem_im32
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod32d_32a_rm11000:
                        DD OFFSET op_one
                        DD OFFSET eax_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm11001:
                        DD OFFSET op_one
                        DD OFFSET ecx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm11010:
                        DD OFFSET op_one
                        DD OFFSET edx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm11011:
                        DD OFFSET op_one
                        DD OFFSET ebx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm11100:
                        DD OFFSET op_one
                        DD OFFSET esp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm11101:
                        DD OFFSET op_one
                        DD OFFSET ebp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm11110:
                        DD OFFSET op_one
                        DD OFFSET esi_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod32d_32a_rm11111:
                        DD OFFSET op_one
                        DD OFFSET edi_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


mem64_8d_32a_tab:
mod64_8d_32a_rm000000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm000001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm000010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm000011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm000100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm000101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eip_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm000110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm000111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm001000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm001001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm001010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm001011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm001100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm001101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eip_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm001110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm001111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm010000:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm010001:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm010010:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm010011:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm010100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm010101:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm010110:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm010111:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm011000:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm011001:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm011010:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm011011:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm011100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm011101:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm011110:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm011111:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm100000:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm100001:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm100010:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm100011:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm100100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm100101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm100110:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm100111:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm101000:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm101001:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm101010:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm101011:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm101100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm101101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm101110:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm101111:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_32a_rm110000:
                        DD OFFSET op_one
                        DD OFFSET al_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm110001:
                        DD OFFSET op_one
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm110010:
                        DD OFFSET op_one
                        DD OFFSET dl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm110011:
                        DD OFFSET op_one
                        DD OFFSET bl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm110100:
                        DD OFFSET op_one
                        DD OFFSET ah_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm110101:
                        DD OFFSET op_one
                        DD OFFSET ch_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm110110:
                        DD OFFSET op_one
                        DD OFFSET dh_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm110111:
                        DD OFFSET op_one
                        DD OFFSET bh_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm111000:
                        DD OFFSET op_one
                        DD OFFSET r8l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm111001:
                        DD OFFSET op_one
                        DD OFFSET r9l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm111010:
                        DD OFFSET op_one
                        DD OFFSET r10l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm111011:
                        DD OFFSET op_one
                        DD OFFSET r11l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm111100:
                        DD OFFSET op_one
                        DD OFFSET r12l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm111101:
                        DD OFFSET op_one
                        DD OFFSET r13l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm111110:
                        DD OFFSET op_one
                        DD OFFSET r14l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_32a_rm111111:
                        DD OFFSET op_one
                        DD OFFSET r15l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


mem64_16d_32a_tab:
mod64_16d_32a_rm000000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm000001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm000010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm000011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm000100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm000101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eip_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm000110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm000111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm001000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm001001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm001010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm001011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm001100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm001101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eip_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm001110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm001111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm010000:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm010001:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm010010:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm010011:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm010100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm010101:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm010110:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm010111:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm011000:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm011001:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm011010:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm011011:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm011100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm011101:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm011110:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm011111:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm100000:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm100001:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm100010:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm100011:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm100100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm100101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm100110:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm100111:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm101000:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm101001:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm101010:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm101011:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm101100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm101101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm101110:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm101111:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_32a_rm110000:
                        DD OFFSET op_one
                        DD OFFSET ax_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm110001:
                        DD OFFSET op_one
                        DD OFFSET cx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm110010:
                        DD OFFSET op_one
                        DD OFFSET dx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm110011:
                        DD OFFSET op_one
                        DD OFFSET bx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm110100:
                        DD OFFSET op_one
                        DD OFFSET sp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm110101:
                        DD OFFSET op_one
                        DD OFFSET bp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm110110:
                        DD OFFSET op_one
                        DD OFFSET si_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm110111:
                        DD OFFSET op_one
                        DD OFFSET di_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


mod64_16d_32a_rm111000:
                        DD OFFSET op_one
                        DD OFFSET r8w_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm111001:
                        DD OFFSET op_one
                        DD OFFSET r9w_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm111010:
                        DD OFFSET op_one
                        DD OFFSET r10w_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm111011:
                        DD OFFSET op_one
                        DD OFFSET r11w_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm111100:
                        DD OFFSET op_one
                        DD OFFSET r12w_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm111101:
                        DD OFFSET op_one
                        DD OFFSET r13w_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm111110:
                        DD OFFSET op_one
                        DD OFFSET r14w_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_32a_rm111111:
                        DD OFFSET op_one
                        DD OFFSET r15w_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


mem64_32d_32a_tab:
mod64_32d_32a_rm000000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm000001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm000010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm000011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm000100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm000101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eip_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm000110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm000111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm001000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm001001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm001010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm001011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm001100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm001101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eip_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm001110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm001111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15d_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm010000:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm010001:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm010010:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm010011:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm010100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm010101:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm010110:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm010111:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm011000:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm011001:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm011010:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm011011:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm011100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm011101:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm011110:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm011111:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm100000:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm100001:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm100010:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm100011:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm100100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm100101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm100110:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm100111:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm101000:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm101001:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm101010:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm101011:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm101100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm101101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm101110:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm101111:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15d_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_32a_rm110000:
                        DD OFFSET op_one
                        DD OFFSET eax_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm110001:
                        DD OFFSET op_one
                        DD OFFSET ecx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm110010:
                        DD OFFSET op_one
                        DD OFFSET edx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm110011:
                        DD OFFSET op_one
                        DD OFFSET ebx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm110100:
                        DD OFFSET op_one
                        DD OFFSET esp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm110101:
                        DD OFFSET op_one
                        DD OFFSET ebp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm110110:
                        DD OFFSET op_one
                        DD OFFSET esi_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm110111:
                        DD OFFSET op_one
                        DD OFFSET edi_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


mod64_32d_32a_rm111000:
                        DD OFFSET op_one
                        DD OFFSET r8d_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm111001:
                        DD OFFSET op_one
                        DD OFFSET r9d_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm111010:
                        DD OFFSET op_one
                        DD OFFSET r10d_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm111011:
                        DD OFFSET op_one
                        DD OFFSET r11d_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm111100:
                        DD OFFSET op_one
                        DD OFFSET r12d_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm111101:
                        DD OFFSET op_one
                        DD OFFSET r13d_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm111110:
                        DD OFFSET op_one
                        DD OFFSET r14d_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_32a_rm111111:
                        DD OFFSET op_one
                        DD OFFSET r15d_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh



mem64_8d_64a_tab:
mod64_8d_64a_rm000000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rax_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm000001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rcx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm000010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm000011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm000100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm000101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rip_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm000110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm000111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm001000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm001001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm001010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm001011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm001100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm001101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rip_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm001110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm001111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm010000:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm010001:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rcx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm010010:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm010011:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm010100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm010101:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm010110:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm010111:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm011000:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm011001:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm011010:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm011011:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm011100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm011101:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm011110:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm011111:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm100000:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm100001:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rcx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm100010:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm100011:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm100100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm100101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm100110:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm100111:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh


mod64_8d_64a_rm101000:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm101001:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm101010:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm101011:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm101100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm101101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm101110:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_8d_64a_rm101111:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh


mod64_8d_64a_rm110000:
                        DD OFFSET op_one
                        DD OFFSET al_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm110001:
                        DD OFFSET op_one
                        DD OFFSET cl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm110010:
                        DD OFFSET op_one
                        DD OFFSET dl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm110011:
                        DD OFFSET op_one
                        DD OFFSET bl_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm110100:
                        DD OFFSET op_one
                        DD OFFSET ah_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm110101:
                        DD OFFSET op_one
                        DD OFFSET ch_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm110110:
                        DD OFFSET op_one
                        DD OFFSET dh_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm110111:
                        DD OFFSET op_one
                        DD OFFSET bh_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm111000:
                        DD OFFSET op_one
                        DD OFFSET r8l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm111001:
                        DD OFFSET op_one
                        DD OFFSET r9l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm111010:
                        DD OFFSET op_one
                        DD OFFSET r10l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm111011:
                        DD OFFSET op_one
                        DD OFFSET r11l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm111100:
                        DD OFFSET op_one
                        DD OFFSET r12l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm111101:
                        DD OFFSET op_one
                        DD OFFSET r13l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm111110:
                        DD OFFSET op_one
                        DD OFFSET r14l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_8d_64a_rm111111:
                        DD OFFSET op_one
                        DD OFFSET r15l_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


mem64_16d_64a_tab:
mod64_16d_64a_rm000000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rax_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm000001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rcx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm000010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm000011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm000100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm000101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rip_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm000110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm000111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm001000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm001001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm001010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm001011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm001100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm001101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rip_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm001110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm001111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm010000:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm010001:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rcx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm010010:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm010011:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm010100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm010101:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm010110:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm010111:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm011000:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm011001:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm011010:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm011011:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm011100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm011101:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm011110:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm011111:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm100000:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm100001:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rcx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm100010:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm100011:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm100100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm100101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm100110:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm100111:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh


mod64_16d_64a_rm101000:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm101001:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm101010:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm101011:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm101100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm101101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm101110:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_16d_64a_rm101111:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh


mod64_16d_64a_rm110000:
                        DD OFFSET op_one
                        DD OFFSET ax_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm110001:
                        DD OFFSET op_one
                        DD OFFSET cx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm110010:
                        DD OFFSET op_one
                        DD OFFSET dx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm110011:
                        DD OFFSET op_one
                        DD OFFSET bx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm110100:
                        DD OFFSET op_one
                        DD OFFSET sp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm110101:
                        DD OFFSET op_one
                        DD OFFSET bp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm110110:
                        DD OFFSET op_one
                        DD OFFSET si_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_16d_64a_rm110111:
                        DD OFFSET op_one
                        DD OFFSET di_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


mem64_32d_64a_tab:
mod64_32d_64a_rm000000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rax_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm000001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rcx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm000010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm000011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbx_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm000100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm000101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rip_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm000110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm000111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdi_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm001000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm001001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm001010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm001011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm001100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm001101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rip_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm001110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm001111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15_txt - OFFSET mne_tab + rhak_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm010000:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm010001:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rcx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm010010:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm010011:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm010100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm010101:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm010110:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm010111:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm011000:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm011001:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm011010:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm011011:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm011100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm011101:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm011110:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm011111:
                        DD OFFSET mem_im8
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm100000:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm100001:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rcx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm100010:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm100011:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm100100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm100101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm100110:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm100111:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh


mod64_32d_64a_rm101000:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm101001:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm101010:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm101011:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm101100:
                        DD OFFSET long_mem_sib
                        DD null_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm101101:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm101110:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm101111:
                        DD OFFSET mem_im32
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + rhak_sep
                        DD 0FFFFFFFFh

mod64_32d_64a_rm110000:
                        DD OFFSET op_one
                        DD OFFSET rax_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm110001:
                        DD OFFSET op_one
                        DD OFFSET rcx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm110010:
                        DD OFFSET op_one
                        DD OFFSET rdx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm110011:
                        DD OFFSET op_one
                        DD OFFSET rbx_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm110100:
                        DD OFFSET op_one
                        DD OFFSET rsp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm110101:
                        DD OFFSET op_one
                        DD OFFSET rbp_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm110110:
                        DD OFFSET op_one
                        DD OFFSET rsi_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm110111:
                        DD OFFSET op_one
                        DD OFFSET rdi_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


mod64_32d_64a_rm111000:
                        DD OFFSET op_one
                        DD OFFSET r8_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm111001:
                        DD OFFSET op_one
                        DD OFFSET r9_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm111010:
                        DD OFFSET op_one
                        DD OFFSET r10_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm111011:
                        DD OFFSET op_one
                        DD OFFSET r11_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm111100:
                        DD OFFSET op_one
                        DD OFFSET r12_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm111101:
                        DD OFFSET op_one
                        DD OFFSET r13_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm111110:
                        DD OFFSET op_one
                        DD OFFSET r14_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

mod64_32d_64a_rm111111:
                        DD OFFSET op_one
                        DD OFFSET r15_txt - OFFSET mne_tab + blank_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


mem_sib0_tab:
sib0_000:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib0_001:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib0_010:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib0_011:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib0_100:
                        DD OFFSET op_one
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib0_101:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

sib0_110:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib0_111:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh


mem_sib1_tab:
sib1_000:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib1_001:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib1_010:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib1_011:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib1_100:
                        DD OFFSET op_one
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib1_101:
                        DD OFFSET op_one
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib1_110:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib1_111:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh


mem_sib2_tab:
sib2_000:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET eax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib2_001:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ecx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib2_010:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib2_011:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib2_100:
                        DD OFFSET op_one
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib2_101:
                        DD OFFSET op_one
                        DD OFFSET ss_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET ebp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib2_110:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET esi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

sib2_111:
                        DD OFFSET op_one
                        DD OFFSET ds_txt - OFFSET mne_tab + kolon_par_sep
                        DD OFFSET edi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh


sib_index_tab:
sibi_000:
                        DD OFFSET op_one
                        DD OFFSET eax_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

sibi_001:
                        DD OFFSET op_one
                        DD OFFSET ecx_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

sibi_010:
                        DD OFFSET op_one
                        DD OFFSET edx_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

sibi_011:
                        DD OFFSET op_one
                        DD OFFSET ebx_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

sibi_100:
                        DD OFFSET op_one
                        DD OFFSET txt_0 - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

sibi_101:
                        DD OFFSET op_one
                        DD OFFSET ebp_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

sibi_110:
                        DD OFFSET op_one
                        DD OFFSET esi_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

sibi_111:
                        DD OFFSET op_one
                        DD OFFSET edi_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


sib_scale_tab:
sibc_00:
                        DD OFFSET op_one
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

sibc_01:
                        DD OFFSET op_one
                        DD OFFSET star2 - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

sibc_10:
                        DD OFFSET op_one
                        DD OFFSET star4 - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

sibc_11:
                        DD OFFSET op_one
                        DD OFFSET star8 - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh


long_mem_sib0_tab:
lsib0_0000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib0_0001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rcx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib0_0010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib0_0011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib0_0100:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib0_0101:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsib0_0110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib0_0111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib0_1000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib0_1001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib0_1010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib0_1011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib0_1100:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r12_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib0_1101:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsib0_1110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib0_1111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh


long_mem_sib1_tab:
lsib1_0000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_0001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rcx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_0010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_0011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_0100:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_0101:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_0110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_0111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_1000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_1001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_1010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_1011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_1100:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r12_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_1101:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_1110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib1_1111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh


long_mem_sib2_tab:
lsib2_0000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rax_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_0001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rcx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_0010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_0011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbx_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_0100:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_0101:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rbp_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_0110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rsi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_0111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET rdi_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_1000:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r8_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_1001:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r9_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_1010:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r10_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_1011:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r11_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_1100:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r12_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_1101:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r13_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_1110:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r14_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh

lsib2_1111:
                        DD OFFSET op_one
                        DD OFFSET noseg_txt - OFFSET mne_tab + lhak_sep
                        DD OFFSET r15_txt - OFFSET mne_tab + plus_sep
                        DD null_tab + no_sep
                        DD 0FFFFFFFFh


long_sib_index_tab:
lsibi_0000:
                        DD OFFSET op_one
                        DD OFFSET rax_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_0001:
                        DD OFFSET op_one
                        DD OFFSET rcx_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_0010:
                        DD OFFSET op_one
                        DD OFFSET rdx_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_0011:
                        DD OFFSET op_one
                        DD OFFSET rbx_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_0100:
                        DD OFFSET op_one
                        DD OFFSET txt_0 - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_0101:
                        DD OFFSET op_one
                        DD OFFSET rbp_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_0110:
                        DD OFFSET op_one
                        DD OFFSET rsi_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_0111:
                        DD OFFSET op_one
                        DD OFFSET rdi_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_1000:
                        DD OFFSET op_one
                        DD OFFSET r8_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_1001:
                        DD OFFSET op_one
                        DD OFFSET r9_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_1010:
                        DD OFFSET op_one
                        DD OFFSET r10_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_1011:
                        DD OFFSET op_one
                        DD OFFSET r11_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_1100:
                        DD OFFSET op_one
                        DD OFFSET r12_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_1101:
                        DD OFFSET op_one
                        DD OFFSET r13_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_1110:
                        DD OFFSET op_one
                        DD OFFSET r14_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

lsibi_1111:
                        DD OFFSET op_one
                        DD OFFSET r15_txt - OFFSET mne_tab + no_sep
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh
                        DD 0FFFFFFFFh

        public adr_16a_tab
        public adr_32a_tab
        public long_adr_32a_tab
        public long_adr_64a_tab
        public adr_sib_tab
        public adr_sib_index_tab
        public long_adr_sib_tab
        public long_adr_sib_index_tab

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
        extrn eip_adr:near
        extrn rax_adr:near
        extrn rbx_adr:near
        extrn rcx_adr:near
        extrn rdx_adr:near
        extrn rsi_adr:near
        extrn rdi_adr:near
        extrn rbp_adr:near
        extrn rsp_adr:near
        extrn rip_adr:near
        extrn r8_adr:near
        extrn r9_adr:near
        extrn r10_adr:near
        extrn r11_adr:near
        extrn r12_adr:near
        extrn r13_adr:near
        extrn r14_adr:near
        extrn r15_adr:near
        extrn r8d_adr:near
        extrn r9d_adr:near
        extrn r10d_adr:near
        extrn r11d_adr:near
        extrn r12d_adr:near
        extrn r13d_adr:near
        extrn r14d_adr:near
        extrn r15d_adr:near

adr_16a_tab:
adr_16a_rm00000:
                        DD OFFSET bx_adr
                        DD OFFSET si_adr

adr_16a_rm00001:
                        DD OFFSET bx_adr
                        DD OFFSET di_adr

adr_16a_rm00010:
                        DD OFFSET bp_adr
                        DD OFFSET si_adr

adr_16a_rm00011:
                        DD OFFSET bp_adr
                        DD OFFSET di_adr

adr_16a_rm00100:
                        DD OFFSET si_adr
                        DD OFFSET no_adr

adr_16a_rm00101:
                        DD OFFSET di_adr
                        DD OFFSET no_adr

adr_16a_rm00110:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_16a_rm00111:
                        DD OFFSET bx_adr
                        DD OFFSET no_adr

adr_16a_rm01000:
                        DD OFFSET bx_adr
                        DD OFFSET si_adr

adr_16a_rm01001:
                        DD OFFSET bx_adr
                        DD OFFSET di_adr

adr_16a_rm01010:
                        DD OFFSET bp_adr
                        DD OFFSET si_adr

adr_16a_rm01011:
                        DD OFFSET bp_adr
                        DD OFFSET di_adr

adr_16a_rm01100:
                        DD OFFSET si_adr
                        DD OFFSET no_adr

adr_16a_rm01101:
                        DD OFFSET di_adr
                        DD OFFSET no_adr

adr_16a_rm01110:
                        DD OFFSET bp_adr
                        DD OFFSET no_adr

adr_16a_rm01111:
                        DD OFFSET bx_adr
                        DD OFFSET no_adr

adr_16a_rm10000:
                        DD OFFSET bx_adr
                        DD OFFSET si_adr

adr_16a_rm10001:
                        DD OFFSET bx_adr
                        DD OFFSET di_adr

adr_16a_rm10010:
                        DD OFFSET bp_adr
                        DD OFFSET si_adr

adr_16a_rm10011:
                        DD OFFSET bp_adr
                        DD OFFSET di_adr

adr_16a_rm10100:
                        DD OFFSET si_adr
                        DD OFFSET no_adr

adr_16a_rm10101:
                        DD OFFSET di_adr
                        DD OFFSET no_adr

adr_16a_rm10110:
                        DD OFFSET bp_adr
                        DD OFFSET no_adr

adr_16a_rm10111:
                        DD OFFSET bx_adr
                        DD OFFSET no_adr

adr_32a_tab:
adr_32a_rm00000:
                        DD OFFSET eax_adr
                        DD OFFSET no_adr

adr_32a_rm00001:
                        DD OFFSET ecx_adr
                        DD OFFSET no_adr

adr_32a_rm00010:
                        DD OFFSET edx_adr
                        DD OFFSET no_adr

adr_32a_rm00011:
                        DD OFFSET ebx_adr
                        DD OFFSET no_adr

adr_32a_rm00100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_32a_rm00101:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_32a_rm00110:
                        DD OFFSET esi_adr
                        DD OFFSET no_adr

adr_32a_rm00111:
                        DD OFFSET edi_adr
                        DD OFFSET no_adr

adr_32a_rm01000:
                        DD OFFSET eax_adr
                        DD OFFSET no_adr

adr_32a_rm01001:
                        DD OFFSET ecx_adr
                        DD OFFSET no_adr

adr_32a_rm01010:
                        DD OFFSET edx_adr
                        DD OFFSET no_adr

adr_32a_rm01011:
                        DD OFFSET ebx_adr
                        DD OFFSET no_adr

adr_32a_rm01100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_32a_rm01101:
                        DD OFFSET ebp_adr
                        DD OFFSET no_adr

adr_32a_rm01110:
                        DD OFFSET esi_adr
                        DD OFFSET no_adr

adr_32a_rm01111:
                        DD OFFSET edi_adr
                        DD OFFSET no_adr

adr_32a_rm10000:
                        DD OFFSET eax_adr
                        DD OFFSET no_adr

adr_32a_rm10001:
                        DD OFFSET ecx_adr
                        DD OFFSET no_adr

adr_32a_rm10010:
                        DD OFFSET edx_adr
                        DD OFFSET no_adr

adr_32a_rm10011:
                        DD OFFSET ebx_adr
                        DD OFFSET no_adr

adr_32a_rm10100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_32a_rm10101:
                        DD OFFSET ebp_adr
                        DD OFFSET no_adr

adr_32a_rm10110:
                        DD OFFSET esi_adr
                        DD OFFSET no_adr

adr_32a_rm10111:
                        DD OFFSET edi_adr
                        DD OFFSET no_adr

long_adr_32a_tab:
adr_64_32a_rm000000:
                        DD OFFSET eax_adr
                        DD OFFSET no_adr

adr_64_32a_rm000001:
                        DD OFFSET ecx_adr
                        DD OFFSET no_adr

adr_64_32a_rm000010:
                        DD OFFSET edx_adr
                        DD OFFSET no_adr

adr_64_32a_rm000011:
                        DD OFFSET ebx_adr
                        DD OFFSET no_adr

adr_64_32a_rm000100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_64_32a_rm000101:
                        DD OFFSET eip_adr
                        DD OFFSET no_adr

adr_64_32a_rm000110:
                        DD OFFSET esi_adr
                        DD OFFSET no_adr

adr_64_32a_rm000111:
                        DD OFFSET edi_adr
                        DD OFFSET no_adr

adr_64_32a_rm001000:
                        DD OFFSET r8d_adr
                        DD OFFSET no_adr

adr_64_32a_rm001001:
                        DD OFFSET r9d_adr
                        DD OFFSET no_adr

adr_64_32a_rm001010:
                        DD OFFSET r10d_adr
                        DD OFFSET no_adr

adr_64_32a_rm001011:
                        DD OFFSET r11d_adr
                        DD OFFSET no_adr

adr_64_32a_rm001100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_64_32a_rm001101:
                        DD OFFSET eip_adr
                        DD OFFSET no_adr

adr_64_32a_rm001110:
                        DD OFFSET r14d_adr
                        DD OFFSET no_adr

adr_64_32a_rm001111:
                        DD OFFSET r15d_adr
                        DD OFFSET no_adr

adr_64_32a_rm010000:
                        DD OFFSET eax_adr
                        DD OFFSET no_adr

adr_64_32a_rm010001:
                        DD OFFSET ecx_adr
                        DD OFFSET no_adr

adr_64_32a_rm010010:
                        DD OFFSET edx_adr
                        DD OFFSET no_adr

adr_64_32a_rm010011:
                        DD OFFSET ebx_adr
                        DD OFFSET no_adr

adr_64_32a_rm010100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_64_32a_rm010101:
                        DD OFFSET ebp_adr
                        DD OFFSET no_adr

adr_64_32a_rm010110:
                        DD OFFSET esi_adr
                        DD OFFSET no_adr

adr_64_32a_rm010111:
                        DD OFFSET edi_adr
                        DD OFFSET no_adr

adr_64_32a_rm011000:
                        DD OFFSET r8d_adr
                        DD OFFSET no_adr

adr_64_32a_rm011001:
                        DD OFFSET r9d_adr
                        DD OFFSET no_adr

adr_64_32a_rm011010:
                        DD OFFSET r10d_adr
                        DD OFFSET no_adr

adr_64_32a_rm011011:
                        DD OFFSET r11d_adr
                        DD OFFSET no_adr

adr_64_32a_rm011100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_64_32a_rm011101:
                        DD OFFSET r13d_adr
                        DD OFFSET no_adr

adr_64_32a_rm011110:
                        DD OFFSET r14d_adr
                        DD OFFSET no_adr

adr_64_32a_rm011111:
                        DD OFFSET r15d_adr
                        DD OFFSET no_adr

adr_64_32a_rm100000:
                        DD OFFSET eax_adr
                        DD OFFSET no_adr

adr_64_32a_rm100001:
                        DD OFFSET ecx_adr
                        DD OFFSET no_adr

adr_64_32a_rm100010:
                        DD OFFSET edx_adr
                        DD OFFSET no_adr

adr_64_32a_rm100011:
                        DD OFFSET ebx_adr
                        DD OFFSET no_adr

adr_64_32a_rm100100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_64_32a_rm100101:
                        DD OFFSET ebp_adr
                        DD OFFSET no_adr

adr_64_32a_rm100110:
                        DD OFFSET esi_adr
                        DD OFFSET no_adr

adr_64_32a_rm100111:
                        DD OFFSET edi_adr
                        DD OFFSET no_adr

adr_64_32a_rm101000:
                        DD OFFSET r8d_adr
                        DD OFFSET no_adr

adr_64_32a_rm101001:
                        DD OFFSET r9d_adr
                        DD OFFSET no_adr

adr_64_32a_rm101010:
                        DD OFFSET r10d_adr
                        DD OFFSET no_adr

adr_64_32a_rm101011:
                        DD OFFSET r11d_adr
                        DD OFFSET no_adr

adr_64_32a_rm101100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_64_32a_rm101101:
                        DD OFFSET r13d_adr
                        DD OFFSET no_adr

adr_64_32a_rm101110:
                        DD OFFSET r14d_adr
                        DD OFFSET no_adr

adr_64_32a_rm101111:
                        DD OFFSET r15d_adr
                        DD OFFSET no_adr

long_adr_64a_tab:
adr_64_64a_rm000000:
                        DD OFFSET rax_adr
                        DD OFFSET no_adr

adr_64_64a_rm000001:
                        DD OFFSET rcx_adr
                        DD OFFSET no_adr

adr_64_64a_rm000010:
                        DD OFFSET rdx_adr
                        DD OFFSET no_adr

adr_64_64a_rm000011:
                        DD OFFSET rbx_adr
                        DD OFFSET no_adr

adr_64_64a_rm000100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_64_64a_rm000101:
                        DD OFFSET rip_adr
                        DD OFFSET no_adr

adr_64_64a_rm000110:
                        DD OFFSET rsi_adr
                        DD OFFSET no_adr

adr_64_64a_rm000111:
                        DD OFFSET rdi_adr
                        DD OFFSET no_adr

adr_64_64a_rm001000:
                        DD OFFSET r8_adr
                        DD OFFSET no_adr

adr_64_64a_rm001001:
                        DD OFFSET r9_adr
                        DD OFFSET no_adr

adr_64_64a_rm001010:
                        DD OFFSET r10_adr
                        DD OFFSET no_adr

adr_64_64a_rm001011:
                        DD OFFSET r11_adr
                        DD OFFSET no_adr

adr_64_64a_rm001100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_64_64a_rm001101:
                        DD OFFSET rip_adr
                        DD OFFSET no_adr

adr_64_64a_rm001110:
                        DD OFFSET r14_adr
                        DD OFFSET no_adr

adr_64_64a_rm001111:
                        DD OFFSET r15_adr
                        DD OFFSET no_adr

adr_64_64a_rm010000:
                        DD OFFSET rax_adr
                        DD OFFSET no_adr

adr_64_64a_rm010001:
                        DD OFFSET rcx_adr
                        DD OFFSET no_adr

adr_64_64a_rm010010:
                        DD OFFSET rdx_adr
                        DD OFFSET no_adr

adr_64_64a_rm010011:
                        DD OFFSET rbx_adr
                        DD OFFSET no_adr

adr_64_64a_rm010100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_64_64a_rm010101:
                        DD OFFSET rbp_adr
                        DD OFFSET no_adr

adr_64_64a_rm010110:
                        DD OFFSET rsi_adr
                        DD OFFSET no_adr

adr_64_64a_rm010111:
                        DD OFFSET rdi_adr
                        DD OFFSET no_adr

adr_64_64a_rm011000:
                        DD OFFSET r8_adr
                        DD OFFSET no_adr

adr_64_64a_rm011001:
                        DD OFFSET r9_adr
                        DD OFFSET no_adr

adr_64_64a_rm011010:
                        DD OFFSET r10_adr
                        DD OFFSET no_adr

adr_64_64a_rm011011:
                        DD OFFSET r11_adr
                        DD OFFSET no_adr

adr_64_64a_rm011100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_64_64a_rm011101:
                        DD OFFSET r13_adr
                        DD OFFSET no_adr

adr_64_64a_rm011110:
                        DD OFFSET r14_adr
                        DD OFFSET no_adr

adr_64_64a_rm011111:
                        DD OFFSET r15_adr
                        DD OFFSET no_adr

adr_64_64a_rm100000:
                        DD OFFSET rax_adr
                        DD OFFSET no_adr

adr_64_64a_rm100001:
                        DD OFFSET rcx_adr
                        DD OFFSET no_adr

adr_64_64a_rm100010:
                        DD OFFSET rdx_adr
                        DD OFFSET no_adr

adr_64_64a_rm100011:
                        DD OFFSET rbx_adr
                        DD OFFSET no_adr

adr_64_64a_rm100100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_64_64a_rm100101:
                        DD OFFSET rbp_adr
                        DD OFFSET no_adr

adr_64_64a_rm100110:
                        DD OFFSET rsi_adr
                        DD OFFSET no_adr

adr_64_64a_rm100111:
                        DD OFFSET rdi_adr
                        DD OFFSET no_adr

adr_64_64a_rm101000:
                        DD OFFSET r8_adr
                        DD OFFSET no_adr

adr_64_64a_rm101001:
                        DD OFFSET r9_adr
                        DD OFFSET no_adr

adr_64_64a_rm101010:
                        DD OFFSET r10_adr
                        DD OFFSET no_adr

adr_64_64a_rm101011:
                        DD OFFSET r11_adr
                        DD OFFSET no_adr

adr_64_64a_rm101100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_64_64a_rm101101:
                        DD OFFSET r13_adr
                        DD OFFSET no_adr

adr_64_64a_rm101110:
                        DD OFFSET r14_adr
                        DD OFFSET no_adr

adr_64_64a_rm101111:
                        DD OFFSET r15_adr
                        DD OFFSET no_adr

adr_sib_tab:
adr_sib0_000:
                        DD OFFSET eax_adr
                        DD OFFSET no_adr

adr_sib0_001:
                        DD OFFSET ecx_adr
                        DD OFFSET no_adr

adr_sib0_010:
                        DD OFFSET edx_adr
                        DD OFFSET no_adr

adr_sib0_011:
                        DD OFFSET ebx_adr
                        DD OFFSET no_adr

adr_sib0_100:
                        DD OFFSET esp_adr
                        DD OFFSET no_adr

adr_sib0_101:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_sib0_110:
                        DD OFFSET esi_adr
                        DD OFFSET no_adr

adr_sib0_111:
                        DD OFFSET edi_adr
                        DD OFFSET no_adr


adr_sib1_000:
                        DD OFFSET eax_adr
                        DD OFFSET no_adr

adr_sib1_001:
                        DD OFFSET ecx_adr
                        DD OFFSET no_adr

adr_sib1_010:
                        DD OFFSET edx_adr
                        DD OFFSET no_adr

adr_sib1_011:
                        DD OFFSET ebx_adr
                        DD OFFSET no_adr

adr_sib1_100:
                        DD OFFSET esp_adr
                        DD OFFSET no_adr

adr_sib1_101:
                        DD OFFSET ebp_adr
                        DD OFFSET no_adr

adr_sib1_110:
                        DD OFFSET esi_adr
                        DD OFFSET no_adr

adr_sib1_111:
                        DD OFFSET edi_adr
                        DD OFFSET no_adr


adr_sib2_000:
                        DD OFFSET eax_adr
                        DD OFFSET no_adr

adr_sib2_001:
                        DD OFFSET ecx_adr
                        DD OFFSET no_adr

adr_sib2_010:
                        DD OFFSET edx_adr
                        DD OFFSET no_adr

adr_sib2_011:
                        DD OFFSET ebx_adr
                        DD OFFSET no_adr

adr_sib2_100:
                        DD OFFSET esp_adr
                        DD OFFSET no_adr

adr_sib2_101:
                        DD OFFSET ebp_adr
                        DD OFFSET no_adr

adr_sib2_110:
                        DD OFFSET esi_adr
                        DD OFFSET no_adr

adr_sib2_111:
                        DD OFFSET edi_adr
                        DD OFFSET no_adr

adr_sib_index_tab:
adr_sibi_000:
                        DD OFFSET eax_adr
                        DD OFFSET no_adr

adr_sibi_001:
                        DD OFFSET ecx_adr
                        DD OFFSET no_adr

adr_sibi_010:
                        DD OFFSET edx_adr
                        DD OFFSET no_adr

adr_sibi_011:
                        DD OFFSET ebx_adr
                        DD OFFSET no_adr

adr_sibi_100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

adr_sibi_101:
                        DD OFFSET ebp_adr
                        DD OFFSET no_adr

adr_sibi_110:
                        DD OFFSET esi_adr
                        DD OFFSET no_adr

adr_sibi_111:
                        DD OFFSET edi_adr
                        DD OFFSET no_adr

long_adr_sib_tab:
ladr_sib0_0000:
                        DD OFFSET rax_adr
                        DD OFFSET no_adr

ladr_sib0_0001:
                        DD OFFSET rcx_adr
                        DD OFFSET no_adr

ladr_sib0_0010:
                        DD OFFSET rdx_adr
                        DD OFFSET no_adr

ladr_sib0_0011:
                        DD OFFSET rbx_adr
                        DD OFFSET no_adr

ladr_sib0_0100:
                        DD OFFSET rsp_adr
                        DD OFFSET no_adr

ladr_sib0_0101:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

ladr_sib0_0110:
                        DD OFFSET rsi_adr
                        DD OFFSET no_adr

ladr_sib0_0111:
                        DD OFFSET rdi_adr
                        DD OFFSET no_adr

ladr_sib0_1000:
                        DD OFFSET r8_adr
                        DD OFFSET no_adr

ladr_sib0_1001:
                        DD OFFSET r9_adr
                        DD OFFSET no_adr

ladr_sib0_1010:
                        DD OFFSET r10_adr
                        DD OFFSET no_adr

ladr_sib0_1011:
                        DD OFFSET r11_adr
                        DD OFFSET no_adr

ladr_sib0_1100:
                        DD OFFSET r12_adr
                        DD OFFSET no_adr

ladr_sib0_1101:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

ladr_sib0_1110:
                        DD OFFSET r14_adr
                        DD OFFSET no_adr

ladr_sib0_1111:
                        DD OFFSET r15_adr
                        DD OFFSET no_adr


ladr_sib1_0000:
                        DD OFFSET rax_adr
                        DD OFFSET no_adr

ladr_sib1_0001:
                        DD OFFSET rcx_adr
                        DD OFFSET no_adr

ladr_sib1_0010:
                        DD OFFSET rdx_adr
                        DD OFFSET no_adr

ladr_sib1_0011:
                        DD OFFSET rbx_adr
                        DD OFFSET no_adr

ladr_sib1_0100:
                        DD OFFSET rsp_adr
                        DD OFFSET no_adr

ladr_sib1_0101:
                        DD OFFSET rbp_adr
                        DD OFFSET no_adr

ladr_sib1_0110:
                        DD OFFSET rsi_adr
                        DD OFFSET no_adr

ladr_sib1_0111:
                        DD OFFSET rdi_adr
                        DD OFFSET no_adr


ladr_sib1_1000:
                        DD OFFSET r8_adr
                        DD OFFSET no_adr

ladr_sib1_1001:
                        DD OFFSET r9_adr
                        DD OFFSET no_adr

ladr_sib1_1010:
                        DD OFFSET r10_adr
                        DD OFFSET no_adr

ladr_sib1_1011:
                        DD OFFSET r11_adr
                        DD OFFSET no_adr

ladr_sib1_1100:
                        DD OFFSET r12_adr
                        DD OFFSET no_adr

ladr_sib1_1101:
                        DD OFFSET r13_adr
                        DD OFFSET no_adr

ladr_sib1_1110:
                        DD OFFSET r14_adr
                        DD OFFSET no_adr

ladr_sib1_1111:
                        DD OFFSET r15_adr
                        DD OFFSET no_adr


ladr_sib2_0000:
                        DD OFFSET rax_adr
                        DD OFFSET no_adr

ladr_sib2_0001:
                        DD OFFSET rcx_adr
                        DD OFFSET no_adr

ladr_sib2_0010:
                        DD OFFSET rdx_adr
                        DD OFFSET no_adr

ladr_sib2_0011:
                        DD OFFSET rbx_adr
                        DD OFFSET no_adr

ladr_sib2_0100:
                        DD OFFSET rsp_adr
                        DD OFFSET no_adr

ladr_sib2_0101:
                        DD OFFSET rbp_adr
                        DD OFFSET no_adr

ladr_sib2_0110:
                        DD OFFSET rsi_adr
                        DD OFFSET no_adr

ladr_sib2_0111:
                        DD OFFSET rdi_adr
                        DD OFFSET no_adr

ladr_sib2_1000:
                        DD OFFSET r8_adr
                        DD OFFSET no_adr

ladr_sib2_1001:
                        DD OFFSET r9_adr
                        DD OFFSET no_adr

ladr_sib2_1010:
                        DD OFFSET r10_adr
                        DD OFFSET no_adr

ladr_sib2_1011:
                        DD OFFSET r11_adr
                        DD OFFSET no_adr

ladr_sib2_1100:
                        DD OFFSET r12_adr
                        DD OFFSET no_adr

ladr_sib2_1101:
                        DD OFFSET r13_adr
                        DD OFFSET no_adr

ladr_sib2_1110:
                        DD OFFSET r14_adr
                        DD OFFSET no_adr

ladr_sib2_1111:
                        DD OFFSET r15_adr
                        DD OFFSET no_adr

long_adr_sib_index_tab:
ladr_sibi_0000:
                        DD OFFSET rax_adr
                        DD OFFSET no_adr

ladr_sibi_0001:
                        DD OFFSET rcx_adr
                        DD OFFSET no_adr

ladr_sibi_0010:
                        DD OFFSET rdx_adr
                        DD OFFSET no_adr

ladr_sibi_0011:
                        DD OFFSET rbx_adr
                        DD OFFSET no_adr

ladr_sibi_0100:
                        DD OFFSET no_adr
                        DD OFFSET no_adr

ladr_sibi_0101:
                        DD OFFSET rbp_adr
                        DD OFFSET no_adr

ladr_sibi_0110:
                        DD OFFSET rsi_adr
                        DD OFFSET no_adr

ladr_sibi_0111:
                        DD OFFSET rdi_adr
                        DD OFFSET no_adr

ladr_sibi_1000:
                        DD OFFSET r8_adr
                        DD OFFSET no_adr

ladr_sibi_1001:
                        DD OFFSET r9_adr
                        DD OFFSET no_adr

ladr_sibi_1010:
                        DD OFFSET r10_adr
                        DD OFFSET no_adr

ladr_sibi_1011:
                        DD OFFSET r11_adr
                        DD OFFSET no_adr

ladr_sibi_1100:
                        DD OFFSET r12_adr
                        DD OFFSET no_adr

ladr_sibi_1101:
                        DD OFFSET r13_adr
                        DD OFFSET no_adr

ladr_sibi_1110:
                        DD OFFSET r14_adr
                        DD OFFSET no_adr

ladr_sibi_1111:
                        DD OFFSET r15_adr
                        DD OFFSET no_adr

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

code ENDS                        

        END
