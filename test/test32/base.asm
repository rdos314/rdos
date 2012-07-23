include \rdos\kernel\user.def
include \rdos\kernel\user.inc

.386

section_struc   STRUC

handle  DD ?
val     DD ?
owner   DD ?
count   DD ?

section_struc   ENDS

.code

    public CreateSection_

CreateSection_    Proc 
    push eax
    push edx
;    
    CreateSectionHandle
    mov eax,16
    AllocateAppMem
    xor eax,eax
    mov [edx].handle,ebx
    mov [edx].val,eax
    mov [edx].owner,eax
    mov [edx].count,eax
    mov ebx,edx
;
    pop edx
    pop eax    
    ret
CreateSection_    Endp

end

