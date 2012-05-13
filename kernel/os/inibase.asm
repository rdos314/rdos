;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2012, Leif Ekblad
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
; INIBASE.ASM
; Ini-file support functions not available from RDOS device-driver interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def
INCLUDE ..\..\kernel\os\proc.inc

    .386p

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadIniVar
;
;       DESCRIPTION:    Read ini var
;
;       PARAMETERS:     EBX     Handle
;                       DS:ESI  Variable
;                       ES:EDI  Buffer
;                       ECX     Size
;
;       RETURNS:        NC   OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_ini_var_name    DB 'Read Ini Var',0

    extrn ReadIniVar:near

read_ini_var16  Proc far
    push fs
    push ecx
    push esi
    push edi
;
    movzx ecx,cx
    movzx esi,si
    movzx edi,di
    mov eax,ds
    mov fs,eax
;    
    call ReadIniVar    
;
    or eax,eax
    jz read_ini16_failed
;
    clc
    jmp read_ini16_done

read_ini16_failed:
    stc

read_ini16_done:
    pop edi
    pop esi
    pop ecx           
    push fs
    ret
read_ini_var16 Endp

read_ini_var32  Proc far
    push fs
;    
    mov eax,ds    
    mov fs,eax
    call ReadIniVar    
;
    or eax,eax
    jz read_ini32_failed
;
    clc
    jmp read_ini32_done

read_ini32_failed:
    stc

read_ini32_done:
    pop fs
    ret
read_ini_var32 Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteIniVar
;
;       DESCRIPTION:    Write ini var
;
;       PARAMETERS:     EBX     Handle
;                       DS:ESI  Variable
;                       ES:EDI  Buffer
;
;       RETURNS:        NC   OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_ini_var_name    DB 'Write Ini Var',0

    extrn WriteIniVar:near

write_ini_var16  Proc far
    push fs
    push eax
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    mov eax,ds
    mov fs,eax
;    
    call WriteIniVar    
;
    or eax,eax
    jz write_ini16_failed
;
    clc
    jmp write_ini16_done

write_ini16_failed:
    stc

write_ini16_done:
    pop edi
    pop esi
    pop eax
    pop fs
    ret
write_ini_var16 Endp

write_ini_var32  Proc far
    push fs
    push eax
;    
    mov eax,ds    
    mov fs,eax
    call WriteIniVar    
;
    or eax,eax
    jz write_ini32_failed
;
    clc
    jmp write_ini32_done

write_ini32_failed:
    stc

write_ini32_done:
    pop eax
    pop fs
    ret
write_ini_var32 Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteIniVar
;
;       DESCRIPTION:    Delete ini var
;
;       PARAMETERS:     EBX     Handle
;                       DS:ESI  Variable
;
;       RETURNS:        NC   OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_ini_var_name    DB 'Delete Ini Var',0

    extrn DeleteIniVar:near

delete_ini_var16  Proc far
    push fs
    push eax
    push esi
;
    movzx esi,si
    mov eax,ds
    mov fs,eax
;    
    call DeleteIniVar    
;
    or eax,eax
    jz delete_ini16_failed
;
    clc
    jmp delete_ini16_done

delete_ini16_failed:
    stc

delete_ini16_done:
    pop esi
    pop eax
    pop fs
    ret
delete_ini_var16 Endp

delete_ini_var32  Proc far
    push fs
    push eax
;    
    mov eax,ds    
    mov fs,eax
    call DeleteIniVar    
;
    or eax,eax
    jz delete_ini32_failed
;
    clc
    jmp delete_ini32_done

delete_ini32_failed:
    stc

delete_ini32_done:
    pop eax
    pop fs
    ret
delete_ini_var32 Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitGates
;
;           DESCRIPTION:    Initialize gates
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitGates_

InitGates_    Proc near
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov ebx,OFFSET read_ini_var16
    mov esi,OFFSET read_ini_var32
    mov edi,OFFSET read_ini_var_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,read_ini_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_ini_var16
    mov esi,OFFSET write_ini_var32
    mov edi,OFFSET write_ini_var_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,write_ini_nr
    RegisterUserGate
;
    mov ebx,OFFSET delete_ini_var16
    mov esi,OFFSET delete_ini_var32
    mov edi,OFFSET delete_ini_var_name
    mov dx,virt_ds_in
    mov ax,delete_ini_nr
    RegisterUserGate
;
    popad
    pop es
    pop ds
    ret
InitGates_    Endp

_TEXT    ENDS

    END
