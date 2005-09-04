/*      commands.c                                19.03.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 2004: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    command line functions
/
*/


/************************/
/*  include files       */
/************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "commands.h"
#include "memo_hnd.h"
#include "perform.h"
#include "err_mess.h"
#include "mb_ctype.h"
#include "history.h"
#include "disp_hnd.h"


/************************/
/* some defines         */
/************************/


/************************/
/* local structures     */
/************************/


/************************/
/*  module definitions  */
/************************/

/* -FF-  */

#if 0

Hinweis !!

Die deutschen Umlaute in diesem Source-File sind 
  - im Programm-Code als Hex-Werte, 
  - in Kommentaren mit normalen ASCII-Charactern (ae, usw...) 
dargestellt.

Grund: Der c-compiler auf dem os-9-rechner meckert ueber Umlaute im File.

#endif

int is_german (char byte1)
{
byte key;

/* returns 1, if byte1 is in "Ae Oe Ue ae oe ue ss", else 0 */

   key = (byte) byte1;

   switch (key)
   {
      case 0x8e: return 1; break;  /* Ae */
      case 0x99: return 1; break;  /* Oe */
      case 0x9a: return 1; break;  /* Ue */
      case 0x84: return 1; break;  /* ae */
      case 0x94: return 1; break;  /* oe */
      case 0x81: return 1; break;  /* ue */
      case 0xe1: return 1; break;  /* ss */

      default:   return 0; break;
   }

}  /* is_german */

/* -FF-  */

void comm_umlaut (char *buffer)
{
byte key;

/* convert chars "AOUaous" <--> "Ae Oe Ue ae oe ue ss" */

   key = (byte) *buffer;

   switch (key)
   {
   /* hin */
      case 'A':   *buffer = (char)0x8e; break;
      case 'O':   *buffer = (char)0x99; break;
      case 'U':   *buffer = (char)0x9a; break;
      case 'a':   *buffer = (char)0x84; break;
      case 'o':   *buffer = (char)0x94; break;
      case 'u':   *buffer = (char)0x81; break;
      case 's':   *buffer = (char)0xe1; break;

   /* und zurueck */
      case 0x8e:  *buffer = 'A';  break;
      case 0x99:  *buffer = 'O';  break;
      case 0x9a:  *buffer = 'U';  break;
      case 0x84:  *buffer = 'a';  break;
      case 0x94:  *buffer = 'o';  break;
      case 0x81:  *buffer = 'u';  break;
      case 0xe1:  *buffer = 's';  break;

      default: break;
   }
}  /* comm_umlaut */

/* -FF-  */

void lower_upper_umlaut (char *buffer, int up_flag)
{
byte key;

/* convert chars "Ae Oe Ue " <--> "ae oe ue " */

   key = (byte) *buffer;

   if (up_flag)
   {
      switch (key)
      {
         case 0x84:  *buffer = (char)0x8e;  break;  /* ae  --> Ae  */
         case 0x94:  *buffer = (char)0x99;  break;  /* oe  --> Oe  */
         case 0x81:  *buffer = (char)0x9a;  break;  /* ue  --> Ue  */
   
         default: break;
      }
   }
   else
   {
      switch (key)
      {
         case 0x8e:  *buffer = (char)0x84;  break;  /* Ae  --> ae  */
         case 0x99:  *buffer = (char)0x94;  break;  /* Oe  --> oe  */
         case 0x9a:  *buffer = (char)0x81;  break;  /* Ue  --> ue  */
   
         default: break;
      }
   }

}  /* lower_upper_umlaut */

/* -FF-  */

char tolower_german (char byte1)
{
char key;

/* convert all chars incl. "ae oe ue " to lower case */

   key = byte1;

   if (is_german (key))
      lower_upper_umlaut (&key, 0);
   else
      key = (char) tolower (key);  

   return key;

}  /* to_lower_german */

/* -FF-  */

char toupper_german (char byte1)
{
char key;

/* convert all chars incl. "ae oe ue " to upper case */

   key = byte1;

   if (is_german (key))
      lower_upper_umlaut (&key, 1);
   else
      key = (char) toupper (key);

   return key;

}  /* toupper_german */

/* -FF-  */

static char unchanged_char (char byte1)
{
   return byte1;
}  /* unchanged_char */

/* -FF-  */

int is_delimiter (char byte1)
{
/* Funktion gibt 1 zurueck, wenn der angegebene char ein delimiter ist. */

#if (WITH_E_DELIMIT)

char *c_ptr;

   if (isspace (byte1))
      return 1;

   for (c_ptr = fc->e_delimit ; *c_ptr ; c_ptr++)
   {
      if (byte1 == *c_ptr)
         return 1;
   }
   return 0;    /* nothing found */

#else

/* is character a letter, number or underscore ? */
   byte1 = (char) toupper (byte1);
   if (((byte1 >= 'A') && (byte1 <= 'Z')) ||
       ((byte1 >= '0') && (byte1 <= '9')) ||
        (byte1 == '_')                    ||
        (is_german(byte1)))
      return 0;
   else
      return 1;

#endif

}  /* is_delimiter */

/* -FF-  */

static int get_part_strings (char *text, int wild_cards)
{
/* no of partial strings in search string = no of '*'s plus 1 */

int count;

   count = 1;

   if (wild_cards)
   {
      while (*text)
      {
         if (*text == '*')
            count++;
         text++;
      }
   }

   return count;
}  /* get_part_strings */

/* -FF-  */

long comm_find (char FA_HU *buff, long index_1,
                long max_ind, char *such_string,
                int direction, int consider_case, int k_token,
                int wild_cards, size_t *len1)
{

/* Funktion sucht zwischen buff[index_1]...buff[max_ind] nach such_string, */
/* wenn erfolgreich, return new byte_index, sonst -1.                        */

#define TEST static
TEST int  found, pp, part_strings, exp_search;
TEST long ii, ianf, iend, d_ii, kk, i1, i2, i_limit;
TEST char FA_HU *abuf;
TEST char FA_HU *cbuf;
TEST char       *astr, *bstr;
TEST char       *ustr;
TEST size_t t_len, p_len, t_rest, p_rest;

STATIC char act_search [BUF_256];
char (*function)(char byte1);
#define ss_len *len1

#define WILDCARDS_HIGHSPEED 1


/* init */
   ss_len = strlen (such_string);
   t_len  = ss_len;

/* search with wild_cards: remove leading, trailing, and double '*'s */
   if (wild_cards)
   {
   /* remove leading '*'s */
      for (ii = 0 ; ii < (long) ss_len ; ii++)
      {
         if (*such_string == '*')
            memcpy (&such_string[0],
                    &such_string[1],
                    (ss_len - (size_t)ii));
         else
            break;
      }
      ss_len = strlen (such_string);

   /* remove trailing '*'s */
      for (ii = (((long)ss_len)-1) ; ii >= 0 ; ii--)
      {
         if (such_string[ii] == '*')
            such_string[ii] = '\0';
         else
            break;
      }
      ss_len = strlen (such_string);

   /* remove double '*'s */
      for (ii = 0 ; ii < (((long)ss_len)-1) ; ii++)
      {
         if ((such_string[ii  ] == '*') &&
             (such_string[ii+1] == '*'))
         {
            memcpy (&such_string[ii],
                    &such_string[ii+1],
                    (ss_len - (size_t)ii));
            ii--;
         }
      }
      ss_len = strlen (such_string);
   }  /* if wild_cards */

   if (ss_len == 0) return -1;                /* abort --> */

/* fallunterscheidung case sensitive or not */
   if (consider_case)
   {
      function = unchanged_char;

   /* uebernehmen suchstring 1:1 */
      strncpy (act_search, such_string, sizeof(act_search));
   }
   else
   {
      function = toupper_german;

   /* umsetzen suchstring --> upper case */
      astr = such_string;
      ustr = act_search;
      for (ii = 0 ; ii < sizeof(act_search) ; ii++)
      {
         *ustr = toupper_german (*astr);
         astr++;
         ustr++;
      }
   }
   act_search [sizeof(act_search) - 1] = '\0';    /* forced end of string */

/* anzahl teilstrings */
   part_strings = get_part_strings (act_search, wild_cards);

/* fallunterscheidung vor / zurueck suchen */
   if (direction)
   {                                       /* vorwaerts */
   /* aeussere schleife fuer buffer */
      ianf = index_1;
      iend = max_ind - (ss_len - (part_strings-1)) + 1;
      i_limit = max_ind;
      d_ii = 1;
      if (ianf >= iend) return -1;            /* abort --> */
   }
   else
   {                                       /* rueckwaerts */
   /* aeussere schleife fuer buffer */
      ianf = index_1 - (ss_len - (part_strings-1));
      iend = -1;
      i_limit = index_1;
      d_ii = -1;
      if (ianf <= iend) return -1;            /* abort --> */
   }

/* -FF-  */

/*---------------------------------------------------------------------------*/

/* suchschleife */
   found = 0;
   abuf  = &buff[ianf];

   for (ii = ianf ; ii != iend ; ii += d_ii)
   {
#if (WILDCARDS_HIGHSPEED)
   /* fallunterscheidung wg. speed */
      if (!wild_cards)
      {
      /* innere schleife fuer string */
         cbuf = abuf;
   
         astr = act_search;
         for (kk = 0 ; kk < (long) ss_len ; kk++)
         {
            if (*astr == function (*cbuf))     /* characters match */
            {
               astr++;
               cbuf++;
            }
            else
            {
               goto next_c1;  /* no match at this char */
            }
         }
      }
      else
#endif
      {
         cbuf   = abuf;
         bstr   = act_search;
         t_len  = 0;        /* total length and rest */
         t_rest = ss_len;
         exp_search = 0;
   
      /* schleife fuer teilstrings */
         for (pp = 0 ; pp < part_strings ; pp++)
         {
            astr   = bstr;
            p_len  = 0;      /* partial length and rest */
            p_rest = t_rest;
   
         /* innere schleife fuer string */
            for (kk = 0 ; kk < (long) p_rest ; kk++)
            {
#define BUGFIX_28_09_94  1
#if (BUGFIX_28_09_94)
                     if (*astr == '*')      /* NEU ! sonst probleme mit */
                     {                      /* text: r*.c               */
                        astr++;             /* such: r*.c               */
                        bstr = astr;
                        t_rest -= (p_len + 1);
                        exp_search = 1;   /* from now on */
                        break;   /* for kk */
                     }
                     else
#endif

               if (( *astr == function (*cbuf)) ||     /* characters match */
#if (WILDCARDS_HIGHSPEED)
                   (*astr == '?'))   /* or wild_card '?' */
#else
                   ((*astr == '?') && (wild_cards)))   /* or wild_card '?' */
                                /* ^^ kann entfallen !! */
#endif
               {
                  cbuf++;
                  p_len++;
                  astr++;
               }
               else
               {
#if (!WILDCARDS_HIGHSPEED)
                  if (!wild_cards)
                  { /* ^^ kann entfallen */
                     goto next_c1;
                  }
                  else
#endif
                  {
#if (!BUGFIX_28_09_94)
                     if (*astr == '*')
                     {
                        astr++;
                        bstr = astr;
                        t_rest -= (p_len + 1);
                        exp_search = 1;   /* from now on */
                        break;   /* for kk */
                     }
                     else
#endif
                     {
                        if ((perform_test_eol (cbuf, 0)) ||     /* end of line ? */
                            ((cbuf+p_rest) >= &buff[max_ind]))  /* end of text ? */
                        {
                           goto next_c1;                     /* stop search */
                        }
                        else
                        {
                           if (exp_search)
                           {                      /* expanded search mode */
                              if (astr == bstr)   /* NEU ! sonst probleme mit */
                              {                   /* text: DefaultSystemMenu  */
                                 cbuf++;          /* such: default*menu       */
                                 p_len++;
                              }
                              pp--;  /* one more try */
                              break;  /* for kk */
                           }
                           else
                           {
                              goto next_c1;
                           }
                        }  /* search not stopped */
                     }  /* != '*' */
                  }  /* wild_cards */
               }  /* if no match */
    
            }  /* for kk */
   
            t_len += p_len;
         }  /* for pp */
   
      /* found string inside range ? */
         if ((ii + (long)t_len) > i_limit)
            goto next_c1;  /* no: outside */
      }  /* wild_cards */
    
   /* string gefunden ! */
      if (!k_token)
      {
         found = 1;         /* o.k., abort search ! */
         break;    
      }
      else                  /* check, if token string ! */
      {
      /* char vor/hinter string */
         i1 = max (0L, (ii - 1));
         i2 = ii + t_len;

         if ((is_delimiter (buff[i1]) || (ii == 0L)) &&
             (is_delimiter (buff[i2])))
         {
            found = 1;
            break;
         }
      }

   next_c1:
      abuf += d_ii;
   }  /* for ii */

/* ii steht jetzt am anfang des gefundenen strings */
   if (direction)             /* vorwaerts-suche: */
      ii += t_len;       /* ende des strings */

/* ende suchvorgang */
   ss_len = t_len;
   if (found == 1)
      return ii;    /* act. zeiger */
   else
      return -1;    /* nothing found */

}  /* comm_find */

/* -FF-  */

#if (WITH_HEX_FIND)

long comm_find_byte (char FA_HU *buff, long index_1,
                     long max_ind, char byte_1, char byte_2)
{

/* Funktion sucht zwischen buff[index_1]...buff[max_ind] nach byte_1, */
/* wenn erfolgreich, return new byte_index, sonst -1.                   */

long index_0;
char FA_HU *buff_1;

   buff_1 = &buff[index_1];
   for (index_0 = index_1 ; index_0 < max_ind ; index_0++)
   {
   /* type cast (unsigned char) fuer z.B. 'H'ex 'F'ind "7e ff" */
      if (((unsigned char)(*buff_1) >= (unsigned char)(byte_1)) &&
          ((unsigned char)(*buff_1) <= (unsigned char)(byte_2)))
         return (index_0 + 1);
      buff_1++;
   }

   return -1;    /* nothing found */

}  /* comm_find_byte */

#endif

/* -FF-  */

long comm_lower_upper (char FA_HU *buff, long index_1,
                       long max_ind, int up_flag)
{

/* Funktion sucht zwischen buff[index_1]...buff[max_ind] nach dem 1. char, */
/* der kein delimiter ist, und ersetzt dann alle char mit tolower/toupper    */
/* bis zum 1. auftreten eines delimiters */

long ii, i1, i2;
char *abuf;

/* init */
   i1 = 0x7fffffff;
   i2 = -1;

/* search for start of next word */
   abuf = &buff[index_1];
   for (ii = index_1 ; ii < max_ind ; ii++)    /* excl. EOF !! */
   {
      if (!is_delimiter (*abuf))
      {
         i1 = ii;
         break;
      }
      abuf++;
   }

/* search for end of next word */
   abuf = &buff[i1];
   for (ii = i1 ; ii <= max_ind ; ii++)        /* incl. EOF !! */
   {
      if (is_delimiter (*abuf))
      {
         i2 = ii;
         break;
      }
      abuf++;
   }

/* found a valid string ? */
   if (i2 <= i1)
   {                        /* no */
      return -1;            /* return 'invalid' */
   }
   else
   {                        /* yes, convert all characters in between */
      abuf = &buff[i1];
      for (ii = i1 ; ii < i2 ; ii++)
      {
         if (is_german (*abuf))
         {
            lower_upper_umlaut (abuf, up_flag);
         }
         else
         {
            if (up_flag)
               *abuf = (char) toupper (*abuf);
            else
               *abuf = (char) tolower (*abuf);
         }

         abuf++;
      }
      return i2;            /* return new pointer */
   }

}  /* comm_lower_upper */

/* -FF-  */

int is_string_character (char FA_HU *buff, long index, long max_index)
{
/* check for string characters:
    "   yes
    \"  no

    '   yes, if delimiter before or behind (avoid Ada "ticks", e.g. Float'Image)
    \'  no ,       "
    \\' yes,       "
*/

    if  (
            (buff[        index    ] == '\"') &&
            (buff[max(0, (index-1))] != '\\')
        )
        return 1;    /* " */


    if (has_single_quote_string())
    {
        if  (
            (   buff[        index    ] == '\'') &&
                (
                    (buff[max(0, (index-1))] != '\\') ||
                    (buff[max(0, (index-2))] == '\\')
                ) &&
                (
                    (is_delimiter(buff[max(0, (index-1))])) ||    /* disable Ada ticks,    */
                    (is_delimiter(buff[       (index+1) ])) ||    /* e.g.: field'last      */
                    (buff[max(0        , (index-2))] == '\'') ||  /* enable short strings, */
                    (buff[min(max_index, (index+2))] == '\'')     /* e.g.: 'C'alc          */
                )
            )
            return 2;    /* ' */
    }


    return 0;       /* none */

}  /* is_string_character */

/* -FF-  */

static int is_visible_token (char FA_HU *buff, long start_index, long max_index,
                             int first, int direction)
{
/* check, if the found token is visible, i.e.: 
   a) not inside a string
   b) not inside a comment
*/

   return (!is_inside_string_or_comment (buff, start_index, max_index, first, direction));

}  /* is_visible_token */

/* -FF-  */

static char *get_strtok (char FA_HU *buff, long index_1, long max_ind, int direction,
                         int *start_ind)
{
/* isolate the token string around the actual index */

static char token[BUF_256];
int new_delim, old_delim;
int ii, i1, i2, len;


/* default */
   i1 = index_1;
   i2 = -1;
   

/* begin of token */
   old_delim = is_delimiter(buff[i1]);

   if (direction == -1)
   {
      for (ii = index_1 ; ii >= 0 ; ii--)   /* search backward */
      {
         new_delim = is_delimiter(buff[ii]);
         if (new_delim && !old_delim)
         {
            i1 = ii+1;      /* ii is the character before the token */
            break;
         } 
         old_delim = new_delim;
      }  /* for ii */
   }
   else
   {
      for (ii = index_1 ; ii <= max_ind ; ii++)   /* search forward */
      {
         new_delim = is_delimiter(buff[ii]);
         if (!new_delim)
         {
            i1 = ii;        /* this is the 1st character of the token */
            break;
         } 
      }  /* for ii */
   }


/* search end of token */
   old_delim = is_delimiter(buff[i1]);

   for (ii = i1+1 ; ii <= max_ind ; ii++)   /* search forward */
   {
      new_delim = is_delimiter(buff[ii]);
      if (new_delim && !old_delim)
      {
         i2 = ii;        /* this is 1 character behind the token */
         break;
      }
      old_delim = new_delim;
   }  /* for ii */


/* found valid token ? */
   if (i2 == -1)
   {
      return NULL;  /* no */
   }
   else
   {
      len = min((i2-i1), sizeof(token)-1);
      strncpy (token, &buff[i1], len);  /* yes */
      token[len] = '\0';
      *start_ind = i1;
      return token;
   }

}  /* get_strtok */

/* -FF-  */

long comm_ctrl_k (char FA_HU *buff, long index_1, long max_ind)
{

/* Funktion sucht zwischen buff[index_1]...buff[max_ind] nach der   */
/* korrespondierenden klammer. (){}[]                                 */
/* NEU ! Zusaetzlich zu den Klammern auch: #if <--> #else <--> #endif */

long ii, i1, i2;
int  level, start_level, start_ind, offset;
char found, klammer1 = 0, klammer2 = 0;

static int  direction, start_index;
static char *string_c [] =   { "#if",
                               "#else",
                               "#elif",
                               "#endif"
                             }; 

static char *string_ada1[] = { "if",
                               "else",
                               "elsif",
                               "end if"
                             }; 


static char end_string[] = {"end"};
static char *string_ptr;
static char token_string[BUF_256];



/* init direction on 1st run */
   if (direction == 0)
      direction = 1;

   start_level = 0;
   offset = 0;

/* suche nach erster klammer ueberhaupt */
/* NEW ! Check only the actual cursor position */
   found = 0;
   for (ii = index_1 ; ii <= index_1  /* ii < max_ind */ ; ii++)
   {
      if (is_visible_token(buff, ii, max_ind, 1, direction))
      {
      /* case 1 */
         if ((buff[ii] == '(') ||
             (buff[ii] == ')') ||
             (buff[ii] == '{') ||
             (buff[ii] == '}') ||
             (buff[ii] == '[') ||
             (buff[ii] == ']') ||
             (buff[ii] == '<') ||
             (buff[ii] == '>'))
         {
            klammer1 = buff[ii];
            found = 1;
            break;
         }

      /* case 2 */
         if (ii <= (max_ind - (long)strlen(string_c[3])))     /* strlen ("#endif") */
         {
            if ((strncmp(&buff[ii], string_c[0], strlen(string_c[0])) == 0) ||
                (strncmp(&buff[ii], string_c[1], strlen(string_c[1])) == 0) ||
                (strncmp(&buff[ii], string_c[2], strlen(string_c[2])) == 0) ||
                (strncmp(&buff[ii], string_c[3], strlen(string_c[3])) == 0))
            {
               klammer1 = buff[ii+2];   /* 'f', 'l' or 'n' */
               found = 2;
               break;
            }
         }

      /* case 3 */
         if (ii <= (max_ind - (long)strlen(string_ada1[3])))  /* strlen ("end if") */
         {
            if ((strnicmp(&buff[ii], string_ada1[0], strlen(string_ada1[0])) == 0) ||
                (strnicmp(&buff[ii], string_ada1[1], strlen(string_ada1[1])) == 0) ||
                (strnicmp(&buff[ii], string_ada1[2], strlen(string_ada1[2])) == 0) ||
                (strnicmp(&buff[ii], string_ada1[3], strlen(string_ada1[3])) == 0))
            {
               klammer1 = buff[ii+1];   /* 'f', 'l' or 'n' */
               found = 3;
               break;
            }
         }


      /* case 4 */
         string_ptr = get_strtok(buff, ii, max_ind, -1, &start_ind);

         if (string_ptr)
         {
            if (strnicmp(string_ptr, end_string, strlen(end_string)) != 0)
            {
               klammer1 = 'f';           /* "<token>" */
               found = 4;
               strncpy (token_string, string_ptr, sizeof(token_string));
               ii = start_ind;
               break;
            }
            else
            {
               string_ptr = get_strtok(buff, (start_ind + strlen(end_string)), max_ind, 1, &start_ind);
               if (string_ptr)
               {
                  klammer1 = 'n';           /* "e(n)d <token>" */
                  found = 4;
                  strncpy (token_string, string_ptr, sizeof(token_string));
                  start_level = -1;
                  break;
               }
            }
         }  /* if string_ptr */
      }  /* if is_visible_token */
   }  /* for ii */

   if (found == 0)
   {
      err_message (NO_CORRESPONDING_BRACKET);
      return index_1;    /* nix gefunden */
   }

/* ------------------------------------------------------------------- */

/* welche klammer war's denn ? */
   if ((klammer1 == '(') ||
       (klammer1 == '{') ||
       (klammer1 == '[') ||
       (klammer1 == '<') ||
       (klammer1 == 'f'))
   {
      direction = 1;
   }
   else
   {
      if (klammer1 != 'l')     /* special case "#else": keep old direction */
         direction = -1;
   }

   if (direction == 1)
   {
      i1 = ii;
      i2 = max_ind;

   /* ggf. suchbereich reduzieren */
      if (found == 2)
         i2 -= (strlen(string_c[3]   ) - 1);   /* "#endif" */

      if (found == 3)
         i2 -= (strlen(string_ada1[3]) - 1);   /* "end if" */

      if (found == 4)
         i2 -= (strlen(string_ptr)     - 1);   /* "loop" */
   }
   else
   {
      i1 = ii;
      i2 = -1;
   }

/* bestimme klammer2 */
   if (klammer1 == '(') klammer2 = ')';
   if (klammer1 == ')') klammer2 = '(';

   if (klammer1 == '{') klammer2 = '}';
   if (klammer1 == '}') klammer2 = '{';

   if (klammer1 == '[') klammer2 = ']';
   if (klammer1 == ']') klammer2 = '[';

   if (klammer1 == '<') klammer2 = '>';
   if (klammer1 == '>') klammer2 = '<';

/* ------------------------------------------------------------------- */

/* search corresponding bracket */
   level = start_level;
   for (ii = i1 ; ii != i2 ; ii += direction)
   {
      if (is_visible_token(buff, ii, max_ind, 0, direction))
      {
         switch (found)
         {
         case 1:
            if (buff[ii] == klammer1) level++;
            if (buff[ii] == klammer2) level--;
            break;

         case 2:
            if  (strncmp(&buff[ii], string_c[0], strlen(string_c[0])) == 0) level++;  /* == #if    */
            if  (strncmp(&buff[ii], string_c[3], strlen(string_c[3])) == 0) level--;  /* == #endif */
   
            if ((strncmp(&buff[ii], string_c[1], strlen(string_c[1])) == 0) ||        /* == #else  */
                (strncmp(&buff[ii], string_c[2], strlen(string_c[2])) == 0))          /* == #elif  */
            {
               if (level == direction) 
                  return ii;    /* gefunden !! */

               if (level == 0)
                  level = direction;
            }
            break;

         case 3:
            if (is_delimiter(buff[max(0, (ii - 1))]))
            {
                if ((     strnicmp(&buff[ii], string_ada1[3], strlen(string_ada1[3])) == 0) &&  /* == end if */
                    is_delimiter(buff[min(max_ind, (ii + (int)strlen(string_ada1[3])))]))
                {
                   level--;
                }
                else if(((strnicmp(&buff[ii], string_ada1[1], strlen(string_ada1[1])) == 0) &&  /* == else   */
                    is_delimiter(buff[min(max_ind, (ii + (int)strlen(string_ada1[1])))])) ||
                        ((strnicmp(&buff[ii], string_ada1[2], strlen(string_ada1[2])) == 0) &&  /* == elsif  */
                    is_delimiter(buff[min(max_ind, (ii + (int)strlen(string_ada1[2])))])))
                {
                   if (level == direction) 
                      return ii;    /* gefunden !! */

                   if (level == 0)
                      level = direction;
                }
                else if ((strnicmp(&buff[ii], string_ada1[0], strlen(string_ada1[0])) == 0) &&  /* == if     */
                (strnicmp(&buff[max(0,ii-4)], string_ada1[3], strlen(string_ada1[3])) != 0) &&  /* != end if */
                    is_delimiter(buff[min(max_ind, (ii + (int)strlen(string_ada1[0])))]))
                {
                   level++;
                }
            }
            break;

         case 4:
            if ((strnicmp(&buff[ii], token_string, strlen(token_string)) == 0)     &&  /* is buff found ? */
                is_delimiter(buff[max(0      , (ii - 1))                        ]) &&  /* is found buff a delimited token ? */
                is_delimiter(buff[min(max_ind, (ii + (int)strlen(token_string)))]))
            {
               string_ptr = get_strtok(buff, (ii - strlen(end_string)), max_ind, -1, &start_ind);
               if (string_ptr)
               {
                  if (strnicmp(string_ptr, end_string, strlen(end_string)) == 0)
                  {
                     offset = (ii - start_ind);   /* point to begin of "end xxxx" */
                     level--;
                  }
                  else
                  {
                     offset = 0;
                     level++;
                  }
               }
            }
            break;
       
         default:
            break;
         }  /* switch found */
      }  /* if is_visible_token */

      if (level == 0) return (ii - offset);    /* gefunden !! */
   }  /* for ii */

/* no match */
   err_message (NO_CORRESPONDING_BRACKET);
   return index_1;    /* nix gefunden */

}  /* comm_ctrl_k */

/* -FF-  */

int parse_input_string (char *string)
{
/* Command "Quit/Init" erhaelt als kommando-string:
   entweder : "filename"
   oder     : "filename vo"   (view_only)

   Dieser string wird hier in seine Bestandteile (1 oder 2) zerlegt:

   Der filename wird im input-string begrenzt (durch setzen von '\0'),
   die option wird als return value uebergeben.
*/

int ii, view_only;

   view_only = 0;  /* default */

/* analyze input_string */

#if (ACT_OP_SYSTEM != WIN_32)

   for (ii = 0 ; ii < BUF_256 ; ii++)
   {
      if (*string == 0) break;  /* reached end of string */

   /* end of filename ? */
      if (isspace(*string))
      {
         *string = '\0';          /* mark end of filename */
         string++;
         break;
      }

   /* next char */
      string++;
   }

/* look for "VO" */
   for (ii = 0 ; ii < BUF_256 ; ii++)
   {
      if (*string == '\0') break;  /* reached end of string */

   /* begin of option ? */
      if ((stricmp (string, "vo")       == 0) ||
          (stricmp (string, "viewonly") == 0))
      {
         view_only = 1;
         break;
      }

   /* next char */
      string++;
   }

#else /* !WIN_32 */

   while (*string == ' ')   /* remove leading spaces */
   {
     strcpy(string, string+1);
   }
   
   ii = strlen(string)-1;

   while (ii)   /* remove trailing spaces */
   {
     if (isspace(string[ii]))
     {
       string[ii] = '\0';
       ii--;
     }
     else
       break;
   }
   
   while (ii)   /* scan for last word */
   {
     if (isspace(string[ii]))
     {
       /* look for "VO" */
       /* the very first word may be "vo"/"viewonly", so
          we can edit files of that name */
       if ((stricmp (string+ii+1, "vo")       == 0) ||
           (stricmp (string+ii+1, "viewonly") == 0))
       {
         view_only = 1;
         string[ii] = '\0';
       }
       break;
     }
     else
       ii--;
   }

#endif
   
   return view_only;

}  /* parse_input_string */

/* -FF-  */

int string_with_eol (char *string)
{
/* check, if there is any <EOL> inside the string */

   while (*string)
   {
      if (perform_test_eol (string, 0)) return 1;
      string++;
   }

   return 0;
}  /* string_with_eol */

/* -FF-  */

#if HELP_COMMAND_DIRECT

int get_current_string (char FA_HU *buff, long index_1,
                        long max_ind, char *result)
{

/* Funktion sucht ab buff[index_1] rueckwaerts nach dem start diesen topic, */
/* dann bis max. max_ind nach dem ende des topics, und kopiert alle char     */
/* dazwischen nach result. */
/* return value : anzahl der kopierten char, bzw. -1 im fehlerfall */

long ii, i1, i2;
char *abuf;

/* init */
   i1 = index_1;
   i2 = index_1;

/* search for next word to left */
   abuf = &buff[index_1];
   for (ii = index_1 ; ii >= 0 ; ii--)    /* rueckwaerts ! */
   {
      i1 = ii;
      if (!is_delimiter (*abuf))
         break;

      abuf--;
   }

/* search for start of this word */
   abuf = &buff[i1];
   for (ii = i1 ; ii >= 0 ; ii--)    /* rueckwaerts ! */
   {
      if (is_delimiter (*abuf))
         break;

      i1 = ii;
      abuf--;
   }
/* i1 is 1.st char of word */

/* search for end of this word */
   abuf = &buff[i1];
   for (ii = i1 ; ii <= max_ind ; ii++)        /* incl. EOF !! */
   {
      i2 = ii;
      if (is_delimiter (*abuf))
         break;

      abuf++;
   }
/* i2 is 1.st char behind (!) word */

/* found a valid string ? */
   if (i2 <= i1)
   {                        /* no */
      return -1;            /* return 'invalid' */
   }
   else
   {                        /* yes, convert all characters in between */
      abuf = &buff[i1];
      i2 = min (i2, (i1 + BUF_256 - strlen (HELP_COMMAND) - 1));  /* limit ! */
      for (ii = i1 ; ii < i2 ; ii++)
      {
         result [ii-i1] = *abuf;
         abuf++;
      }
      result [i2-i1] = '\0';   /* end of string */

      return (int)(i2-i1);
   }

}  /* get_current_string */

#endif

/* -FF-  */

/* Modification History */
/* 29.11.92 - file erzeugt */
/* 01.12.92 - comm_find () */
/* 03.12.92 - comm_ctrl_k */
/* 08.12.92 - parse_input_string () */
/* 09.12.92 - string_with_lf () */
/* 10.12.92 - is_german (), lower_upper_umlaut () */
/* 19.12.92 - FA_HU (far / huge) */
/* 21.12.92 - EOL */
/* 30.12.92 - get_current_string () */
/* 04.01.93 - tolower_german () */
/* 28.07.93 - HELP_COMMAND wieder als macro */
/* 28.07.93 - EOL --> EOLN */
/* 28.08.93 - STATIC */
/* 05.09.93 - Find mit Wildcard: '?' */
/* 08.09.93 - Find mit Wildcard: '*' */
/* 10.10.93 - bugfix: S*Y, Find:"*" */
/* 07.11.93 - ^K: nothing found --> err_message () */
/* 29.11.93 - mb_ctype.h */
/* 11.03.94 - comm_find (): verbessertes verhalten bei wildcard-suche */
/* 04.07.94 - WITH_E_DELIMIT */
/* 18.09.94 - long comm_ctrl_k(): #if <--> #else <--> #endif */
#if 0
         if (strcmp(&buff[ii], string[0]) == 0) level++;
commands.c(712) : fatal error C1001: Internal Compiler Error
        (compiler file '../grammar.c', line 91)
        Contact Microsoft Technical Support

         if (strcmp(string[0], &buff[ii]) == 0) level++;
                alles o.k.
#endif
/* 27.09.94 - type cast(s) wg. compiler warnings (microsoft c 6.0) */
/* 28.09.94 - bugfix: comm_find(): text   "r*.c",                */
/*                                 search "r*.c", S*Y, not found */
/* 29.09.94 - bugfix: comm_find(): with wild_cards: segmentation violation, */
/*                                 stop searching at end of text buffer     */
/* 30.09.94 - is_delimiter(): speed up */
/* 26.01.96 - comm_find_byte() */
/* 31.01.96 - WITH_HEX_FIND */
/* 04.03.99 - corresponding brackets '<' and '>' (e.g. for HTML code) */
/* 22.06.99 - comm_find_byte(): bugfix (unsigned char) for 'H'ex 'F'ind */
/* 14.11.02 - comm_ctrl_k(): #elif */
/* 16.04.03 - comm_ctrl_k(): ada: ^K: if, else, elsif, end if */
/* 16.04.03 - comm_ctrl_k(): ada: ^K: loop, end loop */
/* 24.04.03 - comm_ctrl_k(): ada: ^K: xxxx, end xxxx (any token) */
/* 25.04.03 - comm_ctrl_k(): ada: ^K: ignore token xxxx, if inside comment or string */
/* 28.04.03 - comm_ctrl_k(): correct handling of comments and strings */
/* 07.05.03 - handle nested strings, e.g. "...'..." */
/* 08.05.03 - disable Ada ticks, enable short strings */
/* 11.05.03 - ^K: Ada identifier "xxxx" and "end xxxx" with white space */
/* 12.05.03 - ^K: Ada identifier "xxxx" with delimiter before and behind */
/* 11.09.03 - ^K: Ada "if, else, end if": with delimiter before and behind */
/* 15.09.03 - bugfix: ^K: Ada, nested "if, end if" */
/* 02.11.03 - Visual Basic uses single quote for comments, not strings */
/* 13.03.04 - disp_hnd.c: modifications for CSS (dashes in keywords) */
/* 18.03.04 - disp_hnd.c: bugfix comments inside strings */
/* 19.03.04 - disp_hnd.c: bugfix of previous bugfix */
