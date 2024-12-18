/*      mouser.c                            14.03.95       */
/*!
/  --------------------------------------------------------------
/  Copyright (C) 1993: Michael Braun
/                      Kaetinger Muehlenweg 103 A
/                      D-28816 Stuhr
/  --------------------------------------------------------------
/
/    handling of mouse events
/
/
/    Copyright Note:
/    This program was developed on the base of a chapter in
/    the following book. It has been carried on and adapted
/    to the special requirements of mbedit by M. Braun.
/
/       Title    : PC intern 3.0
/       Author   : Michael Tischer
/       Publisher: Data Becker, Duesseldorf
/       ISBN     : 3-89011-591-8
/       1st edition 1992
/
*/

/*== Include-Dateien einbinden =======================================*/

#include "config.h"
#include "global.h"
#include "standard.h"
#include "mousec.h"
#include "mbedit.h"
#include "perform.h"
#include "history.h"
#include "disp_hnd.h"
#include "mon_outp.h"
#include "mbed_sub.h"
#include "kb_input.h"
#include "rdos.h"

/*== Konstanten ======================================================*/

/*-- Makros zur Erstellung der Bit-Maske, die das Erscheinungsbild ---*/
/*-- des Maus-Cursors definiert.                                   ---*/
/*-- Der Aufruf von MouPtrMask lautet beispielsweise:              ---*/
/*--   MouPtrMask( PTRDIFCHAR( 'x' ), PTRINVCOL )                  ---*/
/*-- um den Maus-Cursor als ein kleines X darzustellen, das die    ---*/
/*-- invertierte Farbe des Zeichens tr„gt, das von ihm berdeckt   ---*/
/*-- wird.                                                         ---*/

/*-- Event-Codes -----------------------------------------------------*/

#define EV_MOU_MOVE      1                             /* Maus bewegt */
#define EV_LEFT_PRESS    2            /* linker Mausknopf niedergedr. */
#define EV_LEFT_REL      4            /* linker Mausknopf losgelassen */
#define EV_RIGHT_PRESS   8           /* rechter Mausknopf niedergedr. */
#define EV_RIGHT_REL    16           /* rechter Mausknopf losgelassen */
#define EV_MOU_ALL      31                        /* alle Maus-Events */

#define KEIN_BEREICH 255           /* Maus-Cursor nicht in Bereich xy */

/*-- Makros ----------------------------------------------------------*/

#define MouGetCol()         (ev_col)        /* liefern Mausposition & */
#define MouGetRow()         (ev_row)        /* -bereich im Moment des */
#define MouGetBereich()     (ev_ber)        /* Event-Eintritts        */
#define MouAvail()          ( mavail )  /* liefert TRUE, wenn Maus v. */
#define MouGetAktCol()      ( moucol )       /* liefern jeweils aktu- */
#define MouGetAktRow()      ( mourow )       /* elle Mausposition und */
#define MouGetAktBer()      ( mouber )       /* aktuellen Mausbereich */
#define MouIsLeftPress()    ( mouevent & EV_LEFT_PRESS )
#define MouIsLeftRel()      ( mouevent & EV_LEFT_REL )
#define MouIsRightPress()   ( mouevent & EV_RIGHT_PRESS )
#define MouIsRightRel()     ( mouevent & EV_RIGHT_REL )

#define MouPtrMask( z, f )\
  ( (( (PTRVIEW) f) >> 8 << 24) + ((( PTRVIEW) z) >> 8 << 16) +\
    (((f) & 255) << 8) + ((z) & 255) )

#define PTRSAMECHAR   ( 0x00ff )        /* gleiches Zeichen           */
#define PTRDIFCHAR(z) ( (z) << 8 )      /* anderes Zeichen            */
#define PTRSAMECOL    ( 0x00ff )        /* gleiche Farbe              */
#define PTRINVCOL     ( 0x7777 )        /* Farbe invertiert           */
#define PTRSAMECOLB   ( 0x807f )        /* gleiche Farbe blinkend     */
#define PTRINVCOLB    ( 0xF777 )        /* invertierte Farbe blinkend */
#define PTRDIFCOL(f)  ( (f) << 8 )      /* andere Farbe               */
#define PTRDIFCOLB(f) (((f)|0x80) << 8) /* andere Farbe blinkend      */

/*-- Makros zur Umrechnung zwischen Maus-Koordinaten in Bezug auf den */
/*-- virtuellen Maus-Bildschirm und dem Textbildschirm                */

#define XTOCOL(x) ( ((x) >> 3) )          /* Rundung ! */   /* X durch 8 */
#define YTOROW(y) ( ((y) >> 3) )                            /* Y durch 8 */
#define COLTOX(c) ( ((c) << 3) + 4)                         /* C mal 8 */
#define ROWTOY(r) ( ((r) << 3) + 4)                         /* R mal 8 */

/*== globale Variablen ===============================================*/

static char tline,                              /* Anzahl Text-Zeilen */
            tcol,                              /* Anzahl Text-Spalten */
            mavail = FALSE;          /* ist TRUE, wenn Maus verfgbar */

/*-- Maske fr den Standard-Maus-Cursor ------------------------------*/

static int  mouevent = EV_LEFT_REL + EV_RIGHT_REL;     /* Event-Maske */
static char moucol,                   /* Mausspalte (Text-Bildschirm) */
            mourow;                   /* Mauszeile  (Text-Bildschirm) */

static char center_col = (INIT_COLUMNS / 2);
static char center_row = (INIT_ROWS / 2);
static char old_win_row, old_win_col;
static int  event_count, disp_window_active;
static int mouse_on_off_status = 0;

#define STACK_SIZE 3

struct WORK_AREA
   {
      char x1, y1, x2, y2;
      char save_row, save_col;
      int  win_flag;
   };

static struct WORK_AREA work_area [STACK_SIZE];
static int stack_ind;

static int left_pressed = 0;
static int right_pressed = 0;

/***********************************************************************
*  Funktion         : update_mouse                    *
**--------------------------------------------------------------------**
*  Aufgabe          : Wird vom Maustreiber ber die Assembler-Routine  *
*                     AssHand aufgerufen, sobald ein Ereignis in Ver-  *
*                     bindung mit der Maus eingetreten ist.            *
*  Eingabe-Parameter: EvFlags  = Event-Maske des Ereignis              *
*                     ButState = Status der Mauskn”pfe                 *
*                     X, Y     = die aktuelle Position des Maus-Cur-   *
*                                sors, bereits umgerechnet in das Ko-  *
*                                ordinatensystem des Textbildschirms   *
*  Return-Wert      : keiner                                           *
*  Info             : - Diese Funktion ist nur zum Aufruf durch den    *
*                       Maus-Treiber bestimmt und darf nicht von einer *
*                       anderen Funktion aufgerufen werden.            *
***********************************************************************/
void update_mouse(void)
{
#define LBITS ( EV_LEFT_PRESS | EV_LEFT_REL )
#define RBITS ( EV_RIGHT_PRESS | EV_RIGHT_REL )

 static char oldcol, oldrow;

 int x, y;
 int EvFlags = 0;

 if (RdosGetLeftButton())
 {
        if (!left_pressed)
        {
          EvFlags |= EV_LEFT_PRESS;
          left_pressed = 1;
          RdosGetLeftButtonPressPosition(&x, &y);
        }
 }
 else
 {
        if (left_pressed)
        {
          EvFlags |= EV_LEFT_REL;
          left_pressed = 0;
          RdosGetLeftButtonReleasePosition(&x, &y);
        }
 }

 if (RdosGetRightButton())
 {
        if (!right_pressed)
        {
          EvFlags |= EV_LEFT_PRESS;
          right_pressed = 1;
          RdosGetRightButtonPressPosition(&x, &y);
        }
 }
 else
 {
        if (right_pressed)
        {
          EvFlags |= EV_LEFT_REL;
          right_pressed = 0;
          RdosGetRightButtonReleasePosition(&x, &y);
        }
 }

 if (!EvFlags)
 {
        EvFlags = EV_MOU_MOVE;
        RdosGetMousePosition(&x, &y);
 }

 mouevent &= ~1;                                  /* Bit 0 ausblenden */
 mouevent |= ( EvFlags & 1 );           /* Bit 0 aus EvFlags kopieren */

 if ( EvFlags & LBITS )      /* linker Mausknopf losg. oder niederg.? */
 {                                                             /* Ja */
   mouevent &= ~LBITS;                /* bisherigen Status ausblenden */
   mouevent |= ( EvFlags & LBITS );        /* neuen Status einblenden */
 }

 if ( EvFlags & RBITS )     /* rechter Mausknopf losg. oder niederg.? */
 {                             /* Ja, Bits ausblenden und einblenden */
   mouevent &= ~RBITS;                /* bisherigen Status ausblenden */
   mouevent |= ( EvFlags & RBITS );        /* neuen Status einblenden */
 }

 moucol = (char) XTOCOL(x);         /* Spalte in Textspalten umrechnen */
 mourow = (char) YTOROW(y);           /* Zeile in Textzeilen umrechnen */


 if ((mourow != oldrow) ||   /* ignore minor movements */
          (moucol != oldcol) ||   /* in the pixel position. */
          (EvFlags & LBITS)  ||   /* handle every button event. */
     (EvFlags & RBITS))
    event_count++;

 oldrow = mourow;
 oldcol = moucol;

 return;
}  /* MouEventHandler */


int mouse_event (void)
{
   return (event_count != 0);
}  /* mouse_event */


int mouse_event_handler_c (int repeat)
{
   static int old_col, phase;
        static unsigned long time_start, time_act;
        static unsigned long msec10_start, msec10_act;
        unsigned long msb;

#define TIME_DELAY 11930    /* 10 msec */

   int  new_col, delta_line, key, ii;
   long new_line, new_index;

#define SLOW_DOWN  1    /* 1: max. mouse speed */
                            /* 2: reduced "    "   */

   static int left_button_tab [] =
           {
              0x00,     /* 0: normal mode */
              0x0d,     /* 1: history window */
              0x0d,     /* 2: filename window */
              0x1b,     /* 3: get_line_2_string */
               'E',     /* 4: hex_view */
              0x09,     /* 5: hex_edit */
           };


   if (event_count > 0)
      event_count--;

   key = 0;  /* default for standard text mode */

/* -----------------------------------------------------------------------*/

/* fallunterscheidung */
   if (disp_window_active)
   {
   /* simulate keys cursor up/down, <enter> + <esc> */

      key = KEY_DO_NOTHING;    /* default for display window */

      if (MouIsRightPress())
         key = 0x03;   /* ^C   */

      if (MouIsLeftPress())
      {
         key = left_button_tab [disp_window_active];
      }

      if ((disp_window_active <= 2) ||     /* history/filename window */
          (disp_window_active >= 4))       /* hex view/edit  */
      {
         if (mourow > old_win_row)
         {
            delta_line = mourow - old_win_row;
            for (ii = 1 ; ii < (delta_line/SLOW_DOWN) ; ii++)
            {
               set_key_fifo (KEY_DOWN);
            }
            key = KEY_DOWN;
         }

         if (mourow < old_win_row)
         {
            delta_line = old_win_row - mourow;
            for (ii = 1 ; ii < (delta_line/SLOW_DOWN) ; ii++)
            {
               set_key_fifo (KEY_UP);
            }
            key = KEY_UP;
         }
      }

      if (disp_window_active >= 3)    /* get_status_line_2_... */
      {                               /* hex editor            */
         if (moucol > old_win_col)
         {
            delta_line = moucol - old_win_col;
            for (ii = 1 ; ii < (delta_line/SLOW_DOWN) ; ii++)
            {
               set_key_fifo (KEY_RIGHT);
            }
            key = KEY_RIGHT;
         }

         if (moucol < old_win_col)
         {
            delta_line = old_win_col - moucol;
            for (ii = 1 ; ii < (delta_line/SLOW_DOWN) ; ii++)
            {
               set_key_fifo (KEY_LEFT);
            }
            key = KEY_LEFT;
         }
      }

      old_win_col = moucol;
      old_win_row = mourow;

      RdosSetMousePosition(moucol, mourow);

   /* @@ prevent multiple reads of mouse buttons !! */
      mouevent &= ~(EV_LEFT_PRESS | EV_RIGHT_PRESS);

      return (key);
   }

/* -----------------------------------------------------------------------*/

/* control repetition behaviour (delay time at begin) */
   if (!repeat)
   {
      phase = 0;        /* no repetition at all */
   }
   else
   {
      if (phase == 0)
      {
         RdosGetSysTime(&msb, &msec10_start);
         phase = 1;     /* begin of time delay */
      }

      if (phase == 1)
      {
         RdosGetSysTime(&msb, &msec10_act);

      /* before completion of time delay: abort repetition */
         if (msec10_act - msec10_start >= TIME_DELAY)
            phase = 2;  /* time delay completed */
      }
   }

/* incompleted time delay: abort repetition */
   if (phase == 1)
      return 0;

/* -----------------------------------------------------------------------*/

/* start handling */
   if (MouIsLeftPress())
   {
   /* set cursor to mouse position */
      check_dirty_cursor ();

   /* set row */
                /* diese klammern muessen sein !! */
                /*          v        v            */
      delta_line = mourow - (fc->lrow);
      if (delta_line)
      {
         new_line = fc->line_index + (long) delta_line;
         new_line = max (0L, min (fc->line_anz, new_line));
         new_index= line_to_index (fc->buff_0, 0L,
                                   fc->byte_anz, new_line);
         if (new_index < 0L)       /* behind EOF */
            new_index = fc->byte_anz;  /* set to EOF */
         perform_move (new_index);
      }

   /* set column */
      new_col = moucol + fc->left_col;
      new_col = max (0, new_col);
      new_index = act_index (fc->buff_0, fc->lin_left,
                             fc->byte_anz, new_col);
      perform_move (new_index);
      fc->column = new_col;

   /* scroll screen up/down */
      if (delta_line == 0)
      {
                        if (mourow == (char) MIN_ROW)
                                perform_key_up (1);

                        if (mourow == (char) MAX_ROW)
            perform_key_down (1);

         update_entire_window (fc->top_left);
         perform_update (fc->buff_0, fc->byte_anz, fc->left_col);

      /* set cursor */
         if (get_video_active (0))
            set_cursor_to (fc->lrow, REL_COLUMN);
      }


   /* scroll screen left/right */
      if ((char) old_col == moucol)
      {
                        if (moucol >= (char) (COLUMNS-1))
            fc->left_col++;

         if (moucol <= 0)
            fc->left_col--;

         fc->left_col = max (0, fc->left_col);
      }
      old_col = moucol;


   /* show screen, set cursor */
      refresh_1_window ();
      if (get_video_active (0))
         set_cursor_to (fc->lrow, REL_COLUMN);
   }  /* if left button pressed */

/* set flag for check_dirty_cursor() in mbedit.c */
   set_mouse_moved ();

   return key;
}  /* mouse_event_handler_c */

/***********************************************************************
*  Funktion         : M o u S h o w M o u s e                          *
**--------------------------------------------------------------------**
*  Aufgabe          : Maus-Cursor auf dem Bildschirm anzeigen.         *
*  Eingabe-Parameter: keine                                            *
*  Return-Wert      : keiner                                           *
*  Info             : Die Aufrufe von MouHidemMouse() und MouShow-     *
*                     Mouse() mssen ausbalanciert sein, damit sie     *
*                     Wirkung zeigen.                                  *
***********************************************************************/

void MouShowMouse( void )
{
 if (mouse_on_off_status == 0)
 {
    mouse_on_off_status++;
//    RdosShowMouse();
 }
}

/***********************************************************************
*  Funktion         : M o u H i d e M o u s e                          *
**--------------------------------------------------------------------**
*  Aufgabe          : Maus-Cursor vom dem Bildschirm entfernen.        *
*  Eingabe-Parameter: keine                                            *
*  Return-Wert      : keiner                                           *
*  Info             : Die Aufrufe von MouHidemMouse() und MouShow-     *
*                     Mouse() mssen ausbalanciert sein, damit sie     *
*                     Wirkung zeigen.                                  *
***********************************************************************/

void MouHideMouse( void )
{
 if (mouse_on_off_status == 1)
 {
    mouse_on_off_status--;
//    RdosHideMouse();
 }
}

/***********************************************************************
*  Funktion         : M o u S e t M o v e A r e a                      *
**--------------------------------------------------------------------**
*  Aufgabe          : Definiert den Bildschirmbereich, innerhalb dessen*
*                     sich der Maus-Cursor bewegen darf.               *
*  Eingabe-Parameter: x1, y1 = Koordinaten der oberen linken Ecke      *
*                     x2, y2 = Koordinaten der unteren rechten Ecke    *
*  Return-Wert      : keiner                                           *
*  Info             : - Beide Angaben beziehen sich auf den Textbild-  *
*                       schirm und nicht auf den virtuellen Grafik-    *
*                       bildschirm des Maustreibers                    *
***********************************************************************/
void MouSetMoveArea( char x1, char y1, char x2, char y2, int window_flag )
{
/* window_flag = 0 : normal text editing */
/*               1 : inside history window */
/*               2 : inside wildname window */
/*               3 : inside get_line_2_string */
/*               4 : inside hex view/edit */
/*              -1 : return to next lower level */

/* handle display windows (history, wildname) */
   center_col = (char) ((x1 + x2) / 2);
   center_row = (char) ((y1 + y2) / 2);

   if (window_flag == 0)
   {
      work_area[stack_ind].save_row = mourow;
      work_area[stack_ind].save_col = moucol;

      work_area[stack_ind].x1 = x1;
      work_area[stack_ind].y1 = y1;
      work_area[stack_ind].x2 = x2;
      work_area[stack_ind].y2 = y2;

      work_area[stack_ind].win_flag = window_flag;
   }

   if (window_flag > 0)   /* save old cursor position */
   {
      work_area[stack_ind].save_row = mourow;
      work_area[stack_ind].save_col = moucol;

      stack_ind++;
      stack_ind = min (stack_ind, (STACK_SIZE-1));

      work_area[stack_ind].x1 = x1;
      work_area[stack_ind].y1 = y1;
      work_area[stack_ind].x2 = x2;
      work_area[stack_ind].y2 = y2;

      work_area[stack_ind].win_flag = window_flag;

      moucol = center_col;
      mourow = center_row;
   }

   if (window_flag < 0)   /* restore old cursor position */
   {
      stack_ind--;
      stack_ind = max (stack_ind, 0);

      mourow = work_area[stack_ind].save_row;
      moucol = work_area[stack_ind].save_col;

      x1 = work_area[stack_ind].x1;
      y1 = work_area[stack_ind].y1;
      x2 = work_area[stack_ind].x2;
      y2 = work_area[stack_ind].y2;
   }

   disp_window_active = work_area[stack_ind].win_flag;

   RdosSetMouseWindow(8 * x1, 8 * y1, 8 * x2, 8 * y2);
   RdosSetMousePosition(moucol, mourow);

   return;
}

/***********************************************************************
*  Funktion         : M o u E n d                                      *
**--------------------------------------------------------------------**
*  Aufgabe          : Beendet die Arbeit mit den Funktionen des Mousec-*
*                     Moduls.                                          *
*  Eingabe-Parameter: keine                                            *
*  Return-Wert      : keiner                                           *
*  Info             : Die Funktion wird bei der Beendigung eines Pro-  *
*                     gramms automatisch aufgerufen, sofern zuvor      *
*                     MouInstall aufgerufen wurde.                     *
***********************************************************************/

void MouEnd( void )
{
//    RdosHideMouse();
}

/***********************************************************************
*                   S T A R T U P    P R O G R A M M                   *
***********************************************************************/

int MouStartup (int columns, int rows)
{
    RdosSetMouseWindow(0, 0, 8 * columns, 8 * rows);
    RdosSetMouseMickey(8, 8);
        RdosSetMousePosition(columns / 2, rows / 2);
    mavail = TRUE;                        /* Maus ist installiert */
    return 0;
}

/* -FF-  */

/* Modification History */
/* 10.12.92 - copied from disc of mentioned book */
/* 11.12.92 - a whole bunch of of modifications/adaptions for mbedit */
/* 12.12.93 - handling of history windows */
/* 14.12.93 - handling of status line 2 */
/* 26.09.94 - MouSetMoveArea(): window_flag = 4/5 (hex view/edit) */
/* 27.09.94 - type cast(s) wg. compiler warnings (microsoft c 6.0) */
/* 09.03.95 - Handling of other resolutions than 80 x 25 (not yet o.k.) */
/* 14.03.95 - more tests for higher resolutions (not yet o.k.) */
