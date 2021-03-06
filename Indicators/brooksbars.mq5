//+------------------------------------------------------------------+
//|                                                   brooksbars.mq5 |
//| brooksbars indicator                                             |
//|                                           http://ninjatrader.com |
//+------------------------------------------------------------------+
#property copyright "NinjaTrader_Paul"
#property link      "http://ninjatrader.com/support/forum/local_links.php?action=sendtofriend&catid=7&linkid=688"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#include <RateChecker_v1_0.mqh>

#property indicator_buffers 2
#property indicator_plots 2


#property indicator_chart_window
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrDeepPink
#property indicator_width1 2

#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrAqua
#property indicator_width2 2
//+------------------------------------------------------------------+
//| CStatus                                                            |
//+------------------------------------------------------------------+
class CStatus
  {
protected:
   int               m_h;
   int               m_l;

public:
   void              CStatus(){};                   // constructor
   void             ~CStatus(){};                   // destructor
   void              Init()
     {
      m_h=0;
      m_l=0;
     }
   int               H() { return m_h;}
   int               L() { return m_l;}
   void              H(int h){m_h=h;}
   void              L(int l){m_l=l;}
   //---
  };

//+------------------------------------------------------------------+

//--- input parameters

double H[];
double L[];
CStatus stat;
CRateChecker Checker;
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
   SetIndexBuffer(0,H,INDICATOR_DATA);
   SetIndexBuffer(1,L,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_ARROW,72);
   PlotIndexSetInteger(1,PLOT_ARROW,71);

   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,-15);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,15);
   Checker.init(300,min_rates_total);
   stat.Init();
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

   int bar=first;
   while(bar<rates_total && !IsStopped())
     {

      int pos;
      if(!Checker.update(bar,open[bar],high[bar],low[bar],close[bar],tick_volume[bar],time[bar],pos))
        {
         bar=pos;
         continue;
        }
      H[bar]=EMPTY_VALUE;
      L[bar]=EMPTY_VALUE;


      int i=bar-1;
      if(!Checker.is_newbar())
        {
         bar++;
         continue;
        }
      //===============================  OUTSIDEBAR
      if(high[i]>high[i-1] && low[i]<low[i-1]) // outside bar
        {
         stat.H(1);
         stat.L(1);
        }
      //======================= "H" BARS ===========================================
      else if(high[i]>high[i-1] && stat.L()==1) // H bar
        {
         H[i]=high[i];
         stat.H(1);
         stat.L(0);
        }
      //================== "L" BARS   ===============================================
      else if(low[i]<low[i-1] && stat.H()==1) // L bar
        {
         L[i]=low[i];
         stat.H(0);
         stat.L(1);
        }

      //---
      bar++;
      //---
     }
//----

   return(rates_total);
  }
//+------------------------------------------------------------------+
