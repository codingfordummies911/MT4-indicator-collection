//+------------------------------------------------------------------+
//|                                     One more average - bands.mq4 |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1  Green
#property indicator_color2  Red
#property indicator_color3  Green
#property indicator_width1  2

//
//
//
//
//

extern int    Length        = 26;
extern int    AppliedPrice  = PRICE_CLOSE;
extern double Speed         = 1.0;
extern bool   Adaptive      = true;
extern bool   ShowBands     = true;
extern double AtrMultiplier = 1.0;
extern int    AtrPeriod     = 20;
extern int    AtrShift      = 10;

//
//
//
//
//

double average[];
double bandUp[];
double bandDo[];
double stored[][7];

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
   SetIndexBuffer(0,average);
   SetIndexBuffer(1,bandUp);
   SetIndexBuffer(2,bandDo);
         Length = MathMax(Length,1);
         Speed  = MathMax(Speed,-1.5);
         if (ShowBands)
         {
            SetIndexStyle(1,DRAW_LINE);
            SetIndexStyle(2,DRAW_LINE);
         }
         else
         {            
            SetIndexStyle(1,DRAW_NONE);
            SetIndexStyle(2,DRAW_NONE);
         }            
   IndicatorShortName("One more average ("+Length+")");
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
   int counted_bars=IndicatorCounted();
   int i,r,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = Bars-counted_bars;
         if (ArrayRange(stored,0) != Bars) ArrayResize(stored,Bars);

   //
   //
   //
   //
   //

   for(i=limit, r=Bars-limit-1; i>=0; i--,r++)
   {
      average[i] = iAverage(iMA(NULL,0,1,0,MODE_SMA,AppliedPrice,i),Length,Speed,Adaptive,r);
      bandUp[i]  = average[i]+AtrMultiplier*iATR(NULL,0,AtrPeriod,i+AtrShift);
      bandDo[i]  = average[i]-AtrMultiplier*iATR(NULL,0,AtrPeriod,i+AtrShift);
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
//

#define E1  0
#define E2  1
#define E3  2
#define E4  3
#define E5  4
#define E6  5
#define res 6

//
//
//
//
//

double iAverage(double price, double averagePeriod, double tconst, bool adaptive, int r)
{
   double e1=stored[r-1][E1];  double e2=stored[r-1][E2];
   double e3=stored[r-1][E3];  double e4=stored[r-1][E4];
   double e5=stored[r-1][E5];  double e6=stored[r-1][E6];

   //
   //
   //
   //
   //

      if (adaptive && (averagePeriod > 1))
      {
         double minPeriod = averagePeriod/2.0;
         double maxPeriod = minPeriod*5.0;
         int    endPeriod = MathCeil(maxPeriod);
         double signal    = MathAbs((price-stored[r-endPeriod][res]));
         double noise     = 0.00000000001;

            for(int k=1; k<endPeriod; k++) noise=noise+MathAbs(price-stored[r-k][res]);

         averagePeriod = ((signal/noise)*(maxPeriod-minPeriod))+minPeriod;
      }
      
      //
      //
      //
      //
      //
      
      double alpha = (2.0+tconst)/(1.0+tconst+averagePeriod);

      e1 = e1 + alpha*(price-e1); e2 = e2 + alpha*(e1-e2); double v1 = 1.5 * e1 - 0.5 * e2;
      e3 = e3 + alpha*(v1   -e3); e4 = e4 + alpha*(e3-e4); double v2 = 1.5 * e3 - 0.5 * e4;
      e5 = e5 + alpha*(v2   -e5); e6 = e6 + alpha*(e5-e6); double v3 = 1.5 * e5 - 0.5 * e6;

   //
   //
   //
   //
   //

   stored[r][E1]  = e1;  stored[r][E2] = e2;
   stored[r][E3]  = e3;  stored[r][E4] = e4;
   stored[r][E5]  = e5;  stored[r][E6] = e6;
   stored[r][res] = price;
   return(v3);
}