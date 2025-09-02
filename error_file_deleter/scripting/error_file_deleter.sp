#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
    name = "Error Files Deleter",
    author = "夜羽真白, Hitomi",
    description = "自动删除 error_logs 和 confoglcompmod 的 logs",
    version = "1.5",
    url = "https://github.com/cy115/"
}

static char
    logPath[PLATFORM_MAX_PATH],
    ccPath[PLATFORM_MAX_PATH],
    fileName[PLATFORM_MAX_PATH];

static DirectoryListing
    listing;

static FileType
    fileType;

static int
    monthDay[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    BuildPath(Path_SM, logPath, sizeof(logPath), "logs");
    if (!DirExists(logPath, false, NULL_STRING)) {
        strcopy(error, err_max, "[EFD]：无法打开 sourcemod/logs 文件夹，文件夹不存在");

        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

public void OnPluginStart()
{
    BuildPath(Path_SM, ccPath, sizeof(ccPath), "logs/confoglcompmod");
    DeleteSourcemodLogs();
    DeleteConfoglCompmodLogs();
}

public void OnPluginEnd()
{
    delete listing;
}

void DeleteSourcemodLogs()
{
    listing = OpenDirectory(logPath, false, NULL_STRING);
    while (listing.GetNext(fileName, sizeof(fileName), fileType)) {
        if (!(fileType & FileType_File)) {
            continue;
        }

        TrimString(fileName);
        char timeStr[32] = {'\0'}, nowTimeStr[32] = {'\0'};
        FormatTime(nowTimeStr, sizeof(nowTimeStr), "%Y%m%d");
        if (fileName[0] == 'e' && strcmp(fileName[16], "log") == 0) {
            strcopy(timeStr, sizeof(timeStr), subString(fileName, 8, 8));
        }
        else if (fileName[0] == 'L' && strcmp(fileName[10], "log") == 0) {
            strcopy(timeStr, sizeof(timeStr), subString(fileName, 2, 8));
        }
        else {
            continue;
        }

        int year = getYear(timeStr), month = getMonth(timeStr), day = getDay(timeStr), sumYearDay = sumDay(month, day);
        int nowYear = getYear(nowTimeStr), nowMonth = getMonth(nowTimeStr), nowDay = getDay(nowTimeStr), sumNowYearDay = sumDay(nowMonth, nowDay), yearInterval = yearDayDiff(year, nowYear);
        if (isLeapYear(year) && month >= 3) {
            sumYearDay += 1;
        }

        if (isLeapYear(nowYear) && nowMonth >= 3) {
            sumNowYearDay += 1;
        }

        char msg[PLATFORM_MAX_PATH] = {'\0'};
        if (sumNowYearDay - sumYearDay + yearInterval > 10) {
            FormatEx(msg, sizeof(msg), "%s\\%s", logPath, fileName);
            DeleteFile(msg);
        }
    }
    
    delete listing;
}

void DeleteConfoglCompmodLogs()
{
    listing = OpenDirectory(ccPath, false, NULL_STRING);
    while (listing.GetNext(fileName, sizeof(fileName), fileType)) {
        if (!(fileType & FileType_File)) {
            continue;
        }

        TrimString(fileName);
        char timeStr[32] = {'\0'}, nowTimeStr[32] = {'\0'};
        FormatTime(nowTimeStr, sizeof(nowTimeStr), "%Y%m%d");
        if (fileName[0] == 'e' && strcmp(fileName[16], "log") == 0) {
            strcopy(timeStr, sizeof(timeStr), subString(fileName, 8, 8));
        }
        else if (fileName[0] == 'L' && strcmp(fileName[10], "log") == 0) {
            strcopy(timeStr, sizeof(timeStr), subString(fileName, 2, 8));
        }
        else {
            continue;
        }

        int year = getYear(timeStr), month = getMonth(timeStr), day = getDay(timeStr), sumYearDay = sumDay(month, day);
        int nowYear = getYear(nowTimeStr), nowMonth = getMonth(nowTimeStr), nowDay = getDay(nowTimeStr), sumNowYearDay = sumDay(nowMonth, nowDay), yearInterval = yearDayDiff(year, nowYear);
        if (isLeapYear(year) && month >= 3) {
            sumYearDay += 1;
        }

        if (isLeapYear(nowYear) && nowMonth >= 3) {
            sumNowYearDay += 1;
        }

        char msg[PLATFORM_MAX_PATH] = {'\0'};
        if (sumNowYearDay - sumYearDay + yearInterval > 10) {
            FormatEx(msg, sizeof(msg), "%s\\%s", ccPath, fileName);
            DeleteFile(msg);
        }
    }
    
    delete listing;
}

char[] subString(const char[] str, int start, int end)
{
    int index = 0;
    char resultStr[32] = {'\0'};
    for (int i = 0; i < end; i++) {
        resultStr[index++] = str[start - 1 + i];
    }

    return resultStr;
}

int getYear(const char[] str)
{
    return StringToInt(subString(str, 1, 4));
}

int getMonth(const char[] str)
{
    return StringToInt(subString(str, 5, 2));
}

int getDay(const char[] str)
{
    return StringToInt(subString(str, 7, 2));
}

int yearDayDiff(int year1, int year2)
{
    int day = (year2 - year1) * 365;
    for (int i = year1; i < year2; i++) {
        if (isLeapYear(i)) {
            day += 1;
        }
    }

    return day;
}

int sumDay(int month, int day)
{
    for (int i = 0; i < month - 1; i++) {
        day += monthDay[i];
    }

    return day;
}

bool isLeapYear(int year)
{
    return ((year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0));
}