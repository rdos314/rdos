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
# userkey.cpp
# User-mode keyboard class
#
########################################################################*/

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "userkey.h"

#define FALSE       0
#define TRUE        1

#define BUFFER_SIZE 64
#define BUFFER_POLL_INTERVALL   10

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::TUserKeyboardDevice
#
#   Purpose....: Constructor for user-mode keyboard
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUserKeyboardDevice::TUserKeyboardDevice(int Enabled)
{
    FCurrentSize = 0;
    FBuffer = new int[BUFFER_SIZE + 1];
    FInPtr = FBuffer;
    FOutPtr = FBuffer;
}

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::~TUserKeyboardDevice
#
#   Purpose....: Destructor for user-mode keyboard
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUserKeyboardDevice::~TUserKeyboardDevice()
{
    delete FBuffer;
}

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::Put
#
#   Purpose....: Put on character in buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUserKeyboardDevice::Put(int ch)
{
    int Done = FALSE;

    if (KeyPreview != 0)
        Done = (*KeyPreview)(this, ch);

    if (!Done && BUFFER_SIZE > FCurrentSize)            /* Check if space is available. */
        if (FInPtr)
        {
            *FInPtr = ch;
            if (++FInPtr >= FBuffer + BUFFER_SIZE)
                FInPtr = FBuffer;
            FCurrentSize++;
        }
}

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::Put
#
#   Purpose....: Poll keyboard buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TUserKeyboardDevice::Poll() const
{
    if (FCurrentSize)
        return true;
    else
        return false;
}

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::Get
#
#   Purpose....: Get one character from buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUserKeyboardDevice::Get()
{
    int     ch = 0;

    if (FCurrentSize)
    {
        ch = *FOutPtr;
        if (++FOutPtr >= FBuffer + BUFFER_SIZE)
            FOutPtr = FBuffer;
        FCurrentSize--;
    }
    return ch;
}

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::Peek
#
#   Purpose....: Peek one character from buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUserKeyboardDevice::Peek()
{
    if (FCurrentSize)
        return *FOutPtr;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::Clear
#
#   Purpose....: Clear keyboard buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUserKeyboardDevice::Clear()
{
    FInPtr = FBuffer;
    FOutPtr = FBuffer;
    FCurrentSize = 0;
}
