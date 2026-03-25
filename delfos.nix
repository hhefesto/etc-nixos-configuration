{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration-delfos.nix ];
  networking.hostName = "delfos";
}
