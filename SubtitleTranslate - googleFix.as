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

string JsonParse_for_openapi(string json)
{
	JsonReader Reader;
	JsonValue Root;
	string err_msg = "translate fail :(";
	// HostPrintUTF8(json);

	if (Reader.parse(json, Root))
	{
		string sub_json = Root[0][2].asString();
		if (Reader.parse(sub_json, Root))
		{
			string ans ="";
			JsonValue translations = Root[1][0][0][5];
			for (int i = 0, len = translations.size(); i < len; i++)
			{
				ans += translations[i][0].asString();
			}
			return ans;
		}
			
		return err_msg;
	} 
	return err_msg;
}

array<string> LangTable = 
{
	"af", "sq", "am", "ar", "hy", "az", "eu", "be", "bn", "bh", "bs", "bg", "my", "ca", "ceb",
	"zh-CN","zh-TW","hr","cs","da","nl","en","eo","et","tl","fi","fr","gl","ka","de","el","gu",
	"ht","ha","iw","hi","hmn","hu","is","ig","id","ga","it","ja","jw","kn","kk","km","ko","ku",
	"ky","lo","la","lv","lt","mk","ms","ml","mt","mi","mr","mn","ne","no","ps","fa","pl","pt",
	"pa","ro","ru","sr","sd","st","si","sk","sl","so","es","sw","sv","sw","tg","ta","te","th",
	"tr","uk","ur","uz","vi","cy","xh","yi","yo","zu"
};

string UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.97 Safari/537.36";
string TranslateHost = "translate.google.cn";
string RPC_ID = 'MkEWBc';

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

string Translate(string Text, string &in SrcLang, string &in DstLang)
{
	// HostOpenConsole();	// for debug

	if (SrcLang.length() <= 0) SrcLang = "auto";
	SrcLang.MakeLower();
	
	// use user's api_key
	if (api_key.length() > 0)
	{
		string enc = HostUrlEncode(Text);
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
	
	// use open api(for free)
	string rpc_url = "https://"+TranslateHost+"/_/TranslateWebserverUi/data/batchexecute?rpcids="+RPC_ID+"&bl=boq_translate-webserver_20210630.09_p0&soc-app=1&soc-platform=1&soc-device=1&rt=c";

	string post_data1 = "[[[\"MkEWBc\",\"[[\\\"";
	string post_data2 = "\\\",\\\""+SrcLang+"\\\",\\\""+DstLang+"\\\",true],[null]]\",null,\"generic\"]]]";
	Text.replace("\\","\\\\");
	Text.replace("\"","\\\"");
	Text.replace("\\","\\\\");
	Text.replace("\"","\\\"");
	Text.replace("\n","\\\\n");
	Text.replace("\r","\\\\r");
	Text.replace("\t","\\\\t");
	string enc_text = Text;
	string post_data = "f.req="+HostUrlEncode(post_data1+enc_text+post_data2);

	string SendHeader = "Content-Type: application/x-www-form-urlencoded";
	
	string text = HostUrlGetString(rpc_url, UserAgent, SendHeader, post_data);
	
	text.replace("\n","");
	int start_pos = text.findFirst("[[", 0);
	int end_pos = text.findLast("]]", -1);
	text=text.substr(start_pos, end_pos - start_pos);
	end_pos = text.findLast("]]", -1);
	text=text.substr(0, end_pos+2);
	string ret = JsonParse_for_openapi(text);
	if (ret.length() > 0)
	{
		SrcLang = "UTF8";
		DstLang = "UTF8";
		return ret;
	}	

	return ret;
}
