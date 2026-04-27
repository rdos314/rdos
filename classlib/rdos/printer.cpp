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
# printer.cpp
# Printer device class
#
########################################################################*/

#include <string.h>
#include "printer.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPrinterDevice::TPrinterDevice
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPrinterDevice::TPrinterDevice()
 : TWaitDevice("Printer")
{
    FHandle = 0;
    FPort = 0;
}

/*##########################################################################
#
#   Name       : TPrinterDevice::TPrinterDevice
#
#   Purpose....: Constructor
#
#   In params..: Port       port number (ie first printer = 1)
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPrinterDevice::TPrinterDevice(int Port)
 : TWaitDevice("Printer")
{
    char str[512];

    Init(Port);
        
    if (RdosGetPrinterName(FHandle, str))
        FDeviceName = str;
}

/*##########################################################################
#
#   Name       : TPrinterDevice::~TPrinterDevice
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPrinterDevice::~TPrinterDevice()
{
    if (FHandle)
        RdosClosePrinter(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::Init
#
#   Purpose....: Init device
#
#   In params..: Port       port number (ie first printer = 1)
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPrinterDevice::Init(int Port)
{
    FPort = Port - 1;
    FHandle = RdosOpenPrinter(FPort);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::GetHandle
#
#   Purpose....: Get handle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPrinterDevice::GetHandle()
{
    return FHandle;
}

/*##########################################################################
#
#   Name       : TPrinterDevice::Add
#
#   Purpose....: Add object to wait
#
#   In params..: wait
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPrinterDevice::Add(TWait *Wait)
{
}

/*##########################################################################
#
#   Name       : TPrinterDevice::IsOnline
#
#   Purpose....: Check if online (and not in error-condition)
#
#   Returns....: TRUE if online
#
##########################################################################*/
bool TPrinterDevice::IsOnline()
{
    return RdosIsPrinterOk(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::IsJammed
#
#   Purpose....: Check if jammed
#
#   Returns....: TRUE if jammed
#
##########################################################################*/
bool TPrinterDevice::IsJammed()
{
    return RdosIsPrinterJammed(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::IsCutterJammed
#
#   Purpose....: Check if cutter jammed
#
#   Returns....: TRUE if cutter jammed
#
##########################################################################*/
bool TPrinterDevice::IsCutterJammed()
{
    return RdosIsPrinterCutterJammed(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::IsPaperLow
#
#   Purpose....: Check if paper is low
#
#   Returns....: TRUE if paper low
#
##########################################################################*/
bool TPrinterDevice::IsPaperLow()
{
    return RdosIsPrinterPaperLow(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::IsPaperEnd
#
#   Purpose....: Check if paper is end
#
#   Returns....: TRUE if paper end
#
##########################################################################*/
bool TPrinterDevice::IsPaperEnd()
{
    return RdosIsPrinterPaperEnd(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::IsPrintHeadLifted
#
#   Purpose....: Check if head is lifted
#
#   Returns....: TRUE if printer head lifted
#
##########################################################################*/
bool TPrinterDevice::IsPrintHeadLifted()
{
    return RdosIsPrinterHeadLifted(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::HasFeedError
#
#   Purpose....: Check if there is a feed error
#
#   Returns....: TRUE if paper feed error
#
##########################################################################*/
bool TPrinterDevice::HasFeedError()
{
    return RdosHasPrinterFeedError(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::HasTemperatureError
#
#   Purpose....: Check if there is a temperature error
#
#   Returns....: TRUE if paper temperature error
#
##########################################################################*/
bool TPrinterDevice::HasTemperatureError()
{
    return RdosHasPrinterTemperatureError(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::HasPaperInPresenter
#
#   Purpose....: Check if there is paper in presenter
#
#   Returns....: TRUE if paper in presenter
#
##########################################################################*/
bool TPrinterDevice::HasPaperInPresenter()
{
    return RdosHasPrinterPaperInPresenter(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::Reset
#
#   Purpose....: Reset
#
#   Returns....:
#
##########################################################################*/
void TPrinterDevice::Reset()
{
    RdosResetPrinter(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::PrintTest
#
#   Purpose....: Make a test printout
#
##########################################################################*/
void TPrinterDevice::PrintTest()
{
    RdosPrintTest(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::CreateBitmap
#
#   Purpose....: Create bitmap of printing
#
#   Parameters.: Height in pixels
#
##########################################################################*/
TBitmapGraphicDevice *TPrinterDevice::CreateBitmap(int Height)
{
    int handle = 0;
    int Width;
    TBitmapGraphicDevice *dev;

    if (FHandle)
        handle = RdosCreatePrinterBitmap(FHandle, Height);

    if (handle)
    {
        dev = new TBitmapGraphicDevice(handle);
        Width = dev->GetWidth();
        dev->SetDrawColor(255, 255, 255);
        dev->SetFilledStyle();
        dev->DrawRect(0, 0, dev->GetWidth() - 1, dev->GetHeight() - 1);
        return dev;
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TPrinterDevice::PrintBitmap
#
#   Purpose....: Print bitmap
#
#   Parameters.: Bitmap
#
##########################################################################*/
void TPrinterDevice::PrintBitmap(TBitmapGraphicDevice *bitmap)
{
    RdosPrintBitmap(FHandle, bitmap->FBitmapHandle);
    delete bitmap;
}

/*##########################################################################
#
#   Name       : TPrinterDevice::WaitForPrint
#
#   Purpose....: Wait for printing to complete
#
#   Parameters.: 
#
##########################################################################*/
void TPrinterDevice::WaitForPrint()
{
    RdosWaitForPrint(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::PresentMedia
#
#   Purpose....: Present media to customer
#
#   Parameters.: mm to present
#
##########################################################################*/
void TPrinterDevice::PresentMedia(int mm)
{
    RdosPresentPrinterMedia(FHandle, mm);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::EjectMedia
#
#   Purpose....: Eject media from printer
#
#   Parameters.:
#
##########################################################################*/
void TPrinterDevice::EjectMedia()
{
    RdosEjectPrinterMedia(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPrinterDevice::SignalNewData()
{
}
