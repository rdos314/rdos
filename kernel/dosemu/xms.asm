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
; XMS.ASM
; XMS emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\os\system.inc
INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\user.def
INCLUDE ..\os.inc
INCLUDE ..\user.inc
INCLUDE ..\handle.inc

xms_handle_seg  STRUC

xms_handle_base     handle_header <>

block_base              DD ?
block_size              DD ?
lock_count              DB ?

xms_handle_seg  ENDS

xms_local_seg   STRUC

xms_hma_state   DB ?
xms_free_mem    DD ?

xms_local_seg   ENDS

data    SEGMENT byte public 'DATA'

xms_handler_seg DW ?

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_XMS_PROCESS
;
;           DESCRIPTION:    Init per process memory
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_xms_process    PROC far
    mov ax,xms_local_sel
    mov ds,ax
    mov es,ax
    mov ds:xms_hma_state,1
    GetFreePhysical
    sub eax,100000h
    mov ds:xms_free_mem,eax
    retf32
init_xms_process    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete_handle
;
;           DESCRIPTION:    Delete handle (called from handle module)
;
;           PARAMETERS:         BX              XMS HANDLE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push ebx
    push si
;
    mov ax,XMS_HANDLE
    DerefHandle
    jc delete_handle_done
;
    mov ecx,ds:[ebx].block_size
    mov edx,ds:[ebx].block_base
    or ecx,ecx
    jz delete_handle_done
;
    FreeLinear

delete_handle_done:
    pop si
    pop ebx
    pop ds
    retf32
delete_handle   Endp

xms_version     PROC near
    mov ax,300h
    mov bx,307h
    mov dx,1
    ret
xms_version     ENDP

xms_req_hma     PROC near
    mov ax,xms_local_sel
    mov ds,ax
    xor ax,ax
    mov al,ds:xms_hma_state
    cmp al,1
    je xms_req_hma_ok
    mov bl,91h
    ret
xms_req_hma_ok:
    mov ds:xms_hma_state,0
    ret
xms_req_hma     ENDP

xms_rel_hma     PROC near
    mov ax,xms_local_sel
    mov ds,ax
    mov ax,1
    mov ds:xms_hma_state,al 
    ret
xms_rel_hma     ENDP

xms_ena_a20     PROC near
    mov ax,1
    ret
xms_ena_a20     ENDP

xms_dis_a20     PROC near
    mov ax,1
    ret
xms_dis_a20     ENDP

xms_query_a20   PROC near
    mov ax,1
    ret
xms_query_a20   ENDP

xms_query_size  PROC near
    push ds
    push bx
    mov bx,xms_local_sel
    mov ds,bx
    mov eax,ds:xms_free_mem
    pop bx
    pop ds
    shr eax,10
    mov dx,ax
    xor bl,bl
    ret
xms_query_size  ENDP

xms_allocate    PROC near
    push ebx
    mov bx,xms_local_sel
    mov ds,bx
    movzx eax,dx
    shl eax,10
    sub ds:xms_free_mem,eax
    jnc xms_allocate_do
;
    add ds:xms_free_mem,eax
    pop bx
    mov bl,0A0h
    xor ax,ax
    ret

xms_allocate_do:
    mov cx,SIZE xms_handle_seg
    AllocateHandle
    jnc xms_allocate_handle_ok
;
    pop ebx
    mov bl,0A1h
    xor ax,ax
    ret

xms_allocate_handle_ok:
    or eax,eax
    jz xms_allocate_zero
;
    push edx
    AllocateLocalLinear
    mov ds:[ebx].block_base,edx
    pop edx

xms_allocate_zero:
    mov ds:[ebx].block_size,eax
    mov ds:[ebx].lock_count,0
    mov ds:[ebx].hh_sign,XMS_HANDLE
    mov dx,ds:[ebx].hh_handle
    pop ebx
    mov ax,1
    ret
xms_allocate    ENDP

xms_free    PROC near
    push ebx
    mov bx,dx
    mov ax,XMS_HANDLE
    DerefHandle
    jnc xms_free_deref_ok
;
    pop ebx
    mov bl,0A2h
    xor ax,ax
    ret

xms_free_deref_ok:
    mov al,ds:[ebx].lock_count
    or al,al
    jz xms_free_lock_ok
;
    pop ebx
    mov bl,0ABh
    xor ax,ax
    ret

xms_free_lock_ok:
    push ecx
    push edx
    mov ecx,ds:[bx].block_size
    mov edx,ds:[bx].block_base
;
    or ecx,ecx
    jz xms_free_global
;
    FreeLinear

xms_free_global:
    FreeHandle
    mov bx,xms_local_sel
    mov ds,bx
    add ds:xms_free_mem,ecx
;
    pop edx
    pop ecx
    pop ebx
    mov ax,1
    ret
xms_free    ENDP

xms_move    PROC near
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    mov bx,si
    mov ecx,[bx]
    mov dx,[bx+4]
    or dx,dx    
    jnz xms_source_high
    movzx eax,word ptr [bx+8]
    shl eax,4
    movzx esi,word ptr [bx+6]
    add esi,eax
    jmp xms_dest

xms_source_high:
    push ds
    push ebx
;
    mov bx,dx
    mov ax,XMS_HANDLE
    DerefHandle
    jnc xms_source_ok
;
    pop ebx
    pop ds
    mov al,0A3h
    jmp xms_move_error

xms_source_ok:
    mov esi,ds:[ebx].block_base
    mov edx,ds:[ebx].block_size
    pop ebx
    pop ds
;
    mov al,0A4h
    sub edx,ecx
    jc xms_move_error
;
    mov al,0A7h
    sub edx,[bx+6]
    jc xms_move_error
;
    add esi,[bx+6]

xms_dest:
    mov dx,[bx+10]
    or dx,dx
    jnz xms_dest_high
    movzx eax,word ptr [bx+14]
    shl eax,4
    movzx edi,word ptr [bx+12]
    add edi,eax
    jmp xms_move_do

xms_dest_high:
    push ds
    push ebx
;
    mov bx,dx
    mov ax,XMS_HANDLE
    DerefHandle
    jnc xms_dest_ok
;
    pop ebx
    pop ds
    mov al,0A5h
    jmp xms_move_error

xms_dest_ok:
    mov edi,ds:[ebx].block_base
    mov edx,ds:[ebx].block_size
    pop ebx
    pop ds
;
    mov al,0A6h
    sub edx,ecx
    jc xms_move_error
;
    mov al,0A7h
    sub edx,[bx+12]
    jc xms_move_error
;
    add edi,[bx+12]

xms_move_do:
    push ds
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
    mov dx,cx
    shr ecx,2
    or ecx,ecx
    jz xms_move_done
;
    rep movs dword ptr es:[edi],ds:[esi]

xms_move_done:
    mov cx,dx
    and cx,3
    jz xms_move_ok

xms_small_move_loop:
    mov al,[esi]
    mov es:[edi],al
    inc esi
    inc edi
    loop xms_small_move_loop

xms_move_ok:
    pop ds
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    mov ax,1
    ret

xms_move_error:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    mov bl,al
    mov ax,0
    ret
xms_move    ENDP

xms_lock    PROC near
    push ebx
    mov bx,dx
    mov ax,XMS_HANDLE
    DerefHandle
    jnc xms_lock_deref_ok
;
    pop ebx
    mov bl,0A2h
    xor ax,ax
    ret

xms_lock_deref_ok:
    movzx ax,ds:[ebx].lock_count
    add al,1
    jnz xms_lock_do
;
    pop ebx
    mov bl,0ACh
    ret

xms_lock_do:
    mov ds:[ebx].lock_count,al
    mov dx,word ptr ds:[ebx].block_base+2
    mov bx,word ptr ds:[ebx].block_base
    pop eax
    mov ax,1
    ret
xms_lock    ENDP

xms_unlock      PROC near
    push ebx
    mov bx,dx
    mov ax,XMS_HANDLE
    DerefHandle
    jnc xms_unlock_deref_ok
;
    pop ebx
    mov bl,0A2h
    xor ax,ax
    ret

xms_unlock_deref_ok:
    movzx ax,ds:[ebx].lock_count
    or al,al
    jnz xms_unlock_do
;
    pop ebx
    mov bl,0AAh
    ret

xms_unlock_do:
    dec al
    mov ds:[ebx].lock_count,al
    pop ebx
    mov ax,1
    ret
xms_unlock      ENDP

xms_info    PROC near
    push ebx
    mov bx,dx
    mov ax,XMS_HANDLE
    DerefHandle
    jnc xms_info_deref_ok
;
    pop ebx
    mov bl,0A2h
    xor ax,ax
    ret

xms_info_deref_ok:
    mov edx,ds:[ebx].block_size
    mov bh,ds:[ebx].lock_count
    shr edx,10
    mov bl,10
    pop eax
    mov ax,1
    ret
xms_info    ENDP

xms_reallocate  PROC near
    xor ax,ax
    mov bl,0A2h
    ret
xms_reallocate  ENDP

xms_req_upper   PROC near
    xor ax,ax
    mov bl,0B1h
    ret
xms_req_upper   ENDP

xms_rel_upper   PROC near
    xor ax,ax
    mov bl,0B2h
    ret
xms_rel_upper   ENDP

xms_invalid     PROC near
    xor ax,ax
    mov bl,80h
    ret
xms_invalid     ENDP

xms_call_tab:
xms0    DW OFFSET xms_version
xms1    DW OFFSET xms_req_hma
xms2    DW OFFSET xms_rel_hma
xms3    DW OFFSET xms_ena_a20
xms4    DW OFFSET xms_dis_a20
xms5    DW OFFSET xms_ena_a20
xms6    DW OFFSET xms_dis_a20
xms7    DW OFFSET xms_query_a20
xms8    DW OFFSET xms_query_size
xms9    DW OFFSET xms_allocate
xmsA    DW OFFSET xms_free
xmsB    DW OFFSET xms_move
xmsC    DW OFFSET xms_lock
xmsD    DW OFFSET xms_unlock
xmsE    DW OFFSET xms_info
xmsF    DW OFFSET xms_reallocate
xms10   DW OFFSET xms_req_upper
xms11   DW OFFSET xms_rel_upper
xmsend  DW OFFSET xms_invalid

xms_name    DB 'Xms Request',0

xms_handler     PROC far
    mov al,ah
    xor ah,ah
    cmp ah,11h
    jbe xms_impl
    mov ah,12h
xms_impl:
    push si
    add ax,ax
    mov si,ax
    mov ax,word ptr [si].xms_call_tab
    pop si
    push OFFSET xms_handle_ret
    push ax
    retn
xms_handle_ret:
    ret
xms_handler     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           QUERY_XMS
;
;           DESCRIPTION:    Query XMS info
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

query_xms_name  DB 'Query Xms',0

query_xms       PROC far
    or al,al
    jne not_xms_inst
    mov al,80h
    retf32
not_xms_inst:
    cmp al,10h
    jne not_xms_entry
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:xms_handler_seg
    mov [bp].vm_es,bx
    mov bx,OFFSET xmm_handler - OFFSET xmm_device_begin
    retf32
not_xms_entry:
    retf32
query_xms       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init XMS
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

xmm_device_begin:
    dd -1
    dw 08000h
    dw OFFSET xmm_strat - OFFSET xmm_device_begin
    dw OFFSET xmm_int - OFFSET xmm_device_begin
    db 'XMSXXXX0'
xmm_handler:
    jmp xmm_handle
    nop
    nop
    nop
xmm_handle:
    XmsHandler
    retf
xmm_strat:
    retf
xmm_int:
    retf
xmm_device_end:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init XMS
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_xms
    
init_xms    PROC near
    mov ax,cs
    mov ds,ax
    mov bx,OFFSET xmm_device_begin
    mov cx,OFFSET xmm_device_end - OFFSET xmm_device_begin
    RegisterDosDevice
;
    mov ax,SEG data
    mov ds,ax
    mov ds:xms_handler_seg,dx
;
    mov eax,SIZE xms_local_seg
    mov bx,xms_local_sel
    AllocateFixedProcessMem
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET init_xms_process
    HookCreateProcess
;
    mov esi,OFFSET xms_handler
    mov edi,OFFSET xms_name
    mov ax,xms_handler_nr
    mov dx,virt_ds_in
    RegisterUserGate
;
    mov esi,OFFSET query_xms
    mov edi,OFFSET query_xms_name
    xor cl,cl
    mov ax,query_xms_nr
    RegisterOsGate
;
    mov edi,OFFSET delete_handle
    mov ax,XMS_HANDLE
    RegisterHandle
    ret
init_xms    ENDP

code    ENDS

    END
