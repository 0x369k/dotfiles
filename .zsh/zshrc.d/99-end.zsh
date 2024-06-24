if [[ $DEBUG == "true" ]]; then
  unsetopt xtrace
  exec 2>&3 3>&-
  zprof > ~/.cache/zi/log/zshprofile_$NOW.log
fi
