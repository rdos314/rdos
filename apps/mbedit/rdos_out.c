
/* This program was written originally by Raimund Spaeth.
   I have made the following modifications:

          - printd disabled
          - setting of ANSI colors with original <ESC> sequences
          - no special file "mbedit.mac" for WIN_32 required

   M. Braun
*/

#if 0
//----------------------------------------------------------------------------
// Bastel-"Lösung", um den von Michael Braun (e-mail: braun-m@t-online.de,
//   http://home.t-online.de/home/braun-m) veröffentlichten Multi-Platform
//   Editor "MBEDIT" (FSF GPL >= V2) auch unter Windows NT nutzen zu können.
//
// Vielleicht ist ja alles nur ein Mißverständnis: Beim Experimentieren mit
//   Suse Linux 6.4 ist mir zufällig besagter "MBEDIT" aufgefallen.
//   Wegen der netten Kombination von Calculator und Macro Recorder fand
//   ich dann dieses "old-styled" Tool recht nützlich und wollte es auch
//   unter Windows NT (4.0 SP5) mal ausprobieren.
//
// Da habe ich wohl etwas falsch gemacht: auf dem Bildschirm erschienen
//   Terminal Steuersequenzen statt lesbarem Text. Soweit ich Windows NT
//   kenne, werden <ESC> Sequenzen für 32 bit Konsol-Anwendungen ja auch
//   nicht unterstützt. Die Variante 16 bit command.com mit mit ANSI.SYS
//   und DOS-Version von "MBEDIT" macht wegen der begrenzten Puffergröße
//   in dieser Umgebung sicher keinen Sinn.
//
// Die Frage: Wie komme ich zu einer 32 bit Konsol-Version
//            von "MBEDIT" für Windows NT?
//
// Experten, bitte nicht lachen: mir ist nichts anderes (als einfache
//   "Lösung") eingefallen, als alle "MBEDIT" Ausgaben abzufangen und
//   die Terminal Steuersequenzen (minimaler Umfang) in Win32 Konsol-
//   funktionen umzusetzen.
//
// DER SOURCECODE IST SCHNELL MAL ZUSAMMENGEFLICKT: Mir fehlte die Muße
//   für Qualitätsarbeit (das generelle Freeware-Problem?). Es fehlt
//   jegliche Fehlerbehandlung, für maximale Windowsize sind willkürliche
//   Konstanten benutzt .........., die Mängelliste ließe sich (fast)
//   endlos fortsetzen. Wenn mal eines Tages so richtig Zeit vom
//   Himmel fällt, wird alles anders .......... Genug, daß ich mich
//   aufgerafft habe, diese Zeilen zu schreiben - für den "MBEDIT"
//   Autor als Feedback.
//
// Die "MBEDIT.MAC" Datei muß natürlich zu dieser einfachen Bastelei
//   passen - siehe gefilterte ESC Sequenzen (was passiert bei SW != 0?
//   was schreibt WriteConsole wohl als "bell" auf den Bildschirm? .....
//   - ich habe es nicht ausprobiert, SW0 ist für mich o.k. Aber es
//   lauern noch andere Fallgruben bei "unpassender" "MBEDIT.MAC" Datei!

//----------------------------------------------------------------------------
// Was habe ich mit den Original-Quellen von Michael Braun gemacht?
//   Nach dem letzen #include in allen .c Dateien noch ein
//   #include "ansi_out.h" eingefügt, die Dateien ansi_out.h und
//   ansi_out.c in den Trichter ..... UND EIN PASSENDE "MBEDIT.MAC"
//   DATEI NICHT VERGESSEN!
//
// Etwas Raten und Experimentieren zeigte, daß alle Ausgaben über
//   printf() und putchar() laufen. Damit werden durch
//
//     #define   printf       ansi_printf
//     #define   putchar(c)   ansi_putchar(c)
//
//   an passender Stelle alle Ausgaben "umgelenkt".
//
//                    +----------+
//                    ¦  MBEDIT  ¦
//                    +----------+
//                      ¦       ¦
//              +--------+     +---------+
//              ¦ printf ¦     ¦ putchar ¦
//              +--------+     +---------+
//                      ¦       ¦
//            +-------------+   ¦
//            ¦ ansi_printf ¦   ¦
//            +-------------+   ¦
//                      ¦       ¦
//                  +--------------+
//                  ¦ ansi_putchar ¦
//                  +--------------+
//                      ¦       ¦
//    +------------------+     +-----------------+
//    ¦ char ansi_buf[]  ¦     ¦ console_putchar ¦
//    ¦ process_ansi_buf ¦     ¦                 ¦
//    ¦                  ¦     ¦ WriteConsole    ¦
//    ¦ Set..Cursor....  ¦     +-----------------+
//    ¦ Set..TextAttr..  ¦
//    +------------------+
//
// Ach ja, und noch etwas: Die "MBEDIT" Version hatte ein global.h
//   mit "V8.17". Bei Übersetzung mit Microsoft Visual Studio V6.0 SP3
//   macht sich ein Bug in disp_hnd.c bemerkbar,
//
//     [ Die Variable "comment_type" in "disp_1_line()" ist nicht
//       als static deklariert. ]
//
//   der natürich nicht auffällt, wenn Compiler und Betriebssystem
//   zusammen ein glückliches Händchen haben, und die auto Variable
//   so im Stack liegt, daß auch durch evtl. Interupt-Behandlung
//   diese zwischen zwei Aufrufen (es geht ja um die Erkennung von
//   mehrzeiligem Kommentar!) nicht überschrieben wird.
//
// Aber mit GNU (wie in Suse Liniux 6.4 bzw. mingw32 2.95.2-msvcrt)
//   passiert weder unter Suse Linux 6.4 noch unter
//   Windows NT 4.0 SP5 etwas!
//   Die alte Binsenweisheit, daß Software manchmal eher zufällig
//   doch funktioniert, ist damit wieder einmal mehr bestätigt.
//
// Zum Schluß herzlichen Dank allen, die zum Enstehen von "MBEDIT"
//   beigetragen haben. Ich find es recht praktisch, jetzt unter
//   Windows NT und Linux mit den gleichen Tasten zum gleichen
//   Ergebnis zu kommen - und zum Thema "vi" o.ä. hier kein weiterer
//   Kommentar!
//
// 8. August 2000, Raimund Späth, 100527.1475@compuserve.com
//
// Jeder Hinweis auf eine einfachere Methode, "MBEDIT" unter
//   Windows NT als 32 bit Applikation zum Laufen zu bringen,
//   ist natürlich herzlich willkommen!

//----------------------------------------------------------------------------
// Last BUT NOT LEAST: Alles gemäß FSF GPL >= V2!
//
// KEINE GEWÄHR für ordnungsgemäße Funktion --- EXPERIMENTELLE VERSION!

//----------------------------------------------------------------------------
#endif

#include "config.h"
#include "global.h"

#include <stdio.h>
#include <stdarg.h>
#include <string.h>

#include "ansi_out.h"
#include "rdos.h"

#define FOREGROUND_BLUE      0x0009 // text color contains blue.
#define FOREGROUND_GREEN     0x000A // text color contains green.
#define FOREGROUND_RED       0x000C // text color contains red.
#define FOREGROUND_INTENSITY 0x0008 // text color is intensified.
#define BACKGROUND_BLUE      0x0001 // background color contains blue.
#define BACKGROUND_GREEN     0x0002 // background color contains green.
#define BACKGROUND_RED       0x0004 // background color contains red.
#define BACKGROUND_INTENSITY 0x0008 // background color is intensified.


static const int fg_colors [9] =
{
/* 0 = black        */ 0,
/* 1 = red          */ FOREGROUND_RED,
/* 2 = green        */                    FOREGROUND_GREEN,
/* 3 = yellow       */ FOREGROUND_RED   | FOREGROUND_GREEN,
/* 4 = blue         */                                       FOREGROUND_BLUE,
/* 5 = magenta      */ FOREGROUND_RED   |                    FOREGROUND_BLUE,
/* 6 = cyan         */                    FOREGROUND_GREEN | FOREGROUND_BLUE,
/* 7 = white        */ FOREGROUND_RED   | FOREGROUND_GREEN | FOREGROUND_BLUE,
/* 8 = bright white */ FOREGROUND_RED   | FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY,
};

static const int bg_colors [9] =
{
/* 0 = black        */ 0,
/* 1 = red          */ BACKGROUND_RED,
/* 2 = green        */                    BACKGROUND_GREEN,
/* 3 = yellow       */ BACKGROUND_RED   | BACKGROUND_GREEN,
/* 4 = blue         */                                       BACKGROUND_BLUE,
/* 5 = magenta      */ BACKGROUND_RED   |                    BACKGROUND_BLUE,
/* 6 = cyan         */                    BACKGROUND_GREEN | BACKGROUND_BLUE,
/* 7 = white        */ BACKGROUND_RED   | BACKGROUND_GREEN | BACKGROUND_BLUE, 
/* 8 = bright white */ BACKGROUND_RED   | BACKGROUND_GREEN | BACKGROUND_BLUE | BACKGROUND_INTENSITY, 
};


/*--------------------------------------------------------------------------*/

static int  display_lines = 0;

int CurrRow = 0;
int CurrCol = 0;

static char ansi_buf[40];

void get_screen_lin_col (int *lines, int *columns)
{
    *lines = 25;
    *columns = 80;
    RdosGetTextSize(lines, columns);
}

//----------------------------------------------------------------------------
// Ausgabe eines einzelnen Zeichens in Windows NT Konsole.
// Sollte theoretisch auch unter Win9x gehen, aber Vorsicht:
//   Die Konsol-Funktionen in Win9x haben einige "Features"!

void console_putchar(int c)
{
    RdosWriteChar((char)c);
}

//----------------------------------------------------------------------------
// Hier werden alle <ESC> Sequenzen bearbeitet.
// Zwischenspeicherung und Erkennung von Anfang/Ende in ansi_putchar.

void process_ansi_buf()
{
    int                          x, y, n;
    char                         c, c2;
         char                         clear_buf[BUF_256];  /* @@ [SCREEN_COLS + 2]; */
        int                                                      hl, fg, bg;
        int                                              fgc, bgc;

        if(strcmp(ansi_buf, "\033[?25h") == 0)   /* Cursor On */
        return;

    if(strcmp(ansi_buf, "\033[?25l") == 0)   /* Cursor Off */
        return;

    if(strcmp(ansi_buf, "\033[?7h") == 0)    /* Wrap On */
        return;

    if(strcmp(ansi_buf, "\033[?7l") == 0)    /* Wrap Off */
        return;

    if(strcmp(ansi_buf, "\033(0") == 0)      /* Grafik On VT100 */
        return;

    if(strcmp(ansi_buf, "\033(B") == 0)      /* Grafik Off VT100 */
        return;

    if((n = sscanf(ansi_buf, "\x1B[%c%c", &c, &c2)) == 1)
    {   
        RdosGetCursorPosition(&CurrRow, &CurrCol);
                                                         /* Cursor Position +/- 1 */
                switch(c)
        {
            case 'A':   /* Up */
                            if (CurrRow)
                    CurrRow--;
                break;

            case 'B':  /* Down */
                if (CurrRow < ROWS)
                    CurrRow++;
                break;

            case 'C':    /* Right */
                if (CurrCol < COLUMNS)
                    CurrCol++;
                break;

            case 'D':   /* Left */
                if (CurrCol)
                    CurrCol--;
                break;

            default:    /* printd("Hoppla, Cursor +-1 mit ubekannter Richtung!\r\n", c); */
                 break;
        }

                RdosSetCursorPosition(CurrRow, CurrCol);

        return;
    }


    if(strcmp(ansi_buf, "\033[0K") == 0)   /* Clear to EOL */
    {
        RdosGetCursorPosition(&CurrRow, &CurrCol);

        for(n = 0; CurrCol + n < COLUMNS; ++n)
            clear_buf[n] = ' ';

        if (n)
        {
            if (CurrRow == ROWS - 1)
                    clear_buf[n - 1] = 0;
                    else
                        clear_buf[n] = 0;

            RdosWriteString(clear_buf);
        }
                return;
         }


         if(strcmp(ansi_buf, "\033[2K") == 0)   /* Clear Line */
         {
        for(n = 0; n < COLUMNS; ++n)
                    clear_buf[n] = ' ';

        RdosGetCursorPosition(&CurrRow, &CurrCol);

                if (CurrRow == ROWS - 1)
                    clear_buf[n - 1] = 0;
                else
                    clear_buf[n] = 0;

        CurrCol = 0;
                RdosSetCursorPosition(CurrRow, CurrCol);
                RdosWriteString(clear_buf);

                return;
         }

         if(strcmp(ansi_buf, "\033[2J") == 0)     /* Clear Screen */
         {
        for (n = 0; n < COLUMNS; n++)
                        clear_buf[n] = ' ';

                clear_buf[n] = 0;

                for (n = 0; n < ROWS; n++)
                {
                        RdosSetCursorPosition(n, 0);
                        
                        if (n == ROWS - 1)
                            clear_buf[COLUMNS - 1] = 0;
                             
                        RdosWriteString(clear_buf);
                }

                return;
         }


         if((n = sscanf(ansi_buf, "\x1B[%d;3%d;4%d%c%c", &hl, &fg, &bg, &c, &c2)) == 4 && c == 'm')
         {
                fgc = fg_colors[fg];
                bgc = bg_colors[bg];

                switch (hl)
                {
                case 0:         /* normal */
                case 1:         /* highlighted */
                case 4:         /* underlined */
                case 5:         /* blinking */
                default:
                        break;

                case 7:         /* invers */
                        fgc = (fg_colors[8] - fgc);
                        bgc = (bg_colors[8] - bgc);
                        break;

                case 8:         /* hidden */
                        fgc = bgc;              /* ostfriesische Nationalflagge */
                        break;
                }  /* switch hl */

                RdosSetForeColor(fgc);
                RdosSetBackColor(bgc);
                return;
        }


         if ((n = sscanf(ansi_buf, "\x1B[%d%c%c", &y, &c, &c2)) == 2 && c == 'm')
         {                                        /* Attribute setzen */
                  switch (y)
                  {
                                /* Normal Video */
                                case 0:
                                         RdosSetBackColor(0);
                                         RdosSetForeColor(7);
                                         break;

                                /* Reverse Video */
                                case 7:
                                         RdosSetBackColor(7);
                                         RdosSetForeColor(0);
                                         break;

                                default:
                                         break;
                  }

                  return;
         }


         if((n = sscanf(ansi_buf, "\033[%d;%dH%c", &y, &x, &c)) == 2)
         {                                        /* Cursor Position setzen */
                  CurrCol = (x - 1);
                  CurrRow = (y - 1);
                  RdosSetCursorPosition(CurrRow, CurrCol);
                  return;
         }


         /* printd("Hoppla, Es gibt noch eine unbekannte <ESC> Sequenz!\r\n"); */
}

/*---------------------------------------------------------------------------- */
/* Hier kommen alle Zeichen im Gänsemarsch vorbei. */
/* Entweder direkte Ausgabe oder Zwischenspeicherung einer <ESC> Sequenz. */

int ansi_putchar(int c)
{
         char   s[2];

         if(ansi_buf[0] == 0 && c != 0x1B)
         {
                  console_putchar(c);
                  return c;
         }

         if(ansi_buf[0] == 0)
         {
                  ansi_buf[0] = (char) c;
                  ansi_buf[1] = 0;
                  return c;
         }

         if(strlen(ansi_buf) + 2 < sizeof(ansi_buf))
         {
                  s[0] = (char) c;
                  s[1] = 0;
                  strcat(ansi_buf, s);

                  /* Ende einer <ESC> Sequenz erkennen */
                  /* Für den hier erwarteten Subset! */

                  if((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
                          (ansi_buf[1] == '(' && ansi_buf[2]))
                  {
                                process_ansi_buf();
                                ansi_buf[0] = 0;
                  }
         }
         else
                  ansi_buf[0] = 0;

         return c;
}

/*---------------------------------------------------------------------------- */

int ansi_printf(char *fmt, ...)
{
         char      buffer[2000];
         va_list   args;
         int       i, len;

         va_start(args, fmt);
         len = vsprintf(buffer, fmt, args);

         for(i = 0; buffer[i]; ++i)
                  (void) ansi_putchar(buffer[i]);   /* Alles muß durch's Nadelöhr! */

         va_end(args);

         return len;
}

/*---------------------------------------------------------------------------- */
/* 28.10.03 - comment characters "//" replaced by "/*" */
