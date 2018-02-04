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
; EXEC.ASM
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

code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code

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
    retf32

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
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateSpawnProg
;
;           DESCRIPTION:    Make global copy of program name
;
;           PARAMETERS:     DS:ESI      Filename
;               GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSpawnProg Proc near
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov edi,esi
    xor ecx,ecx

csprLoop:
    lods byte ptr [esi]
    or al,al
    jz csprSizeOk
;
    inc ecx
    jmp csprLoop

csprSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    mov gs:s_name,es
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
;    
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    ret
CreateSpawnProg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateSpawnParam
;
;           DESCRIPTION:    Make global copy of parameters
;
;           PARAMETERS:     ES:EDI      Param struc
;               GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSpawnParam Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov eax,es:[edi].lp_param_sel
    or ax,3
    verr ax
    stc
    jnz cspaNoParam
;
    mov ds,ax
    mov esi,es:[edi].lp_param_offs
    mov edi,esi
    xor ecx,ecx

cspaLoop:
    lods byte ptr [esi]
    or al,al
    jz cspaSizeOk
;
    inc ecx
    jmp cspaLoop

cspaSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    jmp cspaDone

cspaNoParam:
    mov eax,1
    AllocateSmallGlobalMem
    xor edi,edi
    xor al,al
    stos byte ptr es:[edi]

cspaDone:    
    mov gs:s_cmd,es
;       
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
CreateSpawnParam Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateSpawnStartDir
;
;           DESCRIPTION:    Make global copy of start dir
;
;           PARAMETERS:     ES:EDI      Param struc
;               GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSpawnStartDir Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov eax,es:[edi].lp_startdir_sel
    or ax,3
    verr ax
    stc
    jnz cssdNoStartDir
;
    mov ds,ax
    mov esi,es:[edi].lp_startdir_offs
    mov edi,esi
    xor ecx,ecx

cssdLoop:
    lods byte ptr [esi]
    or al,al
    jz cssdSizeOk
;
    inc ecx
    jmp cssdLoop

cssdSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    jmp cssdDone

cssdNoStartDir:
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

cssdDone:    
    mov gs:s_curr_dir,es
;       
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
CreateSpawnStartDir Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateSpawnEnv
;
;           DESCRIPTION:    Make global copy of environment variables
;
;           PARAMETERS:     ES:EDI      Param struc
;               GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSpawnEnv Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov eax,es:[edi].lp_env_sel
    or ax,3
    verr ax
    stc
    jnz cseNoEnv
;
    mov ds,ax
    mov esi,es:[edi].lp_env_offs
    mov edi,esi
    xor ecx,ecx

cseLoop:
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz cseLoop
;
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz cseLoop

cseSizeOk:
    mov esi,edi
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    jmp cseDone

cseNoEnv:
    OpenProcEnv
    GetEnvSize
    movzx eax,ax
    AllocateSmallGlobalMem
    xor di,di
    GetEnvData
    CloseEnv

cseDone:    
    mov gs:s_env,es
;       
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
CreateSpawnEnv Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupSpawnDir
;
;           DESCRIPTION:    Setup spawn directory
;
;           PARAMETERS:     GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupSpawnDir Proc near
    push es
    push ax
    push di
;
    mov es,gs:s_curr_dir
    xor di,di
    mov ax,es:[di]
    cmp ah,':'
    jne spDirOk
;
    sub al,'A'
    jc spDirOk
;
    cmp al,26
    jc spSetDrive
;
    sub al,20h
    jc spDirOk
;
    cmp al,26
    jnc spDirOk

spSetDrive:
    SetCurDrive
    add di,2
    SetCurDir
    
spDirOk:
    pop di
    pop ax
    pop es
    ret
SetupSpawnDir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupSpawnEnv
;
;           DESCRIPTION:    Setup spawn environment
;
;           PARAMETERS:     GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupSpawnEnv Proc near
    push es
    push bx
    push di
;
    mov es,gs:s_env
    xor di,di
;
    OpenProcEnv
    SetEnvData
    CloseEnv
;
    pop di
    pop bx
    pop es
    ret
SetupSpawnEnv   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeSpawn
;
;           DESCRIPTION:    Free spawn environment
;
;           PARAMETERS:     GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeSpawn Proc near
    mov es,gs:s_name
    FreeMem
;
    mov es,gs:s_cmd
    FreeMem
;
    mov es,gs:s_curr_dir
    FreeMem
;
    mov es,gs:s_env
    FreeMem    
;
    mov ax,gs
    mov es,ax
    xor ax,ax
    mov gs,ax
    FreeMem
    ret
FreeSpawn   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupSpawn
;
;           DESCRIPTION:    Setup spawn
;
;           PARAMETERS:     DX      Debug module handle
;
;       RETURNS:    GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupSpawn Proc near    
    push ds
    push eax
    push bx
; 
    push es
    mov eax,SIZE spawn_struc
    AllocateSmallGlobalMem
    mov ax,es
    mov gs,ax
    pop es
;  
    mov gs:s_name,0
    mov gs:s_cmd,0
    mov gs:s_curr_dir,0
    mov gs:s_env,0
    mov gs:s_param,0
    mov bx,dx
    DerefModuleHandle
    jc spDebugOk
;    
    mov gs:s_param,bx

spDebugOk:
    mov gs:s_switch,0
;
    GetThread
    mov bx,ax
    GetThreadFocusKey
    jc spFocusDone
;
    mov gs:s_switch,al

spFocusDone:
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov gs:s_parent_app_sel,ds
    mov eax,ds:app_loader_name
    mov gs:s_loader_name,eax
;
    InitSection gs:s_sect1
    mov gs:s_sect1.cs_value,-1
;
    pop bx
    pop eax
    pop ds
    ret
SetupSpawn  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoSpawn
;
;           DESCRIPTION:    Do spawn
;
;           PARAMETERS:     GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoSpawn Proc near       
    push ds
    push es
    push ax
    push bx
    push ecx
    push si
    push di
;    
    mov es,gs:s_name
    xor edi,edi
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET spawn_startup
    mov bx,gs
    mov ax,2
    mov ecx,stack0_size
    CreateProcess
;
    pop di
    pop si
    pop ecx
    pop bx
    pop ax
    pop es
    pop ds
    ret
DoSpawn Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoSpawn64
;
;           DESCRIPTION:    Do spawn, 64-bit
;
;           PARAMETERS:     GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoSpawn64 Proc near       
    push ds
    push es
    push ax
    push bx
    push ecx
    push si
    push di
;    
    mov es,gs:s_name
    xor edi,edi
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET spawn_startup64
    mov bx,gs
    mov ax,202h
    mov ecx,stack0_size
    CreateProcess
;
    pop di
    pop si
    pop ecx
    pop bx
    pop ax
    pop es
    pop ds
    ret
DoSpawn64 Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForSpawn
;
;           DESCRIPTION:    Wait for spawn
;
;           PARAMETERS:     GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForSpawn Proc near  
    push ds
    push ax
;    
    mov ax,gs
    mov ds,ax
    EnterSection ds:s_sect1
;
    pop ax
    pop ds
    ret
WaitForSpawn    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetSpawnThread
;
;           DESCRIPTION:    Get spawned thread id
;
;           PARAMETERS:     GS      Spawn sel
;
;       RETURNS:    AX      Thread id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSpawnThread Proc near
    push es
    mov ax,gs:s_thread
    mov es,ax
    mov ax,es:p_id
    pop es
    ret
GetSpawnThread  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateSpawnHandle
;
;           DESCRIPTION:    Create new spawn handle
;
;           PARAMETERS:     GS      Spawn sel
;
;       RETURNS:    BX      Process handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSpawnHandle Proc near
    push ax
    push dx
;    
    mov ax,gs:s_param
    or ax,ax
    jz spLibOk
;       
    push es
    mov es,gs:s_app
    mov ax,es:app_mod_sel
    pop es

spLibOk:
    mov dx,gs:s_proc_sel
    CreateProcHandle
;    
    pop dx
    pop ax
    ret
CreateSpawnHandle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SpawnStartup
;
;           DESCRIPTION:    Spawn startup stub
;
;           PARAMETERS:     BX      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

spawn_startup:
    sti
    mov gs,bx
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
    push es
    GetThread
    mov es,ax
    mov es,es:p_app_sel
    mov es:app_context,bx
    mov es:app_unload_proc,OFFSET spUnload
;
    mov ds,gs:s_parent_app_sel
    AppNotifySpawn
;
    mov ax,3Bh
    EnableFocus
    SetFocus
    mov es:app_key,al
;
    xor si,si
    mov ds,gs:s_name    
    mov di,OFFSET app_exe_name

spCopyExeLoop:
    lodsb
    stosb
    or al,al
    jne spCopyExeLoop
;
    pop ds
    xor bx,bx
;
    GetThread
    mov es,ax
    mov al,gs:s_switch
    mov es:p_parent_switch,al
;       
    GetThread
    mov gs:s_thread,ax
;
    call SetupSpawnDir
    call SetupSpawnEnv
;       
    xor di,di
    mov es,gs:s_name
    mov cx,O_RDONLY OR O_BINARY
    OpenKernelFile
    jc spFail
;
    xor esi,esi
    xor edi,edi
    mov ds,gs:s_name
    mov es,gs:s_cmd
;
    Exec
    jc spCloseFail
;
    mov gs:s_ret_code,0
    GetThread
    mov ds,ax
    mov ax,ds:p_app_sel
    mov gs:s_app,ax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_process_sel
    mov ax,ds:ms_pd_sel
    mov gs:s_proc_sel,ax
;
    mov ax,gs
    mov ds,ax
    mov es,ax
    LeaveSection ds:s_sect1
    WaitForSignal
;
    mov ax,10
    WaitMilliSec
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov eax,ds:app_spawn_proc
    or eax,ds:app_spawn_proc+4
    jz spNotifyDone
;
    call fword ptr ds:app_spawn_proc

spNotifyDone:
    call FreeSpawn
;
    test byte ptr [bp+2].load_eflags,2
    jnz spVm16
;
    mov ds,[bp].load_ds
    mov es,[bp].load_es
    mov fs,[bp].load_fs
    mov gs,[bp].load_gs

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
    CloseFile

spFail:
    mov gs:s_ret_code,-1
    mov ax,gs
    mov ds,ax
    LeaveSection ds:s_sect1
    WaitForSignal
;
    mov ax,10
    WaitMilliSec
;
    call FreeSpawn
    UnloadExe

spUnload:
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SpawnStartup64
;
;           DESCRIPTION:    Spawn startup stub, 64-bit version
;
;           PARAMETERS:     BX      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

spawn_startup64:
    sti
    mov gs,bx
    GetThread
    mov es,ax
;
    mov ax,3Bh
    EnableFocus
    SetFocus
;
    GetThread
    mov es,ax
    mov al,gs:s_switch
    mov es:p_parent_switch,al
;       
    GetThread
    mov gs:s_thread,ax
;
    call SetupSpawnDir
    call SetupSpawnEnv
;
    xor esi,esi
    xor edi,edi
    mov ds,gs:s_name
    mov es,gs:s_cmd
    InitLongExe
    jc spFail64
;    
    mov gs:s_ret_code,0
    mov gs:s_app,0
;
    GetThread
    mov ds,ax
    mov ds,ds:p_process_sel
    mov ax,ds:ms_pd_sel
    mov gs:s_proc_sel,ax
;
    mov ax,gs
    mov ds,ax
    mov es,ax
    LeaveSection ds:s_sect1
    WaitForSignal
;
    mov ax,10
    WaitMilliSec
;
    call FreeSpawn
    StartLongExe

spFail64:
    mov gs:s_ret_code,-1
    mov ax,gs
    mov ds,ax
    LeaveSection ds:s_sect1
    WaitForSignal
;
    mov ax,10
    WaitMilliSec
;
    call FreeSpawn
    UnloadExe

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           spawn_program16/32
;
;           DESCRIPTION:    Load & detach executable file
;
;           PARAMETERS:     DS:(E)SI    Filename
;                           ES:(E)DI    Parameters
;                               +0  command line
;                               +8  startdir
;                               +12 env
;                           DX              Debug module handle
;
;       RETURN VALUE:   AX          Thread ID
;               DX      Process handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

spawn_exe_name  DB 'Spawn Exe',0

spawn_program   Proc near
    push gs
    push bx
    push cx
;
    UserGateForce32 is_64_bit_exe_nr
    jc spProt
;
    call SetupSpawn
    call CreateSpawnProg
    call CreateSpawnParam
    call CreateSpawnStartDir
    call CreateSpawnEnv
;
    call DoSpawn64    
    jmp spWait
    
spProt:
    call SetupSpawn
    call CreateSpawnProg
    call CreateSpawnParam
    call CreateSpawnStartDir
    call CreateSpawnEnv
;
    call DoSpawn

spWait:    
    call WaitForSpawn
;
    mov cx,gs:s_ret_code
    or cx,cx
    jnz spLeave
;    
    call GetSpawnThread
    call CreateSpawnHandle
    mov dx,bx

spLeave:
    push cx
    mov bx,gs:s_thread
    xor cx,cx
    mov gs,cx    
    Signal
    pop cx
;
    or cx,cx
    jz spOk
;
    stc
    jmp spDone

spOk:
    clc

spDone:
    pop cx
    pop bx
    pop gs
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
    retf32
spawn_program16 Endp
    
spawn_program32 Proc far
    call spawn_program
    retf32
spawn_program32 Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateExecProg
;
;           DESCRIPTION:    Make global copy of program name
;
;           PARAMETERS:     DS:ESI      Filename
;                           GS          Load sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateExecProg Proc near
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov edi,esi
    xor ecx,ecx

cexrLoop:
    lods byte ptr [esi]
    or al,al
    jz cexrSizeOk
;
    inc ecx
    jmp cexrLoop

cexrSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    mov gs:el_name,es
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
;    
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    ret
CreateExecProg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateExecParam
;
;           DESCRIPTION:    Make global copy of parameters
;
;           PARAMETERS:     ES:EDI      Param struc
;                           GS          Load sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateExecParam Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov eax,es:[edi].lp_param_sel
    or ax,3
    verr ax
    stc
    jnz cexpNoParam
;
    mov ds,ax
    mov esi,es:[edi].lp_param_offs
    mov edi,esi
    xor ecx,ecx

cexpLoop:
    lods byte ptr [esi]
    or al,al
    jz cexpSizeOk
;
    inc ecx
    jmp cexpLoop

cexpSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    jmp cexpDone

cexpNoParam:
    mov eax,1
    AllocateSmallGlobalMem
    xor edi,edi
    xor al,al
    stos byte ptr es:[edi]

cexpDone:    
    mov gs:el_cmd,es
;       
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
CreateExecParam Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateExecStartDir
;
;           DESCRIPTION:    Make global copy of start dir
;
;           PARAMETERS:     ES:EDI      Param struc
;                           GS          Load sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateExecStartDir Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov eax,es:[edi].lp_startdir_sel
    or ax,3
    verr ax
    stc
    jnz cexsdNoStartDir
;
    mov ds,ax
    mov esi,es:[edi].lp_startdir_offs
    mov edi,esi
    xor ecx,ecx

cexsdLoop:
    lods byte ptr [esi]
    or al,al
    jz cexsdSizeOk
;
    inc ecx
    jmp cexsdLoop

cexsdSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    jmp cexsdDone

cexsdNoStartDir:
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

cexsdDone:    
    mov gs:el_curr_dir,es
;       
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
CreateExecStartDir Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateExecEnv
;
;           DESCRIPTION:    Make global copy of environment variables
;
;           PARAMETERS:     ES:EDI      Param struc
;                           GS          Load sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateExecEnv Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov eax,es:[edi].lp_env_sel
    or ax,3
    verr ax
    stc
    jnz cexeNoEnv
;
    mov ds,ax
    mov esi,es:[edi].lp_env_offs
    mov edi,esi
    xor ecx,ecx

cexeLoop:
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz cexeLoop
;
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz cexeLoop

cexeSizeOk:
    mov esi,edi
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    jmp cexeDone

cexeNoEnv:
    OpenProcEnv
    GetEnvSize
    movzx eax,ax
    AllocateSmallGlobalMem
    xor di,di
    GetEnvData
    CloseEnv

cexeDone:    
    mov gs:el_env,es
;       
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
CreateExecEnv Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupExecDir
;
;           DESCRIPTION:    Setup spawn directory
;
;           PARAMETERS:     GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupExecDir Proc near
    push es
    push ax
    push di
;
    mov es,gs:el_curr_dir
    xor di,di
    mov ax,es:[di]
    cmp ah,':'
    jne sexDirOk
;
    sub al,'A'
    jc sexDirOk
;
    cmp al,26
    jc sexSetDrive
;
    sub al,20h
    jc sexDirOk
;
    cmp al,26
    jnc sexDirOk

sexSetDrive:
    SetCurDrive
    add di,2
    SetCurDir
    
sexDirOk:
    pop di
    pop ax
    pop es
    ret
SetupExecDir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupExecEnv
;
;           DESCRIPTION:    Setup exec environment
;
;           PARAMETERS:     GS      Load sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupExecEnv Proc near
    push es
    push bx
    push di
;
    mov es,gs:el_env
    xor di,di
;
    OpenProcEnv
    SetEnvData
    CloseEnv
;
    pop di
    pop bx
    pop es
    ret
SetupExecEnv   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeExec
;
;           DESCRIPTION:    Free exec environment
;
;           PARAMETERS:     GS      Load sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeExec Proc near
    mov es,gs:el_name
    FreeMem
;
    mov es,gs:el_cmd
    FreeMem
;
    mov es,gs:el_curr_dir
    FreeMem
;
    mov es,gs:el_env
    FreeMem    
;
    mov ax,gs
    mov es,ax
    xor ax,ax
    mov gs,ax
    FreeMem
    ret
FreeExec   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupExec
;
;           DESCRIPTION:    Setup exec
;
;           RETURNS:        GS      Load sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupExec Proc near    
    push ds
    push eax
    push bx
; 
    push es
    mov eax,SIZE exec_load_struc
    AllocateSmallGlobalMem
    mov ax,es
    mov gs,ax
    pop es
;  
    mov gs:el_name,0
    mov gs:el_cmd,0
    mov gs:el_curr_dir,0
    mov gs:el_env,0
    mov gs:el_param,0
    mov gs:el_wake_thread,0
    mov gs:el_done,0
;
    GetThread
    mov ds,ax
    mov ax,ds:p_id
    mov gs:el_pid,ax
    mov ds,ds:p_app_sel
;
    pop bx
    pop eax
    pop ds
    ret
SetupExec  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           load_program16/32
;
;           DESCRIPTION:    Load executable file
;
;           PARAMETERS:     DS:(E)SI    Filename
;                           ES:(E)DI    Parameters
;                               +0  command line
;                               +8  startdir
;                               +12 env
;
;       RETURN VALUE:   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_program_name   DB 'Load Program',0

load_program   Proc near
    push gs
    push bx
    push cx
;
    call SetupExec
    call CreateExecProg
    call CreateExecParam
    call CreateExecStartDir
    call CreateExecEnv
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
    mov es:app_unload_proc,OFFSET lepRet
    AppNotifyExec
;
    GetThread
    mov es,ax
    xor si,si
    mov ds,gs:el_name    
    mov di,OFFSET thread_name
    mov cx,32

lepThreadNameLoop:
    lodsb
    or al,al
    jz lepThreadNamePad
;
    stosb
    loop lepThreadNameLoop

lepThreadNamePad:
    or cx,cx
    jz lepThreadNameDone
;
    mov al,' '
    rep stosb

lepThreadNameDone:
    mov es,es:p_app_sel
    xor si,si
    mov ds,gs:el_name    
    mov di,OFFSET app_exe_name

lepCpExeLoop:
    lodsb
    stosb
    or al,al
    jne lepCpExeLoop
;
    xor bx,bx
;
    call SetupExecDir
    call SetupExecEnv
;       
    xor di,di
    mov es,gs:el_name
    mov cx,O_RDONLY OR O_BINARY
    OpenKernelFile
    jc lepFail
;
    xor esi,esi
    xor edi,edi
    mov ds,gs:el_name
    mov es,gs:el_cmd
    Exec
    jc lepFail
;
    mov gs:el_ret_code,0
;
    test byte ptr [bp+2].load_eflags,2
    jnz lepVm16
;
    mov ds,[bp].load_ds
    mov es,[bp].load_es
    mov fs,[bp].load_fs
    mov gs,[bp].load_gs

lepVm16:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

lepFail:
    mov ax,-1
    UnloadExe

lepRet:
    push ax
    GetThread
    mov ds,ax
    mov ds:p_temp_word,fs
    mov ds,ds:p_app_sel
    mov bx,ds:app_context
    pop ax
    mov ds:app_exit_code,ax
    RestoreContext
;
    GetThread
    mov ds,ax
    mov fs,ds:p_temp_word
    mov ds,ds:p_app_sel
    mov ax,ds:app_exit_code    
    mov gs:el_ret_code,ax
    mov gs:el_done,1
    TerminateThread
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
;           NAME:           unload_exe
;
;           DESCRIPTION:    Unload running program
;
;           PARAMETERS:         AX          Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unload_exe_name DB 'Unload Exe',0
    
unload_exe:
    push ax
    GetThread
    mov ds,ax
    pop ax
;       
    mov ds,ds:p_process_sel
    mov ds,ds:ms_pd_sel
    mov ds:pd_exit_code,ax
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
    retf32
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
    push ds
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_exit_code
    pop ds
    retf32
get_exit_code   Endp


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

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov ebx,OFFSET load_program16
    mov esi,OFFSET load_program32
    mov edi,OFFSET load_program_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,load_exe_nr
    RegisterUserGate
;
    mov esi,OFFSET dos_ext_exec16
    mov edi,OFFSET dos_ext_exec_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,dos_ext_exec_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET unload_exe
    mov edi,OFFSET unload_exe_name
    xor dx,dx
    mov ax,unload_exe_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET spawn_program16
    mov esi,OFFSET spawn_program32
    mov edi,OFFSET spawn_exe_name
    mov dx,virt_es_in OR virt_ds_in
    mov ax,spawn_exe_nr
    RegisterUserGate
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
    ret
init    ENDP

code    ENDS

    END init
