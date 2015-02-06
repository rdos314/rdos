 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2015, Leif Ekblad
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
; RDOS.ASM
; 64-bit UEFI loader for RDOS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

format pe64 dll efi
entry main

include "uefiproto.inc"
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           uefi_call_wrapper
;
;   DESCRIPTION:    Invoke UEFI function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

macro uefi_call_wrapper			interface,function,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11
{
numarg = 0
if ~ arg11 eq
 numarg = numarg + 1
 if ~ arg11 eq rdi
		mov	rdi, arg11
 end if
end if
if ~ arg10 eq
 numarg = numarg + 1
 if ~ arg10 eq rsi
		mov	rsi, arg10
 end if
end if
if ~ arg9 eq
 numarg = numarg + 1
 if ~ arg9 eq r14
		mov	r14, arg9
 end if
end if
if ~ arg8 eq
 numarg = numarg + 1
 if ~ arg8 eq r13
		mov	r13, arg8
 end if
end if
if ~ arg7 eq
 numarg = numarg + 1
 if ~ arg7 eq r12
		mov	r12, arg7
 end if
end if
if ~ arg6 eq
 numarg = numarg + 1
 if ~ arg6 eq r11
		mov	r11, arg6
 end if
end if
if ~ arg5 eq
 numarg = numarg + 1
 if ~ arg5 eq r10
		mov	r10, arg5
 end if
end if
if ~ arg4 eq
 numarg = numarg + 1
 if ~ arg4 eq r9
		mov	r9, arg4
 end if
end if
if ~ arg3 eq
 numarg = numarg + 1
 if ~ arg3 eq r8
		mov	r8, arg3
 end if
end if
if ~ arg2 eq
 numarg = numarg + 1
 if ~ arg2 eq rdx
		mov	rdx, arg2
 end if
end if
if ~ arg1 eq
 numarg = numarg + 1
 if ~ arg1 eq rcx
  if ~ arg1 in <ConsoleInHandle,ConIn,ConsoleOutHandle,ConOut,StandardErrorHandle,StdErr,RuntimeServices,BootServices>
		mov	rcx, arg1
  end if
 end if
end if
		xor	rax, rax
		mov	al, numarg
if interface in <ConsoleInHandle,ConIn,ConsoleOutHandle,ConOut,StandardErrorHandle,StdErr,RuntimeServices,BootServices>
		mov	rbx, [efi_ptr]
		mov	rbx, [rbx + EFI_SYSTEM_TABLE.#interface]
else
 if ~ interface eq rbx
		mov	rbx, interface
 end if
end if
if arg1 in <ConsoleInHandle,ConIn,ConsoleOutHandle,ConOut,StandardErrorHandle,StdErr,RuntimeServices,BootServices>
		mov	rcx, rbx
end if
if defined SIMPLE_INPUT_INTERFACE.#function
		mov	rbx, [rbx + SIMPLE_INPUT_INTERFACE.#function]
else
 if defined SIMPLE_TEXT_OUTPUT_INTERFACE.#function
		mov	rbx, [rbx + SIMPLE_TEXT_OUTPUT_INTERFACE.#function]
 else
  if defined EFI_BOOT_SERVICES_TABLE.#function
		mov	rbx, [rbx + EFI_BOOT_SERVICES_TABLE.#function]
  else
   if defined EFI_RUNTIME_SERVICES_TABLE.#function
		mov	rbx, [rbx + EFI_RUNTIME_SERVICES_TABLE.#function]
   else
    if defined EFI_GRAPHICS_OUTPUT_PROTOCOL.#function
		mov	rbx, [rbx + EFI_GRAPHICS_OUTPUT_PROTOCOL.#function]
    else
     if defined EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE.#function
		mov	rbx, [rbx + EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE.#function]
     else
		mov	rbx, [rbx + function]
     end if
    end if
   end if
  end if
 end if
end if
	call uefifunc
}

section '.text' code executable readable
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           uefifunc
;
;   DESCRIPTION:    Call UEFI function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uefifunc:	
;save stack pointer
    mov	qword [uefi_rsptmp], rsp
;set up new aligned stack
	and esp, 0FFFFFFF0h
;alignment check on arguments
	bt eax, 0
	jnc	@f
	push rax
;arguments
@@:		
    cmp	al, 11
	jb @f
	push rdi
@@:		
    cmp al, 10
	jb @f
	push rsi
@@:		
    cmp al, 9
	jb @f
	push r14
@@:		
    cmp al, 8
	jb @f
	push r13
@@:		
    cmp al, 7
	jb @f
	push r12
@@:		
    cmp	al, 6
	jb @f
	push r11
@@:		
    cmp	al, 5
	jb @f
	push r10
@@:		
;space for
;r9
;r8
;rdx
;rcx
	sub rsp, 4*8
;call function
	call rbx
;restore old stack
	mov	rsp, qword [uefi_rsptmp]
	ret
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           main
;
;   DESCRIPTION:    Entrypoint
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

main:
	clc
	or rdx, rdx
	jz .badout
	cmp	dword [rdx], 20494249h
	je @f
.badout:	
    xor	rcx, rcx
	xor	rdx, rdx
	jc efiexit.return

@@:		
    mov	[efi_handler], rcx		; ImageHandle
	mov	[efi_ptr], rdx    		; pointer to SystemTable

;return to caller (if possible)
efiexit:	
    uefi_call_wrapper	ConOut, Reset, ConOut
	xor	rdx, rdx
	inc	rdx
	uefi_call_wrapper	ConOut, EnableCursor, ConOut, rdx
	uefi_call_wrapper	BootServices, Exit, qword [efi_handler], EFI_SUCCESS
efiexit.return: 
    xor	rax, rax
	retn

section '.data' data readable writeable

efi_handler:	dq 0
efi_ptr:	    dq 0
uefi_rsptmp:	dq 0

; section '.reloc' fixups data discardable
