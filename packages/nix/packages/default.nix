{ nixpkgs, forEachSystem, }:
(forEachSystem (system:
  let
    # Panfactum packages
    pkgs = nixpkgs.legacyPackages.${system};

    # Utitily functions
    util = {
      customNixModule = module: import ./${module}.nix { inherit pkgs; };
      customShellScript = name:
        (pkgs.writeScriptBin name
          (builtins.readFile ./${name}.sh)).overrideAttrs (old: {
            buildCommand = ''
              ${old.buildCommand}
               patchShebangs $out
            '';
            env = { };
          });
    };

    # Pinned Package Sources
    src1 = import (pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "c726225724e681b3626acc941c6f95d2b0602087";
      sha256 = "2xu0jVSjuKhN97dqc4bVtvEH52Rwh6+uyI1XCnzoUyI=";
    }) { inherit system; };
    src2 = import (pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "20bc93ca7b2158ebc99b8cef987a2173a81cde35";
      sha256 = "dkJmk/ET/tRV4007O6kU101UEg1svUwiyk/zEEX9Tdg=";
    }) { inherit system; };
    src3 = import (pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "a343533bccc62400e8a9560423486a3b6c11a23b";
      sha256 = "TofHtnlrOBCxtSZ9nnlsTybDnQXUmQrlIleXF1RQAwQ=";
    }) { inherit system; };
    src4 = import (pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "5710127d9693421e78cca4f74fac2db6d67162b1";
      sha256 = "/KY8hffTh9SN/tTcDn/FrEiYwTXnU8NKnr4D7/stmmA=";
    }) { inherit system; };
    src5 = import (pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "9a9dae8f6319600fa9aebde37f340975cab4b8c0";
      sha256 = "hL7N/ut2Xu0NaDxDMsw2HagAjgDskToGiyZOWriiLYM=";
    }) { inherit system; };
    src6 = import (pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "807c549feabce7eddbf259dbdcec9e0600a0660d";
      sha256 = "9slQ609YqT9bT/MNX9+5k5jltL9zgpn36DpFB7TkttM=";
    }) { inherit system; };
    src7 = import (pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "a9858885e197f984d92d7fe64e9fff6b2e488d40";
      sha256 = "aTIpfLT+hQr0H1d7QA2k5a5rWrkL+M8ECN2tI9ClpSg=";
    }) { inherit system; };
    src8 = import (pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "325eb628b89b9a8183256f62d017bfb499b19bd9";
      sha256 = "9mZL4N+G/iAADDdR6vKDFwiweYLO8hAmjnDHvfVhYCY=";
    }) { inherit system; };
    src9 = import (pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "73bed75dbd3de6d4fca3f81ce25a0cc7766afff6";
      sha256 = "IeBVJ75Bd7yWz8i3m225x5Q25O1Wk8cBWi8DI7bCgSo=";
    }) { inherit system; };

    # Custom Packages
    # We need to us a later version of terragrunt than publicly available
    # b/c the provider-cache is broken and we need it for CI pipelines to
    # work properly
    terragrunt = src7.buildGoModule rec {
      pname = "terragrunt";
      version = "0.59.3";

      src = src7.fetchFromGitHub {
        owner = "gruntwork-io";
        repo = pname;
        rev = "refs/tags/v${version}";
        hash = "sha256-3tXhv/W8F9ag5G7hOjuS7AOU0sdpjdasedhPgMQAV0k=";
      };

      nativeBuildInputs = [ src7.go-mockery ];

      preBuild = ''
        make generate-mocks
      '';

      vendorHash = "sha256-a/pWEgEcT8MFES0/Z1vFCnbSaI47ZIVjhWZbvMC/OJk=";

      doCheck = false;

      ldflags = [
        "-s"
        "-w"
        "-X github.com/gruntwork-io/go-commons/version.Version=v${version}"
      ];

      doInstallCheck = true;

      installCheckPhase = ''
        runHook preInstallCheck
        $out/bin/terragrunt --help
        $out/bin/terragrunt --version | grep "v${version}"
        runHook postInstallCheck
      '';

      meta = with src7.lib; {
        homepage = "https://terragrunt.gruntwork.io";
        changelog =
          "https://github.com/gruntwork-io/terragrunt/releases/tag/v${version}";
        description =
          "Thin wrapper for Terraform that supports locking for Terraform state and enforces best practices";
        mainProgram = "terragrunt";
        license = licenses.mit;
        maintainers = with maintainers; [ jk qjoly kashw2 ];
      };
    };
    customTerragrunt = pkgs.writeShellScriptBin "terragrunt" ''
      #!/bin/env bash

      export GIT_LFS_SKIP_SMUDGE=1
      for arg in "$@"
      do
          if [[ "$arg" == "run-all" ]]; then
              export TERRAGRUNT_PROVIDER_CACHE=1
              export TERRAGRUNT_PROVIDER_CACHE_DIR="$TF_PLUGIN_CACHE_DIR"
              ${terragrunt}/bin/terragrunt "$@"
              exit "$?"
          fi
      done
      ${terragrunt}/bin/terragrunt "$@"
    '';
    cilium = pkgs.symlinkJoin {
      name = "cilium-cli";
      paths = [ src3.cilium-cli ];
      buildInputs = [ src3.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/cilium \
          --add-flags "-n cilium"
      '';
    };
    linkerdVersion = "24.5.1";
    linkerd = pkgs.buildGo122Module rec {
      pname = "linkerd-edge";
      vendorHash = "sha256-sLLgTZN7Zvxkf9J1omh/YGMBUgAtvQD+nbhSuR7/PZg=";
      version = linkerdVersion;

      src = pkgs.fetchFromGitHub {
        owner = "linkerd";
        repo = "linkerd2";
        rev = "edge-${linkerdVersion}";
        sha256 = "sha256-Q+EvW45pClmyCifO72nl2XwqByMfZcVW9PLCHetDZdA=";
      };

      subPackages = [ "cli" ];

      preBuild = ''
        env GOFLAGS="" go generate ./pkg/charts/static
        env GOFLAGS="" go generate ./jaeger/static
        env GOFLAGS="" go generate ./multicluster/static
        env GOFLAGS="" go generate ./viz/static

        # Necessary for building Musl
        if [[ $NIX_HARDENING_ENABLE =~ "pie" ]]; then
            export GOFLAGS="-buildmode=pie $GOFLAGS"
        fi
      '';

      tags = [ "prod" ];

      ldflags = [
        "-s"
        "-w"
        "-X github.com/linkerd/linkerd2/pkg/version.Version=${src.rev}"
      ];

      nativeBuildInputs = [ pkgs.installShellFiles ];

      postInstall = ''
        mv $out/bin/cli $out/bin/linkerd
        installShellCompletion --cmd linkerd \
          --bash <($out/bin/linkerd completion bash) \
          --zsh <($out/bin/linkerd completion zsh) \
          --fish <($out/bin/linkerd completion fish)
      '';

      doInstallCheck = true;
      installCheckPhase = ''
        $out/bin/linkerd version --client | grep ${src.rev} > /dev/null
      '';

      passthru.updateScript = (./. + "/update-edge.sh");

      meta = with pkgs.lib; {
        description =
          "A simple Kubernetes service mesh that improves security, observability and reliability";
        mainProgram = "linkerd";
        downloadPage = "https://github.com/linkerd/linkerd2/";
        homepage = "https://linkerd.io/";
        license = licenses.asl20;
      };
    };
    pgadmin = src3.pgadmin4-desktopmode.overrideAttrs
      (finalAttrs: previousAttrs: {
        postPatch = previousAttrs.postPatch + ''
          substituteInPlace web/config.py --replace "MASTER_PASSWORD_REQUIRED = True" "MASTER_PASSWORD_REQUIRED = False"
        '';

        # These install checks take way too long on first install
        # and are very brittle (don't work on aaarch64)
        doCheck = false;
        doInstallCheck = false;
      });

  in with pkgs; [

    ####################################
    # Nix
    ####################################
    nix

    ####################################
    # Kubernetes
    ####################################
    src5.kubectl # kubernetes CLI
    src5.kubectx # switching between namespaces and contexts
    src5.kustomize # tool for editing manifests programatically
    src5.kubernetes-helm # for working with Helm charts
    (util.customShellScript
      "pf-get-kube-token") # used for authentication within kube_config
    src5.kube-capacity # for visualizing resource utilization in the cluster
    src5.kubectl-cnpg # for managing the cnpg postgres databases
    src5.kubectl-evict-pod # for initiating pod evictions
    linkerd # utility for working with the service mesh
    cilium # for managing the cilium CNI
    src5.argo # utility for working with argo workflows
    src4.cmctl # for working with cert-manager
    src4.stern # log aggregator for quick cli log inspection
    src3.velero # backups of cluster state
    (util.customShellScript
      "pf-tunnel") # for connecting to private network resources through ssh bastion
    src3.k9s # kubernetes tui
    (util.customShellScript
      "pf-eks-reset") # script for resetting cluster during bootstrapping
    (util.customShellScript
      "pf-eks-suspend") # helper to suspending environment resources
    (util.customShellScript
      "pf-eks-resume") # helper to restore suspended environment resources
    (util.customShellScript
      "pf-get-aws-profile-for-kube-context") # get the aws profile used for a kubernetes context
    (util.customShellScript
      "pf-set-pvc-metadata") # sets labels and annotations on a PVC
    (util.customShellScript
      "pf-voluntary-disruptions-enable") # enables voluntary disruptions on a PDB
    (util.customShellScript
      "pf-voluntary-disruptions-disable") # disables voluntary disruptions on a PDB
    (util.customShellScript
      "pf-velero-snapshot-gc") # cleans up orphaned pvc snapshots

    ####################################
    # BuildKit Management
    ####################################
    (util.customShellScript "pf-buildkit-scale-up")
    (util.customShellScript "pf-buildkit-scale-down")
    (util.customShellScript "pf-buildkit-validate")
    (util.customShellScript "pf-buildkit-get-address")
    (util.customShellScript "pf-buildkit-record-build")
    (util.customShellScript "docker-credential-panfactum")
    (util.customShellScript "pf-buildkit-tunnel")
    (util.customShellScript "pf-buildkit-build")
    (util.customShellScript "pf-buildkit-clear-cache")

    ####################################
    # Hashicorp Vault
    ####################################
    src8.vault # provides the vault cli for interacting with vault
    (util.customShellScript
      "pf-get-vault-token") # our helper tool for getting vault tokens during tf runs

    ####################################
    # Infrastructure-as-Code
    ####################################
    src9.opentofu # declarative iac tool (open alternative to terraform)
    customTerragrunt # opentofu-runner
    (util.customShellScript "pf-get-version-hash") # helper for the IaC tagging
    (util.customShellScript
      "wait-on-image") # helper for waiting on image availability
    (util.customShellScript
      "pf-tf-delete-locks") # helper for waiting on image availability
    (util.customShellScript
      "pf-sops-set-profile") # helper for unifiying profile used to access sops-encrypted files
    (util.customShellScript
      "pf-get-terragrunt-variables") # helper for getting terragrunt variables that would be used by modules in the current directory
    (util.customShellScript
      "pf-get-local-module-hash") # helper for invalidating the terraform cache

    ####################################
    # Editors
    ####################################
    micro # a nano alternative with better keybindings
    less # better pager

    ####################################
    # Bash Scripting Utilities
    ####################################
    coreutils # GNU core utilities
    bash # shell
    parallel # run bash commands in parallel
    ripgrep # better alternative to grep
    rsync # file synchronization
    unzip # extraction utility for zip format
    zx # General purpose data compression utility
    entr # Re-running scripts when files change
    bc # bash calculator
    jq # json
    yq # yaml
    fzf # fuzzy selector
    getopt # for parsing command-line arguments
    envsubst # environment substitution in files
    gawk # awk
    gnused # sed
    gnugrep # grep
    gnutar # tar
    findutils # find
    gzip # compression programs
    procps # process info
    lsof # query for open files and (and other fds like ports)
    mktemp # utility for making temporary directories and files
    (util.customShellScript
      "pf-get-repo-variables") # helper for getting repo variables

    ####################################
    # Workflow Utilities
    ####################################
    (util.customShellScript
      "pf-wf-git-checkout") # helper for efficiently cloning repos

    ####################################
    # AWS Utilities
    ####################################
    src1.awscli2 # aws CLI
    src7.ssm-session-manager-plugin # for connecting to hardened ec2 nodes
    aws-nuke # nukes resources in aws accounts
    (util.customShellScript "pf-vpc-network-test") # Test vpc connectivity

    ####################################
    # Secrets Management
    ####################################
    croc # P2P secret sharing
    sops # terminal editor for secrets stored on disk; integrates with tf ecosystem for config-as-code

    ####################################
    # Version Control
    ####################################
    git # vcs CLI
    git-lfs # stores binary files in git host

    ####################################
    # Container Utilities
    ####################################
    buildkit # used for building containers using moby/buildkit
    skopeo # used for moving images around
    manifest-tool # for working with image manifests

    ####################################
    # Network Utilities
    ####################################
    dig # dns lookup
    mtr # better traceroute alternative
    openssh # ssh client and server
    autossh # automatically restart tunnels
    step-cli # working with certificates
    curl # submit network requests from the CLI
    (util.customShellScript "pf-get-open-port") # Test vpc connectivity

    ####################################
    # Database Tools
    ####################################
    src7.redis # redis-cli
    src6.postgresql_16 # psql, cli for working with postgres
    src2.barman # barman cli for backups and restore with postgres
    (util.customShellScript
      "pf-get-db-creds") # gets database credentials from vault
    (util.customShellScript
      "pf-db-tunnel") # establishes a tunnel to a selected database
  ]))
