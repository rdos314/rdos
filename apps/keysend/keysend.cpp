#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "serial.h"
#include "rdos.h"
#include "keyboard.h"

#include "str.h"
#include "path.h"

TSerialDevice *Serial = 0;

/*##################  KeyPress ##########################
*   Purpose....: Key press                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void KeyPress(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    char str[120];

    sprintf(str, "ExtKey = %04hX, KeyState = %04hX, VK = %02hX, Scan = %02hX, Pressed", ExtKey, KeyState, VirtualKey, ScanCode);
    printf(str);
}

/*##################  KeyRelease ##########################
*   Purpose....: Key release                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void KeyRelease(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    char str[120];

    sprintf(str, "ExtKey = %04hX, KeyState = %04hX, VK = %02hX, Scan = %02hX, Released", ExtKey, KeyState, VirtualKey, ScanCode);
    printf(str);
}

/*##################  main ##########################
*   Purpose....: Program entry-point                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
    int port;
    char ch;
    TKeyboardDevice Keyboard;
    int ok;
    int ExtKey;
    int State;
    int VirtKey;
    int ScanCode;
    TWait Wait;

    if (argc == 2)
        port = atoi(argv[1]);
    else
        port = 0;

    if (port)
    {
        Serial = new TSerialDevice(port, 9600, 'N', 8, 1);

        Keyboard.OnKeyPress = KeyPress;
        Keyboard.OnKeyRelease = KeyRelease;

        Wait.Add(&Keyboard);

        for (;;)
            Wait.WaitForever();
    }
    else
        printf("usage: keysend port\r\n");

    return 0;
}
