# 컨테이너 터미널 Alias 목록

이 문서는 `dev_container` 환경의 `dev-user`를 위해 `.zshrc` 파일에 자동으로 추가된 alias 목록을 설명합니다.

---

## 1. 일반 & 탐색 (General & Navigation)

| Alias  | 원본 명령어                                         | 설명                                        |
| :----- | :---------------------------------------------------- | :------------------------------------------ |
| `l`    | `ls -CF`                                              | 기본적인 파일/폴더 목록 보기              |
| `la`   | `ls -A`                                               | 숨김 파일을 포함한 목록 보기              |
| `ll`   | `ls -alF`                                             | 모든 정보를 포함한 긴 목록 보기           |
| `l.`   | `ls -d .* --color=auto`                             | 숨김 파일/폴더만 보기                     |
| `..`   | `cd ..`                                               | 상위 폴더로 이동                          |
| `...`  | `cd ../..`                                            | 두 단계 상위 폴더로 이동                  |
| `....` | `cd ../../..`                                         | 세 단계 상위 폴더로 이동                  |
| `h`    | `history`                                             | 명령어 사용 기록 보기                     |
| `grep` | `grep --color=auto`                                 | `grep` 결과에 색상 입히기                 |
| `ports`| `sudo netstat -tulpn`                                 | 현재 사용 중인 포트 목록 확인             |
| `update`| `sudo apt-get update && sudo apt-get upgrade -y`      | 시스템 패키지를 한번에 업데이트           |

## 2. 빌드 도구 (Maven / Gradle)

| Alias  | 원본 명령어               | 설명                                        |
| :----- | :------------------------ | :------------------------------------------ |
| `mc`   | `mvn clean`               | Maven: `clean` 라이프사이클 실행          |
| `mci`  | `mvn clean install`         | Maven: `clean` 후 `install` 까지 실행     |
| `mcp`  | `mvn clean package`         | Maven: `clean` 후 `package` 까지 실행     |
| `mcd`  | `mvn clean deploy`          | Maven: `clean` 후 `deploy` 까지 실행      |
| `gw`   | `./gradlew`               | Gradle Wrapper 실행                       |
| `gwc`  | `gw clean`                | Gradle: `clean` 태스크 실행               |
| `gwb`  | `gw build`                | Gradle: `build` 태스크 실행               |
| `gwbs` | `gw build -x test`        | Gradle: 테스트를 제외하고 `build` 실행    |
