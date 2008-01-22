
struct TQuizRow
{
    long ID;
    long userid;
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
	char Referer[100];
	long AsResult;
	long NtResult;
	long DysResult;
	char Quiz[250];
	char GroupResult[ACTIVE_GROUP_COUNT];
    char DxResult[DX_COUNT];
};

