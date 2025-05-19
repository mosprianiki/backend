# zit

- [zit](#zit)
  - [Запуск проекта](#запуск-проекта)
  - [1. Клонировать проект](#1-клонировать-проект)
  - [Запуск в Docker](#запуск-в-docker)
    - [2. Установить Docker Desktop](#2-установить-docker-desktop)
    - [3. Создать .env](#3-создать-env)
    - [4. Запуск](#4-запуск)
  - [Запуск вне Docker](#запуск-вне-docker)
    - [2. Установить uv](#2-установить-uv)
    - [3. Установить зависимости](#3-установить-зависимости)
    - [4. Создать .env.dev](#4-создать-envdev)
    - [5. Запуск](#5-запуск)

## Запуск проекта

## 1. Клонировать проект

```bach
git clone 
```

## Запуск в Docker

### 2. Установить Docker Desktop

<https://www.docker.com/products/docker-desktop/>

### 3. Создать .env

```bash
cp .env.template .env
```

Заполните файл своими данными.

### 4. Запуск

```bash
docker compose up -d --build
```

## Запуск вне Docker

### 2. Установить uv

- Для Windows

  ```shell
  powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
  ```

- Для Linux и Mac OS

  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```

### 3. Установить зависимости

```bash
uv sync
```

### 4. Создать .env.dev

```bash
cp .env.template .env.dev
```

Заполните файл своими данными.

```bash
# Обязательно установить переменные окружения
BACKEND__DB__HOST=localhost
```

### 5. Запуск

- При неактивированном виртуальном окружении

  ```bash
  # dev
  uv run fastapi dev main.py

  # prod
  uv run fastapi run main.py
  ```

- При активированном виртуальном окружении

  ```bash
  # dev
  fastapi dev main.py

  # prod
  fastapi run main.py
  ```

DEV_ENV, PROD_ENV, SSH_KEY, SSH_HOST, SSH_USER, TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID
