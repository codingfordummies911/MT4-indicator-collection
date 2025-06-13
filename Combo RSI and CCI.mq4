//+------------------------------------------------------------------+
//|                                               ThierryRSI_CCI.mq4 |
//+------------------------------------------------------------------+
#property copyright "copyright jacob uzon"
#property link      "www.ctlforum.com"
//Modified TrendMagic Indicator

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Yellow

//
//
//
//
//

extern string  timeFrame = "Current time frame";
extern int CCIPeriod = 14;
extern int RSIPeriod = 8;

//
//
//
//
//

double   Trend[];
double   TrendDoA[];
double   TrendDoB[];
double   Direction[];
int      TimeFrame;
string   IndicatorFileName;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int init()
{
   IndicatorBuffers(4);
      SetIndexBuffer(0, Trend);
      SetIndexBuffer(1, TrendDoA);
      SetIndexBuffer(2, TrendDoB);
      SetIndexBuffer(3, Direction);
         SetIndexLabel(0,"SuperTrend");
         SetIndexLabel(1,"SuperTrend");
         SetIndexLabel(2,"SuperTrend");
        
   TimeFrame = stringToTimeFrame(timeFrame);
   IndicatorFileName = WindowExpertName();
   IndicatorShortName("ThierryTrend "+TimeFrameToString(TimeFrame));    
}
int deinit()
{
   return(0);
}




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int start()
{
   int      counted_bars = IndicatorCounted();
   int      limit,i;


   if(counted_bars < 0) return(-1);
   if(counted_bars>0) counted_bars--;
      limit = MathMax(Bars-counted_bars,Bars-1);

      if (Direction[limit] == -1) CleanPoint(limit,TrendDoA,TrendDoB);

   //
   //
   //
   //
   //

      if (TimeFrame != Period())
      {
         limit = MathMax(limit,TimeFrame/Period());
         
            //
            //
            //
            //
            //
         
            for(i=limit; i>=0; i--)
            {
               int y = iBarShift(NULL,TimeFrame,Time[i]);
               double cciTrend = iCCI(NULL, 0, CCIPeriod, PRICE_TYPICAL, y);
               double rsiTrend = iRSI(NULL, 0, RSIPeriod, PRICE_TYPICAL, y);
                  
               //
               //
               //
               //
               //
                  
               TrendDoA[i]  = EMPTY_VALUE;
               TrendDoB[i]  = EMPTY_VALUE;
               Trend[i]     = iCustom(NULL,TimeFrame,IndicatorFileName,0,y);
               Direction[i] = Direction[i+1];
                  if (cciTrend>0 && rsiTrend > 50) Direction[i] =  1;
                  if (cciTrend<0 && rsiTrend < 50) Direction[i] = -1;
                  if (Direction[i]==-1) PlotPoint(i,TrendDoA,TrendDoB,Trend);
            }
         return(0);         
      }

   //
   //
   //
   //
   //
   //
   //
   //
   //
   //
      
   for(i = limit; i >= 0; i--)
   {
         cciTrend = iCCI(NULL, 0, CCIPeriod, PRICE_TYPICAL, i);
         rsiTrend = iRSI(NULL, 0, RSIPeriod, PRICE_TYPICAL, i);
         
         //
         //
         //
         //
         //
         
         TrendDoA[i]  = EMPTY_VALUE;
         TrendDoB[i]  = EMPTY_VALUE;
         Trend[i]     = Trend[i+1];
         Direction[i] = Direction[i+1];
            if (cciTrend > 0 && rsiTrend > 50) { Trend[i] = MathMax(Low[i]  - iATR(NULL, 0, 5, i),Trend[i+1]); Direction[i] =  1; }
            if (cciTrend < 0 && rsiTrend < 50) { Trend[i] = MathMin(High[i] + iATR(NULL, 0, 5, i),Trend[i+1]); Direction[i] = -1; }
            if (Direction[i]==-1) PlotPoint(i,TrendDoA,TrendDoB,Trend);
   }
   return(0);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

void CleanPoint(int i,double& first[],double& second[])
{
   if ((second[i]  != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
        second[i+1] = EMPTY_VALUE;
   else
      if ((first[i] != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
          first[i+1] = EMPTY_VALUE;
}

//
//
//
//
//

void PlotPoint(int i,double& first[],double& second[],double& from[])
{
   if (first[i+1] == EMPTY_VALUE)
      {
      if (first[i+2] == EMPTY_VALUE) {
          first[i]    = from[i];
          first[i+1]  = from[i+1];
          second[i]   = EMPTY_VALUE;
         }
      else {
          second[i]   = from[i];
          second[i+1] = from[i+1];
          first[i]    = EMPTY_VALUE;
         }
      }
   else
      {
         first[i]   = from[i];
         second[i]  = EMPTY_VALUE;
      }
}

//+------------------------------------------------------------------+
//|
//+------------------------------------------------------------------+

int stringToTimeFrame(string tfs)
{
   int tf=0;
       tfs = StringUpperCase(tfs);
         if (tfs=="M1" || tfs=="1")     tf=PERIOD_M1;
         if (tfs=="M5" || tfs=="5")     tf=PERIOD_M5;
         if (tfs=="M15"|| tfs=="15")    tf=PERIOD_M15;
         if (tfs=="M30"|| tfs=="30")    tf=PERIOD_M30;
         if (tfs=="H1" || tfs=="60")    tf=PERIOD_H1;
         if (tfs=="H4" || tfs=="240")   tf=PERIOD_H4;
         if (tfs=="D1" || tfs=="1440")  tf=PERIOD_D1;
         if (tfs=="W1" || tfs=="10080") tf=PERIOD_W1;
         if (tfs=="MN" || tfs=="43200") tf=PERIOD_MN1;
         if (tf<Period()) tf=Period();
  return(tf);
}
string TimeFrameToString(int tf)
{
   string tfs="";
   if (Period()!=tf)
   switch(tf) {
      case PERIOD_M1:  tfs="M1"  ; break;
      case PERIOD_M5:  tfs="M5"  ; break;
      case PERIOD_M15: tfs="M15" ; break;
      case PERIOD_M30: tfs="M30" ; break;
      case PERIOD_H1:  tfs="H1"  ; break;
      case PERIOD_H4:  tfs="H4"  ; break;
      case PERIOD_D1:  tfs="D1"  ; break;
      case PERIOD_W1:  tfs="W1"  ; break;
      case PERIOD_MN1: tfs="MN1";
   }
   return(tfs);
}

//
//
//
//
//

string StringUpperCase(string str)
{
   string   s = str;
   int      lenght = StringLen(str) - 1;
   int      tchar;
   
   while(lenght >= 0)
      {
         tchar = StringGetChar(s, lenght);
         
         //
         //
         //
         //
         //
         
         if((tchar > 96 && tchar < 123) || (tchar > 223 && tchar < 256))
                  s = StringSetChar(s, lenght, tchar - 32);
         else 
              if(tchar > -33 && tchar < 0)
                  s = StringSetChar(s, lenght, tchar + 224);
         lenght--;
   }
   
   //
   //
   //
   //
   //
   
   return(s);
}