# All-in-One CLI Dev Container

이 프로젝트는 Docker를 사용하여 Java, Node.js, 각종 빌드 도구 및 버전 관리 시스템이 포함된 일관되고 격리된 **CLI (Command Line Interface) 중심의 개발 환경**을 구축하는 것을 목표로 합니다.

모든 관리는 프로젝트 루트의 `dev.sh` 헬퍼 스크립트를 통해 이루어지며, 호스트 PC에는 **Docker**만 설치되어 있으면 됩니다.

---

## 📋 주요 설치 항목

### 언어 및 런타임
- **Java**:
  - **버전 관리**: `SDKMAN!`을 통해 관리됩니다.
  - **설치**: `.env` 파일 설정에 따라 Java 17 (기본), 8, 11, 21을 선택적으로 설치할 수 있습니다.
- **Node.js**:
  - **버전 관리**: `nvm` (Node Version Manager)을 통해 관리됩니다.
  - **설치**: `.env` 파일 설정에 따라 최신 LTS (Long Term Support) 버전을 설치할 수 있습니다.

### 빌드 도구
- Gradle
- Maven

### 버전 관리 시스템 (VCS)
- Git
- Subversion (svn)

### 터미널 환경
- **기본 셸**: Zsh
- **셸 프레임워크**: Oh My Zsh
- **편의 유틸리티**: `htop`, `jq`, `tree`, `tmux`, `ncdu` (선택적 설치)

---

## 🚀 사용 방법

### 1. 사전 준비
- **Docker Desktop**: [공식 사이트](https://www.docker.com/products/docker-desktop/)에서 OS에 맞게 설치하고 실행합니다.

### 2. 기능 선택
컨테이너를 빌드하기 전, 프로젝트 최상위 폴더의 `.env` 파일을 열어 필요한 기능만 선택하여 설치할 수 있습니다. `true` 또는 `false` 값을 수정하여 설치 여부를 제어합니다.

**`.env` 파일 설정:**
```
# "true" 또는 "false"로 설치할 기능을 선택합니다.
INSTALL_NODE="true"
INSTALL_EXTRA_JDKS="true"
INSTALL_CONVENIENCE_TOOLS="true"
INSTALL_ZSH_PLUGINS="true"
```

### 3. 컨테이너 빌드 및 실행
`.env` 파일 수정 후, 터미널에서 **프로젝트 최상위 폴더 (`dev_container`)**로 이동하여 아래 명령어들을 순서대로 실행합니다.

**1) 스크립트 실행 권한 부여 (최초 1회만):**
```bash
chmod +x dev.sh
```

**2) 컨테이너 빌드 및 시작:**
```bash
./dev.sh up
```
*최초 실행 시, 필요한 모든 도구를 다운로드하고 설치하므로 몇 분 정도 소요될 수 있습니다. `up` 명령어는 이 모든 과정이 완료될 때까지 종료되지 않습니다.*
*두 번째 실행부터는 이미 설정이 완료되었으므로 컨테이너가 즉시 시작됩니다.*

### 4. 컨테이너 셸 접속
순수 CLI 환경을 사용하려면, `up` 명령이 완료된 후 아래 명령어로 컨테이너 내부의 Zsh 셸에 접속하여 개발을 시작할 수 있습니다.
```bash
./dev.sh shell
```

---

## 💻 호스트 IDE와 연동하기 (원격 개발)

이 CLI 컨테이너는 호스트 PC에 설치된 IntelliJ IDEA나 VS Code와 같은 IDE의 강력한 백엔드 역할을 할 수 있습니다. 이 방식을 사용하면, 호스트에서는 부드러운 네이티브 UI를 사용하면서, 실제 코드 분석, 빌드, 실행은 컨테이너의 격리된 환경에서 이루어집니다.

### IntelliJ IDEA
1.  **사전 준비**: 호스트 PC(Mac, Windows 등)에 **IntelliJ IDEA** (Ultimate 또는 Community)를 설치합니다.
2.  **Remote Development 시작**:
    *   IntelliJ IDEA를 실행합니다.
    *   IntelliJ 상단 메뉴에서 **`File` > `Remote Development`**를 클릭합니다. (IntelliJ 시작 화면에서도 'Remote Development' 기능을 찾을 수 있습니다.)
3.  **Dev Container 선택**: `Remote Development` 섹션 아래의 **Dev Containers** 탭을 클릭합니다.
4.  **연결**:
    *   **실행 중인 컨테이너에 연결**: 목록에서 현재 실행 중인 `devcontainer-devcontainer-1` (또는 `All-in-One CLI Dev Container`)를 찾아 클릭합니다.
    *   **프로젝트 폴더에서 직접 연결**: "New Connection" 또는 "Add Dev Container Path"를 눌러 이 프로젝트 폴더(`dev_container`)를 직접 선택할 수도 있습니다.
5.  **백엔드 설치 및 클라이언트 실행**: 연결을 시작하면 Gateway가 컨테이너에 접속하여 원격 개발에 필요한 구성 요소를 자동으로 설치하거나 확인한 후, 호스트 PC에 원격 연결용 IntelliJ 클라이언트를 실행합니다.

### Visual Studio Code
1.  **사전 준비**: 호스트 PC에 **Visual Studio Code**와 Microsoft의 **"Dev Containers"** 확장 프로그램을 설치합니다.
2.  **연결**:
    *   VS Code에서 이 프로젝트 폴더(`dev_container`)를 엽니다.
    *   VS Code가 `.devcontainer` 폴더를 자동으로 감지하고, 창 우측 하단에 **"Reopen in Container"** 알림을 표시합니다.
    *   이 알림 버튼을 클릭하면, VS Code가 자동으로 컨테이너를 시작하고 원격으로 연결하여 창을 다시 엽니다.

---

## 🛠️ 주요 명령어 (`dev.sh`)

모든 관리는 프로젝트 루트의 `dev.sh` 스크립트를 통해 이루어집니다.

| 명령어 (Command) | 설명 (Description) |
| :--------------- | :----------------------------------------------------------- |
| `up`             | 컨테이너를 빌드하고, 필요 시 최초 설정을 실행합니다.         |
| `down`           | 컨테이너를 중지하고 제거합니다. (데이터는 보존됨)            |
| `down-v`         | **[주의]** 컨테이너와 모든 볼륨(도구 설정 데이터)을 함께 제거합니다. (완전 초기화) |
| `shell`          | 컨테이너 내부의 대화형 zsh 셸을 엽니다.                    |
| `backup`         | 모든 도구 설정 데이터를 `./backups` 폴더에 압축하여 저장합니다. |
| `restore <file>` | 지정된 백업 파일로부터 모든 설정을 복원합니다.             |
| `logs`           | 컨테이너의 로그를 실시간으로 확인합니다.                   |

---

## 💡 컨테이너 내부 명령어 가이드

컨테이너 터미널 내에서(`dev.sh shell` 또는 IDE 원격 터미널로 접속) 아래 별칭(Alias)들을 사용하여 개발 환경을 편리하게 제어할 수 있습니다.

### 주요 별칭 (Aliases)

| 별칭 (Alias) | 설명 (Description)                               |
| :----------- | :----------------------------------------------- |
| `lij`        | 설치된 Java 버전 목록 보기                       |
| `sdj <ver>`  | 기본 Java 버전 설정 (영구)                       |
| `lnv`        | 설치된 Node.js 버전 목록 보기                    |
| `sdn <ver>`  | 기본 Node.js 버전 설정 (영구)                    |
| `sp <url>`   | `/workspace`에서 Git 프로젝트 클론 시작          |
| `ll`         | `ls -alF` (자세히 보기)                          |
| `..`         | `cd ..` (상위 폴더로 이동)                        |
| `update`     | `sudo apt-get update && sudo apt-get upgrade -y` (시스템 패키지 업데이트) |

---

## 💾 데이터 영속성 및 백업

### 1. 소스 코드: 바인드 마운트 (Bind Mount)
소스 코드는 컨테이너 외부의 호스트 PC에 직접 저장됩니다. `docker-compose.yml`의 `../:/workspace:cached` 설정은 이 프로젝트 폴더의 부모 폴더 전체를 컨테이너의 `/workspace`와 동기화합니다. 따라서 컨테이너에서 작업한 코드는 호스트에 그대로 남게 됩니다.

### 2. 도구 설정: 네임드 볼륨 (Named Volumes)
`SDKMAN`으로 설치한 Java, `nvm`으로 설치한 Node.js, 터미널 명령어 기록 등은 Docker가 관리하는 **네임드 볼륨**에 저장되어 컨테이너를 삭제해도 보존됩니다.

#### 네임드 볼륨 목록
| 볼륨 이름 (Volume Name) | 저장되는 데이터                                       |
| :---------------------- | :---------------------------------------------------- |
| `sdkman-data`           | `SDKMAN`으로 설치된 Java, Gradle 등 SDK 파일      |
| `nvm-data`              | `nvm`으로 설치된 Node.js 버전 파일                  |
| `zsh-history`           | Zsh 터미널에서 사용한 명령어 기록 (`history` 파일)    |

### 3. 설정 백업 및 복원 (`dev.sh` 사용)
`dev.sh`의 `backup` 및 `restore` 명령어를 사용하여 모든 도구 설정(네임드 볼륨)을 쉽게 백업하고 다른 PC에서 복원할 수 있습니다.

- **백업 생성:**
  ```bash
  ./dev.sh backup
  ```
  - `./backups` 폴더 안에 `dev_container_backup_YYYYMMDD_HHMMSS.tar.gz` 형식의 압축 파일이 저장됩니다.

- **백업으로부터 복원:**
  ```bash
  # 예시
  ./dev.sh restore ./backups/dev_container_backup_20251127_170000.tar.gz
  ```
  - **주의**: 복원 전에는 컨테이너가 중지된 상태여야 합니다. (`./dev.sh down`)
