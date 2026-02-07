#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}Setting up your ZSH configuration...${NC}"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${BLUE}Installing Oh My Zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo -e "${GREEN}Oh My Zsh is already installed.${NC}"
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    echo -e "${BLUE}Installing zsh-autosuggestions...${NC}"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
else
    echo -e "${GREEN}zsh-autosuggestions is already installed.${NC}"
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    echo -e "${BLUE}Installing zsh-syntax-highlighting...${NC}"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
else
    echo -e "${GREEN}zsh-syntax-highlighting is already installed.${NC}"
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    echo -e "${BLUE}Installing powerlevel10k theme...${NC}"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
    echo -e "${GREEN}powerlevel10k theme is already installed.${NC}"
fi

if ! command -v fzf &> /dev/null; then
    echo -e "${BLUE}Installing fzf...${NC}"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
    
    if ! grep -q "export FZF_BASE=" ~/.zshrc; then
        echo -e "${BLUE}Adding FZF_BASE to .zshrc...${NC}"
        echo "export FZF_BASE=$HOME/.fzf" >> ~/.zshrc
    fi
else
    echo -e "${GREEN}fzf is already installed.${NC}"
    if ! grep -q "export FZF_BASE=" ~/.zshrc; then
        echo -e "${BLUE}Adding FZF_BASE to .zshrc...${NC}"
        echo "export FZF_BASE=$HOME/.fzf" >> ~/.zshrc
    fi
fi

if ! command -v autojump &> /dev/null; then
    echo -e "${BLUE}Installing autojump...${NC}"
    
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y autojump
        elif command -v yum &> /dev/null; then
        sudo yum install -y autojump
        elif command -v brew &> /dev/null; then
        brew install autojump
    else
        echo -e "${YELLOW}Could not determine package manager. Installing autojump from source...${NC}"
        cd /tmp
        git clone https://github.com/wting/autojump.git
        cd autojump
        ./install.py
    fi
else
    echo -e "${GREEN}autojump is already installed.${NC}"
fi

echo -e "${GREEN}Setup complete! You may need to restart your terminal or run 'source ~/.zshrc' for changes to take effect.${NC}"
echo -e "${YELLOW}Note: If you're in a Docker container or a restricted environment, some installations might require additional permissions.${NC}"
