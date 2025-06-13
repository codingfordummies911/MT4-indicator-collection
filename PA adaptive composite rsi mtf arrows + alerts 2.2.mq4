//+------------------------------------------------------------------
//|
//+------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers    3
#property indicator_color1     LimeGreen
#property indicator_color2     Orange
#property indicator_color3     Orange
#property indicator_width1     3
#property indicator_width2     3
#property indicator_width3     3
#property indicator_minimum    -0.1
#property indicator_maximum    1.1

//
//
//
//
//

extern ENUM_TIMEFRAMES TimeFrame      = PERIOD_CURRENT;
extern double PaCycles        = 1.0;
extern double PaFilter        = 1.0;
extern int    RsiPrice         = 0;
extern int    RsiDepth         = 5;
extern bool   RsiFast          = false;
extern double LevelUp          = 0.85;
extern double LevelDown        = 0.15;
extern bool   alertsOn         = false;
extern bool   alertsOnCurrent  = true;
extern bool   alertsOnSlope    = true;
extern bool   alertsOnLevels   = true;
extern bool   alertsMessage    = true;
extern bool   alertsSound      = false;
extern bool   alertsNotify     = false;
extern bool   alertsEmail      = false;
extern string soundFile        = "alert2.wav";
extern bool   ShowArrows       = false;
extern string arrowsIdentifier = "pacrsi Arrows1";
extern double arrowsUpperGap   = 0.5;
extern double arrowsLowerGap   = 0.5;
extern color  arrowsUpColor    = LimeGreen;
extern color  arrowsDnColor    = Red;
extern int    arrowsUpCode     = 241;
extern int    arrowsDnCode     = 242;
extern bool   Interpolate      = true;

//
//
//
//
//

double rsi[];
double rsiDa[];
double rsiDb[];
double slope[];
double trend[];
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
   SetIndexBuffer(0,rsi);
   SetIndexBuffer(1,rsiDa);
   SetIndexBuffer(2,rsiDb);
   SetIndexBuffer(3,slope);
   SetIndexBuffer(4,trend);
   SetLevelValue(0,LevelUp);
   SetLevelValue(1,LevelDown);
   
      RsiDepth          = MathMax(MathMin(RsiDepth,25),2);
      indicatorFileName = WindowExpertName();
      returnBars        = TimeFrame == -99;
      TimeFrame         = MathMax(TimeFrame,_Period);
 
   IndicatorShortName(timeFrameToString(TimeFrame)+" Composite RSI ("+DoubleToStr(PaCycles,2)+","+RsiDepth+")");
   return(0);
}

void deinit() 
{ 
   string lookFor       = arrowsIdentifier+":";
   int    lookForLength = StringLen(lookFor);
   for (int i=ObjectsTotal()-1; i>=0; i--)
   {
      string objectName = ObjectName(i);
         if (StringSubstr(objectName,0,lookForLength) == lookFor) ObjectDelete(objectName);
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

int start()
{
   int counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
           int limit=MathMin(Bars-counted_bars,Bars-1);
           if (returnBars) { rsi[0] = limit+1; return(0); }
           if (TimeFrame!=Period())
           {
               limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/Period()));
               if (slope[limit]==-1) CleanPoint(limit,rsiDa,rsiDb);
               for (int i=limit; i>=0; i--)
               {
                   int y = iBarShift(NULL,TimeFrame,Time[i]);               
                      rsi[i]   = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,PaCycles,PaFilter,RsiPrice,RsiDepth,RsiFast,LevelUp,LevelDown,alertsOn,alertsOnCurrent,alertsOnSlope,alertsOnLevels,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,0,y);
                      slope[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,PaCycles,PaFilter,RsiPrice,RsiDepth,RsiFast,LevelUp,LevelDown,alertsOn,alertsOnCurrent,alertsOnSlope,alertsOnLevels,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,3,y);  
                      rsiDa[i] = EMPTY_VALUE;
                      rsiDb[i] = EMPTY_VALUE; 
                      
                      if (!Interpolate || y==iBarShift(NULL,TimeFrame,Time[i-1])) continue;

                      //
                      //
                      //
                      //
                      //

                      datetime time = iTime(NULL,TimeFrame,y);
                         for(int n = 1; i+n < Bars && Time[i+n] >= time; n++) continue;	
                         for(int k = 1; k < n; k++) rsi[i+k] = rsi[i] + (rsi[i+n] - rsi[i]) * k/n;
              
               }
               for (i=limit;i>=0;i--) if (slope[i]==-1) PlotPoint(i,rsiDa,rsiDb,rsi);
               return(0);
      }

      //
      //
      //
      //
      //
      
      if (slope[limit]==-1) CleanPoint(limit,rsiDa,rsiDb);
      for(i = limit; i >= 0 ; i--)
      {
         double price  =  iMA(NULL,0,1,0,MODE_SMA,RsiPrice,i);
         int RsiPeriod = MathMax(3,iHilbertPhase(price,PaFilter,PaCycles,i));
            rsi[i]   = iCompRsi(price,RsiPeriod,RsiDepth,RsiFast,i);
            rsiDa[i] = EMPTY_VALUE;
            rsiDb[i] = EMPTY_VALUE;
            slope[i] = slope[i+1];
            trend[i] = 0;
               if (rsi[i] > rsi[i+1])   slope[i] =  1;
               if (rsi[i] < rsi[i+1])   slope[i] = -1;
               if (rsi[i] > LevelUp)    trend[i] = 1;
               if (rsi[i] < LevelDown)  trend[i] =-1;  
               if (slope[i]==-1) PlotPoint(i,rsiDa,rsiDb,rsi);
               
               //
               //
               //
               //
               //
               
               if (ShowArrows)
               {
                 string name = arrowsIdentifier+":"+Time[i]; ObjectDelete(name);
                 if (trend[i]!=trend[i+1])
                 {
                   if (trend[i+1] ==  1 && trend[i] != 1) drawArrow(i,arrowsDnColor,arrowsDnCode,true);
                   if (trend[i+1] == -1 && trend[i] !=-1) drawArrow(i,arrowsUpColor,arrowsUpCode,false);
                 }
               }  
     }
     
     //
     //
     //
     //
     //
     
     if (alertsOn)
     {
        if (alertsOnCurrent)
             int whichBar = 0;
        else     whichBar = 1;
        static datetime time1 = 0;
        static string   mess1 = "";
        if (alertsOnLevels && trend[whichBar] != trend[whichBar+1])
        {
           if (trend[whichBar+1] ==  1 && trend[whichBar] != 1) doAlert(time1,mess1,whichBar,"leaving overbought");
           if (trend[whichBar+1] == -1 && trend[whichBar] !=-1) doAlert(time1,mess1,whichBar,"leaving oversold");
        }         
        static datetime time2 = 0;
        static string   mess2 = "";
        if (alertsOnSlope && slope[whichBar] != slope[whichBar+1])
        {
           if (slope[whichBar+1] ==  1 ) doAlert(time2,mess2,whichBar,"slope changed to up");
           if (slope[whichBar+1] == -1 ) doAlert(time2,mess2,whichBar,"slope changed to down");
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

double workCompRsi[][26];
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

string sTfTable[] = {"M1","M5","M10","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,10,15,30,60,240,1440,10080,43200};

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

void CleanPoint(int i,double& first[],double& second[])
{
   if ((second[i]  != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
        second[i+1] = EMPTY_VALUE;
   else
      if ((first[i] != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
          first[i+1] = EMPTY_VALUE;
}
void PlotPoint(int i,double& first[],double& second[],double& from[])
{
   if (first[i+1] == EMPTY_VALUE)
         if (first[i+2] == EMPTY_VALUE) 
               {  first[i]  = from[i]; first[i+1]  = from[i+1]; second[i] = EMPTY_VALUE; }
         else  {  second[i] = from[i]; second[i+1] = from[i+1]; first[i]  = EMPTY_VALUE; }
   else        {  first[i]  = from[i];                          second[i] = EMPTY_VALUE; }
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

       message =  StringConcatenate(Symbol()," ",timeFrameToString(_Period)," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," Pa adaptive composite rsi ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsNotify)  SendNotification(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," Pa adaptive composite rsi "),message);
          if (alertsSound)   PlaySound(soundFile);
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

void drawArrow(int i,color theColor,int theCode,bool up)
{
   
   string name = arrowsIdentifier+":"+Time[i];
   double gap  = 3.0*iATR(NULL,0,20,i)/4.0;   
   
      //
      //
      //
      //
      //
      
      ObjectCreate(name,OBJ_ARROW,0,Time[i],0);
         ObjectSet(name,OBJPROP_ARROWCODE,theCode);
         ObjectSet(name,OBJPROP_COLOR,theColor);
         if (up)
               ObjectSet(name,OBJPROP_PRICE1,High[i] + arrowsUpperGap * gap);
         else  ObjectSet(name,OBJPROP_PRICE1,Low[i]  - arrowsUpperGap * gap);
}