//+------------------------------------------------------------------
//|
//+------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_color1  DarkGray
#property indicator_color2  PaleVioletRed
#property indicator_color3  LimeGreen
#property indicator_color4  LimeGreen
#property indicator_color5  PaleVioletRed
#property indicator_color6  PaleVioletRed
#property indicator_style1  STYLE_DOT
#property indicator_style2  STYLE_DOT
#property indicator_style3  STYLE_DOT
#property indicator_width4  2
#property indicator_width5  2
#property indicator_width6  2
#property indicator_minimum -0.1
#property indicator_maximum  1.1
#property indicator_levelcolor DarkGray

//
//
//
//
//

#import "dynamicZone.dll"
   double dzBuyP(double& sourceArray[],double probabiltyValue, int lookBack, int bars, int i, double precission );
   double dzSellP(double& sourceArray[],double probabiltyValue, int lookBack, int bars, int i, double precission );
#import

//
//
//
//
//

extern double PaCycles          = 1.0;
extern double PaFilter          = 1.0;
extern int    RsiPrice          = 0;
extern int    RsiDepth          = 10;
extern bool   RsiFast           = false;
extern int    DzLookBack        = 35;
extern double DzBuyProbability  = 0.90;
extern double DzSellProbability = 0.90;

//
//
//
//
//

double rsi[];
double zli[];
double bli[];
double sli[];
double rsiDa[];
double rsiDb[];
double slope[];

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
   IndicatorBuffers(7);
   SetIndexBuffer(0,zli);
   SetIndexBuffer(1,bli);
   SetIndexBuffer(2,sli);
   SetIndexBuffer(3,rsi);
   SetIndexBuffer(4,rsiDa);
   SetIndexBuffer(5,rsiDb);
   SetIndexBuffer(6,slope);
      RsiDepth = MathMax(MathMin(RsiDepth,25),2);
   IndicatorShortName("Composite RSI ("+DoubleToStr(PaCycles,2)+","+RsiDepth+")");
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
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit = MathMin(Bars - counted_bars,Bars-1);
         if (slope[limit]==-1) CleanPoint(limit,rsiDa,rsiDb);

   //
   //
   //
   //
   //
   
      for(int i = limit; i >= 0 ; i--)
      {
         double price  = iMA(NULL,0,1,0,MODE_SMA,RsiPrice,i);
         int RsiPeriod = MathMax(3,iHilbertPhase(price,PaFilter,PaCycles,i));
            rsi[i]     = iCompRsi(price,RsiPeriod,RsiDepth,RsiFast,i);
            rsiDa[i]   = EMPTY_VALUE;
            rsiDb[i]   = EMPTY_VALUE;
            slope[i]   = slope[i+1];
               if (rsi[i] > rsi[i+1]) slope[i] =  1;
               if (rsi[i] < rsi[i+1]) slope[i] = -1;
               if (slope[i]==-1) PlotPoint(i,rsiDa,rsiDb,rsi);
         bli[i] = dzBuyP (rsi, DzBuyProbability,  DzLookBack, Bars, i, 0.0001);
         sli[i] = dzSellP(rsi, DzSellProbability, DzLookBack, Bars, i, 0.0001);
         zli[i] = dzSellP(rsi, 0.5,               DzLookBack, Bars, i, 0.0001);
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

double workCompRsi[][26];

//
//
//
//
//

double iCompRsi(double price, double period, int depth, bool fast, int i, int instanceNo=0)
{
   if (ArrayRange(workCompRsi,0) !=Bars) ArrayResize(workCompRsi,Bars);
   if (!fast)
        double alpha = 2.0/(1.0 + period);
   else        alpha = 2.0/(2.0 + (period-1.0)/2.0);
   instanceNo *= 26; i = Bars-i-1;
   
   //
   //
   //
   //
   //
   
   double CU = 0;
   double CD = 0;
   for (int k=0; k<=depth; k++)
   {
      if (i == 0)
            workCompRsi[i][instanceNo+k] = price;
      else  workCompRsi[i][instanceNo+k] = workCompRsi[i-1][instanceNo+k]+alpha*(price-workCompRsi[i-1][instanceNo+k]);

      //
      //
      //
      //
      //
         
      price = workCompRsi[i][k+instanceNo];
      if (k>0)
         if (workCompRsi[i][instanceNo+k-1] >= workCompRsi[i][instanceNo+k])
              CU += workCompRsi[i][instanceNo+k-1] - workCompRsi[i][instanceNo+k  ];
         else CD += workCompRsi[i][instanceNo+k  ] - workCompRsi[i][instanceNo+k-1];
   }
   double trsi = 0; if (CU + CD != 0) trsi = CU / (CU + CD); 
   return(trsi);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

double workHil[][9];
#define _price      0
#define _smooth     1
#define _detrender  2
#define _period     3
#define _instPeriod 4
#define _phase      5
#define _deltaPhase 6
#define _Q1         7
#define _I1         8

#define Pi 3.14159265358979323846264338327950288

//
//
//
//
//

double iHilbertPhase(double price, double filter, double cyclesToReach, int i, int s=0)
{
   if (ArrayRange(workHil,0)!=Bars) ArrayResize(workHil,Bars);
   int r = Bars-i-1; s = s*9;
      
   //
   //
   //
   //
   //
      
      workHil[r][s+_price]      = price;
      workHil[r][s+_smooth]     = (4.0*workHil[r][s+_price]+3.0*workHil[r-1][s+_price]+2.0*workHil[r-2][s+_price]+workHil[r-3][s+_price])/10.0;
      workHil[r][s+_detrender]  = calcComp(r,_smooth,s);
      workHil[r][s+_Q1]         = 0.15*calcComp(r,_detrender,s)  +0.85*workHil[r-1][s+_Q1];
      workHil[r][s+_I1]         = 0.15*workHil[r-3][s+_detrender]+0.85*workHil[r-1][s+_I1];
      workHil[r][s+_phase]      = workHil[r-1][s+_phase];
      workHil[r][s+_instPeriod] = workHil[r-1][s+_instPeriod];

      //
      //
      //
      //
      //
           
         if (MathAbs(workHil[r][s+_I1])>0)
                     workHil[r][s+_phase] = 180.0/Pi*MathArctan(MathAbs(workHil[r][s+_Q1]/workHil[r][s+_I1]));
           
         if (workHil[r][s+_I1]<0 && workHil[r][s+_Q1]>0) workHil[r][s+_phase] = 180-workHil[r][s+_phase];
         if (workHil[r][s+_I1]<0 && workHil[r][s+_Q1]<0) workHil[r][s+_phase] = 180+workHil[r][s+_phase];
         if (workHil[r][s+_I1]>0 && workHil[r][s+_Q1]<0) workHil[r][s+_phase] = 360-workHil[r][s+_phase];

      //
      //
      //
      //
      //
                        
      workHil[r][s+_deltaPhase] = workHil[r-1][s+_phase]-workHil[r][s+_phase];

         if (workHil[r-1][s+_phase]<90 && workHil[r][s+_phase]>270)
             workHil[r][s+_deltaPhase] = 360+workHil[r-1][s+_phase]-workHil[r][s+_phase];
             workHil[r][s+_deltaPhase] = MathMax(MathMin(workHil[r][s+_deltaPhase],60),7);
      
            //
            //
            //
            //
            //
                  
            double alpha    = 2.0/(1.0+MathMax(filter,1));
            double phaseSum = 0; for (int k=0; phaseSum<cyclesToReach*360 && (r-k)>0; k++) phaseSum += workHil[r-k][s+_deltaPhase];
         
            if (k>0) workHil[r][s+_instPeriod]= k;
                    workHil[r][s+_period] = workHil[r-1][s+_period]+alpha*(workHil[r][s+_instPeriod]-workHil[r-1][s+_period]);
            return (workHil[r][s+_period]);
}

//
//
//
//
//

double calcComp(int r, int from, int s)
{
   return((0.0962*workHil[r  ][s+from] + 
           0.5769*workHil[r-2][s+from] - 
           0.5769*workHil[r-4][s+from] - 
           0.0962*workHil[r-6][s+from]) * (0.075*workHil[r-1][s+_period] + 0.54));
}

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
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
                first[i]   = from[i];
                first[i+1] = from[i+1];
                second[i]  = EMPTY_VALUE;
            }
         else {
                second[i]   =  from[i];
                second[i+1] =  from[i+1];
                first[i]    = EMPTY_VALUE;
            }
      }
   else
      {
         first[i]  = from[i];
         second[i] = EMPTY_VALUE;
      }
}