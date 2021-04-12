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

MAX_BITMAP_COUNT =  16
MAX_DISC_COUNT   =  16
MAX_PART_COUNT   = 255

req_wait_header      STRUC

rw_obj              wait_obj_header <>
rw_handle           DW ?

req_wait_header      ENDS

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


data    SEGMENT byte public 'DATA'

disc_arr        DW MAX_DISC_COUNT DUP (?)

part_arr        DW MAX_PART_COUNT DUP (?)

data    ENDS


;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern LocalLockSector:near
    extern LocalUnlockSector:near
    extern VfsServer:far
    extern RemoveReq:near
    extern BlockToBuf:near
    extern BlockToBitmap:near
    extern SectorToBlock:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyPart
;
;       DESCRIPTION:    Notify part
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       FS          Part sel
;                       EDX:EAX     Sector
;                       SI          Req mask
;                       CX          Lock count
;
;       RETURNS:        CX          Lock count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyPart    Proc near
    push gs
    push ebx
    push esi
    push edi
    push ebp
;
    mov bx,si
    push ebx

npLoop:
    pop ebx
    or bx,bx
    jz npDone
;
    bsf si,bx
    btc bx,si
;
    push ebx
    movzx esi,si
    dec esi
    add esi,esi
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz npLoop
;
    mov gs,si
    movzx ebp,gs:vfsrh_entry_count
    mov ebx,SIZE vfs_req_header
    or ebp,ebp
    jz npLoop

npCheckLoop:
    mov esi,gs:[ebx].vfsre_sector_count
    or esi,esi
    jz npCheckNext
;
    mov esi,eax
    mov edi,edx
    sub esi,gs:[ebx].vfsre_start_sector
    sbb edi,gs:[ebx].vfsre_start_sector+4
    jc npCheckNext
;
    or edi,edi
    jnz npCheckNext
;
    cmp esi,gs:[ebx].vfsre_sector_count
    jae npCheckNext
;
    inc cx
    sub gs:vfsrh_remain_count,1
    jnz npCheckNext
;
    xor di,di
    xchg di,gs:vfsrh_wait_obj
    or di,di
    jz npCheckNext
;
    push es
    mov es,edi
    SignalWait
    pop es
    
npCheckNext:
    add ebx,SIZE vfs_req_entry
    sub ebp,1
    jnz npCheckLoop
;
    jmp npLoop

npDone:
    pop ebp
    pop edi
    pop esi
    pop ebx
    pop gs
    ret
NotifyPart    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyVfs
;
;       DESCRIPTION:    Notify read buffers
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Sector
;                       BX          Req mask
;                       CX          Lock count
;
;       RETURNS:        CX          Lock count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyVfs    Proc near
    push fs
    push esi
    push edi
    push ebp
;
    push ebx
;
    mov ebx,OFFSET vfs_part_arr
    mov ebp,MAX_VFS_PARTITIONS

nvfLoop:
    mov si,ds:[ebx]
    or si,si
    jz nvfNext
;
    mov fs,si
    mov esi,eax
    mov edi,edx
    add esi,7
    adc edi,0
    sub esi,fs:vfsp_start_sector
    sbb edi,fs:vfsp_start_sector+4
    jc nvfNext
;
    sub esi,7
    sbb edi,0
    jc nvfHandle
;
    sub esi,fs:vfsp_sector_count    
    sbb edi,fs:vfsp_sector_count+4
    jnc nvfNext

nvfHandle:
    pop esi
    call NotifyPart
    push esi

nvfNext:
    add ebx,2
    sub ebp,1
    jnz nvfLoop
;
    pop ebx
;
    pop ebp
    pop edi
    pop esi
    pop fs
    ret
NotifyVfs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyReadBuf
;
;       DESCRIPTION:    Notify read buffers
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Sector
;                       ESI         Physical entry buf
;                       ECX         Sector count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public NotifyReadBuf

NotifyReadBuf    Proc near
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push ebp
;
    mov ebp,ecx
  
nrbLoop:
    xor cx,cx
    or es:[esi].vfsp_flags,VFS_PHYS_VALID
    mov bx,es:[esi].vfsp_ref_bitmap
    or bx,bx
    jz nrbNext
;
    and bx,0FFFEh
    jz nrbPartOk
;
    call NotifyVfs

nrbPartOk:
    mov bx,es:[esi].vfsp_ref_bitmap
    test bx,1
    jz nrbNext
;
    call RemoveReq

nrbNext:
    mov es:[esi].vfsp_ref_bitmap,cx
    add esi,8
    sub bp,ds:vfs_sectors_per_block
    ja nrbLoop
;
    pop ebp
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
NotifyReadBuf   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RunVfsReq
;
;       DESCRIPTION:    Run VFS req
;
;       PARAMETERS:     DS      Disc sel
;                       ES      Req sel`
;                       AX      Op
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunVfsReq  Proc near
    push eax
;
    mov es:vch_op,ax
    GetThread
    mov es:vch_thread,ax
;
    EnterSection ds:vfs_section
;
    mov ax,ds:vfs_req_list
    or ax,ax
    je rvrEmpty
;    
    push ds
    push esi
;
    mov ds,ax
    mov si,ds:vch_prev
    mov ds:vch_prev,es
    mov ds,si
    mov ds:vch_next,es
    mov es:vch_next,ax
    mov es:vch_prev,si
;
    pop esi
    pop ds
    jmp rvrWait
    
rvrEmpty:
    mov es:vch_next,es
    mov es:vch_prev,es
    mov ds:vfs_req_list,es

rvrWait:
    LeaveSection ds:vfs_section
;
    WaitForSignal
;
    pop eax
    ret
RunVfsReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateDiscSel
;
;       DESCRIPTION:    Create partition selector
;
;       PARAMETERS:     DS:ESI  VFS table
;                       BX      Param
;
;       RETURNS:        BX      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDiscSel  Proc near
    push es
    push fs
    push ecx
    push esi
    push edi
    push ebp
;
    mov ax,SEG data
    mov fs,ax
    InstallVfsDisc
;
    movzx ebp,al
    shl ebp,1
    add ebp,OFFSET disc_arr
;
    mov eax,OFFSET vfs_buf_arr
    AllocateSmallGlobalMem
;
    mov ecx,SIZE vfs_table_struc
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov ecx,OFFSET vfs_buf_arr - SIZE vfs_table_struc
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov fs:[ebp],es
    mov es:vfs_param,bx
    mov es:vfs_flags,0
    mov es:vfs_server,0
;
    mov eax,ebp
    sub eax,OFFSET disc_arr
    shr eax,1
    mov es:vfs_disc_nr,al
;
    mov bx,es
    clc

cdsDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop fs
    pop es
    ret
CreateDiscSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreatePartSel
;
;       DESCRIPTION:    Create partition selector
;
;       PARAMETERS:     DS      VFS sel
;
;       RETURNS:        BX      Part sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePartSel  Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov ecx,MAX_VFS_PARTITIONS
    mov esi,OFFSET vfs_part_arr

cpsLoop:
    mov ax,ds:[esi]
    or ax,ax
    jz cpsFound
;
    add esi,2
    loop cpsLoop
;
    stc
    jmp cpsDone

cpsFound:
    mov eax,SIZE vfs_part
    AllocateSmallGlobalMem
    mov ecx,eax
    xor edi,edi
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov eax,ds:vfs_curr_start_sector
    mov es:vfsp_start_sector,eax
    mov eax,ds:vfs_curr_start_sector+4
    mov es:vfsp_start_sector+4,eax
    mov eax,ds:vfs_curr_sector_count
    mov es:vfsp_sector_count,eax
    mov eax,ds:vfs_curr_sector_count+4
    mov es:vfsp_sector_count+4,eax
    mov es:vfsp_disc_sel,ds
;
    mov ds:[esi],es
    mov eax,esi
    sub eax,OFFSET vfs_part_arr
    shr eax,1
    mov es:vfsp_part_nr,al
;
    mov al,ds:vfs_disc_nr
    mov es:vfsp_disc_nr,al
;
    mov ax,SEG data
    mov ds,ax
    mov ecx,MAX_PART_COUNT
    mov esi,OFFSET part_arr

cpsPartLoop:
    mov ax,ds:[esi]
    or ax,ax
    jz cpsPartFound
;
    add esi,2
    loop cpsPartLoop
;
    CrashGate

cpsPartFound:
    mov ds:[esi],es
    mov bx,es
    clc

cpsDone:
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
CreatePartSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddFatPartition
;
;       DESCRIPTION:    Add FAT partition
;
;       PARAMETERS:     DS      VFS sel
;                       ES:EDI  Partition name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fat_serv_name  DB 'fat', 0

AddFatPartition   Proc near
    push ds
    push es
    push fs
    pushad
;
    call CreatePartSel
    jc afpDone
;
    mov fs,bx
;
    mov ax,es
    mov ds,ax
    mov esi,edi
    mov eax,6
    AllocateSmallGlobalMem
    xor edi,edi
    movs dword ptr es:[edi],ds:[esi]
    movs byte ptr es:[edi],ds:[esi]
    xor al,al
    stos byte ptr es:[edi]
;
    mov ax,es
    mov ds,ax
    xor esi,esi
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET fat_serv_name
    mov al,4
    mov bh,fs:vfsp_disc_nr
    mov bl,fs:vfsp_part_nr
    LoadServer
;
    mov fs:vfsp_app_sel,bx
;
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem

afpDone:
    popad
    pop fs
    pop es
    pop ds
    ret
AddFatPartition   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddPartition
;
;       DESCRIPTION:    Add partition
;
;       PARAMETERS:     DS      VFS sel
;                       ES:EDI  Partition name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPartition   Proc near
    push eax
;
    mov ax,es:[edi]
    cmp ax,'AF'
    jne apNotFat
;
    mov al,es:[edi+2]
    cmp al,'T'
    jne apNotFat
;
    call AddFatPartition

apNotFat:
    pop eax
    ret
AddPartition   Endp

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
;       NAME:           InitPartition
;
;       DESCRIPTION:    Init partition
;
;       PARAMETERS:     BX       VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_part_name       DB 'VFS Init',0

init_part:
    mov ds,bx
;
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
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreatePartThread
;
;       DESCRIPTION:    Start part thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreatePartThread

CreatePartThread Proc near
    push ds
;
    mov bx,ds
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET init_part
    mov edi,OFFSET init_part_name
    mov al,4
    CreateThread
;
    pop ds
    ret
CreatePartThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartVfs
;
;       DESCRIPTION:    Start VFS
;
;       PARAMETERS:     DS:ESI  VFS table
;                       ES:EDI  Server name
;                       BX      Dev param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_vfs_name       DB 'Start VFS',0

start_vfs    Proc far
    push ds
    push eax
    push esi
;
    call CreateDiscSel
    jc svfsDone
;
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET VfsServer
    mov al,4
    CreateServerProcess

svfsDone:
    pop esi
    pop eax
    pop ds
    ret
start_vfs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StopVfs
;
;       DESCRIPTION:    Stop vfs
;
;       PARAMETERS:     BX      VFS handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_vfs_name       DB 'Stop VFS',0

stop_vfs    Proc far
    push es
    push ebx
;
    mov es,ebx
    lock or es:vfs_flags,VFS_FLAG_STOPPED
    mov bx,es:vfs_server
    Signal
;
    pop ebx
    pop es    
    ret
stop_vfs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsHandle
;
;       DESCRIPTION:    Get VFS handle
;
;       RETURNS:        EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_handle_name       DB 'Get VFS Handle',0

get_vfs_handle    Proc far
    push ds
    push es
    push eax
    push esi
;
    GetThread
    mov ds,ax
    mov bx,ds:p_prog_id
;
    mov ax,SEG data
    mov ds,ax

gvfshRetry:
    mov esi,OFFSET part_arr
    mov ecx,MAX_PART_COUNT

gvfshLoop:
    mov ax,ds:[esi]
    or ax,ax
    jz gvfshNext
;
    mov es,ax
    cmp bx,es:vfsp_app_sel
    je gvfshFound

gvfshNext:
    add esi,2
    loop gvfshLoop
;
    mov ax,10
    WaitMilliSec
    jmp gvfshRetry

gvfshFound:
    sub esi,OFFSET part_arr
    shr esi,1
    inc esi
    mov ebx,esi
;
    pop esi
    pop eax
    pop es
    pop ds
    ret
get_vfs_handle    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleToPart
;
;       DESCRIPTION:    Convert from handle to partition selector
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        ES          VFS part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleToPart    Proc near
    push eax
    push ebx
;
    mov ax,SEG data
    mov es,ax
    or bx,bx
    jz htpFail
;
    cmp ebx,MAX_PART_COUNT
    jbe htpInRange

htpFail:
    stc
    jmp htpDone

htpInRange:
    dec ebx
    add ebx,ebx
    mov ax,es:[ebx].part_arr
    or ax,ax
    jz htpFail
;
    mov es,ax
    clc

htpDone:
    pop ebx
    pop eax
    ret
HandleToPart    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsSectors
;
;       DESCRIPTION:    Get VFS sectors
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        EDX:EAX     Sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_sectors_name       DB 'Get VFS Sectors',0

get_vfs_sectors    Proc far
    push es
;
    call HandleToPart
    jc gvsDone
;
    mov eax,es:vfsp_sector_count
    mov edx,es:vfsp_sector_count+4
    clc

gvsDone:
    pop es
    ret
get_vfs_sectors    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateVfsReq
;
;       DESCRIPTION:    Create a VFS req
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        EBX         Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_vfs_req_name       DB 'Create VFS Req',0

create_vfs_req    Proc far
    push ds
    push es
    push eax
    push ecx
    push edx
    push edi
;
    mov dh,bl
;
    call HandleToPart
    jc crvrDone
;
    mov eax,es
    mov ds,eax
    mov ecx,MAX_VFS_REQ_COUNT
    mov edi,OFFSET vfsp_req_arr
    xor ax,ax
    repnz scas word ptr es:[edi]
    jz crvrFound

crvrFail:
    stc
    jmp crvrDone

crvrFound:
    mov bx,di
    sub bx,OFFSET vfsp_req_arr
    shr bx,1
    mov bh,dh
    sub edi,2
;
    mov eax,SIZE vfs_part_req
    AllocateBigServSel
    mov ds:[edi],es
;
    xor edi,edi
    mov ecx,SIZE vfs_part_req
    shr ecx,2
    xor eax,eax
    rep stos dword ptr es:[edi]
    clc

crvrDone:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
create_vfs_req    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CloseVfsReq
;
;       DESCRIPTION:    Close a VFS req
;
;       PARAMETERS:     EBX         Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_vfs_req_name       DB 'Close VFS Req',0

close_vfs_req    Proc far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    mov ax,SEG data
    mov ds,ax
    or bh,bh
    jz clvrDone
;
    cmp bh,MAX_PART_COUNT
    ja clvrDone
;
    movzx esi,bh
    dec esi
    add esi,esi
    mov ax,ds:[esi].part_arr
    or ax,ax
    jz clvrDone
;
    mov ds,ax
    or bl,bl
    jz clvrDone
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja clvrDone
;
    movzx esi,bl
    dec esi
    shl esi,1
    xor bx,bx
    xchg bx,ds:[esi].vfsp_req_arr
    or bx,bx
    jz clvrDone
;
    mov es,bx
    FreeBigServSel

clvrDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
close_vfs_req    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReqHandleToSel
;
;       DESCRIPTION:    Convert req handle to selector
;
;       PARAMETERS:     EBX         Req handle
;
;       RETURNS:        NC
;                           FS      Part sel
;                           GS      Req sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqHandleToSel  Proc near
    push ds
    push esi
;
    mov si,SEG data
    mov ds,si
    or bh,bh
    jz rqhsFail
;
    cmp bh,MAX_PART_COUNT
    ja rqhsFail
;
    movzx esi,bh
    dec esi
    add esi,esi
    mov si,ds:[esi].part_arr
    or si,si
    jz rqhsFail
;
    mov fs,si
    or bl,bl
    jz rqhsFail
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja rqhsFail
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz rqhsFail
;
    mov gs,si
    clc
    jmp rqhsDone

rqhsFail:
    stc

rqhsDone:
    pop esi
    pop ds
    ret
ReqHandleToSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartVfsReq
;
;       DESCRIPTION:    Start VFS req
;
;       PARAMETERS:     EBX         Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_vfs_req_name       DB 'Start VFS Req',0

start_vfs_req    Proc far
    push fs
    push gs
    push ebx
;
    call ReqHandleToSel
    jc srqDone
;
    mov eax,gs:vfsrh_remain_count
    or eax,eax
    jz srqDone
;
    push ds
    mov ds,fs:vfsp_disc_sel
    mov bx,ds:vfs_server
    Signal
    pop ds

srqDone:
    pop ebx
    pop gs
    pop fs
    ret
start_vfs_req   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsVfsReqDone
;
;       DESCRIPTION:    Is VFS req done
;
;       PARAMETERS:     EBX         Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_vfs_req_done_name       DB 'Is VFS Req Done',0

is_vfs_req_done    Proc far
    push fs
    push gs
    push esi
;
    call ReqHandleToSel
    jc irqdDone
;
    mov esi,gs:vfsrh_remain_count
    or esi,esi
    stc
    jnz irqdDone
;
    clc

irqdDone:
    pop esi
    pop gs
    pop fs
    ret
is_vfs_req_done   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForReq
;
;           DESCRIPTION:    Start a wait for req
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_req      PROC far
    push fs
    push gs
    push eax
    push ebx
;
    mov bx,es:rw_handle
    call ReqHandleToSel
    jc stwrDone
;
    mov gs:vfsrh_wait_obj,es
    mov eax,gs:vfsrh_remain_count
    or eax,eax
    jnz stwrStart
;
    mov gs:vfsrh_wait_obj,0
    SignalWait
    jmp stwrDone

stwrStart:
    push ds
    mov ds,fs:vfsp_disc_sel
    mov bx,ds:vfs_server
    Signal
    pop ds

stwrDone:
    pop ebx
    pop eax
    pop gs
    pop fs
    ret
start_wait_for_req Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForReq
;
;           DESCRIPTION:    Stop a wait for req
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_req       PROC far
    push fs
    push gs
    push eax
    push ebx
;
    mov bx,es:rw_handle
    call ReqHandleToSel
    jc spwrDone
;
    mov gs:vfsrh_wait_obj,0

spwrDone:
    pop ebx
    pop eax
    pop gs
    pop fs
    ret
stop_wait_for_req Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearReq
;
;           DESCRIPTION:    Clear req
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_req       PROC far
    ret
clear_req       Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsReqIdle
;
;           DESCRIPTION:    Check if req is idle
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_req_idle     PROC far
    push fs
    push gs
    push eax
    push ebx
;
    mov bx,es:rw_handle
    call ReqHandleToSel
    jc iriDone
;
    mov eax,gs:vfsrh_remain_count
    or eax,eax
    clc
    jne iriDone
;
    stc

iriDone:
    pop ebx
    pop eax
    pop gs
    pop fs
    ret
is_req_idle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddWaitForVfsReq
;
;       DESCRIPTION:    Add wait for VFS req
;
;       PARAMETERS:     EBX         Wait handle
;                       EAX         Req handle
;                       ECX         ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_vfs_req_name       DB 'Add Wait For VFS Req',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_req,   SEG code
aw1 DD OFFSET stop_wait_for_req,    SEG code
aw2 DD OFFSET clear_req,            SEG code
aw3 DD OFFSET is_req_idle,          SEG code

add_wait_for_vfs_req    Proc far
    push ds
    push es
    push eax
    push edi
;
    push ax
    mov eax,cs
    mov es,eax
    mov ax,SIZE req_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWait
    pop ax
    jc awrqDone
;
    mov es:rw_handle,ax

awrqDone:
    pop edi
    pop eax
    pop es
    pop ds
    ret
add_wait_for_vfs_req   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForVfsCmd
;
;       DESCRIPTION:    Wait for VFS cmd
;
;       PARAMETERS:     EBX        VFS handle
;                       EDX        Buffer
;
;       RETURNS:        EAX        Cmd #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_vfs_cmd_name DB 'Wait For VFS Cmd', 0

wait_for_vfs_cmd   Proc far
    WaitForSignal
    ret
wait_for_vfs_cmd   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           TestServ
;
;       DESCRIPTION:    Test server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_serv_name DB 'Test Serv', 0

test_serv   Proc far
    WaitForSignal
    ret
test_serv   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDiscInfo
;
;       DESCRIPTION:    Get VFS disc info
;
;       PARAMETERS:     AL          Disc #
;
;       RETURNS:        CX          Bytes / sector
;                       EDX:EAX     Total sectors
;                       SI          BIOS sectors / cylinder
;                       DI          BIOS heads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_disc_info_name       DB 'Get VFS Disc Info',0

get_vfs_disc_info    Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov ax,ds:[ebx].disc_arr
    or ax,ax
    stc
    jz gvdiDone
;
    mov ds,ax
    mov cx,ds:vfs_bytes_per_sector
    mov eax,ds:vfs_sectors
    mov edx,ds:vfs_sectors+4
    mov si,-1
    mov di,-1
    clc

gvdiDone:
    pop ebx
    pop ds
    ret
get_vfs_disc_info   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDiscVendorInfo
;
;       DESCRIPTION:    Get VFS disc vendor info
;
;       PARAMETERS:     AL          Disc #
;                       ES:EDI      Vendor buffer
;                       ECX         Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_disc_vendor_info_name       DB 'Get VFS Disc Vendor Info',0

get_vfs_disc_vendor_info    Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].disc_arr
    or bx,bx
    stc
    jz gvdviDone
;
    sub ecx,1
    jbe gvdviDone
;
    cmp ecx,255
    jb gdvdiSizeOk
;
    mov ds,bx
    mov esi,OFFSET vfs_vendor_str
    mov ecx,255

gdvdiSizeOk:
    xor edx,edx

gdvdiCopy:
    lodsb
    or al,al
    jz gdvdiEob
;
    inc edx
    stos byte ptr es:[edi]
    loop gdvdiCopy

gdvdiEob:    

gdvdiTrim:
    sub edx,1
    jbe gdvdiTerm    
;
    mov al,es:[edi-1]
    cmp al,' '
    jne gdvdiTerm 
;       
    sub edi,1
    jmp gdvdiTrim

gdvdiTerm:
    xor al,al
    stos byte ptr es:[edi]
    clc

gvdviDone:
    pop ebx
    pop ds
    ret
get_vfs_disc_vendor_info   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadRawSectors
;
;       DESCRIPTION:    Read raw sectors
;
;       PARAMETERS:     DS              Disc sel
;                       EDX:EAX         Sector
;                       ECX             Sector count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadRawSectors  Proc near
    push eax
    mov eax,ecx
    shl eax,3
    add eax,SIZE vfs_cmd_read
    AllocateSmallGlobalMem
    pop eax
;
    mov es:vcr_sector,eax
    mov es:vcr_sector+4,edx
    mov es:vcr_count,ecx
    mov ax,VFS_READ_MSG
    call RunVfsReq

    ret
ReadRawSectors  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadVfsDisc
;
;       DESCRIPTION:    Read VFS disc
;
;       PARAMETERS:     BL              Disc #
;                       EDX:EAX         Sector
;                       ES:EDI          Buffer
;                       ECX             Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_vfs_disc_name       DB 'Read VFS Disc',0

read_vfs_disc    Proc far
    push ds
    push ebx
;
    int 3
    push bx
    mov bx,SEG data
    mov ds,bx
    pop bx
    movzx ebx,bx
    shl ebx,1
    mov bx,ds:[ebx].disc_arr
    or bx,bx
    stc
    jz rvdDone
;
    push ecx
    mov ds,bx
    mov ebx,ecx
    dec ebx
    sub cl,ds:vfs_sector_shift
    add cl,9
    shr ebx,cl
    mov ecx,ebx
    inc ecx
    call ReadRawSectors
    pop ecx

rvdDone:
    pop ebx
    pop ds
    ret
read_vfs_disc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SectorCountToBlock
;
;       DESCRIPTION:    Converts between sector & count # and block #
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Sector #
;                       ECX         Sector count
;
;       RETURNS:        NC
;                         EDX:EAX   Block #
;                         ECX       Block count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SectorCountToBlock    Proc near
    push ebx
    push ebp
;
    mov ebp,ecx
;
    cmp edx,ds:vfs_sectors+4
    jb sctbInRange
    ja sctbFail
;
    cmp eax,ds:vfs_sectors
    jb sctbInRange

sctbFail:
    stc
    jmp sctbDone

sctbInRange:
    mov cl,3
    sub cl,ds:vfs_sector_shift
    mov bx,1
    shl bx,cl
    dec bx
    and bl,al
    jz sctbCountOk

cstbLoop:
    inc ebp
    dec eax
    sub bl,1
    jnz cstbLoop

sctbCountOk:
    dec ebp
    shr ebp,cl
    inc ebp
;
    mov cl,ds:vfs_sector_shift
    or cl,cl
    jz sctbOk

sctbShift:
    add eax,eax
    adc edx,edx
;
    sub cl,1
    jnz sctbShift

sctbOk:
    mov ecx,ebp
    clc

sctbDone:
    pop ebp
    pop ebx
    ret
SectorCountToBlock   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetReqMask
;
;       DESCRIPTION:    Get req mask
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       FS          Part sel
;                       EBX         Req handle
;
;       RETURNS:        BP          Req mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetReqMask    Proc near
    push ecx
;
    mov cl,bl
    mov bp,1
    shl bp,cl
;
    pop ecx
    ret
GetReqMask   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddVfsSectors
;
;       DESCRIPTION:    Add VFS sectors
;
;       PARAMETERS:     EBX         Req handle
;                       EDX:EAX     Start sector
;                       ECX         Sector count
;
;       RETURNS:        EBX         Req #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_vfs_sectors_name       DB 'Add VFS Sectors',0

add_vfs_sectors    Proc far
    push ds
    push es
    push fs
    push gs
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov si,SEG data
    mov ds,si
    or bh,bh
    jz arsFail
;
    cmp bh,MAX_PART_COUNT
    ja arsFail
;
    movzx esi,bh
    dec esi
    add esi,esi
    mov si,ds:[esi].part_arr
    or si,si
    jz arsFail
;
    mov fs,si
    or bl,bl
    jz arsFail
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja arsFail
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz arsFail
;
    mov gs,si
    mov esi,fs:vfsp_sector_count
    mov edi,fs:vfsp_sector_count+4
    sub esi,eax
    sbb edi,edx
    jc arsFail
;
    sub esi,ecx
    sbb edi,0
    jc arsFail
;
    mov ds,fs:vfsp_disc_sel
    mov si,serv_flat_sel
    mov es,si
;
    EnterSection ds:vfs_section
;
    mov di,gs:vfsrh_deleted_count
    or di,di
    jz arsAppend
;
    dec di
    mov gs:vfsrh_deleted_count,di
;
    mov edi,SIZE vfs_req_header

arsScanLoop:
    mov esi,gs:[edi].vfsre_sector_count
    or esi,esi
    jz arsTake
;
    add edi,SIZE vfs_req_entry
    jmp arsScanLoop

arsAppend:
    movzx edi,gs:vfsrh_entry_count
    cmp di,MAX_VFS_ENTRY_COUNT
    je arsLeaveFail
;
    inc di
    mov gs:vfsrh_entry_count,di
    shl edi,4

arsTake:
    add eax,fs:vfsp_start_sector
    adc edx,fs:vfsp_start_sector+4
;
    push eax
    push ebx
    push ecx
;
    mov cl,3
    sub cl,ds:vfs_sector_shift
    mov bx,1
    shl bx,cl
    dec bx
    movzx esi,ax
    and si,bx
    shl si,9
    mov gs:[edi].vfsre_linear,esi
    not bx
    and ax,bx
    mov gs:[edi].vfsre_start_sector,eax
    mov gs:[edi].vfsre_start_sector+4,edx
;
    pop ecx
    pop ebx
    pop eax
;
    call SectorCountToBlock
    jc arsLeaveFail
;
    push ebx
    push ecx
;
    mov ebx,ecx
    mov cl,3
    sub cl,ds:vfs_sector_shift
    shl ebx,cl
    mov gs:[edi].vfsre_sector_count,ebx
;
    pop ecx
    pop ebx
;
    call GetReqMask

arsLoop:
    call BlockToBuf
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jnz arsNext
;
    inc gs:vfsrh_remain_count
    or es:[esi].vfsp_ref_bitmap,bp
;
    push edi
;
    call BlockToBitmap
    mov ebx,eax
    shr ebx,3
    and ebx,1FFFFh
    bts es:[edi],ebx
;
    pop edi
;
    mov ebx,ds:vfs_scan_pos
    and ebx,ds:vfs_scan_pos+4
    add ebx,1
    jnc arsNext
;
    mov ds:vfs_scan_pos,eax
    mov ds:vfs_scan_pos+4,edx

arsNext:
    add eax,8
    adc edx,0
    sub ecx,1
    jnz arsLoop
;
    LeaveSection ds:vfs_section
;
    mov ebx,edi
    shr ebx,4
    clc
    jmp arsDone

arsLeaveFail:
    LeaveSection ds:vfs_section

arsFail:
    stc

arsDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    ret
add_vfs_sectors    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RemoveVfsSectors
;
;       DESCRIPTION:    Remove VFS sectors
;
;       PARAMETERS:     EBX         Req handle
;                       EAX         Req #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_vfs_sectors_name       DB 'Remove VFS Sectors',0

remove_vfs_sectors    Proc far
    push ds
    push es
    push fs
    push gs
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov si,SEG data
    mov ds,si
    or bh,bh
    jz rrsDone
;
    cmp bh,MAX_PART_COUNT
    ja rrsDone
;
    movzx esi,bh
    dec esi
    add esi,esi
    mov si,ds:[esi].part_arr
    or si,si
    jz rrsDone
;
    mov fs,si
    or bl,bl
    jz rrsDone
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja rrsDone
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz rrsDone
;
    mov gs,si
    mov ds,fs:vfsp_disc_sel
    mov si,serv_flat_sel
    mov es,si
    mov edi,eax
    shl edi,4
;
    EnterSection ds:vfs_section
;
    xor eax,eax
    xchg eax,gs:[edi].vfsre_sector_count
    or eax,eax
    jz rrsLeave
;
    mov cl,3
    sub cl,ds:vfs_sector_shift
    shr eax,cl
    mov ecx,eax
;
    inc gs:vfsrh_deleted_count
    mov eax,gs:[edi].vfsre_start_sector
    mov edx,gs:[edi].vfsre_start_sector+4
    call SectorToBlock
    jc rrsLeave

rrsLoop:
    call BlockToBuf
    jc rrsNext
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz rrsDecRem

rrsUnlock:
    sub es:[esi].vfsp_ref_bitmap,1
    jmp rrsNext

rrsDecRem:
    dec gs:vfsrh_remain_count

rrsNext:
    add eax,8
    adc edx,0
    sub ecx,1
    jnz rrsLoop

rrsLeave:
    LeaveSection ds:vfs_section

rrsDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    ret
remove_vfs_sectors Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MapVfsReq
;
;       DESCRIPTION:    Map VFS req
;
;       PARAMETERS:     EBX         Req handle
;                       EAX         Req #
;
;       RETURNS:        EDX         Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_vfs_req_name       DB 'Map VFS Req',0

map_vfs_req    Proc far
    push ds
    push es
    push fs
    push gs
    push eax
    push ebx
    push ecx
    push esi
    push edi
    push ebp
;
    mov si,SEG data
    mov ds,si
    or bh,bh
    jz mvrFail
;
    cmp bh,MAX_PART_COUNT
    ja mvrFail
;
    movzx esi,bh
    dec esi
    add esi,esi
    mov si,ds:[esi].part_arr
    or si,si
    jz mvrFail
;
    mov fs,si
    or bl,bl
    jz mvrFail
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja mvrFail
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz mvrFail
;
    mov gs,si
    mov ds,fs:vfsp_disc_sel
    mov si,serv_flat_sel
    mov es,si
    mov edi,eax
    shl edi,4
;
    EnterSection ds:vfs_section
;
    mov eax,gs:[edi].vfsre_sector_count
    or eax,eax
    stc
    jz mvrLeave
;
    mov cl,3
    sub cl,ds:vfs_sector_shift
    shr eax,cl
    mov ecx,eax
;
    shl eax,12
    AllocateLocalLinear
    mov ebp,edx
;
    mov eax,gs:[edi].vfsre_start_sector
    mov edx,gs:[edi].vfsre_start_sector+4
    call SectorToBlock
    jc mvrLeave
;
    push ebp

mvrLoop:
    call BlockToBuf
    jc mvrNext
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz mvrNext
;
    push eax
    push edx
;
    mov edx,ebp
    mov eax,es:[esi]
    and ax,0F000h
    or ax,867h
    movzx ebx,word ptr es:[esi+4]
    SetPageEntry
;
    pop edx
    pop eax

mvrNext:
    add ebp,1000h
    add eax,8
    adc edx,0
    sub ecx,1
    jnz mvrLoop
;
    pop edx
    mov eax,gs:[edi].vfsre_linear
    and eax,0E00h
    add edx,eax
    mov gs:[edi].vfsre_linear,edx
;
    mov bx,system_data_sel
    mov es,bx
    sub edx,es:flat_base
    clc

mvrLeave:
    LeaveSection ds:vfs_section
    jmp mvrDone

mvrFail:
    stc

mvrDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    ret
map_vfs_req Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnmapVfsReq
;
;       DESCRIPTION:    Unmap VFS req
;
;       PARAMETERS:     EBX         Req handle
;                       EAX         Req #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unmap_vfs_req_name       DB 'Map VFS Req',0

unmap_vfs_req    Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov si,SEG data
    mov ds,si
    or bh,bh
    jz umvrDone
;
    cmp bh,MAX_PART_COUNT
    ja umvrDone
;
    movzx esi,bh
    dec esi
    add esi,esi
    mov si,ds:[esi].part_arr
    or si,si
    jz umvrDone
;
    mov fs,si
    or bl,bl
    jz umvrDone
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja umvrDone
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz umvrDone
;
    mov gs,si
    mov ds,fs:vfsp_disc_sel
    mov si,serv_flat_sel
    mov es,si
    mov edi,eax
    shl edi,4
;
    EnterSection ds:vfs_section
;
    mov eax,gs:[edi].vfsre_sector_count
    or eax,eax
    stc
    jz umvrLeave
;
    mov cl,3
    sub cl,ds:vfs_sector_shift
    shr eax,cl
    shl eax,12
    mov ecx,eax
    mov edx,gs:[edi].vfsre_linear
    and edx,0FFFFF000h
    jz umvrLeave
;
    FreeLinear
;
    mov edx,gs:[edi].vfsre_linear
    and edx,0FFFh
    mov gs:[edi].vfsre_linear,edx

umvrLeave:
    LeaveSection ds:vfs_section

umvrDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
unmap_vfs_req    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init
;
;       description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn init_buf:near

init    Proc far
    call init_buf
;
    mov ax,SEG data
    mov es,ax
    mov edi,OFFSET disc_arr
    mov ecx,MAX_DISC_COUNT
    xor ax,ax
    rep stos word ptr es:[edi]
;
    mov edi,OFFSET part_arr
    mov ecx,MAX_PART_COUNT
    xor ax,ax
    rep stos word ptr es:[edi]
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET start_vfs
    mov edi,OFFSET start_vfs_name
    xor cl,cl
    mov ax,start_vfs_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_vfs
    mov edi,OFFSET stop_vfs_name
    xor cl,cl
    mov ax,stop_vfs_nr
    RegisterOsGate
;
    mov esi,OFFSET get_vfs_disc_info
    mov edi,OFFSET get_vfs_disc_info_name
    xor cl,cl
    mov ax,get_vfs_disc_info_nr
    RegisterOsGate
;
    mov esi,OFFSET get_vfs_disc_vendor_info
    mov edi,OFFSET get_vfs_disc_vendor_info_name
    xor cl,cl
    mov ax,get_vfs_disc_vendor_info_nr
    RegisterOsGate
;
    mov esi,OFFSET read_vfs_disc
    mov edi,OFFSET read_vfs_disc_name
    xor cl,cl
    mov ax,read_vfs_disc_nr
    RegisterOsGate
;
    mov esi,OFFSET get_vfs_handle
    mov edi,OFFSET get_vfs_handle_name
    xor cl,cl
    mov ax,get_vfs_handle_nr
    RegisterServGate
;
    mov esi,OFFSET get_vfs_sectors
    mov edi,OFFSET get_vfs_sectors_name
    xor cl,cl
    mov ax,get_vfs_sectors_nr
    RegisterServGate
;
    mov esi,OFFSET create_vfs_req
    mov edi,OFFSET create_vfs_req_name
    xor cl,cl
    mov ax,create_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET close_vfs_req
    mov edi,OFFSET close_vfs_req_name
    xor cl,cl
    mov ax,close_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET start_vfs_req
    mov edi,OFFSET start_vfs_req_name
    xor cl,cl
    mov ax,start_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET is_vfs_req_done
    mov edi,OFFSET is_vfs_req_done_name
    xor cl,cl
    mov ax,is_vfs_req_done_nr
    RegisterServGate
;
    mov esi,OFFSET add_wait_for_vfs_req
    mov edi,OFFSET add_wait_for_vfs_req_name
    xor cl,cl
    mov ax,add_wait_for_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET wait_for_vfs_cmd
    mov edi,OFFSET wait_for_vfs_cmd_name
    xor cl,cl
    mov ax,wait_for_vfs_cmd_nr
    RegisterServGate
;
    mov esi,OFFSET test_serv
    mov edi,OFFSET test_serv_name
    mov ax,test_serv_nr
    RegisterServGate
;
    mov esi,OFFSET add_vfs_sectors
    mov edi,OFFSET add_vfs_sectors_name
    xor cl,cl
    mov ax,add_vfs_sectors_nr
    RegisterServGate
;
    mov esi,OFFSET remove_vfs_sectors
    mov edi,OFFSET remove_vfs_sectors_name
    xor cl,cl
    mov ax,remove_vfs_sectors_nr
    RegisterServGate
;
    mov esi,OFFSET map_vfs_req
    mov edi,OFFSET map_vfs_req_name
    xor cl,cl
    mov ax,map_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET unmap_vfs_req
    mov edi,OFFSET unmap_vfs_req_name
    xor cl,cl
    mov ax,unmap_vfs_req_nr
    RegisterServGate
    clc
    ret
init    Endp


code    ENDS

    END init
