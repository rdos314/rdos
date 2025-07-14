;
; VFSDISC.ASM
; VFS disc
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
include ..\os\exec.def
include vfs.inc

    .386p

MAX_DISC_COUNT   =  16

vfs_cmd      STRUC

vc_prev            DW ?
vc_next            DW ?
vc_thread          DW ?
vc_op              DW ?

vc_eflags          DD ?
vc_eax             DD ?
vc_ebx             DD ?
vc_ecx             DD ?
vc_edx             DD ?
vc_esi             DD ?
vc_edi             DD ?
vc_fs              DW ?
vc_gs              DW ?

vfs_cmd      ENDS


data    SEGMENT byte public 'DATA'

disc_arr        DW MAX_DISC_COUNT DUP (?)

disc_wait_thread   DW ?
pending_count      DW ?
assign_thread      DW ?
init_completed     DW ?

data    ENDS


;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern InvalidateCache:near
    extern StopPartitions:near
    extern StopRequests:near
    extern DiscReadIo:near
    extern DiscWriteIo:near

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

    public CreateDiscSel

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
    mov es:vfs_cached_pages,0
    mov es:vfs_part_thread,0
    mov es:vfs_part_done,0
;
; test only
;
    mov es:vfs_max_cached_pages,1500
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
;       NAME:           FindVfsHandle
;
;       DESCRIPTION:    Find VFS handle
;
;       PARAMETERS:     BX          Prog id
;
;       RETURNS:        EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FindVfsHandle

FindVfsHandle    Proc near
    push ds
    push es
    push fs
    push eax
    push esi
;
    mov ax,SEG data
    mov fs,ax

fvhRetry:
    xor esi,esi
    mov ecx,MAX_DISC_COUNT

fvhDiscLoop:
    mov ax,fs:[2*esi].disc_arr
    or ax,ax
    jz fvhDiscNext
;
    mov ds,ax
    cmp bx,ds:vfs_app_sel
    jne fvhCheckPart
;
    xor ebx,ebx
    jmp fvhFound

fvhCheckPart:
    push esi
    push ecx
;
    xor esi,esi
    mov ecx,MAX_VFS_PARTITIONS

fvhPartLoop:
    mov ax,ds:[2*esi].vfs_part_arr
    or ax,ax
    jz fvhPartNext
;
    mov es,ax
    cmp bx,es:vfsp_app_sel
    jne fvhPartNext
;
    inc esi
    mov ebx,esi
;
    pop ecx
    pop esi
    jmp fvhFound
    
fvhPartNext:
    inc esi
    loop fvhPartLoop
;
    pop ecx
    pop esi

fvhDiscNext:
    inc esi
    loop fvhDiscLoop
;
    mov ax,10
    WaitMilliSec
    jmp fvhRetry

fvhFound:
    mov ax,si
    inc ax
    mov bh,al
    or ebx,VFS_HANDLE_SIG SHL 24
;
    pop esi
    pop eax
    pop fs
    pop es
    pop ds
    ret
FindVfsHandle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleToDisc
;
;       DESCRIPTION:    Convert from handle to disc sel
;
;       PARAMETERS:     AL          Disc part of handle
;
;       RETURNS:        AX          Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HandleToDisc

HandleToDisc    Proc near
    push ds
    push ebx
;
    or al,al
    jz htdFail
;
    mov bx,SEG data
    mov ds,ebx
;
    movzx ebx,al
    dec ebx
    cmp ebx,MAX_DISC_COUNT
    jae htdFail
;
    mov ax,ds:[2*ebx].disc_arr
    or ax,ax
    jz htdFail
;
    clc
    jmp htdDone

htdFail:
    stc
    
htdDone:
    pop ebx
    pop ds
    ret
HandleToDisc    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleToPartEs
;
;       DESCRIPTION:    Convert from handle to partition selector
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        ES          VFS part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HandleToPartEs

HandleToPartEs    Proc near
    push eax
    push esi
;
    or bh,bh
    jz htpeFail
;
    mov eax,ebx
    shr eax,24
    cmp al,VFS_HANDLE_SIG
    jne htpeFail
;
    mov ax,SEG data
    mov es,ax
    movzx eax,bh
    dec ax
    cmp ax,MAX_DISC_COUNT
    jb htpeInRange

htpeFail:
    stc
    jmp htpeDone

htpeInRange:
    movzx esi,bh
    dec esi
    mov ax,es:[2*esi].disc_arr
    or ax,ax
    jz htpeFail
;
    mov es,eax
    movzx esi,bl
    or esi,esi
    jz htpeDisc
;
    dec esi
    mov ax,es:[2*esi].vfs_part_arr
    jmp htpeValidate

htpeDisc:
    mov ax,es:vfs_my_part

htpeValidate:
    or ax,ax
    jz htpeFail
;
    mov es,ax
    test es:vfsp_flag,VFSP_FLAG_STOPPED
    jnz htpeFail
;
    clc

htpeDone:
    pop esi
    pop eax
    ret
HandleToPartEs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleToPartFs
;
;       DESCRIPTION:    Convert from handle to partition selector
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        FS          VFS part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HandleToPartFs

HandleToPartFs    Proc near
    push eax
    push esi
;
    or bh,bh
    jz htpfFail
;
    mov eax,ebx
    shr eax,24
    cmp al,VFS_HANDLE_SIG
    jne htpfFail
;
    mov ax,SEG data
    mov fs,ax
    movzx eax,bh
    dec ax
    cmp ax,MAX_DISC_COUNT
    jb htpfInRange

htpfFail:
    stc
    jmp htpfDone

htpfInRange:
    movzx esi,bh
    dec esi
    mov ax,fs:[2*esi].disc_arr
    or ax,ax
    jz htpfFail
;
    mov fs,eax
    movzx esi,bl
    or esi,esi
    jz htpfDisc
;
    dec esi
    mov ax,fs:[2*esi].vfs_part_arr
    jmp htpfValidate

htpfDisc:
    mov ax,fs:vfs_my_part

htpfValidate:
    or ax,ax
    jz htpfFail
;
    mov fs,ax
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz htpfFail
;
    clc

htpfDone:
    pop esi
    pop eax
    ret
HandleToPartFs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlinkPartEs
;
;       DESCRIPTION:    Unlink part ES and return part sel
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        ES          VFS part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public UnlinkPartEs

UnlinkPartEs    Proc near
    push eax
    push esi
;
    or bh,bh
    jz upeFail
;
    mov eax,ebx
    shr eax,24
    cmp al,VFS_HANDLE_SIG
    jne upeFail
;
    mov ax,SEG data
    mov es,ax
    movzx eax,bh
    dec ax
    cmp ax,MAX_DISC_COUNT
    jb upeInRange

upeFail:
    stc
    jmp upeDone

upeInRange:
    movzx esi,bh
    dec esi
    mov ax,es:[2*esi].disc_arr
    or ax,ax
    jz upeFail
;
    mov es,eax
    movzx esi,bl
    or esi,esi
    jz upeFail
;
    dec esi
    xor ax,ax
    xchg ax,es:[2*esi].vfs_part_arr
;
    or ax,ax
    jz upeFail
;
    mov es,ax
    clc

upeDone:
    pop esi
    pop eax
    ret
UnlinkPartEs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FileHandleToPartFs
;
;       DESCRIPTION:    Convert from file handle to partition selector
;
;       PARAMETERS:     EBX         File handle
;
;       RETURNS:        FS          VFS part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FileHandleToPartFs

FileHandleToPartFs    Proc near
    push eax
    push ebx
    push esi
;
    mov ax,SEG data
    mov fs,ax
    shr ebx,16
    movzx eax,bh
    dec ax
    cmp ax,MAX_DISC_COUNT
    jb fhtpfInRange

fhtpfFail:
    stc
    jmp fhtpfDone

fhtpfInRange:
    movzx esi,bh
    dec esi
    mov ax,fs:[2*esi].disc_arr
    or ax,ax
    jz fhtpfFail
;
    mov fs,eax
    movzx esi,bl
    or esi,esi
    jz fhtpfFail
;
    dec esi
    mov ax,fs:[2*esi].vfs_part_arr
    or ax,ax
    jz fhtpfFail
;
    mov fs,ax
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz fhtpfFail
;
    clc

fhtpfDone:
    pop esi
    pop ebx
    pop eax
    ret
FileHandleToPartFs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleDiscMsg
;
;       DESCRIPTION:    Handle disc msg
;
;       PARAMETERS:     DS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HandleDiscMsg

HandleDiscMsg  Proc near
    GetThread
    mov ds:vfs_cmd_thread,ax

hdLoop:
    test ds:vfs_flags,VFS_FLAG_STOPPED
    jnz hdExit
;
    WaitForSignal
    test ds:vfs_flags,VFS_FLAG_STOPPED
    jnz hdExit

hdRetry:
    mov eax,ds:vfs_cached_pages
    cmp eax,ds:vfs_max_cached_pages
    jb hdCheckCmd
;
    call InvalidateCache

hdCheckCmd:
    test ds:vfs_flags,VFS_FLAG_STOPPED
    jnz hdExit
;
    mov eax,ds:vfs_cached_pages
    cmp eax,ds:vfs_max_cached_pages
    jb hdLoop
    jmp hdRetry

hdExit:
    call StopPartitions
    call StopRequests
    mov al,ds:vfs_disc_nr
    RemoveVfsDisc
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    shl bx,1
    mov ds:[bx].disc_arr,0
    int 3
    ret
HandleDiscMsg  Endp

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
    push fs
    push ebx
    push ecx
    push esi
    push edi
    push ebp
;
    push bx
    mov bx,SEG data
    mov ds,bx
    mov bx,flat_sel
    mov fs,bx
    pop bx
    movzx ebx,bx
    shl ebx,1
    mov bx,ds:[ebx].disc_arr
    or bx,bx
    stc
    jz rvdDone
;
    call DiscReadIo

rvdDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop fs
    pop ds
    ret
read_vfs_disc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteVfsDisc
;
;       DESCRIPTION:    Write VFS disc
;
;       PARAMETERS:     BL              Disc #
;                       EDX:EAX         Sector
;                       ES:EDI          Buffer
;                       ECX             Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_vfs_disc_name       DB 'Write VFS Disc',0

write_vfs_disc    Proc far
    push ds
    push fs
    push ebx
    push ecx
    push esi
    push edi
    push ebp
;
    push bx
    mov bx,SEG data
    mov ds,bx
    mov bx,flat_sel
    mov fs,bx
    pop bx
    movzx ebx,bx
    shl ebx,1
    mov bx,ds:[ebx].disc_arr
    or bx,bx
    stc
    jz wvdDone
;
    call DiscWriteIo

wvdDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop fs
    pop ds
    ret
write_vfs_disc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsVfsDisc
;
;       DESCRIPTION:    Check if VFS disc
;
;       PARAMETERS:     AL              Disc #
;
;       RETURNS:        NC              VFS disc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_vfs_disc_name       DB 'Is Vfs Disc',0

is_vfs_disc    Proc far
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
    jz ivdDone
;
    clc

ivdDone:
    pop ebx
    pop ds
    ret
is_vfs_disc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetDiscCache
;
;       DESCRIPTION:    Get current size of disc cache
;
;       PARAMETERS:     AL              Disc #
;
;       RETURNS:        EDX:EAX         Size of disc cache in bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disc_cache_name       DB 'Get Disc Cache',0

get_disc_cache    Proc far
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
    jz gdcDone
;
    mov ds,bx
    mov eax,ds:vfs_cached_pages
    mov edx,1000h
    mul edx
    clc

gdcDone:
    pop ebx
    pop ds
    ret
get_disc_cache   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetDiscLocked
;
;       DESCRIPTION:    Get currently locked size
;
;       PARAMETERS:     AL              Disc #
;
;       RETURNS:        EDX:EAX         Locked size in bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disc_locked_name       DB 'Get Disc Locked',0

get_disc_locked    Proc far
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
    jz gdlDone
;
    mov ds,bx
    mov eax,ds:vfs_locked_pages
    mov edx,1000h
    mul edx
    clc

gdlDone:
    pop ebx
    pop ds
    ret
get_disc_locked   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           BeginVfsDisc
;
;       DESCRIPTION:    Begin VFS detect
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

begin_vfs_disc_name       DB 'Begin VFS Disc',0

begin_vfs_disc    Proc far
    push ds
    push eax
;
    mov eax,sEG data
    mov ds,eax
    inc ds:pending_count
;
    pop eax
    pop ds
    ret
begin_vfs_disc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           EndVfsDisc
;
;       DESCRIPTION:    End VFS detect
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

end_vfs_disc_name       DB 'End VFS Disc',0

end_vfs_disc    Proc far
    push ds
    push eax
    push ebx
;
    mov eax,sEG data
    mov ds,eax
    sub ds:pending_count,1
    jnz evdDone
;
    mov bx,ds:disc_wait_thread
    or bx,bx
    jz evdDone
;
    Signal

evdDone:
    pop ebx
    pop eax
    pop ds
    ret
end_vfs_disc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitParts
;
;       DESCRIPTION:    Initialize partitions
;
;       PARAMETERS:     EBX         VFS handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_parts_name       DB 'Init VFS Parts',0

init_parts    Proc far
    push ds
    push es
    push fs
    pushad
;
    or bh,bh
    jz ipsDone
;
    mov eax,ebx
    shr eax,24
    cmp al,VFS_HANDLE_SIG
    jne ipsDone
;
    mov ax,SEG data
    mov ds,ax
    movzx eax,bh
    dec ax
    cmp ax,MAX_DISC_COUNT
    jae ipsDone
;
    mov ax,ds:[2*eax].disc_arr
    or ax,ax
    jz ipsDone
;
    mov es,eax
    GetThread
    mov es:vfs_part_thread,ax
;
    mov bx,ds:disc_wait_thread
    or bx,bx
    jz ipsIdle
;
    Signal
    jmp ipsWait

ipsIdle:
    mov ax,ds:init_completed
    or ax,ax
    jz ipsWait

ipsStart:
    call StartPendHandler

ipsWait:
    WaitForSignal
;
    mov ax,es:vfs_part_thread
    or ax,ax
    jnz ipsWait

ipsDone:
    popad
    pop fs
    pop es
    pop ds
    ret
init_parts   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DoneParts
;
;       DESCRIPTION:    Partitions done
;
;       PARAMETERS:     EBX         VFS handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

done_parts_name       DB 'VFS Parts Done',0

done_parts    Proc far
    push ds
    push es
    push fs
    pushad
;
    or bh,bh
    jz dpsDone
;
    mov eax,ebx
    shr eax,24
    cmp al,VFS_HANDLE_SIG
    jne dpsDone
;
    mov ax,SEG data
    mov ds,ax
    movzx eax,bh
    dec ax
    cmp ax,MAX_DISC_COUNT
    jae dpsDone
;
    mov ax,ds:[2*eax].disc_arr
    or ax,ax
    jz dpsDone
;
    mov es,eax
    mov es:vfs_part_done,1
;
    mov bx,ds:assign_thread
    or bx,bx
    jz dpsDone
;
    Signal

dpsDone:
    popad
    pop fs
    pop es
    pop ds
    ret
done_parts   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CheckPendDisc
;
;       DESCRIPTION:    Check if any disc is pending
;
;       PARAMETERS:     DS	Data seg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckPendDisc   Proc near
    push es
    push eax
    push ecx
    push esi
;
    mov ecx,MAX_DISC_COUNT
    mov esi, OFFSET disc_arr

cpdLoop:
    lodsw
    or ax,ax
    jz cpdNext
;
    mov es,eax
    mov ax,es:vfs_part_done
    or ax,ax
    jnz cpdNext
;
    mov ax,es:vfs_part_thread
    or ax,ax
    jnz cpdNext
;
    stc
    jmp cpdDone

cpdNext:
    loop cpdLoop
;

    clc

cpdDone:
    pop esi
    pop ecx
    pop eax
    pop es
    ret
CheckPendDisc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AssignPendDisc
;
;       DESCRIPTION:    Assign drives to pending discs
;
;       PARAMETERS:     DS	Data seg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AssignPendDisc   Proc near
    push es
    push eax
    push ebx
    push ecx
    push esi
;
    mov ecx,MAX_DISC_COUNT
    mov esi, OFFSET disc_arr

apdLoop:
    lodsw
    or ax,ax
    jz apdNext
;
    mov es,eax
    mov ax,es:vfs_part_done
    or ax,ax
    jnz apdNext
;
    GetThread
    mov ds:assign_thread,ax
;
    xor bx,bx
    xchg bx,es:vfs_part_thread

apdRetry:
    Signal
;
    WaitForSignal
    mov ax,es:vfs_part_done
    or ax,ax
    jz apdRetry
;
    mov ds:assign_thread,0

apdNext:
    loop apdLoop

apdDone:
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
AssignPendDisc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandlePendDiscs
;
;       DESCRIPTION:    Handle pending discs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandlePendDiscs   Proc near
    push ds
    push eax
    push ebx

wfdRetry:
    mov ax,ds:pending_count
    or ax,ax
    jz wfdPendOk

wfdWait:
    WaitForSignal
    jmp wfdRetry

wfdPendOk:
    call CheckPendDisc
    jc wfdWait
;
    mov ds:disc_wait_thread,0
    ClearSignal
    call AssignPendDisc
;
    pop ebx
    pop eax
    pop ds
    ret
HandlePendDiscs   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartPendHandler
;
;       DESCRIPTION:    Start pending disc handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pend_handler_name   DB 'Pending Discs', 0

pend_handler:
    mov ax,SEG data
    mov ds,eax
    GetThread
    xchg ax,ds:disc_wait_thread
    or ax,ax
    jnz phExit
;
    call HandlePendDiscs

phExit:
    TerminateThread

StartPendHandler   Proc near
    push ds
    push es
    pushad
;
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET pend_handler
    mov edi,OFFSET pend_handler_name
    mov al,2
    CreateThread
;
    popad
    pop es
    pop ds
    ret
StartPendHandler  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForVfsDiscs
;
;       DESCRIPTION:    Wait for VFS discs to be completed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_vfs_discs_name       DB 'Wait For VFS Discs',0

wait_for_vfs_discs    Proc far
    push ds
    push eax
    push ebx
;
    mov ax,SEG data
    mov ds,eax
    GetThread
    mov ds:disc_wait_thread,ax
;
    call HandlePendDiscs
;
    mov ds:init_completed,1
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ax,ds:pf_cur_dir_sel
    or ax,ax
    jnz wfdDirOk
;
    CreateCurDir
    mov ds:pf_cur_dir_sel,ax

wfdDirOk:
    StartPrograms
;
    pop ebx
    pop eax
    pop ds
    ret
wait_for_vfs_discs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init_disc
;
;       description:    Init disc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_disc

init_disc    Proc near
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    mov edi,OFFSET disc_arr
    mov ecx,MAX_DISC_COUNT
    xor ax,ax
    rep stos word ptr es:[edi]
;
    mov es:disc_wait_thread,0
    mov es:assign_thread,0
    mov es:pending_count,0
    mov es:init_completed,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET begin_vfs_disc
    mov edi,OFFSET begin_vfs_disc_name
    xor cl,cl
    mov ax,begin_vfs_disc_nr
    RegisterOsGate
;
    mov esi,OFFSET end_vfs_disc
    mov edi,OFFSET end_vfs_disc_name
    xor cl,cl
    mov ax,end_vfs_disc_nr
    RegisterOsGate
;
    mov esi,OFFSET wait_for_vfs_discs
    mov edi,OFFSET wait_for_vfs_discs_name
    xor cl,cl
    mov ax,wait_for_vfs_discs_nr
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
    mov esi,OFFSET write_vfs_disc
    mov edi,OFFSET write_vfs_disc_name
    xor cl,cl
    mov ax,write_vfs_disc_nr
    RegisterOsGate
;
    mov esi,OFFSET init_parts
    mov edi,OFFSET init_parts_name
    xor cl,cl
    mov ax,vfs_init_parts_nr
    RegisterServGate
;
    mov esi,OFFSET done_parts
    mov edi,OFFSET done_parts_name
    xor cl,cl
    mov ax,vfs_done_parts_nr
    RegisterServGate
;
    mov esi,OFFSET is_vfs_disc
    mov edi,OFFSET is_vfs_disc_name
    xor dx,dx
    mov ax,is_vfs_disc_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_disc_cache
    mov edi,OFFSET get_disc_cache_name
    xor dx,dx
    mov ax,get_disc_cache_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_disc_locked
    mov edi,OFFSET get_disc_locked_name
    xor dx,dx
    mov ax,get_disc_locked_nr
    RegisterBimodalUserGate
    ret
init_disc    Endp


code    ENDS

    END
