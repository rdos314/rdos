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
; FATDIR.ASM
; Directory handling for FAT
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

        .386p


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

code    SEGMENT byte public use16 'CODE'

        assume cs:code

        extrn next_cluster:near
        extrn allocate_cluster:near
        extrn link_cluster:near
        extrn next_sector:near
        extrn free_cluster:near


char_tab:
ct00 DB 0,              0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct08 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct10 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct18 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct20 DB ' ',    '!',    0FFh,   '#',    '$',    '%',    '&',    27h
ct28 DB '(',    ')',    0FFh,   0FFh,   0FFh,   '-',    '.',    0
ct30 DB '0',    '1',    '2',    '3',    '4',    '5',    '6',    '7'
ct38 DB '8',    '9',    0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct40 DB '@',    'A',    'B',    'C',    'D',    'E',    'F',    'G'
ct48 DB 'H',    'I',    'J',    'K',    'L',    'M',    'N',    'O'
ct50 DB 'P',    'Q',    'R',    'S',    'T',    'U',    'V',    'W'
ct58 DB 'X',    'Y',    'Z',    0FFh,   0,              0FFh,   '^',    '_'
ct60 DB 60h,    'A',    'B',    'C',    'D',    'E',    'F',    'G'
ct68 DB 'H',    'I',    'J',    'K',    'L',    'M',    'N',    'O'
ct70 DB 'P',    'Q',    'R',    'S',    'T',    'U',    'V',    'W'
ct78 DB 'X',    'Y',    'Z',    '{',    0FFh,   '}',    '~',    0FFh
ct80 DB 0FFh,   0FFh,   0FFh,   0FFh,   'é',    0FFh,   'è',    0FFh
ct88 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   'é',    'è'
ct90 DB 0FFh,   0FFh,   0FFh,   0FFh,   'ô',    0FFh,   0FFh,   0FFh
ct98 DB 0FFh,   'ô',    0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctA0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctA8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctB0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctB8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctC0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctC8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctD0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctD8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctE0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctE8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctF0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctF8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh

lower_tab:
lt00 DB 0,              0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
lt08 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
lt10 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
lt18 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
lt20 DB ' ',    '!',    0FFh,   '#',    '$',    '%',    '&',    27h
lt28 DB '(',    ')',    0FFh,   0FFh,   0FFh,   '-',    '.',    0
lt30 DB '0',    '1',    '2',    '3',    '4',    '5',    '6',    '7'
lt38 DB '8',    '9',    0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
lt40 DB '@',    'a',    'b',    'c',    'd',    'e',    'f',    'g'
lt48 DB 'h',    'i',    'j',    'k',    'l',    'm',    'n',    'o'
lt50 DB 'p',    'q',    'r',    's',    't',    'u',    'v',    'w'
lt58 DB 'x',    'y',    'z',    0FFh,   0,              0FFh,   '^',    '_'
lt60 DB 60h,    'a',    'b',    'c',    'd',    'e',    'f',    'g'
lt68 DB 'h',    'i',    'j',    'k',    'l',    'm',    'n',    'o'
lt70 DB 'p',    'q',    'r',    's',    't',    'u',    'v',    'w'
lt78 DB 'x',    'y',    'z',    '{',    0FFh,   '}',    '~',    0FFh
lt80 DB 0FFh,   0FFh,   0FFh,   0FFh,   'é',    0FFh,   'è',    0FFh
lt88 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   'é',    'è'
lt90 DB 0FFh,   0FFh,   0FFh,   0FFh,   'ô',    0FFh,   0FFh,   0FFh
lt98 DB 0FFh,   'ô',    0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ltA0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ltA8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ltB0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ltB8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ltC0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ltC8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ltD0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ltD8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ltE0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ltE8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ltF0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ltF8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh


FAT_INVALID = 1
FAT_UPPER = 2
FAT_LOWER = 4

lfn_tab:
lft00 DB 1,     1,      1,      1,      1,      1,      1,      1
lft08 DB 1,     1,      1,      1,      1,      1,      1,      1
lft10 DB 1,     1,      1,      1,      1,      1,      1,      1
lft18 DB 1,     1,      1,      1,      1,      1,      1,      1
lft20 DB 0,     0,      0,      0,      0,      0,      0,      0
lft28 DB 0,     0,      1,      1,      1,      0,      0,      1
lft30 DB 0,     0,      0,      0,      0,      0,      0,      0
lft38 DB 0,     0,      1,      1,      1,      1,      1,      1
lft40 DB 0,     2,      2,      2,      2,      2,      2,      2
lft48 DB 2,     2,      2,      2,      2,      2,      2,      2
lft50 DB 2,     2,      2,      2,      2,      2,      2,      2
lft58 DB 2,     2,      2,      1,      1,      1,      0,      0
lft60 DB 0,     4,      4,      4,      4,      4,      4,      4
lft68 DB 4,     4,      4,      4,      4,      4,      4,      4
lft70 DB 4,     4,      4,      4,      4,      4,      4,      4
lft78 DB 4,     4,      4,      0,      1,      0,      0,      1
lft80 DB 1,     1,      1,      1,      1,      1,      1,      1
lft88 DB 1,     1,      1,      1,      1,      1,      1,      1
lft90 DB 1,     1,      1,      1,      1,      1,      1,      1
lft98 DB 1,     1,      1,      1,      1,      1,      1,      1
lftA0 DB 1,     1,      1,      1,      1,      1,      1,      1
lftA8 DB 1,     1,      1,      1,      1,      1,      1,      1
lftB0 DB 1,     1,      1,      1,      1,      1,      1,      1
lftB8 DB 1,     1,      1,      1,      1,      1,      1,      1
lftC0 DB 1,     1,      1,      1,      1,      1,      1,      1
lftC8 DB 1,     1,      1,      1,      1,      1,      1,      1
lftD0 DB 1,     1,      1,      1,      1,      1,      1,      1
lftD8 DB 1,     1,      1,      1,      1,      1,      1,      1
lftE0 DB 1,     1,      1,      1,      1,      1,      1,      1
lftE8 DB 1,     1,      1,      1,      1,      1,      1,      1
lftF0 DB 1,     1,      1,      1,      1,      1,      1,      1
lftF8 DB 1,     1,      1,      1,      1,      1,      1,      1


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   AllocateDirSel
;
;               DESCRIPTION:    Allocate dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public allocate_dir_sel

allocate_dir_sel        PROC far
        push es
        push eax
;
        mov eax,SIZE fat_dir_sel_data_struc
        AllocateSmallGlobalMem
        mov es:fds_deleted_ptr,0
        mov es:fds_free_ptr,0
        mov bx,es
;
        pop eax
        pop es
        retf32
allocate_dir_sel        ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   FreeDirSel
;
;               DESCRIPTION:    Free dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public free_dir_sel

free_dir_sel    PROC far
        push ds
        push es
        push eax
        push ecx
        push edx
;
        mov ax,flat_sel
        mov es,ax
        mov ds,bx
        mov edx,ds:fds_deleted_ptr
        or edx,edx
        jz free_dir_free

free_dir_deleted_loop:
        mov eax,es:[edx].de_next
        xor ecx,ecx
        FreeLinear
        mov edx,eax
        cmp edx,ds:fds_deleted_ptr
        jne free_dir_deleted_loop

free_dir_free:
        mov edx,ds:fds_free_ptr
        or edx,edx
        jz free_dir_del

free_dir_free_loop:
        mov eax,es:[edx].de_next
        xor ecx,ecx
        FreeLinear
        mov edx,eax
        cmp edx,ds:fds_free_ptr
        jne free_dir_free_loop

free_dir_del:
        xor ax,ax
        mov ds,ax
        mov es,bx
        FreeMem
;
        pop edx
        pop ecx
        pop eax
        pop es
        pop ds
        retf32
free_dir_sel    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   InsertFreeEntry
;
;               DESCRIPTION:    Insert free entry structure
;
;               PARAMETERS:             BX                      Dir selector
;                                               EDX                     Free entry
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertFreeEntry PROC near
        push ds
        push es
        push eax
        push ebx
;
        mov ds,bx
        mov ax,flat_sel
        mov es,ax
;
        mov eax,ds:fds_free_ptr
        or eax,eax
        jne insert_free_used

insert_free_empty:
        mov es:[edx].de_prev,edx
        mov es:[edx].de_next,edx
        mov ds:fds_free_ptr,edx
        jmp insert_free_done

insert_free_used:
        mov ebx,es:[eax].de_prev
        mov es:[eax].de_prev,edx
        mov es:[ebx].de_next,edx
        mov es:[edx].de_prev,ebx
        mov es:[edx].de_next,eax        

insert_free_done:
        pop ebx
        pop eax
        pop es
        pop ds
        ret
InsertFreeEntry ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   InsertDeletedEntry
;
;               DESCRIPTION:    Insert deleted entry structure
;
;               PARAMETERS:             BX                      Dir selector
;                                               EDX                     Deleted entry
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertDeletedEntry      PROC near
        push ds
        push es
        push eax
        push ebx
;
        mov ds,bx
        mov ax,flat_sel
        mov es,ax
;
        mov eax,ds:fds_deleted_ptr
        or eax,eax
        jne insert_deleted_used

insert_deleted_empty:
        mov es:[edx].de_prev,edx
        mov es:[edx].de_next,edx
        mov ds:fds_deleted_ptr,edx
        jmp insert_deleted_done

insert_deleted_used:
        mov ebx,es:[eax].de_prev
        mov es:[eax].de_prev,edx
        mov es:[ebx].de_next,edx
        mov es:[edx].de_prev,ebx
        mov es:[edx].de_next,eax        

insert_deleted_done:
        pop ebx
        pop eax
        pop es
        pop ds
        ret
InsertDeletedEntry      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetFreeEntry
;
;               DESCRIPTION:    Get free entry structure
;
;               PARAMETERS:             BX                      Dir selector
;
;               RETURNS:                EDX                     Entry
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFreeEntry    PROC near
        push ds
        push es
        push eax
        push ebx
;
        mov ds,bx
        mov ax,flat_sel
        mov es,ax
;
        mov edx,ds:fds_free_ptr
        or edx,edx
        stc
        jz get_free_done
;
        mov eax,es:[edx].de_next
        mov ebx,es:[edx].de_prev
        mov es:[ebx].de_next,eax
        mov es:[eax].de_prev,ebx
        mov ds:fds_free_ptr,eax
        cmp eax,edx
        jne get_free_list_ok
;
        mov ds:fds_free_ptr,0

get_free_list_ok:
        clc

get_free_done:
        pop ebx
        pop eax
        pop es
        pop ds
        ret
GetFreeEntry    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetDeletedEntry
;
;               DESCRIPTION:    Get deleted entry structure
;
;               PARAMETERS:             BX                      Dir selector
;
;               RETURNS:                EDX                     Entry
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDeletedEntry PROC near
        push ds
        push es
        push eax
        push ebx
;
        mov ds,bx
        mov ax,flat_sel
        mov es,ax
;
        mov edx,ds:fds_deleted_ptr
        or edx,edx
        stc
        jz get_deleted_done
;
        mov eax,es:[edx].de_next
        mov ebx,es:[edx].de_prev
        mov es:[ebx].de_next,eax
        mov es:[eax].de_prev,ebx
        mov ds:fds_deleted_ptr,eax
        cmp eax,edx
        jne get_deleted_list_ok
;
        mov ds:fds_deleted_ptr,0

get_deleted_list_ok:
        clc

get_deleted_done:
        pop ebx
        pop eax
        pop es
        pop ds
        ret
GetDeletedEntry ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetSpecFreeEntry
;
;               DESCRIPTION:    Get a specific free entry structure
;
;               PARAMETERS:             BX                      Dir selector
;                       EDX         Sector
;                       AX          Offset
;
;       RETURNS:        EDX         Entry
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSpecFreeEntry        PROC near
        push ds
        push es
        push eax
        push ebx
        push esi
;
        mov ds,bx
        mov si,flat_sel
        mov es,si
;
        mov esi,ds:fds_free_ptr
        or esi,esi
        stc
        jz gsfeDone
;
    mov ebx,esi

gsfeLoop:
    cmp edx,es:[esi].fe_entry_sector 
    jne gsfeNext
;
    cmp ax,es:[esi].fe_entry_offset
    je gsfeTake

gsfeNext: 
    mov esi,es:[esi].de_next
    cmp ebx,esi
    jne gsfeLoop
;
    stc
    jmp gsfeDone

gsfeTake:
    mov ds:fds_free_ptr,esi
;
    mov edx,ds:fds_free_ptr
        mov eax,es:[edx].de_next
        mov ebx,es:[edx].de_prev
        mov es:[ebx].de_next,eax
        mov es:[eax].de_prev,ebx
        mov ds:fds_free_ptr,eax
        cmp eax,edx
        jne gsfeOk
;
        mov ds:fds_free_ptr,0

gsfeOk:
        clc

gsfeDone:
    pop esi
    pop ebx
    pop eax
        pop es
        pop ds
        ret
GetSpecFreeEntry        ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetSpecDeleteEntry
;
;               DESCRIPTION:    Get a specific deleted entry structure
;
;               PARAMETERS:             BX                      Dir selector
;                       EDX         Sector
;                       AX          Offset
;
;       RETURNS:        EDX         Entry
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSpecDeletedEntry     PROC near
        push ds
        push es
        push eax
        push ebx
        push esi
;
        mov ds,bx
        mov si,flat_sel
        mov es,si
;
        mov esi,ds:fds_deleted_ptr
        or esi,esi
        stc
        jz gsdeDone
;
    mov ebx,esi

gsdeLoop:
    cmp edx,es:[esi].fe_entry_sector 
    jne gsdeNext
;
    cmp ax,es:[esi].fe_entry_offset
    je gsdeTake

gsdeNext: 
    mov esi,es:[esi].de_next
    cmp ebx,esi
    jne gsdeLoop
;
    stc
    jmp gsdeDone

gsdeTake:
    mov ds:fds_deleted_ptr,esi
;
    mov edx,ds:fds_deleted_ptr
        mov eax,es:[edx].de_next
        mov ebx,es:[edx].de_prev
        mov es:[ebx].de_next,eax
        mov es:[eax].de_prev,ebx
        mov ds:fds_deleted_ptr,eax
        cmp eax,edx
        jne gsdeOk
;
        mov ds:fds_deleted_ptr,0

gsdeOk:
        clc

gsdeDone:
    pop esi
    pop ebx
    pop eax
        pop es
        pop ds
        ret
GetSpecDeletedEntry     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               allocate_root_lfn_entries
;
;               DESCRIPTION:    Allocate LFN entries in root directory
;
;               PARAMETERS:             BX                      Cached dir selector
;                       FS          LFN cache selector
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_root_lfn_entries       Proc near
        push ax
        push ebx
        push cx
        push edx
        push esi
        push di
        push bp
;
        mov cx,ds:root_entries
        shr cx,4
        mov edx,ds:root_sector
;
    mov di,OFFSET lfn_entry_arr
    mov bp,fs:lfn_entries
    inc bp

arle_sector_loop:
        mov al,ds:drive_nr
        LockSector
        jc arle_dir_next

arle_entry_loop:
        mov al,es:[esi].fat_base
        or al,al
        je arle_this_free
;
        cmp al,0E5h
        je arle_this_free
;
    mov di,OFFSET lfn_entry_arr
    mov bp,fs:lfn_entries
    inc bp
    jmp arle_entry_next

arle_this_free:
    sub bp,1
    jz arle_ok
;    
    mov fs:[di].lfnp_sector,edx
    movzx eax,si
    and ax,1FFh
    mov fs:[di].lfnp_offset,eax
    add di,8
    jmp arle_entry_next
    
arle_ok:
    mov fs:lfn_fat_sector,edx
    mov ax,si
    and ax,1FFh
    mov fs:lfn_fat_offset,ax
    clc
    jmp arle_done

arle_entry_next:        
        add si,20h
        test si,1FFh
        jnz arle_entry_loop

arle_dir_next:
        UnlockSector                    
        inc edx
        loop arle_sector_loop
;
    stc

arle_done:    
    pop bp
        pop di
        pop esi
        pop edx
        pop cx
        pop ebx
        pop ax
        ret
allocate_root_lfn_entries       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   allocate_dir_lfn_entries
;
;               DESCRIPTION:    Allocate LFN entries in sub directory
;
;               PARAMETERS:             EDX                     Start sector
;                                               BX                      Cached dir selector
;                       FS          LFN cache selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dir_lfn_entries        Proc near
        push ax
        push ebx
        push edx
        push esi
        push di
        push bp
;
    mov bp,cx
;
    mov di,OFFSET lfn_entry_arr
    mov bp,fs:lfn_entries
    inc bp

adl_sector_loop:
        mov al,ds:drive_nr
        LockSector
        jc adl_dir_next

adl_entry_loop:
        mov al,es:[esi].fat_base
        or al,al
        je adl_this_free
;
        cmp al,0E5h
        je adl_this_free
;
    mov di,OFFSET lfn_entry_arr
    mov bp,fs:lfn_entries
    inc bp
    jmp adl_entry_next

adl_this_free:
    sub bp,1
    jz adl_ok
;    
    mov fs:[di].lfnp_sector,edx
    movzx eax,si
    and ax,1FFh
    mov fs:[di].lfnp_offset,eax
    add di,8
    jmp adl_entry_next
    
adl_ok:
    mov fs:lfn_fat_sector,edx
    mov ax,si
    and ax,1FFh
    mov fs:lfn_fat_offset,ax
    clc
    jmp adl_done

adl_entry_next:         
        add si,20h
        test si,1FFh
        jnz adl_entry_loop

adl_dir_next:
        mov al,ds:drive_nr
        UnlockSector                    
        call next_sector
        jnc adl_sector_loop

adl_done:
    pop bp
        pop di
        pop esi
        pop edx
        pop ebx
        pop ax
        ret
allocate_dir_lfn_entries        Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   allocate_lfn_entries
;
;               DESCRIPTION:    Allocate LFN entries
;
;               PARAMETERS:             BX                      Cached dir selector
;                                       GS:EDI      Entry name
;
;       RETURNS:        FS          LFN cache selector 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_lfn_entries    Proc near
    push es
    push eax
    push ecx
    push edx
    push edi
;    
    mov fs,bx
    mov edx,fs:fds_start_sector
;
    mov eax,SIZE lfn_struc
    AllocateSmallGlobalMem
;    
    push di
    mov di,OFFSET lfn_name
    mov cx,40h
    mov eax,-1
    rep stosd
    pop di
;    
    mov es:lfn_entries,1
    mov es:lfn_chksum,0
;    
    xor ah,ah
    mov si,OFFSET lfn_name

ale_entry_loop:
    inc ah
    cmp ah,13
    jbe ale_next_char
;
    inc es:lfn_entries
    inc cx
    mov ah,1

ale_next_char:    
    mov al,gs:[edi]
    mov es:[si],al
    inc si
    inc edi
    or al,al
    jnz ale_entry_loop
;    
    mov ax,es
    mov fs,ax
    mov ax,flat_sel
    mov es,ax
;
    mov cx,fs:lfn_entries
    inc cx
    or edx,edx
    jz ale_root
;
    call allocate_dir_lfn_entries
    jnc ale_done
    jmp ale_fail

ale_root:
    call allocate_root_lfn_entries
    jnc ale_done

ale_fail: 
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
    stc

ale_done:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    ret
allocate_lfn_entries    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   calc_lfn_fat_name
;
;               DESCRIPTION:    Calculate FAT name for a long file
;
;               PARAMETERS:             FS          LFN cache selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

calc_lfn_fat_name   Proc near
    pushad
;    
    mov si,OFFSET lfn_name
    mov bx,OFFSET char_tab
    mov di,OFFSET lfn_fat_name
    mov cx,6

calc_lfn_fat_base_loop:
    lods byte ptr fs:[si]
    cmp al,' '
    je calc_lfn_fat_base_loop
;        
    cmp al,'.'
    jne calc_lfn_fat_base_xlat
;
    mov al,'_'

calc_lfn_fat_base_pad_loop:
    mov fs:[di],al
    inc di
    loop calc_lfn_fat_base_pad_loop
    jmp calc_lfn_fat_base_done

calc_lfn_fat_base_xlat:
    xlat byte ptr cs:char_tab
    or al,al
    jz calc_lfn_fat_base_ill
;
    cmp al,-1
    jne calc_lfn_fat_base_save

calc_lfn_fat_base_ill:
    mov al,'_'

calc_lfn_fat_base_save:
    mov fs:[di],al
    inc di

calc_lfn_fat_base_next:
    loop calc_lfn_fat_base_loop

calc_lfn_fat_base_done:
    mov al,'~'
    mov fs:[di],al
    inc di
    mov al,'1'
    mov fs:[di],al
    inc di
    mov al,'.'
    mov fs:[di],al
    inc di
;
    mov bx,si

calc_lfn_fat_ext_size_loop:
    lods byte ptr fs:[si]
    or al,al
    jz calc_lfn_fat_ext_size_found
;
    cmp al,-1
    je calc_lfn_fat_ext_size_found    
;
    cmp al,'.'
    jne calc_lfn_fat_ext_size_loop
;    
    mov bx,si
    jmp calc_lfn_fat_ext_size_loop

calc_lfn_fat_ext_size_found:
    mov si,bx
    mov bx,OFFSET char_tab
    mov cx,3

calc_lfn_fat_ext_loop:
    lods byte ptr fs:[si]
    cmp al,' '
    je calc_lfn_fat_ext_loop
;    
    cmp al,'.'
    jne calc_lfn_fat_ext_xlat
;
    mov al,' '

calc_lfn_fat_ext_pad_loop:
    mov fs:[di],al
    inc di
    loop calc_lfn_fat_ext_pad_loop
    jmp calc_lfn_fat_done

calc_lfn_fat_ext_xlat:        
    xlat byte ptr cs:char_tab
    or al,al
    jz calc_lfn_fat_ext_ill
;
    cmp al,-1
    jne calc_lfn_fat_ext_save

calc_lfn_fat_ext_ill:
    mov al,'_'

calc_lfn_fat_ext_save:
    mov fs:[di],al
    inc di

calc_lfn_fat_ext_next:
    loop calc_lfn_fat_ext_loop

calc_lfn_fat_done:
    popad
    ret
calc_lfn_fat_name   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   check_lfn_file_entry
;
;               DESCRIPTION:    Check if LFN file entry exists
;
;               PARAMETERS:             FS          LFN cache selector
;                       GS          dir entry sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_lfn_file_entry    Proc near
    pushad
;    
    mov edx,gs:ds_file_ptr
    or edx,edx
    jz check_lfn_file_fail
;    
    mov ebx,edx

check_lfn_file_loop:
    lea edi,[edx].ffe_fat_name
    mov esi,OFFSET lfn_fat_name
    mov ecx,11
    repe cmps byte ptr fs:[esi],[edi]
    jz check_lfn_file_ok
;
    mov edx,es:[edx].de_next
    cmp ebx,edx
    jnz check_lfn_file_loop
        
check_lfn_file_fail:
    stc
    jmp check_lfn_file_done

check_lfn_file_ok:
    clc

check_lfn_file_done:
    popad  
    ret
check_lfn_file_entry    Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   check_lfn_dir_entry
;
;               DESCRIPTION:    Check if LFN dir entry exists
;
;               PARAMETERS:             FS          LFN cache selector
;                       GS          dir entry sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_lfn_dir_entry    Proc near
    pushad
;    
    mov edx,gs:ds_dir_ptr
    or edx,edx
    jz check_lfn_dir_fail
;    
    mov ebx,edx

check_lfn_dir_loop:
    lea edi,[edx].fde_fat_name
    mov esi,OFFSET lfn_fat_name
    mov ecx,11
    repe cmps byte ptr fs:[esi],[edi]
    jz check_lfn_dir_ok
;
    mov edx,es:[edx].de_next
    cmp ebx,edx
    jnz check_lfn_dir_loop
        
check_lfn_dir_fail:
    stc
    jmp check_lfn_dir_done

check_lfn_dir_ok:
    clc

check_lfn_dir_done:
    popad  
    ret
check_lfn_dir_entry    Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   make_lfn_fat_name_unique
;
;               DESCRIPTION:    Make LFN fat name unique
;
;               PARAMETERS:             FS          LFN cache selector
;                       BX          dir entry sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

make_lfn_fat_name_unique   Proc near
    push gs
    pushad
;
    mov gs,bx

make_lfn_unique_retry:
    call check_lfn_file_entry
    jnc make_lfn_unique_try_new
;
    call check_lfn_dir_entry
    jc make_lfn_unique_ok

make_lfn_unique_try_new:
    mov al,fs:lfn_fat_name+7
    cmp al,'9'
    jne make_lfn_unique_save7
;
    mov al,fs:lfn_fat_name+6
    cmp al,'-'
    jne make_lfn_unique_first6
;
    cmp al,'9'
    jne make_lfn_unique_save6
;
    mov al,fs:lfn_fat_name+5
    cmp al,'-'
    jne make_lfn_unique_first5
;
    cmp al,'9'
    jne make_lfn_unique_save5
;
    mov al,fs:lfn_fat_name+4
    cmp al,'-'
    jne make_lfn_unique_first4
;
    cmp al,'9'
    jne make_lfn_unique_save4
;
    mov al,fs:lfn_fat_name+3
    cmp al,'-'
    jne make_lfn_unique_first3
;
    cmp al,'9'
    jne make_lfn_unique_save3
;
    stc
    jmp make_lfn_unique_done    

make_lfn_unique_save3:    
    inc al
    mov fs:lfn_fat_name+3,al
    mov fs:lfn_fat_name+4,'0'
    mov fs:lfn_fat_name+5,'0'
    mov fs:lfn_fat_name+6,'0'
    mov fs:lfn_fat_name+7,'0'
    jmp make_lfn_unique_retry

make_lfn_unique_first3:
    mov fs:lfn_fat_name+2,'-'
    mov fs:lfn_fat_name+3,'0'
    mov fs:lfn_fat_name+4,'0'
    mov fs:lfn_fat_name+5,'0'
    mov fs:lfn_fat_name+6,'0'
    mov fs:lfn_fat_name+7,'0'
    jmp make_lfn_unique_retry

make_lfn_unique_save4:    
    inc al
    mov fs:lfn_fat_name+4,al
    mov fs:lfn_fat_name+5,'0'
    mov fs:lfn_fat_name+6,'0'
    mov fs:lfn_fat_name+7,'0'
    jmp make_lfn_unique_retry

make_lfn_unique_first4:
    mov fs:lfn_fat_name+3,'-'
    mov fs:lfn_fat_name+4,'0'
    mov fs:lfn_fat_name+5,'0'
    mov fs:lfn_fat_name+6,'0'
    mov fs:lfn_fat_name+7,'0'
    jmp make_lfn_unique_retry

make_lfn_unique_save5:    
    inc al
    mov fs:lfn_fat_name+5,al
    mov fs:lfn_fat_name+6,'0'
    mov fs:lfn_fat_name+7,'0'
    jmp make_lfn_unique_retry

make_lfn_unique_first5:
    mov fs:lfn_fat_name+4,'-'
    mov fs:lfn_fat_name+5,'0'
    mov fs:lfn_fat_name+6,'0'
    mov fs:lfn_fat_name+7,'0'
    jmp make_lfn_unique_retry
    
make_lfn_unique_save6:
    inc al
    mov fs:lfn_fat_name+6,al        
    mov fs:lfn_fat_name+7,'0'
    jmp make_lfn_unique_retry

make_lfn_unique_first6:
    mov fs:lfn_fat_name+5,'-'
    mov fs:lfn_fat_name+6,'0'
    mov fs:lfn_fat_name+7,'0'
    jmp make_lfn_unique_retry
    
make_lfn_unique_save7:
    inc al
    mov fs:lfn_fat_name+7,al        
    jmp make_lfn_unique_retry

make_lfn_unique_ok: 
    clc   

make_lfn_unique_done:
    popad
    pop gs
    ret
make_lfn_fat_name_unique   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   allocate_lfn_list_entries
;
;               DESCRIPTION:    Allocate LFN entries from free / deleted list
;
;               PARAMETERS:             FS          LFN cache selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_lfn_list_entries    Proc near
    pushad
;    
    mov si,OFFSET lfn_entry_arr
    mov cx,fs:lfn_entries

allocate_lfn_list_loop:
    mov edx,fs:[si].lfnp_sector
    mov eax,fs:[si].lfnp_offset
    call GetSpecFreeEntry
    jnc allocate_lfn_list_next
;
    call GetSpecDeletedEntry
    jc allocate_lfn_list_done

allocate_lfn_list_next:
    push ecx
        xor ecx,ecx
        FreeLinear
        pop ecx
;
    add si,8
    loop allocate_lfn_list_loop
;
    clc
    jmp allocate_lfn_list_done    

allocate_lfn_list_done:
    popad
    ret
allocate_lfn_list_entries    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   write_lfn_entries
;
;               DESCRIPTION:    Write LFN entries
;
;               PARAMETERS:             FS          LFN cache selector
;                       AL          Checksum
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_lfn_entries    Proc near
    pushad
;
    mov fs:lfn_chksum,al
    mov fs:lfn_seq,1
;
    mov bx,fs:lfn_entries
    mov bh,bl
    or bh,40h
    mov bl,al
    mov si,OFFSET lfn_entry_arr
    mov cx,fs:lfn_entries
    dec cx
    mov di,OFFSET lfn_name
    mov ax,13
    mul cx
    add di,ax

write_lfn_loop:
    mov edx,fs:[si].lfnp_sector
    mov eax,fs:[si].lfnp_offset
    push si
    push di
;    
    push bx
    push ax
        mov al,ds:drive_nr
    LockSector
    pop ax
    or esi,eax
    xchg esi,edi
    xor ax,ax
    lods byte ptr fs:[si]
    mov word ptr es:[edi].lfne_char1,ax
    lods byte ptr fs:[si]
    mov word ptr es:[edi].lfne_char2,ax
    lods byte ptr fs:[si]
    mov word ptr es:[edi].lfne_char3,ax
    lods byte ptr fs:[si]
    mov word ptr es:[edi].lfne_char4,ax
    lods byte ptr fs:[si]
    mov word ptr es:[edi].lfne_char5,ax
    lods byte ptr fs:[si]
    mov word ptr es:[edi].lfne_char6,ax
    lods byte ptr fs:[si]
    mov word ptr es:[edi].lfne_char7,ax
    lods byte ptr fs:[si]
    mov word ptr es:[edi].lfne_char8,ax
    lods byte ptr fs:[si]
    mov word ptr es:[edi].lfne_char9,ax
    lods byte ptr fs:[si]
    mov word ptr es:[edi].lfne_char10,ax
    lods byte ptr fs:[si]
    mov word ptr es:[edi].lfne_char11,ax
    lods byte ptr fs:[si]
    mov word ptr es:[edi].lfne_char12,ax
    lods byte ptr fs:[si]
    mov word ptr es:[edi].lfne_char13,ax
;
    mov es:[edi].lfne_attrib,0Fh
    mov es:[edi].lfne_type,0
    pop dx
    mov es:[edi].lfne_chksum,dl
    mov es:[edi].lfne_clust,0
    mov es:[edi].lfne_seq,dh
    and dh,3Fh
    dec dh
    pop di
    pop si
;
    push dx
    ModifySector
    UnlockSector
    pop bx
;
    add si,8
    sub di,13
    or bh,bh
    jnz write_lfn_loop    
;
    popad
    ret
write_lfn_entries    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   get_entry_name_size
;
;               DESCRIPTION:    Get dir entry name size
;
;               PARAMETERS:             ESI             Entry data
;
;               RETURNS:                ECX             Size of entry name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_entry_name_size     Proc near
        push dx
        push esi
;
        xor ecx,ecx
        xor dl,dl
        mov cx,8
        add esi,OFFSET fat_base

get_name_base_loop:
        lods byte ptr es:[esi]
        cmp al,' '
        je get_name_base_ok
;
        inc dl
        loop get_name_base_loop
;
        inc esi

get_name_base_ok:
        dec esi
        add esi,ecx
        inc dl
;
        mov cx,3

get_name_ext_loop:
        lods byte ptr es:[esi]
        cmp al,' '
        je get_name_ext_ok
;
        inc dl
        loop get_name_ext_loop

get_name_ext_ok:
        movzx ecx,dl
        pop esi
        pop dx
        ret
get_entry_name_size     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   copy_entry_name
;
;               DESCRIPTION:    Copy entry name
;
;               PARAMETERS:             ESI             Entry data
;                                               EDI             Dir entry name offset
;
;       RETURNS:        CX      Size of name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

copy_entry_name Proc near
        push dx
        push esi
        push edi
;
        xor ecx,ecx
        xor dx,dx
        mov cx,8
copy_name_base_loop:
        lods byte ptr es:[esi]
        cmp al,' '
        je copy_name_base_ok
;
        inc dx
        stos byte ptr es:[edi]
        loop copy_name_base_loop
;
        inc esi

copy_name_base_ok:
        dec esi
        add esi,ecx
        mov al,'.'
        inc dx
        stos byte ptr es:[edi]
;
        mov cx,3
copy_name_ext_loop:
        lods byte ptr es:[esi]
        cmp al,' '
        je copy_name_ext_ok
;
        inc dx
        stos byte ptr es:[edi]
        loop copy_name_ext_loop

copy_name_ext_ok:
        mov al,es:[edi-1]
        cmp al,'.'
        jne copy_name_add_zero
;
        dec edi
        dec dx

copy_name_add_zero:
        xor al,al
        stos byte ptr es:[edi]
;
        mov cx,dx
        pop edi
        pop esi
        pop dx
        ret
copy_entry_name Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   copy_entry_xlat
;
;               DESCRIPTION:    Copy entry name & translate
;
;               PARAMETERS:             ESI             Entry data
;                                               EDI             Dir entry name offset
;                       BX      Table
;
;       RETURNS:        CX      Size of name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

copy_entry_xlat Proc near
        push dx
        push esi
        push edi
;
        xor ecx,ecx
        xor dx,dx
        mov cx,8
xcopy_name_base_loop:
        lods byte ptr es:[esi]
        xlat byte ptr cs:char_tab
        cmp al,' '
        je xcopy_name_base_ok
;
        inc dx
        stos byte ptr es:[edi]
        loop xcopy_name_base_loop
;
        inc esi

xcopy_name_base_ok:
        dec esi
        add esi,ecx
        mov al,'.'
        inc dx
        stos byte ptr es:[edi]
;
        mov cx,3
xcopy_name_ext_loop:
        lods byte ptr es:[esi]
        xlat cs:byte ptr char_tab
        cmp al,' '
        je xcopy_name_ext_ok
;
        inc dx
        stos byte ptr es:[edi]
        loop xcopy_name_ext_loop

xcopy_name_ext_ok:
        mov al,es:[edi-1]
        cmp al,'.'
        jne xcopy_name_add_zero
;
        dec edi
        dec dx

xcopy_name_add_zero:
        xor al,al
        stos byte ptr es:[edi]
;
        mov cx,dx
        pop edi
        pop esi
        pop dx
        ret
copy_entry_xlat Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   get_lfn_name_size
;
;               DESCRIPTION:    Get LFN name size
;
;               PARAMETERS:             DI                      Cached dir selector
;                                               EDX                     Sector
;                                               ESI                     Entry data
;                       FS          LFN data
;
;               RETURNS:                NC          LFN valid
;                           ECX         Size of LFN name
;                       
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_lfn_name_size       Proc near
    push ax
    push bx
    push dx
;
    mov ax,fs
    or ax,ax    
    stc
    jz get_lfn_name_size_done
;
    push esi
    xor al,al
    mov cx,11

get_lfn_chksum_loop:
    ror al,1
    add al,es:[esi]
    inc esi
    loop get_lfn_chksum_loop
;            
    pop esi
    cmp al,fs:lfn_chksum
    jne get_lfn_name_delete
;
    mov al,fs:lfn_seq
    cmp al,1
    je get_lfn_name_size_start

get_lfn_name_delete:
    call delete_lfn_entries
    stc
    jmp get_lfn_name_size_done

get_lfn_name_size_start:
    mov bx,OFFSET lfn_name
    xor ecx,ecx
    mov dx,255

get_lfn_name_size_loop:
    mov al,fs:[bx]
    or al,al
    jz get_lfn_name_size_ok
;
    cmp al,-1
    je get_lfn_name_size_ok
;
    inc cx
    inc bx
    sub dx,1
    jnz get_lfn_name_size_loop
;
    mov byte ptr fs:[bx],0    

get_lfn_name_size_ok:
    clc

get_lfn_name_size_done:
    pop dx
    pop bx
    pop ax
    ret
get_lfn_name_size   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   get_entry_time
;
;               DESCRIPTION:    Get entry time
;
;               PARAMETERS:             ESI             Entry data
;
;               RETURNS:                EDX:EAX         Time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_entry_time  Proc near
        push bx
        push cx
;
        mov dx,es:[esi].fat_date
        mov ax,dx
        shr dx,9
        add dx,1980
        mov cx,ax
        shr cx,5
        mov ch,cl
        and ch,0Fh
        mov cl,al
        and cl,1Fh
        mov bx,es:[esi].fat_time
        mov ax,bx
        shr bx,11
        mov bh,bl
        shr ax,5
        and al,3Fh
        mov bl,al
        mov ax,es:[esi].fat_time
        mov ah,al
        add ah,ah
        and ah,3Fh
        TimeToBinary
        add eax,1193
        adc edx,0
;
        pop cx
        pop bx
        ret
get_entry_time  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   is_valid_fat_name
;
;               DESCRIPTION:    Check if file is valid 8.3 name
;
;               PARAMETERS:             GS:EDI  Entry name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_valid_fat_name       PROC near
    push ax
        push bx
        push cx
        push dx
        push edi
;
        mov bx,OFFSET lfn_tab
        xor dx,dx
        xor cx,cx    

is_valid_fat_name_loop:
    mov al,gs:[edi]
    or al,al
    jz is_valid_fat_name_check
;    
    cmp al,'.'
    je is_valid_fat_name_dot
;   
        xlat byte ptr cs:lfn_tab
        or dl,al
    inc cx
        jmp is_valid_fat_name_next

is_valid_fat_name_dot:
    or dh,dh
    jne is_valid_fat_name_fail
;    
    cmp cx,8
    ja is_valid_fat_name_fail
;
    inc dh
    xor cx,cx

is_valid_fat_name_next: 
    inc edi
    jmp is_valid_fat_name_loop

is_valid_fat_name_check:
    or dh,dh
    je is_valid_fat_name_check_base

is_valid_fat_name_check_ext:
    cmp cx,3
    ja is_valid_fat_name_fail
    jmp is_valid_fat_name_83_ok 

is_valid_fat_name_check_base:
    cmp cx,8
    ja is_valid_fat_name_fail

is_valid_fat_name_83_ok:
    test dl,FAT_INVALID
    jnz is_valid_fat_name_fail
;
    and dl,FAT_LOWER OR FAT_UPPER
    cmp dl,FAT_LOWER OR FAT_UPPER
    je is_valid_fat_name_fail
;
    clc
    jmp is_valid_fat_name_done

is_valid_fat_name_fail:
    stc

is_valid_fat_name_done:         
        pop edi
        pop dx
        pop cx
        pop bx
        pop ax
        ret
is_valid_fat_name       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   extend_dir
;
;               DESCRIPTION:    Extend directory
;
;               PARAMETERS:             FS              Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extend_dir      Proc near
        pushad
;
        mov ax,fs:ds_parent
        or ax,ax
        jnz extend_dir_do
;
        cmp ds:fat_type,fat32
        stc
        jne extend_dir_done

extend_dir_do:
        mov al,ds:drive_nr
        mov edi,fs:ds_handle
        mov edx,es:[edi].fde_start_cluster

extend_dir_loop:
        mov ecx,edx
        call next_cluster
        jnc extend_dir_loop
;
        call allocate_cluster
        jc extend_dir_done
;
        xchg ecx,edx
        call link_cluster
        xchg ecx,edx
;
        sub edx,2
        mov cl,ds:fat_cluster_shift
        shl edx,cl
        add edx,ds:start_sector
        mov bx,1
        shl bx,cl
        mov cx,bx

extend_dir_sector_loop:
        push cx
        push edx
        mov al,ds:drive_nr
        LockSector
        jc extend_dir_try_next
;
        mov edi,esi
        mov ecx,80h
        xor eax,eax
        rep stos dword ptr es:[edi]

extend_dir_entry_loop:
        mov di,fs
        call cache_free_entry
        add si,20h
        test si,1FFh
        jnz extend_dir_entry_loop
;
        ModifySector
        UnlockSector

extend_dir_try_next:
        pop edx
        pop cx
        inc edx
        loop extend_dir_sector_loop
;
        clc

extend_dir_done:
        popad
        ret
extend_dir      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   allocate_dir_entry
;
;               DESCRIPTION:    Allocate a new directory entry
;
;               PARAMETERS:             FS              Dir selector
;
;               RETURNS:                EDX             Sector
;                                               AX              Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dir_entry      Proc near
        mov edx,fs:fds_deleted_ptr
        or edx,edx
        jz alloc_dir_try_free
;
        mov bx,fs
        call GetDeletedEntry
        jnc alloc_dir_init

alloc_dir_try_free:
        mov edx,fs:fds_free_ptr
        or edx,edx
        jz alloc_dir_extend
;
        mov bx,fs
        call GetFreeEntry
        jnc alloc_dir_init

alloc_dir_extend:
        call extend_dir
        jnc alloc_dir_try_free
        jmp alloc_dir_done

alloc_dir_init:
        mov ax,es:[edx].fe_entry_offset
        push es:[edx].fe_entry_sector
        push ecx
        xor ecx,ecx
        FreeLinear
        pop ecx
        pop edx
        clc

alloc_dir_done:
        ret
allocate_dir_entry      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   set_dir_name
;
;               DESCRIPTION:    Set name of dir entry
;
;               PARAMETERS:             GS:EDI  Name of entry
;                                               ESI             Disk data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dir_name    PROC near
        push ax
        push bx
        push ecx
        push esi
        push edi
;
        mov bx,OFFSET char_tab
        xchg esi,edi
        mov al,gs:[esi]
        cmp al,'.'
        jne set_name_base

set_name_spec:
        inc esi
        mov ecx,10
        stos byte ptr es:[edi]
        lods byte ptr gs:[esi]
        or al,al
        je set_name_pad
;
        cmp al,'.'
        stc
        jne set_name_done
;
        dec cx
        stos byte ptr es:[edi]
        lods byte ptr gs:[esi]
        or al,al        
        je set_name_pad
;
        stc
        jmp set_name_done
        
set_name_base:
        mov ecx,8
set_name_base_loop:
        lods byte ptr gs:[esi]
        xlat byte ptr cs:char_tab
        or al,al
        je set_name_ext
;
        cmp al,'.'
        je set_name_ext
;
        stos byte ptr es:[edi]
        loop set_name_base_loop
;
        lods byte ptr gs:[esi]
        xlat byte ptr cs:char_tab
        or al,al
        je set_name_ext
;
        cmp al,'.'
        je set_name_ext
;
        stc
        jmp set_name_done

set_name_ext:
        mov ah,al
        mov al,' '
        rep stos byte ptr es:[edi]
        mov ecx,3
        mov al,ah
        or al,al
        je set_name_pad

set_name_ext_loop:
        lods byte ptr gs:[esi]
        xlat byte ptr cs:char_tab
        or al,al
        je set_name_pad
;
        stos byte ptr es:[edi]
        loop set_name_ext_loop
;
        lods byte ptr gs:[esi]
        or al,al
        clc
        je set_name_done

set_name_pad:
        mov al,' '
        rep stos byte ptr es:[edi]
        clc

set_name_done:
        pop edi
        pop esi
        pop ecx
        pop bx
        pop ax
        ret
set_dir_name    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   set_dir_time
;
;               DESCRIPTION:    Set dir entry time
;
;               PARAMETERS:             EDX:EAX Time
;                                               ESI             Disk data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dir_time    Proc near
        push eax
        push bx
        push cx
        push edx
;       
    add eax,1193
    adc edx,0
        BinaryToTime
        shl cl,3
        shr cx,3
        sub dx,1980
        mov dh,dl
        shl dh,1
        xor dl,dl
        or dx,cx
        mov al,ah
        shr al,1
        shl bl,2
        shl bx,3
        or bl,al
        mov es:[esi].fat_time,bx
        mov es:[esi].fat_date,dx
;
        pop edx
        pop cx
        pop bx
        pop eax
        ret
set_dir_time    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CACHE_FREE_ENTRY
;
;               DESCRIPTION:    Cache free entry
;
;               PARAMETERS:             DI                      Cached dir selector
;                                               EDX                     Sector
;                                               ESI                     Entry data
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_free_entry        Proc near
        push eax
        push bx
        push edx
        push edi
;
        mov bx,di
        push edx
        mov eax,SIZE fe_struc
        AllocateSmallLinear
        mov edi,edx
        pop edx
;
        mov es:[edi].fe_entry_sector,edx
        mov ax,si
        and ax,1FFh
        mov es:[edi].fe_entry_offset,ax
;
        mov edx,edi
        call InsertFreeEntry
;
        pop edi
        pop edx
        pop bx
        pop eax
        ret
cache_free_entry        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CACHE_DELETED_ENTRY
;
;               DESCRIPTION:    Cache deleted entry
;
;               PARAMETERS:             DI                      Cached dir selector
;                                               EDX                     Sector
;                                               ESI                     Entry data
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_deleted_entry     Proc near
        push eax
        push bx
        push edx
        push edi
;
        mov bx,di
        push edx
        mov eax,SIZE fe_struc
        AllocateSmallLinear
        mov edi,edx
        pop edx
;
        mov es:[edi].fe_entry_sector,edx
        mov ax,si
        and ax,1FFh
        mov es:[edi].fe_entry_offset,ax
;
        mov edx,edi
        call InsertDeletedEntry
;
        pop edi
        pop edx
        pop bx
        pop eax
        ret
cache_deleted_entry     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CACHE_FILE_ENTRY
;
;               DESCRIPTION:    Cache file entry
;
;               PARAMETERS:             DI                      Cached dir selector
;                                               EDX                     Sector
;                                               ESI                     Entry data
;                       FS          LFN cache
;
;               RETURNS:                EDX                     Dir file entry
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_file_entry        Proc near
        push eax
        push bx
        push ecx
        push edi
;
        mov bx,di
    call get_lfn_name_size
    jc cache_file_83
;
        mov eax,SIZE ffe_struc
        add eax,ecx
        push edx
        AllocateSmallLinear
        mov edi,edx
        add edx,OFFSET ffe_name
        mov es:[edi].de_name,edx
        pop edx
        mov al,ds:drive_nr
        mov es:[edi].de_drive,al
        mov es:[edi].de_usage,0
        mov al,es:[esi].fat_attrib
        mov es:[edi].de_attrib,al
        mov es:[edi].ffe_entry_sector,edx
        mov ax,si
        and ax,1FFh
        mov es:[edi].ffe_entry_offset,ax
;       
    push cx
    push edi
        lea edi,[edi].ffe_fat_name
        call copy_entry_name
        pop edi
        pop cx
;       
        push ecx
    push esi
    push edi
;    
    movzx ecx,cx
    mov esi,OFFSET lfn_name
        mov edi,es:[edi].de_name
        rep movs byte ptr es:[edi],fs:[esi]
        xor al,al
        stos byte ptr es:[edi]
;       
        pop edi
        pop esi
        pop ecx
        mov es:[edi].de_name_size,cx
;
    push esi
    push edi
    movzx ecx,fs:lfn_entries
    mov es:[edi].ffe_lfn_count,cx
    shl ecx,3
    mov esi,OFFSET lfn_entry_arr
    lea edi,[edi].ffe_lfn_arr
        rep movs dword ptr es:[edi],fs:[esi]            
        pop edi
        pop esi
;
    push es
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
    pop es
    jmp cache_file_time

cache_file_83:  
        call get_entry_name_size
        mov eax,SIZE ffe_struc
        add eax,ecx
        push edx
        AllocateSmallLinear
        mov edi,edx
        add edx,OFFSET ffe_name
        mov es:[edi].de_name,edx
        pop edx
        mov al,ds:drive_nr
        mov es:[edi].de_drive,al
        mov es:[edi].de_usage,0
        mov al,es:[esi].fat_attrib
        mov es:[edi].de_attrib,al
        mov es:[edi].ffe_entry_sector,edx
        mov ax,si
        and ax,1FFh
        mov es:[edi].ffe_entry_offset,ax
    mov es:[edi].ffe_lfn_count,0
;       
    push edi
        lea edi,[edi].ffe_fat_name
        call copy_entry_name
        pop edi
;       
    push bx
    push edi
        mov edi,es:[edi].de_name
        mov bx,OFFSET lower_tab
        call copy_entry_xlat
        pop edi
        pop bx
        mov es:[edi].de_name_size,cx

cache_file_time:
        call get_entry_time
        mov es:[edi].de_time,eax
        mov es:[edi+4].de_time,edx
;
        cmp ds:fat_type,fat32
        je cache_file_entry_cluster32
;
        movzx eax,es:[esi].fat_cluster
        jmp cache_file_entry_cluster_ok

cache_file_entry_cluster32:
        mov ax,es:[esi].fat_cluster_hi
        shl eax,16
        mov ax,es:[esi].fat_cluster

cache_file_entry_cluster_ok:    
        mov es:[edi].ffe_start_cluster,eax
        mov eax,es:[esi].fat_file_size
        mov es:[edi].dfe_data_size,eax
        mov es:[edi].dfe_file_sel,0
;
        mov edx,edi
        InsertFileEntry
;
        pop edi
        pop ecx
        pop bx
        pop eax
        ret
cache_file_entry        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CACHE_DIR_ENTRY
;
;               DESCRIPTION:    Cache dir entry
;
;               PARAMETERS:             DI                      Cached dir selector
;                                               EDX                     Sector
;                                               ESI                     Entry data
;                       FS          LFN cache
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_dir_entry Proc near
        push eax
        push bx
        push ecx
        push edi
;
        mov bx,di
    call get_lfn_name_size
    jc cache_dir_83
;
        mov eax,SIZE fde_struc
        add eax,ecx
        push edx
        AllocateSmallLinear
        mov edi,edx
        add edx,OFFSET fde_name
        mov es:[edi].de_name,edx
        pop edx
        mov al,ds:drive_nr
        mov es:[edi].de_drive,al
        mov es:[edi].de_usage,0
        mov al,es:[esi].fat_attrib
        mov es:[edi].de_attrib,al
        mov es:[edi].fde_entry_sector,edx
        mov ax,si
        and ax,1FFh
        mov es:[edi].fde_entry_offset,ax
;       
    push cx
    push edi
        lea edi,[edi].fde_fat_name
        call copy_entry_name
        pop edi
        pop cx
;       
        push ecx
    push esi
    push edi
;    
    movzx ecx,cx
    mov esi,OFFSET lfn_name
        mov edi,es:[edi].de_name
        rep movs byte ptr es:[edi],fs:[esi]
        xor al,al
        stos byte ptr es:[edi]
;       
        pop edi
        pop esi
        pop ecx
        mov es:[edi].de_name_size,cx
;
    push esi
    push edi
    movzx ecx,fs:lfn_entries
    mov es:[edi].fde_lfn_count,cx
    shl ecx,3
    mov esi,OFFSET lfn_entry_arr
    lea edi,[edi].fde_lfn_arr
        rep movs dword ptr es:[edi],fs:[esi]            
        pop edi
        pop esi
;
    push es
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
    pop es
    jmp cache_dir_time

cache_dir_83:   
        call get_entry_name_size
        mov eax,SIZE fde_struc
        add eax,ecx
        push edx
        AllocateSmallLinear
        mov edi,edx
        add edx,OFFSET fde_name
        mov es:[edi].de_name,edx
        pop edx
        mov al,ds:drive_nr
        mov es:[edi].de_drive,al
        mov es:[edi].de_usage,0
        mov al,es:[esi].fat_attrib
        mov es:[edi].de_attrib,al
        mov es:[edi].fde_entry_sector,edx
        mov ax,si
        and ax,1FFh
        mov es:[edi].fde_entry_offset,ax
    mov es:[edi].fde_lfn_count,0
;       
    push edi
        lea edi,[edi].fde_fat_name
        call copy_entry_name
        pop edi
;       
    push bx
    push edi
        mov edi,es:[edi].de_name
        mov bx,OFFSET lower_tab
        call copy_entry_xlat
        pop edi
        pop bx
        mov es:[edi].de_name_size,cx

cache_dir_time:
        call get_entry_time
        mov es:[edi].de_time,eax
        mov es:[edi+4].de_time,edx
;
        cmp ds:fat_type,fat32
        je cache_dir_entry_cluster32
;
        movzx eax,es:[esi].fat_cluster
        jmp cache_dir_entry_cluster_ok

cache_dir_entry_cluster32:
        mov ax,es:[esi].fat_cluster_hi
        shl eax,16
        mov ax,es:[esi].fat_cluster

cache_dir_entry_cluster_ok:     
        mov es:[edi].fde_start_cluster,eax
        sub eax,2
        mov cl,ds:fat_cluster_shift
        shl eax,cl
        add eax,ds:start_sector
        mov es:[edi].fde_start_sector,eax
;
        mov edx,edi
        InsertDirEntry
;
        pop edi
        pop ecx
        pop bx
        pop eax
        ret
cache_dir_entry Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CACHE_LFN_ENTRY
;
;               DESCRIPTION:    Cache LFN entry
;
;               PARAMETERS:             DI                      Cached dir selector
;                                               EDX                     Sector
;                                               ESI                     Entry data
;                       FS          LFN cache
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_lfn_entry Proc near
    push es
    push eax
    push bx
    push ecx
;
    mov bx,fs
    mov ax,flat_sel
    mov fs,ax
    mov es,bx
;
    or bx,bx
    jnz cache_lfn_check_seq

cache_lfn_retry:
    test fs:[esi].lfne_seq,40h
    jnz cache_lfn_alloc
;
    push es
    push ebx
    push ecx
    push edi
;
    mov ax,flat_sel
    mov es,ax
        mov al,ds:drive_nr
    push esi
        LockSector
        pop esi
        call cache_free_entry
        mov edi,esi
    mov ecx,8
    xor eax,eax
    rep stos dword ptr es:[edi]
    ModifySector
    UnlockSector
;
    pop edi
    pop ecx
    pop ebx        
    pop es
    jmp cache_lfn_done

cache_lfn_alloc:
    mov eax,SIZE lfn_struc
    AllocateSmallGlobalMem
;    
    push di
    mov di,OFFSET lfn_name
    mov cx,40h
    mov eax,-1
    rep stosd
    pop di
;    
    mov es:lfn_entries,0
    mov al,fs:[esi].lfne_chksum
    mov es:lfn_chksum,al
    mov al,fs:[esi].lfne_seq
    and al,3Fh
    jmp cache_lfn_seq_ok

cache_lfn_check_seq:
    mov es,bx
    mov al,fs:[esi].lfne_chksum
    cmp al,es:lfn_chksum
    jne cache_lfn_error
;    
    mov al,fs:[esi].lfne_seq
    mov ah,es:lfn_seq
    dec ah
    cmp al,ah
    je cache_lfn_seq_ok

cache_lfn_error:
    push fs
    mov ax,es
    mov fs,ax
    mov ax,flat_sel
    mov es,ax
    call delete_lfn_entries    
    pop fs
    xor ax,ax
    mov es,ax
    jmp cache_lfn_retry
    
cache_lfn_seq_ok:
    mov es:lfn_seq,al
    mov bx,es:lfn_entries
    cmp bx,20
    jae cache_lfn_error
;
    shl bx,3    
    mov es:lfn_entry_arr.[bx].lfnp_sector,edx
    mov eax,esi
    and eax,1FFh
    mov es:lfn_entry_arr.[bx].lfnp_offset,eax    
    inc es:lfn_entries
;
    push di
    push si
    std
    mov si,OFFSET lfn_name + 255 - 13
    mov di,OFFSET lfn_name + 255
    mov cx,256 - 13
    rep movs byte ptr es:[di],es:[si]    
    cld
    mov di,OFFSET lfn_name
    mov al,-1
    mov cx,13
    rep stosb
    pop si
;
    mov di,OFFSET lfn_name
    mov al,fs:[esi].lfne_char1
    stosb
    mov al,fs:[esi].lfne_char2
    stosb
    mov al,fs:[esi].lfne_char3
    stosb
    mov al,fs:[esi].lfne_char4
    stosb
    mov al,fs:[esi].lfne_char5
    stosb
    mov al,fs:[esi].lfne_char6
    stosb
    mov al,fs:[esi].lfne_char7
    stosb
    mov al,fs:[esi].lfne_char8
    stosb
    mov al,fs:[esi].lfne_char9
    stosb
    mov al,fs:[esi].lfne_char10
    stosb
    mov al,fs:[esi].lfne_char11
    stosb
    mov al,fs:[esi].lfne_char12
    stosb
    mov al,fs:[esi].lfne_char13
    stosb        
    pop di

cache_lfn_done:
    mov ax,es
    mov fs,ax
;
    pop ecx
    pop bx
    pop eax
    pop es
    ret
cache_lfn_entry Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DELETE_LFN_ENTRIES
;
;               DESCRIPTION:    Delete LFN entries
;
;               PARAMETERS:             DI          Cached dir selector
;                       FS          LFN cache
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_lfn_entries      Proc near
    push es
    pushad
;
    mov bx,fs
    or bx,bx
    jz delete_lfn_done
;    
    mov bp,di
    mov cx,fs:lfn_entries
    mov di,OFFSET lfn_entry_arr

delete_lfn_loop:
    mov edx,fs:[di].lfnp_sector
        mov al,ds:drive_nr
        LockSector
        or esi,fs:[di].lfnp_offset
;       
        push ecx
        push edi
        mov edi,esi
        mov ecx,8
        xor eax,eax
    rep stos dword ptr es:[edi]
;    
    mov di,bp
    call cache_free_entry
;
    pop edi
    pop ecx
;
    ModifySector
    UnlockSector
;
    add di,8 
    loop delete_lfn_loop    
;    
    mov ax,fs
    mov es,ax    
    xor ax,ax
    mov fs,ax
    FreeMem

delete_lfn_done:
    popad
    pop es
    ret
delete_lfn_entries  Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CACHE_FREE_LFN
;
;               DESCRIPTION:    Free LFN entry
;
;               PARAMETERS:             FS          LFN cache
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_free_lfn  Proc near
    push es
    push ax
;
    mov ax,fs
    or ax,ax
    jz cache_free_lfn_done
;
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem 

cache_free_lfn_done:   
    pop ax
    pop es    
    ret
cache_free_lfn Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CACHE_ENTRY
;
;               DESCRIPTION:    Cache an entry
;
;               PARAMETERS:             DI                      Cached dir selector
;                                               EDX                     Sector
;                                               ESI                     Entry data
;                       FS          LFN info
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_entry     Proc near
    push edx
;    
        mov al,es:[esi].fat_base
        or al,al
        je cache_entry_free
;
        cmp al,'.'
        je cache_entry_done
;
        cmp al,0E5h
        je cache_entry_deleted
;
        mov al,es:[esi].fat_attrib
        mov ah,al
        and ah,0Fh
        cmp ah,0Fh
        je cache_entry_lfn
;
        test al,10h
        jz cache_entry_file
;
        call cache_dir_entry
        jmp cache_entry_done

cache_entry_file:
        call cache_file_entry
        jmp cache_entry_done

cache_entry_lfn:
    call cache_lfn_entry
    jmp cache_entry_done

cache_entry_deleted:
        call cache_deleted_entry
        jmp cache_entry_done

cache_entry_free:
        call cache_free_entry

cache_entry_done:
    pop edx
        ret
cache_entry     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CACHE_ROOT_DIR
;
;               DESCRIPTION:    Cache root directory structure
;
;               PARAMETERS:             EDI                     Dir entry to cache or 0
;                                               BX                      Cached dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_root_dir  Proc near
    push fs
        push ax
        push ebx
        push cx
        push edx
        push esi
        push di
;
    mov fs,bx
    mov fs:fds_start_sector,0
;
    xor di,di
    mov fs,di
        mov di,bx
        mov cx,ds:root_entries
        shr cx,4
        mov edx,ds:root_sector

cache_root_sector_loop:
        mov al,ds:drive_nr
        LockSector
        jc cache_root_dir_next

cache_root_entry_loop:
        call cache_entry
        add si,20h
        test si,1FFh
        jnz cache_root_entry_loop

cache_root_dir_next:
        UnlockSector                    
        inc edx
        loop cache_root_sector_loop
;
    call delete_lfn_entries
;    
        pop di
        pop esi
        pop edx
        pop cx
        pop ebx
        pop ax
        pop fs
        clc
        ret
cache_root_dir  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CACHE_SUB_DIR
;
;               DESCRIPTION:    Cache subdirectory structure
;
;               PARAMETERS:             EDX                     Start sector
;                                               EDI                     Dir entry to cache or 0
;                                               BX                      Cached dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_sub_dir   Proc near
    push fs
        push ax
        push ebx
        push edx
        push esi
        push di
;
    mov fs,bx
    mov fs:fds_start_sector,edx
;
    xor di,di
    mov fs,di
        mov di,bx       

cache_sub_dir_sector_loop:
        mov al,ds:drive_nr
        LockSector
        jc cache_sub_dir_next

cache_sub_dir_entry_loop:
        call cache_entry
        add si,20h
        test si,1FFh
        jnz cache_sub_dir_entry_loop

cache_sub_dir_next:
        mov al,ds:drive_nr
        UnlockSector                    
        call next_sector
        jnc cache_sub_dir_sector_loop
;
    call delete_lfn_entries
;
        pop di
        pop esi
        pop edx
        pop ebx
        pop ax
        pop fs
        clc
        ret
cache_sub_dir   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CACHE_DIR12_16
;
;               DESCRIPTION:    Cache FAT12 + FAT16 directory structure
;
;               PARAMETERS:             EDX                     Dir entry to cache or 0
;                                               BX                      Cached dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public cache_dir12_16

cache_dir12_16  Proc far
        push es
        push ax
        push edx
;
        mov ax,flat_sel
        mov es,ax
;
        or edx,edx
        jz cache_dir12_16_root
;
        mov edx,es:[edx].fde_start_sector
        call cache_sub_dir
        jmp cache_dir12_16_done

cache_dir12_16_root:
        call cache_root_dir

cache_dir12_16_done:
        pop edx
        pop ax
        pop es
        retf32
cache_dir12_16  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CACHE_DIR32
;
;               DESCRIPTION:    Cache FAT32 directory structure
;
;               PARAMETERS:             EDX                     Dir entry to cache or 0
;                                               BX                      Cached dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public cache_dir32

cache_dir32     Proc far
        push es
        push ax
        push edx
;
        mov ax,flat_sel
        mov es,ax
;
        or edx,edx
        jz cache_dir32_root
;
        mov edx,es:[edx].fde_start_sector
        call cache_sub_dir
        jmp cache_dir32_done

cache_dir32_root:
        mov edx,ds:root_sector
        call cache_sub_dir

cache_dir32_done:
        pop edx
        pop ax
        pop es
        retf32
cache_dir32     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   InitDir
;
;               DESCRIPTION:    Init a new directory
;
;               PARAMETERS:             FS                      DIR SELECTOR
;       
;               RETURNS:                EAX                     CLUSTER
;                                               NC                      SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_dir        Proc near
        push edx
        mov al,ds:drive_nr
        call allocate_cluster
        jc init_dir_done
;
        push ebx
        push ecx
        push edx
        push esi
        push edi
;
        sub edx,2
        mov cl,ds:fat_cluster_shift
        shl edx,cl
        add edx,ds:start_sector
        mov bx,1
        shl bx,cl
        mov cx,bx

init_dir_sector_loop:
        push cx
        mov al,ds:drive_nr
        LockSector
        jc init_dir_try_next
;
        mov edi,esi
        mov ecx,80h
        xor eax,eax
        rep stos dword ptr es:[edi]
;
        ModifySector
        UnlockSector

init_dir_try_next:
        pop cx
        inc edx
        loop init_dir_sector_loop
;
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        mov eax,edx
        clc

init_dir_done:
        pop edx
        ret
init_dir        Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   add_dir
;
;               DESCRIPTION:    Add directory
;
;               PARAMETERS:             BX                      DIR SELECTOR
;                                               GS:EDI          DIR NAME
;                                               EDX                     CLUSTER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_dir Proc near
        push fs
        push ax
        push ebx
        push cx
        push edx
        push esi
        push ebp
;
        mov fs,bx
        mov ebp,edx
;
        call allocate_dir_entry
        jc add_dir_done
;
        push ax
        mov al,ds:drive_nr
        LockSector
        pop ax
        jc add_dir_done
;
        or si,ax
        call set_dir_name
        jc add_dir_unlock
;
        mov es:[esi].fat_cluster,bp
        shr ebp,16
        mov es:[esi].fat_cluster_hi,bp
        mov es:[esi].fat_attrib,10h
        mov es:[esi].fat_file_size,0
        push edx
        GetTime
        call set_dir_time
        pop edx
;
        ModifySector
        UnlockSector
        clc
        jmp add_dir_done

add_dir_unlock:
        mov di,fs
        call cache_free_entry
        UnlockSector
        stc

add_dir_done:
        pop ebp
        pop esi
        pop edx
        pop cx
        pop ebx
        pop ax
        pop fs
        ret
add_dir Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CREATE_DIR
;
;               DESCRIPTION:    Create directory
;
;               PARAMETERS:             ES:EDI          DIRECTORY NAME
;                                               BX                      DIR SELECTOR
;       
;               RETURNS:                EDX                     DIR ENTRY
;                                               NC                      SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public create_dir

dot_dir DB '.', 0
dot_dot_dir     DB '..',0

create_dir      PROC far
        push es
        push fs
        push gs
        push ax
        push ebx
        push cx
        push esi
;
        mov ax,es
        mov gs,ax
        mov ax,flat_sel
        mov es,ax
        mov fs,bx
;
    call is_valid_fat_name
    jnc create_dir_83
;
    call allocate_lfn_entries
    jnc create_dir_lfn
;
    mov fs,bx    
        call extend_dir
;
    call allocate_lfn_entries
    jc create_dir_done

create_dir_lfn:
    call calc_lfn_fat_name
    call make_lfn_fat_name_unique
    jc create_dir_fail_lfn
;
    call allocate_lfn_list_entries
    jc create_dir_fail_lfn
;    
        mov di,bx
    mov edx,fs:lfn_fat_sector
    mov ax,fs:lfn_fat_offset
        push ax
        mov al,ds:drive_nr
        LockSector
        pop ax
;
    push gs
    push di
        or si,ax
        mov ax,fs
        mov gs,ax
        mov edi,OFFSET lfn_fat_name
        call set_dir_name
        pop di
        pop gs
;
    push fs
    mov fs,di
        call init_dir
        pop fs
        jc create_dir_fail_lfn_unlock
;
        mov es:[esi].fat_cluster,ax
        shr eax,16
        mov es:[esi].fat_cluster_hi,ax
        mov es:[esi].fat_attrib,10h
        mov es:[esi].fat_file_size,0
;       
        push edx
        GetTime
        call set_dir_time
        pop edx
;
    push esi
    xor al,al
    mov cx,11

create_dir_chksum_loop:
    ror al,1
    add al,es:[esi]
    inc esi
    loop create_dir_chksum_loop
    pop esi
;
        ModifySector
        UnlockSector
        push edx
;       
    call write_lfn_entries
        call cache_dir_entry
        mov fs,di
    jmp create_dir_lfn_done

create_dir_fail_lfn_unlock:
    UnlockSector
    
create_dir_fail_lfn:
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
    stc
    jmp create_dir_done

create_dir_83:
        call allocate_dir_entry
        jc create_dir_done
;
        push ax
        mov al,ds:drive_nr
        LockSector
        pop ax
        jc create_dir_done
;
        or si,ax
        call set_dir_name
        jc create_dir_unlock
;
        call init_dir
        jc create_dir_unlock
;
        mov es:[esi].fat_cluster,ax
        shr eax,16
        mov es:[esi].fat_cluster_hi,ax
        mov es:[esi].fat_attrib,10h
        mov es:[esi].fat_file_size,0
        push edx
        GetTime
        call set_dir_time
        pop edx
;
        ModifySector
        UnlockSector
;
        mov di,fs
        push edx
;       
        push fs
        xor bx,bx
        mov fs,bx
        call cache_dir_entry
        pop fs

create_dir_lfn_done:
        mov bx,fs
        CacheDir
;
        push gs
        push edi
;
        mov ax,cs
        mov gs,ax
;
        mov edi,OFFSET dot_dir
        mov edx,es:[edx].fde_start_cluster
        call add_dir
;
        mov edi,OFFSET dot_dot_dir
        mov edx,fs:ds_handle
        or edx,edx
        jz create_dir_dot_dot_add
;
        mov edx,es:[edx].fde_start_cluster

create_dir_dot_dot_add:
        call add_dir
;
        pop edi
        pop gs
;
        pop edx
        clc
        jmp create_dir_done

create_dir_unlock:
        mov di,fs
        call cache_free_entry
        UnlockSector
        stc

create_dir_done:
        pop esi
        pop cx
        pop ebx
        pop ax
        pop gs
        pop fs
        pop es
        retf32
create_dir      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DELETE_DIR
;
;               DESCRIPTION:    Delete directory
;
;               PARAMETERS:             BX                      DIR SELECTOR
;                                               EDX                     DIR ENTRY TO DELETE
;                                               NC                      SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public delete_dir

delete_dir      PROC far
        push es
        push fs
        pushad
;
        mov ax,flat_sel
        mov es,ax
        mov eax,es:[edx].fde_entry_sector
        mov cx,es:[edx].fde_entry_offset
        mov edi,es:[edx].fde_start_cluster
        mov es:[edx].fe_entry_sector,eax
        mov es:[edx].fe_entry_offset,cx
        call InsertDeletedEntry
;
        mov fs,bx
        mov edx,eax
        mov al,ds:drive_nr
        LockSector
        or si,cx
        mov byte ptr es:[esi],0E5h
        ModifySector
        UnlockSector
;
        mov edx,edi

delete_dir_cluster_loop:
        mov ebx,edx
        call next_cluster
        jc delete_dir_free_last
;
        xchg ebx,edx
        call free_cluster
        jc delete_dir_done
;
        mov edx,ebx
        jmp delete_dir_cluster_loop

delete_dir_free_last:
        mov edx,ebx
        call free_cluster

delete_dir_done:
        popad
        pop fs
        pop es
        clc
        retf32
delete_dir      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DELETE_FILE
;
;               DESCRIPTION:    Delete file
;
;               PARAMETERS:             BX                      DIR SELECTOR
;                                               EDX                     FILE ENTRY TO DELETE
;                                               NC                      SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public delete_file

delete_file     PROC far
        push ds
        push es
        pushad
;
        mov ax,flat_sel
        mov es,ax
        mov ds,bx
;
    mov cx,es:[edx].ffe_lfn_count
    or cx,cx
    jz delete_file_lfn_done
;
    lea ebp,[edx].ffe_lfn_arr
    push ebx
    push edx
    mov di,bx

delete_file_lfn_loop:
    mov edx,es:[ebp].lfnp_sector
    mov al,ds:ds_drive
    LockSector
    or esi,es:[ebp].lfnp_offset
    call cache_free_entry
    push ecx
    push edi
    mov edi,esi
    mov ecx,8
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop edi
    pop ecx
    ModifySector
    UnlockSector
;
    add ebp,8
    loop delete_file_lfn_loop
;
    pop edx
    pop ebx    

delete_file_lfn_done:
        mov eax,es:[edx].ffe_entry_sector
        mov cx,es:[edx].ffe_entry_offset
        mov es:[edx].fe_entry_sector,eax
        mov es:[edx].fe_entry_offset,cx
        call InsertDeletedEntry
;
        mov edx,eax
        mov al,ds:ds_drive
        LockSector
        or si,cx
        mov byte ptr es:[esi],0E5h
        ModifySector
        UnlockSector
;
        popad
        pop es
        pop ds
        clc
        retf32
delete_file     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   RENAME_FILE
;
;               DESCRIPTION:    Rename file
;
;               PARAMETERS:             FS:EBX          CURRENT NAME
;                                               ES:EDI          NEW NAME
;                                               NC                      SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public rename_file

rename_file     PROC far
        push fs
        push es
        push eax
        push ebx
        push cx
        push edx
        push esi
        push edi
;
        push es
        push edi
        mov dx,fs
        mov gs,dx
        mov dx,flat_sel
        mov es,dx
        mov edx,ebx
;
;       call parse_dir
;       call parse_file
        mov eax,edi
        pop edi
        pop es
        jc rename_file_done
;
        push eax
        mov dx,es
        mov gs,dx
        mov dx,flat_sel
        mov es,dx
        mov edx,edi
;
        mov cx,fs
;       call parse_dir
        mov al,gs:[edx]
        or al,al
        je rename_dest_fail
        mov ax,fs
        cmp ax,cx
        jne rename_dest_fail
;       call parse_file
        jnc rename_dest_fail
        pop edi
;       call lock_dir_entry
        call set_dir_name
        ModifySector
        UnlockSector
        clc
        jmp rename_file_done

rename_dest_fail:
        pop edi
        stc
rename_file_done:
        pop edi
        pop esi
        pop edx
        pop cx
        pop ebx
        pop eax
        pop es
        pop fs
        retf32
rename_file     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CREATE_FILE
;
;               DESCRIPTION:    Create a file
;
;               PARAMETERS:             ES:EDI          Filename
;                                               BX                      Dir
;                                               CX                      Attribute
;
;               RETURNS:                EDX                     Dir entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public create_file

create_file     PROC far
        push es
        push fs
        push gs
        push ax
        push ebx
        push cx
        push esi
;
        mov ax,es
        mov gs,ax
        mov ax,flat_sel
        mov es,ax
        mov fs,bx
;
    call is_valid_fat_name
    jnc create_file_83
;
    call allocate_lfn_entries
    jnc create_file_lfn
;
    mov fs,bx    
        call extend_dir
;
    call allocate_lfn_entries
    jc create_file_done

create_file_lfn:
    call calc_lfn_fat_name
    call make_lfn_fat_name_unique
    jc create_file_fail_lfn
;
    call allocate_lfn_list_entries
    jc create_file_fail_lfn
;    
        mov di,bx
    mov edx,fs:lfn_fat_sector
    mov ax,fs:lfn_fat_offset
        push ax
        mov al,ds:drive_nr
        LockSector
        pop ax
;
        or si,ax
        push gs
        push di
        mov ax,fs
        mov gs,ax
        mov edi,OFFSET lfn_fat_name
        call set_dir_name
        pop di
        pop gs
;
        or cl,20h
        mov es:[esi].fat_attrib,cl
        mov es:[esi].fat_cluster,0
        mov es:[esi].fat_cluster_hi,0
        mov es:[esi].fat_file_size,0
        push edx
        GetTime
        call set_dir_time
        pop edx
;
    push esi
    xor al,al
    mov cx,11

create_file_chksum_loop:
    ror al,1
    add al,es:[esi]
    inc esi
    loop create_file_chksum_loop
    pop esi
;
        ModifySector
        UnlockSector
    call write_lfn_entries
        call cache_file_entry
        clc
        jmp create_file_done

create_file_fail_lfn:
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
    stc
    jmp create_file_done

create_file_83:
        call allocate_dir_entry
        jc create_file_done
;
        push ax
        mov al,ds:drive_nr
        LockSector
        pop ax
        jc create_file_done
;
        or si,ax
        call set_dir_name
        jc create_file_unlock
;
        or cl,20h
        mov es:[esi].fat_attrib,cl
        mov es:[esi].fat_cluster,0
        mov es:[esi].fat_cluster_hi,0
        mov es:[esi].fat_file_size,0
        push eax
        push edx
        GetTime
        call set_dir_time
        pop edx
        pop eax
;
        ModifySector
        UnlockSector
        push fs
        mov di,fs
        xor bx,bx
        mov fs,bx
        call cache_file_entry
        pop fs
        clc
        jmp create_file_done

create_file_unlock:
        mov di,fs
        call cache_free_entry
        UnlockSector
        stc

create_file_done:
        pop esi
        pop cx
        pop ebx
        pop ax
        pop gs
        pop fs
        pop es
        retf32
create_file     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   update_dir
;
;               DESCRIPTION:    Update dir entry
;
;               PARAMETERS:             EDX                     Dir dir entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public update_dir

update_dir      PROC far
        push es
        pushad
;
        mov ax,flat_sel
        mov es,ax
;
        mov edi,edx
        mov edx,es:[edi].fde_entry_sector
        mov al,ds:drive_nr
        LockSector
        jc update_dir_entry_done
;
        or si,es:[edi].fde_entry_offset
        mov cl,es:[edi].de_attrib
        and cl,NOT 10h
        mov ch,es:[esi].fat_attrib
        and ch,10h
        or cl,ch
        mov es:[esi].fat_attrib,cl
        mov eax,es:[edi].de_time
        mov edx,es:[edi].de_time+4
        call set_dir_time
;
        ModifySector
        UnlockSector

update_dir_entry_done:
        popad
        pop es
        retf32
update_dir      ENDP
        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   update_file_entry
;
;               DESCRIPTION:    Update file entry
;
;               PARAMETERS:             EDX                     Dir file entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public update_file

update_file     PROC far
        push es
        pushad
;
        mov ax,flat_sel
        mov es,ax
;
        mov edi,edx
        mov edx,es:[edi].ffe_entry_sector
        mov al,ds:drive_nr
        LockSector
        jc update_file_entry_done
;
        or si,es:[edi].ffe_entry_offset
        mov cl,es:[edi].de_attrib
        and cl,NOT 10h
        mov ch,es:[esi].fat_attrib
        and ch,10h
        or cl,ch
        mov es:[esi].fat_attrib,cl
        mov eax,es:[edi].de_time
        mov edx,es:[edi].de_time+4
        call set_dir_time
;
        ModifySector
        UnlockSector

update_file_entry_done:
        popad
        pop es
        retf32
update_file     ENDP
        

code    ENDS

        END

