#!/bin/bash
# ---------------------------------------------------
# Arch/CachyOS Hyprland & Pentesting Env Auto Installer
# ---------------------------------------------------

# 에러 발생 시 스크립트 중단
set -e

# 스크립트가 실행된 현재 디렉토리의 절대 경로 확보
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">>> 시스템 마이그레이션 및 패키지 설치를 시작합니다..."

# 1. 기존 사용자 설정 안전 백업 (동적 백업 방식)
BACKUP_DIR="$HOME/dotfiles-backup-$(date +%Y%m%d_%H%M%S)"
echo ">>> 충돌 방지를 위해 기존 설정을 백업합니다. ($BACKUP_DIR)"
mkdir -p "$BACKUP_DIR/.config"

# 저장소의 .config 폴더 내에 있는 디렉토리들만 확인하여 기존 환경 백업
if [ -d "$SCRIPT_DIR/.config" ]; then
    for item in "$SCRIPT_DIR/.config"/*; do
        item_name=$(basename "$item")
        if [ -e "$HOME/.config/$item_name" ]; then
            mv "$HOME/.config/$item_name" "$BACKUP_DIR/.config/"
            echo "  -> $item_name 백업 완료"
        fi
    done
fi

# 쉘 설정 파일 백업
for file in .bashrc .bash_profile .xprofile; do
    if [ -f "$HOME/$file" ]; then
        mv "$HOME/$file" "$BACKUP_DIR/"
        echo "  -> $file 백업 완료"
    fi
done

# 2. 필수 패키지 설치
echo ">>> 시스템 업데이트 및 패키지 설치를 진행합니다..."
sudo pacman -Syu --noconfirm

if [ -f "$SCRIPT_DIR/pkglist.txt" ]; then
    echo ">>> 공식 레포지토리 패키지(pkglist.txt)를 설치합니다..."
    sudo pacman -S --needed --noconfirm - < "$SCRIPT_DIR/pkglist.txt"
fi

if [ -f "$SCRIPT_DIR/aurlist.txt" ]; then
    echo ">>> AUR 패키지(aurlist.txt)를 설치합니다..."
    # CachyOS 기본 제공 paru 사용
    paru -S --needed --noconfirm - < "$SCRIPT_DIR/aurlist.txt"
fi

# 3. 새로운 설정 파일(Dotfiles) 적용
echo ">>> 새로운 설정 파일들을 시스템에 적용합니다..."
mkdir -p ~/.config

# .config 하위 폴더 복사
if [ -d "$SCRIPT_DIR/.config" ]; then
    cp -r "$SCRIPT_DIR/.config/"* ~/.config/
fi

# 홈 디렉토리 쉘 설정 파일 복사
for file in .bashrc .bash_profile .xprofile; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        cp "$SCRIPT_DIR/$file" ~/
    fi
done

# 환경 변수 파일(environment) 처리
# 루트 권한이 필요한 /etc/environment 대신 사용자 전용 경로로 안전하게 복사
if [ -f "$SCRIPT_DIR/environment" ]; then
    mkdir -p ~/.config/environment.d
    cp "$SCRIPT_DIR/environment" ~/.config/environment.d/env.conf
    echo "  -> 환경 변수(environment)가 ~/.config/environment.d/env.conf 로 적용되었습니다."
fi

# 4. 마무리
echo ">>> 폰트 캐시를 갱신합니다..."
fc-cache -fv

echo "✅ 모든 설치 및 세팅이 완벽하게 끝났습니다!"
echo "변경 사항을 시스템에 완전히 반영하려면 재부팅(sudo reboot) 하십시오."
