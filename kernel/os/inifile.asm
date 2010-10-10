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
; INI.ASM
; Ini file handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                
                NAME inifile

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\handle.inc
INCLUDE system.def

ini_handle_seg  STRUC

ih_hheader      handle_header <>

ih_sel                  DW ?
ih_file_handle  DW ?
ih_base                 DD ?
ih_size             DD ?
ih_file_size    DD ?
ih_mmap_handle  DW ?
ih_name_sel     DW ?
ih_name_size    DD ?
ih_sect_start   DD ?
ih_sect_base    DD ?
ih_sect_size    DD ?
ih_entry_start  DD ?
ih_entry_base   DD ?
ih_entry_size   DD ?

ini_handle_seg  ENDS

ini_file_seg STRUC

if_prev                 DW ?
if_next                 DW ?
if_section      section_typ <>
if_list                 DD ?
if_usage                DW ?
if_file_sel     DW ?
if_access       DB ?
if_drive        DB ?

ini_file_seg ENDS

data    SEGMENT byte public 'DATA'

is_section      section_typ <>

is_sys_sel      DW ?

data    ENDS

        .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenSystemIni
;
;       DESCRIPTION:    Opens system ini file
;
;               RETURNS:                BX                      ini file handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DefaultSysIniName       DB 'z:\system.ini', 0
SysIniVar       DB 'SYSINI', 0

OpenSystemIni   Proc near
        push ds
        push es
        push eax
        push si
        push di
;
        OpenSysEnv
;
        mov eax,1000h
        AllocateGlobalMem
        xor di,di
;
        mov ax,cs
        mov ds,ax
        mov si,OFFSET SysIniVar
;
        FindEnvVar
        pushf
        CloseEnv
        popf
        jc open_sys_ini_test_file
;
        mov cl,0
        OpenFile

open_sys_ini_test_file:
        pushf
        FreeMem
        popf
        jnc open_sys_ini_done
;       
        mov ax,cs
        mov es,ax
        mov di,OFFSET DefaultSysIniName
        OpenFile
        jnc open_sys_ini_done
;
        OpenSysEnv
;
        mov eax,1000h
        AllocateGlobalMem
        xor di,di
;
        mov ax,cs
        mov ds,ax
        mov si,OFFSET SysIniVar
;
        FindEnvVar
        pushf
        CloseEnv
        popf
        jc open_sys_ini_free
;
        xor cx,cx
        CreateFile

open_sys_ini_free:
        pushf
        FreeMem
        popf

open_sys_ini_done:
        pop di
        pop si
        pop eax
        pop es
        pop ds
        ret
OpenSystemIni   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenoPrivIni
;
;       DESCRIPTION:    Opens private ini file
;
;       PARAMETERS:     ES:EDI      file name
;
;               RETURNS:                BX                      ini file handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPrivIni     Proc near
    push cx
;
        mov cl,0
        UserGateForce32 open_file_nr
        jnc open_priv_ini_done
;
        xor cx,cx
        UserGateForce32 create_file_nr

open_priv_ini_done:
    pop cx
        ret
OpenPrivIni     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LockIni
;
;       DESCRIPTION:    Lock ini file & goto current section
;
;               PARAMETERS:             DS:BX           handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockIni Proc near
        push ds
        push es
        pushad
;
        mov si,bx
;       
    push ds
    mov ds,[si].ih_sel
    EnterSection ds:if_section
    pop ds
;
        mov bx,[si].ih_file_handle
        GetFileSize
        mov ds:[si].ih_file_size,eax
        and ax,0F000h
        add eax,1000h
        AllocateLocalLinear
        push ds
        push ax
        mov ax,system_data_sel
        mov ds,ax
        sub edx,ds:flat_base
        pop ax
        pop ds
        mov ds:[si].ih_base,edx
        mov ds:[si].ih_size,eax 
;
        CreateFileMapping
        mov ds:[si].ih_mmap_handle,bx
;
        mov ax,flat_data_sel
        mov es,ax
        xor eax,eax
        mov edi,ds:[si].ih_base
        mov ecx,ds:[si].ih_size
        UserGateForce32 map_view_nr
;    
        popad
        pop es
        pop ds
        ret
LockIni Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlockIni
;
;       DESCRIPTION:    Unlock ini
;
;               PARAMETERS:             DS:BX           handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockIni       Proc near
        push ds
        push es
        pushad
;
        mov si,bx
;
        mov bx,ds:[si].ih_mmap_handle
        UnmapView
        CloseMapping
        mov ds:[si].ih_mmap_handle,0
;
        mov edx,ds:[si].ih_base
        or edx,edx
        jz uiNoMem
;
        push ds
        mov ax,system_data_sel
        mov ds,ax
        add edx,ds:flat_base
        pop ds
        mov ecx,ds:[si].ih_size
        FreeLinear

uiNoMem:
    mov ds,[si].ih_sel
    LeaveSection ds:if_section
;    
        popad
        pop es
        pop ds
        ret
UnlockIni       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindIniSection
;
;       DESCRIPTION:    Find current section
;
;               PARAMETERS:             DS:BX       Handle data
;
;               RETURNS:            EDI         Linear address to section
;                       ECX         Size of section
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindIniSection Proc near
    push ds
    push es
    push fs
    push ax
    push esi
;
        mov ax,flat_data_sel
        mov es,ax
        mov edi,ds:[bx].ih_base
        mov ecx,ds:[bx].ih_file_size
        mov fs,ds:[bx].ih_name_sel
;       
    or ecx,ecx
    stc
    jz FindIniSectionDone
;
    mov al,es:[edi]
    cmp al,'['
    jne FindIniSectionScan
;
    mov ds:[bx].ih_sect_start,edi
    inc edi
    dec ecx
    jmp FindIniSectionCheck
        
FindIniSectionScan:
        mov al,'['
        repne scas byte ptr es:[edi]
        cmp byte ptr es:[edi-1],'['
        stc
        jne FindIniSectionDone
;       
    mov eax,edi
    dec eax
    mov ds:[bx].ih_sect_start,eax
;
    mov al,es:[edi-2]
    cmp al,0Dh
    je FindIniSectionCheck
    cmp al,0Ah
    jne FindIniSectionScan

FindIniSectionCheck:
        xor esi,esi
        repe cmps byte ptr fs:[esi],[edi]
        dec esi
        dec edi
        inc ecx
        lods byte ptr fs:[esi]
        or al,al
        jne FindIniSectionScan
;
        mov al,es:[edi]
        cmp al,']'
        jne FindIniSectionScan
;
        inc edi
        dec ecx
;
    push edi

FindIniSectionNextSize:
        mov al,'['
        repne scas byte ptr es:[edi]
    mov al,es:[edi-1]
    cmp al,'['
    jne FindIniSectionSize
;
    dec edi
    mov al,es:[edi-1]
    cmp al,0Dh
    je FindIniSectionSize
;
    cmp al,0Ah
    je FindIniSectionSize
;
    inc edi
    jmp FindIniSectionNextSize

FindIniSectionSize:
        mov ecx,edi
        pop edi
        sub ecx,edi
    clc

FindIniSectionDone:
    pop esi
    pop ax
    pop fs
    pop es
    pop ds
    ret
FindIniSection Endp     

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindIniKey
;
;       DESCRIPTION:    Find key in section
;
;               PARAMETERS:             DS:BX       Handle data
;                       FS:ESI      Key name
;                       EDI         Start of section
;                       ECX         Size of section
;
;       RETURNS:        EDI         Start of value
;                       ECX         Remaining size of section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindIniKey      Proc near
    push es
    push ax
;
    mov ax,flat_data_sel
    mov es,ax
        
FindIniKeyControl:
        mov al,es:[edi]
        cmp al,0Dh
        je FindIniKeyControlPass
        cmp al,0Ah
        je FindIniKeyControlPass
        cmp al,' '
        je FindIniKeyControlPass
        cmp al,9
        jne FindIniKeyScan
        
FindIniKeyControlPass:
        inc edi
        sub ecx,1
        jnz FindIniKeyControl
        stc
        jmp FindIniKeyDone
        
FindIniKeyScan:
    mov ds:[bx].ih_entry_start,edi
        push esi
        repe cmps byte ptr fs:[esi],[edi]
        dec esi
        dec edi
        inc ecx
        lods byte ptr fs:[esi]
        pop esi
        or al,al
        jne FindIniKeyWrongName
        
FindIniKeySpacePass:
        mov al,es:[edi]
        cmp al,'='
        je FindIniKeyCorrectName
        cmp al,' '
        je FindIniKeySpaceNext
        cmp al,9
        jne FindIniKeyWrongName

FindIniKeySpaceNext:    
        inc edi
        sub ecx,1
        jc FindIniKeyDone
        jmp FindIniKeySpacePass
        
FindIniKeyWrongName:
        mov al,es:[edi]
        cmp al,0Dh
        je FindIniKeyControl
        inc edi 
        sub ecx,1
        jc FindIniKeyDone
        jmp FindIniKeyWrongName
        
FindIniKeyCorrectName:
        inc edi
        sub ecx,1
        jc FindIniKeyDone
        jz FindIniKeyOk
;
    mov al,es:[edi]
    cmp al,' '
    je FindIniKeyCorrectName
;
    cmp al,9
    je FindIniKeyCorrectName    
    
FindIniKeyOk:
        clc
        
FindIniKeyDone:
    pop ax
    pop es
        ret
FindIniKey      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindKeySize
;
;       DESCRIPTION:    Find a size of key
;
;               PARAMETERS:             FS:ESI      Key name
;                       EDI         Start of data
;                       ECX         Remaining size of section
;
;       RETURNS:        ECX         Size of key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindKeySize     Proc near
    push es
    push ax
    push esi
    push edi
;
    push edi
    mov ax,flat_data_sel
    mov es,ax
        
FindKeySizeLoop:
        mov al,es:[edi]
        cmp al,0Dh
        je FindKeyEndFound
        cmp al,0Ah
        je FindKeyEndFound
;       
        inc edi
        sub ecx,1
        jnz FindKeySizeLoop
        
FindKeyEndFound:
    mov ecx,edi
    pop eax
    sub ecx,eax

FindKeyBackLoop:
    or ecx,ecx
    jz FindKeySizeDone
;
    dec ecx
    dec edi
    mov al,es:[edi]
    cmp al,' '
    je FindKeyBackLoop
;
    cmp al,9
    je FindKeyBackLoop
;
    inc ecx

FindKeySizeDone:
    pop edi
    pop esi
    pop ax
    pop es
        ret
FindKeySize     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateIniSection
;
;       DESCRIPTION:    Create current ini section
;
;               PARAMETERS:             DS:BX       Handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIniSection Proc near
    push ds
    push es
    pushad
;
    sub sp,4
    mov bp,sp
;    
    mov si,bx
    mov bx,ds:[si].ih_file_handle
    GetFileSize
    SetFilePos
;
    mov ax,ss
    mov es,ax
    mov di,bp   
    mov byte ptr es:[di],'['
    mov cx,1
    WriteFile
;
    mov es,ds:[si].ih_name_sel
        mov ecx,ds:[si].ih_name_size
        dec ecx
        xor edi,edi
        UserGateForce32 write_file_nr
;
    mov ax,ss
    mov es,ax
    mov di,bp
    mov al,']'
    stosb
    mov al,0Dh
    stosb
    mov al,0Ah
    stosb
;
    mov di,bp
    mov cx,3
    WriteFile    
;
    add sp,4
;
    popad
    pop es
    pop ds
    ret
CreateIniSection Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetIniFreeSize
;
;       DESCRIPTION:    Get free size of ini file
;
;               PARAMETERS:             DS:BX       Handle data
;
;       RETURNS:        ECX         Free size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIniFreeSize  Proc near
    push es
    push ax
    push edx
    push edi
;
    mov ax,flat_data_sel
    mov es,ax

        mov edi,ds:[bx].ih_base
        mov edx,ds:[bx].ih_file_size
;
    add edi,edx
;       
    xor ecx,ecx

gifLoop:
    or edx,edx
    jz gifDone
;
    dec edi
    dec edx
    inc ecx
    mov al,es:[edi]
    cmp al,' '
    je gifLoop    
;
    dec ecx

gifDone:  
    pop edi
    pop edx
    pop ax
    pop es
        ret
GetIniFreeSize  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GrowIni
;
;       DESCRIPTION:    Grow ini file size
;
;               PARAMETERS:             DS:BX       Handle data
;                       ECX         Byte to add
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowIni Proc near
    push es
    pushad
;
    or ecx,ecx
    jz giDone
;    
    push bx
    call UnlockIni
;    
    mov si,bx
    mov bx,ds:[si].ih_file_handle
    GetFileSize
    SetFilePos
;
    mov eax,ecx
    AllocateSmallGlobalMem
;
    push ecx
    xor edi,edi
    mov al,' '
    rep stos byte ptr es:[edi]
    pop ecx
;
    xor edi,edi
    UserGateForce32 write_file_nr
    FreeMem
;    
    pop bx
    call LockIni

giDone:
    popad
    pop es
    ret
GrowIni Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateIniSel
;
;       DESCRIPTION:    Create ini selector
;
;               PARAMETERS:             BX                      original file handle
;
;               RETURNS:                DS                      ini selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIniSel    proc near
        push es
        push eax
        push cx
;
        mov eax,SIZE ini_file_seg
        AllocateSmallGlobalMem
        mov ax,es
        mov ds,ax
;
        InitSection ds:if_section
        GetFileInfo
        mov ds:if_access,cl
        mov ds:if_drive,ch
        mov ds:if_file_sel,ax
        mov ds:if_usage,0
        mov ds:if_list,0
;
        pop cx
        pop eax
        pop es
        ret
CreateIniSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeIniSel
;
;       DESCRIPTION:    Free ini selector (if usage permits)
;
;               PARAMETERS:             DS                      ini selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeIniSel      proc near
        push es
        push ax
        push cx
;
        sub ds:if_usage,1
        jnz fisDone
;
        mov cx,ds
        mov ax,SEG data
        mov ds,ax
        cmp cx,ds:is_sys_sel
        jne fisPriv
;
        EnterSection ds:is_section
        mov es,cx
        mov ds:is_sys_sel,0
        FreeMem
        LeaveSection ds:is_section
        jmp fisDone

fisPriv:
        mov es,cx
        FreeMem

fisDone:
        pop cx
        pop ax
        pop es
        ret
FreeIniSel      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateIniHandle
;
;       DESCRIPTION:    Create ini handle
;
;               PARAMETERS:             DS                      ini selector
;                                               BX                      "original" file handle or 0
;
;               RETURNS:                BX                      ini handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIniHandle proc near
        push ds
        push ax
        push cx
;
        inc ds:if_usage
        or bx,bx
        jnz cihNew
;
        mov cl,ds:if_access
        mov ch,ds:if_drive
        mov ax,ds:if_file_sel
        DuplFileInfo

cihNew:
        push ds
        push bx
        mov cx,SIZE ini_handle_seg
        AllocateHandle
        pop ax
        mov [bx].ih_file_handle,ax
        mov [bx].ih_name_sel,0
        pop ax
        mov [bx].ih_sel,ax
        mov [bx].hh_sign,INI_HANDLE
        mov bx,[bx].hh_handle
;
        pop cx
        pop ax
        pop ds
        ret
CreateIniHandle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenSysIni
;
;       DESCRIPTION:    Open system ini file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_sys_ini_name       DB 'Open Sys Ini', 0

open_sys_ini    Proc far
        push ds
        push es
        push ax
;
        xor bx,bx
        mov ax,SEG data
        mov ds,ax
        EnterSection ds:is_section
;
        mov ax,ds:is_sys_sel
        or ax,ax
        jnz osiCreateHandle
;
        call OpenSystemIni
        jc osiDone
;
        call CreateIniSel
;
        mov ax,SEG data
        mov es,ax
        mov es:is_sys_sel,ds

osiCreateHandle:
        mov ax,SEG data
        mov ds,ax
        LeaveSection ds:is_section
;
        mov ds,ds:is_sys_sel
        call CreateIniHandle
        clc

osiDone:
        pop ax
        pop es
        pop ds
        retf32
open_sys_ini    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenIni
;
;       DESCRIPTION:    Open ini file
;
;       PARAMETERS:     ES:(E)DI        File name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_ini_name   DB 'Open Ini', 0

open_ini        Proc near
        push ds
        push ax
;
        call OpenPrivIni
        jc opiDone
;
        call CreateIniSel
        call CreateIniHandle
        clc

opiDone:
        pop ax
        pop ds
        ret
open_ini        Endp

open_ini16 Proc far
    push edi
    movzx edi,di
    call open_ini
    pop edi
    ret
open_ini16  Endp

open_ini32:
    call open_ini
    retf32
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CloseIni
;
;               DESCRIPTION:    Close ini
;
;               PARAMETERS:             BX                      INI HANDLE
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_ini_name  DB 'Close Ini', 0

close_ini       Proc far
        push ds
        push es
        push bx
        push si
;
        mov ax,INI_HANDLE
        DerefHandle
        jc ciDone
;
    mov si,bx
    mov ax,ds:[bx].ih_name_sel
    or ax,ax
    jz ciCloseFile
;
    mov es,ax
    FreeMem

ciCloseFile:
        push ds:[bx].ih_file_handle
        mov ds,ds:[bx].ih_sel
        call FreeIniSel
        pop bx
        CloseFile
;
    mov bx,si
    FreeHandle

ciDone:
    pop si
        pop bx
        pop es
        pop ds
        retf32
close_ini       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GotoIniSection
;
;       DESCRIPTION:    Goto a ini section
;
;       PARAMETERS:     BX          Ini handle
;                       ES:(E)DI    Section name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

goto_ini_section_name   DB 'Goto Ini Section', 0

goto_ini_section        Proc near
    push ds
        push es
    push eax
    push bx
    push ecx
    push edx
    push esi
    push edi
;
        mov ax,INI_HANDLE
        DerefHandle
        jc gisDone
;
    mov ax,ds:[bx].ih_name_sel
    or ax,ax
    jz gisSectFree
;
    push es
    mov es,ax
    FreeMem
    pop es

gisSectFree:
    push edi
    xor ecx,ecx

gisSectSizeLoop:
    mov al,es:[edi]
    or al,al
    jz gisSectSizeOk
;
    inc edi
    inc ecx
    jmp gisSectSizeLoop

gisSectSizeOk:
    pop edi    
    inc ecx
    mov eax,ecx
    push es
    AllocateSmallMem
    mov ds:[bx].ih_name_sel,es
    mov ds:[bx].ih_name_size,ecx
    pop ds
    mov esi,edi
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]
    clc

gisDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop bx
    pop eax
        pop es
    pop ds
    ret
goto_ini_section    Endp

goto_ini_section16  Proc far
    push edi
    movzx edi,di
    call goto_ini_section
    pop edi
    ret
goto_ini_section16  Endp

goto_ini_section32  Proc far
    call goto_ini_section
    retf32
goto_ini_section32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteSection
;
;       DESCRIPTION:    Delete entire section
;
;       PARAMETERS:     DS:BX       Ini handle data
;                       EDI         Start of section
;                       ECX         Size of section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteSection   Proc near
    push es
    push ax
    push ecx
    push esi
    push edi
;       
    or ecx,ecx
    jz dsDone
;
    mov ax,flat_data_sel
    mov es,ax
;
    push ecx
    mov esi,edi
    add esi,ecx
    mov ecx,ds:[bx].ih_file_size
    sub ecx,esi
    add ecx,ds:[bx].ih_base
    rep movs byte ptr es:[edi],es:[esi]
    pop ecx
    mov al,' '
    rep stos byte ptr es:[edi]

dsDone:
    pop edi
    pop esi
    pop ecx
    pop ax
    pop es
        ret
DeleteSection   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RemoveIniSection
;
;       DESCRIPTION:    Remove a ini section
;
;       PARAMETERS:     BX          Ini handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_ini_section_name DB 'Remove Ini Section', 0

remove_ini_section      Proc near
    push ds
    push eax
    push bx
    push esi
;
    push ecx
    push edi
;
        mov ax,INI_HANDLE
        DerefHandle
        jc rmiFail
;
    mov ax,ds:[bx].ih_name_sel
    or ax,ax
    jz rmiFail
;
    call LockIni
    call FindIniSection    
    jc rmiDone
;
    mov eax,edi
    sub eax,ds:[bx].ih_sect_start
;
    sub edi,eax
    add ecx,eax
        call DeleteSection
        jmp rmiDone

rmiFail:
    pop edi
    pop ecx
    stc
    jmp rmiEnd

rmiDone:
    pop edi
    pop ecx
    pushf
    call UnlockIni
    popf

rmiEnd:    
    pop esi
    pop bx
    pop eax
    pop ds
    ret
remove_ini_section    Endp

remove_ini_section16  Proc far
    push edi
    movzx edi,di
    call remove_ini_section
    pop edi
    ret
remove_ini_section16  Endp

remove_ini_section32  Proc far
    call remove_ini_section
    retf32
remove_ini_section32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadIni
;
;       DESCRIPTION:    Read ini var
;
;       PARAMETERS:     BX          Ini handle
;                       DS:(E)SI    Var name
;                       ES:(E)DI    Buffer
;                       (E)CX       Max size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_ini_name   DB 'Read Ini', 0

read_ini        Proc near
    push ds
    push fs
    push eax
    push bx
    push esi
;
    push ecx
    push edi
    mov ax,ds
    mov fs,ax
;
        mov ax,INI_HANDLE
        DerefHandle
        jc riFail
;
    mov ax,ds:[bx].ih_name_sel
    or ax,ax
    stc
    jz riFail
;
    call LockIni
    call FindIniSection    
    jc riDone
;
    call FindIniKey
    jc riDone
;
    call FindKeySize
    mov esi,edi
    mov eax,ecx
    pop edi
    pop ecx
    push ecx
    push edi
;
    xchg eax,ecx
    cmp ecx,eax
    jb riCopy
;
    mov ecx,eax
    dec ecx

riCopy:
        mov ax,flat_data_sel
        mov fs,ax
    rep movs byte ptr es:[edi],fs:[esi]
    xor al,al
    stos byte ptr es:[edi]
    clc
    jmp riDone

riFail:
    pop edi
    pop ecx
    stc
    jmp riEnd

riDone:
    pop edi
    pop ecx
    pushf
    call UnlockIni
    popf

riEnd:    
    pop esi
    pop bx
    pop eax
    pop fs
    pop ds
    ret
read_ini    Endp

read_ini16  Proc far
    push ecx
    push esi
    push edi
    movzx ecx,cx
    movzx esi,si
    movzx edi,di
    call read_ini
    pop edi
    pop esi
    pop ecx
    ret
read_ini16  Endp

read_ini32  Proc far
    call read_ini
    retf32
read_ini32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetEntrySize
;
;       DESCRIPTION:    Get required size of entry
;
;       PARAMETERS:     DS:BX       Ini handle data
;                       FS:ESI      Var name
;                       ES:EBP      Buffer
;
;               RETURNS:                ECX                     Required size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetEntrySize    Proc near
        push ax
    push esi
    push ebp
;
        mov ecx,3

gesVarLoop:
    mov al,fs:[esi]
    or al,al
    je gesBufLoop
;
    inc esi
    inc ecx
    jmp gesVarLoop

gesBufLoop:
    mov al,es:[ebp]
    or al,al
    je gesSizeOk
;    
    inc ebp
    inc ecx
    jmp gesBufLoop

gesSizeOk:
    pop ebp
    pop esi
        pop ax
        ret
GetEntrySize    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetDataSize
;
;       DESCRIPTION:    Get required size of data
;
;       PARAMETERS:     DS:BX       Ini handle data
;                       ES:EBP      Buffer
;
;               RETURNS:                ECX                     Required size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDataSize     Proc near
        push ax
    push ebp
;
        xor ecx,ecx

gdsBufLoop:
    mov al,es:[ebp]
    or al,al
    je gdsSizeOk
;    
    inc ebp
    inc ecx
    jmp gdsBufLoop

gdsSizeOk:
    pop ebp
        pop ax
        ret
GetDataSize     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteEntryData
;
;       DESCRIPTION:    Delete entry data part
;
;       PARAMETERS:     DS:BX       Ini handle data
;                       EDI         Start of value
;                       ECX         Remaining size of section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteEntryData Proc near
    push es
    push ax
    push ecx
    push esi
    push edi
;
    mov ax,flat_data_sel
    mov es,ax
    call FindKeySize
    or ecx,ecx
    jz dedDone
;
    push ecx
    mov esi,edi
    add esi,ecx
    mov ecx,ds:[bx].ih_file_size
    sub ecx,esi
    add ecx,ds:[bx].ih_base
    rep movs byte ptr es:[edi],es:[esi]
    pop ecx
    mov al,' '
    rep stos byte ptr es:[edi]

dedDone:
    pop edi
    pop esi
    pop ecx
    pop ax
    pop es
        ret
DeleteEntryData Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MoveForData
;
;       DESCRIPTION:    Move to make space for data
;
;       PARAMETERS:     DS:BX       Ini handle data
;                       FS:ESI      Var name
;                       ES:EBP      Buffer
;                       EDI         Insert point
;                       ECX         Space needed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveForData     Proc near
    push es
        push eax
        push ecx
        push esi
        push edi
;
    mov esi,ds:[bx].ih_base
    add esi,ds:[bx].ih_file_size
        cmp edi,esi
        je mfeDone
;
    dec esi
    mov ax,flat_data_sel
    mov es,ax
    mov eax,esi
    sub esi,ecx
    mov ecx,esi
    sub ecx,edi
    mov edi,eax
    inc ecx
    std
    rep movs byte ptr es:[edi],es:[esi]
    cld

mfdDone:
        pop edi
        pop esi
        pop ecx
        pop eax
        pop es
        ret
MoveForData     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CacheEntryAttrib
;
;       DESCRIPTION:    Cache entry attributes
;
;       PARAMETERS:     DS:BX       Ini handle data
;                       FS:ESI      Var name
;                       ES:EBP      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CacheEntryAttrib        Proc near
    push es
        push ax
        push ecx
        push edi
;
    call GetIniFreeSize
        mov edi,ds:[bx].ih_base
        add edi,ds:[bx].ih_file_size
        sub edi,ecx
        dec edi
        call GetEntrySize
    mov ax,flat_data_sel
    mov es,ax
        add ecx,2
        mov al,es:[edi]
        cmp al,0Ah
        jne ceaDone
;
        dec ecx
        dec edi
        mov al,es:[edi]
        cmp al,0Dh
        jne ceaDone
;
        dec ecx
        dec edi

ceaDone:
        inc edi
        mov ds:[bx].ih_entry_base,edi
        mov ds:[bx].ih_entry_size,ecx
;
        pop edi
        pop ecx
        pop ax
        pop es
        ret
CacheEntryAttrib        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MoveForEntry
;
;       DESCRIPTION:    Move to make space for entry
;
;       PARAMETERS:     DS:BX       Ini handle data
;                       FS:ESI      Var name
;                       ES:EBP      Buffer
;                       ECX         Space needed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveForEntry    Proc near
    push es
        push eax
        push ecx
        push esi
        push edi
;
        mov edi,ds:[bx].ih_sect_base
    add edi,ds:[bx].ih_sect_size
    mov esi,ds:[bx].ih_base
    add esi,ds:[bx].ih_file_size
        cmp edi,esi
        je mfeDone
;
    dec esi
    mov ax,flat_data_sel
    mov es,ax
    mov eax,esi
    sub esi,ecx
    mov ecx,esi
    sub ecx,edi
    mov edi,eax
    inc ecx
    std
    rep movs byte ptr es:[edi],es:[esi]
    cld

mfeDone:
        pop edi
        pop esi
        pop ecx
        pop eax
        pop es
        ret
MoveForEntry    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddEntry
;
;       DESCRIPTION:    Add entry
;
;       PARAMETERS:     DS:BX       Ini handle data
;                       FS:ESI      Var name
;                       ES:EBP      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddEntry        Proc near
        push ds
        pushad
;
        mov edx,ds:[bx].ih_entry_base
        mov ax,flat_data_sel
        mov ds,ax
;
        mov ax,0A0Dh
        mov ds:[edx],ax
        inc edx
        inc edx

aeVarLoop:
    mov al,fs:[esi]
    or al,al
    je aeBuf
;
        mov ds:[edx],al
    inc esi
        inc edx
    jmp aeVarLoop

aeBuf:
        mov al,'='
        mov ds:[edx],al
        inc edx

aeBufLoop:
    mov al,es:[ebp]
    or al,al
    je aeFooter
;    
        mov ds:[edx],al
    inc ebp
    inc edx
    jmp aeBufLoop

aeFooter:
        mov ax,0A0Dh
        mov ds:[edx],ax
;
        popad
        pop ds
        ret
AddEntry        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddData
;
;       DESCRIPTION:    Add data
;
;       PARAMETERS:     DS:BX       Ini handle data
;                       ES:EBP      Buffer
;                       EDI         Insert point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddData Proc near
        push ds
        pushad
;
        mov ax,flat_data_sel
        mov ds,ax

adBufLoop:
    mov al,es:[ebp]
    or al,al
    je adDone
;    
        mov ds:[edi],al
    inc ebp
    inc edi
    jmp adBufLoop

adDone:
        popad
        pop ds
        ret
AddData Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteIni
;
;       DESCRIPTION:    Write ini var
;
;       PARAMETERS:     BX          Ini handle
;                       DS:(E)SI    Var name
;                       ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_ini_name  DB 'Write Ini', 0

write_ini       Proc near
    push ds
    push fs
    pushad
;
    mov ebp,edi
    mov ax,ds
    mov fs,ax
;    
        mov ax,INI_HANDLE
        DerefHandle
        jc wiFail
;
    mov ax,ds:[bx].ih_name_sel
    or ax,ax
    jz wiFail
;
    call LockIni

wiFindLoop:    
    call FindIniSection    
    jnc wiFindVar
;
    call UnlockIni
    call CreateIniSection
    call LockIni
    call FindIniSection
    jc wiDone

wiFindVar:
        mov ds:[bx].ih_sect_base,edi
        mov ds:[bx].ih_sect_size,ecx
    call FindIniKey
    jc wiAdd

wiRepl:
    call DeleteEntryData
    call GetDataSize
    mov edx,ecx
    call GetIniFreeSize
    cmp ecx,edx
    jae wiReplDo
;
    sub ecx,edx
    neg ecx
    call GrowIni
    jmp wiFindLoop

wiReplDo:
    mov ecx,edx
    call MoveForData
    call AddData
    jmp wiDone

wiAdd:
        call CacheEntryAttrib
    call GetIniFreeSize
        cmp ecx,ds:[bx].ih_entry_size
        jae wiSizeOk
;
    sub ecx,ds:[bx].ih_entry_size
        neg ecx
    call GrowIni
    jmp wiFindLoop

wiSizeOk:
        call MoveForEntry
        call AddEntry
        jmp wiDone

wiFail:
    stc
    jmp wiEnd

wiDone:
    pushf
    call UnlockIni
    popf

wiEnd:
    popad
    pop fs
    pop ds
    ret
write_ini    Endp

write_ini16  Proc far
    push esi
    push edi
    movzx esi,si
    movzx edi,di
    call write_ini
    pop edi
    pop esi
    ret
write_ini16  Endp

write_ini32  Proc far
    call write_ini
    retf32
write_ini32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteIni
;
;       DESCRIPTION:    Delete ini var
;
;       PARAMETERS:     BX          Ini handle
;                       DS:(E)SI    Var name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_ini_name DB 'Delete Ini', 0

delete_ini      Proc near
    stc
    ret
delete_ini    Endp

delete_ini16  Proc far
    push esi
    movzx esi,si
    call delete_ini
    pop esi
    ret
delete_ini16  Endp

delete_ini32  Proc far
    call delete_ini
    retf32
delete_ini32  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Delete_handle
;
;               DESCRIPTION:    Delete handle (called from handle module)
;
;               PARAMETERS:             BX                      INI HANDLE
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
        push ds
        push bx
;
        mov ax,INI_HANDLE
        DerefHandle
        jc delete_handle_done
;
    mov ax,ds:[bx].ih_name_sel
    or ax,ax
    jz delete_handle_name_done
;
    push es
    mov es,ax
    FreeMem
    pop es

delete_handle_name_done:
    push es
    mov es,ax
    FreeMem
    pop es
        push ds
        mov ds,ds:[bx].ih_sel
        call FreeIniSel
        pop ds

delete_handle_done:
        pop bx
        pop ds
        ret
delete_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           Init
;
;       DESCRIPTION:    Init driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_inifile
    
init_inifile    Proc near
        mov ax,SEG data
        mov ds,ax
        InitSection ds:is_section
        mov ds:is_sys_sel,0
;
        mov ax,cs
        mov ds,ax
        mov es,ax
;
        mov si,OFFSET open_sys_ini
        mov di,OFFSET open_sys_ini_name
        xor dx,dx
        mov ax,open_sys_ini_nr
        RegisterBimodalUserGate
;    
        mov bx,OFFSET open_ini16
        mov si,OFFSET open_ini32
        mov di,OFFSET open_ini_name
        mov dx,virt_es_in
        mov ax,open_ini_nr
        RegisterUserGate
;
        mov si,OFFSET close_ini
        mov di,OFFSET close_ini_name
        xor dx,dx
        mov ax,close_ini_nr
        RegisterBimodalUserGate
;    
        mov bx,OFFSET goto_ini_section16
        mov si,OFFSET goto_ini_section32
        mov di,OFFSET goto_ini_section_name
        mov dx,virt_es_in
        mov ax,goto_ini_section_nr
        RegisterUserGate
;    
        mov bx,OFFSET remove_ini_section16
        mov si,OFFSET remove_ini_section32
        mov di,OFFSET remove_ini_section_name
        mov dx,virt_es_in
        mov ax,remove_ini_section_nr
        RegisterUserGate
;    
        mov bx,OFFSET read_ini16
        mov si,OFFSET read_ini32
        mov di,OFFSET read_ini_name
        mov dx,virt_ds_in OR virt_es_in
        mov ax,read_ini_nr
        RegisterUserGate
;    
        mov bx,OFFSET write_ini16
        mov si,OFFSET write_ini32
        mov di,OFFSET write_ini_name
        mov dx,virt_ds_in OR virt_es_in
        mov ax,write_ini_nr
        RegisterUserGate
;    
        mov bx,OFFSET delete_ini16
        mov si,OFFSET delete_ini32
        mov di,OFFSET delete_ini_name
        mov dx,virt_ds_in
        mov ax,delete_ini_nr
        RegisterUserGate
;
        mov di,OFFSET delete_handle
        mov ax,INI_HANDLE
        RegisterHandle
        ret
init_inifile    Endp

code    ENDS

        END

