//+------------------------------------------------------------------+
//|                                           |
//|                                               Yuriy Tokman (YTG) |
//|                                               http://ytg.com.ua/ |
//+------------------------------------------------------------------+
#property copyright "Yuriy Tokman (YTG)"
#property link      "http://ytg.com.ua/"
#property version   "1.00"
#property strict
#property indicator_separate_window

#property indicator_buffers 5
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Blue
#property indicator_color4 Red
#property indicator_color5 Lime

extern ENUM_TIMEFRAMES    TimeFrame    = PERIOD_CURRENT; // Time frame
extern int       FastEMA   = 5;
extern int       SlowEMA   = 12;
extern int       RSIPeriod = 21;
input  int       shift     = 1;

extern bool   Alerts=true;
extern string Text_BUY="BUY signal text";
extern string Text_SELL = "SELL signals text";
extern bool   Send_Mail = false;
extern string subject="subject text";
extern bool Send_Notification=false;
extern bool               Interpolate  = true;           // Interpolate


//---- buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];
double ExtMapBuffer3[];
double ExtMapBuffer4[];
double ExtMapBuffer5[];

bool metka_buy=false;
bool metka_sell=false;
string text="",name="";
string indicatorFileName;
bool   returnBars;
   #define _mtfCall(_buff,_y) iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,FastEMA,SlowEMA,RSIPeriod,shift,Alerts,Text_BUY,Text_SELL,Send_Mail,subject,Send_Notification,_buff,_y)
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   name="RSI_MA_Trade_Sist";
   IndicatorShortName(name);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexLabel(0,"Fast EMA ");
   SetIndexDrawBegin(0,FastEMA);
   SetIndexBuffer(1,ExtMapBuffer2);
   SetIndexLabel(1,"Slow EMA ");
   SetIndexDrawBegin(1,SlowEMA);
   SetIndexStyle(2,DRAW_ARROW);
   SetIndexArrow(2,217);
   SetIndexBuffer(2,ExtMapBuffer3);
   SetIndexEmptyValue(2,0.0);
   SetIndexLabel(2,"BUY Signal ");
   SetIndexStyle(3,DRAW_ARROW);
   SetIndexArrow(3,218);
   SetIndexBuffer(3,ExtMapBuffer4);
   SetIndexEmptyValue(3,0.0);
   SetIndexLabel(3,"SELL Signal ");
   SetIndexBuffer(4,ExtMapBuffer5);
   SetIndexLabel(4,"RSI ");
   SetIndexDrawBegin(4,RSIPeriod);
//---
      indicatorFileName = WindowExpertName();
      returnBars        = TimeFrame==-99;
      TimeFrame         = MathMax(TimeFrame,_Period);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   GetDellName();
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int limit=MathMin(rates_total-prev_calculated+1,rates_total-1);
            if (returnBars) { ExtMapBuffer1[0] = MathMin(limit,rates_total-1); return(rates_total); }
            if (TimeFrame != _Period)
            {
               limit = (int)MathMax(limit,MathMin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/_Period));
               for(int i=limit; i>=0; i--)
               {
                  int y = iBarShift(NULL,TimeFrame,time[i]);
                  int x = (i<rates_total-1) ? iBarShift(NULL,TimeFrame,time[i+1]) : y;
                     ExtMapBuffer1[i] = _mtfCall(0,y);
                     ExtMapBuffer2[i] = _mtfCall(1,y);
                     ExtMapBuffer5[i] = _mtfCall(4,y);
                     ExtMapBuffer3[i] = (x!=y) ? _mtfCall(2,y) : 0;
                     ExtMapBuffer4[i] = (x!=y) ? _mtfCall(3,y) : 0;
                  
                     //
                     //
                     //
                     //
                     //
                  
                     if (!Interpolate || (i>0 && y==iBarShift(NULL,TimeFrame,time[i-1]))) continue;
                        #define _interpolate(buff) buff[i+k] = buff[i]+(buff[i+n]-buff[i])*k/n
                        int n,k; datetime ctime = iTime(NULL,TimeFrame,y);
                           for(n = 1; (i+n)<rates_total && time[i+n] >= ctime; n++) continue;	
                           for(k = 1; k<n && (i+n)<rates_total && (i+k)<rates_total; k++) 
                           {
                              _interpolate(ExtMapBuffer1);
                              _interpolate(ExtMapBuffer2);
                              _interpolate(ExtMapBuffer5);
                           }                              
               }
               return(rates_total);
            }
  
//---
   double rsi_sig=0,fast_sig=0,slow_sig=0,price_OP=0;
   double rsi_sig_prev=0,fast_sig_prev=0,slow_sig_prev=0;
   string txt=WindowExpertName()+" "+Symbol()+"  "+GetNameTF()+"  ";
//---
   for(int i=limit; i>=0 && !IsStopped(); i--)
     {
      ExtMapBuffer1[i] = iMA(NULL,0,FastEMA,0,MODE_EMA,PRICE_CLOSE,i);
      ExtMapBuffer2[i] = iMA(NULL,0,SlowEMA,0,MODE_EMA,PRICE_CLOSE,i);
      ExtMapBuffer5[i] = iMA(NULL,0,SlowEMA,0,MODE_EMA,PRICE_CLOSE,i) - (50 - iRSI(NULL, 0, RSIPeriod, PRICE_CLOSE,i))*Point;
      ExtMapBuffer3[i] = 0;
      ExtMapBuffer4[i] = 0;

      fast_sig = iMA(NULL,0,FastEMA,0,MODE_EMA,PRICE_CLOSE,i+shift);
      slow_sig = iMA(NULL,0,SlowEMA,0,MODE_EMA,PRICE_CLOSE,i+shift);
      rsi_sig  = iRSI(NULL, 0, RSIPeriod, PRICE_CLOSE,i+shift);

      fast_sig_prev = iMA(NULL,0,FastEMA,0,MODE_EMA,PRICE_CLOSE,i+shift+1);
      slow_sig_prev = iMA(NULL,0,SlowEMA,0,MODE_EMA,PRICE_CLOSE,i+shift+1);
      rsi_sig_prev  = iRSI(NULL, 0, RSIPeriod, PRICE_CLOSE,i+shift+1);

      if(((fast_sig>slow_sig && rsi_sig>50 && fast_sig_prev<=slow_sig_prev)
         || (fast_sig>slow_sig && rsi_sig>50 && rsi_sig_prev<=50)) && !metka_buy)
        {
         metka_sell= false;
         metka_buy = true;
         ExtMapBuffer3[i]=slow_sig-iATR(Symbol(),0,10,i)/2;
         price_OP=Bid;
         text=" Price Open = "+DoubleToStr(price_OP,Digits);
         Label("ytg_name_label","Buy,"+text,1,3,15,10,"Arial",Green,name);
         if(i==0 && NewBar())
           {
            if(Alerts)Alert(txt+Text_BUY+text);
            if(Send_Mail)SendMail(txt+subject,Text_BUY+text);
            if(Send_Notification)SendNotification(txt+Text_BUY+text);
           }
        }
      if(((fast_sig<slow_sig && rsi_sig<50 && fast_sig_prev>=slow_sig_prev)
         || (fast_sig<slow_sig && rsi_sig<50 && rsi_sig_prev>=50)) && !metka_sell)
        {
         metka_sell= true;
         metka_buy = false;
         ExtMapBuffer4[i]=slow_sig+iATR(Symbol(),0,10,i)/2;
         price_OP=Ask;
         text=" Price Open = "+DoubleToStr(price_OP,Digits);
         Label("ytg_name_label","Sell,"+text,3,3,15,10,"Arial",Red,name);
         if(i==0 && NewBar())
           {
            if(Alerts)Alert(txt+Text_SELL+text);
            if(Send_Mail)SendMail(txt+subject,Text_SELL+text);
            if(Send_Notification)SendNotification(txt+Text_SELL+text);
           }
        }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
bool NewBar(int TF=0)
  {
   static datetime NewTime=0;
   if(NewTime!=iTime(Symbol(),TF,0))
     {
      NewTime=iTime(Symbol(),TF,0);
      return(true);
     }
   return(false);
  }
//----
string GetNameTF(int tTimeFrame=0) 
  {
   if(tTimeFrame==0) tTimeFrame=Period();
   switch(tTimeFrame) 
     {
      case PERIOD_M1:  return("M1");
      case PERIOD_M5:  return("M5");
      case PERIOD_M15: return("M15");
      case PERIOD_M30: return("M30");
      case PERIOD_H1:  return("H1");
      case PERIOD_H4:  return("H4");
      case PERIOD_D1:  return("Daily");
      case PERIOD_W1:  return("Weekly");
      case PERIOD_MN1: return("Monthly");
      default:         return("UnknownPeriod");
     }
  }
//+----------------------------------------------------------------------+
//| Описание: Создание текстовой метки                                   | 
//| Автор:    Юрий Токмань                                               |
//| e-mail:   yuriytokman@gmail.com                                      |
//+----------------------------------------------------------------------+
void Label(string name_label,           //Имя объекта.
           string text_label,           //Текст обьекта. 
           int corner = 2,              //Hомер угла привязки 
           int x = 3,                   //Pасстояние X-координаты в пикселях 
           int y=15,                    //Pасстояние Y-координаты в пикселях 
           int font_size = 10,          //Размер шрифта в пунктах.
           string font_name = "Arial",  //Наименование шрифта.
           color text_color = LimeGreen,//Цвет текста.
           string Window_Find="NULL"
           )
  {
   if(ObjectFind(name_label)!=-1) ObjectDelete(name_label);
   ObjectCreate(name_label,OBJ_LABEL,WindowFind(Window_Find),0,0,0,0);
   ObjectSet(name_label,OBJPROP_CORNER,corner);
   ObjectSet(name_label,OBJPROP_XDISTANCE,x);
   ObjectSet(name_label,OBJPROP_YDISTANCE,y);
   ObjectSetText(name_label,text_label,font_size,font_name,text_color);
  }
//----
void GetDellName(string name_n="ytg_")
  {
   string vName;
   for(int i=ObjectsTotal()-1; i>=0;i--)
     {
      vName=ObjectName(i);
      if(StringFind(vName,name_n)!=-1) ObjectDelete(vName);
     }
  }
//+------------------------------------------------------------------+
