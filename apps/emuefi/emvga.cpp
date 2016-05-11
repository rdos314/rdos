/*###########################################################################
* Em486 CPU emulator
* Copyright (C) 1998-2000, Leif Ekblad
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version. The only exception to this rule
* is for commercial usage. For information on commercial usage,
* contact em486@rdos.net.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*
* The author of this program may be contacted at leif@rdos.net
*
* EMVGA.CPP
* Remote display for simulator, UEFI LFB
*
*##########################################################################*/

#include <rdos.h>
#include <stdio.h>
#include "dispmsg.h"

char FocusKey;
int VideoHandle;

unsigned char VkToKeyTab[256] =
{
        0,      0,      0,      0,      0,      0,      0,      0,   // 00
        0xE,    0xF,    0,      0,      0,      0x1C,   0,      0,   // 08
        0x2A,   0x1D,   0x38,   0,      0x3A,   0,      0,      0,   // 10
        0,      0,      0,      1,      0,      0,      0,      0,   // 18
        0x39,   0,      0,      0,      0,      0,      0,      0,   // 20
        0,      0,      0,      0,      0x37,   0,      0,      0,   // 28
        0xB,    2,      3,      4,      5,      6,      7,      8,   // 30
        9,      0xA,    0,      0,      0x56,   0,      0,      0,   // 38
        0,      0x1E,   0x30,   0x2E,   0x20,   0x12,   0x21,   0x22,// 40
        0x23,   0x17,   0x24,   0x25,   0x26,   0x32,   0x31,   0x18,// 48
        0x19,   0x10,   0x13,   0x1F,   0x14,   0x16,   0x2F,   0x11,// 50
        0x2D,   0x15,   0x2C,   0x5B,   0,      0,      0,      0,   // 58
        0x52,   0x4F,   0x50,   0x51,   0x4B,   0x4C,   0x4D,   0x47,// 60
        0x48,   0x49,   0,      0x4E,   0x53,   0x4A,   0x54,   0,   // 68 
        0x3B,   0x3C,   0x3D,   0x3E,   0x3F,   0x40,   0x41,   0x42,// 70
        0x43,   0x44,   0x57,   0x58,   0,      0,      0,      0,   // 78
        0,      0,      0,      0,      0,      0,      0,      0,   // 80
        0,      0,      0,      0,      0,      0,      0,      0,   // 88
        0x45,   0x46,   0,      0,      0,      0,      0,      0,   // 90
        0,      0,      0,      0,      0,      0,      0,      0,   // 98
        0,      0,      0,      0,      0,      0,      0,      0,   // A0
        0,      0,      0,      0,      0,      0,      0,      0,   // A8
        0,      0,      0,      0,      0,      0,      0,      0,   // B0
        0,      0,      0x1B,   0xC,    0x33,   0x35,   0x34,   0x2B,// B8
        0x27,   0,      0,      0,      0,      0,      0,      0,   // C0
        0,      0,      0,      0,      0,      0,      0,      0,   // C8
        0,      0,      0,      0,      0,      0,      0,      0,   // D0
        0,      0,      0,      0xD,    0x29,   0x1A,   0x28,   0,   // D8
        0,      0,      0,      0,      0,      0,      0,      0,   // E0
        0,      0,      0,      0,      0,      0,      0,      0,   // E8
        0,      0,      0,      0,      0,      0,      0,      0,   // F0
        0,      0,      0,      0,      0,      0,      0,      0,   // F8
};


/*##################  HandleFocus  ###############
*   Purpose....: Handle focus req                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void HandleFocus()
{
    RdosReplyMailslot(&FocusKey, 1);
}

/*##################  HandleVideo  ###############
*   Purpose....: Handle video req                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void HandleVga(struct TVgaReq *req)
{
    RdosSetDrawColor(VideoHandle, req->val);
    RdosSetPixel(VideoHandle, req->x, req->y);
    RdosReplyMailslot("", 0);
}

/*##################  HandleKey  ###############
*   Purpose....: Handle key req                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void HandleKey()
{
    int ExtKey;
    int KeyState;
    int VirtKey;
    int ScanCode;
    unsigned char Code = 0;

    if (RdosPeekKeyEvent(&ExtKey, &KeyState, &VirtKey, &ScanCode))
    {
        if (RdosReadKeyEvent(&ExtKey, &KeyState, &VirtKey, &ScanCode))
            if (VirtKey < 256)
                Code = VkToKeyTab[VirtKey];

        if (Code && (ExtKey & 0x8000))
            Code = Code | 0x80;         
    }

    if (Code)
        RdosReplyMailslot(&Code, 1);
    else
        RdosReplyMailslot(&Code, 0);
}

/*##################  main  ###############
*   Purpose....: main                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void main(void)
{
    char *msg = new char[0x1000];
    int size;
    struct TBaseReq *BaseReq = (struct TBaseReq *)msg;
    void *buf;
    int BitsPerPixel = 32;
    int xres = 640;
    int yres = 480;
    int linesize = 0;
    
    FocusKey = RdosGetFocus();

    RdosDefineMailslot("emdisp", 0x1000);

    VideoHandle = RdosSetVideoMode(&BitsPerPixel, &xres, &yres, &linesize, &buf);

    for (;;)
    {
        size = RdosReceiveMailslot(msg);
        if (size >= 4)
        {
            switch (BaseReq->MsgType)
            {
                case DISP_MSG_FOCUS:
                    HandleFocus();
                    break;

                case DISP_MSG_KEY:
                    HandleKey();
                    break;

                case DISP_MSG_VGA:
                    HandleVga((struct TVgaReq *)msg);
                    break;

                default:
                    RdosReplyMailslot(msg, 0);
                    break;
            }
        }
        else
            RdosReplyMailslot(msg, 0);
    }        
}
