//+------------------------------------------------------------------+
//|                                                      cascade.mq5 |
//| cascade indicator                         Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_buffers 15
#property indicator_plots 6



#property indicator_chart_window
#property indicator_type1 DRAW_COLOR_LINE
#property indicator_color1 clrAqua,clrDeepPink
#property indicator_width1 2

#property indicator_type2 DRAW_COLOR_LINE
#property indicator_color2 clrAqua,clrDeepPink
#property indicator_width2 2

#property indicator_type3 DRAW_COLOR_LINE
#property indicator_color3 clrAqua,clrDeepPink
#property indicator_width3 2

#property indicator_type4 DRAW_COLOR_LINE
#property indicator_color4 clrAqua,clrDeepPink
#property indicator_width4 2

#property indicator_type5 DRAW_COLOR_LINE
#property indicator_color5 clrAqua,clrDeepPink
#property indicator_width5 2

#property indicator_type6 DRAW_COLOR_LINE
#property indicator_color6 clrAqua,clrDeepPink
#property indicator_width6 2

//+------------------------------------------------------------------+

//--- input parameters
input double InpSize =0.8; //Size
int AtrPeriod=100;      // ATR Period
double AtrAlpha=2.0/(AtrPeriod+1.0);


double Size1=1.0;
double Size2=1.25;
double Size3=1.5;
double Size4=1.75;
double Size5=2.0;
double Size6=2.25;
//---- will be used as indicator buffers
double STEP1[];
double STEP2[];
double STEP3[];
double STEP4[];
double STEP5[];
double STEP6[];

double CLR1[];
double CLR2[];
double CLR3[];
double CLR4[];
double CLR5[];
double CLR6[];
double TREND[];
double CLR[];
double ATR[];

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
   SetIndexBuffer(i++,STEP1,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR1,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,STEP2,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR2,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,STEP3,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR3,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,STEP4,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR4,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,STEP5,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR5,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,STEP6,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR6,INDICATOR_COLOR_INDEX);

   SetIndexBuffer(i++,TREND,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,ATR,INDICATOR_DATA);
  
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
         
         double atr=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
         ATR[i]=atr;
         if(i==begin_pos)continue;
         atr=fmax(ATR[i-1]*0.667,fmin(atr,ATR[i-1]*1.333));
         ATR[i]=AtrAlpha*atr+(1-AtrAlpha)*ATR[i-1];
     
         double price=(close[i]+high[i]+low[i])/3;
         //--- 
         iStepMa(STEP1,CLR1,price,ATR[i]*Size1*InpSize,i);
         iStepMa(STEP2,CLR2,price,ATR[i]*Size2*InpSize,i);
         iStepMa(STEP3,CLR3,price,ATR[i]*Size3*InpSize,i);
         iStepMa(STEP4,CLR4,price,ATR[i]*Size4*InpSize,i);
         iStepMa(STEP5,CLR5,price,ATR[i]*Size5*InpSize,i);
         iStepMa(STEP6,CLR6,price,ATR[i]*Size6*InpSize,i);
     }

//----

   return(rates_total);
  }
//+------------------------------------------------------------------+

void iStepMa(double &step[],double &clr[],const double price,const double size,const int i)
{
         if(clr[i-1]==0)
         {
            if((price-size)>step[i-1]) step[i]=price-size;
            else if((price+size)<step[i-1]) step[i]=price+size;
            else step[i]=step[i-1];
         }
         else
         {
            if((price-size)>step[i-1]) step[i]=price-size;
            else if((price+size)<step[i-1]) step[i]=price+size;
            else step[i]=step[i-1];
         }
         if(step[i]>step[i-1])clr[i]=0;
         else if(step[i]<step[i-1])clr[i]=1;
         else clr[i]=clr[i-1];

}