#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "serial.h"

unsigned short int CalcCrc16(char *data, int len)
{
    int i, j;
    unsigned short int x16, crc;
    char input;

    crc = 0;
    for (i = 0; i < len; i++)
    {
        input = data[i];
        for (j = 0; j < 8; j++)
        {
            if ((crc & 1) ^ (input & 1))
               x16 = 0x8408;
            else
               x16 = 0;
            crc = crc >> 1;
            crc = crc ^ x16;
            input = input >> 1;
        }
    }

    return crc;
}

void main()
{
    char Data[] = {0x47, 0x30, 0x31, 0x61, 0x3A};
    unsigned short int crc;
    int i;
    char buf[40];
    char str[10];
    TSerialDevice serial(1, 1200);

    serial.Open();

    memcpy(buf, Data, 5);
    crc = CalcCrc16(buf, 5);
    sprintf(str, "%04hX", crc);
    buf[5] = str[2];
    buf[6] = str[3];
    buf[7] = 0xd;
    
    serial.Write(buf, 8);

    i = 0;
    while (serial.WaitForChar(1000))
    {
        buf[i] = serial.Read();
        i++;
    }
    
}
