#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dnapop.h"
#include "dnaseq.h"
#include "dnamut.h"
#include "dnaind.h"
#include "dnaeval.h"

#define FALSE	0
#define	TRUE	!FALSE

int main(int argc, char **argv)
{
	TDnaPopulation *pop;
	TDnaMutator *mut;
	TDnaEvaluator *eval;
	int i;

	randomize();
	random(1000);

	mut = new TDnaMutator(500, 0.01);
	eval = new TDnaEvaluator(500);

	pop = new TDnaPopulation(mut, 100, 500);
	pop->Create(200);
	pop->WriteScores(eval);

	return 0;
}

