/*------------------------------------------------------------------+
 |                                                  Rsi_Bands_B.mq4 |
 |                                                 Copyright © 2010 |
 |                                             basisforex@gmail.com |
 +------------------------------------------------------------------*/
#property copyright "Copyright © 2010, basisforex@gmail.com"
#property link      "basisforex@gmail.com"
//-----
#property indicator_chart_window
#property indicator_buffers  2
#property indicator_color1   Blue
#property indicator_color2   Yellow
//-----
extern    int       nPeriod     = 13;
extern    int       MaShift     = 0;
//-----
double    Deviation, r;
double    MaBuffer[];
double    RSIBuffer[];
//+------------------------------------------------------------------+
int init()
 {
   SetIndexShift(0, MaShift);
   SetIndexShift(1, MaShift);
   //-----
   SetIndexBuffer(0, MaBuffer);
   SetIndexBuffer(1, RSIBuffer);
   //-----
   SetIndexStyle(0, DRAW_LINE, STYLE_DOT);
   SetIndexStyle(1, DRAW_LINE);
   //-----
   SetIndexLabel(0, "MA");
   SetIndexLabel(1, "RSI");
   //-----
   return(0);
 }
//+------------------------------------------------------------------+
int start()
 {
   int limit;
   double a;
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) return(-1);
   if(counted_bars > 0) counted_bars--;
   limit = Bars - counted_bars;
   for(int i = 0; i < limit; i++)
    {
      a = 0;
      for(int j = 0; j < nPeriod; j++)
       {
         a = a + (iHigh(NULL, 0, i + j) + iLow(NULL, 0, i + j) + iClose(NULL, 0, i + j) * 2) / 4;
       }       
      MaBuffer[i]  =  a / nPeriod;
      //-----      
      r = iRSI(NULL, 0, nPeriod, PRICE_WEIGHTED, i);
      Deviation = iATR(NULL, 0, nPeriod, i) * 300;
      //-----
      if(iHigh(NULL, 0, i) > MaBuffer[i] && iClose(NULL, 0, i) > MaBuffer[i])
       {
         RSIBuffer[i] = MaBuffer[i] + r * Point * Deviation;
       }  
      else if(iLow(NULL, 0, i) < MaBuffer[i] && iClose(NULL, 0, i) < MaBuffer[i])
       {
         RSIBuffer[i] = MaBuffer[i] - (100 - r) * Point * Deviation;
       }
      else
       {
         RSIBuffer[i] = MaBuffer[i];
       }    
    }  
   //-----
   return(0);
 }
//+------------------------------------------------------------------+

/*      switch (Period())
       {
         case 1:
            Deviation = 0.236;
            break;
         case 5:
            Deviation = 0.5;
            break; 
         case 15:
            Deviation = 0.764;
            break; 
         case 30:
            Deviation = 1;
            break;
         case 60:
            Deviation = 1.618;
            break;
         case 240:
            Deviation = 2.618;
            break;
         case 1440:
            Deviation = 4.618;
            break;
         case 10080:
            Deviation = 10.618;
            break;
         case 43200:
            Deviation = 25.618;
            break;
       }                                 
*/   