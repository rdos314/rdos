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
; FAT.ASM
; FAT filesystem driver
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

attr_read_only          EQU 1
attr_hidden                     EQU 2
attr_system                     EQU 4
attr_volume                     EQU 8
attr_dir                        EQU 10h
attr_arcive                     EQU 20h

        extrn allocate_dir_sel:near
        extrn free_dir_sel:near

        extrn cache_dir12_16:near
        extrn cache_dir32:near
        extrn create_dir:near
        extrn delete_dir:near
        extrn delete_file:near
        extrn rename_file:near
        extrn create_file:near

        extrn update_dir:near
        extrn update_file:near
        extrn set_file_size:near
        extrn allocate_file_list:near
        extrn free_file_list:near
        extrn read_file_block:near
        extrn write_file_block:near

        extrn format12:near
        extrn format16:near
        extrn format32:near

        extrn get_param12:near
        extrn get_param16:near
        extrn get_param32:near

        .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   MOUNT12
;
;               DESCRIPTION:    Mount FAT12 on a drive
;
;               RETRUNS:                DS:SI           ADDRESS TO DRIVE DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mount12 PROC far
        push es
;
        push ax
        mov eax,SIZE drive_data_seg
        AllocateSmallGlobalMem
        mov ax,es
        mov ds,ax
        mov ax,flat_sel
        mov es,ax
        pop ax
        mov ds:fat_type,fat12
        call get_param12
        xor esi,esi
;
        pop es
        retf32
mount12 ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   MOUNT16
;
;               DESCRIPTION:    Mount FAT16 on a drive
;
;               RETRUNS:                DS:SI           ADDRESS TO DRIVE DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mount16 PROC far
        push es
;
        push ax
        mov eax,SIZE drive_data_seg
        AllocateSmallGlobalMem
        mov ax,es
        mov ds,ax
        mov ax,flat_sel
        mov es,ax
        pop ax
        mov ds:fat_type,fat16
        call get_param16
        xor esi,esi
;
        pop es
        retf32
mount16 ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   MOUNT32
;
;               DESCRIPTION:    Mount FAT32 on a drive
;
;               RETRUNS:                DS:SI           ADDRESS TO DRIVE DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mount32 PROC far
        push es
;
        push ax
        mov eax,SIZE drive_data_seg
        AllocateSmallGlobalMem
        mov ax,es
        mov ds,ax
        mov ax,flat_sel
        mov es,ax
        pop ax
        mov ds:fat_type,fat32
        call get_param32
        xor esi,esi
;
        pop es
        retf32
mount32 ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   FLUSH
;
;               DESCRIPTION:    Flush filesystem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush   PROC far
        clc
        retf32
flush   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DISMOUNT
;
;               DESCRIPTION:    Dismount filesystem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dismount        PROC far
        retf32
dismount        ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GET_DRIVE_INFO
;
;               DESCRIPTION:    Read info from drive
;
;               RETURNS:                EAX             FREE UNITS
;                                               CX              BYTES / UNIT
;                                               EDX             TOTAL UNITS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_drive_info  PROC far
    mov eax,ds:free_clusters
        mov edx,ds:clusters
        mov cl,ds:fat_cluster_shift
        shl eax,cl
        shl edx,cl
        mov cx,200h
        clc
        retf32
get_drive_info  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GET_IOCTL_DATA
;
;               DESCRIPTION:    Get IOCTL data
;
;               PARAMETERS:             BX                      HANDLE
;
;               RETURNS:                DX                      IOCTL_DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ioctl_data  PROC far
        movzx dx,al
        or dx,40h
        retf32
get_ioctl_data  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   init
;
;               DESCRIPTION:    init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy   Proc far
        stc
        retf32
dummy   Endp

fs12_name       DB 'FAT12',0

fs12_ctrl:
f12s00  DD OFFSET format12,                     SEG code
f12s01  DD OFFSET mount12,                      SEG code
f12s02  DD OFFSET flush,                        SEG code
f12s03  DD OFFSET dismount,                     SEG code
f12s04  DD OFFSET get_drive_info,       SEG code
f12s05  DD OFFSET allocate_dir_sel,     SEG code
f12s06  DD OFFSET free_dir_sel,         SEG code
f12s07  DD OFFSET cache_dir12_16,       SEG code
f12s08  DD OFFSET update_dir,           SEG code
f12s09  DD OFFSET update_file,          SEG code
f12s10  DD OFFSET create_dir,           SEG code
f12s11  DD OFFSET delete_dir,           SEG code
f12s12  DD OFFSET delete_file,          SEG code
f12s13  DD OFFSET rename_file,          SEG code
f12s14  DD OFFSET create_file,          SEG code
f12s15  DD OFFSET get_ioctl_data,       SEG code
f12s16  DD OFFSET set_file_size,        SEG code
f12s17  DD OFFSET dummy,                        SEG code
f12s18  DD OFFSET dummy,                        SEG code
f12s19  DD OFFSET allocate_file_list,SEG code
f12s20  DD OFFSET free_file_list,       SEG code
f12s21  DD OFFSET read_file_block,      SEG code
f12s22  DD OFFSET write_file_block,     SEG code

fs16_name       DB 'FAT16',0

fs16_ctrl:
f16s00  DD OFFSET format16,                     SEG code
f16s01  DD OFFSET mount16,                      SEG code
f16s02  DD OFFSET flush,                        SEG code
f16s03  DD OFFSET dismount,                     SEG code
f16s04  DD OFFSET get_drive_info,       SEG code
f16s05  DD OFFSET allocate_dir_sel,     SEG code
f16s06  DD OFFSET free_dir_sel,         SEG code
f16s07  DD OFFSET cache_dir12_16,       SEG code
f16s08  DD OFFSET update_dir,           SEG code
f16s09  DD OFFSET update_file,          SEG code
f16s10  DD OFFSET create_dir,           SEG code
f16s11  DD OFFSET delete_dir,           SEG code
f16s12  DD OFFSET delete_file,          SEG code
f16s13  DD OFFSET rename_file,          SEG code
f16s14  DD OFFSET create_file,          SEG code
f16s15  DD OFFSET get_ioctl_data,       SEG code
f16s16  DD OFFSET set_file_size,        SEG code
f16s17  DD OFFSET dummy,                        SEG code
f16s18  DD OFFSET dummy,                        SEG code
f16s19  DD OFFSET allocate_file_list,SEG code
f16s20  DD OFFSET free_file_list,       SEG code
f16s21  DD OFFSET read_file_block,      SEG code
f16s22  DD OFFSET write_file_block,     SEG code

fs32_name       DB 'FAT32',0

fs32_ctrl:
f32s00  DD OFFSET format32,                     SEG code
f32s01  DD OFFSET mount32,                      SEG code
f32s02  DD OFFSET flush,                        SEG code
f32s03  DD OFFSET dismount,                     SEG code
f32s04  DD OFFSET get_drive_info,       SEG code
f32s05  DD OFFSET allocate_dir_sel,     SEG code
f32s06  DD OFFSET free_dir_sel,         SEG code
f32s07  DD OFFSET cache_dir32,          SEG code
f32s08  DD OFFSET update_dir,           SEG code
f32s09  DD OFFSET update_file,          SEG code
f32s10  DD OFFSET create_dir,           SEG code
f32s11  DD OFFSET delete_dir,           SEG code
f32s12  DD OFFSET delete_file,          SEG code
f32s13  DD OFFSET rename_file,          SEG code
f32s14  DD OFFSET create_file,          SEG code
f32s15  DD OFFSET get_ioctl_data,       SEG code
f32s16  DD OFFSET set_file_size,        SEG code
f32s17  DD OFFSET dummy,                        SEG code
f32s18  DD OFFSET dummy,                        SEG code
f32s19  DD OFFSET allocate_file_list,SEG code
f32s20  DD OFFSET free_file_list,       SEG code
f32s21  DD OFFSET read_file_block,      SEG code
f32s22  DD OFFSET write_file_block,     SEG code

init    PROC far
        mov ax,cs
        mov ds,ax
        mov es,ax
;
        mov esi,OFFSET fs12_name
        mov edi,OFFSET fs12_ctrl
        RegisterFileSystem
;
        mov esi,OFFSET fs16_name
        mov edi,OFFSET fs16_ctrl
        RegisterFileSystem
;
        mov esi,OFFSET fs32_name
        mov edi,OFFSET fs32_ctrl
        RegisterFileSystem
        clc
        ret
init    ENDP

code    ENDS

        END init
