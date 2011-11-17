/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
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
