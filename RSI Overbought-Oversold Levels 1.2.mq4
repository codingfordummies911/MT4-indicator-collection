//------------------------------------------------------------------
//
//------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-station.com"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1  clrSandyBrown
#property indicator_color2  clrSilver
#property indicator_color3  clrLimeGreen
#property indicator_width1  2
#property indicator_width3  2
#property strict

//
//
//
//
//

enum enMode
{
   ob_onCross, // Set OB/OS levels only when the levels are crossed
   ob_onZone   // Set OB/OS levels when the RSI levels are above or bellow the desired levels
};
extern int    RsiPeriod    = 8;  // RSI period
extern int    SmoothPeriod = 4;  // Smooth period
extern double OverBought   = 70; // Overbought level
extern double OverSold     = 30; // Oversold level
extern enMode Mode         = ob_onZone; // Calculation method

//
//
//
//
//

double ob[],os[],mi[],rsi[],state[];

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
   IndicatorBuffers(5);
   SetIndexBuffer(0,ob);
   SetIndexBuffer(1,mi);
   SetIndexBuffer(2,os);
   SetIndexBuffer(3,rsi);
   SetIndexBuffer(4,state);
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
      if (i>=Bars-2) { ob[i]=Close[i]; os[i]=Close[i]; state[i] = 0; continue; }
      
         ob[i]    = ob[i+1]; os[i] = os[i+1];
         state[i] = 0;
            if (rsi[i]>OverBought && rsi[i]>rsi[i+1]) state[i] =  1;
            if (rsi[i]<OverSold   && rsi[i]<rsi[i+1]) state[i] = -1;
            if (Mode==ob_onZone)
            {
               if (state[i]== 1) if (state[i]!=state[i+1]) ob[i] = Close[i]; else ob[i] = MathMax(Close[i],ob[i+1]);
               if (state[i]==-1) if (state[i]!=state[i+1]) os[i] = Close[i]; else os[i] = MathMin(Close[i],os[i+1]);
            }
            else
            {
               if (state[i+1]!= 1 && state[i]== 1) ob[i] = Close[i];
               if (state[i+1]!=-1 && state[i]==-1) os[i] = Close[i];
            }
            mi[i] = (ob[i]+os[i])/2.0;
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