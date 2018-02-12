#define DLL_EXPORT      __declspec(dllexport) __stdcall

int __stdcall LibMain( int hdll, int reason, void *reserved )
{
    return 1;
}
                     
void DLL_EXPORT TestFunc()
{
}

int __declspec(dllexport) __pascal WEP(int p)
{
    return 1;
}
