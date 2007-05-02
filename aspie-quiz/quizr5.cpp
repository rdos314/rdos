/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# quizr5.cpp
# Quiz R5 class
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizr5.h"
#include "file.h"
#include "quizdbr5.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizR5::TQuizR5
#
#   Purpose....: Constructor for TQuizR5
#
#   In params..: Filename to load quiz 9 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR5::TQuizR5(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4)
  : TQuiz(144),
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

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	LoadPopulations();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9, QuizR1, QuizR2, QuizR3, QuizR4);
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizR5::~TQuizR5
#
#   Purpose....: Destructor for TQuizR5
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR5::~TQuizR5()
{
}

/*##################  TQuizR5::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizR5::GetPcaCount()
{
	return 4;
}

/*##########################################################################
#
#   Name       : TQuizR5::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::WriteName(TFile &File)
{
	 File.Write("R5");
}

/*##################  TQuizR5::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR5::DefineQuiz()
{
    return;
    
	DefineID(1, 330);

#ifdef ENGLISH
	DefineText(2, "Do you have a good sense of how much pressure to apply when doing things with your hands?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(2, "Har du ett bra sinne för hur hårt man bör ta i när man gör saker med händerna?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(3, "Do you find it easy to imitate & time the movements of others, e.g. when learning new dance steps or in gym class?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(3, "Har du lätt för att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(4, "Do you seldom fall, stumble or bump into things?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(4, "Är det sällan du ramlar, snubblar eller springer in i saker?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(5, "Can you easily judge distance, height, depth and speed?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(5, "Har du lätt för att bedöma avstånd, höjd, djup eller fart?", GROUP_MIXED);
#endif

	DefineID(6, 207);
	DefineID(7, 53);
	DefineID(8, 61);
	DefineID(9, 503);
	DefineID(10, 502);
	DefineID(11, 55);
	DefineID(12, 632);
	DefineID(13, 506);
	DefineID(14, 385);
	DefineID(15, 57);
	DefineID(16, 634);
	DefineID(17, 26);

#ifdef ENGLISH
	DefineText(18, "As a child, was your play more directed towards social games with other kids, than for example, sorting, building, investigating or taking things apart?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(18, "Brukade dina lekar mer bestå i sociala lekar med andra barn än att t ex sortera, bygga, undersöka eller ta isär saker?", GROUP_MIXED);
#endif

	DefineID(19, 100);
	DefineID(20, 591);

#ifdef ENGLISH
	DefineText(21, "Do you notice patterns in things all the time?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(21, "Ser du mönster i saker hela tiden?", GROUP_MIXED);
#endif

	DefineID(22, 20);
	DefineID(23, 519);
	DefineID(24, 23);
	DefineID(25, 606);
	DefineID(26, 5);
	DefineID(27, 599);
	DefineID(28, 164);
	DefineID(29, 143);

#ifdef ENGLISH
	RedefineText(30, 319, "Do you find it difficult to take notes in lectures?");
#endif

#ifdef SWEDISH
	DefineID(30, 319);
#endif

	DefineID(31, 316);
	DefineID(32, 487);
	DefineID(33, 70);
	DefineID(34, 549);
	DefineID(35, 66);
	DefineID(36, 552);

#ifdef ENGLISH
	DefineText(37, "Is it easy for you to make friends?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(37, "Har du lätt för att få vänner?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(38, "Don't you usually mind unexpected touch or an unexpected hug?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(38, "Har du oftast inget emot oväntad beröring eller en oväntad kram?", GROUP_MIXED);
#endif

	DefineID(39, 269);
	DefineID(40, 78);

#ifdef ENGLISH
	DefineText(41, "Do you feel excited in unfamiliar situations?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(41, "Blir du upprymd av okända situationer?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(42, "Do you prefer to eat different food every day?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(42, "Föredrar du att äta olika maträtter varje dag?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(43, "Do you prefer to change cloth every day?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(43, "Föredrar du att byta kläder varje dag?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(44, "Do you prefer the company of those that are the same age as yourself?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(44, "Föredrar du att umgås med jämnåriga?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(45, "Are you good at social chitchat?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(45, "Är du bra på kallprat?", GROUP_MIXED);
#endif

	DefineID(46, 31);

#ifdef ENGLISH
	DefineText(47, "Do you prefer to use others' help or expertise instead of doing things on your own?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(47, "Föredrar du att använda andras hjälp och expertis istället för att göra saker på egen hand?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(48, "Do you find it easier to communicate in real life than online?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(48, "Tycker du att det är lättare att kommunicera i verkliga livet än via dator?", GROUP_MIXED);
#endif

	DefineID(49, 255);
	DefineID(50, 545);
	DefineID(51, 363);
	DefineID(52, 595);
	DefineID(53, 366);
	DefineID(54, 34);

#ifdef ENGLISH
	DefineText(55, "Are you usually aware of/interested in what is currently in vogue?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(55, "Är du ofta medveten om/intresserad av vad som för tillfället råkar vara modernt/inne?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(56, "Do you enjoy when people drop by to visit you univited?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(56, "Gillar du när folk kommer på besök oanmälda?", GROUP_MIXED);
#endif

	DefineID(57, 256);
	DefineID(58, 282);
	DefineID(59, 277);
	DefineID(60, 25);
	DefineID(61, 443);

#ifdef ENGLISH
	DefineText(62, "Do you instinctively know when it is your turn to speak when talking on the phone?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(62, "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?", GROUP_MIXED);
#endif

	DefineID(63, 500);
	DefineID(64, 397);
	DefineID(65, 596);
	DefineID(66, 39);
	DefineID(67, 36);
	DefineID(68, 551);
	DefineID(69, 126);
	DefineID(70, 133);
	DefineID(71, 433);
	DefineID(72, 403);
	DefineID(73, 516);
	DefineID(74, 616);

#ifdef ENGLISH
	DefineText(75, "Do you naturally fit into the expected gender stereotypes?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(75, "Passar du naturligt in i de förväntade könsrollerna?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(76, "Do you have unusual eating and/or sleeping patterns?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(76, "Har du ovanliga ät- och/eller sovvanor?", GROUP_MIXED);
#endif

	DefineID(77, 240);
	DefineID(78, 623);
	DefineID(79, 592);
	DefineID(80, 17);
	DefineID(81, 518);
	DefineID(82, 101);
	DefineID(83, 448);
	DefineID(84, 473);
	DefineID(85, 234);
	DefineID(86, 123);
	DefineID(87, 362);
	DefineID(88, 600);

#ifdef ENGLISH
	DefineText(89, "Does it come more natural to you to think in words than in pictures?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(89, "Är det mer naturligt för dig att tänka i ord än i bilder?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(90, "Do you eat almost anything?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(90, "Äter du nästan allt?", GROUP_MIXED);
#endif

	DefineID(91, 16);
	DefineID(92, 523);
	DefineID(93, 638);
	DefineID(94, 637);
	DefineID(95, 574);
	DefineID(96, 575);
	DefineID(97, 589);
	DefineID(98, 590);
	DefineID(99, 402);
	DefineID(100, 582);
	DefineID(101, 624);
	DefineID(102, 572);
	DefineID(103, 573);
	DefineID(104, 401);

#ifdef ENGLISH
	DefineText(105, "Do you make unusual facial expressions?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(105, "Har du ovanliga ansiktsuttryck?", GROUP_MIXED);
#endif

	DefineID(106, 628);
	DefineID(107, 399);
	DefineID(108, 587);
	DefineID(109, 536);
	DefineID(110, 588);

#ifdef ENGLISH
	DefineText(111, "Do people understand you?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(111, "Förstår sig folk på dig?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(112, "Are you good at interpreting facial expressions?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(112, "Är du bra på att tolka ansiktsuttryck?", GROUP_MIXED);
#endif

	DefineID(113, 83);
	DefineID(114, 278);

#ifdef ENGLISH
	DefineText(115, "Can you easily remember verbal instructions?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(115, "Kommer du lätt ihåg verbala instruktioner?", GROUP_MIXED);
#endif

	DefineID(116, 6);

#ifdef ENGLISH
	DefineText(117, "Is your sense of humor fairly conventional?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(117, "Är ditt sinne för humor ganska konventionellt?", GROUP_MIXED);
#endif

	DefineID(118, 115);
	DefineID(119, 95);
	DefineID(120, 262);
	DefineID(121, 547);

#ifdef ENGLISH
	DefineText(122, "Do you intuitively sense boundraries and personal space of others?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(122, "Känner du intuitivt av andras gränser och privata sfär?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(123, "Are you sometimes afraid in safe situations?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(123, "Är du ibland rädd i ofarliga situationer?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(124, "Do you find it easy to do more than one thing at the time?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(124, "Tycker du det är lätt att göra mer än en sak i taget?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(125, "Do you find it easy to 'read between the lines' in a conversation?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(125, "Tycker du det är lätt att 'läsa mellan raderna' i en konversation?", GROUP_MIXED);
#endif

	DefineID(126, 227);
	DefineID(127, 359);

#ifdef ENGLISH
	DefineText(128, "Do you find it easy to describe & summarize for example events, conversations or something you've read?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(128, "Har du lätt för att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?", GROUP_MIXED);
#endif

	DefineID(129, 54);

#ifdef ENGLISH
	DefineText(130, "Do you easily accept criticism, correction, and direction?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(130, "Har du lätt för att acceptera kritik, korrektion och direktiv?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(131, "Do you have a good sense of what time it is?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(131, "Har du ett bra sinne för hur mycket klockan är?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(132, "Do you find it easy estimate the age of people?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(132, "Har du lätt för att bedömma människors ålder?", GROUP_MIXED);
#endif

	DefineID(133, 93);
	DefineID(134, 613);

#ifdef ENGLISH
	DefineText(135, "Do you easily recognize faces?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(135, "Har du lätt för att känna igen ansikten?", GROUP_MIXED);
#endif

	DefineID(136, 229);

#ifdef ENGLISH
	DefineText(137, "Can you easily keep track of several different people's conversations?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(137, "Kan du lätt hålla koll på flera olika människors konversationer?", GROUP_MIXED);
#endif

	DefineID(138, 119);
	DefineID(139, 287);

#ifdef ENGLISH
	DefineText(140, "Do you find it natural to wave when you meet people?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(140, "Är det naturligt för dig att vinka när du möter folk?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(141, "Do you instinctively point to things of interest?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(141, "Pekar du insktinktivt på saker du finner intressanta?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(142, "Do you instinctively cross your arms when you are in a closed state of mind?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(142, "Korsar du instinktivt dina armar när du är reserverad?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(143, "Do you interpret a pat on somebody's head as patronizing?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(143, "Uppfattar du en klapp på huvudet som nedlåtande?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(144, "Do you often don't know where to put your arms?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(144, "Vet du ofta inte var du ska göra av dina armar?", GROUP_MIXED);
#endif

}

/*##########################################################################
#
#   Name       : TQuizR5::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::SetupTexts()
{
  Quiz[1].Reverse = TRUE;
  Quiz[2].Reverse = TRUE;
  Quiz[4].Reverse = TRUE;
  Quiz[17].Reverse = TRUE;
  Quiz[36].Reverse = TRUE;
  Quiz[41].Reverse = TRUE;
  Quiz[42].Reverse = TRUE;
  Quiz[43].Reverse = TRUE;
  Quiz[44].Reverse = TRUE;
  Quiz[47].Reverse = TRUE;
  Quiz[48].Reverse = TRUE;
  Quiz[49].Reverse = TRUE;
  Quiz[54].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[56].Reverse = TRUE;
  Quiz[57].Reverse = TRUE;
  Quiz[58].Reverse = TRUE;
  Quiz[61].Reverse = TRUE;
  Quiz[74].Reverse = TRUE;
  Quiz[89].Reverse = TRUE;
  Quiz[110].Reverse = TRUE;
  Quiz[111].Reverse = TRUE;
  Quiz[114].Reverse = TRUE;
  Quiz[116].Reverse = TRUE;
  Quiz[119].Reverse = TRUE;
  Quiz[121].Reverse = TRUE;
  Quiz[123].Reverse = TRUE;
  Quiz[124].Reverse = TRUE;
  Quiz[127].Reverse = TRUE;
  Quiz[129].Reverse = TRUE;
  Quiz[130].Reverse = TRUE;
  Quiz[131].Reverse = TRUE;
  Quiz[134].Reverse = TRUE;
  Quiz[138].Reverse = TRUE;
  Quiz[139].Reverse = TRUE;
  Quiz[0].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[1].MyGroup = GROUP_MIXED;
  Quiz[2].MyGroup = GROUP_MIXED;
  Quiz[3].MyGroup = GROUP_MIXED;
  Quiz[4].MyGroup = GROUP_MIXED;
  Quiz[5].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[6].MyGroup = GROUP_SENSORY;
  Quiz[7].MyGroup = GROUP_SENSORY;
  Quiz[8].MyGroup = GROUP_SENSORY;
  Quiz[9].MyGroup = GROUP_SENSORY;
  Quiz[10].MyGroup = GROUP_SENSORY;
  Quiz[11].MyGroup = GROUP_SENSORY;
  Quiz[12].MyGroup = GROUP_SENSORY;
  Quiz[13].MyGroup = GROUP_ASPIE_COMM;
  Quiz[14].MyGroup = GROUP_SENSORY;
  Quiz[15].MyGroup = GROUP_SENSORY;
  Quiz[16].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[17].MyGroup = GROUP_MIXED;
  Quiz[18].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[19].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[20].MyGroup = GROUP_MIXED;
  Quiz[21].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[22].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[23].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[24].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[25].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[26].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[27].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[28].MyGroup = GROUP_NT_TALENT;
  Quiz[29].MyGroup = GROUP_NT_TALENT;
  Quiz[30].MyGroup = GROUP_NT_TALENT;
  Quiz[31].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[32].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[33].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[34].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[35].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[36].MyGroup = GROUP_MIXED;
  Quiz[37].MyGroup = GROUP_MIXED;
  Quiz[38].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[39].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[40].MyGroup = GROUP_MIXED;
  Quiz[41].MyGroup = GROUP_MIXED;
  Quiz[42].MyGroup = GROUP_MIXED;
  Quiz[43].MyGroup = GROUP_MIXED;
  Quiz[44].MyGroup = GROUP_MIXED;
  Quiz[45].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[46].MyGroup = GROUP_MIXED;
  Quiz[47].MyGroup = GROUP_MIXED;
  Quiz[48].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[49].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[50].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[51].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[52].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[53].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[54].MyGroup = GROUP_MIXED;
  Quiz[55].MyGroup = GROUP_MIXED;
  Quiz[56].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[57].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[58].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[59].MyGroup = GROUP_ASPIE_COMM;
  Quiz[60].MyGroup = GROUP_ASPIE_COMM;
  Quiz[61].MyGroup = GROUP_MIXED;
  Quiz[62].MyGroup = GROUP_ASPIE_COMM;
  Quiz[63].MyGroup = GROUP_ASPIE_COMM;
  Quiz[64].MyGroup = GROUP_ASPIE_COMM;
  Quiz[65].MyGroup = GROUP_ASPIE_COMM;
  Quiz[66].MyGroup = GROUP_ASPIE_COMM;
  Quiz[67].MyGroup = GROUP_ASPIE_COMM;
  Quiz[68].MyGroup = GROUP_ASPIE_COMM;
  Quiz[69].MyGroup = GROUP_ASPIE_COMM;
  Quiz[70].MyGroup = GROUP_ASPIE_COMM;
  Quiz[71].MyGroup = GROUP_ASPIE_COMM;
  Quiz[72].MyGroup = GROUP_ASPIE_COMM;
  Quiz[73].MyGroup = GROUP_ASPIE_COMM;
  Quiz[74].MyGroup = GROUP_MIXED;
  Quiz[75].MyGroup = GROUP_MIXED;
  Quiz[76].MyGroup = GROUP_ASPIE_COMM;
  Quiz[77].MyGroup = GROUP_ASPIE_COMM;
  Quiz[78].MyGroup = GROUP_ASPIE_COMM;
  Quiz[79].MyGroup = GROUP_ASPIE_COMM;
  Quiz[80].MyGroup = GROUP_ASPIE_COMM;
  Quiz[81].MyGroup = GROUP_ASPIE_COMM;
  Quiz[82].MyGroup = GROUP_ASPIE_COMM;
  Quiz[83].MyGroup = GROUP_ASPIE_COMM;
  Quiz[84].MyGroup = GROUP_ASPIE_COMM;
  Quiz[85].MyGroup = GROUP_ASPIE_COMM;
  Quiz[86].MyGroup = GROUP_ASPIE_COMM;
  Quiz[87].MyGroup = GROUP_ASPIE_COMM;
  Quiz[88].MyGroup = GROUP_MIXED;
  Quiz[89].MyGroup = GROUP_MIXED;
  Quiz[90].MyGroup = GROUP_ASPIE_COMM;
  Quiz[91].MyGroup = GROUP_ASPIE_COMM;
  Quiz[92].MyGroup = GROUP_ASPIE_COMM;
  Quiz[93].MyGroup = GROUP_ASPIE_COMM;
  Quiz[94].MyGroup = GROUP_ASPIE_NVC;
  Quiz[95].MyGroup = GROUP_ASPIE_NVC;
  Quiz[96].MyGroup = GROUP_ASPIE_NVC;
  Quiz[97].MyGroup = GROUP_ASPIE_NVC;
  Quiz[98].MyGroup = GROUP_ASPIE_NVC;
  Quiz[99].MyGroup = GROUP_ASPIE_NVC;
  Quiz[100].MyGroup = GROUP_ASPIE_NVC;
  Quiz[101].MyGroup = GROUP_ASPIE_NVC;
  Quiz[102].MyGroup = GROUP_ASPIE_NVC;
  Quiz[103].MyGroup = GROUP_ASPIE_NVC;
  Quiz[104].MyGroup = GROUP_MIXED;
  Quiz[105].MyGroup = GROUP_ASPIE_NVC;
  Quiz[106].MyGroup = GROUP_ASPIE_NVC;
  Quiz[107].MyGroup = GROUP_ASPIE_NVC;
  Quiz[108].MyGroup = GROUP_ASPIE_NVC;
  Quiz[109].MyGroup = GROUP_ASPIE_NVC;
  Quiz[110].MyGroup = GROUP_MIXED;
  Quiz[111].MyGroup = GROUP_MIXED;
  Quiz[112].MyGroup = GROUP_NONVERBAL;
  Quiz[113].MyGroup = GROUP_NONVERBAL;
  Quiz[114].MyGroup = GROUP_MIXED;
  Quiz[115].MyGroup = GROUP_NONVERBAL;
  Quiz[116].MyGroup = GROUP_MIXED;
  Quiz[117].MyGroup = GROUP_NONVERBAL;
  Quiz[118].MyGroup = GROUP_NONVERBAL;
  Quiz[119].MyGroup = GROUP_NONVERBAL;
  Quiz[120].MyGroup = GROUP_NONVERBAL;
  Quiz[121].MyGroup = GROUP_MIXED;
  Quiz[122].MyGroup = GROUP_MIXED;
  Quiz[123].MyGroup = GROUP_MIXED;
  Quiz[124].MyGroup = GROUP_MIXED;
  Quiz[125].MyGroup = GROUP_NONVERBAL;
  Quiz[126].MyGroup = GROUP_NONVERBAL;
  Quiz[127].MyGroup = GROUP_MIXED;
  Quiz[128].MyGroup = GROUP_NONVERBAL;
  Quiz[129].MyGroup = GROUP_MIXED;
  Quiz[130].MyGroup = GROUP_MIXED;
  Quiz[131].MyGroup = GROUP_MIXED;
  Quiz[132].MyGroup = GROUP_NONVERBAL;
  Quiz[133].MyGroup = GROUP_NONVERBAL;
  Quiz[134].MyGroup = GROUP_MIXED;
  Quiz[135].MyGroup = GROUP_NONVERBAL;
  Quiz[136].MyGroup = GROUP_MIXED;
  Quiz[137].MyGroup = GROUP_NONVERBAL;
  Quiz[138].MyGroup = GROUP_NONVERBAL;
  Quiz[139].MyGroup = GROUP_MIXED;
  Quiz[140].MyGroup = GROUP_MIXED;
  Quiz[141].MyGroup = GROUP_MIXED;
  Quiz[142].MyGroup = GROUP_MIXED;
  Quiz[143].MyGroup = GROUP_MIXED;

#ifdef ENGLISH
  Quiz[0].Text = "Do you look, feel or act younger than your biological age?";
  Quiz[1].Text = "Do you have a good sense of how much pressure to apply when doing things with your hands?";
  Quiz[2].Text = "Do you find it easy to imitate & time the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[3].Text = "Do you seldom fall, stumble or bump into things?";
  Quiz[4].Text = "Can you easily judge distance, height, depth and speed?";
  Quiz[5].Text = "Do you have difficulties throwing and/or catching a ball?";
  Quiz[6].Text = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
  Quiz[7].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[8].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[9].Text = "Do you have extra sensitive hearing?";
  Quiz[10].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[11].Text = "Are you affected negatively by high air humidity combined with hot weather?";
  Quiz[12].Text = "Are you sensitive to weather changes?";
  Quiz[13].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[14].Text = "Do you have a very acute sense of smell and/or taste?";
  Quiz[15].Text = "Are you sensitive to dry air?";
  Quiz[16].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[17].Text = "As a child, was your play more directed towards social games with other kids, than for example, sorting, building, investigating or taking things apart?";
  Quiz[18].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[19].Text = "Do you need to finish what you're doing before turning to another task or person?";
  Quiz[20].Text = "Do you notice patterns in things all the time?";
  Quiz[21].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[22].Text = "Do you have a hyperactive mind?";
  Quiz[23].Text = "Do you have unconventional ways of solving problems?";
  Quiz[24].Text = "Do tend to do everything worth doing, more perfect than really needed?";
  Quiz[25].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[26].Text = "Do you feel an urge to correct people with accurate facts, numbers, spelling, grammar etc., when they get something wrong?";
  Quiz[27].Text = "Do you often find reasons to question authorities?";
  Quiz[28].Text = "Are you easily distracted and/or bored?";
  Quiz[29].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[30].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[31].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[32].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[33].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[34].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[35].Text = "Do you prefer to avoid eye-contact?";
  Quiz[36].Text = "Is it easy for you to make friends?";
  Quiz[37].Text = "Don't you usually mind unexpected touch or an unexpected hug?";
  Quiz[38].Text = "Have you felt different from others for most of your life?";
  Quiz[39].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[40].Text = "Do you feel excited in unfamiliar situations?";
  Quiz[41].Text = "Do you prefer to eat different food every day?";
  Quiz[42].Text = "Do you prefer to change cloth every day?";
  Quiz[43].Text = "Do you prefer the company of those that are the same age as yourself?";
  Quiz[44].Text = "Are you good at social chitchat?";
  Quiz[45].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[46].Text = "Do you prefer to use others' help or expertise instead of doing things on your own?";
  Quiz[47].Text = "Do you find it easier to communicate in real life than online?";
  Quiz[48].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[49].Text = "Are you good at teamwork?";
  Quiz[50].Text = "Do you prefer animals to people?";
  Quiz[51].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[52].Text = "Do you feel uncomfortable with strangers?";
  Quiz[53].Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  Quiz[54].Text = "Are you usually aware of/interested in what is currently in vogue?";
  Quiz[55].Text = "Do you enjoy when people drop by to visit you univited?";
  Quiz[56].Text = "Are you energised by being in the company of others?";
  Quiz[57].Text = "Are your views typical of your peer group?";
  Quiz[58].Text = "Have you felt kinship and belonging to others for most of your life?";
  Quiz[59].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[60].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[61].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[62].Text = "Before doing something or going somewhere, do you need to visualize the place you're going to or rehearse possible scenarios in your mind so as to prepare yourself?";
  Quiz[63].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[64].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[65].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[66].Text = "Do you have certain routines which you need to follow?";
  Quiz[67].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[68].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[69].Text = "Do you have an alternative view of what is attractive in the opposite sex?";
  Quiz[70].Text = "Do you drop things when your attention is on other things?";
  Quiz[71].Text = "Have you been accused of staring?";
  Quiz[72].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[73].Text = "Are you easily distracted?";
  Quiz[74].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[75].Text = "Do you have unusual eating and/or sleeping patterns?";
  Quiz[76].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[77].Text = "Are you prone to getting depressions?";
  Quiz[78].Text = "Do you love to collect things?";
  Quiz[79].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[80].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[81].Text = "Do you have an unusual sensitivity to pain?";
  Quiz[82].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[83].Text = "Is it harder for you than for others to get over a failed relationship?";
  Quiz[84].Text = "Do you stutter when stressed?";
  Quiz[85].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[86].Text = "Have you experienced stronger than normal attachments to certain people?";
  Quiz[87].Text = "Do you find it hard to resist picking scabs or peeling skin flakes?";
  Quiz[88].Text = "Does it come more natural to you to think in words than in pictures?";
  Quiz[89].Text = "Do you eat almost anything?";
  Quiz[90].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
  Quiz[91].Text = "Are you sometimes fearless in situations that can be dangerous?";
  Quiz[92].Text = "Do you like to relax and do absolutely nothing while pondering on things of interest?";
  Quiz[93].Text = "Do you enjoy digging?";
  Quiz[94].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[95].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[96].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[97].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[98].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[99].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[100].Text = "Do you tap your fingers or fiddle with something (e.g. when bored, restless or concentrating)?";
  Quiz[101].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[102].Text = "Do you grind teeth?";
  Quiz[103].Text = "Do you talk to yourself?";
  Quiz[104].Text = "Do you make unusual facial expressions?";
  Quiz[105].Text = "Do you repeatedly blink or have twitches in eyes or face?";
  Quiz[106].Text = "Do you roll your eyes involuntary?";
  Quiz[107].Text = "Do you bite yourself (e.g. when frustrated or upset)?";
  Quiz[108].Text = "Do you clench your fists when angry?";
  Quiz[109].Text = "Do you flap your hands (e.g. when excited or upset)?";
  Quiz[110].Text = "Do people understand you?";
  Quiz[111].Text = "Are you good at interpreting facial expressions?";
  Quiz[112].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[113].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[114].Text = "Can you easily remember verbal instructions?";
  Quiz[115].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[116].Text = "Is your sense of humor fairly conventional?";
  Quiz[117].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[118].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
  Quiz[119].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[120].Text = "Do you tend to talk either too softly or too loundly?";
  Quiz[121].Text = "Do you intuitively sense boundraries and personal space of others?";
  Quiz[122].Text = "Are you sometimes afraid in safe situations?";
  Quiz[123].Text = "Do you find it easy to do more than one thing at the time?";
  Quiz[124].Text = "Do you find it easy to 'read between the lines' in a conversation?";
  Quiz[125].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[126].Text = "Do you have an odd posture or gait?";
  Quiz[127].Text = "Do you find it easy to describe & summarize for example events, conversations or something you've read?";
  Quiz[128].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[129].Text = "Do you easily accept criticism, correction, and direction?";
  Quiz[130].Text = "Do you have a good sense of what time it is?";
  Quiz[131].Text = "Do you find it easy estimate the age of people?";
  Quiz[132].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[133].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[134].Text = "Do you easily recognize faces?";
  Quiz[135].Text = "Do you have difficulties with pronunciation?";
  Quiz[136].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[137].Text = "Do you flip letters when you write?";
  Quiz[138].Text = "Are you always aware of other things going on around you even when reading or otherwise occupied?";
  Quiz[139].Text = "Do you find it natural to wave when you meet people?";
  Quiz[140].Text = "Do you instinctively point to things of interest?";
  Quiz[141].Text = "Do you instinctively cross your arms when you are in a closed state of mind?";
  Quiz[142].Text = "Do you interpret a pat on somebody's head as patronizing?";
  Quiz[143].Text = "Do you often don't know where to put your arms?";
#endif

#ifdef SWEDISH
  Quiz[0].Text = "Ser du yngre ut, känner du dig eller uppträder du som om du vore yngre än din biologiska ålder?";
  Quiz[1].Text = "Har du ett bra sinne för hur hårt man bör ta i när man gör saker med händerna?";
  Quiz[2].Text = "Har du lätt för att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[3].Text = "Är det sällan du ramlar, snubblar eller springer in i saker?";
  Quiz[4].Text = "Har du lätt för att bedöma avstånd, höjd, djup eller fart?";
  Quiz[5].Text = "Har du svårigheter med att kasta och/eller fånga en boll?";
  Quiz[6].Text = "Brukar du höra ljud som andra inte hör och plågas av höga eller störande ljud?";
  Quiz[7].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[8].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[9].Text = "Har du extra känslig hörsel?";
  Quiz[10].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[11].Text = "Brukar du påverkas negativt av hög luftfuktighet i kombination med varmt väder?";
  Quiz[12].Text = "Är du känslig för väderomslag?";
  Quiz[13].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[14].Text = "Har du extra känsligt lukt- och/eller smaksinne?";
  Quiz[15].Text = "Är du känslig för torr luft?";
  Quiz[16].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[17].Text = "Brukade dina lekar mer bestå i sociala lekar med andra barn än att t ex sortera, bygga, undersöka eller ta isär saker?";
  Quiz[18].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[19].Text = "Behöver du göra klart det du håller på med innan du kan ägna din uppmärksamhet åt något annat/någon annan?";
  Quiz[20].Text = "Ser du mönster i saker hela tiden?";
  Quiz[21].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[22].Text = "Är du mentalt hyperaktiv?";
  Quiz[23].Text = "Brukar du lösa problem på okonventionella sätt?";
  Quiz[24].Text = "Brukar du göra allt som är värt att göras, mer perfekt än vad som egentligen behövs?";
  Quiz[25].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[26].Text = "Har du svårt att låta bli att korrigera andra med korrekta fakta, siffror, stavning, grammatik etc, när de missar något?";
  Quiz[27].Text = "Tycker du att det ofta finns skäl att ifrågasätta auktoriteter?";
  Quiz[28].Text = "Blir du lätt distraherad och/eller uttråkad?";
  Quiz[29].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[30].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[31].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[32].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[33].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[34].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[35].Text = "Föredrar du att undvika ögonkontakt?";
  Quiz[36].Text = "Har du lätt för att få vänner?";
  Quiz[37].Text = "Har du oftast inget emot oväntad beröring eller en oväntad kram?";
  Quiz[38].Text = "Har du känt dig annorlunda större delen av ditt liv?";
  Quiz[39].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[40].Text = "Blir du upprymd av okända situationer?";
  Quiz[41].Text = "Föredrar du att äta olika maträtter varje dag?";
  Quiz[42].Text = "Föredrar du att byta kläder varje dag?";
  Quiz[43].Text = "Föredrar du att umgås med jämnåriga?";
  Quiz[44].Text = "Är du bra på kallprat?";
  Quiz[45].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[46].Text = "Föredrar du att använda andras hjälp och expertis istället för att göra saker på egen hand?";
  Quiz[47].Text = "Tycker du att det är lättare att kommunicera i verkliga livet än via dator?";
  Quiz[48].Text = "Trivs du i romantiska situationer?";
  Quiz[49].Text = "Är du bra på att arbeta i grupp?";
  Quiz[50].Text = "Umgås du hellre med djur än med människor?";
  Quiz[51].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[52].Text = "Känner du dig obekväm bland främmande människor?";
  Quiz[53].Text = "Föredrar du att bara umgås med folk du känner väl, på tu man hand eller i en mindre grupp?";
  Quiz[54].Text = "Är du ofta medveten om/intresserad av vad som för tillfället råkar vara modernt/inne?";
  Quiz[55].Text = "Gillar du när folk kommer på besök oanmälda?";
  Quiz[56].Text = "Får du energi av att vara i sällskap med andra?";
  Quiz[57].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[58].Text = "Har du känt att du tillhör en grupp större delen av ditt liv?";
  Quiz[59].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[60].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[61].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[62].Text = "Innan du gör något eller åker någonstans, behöver du ha en inre bild av platsen eller mentalt öva på tänkbara scenarier för att förbereda dig?";
  Quiz[63].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[64].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[65].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[66].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[67].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[68].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[69].Text = "Har du avvikande uppfattning om vad som är attraktivt hos det motsatta könet?";
  Quiz[70].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[71].Text = "Har du blivit anklagad för att stirra?";
  Quiz[72].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[73].Text = "Blir du lätt distraherad?";
  Quiz[74].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[75].Text = "Har du ovanliga ät- och/eller sovvanor?";
  Quiz[76].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[77].Text = "Brukar du få depressioner?";
  Quiz[78].Text = "Gillar du att samla?";
  Quiz[79].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[80].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[81].Text = "Har du ovanlig känslighet för smärta? ";
  Quiz[82].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[83].Text = "Är det svårare för dig än för andra att komma över en misslyckad relation";
  Quiz[84].Text = "Stammar du när du blir stressad?";
  Quiz[85].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[86].Text = "Har du upplevt starkare bindningar än normalt med vissa människor?";
  Quiz[87].Text = "Har du svårt att låta bli att pilla bort sårskorpor eller dra i flagande hud?";
  Quiz[88].Text = "Är det mer naturligt för dig att tänka i ord än i bilder?";
  Quiz[89].Text = "Äter du nästan allt?";
  Quiz[90].Text = "Blandar du ibland ihop pronomen och t ex säger "vi" eller "du" när du menar "jag" eller tvärtom?";
  Quiz[91].Text = "Händer det att du är orädd i situationer som faktiskt kan vara farliga?";
  Quiz[92].Text = "Brukar du gilla att bara slappa och göra ingenting medan du tänker på intressanta saker?";
  Quiz[93].Text = "Gillar du att gräva?";
  Quiz[94].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[95].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[96].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[97].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[98].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[99].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[100].Text = "Brukar du trumma med fingrarna eller fingra på något (t ex när du är uttråkad, rastlös eller koncenterar dig)?";
  Quiz[101].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[102].Text = "Brukar du gnissla tänder?";
  Quiz[103].Text = "Brukar du prata med dig själv?";
  Quiz[104].Text = "Har du ovanliga ansiktsuttryck?";
  Quiz[105].Text = "Brukar du ha upprepade blinkningar eller ryckningar i ögon eller ansikte?";
  Quiz[106].Text = "Rullar du med ögonen ofrivilligt?";
  Quiz[107].Text = "Brukar du bita dig själv? (t ex när du är upprörd)?";
  Quiz[108].Text = "Knyter du nävarna när du är arg?";
  Quiz[109].Text = "Brukar du vifta med händerna (t ex när du är upprymd eller upprörd)?";
  Quiz[110].Text = "Förstår sig folk på dig?";
  Quiz[111].Text = "Är du bra på att tolka ansiktsuttryck?";
  Quiz[112].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[113].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[114].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[115].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[116].Text = "Är ditt sinne för humor ganska konventionellt?";
  Quiz[117].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[118].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
  Quiz[119].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[120].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[121].Text = "Känner du intuitivt av andras gränser och privata sfär?";
  Quiz[122].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[123].Text = "Tycker du det är lätt att göra mer än en sak i taget?";
  Quiz[124].Text = "Tycker du det är lätt att 'läsa mellan raderna' i en konversation?";
  Quiz[125].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[126].Text = "Har du ovanlig kroppshållning eller gångstil?";
  Quiz[127].Text = "Har du lätt för att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[128].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[129].Text = "Har du lätt för att acceptera kritik, korrektion och direktiv?";
  Quiz[130].Text = "Har du ett bra sinne för hur mycket klockan är?";
  Quiz[131].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[132].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[133].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[134].Text = "Har du lätt för att känna igen ansikten?";
  Quiz[135].Text = "Har du svårigheter med uttal?";
  Quiz[136].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[137].Text = "Brukar du kasta om bokstäver när du skriver?";
  Quiz[138].Text = "Är du alltid medveten om det som försigår runt omkring dig även om du läser eller sysslar med något annat?";
  Quiz[139].Text = "Är det naturligt för dig att vinka när du möter folk?";
  Quiz[140].Text = "Pekar du insktinktivt på saker du finner intressanta?";
  Quiz[141].Text = "Korsar du instinktivt dina armar när du är reserverad?";
  Quiz[142].Text = "Uppfattar du en klapp på huvudet som nedlåtande?";
  Quiz[143].Text = "Vet du ofta inte var du ska göra av dina armar?";
#endif

}

/*##########################################################################
#
#   Name       : TQuizR5::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::InitReferers()
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
 }

/*##########################################################################
#
#   Name       : TQuizR5::UpdateReferer
#
#   Purpose....: Update a referer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::UpdateReferer(TReferer *ref, int AsResult, int NtResult)
{
	int diff;

	ref->Count++;
	ref->AsResult += AsResult;
	ref->NtResult += NtResult;

	diff = AsResult - NtResult;

	if (diff >= 35)
		ref->ResultAs++;
	else
	{
		if (diff <= -35)
			ref->ResultNt++;
		else
			ref->ResultMixed++;
	}
}

/*##################  TQuizR5::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR5::LoadReferers()
{
	TQuizRow Row;
	TReferer *ref;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult);

		if (Row.Autism == 1 || Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult);

		if (Row.ADHD == 1)
			UpdateReferer(&SelfAddRef, Row.AsResult, Row.NtResult);

		if (Row.Aspie == 2 || Row.Autism == 2)
			UpdateReferer(&DxAsRef, Row.AsResult, Row.NtResult);

		if (Row.ADHD == 2)
			UpdateReferer(&DxAddRef, Row.AsResult, Row.NtResult);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.Gender == 1)
				UpdateReferer(&MaleAsRef, Row.AsResult, Row.NtResult);
			else
				UpdateReferer(&FemaleAsRef, Row.AsResult, Row.NtResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizR5::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::LoadPopulations()
{
	TQuizRow Row;
	int i;
	TReferer *ref;
	int aspie;

	for (i = 0; i < N; i++)
		Quiz[i].NoAnswer = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;

		}

		aspie = FALSE;

		if (Row.Autism || Row.Aspie)
			aspie = TRUE;

		All.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

			if (Row.Gender == 1)
			{
			    if (Row.BirthYear > 1986)
			        YoungMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			        
				AsMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			}
			else
			{
			    if (Row.BirthYear > 1986)
			        YoungFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			        
				AsFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			}

			if (Row.Autism == 2 || Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.ADHD)
		{
			Add.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizR5::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::SetupControlGroups()
{
	DefineNt("flashback.info");
	DefineNt("rdos.net/sv");
	DefineNt("circvsmaximvs.com");
	DefineNt("panterachat.com");
	DefineNt("kaytastrophe.com");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##########################################################################
#
#   Name       : TQuizR5::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4)
{
    DefineCross(QuizR4, 0, 111);
    DefineGlobalId( 1, 689);
    DefineGlobalId( 2, 690);
    DefineGlobalId( 3, 691);
    DefineGlobalId( 4, 692);
    DefineCross(QuizR4, 5, 134);
    DefineCross(Quiz9, 6, 19);
    DefineCross(QuizR4, 7, 52);
    DefineCross(QuizR4, 8, 46);
    DefineCross(QuizR4, 9, 40);
    DefineCross(QuizR4, 10, 45);
    DefineCross(QuizR4, 11, 141);
    DefineCross(QuizR4, 12, 59);
    DefineCross(QuizR2, 13, 18);
    DefineCross(QuizR2, 14, 17);
    DefineCross(QuizR4, 15, 143);
    DefineCross(QuizR4, 16, 81);
    DefineGlobalId( 17, 693);
    DefineCross(Quiz9, 18, 126);
    DefineCross(QuizR4, 19, 82);
    DefineGlobalId( 20, 694);
    DefineCross(QuizR4, 21, 101);
    DefineCross(QuizR4, 22, 108);
    DefineCross(QuizR4, 23, 103);
    DefineCross(QuizR4, 24, 104);
    DefineCross(QuizR4, 25, 102);
    DefineCross(QuizR4, 26, 98);
    DefineCross(QuizII, 27, 91);
    DefineCross(QuizR2, 28, 38);
    DefineCross(QuizR3, 29, 165);
    DefineCross(Quiz8, 30, 41);
    DefineCross(QuizR4, 31, 5);
    DefineCross(QuizIII, 32, 44);
    DefineCross(QuizR4, 33, 24);
    DefineCross(QuizR4, 34, 13);
    DefineCross(QuizR4, 35, 36);
    DefineGlobalId( 36, 695);
    DefineGlobalId( 37, 696);
    DefineCross(QuizR4, 38, 0);
    DefineCross(Quiz9, 39, 62);
    DefineGlobalId( 40, 697);
    DefineGlobalId( 41, 698);
    DefineGlobalId( 42, 699);
    DefineGlobalId( 43, 700);
    DefineGlobalId( 44, 701);
    DefineCross(QuizR4, 45, 120);
    DefineGlobalId( 46, 702);
    DefineGlobalId( 47, 703);
    DefineCross(Quiz9, 48, 49);
    DefineCross(QuizR4, 49, 19);
    DefineCross(Quiz8, 50, 57);
    DefineCross(QuizR4, 51, 91);
    DefineCross(Quiz9, 52, 71);
    DefineCross(QuizR4, 53, 10);
    DefineGlobalId( 54, 704);
    DefineGlobalId( 55, 705);
    DefineCross(Quiz9, 56, 66);
    DefineCross(QuizR2, 57, 64);
    DefineCross(QuizNd, 58, 122);
    DefineCross(QuizR4, 59, 80);
    DefineCross(QuizR4, 60, 117);
    DefineGlobalId( 61, 706);
    DefineCross(QuizR2, 62, 48);
    DefineCross(QuizR4, 63, 84);
    DefineCross(QuizR4, 64, 92);
    DefineCross(QuizR4, 65, 95);
    DefineCross(QuizR4, 66, 89);
    DefineCross(QuizR4, 67, 34);
    DefineCross(QuizR4, 68, 7);
    DefineCross(QuizR4, 69, 116);
    DefineCross(QuizR2, 70, 141);
    DefineCross(QuizR4, 71, 37);
    DefineCross(QuizR4, 72, 109);
    DefineCross(QuizR4, 73, 126);
    DefineGlobalId( 74, 707);
    DefineGlobalId( 75, 708);
    DefineCross(QuizR2, 76, 110);
    DefineCross(QuizR3, 77, 179);
    DefineCross(QuizR4, 78, 88);
    DefineCross(QuizR4, 79, 25);
    DefineCross(QuizR4, 80, 130);
    DefineCross(QuizR2, 81, 14);
    DefineCross(QuizR2, 82, 15);
    DefineCross(QuizR2, 83, 113);
    DefineCross(QuizR4, 84, 139);
    DefineCross(QuizR4, 85, 31);
    DefineCross(Quiz9, 86, 133);
    DefineCross(QuizR4, 87, 97);
    DefineGlobalId( 88, 709);
    DefineGlobalId( 89, 710);
    DefineCross(Quiz9, 90, 132);
    DefineCross(QuizR4, 91, 119);
    DefineCross(QuizR4, 92, 151);
    DefineCross(QuizR4, 93, 147);
    DefineCross(QuizR4, 94, 61);
    DefineCross(QuizR4, 95, 62);
    DefineCross(QuizR4, 96, 71);
    DefineCross(QuizR4, 97, 72);
    DefineCross(QuizR4, 98, 77);
    DefineCross(QuizR4, 99, 69);
    DefineCross(QuizR4, 100, 60);
    DefineCross(QuizR4, 101, 67);
    DefineCross(QuizR3, 102, 80);
    DefineCross(QuizR4, 103, 64);
    DefineGlobalId( 104, 711);
    DefineCross(QuizR4, 105, 79);
    DefineCross(Quiz7, 106, 108);
    DefineCross(QuizR4, 107, 74);
    DefineCross(QuizR1, 108, 125);
    DefineCross(QuizR4, 109, 73);
    DefineGlobalId( 110, 712);
    DefineGlobalId( 111, 713);
    DefineCross(QuizR4, 112, 23);
    DefineCross(QuizR4, 113, 9);
    DefineGlobalId( 114, 714);
    DefineCross(QuizR4, 115, 83);
    DefineGlobalId( 116, 715);
    DefineCross(QuizR2, 117, 91);
    DefineCross(QuizR2, 118, 92);
    DefineCross(QuizR1, 119, 20);
    DefineCross(QuizR4, 120, 22);
    DefineGlobalId( 121, 716);
    DefineGlobalId( 122, 717);
    DefineGlobalId( 123, 718);
    DefineGlobalId( 124, 719);
    DefineCross(QuizR4, 125, 6);
    DefineCross(QuizR2, 126, 98);
    DefineGlobalId( 127, 720);
    DefineCross(QuizR4, 128, 43);
    DefineGlobalId( 129, 721);
    DefineGlobalId( 130, 722);
    DefineGlobalId( 131, 723);
    DefineCross(QuizR4, 132, 14);
    DefineCross(QuizR4, 133, 90);
    DefineGlobalId( 134, 724);
    DefineCross(QuizR4, 135, 138);
    DefineGlobalId( 136, 725);
    DefineCross(QuizR3, 137, 164);
    DefineCross(QuizNd, 138, 133);
    DefineGlobalId( 139, 726);
    DefineGlobalId( 140, 727);
    DefineGlobalId( 141, 728);
    DefineGlobalId( 142, 729);
    DefineGlobalId( 143, 730);
}

/*##########################################################################
#
#   Name       : TQuizR5::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR5::GetReferer(const char *referer, TPopulation *pop)
{
	int i;
	TReferer *ref;
	TQuizRow Row;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(referer))
			break;
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		if (ref->IsMatch(Row.Referer))
			pop->Add(Row.AsResult, Row.NtResult, FALSE, Row.Quiz);
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
			if (row->BirthYear >= 1980)
                return TRUE;
			else
				return FALSE;

		case PCA_TYPE_OLD:
			if (row->BirthYear <= 1965)
                return TRUE;
			else
				return FALSE;

		case PCA_TYPE_AS:
				if (row->Autism == 2 || row->Aspie == 2)
				return TRUE;
			else
                return FALSE;

    }
	return FALSE;
}

/*##################  TQuizR5::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR5::ExportExcelCase(const char *filename, int PcaType)
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

			for (i = 0; i < N; i++)
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
					if (i != N - 1)
						file.Write(", ");
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizR5::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR5::ExportExcelGroups(const char *filename)
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

		for (i = 0; i < N; i++)
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

/*##################  TQuizR5::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR5::ImportMvsp(const char *filename, int PcaType)
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
//					if (PcaType == PCA_TYPE_ALL)
//						d2 = -d2;

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
