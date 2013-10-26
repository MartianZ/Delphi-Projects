// Compile.cpp : ���� DLL Ӧ�ó���ĵ���������
//

#include "stdafx.h"
#include "Compile.h"
#include <Shlwapi.h>

#include <algorithm>
#include <string>
using namespace std;


COMPILE_API int __stdcall Compile(LPSTR lpFileName, LPSTR lpCompileCommand, LPSTR* lpCompileInfo)
{
	LPSTR buffer = new char[65536];
	ZeroMemory(buffer,sizeof(buffer));
	
	//MessageBox(NULL, lpCompileCommand, lpFileName, MB_OK);
	//�����ܵ�
	HANDLE hRPipe,hWPipe;
	SECURITY_ATTRIBUTES sa = {sizeof(SECURITY_ATTRIBUTES), NULL, TRUE};
	BOOL bCP = CreatePipe(&hRPipe, &hWPipe, &sa, 0);

	if(!bCP)
	{
		 
		char* strTemp = new char[255];
		sprintf(strTemp, "���������ܵ�ʧ�ܣ��������:%d",GetLastError());
		*lpCompileInfo = strTemp;
		delete []strTemp;
		delete []buffer;
		return COMP_PIPEERROR;
	}

	STARTUPINFO sui = {0};
	sui.cb = sizeof(STARTUPINFO);
	sui.dwFlags = STARTF_USESTDHANDLES|STARTF_USESHOWWINDOW;
	sui.wShowWindow = SW_HIDE;
	sui.hStdOutput = hWPipe;
	sui.hStdError = hWPipe;
	sui.hStdInput = hRPipe;

	PROCESS_INFORMATION pi;
	unsigned long CuandoSale;

	string sTempCC = lpCompileCommand;
	lstrReplace(&lpCompileCommand, lpFileName);	//��%s�滻���ļ���
	//MessageBox(NULL,lpCompileCommand,NULL,MB_OK);
	BOOL bTemp = CreateProcess(NULL, lpCompileCommand, &sa, &sa, true, CREATE_NEW_CONSOLE, NULL, NULL, &sui, &pi);

	if(bTemp != false)
	{
		do
		{
			CuandoSale = WaitForSingleObject(pi.hProcess,100);
		}
		while (CuandoSale == WAIT_TIMEOUT);
		
		unsigned long BytesRead = 0;
		LPSTR lpTempCompileInfo = new char[65536];
		lpTempCompileInfo[0] = '\0';
		
		CloseHandle(hWPipe);	//��ǰ�ر�д�������ֹ��ܵ��������ݵ���ReadFile����
		while(ReadFile(hRPipe, buffer, 65535, &BytesRead, NULL))
		{
			buffer[BytesRead] = 0;
			lstrcat(lpTempCompileInfo, buffer);
		}

/*		do
		{
			BytesRead = 0;
			ReadFile(hRPipe,buffer,65535,&BytesRead,NULL);
			buffer[BytesRead] = 0;
			OemToAnsi(buffer,buffer);
			lstrcat(lpTempCompileInfo, buffer);
		}while (BytesRead >= 65535);
		*/
		*lpCompileInfo = lpTempCompileInfo;	//strcpy(*lpCompileInfo, lpTempCompileInfo);
		CloseHandle(pi.hProcess);
		CloseHandle(pi.hThread);
	}
	else
	{
		*lpCompileInfo = "δ�ҵ�������";
		delete[] buffer;
		CloseHandle(hRPipe);
		CloseHandle(hWPipe);
		return COMP_CREATEPROCESSERROR;
	}
	delete[] buffer;
	CloseHandle(hRPipe);
	return COMP_SUCCEED;
}
void lstrReplace(LPSTR* lpStr1,LPSTR lpStr2)
{
	LPSTR lpTempStr = *lpStr1;
	LPSTR lpTempStrT = new char[65535];
	int j=0;
	int len = lstrlen(lpTempStr);
	for(int i=0;i <= len;i++)
	{
		if((lpTempStr[i] == '%') && (lpTempStr[i+1] == 's'))
		{
			for(int k=0;k<lstrlen(lpStr2);k++)
			{
				lpTempStrT[j+k] = lpStr2[k];
			}
			i++;
			j+=lstrlen(lpStr2);
		}
		else
		{
			lpTempStrT[j] = lpTempStr[i];
			j++;
		}
	}
	*lpStr1 = lpTempStrT;
}
