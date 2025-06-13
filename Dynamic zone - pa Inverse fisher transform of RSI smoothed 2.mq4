//+------------------------------------------------------------------+
//|                              Inverse fisher transform of RSI.mq4 |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property  copyright "mladen"
#property  link      "mladenfx@gmail.com"

#property indicator_separate_window
#property indicator_buffers   8
#property indicator_color1    DimGray
#property indicator_color2    PaleVioletRed
#property indicator_color3    PaleVioletRed
#property indicator_color4    DeepSkyBlue
#property indicator_color5    DeepSkyBlue
#property indicator_color6    PaleVioletRed
#property indicator_color7    DeepSkyBlue
#property indicator_color8    DimGray
#property indicator_width2    2
#property indicator_width3    2
#property indicator_width4    2
#property indicator_width5    2
#property indicator_style8    STYLE_DOT
#property indicator_maximum   1
#property indicator_minimum  -1

//
//
//
//
//

#import "dynamicZone.dll"
   double dzBuy(double& sourceArray[],double probabiltyValue, int lookBack, int bars, int i);
   double dzSell(double& sourceArray[],double probabiltyValue, int lookBack, int bars, int i);
#import

//
//
//
//
//

extern string TimeFrame              = "Current time frame";
extern int    RSIPeriod              = 5;
extern int    RSIPrice               = PRICE_CLOSE;
extern double SmoothLength           = 9;
extern double SmoothPhase            = 0;
extern bool   SmoothDouble           = false;
extern double PaFilter               = 1.0;
extern double PaCycles               = 2.0;
extern double DzStartBuyProbability  = 0.15;
extern double DzStartSellProbability = 0.15;
extern bool   Interpolate            = true;

//
//
//
//
//

double ifishua[];
double ifishub[];
double ifishda[];
double ifishdb[];
double ifisher[];
double sli[];
double bli[];
double zli[];

//
//
//
//
//

string indicatorFileName;
bool   returnBars;
bool   calculateValue;
int    timeFrame;

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
   SetIndexBuffer(0,ifisher);
   SetIndexBuffer(1,ifishda);
   SetIndexBuffer(2,ifishdb);
   SetIndexBuffer(3,ifishua);
   SetIndexBuffer(4,ifishub);
   SetIndexBuffer(5,bli);
   SetIndexBuffer(6,sli);
   SetIndexBuffer(7,zli);

      //
      //
      //
      //
      //
      
      indicatorFileName   = WindowExpertName();
      returnBars          = TimeFrame=="returnBars";          if (returnBars)          return(0);
      calculateValue      = TimeFrame=="calculateValue";      if (calculateValue)      return(0);

   //
   //
   //
   //
   //
            
   timeFrame = stringToTimeFrame(TimeFrame);
   IndicatorShortName(timeFrameToString(timeFrame)+" PA 2 inverse fisher of RSI ("+DoubleToStr(PaCycles,2)+","+DoubleToStr(SmoothLength,2)+")");
   return(0);
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

double trend[];

//
//
//
//
//

int start()
{
   int limit,i,r,counted_bars=IndicatorCounted();
   
   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
           limit=MathMin(Bars-counted_bars,Bars-1);
           if (returnBars) { ifisher[0] = limit+1; return(0); }

   //
   //
   //
   //
   //
   
   if (calculateValue || timeFrame==Period())
   {
      if (ArraySize(trend)!=Bars) ArrayResize(trend,Bars);
      if (!calculateValue) if (trend[Bars-limit-1]== 1) CleanPoint(limit,ifishua,ifishub);
      if (!calculateValue) if (trend[Bars-limit-1]==-1) CleanPoint(limit,ifishda,ifishdb);

      //
      //
      //
      //
      //
      
      for(i=limit, r=Bars-i-1; i>=0; i--,r++)
      {
         double price = iMA(NULL,0,1,0,MODE_SMA,RSIPrice,i);
         double DzLookBackBars = iHilbertPhase(price,PaFilter,PaCycles,i);
         double avgRsi = iDSmooth(0.1*(iRSI(NULL,0,RSIPeriod,RSIPrice,i)-50),SmoothLength,SmoothPhase,i);
            ifisher[i] = (MathExp(2*avgRsi)-1)/(MathExp(2*avgRsi)+1);
            bli[i]     = dzBuy (ifisher, DzStartBuyProbability,  DzLookBackBars, Bars, i);
            sli[i]     = dzSell(ifisher, DzStartSellProbability, DzLookBackBars, Bars, i);
            zli[i]     = dzSell(ifisher, 0.5,                    DzLookBackBars, Bars, i);
            if (calculateValue) continue;
            
         //
         //
         //
         //
         //

            trend[r]   = trend[r-1];
               if (ifisher[i] < sli[i] && ifisher[i] > bli[i]) trend[r] =  0;
               if (ifisher[i] > sli[i])                        trend[r] =  1;
               if (ifisher[i] < bli[i])                        trend[r] = -1;
            ifishda[i] = EMPTY_VALUE; ifishdb[i] = EMPTY_VALUE;         
            ifishua[i] = EMPTY_VALUE; ifishub[i] = EMPTY_VALUE;         
               if (trend[r]== 1) PlotPoint(i,ifishua,ifishub,ifisher);
               if (trend[r]==-1) PlotPoint(i,ifishda,ifishdb,ifisher);
      }
      return(0);
   }      

   //
   //
   //
   //
   //

   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));

   if (ArraySize(trend)!=Bars) ArrayResize(trend,Bars);
   if (trend[Bars-limit-1]== 1) CleanPoint(limit,ifishua,ifishub);
   if (trend[Bars-limit-1]==-1) CleanPoint(limit,ifishda,ifishdb);
   for(i=limit, r=Bars-i-1; i>=0; i--,r++)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         ifishda[i] = EMPTY_VALUE; 
         ifishdb[i] = EMPTY_VALUE;         
         ifishua[i] = EMPTY_VALUE; 
         ifishub[i] = EMPTY_VALUE;         
         ifisher[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,RSIPrice,SmoothLength,SmoothPhase,SmoothDouble,PaFilter,PaCycles,DzStartBuyProbability,DzStartSellProbability,0,y);
         bli[i]     = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,RSIPrice,SmoothLength,SmoothPhase,SmoothDouble,PaFilter,PaCycles,DzStartBuyProbability,DzStartSellProbability,5,y);
         sli[i]     = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,RSIPrice,SmoothLength,SmoothPhase,SmoothDouble,PaFilter,PaCycles,DzStartBuyProbability,DzStartSellProbability,6,y);
         zli[i]     = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,RSIPrice,SmoothLength,SmoothPhase,SmoothDouble,PaFilter,PaCycles,DzStartBuyProbability,DzStartSellProbability,7,y);
            if (ifisher[i] < sli[i] && ifisher[i] > bli[i]) trend[r] =  0;
            if (ifisher[i] > sli[i])                        trend[r] =  1;
            if (ifisher[i] < bli[i])                        trend[r] = -1;

         //
         //
         //
         //
         //
      
         if (!Interpolate || y==iBarShift(NULL,timeFrame,Time[i-1])) continue;

         //
         //
         //
         //
         //

         datetime time = iTime(NULL,timeFrame,y);
            for(int n = 1; i+n < Bars && Time[i+n] >= time; n++) continue;	
            double factor = 1.0 / n;
            for(int k = 1; k < n; k++)
            {
               ifisher[i+k] = k*factor*ifisher[i+n] + (1.0-k*factor)*ifisher[i];
               bli[i+k]     = k*factor*bli[i+n]     + (1.0-k*factor)*bli[i];
               sli[i+k]     = k*factor*sli[i+n]     + (1.0-k*factor)*sli[i];
               zli[i+k]     = k*factor*zli[i+n]     + (1.0-k*factor)*zli[i];
            }
   }
   for(i=limit,r=Bars-i-1; i>=0; i--,r++)
   {
      if (trend[r]== 1) PlotPoint(i,ifishua,ifishub,ifisher);
      if (trend[r]==-1) PlotPoint(i,ifishda,ifishdb,ifisher);
   }
   
   //
   //
   //
   //
   //
   
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
           
         if (workHil[r][s+_I1]<0 && workHil[r][s+_Q1]>0) workHil[r][s+_phase] = 180.0-workHil[r][s+_phase];
         if (workHil[r][s+_I1]<0 && workHil[r][s+_Q1]<0) workHil[r][s+_phase] = 180.0+workHil[r][s+_phase];
         if (workHil[r][s+_I1]>0 && workHil[r][s+_Q1]<0) workHil[r][s+_phase] = 360.0-workHil[r][s+_phase];

      //
      //
      //
      //
      //
                        
      workHil[r][s+_deltaPhase] = workHil[r-1][s+_phase]-workHil[r][s+_phase];

         if (workHil[r-1][s+_phase]<90.0 && workHil[r][s+_phase]>270.0)
             workHil[r][s+_deltaPhase] = 360.0+workHil[r-1][s+_phase]-workHil[r][s+_phase];
             workHil[r][s+_deltaPhase] = MathMax(MathMin(workHil[r][s+_deltaPhase],60),7);
      
            //
            //
            //
            //
            //
                  
            double alpha    = 2.0/(1.0+MathMax(filter,1));
            double phaseSum = 0; for (int k=0; phaseSum<cyclesToReach*360.0 && (r-k)>0; k++) phaseSum += workHil[r-k][s+_deltaPhase];
         
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


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

double wrk[][20];

#define bsmax  5
#define bsmin  6
#define volty  7
#define vsum   8
#define avolty 9

//
//
//
//
//

double iDSmooth(double price, double length, double phase, int i, int s=0)
{
   if (SmoothDouble)
         return (iSmooth(iSmooth(price,MathSqrt(length),phase,i,s),MathSqrt(length),phase,i,s+10));
   else  return (iSmooth(price,length,phase,i,s));
}

//
//
//
//
//

double iSmooth(double price, double length, double phase, int i, int s=0)
{
   if (length <=1) return(price);
   if (ArrayRange(wrk,0) != Bars) ArrayResize(wrk,Bars);
   
   int r = Bars-i-1; 
      if (r==0) { for(int k=0; k<7; k++) wrk[r][k+s]=price; for(; k<10; k++) wrk[r][k+s]=0; return(price); }

   //
   //
   //
   //
   //
   
      double len1   = MathMax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
      double pow1   = MathMax(len1-2.0,0.5);
      double del1   = price - wrk[r-1][bsmax+s];
      double del2   = price - wrk[r-1][bsmin+s];
      double div    = 1.0/(10.0+10.0*(MathMin(MathMax(length-10,0),100))/100);
      int    forBar = MathMin(r,10);
	
         wrk[r][volty+s] = 0;
               if(MathAbs(del1) > MathAbs(del2)) wrk[r][volty+s] = MathAbs(del1); 
               if(MathAbs(del1) < MathAbs(del2)) wrk[r][volty+s] = MathAbs(del2); 
         wrk[r][vsum+s] =	wrk[r-1][vsum+s] + (wrk[r][volty+s]-wrk[r-forBar][volty+s])*div;
         
         //
         //
         //
         //
         //
   
         wrk[r][avolty+s] = wrk[r-1][avolty+s]+(2.0/(MathMax(4.0*length,30)+1.0))*(wrk[r][vsum+s]-wrk[r-1][avolty+s]);
            if (wrk[r][avolty+s] > 0)
               double dVolty = wrk[r][volty+s]/wrk[r][avolty+s]; else dVolty = 0;   
	               if (dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
                  if (dVolty < 1)                      dVolty = 1.0;

      //
      //
      //
      //
      //
	        
   	double pow2 = MathPow(dVolty, pow1);
      double len2 = MathSqrt(0.5*(length-1))*len1;
      double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

         if (del1 > 0) wrk[r][bsmax+s] = price; else wrk[r][bsmax+s] = price - Kv*del1;
         if (del2 < 0) wrk[r][bsmin+s] = price; else wrk[r][bsmin+s] = price - Kv*del2;
	
   //
   //
   //
   //
   //
      
      double R     = MathMax(MathMin(phase,100),-100)/100.0 + 1.5;
      double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
      double alpha = MathPow(beta,pow2);

         wrk[r][0+s] = price + alpha*(wrk[r-1][0+s]-price);
         wrk[r][1+s] = (price - wrk[r][0+s])*(1-beta) + beta*wrk[r-1][1+s];
         wrk[r][2+s] = (wrk[r][0+s] + R*wrk[r][1+s]);
         wrk[r][3+s] = (wrk[r][2+s] - wrk[r-1][4+s])*MathPow((1-alpha),2) + MathPow(alpha,2)*wrk[r-1][3+s];
         wrk[r][4+s] = (wrk[r-1][4+s] + wrk[r][3+s]); 

   //
   //
   //
   //
   //

   return(wrk[r][4+s]);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   tfs = StringUpperCase(tfs);
   for (int i=ArraySize(iTfTable)-1; i>=0; i--)
         if (tfs==sTfTable[i] || tfs==""+iTfTable[i]) return(MathMax(iTfTable[i],Period()));
                                                      return(Period());
}
string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

//
//
//
//
//

string StringUpperCase(string str)
{
   string   s = str;

   for (int length=StringLen(str)-1; length>=0; length--)
   {
      int tchar = StringGetChar(s, length);
         if((tchar > 96 && tchar < 123) || (tchar > 223 && tchar < 256))
                     s = StringSetChar(s, length, tchar - 32);
         else if(tchar > -33 && tchar < 0)
                     s = StringSetChar(s, length, tchar + 224);
   }
   return(s);
}