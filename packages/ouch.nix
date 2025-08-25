# https://github.com/NixOS/nixpkgs/blob/20075955deac2583bb12f07151c2df830ef346b4/pkgs/by-name/ou/ouch/package.nix
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  pkg-config,
  bzip2,
  bzip3,
  xz,
  git,
  zlib,
  zstd,

  # RAR code is under non-free unRAR license
  # see the meta.license section below for more details
  enableUnfree ? false,
}:

rustPlatform.buildRustPackage rec {
  pname = "ouch";
  version = "main";

  src = fetchFromGitHub {
    owner = "ouch-org";
    repo = "ouch";
    rev = version;
    hash = "sha256-73uALo/X9NMFHlx2pTTP/P67aotvew8InmdwB3Oj6H0=";
  };

  cargoHash = "sha256-FCIqV3ce70Axz4enAH0gdOeWGoIp2JwMWgSFfp7uMZw==";

  nativeBuildInputs = [
    installShellFiles
    pkg-config
    rustPlatform.bindgenHook
  ];

  nativeCheckInputs = [
    git
  ];

  buildInputs = [
    bzip2
    bzip3
    xz
    zlib
    zstd
  ];

  buildNoDefaultFeatures = true;
  buildFeatures = [
    "use_zlib"
    "use_zstd_thin"
    # "bzip3" will be optional in the next version
    "zstd/pkg-config"
  ]
  ++ lib.optionals enableUnfree [
    "unrar"
  ];

  postInstall = ''
    installManPage artifacts/*.1
    installShellCompletion artifacts/ouch.{bash,fish} --zsh artifacts/_ouch
  '';

  env.OUCH_ARTIFACTS_FOLDER = "artifacts";

  meta = {
    description = "Command-line utility for easily compressing and decompressing files and directories";
    homepage = "https://github.com/ouch-org/ouch";
    changelog = "https://github.com/ouch-org/ouch/blob/${version}/CHANGELOG.md";
    license = with lib.licenses; [ mit ] ++ lib.optionals enableUnfree [ unfreeRedistributable ];
    maintainers = with lib.maintainers; [
      figsoda
      psibi
      krovuxdev
    ];
    mainProgram = "ouch";
  };
}
