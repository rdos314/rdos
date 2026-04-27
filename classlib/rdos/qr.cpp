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
# qr.cpp
# QR code class
#
########################################################################*/

#include "qr.h"
#include "qrcodegen.h"

/*##########################################################################
#
#   Name       : TQrBitmap::TQrBitmap
#
#   Purpose....: Constructor for TQrBitmap
#
#   In params..: 
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQrBitmap::TQrBitmap(const char *text)
{
    int len;
    unsigned char *tempbuf;
    
    len = qrcodegen_BUFFER_LEN_FOR_VERSION(qrcodegen_VERSION_MAX);
    FQrBuf = new unsigned char [len + 1];
    tempbuf = new unsigned char [len + 1];

    FOk = qrcodegen_encodeText(text, tempbuf, FQrBuf, qrcodegen_Ecc_MEDIUM, qrcodegen_VERSION_MIN, qrcodegen_VERSION_MAX, qrcodegen_Mask_AUTO, true);
    FSize = 0;
    FPixels = 0;

    delete tempbuf;
}

/*##########################################################################
#
#   Name       : TQrBitmap::~TQrBitmap
#
#   Purpose....: Destructor for TQrBitmap
#
#   In params..: 
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQrBitmap::~TQrBitmap()
{
    if (FQrBuf)
        delete FQrBuf;
}

/*##########################################################################
#
#   Name       : TQrBitmap::AdjustSize
#
#   Purpose....: Adjust size
#
#   In params..: 
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TQrBitmap::AdjustSize(int MaxSize)
{
    if (FOk)
    {
        FSize = qrcodegen_getSize(FQrBuf);
        FPixels = MaxSize / FSize;
    }
    else
        FSize = 0;
    
    return FSize * FPixels;
}

/*##########################################################################
#
#   Name       : TQrBitmap::SetupBitmap
#
#   Purpose....: Setup bitmap
#
#   In params..: 
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TQrBitmap::SetupBitmap(TGraphicDevice *bitmap, int xstart, int ystart)
{
    int x, y;
    bool off;

    bitmap->SetLgopNone();
    bitmap->SetFilledStyle();
    
    if (FSize)
    {
        for (x = 0; x < FSize; x++)
        {
            for (y = 0; y < FSize; y++)
            {
                off = qrcodegen_getModule(FQrBuf, x, y);
                if (off)
                    bitmap->SetDrawColor(0, 0, 0);
                else
                    bitmap->SetDrawColor(255, 255, 255);
                    
                bitmap->DrawRect(xstart + FPixels * x, ystart + FPixels * y, xstart + FPixels * x - FPixels - 1, ystart + FPixels * y - FPixels - 1); 
            }
        }
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TQrBitmap::SetupBitmap
#
#   Purpose....: Setup bitmap
#
#   In params..: 
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBitmapGraphicDevice *TQrBitmap::CreateBitmap(int MaxSize)
{
    TBitmapGraphicDevice *bitmap = 0;

    if (FOk)
    {
        FSize = qrcodegen_getSize(FQrBuf);
        FPixels = MaxSize / FSize;
        bitmap = new TBitmapGraphicDevice(1, FSize * FPixels, FSize * FPixels);
        SetupBitmap(bitmap, 0, 0);
    }
    
    return bitmap;
}
