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
; NE.ASM
; NE (New Executable) loader
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE int.def
INCLUDE exec.def
INCLUDE ..\handle.inc
INCLUDE ne.def
INCLUDE system.def
INCLUDE system.inc

code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			AllocateSymbolMem
;
;	Purpose:		Allocate memory for symbols
;
;	Parameters:		EAX		Size of memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public AllocateSymbolMem

AllocateSymbolMem	Proc near
	push ds
	push eax
	push bx
	push edx
	AllocateLocalLinear
	AllocateGdt
	or bx,3
	mov ecx,eax
	CreateDataSelector16
	mov es,bx
	pop edx
	pop bx
	pop eax
	pop ds
	ret
AllocateSymbolMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_entry_ordinal
;
;		DESCRIPTION:    get entry table ordinal
;
;		PARAMETERS:    	DX		ORDINAL NUMBER TO SEARCH FOR
;						ES		LIB SELECTOR
;						AH		FLAGS
;						AL		SEGMENT NUMBER
;						BX		OFFSET
;						NC		ENTRY FOUND
;						CY		NO ENTRY
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_entry_ordinal	Proc near 
	push cx
	push dx
	mov ax,1
	mov bx,es:lib_entry_table_offset
get_entry_ord_loop:
	movzx cx,es:[bx].e_count
	or cx,cx
	stc
	jz get_entry_ord_done
	add cx,ax
	cmp dx,cx
	jc get_entry_ord_found
	mov al,es:[bx].e_segment
	or al,al
	je get_entry_ord_next2
	cmp al,0FFh                 
	mov al,3
	jne get_entry_ord_next
	shl al,1
get_entry_ord_next:
	mul es:[bx].e_count
	add bx,ax
get_entry_ord_next2:
	add bx,2
	mov ax,cx
	jmp get_entry_ord_loop
get_entry_ord_found:
	sub dx,ax
    mov al,es:[bx].e_segment
    or al,al             
    stc
    jz get_entry_ord_done
    cmp al,0FFh
    je get_entry_ord_move
get_entry_ord_fixed:
	mov al,3
	mul dl
	mov cl,es:[bx].e_segment
	add bx,ax
	add bx,2
	mov ah,es:[bx].fe_flag
	mov bx,es:[bx].fe_offset
	mov al,cl
	clc
	jmp get_entry_ord_done
get_entry_ord_move:
	mov al,6
	mul dl
	add bx,ax
	add bx,2
	mov al,es:[bx].me_segment
	mov ah,es:[bx].me_flag
	mov bx,es:[bx].me_offset
	clc
get_entry_ord_done:
	pop dx   
	pop cx
	ret
get_entry_ordinal	ENDP	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			demand_load
;
;		DESCRIPTION:    load segment data into memory
;
;		PARAMETERS:     BX		Selector to load
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reloc_error		Proc near
	int 3
	ret
reloc_error		Endp

reloc_internal_segment	Proc near
	movzx bx,byte ptr [si+4]
	cmp bl,0FFh
	je reloc_internal_move_segment
	dec bx
	shl bx,3
	mov ax,es:[bx].lib_tables.seg_selector
	mov bx,[si+2]                  
reloc_internal_segment_loop:
	mov dx,fs:[bx]
	mov fs:[bx],ax
	mov bx,dx
	cmp bx,-1
	jne reloc_internal_segment_loop
	ret                           
reloc_internal_move_segment:
	mov dx,[si+6]
	call get_entry_ordinal	
	jc reloc_int_seg_done
	movzx bx,al
	dec bx
	shl bx,3
	mov ax,es:[bx].lib_tables.seg_selector
	mov bx,[si+2]
reloc_internal_move_segment_loop:
	mov dx,fs:[bx]
	mov fs:[bx],ax
	mov bx,dx
	cmp bx,-1
	jne reloc_internal_move_segment_loop
reloc_int_seg_done:
	ret
reloc_internal_segment	Endp

reloc_internal_pointer	Proc near
	movzx bx,byte ptr [si+4]
	cmp bl,0FFh
	je reloc_internal_move_pointer
	dec bx
	shl bx,3
	mov ax,es:[bx].lib_tables.seg_selector
	mov bx,[si+2]
	mov dx,[si+6]                  
reloc_internal_pointer_loop:
	mov fs:[bx+2],ax
	push word ptr fs:[bx]
	mov fs:[bx],dx
	pop bx
	cmp bx,-1
	jne reloc_internal_pointer_loop
	ret                           
reloc_internal_move_pointer:
	mov dx,[si+6]
	call get_entry_ordinal	
	jc reloc_int_pointer_done
	mov dx,bx
	movzx bx,al
	dec bx
	shl bx,3
	mov ax,es:[bx].lib_tables.seg_selector
	mov bx,[si+2]
reloc_internal_move_pointer_loop:
	mov fs:[bx+2],ax
	push word ptr fs:[bx]
	mov fs:[bx],dx
	pop bx
	cmp bx,-1
	jne reloc_internal_move_pointer_loop
reloc_int_pointer_done:
	ret
reloc_internal_pointer	Endp

reloc_internal_offset	Proc near
	movzx bx,byte ptr [si+4]
	cmp bl,0FFh
	je reloc_internal_move_offset
	mov bx,[si+2]
	mov ax,[si+6]
reloc_internal_offset_loop:
	mov dx,fs:[bx]
	mov fs:[bx],ax
	mov bx,dx
	cmp bx,-1
	jne reloc_internal_offset_loop
	ret                          
reloc_internal_move_offset:
	mov dx,[si+6]
	call get_entry_ordinal
	jc reloc_int_offset_done
	mov ax,bx	
	mov bx,[si+2]
reloc_internal_move_offset_loop:
	mov dx,fs:[bx]
	mov fs:[bx],ax
	mov bx,dx
	cmp bx,-1
	jne reloc_internal_move_offset_loop
reloc_int_offset_done:
	ret
reloc_internal_offset	Endp
                                              
reloc_internal_table:
rint0	DW OFFSET reloc_error
rint1	DW OFFSET reloc_error
rint2	DW OFFSET reloc_internal_segment
rint3	DW OFFSET reloc_internal_pointer
rint4	DW OFFSET reloc_error
rint5	DW OFFSET reloc_internal_offset
rint6	DW OFFSET reloc_error
                                              
reloc_internal	Proc near
	movzx bx,byte ptr [si]
	cmp bx,6
	jc reloc_internal_do
	mov bx,6
reloc_internal_do:
	shl bx,1
	call word ptr cs:[bx].reloc_internal_table
	ret
reloc_internal	Endp

add_internal_segment	Proc near
	movzx bx,byte ptr [si+4]
	cmp bl,0FFh
	je add_internal_move_segment
	dec bx
	shl bx,3
	mov ax,es:[bx].lib_tables.seg_selector
	mov bx,[si+2]                  
	add fs:[bx],ax
	ret                           
add_internal_move_segment:
	mov dx,[si+6]
	call get_entry_ordinal	
	jc add_int_seg_done
	movzx bx,al
	dec bx
	shl bx,3
	mov ax,es:[bx].lib_tables.seg_selector
	mov bx,[si+2]
	add fs:[bx],ax
add_int_seg_done:
	ret
add_internal_segment	Endp
                                              
add_internal_table:
aint0	DW OFFSET reloc_error
aint1	DW OFFSET reloc_error
aint2	DW OFFSET add_internal_segment
aint3	DW OFFSET reloc_error
aint4	DW OFFSET reloc_error
aint5	DW OFFSET reloc_error
aint6	DW OFFSET reloc_error
                                              
add_internal	Proc near
	movzx bx,byte ptr [si]
	cmp bx,6
	jc add_internal_do
	mov bx,6
add_internal_do:
	shl bx,1
	call word ptr cs:[bx].add_internal_table
	ret
add_internal	Endp

reloc_import_ordinal	Proc near
	push di
	mov di,[si+4]
	dec di
	add di,di
	add di,es:lib_module_offset
	mov bx,es:[di]
	push es
	or bx,bx
	jz reloc_import_ordinal_done
	mov es,bx
	mov dx,[si+6]
	call get_entry_ordinal
	jc reloc_import_ordinal_done
	cmp al,0FEh
	jne reloc_import_ordinal_ptr
reloc_import_ordinal_offset:
	mov dx,bx
	mov bx,[si+2]
reloc_import_ordinal_offset_loop:
	push word ptr fs:[bx]
	mov fs:[bx],dx
	pop bx
	cmp bx,-1
	jne reloc_import_ordinal_offset_loop	
	jmp reloc_import_ordinal_done
reloc_import_ordinal_ptr:
	mov dx,bx
	movzx bx,al
	dec bx
	shl bx,3
	mov ax,es:[bx].lib_tables.seg_selector
	mov bx,[si+2]
reloc_import_ordinal_ptr_loop:
	mov fs:[bx+2],ax
	push word ptr fs:[bx]
	mov fs:[bx],dx
	pop bx
	cmp bx,-1
	jne reloc_import_ordinal_ptr_loop	
reloc_import_ordinal_done:
	pop es
	pop di
	ret
reloc_import_ordinal	Endp

add_import_ordinal	Proc near
	push di
	mov di,[si+4]
	dec di
	add di,di
	add di,es:lib_module_offset
	mov bx,es:[di]
	push es
	or bx,bx
	jz add_import_ordinal_done
	mov es,bx
	mov dx,[si+6]
	call get_entry_ordinal
	jc add_import_ordinal_done
	cmp al,0FEh
	jne add_import_ordinal_ptr
add_import_ordinal_offset:
	mov dx,bx
	mov bx,[si+2]
	add fs:[bx],dx
	jmp add_import_ordinal_done
add_import_ordinal_ptr:
	mov dx,bx
	movzx bx,al
	dec bx
	shl bx,3
	mov ax,es:[bx].lib_tables.seg_selector
	mov bx,[si+2]
	add fs:[bx+2],ax
add_import_ordinal_done:
	pop es
	pop di
	ret
add_import_ordinal	Endp

reloc_import_name		Proc near
	int 3
	ret
reloc_import_name		Endp

reloc_table:
r0	DW OFFSET reloc_internal
r1	DW OFFSET reloc_import_ordinal
r2	DW OFFSET reloc_import_name
r3	DW OFFSET reloc_error
r4	DW OFFSET add_internal
r5	DW OFFSET add_import_ordinal
r6	DW OFFSET reloc_error
r7	DW OFFSET reloc_error

demand_load_name	DB 'Segment Not Present',0

demand_load	Proc far
    push ds
	push es
	push fs
	push ecx
	push edx
	push esi
	push edi
	mov bx,[bp].vm_err
	test bx,4
	stc
	jz demand_load_end

demand_load_ldt:
    push bx
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov bx,ds:app_mod_id
    ModuleIdToSel
    pop bx
	jc demand_load_end
;    
    push ax
    mov ds,ax
    EnterSection ds:mod_section
;
    GetThread
	mov ds,ax
	mov ds,ds:p_ldt_sel
	and bx,0FFF8h
	mov ax,[bx+2]
	verr ax
	stc
	jnz demand_load_leave
;
	mov cl,[bx+5]
	test cl,80h
	jnz demand_load_leave
;
	mov es,ax    
	mov di,[bx+6]
	movzx eax,word ptr [bx]
	inc eax
	AllocateLocalLinear
	rol edx,8
	mov [bx+7],dl
	mov dl,[bx+5]
	or dl,80h
	push ds
	push bx
	push dx
	mov dl,0F2h
	ror edx,8
	mov [bx+2],edx
	mov byte ptr [bx+6],0
	or bx,7
	mov fs,bx
	mov bx,es:lib_file_handle
	mov ax,1
	mov cx,es:lib_sector_shift
	shl ax,cl
	mul es:[di].lib_tables.seg_sector
	push dx
	push ax
	pop eax
	SetFilePos
	mov cx,es:[di].lib_tables.seg_file_size
	push es
	push di
	mov di,fs
	mov es,di
	xor di,di
	ReadFile
	pop di
	pop es
	mov ax,es:[di].lib_tables.seg_flags
	test ax,100h
	jz demand_load_done
	push es
	push di
	sub sp,2
	mov di,ss
	mov es,di
	mov di,sp
	mov cx,2
	ReadFile
	pop cx
	shl cx,3
	movzx eax,cx
	AllocateLocalMem
	xor di,di
	ReadFile
	mov ax,es
	mov ds,ax
	pop di
	pop es
reloc_start:
	xor si,si
	shr cx,3
reloc_loop:
	movzx bx, byte ptr [si+1]
	cmp bx,7
	jc reloc_do
	mov bx,7
reloc_do:                           
	shl bx,1
	call word ptr cs:[bx].reloc_table
	add si,8
	loop reloc_loop
	push es
	mov ax,ds
	mov es,ax
	xor ax,ax
	mov ds,ax 
;	FreeMem
	pop es
demand_load_done:
	pop dx  
	pop bx
	pop ds
;
	mov ax,es:[di].lib_tables.seg_flags
    and ax,1
	jnz demand_load_data

demand_load_code:
	test dl,4
	jz demand_load_code_code

demand_load_code_data:
	mov [bx+5],dl
	mov eax,[bx]
	mov [bx-8],eax
	mov eax,[bx+4]
	mov [bx-4],eax
	mov byte ptr [bx-3],0FAh
	jmp demand_load_leave

demand_load_code_code:
	mov [bx+5],dl
	mov eax,[bx]
	mov [bx+8],eax
	mov eax,[bx+4]
	mov [bx+12],eax
	mov byte ptr [bx+13],0F2h
	jmp demand_load_leave

demand_load_data:
	mov [bx+5],dl

demand_load_leave:
    pop ds
	LeaveSection ds:mod_section
	clc
demand_load_end:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop fs
	pop es
	pop ds
	ret
demand_load	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			null_terminate_table
;
;		DESCRIPTION:    change names in table to asciiz strings
;
;		PARAMETERS:     ES		LIB SEGMENT         
;						BX		TABLE OFFSET
;						CX		TABLE SIZE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

null_terminate_table	PROC near                                  
	or cx,cx
	jz null_terminate_table_done
	mov ah,es:[bx]
	or ah,ah
	jz null_terminate_table_moved
	sub cl,ah
	sbb ch,0
null_terminate_table_loop:
	mov al,es:[bx+1]
	mov es:[bx],al
	inc bx
	sub ah,1
	jnz null_terminate_table_loop
null_terminate_table_moved:
	mov es:[bx],ah
	inc bx
	dec cx
	jmp null_terminate_table		
null_terminate_table_done:
	ret
null_terminate_table	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			read_segment_table
;
;		DESCRIPTION:    read segment table into lib segment
;
;		PARAMETERS:     BX		LIB FILE HANDLE
;						DS		NE HEADER
;						ES		LIB SEGMENT
;						DI		OFFSET TO NEXT TABLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_segment_table	PROC near
	push bx
	movzx eax,ds:seh_segment_offset
	add ax,es:lib_filebase
	SetFilePos
	mov di,OFFSET lib_tables
	mov cx,ds:seh_segment_entries
	mov es:lib_segment_entries,cx
	shl cx,3
	ReadFile
	mov dx,ds:seh_automatic_ds
	mov di,dx
	or di,di
	jz read_segment_no_auto
	dec di
	shl di,3
	mov ax,word ptr es:[di+6].lib_tables
	cmp dx,ds:seh_ss
	jne read_segment_farstack
	mov cx,ds:seh_stack_size
	or cx,cx
	jz read_segment_farstack
;
	add ax,cx
	mov ds:seh_sp,ax
read_segment_farstack:
	add ax,ds:seh_heap_size
	mov word ptr es:[di+6].lib_tables,ax
	mov ds:seh_automatic_size,ax
read_segment_no_auto:	    
	mov cx,ds:seh_segment_entries
	push ds
	GetThread
	mov ds,ax
	mov ds,ds:p_ldt_sel
	xor di,di
init_segments:
	mov dx,word ptr es:[di+6].lib_tables
    dec dx
	mov ah,es:[di+4].lib_tables
    and ah,1
	jz init_code_segment

init_data_segment:
	AllocateLdt
    mov [bx],dx
    mov [bx+2],es
    mov [bx+6],di         
    mov byte ptr [bx+5],72h
	or bx,7
    mov es:[di].lib_tables.seg_selector,bx
	jmp init_next_segment

init_code_segment:
	push cx
	mov cx,2
	AllocateMultipleLdt
	pop cx
    mov [bx],dx
    mov [bx+2],es
    mov [bx+6],di
	mov byte ptr [bx+5],7Ah
	or bx,7
    mov es:[di].lib_tables.seg_selector,bx
;
	inc bx
    mov [bx],dx
    mov [bx+2],es
    mov [bx+6],di
	mov byte ptr [bx+5],72h

init_next_segment:
    add di,8
    loop init_segments                     
    add di,OFFSET lib_tables
    pop ds 
    pop bx
	ret
read_segment_table	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			read_entry_table
;
;		DESCRIPTION:    read entry table into lib segment
;
;		PARAMETERS:     BX		LIB FILE HANDLE
;						DS		NE HEADER
;						ES		LIB SEGMENT         
;						DI		OFFSET FROM PREV AND NEXT TABLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_entry_table	PROC near                                  
	movzx eax,ds:seh_entry_table_offset
	add ax,es:lib_filebase
	SetFilePos
	mov es:lib_entry_table_offset,di
	mov cx,ds:seh_entry_table_size
	mov es:lib_entry_table_size,cx		
	ReadFile
	add di,cx
	ret
read_entry_table	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			read_resource_table
;
;		DESCRIPTION:    read resource table into lib segment
;
;		PARAMETERS:     BX		LIB FILE HANDLE
;						DS		NE HEADER
;						ES		LIB SEGMENT         
;						DI		OFFSET FROM PREV AND NEXT TABLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_resource_table	PROC near                                  
	movzx eax,ds:seh_resource_offset
	add ax,es:lib_filebase
	SetFilePos
	mov es:lib_resource_offset,di
	mov cx,ds:seh_resident_offset
	sub cx,ds:seh_resource_offset
	mov es:lib_resource_size,cx		
	or cx,cx
	jz read_resource_done
;
    push ecx
    push si
	ReadFile
;
    mov si,di
    mov cx,es:[si].rsc_align_shift
    add si,SIZE resource_struc

read_resource_type_loop:
    mov ax,es:[si].rt_type_id
    or ax,ax
    jz read_resource_type_done
;
    mov dx,es:[si].rt_resource_count
    add si,SIZE resource_type_struc

read_resource_name_loop:
    movzx eax,es:[si].rn_offset
    shl eax,cl
    SetFilePos
;
    movzx eax,es:[si].rn_len
    shl eax,cl
;
    push es
	push cx
    push edi
    AllocateLocalMem
    mov ecx,eax
    xor edi,edi
    UserGateForce32 read_file_nr
    mov ax,es
    pop edi
	pop cx
    pop es            
;
    mov es:[si].rn_sel,ax
    add si,SIZE resource_name_struc
    sub dx,1
    jnz read_resource_name_loop
;
    jmp read_resource_type_loop

read_resource_type_done:
    pop si
    pop ecx
    
read_resource_done:
	add di,cx
	ret
read_resource_table	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			read_resident_table
;
;		DESCRIPTION:    read resident names table into lib segment
;
;		PARAMETERS:     BX		LIB FILE HANDLE
;						DS		NE HEADER
;						ES		LIB SEGMENT         
;						DI		OFFSET FROM PREV AND NEXT TABLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_resident_table	PROC near                                  
	movzx eax,ds:seh_resident_offset
	add ax,es:lib_filebase
	SetFilePos
	mov es:lib_resident_offset,di
	mov cx,ds:seh_module_offset
	sub cx,ds:seh_resident_offset
	mov es:lib_resident_size,cx		
	ReadFile
	add di,cx
	ret
read_resident_table	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			read_module_table
;
;		DESCRIPTION:    read module table into lib segment
;
;		PARAMETERS:     BX		LIB FILE HANDLE
;						DS		NE HEADER
;						ES		LIB SEGMENT         
;						DI		OFFSET FROM PREV AND NEXT TABLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_module_table	PROC near                                  
	movzx eax,ds:seh_module_offset
	add ax,es:lib_filebase
	SetFilePos
	mov es:lib_module_offset,di
	mov cx,ds:seh_imported_offset
	sub cx,ds:seh_module_offset
	mov es:lib_module_size,cx		
	ReadFile
	add di,cx
	ret
read_module_table	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			load_imported_dlls
;
;		DESCRIPTION:    read imported names table and load all dlls
;
;		PARAMETERS:     BX		LIB FILE HANDLE
;						DS		NE HEADER
;						ES		LIB SEGMENT         
;						DI		OFFSET FROM PREV AND NEXT TABLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_imported_dlls	PROC near                                  
	mov cx,es:lib_module_size
	or cx,cx
	clc
	jz load_imported_dlls_end
	movzx eax,ds:seh_imported_offset
	add ax,es:lib_filebase
	SetFilePos
	mov es:lib_imported_offset,di
	mov cx,ds:seh_entry_table_offset
	sub cx,ds:seh_imported_offset
	push ds
	push es
	pusha
	mov ax,es
	mov ds,ax
	movzx eax,cx
	AllocateLocalMem
	xor di,di
	ReadFile
	mov bx,di
	call null_terminate_table
	mov si,ds:lib_module_offset
	mov cx,ds:lib_module_size
	shr cx,1
load_imported_dlls_loop:
	mov di,[si]
	call load_dll
	jc load_imported_fail
;
	mov [si],bx
	add si,2
	loop load_imported_dlls_loop
	FreeMem
	clc
	jmp load_imported_ok

load_imported_fail:
	FreeMem
	popa
	pop es
	pop ds
	stc
	jmp load_imported_dlls_end

load_imported_ok:
	popa
	pop es
	pop ds
	clc

load_imported_dlls_end:
	ret
load_imported_dlls	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			create_lib
;
;		DESCRIPTION:    Create lib segment from ne-header
;
;		PARAMETERS:     BX		LIB FILE HANDLE
;						DX		FILEPOSITION OF HEADER
;						ES		NE HEADER
;
;       RETURN VALUE:   ES		LIB SEGMENT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
create_lib	Proc near 
	push dx
	movzx eax,word ptr es:seh_entry_table_size
	mov cx,es:seh_segment_entries
	shl cx,3
	add ax,cx
	mov cx,es:seh_entry_table_offset
	sub cx,es:seh_resource_offset
	add ax,cx
	add ax,OFFSET lib_tables
	push es
	pop ds
	call AllocateSymbolMem
	mov es:lib_file_handle,bx
	mov es:lib_filebase,dx
	mov es:lib_usage_count,0
	mov ax,ds:seh_sector_shift
	mov es:lib_sector_shift,ax
	GetFileInfo
	mov es:lib_handle_selector,ax
	call read_segment_table
	call read_entry_table
	call read_resource_table
	call read_resident_table
	call read_module_table
	call load_imported_dlls
	jc create_lib_done
;
	mov bx,es:lib_resident_offset
	mov cx,es:lib_resident_size
	call null_terminate_table
;
    mov es:mod_free_dll_proc,0
    mov es:mod_get_proc_proc,0
    mov es:mod_get_name_proc,0
    mov es:mod_start_wait_for_debug_event_proc,0
    mov es:mod_stop_wait_for_debug_event_proc,0
    mov es:mod_is_debug_event_idle_proc,0
    mov es:mod_get_debug_event_proc,0
    mov es:mod_get_debug_event_data_proc,0
    mov es:mod_clear_debug_event_proc,0
    mov es:mod_continue_debug_event_proc,0
;
    mov word ptr es:mod_get_resource_proc,OFFSET get_resource
    mov word ptr es:mod_get_resource_proc+2,cs
	clc

create_lib_done:
	pop dx
	ret
create_lib	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			destroy_lib
;
;		DESCRIPTION:    Destroy lib segment
;
;		PARAMETERS:     ES		LIB HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
destroy_lib	Proc near 
	mov cx,es:lib_segment_entries
	mov di,OFFSET lib_tables
	GetThread
	mov ds,ax
	mov ds,ds:p_ldt_sel
destroy_selectors:
	mov bx,es:[di].seg_selector
	mov dx,bx
	and bx,0FFF8h
	mov al,[bx+5]
	test al,80h
	jz destroy_next_selector
	push es
	mov es,dx
	FreeMem
	pop es
destroy_next_selector:
	add di,8
	loop destroy_selectors
;
    mov ax,es:lib_resource_size
    or ax,ax
    jz destroy_resource_done
;
    mov di,es:lib_resource_offset
    add di,SIZE resource_struc

destroy_resource_type_loop:
    mov ax,es:[di].rt_type_id
    or ax,ax
    jz destroy_resource_done
;
    mov cx,es:[di].rt_resource_count
    add di,SIZE resource_type_struc

destroy_resource_name_loop:
    push es
    mov es,es:[di].rn_sel
    FreeMem
    pop es
;
    add di,SIZE resource_name_struc
    loop destroy_resource_name_loop
;
    jmp destroy_resource_type_loop
    
destroy_resource_done:
	ret
destroy_lib	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			run_ne_dll
;
;		DESCRIPTION:    Run new executable file
;
;		PARAMETERS:     DS		NE header
;						ES		LIB SEGMENT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                           
run_ne_dll	proc near
	push ds
	push es
	push gs
	pushad
;
	mov si,ds:seh_cs
	dec si
	shl si,3
	mov ax,es:[si].lib_tables.seg_selector
	mov gs,ax
	push ax
	push ds:seh_ip
	xor eax,eax
	xor ebx,ebx
	xor ecx,ecx
	xor edx,edx
	xor esi,esi
	xor edi,edi
	CallPM16
;
	popad
	pop gs
	pop es
	pop ds
	ret
run_ne_dll	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_dll
;
;		DESCRIPTION:    get dll selector from name
;
;		PARAMETERS:    	ES:DI	DLL NAME
;						BX		DLL SELECTOR
;						NC		DLL FOUND
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_dll	Proc near
	push ds
	push si
	push di
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov bx,ds:app_mod_id
    ModuleIdToSel
	jc get_dll_end
;
    push ds
    mov ds,bx
    EnterSection ds:mod_section
;    mov ax,ds:mod_list
    or ax,ax
    jz get_dll_fail

get_dll_check_dll:
    mov ds,ax
	mov si,ds:lib_resident_offset

get_dll_check_name:
	lodsb
	cmp al,es:[di]
	jne get_dll_next
	or al,al
	je get_dll_ok
	inc di
	jmp get_dll_check_name

get_dll_next:
    mov ax,ds:mod_next
    or ax,ax
	jne get_dll_check_dll

get_dll_fail:
	xor bx,bx
    pop ds
    LeaveSection ds:mod_section
	stc
	jmp get_dll_end

get_dll_ok:
	mov bx,ds
    pop ds
    LeaveSection ds:mod_section
	clc

get_dll_end:
	pop di
	pop si		
	pop ds
	ret
get_dll	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			open_dll
;
;		DESCRIPTION:    Open DLL file
;
;		PARAMETERS:     FS:SI	DLL name
;						ES		Buffer
;
;		RETURNS:		BX		File handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PathName		DB 'PATH',0

open_dll	Proc near	
	push ds
	push gs
	push ax
	push cx
	push dx
	push si
	push di
;
    LockProcEnv
    mov ds,bx
;
	xor di,di
	mov cx,0F00h
	push si
	push di
open_dll_move_loop:
	lods byte ptr fs:[si]
	or al,al
	jz open_dll_move_done
	stosb
	loop open_dll_move_loop
open_dll_move_done:
	mov ax,'d.'
	stosw
	mov ax,'ll'
	stosw
	xor al,al
	stosb
	pop di
	pop si
	xor cl,cl
	xor cl,cl
	OpenFile
	jnc open_dll_ok
;
	mov bx,si
	mov ax,es
	mov gs,ax
	xor si,si
	mov ax,cs
	mov es,ax
	mov di,OFFSET PathName
find_path_loop:
	cmpsb
	jnz find_path_next
	mov al,es:[di]
	or al,al
	jnz find_path_loop
	mov al,[si]
	cmp al,'='
	je find_path_found

find_path_next:
	lodsb
	or al,al
	jnz find_path_next
	mov al,[si]
	or al,al
	mov di,OFFSET PathName
	jne find_path_loop
	jmp find_path_failed

find_path_found:
	mov ax,gs
	mov es,ax
	xor di,di
	inc si
find_path_move_loop:
	lodsb
	or al,al
	jz find_path_move_ok
	cmp al,';'
	je find_path_move_ok
	stosb
	jmp find_path_move_loop	

find_path_move_ok:
	mov cx,0F00h
	push bx
find_path_name_loop:
	mov al,fs:[bx]
	inc bx
	or al,al
	jz find_path_name_move_ext
	stosb
	loop find_path_name_loop

find_path_name_move_ext:
	mov ax,'d.'
	stosw
	mov ax,'ll'
	stosw
	xor al,al
	stosb
	pop bx
;
	mov dx,bx
	xor di,di
	xor cl,cl
	OpenFile
	jnc open_dll_ok
;
	mov bx,dx
	mov al,[si-1]
	or al,al
	jnz find_path_move_loop

find_path_failed:
	stc
	jmp open_dll_done

open_dll_ok:
	clc
	
open_dll_done:
    pushf
    UnlockProcEnv
    popf
;
	pop di
	pop si
	pop dx
	pop cx
	pop ax
	pop gs
	pop ds
	ret
open_dll Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			load_dll
;
;		DESCRIPTION:    Load DLL
;
;       PARAMETERS:		ES:DI	name of dll to load
;
;		RETURNS:		BX		HANDLE OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_dll	Proc near
	push ds
	push es
	push fs
	push ax
	push cx
	push dx
	push si
	push di
;
	call get_dll
	jnc load_dll_ok
;
	mov ax,es
	mov fs,ax
	mov si,di
;
	mov eax,1000h
	AllocateBigMem
;
	call open_dll
	jc load_dll_fail
;
	mov cx,40h
	xor di,di
	ReadFile
	jc load_dll_fail
	cmp ax,40h
	jne load_dll_fail
	mov ax,es:exeh_signature
	cmp ax,5A4Dh
	jne load_dll_fail
	mov ax,es:exeh_reloc_offs
	cmp ax,40h
	jne load_dll_fail
	mov dx,es:[3Ch]
	movzx eax,dx
	SetFilePos
	mov cx,40h
	ReadFile   
	mov ax,es:[0]
	cmp ax,'EN'
	jne load_dll_fail
	push es
	call create_lib
	jc load_dll_import_fail
;
    mov word ptr es:mod_free_dll_proc,OFFSET free_dll	
    mov word ptr es:mod_free_dll_proc+2,cs
    CreateModule
;
	push ds
	GetThread
	mov ds,ax
	mov ds:p_lib_sel,es
	pop ds
	call run_ne_dll
	xor ax,ax
	mov ds,ax
	mov bx,es
	pop es
	FreeMem

load_dll_ok:
	mov es,bx
	inc es:lib_usage_count
	clc
	jmp load_dll_done

load_dll_import_fail:
	pop es

load_dll_fail:
	FreeMem
	stc

load_dll_done:
	pop di
	pop si
	pop dx
	pop cx
	pop ax
	pop fs
	pop es
	pop ds
	ret
load_dll	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			free_dll
;
;		DESCRIPTION:    Free DLL
;
;       PARAMETERS:		BX		HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_dll	Proc near
	push ds
	push es
	pusha
	mov es,bx
;
	FreeModule
;	
	call destroy_lib
	mov bx,es:lib_file_handle
	CloseFile
	FreeMem
	popa
	pop es
	pop ds
	ret
free_dll	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			run_ne
;
;		DESCRIPTION:    Run new executable file
;
;		PARAMETERS:     DS		NE header
;						ES		LIB SEGMENT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                           
run_ne	PROC near
	mov ax,ds:seh_flag
	mov si,ds:seh_automatic_ds
	or si,si
	jz run_no_auto_ds
	dec si
	shl si,3                    
	mov bx,es:[si].lib_tables.seg_selector
	mov ds:seh_automatic_ds,bx
run_no_auto_ds:
	mov si,ds:seh_cs
	dec si
	shl si,3
	mov bx,es:[si].lib_tables.seg_selector
	mov ds:seh_cs,bx
	mov ax,es:seh_flag
	test ax,8000h
	jz run_ne_sp_add
	mov ds:seh_ss,0
	jmp run_ne_sp_ok

run_ne_sp_add:
	mov si,ds:seh_ss
	or si,si
	jz run_ne_sp_ok
	dec si
	shl si,3
	mov bx,es:[si].lib_tables.seg_selector
	mov ds:seh_ss,bx
	cmp bx,ds:seh_automatic_ds
	je run_ne_sp_ok
;
	mov cx,ds:seh_sp
	push ds
	GetThread
	mov ds,ax
	mov ds,ds:p_ldt_sel
	and bx,0FFF8h
	movzx eax,cx
	AllocateLocalLinear
	dec cx
	mov [bx],cx
	mov [bx+2],edx
	mov al,0F2h
	xchg al,[bx+5]
	mov byte ptr [bx+6],0
	mov [bx+7],al
	pop ds

run_ne_sp_ok:
	movzx eax,ds:seh_ss
	or ax,ax
	jnz run_stack_ok
	movzx eax,ds:seh_stack_size
	push es
	AllocateLocalMem
	mov ax,es
	pop es
	mov dword ptr [bp].load_ss,eax
	mov ax,ds:seh_stack_size
	mov dword ptr [bp].load_esp,eax
	jmp run_stack_done
run_stack_ok:
	mov dword ptr [bp].load_ss,eax
	mov ax,ds:seh_sp
	mov dword ptr [bp].load_esp,eax
run_stack_done:
	mov ax,ds:seh_cs
	mov dword ptr [bp].load_cs,eax
	mov ax,ds:seh_ip
	mov dword ptr [bp].load_eip,eax
	mov word ptr [bp+2].load_eflags,0
	mov ax,7202h
	SetFlags
	mov [bp].load_eflags,ax
	mov ax,ds:seh_automatic_ds
	mov [bp].load_ds,ax
	clc
	ret
run_ne	ENDP
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			load_ne
;
;		DESCRIPTION:    Load new executable file
;
;		PARAMETERS:     BX		file handle
;						DS:ESI	File name
;						ES:EDI	Command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_ne	Proc far
	push ds
	push es
	push esi
	push edi
;
	xor eax,eax
	SetFilePos
	mov eax,40h
	AllocateSmallGlobalMem
	mov cx,ax
	xor di,di
	ReadFile
	jc load_ne_fail
	cmp ax,40h
	jne load_ne_fail
	mov ax,es:exeh_signature
	cmp ax,5A4Dh
	jne load_ne_fail
	mov ax,es:exeh_reloc_offs
	cmp ax,40h
	jne load_ne_fail
	mov dx,es:[3Ch]
	movzx eax,dx
	SetFilePos
	mov cx,40h
	ReadFile   
	jc load_ne_fail
	mov ax,es:[0]
	cmp ax,'EN'
	jne load_ne_fail
;
	push es
	mov al,16
	SetBitness
;
	call create_lib
	jc load_ne_import_fail
;
	SetModule
;
	call run_ne
	GetThread
	mov ds,ax
	mov ds:p_lib_sel,es
	pop es
	FreeMem
	mov word ptr [bp].load_es,0
	GetThread
	mov ds,ax
	mov ds,ds:p_app_sel
	mov word ptr ds:app_load_dll_proc,OFFSET load_dll_pr
	mov word ptr ds:app_load_dll_proc+2,cs
	clc
	jmp load_ne_done

load_ne_import_fail:
	xor ax,ax
	mov ds,ax
	pop es
	FreeMem

load_ne_fail:
	FreeMem
	stc

load_ne_done:
	pop edi
	pop esi
	pop es
	pop ds
	retf32
load_ne	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			load_dll_pr
;
;		DESCRIPTION:    Load DLL
;
;       PARAMETERS:		ES:DI	name of dll to load
;
;		RETURNS:		BX		HANDLE OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_dll_pr	Proc far
	push ds
	push es
	push ax
	push cx
	push dx
	push si
	push di
;
	call load_dll
;
	pop di
	pop si
	pop dx
	pop cx
	pop ax
	pop es
	pop ds
	ret
load_dll_pr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			free_dll
;
;		DESCRIPTION:    Free DLL
;
;       PARAMETERS:		BX		Lib sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_dll_pr	Proc far
	push ds
	push es
	pusha
;
	call free_dll
;
	popa
	pop es
	pop ds
	ret
free_dll_pr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetResource
;
;		DESCRIPTION:    Get resource
;
;       PARAMETERS:		BX		Lib sel
;						AX		Resource id
;						DX		Resource type
;						
;		RETURNS:		DS:ESI	Resource Address
;						ECX		Resource size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_resource	Proc far
    push es
	push eax
	push ebx
	push edx
	push di
;
	mov si,ax
	mov es,bx
    mov di,es:lib_resource_offset
    mov cx,es:[di].rsc_align_shift
    add di,SIZE resource_struc

get_resource_type_loop:
    mov ax,es:[di].rt_type_id
    or ax,ax
    jz get_resource_fail
;
    test ax,8000h
    jz get_resource_next
;
    and ax,7FFFh
    cmp ax,dx
    jne get_resource_next
;
    mov dx,es:[di].rt_resource_count
    add di,SIZE resource_type_struc

get_resource_entry_loop:
	mov ax,es:[di].rn_id
	test ax,8000h
	jz get_resource_entry_next
;
	and ax,7FFFh
	shl ax,4
	cmp si,ax
	jb get_resource_name_search

get_resource_entry_next:
	add di,SIZE resource_name_struc
	sub dx,1
	jnz get_resource_entry_loop
	jmp get_resource_fail

get_resource_name_search:
	sub ax,10h
	sub si,ax
	jc get_resource_fail

get_resource_name_loop:
    mov ds,es:[di].rn_sel
    movzx edx,es:[di].rn_len
    shl edx,cl
    xor ebx,ebx

get_resource_arr_loop:
    cmp ebx,edx
    jae get_resource_fail
;
    or si,si
    je get_resource_ok
;
    movzx eax,byte ptr [ebx]
    add ebx,eax
    inc ebx
    dec si
    jmp get_resource_arr_loop

get_resource_next:
    mov dx,es:[di].rt_resource_count
    add di,SIZE resource_type_struc

get_resource_next_name:
    add di,SIZE resource_name_struc
    sub dx,1
    jnz get_resource_next_name
    jmp get_resource_type_loop

get_resource_fail:
    stc
    jmp get_resource_done

get_resource_ok:
    movzx ecx,byte ptr [ebx]
    mov esi,ebx
    inc esi
    clc
    
get_resource_done:
	pop di
	pop edx
	pop ebx
	pop eax
	pop es
	ret
get_resource	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			open_app
;
;		DESCRIPTION:    Open app hook
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_app	Proc far
	retf32
open_app	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			close_app
;
;		DESCRIPTION:   	Close app
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_app	Proc far
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
	mov ax,ds:app_mod_sel
	or ax,ax
	jz close_app_done
;
    mov es,ax
    ResetModule
;
	xor ax,ax
	mov es,ax
	mov fs,ax
	mov gs,ax
;
;    mov bx,es:mod_list
    or bx,bx
    jz close_app_done	

unload_loop:
    mov es,bx
	push ds
	call free_dll
	pop ds
;
    mov bx,es:mod_next	
	or bx,bx
	jnz unload_loop

close_app_done:
	retf32
close_app	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Delete_handle
;
;		DESCRIPTION:	Delete handle (called from handle module)
;
;		PARAMETERS:		BX			DLL HANDLE
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle	Proc far
	push ds
	push es
	pushad
;
	mov ax,DLL_HANDLE16
	DerefHandle
	jc delete_handle_done
;
    mov bx,ds:[bx].lh_sel

delete_handle_done:
    popad
	pop es
	pop ds
	ret
delete_handle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_ne
;
;		DESCRIPTION:    Init ne loader module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	push ds
	push es
	pusha
;
	mov bx,ne_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET delete_handle
	mov ax,DLL_HANDLE16
	RegisterHandle
;
	mov edi,OFFSET load_ne
	HookLoadDosExe
;
	mov si,OFFSET demand_load
	mov di,OFFSET demand_load_name
	xor cl,cl
	mov ax,segment_not_present_nr
	RegisterOsGate
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code    ENDS

        END init
