# Get the filename to store/lookup the environment from
HOST=${HOST:-device}
USERNAME=${USERNAME:-$USER:-user}

ssh_env_cache="$HOME/.ssh/env-$HOST"

_start_agent() {
  if (( ! $+commands[ssh] || ! $+commands[ssh-agent] )); then
    zstyle -t :zi:plugins:ssh-agent quiet || echo >&2 "Commands ssh and ssh-agent not found ..."
    return 1
  fi

  if [[ -f "$ssh_env_cache" ]]; then
    . "$ssh_env_cache" > /dev/null
    zmodload zsh/net/socket
    if [[ -S "$SSH_AUTH_SOCK" ]] && zsocket "$SSH_AUTH_SOCK" 2>/dev/null; then
      return 0
    fi
  fi

  if [[ ! -d "$HOME/.ssh" ]]; then
    zstyle -t :zi:plugins:ssh-agent quiet || echo >&2 "The ssh-agent plugin requires ~/.ssh directory ..."
    return 1
  fi

  local lifetime
  zstyle -s :zi:plugins:ssh-agent lifetime lifetime

  zstyle -t :zi:plugins:ssh-agent quiet || echo >&2 "Starting ssh-agent ..."
  ssh-agent -s ${lifetime:+-t} ${lifetime} | sed '/^echo/d' >! "$ssh_env_cache"
  chmod 600 "$ssh_env_cache"
  . "$ssh_env_cache" > /dev/null
}

_add_identities() {
  local id file line sig lines
  local -a identities loaded_sigs loaded_ids not_loaded
  zstyle -a :zi:plugins:ssh-agent identities identities

  if [[ ! -d "$HOME/.ssh" ]]; then
    return
  fi

  if [[ ${#identities} -eq 0 ]]; then
    for id in id_rsa id_dsa id_ecdsa id_ed25519 identity; do
      [[ -f "$HOME/.ssh/$id" ]] && identities+=($id)
    done
  fi

  if lines=$(ssh-add -l); then
    for line in ${(f)lines}; do
      loaded_sigs+=${${(z)line}[2]}
      loaded_ids+=${${(z)line}[3]}
    done
  fi

  for id in $identities; do
    [[ "$id" = /* ]] && file="$id" || file="$HOME/.ssh/$id"
    if [[ ${loaded_ids[(I)$file]} -le 0 ]]; then
      sig="$(ssh-keygen -lf "$file" | awk '{print $2}')"
      [[ ${loaded_sigs[(I)$sig]} -le 0 ]] && not_loaded+=("$file")
    fi
  done

  if [[ ${#not_loaded} -eq 0 ]]; then
    return
  fi

  local args
  zstyle -a :zi:plugins:ssh-agent ssh-add-args args

  zstyle -t :zi:plugins:ssh-agent quiet && args=(-q $args)

  local helper
  zstyle -s :zi:plugins:ssh-agent helper helper

  if [[ -n "$helper" ]]; then
    if [[ -z "${commands[$helper]}" ]]; then
      echo >&2 "ssh-agent: the helper '$helper' has not been found."
    else
      SSH_ASKPASS="$helper" ssh-add "${args[@]}" ${^not_loaded} < /dev/null
      return $?
    fi
  fi

  ssh-add "${args[@]}" ${^not_loaded}
}

if zstyle -t :zi:plugins:ssh-agent agent-forwarding && [[ -n "$SSH_AUTH_SOCK" && ! -L "$SSH_AUTH_SOCK" ]]; then
  ln -sf "$SSH_AUTH_SOCK" /tmp/ssh-agent-$USERNAME-screen
else
  _start_agent
fi

if ! zstyle -t :zi:plugins:ssh-agent lazy; then
  _add_identities
fi

unset agent_forwarding ssh_env_cache
unfunction _start_agent _add_identities
