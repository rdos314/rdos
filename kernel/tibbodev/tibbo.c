/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2011, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# tibbo.c
# Tibbo device
#
########################################################################*/

#include "rdos.h"
#include "rdosdev.h"
#include "string.h"

#include <stdlib.h>
#include <stdio.h>

#define MAX_UDP_DEV     16
#define MAX_TIBBO_DEV   16

#define FALSE   0
#define TRUE    !FALSE

extern void InitTibboBase();
extern void InitBroadcast();

struct tibbo_dev
{
    char mac[30];
    long ip;
    short int port;
    char loader;
    char dhcp;
    char ok;
};

int DriverCount;
int DriverArr[MAX_UDP_DEV];

int TibboCount;
struct tibbo_dev *TibboArr[MAX_TIBBO_DEV];
    
/*##########################################################################
#
#   Name       : BroadcastData
#
##########################################################################*/
void BroadcastData(char *buf, int size)
{
    int i;

    DriverCount = 0;
    InitBroadcast();

    for (i = 0; i < DriverCount; i++)
        RdosBroadcastUdp(4095, -1, DriverArr[i], buf, size);
}        
    
/*##########################################################################
#
#   Name       : RunTibboThread
#
##########################################################################*/
void RunTibboThread()
{
    char str[10] = "X";

    TibboCount = 0;

    for (;;)
    {
        BroadcastData(str, strlen(str));
        RdosWaitMilli(250);
    }
}
    
/*##########################################################################
#
#   Name       : TibboThread
#
##########################################################################*/
#pragma aux TibboThread "*" rdosdev parm routine [es edi]
void __far TibboThread(void *param)
{
    _asm int 3;
    RunTibboThread();
}
    
/*##########################################################################
#
#   Name       : Test gate (used for debugging)
#
##########################################################################*/
#pragma aux ImplTestGate "*" rdosdev parm routine [es edi]
void __far ImplTestGate(const char *msg)
{
    RunTibboThread();
}
    
/*##########################################################################
#
#   Name       : ParseEchoPar
#
##########################################################################*/
void ParseEchoPar(struct tibbo_dev *dev, int par, char *buf)
{
    switch (par)
    {
        case 0:
            strcpy(dev->mac, buf + 1);
            break;
            
        case 1:
            dev->port = atoi(buf);
            break;

        case 2:
            dev->ok = TRUE;
            dev->loader = FALSE;
            dev->dhcp = FALSE;

            switch (buf[0])
            {
                case 'L':
                    dev->loader = TRUE;

                case 'N':
                    break;

                default:
                    dev->ok = FALSE;
            }

            if (buf[1] != '*')
                dev->ok = FALSE;
                
            if (buf[2] != '*')
                dev->ok = FALSE;

            if (buf[3] != 'M')
                dev->dhcp = TRUE;

            break;
    }
}
    
/*##########################################################################
#
#   Name       : ParseEcho
#
##########################################################################*/
void ParseEcho(struct tibbo_dev *dev, char *buf, int size)
{
    int i;
    char *ptr = buf;
    int nr = 0;

    for (i = 0; i < size; i++)
    {
        if (buf[i] == '/')
        {
            buf[i] = 0;
            ParseEchoPar(dev, nr, ptr);
            ptr = buf + i + 1;
            nr++;
        }            
    }    
}
    
/*##########################################################################
#
#   Name       : InsertDev
#
##########################################################################*/
void InsertDev(struct tibbo_dev *dev)
{
    int i;
    int found = FALSE;

    for (i = 0; i < TibboCount && !found; i++)
        if (!strcmp(dev->mac, TibboArr[i]->mac))
            found = TRUE;

    if (found)
        free(dev);
    else
    {
        TibboArr[TibboCount] = dev;
        TibboCount++;
    }
}
    
/*##########################################################################
#
#   Name       : ImplUdpCallback
#
##########################################################################*/
#pragma aux ImplUdpCallback "*" rdosdev parm routine [edx] [es edi] [ecx]
void ImplUdpCallback(long ip, char *buf, int size)
{
    struct tibbo_dev *dev = (struct tibbo_dev *)malloc(sizeof(struct tibbo_dev));
    char *ret_msg = 0;

    dev->ip = ip;
    ParseEcho(dev, buf, size);

    if (dev->ok)
        InsertDev(dev);
    else
        free(dev);
}
    
/*##########################################################################
#
#   Name       : ImplBroadcast
#
##########################################################################*/
#pragma aux ImplBroadcast "*" rdosdev parm routine [eax]
void ImplBroadcast(int driver_sel)
{
    DriverArr[DriverCount] = driver_sel;
    DriverCount++;
}

/*##########################################################################
#
#   Name       : InitTasking
#
#   Purpose....: Init tasking callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux InitTasking "*" rdosdev parm routine
void __far InitTasking()
{
    InitTibboBase();

    RdosCreateKernelThread(5, 0x1000, &TibboThread, "Tibbo", 0);
} 

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Initialization
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    RdosHookInitTasking(&InitTasking);
    RdosRegisterBimodalUserGate(usergate_test_gate, &ImplTestGate, "Test Gate");
}
