// ���� ifdef ���Ǵ���ʹ�� DLL �������򵥵�
// ��ı�׼�������� DLL �е������ļ��������������϶���� COMPILE_EXPORTS
// ���ű���ġ���ʹ�ô� DLL ��
// �κ�������Ŀ�ϲ�Ӧ����˷��š�������Դ�ļ��а������ļ����κ�������Ŀ���Ὣ
// COMPILE_API ������Ϊ�Ǵ� DLL ����ģ����� DLL ���ô˺궨���
// ������Ϊ�Ǳ������ġ�

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
���ܣ���%s.cpp/c/pas����Ϊ%s.exe�����ڵ�ǰĿ¼
������
	lpFileName���ļ���
	lpCompileCommand����������﷨��cena
	lpCompileInfo����������Ҫ�㹻���������ر�����Ϣ
*/
COMPILE_API int __stdcall iCompile(LPSTR lpFileName, LPSTR lpCompileCommand, LPSTR* lpCompileInfo);

void lstrReplace(LPSTR* lpStr1,LPSTR lpStr2);
