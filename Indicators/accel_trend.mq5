//+------------------------------------------------------------------+
//|                                                  accel_trend.mq5 |
//| accel_trend                               Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#include <MovingAverages.mqh>

#property indicator_levelcolor Silver

#property indicator_minimum 0
#property indicator_maximum 1

#property indicator_buffers 7
#property indicator_plots   2
#property indicator_separate_window

#property indicator_type1 DRAW_COLOR_HISTOGRAM
#property indicator_color1 clrCornflowerBlue,clrSalmon
#property indicator_width1 4



//+------------------------------------------------------------------+

//--- input parameters

input double InpAccelSpeed=0.45;    // Accel Speed  
input int InpAccelPeriod=20;  // AccelMA Period
input int InpAccelSmooth=12;  //Smoothing
input int InpSigPeriod=15;  //Signal Period;

double  InpThreshhold=0.04; // Threshhold
int AccelPeriod=int(InpAccelSpeed*20);
double alpha=MathMax(0.001,MathMin(1,InpAccelSpeed));

//---- will be used as indicator buffers
double MA[];
double MOM[];
double VOLAT[];
double Accel[];
double HIST[];
double CLR[];

double MAIN[];
double SIG[];

//---- declaration of global variables
// SuperSmoother Filter
double SQ2=sqrt(2);
double A1 = MathExp( -SQ2  * M_PI / InpAccelSmooth );
double B1 = 2 * A1 * MathCos( SQ2 *M_PI / InpAccelSmooth );
double C2 = B1;
double C3 = -A1 * A1;
double C1 = 1 - C2 - C3;

int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

//---- Initialization of variables of data calculation starting point
   min_rates_total=2;

//--- indicator buffers
   int i=0;
   SetIndexBuffer(i++,HIST,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,MAIN,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG,INDICATOR_DATA);
   SetIndexBuffer(i++,MA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,MOM,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,VOLAT,INDICATOR_CALCULATIONS);

   for(int j=0;j<i;j++) PlotIndexSetDouble(j,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---
   ArrayResize(Accel,AccelPeriod);
   for(int j=0;j<AccelPeriod;j++) Accel[j]=pow(alpha,MathLog(j+1));

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

//---
   for(int i=first;i<rates_total && !IsStopped(); i++)
     {
      MA[i]=close[i];
      MOM[i]=close[i]-close[i-1];
      VOLAT[i]=fabs(close[i]-close[i-1]);
      //---
      HIST[i]=1.0;
      MAIN[i]=0;
      SIG[i]=EMPTY_VALUE;
      //---

      int i1st=begin_pos+fmax(AccelPeriod,InpAccelPeriod);
      if(i<=i1st)continue;
      double dsum=0.0000000001;
      double volat=0.0000000001;
      double b=0;
      double dmax=0;
      double dmin=0;
      for(int j=0;j<AccelPeriod;j++)
        {
         dsum+=MOM[i-j]*Accel[j];
         if(dsum>dmax)dmax=dsum;
         if(dsum<dmin)dmin=dsum;
        }
      //---
      for(int j=0;j<InpAccelPeriod;j++) volat+=VOLAT[i-j];
      double range=MathMax(0.0000000001,dmax-dmin);
      double accel1=range/volat;
      MA[i]=accel1*(close[i]-MA[i-1])+MA[i-1];
      //---
      MAIN[i]=C1*MA[i]+C2*MAIN[i-1]+C3*MAIN[i-2];
      //---
      int i2nd=i1st+InpSigPeriod+1;
      if(i<=i2nd)continue;

      SIG[i]=SimpleMA(i,InpSigPeriod,MAIN);
      CLR[i]=(SIG[i]<=MAIN[i]) ? 0:1;
     }

//----

   return(rates_total);
  }
//+------------------------------------------------------------------+
