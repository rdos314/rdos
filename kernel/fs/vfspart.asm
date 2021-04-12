;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
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
; VFS.ASM
; Virtual file system
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os\system.def
include ..\os.def
include ..\os.inc
include ..\serv.def
include ..\serv.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\handle.inc
include ..\wait.inc
include ..\os\protseg.def
include vfs.inc

    .386p

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

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern LocalLockSector:near
    extern LocalUnlockSector:near
    extern AddPartition:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ChsToLba
;
;       DESCRIPTION:    Convert CHS to LBA
;
;       PARAMETERS:     DS       VFS sel
;                       ES:SI    CHS address
;
;       RETURNS:        EDX      LBA address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChsToLba    Proc near
    push eax
    push ebx
    push ecx
;
    call fword ptr ds:vfs_get_bios
    jc ctlDone
;
    mov cl,es:[si+3]
    movzx ax,byte ptr es:[si+2]
    and al,0C0h
    shl ax,2
    mov ch,ah
    cmp cx,1023
    stc
    je ctlDone
;
    movzx eax,ax
    movzx ecx,cx
    mul ecx
    movzx ecx,byte ptr es:[si].part_start_head
    add ecx,eax
    movzx eax,bx
    mul ecx
    movzx ecx,byte ptr es:[si+2]
    and cl,3Fh
    add eax,ecx
    dec eax
    mov edx,eax
    clc

ctlDone:
    pop ecx
    pop ebx
    pop eax
    ret
ChsToLba    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InstallMbrPartition
;
;       DESCRIPTION:    Install MBR partition
;
;       PARAMETERS:     DS      VFS sel
;                       ES      Parent partition
;                       CL      Partition type
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
fs00    DD OFFSET fs_unknown
fs01    DD OFFSET fs_fat12
fs02    DD OFFSET fs_unknown
fs03    DD OFFSET fs_unknown
fs04    DD OFFSET fs_fat16
fs05    DD OFFSET fs_unknown
fs06    DD OFFSET fs_fat16
fs07    DD OFFSET fs_hpfs
fs08    DD OFFSET fs_unknown
fs09    DD OFFSET fs_unknown
fs0A    DD OFFSET fs_unknown
fs0B    DD OFFSET fs_fat32
fs0C    DD OFFSET fs_fat32
fs0D    DD OFFSET fs_unknown
fs0E    DD OFFSET fs_unknown
fs0F    DD OFFSET fs_unknown
fs10    DD OFFSET fs_unknown
fs11    DD OFFSET fs_unknown
fs12    DD OFFSET fs_unknown
fs13    DD OFFSET fs_unknown
fs14    DD OFFSET fs_unknown
fs15    DD OFFSET fs_unknown
fs16    DD OFFSET fs_unknown
fs17    DD OFFSET fs_unknown
fs18    DD OFFSET fs_unknown
fs19    DD OFFSET fs_unknown
fs1A    DD OFFSET fs_unknown
fs1B    DD OFFSET fs_unknown
fs1C    DD OFFSET fs_unknown
fs1D    DD OFFSET fs_unknown
fs1E    DD OFFSET fs_unknown
fs1F    DD OFFSET fs_unknown
fs20    DD OFFSET fs_unknown
fs21    DD OFFSET fs_unknown
fs22    DD OFFSET fs_unknown
fs23    DD OFFSET fs_unknown
fs24    DD OFFSET fs_unknown
fs25    DD OFFSET fs_unknown
fs26    DD OFFSET fs_unknown
fs27    DD OFFSET fs_unknown
fs28    DD OFFSET fs_unknown
fs29    DD OFFSET fs_unknown
fs2A    DD OFFSET fs_unknown
fs2B    DD OFFSET fs_unknown
fs2C    DD OFFSET fs_unknown
fs2D    DD OFFSET fs_unknown
fs2E    DD OFFSET fs_unknown
fs2F    DD OFFSET fs_unknown
fs30    DD OFFSET fs_unknown
fs31    DD OFFSET fs_unknown
fs32    DD OFFSET fs_unknown
fs33    DD OFFSET fs_unknown
fs34    DD OFFSET fs_unknown
fs35    DD OFFSET fs_unknown
fs36    DD OFFSET fs_unknown
fs37    DD OFFSET fs_unknown
fs38    DD OFFSET fs_unknown
fs39    DD OFFSET fs_unknown
fs3A    DD OFFSET fs_unknown
fs3B    DD OFFSET fs_unknown
fs3C    DD OFFSET fs_unknown
fs3D    DD OFFSET fs_unknown
fs3E    DD OFFSET fs_unknown
fs3F    DD OFFSET fs_unknown
fs40    DD OFFSET fs_unknown
fs41    DD OFFSET fs_unknown
fs42    DD OFFSET fs_unknown
fs43    DD OFFSET fs_unknown
fs44    DD OFFSET fs_unknown
fs45    DD OFFSET fs_unknown
fs46    DD OFFSET fs_unknown
fs47    DD OFFSET fs_unknown
fs48    DD OFFSET fs_unknown
fs49    DD OFFSET fs_unknown
fs4A    DD OFFSET fs_unknown
fs4B    DD OFFSET fs_unknown
fs4C    DD OFFSET fs_unknown
fs4D    DD OFFSET fs_unknown
fs4E    DD OFFSET fs_unknown
fs4F    DD OFFSET fs_unknown
fs50    DD OFFSET fs_unknown
fs51    DD OFFSET fs_unknown
fs52    DD OFFSET fs_unknown
fs53    DD OFFSET fs_unknown
fs54    DD OFFSET fs_unknown
fs55    DD OFFSET fs_unknown
fs56    DD OFFSET fs_unknown
fs57    DD OFFSET fs_unknown
fs58    DD OFFSET fs_unknown
fs59    DD OFFSET fs_unknown
fs5A    DD OFFSET fs_unknown
fs5B    DD OFFSET fs_unknown
fs5C    DD OFFSET fs_unknown
fs5D    DD OFFSET fs_unknown
fs5E    DD OFFSET fs_unknown
fs5F    DD OFFSET fs_unknown
fs60    DD OFFSET fs_unknown
fs61    DD OFFSET fs_unknown
fs62    DD OFFSET fs_unknown
fs63    DD OFFSET fs_unknown
fs64    DD OFFSET fs_unknown
fs65    DD OFFSET fs_unknown
fs66    DD OFFSET fs_unknown
fs67    DD OFFSET fs_unknown
fs68    DD OFFSET fs_unknown
fs69    DD OFFSET fs_unknown
fs6A    DD OFFSET fs_unknown
fs6B    DD OFFSET fs_unknown
fs6C    DD OFFSET fs_unknown
fs6D    DD OFFSET fs_unknown
fs6E    DD OFFSET fs_unknown
fs6F    DD OFFSET fs_unknown
fs70    DD OFFSET fs_unknown
fs71    DD OFFSET fs_unknown
fs72    DD OFFSET fs_unknown
fs73    DD OFFSET fs_unknown
fs74    DD OFFSET fs_unknown
fs75    DD OFFSET fs_unknown
fs76    DD OFFSET fs_unknown
fs77    DD OFFSET fs_unknown
fs78    DD OFFSET fs_unknown
fs79    DD OFFSET fs_unknown
fs7A    DD OFFSET fs_unknown
fs7B    DD OFFSET fs_unknown
fs7C    DD OFFSET fs_unknown
fs7D    DD OFFSET fs_unknown
fs7E    DD OFFSET fs_unknown
fs7F    DD OFFSET fs_unknown
fs80    DD OFFSET fs_unknown
fs81    DD OFFSET fs_unknown
fs82    DD OFFSET fs_unknown
fs83    DD OFFSET fs_unknown
fs84    DD OFFSET fs_unknown
fs85    DD OFFSET fs_unknown
fs86    DD OFFSET fs_unknown
fs87    DD OFFSET fs_unknown
fs88    DD OFFSET fs_unknown
fs89    DD OFFSET fs_unknown
fs8A    DD OFFSET fs_unknown
fs8B    DD OFFSET fs_unknown
fs8C    DD OFFSET fs_unknown
fs8D    DD OFFSET fs_unknown
fs8E    DD OFFSET fs_unknown
fs8F    DD OFFSET fs_unknown
fs90    DD OFFSET fs_unknown
fs91    DD OFFSET fs_unknown
fs92    DD OFFSET fs_unknown
fs93    DD OFFSET fs_unknown
fs94    DD OFFSET fs_unknown
fs95    DD OFFSET fs_unknown
fs96    DD OFFSET fs_unknown
fs97    DD OFFSET fs_unknown
fs98    DD OFFSET fs_unknown
fs99    DD OFFSET fs_unknown
fs9A    DD OFFSET fs_unknown
fs9B    DD OFFSET fs_unknown
fs9C    DD OFFSET fs_unknown
fs9D    DD OFFSET fs_unknown
fs9E    DD OFFSET fs_unknown
fs9F    DD OFFSET fs_unknown
fsA0    DD OFFSET fs_unknown
fsA1    DD OFFSET fs_unknown
fsA2    DD OFFSET fs_unknown
fsA3    DD OFFSET fs_unknown
fsA4    DD OFFSET fs_unknown
fsA5    DD OFFSET fs_unknown
fsA6    DD OFFSET fs_unknown
fsA7    DD OFFSET fs_unknown
fsA8    DD OFFSET fs_unknown
fsA9    DD OFFSET fs_unknown
fsAA    DD OFFSET fs_unknown
fsAB    DD OFFSET fs_unknown
fsAC    DD OFFSET fs_unknown
fsAD    DD OFFSET fs_unknown
fsAE    DD OFFSET fs_rdfs
fsAF    DD OFFSET fs_flashfs
fsB0    DD OFFSET fs_unknown
fsB1    DD OFFSET fs_unknown
fsB2    DD OFFSET fs_unknown
fsB3    DD OFFSET fs_unknown
fsB4    DD OFFSET fs_unknown
fsB5    DD OFFSET fs_unknown
fsB6    DD OFFSET fs_unknown
fsB7    DD OFFSET fs_unknown
fsB8    DD OFFSET fs_unknown
fsB9    DD OFFSET fs_unknown
fsBA    DD OFFSET fs_unknown
fsBB    DD OFFSET fs_unknown
fsBC    DD OFFSET fs_unknown
fsBD    DD OFFSET fs_unknown
fsBE    DD OFFSET fs_unknown
fsBF    DD OFFSET fs_unknown
fsC0    DD OFFSET fs_unknown
fsC1    DD OFFSET fs_unknown
fsC2    DD OFFSET fs_unknown
fsC3    DD OFFSET fs_unknown
fsC4    DD OFFSET fs_unknown
fsC5    DD OFFSET fs_unknown
fsC6    DD OFFSET fs_unknown
fsC7    DD OFFSET fs_unknown
fsC8    DD OFFSET fs_unknown
fsC9    DD OFFSET fs_unknown
fsCA    DD OFFSET fs_unknown
fsCB    DD OFFSET fs_unknown
fsCC    DD OFFSET fs_unknown
fsCD    DD OFFSET fs_unknown
fsCE    DD OFFSET fs_unknown
fsCF    DD OFFSET fs_unknown
fsD0    DD OFFSET fs_unknown
fsD1    DD OFFSET fs_unknown
fsD2    DD OFFSET fs_unknown
fsD3    DD OFFSET fs_unknown
fsD4    DD OFFSET fs_unknown
fsD5    DD OFFSET fs_unknown
fsD6    DD OFFSET fs_unknown
fsD7    DD OFFSET fs_unknown
fsD8    DD OFFSET fs_unknown
fsD9    DD OFFSET fs_unknown
fsDA    DD OFFSET fs_unknown
fsDB    DD OFFSET fs_unknown
fsDC    DD OFFSET fs_unknown
fsDD    DD OFFSET fs_unknown
fsDE    DD OFFSET fs_unknown
fsDF    DD OFFSET fs_unknown
fsE0    DD OFFSET fs_unknown
fsE1    DD OFFSET fs_unknown
fsE2    DD OFFSET fs_unknown
fsE3    DD OFFSET fs_unknown
fsE4    DD OFFSET fs_unknown
fsE5    DD OFFSET fs_unknown
fsE6    DD OFFSET fs_unknown
fsE7    DD OFFSET fs_unknown
fsE8    DD OFFSET fs_unknown
fsE9    DD OFFSET fs_unknown
fsEA    DD OFFSET fs_unknown
fsEB    DD OFFSET fs_unknown
fsEC    DD OFFSET fs_unknown
fsED    DD OFFSET fs_unknown
fsEE    DD OFFSET fs_unknown
fsEF    DD OFFSET fs_unknown
fsF0    DD OFFSET fs_unknown
fsF1    DD OFFSET fs_unknown
fsF2    DD OFFSET fs_unknown
fsF3    DD OFFSET fs_unknown
fsF4    DD OFFSET fs_unknown
fsF5    DD OFFSET fs_unknown
fsF6    DD OFFSET fs_unknown
fsF7    DD OFFSET fs_unknown
fsF8    DD OFFSET fs_unknown
fsF9    DD OFFSET fs_unknown
fsFA    DD OFFSET fs_unknown
fsFB    DD OFFSET fs_unknown
fsFC    DD OFFSET fs_unknown
fsFD    DD OFFSET fs_unknown
fsFE    DD OFFSET fs_unknown
fsFF    DD OFFSET fs_unknown

InstallMbrPartition    Proc near
    push es
    pushad
;
    cmp cl,7
    je impCheckPart
;
    cmp cl,0Ch
    jne impCheckType

impCheckPart:
    mov eax,ds:vfs_curr_start_sector
    mov edx,ds:vfs_curr_start_sector+4
    call LocalLockSector
;
    push edx
    mov edx,ds:vfs_map_entry
    MapServEntry
    mov edi,edx
    pop edx
;
    mov ax,serv_flat_sel
    mov es,ax
;
    mov al,es:[edi+26h]
    cmp al,29h
    je impUsePartFat
;
    mov ax,cs
    mov es,ax
    movzx edi,cl
    shl edi,2
    mov edi,cs:[edi].FsTab
    jmp impUsePartAdd

impUsePartFat:
    lea edi,[edi+36h]

impUsePartAdd:
    call AddPartition
;
    mov eax,ds:vfs_curr_start_sector
    mov edx,ds:vfs_curr_start_sector+4
    call LocalUnlockSector    
    jmp impDone

impCheckType:
    mov di,cs
    mov es,di
    movzx edi,cl
    shl edi,2
    mov edi,cs:[edi].FsTab
    call AddPartition

impDone:
    popad
    pop es
    ret
InstallMbrPartition    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InstallMbrExtended
;
;       DESCRIPTION:    Install extended partion on drive
;
;       PARAMETERS:     DS      VFS sel
;                       ES      Parent partition
;                       CL      Partition type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallMbrExtended Proc near
    push es
    pushad
;
    mov eax,ds:vfs_curr_start_sector
    mov edx,ds:vfs_curr_start_sector+4
    mov ebp,eax
    call LocalLockSector
;
    push edx
    mov edx,ds:vfs_map_entry
    MapServEntry
    mov esi,edx
    pop edx
;
    mov ax,serv_flat_sel
    mov fs,ax
    add esi,1BEh
;
    mov eax,40h
    AllocateSmallServ
    xor edi,edi
    mov ecx,10h
    rep movs dword ptr es:[edi],fs:[esi]
;
    mov eax,ds:vfs_curr_start_sector
    mov edx,ds:vfs_curr_start_sector+4
    call LocalUnlockSector
;
    xor si,si

imeLoop:
    mov cl,es:[si].part_type
    or cl,cl
    jz imeNextPart
;
    mov eax,es:[si].part_sectors
    call ChsToLba
    jnc imeInst
;
    mov edx,es:[si].part_start_sector
    add edx,ebp

imeInst:
    mov ds:vfs_curr_start_sector,edx
    mov ds:vfs_curr_start_sector+4,0
    mov ds:vfs_curr_sector_count,eax
    mov ds:vfs_curr_sector_count+4,0
;
    cmp cl,5
    je imeLink
;
    cmp cl,0Fh
    je imeLink
;
    call InstallMbrPartition
    jmp imeNextPart

imeLink:
    call InstallMbrExtended

imeNextPart:
    add si,10h
    cmp si,40h
    jne imeLoop
;
    FreeSmallServ
;
    popad
    pop es
    ret
InstallMbrExtended Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InstallEfiPart
;
;       DESCRIPTION:    Install EFI partition
;
;       PARAMETERS:     DS      VFS sel
;                       ES:EDI  GPT entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallEfiPart Proc near
    push es
    pushad
;
    mov eax,es:[edi].gpe_first_lba
    mov edx,es:[edi].gpe_first_lba+4
    mov ds:vfs_curr_start_sector,eax
    mov ds:vfs_curr_start_sector+4,edx
;
    mov ecx,es:[edi].gpe_last_lba
    sub ecx,eax
    mov ds:vfs_curr_sector_count,ecx
    mov ecx,es:[edi].gpe_last_lba+4
    sbb ecx,edx
    mov ds:vfs_curr_sector_count+4,ecx
    add ds:vfs_curr_sector_count,1
    adc ds:vfs_curr_sector_count+4,0
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET fs_fat32
    call AddPartition
;
    popad
    pop es
    ret
InstallEfiPart Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InstallBasicPart
;
;       DESCRIPTION:    Install basic partition
;
;       PARAMETERS:     DS      VFS sel
;                       ES:EDI  GPT entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallBasicPart Proc near
    pushad
;
    mov esi,edi
    mov eax,es:[esi].gpe_first_lba
    mov edx,es:[esi].gpe_first_lba+4
    mov ds:vfs_curr_start_sector,eax
    mov ds:vfs_curr_start_sector+4,edx
;
    mov ecx,es:[esi].gpe_last_lba
    sub ecx,eax
    mov ds:vfs_curr_sector_count,ecx
    mov ecx,es:[esi].gpe_last_lba+4
    sbb ecx,edx
    mov ds:vfs_curr_sector_count+4,ecx
    add ds:vfs_curr_sector_count,1
    adc ds:vfs_curr_sector_count+4,0
;
    call LocalLockSector
;
    mov edx,ds:vfs_map_entry
    MapServEntry
    mov edi,edx
;
    mov cl,es:[edi+3]
    cmp cl,'M'
    je ibpDos
;
    cmp cl,'m'
    je ibpLinux    
;
    cmp cl,'R'
    je ibpLinux    
;
    add edi,3
    jmp ibpAdd

ibpLinux:
    add edi,36h
    jmp ibpAdd

ibpDos:
    add edi,52h

ibpAdd:
    call AddPartition
;
    mov eax,ds:vfs_curr_start_sector
    mov edx,ds:vfs_curr_start_sector+4
    call LocalUnlockSector
;
    popad
    ret
InstallBasicPart Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InstallGptEntry
;
;       DESCRIPTION:    Install GPT entry
;
;       PARAMETERS:     DS      VFS sel
;                       ES:EDI  GPT entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallGptEntry Proc near
    mov eax,dword ptr es:[edi].gpe_part_guid
    cmp eax,0C12A7328h
    jne igeNotEfi
;
    mov eax,dword ptr es:[edi].gpe_part_guid+4
    cmp eax,11D2F81Fh
    jne igeNotEfi
;    
    mov eax,dword ptr es:[edi].gpe_part_guid+8
    cmp eax,0A0004BBAh
    jne igeNotEfi
;    
    mov eax,dword ptr es:[edi].gpe_part_guid+12
    cmp eax,3BC93EC9h
    jne igeNotEfi
;
    call InstallEfiPart
    jmp igeDone

igeNotEfi:    
    mov eax,dword ptr es:[edi].gpe_part_guid
    cmp eax,0EBD0A0A2h
    jne igeDone
;
    mov eax,dword ptr es:[edi].gpe_part_guid+4
    cmp eax,4433B9E5h
    jne igeDone
;    
    mov eax,dword ptr es:[edi].gpe_part_guid+8
    cmp eax,0B668C087h
    jne igeDone
;    
    mov eax,dword ptr es:[edi].gpe_part_guid+12
    cmp eax,0C79926B7h
    jne igeDone
;
    call InstallBasicPart

igeDone:    
    ret
InstallGptEntry Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InstallGpt
;
;       DESCRIPTION:    Install GPT partition
;
;       PARAMETERS:     DS      VFS sel
;                       ES      Parent partition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallGpt    Proc near
    push es
    pushad
;
    mov eax,1
    xor edx,edx
    call LocalLockSector
;
    mov edx,ds:vfs_map_entry
    MapServEntry
;
    mov ax,serv_flat_sel
    mov es,ax
    mov edi,edx
;
    mov eax,dword ptr es:[edi].gpt_sign
    cmp eax,20494645h
    jne igptDone
;
    mov eax,dword ptr es:[edi].gpt_sign+4
    cmp eax,54524150h
    jne igptDone
;
    xor edx,edx
    xchg edx,es:[edi].gpt_crc32
    mov ecx,es:[edi].gpt_header_size
    cmp ecx,200h
    jae igptDone
;
    mov eax,-1
    CalcCrc32
;
    cmp eax,edx
    jne igptDone
;    
    mov eax,es:[edi].gpt_entry_size
    cmp eax,128
    jne igptDone
;
    mov ecx,es:[edi].gpt_entry_count
    mov ds:vfs_gpt_entry_count,ecx
    add ecx,8
    mov eax,ecx
    shl eax,7
    dec eax
    and ax,0F000h
    add eax,1000h
    AllocateBigServ
    mov ds:vfs_gpt_base,edx
;
    push edi
;
    mov ecx,es:[edi].gpt_entry_count
    dec ecx
    shr ecx,2
    inc ecx
    mov eax,es:[edi].gpt_entry_lba
    mov edx,es:[edi].gpt_entry_lba+4
    mov ds:vfs_gpt_start_sector,eax
    mov ds:vfs_gpt_start_sector+4,edx
    mov ds:vfs_curr_start_sector,eax
    mov ds:vfs_curr_start_sector+4,edx
;
    call LocalLockSector
;
    mov edx,ds:vfs_gpt_base
    mov edi,edx
    MapServEntry
    mov ds:vfs_gpt_start,edx

igptLockLoop:
    inc ds:vfs_curr_start_sector
    sub ecx,1
    jz igptLockDone
;
    mov eax,ds:vfs_curr_start_sector
    mov edx,ds:vfs_curr_start_sector+4
    call LocalLockSector
    test eax,0FFFh
    jnz igptMap
;
    add edi,1000h

igptMap:
    mov edx,edi
    MapServEntry
    jmp igptLockLoop

igptLockDone:
    pop edi
;
    push edi
;    
    mov ecx,es:[edi].gpt_entry_count
    shl ecx,7
    mov edi,ds:vfs_gpt_start
    mov eax,-1
    CalcCrc32
;    
    pop edi
;
    cmp eax,es:[edi].gpt_entry_crc32
    jne igptUnlock
;
    push edi
    mov ecx,es:[edi].gpt_entry_count
    mov edi,ds:vfs_gpt_start
    or ecx,ecx
    jz igptEntryDone

igptEntryLoop:
    mov eax,es:[edi].gpe_first_lba
    or eax,es:[edi].gpe_first_lba+4
    jz igptEntryNext
;
    call InstallGptEntry

igptEntryNext:
    add edi,128 
    sub ecx,1
    jnz igptEntryLoop

igptEntryDone:     
    pop edi

igptUnlock:
    mov ecx,ds:vfs_gpt_entry_count
    add ecx,8
    shl ecx,7
    dec ecx
    and cx,0F000h
    add ecx,1000h
    mov edx,ds:vfs_gpt_base
    FreeBigServ
;
    mov eax,ds:vfs_gpt_start_sector
    mov edx,ds:vfs_gpt_start_sector+4
    mov ds:vfs_curr_start_sector,eax
    mov ds:vfs_curr_start_sector+4,edx
;
    mov ecx,ds:vfs_gpt_entry_count
    dec ecx
    shr ecx,2
    inc ecx

igptUnlockLoop:
    mov eax,ds:vfs_curr_start_sector
    mov edx,ds:vfs_curr_start_sector+4
    call LocalUnlockSector
;
    inc ds:vfs_curr_start_sector
    sub ecx,1
    jnz igptUnlockLoop

igptDone:
    mov eax,1
    xor edx,edx
    call LocalUnlockSector
;        
    popad
    pop es
    ret
InstallGpt    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           init_part
;
;       DESCRIPTION:    Init partition
;
;       PARAMETERS:     DS     VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_part

init_part   Proc near
    mov eax,1000h
    AllocateBigServ
    mov ds:vfs_map_entry,edx
;
    xor eax,eax
    xor edx,edx
    call LocalLockSector
;
    mov edx,ds:vfs_map_entry
    MapServEntry
;
    mov ax,serv_flat_sel
    mov fs,ax
    mov esi,edx
    add esi,1BEh
;
    mov eax,40h
    AllocateSmallServ
    xor edi,edi
    mov ecx,10h
    rep movs dword ptr es:[edi],fs:[esi]
;
    xor eax,eax
    xor edx,edx
    call LocalUnlockSector
;
    xor si,si

ipLoop:
    mov cl,es:[si].part_type
    or cl,cl
    jz ipDone
;
    cmp cl,0EEh
    je ipGpt
;
    mov eax,es:[si].part_sectors
    call ChsToLba
    jnc ipInst
;
    mov edx,es:[si].part_start_sector

ipInst:
    mov ds:vfs_curr_start_sector,edx
    mov ds:vfs_curr_start_sector+4,0
    mov ds:vfs_curr_sector_count,eax
    mov ds:vfs_curr_sector_count+4,0
;
    cmp cl,5
    je ipLink
;
    cmp cl,0Fh
    je ipLink
;
    call InstallMbrPartition
    jmp ipNextPart

ipLink:
    call InstallMbrExtended
    jmp ipNextPart

ipGpt:
    call InstallGpt

ipNextPart:
    add si,10h
    cmp si,40h
    jne ipLoop

ipDone:
    FreeSmallServ
    ret
init_part   Endp

code    ENDS

    END
