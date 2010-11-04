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

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE int.def
INCLUDE exec.def
INCLUDE system.def
INCLUDE system.inc

data    SEGMENT byte public 'DATA'

load_exe_hooks  DB ?
load_exe_arr    DW 2*16 DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_LOAD_EXE
;
;           DESCRIPTION:    Add hook for LoadExe
;
;           PARAMETERS:         ES:DI       Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_load_exe_name      DB 'Hook Load Exe',0

hook_load_exe   PROC far
    push ds
    push ax
    push bx
    mov ax,SEG data
    mov ds,ax
    mov al,ds:load_exe_hooks
    mov bl,al
    xor bh,bh
    shl bx,2
    add bx,OFFSET load_exe_arr
    mov [bx],di
    mov [bx+2],es
    inc al
    mov ds:load_exe_hooks,al
    pop bx
    pop ax
    pop ds
    ret
hook_load_exe   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LOAD_EXE_FILE
;
;           DESCRIPTION:    Load executable file
;
;           PARAMETERS:     BX          File handle
;                           DS:ESI  File name
;                           ES:EDI  Command line
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_exe_file   PROC near
    push gs
    mov ax,SEG data
    mov fs,ax
    mov cl,fs:load_exe_hooks
    or cl,cl
    stc
    je load_exe_file_done
;
    mov ax,OFFSET load_exe_arr

load_exe_file_loop:
    push fs
    push ax
    push cx
;
    push bx
    mov bx,ax
    mov eax,fs:[bx]
    pop bx
;
    push cs
    push OFFSET load_exe_file_ret
    push eax
    retf

load_exe_file_ret:
    pop cx
    pop ax
    pop fs
    jnc load_exe_file_done
;
    add ax,4
    dec cl
    jnz load_exe_file_loop
;
    stc

load_exe_file_done:
    pop gs
    ret
load_exe_file   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupExec
;
;           DESCRIPTION:    Setup exec
;
;       RETURNS:    FS      Exec sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupExec Proc near     
    push ds
    push es
    push eax
; 
    mov eax,SIZE exec_struc
    AllocateSmallGlobalMem
    mov ax,es
    mov fs,ax
;  
    mov fs:e_name,0
    mov fs:e_cmd,0
    mov fs:e_opt,0
;
    pop eax
    pop es
    pop ds
    ret
SetupExec  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateExecProg
;
;           DESCRIPTION:    Make global copy of program name
;
;           PARAMETERS:     DS:ESI      Filename
;               FS      Exec sel
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

ceprLoop:
    lods byte ptr [esi]
    or al,al
    jz ceprSizeOk
;
    inc ecx
    jmp ceprLoop

ceprSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    mov fs:e_name,es
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
;           PARAMETERS:     ES:EDI      Cmd line
;               FS      Exec sel
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
    mov ax,es
    mov ds,ax
    mov esi,edi
    xor ecx,ecx

cepaLoop:
    lods byte ptr [esi]
    or al,al
    jz cepaSizeOk
;
    inc ecx
    jmp cepaLoop

cepaSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    jmp cepaDone

cepaNoParam:
    mov eax,1
    AllocateSmallGlobalMem
    xor edi,edi
    xor al,al
    stos byte ptr es:[edi]

cepaDone:    
    mov fs:e_cmd,es
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
;           NAME:           CreateExecOptions
;
;           DESCRIPTION:    Make global copy of options
;
;           PARAMETERS:     GS:EBX      Param struc
;               FS      Exec sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateExecOptions Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;   
    mov ax,gs
    mov ds,ax
    mov esi,ebx
    mov edi,esi
    xor ecx,ecx

ceoLoop:
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz ceoLoop
;
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz ceoLoop

ceoSizeOk:
    mov esi,edi
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    push ecx
    rep movs byte ptr es:[edi],ds:[esi]     
    pop ecx
    jmp ceoDone

ceoNoOpt:
    xor ax,ax
    mov es,ax
    xor ecx,ecx

ceoDone:    
    mov fs:e_opt,es
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
CreateExecOptions Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupExecOptions
;
;           DESCRIPTION:    Setup exec options
;
;           PARAMETERS:     GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupExecOptions Proc near
    push es
    push ax
;
    mov ax,gs:e_opt
    or ax,ax
    jz seoDone
;
    mov es,ax
    SetOptions

seoDone:    
    pop ax
    pop es
    ret
SetupExecOptions   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeExec
;
;           DESCRIPTION:    Free exec environment
;
;           PARAMETERS:     GS      Exec sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeExec Proc near
    push ax
;    
    xor ax,ax
    mov ds,ax
    mov es,gs:e_name
    FreeMem
;
    mov es,gs:e_cmd
    FreeMem
;
    mov ax,gs:e_opt
    or ax,ax
    jz feOptOk
;    
    mov es,ax
    FreeMem

feOptOk:
    mov ax,gs
    mov es,ax
    xor ax,ax
    mov gs,ax
    FreeMem
;
    pop ax
    ret
FreeExec   Endp 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           load_program16/32
;
;           DESCRIPTION:    Load executable file
;
;           PARAMETERS:     DS:(E)SI    Filename
;                           ES:(E)DI    Command line
;               GS:(E)BX    Options
;
;       RETURN VALUE:   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_exe_name   DB 'Load Exe',0

load_program    Proc near
    pop ax
;       
    push word ptr 0
    push cs
    push word ptr 0
    push ax
;       
    call SetupExec
    call CreateExecProg
    call CreateExecParam
    call CreateExecOptions
;       
    SimSti
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
    mov ax,fs
    mov gs,ax
    xor ax,ax
    mov fs,ax
;
    OpenApp
    GetThread
    mov es,ax
    mov es,es:p_app_sel
    mov es:app_context,bx
;
    xor si,si
    mov ds,gs:e_name
    mov di,OFFSET app_exe_name

epCopyExeLoop:
    lodsb
    stosb
    or al,al
    jne epCopyExeLoop
;
    mov es,gs:e_name
    xor di,di
    OpenFile
    jc load_fail
;
    xor esi,esi
    xor edi,edi
    mov ds,gs:e_name
    mov es,gs:e_cmd
    call load_exe_file
    jc load_close_fail
;
    call SetupExecOptions
    call FreeExec
    test byte ptr [bp+2].load_eflags,2
    jnz load_prog_vm
;
    mov ds,[bp].load_ds
    mov es,[bp].load_es
    mov fs,[bp].load_fs
    mov gs,[bp].load_gs

load_prog_vm:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

load_close_fail:
    CloseFile

load_fail:
    call FreeExec
    CloseApp
;
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
load_program    Endp
    
load_program16 Proc far
    push fs
    push ebx
    push esi
    push edi
;
    movzx ebx,bx
    movzx esi,si
    movzx edi,di    
    call load_program
;
    pop edi
    pop esi
    pop ebx
    pop fs
    ret
load_program16  Endp
    
load_program32 Proc far
    push fs
    push bx
;
    call load_program
;
    pop bx
    pop fs
    retf32
load_program32  Endp

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
    SimSti
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           load_process
;
;           DESCRIPTION:    Run program as process
;
;       RETURN VALUE:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_cmd_line   DB 0, 0Dh

load_process:
    SimSti
    mov ax,SEG data
    mov ds,ax
    mov es,bx
    xor di,di
    mov al,es:[di+1]
    cmp al,':'
    jne load_process_default_drive
    mov al,es:[di]
    sub al,'a'
    jnc load_process_set_drive
    add al,20h
load_process_set_drive:
    SetCurDrive
load_process_default_drive:
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
    mov ax,es
    mov ds,ax
    mov si,di
;       
    GetThread
    mov es,ax
    mov es,es:p_app_sel
    mov ax,3Bh
    EnableFocus
    SetFocus
    mov es:app_key,al
    mov es:app_context,bx
;       
    push si
    mov di,OFFSET app_exe_name
    mov cx,100h
    rep movsb
    pop di
    xor bx,bx
    mov ax,ds
    mov es,ax
    movzx edi,di
    xor cl,cl
    OpenFile
    jc load_process_fail
;
    xor esi,esi
    mov ax,cs
    mov es,ax
    mov di,OFFSET load_cmd_line
    call load_exe_file
    jc load_process_close_fail
;
    test byte ptr [bp+2].load_eflags,2
    jnz load_process_vm
;
    mov ds,[bp].load_ds
    mov es,[bp].load_es
    mov fs,[bp].load_fs
    mov gs,[bp].load_gs

load_process_vm:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

load_process_close_fail:
    CloseFile

load_process_fail:
    TerminateThread

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
    mov eax,es:[edi].sp_param_sel
    or ax,3
    verr ax
    stc
    jnz cspaNoParam
;
    mov ds,ax
    mov esi,es:[edi].sp_param_offs
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
    mov eax,es:[edi].sp_startdir_sel
    or ax,3
    verr ax
    stc
    jnz cssdNoStartDir
;
    mov ds,ax
    mov esi,es:[edi].sp_startdir_offs
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
    mov eax,es:[edi].sp_env_sel
    or ax,3
    verr ax
    stc
    jnz cseNoEnv
;
    mov ds,ax
    mov esi,es:[edi].sp_env_offs
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
;           NAME:           CreateSpawnOptions
;
;           DESCRIPTION:    Make global copy of options
;
;           PARAMETERS:     ES:EDI      Param struc
;               GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSpawnOptions Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov eax,es:[edi].sp_option_sel
    or ax,3
    verr ax
    stc
    jnz csoNoOpt
;
    mov ds,ax
    mov esi,es:[edi].sp_option_offs
    mov edi,esi
    xor ecx,ecx

csoLoop:
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz csoLoop
;
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz csoLoop

csoSizeOk:
    mov esi,edi
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    push ecx
    rep movs byte ptr es:[edi],ds:[esi]     
    pop ecx
    jmp csoDone

csoNoOpt:
    xor ax,ax
    mov es,ax
    xor ecx,ecx

csoDone:    
    mov gs:s_opt,es
    mov gs:s_opt_size,cx
;       
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
CreateSpawnOptions Endp

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
;           NAME:           SetupSpawnOptions
;
;           DESCRIPTION:    Setup span options
;
;           PARAMETERS:     GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupSpawnOptions Proc near
    push es
    push ax
;
    mov ax,gs:s_opt
    or ax,ax
    jz ssoDone
;
    mov es,ax
    SetOptions

ssoDone:    
    pop ax
    pop es
    ret
SetupSpawnOptions   Endp

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
    mov ax,gs:s_opt
    or ax,ax
    jz fsOptOk
;    
    mov es,ax
    FreeMem

fsOptOk:
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
    mov gs:s_opt,0
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
    mov eax,ds:app_loader_name
    mov gs:s_loader_name,eax
;
    mov gs:s_sect1.cs_value,-1
    mov gs:s_sect1.cs_list,0
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
    xor di,di
    mov ax,cs
    mov ds,ax
    mov si,OFFSET spawn_startup
    mov bx,gs
    mov ax,2
    mov ecx,200h
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
    mov gs,bx
    mov ax,SEG data
    mov ds,ax
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
    xor cx,cx
    OpenFile
    jc spFail
;
    xor esi,esi
    xor edi,edi
    mov ds,gs:s_name
    mov es,gs:s_cmd
;
    call load_exe_file
    jc spCloseFail
;
    call SetupSpawnOptions
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
    or eax,eax
    jz spNotifyDone
;
    call ds:app_spawn_proc

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           spawn_program16/32
;
;           DESCRIPTION:    Load & detach executable file
;
;           PARAMETERS:     DS:(E)SI    Filename
;                           ES:(E)DI    Parameters
;                   +0  command line
;                   +8  startdir
;                   +12 env
;                   +16 options (file redir)
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
    int 3
    UserTestForce32 get_thread_nr
;    
    call SetupSpawn
    call CreateSpawnProg
    call CreateSpawnParam
    call CreateSpawnStartDir
    call CreateSpawnEnv
    call CreateSpawnOptions
;
    call DoSpawn
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
    ret
spawn_program16 Endp
    
spawn_program32 Proc far
    call spawn_program
    retf32
spawn_program32 Endp

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
    
unload_exe      Proc far
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
    UnhookMouse
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    push ds:app_context
    CloseApp
    pop bx
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    pop ax
    or bx,bx
    jz unload_exe
;
    xor ah,ah
    sldt dx
    or dx,dx
    jz unload_terminate
;
    mov ds:app_exit_code,ax
;
    RestoreContext
    push ds
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_exit_code
    pop ds
    clc
    retf32
unload_exe      Endp

unload_terminate:
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateForkName
;
;           DESCRIPTION:    Make global copy of fork name
;
;           PARAMETERS:     DS:ESI      Filename
;               GS      Fork sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateForkName Proc near
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov edi,esi
    xor ecx,ecx

cfnLoop:
    lods byte ptr [esi]
    or al,al
    jz cfnSizeOk
;
    inc ecx
    jmp cfnLoop

cfnSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    mov gs:f_name,es
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
;
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    ret
CreateForkName Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateForkOptions
;
;           DESCRIPTION:    Make global copy of options
;
;           PARAMETERS:     ES:EDI      Options
;               GS      Fork sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateForkOptions Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov ax,es
    mov ds,ax
    mov esi,edi
    xor ecx,ecx

cfoLoop:
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz cfoLoop
;
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz cfoLoop

cfoSizeOk:
    mov esi,edi
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    mov gs:f_opt,es
;       
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
CreateForkOptions Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateForkExeName
;
;           DESCRIPTION:    Make global copy of fork exe name
;
;           PARAMETERS:     GS      Fork sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateForkExeName Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    xor edi,edi
    GetExeName
    mov esi,edi
    mov ax,es
    mov ds,ax
    xor ecx,ecx

cfenLoop:
    lods byte ptr [esi]
    or al,al
    jz cfenSizeOk
;
    inc ecx
    jmp cfenLoop

cfenSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    mov gs:f_exe_name,es
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
;
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
CreateForkExeName Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeFork
;
;           DESCRIPTION:    Free fork environment
;
;           PARAMETERS:     GS      Fork sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeFork Proc near
    mov es,gs:f_name
    FreeMem
;
    mov ax,gs:f_opt
    mov es,ax
    FreeMem
;
    mov ax,gs
    mov es,ax
    xor ax,ax
    mov gs,ax
    FreeMem
    ret
FreeFork   Endp 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupFork
;
;           DESCRIPTION:    Setup fork
;
;       RETURNS:    GS      Fork sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupFork Proc near     
    push ds
    push eax
; 
    push es
    mov eax,SIZE fork_struc
    AllocateSmallGlobalMem
    mov ax,es
    mov gs,ax
    pop es
;  
    mov gs:f_name,0
    mov gs:f_opt,0
;
    pop eax
    pop ds
    ret
SetupFork  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Fork_pr
;
;           DESCRIPTION:    Fork
;
;       PARAMETERS:     DS:(E)SI    Process name
;               ES:(E)DI    Options
;
;           RETURNS:        AX          Process handle (parent) or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fork_name DB 'Fork',0

fork_pr    Proc near
    push es
    push gs
;
    int 3
    call SetupFork
    call CreateForkName
    call CreateForkOptions
    call CreateForkExeName
;    
    CloneHandleMem
    mov gs:f_handle,es
;
    CloneApp
    mov gs:f_app,es
;
    call FreeFork
;    
    mov ax,-1
    pop gs
    pop es
    ret
fork_pr    Endp
    
fork16  Proc far
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    call fork_pr
;
    pop edi
    pop esi    
    ret
fork16  Endp
    
fork32  Proc far
    call fork_pr
    retf32
fork32  Endp

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
    pushad
    mov ecx,[edx].len
    sub ecx,SIZE rdos_header
    add edx,SIZE rdos_header
    mov esi,edx
    mov eax,1000h
    AllocateGlobalMem
    xor edi,edi
    rep movs dword ptr es:[edi],ds:[esi]
    xor edi,edi
    mov bx,es
    mov ax,cs
    mov ds,ax
    mov si,OFFSET load_process
    mov ax,2
    mov ecx,200h
    CreateProcess
    popad
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

init_adapter_process    Proc near
    push ds
    push ax
    push bx
    push edx
    mov ax,flat_sel
    mov ds,ax
init_adapter_process_loop:
    mov ax,[edx].typ
    cmp ax,RdosCommand
    jne not_run_process
    call run_process
    jmp init_adapter_process_next
not_run_process:
    cmp ax,RdosEnd
    je init_adapter_process_done
init_adapter_process_next:
    add edx,[edx].len
    jmp init_adapter_process_loop
init_adapter_process_done:
    pop edx
    pop bx
    pop ax
    pop ds
    ret
init_adapter_process    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           cmd_start_thread
;
;           DESCRIPTION:    Start all processes
;
;       RETURN VALUE:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cmd_start_name  DB 'Autostart', 0

cmd_start_thread    Proc far
    mov ax,1000
    WaitMilliSec
;
    mov ax,system_data_sel
    mov ds,ax
    mov cx,ds:rom_modules
    mov bx,OFFSET rom_adapters
init_sys_loop:
    mov edx,[bx].adapter_base
    call init_adapter_process
    add bx,SIZE adapter_typ
    loop init_sys_loop
    ret
cmd_start_thread    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_sys
;
;           DESCRIPTION:    Start all processes
;
;       RETURN VALUE:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_sys    PROC far
    push ds
    push es
    pushad
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET cmd_start_thread
    mov di,OFFSET cmd_start_name
    mov ax,4
    mov cx,1024
    CreateThread
;
    popad
    pop es
    pop ds
    ret
init_sys    ENDP

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
    mov bx,SEG data
    mov es,bx
    mov es:load_exe_hooks,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov di,OFFSET init_sys
    HookInitTasking
;
    mov si,OFFSET hook_load_exe
    mov di,OFFSET hook_load_exe_name
    xor cl,cl
    mov ax,hook_load_exe_nr
    RegisterOsGate
;
    mov bx,OFFSET load_program16
    mov si,OFFSET load_program32
    mov di,OFFSET load_exe_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,load_exe_nr
    RegisterUserGate
;
    mov si,OFFSET dos_ext_exec16
    mov di,OFFSET dos_ext_exec_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,dos_ext_exec_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET unload_exe
    mov di,OFFSET unload_exe_name
    xor dx,dx
    mov ax,unload_exe_nr
    RegisterBimodalUserGate
;
    mov bx,OFFSET spawn_program16
    mov si,OFFSET spawn_program32
    mov di,OFFSET spawn_exe_name
    mov dx,virt_es_in OR virt_ds_in
    mov ax,spawn_exe_nr
    RegisterUserGate
;
    mov bx,OFFSET fork16
    mov si,OFFSET fork32
    mov di,OFFSET fork_name
    mov dx,virt_es_in OR virt_ds_in
    mov ax,fork_nr
    RegisterUserGate
;
    mov si,OFFSET get_exit_code
    mov di,OFFSET get_exit_code_name
    xor dx,dx
    mov ax,get_exit_code_nr
    RegisterBimodalUserGate
    ret
init    ENDP

code    ENDS

    END init
