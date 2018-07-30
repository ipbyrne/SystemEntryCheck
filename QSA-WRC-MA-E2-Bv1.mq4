#property strict
#property indicator_separate_window
#property indicator_minimum    -1
#property indicator_maximum    101
#property indicator_level1     5.0
#property indicator_buffers 5
#property indicator_color1  clrYellow  
#property indicator_color2  clrFireBrick
#property indicator_color3  clrBlue
#property indicator_color4  clrGreen
#property indicator_color5  clrPurple

input int sampleSize = 30000;
input int WRCs = 5000;
sinput string Info_1=""; // SET UP INPUTS
input int T = 25;
input int S = 50;
input bool rolling = false;
sinput string Info_2=""; // INDICATOR INPUTS
input int period = 50;
sinput string Info_3=""; // TEXT SETTINGS
sinput color TextColor = clrWhite;
sinput int xValue = 20;

string objprefix = "QSA-WRC-MA" + IntegerToString(period);
double pvalue = 0.5;
double pvalue2 = 0.5;
double owrcpvalue = 0.5;
double rwrcpvalue = 0.5;

double berateb[];
double owinrate[];
double rwinrate[];
double opvalue[];
double rpvalue[];

bool loaded = false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,berateb);
   SetIndexLabel(0,"BE WINRATE");
   SetIndexBuffer(1,owinrate);
   SetIndexLabel(1,"O WINRATE");
   SetIndexBuffer(2,rwinrate);
   SetIndexLabel(2,"R WINRATE");
   SetIndexBuffer(3,opvalue);
   SetIndexLabel(3, "O P VALUE");
   SetIndexBuffer(4,rpvalue);
   SetIndexLabel(4, "R P VALUE");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator de-initialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){DeleteObjects(objprefix);}
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
   if(loaded) {return(0);}  
   int x = 10000;
   while(x>0)
      {
      //----------
      // Main Loop - Gather Data to Get Win Rate
      //----------
      int i = sampleSize;
      int startTime = 0;
      double startingLevel = 0;
      int MAE = 0;
      int MFE = 0;
      bool longOp = false;
      bool shortOp = false;
      bool tradeOp = false;
      int count = 0;
      int wins = 0;
      
      int startTime2 = 0;
      double startingLevel2 = 0;
      int MAE2 = 0;
      int MFE2 = 0;
      bool longOp2 = false;
      bool shortOp2 = false;
      bool tradeOp2 = false;
      int count2 = 0;
      int wins2 = 0;
      
      int sumOfO = 0;
      int sumOfR = 0;
      
      while(i>0)
         {
          //--------------
          // ENTRY SIGNAL
          //--------------
          double currentMA = iMA(NULL,0,period,0,MODE_SMA,PRICE_CLOSE,i+1+x);
          double lastMA = iMA(NULL,0,period,0,MODE_SMA,PRICE_CLOSE,i+2+x);
          int slope = 0;
          if(currentMA > lastMA) {slope = 1;}
          if(currentMA < lastMA) {slope = -1;}
          
          bool longSignal = false;
          bool shortSignal = false;
          
          if(slope == 1 && Open[i+x] > currentMA && Open[i+x+1] < currentMA) {longSignal = true;} // Long Signal Condition Check
          if(slope == -1 && Open[i+x] < currentMA && Open[i+x+1] > currentMA) {shortSignal = true;} // Short Signal Condition Check
   
          //-----------------------
          // ORIGINAL SIGNAL TEXT
          //-----------------------
          //--------------
          // LONG OPP OPEN
          //--------------
          if(!longOp && !shortOp)// Confirm No Trades are Open
             {
             if(longSignal) // Long Oppurtunity Started
                {
                startTime = i+x;
                startingLevel = Open[i+x];
                longOp = true;
                count++;
                }
             }
             
          
          //--------------
          // LONG UPDATE MAE/MFE
          //--------------
          if(longOp) // Check For Open Trade
             {
             int MAEdistance = int((startingLevel-Low[i+x])/CalculateNormalizedDigits()); // Draw Down Distance
             int MFEdistance = int((High[i+x]-startingLevel)/CalculateNormalizedDigits()); // Run Up Distance
             
             // Compare Distances to Current Place Holders
             if(MAEdistance>MAE) {MAE = MAEdistance;}
             
             if(MFEdistance>MFE) {MFE = MFEdistance;}
             
             if(!tradeOp)
               {
               if(MAE >= S && MFE < T) {tradeOp = true; sumOfO-= S;}
               if(MFE >= T && MAE < S) {wins++; tradeOp = true; sumOfO+= T;}
               }
             }
         
                
          //--------------
          // LONG OPP CLOSE
          //--------------
          if(longOp) // Check For Open Trade
             {
             if((MAE >= S && MFE < T) || (MFE >= T && MAE < S)) // Long Opp is Closed
                {
                // Reset Counters
                MAE = 0;
                MFE = 0;
                longOp = false;
                tradeOp = false;
                if(rolling) {i = startTime;}
                }
             }
            
          //--------------
          // SHORT OPP OPEN
          //--------------
          if(!shortOp && !longOp) // Confirm No Trades are Open
             {
             if(shortSignal)
                {
                startTime = i+x;
                startingLevel = Open[i+x];
                shortOp = true;
                count++;
                }
             }
            
          //--------------
          // SHORT UPDATE MAE/MFE
          //--------------
          if(shortOp) // Check For Open Trade
             {
             int MAEdistance = int((High[i+x]-startingLevel)/CalculateNormalizedDigits()); // Draw Down Distance
             int MFEdistance = int((startingLevel-Low[i+x])/CalculateNormalizedDigits()); // Run Up Distance
             
             // Compare Distances to Current Place Holders
             if(MAEdistance>MAE) {MAE = MAEdistance;}
             if(MFEdistance>MFE) {MFE = MFEdistance;}
             
             if(!tradeOp)
               {
               if(MAE >= S && MFE < T) {tradeOp = true; sumOfO-= S;}
               if(MFE >= T && MAE < S) {wins++; tradeOp = true; sumOfO+= T;}
               }
             }
         
          //--------------
          // SHORT OPP CLOSE
          //--------------
          if(shortOp) // Check For Open Trade
             {
             if((MAE >= S && MFE < T) || (MFE >= T && MAE < S)) // Short Opp is Closed
                {
                // Reset Counters
                MAE = 0;
                MFE = 0;
                shortOp = false;
                tradeOp = false;
                if(rolling) {i = startTime;}
                }
             }
         
          i--;
         }
      
      i = sampleSize;
      while(i>0)
         {
          //-----------------------
          // REVERSE SIGNAL TEXT
          //-----------------------
          //--------------
          // ENTRY SIGNAL - REVERSE
          //--------------
          double currentMA = iMA(NULL,0,period,0,MODE_SMA,PRICE_CLOSE,i+x+1);
          double lastMA = iMA(NULL,0,period,0,MODE_SMA,PRICE_CLOSE,i+x+2);
          int slope = 0;
          if(currentMA > lastMA) {slope = 1;}
          if(currentMA < lastMA) {slope = -1;}
          
          bool longSignal = false;
          bool shortSignal = false;
          
          if(slope == -1 && Open[i+x] < currentMA && Open[i+x+1] > currentMA) {longSignal = true;} // Long Signal Condition Check
          if(slope == 1 && Open[i+x] > currentMA && Open[i+x+1] < currentMA) {shortSignal = true;} // Short Signal Condition Check
   
          //--------------
          // LONG OPP OPEN
          //--------------
          if(!longOp2 && !shortOp2)// Confirm No Trades are Open
             {
             if(longSignal) // Long Oppurtunity Started
                {
                startTime2 = i+x;
                startingLevel2 = Open[i+x];
                longOp2 = true;
                count2++;
                }
             }
             
          
          //--------------
          // LONG UPDATE MAE/MFE
          //--------------
          if(longOp2) // Check For Open Trade
             {
             int MAEdistance = int((startingLevel2-Low[i+x])/CalculateNormalizedDigits()); // Draw Down Distance
             int MFEdistance = int((High[i+x]-startingLevel2)/CalculateNormalizedDigits()); // Run Up Distance
             
             // Compare Distances to Current Place Holders
             if(MAEdistance>MAE2) {MAE2 = MAEdistance;}
             
             if(MFEdistance>MFE2) {MFE2 = MFEdistance;}
             
             if(!tradeOp2)
               {
               if(MAE2 >= S && MFE2 < T) {tradeOp2 = true; sumOfR-= S;}
               if(MFE2 >= T && MAE2 < S) {wins2++; tradeOp2 = true; sumOfR+= T;}
               }
             }
         
                
          //--------------
          // LONG OPP CLOSE
          //--------------
          if(longOp2) // Check For Open Trade
             {
             if((MAE2 >= S && MFE2 < T) || (MFE2 >= T && MAE2 < S)) // Long Opp is Closed
                {
                // Reset Counters
                MAE2 = 0;
                MFE2 = 0;
                longOp2 = false;
                tradeOp2 = false;
                if(rolling) {i = startTime2;}
                }
             }
            
          //--------------
          // SHORT OPP OPEN
          //--------------
          if(!shortOp2 && !longOp2) // Confirm No Trades are Open
             {
             if(shortSignal)
                {
                startTime2 = i;
                startingLevel2 = Open[i+x];
                shortOp2 = true;
                count2++;
                }
             }
            
          //--------------
          // SHORT UPDATE MAE/MFE
          //--------------
          if(shortOp2) // Check For Open Trade
             {
             int MAEdistance = int((High[i+x]-startingLevel2)/CalculateNormalizedDigits()); // Draw Down Distance
             int MFEdistance = int((startingLevel2-Low[i+x])/CalculateNormalizedDigits()); // Run Up Distance
             
             // Compare Distances to Current Place Holders
             if(MAEdistance>MAE2) {MAE2 = MAEdistance;}
             if(MFEdistance>MFE2) {MFE2 = MFEdistance;}
             
             if(!tradeOp2)
               {
               if(MAE2 >= S && MFE2 < T) {tradeOp2 = true; sumOfR-= S;}
               if(MFE2 >= T && MAE2 < S) {wins2++; tradeOp2 = true; sumOfR+= T;}
               }
             }
         
          //--------------
          // SHORT OPP CLOSE
          //--------------
          if(shortOp2) // Check For Open Trade
             {
             if((MAE2 >= S && MFE2 < T) || (MFE2 >= T && MAE2 < S)) // Short Opp is Closed
                {
                // Reset Counters
                MAE2 = 0;
                MFE2 = 0;
                shortOp2 = false;
                tradeOp2 = false;
                if(rolling) {i = startTime2;}
                }
             }
          i--;
         }
    
      //--------------
      // Gather Win Rates
      //--------------
      double berate = (double(S)/(double(S)+double(T)))*100;
      double winrate = (double(wins)/double(count))*100;
      double spreadrisk = 0;
      if((MarketInfo(Symbol(),MODE_SPREAD)/10) > 6)
         {
         spreadrisk = (3/(T+S))*100;
         }
      else
         {
         spreadrisk = ((MarketInfo(Symbol(),MODE_SPREAD)/10)/(T+S))*100;
         }
      double winrate2 = (double(wins2)/double(count2))*100;
     
      
      //--------------
      // WRC
      //--------------
      WhitesRealityCheck(sumOfO, sumOfR, count, count2, berate, spreadrisk);
      
      //--------------
      // Draw Buffers
      //--------------
      berateb[x] = berate;
      owinrate[x] = winrate;
      rwinrate[x] = winrate2;
      opvalue[x] = owrcpvalue*100;
      rpvalue[x] = rwrcpvalue*100;
      
      x--;
      }
   loaded = true;
   WriteFile();
   return(rates_total);
  }
//+------------------------------------------------------------------+
//+--------------
//|DELETE OBJECTS                                                 
//+--------------  
void DeleteObjects(string prefix)
  {
   string strObj;
   int ObjTotal=ObjectsTotal();
   for(int i=ObjTotal-1;i>=0;i--)
     {
      strObj=ObjectName(i);
      if(StringFind(strObj,prefix,0)>-1)
        {
         ObjectDelete(strObj);
        }
     }
  }
//+----------------
//|Normalize Digits                                                  
//+---------------- 
double CalculateNormalizedDigits()
  {
//If there are 3 or less digits (JPY for example) then return 0.01 which is the pip value
   if(Digits<=3)
     {
      return(0.01);
     }
//If there are 4 or more digits then return 0.0001 which is the pip value
   else if(Digits>=4)
     {
      return(0.0001);
     }
//In all other cases (there shouldn't be any) return 0
   else return(0);
  }
//+----------------
//| Whites Reality Check                                          
//+----------------
void WhitesRealityCheck(int sumOfO, int sumOfR, int count, int count2, double berate, double spreadRisk)
  {
  //-------------
  // Original WRC
  //-------------
  int i = WRCs;
  double winrate = (berate + spreadRisk);
  double aboveOSum = 0;
  while(i>0)
   {
   int x = count;
   int tempSum = 0;
   while(x>0)
      {
      if(0 + 100*MathRand()/32768 <= winrate) {tempSum+= T;} else {tempSum-= S;}
      x--;
      }

   if(sumOfO <= tempSum){aboveOSum++;} 
   i--;
   }
  owrcpvalue = double(aboveOSum)/double(WRCs);

  //-------------
  // Reverse WRC
  //-------------
  i = WRCs;
  double aboveRSum = 0;
  while(i>0)
   {
   int x = count2;
   int tempSum = 0;
   while(x>0)
      {
      if(0 + 100*MathRand()/32768 <= winrate) {tempSum+= T;} else {tempSum-= S;}
      x--;
      }
   
   if(sumOfR <= tempSum){aboveRSum++;} 
   i--;
   }
  rwrcpvalue = double(aboveRSum)/double(WRCs);
  }
//+--------------------------
//|WRITE STATISTICS INTO FILE                                        
//+--------------------------
bool WriteFile()
  {
   int file_handle=FileOpen("Statistics"+"//"+"QSA-WRC-MA-E2-B.txt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI);
   if(file_handle!=INVALID_HANDLE)
     {
      PrintFormat("%s file is available for writing","QSA-WRC-MA-E2-B.txt");
      PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));

      string strData="";
      
      int x = 10000;
      while(x > 0)
         {
         strData += DoubleToStr(berateb[x],2) + "," + DoubleToStr(owinrate[x],2) + "," + DoubleToStr(rwinrate[x],2) + "," + DoubleToStr(opvalue[x],2) + "," + DoubleToStr(rpvalue[x],2) + "\n";
         x--;
         }

      FileWriteString(file_handle,strData);

      //--- close the file
      FileClose(file_handle);
      PrintFormat("Data is written, %s file is closed","QSA-WRC-MA-E2-B.txt");
      
      return(true);
     }
   else
     {
      PrintFormat("Failed to open %s file, Error code = %d","QSA-WRC-MA-E2-B.txt",GetLastError());
      return(false);
     }
  }