//------------------------------------------------------------------
//
//------------------------------------------------------------------

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 Lime
#property indicator_color2 SlateBlue
#property indicator_color3 Orange
#property indicator_color4 DarkGray
#property indicator_style4 STYLE_DOT

extern string TimeFrame              = "Current time frame";
extern int    RSIPeriod              = 14;
extern int    BandPeriod             = 20;
extern double BandDeviation          = 1.3185;
extern bool   verticalLinesVisible   = true;
extern string verticalLinesID        = "rsiBbLines1";
extern color  verticalLinesUpColor   = DeepSkyBlue;
extern color  verticalLinesDownColor = PaleVioletRed;
extern int    verticalLinesStyle     = STYLE_DOT;
extern int    verticalLinesWidth     = 0;
extern bool   alertsOn               = true;
extern bool   alertsOnCurrent        = true;
extern bool   alertsMessage          = true;
extern bool   alertsSound            = true;
extern bool   alertsNotify           = true;
extern bool   alertsEmail            = false;
extern string soundFile              = "alert2.wav";
extern bool   ShowArrows             = true;
extern string arrowsIdentifier       = "rsibb Arrows1";
extern double arrowsUpperGap         = 1.0;
extern double arrowsLowerGap         = 1.0;
extern color  arrowsUpColor          = LimeGreen;
extern color  arrowsDnColor          = Red;
extern int    arrowsUpCode           = 241;
extern int    arrowsDnCode           = 242;



double RSIBuf[],UpZone[],DnZone[],Ma[],trend[],cross[];

//
//
//
//
//

string indicatorFileName;
bool   returnBars;
int    timeFrame;

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
   IndicatorBuffers(6);
   SetIndexBuffer(0,RSIBuf);
   SetIndexBuffer(1,UpZone);
   SetIndexBuffer(2,DnZone);
   SetIndexBuffer(3,Ma);
   SetIndexBuffer(4,trend);
   SetIndexBuffer(5,cross);
    //
    //
    //
    //
    //
   
    indicatorFileName = WindowExpertName();
    returnBars        = TimeFrame == "returnBars";     if (returnBars)     return(0);
    timeFrame         = stringToTimeFrame(TimeFrame);
   
    //
    //
    //
    //
    //
    
    IndicatorShortName(timeFrameToString(timeFrame)+" Rsi bands");
   return(0);
}
int deinit()
{
   deleteArrows();
   string lookFor       = verticalLinesID+":";
   int    lookForLength = StringLen(lookFor);
   for (int i=ObjectsTotal()-1; i>=0; i--)
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
   int counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
           int limit=MathMin(Bars-counted_bars,Bars-1);
           if (returnBars) { RSIBuf[0] = limit+1; return(0); }
            if (timeFrame!=Period())
            {
               limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
               for (int i=limit; i>=0; i--)
               {
                   int y = iBarShift(NULL,timeFrame,Time[i]);               
                      RSIBuf[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,BandPeriod,BandDeviation,verticalLinesVisible,verticalLinesID,verticalLinesUpColor,verticalLinesDownColor,verticalLinesStyle,verticalLinesWidth,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,0,y);
                      UpZone[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,BandPeriod,BandDeviation,verticalLinesVisible,verticalLinesID,verticalLinesUpColor,verticalLinesDownColor,verticalLinesStyle,verticalLinesWidth,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,1,y);
                      DnZone[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,BandPeriod,BandDeviation,verticalLinesVisible,verticalLinesID,verticalLinesUpColor,verticalLinesDownColor,verticalLinesStyle,verticalLinesWidth,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,2,y);
                      Ma[i]     = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RSIPeriod,BandPeriod,BandDeviation,verticalLinesVisible,verticalLinesID,verticalLinesUpColor,verticalLinesDownColor,verticalLinesStyle,verticalLinesWidth,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,3,y);           
               }
               return(0);
            }
   
   //
   //
   //
   //
   //
   
   for(i=limit; i>=0; i--) RSIBuf[i] = iRSI(NULL,0,RSIPeriod,PRICE_WEIGHTED,i);
   for(i=limit; i>=0; i--) 
   {
      double dev = iStdDevOnArray(RSIBuf,0,BandPeriod,0,MODE_SMA,i);
         Ma[i]     = iMAOnArray(RSIBuf,0,BandPeriod,0,MODE_SMA,i);
         UpZone[i] = Ma[i] + BandDeviation * dev;
         DnZone[i] = Ma[i] - BandDeviation * dev;  
         trend[i]  = trend[i+1];
         cross[i]  = cross[i+1];
            if (RSIBuf[i]>UpZone[i]) trend[i] = 1;
            if (RSIBuf[i]<DnZone[i]) trend[i] =-1;
            if (RSIBuf[i]>Ma[i])     cross[i] = 1;
            if (RSIBuf[i]<Ma[i])     cross[i] =-1;
            
            //
            //
            //
            //
            //
     
            if (ShowArrows)
            {
              deleteArrow(Time[i]);
              if (cross[i] != cross[i+1])
              {
                 if (cross[i] == 1)  drawArrow(i,arrowsUpColor,arrowsUpCode,false);
                 if (cross[i] ==-1)  drawArrow(i,arrowsDnColor,arrowsDnCode, true);
              }
            }
            manageLines(i);
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
      if (cross[whichBar] != cross[whichBar+1])
      if (cross[whichBar] == 1)
            doAlert("crossing up");
      else  doAlert("crossing down");       
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

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   tfs = stringUpperCase(tfs);
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

string stringUpperCase(string str)
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


//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

void manageLines(int i)
{
   if (verticalLinesVisible )
   {
      ObjectDelete(verticalLinesID+":"+Time[i]);   
         if (trend[i]!=trend[i+1])
         {
            if (trend[i] == 1) drawLine(i,verticalLinesUpColor);
            if (trend[i] ==-1) drawLine(i,verticalLinesDownColor);
         }
   }
}               

//
//
//
//
//

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

void deleteLine(datetime time)
{
   
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

          message =  StringConcatenate(Symbol()," ",timeFrameToString(timeFrame)," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," RSI + Bollinger bands ",doWhat);
             if (alertsMessage) Alert(message);
             if (alertsNotify)  SendNotification(message);
             if (alertsEmail)   SendMail(StringConcatenate(Symbol()," RSI + Bollinger bands "),message);
             if (alertsSound)   PlaySound(soundFile);
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
               ObjectSet(name,OBJPROP_PRICE1,High[i] + arrowsUpperGap * gap);
         else  ObjectSet(name,OBJPROP_PRICE1,Low[i]  - arrowsLowerGap * gap);
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




