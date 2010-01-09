/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2006, Leif Ekblad
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
# wwwdata.h
# Data-type for binary data store
#
########################################################################*/

#ifndef WWWDATA_H
#define WWWDATA_H

#define RAD_COUNT       10
#define WWW_DATA_VER    1

struct TBoolData
{
    char val;
    char valid;
};

struct TFloatData
{
    long double val;
    char valid;
};

struct TWwwRadData
{
    TFloatData Ref;
    TFloatData Temp;
    TFloatData Motor;
    TFloatData Light;
    TFloatData AuxTemp;
};

struct TWwwDataEntry
{
    TFloatData Temp;
    TFloatData Humidity;
    TFloatData WindSpeed;
    TFloatData WindDir;
    TFloatData AirPressure;

    TFloatData CircSpeed;
    TFloatData TankTemp;
    TFloatData TankP;
    TFloatData HeatTemp;
    TFloatData HeatP;

    TBoolData Vp;
    TBoolData Ep;

	TWwwRadData Rad[RAD_COUNT];
};

struct TWwwHeader
{
	char Version;
	long FirstEntry;
	long LastEntry;
};

struct TWwwData
{
	TWwwHeader header;
    TWwwDataEntry data[24 * 60];
};    

#endif
