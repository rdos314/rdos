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
; FATTAB.ASM
; FAT allocation chain support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE system.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\fs.inc
INCLUDE fat.inc

        extrn lock_sector:near

        .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   LOCK_FAT
;
;               DESCRIPTION:    Lock first or second FAT sector, whichever is successful
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Sector # of first FAT
;
;               RETURNS:                EBX                     Handle
;                                               ESI                     Linear address
;                                               NC                      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_fat        PROC near
        call lock_sector
        jnc lock_fat_done
        push edx
        sub edx,ds:fat1_sector
        add edx,ds:fat2_sector
        call lock_sector
        pop edx
        jnc lock_fat_done
        xor ebx,ebx
        stc
lock_fat_done:
        ret
lock_fat        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   UPDATE_CLUSTER_LINK12
;
;               DESCRIPTION:    Update cluster link for FAT12
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Cluster #
;                                               ECX                     Next cluster
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_cluster_link12   PROC near
        push ebx
        push ecx
        push edx
        push esi
        push di
;
        cmp edx,ds:clusters
        cmc
        jc update_cluster_link_done2
;
        push ecx
        mov ecx,edx
        add edx,edx
        add edx,ecx
        mov ecx,edx
        shr edx,10
        add edx,ds:fat1_sector
        and cx,3FFh
        mov di,cx
        clc
        rcr cx,1
        pushf
        call lock_sector
        jnc update_cluster_link_low1
        popf
        pop ecx
        push edx
        jmp update_cluster_link_done1

update_cluster_link_low1:
        or si,cx
        popf
        pop ecx
        push edx
        jc update_cluster_link_high1
        mov es:[esi],cl
        inc si
        test si,1FFh
        jnz update_cluster_link_low_ok1
        ModifySector
        UnlockSector
        inc edx
        call lock_sector
        jc update_cluster_link_done1
        
update_cluster_link_low_ok1:
        push ax
        mov al,es:[esi]
        and al,0F0h
        or al,ch
        mov es:[esi],al
        pop ax
        jmp update_cluster_link_ok1

update_cluster_link_high1:
        push cx
        push ax
        ror cx,4
        mov al,es:[esi]
        and al,0Fh
        or al,ch
        mov es:[esi],al
        pop ax
        inc si
        test si,1FFh
        jnz update_cluster_link_high_ok1
        ModifySector
        UnlockSector
        inc edx
        call lock_sector
        jnc update_cluster_link_high_ok1
        pop cx
        jmp update_cluster_link_done1

update_cluster_link_high_ok1:
        mov es:[esi],cl
        pop cx
update_cluster_link_ok1:
        ModifySector
        UnlockSector

update_cluster_link_done1:
        pop edx
        push cx
        sub edx,ds:fat1_sector
        add edx,ds:fat2_sector
        mov cx,di
        clc
        rcr cx,1
        pushf
        call lock_sector
        jnc update_cluster_link_low2
        popf
        pop cx
        jmp update_cluster_link_done2

update_cluster_link_low2:
        or si,cx
        popf
        pop cx
        jc update_cluster_link_high2
        mov es:[esi],cl
        inc si
        test si,1FFh
        jnz update_cluster_link_low_ok2
        ModifySector
        UnlockSector
        inc edx
        call lock_sector
        jc update_cluster_link_done2
        
update_cluster_link_low_ok2:
        push ax
        mov al,es:[esi]
        and al,0F0h
        or al,ch
        mov es:[esi],al
        pop ax
        jmp update_cluster_link_ok2

update_cluster_link_high2:
        push cx
        push ax
        ror cx,4
        mov al,es:[esi]
        and al,0Fh
        or al,ch
        mov es:[esi],al
        pop ax
        inc si
        test si,1FFh
        jnz update_cluster_link_high_ok2
        ModifySector
        UnlockSector
        inc edx
        call lock_sector
        jnc update_cluster_link_high_ok2
        pop cx
        jmp update_cluster_link_done2

update_cluster_link_high_ok2:
        mov es:[esi],cl
        pop cx
update_cluster_link_ok2:
        ModifySector
        UnlockSector

update_cluster_link_done2:
;
        pop di
        pop esi
        pop edx
        pop ecx
        pop ebx
        ret
update_cluster_link12   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   UPDATE_CLUSTER_LINK16
;
;               DESCRIPTION:    Update cluster link for FAT16
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Cluster #
;                                               ECX                     Next cluster
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_cluster_link16   PROC near
        push ebx
        push ecx
        push edx
        push esi
        push di
;
        cmp edx,ds:clusters
        cmc
        jc update_cluster_link16_done
        mov di,cx
        movzx edx,dx
        add edx,edx
        mov cx,dx
        shr edx,9
        add edx,ds:fat1_sector
        and cx,1FFh
        call lock_sector
        jc update_cluster_link16_fat2
        or si,cx
        mov es:[esi],di
        ModifySector
        UnlockSector
update_cluster_link16_fat2:
        sub edx,ds:fat1_sector
        add edx,ds:fat2_sector
        call lock_sector
        jc update_cluster_link16_done
        or si,cx
        mov es:[esi],di
        ModifySector
        UnlockSector
        clc
update_cluster_link16_done:
;
        pop di
        pop esi
        pop edx
        pop ecx
        pop ebx
        ret
update_cluster_link16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   UPDATE_CLUSTER_LINK32
;
;               DESCRIPTION:    Update cluster link for FAT32
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Cluster #
;                                               ECX                     Next cluster
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_cluster_link32   PROC near
        push ebx
        push ecx
        push edx
        push esi
        push edi
;
        cmp edx,ds:clusters
        cmc
        jc update_cluster_link32_done
        mov edi,ecx
        and edx,0FFFFFFFh
        shl edx,2
        mov ecx,edx
        shr edx,9
        add edx,ds:fat1_sector
        and cx,1FFh
        call lock_sector
        jc update_cluster_link32_fat2
        or si,cx
        mov es:[esi],edi
        ModifySector
        UnlockSector
update_cluster_link32_fat2:
        sub edx,ds:fat1_sector
        add edx,ds:fat2_sector
        call lock_sector
        jc update_cluster_link32_done
        or si,cx
        mov es:[esi],edi
        ModifySector
        UnlockSector
        clc
update_cluster_link32_done:
;
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        ret
update_cluster_link32   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   NEXT_CLUSTER12
;
;               DESCRIPTION:    Find next cluster for FAT12
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Cluster #
;
;               RETURNS:                EDX                     Next cluster #
;                                               NC                      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

next_cluster12  PROC near
        push ds
        push ebx
        push cx
        push esi
;
        EnterSection ds:cluster_section
        mov cx,dx
        add dx,dx
        add dx,cx
        mov cx,dx
        movzx edx,dx
        shr edx,10
        add edx,ds:fat1_sector
        and cx,3FFh
        clc
        rcr cx,1
        pushf
        call lock_fat
        jnc next_cluster_locked
        popf
        stc
        jmp next_cluster12_done

next_cluster_locked:
        or si,cx
        popf
        jc next_cluster_high
        mov cl,es:[esi]
        inc si
        test si,1FFh
        jnz next_cluster_low_ok
        UnlockSector
        inc edx
        call lock_fat
        jc next_cluster12_done

next_cluster_low_ok:
        mov ch,es:[esi]
        and cx,0FFFh
        jmp next_cluster_ok

next_cluster_high:
        mov ch,es:[esi]
        and ch,0F0h
        inc si
        test si,1FFh
        jnz next_cluster_high_ok
        UnlockSector
        inc edx
        call lock_fat
        jc next_cluster12_done

next_cluster_high_ok:
        mov cl,es:[esi]
        rol cx,4
next_cluster_ok:
        UnlockSector
        movzx edx,cx
        cmp edx,0FF8h
        cmc

next_cluster12_done:
        pushf
        LeaveSection ds:cluster_section
        popf
;
        pop esi
        pop cx
        pop ebx
        pop ds
        ret
next_cluster12  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   NEXT_CLUSTER16
;
;               DESCRIPTION:    Find next cluster for FAT16
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Cluster #
;
;               RETURNS:                EDX                     Next cluster #
;                                               NC                      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

next_cluster16  PROC near
        push ds
        push ebx
        push cx
        push esi
;
        EnterSection ds:cluster_section
        add edx,edx
        mov cx,dx
        shr edx,9
        add edx,ds:fat1_sector
        and cx,1FFh
        call lock_fat
        jc next_cluster16_done

        or si,cx
        movzx edx,word ptr es:[esi]
        UnlockSector
        cmp edx,0FFF8h
        cmc

next_cluster16_done:
        pushf
        LeaveSection ds:cluster_section
        popf
;
        pop esi
        pop cx
        pop ebx
        pop ds
        ret
next_cluster16  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   NEXT_CLUSTER32
;
;               DESCRIPTION:    Find next cluster for FAT32
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Cluster #
;
;               RETURNS:                EDX                     Next cluster #
;                                               NC                      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

next_cluster32  PROC near
        push ds
        push ebx
        push cx
        push esi
;
        EnterSection ds:cluster_section
        shl edx,2
        mov cx,dx
        shr edx,9
        add edx,ds:fat1_sector
        and cx,1FFh
        call lock_fat
        jc next_cluster32_done

        or si,cx
        mov edx,es:[esi]
        and edx,0FFFFFFFh
        UnlockSector
        cmp edx,0FFFFFF8h
        cmc

next_cluster32_done:
        pushf
        LeaveSection ds:cluster_section
        popf
;
        pop esi
        pop cx
        pop ebx
        pop ds
        ret
next_cluster32  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   NEXT_CLUSTER
;
;               DESCRIPTION:    Find next cluster
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Cluster #
;
;               RETURNS:                EDX                     Next cluster #
;                                               NC                      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public next_cluster

next_cluster    Proc near
        cmp ds:fat_type,fat12
        je nextc12
;
        cmp ds:fat_type,fat16
        je nextc16

nextc32:
        call next_cluster32
        jmp next_cluster_done

nextc16:
        call next_cluster16
        jmp next_cluster_done

nextc12:
        call next_cluster12

next_cluster_done:
        ret
next_cluster    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   NEXT_SECTOR12
;
;               DESCRIPTION:    Find next sector for FAT12
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Sector #
;
;               RETURNS:                EDX                     Next sector #
;                                               NC                      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

next_sector12   PROC near
        push ecx
        push esi
        inc edx
        mov cl,ds:fat_cluster_shift
        mov si,1
        shl si,cl
        dec si
        sub edx,ds:start_sector
        test si,dx
        clc
        jnz next_sector12_ok
        dec edx
        mov cl,ds:fat_cluster_shift
        shr edx,cl
        add edx,2
        call next_cluster12
        jc next_sector12_done
        sub edx,2
        mov cl,ds:fat_cluster_shift
        shl edx,cl
next_sector12_ok:
        add edx,ds:start_sector
        clc
next_sector12_done:
        pop esi
        pop ecx
        ret
next_sector12   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   NEXT_SECTOR16
;
;               DESCRIPTION:    Find next sector for FAT16
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Sector #
;
;               RETURNS:                EDX                     Next sector #
;                                               NC                      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

next_sector16   PROC near
        push ecx
        push esi
        inc edx
        mov cl,ds:fat_cluster_shift
        mov si,1
        shl si,cl
        dec si
        sub edx,ds:start_sector
        test si,dx
        clc
        jnz next_sector16_ok
        dec edx         
        mov cl,ds:fat_cluster_shift
        shr edx,cl
        add edx,2
        call next_cluster16
        jc next_sector16_done
        sub edx,2
        mov cl,ds:fat_cluster_shift
        shl edx,cl
next_sector16_ok:
        add edx,ds:start_sector
        clc
next_sector16_done:
        pop esi
        pop ecx
        ret
next_sector16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   NEXT_SECTOR32
;
;               DESCRIPTION:    Find next sector for FAT32
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Sector #
;
;               RETURNS:                EDX                     Next sector #
;                                               NC                      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

next_sector32   PROC near
        push ecx
        push esi
        inc edx
        mov cl,ds:fat_cluster_shift
        mov si,1
        shl si,cl
        dec si
        sub edx,ds:start_sector
        test si,dx
        clc
        jnz next_sector32_ok
        dec edx         
        mov cl,ds:fat_cluster_shift
        shr edx,cl
        add edx,2
        call next_cluster32
        jc next_sector32_done
        sub edx,2
        mov cl,ds:fat_cluster_shift
        shl edx,cl
next_sector32_ok:
        add edx,ds:start_sector
        clc
next_sector32_done:
        pop esi
        pop ecx
        ret
next_sector32   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   NEXT_SECTOR
;
;               DESCRIPTION:    Find next sector
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Sector #
;
;               RETURNS:                EDX                     Next sector #
;                                               NC                      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public next_sector

next_sector     Proc near
        cmp ds:fat_type,fat12
        je next12
;
        cmp ds:fat_type,fat16
        je next16

next32:
        call next_sector32
        jmp next_sector_done

next16:
        call next_sector16
        jmp next_sector_done

next12:
        call next_sector12

next_sector_done:
        ret
next_sector     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ALLOCATE_CLUSTER12
;
;               DESCRIPTION:    Allocate a cluster for FAT12
;
;               PARAMETERS:             AL                      Drive
;
;               RETURNS                 EDX                     Cluster #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_cluster12      PROC near
        push ebx
        push ecx
        push esi
        push edi
;
        EnterSection ds:cluster_section
    dec ds:free_clusters
        mov edx,ds:fat1_sector
        xor edi,edi
;
        call lock_fat
        jc allocate_cluster_failed0
        mov edi,2
        add si,3
        jmp allocate_cluster_low

allocate_cluster_lock0:

        call lock_fat
        jnc allocate_cluster_low

allocate_cluster_failed0:
        inc edx
        add edi,342
        cmp edi,ds:clusters
        cmc
        jc allocate_cluster12_fail

allocate_cluster_lock1:
        call lock_fat
        jnc allocate_cluster_low_locked1
;
        inc edx
        add edi,341
        cmp edi,ds:clusters
        cmc
        jc allocate_cluster12_fail

allocate_cluster_lock0_5:
        call lock_fat
        jnc allocate_cluster_high
;
        inc edx
        add edi,341
        cmp edi,ds:clusters
        cmc
        jc allocate_cluster12_fail
        jmp allocate_cluster_lock0

allocate_cluster_low_locked1:
        inc si

allocate_cluster_low:
        mov cl,es:[esi]
        inc si
        test si,1FFh
        jnz allocate_cluster_low_ok
        UnlockSector
        inc edx
        call lock_fat
        jnc allocate_cluster_low_ok
;
        inc edx
        add edi,342
        cmp edi,ds:clusters
        cmc
        jc allocate_cluster12_fail
        jmp allocate_cluster_lock0

allocate_cluster_low_ok:
        mov ch,es:[esi]
        and ch,0Fh
        stc
        jmp allocate_cluster12_test

allocate_cluster_high:
        mov ch,es:[esi]
        and ch,0F0h
        inc si
        test si,1FFh
        jnz allocate_cluster_high_ok
        UnlockSector
        inc edx
        call lock_fat
        jnc allocate_cluster_high_ok
;
        inc edx
        add edi,342
        cmp edi,ds:clusters
        cmc
        jc allocate_cluster12_fail
        jmp allocate_cluster_lock0_5

allocate_cluster_high_ok:
        mov cl,es:[esi]
        rol cx,4
        inc si
        clc

allocate_cluster12_test:
        pushf
        or cx,cx
        jz allocate_cluster12_mark
        add edi,1
        cmp edi,ds:clusters
        jc allocate_cluster12_next
        popf
        stc 
        jmp allocate_cluster12_done

allocate_cluster12_next:
        popf
        jc allocate_cluster_high
        test si,1FFh
        jnz allocate_cluster_low
        UnlockSector
        inc edx
        jmp allocate_cluster_lock0

allocate_cluster12_mark:
        popf
        mov edx,edi
        mov ecx,0FFFh
        call update_cluster_link12

allocate_cluster12_done:
        pushf
        UnlockSector
        popf

allocate_cluster12_fail:
        pushf
        LeaveSection ds:cluster_section
        popf
;
        pop edi
        pop esi
        pop ecx
        pop ebx
        ret
allocate_cluster12      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ALLOCATE_CLUSTER16
;
;               DESCRIPTION:    Allocate a cluster for FAT16
;
;               PARAMETERS:             AL                      Drive
;
;               RETURNS                 EDX                     Cluster #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_cluster16      PROC near
        push ebx
        push ecx
        push esi
        push edi
;
        EnterSection ds:cluster_section
    dec ds:free_clusters
        mov edx,ds:fat1_sector
        xor edi,edi
;
        call lock_fat
        jc allocate_cluster16_failed
        mov edi,2
        add si,4
        jmp allocate_cluster16_loop

allocate_cluster16_lock:
        call lock_fat
        jnc allocate_cluster16_loop

allocate_cluster16_failed:
        inc edx
        add edi,256
        cmp edi,ds:clusters
        cmc
        jc allocate_cluster16_fail
        
allocate_cluster16_loop:
        mov cx,es:[esi]
        add si,2
        or cx,cx
        jz allocate_cluster16_mark
        inc edi
        cmp edi,ds:clusters
        jc allocate_cluster16_next
        stc 
        jmp allocate_cluster16_done

allocate_cluster16_next:
        test si,1FFh
        jnz allocate_cluster16_loop
        UnlockSector
        inc edx
        jmp allocate_cluster16_lock

allocate_cluster16_mark:
        mov edx,edi
        mov ecx,0FFFFh
        call update_cluster_link16
allocate_cluster16_done:
        pushf
        UnlockSector
        popf

allocate_cluster16_fail:
        pushf
        LeaveSection ds:cluster_section
        popf
;
        pop edi
        pop esi
        pop ecx
        pop ebx
        ret
allocate_cluster16      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ALLOCATE_CLUSTER32
;
;               DESCRIPTION:    Allocate a cluster for FAT32
;
;               PARAMETERS:             AL                      Drive
;
;               RETURNS                 EDX                     Cluster #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_cluster32      PROC near
        push ebx
        push ecx
        push esi
        push edi
;
        EnterSection ds:cluster_section
    dec ds:free_clusters
    mov edx,ds:info_sector
    or edx,edx
    jz allocate_cluster32_do
;
    mov al,ds:drive_nr
    LockSector
    mov edx,ds:free_clusters
    mov es:[esi].fi_free_clusters,edx
    ModifySector
    UnlockSector

allocate_cluster32_do:
        mov edx,ds:fat1_sector
        xor edi,edi
;
        call lock_fat
        jc allocate_cluster32_failed
        mov edi,2
        add si,8
        jmp allocate_cluster32_loop

allocate_cluster32_lock:
        call lock_fat
        jnc allocate_cluster32_loop

allocate_cluster32_failed:
        inc edx
        add edi,128
        cmp edi,ds:clusters
        cmc
        jc allocate_cluster32_fail
        
allocate_cluster32_loop:
        mov ecx,es:[esi]
        add si,4
        or ecx,ecx
        jz allocate_cluster32_mark
        inc edi
        cmp edi,ds:clusters
        jc allocate_cluster32_next
        stc 
        jmp allocate_cluster32_done

allocate_cluster32_next:
        test si,1FFh
        jnz allocate_cluster32_loop
        UnlockSector
        inc edx
        jmp allocate_cluster32_lock

allocate_cluster32_mark:
        mov edx,edi
        mov ecx,0FFFFFFFh
        call update_cluster_link32
allocate_cluster32_done:
        pushf
        UnlockSector
        popf

allocate_cluster32_fail:
        pushf
        LeaveSection ds:cluster_section
        popf
;
        pop edi
        pop esi
        pop ecx
        pop ebx
        ret
allocate_cluster32      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ALLOCATE_CLUSTER_NO_VERIFY
;
;               DESCRIPTION:    Allocate a cluster without verification
;
;               PARAMETERS:             AL                      Drive
;
;               RETURNS                 EDX                     Cluster #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public allocate_cluster_no_verify

allocate_cluster_no_verify      Proc near
        cmp ds:fat_type,fat12
        je alloc12
;
        cmp ds:fat_type,fat16
        je alloc16

alloc32:
        call allocate_cluster32
        jmp allocate_cluster_done

alloc16:
        call allocate_cluster16
        jmp allocate_cluster_done

alloc12:
        call allocate_cluster12

allocate_cluster_done:
        ret
allocate_cluster_no_verify      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   FREE_CLUSTER
;
;               DESCRIPTION:    Free a cluster
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Cluster #
;
;               RETURNS:                NC                      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public free_cluster

free_cluster    Proc near
        push ecx
        EnterSection ds:cluster_section
        cmp ds:fat_type,fat12
        je free12
;
        cmp ds:fat_type,fat16
        je free16

free32:
        xor ecx,ecx
        call update_cluster_link32
;       
    pushf
    push ebx
    push edx
    push esi
    inc ds:free_clusters
    mov edx,ds:info_sector
    or edx,edx
    jz free_cluster32_done
;
    LockSector
    mov edx,ds:free_clusters
    mov es:[esi].fi_free_clusters,edx
    ModifySector
    UnlockSector

free_cluster32_done:
    pop esi
    pop edx
    pop ebx
    popf
        jmp free_cluster_done

free16:
        xor ecx,ecx
        call update_cluster_link16
    inc ds:free_clusters
        jmp free_cluster_done

free12:
        xor ecx,ecx
        call update_cluster_link12
    inc ds:free_clusters

free_cluster_done:
        LeaveSection ds:cluster_section
        pop ecx
        ret
free_cluster    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   LINK_CLUSTER
;
;               DESCRIPTION:    Link a cluster
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Cluster #
;                                               ECX                     Linked cluster #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public link_cluster

link_cluster    Proc near
        EnterSection ds:cluster_section
        cmp ds:fat_type,fat12
        je link12
;
        cmp ds:fat_type,fat16
        je link16

link32:
        call update_cluster_link32
        jmp link_cluster_done

link16:
        call update_cluster_link16
        jmp link_cluster_done

link12:
        call update_cluster_link12

link_cluster_done:
        LeaveSection ds:cluster_section
        ret
link_cluster    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EOF_CLUSTER
;
;               DESCRIPTION:    Mark cluster as last
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Cluster #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public eof_cluster

eof_cluster     Proc near
        EnterSection ds:cluster_section
        cmp ds:fat_type,fat12
        je eof12
;
        cmp ds:fat_type,fat16
        je eof16

eof32:
        mov ecx,0FFFFFFFFh
        call update_cluster_link32
        jmp eof_cluster_done

eof16:
        mov ecx,0FFFFh
        call update_cluster_link16
        jmp eof_cluster_done

eof12:
        mov ecx,0FFFh
        call update_cluster_link12

eof_cluster_done:
        LeaveSection ds:cluster_section
        ret
eof_cluster     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   BAD_CLUSTER
;
;               DESCRIPTION:    Mark cluster as bad
;
;               PARAMETERS:             AL                      Drive
;                                               EDX                     Cluster #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public bad_cluster

bad_cluster     Proc near
        EnterSection ds:cluster_section
        cmp ds:fat_type,fat12
        je bad12
;
        cmp ds:fat_type,fat16
        je bad16

bad32:
        mov ecx,0FFFFFFF8h
        call update_cluster_link32
        jmp bad_cluster_done

bad16:
        mov ecx,0FFF8h
        call update_cluster_link16
        jmp bad_cluster_done

bad12:
        mov ecx,0FF8h
        call update_cluster_link12

bad_cluster_done:
        LeaveSection ds:cluster_section
        ret
bad_cluster     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GET_FREE_CLUSTER12
;
;               DESCRIPTION:    Get free clusters for FAT12
;
;               PARAMETERS:             AL                      Drive
;
;               RETURNS                 EDX                     Free clusters
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_free_cluster12      PROC near
        push ebx
        push ecx
        push esi
        push edi
        push ebp
;
    xor ebp,ebp
        EnterSection ds:cluster_section
        mov edx,ds:fat1_sector
        xor edi,edi
;
        call lock_fat
        jc get_free_cluster_failed0
        mov edi,2
        add si,3
        jmp get_free_cluster_low

get_free_cluster_lock0:

        call lock_fat
        jnc get_free_cluster_low

get_free_cluster_failed0:
        inc edx
        add edi,342
        cmp edi,ds:clusters
        cmc
        jc get_free_cluster12_done

get_free_cluster_lock1:
        call lock_fat
        jnc get_free_cluster_low_locked1
;
        inc edx
        add edi,341
        cmp edi,ds:clusters
        cmc
        jc get_free_cluster12_done

get_free_cluster_lock0_5:
        call lock_fat
        jnc get_free_cluster_high
;
        inc edx
        add edi,341
        cmp edi,ds:clusters
        cmc
        jc get_free_cluster12_done
        jmp get_free_cluster_lock0

get_free_cluster_low_locked1:
        inc si

get_free_cluster_low:
        mov cl,es:[esi]
        inc si
        test si,1FFh
        jnz get_free_cluster_low_ok
        UnlockSector
        inc edx
        call lock_fat
        jnc get_free_cluster_low_ok
;
        inc edx
        add edi,342
        cmp edi,ds:clusters
        cmc
        jc get_free_cluster12_done
        jmp get_free_cluster_lock0

get_free_cluster_low_ok:
        mov ch,es:[esi]
        and ch,0Fh
        stc
        jmp get_free_cluster12_test

get_free_cluster_high:
        mov ch,es:[esi]
        and ch,0F0h
        inc si
        test si,1FFh
        jnz get_free_cluster_high_ok
;       
        UnlockSector
        inc edx
        call lock_fat
        jnc get_free_cluster_high_ok
;
        inc edx
        add edi,342
        cmp edi,ds:clusters
        cmc
        jc get_free_cluster12_done
        jmp get_free_cluster_lock0_5

get_free_cluster_high_ok:
        mov cl,es:[esi]
        rol cx,4
        inc si
        clc

get_free_cluster12_test:
        pushf
        or cx,cx
        jnz get_free_cluster12_used
;
    inc ebp

get_free_cluster12_used:        
        add edi,1
        cmp edi,ds:clusters
        jc get_free_cluster12_next
;       
        popf
        jmp get_free_cluster12_leave

get_free_cluster12_next:
        popf
        jc get_free_cluster_high
        test si,1FFh
        jnz get_free_cluster_low
        UnlockSector
        inc edx
        jmp get_free_cluster_lock0

get_free_cluster12_done:
        UnlockSector

get_free_cluster12_leave:
        LeaveSection ds:cluster_section
;
    mov edx,ebp
    pop ebp
        pop edi
        pop esi
        pop ecx
        pop ebx
        ret
get_free_cluster12      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GET_FREE_CLUSTER16
;
;               DESCRIPTION:    Get free clusters for FAT16
;
;               PARAMETERS:             AL                      Drive
;
;               RETURNS                 EDX                     Free clusters
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_free_cluster16      PROC near
        push ebx
        push ecx
        push esi
        push edi
        push ebp
;
        xor ebp,ebp
        EnterSection ds:cluster_section
        mov edx,ds:fat1_sector
        xor edi,edi
;
        call lock_fat
        jc get_free_cluster16_leave
;       
        mov edi,2
        add si,4
        jmp get_free_cluster16_loop

get_free_cluster16_lock:
        call lock_fat
        jnc get_free_cluster16_loop

get_free_cluster16_failed:
        inc edx
        add edi,256
        cmp edi,ds:clusters
        cmc
        jc get_free_cluster16_leave
        
get_free_cluster16_loop:
        mov cx,es:[esi]
        add si,2
        or cx,cx
        jnz get_free_cluster16_used
;
    inc ebp

get_free_cluster16_used:
        inc edi
        cmp edi,ds:clusters
        jnc get_free_cluster16_done

get_free_cluster16_next:
        test si,1FFh
        jnz get_free_cluster16_loop
        UnlockSector
        inc edx
        jmp get_free_cluster16_lock
        
get_free_cluster16_done:
        pushf
        UnlockSector
        popf

get_free_cluster16_leave:
        LeaveSection ds:cluster_section
;
    mov edx,ebp
    pop ebp
        pop edi
        pop esi
        pop ecx
        pop ebx
        ret
get_free_cluster16      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GET_FREE_CLUSTER32
;
;               DESCRIPTION:    Get free clusters for FAT32
;
;               PARAMETERS:             AL                      Drive
;
;               RETURNS                 EDX                     Free clusters
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_free_cluster32      PROC near
        push ebx
        push ecx
        push esi
        push edi
        push ebp
;
    xor ebp,ebp
        EnterSection ds:cluster_section
        mov edx,ds:fat1_sector
        xor edi,edi
;
        call lock_fat
        jc get_free_cluster32_leave
;       
        mov edi,2
        add si,8
        jmp get_free_cluster32_loop

get_free_cluster32_lock:
        call lock_fat
        jnc get_free_cluster32_loop

get_free_cluster32_failed:
        inc edx
        add edi,128
        cmp edi,ds:clusters
        cmc
        jc get_free_cluster32_leave
        
get_free_cluster32_loop:
        mov ecx,es:[esi]
        add si,4
        or ecx,ecx
        jnz get_free_cluster32_used
;
    inc ebp

get_free_cluster32_used:        
        inc edi
        cmp edi,ds:clusters
        jnc get_free_cluster32_done

get_free_cluster32_next:
        test si,1FFh
        jnz get_free_cluster32_loop
        UnlockSector
        inc edx
        jmp get_free_cluster32_lock

get_free_cluster32_done:
    UnlockSector
    
get_free_cluster32_leave:
        LeaveSection ds:cluster_section
;
    mov edx,ebp
    pop ebp
        pop edi
        pop esi
        pop ecx
        pop ebx
        ret
get_free_cluster32      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GET_FREE_CLUSTERS
;
;               DESCRIPTION:    Get number of free clusters
;
;               PARAMETERS:             AL                      Drive
;
;       RETURNS:        EDX                     Free clusters
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public get_free_clusters

get_free_clusters   Proc near
        cmp ds:fat_type,fat12
        je gfc12
;
        cmp ds:fat_type,fat16
        je gfc16

gfc32:
        call get_free_cluster32
        jmp gfc_cluster_done

gfc16:
        call get_free_cluster16
        jmp gfc_cluster_done

gfc12:
        call get_free_cluster12

gfc_cluster_done:
    ret
get_free_clusters   Endp

code    ENDS

        END

