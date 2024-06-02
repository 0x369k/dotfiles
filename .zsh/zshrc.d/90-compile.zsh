#COMP=false
#if [[ $COMP == "true" ]]; then
#compile_zsh_scripts() {
#    local script_dir=$1
#    for script in $script_dir/*.zsh; do
#        if [[ -f "$script" && (! -f "$script.zwc" || "$script" -nt "$script.zwc") ]]; then
#            zcompile "$script"
#            echo "Kompiliert: $script zu $script.zwc"
#        fi
#    done
#}

# Kompilieren der Skripte
#compile_zsh_scripts "$HOME/.zsh/functions"
#f1