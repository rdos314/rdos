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
# fddisc.cpp
# Direct floppy disc access class
#
########################################################################*/

#include "rdos.h"
#include "fddisc.h"

/*##################  TFloppyDisc::TFloppyDisc  #############
*   Purpose....: Floppy disc constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFloppyDisc::TFloppyDisc(int Unit)
{
    int Disc = RdosGetFloppyDisc(Unit);

    if (Disc >= 0)
        Define(Disc);
}

/*##################  TFloppyDisc::TFloppyDisc  #############
*   Purpose....: Floppy disc constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFloppyDisc::TFloppyDisc(int Unit, int SectorSize, long Sectors, int SectorsPerCyl, int Heads)
{
    int Disc = RdosGetFloppyDisc(Unit);

    if (Disc >= 0)
    {
        RdosSetDiscInfo(Disc, SectorSize, Sectors, SectorsPerCyl, Heads);
        Define(Disc);
    }
}

/*##################  TFloppyDisc::Format  #############
*   Purpose....: Format disc							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TFloppyDisc::Format(long Sectors)
{
    RdosFormatDrive(FDisc, 0, Sectors, "FAT12");
}
