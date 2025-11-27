# 베이스 이미지
FROM mcr.microsoft.com/devcontainers/java:17-bookworm

# 기능 선택을 위한 빌드 시점 변수
ARG INSTALL_NODE="true"
ARG INSTALL_CONVENIENCE_TOOLS="true"

# 패키지 설치를 위해 root 사용자로 전환
USER root

# 1. 필수 도구 및 신규 저장소 추가용 도구 설치
RUN apt-get update && apt-get install -y \
    git \
    subversion \
    gradle \
    maven \
    curl \
    wget \
    vim \
    zsh \
    zip \
    unzip \
    sudo \
    locales \
    # 다른 리포지토리 추가에 사용될 수 있으므로 유지
    apt-transport-https \
    gpg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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

# 2. non-root 사용자인 'dev-user'를 생성하고 sudo 권한 부여
RUN useradd -m -s /bin/zsh -u 1001 -G sudo dev-user && \
    echo 'dev-user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    touch /home/dev-user/.zshrc && \
    chown dev-user:dev-user /home/dev-user/.zshrc

# 5. SDKMAN! 핵심 파일 설치
ENV SDKMAN_DIR="/usr/local/sdkman"
RUN curl -s "https://get.sdkman.io?rc_path=/etc/profile.d/sdkman-init.sh" | bash && \
    chown -R dev-user:dev-user $SDKMAN_DIR

# 6. nvm 핵심 파일 조건부 설치
RUN if [ "$INSTALL_NODE" = "true" ]; then \
        echo "Installing nvm..." && \
        export NVM_DIR="/opt/nvm" && \
        git clone https://github.com/nvm-sh/nvm.git $NVM_DIR && \
        chown -R dev-user:dev-user $NVM_DIR; \
    fi

# 로케일 설정
RUN sed -i -e 's/# ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
    
# 환경 변수 설정
ENV LANG=ko_KR.UTF-8 \
    LANGUAGE=ko_KR:en_US \
    LC_ALL=ko_KR.UTF-8

# 컨테이너 생성 후 실행될 스크립트를 복사하고 실행 권한 부여
COPY post-create-command.sh /usr/local/bin/post-create-command.sh
RUN chmod +x /usr/local/bin/post-create-command.sh