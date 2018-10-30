/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2018, Leif Ekblad
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
# json.cpp
# json class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <stdarg.h>

#include "json.h"
#include "rdos.h"

#define json_tokener_success				1
#define json_tokener_continue				2
#define json_tokener_error_depth			3
#define json_tokener_error_parse_eof			4
#define json_tokener_error_parse_unexpected		5
#define json_tokener_error_parse_null			6
#define json_tokener_error_parse_boolean		7
#define json_tokener_error_parse_number			8
#define json_tokener_error_parse_array			9
#define json_tokener_error_parse_object_key_name	10
#define json_tokener_error_parse_object_key_sep		11
#define json_tokener_error_parse_object_value_sep	12
#define json_tokener_error_parse_string			13
#define json_tokener_error_parse_comment		14
#define json_tokener_error_size				15

#define json_tokener_state_eatws			1
#define json_tokener_state_start			2
#define json_tokener_state_finish			3
#define json_tokener_state_null				4
#define json_tokener_state_comment_start		5
#define json_tokener_state_comment			6
#define json_tokener_state_comment_eol			7
#define json_tokener_state_comment_end			8
#define json_tokener_state_string			9
#define json_tokener_state_string_escape		10
#define json_tokener_state_escape_unicode		11
#define json_tokener_state_boolean			12
#define json_tokener_state_number			13
#define json_tokener_state_array			14
#define json_tokener_state_array_add			15
#define json_tokener_state_array_sep			16
#define json_tokener_state_object_field_start		17
#define json_tokener_state_object_field			18
#define json_tokener_state_object_field_end		19
#define json_tokener_state_object_value			20
#define json_tokener_state_object_value_add		21
#define json_tokener_state_object_sep			22
#define json_tokener_state_array_after_sep		23
#define json_tokener_state_object_field_start_after_sep	24
#define json_tokener_state_inf				25

#define json_ret_out                                    1
#define json_ret_redo                                   2
#define json_ret_break                                  3

/*##########################################################################
#
#   Name       : PrintfCallback
#
#   Purpose....: Printf callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void PrintfCallback(void *param, char ch)
{
    TJsonPrintBuf *buf = (TJsonPrintBuf *)param;
    buf->MemAppend(&ch, 1);
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::TJsonPrintBuf
#
#   Purpose....: Constructor for TJsonPrintBuf
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonPrintBuf::TJsonPrintBuf()
{
    FSize = 32;
    FBpos = 0;
    FBuf = new char[FSize];
    FBuf[0] = 0;
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::~TJsonPrintBuf
#
#   Purpose....: Destructor for TJsonPrintBuf
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonPrintBuf::~TJsonPrintBuf()
{
    delete FBuf;
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::Reset
#
#   Purpose....: Reset object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonPrintBuf::Reset()
{
    FBpos = 0;
    FBuf[0] = 0;
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::Extend
#
#   Purpose....: Extend buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonPrintBuf::Extend(int min_size)
{
    char *t;
    int new_size;

    if (FSize < min_size)
    {
        new_size = FSize * 2;
        if (new_size < min_size + 8)
            new_size =  min_size + 8;

        t = new char[new_size];
        memcpy(t, FBuf, FSize);
        delete FBuf;

        FSize = new_size;
        FBuf = t;
    }
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::MemAppend
#
#   Purpose....: Append
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonPrintBuf::MemAppend(const char *buf, int size)
{
    if (FSize <= FBpos + size + 1) 
        Extend(FBpos + size + 1);

    memcpy(FBuf + FBpos, buf, size);
    FBpos += size;
    FBuf[FBpos]= 0;
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::MemSet
#
#   Purpose....: Set
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonPrintBuf::Memset(int offset, int charvalue, int len)
{
    int size_needed;

    if (offset == -1)
        offset = FBpos;

    size_needed = offset + len;

    if (FSize < size_needed)
        Extend(size_needed);

    memset(FBuf + offset, charvalue, len);
    if (FBpos < size_needed)
        FBpos = size_needed;
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::printf
#
#   Purpose....: printf
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonPrintBuf::printf(const char *fmt, va_list args)
{
    int n;

    n = RdosPrintf(&PrintfCallback, this, fmt, args);
        
    return n;
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::printf
#
#   Purpose....: printf
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonPrintBuf::printf(const char *fmt, ...)
{
    va_list args;
    int result;

    va_start(args, fmt);
    result = RdosPrintf(&PrintfCallback, this, fmt, args);
    va_end(args);

    return result;
}

/*##########################################################################
#
#   Name       : TJsonObject::TJsonObject
#
#   Purpose....: Constructor for TJsonObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject::TJsonObject()
{
}

/*##########################################################################
#
#   Name       : TJsonObject::~TJsonObject
#
#   Purpose....: Destructor for TJsonObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject::~TJsonObject()
{
}

/*##########################################################################
#
#   Name       : TJsonArray::TJsonArray
#
#   Purpose....: Constructor for TJsonArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonArray::TJsonArray()
{
}

/*##########################################################################
#
#   Name       : TJsonArray::~TJsonArray
#
#   Purpose....: Destructor for TJsonArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonArray::~TJsonArray()
{
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::TJsonStackEntry
#
#   Purpose....: Constructor for TJsonStackEntry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonStackEntry::TJsonStackEntry(TJsonObject *object)
{
    pb = new TJsonPrintBuf;
    obj = object;
    obj_field_name = 0;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::~TJsonStackEntry
#
#   Purpose....: Destructor for TJsonStackEntry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonStackEntry::~TJsonStackEntry()
{
    if (pb)
        delete pb;

    if (obj_field_name)
        delete obj_field_name;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::AddLevel
#
#   Purpose....: Add level
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonStackEntry::AddLevel(TJsonDocument *doc, TJsonObject *object)
{
    return doc->AddLevel(object);
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleEatWs
#
#   Purpose....: Handle eat ws state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleEatWs(TJsonDocument *doc)
{
    while (isspace(*doc->str)) 
    {
	if (!doc->AdvanceChar() || !doc->PeekChar(this))
	    return json_ret_out;
    }

    if (*doc->str == '/') 
    {
        pb->Reset();
	pb->MemAppend(doc->str, 1);
	state = json_tokener_state_comment_start;
    } 
    else 
    {
        state = saved_state;
        return json_ret_redo;
    }
    return json_ret_break;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleStart
#
#   Purpose....: Handle state state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleStart(TJsonDocument *doc)
{
    TJsonObject *o;

    switch (*doc->str) 
    {
        case '{':
	    state = json_tokener_state_eatws;
	    saved_state = json_tokener_state_object_field_start;
	    o = new TJsonObject();
            if (AddLevel(doc, o))
                return json_ret_break;
            else
                return json_ret_out;

        case '[':
            state = json_tokener_state_eatws;
            saved_state = json_tokener_state_array;
	    o = new TJsonArray();
            if (AddLevel(doc, o))
                return json_ret_break;
            else
                return json_ret_out;

        case 'I':
        case 'i':
            state = json_tokener_state_inf;
            pb->Reset();
	    doc->st_pos = 0;
            return json_ret_redo;

        case 'N':
        case 'n':
	    state = json_tokener_state_null; // or NaN
            pb->Reset();
	    doc->st_pos = 0;
	    return json_ret_redo;

        case '\'':
        case '"':
	    state = json_tokener_state_string;
	    pb->Reset();
	    doc->quote_char = *doc->str;
            return json_ret_break;

        case 'T':
        case 't':
        case 'F':
        case 'f':
	    state = json_tokener_state_boolean;
	    pb->Reset();
	    doc->st_pos = 0;
	    return json_ret_redo;

        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '-':
	    state = json_tokener_state_number;
	    pb->Reset();
            doc->is_double = 0;
	    return json_ret_redo;

        default:
	    doc->err = json_tokener_error_parse_unexpected;
	    return json_ret_out;
    }
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::Parse
#
#   Purpose....: Parse object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonStackEntry::Parse(TJsonDocument *doc)
{
    int ret;

    switch(state) 
    {
        case json_tokener_state_eatws:
            ret = HandleEatWs(doc);

        case json_tokener_state_start:
            ret = HandleStart(doc);
    }

    return true;
}

/*##########################################################################
#
#   Name       : TJsonDocument::TJsonDocument
#
#   Purpose....: Constructor for TJsonDocument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDocument::TJsonDocument()
{
}

/*##########################################################################
#
#   Name       : TJsonDocument::TJsonDocument
#
#   Purpose....: Constructor for TJsonDocument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDocument::TJsonDocument(const char *doc)
{
}

/*##########################################################################
#
#   Name       : TJsonDocument::~TJsonDocument
#
#   Purpose....: Destructor for TJsonDocument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDocument::~TJsonDocument()
{
}

/*##########################################################################
#
#   Name       : TJsonDocument::PeekChar
#
#   Purpose....: Peek next char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonDocument::PeekChar(TJsonStackEntry *entry)
{
    if (char_offset == len)
    {
        if (depth == 0 && entry->state == json_tokener_state_eatws && entry->saved_state == json_tokener_state_finish)
            err = json_tokener_success;
        else
            err = json_tokener_continue;

        return false;
    }
    else
        return true;
}
 
/*##########################################################################
#
#   Name       : TJsonDocument::AdvanceChar
#
#   Purpose....: Advance to next char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonDocument::AdvanceChar()
{
    if (*str)
    {
        str++;
        char_offset++;
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TJsonDocument::AddLevel
#
#   Purpose....: Add new level
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonDocument::AddLevel(TJsonObject *object)
{
    TJsonStackEntry *entry;

    if (depth < MAX_JSON_DEPTH)
    {
        entry = new TJsonStackEntry(object);
        StackArr[depth] = entry;
        depth++;
        return entry->Parse(this);
    }
    else
        return false;
}

/*
struct json_object* json_tokener_parse_ex(struct json_tokener *tok,
					  const char *str, int len)
{
  struct json_object *obj = NULL;
  char c = '\1';

  t*ok->char_offset = 0;
  tok->err = json_tokener_success;

  if ((len < -1) || (len == -1 && strlen(str) > INT32_MAX)) {
    tok->err = json_tokener_error_size;
    return NULL;
  }

  while (PEEK_CHAR(c, tok)) 
  {

  redo_char:


      break;

    case json_tokener_state_finish:
      if(tok->depth == 0) goto out;
      obj = json_object_get(current);
      json_tokener_reset_level(tok, tok->depth);
      tok->depth--;
      goto redo_char;

    case json_tokener_state_inf:
      {
	int is_negative = 0;
	const char *_json_inf_str = json_inf_str;
	if (!(tok->flags & JSON_TOKENER_STRICT))
		_json_inf_str = json_inf_str_lower;

	while (tok->st_pos < (int)json_inf_str_len)
	{
		char inf_char = *str;
		if (!(tok->flags & JSON_TOKENER_STRICT))
			inf_char = tolower((int)*str);
		if (inf_char != _json_inf_str[tok->st_pos])
		{
			tok->err = json_tokener_error_parse_unexpected;
			goto out;
		}
		tok->st_pos++;
		(void)ADVANCE_CHAR(str, tok);
		if (!PEEK_CHAR(c, tok))
		{
			goto out;
		}
	}
	if (printbuf_length(tok->pb) > 0 && *(tok->pb->buf) == '-')
	{
		is_negative = 1;
	}
	current = json_object_new_double(is_negative
					 ? -INFINITY : INFINITY);
	if (current == NULL)
		goto out;
	saved_state = json_tokener_state_finish;
	state = json_tokener_state_eatws;
	goto redo_char;
	 
      }
      break;

    case json_tokener_state_null:
      {
	int size;
	int size_nan;
	printbuf_memappend_fast(tok->pb, &c, 1);
	size = json_min(tok->st_pos+1, json_null_str_len);
	size_nan = json_min(tok->st_pos+1, json_nan_str_len);
	if((!(tok->flags & JSON_TOKENER_STRICT) &&
	  strncasecmp(json_null_str, tok->pb->buf, size) == 0)
	  || (strncmp(json_null_str, tok->pb->buf, size) == 0)
	  ) 
        {
	  if (tok->st_pos == json_null_str_len) {
	    current = NULL;
	    saved_state = json_tokener_state_finish;
	    state = json_tokener_state_eatws;
	    goto redo_char;
	  }
	}
	else if ((!(tok->flags & JSON_TOKENER_STRICT) &&
	          strncasecmp(json_nan_str, tok->pb->buf, size_nan) == 0) ||
	         (strncmp(json_nan_str, tok->pb->buf, size_nan) == 0)
	        )
	{
		if (tok->st_pos == json_nan_str_len)
		{
			current = json_object_new_double(NAN);
			if (current == NULL)
			    goto out;
			saved_state = json_tokener_state_finish;
			state = json_tokener_state_eatws;
			goto redo_char;
		}
	} 
        else 
        {
	  tok->err = json_tokener_error_parse_null;
	  goto out;
	}
	tok->st_pos++;
      }
      break;

    case json_tokener_state_comment_start:
      if(c == '*') 
      {
	state = json_tokener_state_comment;
      } 
      else if(c == '/') 
      {
	state = json_tokener_state_comment_eol;
      } 
      else 
      {
	tok->err = json_tokener_error_parse_comment;
	goto out;
      }
      printbuf_memappend_fast(tok->pb, &c, 1);
      break;

    case json_tokener_state_comment:
          const char *case_start = str;
          while(c != '*') {
            if (!ADVANCE_CHAR(str, tok) || !PEEK_CHAR(c, tok)) {
              printbuf_memappend_fast(tok->pb, case_start, str-case_start);
              goto out;
            }
          }
          printbuf_memappend_fast(tok->pb, case_start, 1+str-case_start);
          state = json_tokener_state_comment_end;
        }
        break;

    case json_tokener_state_comment_eol:
	const char *case_start = str;
	while(c != '\n') {
	  if (!ADVANCE_CHAR(str, tok) || !PEEK_CHAR(c, tok)) {
	    printbuf_memappend_fast(tok->pb, case_start, str-case_start);
	    goto out;
	  }
	}
	printbuf_memappend_fast(tok->pb, case_start, str-case_start);
	state = json_tokener_state_eatws;
      }
      break;

    case json_tokener_state_comment_end:
      printbuf_memappend_fast(tok->pb, &c, 1);
      if(c == '/')
	state = json_tokener_state_eatws;
      else
	state = json_tokener_state_comment;
      break;

    case json_tokener_state_string:
      {
	const char *case_start = str;
	while(1) 
        {
	  if(c == tok->quote_char) 
          {
	    printbuf_memappend_fast(tok->pb, case_start, str-case_start);
	    current = json_object_new_string_len(tok->pb->buf, tok->pb->bpos);
	    if(current == NULL)
		goto out;
	    saved_state = json_tokener_state_finish;
	    state = json_tokener_state_eatws;
	    break;
	  } 
          else if(c == '\\') 
          {
	    printbuf_memappend_fast(tok->pb, case_start, str-case_start);
	    saved_state = json_tokener_state_string;
	    state = json_tokener_state_string_escape;
	    break;
	  }

	  if (!ADVANCE_CHAR(str, tok) || !PEEK_CHAR(c, tok)) 
          {
	    printbuf_memappend_fast(tok->pb, case_start, str-case_start);
	    goto out;
	  }
	}
      }
      break;

    case json_tokener_state_string_escape:
      switch(c) 
      {
      case '"':
      case '\\':
      case '/':
	printbuf_memappend_fast(tok->pb, &c, 1);
	state = saved_state;
	break;
      case 'b':
      case 'n':
      case 'r':
      case 't':
      case 'f':
	if(c == 'b') printbuf_memappend_fast(tok->pb, "\b", 1);
	else if(c == 'n') printbuf_memappend_fast(tok->pb, "\n", 1);
	else if(c == 'r') printbuf_memappend_fast(tok->pb, "\r", 1);
	else if(c == 't') printbuf_memappend_fast(tok->pb, "\t", 1);
	else if(c == 'f') printbuf_memappend_fast(tok->pb, "\f", 1);
	state = saved_state;
	break;
      case 'u':
	tok->ucs_char = 0;
	tok->st_pos = 0;
	state = json_tokener_state_escape_unicode;
	break;
      default:
	tok->err = json_tokener_error_parse_string;
	goto out;
      }
      break;

    case json_tokener_state_escape_unicode:
	{
          unsigned int got_hi_surrogate = 0;

	  while(1) 
          {
	    if (c && strchr(json_hex_chars, c)) 
            {
	      tok->ucs_char += ((unsigned int)jt_hexdigit(c) << ((3-tok->st_pos++)*4));
	      if(tok->st_pos == 4) 
              {
		unsigned char unescaped_utf[4];

                if (got_hi_surrogate) 
                {
		  if (IS_LOW_SURROGATE(tok->ucs_char)) 
                    tok->ucs_char = DECODE_SURROGATE_PAIR(got_hi_surrogate, tok->ucs_char);
                  else
		    printbuf_memappend_fast(tok->pb, (char*)utf8_replacement_char, 3);
                  got_hi_surrogate = 0;
                }

		if (tok->ucs_char < 0x80) 
                {
		  unescaped_utf[0] = tok->ucs_char;
		  printbuf_memappend_fast(tok->pb, (char*)unescaped_utf, 1);
		} 
                else if (tok->ucs_char < 0x800) 
                {
		  unescaped_utf[0] = 0xc0 | (tok->ucs_char >> 6);
		  unescaped_utf[1] = 0x80 | (tok->ucs_char & 0x3f);
		  printbuf_memappend_fast(tok->pb, (char*)unescaped_utf, 2);
		} 
                else if (IS_HIGH_SURROGATE(tok->ucs_char)) 
                {
                  got_hi_surrogate = tok->ucs_char;
                  if ((len == -1 || len > (tok->char_offset + 2)) &&
                      // str[0] != '0' &&  // implied by json_hex_chars, above.
                      (str[1] == '\\') &&
                      (str[2] == 'u'))
                  {
	            if( !ADVANCE_CHAR(str, tok) || !ADVANCE_CHAR(str, tok) ) {
                    printbuf_memappend_fast(tok->pb,
					    (char*) utf8_replacement_char, 3);
		    }
	            if (!ADVANCE_CHAR(str, tok) || !PEEK_CHAR(c, tok)) {
	              printbuf_memappend_fast(tok->pb,
					      (char*) utf8_replacement_char, 3);
	              goto out;
                    }
	            tok->ucs_char = 0;
                    tok->st_pos = 0;
                    continue;
                  } 
                  else 
                  {
		    printbuf_memappend_fast(tok->pb,
					    (char*) utf8_replacement_char, 3);
                  }
		} 
                else if (IS_LOW_SURROGATE(tok->ucs_char)) 
                {
		  printbuf_memappend_fast(tok->pb, (char*)utf8_replacement_char, 3);
                } 
                else if (tok->ucs_char < 0x10000) 
                {
		  unescaped_utf[0] = 0xe0 | (tok->ucs_char >> 12);
		  unescaped_utf[1] = 0x80 | ((tok->ucs_char >> 6) & 0x3f);
		  unescaped_utf[2] = 0x80 | (tok->ucs_char & 0x3f);
		  printbuf_memappend_fast(tok->pb, (char*)unescaped_utf, 3);
		} 
                else if (tok->ucs_char < 0x110000) 
                {
		  unescaped_utf[0] = 0xf0 | ((tok->ucs_char >> 18) & 0x07);
		  unescaped_utf[1] = 0x80 | ((tok->ucs_char >> 12) & 0x3f);
		  unescaped_utf[2] = 0x80 | ((tok->ucs_char >> 6) & 0x3f);
		  unescaped_utf[3] = 0x80 | (tok->ucs_char & 0x3f);
		  printbuf_memappend_fast(tok->pb, (char*)unescaped_utf, 4);
		} 
                else 
                {
		  printbuf_memappend_fast(tok->pb, (char*)utf8_replacement_char, 3);
                }
		state = saved_state;
		break;
	      }
	    } 
            else 
            {
	      tok->err = json_tokener_error_parse_string;
	      goto out;
	    }
	  if (!ADVANCE_CHAR(str, tok) || !PEEK_CHAR(c, tok)) 
          {
            if (got_hi_surrogate)
	      printbuf_memappend_fast(tok->pb, (char*)utf8_replacement_char, 3);
	    goto out;
	  }
	}
      }
      break;

    case json_tokener_state_boolean:
      {
	int size1, size2;
	printbuf_memappend_fast(tok->pb, &c, 1);
	size1 = json_min(tok->st_pos+1, json_true_str_len);
	size2 = json_min(tok->st_pos+1, json_false_str_len);
	if((!(tok->flags & JSON_TOKENER_STRICT) &&
	  strncasecmp(json_true_str, tok->pb->buf, size1) == 0)
	  || (strncmp(json_true_str, tok->pb->buf, size1) == 0)
	  ) 
        {
	  if(tok->st_pos == json_true_str_len) 
          {
	    current = json_object_new_boolean(1);
	    if(current == NULL)
		goto out;
	    saved_state = json_tokener_state_finish;
	    state = json_tokener_state_eatws;
	    goto redo_char;
	  }
	} 
        else if((!(tok->flags & JSON_TOKENER_STRICT) &&
	  strncasecmp(json_false_str, tok->pb->buf, size2) == 0)
	  || (strncmp(json_false_str, tok->pb->buf, size2) == 0)) 
        {
	  if(tok->st_pos == json_false_str_len) 
          {
	    current = json_object_new_boolean(0);
	    if(current == NULL)
		goto out;
	    saved_state = json_tokener_state_finish;
	    state = json_tokener_state_eatws;
	    goto redo_char;
	  }
	} 
        else 
        {
	  tok->err = json_tokener_error_parse_boolean;
	  goto out;
	}
	tok->st_pos++;
      }
      break;

    case json_tokener_state_number:
      {
	const char *case_start = str;
	int case_len=0;
	int is_exponent=0;
	int negativesign_next_possible_location=1;
	while(c && strchr(json_number_chars, c)) 
        {
	  ++case_len;

	  if (c == '.') {
	    if (tok->is_double != 0) 
            {
	      tok->err = json_tokener_error_parse_number;
	      goto out;
	    }
	    tok->is_double = 1;
	  }
	  if (c == 'e' || c == 'E') 
          {
	    if (is_exponent != 0) 
            {
	      tok->err = json_tokener_error_parse_number;
	      goto out;
	    }
	    is_exponent = 1;
	    tok->is_double = 1;
	    negativesign_next_possible_location = case_len + 1;
	  }
	  if (c == '-' && case_len != negativesign_next_possible_location) 
          {
	    tok->err = json_tokener_error_parse_number;
	    goto out;
	  }

	  if (!ADVANCE_CHAR(str, tok) || !PEEK_CHAR(c, tok)) 
          {
	    printbuf_memappend_fast(tok->pb, case_start, case_len);
	    goto out;
	  }
	}
        if (case_len>0)
          printbuf_memappend_fast(tok->pb, case_start, case_len);

	if (tok->pb->buf[0] == '-' && case_len <= 1 &&
	    (c == 'i' || c == 'I'))
	{
		state = json_tokener_state_inf;
		tok->st_pos = 0;
		goto redo_char;
	}
      }
      {
	int64_t num64;
	double  numd;
	if (!tok->is_double && json_parse_int64(tok->pb->buf, &num64) == 0) 
        {
		if (num64 && tok->pb->buf[0]=='0' &&
		    (tok->flags & JSON_TOKENER_STRICT)) 
                {
			tok->err = json_tokener_error_parse_number;
			goto out;
		}
		current = json_object_new_int64(num64);
		if(current == NULL)
		    goto out;
	}
	else if(tok->is_double && json_parse_double(tok->pb->buf, &numd) == 0)
	{
          current = json_object_new_double_s(numd, tok->pb->buf);
	  if(current == NULL)
		goto out;
        } 
        else 
        {
          tok->err = json_tokener_error_parse_number;
          goto out;
        }
        saved_state = json_tokener_state_finish;
        state = json_tokener_state_eatws;
        goto redo_char;
      }
      break;

    case json_tokener_state_array_after_sep:
    case json_tokener_state_array:
      if(c == ']') 
      {
	if (state == json_tokener_state_array_after_sep &&
	    (tok->flags & JSON_TOKENER_STRICT))
	  {
	    tok->err = json_tokener_error_parse_unexpected;
	    goto out;
	  }
	saved_state = json_tokener_state_finish;
	state = json_tokener_state_eatws;
      } 
      else 
      {
	if(tok->depth >= tok->max_depth-1) {
	  tok->err = json_tokener_error_depth;
	  goto out;
	}
	state = json_tokener_state_array_add;
	tok->depth++;
	json_tokener_reset_level(tok, tok->depth);
	goto redo_char;
      }
      break;

    case json_tokener_state_array_add:
      if( json_object_array_add(current, obj) != 0 )
        goto out;
      saved_state = json_tokener_state_array_sep;
      state = json_tokener_state_eatws;
      goto redo_char;

    case json_tokener_state_array_sep:
      if(c == ']') 
      {
	saved_state = json_tokener_state_finish;
	state = json_tokener_state_eatws;
      } 
      else if(c == ',') 
      {
	saved_state = json_tokener_state_array_after_sep;
	state = json_tokener_state_eatws;
      } 
      else 
      {
	tok->err = json_tokener_error_parse_array;
	goto out;
      }
      break;

    case json_tokener_state_object_field_start:
    case json_tokener_state_object_field_start_after_sep:
      if(c == '}') 
      {
		if (state == json_tokener_state_object_field_start_after_sep &&
		    (tok->flags & JSON_TOKENER_STRICT))
		{
			tok->err = json_tokener_error_parse_unexpected;
			goto out;
		}
	saved_state = json_tokener_state_finish;
	state = json_tokener_state_eatws;
      } 
      else if (c == '"' || c == '\'') 
      {
	tok->quote_char = c;
	printbuf_reset(tok->pb);
	state = json_tokener_state_object_field;
      } 
      else 
      {
	tok->err = json_tokener_error_parse_object_key_name;
	goto out;
      }
      break;

    case json_tokener_state_object_field:
      {
	const char *case_start = str;
	while(1) 
        {
	  if(c == tok->quote_char) 
          {
	    printbuf_memappend_fast(tok->pb, case_start, str-case_start);
	    obj_field_name = strdup(tok->pb->buf);
	    saved_state = json_tokener_state_object_field_end;
	    state = json_tokener_state_eatws;
	    break;
	  } 
          else if(c == '\\') 
          {
	    printbuf_memappend_fast(tok->pb, case_start, str-case_start);
	    saved_state = json_tokener_state_object_field;
	    state = json_tokener_state_string_escape;
	    break;
	  }
	  if (!ADVANCE_CHAR(str, tok) || !PEEK_CHAR(c, tok)) 
          {
	    printbuf_memappend_fast(tok->pb, case_start, str-case_start);
	    goto out;
	  }
	}
      }
      break;

    case json_tokener_state_object_field_end:
      if(c == ':') 
      {
	saved_state = json_tokener_state_object_value;
	state = json_tokener_state_eatws;
      } 
      else 
      {
	tok->err = json_tokener_error_parse_object_key_sep;
	goto out;
      }
      break;

    case json_tokener_state_object_value:
      if(tok->depth >= tok->max_depth-1) 
      {
	tok->err = json_tokener_error_depth;
	goto out;
      }
      state = json_tokener_state_object_value_add;
      tok->depth++;
      json_tokener_reset_level(tok, tok->depth);
      goto redo_char;

    case json_tokener_state_object_value_add:
      json_object_object_add(current, obj_field_name, obj);
      free(obj_field_name);
      obj_field_name = NULL;
      saved_state = json_tokener_state_object_sep;
      state = json_tokener_state_eatws;
      goto redo_char;

    case json_tokener_state_object_sep:
      if(c == '}') 
      {
	saved_state = json_tokener_state_finish;
	state = json_tokener_state_eatws;
      } 
      else if(c == ',') 
      {
	saved_state = json_tokener_state_object_field_start_after_sep;
	state = json_tokener_state_eatws;
      } 
      else 
      {
	tok->err = json_tokener_error_parse_object_value_sep;
	goto out;
      }
      break;

    }
    if (!ADVANCE_CHAR(str, tok))
      goto out;
  }

 out:
  if (c &&
     (state == json_tokener_state_finish) &&
     (tok->depth == 0) &&
     (tok->flags & JSON_TOKENER_STRICT)) 
  {
      tok->err = json_tokener_error_parse_unexpected;
  }
  if (!c) { 
    if(state != json_tokener_state_finish &&
       saved_state != json_tokener_state_finish)
      tok->err = json_tokener_error_parse_eof;
  }

  if (tok->err == json_tokener_success)
  {
    json_object *ret = json_object_get(current);
	int ii;

    for(ii = tok->depth; ii >= 0; ii--)
      json_tokener_reset_level(tok, ii);
    return ret;
  }

  return NULL;
}

*/
