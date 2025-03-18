FROM 117503445/dev-base:sha-c08a8ac

RUN pacman -Sy --noconfirm go-task qemu aria2

RUN su - builder -c "yay -Sy --noconfirm novnc"

WORKDIR /workspace

COPY ./scripts/run-vm/br.sh /workspace/script/br.sh

COPY nixos-playground .

ENTRYPOINT [ "/workspace/nixos-playground", "runner" ]