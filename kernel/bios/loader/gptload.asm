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
; FATBOOT.ASM
; Second stage boot-loader for FAT12, FAT16 and FAT32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

IMG_SEG = 5000h
DATA_SEG = 6000h
MAX_IMAGES = 20

IMAGE_BASE = 121000h

boot_struc      STRUC

boot_jmp                    DB ?,?,?
boot_name                       DB 8 DUP(?)
boot_bytes_per_sector       DW ?
boot_sectors_per_cluster    DB ?
boot_resv_sectors               DW ?
boot_fats                       DB ?
boot_root_dirs              DW ?
boot_sectors16              DW ?
boot_media                      DB ?
boot_fat_sectors16              DW ?
boot_sectors_per_cyl        DW ?
boot_heads                      DW ?
boot_hidden_sectors             DD ?
boot_sectors                DD ?
boot_fat_sectors            DD ?
boot_ext_flags              DW ?
boot_fs_version             DW ?
boot_root_cluster               DD ?
boot_info_sector            DW ?
boot_backup_sector              DW ?

boot_struc          ENDS

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

fat_dir_struc   STRUC

fat_base        DB 8 DUP(?)
fat_ext         DB 3 DUP(?)
fat_attrib          DB ?
fat_case        DB ?
fat_cr_time_ms  DB ?
fat_cr_time         DW ?
fat_cr_date         DW ?
fat_acc_date    DW ?
fat_cluster_hi  DW ?
fat_time        DW ?
fat_date        DW ?
fat_cluster         DW ?
fat_file_size   DD ?

fat_dir_struc   ENDS

bios_lba_struc  STRUC
bl_size     DB 10h
bl_2        DB 0
bl_count    DW 1
bl_buf      DD 0
bl_lba      DD 0
bl_lbah     DD 0
bios_lba_struc  ENDS

mmap_struc  STRUC

mmap_len    DD ?
mmap_base   DD ?,?
mmap_size   DD ?,?
mmap_type   DD ?

mmap_struc  ENDS

bios_mem_struc  STRUC

bmap_base   DD ?,?
bmap_size   DD ?,?
bmap_type   DD ?
bmap_acpi   DD ?

bios_mem_struc  ENDS


_TEXT segment byte public use16 'CODE'

    .386p

; make sure the first instruction is a jump to the startup-code

    jmp Start

    extrn init:near

ReadCount           DW 0
RdosSectors         DW 0,0
DriveNr             DB 80h
DefaultBoot     DB 0
BootSector      DD 0
FatSector       DD 0
RootSector      DD 0
DataSector      DD 0
SectorsPerFat       DD 0
CurrentCluster      DD 0
RootEntries     DW 0
FatSize         DB 0
SafeBoot        DB 0
SectorsPerCluster   DW 0
ImageSize       DD 0
CurrFatSector       DD 0

Tics        DD ?

FsName          DB 10 DUP(?)

OrgTimerVect    DD ?
BootMedia       DB 0
CurrEntry       DW ?
MenuEntries     DW 0
MenuArr         DW MAX_IMAGES DUP(0)
EntryCount      DW 0
EntryArr        DB MAX_IMAGES * 32 DUP(0)

lba_buf bios_lba_struc <>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           singel_hex
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AL          Value
;                           AX          Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

singel_hex      PROC near
hex_conv_low:
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
    add al,7
ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
    add ah,7
ok_high1:
    add ah,30h
    ret
singel_hex      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteChar
;
;           DESCRIPTION:    Write character
;
;           PARAMETERS:         AL          Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteChar       PROC near
    push ax
    push bx
    mov ah,0Eh
    mov bx,7
    int 10h
    pop bx
    pop ax
    ret
WriteChar       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexByte
;
;           DESCRIPTION:    Write hex byte on screen
;
;           PARAMETERS:         AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    PROC near
    push ax
    mov ah,al
    and al,0F0h
    rol al,4
    cmp al,0Ah
    jb write_byte_low1
    add al,7
write_byte_low1:
    add al,'0'
    push ax
    push bx
    mov ah,0Eh
    mov bx,7
    int 10h
    pop bx
    pop ax
    mov al,ah
    and al,0Fh
    cmp al,0Ah
    jb write_byte_high1
    add al,7
write_byte_high1:
    add al,'0'
    push bx
    mov ah,0Eh
    mov bx,7
    int 10h
    pop bx
    pop ax
    ret
WriteHexByte    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexWord
;
;           DESCRIPTION:    Write hex word on screen
;
;           PARAMETERS:         AX          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord    PROC near
    xchg al,ah
    call WriteHexByte
    xchg al,ah
    call WriteHexByte
    ret
WriteHexWord    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexDword
;
;           DESCRIPTION:    Write hex dword on screen
;
;           PARAMETERS:     EAX          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword    PROC near
    push bx
;    
    mov bx,ax
    shr eax,16
    xchg al,ah
    call WriteHexByte
    xchg al,ah
    call WriteHexByte
;
    mov ax,bx    
    xchg al,ah
    call WriteHexByte
    xchg al,ah
    call WriteHexByte
;
    pop bx    
    ret
WriteHexDword    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TimerInt
;
;           DESCRIPTION:    TIMER INTERRUPT
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TimerInt:
    push eax
    mov eax,cs:Tics
    or eax,eax
    jz tiDone
;
    dec eax
    mov cs:Tics,eax

tiDone:
    pop eax
    jmp cs:OrgTimerVect
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteAsciiz
;
;           DESCRIPTION:    Write text to screen
;
;           PARAMETERS:         CS:SI       Message to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteAsciiz     Proc near
    lods byte ptr cs:[si]
    or al,al
    jz WriteAsciizDone
    mov ah,0Eh
    mov bx,7
    int 10h
    jmp WriteAsciiz
WriteAsciizDone:
    ret
WriteAsciiz     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMemMap
;
;       DESCRIPTION:    Get memory map
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMemMap   Proc near
    push es
    pushad
;    
    mov ax,9E00h
    mov es,ax
;
    xor di,di
    xor ebx,ebx
    mov es:[edi],ebx
;    
    mov di,4    
    mov eax,20
    stosd
    xor ebp,ebp
    mov edx,534D4150h
    mov eax,0E820h
    mov ecx,24    
    mov es:[di].bmap_acpi,1
    int 15h
    jc gmmFail
;
    mov edx,534D4150h
    cmp eax,edx
    jne gmmFail
;
    test ebx,ebx
    jz gmmFail
;
    jmp gmmValidate

gmmLoop:
    mov eax,0E820h
    mov es:[di].bmap_acpi,1
    mov ecx,24
    int 15h
    jc gmmEnd         
;
    mov edx,534D4150h

gmmValidate:
    jcxz gmmNext
;
    test es:[di].bmap_acpi,1
    jz gmmNext
;
    mov ecx,es:[di].bmap_size
    or ecx,es:[di].bmap_size+4
    jz gmmNext
;
    add ebp,SIZE mmap_struc
    add di,OFFSET bmap_acpi
    mov eax,20
    stosd

gmmNext:
    test ebx,ebx
    jne gmmLoop

gmmEnd:
    xor di,di
    mov eax,ebp
    stosd
        
gmmFail:
    popad
    pop es   
    ret
GetMemMap   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadSector
;
;           DESCRIPTION:    Read data
;
;           PARAMETERS:     EDX         Sector #
;                           DS:BX   Address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector      Proc near
    push ds
    pushad
;    
    mov cs:lba_buf.bl_count,1
    mov cs:lba_buf.bl_lba,edx
    mov word ptr cs:lba_buf.bl_buf,bx
    mov word ptr cs:lba_buf.bl_buf+2,ds
;    
    mov ax,cs
    mov ds,ax
    mov si,OFFSET lba_buf
    mov ah,42h
    mov dl,cs:DriveNr
    int 13h
;
    popad
    pop ds
    ret
ReadSector      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadSectors
;
;           DESCRIPTION:    Read data
;
;           PARAMETERS:     EDX     Sector #
;                           CX      Number of sectors
;                           DS:BX   Address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSectors      Proc near
    push ds
    pushad
;    
    mov cs:lba_buf.bl_count,cx
    mov cs:lba_buf.bl_lba,edx
    mov word ptr cs:lba_buf.bl_buf,bx
    mov word ptr cs:lba_buf.bl_buf+2,ds
;    
    mov ax,cs
    mov ds,ax
    mov si,OFFSET lba_buf
    mov ah,42h
    mov dl,cs:DriveNr
    int 13h
;
    popad
    pop ds
    ret
ReadSectors      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadFatSector
;
;           DESCRIPTION:    Read fat sector
;
;           PARAMETERS:         EDX         Sector #
;                           DS:200  Address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadFatSector   Proc near
    cmp edx,cs:CurrFatSector
    clc
    je ReadFatSectorDone
;
    call ReadSector
    mov cs:CurrFatSector,edx

ReadFatSectorDone:
    ret
ReadFatSector   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupVectors
;
;           DESCRIPTION:    Setup new int-vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupVectors    Proc near
    push ds
    push eax
    push bx
;    
    xor ax,ax
    mov ds,ax
    mov bx,8 SHL 2
    mov eax,[bx]
    mov cs:OrgTimerVect,eax
    mov word ptr [bx],OFFSET TimerInt
    mov [bx+2],cs
;
    pop bx
    pop eax
    pop ds    
    ret
SetupVectors    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NextCluster12
;
;           DESCRIPTION:    Find next cluster for FAT12
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NextCluster12   PROC near
    push ebx
    push cx
;
    mov edx,cs:CurrentCluster
    mov cx,dx
    add dx,dx
    add dx,cx
    mov cx,dx
    movzx edx,dx
    shr edx,10
    add edx,cs:FatSector
    and cx,3FFh
    clc
    rcr cx,1
    pushf
    mov bx,200h
    call ReadFatSector
    jnc nc12Locked
    popf
    stc
    jmp nc12Done

nc12Locked:
    mov bx,cx
    add bx,200h
    popf
    jc nc12High
    mov cl,[bx]
    inc bx
    test bx,1FFh
    jnz nc12LowOk
    inc edx
    mov bx,200h
    call ReadFatSector
    jc nc12Done

nc12LowOk:
    mov ch,[bx]
    and cx,0FFFh
    jmp nc12Ok

nc12High:
    mov ch,[bx]
    and ch,0F0h
    inc bx
    test bx,1FFh
    jnz nc12HighOk
    inc edx
    mov bx,200h
    call ReadFatSector
    jc nc12Done

nc12HighOk:
    mov cl,[bx]
    rol cx,4
nc12Ok:
    movzx edx,cx
    mov cs:CurrentCluster,edx
    cmp edx,0FF8h
    cmc

nc12Done:
    pop cx
    pop ebx
    ret
NextCluster12   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NextCluster16
;
;           DESCRIPTION:    Find next cluster for FAT16
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NextCluster16   PROC near
    push bx
    push cx
;
    mov bx,200h
    mov edx,cs:CurrentCluster
    add edx,edx
    mov cx,dx
    shr edx,9
    add edx,cs:FatSector
    and cx,1FFh
    call ReadFatSector
    jc nc16Done
;
    add bx,cx
    movzx edx,word ptr [bx]
    mov cs:CurrentCluster,edx
    cmp edx,0FFF8h
    cmc

nc16Done:
    pop cx
    pop bx
    ret
NextCluster16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NextCluster32
;
;           DESCRIPTION:    Find next cluster for FAT32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NextCluster32   PROC near
    push bx
    push cx
;
    mov bx,200h
    mov edx,cs:CurrentCluster
    shl edx,2
    mov cx,dx
    shr edx,9
    add edx,cs:FatSector
    and cx,1FFh
    call ReadFatSector
    jc nc32Done
;
    add bx,cx
    mov edx,[bx]
    and edx,0FFFFFFFh
    mov cs:CurrentCluster,edx
    cmp edx,0FFFFFF8h
    cmc

nc32Done:
    pop cx
    pop bx
    ret
NextCluster32   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NextCluster
;
;           DESCRIPTION:    Find next cluster
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NextCluster     Proc near
    cmp cs:FatSize,12
    je nextc12
;
    cmp cs:FatSize,16
    je nextc16

nextc32:
    call NextCluster32
    jmp next_cluster_done

nextc16:
    call NextCluster16
    jmp next_cluster_done

nextc12:
    call NextCluster12

next_cluster_done:
    ret
NextCluster     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCurrentSector
;
;           DESCRIPTION:    Get current sector
;
;       RETURNS:    EDX     Sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetCurrentSector    Proc near
    mov edx,cs:CurrentCluster
    sub edx,2
    movzx eax,cs:SectorsPerCluster
    mul edx
    mov edx,eax
    add edx,cs:DataSector
    ret
GetCurrentSector    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckDirEntry
;
;           DESCRIPTION:    Check a directory entry for a RDOS image file
;
;       PARAMETERS:     DS:SI       Dir entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckDirEntry   Proc near
    push es
    pushad
;
    mov ax,word ptr [si].fat_ext
    cmp ax,'IB'
    jne cdeDone
;
    mov al,[si].fat_ext+2
    cmp al,'N'
    jne cdeDone
;
    mov al,[si].fat_attrib
    test al,10h
    jnz cdeDone
;
    push cs:CurrentCluster
;    
    movzx edx,ds:[si].fat_cluster
    cmp cs:FatSize,32
    jnz cdeClustOk
;
    movzx eax,ds:[si].fat_cluster_hi
    shl eax,16
    or edx,eax

cdeClustOk:       
    mov cs:CurrentCluster,edx
;
    call GetCurrentSector
    mov bx,400h
    call ReadSector
    mov eax,[bx]    
    cmp eax,5A1E75D4h
    jne cdeNotRdos
;
    mov cx,cs:EntryCount
    mov di,OFFSET EntryArr
    mov ax,cx
    shl ax,5
    add di,ax
    mov ax,cs
    mov es,ax
    mov cx,10h
    rep movsw    
    inc cs:EntryCount

cdeNotRdos:
    pop cs:CurrentCluster       

cdeDone:    
    popad
    pop es
    ret
CheckDirEntry   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ScanDir
;
;           DESCRIPTION:    Scan directory for RDOS .bin files
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ScanDir Proc near
    push es
    push eax
    push cx
    push bp
;    
    mov ax,cs
    mov es,ax

sdClusterLoop:
    call GetCurrentSector
    mov cx,cs:SectorsPerCluster    

sdSectorLoop:
    mov si,200h
    push bx
    mov bx,si
    call ReadSector
    pop bx

sdLoop:
    call CheckDirEntry
    add si,20h
    test si,1FFh
    jnz sdLoop
;
    inc edx
    loop sdSectorLoop
;
    call NextCluster
    jnc sdClusterLoop

sdDone:
    pop bp
    pop cx
    pop eax
    pop es
    ret
ScanDir Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ScanRootDir
;
;           DESCRIPTION:    Scan root directory
;
;       PARAMETERS:     DI      File to scan for
;
;       RETURNS:    EDX     Start cluster # of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ScanRootDir Proc near
    push es
    push eax
    push cx
;    
    mov ax,cs
    mov es,ax
    xor si,si
    mov cx,cs:RootEntries
    mov edx,cs:RootSector
    push bx
    xor bx,bx
    call ReadSector
    pop bx

srdLoop:
    call CheckDirEntry
    add si,20h
    test si,1FFh
    jnz srdNextEntry
;
    xor si,si
    inc edx
;    
    push bx
    xor bx,bx
    call ReadSector
    pop bx

srdNextEntry:
    loop srdLoop

srdDone:
    pop cx
    pop eax
    pop es
    ret
ScanRootDir Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindRdosFiles
;
;           DESCRIPTION:    Find RDOS bootable files
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindRdosFiles   Proc near
    mov al,cs:FatSize
    cmp al,32
    je frf32
;
    call ScanRootDir
    ret

frf32:
    call ScanDir
    ret
FindRdosFiles   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindLine
;
;           DESCRIPTION:    Find a specific line
;
;       PARAMETERS:     SI      Filename
;
;       RETURNS:    AX      Entry offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindLine    Proc near
    push cx
    push edx
    push di
;
    mov cx,cs:EntryCount
    mov di,OFFSET EntryArr
    or cx,cx
    jz flFail

flLoop:
    mov edx,cs:[si]
    cmp edx,cs:[di]
    jne flNext
;
    mov edx,cs:[si+4]
    cmp edx,cs:[di+4]
    jne flNext
;
    mov dword ptr cs:[di],0
    mov ax,di
    clc
    jmp flDone

flNext:
    add di,20h
    loop flLoop

flFail:
    stc

flDone:
    pop di
    pop edx
    pop cx      
    ret
FindLine    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteLine
;
;           DESCRIPTION:    Write one full line
;
;       PARAMETERS:     SI      Offset to text
;               ES:DI   Screen buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteLine  Proc near
    push ax
    push cx
    push si
;
    mov ah,7
    mov cx,80

wlLoop:
    lods byte ptr cs:[si]
    stosw
    loop wlLoop
;
    pop si
    pop cx
    pop ax    
    ret
WriteLine   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCust
;
;           DESCRIPTION:    Write a custom line
;
;       PARAMETERS:     SI      Offset to dir entry
;               ES:DI   Screen buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cust_bl    DB '                    บ  RDOS - ', 0
cust_el    DB 'บ                   ', 0
cust_ext   DB '.BIN boot', 0

WriteCust   Proc near
    push cx
    push si
;
    mov ah,7
    mov cx,80

    push si
    mov si,OFFSET cust_bl

wcBeginLoop:
    lods byte ptr cs:[si]
    or al,al
    jz wcBeginDone
;    
    stosw
    loop wcBeginLoop
    
wcBeginDone:
    pop si
;
    mov cx,30

wcNameLoop:
    lods byte ptr cs:[si]
    cmp al,' '
    je wcNameDone
;
    stosw
    loop wcNameLoop        

wcNameDone:
    mov si,OFFSET cust_ext

wcExtLoop:
    lods byte ptr cs:[si]
    or al,al
    je wcExtDone
;
    stosw
    loop wcExtLoop
    jmp wcAddEnd

wcExtDone:
    mov al,' '

wcPadLoop:
    stosw
    loop wcPadLoop

wcAddEnd:
    mov si,OFFSET cust_el

wcAddLoop:
    lods byte ptr cs:[si]
    or al,al
    je wcDone
;
    stosw
    jmp wcAddLoop 

wcDone:   
    pop si
    pop cx    
    ret
WriteCust   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteMenu
;
;           DESCRIPTION:    Write boot-menu
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


blank_line DB '                                                                                  '
l1         DB '                                  RDOS Bootloader                                 '
l2         DB '                    ษอออออออออออออออออออออออออออออออออออออออป                     '
l4         DB '                    ศอออออออออออออออออออออออออออออออออออออออผ                     '
org_line   DB '                    บ  Boot original Operating system       บ                     '
norm_line  DB '                    บ  RDOS - normal boot                   บ                     '
safe_line  DB '                    บ  RDOS - safe mode boot                บ                     '

norm_file   DB 'RDOS    '
safe_file   DB 'SAFE    '
                  
WriteMenu  Proc near
    push es
    pushad
;    
    mov ax,0B800h
    mov es,ax
    xor di,di
    mov si,OFFSET l1
    call WriteLine
    mov si,OFFSET l2
    call WriteLine
    mov cx,22
;
    mov bx,OFFSET MenuArr
    mov cs:MenuEntries,0
    mov al,cs:BootMedia
    cmp al,0F0h
    jne wmOrgDone
;    
    mov cs:MenuEntries,1
    dec cx
    mov si,OFFSET org_line
    call WriteLine
    mov word ptr cs:[bx],0
    add bx,2

wmOrgDone:    
    mov si,OFFSET norm_file
    call FindLine
    jc wmNormOk
;    
    inc cs:MenuEntries
    dec cx
    mov si,OFFSET norm_line
    call WriteLine
    mov cs:[bx],ax
    add bx,2

wmNormOk:
    mov si,OFFSET safe_file
    call FindLine
    jc wmSafeOk
;    
    inc cs:MenuEntries
    dec cx
    mov si,OFFSET safe_line
    call WriteLine    
    mov cs:[bx],ax
    add bx,2

wmSafeOk: 
    mov dx,cs:EntryCount
    mov si,OFFSET EntryArr
    or dx,dx
    jz wmEntryDone

wmEntryLoop:
    mov al,cs:[si]
    or al,al
    jz wmEntryNext
;
    inc cs:MenuEntries
    dec cx
    mov cs:[bx],si
    add bx,2
    call WriteCust

wmEntryNext:
    add si,20h
    sub dx,1
    jnz wmEntryLoop

wmEntryDone:
    mov si,OFFSET l4
    call WriteLine
    mov si,OFFSET blank_line

wbl:
    call WriteLine
    loop wbl
;
    popad
    pop es       
    ret
WriteMenu   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MarkEntry
;
;           DESCRIPTION:    Mark a entry
;
;       PARAMETERS:     AX      Entry #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MarkEntry   Proc near
    push ds
    pusha
;
    add ax,2
    mov dx,2 * 80
    mul dx
    mov bx,ax
    add bx,2 * 22
    mov cx,37
;
    mov ax,0B800h
    mov ds,ax
    inc bx

meLoop:
    mov byte ptr [bx],70h
    add bx,2
    loop meLoop
;    
    popa
    pop ds
    ret
MarkEntry   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnmarkEntry
;
;           DESCRIPTION:    Unmark a entry
;
;       PARAMETERS:     AX      Entry #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnmarkEntry   Proc near
    push ds
    pusha
;
    add ax,2
    mov dx,2 * 80
    mul dx
    mov bx,ax
    add bx,2 * 22
    mov cx,37
;
    mov ax,0B800h
    mov ds,ax
    inc bx

umeLoop:
    mov byte ptr [bx],7
    add bx,2
    loop umeLoop
;    
    popa
    pop ds
    ret
UnmarkEntry   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleMenu
;
;           DESCRIPTION:    Handle menu
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleMenu  Proc near    
    mov cs:Tics, 5 * 17

hmWaitKey:
    mov ah,1
    int 16h
    jnz hmWait
;
    mov eax,cs:Tics
    or eax,eax
    jne hmWaitKey
;
    jmp hmOk
    
hmWait:
    mov ax,0
    int 16h 
    cmp al,0Dh
    je hmOk
;
    cmp ax,4800h
    jne hmNotUp

hmUp:
    mov ax,cs:CurrEntry
    or ax,ax
    jz hmWait
;
    call UnmarkEntry
    dec ax
    call MarkEntry
    mov cs:CurrEntry,ax
    jmp hmWait   

hmNotUp:
    cmp ax,5000h
    jne hmWait

hmDown:
    mov ax,cs:CurrEntry
    inc ax
    cmp ax,cs:MenuEntries
    je hmWait
;
    dec ax
    call UnmarkEntry    
    inc ax
    call MarkEntry
    mov cs:CurrEntry,ax
    jmp hmWait

hmOk: 
    mov si,cs:CurrEntry
    add si,si
    mov si,cs:[si].MenuArr
    or si,si
    jz hmOrgOs
;    
    movzx edx,cs:[si].fat_cluster
    cmp cs:FatSize,32
    jnz hmClustOk
;
    movzx eax,cs:[si].fat_cluster_hi
    shl eax,16
    or edx,eax

hmClustOk:       
    mov cs:CurrentCluster,edx
    mov eax,cs:[si].fat_file_size
    mov cs:ImageSize,eax
    clc
    jmp hmDone

hmOrgOs:
    mov cs:CurrentCluster,0
    mov cs:ImageSize,0
    stc

hmDone:    
    ret
HandleMenu  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClearScreen
;
;           DESCRIPTION:    Clear screen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                  
ClearScreen  Proc near
    push es
    pusha
;    
    mov ax,0B800h
    mov es,ax
    xor di,di
    mov ax,0720h
    mov cx,80 * 25
    rep stosw
;
    mov ax,3
    int 10h
;
    popa
    pop es
    ret
ClearScreen Endp       

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GateA20
;
;           DESCRIPTION:    Enable A20 line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateA20 Proc near
    xor cx,cx

wait_gate1:
    sub cx,1
    jz gate_done
;    
    in al,64h
    and al,2
    jnz wait_gate1
;    
    mov al,0D1h
    out 64h,al
;    
    xor cx,cx

wait_gate2:
    sub cx,1
    jz gate_done
;    
    in al,64h
    and al,2
    jnz wait_gate2
;    
    mov al,0DFh
    out 60h,al
;    
    xor cx,cx

wait_gate3:
    sub cx,1
    jz gate_done
;    
    in al,64h
    and al,2
    jnz wait_gate3
    
    xor cx,cx
gate_wait:
    inc ax
    loop gate_wait

gate_done:
    ret
GateA20 Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitGdt
;
;           DESCRIPTION:    Init protected mode GDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

source_sel      EQU 8
dest_sel    EQU 10h
flat_sel    EQU 18h

LoadGdt:
load_gdt0:
            DW 27h
            DD 0
            DW 0
load_gdt_source:
        DW 0FFFFh
        DD 92000000h
        DW 0
load_gdt_dest:
        DW 0FFFFh
        DD 92300000h
        DW 0
load_gdt_flat:
            DW 0FFFFh
            DD 92000000h
            DW 008Fh
load_gdt_cs:
            DW 0FFFFh
            DD 9A000000h
            DW 0

InitGdt Proc near
    mov ax,cs
    movzx eax,ax
    shl eax,4
    add eax,OFFSET LoadGdt
    mov dword ptr cs:load_gdt0+2,eax
    lgdt fword ptr cs:load_gdt0
;
    mov ax,cs
    movzx eax,ax
    shl eax,4
    or dword ptr cs:load_gdt_cs+2,eax
    ret
InitGdt Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MoveData
;
;           DESCRIPTION:    Move data to extended memory
;
;           PARAMETERS:         ESI         Linear source address
;                           EDI         Linear dest address
;                           ECX         Number of bytes to move
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveData    Proc near
    push ds
    push es
    pushad
;
    mov eax,esi
    mov dword ptr cs:load_gdt_source+2,eax
    mov al,92h
    xchg al,byte ptr cs:load_gdt_source+5
    mov byte ptr cs:load_gdt_source+7,al
;
    mov eax,edi
    mov dword ptr cs:load_gdt_dest+2,eax
    mov al,92h
    xchg al,byte ptr cs:load_gdt_dest+5
    mov byte ptr cs:load_gdt_dest+7,al
    mov word ptr cs:MoveDataRmCs,cs
;
    cli
    mov eax,cr0
    or al,1
    mov cr0,eax
;
    db 0EAh
    dw OFFSET MoveDataPm
    dw 20h

MoveDataPm:
    mov ax,source_sel
    mov ds,ax
    mov ax,dest_sel
    mov es,ax
    xor esi,esi
    xor edi,edi
    rep movs byte ptr es:[edi],[esi]
;
    mov eax,cr0
    and al,NOT 1
    mov cr0,eax
;
    db 0EAh
    dw OFFSET MoveDataRm
MoveDataRmCs:
    dw 0

MoveDataRm:
    sti
    popad
    pop es
    pop ds
    ret
MoveData    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LoadAdapter
;
;           DESCRIPTION:    Load adapter into extended memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadAdapter     Proc near
    push ds
    push esi
;    
    mov ax,cs
    mov es,ax
    mov ax,DATA_SEG
    mov ds,ax

laClusterLoop:
    call GetCurrentSector
    mov cx,cs:SectorsPerCluster    

laSectorLoop:
    xor si,si
    push bx
    push cx
    mov bx,1000h
;
    cmp cx,64
    jbe laSectorsOk
;
    mov cx,64

laSectorsOk:        
    movzx ebp,cx
    call ReadSectors
    pop cx
    pop bx
    jc laError
;
    push edx
    push cx
    mov esi,(16 * DATA_SEG) + 1000h
    mov ecx,ebp
    shl ecx,9
    call MoveData
    add edi,ecx
    sub cs:ImageSize,ecx
    pop cx
    pop edx
    jbe laDone
;
    add edx,ebp
    sub cx,bp
    jnz laSectorLoop
;
    call NextCluster
    jnc laClusterLoop
    jmp laDone
    
laError:
    mov si,OFFSET ReadError
    call WriteAsciiz
    
laDone:
    pop esi
    pop ds
    ret     
LoadAdapter     Endp

LoadAdapterDone DB 'Load adapter done',0

ReadError       db 'Cannot read rdos.bin',0Dh,0Ah,0
InvFatMsg       db 0Dh,0Ah,'Unknown file-system.',0Dh,0Ah,0
LoadMsg     db 0Dh,0Ah,'Loading Rdos operating system',0

InvalidDisc db 'Cannot read disc', 0Dh, 0Ah, 0
InvalidGpt db 'Invalid GPT table', 0Dh, 0Ah, 0
InvalidCrc db 'Invalid GPT CRC', 0Dh, 0Ah, 0
MissingPart db 'No Partition to boot from', 0Dh, 0Ah, 0
InvalidFs db 'Unknown filesystem', 0Dh, 0Ah, 0
BootNotFound db 'Cannot find boot image', 0Dh, 0Ah, 0

read_part_error:
    mov si,OFFSET InvalidDisc
    call WriteAsciiz
    jmp part_stop

read_gpt_error:
    mov si,OFFSET InvalidGpt
    call WriteAsciiz
    jmp part_stop

read_crc_error:
    mov si,OFFSET InvalidCrc
    call WriteAsciiz
    jmp part_stop

missing_part_error:
    mov si,OFFSET MissingPart
    call WriteAsciiz
    jmp part_stop

fs_error:
    mov si,OFFSET InvalidFs
    call WriteAsciiz
    jmp part_stop

part_stop:
    jmp part_stop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CalcCrc32
;
;       DESCRIPTION:    Calculate CRC32
;
;       PARAMETERS:     EAX         CRC in
;                       ES:EDI      Data
;                       ECX         Size
;
;       RETURNS:        EAX         CRC out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crc32_tab: 
  DD 000000000h, 077073096h, 0ee0e612ch, 0990951bah, 0076dc419h, 0706af48fh
  DD 0e963a535h, 09e6495a3h, 00edb8832h, 079dcb8a4h, 0e0d5e91eh, 097d2d988h
  DD 009b64c2bh, 07eb17cbdh, 0e7b82d07h, 090bf1d91h, 01db71064h, 06ab020f2h
  DD 0f3b97148h, 084be41deh, 01adad47dh, 06ddde4ebh, 0f4d4b551h, 083d385c7h
  DD 0136c9856h, 0646ba8c0h, 0fd62f97ah, 08a65c9ech, 014015c4fh, 063066cd9h
  DD 0fa0f3d63h, 08d080df5h, 03b6e20c8h, 04c69105eh, 0d56041e4h, 0a2677172h
  DD 03c03e4d1h, 04b04d447h, 0d20d85fdh, 0a50ab56bh, 035b5a8fah, 042b2986ch
  DD 0dbbbc9d6h, 0acbcf940h, 032d86ce3h, 045df5c75h, 0dcd60dcfh, 0abd13d59h
  DD 026d930ach, 051de003ah, 0c8d75180h, 0bfd06116h, 021b4f4b5h, 056b3c423h
  DD 0cfba9599h, 0b8bda50fh, 02802b89eh, 05f058808h, 0c60cd9b2h, 0b10be924h
  DD 02f6f7c87h, 058684c11h, 0c1611dabh, 0b6662d3dh, 076dc4190h, 001db7106h
  DD 098d220bch, 0efd5102ah, 071b18589h, 006b6b51fh, 09fbfe4a5h, 0e8b8d433h
  DD 07807c9a2h, 00f00f934h, 09609a88eh, 0e10e9818h, 07f6a0dbbh, 0086d3d2dh
  DD 091646c97h, 0e6635c01h, 06b6b51f4h, 01c6c6162h, 0856530d8h, 0f262004eh
  DD 06c0695edh, 01b01a57bh, 08208f4c1h, 0f50fc457h, 065b0d9c6h, 012b7e950h
  DD 08bbeb8eah, 0fcb9887ch, 062dd1ddfh, 015da2d49h, 08cd37cf3h, 0fbd44c65h
  DD 04db26158h, 03ab551ceh, 0a3bc0074h, 0d4bb30e2h, 04adfa541h, 03dd895d7h
  DD 0a4d1c46dh, 0d3d6f4fbh, 04369e96ah, 0346ed9fch, 0ad678846h, 0da60b8d0h
  DD 044042d73h, 033031de5h, 0aa0a4c5fh, 0dd0d7cc9h, 05005713ch, 0270241aah
  DD 0be0b1010h, 0c90c2086h, 05768b525h, 0206f85b3h, 0b966d409h, 0ce61e49fh
  DD 05edef90eh, 029d9c998h, 0b0d09822h, 0c7d7a8b4h, 059b33d17h, 02eb40d81h
  DD 0b7bd5c3bh, 0c0ba6cadh, 0edb88320h, 09abfb3b6h, 003b6e20ch, 074b1d29ah
  DD 0ead54739h, 09dd277afh, 004db2615h, 073dc1683h, 0e3630b12h, 094643b84h
  DD 00d6d6a3eh, 07a6a5aa8h, 0e40ecf0bh, 09309ff9dh, 00a00ae27h, 07d079eb1h
  DD 0f00f9344h, 08708a3d2h, 01e01f268h, 06906c2feh, 0f762575dh, 0806567cbh
  DD 0196c3671h, 06e6b06e7h, 0fed41b76h, 089d32be0h, 010da7a5ah, 067dd4acch
  DD 0f9b9df6fh, 08ebeeff9h, 017b7be43h, 060b08ed5h, 0d6d6a3e8h, 0a1d1937eh
  DD 038d8c2c4h, 04fdff252h, 0d1bb67f1h, 0a6bc5767h, 03fb506ddh, 048b2364bh
  DD 0d80d2bdah, 0af0a1b4ch, 036034af6h, 041047a60h, 0df60efc3h, 0a867df55h
  DD 0316e8eefh, 04669be79h, 0cb61b38ch, 0bc66831ah, 0256fd2a0h, 05268e236h
  DD 0cc0c7795h, 0bb0b4703h, 0220216b9h, 05505262fh, 0c5ba3bbeh, 0b2bd0b28h
  DD 02bb45a92h, 05cb36a04h, 0c2d7ffa7h, 0b5d0cf31h, 02cd99e8bh, 05bdeae1dh
  DD 09b64c2b0h, 0ec63f226h, 0756aa39ch, 0026d930ah, 09c0906a9h, 0eb0e363fh
  DD 072076785h, 005005713h, 095bf4a82h, 0e2b87a14h, 07bb12baeh, 00cb61b38h
  DD 092d28e9bh, 0e5d5be0dh, 07cdcefb7h, 00bdbdf21h, 086d3d2d4h, 0f1d4e242h
  DD 068ddb3f8h, 01fda836eh, 081be16cdh, 0f6b9265bh, 06fb077e1h, 018b74777h
  DD 088085ae6h, 0ff0f6a70h, 066063bcah, 011010b5ch, 08f659effh, 0f862ae69h
  DD 0616bffd3h, 0166ccf45h, 0a00ae278h, 0d70dd2eeh, 04e048354h, 03903b3c2h
  DD 0a7672661h, 0d06016f7h, 04969474dh, 03e6e77dbh, 0aed16a4ah, 0d9d65adch
  DD 040df0b66h, 037d83bf0h, 0a9bcae53h, 0debb9ec5h, 047b2cf7fh, 030b5ffe9h
  DD 0bdbdf21ch, 0cabac28ah, 053b39330h, 024b4a3a6h, 0bad03605h, 0cdd70693h
  DD 054de5729h, 023d967bfh, 0b3667a2eh, 0c4614ab8h, 05d681b02h, 02a6f2b94h
  DD 0b40bbe37h, 0c30c8ea1h, 05a05df1bh, 02d02ef8dh

CalcCrc32 Proc near
    push ebx
    push ecx
    push edx
    push edi
;    
    or ecx,ecx
    jz ccDone32

ccLoop32:
    mov bl,es:[edi]
    inc edi
    xor bl,al
    movzx bx,bl
    shl bx,2
    mov edx,dword ptr cs:[bx].crc32_tab
    shr eax,8
    xor eax,edx
    sub ecx,1
    jnz ccLoop32
    
ccDone32:    
    mov edx,-1
    xor eax,edx
;
    pop edi
    pop edx
    pop ecx
    pop ebx    
    ret
CalcCrc32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;           DESCRIPTION:    Second stage boot-loader entry point
;
;           RETURNS:        DL      Bios disc #
;               AL      Default boot #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public Start

ok_text  DB 'GPT loaded..', 0Dh, 0Ah, 0     
    
Start:
    mov cs:DefaultBoot,al
    call GetMemMap    
    call SetupVectors
    sti
    mov cs:DriveNr,dl
;
    mov ax,DATA_SEG
    mov ds,ax
    xor bx,bx
    mov edx,1
    mov cx,21h

read_gpt_loop:
    call ReadSector
    jc read_part_error
;
    inc edx
    add bx,200h
;    
    loop read_gpt_loop
;
    mov ax,DATA_SEG
    mov es,ax
    mov eax,dword ptr es:gpt_sign
    cmp eax,20494645h
    jne read_gpt_error
;
    mov eax,dword ptr es:gpt_sign+4
    cmp eax,54524150h
    jne read_gpt_error
;
    xor edx,edx
    xchg edx,es:gpt_crc32
    mov ecx,es:gpt_header_size
    cmp ecx,200h
    jae read_gpt_error
;    
    mov eax,-1
    xor edi,edi
    call CalcCrc32
    cmp eax,edx
    jne read_crc_error
;    
    mov eax,es:gpt_entry_size
    cmp eax,128
    jne read_gpt_error
;
    mov eax,es:gpt_entry_lba+4
    or eax,eax
    jnz read_gpt_error
;
    mov ecx,es:gpt_entry_count
    shl ecx,7
    mov edi,200h
    mov eax,-1
    call CalcCrc32
;
    cmp eax,es:gpt_entry_crc32
    jne read_gpt_error
;
    mov ecx,es:gpt_entry_count
    mov edi,200h

find_data_part_loop:
    mov eax,dword ptr es:[di].gpe_part_guid
    cmp eax,0EBD0A0A2h
    jne find_data_part_next
;
    mov eax,dword ptr es:[di].gpe_part_guid+4
    cmp eax,4433B9E5h
    jne find_data_part_next
;    
    mov eax,dword ptr es:[di].gpe_part_guid+8
    cmp eax,0B668C087h
    jne find_data_part_next
;    
    mov eax,dword ptr es:[di].gpe_part_guid+12
    cmp eax,0C79926B7h
    je find_data_part_ok

find_data_part_next:
    add di,128 
    loop find_data_part_loop
;
    jmp missing_part_error

find_data_part_ok:
    mov edx,es:[di].gpe_first_lba
    mov cs:BootSector,edx
    xor bx,bx
    call ReadSector
    jc read_part_error
;
    mov bx,OFFSET FsName
    xor si,si
    mov al,ds:[si+3]
    cmp al,'M'
    je find_type_dos
;
    cmp al,'m'
    je find_type_linux
;
    cmp al,'R'
    je find_type_linux
;
    add si,3
    jmp find_copy_fs_name

find_type_linux:
    add si,36h
    jmp find_copy_fs_name

find_type_dos:
    add si,52h

find_copy_fs_name:
    mov cx,8

find_copy_name_loop:    
    mov al,ds:[si]
    or al,al
    jz find_copy_name_done
;
    cmp al,' '
    jz find_copy_name_done
;
    mov cs:[bx],al
    inc bx
    inc si
    loop find_copy_name_loop

find_copy_name_done:
    xor al,al
    mov cs:[bx],al
;
    mov si,OFFSET FsName
    mov al,cs:[si]
    cmp al,'F'
    jne fs_error
;
    inc si
    mov al,cs:[si]
    cmp al,'A'
    jne fs_error
;
    inc si
    mov al,cs:[si]
    cmp al,'T'
    jne fs_error
;
    inc si
    mov al,cs:[si]
    cmp al,'3'
    je possible_fat32
;
    cmp al,'1'
    jne fs_error
;
    inc si
    mov al,cs:[si]
    cmp al,'2'
    je fs_fat12
;
    cmp al,'6'
    jne fs_error

fs_fat16:
    mov al,16
    jmp save_fs

fs_fat12:
    mov al,12
    jmp save_fs

possible_fat32:
    inc si
    mov al,cs:[si]
    cmp al,'2'
    jne fs_error

fs_fat32:
    mov al,32

save_fs:
    mov cs:FatSize,al     ; calc this one
;
    mov al,ds:boot_media
    mov cs:BootMedia,al
;    
    movzx eax,ds:boot_resv_sectors
    add eax,cs:BootSector
    mov cs:FatSector,eax
;
    movzx eax,ds:boot_fat_sectors16
    or ax,ax
    jnz boot_fat_sectors_ok
;
    mov eax,ds:boot_fat_sectors

boot_fat_sectors_ok:
    mov cs:SectorsPerFat,eax
    mov eax,cs:FatSector
;
    mov cl,ds:boot_fats
    or cl,cl
    jz read_part_error

boot_fat_adv_loop:
    add eax,cs:SectorsPerFat
    sub ds:boot_fats,1
    jnz boot_fat_adv_loop
;
    cmp cs:FatSize,32
    je boot_data_sector_ok
;
    mov cs:RootSector,eax
    movzx ecx,ds:boot_root_dirs
    shr ecx,4
    add eax,ecx

boot_data_sector_ok:    
    mov cs:DataSector,eax
    mov eax,ds:boot_root_cluster
    mov cs:CurrentCluster,eax
    mov ax,ds:boot_root_dirs
    mov cs:RootEntries,ax
    movzx ax,ds:boot_sectors_per_cluster
    mov cs:SectorsPerCluster,ax
    mov cs:EntryCount,0
    call FindRdosFiles
    call WriteMenu
;
    movzx ax,cs:DefaultBoot
    cmp ax,cs:MenuEntries
    jb LoadDefaultOk
;
    xor ax,ax

LoadDefaultOk:
    mov cs:CurrEntry,ax
    call MarkEntry
    call HandleMenu       
    jnc LoadStart
;    
    call ClearScreen
    xor ax,ax
    mov ds,ax
;    
    xor edx,edx
    mov bx,600h
    call ReadSector
;    
    mov edx,cs:BootSector
    mov bx,7C00h
    call ReadSector
;
    mov bx,8 SHL 2
    mov eax,cs:OrgTimerVect
    mov [bx],eax
;
    mov si,600h + 1BEh    
    db 0EAh
    dw 7C00h
    dw 0
    
LoadStart:
    call ClearScreen
    mov si,OFFSET LoadMsg
    call WriteAsciiz
    call GateA20
    call InitGdt
    mov edi,IMAGE_BASE
    mov ecx,cs:ImageSize
    dec ecx
    and cx,0F000h
    add ecx,1000h
    push edi
    push ecx
    call LoadAdapter
    mov dx,3F2h
    mov al,0
    out dx,al
    pop ecx
    pop edi
    jmp init

stop:
    jmp stop

;pad db 308 DUP(0)

_TEXT   ends    

    END Start
