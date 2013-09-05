for location in zsh-custom/*.*; do
  file="${location##*/}"
  file="${file%.*}"
  echo "Linking '$dotfiles/$location' to '$HOME/.$file'"
done

