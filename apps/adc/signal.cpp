/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2020, Leif Ekblad
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
# signal.cpp
# Signal analysator
#
########################################################################*/

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "rdos.h"

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
    int ok;

    ok = RdosSetupAdcChannel(0, 92000000, 50);
    ok = RdosSetupAdcChannel(1, 92100000, 50);
    ok = RdosSetupAdcChannel(2, 92200000, 50);
    ok = RdosSetupAdcChannel(3, 92300000, 50);
    ok = RdosSetupAdcChannel(4, 92400000, 50);
    ok = RdosSetupAdcChannel(5, 92500000, 50);
    ok = RdosSetupAdcChannel(6, 92600000, 50);
    ok = RdosSetupAdcChannel(7, 92700000, 50);
    ok = RdosSetupAdcChannel(8, 92800000, 50);
    ok = RdosSetupAdcChannel(9, 92900000, 50);
    ok = RdosSetupAdcChannel(10, 93000000, 50);


    RdosClearAdcChannel(0);
}
