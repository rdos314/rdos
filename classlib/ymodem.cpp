/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# ymodem.cpp
# Ymodem class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include "ymodem.h"

#include "rdos.h"

#define SOH     0x01
#define STX     0x02
#define EOT     0x04
#define ACK     0x06
#define NAK     0x15
#define CAN     0x18

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TYModem::TYModem
#
#   Purpose....: Constructor for YModem protocol
#
#   In params..: Serial device
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TYModem::TYModem(TSerialDevice *Serial)
{
    int i, j;
    int val;
        int acc;

        OnHeader = 0;
    FSerial = Serial;

    for (i = 0; i < 256; i++)
    {
        acc = 0;
        val = i << 8;
        for (j = 8; j; j--)
        {
                        if (((val ^ acc) & 0x8000) == 0)
                                acc = acc << 1;
                        else
                                acc = (acc << 1) ^ 0x1021;
                        val = val << 1;
                }
        FCrcTable[i] = acc;
    }
}

/*##########################################################################
#
#   Name       : TYModem::NotifyHeader
#
#   Purpose....: Notify header char
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TYModem::NotifyHeader(char header)
{
        if (OnHeader)
                (*OnHeader)(this, header);
}

/*##########################################################################
#
#   Name       : TYModem::SendStartup
#
#   Purpose....: Startup send protocol
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if successful
#
##########################################################################*/
int TYModem::SendStartup()
{
        int i;

        FSerial->Clear();
        for (i = 0; i < 20; i++)
        {
                if (FSerial->WaitForChar(1000))
                {
                        FNCG = FSerial->Read();
                        NotifyHeader(FNCG);
                        switch (FNCG)
                        {
                                case NAK:
                                case 'C':
                                case 'G':
                                        return TRUE;

                        }
                }
        }
        return FALSE;
}

/*##########################################################################
#
#   Name       : TYModem::SendPacket
#
#   Purpose....: Send a single packet
#
#   In params..: Buffer to send
#                Size of data
#   Out params.: *
#   Returns....: TRUE if successful
#
##########################################################################*/
int TYModem::SendPacket(char *Buffer, int Size)
{
        char ch;
        int i;
        int j;
        int crc;
        int ind;

        for (i = 0; i < 3; i++)
        {
                if (Size == 1024)
                        FSerial->Write(STX);
                else
                        FSerial->Write(SOH);

                ch = (char)FPacketNr;
                FSerial->Write(ch);

                ch = 0xFF - ch;
                FSerial->Write(ch);

                FSerial->Write((char *)Buffer, Size);

                if (FNCG == NAK)
                {
                        ch = 0;
                        for (j = 0; j < Size; j++)
                                ch += Buffer[j];
                        FSerial->Write(ch);
                }
                else
                {
                        crc = 0;
                        for (j = 0; j < Size; j++)
                        {
                                ind = crc >> 8;
                                ind = ind ^ Buffer[j];
                                ind = ind & 0xFF;
                                ind = FCrcTable[ind];
                                crc = ind ^ (crc << 8);
                        }
                        ch = (char)((crc >> 8) & 0xFF);
                        FSerial->Write(ch);

                        ch = (char)(crc & 0xFF);
                        FSerial->Write(ch);
                }

                if (FSerial->WaitForChar(2000))
                {
                        ch = FSerial->Read();
                        NotifyHeader(ch);
                        switch (ch)
                        {
                                case CAN:
                                        return FALSE;

                                case ACK:
                                        return TRUE;

                                case NAK:
                                        break;

                                default:
                                        return FALSE;
                        }
                }
        }

        return FALSE;
}

/*##########################################################################
#
#   Name       : TYModem::SendFile
#
#   Purpose....: Send a file
#
#   In params..: File       file to send
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TYModem::SendFile(TFile *File)
{
        char Buf[1024];
        int BlockSize;
        int Remaining;
        int Size;
        int i;

        Remaining = (int)File->GetSize();

        if (Remaining == 0)
                return FALSE;

        if (!SendStartup())
                return FALSE;

        FPacketNr = 0;
        Size = strlen(File->GetFileName());
        strcpy(Buf, File->GetFileName());
        sprintf(&Buf[Size + 1], "%d", Remaining);
        Size += strlen(&Buf[Size + 1]) + 1;
        for (i = Size; i < 128; i++)
                Buf[i] = 0;

        if (!SendPacket(Buf, 128))
                return FALSE;

        if (!SendStartup())
                return FALSE;

        while (Remaining)
        {
                FPacketNr++;

                if (Remaining >= 1024)
                        BlockSize = 128;
                else
                        BlockSize = 128;

                if (Remaining < BlockSize)
                        Size = Remaining;
                else
                        Size = BlockSize;

                Size = File->Read(Buf, Size);
                Remaining -= Size;

                if (Size < BlockSize)
                        for (i = Size; i < BlockSize; i++)
                                Buf[i] = 0x1A;

                if (!SendPacket(Buf, BlockSize))
                        return FALSE;

                if (Size == 0 && Remaining)
                        return FALSE;
        }

        FSerial->Write(EOT);
        FSerial->Write(0x1b);

        return TRUE;
}

/*##########################################################################
#
#   Name       : TYModem::SendFile
#
#   Purpose....: Send a file
#
#   In params..: File       file to send
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TYModem::SendFile(const char *FileName)
{
        TFile File(FileName);

        return SendFile(&File);
}


/*##########################################################################
#
#   Name       : TYModem::RecType
#
#   Purpose....: Receive packet type
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if successful
#
##########################################################################*/
int TYModem::RecType()
{
        while (FSerial->WaitForChar(1000))
        {
                FPacketType = FSerial->Read();
                NotifyHeader(FPacketType);
                switch (FPacketType)
                {
                        case STX:
                        case SOH:
                        case EOT:
                                return TRUE;
                }
        }
        return FALSE;
}

/*##########################################################################
#
#   Name       : TYModem::RecStartup
#
#   Purpose....: Startup receive protocol
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if successful
#
##########################################################################*/
int TYModem::RecStartup()
{
        int i;

        for (i = 0; i < 20; i++)
        {
                FSerial->Clear();
                FSerial->Write('C');
                NotifyHeader('C');
                if (FSerial->WaitForChar(1000))
                {
                        FPacketType = FSerial->Read();
                        NotifyHeader(FPacketType);
                        switch (FPacketType)
                        {
                                case STX:
                                case SOH:
                                        return TRUE;

                                default:
                                        RdosWaitMilli(500);
                                        break;
                        }
                }
        }
        return FALSE;
}

/*##########################################################################
#
#   Name       : TYModem::RecPacket
#
#   Purpose....: Receive a single packet
#
#   In params..: Buffer to send
#   Out params.: Size of packet
#   Returns....: TRUE if successful
#
##########################################################################*/
int TYModem::RecPacket(char *Buffer, int *Size)
{
        char ch;
        int i;
        int crc;
        int ind;
        int ok;
        char cpacket;
        int NewPacket;

        switch (FPacketType)
        {
                case STX:
                        *Size = 1024;
                        ok = TRUE;
                        break;

                case SOH:
                        *Size = 128;
                        ok = TRUE;
                        break;

                case EOT:
                        *Size = 0;
                        FSerial->Write(ACK);
                        return TRUE;

                default:
                        ok = FALSE;
                        break;
        }

        if (ok)
                ok = FSerial->WaitForChar(1000);

        if (ok)
        {
                cpacket = FSerial->Read();
                ok = FSerial->WaitForChar(1000);
        }

        if (ok)
        {
                ok = FALSE;
                NewPacket = FALSE;
                ch = FSerial->Read();
                ch = 0xFF - ch;
                if (ch == cpacket)
                        ok = TRUE;
        }

        if (ok)
        {
                ok = FALSE;

                if (cpacket == (char)FPacketNr)
                {
                        ok = TRUE;
                        NewPacket = TRUE;
                }

                cpacket++;

                if (cpacket == (char)FPacketNr)
                        ok = TRUE;
        }

        crc = 0;

        for (i = 0; i < *Size && ok; i++)
        {
                ok = FSerial->WaitForChar(1000);
                if (ok)
                {
                        ch = FSerial->Read();
                        Buffer[i] = ch;

                        ind = crc >> 8;
                        ind = ind ^ Buffer[i];
                        ind = ind & 0xFF;
                        ind = FCrcTable[ind];
                        crc = ind ^ (crc << 8);
                }
        }

        if (ok)
        {
                {
                        ok = FSerial->WaitForChar(1000);
                        if (ok)
                        {
                                ch = FSerial->Read();
                                if ((char)((crc >> 8) & 0xFF) == ch)
                                        ok = TRUE;
                                else
                                        ok = FALSE;
                        }

                        if (ok)
                                ok = FSerial->WaitForChar(1000);

                        if (ok)
                        {
                                ch = FSerial->Read();
                                if ((char)(crc & 0xFF) == ch)
                                        ok = TRUE;
                                else
                                        ok = FALSE;
                        }

                        if (ok)
                        {
                                FSerial->Write(ACK);
                                if (NewPacket)
                                        return TRUE;
                                else
                                        return FALSE;
                        }
                        else
                        {
                                FSerial->Write(NAK);
                                return FALSE;
                        }
                }
        }
        return FALSE;
}

/*##########################################################################
#
#   Name       : TYModem::RecFile
#
#   Purpose....: Receive a file
#
#   In params..: File       file to receive
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TYModem::RecFile(TFile *File)
{
        char Buf[1024];
        int Size;
        int i;
        long FileSize;
        int ok;

        File->SetSize(0);
        File->SetPos(0);

        FPacketNr = 0;

        if (!RecStartup())
                return FALSE;

        if (!RecPacket(Buf, &Size))
                return FALSE;

        if (Size)
        {
                Size = strlen(Buf);
                if (sscanf(&Buf[Size + 1], "%ld", &FileSize) != 1)
                        return FALSE;
        }
        else
                return FALSE;

        FPacketNr++;

        if (!RecStartup())
                return FALSE;

        for (;;)
        {
                ok = FALSE;
                for (i = 0; i < 3 && !ok; i++)
                {
                        ok = RecPacket(Buf, &Size);
                        RecType();
                }

                if (Size)
                {
                        if (ok)
                        {
                                File->Write(Buf, Size);
                                FPacketNr++;
                        }
                        else
                                return FALSE;
                }
                else
                {
                        File->SetSize(FileSize);
                        FSerial->Write(ACK);
                        return TRUE;
                }
        }
}

/*##########################################################################
#
#   Name       : TYModem::RecFile
#
#   Purpose....: Receive a file
#
#   In params..: File       file to receive
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TYModem::RecFile(const char *FileName)
{
        TFile File(FileName, 0);

        return RecFile(&File);
}
