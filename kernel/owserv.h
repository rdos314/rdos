
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


#pragma aux ServSignal = \
    ServGate_serv_signal  \
    __parm [__eax]

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
    __parm [__ebx] [__edx] \
    __value [__ebx]

#pragma aux ServUpdateVfsFile = \
    ServGate_serv_update_file  \
    __parm [__ebx]

#pragma aux ServCloseVfsFile = \
    ServGate_serv_close_file  \
    __parm [__ebx]

#pragma aux ServNotifyVfsFileReq = \
    ServGate_serv_notify_file_req  \
    __parm [__ebx] [__edx __eax] [__ecx]

#pragma aux ServVfsFileReadReq = \
    ServGate_serv_file_read_req  \
    __parm [__ebx] [__esi] [__edx __eax] [__edi] [__ecx] \
    __value [__ecx]

#pragma aux ServVfsFileWriteReq = \
    ServGate_serv_file_write_req  \
    __parm [__ebx] [__esi] [__edx __eax] [__edi] [__ecx] \
    __value [__ecx]

#pragma aux ServUpdateVfsFileReq = \
    ServGate_serv_update_file_req  \
    __parm [__ebx] [__edx] [__esi] [__ecx]

#pragma aux ServDisableVfsFileReq = \
    ServGate_serv_disable_file_req  \
    __parm [__ebx] [__edx]

#pragma aux ServFreeVfsFileReq = \
    ServGate_serv_free_file_req  \
    __parm [__ebx] [__edx]

#pragma aux ServWaitVfsIoServer = \
    ServGate_serv_wait_io_serv  \
    __parm [__ebx] [__edx]

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

#pragma aux ServGetVfsPartType = \
    ServGate_get_vfs_part_type  \
    __parm [__ebx] \
    __value [__eax]

#pragma aux ServGetVfsPartDrive = \
    ServGate_get_vfs_part_drive  \
    __parm [__ebx] \
    __value [__al]

#pragma aux ServSetVfsStartSector = \
    ServGate_set_vfs_start_sector  \
    __parm [__ebx] [__edx __eax]

#pragma aux ServSetVfsSectors = \
    ServGate_set_vfs_sectors  \
    __parm [__ebx] [__edx __eax]

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

#pragma aux ServIsVfsBusy = \
    ServGate_is_vfs_busy  \
    CarryToBool \
    __parm [__ebx] \
    __value [__eax]

#pragma aux ServStartVfsIoServer = \
    ServGate_start_vfs_io_serv  \
    __parm [__ebx] [__edx]

#pragma aux ServStopVfsIoServer = \
    ServGate_stop_vfs_io_serv  \
    __parm [__ebx]

#pragma aux ServLoadVfsPartition = \
    ServGate_serv_load_part  \
    __parm [__ebx] [__ecx] [__edx __eax] [__edi __esi] \
    __value [__ebx]

#pragma aux ServDisableVfsPartition = \
    ServGate_serv_disable_part  \
    __parm [__ebx]

#pragma aux ServStartVfsPartition = \
    ServGate_serv_start_part  \
    __parm [__ebx]

#pragma aux ServStopVfsPartition = \
    ServGate_serv_stop_part  \
    __parm [__ebx]

#pragma aux ServCloseVfsPartition = \
    ServGate_serv_close_part  \
    __parm [__ebx]

#pragma aux ServFormatVfsPartition = \
    ServGate_serv_format_part \
    __parm [__ebx] \
    __value [__eax]

#pragma aux ServInitPartitions = \
    ServGate_vfs_init_parts \
    __parm [__ebx]

#pragma aux ServPartitionsDone = \
    ServGate_vfs_done_parts \
    __parm [__ebx]

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

#pragma aux ServLockVfsSectors = \
    ServGate_lock_vfs_sectors  \
    "jc fail" \
    "mov eax,ebx" \
    "jmp done" \
    "fail:" \
    "xor eax,eax" \
    "done:" \
    __parm [__ebx] [__edx __eax] [__ecx] \
    __value [__eax]

#pragma aux ServZeroVfsSectors = \
    ServGate_zero_vfs_sectors  \
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

#pragma aux ServWriteVfsSectors = \
    ServGate_write_vfs_sectors  \
   __parm [__ebx] [__edx __eax] [__ecx]

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


#pragma aux ServNotifyVfsMsg = \
    ServGate_notify_vfs_msg  \
    __parm [__ebx] [__edx]

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


#pragma aux ServUacpiGetAcpi = \
    ServGate_uacpi_get_acpi  \
    __value [__edx __eax]

#pragma aux ServUacpiMap = \
    ServGate_uacpi_map  \
    __parm [__edx __eax] [__ecx] \
    __value [_eax]

#pragma aux ServUacpiUnmap = \
    ServGate_uacpi_unmap  \
    __parm [__edx] [__ecx]

#pragma aux ServUacpiEnableIo = \
    ServGate_uacpi_enable_io  \
    __parm [__edx] [__ecx]

#pragma aux ServUacpiDisableIo = \
    ServGate_uacpi_disable_io  \
    __parm [__edx] [__ecx]
