/*
	real time subtitle translate for PotPlayer using google API
*/

// string GetTitle() 														-> get title for UI
// string GetVersion														-> get version for manage
// string GetDesc()															-> get detail information
// string GetLoginTitle()													-> get title for login dialog
// string GetLoginDesc()													-> get desc for login dialog
// string ServerLogin(string User, string Pass)								-> login
// string ServerLogout()													-> logout
// array<string> GetSrcLangs() 												-> get source language
// array<string> GetDstLangs() 												-> get target language
// string Translate(string Text, string &in SrcLang, string &in DstLang) 	-> do translate !!

string JsonParseOld(string json)
{
	JsonReader Reader;
	JsonValue Root;
	string ret = "";	
	
	if (Reader.parse(json, Root) && Root.isArray())
	{
		for (int i = 0, len = Root.size(); i < len; i++)
		{
			JsonValue child1 = Root[i];
			
			if (child1.isArray())
			{
				for (int j = 0, len = child1.size(); j < len; j++)
				{		
					JsonValue child2 = child1[j];
					
					if (child2.isArray())
					{
						JsonValue item = child2[0];
				
						if (item.isString()) ret = ret + item.asString();
					}
				}
				break;
			}
		}
	} 
	return ret;
}

string JsonParseNew(string json)
{
	JsonReader Reader;
	JsonValue Root;
	string ret = "";	
	
	if (Reader.parse(json, Root) && Root.isObject())
	{
		JsonValue data = Root["data"];
			
		if (data.isObject())
		{
			JsonValue translations = data["translations"];
			
			if (translations.isArray())
			{
				for (int j = 0, len = translations.size(); j < len; j++)
				{		
					JsonValue child1 = translations[j];
					
					if (child1.isObject())
					{
						JsonValue translatedText = child1["translatedText"];
				
						if (translatedText.isString()) ret = ret + translatedText.asString();
					}
				}
			}
		}
	} 
	return ret;
}

array<string> LangTable = 
{
	"af",
	"sq",
	"am",
	"ar",
	"hy",
	"az",
	"eu",
	"be",
	"bn",
	"bh",
	"bs",
	"bg",
	"my",
	"ca",
	"ceb",
// 	"chr",
//	"zh",
	"zh-CN",
	"zh-TW",
	"hr",
	"cs",
	"da",
// 	"dv",
	"nl",
	"en",
	"eo",
	"et",
	"tl",
	"fi",
	"fr",
	"gl",
	"ka",
	"de",
	"el",
// 	"gn",
	"gu",
	"ht",
	"ha",
	"iw",
	"hi",
	"hmn",
	"hu",
	"is",
	"ig",
	"id",
	"ga",
// 	"iu",
	"it",
	"ja",
	"jw",
	"kn",
	"kk",
	"km",
	"ko",
	"ku",
	"ky",
	"lo",
	"la",
	"lv",
	"lt",
	"mk",
	"ms",
	"ml",
	"mt",
	"mi",
	"mr",
	"mn",
	"ne",
	"no",
//	"or",
	"ps",
	"fa",
	"pl",
	"pt",
	"pa",
	"ro",
//	"romanji",
	"ru",
//	"sa",
	"sr",
	"sd",
	"st",
	"si",
	"sk",
	"sl",
	"so",
	"es",
	"sw",
	"sv",
	"sw",
	"tg",
	"ta",
//	"tl",
	"te",
	"th",
//	"bo",
	"tr",
	"uk",
	"ur",
	"uz",
//	"ug",
	"vi",
	"cy",
	"xh",
	"yi",
	"yo",
	"zu"
};

string UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.97 Safari/537.36";

string GetTitle()
{
	return "{$CP949=구글 번역Fix$}{$CP950=Google 翻譯Fix$}{$CP0=Google translateFix$}";
}

string GetVersion()
{
	return "1";
}

string GetDesc()
{
	return "https://translate.google.cn";
}

string GetLoginTitle()
{
	return "Input google API key";
}

string GetLoginDesc()
{
	return "Input google API key to user name";
}

string api_key;

string ServerLogin(string User, string Pass)
{
	api_key = User;
	if (api_key.empty()) return "fail";
	return "200 ok";
}

void ServerLogout()
{
	api_key = "";
}

array<string> GetSrcLangs()
{
	array<string> ret = LangTable;
	
	ret.insertAt(0, ""); // empty is auto
	return ret;
}

array<string> GetDstLangs()
{
	array<string> ret = LangTable;
	
	return ret;
}

array<string> split(string str, string delimiter) 
{
	array<string> parts;
	int startPos = 0;
	while (true) {
		int index = str.findFirst(delimiter, startPos);
		if ( index == -1 ) {
			parts.insertLast( str.substr(startPos) );
			break;
		}
		else {
			parts.insertLast( str.substr(startPos, index - startPos) );
			startPos = index + delimiter.length();
		}
	}
	return parts;
}

string CalcTK(string s,string tkk) {
	array<string> tkks = split(tkk,".");
	uint64 t0,t1,t0bak;
	t0 = parseUInt(tkks[0]);
	t0bak=t0;
	t1 = parseUInt(tkks[1]);
	for(uint i=0;i<s.length();i++){
		t0 += s[i];
		t0 &= 0xffffffff;
		t0 += t0<<10;
		t0 &= 0xffffffff;
        t0 ^= t0>>>6;
		t0 &= 0xffffffff;
	}
	t0 += t0 << 3;
	t0 &= 0xffffffff;
    t0 ^= t0 >>>11;
	t0 &= 0xffffffff;
    t0 += t0 <<15;
	t0 &= 0xffffffff;
	t0 ^= t1;
	if(t0<0){
        t0 = (t0 & 0x7ffffffff) + 0x80000000;
    }
    t0 %= 1000000;
	t0bak ^= t0;
	return formatUInt(t0)+"."+formatUInt(t0bak);
}

string GetTkk(string htmlData){
	int idx = htmlData.findFirst("tkk:'", 0);
	htmlData = htmlData.substr(idx+5);
	idx = htmlData.findFirst("'", 0);
	htmlData = htmlData.substr(0,idx);
	return htmlData;
}


string tkk = "";

string Translate(string Text, string &in SrcLang, string &in DstLang)
{
//HostOpenConsole();	// for debug
	if(tkk.length() <= 0){
		string getTkkUrl = "https://translate.google.cn";
		string html = HostUrlGetString(getTkkUrl, UserAgent);
		tkk = GetTkk(html);
	}

	if (SrcLang.length() <= 0) SrcLang = "auto";
	SrcLang.MakeLower();
	
	string enc = HostUrlEncode(Text);
	
	if (api_key.length() > 0)
	{
		string url = "https://translation.googleapis.com/language/translate/v2?target=" + DstLang + "&q=" + enc;
		if (!SrcLang.empty() && SrcLang != "auto") url = url + "&source=" + SrcLang;
		url = url + "&key=" + api_key;
		string text = HostUrlGetString(url, UserAgent);
		string ret = JsonParseNew(text);		
		if (ret.length() > 0)
		{
			SrcLang = "UTF8";
			DstLang = "UTF8";
			return ret;
		}	
	}
	
//	API.. Always UTF-8
	string tk = CalcTK(Text,tkk);
	string url = "https://translate.google.cn/translate_a/single?client=webapp&sl="+SrcLang+"&tl="+DstLang+"&dt=t&tk="+tk+"&q="+enc;
	string text = HostUrlGetString(url, UserAgent);
	string ret = JsonParseOld(text);
	if (ret.length() > 0)
	{
		SrcLang = "UTF8";
		DstLang = "UTF8";
		return ret;
	}	

	return ret;
}
