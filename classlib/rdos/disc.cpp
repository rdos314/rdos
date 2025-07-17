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
# disc.cpp
# Direct disc access class
#
########################################################################*/

#include "rdos.h"
#include "disc.h"

#define FALSE   0
#define TRUE    !FALSE

/*##################  TDisc::TDisc  #############
*   Purpose....: Disc constructor                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDisc::TDisc()
{
    FValid = FALSE;
}

/*##################  TDisc::TDisc  #############
*   Purpose....: Disc constructor                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDisc::TDisc(int Disc)
{
    Define(Disc);
}

/*##################  TDisc::Define  #############
*   Purpose....: Define disc                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDisc::Define(int Disc)
{
    FDisc = Disc;
    FValid = RdosGetDiscInfo(Disc, &FBytesPerSector, &FSectors, &FSectorsPerCyl, &FHeads);

    if (FValid && FBytesPerSector == 0)
        FValid = FALSE;

    if (!FValid)
    {
        FBytesPerSector = 0;
        FSectors = 0;
        FSectorsPerCyl = 0;
        FHeads = 0;
    }
}

/*##################  TDisc::~TDisc  #############
*   Purpose....: Disc destructor                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDisc::~TDisc()
{
}

/*##################  TDisc::IsValid  #############
*   Purpose....: Is disc valid?                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::IsValid()
{
    return FValid;
}

/*##################  TDisc::IsGpt  #############
*   Purpose....: Is GPT partitioned disc?                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::IsGpt()
{
    char *Buf;
    unsigned char Type;

    if (FValid)
    {
        Buf = new char[512];
        Read(0, Buf, 512);
        Type = Buf[0x1BE + 4];
        delete Buf;

        if (Type == 0xEE)
            return TRUE;
    }
    return FALSE;
}

/*##################  TDisc::GetDiscNr  #############
*   Purpose....: Get disc #                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::GetDiscNr()
{
    if (FValid)
        return FDisc;
    else
        return 0;
}

/*##################  TDisc::GetBytesPerSector  #############
*   Purpose....: Get bytes per sector                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::GetBytesPerSector()
{
    return FBytesPerSector;
}

/*##################  TDisc::GetTotalSectors  #############
*   Purpose....: Get total sectors on disc                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long long TDisc::GetTotalSectors()
{
    return FSectors;
}

/*##################  TDisc::GetSectorsPerCyl  #############
*   Purpose....: Get sectors per cylinder                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::GetSectorsPerCyl()
{
    return FSectorsPerCyl;
}

/*##################  TDisc::GetHeads  #############
*   Purpose....: Get heads                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::GetHeads()
{
    return FHeads;
}

/*##################  TDisc::GetCached  #############
*   Purpose....: Get current cache size                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long long TDisc::GetCached()
{
    return RdosGetDiscCache(FDisc);
}

/*##################  TDisc::GetLocked  #############
*   Purpose....: Get current locked size                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long long TDisc::GetLocked()
{
    return RdosGetDiscLocked(FDisc);
}

/*##################  TDisc::WaitForIdle  #############
*   Purpose....: Wait for disc idle
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDisc::WaitForIdle()
{
    while (!RdosIsDiscIdle(FDisc))
        RdosWaitMilli(250);
}

/*##################  TDisc::Reset  #############
*   Purpose....: Reset disc
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDisc::Reset()
{
    RdosResetDisc(FDisc);
}

/*##################  TDisc::Read  #############
*   Purpose....: Read a sector
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::Read(long long Sector, char *buf, int size)
{
    return RdosReadDisc(FDisc, Sector, buf, size);
}

/*##################  TDisc::Write  #############
*   Purpose....: Write a sector
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::Write(long long Sector, const char *buf, int size)
{
    return RdosWriteDisc(FDisc, Sector, buf, size);
}

/*##################  TDisc::GetDrive  #############
*   Purpose....: Get drive from physical sectors                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::GetDrive(long long Start, long long Size)
{
    int DriveNr;
    int DiscNr;
    long long StartSector;
    long ShortStartSector;
    long DriveSize;

    for (DriveNr = 0; DriveNr < 25; DriveNr++)
    {
        DiscNr = RdosGetVfsDriveDisc(DriveNr);
        if (DiscNr == FDisc)
        {
            StartSector = RdosGetVfsDriveStart(DriveNr);
            if (Start == StartSector)
                return DriveNr;
        }
        else
        {
            if (RdosGetDriveDiscParam(DriveNr, &DiscNr, &ShortStartSector, &DriveSize))    
                if (DiscNr == FDisc)
                    if (Start == ShortStartSector)
                        return DriveNr;
        }
    }

    return 0;
}

/*##################  TDisc::ChsToLba  #############
*   Purpose....: Convert CHS to LBA                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long TDisc::ChsToLba(const char *Data)
{
    int chs[3];
    int BiosHead;
    int BiosSector;
    int BiosCyl;

    chs[0] = *(unsigned char *)Data;
    chs[1] = *(unsigned char *)(Data + 1);
    chs[2] = *(unsigned char *)(Data + 2);

    BiosCyl = chs[2];
    BiosCyl += (chs[1] & 0xC0) << 2;
    BiosSector = chs[1] & 0x3F;
    BiosHead = chs[0];

    if (BiosCyl == 1023)
        return 0;

    if (BiosSector == 0)
        return 0;

    return BiosSector + FSectorsPerCyl * (BiosHead + FHeads * BiosCyl) - 1;
}

/*##################  TDisc::LbaToChs  #############
*   Purpose....: Convert LBA to CHS                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDisc::LbaToChs(long Sector, char *Data)
{
    int BiosHead;
    int BiosSector;
    int BiosCyl;

    BiosCyl = Sector / FSectorsPerCyl / FHeads;
    if (BiosCyl >= 1024)
    {
        BiosCyl = 1023;
        BiosHead = FHeads - 1;
        BiosSector = FSectorsPerCyl;
    }
    else
    {
        Sector = Sector - BiosCyl * FSectorsPerCyl * FHeads;
        BiosHead = Sector / FSectorsPerCyl;
        BiosSector = Sector - BiosHead * FSectorsPerCyl + 1;
    }

    *Data = (char)BiosHead;
    *(Data + 1) = (char)BiosSector;
    *(Data + 2) = (char)BiosCyl;
    *(Data + 1) |= (char)((BiosCyl >> 2) & 0xC0);
}
