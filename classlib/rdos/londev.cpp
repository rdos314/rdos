/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# londev.cpp
# Lon device class
#
########################################################################*/

#include <stdio.h>
#include "rdos.h"
#include "londev.h"

#define LonNiNull           0x00
#define LonNiXOff           0x01        /* software flow control                    */
#define LonNiXOn            0x02
#define LonNiService        0x06        /* Uplink: Service pin has been pressed     */
                                        /* Downlink: to send a service pin message  */
#define LonNiAppInit        0x08        /* Downlink, APPINIT command                */
#define LonNiSiData         0x0A        /* Downlink, SIDATA command                 */
#define LonNiNvInit         0x0B        /* Downlink, NVINIT command                 */
#define LonNiServiceHeld    0x0B        /* Uplink, delayed service pin notification command */
#define LonNiNascentKey     0x0C        /* Downlink, set nascent key                        */
#define LonNiUsop           0x0D        /* Downlink, send an extended local command to Micro Server   */
#define LonNiComm           0x10        /* Data transfer to/from network (lower nibble is   */
                                        /* LonSmipQueue value)                              */
#define LonNiNetManagement  0x20        /* Local network management/diagnostics (lower      */
                                        /* nibble is LonSmipQueue value)                    */
#define LonNiPhase          0x40        /* Lower nibble contains phase reading.                                      */
#define LonNiReset          0x50        /* Uplink: node resets            */
                                        /* Downlink: ask node to reset    */
#define LonNiFlushComplete  0x60        /* Uplink                         */
#define LonNiFlushCancel    0x60        /* Downlink                       */
#define LonNiOnLine         0x70        /* Downlink: Ask node go online   */
#define LonNiOffLine        0x80        /* Downlink: Ask node go offline  */
#define LonNiFlush          0x90        /* Downlink                       */
#define LonNiFlushIgnore    0xA0        /* Downlink                       */
#define LonNiSleep          0xB0        /* Not supported by ShortStack Micro Server   */    
#define LonIsiNack          0xBC        /* Uplink: ISI Nack in response to a downlink RPC */
#define LonIsiAck           0xBD        /* Uplink: ISI Ack in response to a downlink RPC */
#define LonIsiCmd           0xBE        /* Downlink: ISI Downlink RPC */
                                        /* Uplink: ISI Uplink RPC */    
#define LonNiNv             0xC0        /* Special case for downlink NV updates and polls.
                                       Least significant 6 bits contain NV index. */

#define LonNiTxQueue              2     /* Transaction queue                        */
#define LonNiTxQueuePriority      3     /* Priority transaction queue               */
#define LonNiNonTxQueue           4     /* Non-transaction queue                    */
#define LonNiNonTxQueuePriority   5     /* Priority non-transaction queue           */
#define LonNiResponse             6     /* Response msg & completion event queue    */
#define LonNiIncoming             8     /* Received message queue                   */
 
struct LonExplicitMessage
{
    unsigned char      Attributes_1;   /* contains msgType, serviceType, authenticated, tag. Use LON_EXPMSG_* macros */
    unsigned char      Attributes_2;   /* contains priority, path, completionCode, explicitAddressing, altPath, pool, response. Use LON_-_* macros */
    unsigned char      Length;         /* Length of message code and data to follow    */
                                       /* not including any explicit address field.    */
    unsigned char      Address[11];    /* Optional explicit addressing information   */
    unsigned char      Code;           /* Message code                                 */
    unsigned char      Data;
};

/*##########################################################################
#
#   Name       : TLonDevice::TLonDevice
#
#   Purpose....: Constructor for TLonDevice                                    
#
#   In params..: Height         requested font height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLonDevice::TLonDevice(int lonid)
{
    char str[80];
    
    FLonId = lonid;
    FLonHandle = RdosOpenLonModule(lonid, 20, 10);

    if (FLonHandle)
    {
        sprintf(str, "Lon Handler #%s", lonid);
        Start(str, 0x6000);
    }
}

/*##########################################################################
#
#   Name       : TLonDevice::~TLonDevice
#
#   Purpose....: Destructor for TLonDevice                                     
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLonDevice::~TLonDevice()
{
    if (FLonHandle)
    {
        Stop();

        while (IsRunning())
            RdosWaitMilli(25);
            
        RdosCloseLonModule(FLonHandle);
    }
}

/*##########################################################################
#
#   Name       : TLonDevice::SendMsg
#
#   Purpose....: Send a message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::SendMsg(const char *msg, int size)
{
    RdosSendLonModuleMsg(FLonHandle, msg, size);
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleReset
#
#   Purpose....: Handle RESET message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleReset(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleService
#
#   Purpose....: Handle service PIN message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleService(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleServiceHeld
#
#   Purpose....: Handle service PIN held message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleServiceHeld(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleUsop
#
#   Purpose....: Handle unsupported message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleUsop(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleIncomingNvMsg
#
#   Purpose....: Handle incoming NV message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleIncomingNvMsg(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleIncomingExpMsg
#
#   Purpose....: Handle incoming explicit message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleIncomingExpMsg(const char *msg, int size)
{
    LonExplicitMessage *Expl = (LonExplicitMessage*)(msg + 1);
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleResponseMsg
#
#   Purpose....: Handle response message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleResponseMsg(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleIsiNack
#
#   Purpose....: Handle ISI NACK message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleIsiNack(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleIsiAck
#
#   Purpose....: Handle ISI ACK message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleIsiAck(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleIsiCmd
#
#   Purpose....: Handle ISI CMD message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleIsiCmd(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::NotifyMsg
#
#   Purpose....: Notify message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::NotifyMsg(const char *msg, int size)
{
    LonExplicitMessage *Expl = (LonExplicitMessage*)(msg + 1);
    unsigned char NvMsg;

    switch (msg[0])
    {
        case LonNiComm | LonNiIncoming:
            NvMsg = (Expl->Attributes_1 & 0x80) >> 7;
            if (NvMsg)
                HandleIncomingNvMsg(msg, size);
            else
                HandleIncomingExpMsg(msg, size);
            break;
            
        case LonNiComm | LonNiResponse:
            HandleResponseMsg(msg, size);
            break;
            
        case LonNiReset:
            HandleReset(msg, size);
            break;

        case LonNiService:
            HandleService(msg, size);
            break;

        case LonNiServiceHeld:
            HandleServiceHeld(msg, size);
            break;

        case LonNiUsop:
            HandleUsop(msg, size);
            break;
            
        case LonIsiNack:
            HandleIsiNack(msg, size);
            break;

        case LonIsiAck:
            HandleIsiAck(msg, size);
            break;

        case LonIsiCmd:
            HandleIsiCmd(msg, size);
            break;
    }                       
}

/*##########################################################################
#
#   Name       : TLonDevice::Execute
#
#   Purpose....: Message handler loop
#
##########################################################################*/
void TLonDevice::Execute()
{
    char *buf;
    int size;
    int wait = RdosCreateWait();

    buf = new char[255];

    RdosAddWaitForLonModule(wait, FLonHandle, (int)this);

    while (FInstalled)
    {
        if (IsOpen())
        {
            RdosWaitTimeout(wait, 1000);

            if (RdosHasLonModuleMsg(FLonHandle))
            {
                size = RdosReceiveLonModuleMsg(FLonHandle, buf);
                NotifyMsg(buf, size);
            }
        }
        else
            RdosWaitMilli(100);
    }

    RdosCloseWait(wait);
    delete buf;
}
