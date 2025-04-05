mkdir $"($nu.data-dir)/vendor/autoload"
pixi completion --shell nushell | save --force $"($nu.data-dir)/vendor/autoload/pixi-completions.nu"
