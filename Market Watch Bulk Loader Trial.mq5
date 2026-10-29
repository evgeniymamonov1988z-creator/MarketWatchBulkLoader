//+------------------------------------------------------------------+
//| Market Watch Bulk Loader (Trial)                                  |
//| Trial version: full features for 3 days from first launch.        |
//| Reads pasted ticker text and selects matching broker symbols.     |
//+------------------------------------------------------------------+
#property strict
#property version "1.00"
#property description "Trial version of Market Watch Bulk Loader. Paste a ticker list into the panel and the matching broker symbols are added to Market Watch."
#property description "Trial period: 3 days from the first launch. No symbol limit."
#property description "This utility does not trade, does not send orders and sends no data outside your terminal."

#define TRIAL_DAYS 3
#define TRIAL_FILE "MWBL_trial.dat"

#define PANEL_PREFIX "MWBLF_"
#define LABEL_TITLE PANEL_PREFIX "title"
#define BUTTON_NOTE PANEL_PREFIX "note"
#define BUTTON_IMPORT PANEL_PREFIX "import"
#define BUTTON_HELP PANEL_PREFIX "help"
#define EDIT_SYMBOLS PANEL_PREFIX "symbols"
#define HELP_BG PANEL_PREFIX "help_bg"
#define HELP_LINE_PREFIX PANEL_PREFIX "help_line_"
#define HELP_RU PANEL_PREFIX "help_ru"
#define HELP_EN PANEL_PREFIX "help_en"
#define HELP_DE PANEL_PREFIX "help_de"
#define HELP_ES PANEL_PREFIX "help_es"
#define HELP_ZH PANEL_PREFIX "help_zh"
#define HELP_TR PANEL_PREFIX "help_tr"
#define HELP_HI PANEL_PREFIX "help_hi"
#define HELP_AR PANEL_PREFIX "help_ar"
#define HELP_FR PANEL_PREFIX "help_fr"
#define HELP_BN PANEL_PREFIX "help_bn"
#define HELP_PT PANEL_PREFIX "help_pt"
#define HELP_ID PANEL_PREFIX "help_id"
#define LABEL_STATUS PANEL_PREFIX "status"
#define LABEL_DETAILS PANEL_PREFIX "details"

input bool InpReplaceMarketWatch = false;

bool g_replaceMarketWatch = false;
bool g_inputShown = false;
string g_inputText = "";
bool g_helpShown = false;
int g_helpLanguage = 1;

string g_status = "Ready. Press TXT, paste, press Copy.";
string g_details = "Trial version: 3 days from first launch.";
bool g_trialExpired = false;

void DestroyPanel();
void HideHelp();
void ToggleHelp();

datetime GetTrialStart()
{
   datetime start = 0;
   if(FileIsExist(TRIAL_FILE, FILE_COMMON))
   {
      int h = FileOpen(TRIAL_FILE, FILE_READ|FILE_BIN|FILE_COMMON);
      if(h != INVALID_HANDLE)
      {
         if(FileSize(h) >= 8)
            start = (datetime)FileReadLong(h);
         FileClose(h);
      }
   }
   if(start <= 0)
   {
      start = TimeLocal();
      int h = FileOpen(TRIAL_FILE, FILE_WRITE|FILE_BIN|FILE_COMMON);
      if(h != INVALID_HANDLE)
      {
         FileWriteLong(h, (long)start);
         FileClose(h);
      }
   }
   return start;
}

int TrialDaysLeft()
{
   datetime start = GetTrialStart();
   long elapsed = (long)(TimeLocal() - start);
   int left = TRIAL_DAYS - (int)(elapsed / 86400);
   if(left < 0) left = 0;
   return left;
}

bool IsTrialExpired()
{
   datetime start = GetTrialStart();
   return ((long)(TimeLocal() - start) > (long)TRIAL_DAYS * 86400);
}

string Trim(string value)
{
   StringTrimLeft(value);
   StringTrimRight(value);
   return value;
}

string Normalize(string value)
{
   string result = Trim(value);
   StringToUpper(result);
   StringReplace(result, " ", "");
   StringReplace(result, ".", "");
   StringReplace(result, "_", "");
   StringReplace(result, "-", "");
   return result;
}

bool Contains(string &values[], string value)
{
   for(int i = 0; i < ArraySize(values); i++)
      if(values[i] == value)
         return true;
   return false;
}

int FindBestMatches(string requested, string &matches[], int brokerSymbols)
{
   ArrayResize(matches, 0);
   string key = Normalize(requested);
   if(key == "")
      return 0;

   for(int symbolIndex = 0; symbolIndex < brokerSymbols; symbolIndex++)
   {
      string brokerName = SymbolName(symbolIndex, false);
      string brokerKey = Normalize(brokerName);
      bool related = (StringFind(brokerKey, key) == 0 || StringFind(key, brokerKey) == 0);
      if(!related)
         continue;

      int matchCount = ArraySize(matches);
      ArrayResize(matches, matchCount + 1);
      matches[matchCount] = brokerName;
   }
   return ArraySize(matches);
}

void SetStatus(string status, string details = "")
{
   g_status = status;
   g_details = details;
   if(ObjectFind(0, LABEL_STATUS) >= 0)
      ObjectSetString(0, LABEL_STATUS, OBJPROP_TEXT, g_status);
   if(ObjectFind(0, LABEL_DETAILS) >= 0)
      ObjectSetString(0, LABEL_DETAILS, OBJPROP_TEXT, g_details);
   ChartRedraw(0);
}

void CreateLabel(string name, int x, int y, color textColor, int fontSize, string text)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

void BuildPanel()
{
   DestroyPanel();

   CreateLabel(LABEL_TITLE, 15, 8, clrDeepSkyBlue, 9,
               "MARKET WATCH BULK LOADER - TRIAL (3 days)");


   ObjectCreate(0, BUTTON_HELP, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BUTTON_HELP, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, BUTTON_HELP, OBJPROP_ZORDER, 10);
   ObjectSetInteger(0, BUTTON_HELP, OBJPROP_XDISTANCE, 15);
   ObjectSetInteger(0, BUTTON_HELP, OBJPROP_YDISTANCE, 25);
   ObjectSetInteger(0, BUTTON_HELP, OBJPROP_XSIZE, 24);
   ObjectSetInteger(0, BUTTON_HELP, OBJPROP_YSIZE, 24);
   ObjectSetInteger(0, BUTTON_HELP, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, BUTTON_HELP, OBJPROP_COLOR, clrBlack);
   ObjectSetString(0, BUTTON_HELP, OBJPROP_TEXT, "?");
   ObjectSetString(0, BUTTON_HELP, OBJPROP_TOOLTIP,
                   "INSTRUCTIONS:\n"
                   "1. Press TXT.\n"
                   "2. Paste tickers with Ctrl+V using commas, spaces, or semicolons.\n"
                   "3. Press Copy.\n"
                   "4. Similar broker symbols will be found.\n"
                   "5. Symbols will be added to Market Watch.\n"
                   "6. Trial version: 3 days from first launch.\n"
                   "7. No orders are placed.");

   ObjectCreate(0, BUTTON_IMPORT, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BUTTON_IMPORT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, BUTTON_IMPORT, OBJPROP_ZORDER, 10);
   ObjectSetInteger(0, BUTTON_IMPORT, OBJPROP_XDISTANCE, 43);
   ObjectSetInteger(0, BUTTON_IMPORT, OBJPROP_YDISTANCE, 25);
   ObjectSetInteger(0, BUTTON_IMPORT, OBJPROP_XSIZE, 80);
   ObjectSetInteger(0, BUTTON_IMPORT, OBJPROP_YSIZE, 24);
   ObjectSetInteger(0, BUTTON_IMPORT, OBJPROP_BGCOLOR, clrGreen);
   ObjectSetInteger(0, BUTTON_IMPORT, OBJPROP_COLOR, clrWhite);
   ObjectSetString(0, BUTTON_IMPORT, OBJPROP_TEXT, "Copy");

   ObjectCreate(0, BUTTON_NOTE, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BUTTON_NOTE, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, BUTTON_NOTE, OBJPROP_ZORDER, 10);
   ObjectSetInteger(0, BUTTON_NOTE, OBJPROP_XDISTANCE, 126);
   ObjectSetInteger(0, BUTTON_NOTE, OBJPROP_YDISTANCE, 25);
   ObjectSetInteger(0, BUTTON_NOTE, OBJPROP_XSIZE, 24);
   ObjectSetInteger(0, BUTTON_NOTE, OBJPROP_YSIZE, 24);
   ObjectSetInteger(0, BUTTON_NOTE, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, BUTTON_NOTE, OBJPROP_COLOR, clrBlack);
   ObjectSetString(0, BUTTON_NOTE, OBJPROP_TEXT, "TXT");
   ObjectSetString(0, BUTTON_NOTE, OBJPROP_TOOLTIP,
                   "Press TXT to open the ticker input field.");

   CreateLabel(LABEL_STATUS, 15, 85, clrWhite, 9, g_status);
   CreateLabel(LABEL_DETAILS, 15, 103, clrSilver, 8, g_details);

   ChartRedraw(0);
}

void ShowInputField()
{
   g_inputShown = true;
   if(ObjectFind(0, EDIT_SYMBOLS) >= 0)
   {
      ObjectSetInteger(0, EDIT_SYMBOLS, OBJPROP_HIDDEN, false);
      ObjectSetInteger(0, EDIT_SYMBOLS, OBJPROP_SELECTED, true);
      ChartRedraw(0);
      return;
   }

   ObjectCreate(0, EDIT_SYMBOLS, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, EDIT_SYMBOLS, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, EDIT_SYMBOLS, OBJPROP_XDISTANCE, 126);
   ObjectSetInteger(0, EDIT_SYMBOLS, OBJPROP_YDISTANCE, 55);
   ObjectSetInteger(0, EDIT_SYMBOLS, OBJPROP_XSIZE, 160);
   ObjectSetInteger(0, EDIT_SYMBOLS, OBJPROP_YSIZE, 24);
   ObjectSetInteger(0, EDIT_SYMBOLS, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, EDIT_SYMBOLS, OBJPROP_COLOR, clrBlack);
   ObjectSetString(0, EDIT_SYMBOLS, OBJPROP_TEXT, g_inputText);
   ObjectSetString(0, EDIT_SYMBOLS, OBJPROP_TOOLTIP, "Paste tickers with Ctrl+V");
   ObjectSetInteger(0, EDIT_SYMBOLS, OBJPROP_SELECTED, true);
   ChartRedraw(0);
}

void HideInputField()
{
   if(ObjectFind(0, EDIT_SYMBOLS) < 0)
      return;
   g_inputText = ObjectGetString(0, EDIT_SYMBOLS, OBJPROP_TEXT);
   ObjectDelete(0, EDIT_SYMBOLS);
   g_inputShown = false;
   ChartRedraw(0);
}

string CloseHelpHint(int language)
{
   if(language == 0)  return "9. Чтобы закрыть это окно, нажмите ?";
   if(language == 2)  return "9. Zum Schliessen dieses Fensters ? druecken.";
   if(language == 3)  return "9. Para cerrar esta ventana pulse ?";
   if(language == 4)  return "9. 关闭此窗口请点击 ? 。";
   if(language == 5)  return "9. Bu pencereyi kapatmak icin ? tusuna basin.";
   if(language == 6)  return "9. यह विंडो बंद करने के लिए ? दबाएं।";
   if(language == 7)  return "9. لإغلاق هذه النافذة اضغط ?";
   if(language == 8)  return "9. Pour fermer cette fenetre appuyez sur ?";
   if(language == 9)  return "9. এই উইন্ডো বন্ধ করতে ? টিপুন।";
   if(language == 10) return "9. Para fechar esta janela pressione ?";
   if(language == 11) return "9. Untuk menutup jendela ini tekan ?";
   return "9. To close this window press ?";
}

string TrialDaysLine(int language, int daysLeft)
{
   string d = IntegerToString(daysLeft);
   if(language == 0)  return "Пробный период: осталось дней - " + d + ".";
   if(language == 2)  return "Testzeitraum: verbleibende Tage - " + d + ".";
   if(language == 3)  return "Periodo de prueba: dias restantes - " + d + ".";
   if(language == 4)  return "试用期：剩余天数 " + d + "。";
   if(language == 5)  return "Deneme suresi: kalan gun - " + d + ".";
   if(language == 6)  return "ट्रायल अवधि: शेष दिन - " + d + "।";
   if(language == 7)  return "الفترة التجريبية: الأيام المتبقية - " + d + ".";
   if(language == 8)  return "Periode d'essai : jours restants - " + d + ".";
   if(language == 9)  return "ট্রায়াল সময়: বাকি দিন - " + d + "।";
   if(language == 10) return "Periodo de teste: dias restantes - " + d + ".";
   if(language == 11) return "Masa uji coba: sisa hari - " + d + ".";
   return "Trial period: days left - " + d + ".";
}

string TrialExpiredLine(int language)
{
   if(language == 0)  return "Пробный период (3 дня) завершён. Нужна полная версия.";
   if(language == 2)  return "Testzeitraum (3 Tage) abgelaufen. Vollversion erforderlich.";
   if(language == 3)  return "Periodo de prueba (3 dias) finalizado. Se requiere la version completa.";
   if(language == 4)  return "试用期（3 天）已结束，请使用完整版。";
   if(language == 5)  return "Deneme suresi (3 gun) doldu. Tam surum gerekli.";
   if(language == 6)  return "ट्रायल अवधि (3 दिन) समाप्त। पूर्ण संस्करण आवश्यक है।";
   if(language == 7)  return "انتهت الفترة التجريبية (3 أيام). النسخة الكاملة مطلوبة.";
   if(language == 8)  return "Periode d'essai (3 jours) terminee. Version complete requise.";
   if(language == 9)  return "ট্রায়াল সময় (3 দিন) শেষ। পূর্ণ সংস্করণ প্রয়োজন।";
   if(language == 10) return "Periodo de teste (3 dias) encerrado. Versao completa necessaria.";
   if(language == 11) return "Masa uji coba (3 hari) berakhir. Perlu versi lengkap.";
   return "Trial period (3 days) ended. Full version required.";
}

int DetectTerminalLanguage()
{
   string name = TerminalInfoString(TERMINAL_LANGUAGE);
   StringToUpper(name);
   if(StringFind(name, "RUS") >= 0) return 0;
   if(StringFind(name, "GERMAN") >= 0 || StringFind(name, "DEUTSCH") >= 0) return 2;
   if(StringFind(name, "SPAN") >= 0 || StringFind(name, "ESPA") >= 0) return 3;
   if(StringFind(name, "CHIN") >= 0) return 4;
   if(StringFind(name, "TURK") >= 0) return 5;
   if(StringFind(name, "HIND") >= 0) return 6;
   if(StringFind(name, "ARAB") >= 0) return 7;
   if(StringFind(name, "FREN") >= 0 || StringFind(name, "FRAN") >= 0) return 8;
   if(StringFind(name, "BENG") >= 0) return 9;
   if(StringFind(name, "PORT") >= 0) return 10;
   if(StringFind(name, "INDONES") >= 0 || StringFind(name, "MALAY") >= 0) return 11;
   return 1;
}

void FillHelpLines(string &lines[])
{
   ArrayResize(lines, 10);
   lines[0] = "MARKET WATCH BULK LOADER - STARTER VERSION";
   lines[1] = "1. Press the TXT button.";
   lines[2] = "2. Paste the ticker list into the input field.";
   lines[3] = "3. Separators: comma, space, or semicolon.";
   lines[4] = "4. Example: EURUSD, GBPUSD; USDJPY XAUUSD";
   lines[5] = "5. Press Copy. Matching broker symbols are added.";
   lines[6] = "6. Duplicate symbols are not added.";
   lines[7] = "7. Trial version: full features for 3 days.";
   lines[8] = "8. The Expert Advisor does not place orders.";

   if(g_helpLanguage == 0)
   {
      lines[0] = "MARKET WATCH BULK LOADER - ПРОБНАЯ ВЕРСИЯ";
      lines[1] = "1. Нажмите кнопку TXT.";
      lines[2] = "2. Вставьте список тикеров в поле ввода.";
      lines[3] = "3. Разделители: запятая, пробел или точка с запятой.";
      lines[4] = "4. Пример: EURUSD, GBPUSD; USDJPY XAUUSD";
      lines[5] = "5. Нажмите Copy. Символы брокера будут добавлены.";
      lines[6] = "6. Дубликаты символов не добавляются.";
      lines[7] = "7. Пробная версия: полный функционал 3 дня.";
      lines[8] = "8. Советник не открывает сделки.";
   }
   else if(g_helpLanguage == 2)
   {
      lines[0] = "MARKET WATCH BULK LOADER - TESTVERSION";
      lines[1] = "1. Klicken Sie auf TXT.";
      lines[2] = "2. Fügen Sie die Tickerliste in das Eingabefeld ein.";
      lines[3] = "3. Trennzeichen: Komma, Leerzeichen oder Semikolon.";
      lines[4] = "4. Beispiel: EURUSD, GBPUSD; USDJPY XAUUSD";
      lines[5] = "5. Copy drücken. Brokersymbole werden hinzugefügt.";
      lines[6] = "6. Doppelte Symbole werden nicht hinzugefügt.";
      lines[7] = "7. Testversion: voller Funktionsumfang fuer 3 Tage.";
      lines[8] = "8. Der Expert Advisor eröffnet keine Trades.";
   }
   else if(g_helpLanguage == 3)
   {
      lines[0] = "MARKET WATCH BULK LOADER - VERSION DE PRUEBA";
      lines[1] = "1. Pulse el botón TXT.";
      lines[2] = "2. Pegue la lista de símbolos en el campo de entrada.";
      lines[3] = "3. Separadores: coma, espacio o punto y coma.";
      lines[4] = "4. Ejemplo: EURUSD, GBPUSD; USDJPY XAUUSD";
      lines[5] = "5. Pulse Copy. Se añaden los símbolos del bróker.";
      lines[6] = "6. No se añaden símbolos duplicados.";
      lines[7] = "7. Version de prueba: funciones completas 3 dias.";
      lines[8] = "8. El asesor experto no abre operaciones.";
   }
   else if(g_helpLanguage == 4)
   {
      lines[0] = "MARKET WATCH BULK LOADER - 试用版";
      lines[1] = "1. 点击 TXT 按钮。";
      lines[2] = "2. 将品种列表粘贴到输入框。";
      lines[3] = "3. 分隔符：逗号、空格或分号。";
      lines[4] = "4. 示例：EURUSD, GBPUSD; USDJPY XAUUSD";
      lines[5] = "5. 点击 Copy，匹配的品种将被添加。";
      lines[6] = "6. 不会重复添加品种。";
      lines[7] = "7. 试用版：完整功能 3 天。";
      lines[8] = "8. EA 不会进行交易。";
   }
   else if(g_helpLanguage == 5)
   {
      lines[0] = "MARKET WATCH BULK LOADER - DENEME SÜRÜMÜ";
      lines[1] = "1. TXT düğmesine basın.";
      lines[2] = "2. Sembol listesini giriş alanına yapıştırın.";
      lines[3] = "3. Ayraçlar: virgül, boşluk veya noktalı virgül.";
      lines[4] = "4. Örnek: EURUSD, GBPUSD; USDJPY XAUUSD";
      lines[5] = "5. Copy tuşuna basın. Semboller eklenir.";
      lines[6] = "6. Yinelenen semboller eklenmez.";
      lines[7] = "7. Deneme sürümü: 3 gün tam özellik.";
      lines[8] = "8. Expert Advisor işlem açmaz.";
   }
   else if(g_helpLanguage == 6)
   {
      lines[0] = "MARKET WATCH BULK LOADER - ट्रायल संस्करण";
      lines[1] = "1. TXT बटन दबाएं।";
      lines[2] = "2. टिकर सूची को इनपुट फ़ील्ड में पेस्ट करें।";
      lines[3] = "3. विभाजक: अल्पविराम, स्पेस या अर्धविराम।";
      lines[4] = "4. उदाहरण: EURUSD, GBPUSD; USDJPY XAUUSD";
      lines[5] = "5. Copy दबाएं। मिले सिंबल जोड़े जाते हैं।";
      lines[6] = "6. डुप्लिकेट सिंबल नहीं जोड़े जाते।";
      lines[7] = "7. ट्रायल संस्करण: 3 दिन पूर्ण सुविधाएँ।";
      lines[8] = "8. Expert Advisor कोई ऑर्डर नहीं भेजता।";
   }
   else if(g_helpLanguage == 7)
   {
      lines[0] = "MARKET WATCH BULK LOADER - إصدار تجريبي";
      lines[1] = "1. اضغط زر TXT.";
      lines[2] = "2. الصق قائمة الرموز في حقل الإدخال.";
      lines[3] = "3. الفواصل: فاصلة أو مسافة أو فاصلة منقوطة.";
      lines[4] = "4. مثال: EURUSD, GBPUSD; USDJPY XAUUSD";
      lines[5] = "5. اضغط Copy. تضاف رموز الوسيط.";
      lines[6] = "6. لا تتم إضافة الرموز المكررة.";
      lines[7] = "7. إصدار تجريبي: كامل الميزات لمدة 3 أيام.";
      lines[8] = "8. لا يرسل المستشار الخبير أي أوامر.";
   }
   else if(g_helpLanguage == 8)
   {
      lines[0] = "MARKET WATCH BULK LOADER - VERSION D'ESSAI";
      lines[1] = "1. Appuyez sur le bouton TXT.";
      lines[2] = "2. Collez la liste des symboles dans le champ de saisie.";
      lines[3] = "3. Separateurs : virgule, espace ou point-virgule.";
      lines[4] = "4. Exemple : EURUSD, GBPUSD; USDJPY XAUUSD";
      lines[5] = "5. Appuyez sur Copy. Les symboles sont ajoutes.";
      lines[6] = "6. Les symboles en double ne sont pas ajoutes.";
      lines[7] = "7. Version d'essai : fonctions completes 3 jours.";
      lines[8] = "8. L'Expert Advisor ne passe aucun ordre.";
   }
   else if(g_helpLanguage == 9)
   {
      lines[0] = "MARKET WATCH BULK LOADER - ট্রায়াল সংস্করণ";
      lines[1] = "1. TXT বোতামে ক্লিক করুন।";
      lines[2] = "2. ইনপুট ক্ষেত্রে টিকার তালিকা পেস্ট করুন।";
      lines[3] = "3. বিভাজক: কমা, স্পেস বা সেমিকোলন।";
      lines[4] = "4. উদাহরণ: EURUSD, GBPUSD; USDJPY XAUUSD";
      lines[5] = "5. Copy টিপুন। পাওয়া প্রতীক যোগ হয়।";
      lines[6] = "6. ডুপলিকেট প্রতীক যোগ করা হয় না।";
      lines[7] = "7. ট্রায়াল সংস্করণ: 3 দিন পূর্ণ সুবিধা।";
      lines[8] = "8. Expert Advisor কোনো অর্ডার দেয় না।";
   }
   else if(g_helpLanguage == 10)
   {
      lines[0] = "MARKET WATCH BULK LOADER - VERSAO DE TESTE";
      lines[1] = "1. Pressione o botao TXT.";
      lines[2] = "2. Cole a lista de simbolos no campo de entrada.";
      lines[3] = "3. Separadores: virgula, espaco ou ponto e virgula.";
      lines[4] = "4. Exemplo: EURUSD, GBPUSD; USDJPY XAUUSD";
      lines[5] = "5. Pressione Copy. Os simbolos sao adicionados.";
      lines[6] = "6. Simbolos duplicados nao sao adicionados.";
      lines[7] = "7. Versao de teste: recursos completos por 3 dias.";
      lines[8] = "8. O Expert Advisor nao envia ordens.";
   }
   else if(g_helpLanguage == 11)
   {
      lines[0] = "MARKET WATCH BULK LOADER - VERSI UJI COBA";
      lines[1] = "1. Tekan tombol TXT.";
      lines[2] = "2. Tempel daftar ticker ke kolom input.";
      lines[3] = "3. Pemisah: koma, spasi, atau titik koma.";
      lines[4] = "4. Contoh: EURUSD, GBPUSD; USDJPY XAUUSD";
      lines[5] = "5. Tekan Copy. Simbol broker akan ditambahkan.";
      lines[6] = "6. Simbol duplikat tidak ditambahkan.";
      lines[7] = "7. Versi uji coba: fitur penuh selama 3 hari.";
      lines[8] = "8. Expert Advisor tidak mengirim order.";
   }

   lines[9] = CloseHelpHint(g_helpLanguage);

   // The last line of the instructions tells how to close this window.
}

void CreateLangButton(string name, int x, int y, int width, string text)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, 24);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 110);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

void ToggleHelp()
{
   if(g_helpShown)
   {
      HideHelp();
      return;
   }

   ObjectCreate(0, HELP_BG, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, HELP_BG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, HELP_BG, OBJPROP_XDISTANCE, 15);
   ObjectSetInteger(0, HELP_BG, OBJPROP_YDISTANCE, 55);
   ObjectSetInteger(0, HELP_BG, OBJPROP_XSIZE, 660);
   ObjectSetInteger(0, HELP_BG, OBJPROP_YSIZE, 290);
   ObjectSetInteger(0, HELP_BG, OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, HELP_BG, OBJPROP_BORDER_COLOR, clrSilver);
   ObjectSetInteger(0, HELP_BG, OBJPROP_SELECTABLE, false);

   string lines[];
   FillHelpLines(lines);

   for(int i = 0; i < ArraySize(lines); i++)
   {
      string lineName = HELP_LINE_PREFIX + IntegerToString(i);
      ObjectCreate(0, lineName, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(0, lineName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, lineName, OBJPROP_XDISTANCE, 25);
      ObjectSetInteger(0, lineName, OBJPROP_YDISTANCE, 120 + i * 20);
      ObjectSetInteger(0, lineName, OBJPROP_COLOR,
                       (i == 9) ? clrDeepSkyBlue : ((i == 0) ? clrGold : clrWhite));
      ObjectSetInteger(0, lineName, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, lineName, OBJPROP_XSIZE, 630);
      ObjectSetInteger(0, lineName, OBJPROP_YSIZE, 20);
      ObjectSetInteger(0, lineName, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(0, lineName, OBJPROP_BORDER_COLOR, clrBlack);
      ObjectSetInteger(0, lineName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, lineName, OBJPROP_READONLY, false);
      ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, lineName, OBJPROP_ZORDER, 100);
      ObjectSetString(0, lineName, OBJPROP_TEXT, lines[i]);
   }

   CreateLangButton(HELP_RU, 25, 62, 100, "Русский");
   CreateLangButton(HELP_EN, 130, 62, 100, "English");
   CreateLangButton(HELP_DE, 235, 62, 80, "Deutsch");
   CreateLangButton(HELP_ES, 320, 62, 70, "Español");
   CreateLangButton(HELP_ZH, 395, 62, 50, "中文");
   CreateLangButton(HELP_TR, 450, 62, 50, "Türkçe");
   CreateLangButton(HELP_HI, 25, 90, 72, "हिन्दी");
   CreateLangButton(HELP_AR, 103, 90, 72, "العربية");
   CreateLangButton(HELP_FR, 181, 90, 72, "Français");
   CreateLangButton(HELP_BN, 259, 90, 72, "বাংলা");
   CreateLangButton(HELP_PT, 337, 90, 72, "Português");
   CreateLangButton(HELP_ID, 415, 90, 72, "Indonesia");

   g_helpShown = true;
   ChartRedraw(0);
}

void HideHelp()
{
   if(!g_helpShown)
      return;
   ObjectDelete(0, HELP_BG);
   ObjectDelete(0, HELP_RU);
   ObjectDelete(0, HELP_EN);
   ObjectDelete(0, HELP_DE);
   ObjectDelete(0, HELP_ES);
   ObjectDelete(0, HELP_ZH);
   ObjectDelete(0, HELP_TR);
   ObjectDelete(0, HELP_HI);
   ObjectDelete(0, HELP_AR);
   ObjectDelete(0, HELP_FR);
   ObjectDelete(0, HELP_BN);
   ObjectDelete(0, HELP_PT);
   ObjectDelete(0, HELP_ID);
   for(int i = ObjectsTotal(0, 0, -1) - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, HELP_LINE_PREFIX) == 0)
         ObjectDelete(0, name);
   }
   g_helpShown = false;
   ChartRedraw(0);
}

void DestroyPanel()
{
   for(int i = ObjectsTotal(0, 0, -1) - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, PANEL_PREFIX) == 0)
         ObjectDelete(0, name);
   }
}

void ImportSymbols()
{
   if(IsTrialExpired())
   {
      SetStatus(TrialExpiredLine(g_helpLanguage), "Trial ended. Full version required.");
      return;
   }

   string pasted = g_inputText;
   if(ObjectFind(0, EDIT_SYMBOLS) >= 0)
   {
      pasted = ObjectGetString(0, EDIT_SYMBOLS, OBJPROP_TEXT);
      g_inputText = pasted;
   }
   if(Trim(pasted) == "")
   {
      SetStatus("No tickers.", "Press TXT and paste with Ctrl+V.");
      HideInputField();
      return;
   }

   string requested[];
   StringReplace(pasted, "\r", "\n");
   StringReplace(pasted, ",", "\n");
   StringReplace(pasted, "\t", "\n");
   StringReplace(pasted, ";", "\n");
   StringReplace(pasted, " ", "\n");
   int count = StringSplit(pasted, '\n', requested);
   if(count <= 0)
   {
      SetStatus("No tickers in the input.", "");
      HideInputField();
      return;
   }

   int found = 0, ambiguous = 0, missing = 0, added = 0;
   string selectedNames[];
   string missingNames = "";
   string ambiguousNames = "";
   int brokerSymbols = SymbolsTotal(false);

   for(int requestIndex = 0; requestIndex < count; requestIndex++)
   {
      string requestedName = Trim(requested[requestIndex]);
      if(requestedName == "" || StringSubstr(requestedName, 0, 1) == "#")
         continue;

      string matches[];
      int matchCount = FindBestMatches(requestedName, matches, brokerSymbols);

      if(matchCount == 0)
      {
         missing++;
         missingNames += (missingNames == "" ? "" : ", ") + requestedName;
         continue;
      }
      if(matchCount > 1)
      {
         ambiguous++;
         ambiguousNames += (ambiguousNames == "" ? "" : "; ") + requestedName;
      }

      for(int matchIndex = 0; matchIndex < matchCount; matchIndex++)
      {
         string match = matches[matchIndex];
         if(Contains(selectedNames, match))
            continue;

         int selectedCount = ArraySize(selectedNames);
         ArrayResize(selectedNames, selectedCount + 1);
         selectedNames[selectedCount] = match;
         found++;
      }
   }

   if(g_replaceMarketWatch)
   {
      int selected = SymbolsTotal(true);
      for(int i = selected - 1; i >= 0; i--)
         SymbolSelect(SymbolName(i, true), false);
   }

   for(int i = 0; i < ArraySize(selectedNames); i++)
      if(SymbolSelect(selectedNames[i], true))
         added++;

   string details = StringFormat("Found %d | added %d | missing %d | multi %d",
                                found, added, missing, ambiguous);
   string logDetails = details;
   if(missingNames != "") logDetails += " | missing: " + missingNames;
   if(ambiguousNames != "") logDetails += " | multi: " + ambiguousNames;

   string statusText = "Import complete. " + TrialDaysLine(g_helpLanguage, TrialDaysLeft());

   Print("Market Watch Bulk Loader Trial: ", logDetails);
   SetStatus(statusText, details);
   HideInputField();
}

int OnInit()
{
   g_replaceMarketWatch = InpReplaceMarketWatch;
   g_helpLanguage = DetectTerminalLanguage();
   g_trialExpired = IsTrialExpired();
   BuildPanel();
   if(g_trialExpired)
      SetStatus(TrialExpiredLine(g_helpLanguage), "Trial ended. Full version required.");
   else
      SetStatus("Ready. Press TXT, paste, press Copy.",
                TrialDaysLine(g_helpLanguage, TrialDaysLeft()));
   // The instructions window stays closed at start. Press ? to open it.
   Print("Market Watch Bulk Loader Trial: ", TRIAL_DAYS, " day(s) trial. Days left: ",
         TrialDaysLeft());
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   DestroyPanel();
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;
   ObjectSetInteger(0, sparam, OBJPROP_STATE, false);

   if(sparam == BUTTON_NOTE)
      ShowInputField();
   else if(sparam == BUTTON_HELP)
      ToggleHelp();
   else if(sparam == BUTTON_IMPORT)
      ImportSymbols();
   else if(sparam == HELP_RU || sparam == HELP_EN || sparam == HELP_DE || sparam == HELP_ES ||
           sparam == HELP_ZH || sparam == HELP_TR || sparam == HELP_HI || sparam == HELP_AR ||
           sparam == HELP_FR || sparam == HELP_BN || sparam == HELP_PT || sparam == HELP_ID)
   {
      int newLanguage = g_helpLanguage;
      if(sparam == HELP_RU) newLanguage = 0;
      if(sparam == HELP_EN) newLanguage = 1;
      if(sparam == HELP_DE) newLanguage = 2;
      if(sparam == HELP_ES) newLanguage = 3;
      if(sparam == HELP_ZH) newLanguage = 4;
      if(sparam == HELP_TR) newLanguage = 5;
      if(sparam == HELP_HI) newLanguage = 6;
      if(sparam == HELP_AR) newLanguage = 7;
      if(sparam == HELP_FR) newLanguage = 8;
      if(sparam == HELP_BN) newLanguage = 9;
      if(sparam == HELP_PT) newLanguage = 10;
      if(sparam == HELP_ID) newLanguage = 11;

      if(newLanguage != g_helpLanguage)
      {
         HideHelp();
         g_helpLanguage = newLanguage;
         ToggleHelp();
      }
   }
}
