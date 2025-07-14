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
# Fat.cpp
# Fat FS
#
########################################################################*/

#include <rdos.h>
#include <serv.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>

#include "sig.h"
#include "parttype.h"
#include "fat12.h"
#include "fat16.h"
#include "fat32.h"

bool Started = false;
TFat *Fs = 0;
const char *FsName = 0;

/*##########################################################################
#
#   Name       : LogError
#
#   Purpose....: Log bad FAT contents
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void LogError(TPartServer *Server, TFat *Fat)
{
    long long TotalSectors;

    TotalSectors = Server->GetPartSectors();

    if (TotalSectors < Fat->PartSectors)
        printf("Partition size mismatch: Part: %lld, Boot: %lld\r\n", TotalSectors, Fat->PartSectors);

    if (Fat->FatSectors == 0)
        printf("No FAT sectors\r\n");

    if (Fat->FatCount != 2)
        printf("Must have 2 FAT tables\r\n");

    if (Fat->SectorsPerCluster <= 0)
        printf("Invalid sectors per cluster: %d\r\n", Fat->SectorsPerCluster);
}

/*#########################################################################
#
#   Name       : GetCluster
#
#   Purpose....: Get cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int GetCluster(struct TFatDirEntry *entry)
{
    unsigned int cluster;
    char *ptr = (char *)&cluster;

    memcpy(ptr, &entry->ClusterLow, 2);
    memcpy(ptr + 2, &entry->ClusterHi, 2);

    return cluster;
}

/*##########################################################################
#
#   Name       : DecodeTime
#
#   Purpose....: Decode date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long DecodeTime(short int Date, short int Time, unsigned char Ms)
{
    int sec = Time & 0x1F;
    int min = (Time >> 5) & 0x3F;
    int hour = (Time >> 11) & 0x1F;
    int day = Date & 0x1F;
    int month = (Date >> 5) & 0xF;
    int year = (Date >> 9) & 0x7F;
    int ms = 10 * (Ms % 100);
    unsigned long lsb, msb;
    long long res;

    year += 1980;
    sec = 2 * sec + Ms / 100;

    lsb = RdosCodeLsbTics(min, sec, ms, 0);
    msb = RdosCodeMsbTics(year, month, day, hour);

    res = lsb + ((long long)msb << 32);
    return res;
}

/*##########################################################################
#
#   Name       : EncodeTime
#
#   Purpose....: Encode date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void EncodeTime(long long RdosTime, short int *Date, short int *Time, unsigned char *Ms)
{
    int us;
    int ms;
    int sec;
    int min;
    int hour;
    int day;
    int month;
    int year;
    unsigned long lsb, msb;

    lsb = (unsigned long)RdosTime;
    msb = (unsigned long)(RdosTime >> 32);

    RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
    RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);

    year -= 1980;

    *Time = sec / 2;
    *Time += min << 5;
    *Time += hour << 11;

    *Date = day;
    *Date += month << 5;
    *Date += year << 9;

    *Ms = ms / 10 + 100 * (sec % 2);
}

/*##########################################################################
#
#   Name       : DecodeAttrib
#
#   Purpose....: Decode attrib
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int DecodeAttrib(char attrib)
{
    return attrib;
}

/*##########################################################################
#
#   Name       : EncodeAttrib
#
#   Purpose....: Encode attrib
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char EncodeAttrib(int attrib)
{
    return (char)attrib;
}

/*##########################################################################
#
#   Name       : GetEntryName
#
#   Purpose....: Get entry name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetEntryName(struct TFatDirEntry *entry, char *name)
{
    char *src;
    char *dst;
    char ch;
    int i;

    src = entry->Base;
    dst = name;

    for (i = 0; i < 8; i++)
    {
        if (*src == ' ')
            break;
        else
        {
            ch = tolower(*src);
            *dst = ch;
            src++;
            dst++;
        }
    }

    src = entry->Ext;
    if (*src != ' ')
    {
        *dst = '.';
        dst++;

        for (i = 0; i < 3; i++)
        {
            if (*src == ' ')
                break;
            else
            {
                ch = tolower(*src);
                *dst = ch;
                src++;
                dst++;
            }
        }
    }

    *dst = 0;
}

/*##########################################################################
#
#   Name       : SetEntryName
#
#   Purpose....: Set entry name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetEntryName(struct TFatDirEntry *entry, const char *name)
{
    const char *src;
    char *dst;
    char ch;
    int i;

    src = name;
    dst = entry->Base;

    for (i = 0; i < 8; i++)
    {
        if (*src == '.' || *src == 0)
            ch = ' ';
        else
        {
            ch = toupper(*src);
            src++;
        }

        *dst = ch;
        dst++;
    }

    dst = entry->Ext;

    if (*src == '.')
        src++;

    for (i = 0; i < 3; i++)
    {
        if (*src == 0)
            ch = ' ';
        else
        {
            ch = toupper(*src);
            src++;
        }

        *dst = ch;
        dst++;
    }
}

/*##########################################################################
#
#   Name       : SetCreateTime
#
#   Purpose....: Set entry create name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool SetCreateTime(struct TFatDirEntry *entry, long long td)
{
    short int date = entry->CrDate;
    short int time = entry->CrTime;
    unsigned char ms = entry->CrMs;

    EncodeTime(td, &entry->CrDate, &entry->CrTime, &entry->CrMs);

    if (date != entry->CrDate)
        return true;

    if (time != entry->CrTime)
        return true;

    return false;
}

/*##########################################################################
#
#   Name       : SetAccessTime
#
#   Purpose....: Set entry access name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool SetAccessTime(struct TFatDirEntry *entry, long long td)
{
    short int date = entry->AcDate;
    short int time;
    unsigned char ms;

    EncodeTime(td, &entry->AcDate, &time, &ms);

    if (date != entry->AcDate)
        return true;
    else
        return false;
}

/*##########################################################################
#
#   Name       : SetWriteTime
#
#   Purpose....: Set entry write name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool SetWriteTime(struct TFatDirEntry *entry, long long td)
{
    short int date = entry->WrDate;
    short int time = entry->WrTime;
    unsigned char ms;

    EncodeTime(td, &entry->WrDate, &entry->WrTime, &ms);

    if (date != entry->WrDate)
        return true;

    if (time != entry->WrTime)
        return true;

    return false;
}

/*##########################################################################
#
#   Name       : GetChkSum
#
#   Purpose....: Get checksum
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char GetChkSum(struct TFatDirEntry *entry)
{
    char sum = 0;
    int i;
    char *ptr = entry->Base;

    for (i = 0; i < 11; i++)
        sum = ((sum & 1) ? 0x80 : 0) + (sum >> 1) + ptr[i];

    return sum;
}

/*##########################################################################
#
#   Name       : IsValidShortChar
#
#   Purpose....: Check for valid short char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool IsValidShortChar(char ch)
{
    switch (ch)
    {
        case 'a':
        case 'b':
        case 'c':
        case 'd':
        case 'e':
        case 'f':
        case 'g':
        case 'h':
        case 'i':
        case 'j':
        case 'k':
        case 'l':
        case 'm':
        case 'n':
        case 'o':
        case 'p':
        case 'q':
        case 'r':
        case 's':
        case 't':
        case 'u':
        case 'v':
        case 'w':
        case 'x':
        case 'y':
        case 'z':
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '$':
        case '%':
        case 0x27:
        case '-':
        case '_':
        case '@':
        case '~':
        case '!':
        case '(':
        case ')':
        case '{':
        case '}':
        case '^':
        case '#':
        case '&':
            return true;

        default:
            return false;
    }
}

/*##########################################################################
#
#   Name       : IsValidShortName
#
#   Purpose....: Check for valid short name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool IsValidShortName(const char *buf)
{
    int i;
    const char *ptr = buf;

    for (i = 0; i < 8; i++)
    {
        if (*ptr == 0)
            return true;

        if (*ptr == '.')
            break;

        if (!IsValidShortChar(*ptr))
            return false;

        ptr++;
    }

    if (*ptr == '.')
    {
        ptr++;

        for (i = 0; i < 3; i++)
        {
            if (*ptr == 0)
                return true;

            if (!IsValidShortChar(*ptr))
                return false;

            ptr++;
        }

        if (*ptr == 0)
            return true;
    }
    else
    {
        if (*ptr == 0)
            return true;
    }

    return false;
}

/*##########################################################################
#
#   Name       : GenerateShortName
#
#   Purpose....: GenerateShortName
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GenerateShortName(const char *name, int index, char *buf)
{
    int len;
    int i;
    char ch;
    char formstr[10];
    char outstr[10];
    const char *inptr = name;
    char *outptr = outstr;
    const char *ptr;

    if (index < 10)
        len = 6;
    else if (index < 100)
        len = 5;
    else if (index < 1000)
        len = 4;
    else if (index < 10000)
        len = 3;
    else
        len = 2;

    i = 0;

    while (i < len)
    {
        if (*inptr == 0 || *inptr == '.')
            break;

        ch = tolower(*inptr);
        if (IsValidShortChar(ch))
        {
            *outptr = ch;
            outptr++;
            i++;
        }
        inptr++;
    }
    *outptr = 0;

    len = i;

    sprintf(formstr, "%%s~%%0%dd", 7 - len);
    sprintf(buf, formstr, outstr, index);

    ptr = strchr(inptr, '.');

    if (ptr)
    {
        do
        {
            inptr = ptr + 1;
            ptr = strchr(inptr, '.');
        }
        while (ptr);

        len = strlen(buf);
        outptr = buf + len;

        *outptr = '.';
        outptr++;

        i = 0;

        while (i < 3)
        {
            if (*inptr == 0)
                break;

            ch = tolower(*inptr);
            if (IsValidShortChar(ch))
            {
                *outptr = ch;
                outptr++;
                i++;
            }
            inptr++;
        }

        outptr--;
        if (*outptr != '.')
            outptr++;

        *outptr = 0;
    }
}

/*##########################################################################
#
#   Name       : StartFs
#
#   Purpose....: Start filesystem
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void StartFs(TPartServer *Server)
{
    char Name[6];
    struct TBaseBootSector *boot;
    struct TBootSector12_16 *boot12_16 = 0;
    struct TBootSector32 *boot32 = 0;
    TPartReq req(Server);
    TPartReqEntry e1(&req, 0, 1);
    int FatSize;

    Fs = 0;
    Started = true;

    req.WaitForever();

    boot = (struct TBaseBootSector *)e1.Map();

    if (!boot)
    {
        printf("Cannot read boot sector\r\n");
        return;
    }

    if (boot->BytesPerSector != 512)
    {
        printf("Unexpected bytes per sector: %d\r\n", boot->BytesPerSector);
        return;
    }

    if (boot->RootDirEntries)
    {
        boot12_16 = (struct TBootSector12_16 *)e1.Map();
        memcpy(Name, boot12_16->ext.FsName, 5);
        Name[5] = 0;
    }
    else
    {
        boot32 = (struct TBootSector32 *)e1.Map();
        memcpy(Name, boot32->ext.FsName, 5);
        Name[5] = 0;
    }

    FatSize = 0;

    if (boot32)
        FatSize = 32;
    else
    {
        if (!strcmp(Name, "FAT12"))
            FatSize = 12;

        if (!strcmp(Name, "FAT16"))
            FatSize = 16;

        if (!FatSize)
        {
            memcpy(Name, FsName, 5);
            Name[5] = 0;

            if (!strcmp(Name, "FAT12"))
                FatSize = 12;

            if (!strcmp(Name, "FAT16"))
                FatSize = 16;
        }
    }

    switch (FatSize)
    {
        case 12:
            Fs = new TFat12(Server, boot12_16, false);
            break;

        case 16:
            Fs = new TFat16(Server, boot12_16, false);
            break;

        case 32:
            Fs = new TFat32(Server, boot32, false);
            break;

        default:
            printf("No FAT size specified\r\n");
            break;
    }

    if (Fs)
    {
        if (!Fs->Validate())
        {
            LogError(Server, Fs);
            delete Fs;
            Fs = 0;
        }
    }
}

/*##########################################################################
#
#   Name       : FormatFs
#
#   Purpose....: Format filesystem
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int FormatFs(TPartServer *Server)
{
    int PartType = Server->GetPartType();
    char *BootSector;
    struct TBaseBootSector *boot;
    struct TBootSector12_16 *boot12_16 = 0;
    struct TBootSector32 *boot32 = 0;
    bool ok;

    Fs = 0;
    Started = true;

    BootSector = new char[512];

    memset(BootSector, 0, 0x1FE);
    *(BootSector + 0x1FE) = 0x55;
    *(BootSector + 0x1FF) = 0xAA;

    RdosReadBinaryResource(0, 100, BootSector, 0x1BE);

    boot = (struct TBaseBootSector *)BootSector;

    switch (PartType)
    {
        case PART_TYPE_FAT12:
            boot12_16 = (struct TBootSector12_16 *)BootSector;
            ok = TFat12::InitFs(Server, boot12_16);
            break;

        case PART_TYPE_FAT16:
            boot12_16 = (struct TBootSector12_16 *)BootSector;
            ok = TFat16::InitFs(Server, boot12_16);
            break;

        case PART_TYPE_FAT32:
        case PART_TYPE_EFI:
            boot32 = (struct TBootSector32 *)BootSector;
            ok = TFat32::InitFs(Server, boot32);
            break;

        case PART_TYPE_FAT:
            boot32 = (struct TBootSector32 *)BootSector;
            ok = TFat32::InitFs(Server, boot32);
            if (ok)
                PartType = PART_TYPE_FAT32;
            else
            {
                boot12_16 = (struct TBootSector12_16 *)BootSector;
                ok = TFat16::InitFs(Server, boot12_16);
                if (ok)
                    PartType = PART_TYPE_FAT16;
            }
            break;

        default:
            ok = false;
            break;
    }

    if (ok)
    {
        switch (PartType)
        {
            case PART_TYPE_FAT12:
                Fs = new TFat12(Server, boot12_16, true);
                break;

            case PART_TYPE_FAT16:
                Fs = new TFat16(Server, boot12_16, true);
                break;

            case PART_TYPE_FAT32:
            case PART_TYPE_EFI:
                Fs = new TFat32(Server, boot32, true);
                break;
        }
    }

    if (Fs && ok)
    {
        if (!Fs->Validate())
        {
            LogError(Server, Fs);
            delete Fs;
            Fs = 0;
            ok = false;
        }
    }

    delete BootSector;

    return ok;
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main(int argc, char **argv)
{
    int dev;
    int unit;
    char *ptr;
    TPartServer *Server;

    if (argc >= 4)
    {
        ptr = argv[1];
        dev = atoi(ptr);

        ptr = argv[2];
        unit = atoi(ptr);

        FsName = argv[3];

        Server = new TPartServer;
        Server->OnStart = StartFs;
        Server->OnFormat = FormatFs;

        while (!Started)
            if (!Server->WaitForMsg())
                break;

        if (Fs)
            Fs->Run();

        Server->Disable();

        if (Fs)
            delete Fs;

        delete Server;
    }
}
