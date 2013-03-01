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

#define MAX_UDP_DEV         16
#define MAX_TIBBO_DEV       16
#define MAX_TIBBO_DEV_PORTS 16
#define MAX_TIBBO_PORTS     32

#define FALSE   0
#define TRUE    !FALSE

struct tibbo_port
{
    struct tibbo_dev *dev;
    int dev_port;
    short int port;
    int tcp_handle;
    int handler_thread;
};

struct tibbo_dev
{
    int driver;
    char mac[6];
    long ip;
    short int port;
    int port_count;
    char loader;
    char dhcp;
    char ok;
    int running;
    struct tibbo_port *port_arr[MAX_TIBBO_DEV_PORTS];
};

extern void InitTibboBase();
extern void InitBroadcast();

extern void AddPort(struct tibbo_port *port);
#pragma aux AddPort parm routine [es edi]

int DriverCount;
int DriverArr[MAX_UDP_DEV];
int CurrDriver = -1;

int TibboCount;
struct tibbo_dev *TibboArr[MAX_TIBBO_DEV];

int TibboPortCount;
struct tibbo_port *TibboPortArr[MAX_TIBBO_PORTS];

char AnswerBuf[64];
int SignalThread = 0;

struct TKernelSection CmdSection;
    
/*##########################################################################
#
#   Name       : Login
#
##########################################################################*/
int Login(struct tibbo_dev *dev)
{
    int ok;

    SignalThread = RdosGetThreadHandle();
    AnswerBuf[0] = 0;
    RdosSendDriverUdp(4095, -1, dev->ip, dev->driver, dev->mac, "L", 1);
    RdosWaitForSignal();

    if (AnswerBuf[0] == 'A')
        return TRUE;
    else
    {
        SignalThread = 0;
        return FALSE;
    }
}
    
/*##########################################################################
#
#   Name       : Logout
#
##########################################################################*/
void Logout(struct tibbo_dev *dev)
{
    RdosSendDriverUdp(4095, -1, dev->ip, dev->driver, dev->mac, "O", 1);
    SignalThread = 0;
}
    
/*##########################################################################
#
#   Name       : Reboot
#
##########################################################################*/
void Reboot(struct tibbo_dev *dev)
{
    RdosSendDriverUdp(4095, -1, dev->ip, dev->driver, dev->mac, "E", 1);
    SignalThread = 0;
    RdosWaitMilli(250);
}
    
/*##########################################################################
#
#   Name       : Session
#
##########################################################################*/
int Session(struct tibbo_dev *dev, char *str, char *reply)
{
    int ok;
    AnswerBuf[0] = 0;
    RdosSendDriverUdp(4095, -1, dev->ip, dev->driver, dev->mac, str, strlen(str));
    RdosWaitForSignal();

    if (AnswerBuf[0] == 'A')
    {
        strcpy(reply, &AnswerBuf[1]);
        return TRUE;
    }
    else
        return FALSE;
}
    
/*##########################################################################
#
#   Name       : SetVar
#
##########################################################################*/
int SetVar(struct tibbo_port *port, const char *setting, const char *val)
{
    char str[64];
    char reply[64];

    if (port->dev_port)
        sprintf(str, "S%s@%d%s", setting, port->dev_port + 1, val);
    else
        sprintf(str, "S%s%s", setting, val);

    return Session(port->dev, str, reply);        
}
    
/*##########################################################################
#
#   Name       : SetPar
#
##########################################################################*/
int SetPar(struct tibbo_port *port, const char *par, const char *val)
{
    char str[64];
    char reply[64];

    if (port->dev_port)
        sprintf(str, "P%s@%d%s", par, port->dev_port + 1, val);
    else
        sprintf(str, "P%s%s", par, val);

    return Session(port->dev, str, reply);        
}
    
/*##########################################################################
#
#   Name       : BroadcastData
#
##########################################################################*/
void BroadcastData(char *buf, int size)
{
    int i;

    RdosEnterKernelSection(&CmdSection);

    DriverCount = 0;
    InitBroadcast();

    for (i = 0; i < DriverCount; i++)
    {
        CurrDriver = DriverArr[i];
        RdosBroadcastUdp(4095, -1, CurrDriver, buf, size);
        RdosWaitMilli(250);
    }

    RdosLeaveKernelSection(&CmdSection);

    CurrDriver = -1;
}        
    
/*##########################################################################
#
#   Name       : InitPort
#
##########################################################################*/
int InitPort(struct tibbo_port *port)
{
    int ok;
    
    ok = SetVar(port, "RM", "0"); 
    if (ok)
        ok = SetVar(port, "TP", "1");

    return ok;        
}        
    
/*##########################################################################
#
#   Name       : InitDevPorts
#
##########################################################################*/
void InitDevPorts(struct tibbo_dev *dev)
{
    int i;
    int ok;

    ok = Login(dev);

    for (i = 0; i < dev->port_count && ok; i++)
        ok = InitPort(dev->port_arr[i]);

    dev->running = ok;
    Reboot(dev);
}        
    
/*##########################################################################
#
#   Name       : RunTibboThread
#
##########################################################################*/
void RunTibboThread()
{
    char str[10] = "X";
    char reply[64];
    int ok;

    TibboCount = 0;
    TibboPortCount = 0;

    RdosWaitMilli(5000);

    for (;;)
    {
        BroadcastData(str, strlen(str));

        if (TibboArr[0]->dhcp)
        {
            if (!TibboArr[0]->running)
                InitDevPorts(TibboArr[0]);
        }            
        else
        {
            ok = Login(TibboArr[0]);
            if (ok)
            {
                Session(TibboArr[0], "SDH1", reply);
                Reboot(TibboArr[0]);
                TibboArr[0]->dhcp = TRUE;
            }
        }
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
//    _asm int 3;
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
#   Name       : ConvMac
#
##########################################################################*/
void ConvMac(char *mac, char *str)
{
    int i;
    char *base = str;
    char *ptr = str;

    i = 0;

    while (i < 6)
    {
        if (*ptr == '.' || *ptr == 0)
        {
            if (*ptr == '.')
            {
                *ptr = 0;
                ptr++;
            }
            mac[i] = atoi(base);
            base = ptr;
            i++;
        }
        else
            ptr++;
    }    
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
            ConvMac(dev->mac, buf + 1);
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

        case 6:
            dev->port_count = atoi(buf);
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
    ParseEchoPar(dev, nr, ptr);
}
    
/*##########################################################################
#
#   Name       : CreateDevPorts
#
##########################################################################*/
void CreateDevPorts(struct tibbo_dev *dev)
{
    int i;
    struct tibbo_port *port;

    for (i = 0; i < MAX_TIBBO_DEV_PORTS; i++)
        dev->port_arr[i] = 0;

    if (dev->port_count > MAX_TIBBO_DEV_PORTS)
        dev->port_count = MAX_TIBBO_DEV_PORTS;

    for (i = 0; i < dev->port_count; i++)
    {
        port = (struct tibbo_port *)malloc(sizeof(struct tibbo_port));
        port->dev = dev;
        port->dev_port = i;
        port->port = dev->port + i;
        dev->port_arr[i] = port;

        TibboPortArr[TibboPortCount] = port;
        TibboPortCount++;

        AddPort(port);
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
    struct tibbo_dev *has_dev;

    for (i = 0; i < TibboCount && !found; i++)
    {
        if (!memcmp(dev->mac, TibboArr[i]->mac, 6))
        {
            found = TRUE;
            has_dev = TibboArr[i];
            break;
        }
    }

    if (found)
    {
        has_dev->ip = dev->ip;
        has_dev->port = dev->port;
        has_dev->loader = dev->loader;
        has_dev->dhcp = dev->dhcp;
        has_dev->ok = dev->ok;       
        free(dev);
    }
    else
    {
        TibboArr[TibboCount] = dev;
        TibboCount++;

        if (dev->ok)
            CreateDevPorts(dev);
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
    struct tibbo_dev *dev;
    char *ret_msg = 0;

    if (SignalThread)
    {
        if (size > 63)
            size = 63;
        buf[size] = 0;
        strcpy(AnswerBuf, buf);

        RdosSignal(SignalThread);
    }
    else
    {
        if ((size > 1) && (buf[0] == 'A'))
        {
            dev = (struct tibbo_dev *)malloc(sizeof(struct tibbo_dev));

            dev->driver = CurrDriver;
            dev->ip = ip;
            dev->port_count = 1;
            dev->running = FALSE;
            dev->ok = FALSE;
            ParseEcho(dev, buf, size);

            if (dev->ok)
                InsertDev(dev);
            else
                free(dev);
        }
    }
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
#   Name       : PortThread
#
##########################################################################*/
#pragma aux PortThread "*" rdosdev parm routine [gs ebx]
void __far PortThread(void *param)
{
    struct tibbo_port *port;

    port = (struct tibbo_port *)param;
    port->handler_thread = RdosGetThreadHandle();

    for (;;)
    {
        RdosWaitForSignal();    
    }
}
    
/*##########################################################################
#
#   Name       : ImplOpenCom
#
##########################################################################*/
#pragma aux ImplOpenCom "*" rdosdev parm routine [es edi] [ecx] [edx] [eax] [ebx] value [eax]
int ImplOpenCom(struct tibbo_port *port, int baudrate, char parity, int databits, int stopbits)
{
    int ok;
    int val;
    char str[64];
    int handle;

    switch (baudrate)
    {
        case 1200:
            val = 0;
            break;

        case 2400:
            val = 1;
            break;

        case 4800:
            val = 2;    
            break;

        case 9600:
            val = 3;
            break;

        case 19200:
            val = 4;
            break;

        case 38400:
            val = 5;
            break;

        case 57600:
            val = 6;
            break;

        case 115200:
            val = 7;
            break;    

        case 150:
            val = 8;
            break;

        case 300:
            val = 9;
            break;

        case 600:
            val = 10;
            break;

        case 28800:
            val = 11;
            break;

        default:
            val = 0;
            break;
    }

    if (val)
    {
        handle = RdosOpenTcpConnection(port->dev->ip, 1000, port->port, 500, 0x1000);
        if (handle)
        {
            ok = RdosWaitForTcpConnection(handle, 500);
            if (!ok)
                RdosCloseTcpConnection(handle);
        }
        else
            ok = FALSE;
    }
    else
        ok = FALSE;

    if (ok)
    {
        RdosEnterKernelSection(&CmdSection);

        ok = Login(port->dev);

        if (ok)
        {
            ok = SetVar(port, "SI", "0");    

            if (ok)
                ok = SetVar(port, "FC", "0");    

            if (ok)
                ok = SetVar(port, "DT", "0");    

            if (ok)
                ok = SetVar(port, "DS", "1");    

            if (ok)
                ok = SetVar(port, "SE", "0");    

            if (ok)
            {
                sprintf(str, "%d", val);
                ok = SetVar(port, "BR", str); 
            }

            if (ok)
            {
                switch (parity)
                {
                    case 'E':
                        val = 1;
                        break;

                    case 'O':
                        val = 2;
                        break;

                    default:
                        val = 0;
                        break;
                }    
                
                sprintf(str, "%d", val);
                ok = SetVar(port, "PR", str); 
            }

            if (ok)
            {
                if (databits == 7)
                    ok = SetVar(port, "BB", "0"); 
                else
                    ok = SetVar(port, "BB", "1"); 
            }                
        }

        Logout(port->dev);

        RdosLeaveKernelSection(&CmdSection);

        port->tcp_handle = handle;

        RdosCreateKernelThread(5, 0x1000, &PortThread, "Tibbo Com", port);
    }

    return ok;
}
    
/*##########################################################################
#
#   Name       : ImplSignalSend
#
##########################################################################*/
#pragma aux ImplSignalSend "*" rdosdev parm routine [es edi]
int ImplSignalSend(struct tibbo_port *port)
{
    RdosSignal(port->handler_thread);
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
    RdosInitKernelSection(&CmdSection);

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
