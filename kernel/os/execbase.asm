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
INCLUDE chandle.inc

.386p

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dos_ext_exec
;
;           DESCRIPTION:    DOS extender load
;
;           PARAMETERS:     DS:(E)SI    Filename
;                           ES:(E)DI    Command line
;
;       RETURN VALUE:   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dos_ext_exec_name       DB 'DOS Extender Exec',0
    
dos_ext_exec16:
    pop ax
    pop dx
    movzx edx,dx
    push edx
    movzx eax,ax
    push eax
    SaveContext
    xor eax,eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
;
    movzx esi,si
    movzx edi,di
    push es
    push di
    GetThread
    mov es,ax
    mov es,es:p_app_sel
    mov es:app_context,bx
    mov es:app_unload_proc,OFFSET unload_dos_ext
;
    push si
    mov di,OFFSET app_exe_name

dos_ext_copy_exe_loop16:
    lodsb
    stosb
    or al,al
    jne dos_ext_copy_exe_loop16
;
    pop di
;
    movzx esi,di
    mov ax,ds
    mov es,ax
    xor cx,cx
    OpenFile
    pop di
    pop es
    jc dos_ext_fail16
;
    LoadDosExe
    jc dos_ext_close_fail16
;
    test byte ptr [bp+2].load_eflags,2
    jnz dos_ext_prog_vm16
;
    mov ds,[bp].load_ds
    mov es,[bp].load_es
    mov fs,[bp].load_fs
    mov gs,[bp].load_gs

dos_ext_prog_vm16:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

dos_ext_close_fail16:
    CloseFile

dos_ext_fail16:
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov bx,ds:app_context
    RestoreContext
    push ds
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_exit_code
    pop ds
    stc
    retf

unload_dos_ext:
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov bx,ds:app_context
    RestoreContext
    push ds
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_exit_code
    pop ds
    clc
    retf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitProcessBlock
;
;       DESCRIPTION:    Init process block
;
;       PARAMETERS:     GS      Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitProcessBlock Proc near    
    mov gs:pr_name_sel,0
    mov gs:pr_cmd_sel,0
    mov gs:pr_dir_sel,0
    mov gs:pr_env_sel,0
    mov gs:pr_cmd_sel,0
    mov gs:pr_debug_sel,0
    mov gs:pr_thread,0
    mov gs:pr_switch,0
    mov gs:pr_thread_count,0
    mov gs:pr_module_count,0
    InitSection gs:pr_section
    ret
InitProcessBlock  Endp

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

system_process_name DB "System", 0

init    PROC far
    mov eax,SIZE process_struc
    AllocateSmallGlobalMem
    mov ax,es
    mov gs,ax
;
    call InitProcessBlock
    mov eax,7
    mov ecx,eax
    AllocateSmallGlobalMem
    mov esi,OFFSET system_process_name
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
    mov esi,OFFSET dos_ext_exec16
    mov edi,OFFSET dos_ext_exec_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,dos_ext_exec_nr
    RegisterBimodalUserGate
    ret
init    ENDP

_TEXT    ENDS

    END init
