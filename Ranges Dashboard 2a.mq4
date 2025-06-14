//+------------------------------------------------------------------+
//|                                          Ranges Dashboard.mq4    |
//+------------------------------------------------------------------+

#property indicator_separate_window  

#property indicator_buffers 0
#property indicator_minimum 0
#property indicator_maximum 1
extern string _            = "PAIRS";
extern string pairs        = "GBPUSD;EURUSD;EURJPY;USDJPY;USDCHF;USDCAD;NZDUSD;AUDUSD;GOLD;";
extern string timeFrames   = "D1;W1;MN1";
extern color  ColorUp      = Lime;
extern color  ColorNeutral = Silver ;
extern color  ColorDown    = Red ;
extern color  ValueColor   = White;
extern int    ValueSize    = 30;
extern string ValueFont    = "Verdana Bold";
extern int    iMode  = 0;

extern bool show_Ranges = true ; 
extern bool show_SCORE = false ; 

int      window;  
int      totalPairs;
int      totalTimeFrames;
int      totalLabels;
int      aTimes[];
string   aPairs[];
string   sTimes[];
color    ColorLabels  = White;
color    Ranges_color;
string   labelNames;
string   Ranges;
string   shortName;
int      corner;
int       INC_UP ;
int       INC_UC ;
int       INC_DN;

bool   ShowCount    = true;
string Pair0    = ""      ;
string Pair1    = ""      ;
string Pair2    = ""      ;
string Pair3    = ""      ;
string Pair4    = ""      ;
string Pair5    = ""      ;
string Pair6    = ""      ;
string Pair7    = ""      ;
string Pair8    = ""      ;

double cVal = 0, pVal = 0;

double xClose;
double xOpen;
color  ColorPrice ; 
double point  ;
int    xPoint ;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int init()
{

   corner     = 0;
   shortName  = MakeUniqueName("Ranges Dashboard ","");
   IndicatorShortName(shortName);

    
      pairs = StringUpperCase(StringTrimLeft(StringTrimRight(pairs)));
      if (StringSubstr(pairs,StringLen(pairs),1) != ";")
      pairs = StringConcatenate(pairs,";");
                                  

         bool isMini = IsMini();            
         int  s      = 0;
         int  i      = StringFind(pairs,";",s);
         int time;
         string current;
        
         
            while (i > 0)
            {
               current = StringSubstr(pairs,s,i-s);
               if (isMini) current = StringConcatenate(current,"m");
              time    = stringToTimeFrame(current);
               current = StringSubstr(pairs,s,i-s);
               if (isMini) current = StringConcatenate(current,"m");
               if (iClose(current,0,0) > 0) {
               ArrayResize(aPairs,ArraySize(aPairs)+1);
                aPairs[ArraySize(aPairs)-1] = current; }
                 s = i + 1;
                i = StringFind(pairs,";",s);
                                                                                   
                                     
            }
    

      timeFrames = StringUpperCase(StringTrimLeft(StringTrimRight(timeFrames)));
      if (StringSubstr(timeFrames,StringLen(timeFrames),1) != ";")
       timeFrames = StringConcatenate(timeFrames,";");

                                                  
         s = 0;
         i = StringFind(timeFrames,";",s);
         //int time;
          while (i > 0)
            {
           current = StringSubstr(timeFrames,s,i-s);
           time    = stringToTimeFrame(current);
           if (time > 0) {
           ArrayResize(sTimes,ArraySize(sTimes)+1);
           ArrayResize(aTimes,ArraySize(aTimes)+1);
           sTimes[ArraySize(sTimes)-1] = TimeFrameToString(time); 
           aTimes[ArraySize(aTimes)-1] = time; }
           s = i + 1;
           i = StringFind(timeFrames,";",s);
            }

   

      totalTimeFrames = ArraySize(aTimes);
      totalPairs      = ArraySize(aPairs);
      totalLabels     = 0;
      
      
Pair0    = aPairs[0];
Pair1    = aPairs[1];
Pair2    = aPairs[2];
Pair3    = aPairs[3];
Pair4    = aPairs[4];
Pair5    = aPairs[5];
Pair6    = aPairs[6];
Pair7    = aPairs[7];
Pair8    = aPairs[8];
      
   return(0);
   
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
   while (totalLabels>0) { ObjectDelete(StringConcatenate(labelNames,totalLabels)); totalLabels--;}
     
   return(0);
}


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int start()
{

ObjectsDeleteAll( window, 21);
ObjectsDeleteAll( window, 22);
ObjectsDeleteAll( window, 23);
int m,n;
int i,k;
   window      = WindowFind(shortName);
   totalLabels = 0;
    for (i=0,m=30; i < totalPairs;      i++, m+=25){
   INC_UP = 0;
   INC_UC = 0;
   INC_DN = 0; 
   for (k=0,n=170; k < totalTimeFrames; k++, n+=80){
   showPair(aPairs[i],aTimes[k],sTimes[k],m,n);}
   if (ShowCount)  DoShowCount(m,n); }             
   if (Pair1 == "") Pair1 = Symbol();
    
     
     
   return(0);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


void DoShowCount( int xdistance, int ydistance )
{

int x_Pair, y_Pair , y_Inc ;

x_Pair = 10;
y_Pair = 40;
y_Inc  = 25;


double PERp,PERC,PER;
int yInc = -125;

  PER=INC_UP; 
  PERC=PER*100;
  PERp=PERC/totalTimeFrames;
  string PER_Str =DoubleToStr(PERp,Point);
   
color xColor = Silver ;
 
if( PERp > 50) { xColor = LimeGreen ; }
else if( PERp < 50 ) { xColor = Crimson ; }


 if(ValueSize>12) ValueSize=12;
 
  if(show_SCORE){  
  setObject(next(),PER_Str,525,xdistance+10, xColor ,ValueFont,10,0);}
  setObject(next(),Pair0,x_Pair,40, ValueColor ,ValueFont,ValueSize);
  setObject(next(),Pair1,x_Pair,65, ValueColor ,ValueFont,ValueSize);
  setObject(next(),Pair2,x_Pair,90, ValueColor ,ValueFont,ValueSize);
  setObject(next(),Pair3,x_Pair,115, ValueColor ,ValueFont,ValueSize);
  setObject(next(),Pair4,x_Pair,140, ValueColor ,ValueFont,ValueSize);
  setObject(next(),Pair5,x_Pair,165, ValueColor ,ValueFont,ValueSize);
  setObject(next(),Pair6,x_Pair,190, ValueColor ,ValueFont,ValueSize);
  setObject(next(),Pair7,x_Pair,215, ValueColor ,ValueFont,ValueSize);
  setObject(next(),Pair8,x_Pair,240, ValueColor ,ValueFont,ValueSize);


   setObject(next(),340,3, ValueColor ,ValueFont,ValueSize);
   setObject(next(),"PAIR",x_Pair,18, ValueColor ,ValueFont,ValueSize);
   setObject(next(),sTimes[0],200,18, ValueColor ,ValueFont,ValueSize);
   setObject(next(),sTimes[1],280,18, ValueColor ,ValueFont,ValueSize);
   setObject(next(),sTimes[2],360,18, ValueColor ,ValueFont,ValueSize);
   setObject(next(),sTimes[3],440,18, ValueColor ,ValueFont,ValueSize);
   setObject(next(),sTimes[4],520,18, ValueColor ,ValueFont,ValueSize);
   setObject(next(),sTimes[5],600,18, ValueColor ,ValueFont,ValueSize);
   setObject(next(),sTimes[6],680,18, ValueColor ,ValueFont,ValueSize);
   setObject(next(),sTimes[7],760,18, ValueColor ,ValueFont,ValueSize);
   setObject(next(),sTimes[8],840,18, ValueColor ,ValueFont,ValueSize);

     

x_Pair = x_Pair + 90 ;

setObject(next(),"Price",x_Pair,18, ValueColor ,ValueFont,ValueSize);
   
if( Pair0 != "" ) { DoPrice( Pair0, x_Pair  , y_Pair ) ; }
if( Pair1 != "" ) { y_Pair = y_Pair + y_Inc ; DoPrice( Pair1, x_Pair  , y_Pair ) ; }
if( Pair2 != "" ) { y_Pair = y_Pair + y_Inc ; DoPrice( Pair2, x_Pair  , y_Pair ) ; }
if( Pair3 != "" ) { y_Pair = y_Pair + y_Inc ; DoPrice( Pair3, x_Pair  , y_Pair ) ; }
if( Pair4 != "" ) { y_Pair = y_Pair + y_Inc ; DoPrice( Pair4, x_Pair  , y_Pair ) ; }
if( Pair5 != "" ) { y_Pair = y_Pair + y_Inc ; DoPrice( Pair5, x_Pair  , y_Pair ) ; }
if( Pair6 != "" ) { y_Pair = y_Pair + y_Inc ; DoPrice( Pair6, x_Pair  , y_Pair ) ; }
if( Pair7 != "" ) { y_Pair = y_Pair + y_Inc ; DoPrice( Pair7, x_Pair  , y_Pair ) ; }
if( Pair8 != "" ) { y_Pair = y_Pair + y_Inc ; DoPrice( Pair8, x_Pair  , y_Pair ) ; }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+



void DoPrice( string dpSymbol, int dp_xAxis, int dp_yAxis )
{
   xClose      = iClose(dpSymbol,PERIOD_D1,0);
   xOpen       = iOpen(dpSymbol,PERIOD_D1,0);
   
   if(xClose > xOpen) { ColorPrice = Lime ; } else {
   if(xClose < xOpen) { ColorPrice = Red ; } else {ColorPrice = Gray ; } }

   point = MarketInfo(dpSymbol,MODE_POINT);  
   
   if ( point == 0.01 )  {xPoint = 2 ; } else { xPoint = 4 ;  } 

   setObject(next(),DoubleToStr(xClose,xPoint),dp_xAxis, dp_yAxis, ColorPrice ,ValueFont,ValueSize);   
}


//+------------------------------------------------------------------+

void showPair(string pair, int timeFrame,string label, int xdistance, int ydistance)
{

   DoWork(pair,timeFrame,1) ;
   
    double high,low;

    if(show_Ranges){  
    high = iHigh(pair,timeFrame,0);
    low  = iLow(pair,timeFrame,0);
    Ranges = iHigh(pair,timeFrame,0) - iLow(pair,timeFrame,0);
    }
   
   
   DoWork(pair,timeFrame,0) ;   
   
 /*  if (Ranges == 0.0) { INC_UC = INC_UC +1 ; Ranges_color = ColorNeutral;} else {
     if (Ranges < 0.0) { INC_DN = INC_DN +1 ;   Ranges_color = ColorDown;} else {
                      INC_UP = INC_UP +1 ;     Ranges_color = ColorUp;  } } 
 */  
    if (Ranges == 0.0) ObjectSetText((pair+timeFrame), DoubleToStr(Ranges, high-low), ValueSize, ValueFont, ColorNeutral);
    else { 
      if (Ranges > 0.0) ObjectSetText((pair+timeFrame), DoubleToStr((high-low)/Point,0), ValueSize, ValueFont, ColorUp);
      else ObjectSetText((pair+timeFrame), DoubleToStr((high-low)/Point,0), ValueSize, ValueFont, ColorDown);
   }
   
   setLabel(" "  ,xdistance+10,ydistance+30," ",Ranges_color,Ranges);
       
  }

//+------------------------------------------------------------------+
//| Custom functions and procedures                                  |
//+------------------------------------------------------------------+

string next() { totalLabels++; return(totalLabels); }  


void setLabel(string text,int x,int y,string sarv, color theColor, string arrow)
{
    
  setObject(next(),arrow                  ,y,x,theColor,"Wingdings",14,0);
      
 }              
             

void setObject(string name,string text,int x,int y,color theColor, string font = "Verdana",int size=10,int angle=0)
{
   string labelName = StringConcatenate(labelNames,name);

  
      if (ObjectFind(labelName) == -1)
          {
             ObjectCreate(labelName,OBJ_LABEL,window,0,0);
             ObjectSet(labelName,OBJPROP_CORNER,corner);
             if (angle != 0)
             ObjectSet(labelName,OBJPROP_ANGLE,angle);
          }               
       ObjectSet(labelName,OBJPROP_XDISTANCE,x);
       ObjectSet(labelName,OBJPROP_YDISTANCE,y);
       ObjectSetText(labelName,text,size,font,theColor);
}


int stringToTimeFrame(string tfs)
{
   int tf=0;
       tfs = StringTrimLeft(StringTrimRight(StringUpperCase(tfs)));
         if (tfs=="M1" || tfs=="1")     tf=PERIOD_M1;
         if (tfs=="M5" || tfs=="5")     tf=PERIOD_M5;
         if (tfs=="M15"|| tfs=="15")    tf=PERIOD_M15;
         if (tfs=="M30"|| tfs=="30")    tf=PERIOD_M30;
         if (tfs=="H1" || tfs=="60")    tf=PERIOD_H1;
         if (tfs=="H4" || tfs=="240")   tf=PERIOD_H4;
         if (tfs=="D1" || tfs=="1440")  tf=PERIOD_D1;
         if (tfs=="W1" || tfs=="10080") tf=PERIOD_W1;
         if (tfs=="MN1" || tfs=="43200") tf=PERIOD_MN1;
  return(tf);
}
string TimeFrameToString(int tf)
{
   string tfs;
   switch(tf) {
      case PERIOD_M1:  tfs="M1"  ; break;
      case PERIOD_M5:  tfs="M5"  ; break;
      case PERIOD_M15: tfs="M15" ; break;
      case PERIOD_M30: tfs="M30" ; break;
      case PERIOD_H1:  tfs="H1"  ; break;
      case PERIOD_H4:  tfs="H4"  ; break;
      case PERIOD_D1:  tfs="D1"  ; break;
      case PERIOD_W1:  tfs="W1"  ; break;
      case PERIOD_MN1: tfs="MN1";
   }
   return(tfs);
}

string StringUpperCase(string str)
{
   string   s = str;
   int      lenght = StringLen(str) - 1;
   int      ichar;
   
   while(lenght >= 0)
      {
         ichar = StringGetChar(s, lenght);
                 
         if((ichar > 96 && ichar < 123) || (ichar > 223 && ichar < 256))
                  s = StringSetChar(s, lenght, ichar - 32);
          else 
              if(ichar > -33 && ichar < 0)
                  s = StringSetChar(s, lenght, ichar + 224);
         lenght--;
   }
  
   
   return(s);
}

string MakeUniqueName(string first, string rest)
{
   string result = first+(MathRand()%1001)+rest;

   while (WindowFind(result)> 0)
          result = first+(MathRand()%1001)+rest;
   return(result);
}
bool IsMini()
{
   if (StringFind(Symbol(),"m") > -1)
         return(true);
   else  return(false);    
}


  
//+------------------------------------------------------------------+

void DoWork( string myPair, int myPeriod , int p )  
{
while(true)
{
break ;  }
                                        
}