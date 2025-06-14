//------------------------------------------------------------------
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1  HotPink
#property indicator_color2  PaleVioletRed
#property indicator_color3  HotPink
#property indicator_width1  6
#property indicator_width2  6
#property indicator_width3  6
#property indicator_minimum -1

//
//
//
//
//

extern string ForSymbol             = "";
extern int    VolatilityPeriodWeeks = 12;
extern int    BarsPerDay            = 21;
extern string IndicatorUniqueID     = "DailyVolatility";
extern color  TextColor             = clrDarkGray;

//
//
//
//
//

double volatilityd[];
double volatilitym[];
double volatilityu[];
double dummy[];
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
   SetIndexBuffer(0,volatilityu); SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(1,volatilitym); SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexBuffer(2,volatilityd); SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexBuffer(3,dummy);       SetIndexStyle(3,DRAW_LINE,EMPTY,EMPTY,clrNONE); 
      BarsPerDay = MathMax(BarsPerDay,10);
         if (ForSymbol=="") ForSymbol=Symbol();
            shortName = IndicatorUniqueID+": for "+ForSymbol+" - "+VolatilityPeriodWeeks+" weeks data ";
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
   string lookFor = IndicatorUniqueID+":";
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
   double pipMultiplier = 1; if (MarketInfo(ForSymbol,MODE_DIGITS)==3 || MarketInfo(ForSymbol,MODE_DIGITS)==5) pipMultiplier=10;
   double intraWeek[7][4];
   double point = MarketInfo(ForSymbol,MODE_POINT);
      ArrayInitialize(intraWeek,0);
      
      //
      //
      //
      //
      //
      
         if (iMA(ForSymbol,PERIOD_D1,1,0,0,0,0)==0) return(0);
         if (iMA(ForSymbol,PERIOD_W1,1,0,0,0,0)==0) return(0);
            datetime startTime = iTime(ForSymbol,PERIOD_W1,VolatilityPeriodWeeks);
                     int limit = iBarShift(ForSymbol,PERIOD_D1,startTime); 
                     if (limit>VolatilityPeriodWeeks*7*7+7) return(0);
                  
            //
            //
            //    leaving last (incomplete) hour out
            //
            //
                  
            for(int i=limit; i>0; i--)
            {
               int day = TimeDayOfWeek(iTime(ForSymbol,PERIOD_D1,i));
                  intraWeek[day][0] += MathMin(iOpen(ForSymbol,PERIOD_D1,i),iClose(ForSymbol,PERIOD_D1,i))-iLow(ForSymbol,PERIOD_D1,i);
                  intraWeek[day][1] += MathAbs(iOpen(ForSymbol,PERIOD_D1,i)-iClose(ForSymbol,PERIOD_D1,i));
                  intraWeek[day][2] += iHigh(ForSymbol,PERIOD_D1,i)-MathMax(iOpen(ForSymbol,PERIOD_D1,i),iClose(ForSymbol,PERIOD_D1,i));
                  intraWeek[day][3] += 1;
            }
      
      //
      //
      //
      //
      //
      
         double max = 0;
         for (i=0; i<7; i++)
         {
            intraWeek[i][0] /= (point*pipMultiplier*MathMax(intraWeek[i][3],1));
            intraWeek[i][1] /= (point*pipMultiplier*MathMax(intraWeek[i][3],1));
            intraWeek[i][2] /= (point*pipMultiplier*MathMax(intraWeek[i][3],1));
         
            //
            //
            //
            //
            //
            
            for (int k=0; k<BarsPerDay; k++)
            {
               volatilityd[(6-i)*(BarsPerDay+1)+k] = intraWeek[i][0];
               volatilitym[(6-i)*(BarsPerDay+1)+k] = intraWeek[i][1]+intraWeek[i][0];
               volatilityu[(6-i)*(BarsPerDay+1)+k] = intraWeek[i][2]+intraWeek[i][1]+intraWeek[i][0];
                                                 max = MathMax(max,volatilityu[(6-i)*(BarsPerDay+1)+k]);
                                                 dummy[i] = max*1.40;                                                 
            }
            volatilityd[(6-i)*(BarsPerDay+1)-1] = EMPTY_VALUE;
            volatilitym[(6-i)*(BarsPerDay+1)-1] = EMPTY_VALUE;
            volatilityu[(6-i)*(BarsPerDay+1)-1] = EMPTY_VALUE;
         }

         //
         //
         //
         //
         //
      
         int window = WindowFind(shortName);
         for (i=0; i<7; i++)
         {
            string name = shortName+i;
            datetime time = Time[(6-i)*(BarsPerDay+1)]-(BarsPerDay*Period()*60)/2.0;
       
                  if (ObjectFind(name) == -1)
                      ObjectCreate(name,OBJ_TEXT,window,0,0);
                         ObjectSet(name,OBJPROP_TIME1,time);
                         ObjectSet(name,OBJPROP_PRICE1,max*1.22);
                         ObjectSet(name,OBJPROP_COLOR,TextColor);
                         ObjectSetText(name,"  "+i,9,"Courier new");
         }
         
         time = Time[3*(BarsPerDay+1)+BarsPerDay/2];
         name = shortName+i;
                     if (ObjectFind(name) == -1)
                         ObjectCreate(name,OBJ_TEXT,window,0,0);
                            ObjectSet(name,OBJPROP_TIME1,time);
                            ObjectSet(name,OBJPROP_PRICE1,max*1.35);
                            ObjectSet(name,OBJPROP_COLOR,TextColor);
                            ObjectSetText(name,ForSymbol+" maximal : "+DoubleToStr(max,2)+" pips",10,"Courier new");
      
      //
      //
      //
      //
      //
      
      SetIndexDrawBegin(0,Bars-7*(BarsPerDay+1)+1);
      SetIndexDrawBegin(1,Bars-7*(BarsPerDay+1)+1);
      SetIndexDrawBegin(2,Bars-7*(BarsPerDay+1)+1);
   return(0);
}