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
# device.cpp
# Basic device class
#
########################################################################*/

#include <stdlib.h>
#include <string.h>
#include "device.h"

#define FALSE 0
#define TRUE !FALSE

TSection TDevice::FListSection;
TDevice *TDevice::FDeviceList = 0;

/*##########################################################################
#
#   Name       : TDevice::InsertDevice
#
#   Purpose....: Insert device into m_DeviceList
#				 Should only done in constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::InsertDevice()
{
	FListSection.Enter();
	FList = FDeviceList;
	FDeviceList = this;
	FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::RemoveDevice
#
#   Purpose....: Remove device from m_DeviceList                   
#				 Should only done in destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::RemoveDevice()
{
	TDevice *ptr;
	TDevice *prev;
	prev = 0;
	FListSection.Enter();
	ptr = FDeviceList;
	while ((ptr != 0) && (ptr != this))
    {
		prev = ptr;
		ptr = ptr->FList;
    }
	if (prev == 0)
		FDeviceList = FDeviceList->FList;
	else
		prev->FList = ptr->FList;
	FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::GetDevice
#
#   Purpose....: Get first device in list		                            
#
#   In params..: DeviceCallb
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::GetDevices(void (*DeviceCallb)(TDevice *Device))
{
	TDevice *ptr;
	FListSection.Enter();
	ptr = FDeviceList;
	while (ptr != 0)
	{
		(*DeviceCallb)(ptr);
		ptr = ptr->FList;
	}
	FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::TDevice
#
#   Purpose....: Constructor for TDevice		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDevice::TDevice()
{
	FIniSection = 0;
	Init();
}

/*##########################################################################
#
#   Name       : TDevice::TDevice
#
#   Purpose....: Constructor for TDevice		                          
#
#   In params..: IniSection to read parameters from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDevice::TDevice(const char *IniSection)
{
	FIniSection = IniSection;
	Init();
}

/*##########################################################################
#
#   Name       : TDevice::LoadProperty
#
#   Purpose....: Loads an integer property		                          
#
#   In params..: Name   name of property
#                Def    default value
#   Out params.: *
#   Returns....: Property value
#
##########################################################################*/
int TDevice::LoadProperty(const char *Name, int Def)
{
	int value;

	if (FIniSection == 0)
    {
    	value = Def;
    }
	else
    {
//		value = GetProfileInt(FIniSection, Name, Def);
        value = Def;
    }
	SaveProperty(Name, value);
	return value;
}

/*##########################################################################
#
#   Name       : TDevice::LoadProperty
#
#   Purpose....: Loads a long property		                          
#
#   In params..: Name   name of property
#                Def    default value
#   Out params.: *
#   Returns....: Property value
#
##########################################################################*/
long TDevice::LoadProperty(const char *Name, long Def)
{
	char value_str[12];
	char default_str[12];
	long value;

	if (FIniSection == 0)
    {
		value = Def;
    }
	else
    {
		ltoa(Def, default_str, 10);
//		if (GetProfileString(FIniSection, Name, default_str, value_str, 12) > 0)
//        {
//			value = atol(value_str);
//        }
//		else
        {
			value = Def;
        }
    }
	SaveProperty(Name, value);
	return value;
}

/*##########################################################################
#
#   Name       : TDevice::SaveProperty
#
#   Purpose....: Save an integer property		                          
#
#   In params..: Name   name of property
#                Value  value to save
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::SaveProperty(const char *Name, int Value)
{
	char stat_str[7];

	if (FIniSection != 0)
    {
		itoa(Value, stat_str, 10);
//		WriteProfileString(FIniSection, Name, stat_str);
	}
}

/*##########################################################################
#
#   Name       : TDevice::SaveProperty
#
#   Purpose....: Save a long property		                          
#
#   In params..: Name   name of property
#                Value  value to save
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::SaveProperty(const char *Name, long Value)
{
	char stat_str[12];

	if (FIniSection != 0)
    {
		ltoa(Value, stat_str, 10);
//		WriteProfileString(FIniSection, Name, stat_str);
	}
}

/*##########################################################################
#
#   Name       : TDevice::~TDevice
#
#   Purpose....: Destructor for TDevice		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDevice::~TDevice()
{
	RemoveDevice();
}

/*##########################################################################
#
#   Name       : TDevice::Init
#
#   Purpose....: Init method for class. register persistent should		
#				 done here.					                               
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Init()
{
	FReset = FALSE;
	FEnabled = FALSE;
	FOnline = FALSE;
	FBusy = FALSE;
	OnOnline = 0;
	OnOffline = 0;
	OnIdle = 0;
	OnBusy = 0;
	InsertDevice();
	FOpen = LoadProperty("Open", FALSE);
}

/*##########################################################################
#
#   Name       : TDevice::NotifyReset
#
#   Purpose....: Notify of system reset			                            
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyReset()
{
	FReset = TRUE;
}

/*##########################################################################
#
#   Name       : TDevice::IsReseted
#
#   Purpose....: Check if device is reseted					                            #
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if reseted
#
##########################################################################*/
int TDevice::IsReseted() const
{
	return FReset;
}

/*##########################################################################
#
#   Name       : TDevice::ClearReset
#
#   Purpose....: Clear reset indication
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::ClearReset()
{
	FReset = FALSE;
}

/*##########################################################################
#
#   Name       : TDevice::Open
#
#   Purpose....: Opens device					                           
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Open()
{
	FOpen = TRUE;
	SaveProperty("Open", FOpen);
}

/*##########################################################################
#
#   Name       : TDevice::Close
#
#   Purpose....: Closes device					                           
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Close()
{
	FOpen = FALSE;
	SaveProperty("Open", FOpen);
}

/*##########################################################################
#
#   Name       : TDevice::IsOpen
#
#   Purpose....: Checks if device is open
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if open
#
##########################################################################*/
int TDevice::IsOpen() const
{
	return FOpen;
}

/*##########################################################################
#
#   Name       : TDevice::Enable
#
#   Purpose....: Enables device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Enable()
{
	FEnabled = TRUE;
}

/*##########################################################################
#
#   Name       : TDevice::Disable
#
#   Purpose....: Disables device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Disable()
{
	FEnabled = FALSE;
}

/*##########################################################################
#
#   Name       : TDevice::IsEnabled
#
#   Purpose....: Checks if device is enabled
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if enabled
#
##########################################################################*/
int TDevice::IsEnabled() const
{
	return FEnabled;
}

/*##########################################################################
#
#   Name       : TDevice::Online
#
#   Purpose....: Sets state to online
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Online()
{
	if (!FOnline)
    {
		FOnline = TRUE;
		if (OnOnline)
			OnOnline(this);
	}
}

/*##########################################################################
#
#   Name       : TDevice::Offline
#
#   Purpose....: Sets state to offline
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Offline()
{
	if (FOnline)
	{
		FOnline = FALSE;
		if (OnOffline)
			OnOffline(this);
	}
}

/*##########################################################################
#
#   Name       : TDevice::IsOnline
#
#   Purpose....: Checks if device is online
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if online
#
##########################################################################*/
int TDevice::IsOnline() const
{
	return FOnline;
}

/*##########################################################################
#
#   Name       : TDevice::IsActive
#
#   Purpose....: Checks if device is open and enabled
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if open and enabled
#
##########################################################################*/
int TDevice::IsActive() const
{
	return FEnabled && FOpen;
}

/*##########################################################################
#
#   Name       : TDevice::Idle
#
#   Purpose....: Sets device to idle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Idle()
{
	if (FBusy)
    {
		FBusy = FALSE;
		if (OnIdle)
			OnIdle(this);
	}
}

/*##########################################################################
#
#   Name       : TDevice::Busy
#
#   Purpose....: Sets device to busy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Busy()
{
	if (!FBusy)
	{
		FBusy = TRUE;
		if (OnBusy)
			OnBusy(this);
	}
}

/*##########################################################################
#
#   Name       : TDevice::IsBusy
#
#   Purpose....: Check if device is busy
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if busy
#
##########################################################################*/
int TDevice::IsBusy() const
{
	return FBusy;
}
