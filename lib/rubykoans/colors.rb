# frozen_string_literal: true

module Rubykoans
  # Terminal color helpers. Stdlib-only — no pastel / colorize / tty-color
  # dependency (research STACK.md §"What NOT to Use": all unmaintained
  # against Ruby 4). Honors `NO_COLOR` (https://no-color.org) and the
  # project-specific `RUBYKOANS_NO_COLOR` opt-out.
  #
  # Usage:
  #   Rubykoans::Colors.red("oops")    # => "\e[31moops\e[0m" on a TTY
  #   Rubykoans::Colors.green("yay")   # => "yay"             when colors are off
  module Colors
    RESET  = "\e[0m"
    RED    = "\e[31m"
    GREEN  = "\e[32m"
    YELLOW = "\e[33m"
    DIM    = "\e[2m"

    module_function

    def use_colors?
      return false if ENV["NO_COLOR"] && !ENV["NO_COLOR"].empty?
      return false if ENV["RUBYKOANS_NO_COLOR"] && !ENV["RUBYKOANS_NO_COLOR"].empty?

      $stdout.tty?
    end

    def red(s)
      use_colors? ? "#{RED}#{s}#{RESET}" : s
    end

    def green(s)
      use_colors? ? "#{GREEN}#{s}#{RESET}" : s
    end

    def yellow(s)
      use_colors? ? "#{YELLOW}#{s}#{RESET}" : s
    end

    def dim(s)
      use_colors? ? "#{DIM}#{s}#{RESET}" : s
    end
  end
end
