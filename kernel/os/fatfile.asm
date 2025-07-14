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
; FATFILE.ASM
; File handling for FAT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\fs.inc
INCLUDE fat.inc

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

        extrn allocate_cluster:near
        extrn link_cluster:near
        extrn free_cluster:near
        extrn eof_cluster:near
        extrn next_cluster:near

        .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GROW_FILE
;
;               DESCRIPTION:    Increase file size
;
;               PARAMETERS:             FS              File selector
;                                               ESI             Current size of file
;                                               EDI             Wanted size of file
;                                               EBP             Cluster size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

grow_file       Proc near
        push eax
        push ebx
        push ecx
        push edx
;
        push esi
        or esi,esi
        jne grow_file_do
;
        mov al,ds:drive_nr
        call allocate_cluster
        jc grow_file_fail
;
        push edx
        mov bx,fs
        xor edx,edx
        GetFileListEntry
        pop edx
;
        mov es:[eax].ffl_clusters,edx
        mov ecx,fs:file_dir_entry
        mov es:[ecx].ffe_start_cluster,edx
        add esi,ebp
        cmp esi,edi
        clc
        je grow_file_cluster_done

grow_file_do:
        sub esi,ebp
        sub edi,ebp
        push edx
        mov bx,fs
        mov edx,esi
        GetFileListEntry
        pop edx
;
        lea ebx,[eax].ffl_clusters
        mov ecx,esi
        mov eax,fs:file_block_size
        dec eax
        and eax,ecx
        mov cl,ds:fat_cluster_shift
        add cl,9
        shr eax,cl
        shl eax,2
        add ebx,eax
        
grow_file_loop:
        mov al,ds:drive_nr
        call allocate_cluster
        jc grow_file_fail
;
        mov ecx,edx
        mov edx,es:[ebx]
        call link_cluster
        add ebx,4
        mov es:[ebx],ecx
        add esi,ebp
        cmp esi,edi
        clc
        je grow_file_cluster_done
;
        mov eax,fs:file_block_size
        dec eax
        and eax,esi
        jnz grow_file_loop
;
        mov edx,es:[ebx]
        push edx
        mov bx,fs
        mov edx,esi
        GetFileListEntry
        pop edx
        lea ebx,[eax].ffl_clusters
        mov es:[ebx],edx
        jmp grow_file_loop

grow_file_cluster_done:
        mov eax,fs:file_block_size
        dec eax
        and eax,esi
        jnz grow_file_lock
;
        mov edx,es:[ebx]
        push edx
        mov bx,fs
        mov edx,esi
        GetFileListEntry
        pop edx
        lea ebx,[eax].ffl_clusters
        mov es:[ebx],edx

grow_file_lock:
        pop esi
        mov ebx,esi

grow_list_loop:
        cmp ebx,fs:file_size
        jae grow_file_done
;
        push bx
        push edx
        mov edx,ebx
        mov bx,fs
        GetFileListEntry
        pop edx
        pop bx
        mov edi,eax
;
        lea ebp,[eax].ffl_clusters
        mov eax,fs:file_block_size
        dec eax
        and eax,ebx
        mov cl,ds:fat_cluster_shift
        add cl,9
        shr eax,cl
        shl eax,2
        add ebp,eax
;
        mov esi,es:[edi].fl_base
        or esi,esi
        jnz grow_lock_valid
;
        push edx
        mov eax,fs:file_block_size
        AllocateBigLinear
        mov esi,edx
        pop edx
        mov es:[edi].fl_base,esi

grow_lock_valid:
        mov eax,fs:file_block_size
        dec eax
        and eax,ebx
        add esi,eax
;
        mov edi,es:[edi].ffl_sector_ptr
        shr eax,9
        shl eax,2
        add edi,eax

grow_lock_loop:
        cmp ebx,fs:file_size
        jae grow_file_done
;
        mov edx,es:[ebp]
        sub edx,2
        mov eax,1
        mov cl,ds:fat_cluster_shift
        shl edx,cl
        shl eax,cl
        mov ecx,eax
        add edx,ds:start_sector

grow_cluster_loop:
        push ebx
        mov ebx,es:[edi]
        cmp ebx,-1
        je grow_define_sector
;
        or ebx,ebx
        jnz grow_cluster_next

grow_define_sector:
        mov al,ds:drive_nr
        DefineSector
        mov es:[edi],ebx

grow_cluster_next:
        pop ebx
        add edi,4
        inc edx
        add esi,200h
        add ebx,200h
        loop grow_cluster_loop
;
        add ebp,4
        mov eax,fs:file_block_size
        dec eax
        and eax,ebx
        jnz grow_lock_loop
        jmp grow_list_loop

grow_file_fail:
        pop esi

grow_file_done:
        pop edx
        pop ecx
        pop ebx
        pop eax
        ret
grow_file       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   SHRINK_FILE
;
;               DESCRIPTION:    Decrease size of file
;
;               PARAMETERS:             FS              File selector
;                                               ESI             Current file size
;                                               EDI             Wanted file size
;                                               EBP             Cluster size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

shrink_file     Proc near
        push eax
        push ebx
        push ecx
        push edx
;
        push esi
        push edi
        
shrink_file_unlock:
        mov ebx,edi

shrink_list_loop:
        cmp ebx,esi
        jae shrink_file_free
;
        push bx
        push edx
        mov edx,ebx
        mov bx,fs
        GetFileListEntry
        pop edx
        pop bx
        mov edi,eax
;
        mov edi,es:[edi].ffl_sector_ptr
        mov eax,fs:file_block_size
        dec eax
        and eax,ebx
        shr eax,9
        add edi,eax

shrink_unlock_loop:
        cmp ebx,esi
        je shrink_file_free
;
        mov eax,1
        mov cl,ds:fat_cluster_shift
        shl eax,cl
        mov ecx,eax

shrink_cluster_loop:
        push ebx
        mov ebx,es:[edi]
        cmp ebx,-1
        je shrink_cluster_next
;
        or ebx,ebx
        jz shrink_cluster_next
;
        UnlockSector

shrink_cluster_next:
        mov dword ptr es:[edi],0
        pop ebx
        add edi,4
        inc edx
        add ebx,200h
        loop shrink_cluster_loop
;
        mov eax,fs:file_block_size
        dec eax
        and eax,ebx
        jnz shrink_unlock_loop
        jmp shrink_list_loop

shrink_file_free:
        pop edi
        pop esi
        sub esi,ebp

shrink_file_list_loop:
        mov bx,fs
        mov edx,esi
        GetFileListEntry
;
        lea ebx,[eax].ffl_clusters
        mov eax,fs:file_block_size
        dec eax
        and eax,esi
        mov cl,ds:fat_cluster_shift
        add cl,9
        shr eax,cl
        shl eax,2
        add ebx,eax
        
shrink_file_loop:
        mov edx,es:[ebx]
        mov al,ds:drive_nr
        call free_cluster
        mov dword ptr es:[ebx],0
;
        mov eax,fs:file_block_size
        dec eax
        and eax,esi
        sub ebx,4
        sub esi,ebp
        jc shrink_file_zero
;
        cmp esi,edi
        jc shrink_file_mark_end
;
        or eax,eax
        jnz shrink_file_loop
;
        mov edx,esi
        add edx,ebp
        mov bx,fs
        push edi
        GetFileListEntry
        mov edi,eax
        FreeFileListEntry
        pop edi
        jmp shrink_file_list_loop

shrink_file_mark_end:
        or eax,eax
        jnz shrink_mark_do
;
        mov edx,esi
        add edx,ebp
        mov bx,fs
        push edi
        GetFileListEntry
        mov edi,eax
        FreeFileListEntry
        pop edi
;
        mov bx,fs
        mov edx,esi
        GetFileListEntry
;
        lea ebx,[eax].ffl_clusters
        mov eax,fs:file_block_size
        dec eax
        and eax,esi
        mov cl,ds:fat_cluster_shift
        add cl,9
        shr eax,cl
        shl eax,2
        add ebx,eax

shrink_mark_do:
        mov edx,es:[ebx]
        mov al,ds:drive_nr
        call eof_cluster
        jmp shrink_file_done

shrink_file_zero:
        push edi
        xor edx,edx
        mov bx,fs
        GetFileListEntry
        mov edi,eax
        FreeFileListEntry
        pop edi
        mov eax,fs:file_dir_entry
        mov es:[eax].ffe_start_cluster,0

shrink_file_done:
        pop edx
        pop ecx
        pop ebx
        pop eax
        ret
shrink_file     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   UPDATE_FILE_CLUSTERS
;
;               DESCRIPTION:    Update number of clusters in file
;
;               PARAMETERS:             FS              File selector
;                                               ECX             New file size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_file_clusters    PROC near
        push eax
        push edx
        push esi
        push edi
        push ebp
;
        push ecx
        mov edi,fs:file_dir_entry
        mov esi,es:[edi].dfe_data_size
        mov edi,ecx
        mov eax,200h
        mov cl,ds:fat_cluster_shift
        shl eax,cl
        mov ebp,eax
        neg eax
        dec esi
        and esi,eax
        dec edi
        and edi,eax
        add esi,ebp
        add edi,ebp
        mov edx,fs:file_size
        or edx,edx
        jz update_file_cluster_ok
;
        mov edx,esi
        sub edx,ebp
        call get_file_cluster
;
        push ebx
        push esi
        push edi
;
        mov bx,fs
        GetFileListEntry
        mov edi,eax
;
        lea esi,[edi].ffl_clusters
        mov eax,fs:file_block_size
        neg eax
        mov ebx,edx
        and ebx,eax
        neg eax
        mov cl,ds:fat_cluster_shift
        add cl,9
        shr eax,cl
        mov ecx,eax

update_req_loop:
        cmp ebx,fs:file_size
        ja update_req_done
;
        mov edx,es:[esi]
        or edx,edx
        jnz update_req_next
;
        mov edx,es:[esi-4]
        mov al,fs:file_drive
        call next_cluster
        mov es:[esi],edx

update_req_next:
        add ebx,ebp
        add esi,4
        loop update_req_loop

update_req_done:
        pop edi
        pop esi
        pop ebx

update_file_cluster_ok:
        pop ecx
        cmp edi,esi
        je update_file_equal
        jc update_file_shrink

update_file_grow:
        mov fs:file_size,ecx
        call grow_file
        jmp update_file_done

update_file_shrink:
        call shrink_file
        mov fs:file_size,ecx
        jmp update_file_done

update_file_equal:
        mov fs:file_size,ecx

update_file_done:
        mov edx,fs:file_dir_entry
        mov es:[edx].dfe_data_size,ecx
        clc
;
        pop ebp
        pop edi
        pop esi
        pop edx
        pop eax
        ret
update_file_clusters    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   get_file_cluster
;
;               DESCRIPTION:    Get cluster of file
;
;               PARAMETERS:             FS                      FILE HANDLE
;                                               EDX                     POSITION
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_file_cluster        Proc near
        pushad
;
        mov ebx,fs:file_block_size
        neg ebx
        and edx,ebx
        mov ebx,edx
        mov ebp,edx
        mov edi,fs:file_dir_entry
        mov edx,es:[edi].ffe_start_cluster
        or ebp,ebp
        jz get_cluster_loop

get_cluster_scan:
        mov edx,es:[edi].ffe_start_cluster
        sub ebp,fs:file_block_size
        jz get_cluster_loop
;
        push bx
        push edx
        mov bx,fs
        mov edx,ebp     
        GetFileListEntry
        pop edx
        pop bx
        mov edx,es:[eax].ffl_clusters
        or edx,edx
        jz get_cluster_scan
;
        lea eax,[eax].ffl_clusters+4
        mov esi,200h
        mov cl,ds:fat_cluster_shift
        shl esi,cl
        mov ecx,edx
        mov edi,fs:file_block_size

advance_cluster_loop:
        mov edx,es:[eax]
        or edx,edx
        jnz advance_cluster_next
;
        mov edx,ecx
        push ax
        mov al,fs:file_drive
        call next_cluster
        pop ax
        mov es:[eax],edx

advance_cluster_next:
        mov ecx,edx
        add eax,4
        sub edi,esi
        jnz advance_cluster_loop
;
        add ebp,fs:file_block_size

get_cluster_loop:
        push bx
        push edx
        mov bx,fs
        mov edx,ebp     
        GetFileListEntry
        pop edx
        pop bx
        mov es:[eax].ffl_clusters,edx

get_cluster_check:
        cmp ebx,ebp
        je get_cluster_done
;
        lea eax,[eax].ffl_clusters+4
        mov esi,200h
        mov cl,ds:fat_cluster_shift
        shl esi,cl
        mov edi,fs:file_block_size

get_file_cluster_loop:
        mov edx,es:[eax]
        or edx,edx
        jnz get_file_cluster_next
;
        mov edx,es:[eax-4]
        push eax
        mov al,fs:file_drive
        call next_cluster
        pop eax
        mov es:[eax],edx

get_file_cluster_next:
        add ebp,esi
        add eax,4
        cmp ebp,fs:file_size
        jnc get_cluster_done
;
        sub edi,esi
        jnz get_file_cluster_loop
;
        jmp get_cluster_loop

get_cluster_done:
        popad
        ret
get_file_cluster        Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   SET_FILE_SIZE
;
;               DESCRIPTION:    Set file size
;
;               PARAMETERS:             BX                      HANDLE
;                                               EDX                     FILE SIZE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public set_file_size

set_file_size   PROC far
        push es
        push fs
        pushad
;
        mov cx,flat_sel
        mov es,cx
        mov fs,bx
        mov ecx,edx
        call update_file_clusters
        jc set_file_size_done
;
        mov al,fs:file_drive
        mov edi,fs:file_dir_entry
        mov edx,es:[edi].ffe_entry_sector
        LockSector
        or si,es:[edi].ffe_entry_offset
        mov eax,es:[edi].ffe_start_cluster
        mov es:[esi].fat_cluster,ax
        shr eax,16
        mov es:[esi].fat_cluster_hi,ax
        mov eax,es:[edi].dfe_data_size
        mov es:[esi].fat_file_size,eax
        ModifySector
        UnlockSector
        clc

set_file_size_done:
        popad
        pop fs
        pop es
        retf32
set_file_size   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ALLOCATE_FILE_LIST
;
;               DESCRIPTION:    Allocate file list block
;
;               PARAMETERS:             BX              File handle
;
;               RETURNS:                EDI             Linear address of file list block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public allocate_file_list

allocate_file_list      PROC far
        push es
        push fs
        push eax
        push ecx
        push edx
;
        mov ax,flat_sel
        mov es,ax
        mov fs,bx
;
        mov cl,fs:file_entry_shift
        sub cl,9
        mov edx,4
        shl edx,cl
        mov eax,4
        sub cl,ds:fat_cluster_shift
        shl eax,cl
        add eax,edx
        add eax,SIZE fat_file_list_struc + 4
        AllocateSmallLinear
        mov edi,edx
;
        mov eax,1
        shl eax,cl
        inc eax
        mov ecx,eax
        xor eax,eax
        push edi
        add edi,OFFSET ffl_clusters
        rep stos dword ptr es:[edi]
        mov edx,edi
        pop edi
;
        mov es:[edi].ffl_sector_ptr,edx
        mov cl,fs:file_entry_shift
        sub cl,9
        mov eax,1
        shl eax,cl
        mov ecx,eax
        xor eax,eax
        push edi
        mov edi,edx
        rep stos dword ptr es:[edi]
        pop edi
;
        pop edx
        pop ecx
        pop eax
        pop fs
        pop es
        retf32
allocate_file_list      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   free_file_list
;
;               DESCRIPTION:    Free file list
;
;               PARAMETERS:             EDI             Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public free_file_list

free_file_list  PROC far
        push es
        push fs
        push eax
        push ebx
        push ecx
        push edx
;
        mov ax,flat_sel
        mov es,ax
        mov fs,bx
;
        mov edx,es:[edi].ffl_sector_ptr
        mov cl,fs:file_entry_shift
        sub cl,9
        mov eax,1
        shl eax,cl
        mov ecx,eax

file_list_flush_loop:
        mov ebx,es:[edx]
        cmp ebx,-1
        je file_list_flush_next
;
        or ebx,ebx
        jz file_list_flush_next 
;
        FlushSector

file_list_flush_next:
        add edx,4
        loop file_list_flush_loop
;
        mov edx,es:[edi].ffl_sector_ptr
        mov cl,fs:file_entry_shift
        sub cl,9
        mov eax,1
        shl eax,cl
        mov ecx,eax

file_list_unlock_loop:
        mov ebx,es:[edx]
        cmp ebx,-1
        je file_list_unlock_next
;
        or ebx,ebx
        jz file_list_unlock_next 
;
        WaitForSector
        UnlockSector

file_list_unlock_next:
        add edx,4
        loop file_list_unlock_loop
;
        mov ecx,edx
        mov edx,edi
        FreeLinear
;
        pop edx
        pop ecx
        pop ebx
        pop eax
        pop fs
        pop es
        clc
        retf32
free_file_list  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   READ_FILE_BLOCK
;
;               DESCRIPTION:    Read file block
;
;               PARAMETERS:             BX                      FILE HANDLE
;                                               ECX                     BYTES TO READ
;                                               EDX                     POSITION
;                                               EDI                     FILE LIST
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public read_file_block

read_file_block PROC far
        push es
        push fs
        pushad
;
        mov fs,bx
        mov ax,flat_sel
        mov es,ax
;
        mov eax,fs:file_size
        sub eax,edx
        cmp eax,ecx
        jnc read_file_inrange
;
        mov ecx,eax

read_file_inrange:
        mov eax,es:[edi].ffl_clusters
        or eax,eax
        jnz read_file_do
;
        call get_file_cluster

read_file_do:
        push edi
;
        mov esi,es:[edi].fl_base
        lea ebp,[edi].ffl_clusters
        mov edi,es:[edi].ffl_sector_ptr
        mov eax,fs:file_block_size
        mov cl,ds:fat_cluster_shift
        add cl,9
        shr eax,cl
        mov ecx,eax
        mov ebx,edx

read_req_loop:
        cmp ebx,fs:file_size
        jae read_file_wait
;
        mov edx,es:[ebp]
        or edx,edx
        jnz read_file_req_cluster
;
    push ecx
    push ebp
    xor ecx,ecx

read_cluster_back_loop:
    inc ecx    
    sub ebp,4
    mov edx,es:[ebp]
    or edx,edx
    jz read_cluster_back_loop

read_cluster_fwd_loop:
    mov edx,es:[ebp]
    mov al,fs:file_drive
    call next_cluster
    jc read_cluster_fail
;    
    add ebp,4
    mov es:[ebp],edx
    loop read_cluster_fwd_loop   
;
    pop ebp
    pop ecx
    jmp read_file_req_cluster

read_cluster_fail:
    pop ebp
    pop ecx
    jmp read_file_wait

read_file_req_cluster:
        push ecx
        sub edx,2
        mov eax,1
        mov cl,ds:fat_cluster_shift
        shl edx,cl
        shl eax,cl
        mov ecx,eax
        add edx,ds:start_sector

read_cluster_loop:
        push ebx
        mov ebx,es:[edi]
        or ebx,ebx
        jnz read_cluster_next
;
        mov al,ds:drive_nr
        ReqSector
        jnc read_cluster_save
;
    mov ebx,-1

read_cluster_save:
        mov es:[edi],ebx

read_cluster_next:
        pop ebx
        add edi,4
        inc edx
        add esi,200h
        add ebx,200h
        loop read_cluster_loop
;
        add ebp,4
        pop ecx
        sub ecx,1
        jnz read_req_loop

read_file_wait:
        mov esi,edi
        pop edi

read_wait_loop:
        sub esi,4
        mov ebx,es:[esi]
        cmp ebx,-1
        je read_wait_next
;
        WaitForSector
        UnlockSector
        mov dword ptr es:[esi],-1

read_wait_next:
        cmp esi,es:[edi].ffl_sector_ptr
        jne read_wait_loop

read_file_done:
        popad
        clc
        pop fs
        pop es
        retf32
read_file_block ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   WRITE_FILE_BLOCK
;
;               DESCRIPTION:    Write file block
;
;               PARAMETERS:             BX                      HANDLE TO DEVICE
;                                               ECX                     NUMBER OF BYTES TO WRITE
;                                               EDX                     POSITION
;                                               EDI                     FILE LIST
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public write_file_block

write_file_block        PROC far
        push es
        push fs
        pushad
;
        mov fs,bx
        mov ax,flat_sel
        mov es,ax
;
        mov eax,fs:file_size
        sub eax,edx
        cmp eax,ecx
        jnc write_file_inrange
;
        mov ecx,eax

write_file_inrange:
        mov eax,es:[edi].ffl_clusters
        or eax,eax
        jnz write_file_do
;
        call get_file_cluster

write_file_do:
        mov esi,es:[edi].fl_base
        lea ebp,[edi].ffl_clusters
        mov edi,es:[edi].ffl_sector_ptr
        mov ebx,ecx
        add ebx,edx
        dec ebx
        mov eax,1
        mov cl,9
        add cl,ds:fat_cluster_shift
        shl eax,cl
        neg eax
        and edx,eax
        and ebx,eax
        neg eax
        add ebx,eax
        sub ebx,edx
        shr ebx,cl
        push ebx
;
        mov eax,fs:file_block_size
        dec eax
        mov ebx,edx
        and edx,eax
        and eax,ebx
        add esi,eax
;
        shr edx,cl
        shl edx,2
        add ebp,edx
;
        mov cl,ds:fat_cluster_shift
        shl edx,cl
        add edi,edx
        pop ecx

write_req_loop:
        cmp ebx,fs:file_size
        ja write_file_done
;
        mov edx,es:[ebp]
        or edx,edx
        jnz write_cluster_ok
;
    push ecx
    push ebp
    xor ecx,ecx

write_cluster_back_loop:
    inc ecx    
    sub ebp,4
    mov edx,es:[ebp]
    or edx,edx
    jz write_cluster_back_loop

write_cluster_fwd_loop:
    mov edx,es:[ebp]
    mov al,fs:file_drive
    call next_cluster
    jc write_cluster_fail
;    
    cmp edx,0FFFFh
    je write_cluster_fail
;    
    add ebp,4
    mov es:[ebp],edx
    loop write_cluster_fwd_loop
;
    pop ebp
    pop ecx
    jmp write_cluster_ok

write_cluster_fail:
    int 3    

write_cluster_ok:
        push ecx
        sub edx,2
        mov eax,1
        mov cl,ds:fat_cluster_shift
        shl edx,cl
        shl eax,cl
        mov ecx,eax
        add edx,ds:start_sector

write_cluster_loop:
        push ebx
        mov ebx,es:[edi]
        cmp ebx,-1
        je write_cluster_define
;
        or ebx,ebx
        jnz write_cluster_next

write_cluster_define:
        mov al,ds:drive_nr
        DefineSector
        jc write_cluster_modify_done
;       
        mov es:[edi],ebx

write_cluster_next:
        ModifySector

write_cluster_modify_done:
        pop ebx
        add edi,4
        inc edx
        add esi,200h
        add ebx,200h
        loop write_cluster_loop
;
        add ebp,4
        pop ecx
        sub cx,1
        jnz write_req_loop

write_file_done:
        popad
        clc
        pop fs
        pop es
        retf32
write_file_block        ENDP

code    ENDS

        END

