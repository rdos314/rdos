
#define serv_gate_wait_for_ssl_cmd 0x00000001
#define serv_gate_reply_ssl_cmd 0x00000002
#define serv_gate_create_ssl_conn 0x00000003

#define serv_gate_ssl_start 0x00000004
#define serv_gate_ssl_stop 0x00000005

#define serv_gate_ssl_init_start 0x00000006
#define serv_gate_ssl_init_done 0x00000007
#define serv_gate_ssl_get_receive_space 0x00000008
#define serv_gate_ssl_add_receive_buf 0x00000009
#define serv_gate_ssl_get_send_count 0x0000000A
#define serv_gate_ssl_get_send_buf 0x0000000B
#define serv_gate_ssl_clear_send_count 0x0000000C
#define serv_gate_ssl_wait_for_change 0x0000000D

#define serv_gate_delete_ssl_conn 0x0000000E
#define serv_gate_create_ssl_listen 0x0000000F
#define serv_gate_delete_ssl_listen 0x00000010
#define serv_gate_add_ssl_listen 0x00000011

#define serv_gate_reply_ssl_data_cmd 0x00000012

#define ServGate_wait_for_ssl_cmd 0x55 0x67 0x9a 1 0 0 0 4 0 0x5d
#define ServGate_reply_ssl_cmd 0x55 0x67 0x9a 2 0 0 0 4 0 0x5d
#define ServGate_create_ssl_conn 0x55 0x67 0x9a 3 0 0 0 4 0 0x5d

#define ServGate_ssl_start 0x55 0x67 0x9a 4 0 0 0 4 0 0x5d
#define ServGate_ssl_stop 0x55 0x67 0x9a 5 0 0 0 4 0 0x5d

#define ServGate_ssl_init_start 0x55 0x67 0x9a 6 0 0 0 4 0 0x5d
#define ServGate_ssl_init_done 0x55 0x67 0x9a 7 0 0 0 4 0 0x5d
#define ServGate_ssl_get_receive_space 0x55 0x67 0x9a 8 0 0 0 4 0 0x5d
#define ServGate_ssl_add_receive_buf 0x55 0x67 0x9a 9 0 0 0 4 0 0x5d
#define ServGate_ssl_get_send_count 0x55 0x67 0x9a 10 0 0 0 4 0 0x5d
#define ServGate_ssl_get_send_buf 0x55 0x67 0x9a 11 0 0 0 4 0 0x5d
#define ServGate_ssl_clear_send_count 0x55 0x67 0x9a 12 0 0 0 4 0 0x5d
#define ServGate_ssl_wait_for_change 0x55 0x67 0x9a 13 0 0 0 4 0 0x5d

#define ServGate_delete_ssl_conn 0x55 0x67 0x9a 14 0 0 0 4 0 0x5d
#define ServGate_create_ssl_listen 0x55 0x67 0x9a 15 0 0 0 4 0 0x5d
#define ServGate_delete_ssl_listen 0x55 0x67 0x9a 16 0 0 0 4 0 0x5d
#define ServGate_add_ssl_listen 0x55 0x67 0x9a 17 0 0 0 4 0 0x5d

#define ServGate_reply_ssl_data_cmd 0x55 0x67 0x9a 18 0 0 0 4 0 0x5d
