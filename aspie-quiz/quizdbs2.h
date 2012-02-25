
struct TQuizRow
{
    long ID;
    long UserID;
    long LsbTime;
    long MsbTime;
    long FilloutTime;
    int  BirthYear;
    int  BirthMonth;
	char Gender;
    char Lang;
	char Autism;
	char Aspie;
	char ADHD;
	char TS;
	char Dyslexia;
	char Dyscalculia;
	char OCD;
	char ODD;
	char Bipolar;
	char Schizophrenia;
	char Social;
	long AsResult;
	long NtResult;
	char Quiz[200];
	char GroupResult[ACTIVE_GROUP_COUNT];
	char Rating[15];
	int  ViewTime[15];
};

