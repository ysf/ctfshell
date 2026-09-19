# ctfshell

heavily opinionated and lazy way of doing ctf/bugbounty on macOS using archlinux remotely.

```sh
git clone https://github.com/ysf/ctfshell.git
cd ctfshell
```
## requirements

### macos

```sh
brew install ansible packer gitleaks caddy

# if you want to use syncthing:
brew install syncthing
brew services start syncthing
open http://127.0.0.1:8384
```

### arch

```sh
sudo pacman --sync --refresh --sysupgrade --needed git ansible packer gitleaks caddy

# if you want to use syncthing:
sudo pacman --sync --refresh --sysupgrade --needed syncthing xdg-utils
systemctl --user enable --now syncthing.service
xdg-open http://127.0.0.1:8384

## setup
```sh
ansible-galaxy collection install -r requirements.yml

cp config.example.yaml config.local.yaml
cp inventory.example inventory
cp vault.example.yaml vault.yaml

chmod 600 config.local.yaml inventory vault.yaml

vim config.local.yaml inventory vault.yaml

# set your basic-auth pw and set it in vault.yml to use interactsh
caddy hash-password
ansible-vault encrypt vault.yaml
```


### i use a packer as machine image
```sh
cd packer
cp -n local.example.pkrvars.hcl local.pkrvars.hcl
chmod 600 local.pkrvars.hcl
vim local.pkrvars.hcl
packer init templates/archlinux.pkr.hcl
packer build -var-file=local.pkrvars.hcl templates/archlinux.pkr.hcl
cd ..
```

## hetzner

you'll need to upload your ssh public key to the hetzner project and set it in `config.local.yaml`. i have not tried other providers yet.

the persistant volume is attached to the running instance under `/mnt/persistent` and is not deleted, therefore it raises your monthly bill.

### create a persitent volume, i use 20gb
```sh
ansible localhost -c local -m hetzner.hcloud.hcloud_volume \
  -a 'name=ctfshell-volume size=20 location=nbg1 format=ext4 state=present api_token="{{ vault_ctfshell_hcloud_token }}"' \
  -e @vault.yaml --ask-vault-pass
```

## dns
set your `domain` in `config.local.yaml`. defaults are `ctf` for the gui, `i` for interactsh, `wh` for webhook.site.

if you have an api for your dns provider everything is set at deployment, i use porkbun's authoritative nameservers for the domain, you need to enable api-access obviously and supply the keys in `vault.yml`. deploying creates the records below.

without api you have to create the records manually. use ttl 300 and disable any http/cdn proxy.

| type | name | value |
| --- | --- | --- |
| a | ctf | <public ip> |
| a | wh | <public ip> |
| a | i | <public ip> |
| a | ns1.i | <public ip> |
| a | ns2.i | <public ip> |
| ns | i | ns1.i.example.com. |
| ns | i | ns2.i.example.com. |

the `ns` records delegate `i.example.com` to interactsh. you only need to do this if you don't want to leak your oob targets to interactsh public servers. for normal ctfs, you might not need this and can skip dns deployment with:

```sh
# manual dns
ansible-playbook --ask-vault-pass --skip-tags dns deploy.yaml
```

you're done if

```sh
dig +short ctf.example.com
dig +short wh.example.com
dig +trace test.i.example.com
```

shows your public ip.

## interactsh

### local client

install locally

```sh
go install github.com/projectdiscovery/interactsh/cmd/interactsh-client@v1.3.1
```

then retrieve the token:

```sh
ssh -t ctf@ctf.example.com sudo /usr/local/sbin/show-tokens
```

and save your token to `~/.config/interactsh-client/config.yaml`:
```yaml
server: "i.example.com"
token: "interactsh-token-here"
```

```sh
umask 077
mkdir -p ~/.config/interactsh-client
vim ~/.config/interactsh-client/config.yaml
chmod 600 ~/.config/interactsh-client/config.yaml
```

replace `i.example.com` obviously.

comfy shortcut for your aliases/shell:

```sh
i() { ~/go/bin/interactsh-client -config ~/.config/interactsh-client/config.yaml "$@"; }
```


### ssh fallback

if you can't install the local client, you can launch it on the server:

```sh
ctf_host=ctf@ctf.example.com
i() { ssh "$ctf_host" i; }
```

`https://i.example.com/` returning 404 is intentional btw, if someone checks their logs. (they don't)

## syncthing for local<->remote file sync

adapt syncthing ports in `~/.ssh/config`:

```sshconfig
host ctf
    hostname ctf.example.com
    user ctf
    localforward 127.0.0.1:8385 127.0.0.1:8384
    sessiontype none
    exitonforwardfailure yes
```

```sh
# leave running; open http://127.0.0.1:8385 locally
ssh ctf
```

ansible binds syncthing gui to `127.0.0.1:8384` and blocks tcp/8384 with ufw.

you'll need to add the remote device-id to your local syncthing and vice versa. enable auto accept for your local device. new folders will be at `/mnt/persistent/projects`.

again, comfy aliases:

```sh
syncthing_device_id='replace-with-server-device-id'

stcli() { syncthing cli "$@"; }

ctf-status() { stcli config folders list; }

ctf-mount() {
    local directory folder
    directory=$(cd "${1:-.}" && pwd) || return
    folder=$(basename "$directory")
    stcli config folders add --id "$folder" --path "$directory" && stcli config folders "$folder" devices add --device-id "$syncthing_device_id"
}

ctf-unmount() { local directory; directory=$(cd "${1:-.}" && pwd) || return; stcli config folders "$(basename "$directory")" delete; }
ctf-pause() { local directory; directory=$(cd "${1:-.}" && pwd) || return; stcli config folders "$(basename "$directory")" paused set true; }
ctf-unpause() { local directory; directory=$(cd "${1:-.}" && pwd) || return; stcli config folders "$(basename "$directory")" paused set false; }

```

`stcli` uses syncthing's default config. `ctf-mount` shares files/directories and `ctf-unmount` removes the config, not the directory. deletes propagate remotely, make backups. folder names must be unique.

```sh
ctf-mount ~/projects/challenge
ctf-status
ctf-pause ~/projects/challenge
ctf-unpause ~/projects/challenge
ctf-unmount ~/projects/challenge
```


## other things.
### vpn
i added a vpn example in `roles/vpn/files/tryhackme.ovpn`. just
place it there and deploy

```sh
~/tools/thm-start.sh # starts tryhackme
~/tools/thm-stop.sh # stops every
```

change for your custom vpns.

gdb/pwndbg is installed, but remote gdb not automatically open optionally binja debugger files are copied, but not started too. (`roles/ctf_tools/files/binja-debugger/`)

tmux plugins set in `.tmux.conf` are installed automatically by ansible.

## clipboard over ssh

if you have osc52 set up in your terminals, you can use the clipboard via ssh. neovim and tmux are set up. for shell output you want to catch without tmux:

```sh
printf 'hello from ctfshell' | ~/bin/yank
~/bin/yank ./notes.txt
```

the helper strips trailing newlines. for local → remote, use your terminal's normal paste shortcut.

please only allow clipboard writes from trusted sessions: remote output can overwrite your local clipboard.
