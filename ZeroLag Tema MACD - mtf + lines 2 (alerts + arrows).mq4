//------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-tsd.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 LimeGreen
#property indicator_color2 DarkOrange
#property indicator_color3 DarkOrange
#property indicator_color4 Yellow
#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 2
#property indicator_style4 STYLE_DOT
#property indicator_level1 0

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
   pr_ha          // Heiken-ashi
};

#define PRICE_HA 7
extern ENUM_TIMEFRAMES TimeFrame          = PERIOD_CURRENT;
extern int             FastPeriod         = 24;
extern int             SlowPeriod         = 52;
extern int             SignalPeriod       =  9;
extern enPrices        Price              = PRICE_HA;
extern int             PricePreSmooth     = 1;
extern bool            ColorOnSignalCross = true;
extern bool            LinesVisible       = false;
extern string          LinesID            = "ZL TEMA macd";
extern color           LinesUpColor       = LimeGreen;
extern color           LinesDnColor       = OrangeRed;
extern ENUM_LINE_STYLE LinesStyle         = STYLE_SOLID;
extern int             LinesWidth         = 0;
extern bool            arrowsVisible      = true;             // Arrows visible?
extern bool            arrowsOnFirst      = false;            // Arrows shift?
extern string          arrowsIdentifier   = "zlmacd Arrows1"; // Unique ID for arrows
extern double          arrowsUpperGap     = 1.0;              // Upper arrow gap
extern double          arrowsLowerGap     = 1.0;              // Lower arrow gap
extern color           arrowsUpColor      = clrDeepSkyBlue;   // Up arrow color
extern color           arrowsDnColor      = clrPaleVioletRed; // Down arrow color
extern int             arrowsUpCode       = 139;              // Up arrow code
extern int             arrowsDnCode       = 139;              // Down arrow code
extern bool            alertsOn           = false;            // Turn alerts on?
extern bool            alertsOnCurrent    = false;            // Alerts on still opened bar?
extern bool            alertsMessage      = true;             // Alerts should display message?
extern bool            alertsSound        = false;            // Alerts should play a sound?
extern bool            alertsNotify       = false;            // Alerts should send a notification?
extern bool            alertsEmail        = false;            // Alerts should send an email?
extern string          soundFile          = "alert2.wav";     // Sound file

double macd[];
double macdda[];
double macddb[];
double signal[];
double mcolor[];

string shortName;
string indicatorFileName;
bool   returnBars;

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
   IndicatorBuffers(5);
   SetIndexBuffer(0,macd); 
   SetIndexBuffer(1,macdda); 
   SetIndexBuffer(2,macddb); 
   SetIndexBuffer(3,signal); 
   SetIndexBuffer(4,mcolor); 
      shortName         = LinesID+" ("+FastPeriod+","+SlowPeriod+","+SignalPeriod+")";
      indicatorFileName = WindowExpertName();
      returnBars        = TimeFrame == -99;
      TimeFrame         = MathMax(TimeFrame,_Period);
   IndicatorShortName(shortName);
   return(0);
}
int deinit()
{
   string find = LinesID+":";
   for (int i=ObjectsTotal()-1; i>= 0; i--)
   {
      string name = ObjectName(i); if (StringFind(name,find)==0) ObjectDelete(name);
   }
   string lookFor       = arrowsIdentifier+":";
   int    lookForLength = StringLen(lookFor);
   for (i=ObjectsTotal()-1; i>=0; i--)
   {
      string objectName = ObjectName(i);
         if (StringSubstr(objectName,0,lookForLength) == lookFor) ObjectDelete(objectName);
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

int start()
{
   int counted_bars = IndicatorCounted();
      if(counted_bars < 0) return(-1);
      if(counted_bars > 0) counted_bars--;
           int limit = MathMin(Bars-counted_bars,Bars-1);
           if (returnBars) { macd[0] = limit+1; return(0); }
           int window = WindowFind(shortName);
   
   //
   //
   //
   //
   //
   
   if (TimeFrame == Period())
   {
      double alpha = 2.0/(SignalPeriod+1);
      if (mcolor[limit]==-1) CleanPoint(limit,macdda,macddb);
      for (int i=limit; i>=0; i--)
      {  
         double tema1 = ihTema(i,FastPeriod,Price,PricePreSmooth,0); double fast = tema1+(tema1-iTema(tema1,FastPeriod,i,0));
         double tema2 = ihTema(i,SlowPeriod,Price,PricePreSmooth,1); double slow = tema2+(tema2-iTema(tema2,SlowPeriod,i,1));
            macd[i]   = fast-slow;
            signal[i] = signal[i+1]+alpha*(macd[i]-signal[i+1]);
            macdda[i] = EMPTY_VALUE;
            macddb[i] = EMPTY_VALUE;
            mcolor[i] = mcolor[i+1];
            if (ColorOnSignalCross)
            {
               if (macd[i]>signal[i]) mcolor[i] =  1;
               if (macd[i]<signal[i]) mcolor[i] = -1;
            }
            else
            {
               if (macd[i]>macd[i+1]) mcolor[i] =  1;
               if (macd[i]<macd[i+1]) mcolor[i] = -1;
            }               
            if (mcolor[i]==-1) PlotPoint(i,macdda,macddb,macd);
            
            //
            //
            //
            //
            //
       
            if (arrowsVisible)
            {
               string lookFor = arrowsIdentifier+":"+(string)Time[i]; ObjectDelete(lookFor);            
                  if (i<Bars-1 && mcolor[i] != mcolor[i+1])
                  {
                     if (mcolor[i] == 1) drawArrow(i,arrowsUpColor,arrowsUpCode,false);
                     if (mcolor[i] ==-1) drawArrow(i,arrowsDnColor,arrowsDnCode, true);
                  }
             }
            
            //
            //
            //
            //
            //
            
            if (LinesVisible && window>-1)
 	         {
 	          string name = LinesID+":"+Time[i];
 	             ObjectDelete(name);
 	             if (mcolor[i]!=mcolor[i+1])
 	             {
 	                color theColor  = LinesUpColor; if (mcolor[i]==-1) theColor = LinesDnColor;
 	                   ObjectCreate(name,OBJ_VLINE,window,Time[i],0);
 	                      ObjectSet(name,OBJPROP_WIDTH,LinesWidth);
 	                      ObjectSet(name,OBJPROP_STYLE,LinesStyle);
 	                      ObjectSet(name,OBJPROP_COLOR,theColor);
 	             }
 	       }
      } 
      if (alertsOn)
      {
         int whichBar = 1; if (alertsOnCurrent) whichBar = 0; 
         if (mcolor[whichBar] != mcolor[whichBar+1])
         {
            if (mcolor[whichBar] == 1) doAlert(" up");
            if (mcolor[whichBar] ==-1) doAlert(" down");       
         }         
      }          
      return(0);
   }
   
   //
   //
   //
   //
   //

   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/Period()));
   if (mcolor[limit]==-1) CleanPoint(limit,macdda,macddb);
   for (i=limit; i>=0; i--)
   {
       int y = iBarShift(NULL,TimeFrame,Time[i]);               
          macd[i]   = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,FastPeriod,SlowPeriod,SignalPeriod,Price,PricePreSmooth,ColorOnSignalCross,LinesVisible,LinesID,LinesUpColor,LinesDnColor,LinesStyle,LinesWidth,arrowsVisible,arrowsOnFirst,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,0,y);
          signal[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,FastPeriod,SlowPeriod,SignalPeriod,Price,PricePreSmooth,ColorOnSignalCross,LinesVisible,LinesID,LinesUpColor,LinesDnColor,LinesStyle,LinesWidth,arrowsVisible,arrowsOnFirst,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,3,y);
          mcolor[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,FastPeriod,SlowPeriod,SignalPeriod,Price,PricePreSmooth,ColorOnSignalCross,LinesVisible,LinesID,LinesUpColor,LinesDnColor,LinesStyle,LinesWidth,arrowsVisible,arrowsOnFirst,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,4,y);
          macdda[i] = EMPTY_VALUE;
          macddb[i] = EMPTY_VALUE;
            if (mcolor[i]==-1) PlotPoint(i,macdda,macddb,macd);
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

double workhTema[][16];
double ihTema(int i, int period, int usePrice, int preSmooth, int index=0)
{
   if (ArrayRange(workhTema,0)!=Bars) ArrayResize(workhTema,Bars); index *= 8; int r = Bars-i-1;

   //
   //
   //
   //
   //
      
      if (usePrice==pr_ha)
      {   
         double haOpen  = (workhTema[r-1][index+6] + workhTema[r-1][index+7]) / 2;
         double haClose = (Open[i]+High[i]+Low[i]+Close[i])/4.0;
         double haHigh  = MathMax(High[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(Low[i] , MathMin(haOpen,haClose));
      
         if(haOpen<haClose) { workhTema[r][index+4] = haLow;  workhTema[r][index+5] = haHigh; } 
         else               { workhTema[r][index+4] = haHigh; workhTema[r][index+5] = haLow;  } 
                              workhTema[r][index+6] = haOpen;
                              workhTema[r][index+7] = haClose;
         double price = 0;
         for (int k=0; k<preSmooth && (r-k)>=0; k++)
               price += (workhTema[r-k][index+4]+workhTema[r-k][index+5]+workhTema[r-k][index+6]+workhTema[r-k][index+7])/4.0;
               price /= preSmooth;
      }
      else price = iMA(NULL,0,preSmooth,0,MODE_SMA,(int)usePrice,i);
      
      //
      //
      //
      //
      //

      double alpha = 2.0 / (1.0 + period);
          workhTema[r][index+3] = workhTema[r-1][index+3]+alpha*(price                -workhTema[r-1][index+3]);
          workhTema[r][index+2] = workhTema[r-1][index+2]+alpha*(workhTema[r][index+3]-workhTema[r-1][index+2]);
          workhTema[r][index+1] = workhTema[r-1][index+1]+alpha*(workhTema[r][index+2]-workhTema[r-1][index+1]);
          workhTema[r][index+0] = 3*workhTema[r][index+3]-3*workhTema[r][index+2]+workhTema[r][index+1];
   return(workhTema[r][index+0]);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

double workTema[][6];
#define _ema1 0
#define _ema2 1
#define _ema3 2

double iTema(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workTema,0)!= Bars) ArrayResize(workTema,Bars); instanceNo*=3; r = Bars-r-1;

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
          workTema[r][_ema1+instanceNo] = workTema[r-1][_ema1+instanceNo]+alpha*(price                        -workTema[r-1][_ema1+instanceNo]);
          workTema[r][_ema2+instanceNo] = workTema[r-1][_ema2+instanceNo]+alpha*(workTema[r][_ema1+instanceNo]-workTema[r-1][_ema2+instanceNo]);
          workTema[r][_ema3+instanceNo] = workTema[r-1][_ema3+instanceNo]+alpha*(workTema[r][_ema2+instanceNo]-workTema[r-1][_ema3+instanceNo]);
   return(workTema[r][_ema3+instanceNo]+3.0*(workTema[r][_ema1+instanceNo]-workTema[r][_ema2+instanceNo]));
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

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

void doAlert(string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
      if (previousAlert != doWhat || previousTime != Time[0]) {
          previousAlert  = doWhat;
          previousTime   = Time[0];

          //
          //
          //
          //
          //

          message =  StringConcatenate(Symbol()," ",timeFrameToString(_Period)," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," Zerolag Tema MACD ",doWhat);
             if (alertsMessage) Alert(message);
             if (alertsNotify)  SendNotification(message);
             if (alertsEmail)   SendMail(_Symbol+" Zerolag Tema MACD ",message);
             if (alertsSound)   PlaySound(soundFile);
      }
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

      int add = 0; if (!arrowsOnFirst) add = _Period*60-1;
      ObjectCreate(name,OBJ_ARROW,0,Time[i]+add,0);
         ObjectSet(name,OBJPROP_ARROWCODE,theCode);
         ObjectSet(name,OBJPROP_COLOR,theColor);
         if (up)
               ObjectSet(name,OBJPROP_PRICE1,High[i] + arrowsUpperGap * gap);
         else  ObjectSet(name,OBJPROP_PRICE1,Low[i]  - arrowsLowerGap * gap);
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

