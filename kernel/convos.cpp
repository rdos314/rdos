#include <stdio.h>
#include <file.h>
#include <string.h>

#define MAX_USER_SIZE   0x10000

int main()
{
    char Buffer[MAX_USER_SIZE];
    char GateName[256];
    int GateId;
    char Macro[256];
    int Size;
    char *ptr;
    char *next;
    TFile InFile("os.def");
    TFile OutFile("rdk.h", 0);

    Size = InFile.Read(Buffer, MAX_USER_SIZE);
    Buffer[Size] = 0;

    ptr = Buffer;
    next = strchr(ptr, 0xd);

    while (next)
    {
        if (*next == 0xd)
        {
            *next = 0;
            next++;
        }

        if (*next == 0xa)
        {
            *next = 0;
            next++;
        }

        if (strchr(ptr, '='))
        {
            if (sscanf(ptr, "%s = %d", GateName, &GateId) == 2)
            {
                if (strcmp(GateName, "osgate_entries") != 0)
                {
                    Size = strlen(GateName);

                    if (GateName[Size - 1] == 'r')
                        GateName[Size - 1] = 0;

                    if (GateName[Size - 2] == 'n')
                        GateName[Size - 2] = 0;

                    if (GateName[Size - 3] == '_')
                        GateName[Size - 3] = 0;

                    sprintf(Macro, "#define OsGate_%s 0x9a %d %d %d %d 3 0\r\n",
                            GateName,
                            GateId & 0xFF,
                            (GateId >> 8) & 0xFF,
                            (GateId >> 16) & 0xFF,
                            (GateId >> 24) & 0xFF);
                    OutFile.Write(Macro);
                }
            }
        }
        else
        {
            OutFile.Write("\r\n");
        }

        ptr = next;
        next = strchr(ptr, 0xd);
    }

    return 0;
}
