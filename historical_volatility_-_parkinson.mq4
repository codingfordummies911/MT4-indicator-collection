//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1  PaleVioletRed
#property indicator_width1  2
#property indicator_minimum 0

//
//
//
//
//

extern int VolatilityPeriod = 18;

//
//
//
//
//

double valatility[];

//+------------------------------------------------------------------+
//|                                                                  |
//|------------------------------------------------------------------|
//
//
//
//
//

int init()
{
   IndicatorDigits(6);
   SetIndexBuffer(0, valatility);
   return(0);
}
int deinit() { return(0); }

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
   double const_ = 1.0/4.0*MathLog(2);
   int i,limit,counted_bars=IndicatorCounted();
   
   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
           limit=MathMin(Bars-counted_bars,Bars-1);

   //
   //
   //
   //
   //
   
   for(i=limit; i>=0; i--)
   {
      double sum = 0;
         for (int k=0; k<VolatilityPeriod && (i+k)<Bars; k++) sum += const_*MathPow(MathLog(High[i+k]/Low[i+k]),2);
      valatility[i] = MathSqrt(sum/VolatilityPeriod);
   }
   return(0);
}