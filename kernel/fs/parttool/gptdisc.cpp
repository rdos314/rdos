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
# gptdisc.cpp
# GPT disc class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <rdos.h>
#include <serv.h>
#include "gptdisc.h"

struct TBootParamBlock
{
    short int BytesPerSector;
    char Resv1;
    short int MappingSectors;
    char Resv3;
    short int Resv4;
    short int SmallSectors;
    char Media;
    short int Resv6;
    unsigned short int SectorsPerCyl;
    unsigned short int Heads;
    int HiddenSectors;
    int Sectors;
    char Drive;
    char Resv7;
    char Signature;
    int Serial;
    char Volume[11];
    char Fs[8];
};

/*##########################################################################
#
#   Name       : UuidToStr
#
#   Purpose....: Convert UUID to string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void UuidToStr(const char *uuid, char *str)
{
    int ival;
    int *ip;
    short int sval;
    short int *sp;

    ip = (int *)uuid;
    ival = *ip;
    sprintf(str, "%08lX-", ival);

    sp = (short int *)(uuid + 4); 
    sval = *sp;
    sprintf(str+9, "%04hX-", sval);
    
    sp = (short int *)(uuid + 6); 
    sval = *sp;
    sprintf(str+14, "%04hX-", sval);

    sp = (short int *)(uuid + 8); 
    sval = RdosSwapShort(*sp);
    sprintf(str+19, "%04hX-", sval);

    sp = (short int *)(uuid + 10); 
    sval = RdosSwapShort(*sp);
    sprintf(str+24, "%04hX", sval);

    sp = (short int *)(uuid + 12); 
    sval = RdosSwapShort(*sp);
    sprintf(str+28, "%04hX", sval);

    sp = (short int *)(uuid + 14); 
    sval = RdosSwapShort(*sp);
    sprintf(str+32, "%04hX", sval);
}

/*##########################################################################
#
#   Name       : TGptPartition::TGptPartition
#
#   Purpose....: Constructor for GPT partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGptPartition::TGptPartition(struct TGptPartEntry *entry, const char *guid)
  : TPartition(entry->FirstLba, entry->LastLba - entry->FirstLba + 1)
{
    memcpy(&Entry, entry, sizeof(struct TGptPartEntry));
    memcpy(Guid, guid, 40);
}

/*##########################################################################
#
#   Name       : TGptPartition::~TGptPartition
#
#   Purpose....: Destructor for GPT partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGptPartition::~TGptPartition()
{
}

/*##########################################################################
#
#   Name       : TGptTable::TGptTable
#
#   Purpose....: Constructor for GPT table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGptTable::TGptTable()
{
    int i;

    PartCount = 0;
    MaxPartCount = 4;
    PartArr = new TGptPartEntry*[MaxPartCount];

    HeaderOk = false;

    for (i = 0; i < MaxPartCount; i++)
        PartArr[i] = 0;
}

/*##########################################################################
#
#   Name       : TGptTable::~TGptTable
#
#   Purpose....: Destructor for GPT table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGptTable::~TGptTable()
{
    int i;

    for (i = 0; i < PartCount; i++)
        if (PartArr[i])
            delete PartArr[i];

    delete PartArr;
}

/*##########################################################################
#
#   Name       : TGptTable::GrowPart
#
#   Purpose....: Grow part array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGptTable::GrowPart()
{
    int i;
    int Size = 2 * MaxPartCount;
    TGptPartEntry **NewArr;

    NewArr = new TGptPartEntry*[Size];

    for (i = 0; i < MaxPartCount; i++)
        NewArr[i] = PartArr[i];

    for (i = MaxPartCount; i < Size; i++)
        NewArr[i] = 0;

    delete PartArr;
    PartArr = NewArr;
    MaxPartCount = Size;
}

/*##################  TGptTable::Add  #############
*   Purpose....: Add entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
bool TGptTable::Add(struct TGptPartEntry *entry)
{
    int pos;
    int i;
    struct TGptPartEntry *e;  

    if (entry->FirstLba == 0)
        return false;

    for (pos = 0; pos < PartCount; pos++)
        if (entry->FirstLba < PartArr[pos]->FirstLba)
            break;

    if (pos)
        if (entry->FirstLba <= PartArr[pos-1]->LastLba)
            return false;

    if (PartCount > pos)
        if (entry->LastLba >= PartArr[pos]->FirstLba)
            return false;

    if (PartCount == MaxPartCount)
        GrowPart();

    e = new TGptPartEntry;
    *e = *entry;

    for (i = PartCount - 1; i > pos; i--)
        PartArr[i] = PartArr[i - 1];

    PartArr[pos] = e;    

    PartCount++;

    return true;
}

/*##########################################################################
#
#   Name       : TGptTable::ReadEntryArr
#
#   Purpose....: Read entry array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGptTable::ReadEntryArr(TDisc *Disc)
{
    char *Buf;
    struct TGptPartEntry *PartEntryArr;
    int SectorCount = Header.EntryCount * sizeof(struct TGptPartEntry) / Disc->FBytesPerSector;
    TDiscServer *Server = Disc->GetServer();
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, Header.EntryLba, SectorCount);
    int size = SectorCount * Disc->FBytesPerSector;
    unsigned int ThisCrc32;
    int i;

    req.WaitForever();

    if (req.IsDone())
    {
        Buf = (char *)e1.Map();

        ThisCrc32 = RdosCalcCrc32(0xFFFFFFFF, Buf, size);

        if (ThisCrc32 == Header.EntryCrc32)
        {
            PartEntryArr = (struct TGptPartEntry *)Buf;

            for (i = 0; i < Header.EntryCount; i++)
                Add(PartEntryArr + i);
        }
    }
}

/*##########################################################################
#
#   Name       : TGptTable::ReadTable
#
#   Purpose....: Read table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGptTable::ReadTable(TDisc *Disc, long long StartSector)
{
    char *Buf;
    TDiscServer *Server = Disc->GetServer();
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, StartSector, 1);
    unsigned int Crc32;
    unsigned int ThisCrc32;

    HeaderOk = false;

    req.WaitForever();

    if (req.IsDone())
    {
        Buf = (char *)e1.Map();
        memcpy(&Header, Buf, sizeof(struct TGptPartHeader));

        if (!strcmp(Header.Sign, "EFI PART"))
        {
            Crc32 = Header.Crc32;
            Header.Crc32 = 0;
            ThisCrc32 = RdosCalcCrc32(0xFFFFFFFF, (const char *)&Header, Header.HeaderSize);
            Header.Crc32 = Crc32;

            if (Crc32 == ThisCrc32) 
            {           
                if (Header.EntrySize == sizeof(struct TGptPartEntry))
                {
                    HeaderOk = true;
                    ReadEntryArr(Disc);
                }
            }
        }
    }
}

/*##################  TGptTable::InitGpt  #############
*   Purpose....: Init GPT
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TGptTable::InitHeader(TDisc *disc, bool primary)
{
    Header.EntryCount = 128;

    strcpy(Header.Sign, "EFI PART");
    Header.Revision[0] = 0;
    Header.Revision[1] = 0;
    Header.Revision[2] = 1;
    Header.Revision[3] = 0;

    Header.HeaderSize = sizeof(struct TGptPartHeader);
    Header.Crc32 = 0;    
    Header.Resv = 0;

    if (primary)
    {
        Header.CurrLba = 1;
        Header.OtherLba = disc->GetSectorCount() - 1;
        Header.EntryLba = 2;
    }
    else
    {
        Header.CurrLba = disc->GetSectorCount() - 1;
        Header.OtherLba = 1;
        Header.EntryLba = disc->GetSectorCount() - 33;
    }

    Header.FirstLba = 34;
    Header.LastLba = disc->GetSectorCount() - 34;
    RdosCreateUuid(Header.Guid);

    Header.EntrySize = 128;
};

/*##########################################################################
#
#   Name       : TGptTable::WriteHeader
#
#   Purpose....: Write header
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGptTable::WriteHeader(TDisc *Disc)
{
    TDiscServer *Server = Disc->GetServer();
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, Header.CurrLba, 1, true);
    char *Buf;

    req.WaitForever();

    if (req.IsDone())
    {
        Buf = (char *)e1.Map();
        memset(Buf, 0, Disc->FBytesPerSector);

        Header.Crc32 = 0;
        Header.Crc32 = RdosCalcCrc32(0xFFFFFFFF, (const char *)&Header, Header.HeaderSize);

        memcpy(Buf, &Header, sizeof(TGptPartHeader));

        e1.Write();
    }
}

/*##########################################################################
#
#   Name       : TGptTable::Recreate
#
#   Purpose....: Recreate table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGptTable::Recreate(TDisc *Disc, TGptTable *Src)
{
    int Sectors = Header.EntrySize * Header.EntryCount / Disc->FBytesPerSector;
    TDiscServer *Server = Disc->GetServer();
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, Header.EntryLba, Sectors, true);
    char *Buf;
    struct TGptPartEntry *CurrEntry;
    int i;
    int size = Sectors * Disc->FBytesPerSector;

    req.WaitForever();

    if (req.IsDone())
    {
        Buf = (char *)e1.Map();
        memset(Buf, 0, size);

        CurrEntry = (struct TGptPartEntry *)Buf;

        for (i = 0; i < Src->PartCount; i++)
        {
            memcpy(CurrEntry, Src->PartArr[i], sizeof(struct TGptPartEntry));
            CurrEntry++;
        }

        Header.EntryCrc32 = RdosCalcCrc32(0xFFFFFFFF, Buf, size);

        e1.Write();

        WriteHeader(Disc);
    }
}

/*##########################################################################
#
#   Name       : TGptDisc::TGptDisc
#
#   Purpose....: Gpt disc constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGptDisc::TGptDisc(TDiscServer *server)
  : TDisc(server)
{
}

/*##########################################################################
#
#   Name       : TGptDisc::~TGptDisc
#
#   Purpose....: Gpt disc destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGptDisc::~TGptDisc()
{
}

/*##########################################################################
#
#   Name       : TGptDisc::IsGpt
#
#   Purpose....: Is GPT partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TGptDisc::IsGpt()
{
    return true;
}

/*##########################################################################
#
#   Name       : TGptDisc::AddPossibleFs
#
#   Purpose....: Add possible Fs
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGptDisc::AddPossibleFs(struct TGptPartEntry *entry)
{
    char GuidStr[40];
    int Type = 0;
    TGptPartition *part;

    UuidToStr(entry->PartGuid, GuidStr);

    if (!strcmp(GuidStr, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"))
    {
        strcpy(GuidStr, "Basic Data");
        Type = PART_TYPE_FAT;
    }

    if (!strcmp(GuidStr, "C12A7328-F81F-11D2-BA4B-00A0C93EC93B"))
    {
        strcpy(GuidStr, "EFI System");
        Type = PART_TYPE_EFI;
    }

    if (Type)
    {
        part = new TGptPartition(entry, GuidStr);
        part->SetType(Type);
        Add(part);        
    }
}

/*##########################################################################
#
#   Name       : TGptDisc::LoadPart
#
#   Purpose....: Load partitions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TGptDisc::LoadPart()
{
    int i;
    bool ok = true;

    PrimaryTable.ReadTable(this, 1);

    if (PrimaryTable.HeaderOk)
    {
        SecondaryTable.ReadTable(this, PrimaryTable.Header.OtherLba);

        if (!SecondaryTable.HeaderOk || (PrimaryTable.Header.EntryCrc32 != SecondaryTable.Header.EntryCrc32))
            SecondaryTable.Recreate(this, &PrimaryTable);
    }
    else
    {
        SecondaryTable.ReadTable(this, PrimaryTable.Header.OtherLba);

        if (SecondaryTable.HeaderOk)
            PrimaryTable.Recreate(this, &SecondaryTable);
        else
            ok = false;
    }

    if (ok)
    {
        for (i = 0; i < PrimaryTable.PartCount; i++)
            AddPossibleFs(PrimaryTable.PartArr[i]);

        return TDisc::LoadPart();
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TIGptDisc::WriteGptSector
#
#   Purpose....: Write GPT boot sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGptDisc::WriteGptBoot()
{
    TDiscReq req(FServer);
    TDiscReqEntry e1(&req, 0, 1, false);
    char *Data;
    char *BootSector;
    TBootParamBlock *bootp;
    long long Total;

    req.WaitForever();

    if (req.IsDone())
    {
        Data = (char *)e1.Map();

        BootSector = new char[512];
        RdosReadBinaryResource(0, 103, BootSector, 0x1BE);
        memcpy(BootSector + 11, Data + 11, sizeof(TBootParamBlock));
        memset(BootSector + 0x1BE, 0, 0x200 - 0x1BE);
    
        bootp = (TBootParamBlock *)(BootSector + 11);

        Total = GetSectorCount();
        if (Total > 0xFFFFFFFF)
            Total = 0xFFFFFFFF;

        bootp->BytesPerSector = FBytesPerSector;
        bootp->Resv1 = 0;
        bootp->MappingSectors = 0;
        bootp->Resv3 = 0;
        bootp->Resv4 = 0;
        bootp->SmallSectors = 0;
        bootp->Media = 0xF1;
        bootp->Resv6 = 0;
        bootp->HiddenSectors = 0;
        bootp->Sectors = (int)Total;
        bootp->Drive = 0x80;
        bootp->Resv7 = 0;
        bootp->Signature = 0;
        bootp->Serial = 0;
        memset(bootp->Volume, 0, 11);
        memcpy(bootp->Fs, "RDOS    ", 8);

        BootSector[0x1FE] = 0x55;
        BootSector[0x1FF] = 0xAA;

        BootSector[0x1BE + 4] = 0xEE;
        *(long *)(BootSector + 0x1BE + 8) = 1;
        if (Total > 0xFFFFFFFF)
            *(long *)(BootSector + 0x1BE + 0xC) = 0xFFFFFFFF;
        else
            *(long *)(BootSector + 0x1BE + 0xC) = (int)Total - 1;

        memcpy(Data, BootSector, 512);
        e1.Write();

        delete BootSector;
    }
}

/*##########################################################################
#
#   Name       : TGptDisc::InitPart
#
#   Purpose....: Init partitions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TGptDisc::InitPart()
{
    WriteGptBoot();            
    PrimaryTable.InitHeader(this, true);
    SecondaryTable.InitHeader(this, false);

    PrimaryTable.Recreate(this, &PrimaryTable);
    SecondaryTable.Recreate(this, &SecondaryTable);
    return true;
}

/*##########################################################################
#
#   Name       : TGptDisc::AddPart
#
#   Purpose....: Add partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TGptDisc::AddPart(const char *FsName, long long Sectors)
{
    long long Start;
    long long Count = Sectors;
    int Type;
    int Handle;

    Start = AllocateSectors(PrimaryTable.Header.FirstLba, Count);

    if (Start)
    {
        if (Start + Count > PrimaryTable.Header.LastLba)
            Count = PrimaryTable.Header.LastLba - Start + 1;

        Handle = FormatPart(FsName, &Start, &Count, &Type);

        if (Handle)
            if (CreatePart(Handle, Type, Start, Count))
                return true;
    }
    return false;
}

/*##################  TGptDisc::GetGuid  #############
*   Purpose....: Get GUID
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TGptDisc::GetGuid(const char *FsName)
{
    static char EfiGuid[] =  {0x28, 0x73, 0x2A, 0xC1, 0x1F, 0xF8, 0xD2, 0x11, 0xBA, 0x4B, 0x00, 0xA0, 0xC9, 0x3E, 0xC9, 0x3B};
    static char DataGuid[] = {0xA2, 0xA0, 0xD0, 0xEB, 0xE5, 0xB9, 0x33, 0x44, 0x87, 0xC0, 0x68, 0xB6, 0xB7, 0x26, 0x99, 0xC7};
    static char Ext4Guid[] = {0xAF, 0x3D, 0xC6, 0x0F, 0x83, 0x84, 0x72, 0x47, 0x8E, 0x79, 0x3D, 0x69, 0xD8, 0x47, 0x7D, 0xE4};    

    if (!strcmp(FsName, "EFI"))
        return EfiGuid;
    else if (!strcmp(FsName, "EXT4"))
        return Ext4Guid;
    else
        return DataGuid;
}

/*##########################################################################
#
#   Name       : TGptDisc::CreatePart
#
#   Purpose....: Create partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TGptDisc::CreatePart(int Handle, int Type, long long Start, long long Sectors)
{
    TGptPartEntry entry;
    TGptPartition *part;
    const char *Name = FsTypeToName(Type);
    const char *Guid = GetGuid(Name);

    if (Guid)
    {
        memcpy(entry.PartGuid, Guid, 16);
        RdosCreateUuid(entry.UniqueGuid);
        entry.FirstLba = Start;
        entry.LastLba = Start + Sectors - 1;
        entry.Attrib = 0;
        memset(entry.Name, 0, 2 * 36);

        PrimaryTable.Add(&entry);
        PrimaryTable.Recreate(this, &PrimaryTable);

        SecondaryTable.Add(&entry);
        SecondaryTable.Recreate(this, &SecondaryTable);

        part = new TGptPartition(&entry, Name);
        part->SetType(Type);
        Add(part);        
        return true;
    }
    else
        return false;
}
