
struct TQuizRow
{
    long ID;
    long LsbTime;
    long MsbTime;
    int  BirthYear;
	char Gender;
    char Lang;
	char Autism;
	char Aspie;
	char PDD;
	char ADHD;
	char Dyslexia;
	char Dyscalculia;
	char NLD;
	char OCD;
	char TS;
	long AsResult;
	long NtResult;
	long AqResult;
	char Quiz[250];
	char GroupResult[ACTIVE_GROUP_COUNT];
};

