#!/bin/bash
# 이 스크립트는 dev_container 환경을 쉽게 관리하기 위한 헬퍼 스크립트입니다.
set -e

# --- CONFIGURATION ---
# Docker Compose 프로젝트 이름 (일반적으로 현재 폴더 이름)
PROJECT_NAME=$(basename "$PWD")
# 백업 파일 이름
BACKUP_FILE="dev_container_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
# 임시 컨테이너에 사용할 이미지
HELPER_IMAGE="alpine:latest"

# --- BASE COMMAND ---
BASE_COMMAND="docker compose --env-file .env -f .devcontainer/docker-compose.yml"

# --- HELPER FUNCTION: Get Volume Mounts ---
# docker-compose.yml에서 'devcontainer' 서비스에 마운트된 모든 네임드 볼륨을 찾아
# 'docker run' 명령어에 필요한 '-v' 플래그 목록을 생성합니다.
get_volume_mounts() {
    local service_name="devcontainer"
    local compose_file=".devcontainer/docker-compose.yml"
    
    # yq가 설치되어 있는지 확인 (macOS/Linux에서 흔히 사용)
    if command -v yq &> /dev/null; then
        # yq를 사용하여 docker-compose.yml 파싱 (더 안정적)
        yq eval ".services.$service_name.volumes[] | select(contains(\":\")) | split(\":\") | \"-v ${PROJECT_NAME}_\" + .[0] + \":\" + .[1]" $compose_file
    else
        # yq가 없을 경우, grep/sed를 사용한 폴백 (덜 안정적)
        grep -E '^\s*-\s*([a-zA-Z0-9_-]+):/home/dev-user' $compose_file | sed -E "s/^\s*-\s*([a-zA-Z0-9_-]+):(.+)/-v ${PROJECT_NAME}_\1:\2/"
        grep -E '^\s*-\s*([a-zA-Z0-9_-]+):/usr/local/sdkman' $compose_file | sed -E "s/^\s*-\s*([a-zA-Z0-9_-]+):(.+)/-v ${PROJECT_NAME}_\1:\2/"
        grep -E '^\s*-\s*([a-zA-Z0-9_-]+):/opt/nvm' $compose_file | sed -E "s/^\s*-\s*([a-zA-Z0-9_-]+):(.+)/-v ${PROJECT_NAME}_\1:\2/"
    fi
}

# --- MAIN COMMAND LOGIC ---
COMMAND=$1
shift

case $COMMAND in
    up) 
        echo "컨테이너를 빌드하고 백그라운드에서 시작합니다..."
        $BASE_COMMAND up -d --build

        echo "최초 설정을 확인하고 실행합니다. 몇 분 정도 소요될 수 있습니다..."
        echo "(자세한 로그는 './dev.sh logs'로 확인 가능합니다)"
        
        $BASE_COMMAND exec devcontainer bash -c "
            if [ ! -f /home/dev-user/.dev_container_setup_complete ]; then
                echo '--- Running first-time setup inside the container... ---' &&
                /usr/local/bin/post-create-command.sh &&
                touch /home/dev-user/.dev_container_setup_complete;
            else
                echo '--- Setup already complete. ---';
            fi
        "

        echo "✅ 모든 설정이 완료되었습니다!"
        echo "이제 './dev.sh shell' 명령어로 컨테이너에 접속할 수 있습니다."
        ;;
    down)
        echo "컨테이너를 중지하고 제거합니다..."
        $BASE_COMMAND down $@
        ;;
    down-v)
        echo "컨테이너를 중지하고, 제거하며, 모든 볼륨(데이터)을 삭제합니다..."
        $BASE_COMMAND down --volumes $@
        ;;
    shell)
        echo "컨테이너 내부의 zsh 셸을 실행합니다..."
        $BASE_COMMAND exec -it devcontainer zsh
        ;;
    backup)
        echo "모든 IDE 및 도구 설정 볼륨을 백업합니다..."
        
        # 백업 디렉토리 생성
        mkdir -p ./backups
        
        # 볼륨 마운트 목록 가져오기
        VOLUME_MOUNTS=$(get_volume_mounts)
        
        # 백업할 볼륨의 컨테이너 내부 경로 목록 생성
        BACKUP_PATHS=$(echo "$VOLUME_MOUNTS" | cut -d':' -f2 | tr '\n' ' ')
        
        echo "다음 볼륨들을 백업합니다:"
        echo "$VOLUME_MOUNTS"
        echo ""
        echo "백업 파일: ./backups/$BACKUP_FILE"

        # 임시 컨테이너를 사용하여 볼륨 데이터를 tar 아카이브로 묶음
        docker run --rm $VOLUME_MOUNTS -v "$(pwd)/backups":/backups "$HELPER_IMAGE" \
            tar -czf /backups/"$BACKUP_FILE" -C / $BACKUP_PATHS

        echo "✅ 백업이 완료되었습니다."
        ;;
    restore)
        # 복원할 백업 파일 찾기
        RESTORE_FILE=$1
        if [ -z "$RESTORE_FILE" ]; then
            echo "오류: 복원할 백업 파일 경로를 지정해야 합니다."
            echo "사용법: $0 restore ./backups/dev_container_backup_YYYYMMDD_HHMMSS.tar.gz"
            exit 1
        fi
        if [ ! -f "$RESTORE_FILE" ]; then
            echo "오류: 백업 파일 '$RESTORE_FILE'을 찾을 수 없습니다."
            exit 1
        fi
        
        read -p "경고: 이 작업은 현재 볼륨의 모든 데이터를 '$RESTORE_FILE'의 내용으로 덮어씁니다. 계속하시겠습니까? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "복원 작업을 취소했습니다."
            exit 1
        fi
        
        echo "백업 파일로부터 모든 설정을 복원합니다..."
        
        # 볼륨 마운트 목록 가져오기
        VOLUME_MOUNTS=$(get_volume_mounts)

        echo "다음 볼륨들을 복원합니다:"
        echo "$VOLUME_MOUNTS"
        
        # 임시 컨테이너를 사용하여 아카이브 압축을 해제하고 볼륨에 덮어씀
        docker run --rm $VOLUME_MOUNTS -v "$(pwd)/$(dirname "$RESTORE_FILE")":/backups "$HELPER_IMAGE" \
            tar -xzf /backups/"$(basename "$RESTORE_FILE")" -C /

        echo "✅ 복원이 완료되었습니다."
        echo "이제 './dev.sh up' 명령어로 컨테이너를 다시 시작하세요."
        ;;
    logs)
        echo "컨테이너 로그를 실시간으로 확인합니다. (Ctrl+C로 종료)"
        $BASE_COMMAND logs -f $@
        ;;
    *)
        echo "사용법: $0 {up|down|down-v|shell|backup|restore|ij|code|logs} [추가 옵션]"
        echo "  up:      컨테이너를 빌드하고, 필요 시 최초 설정을 실행합니다."
        echo "  down:    컨테이너를 중지하고 제거합니다."
        echo "  down-v:  컨테이너와 모든 볼륨(영속화된 데이터)을 함께 제거합니다."
        echo "  shell:   컨테이너 내부의 대화형 zsh 셸을 엽니다."
        echo "  backup:  IDE, SDK 등 모든 설정 데이터를 './backups' 폴더에 압축하여 저장합니다."
        echo "  restore: 지정된 백업 파일로부터 모든 설정을 복원합니다."
        echo "  logs:    컨테이너 로그를 실시간으로 확인합니다."
        exit 1
        ;;
esac