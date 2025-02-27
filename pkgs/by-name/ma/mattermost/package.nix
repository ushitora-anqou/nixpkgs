{ lib
, buildGoModule
, fetchFromGitHub
, nix-update-script
, fetchurl
, nixosTests
}:

buildGoModule rec {
  pname = "mattermost";
  # ESR releases only.
  # See https://docs.mattermost.com/upgrade/extended-support-release.html
  # When a new ESR version is available (e.g. 8.1.x -> 9.5.x), update
  # the version regex in passthru.updateScript as well.
  version = "9.11.6";

  src = fetchFromGitHub {
    owner = "mattermost";
    repo = "mattermost";
    rev = "v${version}";
    hash = "sha256-5nUzUnVWVBnQErbMJeSe2ZxCcdcHSmT34JXjFlRMW/s=";
  };

  # Needed because buildGoModule does not support go workspaces yet.
  # We use go 1.22's workspace vendor command, which is not yet available
  # in the default version of go used in nixpkgs, nor is it used by upstream:
  # https://github.com/mattermost/mattermost/issues/26221#issuecomment-1945351597
  overrideModAttrs = (_: {
    buildPhase = ''
      make setup-go-work
      go work vendor -e
    '';
  });

  webapp = fetchurl {
    url = "https://releases.mattermost.com/${version}/mattermost-${version}-linux-amd64.tar.gz";
    hash = "sha256-yG5GDeuCHv95e+b2xi/UYiCGkV+I3aqj13Qh/YbyOWQ=";
  };

  # Makes nix-update-script pick up the fetchurl for the webapp.
  # https://github.com/Mic92/nix-update/blob/1.3.1/nix_update/eval.py#L179
  offlineCache = webapp;

  vendorHash = "sha256-Gwv6clnq7ihoFC8ox8iEM5xp/us9jWUrcmqA9/XbxBE=";

  modRoot = "./server";
  preBuild = ''
    make setup-go-work
  '';

  subPackages = [ "cmd/mattermost" ];

  tags = [ "production" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/mattermost/mattermost/server/public/model.Version=${version}"
    "-X github.com/mattermost/mattermost/server/public/model.BuildNumber=${version}-nixpkgs"
    "-X github.com/mattermost/mattermost/server/public/model.BuildDate=1970-01-01"
    "-X github.com/mattermost/mattermost/server/public/model.BuildHash=v${version}"
    "-X github.com/mattermost/mattermost/server/public/model.BuildHashEnterprise=none"
    "-X github.com/mattermost/mattermost/server/public/model.BuildEnterpriseReady=false"
  ];

  postInstall = ''
    tar --strip 1 --directory $out -xf $webapp \
      mattermost/{client,i18n,fonts,templates,config}

    # For some reason a bunch of these files are executable
    find $out/{client,i18n,fonts,templates,config} -type f -exec chmod -x {} \;
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [ "--version-regex" "^v(9\\.11\\.[0-9]+)$" ];
    };
    tests.mattermost = nixosTests.mattermost;
  };

  meta = with lib; {
    description = "Mattermost is an open source platform for secure collaboration across the entire software development lifecycle";
    homepage = "https://www.mattermost.org";
    license = with licenses; [ agpl3Only asl20 ];
    maintainers = with maintainers; [ ryantm numinit kranzes mgdelacroix ];
    mainProgram = "mattermost";
  };
}
