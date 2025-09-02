#define serv_gate_invalid_serv 0x00000000
#define serv_gate_test_serv 0x00000001
#define serv_gate_get_vfs_handle 0x00000002
#define serv_gate_get_vfs_sectors 0x00000003
#define serv_gate_create_vfs_req 0x00000004
#define serv_gate_close_vfs_req 0x00000005
#define serv_gate_add_vfs_sectors 0x00000006
#define serv_gate_remove_vfs_sectors 0x00000007
#define serv_gate_start_vfs_req 0x00000008
#define serv_gate_is_vfs_req_done 0x00000009
#define serv_gate_add_wait_for_vfs_req 0x0000000A
#define serv_gate_map_vfs_req 0x0000000B
#define serv_gate_unmap_vfs_req 0x0000000C
#define serv_gate_wait_for_vfs_cmd 0x0000000D
#define serv_gate_is_vfs_active 0x0000000E
#define serv_gate_reply_vfs_cmd 0x0000000F
#define serv_gate_create_serv_share_block 0x00000010
#define serv_gate_free_serv_share_block 0x00000011
#define serv_gate_grow_serv_share_block 0x00000012
#define serv_gate_fork_serv_share_block 0x00000013
#define serv_gate_reply_vfs_block_cmd 0x00000014
#define serv_gate_reply_vfs_data_cmd 0x00000015
#define serv_gate_serv_open_file 0x00000016
#define serv_gate_serv_to_system_share_block 0x00000017
#define serv_gate_serv_file_read_req 0x00000018
#define serv_gate_reply_vfs_post 0x00000019
#define serv_gate_serv_close_file 0x0000001A
#define serv_gate_serv_free_file_req 0x0000001B
#define serv_gate_get_vfs_start_sector 0x0000001C
#define serv_gate_get_vfs_bytes_per_sector 0x0000001D
#define serv_gate_serv_file_info 0x0000001E
#define serv_gate_serv_wait_io_serv 0x0000001F
#define serv_gate_get_vfs_disc_part 0x00000020
#define serv_gate_start_vfs_io_serv 0x00000021
#define serv_gate_serv_notify_file_req 0x00000022
#define serv_gate_serv_load_part 0x00000023
#define serv_gate_serv_start_part 0x00000024
#define serv_gate_serv_stop_part 0x00000025
#define serv_gate_notify_vfs_msg 0x00000026
#define serv_gate_map_vfs_cmd_buf 0x00000027
#define serv_gate_unmap_vfs_cmd_buf 0x00000028
#define serv_gate_lock_vfs_sectors 0x00000029
#define serv_gate_zero_vfs_sectors 0x0000002A
#define serv_gate_write_vfs_sectors 0x0000002B
#define serv_gate_serv_disable_part 0x0000002C
#define serv_gate_stop_vfs_io_serv 0x0000002D
#define serv_gate_serv_close_part 0x0000002E
#define serv_gate_serv_format_part 0x0000002F
#define serv_gate_get_vfs_part_type 0x00000030
#define serv_gate_set_vfs_start_sector 0x00000031
#define serv_gate_set_vfs_sectors 0x00000032
#define serv_gate_is_vfs_busy 0x00000033
#define serv_gate_serv_file_write_req 0x00000034
#define serv_gate_serv_update_file_req 0x00000035

#define serv_gate_vfs_init_parts 0x00000036
#define serv_gate_vfs_done_parts 0x00000037
#define serv_gate_get_vfs_part_drive 0x00000038
#define serv_gate_serv_disable_file_req 0x00000039
#define serv_gate_serv_signal 0x0000003A
#define serv_gate_serv_update_file 0x0000003B

#define ServGate_invalid_serv 0x55 0x67 0x9a 0 0 0 0 4 0 0x5d
#define ServGate_test_serv 0x55 0x67 0x9a 1 0 0 0 4 0 0x5d
#define ServGate_get_vfs_handle 0x55 0x67 0x9a 2 0 0 0 4 0 0x5d
#define ServGate_get_vfs_sectors 0x55 0x67 0x9a 3 0 0 0 4 0 0x5d
#define ServGate_create_vfs_req 0x55 0x67 0x9a 4 0 0 0 4 0 0x5d
#define ServGate_close_vfs_req 0x55 0x67 0x9a 5 0 0 0 4 0 0x5d
#define ServGate_add_vfs_sectors 0x55 0x67 0x9a 6 0 0 0 4 0 0x5d
#define ServGate_remove_vfs_sectors 0x55 0x67 0x9a 7 0 0 0 4 0 0x5d
#define ServGate_start_vfs_req 0x55 0x67 0x9a 8 0 0 0 4 0 0x5d
#define ServGate_is_vfs_req_done 0x55 0x67 0x9a 9 0 0 0 4 0 0x5d
#define ServGate_add_wait_for_vfs_req 0x55 0x67 0x9a 10 0 0 0 4 0 0x5d
#define ServGate_map_vfs_req 0x55 0x67 0x9a 11 0 0 0 4 0 0x5d
#define ServGate_unmap_vfs_req 0x55 0x67 0x9a 12 0 0 0 4 0 0x5d
#define ServGate_wait_for_vfs_cmd 0x55 0x67 0x9a 13 0 0 0 4 0 0x5d
#define ServGate_is_vfs_active 0x55 0x67 0x9a 14 0 0 0 4 0 0x5d
#define ServGate_reply_vfs_cmd 0x55 0x67 0x9a 15 0 0 0 4 0 0x5d
#define ServGate_create_serv_share_block 0x55 0x67 0x9a 16 0 0 0 4 0 0x5d
#define ServGate_free_serv_share_block 0x55 0x67 0x9a 17 0 0 0 4 0 0x5d
#define ServGate_grow_serv_share_block 0x55 0x67 0x9a 18 0 0 0 4 0 0x5d
#define ServGate_fork_serv_share_block 0x55 0x67 0x9a 19 0 0 0 4 0 0x5d
#define ServGate_reply_vfs_block_cmd 0x55 0x67 0x9a 20 0 0 0 4 0 0x5d
#define ServGate_reply_vfs_data_cmd 0x55 0x67 0x9a 21 0 0 0 4 0 0x5d
#define ServGate_serv_open_file 0x55 0x67 0x9a 22 0 0 0 4 0 0x5d
#define ServGate_serv_to_system_share_block 0x55 0x67 0x9a 23 0 0 0 4 0 0x5d
#define ServGate_serv_file_read_req 0x55 0x67 0x9a 24 0 0 0 4 0 0x5d
#define ServGate_reply_vfs_post 0x55 0x67 0x9a 25 0 0 0 4 0 0x5d
#define ServGate_serv_close_file 0x55 0x67 0x9a 26 0 0 0 4 0 0x5d
#define ServGate_serv_free_file_req 0x55 0x67 0x9a 27 0 0 0 4 0 0x5d
#define ServGate_get_vfs_start_sector 0x55 0x67 0x9a 28 0 0 0 4 0 0x5d
#define ServGate_get_vfs_bytes_per_sector 0x55 0x67 0x9a 29 0 0 0 4 0 0x5d
#define ServGate_serv_file_info 0x55 0x67 0x9a 30 0 0 0 4 0 0x5d
#define ServGate_serv_wait_io_serv 0x55 0x67 0x9a 31 0 0 0 4 0 0x5d
#define ServGate_get_vfs_disc_part 0x55 0x67 0x9a 32 0 0 0 4 0 0x5d
#define ServGate_start_vfs_io_serv 0x55 0x67 0x9a 33 0 0 0 4 0 0x5d
#define ServGate_serv_notify_file_req 0x55 0x67 0x9a 34 0 0 0 4 0 0x5d
#define ServGate_serv_load_part 0x55 0x67 0x9a 35 0 0 0 4 0 0x5d
#define ServGate_serv_start_part 0x55 0x67 0x9a 36 0 0 0 4 0 0x5d
#define ServGate_serv_stop_part 0x55 0x67 0x9a 37 0 0 0 4 0 0x5d
#define ServGate_notify_vfs_msg 0x55 0x67 0x9a 38 0 0 0 4 0 0x5d
#define ServGate_map_vfs_cmd_buf 0x55 0x67 0x9a 39 0 0 0 4 0 0x5d
#define ServGate_unmap_vfs_cmd_buf 0x55 0x67 0x9a 40 0 0 0 4 0 0x5d
#define ServGate_lock_vfs_sectors 0x55 0x67 0x9a 41 0 0 0 4 0 0x5d
#define ServGate_zero_vfs_sectors 0x55 0x67 0x9a 42 0 0 0 4 0 0x5d
#define ServGate_write_vfs_sectors 0x55 0x67 0x9a 43 0 0 0 4 0 0x5d
#define ServGate_serv_disable_part 0x55 0x67 0x9a 44 0 0 0 4 0 0x5d
#define ServGate_stop_vfs_io_serv 0x55 0x67 0x9a 45 0 0 0 4 0 0x5d
#define ServGate_serv_close_part 0x55 0x67 0x9a 46 0 0 0 4 0 0x5d
#define ServGate_serv_format_part 0x55 0x67 0x9a 47 0 0 0 4 0 0x5d
#define ServGate_get_vfs_part_type 0x55 0x67 0x9a 48 0 0 0 4 0 0x5d
#define ServGate_set_vfs_start_sector 0x55 0x67 0x9a 49 0 0 0 4 0 0x5d
#define ServGate_set_vfs_sectors 0x55 0x67 0x9a 50 0 0 0 4 0 0x5d
#define ServGate_is_vfs_busy 0x55 0x67 0x9a 51 0 0 0 4 0 0x5d
#define ServGate_serv_file_write_req 0x55 0x67 0x9a 52 0 0 0 4 0 0x5d
#define ServGate_serv_update_file_req 0x55 0x67 0x9a 53 0 0 0 4 0 0x5d

#define ServGate_vfs_init_parts 0x55 0x67 0x9a 54 0 0 0 4 0 0x5d
#define ServGate_vfs_done_parts 0x55 0x67 0x9a 55 0 0 0 4 0 0x5d
#define ServGate_get_vfs_part_drive 0x55 0x67 0x9a 56 0 0 0 4 0 0x5d
#define ServGate_serv_disable_file_req 0x55 0x67 0x9a 57 0 0 0 4 0 0x5d
#define ServGate_serv_signal 0x55 0x67 0x9a 58 0 0 0 4 0 0x5d
#define ServGate_serv_update_file 0x55 0x67 0x9a 59 0 0 0 4 0 0x5d

