FROM archlinux:base-devel

RUN pacman-key --init \
    && pacman-key --populate archlinux \
    && pacman -Syu --noconfirm \
    && pacman -S --noconfirm --needed \
        ca-certificates \
        curl \
        fd \
        git \
        neovim \
        ripgrep \
        screenfetch \
        unzip \
        which \
        yazi \
        zsh \
    && sed -i 's/^#ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /usr/share/oh-my-zsh/custom/themes/powerlevel10k \
    && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git /usr/share/oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/share/oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
    && rm -rf /var/cache/pacman/pkg/*

RUN useradd --create-home --shell /usr/bin/zsh --uid 1000 --user-group kento \
    && echo 'kento ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/kento \
    && chmod 440 /etc/sudoers.d/kento

RUN curl -fsSL https://moonrepo.dev/install/proto.sh -o /tmp/proto-install.sh \
    && PROTO_HOME=/opt/proto bash /tmp/proto-install.sh --yes --no-profile \
    && install -m 755 /opt/proto/bin/proto /usr/bin/proto \
    && install -m 755 /opt/proto/bin/proto-shim /usr/bin/proto-shim \
    && rm -rf /opt/proto /tmp/proto-install.sh \
    && git clone --depth=1 https://aur.archlinux.org/paru.git /tmp/paru \
    && chown -R kento:kento /tmp/paru \
    && runuser -u kento -- bash -c 'cd /tmp/paru && makepkg -si --noconfirm' \
    && rm -rf /tmp/paru /home/kento/.cargo

RUN pacman -S --noconfirm --needed openssh \
    && rm -rf /var/cache/pacman/pkg/*

COPY entrypoint.sh /usr/local/bin/wslc-dev-entrypoint
RUN chmod 755 /usr/local/bin/wslc-dev-entrypoint

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/wslc-dev-entrypoint"]
CMD ["sleep", "infinity"]
