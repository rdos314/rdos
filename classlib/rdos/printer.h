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
# printer.h
# Printer device class
#
########################################################################*/

#ifndef _PRINTER_H
#define _PRINTER_H

#include "waitdev.h"
#include "bitdev.h"

class TPrinterDevice : public TWaitDevice
{
public:
    TPrinterDevice(int Port);
    ~TPrinterDevice();

    int GetHandle();

    virtual void DeviceName(char *Name, int MaxLen) const;

    virtual int IsOnline();

    virtual int IsJammed();
    virtual int IsCutterJammed();
    virtual int IsPaperLow();
    virtual int IsPaperEnd();
    virtual int IsPrintHeadLifted();
    virtual int HasFeedError();
    virtual int HasTemperatureError();
    virtual int HasPaperInPresenter();
    virtual void Reset();

    virtual void PrintTest();

    TBitmapGraphicDevice *CreateBitmap(int Height);
    void PrintBitmap(TBitmapGraphicDevice *bitmap);
    void WaitForPrint();

    virtual void PresentMedia(int mm);
    virtual void EjectMedia();

protected:
    TPrinterDevice(const char *IniSection);
    TPrinterDevice();

    virtual void SignalNewData();
    virtual void Add(TWait *Wait);

private:
    void Init(int Port);

    int FHandle;
    int FPort;

};

#endif

