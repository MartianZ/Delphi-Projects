// 下列 ifdef 块是创建使从 DLL 导出更简单的
// 宏的标准方法。此 DLL 中的所有文件都是用命令行上定义的 COMPILE_EXPORTS
// 符号编译的。在使用此 DLL 的
// 任何其他项目上不应定义此符号。这样，源文件中包含此文件的任何其他项目都会将
// COMPILE_API 函数视为是从 DLL 导入的，而此 DLL 则将用此宏定义的
// 符号视为是被导出的。

#pragma comment(linker, "/EXPORT:iCompile=?Compile@@YGHPAD0PAPAD@Z")

#ifdef COMPILE_EXPORTS
#define COMPILE_API __declspec(dllexport)
#else
#define COMPILE_API __declspec(dllimport)
#endif

#define COMP_SUCCEED				0
#define COMP_PIPEERROR				1
#define COMP_CREATEPROCESSERROR		2

/*
功能：把%s.cpp/c/pas编译为%s.exe保存在当前目录
参数：
	lpFileName：文件名
	lpCompileCommand：编译命令，语法见cena
	lpCompileInfo：缓冲区，要足够大，用来返回编译信息
*/
COMPILE_API int __stdcall iCompile(LPSTR lpFileName, LPSTR lpCompileCommand, LPSTR* lpCompileInfo);

void lstrReplace(LPSTR* lpStr1,LPSTR lpStr2);
