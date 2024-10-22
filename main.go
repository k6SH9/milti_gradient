package main

import (
	"encoding/base64"
	"fmt"
	"github.com/go-vgo/robotgo"
	"log"
	"os"
	"os/exec"
	"time"

	"github.com/tebeka/selenium"
	"github.com/tebeka/selenium/chrome"
)

func main() {

	const (
		seleniumPort = 45747
	)

	opts := []selenium.ServiceOption{
		selenium.Output(nil),
	}
	service, err := selenium.NewChromeDriverService("/usr/local/bin/chromedriver", seleniumPort, opts...)
	fmt.Println("Запускаем хром драйвер")
	if err != nil {
		log.Fatalf("Ошибка при запуске Chromedriver: %v", err)
	}
	defer func(service *selenium.Service) {
		err := service.Stop()
		if err != nil {

		}
	}(service)

	extensionBytes, err := os.ReadFile("Gradient-Sentry-Node-Chrome.crx")
	fmt.Println("Устанавливаем расширение из base64")
	if err != nil {
		log.Fatalf("Не удалось прочитать файл расширения: %v", err)
	}
	encodedExtension := base64.StdEncoding.EncodeToString(extensionBytes)

	caps := selenium.Capabilities{
		"browserName": "chrome",
	}

	fmt.Println("Используем пакет chrome для установки опций")
	chromeCaps := chrome.Capabilities{
		Args: []string{
			"--no-sandbox",
			//"--disable-dev-shm-usage",
			//"--disable-gpu",
			"--window-size=1920,1080",
			"--start-maximized",
			"--disable-blink-features=AutomationControlled",
			"--disable-extensions-file-access-check",
		},
		Extensions: []string{encodedExtension},
	}
	caps.AddChrome(chromeCaps)

	fmt.Println("Создание нового сеанса WebDriver")
	wd, err := selenium.NewRemote(caps, fmt.Sprintf("http://localhost:%d/wd/hub", seleniumPort))
	if err != nil {
		log.Fatalf("Ошибка при создании нового сеанса WebDriver: %v", err)
	}
	defer func(wd selenium.WebDriver) {
		err := wd.Quit()
		if err != nil {

		}
	}(wd)

	fmt.Println("Удаление navigator.webdriver...")
	_, err = wd.ExecuteScript("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})", nil)
	if err != nil {
		panic(err)
	}

	time.Sleep(5 * time.Second)

	fmt.Println("Открываем страничку..")
	err = wd.Get("https://app.gradient.network/")
	if err != nil {
		log.Fatalf("Failed to load page: %v", err)
	}

	time.Sleep(5 * time.Second)

	robotgo.TypeStr("$proxyLOGIN")
	fmt.Println("Ввели логин...")
	err = robotgo.KeyTap("tab")
	if err != nil {
		return
	}
	robotgo.TypeStr("$proxyPASSWORD")
	fmt.Println("Ввели пароль...")
	err = robotgo.KeyTap("enter")
	if err != nil {
		return
	}

	fmt.Println("Ожидание полной загрузки страницы с помощью JavaScript...")

	err = wd.WaitWithTimeout(func(wd selenium.WebDriver) (bool, error) {
		state, err := wd.ExecuteScript("return document.readyState", nil)
		if err != nil {
			return false, err
		}
		return state == "complete", nil
	}, 10*time.Second)
	if err != nil {
		panic(err)
	}

	time.Sleep(30 * time.Second)

	fmt.Println("Страница загружена!")

	emailField, err := wd.FindElement(selenium.ByXPATH, "//input[@placeholder='Enter Email']")
	if err != nil {
		log.Fatalf("Failed to find email field: %v", err)
	}
	fmt.Println("Вводим эмейл")
	err = emailField.SendKeys("$email")
	if err != nil {
		log.Fatalf("Ошибка ввода емейла (возможно, плохие прокси): %v", err)
	}

	passwordField, err := wd.FindElement(selenium.ByXPATH, "//input[@placeholder='Enter Password']")
	if err != nil {
		log.Fatalf("Ошибка ввода пароля (возможно, плохие прокси): %v", err)
	}
	fmt.Println("Вводим пароль")
	err = passwordField.SendKeys("$password")
	if err != nil {
		log.Fatalf("Failed to enter password: %v", err)
	}

	time.Sleep(10 * time.Second)

	loginButton, err := wd.FindElement(selenium.ByXPATH, "//button[contains(text(), 'log in') or contains(text(), 'Log In')]")
	if err != nil {
		log.Fatalf("Не удалось найти кнопку 'log in': %v", err)
	}

	err = loginButton.Click()
	if err != nil {
		log.Fatalf("Не удалось нажать на кнопку 'log in': %v", err)
	}

	fmt.Println("Кнопка 'log in' нажата успешно.")

	time.Sleep(15 * time.Second)

	err = captureFullScreen("full_screenshot.png")
	if err != nil {
		log.Fatalf("Не удалось сделать полный скриншот: %v", err)
	}
	fmt.Println("Полный скриншот успешно сохранён как full_screenshot.png")

	time.Sleep(30 * time.Second)
	fmt.Println("Нода успешно запущена!")

	select {}
}

func captureFullScreen(filename string) error {
	cmd := exec.Command("import", "-display", os.Getenv("DISPLAY"), "-window", "root", filename)
	return cmd.Run()
}
