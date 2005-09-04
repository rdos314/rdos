/*      macro.c                                     13.03.04       */
/*
/  --------------------------------------------------------------
/  Copyright (C) 2004: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    macro handler fuer mbedit.c
/
*/


/************************/
/*  include files       */
/************************/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "macro.h"
#include "mbedit.h"
#include "perform.h"
#include "kb_input.h"
#include "mon_outp.h"
#include "history.h"
#include "disp_hnd.h"
#include "err_mess.h"
#include "memo_hnd.h"
#include "mb_ctype.h"
#include "mousec.h"
#include "ansi_out.h"


/************************/
/* some defines         */
/************************/

#define MAC_TEST     0
#define TEST_TABLES  0

/* use macro names case sensitive ? (AEDIT: yes !) */

#define MACRO_NAME_IGNORE_CASE 1

#if MACRO_NAME_IGNORE_CASE
#define namcmp stricmp
#else
#define namcmp strcmp
#endif


/************************/
/* local structures     */
/************************/



/************************/
/*  module definitions  */
/************************/

#if (ACT_OP_SYSTEM == MS_DOS)
#define MACRO_FILE_NO  4   /* wg. Speicherplatz */
#else
#define MACRO_FILE_NO  8
#endif

static char macro_filename [MACRO_FILE_NO][BUF_256];  /* last macro filename */
static int  macro_level    [MACRO_FILE_NO];
static int mac_count  = -1;
static int incl_level =  0;
#define MAC_ACT_IND (max(0,mac_count) % MACRO_FILE_NO)

struct KEY_TAB {int   key;
                char *string;
               };

static const struct KEY_TAB key_tab [] = {
                                     /* functions keys <F1>...<F10> */
               KEY_F1    , "\\090",
               KEY_F2    , "\\091",
               KEY_F3    , "\\092",
               KEY_F4    , "\\093",
               KEY_F5    , "\\094",
               KEY_F6    , "\\095",
               KEY_F7    , "\\096",
               KEY_F8    , "\\097",
               KEY_F9    , "\\098",
               KEY_F10   , "\\099",
                                     /* SHIFT function keys */
               SHIFT_F1  , "\\0A0",
               SHIFT_F2  , "\\0A1",
               SHIFT_F3  , "\\0A2",
               SHIFT_F4  , "\\0A3",
               SHIFT_F5  , "\\0A4",
               SHIFT_F6  , "\\0A5",
               SHIFT_F7  , "\\0A6",
               SHIFT_F8  , "\\0A7",
               SHIFT_F9  , "\\0A8",
               SHIFT_F10,  "\\0A9",
                                     /* CTRL function keys */
               CTRL_F1   , "\\0B0",
               CTRL_F2   , "\\0B1",
               CTRL_F3   , "\\0B2",
               CTRL_F4   , "\\0B3",
               CTRL_F5   , "\\0B4",
               CTRL_F6   , "\\0B5",
               CTRL_F7   , "\\0B6",
               CTRL_F8   , "\\0B7",
               CTRL_F9   , "\\0B8",
               CTRL_F10  , "\\0B9",
                                     /* ALT function keys */
               ALT_F1    , "\\0C0",
               ALT_F2    , "\\0C1",
               ALT_F3    , "\\0C2",
               ALT_F4    , "\\0C3",
               ALT_F5    , "\\0C4",
               ALT_F6    , "\\0C5",
               ALT_F7    , "\\0C6",
               ALT_F8    , "\\0C7",
               ALT_F9    , "\\0C8",
               ALT_F10   , "\\0C9",
                                     /* cursor keys */
               KEY_UP    , "\\CU" ,
               KEY_DOWN  , "\\CD" ,
               KEY_RIGHT , "\\CR" ,
               KEY_LEFT  , "\\CL" ,

               KEY_HOME  , "\\CH" ,
               KEY_INS   , "\\083",
               KEY_DEL   , "\\XF" ,
               KEY_END   , "\\081",
               KEY_PGUP  , "\\080",
               KEY_PGDN  , "\\082",

                                     /* control cursor keys */
               CTRL_PGUP , "\\089",
               CTRL_HOME , "\\088",
               CTRL_PGDN , "\\087",
               CTRL_END  , "\\086",
               CTRL_RIGHT, "\\085",
               CTRL_LEFT , "\\084",

                                     /* control keys */
                                     /* ^@ (no translation) */
               0x01      , "\\XA" ,  /* ^A */
               0x02      , "\\002",  /* ^B */
                                     /* ^C (no translation) */
               0x04      , "\\004",  /* ^D */
               0x05      , "\\XE" ,  /* ^E */
               0x06      , "\\XF" ,  /* ^F */
               0x07      , "\\007",  /* ^G */
               0x08      , "\\RB" ,  /* ^H <backspace> */
               0x09      , "\\TB" ,  /* ^I <tab> */
               0x0a      , "\\00A",  /* ^J <lf> (vorher "\\0A") */
               0x0b      , "\\00B",  /* ^K */
               0x0c      , "\\00C",  /* ^L */
               0x0d      , "\\00D",  /* ^M <cr> (vorher "\\0D") */
               EOLN_INIT , "\\NL" ,  /* <cr><lf> (0x0d0a) */
               0x0e      , "\\XN" ,  /* ^N */
               0x0f      , "\\00F",  /* ^O */
               0x10      , "\\010",  /* ^P */
               0x11      , "\\011",  /* ^Q */
               0x12      , "\\XH" ,  /* ^R */
               0x13      , "\\XS" ,  /* ^S */
               0x14      , "\\CR" ,  /* ^T */
               0x15      , "\\XU" ,  /* ^U */
               0x16      , "\\016",  /* ^V */
               0x17      , "\\017",  /* ^W */
               0x18      , "\\XX" ,  /* ^X */
               0x19      , "\\019",  /* ^Y */
               0x1a      , "\\XZ" ,  /* ^Z */
               0x1b      , "\\BR" ,  /* ^[ <esc> */
               0x1c      , "\\CD" ,  /* ^\ */
               0x1d      , "\\CH" ,  /* ^] */
               0x1e      , "\\CU" ,  /* ^^ */
               0x1f      , "\\CL" ,  /* ^_ */

               0x5c      , "\\\\" ,  /* '\' <backslash> */

#if (ACT_OP_SYSTEM == SCO_UNIX)
               0x7f      , "\\XF" ,  /* statt KEY_DEL */
#else
               0x7f      , "\\RB" ,  /* Rubout */
#endif

               SEQU_MM   , "\\MM" ,  /* end   of sequence */
               SEQU_EM   , "\\EM" ,  /* end   of sequence */
               COMM_STT  , "\\*"  ,  /* start of comment  */

/* ab hier Erweiterung zu AEDIT */ 
                                     /* CTRL  diverse keys */
               CTRL_2    , "\\0D@",  /* CTRL 2 */

                                     /* ALT diverse keys */
               ALT_1     , "\\0D1",  /* ALT 1 */
               ALT_2     , "\\0D2",  /* ALT 2 */
               ALT_3     , "\\0D3",  /* ALT 3 */
               ALT_4     , "\\0D4",  /* ALT 4 */
               ALT_5     , "\\0D5",  /* ALT 5 */
               ALT_6     , "\\0D6",  /* ALT 6 */
               ALT_7     , "\\0D7",  /* ALT 7 */
               ALT_8     , "\\0D8",  /* ALT 8 */
               ALT_9     , "\\0D9",  /* ALT 9 */
               ALT_0     , "\\0D0",  /* ALT 0 */
               ALT_MIN   , "\\0DM",  /* ALT - */
               ALT_EQU   , "\\0DE",  /* ALT = */

                                     /* ALT alpha keys */
               ALT_A     , "\\0EA",  /* ALT A */
               ALT_B     , "\\0EB",  /* ALT B */
               ALT_C     , "\\0EC",  /* ALT C */
               ALT_D     , "\\0ED",  /* ALT D */
               ALT_E     , "\\0EE",  /* ALT E */
               ALT_F     , "\\0EF",  /* ALT F */
               ALT_G     , "\\0EG",  /* ALT G */
               ALT_H     , "\\0EH",  /* ALT H */
               ALT_I     , "\\0EI",  /* ALT I */
               ALT_J     , "\\0EJ",  /* ALT J */
               ALT_K     , "\\0EK",  /* ALT K */
               ALT_L     , "\\0EL",  /* ALT L */
               ALT_M     , "\\0EM",  /* ALT M */
               ALT_N     , "\\0EN",  /* ALT N */
               ALT_O     , "\\0EO",  /* ALT O */
               ALT_P     , "\\0EP",  /* ALT P */
               ALT_Q     , "\\0EQ",  /* ALT Q */
               ALT_R     , "\\0ER",  /* ALT R */
               ALT_S     , "\\0ES",  /* ALT S */
               ALT_T     , "\\0ET",  /* ALT T */
               ALT_U     , "\\0EU",  /* ALT U */
               ALT_V     , "\\0EV",  /* ALT V */
               ALT_W     , "\\0EW",  /* ALT W */
               ALT_X     , "\\0EX",  /* ALT X */
               ALT_Y     , "\\0EY",  /* ALT Y */
               ALT_Z     , "\\0EZ"   /* ALT Z */
              };

/* -FF-  */

static struct MACRO * top_of_macros;

static int stack_index;
static int macro_aborted;
static struct MACRO_STACK macro_stack [MAX_STACK_NUM];

/* -FF-  */

int start_index (int len)
{
/* calculates the biggest power of 2 below len */

int ii;

   len--;  /* reduce by one */

   for (ii = 0 ; ii < 16 ; ii++)
   {
      if (len == 1)          /* found left most set bit ? */
         return (1 << ii);

      len >>= 1;             /* shift right 1 bit */
   }  /* for ii */

   return 0;                 /* never reached ! */
}  /* start_index */

/* -FF-  */

#if (MACRO_TUNING)

/*
   The translation from macro string <--> key was done by a sequential
   search in the list key_tab (array of structures).

   For high speed operating, the list is copied into two sorted lists,
   one sorted by key, one sorted by string. The search for the correct
   entry is now done by successive approximation. That means: max. 8
   iterations now instead of 130 before.
*/

static struct KEY_TAB sorted_by_key    [lengthof(key_tab)];
static struct KEY_TAB sorted_by_string [lengthof(key_tab)];
static int start_index0;


static void drop_double_entries (void)
{
int ii, key0, key1;
char *string0, *string1;

   for (ii = 1 ; ii < lengthof(key_tab) ; ii++)
   {
      key0    = sorted_by_string[ii-1].key; 
      string0 = sorted_by_string[ii-1].string; 

      key1    = sorted_by_string[ii  ].key; 
      string1 = sorted_by_string[ii  ].string; 

      if (stricmp (string0, string1) == 0)
      {
         if (key0 < key1)
            sorted_by_string[ii  ].key = key0;
         else
            sorted_by_string[ii-1].key = key1;
      }
   }  /* for ii */
   
}  /* drop_double_entries */


#if (TEST_TABLES)

static void test_tables (void)
{
int ii, key0, key1, key2;
char *string0, *string1, *string2;

   printf ("\n test transformation there + back \n");
   for (ii = 0 ; ii < lengthof(key_tab) ; ii++)
   {
      key1    = key_tab[ii].key;
      string1 = key_2_string (key1);
      string2 = string1;
      key2    = string_2_key (&string1);

      printf ("\n key = %04x, string = \"%s\"", key1, string2);
      if (key1 != key2)
         printf (", key2 = %04x", key2);
   }  /* for ii */
   printf ("\n");
   

   printf ("\n test double occurences \n");
   key0 = 0;
   string0 = '\0';
   for (ii = 0 ; ii < lengthof(key_tab) ; ii++)
   {
      key1    = sorted_by_key   [ii].key;
      string1 = sorted_by_key   [ii].string;
      key2    = sorted_by_string[ii].key; 
      string2 = sorted_by_string[ii].string; 

      printf ("\n key = %04x, string = \"%s\"", key1, string1);
      if (key0 == key1) printf ("***");

      printf ("\t key = %04x, string = \"%s\"", key2, string2);
      if (stricmp (string0, string2) == 0) printf ("***");

      key0    = key1;
      string0 = string2;
   }  /* for ii */
   printf ("\n");
   
}  /* test_tables */

#endif


void init_sorted_tables (void)
{

   start_index0 = start_index (lengthof(key_tab) + 1);

/* tabellen kopieren */
   memcpy (sorted_by_key   , key_tab, sizeof(key_tab));
   memcpy (sorted_by_string, key_tab, sizeof(key_tab));

/* tabellen sortieren */
   qsort (sorted_by_key   , lengthof(key_tab),
                            sizeof(struct KEY_TAB), comp_keys);
   qsort (sorted_by_string, lengthof(key_tab),
                            sizeof(struct KEY_TAB), comp_strings);

   drop_double_entries ();

#if (TEST_TABLES)
   test_tables ();
#endif

   return;
}  /* init_sorted_tables */


#if (QSORT_FUNC_ANSI)
static int comp_keys  (const void *kt1, const void *kt2)
#else
static int comp_keys  (kt1, kt2)
const void *kt1;
const void *kt2;
#endif
{
   return (((struct KEY_TAB *) kt1)->key - 
           ((struct KEY_TAB *) kt2)->key);
}  /* comp_keys */


#if (QSORT_FUNC_ANSI)
static int comp_strings (const void *kt1, const void *kt2)
#else
static int comp_strings (kt1, kt2)
const void *kt1;
const void *kt2;
#endif
{
   return (stricmp (((struct KEY_TAB *) kt1)->string,
                    ((struct KEY_TAB *) kt2)->string));
}  /* comp_strings */


/* -FF-  */

char * key_2_string (int key)
{
/* translate with sorted key table */

int index, delta, diff;
static char help [2];

#if (VAR_EOLN)
   if (key == EOLN)
      return "\\NL";
#endif

   delta = start_index0;

   for (index = delta-1 ; delta > 0 ;  /* */ )
   {
      if (index >= lengthof(key_tab))
      {
         diff = -1;          /* outside range */
      }
      else
      {
         diff = key - sorted_by_key[index].key;
         if (diff == 0)
            return (sorted_by_key[index].string);
      }

      delta >>= 1;           /* shift right 1 bit */

      if (diff > 0)  /* succesive approximation */
         index += delta;
      else
         index -= delta;
   }  /* for loop */


/* key is not in table: build 'special string' with 1 single char + eos */
   help [0] = (char) key;
   help [1] = '\0';         /* eos: end of string */

   return help;

}  /* key_2_string */


int string_2_key (char **string)
{
/* translate with sorted key table */

int index, delta, help;


/* <backslash> sequence ? */
   if (**string == '\\')
   {
#if (VAR_EOLN)
      if (strnicmp (*string, "\\NL", strlen ("\\NL")) == 0)
      {
         *string += strlen ("\\NL"); /* next index */
         return EOLN;
      }
#endif

      delta = start_index0;
   
      for (index = delta-1 ; delta > 0 ;  /* */ )
      {
         if (index >= lengthof(key_tab))
         {
            help = -1;          /* outside range */
         }
         else
         {
            help = strnicmp (*string, sorted_by_string[index].string,
                              strlen (sorted_by_string[index].string));
         
            if (help == 0)
            {
               *string += strlen (sorted_by_string[index].string); /* next index */
               return (sorted_by_string[index].key);
            }
         }

         delta >>= 1;           /* shift right 1 bit */
   
         if (help > 0)          /* successive approximation */
            index += delta;
         else
            index -= delta;
      }  /* for loop */
   }  /* if '\' */


/* single char or unknown sequence */
   help = (int) **string;
   (*string)++;                /* next index */
   return help;                /* single char */

}  /* string_2_key */

#else

/* -FF-  */

char * key_2_string (int key)
{
/* translate with key table */

int ii;
static char help [2];

#if (VAR_EOLN)
   if (key == EOLN)
      return "\\NL";
#endif

/* search for key in table */
   for (ii = 0 ; ii < lengthof(key_tab) ; ii++)
   {
      if (key == key_tab[ii].key)        /* found key */
         return key_tab[ii].string;      /* return pointer to string */
   }

/* key is not in table: build 'special string' with 1 single char + eos */
   help [0] = (char) key;
   help [1] = '\0';         /* eos: end of string */

   return help;

}  /* key_2_string */


int string_2_key (char **string)
{
/* translate with key table */

int ii, help;

/* <backslash> sequence ? */
   if (**string == '\\')
   {
#if (VAR_EOLN)
      if (strnicmp (*string, "\\NL", strlen ("\\NL")) == 0)
      {
         *string += strlen ("\\NL"); /* next index */
         return EOLN;
      }
#endif

   /* search for key in table */
      for (ii = 0 ; ii < lengthof(key_tab) ; ii++)
      {
         if (strnicmp (*string, key_tab[ii].string,
                        strlen (key_tab[ii].string)) == 0)  /* found string */
         {
            *string += strlen (key_tab[ii].string);        /* next index */
            return key_tab[ii].key;                        /* return key */
         }
      }
   }


/* single char or unknown sequence */
   help = (int) **string;
   (*string)++;                /* next index */
   return help;                /* single char */

}  /* string_2_key */

#endif

/* -FF-  */

struct MACRO *init_macro (char *macro_name)
{
struct MACRO *macro;
size_t nam_len;

   macro = (struct MACRO *) mac_malloc (MACRO_SIZE);
   if (macro != NULL)
   {
     macro->next_macro = NULL;
     
  /* store macro name in buffer */
     nam_len = min (strlen (macro_name), 
                    (sizeof (macro->name)-1));
     macro_name [nam_len] = '\0';  /* limit */
     strcpy (macro->name, macro_name);

  /* store macro sequence */
     macro->length = sizeof (struct MACRO);
     macro->i_ptr = macro->sequence;

  /* aktivate macro store */
     push_macro_stack (macro, MACRO_CREATE, 1L, 0);
   }

   return macro;
}  /* init_macro */

/* -FF-  */

struct MACRO *get_macro_adress (char *macro_name)
{
/* search for macro name in chain */

struct MACRO *act_buf;

   act_buf = top_of_macros;

   while (act_buf != NULL)
   {
   /* check this macro name */
      if (namcmp (act_buf->name, macro_name) == 0)
      {
         return act_buf;   /* found ! */
      }

   /* next turn */
      act_buf = act_buf->next_macro;
   }

/* reached end of chain */
   return NULL;  /* name not found in chain */
}  /* get_macro_adress */

/* -FF-  */

#if 0

size_t mac_len (struct MACRO *macro)
{
size_t length;
int *ptr;

   length = 0;
   ptr = macro->sequence;

   while (*ptr != 0)
   {
      length += sizeof(int);
      ptr++;
   }

   return sizeof(struct MACRO) + length;
}  /* mac_len */


int get_macro_aborted (void)
{
   return (macro_aborted)
}  /* get_macro_aborted */

#endif

/* -FF-  */

int free_current_macro (struct MACRO *macro)
{
/* ^C aborted current macro create */

   if (macro != 0)
   {
      mac_free (macro);
      return 1;       /* o.k. */
   }
   else
   {
      return -1;      /* error */
   }
   
}  /* free_current_macro */

/* -FF-  */

int unchain_macro (char *macro_name)
{
/* release old macro from chain */

struct MACRO *act_buf;
struct MACRO *old_buf;

   old_buf = (struct MACRO *) &top_of_macros;
   act_buf =                   top_of_macros;

   while (act_buf != NULL)
   {
   /* check this macro name */
      if (namcmp (act_buf->name, macro_name) == 0)
      {
      /* macro ausfaedeln */
         old_buf->next_macro = act_buf->next_macro;
         mac_free (act_buf);
         return 1;            /* found ! abort search */
      }

   /* next turn */
      old_buf = act_buf;
      act_buf = act_buf->next_macro;
   }

/* reached end of chain */
   return 0;  /* name not found in chain */

}  /* unchain_macro */

/* -FF-  */

struct MACRO *chain_macro (struct MACRO *macro, int mode)
{
size_t buf_size;
long repeat;
struct MACRO *new_buf;
struct MACRO *act_buf;
struct MACRO *old_buf;

/* modeless or non-modeless macro ? */
   macro->mode = mode;

/* ggf. ausfaedeln des alten macro aus der kette */
   unchain_macro (macro->name);

/* get new buffer */
   buf_size = macro->length;

   new_buf = (struct MACRO *) mac_malloc (buf_size);

   if (new_buf == NULL)  /* out of memory ? */
   {
      new_buf = macro;   /* keep old buffer */
   }
   else                  /* take new (smaller) buffer */
   {
      memcpy (new_buf, macro, buf_size);
      repeat = pop_macro_stack (macro, 0);
      push_macro_stack (new_buf, MACRO_CREATE, repeat, 0);
      mac_free (macro);
   }

/* chain at end of thread */
   old_buf = (struct MACRO *) &top_of_macros;
   act_buf =                   top_of_macros;

   while (act_buf != NULL)
   {
      old_buf = act_buf;
      act_buf = act_buf->next_macro;
   }

/* reached end of chain */
   old_buf->next_macro = new_buf;
   new_buf->next_macro = NULL;

   return new_buf;
}  /* chain_macro */

/* -FF-  */

void reset_macro_stack (void)
{
   stack_index = 0;
   macro_aborted = 1;

   macro_stack [1].cntmac = macro_stack [1].cntexe;
   macro_stack [1].cntexe = 0L;

   return;
}  /* reset_macro_stack */


void stop_this_macro (void)
{
   macro_stack[stack_index].repeat = 1L;   /* letzter durchlauf */
   pop_macro_stack (macro_stack[stack_index].macro, 1);

   return;
}  /* stop_this_macro */

/* -FF-  */

int push_macro_stack (struct MACRO *macro, enum MACRO_STATUS status,
                      long repeat, int save_mode_flag)
{
   if (stack_index >= (MAX_STACK_NUM-1))
   {
      return -1;   /* error, stack overflow */
   }
   else
   {
      stack_index++;
      macro_stack[stack_index].repeat = repeat;
      macro_stack[stack_index].cntexe = 1L;
      macro_stack[stack_index].cntmac = 0L;
      macro_stack[stack_index].macro  = macro;
      macro_stack[stack_index].status = status;
      macro_stack[stack_index].save_mode_flag = save_mode_flag;

      macro->i_ptr = macro->sequence;

      macro_aborted = 0;
      return stack_index;   /* o.k. */
   }

}  /* push_macro_stack */

/* -FF-  */

long pop_macro_stack (struct MACRO *macro, int dekr_repeat)
{
#define REPEAT macro_stack[stack_index].repeat

   macro->i_ptr = macro->sequence;  /* restore pointer to begin of sequence */

   if (stack_index > 0)
   {
      if (dekr_repeat)
      {
          macro_stack[stack_index].repeat--;

          if (macro_stack[stack_index].repeat == 0L)
          {
             macro_stack[stack_index].cntmac = macro_stack[stack_index].cntexe;
             macro_stack[stack_index].cntexe = 0L;
          }
          else
          {
             macro_stack[stack_index].cntexe++;
          }
      }

      if ((macro_stack[stack_index].repeat <= 0) || (dekr_repeat == 0))
      {
         stack_index--;
      }

      return macro_stack[stack_index].repeat;  /* o.k. */
   }
   else
   {
      return -1;           /* error */
   }

}  /* pop_macro_stack */

/* -FF-  */

enum MACRO_STATUS get_macro_status (void)
{
   return macro_stack[stack_index].status;
}  /* get_macro_status */


int get_macro_nesting_level (void)
{
   return stack_index;
}  /* get_macro_nesting_level */


int get_save_mode_flag (void)
{
   return macro_stack[stack_index + 1].save_mode_flag;
}  /* get_macro_nesting_level */


long get_macro_cntexe (void)
{
   return macro_stack [1].cntexe;
}


long get_macro_cntmac (void)
{
   return macro_stack [1].cntmac;
}

/* -FF-  */

int get_macro_key (void)
{
int key;
struct MACRO *macro;
static int start_flag, end_flag;

   macro = macro_stack[stack_index].macro;

/* first key in modeless macro ? */
   if ((macro->i_ptr == macro->sequence) &&
       (macro->mode == 0))
   {
      if (start_flag == 0)
      {
         start_flag = 1;
         return 0x1b;     /* always perform additional <esc> as 1st key */
      }
      else
      {
         start_flag = 0;
      }
   }

/* now get macro key */
   key = *macro->i_ptr;   /* get key */
   macro->i_ptr++;

   if (key == SEQU_EM)               /* end of non-modeless macro ? */
   {
      pop_macro_stack (macro, 1);
      return SEQU_EM;
   }

   if (key == SEQU_MM)               /* end of modeless macro ? */
   {
      if (end_flag == 0)
      {
         end_flag = 1;
         macro->i_ptr--;       /* get same code again */
         return 0x1b;          /* last command of each macro is <esc> */
      }
      else
      {
         end_flag = 0;
         pop_macro_stack (macro, 1);
         return SEQU_MM;
      }
   }

/* sonst */
   return key;

}  /* get_macro_key */

/* -FF-  */

int put_macro_key (int key)
{
struct MACRO *macro;

   macro = macro_stack[stack_index].macro;

   *macro->i_ptr = key;   /* put key */
   macro->i_ptr++;
   macro->length += sizeof (int);

   if (macro->length >= (MACRO_SIZE-sizeof(int)))    /* reached max. size ? */
   {                                                 /* force end of macro */
      *macro->i_ptr = SEQU_MM;          /* write new end of sequence */
      macro->i_ptr++;
      macro->length += sizeof (int); /* @@ */

      macro = chain_macro (macro, 0);
      pop_macro_stack (macro, 0);
      return -1;  /* abort */
   }
   else
   {
      return 0;   /* o.k. */
   }
}  /* put_macro_key */

/* -FF-  */

int delete_last_macro_key (void)
{
struct MACRO *macro;
int err_flag;

   macro = macro_stack[stack_index].macro;

   macro->i_ptr--;
   /* macro->length -= sizeof (int);  @@ */

   err_flag = - (toupper(*macro->i_ptr) != 'M');   /*  0 = o.k. */
                                                   /* -1 = error */

   *macro->i_ptr = SEQU_MM;        /* write new end of sequence */
   macro->i_ptr++;
   /* macro->length += sizeof (int);  @@ */

   return err_flag;
}  /* delete_last_macro_key */

/* -FF-  */

int save_macro (char *macro_name)
{
struct MACRO *macro;

   macro = get_macro_adress (macro_name);
   if (macro == NULL)
   {
      return -1;  /* error */
   }
   else

/* save macro in aedit format : */
/* "M<macro name>\BR<translated sequence>\MM" */
   {
      set_cursor_to (fc->lrow, REL_COLUMN);

   /* macro name */
      perform_key_insert ('M', 0);   /* 'M' */
      perform_string_insert (macro->name);
      perform_string_insert ("\\BR");

   /* translated sequence */
      macro->i_ptr = macro->sequence;
      while ((*macro->i_ptr != SEQU_MM) &&
             (*macro->i_ptr != SEQU_EM))
      {
         perform_string_insert
            (key_2_string (*macro->i_ptr));
         macro->i_ptr++;

      /* ggf. insert <cr> */
         if (fc->column > (COLUMNS-5))
            perform_insert_eol ();   /* <cr> */
      }
   
   /* end of macro */
      perform_string_insert
         (key_2_string (*macro->i_ptr));
      perform_key_insert (';', 0);
      perform_insert_eol ();

      return 0;  /* o.k. */
   }
}  /* save_macro */

/* -FF-  */

int insert_macro (void)
{
int change_flag, key_2;

   show_status_line_2 ("Abort with ^C", 0, -2, 0);
   set_cursor_to (fc->lrow, REL_COLUMN);

   change_flag = 0;

   while ((key_2 = get_1_key (0)) != 0x03)
   {
      change_flag = 1;

   /* insert key or \-sequence */
      if (key_2 == C_R)
         perform_insert_eol ();
      else
         perform_string_insert (key_2_string (key_2));

   /* ggf. insert <cr> */
      if (fc->column > (COLUMNS-5))
      {
         update_rest_of_window (fc->lin_left, fc->lrow);
         perform_insert_eol ();   /* <cr> */
      }
      else
      {
         update_this_line (fc->lin_left, fc->lrow);
      }

   /* display */
      if (fc->lrow >= MAX_ROW)
         perform_view ();
      else
         perform_update (fc->buff_0, fc->byte_anz,
                         fc->left_col);

      fc->change_flag = 1;
      show_status_line_1 (get_line_1_text (), fc);

      set_cursor_to (fc->lrow, REL_COLUMN);
   }

   return change_flag;
}  /* insert_macro */

/* -FF-  */

int list_macros (void)
{
int mac_num, ii, tab_diff;
int mf_ind, mf_min, mf_max, mf_act;
int row, line_len, end_index;
struct MACRO *act_buf;
long mac_size;
char line [81];

   mac_num  = 0;
   mac_size = 0;
   line_len = 0;
   act_buf  = top_of_macros;


/* 1. exec pathname */
   printf ("\015\012");
   printf ("exec path mbedit    : \"%s\"\015\012", get_exe_path());
   row = 2;


/* 2. syntax file pathname */
   row += show_syntax_file();

   if (row >= (w_bot[0] - STATUS_LINES - 2))
   {
      printf ("\015\012 hit any key to continue ... ");
      get_1_key (0);
      clear_screen ();
      printf ("\015\012");
      row = 1;
   }


/* 3. macro file(s) pathname(s) */
   printf ("\015\012");
   printf ("loaded macro file(s):\015\012"); 
   printf ("    ind lev: pathname \015\012");
   row += 3;

   if (mac_count < 0)
   {
      printf ("     <none> \015\012");
      row++;
   }
   else
   {
      if (mac_count < MACRO_FILE_NO)
      {
         mf_min = 0;
         mf_max = mac_count;
      }
      else
      {
         mf_min = mac_count - (MACRO_FILE_NO - 1);
         mf_max = mac_count;
         printf ("     <incomplete list> \015\012");
         row++;
      }

      for (mf_ind = mf_min ; mf_ind <= mf_max ; mf_ind++)
      {
         mf_act = mf_ind % MACRO_FILE_NO;
         printf ("     %2d (%d): \"%s\" \015\012",
                        mf_ind+1,
                        macro_level   [mf_act],
                        macro_filename[mf_act]);
         row++;
      }  /* for mm */
   }

   if (row >= (w_bot[0] - STATUS_LINES - 2))
   {
      printf ("\015\012 hit any key to continue ... ");
      get_1_key (0);
      clear_screen ();
      printf ("\015\012");
      row = 1;
   }


/* 4. macro list */
   printf ("\015\012");
   printf ("list of macros [size in bytes]:\015\012");
   row += 2;

/* loop for all macros */
   while (act_buf != NULL)
   {
   /* prepare buffer */
      sprintf (line, "%s [%d], ", act_buf->name, act_buf->length);

   /* n blanks anhaengen anstatt <tab> (wg. mitzaehlen) */
      end_index = strlen(line);
      tab_diff = set.tabs - (end_index % set.tabs);
      for (ii = end_index ; ii < (end_index + tab_diff) ; ii++)
      {
         line [ii  ] = ' ';    /* insert blank */
      }
      end_index += tab_diff;
      line[end_index] = '\0';  /* new end of string */

   /* new line ? */
      if ((line_len + (int)strlen(line)) >= (COLUMNS-1))
      {
         printf ("\015\012");
         row++;
         line_len = 0;  /* no of blanks in printf above */

      /* ggf. pause */
         if (row >= (w_bot[0] - STATUS_LINES - 2))
         {
            printf ("\015\012 hit any key to continue ... ");
            get_1_key (0);
            clear_screen ();
            printf ("\015\012");
            row = 1;
         }
      }

   /* show macro name */
      line_len += printf ("%s", line);

   /* statistics */
      mac_size += act_buf->length;
      mac_num++;

   /* next macro */      
      act_buf = act_buf->next_macro;
   }

/* unterschrift */
   printf ("\015\012\n Total Number of Macros = %d", mac_num);
   printf ("\015\012 Total Size   of Macros = %ld (Bytes dec.)\015\012", mac_size);

   printf ("\015\012 hit any key to continue ... ");
   get_1_key (0);
   return mac_num;
}  /* list_macros */

/* -FF-  */

char *get_macro_filename (void)
{
   return macro_filename[MAC_ACT_IND];
}  /* get_macro_filename */

/* -FF-  */

#if (WITH_E_DELIMIT)

#if (QSORT_FUNC_ANSI)
static int comp_chars  (const void *ch1, const void *ch2)
#else
static int comp_chars  (ch1, ch2)
const void *ch1;
const void *ch2;
#endif
{
   return ((* (char *) ch1) -
           (* (char *) ch2));
}  /* comp_chars */


static void drop_double_chars (char *string, size_t num)
{
int ii;

   for (ii = 1; ii < (int) num ; ii++)
   {
      if (string[ii] == string[ii-1])
      {
         memcpy (&string[ii-1], &string[ii], (num - ii + 1));
         num--;
         ii--;
      }
   }

   return;

}  /* drop_double_chars */


void normalize_delims (void)
{

/* sort delimiter set in ascending order */
   qsort (fc->e_delimit, strlen (fc->e_delimit),
                         1, comp_chars);

/* remove double values */
   drop_double_chars (fc->e_delimit, strlen (fc->e_delimit));

   return;

}  /* normalize_delims */

#endif

/* -FF-  */

int read_macro_file (char *filename, int store_filename)
{
struct MACRO *macro = NULL;
FILE *fp;
STATIC char parse_line [BUF_256];
char *parse_ptr, *max_ptr, *help_ptr;
char macro_name [81];
char *name_ptr;
int key, line_no, err_line;
char err_text [20];
enum FILE_STAT {  NORMAL,
                  MACRO_NAME,
                  MACRO_SEQUENCE,
                  COMMENT
               };
enum FILE_STAT file_stat, save_stat = NORMAL;

int  val, mode;

#if (ACT_OP_SYSTEM == OS_9)
#define BIG_BUFFER 32
#endif

#if BIG_BUFFER
static int read_level;
static char bigbuff [BIG_BUFFER*BUFSIZ];
#endif

int num, help_int, help_int2, help_int3;
char komma;

#define FILE_MUST_EXIST  1    /* NEU, konst. ! */

#if (ACT_SERVER == SERVER_VGA)
long attr;
#else
int ii;
#define LINE_LEN 16
char esc_line [LINE_LEN];
#endif


   err_line = 0;  /* default: no error */
   line_no  = 0;

/* anzeige */
   show_status_line_2 ("*** reading macro file ***", 0, -2, 0);

/* open datafile */
   fp = fopen (filename, "r");
   if (fp == NULL)           /* file doesn't exist */
   {
#if FILE_MUST_EXIST
      err_message (FILE_DOESN_T_EXIST);
      return -2;          /* error : abort --> */
#else
      return 0;           /* no bytes read */
#endif
   }

/* for speed up */
#if BIG_BUFFER
   if (read_level == 0)    /* only the first time */
      setvbuf (fp, bigbuff, _IOFBF, sizeof(bigbuff));
   read_level++;
#endif

/* read datafile */
#if MAC_TEST
   printf ("\015\012");
#endif

/* save <macro filename> for perform_special_keys () */
   if (store_filename)
   {
      mac_count++;
      macro_level[MAC_ACT_IND] = incl_level;
      strncpy (macro_filename[MAC_ACT_IND],
               filename,
               sizeof(macro_filename[0]));
   }


/* interprete macro file */
   file_stat = NORMAL;
   while (fgets (parse_line, sizeof(parse_line), fp) != NULL)
   {
      line_no++;
      max_ptr = &parse_line[min(strlen(parse_line),
                                sizeof(parse_line))-1];

#if MAC_TEST
      printf ("%s", parse_line);
#endif

      for (parse_ptr = parse_line ; (*parse_ptr != 0x0a) && (*parse_ptr != 0x0d) ; /* no ++ here ! */ )
      {
      /* for safety reasons ... */
         if (parse_ptr >= max_ptr)
         {
            err_line = line_no;
            break; 
         }
      
         switch (file_stat)
         {
            case NORMAL:
               switch (toupper(*parse_ptr))
               {
                  case 'I':  /* "INCLUDE macrofile" (exactly one <space> !) */
                     if (parse_ptr == parse_line)   /* column 0 only !! */
                     {
                        if (strnicmp (parse_ptr, "INCLUDE", 7) == 0)
                        {
                           parse_ptr += 8;   /* skip "INCLUDE " */

                        /* terminate filename */
                           help_ptr = parse_ptr;
                           for (help_ptr = parse_ptr ; ; help_ptr++)
                           {
                              if ((*help_ptr <= 0x20) || (*help_ptr >= 0x7f))
                              {
                                 *help_ptr = '\0';  /* forced end of string */
                                 break;
                              }
                           }

                        /* read include file */
                           incl_level++;
                           if (incl_level >= MAX_INCLUDE_NUM)
                              err_message (MACRO_INCLUDE_NESTING_TO_DEEP);
                           else
                              read_macro_file (parse_ptr, 1);  /* 25.11.95: 0 --> 1 */
                           incl_level--;
                        }
                        else
                        {
                           err_line = line_no;
                        }
                     }
                     *parse_ptr = EOLA;  /* forced end of parse_line */
                     break;

                  case 'M':   /* Macro */
                     if (parse_ptr == parse_line)   /* column 0 only !! */
                        file_stat = MACRO_NAME;

                     parse_ptr++;
                     break;

                  case 'A':
                     if (parse_ptr == parse_line)   /* column 0 only !! */
                     {
                        parse_ptr++;
                        switch (toupper(*parse_ptr))
                        {
                           case 'V':   /* number of lines on screen */
                              parse_ptr++;
                              parse_ptr++;       /* ignore '=' */
                              if (sscanf (parse_ptr, "%d", &ROWS) != 1)
                              {
                                 err_line = line_no;
                              }
                              ROWS = max (ROWS, STATUS_LINES + 1);
                              ROWS = min (ROWS, LIMIT_ROWS);
                              limit_windows ();
                              break;

                           case 'C':   /* number of columns on screen */
                              parse_ptr++;
                              parse_ptr++;       /* ignore '=' */
                              if (sscanf (parse_ptr, "%d", &COLUMNS) != 1)
                              {
                                 err_line = line_no;
                              }
                              COLUMNS = max (COLUMNS, 1);
                              COLUMNS = min (COLUMNS, LIMIT_COLUMNS);
                              break;

                           case 'G':   /* semi grafik ON/OFF */
                              parse_ptr++;
                              parse_ptr++;       /* ignore '=' */
                              if (sscanf (parse_ptr, "%d", &val) != 1)
                              {
                                 err_line = line_no;
                              }
                              set_grafik_status (val);
                              break;

#if (WITH_MOUSE)
                           case 'M':   /* mouse driver ON/OFF */
                              parse_ptr++;
                              parse_ptr++;       /* ignore '=' */
                              if (sscanf (parse_ptr, "%d", &val) != 1)
                              {
                                 err_line = line_no;
                              }
                              set_mouse_status (val);
                              break;
#endif

                           case 'S':   /* Auto Shift */
                              parse_ptr++;
                              parse_ptr++;       /* ignore '=' */
                              if (sscanf (parse_ptr, "%d", &val) != 1)
                              {
                                 err_line = line_no;
                              }
                              set_auto_shift (val);
                              break;

#if (ACT_OP_SYSTEM != MS_DOS) && (ACT_OP_SYSTEM != WIN_32) && (ACT_OP_SYSTEM != RDOS)
                           case 'E':   /* Escape wait time */
                              parse_ptr++;
                              parse_ptr++;       /* ignore '=' */
                              if (sscanf (parse_ptr, "%d", &val) != 1)
                              {
                                 err_line = line_no;
                              }
                              esc_waittime = max (0, val);
                              break;
#endif

                           case 'F':   /* attribute (color) on screen */
                              parse_ptr++;
                              switch (mode = toupper(*parse_ptr))
                              {
                                 case 'N':  /* normal video  */
                                 case 'R':  /* reverse video */
                                 case '1':  /* status line 1 */
                                 case '2':  /* status line 1 */
#if (WITH_SYNTAX_HIGHLIGHTING)
                                 case 'C':  /* comment       */
                                 case 'K':  /* keyword       */
                                 case 'S':  /* string        */
#endif
                                    parse_ptr++;
                                    parse_ptr++;       /* ignore 'V' */
                                    parse_ptr++;       /* ignore '=' */
#if (ACT_SERVER == SERVER_VGA)
                                 /* vga codes */
                                    if (*parse_ptr != '\"')
                                    {
                                       if (sscanf (parse_ptr, "%lx", &attr)
                                                   != 1)
                                       {
                                          err_line = line_no;
                                       }
                                       else
                                       {
                                          switch (mode)
                                          {
                                             case 'N': set_default_attribute ((byte) attr); break;
                                             case 'R': set_invers_attribute  ((byte) attr); break;
                                             case '1': set_stat_1_attribute  ((byte) attr); break;
                                             case '2': set_stat_2_attribute  ((byte) attr); break;
#if (WITH_SYNTAX_HIGHLIGHTING)
                                             case 'C': set_comment_attribute ((byte) attr); break;
                                             case 'K': set_keyword_attribute ((byte) attr); break;
                                             case 'S': set_string_attribute  ((byte) attr); break;
#endif
                                             default : break;
                                          }
                                       }
                                    }
#else
                                 /* esc sequence for VT100 / ANSI */
                                    if (*parse_ptr == '\"')
                                    {
                                       parse_ptr++;

                                    /* read escape sequence */
                                       memset (esc_line, 0 , sizeof(esc_line));
                                       for (ii = 0 ; ii < (LINE_LEN-1) ; ii++)
                                       {
                                          esc_line [ii] = (char) *parse_ptr;
                                          parse_ptr++;
   
                                          if (*parse_ptr == '\"')  /* end of string */
                                             break;
                                       }  /* for ii */
   
                                    /* store <esc> sequence */
                                       switch (mode)
                                       {
                                          case 'N': set_default_attribute (esc_line); break;
                                          case 'R': set_invers_attribute  (esc_line); break;
                                          case '1': set_stat_1_attribute  (esc_line); break;
                                          case '2': set_stat_2_attribute  (esc_line); break;
#if (WITH_SYNTAX_HIGHLIGHTING)
                                          case 'C': set_comment_attribute (esc_line); break;
                                          case 'K': set_keyword_attribute (esc_line); break;
                                          case 'S': set_string_attribute  (esc_line); break;
#endif
                                          default : break;
                                       }
                                    }
#endif
                                    break;

                                 default:
                                    parse_ptr++;
                                    break;
                              }
                              break;

                           default:
                              parse_ptr++;
                              break;
                        }
                     }
                     parse_ptr++;
                     break;

                  case 'S':
                     if (parse_ptr == parse_line)   /* column 0 only !! */
                     {
                        parse_ptr++;
                        switch (toupper(*parse_ptr))
                        {
                           case 'A':   /* Auto <nl> */
                              parse_ptr++;
                              set.autonl = (toupper(*parse_ptr) == 'Y');
                              break;

                           case 'B':   /* Backup Files */
                              parse_ptr++;
                              set.bak_file = (toupper(*parse_ptr) == 'Y');
                              break;

                           case 'C':   /* Consider Case */
                              parse_ptr++;
                              set.c_case = (toupper(*parse_ptr) == 'Y');
                              break;

                           case 'D':   /* Display Macro Execution */
                              parse_ptr++;
                              set.display = (toupper(*parse_ptr) == 'Y');
                              break;

#if 0   /* (WITH_E_DELIMIT) not used any more */
                           case 'E':
                              parse_ptr++;
                              sscanf (parse_ptr, "%s", set.e_delimit);
                              normalize_delims ();
                              break;
#endif

                           case 'F':   /* File number */
                              parse_ptr++;
                              if (sscanf (parse_ptr, "%d", &set.file_num) != 1)
                              {
                                 err_line = line_no;
                              }
                              set.file_num = max (1,   /* minimum 1 file !! */
                                             min (MAX_FC_NUM, set.file_num));
                              break;

                           case 'H':   /* Display Highbit Characters as is */
                              parse_ptr++;
							  /* default */                   set.highbit_global = 0;  /* No   */
                              if (toupper(*parse_ptr) == 'Y') set.highbit_global = 1;  /* Yes  */
                              if (toupper(*parse_ptr) == 'A') set.highbit_global = 2;  /* Auto */
                           
							  set_highbit();
                              break;

                           case 'I':   /* Indent */
                              parse_ptr++;
                              set.indent = (toupper(*parse_ptr) == 'Y');
                              break;

                           case 'K':   /* k_token */
                              parse_ptr++;
                              set.k_token = (toupper(*parse_ptr) == 'Y');
                              break;

                           case 'M':   /* Margin */
                              parse_ptr++;

                              help_int  = set.margin[0];
                              help_int2 = set.margin[1];
                              help_int3 = set.margin[2];

                              num = sscanf (parse_ptr, "%d %c %d %c %d",
                                                        &help_int,
                                                        &komma,
                                                        &help_int2,
                                                        &komma,
                                                        &help_int3 );
                              if ((num < 1) ||
                                  (help_int3 <= help_int) ||
                                  (help_int3 <= help_int2))
                              {
                                 err_line = line_no;
                              }
                              else
                              {
                                               set.margin[0] = help_int;
                                 if (num >= 2) set.margin[1] = help_int2;
                                 if (num >= 3) set.margin[2] = help_int3;
                              } 
                              break;

                           case 'N':   /* No Tabs */
                              parse_ptr++;
                              set.notab = (toupper(*parse_ptr) == 'Y');
                              break;

                           case 'R':   /* Radix */
                              parse_ptr++;
                              switch (toupper(*parse_ptr))
                              {
                                 case 'A':
                                 case 'B':
                                 case 'D':
                                 case 'H':
                                 case 'O':
                                    set.radix = toupper(*parse_ptr);
                                    break;
         
                                 default:
                                    err_line = line_no;
                                    break;
                              }
                              break;

                           case 'S':   /* Show Find */
                              parse_ptr++;
                              set.showfind = (toupper(*parse_ptr) == 'Y');
                              break;

                           case 'T':   /* Tabs */
                              parse_ptr++;
                              if (sscanf (parse_ptr, "%d", &set.tabs) != 1)
                              {
                                 err_line = line_no;
                              }
                              set.tabs = max (1, min (COLUMNS, set.tabs));

							  /* bugfix 08.06.02 */
                              update_entire_window (fc->top_left);
                              check_dirty_cursor ();
                              break;

                           case 'V':   /* View Row */
                              parse_ptr++;
                              if (sscanf (parse_ptr, "%d", &set.viewrow) != 1)
                              {
                                 err_line = line_no;
                              }
                              set.viewrow -= LINE_OFFSET;
                              set.viewrow = max (0, min ((ROWS-1),
                                                  set.viewrow));
                              break;

                           case 'W':   /* Warning with beep */
                              parse_ptr++;
                              set.warning = (toupper(*parse_ptr) == 'Y');
                              set.warning = *parse_ptr - '0';
                              set.warning = max (0, min (2, set.warning));
                              break;

                           case '*':   /* Search with Wildcards */
                              parse_ptr++;
                              set.wildcards = (toupper(*parse_ptr) == 'Y');
                              break;

                           case '~':   /* Replace '~' with home directory */
                              parse_ptr++;
                              set.tilde_home = (toupper(*parse_ptr) == 'Y');
                              break;

#if (WITH_SYNTAX_HIGHLIGHTING)
                           case 'Y':   /* default sYntax */
                              parse_ptr++;
                              if (sscanf (parse_ptr, "%d", &set.syntax_global) != 1)
                              {
                                 err_line = line_no;
                              }
                              set.syntax_global &= 0x07;
                              fc->syntax_flag   &= set.syntax_global;
                              break;
#endif

                           default:
                              parse_ptr++;
                              break;
                        }
                     }
                     parse_ptr++;
                     break;

                  case '\\':   /* Comment */
                     key = string_2_key (&parse_ptr);
                     switch (key)
                     {
                        case COMM_STT:
                           save_stat = file_stat;
                           file_stat = COMMENT;
                           break;

                        default:
                           break;
                     }
                     break;

                  default:
                     parse_ptr++;
                     break;
               }
               break;
   
            case MACRO_NAME:
               name_ptr = macro_name;
               *name_ptr = '\0';
               help_ptr = parse_ptr;
               while (string_2_key (&help_ptr) != 0x1b)
               {                                  /* search end of name */
                  *name_ptr = *parse_ptr;
                  name_ptr++;
                  *name_ptr = '\0';
                  parse_ptr++;
                  help_ptr = parse_ptr;

               /* don't exceed max. name length */
                  if (name_ptr >= &macro_name[sizeof(macro_name)-1])
                  {
                     err_line = line_no;
                     break;
                  }

               /* for safety reasons ... */
                  if (parse_ptr >= max_ptr)
                  {
                     err_line = line_no;
                     break;
                  }
               }

               macro = init_macro (macro_name);
               if (macro == NULL)
               {
                  err_message (OUT_OF_MEMORY);
                  fclose (fp);
#if BIG_BUFFER
                  read_level--;
#endif
                  return -1;      /* error : abort --> */
               }

               parse_ptr += 3;   /* ignore "\BR" */

               file_stat = MACRO_SEQUENCE;
               break;
   
            case MACRO_SEQUENCE:
               if (macro->length >= (MACRO_SIZE-sizeof(int)))    /* reached max. size ? */
                  key = SEQU_MM;
               else
                  key = string_2_key (&parse_ptr);

               *macro->i_ptr = key;               /* add new key */
               macro->i_ptr++;
               macro->length += sizeof (int);

               if ((key == SEQU_MM) ||            /* end of sequence ? */
                   (key == SEQU_EM))
               {                                  /* yes : finish macro */
                  macro = chain_macro (macro, (key == SEQU_EM));
                  pop_macro_stack (macro, 0);
                  file_stat = NORMAL;
               }
               break;
   
            case COMMENT:
               switch (*parse_ptr)
               {
                  case '*':
                     parse_ptr++;
                     if (*parse_ptr == '\\')
                     {
                        file_stat = save_stat;
                     }
                     break;

                  default:
                     parse_ptr++;
                     break;
               }
               break;
         }  /* switch file_stat */
      }  /* for parse_ptr */

   }  /* while loop */

/* close datafile */
   fclose (fp);

#if BIG_BUFFER
   read_level--;
#endif

   if (err_line)
   {
      sprintf (err_text, " (line %d)", err_line);
      err_message_1 (INVALID_MACRO_ENTRY, err_text);
      return (- err_line);  /* error */
   }
   else
   {
      show_status_line_2 ("*** got macro file ***", 0, -2, 0);
      return 1;   /* o.k. */
   }
}  /* read_macro_file */

/* -FF-  */

int search_macro_file (void)
{
static char filename [BUF_256];
FILE *fp;

/* search sequence, without return between searches. */

/* 1.) search in PATH (not in ms/dos, only unix + os_9) */
/* 2.) search in mbedit path (path of exe-file = argv[0]) */
/* 3.) search in home directory */

#if (ACT_OP_SYSTEM == MS_DOS) /* || (ACT_OP_SYSTEM == WIN_32) */
#define SEARCH_IN_PATH 0
#else
#define SEARCH_IN_PATH 1
#endif

#if SEARCH_IN_PATH
static char path [BUF_256];
char *name_stt, *name_end;
#endif


#if SEARCH_IN_PATH

/* 1.) search in PATH */

/* get environment variable "PATH" */
   strncpy (path, getenv ("PATH"), sizeof (path));
   path [sizeof(path) - 1] = '\0';  /* forced end of string */

/* example: */
/* PATH=H:;D:\USR.PC\BIN;C:\SYSTEM;C:\PCLINK3;C:\BIN;D:\BIN;D:\BAT;D:\UTIL; */

/* parse environment variable */
   name_stt = path;
   name_end = path;
   while (*name_stt != 0)
   {
      while (*name_end != PATH_SEPARATOR)
      {
         if (*name_end == '\0')   /* missing last separator ? */
            break;                /* for safety reasons */
         name_end++;
      }
      *name_end = '\0';

   /* build macro filename */
      strncpy (filename, name_stt, sizeof(filename));
      strcat  (filename, FILE_SEPARATOR);
      strcat  (filename, MACRO_FILENAME);

#if MAC_TEST
      printf ("\015\012 filename = %s\015\012", filename);
#endif

   /* test, if file exists */
      if ((fp = fopen (filename, "r")) != NULL)
      {                                         /* found file in search path */
         fclose (fp);
         read_macro_file (filename, 1);  /* get it */
         break;
      }

   /* next pathname */
      name_end++;
      name_stt = name_end;
   }  /* while name_stt */

#endif

/* 2.) search in mbedit path */

/* build macro filename */
   strcpy (filename, get_exe_path ());
   strcat (filename, FILE_SEPARATOR);
   strcat (filename, MACRO_FILENAME);

#if MAC_TEST
   printf ("\015\012 filename = %s\015\012", filename);
#endif

/* test, if file exists */
   if ((fp = fopen (filename, "r")) != NULL)
   {                                         /* found file in search path */
      fclose (fp);
      read_macro_file (filename, 1);  /* get it */
   }

/* 3.) search in home directory */

/* build macro filename */
   strcpy (filename, HOME_DIR);
   strcat (filename, FILE_SEPARATOR);
   strcat (filename, MACRO_FILENAME);

#if MAC_TEST
   printf ("\015\012 filename = %s\015\012", filename);
#endif

/* test, if file exists */
   if ((fp = fopen (filename, "r")) != NULL)
   {                                         /* found file in search path */
      fclose (fp);
      return read_macro_file (filename, 1);  /* get it */
   }


   return -1;  /* nothing found */

}  /* search_macro_file */

/* -FF-  */

/* Modification History */
/* 30.12.92 - file erzeugt */
/* 01.01.93 - macro_stack */
/* 02.01.93 - list_macros () */
/* 03.01.93 - struct MACRO : int repeat */
/* 05.01.93 - more CTRL_keys (Home, End, PgUp, PgDn, Leftm Right) */
/* 17.06.93 - AFNV, AFRV */
/* 18.06.93 - set.warning */
/* 27.07.93 - set.warning: 0-2 */
/* 19.08.93 - put_macro_key ()  : force end of macro, if limits exceeded */
/* 24.08.93 - perform_insert_eol () */
/* 28.08.93 - STATIC */
/* 05.09.93 - Find mit Wildcard: '?' */
/* 10.09.93 - setvbuf (for speed) */
/* 12.09.93 - show_status_line_2 (..., ignore_batch) */
/* 29.09.93 - update_rest_of_window(), ...entire_window() */
/* 30.09.93 - key_tab: 0x0d0a */
/* 09.10.93 - Set Margin */
/* 11.10.93 - bugfix: \NL auch bei EOLN <= 0xff */
/* 20.10.93 - 'S'et 'M'argin: check bad values */
/* 29.11.93 - mb_ctype.h */
/* 29.11.93 - semigrafik abschaltbar */
/* 10.12.93 - MouSetMoveArea () */
/* 12.12.93 - MouSetMoveArea (..., 0) */
/* 13.12.93 - 'S','M': Aedit Format */
/* 07.01.94 - AS = 1: automatic shift of screen with cursor, set_auto_shift () */
/* 17.02.94 - read_macro_file (..., store_filename) */
/* 09.05.94 - AE=200, esc_waittime */
/* 10.05.94 - search_macro_file: modified search algorithm */
/* 11.05.94 - search_macro_file: return -1; --> break; */
/* 12.05.94 - MACRO_TUNING */
/* 13.05.94 - 0x0d --> "\\00D" (anstatt "\\0D") eindeutig: "\\0D1", usw... */
/* 15.05.94 - 0x0a --> "\\00A" (anstatt "\\0A") eindeutig: "\\0A0", usw... */
/* 17.05.94 - removed BIG_BUFFER fuer MS_DOS, HDS */
/* 19.05.94 - EOL --> EOLA */
/* 26.05.94 - list_macros: (w_bot[0] - STATUS_LINES) anstatt MAX_ROW */
/* 02.06.94 - INCLUDE macrofile */
/* 04.06.94 - INCLUDE macrofile: error message */
/* 05.06.94 - redisplay window, only if size changed */
/* 21.06.94 - key_tab []: 0x7f <--> "\RB" (Rubout) */
/* 29.06.94 - set.tilde_home */
/* 04.07.94 - WITH_E_DELIMIT */
/* 06.07.94 - 'S'et 'A'utonl */
/* 12.07.94 - Schreibfehler korrigiert */
/* 27.09.94 - type cast(s) wg. compiler warnings (microsoft c 6.0) */
/* 30.09.94 - start_index () global */
/* 02.10.94 - WITH_SYNTAX_HIGHLIGHTING */
/* 04.10.94 - <esc> sequences for vt100 */
/* 05.10.94 - vga: use hex code only, vt100: use string format only */
/* 06.10.94 - special case 0x7f = "\\XF" for SCO_UNIX */
/* 24.02.95 - QSORT_FUNC_ANSI */
/* 17.11.95 - syntax_global */
/* 25.11.95 - list of n macro files */
/* 27.11.95 - macro nesting level (display + limitation) */
/* 23.01.96 - printf ("\015\012") anstatt printf ("\r\n") */
/* 05.09.98 - key_tab: EOLN --> EOLN_INIT */
/* 07.09.98 - bugfixes: EOLN = special case in key_2_string + string_2_key */
/* 08.06.02 - bugfix: read_macro_file(): 'S'et 'T'abs: update_entire_window(), check_dirty_cursor() */
/* 29.03.03 - bugfix: init_sorted_tables(): start_index(... + 1) */
/* 01.04.03 - list_macros(): count additional rows of show_syntax_file() */
/* 23.04.03 - read_macro_file(): break reading line with 0x0a and 0x0d */
/* 30.04.03 - syntax highlighting for strings */
/* 11.02.04 - 'S'et 'H'ighbit 'A'uto */
/* 13.03.04 - disp_hnd.c: modifications for CSS (dashes in keywords) */
