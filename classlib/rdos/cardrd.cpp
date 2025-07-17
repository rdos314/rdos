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
# cardrd.cpp
# Card reader device class
#
########################################################################*/

#include <string.h>
#include "cardrd.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE


/*##########################################################################
#
#   Name       : TCardReaderDevice::TCardReaderDevice
#
#   Purpose....: Constructor
#
#   In params..: Port       port number (ie first printer = 1)
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCardReaderDevice::TCardReaderDevice(int Port)
{
        Init(Port);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::~TCardReaderDevice
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCardReaderDevice::~TCardReaderDevice()
{
    if (FHandle)
        RdosCloseCardDev(FHandle);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::Init
#
#   Purpose....: Init device
#
#   In params..: Port       port number (ie first printer = 1)
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCardReaderDevice::Init(int Port)
{
    char str[512];

    BadCard = 0;
    Track1 = 0;
    GoodCard = 0;

    FPort = Port - 1;
    FHandle = RdosOpenCardDev(FPort);

    if (!RdosGetCardDevName(FHandle, str))
        strcpy(str, "Card reader device");
    
    Start(str, 0x2000);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::DeviceName
#
#   Purpose....: Returns device-name
#
#   In params..: MaxLen max size of name
#   Out params.: Name   device name
#   Returns....: *
#
##########################################################################*/
void TCardReaderDevice::DeviceName(char *Name, int MaxLen) const
{
    char str[512];

    if (RdosGetCardDevName(FHandle, str))
        strncpy(Name, str, MaxLen);
    else
        strncpy(Name,"Card reader device",MaxLen);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::IsOnline
#
#   Purpose....: Check if online (and not in error-condition)
#
#   Returns....: TRUE if online
#
##########################################################################*/
int TCardReaderDevice::IsOnline() const
{
    return RdosIsCardDevOk(FHandle);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::IsBusy
#
#   Purpose....: Check if busy
#
#   Returns....: TRUE if busy
#
##########################################################################*/
int TCardReaderDevice::IsBusy() const
{
    return RdosIsCardDevBusy(FHandle);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::IsCardInserted
#
#   Purpose....: Check if card is inserted
#
#   Returns....: TRUE if card inserted
#
##########################################################################*/
int TCardReaderDevice::IsCardInserted() const
{
    return RdosIsCardDevInserted(FHandle);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::WasCardInserted
#
#   Purpose....: Check if card is was inserted
#
#   Returns....: TRUE if card inserted
#
##########################################################################*/
int TCardReaderDevice::WasCardInserted() const
{
    return RdosHadCardDevInserted(FHandle);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::ClearCardInserted
#
#   Purpose....: Clear card is was inserted
#
##########################################################################*/
void TCardReaderDevice::ClearCardInserted() const
{
    RdosClearCardDevInserted(FHandle);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::Execute
#
#   Purpose....: Execute card reader
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCardReaderDevice::Execute()
{
    char Strip[40];
    char Data[80];
    
    while (FInstalled)
    {
        if (RdosWaitForCard(FHandle, Strip))
        {
            if (Track1)
                if (RdosGetCardDevTrack1(FHandle, Data))
                    (*Track1)(this, Data);            

            if (GoodCard)
                (*GoodCard)(this, Strip);
        }
        else
        {
            if (RdosIsCardDevOk(FHandle))
            {
                if (BadCard)
                    (*BadCard)(this);
            }
            else
                RdosWaitMilli(1000);
        } 
    }
}
