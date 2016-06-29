//+------------------------------------------------------------------+
//|                                               CExpertAdvisor.mq5 |
//|              Copyright Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property library

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\DealInfo.mqh>
//+------------------------------------------------------------------+
//|  New bar appearing moment detection algorithm                    |
//+------------------------------------------------------------------+  
class CIsNewBar
  {
   //----
public:
   //---- new bar appearing moment detection function
   bool IsNewBar(string symbol,ENUM_TIMEFRAMES timeframe)
     {
      //---- getting the time of the current bar appearing
      datetime TNew=datetime(SeriesInfoInteger(symbol,timeframe,SERIES_LASTBAR_DATE));

      if(TNew!=m_TOld && TNew) // checking for a new bar
        {
         m_TOld=TNew;
         return(true); // a new bar has appeared!
        }
      //----
      return(false); // there are no new bars yet!
     };

   //---- class constructor    
                     CIsNewBar(){m_TOld=-1;};

protected: datetime m_TOld;
   //---- 
  };


//------------------------------------------------------------------ CExpertAdvisor
class CExpertAdvisor
  {
protected:
   bool              m_bInit;       // flag of correct initialization
   ulong             m_magic;       // magic number of expert
   string            m_smb;         // symbol, on which expert works
   ENUM_TIMEFRAMES   m_tf;          // working timeframe
   CSymbolInfo       m_smbinf;      // symbol parameters
   int               m_timer;       // time for timer

public:
   double            m_pnt;         // consider digit quotes for stops
   CTrade            m_trade;       // object to execute trade orders
   string            m_inf;         // comment string for information about expert's work

public:
   //--- Initialization
   void              CExpertAdvisor();                               // constructor
   void             ~CExpertAdvisor();                               // destructor
   virtual bool      Init(long magic,string smb,ENUM_TIMEFRAMES tf); // initialization

   //--- Trade modules
   virtual bool      Main();                            // main module controlling trade process
   virtual void      OpenPosition(long dir) {};         // module of opening position
   virtual void      CheckPosition(long dir) {};        // check position and open additional ones
   virtual void      ClosePosition(long dir) {};        // close position
   virtual void      BEPosition(long dir,int BE);       // moving Stop Loss to break-even
   virtual void      TrailingPosition(long dir,int TS); // trailing position of Stop Loss
   virtual void      CheckTrailingStopLong(const double dStop,const double dLow, const int trail_minimum,const int trail_maximum);
   virtual void      CheckTrailingStopShort(const double dStop,const double dHigh, const int trail_minimum,const int trail_maximum);

   virtual void      OpenPending(long dir) {};          // module of opening pending orders
   virtual void      CheckPending(long dir) {};         // work with current orders and open additional ones
   virtual void      TrailingPending(long dir) {};      // move pending orders
   virtual void      DeletePending(long dir) {};        // delete pending orders

   //--- Functions of getting signals/events
   bool              CheckTime(datetime start,datetime end);   // check allowed trade time
   virtual long      CheckSignal(bool bEntry) { return(-1); }; // check signal 
   virtual bool      CheckFilter(long dir) { return(false); }; // check filter for direction
   bool SetTimer(int sec)                                      // set timer
     { m_timer=sec; return(EventSetTimer(m_timer)); }
   int GetTimer() { return(m_timer); }                         // returns time of set timer
   void KillTimer() { EventKillTimer(); }                      // deletes timer event processing

   //--- Service functions
   double            CountLotByRisk(int dist,double risk,double lot); // calculate lot by size of risk
   ulong             DealOpen(long dir,double lot,int SL,int TP);     // execute deal with specified parameters
   ulong             GetDealByOrder(ulong order);                     // get deal ticket by order ticket
   double            CountProfitByDeal(ulong ticket);                 // calculate profit by deal ticket

   //--- Type conversion macro
   long              BaseType(long dir);             // returns the base type of order for specified direction
   long              ReversType(long dir);           // returns the reverse type of order for specified direction
   long              StopType(long dir);             // returns the stop-order type for specified direction
   long              LimitType(long dir);            // returns the limit-order type for specified direction

   //--- Normalization macro
   double            NormalPrice(double d);          // normalization of price
   double            NormalDbl(double d, int n=-1);  // normalization of price per tick
   double            BasePrice(long dir);            // returns Bid/Ask price for specified direction
   double            ReversPrice(long dir);          // returns Bid/Ask price for reverse direction
   double            NormalOpen(long dir,double op,double stop); // normalization of pending order opening price
   double            NormalTP(long dir, double op, double pr, int TP, double stop); // normalization of Take Profit considering stop level and spread
   double            NormalSL(long dir, double op, double pr, int SL, double stop); // normalization of Stop Loss considering stop level and spread
   double            NormalLot(double lot);          // normalization of lot considering symbol properties

   //--- Info macro
   void              AddInfo(string st,bool ini=false);            // add string to m_inf parameter
   void              ErrorHandle(int err,ulong ticket,string str); // display error and description
  };
//------------------------------------------------------------------ CExpertAdvisor
void CExpertAdvisor::CExpertAdvisor()
  {
   m_bInit=false;
  }
//------------------------------------------------------------------ ~CExpertAdvisor
void CExpertAdvisor::~CExpertAdvisor()
  {
  }
//------------------------------------------------------------------ Init
bool CExpertAdvisor::Init(long magic,string smb,ENUM_TIMEFRAMES tf)
  {
   m_magic=magic; m_smb=smb; m_tf=tf;     // set initializing parameters
   m_smbinf.Name(m_smb);                  // initialize symbol
   m_pnt=m_smbinf.Point();                // point
   m_trade.SetExpertMagicNumber(m_magic); // set magic number for expert

   m_bInit=true; return(true);            // trade allowed
  }
//--- Trade modules
//------------------------------------------------------------------ Main
bool CExpertAdvisor::Main() // Main module
  {
   if(!m_bInit) return(false);
   if(!MQL5InfoInteger(MQL5_TRADE_ALLOWED) || !TerminalInfoInteger(TERMINAL_CONNECTED))
      return(false);                            // if trade is not possible, then exit
   m_inf="";                                    // reset information string

   m_smbinf.Refresh(); m_smbinf.RefreshRates(); // update symbol parameters
   return(true);
  }
//------------------------------------------------------------------ BEPositin
void CExpertAdvisor::BEPosition(long dir,int BE)
  {
   double sl,apr,csl,cop,ctp;
   if(!PositionSelect(m_smb)) return;                       // if there is no positions or error, then exit
   m_smbinf.Refresh(); m_smbinf.RefreshRates();             // update symbol parameters
   double StopLvl=m_smbinf.StopsLevel()*m_smbinf.Point();   // Stop Level
   double FreezLvl=m_smbinf.FreezeLevel()*m_smbinf.Point(); // Freeze level
   apr=ReversPrice(dir);
   cop=NormalDbl(PositionGetDouble(POSITION_PRICE_OPEN));   // price of position opening
   csl=NormalDbl(PositionGetDouble(POSITION_SL));           // Stop Loss
   ctp=NormalDbl(PositionGetDouble(POSITION_TP));           // Take Profit
   if(MathAbs(ctp-apr)<=FreezLvl || MathAbs(csl-apr)<=FreezLvl) return;          // check freeze level
   sl=NormalPrice(dir==ORDER_TYPE_BUY ? cop+BE*m_pnt:cop-BE*m_pnt);              // calculate new value of Stop Loss
   if((dir==ORDER_TYPE_BUY && sl<apr+StopLvl && (sl>csl || csl==NormalPrice(0))) // check fulfillment of condition
      || (dir==ORDER_TYPE_SELL && sl>apr-StopLvl && (sl<csl || csl==NormalPrice(0))))
     {
      if(!m_trade.PositionModify(m_smb,sl,ctp))             // modify Stop Loss 
         ErrorHandle(GetLastError(),PositionGetInteger(POSITION_IDENTIFIER),"-BEPosition ");
     }
  }
//------------------------------------------------------------------ TralPos
void CExpertAdvisor::TrailingPosition(long dir,int TS)
  {
   double sl,apr,csl,cop,ctp;
   if(TS<=0) return;
   if(!PositionSelect(m_smb)) return;                       // if there is no positions or error, then exit
   m_smbinf.Refresh(); m_smbinf.RefreshRates();             // update symbol parameters
   double StopLvl=m_smbinf.StopsLevel()*m_smbinf.Point();   // Stop Level
   double FreezLvl=m_smbinf.FreezeLevel()*m_smbinf.Point(); // Freeze level
   apr=ReversPrice(dir);
   cop=NormalDbl(PositionGetDouble(POSITION_PRICE_OPEN));   // price of position opening
   csl=NormalDbl(PositionGetDouble(POSITION_SL));           // Stop Loss
   ctp=NormalDbl(PositionGetDouble(POSITION_TP));           // Take Profit
   if(MathAbs(ctp-apr)<=FreezLvl || MathAbs(csl-apr)<=FreezLvl) return;  // check freeze level
   sl=NormalSL(dir,apr,apr,TS,StopLvl);                     // calculate Stop Loss
   if((dir==ORDER_TYPE_BUY && apr-cop>TS*m_pnt && (sl>cop && (sl>csl || csl==NormalPrice(0)))) // check condition
      || (dir==ORDER_TYPE_SELL && cop-apr>TS*m_pnt && (sl<cop && (sl<csl || csl==NormalPrice(0)))))
     {
      if(!m_trade.PositionModify(m_smb,sl,ctp))             // move Stop Loss to new place
         ErrorHandle(GetLastError(),PositionGetInteger(POSITION_IDENTIFIER),"-TrailingPosition ");
     }
  }
//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for long position.          |
//+------------------------------------------------------------------+
void CExpertAdvisor::CheckTrailingStopLong(const double dStop ,const double dLow, const int trail_minimum,const int trail_maximum)
  {


  //--- check freeze level
   if(!PositionSelect(m_smb)) return;                       // if there is no positions or error, then exit
   m_smbinf.Refresh(); m_smbinf.RefreshRates();             // update symbol parameters

   double FreezLvl= m_smbinf.FreezeLevel()*m_smbinf.Point(); // Freeze level
   double price =m_smbinf.Bid();   
   double cp_open=NormalDbl(PositionGetDouble(POSITION_PRICE_OPEN));   // price of position opening
   double cp_tp=NormalDbl(PositionGetDouble(POSITION_TP));            //take profit
   double cp_sl=NormalDbl(PositionGetDouble(POSITION_SL));           // Stop Loss
   if(MathAbs(cp_tp-price)<=FreezLvl || MathAbs(cp_sl-price)<=FreezLvl) return;  // check freeze level
//---
   double min_stop=trail_minimum*( m_smbinf.Point());
   double max_stop=trail_maximum*(m_smbinf.Point());
   double adj=2*(m_smbinf.Point());
   double sp = m_smbinf.Spread()* m_smbinf.Point();
   
   double level =NormalizeDouble(price-m_smbinf.StopsLevel()*m_smbinf.Point(),m_smbinf.Digits());
   double new_sl=(dStop!=0) ? NormalizeDouble(dStop-(adj+sp),m_smbinf.Digits()) : 0;
   double pos_sl=cp_sl;
   double base  =(pos_sl==0.0) ? cp_open : pos_sl;
//---
   double delta=max_stop-sp;
   if(new_sl!=0 && new_sl>level)new_sl=0;
   if(new_sl!=0 && dLow - min_stop < new_sl) new_sl=0;
   if(new_sl!=0 && (price-delta)>new_sl)new_sl=0;

   double sl=EMPTY_VALUE;
   if(new_sl!=0 && new_sl>base && new_sl<level ) sl = new_sl;
   if(new_sl==0 && (price-base)>delta) sl=price-delta;
//---
   if(sl!=EMPTY_VALUE)
      if(!m_trade.PositionModify(m_smb,sl,cp_tp))     // move Stop Loss to new place
         ErrorHandle(GetLastError(),PositionGetInteger(POSITION_IDENTIFIER),"-TrailingPosition ");

  }
//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for short position.         |
//+------------------------------------------------------------------+
void CExpertAdvisor::CheckTrailingStopShort(const double dStop ,const double dHigh, const int trail_minimum,const int trail_maximum)
  {
  //--- check freeze level
   if(!PositionSelect(m_smb)) return;                       // if there is no positions or error, then exit
   m_smbinf.Refresh(); m_smbinf.RefreshRates();             // update symbol parameters

   double FreezLvl= m_smbinf.FreezeLevel()*m_smbinf.Point(); // Freeze level
   double price =m_smbinf.Ask();   
   double cp_open=NormalDbl(PositionGetDouble(POSITION_PRICE_OPEN));   // price of position opening
   double cp_tp=NormalDbl(PositionGetDouble(POSITION_TP));            //take profit
   double cp_sl=NormalDbl(PositionGetDouble(POSITION_SL));           // Stop Loss
   if(MathAbs(cp_tp-price)<=FreezLvl || MathAbs(cp_sl-price)<=FreezLvl) return;  // check freeze level
//---
   double min_stop=trail_minimum*( m_smbinf.Point());
   double max_stop=trail_maximum*(m_smbinf.Point());
   double adj=2*(m_smbinf.Point());
   double sp = m_smbinf.Spread()* m_smbinf.Point();

   double level =NormalizeDouble(price + m_smbinf.StopsLevel() * m_smbinf.Point(), m_smbinf.Digits());
   double new_sl=(dStop!=0) ? NormalizeDouble(dStop+(adj+sp),m_smbinf.Digits()) : 0;
   double pos_sl=cp_sl;
   double base  =(pos_sl==0.0) ? cp_open : pos_sl;

//---
   double delta=max_stop+sp;

   if(new_sl!=0 && new_sl<level)new_sl=0;
   if(new_sl!=0 && dHigh +min_stop>new_sl) new_sl=0;
   if(new_sl!=0 && (price+delta)<new_sl)new_sl=0;
   
//---
   double sl=EMPTY_VALUE;
   if(new_sl!=0 && new_sl<base && new_sl>level) sl=new_sl;
   if(new_sl==0 && (base-price)>delta) sl=price+delta;
//---
   if(sl!=EMPTY_VALUE)
      if(!m_trade.PositionModify(m_smb,sl,cp_tp))     // move Stop Loss to new place
         ErrorHandle(GetLastError(),PositionGetInteger(POSITION_IDENTIFIER),"-TrailingPosition ");

  }
//+------------------------------------------------------------------+



//--- Functions of getting signals/events
//---------------------------------------------------------------   CheckTime
bool CExpertAdvisor::CheckTime(datetime start,datetime end)
  {
   datetime dt=TimeCurrent();                          // current time
   if(start<end) if(dt>=start && dt<end) return(true); // check if we are in the range
   if(start>=end) if(dt>=start|| dt<end) return(true);
   return(false);
  }
//--- Service functions
//---------------------------------------------------------------   CountLotByRisk
double CExpertAdvisor::CountLotByRisk(int dist,double risk,double lot) // calculate lot by size of risk
  {
   if(dist==0 || risk==0) return(lot);
   m_smbinf.Refresh();
   return(NormalLot(AccountInfoDouble(ACCOUNT_BALANCE)*risk/(dist*10*m_smbinf.TickValue())));
  }
//------------------------------------------------------------------	DealOpen
ulong CExpertAdvisor::DealOpen(long dir,double lot,const int _sl,const int _tp)
  {
   double op,sl,tp,apr,StopLvl;
// determine price parameters
   m_smbinf.RefreshRates(); m_smbinf.Refresh();
   StopLvl=m_smbinf.StopsLevel()*m_smbinf.Point(); // remember stop level
   apr=ReversPrice(dir); op=BasePrice(dir);        // open price
   sl=NormalSL(dir, op, apr, _sl, StopLvl);         // Stop Loss
   tp=NormalTP(dir, op, apr, _tp, StopLvl);         // Take Profit

                                                   // open position
   m_trade.PositionOpen(m_smb,(ENUM_ORDER_TYPE)dir,lot,op,sl,tp);
   ulong order=m_trade.ResultOrder(); if(order<=0) return(0); // order ticket
   return(GetDealByOrder(order));                  // return deal ticket
  }
//---------------------------------------------------------------   GetDealByOrder
ulong CExpertAdvisor::GetDealByOrder(ulong order) // get deal ticket by order ticket
  {
   PositionSelect(m_smb);
   HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER));
   uint total=HistoryDealsTotal();
   for(uint i=0; i<total; i++)
     {
      ulong deal=HistoryDealGetTicket(i);
      if(order==HistoryDealGetInteger(deal,DEAL_ORDER))
         return(deal);                            // remember deal ticket 
     }
   return(0);
  }
//---------------------------------------------------------------   CountProfit
double CExpertAdvisor::CountProfitByDeal(ulong ticket)// position profit by deal ticket
  {
   CDealInfo deal; deal.Ticket(ticket);               // deal ticket
   HistorySelect(deal.Time(),TimeCurrent());          // select all deals after this
   uint total=HistoryDealsTotal();
   long pos_id=deal.PositionId();                     // get position id
   double prof=0;
   for(uint i=0; i<total; i++)                        // find all deals with this id
     {
      ticket=HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket,DEAL_POSITION_ID)!=pos_id) continue;
      prof+=HistoryDealGetDouble(ticket,DEAL_PROFIT); // summarize profit
     }
   return(prof);                                      // return profit
  }
//--- Type conversion macro
//---------------------------------------------------------------   DIR
long CExpertAdvisor::BaseType(long dir)
  {
   if(dir==ORDER_TYPE_BUY || dir==ORDER_TYPE_BUY_STOP || dir==ORDER_TYPE_BUY_LIMIT) return(ORDER_TYPE_BUY);
   if(dir==ORDER_TYPE_SELL || dir==ORDER_TYPE_SELL_STOP || dir==ORDER_TYPE_SELL_LIMIT) return(ORDER_TYPE_SELL);
   return(-1);
  }
//------------------------------------------------------------------	ADIR
long CExpertAdvisor::ReversType(long dir)
  {
   if(dir==ORDER_TYPE_BUY || dir==ORDER_TYPE_BUY_STOP || dir==ORDER_TYPE_BUY_LIMIT) return(ORDER_TYPE_SELL);
   if(dir==ORDER_TYPE_SELL || dir==ORDER_TYPE_SELL_STOP || dir==ORDER_TYPE_SELL_LIMIT) return(ORDER_TYPE_BUY);
   return(-1);
  }
//---------------------------------------------------------------   SDIR
long CExpertAdvisor::StopType(long dir)
  {
   if(dir==ORDER_TYPE_BUY || dir==ORDER_TYPE_BUY_STOP || dir==ORDER_TYPE_BUY_LIMIT) return(ORDER_TYPE_BUY_STOP);
   if(dir==ORDER_TYPE_SELL || dir==ORDER_TYPE_SELL_STOP || dir==ORDER_TYPE_SELL_LIMIT) return(ORDER_TYPE_SELL_STOP);
   return(-1);
  }
//---------------------------------------------------------------   LDIR
long CExpertAdvisor::LimitType(long dir)
  {
   if(dir==ORDER_TYPE_BUY || dir==ORDER_TYPE_BUY_STOP || dir==ORDER_TYPE_BUY_LIMIT) return(ORDER_TYPE_BUY_LIMIT);
   if(dir==ORDER_TYPE_SELL || dir==ORDER_TYPE_SELL_STOP || dir==ORDER_TYPE_SELL_LIMIT) return(ORDER_TYPE_SELL_LIMIT);
   return(-1);
  }

//--- Normalization macro
//---------------------------------------------------------------   ND
double CExpertAdvisor::NormalDbl(double d,int n=-1) {  if(n<0) return(::NormalizeDouble(d,m_smbinf.Digits())); return(NormalizeDouble(d,n)); }
//---------------------------------------------------------------   NP
double CExpertAdvisor::NormalPrice(double d) { return(NormalDbl(MathRound(d/m_smbinf.TickSize())*m_smbinf.TickSize())); }
//---------------------------------------------------------------   NPR
double CExpertAdvisor::BasePrice(long dir)
  {
   if(dir==(long)ORDER_TYPE_BUY) return(m_smbinf.Ask());
   if(dir==(long)ORDER_TYPE_SELL) return(m_smbinf.Bid());
   return(WRONG_VALUE);
  }
//---------------------------------------------------------------   APR
double CExpertAdvisor::ReversPrice(long dir)
  {
   if(dir==(long)ORDER_TYPE_BUY) return(m_smbinf.Bid());
   if(dir==(long)ORDER_TYPE_SELL) return(m_smbinf.Ask());
   return(WRONG_VALUE);
  }
//---------------------------------------------------------------   NOP
double CExpertAdvisor::NormalOpen(long dir,double op,double stop)
  {
   if(dir==ORDER_TYPE_BUY_LIMIT) return(NormalPrice(MathMin(op,m_smbinf.Ask()-stop)));
   if(dir==ORDER_TYPE_BUY_STOP) return(NormalPrice(MathMax(op,m_smbinf.Ask()+stop)));
   if(dir==ORDER_TYPE_SELL_LIMIT) return(NormalPrice(MathMax(op,m_smbinf.Bid()+stop)));
   if(dir==ORDER_TYPE_SELL_STOP) return(NormalPrice(MathMin(op,m_smbinf.Bid()-stop)));
   return(WRONG_VALUE);
  }
//---------------------------------------------------------------   NTP
double CExpertAdvisor::NormalTP(long dir,double op,double pr,int _tp,double stop)
  {
   if(_tp==0) return(NormalPrice(0));
   if(dir==ORDER_TYPE_BUY || dir==ORDER_TYPE_BUY_STOP || dir==ORDER_TYPE_BUY_LIMIT) return(NormalPrice(MathMax(op+_tp*m_pnt,pr+stop)));
   if(dir==ORDER_TYPE_SELL || dir==ORDER_TYPE_SELL_STOP || dir==ORDER_TYPE_SELL_LIMIT) return(NormalPrice(MathMin(op-_tp*m_pnt,pr-stop)));
   return(WRONG_VALUE);
  }
//---------------------------------------------------------------   NSL
double CExpertAdvisor::NormalSL(long dir,double op,double pr,int _sl,double stop)
  {
   if(_sl==0) return(NormalPrice(0));
   if(dir==ORDER_TYPE_BUY || dir==ORDER_TYPE_BUY_STOP || dir==ORDER_TYPE_BUY_LIMIT) return(NormalPrice(MathMin(op-_sl*m_pnt,pr-stop)));
   if(dir==ORDER_TYPE_SELL || dir==ORDER_TYPE_SELL_STOP || dir==ORDER_TYPE_SELL_LIMIT) return(NormalPrice(MathMax(op+_sl*m_pnt,pr+stop)));
   return(WRONG_VALUE);
  }
//---------------------------------------------------------------   NL
double CExpertAdvisor::NormalLot(double lot)
  {
   int k=0;
   double ll=lot,ls=m_smbinf.LotsStep();
   if(ls<=0.001) k=3; else if(ls<=0.01) k=2; else if(ls<=0.1) k=1;
   ll=NormalDbl(MathMin(m_smbinf.LotsMax(),MathMax(m_smbinf.LotsMin(),ll)),k);
   return(ll);
  }
//--- Information functions
//---------------------------------------------------------------   INF
void CExpertAdvisor::AddInfo(string st,bool ini=false)
  {
   string zn="\n      ",zzn="\n               ";
   if(ini) m_inf=m_inf+zn+st; else m_inf=m_inf+zzn+st;
  }
//---------------------------------------------------------------   ErrorHandle
void CExpertAdvisor::ErrorHandle(int err,ulong ticket,string str)
  {
   Print("-Err(",err,") ",m_magic," #",ticket," | "+str);
   switch(err)
     {
      case TRADE_RETCODE_REJECT:
      case TRADE_RETCODE_TOO_MANY_REQUESTS:
         Sleep(2000);        // wait 2 seconds
         break;

      case TRADE_RETCODE_PRICE_OFF:
      case TRADE_RETCODE_PRICE_CHANGED:
      case TRADE_RETCODE_REQUOTE:
         m_smbinf.Refresh(); // refresh symbol info
         m_smbinf.RefreshRates();
         break;
     }
  }
//+------------------------------------------------------------------+
