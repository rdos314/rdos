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
; intdeb.asm
; Internal crash debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\core.inc
INCLUDE kdebug.inc
INCLUDE emseg.inc

    .386p

flat_sel = 20h

code    SEGMENT byte public use32 'CODE'

    assume cs:code

    extrn font8x19:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowChar
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowChar Proc near
    push ds
    push es
    pushad
;   
    push eax
    mov ax,mon_system_data_sel
    mov ds,ax
    mov eax,ds:mon_fixed_lfb
    or eax,eax
    pop eax
    jnz scLfb

scText:
    push eax
    mov ax,mon_text_sel
    mov es,ax
;
    mov ax,ds:int_deb_row
    mov cx,80
    mul cx
    add ax,ds:int_deb_col
    add ax,ax
    movzx edi,ax
    pop eax
    mov ah,7
    stosw
    jmp scUpdate

scLfb:
    push eax
    mov ax,mon_flat_sel
    mov es,ax
; 
    mov ax,ds:int_deb_row
    mov cx,19
    mul cx
    movzx eax,ax
    movzx edx,ds:int_deb_col
    shl edx,3
    xchg eax,edx
;
    push eax
    mov eax,ds:efi_scan_size
    mul edx
    mov edi,ds:mon_fixed_lfb
    add edi,eax
    pop eax
    shl eax,2
    add edi,eax
    pop eax
;
    mov ah,19
    mul ah
    movzx ebx,ax
    add ebx,OFFSET font8x19
;
    mov ecx,19

scRowLoop:    
    push ecx
    push edi
    mov ecx,8
    mov al,cs:[ebx]

scLoop:
    test al,80h
    jz scBack

scFore:
    mov edx,dword ptr ds:efi_fore_col
    mov es:[edi],edx
    jmp scNext

scBack:
    mov edx,dword ptr ds:efi_back_col
    mov es:[edi],edx

scNext:
    add edi,4
    shl al,1
;
    loop scLoop    
;
    pop edi
    pop ecx
    add edi,ds:efi_scan_size
    inc ebx
;
    loop scRowLoop    

scUpdate:
    inc ds:int_deb_col
    mov ax,ds:int_deb_col
    cmp ax,80
    jne scDone
;
    mov ds:int_deb_col,0
    inc ds:int_deb_row    

scDone:
    popad        
    pop es
    pop ds
    ret
ShowChar Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Clear
;
;           DESCRIPTION:    Clear screen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Clear Proc near
    push ds
    push es
    pushad
;    
    mov ax,mon_system_data_sel
    mov ds,ax 
    mov eax,ds:mon_fixed_lfb
    or eax,eax
    jnz cLfb

cText:
    xor edi,edi
    mov ax,mon_text_sel
    mov es,ax
    mov ax,0720h
    mov ecx,80 * 24
    rep stosw
    jmp cUpdate

cLfb:
    mov ax,mon_flat_sel
    mov es,ax
;
    mov edi,ds:mon_fixed_lfb
    movzx ecx,ds:efi_height

cLoop:
    push ecx    
    mov ecx,ds:efi_scan_size    
    xor ax,ax
    rep stos byte ptr es:[edi]
    pop ecx
    loop cLoop

cUpdate:
    mov ds:int_deb_col,0
    mov ds:int_deb_row,0
;
    popad
    pop es
    pop ds    
    ret
Clear Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NewLine
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NewLine Proc near
    push ds
    push ax
    push dx
;
    mov ax,mon_system_data_sel
    mov ds,ax

nlRetry:    
    mov al,' '
    call ShowChar
;
    mov dx,ds:int_deb_col
    or dx,dx
    jnz nlRetry
;
    pop dx
    pop ax
    pop ds
    ret
NewLine Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowCodeAsciiz
;
;           DESCRIPTION:    Show asciiz string from code
;
;           PARAMETERS:     CS:ESI      String to add
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowCodeAsciiz   PROC near
    push ax

scaLoop:
    lods cs:[esi]
    or al,al
    jz scaDone
;
    call ShowChar
    jmp scaLoop    

scaDone:
    pop ax
    ret
ShowCodeAsciiz   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowCodeSizeString
;
;           DESCRIPTION:    
;
;           PARAMETERS:     CS:ESI       String
;                           ECX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowCodeSizeString Proc near
    push eax
    push ecx
    push esi
;
    or ecx,ecx
    jz scssDone

scssLoop:
    lods byte ptr cs:[esi]
    call ShowChar
    loop scssLoop    

scssDone:
    pop esi
    pop ecx
    pop eax    
    ret
ShowCodeSizeString Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AL          Byte to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    PROC near
    push ax
    mov ah,al
    and al,0F0h
    rol al,4
    cmp al,0Ah
    jb write_byte_low1
;    
    add al,7

write_byte_low1:
    add al,'0'
    call ShowChar
    mov al,ah
    and al,0Fh
    cmp al,0Ah
    jb write_byte_high1
;    
    add al,7

write_byte_high1:
    add al,'0'
    call ShowChar
    pop ax
    ret
WriteHexByte    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AX          Word to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord    PROC near
    xchg al,ah
    call WriteHexByte
    xchg al,ah
    call WriteHexByte
    ret
WriteHexWord    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:         EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword   PROC near
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    ret
WriteHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteFault
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_code_tab:
ke00    DB 'Divide error            '
ke01    DB 'Single step             '
ke02    DB 'NMI                     '
ke03    DB 'Breakpoint              '
ke04    DB 'Overflow                '
ke05    DB 'Array bounds error      '
ke06    DB 'Invalid OP-code         '
ke07    DB '80387 not present       '
ke08    DB 'Double fault            '
ke09    DB '80387 overrun           '
ke0A    DB 'Invalid TSS             '
ke0B    DB 'Segment not present     '
ke0C    DB 'Stack fault             '
ke0D    DB 'Protection fault        '
ke0E    DB 'Page fault              '
ke0F    DB '                        '
ke10    DB '80387 error             '
ke11    DB 'Cannot emulate          '
ke12    DB 'Cannot emulate 80387    '
ke13    DB 'Now in real mode        '
ke14    DB '----------------------- '
ke15    DB 'Illegal int request     '
ke16    DB 'Undefined method        '
ke17    DB 'Invalid handle          '
ke18    DB 'Invalid selector        '
ke19    DB 'NMI                     '
ke1A    DB 'Crash Gate              '

WriteFault    Proc near
    mov al,' '
    call ShowChar
;
    movzx edx,ds:[ebp].fault_vect
    cmp dl,1Ah
    jbe wfDo
;
    mov dl,14h    

wfDo:
    mov ebx,edx
    add ebx,ebx
    add ebx,ebx
    add ebx,ebx
    mov ecx,ebx
    add ecx,ecx
    add ebx,ecx
    mov esi,OFFSET error_code_tab
    add esi,ebx
    mov ecx,24
    call ShowCodeSizeString
    ret
WriteFault    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteErrorReason
;
;   DESCRIPTION:    Write error reason
;
;   PARAMETERS:     DS:EBP      Regs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ft_idt  DB 'Idt '
ft_ldt  DB 'Ldt '
ft_gdt  DB 'Gdt '

WriteErrorReason     PROC near
    mov eax,ds:[ebp].fault_error
    test ax,2
    jz werNotIdt
;    
    mov esi,OFFSET ft_idt
    jmp werDo
    
werNotIdt:
    mov esi,OFFSET ft_gdt
    test ax,4
    jz werDo
;    
    mov esi,OFFSET ft_ldt

werDo:
    mov ecx,4
    call ShowCodeSizeString
;
    mov eax,ds:[ebp].fault_error
    and ax,0FFF8h
    call WriteHexWord    
    ret
WriteErrorReason     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteEflags
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eflags_tab:
;
;           reset       set
et_cf   DB 'NC ',       'CY '
et_1    DB 0,0,0,       0,0,0
et_pf   DB 'PO ',       'PE '
et_3    DB 0,0,0,       0,0,0
et_af   DB 'NA ',       'AC '
et_5    DB 0,0,0,       0,0,0
et_zf   DB 'NZ ',       'ZR '
et_sf   DB 'PL ',       'NG '
et_tf   DB 0,0,0,       0,0,0
et_if   DB 'DI ',       'EI '
et_df   DB 'UP ',       'DN '
et_of   DB 'NV ',       'OV '
et_12   DB 0,0,0,       0,0,0
et_13   DB 0,0,0,       0,0,0
et_14   DB 'PR ' ,      'NT '
et_15   DB 0,0,0,       0,0,0
et_16   DB 0,0,0,       0,0,0
et_vm   DB 'PM ',       'VM '

iopl_text       DB ' IOPL=',0

WriteEflags     PROC near
    push eax
    push ecx
    push edx
    push esi
;    
    mov eax,dword ptr ds:[ebp].reg_eflags
    mov esi,OFFSET eflags_tab
    mov ecx,18
    
eflags_loop:
    push esi
;    
    mov dl,cs:[esi]
    or dl,dl
    je eflags_next
;
    test al,1
    jz eflags_write_one
;    
    add esi,3

eflags_write_one:
    push ecx
    mov ecx,3
    call ShowCodeSizeString
    pop ecx
    
eflags_next:
    pop esi
;
    shr eax,1
    add esi,6
;
    loop eflags_loop
;
    mov esi,OFFSET iopl_text
    call showCodeAsciiz
;    
    mov ax,word ptr ds:[ebp].reg_eflags
    shr ax,12
    and ax,3
    add al,'0'
    call ShowChar
;
    pop esi
    pop edx
    pop ecx
    pop eax    
    ret
WriteEflags     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteDwordRegs
;
;           DESCRIPTION:    Write 32-bit registers
;
;           PARAMETERS:     CS:ESI       Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fault_reg_tab1:
    DB ' EAX='
    DD OFFSET reg_eax
    DB ' EBX='
    DD OFFSET reg_ebx
    DB ' ECX='
    DD OFFSET reg_ecx
    DB ' EDX='
    DD OFFSET reg_edx
    DB ' ESI='
    DD OFFSET reg_esi
    DB ' EDI='
    DD OFFSET reg_edi
    DB 0
    
fault_reg_tab2:
    DB ' EPC='
    DD OFFSET reg_eip
    DB ' ESP='
    DD OFFSET reg_esp
    DB ' EBP='
    DD OFFSET reg_ebp
    DB 0

WriteDwordRegs  PROC near

dword_write_loop:
    mov al,cs:[esi]
    or al,al
    je dword_write_end
;
    mov ecx,5
    call ShowCodeSizeString
    add esi,5
    mov ebx,cs:[esi]
    mov eax,ds:[ebx+ebp]
    call WriteHexDword
    add esi,4
    jmp dword_write_loop

dword_write_end:
    ret
WriteDwordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteWordRegs
;
;           DESCRIPTION:    Write 16-bit registers
;
;           PARAMETERS:     CS:ESI       Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fault_reg_tab:
    DB ' CS='
    DD OFFSET reg_cs.d_selector
    DB ' SS='
    DD OFFSET reg_ss.d_selector
    DB ' DS='
    DD OFFSET reg_ds.d_selector
    DB ' ES='
    DD OFFSET reg_es.d_selector
    DB ' FS='
    DD OFFSET reg_fs.d_selector
    DB ' GS='
    DD OFFSET reg_gs.d_selector
    DB 0

WriteWordRegs  PROC near

word_write_loop:
    mov al,cs:[esi]
    or al,al
    je word_write_end
;
    mov ecx,4
    call ShowCodeSizeString
    add esi,4
    mov ebx,cs:[esi]
    mov ax,ds:[ebx+ebp]
    call WriteHexWord
    add esi,4
    jmp word_write_loop

word_write_end:
    ret
WriteWordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DumpFault
;
;           DESCRIPTION:    Dump fault
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DumpFault:
    push es
;
    mov ax,mon_data_sel
    mov es,ax
;    
    mov al,byte ptr [ebp].trap_exc_nr
    mov es:fault_vect,al
;
    mov eax,[ebp].trap_err
    mov es:fault_error,eax
;
    mov eax,[ebp].trap_eip
    mov es:reg_eip,eax
;
    mov eax,[ebp].trap_eflags
    mov es:reg_eflags,eax
    mov eax,[ebp].trap_eax
    mov es:reg_eax,eax
    mov es:reg_ecx,ecx
    mov es:reg_edx,edx
    mov eax,[ebp].trap_ebx
    mov es:reg_ebx,eax
    mov eax,ebp
    add eax,20
    mov es:reg_esp,eax
    mov es:reg_esi,esi
    mov es:reg_edi,edi
    mov ax,[ebp].trap_cs
    mov es:reg_cs.d_selector,ax
    mov es:reg_ss.d_selector,ss
    mov ax,[ebp].trap_pds
    mov es:reg_ds.d_selector,ax
    pop ax
    mov es:reg_es.d_selector,ax
    mov es:reg_fs.d_selector,fs
    mov es:reg_gs.d_selector,gs
    mov ebp,[ebp].trap_ebp
    mov es:reg_ebp,ebp
    sldt ax
    mov es:reg_ldt.d_selector,ax       
;
    call Clear
;    
    mov ax,mon_system_data_sel
    mov ds,ax
    mov ds:efi_text_row,20
    mov ds:efi_text_col,0
;    
    mov ax,mon_data_sel
    mov ds,ax
    xor ebp,ebp    
;    
    call WriteFault
    call WriteErrorReason
    call NewLine
;
    mov esi,OFFSET fault_reg_tab1
    call WriteDwordRegs
    call NewLine
;
    mov esi,OFFSET fault_reg_tab2
    call WriteDwordRegs
;
    mov al,' '
    call ShowChar
    call WriteEflags    
    call NewLine
;
    mov esi,OFFSET fault_reg_tab
    call WriteWordRegs
    
fdLoop:
    hlt
    jmp fdLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Fault handlers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cint0:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,0
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint1:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,1
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint3:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,3
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint4:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,4
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint5:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,5
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint6:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,6
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint7:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,7
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint8:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,8
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint9:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,9
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint10:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    push ds
    mov ax,10
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint11:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,11
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint12:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,12
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint13:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,13
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint14:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,14
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

cint16:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,16
    push ax
    mov ax,ds
    push ax
    jmp DumpFault

chwint:
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupInt
;
;           DESCRIPTION:    Create int gate selector
;
;           PARAMETERS:     AL              Int #
;                           ESI             Entry point
;                           EDX             IDT base
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInt     PROC near
    push ds
    push eax
    push ebx
;   
    movzx ebx,al
    shl ebx,3
    add ebx,edx
;
    mov ax,flat_sel
    mov ds,ax    
;    
    mov ax,8E00h
    mov ds:[ebx+4],ax
    mov ds:[ebx],esi
    mov ax,mon_code_sel
    xchg ax,ds:[ebx+2]
    mov ds:[ebx+6],ax
;
    pop ebx
    pop eax
    pop ds
    ret
SetupInt     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          InitMonitorIdt
;
;           DESCRIPTION:   Init monitor IDT
;
;           PARAMETERS:    EDX          IDT base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crash_int_tab:
;
;               int #       Entry          
;
ci0     DD      0,          OFFSET cint0
ci1     DD      1,          OFFSET cint1
ci2     DD      2,          OFFSET chwint
ci3     DD      3,          OFFSET cint3
ci4     DD      4,          OFFSET cint4
ci5     DD      5,          OFFSET cint5
ci6     DD      6,          OFFSET cint6
ci7     DD      7,          OFFSET cint7
ci8     DD      8,          OFFSET cint8
ci9     DD      9,          OFFSET cint9
ci10    DD      10,         OFFSET cint10
ci11    DD      11,         OFFSET cint11
ci12    DD      12,         OFFSET cint12
ci13    DD      13,         OFFSET cint13
ci14    DD      14,         OFFSET cint14
ci16    DD      16,         OFFSET cint16
ci40    DD      40h,        OFFSET chwint
ci80    DD      80h,        OFFSET chwint
ci81    DD      81h,        OFFSET chwint
ci82    DD      82h,        OFFSET chwint
ci83    DD      83h,        OFFSET chwint
ci_end  DD      0FFFFFFFFh

    public InitMonitorIdt

InitMonitorIdt    Proc near
    mov edi,OFFSET crash_int_tab

imiLoop:
    mov ax,cs:[edi]
    cmp ax,0FFFFh
    jz imiDone
;
    xor bl,bl
    mov esi,dword ptr cs:[edi+4]
    call SetupInt
    add edi,8
    jmp imiLoop

imiDone:
    ret
InitMonitorIdt   Endp

code    ENDS

    END
