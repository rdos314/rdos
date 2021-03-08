#define share_gate_invalid_shared 0x00000000
#define share_gate_test_shared 0x00000001



#ifdef __FLAT__
#define ShareGate_invalid_shared 0x55 0x67 0x9a 0 0 0 0 4 0 0x5d
#define ShareGate_test_shared 0x55 0x67 0x9a 1 0 0 0 4 0 0x5d

#else
#define ShareGate_invalid_shared 0x3e 0x67 0x9a 0 0 0 0 4 0
#define ShareGate_test_shared 0x3e 0x67 0x9a 1 0 0 0 4 0

#endif
