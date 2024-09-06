//+------------------------------------------------------------------+
//|                                                                  |
//|                         PivotsDWM                                |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Visual_BT_Pivots.mq4, MicroMan"
#property link      "Fish.net" 

/*-------------------------------------------------------------------+
PivotsDWM: 

This is an enhanced version of Visual_BT_Pivots.mq4  It provides for
color and line style selection of pivot lines.  It provides for color,
font size and font style selection of line labels, and the ability to 
move line labels left and right of the chart center.  The chart center
is automatically adjusted as you increase/decrease the chart density.
Included is the ability to independently turn on/off the price display 
for the line labels and the chart margin.  For the three selectable 
Pivot time periods (Daily, Weekly, Monthly) the pivot lines can be
calculated using either the "Daily" pivot formula (default), or the
"Fibonacci" formula.  Included are MidPivot lines which can be turned
on/off.

The first item in the simplified Indicator Window is the indicator "On"
switch with default of "true".  To turn the indicator display "Off"
you do no have to remove the indicator from your chart indicators list.
Instead, just edit the indicator to select "false" to turn it off.

                                    - Traderathome, February 26, 2009
---------------------------------------------------------------------*/

#property  indicator_chart_window

extern bool   Indicator_On?                 = true;
extern int    Daily_or_Fibonacci_Pivots_12  = 1;
extern int    Day_Week_Month_123            = 1;
extern bool   Margin_Prices?                = true;
extern bool   Line_Prices?                  = false;
extern int    MoveLabels_LR_DecrIncr        = 0;
extern color  Resistances                   = Red;
extern color  CentralPivot                  = Magenta;
extern color  Supports                      = LimeGreen;
extern color  MidPivots                     = Olive;
extern bool   Show_MidPivots?               = true;
extern int    Pivots_LineStyle_01234        = 2;     
extern int    SolidLine_Thickness_12345     = 1;
extern color  Labels_color                  = DarkGray;
extern int    Labels_Fontsize               = 8; 
extern int    Labels_Fontstyle_123          = 1;

//+-------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+-------------------------------------------------------------------+
int init()
   {
   return(0);
   }
     
//+-------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+-------------------------------------------------------------------+  
int deinit()
   {    
   int obj_total= ObjectsTotal();  
   for (int k= obj_total; k>=0; k--) 
      {
      string name= ObjectName(k);    
      if (StringSubstr(name,0,11)=="[PivotsMWD]") { ObjectDelete(name); }
      }   
   return(0);
   }
   
//+-------------------------------------------------------------------+
//| Custom indicator start function                               |
//+-------------------------------------------------------------------+   
int start()
   {
   if (Indicator_On? == false){return(0);}
   int CalcPeriod;
	string pLineStr,pStr,p,s1Str,S1LineStr,s1,r1Str,R1LineStr,r1,s2Str,S2LineStr,s2,r2Str,R2LineStr,r2; 
	string s3Str,S3LineStr,s3,r3Str,R3LineStr,r3;
 
   if( Day_Week_Month_123   == 3)
      { 
      CalcPeriod = 43200;
      pLineStr = "Monthly Pivot ";if( Daily_or_Fibonacci_Pivots_12  == 2){pLineStr = "Monthly Fibonacci Pivot ";}
      S1LineStr = "Monthly S1 ";
      R1LineStr = "Monthly R1 ";
      S2LineStr = "Monthly S2 ";
      R2LineStr = "Monthly R2 ";
      S3LineStr = "Monthly S3 ";
      R3LineStr = "Monthly R3 ";           
      }
   if( Day_Week_Month_123   == 2)
      {
      CalcPeriod = 10080;
      pLineStr = "Weekly Pivot ";if( Daily_or_Fibonacci_Pivots_12  == 2){pLineStr = "Weekly Fibonacci Pivot ";}
      S1LineStr = "Weekly S1 ";
      R1LineStr = "Weekly R1 ";
      S2LineStr = "Weekly S2 ";
      R2LineStr = "Weekly R2 ";
      S3LineStr = "Weekly S3 ";
      R3LineStr = "Weekly R3 ";     
      }
   if( Day_Week_Month_123   == 1 &&   Daily_or_Fibonacci_Pivots_12  == 1)
      {
      CalcPeriod = 1440;
      pLineStr = "Daily Pivot ";
      S1LineStr = "Daily S1 ";
      R1LineStr = "Daily R1 ";
      S2LineStr = "Daily S2 ";
      R2LineStr = "Daily R2 ";
      S3LineStr = "Daily S3 ";
      R3LineStr = "Daily R3 ";
      }
   if( Day_Week_Month_123   == 1 &&   Daily_or_Fibonacci_Pivots_12  == 2)
      {   
      CalcPeriod = 1440;
      pLineStr = "Fibonacci Pivot ";
      S1LineStr = "Fibonacci S1 ";
      R1LineStr = "Fibonacci R1 ";
      S2LineStr = "Fibonacci S2 ";
      R2LineStr = "Fibonacci R2 ";
      S3LineStr = "Fibonacci S3 ";
      R3LineStr = "Fibonacci R3 ";
      }
      
   int shift,dow; 
	double HiPrice,LoPrice,Range,ClosePrice,Pivot,R1,S1,R2,S2,R3,S3 ;
   shift	= iBarShift(NULL,CalcPeriod,Time[0])+ 1;	// default = one period ago	 
	datetime StartTime	= iTime(NULL,CalcPeriod,shift);	 
	dow = TimeDayOfWeek(StartTime);string dowStr;
	   switch(dow)
	   {
	   case 5:	 
         dowStr = "Sunday  ";
         break;
      case 0:
         shift	= iBarShift(NULL,CalcPeriod,Time[0])+2;	// two periods ago or Friday value	 
         dowStr = "Monday  ";     
         break;
      case 1:
         dowStr = "Tuesday  ";
         break;
      case 2:
         dowStr = "Wednesday  ";
         break;
      case 3:
         dowStr = "Thursday  ";
         break;
      case 4:
         dowStr = "Friday  "; 
         break; 
      } 	 
  
   if(Day_Week_Month_123 > 1)dowStr="";
 	ClosePrice  = NormalizeDouble(iClose(NULL,CalcPeriod,shift),4);
   HiPrice     = NormalizeDouble (iHigh(NULL,CalcPeriod,shift),4); 
   LoPrice     = NormalizeDouble (iLow(NULL,CalcPeriod,shift),4);
   Range       = HiPrice -  LoPrice;
   Pivot       = NormalizeDouble((HiPrice+LoPrice+ClosePrice)/3,4);
      
   if( Daily_or_Fibonacci_Pivots_12  == 2)
      {
      R1 = Pivot + (Range  * 0.382);
      S1 = Pivot - (Range  * 0.382); 
      R2 = Pivot + (Range  * 0.618);
      S2 = Pivot - (Range  * 0.618);
      R3 = Pivot +  Range ;  
      S3 = Pivot -  Range ;
      }
   else
      {   
      R1 = (2*Pivot)-LoPrice;
      S1 = (2*Pivot)-HiPrice;
      R2 = Pivot+(R1-S1);
      S2 = Pivot-(R1-S1); 
      R3 = ( 2.0 * Pivot) + ( HiPrice - ( 2.0 * LoPrice ) );
      S3 = ( 2.0 * Pivot) - ( ( 2.0 * HiPrice ) - LoPrice );
      }

   drawLine("R3", R3, Resistances); 
   drawLabel( R3LineStr,R3,Labels_color);
   drawLine("R2", R2, Resistances);
   drawLabel(R2LineStr,R2,Labels_color);
   drawLine("R1", R1, Resistances);
   drawLabel(R1LineStr,R1,Labels_color);
   drawLine("PIVOT", Pivot, CentralPivot);
   drawLabel(dowStr+pLineStr, Pivot,Labels_color);
   drawLine("S1", S1,Supports);
   drawLabel(S1LineStr,S1,Labels_color);
   drawLine("S2", S2,Supports);
   drawLabel(S2LineStr,S2,Labels_color);
   drawLine("S3", S3,Supports);
   drawLabel(S3LineStr ,S3,Labels_color);

   if(Show_MidPivots?)
      {
      drawLine("MR3", (R2+R3)/2, MidPivots); 
      drawLabel("MR3",(R2+R3)/2,Labels_color);
      drawLine("MR2", (R1+R2)/2, MidPivots); 
      drawLabel("MR2",(R1+R2)/2,Labels_color); 
      drawLine("MR1", (Pivot+R1)/2, MidPivots); 
      drawLabel("MR1",(Pivot+R1)/2,Labels_color);
      drawLine("MS1", (Pivot+S1)/2, MidPivots); 
      drawLabel("MS1",(Pivot+S1)/2,Labels_color);
      drawLine("MS2", (S1+S2)/2, MidPivots); 
      drawLabel("MS2",(S1+S2)/2,Labels_color);
      drawLine("MS3", (S2+S3)/2, MidPivots); 
      drawLabel("MS3",(S2+S3)/2,Labels_color);
      }
   
       
   return(0);
   } 

//+-------------------------------------------------------------------+
//| Subroutine to draw line labels                                    |                                                        
//+-------------------------------------------------------------------+
void drawLabel(string text, double level, color Color)
    {
    int L = (WindowFirstVisibleBar() /2) -  MoveLabels_LR_DecrIncr;
    string Font;
    string name = "[PivotsMWD] " + text + " Label"; 
    if(ObjectFind(name) != 0)
       {
       if (Labels_Fontstyle_123  <= 1){Font = "Arial";}
       if (Labels_Fontstyle_123  == 2){Font = "Arial Bold";}
       if (Labels_Fontstyle_123  >= 3){Font = "Arial Black";}
       ObjectCreate(name, OBJ_TEXT, 0, Time[L], level);       
       ObjectSet(name, OBJPROP_FONTSIZE, Labels_Fontsize); 
       ObjectSet(name, OBJPROP_COLOR, Color );
       ObjectSetText(name, text, Labels_Fontsize, Font);
       }
       else
       {
       ObjectMove(name, 0, Time[L], level);
       }     
    if (Line_Prices? == true) text= text + ":  "+DoubleToStr(level, Digits); 
    ObjectSetText(name, text, Labels_Fontsize , Font, Color);        
    }

//+-------------------------------------------------------------------+
//| Sub-routing to draw lines                                         |                                                        
//+-------------------------------------------------------------------+
void drawLine(string text, double level, color Color)
    {
    int AA = WindowFirstVisibleBar(); 
    int a = Pivots_LineStyle_01234;
    int b = SolidLine_Thickness_12345;
    int c =1; if (a==0&&b>1)c=b;
    string name= "[PivotsMWD] " + text + " Line";
    int Z= OBJ_TREND;
    if(  Margin_Prices? == true){Z = OBJ_HLINE;}   
    if(ObjectFind(name) != 0)
       {
       ObjectCreate(name, Z, 0, AA, level, Time[0], level);                            
       ObjectSet(name, OBJPROP_STYLE, Pivots_LineStyle_01234);              
       ObjectSet(name, OBJPROP_WIDTH, c); 
       ObjectSet(name, OBJPROP_COLOR, Color);                  
       }
       else
       {
      // ObjectMove(name, 0, Time[0], level);
       
       ObjectMove  (name, 1, Time[0],level);
       ObjectMove  (name, 0, AA, level);
       
       }    
    }

//+----------------------- End of Program ----------------------------+