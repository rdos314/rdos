/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# cmdhelp.cpp
# Command help base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "file.h"
#include "strlist.h"
#include "keyboard.h"

#define FALSE 0
#define TRUE !FALSE

int FStdInput = TRUE;
int FStdOutput = TRUE;

TFile *FInputFile = new TFile("CON");
TFile *FOutputFile = new TFile("CON");
TFile *FErrorFile = new TFile("CON");

static TStringList History;
static TWait *wait;
static TKeyboardDevice *keyboard;

/*##########################################################################
#
#   Name       : SetInputFile
#
#   Purpose....: Set input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetInputFile(TFile *File)
{
	FInputFile = File;
}

/*##########################################################################
#
#   Name       : SetOutputFile
#
#   Purpose....: Set output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetOutputFile(TFile *File)
{
	FOutputFile = File;
}

/*##########################################################################
#
#   Name       : SetErrorFile
#
#   Purpose....: Set error file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetErrorFile(TFile *File)
{
	FErrorFile = File;
}

/*##########################################################################
#
#   Name       : GetInputFile
#
#   Purpose....: Get input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *GetInputFile()
{
	return FInputFile;
}

/*##########################################################################
#
#   Name       : GetOutputFile
#
#   Purpose....: Get output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *GetOutputFile()
{
	return FOutputFile;
}

/*##########################################################################
#
#   Name       : GetErrorFile
#
#   Purpose....: Get error file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *GetErrorFile()
{
	return FErrorFile;
}

/*##########################################################################
#
#   Name       : IsEmpty
#
#   Purpose....: Return true if string is 0 or contains only spaces
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsEmpty(const char *s)
{
	if (s)
	{
		while(*s)
		{
			s++;
			if (!isspace(*s))
				return FALSE;
		}
	}
	return TRUE;
}

/*##########################################################################
#
#   Name       : IsArgDelim
#
#   Purpose....: Check for argument delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsArgDelim(char ch)
{
	return isspace(ch) || iscntrl(ch) || strchr(",;=", ch);
}

/*##########################################################################
#
#   Name       : IsOptDelim
#
#   Purpose....: Check for option delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsOptDelim(char ch)
{
	return isspace(ch) || iscntrl(ch);
}

/*##########################################################################
#
#   Name       : IsOptChar
#
#   Purpose....: Is option char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsOptChar(char ch)
{
	return ch == '/';
}


/*##########################################################################
#
#   Name       : IsFileNameChar
#
#   Purpose....: Is filename char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsFileNameChar(char c)
{
    return !(c <= ' ' || c == 0x7f || strchr(".\"/\\[]:|<>+=;,", c));
}

/*##########################################################################
#
#   Name       : LTrimsp
#
#   Purpose....: Trim of leading spaces
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *LTrimsp(const char *str)
{
	while (*str && isspace(*str))
	    str++;
	return str;
}

/*##########################################################################
#
#   Name       : LTrim
#
#   Purpose....: Remove leading "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *LTrim(const char *str)
{
	while (*str)
	{
		if (IsArgDelim(*str))
			str++;
		else
			break;
	}
	return str;
}

/*##########################################################################
#
#   Name       : RTrim
#
#   Purpose....: Remove trailing "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void RTrim(char *str)
{ 
	char *p;

	p = strchr(str, 0);
	p--;

	while (p >= str && IsArgDelim(*p))
		p--;

	p[1] = 0;
}

/*##########################################################################
#
#   Name       : Unquote
#
#   Purpose....: Unquote to new string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *Unquote(const char *str, const char *end)
{
	char *h, *newStr;
	const char *q;
	int len;

	newStr = new char[end - str + 1];
	h = newStr;

	while ((q = strpbrk(str, "\"")) != 0 && q < end)
	{
		memcpy(h, str, len = q++ - str);
		h += len;
		if ((str = strchr(q, q[-1])) == 0 || str >= end)
		{
			str = q;
			break;
		}

		memcpy(h, q, len = str++ - q);
		h += len;
	}

	memcpy(h, str, len = end - str);
	h[len] = 0;
	return newStr;
}

/*##########################################################################
#
#   Name       : MatchToken
#
#   Purpose....: Match token at begining of line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int MatchToken(char **Xp, const char *word, int len)
{	
    char *p;
    char *q;

    p = *Xp;
	if (strncmpi(p, word, len) == 0)
	{
		p += len;
		if (*p)
		{
			q = (char *)LTrim(p);
			if (q == p)
				return FALSE;
			p = q;
		}
		*Xp = p;
		return TRUE;
	}

	return FALSE;
}

/*##########################################################################
#
#   Name       : Write
#
#   Purpose....: Write character to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void Write(char ch)
{
	char str[2];

	str[0] = ch;
	str[1] = 0;

	if (FOutputFile)
		FOutputFile->Write(str, 1);
}

/*##########################################################################
#
#   Name       : Write
#
#   Purpose....: Write string to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void Write(const char *str)
{
	int size = strlen(str);

	if (FOutputFile)
		FOutputFile->Write(str, size);
}

/*##########################################################################
#
#   Name       : WriteError
#
#   Purpose....: Write character to standard error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void WriteError(char ch)
{
	char str[2];

	str[0] = ch;
	str[1] = 0;

	if (FOutputFile)
		FOutputFile->Write(str, 1);
}

/*##########################################################################
#
#   Name       : WriteError
#
#   Purpose....: Write string to standard error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void WriteError(const char *str)
{
	int size = strlen(str);

	if (FOutputFile)
		FOutputFile->Write(str, size);
}

/*##########################################################################
#
#   Name       : WriteNumber
#
#   Purpose....: Write number to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void WriteLong(long value)
{
	char str[4];
	int tmp;
	int use = FALSE;

	tmp = value / 1000000000;
	if (tmp)
	{
		use = TRUE;
		sprintf(str, "%2d", tmp);
	}
	else
		strcpy(str, "  ");
	Write(str);
	Write(" ");
	value = value % 1000000000;

	tmp = value / 1000000;
	if (use)
		sprintf(str, "%03d", tmp);
	else
	{
		if (tmp)
		{
			use = TRUE;
			sprintf(str, "%3d", tmp);
		}
		else
			strcpy(str, "   ");
	}
	Write(str);
	Write(" ");
	value = value % 1000000;

	tmp = value / 1000;
	if (use)
		sprintf(str, "%03d", tmp);
	else
	{
		if (tmp)
		{
			use = TRUE;
			sprintf(str, "%3d", tmp);
		}
		else
			strcpy(str, "   ");
	}
	Write(str);
	Write(" ");
	value = value % 1000;

	tmp = value;
	if (use)
		sprintf(str, "%03d", tmp);
	else
		sprintf(str, "%3d", tmp);
	Write(str);
}

/*##########################################################################
#
#   Name       : Read
#
#   Purpose....: Read a character from standard input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char Read()
{
	char ch = 3;

	if (FInputFile)
		FInputFile->Read(&ch, 1);

	return ch;
}

/*##########################################################################
#
#   Name       : Read
#
#   Purpose....: Read a string from standard input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int Read(char *str, int maxsize)
{
	char ch;
	int i;

	if (FInputFile)
	{
		for (i = 0; i < maxsize; i++)
		{
			ch = 0;
			FInputFile->Read(&ch, 1);

			if (ch == 3)
				return FALSE;

			if (ch == 0 || ch == 0xa)
			{
				*str = 0;
				break;
			}
			else
			{
				*str = ch;
				str++;
			}
		}
		*str = 0;
		return TRUE;
	}
	return FALSE;
}

/*##########################################################################
#
#   Name       : ReadCon
#
#   Purpose....: Read a string from console
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int ReadCon(char *str, int maxsize)
{
	char insert = 1;
	char ch;
	int histLevel = 0;
	int curx;
	int cury;
	int count;
	int current = 0;
	int charcount = 0;

	int OrgX;
	int OrgY;
	int ExtKey;
	int State;
	int VirtKey;
	int ScanCode;

	RdosGetCursorPosition(&OrgY, &OrgX);
	memset(str, 0, maxsize);

	if (!Wait)
		Wait = new TWait;

	if (!Keyboard)
		Keyboard = new TKeyboard(Wait);

	do
	{
		Wait->WaitForEver();
		if (ReadEvent(&ExtKey, &State, &VirtKey, &ScanCode))
		{

		if(cbreak)
			ch = KEY_CTL_C;

		switch(ch) {
		case KEY_BS:               /* delete character to left of cursor */

			if(current > 0 && charcount > 0) {
			  if(current == charcount) {     /* if at end of line */
				str[current - 1] = 0;
				if (wherex() != 1)
				  outs("\b \b");
				else
				{
				  goxy(MAX_X, wherey() - 1);
				  outblank();
				  goxy(MAX_X, wherey() - 1);
				}
			  }
			  else
			  {
				for (count = current - 1; count < charcount; count++)
				  str[count] = str[count + 1];
				if (wherex() != 1)
				  goxy(wherex() - 1, wherey());
				else
				  goxy(MAX_X, wherey() - 1);
				curx = wherex();
				cury = wherey();
				outsblank(&str[current - 1]);
				goxy(curx, cury);
			  }
			  charcount--;
			  current--;
			}
			break;

		case KEY_INSERT:           /* toggle insert/overstrike mode */
			insert ^= 1;
			if (insert)
			  _setcursortype(_NORMALCURSOR);
			else
			  _setcursortype(_SOLIDCURSOR);
			break;

		case KEY_DELETE:           /* delete character under cursor */

			if (current != charcount && charcount > 0)
			{
			  for (count = current; count < charcount; count++)
				str[count] = str[count + 1];
			  charcount--;
			  curx = wherex();
			  cury = wherey();
			  outsblank(&str[current]);
			  goxy(curx, cury);
			}
			break;

		case KEY_HOME:             /* goto beginning of string */

			if (current != 0)
			{
			  goxy(orgx, orgy);
			  current = 0;
			}
			break;

		case KEY_END:              /* goto end of string */

			if (current != charcount)
			{
			  goxy(orgx, orgy);
			  outs(str);
			  current = charcount;
			}
			break;

#ifdef FEATURE_FILENAME_COMPLETION
		case KEY_TAB:		 /* expand current file name */
			if(current == charcount) {      /* only works at end of line */
			  if(lastch != KEY_TAB) { /* if first TAB, complete filename */
				complete_filename(str, charcount);
				charcount = strlen(str);
				current = charcount;

				goxy(orgx, orgy);
				outs(str);
				if ((strlen(str) > (MAX_X - orgx)) && (orgy == MAX_Y + 1))
				  orgy--;
			  } else {                 /* if second TAB, list matches */
				if (show_completion_matches(str, charcount))
				{
				  printprompt();
				  orgx = wherex();
				  orgy = wherey();
				  outs(str);
				}
			  }
			}
			else
			  beep();
			break;
#endif

		case KEY_ENTER:            /* end input, return to main */

#ifdef FEATURE_HISTORY
			if(str[0])
			  histSet(0, str);      /* add to the history */
#endif

			outc('\n');
			break;

		case KEY_CTL_C:       		/* ^C */
		case KEY_ESC:              /* clear str  Make this callable! */

			clrcmdline(str, maxlen, orgx, orgy);
			current = charcount = 0;

			if(ch == KEY_CTL_C && !echo) {
			  /* enable echo to let user know that's this
				is the command line */
			  echo = 1;
			  printprompt();
			}
			break;

		case KEY_RIGHT:            /* move cursor right */

			if (current != charcount)
			{
			  current++;
			  if (wherex() == MAX_X)
				goxy(1, wherey() + 1);
			  else
				goxy(wherex() + 1, wherey());
				break;
			}
			/* cursor-right at end of string grabs the next character
				from the previous line */
			/* FALL THROUGH */

#ifndef FEATURE_HISTORY
			break;
#else
		case KEY_F1:       /* get character from last command buffer */
			  if (current < strlen(prvLine)) {
				 outc(str[current] = prvLine[current]);
				 charcount = ++current;
			  }
			  break;
			  
		case KEY_F3:               /* get previous command from buffer */
			if(charcount < strlen(prvLine)) {
				outs(strcpy(&str[charcount], &prvLine[charcount]));
			   current = charcount = strlen(str);
		   }
		   break;

		case KEY_UP:               /* get previous command from buffer */
			if(!histGet(--histLevel, prvLine, sizeof(prvLine)))
				++histLevel;		/* failed -> keep current command line */
			else {
				clrcmdline(str, maxlen, orgx, orgy);
				strcpy(str, prvLine);
				current = charcount = strlen(str);
				outs(str);
				histGet(histLevel - 1, prvLine, sizeof(prvLine));
			}
			break;

		case KEY_DOWN:             /* get next command from buffer */
			if(histLevel) {
				clrcmdline(str, maxlen, orgx, orgy);
				strcpy(prvLine, str);
				histGet(++histLevel, str, maxlen);
				current = charcount = strlen(str);
				outs(str);
			}
			break;

		case KEY_F5: /* keep cmdline in F3/UP buffer and move to next line */
			strcpy(prvLine, str);
			clrcmdline(str, maxlen, orgx, orgy);
			outc('@');
			if(orgy >= MAX_Y) {
				outc('\n');			/* Force scroll */
				orgy = MAX_Y;
			} else {
				++orgy;
			}
			goxy(orgx, orgy);
			current = charcount = 0;

			break;

#endif

		case KEY_LEFT:             /* move cursor left */

			if (current > 0)
			{
			  current--;
			  if (wherex() == 1)
				goxy(MAX_X, wherey() - 1);
			  else
				goxy(wherex() - 1, wherey());
			}
#if 0
			else
				   beep();
#endif
			break;

		default:                 /* insert character into string... */

			if ((ch >= 32 && ch <= 255) && (charcount != (maxlen - 2)))
			{
			  if (insert && current != charcount)
			  {
				for (count = charcount; count > current; count--)
				  str[count] = str[count - 1];
				str[current++] = ch;
				curx = wherex() + 1;
				cury = wherey();
				outs(&str[current - 1]);
				if ((strlen(str) > (MAX_X - orgx)) && (orgy == MAX_Y + 1))
				  cury--;
				goxy(curx, cury);
				charcount++;
			  }
			  else
			  {
				if (current == charcount)
				  charcount++;
				str[current++] = ch;
				outc(ch);
			  }
			  if ((strlen(str) > (MAX_X - orgx)) && (orgy == MAX_Y + 1))
				orgy--;
			}
			else
			  beep();
			break;
		}
#ifdef FEATURE_FILENAME_COMPLETION
		lastch = ch;
#endif
	} while(ch != KEY_ENTER);

	_setcursortype(_NORMALCURSOR);
}

/*##########################################################################
#
#   Name       : ReadCmd
#
#   Purpose....: Read a command string from standard input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int ReadCmd(char *str, int maxsize)
{
	if (FInputFile->IsDevice())
		return ReadCon(str, maxsize);
	else
		return Read(str, maxsize);
}
