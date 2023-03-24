
/* 32-bit compiler */

// check carry flag, and set eax=0 if set and eax=1 if clear
#define CarryToBool 0x73 4 0x33 0xC0 0xEB 5 0xB8 1 0 0 0

// check carry flag, and set ebx=0 if set and ebx=bx if clear
#define ValidateHandle 0x73 2 0x33 0xDB 0xF 0xB7 0xDB

// check carry flag, and set eax=0 if set
#define ValidateEax 0x73 2 0x33 0xC0

// check carry flag, and set ecx=0 if set
#define ValidateEcx 0x73 2 0x33 0xC9

// check carry flag, and set edx=0 if set
#define ValidateEdx 0x73 2 0x33 0xD2

// check carry flag, and set esi=0 if set
#define ValidateEsi 0x73 2 0x33 0xF6

// check carry flag, and set edi=0 if set
#define ValidateEdi 0x73 2 0x33 0xFF

// check disc id, set to -1 on carry, extend to eax
#define ValidateDisc 0x73 2 0xB0 0xFF 0xF 0xBE 0xC0

#pragma aux ServCreateShareBlock = \
    ServGate_create_serv_share_block  \
    __value [__edx]

#pragma aux ServFreeShareBlock = \
    ServGate_free_serv_share_block  \
    __parm [__edx]

#pragma aux ServGrowShareBlock = \
    ServGate_grow_serv_share_block  \
    __parm [__edx] \
    __value [__edx]

#pragma aux ServForkShareBlock = \
    ServGate_fork_serv_share_block  \
    __parm [__edx] \
    __value [__edx]

#pragma aux ServOpenVfsFile = \
    ServGate_serv_open_file  \
    __parm [__ebx] [__edx] [__ecx] \
    __value [__ebx]

#pragma aux ServCloseVfsFile = \
    ServGate_serv_close_file  \
    __parm [__ebx]

#pragma aux ServAddVfsFileReq = \
    ServGate_serv_add_file_req  \
    CarryToBool \
    __parm [__ebx] [__edx] [__edi] [__ecx] \
    __value [__eax]

#pragma aux ServFreeVfsFileReq = \
    ServGate_serv_free_file_req  \
    __parm [__ebx] [__edx]

#pragma aux ServWaitVfsFileQueue = \
    ServGate_serv_wait_file_queue  \
    __parm [__ebx]

#pragma aux ServVfsFileReqCount = \
    ServGate_serv_file_info  \
    __parm [__ebx] \
    __modify [__ebx __ecx __edx] \
    __value [__eax]

#pragma aux ServVfsFileWaitCount = \
    ServGate_serv_file_info  \
    __parm [__ebx] \
    __modify [__eax __ecx __edx] \
    __value [__ebx]

#pragma aux ServVfsFileBlockCount = \
    ServGate_serv_file_info  \
    __parm [__ebx] \
    __modify [__eax __ebx __edx] \
    __value [__ecx]

#pragma aux ServVfsFilePhysCount = \
    ServGate_serv_file_info  \
    __parm [__ebx] \
    __modify [__eax __ebx __ecx] \
    __value [__edx]

#pragma aux ServTest = \
    ServGate_test_serv

#pragma aux ServGetVfsHandle = \
    ServGate_get_vfs_handle  \
    __value [__ebx]

#pragma aux ServGetVfsDisc = \
    ServGate_get_vfs_disc_part  \
    "movzx eax,ah" \
    __parm [__ebx] \
    __value [__eax]

#pragma aux ServGetVfsPart = \
    ServGate_get_vfs_disc_part  \
    "movzx eax,al" \
    __parm [__ebx] \
    __value [__eax]

#pragma aux ServGetVfsStartSector = \
    ServGate_get_vfs_start_sector  \
    __parm [__ebx] \
    __value [__edx __eax]

#pragma aux ServGetVfsSectors = \
    ServGate_get_vfs_sectors  \
    __parm [__ebx] \
    __value [__edx __eax]

#pragma aux ServGetVfsBytesPerSector = \
    ServGate_get_vfs_bytes_per_sector  \
    "movzx eax,ax" \
    __parm [__ebx] \
    __value [__eax]

#pragma aux ServIsVfsActive = \
    ServGate_is_vfs_active  \
    CarryToBool \
    __parm [__ebx] \
    __value [__eax]

#pragma aux ServStartVfsIoServer = \
    ServGate_start_vfs_io_serv  \
    __parm [__ebx] \
    __value [__edx]

#pragma aux ServCreateVfsReq = \
    ServGate_create_vfs_req  \
    __parm [__ebx] \
    __value [__ebx]

#pragma aux ServCloseVfsReq = \
    ServGate_close_vfs_req  \
    __parm [__ebx]

#pragma aux ServAddVfsSectors = \
    ServGate_add_vfs_sectors  \
    "jc fail" \
    "mov eax,ebx" \
    "jmp done" \
    "fail:" \
    "xor eax,eax" \
    "done:" \
    __parm [__ebx] [__edx __eax] [__ecx] \
    __value [__eax]

#pragma aux ServRemoveVfsSectors = \
    ServGate_remove_vfs_sectors  \
    __parm [__ebx] [__eax]

#pragma aux ServMapVfsReq = \
    ServGate_map_vfs_req  \
   __parm [__ebx] [__eax] \
    __value [__edx]

#pragma aux ServUnmapVfsReq = \
    ServGate_unmap_vfs_req  \
   __parm [__ebx] [__eax]

#pragma aux ServStartVfsReq = \
    ServGate_start_vfs_req  \
    __parm [__ebx]

#pragma aux ServIsVfsReqDone = \
    ServGate_is_vfs_req_done  \
    CarryToBool \
    __parm [__ebx]

#pragma aux ServAddWaitForVfsReq = \
    ServGate_add_wait_for_vfs_req  \
    __parm [__ebx] [__eax] [__ecx]
