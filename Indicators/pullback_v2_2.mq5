﻿//+------------------------------------------------------------------+
//|                                               pullback_v2_00.mq5 |
//| pullback 2.0                              Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "2.2"

#include <MovingAverages.mqh>

#property indicator_buffers 28
#property indicator_plots 8
#property indicator_chart_window

#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrRed
#property indicator_width1 1

#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrDodgerBlue
#property indicator_width2 1

#property indicator_type3 DRAW_COLOR_LINE
#property indicator_color3 clrAqua,clrDeepPink
#property indicator_width3 1

#property indicator_type4 DRAW_LINE
#property indicator_color4 clrNONE
#property indicator_width4 1

#property indicator_type5 DRAW_LINE
#property indicator_color5 clrNONE
#property indicator_width5 2
//+------------------------------------------------------------------+
//| CSignal                                                          |
//+------------------------------------------------------------------+
class CSignal
  {
protected:
   int               m_entry_count,m_sig,m_brake_pos,m_prev_pos,m_1st_pos,m_2nd_pos,m_3rd_pos,m_min_pos,m_max_pos;
   double            m_min,m_max;

public:
   void              CSignal(){};                   // constructor
   void             ~CSignal(){};                   // destructor
   void              Init()
     {
      m_entry_count=0; m_sig=0; m_brake_pos=NULL;m_prev_pos=2; m_1st_pos=NULL;  m_2nd_pos=NULL;  m_3rd_pos=NULL;
      m_min_pos=NULL;  m_max_pos=NULL; m_min=NULL; m_max=NULL;
     }
   void              Begin(int a,int b, int sig){ Init(); m_1st_pos=a; m_brake_pos=b; m_sig=sig;}
   void              Exit()                     { int a=m_brake_pos;Init(); m_prev_pos = a;}
   int               Sig()                      { return m_sig;}
   int               GetBrakePos()              { return m_brake_pos;}
   int               Get1stPos()                { return m_1st_pos;}
   int               Get2ndPos()                { return m_2nd_pos;}
   int               Get3rdPos()                { return m_3rd_pos;}
   void              UpdateMax(int i,double v)  { if(m_max==NULL || v>m_max){m_max=v; m_max_pos=i;}}
   int               GetMaxPos()                { return m_max_pos;}
   void              UpdateMin(int i,double v)  { if(m_min==NULL || v<m_min){m_min=v; m_min_pos=i;}}
   int               GetMinPos()                { return m_min_pos;}
   int               GetPrevPos()               { return m_prev_pos;}

   void              SetNextPos(int i)
     {
      if(State()==1)m_2nd_pos=i;
      else if(State()==2)m_3rd_pos=i;
      m_min_pos=NULL; m_min=NULL;m_max_pos=NULL;m_max=NULL;
     }

   int               State()
     {
      if(m_3rd_pos!=NULL) return 3;
      else if(m_2nd_pos!=NULL)return 2;
      else if(m_brake_pos!=NULL)return 1;
      else return 0;
     }
   int               EntryCount(){return m_entry_count;}
   void              Entry(){m_entry_count++;};

   int               NextDir()
     {
      // (sig=1)->l-h-l ,(sig= -1)->h-l-h
      if(m_sig==0) return 0;
      int dir = (( 1 & State()) == 1) ? 1  : -1;
      return  (dir * m_sig);
     }
  };
//+------------------------------------------------------------------+
//| CStatus                                                            |
//+------------------------------------------------------------------+
class CStatus
  {
protected:
   int               m_calc_pos;
   int               m_turn;
   int               m_turn_pos;
   datetime          m_old_time;

public:
   void              CStatus(){};                   // constructor
   void             ~CStatus(){};                   // destructor
   void              Init()
     {
      m_turn=NULL;
      m_turn_pos=NULL;
      m_old_time=0;
      m_calc_pos=NULL;
     }
   void              SetCalcPos(int p) {m_calc_pos=p;}
   int               CalcPos() {return m_calc_pos;}
   int               Turn() { return m_turn;}
   void              SetTurn(int p,int v) {m_turn_pos=p;  m_turn=v;}
   int               TurnPos() { return m_turn_pos;}
   //---
   bool IsNewBar()
     {
      //---
      bool res=false;            // variable for the analysis result
      datetime new_time[1];      // time of a new bar
      //---
      int copied=CopyTime(_Symbol,PERIOD_CURRENT,0,1,new_time); // copy the last bar time into the new_time cell
      //---
      if(copied>0) //  Data have been copied
        {
         if(m_old_time!=new_time[0]) // if the old time of the bar is not equal to new one
           {
            res=true;
            m_old_time=new_time[0];     // store the bar's time
           }
        }
      //---
      return(res);
     }

  };
//+------------------------------------------------------------------+
//| CBuffer                                                          |
//+------------------------------------------------------------------+
class CBuffer
  {
protected:
   int               m_size;
   int               m_index[];
   double            m_data[];
   int               m_last_pos;
public:
   void              CBuffer(){};                   // constructor
   void             ~CBuffer(){};                   // destructor
   void              Init(const int sz)
     {
      m_size=sz;
      m_last_pos=0;
      ArrayResize(m_index,m_size);
      ArrayResize(m_data,m_size);
      ArrayFill(m_index,0,m_size,NULL);
      ArrayFill(m_data,0,m_size,NULL);
     }
   int Size() { return m_size;}
   double GetValue(const int pos) const
     {
      if(pos < 0 && pos >= m_size) return (NULL);
      return ( m_data [((m_size + ((m_last_pos-pos)-1)) % m_size)]);
     }
   int GetIndex(const int pos) const
     {
      if(pos < 0 && pos >= m_size) return (NULL);
      return ( m_index [((m_size + ((m_last_pos-pos)-1)) % m_size)]);
     }
   void Add(const int index,const double value)
     {
      int pos=(m_size+(m_last_pos-1))%m_size;

      if(m_index[pos]==index)
        {
         m_data[pos]=value;
        }
      else
        {
         m_data[m_last_pos]=value;
         m_index[m_last_pos]=index;
         m_last_pos=(m_last_pos+1)%m_size;
        }
     }
  };

//+------------------------------------------------------------------+

//--- input parameters

input double InpStep1Size=0.5;  //1st Step Size
input double InpStep2Size=2;   //2nd Step Size
input int InpEmaPeriod=60;  //Secound EMA Period
input int InpAdxPeriod=14;  //DX Period
int InpBackStep=20;   //Back Step

int InpKPeriod=5;  // K period
int InpDPeriod=3;  //D period
int InpSlowing=3;  // Slowing


int AtrPeriod=100;      // ATR Period
double AtrAlpha=2.0/(AtrPeriod+1.0);
double AdxAlpha=(InpAdxPeriod-1.0)/InpAdxPeriod;
double EmaAlpha=2.0/(InpEmaPeriod+1.0);

//---- will be used as indicator buffers
double OSC[];
double OSCSIG[];
//--- ADX
double SPDI[];
double SMDI[];
double STR[];
double PDI[];
double MDI[];
double ADX[];
//---
double SL[];

double EMA[];
double PRICE[];
double STEP2[];
double CNR[];

double UPPER[];
double LOWER[];

double UP1[];
double DN1[];
double UP2[];
double DN2[];
double ATR[];
double BUY[];
double SELL[];

double BAR[];
double CNT[];
double CLR1[];
double CLR2[];
double HI[];
double LO[];

bool IsReset=false;
CSignal DnSignal;
CSignal UpSignal;
CStatus Stat;
CBuffer TurnBuffer;
CBuffer StepBuffer;

//---- declaration of global variables

int min_rates_total=5;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
//--- indicator buffers
   int i=0;

   SetIndexBuffer(i++,SELL,INDICATOR_DATA);
   SetIndexBuffer(i++,BUY,INDICATOR_DATA);
   SetIndexBuffer(i++,STEP2,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR2,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,EMA,INDICATOR_DATA);
   SetIndexBuffer(i++,ATR,INDICATOR_DATA);
   SetIndexBuffer(i++,SL,INDICATOR_DATA);
   SetIndexBuffer(i++,ADX,INDICATOR_DATA);
   SetIndexBuffer(i++,DN1,INDICATOR_DATA);
   SetIndexBuffer(i++,UP1,INDICATOR_DATA);
   SetIndexBuffer(i++,DN2,INDICATOR_DATA);
   SetIndexBuffer(i++,UP2,INDICATOR_DATA);
   SetIndexBuffer(i++,CNT,INDICATOR_DATA);
   SetIndexBuffer(i++,BAR,INDICATOR_DATA);
   SetIndexBuffer(i++,UPPER,INDICATOR_DATA);
   SetIndexBuffer(i++,LOWER,INDICATOR_DATA);
   SetIndexBuffer(i++,OSC,INDICATOR_DATA);
   SetIndexBuffer(i++,OSCSIG,INDICATOR_DATA);
   SetIndexBuffer(i++,HI,INDICATOR_DATA);
   SetIndexBuffer(i++,LO,INDICATOR_DATA);

   SetIndexBuffer(i++,PDI,INDICATOR_DATA);
   SetIndexBuffer(i++,MDI,INDICATOR_DATA);
   SetIndexBuffer(i++,SPDI,INDICATOR_DATA);
   SetIndexBuffer(i++,SMDI,INDICATOR_DATA);
   SetIndexBuffer(i++,STR,INDICATOR_DATA);

   SetIndexBuffer(i++,CNR,INDICATOR_DATA);
   SetIndexBuffer(i++,PRICE,INDICATOR_DATA);

   for(int j=2;j<i;j++) PlotIndexSetDouble(j,PLOT_EMPTY_VALUE,0);

   PlotIndexSetInteger(0,PLOT_ARROW,234);
   PlotIndexSetInteger(1,PLOT_ARROW,233);
   PlotIndexSetInteger(4,PLOT_ARROW,140);
   PlotIndexSetInteger(5,PLOT_ARROW,140);
   PlotIndexSetInteger(6,PLOT_ARROW,141);
   PlotIndexSetInteger(7,PLOT_ARROW,141);

   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,-30);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,30);
   PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,-15);
   PlotIndexSetInteger(5,PLOT_ARROW_SHIFT,15);
   PlotIndexSetInteger(6,PLOT_ARROW_SHIFT,15);
   PlotIndexSetInteger(7,PLOT_ARROW_SHIFT,-15);

//---
   DnSignal.Init();
   UpSignal.Init();
   Stat.Init();
   TurnBuffer.Init(100);
   StepBuffer.Init(100);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

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
   Stat.SetCalcPos(fmax(0,prev_calculated-2));

//---
   int i,first;
   if(rates_total<=min_rates_total)
      return(0);
   int begin_pos=min_rates_total;
//---
   if(!Stat.IsNewBar()) return rates_total;

//+----------------------------------------------------+
//|Set Median Buffeer                                |
//+----------------------------------------------------+
   first=begin_pos;
   if(first<prev_calculated) first=prev_calculated-1;
//---
   for(int bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      i=bar-1;
      if(CNT[i]==1)continue;
      BAR[bar]=bar;
      CNT[i]=1;
      SPDI[bar]=EMPTY_VALUE;
      SMDI[bar]=EMPTY_VALUE;
      PDI[bar]=EMPTY_VALUE;
      MDI[bar]=EMPTY_VALUE;
      ADX[bar]=EMPTY_VALUE;
      STR[bar]=EMPTY_VALUE;
      UPPER[bar]=EMPTY_VALUE;
      LOWER[bar]=EMPTY_VALUE;
      STEP2[bar]=EMPTY_VALUE;
      CLR2[bar]=EMPTY_VALUE;
      ATR[bar]=EMPTY_VALUE;
      EMA[bar]=EMPTY_VALUE;
      BUY[bar]=EMPTY_VALUE;
      SELL[bar]=EMPTY_VALUE;
      PRICE[bar]=EMPTY_VALUE;
      UP1[bar]=EMPTY_VALUE;
      UP2[bar]=EMPTY_VALUE;
      DN1[bar]=EMPTY_VALUE;
      DN2[bar]=EMPTY_VALUE;
      OSC[bar]=EMPTY_VALUE;
      OSCSIG[bar]=EMPTY_VALUE;

      if(i==begin_pos)
        {
         // only first time
         ATR[i]=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
         EMA[i]=close[i];
        }
      else
        {
         double atr=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
         atr=fmax(ATR[i-1]*0.667,fmin(atr,ATR[i-1]*1.333));
         ATR[i]=AtrAlpha*atr+(1-AtrAlpha)*ATR[i-1];
         EMA[i]=EmaAlpha*close[i]+(1-EmaAlpha)*EMA[i-1];
        }


      PRICE[i]=(low[i]+high[i]+close[i])/3;
      //---
      //--- ADX
      double tr=fmax(high[i],close[i-1])-fmin(low[i],close[i-1]);
      double hh= high[i]-high[i-1];
      double ll= low[i-1]-low[i];
      double pdm=(hh > ll && hh>0) ? hh : 0.0;
      double mdm=(ll > hh && ll>0) ? ll : 0.0;
      //---
      SPDI[i]= AdxAlpha * SPDI[i-1] + pdm;
      SMDI[i]= AdxAlpha * SMDI[i-1] + mdm;
      STR[i]=AdxAlpha*STR[i-1]+tr;
      //---
      PDI[i] = (STR[i] > 0) ? 100.00 * SPDI[i]/STR[i] : 0.0;
      MDI[i] = (STR[i] > 0) ? 100.00 * SMDI[i]/STR[i] : 0.0;
      //---
      double DX=0.0;
      if((PDI[i]+MDI[i])>0) DX=100*fabs(PDI[i]-MDI[i])/(PDI[i]+MDI[i]);
      ADX[i]=AdxAlpha *ADX[i-1]+DX/InpAdxPeriod;
      //---
      int i1st=begin_pos+5+InpKPeriod+InpDPeriod+InpSlowing;
      if(i<=i1st) continue;
      //--- Stochastics
      HI[i]=high[ArrayMaximum(high,i-(InpKPeriod-1),InpKPeriod)];
      LO[i]=low[ArrayMinimum(low,i-(InpKPeriod-1),InpKPeriod)];

      double sumlow=0.0;
      double sumhigh=0.0;
      for(int k=(i-InpSlowing+1);k<=i;k++)
        {
         sumlow +=(close[k]-LO[k]);
         sumhigh+=(HI[k]-LO[k]);
        }
      OSC[i]=(sumhigh==0)? 50 :(sumlow/sumhigh*100);
      OSCSIG[i]=SimpleMA(i,InpDPeriod,OSC);
      //---
      //---
      double base=ATR[i]*InpStep1Size;
      double up=(high[i]+close[i])/2;
      double dn=(low[i]+close[i])/2;
      double mid=(close[i]);
      //---      

      //--- 
      if((up-base)>UPPER[i-1]) UPPER[i]=up;
      else if((up+base)<UPPER[i-1]) UPPER[i]=up+base;
      else UPPER[i]=UPPER[i-1];
      //--- 
      if((dn-base)>LOWER[i-1]) LOWER[i]=dn-base;
      else if((dn+base)<LOWER[i-1]) LOWER[i]=dn;
      else LOWER[i]=LOWER[i-1];
      //--- 

      base=ATR[i]*InpStep2Size;
      //--- 
      if((PRICE[i]-base)>STEP2[i-1]) STEP2[i]=PRICE[i]+base*0.5;
      else if((PRICE[i]+base)<STEP2[i-1]) STEP2[i]=PRICE[i]+base*0.5;
      else STEP2[i]=STEP2[i-1];

      if(STEP2[i]>STEP2[i-1])CLR2[i]=0;
      else if(STEP2[i]<STEP2[i-1])CLR2[i]=1;
      else CLR2[i]=CLR2[i-1];

      int x1=TurnBuffer.GetIndex(0);
      double v1=TurnBuffer.GetValue(0);

      if(STEP2[i]>STEP2[i-1])
         if(x1==NULL || (x1!=NULL && v1==-1.0)) TurnBuffer.Add(i,1);
      else if(STEP2[i]<STEP2[i-1])
         if(x1==NULL || (x1!=NULL && v1==1.0)) TurnBuffer.Add(i,-1);

      if(STEP2[i]<= STEP2[i-1] && STEP2[i-1]>STEP2[i-2])   StepBuffer.Add(i-1,1);
      if(STEP2[i]>= STEP2[i-1] && STEP2[i-1]<STEP2[i-2])   StepBuffer.Add(i-1,-1);

      if(StepBuffer.GetIndex(1)==NULL || TurnBuffer.GetIndex(0)==NULL)continue;
      //+------------------------------------------------------------------+
      //| Beginning Signal                                                 |
      //+------------------------------------------------------------------+
      //---
      if(Stat.TurnPos()==i
         || (STEP2[i]!=STEP2[i-1] && STEP2[i-1]==STEP2[i-2] && STEP2[i-2]==STEP2[i-3]))
        {
         //---
         if(UpSignal.Sig()==0 && STEP2[i]>STEP2[i-1] && EMA[i]>EMA[i-1])
           {
            int ifrom=InpBackStep;
            if(Stat.TurnPos()<i) ifrom=fmax(i-InpBackStep,StepBuffer.GetIndex(0));
            int imin=ArrayMinimum(low,ifrom,i-(ifrom-1));
            UpSignal.Begin(imin, i, 1);
            UpSignal.UpdateMax(i,high[i]);
            UP1[imin]=low[imin];

           }
         if(DnSignal.Sig()==0 && STEP2[i]<STEP2[i-1] && EMA[i]<EMA[i-1])
           {
            int ifrom=InpBackStep;
            if(Stat.TurnPos()<i)ifrom=fmax(i-InpBackStep,StepBuffer.GetIndex(0));
            int imax=ArrayMaximum(high,ifrom,i-(ifrom-1));
            DnSignal.Begin(imax, i, -1);
            DnSignal.UpdateMin(i,low[i]);
            DN1[imax]=high[imax];

           }
        }

      //+------------------------------------------------------------------+
      //| Open Trade                                                       |
      //+------------------------------------------------------------------+
      //---
      if(UpSignal.State()==2 && OSC[i]>OSCSIG[i] && OSC[i-1]<OSCSIG[i-1] && high[i]-low[i]<ATR[i]*3)
        {
         if(PDI[i]>MDI[i])
           {

            if(UpSignal.EntryCount()<3)
              {
               UpSignal.Entry();
               BUY[i]=low[i];
               SL[i]=UpSignal.Get1stPos();
              }
            else
               UpSignal.Exit();

           }

        }
      //---
      if(DnSignal.State()==2 && OSC[i]<OSCSIG[i] && OSC[i-1]>OSCSIG[i-1] && high[i]-low[i]<ATR[i]*3)
        {
         if(MDI[i]>PDI[i])
           {
            if(DnSignal.EntryCount()<3)
              {
               DnSignal.Entry();
               SELL[i]=high[i];
               SL[i]=DnSignal.Get1stPos();
              }
            else
               DnSignal.Exit();
           }
        }

      //+------------------------------------------------------------------+
      //| Exit Signal                                                      |
      //+------------------------------------------------------------------+
      //---
      if(UpSignal.Sig()>0)
        {
         double a=low[UpSignal.Get1stPos()];
         double b=high[UpSignal.Get2ndPos()];

         //       if(EMA[i]<EMA[i-1])UpSignal.Exit();
         if(UpSignal.State()>=1 && a>close[i]) UpSignal.Exit();
         if(UpSignal.State()>=2 && b<close[i]) UpSignal.Exit();
        }
      //---
      if(DnSignal.Sig()<0)
        {
         double a=high[DnSignal.Get1stPos()];
         double b=low[DnSignal.Get2ndPos()];

         //       if(EMA[i]>EMA[i-1]) DnSignal.Exit();
         if(DnSignal.State()>=1 && a<close[i])   DnSignal.Exit();
         if(DnSignal.State()>=2 && b>close[i])   DnSignal.Exit();
        }
      //---

      //+------------------------------------------------------------------+
      //| Make Setup                                                       |
      //+------------------------------------------------------------------+
      //---
      if(UpSignal.Sig()>0 && UpSignal.State()<2)
        {
         UpSignal.UpdateMax(i,high[i]);
         if(UPPER[i]<UPPER[i-1])
           {
            int x=UpSignal.GetMaxPos();
            UpSignal.SetNextPos(x);
            UP2[x]=high[x];
           }
        }
      //---
      if(DnSignal.Sig()<0 && DnSignal.State()<2)
        {
         DnSignal.UpdateMin(i,low[i]);
         if(LOWER[i]>LOWER[i-1])
           {
            int x=DnSignal.GetMinPos();
            DnSignal.SetNextPos(x);
            DN2[x]=low[x];
           }
        }
     }

//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
