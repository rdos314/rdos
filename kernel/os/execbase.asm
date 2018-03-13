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
; EXECBASE.ASM
; Basic executable loader support module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE int.def
INCLUDE exec.def
INCLUDE system.inc
INCLUDE ..\fs.inc
INCLUDE ..\wait.inc
INCLUDE chandle.inc

.386p

debug_event_wait_header STRUC

dew_obj             wait_obj_header <>
dew_module_id       DW ?

debug_event_wait_header ENDS

data    SEGMENT byte public 'DATA'

term_gate_sel           DW ?
free_dll_gate_sel       DW ?
exit_gate_sel           DW ?

focus_current_console   DW ?
focus_section           section_typ <>

loader_count            DW ?
loader_arr              DW 16 DUP(?)

focus_console_arr       DW 256 DUP(?)

data    ENDS

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetFocus
;
;           DESCRIPTION:    Set input focus
;
;           PARAMETERS:     AL      KEY NUMBER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_focus_name  DB 'Set Focus',0

set_focus       PROC far
    push ds
    push es
    pushad
;
    mov bx,SEG data
    mov ds,bx
    EnterSection ds:focus_section
;
    movzx bx,al
    add bx,bx
    mov bx,ds:[bx].focus_console_arr
    or bx,bx
    jz set_focus_done
;    
    mov ds:focus_current_console,bx
    SetFocusConsole

set_focus_done:
    LeaveSection ds:focus_section
;
    popad
    pop es
    pop ds
    ret
set_focus       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           EnableFocus
;
;           DESCRIPTION:    Enable focus
;
;           PARAMETERS:     AL      KEY NUMBER
;
;       RETURNS:            AL      Actual key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_focus_name       DB 'Enable Focus',0

enable_focus    PROC far
    push ds
    push bx
    push si
;
    mov bx,SEG data
    mov ds,bx
;
    movzx si,al
    add si,si

enable_focus_loop:
    mov bx,ds:[si].focus_console_arr
    or bx,bx
    jnz enable_focus_next
;
    CreateConsole
    mov ds:[si].focus_console_arr,bx
;
    GetThread
    mov ds,ax
    mov ds:p_console,bx
;
    mov ax,si
    shr ax,1
    clc
    jmp enable_focus_done

enable_focus_next:
    add si,2
    cmp si,200h
    jne enable_focus_loop
;
    stc

enable_focus_done:
    pop si
    pop bx
    pop ds
    ret
enable_focus    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Upper case table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UCaseTab:
ct00 DB 0,          0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct08 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct10 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct18 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct20 DB ' ',    '!',    0FFh,   '#',    '$',    '%',    '&',    27h
ct28 DB '(',    ')',    0FFh,   0FFh,   0FFh,   '-',    0,          '/'
ct30 DB '0',    '1',    '2',    '3',    '4',    '5',    '6',    '7'
ct38 DB '8',    '9',    0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct40 DB '@',    'A',    'B',    'C',    'D',    'E',    'F',    'G'
ct48 DB 'H',    'I',    'J',    'K',    'L',    'M',    'N',    'O'
ct50 DB 'P',    'Q',    'R',    'S',    'T',    'U',    'V',    'W'
ct58 DB 'X',    'Y',    'Z',    0FFh,   '\',    0FFh,   '^',    '_'
ct60 DB 60h,    'A',    'B',    'C',    'D',    'E',    'F',    'G'
ct68 DB 'H',    'I',    'J',    'K',    'L',    'M',    'N',    'O'
ct70 DB 'P',    'Q',    'R',    'S',    'T',    'U',    'V',    'W'
ct78 DB 'X',    'Y',    'Z',    '{',    0FFh,   '}',    '~',    0FFh
ct80 DB 0FFh,   0FFh,   0FFh,   0FFh,   'é',    0FFh,   'è',    0FFh
ct88 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   'é',    'è'
ct90 DB 0FFh,   0FFh,   0FFh,   0FFh,   'ô',    0FFh,   0FFh,   0FFh
ct98 DB 0FFh,   'ô',    0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctA0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctA8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctB0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctB8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctC0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctC8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctD0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctD8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctE0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctE8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctF0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctF8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitProgramBlock
;
;       DESCRIPTION:    Init program block
;
;       PARAMETERS:     GS      Program sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitProgramBlock Proc near    
    mov gs:pr_name_sel,0
    mov gs:pr_cmd_sel,0
    mov gs:pr_dir_sel,0
    mov gs:pr_env_sel,0
    mov gs:pr_cmd_sel,0
    mov gs:pr_debug_id,0
    mov gs:pr_thread,0
    mov gs:pr_bitness,0
    mov gs:pr_module_count,0
    mov gs:pr_process_count,0
    mov gs:pr_page_table_count,0
    mov gs:pr_cow_thread,0
    mov gs:pr_cow_counter,0
    mov gs:pr_fault_linear,-1
    mov gs:pr_fault_counter,0
    InitSection gs:pr_section
    InitSection gs:pr_cow_section
    mov gs:pr_memmap_list,0
    InitSpinlock gs:pr_memmap_spinlock
    ret
InitProgramBlock  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateProgram
;
;       DESCRIPTION:    Allocate program
;
;       PARAMETERS:     DX      Debug module ID
;                       GS      Program sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateProgram Proc near    
    push ds
    pushad
;
    movzx ebx,dx
    ModuleIdToSel
    jc apDebugOk
;    
    mov gs:pr_debug_id,dx

apDebugOk:
    popad
    pop ds
    ret
AllocateProgram  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateProg
;
;       DESCRIPTION:    Make global copy of program name
;
;       PARAMETERS:     DS:ESI      Filename
;                       GS          Program sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateProg Proc near
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov edi,esi
    xor ecx,ecx

cprLoop:
    lods byte ptr [esi]
    or al,al
    jz cprSizeOk
;
    inc ecx
    jmp cprLoop

cprSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    mov gs:pr_name_sel,es
;    
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    ret
CreateProg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RemoveProg
;
;       DESCRIPTION:    Remove prog
;
;       PARAMETERS:     BX       Progam ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveProg Proc near
    movzx ebx,bx
    GetProgramSel
    jc rpDone
;
    mov ds,eax
    movzx ebx,ax
    ProgramTerminated
;
    mov es,ds:pr_name_sel
    FreeMem
;
    mov es,ds:pr_cmd_sel
    FreeMem
;
    mov es,ds:pr_dir_sel
    FreeMem
;
    mov es,ds:pr_env_sel
    FreeMem
;
    mov eax,ds
    mov es,eax
    FreeMem

rpDone:
    ret
RemoveProg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddProgramModule
;
;           DESCRIPTION:    Add module to program
;
;           PARAMETERS:     BX      Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddProgramModule    Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
;
    GetThread
    mov es,ax
;
    push ebx
    movzx ebx,es:p_prog_id
    GetProgramSel
    pop ebx
    jc apmDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    movzx ecx,ds:pr_module_count
    cmp ecx,MAX_PROGRAM_MODULES
    jae apmLeave
;
    mov eax,ecx
    shl eax,1
    inc ecx
    mov ds:pr_module_count,cx
;
    mov ds:[eax].pr_module_arr,bx
    
apmLeave:
    LeaveSection ds:pr_section
            
apmDone:
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
AddProgramModule    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddKernelProgramModule
;
;           DESCRIPTION:    Add kernel module to program
;
;           PARAMETERS:     BX      Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddKernelProgramModule    Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
;
    push ebx
    mov ebx,1
    GetProgramSel
    pop ebx
    jc akpmDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    movzx ecx,ds:pr_module_count
    cmp ecx,MAX_PROGRAM_MODULES
    jae akpmLeave
;
    mov eax,ecx
    shl eax,1
    inc ecx
    mov ds:pr_module_count,cx
;
    mov ds:[eax].pr_module_arr,bx
    
akpmLeave:
    LeaveSection ds:pr_section
            
akpmDone:
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
AddKernelProgramModule    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RemoveProgramModule
;
;           DESCRIPTION:    Remove module from program
;
;           PARAMETERS:     BX      Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveProgramModule    Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
;
    GetThread
    mov es,ax
;
    push ebx
    movzx ebx,es:p_prog_id
    GetProgramSel
    pop ebx
    jc rpmDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    mov ax,bx
    movzx ecx,ds:pr_module_count
    mov ebx,OFFSET pr_module_arr
    or ecx,ecx
    jz rpmLeave

rpmLoop:
    cmp ax,ds:[ebx]
    je rpmFound
;
    add bx,2
    loop rpmLoop
;
    jmp rpmLeave

rpmFound:
    dec ds:pr_module_count
;
    sub ecx,1
    jz rpmLeave

rpmMove:
    mov ax,ds:[ebx+2]
    mov ds:[ebx],ax
    add ebx,2
    loop rpmMove

rpmLeave:
    LeaveSection ds:pr_section
            
rpmDone:
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
RemoveProgramModule    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddProcessModule
;
;           DESCRIPTION:    Add module to process
;
;           PARAMETERS:     BX      Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddProcessModule    Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
;
    GetThread
    mov es,ax
;
    mov ds,es:p_proc_sel
    EnterSection ds:pf_section
;
    movzx ecx,ds:pf_module_count
    cmp ecx,MAX_PROCESS_MODULES
    jae apfmLeave
;
    mov eax,ecx
    shl eax,1
    inc ecx
    mov ds:pf_module_count,cx
;
    mov ds:[eax].pf_module_arr,bx
    mov ds:[eax].pf_module_usage_arr,1
    
apfmLeave:
    LeaveSection ds:pf_section
;
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
AddProcessModule    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RemoveProcessModule
;
;           DESCRIPTION:    Remove module from process
;
;           PARAMETERS:     BX      Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveProcessModule    Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
;
    GetThread
    mov es,ax
    mov ds,es:p_proc_sel
    EnterSection ds:pf_section
;
    mov ax,bx
    movzx ecx,ds:pf_module_count
    mov ebx,OFFSET pf_module_arr
    or ecx,ecx
    jz rpfmLeave

rpfmLoop:
    cmp ax,ds:[ebx]
    je rpfmFound
;
    add bx,2
    loop rpfmLoop
;
    jmp rpfmLeave

rpfmFound:
    dec ds:pf_module_count
;
    sub ecx,1
    jz rpfmLeave

rpfmMove:
    mov ax,ds:[ebx+2]
    mov ds:[ebx],ax
    add ebx,2
    loop rpfmMove

rpfmLeave:
    LeaveSection ds:pf_section
            
rpfmDone:
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
RemoveProcessModule    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IncModuleUsage
;
;           DESCRIPTION:    Increase module usage
;
;           PARAMETERS:     BX      Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IncModuleUsage    Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
;
    GetThread
    mov es,ax
    mov ds,es:p_proc_sel
    EnterSection ds:pf_section
;
    mov ax,bx
    movzx ecx,ds:pf_module_count
    xor ebx,ebx
    or ecx,ecx
    jz imuLeave

imuLoop:
    cmp ax,ds:[ebx].pf_module_arr
    je imuFound
;
    add bx,2
    loop imuLoop
;
    jmp imuLeave

imuFound:
    inc ds:[ebx].pf_module_usage_arr
    
imuLeave:
    LeaveSection ds:pf_section
;
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
IncModuleUsage    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DecModuleUsage
;
;           DESCRIPTION:    Decrease module usage
;
;           PARAMETERS:     BX      Module ID
;
;           RETURNS:        ECX     Usage count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecModuleUsage    Proc near
    push ds
    push es
    push eax
    push ebx
;
    GetThread
    mov es,ax
    mov ds,es:p_proc_sel
    EnterSection ds:pf_section
;
    mov ax,bx
    movzx ecx,ds:pf_module_count
    xor ebx,ebx
    or ecx,ecx
    jz dmuLeave

dmuLoop:
    cmp ax,ds:[ebx].pf_module_arr
    je dmuFound
;
    add bx,2
    loop dmuLoop
;
    xor ecx,ecx
    jmp dmuLeave

dmuFound:
    movzx ecx,ds:[ebx].pf_module_usage_arr
    sub ecx,1
    jc dmuLeave
;
    mov ds:[ebx].pf_module_usage_arr,cx
    
dmuLeave:
    LeaveSection ds:pf_section
;
    pop ebx
    pop eax
    pop es
    pop ds
    ret
DecModuleUsage    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleReferences
;
;           DESCRIPTION:    Get module reference count
;
;           PARAMETERS:     BX      Module ID
;
;           RETURNS:        ECX     References
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetModuleReferences    Proc near
    push ds
    push es
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    mov bp,bx
    xor edx,edx
;
    GetThread
    mov es,ax
    mov ds,es:p_prog_sel
    EnterSection ds:pr_section
    movzx ecx,ds:pr_process_count
    mov esi,OFFSET pr_process_arr

gmrProcLoop:
    push ds
    push ecx
;
    movzx ebx,word ptr ds:[esi]
    ProcessIdToSel
    jc gmrProcNext
;
    mov ds,ebx
    EnterSection ds:pf_section
    movzx ecx,ds:pf_module_count
    mov ebx,OFFSET pf_module_arr

gmrModuleLoop:
    cmp bp,ds:[ebx]
    jne gmrModuleNext
;
    inc edx

gmrModuleNext:
    add ebx,2
    loop gmrModuleLoop
;
    LeaveSection ds:pf_section

gmrProcNext:
    pop ecx
    pop ds
;
    add esi,2
    loop gmrProcLoop
;
    LeaveSection ds:pr_section
    mov ecx,edx
;
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
GetModuleReferences  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenModuleFile
;
;           DESCRIPTION:    Open module file
;
;           PARAMETERS:     DS:ESI  File name
;
;           RETURNS:        BX          C File handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PathName        DB 'PATH',0

OpenModuleFile Proc near       
    push ds
    push es
    push fs
    push eax
    push ecx
    push esi
    push edi
;
    mov eax,ds
    mov es,eax
    mov edi,esi
;
    mov cx,O_RDONLY OR O_BINARY
    OpenKernelFile
    jnc omfDone
;
    mov eax,ds
    mov fs,eax
;
    LockProcEnv
    mov ds,bx
    mov ebx,esi
    xor esi,esi
    mov ax,cs
    mov es,ax
    mov edi,OFFSET PathName

omfFindLoop:
    cmpsb
    jnz omfFindNext
;
    mov al,es:[edi]
    or al,al
    jnz omfFindLoop
;
    mov al,[esi]
    cmp al,'='
    je omfFindFound

omfFindNext:
    lodsb
    or al,al
    jnz omfFindNext
;
    mov al,[esi]
    or al,al
    mov edi,OFFSET PathName
    jne omfFindLoop
    jmp omfFailed

omfFindFound:
    mov eax,200h
    AllocateSmallGlobalMem
;
    xor edi,edi
    inc esi

omfMoveLoop:
    lodsb
    or al,al
    jz omfMoveOk
;
    cmp al,';'
    je omfMoveOk
;
    stosb
    jmp omfMoveLoop 

omfMoveOk:
    or edi,edi
    jz omfAddFile
;    
    mov al,es:[edi-1]
    cmp al,'\'
    je omfAddFile
;
    cmp al,'/'
    je omfAddFile
;
    cmp al,':'
    je omfAddFile
;
    mov al,'\'
    stosb
    
omfAddFile:    
    push ebx

omfNameLoop:
    mov al,fs:[ebx]
    inc ebx
    stosb
    or al,al
    jnz omfNameLoop
;
    pop ebx
;
    push bx
    xor edi,edi
    mov cx,O_RDONLY OR O_BINARY
    OpenKernelFile
    jnc omfFileOk
;
    pop bx
    mov al,[esi-1]
    or al,al
    jnz omfMoveLoop
;
    FreeMem

omfFailed:
    stc
    jmp omfUnlock

omfFileOk:
    add esp,2
    FreeMem
    clc
    
omfUnlock:
    pushf
    UnlockProcEnv
    popf

omfDone:
    pop edi
    pop esi
    pop ecx
    pop eax
    pop fs
    pop es
    pop ds
    ret
OpenModuleFile Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetProgramLoader
;
;       DESCRIPTION:    Get program loader
;
;       PARAMETERS:     DS:ESI  File name
;
;       RETURNS:        AX      Loader
;                       GS      Program sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetProgramLoader Proc near
    push ds
    push es
    push fs
    push ecx
    push esi
    push edi
;
    mov eax,ds
    mov es,eax
    mov edi,esi
;
    mov ax,SEG data
    mov fs,ax
    movzx ecx,fs:loader_count
    or ecx,ecx
    je gplFail
;
    mov esi,OFFSET loader_arr

gplLoop:
    mov ds,fs:[esi]
    call fword ptr ds:loader_is_valid_exe_proc
    jnc gplOk
;
    add esi,2
    loop gplLoop

gplFail:
    stc
    jmp gplDone

gplOk:
    mov ax,fs:[esi]
    clc

gplDone:
    pop edi
    pop esi
    pop ecx
    pop fs
    pop es
    pop ds
    ret
GetProgramLoader Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateNoParam
;
;       DESCRIPTION:    Make global copy of empty parameters
;
;       PARAMETERS:     GS          Program sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateNoParam Proc near
    push es
    push eax
    push ecx
    push edi
;
    mov eax,1
    AllocateSmallGlobalMem
    xor edi,edi
    xor al,al
    stos byte ptr es:[edi]
    mov gs:pr_cmd_sel,es
;       
    pop edi
    pop ecx
    pop eax
    pop es
    ret
CreateNoParam Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateParam
;
;       DESCRIPTION:    Make global copy of parameters
;
;       PARAMETERS:     DS:ESI      Param pointer
;                       GS          Program sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateParam Proc near
    push es
    push eax
    push ecx
    push edi
;
    mov edi,esi
    xor ecx,ecx

cpaLoop:
    lods byte ptr [esi]
    or al,al
    jz cpaSizeOk
;
    inc ecx
    jmp cpaLoop

cpaSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    mov gs:pr_cmd_sel,es
;       
    pop edi
    pop ecx
    pop eax
    pop es
    ret
CreateParam Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateDefaultStartDir
;
;       DESCRIPTION:    Make global copy of default directory
;
;       PARAMETERS:     GS          Program sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDefaultStartDir Proc near
    push es
    push eax
    push ecx
    push edi
;
    mov eax,256
    AllocateSmallGlobalMem
    xor edi,edi
    GetCurDrive
    mov ah,al
    add al,'A'
    stos byte ptr es:[edi]
;
    mov al,':'
    stos byte ptr es:[edi]
;
    mov al,'\'
    stos byte ptr es:[edi]
;
    mov al,ah
    GetCurDir
;
    mov gs:pr_dir_sel,es
;       
    pop edi
    pop ecx
    pop eax
    pop es
    ret
CreateDefaultStartDir Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateStartDir
;
;       DESCRIPTION:    Make global copy of start dir
;
;       PARAMETERS:     DS:ESI      Startup dir
;                       GS          Program sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateStartDir Proc near
    push es
    push eax
    push ecx
    push edi
;
    mov edi,esi
    xor ecx,ecx

csdLoop:
    lods byte ptr [esi]
    or al,al
    jz csdSizeOk
;
    inc ecx
    jmp csdLoop

csdSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    mov gs:pr_dir_sel,es
;       
    pop edi
    pop ecx
    pop eax
    pop es
    ret
CreateStartDir Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateDefaultEnv
;
;       DESCRIPTION:    Make global copy of default environment variables
;
;       PARAMETERS:     GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDefaultEnv Proc near
    push es
    push eax
    push ecx
    push edi
;
    OpenProcEnv
    GetEnvSize
    movzx eax,ax
    AllocateSmallGlobalMem
    xor edi,edi
    GetEnvData
    CloseEnv
    mov gs:pr_env_sel,es
;       
    pop edi
    pop ecx
    pop eax
    pop es
    ret
CreateDefaultEnv Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateEnv
;
;       DESCRIPTION:    Put environment variables in program structure
;
;       PARAMETERS:     DS:ESI  Environment ptr
;                       GS      Program sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateEnv Proc near
    push es
    push eax
    push ecx
    push edi
;
    mov edi,esi
    xor ecx,ecx

ceLoop:
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz ceLoop
;
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz ceLoop

ceSizeOk:
    mov esi,edi
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    mov gs:pr_env_sel,es
;       
    pop edi
    pop ecx
    pop eax
    pop es
    ret
CreateEnv Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupStartDir
;
;           DESCRIPTION:    Setup start directory
;
;           PARAMETERS:     GS      Program sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupStartDir Proc near
    push es
    push ax
    push edi
;
    mov es,gs:pr_dir_sel
    xor edi,edi
    mov ax,es:[edi]
    cmp ah,':'
    jne sdDirOk
;
    sub al,'A'
    jc sdDirOk
;
    cmp al,26
    jc sdSetDrive
;
    sub al,20h
    jc sdDirOk
;
    cmp al,26
    jnc sdDirOk

sdSetDrive:
    SetCurDrive
    add edi,2
    SetCurDir
    
sdDirOk:
    pop edi
    pop ax
    pop es
    ret
SetupStartDir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupEnv
;
;           DESCRIPTION:    Setup environment
;
;           PARAMETERS:     GS      Program sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupEnv Proc near
    push es
    push ebx
    push edi
;
    mov es,gs:pr_env_sel
    xor edi,edi
;
    OpenProcEnv
    SetEnvData
    CloseEnv
;
    pop edi
    pop ebx
    pop es
    ret
SetupEnv   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddKernelModule
;
;           DESCRIPTION:    Add kernel module
;
;           PARAMETERS:     BX          Selector
;                           EDX         Base
;                           ECX         Size
;                           ES:EDI      Module name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddKernelModule     PROC near
    push ds
    push es
    pushad
;
    mov eax,es
    mov ds,eax
    mov esi,edi
;
    mov ebp,ecx
    xor ecx,ecx

akmSizeLoop:
    inc ecx
    lodsb
    or al,al
    jne akmSizeLoop
;
    mov eax,SIZE module_struc
    add eax,ecx
    AllocateSmallGlobalMem
    mov es:mod_base,edx
    mov es:mod_base+4,0
    mov es:mod_size,ebp
    mov es:mod_size+4,0
    mov es:mod_sel,bx
    mov es:mod_name_offs,SIZE module_struc
    mov es:mod_loader,0
    mov es:mod_id,0
    InitSection es:mod_section
;
    mov esi,edi
    mov edi,SIZE module_struc
    rep movsb
;
    mov ebx,es
    ModuleLoaded
;
    mov ebx,eax
    call AddKernelProgramModule
;
    popad
    pop es
    pop ds
    ret
AddKernelModule     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SpawnStartup
;
;           DESCRIPTION:    Spawn startup stub
;
;           PARAMETERS:     BX      Program ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

spawn_startup:
    sti
    CreateLdt
    CreateHandleData
;
    GetThread
    mov es,ax
    mov ax,es:p_console
    mov es:p_parent_console,ax
    mov gs,es:p_prog_sel
;
    xor eax,eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
    mov ebp,esp
;
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
;
    GetThread
    mov gs:pr_thread,ax
    mov ds,ax
;
    mov ax,gs:pr_loader
    mov ds:p_loader,ax
;
    mov bx,gs:pr_parent_thread
    Signal
;
    call SetupStartDir
    call SetupEnv
;       
    mov bx,gs:pr_kernel_file
    xor esi,esi
    xor edi,edi
    mov ds,gs:pr_name_sel
    mov es,gs:pr_cmd_sel
;
    mov dx,gs:pr_debug_id
    push gs
    mov gs,gs:pr_loader
    call fword ptr gs:loader_init_exe_proc
    pop gs
    jc spCloseFail
;
    SetBitness
;
    push ds
    push es
    mov es,bx
;
    movzx ebx,bx
    ModuleLoaded
;
    mov ebx,eax
    call AddProgramModule
    call AddProcessModule
;
    InitSection es:mod_section
    mov es:mod_id,bx
;
    mov ax,3Bh
    EnableFocus
    SetFocus
    mov es:mod_key,al
;
    mov bx,es
    pop es
    pop ds
;
    mov dx,gs:pr_debug_id
    mov fs,gs:pr_loader
    call fword ptr fs:loader_fixup_exe_proc
 
spDebugDone:
    test byte ptr [ebp+2].load_eflags,2
    jnz spVm16
;
    mov ds,[ebp].load_ds
    mov es,[ebp].load_es
    mov fs,[ebp].load_fs
    mov gs,[ebp].load_gs

spVm16:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

spCloseFail:
    CloseCFile

spFail:
    int 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetExeStart32
;
;       DESCRIPTION:    Get 32-bit entry-point
;
;       RETURN VALUE:   DS:ESI      Entry point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exe_start32_name  DB 'Get Exe Start32',0

get_exe_start32   Proc far
    mov esi,cs
    mov ds,esi
    mov esi,OFFSET spawn_startup
    ret
get_exe_start32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           spawn_program16/32
;
;       DESCRIPTION:    Load & detach executable file
;
;       PARAMETERS:     DS:(E)SI    Filename
;                       ES:(E)DI    Parameters
;                           +0      command line
;                           +8      startdir
;                           +12     env
;                       DX          Debug module handle
;
;       RETURN VALUE:   AX          Thread ID
;                       DX          Program ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

spawn_exe_name  DB 'Spawn Exe',0

spawn_program   Proc near
    push ds
    push es
    push gs
    push ebx
    push ecx
    push esi
    push edi
;
    call OpenModuleFile
    jc spDone
;
    call GetProgramLoader
    jnc spLoaderOk
;
    CloseCFile
    stc
    jmp spDone

spLoaderOk:    
    call InitProgramBlock
    call AllocateProgram
    mov gs:pr_loader,ax
    mov gs:pr_kernel_file,bx
;
    GetThread
    mov gs:pr_parent_thread,ax
;
    call CreateProg
;
    mov eax,es:[edi].lp_param_sel
    or ax,3
    verr ax
    stc
    jnz spNoParam
;
    mov ds,ax
    mov esi,es:[edi].lp_param_offs
    call CreateParam
    jmp spParamDone

spNoParam:
    call CreateNoParam

spParamDone:
    mov eax,es:[edi].lp_startdir_sel
    or ax,3
    verr ax
    stc
    jnz spNoStartDir
;
    mov ds,ax
    mov esi,es:[edi].lp_startdir_offs
    call CreateStartDir
    jmp spStartDirDone

spNoStartDir:
    call CreateDefaultStartDir

spStartDirDone:
    mov eax,es:[edi].lp_env_sel
    or ax,3
    verr ax
    stc
    jnz spNoEnv
;
    mov ds,ax
    mov esi,es:[edi].lp_env_offs
    call CreateEnv
    jmp spEnvDone

spNoEnv:
    call CreateDefaultEnv

spEnvDone:
    mov ebx,gs
    ProgramCreated
;
    mov ebx,eax
    ClearSignal
;
    mov es,gs:pr_name_sel
    xor edi,edi
    mov ds,gs:pr_loader
    call fword ptr ds:loader_create_process_proc

spWait:    
    WaitForSignal
    mov ax,gs:pr_thread
    or ax,ax
    jz spWait
;
    mov es,ax
    mov ax,es:p_id
;
    mov dx,gs:pr_debug_id
    or dx,dx
    jz spLibOk
;
    push ebx
    movzx ebx,gs:pr_module_arr
    ModuleIdToSel
    mov ax,bx
    pop ebx

spLibOk:
    mov dx,bx
    clc
    jmp spDone

spInvalid:
    stc
    jmp spDone

spOk:
    clc   

spDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop gs
    pop es
    pop ds
    ret
spawn_program   Endp
    
spawn_program16 Proc far
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    call spawn_program
;
    pop edi
    pop esi
    ret
spawn_program16 Endp
    
spawn_program32 Proc far
    call spawn_program
    ret
spawn_program32 Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           load_program16/32
;
;       DESCRIPTION:    Load executable file
;
;       PARAMETERS:     DS:(E)SI    Filename
;                       ES:(E)DI    Parameters
;                           +0  command line
;                           +8  startdir
;                           +12 env
;
;       RETURN VALUE:   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_program_name   DB 'Load Program',0

load_program   Proc near
    push ds
    push es
    push gs
    push ebx
    push ecx
    push esi
    push edi
;
    call OpenModuleFile
    jc lpFail
;
    call GetProgramLoader
    jnc lpLoaderOk
;
    CloseCFile
    jmp lpFail

lpLoaderOk:    
    call InitProgramBlock
    call AllocateProgram
    mov gs:pr_loader,ax
    mov gs:pr_kernel_file,bx
;
    call CreateProg
;
    mov eax,es:[edi].lp_param_sel
    or ax,3
    verr ax
    stc
    jnz lpNoParam
;
    mov ds,ax
    mov esi,es:[edi].lp_param_offs
    call CreateParam
    jmp lpParamDone

lpNoParam:
    call CreateNoParam

lpParamDone:
    mov eax,es:[edi].lp_startdir_sel
    or ax,3
    verr ax
    stc
    jnz lpNoStartDir
;
    mov ds,ax
    mov esi,es:[edi].lp_startdir_offs
    call CreateStartDir
    jmp lpStartDirDone

lpNoStartDir:
    call CreateDefaultStartDir

lpStartDirDone:
    mov eax,es:[edi].lp_env_sel
    or ax,3
    verr ax
    stc
    jnz lpNoEnv
;
    mov ds,ax
    mov esi,es:[edi].lp_env_offs
    call CreateEnv
    jmp lpEnvDone

lpNoEnv:
    call CreateDefaultEnv

lpEnvDone:
    mov ebx,gs
    ProgramCreated
    mov ebx,eax
;
    GetThread
    mov es,ax
    lock and es:p_flags,NOT THREAD_FLAG_FORKED
;
    ResetProcess
;
    xor eax,eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
    mov ebp,esp
;
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
;
    GetThread
    mov es,ax
;
    mov ax,gs:pr_loader
    mov es:p_loader,ax
;
    xor esi,esi
    mov ds,gs:pr_name_sel
    mov edi,OFFSET thread_name
    mov ecx,32

lpThreadNameLoop:
    lodsb
    or al,al
    jz lpThreadNamePad
;
    stosb
    loop lpThreadNameLoop

lpThreadNamePad:
    or ecx,ecx
    jz lpThreadNameDone
;
    mov al,' '
    rep stosb

lpThreadNameDone:
    xor bx,bx
;
    call SetupStartDir
    call SetupEnv
;       
    mov bx,gs:pr_kernel_file
    xor esi,esi
    xor edi,edi
    mov ds,gs:pr_name_sel
    mov es,gs:pr_cmd_sel
;
    push gs
    mov gs,gs:pr_loader
    call fword ptr gs:loader_init_exe_proc
    pop gs
    jc lpLoadFail
;
    SetBitness
;
    push ds
    push es
    mov es,bx
;
    movzx ebx,bx
    ModuleLoaded
;
    mov ebx,eax
    call AddProgramModule
    call AddProcessModule
;
    InitSection es:mod_section
    mov es:mod_id,bx
    mov es:mod_key,0
;
    mov bx,es
    pop es
    pop ds
;
    mov fs,gs:pr_loader
    call fword ptr fs:loader_fixup_exe_proc
;
    mov gs:el_ret_code,0
;
    test byte ptr [ebp+2].load_eflags,2
    jnz lpVm16
;
    mov ds,[ebp].load_ds
    mov es,[ebp].load_es
    mov fs,[ebp].load_fs
    mov gs,[ebp].load_gs

lpVm16:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

lpLoadFail:
    int 3

lpFail:
    stc
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop gs
    pop es
    pop ds
    ret
load_program    Endp
    
load_program16 Proc far
    push ebx
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    movzx ebx,bx
    call load_program
;
    pop edi
    pop esi
    pop ebx
    retf32
load_program16  Endp
    
load_program32 Proc far
    call load_program
    retf32
load_program32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           run_program
;
;           DESCRIPTION:    Run programs in adapter
;
;           PARAMETERS:         DS:EDX  device header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_program     PROC near
    push ds
    push es
    push fs
    pushad
;
    mov esi,edx
    add esi,SIZE rdos_header
    call OpenModuleFile
    jc rpFail
;
    call GetProgramLoader
    jnc rpLoaderOk
;
    CloseCFile
    stc
    jmp rpFail

rpLoaderOk:
    call InitProgramBlock
    call AllocateProgram
    mov gs:pr_kernel_file,bx
    mov gs:pr_loader,ax
;
    GetThread
    mov gs:pr_parent_thread,ax
;
    call CreateProg
    call CreateNoParam
    call CreateDefaultStartDir
    call CreateDefaultEnv
;
    mov ebx,gs
    ProgramCreated
    mov ebx,eax
;
    mov es,gs:pr_name_sel
    xor edi,edi
    mov ds,gs:pr_loader
    call fword ptr ds:loader_create_process_proc
;
    WaitForSignal
;
    mov ax,25
    WaitMilliSec

rpFail:
    popad
    pop fs
    pop es
    pop ds
    ret
run_program     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_adapter_programs
;
;           DESCRIPTION:    Start all programs in adapter
;
;           PARAMETERS:         edx         base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kernel_code_text DB 'kernel.exe', 0

init_adapter_programs    Proc near
    push ds
    push es
    pushad
;
    mov ax,flat_sel
    mov ds,ax
    mov es,ax

init_adapter_program_loop:
    mov ax,[edx].typ
    cmp ax,RdosCommand
    jne not_run_program
;
    call run_program
    jmp init_adapter_program_next

not_run_program:
    cmp ax,RdosKernel
    jne adapter_not_kernel
;
    push es
    push edx
    mov bx,kernel_code
    GetSelectorBaseSize
    mov eax,cs
    mov es,eax
    mov edi,OFFSET kernel_code_text    
    xor edx,edx
    call AddKernelModule
    pop edx
    pop es
    jmp init_adapter_program_next

adapter_not_kernel:
    cmp ax,RdosDevice16
    jne adapter_not_device16
;
    push edx
    mov edi,edx
    add edi,SIZE rdos_header
    mov bx,ds:[edi].dev16_code_sel
    movzx ecx,ds:[edi].dev16_code_size
    add edi,SIZE device16_header
    xor edx,edx
    call AddKernelModule
    pop edx
    jmp init_adapter_program_next

adapter_not_device16:
    cmp ax,RdosDevice32
    jne adapter_not_device32
;
    push edx
    mov edi,edx
    add edi,SIZE rdos_header
    mov bx,ds:[edi].dev32_code_sel
    mov ecx,ds:[edi].dev32_code_size
    add edi,SIZE device32_header
    xor edx,edx
    call AddKernelModule
    pop edx
    jmp init_adapter_program_next

adapter_not_device32:
    cmp ax,RdosLongMode
    jne adapter_not_long
;
    push edx
    mov edi,edx
    add edi,SIZE rdos_header
    xor bx,bx
    mov ecx,ds:[edi].lm_image_size
    mov edx,ds:[edi].lm_image_base
    add edi,SIZE long_mode_header
    call AddKernelModule
    pop edx
    
adapter_not_long:
    cmp ax,RdosEnd
    je init_adapter_program_done

init_adapter_program_next:
    add edx,[edx].len
    jmp init_adapter_program_loop

init_adapter_program_done:
    popad
    pop es
    pop ds
    ret
init_adapter_programs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartPrograms
;
;           DESCRIPTION:    Start all programs
;
;       RETURN VALUE:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_programs_name DB 'Start Programs', 0

start_programs    Proc far
    push ds
    pushad
;
    mov ax,system_data_sel
    mov ds,ax
    movzx ecx,ds:rom_modules
    mov bx,OFFSET rom_adapters

spLoop:
    mov edx,[bx].adapter_base
    call init_adapter_programs
    add bx,SIZE adapter_typ
    loop spLoop
;
    popad
    pop ds
    ret
start_programs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AttachDebugger
;
;       DESCRIPTION:    Attach debugger to running thread
;
;       PARAMETERS:     BX          Program ID
;                       DX          Debug module handle
;
;       RETURN VALUE:   AX          Thread ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

attach_debugger_name  DB 'Attach Debugger',0

attach_debugger   Proc far
    push fs
    push gs
    push ebx
    push ecx
;
    push ebx
    movzx ebx,dx
    ModuleIdToSel
    pop ebx
    jc atdDone
;    
    GetProgramSel
    jc atdDone
;
    mov gs,eax
    mov cx,gs:pr_module_count
    or cx,cx
    stc
    jz atdDone
;
    mov cx,gs:pr_process_count
    or cx,cx
    stc
    jz atdDone
;
    mov fs,gs:pr_loader
    call fword ptr fs:loader_attach_debug_proc
;
    mov gs,gs:pr_process_arr
    mov ax,gs:pf_thread_arr

atdDone:
    pop ecx
    pop ebx
    pop gs
    pop fs
    ret
attach_debugger   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RegisterLoader
;
;           DESCRIPTION:    Register a loader
;
;           PARAMETERS:     BX       Loader table selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_loader_name      DB 'Register Loader',0

register_loader   PROC far
    push ds
    push ax
    push esi
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:loader_count
    movzx esi,ax
    add esi,esi
    mov ds:[esi].loader_arr,bx
    inc ax
    mov ds:loader_count,ax
;
    pop esi
    pop ax
    pop ds
    ret
register_loader   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnloadProgram
;
;           DESCRIPTION:    Unload program
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnloadProgram:
    ResetProcess
;
    GetThread
    mov es,ax
;
    mov ds,es:p_prog_sel
    EnterSection ds:pr_section
    movzx ebx,ds:pr_module_arr
    LeaveSection ds:pr_section
;
    ModuleIdToSel
    jc ukDone
;
    mov ds,ebx
    mov ax,ds:mod_loader
    or ax,ax
    mov es,eax
    jz ukDone
;    
    call fword ptr es:loader_unload_exe_kernel_proc

ukDone:
    mov ds,ebx
    movzx ebx,ds:mod_id
    call RemoveProgramModule
    call RemoveProcessModule
;
    mov ebx,ds
    movzx ebx,bx
    ModuleUnloaded
;
    mov es,ebx
    mov bx,es:mod_c_file_handle
    CloseCFile
;
    FreeMem
;
    GetFocusConsole
    GetThread
    mov ds,eax
    cmp bx,ds:p_console
    jne ukFocusOk
;
    mov bx,ds:p_parent_console
    or bx,bx
    jz ukFocusOk
;
    SetFocusConsole

ukFocusOk:
    mov bx,ds:p_console
    CloseConsole
    DestroyHandleData
    DestroyLdt
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnloadProcess
;
;           DESCRIPTION:    Unload process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnloadProcess:
    GetThread
    mov es,ax
    mov ds,es:p_prog_sel
;
    movzx ecx,ds:pr_process_count
    cmp ecx,1
    jbe UnloadProgram
;
    mov es,es:p_loader
    call fword ptr es:loader_detach_kernel_fork_proc
;
    EnterSection ds:pr_cow_section
    DetachFork
    LeaveSection ds:pr_cow_section
    ResetProcess
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnloadUser
;
;           DESCRIPTION:    Do user-level unload
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnloadUser       Proc near
    GetThread
    mov es,ax
    mov ds,es:p_proc_sel
    movzx ecx,ds:pf_thread_count
    cmp ecx,1
    jbe uuThreadsGone
;
    int 3
    TerminateThread

uuThreadsGone:
    mov ds,es:p_proc_sel
    movzx ecx,ds:pf_module_count
    sub ecx,1
    jz uupModulesOk
;
    mov esi,2

uupModulesLoop:
    mov bx,ds:[esi].pf_module_arr
    FreeDll

uupModulesNext:
    add esi,2
    loop uupModulesLoop    

uupModulesOk:
    mov ds,es:p_prog_sel
    movzx ecx,ds:pr_process_count
    cmp ecx,1
    jbe uuProgram

uuProcess:
    mov es,es:p_loader
    call fword ptr es:loader_detach_user_fork_proc
    jmp uuDone

uuProgram:
    EnterSection ds:pr_section
    movzx ebx,ds:pr_module_arr
    LeaveSection ds:pr_section
;
    ModuleIdToSel
    jc uuDone
;
    mov ds,ebx
    mov ax,ds:mod_loader
    or ax,ax
    mov es,eax
    jz uuDone
;    
    call fword ptr es:loader_unload_exe_user_proc

uuDone:
    ret
UnloadUser       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           unload_exe
;
;           DESCRIPTION:    Unload running program
;
;           PARAMETERS:         AX          Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unload_exe_name DB 'Unload Exe',0
    
unload_exe:
    pushfd
    push eax
    mov eax,[esp+12]
    test al,3
    jz UnloadProcess
;
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp,esp
    add ebp,28
    push dword ptr [ebp+4].load_eax
    mov eax,[ebp+4].load_eip
    mov [ebp].load_eip,eax
    mov eax,[ebp+4].load_cs
    mov [ebp].load_cs,eax
    pop dword ptr [ebp].load_eflags   
;
    push ds
    push es
    push fs
    push gs
;
    mov ax,SEG data
    mov ds,eax
    mov bx,ds:exit_gate_sel
;
    GetThread
    mov ds,eax
    mov ax,ds:p_loader
    or ax,ax
    jz UnloadProcess
;
    mov ds,eax
    call fword ptr ds:loader_add_gate_proc
    call UnloadUser
;
    pop gs
    pop fs
    pop es
    pop ds
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Fork
;
;           DESCRIPTION:    Fork process
;
;           RETURNS:        AX = 0 for child
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fork_name   DB 'Fork',0

fork_pr    PROC far
    push ds
;
    GetThread
    mov ds,eax
    mov ax,ds:p_loader
    or ax,ax
    stc
    jz fork_done
;
    mov ds,eax
    call fword ptr ds:loader_fork_proc
    
fork_done:
    pop ds
    ret
fork_pr    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsForked
;
;           DESCRIPTION:    Check if thread is forked
;
;           RETURNS:        NC          Forked
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_forked_name   DB 'Is Forked',0

is_forked    PROC far
    push ds
    push ax
;
    GetThread
    mov ds,ax
    test ds:p_flags,THREAD_FLAG_FORKED
    stc
    jz ifDone
;
    clc

ifDone:
    pop ax
    pop ds
    ret
is_forked    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RemovedProcess
;
;           DESCRIPTION:    Update program after removed process
;
;           PARAMETERS:     BX       Program ID
;                           DS       Removed process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

removed_process_name   DB 'Removed Process',0

removed_process    PROC far
    push ds
    push es
    pushad
;
    mov eax,ds
    mov es,eax
;
    movzx ebx,bx
    GetProgramSel
    jc rpfDone
;
    mov ds,eax
    EnterSection ds:pr_section
    movzx ecx,ds:pr_process_count
    or ecx,ecx
    jz rpfEnd
;
    EnterSection ds:pr_cow_section
    push ds
    mov eax,es
    mov ds,eax
    DeleteFork
    pop ds
;
    cmp ecx,1
    jne rpfLeave

rpfUnfork:
    CleanupFork
    jmp rpfLeave

rpfEnd:
    LeaveSection ds:pr_section
    call RemoveProg
    jmp rpfDone

rpfLeave:
    LeaveSection ds:pr_cow_section
    LeaveSection ds:pr_section

rpfDone:
    popad
    pop es
    pop ds    
    ret
removed_process    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FatalErrorExit
;
;           DESCRIPTION:    Fatal error exit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fatal_error_exit_name       DB 'Fatal Error Exit',0

fatal_error_exit    PROC far
    mov ax,wd_code_sel
    verr ax
    jnz feeDone
;
    mov ax,2500
    WaitMilliSec
;
    SoftReset

feeDone:
    ret
fatal_error_exit    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AppPatch
;
;       DESCRIPTION:    Patch app
;
;       DESCRIPTION:    App specific usergate patching
;
;       PARAMETERS:     DS:EBX      Instruction to patch
;                       EAX         Gate #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_patch_name DB 'App Patch', 0

app_patch Proc far
    push fs
    push gs
;
    push eax
    GetThread
    mov gs,ax
    mov ax,gs:p_loader
    or ax,ax
    mov fs,ax
    stc
    pop eax
    jz apDone
;
    mov gs,gs:p_prog_sel
    call fword ptr fs:loader_patch_proc

apDone:
    pop gs
    pop fs
    ret
app_patch Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForExec
;
;           DESCRIPTION:    Wait for exec
;
;           PARAMETERS:     AX          Forked ID
;
;           RETURNS:        AX          Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_exec_name DB 'Wait For Exec',0
    
wait_for_exec   Proc far
    ret
wait_for_exec   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetExitCode
;
;           DESCRIPTION:    Get exit code
;
;           RETURNS:        AX          Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exit_code_name DB 'Get Exit Code',0
    
get_exit_code   Proc far
    int 3
    ret
get_exit_code   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetExeName
;
;           DESCRIPTION:    Get name of executable file
;
;           RETURNS:        ES:(E)DI        Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exe_name_name       DB 'Get Exe Name',0

get_exe_name    PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ax,ds:p_loader
    or ax,ax
    mov ds,ax
    pop eax
    stc
    jz get_exe_name_done
;
    call fword ptr ds:loader_get_exe_proc

get_exe_name_done:
    pop ds
    ret
get_exe_name    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetCmdLine
;
;           DESCRIPTION:    Get command line
;
;           RETURNS:        ES:(E)DI        Command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cmd_line_name       DB 'Get Cmd Line',0

get_cmd_line    PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ax,ds:p_loader
    or ax,ax
    mov ds,ax
    pop eax
    stc
    jz get_cmd_line_done
;
    call fword ptr ds:loader_get_cmd_line_proc

get_cmd_line_done:
    pop ds
    ret
get_cmd_line    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetEnvironment
;
;           DESCRIPTION:    Get environment
;
;           RETURNS:        ES:(E)DI        Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_env_name    DB 'Get Environment',0

get_env PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ax,ds:p_loader
    or ax,ax
    mov ds,ax
    pop eax
    stc
    jz get_env_done
;
    call fword ptr ds:loader_get_env_proc

get_env_done:
    pop ds
    ret
get_env ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleFocusKey
;
;           DESCRIPTION:    Get module focus key
;
;       PARAMETERS:         BX          Module handle
;
;       RETURNS:    AL      Key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_focus_key_name       DB 'Get Module Focus Key',0

get_module_focus_key  Proc far
    push ds
    push ebx
;    
    movzx ebx,bx
    ModuleIdToSel
    jc get_module_focus_done
;
    mov ds,ebx
    mov al,ds:mod_key
    clc

get_module_focus_done:
    pop ebx
    pop ds    
    ret
get_module_focus_key  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           load_dll
;
;       DESCRIPTION:    Load DLL
;
;       PARAMETERS:     ES:EDI      Name of dll to load
;                       EBP         Stack frame   
;
;       RETURNS:        BX          Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_dll        Proc  near    
    mov eax,es
    mov fs,eax
    mov esi,edi
;
    GetThread
    mov ds,ax
    movzx ebx,ds:p_proc_id
    FindModuleByName
    jnc ldllOk
;
    mov eax,es
    mov ds,eax
    call OpenModuleFile
    jc ldllFail
;
    GetThread
    mov es,ax
    mov ax,es:p_loader
    or ax,ax
    mov gs,ax
    jz ldllFail
;
    call fword ptr gs:loader_init_dll_proc
    jc ldllFail
;
    push ebx
    movzx ebx,es:p_prog_id
    GetProgramSel
    mov es,ax
    mov dx,es:pr_debug_id
    pop ebx
    mov es,bx
;
    movzx ebx,bx
    ModuleLoaded
;
    mov ebx,eax
    call AddProgramModule
    call AddProcessModule
;
    InitSection es:mod_section
    mov es:mod_id,bx
;
    push ebx
    mov ebx,es
    call fword ptr gs:loader_fixup_dll_proc
    pop ebx
    clc
    jmp ldllDone

ldllOk:
    mov [ebp].load_ebx,ebx
    call IncModuleUsage
    clc
    jmp ldllDone

ldllFail:
    stc
    
ldllDone:
    ret
load_dll        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           load_dll
;
;           DESCRIPTION:    Load DLL
;
;       PARAMETERS:         ES:(E)DI    Name of dll to load
;
;           RETURNS:        BX          Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_dll_name   DB 'Load Dll',0

load_dll32  Proc far
    pushfd
    push eax
    mov eax,[esp+12]
    test al,3
    jz load_dll_kernel32
;
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp,esp
    add ebp,28
    push dword ptr [ebp+4].load_eax
    mov eax,[ebp+4].load_eip
    mov [ebp].load_eip,eax
    mov eax,[ebp+4].load_cs
    mov [ebp].load_cs,eax
    pop dword ptr [ebp].load_eflags   
;
    push ds
    push es
    push fs
    push gs
;
    GetThread
    mov ds,eax
    mov ax,ds:p_loader
    or ax,ax
    stc
    jz load_dll_fail32
;
    mov ds,eax
    call fword ptr ds:loader_regs_to_user_proc
;
    push ds
    push esi
;    
    call load_dll
;
    pop esi
    pop ds
;
    mov ds:[esi].user_ebx,bx
    and byte ptr ds:[esi].user_eflags,NOT 1
    jmp load_dll_exit32

load_dll_fail32:
    or byte ptr ds:[esi].user_eflags,1

load_dll_exit32:
    pop gs
    pop fs
    pop es
    pop ds
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

load_dll_kernel32:
    push ecx
    push edx
    push esi
    push edi
    push ds
    push es
    push fs
    push gs
;
    call load_dll
;
    pop gs
    pop fs
    pop es
    pop ds
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    add esp,4
    ret
load_dll32  Endp

load_dll16  Proc far
    pushfd
    push eax
    mov eax,[esp+12]
    test al,3
    jz load_dll_kernel16
;
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp,esp
    add ebp,28
    push dword ptr [ebp+4].load_eax
    mov eax,[ebp+4].load_eip
    mov [ebp].load_eip,eax
    mov eax,[ebp+4].load_cs
    mov [ebp].load_cs,eax
    pop dword ptr [ebp].load_eflags   
;
    push ds
    push es
    push fs
    push gs
;
    movzx edi,di
;
    GetThread
    mov ds,eax
    mov ax,ds:p_loader
    or ax,ax
    stc
    jz load_dll_fail16
;
    mov ds,eax
    call fword ptr ds:loader_regs_to_user_proc
;
    push ds
    push esi
;    
    call load_dll
;
    pop esi
    pop ds
;
    mov ds:[esi].user_ebx,bx
    and byte ptr ds:[esi].user_eflags,NOT 1
    jmp load_dll_exit16

load_dll_fail16:
    or byte ptr ds:[esi].user_eflags,1

load_dll_exit16:
    pop gs
    pop fs
    pop es
    pop ds
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

load_dll_kernel16:
    push ecx
    push edx
    push esi
    push edi
    push ds
    push es
    push fs
    push gs
;
    movzx edi,di
    call load_dll
;
    pop gs
    pop fs
    pop es
    pop ds
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    add esp,4
    ret
load_dll16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           unload_dll
;
;           DESCRIPTION:    Unload DLL callback
;
;       PARAMETERS:         EBX         Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unload_dll Proc far
    push ds
    push es
    pushad
;
    call RemoveProcessModule
    call GetModuleReferences
    or ecx,ecx
    jnz unload_dll_done
;
    call RemoveProgramModule
;
    ModuleIdToSel
    jc unload_dll_done
;
    mov ds,ebx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz unload_dll_free
;    
    push bx
    call fword ptr ds:loader_free_dll_proc    
    pop bx

unload_dll_free:
    movzx ebx,bx
    ModuleUnloaded
;
    mov es,ebx
    mov bx,es:mod_c_file_handle
    CloseCFile
;
    FreeMem

unload_dll_done:
    popad
    pop es
    pop ds
    ret
unload_dll      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           free_dll_do
;
;           DESCRIPTION:    Free DLL
;
;       PARAMETERS:         BX          Module handle
;                           EBP         Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_dll_do  Proc near
    push ecx
    call DecModuleUsage
    or ecx,ecx
    pop ecx
    clc
    jnz free_dll_done
;
    movzx ebx,bx
    ModuleIdToSel
    jc free_dll_done
;
    mov ax,SEG data
    mov ds,eax
    mov dx,ds:free_dll_gate_sel
;
    GetThread
    mov ds,eax
    mov ax,ds:p_loader
    or ax,ax
    stc
    jz free_dll_done
;
    push ebx
    mov bx,dx
    mov ds,eax
    call fword ptr ds:loader_add_gate_proc
    pop ebx
;    
    call fword ptr ds:loader_unload_dll_proc    

free_dll_done:
    ret
free_dll_do  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           free_dll
;
;           DESCRIPTION:    Free DLL
;
;       PARAMETERS:         BX          Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_dll_name   DB 'Free Dll',0

free_dll  Proc far
    pushfd
    push eax
    mov eax,[esp+12]
    test al,3
    jz free_dll_kernel
;
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp,esp
    add ebp,28
    push dword ptr [ebp+4].load_eax
    mov eax,[ebp+4].load_eip
    mov [ebp].load_eip,eax
    mov eax,[ebp+4].load_cs
    mov [ebp].load_cs,eax
    pop dword ptr [ebp].load_eflags   
;
    push ds
    push es
    push fs
    push gs
;
    call free_dll_do
;
    pop gs
    pop fs
    pop es
    pop ds
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

free_dll_kernel:
    push ecx
    push edx
    push esi
    push edi
    push ds
    push es
    push fs
    push gs
;
    call free_dll_do
;
    pop gs
    pop fs
    pop es
    pop ds
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    add esp,4
    ret
    ret
free_dll  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCurrentDll
;
;           DESCRIPTION:    Get current DLL module handle
;
;       PARAMETERS:         ES:EDI      Code position
;
;       RETURNS:            BX          Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_current_dll_name       DB 'Get Current Dll',0

get_current_dll  Proc far
    push ebp
    mov ebp,esp
    push ds
    push es
    push eax
    push edi
;    
    les edi,[ebp+4]    
    GetThread
    mov ds,ax
    mov ax,ds:p_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_current_dll_done
;
    call fword ptr ds:loader_get_current_dll_proc
    jc get_current_dll_done
;
    mov es,bx
    mov bx,es:mod_id

get_current_dll_done:
    pop edi
    pop eax
    pop es
    pop ds    
    pop ebp
    ret
get_current_dll  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleProc
;
;           DESCRIPTION:    Get module procedure
;
;       PARAMETERS:         BX          Module handle
;                           ES:(E)DI    Proc name
;
;       RETURNS:    DS:(E)SI    Proc address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_proc_name    DB 'Get Module Proc',0

get_module_proc32  Proc far
    push eax
    push ebx
;    
    movzx ebx,bx
    ModuleIdToSel
    jc get_module_proc_done32
;
    mov ds,ebx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_module_proc_done32
;    
    call fword ptr ds:loader_get_proc_proc

get_module_proc_done32:
    pop ebx
    pop eax
    ret
get_module_proc32  Endp

get_module_proc16  Proc far
    push eax
    push ebx
    push edi
;    
    movzx edi,di
    movzx ebx,bx
    ModuleIdToSel
    jc get_module_proc_done16
;
    mov ds,ebx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_module_proc_done16
;
    call fword ptr ds:loader_get_proc_proc

get_module_proc_done16:
    pop edi
    pop ebx
    pop eax
    ret
get_module_proc16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleResource
;
;           DESCRIPTION:    Get module resource
;
;       PARAMETERS:         BX          Module handle
;               (E)AX       Resource handle
;               (E)DX       Resource type
;
;       RETURNS:    DS:(E)SI    Resource address
;               (E)CX       Resource size   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_resource_name    DB 'Get Module Resource',0

get_module_resource  Proc far
    push ebx
;   
    movzx ebx,bx 
    ModuleIdToSel
    jc get_resource_done
;
    mov ds,ebx
    mov cx,ds:mod_loader
    or cx,cx
    mov ds,cx
    stc
    jz get_resource_done
;    
    call fword ptr ds:loader_get_resource_proc

get_resource_done:
    pop ebx
    ret
get_module_resource  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleName
;
;           DESCRIPTION:    Get module name
;
;       PARAMETERS:         BX          Handle
;                           (E)CX       Max name size
;                           ES:(E)DI    Name buffer
;                           
;           RETURNS:        (E)AX       Bytes copied
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_name_name    DB 'Get Module Name',0

get_module_name32  Proc far
    push ds
    push ebx
;    
    movzx ebx,bx
    ModuleIdToSel
    jc get_module_name_done32
;
    mov ds,ebx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_module_name_done32
;    
    call fword ptr ds:loader_get_name_proc

get_module_name_done32:
    pop ebx
    pop ds
    ret
get_module_name32  Endp

get_module_name16  Proc far
    push ds
    push ebx
    push edi
;    
    movzx edi,di
    movzx ebx,bx
    ModuleIdToSel
    jc get_module_name_done16
;
    mov ds,ebx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_module_name_done16
;    
    call fword ptr ds:loader_get_name_proc

get_module_name_done16:
    pop edi
    pop ebx
    pop ds
    ret
get_module_name16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateAppMem
;
;           DESCRIPTION:    Allocate application memory
;
;           PARAMETERS:         EAX             Size
;
;           RETURNS:        ES / (E)DX      Memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_app_mem_name   DB 'Allocate App Mem',0

allocate_app_mem    PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ax,ds:p_loader
    or ax,ax
    mov ds,ax
    pop eax
    jz allocate_mem_default
;
    call fword ptr ds:loader_allocate_mem_proc
    jmp allocate_mem_done

allocate_mem_default:
    AllocateLocalMem

allocate_mem_done:
    pop ds
    ret
allocate_app_mem    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeAppMem
;
;           DESCRIPTION:    Free application memory
;
;           PARAMETERS:         ES / (E)DX      Memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_app_mem_name       DB 'Free App Mem',0

free_app_mem    PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ax,ds:p_loader
    or ax,ax
    mov ds,ax
    pop eax
    jz free_mem_default
;
    call fword ptr ds:loader_free_mem_proc
    jmp free_mem_done

free_mem_default:
    FreeMem

free_mem_done:
    pop ds
    ret
free_app_mem    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateDebugAppMem
;
;           DESCRIPTION:    Allocate application memory, debug mode
;
;           PARAMETERS:         EAX             Size
;
;           RETURNS:        ES / (E)DX      Memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_debug_app_mem_name     DB 'Allocate Debug App Mem',0

allocate_debug_app_mem  PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ax,ds:p_loader
    or ax,ax
    mov ds,ax
    pop eax
    jz allocate_debug_mem_norm
;
    call fword ptr ds:loader_debug_allocate_mem_proc
    jmp allocate_debug_mem_done

allocate_debug_mem_norm:
    AllocateLocalMem

allocate_debug_mem_done:
    pop ds
    ret
allocate_debug_app_mem  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeDebugAppMem
;
;           DESCRIPTION:    Free application memory, debug mode
;
;           PARAMETERS:         ES / (E)DX      Memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_debug_app_mem_name DB 'Free Debug App Mem',0

free_debug_app_mem      PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ax,ds:p_loader
    or ax,ax
    mov ds,ax
    pop eax
    jz free_debug_mem_norm
;
    call fword ptr ds:loader_debug_free_mem_proc
    jmp free_debug_mem_done

free_debug_mem_norm:
    FreeMem

free_debug_mem_done:
    pop ds
    ret
free_debug_app_mem      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPrimaryModule
;
;           DESCRIPTION:    Get primary module ID from program ID
;
;       PARAMETERS:         BX          Program ID
;
;           RETURNS:        AX          Primary module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPrimaryModule  Proc near
    push ds
;
    movzx ebx,bx
    GetProgramSel
    jc gpmodFail
;
    mov ds,eax
    mov ax,ds:pr_module_count
    or ax,ax
    jz gpmodFail
;
    mov ax,ds:pr_module_arr
    clc
    jmp gpmodDone

gpmodFail:
    stc

gpmodDone:
    pop ds
    ret
GetPrimaryModule  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForDebugEvent
;
;           DESCRIPTION:    Start a wait for debug event
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_debug_event      PROC far
    push ds
    push eax
    push bx
;
    movzx ebx,es:dew_module_id
    ModuleIdToSel
    jc start_wait_for_done
;
    mov ds,bx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz start_wait_for_done
;    
    call fword ptr ds:loader_start_wait_for_debug_event_proc

start_wait_for_done:
    pop bx
    pop eax
    pop ds
    ret
start_wait_for_debug_event Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForDebugEvent
;
;           DESCRIPTION:    Stop a wait for debug event
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_debug_event       PROC far
    push ds
    push eax
    push bx
;
    movzx ebx,es:dew_module_id
    ModuleIdToSel
    jc stop_wait_for_done
;
    mov ds,bx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz stop_wait_for_done
;    
    call fword ptr ds:loader_stop_wait_for_debug_event_proc

stop_wait_for_done:
    pop bx
    pop eax
    pop ds
    ret
stop_wait_for_debug_event Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DummyClearDebugEvent
;
;           DESCRIPTION:    Clear debug event
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy_clear_debug_event PROC far
    ret
dummy_clear_debug_event Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsDebugEventIdle
;
;           DESCRIPTION:    Check if debug event is idle
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_debug_event_idle     PROC far
    push ds
    push eax
    push bx
;
    movzx ebx,es:dew_module_id
    ModuleIdToSel
    jc is_idle_done
;
    mov ds,bx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz is_idle_done
;    
    call fword ptr ds:loader_is_debug_event_idle_proc

is_idle_done:
    pop bx
    pop eax
    pop ds
    ret
is_debug_event_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForDebugEvent
;
;           DESCRIPTION:    Add a wait for debug event
;
;           PARAMETERS:     AX      Program handle
;                           BX      Wait handle
;                           ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_debug_event_name   DB 'Add Wait For Debug Event',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_debug_event,   SEG _text
aw1 DD OFFSET stop_wait_for_debug_event,    SEG _text
aw2 DD OFFSET dummy_clear_debug_event,      SEG _text
aw3 DD OFFSET is_debug_event_idle,          SEG _text

add_wait_for_debug_event    PROC far
    push ds
    push es
    push eax
    push ebx
    push edx
    push edi
;
    push bx
    mov bx,ax
    call GetPrimaryModule
    pop bx
    jc add_wait_done
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE debug_event_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWait
    pop ax
    jc add_wait_done
;    
    mov es:dew_module_id,ax

add_wait_done:
    pop edi
    pop edx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
add_wait_for_debug_event    ENDP
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetDebugEvent
;
;       DESCRIPTION:    Get current debug event
;
;       PARAMETERS:     BX      Program handle
;
;       RETURNS:        AX      Thread ID
;                       BL      Event type  
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_event_name    DB 'Get Debug Event',0

get_debug_event  Proc far
    push ds
    push ecx
    push dx
;    
    call GetPrimaryModule
    jc get_debug_event_done
;
    movzx ebx,ax
    ModuleIdToSel
    jc get_debug_event_done
;
    mov eax,ebx
    mov ds,eax
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_debug_event_done
;    
    call fword ptr ds:loader_get_debug_event_proc

get_debug_event_done:
    pop dx
    pop ecx
    pop ds
    ret
get_debug_event  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDebugEventData
;
;           DESCRIPTION:    Get debug event data
;
;       PARAMETERS:         BX          Handle
;                           ES:(E)DI    Event buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_event_data_name       DB 'Get Debug Event Data',0

get_debug_event_data32  Proc far
    push ds
    push eax
    push ebx
    push edx
;    
    call GetPrimaryModule
    jc get_debug_event_data_done32
;
    movzx ebx,ax
    ModuleIdToSel
    jc get_debug_event_data_done32
;
    mov eax,ebx
    mov ds,eax
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_debug_event_data_done32
;    
    call fword ptr ds:loader_get_debug_event_data_proc

get_debug_event_data_done32:
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
get_debug_event_data32  Endp

get_debug_event_data16  Proc far
    push ds
    push eax
    push ebx
    push edx
    push edi
;    
    call GetPrimaryModule
    jc get_debug_event_data_done16
;
    movzx ebx,ax
    ModuleIdToSel
    jc get_debug_event_data_done16
;
    mov eax,ebx
    mov ds,eax
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_debug_event_data_done16
;    
    call fword ptr ds:loader_get_debug_event_data_proc

get_debug_event_data_done16:
    pop edi
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
get_debug_event_data16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClearDebugEvent
;
;           DESCRIPTION:    Clear debug event
;
;       PARAMETERS:         BX          Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_debug_event_name  DB 'Clear Debug Event',0

clear_debug_event  Proc far
    push ds
    push eax
    push ebx
    push ecx
    push edx
;    
    call GetPrimaryModule
    jc clear_debug_event_done
;
    movzx ebx,ax
    ModuleIdToSel
    jc clear_debug_event_done
;
    mov eax,ebx
    mov ds,eax
    mov cx,ds:mod_loader
    or cx,cx
    mov ds,cx
    stc
    jz clear_debug_event_done
;    
    call fword ptr ds:loader_clear_debug_event_proc

clear_debug_event_done:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
clear_debug_event  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ContinueDebugEvent
;
;           DESCRIPTION:    Continue debug event
;
;       PARAMETERS:         BX          Module handle
;                           EAX     Thread ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

continue_debug_event_name       DB 'Continue Debug Event',0

continue_debug_event  Proc far
    push ds
    push ebx
    push ecx
    push edx
    push esi
;    
    mov esi,eax
    call GetPrimaryModule
    jc continue_debug_event_done
;
    movzx ebx,ax
    ModuleIdToSel
    jc continue_debug_event_done
;
    mov eax,ebx
    mov ds,eax
    mov eax,esi
    mov cx,ds:mod_loader
    or cx,cx
    mov ds,cx
    stc
    jz continue_debug_event_done
;    
    call fword ptr ds:loader_continue_debug_event_proc

continue_debug_event_done:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
continue_debug_event  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AbortDebug
;
;           DESCRIPTION:    Abort debugging
;
;       PARAMETERS:         BX          Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

abort_debug_name  DB 'Abort Debug',0

abort_debug  Proc far
    push ds
    push es
    pushad
;    
    movzx ebx,bx
    GetProgramSel
    jc adDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    movzx ecx,ds:pr_module_count
    mov esi,OFFSET pr_module_arr
    
adLoop:
    movzx ebx,word ptr ds:[esi]
    ModuleIdToSel
    jc adNext
;
    mov es,ebx
    mov es:mod_debug_id,0
;
    mov ax,es:mod_loader
    or ax,ax
    mov es,eax
    stc
    jz adNext
;    
    call fword ptr es:loader_stop_debug_proc

adNext:
    add esi,2
    loop adLoop

    LeaveSection ds:pr_section

adDone:
    popad
    pop es
    pop ds
    ret
abort_debug  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AliasModuleHandle
;
;           DESCRIPTION:    Create an alias handle for module
;
;       PARAMETERS:         BX      Lib sel
;
;           RETURNS:        BX      Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

alias_module_handle_name    DB 'Alias Module Handle',0

alias_module_handle  Proc far
    push ds
    mov ds,bx
    mov bx,ds:mod_id
    pop ds
    ret
alias_module_handle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DuplModuleFileHandle
;
;       DESCRIPTION:    Dupl module file handle
;
;       PARAMETERS:     BX          Module handle
;
;       RETURNS:        BX          Duplicated file handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dupl_module_file_handle_name       DB 'Dupl Module File Handle',0

dupl_module_file_handle  Proc far
    push ds
;
    movzx ebx,bx    
    ModuleIdToSel
    jc dupl_module_file_handle_done
;
    mov ds,ebx
    mov bx,ds:mod_c_file_handle
    DuplCFileToFile
    clc

dupl_module_file_handle_done:
    pop ds    
    ret
dupl_module_file_handle  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProgramInfo
;
;           DESCRIPTION:    Get program info
;
;           PARAMETERS:     AX          Program #
;                           ES:(E)DI    Name buffer
;                           (E)CX       Size of buffer
;
;           RETURNS:        DX          program ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_program_info_name DB 'Get Program Info',0
    
get_program_info    Proc near
    push ds
    push eax
    push ebx
    push esi
    push edi
;
    GetProgramId
    jc gpiDone
;
    mov edx,eax
    mov ebx,eax
    GetProgramSel
    jc gpiDone
;
    mov ds,eax
    mov ds,ds:pr_name_sel
    xor esi,esi

gpiCopy:
    lodsb
    stosb
    or al,al
    jz gpiOk
;
    loop gpiCopy
;
    xor al,al
    mov es:[edi-1],al

gpiOk:
    clc

gpiDone:
    pop edi
    pop esi
    pop ebx
    pop eax
    pop ds
    ret
get_program_info    Endp

get_program_info16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_program_info
;
    pop edi
    pop ecx
    ret
get_program_info16   Endp

get_program_info32   Proc far
    call get_program_info
    ret
get_program_info32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProgramModules
;
;           DESCRIPTION:    Get program modules
;
;           PARAMETERS:     AX          Program #
;                           ES:(E)DI    Module ID buffer (2 bytes per entry)
;                           (E)CX       Max module ids
;
;           RETURNS:        ECX         Actual modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_program_modules_name DB 'Get Program Modules',0
    
get_program_modules    Proc near
    push ds
    push ebx
    push edx
    push esi
    push edi
;
    GetProgramId
    jc gpmDone
;
    mov edx,eax
    mov ebx,eax
    GetProgramSel
    jc gpmDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    movzx edx,ds:pr_module_count
    mov esi,OFFSET pr_module_arr

gpmCopy:
    or edx,edx
    jz gpmLeave
;
    dec edx
    lodsw
    stosw
    loop gpmCopy

gpmLeave:
    movzx ecx,ds:pr_module_count
    LeaveSection ds:pr_section
    clc

gpmDone:
    pop edi
    pop esi
    pop edx
    pop ebx
    pop ds
    ret
get_program_modules    Endp

get_program_modules16   Proc far
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_program_modules
;
    pop edi
    ret
get_program_modules16   Endp

get_program_modules32   Proc far
    call get_program_modules
    ret
get_program_modules32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProgramProcesses
;
;           DESCRIPTION:    Get program processes
;
;           PARAMETERS:     AX          Program #
;                           ES:(E)DI    Process ID buffer (2 bytes per entry)
;                           (E)CX       Max process ids
;
;           RETURNS:        ECX         Actual processes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_program_processes_name DB 'Get Program Processes',0
    
get_program_processes    Proc near
    push ds
    push ebx
    push edx
    push esi
    push edi
;
    GetProgramId
    jc gppDone
;
    mov edx,eax
    mov ebx,eax
    GetProgramSel
    jc gppDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    movzx edx,ds:pr_process_count
    mov esi,OFFSET pr_process_arr

gppCopy:
    or edx,edx
    jz gppLeave
;
    dec edx
    lodsw
    stosw
    loop gppCopy

gppLeave:
    movzx ecx,ds:pr_process_count
    LeaveSection ds:pr_section
    clc

gppDone:
    pop edi
    pop esi
    pop edx
    pop ebx
    pop ds
    ret
get_program_processes    Endp

get_program_processes16   Proc far
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_program_processes
;
    pop edi
    ret
get_program_processes16   Endp

get_program_processes32   Proc far
    call get_program_processes
    ret
get_program_processes32   Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleByIndex
;
;           DESCRIPTION:    Get module for a DLL or app module by index
;
;           PARAMETERS:     BX          Process ID
;                           AX          Entry #
;
;           RETURNS:        BX          Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_by_index_name DB 'Get Module By Index', 0

get_module_by_index Proc far
    push ds
    push eax
    push ecx
    push edx
;
    mov dx,ax
    movzx ebx,bx
    ProcessIdToSel
    jc gmbiDone
;
    mov ds,ebx
    EnterSection ds:pf_section
;
    mov cx,ds:pf_module_count
    cmp dx,cx
    jae gmbiFail
;
    mov bx,dx
    add bx,bx
    mov bx,ds:[bx].pf_module_arr
    LeaveSection ds:pf_section
    clc
    jmp gmbiDone

gmbiFail:
    LeaveSection ds:pf_section
    stc

gmbiDone:
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
get_module_by_index Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindModuleByAddress
;
;           DESCRIPTION:    Search for a DLL or app module
;
;           PARAMETERS:     BX          Process ID
;                           EDX         Virtual adress
;
;           RETURNS:        AX          Entry #
;                           BX          Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_module_by_address_name DB 'Find Module By Address', 0

find_module_by_address Proc far
    push ds
    push es
    push ecx
    push esi
;
    movzx ebx,bx
    ProcessIdToSel
    jc fmbaDone
;
    mov ds,ebx
    EnterSection ds:pf_section
;
    movzx ecx,ds:pf_module_count
    mov esi,OFFSET pf_module_arr
;
    or ecx,ecx
    jz fmbaFail

fmbaLoop:
    movzx ebx,word ptr ds:[esi]
    ModuleIdToSel
    jc fmbaNext
;
    mov es,ebx
    mov eax,edx
    sub eax,es:mod_base
    jc fmbaNext
;       
    cmp eax,es:mod_size
    jc fmbaOk

fmbaNext:
    add esi,2
    loop fmbaLoop

fmbaFail:
    LeaveSection ds:pf_section
    stc
    jmp fmbaDone

fmbaOk:
    LeaveSection ds:pf_section
;
    mov eax,esi
    sub eax,OFFSET pf_module_arr
    shr eax,1
    mov bx,es:mod_id
    clc

fmbaDone:
    pop esi
    pop ecx
    pop es
    pop ds
    ret
find_module_by_address Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindModuleByName
;
;           DESCRIPTION:    Find module by name
;
;           PARAMETERS:     BX          Process ID
;                           FS:ESI      App / DLL NAME
;
;           RETURNS:        AX          Entry #
;                           BX          Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_module_by_name_name DB 'Find Module By Name', 0

find_module_by_name Proc far
    push ds
    push es
    push ecx
    push edi
    push ebp
;
    mov ebp,esi

fmbnRefLoop:
    mov al,fs:[ebp]
    or al,al
    jz fmbnRefOk
;
    inc ebp
    jmp fmbnRefLoop

fmbnRefOk:
    movzx ebx,bx
    ProcessIdToSel
    jc fmbnDone
;
    mov ds,ebx
    EnterSection ds:pf_section
;
    movzx ecx,ds:pf_module_count
    mov edi,OFFSET pf_module_arr
;
    or ecx,ecx
    jz fmbnFail

fmbnLoop:
    movzx ebx,word ptr ds:[edi]
    ModuleIdToSel
    jc fmbnNext
;
    mov es,ebx
    movzx ebx,es:mod_name_offs
    mov ebp,esi

fmbnCheckName:
    mov al,es:[ebx]
    movzx edx,al
    mov al,byte ptr cs:[edx].UCaseTab
    mov ah,fs:[ebp]
    movzx edx,ah
    mov ah,byte ptr cs:[edx].UCaseTab
    cmp al,ah
    jne fmbnNext
;       
    or al,al
    je fmbnOk
;
    inc ebx
    inc ebp
    jmp fmbnCheckName

fmbnNext:
    add edi,2
    loop fmbnLoop

fmbnFail:
    LeaveSection ds:pf_section
    stc
    jmp fmbnDone

fmbnOk:
    LeaveSection ds:pf_section
;
    mov eax,edi
    sub eax,OFFSET pf_module_arr
    shr eax,1
    mov bx,es:mod_id
    clc

fmbnDone:
    pop ebp
    pop edi
    pop ecx
    pop es
    pop ds
    ret
find_module_by_name Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleInfo
;
;           DESCRIPTION:    Get module info
;
;           PARAMETERS:     AX          Module #
;                           ES:(E)DI    Name buffer
;                           (E)CX       Size of buffer
;
;           RETURNS:        DX          module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_info_name DB 'Get Module Info',0
    
get_module_info    Proc near
    push ds
    push eax
    push ebx
    push esi
    push edi
;
    GetModuleId
    jc gmiDone
;
    mov edx,eax
    mov ebx,eax
    ModuleIdToSel
    jc gmiDone
;
    mov ds,ebx
    movzx esi,ds:mod_name_offs

gmiCopyLoop:
    lodsb
    stosb
    or al,al
    jz gmiCopyDone
;
    loop gmiCopyLoop
;
    xor al,al
    mov es:[edi-1],al

gmiCopyDone:
    clc

gmiDone:
    pop edi
    pop esi
    pop ebx
    pop eax
    pop ds
    ret
get_module_info    Endp

get_module_info16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_module_info
;
    pop edi
    pop ecx
    ret
get_module_info16   Endp

get_module_info32   Proc far
    call get_module_info
    ret
get_module_info32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleSel
;
;           DESCRIPTION:    Get module sel
;
;           PARAMETERS:     BX          Module ID
;
;           RETURNS:        AX          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_sel_name DB 'Get Module Sel',0
    
get_module_sel    Proc far
    push ds
    push ebx
;
    movzx ebx,bx
    ModuleIdToSel
    jc gmsDone
;
    mov ds,ebx
    mov ax,ds:mod_sel
    clc

gmsDone:
    pop ebx
    pop ds
    ret
get_module_sel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDll
;
;           DESCRIPTION:    Get DLL handle
;
;       PARAMETERS:         ES:(E)DI    DLL name
;                           
;           RETURNS:        EBX         DLL handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_dll_handle_name     DB 'Get DLL',0

get_dll_handle  Proc near
    push es
    push fs
    push eax
    push esi
;
    mov eax,es
    mov fs,eax
    mov esi,edi
;
    GetThread
    mov es,eax
    movzx ebx,es:p_proc_id
    FindModuleByName
    jc gdhDone
;
    ModuleIdToSel
    jc gdhDone
;
    mov es,ebx
    movzx ebx,es:mod_id
    clc

gdhDone:
    pop esi
    pop eax
    pop fs
    pop es
    ret
get_dll_handle  Endp

get_dll_handle16   Proc far
    push edi
;
    movzx edi,di
    call get_dll_handle
;
    pop edi
    ret
get_dll_handle16   Endp

get_dll_handle32   Proc far
    call get_dll_handle
    ret
get_dll_handle32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleBase
;
;           DESCRIPTION:    Get module base
;
;           PARAMETERS:     BX          Module ID
;
;           RETURNS:        EDX:EAX     Base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_base_name DB 'Get Module Base',0
    
get_module_base    Proc far
    push ds
    push ebx
;
    movzx ebx,bx
    ModuleIdToSel
    jc gmbDone
;
    mov ds,ebx
    mov eax,ds:mod_base
    mov edx,ds:mod_base+4
    clc

gmbDone:
    pop ebx
    pop ds
    ret
get_module_base    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleSize
;
;           DESCRIPTION:    Get module size
;
;           PARAMETERS:     BX          Module ID
;
;           RETURNS:        EDX:EAX     Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_size_name DB 'Get Module Size',0
    
get_module_size    Proc far
    push ds
    push ebx
;
    movzx ebx,bx
    ModuleIdToSel
    jc gmszDone
;
    mov ds,ebx
    mov eax,ds:mod_size
    mov edx,ds:mod_size+4
    clc

gmszDone:
    pop ebx
    pop ds
    ret
get_module_size    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProcessInfo
;
;           DESCRIPTION:    Get process info
;
;           PARAMETERS:     AX          Process #
;                           ES:(E)DI    Name buffer
;                           (E)CX       Size of buffer
;
;           RETURNS:        DX          process ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_process_info_name DB 'Get Process Info',0
    
get_process_info    Proc near
    push ds
    push eax
    push ebx
    push esi
    push edi
;
    GetProcessId
    jc gmpDone
;
    mov edx,eax
    mov ebx,eax
    ProcessIdToSel
    jc gmpDone
;
    mov ds,ebx
    mov esi,OFFSET pf_name

gmpCopyLoop:
    lodsb
    stosb
    or al,al
    jz gmpCopyDone
;
    loop gmpCopyLoop
;
    xor al,al
    mov es:[edi-1],al

gmpCopyDone:
    clc

gmpDone:
    pop edi
    pop esi
    pop ebx
    pop eax
    pop ds
    ret
get_process_info    Endp

get_process_info16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_process_info
;
    pop edi
    pop ecx
    ret
get_process_info16   Endp

get_process_info32   Proc far
    call get_process_info
    ret
get_process_info32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProcessThreads
;
;           DESCRIPTION:    Get process threads
;
;           PARAMETERS:     BX          Process ID
;                           ES:(E)DI    Thread ID buffer (2 bytes per entry)
;                           (E)CX       Max thread ids
;
;           RETURNS:        ECX         Actual threads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_process_threads_name DB 'Get Process Threads',0
    
get_process_threads    Proc near
    push ds
    push ebx
    push edx
    push esi
    push edi
;
    movzx ebx,bx
    ProcessIdToSel
    jc gpftDone
;
    mov ds,ebx
    EnterSection ds:pf_section
;
    movzx edx,ds:pf_thread_count
    mov esi,OFFSET pf_thread_arr

gpftCopy:
    or edx,edx
    jz gpftLeave
;
    dec edx
    lodsw
    stosw
    loop gpftCopy

gpftLeave:
    movzx ecx,ds:pf_thread_count
    LeaveSection ds:pf_section
    clc

gpftDone:
    pop edi
    pop esi
    pop edx
    pop ebx
    pop ds
    ret
get_process_threads    Endp

get_process_threads16   Proc far
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_process_threads
;
    pop edi
    ret
get_process_threads16   Endp

get_process_threads32   Proc far
    call get_process_threads
    ret
get_process_threads32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProcessModules
;
;           DESCRIPTION:    Get process modules
;
;           PARAMETERS:     BX          Process ID
;                           ES:(E)DI    Module ID buffer (2 bytes per entry)
;                           (E)CX       Max module ids
;
;           RETURNS:        ECX         Actual modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_process_modules_name DB 'Get Process Modules',0
    
get_process_modules    Proc near
    push ds
    push ebx
    push edx
    push esi
    push edi
;
    movzx ebx,bx
    ProcessIdToSel
    jc gpfmDone
;
    mov ds,ebx
    EnterSection ds:pf_section
;
    movzx edx,ds:pf_module_count
    mov esi,OFFSET pf_module_arr

gpfmCopy:
    or edx,edx
    jz gpfmLeave
;
    dec edx
    lodsw
    stosw
    loop gpfmCopy

gpfmLeave:
    movzx ecx,ds:pf_module_count
    LeaveSection ds:pf_section
    clc

gpfmDone:
    pop edi
    pop esi
    pop edx
    pop ebx
    pop ds
    ret
get_process_modules    Endp

get_process_modules16   Proc far
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_process_modules
;
    pop edi
    ret
get_process_modules16   Endp

get_process_modules32   Proc far
    call get_process_modules
    ret
get_process_modules32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProcessModuleUsage
;
;           DESCRIPTION:    Get usage count for module
;
;           PARAMETERS:     BX          Process ID
;                           DX          Module ID
;
;           RETURNS:        ECX         Usage
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_process_module_usage_name DB 'Get Process Module Usage',0
    
get_process_module_usage    Proc far
    push ds
    push ebx
    push esi
;
    movzx ebx,bx
    ProcessIdToSel
    jc gpmuDone
;
    mov ds,ebx
    EnterSection ds:pf_section
;
    movzx ecx,ds:pf_module_count
    xor esi,esi
    xor eax,eax

gpmuFind:
    cmp dx,ds:[esi].pf_module_arr
    jne gpmuNext
;
    movzx ecx,ds:[esi].pf_module_usage_arr
    jmp gpmuDone

gpmuNext:
    add esi,2
    loop gpmuFind
;
    xor ecx,ecx

gpmuDone:
    LeaveSection ds:pf_section
    clc
;
    pop esi
    pop ebx
    pop ds
    ret
get_process_module_usage    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AppThreadStarted
;
;           DESCRIPTION:    Startup of app thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_thread_started:
    pushfd
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp,esp
    add ebp,28
    push dword ptr [ebp+4].load_eax
    mov eax,[ebp+4].load_eip
    mov [ebp].load_eip,eax
    mov eax,[ebp+4].load_cs
    mov [ebp].load_cs,eax
    pop dword ptr [ebp].load_eflags   
;
    push ds
    push es
    push fs
    push gs
;
    GetThread
    mov ds,ax
    mov ds,ds:p_loader
    call fword ptr ds:loader_start_thread_proc
;
    pop gs
    pop fs
    pop es
    pop ds
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateAppThread
;
;           DESCRIPTION:    Create application thread
;
;           PARAMETERS:     DS          New thread 
;                           ECX         User stack size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_app_thread_name  DB 'Create App Thread', 0

create_app_thread    Proc far
    push es
    push eax
    push ebx
    push edx
;
    GetThread
    mov es,ax
    mov es,es:p_loader
;
    mov eax,ecx
    call fword ptr es:loader_init_thread_proc
;
    mov ax,ds:p_ss
    test al,3
    jnz catStackOk
; 
    mov eax,ecx
    call fword ptr es:loader_allocate_mem_proc
    mov ds:p_ss,flat_data_sel
    mov dword ptr ds:p_rsp,edx

catStackOk:
    mov ax,ds:p_cs
    cmp ax,flat_code_sel
    je catFlat
;
    int 3

catFlat:
    mov edx,dword ptr ds:p_rsp
;
    mov ax,ds:p_kernel_ss
    mov ds:p_ss,ax
    mov es,eax
    mov ebx,stack0_size
;
    sub ebx,4
    mov eax,flat_data_sel
    mov es:[ebx],eax
;
    sub ebx,4
    mov es:[ebx],edx
;
    sub ebx,4
    movzx eax,ds:p_cs
    mov es:[ebx],eax
;
    sub ebx,4
    mov eax,dword ptr ds:p_rip
    mov es:[ebx],eax
;
    mov dword ptr ds:p_rsp,ebx
;
    mov ax,cs
    mov ds:p_cs,ax
    mov dword ptr ds:p_rip,OFFSET app_thread_started
;
    pop edx
    pop ebx
    pop eax
    pop es
    ret
create_app_thread       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TerminateAppThreadKernel
;
;           DESCRIPTION:    Terminate application thread, callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

terminate_app_thread_kernel:
    GetThread
    mov es,ax
    mov es,es:p_loader
    call fword ptr es:loader_free_thread_kernel_proc
;
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TerminateAppThread
;
;           DESCRIPTION:    Terminate application thread with user stack
;
;           PARAMETERS:     EBP         Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

terminate_app_thread_name  DB 'Terminate App Thread', 0

terminate_app_thread:
    add esp,8
;
    push ds
    push es
    push fs
    push gs
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:term_gate_sel
;
    GetThread
    mov ds,eax
    mov ax,ds:p_loader
    or ax,ax
    stc
    jz terminate_app_thread_fail
;
    mov ds,eax
    call fword ptr ds:loader_add_gate_proc
    call fword ptr ds:loader_free_thread_user_proc
;
    pop gs
    pop fs
    pop es
    pop ds
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

terminate_app_thread_fail:
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    init module
;
;       RETURN VALUE:   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

system_program_name DB "System", 0

    public InitExec_

InitExec_    Proc near
    mov ax,SEG data
    mov ds,eax
    mov es,eax
    mov ds:loader_count,0
;
    mov edi,OFFSET focus_console_arr
    mov ecx,256
    xor ax,ax
    rep stosw
    mov ds:focus_current_console,0
    InitSection ds:focus_section
;
    AllocateGdt
    or bl,3
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET terminate_app_thread_kernel
    xor cl,cl
    CreateCallGateSelector32
    mov es:term_gate_sel,bx
;
    AllocateGdt
    or bl,3
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET unload_dll
    xor cl,cl
    CreateCallGateSelector32
    mov es:free_dll_gate_sel,bx
;
    AllocateGdt
    or bl,3
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET UnloadProcess
    xor cl,cl
    CreateCallGateSelector32
    mov es:exit_gate_sel,bx
;
    mov eax,SIZE program_struc
    AllocateSmallGlobalMem
    mov ax,es
    mov gs,ax
;
    call InitProgramBlock
    mov eax,7
    mov ecx,eax
    AllocateSmallGlobalMem
    mov esi,OFFSET system_program_name
    xor edi,edi
    rep movs byte ptr es:[edi],cs:[esi]
    mov gs:pr_name_sel,es
;
    mov ebx,gs
    ProgramCreated
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET register_loader
    mov edi,OFFSET register_loader_name
    xor cl,cl
    mov ax,register_loader_nr
    RegisterOsGate
;
    mov esi,OFFSET start_programs
    mov edi,OFFSET start_programs_name
    xor cl,cl
    mov ax,start_programs_nr
    RegisterOsGate
;
    mov esi,OFFSET get_exe_start32
    mov edi,OFFSET get_exe_start32_name
    xor cl,cl
    mov ax,get_exe_start32_nr
    RegisterOsGate
;
    mov esi,OFFSET app_patch
    mov edi,OFFSET app_patch_name
    xor cl,cl
    mov ax,app_patch_nr
    RegisterOsGate
;
    mov esi,OFFSET alias_module_handle
    mov edi,OFFSET alias_module_handle_name
    xor cl,cl
    mov ax,alias_module_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET get_module_by_index
    mov edi,OFFSET get_module_by_index_name
    xor cl,cl
    mov ax,get_module_by_index_nr
    RegisterOsGate
;
    mov esi,OFFSET find_module_by_address
    mov edi,OFFSET find_module_by_address_name
    xor cl,cl
    mov ax,find_module_by_address_nr
    RegisterOsGate
;
    mov esi,OFFSET find_module_by_name
    mov edi,OFFSET find_module_by_name_name
    xor cl,cl
    mov ax,find_module_by_name_nr
    RegisterOsGate
;
    mov esi,OFFSET create_app_thread
    mov edi,OFFSET create_app_thread_name
    xor cl,cl
    mov ax,create_app_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET terminate_app_thread
    mov edi,OFFSET terminate_app_thread_name
    xor cl,cl
    mov ax,terminate_app_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET removed_process
    mov edi,OFFSET removed_process_name
    xor cl,cl
    mov ax,removed_process_nr
    RegisterOsGate
;
    mov esi,OFFSET set_focus
    mov edi,OFFSET set_focus_name
    xor dx,dx
    mov ax,set_focus_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET enable_focus
    mov edi,OFFSET enable_focus_name
    xor dx,dx
    mov ax,enable_focus_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET load_program16
    mov esi,OFFSET load_program32
    mov edi,OFFSET load_program_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,load_exe_nr
    RegisterUserGate
;
    mov ebx,OFFSET spawn_program16
    mov esi,OFFSET spawn_program32
    mov edi,OFFSET spawn_exe_name
    mov dx,virt_es_in OR virt_ds_in
    mov ax,spawn_exe_nr
    RegisterUserGate
;
    mov esi,OFFSET attach_debugger
    mov edi,OFFSET attach_debugger_name
    xor dx,dx
    mov ax,attach_debugger_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET unload_exe
    mov edi,OFFSET unload_exe_name
    xor dx,dx
    mov ax,unload_exe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET fork_pr
    mov edi,OFFSET fork_name
    xor dx,dx
    mov ax,fork_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_forked
    mov edi,OFFSET is_forked_name
    xor dx,dx
    mov ax,is_forked_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET wait_for_exec
    mov edi,OFFSET wait_for_exec_name
    xor dx,dx
    mov ax,wait_for_exec_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_exit_code
    mov edi,OFFSET get_exit_code_name
    xor dx,dx
    mov ax,get_exit_code_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_exe_name
    mov edi,OFFSET get_exe_name_name
    mov dx,virt_es_in
    mov ax,get_exe_name_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_cmd_line
    mov edi,OFFSET get_cmd_line_name
    mov dx,virt_es_in
    mov ax,get_cmd_line_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_env
    mov edi,OFFSET get_env_name
    mov dx,virt_es_in
    mov ax,get_env_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET fatal_error_exit
    mov edi,OFFSET fatal_error_exit_name
    xor dx,dx
    mov ax,fatal_error_exit_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_module_focus_key
    mov edi,OFFSET get_module_focus_key_name
    xor dx,dx
    mov ax,get_module_focus_key_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET load_dll16
    mov esi,OFFSET load_dll32
    mov edi,OFFSET load_dll_name
    mov dx,virt_es_in
    mov ax,load_dll_nr
    RegisterUserGate
;
    mov esi,OFFSET free_dll
    mov edi,OFFSET free_dll_name
    xor dx,dx
    mov ax,free_dll_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_current_dll
    mov edi,OFFSET get_current_dll_name
    xor dx,dx
    mov ax,get_current_dll_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_module_proc16
    mov esi,OFFSET get_module_proc32
    mov edi,OFFSET get_module_proc_name
    mov dx,virt_ds_out OR virt_es_in
    mov ax,get_module_proc_nr
    RegisterUserGate
;
    mov esi,OFFSET get_module_resource
    mov edi,OFFSET get_module_resource_name
    xor dx,dx
    mov ax,get_module_resource_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_module_name16
    mov esi,OFFSET get_module_name32
    mov edi,OFFSET get_module_name_name
    mov dx,virt_es_in
    mov ax,get_module_name_nr
    RegisterUserGate
;
    mov esi,OFFSET allocate_app_mem
    mov edi,OFFSET allocate_app_mem_name
    mov dx,virt_es_out
    mov ax,allocate_app_mem_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET free_app_mem
    mov edi,OFFSET free_app_mem_name
    mov dx,virt_es_in
    mov ax,free_app_mem_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET allocate_debug_app_mem
    mov edi,OFFSET allocate_debug_app_mem_name
    mov dx,virt_es_out
    mov ax,allocate_debug_app_mem_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET free_debug_app_mem
    mov edi,OFFSET free_debug_app_mem_name
    mov dx,virt_es_in
    mov ax,free_debug_app_mem_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_debug_event
    mov edi,OFFSET add_wait_for_debug_event_name
    xor dx,dx
    mov ax,add_wait_for_debug_event_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_debug_event
    mov edi,OFFSET get_debug_event_name
    xor dx,dx
    mov ax,get_debug_event_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_debug_event_data16
    mov esi,OFFSET get_debug_event_data32
    mov edi,OFFSET get_debug_event_data_name
    mov dx,virt_es_in
    mov ax,get_debug_event_data_nr
    RegisterUserGate
;
    mov esi,OFFSET clear_debug_event
    mov edi,OFFSET clear_debug_event_name
    xor dx,dx
    mov ax,clear_debug_event_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET continue_debug_event
    mov edi,OFFSET continue_debug_event_name
    xor dx,dx
    mov ax,continue_debug_event_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET abort_debug
    mov edi,OFFSET abort_debug_name
    xor dx,dx
    mov ax,abort_debug_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET dupl_module_file_handle
    mov edi,OFFSET dupl_module_file_handle_name
    xor dx,dx
    mov ax,dupl_module_file_handle_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_program_info16
    mov esi,OFFSET get_program_info32
    mov edi,OFFSET get_program_info_name
    mov dx,virt_es_in
    mov ax,get_program_info_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_program_modules16
    mov esi,OFFSET get_program_modules32
    mov edi,OFFSET get_program_modules_name
    mov dx,virt_es_in
    mov ax,get_program_modules_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_program_processes16
    mov esi,OFFSET get_program_processes32
    mov edi,OFFSET get_program_processes_name
    mov dx,virt_es_in
    mov ax,get_program_processes_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_dll_handle16
    mov esi,OFFSET get_dll_handle32
    mov edi,OFFSET get_dll_handle_name
    mov dx,virt_es_in
    mov ax,get_module_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_module_info16
    mov esi,OFFSET get_module_info32
    mov edi,OFFSET get_module_info_name
    mov dx,virt_es_in
    mov ax,get_module_info_nr
    RegisterUserGate
;
    mov esi,OFFSET get_module_sel
    mov edi,OFFSET get_module_sel_name
    xor dx,dx
    mov ax,get_module_sel_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_module_base
    mov edi,OFFSET get_module_base_name
    xor dx,dx
    mov ax,get_module_base_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_module_size
    mov edi,OFFSET get_module_size_name
    xor dx,dx
    mov ax,get_module_size_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_process_info16
    mov esi,OFFSET get_process_info32
    mov edi,OFFSET get_process_info_name
    mov dx,virt_es_in
    mov ax,get_process_info_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_process_threads16
    mov esi,OFFSET get_process_threads32
    mov edi,OFFSET get_process_threads_name
    mov dx,virt_es_in
    mov ax,get_process_threads_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_process_modules16
    mov esi,OFFSET get_process_modules32
    mov edi,OFFSET get_process_modules_name
    mov dx,virt_es_in
    mov ax,get_process_modules_nr
    RegisterUserGate
;
    mov esi,OFFSET get_process_module_usage
    mov edi,OFFSET get_process_module_usage_name
    xor dx,dx
    mov ax,get_process_module_usage_nr
    RegisterBimodalUserGate
    ret
InitExec_    Endp

_TEXT    ENDS

    END
