package main

import (
	"archive/tar"
	"compress/gzip"
	b64 "encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/go-redis/redis"
)

const debugMode = false
const BufferSize = 32000

//const nginxConfDir = "/tmp/varnish-tenants.d/"
const nginxConfDir = "/opt/nginx/conf/nginx-tenants.d/"
const varnishConfDir = "/opt/varnish/conf/varnish-tenants.d/"
const redisConfDir = "/opt/redis/conf/redis-tenants.d/"
const kubeConfDir = "/opt/kube/conf/kube-tenants.d/"
const apiKeySignKeyFile = "/home/ec2-user/api_sign.key"

var redisHostStr = os.Getenv("REDIS_HOST")
var redisPortStr = os.Getenv("REDIS_PORT")
var mySigningKeyStr = initSignKeyStr()

func initSignKeyStr() string {
	//if file exists, read it and return it
	var apiJWTPassphrase = ""
	exist := fileExists(apiKeySignKeyFile)

	if exist {
		apiJWTPassphrase = readContentFromFile(apiKeySignKeyFile)
		apiJWTPassphrase = strings.TrimSpace(apiJWTPassphrase)
		fmt.Println("apiJWTPassphrase value from file:", apiJWTPassphrase)

	} else {
		apiJWTPassphrase = os.Getenv("SIGN_KEY")
		fmt.Println("apiJWTPassphrase value from ENV var:", apiJWTPassphrase)
	}

	if apiJWTPassphrase == "" {
		apiJWTPassphrase = "lonewolfattacksarebad"
		fmt.Println("apiJWTPassphrase default value:", apiJWTPassphrase)
	}
	return apiJWTPassphrase
}

type RedisConf struct {
	RedisHost string `json:"redis_host"`
	RedisPort string `json:"redis_port"`
}

var mySigningKey = []byte(mySigningKeyStr)
var fileContentStr = ""

func isAuthorized(endpoint func(http.ResponseWriter, *http.Request)) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		if r.Header["Token"] != nil {

			token, err := jwt.Parse(r.Header["Token"][0], func(token *jwt.Token) (interface{}, error) {
				if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, fmt.Errorf("There was an error")
				}
				return mySigningKey, nil
			})

			if err != nil {
				fmt.Fprintf(w, err.Error())
			}

			if token.Valid {
				endpoint(w, r)
			}
		} else {
			w.WriteHeader(http.StatusForbidden)
			fmt.Fprintf(w, "Not Authorized")
		}
	})
}

func runSystemD(optionStr string, serviceNameStr string) {

	if debugMode {
		fmt.Println("systemctl: ", optionStr+" "+serviceNameStr)

	} else {
		cmd := exec.Command("sudo", "-S", "systemctl", optionStr, serviceNameStr)
		cmd.Stderr = os.Stderr
		cmd.Stdin = os.Stdin

		out, err := cmd.Output()
		if err != nil {
			fmt.Println("runSystemD Err", err)
		} else {
			fmt.Println("runSystemD OUT:", string(out))
		}
	}
}

func runCmd0(cmdStr string) string {

	if debugMode {
		return ("runCmd: " + cmdStr)
	} else {

		cmd := exec.Command("sudo", "-S", cmdStr)
		cmd.Stderr = os.Stderr
		cmd.Stdin = os.Stdin
		var responseStr = ""
		out, err := cmd.Output()
		if err != nil {
			responseStr = err.Error()
		} else {
			responseStr = string(out)
		}
		return responseStr
	}
	return ""
}

func runCmd2(cmdStr string, arg1Str string, arg2Str string) string {

	if debugMode {
		return ("runCmd: " + cmdStr + " " + arg1Str + " " + arg2Str)
	} else {

		cmd := exec.Command("sudo", "-S", cmdStr, arg1Str, arg2Str)
		cmd.Stderr = os.Stderr
		cmd.Stdin = os.Stdin
		var responseStr = ""
		out, err := cmd.Output()
		if err != nil {
			responseStr = err.Error()
		} else {
			responseStr = string(out)
		}
		return responseStr
	}
	return ""
}

func runCmdStdOut(cmdStr string, arg1Str string, arg2Str string, arg3Str string, arg4Str string) string {

	if debugMode {
		return ("runCmd: " + cmdStr + " " + arg1Str + " " + arg2Str + " " + arg3Str + " " + arg4Str)
	} else {

		cmd := exec.Command("sudo", "-S", cmdStr, arg1Str, arg2Str, arg3Str, arg4Str)
		cmd.Stderr = os.Stderr
		cmd.Stdin = os.Stdin
		var responseStr = ""
		out, err := cmd.Output()
		if err != nil {
			responseStr = err.Error()
		} else {
			responseStr = string(out)
		}
		return responseStr
	}
	return ""
}

func runCmd(cmdStr string, arg1Str string, arg2Str string, arg3Str string, arg4Str string) {

	if debugMode {
		fmt.Println("runCmd: ", cmdStr+" "+arg1Str+" "+arg2Str+" "+arg3Str+" "+arg4Str)
	} else {
		cmd := exec.Command("sudo", "-S", cmdStr, arg1Str, arg2Str, arg3Str, arg4Str)
		cmd.Stderr = os.Stderr
		cmd.Stdin = os.Stdin

		out, err := cmd.Output()
		if err != nil {
			fmt.Println("Err: ", err)
		} else {
			fmt.Println("OUT: ", string(out))
		}
	}
}

//v1 api we are going to target amazon linux and openresty binary
//v2 api we are going to target ubuntu linux and openresty binary
//v3 api we are going to target windows and openresty binary
//v4 api we are going to target mac and openresty binary

func getOS() string {
	os := runtime.GOOS
	switch os {
	case "windows":
		return "Windows"

	case "darwin":
		return "MAC"
	case "linux":
		return "Linux"
	default:
		fmt.Printf("%s.\n", os)
		return "amazon-linux"
	}
}

func runBashFile(cmdStr string) {
	cmd := exec.Command("/bin/bash", cmdStr)
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	out, err := cmd.Output()
	if err != nil {
		fmt.Println("Err", err)
	} else {
		fmt.Println("OUT:", string(out))
	}
}

func fileNameWithoutExtTrimSuffix(fileName string) string {
	return strings.TrimSuffix(fileName, filepath.Ext(fileName))
}

func touchPath(pDirStr string) {
	var err = os.MkdirAll(pDirStr, os.FileMode(0755)) // or use 0755 if you prefer

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	//runCmd("chmod", "666", "/var/run/varnish/varnish.sock", "", "")
	// if err := os.Chmod(pDirStr, 755); err != nil {
	// 	log.Fatal(err)
	// }

	//runCmd("chown", "-R", "ec2-user", pDirStr, "")
	// if err := os.Chown(pDirStr, 755); err != nil {
	// 	log.Fatal(err)
	// }

}

func touchFilePath(pDirStr string, pFileNameStr string) {
	touchPath(pDirStr)
	//runCmd("chmod", "666", "/var/run/varnish/varnish.sock", "", "")
	if err := os.Chmod(pFileNameStr, 666); err != nil {
		log.Fatal(err)
	}
}

func fileNameTest() {
	fmt.Println(fileNameWithoutExtTrimSuffix("abc.txt")) // abc
}

func lsDirPath(w http.ResponseWriter, req *http.Request) {
	fmt.Println("VCL File names list print")

	//items, _ := ioutil.ReadDir(nginxConfDir)
	items, _ := ioutil.ReadDir("/tmp/")

	for _, item := range items {
		if item.IsDir() {
			// fmt.Println("DIRNAME: ")
			// subitems, _ := ioutil.ReadDir(item.Name())
			// for _, subitem := range subitems {
			// 	if !subitem.IsDir() {
			// 		// handle file there
			// 		fmt.Println(item.Name() + "/" + subitem.Name())
			// 	}
			// }
		} else {
			// handle file there
			var fileNameStr = item.Name()
			var fileExtStr = path.Ext(fileNameStr)
			var fileNameWithoutExtStr = fileNameWithoutExtTrimSuffix(fileNameStr)
			if fileExtStr == ".vcl" {
				fmt.Println("VCLFileName vcl: " + fileNameWithoutExtStr + ", extension: " + fileExtStr)

			} else {
				fmt.Println("VCLFileName not vcl: " + fileNameWithoutExtStr + ", extension: " + fileExtStr)

			}
		}
	}
}

func check(e error) {
	if e != nil {
		panic(e)
	}
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return !os.IsNotExist(err)
}

func readContentFromFile(filepath string) string {

	fileContentStr = ""
	file, err := os.Open(filepath)
	if err != nil {
		fmt.Println(err)
		return ""
	}
	defer file.Close()

	buffer := make([]byte, BufferSize)

	for {
		bytesread, err := file.Read(buffer)
		if err != nil {
			if err != io.EOF {
				fmt.Println(err)
			}
			break
		}
		//fmt.Println("bytes read: ", bytesread)
		fileContentStr = string(buffer[:bytesread])
		//fmt.Println("bytestream to string: ", fileContentStr)
	}
	fmt.Printf("{\"fn\":\"readContentFromFile\",\"path\":\"%s\"}\n", filepath)
	return fileContentStr
}

func writeContentToFile(content string, filepath string) {

	exist := fileExists(filepath)

	if exist {
		fmt.Println("file exist: " + filepath)
		e := os.Remove(filepath)
		if e != nil {
			log.Fatal(e)
		}

	} else {

		fmt.Println("file does not exist")
	}

	f, err := os.Create(filepath)

	if err != nil {
		log.Fatal(err)
	}

	defer f.Close()

	_, err2 := f.WriteString(content)

	if err2 != nil {
		log.Fatal(err2)
	}
	fmt.Printf("{\"fn\":\"writeContentToFile\",\"path\":\"%s\"}\n", filepath)
}

func readContentToFile(filepath string) string {

	fmt.Printf("{\"fn\":\"readContentToFile\",\"path\":\"%s\"}", filepath)
	return "readContentToFile"
}

// File copies a single file from src to dst
func File(src, dst string) error {
	var err error
	var srcfd *os.File
	var dstfd *os.File
	var srcinfo os.FileInfo

	if srcfd, err = os.Open(src); err != nil {
		return err
	}
	defer srcfd.Close()

	if dstfd, err = os.Create(dst); err != nil {
		return err
	}
	defer dstfd.Close()

	if _, err = io.Copy(dstfd, srcfd); err != nil {
		return err
	}
	if srcinfo, err = os.Stat(src); err != nil {
		return err
	}
	return os.Chmod(dst, srcinfo.Mode())
}

// Dir copies a whole directory recursively
func Dir(src string, dst string) error {
	var err error
	var fds []os.FileInfo
	var srcinfo os.FileInfo

	if srcinfo, err = os.Stat(src); err != nil {
		return err
	}

	if err = os.MkdirAll(dst, srcinfo.Mode()); err != nil {
		return err
	}

	if fds, err = ioutil.ReadDir(src); err != nil {
		return err
	}
	for _, fd := range fds {
		srcfp := path.Join(src, fd.Name())
		dstfp := path.Join(dst, fd.Name())

		if fd.IsDir() {
			if err = Dir(srcfp, dstfp); err != nil {
				fmt.Println(err)
			}
		} else {
			if err = File(srcfp, dstfp); err != nil {
				fmt.Println(err)
			}
		}
	}
	return nil
}

func ensureDir(dirName string) error {
	err := os.Mkdir(dirName, 0777)
	if err == nil {
		return nil
	}
	if os.IsExist(err) {
		// check that the existing path is a directory
		info, err := os.Stat(dirName)
		if err != nil {
			return err
		}
		if !info.IsDir() {
			return errors.New("path exists but is not a directory")
		}
		return nil
	}
	return err
}

//untar file
func untarFile(sourceFile string, nginxConfDir string, renameStr string) {

	//flag.Parse() // get the arguments from command line

	//sourceFile := flag.Arg(0)

	if sourceFile == "" {
		fmt.Println("Usage : go-untar sourceFile.tar")
		os.Exit(1)
	}

	var err = os.MkdirAll(nginxConfDir, os.FileMode(0755)) // or use 0755 if you prefer

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	file, err := os.Open(sourceFile)

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	defer file.Close()

	var fileReader io.ReadCloser = file

	// just in case we are reading a tar.gz file, add a filter to handle gzipped file
	if strings.HasSuffix(sourceFile, ".gz") {
		if fileReader, err = gzip.NewReader(file); err != nil {

			fmt.Println(err)
			os.Exit(1)
		}
		defer fileReader.Close()
	}

	tarBallReader := tar.NewReader(fileReader)

	// Extracting tarred files
	var dirNameFromTar = ""

	for {
		header, err := tarBallReader.Next()
		if err != nil {
			if err == io.EOF {
				break
			}
			fmt.Println(err)
			os.Exit(1)
		}

		// get the individual filename and extract to the current directory
		filename := header.Name
		if dirNameFromTar == "" {
			dirNameFromTar = filename
		}
		switch header.Typeflag {
		case tar.TypeDir:
			// handle directory
			fmt.Println("Creating directory :", filename)
			err = os.MkdirAll(filename, os.FileMode(header.Mode)) // or use 0755 if you prefer

			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}

		case tar.TypeReg:
			// handle normal file
			//fmt.Println("Untarring :", filename)
			writer, err := os.Create(filename)

			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}

			io.Copy(writer, tarBallReader)

			err = os.Chmod(filename, os.FileMode(header.Mode))

			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}

			writer.Close()

			//runCmd("rm", "-Rf", filename, "._*", "")

		default:
			fmt.Printf("Unable to untar type : %c in file %s", header.Typeflag, filename)
		}
	}

	fmt.Printf("DIR NAME : %s", renameStr)
	Dir(renameStr, nginxConfDir)
	errRemoveAll := os.RemoveAll(dirNameFromTar)
	if errRemoveAll != nil {
		log.Fatal(err)
	}

}

//kubernetes tenant create
func kubectl_apply() {
	runCmd("kubectl", "-f", "/opt/kube/conf/kube-tenants.d/", "", "")

}

// Nginx

// func nginxConfigDeployTenant() {
// 	runBashFile("/opt/nginx/scripts/nginx-deploy-tenant-config.sh")
// }
func apiTenantCreateInstance(w http.ResponseWriter, req *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPSAPI: Tenant instance created ok"}`))
}

func apiNginxConfigList(w http.ResponseWriter, req *http.Request) {
	fmt.Println("{\"func\": \"apiNginxListConfigFiles\"}")
	apiNginxListConfigFiles()
	json.NewEncoder(w).Encode(NginxConfigFilesList)
	// w.WriteHeader(http.StatusOK)
	// w.Header().Set("Content-Type", "application/json")
	//w.Write([]byte(`{"message":"The OPS API: nginx list goes here"}`))
}

func apiNginxConfigJSONList(w http.ResponseWriter, req *http.Request) {
	fmt.Println("{\"func\": \"apiNginxConfigJSONList\"}")
	apiNginxListJSONFiles()
	json.NewEncoder(w).Encode(NginxConfigFilesList)
	// w.WriteHeader(http.StatusOK)
	// w.Header().Set("Content-Type", "application/json")
	//w.Write([]byte(`{"message":"The OPS API: nginx list goes here"}`))
}

func apiNginxBinaryPath(w http.ResponseWriter, req *http.Request) {
	var nginxBinPathStr = nginxBinaryPath()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPSAPI: Nginx Bin Path", "path": "` + nginxBinPathStr + `"}`))
}

//like which command on linux
func nginxBinaryPath() string {
	//runBashFile("/opt/nginx/scripts/nginx-configtest.sh")
	path, err := exec.LookPath("openresty")
	if err != nil {
		log.Fatal("installing openresty is in your future")
	}
	//fmt.Printf("openresty is available at %s\n", path)
	return path
}

func killBinaryPath() string {
	path, err := exec.LookPath("kill")
	if err != nil {
		log.Fatal("installing kill is in your future")
	}
	return path
}

//echo $(ps -ef | grep 'nginx' | head -1 | awk '{print $2}') > /var/run/nginx.pid
//echo $(ps aux | grep 'nginx' | awk '{print $1}') > /var/run/nginx.pid
func nginxStopService() string {
	runSystemD("stop", "openresty.service")
	var nginxBinPathStr = nginxBinaryPath()
	//	var killBinPathStr = killBinaryPath()
	var resultStr = runCmd2(nginxBinPathStr, "-s", "stop")
	resultStr = runCmd2("rm", "-Rf", "/var/run/nginx.sock")
	return resultStr
}

func nginxStopServiceBash() string {
	runBashFile("/opt/nginx/scripts/nginx-stop.sh")
	var nginxBinPathStr = nginxBinaryPath()
	//	var killBinPathStr = killBinaryPath()
	var resultStr = runCmd2(nginxBinPathStr, "-s", "stop")
	resultStr = runCmd2("rm", "-Rf", "/var/run/nginx.sock")
	return resultStr
}

func nginxConfigTestReturn() string {
	//runBashFile("/opt/nginx/scripts/nginx-configtest.sh")
	//runSystemD("restart", "openresty.service")
	var nginxBinPathStr = nginxBinaryPath()
	var resultStr = runCmdStdOut(nginxBinPathStr, "-t", "", "", "")
	return resultStr
}

func nginxInstall() string {
	// Create a JSON file of what we installed, date and timestamp, type of install, etc

	var targetPlatformStr = "docker"
	if targetPlatformStr == "docker" {
		//installDockerContainer()
	} else {
		nginxInstallNginx()

	}

	//targetPlatformStr options are docker | kubernetes | baremetal
	var nginxTypeStr = "openresty"
	//nginxTypeStr options are openresty | openresty-php | nginx | nginx-pkg-manager

	if nginxTypeStr == "openresty" {
		nginxInstallOpenResty()
	} else {
		nginxInstallNginx()

	}
	if !fileExists("/opt/nginx") {
		runCmd("mkdir", "-p", "/opt/nginx", "", "")
	}

	fmt.Println("Nginx Install using Golang CLI Module")

	return "Nginx Install using Golang CLI Module"
}

func nginxInstallOpenResty() {
	runBashFile("/opt/nginx/scripts/nginx-install-openresty.sh")
	fmt.Println("Hello OpenResty Install using Golang CLI Module compile from source")
}

func nginxInstallNginx() {
	fmt.Println("Hello Nginx Install using Golang CLI Module compile from source")
}

// func nginxInstallNginxPkgManager() {
// nginx-pkg-manager
// 	fmt.Println("Hello Nginx Install using Yum or Apt")
// }

// func isOSType() string {
// 	var osType = runtime.GOOS
// 	fmt.Println("Hello Nginx Install using Yum or Apt")
// 	return osType
// }

func nginxConfigTest() {
	//runBashFile("/opt/nginx/scripts/nginx-configtest.sh")
	//runSystemD("restart", "openresty.service")
	var nginxConfigTestStr = nginxConfigTestReturn()
	fmt.Println(nginxConfigTestStr)
}

func nginxRestartService() {
	runSystemD("restart", "openresty.service")
}

func nginxStartService() {
	var nginxBinPathStr = nginxBinaryPath()
	var resultStr = runCmd0(nginxBinPathStr)
	runSystemD("start", "openresty.service")
	fmt.Println(resultStr)
}

func nginxStartServiceBash() {
	var nginxBinPathStr = nginxBinaryPath()
	var resultStr = runCmd0(nginxBinPathStr)
	runBashFile("/opt/nginx/scripts/nginx-start.sh")
	fmt.Println(resultStr)
}

func nginxReloadService() string {
	var nginxBinPathStr = nginxBinaryPath()
	var resultStr = runCmd2("rm", "-Rf", "/var/run/nginx.sock")
	resultStr = runCmd2(nginxBinPathStr, "-s", "reload")
	return resultStr
}

func nginxReloadServiceBash() string {
	var nginxBinPathStr = nginxBinaryPath()
	var resultStr = runCmd0(nginxBinPathStr)
	runBashFile("/opt/nginx/scripts/nginx-reload.sh")
	fmt.Println(resultStr)
	return resultStr
}

func apiNginxStartService(w http.ResponseWriter, req *http.Request) {
	nginxStartService()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: nginx service started ok"}`))
}

func apiNginxStartServiceBash(w http.ResponseWriter, req *http.Request) {
	nginxStartServiceBash()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: bash nginx service started ok"}`))
}

func apiNginxStopService(w http.ResponseWriter, req *http.Request) {
	var nginxResponseStr = nginxStopService()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: nginx service stopped ok","response":"` + nginxResponseStr + `"}`))
}
func apiNginxStopServiceBash(w http.ResponseWriter, req *http.Request) {
	var nginxResponseStr = nginxStopServiceBash()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: bash nginx service stopped ok","response":"` + nginxResponseStr + `"}`))
}

func apiNginxReloadService(w http.ResponseWriter, req *http.Request) {
	nginxConfigTest()
	nginxReloadService()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: nginx service reloaded ok"}`))
}

func apiNginxReloadServiceBash(w http.ResponseWriter, req *http.Request) {
	nginxConfigTest()
	nginxReloadServiceBash()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: bash nginx service reloaded ok"}`))
}

func apiNginxRestartService(w http.ResponseWriter, req *http.Request) {
	nginxConfigTest() // nginx -t
	nginxRestartService()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: nginx service restarted ok"}`))
}
func apiNginxRestartServiceBash(w http.ResponseWriter, req *http.Request) {
	nginxConfigTest()
	nginxRestartServiceBash()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: bash nginx service restarted ok"}`))
}

func apiNginxInstallService(w http.ResponseWriter, req *http.Request) {
	var responseCodeStr = nginxInstall()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: nginx installed ok %s"` + responseCodeStr + `}`))
}

func apiNginxTestService(w http.ResponseWriter, req *http.Request) {
	nginxConfigTest()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: nginx config test ok"}`))
}

func nginxRestartServiceBash() {
	runBashFile("/opt/nginx/scripts/nginx-restart.sh")
}

// func varnishConfigDeployTenant() {
// 	runBashFile("/opt/varnish/scripts/varnish-deploy-tenant-config.sh")
// }

func varnishConfigTest() {
	runSystemD("restart", "varnish.service")
	//	runBashFile("/opt/varnish/scripts/varnish-configtest.sh")
}

func varnishResetPermissions() {
	//	runCmd("mkdir", "-p", "/var/run/varnish/", "", "")
	touchFilePath("/var/run/varnish/", "/var/run/varnish/varnish.sock")

}

func varnishRestartService() {
	varnishResetPermissions()
	runSystemD("restart", "varnish.service")
	varnishResetPermissions()
}

func varnishStartService() {
	varnishResetPermissions()
	runSystemD("start", "varnish.service")
	varnishResetPermissions()
}

func varnishStopService() {
	//	runBashFile("/opt/varnish/scripts/varnish-stop.sh")
	runSystemD("stop", "varnish.service")
}

func varnishLoadVCL(pFileNameStr string) {
	// runCmd(cmdStr, arg1Str, arg2Str, arg3Str, arg4Str) {

	if pFileNameStr == "root" {
		runCmd("/usr/local/bin/varnishadm", "vcl.load", "vcl-"+pFileNameStr, varnishConfDir+pFileNameStr+".vcl", "")
		runCmd("/usr/local/bin/varnishadm", "vcl.use", "vcl-"+pFileNameStr, "", "")

	} else if pFileNameStr == "vcl.list" {
		runCmd("/usr/local/bin/varnishadm", "vcl.list", "", "", "")

	} else {
		runCmd("/usr/local/bin/varnishadm", "vcl.load", "vcl-"+pFileNameStr, varnishConfDir+pFileNameStr+".vcl", "")
		runCmd("/usr/local/bin/varnishadm", "vcl.label", "label-"+pFileNameStr, "vcl-"+pFileNameStr, "")
	}
}

func varnishReloadVCLFiles() {

	varnishRestartService()

	writeContentToFile("#This is a default VCL\n\nvcl 4.1;\nbackend default {\n.host = \"0:0\";\n}\n", varnishConfDir+"default.vcl")
	varnishLoadVCL("default") //required to get vcl initialised without too much of work

	writeContentToFile("#This is a edgeone VCL\n\nvcl 4.1;\nbackend default {\n.host = \"0:0\";\n}\n", varnishConfDir+"edgeone.vcl")
	varnishLoadVCL("edgeone")

	var rootVCLFileTxt = ""
	rootVCLFileTxt = rootVCLFileTxt + "vcl 4.1;\n"
	rootVCLFileTxt = rootVCLFileTxt + "backend default {\n.host = \"0:0\";\n}\n"

	rootVCLFileTxt = rootVCLFileTxt + "sub vcl_recv {\n"
	rootVCLFileTxt = rootVCLFileTxt + "if (req.http.host == \"DiyCDN.cloud\")\n{\nreturn (vcl(label-edgeone));\n}\n"
	items, _ := ioutil.ReadDir(varnishConfDir)

	for _, item := range items {
		if item.IsDir() {
			// fmt.Println("DIRNAME: ")
			// subitems, _ := ioutil.ReadDir(item.Name())
			// for _, subitem := range subitems {
			// 	if !subitem.IsDir() {
			// 		// handle file there
			// 		fmt.Println(item.Name() + "/" + subitem.Name())
			// 	}
			// }
		} else {
			// handle file there
			var fileNameStr = item.Name()
			var fileExtStr = path.Ext(fileNameStr)
			var fileNameWithoutExtStr = fileNameWithoutExtTrimSuffix(fileNameStr)
			if fileExtStr == ".vcl" {
				if fileNameStr == "root.vcl" { //loaded later on manually
				} else {
					if fileNameWithoutExtStr == "root" { //loaded later on manually
					} else {

						// vcl file into varnish memory and then add ref of it into root file
						varnishLoadVCL(fileNameWithoutExtStr)

						fileContentStr = readContentFromFile(varnishConfDir + fileNameWithoutExtStr + ".host")

						if fileContentStr == "" {
							fmt.Println("Host name is not provided so just build one so varnish does not crash")
							fileContentStr = fileNameWithoutExtStr + ".DiyCDN.cloud"
						} else {

							var hostsArray = strings.Split(fileContentStr, "\n")
							if len(hostsArray) == 0 {
								fmt.Println("VCLFileName vcl: " + fileNameWithoutExtStr + ", extension: " + fileExtStr)
								rootVCLFileTxt = rootVCLFileTxt + "else if (req.http.host == \"" + fileContentStr + "\")\n{\nreturn (vcl(label-" + fileNameWithoutExtStr + "));\n}\n"

							} else {
								//fmt.Println("\n---------------Example 2--------------------\n")
								for i := 0; i < len(hostsArray); i++ {
									//fmt.Println(hostsArray[i])
									fmt.Println("VCLFileName vcl: " + fileNameWithoutExtStr + ", extension: " + fileExtStr)
									rootVCLFileTxt = rootVCLFileTxt + "else if (req.http.host == \"" + hostsArray[i] + "\")\n{\nreturn (vcl(label-" + fileNameWithoutExtStr + "));\n}\n"

								}
							}
						}

					}
				}
			} else {
				fmt.Println("VCLFileName not vcl: " + fileNameWithoutExtStr + ", extension: " + fileExtStr)

			}
		}
	}

	rootVCLFileTxt = rootVCLFileTxt + "else {\nreturn (synth(404));\n}\n}\n"

	writeContentToFile(rootVCLFileTxt, varnishConfDir+"root.vcl")
	//create minimal default vcl to facilitate the root file generation
	varnishLoadVCL("root") //required to get vcl load all the tenants into the varnish
	varnishLoadVCL("vcl.list")

}

func apiVarnishStartService(w http.ResponseWriter, req *http.Request) {
	varnishStartService()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: varnish service started ok"}`))
}

func apiVarnishStopService(w http.ResponseWriter, req *http.Request) {
	varnishStopService()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: varnish service stopped ok"}`))
}

func apiVarnishRestartService(w http.ResponseWriter, req *http.Request) {
	varnishConfigTest()
	varnishRestartService()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: varnish service restarted ok"}`))
}

func apiVarnishTestConfig(w http.ResponseWriter, req *http.Request) {
	varnishConfigTest()
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"The OPS API: varnish config test ok"}`))
}

func homePage(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message":"Welcome to the OPSAPI Server - https://opsapi.org"}`))
}

//echo "# this is test nginx config file" >> test.conf

//curl -i -X POST -H "Token: $JWT_TOKEN" -H "Content-Type: multipart/form-data" -F "myFile=@test.conf" -F "rename=test.conf" -F "svc=nginx" http://$TARGET:3333/upload
//clear; curl -i -X POST -H "Token: $JWT_TOKEN" -H "Content-Type: multipart/form-data" -F "myFile=@/etc/nginx/sites-available/crm_workstation.conf" -F "rename=crm_workstation.conf" -F "svc=nginx" http://$TARGET:3333/upload
//curl -H "Token: $JWT_TOKEN" http://$TARGET:3333/nginx_restart
var NginxConfigFilesList []NginxConfigFile

type NginxConfigFile struct {
	Name    string `json:"name"`
	ModTime string `json:"modtime"`
	Path    string `json:"path"`
	Desc    string `json:"desc"`
	Mode    string `json:"mode"`
	Config  string `json:"content"`
}

func apiNginxListConfigFiles() {
	NginxConfigFilesList = []NginxConfigFile{}

	err := filepath.Walk(nginxConfDir,
		func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			//fmt.Println(path, info.Name(), info.Size())
			if filepath.Ext(nginxConfDir+info.Name()) == ".conf" {
				//fmt.Println("We can process this file as it is Conf")
				var filePath = nginxConfDir + info.Name()
				var fileModTime = info.ModTime()
				var fileModeStr = info.Mode().String()
				fileContentStr = readContentFromFile(filePath)
				sEnc := b64.StdEncoding.EncodeToString([]byte(fileContentStr))

				NginxConfigFilesList = append(NginxConfigFilesList,
					NginxConfigFile{Name: info.Name(), Path: filePath, ModTime: fileModTime.String(), Desc: "fileSize of file ", Mode: fileModeStr, Config: sEnc})
			}
			return nil
		})
	if err != nil {
		log.Println(err)
	}
}

func apiNginxListJSONFiles() {
	NginxConfigFilesList = []NginxConfigFile{}

	err := filepath.Walk(nginxConfDir,
		func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			fmt.Println(path, info.Name(), info.Size())
			if filepath.Ext(nginxConfDir+info.Name()) == ".json" {
				NginxConfigFilesList = append(NginxConfigFilesList, NginxConfigFile{Name: info.Name()})
				//fmt.Println("We can process this file as it is JSON")
			}
			return nil
		})
	if err != nil {
		log.Println(err)
	}
}

func apiUploadFile(w http.ResponseWriter, r *http.Request) {
	fmt.Println("File Upload Hit")
	//handle type of config file received nginx | varnish | or service manager call nginx_start, nginx_restart, nginx_config_test, varnish_start etc
	// Parse our multipart form, 10 << 20 specifies a maximum
	// upload of 10 MB files.
	r.ParseMultipartForm(10 << 20)
	// FormFile returns the first file for the given key `myFile`
	// it also returns the FileHeader so we can get the Filename,
	// the Header and the size of the file
	file, handler, err := r.FormFile("myFile")

	if err != nil {
		fmt.Println("Error Retrieving the File")
		fmt.Println(err)
		return
	}
	defer file.Close()
	fmt.Printf("Uploaded File: %+v\n", handler.Filename)
	fmt.Printf("File Size: %+v\n", handler.Size)
	fmt.Printf("MIME Header: %+v\n", handler.Header)

	var svcUploadType = r.FormValue("svc")
	var fileNameStr = r.FormValue("rename")
	var hostNameStr = r.FormValue("host")
	var fileNameWithoutExtStr = fileNameWithoutExtTrimSuffix(fileNameStr)
	if hostNameStr == "" {
		fmt.Println("Host name is not provided so build one")
		hostNameStr = fileNameWithoutExtStr + ".DiyCDN.cloud"
	}

	// Create a temporary file within our upload_files directory that follows
	// a particular naming pattern
	if err := ensureDir("upload_files"); err != nil {
		fmt.Println("Directory creation failed with error: " + err.Error())
		os.Exit(1)
	}

	if svcUploadType == "content_tar" {

		tempFile, err := ioutil.TempFile("upload_files", "upload-*.tar.gz")
		//tempDir, err := ioutil.TempDir("upload_files", "")
		if err != nil {
			fmt.Println(err)
		}
		defer tempFile.Close()

		// read all of the contents of our uploaded file into a
		// byte array
		fileBytes, err := ioutil.ReadAll(file)
		if err != nil {
			fmt.Println(err)
		}
		// write this byte array to our temporary file
		tempFile.Write(fileBytes)
		// return that we have successfully uploaded our file!
		fmt.Fprintf(w, "Successfully Uploaded File to dir: \n")
		//get path of the temp file
		//path, err := os.Getwd()
		if err != nil {
			log.Println(err)
		}

		if err := os.Chmod(tempFile.Name(), 0755); err != nil {
			log.Fatal(err)
		}

		untarFile(tempFile.Name(), "/var/www/nginx/", fileNameStr)
		//fmt.Println("command:", "tar -xvzf "++" -C /tmp/finaldest")
		//cmd := exec.Command("tar -xvzf " + path + "/" + tempFile.Name() + " -C /tmp/finaldest")
		//cmd := exec.Command("/usr/bin/tar -xvzf " + tempFile.Name() + " -C /tmp/finaldest")
		//opt/nginx/conf/nginx-tenants.d/
		// cmd.Stderr = os.Stderr
		// cmd.Stdin = os.Stdin

		// out, err := cmd.Output()
		// if err != nil {
		// 	fmt.Println("Err", err)
		// } else {
		// 	fmt.Println("OUT:", string(out))
		// }

	} else {

		// Create a temporary file within our upload_files directory that follows
		// a particular naming pattern
		tempFile, err := ioutil.TempFile("upload_files", "upload-*.txt")
		//tempDir, err := ioutil.TempDir("upload_files", "")
		if err != nil {
			fmt.Println(err)
		}
		defer tempFile.Close()

		// read all of the contents of our uploaded file into a
		// byte array
		fileBytes, err := ioutil.ReadAll(file)
		if err != nil {
			fmt.Println(err)
		}
		// write this byte array to our temporary file
		tempFile.Write(fileBytes)
		// return that we have successfully uploaded our file!
		fmt.Fprintf(w, "Successfully Uploaded File to dir: \n")
		//get path of the temp file

		if svcUploadType == "nginx" {
			fmt.Println("svc:", svcUploadType)
			fmt.Println("rename:", fileNameStr)
			fmt.Println("nginx , file path:", tempFile.Name())
			var err = os.MkdirAll(nginxConfDir, os.FileMode(0755)) // or use 0755 if you prefer

			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}

			if fileNameStr == "" {
				now := time.Now()      // current local time
				nsec := now.UnixNano() // number of nanoseconds since January 1, 1970 UTC
				fileNameStr = string(nsec) + ".conf"
			}

			os.Rename(tempFile.Name(), nginxConfDir+fileNameStr) ///opt/nginx/conf/nginx-tenants.d/

		} else if svcUploadType == "redis" {
			fmt.Println("svc:", svcUploadType)
			fmt.Println("rename:", fileNameStr)
			fmt.Println("redis , file path:", tempFile.Name())
			var err = os.MkdirAll(redisConfDir, os.FileMode(0755)) // or use 0755 if you prefer

			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}

			if fileNameStr == "" {
				now := time.Now()      // current local time
				nsec := now.UnixNano() // number of nanoseconds since January 1, 1970 UTC
				fileNameStr = string(nsec) + ".json"
			}

			apiRedisSetDefaults()
			os.Rename(tempFile.Name(), redisConfDir+fileNameStr) ///opt/redis/conf/redis-tenants.d/

			//
			apiRedisSetKey(hostNameStr+":host", redisConfDir+fileNameStr, fileNameStr)

		} else if svcUploadType == "yaml" {
			fmt.Println("svc:", svcUploadType)
			fmt.Println("rename:", fileNameStr)
			fmt.Println("yaml , file path:", tempFile.Name())
			var err = os.MkdirAll(redisConfDir, os.FileMode(0755)) // or use 0755 if you prefer

			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}

			if fileNameStr == "" {
				now := time.Now()      // current local time
				nsec := now.UnixNano() // number of nanoseconds since January 1, 1970 UTC
				fileNameStr = string(nsec) + ".yaml"
			}

			apiRedisSetDefaults()
			os.Rename(tempFile.Name(), kubeConfDir+fileNameStr) ///opt/redis/conf/redis-tenants.d/

			//applyKubeConf("test-cluster-a-prod", kubeConfDir+fileNameStr)

		} else if svcUploadType == "varnish" {

			fmt.Println("svc:", svcUploadType)
			fmt.Println("rename:", fileNameStr)
			if fileNameStr == "root" || fileNameStr == "default" {
				fmt.Println("The root and default are reserved names for vcl file names by the this system")
				os.Exit(1)
			}

			fmt.Println("varnish , file path:", tempFile.Name())
			var err = os.MkdirAll(varnishConfDir, os.FileMode(0755)) // or use 0755 if you prefer

			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}
			if fileNameStr == "" {
				now := time.Now()      // current local time
				nsec := now.UnixNano() // number of nanoseconds since January 1, 1970 UTC
				fileNameStr = string(nsec) + ".vcl"
			}

			os.Rename(tempFile.Name(), varnishConfDir+fileNameStr)

			if err := os.Chmod(varnishConfDir+fileNameStr, 0777); err != nil {
				log.Fatal(err)
			}
			//create host starts
			//create host file tied to this vcl

			writeContentToFile(hostNameStr, "/tmp/"+fileNameWithoutExtStr+".host")
			os.Rename("/tmp/"+fileNameWithoutExtStr+".host", varnishConfDir+fileNameWithoutExtStr+".host")

			if err := os.Chmod(varnishConfDir+fileNameWithoutExtStr+".host", 0777); err != nil {
				log.Fatal(err)
			}

			//create host ends
			varnishReloadVCLFiles()

		}
	}

}

func apiRedisSetDefaults() {
	touchPath(redisConfDir)
}

func apiVarnishPing(w http.ResponseWriter, req *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")

	var nginxConfigTestStr = "apiVarnishPing"

	fmt.Println("varnish config test :", nginxConfigTestStr)
	w.Write([]byte("varnish config test: " + nginxConfigTestStr))
}

func apiNginxPing(w http.ResponseWriter, req *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")

	var nginxConfigTestStr = "apiNginxPing"

	fmt.Println("nginx config test :", nginxConfigTestStr)
	w.Write([]byte("nginx config test: " + nginxConfigTestStr))
}

func apiRedisPing(w http.ResponseWriter, req *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")

	if redisHostStr == "" {
		redisHostStr = "localhost:6379"
	}
	// Read the contents of the file into a byte slice
	data, err := ioutil.ReadFile("/opt/opsapi_settings.json")
	if err != nil {
		fmt.Println("error:", err)
		return
	}

	// Unmarshal the JSON data into the struct
	var p RedisConf
	err = json.Unmarshal(data, &p)
	if err != nil {
		fmt.Println("error:", err)
		return
	}
	// // Access the values in the struct
	// fmt.Println("RedisHost:", p.RedisHost)
	// fmt.Println("RedisPort:", p.RedisPort)

	if p.RedisHost != "" {
		redisHostStr = p.RedisHost
	} else {
		redisPortStr = "127.0.0.1"
	}
	if p.RedisPort != "" {
		redisPortStr = p.RedisPort
	} else {
		redisPortStr = "6379"
	}

	redisHostStr = redisHostStr + ":" + redisPortStr

	if redisHostStr == "" {
		redisHostStr = ":6379"
	}
	fmt.Println("Redis host:", redisHostStr)

	client := redis.NewClient(&redis.Options{
		Addr:     redisHostStr,
		Password: "",
		DB:       0,
	})

	pong, err := client.Ping().Result()
	fmt.Println(pong, err)
	if err != nil {
		fmt.Println(err)
		//os.Exit(1)
		w.Write([]byte(redisHostStr + " is not reachable"))
	} else {
		w.Write([]byte(redisHostStr + " is reachable"))
	}
}

func tenant_create(w http.ResponseWriter, req *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	fmt.Println("Tenant API create new tenant deployment")
	w.Write([]byte(`{"message":"deployed ok"}`))
}

func apiRedisSetKey(pKeyNameStr string, pFilePathStr string, pFileNameStr string) {
	//	fmt.Println("key name:", pKeyNameStr)
	fileContentStr = readContentFromFile(redisConfDir + pFileNameStr)

	fmt.Println("Go Redis Tutorial")

	client := redis.NewClient(&redis.Options{
		Addr:     redisHostStr,
		Password: "",
		DB:       0,
	})

	var err = client.Set(pKeyNameStr, fileContentStr, 0).Err()
	// if there has been an error setting the value
	// handle the error
	if err != nil {
		fmt.Println(err)
	}

	//fmt.Println("fileContent: ", fileContentStr)
	//err = client.Set("name", "Elliot", 0).Err()

	//runCmd("/usr/local/bin/redis-cli -h workstation-redis-cluster-001.xg2iur.0001.euw2.cache.amazonaws.com set "+pKeyNameStr+" \""+fileContentStr+"\"", "", "", "", "")
	//runCmd("/usr/local/bin/redis-cli", "-h", "workstation-redis-cluster-001.xg2iur.0001.euw2.cache.amazonaws.com", "set "+pKeyNameStr+" \""+fileContentStr+"\"", "")
}

func apiTestMethod(w http.ResponseWriter, req *http.Request) {
	apiRedisSetKey("my.workstation.co.uk:host", "{\"proxy_pass\": \"34.240.98.233:3016\"}", "")
}

func headers(w http.ResponseWriter, req *http.Request) {
	for name, headers := range req.Header {
		for _, h := range headers {
			fmt.Fprintf(w, "%v: %v\n", name, h)
		}
	}
}

//export JWT_TOKEN=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzb21lIjoicGF5bG9hZCJ9.sNiY46w09fE1UD2GbzE3w6QDfbvdmBtbWEWMOhMw5i
//export TARGET=localhost
//curl -H "Content-Type: application/json" -H "Token: $JWT_TOKEN" http://$TARGET:8888/__api/system/nginx/service_control/nginx_config_deploy
// http://localhost:3333/nginx_restart

func local_Test() {
	varnishReloadVCLFiles()
}

func generateCerts() {
	// generate a self-signed certificate
	//cert, _ := tls.LoadX509KeyPair("localhost.crt", "localhost.key")
}

func Run(addr string, sslAddr string, ssl map[string]string) chan error {

	errs := make(chan error)

	// Starting HTTP server
	go func() {
		log.Printf("Staring HTTP service on %s ...", addr)

		if err := http.ListenAndServe(addr, nil); err != nil {
			errs <- err
		}

	}()

	// Starting HTTPS server
	go func() {
		log.Printf("Staring HTTPS service on %s ...", sslAddr)
		if err := http.ListenAndServeTLS(sslAddr, ssl["cert"], ssl["key"], nil); err != nil {
			errs <- err
		}
	}()

	return errs
}

func main() {

	generateCerts()

	//http.Handle("/", isAuthorized(homePage))
	http.Handle("/", http.FileServer(http.Dir("./static")))
	// kubernetes api
	http.Handle("/tenant_create", isAuthorized(tenant_create))
	http.Handle("/tenant_update", isAuthorized(homePage))
	http.Handle("/tenant_delete", isAuthorized(homePage))

	http.Handle("/varnish_start", isAuthorized(apiVarnishStartService))
	http.Handle("/varnish_stop", isAuthorized(apiVarnishStopService))
	http.Handle("/varnish_restart", isAuthorized(apiVarnishRestartService))
	http.Handle("/varnish_config_test", isAuthorized(apiVarnishTestConfig))
	//	http.Handle("/varnish_config_deploy", isAuthorized(apiDeployVarnishConfig))

	http.Handle("/nginx_config_json_files", isAuthorized(apiNginxConfigJSONList))
	http.Handle("/nginx_config_files", isAuthorized(apiNginxConfigList))
	http.HandleFunc("/nginx_start", apiNginxStartService)
	http.HandleFunc("/nginx_start_bash", apiNginxStartServiceBash)
	http.HandleFunc("/nginx_stop", apiNginxStopService)
	http.HandleFunc("/nginx_stop_bash", apiNginxStopServiceBash)
	http.HandleFunc("/nginx_reload", apiNginxReloadService)
	http.HandleFunc("/nginx_reload_bash", apiNginxReloadServiceBash)
	http.HandleFunc("/nginx_restart", apiNginxRestartService)
	http.HandleFunc("/nginx_restart_bash", apiNginxRestartServiceBash)
	http.HandleFunc("/nginx_bin_path", apiNginxBinaryPath)
	http.HandleFunc("/nginx_config_test", apiNginxTestService)
	//	http.Handle("/nginx_config_deploy", isAuthorized(apiDeployNginxConfig))
	http.HandleFunc("/nginx_install", apiNginxInstallService)

	http.Handle("/tenant_create_instance", isAuthorized(apiTenantCreateInstance))
	http.Handle("/upload", isAuthorized(apiUploadFile))
	http.Handle("/headers", isAuthorized(headers))
	http.Handle("/__ls", isAuthorized(lsDirPath))
	http.Handle("/__test_method", isAuthorized(apiTestMethod))
	// http.Handle("/nginx_healthcheck", isAuthorized(apiNginxhealthCheck))

	http.Handle("/nginx_ping", isAuthorized(apiNginxPing))
	http.Handle("/varnish_ping", isAuthorized(apiVarnishPing))

	http.Handle("/redis_ping", isAuthorized(apiRedisPing))
	http.Handle("/redis_set_key", isAuthorized(apiRedisPing))

	errs := Run(":3333", ":10443", map[string]string{
		"cert": "localhost.crt",
		"key":  "localhost.key",
	})

	// This will run forever until channel receives error
	select {
	case err := <-errs:
		log.Printf("Error starting server (error: %s)", err)
	}

}
