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
# serial.cpp
# Serial device class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include "serial.h"

#ifdef __RDOS__
#include "rdos.h"
#include "path.h"
#include "direntry.h"
#else
#include <filesystem>
#include <fstream>
#include <string>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/usbdevice_fs.h>
#include <linux/serial.h>
#include <errno.h>
#include <poll.h>
#include "str.h"
#endif

#ifndef __RDOS__

namespace fs=std::filesystem;

#define MAX_PORTS 100


static bool IsInited = false;
static TSection FPortSection("Serial Ports");
static TLinuxSerial *PortArr[MAX_PORTS];


TLinuxSerial::TLinuxSerial()
{
    IsUsed = false;
}

TLinuxSerial::~TLinuxSerial()
{
}

int TLinuxSerial::GetSendBufferSpace()
{
    return 1000;
}

int TLinuxSerial::GetReceiveBufferSpace()
{
    return 1000;
}

void TLinuxSerial::Reset()
{
}

bool TLinuxSerial::IsStdSerial()
{
    return false;
}

bool TLinuxSerial::IsUsbSerial()
{
    return false;
}

bool TLinuxSerial::IsCanSerial()
{
    return false;
}

TLinuxTtySerial::TLinuxTtySerial(const char *dev)
  : FDev(dev)
{
    FHandle = -1;
    FBaudrate = 0;
    FParity = 0;
    FDataBits = 0;
    FStopBits = 0;
}


TLinuxTtySerial::~TLinuxTtySerial()
{
}

bool TLinuxTtySerial::Open(long Baudrate, char Parity, int DataBits, int StopBits)
{
    struct termios tty;
    speed_t speed;
    bool ok;

    if (FHandle > 0)
        return true;

    FHandle = open(FDev.GetData(), O_RDWR | O_NOCTTY | O_NDELAY);

    if (FHandle < 0)
        return false; // Could not open the port

    FBaudrate = Baudrate;
    FParity = Parity;
    FDataBits = DataBits;
    FStopBits = StopBits;

    if (tcgetattr(FHandle, &tty) != 0)
        ok = false;
    else
        ok = true;

    if (ok)
    {
        switch (Baudrate)
        {
            case 110:    speed = B110;    break;
            case 300:    speed = B300;    break;
            case 600:    speed = B600;    break;
            case 1200:   speed = B1200;   break;
            case 2400:   speed = B2400;   break;
            case 4800:   speed = B4800;   break;
            case 9600:   speed = B9600;   break;
            case 19200:  speed = B19200;  break;
            case 38400:  speed = B38400;  break;
            case 57600:  speed = B57600;  break;
            case 115200: speed = B115200; break;
            default: ok = false;
        }

        if (ok)
        {
            tty.c_cflag &= ~CRTSCTS;
            cfsetospeed(&tty, speed);
            cfsetispeed(&tty, speed);
        }
    }

    // Set data bits
    if (ok)
    {
        tty.c_cflag &= ~CSIZE;
        switch (DataBits)
        {
            case 5:
                tty.c_cflag |= CS5;
                break;

            case 6:
                tty.c_cflag |= CS6;
                break;

            case 7:
                tty.c_cflag |= CS7;
                break;

            case 8:
                tty.c_cflag |= CS8;
                break;

            default:
                ok = false;
        }
    }

    if (ok)
    {
        switch (Parity)
        {
            case 'N':
                tty.c_cflag &= ~PARENB;
                break;

            case 'E':
                tty.c_cflag |= PARENB;
                tty.c_cflag &= ~PARODD;
                break;

            case 'O':
                tty.c_cflag |= PARENB;
                tty.c_cflag |= PARODD;
                break;

            default:
                ok = false;
        }
    }

    if (ok)
    {
        switch (StopBits)
        {
            case 1:
                tty.c_cflag &= ~CSTOPB;
                break;

            case 2:
                tty.c_cflag |= CSTOPB;
                break;

            default:
                ok = false;
        }
    }

    if (tcsetattr(FHandle, TCSANOW, &tty) != 0)
        ok = false;

    if (!ok && FHandle > 0)
        close(FHandle);

    return ok;
}

void TLinuxTtySerial::Close()
{
    if (FHandle > 0)
    {
        close(FHandle);
        FHandle = 0;
    }
}

bool TLinuxTtySerial::IsOpen()
{
    return FHandle > 0;
}

bool TLinuxTtySerial::Reopen()
{
    Close();
    if (!Open(FBaudrate, FParity, FDataBits, FStopBits))
    {
        usleep(100000);
        return false;
    }
    return true;
}

void TLinuxTtySerial::Clear()
{
    if (FHandle > 0)
        tcflush(FHandle, TCIOFLUSH);
}

bool TLinuxTtySerial::GetCts()
{
    int status;

    if (FHandle <= 0)
        return false;

    if (ioctl(FHandle, TIOCMGET, &status) == -1)
        return false;

    return (status & TIOCM_CTS) != 0;
}

bool TLinuxTtySerial::GetDsr()
{
    int status;

    if (FHandle <= 0)
        return false;

    if (ioctl(FHandle, TIOCMGET, &status) == -1)
        return false;

    return (status & TIOCM_DSR) != 0;
}

void TLinuxTtySerial::ResetDtr()
{
    int mask = TIOCM_DTR;

    if (FHandle <= 0)
        return;

    ioctl(FHandle, TIOCMBIC, &mask);
}

void TLinuxTtySerial::SetDtr()
{
    int mask = TIOCM_DTR;

    if (FHandle <= 0)
        return;

    ioctl(FHandle, TIOCMBIS, &mask);
}

void TLinuxTtySerial::ResetRts()
{
    int mask = TIOCM_RTS;

    if (FHandle <= 0)
        return;

    ioctl(FHandle, TIOCMBIC, &mask);
}

void TLinuxTtySerial::SetRts()
{
    int mask = TIOCM_RTS;

    if (FHandle <= 0)
        return;

    ioctl(FHandle, TIOCMBIS, &mask);
}

void TLinuxTtySerial::EnableAutoRts()
{
    struct serial_rs485 rs485conf;

    if (FHandle <= 0)
        return;

    memset(&rs485conf, 0, sizeof(rs485conf));
    rs485conf.flags |= SER_RS485_ENABLED;
    rs485conf.flags |= SER_RS485_RTS_ON_SEND;
    rs485conf.flags |= SER_RS485_RTS_AFTER_SEND;
    ioctl(FHandle, TIOCSRS485, &rs485conf);
}

void TLinuxTtySerial::DisableAutoRts()
{
    struct serial_rs485 rs485conf;

    if (FHandle <= 0)
        return;

    memset(&rs485conf, 0, sizeof(rs485conf));
    ioctl(FHandle, TIOCSRS485, &rs485conf);
}

bool TLinuxTtySerial::IsAutoRtsOn()
{
    struct serial_rs485 rs485conf;

    if (FHandle <= 0)
        return false;

    if (ioctl(FHandle, TIOCGRS485, &rs485conf) < 0)
        return false;

    return (rs485conf.flags & SER_RS485_ENABLED) != 0;
}

void TLinuxTtySerial::SendBreak(char CharCount)
{
    if (FHandle <= 0)
        return;

    ioctl(FHandle, TCSBRK, 0);
}

void TLinuxTtySerial::Write(const char *buf, int count)
{
    if (FHandle <= 0)
        return;

    while (count > 0)
    {
        int written = write(FHandle, buf, count);
        if (written > 0)
        {
            buf += written;
            count -= written;
        }
        else if (written == -1)
        {
            if (errno == EAGAIN || errno == EWOULDBLOCK)
            {
                usleep(1000);
                continue;
            }
            else if (errno == EIO || errno == ENODEV || errno == ENXIO || errno == EBADF)
                Reopen();

            break;
        }
    }
}

void TLinuxTtySerial::Write(char ch)
{
    Write(&ch, 1);
}

void TLinuxTtySerial::Write(const char *str)
{
    Write(str, strlen(str));
}

void TLinuxTtySerial::WaitForSendCompleted()
{
    if (FHandle > 0)
        tcdrain(FHandle);
}

bool TLinuxTtySerial::Poll()
{
    int bytes_available = 0;

    if (FHandle <= 0)
        return false;

    if (ioctl(FHandle, FIONREAD, &bytes_available) == -1)
        return false;

    return bytes_available > 0;
}

char TLinuxTtySerial::Read()
{
    char ch = 0;
    int n;

    if (FHandle <= 0)
        return 0;

    n = read(FHandle, &ch, 1);

    if (n == 1)
        return ch;
    else if (n == -1)
    {
        if (errno == EIO || errno == ENODEV || errno == ENXIO || errno == EBADF)
            Reopen();
    }
    return 0;
}

bool TLinuxTtySerial::WaitForChar(long Timeout)
{
    struct pollfd pfd;
    int ret;

    if (FHandle <= 0)
        return false;

    pfd.fd = FHandle;
    pfd.events = POLLIN;

    ret = poll(&pfd, 1, (int)Timeout);

    if (ret > 0 && (pfd.revents & POLLIN))
        return true;

    return false;
}

bool TLinuxTtySerial::SupportsFullDuplex()
{
    return false;
}

void TLinuxTtySerial::EnableCts()
{
    struct termios tty;

    if (FHandle <= 0)
        return;

    if (tcgetattr(FHandle, &tty) == 0)
    {
        tty.c_cflag |= CRTSCTS;
        tcsetattr(FHandle, TCSANOW, &tty);
    }
}

void TLinuxTtySerial::DisableCts()
{
    struct termios tty;

    if (FHandle <= 0)
        return;

    if (tcgetattr(FHandle, &tty) == 0)
    {
        tty.c_cflag &= ~CRTSCTS;
        tcsetattr(FHandle, TCSANOW, &tty);
    }
}

TLinuxStdSerial::TLinuxStdSerial(const char *dev, int base, int irq)
  : TLinuxTtySerial(dev)
{
    FIoBase = base;
    FIrq = irq;
}

TLinuxStdSerial::~TLinuxStdSerial()
{
}

bool TLinuxStdSerial::IsStdSerial()
{
    return true;
}

int TLinuxStdSerial::GetBase()
{
    return FIoBase;
}

int TLinuxStdSerial::GetIrq()
{
    return FIrq;
}

TLinuxUsbSerial::TLinuxUsbSerial(const char *dev, int bus, int device, int vendor, int product)
  : TLinuxTtySerial(dev)
{
    FBus = bus;
    FDevice = device;
    FVendor = vendor;
    FProduct = product;
}

TLinuxUsbSerial::~TLinuxUsbSerial()
{
}

bool TLinuxUsbSerial::IsUsbSerial()
{
    return true;
}

void TLinuxUsbSerial::Reset()
{
    char path[64];
    snprintf(path, sizeof(path), "/dev/bus/usb/%03d/%03d", FBus, FDevice);
    int fd = open(path, O_WRONLY);
    if (fd >= 0)
    {
        ioctl(fd, USBDEVFS_RESET, 0);
        close(fd);
    }
}

int TLinuxUsbSerial::GetBus()
{
    return FBus;
}

int TLinuxUsbSerial::GetDevice()
{
    return FDevice;
}

int TLinuxUsbSerial::GetVendor()
{
    return FVendor;
}

int TLinuxUsbSerial::GetProduct()
{
    return FProduct;
}

static void AddSerial(TLinuxSerial *serial)
{
    int i;

    for (i = 0; i < MAX_PORTS; ++i)
    {
        if (PortArr[i] == 0)
        {
            PortArr[i] = serial;
            return;
        }
    }
    delete serial;
}

static bool FindUsbSerial(int bus, int device, int vendor, int product)
{
    int i;
    TLinuxUsbSerial *serial;

    for (i = 0; i < MAX_PORTS; ++i)
    {
        if (PortArr[i] && PortArr[i]->IsUsbSerial())
        {
            serial = (TLinuxUsbSerial *)PortArr[i];
            if (serial->GetBus() == bus && serial->GetDevice() == device && serial->GetVendor() == vendor && serial->GetProduct() == product)
                return true;
        }
    }
    return false;
}

static void FoundUsbSerial(const char *dev, int bus, int device, int vendor, int product)
{
    TLinuxUsbSerial *serial;

    if (!FindUsbSerial(bus, device, vendor, product))
    {
        serial = new TLinuxUsbSerial(dev, bus, device, vendor, product);
        AddSerial(serial);
    }
}

static bool readFile(const fs::path& p, std::string& out)
{
    std::ifstream f(p);
    if (!f) return false;
    f >> out;
    return true;
}

static void GetUarts()
{
    TLinuxStdSerial *serial;
    int irq;
    unsigned long iobase;
    int type;

    for (int i = 0; i < 32; ++i)
    {
        std::string tty = "/dev/ttyS" + std::to_string(i);
        if (fs::exists(tty))
        {
            std::string str;
            fs::path base = "/sys/class/tty/ttyS" + std::to_string(i);

            readFile(base / "type", str);
            type = str.empty() ? 0 : std::stoi(str);

            readFile(base / "irq", str);
            irq = str.empty() ? 0 : std::stoi(str);

            readFile(base / "port", str);
            iobase = str.empty() ? 0 : std::stoul(str, nullptr, 16);

            if (irq > 0 && type)
            {
                serial = new TLinuxStdSerial(tty.c_str(), iobase, irq);
                AddSerial(serial);
            }
        }
    }
}

static void GetUsbSerial()
{
    int i;
    int vendor;
    int product;
    int bus;
    int device;

    fs::path usbSerialDir = "/sys/bus/usb-serial/devices";
    if (fs::exists(usbSerialDir))
    {
        for (const auto& entry : fs::directory_iterator(usbSerialDir))
        {
            std::string tty = entry.path().filename();
            fs::path iface = fs::canonical(entry.path());
            fs::path parent = iface.parent_path();
            std::string str;

            for (i = 0; i < 3; i++)
            {
                readFile(parent / "busnum", str);
                bus = str.empty() ? -1 : std::stoi(str);
                if (bus >= 0)
                    break;
                else
                    parent = parent.parent_path();
            }

            if (bus >= 0)
            {
                readFile(parent / "idVendor", str);
                vendor = str.empty() ? 0 : std::stoul(str, nullptr, 16);

                readFile(parent / "idProduct", str);
                product = str.empty() ? 0 : std::stoul(str, nullptr, 16);

                readFile(parent / "devnum", str);
                device = str.empty() ? 0 : std::stoi(str);

                std::string tty_full = "/dev/" + tty;

                FoundUsbSerial(tty_full.c_str(), bus, device, vendor, product);
            }
        }
    }
}

/**
 * Enumerates USB CDC devices by scanning /sys/class/tty and printing their USB details.
 */
static void GetUsbCdc()
{
    int i;
    TLinuxUsbSerial *serial;
    int vendor;
    int product;
    int bus;
    int device;

    fs::path usbCdcDir = "/sys/class/tty";
    if (fs::exists(usbCdcDir))
    {
        for (const auto& entry : fs::directory_iterator(usbCdcDir))
        {
            std::string tty = entry.path().filename();
            fs::path iface = fs::canonical(entry.path());
            fs::path parent = iface.parent_path();
            std::string str;

            for (i = 0; i < 3; i++)
            {
                readFile(parent / "busnum", str);
                bus = str.empty() ? -1 : std::stoi(str);
                if (bus >= 0)
                    break;
                else
                    parent = parent.parent_path();
            }

            if (bus >= 0)
            {
                readFile(parent / "idVendor", str);
                vendor = str.empty() ? 0 : std::stoul(str, nullptr, 16);

                readFile(parent / "idProduct", str);
                product = str.empty() ? 0 : std::stoul(str, nullptr, 16);

                readFile(parent / "devnum", str);
                device = str.empty() ? 0 : std::stoi(str);

                std::string tty_full = "/dev/" + tty;

                FoundUsbSerial(tty_full.c_str(), bus, device, vendor, product);
            }
        }
    }
}

static void UpdateUsbSerial()
{
    FPortSection.Enter();
    GetUsbSerial();
    GetUsbCdc();
    FPortSection.Leave();
}

static void InitSerial()
{
    int i;

    if (!IsInited)
    {
        IsInited = true;

        for (i = 0; i < MAX_PORTS; ++i)
            PortArr[i] = 0;

        GetUarts();
        UpdateUsbSerial();
    }
}

#endif

TSerialCommand::TSerialCommand(TSerialDevice *serial)
{
    FSerial = serial;
}

TSerialCommand::~TSerialCommand()
{
}

void TSerialCommand::Block()
{
    FSerial->Block();
}

void TSerialCommand::Unblock()
{
    FSerial->Unblock();
}

int TSerialCommand::Run()
{
    int stat;

    FSerial->Block();
    stat = Execute();
    FSerial->Unblock();
    return stat;
}

void TSerialCommand::Clear()
{
    FSerial->Clear();
}

bool TSerialCommand::DefineEventDebug(const char *LogPath, int DumpFiles, int EntryCount, int InChannel, int OutChannel)
{
    return FSerial->DefineEventDebug(LogPath, DumpFiles, EntryCount, InChannel, OutChannel);
}

bool TSerialCommand::DumpEvents()
{
    return FSerial->DumpEvents();
}

void TSerialCommand::ResetDtr()
{
    FSerial->ResetDtr();
}

void TSerialCommand::SetDtr()
{
    FSerial->SetDtr();
}

void TSerialCommand::ResetRts()
{
    FSerial->ResetRts();
}

void TSerialCommand::SetRts()
{
    FSerial->SetRts();
}

void TSerialCommand::EnableAutoRts()
{
    FSerial->EnableAutoRts();
}

void TSerialCommand::DisableAutoRts()
{
    FSerial->DisableAutoRts();
}

void TSerialCommand::Write(char ch)
{
    FSerial->Write(ch);
}

void TSerialCommand::Write(const char *buf, int count)
{
    FSerial->Write(buf, count);
}

void TSerialCommand::Write(const char *str)
{
    FSerial->Write(str);
}

char TSerialCommand::Read()
{
    return FSerial->Read();
}

bool TSerialCommand::WaitForChar(long MaxWait)
{
    return FSerial->WaitForChar(MaxWait);
}

TSerialDevice::TSerialDevice()
 : TWaitDevice("Serial Device"),
   FSection("Serial"),
   FEventSection("EvSerial")
{
    Init();
}

#ifdef __RDOS__

TSerialDevice::TSerialDevice(int Handle)
 : TWaitDevice("Serial Device"),
   FSection("Serial"),
   FEventSection("EvSerial")
{
    Init();

    FPort = 0;
    FHandle = Handle;
    FSupportsFullDuplex = RdosSupportsFullDuplex(FHandle);
}
#endif

TSerialDevice::TSerialDevice(int Port, long Baudrate)
  : TWaitDevice("Serial Device"),
    FSection("Serial"),
    FEventSection("EvSerial")
{
    Init(Port, Baudrate, 'N', 8, 1);
}

TSerialDevice::TSerialDevice(int Port, long Baudrate, char Parity, int DataBits, int StopBits)
  : TWaitDevice("Serial Device"),
    FSection("Serial"),
    FEventSection("EvSerial")
{
    Init(Port, Baudrate, Parity, DataBits, StopBits);
}

TSerialDevice::~TSerialDevice()
{
    Stop();

#ifdef __RDOS__
    if (FHandle)
        RdosCloseCom(FHandle);
#else
    if (FSerial)
    {
        FSerial->Close();
        FSerial->IsUsed = false;
    }
#endif
}

void TSerialDevice::Init()
{
    OnChar = 0;

    FPort = 0;
    FBaudrate = 9600;
    FParity = 'N';
    FDataBits = 8;
    FStopBits = 1;
    FDebugFile = 0;
    FCurrFile = 0;
    FCurrId = 0;
    FNextPos = 0;
    FEntryCount = 0;
    FFileCount = 0;
    FUseCts = false;
    FBufferSize = 0x4000;

#ifdef __RDOS__
    FHandle = 0;
#else
    if (FSerial)
    {
        FSerial->Close();
        FSerial = 0;
    }
#endif
}

void TSerialDevice::Init(int Port, long Baudrate, char Parity, int DataBits, int StopBits)
{
    Init();

    FPort = Port;
    FBaudrate = Baudrate;
    FParity = Parity;
    FDataBits = DataBits;
    FStopBits = StopBits;

#ifndef __RDOS__

    if (Port > 0 && Port <= MAX_PORTS)
    {
        if (!IsInited)
            InitSerial();

        FPortSection.Enter();

        FSerial = PortArr[Port - 1];
        if (FSerial && FSerial->IsUsed)
            FSerial = 0;

        if (FSerial)
            FSerial->IsUsed = true;

        FPortSection.Leave();
    }
    else
        FSerial = 0;

#endif

    OpenPort();
}

void TSerialDevice::Block()
{
    FSection.Enter();
}

void TSerialDevice::Unblock()
{
    FSection.Leave();
}

#ifdef __RDOS__

void TSerialDevice::Add(TWait *Wait)
{
    if (FHandle)
        RdosAddWaitForCom(Wait->GetHandle(), FHandle, (int)this);
}

int TSerialDevice::GetHandle()
{
    return FHandle;
}

#else

bool TSerialDevice::WaitForever()
{
    return false;
}

bool TSerialDevice::WaitTimeout(int Timeout)
{
    return false;
}

bool TSerialDevice::WaitUntil(TDateTime &DateTime)
{
    return false;
}

#endif

void TSerialDevice::SetBufferSize(int Size)
{
    FBufferSize = Size;
}

void TSerialDevice::StartDebug(TFile *File, int InChannel, int OutChannel)
{
    FDebugFile = File;
    FInChannel = InChannel;
    FOutChannel = OutChannel;
}

void TSerialDevice::StopDebug()
{
    FDebugFile = 0;
}

void TSerialDevice::CheckFileCount()
{
#ifdef __RDOS__
    TDirList FileList;
    TDirEntry entry;
    TString basename;
    TPathName path;
    char *file;
    int count = 0;
    bool ok;

    file = new char[256];

    FileList.AddSortByTime();
    FileList.Add(FLogPath);
    FileList.Sort();

    ok = FileList.GotoLast();

    while (ok)
    {
        entry = FileList.Get();
        basename = entry.GetEntryName();
        strcpy(file, basename.GetData());
        if (strstr(file, ".sdd"))
        {
            if (entry.GetFileSize() == 0)
            {
                path = entry.GetPathName();
                if (path.IsFile())
                    path.DeleteFile();
            }
            else
            {
                count++;
                if (count > FFileCount)
                {
                    path = entry.GetPathName();
                    if (path.IsFile())
                        path.DeleteFile();
                }
            }
        }
            
        ok = FileList.GotoPrev();
    }    

    delete file;
#endif
}

void TSerialDevice::InitFiles()
{
#ifdef __RDOS__
    bool ok;
    TDirList FileList;
    TDirEntry entry;
    TString basename;
    TPathName path;
    char *file;
    char *ptr;
    int index;
    TString str;

    CheckFileCount();        

    FCurrId = 0;

    file = new char[256];

    FileList.AddSortByTime();
    FileList.Add(FLogPath);
    FileList.Sort();

    ok = FileList.GotoFirst();

    while (ok)
    {
        entry = FileList.Get();
        basename = entry.GetEntryName();
        strcpy(file, basename.GetData());
        if (strstr(file, ".sdd"))
        {
            ptr = strchr(file, '.');
            if (ptr)
                *ptr = 0;

            index = atoi(file);            

            if (index > FCurrId)
                FCurrId = index;
        }
            
        ok = FileList.GotoNext();
    }    

    delete file;

    FCurrId++;
    str.printf("%s/%d.sdd", FLogPath.GetData(), FCurrId);
    FCurrFile = new TFile(str.GetData(), 0);
#endif
}

bool TSerialDevice::DefineEventDebug(const char *LogPath, int DumpFiles, int EntryCount, int InChannel, int OutChannel)
{
#ifdef __RDOS__
    int i;

    FLogPath = LogPath;
    FInChannel = InChannel;
    FOutChannel = OutChannel;
    FFileCount = DumpFiles;

    TPathName path(FLogPath);

    if (path.MakeDir())
    {        
        CheckFileCount();

        FEntryCount = EntryCount;
        FEntryArr = new struct TSerialDebug[EntryCount];

        // initialize cache to empty
        for (i = 0; i < EntryCount; i++) 
        {
            FEntryArr[i].Channel = 0;
            FEntryArr[i].Time = 0;
            FEntryArr[i].ch = 0;
        }

        return true;
    }
    else
    {
        FFileCount = 0;
        return false;
    }
#else
    return false;
#endif
}

bool TSerialDevice::DumpEvents()
{
    TString str;

    if (FFileCount && FInChannel && FOutChannel && !IsRunning() && FNewData)
    {
        str.printf("ComLog %d", FPort);
        Start(str.GetData(), 0x4000);
        return true;
    }
    else
        return false;
}

void TSerialDevice::Execute()
{
#ifdef __RDOS__
    int pos;
    struct TSerialDebug *DumpArr;
    TPathName path(FLogPath);

    RdosWaitMilli(100);

    if (path.MakeDir())
    {        
        InitFiles();

        DumpArr = new struct TSerialDebug[FEntryCount];

        FEventSection.Enter();

        pos = FNextPos;

        for (int i = 0; i < FEntryCount; i++)
            DumpArr[i] = FEntryArr[i];

        FNewData = false;
        
        FEventSection.Leave();
        
        for (int i = pos; i < FEntryCount; i++) 
            if (DumpArr[i].Time)
                FCurrFile->Write(&DumpArr[i], sizeof(struct TSerialDebug));

        for (int i = 0; i < pos; i++)
            if (DumpArr[i].Time)
                FCurrFile->Write(&DumpArr[i], sizeof(struct TSerialDebug));

        delete DumpArr;
        delete FCurrFile;
        FCurrFile = 0;
    }
#endif
}

void TSerialDevice::OpenPort()
{
#ifdef __RDOS__
    if (FPort)
        FHandle = RdosOpenCom(FPort - 1, FBaudrate, FParity, FDataBits, FStopBits, FBufferSize, FBufferSize);
    else
        FHandle = 0;
        
    if (FHandle)
    {
        FSupportsFullDuplex = RdosSupportsFullDuplex(FHandle);

        if (FUseCts)
            RdosEnableCts(FHandle);
        else
            RdosDisableCts(FHandle);
    }
#else
    if (FSerial)
        FSerial->Open(FBaudrate, FParity, FDataBits, FStopBits);
#endif
}

bool TSerialDevice::IsOpen()
{
#ifdef __RDOS__
    if (FHandle)
        return true;
    else
        return false;
#else
    if (FSerial && FSerial->IsOpen())
        return true;
    else
        return false;
#endif
}

void TSerialDevice::Open()
{
#ifdef __RDOS__
    if (!FHandle)
        OpenPort();
#else
    if (FSerial)
        OpenPort();
#endif
}

void TSerialDevice::Close()
{
#ifdef __RDOS__
    if (FHandle)
    {
        RdosCloseCom(FHandle);
        FHandle = 0;
    }
#else
    if (FSerial)
        FSerial->Close();
#endif
}

void TSerialDevice::Clear()
{
#ifdef __RDOS__
    if (FHandle)
        RdosFlushCom(FHandle);
#else
    if (FSerial)
        FSerial->Clear();
#endif
}

void TSerialDevice::SetBaudrate(long Baudrate)
{
    if (IsOpen())
    {
        Close();
        FBaudrate = Baudrate;
        Open();
    }
    else
        FBaudrate = Baudrate;
}

void TSerialDevice::SetParity(char Parity)
{
    if (IsOpen())
    {
        Close();
        FParity = Parity;
        Open();
    }
    else
        FParity = Parity;
}

void TSerialDevice::SetDataBits(int DataBits)
{
    if (IsOpen())
    {
        Close();
        FDataBits = DataBits;
        Open();
    }
    else
        FDataBits = DataBits;
}

void TSerialDevice::SetStopBits(int StopBits)
{
    if (IsOpen())
    {
        Close();
        FStopBits = StopBits;
        Open();
    }
    else
        FStopBits = StopBits;
}

int TSerialDevice::GetPort() const
{
    return FPort;
}

long TSerialDevice::GetBaudrate() const
{
    return FBaudrate;
}

char TSerialDevice::GetParity() const
{
    return FParity;
}

int TSerialDevice::GetDataBits() const
{
    return FDataBits;
}

int TSerialDevice::GetStopBits() const
{
    return FStopBits;
}

int TSerialDevice::GetSendBufferSpace()
{
    return 1000;
}

int TSerialDevice::GetReceiveBufferSpace()
{
    return 1000;
}

bool TSerialDevice::SupportsFullDuplex()
{
    return FSupportsFullDuplex;
}

void TSerialDevice::Reset()
{
#ifdef __RDOS__
    if (FHandle)
        RdosResetCom(FHandle);
#else
    if (FSerial)
        FSerial->Reset();
#endif
}

void TSerialDevice::EnableCts()
{
    FUseCts = true;

#ifdef __RDOS__
    if (FHandle)
        RdosEnableCts(FHandle);
#else
    if (FSerial)
        FSerial->EnableCts();
#endif
}

void TSerialDevice::DisableCts()
{
    FUseCts = false;

#ifdef __RDOS__
    if (FHandle)
        RdosDisableCts(FHandle);
#else
    if (FSerial)
        FSerial->DisableCts();
#endif
}

bool TSerialDevice::GetCts()
{
#ifdef __RDOS__
    if (FHandle)
        return RdosGetCts(FHandle);
    else
        return false;
#else
    if (FSerial)
        return FSerial->GetCts();
    else
        return false;
#endif
}

bool TSerialDevice::GetDsr()
{
#ifdef __RDOS__
    if (FHandle)
        return RdosGetDsr(FHandle);
    else
        return false;
#else
    if (FSerial)
        return FSerial->GetDsr();
    else
        return false;
#endif
}

void TSerialDevice::ResetDtr()
{
#ifdef __RDOS__
    if (FHandle)
        RdosResetDtr(FHandle);
#else
    if (FSerial)
        FSerial->ResetDtr();
#endif
}

void TSerialDevice::SetDtr()
{
#ifdef __RDOS__
    if (FHandle)
        RdosSetDtr(FHandle);
#else
    if (FSerial)
        FSerial->SetDtr();
#endif
}

void TSerialDevice::ResetRts()
{
#ifdef __RDOS__
    if (FHandle)
        RdosResetRts(FHandle);
#else
    if (FSerial)
        FSerial->ResetRts();
#endif
}

void TSerialDevice::SetRts()
{
#ifdef __RDOS__
    if (FHandle)
        RdosSetRts(FHandle);
#else
    if (FSerial)
        FSerial->SetRts();
#endif
}

void TSerialDevice::EnableAutoRts()
{
#ifdef __RDOS__
    if (FHandle)
        RdosEnableAutoRts(FHandle);
#else
    if (FSerial)
        FSerial->EnableAutoRts();
#endif
}

void TSerialDevice::DisableAutoRts()
{
#ifdef __RDOS__
    if (FHandle)
        RdosDisableAutoRts(FHandle);
#else
    if (FSerial)
        FSerial->DisableAutoRts();
#endif
}

bool TSerialDevice::IsAutoRtsOn()
{
#ifdef __RDOS__
    if (FHandle)
        return RdosIsAutoRtsOn(FHandle);
    else
        return false;
#else
    if (FSerial)
        return FSerial->IsAutoRtsOn();
    else
        return false;
#endif
}

void TSerialDevice::SendBreak(char CharCount)
{
#ifdef __RDOS__
    if (FHandle && CharCount > 0)
        RdosSendComBreak(FHandle, CharCount);
#else
    if (FSerial)
        FSerial->SendBreak(CharCount);
#endif
}

void TSerialDevice::Write(char ch)
{
    TSerialDebug Debug;

#ifdef __RDOS__
    if (FHandle)
    {
        RdosWriteCom(FHandle, ch);

        if (FDebugFile && FOutChannel)
        {
            Debug.Time = RdosGetLongTime();
            Debug.Channel = FOutChannel;
            Debug.ch = ch;
            FDebugFile->Write(&Debug, sizeof(Debug));
        }

        if (FFileCount && FEntryCount && FOutChannel)
        {
            FEventSection.Enter();

            FEntryArr[FNextPos].Time = RdosGetLongTime();
            FEntryArr[FNextPos].Channel = FOutChannel;
            FEntryArr[FNextPos].ch = ch;

            FNextPos++;
            if (FNextPos >= FEntryCount)
                FNextPos = 0;

            FNewData = true;

            FEventSection.Leave();
        }        
    }
#else
    if (FSerial)
        FSerial->Write(ch);
#endif
}

void TSerialDevice::Write(const char *buf, int count)
{
#ifdef __RDOS__
    int i;

    for (i = 0; i < count; i++)
    {
        Write(*buf);
        buf++;
    }
#else
    if (FSerial)
        FSerial->Write(buf, count);
#endif
}

void TSerialDevice::Write(const char *str)
{
#ifdef __RDOS__
    while (*str != 0)
    {
        Write(*str);
        str++;
    }
#else
    if (FSerial)
        FSerial->Write(str);
#endif
}

void TSerialDevice::WaitForSendCompleted()
{
#ifdef __RDOS__
    if (FHandle)
        RdosWaitForSendCompletedCom(FHandle);
#else
    if (FSerial)
        FSerial->WaitForSendCompleted();
#endif
}

bool TSerialDevice::WaitForChar(long Timeout)
{
#ifdef __RDOS__
    TWaitDevice *wd;

    if (!FWait)
        CreateWait();

    if (FWait && FHandle)
    {
        wd = FWait->WaitTimeout(Timeout);
        if (wd == this)
            return true;
        else
            return Poll();
    }

    return false;
#else
    if (FSerial)
        return FSerial->WaitForChar(Timeout);
    else
        return false;
#endif
}

bool TSerialDevice::Poll()
{
#ifdef __RDOS__
    if (RdosGetComRecCount(FHandle))
        return true;
    else
        return false;
#else
    if (FSerial)
        return FSerial->Poll();
    else
        return false;
#endif
}

char TSerialDevice::Read()
{
#ifdef __RDOS__
    char ch = 0;
    TSerialDebug Debug;

    if (FHandle)
    {
        ch = RdosReadCom(FHandle);

        if (FDebugFile && FInChannel)
        {
            Debug.Time = RdosGetLongTime();
            Debug.Channel = FInChannel;
            Debug.ch = ch;
            FDebugFile->Write(&Debug, sizeof(Debug));
        }   

        if (FFileCount && FEntryCount && FInChannel)
        {
            FEventSection.Enter();

            FEntryArr[FNextPos].Time = RdosGetLongTime();
            FEntryArr[FNextPos].Channel = FInChannel;
            FEntryArr[FNextPos].ch = ch;

            FNextPos++;
            if (FNextPos >= FEntryCount)
                FNextPos = 0;

            FNewData = true;

            FEventSection.Leave();
        }
    }
    
    return ch;
#else
    if (FSerial)
        return FSerial->Read();
    else
        return 0;
#endif
}

void TSerialDevice::SignalNewData()
{
    if (OnChar)
        (*OnChar)(this, Read());
}
