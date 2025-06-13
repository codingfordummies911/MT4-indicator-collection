//+------------------------------------------------------------------
//|
//+------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1  PaleVioletRed
#property indicator_color2  DimGray
#property indicator_width1  2
#property indicator_style2  STYLE_DASHDOTDOT
#property indicator_levelcolor DimGray

//
//
//
//
//

extern double RsiGamma             = 0.50;
extern int    RsiPrice             = 0;
extern double RsiSmoothGamma       = 0.001;
extern double FilterGamma          = 0.60;
extern double LevelUp              = 0.85;
extern double LevelDown            = 0.15;
extern bool   NoTradeZoneVisible   = true;
extern double NoTradeZoneUp        = 0.65;
extern double NoTradeZoneDown      = 0.35;
extern color  NoTradeZoneColor     = Gainsboro;
extern color  NoTradeZoneTextColor = PaleVioletRed;
extern string UniqueID             = "Laguerre rsi & filter 1";

//
//
//
//
//

double lag[];
double fil[];
string shortName;

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
   SetIndexBuffer(0,lag);
   SetIndexBuffer(1,fil);
      SetLevelValue(0,LevelUp);
      SetLevelValue(1,LevelDown);
      shortName = UniqueID+": ("+DoubleToStr(RsiGamma,2)+","+DoubleToStr(RsiSmoothGamma,2)+") filter ("+DoubleToStr(FilterGamma,2)+")";
      IndicatorShortName(shortName);
   return(0);
}

//
//
//
//
//

int deinit()
{
   string lookFor = UniqueID+":";
   int    lookForLength = StringLen(lookFor);
   for (int i=ObjectsTotal()-1; i>=0; i--)
   {
      string objectName = ObjectName(i); if (StringSubstr(objectName,0,lookForLength) == lookFor) ObjectDelete(objectName);
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
         int limit = MathMin(Bars - counted_bars,Bars-1);

   //
   //
   //
   //
   //
   
      for(int i = limit; i >= 0 ; i--)
      {
         lag[i] = LaGuerreRsi(iMA(NULL,0,1,0,MODE_SMA,RsiPrice,i),RsiGamma,RsiSmoothGamma,i);
         fil[i] = LaGuerreFil(lag[i],FilterGamma,i);
      }
      
      //
      //
      //
      //
      //
      
      if (NoTradeZoneVisible)
      {
         string name   = UniqueID+":zone";
         int    window = WindowFind(shortName);
            if (ObjectFind(name) == -1)
                ObjectCreate(name,OBJ_RECTANGLE,window,0,0,0,0);
                   ObjectSet(name,OBJPROP_TIME1,Time[Bars-1]);
                   ObjectSet(name,OBJPROP_TIME2,Time[0]);
                   ObjectSet(name,OBJPROP_PRICE1,NoTradeZoneUp);
                   ObjectSet(name,OBJPROP_PRICE2,NoTradeZoneDown);
                   ObjectSet(name,OBJPROP_COLOR,NoTradeZoneColor);
                   ObjectSet(name,OBJPROP_BACK,true);
         name = UniqueID+":text";                   
            if (ObjectFind(name) == -1)
                ObjectCreate(name,OBJ_TEXT,window,0,0);
                   ObjectSet(name,OBJPROP_TIME1,Time[0]+30*Period()*60);
                   ObjectSet(name,OBJPROP_PRICE1,(NoTradeZoneUp+NoTradeZoneDown)/2.0);
                   ObjectSet(name,OBJPROP_COLOR,NoTradeZoneTextColor);
                   ObjectSetText(name,"no-trade zone "+DoubleToStr(NoTradeZoneDown,2)+":"+DoubleToStr(NoTradeZoneUp,2),10,"Courier new");
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

double workLagRsi[][15];
double LaGuerreRsi(double price, double gamma, double smooth, int i, int instanceNo=0)
{
   if (ArrayRange(workLagRsi,0)!=Bars) ArrayResize(workLagRsi,Bars); int r = i; i=Bars-i-1; instanceNo*=5;

   //
   //
   //
   //
   //
      
   workLagRsi[i][instanceNo+0] = (1.0 - gamma)*price                                                + gamma*workLagRsi[i-1][instanceNo+0];
	workLagRsi[i][instanceNo+1] = -gamma*workLagRsi[i][instanceNo+0] + workLagRsi[i-1][instanceNo+0] + gamma*workLagRsi[i-1][instanceNo+1];
	workLagRsi[i][instanceNo+2] = -gamma*workLagRsi[i][instanceNo+1] + workLagRsi[i-1][instanceNo+1] + gamma*workLagRsi[i-1][instanceNo+2];
	workLagRsi[i][instanceNo+3] = -gamma*workLagRsi[i][instanceNo+2] + workLagRsi[i-1][instanceNo+2] + gamma*workLagRsi[i-1][instanceNo+3];

   //
   //
   //
   //
   //
   
      double CU = 0.00;
      double CD = 0.00;
            if (workLagRsi[i][instanceNo+0] >= workLagRsi[i][instanceNo+1])
            			CU =      workLagRsi[i][instanceNo+0] - workLagRsi[i][instanceNo+1];
            else	   CD =      workLagRsi[i][instanceNo+1] - workLagRsi[i][instanceNo+0];
            if (workLagRsi[i][instanceNo+1] >= workLagRsi[i][instanceNo+2])
            			CU = CU + workLagRsi[i][instanceNo+1] - workLagRsi[i][instanceNo+2];
            else	   CD = CD + workLagRsi[i][instanceNo+2] - workLagRsi[i][instanceNo+1];
            if (workLagRsi[i][instanceNo+2] >= workLagRsi[i][instanceNo+3])
   	       		   CU = CU + workLagRsi[i][instanceNo+2] - workLagRsi[i][instanceNo+3];
            else	   CD = CD + workLagRsi[i][instanceNo+3] - workLagRsi[i][instanceNo+2];
            if (CU + CD != 0) 
                     workLagRsi[i][instanceNo+4] = CU / (CU + CD);
            else     workLagRsi[i][instanceNo+4] = 0;

   //
   //
   //
   //
   //

   return(LaGuerreFil(workLagRsi[i][instanceNo+4],smooth,r,1));
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

double workLagFil[][8];
double LaGuerreFil(double price, double gamma, int i, int instanceNo=0)
{
   if (ArrayRange(workLagFil,0)!=Bars) ArrayResize(workLagFil,Bars); i=Bars-i-1; instanceNo*=4;
   if (gamma<=0) return(price);

   //
   //
   //
   //
   //
      
   workLagFil[i][instanceNo+0] = (1.0 - gamma)*price                                                + gamma*workLagFil[i-1][instanceNo+0];
	workLagFil[i][instanceNo+1] = -gamma*workLagFil[i][instanceNo+0] + workLagFil[i-1][instanceNo+0] + gamma*workLagFil[i-1][instanceNo+1];
	workLagFil[i][instanceNo+2] = -gamma*workLagFil[i][instanceNo+1] + workLagFil[i-1][instanceNo+1] + gamma*workLagFil[i-1][instanceNo+2];
	workLagFil[i][instanceNo+3] = -gamma*workLagFil[i][instanceNo+2] + workLagFil[i-1][instanceNo+2] + gamma*workLagFil[i-1][instanceNo+3];

   //
   //
   //
   //
   //
   
   return((workLagFil[i][instanceNo+0]+2.0*workLagFil[i][instanceNo+1]+2.0*workLagFil[i][instanceNo+2]+workLagFil[i][instanceNo+3])/6.0);
}