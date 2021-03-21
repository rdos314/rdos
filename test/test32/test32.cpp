#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "sockobj.h"

#define FALSE 0
#define TRUE !FALSE


/*##########################################################################
#
#   Name       : DecodeData
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DecodeData(const char *str, int size)
{
    const char *ptr = str;
    unsigned char uch;
    long double dval;
    int val;

    if (ptr[0] == 0x24 && ptr[1] == 0x6B)
    {
        memcpy(&uch, ptr + 2, 1);
        val = uch;
        memcpy(&uch, ptr + 3, 1);
        if (uch & 0x80)
             val += 0x100;
        printf("WindDir: %d ", val);

        val = (uch & 0xF) << 8;
        memcpy(&uch, ptr + 4, 1);
        val += uch;
        dval = ((long double)val - 400.0) / 10.0;
        printf("Temp: %4.1Lf ", dval);

        memcpy(&uch, ptr + 5, 1);
        val = uch;
        printf("Humidity: %d ", val);

        memcpy(&uch, ptr + 6, 1);
        val = uch;
        dval = (long double)val / 8.0 * 1.12;
        printf("WindSpeed: %4.1Lf ", dval);

        memcpy(&uch, ptr + 7, 1);
        val = uch;
        dval = (long double)val * 1.12;
        printf("Gust: %4.1Lf ", dval);

        memcpy(&uch, ptr + 8, 1);
        val = uch << 8;
        memcpy(&uch, ptr + 9, 1);
        val += uch;
        dval = (long double)val * 0.3;
        printf("Rain: %4.1Lf ", dval);

        memcpy(&uch, ptr + 10, 1);
        val = uch << 8;
        memcpy(&uch, ptr + 11, 1);
        val += uch;
        dval = (long double)val * 0.01;
        printf("UV: %5.2Lf ", dval);

        memcpy(&uch, ptr + 12, 1);
        val = uch << 16;
        memcpy(&uch, ptr + 13, 1);
        val += uch << 8;
        memcpy(&uch, ptr + 14, 1);
        val += uch;
        dval = (long double)val * 0.1;
        printf("Light: %5.1Lf ", dval);


        printf("\r\n");
    }
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void main()
{
    long ip = 0x3901A8C0;
    TTcpSocket *socket;
    int size;
    char buf[40];
    char str[10];
    char ch;

    socket = new TTcpSocket(ip, 1234, 5000, 0x2000);
    socket->WaitForConnection(5000);

    if (socket->IsOpen())
        while (socket->WaitForData(1000))
            ch = socket->Read();

    while (socket->IsOpen())
    {
        if (socket->WaitForData(2500))
        {
            printf("<");

            size = 0;
            while (socket->WaitForData(1000))
            {
                ch = socket->Read();
                printf(" %02hX", ch);

                buf[size] = ch;
                size++;
            }
            printf(">\r\n");
            DecodeData(buf, size);
        }
        else
            socket->Push();
    }
    printf("exit\r\n");

    RdosTestGate("");
}
