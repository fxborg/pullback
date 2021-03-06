//+------------------------------------------------------------------+
//|                                                cascade_lines.mq5 |
//| cascade_lines v1.00                       Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_buffers 31
#property indicator_plots 4



#property indicator_chart_window

#property indicator_type1 DRAW_COLOR_LINE
#property indicator_color1 clrDarkGreen,clrLimeGreen,clrYellow,clrOrangeRed,clrMaroon
#property indicator_width1 6

#property indicator_type2 DRAW_LINE
#property indicator_color2 clrAqua
#property indicator_width2 2

#property indicator_type3 DRAW_ARROW
#property indicator_color3 clrDeepPink
#property indicator_width3 1

#property indicator_type4 DRAW_ARROW
#property indicator_color4 clrAqua
#property indicator_width4 1




input double InpStep1Factor =0.4; //Step1Factor
input double InpStep2Factor =1.0; //Step2Factor
input bool   InpShowSign=true; // Show Sign
int AtrPeriod=100;      // ATR Period
double AtrAlpha=2.0/(AtrPeriod+1.0);
double Size1=1.0;
double Size2=1.25;
double Size3=1.5;
double Size4=1.75;
double Size5=2.0;
double Size6=2.25;
//--- input parameters
double STEP1[];
double STEP2[];
double STEP3[];
double STEP4[];
double STEP5[];
double STEP6[];
double SELL[];
double BUY[];
double ATR[];

double STEP1CLR[];
double STEP2CLR[];
double STEP3CLR[];
double STEP4CLR[];
double STEP5CLR[];
double STEP6CLR[];
double TREND1[];
double TREND2[];
double TREND1CLR[];
double TREND2CLR[];

double FAST1[];
double FAST2[];
double FAST3[];
double FAST4[];
double FAST5[];
double FAST6[];
double FAST1CLR[];
double FAST2CLR[];
double FAST3CLR[];
double FAST4CLR[];
double FAST5CLR[];
double FAST6CLR[];


int min_rates_total=2;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

//---- Initialization of variables of data calculation starting point

//--- indicator buffers
   int i=0;
   SetIndexBuffer(i++,TREND2,INDICATOR_DATA);
   SetIndexBuffer(i++,TREND2CLR,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,TREND1,INDICATOR_DATA);
   SetIndexBuffer(i++,SELL,INDICATOR_DATA);
   SetIndexBuffer(i++,BUY,INDICATOR_DATA);

   SetIndexBuffer(i++,STEP1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP1CLR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP2CLR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP3CLR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP4,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP4CLR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP5,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP5CLR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP6,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP6CLR,INDICATOR_CALCULATIONS);

   SetIndexBuffer(i++,FAST1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST1CLR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST2CLR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST3CLR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST4,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST4CLR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST5,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST5CLR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST6,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST6CLR,INDICATOR_CALCULATIONS);

   SetIndexBuffer(i++,ATR,INDICATOR_DATA);

   PlotIndexSetInteger(2,PLOT_ARROW,234);
   PlotIndexSetInteger(3,PLOT_ARROW,233);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,-30);
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,30);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int first;
   if(rates_total<=min_rates_total)
      return(0);
//---
//+----------------------------------------------------+
//|Set Median Buffeer                                |
//+----------------------------------------------------+
   int begin_pos=min_rates_total;

   first=begin_pos;
   if(first<prev_calculated) first=prev_calculated-1;

   for(int i=first;i<rates_total && !IsStopped();i++)
     {

      ATR[i]=EMPTY_VALUE;
      BUY[i]=EMPTY_VALUE;
      SELL[i]=EMPTY_VALUE;
      TREND1[i]=EMPTY_VALUE;
      TREND2[i]=EMPTY_VALUE;
      TREND2CLR[i]=EMPTY_VALUE;
      STEP1[i]=EMPTY_VALUE;
      STEP2[i]=EMPTY_VALUE;
      STEP3[i]=EMPTY_VALUE;
      STEP4[i]=EMPTY_VALUE;
      STEP5[i]=EMPTY_VALUE;
      STEP6[i]=EMPTY_VALUE;
      STEP1CLR[i]=EMPTY_VALUE;
      STEP2CLR[i]=EMPTY_VALUE;
      STEP3CLR[i]=EMPTY_VALUE;
      STEP4CLR[i]=EMPTY_VALUE;
      STEP5CLR[i]=EMPTY_VALUE;
      STEP6CLR[i]=EMPTY_VALUE;

      FAST1[i]=EMPTY_VALUE;
      FAST2[i]=EMPTY_VALUE;
      FAST3[i]=EMPTY_VALUE;
      FAST4[i]=EMPTY_VALUE;
      FAST5[i]=EMPTY_VALUE;
      FAST6[i]=EMPTY_VALUE;
      FAST1CLR[i]=EMPTY_VALUE;
      FAST2CLR[i]=EMPTY_VALUE;
      FAST3CLR[i]=EMPTY_VALUE;
      FAST4CLR[i]=EMPTY_VALUE;
      FAST5CLR[i]=EMPTY_VALUE;
      FAST6CLR[i]=EMPTY_VALUE;

      double atr=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      ATR[i]=atr;
      if(i==begin_pos)continue;
      atr=fmax(ATR[i-1]*0.667,fmin(atr,ATR[i-1]*1.333));
      ATR[i]=AtrAlpha*atr+(1-AtrAlpha)*ATR[i-1];

      double price=(close[i]+high[i]+low[i])/3;
      //--- 
      iStepMa(STEP1,STEP1CLR,price,ATR[i]*Size1*InpStep2Factor,i);
      iStepMa(STEP2,STEP2CLR,price,ATR[i]*Size2*InpStep2Factor,i);
      iStepMa(STEP3,STEP3CLR,price,ATR[i]*Size3*InpStep2Factor,i);
      iStepMa(STEP4,STEP4CLR,price,ATR[i]*Size4*InpStep2Factor,i);
      iStepMa(STEP5,STEP5CLR,price,ATR[i]*Size5*InpStep2Factor,i);
      iStepMa(STEP6,STEP6CLR,price,ATR[i]*Size6*InpStep2Factor,i);
      TREND2[i]=(STEP1[i]+STEP2[i]+STEP3[i]+STEP4[i]+STEP5[i]+STEP6[i])/6;

      int bull=0;
      int bear=0;
      if(STEP1CLR[i]==0)bull++;else bear++;
      if(STEP2CLR[i]==0)bull++;else bear++;
      if(STEP3CLR[i]==0)bull++;else bear++;
      if(STEP4CLR[i]==0)bull++;else bear++;
      if(STEP5CLR[i]==0)bull++;else bear++;
      if(STEP6CLR[i]==0)bull++;else bear++;
      double clr=0;
      if(bull==6) clr=0;
      else if(bull==5) clr=1;
      else if(bear==6) clr=4;
      else if(bear==5) clr=3;
      else clr=2;
      TREND2CLR[i]=clr;

      iStepMa(FAST1,FAST1CLR,price,ATR[i]*Size1*InpStep1Factor,i);
      iStepMa(FAST2,FAST2CLR,price,ATR[i]*Size2*InpStep1Factor,i);
      iStepMa(FAST3,FAST3CLR,price,ATR[i]*Size3*InpStep1Factor,i);
      iStepMa(FAST4,FAST4CLR,price,ATR[i]*Size4*InpStep1Factor,i);
      iStepMa(FAST5,FAST5CLR,price,ATR[i]*Size5*InpStep1Factor,i);
      iStepMa(FAST6,FAST6CLR,price,ATR[i]*Size6*InpStep1Factor,i);
      TREND1[i]=(FAST1[i]+FAST2[i]+FAST3[i]+FAST4[i]+FAST5[i]+FAST6[i])/6;

      if(!InpShowSign)continue;
      if(TREND2CLR[i]<=1 && TREND2CLR[i-1]>1)BUY[i]=low[i];
      if(TREND2CLR[i]>=3 && TREND2CLR[i-1]<3)SELL[i]=high[i];


      //--- UP TREND
      if(TREND2CLR[i]<=1 && TREND2CLR[i-1]<=1)
        {
         if(TREND1[i]>TREND1[i-1] && TREND1[i-1]<=TREND1[i-2])BUY[i]=low[i];

        }
      //--- DOWN TREND
      if(TREND2CLR[i]>=3 && TREND2CLR[i-1]>=3)
        {
         if(TREND1[i]<TREND1[i-1] && TREND1[i-1]>=TREND1[i-2])SELL[i]=high[i];

        }
     }
//----

   return(rates_total);
  }
//+------------------------------------------------------------------+
void iStepMa(double &step[],double &clr[],const double price,const double size,const int i)
  {
   if((price-size)>step[i-1]) step[i]=price-size;
   else if((price+size)<step[i-1]) step[i]=price+size;
   else step[i]=step[i-1];

   if(step[i]>step[i-1])clr[i]=0;
   else if(step[i]<step[i-1])clr[i]=1;
   else clr[i]=clr[i-1];

  }
//+------------------------------------------------------------------+
