#for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
for file in ~/.{exports,aliases,functions}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;
[[ `uname -s` == "Linux" ]] && [[ $- = *i* ]] && source ~/.liquidprompt/liquidprompt && . /usr/local/etc/profile.d/z.sh
[[ `uname -s` == "Darwin" ]] && . /usr/local/share/liquidprompt && . /usr/local/etc/profile.d/z.sh
