#include <stdio.h>
#include "env.h"

void main()
{
	TEnv *env;
	TEnvVar *var;

	env = TEnv::OpenSysEnv();
	env->Add("TEST", "ABCD");
	env->Delete("SERNET.NODE");

	var = env->GotoFirst();
	while (var)
	{
		printf("%s=%s\r\n", var->GetName(), var->GetValue());
		var = env->GotoNext();
	}

	delete env;

	printf("hello\n");
}