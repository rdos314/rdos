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
dew_module_sel      DW ?

debug_event_wait_header ENDS

data    SEGMENT byte public 'DATA'

free_dll_gate_sel   DW ?

loader_count        DW ?
loader_arr          DW 16 DUP(?)

data    ENDS

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
;       NAME:           AllocateProcess
;
;       DESCRIPTION:    Allocate process
;
;       PARAMETERS:     DX      Debug module handle
;                       GS      Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateProcess Proc near    
    push ds
    pushad
;
    mov bx,dx
    ModuleIdToSel
    jc apDebugOk
;    
    mov gs:pr_debug_sel,bx

apDebugOk:
    mov gs:pr_switch,0
;
    GetThread
    mov bx,ax
    GetThreadFocusKey
    jc apFocusDone
;
    mov gs:pr_switch,al

apFocusDone:
    popad
    pop ds
    ret
AllocateProcess  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateProg
;
;       DESCRIPTION:    Make global copy of program name
;
;       PARAMETERS:     DS:ESI      Filename
;                       GS          Process sel
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
;           NAME:           AddProgramThread
;
;           DESCRIPTION:    Add thread to program
;
;           PARAMETERS:     ES      Thread
;                           BX      Program ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddProgramThread    Proc near
    push ds
    push eax
    push ebx
    push ecx
;
    GetProgramSel
    jc aptDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    movzx ecx,ds:pr_thread_count
    cmp ecx,MAX_PROCESS_THREADS
    jae aptLeave
;
    mov ebx,ecx
    shl ebx,1
    inc ecx
    mov ds:pr_thread_count,cx
;
    mov ax,es:p_id
    mov ds:[ebx].pr_thread_arr,ax
    
aptLeave:
    LeaveSection ds:pr_section
            
aptDone:
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
AddProgramThread    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RemoveProgramThread
;
;           DESCRIPTION:    Remove thread from program
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveProgramThread    Proc near
    push ds
    push eax
    push ebx
    push ecx
;
    movzx ebx,es:p_prog_id
    or ebx,ebx
    jnz rptStart
;
    mov ebx,1

rptStart:
    GetProgramSel
    jc rptDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    mov ax,es:p_id
    movzx ecx,ds:pr_thread_count
    mov ebx,OFFSET pr_thread_arr
    or ecx,ecx
    jz rptLeave

rptLoop:
    cmp ax,ds:[ebx]
    je rptFound
;
    add bx,2
    loop rptLoop
;
    jmp rptLeave

rptFound:
    dec ds:pr_thread_count
;
    sub ecx,1
    jz rptLeave

rptMove:
    mov ax,ds:[ebx+2]
    mov ds:[ebx],ax
    add ebx,2
    loop rptMove

rptLeave:
    LeaveSection ds:pr_section
            
rptDone:
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
RemoveProgramThread    Endp

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
    cmp ecx,MAX_PROCESS_MODULES
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
    cmp ecx,MAX_PROCESS_MODULES
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
;                       GS      Process sel
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
;       PARAMETERS:     GS          Process sel
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
;                       GS          Process sel
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
;       PARAMETERS:     GS          Process sel
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
;                       GS          Process sel
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
;       DESCRIPTION:    Put environment variables in process structure
;
;       PARAMETERS:     DS:ESI  Environment ptr
;                       GS      Process sel
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
;           PARAMETERS:     GS      Process sel
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
;           PARAMETERS:     GS      Process sel
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
;           PARAMETERS:     BX      Process ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

spawn_startup:
    sti
    GetThread
    mov es,ax
    call RemoveProgramThread
;
    mov es:p_prog_id,bx
    call AddProgramThread
;
    GetProgramSel
    mov es:p_prog_sel,ax
    mov gs,eax
;
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
    GetThread
    mov es,ax
    mov es,es:p_app_sel
    mov es:app_context,bx
    mov es:app_unload_proc,OFFSET spUnload
;
    mov ax,gs:pr_parent_app_sel
    or ax,ax
    jnz ssSpawn

ssStart:
    AppNotifyStart
    jmp ssNotifyOk

ssSpawn:
    mov ds,gs:pr_parent_app_sel
    AppNotifySpawn

ssNotifyOk:
    mov ax,3Bh
    EnableFocus
    SetFocus
    mov es:app_key,al
;
    xor esi,esi
    mov ds,gs:pr_name_sel    
    mov edi,OFFSET app_exe_name

spCopyExeLoop:
    lodsb
    stosb
    or al,al
    jne spCopyExeLoop
;
    GetThread
    mov es,ax
    mov al,gs:pr_switch
    mov es:p_parent_switch,al
;       
    GetThread
    mov gs:pr_thread,ax
    mov ds,ax
    mov ax,ds:p_app_sel
    mov gs:pr_app_sel,ax
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
    mov dx,gs:pr_debug_sel
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
;
    InitSection es:mod_section
    mov es:mod_id,bx
;    
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ds:app_mod_id,bx
    mov ds:app_mod_sel,es
    mov al,ds:app_key
    mov es:mod_key,al
;
    mov bx,es
    pop es
    pop ds
;
    mov dx,gs:pr_debug_sel
    mov fs,gs:pr_loader
    call fword ptr fs:loader_fixup_exe_proc
    call fword ptr fs:loader_setup_names_proc
 
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

spUnload:
    TerminateThread


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
;                       DX          Process ID
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
    call InitProcessBlock
    call AllocateProcess
    mov gs:pr_loader,ax
    mov gs:pr_kernel_file,bx
;
    push ds
    GetThread
    mov gs:pr_parent_thread,ax
    mov ds,ax
    mov ds,ds:p_app_sel
    mov gs:pr_parent_app_sel,ds
    pop ds
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
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET spawn_startup
    mov ax,2
    mov ecx,stack0_size
    CreateProcess

spWait:    
    WaitForSignal
    mov ax,gs:pr_thread
    or ax,ax
    jz spWait
;
    mov es,ax
    mov ax,es:p_id
;
    mov dx,gs:pr_debug_sel
    or dx,dx
    jz spLibOk
;
    mov es,gs:pr_app_sel
    mov ax,es:app_mod_sel

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
    call InitProcessBlock
    call AllocateProcess
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
    call RemoveProgramThread
;
    mov es:p_prog_id,bx
    mov es:p_prog_sel,gs
    call AddProgramThread
;
    push gs
    ExecApp
    pop gs
;
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
    GetThread
    mov es,ax
    mov es,es:p_app_sel
    mov es:app_context,bx
;    mov es:app_unload_proc,OFFSET lepRet
    AppNotifyExec
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
    mov es,es:p_app_sel
    xor esi,esi
    mov ds,gs:pr_name_sel
    mov edi,OFFSET app_exe_name

lpCpExeLoop:
    lodsb
    stosb
    or al,al
    jne lpCpExeLoop
;
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
;
    InitSection es:mod_section
    mov es:mod_id,bx
;    
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ds:app_mod_id,bx
    mov ds:app_mod_sel,es
;
    mov al,ds:app_key
    mov es:mod_key,al
;
    mov bx,es
    pop es
    pop ds
;
    mov fs,gs:pr_loader
    call fword ptr fs:loader_fixup_exe_proc
    call fword ptr fs:loader_setup_names_proc
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
;           NAME:           run_process
;
;           DESCRIPTION:    Run processes in adapter
;
;           PARAMETERS:         DS:EDX  device header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_process     PROC near
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
    call InitProcessBlock
    call AllocateProcess
    mov gs:pr_kernel_file,bx
    mov gs:pr_loader,ax
;
    GetThread
    mov gs:pr_parent_thread,ax
    mov gs:pr_parent_app_sel,0
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
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET spawn_startup
    mov ax,2
    mov ecx,stack0_size
    CreateProcess
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
run_process     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_adapter_process
;
;           DESCRIPTION:    Start all processes in adapter
;
;           PARAMETERS:         edx         base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kernel_code_text DB 'kernel.exe', 0

init_adapter_process    Proc near
    push ds
    push es
    pushad
;
    mov ax,flat_sel
    mov ds,ax
    mov es,ax

init_adapter_process_loop:
    mov ax,[edx].typ
    cmp ax,RdosCommand
    jne not_run_process
;
    call run_process
    jmp init_adapter_process_next

not_run_process:
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
    jmp init_adapter_process_next

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
    jmp init_adapter_process_next

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
    jmp init_adapter_process_next

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
    je init_adapter_process_done

init_adapter_process_next:
    add edx,[edx].len
    jmp init_adapter_process_loop

init_adapter_process_done:
    popad
    pop es
    pop ds
    ret
init_adapter_process    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartPrograms
;
;           DESCRIPTION:    Start all processes
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
    call init_adapter_process
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
;           NAME:           unload_exe
;
;           DESCRIPTION:    Unload running program
;
;           PARAMETERS:         AX          Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unload_exe_name DB 'Unload Exe',0
    
unload_exe:
    int 3
    push ax
    GetThread
    mov ds,ax
    pop ax
;
    push ax
    GetThread
    mov ds,ax
    pop ax
    mov ds,ds:p_app_sel
    jmp ds:app_unload_proc    
    
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
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov eax,ds:app_fatal_error_exit_proc
    or eax,ds:app_fatal_error_exit_proc+4
    pop eax
    stc
    jz fatal_error_exit_done
;
    call fword ptr ds:app_fatal_error_exit_proc

fatal_error_exit_done:
    pop ds
    ret
fatal_error_exit    ENDP
    
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
    movzx ebx,ds:p_prog_id
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
    mov dx,es:pr_debug_sel
    pop ebx
    mov es,bx
;
    movzx ebx,bx
    ModuleLoaded
;
    mov ebx,eax
    call AddProgramModule
;
    InitSection es:mod_section
    mov es:mod_usage,1
    mov es:mod_id,bx
    mov [ebp].load_ebx,ebx
    and byte ptr [ebp].load_eflags,NOT 1
    mov ebx,es
;
    push ebx
    call fword ptr gs:loader_fixup_dll_proc
    pop ebx
    jmp ldllDone

ldllOk:
    mov [ebp].load_ebx,ebx
;
    ModuleIdToSel
    jc ldllFail
;
    mov es,ebx
    inc es:mod_usage
    and byte ptr [ebp].load_eflags,NOT 1
    jmp ldllDone

ldllFail:
    or byte ptr [ebp].load_eflags,1
    
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
    mov bx,[esp+4]
    cmp bx,flat_code_sel
    jne load_dll_kernel32
;
    push eax
    pushfd
    pop eax
    mov [esp+8],eax
    mov eax,[esp+4]
    xchg eax,[esp]
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp,esp
    add ebp,28
    mov dword ptr [ebp].load_cs,flat_code_sel
;
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
    push ds
    push es
    push fs
    push gs
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    call load_dll
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    ret
load_dll32  Endp

load_dll16  Proc far
    mov bx,[esp+4]
    cmp bx,flat_code_sel
    jne load_dll_kernel16
;
    push eax
    pushfd
    pop eax
    mov [esp+8],eax
    mov eax,[esp+4]
    xchg eax,[esp]
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp,esp
    add ebp,28
    mov dword ptr [ebp].load_cs,flat_code_sel
;
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
    push ds
    push es
    push fs
    push gs
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    movzx edi,di
    call load_dll
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
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

unload_dll:
    push eax
    pushfd
    pop eax
    mov [esp+8],eax
    mov eax,[esp+4]
    xchg eax,[esp]
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp,esp
    add ebp,28
    mov dword ptr [ebp].load_cs,flat_code_sel
;
    push ds
    push es
    push fs
    push gs
;
    call RemoveProgramModule
;
    mov es,[ebp].load_ss
    mov edi,[ebp].load_esp
    add edi,8
    mov eax,es:[edi]
    mov [ebp].load_eip,eax
    add edi,4
    mov [ebp].load_esp,edi
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
;           NAME:           free_dll_do
;
;           DESCRIPTION:    Free DLL
;
;       PARAMETERS:         BX          Module handle
;                           EBP         Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_dll_do  Proc near
    ModuleIdToSel
    jc free_dll_done
;
    mov ds,ebx
    sub ds:mod_usage,1
    jnz free_dll_done
;
    push ds
    push es
    push edx
    push edi
;
    mov ax,SEG data
    mov ds,ax
;
    mov edx,[ebp].load_eip
    mov es,[ebp].load_ss
    mov edi,[ebp].load_esp
    sub edi,12
    mov [ebp].load_esp,edi
    mov [ebp].load_eip,edi
;
    mov al,90h
    stosb
;
    mov al,9Ah
    stosb
;
    xor eax,eax
    stosd
;
    mov ax,ds:free_dll_gate_sel
    stosw
;
    mov eax,edx
    stosd
;
    pop edi
    pop edx
    pop es
    pop ds
;
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz free_dll_done
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
    push eax
    mov ax,[esp+8]
    cmp ax,flat_code_sel
    pop eax
    jne free_dll_kernel
;
    push eax
    pushfd
    pop eax
    mov [esp+8],eax
    mov eax,[esp+4]
    xchg eax,[esp]
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp,esp
    add ebp,28
    mov dword ptr [ebp].load_cs,flat_code_sel
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
    push ds
    push es
    push fs
    push gs
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    call free_dll_do
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
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
;           DESCRIPTION:    Get primary module ID from process ID
;
;       PARAMETERS:         BX          Process ID
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
    mov bx,es:dew_module_sel
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
    mov bx,es:dew_module_sel
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
    mov bx,es:dew_module_sel
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
;           PARAMETERS:     AX      Process handle
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
    movzx ebx,ax
    ModuleIdToSel
    mov es:dew_module_sel,bx

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
;       PARAMETERS:     BX      Process handle
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
;           NAME:           init
;
;           DESCRIPTION:    init module
;
;       RETURN VALUE:   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

system_process_name DB "System", 0

init    PROC far
    mov ax,SEG data
    mov ds,eax
    mov es,eax
    mov ds:loader_count,0
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
    mov esi,OFFSET alias_module_handle
    mov edi,OFFSET alias_module_handle_name
    xor cl,cl
    mov ax,alias_module_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET dos_ext_exec16
    mov edi,OFFSET dos_ext_exec_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,dos_ext_exec_nr
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
    mov esi,OFFSET unload_exe
    mov edi,OFFSET unload_exe_name
    xor dx,dx
    mov ax,unload_exe_nr
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
    mov esi,OFFSET dupl_module_file_handle
    mov edi,OFFSET dupl_module_file_handle_name
    xor dx,dx
    mov ax,dupl_module_file_handle_nr
    RegisterBimodalUserGate
    ret
init    ENDP

_TEXT    ENDS

    END init
