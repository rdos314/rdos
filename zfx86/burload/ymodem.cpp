/*####################################  YMODEM.CPP                      #################################################
##    Description: Ymodem class                                          ##
##                                                                                                                  ##
##    Created....: 02-11-18 le                                                        Printed...: 90-10-25 an      ##
####################################################################################################################*/

#include <string.h>
#include "serial.h"
#include "kernel.h"

/*##################  TYModem::TYModem ############
*   Purpose....: Constructor for Ymodem class       	                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TYModem::TYModem(TSerialDevice *Serial)
{
    FSerial = Serial;
}

/*##################  TSerialCommand::TSerialCommand ############
*   Purpose....: Constructor for TSerialCommand	                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
{
    int BlockSize;
    int Number128;
    int Number1K;
    
    BlockSize = 128;
    Number128 = 0;
    Number1K = 0;
    NCGByte = NAK;
    Empty = FALSE;
    EOT = FALSE;

    if (Batch)
        if (strlen(FileName) == 0)
            Empty = TRUE;

    printf("Waiting for receiver\r\n");

    if (!Empty)
    {
        FileSize = GetFileSize();
        RemainingBytes = FileSize;
        if (Use1K)
            Number1K = FileSize / 1024;

        Number128 = (FileSize - 1024 * Number1K) / 128;            
        if (128 * Number128 + 1024 * Number1K) < FileSize)
            Number128++;
    }
    
    FSerial->Clear();
    FSerial->Write(NAK)   

    if (!Startup(NCGByte)
        return FALSE;

    if (Batch)
        FirstPacket = 0;
    else
        FirstPacket = 1;

    Tics = GetTimer();        

    for (Packet = FirstPacket; Packet <= Number1K + Number128; Packet++)
    {
        if (PollKeyboard())
        {
            FSerial->Write(CAN);
            return FALSE;
        }

        if (Packet == 0)
        {
            if (Empty)
                Buf[0] = 0;
            else
            {
                BlockSize = 128;
                Size = strlen(FileName);
                strcpy(Buf, FileName);
                sprintf(&Buf[Size + 1], "%d", FileSize);
                Size += strlen(&Buf[Size + 1];
                for (i = Size; i < 128; i++)
                    Buffer[i] = 0;
            }
        }
        else
        {
            if (Batch && Packet <= Number1K)
                BlockSize = 1024;
            else
                BlockSize = 128;

            if (RemainingBytes < BlockSize)
                ReadSize = RemainingBytes;
            else
                ReadSize = BlockSize;

            Read(Buf, ReadSize);
            RemainingBytes -= ReadSize;

            if (ReadSize < BlockSize)
                for (i = ReadSize; i < BlockSize; i++)
                    Buf[i] = 0x1A;
        }

        TxPacket(Packet, BlockSize, Buf, NCGByte);

        if (!Empty) && Packet = 0)
            Startup(NCGByte);
    }
                
}

/*##################  TYModem::Send ############
*   Purpose....: Send a file       	                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TYModem::Send(const char *FileName)
{
    FSerial = Serial;
}
