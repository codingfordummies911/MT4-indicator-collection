//+------------------------------------------------------------------
//|
//+------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_color1  clrDodgerBlue
#property indicator_color2  clrSandyBrown
#property indicator_color3  clrSandyBrown
#property indicator_color4  clrDeepSkyBlue  
#property indicator_color5  clrDimGray
#property indicator_color6  clrSandyBrown
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_style4  STYLE_DOT
#property indicator_style5  STYLE_DOT
#property indicator_style6  STYLE_DOT
#property strict

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
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased   // Heiken ashi trend biased price
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
enum colorOn
{
   clrOnSlope, // Color change on slope change
   clrOnZero,  // Color change on zero cross
   clrOnlevel  // Color change on levels cross
};


extern ENUM_TIMEFRAMES TimeFrame        = PERIOD_CURRENT;    // Time frame to use
extern int             RsiPeriod        = 14;                // Rsi period
extern enRsiTypes      RsiType          = rsi_rsx;           // Rsi type
extern int             GaussPeriod      = 32;                // Gaussian period
extern int             GaussOrder       = 2;                 // Gaussian order
extern enPrices        GaussPrice       = pr_close;          // Price to use
extern int             MinMaxPeriod     = 35;                // Floating levels period
extern double          LevelUp          = 90;                // Floating levels up
extern double          LevelDown        = 10;                // Floating levels down
extern colorOn         ColorChangeOn    = clrOnSlope;        // Color change on : 
extern bool            alertsOn         = false;             // Turn alerts on
extern bool            alertsOnCurrent  = false;             // Alerts on current (still opened) bar?
extern bool            alertsMessage    = true;              // Alerts should display a pop-up message
extern bool            alertsSound      = true;              // Alerts should play an alert sound?
extern bool            alertsEmail      = false;             // Alerts should send an email?
extern bool            arrowsVisible    = false;             // Arrows visible?
extern bool            arrowsOnNewest   = false;             // Arrows drawn on newst bar of higher time frame bar?
extern string          arrowsIdentifier = "rsikama Arrows1"; // Unique ID for arrows
extern double          arrowsUpperGap   = 1.0;               // Upper arrow gap
extern double          arrowsLowerGap   = 1.0;               // Lower arrow gap
extern color           arrowsUpColor    = clrLimeGreen;      // Up arrow color
extern color           arrowsDnColor    = clrOrange;         // Down arrow color
extern int             arrowsUpCode     = 241;               // Up arrow code
extern int             arrowsDnCode     = 242;               // Down arrow code
extern int             arrowsSize       = 0;                 // Arrows size
extern bool            Interpolate      = true;

//
//
//
//
//

double rsiLUp[];
double rsiLMi[];
double rsiLDn[];
double rsi[];
double rsiUpa[];
double rsiUpb[];
double rsiDna[];
double rsiDnb[];
double trend[];
double trenc[];
string indicatorFileName;
bool   returnBars;

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
   IndicatorBuffers(7);
   SetIndexBuffer(0,rsi,   INDICATOR_DATA);
   SetIndexBuffer(1,rsiDna,INDICATOR_DATA);
   SetIndexBuffer(2,rsiDnb,INDICATOR_DATA);
   SetIndexBuffer(3,rsiLUp,INDICATOR_DATA);
   SetIndexBuffer(4,rsiLMi,INDICATOR_DATA);
   SetIndexBuffer(5,rsiLDn,INDICATOR_DATA);
   SetIndexBuffer(6,trend ,INDICATOR_CALCULATIONS);
   
      indicatorFileName = WindowExpertName();
      returnBars        = TimeFrame==-99;
      TimeFrame         = MathMax(TimeFrame,_Period);
   
      IndicatorShortName(timeFrameToString(TimeFrame)+"  "+getRsiName((int)RsiType)+" of gaussian filter ("+(string)RsiPeriod+")");
   return(0);
}
int deinit()
{
   string lookFor       = arrowsIdentifier+":";
   int    lookForLength = StringLen(lookFor);
   for (int i=ObjectsTotal()-1; i>=0; i--)
   {
      string objectName = ObjectName(i);
         if (StringSubstr(objectName,0,lookForLength) == lookFor) ObjectDelete(objectName);
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

double work[][2];
#define _lastLo 0
#define _lastHi 1

int start()
{
   int i,limit,counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars-counted_bars,Bars-1);
         if (returnBars) { rsi[0] = limit+1; return(0); }
         if (ArrayRange(work,0)!=Bars) ArrayResize(work,Bars);

   //
   //
   //
   //
   //

   if (TimeFrame == Period())
   { 
      if (trend[limit] ==-1) CleanPoint(limit,rsiDna,rsiDnb);
      for(i=limit; i>=0; i--)
      {
            rsi[i] = iRsi(RsiType,iGFilter(getPrice(GaussPrice,Open,Close,High,Low,i),GaussPeriod,GaussOrder,i),RsiPeriod,i);
           
            //
            //
            //
            //
            //
                   
            double rsiMin = rsi[ArrayMinimum(rsi,MinMaxPeriod,i)];
            double rsiMax = rsi[ArrayMaximum(rsi,MinMaxPeriod,i)];
            double range  = rsiMax-rsiMin;
               rsiLDn[i]  = rsiMin+range*LevelDown/100.0;
               rsiLMi[i]  = rsiMin+range*0.5;
               rsiLUp[i]  = rsiMin+range*LevelUp/100.0;
               
               rsiDna[i] = EMPTY_VALUE;
               rsiDnb[i] = EMPTY_VALUE;
               if (i<Bars-1) trend[i] = trend[i+1];
               switch (ColorChangeOn)
               {
                  case clrOnSlope: 
                     if (i<Bars-1)
                     {
                        if (rsi[i]>rsi[i+1])    trend[i] =  1;
                        if (rsi[i]<rsi[i+1])    trend[i] = -1;
                     }                        
                     break;
                  case clrOnZero: 
                     if (rsi[i]>rsiLMi[i])   trend[i] =  1;
                     if (rsi[i]<rsiLMi[i])   trend[i] = -1;
                     break;
                  default : 
                     if (rsi[i]>rsiLUp[i])   trend[i] =  1;
                     if (rsi[i]<rsiLDn[i])   trend[i] = -1;
                     break;
               }    
               if (trend[i] == -1) PlotPoint(i,rsiDna,rsiDnb,rsi);
               
               //
               //
               //
               //
               //
               
               if (arrowsVisible)
               {
                 string lookFor = arrowsIdentifier+":"+(string)Time[i]; ObjectDelete(lookFor);            
                     if ((i<Bars-1) && trend[i] != trend[i+1])
                     {
                        if (trend[i] == 1) drawArrow(i,arrowsUpColor,arrowsUpCode,false);
                        if (trend[i] ==-1) drawArrow(i,arrowsDnColor,arrowsDnCode, true);
                     }
               }
      }      
      manageAlerts();
      return(0);
   }
   
   //
   //
   //
   //
   //
   
   limit = (int)MathMax(limit,MathMin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/Period()));
   if (trend[limit] ==-1) CleanPoint(limit,rsiDna,rsiDnb);
   for (i=limit;i>=0;i--)
   {
      int y = iBarShift(NULL,TimeFrame,Time[i]);
         rsi   [i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPeriod,RsiType,GaussPeriod,GaussOrder,GaussPrice,MinMaxPeriod,LevelUp,LevelDown,ColorChangeOn,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,arrowsVisible,arrowsOnNewest,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,0,y); 
         rsiLUp[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPeriod,RsiType,GaussPeriod,GaussOrder,GaussPrice,MinMaxPeriod,LevelUp,LevelDown,ColorChangeOn,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,arrowsVisible,arrowsOnNewest,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,3,y);
         rsiLMi[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPeriod,RsiType,GaussPeriod,GaussOrder,GaussPrice,MinMaxPeriod,LevelUp,LevelDown,ColorChangeOn,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,arrowsVisible,arrowsOnNewest,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,4,y);
         rsiLDn[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPeriod,RsiType,GaussPeriod,GaussOrder,GaussPrice,MinMaxPeriod,LevelUp,LevelDown,ColorChangeOn,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,arrowsVisible,arrowsOnNewest,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,5,y);
         trend[i]  = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPeriod,RsiType,GaussPeriod,GaussOrder,GaussPrice,MinMaxPeriod,LevelUp,LevelDown,ColorChangeOn,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,arrowsVisible,arrowsOnNewest,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,6,y); 
         rsiDna[i] = EMPTY_VALUE;
         rsiDnb[i] = EMPTY_VALUE;
         
         //
         //
         //
         //
         //
      
         if (!Interpolate || (i>0 && y==iBarShift(NULL,TimeFrame,Time[i-1]))) continue;
                  
         //
         //
         //
         //
         //
                  
         int n,j; datetime time = iTime(NULL,TimeFrame,y);
            for(n = 1; (i+n)<Bars && Time[i+n] >= time; n++) continue;	
            for(j = 1; j<n && (i+n)<Bars && (i+j)<Bars; j++)
            {
               rsi[i+j]    = rsi[i]    + (rsi[i+n]    - rsi[i]   )*j/n;
               rsiLUp[i+j] = rsiLUp[i] + (rsiLUp[i+n] - rsiLUp[i])*j/n;
               rsiLMi[i+j] = rsiLMi[i] + (rsiLMi[i+n] - rsiLMi[i])*j/n;
               rsiLDn[i+j] = rsiLDn[i] + (rsiLDn[i+n] - rsiLDn[i])*j/n;
            }
            
   }
   for (i=limit;i>=0;i--) if (trend[i] ==-1)PlotPoint(i,rsiDna,rsiDnb,rsi);           
   return(0);       
}


//-------------------------------------------------------------------
//                                                                  
//-------------------------------------------------------------------
//
//
//
//
//

void manageAlerts()
{
   if (alertsOn)
   {
      int whichBar = 1; if (alertsOnCurrent) whichBar = 0;
      if (trend[whichBar] != trend[whichBar+1])
      {
         switch (ColorChangeOn)
         {
            case clrOnSlope: 
               if (trend[whichBar]== 1) doAlert(whichBar,"slope changed to up");
               if (trend[whichBar]==-1) doAlert(whichBar,"slope changed to down");
               break;
            case clrOnZero: 
               if (trend[whichBar]== 1) doAlert(whichBar,"zero crossed up");
               if (trend[whichBar]==-1) doAlert(whichBar,"zero crossed down");
               break;
            default : 
               if (trend[whichBar]== 1) doAlert(whichBar,"upper level crossed up");
               if (trend[whichBar]==-1) doAlert(whichBar,"lower level crossed down");
         }    
      }
   }
}

//
//
//
//
//

void doAlert(int forBar, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[forBar]) {
       previousAlert  = doWhat;
       previousTime   = Time[forBar];

       //
       //
       //
       //
       //

       message = timeFrameToString(_Period)+" "+Symbol()+" at "+TimeToStr(TimeLocal(),TIME_SECONDS)+" rsi of gaussian filter "+doWhat;
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(Symbol()+" rsi of gaussian filter ",message);
          if (alertsSound)   PlaySound("alert2.wav");
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

string rsiMethodNames[] = {"RSI","Slow RSI","Rapid RSI","Harris RSI","RSX","Cuttler RSI"};
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

#define rsiInstances 1
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

#define Pi 3.141592653589793238462643

int    periods[3];
double coeffs[][9];
double filters[][3];
double iGFilter(double price, int period, int order, int i, int instanceNo=0)
{
   if (ArrayRange(filters,0)!=Bars)  ArrayResize(filters,Bars);
   if (ArrayRange(coeffs,0)<order+1) ArrayResize(coeffs,order+1);
   if (periods[instanceNo]!=period)
   {
      periods[instanceNo]=period;
         double b = (1.0 - MathCos(2.0*Pi/period))/(MathPow(MathSqrt(2.0),2.0/order) - 1.0);
         double a = -b + MathSqrt(b*b + 2.0*b);
         for(int r=0; r<=order; r++)
         {
             coeffs[r][instanceNo*3+0] = fact(order)/(fact(order-r)*fact(r));
             coeffs[r][instanceNo*3+1] = MathPow(    a,r);
             coeffs[r][instanceNo*3+2] = MathPow(1.0-a,r);
         }
   }

   //
   //
   //
   //
   //
   
   i = Bars-i-1;
   filters[i][instanceNo] = price*coeffs[order][instanceNo*3+1];
      double sign = 1;
         for (int r=1; r <= order &&i-r>=0; r++, sign *= -1.0)
                  filters[i][instanceNo] += sign*coeffs[r][instanceNo*3+0]*coeffs[r][instanceNo*3+2]*filters[i-r][instanceNo];
   return(filters[i][instanceNo]);
}

//
//
//
//
//

double fact(int n)
{
   double a=1;
         for(int i=1; i<=n; i++) a*=i;
   return(a);
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

double workHa[][4];
double getPrice(int price, const double& open[], const double& close[], const double& high[], const double& low[], int i, int instanceNo=0)
{
  if (price>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= Bars) ArrayResize(workHa,Bars);
         int r = Bars-i-1;
         
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
         
         switch (price)
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
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (price)
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
   }
   return(0);
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

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
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

//-------------------------------------------------------------------
//                                                                  
//-------------------------------------------------------------------
//
//
//
//
//

void drawArrow(int i,color theColor,int theCode,bool up)
{
   string name = arrowsIdentifier+":"+(string)Time[i];
   double gap  = iATR(NULL,0,20,i);   
   
      //
      //
      //
      //
      //

      datetime time = Time[i]; if (arrowsOnNewest) time += _Period*60-1;      
      ObjectCreate(name,OBJ_ARROW,0,time,0);
         ObjectSet(name,OBJPROP_ARROWCODE,theCode);
         ObjectSet(name,OBJPROP_WIDTH,arrowsSize);
         ObjectSet(name,OBJPROP_COLOR,theColor);
         if (up)
               ObjectSet(name,OBJPROP_PRICE1,High[i] + arrowsUpperGap * gap);
         else  ObjectSet(name,OBJPROP_PRICE1,Low[i]  - arrowsLowerGap * gap);
}