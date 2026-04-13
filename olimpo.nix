{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration-olimpo.nix
    ./expedientes-local.nix
  ];

  networking.hostName = "olimpo";
}
