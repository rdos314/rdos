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
; DOS.ASM
; DOS emulation.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE dos.inc

mode_vm EQU 2
mode_pm EQU 0

    .386p


code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn init_ems:near
    extrn init_multiplx:near
    extrn init_xms:near

    extrn init_dosdev:near
    extrn init_dos_mem:near
    extrn init_dosvm:near
    extrn init_dos16:near
    extrn init_dos32:near
    extrn init_dos_exec:near

    extrn init_process_mem:near
    extrn free_app_mem:near

    public doscallback_start
    public doscallback_end
    public case_map
    public ucase_tab
    public file_ucase_tab
    public collate_tab

doscallback_start:

ucase_tab:
    dw      80h
    db      80h,    9Ah,    'E',    'A',    8Eh,    'A',    8Fh,    80h
    db      'E',    'E',    'E',    'I',    'I',    'I',    8Eh,    8Fh
    db      90h,    92h,    92h,    'O',    99h,    'O',    'U',    'U'
    db      'Y',    99h,    9Ah,    9Bh,    9Ch,    9Dh,    9Eh,    9Fh
    db      'A',    'I',    'O',    'U',    0A5h,   0A5h,   0A6h,   0A7h
    db      0A8h,   0A9h,   0AAh,   0ABh,   0ACh,   0ADh,   0AEh,   0AFh
    db      0B0h,   0B1h,   0B2h,   0B3h,   0B4h,   0B5h,   0B6h,   0B7h
    db      0B8h,   0B9h,   0BAh,   0BBh,   0BCh,   0BDh,   0BEh,   0BFh
    db      0C0h,   0C1h,   0C2h,   0C3h,   0C4h,   0C5h,   0C6h,   0C7h
    db      0C8h,   0C9h,   0CAh,   0CBh,   0CCh,   0CDh,   0CEh,   0CFh
    db      0D0h,   0D1h,   0D2h,   0D3h,   0D4h,   0D5h,   0D6h,   0D7h
    db      0D8h,   0D9h,   0DAh,   0DBh,   0DCh,   0DDh,   0DEh,   0DFh
    db      0E0h,   0E1h,   0E2h,   0E3h,   0E4h,   0E5h,   0E6h,   0E7h
    db      0E8h,   0E9h,   0EAh,   0EBh,   0ECh,   0EDh,   0EEh,   0EFh
    db      0F0h,   0F1h,   0F2h,   0F3h,   0F4h,   0F5h,   0F6h,   0F7h
    db      0F8h,   0F9h,   0FAh,   0FBh,   0FCh,   0FDh,   0FEh,   0FFh

file_ucase_tab:
    dw      80h
    db      80h,    9Ah,    90h,    5Fh,    8Eh,    5Fh,    8Fh,    80h
    db      5Fh,    5Fh,    5Fh,    5Fh,    5Fh,    5Fh,    8Eh,    8Fh
    db      90h,    92h,    92h,    5Fh,    99h,    5Fh,    5Fh,    5Fh
    db      5Fh,    99h,    9Ah,    9Bh,    9Ch,    9Dh,    9Eh,    9Fh
    db      5Fh,    5Fh,    5Fh,    5Fh,    0A5h,   0A5h,   0A6h,   0A7h        
    db      0A8h,   0A9h,   0AAh,   0ABh,   0ACh,   0ADh,   0AEh,   0AFh
    db      0B0h,   0B1h,   0B2h,   0B3h,   0B4h,   0B5h,   0B6h,   0B7h
    db      0B8h,   0B9h,   0BAh,   0BBh,   0BCh,   0BDh,   0BEh,   0BFh
    db      0C0h,   0C1h,   0C2h,   0C3h,   0C4h,   0C5h,   0C6h,   0C7h
    db      0C8h,   0C9h,   0CAh,   0CBh,   0CCh,   0CDh,   0CEh,   0CFh
    db      0D0h,   0D1h,   0D2h,   0D3h,   0D4h,   0D5h,   0D6h,   0D7h
    db      0D8h,   0D9h,   0DAh,   0DBh,   0DCh,   0DDh,   0DEh,   0DFh
    db      0E0h,   0E1h,   0E2h,   0E3h,   0E4h,   0E5h,   0E6h,   0E7h
    db      0E8h,   0E9h,   0EAh,   0EBh,   0ECh,   0EDh,   0EEh,   0EFh
    db      0F0h,   0F1h,   0F2h,   0F3h,   0F4h,   0F5h,   0F6h,   0F7h
    db      0F8h,   0F9h,   0FAh,   0FBh,   0FCh,   0FDh,   0FEh,   0FFh

collate_tab:
    dw      100h
    db      0,          1,          2,          3,          4,          5,          6,          7
    db      8,          9,          0Ah,    0Bh,    0Ch,    0Dh,    0Eh,    0Fh
    db      10h,    11h,    12h,    13h,    14h,    15h,    16h,    17h
    db      18h,    19h,    1Ah,    1Bh,    1Ch,    1Dh,    1Eh,    1Fh
    db      20h,    21h,    22h,    23h,    24h,    25h,    26h,    27h
    db      28h,    29h,    2Ah,    2Bh,    2Ch,    2Dh,    2Eh,    2Fh
    db      30h,    31h,    32h,    33h,    34h,    35h,    36h,    37h
    db      38h,    39h,    3Ah,    3Bh,    3Ch,    3Dh,    3Eh,    3Fh
    db      40h,    41h,    42h,    43h,    44h,    45h,    46h,    47h
    db      48h,    49h,    4Ah,    4Bh,    4Ch,    4Dh,    4Eh,    4Fh
    db      50h,    51h,    52h,    53h,    54h,    55h,    56h,    57h
    db      58h,    59h,    5Ah,    5Bh,    5Ch,    5Dh,    5Eh,    5Fh
    db      60h,    41h,    42h,    43h,    44h,    45h,    46h,    47h
    db      48h,    49h,    4Ah,    4Bh,    4Ch,    4Dh,    4Eh,    4Fh
    db      50h,    51h,    52h,    53h,    54h,    55h,    56h,    57h
    db      58h,    59h,    5Ah,    7Bh,    7Ch,    7Dh,    7Eh,    7Fh
    db      43h,    55h,    45h,    41h,    41h,    41h,    41h,    43h
    db      45h,    45h,    45h,    49h,    49h,    49h,    41h,    41h
    db      45h,    41h,    41h,    4Fh,    4Fh,    4Fh,    55h,    55h
    db      59h,    4Fh,    55h,    24h,    24h,    24h,    24h,    24h
    db      41h,    49h,    4Fh,    55h,    4Eh,    4Eh,    0A6h,   0A7h
    db      3Fh,    0A9h,   0AAh,   0ABh,   0ACh,   21h,    22h,    22h
    db      0B0h,   0B1h,   0B2h,   0B3h,   0B4h,   0B5h,   0B6h,   0B7h
    db      0B8h,   0B9h,   0BAh,   0BBh,   0BCh,   0BDh,   0BEh,   0BFh
    db      0C0h,   0C1h,   0C2h,   0C3h,   0C4h,   0C5h,   0C6h,   0C7h
    db      0C8h,   0C9h,   0CAh,   0CBh,   0CCh,   0CDh,   0CEh,   0CFh
    db      0D0h,   0D1h,   0D2h,   0D3h,   0D4h,   0D5h,   0D6h,   0D7h
    db      0D8h,   0D9h,   0DAh,   0DBh,   0DCh,   0DDh,   0DEh,   0DFh
    db      0E0h,   53h,    0E2h,   0E3h,   0E4h,   0E5h,   0E6h,   0E7h
    db      0E8h,   0E9h,   0EAh,   0EBh,   0ECh,   0EDh,   0EEh,   0EFh
    db      0F0h,   0F1h,   0F2h,   0F3h,   0F4h,   0F5h,   0F6h,   0F7h
    db      0F8h,   0F9h,   0FAh,   0FBh,   0FCh,   0FDh,   0FEh,   0FFh

case_map:
    cmp al,80h
    jnc map_high
    retf
map_high:
    sub al,80h
    push bx
    mov bx,OFFSET ucase_tab+2
    xlat byte ptr cs:ucase_tab
    pop bx
    retf
doscallback_end:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CREATE_ENVIROMENT
;
;           DESCRIPTION:    CREATE ENVIROMENT
;
;           PARAMETERS:         DS:ESI      App name
;                           BX              Old environment segment or 0
;
;           RETURNS:        BX              New environment segment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public create_enviroment

create_enviroment       PROC near
    push es
    push fs
    push ax
    push cx
    push esi
    push edi
;
    GetThread
    mov fs,ax
    mov fs,fs:p_prog_sel
;    
    mov ax,bx
    LockProcEnv
    or ax,ax
    jz create_env_start
;
    mov bx,ax
    cmp fs:dpr_psp_mode,mode_pm
    jz create_env_start
;
    SegmentToSelector

create_env_start:    
    push ds
    push esi
    xor cx,cx
not_load_com_start:
    inc cx
    lods byte ptr [esi]
    or al,al
    jnz not_load_com_start
        
create_env_check_mode:
    mov ds,bx
    xor esi,esi
create_env_find_sep:
    lodsb
    or al,al
    jne create_env_find_sep
    lodsb
    or al,al
    jne create_env_find_sep
    movzx eax,cx
    add ax,si
    add ax,5
    push edx
    AllocateDosLinear
    jc create_env_fail
    mov ax,flat_sel
    mov es,ax
    mov edi,edx
    mov ebx,edi
    shr ebx,4
    pop edx
    push cx
    mov ecx,esi
    xor esi,esi
    rep movs byte ptr es:[edi],ds:[esi]
    pop cx
    cmp fs:dpr_psp_mode,mode_pm
    jz create_env_no_free
;
    mov ax,ds
    test al,3
    jz create_env_no_free
;
    push es
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeSelector
    pop es

create_env_no_free:
    pop esi
    pop ds
    mov ax,1
    stos word ptr es:[edi]
    rep movs byte ptr es:[edi],ds:[esi]
    clc
    jmp create_env_done

create_env_fail:
    pop edx
    cmp fs:dpr_psp_mode,mode_pm
    jz create_env_no_fail_free
    push es
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeSelector
    pop es
create_env_no_fail_free:
    pop esi
    pop ds
    stc

create_env_done:
    pushf
    UnlockProcEnv
    popf
;
    pop edi
    pop esi
    pop cx
    pop ax
    pop fs
    pop es
    ret
create_enviroment       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_PSP
;
;           DESCRIPTION:    Read PSP
;
;           PARAMETERS:         BX              PSP
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_psp_name    DB 'Get Psp',0

get_psp_gate    PROC far
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel 
    mov bx,ds:dpr_vm_psp_seg
;
    pop ax      
    pop ds
    retf32
get_psp_gate    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_PSP
;
;           DESCRIPTION:    Write PSP
;
;           PARAMETERS:         BX              PSP
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_psp_name    DB 'Set Psp',0

set_psp_gate    PROC far
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel 
    mov ds:dpr_vm_psp_seg,bx
;
    pop ax
    pop ds
    retf32
set_psp_gate    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_PSP_SEL
;
;           DESCRIPTION:    Read protected mode PSP
;
;           PARAMETERS:         BX              PSP
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_psp_sel_name    DB 'Get Psp Sel',0

get_psp_sel     PROC far
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel 
    mov bx,ds:dpr_pm_psp_sel
;
    pop ax      
    pop ds
    retf32
get_psp_sel     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CLEAR_PSP
;
;           DESCRIPTION:    Clear PSP selectors
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public clear_psp

clear_psp       PROC near
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov ds:dpr_vm_psp_seg,0
    mov ds:dpr_pm_psp_sel,0
    mov ds:dpr_psp_mode,mode_vm
;
    pop ax
    pop ds
    ret
clear_psp       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_VIRT_PSP
;
;           DESCRIPTION:    Get V86 mode PSP
;
;           PARAMETERS:         BX          PSP segment
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_virt_psp

get_virt_psp    PROC near
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov bx,ds:dpr_vm_psp_seg
;
    pop ax
    pop ds
    ret
get_virt_psp    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_VIRT_PSP
;
;           DESCRIPTION:    Set V86 mode PSP
;
;           PARAMETERS:         BX          PSP segment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public set_virt_psp

set_virt_psp    PROC near
    push ds
    push ax
    push bx
    push edx
;       
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov ds:dpr_vm_psp_seg,bx
    cmp ds:dpr_psp_mode,mode_pm
    je set_virt_psp_nofree
;
    push bx
    mov bx,ds:dpr_pm_psp_sel
    and bx,0FFF8h
    FreeLdt
    pop bx

set_virt_psp_nofree:
    movzx edx,bx
    shl edx,4
    push ds
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    AllocateLdt
    mov word ptr [bx],0FFh
    mov [bx+2],edx
    mov byte ptr [bx+5],0F2h
    mov word ptr [bx+6],0
    or bx,7
    pop ds
    mov ds:dpr_pm_psp_sel,bx
    mov ds:dpr_psp_mode,mode_vm
;       
    pop edx
    pop bx
    pop ax
    pop ds
    ret
set_virt_psp    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_PROT_PSP
;
;           DESCRIPTION:    Get protected mode PSP
;
;           PARAMETERS:         BX          PSP selector
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_prot_psp

get_prot_psp    PROC near
    push ds
    push ax
;       
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov bx,ds:dpr_pm_psp_sel
;
    pop ax
    pop ds
    ret
get_prot_psp    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_PROT_PSP
;
;           DESCRIPTION:    Set protected mode PSP
;
;           PARAMETERS:         BX          PSP selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public set_prot_psp

set_prot_psp    PROC near
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov ds:dpr_pm_psp_sel,bx
    mov ds:dpr_psp_mode,mode_pm
;
    pop ax
    pop ds
    ret
set_prot_psp    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_VIRT_DTA
;
;           DESCRIPTION:    Get V86 mode DTA
;
;           RETURNS:        DX:BX   DTA address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_virt_dta

get_virt_dta    PROC near
    push ds
    push ax
;       
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov dx,ds:dpr_vm_dta_seg
    mov bx,word ptr ds:dpr_dta_offset
;
    pop ax      
    pop ds
    ret
get_virt_dta    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_VIRT_DTA
;
;           DESCRIPTION:    Set V86 mode DTA
;
;           PARAMETERS:         DX:BX   DTA address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public set_virt_dta

set_virt_dta    PROC near
    push ds
    push ax
    push bx
    push edx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov ds:dpr_vm_dta_seg,dx
    mov word ptr ds:dpr_dta_offset,bx
    mov word ptr ds:dpr_dta_offset+2,0
    mov bx,dx
    cmp ds:dpr_dta_mode,mode_pm
    je set_virt_dta_nofree
;
    push bx
    mov bx,ds:dpr_pm_dta_sel
    and bx,0FFF8h
    FreeLdt
    pop bx

set_virt_dta_nofree:
    movzx edx,bx
    shl edx,4
    push ds
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    AllocateLdt
    mov word ptr [bx],0FFFFh
    mov [bx+2],edx
    mov byte ptr [bx+5],0F2h
    mov word ptr [bx+6],0
    or bx,7
    pop ds
    mov ds:dpr_pm_dta_sel,bx
    mov ds:dpr_dta_mode,mode_vm
;
    pop edx
    pop bx
    pop ax
    pop ds
    ret
set_virt_dta    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_PROT_DTA
;
;           DESCRIPTION:    Get protected mode DTA
;
;           RETURNS:        DX:EBX  DTA selector:offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_prot_dta

get_prot_dta    PROC near
    push ds
    push ax
;       
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov dx,ds:dpr_pm_dta_sel
    mov ebx,ds:dpr_dta_offset
;
    pop ax
    pop ds
    ret
get_prot_dta    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_PROT_DTA
;
;           DESCRIPTION:    Set protected mode DTA
;
;           PARAMETERS:         DX:EBX  DTA selector:offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public set_prot_dta

set_prot_dta    PROC near
    push ds
    push ax
    push bx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel 
    mov ds:dpr_dta_mode,mode_pm
    mov ds:dpr_pm_dta_sel,dx
    mov ds:dpr_dta_offset,ebx
;       
    pop bx
    pop ax
    pop ds
    ret
set_prot_dta    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_FIND_SEL
;
;           DESCRIPTION:    Gets find first/next selector
;
;           RETURNS:        BX          Dir handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_find_sel

get_find_sel    Proc near
    push ds
    push ax
;       
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov bx,ds:dpr_find_sel
;
    pop ax      
    pop ds
    ret
get_find_sel    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_FIND_SEL
;
;           DESCRIPTION:    Sets find first/next selector
;
;           PARAMETERS:         BX          Dir handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public set_find_sel

set_find_sel    Proc near
    push ds
    push ax
;       
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov ds:dpr_find_sel,bx
;
    pop ax
    pop ds
    ret
set_find_sel    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RESET_FIND_SEL
;
;           DESCRIPTION:    Resets find first/next selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public reset_find_sel

reset_find_sel  Proc near
    push ds
    push es
    push ax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov ax,ds:dpr_find_sel
    or ax,ax
    jz reset_find_done
;
    mov es,ax
    FreeMem
    mov ds:dpr_find_sel,0

reset_find_done:
    pop ax
    pop es
    pop ds
    ret
reset_find_sel  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEFAULT_PSP
;
;           DESCRIPTION:    Create default PSP segment
;
;           PARAMETERS:         ES          Selector to PSP
;                           AX          Environment segment
;                           BX          PSP segment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public default_psp

default_psp     PROC near
    push ds
    push ax
    push bx
    push cx
    push dx
    push di
;
    push ax
    push bx
    xor di,di
    mov ax,20CDh
    stosw
    mov ax,0A000h
    stosw
    xor al,al
    stosb
    mov al,9Ah
    stosb
    mov ax,-1
    stosw
    stosw
    mov al,22h
    GetVMInt
    mov ax,bx
    stosw
    mov ax,dx
    stosw
    mov al,23h
    GetVMInt
    mov ax,bx
    stosw
    mov ax,dx
    stosw
    mov al,24h
    GetVMInt
    mov ax,bx
    stosw
    mov ax,dx
    stosw
    pop bx
    mov ax,bx
    stosw
    mov al,1
    stosb
    stosb
    stosb
    mov al,0
    stosb
    mov al,2
    stosb
    mov al,0FFh
    mov cx,15
    rep stosb
    pop ax
    stosw
    mov ax,-1
    stosw
    stosw
    mov ax,20
    stosw
    mov ax,18h
    stosw
    mov ax,bx
    stosw
    xor ax,ax
    mov cx,12
    rep stosw
    mov ax,21CDh
    stosw
    mov al,0CBh
    stosb
    xor al,al
    mov cx,9
    rep stosb
    mov al,' '
    mov cx,11
    rep stosb
    xor al,al
    mov cx,5
    rep stosb
    mov al,' '
    mov cx,11
    rep stosb
    xor al,al
    mov cx,9
    rep stosb       
;
    mov dx,fixed_vm_linear SHR 4
    mov bx,22h*4
    mov al,22h
    SetVMInt
    mov bx,23h*4
    mov al,23h
    SetVMInt
    mov bx,24h*4
    mov al,24h
    SetVMInt
;
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    pop ds
    ret
default_psp     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreatePsp
;
;           DESCRIPTION:    Create PSP
;
;           PARAMETERS:         AX          Environment segment
;                           BX          PSP segment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public create_psp

create_psp      PROC near
    push ds
    push es
    push ax
    push bx
    push cx
    push dx
    push di
;
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    pop ax
;    
    push ds:dpr_vm_psp_seg
    push ax
    push bx
;
    movzx edx,bx
    shl edx,4
    mov ds:dpr_vm_psp_seg,bx
    cmp ds:dpr_psp_mode,mode_pm
    je create_psp_virt_psp_nofree
;
    mov bx,ds:dpr_pm_psp_sel
    or bx,bx
    jz create_psp_virt_psp_nofree
;
    and bx,0FFF8h
    FreeLdt

create_psp_virt_psp_nofree:
    push ds
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    AllocateLdt
    mov word ptr [bx],0FFh
    mov [bx+2],edx
    mov byte ptr [bx+5],0F2h
    mov word ptr [bx+6],0
    or bx,7
    pop ds
    mov ds:dpr_pm_psp_sel,bx
    mov ds:dpr_psp_mode,mode_vm
;
    mov es,bx
    xor di,di
    mov ax,20CDh
    stosw
    mov ax,0A000h
    stosw
    xor al,al
    stosb
    mov al,9Ah
    stosb
    mov ax,-1
    stosw
    stosw
    mov al,22h
    GetVMInt
    mov ax,bx
    stosw
    mov ax,dx
    stosw
    mov al,23h
    GetVMInt
    mov ax,bx
    stosw
    mov ax,dx
    stosw
    mov al,24h
    GetVMInt
    mov ax,bx
    stosw
    mov ax,dx
    stosw
    pop bx
    mov ax,bx
    stosw
    mov al,1
    stosb
    stosb
    stosb
    mov al,0
    stosb
    mov al,2
    stosb
    mov al,0FFh
    mov cx,15
    rep stosb
    pop ax
    stosw
    mov ax,-1
    stosw
    stosw
    mov ax,20
    stosw
    mov ax,18h
    stosw
    mov ax,bx
    stosw
    xor ax,ax
    mov cx,12
    rep stosw
    mov ax,21CDh
    stosw
    mov al,0CBh
    stosb
    xor al,al
    mov cx,9
    rep stosb
    mov al,' '
    mov cx,11
    rep stosb
    xor al,al
    mov cx,5
    rep stosb
    mov al,' '
    mov cx,11
    rep stosb
    xor al,al
    mov cx,9
    rep stosb       
;
    mov dx,fixed_vm_linear SHR 4
    mov bx,22h*4
    mov al,22h
    SetVMInt
    mov bx,23h*4
    mov al,23h
    SetVMInt
    mov bx,24h*4
    mov al,24h
    SetVMInt
;
    mov bx,ds:dpr_vm_psp_seg
    push ds
    mov ax,flat_sel
    mov ds,ax
    movzx eax,bx
    dec ax
    shl eax,4
    mov [eax+1],bx
    pop ds
;
    mov ds:dpr_vm_dta_seg,bx
    mov ds:dpr_dta_offset,80h
    movzx edx,bx
    shl edx,4
    cmp ds:dpr_dta_mode,mode_pm
    je create_psp_virt_dta_nofree
;
    mov bx,ds:dpr_pm_dta_sel
    or bx,bx
    jz create_psp_virt_dta_nofree
;
    and bx,0FFF8h
    FreeLdt

create_psp_virt_dta_nofree:
    push ds
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    AllocateLdt
    mov word ptr [bx],0FFFFh
    mov [bx+2],edx
    mov byte ptr [bx+5],0F2h
    mov word ptr [bx+6],0
    or bx,7
    pop ds
    mov ds:dpr_pm_dta_sel,bx
    mov ds:dpr_dta_mode,mode_vm
;
    pop bx
    mov es:psp_parent,bx
;
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
    ret
create_psp      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           UNLOAD_PROGRAM
;
;           DESCRIPTION:    Unload program
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unload_program  Proc near
    push ds
    push es
    pusha
;
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov bx,ds:dpr_pm_psp_sel
    or bx,bx
    jz unload_program_done
;
    mov es,bx
    mov bx,es:psp_handleads
    mov dx,es:psp_handlesize
unload_close_loop:
    mov al,es:[bx]
    cmp al,3
    jc unload_close_next
;
    test al,80h
    jnz unload_close_next
;
    push bx
    movzx bx,al
    CloseFile
    pop bx
    mov di,es:psp_handleads
    mov cx,es:psp_handlesize
unload_close_free_loop:
    repne scasb
    jne unload_close_next
;
    mov byte ptr es:[di-1],0FFh
    or cx,cx
    jnz unload_close_free_loop

unload_close_next:
    inc bx
    sub dx,1
    jnz unload_close_loop

unload_program_done:
    popa
    pop es
    pop ds
    ret
unload_program  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_ALLOCATION_STRAT
;
;           DESCRIPTION:    Get memory allocation strategy
;
;           RETURNS:        AX          Allocation strategy
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_allocation_strat

get_allocation_strat    Proc near
    push ds
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov ax,ds:dpr_vm_mem_strat
    pop ds
    ret
get_allocation_strat    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_ALLOCATION_STRAT
;
;           DESCRIPTION:    Set memory allocation strategy
;
;           PARAMETERS:         AX          Allocation strategy
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public set_allocation_strat

set_allocation_strat    Proc near
    push ds
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    pop ax
    mov ds:dpr_vm_mem_strat,ax
    pop ds
    ret
set_allocation_strat    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InitProcess
;
;           DESCRIPTION:    Init process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process    Proc far
    call init_process_mem
    retf32
init_process    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           OpenApp
;
;           DESCRIPTION:    Open app callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_app    Proc far
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel    
    mov ds:dpr_psp_mode,mode_vm
    mov ds:dpr_dta_mode,mode_vm
;
    pop ax
    pop ds
    retf32
open_app    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloseApp
;
;           DESCRIPTION:    Close app callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_app       Proc far
    call reset_find_sel
    call unload_program
    call free_app_mem
    retf32
close_app       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init driver
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_psp_gate
    mov edi,OFFSET get_psp_name
    xor cl,cl
    mov ax,get_psp_nr
    RegisterOsGate
;
    mov esi,OFFSET set_psp_gate
    mov edi,OFFSET set_psp_name
    xor cl,cl
    mov ax,set_psp_nr
    RegisterOsGate
;
    mov esi,OFFSET get_psp_sel
    mov edi,OFFSET get_psp_sel_name
    xor dx,dx
    mov ax,get_psp_sel_nr
    RegisterBimodalUserGate
;
    mov edi,OFFSET init_process
    HookCreateProcess
;
    mov eax,SIZE dos_process_seg
    mov bx,dos_process_sel
    AllocateFixedProcessMem
;
    mov eax,OFFSET doscallback_end - OFFSET doscallback_start
    AllocateFixedVMLinear
;
    push edx
    mov eax,OFFSET dos_vm_size
    AllocateFixedVMLinear
    mov bx,dos_vm_sel
    mov ecx,eax
    CreateDataSelector16
;
    mov ds,bx
    mov ds:indos_flag,0
    mov ds:critical_flag,0
    mov ds:control_c_flag,1
    mov ax,system_data_sel
    mov es,ax
    mov ds:dos_first_dpb,-1
    mov ds:dos_first_dpb+2,-1
    mov ds:dos_first_sft,-1
    mov ds:dos_first_sft+2,-1
    mov ds:dos_clock,-1
    mov ds:dos_clock+2,-1
    mov ds:dos_con,-1
    mov ds:dos_con+2,-1
    pop edx
    mov edi,edx
    shr edx,4
    mov ds:dos_callback_seg,dx
    mov ax,cs
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    mov esi,OFFSET doscallback_start
    mov ecx,OFFSET doscallback_end - OFFSET doscallback_start
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov ax,system_data_sel
    mov ds,ax
    mov ds:flat_base,local_page_linear
;    
    call init_dosdev
    call init_ems
    call init_multiplx
    call init_xms
;    
    call init_dos_mem
    call init_dosvm
    call init_dos16
    call init_dos32
    call init_dos_exec
    clc
    ret
init    ENDP

code    ENDS

    END init

