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
; FATFILE.ASM
; File handling for FAT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME fatfile

GateSize = 16

INCLUDE ..\os\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\user.def
INCLUDE ..\os\virt.def
INCLUDE ..\os\os.def
INCLUDE ..\os\user.inc
INCLUDE ..\os\virt.inc
INCLUDE ..\os\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\int.def
INCLUDE ..\os\system.inc
INCLUDE fat.inc

	.386p


	extrn lock_sector:near
	extrn modify_file_entry:near
	extrn next_cluster:near
	extrn allocate_cluster:near
	extrn free_cluster:near
	extrn link_cluster:near

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_LIST_BLOCK
;
;		DESCRIPTION:	Allocate list block
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_list_block	PROC near
	push eax
	push ecx
	push edx
	mov eax,1000h
	AllocateBigLinear
	mov ds:file_list_ptr,edx
	pop edx
	pop ecx
	pop eax
	ret
allocate_list_block	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_INDEX_BLOCK
;
;		DESCRIPTION:	Allocate index block
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						ES		FLAT SEL
;
;		RETURNS:		EDI		Index block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_index_block	PROC near
	push edx
	mov edi,ds:file_free_ptr
	or edi,edi
	jz allocate_index_block_new
	mov edx,es:[edi]
	mov ds:file_free_ptr,edx
	jmp allocate_index_block_done

allocate_index_block_new:
	mov edx,ds:file_list_ptr
	test dx,0FFFh
	jnz allocate_index_list_not_full
	call allocate_list_block
	mov edx,ds:file_list_ptr
allocate_index_list_not_full:
	mov edi,edx
	add edx,FILE_ENTRY_SIZE
	mov ds:file_list_ptr,edx

allocate_index_block_done:
	pop edx
	ret
allocate_index_block	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FREE_INDEX_BLOCK
;
;		DESCRIPTION:	Free index block
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						ES		FLAT SEL
;						EDI		Index block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_index_block	PROC near
	push edx
	mov edx,ds:file_free_ptr
	mov es:[edi],edx
	mov ds:file_free_ptr,edi
	pop edx
	ret
free_index_block	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			READ_FILE
;
;		DESCRIPTION:	Read file cluster chain
;
;		PARAMETERS:		AL			Drive
;						EDX			Start cluster
;						FS			File selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_file	Proc near
	push ebx
	push edx
	push edi
;
	call allocate_index_block
	mov fs:file_ptr,edi
	mov ebx,edi
	jmp read_file_cluster2

read_file_cluster_loop:
	call next_cluster
	jc read_file_done
	call allocate_index_block
	mov es:[ebx].file_next,edi
read_file_cluster2:
	mov es:[edi].file_cluster,edx
	call next_cluster
	jc read_file_done
	mov es:[edi].file_cluster+4,edx
	call next_cluster
	jc read_file_done
	mov es:[edi].file_cluster+8,edx
	mov ebx,edi
	jmp read_file_cluster_loop

read_file_done:
	mov es:[edi].file_next,0
;
	pop edi
	pop edx
	pop ebx
	ret
read_file	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_FILE
;
;		DESCRIPTION:	Open and buffer file
;
;		PARAMETERS:		AL			Drive
;						EDX			Start cluster
;						FS			Dir selector
;						EDI			Linear address of dir
;
;		RETURNS:		FS			File selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_file	PROC near
	push bx
	push edx
;
	mov bx,fs
	push es
	push eax
	mov eax,SIZE file_data_struc
	AllocateSmallGlobalMem
	mov ax,es
	mov fs,ax
	pop eax
	pop es
	InitReadWriteSection fs:file_section
	mov fs:file_usage,0
	mov fs:file_ptr,0
	mov fs:file_dir_entry,edi
	mov fs:file_parent,bx
	mov fs:file_cache_entry,-1
;
	or edx,edx
	jz open_file_done
	call read_file
open_file_done:
;
	pop edx
	pop bx
	ret
open_file	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_FILE_HANDLE
;
;		DESCRIPTION:	Open file handle
;
;		PARAMETERS:		EDI		Linear address of file
;						FS		Dir selector
;
;		RETURNS:		FS		File selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public open_file_handle

open_file_handle	Proc near
	push eax
	push edx
;
	mov dx,es:[edi].dir_handle
	or dx,dx
	jnz open_file_handle_done
	mov al,ds:drive_nr
	mov edx,es:[edi].dir_cluster
	call open_file
	mov es:[edi].dir_handle,fs	
	mov dx,fs
open_file_handle_done:
	mov fs,dx
	inc fs:file_usage
	pop edx
	pop eax
	ret
open_file_handle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CLOSE_FILE_HANDLE
;
;		DESCRIPTION:	Close file handle
;
;		PARAMETERS:		FS		File selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public close_file_handle

close_file_handle	Proc near
	push eax
	push edi
;
	sub fs:file_usage,1
	jnz close_file_done
;
	mov eax,fs:file_ptr
	mov edi,fs:file_dir_entry
	mov es:[edi].dir_handle,0
	push es
	mov di,fs
	mov es,di
	mov fs,fs:file_parent
	FreeMem
	pop es
close_file_loop:
	or eax,eax
	je close_file_done
	mov edi,eax
	mov eax,es:[edi].file_next
	call free_index_block
	jmp close_file_loop
close_file_done:
	pop edi
	pop eax
	ret
close_file_handle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LOCK_FILE
;
;		DESCRIPTION:	Get a buffer to file position
;
;		PARAMETERS:		FS		File selector
;						EDX		File offset
;
;		RETURNS:		EBX		Sector handle
;						ESI		Linear address of disk data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public lock_file

lock_file	Proc near
	push eax
	push ecx
	push edx
	push edi
;
	mov edi,fs:file_ptr
	push edx
	mov cl,9
	shr edx,cl
	push edx
	mov cl,ds:fat_cluster_shift
	shr edx,cl
	mov eax,edx
	xor edx,edx
	mov ecx,3
	div ecx
	mov ecx,eax
	or ecx,ecx
	jz lock_file_setup
;
	cmp ecx,fs:file_cache_entry
	jnz lock_file_cluster_search
;
	mov edi,fs:file_cache_ads
	jmp lock_file_setup

lock_file_cluster_search:
	mov eax,fs:file_cache_entry
	mov edi,fs:file_cache_ads
	mov fs:file_cache_entry,ecx
	sub ecx,eax
	jnc lock_file_cluster_loop
;
	mov edi,fs:file_ptr
	add ecx,eax

lock_file_cluster_loop:
	mov edi,es:[edi].file_next
	sub ecx,1
	jnz lock_file_cluster_loop
;
	mov fs:file_cache_ads,edi
		
lock_file_setup:
	shl edx,2
	mov edx,es:[edx+edi].file_cluster
	sub edx,2
	mov eax,1
	mov cl,ds:fat_cluster_shift
	shl edx,cl
	shl eax,cl
	add edx,ds:start_sector
	mov ecx,eax
	pop eax
	dec ecx
	and eax,ecx
	add edx,eax	
	mov al,ds:drive_nr
	call lock_sector
	pop edx
	jc lock_file_done
	and dx,1FFh
	or si,dx
	clc
lock_file_done:
	pop edi
	pop edx
	pop ecx
	pop eax
	ret
lock_file	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ADD_FIRST_CLUSTER
;
;		DESCRIPTION:	Add first cluster to file
;
;		PARAMETERS:		FS		File selector
;
;		RETURNS:		EDI		Linear address of cluster
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_first_cluster	Proc near
	push eax
	push edx
;
	call allocate_index_block
	mov fs:file_ptr,edi
	push edi
	mov edi,fs:file_dir_entry
	mov al,ds:drive_nr
	call allocate_cluster
	mov es:[edi].dir_cluster,edx
	pop edi
	mov es:[edi].file_cluster,edx
	mov es:[edi].file_cluster+4,0
	mov es:[edi].file_cluster+8,0
;
	pop edx
	pop eax
	ret
add_first_cluster	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ADD_CLUSTER1
;
;		DESCRIPTION:	Add cluster in first position of file
;
;		PARAMETERS:		FS		File selector
;						EDI		Cluster buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_cluster1	Proc near
	push ax
	push ebx
	push ecx
	push edx
;
	mov ebx,edi
	call allocate_index_block
	mov es:[ebx].file_next,edi
	mov edx,es:[ebx].file_cluster+8
	push edx
	mov al,ds:drive_nr
	call allocate_cluster
	mov ecx,edx
	pop edx
	jc add_cluster1_done
	call link_cluster
	mov es:[edi].file_cluster,ecx
	clc
add_cluster1_done:
;
	pop edx
	pop ecx
	pop ebx
	pop ax
	ret
add_cluster1	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ADD_CLUSTER2
;
;		DESCRIPTION:	Add cluster in second position of file
;
;		PARAMETERS:		FS		File selector
;						EDI		Cluster buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_cluster2	Proc near
	push ax
	push ecx
	push edx
;
	mov al,ds:drive_nr
	call allocate_cluster
	mov ecx,edx
	jc add_cluster2_done
	mov edx,es:[edi].file_cluster
	call link_cluster
	mov es:[edi].file_cluster+4,ecx
	clc
add_cluster2_done:
;
	pop edx
	pop ecx
	pop ax
	ret
add_cluster2	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ADD_CLUSTER3
;
;		DESCRIPTION:	Add cluster in third position of file
;
;		PARAMETERS:		FS		File selector
;						EDI		Cluster buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_cluster3	Proc near
	push ax
	push ecx
	push edx
;
	mov al,ds:drive_nr
	call allocate_cluster
	mov ecx,edx
	jc add_cluster3_done
	mov edx,es:[edi].file_cluster+4
	call link_cluster
	mov es:[edi].file_cluster+8,ecx
	clc
add_cluster3_done:
;
	pop edx
	pop ecx
	pop ax
	ret
add_cluster3	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GROW_FILE
;
;		DESCRIPTION:	Increase file size
;
;		PARAMETERS:		FS		File selector
;						EDX		Current number of clusters in file
;						ECX		Wanted number of clusters in file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_cluster_tab:
act0	DW OFFSET add_cluster1
act1	DW OFFSET add_cluster2
act2	DW OFFSET add_cluster3

grow_file	Proc near
	push eax
	push ecx
	push edx
	push edi
;
	or edx,edx
	jne grow_first_ok
	call add_first_cluster
	jc grow_file_done
	inc edx
	mov eax,1
	jmp grow_handle_link

grow_first_ok:
	mov edi,fs:file_ptr
	push edx
	push ecx
	mov ecx,edx
	mov eax,ecx
	xor edx,edx
	mov ecx,3
	div ecx
	mov ecx,eax
	or ecx,ecx
	jz grow_eof
	or edx,edx
	jnz grow_eof_loop
	sub ecx,1
	jz grow_eof
grow_eof_loop:
	mov edi,es:[edi].file_next
	sub ecx,1
	jnz grow_eof_loop
grow_eof:
	pop ecx
	mov eax,edx
	pop edx

grow_handle_link:
	sub ecx,edx
	or ecx,ecx
	jz grow_file_ok

grow_file_loop:
	call word ptr cs:[2*eax].add_cluster_tab
	jc grow_file_done
	sub ecx,1
	jz grow_file_ok
	inc eax
	cmp eax,3
	jne grow_file_loop
	xor eax,eax
	jmp grow_file_loop

grow_file_ok:
	mov es:[edi].file_next,0
	clc

grow_file_done:
	pop edi
	pop edx
	pop ecx
	pop eax
	ret
grow_file	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SHRINK_FILE
;
;		DESCRIPTION:	Decrease size of file
;
;		PARAMETERS:		FS		File selector
;						EDX		Current number of clusters in file
;						ECX		Wanted number of clusters in file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

shrink_file	Proc near
	push eax
	push ebx
	push ecx
	push edx
	push edi
;
	or ecx,ecx
	jne shrink_first_ok
;
	push edx
	mov edi,fs:file_ptr
	mov fs:file_ptr,0
	mov edx,es:[edi].file_cluster
	or edx,edx
	jz shrink_file_freed1
	mov al,ds:drive_nr
	call free_cluster
shrink_file_freed1:
	push edi
	mov edi,fs:file_dir_entry
	mov es:[edi].dir_cluster,0
	pop edi
	mov es:[edi].file_cluster,0
	pop edx
	dec edx
	or edx,edx
	mov eax,1
	sub ecx,edx
	neg ecx
	jne shrink_file_loop
	jmp shrink_file_free_last

shrink_first_ok:
	mov edi,fs:file_ptr
	xor ebx,ebx
	push edx
	push ecx
	dec ecx
	mov eax,ecx
	xor edx,edx
	mov ecx,3
	div ecx
	mov ecx,eax
	or ecx,ecx
	jz shrink_pos_ok
shrink_pos_loop:
	mov ebx,edi
	mov edi,es:[edi].file_next
	or edi,edi
	jz shrink_file_done
	sub ecx,1
	jnz shrink_pos_loop
shrink_pos_ok:
	pop ecx
	mov eax,edx
	pop edx
;
	sub ecx,edx
	neg ecx
	or ecx,ecx
	jz shrink_file_done
;
	or eax,eax
	jnz shrink_file_start
;
	mov es:[ebx].file_next,0
	push edi
	jmp shrink_file_start_done
	
shrink_file_start:
	push es:[edi].file_next
	mov es:[edi].file_next,0
shrink_file_start_loop:
	mov edx,es:[4*eax+edi].file_cluster
	or edx,edx
	jz shrink_file_freed2
	push ax
	mov al,ds:drive_nr
	call free_cluster
	pop ax
shrink_file_freed2:
	mov es:[4*eax+edi].file_cluster,0
	inc eax
	cmp eax,3
	je shrink_file_start_done
	sub ecx,1
	jnz shrink_file_start_loop
	add sp,4
	jmp shrink_file_done

shrink_file_start_done:
	pop edi
	or edi,edi
	jz shrink_file_done
	xor eax,eax

shrink_file_loop:
	mov edx,es:[4*eax+edi].file_cluster
	or edx,edx
	jz shrink_file_next
	push ax
	mov al,ds:drive_nr
	call free_cluster
	pop ax
	mov es:[4*eax+edi].file_cluster,0
shrink_file_next:
	sub ecx,1
	jz shrink_file_free_last
	inc eax
	cmp eax,3
	jnz shrink_file_loop
	xor eax,eax
	push es:[edi].file_next
	call free_index_block
	pop edi
	or edi,edi
	jz shrink_file_done
	jmp shrink_file_loop

shrink_file_free_last:
	call free_index_block

shrink_file_done:
	clc
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
shrink_file	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UPDATE_FILE_CLUSTERS
;
;		DESCRIPTION:	Update number of clusters in file
;
;		PARAMETERS:		FS		File selector
;						ECX		New file size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_file_clusters	PROC near
	push eax
	push ecx
	push edx
	push edi
;
	mov edi,fs:file_dir_entry
	mov eax,ecx
	mov cl,ds:fat_cluster_shift
	add cl,9
	dec eax
	sar eax,cl
	inc eax
	mov edx,es:[edi].dir_file_size
	dec edx
	sar edx,cl
	inc edx
update_cluster_before_ok:
	mov ecx,eax
	cmp ecx,edx
	clc
	je update_file_done
	cmp ecx,edx
	jc update_file_shrink

update_file_grow:
	call grow_file
	jmp update_file_done

update_file_shrink:
	call shrink_file

update_file_done:
	pop edi
	pop edx
	pop ecx
	pop eax
	ret
update_file_clusters	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UPDATE_FILE
;
;		DESCRIPTION:	Set file size
;
;		PARAMETERS:		FS		File selector
;						ECX		New file size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public update_file

update_file	PROC near
	push edi
	call update_file_clusters
	jc update_file_end
	mov edi,fs:file_dir_entry
	call modify_file_entry
update_file_end:
	pop edi
	ret
update_file	ENDP

code	ENDS

	END

