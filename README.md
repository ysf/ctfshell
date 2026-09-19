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
```

## setup
```sh
ansible-galaxy collection install -r requirements.yml

cp config.example.yaml config.local.yaml
cp inventory.example inventory
cp vault.example.yaml vault.yaml

chmod 600 config.local.yaml inventory vault.yaml

vim config.local.yaml inventory vault.yaml

# set http-basic-auth pw to the output below
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

automatic dns currently supports porkbun only. use its authoritative nameservers, enable domain api access and supply `porkbun_api_key` + `porkbun_secret_key` in `vault.yaml`. deployment creates the records below.

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

the `ns` records delegate `i.example.com` to your interactsh server. `--skip-tags dns` only skips the porkbun api tasks; it does not configure public interactsh servers or remove the need for manual dns.

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

the first two commands should return your server ip. the trace should reach your delegated interactsh server once it is running.

## deploy / remove

set the server hostname or public ip under `[ctf_servers]` in your local `inventory`.

```sh
# create / configure; add --skip-tags dns only for manually managed dns
ansible-playbook --ask-vault-pass deploy.yaml
```

```sh
# remove the server, keep the persistent volume; not the next setup step
ansible-playbook --ask-vault-pass delete.yaml
```

if you keep your vault password in the ignored `.vault-pass`, use `--vault-password-file .vault-pass` instead of `--ask-vault-pass`.

## web interfaces

- `https://ctf.example.com`: interactsh gui, protected by caddy basic auth. use `vault_interactsh_gui_user` and the password you hashed, not the hash itself.
- `https://wh.example.com`: webhook.site; open it and copy the unique webhook url. no caddy basic auth is configured here.
- `i.example.com`: interactsh protocol endpoint, not the gui. clients use `vault_interactsh_token`, not the gui password.

## blocking public scanners

known scanner sources (censys, shodan, etc.) are loaded from misp warninglists into ipv4/ipv6 ipsets and dropped into ufw's service rules.

ansible fetches the lists locally during deployment. the server restores them at boot and refreshes them weekly.

```sh
sudo scanner-block status
sudo scanner-block update
systemctl list-timers scanner-block-update.timer
```

to disable persistently, set this in `config.local.yaml`, then apply the role:

```yaml
scanner_block_enabled: false
```

```sh
ansible-playbook --ask-vault-pass --tags scanner_block deploy.yaml
```

set it back to `true` and rerun to enable. `scanner-block off` alone is not persistent: the timer, ufw hook or next deploy can reapply it. `scanner_block_auto_update: false` disables only refreshes.

keep `scanner_block_allowlist` empty unless you know what you do.

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
host ctf-sync
    hostname ctf.example.com
    user ctf
    localforward 127.0.0.1:8385 127.0.0.1:8384
    sessiontype none
    exitonforwardfailure yes
```

```sh
ssh ctf-sync # leave running; open http://127.0.0.1:8385
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

the server also gets neovim, zsh/pure, fzf, ripgrep, gdb/pwndbg, radare2, pwntools and other ctf tools. neovim plugins bootstrap on first launch.

```sh
# optional: with mosh installed locally; server udp 60000–61000 is allowed
mosh ctf@ctf.example.com
```

## clipboard over ssh

if you have osc52 set up in your terminals, you can use the clipboard via ssh. neovim and tmux are set up. for shell output you want to catch without tmux:

```sh
printf 'hello from ctfshell' | ~/bin/yank
~/bin/yank ./notes.txt
```

the helper strips trailing newlines. for local → remote, use your terminal's normal paste shortcut.

please only allow clipboard writes from trusted sessions: remote output can overwrite your local clipboard.
