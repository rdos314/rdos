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
# bindata.h
# Data-type for binary data store
#
########################################################################*/

#ifndef BINDATA_H
#define BINDATA_H

#include "file.h"
#include "device.h"

#define RAD_COUNT       10
#define BIN_DATA_VER    1

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

struct TBinRadData
{
    TFloatData Ref;
    TFloatData Temp;
    TFloatData Motor;
    TFloatData Light;
    TFloatData AuxTemp;
};

struct TBinDataEntry
{
    TFloatData Temp;
    TFloatData Humidity;
    TFloatData WindSpeed;
    TFloatData WindGust;
    TFloatData WindDir;
    TFloatData AirPressure;
    TFloatData Rain;

    TFloatData CircSpeed;
    TFloatData TankTemp;
    TFloatData TankP;
    TFloatData HeatTemp;
    TFloatData HeatP;

	TBinRadData Rad[RAD_COUNT];
};

struct TBinHeader
{
	char Version;
};

class TBinData
{
public:
    TBinData();
    ~TBinData();

    void Clear();
    void LoadCotex(int year, int month, int day);
    void SaveBin(int year, int month, int day);
    void Update(TDeviceMsg *doc);

    void LoadBin(int year, int month, int day);
    void LoadNewest();

    TDateTime GetTimeBase();
    TBinRadData *GetData(TDateTime &time);

    void AddData(TDeviceMsg *doc);

protected:
    void InitRadEntry(TBinRadData *data);
    void InitEntry(TBinDataEntry *data);

    void DecodeOutdoor(TDeviceTag *tag, TBinDataEntry *data);
    void DecodeCirc(TDeviceTag *tag, TBinDataEntry *data);
    void DecodeTank(TDeviceTag *tag, TBinDataEntry *data);
    void DecodeHeat(TDeviceTag *tag, TBinDataEntry *data);
    void DecodeRadData(TDeviceTag *tag, TBinRadData *data);
    void DecodeRad(TDeviceTag *tag, TBinDataEntry *data);
    void CotexToBinary(TDeviceMsg *doc, TBinDataEntry *data);

    TDeviceMsg *GetNextCotex(TFile *file);

    void CreateRootDir();
	void CreateDayFile(int year, int month, int day);
    void OpenDayFile(int year, int month, int day);
    
    int FFirstEntry;   
    TDateTime FTimeBase; 
    TBinDataEntry FData[24 * 60];

    TFile *FFile;
};    

#endif
