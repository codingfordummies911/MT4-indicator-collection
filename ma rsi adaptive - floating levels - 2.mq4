//+------------------------------------------------------------------
//|
//+------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_color1  clrDeepSkyBlue  
#property indicator_color2  clrDimGray
#property indicator_color3  clrPaleVioletRed
#property indicator_color4  clrDeepSkyBlue
#property indicator_color5  clrSandyBrown
#property indicator_color6 clrSandyBrown
#property indicator_width4  2
#property indicator_width5  2
#property indicator_width6  2
#property indicator_style1  STYLE_DOT
#property indicator_style2  STYLE_DOT
#property indicator_style3  STYLE_DOT
#property strict

//
//
//
//
//

enum enRsiMethod
{
   rsi_rsi, // Classical RSI
   rsi_slw, // Slow RSI
   rsi_rsx, // RSX
   rsi_cut  // Cuttler RSi
};
extern int         RsiPeriod    =   14;        // Rsi period
extern int         RsiPrice     = PRICE_CLOSE; // Price to use
extern enRsiMethod RsiMethod    = 0;           // Rsi method
extern int         MinMaxPeriod =  100;        // Floating levels period
extern double      LevelUp      = 76.4;        // Level up
extern double      LevelDown    = 23.6;        // Level down

//
//
//
//
//

double rsiMin[];
double rsiMax[];
double rsiLUp[];
double rsiLMi[];
double rsiLDn[];
double rsi[],rsiDa[],rsiDb[],slope[];
double gap[];

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
// 
//
//
//
//

int init()
{
   IndicatorBuffers(10);
   SetIndexBuffer(0,rsiLUp);
   SetIndexBuffer(1,rsiLMi);
   SetIndexBuffer(2,rsiLDn);
   SetIndexBuffer(3,rsi);
   SetIndexBuffer(4,rsiDa);
   SetIndexBuffer(5,rsiDb);
   SetIndexBuffer(6,rsiMin);
   SetIndexBuffer(7,rsiMax);
   SetIndexBuffer(8,gap);
   SetIndexBuffer(9,slope);
      IndicatorShortName("ma "+getRsiName(RsiMethod)+" adaptive("+(string)RsiPeriod+","+DoubleToStr(LevelDown,2)+","+DoubleToStr(LevelUp,2)+")");
   return(0);
}
int deinit() { return(0); }


//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//

int start()
{
   int i,limit,counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars-counted_bars,Bars-1);

   //
   //
   //
   //
   //

   if (slope[limit] == 1) CleanPoint(limit,rsiDa,rsiDb);
   for(i=limit; i>=0; i--) 
   {
      double price = iMA(NULL,0,1,0,MODE_SMA,RsiPrice,i);
         if (i>Bars-RsiPeriod)
               rsi[i]   = price;
         else  rsi[i]   = rsi[i+1]+(2.0*MathAbs(iRsi(price,RsiPeriod,i,0,RsiMethod)/100.0-0.5))*(price-rsi[i+1]);
               rsiDa[i] = EMPTY_VALUE;
               rsiDb[i] = EMPTY_VALUE;
         if (i<Bars-1) 
         {
            slope[i] = slope[i+1];
            if (rsi[i]>rsi[i+1]) slope[i] =  1;
            if (rsi[i]<rsi[i+1]) slope[i] = -1;
            if (slope[i]==-1) PlotPoint(i,rsiDa,rsiDb,rsi);

         //
         //
         //
         //
         //
         
            gap[i] = 0;
               if (High[i]<Low[i+1]) gap[i] = High[i]-Low[i+1];
               if (Low[i]>High[i+1]) gap[i] = Low[i]-High[i+1];
      
                  double displaceup = 0;
                  double displacedn = 0;
                  double max        = rsi[i];
                  double min        = rsi[i];
                  for (int k=0; k<MinMaxPeriod && (i+k)<Bars; k++)
                  {
                     if (gap[i+k]<0) displacedn += gap[i+k];
                     if (gap[i+k]>0) displaceup += gap[i+k];
                     if ((rsi[i+k]+displaceup) < min) min = rsi[i+k]+displacedn;
                     if ((rsi[i+k]+displacedn) > max) max = rsi[i+k]+displacedn;
                  }
            rsiMin[i] = min;
            rsiMax[i] = max;
         }  
      
         //
         //
         //
         //
         //
                   
         double range = rsiMax[i]-rsiMin[i];
            rsiLDn[i] = rsiMin[i]+range*LevelDown/100.0;
            rsiLMi[i] = rsiMin[i]+range*0.5;
            rsiLUp[i] = rsiMin[i]+range*LevelUp/100.0;
   }      
   return(0);
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

string rsiMethodNames[] = {"rsi","Slow rsi","rsx","Cuttler RSI"};
string getRsiName(int method)
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
         {
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
         }
         
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
         {   
         double Kg = (3.0)/(2.0+period), Hg = 1.0-Kg;
         if (r<period) { for (int k=1; k<13; k++) workRsi[r][k+z] = 0; return(50); }  

         //
         //
         //
         //
         //
      
         double mom = workRsi[r][_price+z]-workRsi[r-1][_price+z];
         double moa = MathAbs(mom);
         for (int k=0; k<3 && r>0; k++)
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
         }
            
      //
      //
      //
      //
      //
      
      case 3 :
         {
         double sump = 0;
         double sumn = 0;
         for (int k=0; k<period && (r-k-1)>=0; k++)
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
   return(50);
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
   if (i>=Bars-3) return;
   if ((second[i]  != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
        second[i+1] = EMPTY_VALUE;
   else
      if ((first[i] != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
          first[i+1] = EMPTY_VALUE;
}

void PlotPoint(int i,double& first[],double& second[],double& from[])
{
   if (i>=Bars-2) return;
   if (first[i+1] == EMPTY_VALUE)
      if (first[i+2] == EMPTY_VALUE) 
            { first[i]  = from[i];  first[i+1]  = from[i+1]; second[i] = EMPTY_VALUE; }
      else  { second[i] =  from[i]; second[i+1] = from[i+1]; first[i]  = EMPTY_VALUE; }
   else     { first[i]  = from[i];                           second[i] = EMPTY_VALUE; }
}