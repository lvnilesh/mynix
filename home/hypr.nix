{
  config,
  pkgs,
  lib,
  ...
}: {
  # Link Hyprland config from dotfiles
  home.file.".config/hypr/hyprland.conf".source = ../dotfiles/hyprland.conf;
  home.file.".config/hypr/hyprlock.conf".source = ../dotfiles/hyprlock.conf;
  home.file.".config/hypr/hypridle.conf".source = ../dotfiles/hypridle.conf;

  home.file.".config/walker/config.toml".source = ../dotfiles/walker/config.toml;

  home.file.".config/waybar/config".source = ../dotfiles/waybar/config;
  home.file.".config/waybar/style.css".source = ../dotfiles/waybar/style.css;
  home.file.".config/waybar/caffeine_status.sh".source = ../dotfiles/waybar/caffeine_status.sh;
  home.file.".config/waybar/caffeine_toggle.sh".source = ../dotfiles/waybar/caffeine_toggle.sh;

  # Initialize mutable theme files on activation (default to current or nord)
  home.activation.initThemeFiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    THEME=$(cat "$HOME/.config/current-theme" 2>/dev/null || echo nord)
    THEME_DIR="$HOME/mynix/themes/$THEME"
    [ -d "$THEME_DIR" ] || THEME_DIR="$HOME/mynix/themes/nord"
    mkdir -p "$HOME/.config/hypr" "$HOME/.config/kitty" "$HOME/.config/waybar" \
             "$HOME/.config/gtk-4.0" "$HOME/.config/mako" "$HOME/.config/swayosd"
    [ -f "$HOME/.config/hypr/theme.conf" ]          || cp "$THEME_DIR/hyprland.conf" "$HOME/.config/hypr/theme.conf"
    [ -f "$HOME/.config/hypr/hyprlock-theme.conf" ] || cp "$THEME_DIR/hyprland.conf" "$HOME/.config/hypr/hyprlock-theme.conf"
    [ -f "$HOME/.config/kitty/theme.conf" ]         || cp "$THEME_DIR/kitty.conf"    "$HOME/.config/kitty/theme.conf"
    [ -f "$HOME/.config/waybar/theme.css" ]         || cp "$THEME_DIR/waybar.css"    "$HOME/.config/waybar/theme.css"
    [ -f "$HOME/.config/gtk-4.0/gtk.css" ]          || cp "$THEME_DIR/gtk4.css"      "$HOME/.config/gtk-4.0/gtk.css"
  '';
}
