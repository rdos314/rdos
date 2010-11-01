/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2009, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# quizge2.cpp
# Quiz final version 2, experimental release 2 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizge2.h"
#include "file.h"
#include "quizdge2.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

class TRace
{
public:
	TRace();
	void Add(TQuizRow *Row);
	void WriteUsRow(TFile &file, int index, const char *text);
	void WriteNonUsRow(TFile &file, int index, const char *text);
	void WriteEntry(TFile &file, int val, int count);

	static void WriteHeader(TFile &file);

	int UsCount[10];
	int UsAsCount[10];
	int NonUsCount[10];
	int NonUsAsCount[10];
};

/*##########################################################################
#
#   Name       : TQuizExp2b::TQuizExp2b
#
#   Purpose....: Constructor for TQuizExp2b
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizExp2b::TQuizExp2b(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12, TQuiz *QuizN1, TQuiz *QuizN2, TQuiz *QuizN3, TQuiz *QuizN4, TQuiz *QuizFI, TQuiz *QuizF1, TQuiz *QuizF2, TQuiz *QuizF3, TQuiz *QuizF4, TQuiz *QuizF5, TQuiz *QuizF6, TQuiz *QuizF7, TQuiz *QuizF8, TQuiz *QuizF9, TQuiz *QuizF10, TQuiz *QuizF11, TQuiz *QuizF12, TQuiz *QuizF13, TQuiz *QuizF14, TQuiz *QuizF15, TQuiz *QuizGe)
  : TQuiz(159),
	FDataFile(FileName)
{
	DefineCross(0, QuizI);
	DefineCross(1, QuizII);
	DefineCross(2, QuizIII);
	DefineCross(3, QuizNd);
	DefineCross(4, Quiz5);
	DefineCross(5, Quiz6);
	DefineCross(6, Quiz7);
	DefineCross(7, Quiz8);
	DefineCross(8, Quiz9);
	DefineCross(9, QuizR1);
	DefineCross(10, QuizR2);
	DefineCross(11, QuizR3);
	DefineCross(12, QuizR4);
	DefineCross(13, QuizR5);
	DefineCross(14, QuizR6);
	DefineCross(15, QuizR7);
	DefineCross(16, QuizS1);
	DefineCross(17, QuizS2);
	DefineCross(18, QuizS3);
	DefineCross(19, QuizS4);
	DefineCross(20, QuizS5);
	DefineCross(21, QuizS6);
	DefineCross(22, QuizS7);
	DefineCross(23, QuizS8);
	DefineCross(24, QuizS9);
	DefineCross(25, QuizS10);
	DefineCross(26, QuizS11);
	DefineCross(27, QuizS12);
	DefineCross(28, QuizN1);
	DefineCross(29, QuizN2);
	DefineCross(30, QuizN3);
	DefineCross(31, QuizN4);
	DefineCross(32, QuizFI);
	DefineCross(33, QuizF1);
	DefineCross(34, QuizF2);
	DefineCross(35, QuizF3);
	DefineCross(36, QuizF4);
	DefineCross(37, QuizF5);
	DefineCross(38, QuizF6);
	DefineCross(39, QuizF7);
	DefineCross(40, QuizF8);
	DefineCross(41, QuizF9);
	DefineCross(42, QuizF10);
	DefineCross(43, QuizF11);
	DefineCross(44, QuizF12);
	DefineCross(45, QuizF13);
	DefineCross(46, QuizF14);
	DefineCross(47, QuizF15);
	DefineCross(48, QuizGe);

	SetupTexts();
//	DefineQuiz();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4, QuizR5, QuizR6, QuizR7, QuizS1, QuizS2, QuizS3, QuizS4, QuizS5, QuizS6, QuizS7, QuizS8, QuizS9, QuizS10, QuizS11, QuizS12, QuizN1, QuizN2, QuizN3, QuizN4, QuizFI, QuizF1, QuizF2, QuizF3, QuizF4, QuizF5, QuizF6, QuizF7, QuizF8, QuizF9, QuizF10, QuizF11, QuizF12, QuizF13, QuizF14, QuizF15, QuizGe);

	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizExp2b::~TQuizExp2b
#
#   Purpose....: Destructor for TQuizExp2b
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizExp2b::~TQuizExp2b()
{
}

/*##################  TQuizExp2b::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizExp2b::GetCatCount(int Question)
{
    return 3;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizExp2b::GetQuizN()
{
	return 159;
}

/*##########################################################################
#
#   Name       : TQuizExp2b::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizExp2b::WriteName(TFile &File)
{
	 File.Write("GE2");
}

/*##########################################################################
#
#   Name       : TQuizExp2b::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizExp2b::WriteLongName(TFile &File)
{
	 File.Write("final version 2b:experimental");
}

/*##################  TQuizExp2b::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizExp2b::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizExp2b::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizExp2b::InitReferers()
{
	AddReferer("livejournal.com/community/asperger", "livejournal.com/community/asperger");
	AddReferer("flashback.info", "flashback.info");
	AddReferer("aspiesforfreedom.", "aspiesforfreedom.com");
	AddReferer("aspergianisland.com", "aspergianisland.com");
	AddReferer("wrongplanet.net", "wrongplanet.net");
	AddReferer("rdos.net/sv", "rdos.net/sv");
	AddReferer("aspalsta.net", "aspalsta.net/viewtopic.php?t=1951");
	AddReferer("circvsmaximvs.com", "circvsmaximvs.com/showthread.php?t=14129");
	AddReferer("panterachat.com", "panterachat.com/phpBB/viewtopic.php?t=24332");
	AddReferer("kaytastrophe.com", "kaytastrophe.com/index.php?topic=708.0");
	AddReferer("tbg.nu", "tbg.nu/news_show/109118/40");
	AddReferer("vof.se", "vof.se/forum/viewtopic.php?t=3080");
	AddReferer("autismspeaks.org", "autismspeaks.org/community/forums");
	AddReferer("nordisk.nu", "nordisk.nu/showthread.php?t=3117");
	AddReferer("swedvdr.org", "swedvdr.org/forums.php?action=viewtopic");
	AddReferer("filmtipset.se", "filmtipset.se/forum.cgi?id=1339244");
	AddReferer("tvsushi.com", "forum.tvsushi.com/index.php?showtopic=52752");
	AddReferer("smogon.com", "smogon.com/forums/showthread.php?t=29171");
	AddReferer("mommyconnection.org", "mommyconnection.org/board/index.php/topic,2840.0.html");
	AddReferer("calientemamas.com", "calientemamas.com/forum_posts.asp?TID=12136");
	AddReferer("forums.britxbox.co.uk", "forums.britxbox.co.uk/viewtopic.php?t=54722");
	AddReferer("goonfleet.com", "goonfleet.com/showthread.php?t=77152");
	AddReferer("weebls-stuff.com", "weebls-stuff.com");
	AddReferer("keithandthegirl.com", "keithandthegirl.com/forums/showthread.php?t=9785");
}

/*##########################################################################
#
#   Name       : TQuizExp2b::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizExp2b::SetupControlGroups()
{
	DefineNt("flashback.info");
	DefineNt("rdos.net/sv");
	DefineNt("circvsmaximvs.com");
	DefineNt("panterachat.com");
	DefineNt("kaytastrophe.com");
	DefineNt("tbg.nu");
	DefineNt("vof.se");
	DefineNt("nordisk.nu");
	DefineNt("swedvdr.org");
	DefineNt("filmtipset.se");
	DefineNt("tvsushi.com");
	DefineNt("smogon.com");
	DefineNt("mommyconnection.org");
	DefineNt("calientemamas.com");
	DefineNt("forums.britxbox.co.uk");
	DefineNt("goonfleet.com");
	DefineNt("weebls-stuff.com");
	DefineNt("keithandthegirl.com");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##########################################################################
#
#   Name       : TQuizExp2b::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizExp2b::SetupTexts()
{
  Quiz[11].Reverse = TRUE;
  Quiz[14].Reverse = TRUE;
  Quiz[18].Reverse = TRUE;
  Quiz[28].Reverse = TRUE;
  Quiz[29].Reverse = TRUE;
  Quiz[30].Reverse = TRUE;
  Quiz[31].Reverse = TRUE;
  Quiz[32].Reverse = TRUE;
  Quiz[33].Reverse = TRUE;
  Quiz[34].Reverse = TRUE;
  Quiz[54].Reverse = TRUE;
  Quiz[65].Reverse = TRUE;
  Quiz[100].Reverse = TRUE;
  Quiz[102].Reverse = TRUE;
  Quiz[103].Reverse = TRUE;
  Quiz[105].Reverse = TRUE;
  Quiz[107].Reverse = TRUE;
  Quiz[108].Reverse = TRUE;
  Quiz[110].Reverse = TRUE;
  Quiz[111].Reverse = TRUE;
  Quiz[143].Reverse = TRUE;
  Quiz[146].Reverse = TRUE;
  Quiz[154].Reverse = TRUE;
  Quiz[155].Reverse = TRUE;
  Quiz[156].Reverse = TRUE;
  Quiz[157].Reverse = TRUE;
  Quiz[158].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[2].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[3].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[4].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[5].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[6].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[7].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[8].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[9].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[10].MyGroup = GROUP_NT_TALENT;
  Quiz[11].MyGroup = GROUP_NT_TALENT;
  Quiz[12].MyGroup = GROUP_NT_TALENT;
  Quiz[13].MyGroup = GROUP_NT_TALENT;
  Quiz[14].MyGroup = GROUP_NT_TALENT;
  Quiz[15].MyGroup = GROUP_NT_TALENT;
  Quiz[16].MyGroup = GROUP_NT_TALENT;
  Quiz[17].MyGroup = GROUP_NT_TALENT;
  Quiz[18].MyGroup = GROUP_NT_TALENT;
  Quiz[19].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[20].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[21].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[22].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[23].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[24].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[25].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[26].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[27].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[28].MyGroup = GROUP_NT_SOCIAL;
  Quiz[29].MyGroup = GROUP_NT_OBSESSION;
  Quiz[30].MyGroup = GROUP_NT_OBSESSION;
  Quiz[31].MyGroup = GROUP_NT_OBSESSION;
  Quiz[32].MyGroup = GROUP_NT_OBSESSION;
  Quiz[33].MyGroup = GROUP_NT_HUNTING;
  Quiz[34].MyGroup = GROUP_NT_OBSESSION;
  Quiz[35].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[36].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[37].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[38].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[39].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[40].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[41].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[42].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[43].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[44].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[45].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[46].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[47].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[48].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[49].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[50].MyGroup = GROUP_NT_TALENT;
  Quiz[51].MyGroup = GROUP_NT_SOCIAL;
  Quiz[52].MyGroup = GROUP_NT_OBSESSION;
  Quiz[53].MyGroup = GROUP_ENVIRONMENT;
  Quiz[54].MyGroup = GROUP_NT_OBSESSION;
  Quiz[55].MyGroup = GROUP_NT_SOCIAL;
  Quiz[56].MyGroup = GROUP_NT_SOCIAL;
  Quiz[57].MyGroup = GROUP_NT_SOCIAL;
  Quiz[58].MyGroup = GROUP_NT_SOCIAL;
  Quiz[59].MyGroup = GROUP_NT_SOCIAL;
  Quiz[60].MyGroup = GROUP_NT_SOCIAL;
  Quiz[61].MyGroup = GROUP_NT_SOCIAL;
  Quiz[62].MyGroup = GROUP_NT_SOCIAL;
  Quiz[63].MyGroup = GROUP_NT_SOCIAL;
  Quiz[64].MyGroup = GROUP_NT_SOCIAL;
  Quiz[65].MyGroup = GROUP_NT_SOCIAL;
  Quiz[66].MyGroup = GROUP_NT_SOCIAL;
  Quiz[67].MyGroup = GROUP_ASPIE_NVC;
  Quiz[68].MyGroup = GROUP_NT_NVC;
  Quiz[69].MyGroup = GROUP_ASPIE_NVC;
  Quiz[70].MyGroup = GROUP_ASPIE_NVC;
  Quiz[71].MyGroup = GROUP_ASPIE_NVC;
  Quiz[72].MyGroup = GROUP_ASPIE_NVC;
  Quiz[73].MyGroup = GROUP_ASPIE_NVC;
  Quiz[74].MyGroup = GROUP_ASPIE_NVC;
  Quiz[75].MyGroup = GROUP_ASPIE_NVC;
  Quiz[76].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[77].MyGroup = GROUP_ASPIE_NVC;
  Quiz[78].MyGroup = GROUP_ASPIE_NVC;
  Quiz[79].MyGroup = GROUP_ASPIE_NVC;
  Quiz[80].MyGroup = GROUP_ASPIE_NVC;
  Quiz[81].MyGroup = GROUP_ASPIE_NVC;
  Quiz[82].MyGroup = GROUP_ASPIE_NVC;
  Quiz[83].MyGroup = GROUP_NT_NVC;
  Quiz[84].MyGroup = GROUP_ASPIE_NVC;
  Quiz[85].MyGroup = GROUP_ASPIE_NVC;
  Quiz[86].MyGroup = GROUP_ASPIE_NVC;
  Quiz[87].MyGroup = GROUP_ASPIE_NVC;
  Quiz[88].MyGroup = GROUP_ASPIE_NVC;
  Quiz[89].MyGroup = GROUP_ASPIE_NVC;
  Quiz[90].MyGroup = GROUP_ASPIE_NVC;
  Quiz[91].MyGroup = GROUP_NT_NVC;
  Quiz[92].MyGroup = GROUP_NT_NVC;
  Quiz[93].MyGroup = GROUP_NT_NVC;
  Quiz[94].MyGroup = GROUP_NT_NVC;
  Quiz[95].MyGroup = GROUP_NT_NVC;
  Quiz[96].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[97].MyGroup = GROUP_NT_NVC;
  Quiz[98].MyGroup = GROUP_NT_NVC;
  Quiz[99].MyGroup = GROUP_ASPIE_NVC;
  Quiz[100].MyGroup = GROUP_NT_NVC;
  Quiz[101].MyGroup = GROUP_NT_NVC;
  Quiz[102].MyGroup = GROUP_NT_SOCIAL;
  Quiz[103].MyGroup = GROUP_NT_SOCIAL;
  Quiz[104].MyGroup = GROUP_NT_NVC;
  Quiz[105].MyGroup = GROUP_NT_NVC;
  Quiz[106].MyGroup = GROUP_NT_NVC;
  Quiz[107].MyGroup = GROUP_NT_NVC;
  Quiz[108].MyGroup = GROUP_NT_NVC;
  Quiz[109].MyGroup = GROUP_NT_NVC;
  Quiz[110].MyGroup = GROUP_NT_SOCIAL;
  Quiz[111].MyGroup = GROUP_NT_NVC;
  Quiz[112].MyGroup = GROUP_NT_NVC;
  Quiz[113].MyGroup = GROUP_NT_NVC;
  Quiz[114].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[115].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[116].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[117].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[118].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[119].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[120].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[121].MyGroup = GROUP_NT_HUNTING;
  Quiz[122].MyGroup = GROUP_NT_HUNTING;
  Quiz[123].MyGroup = GROUP_NT_HUNTING;
  Quiz[124].MyGroup = GROUP_NT_HUNTING;
  Quiz[125].MyGroup = GROUP_NT_HUNTING;
  Quiz[126].MyGroup = GROUP_NT_HUNTING;
  Quiz[127].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[128].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[129].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[130].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[131].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[132].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[133].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[134].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[135].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[136].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[137].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[138].MyGroup = GROUP_NT_SENSORY;
  Quiz[139].MyGroup = GROUP_NT_SENSORY;
  Quiz[140].MyGroup = GROUP_NT_SENSORY;
  Quiz[141].MyGroup = GROUP_NT_SENSORY;
  Quiz[142].MyGroup = GROUP_NT_SENSORY;
  Quiz[143].MyGroup = GROUP_NT_SENSORY;
  Quiz[144].MyGroup = GROUP_NT_SENSORY;
  Quiz[145].MyGroup = GROUP_NT_SENSORY;
  Quiz[146].MyGroup = GROUP_NT_SENSORY;
  Quiz[147].MyGroup = GROUP_ENVIRONMENT;
  Quiz[148].MyGroup = GROUP_ENVIRONMENT;
  Quiz[149].MyGroup = GROUP_ENVIRONMENT;
  Quiz[150].MyGroup = GROUP_ENVIRONMENT;
  Quiz[151].MyGroup = GROUP_ENVIRONMENT;
  Quiz[152].MyGroup = GROUP_ENVIRONMENT;
  Quiz[153].MyGroup = GROUP_ENVIRONMENT;

  Quiz[154].MyGroup = GROUP_NT_TALENT;
  Quiz[155].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[156].MyGroup = GROUP_NT_NVC;
  Quiz[157].MyGroup = GROUP_NT_SENSORY;
  Quiz[158].MyGroup = GROUP_ENVIRONMENT;

#ifdef ENGLISH
  Quiz[0].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[1].Text = "Do you have an avid perseverance in gathering and cataloguing information on a topic of interest?";
  Quiz[2].Text = "Do you or others think that you have unconventional ways of solving problems?";
  Quiz[3].Text = "As a child, was your play more directed towards, for example, sorting, building, investigating or taking things apart than towards social games with other kids?";
  Quiz[4].Text = "Is you imagination unusual, with unique ideas that others don't have?";
  Quiz[5].Text = "Do you need periods of contemplation?";
  Quiz[6].Text = "Do you tend to notice details that others do not?";
  Quiz[7].Text = "Do you notice patterns in things all the time?";
  Quiz[8].Text = "Do you have one special talent which you have emphasised and worked on?";
  Quiz[9].Text = "Do you have a strong preference for detail over gestalt?";
  Quiz[10].Text = "Do you get confused by several verbal instructions at the same time?";
  Quiz[11].Text = "Do you find it easy to do more than one thing at once?";
  Quiz[12].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[13].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[14].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[15].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[16].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[17].Text = "Are you easily distracted?";
  Quiz[18].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[19].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[20].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[21].Text = "Do you prefer to wear the same clothes or eat the same food many days in a row?";
  Quiz[22].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[23].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[24].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[25].Text = "Do you have certain routines which you need to follow?";
  Quiz[26].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[27].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[28].Text = "Do you enjoy meeting new people?";
  Quiz[29].Text = "Are your views typical of your peer group?";
  Quiz[30].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[31].Text = "Do you have an interest for the current fashions?";
  Quiz[32].Text = "Do you enjoy gossip?";
  Quiz[33].Text = "Are friends of the same gender important to you?";
  Quiz[34].Text = "Do you prefer the company of those of the same generation as yourself?";
  Quiz[35].Text = "Do you find it easier to understand and communicate with odd & unusual people than with ordinary people?";
  Quiz[36].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[37].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[38].Text = "Do you have an alternative view of what is attractive in the opposite sex?";
  Quiz[39].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[40].Text = "Do you tend to become obsessed with a potential partner and cannot let go of him/her?";
  Quiz[41].Text = "Do you see your own activities as more important than other people's?";
  Quiz[42].Text = "Do your feelings cycle regulary between hopelessness and extremely high confidence?";
  Quiz[43].Text = "Do you have trouble with authority?";
  Quiz[44].Text = "Do you have atypical or irregular sleeping patterns that deviate from the 24-h cycle?";
  Quiz[45].Text = "Do you have problems starting and / or finishing projects?";
  Quiz[46].Text = "Do you find the norms of hygiene too strict?";
  Quiz[47].Text = "Do you sometimes lie awake at night because of too many thoughts?";
  Quiz[48].Text = "Have you have had long-lasting urges to take revenge?";
  Quiz[49].Text = "Do you have unusual sexual preferences?";
  Quiz[50].Text = "Do you prefer to read directions only when all else have failed?";
  Quiz[51].Text = "Do you have a tendency to become stuck when asked questions in social situation?";
  Quiz[52].Text = "Do you often feel out-of-sync with others?";
  Quiz[53].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[54].Text = "Do you enjoy team sports?";
  Quiz[55].Text = "Do you avoid talking face to face with someone you don't know very well?";
  Quiz[56].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[57].Text = "Do people think you are aloof and distant?";
  Quiz[58].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[59].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[60].Text = "Do you dislike shaking hands with strangers?";
  Quiz[61].Text = "Do you prefer animals to people?";
  Quiz[62].Text = "Do you feel uncomfortable with strangers?";
  Quiz[63].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[64].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[65].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[66].Text = "Do you dislike reading aloud?";
  Quiz[67].Text = "Do people comment on your unusual mannerisms and habits?";
  Quiz[68].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[69].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[70].Text = "Do you often don't know where to put your arms?";
  Quiz[71].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[72].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[73].Text = "Have you been accused of staring?";
  Quiz[74].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[75].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[76].Text = "Do you mistake noises for voices?";
  Quiz[77].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[78].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[79].Text = "Do recently heard tunes or rhytms tend to stick and replay themselves repeatedly in your head?";
  Quiz[80].Text = "Do you repeat vocalizations made by others?";
  Quiz[81].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[82].Text = "Do you fiddle with things?";
  Quiz[83].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[84].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[85].Text = "Do you stutter when stressed?";
  Quiz[86].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[87].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[88].Text = "Do you talk to yourself?";
  Quiz[89].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
  Quiz[90].Text = "Do you have difficulties with pronunciation?";
  Quiz[91].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[92].Text = "Do you have problems with timing in conversations?";
  Quiz[93].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[94].Text = "Do others often misunderstand you?";
  Quiz[95].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[96].Text = "Do you tend to say things that are considered socially inappropriate when you are tired, frustrated or when you act naturally?";
  Quiz[97].Text = "As a teenager, were you usually unaware of social rules & boundaries unless they were clearly spelled out?";
  Quiz[98].Text = "Do you tend to interpret things literally?";
  Quiz[99].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[100].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[101].Text = "In a conversation, do you tend to focus on your own thoughts rather than on what your listener might be thinking?";
  Quiz[102].Text = "Can you quickly and naturally work out people's intentions in conversations?";
  Quiz[103].Text = "Are you naturally good at returning social courtesies and gestures?";
  Quiz[104].Text = "Is it hard for you to see why some things upset people so much?";
  Quiz[105].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[106].Text = "Do people often tell you that you keep going on and on about the same thing?";
  Quiz[107].Text = "Do you know when you are expected to offer an apology?";
  Quiz[108].Text = "Are you good at interpreting facial expressions?";
  Quiz[109].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[110].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[111].Text = "Do you find it easy to describe your feelings?";
  Quiz[112].Text = "Do you have a monotonous voice?";
  Quiz[113].Text = "Are you naturally so honest and sincere yourself that you assume everyone should be?";
  Quiz[114].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[115].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[116].Text = "Do you sometimes have an urge to jump over things?";
  Quiz[117].Text = "Do you enjoy mimicking animal sounds?";
  Quiz[118].Text = "Are you or have you been hyperactive?";
  Quiz[119].Text = "Do you enjoy walking on your toes?";
  Quiz[120].Text = "Have you been fascinated with making traps?";
  Quiz[121].Text = "Do you find it difficult to take messages on the telephone and pass them on correctly?";
  Quiz[122].Text = "Do you drop things when your attention is on other things?";
  Quiz[123].Text = "Do you have problems filling out forms?";
  Quiz[124].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[125].Text = "Do you mix up digits in numbers like 95 and 59?";
  Quiz[126].Text = "Do you have trouble reading clocks?";
  Quiz[127].Text = "Do you suddenly feel distracted by distant sounds?";
  Quiz[128].Text = "Do you have extra sensitive hearing?";
  Quiz[129].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[130].Text = "Do you dislike when people walk behind you?";
  Quiz[131].Text = "Are you bothered by clothes tags or light touch?";
  Quiz[132].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[133].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[134].Text = "Are you sensitive to changes in humidity and air pressure?";
  Quiz[135].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[136].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[137].Text = "Does it come more natural to you to think in pictures than in words?";
  Quiz[138].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[139].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[140].Text = "Do you misjudge how much time has passed when involved in interesting activities?";
  Quiz[141].Text = "Do you find it hard to tell the age of people?";
  Quiz[142].Text = "Can you make good estimates of distance, height, depth and speed?";
  Quiz[143].Text = "Do you have difficulties with activities requiring manual precision, e.g sewing, tying shoe-laces, fastening buttons or handling small objects?";
  Quiz[144].Text = "Do you have problems finding your way to new places?";
  Quiz[145].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[146].Text = "Do you have a good sense of how much pressure to apply when doing things with your hands?";
  Quiz[147].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[148].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[149].Text = "Are you sometimes afraid in safe situations?";
  Quiz[150].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[151].Text = "Are you prone to getting depressions?";
  Quiz[152].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[153].Text = "Are you impatient and have low frustration tolerance?";

  Quiz[154].Text = "Can you easily remember verbal instructions?";
  Quiz[155].Text = "Is your sense of humor fairly conventional?";
  Quiz[156].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[157].Text = "Do you find it easy to estimate the age of people?";
  Quiz[158].Text = "Are you gracious about criticism, correction and direction?";
#endif  
}

/*##################  TQuizExp2b::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizExp2b::LoadReferers()
{
	TQuizRow Row;
	TReferer *ref;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Gender == 1)
			UpdateReferer(&MaleRef, Row.AsResult, Row.NtResult, Row.GroupResult);
        else			
			UpdateReferer(&FemaleRef, Row.AsResult, Row.NtResult, Row.GroupResult);
	
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie == 2)
			UpdateReferer(&AsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD == 2)
			UpdateReferer(&AddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.OCD == 2)
			UpdateReferer(&OCDRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Social == 2)
			UpdateReferer(&SocialPhobiaRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie)
		{
			if (Row.Gender == 1)
				UpdateReferer(&MaleAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);
			else
				UpdateReferer(&FemaleAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizExp2b::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizExp2b::LoadPopulations()
{
	TQuizRow Row;
	int i;
	int id;
	TReferer *ref;
	char DxArr[DX_COUNT];
	char score;
	int IdArr[MAX_QUESTIONS];

	for (i = 0; i < N; i++)
	{
		Quiz[i].NoAnswer = 0;
		IdArr[i] = GetGlobalId(i);
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		BirthMonth.Add(Row.AsResult, Row.NtResult, Row.BirthMonth);

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
				if (i < 161)
				{
					score = Row.Quiz[i] - 1;
					id = IdArr[i];

					DsmAs.Add(Row.Aspie, id, score);
					DsmAdd.Add(Row.ADHD, id, score);
					DsmSocialPhobia.Add(Row.Social, id, score);
				}
			}
		}

		for (i = 0; i < DX_COUNT; i++)
			DxArr[i] = DX_STATE_UNKNOWN;

		if (Row.Aspie == 2)
			DxArr[DX_AS] = DX_STATE_YES;

		if (Row.Aspie == 1)
			DxArr[DX_AS] = DX_STATE_SELF;

		if (Row.Aspie == 0)
			DxArr[DX_AS] = DX_STATE_NO;

		if (Row.ADHD == 2)
			DxArr[DX_ADD] = DX_STATE_YES;

		if (Row.ADHD == 1)
			DxArr[DX_ADD] = DX_STATE_SELF;

		if (Row.ADHD == 0)
			DxArr[DX_ADD] = DX_STATE_NO;

		if (Row.OCD == 2)
			DxArr[DX_OCD] = DX_STATE_YES;

		if (Row.OCD == 1)
			DxArr[DX_OCD] = DX_STATE_SELF;

		if (Row.OCD == 0)
			DxArr[DX_OCD] = DX_STATE_NO;

		if (Row.Social == 2)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_YES;

		if (Row.Social == 1)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_SELF;

		if (Row.Social == 0)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_NO;

		All.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

			if (Row.Gender == 1)
			{
				if (Row.BirthYear > 1986)
					YoungMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

				AsMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			}
			else
			{
				if (Row.BirthYear > 1986)
					YoungFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

				AsFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			}

			if (Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

			if (Row.Aspie == 1)
				AspieControl.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}

		if (Row.ADHD >= 1)
		{
			Add.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}

		if (Row.Social >= 1)
			SocialPhobia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}
		else
		{
			ref = FindReferer(Row.Referer);
			if (ref && ref->NT)
				NtControl.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
		}

	}
}

/*##########################################################################
#
#   Name       : TQuizExp2b::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizExp2b::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12, TQuiz *QuizN1, TQuiz *QuizN2, TQuiz *QuizN3, TQuiz *QuizN4, TQuiz *QuizFI, TQuiz *QuizF1, TQuiz *QuizF2, TQuiz *QuizF3, TQuiz *QuizF4, TQuiz *QuizF5, TQuiz *QuizF6, TQuiz *QuizF7, TQuiz *QuizF8, TQuiz *QuizF9, TQuiz *QuizF10, TQuiz *QuizF11, TQuiz *QuizF12, TQuiz *QuizF13, TQuiz *QuizF14, TQuiz *QuizF15, TQuiz *QuizGE)
{
    DefineCross(QuizGE, 0, 0);
    DefineCross(QuizF5, 1, 167);
    DefineCross(QuizGE, 2, 2);
	DefineCross(QuizS10, 3, 7);
    DefineCross(Quiz9, 4, 32);
    DefineCross(QuizGE, 5, 4);
    DefineCross(QuizF1, 6, 161);
    DefineCross(QuizGE, 7, 6);
	DefineCross(QuizGE, 8, 7);
    DefineCross(QuizF5, 9, 164);
    DefineCross(QuizGE, 10, 8);
    DefineCross(QuizF1, 11, 181);
    DefineCross(QuizGE, 12, 11);
    DefineCross(QuizGE, 13, 12);
	DefineCross(QuizGE, 14, 13);
    DefineCross(QuizGE, 15, 14);
    DefineCross(QuizGE, 16, 15);
    DefineCross(QuizGE, 17, 16);
    DefineCross(QuizGE, 18, 17);
    DefineCross(QuizGE, 19, 18);
    DefineCross(QuizGE, 20, 19);
    DefineCross(QuizGE, 21, 20);
	DefineCross(QuizGE, 22, 21);
	DefineCross(QuizGE, 23, 22);
	DefineCross(QuizGE, 24, 23);
    DefineCross(QuizGE, 25, 24);
    DefineCross(QuizGE, 26, 25);
    DefineCross(QuizGE, 27, 26);
    DefineCross(QuizGE, 28, 27);
    DefineCross(QuizGE, 29, 28);
    DefineCross(QuizGE, 30, 29);
    DefineCross(QuizGE, 31, 31);
    DefineCross(QuizGE, 32, 32);
	DefineCross(QuizGE, 33, 33);
    DefineCross(QuizGE, 34, 34);
    DefineCross(QuizGE, 35, 35);
    DefineCross(QuizGE, 36, 36);
    DefineCross(QuizGE, 37, 37);
	DefineCross(QuizGE, 38, 39);
    DefineCross(QuizGE, 39, 38);
    DefineCross(QuizGE, 40, 41);
    DefineCross(QuizGE, 41, 40);
    DefineCross(QuizGE, 42, 42);
    DefineCross(QuizGE, 43, 43);
	DefineCross(QuizGE, 44, 44);
    DefineCross(QuizGE, 45, 45);
    DefineCross(QuizGE, 46, 46);
    DefineCross(QuizGE, 47, 47);
    DefineCross(QuizGE, 48, 48);
    DefineCross(QuizGE, 49, 49);
    DefineCross(QuizGE, 50, 50);
    DefineCross(QuizGE, 51, 51);
	DefineCross(QuizGE, 52, 52);
	DefineCross(QuizGE, 53, 53);
	DefineCross(QuizS3, 54, 129);
	DefineCross(QuizGE, 55, 55);
    DefineCross(QuizGE, 56, 56);
    DefineCross(QuizGE, 57, 57);
    DefineCross(QuizGE, 58, 58);
    DefineCross(QuizGE, 59, 59);
    DefineCross(QuizGE, 60, 60);
    DefineCross(QuizGE, 61, 61);
    DefineCross(QuizN2, 62, 50);
	DefineCross(QuizGE, 63, 63);
    DefineCross(QuizGE, 64, 64);
    DefineCross(QuizGE, 65, 65);
    DefineCross(QuizGE, 66, 66);
    DefineCross(QuizGE, 67, 67);
	DefineCross(QuizGE, 68, 68);
    DefineCross(QuizGE, 69, 69);
    DefineCross(QuizGE, 70, 70);
    DefineCross(QuizGE, 71, 71);
    DefineCross(QuizGE, 72, 72);
    DefineCross(QuizGE, 73, 73);
	DefineCross(QuizGE, 74, 74);
    DefineCross(QuizGE, 75, 76);
    DefineCross(QuizGE, 76, 75);
    DefineCross(QuizGE, 77, 77);
    DefineCross(QuizGE, 78, 78);
    DefineCross(QuizGE, 79, 79);
    DefineCross(QuizN1, 80, 185);
    DefineCross(QuizGE, 81, 81);
	DefineCross(QuizGE, 82, 82);
	DefineCross(QuizGE, 83, 84);
	DefineCross(QuizGE, 84, 85);
    DefineCross(QuizGE, 85, 86);
    DefineCross(QuizGE, 86, 87);
    DefineCross(QuizGE, 87, 88);
    DefineCross(QuizGE, 88, 89);
    DefineCross(QuizGE, 89, 90);
    DefineCross(QuizGE, 90, 91);
    DefineCross(QuizGE, 91, 92);
    DefineCross(QuizGE, 92, 93);
	DefineCross(QuizGE, 93, 94);
    DefineCross(QuizGE, 94, 95);
    DefineCross(QuizGE, 95, 96);
    DefineCross(QuizGE, 96, 164);
    DefineCross(QuizGE, 97, 162);
	DefineCross(QuizGE, 98, 99);
    DefineCross(QuizGE, 99, 100);
    DefineCross(QuizGE, 100, 157);
    DefineCross(QuizGE, 101, 104);
    DefineCross(QuizGE, 102, 163);
    DefineCross(QuizGE, 103, 165);
	DefineCross(QuizF12, 104, 161);
    DefineCross(QuizGE, 105, 103);
    DefineCross(QuizF1, 106, 188);
	DefineCross(QuizGE, 107, 107);
	DefineCross(QuizGE, 108, 109);
	DefineCross(QuizGE, 109, 110);
	DefineCross(QuizGE, 110, 111);
	DefineCross(QuizGE, 111, 112);
	DefineCross(QuizGE, 112, 113);
	DefineCross(QuizGE, 113, 170);
	DefineCross(QuizGE, 114, 116);
	DefineCross(QuizGE, 115, 117);
	DefineCross(QuizGE, 116, 118);
	DefineCross(QuizGE, 117, 119);
	DefineCross(QuizGE, 118, 120);
	DefineCross(QuizGE, 119, 121);
	DefineCross(QuizGE, 120, 122);
	DefineCross(QuizGE, 121, 123);
	DefineCross(QuizGE, 122, 124);
	DefineCross(QuizGE, 123, 125);
	DefineCross(QuizGE, 124, 126);
	DefineCross(QuizGE, 125, 127);
	DefineCross(QuizGE, 126, 128);
	DefineCross(QuizGE, 127, 129);
	DefineCross(QuizR5, 128, 9);
	DefineCross(QuizGE, 129, 131);
	DefineCross(QuizGE, 130, 132);
	DefineCross(QuizGE, 131, 133);
	DefineCross(QuizGE, 132, 134);
	DefineCross(QuizGE, 133, 135);
	DefineCross(QuizGE, 134, 136);
	DefineCross(QuizGE, 135, 138);
	DefineCross(QuizGE, 136, 137);
	DefineCross(QuizGE, 137, 139);
	DefineCross(QuizGE, 138, 140);
	DefineCross(QuizGE, 139, 141);
	DefineCross(QuizGE, 140, 142);
	DefineCross(QuizGE, 141, 143);
	DefineCross(QuizR7, 142, 6);
	DefineCross(QuizGE, 143, 145);
	DefineCross(QuizGE, 144, 146);
	DefineCross(QuizGE, 145, 114);
	DefineCross(QuizGE, 146, 147);
	DefineCross(QuizGE, 147, 148);
	DefineCross(QuizGE, 148, 149);
	DefineCross(QuizGE, 149, 150);
	DefineCross(QuizGE, 150, 151);
	DefineCross(QuizGE, 151, 152);
	DefineCross(QuizGE, 152, 153);
	DefineCross(QuizGE, 153, 154);

	DefineCross(QuizGE, 154, 155);
	DefineCross(QuizR7, 155, 83);
	DefineCross(QuizGE, 156, 157);
	DefineCross(QuizGE, 157, 158);
	DefineCross(QuizGE, 158, 159);
}

/*##########################################################################
#
#   Name       : TQuizExp2b::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizExp2b::GetReferer(const char *referer, TPopulation *pop)
{
	int i;
	TReferer *ref;
	TQuizRow Row;
	char DxArr[DX_COUNT];

	for (i = 0; i < DX_COUNT; i++)
		DxArr[DX_COUNT] = DX_STATE_UNKNOWN;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(referer))
			break;
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		if (ref->IsMatch(Row.Referer))
			pop->Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, Row.GroupResult, Row.DxResult);
}

/*##################  IsPca ##########################
*   Purpose....: Check quiz row against pca-type                 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static int IsPca(TQuizRow *row, int PcaType)
{
    switch (PcaType)
	{
		case PCA_TYPE_ALL:
		case PCA_TYPE_MIXED:
				return TRUE;

		case PCA_TYPE_MALE:
			if (row->Gender == 1)
                return TRUE;
			else
                return FALSE;

        case PCA_TYPE_FEMALE:
			if (row->Gender == 2)
				return TRUE;
			else
                return FALSE;

        case PCA_TYPE_YOUNG:
			if (row->BirthYear >= 1975)
				return TRUE;
			else
				return FALSE;

		case PCA_TYPE_OLD:
			if (row->BirthYear < 1975)
				return TRUE;
			else
				return FALSE;

		case PCA_TYPE_AS:
				if (row->Aspie == 2)
				return TRUE;
			else
                return FALSE;

    }
	return FALSE;
}

/*##################  TQuizExp2b::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizExp2b::ExportExcelCase(const char *filename, int PcaType)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < GetQuizN(); i++)
	{
		if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
		{
			file.Write("\"");

//  	      strncpy(str, Quiz[i].Text, 35);
//      	  str[35] = 0;
			sprintf(str, "#%d", i + 1);
			file.Write(str);

			file.Write("\"");
			if (i != N - 1)
				file.Write(", ");
		}
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (IsPca(&Row, PcaType))
		{
			sprintf(str, "\"%d\", ", Row.AsResult);
			file.Write(str);

			sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < GetQuizN(); i++)
			{
				if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
				{
    				ival = Row.Quiz[i];
	    			if (ival)
						ival--;
    
					if (ival > 2)
						ival = 0;
                    
					sprintf(str, "\"%d\"", ival);
					file.Write(str);
					if (i != GetQuizN() - 1)
						file.Write(", ");
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizExp2b::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizExp2b::ExportExcelAspie(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < N; i++)
	{
		file.Write("\"");

		sprintf(str, "#%d", i + 1);
		file.Write(str);

		file.Write("\"");
		if (i != N - 1)
			file.Write(", ");
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (1)
		{
			sprintf(str, "\"%d\", ", Row.AsResult);
			file.Write(str);

			sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < N; i++)
			{
				ival = Row.Quiz[i];

				if (ival)
				{
					if (Quiz[i].Reverse)
						ival = GetCatCount(i) - ival;
					else
						ival--;
				}


				if (ival >= GetCatCount(i))
					ival = 0;

				sprintf(str, "\"%d\"", ival);
				file.Write(str);
				if (i != N - 1)
					file.Write(", ");
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizExp2b::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizExp2b::ExportExcelGroups(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	int group;
	int ok;
	char str[80];
	TFile file(filename, 0);
	int GroupSum[GROUP_COUNT];
	int GroupCount[GROUP_COUNT];

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < GROUP_COUNT; i++)
	{
		file.Write("\"");

		strncpy(str, Group[i].PosName, 35);
		str[35] = 0;
//        sprintf(str, "#%d", i + 1);
		file.Write(str);

		file.Write("\"");
		if (i != GROUP_COUNT - 1)
			file.Write(", ");
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		for (i = 0; i < GROUP_COUNT; i++)
		{
			GroupSum[i] = 0;
			GroupCount[i] = 0;
		}

		for (i = 0; i < GetQuizN(); i++)
		{
			ival = Row.Quiz[i];

			if (ival)
			{
				if (Quiz[i].Reverse)
					ival = 3 - ival;
				else
					ival--;
				group = Quiz[i].MyGroup;
				GroupSum[group] += ival;
				GroupCount[group]++;
			}
		}

		ok = TRUE;
		for (i = 0; i < GROUP_COUNT; i++)
			if (GroupCount[i] == 0)
				ok = FALSE;

		if (ok)
		{
			sprintf(str, "\%d\", ", Row.AsResult);
			file.Write(str);

				sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < GROUP_COUNT; i++)
			{
				ival = round(100.0 * (long double)GroupSum[i] / (long double)GroupCount[i]);
				sprintf(str, "\"%d\"", ival);
				file.Write(str);
				if (i != GROUP_COUNT - 1)
					file.Write(", ");
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizExp2b::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizExp2b::ImportMvsp(const char *filename, int PcaType)
{
	char buf[MAX_IN_ROW];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	int i;
	long double d1, d2, d3, d4;
	int q;
	int count;
	TFile infile(filename);

	while (size = infile.Read(buf, MAX_IN_ROW))
	{
		buf[size] = 0;
		rowstr = strstr(buf, "#");
		if (rowstr)
		{
			rowstr++;
			ptr = strstr(rowstr, "\r");
			if (ptr)
				 *ptr = 0;
			else
				 rowstr = 0;
		}

		pos += strlen(buf) + 1;
		infile.SetPos(pos);

		if (rowstr)
		{
			for (i = 0; i < strlen(rowstr); i++)
			{
				switch (rowstr[i])
				{
					case ',':
						rowstr[i] = '.';
						break;

					case 0x9:
					case 0xd:
						rowstr[i] = ' ';
						break;
				}
			}

			if (sscanf(rowstr, "%d %Lf %Lf %Lf %Lf", &q, &d1, &d2, &d3, &d4) == 5)
			{
				if (PcaType != PCA_TYPE_MIXED)
				{
					if (PcaType == PCA_TYPE_FEMALE || PcaType == PCA_TYPE_MALE)
						d2 = -d2;

					if (PcaType == PCA_TYPE_ALL)
						d3 = -d3;

//					if (PcaType == PCA_TYPE_ALL)
//						d4 = -d4;

//					if (d1 > 0 && d2 > 0)
//					{
//						if (d1 > d2)
//						{
//							d1 = d1 - d2;
//							d2 = 0;
//						}
//						else
//						{
//							d2 = d2 - d1;
//							d1 = 0;
//						}
//					}
				}

				switch (PcaType)
				{
					case PCA_TYPE_ALL:
						Quiz[q - 1].Pca[0] = d1;
						Quiz[q - 1].Pca[1] = d2;
						Quiz[q - 1].Pca[2] = d3;
						Quiz[q - 1].Pca[3] = d4;
						break;

					case PCA_TYPE_MALE:
						Quiz[q - 1].MalePca[0] = d1;
						Quiz[q - 1].MalePca[1] = d2;
						Quiz[q - 1].MalePca[2] = d3;
						Quiz[q - 1].MalePca[3] = d4;
						break;

					case PCA_TYPE_FEMALE:
						Quiz[q - 1].FemalePca[0] = d1;
						Quiz[q - 1].FemalePca[1] = d2;
						Quiz[q - 1].FemalePca[2] = d3;
						Quiz[q - 1].FemalePca[3] = d4;
						break;

					case PCA_TYPE_YOUNG:
						Quiz[q - 1].YoungPca[0] = d1;
						Quiz[q - 1].YoungPca[1] = d2;
						Quiz[q - 1].YoungPca[2] = d3;
						Quiz[q - 1].YoungPca[3] = d4;
						break;

					case PCA_TYPE_OLD:
						Quiz[q - 1].OldPca[0] = d1;
						Quiz[q - 1].OldPca[1] = d2;
						Quiz[q - 1].OldPca[2] = d3;
						Quiz[q - 1].OldPca[3] = d4;
						break;

					case PCA_TYPE_ASIA:
						Quiz[q - 1].AsiaPca[0] = d1;
						Quiz[q - 1].AsiaPca[1] = d2;
						Quiz[q - 1].AsiaPca[2] = d3;
						Quiz[q - 1].AsiaPca[3] = d4;
						break;

					case PCA_TYPE_AS:
						Quiz[q - 1].AsPca[0] = d1;
						Quiz[q - 1].AsPca[1] = d2;
						Quiz[q - 1].AsPca[2] = d3;
						Quiz[q - 1].AsPca[3] = d4;
						break;

					case PCA_TYPE_MIXED:
						Quiz[q - 1].MixedPca[0] = d1;
						Quiz[q - 1].MixedPca[1] = d2;
						Quiz[q - 1].MixedPca[2] = d3;
						Quiz[q - 1].MixedPca[3] = d4;
						break;
				}
			}
		}
	}
}

/*##################  round ##########################
*   Purpose....: round long double to int       	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int round(long double val)
{
	return (int)(val + 0.5);
}

/*##################  WriteCenteredFieldHeader ##########################
*   Purpose....: Write centered field header for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteCenteredFieldHeader(TFile &File, int RelWidth)
{
	char str[80];

	sprintf(str, "\n<td width=\"%d%\" colspan=2 valign=top>\n", RelWidth);
	File.Write(str);

	File.Write("<p align=\"center\">\n");
	File.Write("<b>\n");
}

/*##################  WriteFieldFooter ##########################
*   Purpose....: Write field footer for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteFieldFooter(TFile &File)
{
	File.Write("\n</b>\n");
	File.Write("</p>\n");

	File.Write("</td>\n");
}

/*##################  TRace::TRace ##########################
*   Purpose....: Initialize TRace                 			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TRace::TRace()
{
	int i;

	for (i = 0; i < 10; i++)
	{
		UsCount[i] = 0;
		UsAsCount[i] = 0;
		NonUsCount[i] = 0;
		NonUsAsCount[i] = 0;
	}
}

/*##################  TRace::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::Add(TQuizRow *Row)
{
	int index = -1;
	int diff = Row->AsResult - Row->NtResult;

	if (Row->Country == 7302)
	{
		if (Row->Ancestry == 3)
			index = 0;      // american indian

		if (Row->Ancestry == 5)
			index = 1;

		if (Row->Ancestry == 6)
			index = 2;      // hispanic

		if (Row->Ancestry >= 1000 && Row->Ancestry < 2000)
			index = 1;

		if ((Row->Ancestry >= 2000 && Row->Ancestry < 3000) || Row->Ancestry == 3205)
			index = 3;      // white

		if (Row->Ancestry >= 3000 && Row->Ancestry < 4000 && Row->Ancestry != 3205)
			index = 4;      // arab

		if (Row->Ancestry >= 4000)
			index = 5;      // asian

		if (index >= 0)
		{
			UsCount[index]++;

			if (diff >= 35)
				UsAsCount[index]++;
		}
	}
	else
	{
		if (Row->Ancestry == 3) // && Row->Hair >= 6 && Row->Eye >= 5)
			index = 0;      // american indian

		if (Row->Ancestry == 5)
			index = 1;      // african american

		if (Row->Ancestry == 6)
			index = 2;      // hispanic

		if (Row->Ancestry >= 1000 && Row->Ancestry < 2000)
			index = 3;      // black african

		if ((Row->Ancestry >= 2000 && Row->Ancestry < 3000) || Row->Ancestry == 3205)
			index = 4;      // white

		if (Row->Ancestry >= 3000 && Row->Ancestry < 4000 && Row->Ancestry != 3205)
			index = 5;      // arab

		if (Row->Ancestry >= 4000)
			index = 6;      // asian

		if (index >= 0)
		{
			NonUsCount[index]++;

			if (diff >= 35)
				NonUsAsCount[index]++;
		}
	}
}

/*##################  TRace::WriteHeader ##########################
*   Purpose....: Write header in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteHeader(TFile &file)
{
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Race");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("All");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("Aspie");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("Interest");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("AS proportion");
	WriteFieldFooter(file);

	file.Write("</tr>");
}

/*##################  TRace::WriteEntry ##########################
*   Purpose....: Write entry in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteEntry(TFile &file, int val, int count)
{
	 char str[80];
	 long double dev;
	long double sd;
	 long double mean;
	 long double r;
	 long double rsum;
	int ival;

	 WriteCenteredFieldHeader(file, 12);

#ifdef CI

	 mean = (long double)val / (long double)count;

	 r = 1.0 - mean;
	 rsum = (long double)val * r * r;

	 r = -mean;
	 rsum += (long double)(count - val) * r * r;

	 if (count > 1 && val)
	 {
		sd = sqrt(rsum / ((long double)count - 1));

		dev = 1.96 * sd / sqrt(count);

		r = mean - dev;
		if (r < 0.0)
			r = 0.0;

		ival = round(1000.0 * r);

		sprintf(str, "%d.%01d", ival / 10, ival % 10);
		file.Write(str);

		r = mean + dev;
		if (r > 1.0)
			r = 1.0;

		ival = round(1000.0 * r);

		sprintf(str, "-%d.%01d%", ival / 10, ival % 10);
		 file.Write(str);
	}
	else
		file.Write("---");

#else
	 ival = val * 1000 / count;
	 sprintf(str, "%d.%01d%", ival / 10, ival % 10);
	 file.Write(str);
#endif

	WriteFieldFooter(file);
}

/*##################  TRace::WriteUsRow ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteUsRow(TFile &file, int index, const char *text)
{
	 char str[80];
	 int sum;
	 int i;

	file.Write("<tr style='height:24.75pt'>");
	WriteCenteredFieldHeader(file, 25);
	 file.Write(text);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", UsCount[index]);
	 file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", UsAsCount[index]);
	 file.Write(str);
	WriteFieldFooter(file);

	 sum = 0;
	for (i = 0; i < 10; i++)
		  sum += UsCount[i];

	 if (sum)
	 {
		  WriteEntry(file, UsCount[index], sum);

		if (UsCount[index])
				WriteEntry(file, UsAsCount[index], UsCount[index]);
	 }
	else
		 file.Write("---");

	 file.Write("</tr>");
}

/*##################  TRace::WriteNonUsRow ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteNonUsRow(TFile &file, int index, const char *text)
{
	 char str[80];
	 int sum;
	 int i;

	file.Write("<tr style='height:24.75pt'>");
	WriteCenteredFieldHeader(file, 25);
	 file.Write(text);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", NonUsCount[index]);
	file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", NonUsAsCount[index]);
	file.Write(str);
	WriteFieldFooter(file);

	sum = 0;
	for (i = 0; i < 10; i++)
		sum += NonUsCount[i];

	if (sum)
	{
		WriteEntry(file, NonUsCount[index], sum);

		if (NonUsCount[index])
			WriteEntry(file, NonUsAsCount[index], NonUsCount[index]);
	}
	else
		file.Write("---");

	file.Write("</tr>");
}


/*##################  TQuizExp2b::WriteRace ##########################
*   Purpose....: Write race report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizExp2b::WriteRace(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	TRace race;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		race.Add(&Row);

	file.Write("<h2>US population</h2>");

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	TRace::WriteHeader(file);

	race.WriteUsRow(file, 0, "Native American");
	race.WriteUsRow(file, 1, "Black African");
	race.WriteUsRow(file, 2, "Hispanic");
	race.WriteUsRow(file, 3, "Caucasian");
	race.WriteUsRow(file, 4, "Arab");
	race.WriteUsRow(file, 5, "Asian");

	file.Write("</table>");

	file.Write("<br><br>");

	file.Write("<h2>Non-US population</h2>");

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	TRace::WriteHeader(file);

	race.WriteNonUsRow(file, 0, "Native American");
	race.WriteNonUsRow(file, 1, "African American");
	race.WriteNonUsRow(file, 2, "Hispanic");
	race.WriteNonUsRow(file, 3, "African");
	race.WriteNonUsRow(file, 4, "Caucasian");
	race.WriteNonUsRow(file, 5, "Arab");
	race.WriteNonUsRow(file, 6, "Asian");

	file.Write("</table>");
}

/*##################  TQuizExp2b::WriteRetest ##########################
*   Purpose....: Write retest report             			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizExp2b::WriteRetest(const char *filename)
{
	TQuizRow Row;
	int userid;
	int i;
	int index;
	int birthyear;
	int birthmonth;
	int gender;
	long double val;
	long double AsSum;
	long double NtSum;
	long double AsMean;
	long double NtMean;
	long double QMean[147];
	long double AsSd;
	long double NtSd;
	long double QSd[147];
	long double AsTot;
	long double NtTot;
	int AsCount;
	int NtCount;
	long double QTot[147];
	int QCount[147];
	long double sd;
	int AsArr[20];
	int NtArr[20];
	int q;
	int count;
	long double sum;
	int QArr[14][20];
	int ok;
	char str[80];
	TFile file(filename, 0);

	for (userid = 0; userid < MAX_USERS; userid++)
		 UserInfo[userid] = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		 userid = Row.userid;

		 if (userid)
		 {
			  if (UserInfo[userid] == 0)
			  {
					UserInfo[userid] = new TUserInfo;
					UserInfo[userid]->Count = 1;
					  UserInfo[userid]->BirthYear = Row.BirthYear;
					  UserInfo[userid]->BirthMonth = Row.BirthMonth;
					UserInfo[userid]->AsSum = Row.AsResult;
					UserInfo[userid]->NtSum = Row.NtResult;
			  }
			  else
					UserInfo[userid]->Count++;
		 }
	}

	 AsCount = 0;
	 NtCount = 0;
	 AsTot = 0;
	 NtTot = 0;

	 for (q = 0; q < 147; q++)
	 {
		  QTot[q] = 0;
		  QCount[q] = 0;
	 }

	for (userid = 1; userid < MAX_USERS; userid++)
	{
		  if (UserInfo[userid])
		  {
				if (UserInfo[userid]->Count > 1)
				 {
					 for (i = 0; i < 20; i++)
					 {
						  AsArr[i] = 0;
						  NtArr[i] = 0;

						  for (q = 0; q < 14; q++)
								QArr[q][i] = 0;
					 }

					 index = 0;

					FDataFile.SetPos(0);
				 while (FDataFile.Read(&Row, sizeof(Row)))
					{
						 if (Row.userid == userid)
						 {
								ok = FALSE;

							if (index == 0)
							{
									birthyear = Row.BirthYear;
									birthmonth = Row.BirthMonth;
									gender = Row.Gender;
								 ok = TRUE;

									  UserInfo[userid]->Count = 1;
									 UserInfo[userid]->BirthYear = Row.BirthYear;
									 UserInfo[userid]->BirthMonth = Row.BirthMonth;
									UserInfo[userid]->AsSum = Row.AsResult;
									UserInfo[userid]->NtSum = Row.NtResult;
							}
							else
							  {
									if (    birthyear == Row.BirthYear &&
											  birthmonth == Row.BirthMonth &&
											gender == Row.Gender)
								 {
									  ok = TRUE;

									  UserInfo[userid]->Count++;
									  UserInfo[userid]->AsSum += Row.AsResult;
									  UserInfo[userid]->NtSum += Row.NtResult;
								 }
							}

							  if (ok)
							  {
								  AsArr[index] = Row.AsResult;
								  NtArr[index] = Row.NtResult;

								  for (q = 0; q < 14; q++)
										QArr[q][index] = Row.Quiz[q];

								 index++;
							}
					  }
				 }

				if (index > 1)
				{
					AsSum = 0;
					NtSum = 0;

					for (i = 0; i < index; i++)
					{
						AsSum += AsArr[i];
						NtSum += NtArr[i];
					 }

					AsMean = AsSum / index;
					NtMean = NtSum / index;

					for (q = 0; q < 147; q++)
					{
						 count = 0;
						  sum = 0;

						 for (i = 0; i < index; i++)
						 {
							  if (QArr[q][i])
							  {
									 sum += QArr[q][i] - 1;
									 count++;
								}
						 }

						 if (count)
							  QMean[q] = sum / count;
						 else
								QMean[q] = 0;
					}

					AsSum = 0;
					NtSum = 0;

					for (i = 0; i < index; i++)
					 {
						val = AsArr[i] - AsMean;
						AsSum += val * val;

						val = NtArr[i] - NtMean;
						NtSum += val * val;
					}

					 AsSd = sqrt(AsSum / index);
					NtSd = sqrt(NtSum / index);

					for (q = 0; q < 147; q++)
					{
						 count = 0;
						  sum = 0;

						 for (i = 0; i < index; i++)
						 {
							  if (QArr[q][i])
								{
									 val = QArr[q][i] - 1 - QMean[q];
									 sum += val * val;
									 count++;
							  }
						 }

								if (count)
								{
							 QSd[q] = sqrt(sum / count);

							 QTot[q] += QSd[q];
							 QCount[q]++;
						}
						else
							  QSd[q] = 0;
					}

						  AsTot += AsSd;
						  AsCount++;

					NtTot += NtSd;
					 NtCount++;

//  				sprintf(str, "Userid: %d, AS: %5.1Lf (%5.1Lf), NT: %5.1Lf (%5.1Lf)<br>", userid, AsMean, AsSd, NtMean, NtSd);
//	    			file.Write(str);
//
//		    		for (q = 0; q < 135; q++)
//			    	{
//				        if (QSd[q] > 0.1)
//  				    {
//        				    sprintf(str, "#%d, Sd = %5.1Lf<br>", q, QSd[q]);
//    	    			    file.Write(str);
//    		    		}
//    		        }
				}
			 }
		}
	}

	AsSd = AsTot / AsCount;
	NtSd = NtTot / NtCount;

#ifdef ENGLISH
	file.Write("<h2>Retest result</h2>\n");
#endif

#ifdef SWEDISH
	file.Write("<h2>Omtestnings resultat</h2>\n");
#endif

#ifdef ENGLISH
	sprintf(str, "Population size: %d", AsCount);
#endif

#ifdef SWEDISH
	sprintf(str, "Populationsstorlek: %d", AsCount);
#endif

	file.Write(str);
	file.Write("<br><br>");

#ifdef ENGLISH
	sprintf(str, "AS score standard deviation: %2.1Lf", AsSd);
#endif

#ifdef SWEDISH
	sprintf(str, "AS poäng standardavvikelse: %2.1Lf", AsSd);
#endif

	file.Write(str);
	file.Write("<br>");

#ifdef ENGLISH
	sprintf(str, "NT score standard deviation: %2.1Lf", NtSd);
#endif

#ifdef SWEDISH
	sprintf(str, "NT poäng standardavvikelse: %2.1Lf", NtSd);
#endif

	file.Write(str);
	file.Write("<br><br>");
}
