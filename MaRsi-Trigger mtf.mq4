/*------------------------------------------------------------------+
 |                                              MaRsi-Trigger.mq4   |
 |                                              fx-system@mail.ru   |
 +------------------------------------------------------------------*/
 // по мотивам (сделан из) Trinity-Impulse из CodeBase mql4.com 
 //  автор Trinity-Impulse: basisforex@gmail.com 
 // ??? Сделать: добавить сигналы с 4часа и Daily 
 //              со старших ТФ еще и с весами???
 // ???          добавить PriceAction-тренд и сигнал от регрессии
#property copyright "Copyright © 2010, fx-system@mail.ru"
//----
#property indicator_separate_window
//----
#property indicator_buffers 1
#property indicator_color1 Red
//----
extern int timeFrame = 0;
extern int nPeriodRsi = 3;
extern int nPeriodRsiLong = 13;
extern int nPeriodMa = 5;
extern int nPeriodMaLong = 10;
//extern int nPeriodADX = 8;
//extern int nLevelADX  = 21;
extern int SetPorog = 0; // меняем >0 только, если добавить сигналы от Cci, St, MACD, ...
//----
double c[];
double iCF[];
//+------------------------------------------------------------------+
int init()
 {
   timeFrame = MathMax(timeFrame,Period());
   string short_name;
   IndicatorBuffers(2);
   SetIndexStyle(0, DRAW_LINE);
   SetIndexBuffer(0, iCF);
   SetIndexBuffer(1, c);
   short_name = "MaRsi-Trigger("+nPeriodMa+"/"+nPeriodMaLong+";"+nPeriodRsi+"/"+nPeriodRsiLong+")";
   IndicatorShortName(short_name);
   SetIndexLabel(0, short_name);
   SetIndexDrawBegin(0, nPeriodRsi);
   return(0);
 }
//+------------------------------------------------------------------+
int start()
 {
   int counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit = MathMin(MathMax(Bars-counted_bars,3*timeFrame/Period()),Bars-1);
 
   int j = limit, iPorog;
//   int kfADX = 1;
   // защита порога (не более числа сигналов)
   iPorog=SetPorog; // если появятся внутренние мотивы изменения
   if (SetPorog > 2) iPorog = 0;
   while(j >= 0)
    {
      int y = iBarShift(NULL,timeFrame,Time[j]);
       // Ma
       if (iMA(NULL,timeFrame,nPeriodMa,0,MODE_EMA,PRICE_CLOSE,y) > iMA(NULL,timeFrame,nPeriodMaLong,0,MODE_EMA,PRICE_CLOSE,y)) c[j] = 1;
       if (iMA(NULL,timeFrame,nPeriodMa,0,MODE_EMA,PRICE_CLOSE,y) < iMA(NULL,timeFrame,nPeriodMaLong,0,MODE_EMA,PRICE_CLOSE,y)) c[j] = -1;
       // Rsi
       if (iRSI(NULL,timeFrame,nPeriodRsi,PRICE_WEIGHTED,y) > iRSI(NULL,timeFrame,nPeriodRsiLong,PRICE_MEDIAN,y)) c[j] = c[j] + 1;
       if (iRSI(NULL,timeFrame,nPeriodRsi,PRICE_WEIGHTED,y) < iRSI(NULL,timeFrame,nPeriodRsiLong,PRICE_MEDIAN,y)) c[j] = c[j] - 1;
       // нормируем сигнал??? если сигналов больше 2-х
//       if (c[j] > 0) c[j] = 1;
//       if (c[j] < 0) c[j] = -1;
//       if (iADX(NULL,0,nPeriodADX,PRICE_WEIGHTED,MODE_MAIN,j) > nLevelADX) kfADX = 1;
//          else kfADX = 0;
          iCF[j] = 0;
          if(c[j] > iPorog)
           {
             iCF[j] = 1;
           }
          if(c[j] < -1*iPorog) // ??? -1*iPorog если сигналов>2 и порог не 0
           {
             iCF[j] = -1;
           }
//           iCF[j] = iCF[j]*kfADX;
       j--;
    }
   return(0);
 }
//+------------------------------------------------------------------+