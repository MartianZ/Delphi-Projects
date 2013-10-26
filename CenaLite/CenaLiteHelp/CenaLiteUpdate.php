<?
//----------------------------------
/*
	CenaLite 检测是否存在新版本
	By Martian 
	2011年1月17日17:34:43
*/
//----------------------------------
function Get_Client_IP()
{
	if ($_SERVER['REMOTE_ADDR']) {
		$cip = $_SERVER['REMOTE_ADDR'];
	} elseif (getenv("REMOTE_ADDR")) {
		$cip = getenv("REMOTE_ADDR");
	} elseif (getenv("HTTP_CLIENT_IP")) {
		$cip = getenv("HTTP_CLIENT_IP");
	} else {
		$cip = "UnKnown";
	}
	return $cip;
}
$LatestVersion="20110117"; //yyyyMMdd格式 Build版本号

$NowVersion=$_GET["version"]; 

$RequestIP=Get_Client_IP();

if (!is_numeric($NowVersion))
{
	echo "Illegal Request!";
	exit;
}
//Gather User Information
$DOCUMENT_ROOT = $_SERVER["DOCUMENT_ROOT"]."/UserInfo.txt";
$fp = fopen($DOCUMENT_ROOT,"a");
$content = "Version:$NowVersion IP:$RequestIP\n";
fwrite($fp,$content);
fclose($fp);

if ($NowVersion<$LatestVersion)
{
	echo "UpdateRequired";
}
?>