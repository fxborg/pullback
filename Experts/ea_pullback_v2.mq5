//+------------------------------------------------------------------+
//|                                             ea_accelma_v1_00.mq5 |
//| ea_accelma v1.00                          Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#include <ExpertAdvisor.mqh>

input string description1="1.-------------------------------";
input double Risk=0.1; // Risk
input int    SL        = 400; // Stop Loss distance
input int    TP        = 300; // Take Profit distance

input int    HourStart =   7; // Hour of trade start
input int    HourEnd   =  22; // Hour of trade end
input string desc1="1--------- PullBack  ------------";
input double Step1Size=0.35;  //1st Step Size
input double Step2Size=1.6;   //2nd Step Size
input int    EmaPeriod=24;  // EMA Period
input int    AdxPeriod=20;  //Adx Period

input string desc2="2.--------- Accel Trend -------------";
input ENUM_TIMEFRAMES MACD_TF=PERIOD_H1; // Ma TF
input double   AccelSpeed=0.44;    // Accel Speed  
input int      AccelSmooth=13;  //Accel Smoothing
input int      AccelPeriod=16;  // Accel Period
input int      OsMaSig=13;  //Trend Signal Period
//---
class CMyEA : public CExpertAdvisor
  {
protected:
   double            m_risk;          // size of risk
   int               m_sl;            // Stop Loss
   int               m_tp;            // Take Profit
   int               m_hourStart;     // Hour of trade start
   int               m_hourEnd;       // Hour of trade end
   int               m_pullback_handle;   // Pull back Handle

   double            m_pb_step1size;     // Ema2 Period
   double            m_pb_step2size;     // Gann Bars
   int               m_pb_ema_period;     // Ema Period
   int               m_pb_adx_period;     // Adx Period
   double            m_pb_adx_speed;     // Adx Speed

   ENUM_TIMEFRAMES   m_ma_tf;  // MA TF
   int               m_ma_handle;  // MA Handle
   double            m_ma_speed;  // MA Speed
   int               m_ma_smooth;  // MA Smooth
   int               m_ma_period;  // MA Period
   int               m_ma_sig;  // MA Signal 

public:
   void              CMyEA();
   void             ~CMyEA();
   virtual bool      Init(string smb,ENUM_TIMEFRAMES tf); // initialization
   virtual bool      Main();                              // main function
   virtual void      OpenPosition(long dir);              // open position on signal
   virtual void      ClosePosition(long dir);             // close position on signal
  };
//------------------------------------------------------------------	CMyEA
void CMyEA::CMyEA(void) { }
//------------------------------------------------------------------	~CMyEA
void CMyEA::~CMyEA(void)
  {
   IndicatorRelease(m_pullback_handle);
   IndicatorRelease(m_ma_handle);
  }
//------------------------------------------------------------------	Init
bool CMyEA::Init(string smb,ENUM_TIMEFRAMES tf)
  {
   if(!CExpertAdvisor::Init(0,smb,tf)) return(false);  // initialize parent class
                                                       // copy parameters
   if(Step1Size*2>Step2Size) return(false);


   m_risk=Risk;
   m_tp=TP;
   m_sl=SL;
   m_hourStart=HourStart;
   m_hourEnd=HourEnd;
//---
   m_pb_ema_period=EmaPeriod;
   m_pb_step1size=Step1Size;
   m_pb_step2size=Step2Size;
   m_pb_adx_period=AdxPeriod;

   m_ma_tf=MACD_TF;
   m_ma_speed=AccelSpeed;
   m_ma_smooth=AccelSmooth;
   m_ma_sig=OsMaSig;
   m_ma_period=AccelPeriod;


//---
   m_ma_handle=iCustom(NULL,m_ma_tf,"accel_trend",m_ma_speed,m_ma_period,m_ma_smooth,m_ma_sig);
   if(m_ma_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit

   m_pullback_handle=iCustom(m_smb,m_tf,"pullback_v2_2",
                             m_pb_step1size,m_pb_step2size,m_pb_ema_period,m_pb_adx_period);

   if(m_pullback_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit

   m_bInit=true; return(true);                         // "trade allowed"
  }
//------------------------------------------------------------------	Main
bool CMyEA::Main() // main function
  {
   if(!CExpertAdvisor::Main()) return(false); // call function of parent class

   static CIsNewBar NB;
   if(!NB.IsNewBar(m_smb,m_tf))return (true);

// check each direction
   MqlRates rt[2];
   if(CopyRates(m_smb,m_tf,1,2,rt)!=2)
     { Print("CopyRates ",m_smb," history is not loaded"); return(WRONG_VALUE); }

   double TREND[2];
   double SELL[2];
   double BUY[2];


   if(CopyBuffer(m_ma_handle,1,1,2,TREND)!=2)
     { Print("CopyBuffer macd - no data 0"); return(WRONG_VALUE); }


   if(CopyBuffer(m_pullback_handle,0,1,2,SELL)!=2)
     { Print("CopyBuffer pullback - no data 1"); return(WRONG_VALUE); }
   if(CopyBuffer(m_pullback_handle,1,1,2,BUY)!=2)
     { Print("CopyBuffer pullback - no data 2"); return(WRONG_VALUE); }

   if(TREND[1]==0)
     {
      ClosePosition(ORDER_TYPE_SELL);
      if(BUY[1]!=EMPTY_VALUE) OpenPosition(ORDER_TYPE_BUY);
     }
   if(TREND[1]==1)
     {
      ClosePosition(ORDER_TYPE_BUY);
      if(SELL[1]!=EMPTY_VALUE)OpenPosition(ORDER_TYPE_SELL);
     }
   return(true);
  }
//------------------------------------------------------------------	OpenPos
void CMyEA::OpenPosition(long dir)
  {
   if(PositionSelect(m_smb)) return;
   if(!CheckTime(StringToTime(IntegerToString(m_hourStart)+":00"),
      StringToTime(IntegerToString(m_hourEnd)+":00"))) return;

   double lot=CountLotByRisk(m_sl,m_risk,0);
   if(lot<=0) return;
   DealOpen(dir,lot,m_sl,m_tp);
  }
//------------------------------------------------------------------	ClosePos
void CMyEA::ClosePosition(long dir)
  {
   if(!PositionSelect(m_smb)) return;
   if(dir!=PositionGetInteger(POSITION_TYPE)) return;
   m_trade.PositionClose(m_smb,1);
  }

CMyEA ea; // class instance
//------------------------------------------------------------------	OnInit
int OnInit()
  {
   ea.Init(Symbol(),Period()); // initialize expert

                               // initialization example
// ea.Init(Symbol(), PERIOD_M5); // for fixed timeframe
// ea.Init("USDJPY", PERIOD_H2); // for fixed symbol and timeframe

   return(0);
  }
//------------------------------------------------------------------	OnDeinit
void OnDeinit(const int reason) { }
//------------------------------------------------------------------	OnTick
void OnTick()
  {
   ea.Main(); // process incoming tick
  }
//+------------------------------------------------------------------+
