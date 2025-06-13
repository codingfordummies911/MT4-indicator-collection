//+------------------------------------------------------------------+
//|                                         RSI of (MACD -SIGNAL).mq4  |
//|                      Copyright © 2009, MetaQuotes Software Corp. |
//|                      http://www.metaquotes.net/                  |
//|                      BY  SOHOCOOL 2012                    |
//+------------------------------------------------------------------+
#property  copyright "Copyright © 2009, MetaQuotes Software Corp."
#property  link      ""
//---- indicator settings
#property  indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 30
#property indicator_level2 50
#property indicator_level3 70
#property  indicator_buffers 1
#property  indicator_color1 DodgerBlue
#property  indicator_width1  2
//---- indicator parameters
extern string TimeFrame                  = "Current time frame";  
extern int    FastEMA                    = 24;
extern int    SlowEMA                    = 48;
extern int    MODE_MA                    = 3;
extern int    SignalSMA                  = 9;
extern int    RSIPeriod                  = 5;
extern string note                       = "turn on Alert = true; turn off = false";
extern bool   alertsOn                   = true;
extern bool   alertsOnCurrent            = true;
extern bool   alertsMessage              = true;
extern bool   alertsSound                = true;
extern bool   alertsNotify               = false;
extern bool   alertsEmail                = false;
extern string soundFile                  = "alert2.wav";
extern bool   ShowArrowsForRsiLevel30_70 = true;
extern bool   ShowArrowsForRsiSlope      = false;
extern string arrowsIdentifier           = "RsiArrows1";
extern double arrowsUpperGap             = 1.0;
extern double arrowsLowerGap             = 1.0;
extern color  arrowsUpColor1             = DeepSkyBlue;
extern color  arrowsDnColor1             = Red;
extern color  arrowsUpColor2             = LawnGreen;
extern color  arrowsDnColor2             = Red;

//---- buffers
double RSIBuffer[];
double PosBuffer[];
double NegBuffer[];
//---- indicator buffers
double     MacdBuffer[];
double     SignalBuffer[];
double trend1[];
double trend2[];

string indicatorFileName;
bool   returnBars;
int    timeFrame;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   IndicatorBuffers(7);
//---- drawing settings
   SetIndexStyle(0,DRAW_LINE);
  // SetIndexStyle(1,DRAW_LINE);
   //SetIndexStyle(2,DRAW_LINE);
   SetIndexDrawBegin(0,RSIPeriod);
   IndicatorDigits(Digits+1);
//---- indicator buffers mapping
   SetIndexBuffer(1,MacdBuffer);
   SetIndexBuffer(2,SignalBuffer);
   SetIndexBuffer(0,RSIBuffer);
   SetIndexBuffer(3,PosBuffer);
   SetIndexBuffer(4,NegBuffer);
   SetIndexBuffer(5,trend1);
   SetIndexBuffer(6,trend2);
   indicatorFileName = WindowExpertName();
   returnBars        = TimeFrame == "returnBars";     if (returnBars)     return(0);
   timeFrame         = stringToTimeFrame(TimeFrame);
   IndicatorShortName(timeFrameToString(timeFrame)+" RSI_(MACD-SIGNAL)("+FastEMA+","+SlowEMA+","+SignalSMA+"),("+RSIPeriod+")");
   SetIndexLabel(0,"MACD");
   SetIndexLabel(1,"Signal");
   SetIndexLabel(2,"RSI");
//---- initialization done
   return(0);
  }
int deinit()
{
   deleteArrows();
   return(0);
}
  
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int start()
{
   int counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
           int limit=MathMin(Bars-counted_bars,Bars-1);
           if (returnBars) { RSIBuffer[0] = limit+1; return(0); }
   
            if (timeFrame!=Period())
            {
               limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
               for (int i=limit; i>=0; i--)
               {
                  int y = iBarShift(NULL,timeFrame,Time[i]);               
                     RSIBuffer[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",FastEMA,SlowEMA,MODE_MA,SignalSMA,RSIPeriod,"",alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,ShowArrowsForRsiLevel30_70,ShowArrowsForRsiSlope,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor1,arrowsDnColor1,arrowsUpColor2,arrowsDnColor2,0,y);
                     
               }
               return(0);
            }
   double rel,negative,positive;        
   for(i=0; i<limit; i++) MacdBuffer[i]=iMA(NULL,0,FastEMA,0,MODE_MA,PRICE_CLOSE,i)-iMA(NULL,0,SlowEMA,0,MODE_MA,PRICE_CLOSE,i);
//---- signal line counted in the 2-nd buffer
   for(i=0; i<limit; i++)    SignalBuffer[i]=iMAOnArray(MacdBuffer,Bars,SignalSMA,0,MODE_SMA,i);
//=============================================================== RSI =
   i=Bars-RSIPeriod-1;
   if(counted_bars>=RSIPeriod) i=Bars-counted_bars-1;
   while(i>=0)
     {
      double sumn=0.0,sump=0.0;
      if(i==Bars-RSIPeriod-1)
        {
         int k=Bars-2;
         //---- initial accumulation
         while(k>=i)
           {
            rel=(MacdBuffer[k]-SignalBuffer[k])-(MacdBuffer[k+1]-SignalBuffer[k+1]);
            if(rel>0) sump+=rel;
            else      sumn-=rel;
            k--;
           }
         positive=sump/RSIPeriod;
         negative=sumn/RSIPeriod;
        }
      else
        {
         //---- smoothed moving average
         rel=(MacdBuffer[i]- SignalBuffer[i])-(MacdBuffer[i+1]-SignalBuffer[i+1]);
         if(rel>0) sump=rel;
         else      sumn=-rel;
         positive=(PosBuffer[i+1]*(RSIPeriod-1)+sump)/RSIPeriod;
         negative=(NegBuffer[i+1]*(RSIPeriod-1)+sumn)/RSIPeriod;
        }
      PosBuffer[i]=positive;
      NegBuffer[i]=negative;
      if(negative==0.0) RSIBuffer[i]=0.0;
      else RSIBuffer[i]=(100.0-100.0/(1+positive/negative) );
      i--;
     }
   for(i=limit; i>=0; i--)
   {
      trend1[i] = trend1[i+1];
      trend2[i] = trend2[i+1];
         if ((RSIBuffer[i+1]<30 && RSIBuffer[i]>30 )||(RSIBuffer[i+1]<70 && RSIBuffer[i]>70)) trend1[i] =  1;
         if ((RSIBuffer[i+1]>70 && RSIBuffer[i]<70)||(RSIBuffer[i+1]>30 && RSIBuffer[i]<30))  trend1[i] = -1;
         
         if (RSIBuffer[i+1]<RSIBuffer[i])  trend2[i] =  1;
         if (RSIBuffer[i+1]>RSIBuffer[i])  trend2[i] = -1;
         
         //
         //
         //
         //
         //
         
         if (ShowArrowsForRsiLevel30_70 || ShowArrowsForRsiSlope)
         {
           if (ShowArrowsForRsiLevel30_70)
           {
             deleteArrow("1",Time[i]);
             if (trend1[i]!=trend1[i+1])
             {
               if (trend1[i] == 1) drawArrow(i,"1",arrowsUpColor1,236,false);
               if (trend1[i] ==-1) drawArrow(i,"1",arrowsDnColor1,238,true);
             }
           }         
           if (ShowArrowsForRsiSlope)
           {
             deleteArrow("2",Time[i]);
             if (trend2[i]!=trend2[i+1])
             {
               if (trend2[i] == 1) drawArrow(i,"2",arrowsUpColor2,241,false);
               if (trend2[i] ==-1) drawArrow(i,"2",arrowsDnColor2,242,true);
             }
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
       else     whichBar = 1;  whichBar = iBarShift(NULL,0,iTime(NULL,timeFrame,whichBar)); 
       if (trend1[whichBar] != trend1[whichBar+1])
       if (trend1[whichBar] == 1)
             doAlert("Buy");
       else  doAlert("Sell");       
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
  
//
//
//
//
//

void drawArrow(int i,string add, color theColor,int theCode,bool up)
{
   string name = arrowsIdentifier+":"+add+":"+Time[i];
   double gap  = 3.0*iATR(NULL,0,120,i)/8.0;   
   
      //
      //
      //
      //
      //
      
      ObjectCreate(name,OBJ_ARROW,0,Time[i],0);
         ObjectSet(name,OBJPROP_ARROWCODE,theCode);
         ObjectSet(name,OBJPROP_COLOR,theColor);
         if (up)
               ObjectSet(name,OBJPROP_PRICE1,High[i]+gap);
         else  ObjectSet(name,OBJPROP_PRICE1,Low[i] -gap);
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
void deleteArrow(string add, datetime time)
{
   string lookFor = arrowsIdentifier+":"+add+":"+time; ObjectDelete(lookFor);
}

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

          message =  StringConcatenate(Symbol()," ",timeFrameToString(timeFrame)," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," RSIofMACD-SIGNAL ",doWhat);
             if (alertsMessage) Alert(message);
             if (alertsNotify)  SendNotification(message);
             if (alertsEmail)   SendMail(StringConcatenate(Symbol()," RSIofMACD-SIGNAL "),message);
             if (alertsSound)   PlaySound(soundFile);
      }
}