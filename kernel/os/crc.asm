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
; CRC.ASM
; CRC calculation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.inc
INCLUDE ..\handle.inc

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

crc_handle_seg      STRUC

crc_handle_base     handle_header <>

crc_handle_sel      DW ?

crc_handle_seg      ENDS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateCrc
;
;           DESCRIPTION:    Creates CRC handle
;
;           PARAMETERS:     AX      CRC polynom
;
;           RETURNS:        BX              Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_crc_name DB 'Create CRC', 0

create_crc      Proc far
    push ds
    push es
    push cx
    push dx
    push si
;
    push eax
    mov eax,200h
    AllocateSmallGlobalMem    
    pop eax
;
    mov cx,SIZE crc_handle_seg
    AllocateHandle
    mov [ebx].crc_handle_sel,es
    mov [ebx].hh_sign,CRC_HANDLE
    mov bx,[ebx].hh_handle
;
    push bx
    xor cl,cl
    xor bx,bx
    
create_crc_loop:   
    xor dx,dx
    xor dh,cl
    shl dx,1
    jnc no_xor0
;
    xor dx,ax

no_xor0:
    shl dx,1
    jnc no_xor1
;
    xor dx,ax 

no_xor1:       
    shl dx,1
    jnc no_xor2
;
    xor dx,ax 

no_xor2:       
    shl dx,1
    jnc no_xor3
;
    xor dx,ax 

no_xor3:       
    shl dx,1
    jnc no_xor4
;
    xor dx,ax 

no_xor4:       
    shl dx,1
    jnc no_xor5
;
    xor dx,ax 

no_xor5:       
    shl dx,1
    jnc no_xor6
;
    xor dx,ax 

no_xor6:       
    shl dx,1
    jnc no_xor7
;
    xor dx,ax 

no_xor7:      
    mov es:[bx],dx
    add bx,2
    inc cx
    or cl,cl
    jnz create_crc_loop
; 
    pop bx      
    clc
;
    pop si
    pop dx
    pop cx
    pop es
    pop ds
    retf32
create_crc      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloseCrc
;
;           DESCRIPTION:    Close CRC handle
;
;           PARAMETERS:     BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_crc_name DB 'Close CRC', 0

close_crc       Proc far
    push ds
    push es
    push ebx
;
    mov ax,CRC_HANDLE
    DerefHandle
    jc close_crc_done
;
    mov es,[ebx].crc_handle_sel
    FreeMem    
    FreeHandle
    clc

close_crc_done:
    pop ebx
    pop es
    pop ds
    retf32
close_crc       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CalcCrc
;
;           DESCRIPTION:    Calculate CRC
;
;           PARAMETERS:         BX              Handle
;               AX      CRC in
;                           ES:(E)DI    Data
;                           (E)CX       Size
;
;           RETURNS:        AX      CRC out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

calc_crc_name   DB 'Calc CRC',0

calc_crc Proc near
    push ds
    push es
    push ebx
    push ecx
    push edi
;
    push ax
    mov ax,CRC_HANDLE
    DerefHandle
    pop ax
    jc calc_crc_done
;
    mov ds,[ebx].crc_handle_sel
    or ecx,ecx
    jz calc_crc_done
;
    xor ebx,ebx

calc_crc_loop:
    mov bl,es:[edi]
    xor bl,ah
    shl ax,8
    xor ax,ds:[2*ebx]
;
    inc edi
    sub ecx,1
    jnz calc_crc_loop    

calc_crc_done:
    pop edi
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
calc_crc    Endp

calc_crc32  Proc far
    call calc_crc
    retf32
calc_crc32  Endp

calc_crc16  Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call calc_crc
;
    pop edi
    pop ecx
    retf32
calc_crc16  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete_handle
;
;           DESCRIPTION:    Delete handle (called from handle module)
;
;           PARAMETERS:         BX          CRC HANDLE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push es
    push ebx
;
    mov ax,CRC_HANDLE
    DerefHandle
    jc delete_handle_done
;    
    mov es,[ebx].crc_handle_sel
    FreeMem
    FreeHandle
    clc

delete_handle_done:
    pop ebx
    pop es
    pop ds
    retf32
delete_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CalcCrc32
;
;       DESCRIPTION:    Calculate CRC32
;
;       PARAMETERS:     EAX         CRC in
;                       ES:(E)DI    Data
;                       (E)CX       Size
;
;       RETURNS:        EAX         CRC out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

calc_crc32_name   DB 'Calc CRC32',0

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

calc_crc32_base Proc near
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
calc_crc32_base   Endp

calc_crc32_32  Proc far
    call calc_crc32_base
    retf32
calc_crc32_32  Endp

calc_crc32_16  Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call calc_crc32_base
;
    pop edi
    pop ecx
    retf32
calc_crc32_16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_crc
    
init_crc    PROC near
    push ds
    push es
    pusha
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET delete_handle
    mov ax,CRC_HANDLE
    RegisterHandle
;
    mov esi,OFFSET create_crc
    mov edi,OFFSET create_crc_name
    xor dx,dx
    mov ax,create_crc_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_crc
    mov edi,OFFSET close_crc_name
    xor dx,dx
    mov ax,close_crc_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET calc_crc16
    mov esi,OFFSET calc_crc32
    mov edi,OFFSET calc_crc_name
    mov dx,virt_es_in
    mov ax,calc_crc_nr
    RegisterUserGate
;
    mov ebx,OFFSET calc_crc32_16
    mov esi,OFFSET calc_crc32_32
    mov edi,OFFSET calc_crc32_name
    mov dx,virt_es_in
    mov ax,calc_crc32_nr
    RegisterUserGate
;
    popa
    pop es
    pop ds      
    ret
init_crc    ENDP

code    ENDS

    END
