/*///+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
Три методики расчёта IBS,RSI,CCI все равноправны в упраляемости, у всех есть переворот расчёта, 
коэффициент относительности и аплиедпрайс ( для IBS это не значащий параметр, но стоит для симметрии параметров).
Отрисовка линий идёт как средняя от трёх IBS,RSI,CCI .
Внутри как прямого так и перевёрнутого можно в свою очередь перевернуть одину из методик,
те они не зависимы как по перевороту так и по относительности.
Так же через Shift линии можно двигать (Shift не может быть отрицательной).
"вариант_1" управляет вариантами расчёта 1 или 2. По умолчанию стоит 2 --> "вариант_1 = false".
"positive" управляет зеркальностью отображения. По умолчанию стоит нормальное отображение --> "positive = true".
 
Методы скользящих:
 
  MODE_SMA 0 Простое скользящее среднее 
  MODE_EMA 1 Экспоненциальное скользящее среднее 
  MODE_SMMA 2 Сглаженное скользящее среднее 
  MODE_LWMA 3 Линейно-взвешенное скользящее среднее 
 
app_price:
 
  PRICE_CLOSE    0 Цена закрытия 
  PRICE_OPEN     1 Цена открытия 
  PRICE_HIGH     2 Максимальная цена 
  PRICE_LOW      3 Минимальная цена 
  PRICE_MEDIAN   4 Средняя цена, (high+low)/2 
  PRICE_TYPICAL  5 Типичная цена, (high+low+close)/3 
  PRICE_WEIGHTED 6 Взвешенная цена закрытия, (high+low+close+close)/4   
 
модификация индикатора WKBIBS, по просьбе Martingeila 
/*///+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
//+------------------------------------------------------------------+
//|                                               IBS_RSI_CCI_v3.mq4 |
//|                                                            Urain |
//+------------------------------------------------------------------+
#property copyright "Urain"
#property link      ""
 
#property indicator_separate_window
//#property indicator_minimum 0
//#property indicator_maximum 100
#property indicator_buffers 3
#property indicator_color1 Yellow  // буфер 0 - сигнальная линия
#property indicator_color2 Red     // буфер 1 - на продажу верхняя линия
#property indicator_color3 Blue    // буфер 2 - на покупку нижняя линия
#property indicator_level1 0.0
//---- input parameters---------------------------------------
extern int           per_IBS  =   5;
extern int            глушка  =   0;
extern double       koef_ibs  = 7.0;
extern bool              ibs  =true;
 
extern int           per_RSI  =  14;
extern int     app_price_RSI  =   0;  //app_price
extern double       koef_rsi  = 9.0;
extern bool              rsi  =true;
 
extern int           per_CCI  =  14;
extern int     app_price_CCI  =   0;  //app_price
extern double       koef_cci  = 1.0;
extern bool              cci  =true;
extern int            Shift  =   0;
extern int             porog  =  50;
//---- input parameters---------------------------------------
extern bool             вариант_1 =false;  
extern bool             positive  =true; 
extern int       RangePeriod_VKWB  = 25;
extern int       SmoothPeriod_VKWB = 3;
extern int       SmoothMode_VKWB   = 0;//Методы скользящих           
 
//---- buffers
double E0[], E1[], E2[], E3[], E4[], E5[], E6[];
int kibs=-1,kcci=-1,krsi=-1,posit=-1,xma1=1;
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   IndicatorBuffers(7); 
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,E0);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,E5);
   SetIndexDrawBegin(0,SmoothPeriod_VKWB);
   SetIndexStyle(2,DRAW_LINE);
   SetIndexBuffer(2,E6);
   SetIndexDrawBegin(1,SmoothPeriod_VKWB);   
   SetIndexBuffer(3,E1);   
   SetIndexBuffer(4,E2);
   SetIndexBuffer(5,E3);
   SetIndexBuffer(6,E4);  
   
   if(cci)kcci=1; if(rsi)krsi=1; if(ibs)kibs=1; 
   if(вариант_1)xma1=0; if(positive)posit=1;   
//----       
   return(0);
  }
//+------------------------------------------------------------------+
int deinit(){return(0);}
//+------------------------------------------------------------------+
int start()
  {
   int  cb=IndicatorCounted();
//----
   int i,limit,limit1,limit2,n_max,n_min;
   if(cb==0){limit=Bars-1; limit1=Bars-RangePeriod_VKWB; limit2=limit1-SmoothPeriod_VKWB;}
   if(cb>0) {limit=Bars-cb; limit1=Bars-cb; limit2=limit1;}  
   limit--;limit1--;limit2--;
   
   Delitel( E2, limit);
   for(i=limit;i>=0;i--)
      {E1[i]=posit*iMA_IBS_RSI_CCI( E2,
                                    per_IBS , per_RSI      , per_CCI      ,
                                    глушка  , app_price_RSI, app_price_CCI,
                                    koef_ibs, koef_rsi     , koef_cci     ,
                                    kibs    , krsi         , kcci         ,
                                    i+Shift);                   
      }
   for(i = limit;i>=0;i--)
      { E0[i]=E0[i+1];
        double raz10=E1[i]-E0[i];      
        if(MathAbs(raz10)>porog) 
          {if(raz10>0) E0[i]=E1[i]-porog*xma1;
           if(raz10<0) E0[i]=E1[i]+porog*xma1;
          }         
      } 
   for(i=limit1; i>=0;i--)
      {n_max=ArrayMaximum(E0,RangePeriod_VKWB,i);
       n_min=ArrayMinimum(E0,RangePeriod_VKWB,i);
       E3[i]=E0[n_max];
       E4[i]=E0[n_min];
      }
   for(i=limit2; i>=0;i--)
      {E5[i]=iMAOnArray(E3,0,SmoothPeriod_VKWB,0,SmoothMode_VKWB,i);
       E6[i]=iMAOnArray(E4,0,SmoothPeriod_VKWB,0,SmoothMode_VKWB,i);
      }             
//----
   return(0);
  }
//+------------------------------------------------------------------+
 
void Delitel(double& ExtMapBuffer[],int limit)
{
 double delitel;
 for(int i=limit;i>=0;i--)
    {delitel=High[i]-Low[i];
     if (delitel>0)  ExtMapBuffer[i]=(Close[i]-Low[i])/delitel;
     else ExtMapBuffer[i]=0.0;
    }
return;
}
 
double iMA_IBS_RSI_CCI(double& ExtMapBuffer[],
                      int tper_IBS,int tper_RSI,int tper_CCI,
                      int tглушка,int tapp_price_RSI,int tapp_price_CCI,
                      double tkoef_ibs,double tkoef_rsi,double tkoef_cci,
                      int tkibs,int tkrsi,int tkcci,
                      int i)
{
 double sum=0.0;
 sum+=tkibs*(iMAOnArray(ExtMapBuffer,0,tper_IBS,0,MODE_SMA,i)-0.5)*100.0*tkoef_ibs;
 sum+=tkcci*iCCI(NULL,0,tper_CCI,tapp_price_CCI,i)*tkoef_cci; 
 sum+=tkrsi*(iRSI(NULL,0,tper_RSI,tapp_price_RSI,i)-50.0)*tkoef_rsi;
 sum*=1.0/3.0; 
return(sum);
}