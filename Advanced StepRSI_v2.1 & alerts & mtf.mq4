//------------------------------------------------------------------
#property copyright "www.forex-station.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 LimeGreen
#property indicator_color2 Orange
#property indicator_color3 DarkGray
#property indicator_width1 2
#property indicator_width2 2

//
//
//
//
//

enum enRsiTypes
{
   rsi_rsi,  // Regular RSI
   rsi_wil,  // Wilders RSI
   rsi_rsx,  // RSX
   rsi_cut   // Cuttlers RSI
};


extern string             TimeFrame        = "Current time frame";
extern enRsiTypes         RsiType          = rsi_rsx;
extern int                PeriodRSI        = 14;
extern ENUM_APPLIED_PRICE Price            = PRICE_CLOSE;
extern int                StepSizeFast     =  5;
extern int                StepSizeSlow     = 15;
extern bool               alertsOn         = false;    // Turn alerts on?
extern bool               alertsOnCurrent  = true;     // Alerts on current (still opened) bar?
extern bool               alertsMessage    = true;     // Alerts should show pop-up message?
extern bool               alertsPushNotif  = false;    // Alerts should send push notification?
extern bool               alertsSound      = false;    // Alerts should play a sound?
extern bool               alertsEmail      = false;    // Alerts should send email?
extern bool               Interpolate      = true;

double Line1Buffer[];
double Line2Buffer[];
double Line3Buffer[];
double trendf[];
double trends[];
double trend[];
double maxf[];
double minf[];
double maxs[];
double mins[];

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
   IndicatorBuffers(10);
   SetIndexBuffer(0,Line2Buffer); SetIndexLabel(0,"StepRSI fast");
   SetIndexBuffer(1,Line3Buffer); SetIndexLabel(1,"StepRSI slow");
   SetIndexBuffer(2,Line1Buffer); SetIndexLabel(2,"RSI");
   SetIndexBuffer(3,trendf);
   SetIndexBuffer(4,trends);
   SetIndexBuffer(5,minf);
   SetIndexBuffer(6,mins);
   SetIndexBuffer(7,maxf);
   SetIndexBuffer(8,maxs);
   SetIndexBuffer(9,trend);
   
      timeFrame         = stringToTimeFrame(TimeFrame);   
      indicatorFileName = WindowExpertName();
      returnBars        = (TimeFrame == "returnBars");
   
   IndicatorShortName(timeFrameToString(timeFrame)+" advanced step "+getRsiName((int)RsiType)+" ("+PeriodRSI+","+StepSizeFast+","+StepSizeSlow+")");
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
           if (returnBars)  { Line2Buffer[0] = limit+1; return(0);  } 
                  if (timeFrame!=Period())
                  {
                     limit = MathMax(limit,MathMin(Bars,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
                     for(int i=limit; i>=0; i--)
                     {
                        int n,l,y = iBarShift(NULL,timeFrame,Time[i]);
                           Line2Buffer[i] = iCustom(NULL,timeFrame,indicatorFileName,"",RsiType,PeriodRSI,Price,StepSizeFast,StepSizeSlow,alertsOn,alertsOnCurrent,alertsMessage,alertsPushNotif,alertsSound,alertsEmail,0,y);
                           Line3Buffer[i] = iCustom(NULL,timeFrame,indicatorFileName,"",RsiType,PeriodRSI,Price,StepSizeFast,StepSizeSlow,alertsOn,alertsOnCurrent,alertsMessage,alertsPushNotif,alertsSound,alertsEmail,1,y);
                           Line1Buffer[i] = iCustom(NULL,timeFrame,indicatorFileName,"",RsiType,PeriodRSI,Price,StepSizeFast,StepSizeSlow,alertsOn,alertsOnCurrent,alertsMessage,alertsPushNotif,alertsSound,alertsEmail,2,y);
                           if (!Interpolate || (i>0 && y==iBarShift(NULL,timeFrame,Time[i-1]))) continue;
                           datetime time = iTime(NULL,timeFrame,y);
                              for(n = 1; i+n < Bars && Time[i+n] >= time; n++) continue;	
                              for(l = 1; l < n && (i+l<Bars) && (i+n)<Bars; l++)
                              {
                                 Line2Buffer[i+l] = Line2Buffer[i] + (Line2Buffer[i+n]-Line2Buffer[i])*l/n;
                                 Line3Buffer[i+l] = Line3Buffer[i] + (Line3Buffer[i+n]-Line3Buffer[i])*l/n;
                                 Line1Buffer[i+l] = Line1Buffer[i] + (Line1Buffer[i+n]-Line1Buffer[i])*l/n;
                              }                                 
                        }                           
                        return(0);
                  }

   //
   //
   //
   //
   //
   
   for(i=limit; i>=0; i--)
   {	
      double rsi=iRsi(iMA(NULL,0,1,0,MODE_SMA,Price,i),PeriodRSI,RsiType,i);
   	   maxf[i] = rsi+2*StepSizeFast;
	      minf[i] = rsi-2*StepSizeFast;
   	   maxs[i] = rsi+2*StepSizeSlow;
	      mins[i] = rsi-2*StepSizeSlow;
         if (i>(Bars-2)) continue;

	      trendf[i] = trendf[i+1];
	         if (rsi > maxf[i+1]) trendf[i] = 1; 
	         if (rsi < minf[i+1]) trendf[i] =-1;
	         if (trendf[i]>0 && minf[i]<minf[i+1]) minf[i]=minf[i+1];
	         if (trendf[i]<0 && maxf[i]>maxf[i+1]) maxf[i]=maxf[i+1];

	      trends[i] = trends[i+1];
	         if (rsi>maxs[i+1]) trends[i] = 1; 
	         if (rsi<mins[i+1]) trends[i] =-1;
	         if (trends[i]>0 && mins[i]<mins[i+1]) mins[i]=mins[i+1];
	         if (trends[i]<0 && maxs[i]>maxs[i+1]) maxs[i]=maxs[i+1];
	  
	         Line1Buffer[i]=rsi;
	         if (trendf[i]>0) Line2Buffer[i]=minf[i]+StepSizeFast;
	         if (trendf[i]<0) Line2Buffer[i]=maxf[i]-StepSizeFast;
	         if (trends[i]>0) Line3Buffer[i]=mins[i]+StepSizeSlow;
	         if (trends[i]<0) Line3Buffer[i]=maxs[i]-StepSizeSlow;
	         
	         trend[i] = trend[i+1];
	            if (Line2Buffer[i]>Line3Buffer[i]) trend[i] =  1;
	            if (Line2Buffer[i]<Line3Buffer[i]) trend[i] = -1;
   }
   manageAlerts();
   return(0);	
}

//-------------------------------------------------------------------
//                                                                  
//-------------------------------------------------------------------
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

int stringToTimeFrame(string tfs) {
   StringToUpper(tfs);
   for (int i=ArraySize(iTfTable)-1; i>=0; i--)
         if (tfs==sTfTable[i] || tfs==""+iTfTable[i]) return(MathMax(iTfTable[i],Period()));
                                                      return(Period());
}
string timeFrameToString(int tf) {
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

void manageAlerts()
{
   if (alertsOn)
   {
      int whichBar = 1; if (alertsOnCurrent) whichBar = 0;
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar]== 1) doAlert(whichBar,"trend changed to up");
         if (trend[whichBar]==-1) doAlert(whichBar,"trend changed to down");
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

       message = Symbol()+" at "+TimeToStr(TimeLocal(),TIME_SECONDS)+"advanced step "+getRsiName((int)RsiType)+" "+doWhat;
          if (alertsMessage)   Alert(message);
          if (alertsEmail)     SendMail(StringConcatenate(Symbol(),"advanced step "+getRsiName((int)RsiType)+" "),message);
          if (alertsPushNotif) SendNotification(StringConcatenate(Symbol(),"advanced step "+getRsiName((int)RsiType)+" "+message));
          if (alertsSound)     PlaySound("alert2.wav");
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

string rsiMethodNames[] = {"rsi","Wilders rsi","rsx","Cuttler RSI"};
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

double iRsi(double price, double period, int rsiMode, int i, int instanceNo=0)
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
         
      //
      //
      //
      //
      //
      
      case 1 :
         workRsi[r][z+1] = iSmma(0.5*(MathAbs(workRsi[r][z+_price]-workRsi[r-1][z+_price])+(workRsi[r][z+_price]-workRsi[r-1][z+_price])),0.5*(period-1),Bars-i-1,instanceNo*2+0);
         workRsi[r][z+2] = iSmma(0.5*(MathAbs(workRsi[r][z+_price]-workRsi[r-1][z+_price])-(workRsi[r][z+_price]-workRsi[r-1][z+_price])),0.5*(period-1),Bars-i-1,instanceNo*2+1);
         if((workRsi[r][z+1] + workRsi[r][z+2]) != 0) 
               return(100.0 * workRsi[r][z+1]/(workRsi[r][z+1] + workRsi[r][z+2]));
         else  return(50);

      //
      //
      //
      //
      //

      case 2 :     
         double Kg = (3.0)/(2.0+period), Hg = 1.0-Kg;
         if (r<period) { for (k=1; k<13; k++) workRsi[r][k+z] = 0; return(50); }  

         //
         //
         //
         //
         //
      
         double mom = workRsi[r][_price+z]-workRsi[r-1][_price+z];
         double moa = MathAbs(mom);
         for (k=0; k<3; k++)
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
            
      //
      //
      //
      //
      //
      
      case 3 :
         double sump = 0;
         double sumn = 0;
         for (k=0; k<period; k++)
         {
            double diff = workRsi[r-k][z+_price]-workRsi[r-k-1][z+_price];
               if (diff > 0) sump += diff;
               if (diff < 0) sumn -= diff;
         }
         if (sumn > 0)
               return(100.0-100.0/(1.0+sump/sumn));
         else  return(50);
   } 
   return(0);
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

   if (r<period)
         workSmma[r][instanceNo] = price;
   else  workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
}
