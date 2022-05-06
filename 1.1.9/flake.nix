{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Pinned to the commit that updated Terraform.
    nixpkgs-terraform.url = "github:nixos/nixpkgs/2696f4c69688d6c31fb8363fdf556e06047eb068";
  };

  outputs = { self, nixpkgs, nixpkgs-terraform, ... }:
    let
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        # The AWS Session Manager plugin is unfree, so we add it to a whitelist.
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          "ssm-session-manager-plugin"
        ];
      };

      terraform_1 = (import nixpkgs-terraform { system = "x86_64-linux"; }).terraform_1;
    in
    {
      defaultPackage."x86_64-linux" = pkgs.dockerTools.buildLayeredImage {
        name = "ghcr.io/d3b-center/terraform";
        tag = lib.getVersion pkgs.terraform_1;

        contents = with pkgs; [
          awscli2
          bashInteractive # Bash with readline support.
          busybox
          git # For fetching Terraform modules over git.
          jq # Useful for parsing JSON output of the AWS CLI.
          openssh
          ssm-session-manager-plugin # For connecting to bastion hosts.
          terraform_1

          (runCommand "base-system" { } ''
            mkdir -p $out/etc

            mkdir -p $out/etc/ssl/certs
            ln -s ${cacert}/etc/ssl/certs/ca-bundle.crt $out/etc/ssl/certs/ca-certificates.crt

            echo "root:x:0:0::/root:${runtimeShell}" > $out/etc/passwd
            echo "root:!x:::::::" > $out/etc/shadow
            echo "root:x:0:" > $out/etc/group

            mkdir -p $out/tmp

            mkdir -p $out/root
          '')
        ];

        config.Entrypoint = [ "${pkgs.terraform_1}/bin/terraform" ];

        # We are making a conscious tradeoff to break binary reproducibility to
        # have a meaningful timestamp on the image.
        # https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools-buildImage
        created = "now";
      };
    };
}
