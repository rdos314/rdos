/*#######################################################################
# FreeCom for RDOS.
#
# This code builds on Steffen Kaiser (ska) FreeCom project
# The maintainer(s) of FreeCOM can be reached at freecom@freedos.org
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version
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
# The maintainer of this port can be contacted at leif@rdos.net
#
# Timedate.cpp
#
# Handles time & date formatting
#
########################################################################*/

#include "datetime.h"

/*################## FormatTime ##########################
*   Purpose....: Format a time string	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void FormatTime(char *buf, TDateTime *time)
{

	/** Warning: condition always true -- if !NLS **/
	if(fmt == 0) {		/* 12hour display */

		if((pm = hour >= 12) != 0) {
			hour -= 12;
		}
		if(hour == 0)
			hour = 12;

		i = sprintf(p = buf, "%2u%s%02u", hour, sep, minute);
	} else {
		/** Warning: unreachable code -- if !defined(NLS) **/
		i = sprintf(p = buf, "%2u%s%02u", hour, sep, minute);
	}

	assert(strlen(buf) < sizeof(buf));

	if(i == EOF) return 0;
	if(second >= 0) {
		i = sprintf(p += i, "%s%02u", sep, second);
		if(i == EOF) return 0;
		if(fraction) {
			i = sprintf(p += i, "%s%-2u", dsep, fraction);
			if(i == EOF) return 0;
			{	char *q = p + i;
				while(*--q == ' ')
					*q = '0';
			}
		}
	}

	assert(strlen(buf) < sizeof(buf));

	/** Warning: conditional always true -- if !NLS **/
	if(fmt == 0) {
		char *q = getString(pm? TEXT_STRING_PM: TEXT_STRING_AM);
		if(!q)		return 0;
		if(mode & NLS_MAKE_SHORT_AMPM) {
			*(p += i) = *ltrimsp(q);
			p[1] = 0;
		} else
			strcpy(p + i, q);
		free(q);
	}

	assert(strlen(buf) < sizeof(buf));

	return strdup(buf);
}

char *nls_makedate(int mode, int year, int month, int day)
{	char buf[4 + 3 + sizeof(int) * 8 * 3];

#ifdef FEATURE_NLS
	refreshNLS();

	switch(nlsBuf->datefmt) {
	case 0:			/* mm/dd/yy */
		sprintf(buf, "%.2u%s%.2u%s%02u", month, nlsBuf->dateSep, day
		 , nlsBuf->dateSep, year);
		break;
	case 1:			/* dd/mm/yy */
		sprintf(buf, "%02u%s%02u%s%02u", day, nlsBuf->dateSep, month
		 , nlsBuf->dateSep, year);
		break;
	case 2:			/* yy/mm/dd */
		sprintf(buf, "%02u%s%02u%s%02u", year, nlsBuf->dateSep, month
		 , nlsBuf->dateSep, day);
		 
		break;
	}
#else
	sprintf(buf, "%.2u-%.2u-%02u", month, day, year);
#endif

	return strdup(buf);
}
