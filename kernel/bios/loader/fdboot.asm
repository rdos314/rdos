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
; Second stage boot-loader for FAT12 floppy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                
                NAME  FatBoot

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.model Small

DATA_SEG = 6000h
MAX_IMAGES = 20

IMAGE_BASE = 121000h

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

ReadCount               DW 0
RdosSectors                 DW 0,0
DriveNr                     DB 0
DefaultBoot         DB 0
BootSector          DD 0
FatSector           DD 0
RootSector          DD 0
DataSector          DD 0
SectorsPerFat       DD 0
CurrentCluster      DD 0
RootEntries         DW 0
SafeBoot            DB 0
SectorsPerCluster   DW 0
ImageSize           DD 0
CurrFatSector       DD 0

Tics                DD ?

OrgTimerVect        DD ?

DiscCyls            DW 1
DiscHeads           DW 1
SectorsPerCyl       DW 1

CurrEntry           DW ?
MenuEntries         DW 0
MenuArr             DW MAX_IMAGES DUP(0)
EntryCount          DW 0
EntryArr            DB MAX_IMAGES * 32 DUP(0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   singel_hex
;
;               DESCRIPTION:    
;
;               PARAMETERS:             AL              Value
;                                               AX              Result
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
;               NAME:                   WriteHexByte
;
;               DESCRIPTION:    Write hex byte on screen
;
;               PARAMETERS:             AL              Value
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
;               NAME:                   WriteHexWord
;
;               DESCRIPTION:    Write hex word on screen
;
;               PARAMETERS:             AX              Value
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
;               NAME:                   WriteAsciiz
;
;               DESCRIPTION:    Write text to screen
;
;               PARAMETERS:             CS:SI           Message to write
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
;               NAME:                   TimerInt
;
;               DESCRIPTION:    TIMER INTERRUPT
;
;               PARAMETERS:             
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
;               NAME:                   ReadSector
;
;               DESCRIPTION:    Read a sector
;
;               PARAMETERS:             EDX             Sector #
;                                               DS:BX   Address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector      Proc near
    push cx
    mov cx,3    

rsLoop:    
    push es
        push ax
        push bx
        push cx
        push edx
;       
    mov ax,ds
    mov es,ax
    push edx
    pop ax
    pop dx
        push bx
        div cs:SectorsPerCyl
        inc dl
        mov bl,dl
        xor dx,dx
        div cs:DiscHeads
        mov bh,dl
        mov dx,ax
        mov ax,201h
        mov cl,6
        shl dh,cl
        or dh,bl
        mov cx,dx
        xchg ch,cl
        mov dl,cs:DriveNr
        mov dh,bh
        pop bx
        int 13h
;       
        pop edx
        pop cx
        pop bx
        pop ax
        pop es
        jnc rsDone
;
        push ax
        push dx
        xor ax,ax
        mov dl,cs:DriveNr
        int 13h
        pop dx
        pop ax
    loop rsLoop
;
    stc
    
rsDone:
    pop cx
        ret
ReadSector      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ReadFatSector
;
;               DESCRIPTION:    Read fat sector
;
;               PARAMETERS:             EDX             Sector #
;                                               DS:200  Address of buffer
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
;               NAME:                   InitIrq
;
;               DESCRIPTION:    Init IRQs
;
;               PARAMETERS:             DS:BX       Sector 0 buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitIrq Proc near
    push ds
    push es
    push bx
;    
    mov ax,ds
    mov es,ax
    mov di,bx
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
    pop es
    pop ds
    ret
InitIrq Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   NextCluster
;
;               DESCRIPTION:    Find next cluster for FAT12
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NextCluster     PROC near
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
        jnc ncLocked
        popf
        stc
        jmp ncDone

ncLocked:
        mov bx,cx
        add bx,200h
        popf
        jc ncHigh
        mov cl,[bx]
        inc bx
        test bx,1FFh
        jnz ncLowOk
        inc edx
        mov bx,200h
        call ReadFatSector
        jc ncDone

ncLowOk:
        mov ch,[bx]
        and cx,0FFFh
        jmp ncOk

ncHigh:
        mov ch,[bx]
        and ch,0F0h
        inc bx
        test bx,1FFh
        jnz ncHighOk
        inc edx
        mov bx,200h
        call ReadFatSector
        jc ncDone

ncHighOk:
        mov cl,[bx]
        rol cx,4
ncOk:
        movzx edx,cx
        mov cs:CurrentCluster,edx
        cmp edx,0FF8h
        cmc

ncDone:
        pop cx
        pop ebx
        ret
NextCluster     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetCurrentSector
;
;               DESCRIPTION:    Get current sector
;
;       RETURNS:        EDX     Sector
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
GetCurrentSector        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CheckDirEntry
;
;               DESCRIPTION:    Check a directory entry for a RDOS image file
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
;               NAME:                   ScanRootDir
;
;               DESCRIPTION:    Scan root directory
;
;       PARAMETERS:     DI          File to scan for
;
;       RETURNS:        EDX         Start cluster # of file
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
;               NAME:                   FindLine
;
;               DESCRIPTION:    Find a specific line
;
;       PARAMETERS:     SI      Filename
;
;       RETURNS:        AX      Entry offset
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
;               NAME:                   WriteLine
;
;               DESCRIPTION:    Write one full line
;
;       PARAMETERS:     SI      Offset to text
;                       ES:DI   Screen buffer
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
;               NAME:                   WriteCust
;
;               DESCRIPTION:    Write a custom line
;
;       PARAMETERS:     SI      Offset to dir entry
;                       ES:DI   Screen buffer
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
;               NAME:                   WriteMenu
;
;               DESCRIPTION:    Write boot-menu
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

blank_line DB '                                                                                  '
l1         DB '                                  RDOS Bootloader                                 '
l2         DB '                    ษอออออออออออออออออออออออออออออออออออออออป                     '
l4         DB '                    ศอออออออออออออออออออออออออออออออออออออออผ                     '
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
    mov cs:MenuEntries,0
    mov bx,OFFSET MenuArr
;
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
;               NAME:                   MarkEntry
;
;               DESCRIPTION:    Mark a entry
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
;               NAME:                   UnmarkEntry
;
;               DESCRIPTION:    Unmark a entry
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
;               NAME:                   HandleMenu
;
;               DESCRIPTION:    Handle menu
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleMenu  Proc near    
    mov cs:Tics, 5 * 17
    movzx ax,cs:DefaultBoot
    mov cs:CurrEntry,ax

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
    dec si
    add si,si
    mov si,cs:[si].MenuArr
    movzx edx,cs:[si].fat_cluster
    mov cs:CurrentCluster,edx
    mov eax,cs:[si].fat_file_size
    mov cs:ImageSize,eax
    clc
    ret
HandleMenu  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ClearScreen
;
;               DESCRIPTION:    Clear screen
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
;               NAME:                   InitGdt
;
;               DESCRIPTION:    Init protected mode GDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

source_sel      EQU 8
dest_sel        EQU 10h
flat_sel        EQU 18h

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
;               NAME:                   MoveData
;
;               DESCRIPTION:    Move data to extended memory
;
;               PARAMETERS:             ESI             Linear source address
;                                               EDI             Linear dest address
;                                               ECX             Number of bytes to move
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveData        Proc near
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
MoveData        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   LoadAdapter
;
;               DESCRIPTION:    Load adapter into extended memory
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
    xor bx,bx
    call ReadSector
    pop bx
    jc laError
;
    push edx
    push cx
        mov esi,16 * DATA_SEG
    mov ecx,512
        call MoveData
        add edi,ecx
        pop cx
        pop edx
;
    sub cs:ImageSize,200h
    jbe laDone
;
    inc edx
    loop laSectorLoop
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
LoadMsg         db 0Dh,0Ah,'Loading Rdos operating system',0

InvalidDisc db 'Cannot read floppy disc', 0Dh, 0Ah, 0
BootNotFound db 'Cannot find boot image', 0Dh, 0Ah, 0
BootNoEntries db 'No image file', 0Dh, 0Ah, 0

boot_no_entry:
    mov si,OFFSET BootNoEntries
    call WriteAsciiz
    jmp part_stop

read_part_error:
    mov si,OFFSET InvalidDisc
    call WriteAsciiz

part_stop:
    jmp part_stop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;               DESCRIPTION:    Second stage boot-loader entry point
;
;               RETURNS:            DL          Bios disc #
;                       AL          Default boot #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public Start

Start:
    mov cs:DefaultBoot,al
    call GetMemMap
    sti
    mov cs:DriveNr,dl
    mov ax,DATA_SEG
    mov ds,ax
    xor bx,bx
    call InitIrq
    jc read_part_error
;    
    xor edx,edx
    mov cs:BootSector,edx
    xor bx,bx
    call ReadSector
        jc read_part_error
;    
    mov ax,ds:boot_sectors_per_cyl
    mov cs:SectorsPerCyl,ax
    mov ax,ds:boot_heads
    mov cs:DiscHeads,ax
    mov cs:DiscCyls,80
;    
    movzx eax,ds:boot_resv_sectors
    add eax,cs:BootSector
    mov cs:FatSector,eax
;
    movzx eax,ds:boot_fat_sectors16
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
    mov cs:RootSector,eax
    movzx ecx,ds:boot_root_dirs
    shr ecx,4
    add eax,ecx
;
    mov cs:DataSector,eax
    mov eax,ds:boot_root_cluster
    mov cs:CurrentCluster,eax
    mov ax,ds:boot_root_dirs
    mov cs:RootEntries,ax
    movzx ax,ds:boot_sectors_per_cluster
    mov cs:SectorsPerCluster,ax
    mov cs:EntryCount,0
    call ScanRootDir
    mov ax,cs:EntryCount
    or ax,ax
    jz boot_no_entry
;    
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

_TEXT   ends    

    END Start
