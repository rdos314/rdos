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
; DOSEXEC.ASM
; DOS exec functions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\int.def
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\exec.def
INCLUDE dos.inc

        extrn create_enviroment:near
        extrn create_psp:near
        extrn clear_psp:near
        extrn set_virt_psp:near
        extrn set_prot_psp:near
        extrn get_prot_psp:near


data    SEGMENT byte public 'DATA'

load_dos_exe_hooks      DB ?
load_dos_exe_arr        DW 2*16 DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'

.386p
        
        assume cs:code

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   HookLoadDosExe
;
;               DESCRIPTION:    Register callback for DOS exe files
;
;               PARAMETERS:             ES:DI           Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_load_dos_exe_name  DB 'Hook Load Dos Exe',0

hook_load_dos_exe       PROC far
        push ds
        push ax
        push bx
        mov ax,SEG data
        mov ds,ax
        mov al,ds:load_dos_exe_hooks
        mov bl,al
        xor bh,bh
        shl bx,2
        add bx,OFFSET load_dos_exe_arr
        mov [bx],di
        mov [bx+2],es
        inc al
        mov ds:load_dos_exe_hooks,al
        pop bx
        pop ax
        pop ds
        ret
hook_load_dos_exe       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SETUP_COMMAND_LINE
;
;               DESCRIPTION:    Setup conmmand line
;
;               PARAMETERS:             DS:ESI          Program name
;                                               ES:EDI          Command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_command_line      PROC near
        push ds
        push es
        push fs
        push ax
        push bx
        push ecx
        push esi
        push edi
;
        mov ax,es
        mov ds,ax
        mov esi,edi
;
        call get_prot_psp
        mov es,bx
        mov edi,OFFSET psp_fcb1
        push esi

setup_bypass_line1_loop:
        lods byte ptr [esi]
        or al,al
        jz setup_line_ok
;
        cmp al,' '
        je setup_bypass_line1_loop
;
        cmp al,9
        je setup_bypass_line1_loop
;
        dec esi
        mov cx,11

setup_put_line1:
        lods byte ptr [esi]
        cmp al,' '
        je setup_line2
;
        or al,al
        jz setup_line_ok
;
        cmp al,9
        je setup_line2
;
        stos byte ptr es:[edi]
        loop setup_put_line1

setup_line2:
        mov edi,OFFSET psp_fcb2
        dec esi

setup_bypass_line2_loop:
        lods byte ptr [esi]
        or al,al
        jz setup_line_ok
;
        cmp al,' '
        je setup_bypass_line2_loop
;
        cmp al,9
        je setup_bypass_line2_loop
;
        dec esi
        mov cx,11

setup_put_line2:
        lods byte ptr [esi]
        or al,al
        jz setup_line_ok
;
        cmp al,' '
        je setup_line_ok
;
        cmp al,9
        je setup_line_ok
;
        stos byte ptr es:[edi]
        loop setup_put_line2

setup_line_ok:
        pop esi
        mov di,81h
        xor cx,cx

setup_cmd_line_loop:
        mov al,[esi]
        or al,al
        jz setup_cmd_line_terminate
;
        inc esi
        inc cx
        stosb
        jmp setup_cmd_line_loop

setup_cmd_line_terminate:
        mov al,0Dh
        stosb
        mov di,80h
        mov al,cl
        stosb
;
        pop edi
        pop esi
        pop ecx
        pop bx
        pop ax
        pop fs
        pop es
        pop ds
        ret
setup_command_line      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   LOAD_COM
;
;               DESCRIPTION:    Load .COM file
;
;               PARAMETERS:             BX              File handle
;                                               DS:ESI  File name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

com_loader_name DB 'DOS COM',0

load_com        PROC near
        push ds
        push es
        push esi
        push edi
;
        push ecx
        push edi
;
        push bx
        xor bx,bx
        call create_enviroment
        mov ax,bx
        pop bx
        push ax
;
        mov al,16
        SetBitness
;
        GetFileSize
        mov ecx,eax
        add ecx,100h
        AvailableDosLinear
        cmp edx,ecx
        jc load_com_fail
;
        mov eax,edx
        AllocateDosLinear
        jc load_com_fail
;
        mov edi,edx
        xor eax,eax
        SetFilePos
        mov ax,flat_sel
        mov es,ax
        add edi,100h
        sub ecx,100h
        UserGateForce32 read_file_nr
        jc load_com_fail
;
        mov eax,edx
        shr edx,4
        sub eax,10h
        mov es:[eax+1],dx
        CloseFile
        pop bx
        pop edi
        pop ecx
;
        mov ax,bx
        mov bx,dx
        call create_psp
;
        mov [bp].load_ss,bx
        mov [bp].load_cs,bx
        mov [bp].load_ds,bx
        mov [bp].load_es,bx
        mov word ptr [bp].load_eip,100h
        mov word ptr [bp].load_esp,0FFFEh
        mov word ptr [bp+2].load_eflags,2
        mov ax,7202h
        SetFlags
        mov [bp].load_eflags,ax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
        mov word ptr ds:app_loader_name,OFFSET com_loader_name
        mov word ptr ds:app_loader_name+2,cs
        clc
        jmp load_com_done

load_com_fail:
        stc
        pop ax
        pop edi
        pop ecx

load_com_done:
        pop edi
        pop esi
        pop es
        pop ds
        ret
load_com        ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   LOAD_EXE
;
;               DESCRIPTION:    Load .EXE file
;
;               PARAMETERS:             BX              File handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

exe_loader_name DB 'DOS EXE',0

load_exe        PROC near
        push ds
        push es
        push esi
        push edi
;
        push bx
        xor bx,bx
        call create_enviroment
        mov ax,bx
        pop bx
        push ax
;
        mov al,16
        SetBitness
;
        mov eax,SIZE exeh_seg
        AllocateSmallGlobalMem
        mov ecx,eax
        xor eax,eax
        SetFilePos
        xor di,di
        ReadFile
;
        mov ax,es
        mov ds,ax
        movzx eax,ds:exeh_size_msb
        dec ax
        shl eax,9
        movzx ecx,ds:exeh_size_lsb
        add eax,ecx
        add eax,100h
;       movzx ecx,ds:exeh_size_header
;       shl ecx,4
;       sub eax,ecx
        movzx ecx,ds:exeh_minalloc
        shl ecx,4
        add ecx,eax
        push eax
        AvailableDosLinear
        cmp edx,ecx
        jc load_exe_fail
;
        pop eax
        movzx ecx,ds:exeh_maxalloc
        shl ecx,4
        add eax,ecx
        cmp edx,eax
        jnc load_exe_whole_size

        mov eax,edx
load_exe_whole_size:
        AllocateDosLinear
        push edx
        mov edi,edx
        add edi,100h
        movzx eax,ds:exeh_size_header
        shl eax,4
;       mov edx,eax
        SetFilePos
        movzx ecx,ds:exeh_size_msb
        dec cx
        shl ecx,9
        movzx eax,ds:exeh_size_lsb
        add ecx,eax
;       sub ecx,edx
        mov ax,flat_sel
        mov es,ax
        UserGateForce32 read_file_nr
        jc load_exe_fail
;
        movzx eax,ds:exeh_reloc_ant
        shl eax,2
        mov ecx,eax
        xor edi,edi
        or eax,eax
        jz load_exe_noreloc1
        AllocateLocalMem
        movzx eax,ds:exeh_reloc_offs
        SetFilePos
        UserGateForce32 read_file_nr
load_exe_noreloc1:
        CloseFile
        pop edx
;
        push ds
        mov ax,flat_sel
        mov ds,ax
        mov eax,edx
        mov esi,edx
        shr edx,4
        sub eax,10h
        mov [eax+1],dx
        add esi,100h
        mov edx,esi
        shr edx,4
        shr ecx,2
        or ecx,ecx
        jz load_exe_noreloc2
load_exe_reloc_loop:
        movzx ebx,word ptr es:[edi]
        movzx eax,word ptr es:[edi+2]
        shl eax,4
        add eax,ebx
        add [esi+eax],dx
        add edi,4
        loop load_exe_reloc_loop
        FreeMem
load_exe_noreloc2:
        pop ds
        pop ax
        mov bx,dx
        sub bx,10h
        call create_psp
;
        mov ax,ds:exeh_ss
        add ax,dx
        mov [bp].load_ss,ax
        mov ax,ds:exeh_sp
        mov [bp].load_esp,ax
        mov ax,ds:exeh_cs
        add ax,dx
        mov [bp].load_cs,ax
        mov ax,ds:exeh_ip
        mov [bp].load_eip,ax
        mov [bp].load_ds,bx
        mov [bp].load_es,bx
        mov word ptr [bp+2].load_eflags,2
        mov ax,7202h
        SetFlags
        mov [bp].load_eflags,ax
;
        mov ax,ds
        mov es,ax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
        mov word ptr ds:app_loader_name,OFFSET exe_loader_name
        mov word ptr ds:app_loader_name+2,cs
        FreeMem
        clc
        jmp load_exe_done

load_exe_fail:
        add sp,6
        stc

load_exe_done:
        pop edi
        pop esi
        pop es
        pop ds
        ret
load_exe        ENDP
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   load_dos_exe
;
;               DESCRIPTION:    Load DOS executable file
;
;               PARAMETERS:     BX              file handle
;                                               DS:ESI  File name
;                                               ES:EDI  Command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_dos_exe    PROC far
        mov ecx,esi

load_dos_check_com:
        lods byte ptr [esi]
        or al,al
        jz load_dos_exe_fail
;
        cmp al,'.'
        jne load_dos_check_com
;
        lods byte ptr [esi]
        cmp al,'c'
        je load_dos_check_com2
;
        cmp al,'C'
        jne load_dos_try_exe

load_dos_check_com2:
        lods byte ptr [esi]
        cmp al,'o'
        je load_dos_check_com3
;
        cmp al,'O'
        jne load_dos_exe_fail

load_dos_check_com3:
        lods byte ptr [esi]
        cmp al,'m'
        je load_dos_check_com4
        cmp al,'M'
        jne load_dos_exe_fail

load_dos_check_com4:
        lods byte ptr [esi]
        or al,al
        jnz load_dos_exe_fail
;
        mov esi,ecx
        call load_com
        jmp load_dos_exe_ok

load_dos_try_exe:
        mov esi,ecx
        push es
        push di
        mov eax,40h
        AllocateSmallGlobalMem
;
        mov cx,ax
        xor eax,eax
        SetFilePos
        xor di,di
        ReadFile
        jc load_dos_exe_free_pop_fail
;
        cmp ax,40h
        jne load_dos_exe_free_pop_fail
;
        mov ax,es:exeh_signature
        FreeMem
        pop di
        pop es
;
        cmp ax,5A4Dh
        jne load_dos_exe_fail
;
        mov ax,SEG data
        mov fs,ax
        mov cl,fs:load_dos_exe_hooks
        or cl,cl
        je load_dos_exe_file_default
;
        mov ax,OFFSET load_dos_exe_arr

load_dos_exe_file_loop:
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
        push OFFSET load_dos_exe_ret
        push eax
        retf

load_dos_exe_ret:
        pop cx
        pop ax
        pop fs
        jnc load_dos_exe_create_env
;
        add ax,4
        dec cl
        jnz load_dos_exe_file_loop

load_dos_exe_file_default:
        call load_exe
        jc load_dos_exe_fail
        jmp load_dos_exe_ok

load_dos_exe_create_env:
        xor bx,bx
        call create_enviroment
;
        mov eax,100h
        AllocateDosLinear
        shr edx,4
        mov ax,bx
        mov bx,dx
        call create_psp
        mov ax,[bp].load_es
        or ax,ax
        jnz load_dos_exe_ok
;
        test byte ptr [bp+2].load_eflags,2
        jnz load_dos_exe_es_psp
;
        EnterDos16
        call get_prot_psp

load_dos_exe_es_psp:
        mov [bp].load_es,bx

load_dos_exe_ok:
        call setup_command_line
        clc
        jmp load_dos_exe_done

load_dos_exe_unload:
        CloseApp
        stc
        jmp load_dos_exe_done

load_dos_exe_free_pop_fail:
        FreeMem
        pop di
        pop es

load_dos_exe_fail:
        stc

load_dos_exe_done:
        ret
load_dos_exe    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   load_dos_ext_exe
;
;               DESCRIPTION:    Load extender .EXE file
;
;               PARAMETERS:             BX              File handle
;                                               DS:ESI  File name
;                                               ES:EDI  Command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_dos_ext_exe_name   DB 'Load DOS Extender Exe', 0

load_dos_ext_exe        PROC far
        push ax
;
        push bx
        call get_prot_psp
        mov ax,bx
        pop bx
        push ax
;
        call clear_psp
;
        push ds
        push es
        push esi
        push edi
;
        push bx
        xor bx,bx
        call create_enviroment
        mov ax,bx
        pop bx
        push ax
;
        mov eax,SIZE exeh_seg
        AllocateSmallGlobalMem
        mov ecx,eax
        xor eax,eax
        SetFilePos
        xor di,di
        ReadFile
;
        mov ax,es
        mov ds,ax
        movzx eax,ds:exeh_size_msb
        dec ax
        shl eax,9
        movzx ecx,ds:exeh_size_lsb
        add eax,ecx
        add eax,100h
;       movzx ecx,ds:exeh_size_header
;       shl ecx,4
;       sub eax,ecx
        movzx ecx,ds:exeh_minalloc
        shl ecx,4
        add ecx,eax
        push eax
        AvailableDosLinear
        cmp edx,ecx
        jc load_ext_exe_fail
;
        pop eax
        movzx ecx,ds:exeh_maxalloc
        shl ecx,4
        add eax,ecx
        cmp edx,eax
        jnc load_ext_exe_whole_size

        mov eax,edx
load_ext_exe_whole_size:
        AllocateDosLinear
        push edx
        mov edi,edx
        add edi,100h
        movzx eax,ds:exeh_size_header
        shl eax,4
;       mov edx,eax
        SetFilePos
        movzx ecx,ds:exeh_size_msb
        dec cx
        shl ecx,9
        movzx eax,ds:exeh_size_lsb
        add ecx,eax
;       sub ecx,edx
        mov ax,flat_sel
        mov es,ax
        UserGateForce32 read_file_nr
        jc load_ext_exe_fail
;
        movzx eax,ds:exeh_reloc_ant
        shl eax,2
        mov ecx,eax
        xor edi,edi
        or eax,eax
        jz load_ext_exe_noreloc1
;
        AllocateLocalMem
        movzx eax,ds:exeh_reloc_offs
        SetFilePos
        UserGateForce32 read_file_nr

load_ext_exe_noreloc1:
        CloseFile
        pop edx
;
        push ds
        mov ax,flat_sel
        mov ds,ax
        mov eax,edx
        mov esi,edx
        shr edx,4
        sub eax,10h
        mov [eax+1],dx
        add esi,100h
        mov edx,esi
        shr edx,4
        shr ecx,2
        or ecx,ecx
        jz load_ext_exe_noreloc2

load_ext_exe_reloc_loop:
        movzx ebx,word ptr es:[edi]
        movzx eax,word ptr es:[edi+2]
        shl eax,4
        add eax,ebx
        add [esi+eax],dx
        add edi,4
        loop load_ext_exe_reloc_loop
;
        FreeMem

load_ext_exe_noreloc2:
        pop ds
        pop ax
        mov bx,dx
        sub bx,10h
        call create_psp
;
        mov ax,ds:exeh_ss
        add ax,dx
        mov [bp].load_ss,ax
        mov ax,ds:exeh_sp
        mov [bp].load_esp,ax
        mov ax,ds:exeh_cs
        add ax,dx
        mov [bp].load_cs,ax
        mov ax,ds:exeh_ip
        mov [bp].load_eip,ax
        mov [bp].load_ds,bx
        mov [bp].load_es,bx
        mov word ptr [bp+2].load_eflags,2
        mov ax,7202h
        SetFlags
        mov [bp].load_eflags,ax
;
        mov ax,ds
        mov es,ax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
        mov word ptr ds:app_loader_name,OFFSET exe_loader_name
        mov word ptr ds:app_loader_name+2,cs
        FreeMem
        jmp load_ext_exe_ok

load_ext_exe_fail:
        add sp,6
        pop edi
        pop esi
        pop es
        pop ds
;
        pop ax
        push bx
        mov bx,ax
        call set_prot_psp
        pop bx
        stc
        jmp load_ext_exe_done

load_ext_exe_ok:
        pop edi
        pop esi
        pop es
        pop ds
;
        pop ax
        call setup_command_line
        clc

load_ext_exe_done:
        pop ax
        ret
load_dos_ext_exe        ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   init
;
;               DESCRIPTION:    init dos exec
;
;       RETURN VALUE:   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public init_dos_exec

init_dos_exec   PROC near
        pusha
        push ds
;
        mov ax,SEG data
        mov ds,ax
        mov ds:load_dos_exe_hooks,0
;
        mov ax,cs
        mov ds,ax
        mov es,ax
;
        mov si,OFFSET hook_load_dos_exe
        mov di,OFFSET hook_load_dos_exe_name
        xor cl,cl
        mov ax,hook_load_dos_exe_nr
        RegisterOsGate
;
        mov si,OFFSET load_dos_ext_exe
        mov di,OFFSET load_dos_ext_exe_name
        xor cl,cl
        mov ax,load_dos_exe_nr
        RegisterOsGate
;
        mov di,OFFSET load_dos_exe
        HookLoadExe
;
        pop ds
        popa
        ret
init_dos_exec   ENDP

code    ENDS

        END
