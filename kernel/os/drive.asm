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
; DRIVE.ASM
; Basic physical drive support module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE int.def
INCLUDE system.inc
INCLUDE ..\drive.inc

MAX_DRIVES	EQU 'Z' - 'A' + 1

DRIVE_WAIT_NUM = 32

POLL_TIMEOUT = 1192 * 100
MIN_TIMEOUT = 1192 * 250

part_struc      STRUC

part_status             DB ?
part_start_head         DB ?
part_start_cyl_sector   DW ?
part_type               DB ?
part_end_head           DB ?
part_end_cyl_sector     DW ?
part_start_sector       DD ?
part_sectors            DD ?

part_struc      ENDS

gpt_part_struc  STRUC

gpt_sign                DB 8 DUP(?)
gpt_rev                 DB 4 DUP(?)
gpt_header_size         DD ?
gpt_crc32               DD ?
gpt_resv                DD ?
gpt_curr_lba            DD ?,?
gpt_other_lba           DD ?,?
gpt_first_lba           DD ?,?
gpt_last_lba            DD ?,?
gpt_guid                DB 16 DUP(?)
gpt_entry_lba           DD ?,?
gpt_entry_count         DD ?
gpt_entry_size          DD ?
gpt_entry_crc32         DD ?

gpt_part_struc  ENDS

gpt_entry_struc STRUC

gpe_part_guid           DB 16 DUP(?)
gpe_unique_guid         DB 16 DUP(?)
gpe_first_lba           DD ?,?
gpe_last_lba            DD ?,?
gpe_attrib              DD ?,?
gpe_name                DB 36 DUP(?)

gpt_entry_struc ENDS

drive_wait_struc    STRUC

dws_link            DW ?
dws_thread              DW ?

drive_wait_struc    ENDS

DISC_FLAG_STOPPED       = 1
DISC_FLAG_USE32         = 2
DISC_FLAG_INSTALLED     = 4
DISC_FLAG_DYNAMIC       = 8

disc_def_struc      STRUC

disc_nr                 DB ?
disc_flags              DB ?
disc_total_sectors      DD ?,?
disc_units              DD ?
disc_bytes_per_sector   DW ?
disc_sectors_per_unit   DW ?
disc_sectors_per_cyl    DW ?
disc_heads              DW ?
disc_cached_sectors     DD ?
disc_cache_limit        DD ?
disc_thread             DW ?
disc_timer_id           DW ?
disc_data_list          DD ?
disc_handle_list        DD ?
disc_readahead          DD ?
disc_free               DD ?
disc_section            section_typ <>
disc_spinlock           spinlock_typ <>
disc_awrite_list        DD ?
disc_awrite_timer       DW ?
disc_awrite_count       DW ?
disc_awrite_timeout     DD ?,?
disc_seq_list           DW ?
disc_handle             DW ?
disc_pend_bitmap        DW ?
disc_curr_unit          DD ?
disc_curr_sector        DW ?
disc_start_unit         DD ?
disc_start_sector       DW ?
disc_pend_low           DD ?
disc_pend_high          DD ?
disc_io_count           DD ?

disc_change_proc        DD ?,?
disc_demand_mount_proc  DD ?,?
disc_fs_name            DB 10 DUP(?)
disc_vendor_str         DB 256 DUP(?)
disc_unit_arr           DD ?

disc_def_struc      ENDS

disc_unit_struc STRUC

disc_sectors            DW ?
disc_sector_pend_low    DW ?
disc_sector_pend_high   DW ?
disc_sector_pend_ptr    DD ?
disc_sector_arr         DD ?

disc_unit_struc ENDS

drive_def_struc STRUC

drive_disc                  DW ?
drive_start_sector          DD ?
drive_sectors           DD ?

drive_def_struc ENDS

disc_seq_struc  STRUC

dss_prev            DW ?
dss_next            DW ?
dss_buf_sel             DW ?
dss_insert_index    DW ?
dss_perform_index       DW ?

dss_arr             DD ?

disc_seq_struc  ENDS

boot_media_struc    STRUC

boot_bytes_per_sector       DW 512
boot_resv1                      DB 0
boot_mapping_sectors        DW 1
boot_resv3                      DB 0
boot_resv4                      DW 0
boot_small_sectors              DW 0
boot_media                      DB 0F8h
boot_resv6                      DW 0
boot_sectors_per_cyl        DW 1
boot_heads                      DW 1
boot_hidden_sectors             DD 1
boot_sectors                DD 0
boot_drive_nr               DB 0,0
boot_signature              DB 0 
boot_serial                     DD 0
boot_volume                     DB 11 DUP(0)
boot_fs                     DB 8 DUP(0)

boot_media_struc        ENDS

boot_struc      STRUC

boot_jmp                    DB ?,?,?
boot_name                       DB 8 DUP(?)
boot_param          boot_media_struc <>

boot_struc          ENDS

data    SEGMENT byte public 'DATA'

disc_def_arr            DW MAX_DRIVES DUP(?)
drive_def_arr           DW MAX_DRIVES DUP(?)
drive_wait_arr          DB 4*DRIVE_WAIT_NUM DUP(?)
drive_wait_free         DW ?
drive_wait_count        DW ?
disc_handler_section    section_typ <>
disc_handlers           DW ?
disc_handler_thread     DW ?

init_done               DW ?
init_timeout            DD ?,?

data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use16 'CODE'

    assume cs:code,ds:data

    extrn init_ramdrive:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;           NAME:           Boot sector. DO NOT MOVE THIS CODE!!!
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    db 0EBh
    db SIZE boot_struc - 2      ; jmp StartBoot
    db 90h
    db 'Rdos    '

BootMedia       boot_media_struc    <>

StartBoot:
    db 0EAh
    dw OFFSET JmpBootCode
    dw 07C0h
JmpBootCode:
    cli
    mov bx,800h
    mov ss,bx
    mov sp,100h
    sti
    mov bx,70h
    mov es,bx
    xor bx,bx
    mov cx,8
    xor dx,dx
    mov ax,1
LoadBootNext:
    push cx
    mov cx,3
LoadBootRetry:
    call ReadSector
    jnc BootSectorOk
    push ax
    mov ax,0
    int 13h
    pop ax
    loop LoadBootRetry      
    stc
BootSectorOk:
    pop cx
    jc BootFail
    add ax,1
    adc dx,0
    add bx,512
    loop LoadBootNext
;
    mov ax,cs
    mov es,ax
    db 0EAh

    public BootLoadOffset

BootLoadOffset:

    dw 0
    dw 70h

BootFail:
    mov si,OFFSET DiskError
    call BootWriteAsciiz
BootStop:
    jmp BootStop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           BootWriteAsciiz
;
;           DESCRIPTION:    Write a message
;
;           PARAMETERS:         CS:SI   Message to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BootWriteAsciiz Proc near
    lods byte ptr cs:[si]
    or al,al
    jz WriteAsciizDone
    mov ah,0Eh
    mov bx,7
    int 10h
    jmp BootWriteAsciiz
WriteAsciizDone:
    ret
BootWriteAsciiz Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadSector
;
;           DESCRIPTION:    Read a sector
;
;           PARAMETERS:         DX:AX   Sector #
;                           ES:BX   Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector      Proc near
    push ax
    push cx
    push dx
    push bx
    div cs:BootMedia.boot_sectors_per_cyl
    inc dl
    mov bl,dl
    xor dx,dx
    div cs:BootMedia.boot_heads
    mov bh,dl
    mov dx,ax
    mov ax,201h
    mov cl,6
    shl dh,cl
    or dh,bl
    mov cx,dx
    xchg ch,cl
    mov dl,cs:BootMedia.boot_drive_nr
    mov dh,bh
    pop bx
    int 13h
    pop dx
    pop cx
    pop ax
    ret
ReadSector      Endp

DiskError:
        db 'Disk error',0Dh,0Ah,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Boot sector ends here
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckAsyncWrite Proc near
    xor cx,cx
    mov edi,ds:disc_awrite_list
    mov eax,edi
    or edi,edi
    jz cawdone

cawloop:
    test es:[edi].dh_flags, FLAG_ASYNC_WRITE
    jz cawfail
;
    cmp es:[edi].dh_state,STATE_DIRTY
    je cawnext

cawfail:
    int 3   
    mov al,es:[edi].dh_state
    mov ah,es:[edi].dh_flags
    jmp cawdone

cawnext:
    mov edi,es:[edi].dh_next
    cmp edi,eax
    jz cawdone
;
    loop cawloop
;
    int 3

cawdone:
    ret
CheckAsyncWrite Endp

CheckAll    Proc near
    push es
    pushad
;
    mov ax,flat_sel
    mov es,ax
    call CheckAsyncWrite
;
    popad
    pop es
    ret
CheckAll    Endp
     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckDeleted
;
;           DESCRIPTION:    Check if block is deleted
;
;           PARAMETERS:     EDI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckDeleted    Proc near
    push es
    pushad
;    
    mov ax,flat_sel
    mov es,ax
;
    xor cx,cx
    mov esi,ds:disc_handle_list
    mov ebp,esi
    or esi,esi
    jz cddone

cdloop:
    cmp esi,edi
    je cdfound
;
    mov esi,es:[esi].dh_next
    or esi,esi
    jz cddone
;
    loop cdloop

cdfound:
    int 3

cddone:
    popad
    pop es
    ret
CheckDeleted    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckBuffered
;
;           DESCRIPTION:    Make sure sector is buffered
;
;           PARAMETERS:         DS          Disc selector
;                           ES          Flat_sel
;                       EDI         DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckBuffered   PROC near
    push es
    pushad
;    
    mov ax,flat_sel
    mov es,ax
;    
    mov esi,es:[edi].dh_unit
    mov eax,ds:[4*esi].disc_unit_arr
    or eax,eax
    jz cbFail
;
    movzx esi,es:[edi].dh_sector
    mov eax,es:[4*esi+eax].disc_sector_arr
;
    or eax,eax
    jnz cbDone
    
cbFail:
    int 3

cbDone:
    popad
    pop es
    ret
CheckBuffered   ENDP


    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckDriveWait
;
;           DESCRIPTION:    Check consistency of drive-wait list
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckDriveWait  Proc near
    push ds
    pushad
;
    mov ax,SEG data
    mov ds,ax
    xor cx,cx
    mov bx,ds:drive_wait_free

cdwLoop:
    or bx,bx
    jz cdwCheck
;
    mov bx,[bx]
    inc cx
    jmp cdwLoop 

cdwCheck:
    cmp cx,ds:drive_wait_count
    je cdwSizeOk
;
    int 3

cdwSizeOk:  
    or cx,cx
    jnz cdwNotEmpty
;
    int 3


cdwNotEmpty:    
    popad
    pop ds
    ret
CheckDriveWait  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Fixup_data
;
;           DESCRIPTION:    Fixup data for 32-bit only discs
;
;           PARAMETERS:     DS          Disc selector
;                           ESI         Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fixup_data   PROC near
    test ds:disc_flags,DISC_FLAG_USE32
    jz fxdDone
;
    push eax
    push ebx
    push edx
;    
    mov edx,esi
    GetPageEntry
    test al,1
    jz fxdAlloc
;
    or ebx,ebx
    jz fxdInRange
;
    int 3

fxdAlloc:            
    AllocatePhysical32
    mov al,13h
    SetPageEntry

fxdInRange:
    pop edx    
    pop ebx
    pop eax

fxdDone:    
    ret
fixup_data   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ALLOCATE_DATA
;
;           DESCRIPTION:    Allocate data
;
;           PARAMETERS:         DS          Disc selector
;
;           RETURNS:        EDX         Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_data   PROC near
    push eax
    push ecx
;
    mov edx,ds:disc_data_list
    or edx,edx
    jnz allocate_data_done
;
    mov eax,1000h
    AllocateBigLinear
    test ds:disc_flags,DISC_FLAG_USE32
    jz allocate_data_phys_ok
;
    push ebx
    AllocatePhysical32
    mov al,13h
    SetPageEntry
    pop ebx

allocate_data_phys_ok:    
    movzx ecx,ds:disc_bytes_per_sector
    mov ds:disc_data_list,edx
allocate_init_data_loop:
    mov eax,edx
    add eax,ecx
    mov es:[edx],eax
    mov edx,eax
    test dx,0FFFh
    jnz allocate_init_data_loop
;
    sub edx,ecx
    mov dword ptr es:[edx],0
    mov edx,ds:disc_data_list

allocate_data_done:
    mov eax,es:[edx]
    mov ds:disc_data_list,eax
;
    pop ecx
    pop eax
    ret
allocate_data   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FREE_DATA
;
;           DESCRIPTION:    Free data
;
;           PARAMETERS:         DS          Disc selector
;                           EDX         Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_data       PROC near
    push eax
    mov eax,ds:disc_data_list
    mov es:[edx],eax
    mov ds:disc_data_list,edx
    pop eax
    ret
free_data       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FREE_HANDLE
;
;           DESCRIPTION:    Free handle
;
;           PARAMETERS:         DS          Disc selector
;                           EDI         Disc buf handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_handle     PROC near

ifdef DEBUG
    call CheckDeleted
endif
    
    push eax
    test es:[edi].dh_flags, FLAG_EXT_DATA
    jnz free_handle_do
;
    push edx
    mov edx,es:[edi].dh_data
    call free_data
    pop edx

free_handle_do:
    mov es:[edi].dh_flags,0
    mov eax,ds:disc_handle_list
    mov es:[edi],eax
    mov ds:disc_handle_list,edi
    dec ds:disc_cached_sectors
    pop eax

ifdef DEBUG
    call CheckAll
endif
    ret
free_handle     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           swap_block
;
;           DESCRIPTION:    Free physical memory, disc block
;
;           PARAMETERS:         ES      Flat sel
;               EDX     Disc block
;               EDI     Unit block entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

swap_block   Proc near
    inc ebp
    mov edi,edx
    test es:[edi].dh_flags,FLAG_EXT_DATA OR BUSY_FLAGS
    jnz swap_block_done
;       
    mov al,es:[edi].dh_lock_count
    or al,al
    jnz swap_block_done
;
    mov al,es:[edi].dh_usage
    or al,al
    jnz swap_block_upd_usage
;
    dec ebp
    call remove_buf
    call free_handle
    jmp swap_block_done

swap_block_upd_usage:
    dec al
    mov es:[edi].dh_usage,al    

swap_block_done:
    ret
swap_block   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           swap_unit
;
;           DESCRIPTION:    Free disc buffers on a disc unit
;
;           PARAMETERS:         DS      Disc sel
;               EDX     Unit block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

swap_unit   Proc near
    mov ax,flat_sel
    mov es,ax
    mov edi,edx
    movzx ecx,ds:disc_sectors_per_unit
    mov si,es:[edx].disc_sectors
    lea edi,[edi].disc_sector_arr

swap_sector_loop:
    or ecx,ecx
    jz swap_unit_done
;    
    xor eax,eax
    repz scas dword ptr es:[edi]
    mov eax,es:[edi-4]
    or eax,eax
    jz swap_sector_loop
;
    push ecx
    push edx
    push si
    push edi
    mov edx,eax
    call swap_block
    pop edi
    pop si
    pop edx
    pop ecx
    sub si,1
    jnz swap_sector_loop

swap_unit_done:
    ret
swap_unit   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           swap_disc
;
;           DESCRIPTION:    Free disc buffers on a disc
;
;           PARAMETERS:         DS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

swap_disc   Proc near
    push ds
    push es
    pushad
;    
    xor ebp,ebp
    mov ax,ds
    mov es,ax
    mov edi,OFFSET disc_unit_arr
    mov ecx,ds:disc_units

swap_unit_loop:
    or ecx,ecx
    jz swap_disc_done
;    
    xor eax,eax
    repz scas dword ptr es:[edi]
    mov edx,es:[edi-4]
    or edx,edx
    jz swap_unit_loop
;
    push es
    push ecx
    push edi
    call swap_unit
    pop edi
    pop ecx
    pop es
    jmp swap_unit_loop

swap_disc_done:
    popad
    pop es
    pop ds
    ret
swap_disc   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ALLOCATE_HANDLE
;
;           DESCRIPTION:    Allocate handle
;
;           PARAMETERS:         DS          Disc selector
;                           
;           RETURNS:        EDI         Discbuf handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_handle PROC near
    push eax
    push edx
;    
    mov eax,ds:disc_cached_sectors
    sub eax,ds:disc_io_count
    cmp eax,ds:disc_cache_limit
    jc alloc_handle_no_swap
; 
    call swap_disc
    mov eax,ds:disc_cached_sectors
    sub eax,ds:disc_io_count
    cmp eax,ds:disc_cache_limit
    jc alloc_handle_no_swap
;
    call swap_disc
    mov eax,ds:disc_cached_sectors
    sub eax,ds:disc_io_count
    cmp eax,ds:disc_cache_limit
    jc alloc_handle_no_swap
;
    shr eax,2
    inc eax
    add ds:disc_cache_limit,eax

alloc_handle_no_swap:      
    inc ds:disc_cached_sectors
    mov edi,ds:disc_handle_list
    or edi,edi
    jnz allocate_handle_done
;
    push cx
    mov eax,1000h
    AllocateBigLinear
    mov ds:disc_handle_list,edx
    pop cx

allocate_init_handle_loop:
    add edx,DISC_HANDLE_SIZE
    mov es:[edx-DISC_HANDLE_SIZE].dh_next,edx
    test dx,0FFFh
    jnz allocate_init_handle_loop
;
    mov es:[edx-DISC_HANDLE_SIZE].dh_next,0
    mov edi,ds:disc_handle_list

allocate_handle_done:
    mov eax,es:[edi].dh_next
    mov ds:disc_handle_list,eax

ifdef DEBUG
    call CheckDeleted
endif    

    pop edx
    pop eax
    ret
allocate_handle ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WAIT_PENDING
;
;           DESCRIPTION:    Wait for pending list to shrink
;
;           PARAMETERS:     DS          DiscBuf handle
;                           ES          Flat_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_pending  PROC near
    push eax

wpRetry:
    mov eax,ds:disc_io_count
    cmp eax,ds:disc_cache_limit
    jb wpOk
;
    mov ax,25
    WaitMilliSec
    jmp wpRetry

wpOk:
    pop eax
    ret
wait_pending  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INSERT_PENDING
;
;           DESCRIPTION:    Insert block into pending request list
;
;           PARAMETERS:         DS          DiscBuf handle
;                           ES          Flat_sel
;                           EDI         DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert_pending  PROC near
    push es
    push eax
    push ebx
    push edx
;
    inc ds:disc_io_count
    or es:[edi].dh_flags,FLAG_IO_PENDING
    mov ebx,es:[edi].dh_unit
    mov edx,ds:[4*ebx].disc_unit_arr
    movzx ebx,es:[edi].dh_sector
    cmp bx,es:[edx].disc_sector_pend_low
    jae inspSectorLowOk
;
    mov es:[edx].disc_sector_pend_low,bx

inspSectorLowOk:    
    cmp bx,es:[edx].disc_sector_pend_high
    jbe inspSectorHighOk
;
    mov es:[edx].disc_sector_pend_high,bx

inspSectorHighOk:
    mov edx,es:[edx].disc_sector_pend_ptr
    bts es:[edx],ebx
    jc inspDone
;
    mov edx,es:[edi].dh_unit
    cmp edx,ds:disc_pend_low
    jae inspUnitLowOk
;
    mov ds:disc_pend_low,edx

inspUnitLowOk:
    cmp edx,ds:disc_pend_high
    jbe inspUnitHighOk
;
    mov ds:disc_pend_high,edx

inspUnitHighOk:
    mov es,ds:disc_pend_bitmap
    xor ebx,ebx
    bts es:[ebx],edx
    jc inspDone
;
    mov bx,ds:disc_thread
    Signal

inspDone:
    pop edx
    pop ebx
    pop eax
    pop es
    ret
insert_pending  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INSERT_ASYNC_WRITE
;
;           DESCRIPTION:    Insert block into async write request list
;
;           PARAMETERS:         DS          DiscBuf handle
;                           ES          Flat_sel
;                           EDI         DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert_async_write      PROC near
    push eax
    push ebx

ifdef DEBUG     
    call CheckDeleted
endif
    
    test es:[edi].dh_flags, FLAG_IO_PENDING
    jnz insert_awrite_end
;
    test es:[edi].dh_flags, FLAG_ASYNC_WRITE
    jnz insert_awrite_done

insert_awrite_do:
    or es:[edi].dh_flags, FLAG_ASYNC_WRITE
;
    mov eax,ds:disc_awrite_list
    or eax,eax
    jne insert_awrite_used

insert_awrite_empty:
    mov es:[edi].dh_prev,edi
    mov es:[edi].dh_next,edi
    mov ds:disc_awrite_count,1
    jmp insert_awrite_done

insert_awrite_used:
    mov ebx,es:[eax].dh_prev
    mov es:[eax].dh_prev,edi
    mov es:[ebx].dh_next,edi
    mov es:[edi].dh_prev,ebx
    mov es:[edi].dh_next,eax    
    inc ds:disc_awrite_count

insert_awrite_done:
    mov ds:disc_awrite_list,edi

insert_awrite_end:
    pop ebx
    pop eax
    ret
insert_async_write      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UPDATE_ASYNC_WRITE
;
;           DESCRIPTION:    Update async write list
;
;           PARAMETERS:         DS          Disc selector
;                           ES          Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_async_write      PROC near
    GetSystemTime
    mov esi,eax
    sub esi,MIN_TIMEOUT
    sub eax,ds:disc_awrite_timeout
    sbb edx,ds:disc_awrite_timeout+4
    jc update_async_done

update_async_loop:
    mov edi,ds:disc_awrite_list
    or edi,edi
    jz update_async_done
;
    mov edi,es:[edi].dh_prev
    mov eax,esi
    sub eax,es:[edi].dh_time_lsb
    jc update_async_done
;
    mov eax,es:[edi].dh_next
    mov ebx,es:[edi].dh_prev
    mov es:[ebx].dh_next,eax
    mov es:[eax].dh_prev,ebx
    cmp eax,edi
    jne update_async_insert
;
    mov dword ptr ds:disc_awrite_list,0
    mov ds:disc_awrite_count,1

update_async_insert:
    dec ds:disc_awrite_count
    and es:[edi].dh_flags, NOT FLAG_ASYNC_WRITE
    call insert_pending
    jmp update_async_loop

update_async_done:
    ret
update_async_write      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FLUSH_ASYNC_WRITE
;
;           DESCRIPTION:    Flush async write list
;
;           PARAMETERS:         DS          Disc selector
;                           ES          Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_async_write       PROC near
    mov edi,ds:disc_awrite_list
    or edi,edi
    jz flush_async_done
;
    mov edi,es:[edi].dh_prev
    mov eax,es:[edi].dh_next
    mov ebx,es:[edi].dh_prev
    mov es:[ebx].dh_next,eax
    mov es:[eax].dh_prev,ebx
    cmp eax,edi
    jne flush_async_insert
;
    mov dword ptr ds:disc_awrite_list,0

flush_async_insert:
    and es:[edi].dh_flags, NOT FLAG_ASYNC_WRITE
    call insert_pending
    jmp flush_async_write

flush_async_done:
    mov ds:disc_awrite_count,0
    ret
flush_async_write       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ASYNC_WRITE_TIMEOUT
;
;           DESCRIPTION:    Async write timeout
;
;           PARAMETERS:         CX          Disc thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

async_write_timeout     Proc far
    mov ds,cx
    RequestSpinlock ds:disc_spinlock
    mov ds:disc_awrite_timer,0
    ReleaseSpinlock ds:disc_spinlock
;
    mov bx,ds:disc_thread
    Signal
    retf32
async_write_timeout     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UPDATE_ASYNC_TIMER
;
;           DESCRIPTION:    Update async write timer
;
;           PARAMETERS:         DS          Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_async_timer      Proc near
    RequestSpinlock ds:disc_spinlock
    mov ax,ds:disc_awrite_timer
    or ax,ax
    jnz update_async_timer_release
;
    mov edi,ds:disc_awrite_list
    or edi,edi
    jz update_async_timer_release
;
    mov ds:disc_awrite_timer,1
    ReleaseSpinlock ds:disc_spinlock
;
    GetSystemTime
    add eax,POLL_TIMEOUT
    adc edx,0
    mov ds:disc_awrite_timeout,eax
    mov ds:disc_awrite_timeout+4,edx
    push es
    mov bx,cs
    mov es,bx
    mov cx,ds
    mov edi,OFFSET async_write_timeout
    StartTimer
    pop es
    jmp update_async_timer_done

update_async_timer_release:
    ReleaseSpinlock ds:disc_spinlock

update_async_timer_done:
    ret
update_async_timer      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UPDATE_DISC_SEQ
;
;           DESCRIPTION:    Update seq write lists
;
;           PARAMETERS:         DS          Disc selector
;                           ES          Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_disc_seq PROC near
    mov ax,ds:disc_seq_list
    or ax,ax
    jz update_seq_done
;
    push fs
    pushad
;
    mov bp,ax

update_seq_loop:
    mov fs,ax
    movzx ebx,fs:dss_perform_index

update_seq_discard_loop:
    mov edi,fs:[4*ebx].dss_arr
    cmp es:[edi].dh_state,STATE_SEQ
    je update_seq_move_loop
;
    mov fs:[4*ebx].dss_arr,0
    inc bx
    mov fs:dss_perform_index,bx
    cmp bx,fs:dss_insert_index
    jne update_seq_discard_loop     
;
    push es
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    mov ds:disc_seq_list,es
    push ds
    mov di,es:dss_next
    cmp di,ds:disc_seq_list
    mov ds:disc_seq_list,di
    mov si,es:dss_prev
    mov ds,di
    mov ds:dss_prev,si
    mov ds,si
    mov ds:dss_next,di
    pop ds
    jne update_seq_free
;
    mov ds:disc_seq_list,0

update_seq_free:
    FreeMem
    pop es
    mov ax,ds:disc_seq_list
    or ax,ax
    jz update_seq_pop_done
;
    mov bp,ax
    jmp update_seq_loop

update_seq_move_loop:
    mov dx,es:[edi].dh_sector
    mov eax,es:[edi].dh_unit
    test es:[edi].dh_flags,FLAG_IO_PENDING
    jnz update_seq_moved
;
    call insert_pending

update_seq_moved:
    inc bx
    inc dx
    cmp bx,fs:dss_insert_index
    je update_seq_pop_done  
;
    mov edi,fs:[4*ebx].dss_arr
    cmp eax,es:[edi].dh_unit
    jne update_seq_next
;
    cmp dx,es:[edi].dh_sector
    je update_seq_move_loop

update_seq_next:
    mov ax,fs:dss_next
    cmp ax,bp
    jne update_seq_loop

update_seq_pop_done:
    popad
    pop fs

update_seq_done:
    ret
update_disc_seq ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CHECK_BUF
;
;           DESCRIPTION:    Check if sector is in buffer cache
;
;           PARAMETERS:     DS          Disc selector
;                           ES          Flat_sel
;                           ECX          Unit #
;                           DX          Sector #
;
;           RETURNS:        EDI         DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_buf       PROC near
    push esi
    mov esi,ecx
    mov edi,ds:[4*esi].disc_unit_arr
    or edi,edi
    jz check_buf_fail
;
    movzx esi,dx
    mov edi,es:[4*esi+edi].disc_sector_arr

ifdef DEBUG

    or edi,edi
    jz check_no_del
    call CheckDeleted
check_no_del:

endif
    
    or edi,edi
    clc
    jnz check_buf_done
    
check_buf_fail:
    stc

check_buf_done:
    pop esi
    ret
check_buf       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INSERT_BUF
;
;           DESCRIPTION:    Insert block in buffer list
;
;           PARAMETERS:         DS          DiscBuf handle
;                           ES          Flat_sel
;                           EDI         DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert_buf      PROC near
    push eax
    push ecx
    push edx
    push esi

ifdef DEBUG
    call CheckDeleted
endif
    
    mov esi,es:[edi].dh_unit
    mov edx,ds:[4*esi].disc_unit_arr
    or edx,edx
    jne insert_buf_used
;
    push ebp
    push edi
;
    mov edi,OFFSET disc_sector_arr
    movzx ecx,ds:disc_sectors_per_unit
    mov eax,ecx
    shl eax,2
    add eax,edi
;
    mov ebp,ecx
    dec ebp
    shr ebp,3
    add ebp,5
    add eax,ebp
    add eax,4
;
    AllocateSmallLinear
    mov ds:[4*esi].disc_unit_arr,edx
    mov es:[edx].disc_sectors,0
    mov es:[edx].disc_sector_pend_low,-1
    mov es:[edx].disc_sector_pend_high,0
    add edi,edx
    xor eax,eax
    inc ecx
    rep stos dword ptr es:[edi]
    mov es:[edx].disc_sector_pend_ptr,edi
;
    mov ecx,ebp
    xor al,al
    rep stos byte ptr es:[edi]
;
    pop edi
    pop ebp

insert_buf_used:
    mov eax,es:[edi].dh_unit
    inc es:[edx].disc_sectors
    movzx esi,es:[edi].dh_sector
    mov es:[4*esi+edx].disc_sector_arr,edi
;
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
insert_buf      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REMOVE_BUF
;
;           DESCRIPTION:    Remove block from buffer list
;
;           PARAMETERS:         DS          Disc selector
;                           ES          Flat_sel
;                           EDI         DiscBlock handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_buf      PROC near
    push ecx
    push edx
    push esi

ifdef DEBUG
    call CheckDeleted
    call CheckBuffered
endif
    
    mov esi,es:[edi].dh_unit
    mov edx,ds:[4*esi].disc_unit_arr
    or edx,edx
    jz remove_buf_done
;
    movzx ecx,es:[edi].dh_sector
    mov es:[4*ecx+edx].disc_sector_arr,0
    sub es:[edx].disc_sectors,1
    jnz remove_buf_done
;
    mov ds:[4*esi].disc_unit_arr,0
    movzx ecx,ds:disc_sectors_per_unit
    inc ecx
    shl ecx,2
    add ecx,OFFSET disc_sector_arr
    FreeLinear

remove_buf_done:
    pop esi
    pop edx
    pop ecx
    ret
remove_buf      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Block
;
;           DESCRIPTION:    Block until IO complete
;
;           PARAMETERS:         DS          Disc selector
;                           ES          Flat_sel
;                           EDI         DiscBlock handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

block   Proc near
    push ax
    push bx
    push dx
;
    mov ax,es:[edi].dh_thread
    or ax,ax
    jnz block_list
;
    GetThread
    mov es:[edi].dh_thread,ax
    mov bx,ds:disc_thread
    Signal
    jmp block_do

block_list:
    push ds
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:drive_wait_free
    mov ax,[bx]
    mov ds:drive_wait_free,ax
    GetThread
    mov ds:[bx].dws_thread,ax
    mov dx,es:[edi].dh_wait
    mov ds:[bx].dws_link,dx
    mov es:[edi].dh_wait,bx
    pop ds

block_list_do:
    LeaveSection ds:disc_section
    WaitForSignal
    EnterSection ds:disc_section
;       
    push ds
    mov bx,SEG data
    mov ds,bx
;    
    GetThread
    mov bx,es:[edi].dh_wait

block_list_check_loop:
    or bx,bx
    jz block_list_exit_pop
;
    cmp ax,ds:[bx].dws_thread
    je block_list_cont_pop
;    
    mov bx,ds:[bx].dws_link
    jmp block_list_check_loop

block_list_cont_pop:
    pop ds
    jmp block_list_do

block_list_exit_pop:
    pop ds
    jmp block_exit
    
block_do:
    LeaveSection ds:disc_section
    WaitForSignal
    EnterSection ds:disc_section
;       
    mov bx,es:[edi].dh_thread
    cmp ax,bx
    je block_do
    
block_exit:
    pop dx
    pop bx
    pop ax
    ret
block   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           START_DISC
;
;           DESCRIPTION:    Start disc
;
;           PARAMETERS:         BX          Disc sel
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_disc_name DB 'Start Disc',0

start_disc      Proc far
    push ds
    push es
    pusha
;
    mov ax,SEG data
    mov ds,ax
    mov cx,MAX_DRIVES
    mov si,OFFSET drive_def_arr

start_drives_loop:
    mov ax,[si]
    or ax,ax
    jz start_drives_next
;
    cmp ax,-1
    je start_drives_next
;
    mov es,ax
    cmp bx,es:drive_disc
    jne start_drives_next
;
    push ecx
    mov ecx,es:drive_sectors
    mov ax,si
    sub ax,OFFSET drive_def_arr
    shr ax,1
    StartFileSystem
    pop ecx

start_drives_next:
    add si,2
    loop start_drives_loop  
;
    popa
    pop es
    pop ds
    retf32
start_disc      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           STOP_DISC
;
;           DESCRIPTION:    Stop disc
;
;           PARAMETERS:         BX          Disc sel
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_disc_name  DB 'Stop Disc',0

stop_disc       Proc far
    push ds
    push es
    pusha
;
    mov ax,SEG data
    mov ds,ax
    mov cx,MAX_DRIVES
    mov si,OFFSET drive_def_arr

stop_drives_loop:
    mov ax,[si]
    or ax,ax
    jz stop_drives_next
;
    cmp ax,-1
    je stop_drives_next
;
    mov es,ax
    cmp bx,es:drive_disc
    jne stop_drives_next
;
    mov ax,si
    sub ax,OFFSET drive_def_arr
    shr ax,1
    CloseDrive

stop_drives_next:
    add si,2
    loop stop_drives_loop   
;
    mov ax,SEG data
    mov ds,ax
    mov si,OFFSET disc_def_arr
    mov cx,MAX_DRIVES

stop_disc_loop:
    cmp bx,[si]
    je stop_disc_do
;
    add si,2
    loop stop_disc_loop
;
    jmp stop_disc_done

stop_disc_do:
    mov word ptr ds:[si],0
    mov es,bx
    FreeMem            

stop_disc_done:
    popa
    pop es
    pop ds
    retf32
stop_disc       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_DISC_PARAM
;
;           DESCRIPTION:    Set disc parameters
;
;           PARAMETERS:         AX          Sectors per unit
;                           BX          Disc sel
;                           CX          Bytes per sector
;                           EDX         Units
;                           SI          BIOS sectors / cylinder
;                           DI          BIOS heads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_disc_param_name     DB 'Set Disc Param',0

set_disc_param  Proc far
    push ds
    push es
    pushad
;
    mov ds,bx
    mov ds:disc_sectors_per_unit,ax
    mov ds:disc_bytes_per_sector,cx
    mov ds:disc_units,edx
    mov ds:disc_sectors_per_cyl,si
    mov ds:disc_heads,di
;
    push edx
    GetFreePhysical
    or edx,edx
    jz set_param_low
;
    mov eax,0FFFFFFFFh

set_param_low:
    pop edx
    shr eax,5           ; use 1/32 of physical memory per disc
    cmp eax,10000h      ; use a minimum of 64k per disc
    ja set_param_max
;
    mov eax,10000h

set_param_max:
    shr eax,9
    mov ds:disc_cache_limit,eax
    mov ds:disc_cached_sectors,0
;
    mov ecx,OFFSET disc_unit_arr
    mov eax,edx
    shl eax,2
    add eax,ecx
    AllocateSmallGlobalMem
    xor di,di
    xor si,si
    rep movsb
;
    xor eax,eax
    movzx edi,di
    mov ecx,edx
    rep stos dword ptr es:[edi]
;
    mov si,ds
    mov di,es
    mov ax,gdt_sel
    mov ds,ax
    cli
    mov eax,[si]
    xchg eax,[di]
    mov [si],eax
    mov eax,[si+4]
    xchg eax,[di+4]
    mov [si+4],eax
    sti
    jmp short $+2
    mov ds,si
    mov es,di
    FreeMem
;
    mov eax,ds:disc_units
    dec eax
    shr eax,3
    add eax,5
    AllocateSmallGlobalMem
    mov ds:disc_pend_bitmap,es
    xor edi,edi
    mov ecx,eax
    xor al,al
    rep stos byte ptr es:[edi]
;
    movzx eax,ds:disc_sectors_per_unit
    mul ds:disc_units
    mov ds:disc_total_sectors,eax
    mov ds:disc_total_sectors+4,edx
;
    popad
    pop es
    pop ds
    retf32
set_disc_param  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CalcParam
;
;       DESCRIPTION:    Calculate various parameters
;
;       PARAMETERS:     DS      Disc sel
;                       EDX:EAX	Sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcParam       Proc near
    pushad
;
    mov ebx,1
    mov ds:disc_total_sectors,eax
    mov ds:disc_total_sectors+4,edx

calc_param_norm_loop:
    shl ebx,1
    cmp ebx,10000h
    je calc_param_done
;
    shr edx,1
    rcr eax,1
;
    or edx,edx
    jnz calc_param_norm_loop
;    
    cmp ebx,eax
    jc calc_param_norm_loop

calc_param_done:
    cmp eax,10000h
    jc calc_param_in_range
;
    mov eax,0FFFFh

calc_param_in_range:    
    movzx ebx,ax
    mov ds:disc_sectors_per_unit,ax
    mov eax,ds:disc_total_sectors
    mov edx,ds:disc_total_sectors+4
    div ebx
    mov ds:disc_units,eax

calc_norm_loop:
    movzx eax,ds:disc_sectors_per_unit
    mul ds:disc_units
    sub edx,ds:disc_total_sectors+4
    sbb eax,ds:disc_total_sectors 
    jnc calc_norm_ok
;
    add ds:disc_sectors_per_unit,1
    jnc calc_norm_loop
;
    dec ds:disc_sectors_per_unit
    inc ds:disc_units
    jmp calc_norm_loop

calc_norm_ok:    
    popad
    ret
CalcParam       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_DISC_LBA_PARAM
;
;           DESCRIPTION:    Set disc LBA params
;
;           PARAMETERS:     BX          Disc sel
;                           CX          Bytes per sector
;                           EDX:EAX     Total sectors
;
;           RETURNS:        AX		Sectors per unit
;                           EDX		Units
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_disc_lba_param_name     DB 'Set Disc LBA Param',0

set_disc_lba_param  Proc far
    push ds
    push es
    push ebx
    push ecx
    push esi
    push edi
;
    mov ds,bx
    mov ds:disc_bytes_per_sector,cx
    mov ds:disc_sectors_per_cyl,-1
    mov ds:disc_heads,-1
    call CalcParam
;
    GetFreePhysical
    or edx,edx
    jz set_lba_param_low
;
    mov eax,0FFFFFFFFh

set_lba_param_low:
    mov edx,ds:disc_units
    shr eax,5           ; use 1/32 of physical memory per disc
    cmp eax,10000h      ; use a minimum of 64k per disc
    ja set_lba_param_max
;
    mov eax,10000h

set_lba_param_max:
    shr eax,9
    mov ds:disc_cache_limit,eax
    mov ds:disc_cached_sectors,0
;
    mov ecx,OFFSET disc_unit_arr
    mov eax,edx
    shl eax,2
    add eax,ecx
    AllocateSmallGlobalMem
    xor di,di
    xor si,si
    rep movsb
;
    xor eax,eax
    movzx edi,di
    mov ecx,edx
    rep stos dword ptr es:[edi]
;
    mov si,ds
    mov di,es
    mov ax,gdt_sel
    mov ds,ax
    cli
    mov eax,[si]
    xchg eax,[di]
    mov [si],eax
    mov eax,[si+4]
    xchg eax,[di+4]
    mov [si+4],eax
    sti
    jmp short $+2
    mov ds,si
    mov es,di
    FreeMem
;
    mov eax,ds:disc_units
    dec eax
    shr eax,3
    add eax,5
    AllocateSmallGlobalMem
    mov ds:disc_pend_bitmap,es
    xor edi,edi
    mov ecx,eax
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov ax,ds:disc_sectors_per_unit
    mov edx,ds:disc_units
;
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop es
    pop ds
    retf32
set_disc_lba_param  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_DISC_VENDOR_INFO_BUF
;
;           DESCRIPTION:    Get disc vendor info buffer
;
;           PARAMETERS:     BX          Disc sel
;
;           RETURNS:        ES:EDI      Vendor info buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disc_vendor_info_buf_name     DB 'Get Disc Vendor Info Buf',0

get_disc_vendor_info_buf  Proc far
    mov es,bx
    mov edi,OFFSET disc_vendor_str
    retf32
get_disc_vendor_info_buf  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_DISC_USE32
;
;           DESCRIPTION:    Set disc to always allocte 32-bit physical blocks
;
;           PARAMETERS:     BX          Disc sel
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_disc_use32_name     DB 'Set Disc Use32',0

set_disc_use32  Proc far
    push ds
    mov ds,bx
    lock or ds:disc_flags,DISC_FLAG_USE32
    pop ds
    retf32
set_disc_use32  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REGISTER_DISC_CHANGE
;
;           DESCRIPTION:    Register disc-change procedure
;
;           PARAMETERS:     BX          Disc sel
;                           ES:EDI   Disc change proc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_disc_change_name       DB 'Register Disc Change',0

register_disc_change    Proc far
    push ds
    push bx
;
    mov ds,bx
    mov dword ptr ds:disc_change_proc,edi
    mov word ptr ds:disc_change_proc+4,es
;
    pop bx
    pop ds
    retf32
register_disc_change    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RegisterDemandMount
;
;           DESCRIPTION:    Register demand mount procedure
;
;           PARAMETERS:     BX       Disc sel
;                           ES:EDI   Demand mount proc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_demand_mount_name       DB 'Register Demand Mount',0

register_demand_mount    Proc far
    push ds
    push bx
;
    mov ds,bx
    mov dword ptr ds:disc_demand_mount_proc,edi
    mov word ptr ds:disc_demand_mount_proc+4,es
;
    pop bx
    pop ds
    retf32
register_demand_mount    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           stop_disc_request
;
;           DESCRIPTION:    stop disc request
;
;           PARAMETERS:     BX          Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_disc_request_name      DB 'Stop Disc Request', 0

stop_disc_request   Proc far
    push ds
    push bx
;
    or bx,bx
    jz sdrDone
;    
    mov ds,bx
    lock or ds:disc_flags,DISC_FLAG_STOPPED
    mov bx,ds:disc_thread
    Signal

sdrDone:
    pop bx
    pop ds
    retf32
stop_disc_request   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           wait_for_disc_request
;
;           DESCRIPTION:    wait for a new disc request
;
;           PARAMETERS:     BX          Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_disc_request_name      DB 'Wait For Disc Request', 0

wait_for_disc_request   Proc far
    push ds
    push es
    pushad
;
    mov ds,bx
    mov ax,flat_sel
    mov es,ax
;
    ClearSignal
    GetThread
    mov ds:disc_thread,ax

wait_for_disc_req_loop:
    EnterSection ds:disc_section
    call update_async_write
    call update_async_timer
    LeaveSection ds:disc_section
;
    mov eax,ds:disc_io_count
    or eax,eax
    clc
    jnz wait_for_disc_req_done
;
    test ds:disc_flags,DISC_FLAG_STOPPED
    stc
    jnz wait_for_disc_req_done
;    
    GetSystemTime
    add eax,1193 * 250
    adc edx,0
    WaitForSignalWithTimeout
    jmp wait_for_disc_req_loop
        
wait_for_disc_req_done:
    mov ds:disc_thread,0
;
    popad
    pop es
    pop ds
    retf32
wait_for_disc_request   Endp
        
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           new_disc_request
;
;           DESCRIPTION:    Create a new disc request and return the handle
;
;           PARAMETERS:         BX          Disc selector
;                           AX          Sector
;                           DX          Unit
;
;           RETURNS:        EDI         Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

new_disc_request_name   DB 'New Disc Request', 0

new_disc_request    Proc far
    push ds
    push es
    push ecx
    push dx
;
    mov ds,bx
    mov cx,flat_sel
    mov es,cx
    movzx ecx,dx
    mov dx,ax
    EnterSection ds:disc_section
;
    call check_buf
    jnc new_disc_req_fail
;
    cmp dx,ds:disc_sectors_per_unit
    jae new_disc_req_fail
;
    cmp ecx,ds:disc_units
    jae new_disc_req_fail
;
    call allocate_handle
    push edx
    call allocate_data
    mov es:[edi].dh_data,edx
    pop edx
    mov es:[edi].dh_buf_sel,ds
    mov es:[edi].dh_sector,dx
    movzx ecx,cx
    mov es:[edi].dh_unit,ecx
    mov es:[edi].dh_wait,0
    mov es:[edi].dh_thread,0
    mov es:[edi].dh_lock_count,0
    mov es:[edi].dh_state,STATE_EMPTY
    mov es:[edi].dh_usage,0
    mov es:[edi].dh_flags,0
    mov es:[edi].dh_time_lsb,0
    call insert_buf
    inc es:[edi].dh_lock_count
    LeaveSection ds:disc_section
    clc
    jmp new_disc_req_done

new_disc_req_fail:
    LeaveSection ds:disc_section
    stc

new_disc_req_done:
    pop dx
    pop ecx
    pop es
    pop ds
    retf32
new_disc_request    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LOCK_DISC_REQUEST
;
;           DESCRIPTION:    Lock disc sector and return handle
;
;           PARAMETERS:         BX          Disc selector
;                           AX          Sector
;                           DX          Unit
;
;           RETURNS:        EDI         Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_disc_request_name  DB 'Lock Disc Request',0

lock_disc_request       PROC far
    push ds
    push es
    push ax
    push ebx
    push ecx
    push edx
;
    mov ds,bx
    mov cx,flat_sel
    mov es,cx
    movzx ecx,dx
    mov dx,ax
    EnterSection ds:disc_section

lock_disc_loop:
    call check_buf
    jnc lock_disc_ok
;
    call allocate_handle
    push edx
    call allocate_data
    mov es:[edi].dh_data,edx
    pop edx
    mov es:[edi].dh_buf_sel,ds
    mov es:[edi].dh_sector,dx
    movzx ecx,cx
    mov es:[edi].dh_unit,ecx
    mov es:[edi].dh_wait,0
    mov es:[edi].dh_thread,0
    mov es:[edi].dh_lock_count,0
    mov es:[edi].dh_state,STATE_EMPTY
    mov es:[edi].dh_usage,0
    mov es:[edi].dh_flags,0
    mov es:[edi].dh_time_lsb,0
    mov es:[edi].dh_flags,0
    call insert_buf
    inc es:[edi].dh_lock_count

lock_disc_ok:
    clc

lock_disc_done:
    pop edx
    pop ecx
    pop ebx
    pop ax
    pop es
    pop ds
    retf32
lock_disc_request       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MODIFY_DISC_REQUEST
;
;           DESCRIPTION:    Modify disc request
;
;           PARAMETERS:         EDI         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

modify_disc_request_name    DB 'Modify Disc Request',0

modify_disc_request     PROC far
    push ds
    push es
    pushad
;
    mov ax,flat_sel
    mov es,ax
    mov ds,es:[edi].dh_buf_sel
;       
    mov al,es:[edi].dh_state
    cmp al,STATE_USED
    jne modify_disc_done
;       
    mov es:[edi].dh_state,STATE_DIRTY
;       
    test es:[edi].dh_flags, FLAG_IO_PENDING
    jnz modify_disc_done
;       
    GetSystemTime
    mov es:[edi].dh_time_lsb,eax
    call insert_async_write
    call update_async_timer

modify_disc_done:
    clc
;
    popad
    pop es
    pop ds
    retf32
modify_disc_request     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UNLOCK_DISC_REQUEST
;
;           DESCRIPTION:    UNlock disc request
;
;           PARAMETERS:         EDI         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_disc_request_name    DB 'Unlock Disc Request',0

unlock_disc_request     PROC far
    push ds
;
    mov ds,es:[edi].dh_buf_sel
    LeaveSection ds:disc_section
;
    pop ds
    clc
    retf32
unlock_disc_request     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           disc_request_completed
;
;           DESCRIPTION:    Disc request completed
;
;           PARAMETERS:         BX          Disc selector
;                           EDI         Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_request_completed_name     DB 'Disc Request Completed', 0

disc_request_completed  Proc far
    push ds
    push es
    push eax
    push bx
    push dx
;
    mov ax,flat_sel
    mov es,ax
    mov ds,bx
    EnterSection ds:disc_section

ifdef DEBUG     
    call CheckDeleted
    call CheckBuffered
endif
    
    dec ds:disc_io_count
;       
    and es:[edi].dh_flags, NOT (FLAG_IO_PENDING OR FLAG_IO_BUSY)
    xor bx,bx
    xchg bx,es:[edi].dh_thread
    Signal
    mov bx,es:[edi].dh_wait
    or bx,bx
    jz completed_wakeup_done
;
    push ds
    mov ax,SEG data
    mov ds,ax

completed_wakeup_loop:
    push bx
    mov bx,ds:[bx].dws_thread
    Signal
    pop bx

ifdef DEBUG
    call CheckDriveWait
endif
    
    mov dx,ds:[bx].dws_link
    mov ax,ds:drive_wait_free
    mov [bx],ax
    mov ds:drive_wait_free,bx

ifdef DEBUG
    inc ds:drive_wait_count
    call CheckDriveWait
endif   
    
    mov bx,dx
    or bx,bx
    jnz completed_wakeup_loop
;
    pop ds

completed_wakeup_done:
    mov es:[edi].dh_wait,0
;
    test es:[edi].dh_flags, FLAG_EXT_DATA
    jz completed_done
;
    cmp es:[edi].dh_lock_count,0
    jnz completed_done
    
    call remove_buf
    mov es:[edi].dh_state, STATE_EMPTY
    mov eax,ds:disc_handle_list
    mov es:[edi],eax
    mov ds:disc_handle_list,edi
    dec ds:disc_cached_sectors

ifdef DEBUG
    call CheckAll
endif

completed_done:
    LeaveSection ds:disc_section
    xor edi,edi
;
    pop dx
    pop bx
    pop eax
    pop es
    pop ds
    retf32
disc_request_completed  Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           disc_request_retry
;
;           DESCRIPTION:    Disc request retry
;
;           PARAMETERS:     BX          Disc selector
;                           EDI         Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_request_retry_name     DB 'Disc Request Retry', 0

disc_request_retry  Proc far
    push ds
    push es
    push eax
    push bx
    push dx
;
    mov ax,flat_sel
    mov es,ax
    mov ds,bx
    EnterSection ds:disc_section
    dec ds:disc_io_count
;       
    and es:[edi].dh_flags, NOT (FLAG_IO_PENDING OR FLAG_IO_BUSY)
    call insert_pending
;
    LeaveSection ds:disc_section
    xor edi,edi
;
    mov bx,ds:disc_thread
    Signal
;
    pop dx
    pop bx
    pop eax
    pop es
    pop ds
    retf32
disc_request_retry  Endp
    
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_disc_request_array
;
;           DESCRIPTION:    get a disc request array
;
;           PARAMETERS:         BX          Disc selector
;                           ECX         Max number of entries
;
;           RETURNS:        ESI         Disc array
;                           ECX         Number of entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disc_request_array_name     DB 'Get Disc Request Array', 0

get_disc_request_array  Proc far
    push ds
    push es
    push fs
    push eax
    push ebx
    push edx
    push edi
    push ebp
;
    mov ebp,ecx
    mov ds,bx
    EnterSection ds:disc_section
    call update_async_write
    call update_async_timer
    call update_disc_seq
    mov fs,ds:disc_pend_bitmap
    mov eax,ds:disc_io_count
    or eax,eax
    stc
    jz gdraDone

gdraRetry:
    mov edi,ds:disc_curr_unit
    cmp edi,-1
    je gdraSetupUnitScan
;
    mov ebx,edi
    mov cl,bl
    and cl,7
    shr ebx,3
    mov eax,fs:[ebx]
    shr eax,cl
    test al,1
    jnz gdraHasUnit
;
    mov ds:disc_start_unit,edi
    mov ds:disc_curr_sector,-1
;
    bsf eax,eax
    jnz gdraFoundUnit
;
    add ebx,3
    mov edi,ebx
    shl edi,3
;
    mov ecx,ds:disc_pend_high
    shr ecx,3
    sub ecx,ebx
    jc gdraSetupUnitScan
;
    shr ecx,2
    inc ecx
    jmp gdraUnitScan

gdraSetupUnitScan:
    mov ds:disc_curr_sector,-1
    mov ebx,ds:disc_pend_low
    cmp ebx,-1
    je gdraNoReq
;
    mov ds:disc_start_unit,ebx
    shr ebx,3
    mov edi,ebx
    shl edi,3
;
    mov ecx,ds:disc_pend_high
    shr ecx,3
    sub ecx,ebx
    shr ecx,2
    inc ecx

gdraUnitScan:
    mov eax,fs:[ebx]
    bsf eax,eax
    jnz gdraFoundUnit
;
    add ebx,4
    add edi,32
    sub ecx,1
    jnz gdraUnitScan
;
    mov eax,ds:disc_pend_low
    cmp eax,ds:disc_start_unit
    jae gdraNoReq
;
    mov ds:disc_curr_unit,-1
    mov eax,ds:disc_start_unit
    mov ds:disc_pend_high,eax
    jmp gdraRetry

gdraNoReq:
    mov ds:disc_pend_low,-1
    mov ds:disc_pend_high,0
    mov ds:disc_curr_unit,-1
    stc
    jmp gdraDone

gdraFoundUnit:
    add edi,eax
;
    mov eax,ds:disc_start_unit
    cmp eax,ds:disc_pend_low
    jne gdraHasUnit
;
    mov ds:disc_pend_low,edi

gdraHasUnit:
    mov ds:disc_curr_unit,edi
;
    mov edi,ds:[4*edi].disc_unit_arr
    or edi,edi
    jz gdraClearUnit
;
    mov edx,es:[edi].disc_sector_pend_ptr
;
    mov ax,ds:disc_curr_sector
    cmp ax,-1
    je gdraSetupSectorScan
;
    movzx ebx,ax
    mov esi,ebx
    mov cl,bl
    and cl,7
    shr ebx,3
    mov eax,es:[ebx+edx]
    shr eax,cl
    test al,1
    jnz gdraHasSector
;
    mov ds:disc_start_sector,si
    bsf eax,eax
    jnz gdraSectorFound
;
    add ebx,3
    mov esi,ebx
    shl esi,3
;
    movzx ecx,es:[edi].disc_sector_pend_high
    shr ecx,3
    sub ecx,ebx
    jc gdraNextUnit
;
    shr ecx,2
    inc ecx
    jmp gdraSectorScan

gdraSetupSectorScan:
    movzx ebx,es:[edi].disc_sector_pend_low
    mov ds:disc_start_sector,bx
    movzx ecx,es:[edi].disc_sector_pend_high
    shr ebx,3
    mov esi,ebx
    shl esi,3
;
    shr ecx,3
    sub ecx,ebx
    shr ecx,2
    inc ecx

gdraSectorScan:
    mov eax,es:[ebx+edx]
    bsf eax,eax
    jnz gdraSectorFound
;
    add ebx,4
    add esi,32
    sub ecx,1
    jnz gdraSectorScan
;
    mov ax,es:[edi].disc_sector_pend_low
    cmp ax,ds:disc_start_sector
    jae gdraClearUnit
;
    mov ax,ds:disc_start_sector
    mov es:[edi].disc_sector_pend_high,ax

gdraNextUnit:
    mov ds:disc_curr_sector,-1
    inc ds:disc_curr_unit
    jmp gdraRetry

gdraClearUnit:
    mov edi,ds:disc_curr_unit
    xor edx,edx
    btr fs:[edx],edi
    mov ds:disc_curr_sector,-1
    jmp gdraRetry

gdraSectorFound:
    add esi,eax
    cmp si,es:[edi].disc_sector_pend_high
    ja gdraNextUnit
;
    mov ax,ds:disc_start_sector
    cmp ax,es:[edi].disc_sector_pend_low
    jne gdraHasSector
;
    mov es:[edi].disc_sector_pend_low,si

gdraHasSector:
    lea ebx,[4*esi+edi].disc_sector_arr
    push ebx
    xor ecx,ecx
    mov edi,es:[ebx]
;
    btr es:[edx],esi
    or es:[edi].dh_flags,FLAG_IO_BUSY
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    je gdraRead

gdraWrite:
    inc ecx
    inc esi
    add ebx,4
    sub ebp,1
    jz gdraOk
;
    mov edi,es:[ebx]
    or edi,edi
    jz gdraOk
;
    mov al,es:[edi].dh_flags
    test al,FLAG_IO_PENDING
    jz gdraOk
;
    test al,FLAG_IO_BUSY
    jnz gdraOk
;
    mov al,es:[edi].dh_state
    cmp al,STATE_DIRTY
    jne gdraOk
;
    btr es:[edx],esi
    or es:[edi].dh_flags,FLAG_IO_BUSY
    jmp gdraWrite

gdraRead:
    inc ecx
    inc esi
    add ebx,4
    sub ebp,1
    jz gdraOk
;
    mov edi,es:[ebx]
    or edi,edi
    jz gdraOk
;
    mov al,es:[edi].dh_flags
    test al,FLAG_IO_PENDING
    jz gdraOk
;
    test al,FLAG_IO_BUSY
    jnz gdraOk
;
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    jne gdraOk
;
    btr es:[edx],esi
    or es:[edi].dh_flags,FLAG_IO_BUSY
    jmp gdraRead
    
gdraOk:
    mov ds:disc_curr_sector,si
    pop esi
    clc
    
gdraDone:
    LeaveSection ds:disc_section
;
    pop ebp
    pop edi
    pop edx
    pop ebx
    pop eax
    pop fs
    pop es
    pop ds
    retf32
get_disc_request_array  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           INSTALL_DISC
;
;   DESCRIPTION:    Install disc unit
;
;   PARAMETERS:     BX          Handle
;                   ECX         Readahead
;
;   RETURNS:        AL          Disc #
;                   BX          Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_static_disc_name       DB 'Install Static Disc',0
install_dynamic_disc_name      DB 'Install Dynamic Disc',0
install_fixed_disc_name        DB 'Install Fixed Disc',0

install_disc    Proc near
    push es
    push cx
    push si
    push di
;
    push cx
    mov ax,SEG data
    mov ds,ax
    mov si,OFFSET disc_def_arr
    mov cx,MAX_DRIVES

install_disc_loop:
    mov ax,[si]
    or ax,ax
    jnz install_disc_next
;
    push bx
    mov eax,SIZE disc_def_struc
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
    mov [si],es
    mov ax,es
    mov ds,ax
    mov ax,si
    sub ax,OFFSET disc_def_arr
    shr ax,1
    mov ds:disc_nr,al
    mov ds:disc_flags,0
    mov ds:disc_handle_list,0
    mov ds:disc_data_list,0
    mov ds:disc_awrite_list,0
    mov ds:disc_awrite_timer,0
    mov ds:disc_awrite_timeout,0
    mov ds:disc_awrite_timeout+4,0
    mov ds:disc_seq_list,0
    mov ds:disc_free,0
    mov ds:disc_timer_id,0
    mov ds:disc_thread,0
    mov ds:disc_change_proc,0
    mov ds:disc_change_proc+4,0
    mov ds:disc_demand_mount_proc,0
    mov ds:disc_demand_mount_proc+4,0
    mov ds:disc_cached_sectors,0
    mov ds:disc_vendor_str,0
    pop ds:disc_handle
;
    pop cx
    mov ds:disc_readahead,ecx
;
    InitSection ds:disc_section
    InitSpinlock ds:disc_spinlock
    mov ds:disc_curr_unit,-1
    mov ds:disc_curr_sector,-1
    mov ds:disc_pend_low,-1
    mov ds:disc_pend_high,0
    mov ds:disc_io_count,0
    mov ds:disc_awrite_count,0
    mov bx,ds
    mov al,ds:disc_nr
    clc
    jmp install_disc_done

install_disc_next:
    add si,2
    sub cx,1
    jnz install_disc_loop
    add sp,2
    stc

install_disc_done:
    pop di
    pop si
    pop cx
    pop es
    ret
install_disc    Endp

install_static_disc    Proc far
    push ds
    call install_disc
    pop ds
    retf32
install_static_disc    Endp

install_dynamic_disc    Proc far
    push ds
    call install_disc
    or ds:disc_flags,DISC_FLAG_DYNAMIC
    pop ds
    retf32
install_dynamic_disc    Endp

install_fixed_disc    Proc far
    push ds
    call install_disc
    or ds:disc_flags,DISC_FLAG_INSTALLED
    pop ds
    retf32
install_fixed_disc    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InstallVfsDisc
;
;   DESCRIPTION:    Install VFS disc unit
;
;   RETURNS:        AL          Disc #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_vfs_disc_name       DB 'Install VFS Disc',0

install_vfs_disc    Proc far
    push ds
    push cx
    push si
;
    mov ax,SEG data
    mov ds,ax
    mov si,OFFSET disc_def_arr
    mov cx,MAX_DRIVES

install_vfs_disc_loop:
    mov ax,[si]
    or ax,ax
    jnz install_vfs_disc_next
;
    mov ax,-1
    mov [si],ax
    mov ax,si
    sub ax,OFFSET disc_def_arr
    shr ax,1
    clc
    jmp install_vfs_disc_done

install_vfs_disc_next:
    add si,2
    sub cx,1
    jnz install_vfs_disc_loop
    stc

install_vfs_disc_done:
    pop si
    pop cx
    pop ds
    retf32
install_vfs_disc    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           RemoveVfsDisc
;
;   DESCRIPTION:    Remove VFS disc unit
;
;   RETURNS:        AL          Disc #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_vfs_disc_name       DB 'Remove VFS Disc',0

remove_vfs_disc    Proc far
    push ds
    push ax
    push bx
;
    movzx bx,al
    shl bx,1
    mov ax,SEG data
    mov ds,ax
    mov ds:[bx].disc_def_arr,0
;
    pop bx
    pop ax
    pop ds
    retf32
remove_vfs_disc    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AllocDynamicVfsDrive
;
;   DESCRIPTION:    Allocate dynamic VFS drive
;
;   RETURNS:        AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dynamic_vfs_drive_name       DB 'Allocate Dynamic VFS Drive',0

allocate_dynamic_vfs_drive    Proc far
    push ds
    push cx
    push si
;
    push ax
    mov ax,SEG data
    mov ds,ax
    mov si,OFFSET drive_def_arr + 2 * (MAX_DRIVES - 1)
    mov cx,MAX_DRIVES

avdLoop:
    mov ax,[si]
    or ax,ax
    jnz avdNext
;
    mov word ptr [si],-1
    mov cx,si
    sub cx,OFFSET drive_def_arr
    shr cx,1
    pop ax
    mov al,cl
    clc
    jmp avdDone
    
avdNext:
    sub si,2
    loop avdLoop
;
    pop ax
    stc
    
avdDone:
    pop si
    pop cx
    pop ds
    retf32
allocate_dynamic_vfs_drive  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AllocStaticVfsDrive
;
;   DESCRIPTION:    Allocate static VFS drive
;
;   RETURNS:        AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_static_vfs_drive_name       DB 'Allocate Static VFS Drive',0

allocate_static_vfs_drive    Proc far
    push ds
    push cx
    push si
;
    push ax
    mov ax,SEG data
    mov ds,ax
    mov cx,MAX_DRIVES - 2
    mov si,OFFSET drive_def_arr + 4

avsLoop:
    mov ax,[si]
    or ax,ax
    jnz avsNext
;
    cmp ax,-1
    je avsNext
;
    mov word ptr [si],-1
    mov cx,si
    sub cx,OFFSET drive_def_arr
    shr cx,1
    pop ax
    mov al,cl
    clc
    jmp avsDone
    
avsNext:
    add si,2
    loop avsLoop
;
    pop ax
    stc
    
avsDone:
    pop si
    pop cx
    pop ds
    retf32
allocate_static_vfs_drive  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AllocFixedVfsDrive
;
;   DESCRIPTION:    Allocate fixed VFS drive
;
;   PARAMETERS:     AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_vfs_drive_name       DB 'Allocate Fixed VFS Drive',0

allocate_fixed_vfs_drive    Proc far
    push ds
    push ax
    push cx
    push si
;
    mov si,SEG data
    mov ds,si
;
    movzx ax,al
    cmp ax,MAX_DRIVES
    jae afvdFail
;
    mov si,OFFSET drive_def_arr
    add ax,ax
    add si,ax
;
    mov ax,[si]
    or ax,ax
    jnz afvdFail
;
    cmp ax,-1
    je afvdFail
;
    mov word ptr [si],-1
    clc
    jmp afvdDone
    
afvdFail:
    stc
    
afvdDone:
    pop si
    pop cx
    pop ax
    pop ds
    retf32
allocate_fixed_vfs_drive  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseVfsDrive
;
;           DESCRIPTION:    Close VFS drive
;
;           PARAMETERS:     AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_vfs_drive_name    DB 'Close VFS Drive',0

close_vfs_drive     Proc far
    push ds
    push es
    push ax
    push bx
;
    movzx bx,al
    shl bx,1
;
    mov ax,SEG data
    mov ds,ax
    xor ax,ax
    mov [bx].drive_def_arr,ax
;
    pop bx
    pop ax
    pop es
    pop ds
    retf32
close_vfs_drive    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsDiscIdle
;
;           DESCRIPTION:    Check if disc is idle
;
;           PARAMETERS:     AL          Disc #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_disc_idle_name       DB 'Is Disc Idle',0

is_disc_idle    Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
;
    cmp al,MAX_DRIVES
    jae is_disc_idle_ok
;
    movzx bx,al
    shl bx,1
    mov ds,ds:[bx].disc_def_arr
    mov ebx,ds:disc_io_count
    or ebx,ebx
    jz is_disc_idle_ok
;
    stc
    jmp is_disc_idle_done

is_disc_idle_ok:
    clc

is_disc_idle_done:
    pop ebx
    pop ds
    retf32
is_disc_idle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RemoveDrive
;
;           DESCRIPTION:    Remove drive
;
;           PARAMETERS:     AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_drive_name       DB 'Remove Drive',0

remove_drive    Proc far
    CloseDrive
    retf32
remove_drive    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetDisc
;
;           DESCRIPTION:    Reset disc
;
;           PARAMETERS:     AL          Disc #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_disc_name       DB 'Reset Disc',0

reset_disc    Proc far
    push ds
    push es
    pushad
;
    mov bx,SEG data
    mov ds,bx
;
    cmp al,MAX_DRIVES
    jae reset_disc_done
;
    movzx bx,al
    shl bx,1
    mov bx,ds:[bx].disc_def_arr
;
    mov cx,MAX_DRIVES
    mov si,OFFSET drive_def_arr

reset_disc_drives_loop:
    mov ax,[si]
    or ax,ax
    jz reset_disc_drives_next
;
    cmp ax,-1
    je reset_disc_drives_next
;
    mov es,ax
    cmp bx,es:drive_disc
    jne reset_disc_drives_next
;
    mov ax,si
    sub ax,OFFSET drive_def_arr
    shr ax,1
    RemoveDrive

reset_disc_drives_next:
    add si,2
    loop reset_disc_drives_loop   

reset_disc_done:
    popad
    pop es
    pop ds
    retf32
reset_disc    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ALLOCATE_FIXED_DRIVE
;
;           DESCRIPTION:    Allocate fixed drive
;
;           PARAMETERS:         AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_drive_name       DB 'Allocate Fixed Drive',0

allocate_fixed_drive    Proc far
    push ds
    push ax
    push bx
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    shl bx,1
    mov ax,[bx].drive_def_arr
    or ax,ax
    stc
    jnz afdDone
;       
    mov word ptr [bx].drive_def_arr,-1
    clc

afdDone:
    pop bx
    pop ax
    pop ds
    retf32
allocate_fixed_drive    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OPEN_DRIVE
;
;           DESCRIPTION:    Open drive
;
;           PARAMETERS:     AL          Drive #
;                           AH          Disc #
;                           EDX         Start sector
;                           ECX         Sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_drive_name DB 'Open Drive',0

open_drive      Proc far
    push ds
    push es
    push bx
    push si
    push di
;
    push ax
    mov ax,SEG data
    mov ds,ax
;
    mov eax,SIZE drive_def_struc
    AllocateSmallGlobalMem
    mov es:drive_start_sector,edx
    mov es:drive_sectors,ecx
    pop ax
    movzx bx,ah
    shl bx,1
    mov bx,ds:[bx].disc_def_arr
    mov es:drive_disc,bx
;
    movzx si,al
    shl si,1
    mov [si].drive_def_arr,es
    clc
;
    pop di
    pop si
    pop bx
    pop es
    pop ds
    retf32
open_drive      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CLOSE_DRIVE
;
;           DESCRIPTION:    Close drive
;
;           PARAMETERS:         AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_drive_name    DB 'Close Drive',0

close_drive     Proc far
    push ds
    push es
    push ax
    push bx
;
    StopFileSystem
    FlushDrive
;
    movzx bx,al
    shl bx,1
;
    mov ax,fs_sys_data_sel
    mov ds,ax
    xor ax,ax
    xchg ax,[bx]
;
    mov ax,SEG data
    mov ds,ax
    xor ax,ax
    xchg ax,[bx].drive_def_arr
    or ax,ax
    jz cdrDone
;       
    cmp ax,-1
    je cdrDone
;    
    mov es,ax
    FreeMem    

cdrDone:
    pop bx
    pop ax
    pop es
    pop ds
    retf32
close_drive    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FlushDrive
;
;           DESCRIPTION:    Flush drive
;
;           PARAMETERS:         AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_drive_name    DB 'Flush Drive',0

flush_drive     Proc far
    push ds
    push es
    pushad
;
    movzx bx,al
    shl bx,1
    mov ax,SEG data
    mov ds,ax
    mov ds,ds:[bx].drive_def_arr
    mov ax,flat_sel
    mov es,ax
    mov edx,ds:drive_start_sector
    mov ecx,ds:drive_sectors
    mov ds,ds:drive_disc
;
    EnterSection ds:disc_section
    movzx ebp,ds:disc_sectors_per_unit
    push edx
    pop ax
    pop dx
    div bp
    movzx esi,ax
    movzx ebx,dx

flush_loop:
    mov edx,ds:[4*esi].disc_unit_arr
    or edx,edx
    jz flush_next_unit
;
    push ecx
    lea edi,[4*ebx+edx].disc_sector_arr
    mov eax,ebp
    sub eax,ebx
    cmp eax,ecx
    ja flush_sector_loop
;
    mov ecx,eax

flush_sector_loop:
    xor eax,eax
    repe scas dword ptr es:[edi]
    sub edi,4
    xchg eax,es:[edi]
    or eax,eax
    jz flush_unit_done
;
    push edi
    mov edi,eax
    call free_handle
    pop edi
    sub es:[edx].disc_sectors,1
    jnz flush_sector_loop
;
    mov ds:[4*esi].disc_unit_arr,0
    movzx ecx,ds:disc_sectors_per_unit
    inc ecx
    shl ecx,2
    add ecx,OFFSET disc_sector_arr
    FreeLinear
    xor ecx,ecx

flush_unit_done:
    mov eax,ebp
    sub eax,ebx
    sub eax,ecx
    pop ecx
    sub ecx,eax
    jz flush_leave
;
    xor ebx,ebx
    inc esi
    mov eax,ds:disc_units
    cmp esi,eax
    jb flush_loop
    jmp flush_leave

flush_next_unit:
    mov edx,ebp
    sub edx,ebx
    sub ecx,edx
    jbe flush_leave
;
    xor ebx,ebx
    inc esi
    mov eax,ds:disc_units
    cmp esi,eax
    jb flush_loop
    jmp flush_leave

flush_leave:
    LeaveSection ds:disc_section
;
    popad
    pop es
    pop ds
    retf32
flush_drive     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDriveParam
;
;           DESCRIPTION:    Get drive param
;
;           PARAMETERS:         AL          Drive #
;
;           RETURNS:        EAX         Readahead
;                           ECX         Size
;                           SI          Sectors per unit
;                           EDI         Units
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_drive_param_name    DB 'Get Drive Param',0

get_drive_param PROC far
    push ds
    push bx
    push edx
;
    cmp al,MAX_DRIVES
    jnc get_drive_param_fail
;
    movzx bx,al
    shl bx,1
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:[bx].drive_def_arr
    cmp ax,-1
    je get_drive_param_fail
;
    mov ds,ax
    mov ax,ds:drive_disc
    or ax,ax
    jz get_drive_param_fail
;
    mov ds,ax
    mov ax,ds:disc_bytes_per_sector
    mov dx,ds:disc_sectors_per_unit
    mul dx
    push dx
    push ax
    pop eax
    mov edx,ds:disc_units
    mul edx
    or edx,edx
    jz get_param_size_ok
;
    mov eax,-1

get_param_size_ok:
    mov ecx,eax
    mov eax,ds:disc_readahead
    mov si,ds:disc_sectors_per_unit
    mov edi,ds:disc_units
    clc
    jmp get_drive_param_done

get_drive_param_fail:
    xor eax,eax
    xor ecx,ecx
    xor si,si
    xor edi,edi
    stc

get_drive_param_done:
    pop edx
    pop bx
    pop ds
    retf32
get_drive_param ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckDrive
;
;           DESCRIPTION:    Check drive
;
;           PARAMETERS:     AL              Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_drive_name  DB 'Check Drive', 0

check_drive   Proc far
    push ds
    push eax
    push edx
    push esi
;
    mov si,SEG data
    mov ds,si
    EnterSection ds:disc_handler_section
;
    movzx si,al
    shl si,1

chRetry:
    push ds
    mov dx,fs_sys_data_sel
    mov ds,dx
    mov dx,ds:[si]
    pop ds
    or dx,dx
    jnz chIsDefined
;
    CheckVfsDrive
    jnc chDone
;
    push ax
    GetSystemTime
    sub eax,ds:init_timeout
    sbb edx,ds:init_timeout+4
    pop ax
    cmc
    jc chDone
;
    LeaveSection ds:disc_handler_section
;
    push ax
    mov ax,50
    WaitMilliSec
    pop ax
;
    EnterSection ds:disc_handler_section
    jmp chRetry

chIsDefined:
    cmp dx,-1
    clc
    jnz chDone
;
    mov ax,si
    shr ax,1
    DemandLoadDrive
    jmp chRetry

chDone:
    LeaveSection ds:disc_handler_section
;
    pop esi
    pop edx
    pop eax
    pop ds
    retf32
check_drive   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NEW_SECTOR
;
;           DESCRIPTION:    Create a new sector cache entry without reading
;
;           PARAMETERS:         AL          Drive #
;                           EDX         Sector #
;
;           RETURNS:        EBX         Handle
;                           ESI         Logical address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

new_sector_name DB 'New Sector',0

new_sector      PROC far
    push ds
    push es
    push ax
    push ecx
    push edx
    push edi
;
    movzx bx,al
    shl bx,1
    mov ax,SEG data
    mov ds,ax
    mov ds,ds:[bx].drive_def_arr
    mov ax,flat_sel
    mov es,ax
    cmp edx,ds:drive_sectors
    jc new_inrange
;
    stc
    jmp new_leave

new_inrange:
    add edx,ds:drive_start_sector
    mov ds,ds:drive_disc
    push edx
    pop ax
    pop dx
    div ds:disc_sectors_per_unit
    movzx ecx,ax
    EnterSection ds:disc_section

new_loop:
    call check_buf
    jnc new_done
;
    call allocate_handle
    push edx
    call allocate_data
    mov es:[edi].dh_data,edx
    pop edx
    mov es:[edi].dh_buf_sel,ds
    mov es:[edi].dh_sector,dx
    movzx ecx,cx
    mov es:[edi].dh_unit,ecx
    mov es:[edi].dh_wait,0
    mov es:[edi].dh_thread,0
    mov es:[edi].dh_lock_count,0
    mov es:[edi].dh_state,STATE_USED
    mov es:[edi].dh_usage,0
    mov es:[edi].dh_flags,0
    mov es:[edi].dh_time_lsb,0
    call insert_buf

new_done:
    inc es:[edi].dh_lock_count
    LeaveSection ds:disc_section
    mov esi,es:[edi].dh_data
    mov ebx,edi

new_leave:
    pop edi
    pop edx
    pop ecx
    pop ax
    pop es
    pop ds
    retf32
new_sector      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LOCK_SECTOR
;
;           DESCRIPTION:    Lock sector and return address
;
;           PARAMETERS:         AL          Drive #
;                           EDX         Sector #
;
;           RETURNS:        EBX         Handle
;                           ESI         Logical address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_sector_name    DB 'Lock Sector',0

lock_sector     PROC far
    push ds
    push es
    push eax
    push ecx
    push edx
    push edi
;
    movzx bx,al
    shl bx,1
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:[bx].drive_def_arr
    or ax,ax
    stc
    jz lock_done
;
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    cmp edx,ds:drive_sectors
    jc lock_inrange
;
    stc
    jmp lock_done

lock_inrange:
    add edx,ds:drive_start_sector
    mov ds,ds:drive_disc
    call wait_pending
;
    push edx
    pop ax
    pop dx
    div ds:disc_sectors_per_unit
    movzx ecx,ax
    EnterSection ds:disc_section

lock_loop:
    call check_buf
    jnc lock_found
;
    ClearSignal
    call allocate_handle
    push edx
    call allocate_data
    mov es:[edi].dh_data,edx
    pop edx
    mov es:[edi].dh_buf_sel,ds
    mov es:[edi].dh_sector,dx
    movzx ecx,cx
    mov es:[edi].dh_unit,ecx
    mov es:[edi].dh_wait,0
    mov es:[edi].dh_thread,0
    mov es:[edi].dh_lock_count,0
    mov es:[edi].dh_state,STATE_EMPTY
    mov es:[edi].dh_usage,0
    mov es:[edi].dh_flags,0
    mov es:[edi].dh_time_lsb,0
    mov es:[edi].dh_flags,0
    call insert_buf
    call insert_pending

lock_read_ahead:
    push dx
    push edi
    inc dx
    cmp dx,ds:disc_sectors_per_unit
    je lock_read_ahead_done
;
    call check_buf
    jnc lock_read_ahead_done
    jmp lock_read_ahead_done
;
    call allocate_handle
    push edx
    call allocate_data
    mov es:[edi].dh_data,edx
    pop edx
    mov es:[edi].dh_buf_sel,ds
    mov es:[edi].dh_sector,dx
    mov es:[edi].dh_unit,ecx
    mov es:[edi].dh_wait,0
    mov es:[edi].dh_thread,0
    mov es:[edi].dh_lock_count,0
    mov es:[edi].dh_state,STATE_EMPTY
    mov es:[edi].dh_usage,0
    mov es:[edi].dh_flags,FLAGS_READ_AHEAD
    mov es:[edi].dh_time_lsb,0
    call insert_buf
    call insert_pending
    
lock_read_ahead_done:
    pop edi
    pop dx

lock_read_signal:
    test es:[edi].dh_flags,FLAGS_READ_AHEAD
    jz lock_read_check_empty
;
    and es:[edi].dh_flags, NOT FLAGS_READ_AHEAD
    jmp lock_read_ahead

lock_read_check_empty:
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    clc
    jne lock_found

lock_read_block:
    call block
    jmp lock_loop

lock_found:
    test es:[edi].dh_flags, FLAG_IO_BUSY
    jnz lock_read_block
;
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    je lock_read_signal
;       
    inc es:[edi].dh_lock_count
    inc es:[edi].dh_usage
    LeaveSection ds:disc_section
    mov al,es:[edi].dh_state
    cmp al,STATE_USED
    je lock_get_adds
;
    cmp al,STATE_DIRTY
    je lock_get_adds
;
    cmp al,STATE_SEQ
    je lock_get_adds
;
    stc
    jmp lock_done

lock_get_adds:
    mov esi,es:[edi].dh_data
    mov ebx,edi

lock_done:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    retf32
lock_sector     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MODIFY_SECTOR
;
;           DESCRIPTION:    Modify sector contents
;
;           PARAMETERS:         EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

modify_sector_name      DB 'Modify Sector',0

modify_sector   PROC far
    push ds
    push es
    pushad
;
    mov ax,flat_sel
    mov es,ax
    mov edi,ebx
    mov ds,es:[edi].dh_buf_sel
    call wait_pending
    ClearSignal
    EnterSection ds:disc_section

ifdef DEBUG     
    call CheckBuffered
endif

modify_try_again:
    test es:[edi].dh_flags, FLAG_IO_BUSY
    jz modify_not_busy
;
    call block
    jmp modify_try_again

modify_not_busy:
    mov al,es:[edi].dh_state
    cmp al,STATE_USED
    jne modify_done

modify_clean:
    mov es:[edi].dh_state,STATE_DIRTY
;       
    test es:[edi].dh_flags, FLAG_IO_PENDING
    jnz modify_done
;
    GetSystemTime
    mov es:[edi].dh_time_lsb,eax
    call insert_async_write
    call update_async_timer

modify_done:
    LeaveSection ds:disc_section
    clc
;
    popad
    pop es
    pop ds
    retf32
modify_sector   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FLUSH_SECTOR
;
;           DESCRIPTION:    Flush sector contents
;
;           PARAMETERS:         EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_sector_name       DB 'Flush Sector',0

flush_sector    PROC far
    push ds
    push es
    pushad
;
    mov ax,flat_sel
    mov es,ax
    mov edi,ebx
    mov ds,es:[edi].dh_buf_sel
    ClearSignal
    EnterSection ds:disc_section

ifdef DEBUG
    call CheckBuffered
endif

flush_try_again:
    test es:[edi].dh_flags, FLAG_IO_BUSY
    jz flush_not_busy

flush_block:
    call block
    jmp flush_try_again

flush_not_busy:
    mov al,es:[edi].dh_state
    cmp al,STATE_DIRTY
    jne flush_done

flush_dirty:
    call flush_async_write
    mov bx,ds:disc_thread
    Signal

flush_done:
    LeaveSection ds:disc_section
    clc
;
    popad
    pop es
    pop ds
    retf32
flush_sector    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CREATE_DISC_SEQ
;
;           DESCRIPTION:    Create a sequence
;
;           PARAMETERS:         CX          Max number of sectors in sequence
;
;           RETURNS:        AX          Sequence handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_disc_seq_name    DB 'Create Disc Seq',0

create_disc_seq PROC far
    push es
    push ecx
    push edi
;
    movzx ecx,cx
    movzx eax,cx
    lea eax,[4*eax].dss_arr
    AllocateSmallGlobalMem
    mov edi,OFFSET dss_arr
    xor eax,eax
    rep stos dword ptr es:[edi]
    mov es:dss_buf_sel,0
    mov es:dss_insert_index,0
    mov es:dss_perform_index,0
    mov ax,es
;
    pop edi
    pop ecx
    pop es
    retf32
create_disc_seq ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MODIFY_SEQ_SECTOR
;
;           DESCRIPTION:    Modify sequential sector contents
;
;           PARAMETERS:     AX              Seq handle
;                           EBX             Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

modify_seq_sector_name  DB 'Modify Seq Sector',0

modify_seq_sector       PROC far
    push ds
    push es
    push fs
    pushad
;
    mov fs,ax
    mov ax,flat_sel
    mov es,ax
    mov edi,ebx
    mov ds,es:[edi].dh_buf_sel
    ClearSignal
    EnterSection ds:disc_section

ifdef DEBUG     
    call CheckBuffered
endif

modify_seq_try_again:
    test es:[edi].dh_flags, FLAG_IO_BUSY
    jz modify_seq_not_busy

modify_seq_block:
    call block
    jmp modify_seq_try_again

modify_seq_not_busy:
    mov al,es:[edi].dh_state
    cmp al,STATE_USED
    jne modify_seq_block

modify_seq_clean:
    mov es:[edi].dh_state,STATE_SEQ
    mov bx,fs:dss_insert_index
    shl bx,2
    mov fs:[bx].dss_arr,edi
    inc fs:dss_insert_index
    mov fs:dss_buf_sel,ds

modify_seq_done:
    LeaveSection ds:disc_section
    clc
;
    popad
    pop fs
    pop es
    pop ds
    retf32
modify_seq_sector       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PERFORM_DISC_SEQ
;
;           DESCRIPTION:    Perform a sequence
;
;           PARAMETERS:         AX              Sequence handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

perform_disc_seq_name   DB 'Perform Disc Seq',0

perform_disc_seq    PROC far
    push ds
    push es
    push eax
    push ebx
;
    mov es,ax
    mov ax,es:dss_buf_sel
    or ax,ax
    jz perform_disc_fail
;
    mov ds,ax
    EnterSection ds:disc_section
;
    mov bx,ds:disc_seq_list
    or bx,bx
    je perform_disc_empty
;
    push ds
    push si
    mov ds,bx
    mov si,ds:dss_prev
    mov ds:dss_prev,es
    mov ds,si
    mov ds:dss_next,es
    mov es:dss_next,bx
    mov es:dss_prev,si
    pop si
    pop ds
    jmp perform_disc_do

perform_disc_empty:
    mov es:dss_next,es
    mov es:dss_prev,es
    mov ds:disc_seq_list,es

perform_disc_do:
    mov ax,flat_sel
    mov es,ax
    call update_disc_seq
    jmp perform_disc_leave

perform_disc_fail:
    FreeMem
    stc
    jmp perform_disc_done

perform_disc_leave:
    LeaveSection ds:disc_section
    mov bx,ds:disc_thread
    Signal
    clc

perform_disc_done:
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
perform_disc_seq    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UNLOCK_SECTOR
;
;           DESCRIPTION:    UNlock sector
;
;           PARAMETERS:         EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_sector_name      DB 'Unlock Sector',0

unlock_sector   PROC far
    push ds
    push es
    push eax
    push edi
;
    mov ax,flat_sel
    mov es,ax
    mov edi,ebx
    mov ds,es:[edi].dh_buf_sel
    EnterSection ds:disc_section

ifdef DEBUG     
    call CheckBuffered
endif

    sub es:[edi].dh_lock_count,1
    jnz unlock_done
;
    test es:[edi].dh_flags, FLAG_EXT_DATA
    jz unlock_done
;
    test es:[edi].dh_flags, BUSY_FLAGS
    jnz unlock_done
;
    cmp es:[edi].dh_state, STATE_USED
    jne unlock_done
;    
    call remove_buf
    mov es:[edi].dh_state, STATE_EMPTY
    mov eax,ds:disc_handle_list
    mov es:[edi],eax
    mov ds:disc_handle_list,edi
    dec ds:disc_cached_sectors

ifdef DEBUG     
    call CheckAll
endif

unlock_done:
    LeaveSection ds:disc_section
    xor ebx,ebx
;
    pop edi
    pop eax
    pop es
    pop ds
    clc
    retf32
unlock_sector   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReqSector
;
;           DESCRIPTION:    Request a sector, but don't block
;
;           PARAMETERS:         AL          Drive #
;                           EDX         Sector #
;                           ESI         Logical address of buffer
;
;           RETURNS:        EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_sector_name DB 'Req Sector',0

req_sector      PROC far
    push ds
    push es
    push ax
    push ecx
    push edx
    push edi
;
    movzx bx,al
    shl bx,1
    mov ax,SEG data
    mov ds,ax
    mov ds,ds:[bx].drive_def_arr
    mov ax,flat_sel
    mov es,ax
    cmp edx,ds:drive_sectors
    jc req_inrange
;
    stc
    jmp req_done

req_inrange:
    add edx,ds:drive_start_sector
    mov ds,ds:drive_disc
    call wait_pending
    call fixup_data
;
    push edx
    pop ax
    pop dx
    div ds:disc_sectors_per_unit
    movzx ecx,ax
    EnterSection ds:disc_section

req_loop:
    call check_buf
    jnc req_found
;
    call allocate_handle
    mov es:[edi].dh_data,esi
    mov es:[edi].dh_buf_sel,ds
    mov es:[edi].dh_sector,dx
    movzx ecx,cx
    mov es:[edi].dh_unit,ecx
    mov es:[edi].dh_wait,0
    mov es:[edi].dh_thread,0
    mov es:[edi].dh_lock_count,0
    mov es:[edi].dh_state,STATE_EMPTY
    mov es:[edi].dh_usage,0
    mov es:[edi].dh_time_lsb,0
    mov es:[edi].dh_flags,FLAG_EXT_DATA
    call insert_buf
    call insert_pending
    jmp req_ok

req_read_signal:
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    clc
    jne req_found

req_read_block:
    call block
    jmp req_loop

req_found:
    test es:[edi].dh_flags, FLAG_IO_BUSY
    jnz req_read_block
;
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    je req_read_signal
;
    mov edx,es:[edi].dh_data
    cmp edx,esi
    je req_ok
;
    or edx,edx
    jz req_new_save
;
    movzx ecx,ds:disc_bytes_per_sector
    shr ecx,2
    push esi
    push edi
    mov edi,esi
    mov esi,edx
    rep movs dword ptr es:[edi],es:[esi]
    pop edi
    pop esi
;
    test es:[edi].dh_flags, FLAG_EXT_DATA
    jnz req_new_save
;
    call free_data

req_new_save:
    mov es:[edi].dh_data,esi
    or es:[edi].dh_flags,FLAG_EXT_DATA
    
req_ok:
    inc es:[edi].dh_lock_count
    inc es:[edi].dh_usage
    LeaveSection ds:disc_section
;
    mov bx,ds:disc_thread
    Signal
    clc
    mov ebx,edi

req_done:
    pop edi
    pop edx
    pop ecx
    pop ax
    pop es
    pop ds
    retf32
req_sector      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DefineSector
;
;           DESCRIPTION:    Define sector contents, don't block or read
;
;           PARAMETERS:         AL          Drive #
;                           EDX         Sector #
;                           ESI         Logical address of buffer
;
;           RETURNS:        EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define_sector_name      DB 'Define Sector',0

define_sector   PROC far
    push ds
    push es
    push ax
    push ecx
    push edx
    push edi
;
    movzx bx,al
    shl bx,1
    mov ax,SEG data
    mov ds,ax
    mov ds,ds:[bx].drive_def_arr
    mov ax,flat_sel
    mov es,ax
    cmp edx,ds:drive_sectors
    jc define_inrange
;
    stc
    jmp define_done

define_inrange:
    add edx,ds:drive_start_sector
    mov ds,ds:drive_disc
    call fixup_data
;    
    push edx
    pop ax
    pop dx
    div ds:disc_sectors_per_unit
    movzx ecx,ax
    EnterSection ds:disc_section

define_loop:
    call check_buf
    jnc define_found
;
    ClearSignal
    call allocate_handle
    mov es:[edi].dh_data,esi
    mov es:[edi].dh_buf_sel,ds
    mov es:[edi].dh_sector,dx
    movzx ecx,cx
    mov es:[edi].dh_unit,ecx
    mov es:[edi].dh_wait,0
    mov es:[edi].dh_thread,0
    mov es:[edi].dh_lock_count,0
    mov es:[edi].dh_state,STATE_USED
    mov es:[edi].dh_usage,0
    mov es:[edi].dh_time_lsb,0
    mov es:[edi].dh_flags,FLAG_EXT_DATA
    call insert_buf
    jmp define_found

define_read_signal:
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    clc
    jne define_found

define_read_block:
    call block
    jmp define_loop

define_found:
    test es:[edi].dh_flags, FLAG_IO_BUSY
    jnz define_read_block
;
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    je define_read_signal
;
    mov edx,es:[edi].dh_data
    cmp edx,esi
    je define_ok
;
    or edx,edx
    jz define_new_save
;
    movzx ecx,ds:disc_bytes_per_sector
    shr ecx,2
    push esi
    push edi
    mov edi,esi
    mov esi,edx
    rep movs dword ptr es:[edi],es:[esi]
    pop edi
    pop esi
;
    test es:[edi].dh_flags, FLAG_EXT_DATA
    jnz define_new_save
;
    call free_data

define_new_save:
    mov es:[edi].dh_data,esi
    or es:[edi].dh_flags,FLAG_EXT_DATA
    
define_ok:
    inc es:[edi].dh_lock_count
    inc es:[edi].dh_usage
    LeaveSection ds:disc_section
    mov al,es:[edi].dh_state
    cmp al,STATE_USED
    je define_valid
;
    cmp al,STATE_DIRTY
    je define_valid
;
    cmp al,STATE_SEQ
    je define_valid
;
    stc
    jmp define_done

define_valid:
    mov ebx,edi
    clc

define_done:
    pop edi
    pop edx
    pop ecx
    pop ax
    pop es
    pop ds
    retf32
define_sector   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForSector
;
;           DESCRIPTION:    Wait until sector is idle
;
;           PARAMETERS:         AL          Drive #
;                           EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_sector_name    DB 'Wait For Sector',0

wait_for_sector PROC far
    push ds
    push es
    push ax
    push edi
;
    mov ax,flat_sel
    mov es,ax
    mov edi,ebx
    mov ds,es:[edi].dh_buf_sel
    EnterSection ds:disc_section

ifdef DEBUG     
    call CheckBuffered
endif

wait_sector_loop:
    cmp es:[edi].dh_state,STATE_EMPTY
    je wait_sector_block
;
    cmp es:[edi].dh_state,STATE_SEQ
    je wait_sector_block
;
    cmp es:[edi].dh_state,STATE_DIRTY
    clc
    jne wait_sector_found

wait_sector_block:
    call block
    jmp wait_sector_loop

wait_sector_found:
    LeaveSection ds:disc_section
    clc
;
    pop edi
    pop ax
    pop es
    pop ds
    retf32
wait_for_sector ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetDrive
;
;           DESCRIPTION:    Try to reset drive
;
;           PARAMETERS:         AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_drive_name    DB 'Reset Disc',0

reset_drive     PROC far
    push ds
    push ax
    push bx
;
    movzx bx,al
    shl bx,1
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:[bx].drive_def_arr
    or ax,ax
    jz reset_drive_done
;
    mov ds,ax
    mov bx,ds:disc_thread
    Signal

reset_drive_done:
    pop bx
    pop ax
    pop ds
    retf32
reset_drive     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_OLD_DISC_INFO
;
;           DESCRIPTION:    Get 32-bit disc info
;
;           PARAMETERS:     AL              Disc #
;
;           RETURNS;        CX              Bytes / sector
;                           EDX             Total sectors
;                           SI              BIOS sectors / cylinder
;                           DI              BIOS heads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_old_disc_info_name      DB 'Get Old Disc Info',0

get_old_disc_info   PROC far
    push ds
    push eax
    push bx
;
    cmp al,MAX_DRIVES
    jae get_old_disc_info_fail
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    add bx,bx
    mov bx,ds:[bx].disc_def_arr
    or bx,bx
    jz get_old_disc_info_fail
;
    mov ds,bx
    mov edx,ds:disc_total_sectors
    mov cx,ds:disc_bytes_per_sector
    mov si,ds:disc_sectors_per_cyl
    mov di,ds:disc_heads
    clc
    jmp get_old_disc_info_done

get_old_disc_info_fail:
    xor cx,cx
    xor edx,edx
    xor si,si
    xor di,di
    stc

get_old_disc_info_done:
    pop bx
    pop eax
    pop ds  
    retf32
get_old_disc_info   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_DISC_INFO
;
;           DESCRIPTION:    Get disc info
;
;           PARAMETERS:     AL              Disc #
;
;           RETURNS;        CX              Bytes / sector
;                           EDX:EAX         Total sectors
;                           SI              BIOS sectors / cylinder
;                           DI              BIOS heads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disc_info_name      DB 'Get Disc Info',0

get_disc_info   PROC far
    push ds
    push bx
;
    cmp al,MAX_DRIVES
    jae get_disc_info_fail
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    add bx,bx
    mov bx,ds:[bx].disc_def_arr
    or bx,bx
    jz get_disc_info_fail
;
    cmp bx,-1
    je get_disc_info_new
;
    mov ds,bx
    mov eax,ds:disc_total_sectors
    mov edx,ds:disc_total_sectors+4
    mov cx,ds:disc_bytes_per_sector
    mov si,ds:disc_sectors_per_cyl
    mov di,ds:disc_heads
    clc
    jmp get_disc_info_done

get_disc_info_new:
    GetVfsDiscInfo
    jmp get_disc_info_done

get_disc_info_fail:
    xor cx,cx
    xor eax,eax
    xor edx,edx
    xor si,si
    xor di,di
    stc

get_disc_info_done:
    pop bx
    pop ds  
    retf32
get_disc_info   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_DISC_INFO
;
;           DESCRIPTION:    Set disc info
;
;           PARAMETERS:     AL              Disc #
;                           CX              Bytes / sector
;                           EDX             Total sectors
;                           SI              BIOS sectors / cylinder
;                           DI              BIOS heads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_disc_info_name      DB 'Set Disc Info',0

set_disc_info   PROC far
    push ds
    push eax
    push ebx
    push edx
;
    cmp al,MAX_DRIVES
    jae set_disc_info_fail
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    add bx,bx
    mov bx,ds:[bx].disc_def_arr
    or bx,bx
    jz set_disc_info_fail
;
    push bx
    mov ax,si
    push edx
    mul di
    movzx ebx,ax
    pop eax
    xor edx,edx
    div ebx
    mov dx,bx
    pop bx
    xchg ax,dx
    movzx edx,dx
    SetDiscParam
    clc
    jmp set_disc_info_done

set_disc_info_fail:
    stc

set_disc_info_done:
    pop edx
    pop ebx
    pop eax
    pop ds  
    retf32
set_disc_info   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_DISC_CACHE_SIZE
;
;           DESCRIPTION:    Get disc cache size
;
;           PARAMETERS:     AL              Disc #
;                           EAX             Cached sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disc_cache_size_name      DB 'Get Disc Cache Size',0

get_disc_cache_size   PROC far
    push ds
    push ebx
;
    cmp al,MAX_DRIVES
    jae get_disc_cache_size_fail
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    add bx,bx
    mov bx,ds:[bx].disc_def_arr
    or bx,bx
    jz get_disc_cache_size_fail
;
    cmp bx,-1
    je get_disc_cache_size_fail
;
    mov ds,bx
    mov eax,ds:disc_cached_sectors
    clc
    jmp get_disc_cache_size_done

get_disc_cache_size_fail:
    stc

get_disc_cache_size_done:
    pop ebx
    pop ds  
    retf32
get_disc_cache_size   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_DISC_VENDOR_INFO
;
;           DESCRIPTION:    Get disc vendor info
;
;           PARAMETERS:     AL              Disc #
;                           ES:(E)DI        Vendor buffer
;                           (E)CX           Buffer size
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disc_vendor_info_name      DB 'Get Disc Vendor Info',0

get_disc_vendor_info   PROC near
    push ds
    push ecx
    push edx
    push esi
    push edi
;
    cmp al,MAX_DRIVES
    jae get_disc_vendor_info_done
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    add bx,bx
    mov bx,ds:[bx].disc_def_arr
    or bx,bx
    stc
    jz get_disc_vendor_info_done
;
    cmp bx,-1
    jne get_disc_vendor_normal
;
    GetVfsDiscVendorInfo
    jmp get_disc_vendor_info_done

get_disc_vendor_normal:
    sub ecx,1
    jbe get_disc_vendor_info_done
;
    cmp ecx,255
    jb get_disc_vendor_info_size_ok
;
    mov ds,bx
    mov si,OFFSET disc_vendor_str
    mov ecx,255

get_disc_vendor_info_size_ok:
    xor edx,edx

get_disc_vendor_info_copy:
    lodsb
    or al,al
    jz get_disc_vendor_eob
;
    inc edx
    stos byte ptr es:[edi]
    loop get_disc_vendor_info_copy

get_disc_vendor_eob:    

get_disc_vendor_info_trim:
    sub edx,1
    jbe get_disc_vendor_info_term    
;
    mov al,es:[edi-1]
    cmp al,' '
    jne get_disc_vendor_info_term 
;       
    sub edi,1
    jmp get_disc_vendor_info_trim

get_disc_vendor_info_term:
    xor al,al
    stos byte ptr es:[edi]
    clc

get_disc_vendor_info_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ds
    ret
get_disc_vendor_info   Endp

get_disc_vendor_info16  Proc far
    push ecx
    push edi
    movzx edi,di
    movzx ecx,cx
    call get_disc_vendor_info
    pop edi
    pop ecx
    retf32
get_disc_vendor_info16  Endp

get_disc_vendor_info32  Proc far
    call get_disc_vendor_info
    retf32
get_disc_vendor_info32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadShortDisc
;
;           DESCRIPTION:    Read disc, 32-bit version
;
;           PARAMETERS:     AL              Disc #
;                           EDX             Sector #
;                           (E)CX       Size
;                           ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_short_disc_name  DB 'Read Short Disc',0

read_short_disc       PROC near
    push ds
    push es
    pushad
;
    cmp al,MAX_DRIVES
    jae read_short_disc_fail
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    add bx,bx
    mov bx,ds:[bx].disc_def_arr
    or bx,bx
    jz read_short_disc_fail
;
    mov ds,bx
    push ds
    push es
    push ecx
    push edi
;
    mov ax,flat_sel
    mov es,ax
    push edx
    pop ax
    pop dx
    div ds:disc_sectors_per_unit
    movzx ecx,ax
    call wait_pending
    EnterSection ds:disc_section

read_short_disc_loop:
    call check_buf
    jnc read_short_disc_found
;
    ClearSignal
    call allocate_handle
    push edx
    call allocate_data
    mov es:[edi].dh_data,edx
    pop edx
    mov es:[edi].dh_buf_sel,ds
    mov es:[edi].dh_sector,dx
    movzx ecx,cx
    mov es:[edi].dh_unit,ecx
    mov es:[edi].dh_wait,0
    mov es:[edi].dh_thread,0
    mov es:[edi].dh_lock_count,0
    mov es:[edi].dh_state,STATE_EMPTY
    mov es:[edi].dh_usage,0
    mov es:[edi].dh_flags,0
    mov es:[edi].dh_time_lsb,0
    mov es:[edi].dh_flags,0
    call insert_buf
    call insert_pending

read_short_disc_signal:
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    clc
    jne read_short_disc_found

read_short_disc_block:
    call block
    jmp read_short_disc_loop

read_short_disc_found:
    test es:[edi].dh_flags, FLAG_IO_BUSY
    jnz read_short_disc_block
;
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    je read_short_disc_signal
;       
    mov esi,es:[edi].dh_data
    mov ax,es
    mov ds,ax
    pop edi
    pop ecx
    pop es
;
    shr ecx,2
    rep movs dword ptr es:[edi],ds:[esi]
    pop ds
    LeaveSection ds:disc_section
    clc
    jmp read_short_disc_done

read_short_disc_fail:
    stc

read_short_disc_done:
    popad
    pop es
    pop ds
    ret
read_short_disc       ENDP

read_short_disc32     Proc far
    call read_short_disc
    retf32
read_short_disc32     Endp

read_short_disc16     Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call read_short_disc
;
    pop edi
    pop ecx
    retf32
read_short_disc16     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteShortDisc
;
;           DESCRIPTION:    Write disc, 32-bit version
;
;           PARAMETERS:     AL              Disc #
;                           EDX             Sector #
;                           (E)CX       Size
;                           ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_short_disc_name DB 'Write Short Disc',0

write_short_disc      PROC near
    push ds
    push es
    pushad
;
    cmp al,MAX_DRIVES
    jae write_short_disc_fail
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    add bx,bx
    mov bx,ds:[bx].disc_def_arr
    or bx,bx
    jz write_short_disc_fail
;
    mov ds,bx
    push ds
    push es
    push ecx
    push edi
;
    mov ax,flat_sel
    mov es,ax
    push edx
    pop ax
    pop dx
    div ds:disc_sectors_per_unit
    movzx ecx,ax
    call wait_pending
    EnterSection ds:disc_section

write_short_disc_loop:
    call check_buf
    jnc write_short_disc_found
;
    ClearSignal
    call allocate_handle
    push edx
    call allocate_data
    mov es:[edi].dh_data,edx
    pop edx
    mov es:[edi].dh_buf_sel,ds
    mov es:[edi].dh_sector,dx
    movzx ecx,cx
    mov es:[edi].dh_unit,ecx
    mov es:[edi].dh_wait,0
    mov es:[edi].dh_thread,0
    mov es:[edi].dh_lock_count,0
    mov es:[edi].dh_state,STATE_EMPTY
    mov es:[edi].dh_usage,0
    mov es:[edi].dh_flags,0
    mov es:[edi].dh_time_lsb,0
    mov es:[edi].dh_flags,0
    call insert_buf
    call insert_pending

write_short_disc_signal:
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    clc
    jne write_short_disc_found

write_short_disc_block:
    call block
    jmp write_short_disc_loop

write_short_disc_found:
    test es:[edi].dh_flags, FLAG_IO_BUSY
    jnz write_short_disc_block
;
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    je write_short_disc_signal
;       
    mov ebx,edi
    mov edi,es:[edi].dh_data
    pop esi
    pop ecx
    pop ds
;
    shr ecx,2
    rep movs dword ptr es:[edi],ds:[esi]
;
    mov edi,ebx
    pop ds
    GetSystemTime
    mov es:[edi].dh_time_lsb,eax
    mov es:[edi].dh_state,STATE_DIRTY
    call insert_async_write
    call update_async_timer
    LeaveSection ds:disc_section
    clc
    jmp write_short_disc_done

write_short_disc_fail:
    stc

write_short_disc_done:
    popad
    pop es
    pop ds
    ret
write_short_disc      ENDP

write_short_disc32    Proc far
    call write_short_disc
    retf32
write_short_disc32    Endp

write_short_disc16    Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call write_short_disc
;
    pop edi
    pop ecx
    retf32
write_short_disc16    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLongDisc
;
;           DESCRIPTION:    Read disc, 64-bit version
;
;           PARAMETERS:     BL          Disc #
;                           EDX:EAX     Sector #
;                           (E)CX       Size
;                           ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_long_disc_name  DB 'Read Long Disc',0

read_long_disc       PROC near
    push ds
    push es
    pushad
;
    cmp bl,MAX_DRIVES
    jae read_long_disc_fail
;
    mov si,SEG data
    mov ds,si
    movzx si,bl
    add si,si
    mov si,ds:[si].disc_def_arr
    or si,si
    jz read_long_disc_fail
;
    cmp si,-1
    jne read_long_disc_norm
;
    ReadVfsDisc
    jmp read_long_disc_done

read_long_disc_norm:
    mov ds,si
    push ds
    push es
    push ecx
    push edi
;
    mov bx,flat_sel
    mov es,bx
    movzx ebx,ds:disc_sectors_per_unit    
    div ebx
    mov ecx,eax
    call wait_pending
    EnterSection ds:disc_section

read_long_disc_loop:
    call check_buf
    jnc read_long_disc_found
;
    ClearSignal
    call allocate_handle
    push edx
    call allocate_data
    mov es:[edi].dh_data,edx
    pop edx
    mov es:[edi].dh_buf_sel,ds
    mov es:[edi].dh_sector,dx
    movzx ecx,cx
    mov es:[edi].dh_unit,ecx
    mov es:[edi].dh_wait,0
    mov es:[edi].dh_thread,0
    mov es:[edi].dh_lock_count,0
    mov es:[edi].dh_state,STATE_EMPTY
    mov es:[edi].dh_usage,0
    mov es:[edi].dh_flags,0
    mov es:[edi].dh_time_lsb,0
    mov es:[edi].dh_flags,0
    call insert_buf
    call insert_pending

read_long_disc_signal:
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    clc
    jne read_long_disc_found

read_long_disc_block:
    call block
    jmp read_long_disc_loop

read_long_disc_found:
    test es:[edi].dh_flags, FLAG_IO_BUSY
    jnz read_long_disc_block
;
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    je read_long_disc_signal
;       
    mov esi,es:[edi].dh_data
    mov ax,es
    mov ds,ax
    pop edi
    pop ecx
    pop es
;
    shr ecx,2
    rep movs dword ptr es:[edi],ds:[esi]
    pop ds
    LeaveSection ds:disc_section
    clc
    jmp read_long_disc_done

read_long_disc_fail:
    stc

read_long_disc_done:
    popad
    pop es
    pop ds
    ret
read_long_disc       ENDP

read_long_disc32     Proc far
    call read_long_disc
    retf32
read_long_disc32     Endp

read_long_disc16     Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call read_long_disc
;
    pop edi
    pop ecx
    retf32
read_long_disc16     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteLongDisc
;
;           DESCRIPTION:    Write disc, 64-bit version
;
;           PARAMETERS:     BL          Disc #
;                           EDX:EAX     Sector #
;                           (E)CX       Size
;                           ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_long_disc_name DB 'Write Long Disc',0

write_long_disc      PROC near
    push ds
    push es
    pushad
;
    cmp bl,MAX_DRIVES
    jae write_long_disc_fail
;
    mov si,SEG data
    mov ds,si
    movzx si,bl
    add si,si
    mov si,ds:[si].disc_def_arr
    or si,si
    jz write_long_disc_fail
;
    cmp si,-1
    jne write_long_disc_norm
;
    WriteVfsDisc
    jmp write_long_disc_done

write_long_disc_norm:
    mov ds,si
    push ds
    push es
    push ecx
    push edi
;
    mov bx,flat_sel
    mov es,bx
    movzx ebx,ds:disc_sectors_per_unit    
    div ebx
    mov ecx,eax
    call wait_pending
    EnterSection ds:disc_section

write_long_disc_loop:
    call check_buf
    jnc write_long_disc_found
;
    ClearSignal
    call allocate_handle
    push edx
    call allocate_data
    mov es:[edi].dh_data,edx
    pop edx
    mov es:[edi].dh_buf_sel,ds
    mov es:[edi].dh_sector,dx
    movzx ecx,cx
    mov es:[edi].dh_unit,ecx
    mov es:[edi].dh_wait,0
    mov es:[edi].dh_thread,0
    mov es:[edi].dh_lock_count,0
    mov es:[edi].dh_state,STATE_DIRTY
    mov es:[edi].dh_usage,0
    mov es:[edi].dh_flags,0
    mov es:[edi].dh_time_lsb,0
    call insert_buf
    jmp write_long_disc_found

write_long_disc_signal:
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    clc
    jne write_long_disc_found

write_long_disc_block:
    call block
    jmp write_long_disc_loop

write_long_disc_found:
    test es:[edi].dh_flags, FLAG_IO_BUSY
    jnz write_long_disc_block
;       
    mov ebx,edi
    mov edi,es:[edi].dh_data
    pop esi
    pop ecx
    pop ds
;
    shr ecx,2
    rep movs dword ptr es:[edi],ds:[esi]
;
    mov edi,ebx
    pop ds
    GetSystemTime
    mov es:[edi].dh_time_lsb,eax
    mov es:[edi].dh_state,STATE_DIRTY
    call insert_async_write
    call update_async_timer
    LeaveSection ds:disc_section
    clc
    jmp write_long_disc_done

write_long_disc_fail:
    stc

write_long_disc_done:
    popad
    pop es
    pop ds
    ret
write_long_disc      ENDP

write_long_disc32    Proc far
    call write_long_disc
    retf32
write_long_disc32    Endp

write_long_disc16    Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call write_long_disc
;
    pop edi
    pop ecx
    retf32
write_long_disc16    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDriveDiscParam
;
;           DESCRIPTION:    Get disc parameters for drive
;
;           PARAMETERS:         AL              Drive #
;
;       RETURNS:    AL      Disc #
;               ECX     Total number of sectors
;               EDX     Start sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_drive_disc_param_name       DB 'Get Drive Disc Param',0

get_drive_disc_param    Proc far
    push ds
    push bx
;
    movzx bx,al
    shl bx,1
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:[bx].drive_def_arr
    or ax,ax
    stc
    jz get_drive_disc_param_done
;
    cmp ax,-1
    stc
    je get_drive_disc_param_done
;
    mov ds,ax   
    mov ecx,ds:drive_sectors
    mov edx,ds:drive_start_sector
    mov ds,ds:drive_disc
    mov al,ds:disc_nr
    clc

get_drive_disc_param_done:
    pop bx
    pop ds      
    retf32
get_drive_disc_param    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           BeginDiscHandler
;
;           DESCRIPTION:    Begin a disc-handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

begin_disc_handler_name     DB 'Begin Disc Handler',0

begin_disc_handler  Proc far
    push ds
    push ax
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:disc_handler_section
    inc ds:disc_handlers
    LeaveSection ds:disc_handler_section
    pop ax
    pop ds
    retf32
begin_disc_handler  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EndDiscHandler
;
;           DESCRIPTION:    End a disc-handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

end_disc_handler_name     DB 'End Disc Handler',0

end_disc_handler  Proc far
    push ds
    push ax
    push bx
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:disc_handler_section
    sub ds:disc_handlers,1
    jnz edhDone
;
    mov bx,ds:disc_handler_thread
    Signal

edhDone:
    LeaveSection ds:disc_handler_section
    pop bx
    pop ax
    pop ds
    retf32
end_disc_handler  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DEMAND_LOAD_DRIVE
;
;           DESCRIPTION:    Run demand-load for disc exporting drive
;
;           PARAMETERS:         AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

demand_load_drive_name  DB 'Demand Load Drive', 0

demand_load_drive       Proc far
    push ds
    pushad
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    add bx,bx
    mov ax,[bx].drive_def_arr
    or ax,ax
    jz demand_load_drive_fail
;
    cmp ax,-1
    je demand_load_drive_fail
;
    mov ds,ax
    mov ds,ds:drive_disc
    mov bx,ds:disc_handle
    call fword ptr ds:disc_demand_mount_proc
    jmp demand_load_drive_done

demand_load_drive_fail:
    stc

demand_load_drive_done:
    popad
    pop ds
    retf32
demand_load_drive       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadDiscSector
;
;           DESCRIPTION:    Read disc sector
;
;           PARAMETERS:     GS          Disc sel
;                           EDX:EAX     Sector #
;                           ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadDiscSector PROC near
    push ds
    pushad
;
    test gs:disc_flags,DISC_FLAG_STOPPED
    stc
    jnz rdsDone
;
    push es
    push ecx
    push edi
;
    mov bx,gs
    mov ds,bx
;
    mov bx,flat_sel
    mov es,bx
;
    movzx ebx,ds:disc_sectors_per_unit    
    div ebx
    mov ecx,eax
    call wait_pending
    EnterSection ds:disc_section

rdsLoop:
    call check_buf
    jnc rdsFound
;
    ClearSignal
    call allocate_handle
    push edx
    call allocate_data
    mov es:[edi].dh_data,edx
    pop edx
    mov es:[edi].dh_buf_sel,ds
    mov es:[edi].dh_sector,dx
    movzx ecx,cx
    mov es:[edi].dh_unit,ecx
    mov es:[edi].dh_wait,0
    mov es:[edi].dh_thread,0
    mov es:[edi].dh_lock_count,0
    mov es:[edi].dh_state,STATE_EMPTY
    mov es:[edi].dh_usage,0
    mov es:[edi].dh_flags,0
    mov es:[edi].dh_time_lsb,0
    mov es:[edi].dh_flags,0
    call insert_buf
    call insert_pending

rdsSignal:
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    jne rdsFound

rdsBlock:
    test gs:disc_flags,DISC_FLAG_STOPPED
    jnz rdsFail
;
    call block
    jmp rdsLoop

rdsFail:
    pop edi
    pop ecx
    pop es
    stc
    jmp rdsDone

rdsFound:
    test es:[edi].dh_flags, FLAG_IO_BUSY
    jnz rdsBlock
;
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    je rdsSignal
;       
    mov esi,es:[edi].dh_data
    mov ax,es
    mov ds,ax
    pop edi
    pop ecx
    pop es
;
    mov ecx,80h
    rep movs dword ptr es:[edi],ds:[esi]
;
    mov bx,gs
    mov ds,bx
    LeaveSection ds:disc_section
    clc

rdsDone:
    popad
    pop ds
    ret
ReadDiscSector       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AllocEfiDrive
;
;   DESCRIPTION:    Allocate EFI system drive
;
;   RETURNS:        AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocEfiDrive   Proc near
    push ds
    push cx
    push si
;
    push ax
    mov ax,SEG data
    mov ds,ax
    mov si,OFFSET drive_def_arr
    mov cx,MAX_DRIVES
;
    mov ax,[si+2]
    or ax,ax
    jz aedTakeB
;
    cmp ax,-1
    jz aedTakeB

aedLoop:
    mov ax,[si]
    or ax,ax
    jnz aedNext
;
    mov word ptr [si],-1
    mov cx,si
    sub cx,OFFSET drive_def_arr
    shr cx,1
    pop ax
    mov al,cl
    clc
    jmp aedDone

aedTakeB:
    pop ax
    mov word ptr [si+2],-1
    mov al,1
    clc
    jmp aedDone
    
aedNext:
    add si,2
    loop aedLoop
;
    pop ax
    stc

aedDone:
    pop si
    pop cx
    pop ds
    ret
AllocEfiDrive   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AllocStaticDrive
;
;   DESCRIPTION:    Allocate static drive
;
;   RETURNS:        AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocStaticDrive   Proc near
    push ds
    push cx
    push si
;
    push ax
    mov ax,SEG data
    mov ds,ax
    mov si,OFFSET drive_def_arr + 4
    mov cx,MAX_DRIVES - 2

asdLoop:
    mov ax,[si]
    or ax,ax
    jnz asdNext
;
    mov word ptr [si],-1
    mov cx,si
    sub cx,OFFSET drive_def_arr
    shr cx,1
    pop ax
    mov al,cl
    clc
    jmp asdDone
    
asdNext:
    add si,2
    loop asdLoop
;
    pop ax
    stc

asdDone:
    pop si
    pop cx
    pop ds
    ret
AllocStaticDrive   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AllocDynamicDrive
;
;   DESCRIPTION:    Allocate dynamic drive
;
;   RETURNS:        AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocDynamicDrive  Proc near
    push ds
    push cx
    push si
;
    push ax
    mov ax,SEG data
    mov ds,ax
    mov si,OFFSET drive_def_arr + 2 * (MAX_DRIVES - 1)
    mov cx,MAX_DRIVES

addLoop:
    mov ax,[si]
    or ax,ax
    jnz addNext
;
    mov word ptr [si],-1
    mov cx,si
    sub cx,OFFSET drive_def_arr
    shr cx,1
    pop ax
    mov al,cl
    clc
    jmp addDone
    
addNext:
    sub si,2
    loop addLoop
;
    pop ax
    stc
    
addDone:
    pop si
    pop cx
    pop ds
    ret
AllocDynamicDrive  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateEfiDrive
;
;       DESCRIPTION:    Create EFI system drive
;
;       PARAMETERS:     GS      Disc sel
;                       EDX     Start sector
;                       ECX     Number of sectors
;                       ES:EDI  File system name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateEfiDrive  Proc near
    push eax
;
    IsFileSystemAvailable
    jc cedDone
;    
    test gs:disc_flags,DISC_FLAG_DYNAMIC
    jnz cedDyn
;    
    test gs:disc_flags,DISC_FLAG_INSTALLED
    jz cedStatic

cedDyn:
    call AllocDynamicDrive
    jmp cedOpen

cedStatic:
    call AllocEfiDrive

cedOpen:
    jc cedDone
;
    mov ah,gs:disc_nr
    OpenDrive
;
    InstallFileSystem
    StartFileSystem
    clc

cedDone:
    pop eax
    ret
CreateEfiDrive  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateDrive
;
;       DESCRIPTION:    Create drive
;
;       PARAMETERS:     GS      Disc sel
;                       EDX     Start sector
;                       ECX     Number of sectors
;                       ES:EDI  File system name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDrive  Proc near
    push eax
;
    IsFileSystemAvailable
    jc cndDone
;    
    test gs:disc_flags,DISC_FLAG_DYNAMIC
    jnz cndDyn
;
    test gs:disc_flags,DISC_FLAG_INSTALLED
    jz cndStatic

cndDyn:
    call AllocDynamicDrive
    jmp cndOpen

cndStatic:
    call AllocStaticDrive

cndOpen:
    jc cndDone
;
    mov ah,gs:disc_nr
    OpenDrive
;
    InstallFileSystem
    StartFileSystem
    clc

cndDone:
    pop eax
    ret
CreateDrive  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ChsToLba
;
;       DESCRIPTION:    Convert CHS to LBA
;
;       PARAMETERS:     GS	 Disc sel
;                       ES:EDI   CHS address
;
;       RETURNS:        EDX      LBA address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChsToLba    Proc near
    push eax
    push ecx
;
    mov ax,gs:disc_heads
    cmp ax,-1
    je chs_to_lba_fail
;
    mov cl,es:[edi+2]
    movzx ax,byte ptr es:[edi+1]
    and al,0C0h
    shl ax,2
    mov ch,ah
    cmp cx,1023
    je chs_to_lba_fail
;
    movzx eax,gs:disc_heads
    movzx ecx,cx
    mul ecx
    movzx ecx,byte ptr es:[edi]
    add ecx,eax
    movzx eax,gs:disc_sectors_per_cyl
    mul ecx
    movzx ecx,byte ptr es:[edi+1]
    and cl,3Fh
    add eax,ecx
    dec eax
    mov edx,eax
    jmp chs_to_lba_done

chs_to_lba_fail:
    xor edx,edx

chs_to_lba_done:
    pop ecx
    pop eax
    ret
ChsToLba    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       InstallPartition
;
;       DESCRIPTION:    Install partition
;
;       PARAMETERS:     GS      Disc sel
;                       ES      flat sel
;                       CL      Partition type
;                       EDX     Start sector
;                       EAX     Number of sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fs_unknown      DB 'UNKNOWN '
fs_fat12        DB 'FAT12   '
fs_fat16        DB 'FAT16   '
fs_fat32        DB 'FAT32   '
fs_hpfs         DB 'HPFS    '
fs_rdfs         DB 'RDFS    '
fs_flashfs      DB 'FLASHFS '

FsTab:
fs00    DW OFFSET fs_unknown
fs01    DW OFFSET fs_fat12
fs02    DW OFFSET fs_unknown
fs03    DW OFFSET fs_unknown
fs04    DW OFFSET fs_fat16
fs05    DW OFFSET fs_unknown
fs06    DW OFFSET fs_fat16
fs07    DW OFFSET fs_hpfs
fs08    DW OFFSET fs_unknown
fs09    DW OFFSET fs_unknown
fs0A    DW OFFSET fs_unknown
fs0B    DW OFFSET fs_fat32
fs0C    DW OFFSET fs_fat32
fs0D    DW OFFSET fs_unknown
fs0E    DW OFFSET fs_unknown
fs0F    DW OFFSET fs_unknown
fs10    DW OFFSET fs_unknown
fs11    DW OFFSET fs_unknown
fs12    DW OFFSET fs_unknown
fs13    DW OFFSET fs_unknown
fs14    DW OFFSET fs_unknown
fs15    DW OFFSET fs_unknown
fs16    DW OFFSET fs_unknown
fs17    DW OFFSET fs_unknown
fs18    DW OFFSET fs_unknown
fs19    DW OFFSET fs_unknown
fs1A    DW OFFSET fs_unknown
fs1B    DW OFFSET fs_unknown
fs1C    DW OFFSET fs_unknown
fs1D    DW OFFSET fs_unknown
fs1E    DW OFFSET fs_unknown
fs1F    DW OFFSET fs_unknown
fs20    DW OFFSET fs_unknown
fs21    DW OFFSET fs_unknown
fs22    DW OFFSET fs_unknown
fs23    DW OFFSET fs_unknown
fs24    DW OFFSET fs_unknown
fs25    DW OFFSET fs_unknown
fs26    DW OFFSET fs_unknown
fs27    DW OFFSET fs_unknown
fs28    DW OFFSET fs_unknown
fs29    DW OFFSET fs_unknown
fs2A    DW OFFSET fs_unknown
fs2B    DW OFFSET fs_unknown
fs2C    DW OFFSET fs_unknown
fs2D    DW OFFSET fs_unknown
fs2E    DW OFFSET fs_unknown
fs2F    DW OFFSET fs_unknown
fs30    DW OFFSET fs_unknown
fs31    DW OFFSET fs_unknown
fs32    DW OFFSET fs_unknown
fs33    DW OFFSET fs_unknown
fs34    DW OFFSET fs_unknown
fs35    DW OFFSET fs_unknown
fs36    DW OFFSET fs_unknown
fs37    DW OFFSET fs_unknown
fs38    DW OFFSET fs_unknown
fs39    DW OFFSET fs_unknown
fs3A    DW OFFSET fs_unknown
fs3B    DW OFFSET fs_unknown
fs3C    DW OFFSET fs_unknown
fs3D    DW OFFSET fs_unknown
fs3E    DW OFFSET fs_unknown
fs3F    DW OFFSET fs_unknown
fs40    DW OFFSET fs_unknown
fs41    DW OFFSET fs_unknown
fs42    DW OFFSET fs_unknown
fs43    DW OFFSET fs_unknown
fs44    DW OFFSET fs_unknown
fs45    DW OFFSET fs_unknown
fs46    DW OFFSET fs_unknown
fs47    DW OFFSET fs_unknown
fs48    DW OFFSET fs_unknown
fs49    DW OFFSET fs_unknown
fs4A    DW OFFSET fs_unknown
fs4B    DW OFFSET fs_unknown
fs4C    DW OFFSET fs_unknown
fs4D    DW OFFSET fs_unknown
fs4E    DW OFFSET fs_unknown
fs4F    DW OFFSET fs_unknown
fs50    DW OFFSET fs_unknown
fs51    DW OFFSET fs_unknown
fs52    DW OFFSET fs_unknown
fs53    DW OFFSET fs_unknown
fs54    DW OFFSET fs_unknown
fs55    DW OFFSET fs_unknown
fs56    DW OFFSET fs_unknown
fs57    DW OFFSET fs_unknown
fs58    DW OFFSET fs_unknown
fs59    DW OFFSET fs_unknown
fs5A    DW OFFSET fs_unknown
fs5B    DW OFFSET fs_unknown
fs5C    DW OFFSET fs_unknown
fs5D    DW OFFSET fs_unknown
fs5E    DW OFFSET fs_unknown
fs5F    DW OFFSET fs_unknown
fs60    DW OFFSET fs_unknown
fs61    DW OFFSET fs_unknown
fs62    DW OFFSET fs_unknown
fs63    DW OFFSET fs_unknown
fs64    DW OFFSET fs_unknown
fs65    DW OFFSET fs_unknown
fs66    DW OFFSET fs_unknown
fs67    DW OFFSET fs_unknown
fs68    DW OFFSET fs_unknown
fs69    DW OFFSET fs_unknown
fs6A    DW OFFSET fs_unknown
fs6B    DW OFFSET fs_unknown
fs6C    DW OFFSET fs_unknown
fs6D    DW OFFSET fs_unknown
fs6E    DW OFFSET fs_unknown
fs6F    DW OFFSET fs_unknown
fs70    DW OFFSET fs_unknown
fs71    DW OFFSET fs_unknown
fs72    DW OFFSET fs_unknown
fs73    DW OFFSET fs_unknown
fs74    DW OFFSET fs_unknown
fs75    DW OFFSET fs_unknown
fs76    DW OFFSET fs_unknown
fs77    DW OFFSET fs_unknown
fs78    DW OFFSET fs_unknown
fs79    DW OFFSET fs_unknown
fs7A    DW OFFSET fs_unknown
fs7B    DW OFFSET fs_unknown
fs7C    DW OFFSET fs_unknown
fs7D    DW OFFSET fs_unknown
fs7E    DW OFFSET fs_unknown
fs7F    DW OFFSET fs_unknown
fs80    DW OFFSET fs_unknown
fs81    DW OFFSET fs_unknown
fs82    DW OFFSET fs_unknown
fs83    DW OFFSET fs_unknown
fs84    DW OFFSET fs_unknown
fs85    DW OFFSET fs_unknown
fs86    DW OFFSET fs_unknown
fs87    DW OFFSET fs_unknown
fs88    DW OFFSET fs_unknown
fs89    DW OFFSET fs_unknown
fs8A    DW OFFSET fs_unknown
fs8B    DW OFFSET fs_unknown
fs8C    DW OFFSET fs_unknown
fs8D    DW OFFSET fs_unknown
fs8E    DW OFFSET fs_unknown
fs8F    DW OFFSET fs_unknown
fs90    DW OFFSET fs_unknown
fs91    DW OFFSET fs_unknown
fs92    DW OFFSET fs_unknown
fs93    DW OFFSET fs_unknown
fs94    DW OFFSET fs_unknown
fs95    DW OFFSET fs_unknown
fs96    DW OFFSET fs_unknown
fs97    DW OFFSET fs_unknown
fs98    DW OFFSET fs_unknown
fs99    DW OFFSET fs_unknown
fs9A    DW OFFSET fs_unknown
fs9B    DW OFFSET fs_unknown
fs9C    DW OFFSET fs_unknown
fs9D    DW OFFSET fs_unknown
fs9E    DW OFFSET fs_unknown
fs9F    DW OFFSET fs_unknown
fsA0    DW OFFSET fs_unknown
fsA1    DW OFFSET fs_unknown
fsA2    DW OFFSET fs_unknown
fsA3    DW OFFSET fs_unknown
fsA4    DW OFFSET fs_unknown
fsA5    DW OFFSET fs_unknown
fsA6    DW OFFSET fs_unknown
fsA7    DW OFFSET fs_unknown
fsA8    DW OFFSET fs_unknown
fsA9    DW OFFSET fs_unknown
fsAA    DW OFFSET fs_unknown
fsAB    DW OFFSET fs_unknown
fsAC    DW OFFSET fs_unknown
fsAD    DW OFFSET fs_unknown
fsAE    DW OFFSET fs_rdfs
fsAF    DW OFFSET fs_flashfs
fsB0    DW OFFSET fs_unknown
fsB1    DW OFFSET fs_unknown
fsB2    DW OFFSET fs_unknown
fsB3    DW OFFSET fs_unknown
fsB4    DW OFFSET fs_unknown
fsB5    DW OFFSET fs_unknown
fsB6    DW OFFSET fs_unknown
fsB7    DW OFFSET fs_unknown
fsB8    DW OFFSET fs_unknown
fsB9    DW OFFSET fs_unknown
fsBA    DW OFFSET fs_unknown
fsBB    DW OFFSET fs_unknown
fsBC    DW OFFSET fs_unknown
fsBD    DW OFFSET fs_unknown
fsBE    DW OFFSET fs_unknown
fsBF    DW OFFSET fs_unknown
fsC0    DW OFFSET fs_unknown
fsC1    DW OFFSET fs_unknown
fsC2    DW OFFSET fs_unknown
fsC3    DW OFFSET fs_unknown
fsC4    DW OFFSET fs_unknown
fsC5    DW OFFSET fs_unknown
fsC6    DW OFFSET fs_unknown
fsC7    DW OFFSET fs_unknown
fsC8    DW OFFSET fs_unknown
fsC9    DW OFFSET fs_unknown
fsCA    DW OFFSET fs_unknown
fsCB    DW OFFSET fs_unknown
fsCC    DW OFFSET fs_unknown
fsCD    DW OFFSET fs_unknown
fsCE    DW OFFSET fs_unknown
fsCF    DW OFFSET fs_unknown
fsD0    DW OFFSET fs_unknown
fsD1    DW OFFSET fs_unknown
fsD2    DW OFFSET fs_unknown
fsD3    DW OFFSET fs_unknown
fsD4    DW OFFSET fs_unknown
fsD5    DW OFFSET fs_unknown
fsD6    DW OFFSET fs_unknown
fsD7    DW OFFSET fs_unknown
fsD8    DW OFFSET fs_unknown
fsD9    DW OFFSET fs_unknown
fsDA    DW OFFSET fs_unknown
fsDB    DW OFFSET fs_unknown
fsDC    DW OFFSET fs_unknown
fsDD    DW OFFSET fs_unknown
fsDE    DW OFFSET fs_unknown
fsDF    DW OFFSET fs_unknown
fsE0    DW OFFSET fs_unknown
fsE1    DW OFFSET fs_unknown
fsE2    DW OFFSET fs_unknown
fsE3    DW OFFSET fs_unknown
fsE4    DW OFFSET fs_unknown
fsE5    DW OFFSET fs_unknown
fsE6    DW OFFSET fs_unknown
fsE7    DW OFFSET fs_unknown
fsE8    DW OFFSET fs_unknown
fsE9    DW OFFSET fs_unknown
fsEA    DW OFFSET fs_unknown
fsEB    DW OFFSET fs_unknown
fsEC    DW OFFSET fs_unknown
fsED    DW OFFSET fs_unknown
fsEE    DW OFFSET fs_unknown
fsEF    DW OFFSET fs_unknown
fsF0    DW OFFSET fs_unknown
fsF1    DW OFFSET fs_unknown
fsF2    DW OFFSET fs_unknown
fsF3    DW OFFSET fs_unknown
fsF4    DW OFFSET fs_unknown
fsF5    DW OFFSET fs_unknown
fsF6    DW OFFSET fs_unknown
fsF7    DW OFFSET fs_unknown
fsF8    DW OFFSET fs_unknown
fsF9    DW OFFSET fs_unknown
fsFA    DW OFFSET fs_unknown
fsFB    DW OFFSET fs_unknown
fsFC    DW OFFSET fs_unknown
fsFD    DW OFFSET fs_unknown
fsFE    DW OFFSET fs_unknown
fsFF    DW OFFSET fs_unknown

InstallPartition    Proc near
    push es
    pushad
;
    cmp cl,7
    je install_check_part
;
    cmp cl,0Ch
    jne install_check_type

install_check_part:
    push eax
;
    push edx
    mov eax,200h
    AllocateSmallLinear
    mov edi,edx
    pop edx
;
    push edx
    mov eax,edx
    xor edx,edx
    call ReadDiscSector
    pop edx
;
    push ds
    push edx
;
    mov al,es:[edi+26h]
    cmp al,29h
    je install_use_part_fat
;
    mov ax,cs
    mov ds,ax
    movzx esi,cl
    shl si,1
    mov si,cs:[si].FsTab
    jmp install_use_part_cont

install_use_part_fat:
    mov ax,flat_sel
    mov ds,ax
    lea esi,[edi+36h]

install_use_part_cont:
    mov edx,edi
    mov eax,10h
    AllocateSmallGlobalMem
    xor edi,edi
    movs dword ptr es:[edi],ds:[esi]
    movs dword ptr es:[edi],ds:[esi]
    movs dword ptr es:[edi],ds:[esi]
    movs dword ptr es:[edi],ds:[esi]
;
    xor ecx,ecx
    FreeLinear
;
    pop edx
    pop ds
;
    pop ecx
    xor edi,edi
    call CreateDrive

install_part_free:
    pushf
    FreeMem
    popf
    jmp install_part_done

install_check_type:
    mov di,cs
    mov es,di
    movzx di,cl
    shl di,1

install_part_test_avail:
    mov ecx,eax
    mov di,word ptr cs:[di].FsTab
    movzx edi,di
    call CreateDrive

install_part_done:
    popad
    pop es
    ret
InstallPartition    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InstallExtended
;
;       DESCRIPTION:    Install extended partion on drive
;
;       PARAMETERS:     ES      Flat sel
;                       GS      Disc sel
;                       EDX     Current sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallExtended Proc near
    mov ebp,edx
    mov eax,1000h
    AllocateBigLinear
    mov edi,edx
    mov es:[edi],eax
;
    mov eax,ebp
    xor edx,edx
    call ReadDiscSector
    jc install_ext_done
;
    mov esi,1BEh

install_ext_loop1:
    mov cl,es:[esi+edi].part_type
    or cl,cl
    jz install_ext_next_part1
;
    cmp cl,5
    je install_ext_next_part1
;
    cmp cl,0Fh
    je install_ext_next_part1
;
    push ebp
    push edi
;
    lea edi,[esi+edi+1]
    call ChsToLba
    or edx,edx
    jnz install_ext_do
;
    mov edx,es:[edi+7]
    add edx,ebp

install_ext_do:
    call InstallPartition
;
    pop edi
    pop ebp

install_ext_next_part1:
    add si,10h
    cmp si,1FEh
    jne install_ext_loop1
;
    mov esi,1BEh

install_ext_loop2:
    mov cl,es:[esi+edi].part_type
    or cl,cl
    jz install_ext_next_part2
;
    cmp cl,5
    je install_ext_install2
;
    cmp cl,0Fh
    jne install_ext_next_part2

install_ext_install2:
    push esi
    push edi
    push ebp
;
    lea edi,[esi+edi+1]
    call ChsToLba
    or edx,edx
    jnz install_ext_link
;
    mov edx,es:[edi+7]
    add edx,ebp

install_ext_link:
    call InstallExtended
;
    pop ebp
    pop edi
    pop esi

install_ext_next_part2:
    add si,10h
    cmp si,1FEh
    jne install_ext_loop2

install_ext_done:
    mov ecx,1000h
    mov edx,edi
    FreeLinear
    ret
InstallExtended Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetFsName
;
;       DESCRIPTION:    Get MS FS name from boot record
;
;       PARAMETERS:     GS      Disc sel
;                       ES:EDI  GPT Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFsName   Proc near
    push ds
    push es
    pushad
;
    mov eax,1000h
    AllocateBigLinear
    mov esi,edx
    mov ebp,edx
    mov es:[edx],eax
;
    mov eax,es:[edi].gpe_first_lba
    mov edx,es:[edi].gpe_first_lba+4
    mov edi,esi
    call ReadDiscSector
;
    mov ax,gs
    mov es,ax
    mov ax,flat_sel
    mov ds,ax
    mov di,OFFSET disc_fs_name
;
    mov al,ds:[esi+3]
    cmp al,'M'
    je gfnDos
;
    cmp al,'m'
    je gfnLinux    
;
    cmp al,'R'
    je gfnLinux    
;
    add esi,3
    jmp gfnCopyName

gfnLinux:
    add esi,36h
    jmp gfnCopyName

gfnDos:
    add esi,52h

gfnCopyName:
    mov cx,8

gfnCopyLoop:    
    mov al,ds:[esi]
    or al,al
    jz gfnCopyDone
;
    cmp al,' '
    jz gfnCopyDone
;
    stosb
    inc si
    loop gfnCopyLoop    

gfnCopyDone:
    xor al,al
    stosb
;    
    mov edx,ebp
    mov ecx,1000h
    FreeLinear
;
    popad
    pop es    
    pop ds
    ret
GetFsName   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetEfiName
;
;       DESCRIPTION:    Get EFI system part name
;
;       PARAMETERS:     GS      Disc sel
;                       ES:EDI  GPT Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetEfiName   Proc near
    push es
    pushad
;
    mov ax,gs
    mov es,ax
    mov si,OFFSET fs_fat32
    mov di,OFFSET disc_fs_name
    mov cx,8

genCopyLoop:    
    mov al,cs:[esi]
    or al,al
    jz genCopyDone
;
    cmp al,' '
    jz genCopyDone
;
    stosb
    inc si
    loop genCopyLoop    

genCopyDone:
    xor al,al
    stosb
;
    popad
    pop es    
    ret
GetEfiName   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InstallEfiPart
;
;       DESCRIPTION:    Install EFI part
;
;       PARAMETERS:     GS      Disc sel
;                       ES:EDI  Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallEfiPart    Proc near
    call GetEfiName
;    
    push ds
    push es
    pushad
;
    mov edx,es:[edi].gpe_first_lba
    mov ecx,es:[edi].gpe_last_lba
    sub ecx,edx
    inc ecx
;
    mov di,gs
    mov es,di
    mov edi,OFFSET disc_fs_name
    call CreateEfiDrive
;
    popad
    pop es    
    pop ds
    ret
InstallEfiPart  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InstallBasicPart
;
;       DESCRIPTION:    Install basic part
;
;       PARAMETERS:     GS      Disc sel
;                       ES:EDI  Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallBasicPart    Proc near
    call GetFsName
;    
    push ds
    push es
    pushad
;
    mov edx,es:[edi].gpe_first_lba
    mov ecx,es:[edi].gpe_last_lba
    sub ecx,edx
    inc ecx
;
    mov di,gs
    mov es,di
    mov edi,OFFSET disc_fs_name
    call CreateDrive
;
    popad
    pop es    
    pop ds
    ret
InstallBasicPart  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InstallEfiGptEntry
;
;       DESCRIPTION:    Install EFI GPT entry
;
;       PARAMETERS:     GS      Disc sel
;                       ES:EDI  Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallEfiGptEntry    Proc near
    mov eax,dword ptr es:[edi].gpe_part_guid
    cmp eax,0C12A7328h
    jne iegpeDone
;
    mov eax,dword ptr es:[edi].gpe_part_guid+4
    cmp eax,11D2F81Fh
    jne iegpeDone
;    
    mov eax,dword ptr es:[edi].gpe_part_guid+8
    cmp eax,0A0004BBAh
    jne iegpeDone
;    
    mov eax,dword ptr es:[edi].gpe_part_guid+12
    cmp eax,3BC93EC9h
    jne iegpeDone
;
    call InstallEfiPart

iegpeDone:    
    ret
InstallEfiGptEntry     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InstallStdGptEntry
;
;       DESCRIPTION:    Install non-EFI GPT entry
;
;       PARAMETERS:     GS      Disc sel
;                       ES:EDI  Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallStdGptEntry    Proc near
    mov eax,dword ptr es:[edi].gpe_part_guid
    cmp eax,0EBD0A0A2h
    jne isgpeDone
;
    mov eax,dword ptr es:[edi].gpe_part_guid+4
    cmp eax,4433B9E5h
    jne isgpeDone
;    
    mov eax,dword ptr es:[edi].gpe_part_guid+8
    cmp eax,0B668C087h
    jne isgpeDone
;    
    mov eax,dword ptr es:[edi].gpe_part_guid+12
    cmp eax,0C79926B7h
    jne isgpeDone
;
    call InstallBasicPart

isgpeDone:    
    ret
InstallStdGptEntry     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InstallGpt1
;
;       DESCRIPTION:    Install GPT partition, first pass
;
;       PARAMETERS:     GS      Disc sel
;                       ES      flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallGpt1    Proc near
    push es
    pushad
;
    xor ebp,ebp
    mov ax,flat_sel
    mov es,ax
;
    mov eax,1000h
    AllocateBigLinear    
    mov edi,edx
    mov es:[edi],eax
;    
    mov eax,1
    xor edx,edx
    call ReadDiscSector
    jc igptDone1
;
    mov eax,dword ptr es:[edi].gpt_sign
    cmp eax,20494645h
    jne igptDone1
;
    mov eax,dword ptr es:[edi].gpt_sign+4
    cmp eax,54524150h
    jne igptDone1
;
    xor edx,edx
    xchg edx,es:[edi].gpt_crc32
    mov ecx,es:[edi].gpt_header_size
    cmp ecx,200h
    jae igptDone1
;    
    mov eax,-1
    UserGateForce32 calc_crc32_nr
    cmp eax,edx
    jne igptDone1
;    
    mov eax,es:[edi].gpt_entry_size
    cmp eax,128
    jne igptDone1
;
    mov eax,es:[edi].gpt_entry_lba+4
    or eax,eax
    jnz igptDone1   
;
    mov ecx,es:[edi].gpt_entry_count
    mov eax,ecx
    shl eax,7
    dec eax
    and ax,0F000h
    add eax,1000h
    AllocateBigLinear    
    mov ebp,edx
;
    push edx
    push edi
;
    mov ecx,eax
    shr ecx,9
    mov eax,es:[edi].gpt_entry_lba
    mov edx,es:[edi].gpt_entry_lba+4
    mov edi,ebp

igptSectorLoop1:
    mov es:[edi],edx
    call ReadDiscSector
;
    inc eax
    add edi,200h
    loop igptSectorLoop1
;
    pop edi
    pop edx
;
    push edi
;    
    mov ecx,es:[edi].gpt_entry_count
    shl ecx,7
    mov edi,ebp
    mov eax,-1
    UserGateForce32 calc_crc32_nr
;    
    pop edi
;
    cmp eax,es:[edi].gpt_entry_crc32
    jne igptDone1
;
    push edi
    mov ecx,es:[edi].gpt_entry_count
    mov edi,ebp
    or ecx,ecx
    jz igptEntryDone1

igptEntryLoop1:
    mov eax,es:[edi].gpe_last_lba+4
    or eax,eax
    jnz igptEntryNext1
;
    mov eax,es:[edi].gpe_first_lba+4
    or eax,eax
    jnz igptEntryNext1
;
    mov eax,es:[edi].gpe_first_lba
    or eax,eax
    jz igptEntryNext1
;
    mov edx,es:[edi].gpe_last_lba
    sub edx,eax
    jc igptEntryNext1
;
    call InstallEfiGptEntry

igptEntryNext1:
    add edi,128 
    sub ecx,1
    jnz igptEntryLoop1

igptEntryDone1:     
    pop edi
    
igptDone1:
    or ebp,ebp
    jz igptEnd1
;
    mov ecx,es:[edi].gpt_entry_count
    shl ecx,7
    mov edx,ebp
    FreeLinear
        
igptEnd1:
    mov ecx,1000h
    mov edx,edi
    FreeLinear
;
    popad
    pop es
    ret
InstallGpt1    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InstallGpt2
;
;       DESCRIPTION:    Install GPT partition, second pass
;
;       PARAMETERS:     GS      Disc sel
;                       ES      flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallGpt2    Proc near
    push es
    pushad
;
    xor ebp,ebp
    mov ax,flat_sel
    mov es,ax
;
    mov eax,1000h
    AllocateBigLinear    
    mov edi,edx
    mov es:[edi],eax
;    
    mov eax,1
    xor edx,edx
    call ReadDiscSector
    jc igptDone2
;
    mov eax,dword ptr es:[edi].gpt_sign
    cmp eax,20494645h
    jne igptDone2
;
    mov eax,dword ptr es:[edi].gpt_sign+4
    cmp eax,54524150h
    jne igptDone2
;
    xor edx,edx
    xchg edx,es:[edi].gpt_crc32
    mov ecx,es:[edi].gpt_header_size
    cmp ecx,200h
    jae igptDone2
;    
    mov eax,-1
    UserGateForce32 calc_crc32_nr
    cmp eax,edx
    jne igptDone2
;    
    mov eax,es:[edi].gpt_entry_size
    cmp eax,128
    jne igptDone2
;
    mov eax,es:[edi].gpt_entry_lba+4
    or eax,eax
    jnz igptDone2
;
    mov ecx,es:[edi].gpt_entry_count
    mov eax,ecx
    shl eax,7
    dec eax
    and ax,0F000h
    add eax,1000h
    AllocateBigLinear    
    mov ebp,edx
;
    push edx
    push edi
;
    mov ecx,eax
    shr ecx,9
    mov eax,es:[edi].gpt_entry_lba
    mov edx,es:[edi].gpt_entry_lba+4
    mov edi,ebp

igptSectorLoop2:
    mov es:[edi],edx
    call ReadDiscSector
;
    inc eax
    add edi,200h
    loop igptSectorLoop2
;
    pop edi
    pop edx
;
    push edi
;    
    mov ecx,es:[edi].gpt_entry_count
    shl ecx,7
    mov edi,ebp
    mov eax,-1
    UserGateForce32 calc_crc32_nr
;    
    pop edi
;
    cmp eax,es:[edi].gpt_entry_crc32
    jne igptDone2
;
    push edi
    mov ecx,es:[edi].gpt_entry_count
    mov edi,ebp
    or ecx,ecx
    jz igptEntryDone2

igptEntryLoop2:
    mov eax,es:[edi].gpe_last_lba+4
    or eax,eax
    jnz igptEntryNext2
;
    mov eax,es:[edi].gpe_first_lba+4
    or eax,eax
    jnz igptEntryNext2
;
    mov eax,es:[edi].gpe_first_lba
    or eax,eax
    jz igptEntryNext2
;
    mov edx,es:[edi].gpe_last_lba
    sub edx,eax
    jc igptEntryNext2
;
    call InstallStdGptEntry

igptEntryNext2:
    add edi,128 
    sub ecx,1
    jnz igptEntryLoop2   

igptEntryDone2:     
    pop edi
    
igptDone2:
    or ebp,ebp
    jz igptEnd2
;
    mov ecx,es:[edi].gpt_entry_count
    shl ecx,7
    mov edx,ebp
    FreeLinear
        
igptEnd2:
    mov ecx,1000h
    mov edx,edi
    FreeLinear
;
    popad
    pop es
    ret
InstallGpt2    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Assign1
;
;       DESCRIPTION:    assign disc drives, step 1
;
;       PARAMETERS:     GS     Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Assign1   Proc near
    mov eax,1000h
    AllocateBigLinear
    xor al,al
    mov es:[edx],al
    mov edi,edx
;    
    xor eax,eax
    xor edx,edx
    call ReadDiscSector
    jc aFree1
;
    mov esi,1BEh

aLoop1:
    mov cl,es:[esi+edi].part_type
    or cl,cl
    jz aFree1
;
    cmp cl,0EEh
    je aGpt1
;
    push edi
;
    mov eax,es:[esi+edi].part_sectors
    lea edi,[esi+edi+1]
    call ChsToLba
    or edx,edx
    jnz aInst1
;
    mov edx,es:[edi+7]

aInst1:
    call InstallPartition
;
    pop edi
    jmp aNextPart1

aGpt1:
    call InstallGpt1

aNextPart1:
    add si,10h
    cmp si,1FEh
    jne aLoop1

aFree1:
    mov ecx,1000h
    mov edx,edi
    FreeLinear
;
    ret
Assign1   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Assign2
;
;       DESCRIPTION:    Assign disc drives, pass 2
;
;       PARAMETERS:     GS	Disc sel
;                       ES      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Assign2   Proc near
    mov eax,1000h
    AllocateBigLinear
    xor al,al
    mov es:[edx],al
    mov edi,edx
;    
    xor eax,eax
    xor edx,edx
    call ReadDiscSector
    jc aFree2
;
    mov esi,1BEh

aLoop2:
    mov cl,es:[esi+edi].part_type
    or cl,cl
    jz aNextPart2
;
    cmp cl,0EEh
    je aGpt2
;
    cmp cl,5
    je aInstall2
;
    cmp cl,0Fh
    jne aNextPart2

aInstall2:
    push esi
    push edi
;
    lea edi,[esi+edi+1]
    call ChsToLba
    or edx,edx
    jnz aExt2
;
    mov edx,es:[edi+7]

aExt2:
    call InstallExtended
;
    pop edi
    pop esi
    jmp aNextPart2

aGpt2:
    call InstallGpt2

aNextPart2:
    add si,10h
    cmp si,1FEh
    jne aLoop2

aFree2:
    mov ecx,1000h
    mov edx,edi
    FreeLinear
    ret
Assign2   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SyncDiscPart
;
;           DESCRIPTION:    Sync disc partitions
;
;           PARAMETERS:     AL          Disc #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sync_disc_part_name  DB 'Sync Disc Part', 0

sync_disc_part      Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;
    cmp al,MAX_DRIVES
    jae sdpDone
;
    movzx si,al
    shl si,1
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:disc_handler_section
;
    mov ax,ds:[si].disc_def_arr
    or ax,ax
    jz sdpDone
;
    mov gs,ax
    mov ax,flat_sel
    mov es,ax
;
    call Assign1
    call Assign2

sdpDone:
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:disc_handler_section
;
    popad
    pop gs
    pop fs
    pop es
    pop ds
    retf32
sync_disc_part      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CopyFsName
;
;       DESCRIPTION:    Copy FS name
;
;       PARAMETERS:     ES:0    FS name
;                       ESI     Sector buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyFsName    Proc near
    push ds
    push eax
    push ecx
    push esi
;       
    mov di,flat_sel
    mov ds,di
    xor di,di
    mov cx,8
    lea esi,[esi].boot_param.boot_fs

cpLoop:
    mov al,es:[di]
    or al,al
    jz cpSpace
;
    inc di
    mov [esi],al
    inc esi
    jmp cpNext

cpSpace:
    mov al,' '
    mov [esi],al
    inc esi    

cpNext:
    loop cpLoop
;
    pop esi    
    pop ecx
    pop eax
    pop ds
    ret
CopyFsName  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FormatDrive
;
;       DESCRIPTION:    Format a drive
;
;       PARAMETERS:     AL          Disc #
;                       EDX         Start sector
;                       ECX         Number of sectors
;                       ES:(E)DI    FS name
;
;       RETURNS:        AL      Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

format_drive_name       DB 'Format Drive',0

format_drive    Proc near
    push ds
    push es
    push fs
    push gs
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    IsFileSystemAvailable
    jc fdDone
;
    push ax
    mov ax,es
    mov ds,ax
    mov esi,edi
    mov eax,10h
    AllocateSmallGlobalMem
    xor edi,edi
    movs dword ptr es:[edi],ds:[esi]
    movs dword ptr es:[edi],ds:[esi]
    movs dword ptr es:[edi],ds:[esi]
    movs dword ptr es:[edi],ds:[esi]
    pop ax
    xor edi,edi
;
    mov bx,SEG data
    mov ds,bx
    EnterSection ds:disc_handler_section
;    
    movzx di,al
    shl di,1
    mov di,ds:[di].disc_def_arr
    mov gs,di
    mov si,OFFSET drive_def_arr
    mov bp,MAX_DRIVES

fdFindLoop:
    mov bx,[si]
    or bx,bx
    je fdFindNext
;
    cmp bx,-1
    je fdFindNext
;
    mov fs,bx
    cmp di,fs:drive_disc
    jne fdFindNext
;
    mov ebx,edx
    sub ebx,fs:drive_start_sector
    jz fdFound
    ja fdFindNext

fdFindBelow:
    add ebx,fs:drive_sectors
    jc fdFail

fdFindNext:
    add si,2
    sub bp,1
    jnz fdFindLoop
;    
    test gs:disc_flags,DISC_FLAG_DYNAMIC
    jz fdStatic
;
    call AllocDynamicDrive
    jmp fdOpen

fdStatic:
    call AllocStaticDrive

fdOpen:
    jc fdFail
;
    mov ah,gs:disc_nr
    OpenDrive
    jmp fdPerf

fdFound:
    push dx
    mov dl,al
    sub si,OFFSET drive_def_arr
    mov ax,si
    shr al,1
    mov ah,dl
    pop dx
    FlushDrive
;
    cmp ecx,fs:drive_sectors
    jbe fdPerf
;
    mov ecx,fs:drive_sectors

fdPerf:
    dec ecx
    or edx,edx
    jz fdMbr
    
fdPart:    
    push edx
    push es
    mov dx,flat_sel
    mov es,dx
    mov dx,cs
    mov ds,dx
    xor edx,edx
    LockSector
;
    mov edx,1
    mov es:[esi].boot_param.boot_mapping_sectors,dx
    sub ecx,edx
    mov edx,ecx
    mov es:[esi].boot_param.boot_sectors,edx
    cmp edx,10000h
    jae fdNoSmall
;
    mov es:[esi].boot_param.boot_small_sectors,dx       

fdNoSmall:
    pop es
;       
    call CopyFsName
;       
    ModifySector
    UnlockSector
    pop edx
    jmp fdDoSys

fdMbr:
    push edx
    push es
    mov dx,flat_sel
    mov es,dx
    mov dx,cs
    mov ds,dx
    xor edx,edx
    LockSector
    pop es
;
    call CopyFsName
;       
    ModifySector
    UnlockSector
    pop edx

fdDoSys:
    xor di,di
    FormatFileSystem
    jc fdFail
;
    StartFileSystem
;
    mov bx,SEG data
    mov ds,bx
    LeaveSection ds:disc_handler_section
;
    FreeMem
    clc
    jmp fdDone

fdFail:
    mov bx,SEG data
    mov ds,bx
    LeaveSection ds:disc_handler_section
;
    FreeMem
    stc

fdDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop gs
    pop fs
    pop es
    pop ds
    ret
format_drive    Endp

format_drive32  Proc far
    call format_drive
    retf32
format_drive32  Endp

format_drive16  Proc far
    push edi
    movzx edi,di
    call format_drive
    pop edi
    retf32
format_drive16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateDiscs
;
;           DESCRIPTION:    Update discs
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateDiscs  Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:disc_handler_section
;
    mov ax,flat_sel
    mov es,ax
;
    mov si,OFFSET disc_def_arr
    mov cx,MAX_DRIVES

udLoop1:
    mov ax,ds:[si]
    or ax,ax
    jz udNext1
;
    cmp ax,-1
    je udNext1
;
    mov gs,ax
    test gs:disc_flags,DISC_FLAG_INSTALLED
    jnz udNext1
;
    push ds
    push si
    push cx
;
    call Assign1
;
    pop cx
    pop si
    pop ds

udNext1:
    add si,2
    loop udLoop1
;
    mov si,OFFSET disc_def_arr
    mov cx,MAX_DRIVES

udLoop2:
    mov ax,ds:[si]
    or ax,ax
    jz udNext2
;
    cmp ax,-1
    je udNext2
;
    mov gs,ax
    test gs:disc_flags,DISC_FLAG_INSTALLED
    jnz udNext2
;
    push ds
    push si
    push cx
;
    call Assign2
;
    pop cx
    pop si
    pop ds
;
    mov al,gs:disc_nr
    StartDisc
;
    lock or gs:disc_flags,DISC_FLAG_INSTALLED

udNext2:
    add si,2
    loop udLoop2
;
    LeaveSection ds:disc_handler_section
;
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
UpdateDiscs  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           supervise_thread
;
;           DESCRIPTION:    Supervisor thread for FS
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

supervise_thread_name DB 'File System Supervisor', 0

supervise_thread:
    mov ax,SEG data
    mov ds,ax
;
    mov cx,4 * 20

stRetry:
    mov ax,ds:init_done
    or ax,ax
    jnz stDone
;
    mov ax,250
    WaitMilliSec
;
    sub cx,1
    jnz stRetry
;    
    SoftReset
    
stDone:
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DiscThread
;
;           DESCRIPTION:    Disc thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_thread_name DB 'Disc', 0

disc_thread_pr:
    mov ax,SEG data
    mov ds,ax
    ClearSignal
    GetThread
    mov ds:disc_handler_thread,ax
;
    mov ax,wd_code_sel
    verr ax
    jnz dtSuperOk
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET supervise_thread
    mov di,OFFSET supervise_thread_name
    mov ax,3
    mov cx,stack0_size
    CreateThread

dtSuperOk:
    mov ax,SEG data
    mov ds,ax
;
    sub ds:disc_handlers,1
    jz dtInitDo

dtRetry:
    mov ax,ds:disc_handlers
    or ax,ax
    jz dtInitDo
;    
    WaitForSignal
    jmp dtRetry
    
dtInitDo:        
    call UpdateDiscs
;
    WaitForVfsDiscs
;
    mov ax,SEG data
    mov ds,ax
    GetSystemTime
    add eax,5 * 1193000
    adc edx,0
    mov ds:init_timeout,eax
    mov ds:init_timeout+4,edx
    mov ds:init_done,1

dtWait:
    WaitForSignal
    call UpdateDiscs
    jmp dtWait

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_disc_thread
;
;           DESCRIPTION:    Create disc thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_disc_thread    Proc far
    push ds
    push es
    pushad
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET disc_thread_pr
    mov di,OFFSET disc_thread_name
    mov ax,3
    mov cx,stack0_size
    CreateThread
;
    popad
    pop es
    pop ds
    retf32
init_disc_thread    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init drive
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET begin_disc_handler
    mov edi,OFFSET begin_disc_handler_name
    mov ax,begin_disc_handler_nr
    RegisterOsGate
;
    mov esi,OFFSET end_disc_handler
    mov edi,OFFSET end_disc_handler_name
    mov ax,end_disc_handler_nr
    RegisterOsGate
;
    mov esi,OFFSET install_static_disc
    mov edi,OFFSET install_static_disc_name
    mov ax,install_static_disc_nr
    RegisterOsGate
;
    mov esi,OFFSET install_dynamic_disc
    mov edi,OFFSET install_dynamic_disc_name
    mov ax,install_dynamic_disc_nr
    RegisterOsGate
;
    mov esi,OFFSET install_fixed_disc
    mov edi,OFFSET install_fixed_disc_name
    mov ax,install_fixed_disc_nr
    RegisterOsGate
;
    mov esi,OFFSET install_vfs_disc
    mov edi,OFFSET install_vfs_disc_name
    mov ax,install_vfs_disc_nr
    RegisterOsGate
;
    mov esi,OFFSET remove_vfs_disc
    mov edi,OFFSET remove_vfs_disc_name
    mov ax,remove_vfs_disc_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_static_vfs_drive
    mov edi,OFFSET allocate_static_vfs_drive_name
    mov ax,allocate_static_vfs_drive_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_dynamic_vfs_drive
    mov edi,OFFSET allocate_dynamic_vfs_drive_name
    mov ax,allocate_dynamic_vfs_drive_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_fixed_vfs_drive
    mov edi,OFFSET allocate_fixed_vfs_drive_name
    mov ax,allocate_fixed_vfs_drive_nr
    RegisterOsGate
;
    mov esi,OFFSET close_vfs_drive
    mov edi,OFFSET close_vfs_drive_name
    mov ax,close_vfs_drive_nr
    RegisterOsGate
;
    mov esi,OFFSET set_disc_param
    mov edi,OFFSET set_disc_param_name
    mov ax,set_disc_param_nr
    RegisterOsGate
;
    mov esi,OFFSET set_disc_lba_param
    mov edi,OFFSET set_disc_lba_param_name
    mov ax,set_disc_lba_param_nr
    RegisterOsGate
;
    mov esi,OFFSET get_disc_vendor_info_buf
    mov edi,OFFSET get_disc_vendor_info_buf_name
    mov ax,get_disc_vendor_info_buf_nr
    RegisterOsGate
;
    mov esi,OFFSET set_disc_use32
    mov edi,OFFSET set_disc_use32_name
    mov ax,set_disc_use32_nr
    RegisterOsGate
;
    mov esi,OFFSET register_disc_change
    mov edi,OFFSET register_disc_change_name
    mov ax,register_disc_change_nr
    RegisterOsGate
;
    mov esi,OFFSET register_demand_mount
    mov edi,OFFSET register_demand_mount_name
    mov ax,register_demand_mount_nr
    RegisterOsGate
;
    mov esi,OFFSET start_disc
    mov edi,OFFSET start_disc_name
    mov ax,start_disc_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_disc
    mov edi,OFFSET stop_disc_name
    mov ax,stop_disc_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_disc_request
    mov edi,OFFSET stop_disc_request_name
    mov ax,stop_disc_request_nr
    RegisterOsGate
;
    mov esi,OFFSET wait_for_disc_request
    mov edi,OFFSET wait_for_disc_request_name
    mov ax,wait_for_disc_request_nr
    RegisterOsGate
;
    mov esi,OFFSET new_disc_request
    mov edi,OFFSET new_disc_request_name
    mov ax,new_disc_request_nr
    RegisterOsGate
;
    mov esi,OFFSET lock_disc_request
    mov edi,OFFSET lock_disc_request_name
    mov ax,lock_disc_request_nr
    RegisterOsGate
;
    mov esi,OFFSET modify_disc_request
    mov edi,OFFSET modify_disc_request_name
    mov ax,modify_disc_request_nr
    RegisterOsGate
;
    mov esi,OFFSET unlock_disc_request
    mov edi,OFFSET unlock_disc_request_name
    mov ax,unlock_disc_request_nr
    RegisterOsGate
;
    mov esi,OFFSET disc_request_completed
    mov edi,OFFSET disc_request_completed_name
    mov ax,disc_request_completed_nr
    RegisterOsGate
;
    mov esi,OFFSET disc_request_retry
    mov edi,OFFSET disc_request_retry_name
    mov ax,disc_request_retry_nr
    RegisterOsGate
;
    mov esi,OFFSET get_disc_request_array
    mov edi,OFFSET get_disc_request_array_name
    mov ax,get_disc_request_array_nr
    RegisterOsGate
;
    mov esi,OFFSET open_drive
    mov edi,OFFSET open_drive_name
    mov ax,open_drive_nr
    RegisterOsGate
;
    mov esi,OFFSET close_drive
    mov edi,OFFSET close_drive_name
    mov ax,close_drive_nr
    RegisterOsGate
;
    mov esi,OFFSET flush_drive
    mov edi,OFFSET flush_drive_name
    mov ax,flush_drive_nr
    RegisterOsGate
;
    mov esi,OFFSET check_drive
    mov edi,OFFSET check_drive_name
    mov ax,check_drive_nr
    RegisterOsGate
;
    mov esi,OFFSET new_sector
    mov edi,OFFSET new_sector_name
    mov ax,new_sector_nr
    RegisterOsGate
;
    mov esi,OFFSET get_drive_param
    mov edi,OFFSET get_drive_param_name
    mov ax,get_drive_param_nr
    RegisterOsGate
;
    mov esi,OFFSET lock_sector
    mov edi,OFFSET lock_sector_name
    mov ax,lock_sector_nr
    RegisterOsGate
;
    mov esi,OFFSET unlock_sector
    mov edi,OFFSET unlock_sector_name
    mov ax,unlock_sector_nr
    RegisterOsGate
;
    mov esi,OFFSET modify_sector
    mov edi,OFFSET modify_sector_name
    mov ax,modify_sector_nr
    RegisterOsGate
;
    mov esi,OFFSET flush_sector
    mov edi,OFFSET flush_sector_name
    mov ax,flush_sector_nr
    RegisterOsGate
;
    mov esi,OFFSET create_disc_seq
    mov edi,OFFSET create_disc_seq_name
    mov ax,create_disc_seq_nr
    RegisterOsGate
;
    mov esi,OFFSET modify_seq_sector
    mov edi,OFFSET modify_seq_sector_name
    mov ax,modify_seq_sector_nr
    RegisterOsGate
;
    mov esi,OFFSET perform_disc_seq
    mov edi,OFFSET perform_disc_seq_name
    mov ax,perform_disc_seq_nr
    RegisterOsGate
;
    mov esi,OFFSET req_sector
    mov edi,OFFSET req_sector_name
    mov ax,req_sector_nr
    RegisterOsGate
;
    mov esi,OFFSET define_sector
    mov edi,OFFSET define_sector_name
    mov ax,define_sector_nr
    RegisterOsGate
;
    mov esi,OFFSET wait_for_sector
    mov edi,OFFSET wait_for_sector_name
    mov ax,wait_for_sector_nr
    RegisterOsGate
;
    mov esi,OFFSET reset_drive
    mov edi,OFFSET reset_drive_name
    mov ax,reset_drive_nr
    RegisterOsGate
;
    mov esi,OFFSET get_old_disc_info
    mov edi,OFFSET get_old_disc_info_name
    xor dx,dx
    mov ax,get_old_disc_info_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_disc_info
    mov edi,OFFSET get_disc_info_name
    xor dx,dx
    mov ax,get_disc_info_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_disc_info
    mov edi,OFFSET set_disc_info_name
    xor dx,dx
    mov ax,set_disc_info_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_disc_cache_size
    mov edi,OFFSET get_disc_cache_size_name
    xor dx,dx
    mov ax,get_disc_cache_size_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET reset_disc
    mov edi,OFFSET reset_disc_name
    xor dx,dx
    mov ax,reset_disc_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_disc_idle
    mov edi,OFFSET is_disc_idle_name
    xor dx,dx
    mov ax,is_disc_idle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET sync_disc_part
    mov edi,OFFSET sync_disc_part_name
    xor dx,dx
    mov ax,sync_disc_part_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET allocate_fixed_drive
    mov edi,OFFSET allocate_fixed_drive_name
    xor dx,dx
    mov ax,allocate_fixed_drive_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_drive_disc_param
    mov edi,OFFSET get_drive_disc_param_name
    xor dx,dx
    mov ax,get_drive_disc_param_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_disc_vendor_info16
    mov esi,OFFSET get_disc_vendor_info32
    mov edi,OFFSET get_disc_vendor_info_name
    mov dx,virt_es_in
    mov ax,get_disc_vendor_info_nr
    RegisterUserGate
;
    mov esi,OFFSET remove_drive
    mov edi,OFFSET remove_drive_name
    xor dx,dx
    mov ax,remove_drive_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET demand_load_drive
    mov edi,OFFSET demand_load_drive_name
    mov ax,demand_load_drive_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET format_drive16
    mov esi,OFFSET format_drive32
    mov edi,OFFSET format_drive_name
    mov dx,virt_es_in
    mov ax,format_drive_nr
    RegisterUserGate
;
    mov ebx,OFFSET read_short_disc16
    mov esi,OFFSET read_short_disc32
    mov edi,OFFSET read_short_disc_name
    mov dx,virt_es_in
    mov ax,read_short_disc_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_short_disc16
    mov esi,OFFSET write_short_disc32
    mov edi,OFFSET write_short_disc_name
    mov dx,virt_es_in
    mov ax,write_short_disc_nr
    RegisterUserGate
;
    mov ebx,OFFSET read_long_disc16
    mov esi,OFFSET read_long_disc32
    mov edi,OFFSET read_long_disc_name
    mov dx,virt_es_in
    mov ax,read_long_disc_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_long_disc16
    mov esi,OFFSET write_long_disc32
    mov edi,OFFSET write_long_disc_name
    mov dx,virt_es_in
    mov ax,write_long_disc_nr
    RegisterUserGate
;
    mov edi,OFFSET init_disc_thread
    HookInitTasking
;
    mov bx,SEG data
    mov es,bx
    InitSection es:disc_handler_section
    mov es:disc_handlers,1
    mov es:init_done,0
    mov es:init_timeout,-1
    mov es:init_timeout+4,-1
;
    mov cx,MAX_DRIVES
    mov di,OFFSET disc_def_arr
    xor ax,ax
    rep stosw
;
    mov cx,MAX_DRIVES
    mov di,OFFSET drive_def_arr
    xor ax,ax
    rep stosw
;
    mov cx,DRIVE_WAIT_NUM
    mov di,4*DRIVE_WAIT_NUM + OFFSET drive_wait_arr
    xor ax,ax

init_drive_wait_loop:
    sub di,4
    mov es:[di],ax
    mov ax,di
    loop init_drive_wait_loop
    mov es:drive_wait_free,di
    mov es:drive_wait_count,DRIVE_WAIT_NUM
;
    call init_ramdrive  
    ret
init    ENDP

code    ENDS

    END init

