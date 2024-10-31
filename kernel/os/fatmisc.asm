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
; FATMISC.ASM
; Untilty functions for FAT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE blk.inc
INCLUDE ..\hint.inc
INCLUDE ..\fs.inc
INCLUDE fat.inc

boot_struc      STRUC

boot_jmp                                        DB ?,?,?
boot_name                                       DB 8 DUP(?)
boot_bytes_per_sector           DW ?
boot_sectors_per_cluster        DB ?
boot_resv_sectors                       DW ?
boot_fats                                       DB ?
boot_root_dirs                          DW ?
boot_sectors16                          DW ?
boot_media                                      DB ?
boot_fat_sectors16                      DW ?
boot_sectors_per_cyl            DW ?
boot_heads                                      DW ?
boot_hidden_sectors                     DD ?
boot_sectors                            DD ?
boot_fat_sectors                        DD ?
boot_ext_flags                          DW ?
boot_fs_version                         DW ?
boot_root_cluster                       DD ?
boot_info_sector                        DW ?
boot_backup_sector                      DW ?

boot_struc              ENDS

fat_dir_struc   STRUC

fat_base                DB 8 DUP(?)
fat_ext                 DB 3 DUP(?)
fat_attrib              DB ?
fat_case                DB ?
fat_cr_time_ms  DB ?
fat_cr_time             DW ?
fat_cr_date             DW ?
fat_acc_date    DW ?
fat_cluster_hi  DW ?
fat_time                DW ?
fat_date                DW ?
fat_cluster             DW ?
fat_file_size   DD ?

fat_dir_struc   ENDS

        .386p

code    SEGMENT byte public use16 'CODE'

    extrn get_free_clusters:near

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   LOCK_SECTOR
;
;               DESCRIPTION:    Lock a sector
;
;               PARAMETERS:             AL                      Drive #
;                                               EDX                     Sector to first FAT
;
;               RETURNS:                EBX                     Sector handle
;                                               ESI                     Linear address
;                                               NC                      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public lock_sector

lock_sector     PROC near
        LockSector
        ret
lock_sector     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GET_PARAM12/16
;
;               DESCRIPTION:    Read drive parameters from boot-record
;
;               RETRUNS:                DS                      Drive data
;                                               ES                      FLAT_SEL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public get_param12
        public get_param16

get_param12     Proc near
get_param16:
        push ax
        push ebx
        push ecx
        push edx
        push esi
;
        InitSection ds:cluster_section
        mov ds:drive_root_handle,0
        mov ds:drive_nr,al
        mov ds:file_list_ptr,0
        mov ds:file_free_ptr,0
        xor edx,edx
        LockSector
        mov cl,es:[esi].boot_sectors_per_cluster
        mov ch,0
get_param1216_shift_loop:
        rcr cl,1        
        jc get_param1216_shift_ok
        inc ch
        jmp get_param1216_shift_loop

get_param1216_shift_ok:
        mov ds:fat_cluster_shift,ch
        mov cx,es:[esi].boot_root_dirs
        mov ds:root_entries,cx
        movzx edx,es:[esi].boot_resv_sectors
        mov ds:fat1_sector,edx
        movzx ecx,es:[esi].boot_fat_sectors16
        add edx,ecx
        mov ds:fat2_sector,edx
        add edx,ecx
        mov ds:root_sector,edx
        movzx ecx,ds:root_entries
        shr ecx,4
        add edx,ecx
        mov ds:start_sector,edx
        movzx edx,es:[esi].boot_sectors16
        or edx,edx
        jnz get_param1216_total_ok
;
        mov edx,es:[esi].boot_sectors

get_param1216_total_ok:
        sub edx,ds:start_sector
        mov cl,ds:fat_cluster_shift
        shr edx,cl
        add edx,2
        mov ds:clusters,edx
    mov ds:info_sector,0
        UnlockSector
;
    mov al,ds:drive_nr
    call get_free_clusters      
        mov ds:free_clusters,edx
;       

        pop esi
        pop edx
        pop ecx
        pop ebx
        pop ax
        ret
get_param12     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GET_PARAM32
;
;               DESCRIPTION:    Read drive parameters from boot-record
;
;               RETRUNS:                DS                      Drive data
;                                               ES                      FLAT_SEL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public get_param32

get_param32     Proc near
        push ax
        push ebx
        push ecx
        push edx
        push esi
;
        InitSection ds:cluster_section
        mov ds:drive_root_handle,0
        mov ds:drive_nr,al
        mov ds:file_list_ptr,0
        mov ds:file_free_ptr,0
        xor edx,edx
        LockSector
        mov cl,es:[esi].boot_sectors_per_cluster
        mov ch,0
get_param32_shift_loop:
        rcr cl,1        
        jc get_param32_shift_ok
        inc ch
        jmp get_param32_shift_loop

get_param32_shift_ok:
        mov ds:fat_cluster_shift,ch
        mov ds:root_entries,0
        movzx edx,es:[esi].boot_resv_sectors
        mov ds:fat1_sector,edx
        mov ecx,es:[esi].boot_fat_sectors
        add edx,ecx
        mov ds:fat2_sector,edx
        add edx,ecx
        mov ds:start_sector,edx
        mov edx,es:[esi].boot_root_cluster
        sub edx,2
        mov cl,ds:fat_cluster_shift
        shl edx,cl
        add edx,ds:start_sector
        mov ds:root_sector,edx
        mov edx,es:[esi].boot_sectors
        sub edx,ds:start_sector
        mov cl,ds:fat_cluster_shift
        shr edx,cl
        add edx,2
        mov ds:clusters,edx
    movzx edx,es:[esi].boot_info_sector
    cmp dx,-1
    jne get_param32_info_ok
;
    xor edx,edx    

get_param32_info_ok:
    mov ds:info_sector,edx      
        UnlockSector
;   
    mov edx,ds:info_sector
    or edx,edx
    jz get_param32_count_clusters
;
        mov al,ds:drive_nr
        LockSector
        mov eax,es:[esi].fi_ext_sign
        cmp eax,41615252h  ; AaRR
        jne get_param32_info_fail
;
    mov eax,es:[esi].fi_info_sign
    cmp eax,61417272h  ; aArr
    jne get_param32_info_fail
;
    mov eax,es:[esi].fi_info_end
    cmp eax,0AA550000h
    jne get_param32_info_fail
;
    mov eax,es:[esi].fi_free_clusters
    mov ds:free_clusters,eax  
        UnlockSector
    jmp get_param32_done
    jmp get_param32_count_clusters      ; for updating info-sector

get_param32_info_fail:
    mov ds:info_sector,0
        UnlockSector
        
get_param32_count_clusters:    
    mov al,ds:drive_nr
    call get_free_clusters      
        mov ds:free_clusters,edx
;
    mov edx,ds:info_sector
    or edx,edx
    jz get_param32_done
;
    mov al,ds:drive_nr
    LockSector
    mov edx,ds:free_clusters
    mov es:[esi].fi_free_clusters,edx
    ModifySector
    UnlockSector
        
get_param32_done:       
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop ax
        ret
get_param32     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Format12
;
;               DESCRIPTION:    Format FAT12 filesystem
;
;               PARAMETERS:             AL                      Drive
;                                               ES:DI           FS name
;                                               ECX                     Number of sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public format12
    
format12        PROC far
    push ds
    push es
    pushad
;
    mov bp,ax
    mov dx,flat_sel
    mov es,dx
        xor edx,edx
        LockSector
;
    mov al,1

format_cluster_loop12:
    cmp ecx,10000h
    jb format_cluster_ok12
;
    shl al,1
    shr ecx,1
    jmp format_cluster_loop12

format_cluster_ok12:
    mov es:[esi].boot_sectors_per_cluster,al
;    
    movzx eax,al
    mul ecx
        mov es:[esi].boot_sectors16,ax
;
    dec ecx
    shr ecx,9
    mov eax,ecx
    shr eax,1
    add ecx,eax
    inc ecx
    mov es:[esi].boot_fat_sectors16,cx
;
    mov es:[esi].boot_fats,2
    mov es:[esi].boot_root_dirs,100h
        mov es:[esi].boot_fs_version,0
        mov es:[esi].boot_root_cluster,2
;       
    mov cx,es:[esi].boot_fat_sectors16
    movzx edx,es:[esi].boot_resv_sectors
;    
    ModifySector
        UnlockSector
;
    push cx
    mov ax,bp
    NewSector
;
    push cx
    mov word ptr es:[esi],0FFF0h
    mov word ptr es:[esi+2],0FFh
    lea edi,[esi+4]
    mov ecx,7Fh
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
    pop cx
    
format_fat1_loop12:
    sub cx,1
    jz format_fat1_done12
;
    push cx
    mov ax,bp
    inc edx
    NewSector
;
    mov edi,esi
    mov ecx,80h
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
    pop cx
    jmp format_fat1_loop12

format_fat1_done12:
    mov ax,bp
    inc edx
    NewSector
;
    mov word ptr es:[esi],0FFF0h
    mov word ptr es:[esi+2],0FFh
    lea edi,[esi+4]
    mov ecx,7Fh
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
;    
    pop cx

format_fat2_loop12:
    sub cx,1
    jz format_fat2_done12
;
    push cx
    mov ax,bp
    inc edx
    NewSector
;
    mov edi,esi
    mov ecx,80h
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
    pop cx
    jmp format_fat2_loop12

format_fat2_done12:
    mov cx,10h

format_root_dir_loop12:    
    push cx
    mov ax,bp
    inc edx
    NewSector
;
    mov edi,esi
    mov ecx,80h
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
    pop cx
    loop format_root_dir_loop12    
;
    mov ax,bp
        mov eax,SIZE drive_data_seg
        AllocateSmallGlobalMem
        mov ax,es
        mov ds,ax
        mov ax,flat_sel
        mov es,ax
        mov ax,bp
        mov ds:fat_type,fat12
    call get_param12
;
    clc    
    popad
    pop es
    pop ds
        retf32
format12        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Format16
;
;               DESCRIPTION:    Format FAT16 filesystem
;
;               PARAMETERS:             AL                      Drive
;                                               ES:DI           FS name
;                                               ECX                     Number of sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public format16
    
format16        PROC far
    push ds
    push es
    pushad
;
    mov bp,ax
    mov dx,flat_sel
    mov es,dx
        xor edx,edx
        LockSector
;
    mov al,1

format_cluster_loop16:
    cmp ecx,10000h
    jb format_cluster_ok16
;
    shl al,1
    shr ecx,1
    jmp format_cluster_loop16

format_cluster_ok16:
    mov es:[esi].boot_sectors_per_cluster,al
;    
    movzx eax,al
    mul ecx
        mov es:[esi].boot_sectors,eax
        mov es:[esi].boot_sectors16,0
;
    dec ecx
    shr ecx,8
    inc ecx
    mov eax,ecx
    shr eax,8
    sub ecx,eax
    mov es:[esi].boot_fat_sectors16,cx
    mov es:[esi].boot_fat_sectors,ecx
;
    mov es:[esi].boot_fats,2
    mov es:[esi].boot_root_dirs,100h
        mov es:[esi].boot_fs_version,0
        mov es:[esi].boot_root_cluster,2
;       
    mov cx,es:[esi].boot_fat_sectors16
    movzx edx,es:[esi].boot_resv_sectors
;    
    ModifySector
        UnlockSector
;
    push cx
    mov ax,bp
    NewSector
;
    push cx
    mov word ptr es:[esi],0FFF8h
    mov word ptr es:[esi+2],0FFFFh
    lea edi,[esi+4]
    mov ecx,7Fh
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
    pop cx
    
format_fat1_loop16:
    sub cx,1
    jz format_fat1_done16
;
    push cx
    mov ax,bp
    inc edx
    NewSector
;
    mov edi,esi
    mov ecx,80h
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
    pop cx
    jmp format_fat1_loop16    

format_fat1_done16:
    mov ax,bp
    inc edx
    NewSector
;
    mov word ptr es:[esi],0FFF8h
    mov word ptr es:[esi+2],0FFFFh
    lea edi,[esi+4]
    mov ecx,7Fh
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
;    
    pop cx

format_fat2_loop16:
    sub cx,1
    jz format_fat2_done16
;
    push cx
    mov ax,bp
    inc edx
    NewSector
;
    mov edi,esi
    mov ecx,80h
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
    pop cx
    jmp format_fat2_loop16    

format_fat2_done16:
    mov cx,10h

format_root_dir_loop16:    
    push cx
    mov ax,bp
    inc edx
    NewSector
;
    mov edi,esi
    mov ecx,80h
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
    pop cx
    loop format_root_dir_loop16    
;
    mov ax,bp
        mov eax,SIZE drive_data_seg
        AllocateSmallGlobalMem
        mov ax,es
        mov ds,ax
        mov ax,flat_sel
        mov es,ax
        mov ax,bp
        mov ds:fat_type,fat16
    call get_param16
;
    clc    
    popad
    pop es
    pop ds
        retf32
format16        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Format32
;
;               DESCRIPTION:    Format FAT32 filesystem
;
;               PARAMETERS:             AL                      Drive
;                                               ES:DI           FS name
;                                               ECX                     Number of sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public format32
    
format32        PROC far
    push ds
    push es
    pushad
;
    mov bp,ax
    mov dx,flat_sel
    mov es,dx
    xor edx,edx
    LockSector
;       
    mov al,1

format_cluster_loop32:
    cmp al,8
    je format_cluster_ok32
;
    cmp ecx,20000h
    jb format_cluster_ok32
;
    shl al,1
    shr ecx,1
    jmp format_cluster_loop32

format_cluster_ok32:
    mov es:[esi].boot_sectors_per_cluster,al
;    
    movzx eax,al
    mul ecx
    mov es:[esi].boot_sectors,eax
    mov es:[esi].boot_sectors16,0
;
    dec ecx
    shr ecx,7
    inc ecx
    mov eax,ecx
    shr eax,7
    sub ecx,eax
    mov es:[esi].boot_fat_sectors16,0
    mov es:[esi].boot_fat_sectors,ecx
    mov es:[esi].boot_ext_flags,0
;
    mov es:[esi].boot_resv_sectors,32
    mov es:[esi].boot_sectors16,0
    mov es:[esi].boot_fats,2
    mov es:[esi].boot_root_dirs,0
    mov es:[esi].boot_fs_version,0
    mov es:[esi].boot_root_cluster,2
    mov es:[esi].boot_info_sector,1
    mov es:[esi].boot_backup_sector,6
    push ebx
    push esi
;
    push ecx
    push esi
    mov ax,bp
    mov edx,6
    LockSector
    mov edi,esi
    pop esi 
    mov ecx,80h
    rep movs dword ptr es:[edi],es:[esi]
    pop ecx
    ModifySector
    UnlockSector
;
    pop esi
    pop ebx
    ModifySector
    UnlockSector
;       
    push ecx
;
    push ecx
    mov ax,bp
    mov edx,1
    NewSector
    mov dword ptr es:[esi],41615252h
    mov dword ptr es:[esi+1E4h],61417272h
    shl ecx,7
    mov es:[esi+1E8h],ecx
    mov dword ptr es:[esi+1ECh],2
    mov dword ptr es:[esi+1F0h],0
    mov dword ptr es:[esi+1FCh],0AA550000h
    ModifySector
    UnlockSector
    pop ecx
;
    push ecx
    mov ax,bp
    mov edx,32
    NewSector
    mov dword ptr es:[esi],0FFFFFF8h
    mov dword ptr es:[esi+4],0FFFFFFFh
    mov dword ptr es:[esi+8],0FFFFFFFh
    lea edi,[esi+12]
    mov ecx,7Dh
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
    pop ecx
    
format_fat1_loop32:
    sub ecx,1
    jz format_fat1_done32
;
    push ecx
    mov ax,bp
    inc edx
    NewSector
    mov edi,esi
    mov ecx,80h
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
    pop ecx
    jmp format_fat1_loop32

format_fat1_done32:
    mov ax,bp
    inc edx
    NewSector
;
    mov dword ptr es:[esi], 0FFFFFF8h
    mov dword ptr es:[esi+4],0FFFFFFFh
    mov dword ptr es:[esi+8],0FFFFFFFh
    lea edi,[esi+12]
    mov ecx,7Dh
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
;    
    pop ecx

format_fat2_loop32:
    sub ecx,1
    jz format_fat2_done32
;
    push ecx
    mov ax,bp
    inc edx
    NewSector
;
    mov edi,esi
    mov ecx,80h
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
    pop ecx
    jmp format_fat2_loop32    

format_fat2_done32:

    mov cx,8

format_root_dir_loop32:    
    push cx
    mov ax,bp
    inc edx
    NewSector
;
    mov edi,esi
    mov ecx,80h
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
    pop cx
    loop format_root_dir_loop32
;
    mov ax,bp
        mov eax,SIZE drive_data_seg
        AllocateSmallGlobalMem
        mov ax,es
        mov ds,ax
        mov ax,flat_sel
        mov es,ax
        mov ax,bp
        mov ds:fat_type,fat32
    call get_param32
;
    clc    
    popad
    pop es
    pop ds
        retf32
format32        Endp

code    ENDS

        END

