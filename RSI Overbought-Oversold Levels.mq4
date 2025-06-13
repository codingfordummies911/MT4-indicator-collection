//------------------------------------------------------------------
//
//------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-station.com"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1  clrSandyBrown
#property indicator_color2  clrLimeGreen
#property indicator_width1  2
#property indicator_width2  2
#property strict

//
//
//
//
//

extern int    RsiPeriod    = 8;  // RSI period
extern int    SmoothPeriod = 4;  // Smooth period
extern double OverBought   = 70; // Overbought level
extern double OverSold     = 30; // Oversold level

//
//
//
//
//

double ob[],os[],rsi[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int init()
{
   IndicatorBuffers(3);
   SetIndexBuffer(0,ob);
   SetIndexBuffer(1,os);
   SetIndexBuffer(2,rsi);
   return(0);
}
int deinit() { return(0); }
int start()
{
   int counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit=MathMin(Bars-counted_bars,Bars-1);

   //
   //
   //
   //
   //
   
   for(int i=limit; i>=0; i--)
   {
      rsi[i] = iSma(iRSI(NULL,0,RsiPeriod,PRICE_CLOSE,i),SmoothPeriod,i);
      if (i>=Bars-2) { ob[i]=Close[i]; os[i]=Close[i]; continue; }
      
         ob[i] = ob[i+1]; os[i] = os[i+1];
         if (rsi[i]>OverBought && rsi[i]>rsi[i+1]) ob[i] = Close[i];
         if (rsi[i]<OverSold   && rsi[i]<rsi[i+1]) os[i] = Close[i];
   }
   return(0);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//

double workSma[][2];
double iSma(double price, int period, int r, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workSma,0)!= Bars) ArrayResize(workSma,Bars); instanceNo *= 2; r=Bars-r-1; int k;

   //
   //
   //
   //
   //
      
   workSma[r][instanceNo+0] = price;
   workSma[r][instanceNo+1] = price; for(k=1; k<period && (r-k)>=0; k++) workSma[r][instanceNo+1] += workSma[r-k][instanceNo+0];  
   workSma[r][instanceNo+1] /= 1.0*k;
   return(workSma[r][instanceNo+1]);
}