//+------------------------------------------------------------------+
//|                                                  OnChart Rsi.mq4 |
//|                                                           mladen |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      ""

#property indicator_chart_window
#property indicator_buffers 6
#property indicator_color1  LimeGreen
#property indicator_color2  PaleVioletRed
#property indicator_color3  PaleVioletRed
#property indicator_color4  BlueViolet
#property indicator_color5  PaleVioletRed
#property indicator_color6  DeepSkyBlue
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_style4  STYLE_DOT
#property indicator_style5  STYLE_DASHDOT
#property indicator_style6  STYLE_DASHDOT

//
//
//
//
//

extern string RsiParams     = "14,45,55;15,45,55;16,45,55;17,45,55;18,45,55;19,45,55;20,45,55;21,45,55;";
extern int    RsiPrice      = PRICE_CLOSE;
extern int    RsiMaMethod   = 18;
extern int    maPeriod      = 20;
extern int    maMethod      =  3;
extern int    maPrice       =  0;
extern int    HighLowPeriod = 34;
extern bool   ShowChannel   = true;
extern bool   ShowZigZag    = true;
extern string RsiMaMethods  = "";
extern string __0           = "SMA";
extern string __1           = "EMA";
extern string __2           = "Double smoothed EMA";
extern string __3           = "Double EMA (DEMA)";
extern string __4           = "Triple EMA (TEMA)";
extern string __5           = "Smoothed MA";
extern string __6           = "Linear weighted MA";
extern string __7           = "Parabolic weighted MA";
extern string __8           = "Alexander MA";
extern string __9           = "Volume weghted MA";
extern string __10          = "Hull MA";
extern string __11          = "Triangular MA";
extern string __12          = "Sine weighted MA";
extern string __13          = "Linear regression";
extern string __14          = "IE/2";
extern string __15          = "NonLag MA";
extern string __16          = "Zero lag EMA";
extern string __17          = "Leader EMA";
extern string __18          = "Super smoother";
extern string __19          = "Smoother";
//
//
//
//
//

double rsiSum[];
double rsiSumda[];
double rsiSumdb[];
double HB[];
double LB[];
double ZZ[];
double ZZLow[];
double ZZHigh[];
int    periods[];
double slope[];
int    size;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int init()
{
   IndicatorBuffers(9);
   SetIndexBuffer(0,rsiSum);
   SetIndexBuffer(1,rsiSumda);
   SetIndexBuffer(2,rsiSumdb);
   SetIndexBuffer(3,ZZ);
   SetIndexBuffer(4,HB);
   SetIndexBuffer(5,LB);
   SetIndexBuffer(6,ZZLow);
   SetIndexBuffer(7,ZZHigh);
   SetIndexBuffer(8,slope);
   
   SetIndexStyle(3,DRAW_SECTION);
   SetIndexEmptyValue(3,0);
   SetIndexEmptyValue(6,0);
   SetIndexEmptyValue(7,0);
          
   if (ShowChannel)
   {
     SetIndexStyle(4,DRAW_LINE);
     SetIndexStyle(5,DRAW_LINE);
   }
   else      
   {
     SetIndexStyle(4,DRAW_NONE);
     SetIndexStyle(5,DRAW_NONE);
   }
   
   //
   //
   //
   //
   //
   
   RsiParams = StringTrimLeft(StringTrimRight(RsiParams));
      if (StringSubstr(RsiParams,StringLen(RsiParams),1) != ";")
                       RsiParams = StringConcatenate(RsiParams,";");

         //
         //
         //
         //
         //                                   
            
         int n,m,s = 0;
         int i = StringFind(RsiParams,";",s);
         while (i > 0)
         {
            string current = StringSubstr(RsiParams,s,i-s);
            if (current!=";")
            {
               size = ArraySize(periods)+1;
                      ArrayResize(periods ,size);
                        n = StringFind(current,",",0); periods[size-1]  = StrToInteger(StringSubstr(current,0,n));  m = n+1;
            }
            s = i + 1;
            i = StringFind(RsiParams,";",s);
        }
        
      //
      //
      //
      //
      //
               
   IndicatorShortName(getAverageName(RsiMaMethod));
   return(0);
}
int deinit()
{
   return(0);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int start()
{
   int lastZag;
   int counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit = MathMin(Bars-counted_bars,Bars-1);
         if (slope[limit] == -1) CleanPoint(limit,rsiSumda,rsiSumdb);

   //
   //
   //
   //
   //

   if (ShowZigZag)
   for(lastZag = limit+1; lastZag < Bars; lastZag++) if (ZZLow[lastZag] != 0 || ZZHigh[lastZag] != 0) break;
   for(int i=limit; i>=0; i--) 
   {
         
      double avgRange = iATR(NULL,PERIOD_D1,maPeriod,i);
      double maValue  = iMA(NULL,0,maPeriod,0,maMethod,maPrice,i);
      int sum=0; 
      for (int k=0; k<size; k++) { double rsiValue = iRsi(getPrice(RsiPrice,i),periods[k],RsiMaMethod,i); }  
         rsiSum[i]   = maValue+(avgRange*(rsiValue-50)/100);
         LB[i]       = rsiSum[ArrayMinimum(rsiSum,HighLowPeriod,i)];
         HB[i]       = rsiSum[ArrayMaximum(rsiSum,HighLowPeriod,i)];
         rsiSumda[i] = EMPTY_VALUE;
         rsiSumdb[i] = EMPTY_VALUE;
         slope[i]    = slope[i+1];
         if (rsiSum[i]>rsiSum[i+1]) slope[i] = 1;
         if (rsiSum[i]<rsiSum[i+1]) slope[i] =-1;
         if (slope[i] == -1) PlotPoint(i,rsiSumda,rsiSumdb,rsiSum); 
         
         //
         //
         //
         //
         //
      
         if (!ShowZigZag) continue;
           ZZLow[i]  = 0;
           ZZHigh[i] = 0;
           if (LB[i] < LB[i+1])
           {
             if (ZZ[lastZag] == LB[lastZag])
               ZZ[lastZag]   =  0;
               ZZ[i]         =  LB[i];
               ZZLow[i]      =  LB[i];
                                lastZag = i;
                                continue;
           }   
           if (HB[i] > HB[i+1])
           {
             if (ZZ[lastZag] == HB[lastZag])
               ZZ[lastZag]   =  0;
               ZZ[i]         =  HB[i];
               ZZHigh[i]     =  HB[i];
                                lastZag = i;
                                continue;
           }   
           if (ZZ[i] != 0)
           {
             ZZ[i] = 0;
             for (lastZag=i+1; lastZag<Bars; lastZag++)
             {
                if (ZZLow[lastZag]  != 0) { ZZ[lastZag] = ZZLow[lastZag];  break; }
                if (ZZHigh[lastZag] != 0) { ZZ[lastZag] = ZZHigh[lastZag]; break; }
             }
               
           }          
      }
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
          first[i]    = from[i];
          first[i+1]  = from[i+1];
          second[i]   = EMPTY_VALUE;
         }
      else {
          second[i]   = from[i];
          second[i+1] = from[i+1];
          first[i]    = EMPTY_VALUE;
         }
      }
   else
      {
         first[i]   = from[i];
         second[i]  = EMPTY_VALUE;
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

double getPrice(int type, int i)
{
   switch (type)
   {
      case 7:     return((Open[i]+Close[i])/2.0);
      case 8:     return((Open[i]+High[i]+Low[i]+Close[i])/4.0);
      default :   return(iMA(NULL,0,1,0,MODE_SMA,type,i));
   }      
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//
//

double workRsi[][3];
#define _price  0
#define _change 1
#define _changa 2

double iRsi(double price, double period, int maMode, int i, int instanceNo=0)
{
   if (ArrayRange(workRsi,0)!=Bars) ArrayResize(workRsi,Bars);
      int z = instanceNo*3; 
      int r = Bars-i-1;
   
   //
   //
   //
   //
   //
   
   workRsi[r][z+_price] = price;
         double chng   = workRsi[r][_price]-workRsi[r-1][_price];
         double changn = iCustomMa(maMode,        chng ,period,i,instanceNo*2+0);
         double changa = iCustomMa(maMode,MathAbs(chng),period,i,instanceNo*2+1);
            if (changn != 0)
                  return(MathMin(MathMax(50.0*(changn/MathMax(changa,0.0000001)+1.0),0),100));
            else  return(50.0);
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

string methodNames[] = {"SMA","EMA","Double smoothed EMA","Double EMA","Triple EMA","Smoothed MA","Linear weighted MA","Parabolic weighted MA","Alexander MA","Volume weghted MA","Hull MA","Triangular MA","Sine weighted MA","Linear regression","IE/2","NonLag MA","Zero lag EMA","Leader EMA","Super smoother","Smoothed"};
string getAverageName(int& method)
{
   int max = ArraySize(methodNames)-1;
      method=MathMax(MathMin(method,max),0); return(methodNames[method]);
}

//
//
//
//
//

#define _maWorkBufferx1 2
#define _maWorkBufferx2 4
#define _maWorkBufferx3 6
#define _maWorkBufferx5 10

double iCustomMa(int mode, double price, double length, int i, int instanceNo=0)
{
   int r = Bars-i-1;
   switch (mode)
   {
      case 0  : return(iSma(price,length,r,instanceNo));
      case 1  : return(iEma(price,length,r,instanceNo));
      case 2  : return(iDsema(price,length,r,instanceNo));
      case 3  : return(iDema(price,length,r,instanceNo));
      case 4  : return(iTema(price,length,r,instanceNo));
      case 5  : return(iSmma(price,length,r,instanceNo));
      case 6  : return(iLwma(price,length,r,instanceNo));
      case 7  : return(iLwmp(price,length,r,instanceNo));
      case 8  : return(iAlex(price,length,r,instanceNo));
      case 9  : return(iWwma(price,length,r,instanceNo));
      case 10 : return(iHull(price,length,r,instanceNo));
      case 11 : return(iTma(price,length,r,instanceNo));
      case 12 : return(iSineWMA(price,length,r,instanceNo));
      case 13 : return(iLinr(price,length,r,instanceNo));
      case 14 : return(iIe2(price,length,r,instanceNo));
      case 15 : return(iNonLagMa(price,length,r,instanceNo));
      case 16 : return(iZeroLag(price,length,r,instanceNo));
      case 17 : return(iLeader(price,length,r,instanceNo));
      case 18 : return(iSsm(price,length,r,instanceNo));
      case 19 : return(iSmooth(price,length,r,instanceNo));
      default : return(0);
   }
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

double workSma[][_maWorkBufferx2];
double iSma(double price, int period, int r, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= Bars) ArrayResize(workSma,Bars); instanceNo *= 2;

   //
   //
   //
   //
   //
      
   workSma[r][instanceNo] = price;
   if (r>=period)
          workSma[r][instanceNo+1] = workSma[r-1][instanceNo+1]+(workSma[r][instanceNo]-workSma[r-period][instanceNo])/period;
   else { workSma[r][instanceNo+1] = 0; for(int k=0; k<period && (r-k)>=0; k++) workSma[r][instanceNo+1] += workSma[r-k][instanceNo];  
          workSma[r][instanceNo+1] /= k; }
   return(workSma[r][instanceNo+1]);
}

//
//
//
//
//

double workEma[][_maWorkBufferx1];
double iEma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= Bars) ArrayResize(workEma,Bars);

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//
//
//
//
//

double workDsema[][_maWorkBufferx2];
#define _ema1 0
#define _ema2 1

double iDsema(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workDsema,0)!= Bars) ArrayResize(workDsema,Bars); instanceNo*=2;

   //
   //
   //
   //
   //
      
   double alpha = 2.0 /(1.0+MathSqrt(period));
          workDsema[r][_ema1+instanceNo] = workDsema[r-1][_ema1+instanceNo]+alpha*(price                         -workDsema[r-1][_ema1+instanceNo]);
          workDsema[r][_ema2+instanceNo] = workDsema[r-1][_ema2+instanceNo]+alpha*(workDsema[r][_ema1+instanceNo]-workDsema[r-1][_ema2+instanceNo]);
   return(workDsema[r][_ema2+instanceNo]);
}

//
//
//
//
//

double workDema[][_maWorkBufferx2];
#define _dema1 0
#define _dema2 1

double iDema(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workDema,0)!= Bars) ArrayResize(workDema,Bars); instanceNo*=2;

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
          workDema[r][_dema1+instanceNo] = workDema[r-1][_dema1+instanceNo]+alpha*(price                         -workDema[r-1][_dema1+instanceNo]);
          workDema[r][_dema2+instanceNo] = workDema[r-1][_dema2+instanceNo]+alpha*(workDema[r][_dema1+instanceNo]-workDema[r-1][_dema2+instanceNo]);
   return(workDema[r][_dema1+instanceNo]*2.0-workDema[r][_dema2+instanceNo]);
}

//
//
//
//
//

double workTema[][_maWorkBufferx3];
#define _tema1 0
#define _tema2 1
#define _tema3 2

double iTema(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workTema,0)!= Bars) ArrayResize(workTema,Bars); instanceNo*=3;

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
          workTema[r][_tema1+instanceNo] = workTema[r-1][_tema1+instanceNo]+alpha*(price                         -workTema[r-1][_tema1+instanceNo]);
          workTema[r][_tema2+instanceNo] = workTema[r-1][_tema2+instanceNo]+alpha*(workTema[r][_tema1+instanceNo]-workTema[r-1][_tema2+instanceNo]);
          workTema[r][_tema3+instanceNo] = workTema[r-1][_tema3+instanceNo]+alpha*(workTema[r][_tema2+instanceNo]-workTema[r-1][_tema3+instanceNo]);
   return(workTema[r][_tema3+instanceNo]+3.0*(workTema[r][_tema1+instanceNo]-workTema[r][_tema2+instanceNo]));
}

//
//
//
//
//

double workSmma[][_maWorkBufferx1];
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

//
//
//
//
//

double workLwma[][_maWorkBufferx1];
double iLwma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLwma,0)!= Bars) ArrayResize(workLwma,Bars);
   
   //
   //
   //
   //
   //
   
   workLwma[r][instanceNo] = price;
      double sumw = period;
      double sum  = period*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k;
                sumw  += weight;
                sum   += weight*workLwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//

double workLwmp[][_maWorkBufferx1];
double iLwmp(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLwmp,0)!= Bars) ArrayResize(workLwmp,Bars);
   
   //
   //
   //
   //
   //
   
   workLwmp[r][instanceNo] = price;
      double sumw = period*period;
      double sum  = sumw*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = (period-k)*(period-k);
                sumw  += weight;
                sum   += weight*workLwmp[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//

double workAlex[][_maWorkBufferx1];
double iAlex(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workAlex,0)!= Bars) ArrayResize(workAlex,Bars);
   if (period<4) return(price);
   
   //
   //
   //
   //
   //

   workAlex[r][instanceNo] = price;
      double sumw = period-2;
      double sum  = sumw*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k-2;
                sumw  += weight;
                sum   += weight*workAlex[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//

double workTma[][_maWorkBufferx1];
double iTma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workTma,0)!= Bars) ArrayResize(workTma,Bars);
   
   //
   //
   //
   //
   //
   
   workTma[r][instanceNo] = price;

      double half = (period+1.0)/2.0;
      double sum  = price;
      double sumw = 1;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = k+1; if (weight > half) weight = period-k;
                sumw  += weight;
                sum   += weight*workTma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//

double workSineWMA[][_maWorkBufferx1];
#define Pi 3.14159265358979323846264338327950288

double iSineWMA(double price, int period, int r, int instanceNo=0)
{
   if (period<1) return(price);
   if (ArrayRange(workSineWMA,0)!= Bars) ArrayResize(workSineWMA,Bars);
   
   //
   //
   //
   //
   //
   
   workSineWMA[r][instanceNo] = price;
      double sum  = 0;
      double sumw = 0;
  
      for(int k=0; k<period && (r-k)>=0; k++)
      { 
         double weight = MathSin(Pi*(k+1.0)/(period+1.0));
                sumw  += weight;
                sum   += weight*workSineWMA[r-k][instanceNo]; 
      }
      return(sum/sumw);
}

//
//
//
//
//

double workWwma[][_maWorkBufferx1];
double iWwma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workWwma,0)!= Bars) ArrayResize(workWwma,Bars);
   
   //
   //
   //
   //
   //
   
   workWwma[r][instanceNo] = price;
      int    i    = Bars-r-1;
      double sumw = Volume[i];
      double sum  = sumw*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = Volume[i+k];
                sumw  += weight;
                sum   += weight*workWwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//

double workHull[][_maWorkBufferx2];
double iHull(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workHull,0)!= Bars) ArrayResize(workHull,Bars);

   //
   //
   //
   //
   //

      int HmaPeriod  = MathMax(period,2);
      int HalfPeriod = MathFloor(HmaPeriod/2);
      int HullPeriod = MathFloor(MathSqrt(HmaPeriod));
      double hma,hmw,weight; instanceNo *= 2;

         workHull[r][instanceNo] = price;

         //
         //
         //
         //
         //
               
         hmw = HalfPeriod; hma = hmw*price; 
            for(int k=1; k<HalfPeriod && (r-k)>=0; k++)
            {
               weight = HalfPeriod-k;
               hmw   += weight;
               hma   += weight*workHull[r-k][instanceNo];  
            }             
            workHull[r][instanceNo+1] = 2.0*hma/hmw;

         hmw = HmaPeriod; hma = hmw*price; 
            for(k=1; k<period && (r-k)>=0; k++)
            {
               weight = HmaPeriod-k;
               hmw   += weight;
               hma   += weight*workHull[r-k][instanceNo];
            }             
            workHull[r][instanceNo+1] -= hma/hmw;

         //
         //
         //
         //
         //
         
         hmw = HullPeriod; hma = hmw*workHull[r][instanceNo+1];
            for(k=1; k<HullPeriod && (r-k)>=0; k++)
            {
               weight = HullPeriod-k;
               hmw   += weight;
               hma   += weight*workHull[r-k][1+instanceNo];  
            }
   return(hma/hmw);
}

//
//
//
//
//

double workLinr[][_maWorkBufferx1];
double iLinr(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLinr,0)!= Bars) ArrayResize(workLinr,Bars);

   //
   //
   //
   //
   //
   
      period = MathMax(period,1);
      workLinr[r][instanceNo] = price;
         double lwmw = period; double lwma = lwmw*price;
         double sma  = price;
         for(int k=1; k<period && (r-k)>=0; k++)
         {
            double weight = period-k;
                   lwmw  += weight;
                   lwma  += weight*workLinr[r-k][instanceNo];  
                   sma   +=        workLinr[r-k][instanceNo];
         }             
   
   return(3.0*lwma/lwmw-2.0*sma/period);
}

//
//
//
//
//

double workIe2[][_maWorkBufferx1];
double iIe2(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workIe2,0)!= Bars) ArrayResize(workIe2,Bars);

   //
   //
   //
   //
   //
   
      period = MathMax(period,1);
      workIe2[r][instanceNo] = price;
         double sumx=0, sumxx=0, sumxy=0, sumy=0;
         for (int k=0; k<period; k++)
         {
            price = workIe2[r-k][instanceNo];
                   sumx  += k;
                   sumxx += k*k;
                   sumxy += k*price;
                   sumy  +=   price;
         }
         double tslope  = (period*sumxy - sumx*sumy)/(sumx*sumx-period*sumxx);
         double average = sumy/period;
   return(((average+tslope)+(sumy+tslope*sumx)/period)/2.0);
}

//
//
//
//
//

double workLeader[][_maWorkBufferx2];
double iLeader(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLeader,0)!= Bars) ArrayResize(workLeader,Bars); instanceNo*=2;

   //
   //
   //
   //
   //
   
      period = MathMax(period,1);
      double alpha = 2.0/(period+1.0);
         workLeader[r][instanceNo  ] = workLeader[r-1][instanceNo  ]+alpha*(price                          -workLeader[r-1][instanceNo  ]);
         workLeader[r][instanceNo+1] = workLeader[r-1][instanceNo+1]+alpha*(price-workLeader[r][instanceNo]-workLeader[r-1][instanceNo+1]);

   return(workLeader[r][instanceNo]+workLeader[r][instanceNo+1]);
}

//
//
//
//
//

double workZl[][_maWorkBufferx2];
#define _zlprice 0
#define _zlema 1

double iZeroLag(double price, double length, int r, int instanceNo=0)
{
   if (ArrayRange(workZl,0)!=Bars) ArrayResize(workZl,Bars); instanceNo *= 2;

   //
   //
   //
   //
   //

   double alpha = 2.0/(1.0+length); 
   int    per   = (length-1.0)/2.0; 

   workZl[r][_zlprice+instanceNo] = price;
   if (r<per)
          workZl[r][_zlema+instanceNo] = price;
   else   workZl[r][_zlema+instanceNo] = workZl[r-1][_zlema+instanceNo]+alpha*(2.0*price-workZl[r-per][_zlprice+instanceNo]-workZl[r-1][_zlema+instanceNo]);
   return(workZl[r][_zlema+instanceNo]);
}

//
//
//
//
//

double workSmooth[][_maWorkBufferx5];
double iSmooth(double price,int length,int r, int instanceNo=0)
{
   if (ArrayRange(workSmooth,0)!=Bars) ArrayResize(workSmooth,Bars); instanceNo *= 5;
 	if(r<=2) { workSmooth[r][instanceNo] = price; workSmooth[r][instanceNo+2] = price; workSmooth[r][instanceNo+4] = price; return(price); }
   
   //
   //
   //
   //
   //
   
	double alpha = 0.45*(length-1.0)/(0.45*(length-1.0)+2.0);
   	  workSmooth[r][instanceNo+0] =  price+alpha*(workSmooth[r-1][instanceNo]-price);
	     workSmooth[r][instanceNo+1] = (price - workSmooth[r][instanceNo])*(1-alpha)+alpha*workSmooth[r-1][instanceNo+1];
	     workSmooth[r][instanceNo+2] =  workSmooth[r][instanceNo+0] + workSmooth[r][instanceNo+1];
	     workSmooth[r][instanceNo+3] = (workSmooth[r][instanceNo+2] - workSmooth[r-1][instanceNo+4])*MathPow(1.0-alpha,2) + MathPow(alpha,2)*workSmooth[r-1][instanceNo+3];
	     workSmooth[r][instanceNo+4] =  workSmooth[r][instanceNo+3] + workSmooth[r-1][instanceNo+4]; 
   return(workSmooth[r][instanceNo+4]);
}

//
//
//
//
//

double workSsm[][_maWorkBufferx2];
#define _tprice  0
#define _ssm    1

double workSsmCoeffs[][4];
#define _period 0
#define _c1     1
#define _c2     2
#define _c3     3

//
//
//
//
//

double iSsm(double price, double period, int i, int instanceNo)
{
   if (ArrayRange(workSsm,0) !=Bars)                 ArrayResize(workSsm,Bars);
   if (ArrayRange(workSsmCoeffs,0) < (instanceNo+1)) ArrayResize(workSsmCoeffs,instanceNo+1);
   if (workSsmCoeffs[instanceNo][_period] != period)
   {
      workSsmCoeffs[instanceNo][_period] = period;
      double a1 = MathExp(-1.414*Pi/period);
      double b1 = 2.0*a1*MathCos(1.414*Pi/period);
         workSsmCoeffs[instanceNo][_c2] = b1;
         workSsmCoeffs[instanceNo][_c3] = -a1*a1;
         workSsmCoeffs[instanceNo][_c1] = 1.0 - workSsmCoeffs[instanceNo][_c2] - workSsmCoeffs[instanceNo][_c3];
   }

   //
   //
   //
   //
   //

      int s = instanceNo*2;   
          workSsm[i][s+_tprice] = price;
          workSsm[i][s+_ssm]    = workSsmCoeffs[instanceNo][_c1]*(workSsm[i][s+_tprice]+workSsm[i-1][s+_price])/2.0 + 
                                  workSsmCoeffs[instanceNo][_c2]*workSsm[i-1][s+_ssm]                               + 
                                  workSsmCoeffs[instanceNo][_c3]*workSsm[i-2][s+_ssm]; 
   return(workSsm[i][s+_ssm]);
}

//
//
//
//
//

#define _length  0
#define _len     1
#define _weight  2

double  nlmvalues[_maWorkBufferx1][3];
double  nlmprices[ ][_maWorkBufferx1];
double  nlmalphas[ ][_maWorkBufferx1];

//
//
//
//
//

double iNonLagMa(double price, double length, int r, int instanceNo=0)
{
   if (ArrayRange(nlmprices,0) != Bars)         ArrayResize(nlmprices,Bars);
   if (ArrayRange(nlmvalues,0) <  instanceNo+1) ArrayResize(nlmvalues,instanceNo+1);
                               nlmprices[r][instanceNo]=price;
   if (length<3 || r<3) return(nlmprices[r][instanceNo]);
   
   //
   //
   //
   //
   //
   
   if (nlmvalues[instanceNo][_length] != length  || ArraySize(nlmalphas)==0)
   {
      double Cycle = 4.0;
      double Coeff = 3.0*Pi;
      int    Phase = length-1;
      
         nlmvalues[instanceNo][_length] = length;
         nlmvalues[instanceNo][_len   ] = length*4 + Phase;  
         nlmvalues[instanceNo][_weight] = 0;

         if (ArrayRange(nlmalphas,0) < nlmvalues[instanceNo][_len]) ArrayResize(nlmalphas,nlmvalues[instanceNo][_len]);
         for (int k=0; k<nlmvalues[instanceNo][_len]; k++)
         {
            if (k<=Phase-1) 
                 double t = 1.0 * k/(Phase-1);
            else        t = 1.0 + (k-Phase+1)*(2.0*Cycle-1.0)/(Cycle*length-1.0); 
            double beta = MathCos(Pi*t);
            double g = 1.0/(Coeff*t+1); if (t <= 0.5 ) g = 1;
      
            nlmalphas[k][instanceNo]        = g * beta;
            nlmvalues[instanceNo][_weight] += nlmalphas[k][instanceNo];
         }
   }
   
   //
   //
   //
   //
   //
   
   if (nlmvalues[instanceNo][_weight]>0)
   {
      double sum = 0;
           for (k=0; k < nlmvalues[instanceNo][_len]; k++) sum += nlmalphas[k][instanceNo]*nlmprices[r-k][instanceNo];
           return( sum / nlmvalues[instanceNo][_weight]);
   }
   else return(0);           
}
