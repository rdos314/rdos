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
# makedll.cpp
# Make DLL files from FreeComs .lng files
#
########################################################################*/

#include <ctype.h>
#include <dir.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "loadsrc.h"

#define MAX_LINES 32

TLang lang;

int WriteRcFile(const char *filename)
{
	FILE *file;
	int i, j;
	char str[2];
	const unsigned char *ptr;
	int id;

	str[1] = 0;

	if ((file = fopen(filename,"wb")) == NULL)
		return 36;

	fprintf(file, "#include \"lang.h\"\n");
	fprintf(file, "\n");
	fprintf(file, "STRINGTABLE\n");
	fprintf(file, "{\n");

	id = MAXSTRINGS;

	for (i = 0; i < lang.maxCnt; i++)
	{
		lang.strg[i].count = id;
		lang.strg[i].id = id;
		fprintf(file, " %d, \"", id);
		id++;

		ptr = (const unsigned char *)lang.strg[i].text;
		while(*ptr)
		{
			switch (*ptr)
			{
				case 0xd:
				case 0xa:
					fprintf(file, "\\r\\n");
					if (*(ptr + 1))
					{
						fprintf(file, "\";\n");
						fprintf(file, " %d, \"", id);
						id++;
					}
					break;

				case 0xFE:
					fprintf(file, "\\r");
					break;

				case 0xFF:
					fprintf(file, "\\n");
					break;

				case '\\':
					fprintf(file, "\\\\");
					break;

				case '"':
					fprintf(file, "\\\"");
					break;

				case '@':
//					fprintf(file, "");
					break;

				default:
					str[0] = *ptr;
					fprintf(file, str);
					break;
			}
			ptr++;
		}

		lang.strg[i].count = id - lang.strg[i].count;
		fprintf(file, "\";\n");
	}

	for (i = 0; i < lang.maxCnt; i++)
		fprintf(file, " %s, \"%d,%d\";\n",
				lang.strg[i].name,
				lang.strg[i].id, lang.strg[i].count);

	fprintf(file, "}\n");
	fprintf(file, "\n");

	fflush(file);
	if(ferror(file))
	{
		fputs("Unspecific write error into " ".dat" "\n", stderr);
		return 38;
	}
	fclose(file);
	return 0;
}

int WriteHFile(const char *filename)
{
	FILE *file;
	int i;

	if ((file = fopen(filename,"wt")) == NULL)
		return 37;

	fprintf(file, "#ifndef LANG_H\n");
	fprintf(file, "#define LANG_H\n");
	fprintf(file, "\n");

	for (i = 0; i < lang.maxCnt; i++)
		fprintf(file, "#define %s  %d\n", lang.strg[i].name, i);

	fprintf(file, "\n");
	fprintf(file, "#endif\n");

	fflush(file);
	if(ferror(file))
	{
		fputs("Unspecific write error into " ".h" "\n", stderr);
		return 39;
	}

	fclose(file);
	return 0;
}

int MakeDll(const char *filename)
{
	char logfile[256];
	char rcfile[256];
	char hfile[256];
	FILE *log;
	unsigned long size;
	unsigned cnt;		/* current string number */
	unsigned lsize;
	int error;

	strcpy(logfile, "default.log");
	strcpy(rcfile, "english.rc");
	strcpy(hfile, "lang.h");

	if (!lang.Load("default.lng"))
		return lang.error;

	strcpy(logfile, filename);
	strcat(logfile, ".log");
	unlink(logfile);

	strcpy(rcfile, filename);
	strcat(rcfile, ".rc");

	if (!lang.Load(filename))
		return lang.error;

/* Now all the strings are cached into memory */

	if(lang.maxCnt < 2)
	{
		fputs("No string definition found.\n", stderr);
		return 43;
	}

	/* Create the LOG file */
	log = NULL;			/* No LOG entry til this time */
	for(cnt = 0; cnt < lang.maxCnt; ++cnt)
	{
		switch(lang.strg[cnt].flags & 3)
		{
			case 0:		/* Er?? */
				fputs("Internal error assigned string has no origin?!\n"
					 , stderr);
				return 99;

			case 1:		/* DEFAULT.LNG only */
				if(!log && (log = fopen(logfile, "wt")) == NULL)
				{
					fprintf(stderr, "Cannot create logfile: '%s'\n"
						 , logfile);
					goto breakLogFile;
				}
				fprintf(log, "%s: Missing from local LNG file\n"
					 , lang.strg[cnt].name);
				break;

			case 2:		/* local.LNG only */
				if(!log && (log = fopen(logfile, "wt")) == NULL)
				{
					fprintf(stderr, "Cannot create logfile: '%s'\n"
						 , logfile);
					goto breakLogFile;
				}
				fprintf(log, "%s: No such string resource\n"
					 , lang.strg[cnt].name);
				break;

			case 3:		/* OK */
				break;
		}

		if(lang.strg[cnt].flags & VERSION_MISMATCH)
		{
			if(!log && (log = fopen(logfile, "wt")) == NULL)
			{
				fprintf(stderr, "Cannot create logfile: '%s'\n"
					 , logfile);
				goto breakLogFile;
			}
			fprintf(log, "%s: Version mismatch, current is: %u\n"
				 , lang.strg[cnt].name, lang.strg[cnt].version);
		}

		if(lang.strg[cnt].flags & VALIDATION_MISMATCH)
		{
			if(!log && (log = fopen(logfile, "wt")) == NULL)
			{
				fprintf(stderr, "Cannot create logfile: '%s'\n"
					 , logfile);
				goto breakLogFile;
			}
			fprintf(log, "%s: printf() format string mismatch, should be: %s\n"
				 , lang.strg[cnt].name, lang.strg[cnt].vstring);
		}
	}

	if(log)
		fclose(log);

breakLogFile:

	error = WriteHFile(hfile);
	if (error)
		return error;

	error = WriteRcFile(rcfile);
	if (error)
		return error;

	return 0;
}

int main(int argc, char **argv)
{
	MakeDll("swedish");
	MakeDll("dutch");
	MakeDll("french");
	MakeDll("german");
	MakeDll("italian");
	MakeDll("pt_br");
	MakeDll("russian");
	MakeDll("serbian");
	MakeDll("spanish");
	MakeDll("yu437");
	MakeDll("english");
}
