//------------------------------------------------------------------
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1  LimeGreen
#property indicator_color2  PaleVioletRed
#property indicator_style2  STYLE_DOT

//
//
//
//
//

extern int  RsiPeriod       = 14;
extern int  RsiPrice        = PRICE_CLOSE;
extern int  SmoothingPeriod = 3;
extern int  SmoothingMethod = MODE_SMA;
extern int  MaPeriod        = 9;
extern int  MaMethod        = MODE_SMA;
extern bool alertsOn        = false;
extern bool alertsOnCurrent = false;
extern bool alertsMessage   = true;
extern bool alertsSound     = true;
extern bool alertsEmail     = false;
extern bool   arrowsVisible      = false;
extern bool   arrowsOnSlope      = true;
extern string arrowsIdentifier   = "rsi ma cross arrows";
extern double arrowsDisplacement = 1.0;
extern color  arrowsUpColor      = LimeGreen;
extern color  arrowsDnColor      = Red;
extern int    arrowsUpCode       = 241;
extern int    arrowsDnCode       = 242;

//
//
//
//
//

double raw[];
double rsi[];
double sig[];
double trend[];

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
   IndicatorBuffers(4);
      SetIndexBuffer(0,rsi);
      SetIndexBuffer(1,sig);
      SetIndexBuffer(2,raw);
      SetIndexBuffer(3,trend);
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
   int i,counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
           int limit=MathMin(Bars-counted_bars,Bars-1);

   //
   //
   //
   //
   //
   
   for(i=limit; i>=0; i--) raw[i] = iRSI(NULL,0,RsiPeriod,RsiPrice,i);
   for(i=limit; i>=0; i--) rsi[i] = iMAOnArray(raw,0,SmoothingPeriod,0,SmoothingMethod,i);
   for(i=limit; i>=0; i--)
   {
      sig[i]   = iMAOnArray(rsi,0,MaPeriod,0,MaMethod,i);
      trend[i] = trend[i+1];
         if (rsi[i] > sig[i])  trend[i] =  1;
         if (rsi[i] < sig[i])  trend[i] = -1;
      manageArrow(i);              
   }
   manageAlerts();
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


void manageAlerts()
{
   if (alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1;
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar] == 1) doAlert(whichBar,"up");
         if (trend[whichBar] ==-1) doAlert(whichBar,"down");
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

          message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," rsi crossed signal line ",doWhat);
             if (alertsMessage) Alert(message);
             if (alertsEmail)   SendMail(StringConcatenate(Symbol(),"rsi ma crosses"),message);
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

void manageArrow(int i)
{
   if (arrowsVisible)
   {
      deleteArrow(Time[i]);
      if (trend[i] != trend[i+1])
      {
         if (trend[i] == 1) drawArrow(i,arrowsUpColor,arrowsUpCode,false);
         if (trend[i] ==-1) drawArrow(i,arrowsDnColor,arrowsDnCode, true);
      }         
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
               ObjectSet(name,OBJPROP_PRICE1,High[i] + arrowsDisplacement * gap);
         else  ObjectSet(name,OBJPROP_PRICE1,Low[i]  - arrowsDisplacement * gap);
}
void deleteArrow(datetime time)
{
   string lookFor = arrowsIdentifier+":"+time; ObjectDelete(lookFor);
}

