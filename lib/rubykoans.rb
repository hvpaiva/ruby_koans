# frozen_string_literal: true

require_relative "rubykoans/version"

module Rubykoans
  # Base error class for all rubykoans-raised exceptions.
  # Subclasses (UnsupportedFormatError, UnknownExerciseError,
  # CorruptStateError, CanonicalMissingError, ...) are added by the modules
  # that raise them. Defined BEFORE the requires below so subclasses in
  # those files can reference `Rubykoans::Error` at load time.
  class Error < StandardError; end
end

require_relative "rubykoans/exercise"
require_relative "rubykoans/curriculum"
require_relative "rubykoans/colors"
