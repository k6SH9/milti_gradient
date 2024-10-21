#!/bin/bash

# Приветствие и ASCII-арт
echo "
███████╗██████╗ ███████╗███╗   ███╗
██╔════╝██╔══██╗██╔════╝████╗ ████║
█████╗  ██████╔╝█████╗  ██╔████╔██║
██╔══╝  ██╔══██╗██╔══╝  ██║╚██╔╝██║
███████╗██████╔╝███████╗██║ ╚═╝ ██║
╚══════╝╚═════╝ ╚══════╝╚═╝     ╚═╝

 ██████╗ ██████╗  █████╗ ██████╗ ██╗███████╗███╗   ██╗████████╗
██╔════╝ ██╔══██╗██╔══██╗██╔══██╗██║██╔════╝████╗  ██║╚══██╔══╝
██║  ███╗██████╔╝███████║██║  ██║██║█████╗  ██╔██╗ ██║   ██║
██║   ██║██╔══██╗██╔══██║██║  ██║██║██╔══╝  ██║╚██╗██║   ██║
╚██████╔╝██║  ██║██║  ██║██████╔╝██║███████╗██║ ╚████║   ██║
 ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝
"
echo "by k6sh9 & Ebynbi yzlov"

# Функция для парсинга файла proxys.txt
parse_proxies() {
    mapfile -t PROXIES < proxys.txt
}

# Функция для обновления main.go и Dockerfile
update_files() {
    proxy="${PROXIES[$(($1 % ${#PROXIES[@]}))]}"
    proxy_ip=$(echo "$proxy" | cut -d':' -f1)
    proxy_port=$(echo "$proxy" | cut -d':' -f2)
    proxy_login=$(echo "$proxy" | cut -d':' -f3)
    proxy_password=$(echo "$proxy" | cut -d':' -f4)

    # Заменяем email и password в main.go
    sed -i "s/\$email/$email/g" main.go
    sed -i "s/\$password/$password/g" main.go

    # Заменяем прокси-данные в main.go
    sed -i "s/\$proxyLOGIN/$proxy_login/g" main.go
    sed -i "s/\$proxyPASSWORD/$proxy_password/g" main.go

    # Заменяем прокси-данные в Dockerfile
    sed -i "s/\$proxyLOGIN/$proxy_login/g" Dockerfile
    sed -i "s/\$proxyPASSWORD/$proxy_password/g" Dockerfile
    sed -i "s/\$proxyIP/$proxy_ip/g" Dockerfile
    sed -i "s/\$proxyPORT/$proxy_port/g" Dockerfile
}

# Функция для запуска контейнеров
start_containers() {
    for ((i = 0; i < $1; i++)); do
        echo "Установка контейнера №" $i+1
        update_files $i $2 $3
        container_name="gradient-$((i+1))"
        docker build -t "$container_name" .
        docker run -d --name "$container_name" "$container_name"
        echo "Контейнер " $i+1 " установлен"
    done
}

# Функция для завершения контейнеров
stop_containers() {
    if [[ $1 -eq 0 ]]; then
        docker stop $(docker ps -q --filter "name=gradient-")
        docker rm $(docker ps -a -q --filter "name=gradient-")
    else
        docker stop "gradient-$1"
        docker rm "gradient-$1"
    fi
}

# Функция для перезапуска контейнеров
restart_containers() {
    containers=$(docker ps --filter "name=gradient-" --format "{{.Names}}")
    i=0
    for container in $containers; do
        docker stop "$container"
        update_files $i "email_placeholder" "password_placeholder"
        docker start "$container"
        ((i++))
    done
}

# Функция для вывода статистики контейнеров
container_stats() {
    docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
}

# Главное меню
while true; do
    echo "
Выберите действие:
1. Установить контейнеры
2. Переустановить контейнеры
3. Завершить контейнеры
4. Статистика запущенных контейнеров
5. Выход
"

    read -rp "Введите номер действия: " choice

    case $choice in
        1)
            read -rp "Сколько контейнеров запустить? " num_containers
            read -rp "Введите email: " email
            read -rp "Введите password: " password
            parse_proxies
            start_containers $num_containers
            ;;
        2)
            parse_proxies
            restart_containers
            ;;
        3)
            read -rp "Введите номер контейнера для завершения (или 0 для завершения всех): " container_number
            stop_containers $container_number
            ;;
        4)
            container_stats
            ;;
        5)
            echo "Выход..."
            exit 0
            ;;
        *)
            echo "Неверный выбор, попробуйте снова."
            ;;
    esac
done