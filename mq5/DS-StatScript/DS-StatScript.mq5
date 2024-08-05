//+------------------------------------------------------------------+
//|                                                DS-StatScript.mq5 |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

#property script_show_inputs

enum ENUM_PRESET {
  PRESET_ZZ             = 1, // Комментарий: DSZZ
  PRESET_BO             = 2, // Комментарий: DSBOP
  PRESET_ATR            = 3, // Комментарий: DSATR
  PRESET_TPO            = 4, // Комментарий: DSTPO
  PRESET_CUSTOM_COMMENT = 5, // Другой комментарий
  PRESET_CUSTOM_MAGIC   = 6  // Другой MAGIC
};


input     ENUM_PRESET        InpPreset          = PRESET_ZZ;              // Тип фильтра позиций
input     string             InpCustom          = "";                     // Другой комментарий/MAGIC
input     datetime           InpTimeFrom        = 0;                      // Период ОТ
input     datetime           InpTimeTo          = 0;                      // Период ДО (01.01.1970 - сегодня)


#include <Arrays\ArrayString.mqh>
#include "Include\DKStdLib\History\DKHistory.mqh"

struct ReportRow {
  //string                       Name;
  string                       Symbol;
  ulong                        Count;
  ulong                        CountWin;
  double                       WinRate;
  
  double                       VolumeAVG;
  double                       Profit;
  double                       ProfitPerPos;
  
  ulong                        HoldingMinAVG;
};

string EnumPresetToString(const ENUM_PRESET _preset) {
  if(_preset == PRESET_ZZ) return "DSZZ";
  if(_preset == PRESET_BO) return "DSBOP";
  if(_preset == PRESET_ATR) return "DSATR";
  if(_preset == PRESET_TPO) return "DSTPO";
  if(_preset == PRESET_CUSTOM_COMMENT) return InpCustom;
  if(_preset == PRESET_CUSTOM_MAGIC) return InpCustom;

  return "";
}

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
  ulong magic = 0;
  string comment_substring = EnumPresetToString(InpPreset);
  if(InpPreset == PRESET_CUSTOM_MAGIC) magic = StringToInteger(comment_substring);
  datetime dt_from = InpTimeFrom;
  datetime dt_to = (InpTimeTo == 0) ? TimeCurrent() : InpTimeTo;

  CDKHistoryPositionList pos_list;
  DKHistoryPos hpos;
  DKHistoryPos hpos_arr[];
  
  pos_list.Load(dt_from, dt_to); // Load historical poses
  
  // Filter pos by comment and fill symbol list
  CArrayString sym_arr;
  for(int i=0;i<pos_list.Total();i++) {
    if(!pos_list.GetSummaryByIndex(i, hpos)) continue;
    if(hpos.TimeOut == 0) continue; // No out deal in pos
    
    // Filter pos
    if(magic == 0 && StringFind(hpos.Comment, comment_substring) < 0) continue;
    if(magic != 0 && hpos.Magic != magic) continue;
    
    ArrayResize(hpos_arr, ArraySize(hpos_arr)+1);
    hpos_arr[ArraySize(hpos_arr)-1] = hpos;
    if(sym_arr.SearchLinear(hpos.Symbol) < 0) sym_arr.Add(hpos.Symbol);
  }  
  
  // Group by symbol
  double total_volume = 0.0;
  sym_arr.Sort();
  ReportRow rrow_arr[];
  for(int i=0;i<sym_arr.Total();i++) {
    ReportRow rrow;
    rrow.Count = 0;
    rrow.CountWin = 0;
    rrow.WinRate = 0.0;
    rrow.HoldingMinAVG = 0;
    //rrow.Name = comment_substring;
    rrow.Profit = 0;
    rrow.ProfitPerPos = 0;
    rrow.Symbol = sym_arr.At(i);
    rrow.VolumeAVG = 0;
    for(int j=0;j<ArraySize(hpos_arr);j++) {
      if(hpos_arr[j].Symbol != rrow.Symbol) continue;
      rrow.Count++; 
      if(hpos_arr[j].Profit > 0) rrow.CountWin++;
      rrow.HoldingMinAVG += hpos_arr[j].DurationSec;
      rrow.Profit += hpos_arr[j].Profit;
      rrow.VolumeAVG += hpos_arr[j].VolumeIn;  
    }
    
    if(rrow.Count != 0) {
      rrow.HoldingMinAVG = rrow.HoldingMinAVG / rrow.Count / 60;
      rrow.WinRate = (double)rrow.CountWin / rrow.Count * 100;
      total_volume += rrow.VolumeAVG;
      rrow.VolumeAVG = rrow.VolumeAVG / rrow.Count;
      rrow.ProfitPerPos = rrow.Profit / rrow.Count;
    }
    else rrow.HoldingMinAVG = 0;
    
    ArrayResize(rrow_arr, ArraySize(rrow_arr)+1);
    rrow_arr[ArraySize(rrow_arr)-1] = rrow;
  }
  
  // Totals
  ReportRow total;
  total.Count = 0;
  total.CountWin = 0;
  total.WinRate = 0.0;
  total.HoldingMinAVG = 0;
  //total.Name = comment_substring;
  total.Profit = 0;
  total.ProfitPerPos = 0;
  total.Symbol = StringFormat("ИТОГО %s:", comment_substring);
  total.VolumeAVG = 0;
  for(int i=0;i<ArraySize(rrow_arr);i++) {
    total.Count += rrow_arr[i].Count;
    total.CountWin += rrow_arr[i].CountWin;
    total.HoldingMinAVG += rrow_arr[i].HoldingMinAVG;
    total.Profit += rrow_arr[i].Profit;
    total.VolumeAVG += rrow_arr[i].VolumeAVG;
  }
  if(ArraySize(rrow_arr) != 0) {
    total.HoldingMinAVG = total.HoldingMinAVG / ArraySize(rrow_arr);
    total.WinRate = (double)total.CountWin / total.Count * 100;
    total.VolumeAVG = total_volume / total.Count;
    total.ProfitPerPos = total.Profit / total.Count;
  }
  else total.HoldingMinAVG = 0;
  
  ArrayResize(rrow_arr, ArraySize(rrow_arr)+1);
  rrow_arr[ArraySize(rrow_arr)-1] = total;
  
  Print("");
  PrintFormat(StringFormat("ОТЧЕТ ПО %s=%s ЗА %s-%s ",
                           (magic == 0) ? "COMMENT" : "MAGIC",
                           comment_substring,
                           TimeToString(dt_from, TIME_DATE),
                           TimeToString(dt_to, TIME_DATE)
                           ));
  ArrayPrint(rrow_arr, 2);
}  