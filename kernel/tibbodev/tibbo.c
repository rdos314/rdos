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
    int wait_handle;
    int signal_handle;
    int sel;
    int baud_val;
    int par_val;
    int data_val;
    int open;
    int running;
};

struct tibbo_dev
{
    int driver;
    char mac[6];
    long ip;
    short int port;
    int port_count;
    char loader;
    char ok;
    int running;
    struct tibbo_port *port_arr[MAX_TIBBO_DEV_PORTS];
};

extern void InitTibboBase();
extern void InitBroadcast();

extern int AddPort(struct tibbo_port *port);
#pragma aux AddPort parm routine [es edi] value [eax]

extern int GetSendData(int sel, char *buf, int size);
#pragma aux GetSendData parm routine [ebx] [es edi] [ecx] value [eax]

extern void WaitForSignal();

extern void WaitForData(int handle);
#pragma aux WaitForData parm routine [ebx]

extern void PostReceiveData(int sel, char *buf, int size);
#pragma aux PostReceiveData parm routine [ebx] [es edi] [ecx]

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

struct tibbo_port *test_port;
    
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
    WaitForSignal();

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
        if (TibboCount == 0 || !TibboArr[0]->running)
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
//    _asm int 3;
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
                dev->running = TRUE;

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
#   Name       : CreateConnection
#
##########################################################################*/
int CreateConnection(struct tibbo_port *port)
{
    int ok;
    int handle;
    char str[64];

    RdosEnterKernelSection(&CmdSection);

    ok = Login(port->dev);

    if (ok)
    {
        ok = SetVar(port, "FC", "0");    

        if (ok)
            ok = SetVar(port, "DS", "1");    

        if (ok)
        {
            sprintf(str, "%d", port->baud_val);
            ok = SetVar(port, "BR", str); 
        }

        if (ok)
        {
            sprintf(str, "%d", port->par_val);
            ok = SetVar(port, "PR", str); 
        }

        if (ok)
        {
            sprintf(str, "%d", port->data_val);
            ok = SetVar(port, "BB", str); 
        }

        RdosLeaveKernelSection(&CmdSection);

        if (ok)
        {
            handle = RdosOpenTcpConnection(port->dev->ip, port->port, port->port, 500, 0x1000);
            if (handle)
            {   
                ok = RdosWaitForTcpConnection(handle, 500);
                if (!ok)
                    RdosCloseTcpConnection(handle);
            }
            else
                ok = FALSE;
        }

        Logout(port->dev);
    }
    else
        RdosLeaveKernelSection(&CmdSection);

    if (ok)
    {
        port->tcp_handle = handle;
        port->wait_handle = RdosCreateWait();
        RdosAddWaitForTcpConnection(port->wait_handle, port->tcp_handle, 1);
        RdosAddWaitForSignal(port->wait_handle, port->signal_handle, 1);
    }
    else
        port->tcp_handle = 0;

    return ok;
}
    
/*##########################################################################
#
#   Name       : PortThread
#
##########################################################################*/
#pragma aux PortThread "*" rdosdev parm routine [gs ebx]
void __far PortThread(void *param)
{
    char *buf;
    struct tibbo_port *port;
    int count;
    int has_push = TRUE;
        
    buf = RdosAllocateSmallGlobalMem(256);

    port = (struct tibbo_port *)param;

    while (port->open)
    {        
        count = GetSendData(port->sel, buf, 256);
        if (count)
        {
            RdosWriteTcpConnection(port->tcp_handle, buf, count);
            RdosPushTcpConnection(port->tcp_handle);
            has_push = TRUE;
        }
        else               
        {
            count = RdosPollTcpConnection(port->tcp_handle);
            if (count)
            {
                if (count > 256)
                    count = 256;
                count = RdosReadTcpConnection(port->tcp_handle, buf, count);

                if (count)
                    PostReceiveData(port->sel, buf, count);
            }
            else
            {
                if (RdosIsTcpConnectionClosed(port->tcp_handle))
                {
                    RdosCloseTcpConnection(port->tcp_handle);
                    RdosCloseWait(port->wait_handle);

                    CreateConnection(port);
                    has_push = TRUE;
                }
                else
                {
                    if (!has_push)
                        RdosPushTcpConnection(port->tcp_handle);

                    has_push = FALSE;
                    WaitForData(port->wait_handle);
                }
            }
        }            
    }                    
        
    RdosFreeMem(RdosSelectorToPointer(buf));

    RdosCloseTcpConnection(port->tcp_handle);
    RdosCloseWait(port->wait_handle);

    port->tcp_handle = 0;
    port->wait_handle = 0;
    port->running = FALSE;
}
    
/*##########################################################################
#
#   Name       : ImplOpenCom
#
##########################################################################*/
#pragma aux ImplOpenCom "*" rdosdev parm routine [es edi] [esi] [ecx] [edx] [eax] [ebx] value [eax]
int ImplOpenCom(struct tibbo_port *port, int sel, int baudrate, char parity, int databits, int stopbits)
{
    int ok;
    char str[64];

    port->sel = sel;
    port->wait_handle = 0;
    port->running = FALSE;
    port->open = FALSE;
    port->signal_handle = RdosCreateSignal();

    ok = TRUE;

    switch (baudrate)
    {
        case 1200:
            port->baud_val = 0;
            break;

        case 2400:
            port->baud_val = 1;
            break;

        case 4800:
            port->baud_val = 2;    
            break;

        case 9600:
            port->baud_val = 3;
            break;

        case 19200:
            port->baud_val = 4;
            break;

        case 38400:
            port->baud_val = 5;
            break;

        case 57600:
            port->baud_val = 6;
            break;

        case 115200:
            port->baud_val = 7;
            break;    

        case 150:
            port->baud_val = 8;
            break;

        case 300:
            port->baud_val = 9;
            break;

        case 600:
            port->baud_val = 10;
            break;

        case 28800:
            port->baud_val = 11;
            break;

        default:
            ok = FALSE;
            break;
    }

    switch (parity)
    {
        case 'E':
            port->par_val = 1;
            break;

        case 'O':
            port->par_val = 2;
            break;

        default:
            port->par_val = 0;
            break;
    }    

    if (databits == 7)
        port->data_val = 0;
    else
        port->data_val = 1;
         
    if (ok)
    {
        ok = CreateConnection(port);

        if (ok)
        {
            port->open = TRUE;
            port->running = TRUE;
            sprintf(str, "Tibbo Com%d", port->port + 1);
            RdosCreateKernelThread(5, 0x1000, &PortThread, str, port);
        }
    }

    return ok;
}
    
/*##########################################################################
#
#   Name       : ImplCloseCom
#
##########################################################################*/
#pragma aux ImplCloseCom "*" rdosdev parm routine [es edi]
void ImplCloseCom(struct tibbo_port *port)
{
    port->open = FALSE;

    while (port->running)
    {    
        RdosSetSignal(port->signal_handle);
        RdosWaitMilli(50);
    }

    RdosFreeSignal(port->signal_handle);
    port->signal_handle = 0;
    port->sel = 0;
}
    
/*##########################################################################
#
#   Name       : ImplSignalSend
#
##########################################################################*/
#pragma aux ImplSignalSend "*" rdosdev parm routine [es edi]
int ImplSignalSend(struct tibbo_port *port)
{
    if (port->signal_handle)
        RdosSetSignal(port->signal_handle);
}

/*##########################################################################
#
#   Name       : Test gate (used for debugging)
#
##########################################################################*/
#pragma aux ImplTestGate "*" rdosdev parm routine [es edi]
void __far ImplTestGate(const char *msg)
{
    PortThread(test_port);
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
