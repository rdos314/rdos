;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2017, Leif Ekblad
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
; CHANDLE.ASM
; C-library handle compatibility layer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
include ..\wait.inc
INCLUDE ..\driver.def
INCLUDE chandle.inc
INCLUDE exec.def

MAX_HANDLES           = 256

handle_proc_struc       STRUC

hp_handle       DW ?
hp_access       DW ?
hp_pos          DD ?

handle_proc_struc       ENDS

handle_struc    STRUC

h_section       section_typ <>

h_arr           DB MAX_HANDLES * size handle_proc_struc DUP(?)

handle_struc    ENDS

socket_wait_header STRUC

sw_obj          wait_obj_header <>
sw_handle       DW ?

socket_wait_header ENDS


    .386p

code    SEGMENT byte public use16 'CODE'
    
    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCHandle
;
;           DESCRIPTION:    Create C handle
;
;           RETURNS:        AX          C handle selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_c_handle_name DB 'Create C Handle', 0

create_c_handle Proc far
    push ds
    push es
    push bx
    push cx
    push dx
    push si
    push di
;    
    mov ax,chandle_data_sel
    mov ds,ax
;
    mov di,OFFSET hd_data
    inc ds:[di].he_ref_count
;
    add di,SIZE handle_entry_struc
    add ds:[di].he_ref_count,2
;
    mov eax,SIZE handle_struc
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
;    
    mov di,OFFSET h_arr
    mov ds:[di].hp_handle,1
    mov ds:[di].hp_access,IO_READ OR IO_ISTTY
    mov ds:[di].hp_pos,0
;
    add di,SIZE handle_proc_struc
    mov ds:[di].hp_handle,2
    mov ds:[di].hp_access,IO_WRITE OR IO_ISTTY
    mov ds:[di].hp_pos,0
;
    add di,SIZE handle_proc_struc
    mov ds:[di].hp_handle,2
    mov ds:[di].hp_access,IO_WRITE OR IO_ISTTY
    mov ds:[di].hp_pos,0
;    
    mov cx,MAX_HANDLES - 3

nsLoop:
    add di,SIZE handle_proc_struc
    mov ds:[di].hp_handle,0
    mov ds:[di].hp_access,0
    mov ds:[di].hp_pos,0
    loop nsLoop
;    
    InitSection ds:h_section
    mov ax,ds
;
    pop di
    pop si
    pop dx
    pop cx
    pop bx    
    pop es
    pop ds
    retf32
create_c_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloneCHandle
;
;           DESCRIPTION:    Clone C handle
;
;           PARAMETERS:     AX          Incoming C handle sel
;
;           RETURNS:        AX          Cloned C handle sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clone_c_handle_name  DB 'Clone C Handle', 0

clone_c_handle  Proc far
    push ds
    push es
    push bx
    push cx
;
    mov ds,ax
;
    mov eax,SIZE handle_struc
    AllocateSmallGlobalMem
    InitSection es:h_section
;    
    mov cx,MAX_HANDLES
    xor bx,bx

ncLoop:
    push bx
    push cx
;
    shl bx,3
    add bx,OFFSET h_arr
;
    mov es:[bx].hp_handle,0
    mov es:[bx].hp_access,0
    mov es:[bx].hp_pos,0
;
    EnterSection ds:h_section
    mov ax,ds:[bx].hp_handle
    or ax,ax
    jz ncNextLeave
;
    mov es:[bx].hp_handle,ax
;
    push ds
    push bx
;
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
    add ds:[bx].he_ref_count,1
;
    pop bx
    pop ds
;
    mov ax,ds:[bx].hp_access
    mov es:[bx].hp_access,ax
;
    mov eax,ds:[bx].hp_pos
    mov es:[bx].hp_pos,eax

ncNextLeave:
    LeaveSection ds:h_section

ncNext:
    pop cx
    pop bx
;
    inc bx
    sub cx,1
    jnz ncLoop
;
    mov ax,es
;
    pop cx
    pop bx
    pop es
    pop ds
    retf32
clone_c_handle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DeleteCHandle
;
;           DESCRIPTION:    Delete C Handle
;
;           PARAMETERS:     AX        C handle sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_c_handle_name DB 'Delete C Handle', 0

delete_c_handle Proc far
    push ds
    push es
    pushad
;
    mov ds,ax
;    
    mov cx,MAX_HANDLES
    xor bx,bx

ntLoop:
    push bx
    push cx
;
    shl bx,3
    add bx,OFFSET h_arr
    EnterSection ds:h_section
    xor ax,ax
    xchg ax,ds:[bx].hp_handle
    mov ds:[bx].hp_access,0
    mov ds:[bx].hp_pos,0
    LeaveSection ds:h_section
;
    cmp ax,SYS_HANDLE_COUNT
    jae ntNext
;    
    or ax,ax
    jz ntNext
;
    push ds
    dec ax
    movzx ecx,ax
    mov dx,SIZE handle_entry_struc
    mul dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
    EnterSection ds:hd_section
;
    sub ds:[bx].he_ref_count,1
    jnz ntLeave
;
    xor ax,ax
    xchg ax,ds:[bx].he_sel
    mov bx,ds:[bx].he_type
    btc ds:hd_bitmap,ecx
;
    cmp bx,10
    jae ntLeave
;
    shl bx,1
    call word ptr cs:[bx].close_tab

ntLeave:
    LeaveSection ds:hd_section
    pop ds

ntNext:
    pop cx
    pop bx
;
    inc bx
    sub cx,1
    jnz ntLoop
;
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem
;
    popad
    pop es
    pop ds
    retf32
delete_c_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           allocate_c_handle
;
;           DESCRIPTION:    Allocate C handle
;
;           PARAMETERS:     AX          Handle type
;                           DX          Sel
;
;           RETURNS:        BX          Entry handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_c_handle_name  DB 'Allocate C Handle', 0

allocate_c_handle     Proc far
    push ds
    push eax
    push ecx
    push edx
    push edi
;
    push eax
    push edx
;
    mov ax,chandle_data_sel
    mov ds,ax
    EnterSection ds:hd_section
;
    mov cx,SYS_BITMAP_COUNT  
    xor edi,edi
    mov bx,OFFSET hd_bitmap

achLoop:
    mov eax,ds:[bx]
    not eax
    bsf edx,eax
    jnz achOk
;
    add bx,4
    add edi,32
;
    loop achLoop
;
    stc
    pop edx
    pop eax
    jmp achLeave

achOk:
    add edx,edi
    bts ds:hd_bitmap,edx
;    
    mov ax,SIZE handle_entry_struc
    mul dx
    mov di,ax
    add di,OFFSET hd_data
;
    pop edx
    pop eax
;
    mov ds:[di].he_type,ax
    mov ds:[di].he_sel,dx
    mov ds:[di].he_ref_count,1
    mov ds:[di].he_read_wait_sel,0
    mov ds:[di].he_write_wait_sel,0
    mov ds:[di].he_exc_wait_sel,0
;
    mov ax,di
    sub ax,OFFSET hd_data
    xor dx,dx
    mov cx,SIZE handle_entry_struc
    div cx
;
    mov bx,ax
    inc bx
    clc

achLeave:
    LeaveSection ds:hd_section
; 
    pop edi
    pop edx
    pop ecx
    pop eax
    pop ds
    retf32
allocate_c_handle  Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ref_c_handle
;
;           DESCRIPTION:    Allocate C handle
;
;           PARAMETERS:     AX          Handle type
;                           BX          Entry handle
;                           DX          Sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ref_c_handle_name  DB 'Ref C Handle', 0

ref_c_handle     Proc far
    push ds
    push di
;
    mov di,chandle_data_sel
    mov ds,di
    EnterSection ds:hd_section
;
    cmp bx,SYS_BITMAP_COUNT
    jae rchLeaveFail
;
    or bx,bx
    jz rchLeaveFail
;
    push eax
    push dx
;
    mov dx,bx
    dec dx
    mov ax,SIZE handle_entry_struc
    mul dx
    mov di,ax
    add di,OFFSET hd_data
;
    movzx eax,bx
    dec eax
    bt ds:hd_bitmap,eax
;
    pop dx
    pop eax
    jnc rchLeaveFail
;
    cmp ax,ds:[di].he_type
    jne rchLeaveFail
;
    cmp dx,ds:[di].he_sel
    jne rchLeaveFail
;
    add ds:[di].he_ref_count,1
    clc
    jmp rchLeave

rchLeaveFail:
    stc

rchLeave: 
    LeaveSection ds:hd_section
;
    pop di
    pop ds
    retf32
ref_c_handle  Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           allocate_proc_handle
;
;           DESCRIPTION:    Allocate process handle
;
;           PARAMETERS:     DS          C handle sel
;                           AX          C Handle
;                           CX          Mode
;                           EDX         Position
;
;           RETURNS:        BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_proc_handle     Proc near
    push dx
;    
    push cx
    mov cx,MAX_HANDLES
    mov bx,OFFSET h_arr
    EnterSection ds:h_section

aphLoop:    
    mov dx,ds:[bx].hp_handle
    or dx,dx
    jz aphFound
;
    add bx,SIZE handle_proc_struc
    loop aphLoop
;
    pop cx
    LeaveSection ds:h_section
    stc
    jmp aphDone

aphFound:    
    pop cx
    mov ds:[bx].hp_handle,ax
    mov ds:[bx].hp_access,cx
    mov ds:[bx].hp_pos,edx
    LeaveSection ds:h_section
;
    sub bx,OFFSET h_arr
    shr bx,3
    clc
    movzx ebx,bx

aphDone:   
    pop dx
    ret
allocate_proc_handle  Endp   
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateCProcHandle
;
;           DESCRIPTION:    Allocate C process handle
;
;           PARAMETERS:     BX          C Handle
;                           CX          Mode
;                           EDX         Position
;
;           RETURNS:        BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_c_proc_handle_name DB 'Allocate C Proc Handle', 0


allocate_c_proc_handle     Proc far
    push ds
    push ax
    push cx
    push dx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    mov ax,bx
    push cx
    mov cx,MAX_HANDLES
    mov bx,OFFSET h_arr
    EnterSection ds:h_section

acphLoop:    
    mov dx,ds:[bx].hp_handle
    or dx,dx
    jz acphFound
;
    add bx,SIZE handle_proc_struc
    loop acphLoop
;
    pop cx
    LeaveSection ds:h_section
    stc
    jmp acphDone

acphFound:    
    pop cx
    mov ds:[bx].hp_handle,ax
    mov ds:[bx].hp_access,cx
    mov ds:[bx].hp_pos,edx
    LeaveSection ds:h_section
;
    sub bx,OFFSET h_arr
    shr bx,3
    clc
    movzx ebx,bx

acphDone:   
    pop dx
    pop cx
    pop ax
    pop ds
    retf32
allocate_c_proc_handle  Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenHandle
;
;           DESCRIPTION:    Open C handle
;
;           PARAMETERS:     ES:(E)DI    Name
;                           CX          Mode
;
;           RETURNS:        EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_handle_name  DB 'Open C Handle', 0

open_handle     Proc near
    push ds
    push ax
    push cx
    push edx
;    
    OpenCFile
    jc ohFail
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;
    mov al,cl
    and al,3
    cmp al,O_RDWR
    je ohRdWr
;
    cmp al,O_RDONLY
    je ohRdOnly
;
    cmp al,O_WRONLY
    je ohWrOnly
;
    xor ax,ax
    jmp ohAccessOk

ohRdWr:
    mov ax,IO_READ OR IO_WRITE
    jmp ohAccessOk

ohRdOnly:
    mov ax,IO_READ
    jmp ohAccessOk

ohWrOnly:
    mov ax,IO_WRITE

ohAccessOk:
    test cx,O_BINARY
    jz ohTextOk
;
    or ax,IO_BINARY

ohTextOk:
    test cx,O_APPEND
    jz ohAppendOk
;
    or ax,IO_APPEND 

ohAppendOk:
    mov cx,ax
    mov ax,bx
    xor edx,edx
    call allocate_proc_handle
    jnc ohDone
;
    dec ax
    movzx ecx,ax
    mov dx,SIZE handle_entry_struc
    mul dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
    EnterSection ds:hd_section
;
    sub ds:[bx].he_ref_count,1
    jnz ohLeaveFail
;
    xor ax,ax
    xchg ax,ds:[bx].he_sel
    mov bx,ds:[bx].he_type
    btc ds:hd_bitmap,ecx
;
    cmp bx,10
    jae ohLeaveFail
;
    shl bx,1
    call word ptr cs:[bx].close_tab

ohLeaveFail:
    LeaveSection ds:hd_section

ohFail:
    mov ebx,-1
    jmp ohDone

ohDone:
    pop edx
    pop cx
    pop ax
    pop ds
    ret
open_handle     Endp

open_handle16    PROC far
    push edi
    movzx edi,di
    call open_handle
    pop edi
    retf32
open_handle16    ENDP

open_handle32    PROC far
    call open_handle
    retf32
open_handle32    ENDP
        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseHandle
;
;           DESCRIPTION:    Close C handle
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EBX         Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_handle_name  DB 'Close C Handle', 0

close_dummy     Proc near
    ret
close_dummy     Endp

close_file      Proc near
    mov bx,ax
    CloseCFile
    ret
close_file      Endp

close_tcp_socket	Proc near
    mov bx,ax
    CloseTcpSocket
    ret
close_tcp_socket	Endp

close_udp_socket	Proc near
    mov bx,ax
    CloseUdpSocket
    ret
close_udp_socket	Endp

close_tab:
ct00  DW OFFSET close_dummy
ct01  DW OFFSET close_file
ct02  DW OFFSET close_dummy
ct03  DW OFFSET close_dummy
ct04  DW OFFSET close_tcp_socket
ct05  DW OFFSET close_udp_socket
ct06  DW OFFSET close_dummy
ct07  DW OFFSET close_dummy
ct08  DW OFFSET close_dummy
ct09  DW OFFSET close_dummy


close_handle     Proc near
    push ds
    push ax
    push ecx
    push dx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae chFail
;
    shl bx,3
    add bx,OFFSET h_arr
    EnterSection ds:h_section
    xor ax,ax
    xchg ax,ds:[bx].hp_handle
    mov ds:[bx].hp_access,0
    mov ds:[bx].hp_pos,0
    LeaveSection ds:h_section
;
    cmp ax,SYS_HANDLE_COUNT
    jae chFail
;    
    or ax,ax
    jz chFail
;
    dec ax
    movzx ecx,ax
    mov dx,SIZE handle_entry_struc
    mul dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
    EnterSection ds:hd_section
;
    sub ds:[bx].he_ref_count,1
    jnz chLeave
;
    xor ax,ax
    xchg ax,ds:[bx].he_sel
    mov bx,ds:[bx].he_type
    btc ds:hd_bitmap,ecx
;
    cmp bx,10
    jae chLeave
;
    shl bx,1
    call word ptr cs:[bx].close_tab

chLeave:
    LeaveSection ds:hd_section
    xor ebx,ebx
    jmp chDone

chFail:
    mov ebx,-1

chDone:
    pop dx
    pop ecx
    pop ax
    pop ds    
    retf32
close_handle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CHandleToFileSel
;
;           DESCRIPTION:    Convert C handle to file selector
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        BX          File sel or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

c_handle_to_file_sel_name  DB 'C Handle To File Sel', 0

c_handle_to_file_sel     Proc near
    push ds
    push eax
    push edx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae chfsFail
;   
    shl bx,3
    add bx,OFFSET h_arr
;
    mov ax,ds:[bx].hp_handle
    cmp ax,SYS_HANDLE_COUNT
    jae chfsFail
;    
    or ax,ax
    jz chfsFail
;
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    mov bx,ds:[bx].he_sel
    clc
    jmp chfsDone

chfsFail:
    stc
    xor bx,bx

chfsDone:
    pop edx
    pop eax
    pop ds    
    retf32
c_handle_to_file_sel     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadHandle
;
;           DESCRIPTION:    Read C handle
;
;           PARAMETERS:     BX          Handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;           RETURNS:        EAX         Read count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_handle_name  DB 'Read C Handle', 0

read_dummy      Proc near
    stc
    ret
read_dummy      Endp

read_stdin       Proc near
    ReadCConsole
    clc
    ret
read_stdin       Endp

read_file       Proc near
    ReadCFile
    ret
read_file       Endp

read_tcp_socket       Proc near
    ReadTcpSocket
    ret
read_tcp_socket       Endp

read_udp_socket       Proc near
    ReadUdpSocket
    ret
read_udp_socket       Endp

read_tab:
rt00  DW OFFSET read_dummy
rt01  DW OFFSET read_file
rt02  DW OFFSET read_stdin
rt03  DW OFFSET read_dummy
rt04  DW OFFSET read_tcp_socket
rt05  DW OFFSET read_udp_socket
rt06  DW OFFSET read_dummy
rt07  DW OFFSET read_dummy
rt08  DW OFFSET read_dummy
rt09  DW OFFSET read_dummy

read_handle     Proc near
    push ds
    push ebx
    push edx
    push esi
    push ebp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae rhFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov si,ds:[bx].hp_access
    test si,IO_READ
    jz rhFail
;
    mov edx,ds:[bx].hp_pos
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae rhFail
;    
    or ax,ax
    jz rhFail
;
    push ds
    push bx
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    test si,IO_BINARY
    jnz rhBinary
;

rhBinary:
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].read_tab
;
    pop bx
    pop ds
    jc rhFail
;
    mov ds:[bx].hp_pos,edx
    jmp rhDone

rhFail:
    mov eax,-1

rhDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop ds    
    ret
read_handle     Endp

read_handle16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call read_handle
;
    pop edi
    pop ecx
    retf32
read_handle16    ENDP

read_handle32    PROC far
    call read_handle
    retf32
read_handle32    ENDP
        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHandle
;
;           DESCRIPTION:    Write C handle
;
;           PARAMETERS:     BX          Handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;           RETURNS:        EAX         Written count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_handle_name  DB 'Write C Handle', 0

write_dummy     Proc near
    stc
    ret
write_dummy     Endp

write_stdout      Proc near
    WriteCConsole
    ret
write_stdout      Endp

write_file      Proc near
    WriteCFile
    clc
    ret
write_file      Endp

write_tcp_socket      Proc near
    WriteTcpSocket
    ret
write_tcp_socket      Endp

write_udp_socket      Proc near
    WriteUdpSocket
    ret
write_udp_socket      Endp

write_tab:
wt00  DW OFFSET write_dummy
wt01  DW OFFSET write_file
wt02  DW OFFSET write_dummy
wt03  DW OFFSET write_stdout
wt04  DW OFFSET write_tcp_socket
wt05  DW OFFSET write_udp_socket
wt06  DW OFFSET write_dummy
wt07  DW OFFSET write_dummy
wt08  DW OFFSET write_dummy
wt09  DW OFFSET write_dummy

txt_cr_lf  DB 0dh, 0ah

write_handle     Proc near
    push ds
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae whFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov si,ds:[bx].hp_access
    test si,IO_WRITE
    jz whFail
;
    mov edx,ds:[bx].hp_pos
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae whFail
;    
    or ax,ax
    jz whFail
;
    push ds
    push bx
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    test si,IO_APPEND
    jz whPosOk
;
    push bx
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].get_size_tab
    pop bx
    jc whPosOk
;
    mov edx,eax

whPosOk:
    test si,IO_BINARY
    jnz whBinary
;
    push ecx
    push edi
;
    or ecx,ecx
    clc
    jz whTextOk
;
    mov esi,edi

whTextLoop:
    mov al,es:[esi]
    cmp al,0ah
    jne whTextNext
;
    cmp esi,edi
    jz whTextAddCrLf
;
    mov al,es:[esi-1]
    cmp al,0dh
    je whTextNext

whTextAddCrLf:
    mov eax,esi
    sub eax,edi
    or eax,eax
;
    push eax
    push ebx
    push ecx
    push edi
    push ebp
    jz whTextBeforeOk
;
    push ebx
    mov ecx,eax
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].write_tab
    pop ebx

whTextBeforeOk:
    push es
    mov ecx,cs
    mov es,ecx
    mov edi,OFFSET txt_cr_lf
    mov ecx,2
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].write_tab
    pop es
;
    pop ebp
    pop edi
    pop ecx
    pop ebx
    pop eax
;
    add edi,eax
    sub ecx,1
    clc
    jz whTextOk
;
    inc edi
    mov esi,edi
    jmp whTextLoop
    
whTextNext:
    inc esi
    sub ecx,1
    jnz whTextLoop
;
    mov ecx,esi
    sub ecx,edi
    clc
    jz whTextOk
;
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].write_tab
    
whTextOk:
    pop edi
    pop eax
    jmp whWriteOk

whBinary:
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].write_tab

whWriteOk:
    pop bx
    pop ds
    jc whFail
;
    mov ds:[bx].hp_pos,edx
    jmp whDone

whFail:
    mov eax,-1

whDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ds    
    ret
write_handle    Endp

write_handle16  Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call write_handle
;
    pop edi
    pop ecx
    retf32
write_handle16    ENDP

write_handle32    PROC far
    call write_handle
    retf32
write_handle32    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DupHandle
;
;           DESCRIPTION:    Dup C handle
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EBX         New handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dup_handle_name  DB 'Dup C Handle', 0

dup_handle     Proc near
    push ds
    push es
    push ax
    push cx
    push edx
    push si
    push di
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae dhFail
;   
    mov si,bx
    shl si,3
    add si,OFFSET h_arr
    mov ax,ds:[si].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae dhFail
;    
    or ax,ax
    jz dhFail
;
    push ax
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    mov di,ax
    add di,OFFSET hd_data
    mov ax,chandle_data_sel
    mov es,ax
    pop ax
;
    mov cx,ds:[si].hp_access
    mov edx,ds:[si].hp_pos
    call allocate_proc_handle
    jc dhFail
;
    inc es:[di].he_ref_count
    jmp dhDone

dhFail:
    mov ebx,-1

dhDone:
    pop di
    pop si
    pop edx
    pop cx
    pop ax
    pop es
    pop ds    
    retf32
dup_handle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Dup2Handle
;
;           DESCRIPTION:    Dup2 C handle
;
;           PARAMETERS:     BX          Src handle
;                           AX          Dest handle
;
;           RETURNS:        EBX         New handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dup2_handle_name  DB 'Dup2 C Handle', 0

dup2_handle     Proc near
    push ds
    push es
    push ax
    push ecx
    push edx
    push si
    push di
    push bp
;
    mov di,ax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae d2hFail
;   
    mov si,bx
    shl si,3
    add si,OFFSET h_arr
    mov ax,ds:[si].hp_handle
    or ax,ax
    jz d2hFail
;
    cmp di,MAX_HANDLES
    jae d2hFail
;   
    push ax
    push bx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov es,ax
    inc es:[bx].he_ref_count
    pop bx
    pop ax
;
    mov bp,di
    shl di,3
    add di,OFFSET h_arr
    EnterSection ds:h_section
    mov dx,ds:[si].hp_access
    mov ds:[di].hp_access,dx
    mov edx,ds:[si].hp_pos
    mov ds:[di].hp_pos,edx
    xchg ax,ds:[di].hp_handle
    LeaveSection ds:h_section
;
    cmp ax,SYS_HANDLE_COUNT
    jae d2hOk
;    
    or ax,ax
    jz d2hOk
;
    dec ax
    movzx ecx,ax
    mov dx,SIZE handle_entry_struc
    mul dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
    EnterSection ds:hd_section
;
    sub ds:[bx].he_ref_count,1
    jnz d2hOkLeave
;
    xor ax,ax
    xchg ax,ds:[bx].he_sel
    mov bx,ds:[bx].he_type
    btc ds:hd_bitmap,ecx
;
    cmp bx,10
    jae d2hOkLeave
;
    shl bx,1
    call word ptr cs:[bx].close_tab

d2hOkLeave:
    LeaveSection ds:hd_section

d2hOk:
    movzx ebx,bp
    jmp d2hDone

d2hFail:
    mov ebx,-1

d2hDone:
    pop bp
    pop di
    pop si
    pop edx
    pop ecx
    pop ax
    pop es
    pop ds    
    retf32
dup2_handle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleSize
;
;           DESCRIPTION:    Get C handle size
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EAX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_size_name  DB 'Get C Handle Size', 0

get_size_dummy      Proc near
    stc
    ret
get_size_dummy      Endp

get_size_file       Proc near
    GetCFileSize
    ret
get_size_file       Endp

get_size_tab:
gst00  DW OFFSET get_size_dummy
gst01  DW OFFSET get_size_file
gst02  DW OFFSET get_size_dummy
gst03  DW OFFSET get_size_dummy
gst04  DW OFFSET get_size_dummy
gst05  DW OFFSET get_size_dummy
gst06  DW OFFSET get_size_dummy
gst07  DW OFFSET get_size_dummy
gst08  DW OFFSET get_size_dummy
gst09  DW OFFSET get_size_dummy

get_handle_size     Proc far
    push ds
    push bx
    push bp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ghsFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ghsFail
;    
    or ax,ax
    jz ghsFail
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].get_size_tab
    jnc ghsDone  

ghsFail:
    mov eax,-1

ghsDone:
    pop bp
    pop bx
    pop ds    
    retf32
get_handle_size     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandleSize
;
;           DESCRIPTION:    Set C handle size
;
;           PARAMETERS:     BX          Handle
;                           EAX         Size
;
;           RETURNS:        EAX         Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_handle_size_name  DB 'Set C Handle Size', 0

set_size_dummy      Proc near
    stc
    ret
set_size_dummy      Endp

set_size_file       Proc near
    SetCFileSize
    ret
set_size_file       Endp

set_size_tab:
sst00  DW OFFSET set_size_dummy
sst01  DW OFFSET set_size_file
sst02  DW OFFSET set_size_dummy
sst03  DW OFFSET set_size_dummy
sst04  DW OFFSET set_size_dummy
sst05  DW OFFSET set_size_dummy
sst06  DW OFFSET set_size_dummy
sst07  DW OFFSET set_size_dummy
sst08  DW OFFSET set_size_dummy
sst09  DW OFFSET set_size_dummy

set_handle_size     Proc far
    push ds
    push bx
    push edx
    push bp
;
    mov edx,eax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae shsFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae shsFail
;    
    or ax,ax
    jz shsFail
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    mov eax,edx
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].set_size_tab
    jnc shsDone

shsFail:
    mov eax,-1

shsDone:
    pop bp
    pop edx
    pop bx
    pop ds    
    retf32
set_handle_size     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleTime
;
;           DESCRIPTION:    Get C handle time
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EDX:EAX     Time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_time_name  DB 'Get C Handle Time', 0

get_time_dummy      Proc near
    stc
    ret
get_time_dummy      Endp

get_time_file       Proc near
    GetCFileTime
    ret
get_time_file       Endp

get_time_tab:
gtt00  DW OFFSET get_time_dummy
gtt01  DW OFFSET get_time_file
gtt02  DW OFFSET get_time_dummy
gtt03  DW OFFSET get_time_dummy
gtt04  DW OFFSET get_time_dummy
gtt05  DW OFFSET get_time_dummy
gtt06  DW OFFSET get_time_dummy
gtt07  DW OFFSET get_time_dummy
gtt08  DW OFFSET get_time_dummy
gtt09  DW OFFSET get_time_dummy

get_handle_time     Proc far
    push ds
    push bx
    push bp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ghtFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ghtFail
;    
    or ax,ax
    jz ghtFail
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].get_time_tab
    jnc ghtDone

ghtFail:
    mov eax,-1
    mov edx,-1

ghtDone:
    pop bp
    pop bx
    pop ds    
    retf32
get_handle_time     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandleTime
;
;           DESCRIPTION:    Set C handle time
;
;           PARAMETERS:     BX          Handle
;                           EDX:EAX     Time
;
;           RETURNS:        EAX         Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_handle_time_name  DB 'Set C Handle Time', 0

set_time_dummy      Proc near
    stc
    ret
set_time_dummy      Endp

set_time_file       Proc near
    SetCFileTime
    ret
set_time_file       Endp

set_time_tab:
stt00  DW OFFSET set_time_dummy
stt01  DW OFFSET set_time_file
stt02  DW OFFSET set_time_dummy
stt03  DW OFFSET set_time_dummy
stt04  DW OFFSET set_time_dummy
stt05  DW OFFSET set_time_dummy
stt06  DW OFFSET set_time_dummy
stt07  DW OFFSET set_time_dummy
stt08  DW OFFSET set_time_dummy
stt09  DW OFFSET set_time_dummy

set_handle_time     Proc far
    push ds
    push bx
    push edx
    push esi
    push bp
;
    mov esi,eax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae shtFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae shtFail
;    
    or ax,ax
    jz shtFail
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    mov eax,esi
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].set_time_tab
    mov eax,0
    jnc shtDone

shtFail:
    mov eax,-1

shtDone:
    pop bp
    pop esi
    pop edx
    pop bx
    pop ds    
    retf32
set_handle_time     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleMode
;
;           DESCRIPTION:    Get C handle mode
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EAX         Mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_mode_name  DB 'Get C Handle Mode', 0

get_handle_mode     Proc far
    push ds
    push bx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ghmFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    movzx eax,ds:[bx].hp_access
    jmp ghmDone

ghmFail:
    mov eax,-1

ghmDone:
    pop bx
    pop ds    
    retf32
get_handle_mode     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandleMode
;
;           DESCRIPTION:    Set C handle mode
;
;           PARAMETERS:     BX          Handle
;                           EAX         Mode
;
;           RETURNS:        EAX         Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_handle_mode_name  DB 'Set C Handle Mode', 0

set_handle_mode     Proc far
    push ds
    push bx
    push dx
;
    mov dx,ax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae shmFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov ds:[bx].hp_access,dx
    xor eax,eax
    jmp shmDone

shmFail:
    mov eax,-1

shmDone:
    pop dx
    pop bx
    pop ds    
    retf32
set_handle_mode     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandlePos
;
;           DESCRIPTION:    Get C handle pos
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EAX         Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_pos_name  DB 'Get C Handle Pos', 0

get_handle_pos     Proc far
    push ds
    push bx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ghpFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov eax,ds:[bx].hp_pos
    jmp ghpDone

ghpFail:
    mov eax,-1

ghpDone:
    pop bx
    pop ds    
    retf32
get_handle_pos     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandlePos
;
;           DESCRIPTION:    Set C handle pos
;
;           PARAMETERS:     BX          Handle
;                           EAX         Position
;
;           RETURNS:        EAX         Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_handle_pos_name  DB 'Set C Handle Pos', 0

set_handle_pos     Proc far
    push ds
    push bx
    push edx
;
    mov edx,eax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae shpFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov ds:[bx].hp_pos,edx
    mov eax,edx
    jmp shpDone

shpFail:
    mov eax,-1

shpDone:
    pop edx
    pop bx
    pop ds    
    retf32
set_handle_pos     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EofHandle
;
;           DESCRIPTION:    Eof for C handle
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EAX         Eof status (-1 = error, 0 = not eof, 1 = eof)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eof_handle_name  DB 'Eof C Handle', 0

eof_dummy      Proc near
    mov eax,-1
    ret
eof_dummy      Endp

eof_stdin      Proc near
    PollKeyboard
    jc eof_stdin_ok
;
    xor eax,eax
    ret

eof_stdin_ok:
    mov eax,1
    ret
eof_stdin      Endp

eof_stdout      Proc near
    mov eax,1
    ret
eof_stdout      Endp

eof_file       Proc near
    GetCFileSize
    cmp eax,edx
    je eof_file_ok
;
    xor eax,eax
    ret

eof_file_ok:
    mov eax,1
    ret
eof_file       Endp

eof_tab:
et00  DW OFFSET eof_dummy
et01  DW OFFSET eof_file
et02  DW OFFSET eof_stdin
et03  DW OFFSET eof_stdout
et04  DW OFFSET eof_dummy
et05  DW OFFSET eof_dummy
et06  DW OFFSET eof_dummy
et07  DW OFFSET eof_dummy
et08  DW OFFSET eof_dummy
et09  DW OFFSET eof_dummy

eof_handle     Proc far
    push ds
    push bx
    push edx
    push bp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ehFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov ax,ds:[bx].hp_handle
    mov edx,ds:[bx].hp_pos
;
    cmp ax,SYS_HANDLE_COUNT
    jae ehFail
;    
    or ax,ax
    jz ehFail
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].eof_tab
    jmp ehDone

ehFail:
    mov eax,-1

ehDone:
    pop bp
    pop edx
    pop bx
    pop ds    
    retf32
eof_handle     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsHandleDevice
;
;           DESCRIPTION:    Check if C handle is device
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        NC          Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_handle_device_name  DB 'Is C Handle Device', 0

not_device      Proc near
    stc
    ret
not_device      Endp

is_device      Proc near
    clc
    ret
is_device      Endp

dev_tab:
idt00  DW OFFSET not_device
idt01  DW OFFSET not_device
idt02  DW OFFSET is_device
idt03  DW OFFSET is_device
idt04  DW OFFSET not_device
idt05  DW OFFSET not_device
idt06  DW OFFSET not_device
idt07  DW OFFSET not_device
idt08  DW OFFSET not_device
idt09  DW OFFSET not_device

is_handle_device     Proc far
    push ds
    push bx
    push bp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ihdFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ihdFail
;    
    or ax,ax
    jz ihdFail
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].dev_tab
    jmp ihdDone

ihdFail:
    stc

ihdDone:
    pop bp
    pop bx
    pop ds    
    retf32
is_handle_device     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsIpv4Socket
;
;           DESCRIPTION:    Check for IPv4 socket
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        NC          IPv4 socket
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_ipv4_socket_name  DB 'Is IPv4 Socket', 0

is_ipv4_socket	Proc far
    push ds
    push ax
    push bx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae iisFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae iisFail
;    
    or ax,ax
    jz iisFail
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
;
    mov ax,chandle_data_sel
    mov ds,ax
    mov ax,ds:[bx].he_type
    cmp ax,C_HANDLE_TCP_SOCKET
    je iisOk
;
    cmp ax,C_HANDLE_UDP_SOCKET
    jne iisFail

iisOk:
    clc
    jmp iisDone

iisFail:
    stc

iisDone:
    pop bx
    pop ax
    pop ds
    retf32
is_ipv4_socket	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ConnectIpv4Socket
;
;           DESCRIPTION:    Connect IPv4 socket
;
;           PARAMETERS:    IN  BX                socket handle
;                          IN  EDX               IP
;                          IN  SI                port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

connect_ipv4_socket_name  DB 'Connect IPv4 Socket', 0

connect_ipv4_socket	Proc far
    push ds
    push ax
    push bx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae cisFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae cisFail
;    
    or ax,ax
    jz cisFail
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
;
    mov ax,chandle_data_sel
    mov ds,ax
    mov ax,ds:[bx].he_type
    cmp ax,C_HANDLE_TCP_SOCKET
    je cisTcp
;
    cmp ax,C_HANDLE_UDP_SOCKET
    jne cisFail

cisUpd:
    ConnectUdpSocket
    mov ds:[bx].he_sel,ax
    jmp cisDone

cisTcp:
    ConnectTcpSocket
    mov ds:[bx].he_sel,ax
    jmp cisDone

cisFail:
    stc

cisDone:
    pop bx
    pop ax
    pop ds
    retf32
connect_ipv4_socket	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          GetHandleReadBufCount
;
;           DESCRIPTION:   Get number of bytes available input buffer
;
;           PARAMETERS:    IN  BX                Handle
;                          OUT ECX               Bytes in input buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_read_buf_count_name  DB 'Get Handle Read Buffer Count', 0

read_buf_dummy      Proc near
    stc
    ret
read_buf_dummy      Endp

read_buf_stdin       Proc near
    PollKeyboard
    jnc rbstdin1
;
    xor ecx,ecx
    clc
    ret

rbstdin1:
    mov ecx,1
    clc
    ret
read_buf_stdin       Endp

read_buf_file       Proc near
    GetCFileSize
    mov ecx,eax
    sub ecx,edx
    clc
    ret
read_buf_file       Endp

read_buf_tcp_socket       Proc near
    GetTcpSocketReadCount
    ret
read_buf_tcp_socket       Endp

read_buf_udp_socket       Proc near
    GetUdpSocketReadCount
    ret
read_buf_udp_socket       Endp

read_buf_tab:
rbt00  DW OFFSET read_buf_dummy
rbt01  DW OFFSET read_buf_file
rbt02  DW OFFSET read_buf_stdin
rbt03  DW OFFSET read_buf_dummy
rbt04  DW OFFSET read_buf_tcp_socket
rbt05  DW OFFSET read_buf_udp_socket
rbt06  DW OFFSET read_buf_dummy
rbt07  DW OFFSET read_buf_dummy
rbt08  DW OFFSET read_buf_dummy
rbt09  DW OFFSET read_buf_dummy

get_handle_read_buf_count	Proc far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae rhbFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov edx,ds:[bx].hp_pos
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae rhbFail
;    
    or ax,ax
    jz rhbFail
;
    push ds
    push bx
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].read_buf_tab
;
    pop bx
    pop ds
    jc rhbFail
;
    jmp rhbDone

rhbFail:
    xor ecx,ecx
    stc

rhbDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    retf32
get_handle_read_buf_count	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          GetHandleWriteBufSpace
;
;           DESCRIPTION:   Get number of bytes available output buffer
;
;           PARAMETERS:    IN  BX                Handle
;                          OUT ECX               Space in output buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_write_buf_space_name  DB 'Get Handle Write Buffer Space', 0

write_buf_dummy      Proc near
    stc
    ret
write_buf_dummy      Endp

write_buf_stdout       Proc near
    mov ecx,1
    clc
    ret
write_buf_stdout       Endp

write_buf_file       Proc near
    GetCFileSize
    mov ecx,7FFFFFFFh
    sub ecx,eax
    clc
    ret
write_buf_file       Endp

write_buf_tcp_socket       Proc near
    GetTcpSocketWriteSpace
    ret
write_buf_tcp_socket       Endp

write_buf_udp_socket       Proc near
    mov ecx,512
    clc
    ret
write_buf_udp_socket       Endp

write_buf_tab:
wbt00  DW OFFSET write_buf_dummy
wbt01  DW OFFSET write_buf_file
wbt02  DW OFFSET write_buf_dummy
wbt03  DW OFFSET write_buf_stdout
wbt04  DW OFFSET write_buf_tcp_socket
wbt05  DW OFFSET write_buf_udp_socket
wbt06  DW OFFSET write_buf_dummy
wbt07  DW OFFSET write_buf_dummy
wbt08  DW OFFSET write_buf_dummy
wbt09  DW OFFSET write_buf_dummy

get_handle_write_buf_space	Proc far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae whbFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov edx,ds:[bx].hp_pos
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae whbFail
;    
    or ax,ax
    jz whbFail
;
    push ds
    push bx
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].write_buf_tab
;
    pop bx
    pop ds
    jc whbFail
;
    jmp whbDone

whbFail:
    xor ecx,ecx
    stc

whbDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    retf32
get_handle_write_buf_space	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          HasHandleException
;
;           DESCRIPTION:   Has handle exception
;
;           PARAMETERS:    IN  BX                Handle
;                          OUT CY		 Has exception
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_handle_exception_name  DB 'Has Handle Exception', 0

exc_dummy      Proc near
    clc
    ret
exc_dummy      Endp

exc_stdin       Proc near
    clc
    ret
exc_stdin       Endp

exc_tcp_socket       Proc near
    HasTcpSocketException
    ret
exc_tcp_socket       Endp

exc_tab:
eht00  DW OFFSET exc_dummy
eht01  DW OFFSET exc_dummy
eht02  DW OFFSET exc_stdin
eht03  DW OFFSET exc_dummy
eht04  DW OFFSET exc_tcp_socket
eht05  DW OFFSET exc_dummy
eht06  DW OFFSET exc_dummy
eht07  DW OFFSET exc_dummy
eht08  DW OFFSET exc_dummy
eht09  DW OFFSET exc_dummy

has_handle_exception	Proc far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae heFail
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov edx,ds:[bx].hp_pos
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae heFail
;    
    or ax,ax
    jz heFail
;
    push ds
    push bx
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].exc_tab
;
    pop bx
    pop ds
    jmp heDone

heFail:
    clc

heDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    retf32
has_handle_exception	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SignalReadHandle
;
;           DESCRIPTION:    Signal read handle
;
;           PARAMETERS:     BX	Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

signal_read_handle_name	DB 'Signal Read Handle', 0

signal_read_handle	Proc far
    push ds
    push ax
    push dx
;
    mov ax,chandle_data_sel
    mov ds,ax
    mov ax,bx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    mov bx,ax
    add bx,OFFSET hd_data
;
    EnterSection ds:hd_section
    xor ax,ax
    xchg ax,ds:[bx].he_read_wait_sel
    or ax,ax
    jz srhLeave
;
    push ds
    push cx
    push si
;
    mov ds,ax
    mov cx,ds:hw_count
    mov si,OFFSET hw_arr
    
srhLoop:
    lodsw
    mov es,ax
    SignalWait
    loop srhLoop
;
    mov ax,ds
    pop si
    pop cx
    pop ds
;
    mov es,ax
    FreeMem

srhLeave:
    LeaveSection ds:hd_section
;
    pop dx
    pop ax
    pop ds
    retf32
signal_read_handle      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForRead
;
;           DESCRIPTION:    Start a wait for read data
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_read_dummy      Proc near
    ret
start_read_dummy      Endp

start_read_stdin       Proc near
    ret
start_read_stdin       Endp

start_read_file       Proc near
    ret
start_read_file       Endp

start_read_tcp_socket       Proc near
    StartReadTcpSocket
    ret
start_read_tcp_socket       Endp

start_read_udp_socket       Proc near
    StartReadUdpSocket
    ret
start_read_udp_socket       Endp

start_wait_read_tab:
swrt00  DW OFFSET start_read_dummy
swrt01  DW OFFSET start_read_file
swrt02  DW OFFSET start_read_stdin
swrt03  DW OFFSET start_read_dummy
swrt04  DW OFFSET start_read_tcp_socket
swrt05  DW OFFSET start_read_udp_socket
swrt06  DW OFFSET start_read_dummy
swrt07  DW OFFSET start_read_dummy
swrt08  DW OFFSET start_read_dummy
swrt09  DW OFFSET start_read_dummy

start_wait_for_read       PROC far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    mov bx,es:sw_handle
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae swfrDone
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov edx,ds:[bx].hp_pos
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae swfrDone
;    
    or ax,ax
    jz swfrDone
;
    push ds
    push es
    push bx
    push di
;
    mov di,ax
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    EnterSection ds:hd_section
;
    mov bp,es
    mov ax,ds:[bx].he_read_wait_sel
    or ax,ax
    jnz swfrAdd
;
    mov eax,SIZE handle_wait_struc
    AllocateSmallGlobalMem
    mov es:hw_handle,di
    mov es:hw_count,1
    mov es:hw_arr,bp
    mov ds:[bx].he_read_wait_sel,es
    LeaveSection ds:hd_section
;
    mov ax,di
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].start_wait_read_tab
    jmp swfrLinked

swfrAdd:
    mov es,ax
    mov di,es:hw_count
    cmp di,HANDLE_WAIT_OBJ_COUNT
    je swfrLeave
;
    shl di,1
    mov es:[di].hw_arr,bp
    inc es:hw_count

swfrLeave:
    LeaveSection ds:hd_section

swfrLinked:
    pop di
    pop bx
    pop es
    pop ds

swfrDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    retf32
start_wait_for_read Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForRead
;
;           DESCRIPTION:    Stop a wait for socket read
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_read_dummy      Proc near
    ret
stop_read_dummy      Endp

stop_read_stdin       Proc near
    ret
stop_read_stdin       Endp

stop_read_file       Proc near
    ret
stop_read_file       Endp

stop_read_tcp_socket       Proc near
    StopReadTcpSocket
    ret
stop_read_tcp_socket       Endp

stop_read_udp_socket       Proc near
    StartReadUdpSocket
    ret
stop_read_udp_socket       Endp

stop_wait_read_tab:
ewrt00  DW OFFSET stop_read_dummy
ewrt01  DW OFFSET stop_read_file
ewrt02  DW OFFSET stop_read_stdin
ewrt03  DW OFFSET stop_read_dummy
ewrt04  DW OFFSET stop_read_tcp_socket
ewrt05  DW OFFSET stop_read_udp_socket
ewrt06  DW OFFSET stop_read_dummy
ewrt07  DW OFFSET stop_read_dummy
ewrt08  DW OFFSET stop_read_dummy
ewrt09  DW OFFSET stop_read_dummy

stop_wait_for_read    PROC far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    mov bx,es:sw_handle
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ewfrDone
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov edx,ds:[bx].hp_pos
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ewfrDone
;    
    or ax,ax
    jz ewfrDone
;
    push ds
    push bx
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    EnterSection ds:hd_section
    mov ax,ds:[bx].he_read_wait_sel
    or ax,ax
    jz ewfrLeave
;
    push ds
    push cx
    push dx
    push si
;
    mov ds,ax
    mov cx,ds:hw_count
    mov si,OFFSET hw_arr
    mov dx,es

ewfrFindLoop:
    lodsw
    cmp ax,dx
    je ewfrFound
;
    loop ewfrFindLoop
    jmp ewfrRemoved

ewfrFound:
    sub cx,1
    jz ewfrRemove

ewfrMoveLoop:
    mov ax,ds:[si]
    mov ds:[si-2],ax
    add si,2
    loop ewfrMoveLoop

ewfrRemove:
    sub ds:hw_count,1
    jnz ewfrRemoved
;
    push es
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem
    pop es
;
    pop si
    pop dx
    pop cx
    pop ds
    mov ds:[bx].he_read_wait_sel,0
    LeaveSection ds:hd_section
;
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].stop_wait_read_tab
    jmp ewfrPop

ewfrRemoved:
    pop si
    pop dx
    pop cx
    pop ds

ewfrLeave:
    LeaveSection ds:hd_section

ewfrPop:
    pop bx
    pop ds

ewfrDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    retf32
stop_wait_for_read Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearRead
;
;           DESCRIPTION:    Clear read
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_read    PROC far
    retf32
clear_read Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HasReadData
;
;           DESCRIPTION:    Check if read data is available
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_read_data      PROC far
    push bx
    push ecx
;
    mov bx,es:sw_handle
    GetHandleReadBufferCount
    cmc
    jnc hrdDone
;
    or ecx,ecx
    stc
    jz hrdDone
;
    clc

hrdDone:
    pop ecx
    pop bx
    retf32
has_read_data Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          AddWaitForHandleRead
;
;           DESCRIPTION:   Add wait for handle read
;
;           PARAMETERS:    IN  AX                Handle
;                          IN  BX                Wait handle
;                          IN  ECX               Object ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_handle_read_name  DB 'Add Wait For Handle Read', 0

add_wait_read_tab:
awr0 DD OFFSET start_wait_for_read,    SEG code
awr1 DD OFFSET stop_wait_for_read,     SEG code
awr2 DD OFFSET clear_read,             SEG code
awr3 DD OFFSET has_read_data,          SEG code

add_wait_for_handle_read	Proc far
    push ds
    push es
    push eax
    push edi
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE socket_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_read_tab
    AddWait
    pop ax
    jc awrDone
;
    mov es:sw_handle,ax

awrDone:
    pop edi
    pop eax
    pop es
    pop ds
    retf32
add_wait_for_handle_read	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SignalWriteHandle
;
;           DESCRIPTION:    Signal write handle
;
;           PARAMETERS:     BX	Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

signal_write_handle_name	DB 'Signal Write Handle', 0

signal_write_handle	Proc far
    push ds
    push ax
    push dx
;
    mov ax,chandle_data_sel
    mov ds,ax
    mov ax,bx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    mov bx,ax
    add bx,OFFSET hd_data
;
    EnterSection ds:hd_section
    xor ax,ax
    xchg ax,ds:[bx].he_write_wait_sel
    or ax,ax
    jz swhLeave
;
    push ds
    push cx
    push si
;
    mov ds,ax
    mov cx,ds:hw_count
    mov si,OFFSET hw_arr
    
swhLoop:
    lodsw
    mov es,ax
    SignalWait
    loop swhLoop
;
    mov ax,ds
    pop si
    pop cx
    pop ds
;
    mov es,ax
    FreeMem

swhLeave:
    LeaveSection ds:hd_section
;
    pop dx
    pop ax
    pop ds
    retf32
signal_write_handle      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForWrite
;
;           DESCRIPTION:    Start a wait for write data
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_write_dummy      Proc near
    ret
start_write_dummy      Endp

start_write_tcp_socket       Proc near
    StartWriteTcpSocket
    ret
start_write_tcp_socket       Endp

start_wait_write_tab:
swwt00  DW OFFSET start_write_dummy
swwt01  DW OFFSET start_write_dummy
swwt02  DW OFFSET start_write_dummy
swwt03  DW OFFSET start_write_dummy
swwt04  DW OFFSET start_write_tcp_socket
swwt05  DW OFFSET start_write_dummy
swwt06  DW OFFSET start_write_dummy
swwt07  DW OFFSET start_write_dummy
swwt08  DW OFFSET start_write_dummy
swwt09  DW OFFSET start_write_dummy

start_wait_for_write       PROC far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    mov bx,es:sw_handle
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae swfwDone
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov edx,ds:[bx].hp_pos
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae swfwDone
;    
    or ax,ax
    jz swfwDone
;
    push ds
    push es
    push bx
    push di
;
    mov di,ax
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    EnterSection ds:hd_section
;
    mov bp,es
    mov ax,ds:[bx].he_write_wait_sel
    or ax,ax
    jnz swfwAdd
;
    mov eax,SIZE handle_wait_struc
    AllocateSmallGlobalMem
    mov es:hw_handle,di
    mov es:hw_count,1
    mov es:hw_arr,bp
    mov ds:[bx].he_write_wait_sel,es
    LeaveSection ds:hd_section
;
    mov ax,di
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].start_wait_write_tab
    jmp swfwLinked

swfwAdd:
    mov es,ax
    mov di,es:hw_count
    cmp di,HANDLE_WAIT_OBJ_COUNT
    je swfwLeave
;
    shl di,1
    mov es:[di].hw_arr,bp
    inc es:hw_count

swfwLeave:
    LeaveSection ds:hd_section

swfwLinked:
    pop di
    pop bx
    pop es
    pop ds

swfwDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    retf32
start_wait_for_write Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForWrite
;
;           DESCRIPTION:    Stop a wait for socket write
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_write_dummy      Proc near
    ret
stop_write_dummy      Endp

stop_write_tcp_socket       Proc near
    StopWriteTcpSocket
    ret
stop_write_tcp_socket       Endp

stop_wait_write_tab:
ewwt00  DW OFFSET stop_write_dummy
ewwt01  DW OFFSET stop_write_dummy
ewwt02  DW OFFSET stop_write_dummy
ewwt03  DW OFFSET stop_write_dummy
ewwt04  DW OFFSET stop_write_tcp_socket
ewwt05  DW OFFSET stop_write_dummy
ewwt06  DW OFFSET stop_write_dummy
ewwt07  DW OFFSET stop_write_dummy
ewwt08  DW OFFSET stop_write_dummy
ewwt09  DW OFFSET stop_write_dummy

stop_wait_for_write    PROC far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    mov bx,es:sw_handle
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ewfwDone
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov edx,ds:[bx].hp_pos
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ewfwDone
;    
    or ax,ax
    jz ewfwDone
;
    push ds
    push bx
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    EnterSection ds:hd_section
    mov ax,ds:[bx].he_write_wait_sel
    or ax,ax
    jz ewfwLeave
;
    push ds
    push cx
    push dx
    push si
;
    mov ds,ax
    mov cx,ds:hw_count
    mov si,OFFSET hw_arr
    mov dx,es

ewfwFindLoop:
    lodsw
    cmp ax,dx
    je ewfwFound
;
    loop ewfwFindLoop
    jmp ewfwRemoved

ewfwFound:
    sub cx,1
    jz ewfwRemove

ewfwMoveLoop:
    mov ax,ds:[si]
    mov ds:[si-2],ax
    add si,2
    loop ewfwMoveLoop

ewfwRemove:
    sub ds:hw_count,1
    jnz ewfwRemoved
;
    push es
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem
    pop es
;
    pop si
    pop dx
    pop cx
    pop ds
    mov ds:[bx].he_write_wait_sel,0
    LeaveSection ds:hd_section
;
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].stop_wait_write_tab
    jmp ewfwPop

ewfwRemoved:
    pop si
    pop dx
    pop cx
    pop ds

ewfwLeave:
    LeaveSection ds:hd_section

ewfwPop:
    pop bx
    pop ds

ewfwDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    retf32
stop_wait_for_write Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearWrite
;
;           DESCRIPTION:    Clear write
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_write    PROC far
    retf32
clear_write Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HasWriteData
;
;           DESCRIPTION:    Check if write data is possible
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_write_data      PROC far
    push bx
    push ecx
;
    mov bx,es:sw_handle
    GetHandleWriteBufferSpace
    cmc
    jnc hwdDone
;
    or ecx,ecx
    stc
    jz hwdDone
;
    clc

hwdDone:
    pop ecx
    pop bx
    retf32
has_write_data Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          AddWaitForHandleWrite
;
;           DESCRIPTION:   Add wait for handle write
;
;           PARAMETERS:    IN  AX                Handle
;                          IN  BX                Wait handle
;                          IN  ECX               Object ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_handle_write_name  DB 'Add Wait For Handle Write', 0

add_wait_write_tab:
aww0 DD OFFSET start_wait_for_write,    SEG code
aww1 DD OFFSET stop_wait_for_write,     SEG code
aww2 DD OFFSET clear_write,             SEG code
aww3 DD OFFSET has_write_data,          SEG code

add_wait_for_handle_write	Proc far
    push ds
    push es
    push eax
    push edi
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE socket_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_write_tab
    AddWait
    pop ax
    jc awwDone
;
    mov es:sw_handle,ax

awwDone:
    pop edi
    pop eax
    pop es
    pop ds
    retf32
add_wait_for_handle_write	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForExc
;
;           DESCRIPTION:    Start a wait for exception
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_exc_dummy      Proc near
    ret
start_exc_dummy      Endp

start_exc_tcp_socket       Proc near
    StartExceptionTcpSocket
    ret
start_exc_tcp_socket       Endp

start_wait_exc_tab:
swet00  DW OFFSET start_exc_dummy
swet01  DW OFFSET start_exc_dummy
swet02  DW OFFSET start_exc_dummy
swet03  DW OFFSET start_exc_dummy
swet04  DW OFFSET start_exc_tcp_socket
swet05  DW OFFSET start_exc_dummy
swet06  DW OFFSET start_exc_dummy
swet07  DW OFFSET start_exc_dummy
swet08  DW OFFSET start_exc_dummy
swet09  DW OFFSET start_exc_dummy

start_wait_for_exc       PROC far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    mov bx,es:sw_handle
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae swfeDone
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov edx,ds:[bx].hp_pos
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae swfeDone
;    
    or ax,ax
    jz swfeDone
;
    push ds
    push bx
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].start_wait_exc_tab
;
    pop bx
    pop ds

swfeDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    retf32
start_wait_for_exc Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForExc
;
;           DESCRIPTION:    Stop a wait for socket exception
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_exc_dummy      Proc near
    ret
stop_exc_dummy      Endp

stop_exc_tcp_socket       Proc near
    StopExceptionTcpSocket
    ret
stop_exc_tcp_socket       Endp

stop_wait_exc_tab:
ewet00  DW OFFSET stop_exc_dummy
ewet01  DW OFFSET stop_exc_dummy
ewet02  DW OFFSET stop_exc_dummy
ewet03  DW OFFSET stop_exc_dummy
ewet04  DW OFFSET stop_exc_tcp_socket
ewet05  DW OFFSET stop_exc_dummy
ewet06  DW OFFSET stop_exc_dummy
ewet07  DW OFFSET stop_exc_dummy
ewet08  DW OFFSET stop_exc_dummy
ewet09  DW OFFSET stop_exc_dummy

stop_wait_for_exc    PROC far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    mov bx,es:sw_handle
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ewfeDone
;   
    shl bx,3
    add bx,OFFSET h_arr
    mov edx,ds:[bx].hp_pos
    mov ax,ds:[bx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ewfeDone
;    
    or ax,ax
    jz ewfeDone
;
    push ds
    push bx
;
    push dx
    dec ax
    mov dx,SIZE handle_entry_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET hd_data
    mov ax,chandle_data_sel
    mov ds,ax
;
    mov bp,ds:[bx].he_type
    mov bx,ds:[bx].he_sel
    shl bp,1
    call word ptr cs:[bp].stop_wait_exc_tab
;
    pop bx
    pop ds

ewfeDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    retf32
stop_wait_for_exc Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearExc
;
;           DESCRIPTION:    Clear exception
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_exc    PROC far
    retf32
clear_exc Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HasExcData
;
;           DESCRIPTION:    Check for pending exception
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_exc_data      PROC far
    push bx
;
    mov bx,es:sw_handle
    HasHandleException
    cmc
;
    pop bx
    retf32
has_exc_data Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          AddWaitForHandleException
;
;           DESCRIPTION:   Add wait for handle exception
;
;           PARAMETERS:    IN  AX                Handle
;                          IN  BX                Wait handle
;                          IN  ECX               Object ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_handle_exception_name  DB 'Add Wait For Handle Exception', 0

add_wait_exc_tab:
awe0 DD OFFSET start_wait_for_exc,    SEG code
awe1 DD OFFSET stop_wait_for_exc,     SEG code
awe2 DD OFFSET clear_exc,             SEG code
awe3 DD OFFSET has_exc_data,          SEG code

add_wait_for_handle_exception	Proc far
    push ds
    push es
    push eax
    push edi
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE socket_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_exc_tab
    AddWait
    pop ax
    jc aweDone
;
    mov es:sw_handle,ax

aweDone:
    pop edi
    pop eax
    pop es
    pop ds
    retf32
add_wait_for_handle_exception	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateTcpSocket
;
;       DESCRIPTION:    Create TCP socket
;
;       PARAMETERS:     OUT BX        Tcp handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_tcp_socket_name DB 'Create Tcp Socket', 0

create_tcp_socket    Proc far
    push es
    push eax
    push dx
;
    xor dx,dx
    mov ax,C_HANDLE_TCP_SOCKET
    AllocateCHandle
;
    mov cx,IO_READ OR IO_WRITE OR IO_BINARY
    xor edx,edx
    AllocateCProcHandle
;
    pop dx
    pop eax
    pop es
    retf32
create_tcp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateUdpSocket
;
;       DESCRIPTION:    Create UDP socket
;
;       PARAMETERS:     OUT BX        Udp handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_udp_socket_name DB 'Create Udp Socket', 0

create_udp_socket    Proc far
    push es
    push eax
    push dx
;
    xor dx,dx
    mov ax,C_HANDLE_UDP_SOCKET
    AllocateCHandle
;
    mov cx,IO_READ OR IO_WRITE OR IO_BINARY
    xor edx,edx
    AllocateCProcHandle
;
    pop dx
    pop eax
    pop es
    retf32
create_udp_socket    Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_chandle
;
;           DESCRIPTION:    Init C handle module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_chandle

init_chandle     PROC near
    push ds
    push es
    pushad
;
    mov eax,SIZE handle_data_struc
    mov bx,chandle_data_sel
    AllocateFixedSystemMem
;
    xor di,di
    mov cx,SIZE handle_data_struc
    xor al,al
    rep stosb
;
    InitSection es:hd_section
    mov es:hd_bitmap,3
;
    mov di,OFFSET hd_data
    mov es:[di].he_type,C_HANDLE_STDIN
    mov es:[di].he_sel,0
    mov es:[di].he_ref_count,1
    mov es:[di].he_read_wait_sel,0
    mov es:[di].he_write_wait_sel,0
    mov es:[di].he_exc_wait_sel,0
;
    add di,SIZE handle_entry_struc
    mov es:[di].he_type,C_HANDLE_STDOUT
    mov es:[di].he_sel,0
    mov es:[di].he_ref_count,2
    mov es:[di].he_read_wait_sel,0
    mov es:[di].he_write_wait_sel,0
    mov es:[di].he_exc_wait_sel,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET create_c_handle
    mov edi,OFFSET create_c_handle_name
    xor cl,cl
    mov ax,create_c_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET clone_c_handle
    mov edi,OFFSET clone_c_handle_name
    xor cl,cl
    mov ax,clone_c_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET delete_c_handle
    mov edi,OFFSET delete_c_handle_name
    xor cl,cl
    mov ax,delete_c_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_c_handle
    mov edi,OFFSET allocate_c_handle_name
    xor cl,cl
    mov ax,allocate_c_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET ref_c_handle
    mov edi,OFFSET ref_c_handle_name
    xor cl,cl
    mov ax,ref_c_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_c_proc_handle
    mov edi,OFFSET allocate_c_proc_handle_name
    xor cl,cl
    mov ax,allocate_c_proc_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET c_handle_to_file_sel
    mov edi,OFFSET c_handle_to_file_sel_name
    xor cl,cl
    mov ax,c_handle_to_file_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET signal_read_handle
    mov edi,OFFSET signal_read_handle_name
    xor cl,cl
    mov ax,signal_read_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET signal_write_handle
    mov edi,OFFSET signal_write_handle_name
    xor cl,cl
    mov ax,signal_write_handle_nr
    RegisterOsGate
;
    mov ebx,OFFSET open_handle16
    mov esi,OFFSET open_handle32
    mov edi,OFFSET open_handle_name
    mov dx,virt_es_in
    mov ax,open_handle_nr
    RegisterUserGate
;
    mov esi,OFFSET close_handle
    mov edi,OFFSET close_handle_name
    xor cl,cl
    mov ax,close_handle_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET read_handle16
    mov esi,OFFSET read_handle32
    mov edi,OFFSET read_handle_name
    mov dx,virt_es_in
    mov ax,read_handle_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_handle16
    mov esi,OFFSET write_handle32
    mov edi,OFFSET write_handle_name
    mov dx,virt_es_in
    mov ax,write_handle_nr
    RegisterUserGate
;
    mov esi,OFFSET dup_handle
    mov edi,OFFSET dup_handle_name
    xor cl,cl
    mov ax,dup_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET dup2_handle
    mov edi,OFFSET dup2_handle_name
    xor cl,cl
    mov ax,dup2_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_size
    mov edi,OFFSET get_handle_size_name
    xor cl,cl
    mov ax,get_handle_size_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_handle_size
    mov edi,OFFSET set_handle_size_name
    xor cl,cl
    mov ax,set_handle_size_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_mode
    mov edi,OFFSET get_handle_mode_name
    xor cl,cl
    mov ax,get_handle_mode_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_handle_mode
    mov edi,OFFSET set_handle_mode_name
    xor cl,cl
    mov ax,set_handle_mode_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_pos
    mov edi,OFFSET get_handle_pos_name
    xor cl,cl
    mov ax,get_handle_pos_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_handle_pos
    mov edi,OFFSET set_handle_pos_name
    xor cl,cl
    mov ax,set_handle_pos_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET eof_handle
    mov edi,OFFSET eof_handle_name
    xor cl,cl
    mov ax,eof_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_handle_device
    mov edi,OFFSET is_handle_device_name
    xor cl,cl
    mov ax,is_handle_device_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_time
    mov edi,OFFSET get_handle_time_name
    xor cl,cl
    mov ax,get_handle_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_handle_time
    mov edi,OFFSET set_handle_time_name
    xor cl,cl
    mov ax,set_handle_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_ipv4_socket
    mov edi,OFFSET is_ipv4_socket_name
    xor cl,cl
    mov ax,is_ipv4_socket_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET connect_ipv4_socket
    mov edi,OFFSET connect_ipv4_socket_name
    xor cl,cl
    mov ax,connect_ipv4_socket_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_handle_read
    mov edi,OFFSET add_wait_for_handle_read_name
    xor cl,cl
    mov ax,add_wait_for_handle_read_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_handle_write
    mov edi,OFFSET add_wait_for_handle_write_name
    xor cl,cl
    mov ax,add_wait_for_handle_write_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_handle_exception
    mov edi,OFFSET add_wait_for_handle_exception_name
    xor cl,cl
    mov ax,add_wait_for_handle_exception_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_read_buf_count
    mov edi,OFFSET get_handle_read_buf_count_name
    xor cl,cl
    mov ax,get_handle_read_buf_count_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_write_buf_space
    mov edi,OFFSET get_handle_write_buf_space_name
    xor cl,cl
    mov ax,get_handle_write_buf_space_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET has_handle_exception
    mov edi,OFFSET has_handle_exception_name
    xor cl,cl
    mov ax,has_handle_exception_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_tcp_socket
    mov edi,OFFSET create_tcp_socket_name
    xor dx,dx
    mov ax,create_tcp_socket_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_udp_socket
    mov edi,OFFSET create_udp_socket_name
    xor dx,dx
    mov ax,create_udp_socket_nr
    RegisterBimodalUserGate
;
    popad
    pop es
    pop ds
    ret
init_chandle     ENDP

code    ENDS

    END
