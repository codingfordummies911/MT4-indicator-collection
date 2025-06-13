//+------------------------------------------------------------------+
//|                                                           rsi ma |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers    2
#property indicator_color1     DeepSkyBlue
#property indicator_color2     White
#property indicator_width1     2
#property indicator_style2     STYLE_DASH
#property indicator_minimum    0
#property indicator_maximum    100
#property indicator_level1     70
#property indicator_level2     50
#property indicator_level3     30

//
//
//
//
//

extern string TimeFrame        = "Current time frame";
extern int    RsiLength        = 14;
extern int    RsiPrice         = PRICE_CLOSE;
extern int    MaPeriod         = 10;
extern int    MaType           = MODE_SMA;
extern bool   alertsOn         = false;
extern bool   alertsOnCurrent  = true;
extern bool   alertsMessage    = true;
extern bool   alertsSound      = false;
extern bool   alertsNotify     = false;
extern bool   alertsEmail      = false;
extern bool   ShowArrows       = true;
extern string arrowsIdentifier = "rsima Arrows1";
extern double arrowsUpperGap   = 1.0;
extern double arrowsLowerGap   = 1.0;
extern color  arrowsUpColor    = LimeGreen;
extern color  arrowsDnColor    = Red;
extern int    arrowsUpCode     = 241;
extern int    arrowsDnCode     = 242;

//
//
//
//
//

double rsi[];
double rsiMa[];
double trend[];

//
//
//
//
//

string indicatorFileName;
int    timeFrame;
bool   returnBars;
bool   calculateValue;

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
  IndicatorBuffers(3);
    SetIndexBuffer(0,rsi);
    SetIndexBuffer(1,rsiMa);
    SetIndexBuffer(2,trend);
    
    //
    //
    //
    //
    //
      
      indicatorFileName = WindowExpertName();
      calculateValue    = (TimeFrame=="calculateValue"); if (calculateValue) return(0);
      returnBars        = (TimeFrame=="returnBars");     if (returnBars)     return(0);
      timeFrame         = stringToTimeFrame(TimeFrame);
      
    //
    //
    //
    //
    //
      
    IndicatorShortName(timeFrameToString(timeFrame)+"  Rsi Ma ("+RsiLength+","+MaPeriod+")");
 
   return(0);
}

int deinit() 
{  
   deleteArrows(); 
   
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

   if (calculateValue || timeFrame==Period())
   {     
         for(i=limit; i >= 0; i--) rsi[i] = iRsi(iMA(NULL,0,1,0,MODE_SMA,RsiPrice,i),RsiLength,i);
         for(i=limit; i >= 0; i--)
         {
            rsiMa[i] = iMAOnArray(rsi,0,MaPeriod,0,MaType,i);
            trend[i] = trend[i+1]; 
	         if (rsi[i] > rsiMa[i]) trend[i]= 1; 
	         if (rsi[i] < rsiMa[i]) trend[i]=-1; 
	         
	         //
	         //
	         //
	         //
	         //
	         
	         if (ShowArrows)
            {
              deleteArrow(Time[i]);
              if (trend[i] != trend[i+1])
              {
                if (trend[i] == 1)  drawArrow(i,arrowsUpColor,arrowsUpCode,false);
                if (trend[i] ==-1)  drawArrow(i,arrowsDnColor,arrowsDnCode, true);
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
  
       limit = MathMax(limit,MathMin(Bars,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
       for (i=limit;i>=0; i--)
       {
          int y = iBarShift(NULL,timeFrame,Time[i]);
              rsi[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiLength,RsiPrice,MaPeriod,MaType,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,0,y);
              rsiMa[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",RsiLength,RsiPrice,MaPeriod,MaType,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,1,y);
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
//

double workRsi[][3];
#define _price  0
#define _change 1
#define _changa 2

double iRsi(double price, double period, int i, int instanceNo=0)
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

//------------------------------------------------------------------
//
//------------------------------------------------------------------
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
            if (trend[whichBar] ==  1) doAlert(whichBar," crossed signal line up");
            if (trend[whichBar] == -1) doAlert(whichBar," crossed signal line down");
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

       message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," - ",timeFrameToString(timeFrame)+" rsi ma ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsNotify)  SendNotification(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," rsi ma "),message);
          if (alertsSound)   PlaySound("alert2.wav");
   }
}