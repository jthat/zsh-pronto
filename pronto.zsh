# pronto zsh theme
#
# Copyright (C) 2021-2022 Jason Thatcher.
# Licensed under the MIT license.
# SPDX-License-Identifier: MIT
#

[[ -o interactive ]] || return
zmodload zsh/datetime || { print "can't load zsh/datetime"; return }
autoload -Uz add-zsh-hook || { print "can't load add-zsh-hook"; return }

(( ${+pronto_features} )) || typeset -A pronto_features=( time 1 git 1 rprompt 1 )

pronto_init() {
  local lp=('%(?..%??)%n@%m:')
  local rp=()

  if (( $pronto_features[rprompt] )) {
    rp+=('%1v')
  } else {
    pronto_features[time]=0
    lp+=('%1v')
  }

  lp+=('%0~%#%(1j.%j&.) ')

  PROMPT=${(j..)lp}
  RPROMPT=${(j..)rp}
}

pronto_preexec() {
  pronto_timestamp=$EPOCHREALTIME
}

pronto_format_duration() {
  local s=()
  local r="$(printf '%.0f' $1)"
  (($r >= 31557600)) && { s+="$(($r / 31557600))y"; r=$(($r % 31557600)) }
  (($r >= 604800  )) && { s+="$(($r / 604800  ))w"; r=$(($r % 604800  )) }
  (($r >= 86400   )) && { s+="$(($r / 86400   ))d"; r=$(($r % 86400   )) }
  (($r >= 3600    )) && { s+="$(($r / 3600    ))h"; r=$(($r % 3600    )) }
  (($r >= 60      )) && { s+="$(($r / 60      ))m"; r=$(($r % 60      )) }
  print -n "${(j::)s}$(printf '%.3f' $(($1 % 60)))s"
}

pronto_precmd () {
  local all=()
  local delta_string=""

  if (( $pronto_features[time] )) {
    pronto_elapsed=0
    if (( pronto_timestamp > 0 )) {
      pronto_elapsed=$(( EPOCHREALTIME - pronto_timestamp ))
      delta_string=$(pronto_format_duration $pronto_elapsed)
      pronto_last_timestamp=$pronto_timestamp
    }
    pronto_timestamp=0
  }

  if (( $pronto_features[git] )) {
    local -A gs

    command git status --porcelain=v2 --branch --untracked-files=no 2>/dev/null | {
      local IFS=''; while read -A; do
        if [[ $reply[1] =~ '^# branch\.(oid|head|ab) (.*)$' ]] {
          gs+=($match)
        }
      done
    }

    if [[ -n $gs ]] {
      local ab_string=()
      if [[ $gs[ab] =~ '^[+]([0-9]+) [-]([0-9]+)$' ]] {
        local ahead=$match[1]
        local behind=$match[2]
        [[ $ahead != 0 ]] && ab_string+=${ahead}↑
        [[ $behind != 0 ]] && ab_string+=${behind}↓
      }
      local git_string=($gs[head] ${gs[oid]:0:7} ${(j::)ab_string})
      (( $pronto_features[rprompt] )) || git_string=(${(Oa)git_string})
      all+=${(j.·.)git_string}
    }
  }

  if (( $pronto_features[time] )) {
    if [[ -n $delta_string ]] {
      all+=$delta_string
    }
    all+=$(print -Pn '%D{%f %b %L:%M:%S%p}')
  }

  if (( $pronto_features[rprompt] )) {
    psvar=("${(j: | :)all}")
  } else {
    (( $#all )) && all+=''
    psvar=("${(j.:.)all}")
  }
}

add-zsh-hook precmd pronto_precmd
add-zsh-hook preexec pronto_preexec

pronto_init
