/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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
	MakeDll("english");
}
