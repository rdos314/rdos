#define serv_gate_invalid_serv 0x00000000
#define serv_gate_test_serv 0x00000001
#define serv_gate_get_vfs_handle 0x00000002
#define serv_gate_get_vfs_sectors 0x00000003
#define serv_gate_create_vfs_req 0x00000004
#define serv_gate_close_vfs_req 0x00000005
#define serv_gate_req_vfs_sectors 0x00000006
#define serv_gate_start_vfs_req 0x00000007
#define serv_gate_is_vfs_req_done 0x00000008
#define serv_gate_add_wait_for_vfs_req 0x00000009

#define ServGate_invalid_serv 0x55 0x67 0x9a 0 0 0 0 4 0 0x5d
#define ServGate_test_serv 0x55 0x67 0x9a 1 0 0 0 4 0 0x5d
#define ServGate_get_vfs_handle 0x55 0x67 0x9a 2 0 0 0 4 0 0x5d
#define ServGate_get_vfs_sectors 0x55 0x67 0x9a 3 0 0 0 4 0 0x5d
#define ServGate_create_vfs_req 0x55 0x67 0x9a 4 0 0 0 4 0 0x5d
#define ServGate_close_vfs_req 0x55 0x67 0x9a 5 0 0 0 4 0 0x5d
#define ServGate_req_vfs_sectors 0x55 0x67 0x9a 6 0 0 0 4 0 0x5d
#define ServGate_start_vfs_req 0x55 0x67 0x9a 7 0 0 0 4 0 0x5d
#define ServGate_is_vfs_req_done 0x55 0x67 0x9a 8 0 0 0 4 0 0x5d
#define ServGate_add_wait_for_vfs_req 0x55 0x67 0x9a 9 0 0 0 4 0 0x5d

