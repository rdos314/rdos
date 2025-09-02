
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

#pragma aux ServCreateSslConnection = \
    ServGate_create_ssl_conn  \
    __parm [__ebx] [__edx] [__esi] [__edi] [__ecx]

#pragma aux ServDeleteSslConnection = \
    ServGate_delete_ssl_conn  \
    __parm [__ebx]

#pragma aux ServCreateSslListen = \
    ServGate_create_ssl_listen  \
    __parm [__ebx] [__esi] [__ecx]

#pragma aux ServDeleteSslListen = \
    ServGate_delete_ssl_listen  \
    __parm [__ebx]

#pragma aux ServAddSslListen = \
    ServGate_add_ssl_listen  \
    __parm [__ebx] [__eax]

#pragma aux ServSslStart = \
    ServGate_ssl_start  \
    __parm [__ebx]

#pragma aux ServSslStop = \
    ServGate_ssl_stop  \
    __parm [__ebx] [__eax]

#pragma aux ServSslInitStart = \
    ServGate_ssl_init_start  \
    __parm [__ebx] [__eax]

#pragma aux ServSslInitDone = \
    ServGate_ssl_init_done  \
    __parm [__ebx]

#pragma aux ServSslGetReceiveSpace = \
    ServGate_ssl_get_receive_space  \
    __parm [__ebx] \
    __value [__ecx]

#pragma aux ServSslAddReceiveBuf = \
    ServGate_ssl_add_receive_buf  \
    __parm [__ebx] [__edi] [__ecx]

#pragma aux ServSslGetSendCount = \
    ServGate_ssl_get_send_count  \
    __parm [__ebx] \
    __value [__ecx]

#pragma aux ServSslGetSendBuf = \
    ServGate_ssl_get_send_buf  \
    __parm [__ebx] [__edi] [__ecx] \
    __value [__ecx]

#pragma aux ServSslClearSendCount = \
    ServGate_ssl_clear_send_count  \
    __parm [__ebx] [__ecx]

#pragma aux ServSslWaitForChange = \
    ServGate_ssl_wait_for_change  \
    __parm [__ebx]

