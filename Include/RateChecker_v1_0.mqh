//+------------------------------------------------------------------+
//|                                                 CRateChecker.mqh |
//|CRateChecker                               Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CRateBuffer
  {
protected:
   int               m_data_size;
   int               m_size;
   int               m_index[];
   double            m_checks[];
   MqlRates          m_data[];
   int               m_last_pos;
   static const MqlRates m_empty_rates;

public:
   void              CRateBuffer(){};                   // constructor
   void             ~CRateBuffer(){};                   // destructor
   //---  
   static MqlRates empty_rates(){return m_empty_rates;};
   //---  
   void              init(const int sz)
     {
      m_size=sz;
      m_data_size=0;
      m_last_pos=0;
      ArrayResize(m_index,m_size);
      ArrayResize(m_data,m_size);
      ArrayResize(m_checks,m_size);
      ArrayInitialize(m_index,NULL);
      ArrayInitialize(m_checks,NULL);
      for(int i=0;i<m_size;i++)m_data[i]=m_empty_rates;
     }

   //---  
   int               size() { return m_size;}
   //---  
   int               data_size() { return m_data_size;}
   //---  
   MqlRates          get_value(const int pos) const
     {
      if(pos < 0 || pos >= m_size) return (m_empty_rates);
      return(m_data [((m_size + ((m_last_pos-pos)-1)) % m_size)]);

     }
   //---  
   int               get_index(const int pos) const
     {
      if(pos < 0 || pos >= m_size) return (NULL);
      return ( m_index [((m_size + ((m_last_pos-pos)-1)) % m_size)]);
     }
   //---  
   double            get_cd(const int pos) const
     {
      if(pos < 0 || pos >= m_size) return (NULL);
      return ( m_checks [((m_size + ((m_last_pos-pos)-1)) % m_size)]);
     }
   //---  
   void              add(const int index,const MqlRates &value)
     {
      int pos=(m_size+(m_last_pos-1))%m_size;

      if(m_index[pos]==index)
        {
         m_data[pos]=value;
         m_checks[pos]=check_digit(value);
        }
      else
        {
         if(m_size>m_data_size)m_data_size++;
         m_data[m_last_pos]=value;
         m_checks[m_last_pos]=check_digit(value);
         m_index[m_last_pos]=index;
         m_last_pos=(m_last_pos+1)%m_size;
        }
     }
   //---  
   void              update(const int pos,const int index,const MqlRates &value)
     {
      if(pos < 0 || pos >= m_size) return;
      int p=((m_size+((m_last_pos-pos)-1))%m_size);
      m_data[p]=value;
      m_index[p]=index;
     }
   //---  
   double            check_digit(const MqlRates &rt)
     {
      return rt.open+rt.time;
     }
   //---  
  };
//---  
const MqlRates CRateBuffer::m_empty_rates={NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL};
//---  
//+------------------------------------------------------------------+
//| CRateChecker                                                     |
//+------------------------------------------------------------------+
class CRateChecker
  {
protected:
   ENUM_TIMEFRAMES   m_tf;
   int               m_buffer_size;
   int               m_minbars;
   bool              m_is_newbar;
   int               m_last_bar;
   double            m_last_time;
   CRateBuffer       m_rates;

public :
   void              CRateChecker(){};                   // constructor
   void             ~CRateChecker(){};                   // destructor

   void              init(const int sz,const int minbars)
     {
      m_buffer_size=sz;
      m_minbars=minbars;
      m_is_newbar=false;
      m_tf=PERIOD_CURRENT;
      m_rates.init(m_buffer_size);
      m_last_time=NULL;
      m_last_bar=NULL;
     }
   bool              is_newbar(){return m_is_newbar;}
   MqlRates          get_rates(const int i)
     {
      int backs=m_last_bar-i;
      return m_rates.get_value(backs);
     }
   MqlRates          to_rates(const double o,const double h,
                              const double l,const double c,
                              const long v,const datetime t)
     {
      MqlRates rt;
      rt.open=o;rt.high=h;rt.low=l;rt.close=c;rt.tick_volume=v;rt.time=t;
      return rt;
     }

//+------------------------------------------------------------------+
//|                                                                  | 
//+------------------------------------------------------------------+
   bool              update(const int i,
                            const double o,const double h,
                            const double l,const double c,
                            const long v,const datetime t,
                            int &pos)
     {
      m_is_newbar=false;
      int chk=checkbars(t,i);
      MqlRates rt=to_rates(o,h,l,c,v,normaltime(t));
      if(chk==3 ) // skipping bar
        {
            pos=m_last_bar ;
            return false;
        }
      else if(chk==2 ) // newbar
        {
         m_rates.add(i,rt);
         m_last_bar=i;
         m_is_newbar=true;
         return true;
        }
      else if(chk==1)// last bar
        {
         m_rates.update(0,i,rt);
         m_last_bar=i;
         return true;
        }
      else  // out bar
        {
         return true;
        }
     }

//+------------------------------------------------------------------+
//|                                                                  | 
//+------------------------------------------------------------------+
   int              checkbars(const datetime t,const int i)
     {
      datetime tt=normaltime(t);
      if(m_rates.data_size()==0)
        {

         // newbar
         return 2;
        }

      int backs=m_last_bar-i;

      MqlRates chk=m_rates.get_value(backs);

      if(chk.time==NULL && backs<0)
        {
         // newbar
         return ((backs == -1)? 2: 3);
        }
      if(chk.time!=NULL && backs==0)
        {
         // last bar
         return 1;
        }
      if(chk.time!=NULL && tt==chk.time)
        {
         // past bar
         return 0;
        }
      // error
      return -1;

     }

   //--- normalized by period 
   datetime           normaltime(datetime t)
     {
      int sec=PeriodSeconds(m_tf);
      return ((t/sec) * sec);
     }

  };
//+------------------------------------------------------------------+
