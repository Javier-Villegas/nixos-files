{ pkgs, ... }:
{
  hardware.pulseaudio.enable = false;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Low Latency Audio
  environment.etc.
  "pipewire/pipewire.conf.d/92-low-latency.conf".text = ''
    context.properties = {
      default.clock.rate = 48000
      default.clock.quantum = 32
      default.clock.min-quantum = 32
      default.clock.max-quantum = 32
    }
  '';

  environment.etc.
  "pipewire/pipewire-pulse.d/92-low-latency.conf" = let
    json = pkgs.formats.json {};
  in {
    source = json.generate "92-low-latency.conf" {
      context.modules = [
        {
	  name = "libpipewire-module-protocol-pulse";
          args = {
            pulse.min.req = "32/48000";
	    pulse.default.req = "32/48000";
	    pulse.max.req = "32/48000";
	    pulse.min.quantum = "32/48000";
	    oulse.max.quantum = "32/48000";
	  };
	}
      ];
      stream.properties = {
        node.latency = "32/48000";
	resample.quality = 1;
      };
    };
  };
}
