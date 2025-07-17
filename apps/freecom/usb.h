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
# usb.h
# USB command class
#
########################################################################*/

#ifndef _USB_H
#define _USB_H

#include "cmd.h"
#include "cmdfact.h"

struct TUsbDescr
{
    unsigned char len;
    char type;
};

struct TUsbDevice
{
    char len;
    char type;
    short int usb_ver;
    char class_id;
    char sub_class;
    char proto;
    char maxlen;
    short int vendor;
    short int prod;
    short int device;
    char man;
    char prodid;
        char num;
    char configs;
};

struct TUsbConfig
{
    char len;
    char type;
    short int size;
    char interface_count;
    char config_id;
    char config_str_id;
    char attrib;
    char power;
};

struct TUsbInterface
{
        char len;
        char type;
        char interface_id;
        char alt_setting;
        char endpoint_count;
        char class_id;
        char sub_class;
        char proto;
        char str_id;
};

struct TUsbEndpoint
{
        char len;
        char type;
        char address;
        char attrib;
        short int maxsize;
        char interval;
};


class TUsbFactory : public TCommandFactory
{
public:
        TUsbFactory();
        virtual TCommand *Create(TSession *session, const char *param);

protected:
};

class TUsbCommand : public TCommand
{
public:
        TUsbCommand(TSession *session, const char *param);

        virtual int Execute(char *param);

protected:
        void ShowClass(char class_id, char sub_class, char protocol, int indent);
        void ShowDevice(int control, int device, TUsbDevice *dev);
        void ShowConfig(int config, TUsbConfig *dev);
        void ShowInterface(int control, int device, TUsbInterface *descr);
        void ShowEndpoint(TUsbEndpoint *descr);
        void ShowDescr(int control, int device, TUsbDescr *descr);
        void Show();
        void Reset();

};

#endif
