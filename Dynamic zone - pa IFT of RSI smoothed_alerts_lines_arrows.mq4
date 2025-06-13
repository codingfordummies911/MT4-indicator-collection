//+------------------------------------------------------------------+
//|                              Inverse fisher transform of RSI.mq4 |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property  copyright "mladen"
#property  link      "mladenfx@gmail.com"

#property indicator_separate_window
#property indicator_buffers   8
#property indicator_color1    Goldenrod
#property indicator_color2    LimeGreen
#property indicator_color3    LimeGreen
#property indicator_color4    Red
#property indicator_color5    Red
#property indicator_color6    DeepSkyBlue
#property indicator_color7    PaleVioletRed
#property indicator_color8    DimGray
#property indicator_width1    2
#property indicator_width2    2
#property indicator_width3    2
#property indicator_width4    2
#property indicator_width5    2
#property indicator_style8    STYLE_DASH

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
extern int    RsiPeriod              = 5;
extern int    RsiPrice               = PRICE_CLOSE;
extern string _rsimethods            = "0=rsi,1=wilder rsi,2=rsx,3=cuttler rsi ";
extern int    RsiMethod              = 0;
extern double SmoothLength           = 9;
extern double SmoothPhase            = 0;
extern bool   SmoothDouble           = false;
extern double PaFilter               = 1.0;
extern double PaCycles               = 2.0;
extern double DzStartBuyProbability  = 0.10;
extern double DzStartSellProbability = 0.10;
extern bool   Interpolate            = true;

extern bool   alertsOn               = true;
extern bool   alertsOnUpDnLevelCross = true;
extern bool   alertsOnCurrent        = true;
extern bool   alertsMessage          = true;
extern bool   alertsSound            = false;
extern bool   alertsEmail            = false;

extern bool   arrowsVisible          = true;
extern string arrowsIdentifier       = "DXIFT Arrows1";
extern double arrowsDisplacement     = 1.0;
extern color  arrowsUpColor          = LimeGreen;
extern color  arrowsDnColor          = Red;
extern bool   arrowsOnUpDnLevelCross = true;

extern bool   LinesVisible           = false;
extern string verticalLinesID        = "DzIft lines1";
extern color  verticalLinesUpColor   = DeepSkyBlue;
extern color  verticalLinesDnColor   = PaleVioletRed;
extern int    verticalLinesStyle     = STYLE_DOT;
extern int    verticalLinesWidth     = 0;
extern bool   linesOnUpDnLevelCross  = true;

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
double trends[][1];
#define _tup1 0

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
   IndicatorShortName(timeFrameToString(timeFrame)+" PA 2 inverse fisher of "+getRsiName(RsiMethod)+" ("+DoubleToStr(PaCycles,2)+","+DoubleToStr(SmoothLength,2)+")");
   return(0);
}
int deinit()
{

   if (!calculateValue && LinesVisible)  deleteLines();
   if (!calculateValue && arrowsVisible) deleteArrows();
   
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
      if (ArrayRange(trends,0)!=Bars) {  ArrayResize(trends,Bars); }
      if (!calculateValue) if (trend[Bars-limit-1]== 1) CleanPoint(limit,ifishua,ifishub);
      if (!calculateValue) if (trend[Bars-limit-1]==-1) CleanPoint(limit,ifishda,ifishdb);

      //
      //
      //
      //
      //
      
      for(i=limit, r=Bars-i-1; i>=0; i--,r++)
      {
         double DzLookBackBars = iHilbertPhase(getPrice(RsiPrice,i),PaFilter,PaCycles,i);
         double avgRsi = iDSmooth(0.1*(iRsi(getPrice(RsiPrice,i),RsiPeriod,i,0,RsiMethod)-50),SmoothLength,SmoothPhase,i);
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
               setTrends(i,r);
               manageArrow(i,r);
               manageLine(i,r);
      }
      manageAlerts(); 
      return(0);
   }      

   //
   //
   //
   //
   //

   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));

   if (ArraySize(trend)!=Bars) ArrayResize(trend,Bars);
   if (ArrayRange(trends,0)!=Bars) ArrayResize(trends,Bars);
   if (trend[Bars-limit-1]== 1) CleanPoint(limit,ifishua,ifishub);
   if (trend[Bars-limit-1]==-1) CleanPoint(limit,ifishda,ifishdb);
   for(i=limit, r=Bars-i-1; i>=0; i--,r++)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         ifishda[i] = EMPTY_VALUE; 
         ifishdb[i] = EMPTY_VALUE;         
         ifishua[i] = EMPTY_VALUE; 
         ifishub[i] = EMPTY_VALUE;         
         ifisher[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,"",RsiMethod,SmoothLength,SmoothPhase,SmoothDouble,PaFilter,PaCycles,DzStartBuyProbability,DzStartSellProbability,0,y);
         bli[i]     = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,"",RsiMethod,SmoothLength,SmoothPhase,SmoothDouble,PaFilter,PaCycles,DzStartBuyProbability,DzStartSellProbability,5,y);
         sli[i]     = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,"",RsiMethod,SmoothLength,SmoothPhase,SmoothDouble,PaFilter,PaCycles,DzStartBuyProbability,DzStartSellProbability,6,y);
         zli[i]     = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiPeriod,RsiPrice,"",RsiMethod,SmoothLength,SmoothPhase,SmoothDouble,PaFilter,PaCycles,DzStartBuyProbability,DzStartSellProbability,7,y);
            if (ifisher[i] < sli[i] && ifisher[i] > bli[i]) trend[r] =  0;
            if (ifisher[i] > sli[i])                        trend[r] =  1;
            if (ifisher[i] < bli[i])                        trend[r] = -1;
            
            setTrends(i,r);
            manageArrow(i,r);
            manageLine(i,r);

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
            for(int k = 1; k < n; k++)
            {
               ifisher[i+k] = ifisher[i] + (ifisher[i+n] - ifisher[i]) * k/n;
               bli[i+k]     = bli[i]     + (bli[i+n]     - bli[i]    ) * k/n;
               sli[i+k]     = sli[i]     + (sli[i+n]     - sli[i]    ) * k/n;
               zli[i+k]     = zli[i]     + (zli[i+n]     - zli[i]    ) * k/n;
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
   
   manageAlerts();
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

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//

double getPrice(int type, int i)
{
   switch (type)
   {
      case 7:     return((Open[i]+Close[i])/2.0);
      case 8:     return((Open[i]+High[i]+Low[i]+Close[i])/4.0);
      default :   return(iMA(NULL,0,1,0,MODE_SMA,type,i));
   }      
}

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//
//

string rsiMethodNames[] = {"rsi","wilders rsi","rsx","cuttler rsi"};
string getRsiName(int& method)
{
   int max = ArraySize(rsiMethodNames)-1;
      method=MathMax(MathMin(method,max),0); return(rsiMethodNames[method]);
}

//
//
//
//
//

double workRsi[][13];
#define _price  0
#define _change 1
#define _changa 2

double iRsi(double price, double period, int i, int instanceNo=0, int rsiMode=0)
{
   if (ArrayRange(workRsi,0)!=Bars) ArrayResize(workRsi,Bars);
      int z = instanceNo*13; 
      int r = Bars-i-1;
   
   //
   //
   //
   //
   //
   
   workRsi[r][z+_price] = price;
   switch (rsiMode)
   {
      case 0:
         double alpha = 1.0/period; 
         if (r<period)
            {
               int k; double sum = 0; for (k=0; k<period && (r-k-1)>=0; k++) sum += MathAbs(workRsi[r-k][z+_price]-workRsi[r-k-1][z+_price]);
                  workRsi[r][z+_change] = (workRsi[r][z+_price]-workRsi[0][z+_price])/MathMax(k,1);
                  workRsi[r][z+_changa] =                                         sum/MathMax(k,1);
            }
         else
            {
               double change = workRsi[r][z+_price]-workRsi[r-1][z+_price];
                               workRsi[r][z+_change] = workRsi[r-1][z+_change] + alpha*(        change  - workRsi[r-1][z+_change]);
                               workRsi[r][z+_changa] = workRsi[r-1][z+_changa] + alpha*(MathAbs(change) - workRsi[r-1][z+_changa]);
            }
         if (workRsi[r][z+_changa] != 0)
               return(50.0*(workRsi[r][z+_change]/workRsi[r][z+_changa]+1));
         else  return(50.0);
         
      //
      //
      //
      //
      //
      
      case 1 :
         workRsi[r][z+1] = iSmma(0.5*(MathAbs(workRsi[r][z+_price]-workRsi[r-1][z+_price])+(workRsi[r][z+_price]-workRsi[r-1][z+_price])),0.5*(period-1),Bars-i-1,0);
         workRsi[r][z+2] = iSmma(0.5*(MathAbs(workRsi[r][z+_price]-workRsi[r-1][z+_price])-(workRsi[r][z+_price]-workRsi[r-1][z+_price])),0.5*(period-1),Bars-i-1,1);
         if((workRsi[r][z+1] + workRsi[r][z+2]) != 0) 
               return(100.0 * workRsi[r][z+1]/(workRsi[r][z+1] + workRsi[r][z+2]));
         else  return(50);

      //
      //
      //
      //
      //

      case 2 :     
         double Kg = (3.0)/(2.0+period), Hg = 1.0-Kg;
         if (r<period) { for (k=1; k<13; k++) workRsi[r][k+z] = 0; return(50); }  

         //
         //
         //
         //
         //
      
         double mom = workRsi[r][_price+z]-workRsi[r-1][_price+z];
         double moa = MathAbs(mom);
         for (k=0; k<3; k++)
         {
            int kk = k*2;
            workRsi[r][z+kk+1] = Kg*mom                + Hg*workRsi[r-1][z+kk+1];
            workRsi[r][z+kk+2] = Kg*workRsi[r][z+kk+1] + Hg*workRsi[r-1][z+kk+2]; mom = 1.5*workRsi[r][z+kk+1] - 0.5 * workRsi[r][z+kk+2];
            workRsi[r][z+kk+7] = Kg*moa                + Hg*workRsi[r-1][z+kk+7];
            workRsi[r][z+kk+8] = Kg*workRsi[r][z+kk+7] + Hg*workRsi[r-1][z+kk+8]; moa = 1.5*workRsi[r][z+kk+7] - 0.5 * workRsi[r][z+kk+8];
         }
         if (moa != 0)
              return(MathMax(MathMin((mom/moa+1.0)*50.0,100.00),0.00)); 
         else return(50);
            
      //
      //
      //
      //
      //
      
      case 3 :
         double sump = 0;
         double sumn = 0;
         for (k=0; k<period; k++)
         {
            double diff = workRsi[r-k][z+_price]-workRsi[r-k-1][z+_price];
               if (diff > 0) sump += diff;
               if (diff < 0) sumn -= diff;
         }
         if (sumn > 0)
               return(100.0-100.0/(1.0+sump/sumn));
         else  return(50);
   } 
}

//
//
//
//
//
//

double workSmma[][2];
double iSmma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workSmma,0)!= Bars) ArrayResize(workSmma,Bars);

   //
   //
   //
   //
   //

   if (r<period)
         workSmma[r][instanceNo] = price;
   else  workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
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

//
//
//
//
//

void setTrends(int i, int r)
{
   trends[r][_tup1] = trends[r-1][_tup1];
   
   
      if (ifisher[i] >= bli[i] && ifisher[i+1] < bli[i+1]) trends[r][_tup1] =  1;
      if (ifisher[i] <= sli[i] && ifisher[i+1] > sli[i+1]) trends[r][_tup1] = -1;
    
 
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

void manageAlerts()
{
   if (!calculateValue && alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1; whichBar = iBarShift(NULL,0,iTime(NULL,timeFrame,whichBar)); 
                             whichBar = Bars-whichBar-1;

      //
      //
      //
      //
      //
            
      static datetime time1 = 0;
      static string   mess1 = "";
      if (alertsOnUpDnLevelCross && trends[whichBar][_tup1] != trends[whichBar-1][_tup1])
      {
         if (trends[whichBar][_tup1] ==  1) doAlert(time1,mess1,whichBar,"crossed lower level up");
         if (trends[whichBar][_tup1] == -1) doAlert(time1,mess1,whichBar,"crossed upper level down");
      }
      
   }
}

//
//
//
//
//

void doAlert(datetime& previousTime, string& previousAlert, int forBar, string doWhat)
{
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[forBar]) {
       previousAlert  = doWhat;
       previousTime   = Time[forBar];

       //
       //
       //
       //
       //

       message =  StringConcatenate(Symbol()," ",timeFrameToString(timeFrame)," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," Vol adj. bands ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," Vol adj. bands "),message);
          if (alertsSound)   PlaySound("alert2.wav");
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

void manageArrow(int i, int r)
{
   if (!calculateValue && arrowsVisible)
   {
      deleteArrow(Time[i]);
      if (arrowsOnUpDnLevelCross && trends[r][_tup1]!=trends[r-1][_tup1])
      {
         if (trends[r][_tup1] == 1) drawArrow(i,arrowsUpColor,241,false);
         if (trends[r][_tup1] ==-1) drawArrow(i,arrowsDnColor,242,true);
      }
      
   }
}               

//
//
//
//
//

void drawArrow(int i,color theColor,int theCode,bool up)
{
   string name = arrowsIdentifier+":"+Time[i];
   double gap  = iATR(NULL,0,20,i);   
   
      //
      //
      //
      //
      //
      
      ObjectCreate(name,OBJ_ARROW,0,Time[i],0);
         ObjectSet(name,OBJPROP_ARROWCODE,theCode);
         ObjectSet(name,OBJPROP_COLOR,theColor);
         if (up)
               ObjectSet(name,OBJPROP_PRICE1,High[i] + arrowsDisplacement * gap);
         else  ObjectSet(name,OBJPROP_PRICE1,Low[i]  - arrowsDisplacement * gap);
}

//
//
//
//
//

void deleteArrows()
{
   string lookFor       = arrowsIdentifier+":";
   int    lookForLength = StringLen(lookFor);
   for (int i=ObjectsTotal()-1; i>=0; i--)
   {
      string objectName = ObjectName(i);
         if (StringSubstr(objectName,0,lookForLength) == lookFor) ObjectDelete(objectName);
   }
}

//
//
//
//
//

void deleteArrow(datetime time)
{
   string lookFor = arrowsIdentifier+":"+time; ObjectDelete(lookFor);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

void manageLine(int i, int r)
{
   if (!calculateValue && LinesVisible)
   {
      deleteLine(Time[i]);
      if (linesOnUpDnLevelCross && trends[r][_tup1]!=trends[r-1][_tup1])
      {
         if (trends[r][_tup1] == 1) drawLine(i,verticalLinesUpColor);
         if (trends[r][_tup1] ==-1) drawLine(i,verticalLinesDnColor);
      }
      
   }
}               

void drawLine(int i,color theColor)
{
   string name = verticalLinesID+":"+Time[i];
   
      //
      //
      //
      //
      //
      
      ObjectCreate(name,OBJ_VLINE,0,Time[i],0);
         ObjectSet(name,OBJPROP_COLOR,theColor);
         ObjectSet(name,OBJPROP_STYLE,verticalLinesStyle);
         ObjectSet(name,OBJPROP_WIDTH,verticalLinesWidth);
         ObjectSet(name,OBJPROP_BACK,true);
}

//
//
//
//
//

void deleteLines()
{
   string lookFor       = verticalLinesID+":";
   int    lookForLength = StringLen(lookFor);
   for (int i=ObjectsTotal()-1; i>=0; i--)
   {
      string objectName = ObjectName(i);
         if (StringSubstr(objectName,0,lookForLength) == lookFor) ObjectDelete(objectName);
   }
}

//
//
//
//
//

void deleteLine(datetime time)
{
   string lookFor = verticalLinesID+":"+time; ObjectDelete(lookFor);
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//