//+------------------------------------------------------------------+
//|                                                           rsioma |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers    4
#property indicator_color1     Lime
#property indicator_color2     Red
#property indicator_color3     Red
#property indicator_color4     White
#property indicator_width1     2
#property indicator_width2     2
#property indicator_width3     2
#property indicator_width4     2
#property indicator_levelcolor MediumOrchid

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

extern ENUM_TIMEFRAMES TimeFrame                = PERIOD_CURRENT;
extern int             RsiCmoPeriod             = 14;
extern int             SmoothPeriod             =  9;
extern enPrices        RsiCmoPrice              = 0;
extern int             MaPeriod                 = 10;
extern ENUM_MA_METHOD  MaType                   = MODE_LWMA;
extern bool            linesVisible             = false;
extern bool            linesOnFirst             = false;
extern string          linesID                  = "  rsi vida_nrp";
extern bool            linesOnRsiMaCross        = false;  
extern color           linesOnRsiMaCrossUpColor = Lime;
extern color           linesOnRsiMaCrossDnColor = Red;
extern ENUM_LINE_STYLE linesOnRsiMaCrossStyle   = STYLE_SOLID;
extern int             linesOnRsiMaCrossWidth   = 3;
extern bool            linesOnSlope             = false;  
extern color           linesOnSlopeUpColor      = Lime;
extern color           linesOnSlopeDnColor      = Red;
extern ENUM_LINE_STYLE linesOnSlopeStyle        = STYLE_SOLID;
extern int             linesOnSlopeWidth        = 3;
extern bool            alertsOn                 = false;
extern bool            alertsOnCurrent          = true;
extern bool            alertsMessage            = true;
extern bool            alertsSound              = false;
extern bool            alertsEmail              = false;
extern string          soundfile                = "alert2.wav";
extern bool            Interpolate              = true;
extern double          levelOb                  = 50;
extern double          levelOs                  = 50;


//
//
//
//
//

double rsi[];
double rsida[];
double rsidb[];
double ma[];
double mab[];
double trend[];
double slope[];
double prices[];

//
//
//
//
//

string shortName;
string indicatorFileName;
bool   returnBars;


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
  IndicatorBuffers(8);
    SetIndexBuffer(0,rsi);
    SetIndexBuffer(1,rsida);
    SetIndexBuffer(2,rsidb);
    SetIndexBuffer(3,ma);
    SetIndexBuffer(4,mab);
    SetIndexBuffer(5,trend);
    SetIndexBuffer(6,slope);
    SetIndexBuffer(7,prices);
    SetLevelValue(0,levelOs);
    SetLevelValue(1,levelOb);
    
       //
       //
       //
       //
       //
       
       shortName         = linesID+"  ("+RsiCmoPeriod+","+MaPeriod+")";
       indicatorFileName = WindowExpertName();
       returnBars        = (TimeFrame==-99);
       TimeFrame         = MathMax(TimeFrame,_Period);
       
 
   IndicatorShortName(linesID+"  ("+RsiCmoPeriod+","+MaPeriod+")");
return(0);
}
        
int deinit()
{
   string find = linesID+":";
   for (int i=ObjectsTotal()-1; i>= 0; i--)
   {
      string name = ObjectName(i); if (StringFind(name,find)==0) ObjectDelete(name);
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

int start()
{
   int counted_bars=IndicatorCounted();
   int i,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars-counted_bars,Bars-1);
         if (returnBars) { rsi[0] = limit+1; return(0); }

   //
   //
   //
   //
   //
   
   if (TimeFrame==Period())
   {
     int window = WindowFind(shortName);
     if  (slope[limit] == -1) CleanPoint(limit,rsida,rsidb);
     for (i=limit; i >= 0; i--) prices[i] = getPrice(RsiCmoPrice,Open,Close,High,Low,i);
     for (i=limit; i >= 0; i--) mab[i] = iVidya(prices[i],RsiCmoPeriod,SmoothPeriod,0,i);
     for (i=limit; i >= 0; i--) rsi[i] = iRSIOnArray(mab,0,RsiCmoPeriod,i);
     for (i=limit; i >= 0; i--)
     {
        ma[i] = iMAOnArray(rsi,0,MaPeriod,0,MaType,i);
        rsida[i] = EMPTY_VALUE;
        rsidb[i] = EMPTY_VALUE;
        slope[i] = slope[i+1];
        trend[i] = trend[i+1]; 
         
	     if (rsi[i] > rsi[i+1]) slope[i]= 1; 
	     if (rsi[i] < rsi[i+1]) slope[i]=-1;
	     if (rsi[i] > ma[i])    trend[i]= 1; 
	     if (rsi[i] < ma[i])    trend[i]=-1;
	     if (slope[i] == -1) PlotPoint(i,rsida,rsidb,rsi);
	     
	     if (linesVisible && window > -1)
        {
           string name = linesID+":"+Time[i];
           int    add  = 0; if (!linesOnFirst) add = _Period*60-1;
            ObjectDelete(name);
            if (linesOnRsiMaCross)
            {
              if (trend[i]!= trend[i+1])
              {
                 color theZColor  = linesOnRsiMaCrossUpColor; if (trend[i]==-1) theZColor = linesOnRsiMaCrossDnColor;
                    ObjectCreate(name,OBJ_VLINE,window,Time[i]+add,0);
                       ObjectSet(name,OBJPROP_WIDTH,linesOnRsiMaCrossWidth);
                       ObjectSet(name,OBJPROP_STYLE,linesOnRsiMaCrossStyle);
                       ObjectSet(name,OBJPROP_COLOR,theZColor);
              }
            }
            if (linesOnSlope)
            {
              if (slope[i]!= slope[i+1])
              {
                color theSColor  = linesOnSlopeUpColor; if (slope[i]==-1) theSColor = linesOnSlopeDnColor;
                    ObjectCreate(name,OBJ_VLINE,window,Time[i]+add,0);
                       ObjectSet(name,OBJPROP_WIDTH,linesOnSlopeWidth);
                       ObjectSet(name,OBJPROP_STYLE,linesOnSlopeStyle);
                       ObjectSet(name,OBJPROP_COLOR,theSColor);
              }
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
   
    limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/Period()));
    if (slope[limit]==-1) CleanPoint(limit,rsida,rsidb);
    for (i=limit;i>=0; i--)
    {
       int y = iBarShift(NULL,TimeFrame,Time[i]);
            rsi[i]   = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiCmoPeriod,SmoothPeriod,RsiCmoPrice,MaPeriod,MaType,linesVisible,linesOnFirst,linesID,linesOnRsiMaCross,linesOnRsiMaCrossUpColor,linesOnRsiMaCrossDnColor,linesOnRsiMaCrossStyle,linesOnRsiMaCrossWidth,linesOnSlope,linesOnSlopeUpColor,linesOnSlopeDnColor,linesOnSlopeStyle,linesOnSlopeWidth,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,soundfile,0,y);
            rsida[i] = EMPTY_VALUE;
            rsidb[i] = EMPTY_VALUE;
            ma[i]    = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiCmoPeriod,SmoothPeriod,RsiCmoPrice,MaPeriod,MaType,linesVisible,linesOnFirst,linesID,linesOnRsiMaCross,linesOnRsiMaCrossUpColor,linesOnRsiMaCrossDnColor,linesOnRsiMaCrossStyle,linesOnRsiMaCrossWidth,linesOnSlope,linesOnSlopeUpColor,linesOnSlopeDnColor,linesOnSlopeStyle,linesOnSlopeWidth,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,soundfile,3,y);
            trend[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiCmoPeriod,SmoothPeriod,RsiCmoPrice,MaPeriod,MaType,linesVisible,linesOnFirst,linesID,linesOnRsiMaCross,linesOnRsiMaCrossUpColor,linesOnRsiMaCrossDnColor,linesOnRsiMaCrossStyle,linesOnRsiMaCrossWidth,linesOnSlope,linesOnSlopeUpColor,linesOnSlopeDnColor,linesOnSlopeStyle,linesOnSlopeWidth,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,soundfile,5,y);
            slope[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiCmoPeriod,SmoothPeriod,RsiCmoPrice,MaPeriod,MaType,linesVisible,linesOnFirst,linesID,linesOnRsiMaCross,linesOnRsiMaCrossUpColor,linesOnRsiMaCrossDnColor,linesOnRsiMaCrossStyle,linesOnRsiMaCrossWidth,linesOnSlope,linesOnSlopeUpColor,linesOnSlopeDnColor,linesOnSlopeStyle,linesOnSlopeWidth,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,soundfile,6,y);  
            
            //
            //
            //
            //
            //
            
            if (!Interpolate || y==iBarShift(NULL,TimeFrame,Time[i-1])) continue;

            //
            //
            //
            //
            //

            datetime time = iTime(NULL,TimeFrame,y);
            for(int n = 1; i+n < Bars && Time[i+n] >= time; n++) continue;	
            for(int k = 1; k < n; k++) 
            {
               rsi[i+k] = rsi[i] + (rsi[i+n] - rsi[i])* k/n;
               ma[i+k]  = ma[i]  + (ma[i+n]  - ma[i]) * k/n;	
            }               
    } 
    for (i=limit;i>=0;i--) if (slope[i]==-1) PlotPoint(i,rsida,rsidb,rsi);
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

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

double  vidyawork[][2];
#define vidyaprice 0
#define vidyavalue 1

//
//
//
//
//

double iVidya(double price, int cmoPeriods, int smoothPeriods, int forCalculation, int i)
{
   if (ArrayRange(vidyawork,0)!=Bars) ArrayResize(vidyawork,Bars);
   
   int r = Bars-i-1;
   int s = forCalculation*2;
      double alpha = 2.00/(1.00+smoothPeriods);
   
      //
      //
      //
      //
      //
      
         vidyawork[r][s+vidyaprice] = price;
         
               double sumUp  = 0;
               double sumDo  = 0;
               for (int j=0; j < cmoPeriods; j++)
               {
                  double diff = Close[i+j]-Close[i+j+1];
                  if (diff > 0)
                        sumUp += diff;
                  else  sumDo -= diff;
               }      
               double k = 1; if ((sumUp+sumDo)!=0) k = MathAbs((sumUp-sumDo)/(sumUp+sumDo));
      
          vidyawork[r][s+vidyavalue] = k*alpha*vidyawork[r][s+vidyaprice] + (1.0-(k*alpha))*vidyawork[r-1][s+vidyavalue];
          
      //
      //
      //
      //
      //
                
   return(vidyawork[r][s+vidyavalue]);
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
  if (price>=pr_haclose && price<=pr_hatbiased)
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


//
//
//
//
//

void manageAlerts()
{
   if (alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1;
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar] == 1) doAlert(whichBar,"BUY");
         if (trend[whichBar] ==-1) doAlert(whichBar,"SELL");
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

       message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," - ",timeFrameToString(_Period)+" RSIOMA ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," rsioma "),message);
          if (alertsSound)   PlaySound(soundfile);
   }
}





