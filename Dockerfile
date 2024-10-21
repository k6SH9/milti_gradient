FROM golang:1.23.0

RUN apt-get update && apt-get install -y \
    xvfb \
    x11-apps \
    imagemagick \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxi6 \
    libxtst6 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxrandr2 \
    libgbm1 \
    libxss1 \
    libgconf-2-4 \
    libasound2 \
    wget \
    unzip \
    ca-certificates \
    gnupg \
    redsocks \
    iptables \
    xorg \
    libx11-dev \
    libxtst-dev \
    libpng-dev \
    libxinerama-dev \
    libxcursor-dev \
    libxrandr-dev \
    gnupg2

# Добавляем репозиторий Google Chrome и устанавливаем последнюю стабильную версию
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable

ENV DISPLAY=:99

WORKDIR /app

COPY go.mod go.sum main.go Gradient-Sentry-Node-Chrome.crx ./

COPY chromedriver_linux /usr/local/bin/chromedriver

RUN chmod +x /usr/local/bin/chromedriver

RUN go mod download

RUN go build -o myapp main.go

ENV http_proxy=http://$proxyLOGIN:$proxyPASSWORD@$proxyIP:$proxyPORT
ENV https_proxy=http://$proxyLOGIN:$proxyPASSWORD@$proxyIP:$proxyPORT

CMD ["sh", "-c", "Xvfb :99 -screen 0 1920x1080x24 & ./myapp"]
