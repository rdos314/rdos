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
# Datastore class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "socket.h"
#include "datastor.h"
#include "rdos.h"
#include "cotdata.h"

#define STACK_SIZE      0x2000

#define FALSE		    0
#define TRUE		    !FALSE

/*##########################################################################
#
#   Name       : TDataStore::TDataStore
#
#   Purpose....: Datastore constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDataStore::TDataStore(const char *RootDir, const char *ServerName, long ServerIp, int ServerPort)
{
    FServerIp = ServerIp;
    FServerPort = ServerPort;

    strcpy(FRootDir, RootDir);
    strlwr(FRootDir);

    CreateRootDir();

    NotifyData = 0;
    
    Start(ServerName, STACK_SIZE);
}

/*##########################################################################
#
#   Name       : TDataStore::TDataStore
#
#   Purpose....: Datastore destructor
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
#   Name       : TDataStore::CreateRootDir
#
#   Purpose....: Create root directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDataStore::CreateRootDir()
{
    if (!RdosSetCurDir(FRootDir))
        RdosMakeDir(FRootDir);
}

/*##########################################################################
#
#   Name       : TDataStore::CreateDayFile
#
#   Purpose....: Create/open a day-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TDataStore::CreateDayFile(int year, int month, int day)
{
	 char str[20];
	 char filename[256];
	 TFile *file;
	 int i, j;
	 int filesize;
	 TFile *File;

	sprintf(str, "%d", year);
	strcpy(filename, FRootDir);
	strcat(filename, "\\");
	strcat(filename, str);

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	sprintf(str, "%d\\%d", year, month);
	strcpy(filename, FRootDir);
	strcat(filename, "\\");
	strcat(filename, str);

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	sprintf(str, "%d\\%d\\%d.cot", year, month, day);
	strcpy(filename, FRootDir);
	strcat(filename, "\\");
	strcat(filename, str);

	File = new TFile(filename);
	if (!File->IsOpen())
	{
		delete File;
		File = new TFile(filename, 0);
	}

	if (File->IsOpen())
		 File->SetPos(File->GetSize());

	return File;
}

/*##########################################################################
#
#   Name       : TDataStore::HandleMsg
#
#   Purpose....: Handle message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDataStore::HandleMsg(TDeviceMsg *doc)
{
    unsigned long msb, lsb;
	TDeviceTag *header;
	int year, month, day, hour;
	int min, sec, ms, us;
	TFile *file;
	int size;
	char *msg;

	header = doc->GetTag(LOG_TAG_HEADER);
	 if (header)
	{
		  msb = header->GetUnsignedInt(LOG_VAR_MsbTime, 0);
		  lsb = header->GetUnsignedInt(LOG_VAR_LsbTime, 0);
		RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
		RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);

    	file = CreateDayFile(year, month, day);

        size = doc->GetSize();
        msg = new char[size];
        doc->GetData(COT_SIGN, msg);
        file->Write(msg, size);
        delete msg;
        delete file;
    }
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
    TSocket *socket;
    int size;
    int count;
	char *msg;
	unsigned long msb, lsb;
	int year, month, day;
	TDeviceMsg *doc;
	char ch;
	long NtpIp;

	NtpIp = RdosNameToIp("ntp.lth.se");

    while (FInstalled)
    {
    	RdosSyncTime(NtpIp);

        socket = new TSocket(0x2800A8C0, 600, 600000, 0x4000);
		socket->WaitForConnection(600000);

		while (socket->IsOpen())
		{
	        if (socket->WaitForChar(30000))
			{
		        count = socket->Read((char *)&size, 4);
				if (count == 4)
				{
					msg = new char[size];
				    count = socket->Read(msg, size);

				    if (count == size)
                    {
                        doc = new TDeviceMsg(MAX_MSG_SIZE);

			    		if (doc->Parse(COT_SIGN, msg, size))
				    	{
					    	delete msg;
						    HandleMsg(doc);

						    if (NotifyData)
						        (*NotifyData)(doc);

    						ch = 0x6;
	    					socket->Write(&ch, 1);
		    				socket->Push();
			    		}
				    	else
					    {
						    delete msg;
    						socket->Close();
	    			    }

		    			delete doc;
			    	}
				    else
				        socket->Close();
				}
			}
			else
			{
    	        socket->Push();
    	        RdosWaitMilli(250);
    	    }
        }
        delete socket;

    	RdosGetTime(&msb, &lsb);
    	lsb = 0;
    	msb++;
    	RdosWaitUntil(msb, lsb);
        
    }
}
