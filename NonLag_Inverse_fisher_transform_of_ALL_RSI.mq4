//+------------------------------------------------------------------+
//|                              Inverse fisher transform of RSI.mq4 |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property  copyright "mladen"
#property  link      "mladenfx@gmail.com"

#property  indicator_separate_window
#property  indicator_buffers    5
#property  indicator_color1     clrSilver
#property  indicator_color2     clrRed
#property  indicator_color3     clrRed
#property  indicator_color4     clrLime
#property  indicator_color5     clrLime
#property  indicator_width1     2
#property  indicator_width2     2
#property  indicator_width3     2
#property  indicator_width4     2
#property  indicator_width5     2
#property  indicator_maximum    1.05
#property  indicator_minimum   -1.05
#property  strict

//
//
//
//
//

enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_tbiased2,   // Trend biased (extreme) price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased,  // Heiken ashi trend biased price
   pr_hatbiased2  // Heiken ashi trend biased (extreme) price
};

enum enRsiTypes
{
   rsi_rsi,  // Regular RSI
   rsi_wil,  // Slow RSI
   rsi_rap,  // Rapid RSI
   rsi_har,  // Harris RSI
   rsi_rsx,  // RSX
   rsi_cut   // Cuttlers RSI
};

enum enColorOn
{
   cc_onSlope,   // Change color on slope change
   cc_onMiddle,  // Change color on middle line cross
   cc_onLevels   // Change color on outer levels cross
};

extern ENUM_TIMEFRAMES    TimeFrame   =  PERIOD_CURRENT; // Time frame
extern enRsiTypes         RsiType     =  rsi_rsx;        // RSI calculation method
extern int                Length      =  5;              // Period
extern enPrices           Price       =  pr_hatbiased2;  // Price
extern int                PriceSmooth =  0;              // Price smoothing period
extern int                NlLength    =  15;             // NonLag smoothing period
extern double             Level1      =  0.90;           // Level 1
extern double             Level2      =  0.0;            // Level 2
extern double             Level3      = -0.90;           // Level 3
extern enColorOn          colorOn     =  cc_onSlope;     // Color change on:
extern bool               Interpolate =  true;           // Interpolate in multi time frame mode

//
//
//
//
//

double ifishua[],ifishub[],ifishda[],ifishdb[],ifisher[],trend[],count[];
string indicatorFileName;
#define _mtfCall(_buff,_y) iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiType,Length,Price,PriceSmooth,NlLength,Level1,Level2,Level3,colorOn,_buff,_y)

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnInit()
{
   IndicatorBuffers(7);
      SetIndexBuffer(0,ifisher);
      SetIndexBuffer(1,ifishda);
      SetIndexBuffer(2,ifishdb);
      SetIndexBuffer(3,ifishua);
      SetIndexBuffer(4,ifishub);
      SetIndexBuffer(5,trend);
      SetIndexBuffer(6,count);
         SetLevelValue(0,Level1);
         SetLevelValue(1,Level2);
         SetLevelValue(2,Level3);

      //
      //
      //
      //
      //
      
      indicatorFileName = WindowExpertName();
      TimeFrame         = MathMax(TimeFrame,_Period);
   IndicatorShortName(timeFrameToString(TimeFrame)+" nonlag inverse fisher of "+getRsiName(RsiType)+" ("+(string)Length+","+(string)PriceSmooth+","+(string)NlLength+")");
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason) { return;}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnCalculate (const int       rates_total,
                 const int       prev_calculated,
                 const datetime& time[],
                 const double&   open[],
                 const double&   high[],
                 const double&   low[],
                 const double&   close[],
                 const long&     tick_volume[],
                 const long&     volume[],
                 const int&      spread[] )
{
   int limit=MathMax(rates_total-prev_calculated-1,0); count[0]=limit;
      if (TimeFrame!=_Period)
      {
         limit = (int)MathMax(limit,MathMin(rates_total-1,(_mtfCall(6,0)+1)*TimeFrame/_Period));
         if (trend[limit]== 1) CleanPoint(limit,ifishua,ifishub);
         if (trend[limit]==-1) CleanPoint(limit,ifishda,ifishdb);
         int i=limit; for (; i>=0 && !_StopFlag; i--)
         {
            int y = iBarShift(NULL,TimeFrame,time[i]);
               ifisher[i] = _mtfCall(0,y);
               trend[i]   = _mtfCall(5,y);
               ifishda[i] = EMPTY_VALUE; 
               ifishdb[i] = EMPTY_VALUE;         
               ifishua[i] = EMPTY_VALUE; 
               ifishub[i] = EMPTY_VALUE;         
               if (!Interpolate || (i>0 && y==iBarShift(NULL,TimeFrame,time[i-1]))) continue;
                  
               //
               //
               //
               //
               //
                  
               #define _interpolate(buff) buff[i+k] = buff[i]+(buff[i+n]-buff[i])*k/n
               int n,k; datetime ctime = iTime(NULL,TimeFrame,y);
                  for(n = 1; (i+n)<rates_total && time[i+n] >= ctime; n++) continue;	
                  for(k = 1; k<n && (i+n)<rates_total && (i+k)<rates_total; k++) _interpolate(ifisher);
         }
         for (i=limit; i>=0 && !_StopFlag; i--)
         {
            if (trend[i]== 1) PlotPoint(i,ifishua,ifishub,ifisher);
            if (trend[i]==-1) PlotPoint(i,ifishda,ifishdb,ifisher);
         }         
         return(rates_total-i-1);
      }               

   //
   //
   //
   //
   //
   
   if (trend[limit]== 1) CleanPoint(limit,ifishua,ifishub);
   if (trend[limit]==-1) CleanPoint(limit,ifishda,ifishdb);
   int i=limit; for(; i>=0 && !_StopFlag; i--)
   {
      double workPrice    = getPrice(Price,open,close,high,low,i,rates_total);
      double workNonLagMa = iNonLagMa(workPrice,PriceSmooth,i,rates_total,1);
      double avg = iNonLagMa(0.1 * (iRsi(RsiType,workNonLagMa,Length,i)-50),NlLength,i,rates_total,0);
         ifisher[i] = (MathExp(2*avg)-1)/(MathExp(2*avg)+1);
         trend[i]   = (i<rates_total-1) ? trend[i+1] : 0;
         
         switch(colorOn)
         {
            case cc_onLevels:
               if (ifisher[i] < Level1 && ifisher[i] > Level3) trend[i] =  0;
               if (ifisher[i] > Level1)                        trend[i] =  1;
               if (ifisher[i] < Level3)                        trend[i] = -1; break;
               
            case cc_onMiddle:         
               trend[i] = (ifisher[i]>Level2) ? 1 : (ifisher[i]<Level2) ? -1 : 0; break;
                            
            default :  
               if (i<Bars-1)
               trend[i] = (ifisher[i]>ifisher[i+1]) ? 1 : (ifisher[i]<ifisher[i+1]) ? -1 : 0; 
         }         

            
            //
            //
            //
            //
            //

            ifishda[i] = EMPTY_VALUE; ifishdb[i] = EMPTY_VALUE;         
            ifishua[i] = EMPTY_VALUE; ifishub[i] = EMPTY_VALUE;         
         if (trend[i]== 1) PlotPoint(i,ifishua,ifishub,ifisher);
         if (trend[i]==-1) PlotPoint(i,ifishda,ifishdb,ifisher);
   }
   return(rates_total-i-1);
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

string rsiMethodNames[] = {"rsi","slow rsi","rapid rsi","harris rsi","rsx","cuttler rsi"};
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

#define rsiInstances 2
double workRsi[][rsiInstances*13];
#define _price  0
#define _change 1
#define _changa 2
#define _rsival 1
#define _rsval  1

double iRsi(int rsiMode, double price, double period, int i, int instanceNo=0)
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
      case rsi_rsi:
         {
         double alpha = 1.0/MathMax(period,1); 
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
      
      case rsi_wil :
         {         
            double up = 0;
            double dn = 0;
            for(int k=0; k<(int)period && (r-k-1)>=0; k++)
            {
               double diff = workRsi[r-k][z+_price]- workRsi[r-k-1][z+_price];
               if(diff>0)
                     up += diff;
               else  dn -= diff;
            }
            if (r<1)
                  workRsi[r][z+_rsival] = 50;
            else               
               if(up + dn == 0)
                     workRsi[r][z+_rsival] = workRsi[r-1][z+_rsival]+(1/MathMax(period,1))*(50            -workRsi[r-1][z+_rsival]);
               else  workRsi[r][z+_rsival] = workRsi[r-1][z+_rsival]+(1/MathMax(period,1))*(100*up/(up+dn)-workRsi[r-1][z+_rsival]);
            return(workRsi[r][z+_rsival]);      
         }
      
      //
      //
      //
      //
      //

      case rsi_rap :
         {
            double up = 0;
            double dn = 0;
            for(int k=0; k<(int)period && (r-k-1)>=0; k++)
            {
               double diff = workRsi[r-k][z+_price]- workRsi[r-k-1][z+_price];
               if(diff>0)
                     up += diff;
               else  dn -= diff;
            }
            if(up + dn == 0)
                  return(50);
            else  return(100 * up / (up + dn));      
         }            

      //
      //
      //
      //
      //

      
      case rsi_har :
         {
            double avgUp=0,avgDn=0; double up=0; double dn=0;
            for(int k=0; k<(int)period && (r-k-1)>=0; k++)
            {
               double diff = workRsi[r-k][instanceNo+_price]- workRsi[r-k-1][instanceNo+_price];
               if(diff>0)
                     { avgUp += diff; up++; }
               else  { avgDn -= diff; dn++; }
            }
            if (up!=0) avgUp /= up;
            if (dn!=0) avgDn /= dn;
            double rs = 1;
               if (avgDn!=0) rs = avgUp/avgDn;
               return(100-100/(1.0+rs));
         }               

      //
      //
      //
      //
      //
      
      case rsi_rsx :  
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
            for (int k=0; k<3; k++)
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
      
      case rsi_cut :
         {
            double sump = 0;
            double sumn = 0;
            for (int k=0; k<(int)period && r-k-1>=0; k++)
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

#define _nlmInstances     2
#define _nlmInstancesSize 1
#define _length  0
#define _len     1
#define _weight  2

double  nlmvalues[ ][3];
double  nlmprices[ ][_nlmInstances*_nlmInstancesSize];
double  nlmalphas[ ][_nlmInstances*_nlmInstancesSize];

double iNonLagMa(double price, double length, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(nlmprices,0) != bars)         ArrayResize(nlmprices,bars);
   if (ArrayRange(nlmvalues,0) <  instanceNo+1) ArrayResize(nlmvalues,instanceNo+1); r=bars-r-1;
                               nlmprices[r][instanceNo]=price;
   if (length<5 || r<3) return(nlmprices[r][instanceNo]);
   
   //
   //
   //
   //
   //
   
   if (nlmvalues[instanceNo][_length] != length)
   {
      double Cycle = 4.0;
      double Coeff = 3.0*M_PI;
      int    Phase = (int)(length-1);
      
         nlmvalues[instanceNo][_length] =       length;
         nlmvalues[instanceNo][_len   ] = (int)(length*4) + Phase;  
         nlmvalues[instanceNo][_weight] = 0;

         if (ArrayRange(nlmalphas,0) < (int)nlmvalues[instanceNo][_len]) ArrayResize(nlmalphas,(int)nlmvalues[instanceNo][_len]);
         for (int k=0; k<(int)nlmvalues[instanceNo][_len]; k++)
         {
            double t;
            if (k<=Phase-1) 
                  t = 1.0 * k/(Phase-1);
            else  t = 1.0 + (k-Phase+1)*(2.0*Cycle-1.0)/(Cycle*length-1.0); 
            double beta = MathCos(M_PI*t);
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
           for (int k=0; k < (int)nlmvalues[instanceNo][_len] && (r-k)>=0; k++) sum += nlmalphas[k][instanceNo]*nlmprices[r-k][instanceNo];
           return( sum / nlmvalues[instanceNo][_weight]);
   }
   else return(0);           
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
   if (i>=Bars-2) return;
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
            { first[i]  = from[i]; first[i+1]  = from[i+1]; second[i] = EMPTY_VALUE; }
      else  { second[i] = from[i]; second[i+1] = from[i+1]; first[i]  = EMPTY_VALUE; }
   else     { first[i]  = from[i];                          second[i] = EMPTY_VALUE; }
}

//
//
//
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
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

#define _priceInstances     1
#define _priceInstancesSize 4
double workHa[][_priceInstances*_priceInstancesSize];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i, int bars, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= bars) ArrayResize(workHa,bars); instanceNo*=_priceInstancesSize; int r = bars-i-1;
         
         //
         //
         //
         //
         //
         
         double haOpen;
         if (r>0)
                haOpen  = (workHa[r-1][instanceNo+2] + workHa[r-1][instanceNo+3])/2.0;
         else   haOpen  = (open[i]+close[i])/2;
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[r][instanceNo+0] = haLow;  workHa[r][instanceNo+1] = haHigh; } 
         else                 { workHa[r][instanceNo+0] = haHigh; workHa[r][instanceNo+1] = haLow;  } 
                                workHa[r][instanceNo+2] = haOpen;
                                workHa[r][instanceNo+3] = haClose;
         //
         //
         //
         //
         //
         
         switch (tprice)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
            case pr_hatbiased2:
               if (haClose>haOpen)  return(haHigh);
               if (haClose<haOpen)  return(haLow);
                                    return(haClose);        
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (tprice)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_medianb:   return((open[i]+close[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
      case pr_tbiased:   
               if (close[i]>open[i])
                     return((high[i]+close[i])/2.0);
               else  return((low[i]+close[i])/2.0);        
      case pr_tbiased2:   
               if (close[i]>open[i]) return(high[i]);
               if (close[i]<open[i]) return(low[i]);
                                     return(close[i]);        
   }
   return(0);
}   