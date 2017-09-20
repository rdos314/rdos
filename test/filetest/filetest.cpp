#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#define FALSE   0
#define TRUE    !FALSE

void CreateFile()
{
    char FileName[40];
    char *str;
    int handle;
    int size;
    int i;
    int id = RdosGetRandom(10);

    sprintf(FileName, "%d.txt", id);
    handle = RdosCreateFile(FileName, 0);
    if (handle)
    {
        size = RdosGetRandom(256);
        str = new char[size + 1];

        for (i = 0; i < size; i++)
            str[i] = 'F';

        RdosWriteFile(handle, str, size);
        delete str;

        printf("Created file <%s>, %d bytes\r\n", FileName, size);                
    }
    RdosCloseFile(handle);        
}

void OpenFile()
{
    char FileName[40];
    char *str;
    int handle;
    int size;
    int i;
    int id = RdosGetRandom(10);

    sprintf(FileName, "%d.txt", id);
    handle = RdosOpenFile(FileName, 0);
    if (handle)
    {
        size = RdosGetFileSize(handle);
        str = new char[size + 1];

        RdosReadFile(handle, str, size);
        delete str;

        printf("File exists <%s>, %d bytes\r\n", FileName, size);                
    }
    else
        printf("File doesn't exist <%s>\r\n", FileName);                
        
    RdosCloseFile(handle);        
}

void AppendFile()
{
    char FileName[40];
    char *str;
    int handle;
    int size;
    int pos;
    int i;
    int id = RdosGetRandom(10);

    sprintf(FileName, "%d.txt", id);
    handle = RdosOpenFile(FileName, 0);
    if (handle)
    {
        pos = RdosGetFileSize(handle);
        RdosSetFilePos(handle, pos);

        size = RdosGetRandom(256);

        str = new char[size + 1];

        for (i = 0; i < size; i++)
            str[i] = 'F';

        RdosWriteFile(handle, str, size);
        delete str;

        printf("File append <%s>, %d bytes\r\n", FileName, size);                
    }
    else
        printf("File doesn't exist <%s>\r\n", FileName);                
        
    RdosCloseFile(handle);        
}

void DeleteFile()
{
    char FileName[40];
    int id = RdosGetRandom(10);

    sprintf(FileName, "%d.txt", id);
    if (RdosDeleteFile(FileName))
        printf("File deleted <%s>\r\n", FileName);
    else
        printf("File not deleted <%s>\r\n", FileName);                
}

void FileThread(void *Param)
{
    for (;;)
    {
        RdosWaitMilli(RdosGetRandom(500) + 5);

        switch (RdosGetRandom(2))
        {
            case 0:
                OpenFile();
                break;

            case 1:
                AppendFile();
                break;

            case 2:
                CreateFile();
                break;

            case 3:
                DeleteFile();
                break;
        }
    }
}

void cdecl main()
{
    int j;
    char ThreadName[40];

    for (j = 0; j < 15; j++)
        CreateFile();

    for (j = 0; j < 15; j++)
    {
        sprintf(ThreadName, "File %d", j);
        RdosCreateThread(FileThread, ThreadName, 0, 0x10000);
    }

    for (;;)
        RdosWaitMilli(250);
}

