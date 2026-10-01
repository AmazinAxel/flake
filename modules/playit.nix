#   sudo mkdir -p /persist/playit
#   sudo playit-cli claim generate
#   sudo playit-cli claim url <code>
#   sudo playit-cli claim exchange <code>
#   printf 'secret_key = "<key>"\n' | sudo tee /persist/playit/secret.toml
#   sudo chmod 0400 /persist/playit/secret.toml
{ inputs, ... }: {
  imports = [ inputs.playit.nixosModules.default ];
  services.playit = {
    enable = true;
    secretPath = "/persist/playit/secret.toml";
  };
}
