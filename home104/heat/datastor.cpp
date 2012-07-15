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
# datastor.cpp
# Permanent data storage class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "discstor.h"
#include "redustor.h"
#include "datastor.h"
#include "section.h"
#include "storserv.h"

#define STACK_SIZE      0x2000

#define LIST_ID         0x2AE0
#define LIST_SECTORS    1440

#define FALSE               0
#define TRUE                !FALSE

/*##########################################################################
#
#   Name       : TDataStore::TDataStore
#
#   Purpose....: Data store constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDataStore::TDataStore()
{
    int i;
    
        FStorList = 0;
    FCirc = 0;
    FVp = 0;

    for (i = 0; i < RAD_COUNT; i++)
        FRadArr[i] = 0;
        
    Start("Data Store", STACK_SIZE);
}

/*##########################################################################
#
#   Name       : TDataStore::TDataStore
#
#   Purpose....: Data store destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDataStore::~TDataStore()
{
}

/*##########################################################################
#
#   Name       : TDataStore::Add
#
#   Purpose....: Add radiator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDataStore::Add(TRad *Rad)
{
    int i;

    i = Rad->GetAddress();
    if (i >= 0x20)
    {
        i -= 0x20;
        if (i < RAD_COUNT)
            FRadArr[i] = Rad;
    }
}

/*##########################################################################
#
#   Name       : TDataStore::Add
#
#   Purpose....: Add circulation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDataStore::Add(TCirc *circ)
{
    FCirc = circ;
}

/*##########################################################################
#
#   Name       : TDataStore::Add
#
#   Purpose....: Add VP
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDataStore::Add(TVp *vp)
{
    FVp = vp;
}

/*##########################################################################
#
#   Name       : TDataStore::Add
#
#   Purpose....: Add climate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDataStore::Add(TClimate *climate)
{
    FClimate = climate;
}

/*##########################################################################
#
#   Name       : TDataStore::Add
#
#   Purpose....: Add power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDataStore::Add(TPower *power)
{
    FPower = power;
}

/*##########################################################################
#
#   Name       : TDataStore::GetCurrRad
#
#   Purpose....: Get current rad data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDataStore::GetCurrRad(TRad *rad, TRadData *data)
{
    if (rad->IsOnline())
        {
            data->HasData = TRUE;
            data->Address = rad->GetAddress();
            data->Ref = (long double)rad->GetRef() / 10.0;
            data->Temp = (long double)rad->GetTemp() / 10.0;
            data->Motor = (long double)rad->GetMotor() / 10.0;
            data->Light = (long double)rad->GetLight() / 10.0;
            data->AuxTemp = (long double)rad->GetAuxTemp() / 10.0;
        }
}

/*##########################################################################
#
#   Name       : TDataStore::GetCurrData
#
#   Purpose....: Get current data record
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDataStore::GetCurrData(THeatData *data)
{
        int i;

        data->Msb = RdosCodeMsbTics(FYear, FMonth, FDay, FHour);
        data->Lsb = RdosCodeLsbTics(FMin, 0, 0, 0);

        data->HasWs = FALSE;
        data->HasVp = FALSE;
        data->HasCirc = FALSE;
        data->HasSolar = FALSE;
        data->HasTankTemp = FALSE;
        data->HasTankP = FALSE;
        data->HasHeatTemp = FALSE;
        data->HasHeatP = FALSE;

        if (FCirc)
        {
                 data->HasCirc = TRUE;
                 data->CircSpeed = FCirc->GetSpeed();
        }

         if (FVp)
         {
                  if (FVp->HasValidTankTemp())
                  {
                                data->HasTankTemp = TRUE;
                                data->TankTemp = (long double)FVp->GetTankTemp() / 10.0;

                                if (FVp->HasValidTankP())
                                {
                                         data->HasTankP = TRUE;
                                         data->TankP = (long double)FVp->GetTankP() / 100.0;
                                }
                  }

                  if (FVp->HasValidHeatTemp())
                  {
                                data->HasHeatTemp = TRUE;
                                data->HeatTemp = (long double)FVp->GetHeatTemp() / 10.0;

                                if (FVp->HasValidHeatP())
                                {
                                         data->HasHeatP = TRUE;
                                         data->HeatP = (long double)FVp->GetHeatP() / 100.0;
                                }
                  }
         }

         if (FClimate)
         {
            if (FClimate->IsWindAverageValid())
            {
                data->HasWs = TRUE;
                data->IndoorTemp = FClimate->GetIndoorTemperature();
                data->IndoorHumidity = FClimate->GetIndoorHumidity();
                data->OutdoorTemp = FClimate->GetOutdoorTemperature();
                data->OutdoorHumidity = FClimate->GetOutdoorHumidity();
                data->WindAverage = FClimate->GetWindAverage();
                data->WindGust = FClimate->GetWindGust();
                data->WindDir = FClimate->GetWindDir();
                data->AirPressure = FClimate->GetPressure();
                data->Rain = FClimate->GetRain();
            }
         }

         if (FPower)
         {
            if (FPower->HasPower())
            {
                data->HasSolar = TRUE;
                data->Solar12P = FPower->GetSolar12Power();
                data->Solar24P = FPower->GetSolar24Power();
            }
         }

         for (i = 0; i < RAD_COUNT; i++)
         {
                  data->Rad[i].HasData = FALSE;

                  if (FRadArr[i])
                                GetCurrRad(FRadArr[i], &data->Rad[i]);
         }
}

/*##########################################################################
#
#   Name       : TDataStore::SendRealtime
#
#   Purpose....: Send realtime data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDataStore::SendRealtime(TRealtimeSocketServerFactory *fact, TRadData *data)
{
}

/*##########################################################################
#
#   Name       : TDataStore::Execute
#
#   Purpose....: Execute thread loop
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDataStore::Execute()
{
        int year, month, day;
        int hour, min, sec;
        int ms, us;
        int i;
        int ival;
        unsigned long msb;
        unsigned long lsb;
        THeatData CurrData;
        TDisc *Disc;
        long StartSector;
        TDiscStorage *DiscStore[4];
        TRedundanceStorageList *redu;
        TStorageSocketServerFactory *storfact;
        TRealtimeSocketServerFactory *realfact;

        RdosGetTime(&msb, &lsb);
        RdosDecodeMsbTics(msb, &FYear, &FMonth, &FDay, &FHour);
        RdosDecodeLsbTics(lsb, &FMin, &sec, &ms, &us);

        Disc = new TDisc(0);
        StartSector = Disc->GetTotalSectors() - 10 * LIST_SECTORS + 4 * LIST_SECTORS;

        for (i = 0; i < 4; i++)
                 DiscStore[i] = new TDiscStorage(Disc, StartSector + LIST_SECTORS * i, LIST_SECTORS);

        redu = new TRedundanceStorageList(sizeof(THeatData), LIST_ID);

        for (i = 0; i < 4; i++)
        redu->Add(DiscStore[i]);

        redu->Recover();
        FStorList = redu;

    storfact = new TStorageSocketServerFactory(redu, 600, 10, 2048);
    storfact->StartHandler("Storage Server", 0x4000);

    realfact = new TRealtimeSocketServerFactory(601, 10, 2048);
    realfact->StartHandler("Realtime Server", 0x4000);
     
        while (FInstalled)
        {
                RdosGetTime(&msb, &lsb);
                RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
                RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);

                if (hour != FHour || min != FMin)
                {
                    FYear = year;
                    FMonth = month;
                    FDay = day;
                        FHour = hour;
                        FMin = min;

                        GetCurrData(&CurrData);
                        FStorList->AddLast(&CurrData);
            realfact->SendData(&CurrData);

        }

        RdosWaitMilli(1000);
    }
}
