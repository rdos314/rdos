/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2008, Leif Ekblad
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
# quizru.cpp
# Quiz class for RU
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizru.h"
#include "quizdbru.h"

#define CI      1

#define MAX_IN_ROW              4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizRU::TQuizRU
#
#   Purpose....: Constructor for TQuizRU
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizRU::TQuizRU(const char *FileName)
  : TQuiz(150),
        FDataFile(FileName)
{
        SetupTexts();
        SetupCross();

        LoadPopulations();
        Calculate();
}

/*##########################################################################
#
#   Name       : TQuizRU::~TQuizRU
#
#   Purpose....: Destructor for TQuizRU
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizRU::~TQuizRU()
{
}

/*##################  TQuizRU::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizRU::GetPcaCount()
{
        return 4;
}

/*##################  TQuizRU::GetCatCount ##########################
*   Purpose....: Return number of categories for question                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizRU::GetCatCount(int Question)
{
        return 3;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizRU::GetQuizN()
{
        return 150;
}

/*##########################################################################
#
#   Name       : TQuizRU::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizRU::WriteName(TFile &File)
{
         File.Write("RU");
}

/*##########################################################################
#
#   Name       : TQuizRU::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizRU::WriteLongName(TFile &File)
{
         File.Write("RU");
}

/*##########################################################################
#
#   Name       : TQuizRU::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizRU::SetupTexts()
{
  Quiz[0].Aspie = TRUE;
  Quiz[1].Aspie = TRUE;
  Quiz[2].Aspie = TRUE;
  Quiz[3].Aspie = TRUE;
  Quiz[4].Aspie = TRUE;
  Quiz[5].Aspie = TRUE;
  Quiz[6].Aspie = TRUE;
  Quiz[7].Aspie = TRUE;
  Quiz[8].Aspie = TRUE;
  Quiz[9].Nt = TRUE;
  Quiz[10].Nt = TRUE;
  Quiz[11].Nt = TRUE;
  Quiz[12].Nt = TRUE;
  Quiz[13].Nt = TRUE;
  Quiz[14].Nt = TRUE;
  Quiz[15].Nt = TRUE;
  Quiz[16].Nt = TRUE;
  Quiz[17].Aspie = TRUE;
  Quiz[18].Aspie = TRUE;
  Quiz[19].Aspie = TRUE;
  Quiz[20].Aspie = TRUE;
  Quiz[21].Aspie = TRUE;
  Quiz[22].Aspie = TRUE;
  Quiz[23].Aspie = TRUE;
  Quiz[24].Aspie = TRUE;
  Quiz[25].Aspie = TRUE;
  Quiz[26].Nt = TRUE;
  Quiz[27].Nt = TRUE;
  Quiz[28].Nt = TRUE;
  Quiz[29].Nt = TRUE;
  Quiz[30].Nt = TRUE;
  Quiz[31].Nt = TRUE;
  Quiz[32].Aspie = TRUE;
  Quiz[33].Aspie = TRUE;
  Quiz[34].Aspie = TRUE;
  Quiz[35].Aspie = TRUE;
  Quiz[36].Aspie = TRUE;
  Quiz[37].Aspie = TRUE;
  Quiz[38].Aspie = TRUE;
  Quiz[39].Aspie = TRUE;
  Quiz[40].Aspie = TRUE;
  Quiz[41].Aspie = TRUE;
  Quiz[42].Aspie = TRUE;
  Quiz[43].Aspie = TRUE;
  Quiz[44].Aspie = TRUE;
  Quiz[45].Aspie = TRUE;
  Quiz[46].Aspie = TRUE;
  Quiz[47].Aspie = TRUE;
  Quiz[48].Nt = TRUE;
  Quiz[49].Nt = TRUE;
  Quiz[50].Nt = TRUE;
  Quiz[51].Nt = TRUE;
  Quiz[52].Nt = TRUE;
  Quiz[53].Nt = TRUE;
  Quiz[54].Nt = TRUE;
  Quiz[55].Nt = TRUE;
  Quiz[56].Nt = TRUE;
  Quiz[57].Nt = TRUE;
  Quiz[58].Nt = TRUE;
  Quiz[59].Nt = TRUE;
  Quiz[60].Nt = TRUE;
  Quiz[61].Nt = TRUE;
  Quiz[62].Aspie = TRUE;
  Quiz[63].Aspie = TRUE;
  Quiz[64].Aspie = TRUE;
  Quiz[65].Aspie = TRUE;
  Quiz[66].Aspie = TRUE;
  Quiz[67].Aspie = TRUE;
  Quiz[68].Aspie = TRUE;
  Quiz[69].Aspie = TRUE;
  Quiz[70].Aspie = TRUE;
  Quiz[71].Aspie = TRUE;
  Quiz[72].Aspie = TRUE;
  Quiz[73].Aspie = TRUE;
  Quiz[74].Aspie = TRUE;
  Quiz[75].Aspie = TRUE;
  Quiz[76].Aspie = TRUE;
  Quiz[77].Aspie = TRUE;
  Quiz[78].Aspie = TRUE;
  Quiz[79].Aspie = TRUE;
  Quiz[80].Aspie = TRUE;
  Quiz[81].Aspie = TRUE;
  Quiz[82].Aspie = TRUE;
  Quiz[83].Aspie = TRUE;
  Quiz[84].Nt = TRUE;
  Quiz[85].Nt = TRUE;
  Quiz[86].Nt = TRUE;
  Quiz[87].Nt = TRUE;
  Quiz[88].Nt = TRUE;
  Quiz[89].Nt = TRUE;
  Quiz[90].Nt = TRUE;
  Quiz[91].Nt = TRUE;
  Quiz[92].Nt = TRUE;
  Quiz[93].Nt = TRUE;
  Quiz[94].Nt = TRUE;
  Quiz[95].Nt = TRUE;
  Quiz[96].Nt = TRUE;
  Quiz[97].Nt = TRUE;
  Quiz[98].Nt = TRUE;
  Quiz[99].Nt = TRUE;
  Quiz[100].Nt = TRUE;
  Quiz[101].Nt = TRUE;
  Quiz[102].Nt = TRUE;
  Quiz[103].Nt = TRUE;
  Quiz[104].Aspie = TRUE;
  Quiz[105].Aspie = TRUE;
  Quiz[106].Aspie = TRUE;
  Quiz[107].Aspie = TRUE;
  Quiz[108].Aspie = TRUE;
  Quiz[109].Aspie = TRUE;
  Quiz[110].Aspie = TRUE;
  Quiz[111].Aspie = TRUE;
  Quiz[112].Nt = TRUE;
  Quiz[113].Nt = TRUE;
  Quiz[114].Nt = TRUE;
  Quiz[115].Nt = TRUE;
  Quiz[116].Nt = TRUE;
  Quiz[117].Nt = TRUE;
  Quiz[118].Aspie = TRUE;
  Quiz[119].Aspie = TRUE;
  Quiz[120].Aspie = TRUE;
  Quiz[121].Aspie = TRUE;
  Quiz[122].Aspie = TRUE;
  Quiz[123].Aspie = TRUE;
  Quiz[124].Aspie = TRUE;
  Quiz[125].Aspie = TRUE;
  Quiz[126].Aspie = TRUE;
  Quiz[127].Aspie = TRUE;
  Quiz[128].Nt = TRUE;
  Quiz[129].Nt = TRUE;
  Quiz[130].Nt = TRUE;
  Quiz[131].Nt = TRUE;
  Quiz[132].Nt = TRUE;
  Quiz[133].Nt = TRUE;
  Quiz[134].Nt = TRUE;
  Quiz[135].Nt = TRUE;
  Quiz[136].Nt = TRUE;

  Quiz[145].Nt = TRUE;
  Quiz[146].Aspie = TRUE;
  Quiz[147].Nt = TRUE;
  Quiz[148].Nt = TRUE;

  Quiz[12].Reverse = TRUE;
  Quiz[16].Reverse = TRUE;
  Quiz[27].Reverse = TRUE;
  Quiz[28].Reverse = TRUE;
  Quiz[29].Reverse = TRUE;
  Quiz[30].Reverse = TRUE;
  Quiz[31].Reverse = TRUE;
  Quiz[55].Reverse = TRUE;
  Quiz[57].Reverse = TRUE;
  Quiz[58].Reverse = TRUE;
  Quiz[60].Reverse = TRUE;
  Quiz[96].Reverse = TRUE;
  Quiz[97].Reverse = TRUE;
  Quiz[98].Reverse = TRUE;
  Quiz[101].Reverse = TRUE;
  Quiz[136].Reverse = TRUE;
  Quiz[145].Reverse = TRUE;
  Quiz[146].Reverse = TRUE;
  Quiz[147].Reverse = TRUE;
  Quiz[148].Reverse = TRUE;
  Quiz[149].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[1].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[2].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[3].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[4].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[5].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[6].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[7].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[8].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[9].MyGroup = GROUP_NT_TALENT;
  Quiz[10].MyGroup = GROUP_NT_TALENT;
  Quiz[11].MyGroup = GROUP_NT_TALENT;
  Quiz[12].MyGroup = GROUP_NT_TALENT;
  Quiz[13].MyGroup = GROUP_NT_TALENT;
  Quiz[14].MyGroup = GROUP_NT_TALENT;
  Quiz[15].MyGroup = GROUP_NT_TALENT;
  Quiz[16].MyGroup = GROUP_NT_TALENT;
  Quiz[17].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[18].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[19].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[20].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[21].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[22].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[23].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[24].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[25].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[26].MyGroup = GROUP_NT_OBSESSION;
  Quiz[27].MyGroup = GROUP_NT_OBSESSION;
  Quiz[28].MyGroup = GROUP_NT_OBSESSION;
  Quiz[29].MyGroup = GROUP_NT_OBSESSION;
  Quiz[30].MyGroup = GROUP_NT_OBSESSION;
  Quiz[31].MyGroup = GROUP_NT_OBSESSION;
  Quiz[32].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[33].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[34].MyGroup = GROUP_ASPIE_SOCIAL;
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
  Quiz[48].MyGroup = GROUP_NT_SOCIAL;
  Quiz[49].MyGroup = GROUP_NT_SOCIAL;
  Quiz[50].MyGroup = GROUP_NT_SOCIAL;
  Quiz[51].MyGroup = GROUP_NT_SOCIAL;
  Quiz[52].MyGroup = GROUP_NT_SOCIAL;
  Quiz[53].MyGroup = GROUP_NT_SOCIAL;
  Quiz[54].MyGroup = GROUP_NT_SOCIAL;
  Quiz[55].MyGroup = GROUP_NT_SOCIAL;
  Quiz[56].MyGroup = GROUP_NT_SOCIAL;
  Quiz[57].MyGroup = GROUP_NT_SOCIAL;
  Quiz[58].MyGroup = GROUP_NT_SOCIAL;
  Quiz[59].MyGroup = GROUP_NT_SOCIAL;
  Quiz[60].MyGroup = GROUP_NT_SOCIAL;
  Quiz[61].MyGroup = GROUP_NT_SOCIAL;
  Quiz[62].MyGroup = GROUP_ASPIE_NVC;
  Quiz[63].MyGroup = GROUP_ASPIE_NVC;
  Quiz[64].MyGroup = GROUP_ASPIE_NVC;
  Quiz[65].MyGroup = GROUP_ASPIE_NVC;
  Quiz[66].MyGroup = GROUP_ASPIE_NVC;
  Quiz[67].MyGroup = GROUP_ASPIE_NVC;
  Quiz[68].MyGroup = GROUP_ASPIE_NVC;
  Quiz[69].MyGroup = GROUP_ASPIE_NVC;
  Quiz[70].MyGroup = GROUP_ASPIE_NVC;
  Quiz[71].MyGroup = GROUP_ASPIE_NVC;
  Quiz[72].MyGroup = GROUP_ASPIE_NVC;
  Quiz[73].MyGroup = GROUP_ASPIE_NVC;
  Quiz[74].MyGroup = GROUP_ASPIE_NVC;
  Quiz[75].MyGroup = GROUP_ASPIE_NVC;
  Quiz[76].MyGroup = GROUP_ASPIE_NVC;
  Quiz[77].MyGroup = GROUP_ASPIE_NVC;
  Quiz[78].MyGroup = GROUP_ASPIE_NVC;
  Quiz[79].MyGroup = GROUP_ASPIE_NVC;
  Quiz[80].MyGroup = GROUP_ASPIE_NVC;
  Quiz[81].MyGroup = GROUP_ASPIE_NVC;
  Quiz[82].MyGroup = GROUP_ASPIE_NVC;
  Quiz[83].MyGroup = GROUP_ASPIE_NVC;
  Quiz[84].MyGroup = GROUP_NT_NVC;
  Quiz[85].MyGroup = GROUP_NT_NVC;
  Quiz[86].MyGroup = GROUP_NT_NVC;
  Quiz[87].MyGroup = GROUP_NT_NVC;
  Quiz[88].MyGroup = GROUP_NT_NVC;
  Quiz[89].MyGroup = GROUP_NT_NVC;
  Quiz[90].MyGroup = GROUP_NT_NVC;
  Quiz[91].MyGroup = GROUP_NT_NVC;
  Quiz[92].MyGroup = GROUP_NT_NVC;
  Quiz[93].MyGroup = GROUP_NT_NVC;
  Quiz[94].MyGroup = GROUP_NT_NVC;
  Quiz[95].MyGroup = GROUP_NT_NVC;
  Quiz[96].MyGroup = GROUP_NT_NVC;
  Quiz[97].MyGroup = GROUP_NT_NVC;
  Quiz[98].MyGroup = GROUP_NT_NVC;
  Quiz[99].MyGroup = GROUP_NT_NVC;
  Quiz[100].MyGroup = GROUP_NT_NVC;
  Quiz[101].MyGroup = GROUP_NT_NVC;
  Quiz[102].MyGroup = GROUP_NT_NVC;
  Quiz[103].MyGroup = GROUP_NT_NVC;
  Quiz[104].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[105].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[106].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[107].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[108].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[109].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[110].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[111].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[112].MyGroup = GROUP_NT_HUNTING;
  Quiz[113].MyGroup = GROUP_NT_HUNTING;
  Quiz[114].MyGroup = GROUP_NT_HUNTING;
  Quiz[115].MyGroup = GROUP_NT_HUNTING;
  Quiz[116].MyGroup = GROUP_NT_HUNTING;
  Quiz[117].MyGroup = GROUP_NT_HUNTING;
  Quiz[118].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[119].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[120].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[121].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[122].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[123].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[124].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[125].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[126].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[127].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[128].MyGroup = GROUP_NT_SENSORY;
  Quiz[129].MyGroup = GROUP_NT_SENSORY;
  Quiz[130].MyGroup = GROUP_NT_SENSORY;
  Quiz[131].MyGroup = GROUP_NT_SENSORY;
  Quiz[132].MyGroup = GROUP_NT_SENSORY;
  Quiz[133].MyGroup = GROUP_NT_SENSORY;
  Quiz[134].MyGroup = GROUP_NT_SENSORY;
  Quiz[135].MyGroup = GROUP_NT_SENSORY;
  Quiz[136].MyGroup = GROUP_NT_SENSORY;
  Quiz[137].MyGroup = GROUP_ENVIRONMENT;
  Quiz[138].MyGroup = GROUP_ENVIRONMENT;
  Quiz[139].MyGroup = GROUP_ENVIRONMENT;
  Quiz[140].MyGroup = GROUP_ENVIRONMENT;
  Quiz[141].MyGroup = GROUP_ENVIRONMENT;
  Quiz[142].MyGroup = GROUP_ENVIRONMENT;
  Quiz[143].MyGroup = GROUP_ENVIRONMENT;
  Quiz[144].MyGroup = GROUP_ENVIRONMENT;

  Quiz[145].MyGroup = GROUP_NT_TALENT;
  Quiz[146].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[147].MyGroup = GROUP_NT_NVC;
  Quiz[148].MyGroup = GROUP_NT_SENSORY;
  Quiz[149].MyGroup = GROUP_ENVIRONMENT;

  Quiz[0].Text = "Вы, как правило, настолько поглощены Вашим специальным интересам, что забываете или игнорируете всё остальное?";
  Quiz[1].Text = "Вы сам или другие люди считаете(ют), что у Вас есть нестандартные способы решения проблем?";
  Quiz[2].Text = "В детстве Вы предпочитали игры, ориентированные на сортировку, строительство, исследования или разбирание предметов на части, чем социальные игры с другими детьми?";
  Quiz[3].Text = "Вы чрезвычайно упорны в сборе и каталогизации информации по интересующей теме?";
  Quiz[4].Text = "Вы нуждаетесь в периодах созерцания?";
  Quiz[5].Text = "Вы постоянно ищите закономерности в структуре, узорах, схемах предметов и вещей?";
  Quiz[6].Text = "Вы чувствуете сильное желание исправить допущенные людьми ошибки, например, в точных фактах, числах, орфографии, грамматике?";
  Quiz[7].Text = "У Вас есть особая (определенная) способность, которую Вы наиболее подчеркиваете и используйте в жизни?";
  Quiz[8].Text = "Вы склонны замечать детали, которые другие не замечают?";
  Quiz[9].Text = "Вы путаетесь в нескольких словесных указаниях, данных одновременно?";
  Quiz[10].Text = "У Вас есть трудности с описанием и обобщением вещей, например, событий, разговоров или прочтенного?";
  Quiz[11].Text = "Вам нужно что-то сделать самому, чтобы запомнить как это делается?";
  Quiz[12].Text = "Если Вас прервали, Вы быстро возвращаетесь к тому, что делали?";
  Quiz[13].Text = "Вы считаете трудным учить то, к чему у Вас нет интереса?";
  Quiz[14].Text = "Вам трудно записывать лекции?";
  Quiz[15].Text = "Вы легко отвлекаетесь?";
  Quiz[16].Text = "Вам легко делать больше одного дела одновременно?";
  Quiz[17].Text = "Считаете ли Вы жизненно важным, чтобы Вас не беспокоили, когда Вы сосредоточены на своём увлечении?";
  Quiz[18].Text = "Прежде чем что-то сделать или куда-то пойти, необходимо ли Вам иметь в голове картинку того, что произойдет, тем самым сперва подготовив себя к этому мысленно?";
  Quiz[19].Text = "Вы предпочитаете одеваться в одну и ту же одежду или есть одну и ту же пищу много дней подряд?";
  Quiz[20].Text = "Вас выводит из равновесия, когда Вас отвлекают, перебивают во время важных для Вас занятий?";
  Quiz[21].Text = "Вы расстроитесь, если не сможете сесть на Ваше любимое место?";
  Quiz[22].Text = "Вы имеете сильную привязанность к определенным любимым вещам?";
  Quiz[23].Text = "У Вас имеются определенные ритуалы, которым Вам необходимо следовать?";
  Quiz[24].Text = "Вас беспокоит или расстраивает ситуация, когда другие опаздывают или появляются раньше, чем было условлено?";
  Quiz[25].Text = "Вы нуждаетесь в списках и расписании (в письменном планировании) для того, чтобы Ваши дела были доведены до конца?";
  Quiz[26].Text = "Вы часто чувствуете себя оторванным от других людей?";
  Quiz[27].Text = "Вы любите командные виды спорта?";
  Quiz[28].Text = "Ваши взгляды типичны среди Ваших сверстников?";
  Quiz[29].Text = "Вы легко вписываетесь в ожидаемые от Вас гендерные стереотипы?";
  Quiz[30].Text = "Вы интересуетесь модой?";
  Quiz[31].Text = "Вас интересуют слухи?";
  Quiz[32].Text = "Вы склонны говорить вещи, которые считаются социально неуместными, если Вы устали, расстроены или когда Вы ведете себя естественно?";
  Quiz[33].Text = "Вам легче понимать и общаться со странными и необычными людьми (чудаками) чем с обычными?";
  Quiz[34].Text = "Ваше чувство юмора отличается от общепринятого (повсеместного) понимания или считается странным (чудаковатым)?";
  Quiz[35].Text = "Вы или другие люди считаете(ют), что у Вас необычные привычки, связанные с едой?";
  Quiz[36].Text = "У Вас альтернативная точка зрения о том, что привлекательно в противоположном поле?";
  Quiz[37].Text = "Вы отчасти мечтатель и часто витаете в собственных мыслях?";
  Quiz[38].Text = "Вы склонны к одержимости потенциальным партнером и не можете отпустить его\её?";
  Quiz[39].Text = "Ваша собственная деятельность представляется Вам более важной чем другим людям?";
  Quiz[40].Text = "Ваши чувства постоянно циклируют между безнадежностью и крайней самоуверенностью?";
  Quiz[41].Text = "У Вас проблемы с начинанием и (или) завершением проектов?";
  Quiz[42].Text = "У Вас проблемы с властями (начальством)?";
  Quiz[43].Text = "У Вас нетипичный и нерегулярный режим сна, который отклоняется от 24-часового цикла?";
  Quiz[44].Text = "Вы считаете нормы гигиены слишком строгими?";
  Quiz[45].Text = "Вы иногда не можете заснуть ночью, потому что у Вас слишком много мыслей?";
  Quiz[46].Text = "Вы испытываете в течение длительного времени сильное желание отомстить?";
  Quiz[47].Text = "У Вас необычные сексуальные предпочтения?";
  Quiz[48].Text = "У Вас склонность к зависанию, когда речь идет о социальных вопросах?";
  Quiz[49].Text = "Вы избегаете разговаривать наедине с теми, кого не знаете хорошо (с малознакомыми людьми)?";
  Quiz[50].Text = "Вы очень устаете от общения и нуждаетесь в одиночестве для восстановления сил?";
  Quiz[51].Text = "Люди считают Вас отчужденным и сдержанным человеком?";
  Quiz[52].Text = "Вам трудно быть эмоционально близким с людьми?";
  Quiz[53].Text = "Вам не нравятся прикосновения или объятия, кроме тех, к которым Вы готовы или о которых просили?";
  Quiz[54].Text = "Вам не нравится пожимать руку незнакомым людям?";
  Quiz[55].Text = "Для Вас естественно обмениваться социальными любезностями и жестами?";
  Quiz[56].Text = "Вы предпочитаете делать вещи по своему усмотрению, даже если можете использовать чужой опыт или помощь?";
  Quiz[57].Text = "Вам нравится знакомиться с новыми людьми?";
  Quiz[58].Text = "Вы чувствуете себя непринужденно в романтической ситуации?";
  Quiz[59].Text = "Вам не нравится, когда приходят незваные гости?";
  Quiz[60].Text = "Вы считаете естественным помахать или сказать 'привет', когда встречаете людей?";
  Quiz[61].Text = "Вам не нравится работать, когда за Вами наблюдают?";
  Quiz[62].Text = "Люди отмечают Ваши необычные манеры и привычки?";
  Quiz[63].Text = "У Вас часто много мыслей, которые Вам считаете трудными для выражения словами?";
  Quiz[64].Text = "В разговорах Вам требуется дополнительное время, чтобы продумать ответ, и перед Вашим ответом возникает пауза?";
  Quiz[65].Text = "Вы часто не знаете, куда девать руки?";
  Quiz[66].Text = "Люди говорили Вам или Вы сами замечали, что делаете необычное (странное) выражение лица?";
  Quiz[67].Text = "Вы, как правило, говорите либо слишком тихо либо слишком громко?";
  Quiz[68].Text = "Вам говорили, что Вы пялитесь?";
  Quiz[69].Text = "Люди говорили, что у Вас странные (чудаковатые) позы или походка?";
  Quiz[70].Text = "Вы сжимаете свои руки, потираете свои руки друг о друга или крутите своими пальцами?";
  Quiz[71].Text = "Вы раскачиваетесь вперед-назад или из стороны в сторону (например, для удобства, для самоуспокоения, когда взволнованы или перевозбуждены)?";
  Quiz[72].Text = "В разговорах Вы используете тихие звуки, которые другие люди не используют?";
  Quiz[73].Text = "Недавно услышанные мелодии и ритмы задерживаются и неоднократно воспроизводятся в Вашей голове?";
  Quiz[74].Text = "Вы затыкаете свои уши или давите на свои глаза (например, когда думате, когда напряжены или утомлены)?";
  Quiz[75].Text = "Вы повторяете слова, фразы и звуки за другими людьми (эхолалия)?";
  Quiz[76].Text = "Вы вертите предметы в руках?";
  Quiz[77].Text = "Вы расхаживаете (например, когда размышляете или тревожитесь)?";
  Quiz[78].Text = "Вы заикаетесь, когда напряжены (волнуетесь)?";
  Quiz[79].Text = "Вы, как правило, долго смотрите на людей, которые Вам нравятся, и почти (или совсем) не смотрите на людей, которые Вам не нравятся?";
  Quiz[80].Text = "Вы кусате свои губы, щеки или язык (например, когда тревожитесь или волнуетесь)?";
  Quiz[81].Text = "Испытываете ли Вы желание (побуждение) счищать соринки с себя или с других?";
  Quiz[82].Text = "Вы разговариваете сами с собой?";
  Quiz[83].Text = "Вы иногда путаете местоимения, например, говорите 'ты' или 'мы', имея в виду 'я' или наоборот?";
  Quiz[84].Text = "Вам трудно понять, как вести себя в различных ситуациях?";
  Quiz[85].Text = "У Вас есть проблемы с синхронизацией во время разговора (с улавливанием момента, когда собеседник закончил фразу и Вы можете начинать свою)?";
  Quiz[86].Text = "Вы склонны выражать свои чувства образом, могущим сбить других с толку?";
  Quiz[87].Text = "Другие люди часто не понимают Вас?";
  Quiz[88].Text = "Вы забываете, что находитесь в социальной ситуации, если что-то привлекает к себе Ваше внимание?";
  Quiz[89].Text = "Подростком Вы часто не осознавали социальных правил и границ до тех пор, пока они не бывали чётко озвучены?";
  Quiz[90].Text = "Люди говорят, что Вы улыбаетесь не к месту?";
  Quiz[91].Text = "Вы склонны интерпретировать вещи буквально?";
  Quiz[92].Text = "Люди часто говорят, что Вы зациклены на одном и том же?";
  Quiz[93].Text = "Вас часто удивляют мотивы людей?";
  Quiz[94].Text = "При разговоре Вы склонны больше фокусироваться на собственных мыслях, чем на том, что может думать Ваш слушатель?";
  Quiz[95].Text = "Вам трудно понять, почему некоторые вещи огорчают людей так сильно?";
  Quiz[96].Text = "Вы инстинктивно понимаете, когда подходит Ваша очередь говорить при разговоре по телефону?";
  Quiz[97].Text = "Вы понимаете, когда ожидается, что Вы должны принести извинения?";
  Quiz[98].Text = "Вы хорошо интерпретируете выражения лиц?";
  Quiz[99].Text = "Случалось ли Вам проявлять инициативу только затем, чтобы обнаружить, что в ней не нуждаются?";
  Quiz[100].Text = "Вы ожидаете, что другие люди будут знать о Ваших мыслях, опыте и мнениях без Вашего рассказа о них?";
  Quiz[101].Text = "Вам легко описывать свои чувства?";
  Quiz[102].Text = "У Вас монотонный голос?";
  Quiz[103].Text = "Для Вас естественно быть честным и искренним и Вы предполагаете, что другие люди ведут себя так же?";
  Quiz[104].Text = "Вы ошибались, принимая различные звуки (шум) за голоса?";
  Quiz[105].Text = "Вам нравится смотреть на вращающиеся или мерцающие объекты?";
  Quiz[106].Text = "Вас зачаровывает медленно текущая вода?";
  Quiz[107].Text = "Вы испытываете иногда побуждение перепрыгивать через предметы?";
  Quiz[108].Text = "Вам нравится имитировать звуки, издаваемые животными?";
  Quiz[109].Text = "Вы являетесь или были прежде гиперактивным(ой)?";
  Quiz[110].Text = "Вам нравится ходить на цыпочках?";
  Quiz[111].Text = "Вас привлекает изготовление ловушек?";
  Quiz[112].Text = "Вам трудно принимать сообщения по телефону и передавать их другим правильно?";
  Quiz[113].Text = "Вы бросаете какие-то вещи, когда ваше внимание занято другими вещами?";
  Quiz[114].Text = "Вы испытываете проблемы с заполнением анкет?";
  Quiz[115].Text = "Вам трудно узнавать номера телефонов, если они произносятся отличным от обычного образом?";
  Quiz[116].Text = "Вы путаете местами цифры в числах как, например, в 95 и 59?";
  Quiz[117].Text = "Вы испытываете затруднения со считыванием показаний часов?";
  Quiz[118].Text = "Вас отвлекают внезапные посторонние звуки?";
  Quiz[119].Text = "Вам трудно отфильтровывать фоновые звуки, когда Вы с кем-то разговариваете?";
  Quiz[120].Text = "Вам не нравится, когда люди идут позади Вас?";
  Quiz[121].Text = "Ярлыки на одежде или лёгкие прикосновения причиняют Вам беспокойство?";
  Quiz[122].Text = "Вы обладаете гипо- или гиперчувствительностью к физической боли, или даже испытываете удовольствие от некоторых видов боли?";
  Quiz[123].Text = "Вы обладаете очень чувствительным слухом?";
  Quiz[124].Text = "Ваши глаза обладают повышенной чувствительностью к яркому свету или сильному блеску?";
  Quiz[125].Text = "Вы чувствительны к изменениям влажности и давления воздуха?";
  Quiz[126].Text = "Ваc раздражает, когда люди постукивают ногой по полу?";
  Quiz[127].Text = "Вы инстинктивно пугаетесь звука мотоцикла?";
  Quiz[128].Text = "Вы обладаете плохим осознанием тела или контролем над ним и склонностью падать, спотыкаться или натыкаться на предметы?";
  Quiz[129].Text = "У Вас есть трудности с повторением и синхронизацией движений с другими людьми, например, например, разучивая новые шаги танца или при занятиях физкультурой?";
  Quiz[130].Text = "Вы неверно оцениваете, сколько прошло времени, когда заняты интересной деятельностью?";
  Quiz[131].Text = "Вам трудно определять возраст людей?";
  Quiz[132].Text = "Вы испытываете трудности с оценкой расстояния, высоты, глубины или скорости?";
  Quiz[133].Text = "У Вас вызывает затруднения деятельность, требующая точных движений рук, например, шитьё, завязывание шнурков на обуви, застёгивание пуговиц или манипуляции с мелкими предметами?";
  Quiz[134].Text = "Вы испытываете проблемы с нахождением пути к новому месту?";
  Quiz[135].Text = "Вы есть проблемы с узнаванием лиц (прозопагнозия)?";
  Quiz[136].Text = "Вы хорошо чувствуете, какое давление нужно прикладывать, когда делаете что-то руками?";
  Quiz[137].Text = "Вам труднее, чем другим, поддерживать дружеские отношения?";
  Quiz[138].Text = "Вы склонны к отключению или слабости, когда испытываете стресс или перегрузку?";
  Quiz[139].Text = "Вам сложнее действовать по своему усмотрению, чем, по-видимому, большинству людей того же возраста?";
  Quiz[140].Text = "Вы иногда чувствуете боязнь в безопасных ситуациях?";
  Quiz[141].Text = "Вам трудно соглашаться с критикой, поправками и указаниями?";
  Quiz[142].Text = "Вы склонны к депрессиям?";
  Quiz[143].Text = "Вас подвергали издевательствам, оскорблениям или обманывали?";
  Quiz[144].Text = "Вы нетерпеливы и имеете низкую устойчивость к фрустрации?";
  Quiz[145].Text = "Вы легко можете запомнить словесные наставления?";
  Quiz[146].Text = "Ваше чувство юмора довольно традиционное?";
  Quiz[147].Text = "Вы находите здравый смысл в том, чтобы поступать в соответствии с принятыми социальными нормами и правилами?";
  Quiz[148].Text = "Вы считаете, что легко определять возраст людей?";
  Quiz[149].Text = "Вы снисходительны к критике, поправкам и распоряжениям?";
}

/*##########################################################################
#
#   Name       : TQuizRU::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizRU::LoadPopulations()
{
        TQuizRow Row;
        int i;
        int id;
        TReferer *ref;
        char DxArr[DX_COUNT];
        char score;
        int IdArr[MAX_QUESTIONS];
        int g;
        char GroupResult[ACTIVE_GROUP_COUNT];
        char DxResult[DX_COUNT];

        for (g = 0; g < ACTIVE_GROUP_COUNT; g++)
                GroupResult[g] = 0;

        for (g = 0; g < DX_COUNT; g++)
                DxResult[g] = 0;

        for (i = 0; i < N; i++)
        {
                Quiz[i].NoAnswer = 0;
                IdArr[i] = GetGlobalId(i);
        }

        FDataFile.SetPos(0);
        while (FDataFile.Read(&Row, sizeof(Row)))
        {
                BirthMonth.Add(Row.AsResult, Row.NtResult, Row.BirthMonth);
                BirthYear.Add(Row.AsResult, Row.NtResult, Row.BirthYear, Row.Gender);

                for (i = 0; i < N; i++)
                {
                        if (Row.Quiz[i] == 0)
                                Quiz[i].NoAnswer++;
                        else
                        {
                                if (i < 150)
                                {
                                        score = Row.Quiz[i] - 1;
                                        id = IdArr[i];

//                                      DsmAs.Add(Row.Aspie, id, score);
//                                      DsmAdd.Add(Row.ADHD, id, score);
//                                      DsmSocialPhobia.Add(Row.Social, id, score);
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

                All.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

                if (Row.Aspie)
                {
                        if (Row.AsResult < Row.NtResult)
                                LowAs.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

                        if (Row.Gender == 1)
                        {
                                if (Row.BirthYear > 1986)
                                        YoungMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

                                AsMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
                        }
                        else
                        {
                                if (Row.BirthYear > 1986)
                                        YoungFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

                                AsFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
                        }

                        if (Row.Aspie == 2)
                                As.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

                        if (Row.Aspie == 1)
                                AspieControl.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
                }

                if (Row.ADHD >= 2)
                {
                        Add.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
                        if (Row.Gender == 1)
                                AddMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
                        else
                                AddFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
                }

                if (Row.Social >= 2)
                        SocialPhobia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

                if (Row.OCD >= 2)
                        OCD.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

                if (Row.NtResult - Row.AsResult >= 35)
                {
                        Nt.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
                        if (Row.Gender == 1)
                                NtMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
                        else
                                NtFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
                }

                if (Row.AsResult - Row.NtResult >= 35)
                {

                        Aspie.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
                        if (Row.Gender == 1)
                                AspieMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
                        else
                                AspieFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
                }

        }
}

/*##########################################################################
#
#   Name       : TQuizRU::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizRU::SetupCross()
{
    int i;

    for (i = 0; i < 150; i++)
            DefineGlobalId(i, i);
}

/*##########################################################################
#
#   Name       : TQuizRU::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizRU::GetReferer(const char *referer, TPopulation *pop)
{
}

/*##################  TQuizRU::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizRU::ImportMvsp(const char *filename, int PcaType)
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
            rowstr = strstr(buf, "variable loadings");
            if (rowstr)
            {
                pos += (rowstr - buf);
                break;
            }
            else
                pos += MAX_IN_ROW - 25;

            infile.SetPos(pos);
        }
        
        infile.SetPos(pos);
                                
        while (size = infile.Read(buf, MAX_IN_ROW))
        {
                buf[size] = 0;
                rowstr = strstr(buf, "C");
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
                                        if (PcaType == PCA_TYPE_ALL || PcaType == PCA_TYPE_MALE)
                                                d2 = -d2;

                                        if (PcaType == PCA_TYPE_ALL)
                                                d3 = -d3;

//                                      if (PcaType == PCA_TYPE_ALL)
//                                              d4 = -d4;

//                                      if (d1 > 0 && d2 > 0)
//                                      {
//                                              if (d1 > d2)
//                                              {
//                                                      d1 = d1 - d2;
//                                                      d2 = 0;
//                                              }
//                                              else
//                                              {
//                                                      d2 = d2 - d1;
//                                                      d1 = 0;
//                                              }
//                                      }
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
