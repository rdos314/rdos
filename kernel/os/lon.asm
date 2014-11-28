;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2002, Leif Ekblad
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
; LON.ASM
; Lonworks (shortstack) module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE protseg.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE system.inc
INCLUDE ..\handle.inc
include ..\wait.inc
INCLUDE lon.inc

MAX_MODULES = 32

lon_handle_seg  STRUC

lon_handle_base  handle_header <>

lon_handle_sel   DW ?

lon_handle_seg  ENDS

lon_wait_header STRUC

lon_obj          wait_obj_header <>
lon_sel          DW ?

lon_wait_header ENDS

data    SEGMENT byte public 'DATA'

lon_module_count    DW ?
lon_module_arr      DW MAX_MODULES DUP(?)

data    ENDS

code    SEGMENT byte public use16 'CODE'
    
    .386

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendLonModuleMsg
;
;       description:    Send message to lon module
;
;       PARAMETERS:     BX              Lon handle
;                       ES:(E)DI        Buffer
;                       (E)CX           Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_lon_module_msg_name DB 'Send Lon Module Msg',0

send_lon_module_msg16       Proc far
    push ds
    push eax
    push ebx
    push edi
;
    mov ax,LON_HANDLE
    DerefHandle
    jc send_lon_msg_done16
;
    movzx ecx,cx
    movzx edi,di
    mov ds,[ebx].lon_handle_sel
    mov eax,ds:lon_send_proc
    or eax,eax
    clc
    jz send_lon_msg_done16
;       
    call ds:lon_send_proc

send_lon_msg_done16:
    pop edi
    pop ebx
    pop eax
    pop ds
    retf32
send_lon_module_msg16       Endp

send_lon_module_msg32       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,LON_HANDLE
    DerefHandle
    jc send_lon_done32
;
    mov ds,[ebx].lon_handle_sel
    mov eax,ds:lon_send_proc
    or eax,eax
    clc
    jz send_lon_done32
;       
    call ds:lon_send_proc

send_lon_done32:
    pop ebx
    pop eax
    pop ds
    retf32
send_lon_module_msg32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HasLonModuleMsg
;
;       description:    Check if message is available
;
;       PARAMETERS:     BX              Lon handle
;
;       RETURNS:        CY              No msg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_lon_module_msg_name DB 'Has Lon Module Msg?',0

has_lon_module_msg       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,LON_HANDLE
    DerefHandle
    jc has_lon_msg_done
;
    mov ds,[ebx].lon_handle_sel
    mov eax,ds:lon_has_msg_proc
    or eax,eax
    clc
    jz has_lon_msg_done
;       
    call ds:lon_has_msg_proc

has_lon_msg_done:
    pop ebx
    pop eax
    pop ds
    retf32
has_lon_module_msg       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReceiveLonModuleMsg
;
;       description:    Receive message from lon module
;
;       PARAMETERS:     BX              Lon handle
;                       ES:(E)DI        Buffer
;                       (E)CX           Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

receive_lon_module_msg_name DB 'Receive Lon Module Msg',0

receive_lon_module_msg16       Proc far
    push ds
    push eax
    push ebx
    push edi
;
    mov ax,LON_HANDLE
    DerefHandle
    jc rec_lon_msg_done16
;
    movzx ecx,cx
    movzx edi,di
    mov ds,[ebx].lon_handle_sel
    mov eax,ds:lon_receive_proc
    or eax,eax
    clc
    jz rec_lon_msg_done16
;       
    call ds:lon_receive_proc

rec_lon_msg_done16:
    pop edi
    pop ebx
    pop eax
    pop ds
    retf32
receive_lon_module_msg16       Endp

receive_lon_module_msg32       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,LON_HANDLE
    DerefHandle
    jc rec_lon_done32
;
    mov ds,[ebx].lon_handle_sel
    mov eax,ds:lon_receive_proc
    or eax,eax
    clc
    jz rec_lon_done32
;       
    call ds:lon_receive_proc

rec_lon_done32:
    pop ebx
    pop eax
    pop ds
    retf32
receive_lon_module_msg32       Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForLon
;
;           DESCRIPTION:    Start a wait for lon msg
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_lon PROC far
    push ds
    push ax
    push bx
;
    mov ds,es:lon_sel
    mov ds:lon_avail_obj,es
;
    call ds:lon_has_msg_proc
    jc start_wait_for_done
;
    mov ds:lon_avail_obj,0
    SignalWait

start_wait_for_done:
    pop bx
    pop ax
    pop ds
    ret
start_wait_for_lon Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForLon
;
;           DESCRIPTION:    Stop a wait for lon
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_lon  PROC far
    push ds
;
    mov ds,es:lon_sel
    mov ds:lon_avail_obj,0
;
    pop ds
    ret
stop_wait_for_lon Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsLonIdle
;
;           DESCRIPTION:    Check if lon is idle
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_lon_idle    PROC far
    push ds
    push ax
    push bx
;
    mov ds,es:lon_sel
    call ds:lon_has_msg_proc
    cmc
;    
    pop bx
    pop ax
    pop ds
    ret
is_lon_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearLon
;
;           DESCRIPTION:    Clear lon
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_lon  PROC far
    ret
clear_lon Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForLonModule
;
;           DESCRIPTION:    Add a wait for lon msg
;
;           PARAMETERS:         BX      Wait handle
;               ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_lon_module_name      DB 'Add Wait For Lon Module',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_lon,      SEG code
aw1 DD OFFSET stop_wait_for_lon,       SEG code
aw2 DD OFFSET clear_lon,               SEG code
aw3 DD OFFSET is_lon_idle,             SEG code

add_wait_for_lon_module   PROC far
    push es
    push ax
    push edi
;
    push ebx
    mov bx,ax
    mov ax,LON_HANDLE
    DerefHandle
    jc add_wait_pop
;    
    mov ax,ds:[ebx].lon_handle_sel
    pop ebx
;    
    push ax
    mov ax,cs
    mov es,ax
    mov edi,OFFSET add_wait_tab
    mov ax,SIZE lon_wait_header - SIZE wait_obj_header
    AddWait
    pop ax
    jc add_wait_done
;
    mov es:lon_sel,ax
    jmp add_wait_done

add_wait_pop:
    pop ebx

add_wait_done:
    pop edi
    pop ax
    pop es
    ret
add_wait_for_lon_module   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetLonModules
;
;       description:    Get number of lon modules
;
;       RETURNS:        AL      Number of modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_lon_modules_name DB 'Get Lon Modules',0

get_lon_modules        Proc far
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:lon_module_count
    pop ds
    retf32
get_lon_modules    Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenLonModule
;
;       description:    Open lon module
;
;       PARAMETERS:     AL              Module #
;
;       RETURNS:        BX              Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_lon_module_name DB 'Open Lon Module',0

open_lon_module       Proc far
    push ds
    push es
    push ax
    push cx
    push dx
;
    mov dx,SEG data
    mov ds,dx
    movzx dx,al
    cmp dx,ds:lon_module_count
    jae open_lon_fail
;    
    mov bx,dx
    add bx,bx
    mov es,ds:[bx].lon_module_arr
;
    mov ax,LON_HANDLE
    mov cx,SIZE lon_handle_seg
    AllocateHandle
    mov [ebx].lon_handle_sel,es
    mov [ebx].hh_sign,LON_HANDLE
    mov bx,[ebx].hh_handle
;
    mov ax,es
    mov ds,ax
    call fword ptr ds:lon_init_proc    
    clc
    jmp open_lon_done
    
open_lon_fail:
    xor bx,bx
    stc

open_lon_done:
    pop dx
    pop cx
    pop ax
    pop es
    pop ds
    retf32 
open_lon_module       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CloseLonModule
;
;       description:    Close lon module
;
;       PARAMETERS:     BX              Lon handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_lon_module_name DB 'Close Lon Module',0

close_lon_module       Proc far
    push ds
    push ax
    push dx
;
    mov ax,LON_HANDLE
    DerefHandle
    jc close_lon_done
;
    FreeHandle

close_lon_done:
    pop dx
    pop ax
    pop ds
    retf32
close_lon_module       Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddLonModule
;
;           DESCRIPTION:    Add lon module
;
;           PARAMETERS:     DS      Lon device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_lon_module_name    DB 'Add Lon Module',0

add_lon_module     PROC far
    push ds
    push bx
    push dx
;
    mov ds:lon_avail_obj,0
;
    mov dx,ds
    mov bx,SEG data
    mov ds,bx
;
    mov bx,ds:lon_module_count
    add bx,bx
    mov ds:[bx].lon_module_arr,dx
    inc ds:lon_module_count
;
    pop dx
    pop bx
    pop ds    
    retf32
add_lon_module     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_lon_handle
;
;           DESCRIPTION:    BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_lon_handle       Proc far
    push ds
    push ax
    push ebx
;
    mov ax,LON_HANDLE
    DerefHandle
    jc delete_lon_handle_done
;
    FreeHandle

delete_lon_handle_done:
    pop ebx
    pop ax
    pop ds
    retf32
delete_lon_handle       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
;    
    mov ax,LON_HANDLE
    mov edi,OFFSET delete_lon_handle
    RegisterHandle
;
    mov esi,OFFSET add_lon_module
    mov edi,OFFSET add_lon_module_name
    xor cl,cl
    mov ax,add_lon_module_nr
    RegisterOsGate
;
    mov esi,OFFSET get_lon_modules
    mov edi,OFFSET get_lon_modules_name
    xor dx,dx
    mov ax,get_lon_modules_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET open_lon_module
    mov edi,OFFSET open_lon_module_name
    xor dx,dx
    mov ax,open_lon_module_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_lon_module
    mov edi,OFFSET close_lon_module_name
    xor dx,dx
    mov ax,close_lon_module_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_lon_module
    mov edi,OFFSET add_wait_for_lon_module_name
    xor dx,dx
    mov ax,add_wait_for_lon_module_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET send_lon_module_msg16
    mov esi,OFFSET send_lon_module_msg32
    mov edi,OFFSET send_lon_module_msg_name
    mov dx,virt_es_in
    mov ax,send_lon_module_msg_nr
    RegisterUserGate
;
    mov esi,OFFSET has_lon_module_msg
    mov edi,OFFSET has_lon_module_msg_name
    xor dx,dx
    mov ax,has_lon_module_msg_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET receive_lon_module_msg16
    mov esi,OFFSET receive_lon_module_msg32
    mov edi,OFFSET receive_lon_module_msg_name
    mov dx,virt_es_in
    mov ax,receive_lon_module_msg_nr
    RegisterUserGate
;
    mov ax,SEG data
    mov ds,ax
    mov ds:lon_module_count,0    
    ret
init    ENDP

code    ENDS

    END init
