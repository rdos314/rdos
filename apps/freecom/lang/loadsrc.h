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
# loadsrc.h
# Load FreeCom .lng file class
#
########################################################################*/

#ifndef _LOADSRC_H
#define _LOADSRC_H

#define MAXSTRINGS       1024

#define VERSION_MISMATCH 128
#define VALIDATION_MISMATCH 64
#define PERFORM_VALIDATION 32

typedef enum STATE
{
	LOOKING_FOR_START,
	GETTING_PROMPT_LINE_1,
	GETTING_PROMPT_LINE_2,
	GETTING_STRING
} read_state;

struct TDynString
{
	char *text;
	int length;
};

struct TLangStringIndex
{
  unsigned index;
  unsigned size;
};

struct TLangStrings
{
	int flags;				/* bitfield: #0 -> DEFAULT, #1 -> special LNG file
								meaning: present in particular file
								#5: perform printf() validation
								#6: printf() validation failed
								#7: Version mismatch */
	char *name;				/* name of string */
	char *text;				/* text of this string */
	int version;
	char *vstring;			/* validation string */
	int id;					/* resource ID start */
	int count;				/* number of ID numbers */
};

class TLang
{
public:
	TLang();
	~TLang();

	int Load(const char *fname);

	TLangStrings strg[MAXSTRINGS];
	TLangStringIndex string[MAXSTRINGS];
	int error;
	unsigned cnt;		/* current string number */
	unsigned maxCnt;	/* number of strings within array */

protected:
	void pxerror(const char *msg1, const char *msg2);
	void HandleStart();
	void HandlePrompt1(const char *fname);
	void HandlePrompt2(const char *fname);
	void HandleString();

	int in_file;
	unsigned long linenr;
	char *ldptr;
	read_state state;
	FILE *fin;
	TDynString text;			/* Current text */
	TDynString vstring;		/* Validation string */
	int version;	
	char temp[1024];
};

#endif

