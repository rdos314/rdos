#include "rdos.h"

char buf[500];
  
int main()
{
    int handle;
    int count;
    int attrib;

    attrib = 0;

    handle = RdosOpenFile("test.exe", attrib);
    if (handle)
    {
        count = 500;
        count = RdosReadFile(handle, buf, count);
        RdosCloseFile(handle);
    }
       
    return 0;
}
