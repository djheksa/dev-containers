# 개발 환경 커스터마이징 가이드 (Customization Guide)

이 문서는 `dev_container` 개발 환경에 새로운 소프트웨어를 추가하거나 설정을 변경하는 방법을 안내합니다.

## ⚙️ 핵심 파일의 역할

이해를 돕기 위해 각 파일의 핵심 역할을 다시 한번 정리합니다.

-   **`.env`**: 기능(Feature)을 켜고 끄는 '컨트롤 패널'입니다.
-   **`.devcontainer/Dockerfile`**: 컨테이너의 기반이 되는 운영체제, 시스템 라이브러리, 핵심 프로그램 등 **시스템 전역적**인 소프트웨어를 설치합니다.
-   **`.devcontainer/docker-compose.yml`**: `.env` 변수를 `Dockerfile`과 컨테이너에 전달하고, 볼륨 마운트, 사용자 설정 등 컨테이너의 **실행 방식**을 정의합니다.
-   **`.devcontainer/post-create-command.sh`**: 컨테이너가 생성된 후 `dev-user`를 위해 실행되는 스크립트입니다. **사용자별 설정**, `sdkman`/`nvm`을 통한 SDK 설치, `Oh My Zsh` 플러그인 설치 등을 담당합니다.
-   **`dev.sh`**: 복잡한 `docker compose` 명령어를 쉽게 사용할 수 있도록 만든 헬퍼 스크립트입니다.

---

## 📝 시나리오: 새로운 터미널 유틸리티 `neofetch` 추가하기

`neofetch`는 시스템 정보를 예쁘게 보여주는 터미널 도구입니다. 이 도구를 우리 개발 환경에 추가하는 과정을 통해 커스터마이징 방법을 익혀보겠습니다.

### 1단계: 소프트웨어 설치 (`Dockerfile` 수정)

`neofetch`는 시스템 전역적으로 설치되는 `apt` 패키지이므로, `Dockerfile`을 수정해야 합니다.

1.  `.devcontainer/Dockerfile` 파일을 엽니다.
2.  `편의 도구 조건부 설치` 섹션을 찾습니다.
3.  `apt-get install -y` 목록에 `neofetch`를 추가합니다.

**변경 전:**
```dockerfile
# 편의 도구 조건부 설치
RUN if [ "$INSTALL_CONVENIENCE_TOOLS" = "true" ]; then \
        echo "Installing convenience tools..." && \
        apt-get update && apt-get install -y \
        htop \
        jq \
        tree \
        tmux \
        ncdu; \
    fi
```

**변경 후:**
```dockerfile
# 편의 도구 조건부 설치
RUN if [ "$INSTALL_CONVENIENCE_TOOLS" = "true" ]; then \
        echo "Installing convenience tools..." && \
        apt-get update && apt-get install -y \
        htop \
        jq \
        tree \
        tmux \
        ncdu \
        neofetch; \
    fi
```

### 2단계 (선택 사항): Alias 추가 (`post-create-command.sh` 수정)

`neofetch` 명령어를 더 짧게 쓰고 싶다면, `post-create-command.sh` 스크립트에서 alias를 추가할 수 있습니다.

1.  `.devcontainer/post-create-command.sh` 파일을 엽니다.
2.  `# --- 사용자 지정 별칭 ---` 섹션을 찾습니다.
3.  원하는 alias를 추가합니다. (예: `alias nf='neofetch'`)

**변경 후:**
```bash
# --- 사용자 지정 별칭 ---
alias l='ls -CF'; alias la='ls -A'; # ... 기존 alias들
alias nf='neofetch'
```

### 3단계: 변경사항 적용 (컨테이너 재빌드)

`Dockerfile`이 수정되었으므로, 이미지를 다시 빌드해야 합니다. 프로젝트 최상위 폴더에서 `dev.sh`를 사용합니다.

```bash
./dev.sh up
```
이 명령어는 내부적으로 `--build` 옵션을 포함하여 `docker compose`를 실행하므로, `Dockerfile`의 변경사항을 감지하고 이미지를 새로 빌드합니다.

### 4단계: 확인

빌드가 완료된 후, 컨테이너에 접속하여 `neofetch` 또는 새로 추가한 alias `nf`를 실행해 봅니다.

```bash
./dev.sh shell
```
```bash
# 컨테이너 내부 터미널에서
neofetch
# 또는
nf
```
시스템 정보가 예쁘게 출력되면 성공적으로 추가된 것입니다.

---

## 💡 일반적인 수정 패턴 요약

-   **시스템 전체 도구/라이브러리 추가**: `Dockerfile`의 `apt-get` 부분을 수정합니다.
-   **Java/Node.js 버전 추가/변경**: `post-create-command.sh`의 `sdk install` 또는 `nvm install` 부분을 수정합니다.
-   **Alias 또는 터미널 설정 변경**: `post-create-command.sh`의 `.zshrc`를 설정하는 부분을 수정합니다.
-   **새로운 기능 선택 옵션 추가**:
    1. `.env` 파일에 `INSTALL_새기능="true"` 변수를 추가합니다.
    2. `docker-compose.yml`의 `args`와 `environment`에 해당 변수를 추가합니다.
    3. `Dockerfile` 또는 `post-create-command.sh`에서 `if [ "$INSTALL_새기능" = "true" ]; then ... fi` 조건문으로 설치 로직을 감쌉니다.

이 가이드를 통해 앞으로 이 개발 환경을 자유자재로 확장하고 관리하실 수 있을 것입니다.
