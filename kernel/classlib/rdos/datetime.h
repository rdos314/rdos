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
# datetime.h
# Date & time class
#
########################################################################*/

#ifndef _DATETIME_H
#define _DATETIME_H

class TDateTime
{
public:
	TDateTime();
	TDateTime(const TDateTime &Source);
	TDateTime(unsigned long Msb, unsigned long Lsb);
    TDateTime(long double real);
	TDateTime(int Year, int Month, int Day);
	TDateTime(int Year, int Month, int Day, int Hour, int Min, int Sec);
	TDateTime(int Year, int Month, int Day, int Hour, int Min, int Sec, int ms);

	operator long double () const;
 
	long GetMsb() const;
	long GetLsb() const;
    void SetRaw(unsigned long Msb, unsigned long Lsb);
	int HasExpired() const;
	void AddTics(long tics);
	void AddMilli(long ms);
	void AddSec(long sec);
	void AddMin(long min);
	void AddHour(long hour);
	void AddDay(long day);

	int GetYear() const;
	int GetMonth() const;
	int GetDay() const;
	int GetHour() const;
	int GetMin() const;
	int GetSec() const;
	int GetMilliSec() const;

protected:
	void RawToRecord();
	void RecordToRaw();

private:
	unsigned long FMsb;
	unsigned long FLsb;
	int FYear;
	int FMonth;
	int FDay;
	int FHour;
	int FMin;
	int FSec;
	int FMilli;
};

#endif

