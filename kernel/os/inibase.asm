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
INCLUDE ..\..\kernel\os\core.inc

    .386p

ini_sel STRUC

ini_prev    DW ?
ini_next    DW ?
ini_sect    section_typ <>

ini_sel ENDS


data    SEGMENT byte public 'DATA'

ini_section     section_typ <>
ini_list        DW ?

data    ENDS


_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Lock
;
;           DESCRIPTION:    Lock section
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public Lock_

Lock_    Proc near
    push ds
    push eax
;
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:ini_section    
;
    pop eax
    pop ds
    ret
Lock_   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Unock
;
;           DESCRIPTION:    Unock section
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public Unlock_

Unlock_    Proc near
    push ds
    push eax
;
    mov eax,SEG data
    mov ds,eax
    LeaveSection ds:ini_section    
;
    pop eax
    pop ds
    ret
Unlock_   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockIni
;
;           DESCRIPTION:    Lock ini file
;
;           PARAMETERS:     DX:EAX      Ini
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LockIni_

LockIni_    Proc near
    push ds
    mov ds,edx
    EnterSection ds:ini_sect
    pop ds
    ret
LockIni_   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockIni
;
;           DESCRIPTION:    Unlock ini file
;
;           PARAMETERS:     DX:EAX      Ini
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public UnlockIni_

UnlockIni_    Proc near
    push ds
    mov ds,edx
    LeaveSection ds:ini_sect
    pop ds
    ret
UnlockIni_   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateIni
;
;           DESCRIPTION:    Create ini file
;
;           PARAMETERS:     ECX       Extra size
;
;           RETURNS:        DX:EAX    Ini
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateIni_

CreateIni_    Proc near
    push es
    mov eax,ecx
    add eax,SIZE ini_sel
    AllocateSmallGlobalMem
    InitSection es:ini_sect
    mov edx,es
    mov eax,SIZE ini_sel
    pop es
    ret
CreateIni_   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DeleteIni
;
;           DESCRIPTION:    Delete ini file
;
;           PARAMETERS:     DX:EAX    Ini
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DeleteIni_

DeleteIni_    Proc near
    push es
    mov es,edx
    FreeMem
    pop es
    ret
DeleteIni_   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetFirstIni
;
;           DESCRIPTION:    Get first ini file
;
;           PARAMETERS:     
;
;           RETURNS:        DX:EAX    Ini
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetFirstIni_

GetFirstIni_    Proc near
    push ds
;
    mov eax,SEG data
    mov ds,eax
    mov dx,ds:ini_list
    xor eax,eax
    or dx,dx
    jz gfiDone
;
    mov eax,SIZE ini_sel    

gfiDone:
    pop ds
    ret
GetFirstIni_   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetNextIni
;
;           DESCRIPTION:    Get next ini file
;
;           PARAMETERS:     DX:EAX    Ini in
;
;           RETURNS:        DX:EAX    next Ini
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetNextIni_

GetNextIni_    Proc near
    push ds
    push es
;
    mov eax,SEG data
    mov ds,eax
;
    mov es,dx
    mov dx,es:ini_next
    cmp dx,ds:ini_list
    jne gniOk
;
    xor dx,dx 
    xor eax,eax
    jmp gniDone

gniOk:    
    mov eax,SIZE ini_sel    

gniDone:       
    pop es
    pop ds
    ret
GetNextIni_   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InsertIni
;
;           DESCRIPTION:    Insert ini object into list
;
;           PARAMETERS:     DX:EAX      Ini
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   public InsertIni_
   
InsertIni_ Proc near
    push ds
    push es
    push eax
;
    mov eax,SEG data
    mov ds,eax
    mov es,dx
;    
    push edi
    mov di,ds:ini_list
    or di,di
    je iiEmpty
;    
    push ds
    push esi
    mov ds,di
    mov si,ds:ini_prev
    mov ds:ini_prev,es
    mov ds,si
    mov ds:ini_next,es
    mov es:ini_next,di
    mov es:ini_prev,si
    pop esi
    pop ds
    pop edi
    jmp iiDone
    
iiEmpty:
    mov es:ini_next,es
    mov es:ini_prev,es
    pop edi
    mov ds:ini_list,es

iiDone:
    pop eax
    pop es
    pop ds
    ret
InsertIni_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RemoveIni
;
;           DESCRIPTION:    Remove ini object from list
;
;           PARAMETERS:     DX:EAX      Ini object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   public RemoveIni_

RemoveIni_ Proc near
    push ds
    push es
    push eax
;
    mov eax,SEG data
    mov ds,eax
;
    mov ax,ds:ini_list
    or ax,ax
    jz riDone

riLoop:
    cmp ax,dx
    je riRemove
;
    mov es,ax
    mov ax,es:ini_next
    cmp ax,ds:ini_list
    jne riLoop
    jmp riDone

riRemove:
    push esi
    mov es,dx
    push edi
    push ds
    mov di,es:ini_next
    mov ds:ini_list,di
    cmp di,dx
    mov ds:ini_list,di
    mov si,es:ini_prev
    mov ds,di
    mov ds:ini_prev,si
    mov ds,si
    mov ds:ini_next,di
    pop ds
    pop edi
    pop esi
    jne riDone
;    
    mov ds:ini_list,0
    
riDone:
    pop eax
    pop es
    pop ds
    ret
RemoveIni_ Endp
   
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
    mov ax,SEG data
    mov ds,ax
    InitSection ds:ini_section
    mov ds:ini_list,0
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
