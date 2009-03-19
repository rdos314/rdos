#include <stdio.h>

#define open_tcp_connection_nr  90
const char l = open_tcp_connection_nr / 0x100;

#define CallGate(gate) 0x0f 0x0b 0x0d (gate % 0x100) (gate / 0x100) 0 0

int RdosOpenTcpConnection(int RemoteIp, int LocalPort, int RemotePort, int Timeout, int BufferSize);

#pragma aux RdosOpenTcpConnection = \
    0x0f 0x0b 0x0d \
    l \
    open_tcp_connection_nr  \
    0 0  \
    "nop" \
    "movzx ebx,bx" \
    parm [edx] [esi] [edi] [eax] [ecx] \
    value [ebx];

void main()
{
    printf("hello world\r\r");
    RdosOpenTcpConnection(0xCCAA6677, 100, 21, 1000, 0x1000);
}
