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

enum LonSmipCmd
{
    LonNiNull           = 0x00,
    LonNiXOff           = 0x01,        /* software flow control                    */
    LonNiXOn            = 0x02,
    LonNiService        = 0x06,        /* Uplink: Service pin has been pressed     */
                                       /* Downlink: to send a service pin message  */
    LonNiAppInit        = 0x08,        /* Downlink, APPINIT command                */
    LonNiSiData         = 0x0A,        /* Downlink, SIDATA command                 */
    LonNiNvInit         = 0x0B,        /* Downlink, NVINIT command                 */
    LonNiServiceHeld    = 0x0B,        /* Uplink, delayed service pin notification command */
    LonNiNascentKey     = 0x0C,        /* Downlink, set nascent key                        */
    LonNiUsop           = 0x0D,        /* Downlink, send an extended local command to Micro Server   */
    LonNiComm           = 0x10,        /* Data transfer to/from network (lower nibble is   */
                                       /* LonSmipQueue value)                              */
    LonNiNetManagement  = 0x20,        /* Local network management/diagnostics (lower      */
                                       /* nibble is LonSmipQueue value)                    */
    LonNiPhase          = 0x40,        /* Lower nibble contains phase reading.                                      */
    LonNiReset          = 0x50,        /* Uplink: node resets            */
                                       /* Downlink: ask node to reset    */
    LonNiFlushComplete  = 0x60,        /* Uplink                         */
    LonNiFlushCancel    = 0x60,        /* Downlink                       */
    LonNiOnLine         = 0x70,        /* Downlink: Ask node go online   */
    LonNiOffLine        = 0x80,        /* Downlink: Ask node go offline  */
    LonNiFlush          = 0x90,        /* Downlink                       */
    LonNiFlushIgnore    = 0xA0,        /* Downlink                       */
    LonNiSleep          = 0xB0,        /* Not supported by ShortStack Micro Server   */    
    LonIsiNack          = 0xBC,        /* Uplink: ISI Nack in response to a downlink RPC */
    LonIsiAck           = 0xBD,        /* Uplink: ISI Ack in response to a downlink RPC */
    LonIsiCmd           = 0xBE,        /* Downlink: ISI Downlink RPC */
                                       /* Uplink: ISI Uplink RPC */    
    LonNiNv             = 0xC0         /* Special case for downlink NV updates and polls.
                                       Least significant 6 bits contain NV index. */
};

struct LonSmipMsg
{
    LonSmipCmd        Command;         /* Network interface command, possibly OR'ed with additional information (such as the queue identifier) */ 
    unsigned char     Payload[1];      /* message payload. */
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
    LonSmipCmd cmd;
    LonSmipMsg* pSmipMsg = (LonSmipMsg*)msg;

    cmd = pSmipMsg->Command;
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
