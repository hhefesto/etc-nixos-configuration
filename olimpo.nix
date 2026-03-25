{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration-olimpo.nix ];
  networking.hostName = "olimpo";
}
