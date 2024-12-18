/*      history.c                           14.02.04       */
/*!
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    handling of history buffers / history file
/
*/

/****************************************************************
*                                                               *
*  BENUTZTE UNTERPROGRAMME (C LIBRARY)                          *
*                                                               *
****************************************************************/

#include "config.h"
#include "standard.h"
#include "global.h"
#include "history.h"
#include "disp_hnd.h"
#include "perform.h"
#include "kb_input.h"
#include "mon_outp.h"
#include "err_mess.h"
#include "mousec.h"

#if (ACT_OP_SYSTEM == RDOS)
#include "rdos.h"
#endif

/****************************************************************
*                                                               *
*  BENUTZTE UNTERPROGRAMME / GLOBALE VARIABLEN                  *
*                                                               *
****************************************************************/

#define SMALL_BUFFERS_WG_CODEVIEW 0

/* zum debuggen kann der history-buffer verkleinert werden,   */
/* codeview nimmt sonst zuviel speicher weg. das abspeichern  */
/* des history-buffers im file wird in dem fall unterdrueckt. */


/* buffer speichert strings in voller laenge ab.        */
/* dargestellt werden nur die ersten window_length chars. */

#if SMALL_BUFFERS_WG_CODEVIEW
#define BUFFER_SIZE 2           /* fuer debug */
#else
#define BUFFER_SIZE BUF_256     /* normal */
#endif

struct HIST {char delete_protected;
             char text [BUFFER_SIZE];
                        };

static struct HIST hist [HIST_NUM] [HIST_SIZE];

#define max_text   sizeof (hist [0][0].text)
#define max_total  sizeof (hist [0][0])

static int window_length;    /* = f (strlen (...text)) */

/* -FF-  */

/* Darstellung des History Windows */

/* PROM-Tabelle */
static const char semi_grafik [] [4]      /* 2. index = 0 : ASCII  */
                                          /*          = 1 : VGA    */
                                          /*          = 2 : VT100  */
                                          /*          = 3 : ANSI   */
                = {  /*  0           1     2    3   */
   /* DEL_PROT_CHAR */  '*',  (char)254,  '*', '*',   /* 0xfe */

   /* GR_TOP_LEFT   */  '+',  (char)218,  'l', 'Z',   /* 0xda */
   /* GR_TOP_RIGHT  */  '+',  (char)191,  'k', '?',   /* 0xbf */
   /* GR_BOT_LEFT   */  '+',  (char)192,  'm', '@',   /* 0xc0 */
   /* GR_BOT_RIGHT  */  '+',  (char)217,  'j', 'Y',   /* 0xd9 */

   /* GR_TICK_RIGHT */  '+',  (char)195,  't', '4',   /* 0xc3 */
   /* GR_TICK_LEFT  */  '+',  (char)180,  'u', 'C',   /* 0xb4 */
   /* GR_TICK_DOWN  */  '+',  (char)194,  'w', 'B',   /* 0xc2 */
   /* GR_TICK_UP    */  '+',  (char)193,  'v', 'A',   /* 0xc1 */

   /* GR_VERTICAL   */  '|',  (char)179,  'x', '3',   /* 0xb3 */
   /* GR_HORIZONT   */  '-',  (char)196,  'q', 'D',   /* 0xc4 */
   /* GR_CROSS      */  '+',  (char)197,  'n', 'E'    /* 0xc5 */
                  };

enum SEMIGRAF_INDEX
       {
         IND_DEL_PROT_CHAR,

         IND_GR_TOP_LEFT,
         IND_GR_TOP_RIGHT,
         IND_GR_BOT_LEFT,
         IND_GR_BOT_RIGHT,

         IND_GR_TICK_RIGHT,
         IND_GR_TICK_LEFT,
         IND_GR_TICK_DOWN,
         IND_GR_TICK_UP,

                 IND_GR_VERTICAL,
         IND_GR_HORIZONT,
         IND_GR_CROSS
       };


#define DEL_PROT_CHAR  (semi_grafik [IND_DEL_PROT_CHAR] [graf_index])

#define GR_TOP_LEFT    (semi_grafik [IND_GR_TOP_LEFT]   [graf_index])
#define GR_TOP_RIGHT   (semi_grafik [IND_GR_TOP_RIGHT]  [graf_index])
#define GR_BOT_LEFT    (semi_grafik [IND_GR_BOT_LEFT]   [graf_index])
#define GR_BOT_RIGHT   (semi_grafik [IND_GR_BOT_RIGHT]  [graf_index])

#define GR_TICK_RIGHT  (semi_grafik [IND_GR_TICK_RIGHT] [graf_index])
#define GR_TICK_LEFT   (semi_grafik [IND_GR_TICK_LEFT]  [graf_index])
#define GR_TICK_DOWN   (semi_grafik [IND_GR_TICK_DOWN]  [graf_index])
#define GR_TICK_UP     (semi_grafik [IND_GR_TICK_UP]    [graf_index])

#define GR_VERTICAL    (semi_grafik [IND_GR_VERTICAL]   [graf_index])
#define GR_HORIZONT    (semi_grafik [IND_GR_HORIZONT]   [graf_index])
#define GR_CROSS       (semi_grafik [IND_GR_CROSS]      [graf_index])


static int graf_index = (ACT_SERVER == SERVER_VT_100);

/* only one array for all functions: NEW !! 23.06.94 */
static char pathname [BUF_256 + FILENAME_LEN];


/****************************************************************
*                                                               *
*  ENDE DER DEKLARATIONEN                                       *
*                                                               *
****************************************************************/

/* -FF-  */

#if 0

   format of entries in (binary) history-file :
   ============================================

   3 1:the quick brown fox ...'\0'<cr><lf>
   | |||                      |   |
   | |||                      |   +-- for possible editing with any text-editor
   | |||                      |
   | |||                      +-- end of string
   | |||
   | ||+-- text with all ASCII-characters except '\0'
   | ||
   | |+-- marker for begin of text
   | |
   | +-- delete protected
   |
   +-- history id

#endif

/* -FF-  */

void set_grafik_status (int flag)
{
/* flag   graf_index   mode  */
/* ------------------------- */
/*   0 -----> 0        ASCII */
/*   1 --+--> 1        VGA   */
/*   1   `--> 2        VT100 */
/*   2 -----> 3        ANSI  */

   if      (flag == 1) graf_index = 1 + (ACT_SERVER == SERVER_VT_100);
   else if (flag == 2) graf_index = 3;   /* ANSI    */
   else if (flag == 3) graf_index = 1;   /* ANSI/PC */
   else                graf_index = 0;   /* ASCII   */

   return;
}  /* set_grafik_status */

/* -FF-  */

void plot_rectangle (int top, int left, int bot, int right)
{
/* plot rectangle with given koordinates on screen. */

/* the upper left corner has coordinates (0,0) */

int row, col;

   push_cursor ();

   if (graf_index >= 2)
      set_grafik_on (graf_index-2);

/* 1. upper horizontal line (incl. corners) */
   row = top;
   col = left;
   set_cursor_to (row, col);

   out_1_char (GR_TOP_LEFT, 1);
   for (col = (left + 1) ; col < right ; col++)
   {
          out_1_char (GR_HORIZONT, 1);
   }
   out_1_char (GR_TOP_RIGHT, 1);


/* 2. lower horizontal line (incl. corners) */
   row = bot;
   col = left;
   set_cursor_to (row, col);

   out_1_char (GR_BOT_LEFT, 1);
   for (col = (left + 1) ; col < right ; col++)
   {
      out_1_char (GR_HORIZONT, 1);
   }
   out_1_char (GR_BOT_RIGHT, 1);


/* 3. left vertical line (excl. corners) */
   col = left;
   for (row = (top + 1) ; row < bot ; row++)
   {
      set_cursor_to (row, col);
      out_1_char (GR_VERTICAL, 1);
   }


/* 4. right vertical line (excl. corners) */
   col = right;
   for (row = (top + 1) ; row < bot ; row++)
   {
      set_cursor_to (row, col);
      out_1_char (GR_VERTICAL, 1);
   }


#if 0
/* 5. clear content of window */
   for (row = (top + 1) ; row < bot ; row++)
   {
      col = left + 1;
      set_cursor_to (row, col);
      for (col = (left + 1) ; col < right ; col++)
      {
         out_1_char (' ', 1);
      }
   }
#endif

   if (graf_index >= 2)
          set_grafik_off (graf_index-2);

   pop_cursor ();

   return;

}  /* plot_rectangle */

/* -FF-  */

static void plot_content (enum HIST_ID id, int select_line)
{
int entry;

/* loop for all entries up to the selected one */
   for (entry = (HIST_SIZE-1) ; entry >= select_line ; entry--)
   {
      print_history_line (id, entry, (entry == select_line), 1);
   }

   return;
}  /* plot_content */

/* -FF-  */

static int top, left, bot, right;

static void plot_history_window (enum HIST_ID id)
{
int  entry, max_len, dummy, len;

   push_cursor ();


/* bestimme max. laenge aller eintraege dieser history id */
   max_len = 0;
   for (entry = 0 ; entry < HIST_SIZE ; entry++)
   {
      len = strlen (build_modified_string (hist [id] [entry].text, 0,
                                           &dummy, &dummy));
      max_len = max (max_len, len);
   }

/* begrenzen */
   max_len = max (max_len, HIST_MIN_LEN);
   max_len = min (max_len, HIST_MAX_LEN);
   max_len = min (max_len, (COLUMNS - 5));

   window_length = max_len + 1;   /* 1 byte for DELETE_PROT_CHAR */


/* fenster mitten auf bildschirm */
   top   = (ROWS    - (HIST_SIZE     + 2)) / 2;
   left  = (COLUMNS - (window_length + 2)) / 2;
   bot   = top  + (HIST_SIZE     + 1);
   right = left + (window_length + 1);

/* begrenzen */
   top  = max (0, top);
   left = max (0, left);

/* plotten */
   plot_rectangle (top, left, bot, right);


/* history inhalt plotten */
   plot_content (id, 0);

   pop_cursor ();

   return;

}  /* plot_history_window */

/* -FF-  */

static void print_history_line (enum HIST_ID id, int entry,
                                int select_flag, int modified)
{
int row, col, dummy;
char line_buf [HIST_MAX_LEN+1];
int ii;

   push_cursor ();

   row = bot - 1 - entry;
   col = left + 1;

   if (hist [id] [entry].delete_protected)
      line_buf [0] = DEL_PROT_CHAR;
   else
      line_buf [0] = ' ';

   strncpy (&line_buf [1],
            build_modified_string (hist [id] [entry].text, 0,
                                   &dummy, &dummy),
            (window_length - 1));
   line_buf [window_length] = '\0';   /* forced end of string */

   set_cursor_to (row, col);

/* display 1 line */
   out_1_char (line_buf[0], 0);

   if (select_flag) set_invers_mode ();
   out_string (&line_buf[1]);

#if (!INVERT_WHOLE_LINE)
   if (select_flag) set_normal_mode ();
#endif

   if ((INVERT_WHOLE_LINE) || (modified))
   {
      for (ii = strlen (line_buf) ; ii < window_length ; ii++)
      {
         out_1_char (' ', 0);    /* fill rest of line with blanks */
      }
   }

#if (INVERT_WHOLE_LINE)
   if (select_flag) set_normal_mode ();
#endif

/* cursor to end of line */
   if (select_flag)
          set_cursor_to (row, right);

   pop_cursor ();

   return;
}  /* print_history_line */

/* -FF-  */

char *get_history_buffer (enum HIST_ID id)
{
int entry, key, ii, return_flag;
char *return_text = NULL;

/* video output ON ? */
   if (!get_video_active (0)) return NULL;

   entry = 0;
   plot_history_window (id);

#if (WITH_MOUSE)
   MouSetMoveArea (0,   0,
                   0, 255,
                   1);
#endif

#if (ACT_SERVER == SERVER_VT_100)
   text_area++;
#endif

/* command loop */
   return_flag = 0;
   while (return_flag == 0)
   {
      key = get_1_key (0);
      switch (key)
      {
         case KEY_UP:
            print_history_line (id, entry, 0, 0);
            entry = (entry + 1) % HIST_SIZE;
            print_history_line (id, entry, 1, 0);
            break;

         case KEY_DOWN:
            print_history_line (id, entry, 0, 0);
            entry = ((entry - 1) + HIST_SIZE) % HIST_SIZE;
            print_history_line (id, entry, 1, 0);
            break;

#if (ACT_OP_SYSTEM == SCO_UNIX)
                 case KEY_RUBOUT:    /* rubout */
#endif
         case KEY_DEL:
            if (hist [id][entry].delete_protected)
            {
               beep ();
            }
            else
            {
               for (ii = entry ; ii < (HIST_SIZE-1) ; ii++)
               {
                  memcpy (&hist [id][ii], &hist [id][ii+1], max_total);
               }
               memset (&hist [id][HIST_SIZE-1], 0, max_total);
            }
            plot_content (id, entry);
            write_history_file (0);
            break;

         case KEY_INS:
            if (*hist [id][entry].text)               /* no empty lines */
            {
               hist [id][entry].delete_protected++;   /* toggle protect mode */
               hist [id][entry].delete_protected &= 1;
               print_history_line (id, entry, 1, 0);
                           write_history_file (0);
            }
            break;

#if (VAR_EOLN)
         case 0x0d:    /* <cr>     */
         case 0x0a:    /* <lf>     */
         case 0x0d0a:  /* <cr><lf> */
#else
         case C_R:     /* <cr> */
#endif
            refresh_display_window (top, left, bot, right);
            return_flag = 1;
            return_text = hist [id][entry].text;
            break;

         case 0x1b:    /* <esc> */
         case 0x03:    /* ^C */
            refresh_display_window (top, left, bot, right);
            return_flag = 1;
            return_text = NULL;
            break;

         case KEY_DO_NOTHING:
            break;

         default:
            beep ();
            break;
      }
   }  /* while */

#if (WITH_MOUSE)
   MouSetMoveArea ( 0                , (byte) TOP_ROW,
                   (byte) (COLUMNS-1), (byte) MAX_ROW,
                    -1);
#endif

#if (ACT_SERVER == SERVER_VT_100)
   text_area--;
#endif

   return (return_text);
}   /* get_history_buffer */

/* -FF-  */

int read_history_file (void)
{
enum HIST_ID id, old_id;
int entry, key = 0, ii;
FILE *fp;
#define RESERVE 100    /* fuer eintrag vor text */
STATIC char line_buf [BUF_256 + RESERVE];
char *line_ptr;
int  delete_prot, err_flag;
char *str_ptr;

   err_flag = 0;  /* default: no error */

   show_status_line_2 ("*** searching history file ***", 0, -2, 0);


/* build filename */
   strcpy (pathname, HOME_DIR);
   strcat (pathname, FILE_SEPARATOR);
   strcat (pathname, HISTO_FILENAME);

/* open file */
   fp = fopen (pathname, "rb");
   if (fp == NULL)           /* file doesn't exist */
   {
      return -1;  /* error */
   }
   else
   {
      show_status_line_2 ("*** reading history file ***", 0, -2, 0);

      entry = 0;
      old_id = (enum HIST_ID) (-1);  /* unknown id */

   /* loop for all entries */
      for (;;)
      {
      /* read line_buf binary */
         line_ptr = line_buf;

         for (ii = 0 ; ii < sizeof(line_buf) ; ii++)
         {
            key = fgetc (fp);
            *line_ptr = (char) key;
            line_ptr++;

            if ((key == '\0') ||    /* end of string */
                (key == EOF))       /* end of file   */
               break;
         }
         fgetc (fp);   /* <cr> <lf> ueberlesen */
         fgetc (fp);
         line_buf [sizeof(line_buf) - 1] = '\0';  /* forced end of string */

         if ((key != '\0') && (key != EOF))
         {
            err_flag = 1;  /* line to long */
            continue;
         }

      /* line_buf auswerten */
         if (key == EOF)
         {
            break;
         }
         else
         {
            sscanf (line_buf, "%d %d", &id, &delete_prot);

            if ((id >= 0) && (id < HIST_NUM))
            {
            /* search for begin of string (1.st char after ':') */
               str_ptr = line_buf;
               for (ii = 0 ; ii < max_text ; ii++)
               {
                  if (*str_ptr == ':') break;
                  str_ptr++;
               }

               if (*str_ptr != ':')
               {
                  err_flag = 3;    /* no ':' in this line */
                  continue;
               }
               str_ptr++;

               if (id != old_id)    /* new id ? */
               {
                  old_id = id;
                  entry = 0;
               }

            /* line to long */
               if (strlen (str_ptr) >= max_text)
               {
                  err_flag = 4;
                  continue;
               }

            /* no errors occured */
               hist [id][entry].delete_protected = (char) delete_prot;
               memcpy (hist [id][entry].text, str_ptr, max_text);

                        /* forced end of string */
               hist [id][entry].text [max_text - 1] = '\0';

            /* count up */
               entry = (entry + 1) % HIST_SIZE;
            }
            else
            {
               err_flag = 2;  /* bad hist_id */
               continue;
            }
         }
      }  /* for (;;) */
      fclose (fp);

      if (err_flag)
      {
         err_message (INVALID_HISTORY_ENTRY);
         return -2;  /* error */
      }
      else
      {
         show_status_line_2 ("*** got history file ***", 0, -2, 0);
         return 1;   /* o.k. */
      }
   }
}  /* read_history_file */

/* -FF-  */

int write_history_file (int status)
{
/* status = 0: set flag file_modified */
/* status = 1: write file, if modified */
static int file_modified;

enum HIST_ID id;
int entry;
FILE *fp;
char *text_ptr;


#if (SMALL_BUFFERS_WG_CODEVIEW)

   return 0;    /* writing of file is switched off */

#else

/* fallunterscheidung */
   if (status == 0)
   {                        /* internal call from history */
      file_modified = 1;    /* set flag */
   }
   else
   {                        /* call from mbedit at end of edit */
      if (file_modified)
      {
         show_status_line_2 ("*** writing history file ***", 0, -2, 0);

      /* build filename */
         strcpy (pathname, HOME_DIR);
         strcat (pathname, FILE_SEPARATOR);
         strcat (pathname, HISTO_FILENAME);

      /* open file */
         fp = fopen (pathname, "wb");
         if (fp == NULL)           /* file doesn't exist */
         {
            return -1;  /* error */
         }
         else
         {
         /* write history entries */
            for (id = 0 ; id < HIST_NUM ; id++)
            {
                           for (entry = 0 ; entry < HIST_SIZE ; entry++)
               {
                  text_ptr = hist [id][entry].text;
                  if (*text_ptr)
                  {
                  /* hist_id + protect-flag */
                     fprintf (fp, "%2d %d:",
                                   id,
                                   hist [id][entry].delete_protected);

                  /* string (mit allen sonderzeichen !) */
                     fwrite (text_ptr, 1, strlen (text_ptr), fp);

                  /* ende kennung */
                     fputc ('\0', fp);   /* end of string */
                     fputc (0x0d, fp);   /* <cr> */
                     fputc (0x0a, fp);   /* <lf> */
                  }
               }
            }

            fclose (fp);
            show_status_line_2 ("*** history file written ***", 0, -2, 0);
         }

                 file_modified = 0;  /* reset flag */
      }
   }

   return 1;  /* o.k. */

#endif

}  /* write_history_file */

/* -FF-  */

#if (WITH_LAST_AGAIN)

int read_status_file (void)
{
FILE *fp;
int file, err_flag, values;
STATIC char line_buf [BUF_256];

   err_flag = 0;  /* default: no error */

   show_status_line_2 ("*** searching status file ***", 0, -2, 0);

/* build filename */
#if (WITH_LAST_AGAIN == 1)
   strcpy (pathname, HOME_DIR);
#else
   strcpy (pathname, ".");
#endif
   strcat (pathname, FILE_SEPARATOR);
   strcat (pathname, STATS_FILENAME);


/* open file */
   fp = fopen (pathname, "r");
   if (fp == NULL)           /* file doesn't exist */
   {
      return -1;  /* error */
   }
   else
   {
      show_status_line_2 ("*** reading status file ***", 0, -2, 0);

   /* loop for all entries */

      for (file = 0 ; file < MAX_FC_NUM ; file++)
      {
         if (fgets (line_buf, sizeof(line_buf), fp) == NULL)
            break;   /* EOF */

         mini_file_num = max (mini_file_num, (file+1));
#if (ACT_OP_SYSTEM == MS_DOS) || (ACT_OP_SYSTEM == WIN_32) || (ACT_OP_SYSTEM == RDOS)
         values = sscanf (line_buf, "%d \"%[^\"]\" %ld",
                            &mini_control[file].view_only,
                             mini_control[file].filename,
                            &mini_control[file].byte_index);
#else
         values = sscanf (line_buf, "%d %s %ld",
                            &mini_control[file].view_only,
                             mini_control[file].filename,
                            &mini_control[file].byte_index);
#endif
         if (values != 3)
            err_flag = 2;  /* bad number of arguments */
      }  /* for file */
      fclose (fp);

      if (err_flag)
      {
         err_message (INVALID_STATUS_ENTRY);
         return -2;  /* error */
      }
      else
      {
                 show_status_line_2 ("*** got status file ***", 0, -2, 0);
         return 1;   /* o.k. */
      }
   }
}  /* read_status_file */

/* -FF-  */

int write_status_file (void)
{
int file;
FILE *fp;

   show_status_line_2 ("*** writing status file ***", 0, -2, 0);

/* build filename */
#if (WITH_LAST_AGAIN == 1)
   strcpy (pathname, HOME_DIR);
#else
   strcpy (pathname, ".");
#endif
   strcat (pathname, FILE_SEPARATOR);
   strcat (pathname, STATS_FILENAME);

/* open file */
   fp = fopen (pathname, "w");
   if (fp == NULL)           /* file doesn't exist */
   {
      return -1;  /* error */
   }
   else
   {
   /* write file infos */
      for (file = 0 ; file < set.file_num ; file++)
      {
         if ((file_control[file].malloc_flag) &&
             (*file_control[file].filename))
         {
         /* file_id, view_only-flag, filename + position */
#if (ACT_OP_SYSTEM == MS_DOS) || (ACT_OP_SYSTEM == WIN_32) || (ACT_OP_SYSTEM == RDOS)
            fprintf (fp, "%d \"%s\" %6ld\n",
                          file_control[file].view_only,
                          file_control[file].filename,
                          file_control[file].byte_index);
#else
            fprintf (fp, "%d %-14s %6ld\n",
                          file_control[file].view_only,
                          file_control[file].filename,
                          file_control[file].byte_index);
#endif
                 }
      }

      fclose (fp);
      show_status_line_2 ("*** history file written ***", 0, -2, 0);
   }

   return 1;  /* o.k. */

}  /* write_status_file */

#endif

/* -FF-  */

void save_history_string (enum HIST_ID id, char *string)
{
int  entry, start_ind, modified;
char del_prot;

/* video output ON ? */
   if (!get_video_active (0)) return;

/* if empty string, return */
   if (*string == '\0') return;

/* set flags to default */
   modified = 0;
   del_prot = 0;

/* search, if new string is already in history buffer */
   start_ind = -1;  /* default: not found */

   for (entry = (HIST_SIZE-1) ; entry >= 0 ; entry--)
   {
      if (strncmp (hist [id][entry].text, string, max_text) == 0)
      {
         start_ind = entry;
         del_prot  = hist [id][entry].delete_protected;  /* keep status of entry */
         if (entry > 0) modified = 1;
         break;
      }
   }

/* not found ? */
   if (start_ind < 0)
   {
   /* then search for last entry without protection */
      for (entry = (HIST_SIZE-1) ; entry >= 0 ; entry--)
      {
                 if (!hist [id][entry].delete_protected)
         {
            start_ind = entry;
            modified = 1;
            break;
         }
      }
   }

/* found deletable entry ? */
/* (hint: in xtree are always at least 2 entrys without protection) */
   if (modified)
   {
   /* shift all entries from found entry to newest */
      for (entry = start_ind ; entry > 0 ; entry--)
      {
         memcpy (&hist [id][entry], &hist [id][entry-1], max_total);
      }

   /* store new entry in buffer */
      memcpy (hist [id][0].text, string, max_text);
      hist [id][0].text [max_text - 1] = '\0';   /* forced end of string */
      hist [id][0].delete_protected = del_prot;

      write_history_file (0);
   }

   return;

}  /* save_history_string */

/* -FF-  */

static void limit_at_1st_blank (char *string)
{
/* example: converts "abcd efg" */
/*                to "abcd"     */

   while (*string)
   {
      if (*string == ' ')
      {
         *string = '\0';    /* forced end of string */
         break;
      }

      string++;
   }

   return;

}  /* limit_at_1st_blank */

/* -FF-  */

char *get_home_dir (void)
{
static char *path;
#define DEFAULT_PATH "."

#if (ACT_OP_SYSTEM == RDOS)
        const char *exename;
        static char str[256];
        int pos;
#endif

   path = getenv(":HOME:");
   if (path)
   {
          limit_at_1st_blank (path);
          if (*path)
                 return path;
   }

   path = getenv("HOME");
   if (path)
   {
          limit_at_1st_blank (path);
          if (*path)
                 return path;
   }

#if (ACT_OP_SYSTEM == RDOS)

        exename = RdosGetExeName();

        strcpy(str, exename);
        pos = strlen(str) - 1;
        while (pos && str[pos] != '\\')
                pos--;

        str[pos] = 0;

        if (pos)
                return str;

#endif

   return DEFAULT_PATH;

}  /* get_home_dir */

/* -FF-  */

/* Modification History */
/* 08.01.93 - file erzeugt */
/* 11.06.93 - Xterm gestrichen */
/* 28.08.93 - STATIC */
/* 10.09.93 - get_home_dir() */
/* 12.09.93 - get_video_active (ignore_batch) */
/* 12.09.93 - show_status_line_2 (..., ignore_batch) */
/* 04.11.93 - plot_rectangle: static --> extern */
/* 06.11.93 - plot_content: ohne modified */
/* 29.11.93 - semigrafik abschaltbar */
/* 01.12.93 - GRAFIK_OFF */
/* 06.12.93 - GRAFIK_OFF --> mon_outp.c */
/* 11.12.93 - hist_window_active */
/* 15.12.93 - build_modified_string (..., int *error) */
/* 20.12.93 - text_area */
/* 09.02.94 - limit_at_1st_blank () */
/* 17.05.94 - VERSION_SCO, KEY_RUBOUT, HDS */
/* 20.05.94 - save + restore last filenames + positions */
/* 21.05.94 - write_status_file(), read_status_file() */
/* 23.06.94 - only one array pathname [] */
/* 23.06.94 - WITH_LAST_AGAIN = 0, 1, 2 */
/* 06.10.94 - semigrafik for ANSI */
/* 24.02.95 - tabelle semi_grafik: dez. zahlen */
/* 05.09.98 - VAR_EOLN */
/* 14.02.04 - out_1_char (int key, int rectangle) */
