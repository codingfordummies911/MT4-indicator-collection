//------------------------------------------------------------------
//
//------------------------------------------------------------------

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 Lime
#property indicator_color2 SlateBlue
#property indicator_color3 Orange

extern int    RSIPeriod     = 14;
extern int    BandPeriod    = 20;
extern double BandDeviation = 1.3185;

double RSIBuf[],UpZone[],DnZone[];

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
   SetIndexBuffer(0,RSIBuf);
   SetIndexBuffer(1,UpZone);
   SetIndexBuffer(2,DnZone);
   return(0);
}
int deinit() { return(0); }

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int start()
{
   int counted_bars=IndicatorCounted();
      if(counted_bars < 0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit = MathMin(Bars-counted_bars,Bars-1);
   
   for(int i=limit; i>=0; i--) RSIBuf[i] = iRSI(NULL,0,RSIPeriod,PRICE_WEIGHTED,i);
   for(    i=limit; i>=0; i--) 
   {
      double ma  = iMAOnArray(RSIBuf,0,BandPeriod,0,MODE_SMA,i);
      double dev = iStdDevOnArray(RSIBuf,0,BandPeriod,0,MODE_SMA,i);
         UpZone[i] = ma + BandDeviation * dev;
         DnZone[i] = ma - BandDeviation * dev;  
   }
   return(0);
}