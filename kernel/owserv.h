
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

#pragma aux ServTest = \
    ServGate_test_serv

#pragma aux ServGetVfsHandle = \
    ServGate_get_vfs_handle  \
    __value [__ebx]

#pragma aux ServGetVfsSectors = \
    ServGate_get_vfs_sectors  \
    __parm [__ebx] \
    __value [__edx __eax]

#pragma aux ServCreateVfsReq = \
    ServGate_create_vfs_req  \
    __parm [__ebx] \
    __value [__ebx]

#pragma aux ServCloseVfsReq = \
    ServGate_close_vfs_req  \
    __parm [__ebx]

#pragma aux ServReqVfsSectors = \
    ServGate_req_vfs_sectors  \
    __parm [__ebx] [__edx __eax] [__ecx] \
    __value [__ecx]
