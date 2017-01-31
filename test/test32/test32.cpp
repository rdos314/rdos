#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "serial.h"
#include "section.h"
#include "file.h"
#include "rdos.h"

#include <math.h>

#define FALSE 0
#define TRUE !FALSE

void main()
{
    char buf[32];
    int size;
    int val;
    char *ptr;
    char *arg[] = {"z:\\command.exe", 0};

    val = fork();

    if (val == 0)
    {
        execv(arg[0], (char **)&arg);

        ptr = new char[256];
        strcpy(ptr,"Forked process\r\n"); 
        printf(ptr);
        delete ptr;
        exit (0);
    }
    else
        printf("Forked ID: %d\r\n", val);

    size = read(0, buf, 30);
    write(1, buf, size);

    char str[100];
    int i;

    printf( "Enter a value :");
    scanf("%s %d", str, &i);

    printf( "\nYou entered: %s %d ", str, i);
    
}
