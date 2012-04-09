/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2010, Leif Ekblad
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
# bindata.cpp
# Bin data conversion module
#
########################################################################*/

#define FALSE	0
#define TRUE	!FALSE

#include <stdio.h>
#include <mem.h>
#include <string.h>

#include "rdos.h"
#include "cotdata.h"
#include "bindata.h"

#define ROOT_DIR        "e:\\bin"

/*##########################################################################
#
#   Name       : TBinData::TBinData
#
#   Purpose....: TBinData constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBinData::TBinData()
{
    FFile = 0;
    Clear();
}

/*##########################################################################
#
#   Name       : TBinData::~TBinData
#
#   Purpose....: TBinData destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBinData::~TBinData()
{
    Clear();
}

/*##########################################################################
#
#   Name       : TBinData::InitRadEntry
#
#   Purpose....: Init rad data structure
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::InitRadEntry(TBinRadData *data)
{
    data->Ref.valid = FALSE;
	data->Temp.valid = FALSE;
	data->Motor.valid = FALSE;
	data->Light.valid = FALSE;
	data->AuxTemp.valid = FALSE;
}

/*##########################################################################
#
#   Name       : TBinData::InitEntry
#
#   Purpose....: Init binary data entry structure
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::InitEntry(TBinDataEntry *data)
{
	 int rad;

	 data->Temp.valid = FALSE;
	 data->Humidity.valid = FALSE;
	 data->WindSpeed.valid = FALSE;
	 data->WindGust.valid = FALSE;
	 data->WindDir.valid = FALSE;
	 data->AirPressure.valid = FALSE;
	 data->Rain.valid = FALSE;
	 data->CircSpeed.valid = FALSE;
	 data->TankTemp.valid = FALSE;
	 data->TankP.valid = FALSE;
	 data->HeatTemp.valid = FALSE;
	 data->HeatP.valid = FALSE;

	 for (rad = 0; rad < RAD_COUNT; rad++)
		  InitRadEntry(&data->Rad[rad]);
}

/*##########################################################################
#
#   Name       : TBinData::Clear
#
#   Purpose....: Clear data contents
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::Clear()
{
    int i;

    if (FFile)
    {
        delete FFile;
        FFile = 0;
    }

    FFirstEntry = 0;
    
    for (i = 0; i < 24 * 60; i++)
        InitEntry(&FData[i]);
}

/*##########################################################################
#
#   Name       : TBinData::DecodeOutdoor
#
#   Purpose....: Decode outdoor tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::DecodeOutdoor(TDeviceTag *tag, TBinDataEntry *data)
{
    TDeviceVar *var;
    long ival;
    long double val;
    
    var = tag->GetVar(LOG_VAR_Temp);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival < 500 && ival > -500)
		{
            val = (long double)ival;
	        data->Temp.val = val / 10.0;
	        data->Temp.valid = TRUE;
	    }
	}
    
    var = tag->GetVar(LOG_VAR_Humidity);
    if (var)
	{
        ival = var->GetSignedInt();

		if (ival <= 100 && ival >= 0)
		{
            val = (long double)ival;
	        data->Humidity.val = val;
	        data->Humidity.valid = TRUE;
	    }
	}

	 var = tag->GetVar(LOG_VAR_Windspeed);
	 if (var)
	{
		  ival = var->GetFloat1();

		if (ival < 400 && ival >= 0)
		{
				val = (long double)ival;
			  data->WindSpeed.val = val / 10.0;
			  data->WindSpeed.valid = TRUE;
		 }
	}

	 var = tag->GetVar(LOG_VAR_Windgust);
	 if (var)
	{
		  ival = var->GetFloat1();

		if (ival < 400 && ival >= 0)
		{
				val = (long double)ival;
			  data->WindGust.val = val / 10.0;
			  data->WindGust.valid = TRUE;
		 }
	}

	 var = tag->GetVar(LOG_VAR_Winddir);
	 if (var)
	{
        ival = var->GetSignedInt();

		if (ival <= 16 && ival >= 0)
		{
            val = (long double)ival;
			data->WindDir.val = val * 22.5;
	        data->WindDir.valid = TRUE;
	    }
	}
    
    var = tag->GetVar(LOG_VAR_Pressure);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival < 11000 && ival >= 9000)
		{
            val = (long double)ival;
	        data->AirPressure.val = val / 10.0;
	        data->AirPressure.valid = TRUE;
	    }
	}
    
    var = tag->GetVar(LOG_VAR_Rain);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival > 0)
		{
            val = (long double)ival;
	        data->Rain.val = val / 10.0;
	        data->Rain.valid = TRUE;
	    }
	}
}

/*##########################################################################
#
#   Name       : TBinData::DecodeCirc
#
#   Purpose....: Decode circ tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::DecodeCirc(TDeviceTag *tag, TBinDataEntry *data)
{
    TDeviceVar *var;
    long ival;
    long double val;
    
    var = tag->GetVar(LOG_VAR_Motor);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival <= 110 && ival >= 0)
		{
            val = (long double)ival;
	        data->CircSpeed.val = val / 10.0;
	        data->CircSpeed.valid = TRUE;
	    }
	}
}

/*##########################################################################
#
#   Name       : TBinData::DecodeTank
#
#   Purpose....: Decode tank tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::DecodeTank(TDeviceTag *tag, TBinDataEntry *data)
{
    TDeviceVar *var;
	 long ival;
    long double val;
    
    var = tag->GetVar(LOG_VAR_Temp);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival <= 1000 && ival >= 0)
		{
            val = (long double)ival;
	        data->TankTemp.val = val / 10.0;
	        data->TankTemp.valid = TRUE;
	    }
	}

    var = tag->GetVar(LOG_VAR_P);
    if (var)
	{
        ival = var->GetFloat2();

		if (ival <= 1000 && ival >= -1000)
		{
            val = (long double)ival;
	        data->TankP.val = val / 100.0;
	        data->TankP.valid = TRUE;
	    }
	}
}

/*##########################################################################
#
#   Name       : TBinData::DecodeHeat
#
#   Purpose....: Decode heat tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::DecodeHeat(TDeviceTag *tag, TBinDataEntry *data)
{
    TDeviceVar *var;
    long ival;
    long double val;
    
    var = tag->GetVar(LOG_VAR_Temp);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival <= 1000 && ival >= 0)
		{
            val = (long double)ival;
	        data->HeatTemp.val = val / 10.0;
	        data->HeatTemp.valid = TRUE;
	    }
	}

	 var = tag->GetVar(LOG_VAR_P);
    if (var)
	{
        ival = var->GetFloat2();

		if (ival <= 1000 && ival >= -1000)
		{
            val = (long double)ival;
	        data->HeatP.val = val / 100.0;
	        data->HeatP.valid = TRUE;
	    }
	}
}

/*##########################################################################
#
#   Name       : TBinData::DecodeRadData
#
#   Purpose....: Decode rad data tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::DecodeRadData(TDeviceTag *tag, TBinRadData *data)
{
    TDeviceVar *var;
    long ival;
    long double val;
    
    var = tag->GetVar(LOG_VAR_Ref);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival <= 1000 && ival >= 0)
		{
            val = (long double)ival;
	        data->Ref.val = val / 10.0;
	        data->Ref.valid = TRUE;
	    }
	}

    var = tag->GetVar(LOG_VAR_Temp);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival <= 1000 && ival >= 0)
		{
            val = (long double)ival;
	        data->Temp.val = val / 10.0;
			  data->Temp.valid = TRUE;
	    }
	}

    var = tag->GetVar(LOG_VAR_Motor);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival <= 110 && ival >= 0)
		{
            val = (long double)ival;
	        data->Motor.val = val / 10.0;
	        data->Motor.valid = TRUE;
	    }
	}

    var = tag->GetVar(LOG_VAR_Light);
    if (var)
	{
        ival = var->GetFloat1();

        val = (long double)ival;
	    data->Light.val = val / 10.0;
	    data->Light.valid = TRUE;
	}

    var = tag->GetVar(LOG_VAR_AuxTemp);
    if (var)
	{
		  ival = var->GetFloat1();

		if (ival <= 1000 && ival >= 0)
		{
            val = (long double)ival;
	        data->AuxTemp.val = val / 10.0;
	        data->AuxTemp.valid = TRUE;
	    }
	}
}

/*##########################################################################
#
#   Name       : TBinData::DecodeRad
#
#   Purpose....: Decode rad tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::DecodeRad(TDeviceTag *tag, TBinDataEntry *data)
{
    TDeviceVar *var;
    long ival;
    long double val;
    
    var = tag->GetVar(LOG_VAR_Address);
    if (var)
	{
        ival = var->GetSignedInt();

        if (ival >= 0x20)
        {
            ival -= 0x20;

            if (ival < RAD_COUNT)
                DecodeRadData(tag, &data->Rad[ival]);
        }
    }
}            

/*##########################################################################
#
#   Name       : TBinData::CotexToBinary
#
#   Purpose....: Convert cotex to binary data format
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::CotexToBinary(TDeviceMsg *doc, TBinDataEntry *data)
{
    TDeviceTag *tag;
    long ival;

	InitEntry(data);

	tag = doc->GotoFirstTag();
	while (tag)
    {
        switch (tag->GetID())
        {
            case LOG_TAG_OUTDOOR:
                DecodeOutdoor(tag, data);
                break;

            case LOG_TAG_CIRC:
                DecodeCirc(tag, data);
                break;
                
            case LOG_TAG_TANK:
                DecodeTank(tag, data);
                break;
                
            case LOG_TAG_HEAT:
                DecodeHeat(tag, data);
                break;

            case LOG_TAG_RAD:
                DecodeRad(tag, data);
                break;
        }

        tag = doc->GotoNextTag();
    }
}

/*##########################################################################
#
#   Name       : TBinData::GetNextCotex
#
#   Purpose....: Get next cotex from file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceMsg *TBinData::GetNextCotex(TFile *file)
{
    long pos;
    int sign;
    int size = 0;
    char *buf;
    TDeviceMsg *msg;

    pos = file->GetPos();

    for (;;)
    {
        file->Read(&sign, 4);

        while (sign != COT_SIGN)
        {
            pos++;
            file->SetPos(pos);
            if (file->Read(&sign, 4) != 4)
                return 0;
        }

        file->Read(&size, 2);
        if (size > 0 && size < 0x4000)
        {
            msg = new TDeviceMsg(MAX_MSG_SIZE);
            
			buf = new char[size + 8];
			file->Read(buf + 6, size + 2);
			memcpy(buf, &sign, 4);
			memcpy(buf + 4, &size, 2);

			if (msg->Parse(COT_SIGN, buf, size + 8))
			{
				delete buf;
				return msg;
		    }
            delete buf;
        }

        pos++;
        file->SetPos(pos);
    }
}

/*##########################################################################
#
#   Name       : TBinData::LoadCotex
#
#   Purpose....: Load cotex-data from file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::LoadCotex(int year, int month, int day)
{
    char FileName[128];
    TFile *file;
    TDeviceMsg *doc;
    unsigned long msb, lsb;
	TDeviceTag *header;
	int fyear, fmonth, fday, fhour;
	int fmin, fsec, fms, fus;
	int ind;

    Clear();
    
    sprintf(FileName, "e:\\data\\%d\\%d\\%d.cot", year, month, day);

    file = new TFile(FileName);

    if (file->IsOpen())
    {
        doc = GetNextCotex(file);

        while (doc)
        {
        	header = doc->GetTag(LOG_TAG_HEADER);
        	if (header)
	        {
                msb = header->GetUnsignedInt(LOG_VAR_MsbTime, 0);
		        lsb = header->GetUnsignedInt(LOG_VAR_LsbTime, 0);
		        lsb += 0x1555555;
		        RdosDecodeMsbTics(msb, &fyear, &fmonth, &fday, &fhour);
		        RdosDecodeLsbTics(lsb, &fmin, &fsec, &fms, &fus);

                if (fday != day)
                {
                    if (fhour > 12)
                    {
                        fhour = 23;
                        fmin = 59;
                    }
                    else
                    {
                        fhour = 0;
                        fmin = 0;
                    }
               }

                ind = 60 * fhour + fmin;

                CotexToBinary(doc, &FData[ind]);
            }
            delete doc;

            doc = GetNextCotex(file);
        }            
    }

    delete file;
    
}

/*##########################################################################
#
#   Name       : TBinData::Update
#
#   Purpose....: Update binary file with new data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::Update(TDeviceMsg *doc)
{
    unsigned long msb, lsb;
	TDeviceTag *header;
	int year, month, day, hour;
	int min, sec, ms, us;
	int ind;

    header = doc->GetTag(LOG_TAG_HEADER);
    if (header)
	{
        msb = header->GetUnsignedInt(LOG_VAR_MsbTime, 0);
		lsb = header->GetUnsignedInt(LOG_VAR_LsbTime, 0);
		lsb += 0x1555555;
		RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
		RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);

        ind = 60 * hour + min;
        CotexToBinary(doc, &FData[ind]);
            
	    if (FFile)
	    {
	        FFile->SetPos(sizeof(TBinHeader) + ind * sizeof(TBinDataEntry));
	        FFile->Write(&FData[ind], sizeof(TBinDataEntry));
        }            
    }
}

/*##########################################################################
#
#   Name       : TBinData::CreateRootDir
#
#   Purpose....: Create root directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::CreateRootDir()
{
    if (!RdosSetCurDir(ROOT_DIR))
        RdosMakeDir(ROOT_DIR);
}

/*##########################################################################
#
#   Name       : TBinData::CreateDayFile
#
#   Purpose....: Create/open a day-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::CreateDayFile(int year, int month, int day)
{
	char str[20];
	char filename[256];

	if (FFile)
	    delete FFile;

	CreateRootDir();

	sprintf(str, "%d", year);
	strcpy(filename, ROOT_DIR);
	strcat(filename, "\\");
	strcat(filename, str);

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	sprintf(str, "%d\\%d", year, month);
	strcpy(filename, ROOT_DIR);
	strcat(filename, "\\");
	strcat(filename, str);

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	sprintf(str, "%d\\%d\\%d.bin", year, month, day);
	strcpy(filename, ROOT_DIR);
	strcat(filename, "\\");
	strcat(filename, str);

    FFile = new TFile(filename, 0);
}

/*##########################################################################
#
#   Name       : TBinData::OpenDayFile
#
#   Purpose....: Open a day-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::OpenDayFile(int year, int month, int day)
{
	char str[20];
	char filename[256];

    if (FFile)
        delete FFile;

	sprintf(str, "%d\\%d\\%d.bin", year, month, day);
	strcpy(filename, ROOT_DIR);
	strcat(filename, "\\");
	strcat(filename, str);

    FFile = new TFile(filename);
}

/*##########################################################################
#
#   Name       : TBinData::SaveBin
#
#   Purpose....: Save binary file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::SaveBin(int year, int month, int day)
{
    TBinHeader header;

    header.Version = BIN_DATA_VER;

    CreateDayFile(year, month, day);

    FFile->Write(&header, sizeof(header));
    FFile->Write(&FData, sizeof(FData));
}

/*##########################################################################
#
#   Name       : TBinData::LoadBin
#
#   Purpose....: Load binary file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::LoadBin(int year, int month, int day)
{
	TBinHeader header;

	Clear();

	OpenDayFile(year, month, day);

	header.Version = 0;
	FFile->Read(&header, sizeof(header));

	if (header.Version != BIN_DATA_VER)
	{
	    Clear();
		LoadCotex(year, month, day);
		SaveBin(year, month, day);
	 }
	 else
		 FFile->Read(&FData, sizeof(FData));
}

/*##########################################################################
#
#   Name       : TBinData::LoadNewest
#
#   Purpose....: Load newest
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBinData::LoadNewest()
{
    TDateTime time;
    int year, month, day;

    time.AddDay(-1);
    year = time.GetYear();
    month = time.GetMonth();
    day = time.GetDay();

    LoadBin(year, month, day);    
}
