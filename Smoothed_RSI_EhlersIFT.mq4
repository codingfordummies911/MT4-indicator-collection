//+------------------------------------------------------------------+
//|   Smoothed_RSI_EhlersIFT.mq4
//+------------------------------------------------------------------+
#include <stdlib.mqh>
#property indicator_separate_window
#property indicator_levelcolor Black
#property indicator_level1 0.5
#property indicator_style1 STYLE_DOT
#property indicator_level2 -0.5
#property indicator_style2 STYLE_DOT
#property indicator_buffers 1

extern int rsiLength = 5;
extern int lwmaPeriod = 9;  
extern color rsiColor = Green;
extern int width = 2;

double SRSI[];
double rsi[];
double lwma[];

int init() 
{
   IndicatorBuffers(3);

   SetIndexBuffer(0,SRSI);
   SetIndexStyle(0,DRAW_LINE,0,width,rsiColor);

   SetIndexBuffer(1,rsi);
   SetIndexStyle(1,DRAW_NONE);

   SetIndexBuffer(2,lwma);
   SetIndexStyle(2,DRAW_NONE);

   return (0);
}
  

int start()
{
   int countedBars = IndicatorCounted();
   if (countedBars < 0) return (-1);
   if (countedBars > 0) countedBars--;
   int limit = Bars-countedBars;
    
   for (int i=limit;i>=0;i--)
   {
      rsi[i] = 0.1 * (iRSI(NULL,0,rsiLength,PRICE_CLOSE,i) - 50);
   }
      
   for (i=limit;i>=0;i--)
   {
      lwma[i] = iMAOnArray(rsi,0,lwmaPeriod,0,MODE_LWMA,i);
   }
      
   for (i=limit;i>=0;i--)
   {
      SRSI[i] = (MathExp(2*lwma[i])-1) / (MathExp(2*lwma[i])+1);
   }
   return (0);   
}
/*
Vars: IFish(0);
Value1 = .1*(RSI(Close, 5) - 50);
Value2 = WAverage(Value1, 9);
IFish = (ExpValue(2*Value2) - 1) / (ExpValue(2*Value2) + 1);
Plot1(IFish, "IFish");
Plot2(0.5, "Sell Ref");
Plot3(-0.5, "Buy Ref");
*/

