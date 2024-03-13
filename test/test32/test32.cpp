#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "keyboard.h"
#include "sockobj.h"
#include "xml.h"


/*##################  GetNextChar  ########################
*   Purpose....: Convert from UTF-8 to ansi (cp1257)                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
static char *GetNextChar(char *str, char *ch)
{
    unsigned char uch;

    uch = (unsigned char)str[0];

    switch (uch)
    {
        case 0xC2:
            uch = (unsigned char)str[1];
            switch (uch)
            {
                case 0xA2:
                case 0xA3:
                case 0xA4:
                case 0xA6:
                case 0xA7:
                case 0xA9:
                case 0xAB:
                case 0xAC:
                case 0xAE:
                case 0xB0:
                case 0xB1:
                case 0xB2:
                case 0xB3:
                case 0xB4:
                case 0xB5:
                case 0xB6:
                case 0xB7:
                case 0xB9:
                case 0xBB:
                case 0xBC:
                case 0xBD:
                case 0xBE:
                    *ch = uch;
                    return str + 2;
                    return str + 2;

                case 0xA8:
                    *ch = 0x8D;
                    return str + 2;

                case 0xAF:
                    *ch = 0x9D;
                    return str + 2;

                case 0xB8:
                    *ch = 0x8F;
                    return str + 2;

                case 0:
                    return str + 1;

                default:
                    *ch = ' ';
                    return str + 2;
            }

        case 0xC3:
            uch = (unsigned char)str[1];
            switch (uch)
            {
                case 0x84:
                case 0x85:
                case 0x89:
                case 0x93:
                case 0x95:
                case 0x96:
                case 0x97:
                case 0x9C:
                case 0x9F:
                case 0xA4:
                case 0xA5:
                case 0xA9:
                case 0xB3:
                case 0xB5:
                case 0xB6:
                case 0xB7:
                case 0xBC:
                    *ch = uch + 0x40;
                    return str + 2;

                case 0x86:
                    *ch = 0xAF;
                    return str + 2;

                case 0x98:
                    *ch = 0xA8;
                    return str + 2;

                case 0xA6:
                    *ch = 0xBF;
                    return str + 2;

                case 0xB8:
                    *ch = 0xB8;
                    return str + 2;

                case 0:
                    return str + 1;

                default:
                    *ch = ' ';
                    return str + 2;
            }                   
            
        case 0xC4:
            uch = (unsigned char)str[1];
            switch (uch)
            {
                case 0x80:
                    *ch = 0xC2;
                    return str + 2;

                case 0x81:
                    *ch = 0xE2;
                    return str + 2;

                case 0x84:
                    *ch = 0xC0;
                    return str + 2;

                case 0x85:
                    *ch = 0xE0;
                    return str + 2;

                case 0x86:
                    *ch = 0xC3;
                    return str + 2;

                case 0x87:
                    *ch = 0xE3;
                    return str + 2;

                case 0x8C:
                    *ch = 0xC8;
                    return str + 2;

                case 0x8D:
                    *ch = 0xE8;
                    return str + 2;

                case 0x92:
                    *ch = 0xC7;
                    return str + 2;

                case 0x93:
                    *ch = 0xE7;
                    return str + 2;

                case 0x96:
                    *ch = 0xCB;
                    return str + 2;

                case 0x97:
                    *ch = 0xEB;
                    return str + 2;

                case 0x98:
                    *ch = 0xC6;
                    return str + 2;

                case 0x99:
                    *ch = 0xE6;
                    return str + 2;

                case 0xA2:
                    *ch = 0xCC;
                    return str + 2;

                case 0xA3:
                    *ch = 0xEC;
                    return str + 2;

                case 0xAA:
                    *ch = 0xCE;
                    return str + 2;

                case 0xAB:
                    *ch = 0xEE;
                    return str + 2;

                case 0xAE:
                    *ch = 0xC1;
                    return str + 2;

                case 0xAF:
                    *ch = 0xE1;
                    return str + 2;

                case 0xB6:
                    *ch = 0xCD;
                    return str + 2;

                case 0xB7:
                    *ch = 0xED;
                    return str + 2;

                case 0xBB:
                    *ch = 0xCF;
                    return str + 2;

                case 0xBC:
                    *ch = 0xEF;
                    return str + 2;

                case 0:
                    return str + 1;

                default:
                    *ch = ' ';
                    return str + 2;
            }                   

        case 0xC5:
            uch = (unsigned char)str[1];
            switch (uch)
            {
                case 0x81:
                    *ch = 0xD9;
                    return str + 2;

                case 0x82:
                    *ch = 0xF9;
                    return str + 2;

                case 0x83:
                    *ch = 0xD1;
                    return str + 2;

                case 0x84:
                    *ch = 0xF1;
                    return str + 2;

                case 0x85:
                    *ch = 0xD2;
                    return str + 2;

                case 0x86:
                    *ch = 0xF2;
                    return str + 2;

                case 0x8C:
                    *ch = 0xD4;
                    return str + 2;

                case 0x8D:
                    *ch = 0xF4;
                    return str + 2;

                case 0x96:
                    *ch = 0xAA;
                    return str + 2;

                case 0x97:
                    *ch = 0xBA;
                    return str + 2;

                case 0x9A:
                    *ch = 0xDA;
                    return str + 2;

                case 0x9D:
                    *ch = 0xFA;
                    return str + 2;

                case 0xA0:
                    *ch = 0xD0;
                    return str + 2;

                case 0xA1:
                    *ch = 0xF0;
                    return str + 2;

                case 0xAA:
                    *ch = 0xDB;
                    return str + 2;

                case 0xAB:
                    *ch = 0xFB;
                    return str + 2;

                case 0xB2:
                    *ch = 0xD8;
                    return str + 2;

                case 0xB3:
                    *ch = 0xF8;
                    return str + 2;

                case 0xB9:
                    *ch = 0xCA;
                    return str + 2;

                case 0xBA:
                    *ch = 0xEA;
                    return str + 2;

                case 0xBB:
                    *ch = 0xDD;
                    return str + 2;

                case 0xBC:
                    *ch = 0xFD;
                    return str + 2;

                case 0xBD:
                    *ch = 0xDE;
                    return str + 2;

                case 0xBE:
                    *ch = 0xFE;
                    return str + 2;

                case 0:
                    return str + 1;

                default:
                    *ch = ' ';
                    return str + 2;
            }
        
        case 0xCB:
            uch = (unsigned char)str[1];
            switch (uch)
            {
                case 0x87:
                    *ch = 0x8E;
                    return str + 2;

                case 0x99:
                    *ch = 0xFF;
                    return str + 2;

                case 0x9B:
                    *ch = 0x9E;
                    return str + 2;

                case 0:
                    return str + 1;

                default:
                    *ch = ' ';
                    return str + 2;
            }

        default:
            *ch = *str;
            return str + 1;
    }
}


void main()
{
    XML xml;
    XMLHeader *head;
    XMLElement *root;
    XMLElement *rep;
    int size;
    char *msg;
    char *buf;
    char *src;
    char *dst;
    char ch;
    TTcpSocket sock(0x850AA8C0, 10097, 5000, 0x2000);
    bool ok = false;

    if (sock.WaitForConnection(5000))
    {
        if (sock.WaitForData(5000))
        {
            size = sock.GetSize();
            if (size)
            {
                msg = new char[size + 1];
                size = sock.Read(msg, size);
                msg[size] = 0;
                if (strstr(msg, "RASO"))
                    ok = true;

                printf(msg);
                delete msg;            
            }
        }
    }

    head = new XMLHeader;
    head->SetEncoding("windows-1257");
    xml.SetHeader(head);

    root = new XMLElement(0, "ST");
    rep = root->AddElement("ReportX");
    xml.SetRootElement(root);

    size = 0x4000;
    buf = new char[size + 1];
    memset(buf, 0, size + 1);

    xml.Export((FILE *)buf, XML_SAVE_MODE_DEFAULT, XML_TARGET_MODE_MEMORY, head);

    size = strlen(buf);
    msg = new char[size + 4];

    src = buf;
    dst = msg;

    while (*src)
    {
        src = GetNextChar(src, &ch);

        if (ch != 0xd && ch != 0xa)
        {
            *dst = ch;
            dst++;
        }
    }

    *dst = 0xd;
    dst++;            

    *dst = 0xa;
    dst++;    

    *dst = 0;        

    delete buf;
        
    strcat(msg, "\r\n");

    sock.Write(msg);
    sock.Push();
    delete msg;

    if (sock.WaitForData(5000))
    {
        size = sock.GetSize();
        if (size)
        {
            msg = new char[size + 1];
            size = sock.Read(msg, size);
            msg[size] = 0;
            strcat(msg, "\r\n");
            printf(msg);
            delete msg;            
        }
    }
  
//    RdosTestGate("");
}



