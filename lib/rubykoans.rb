# frozen_string_literal: true

require_relative "rubykoans/version"

module Rubykoans
  # Base error class for all rubykoans-raised exceptions.
  # Subclasses (UnknownExerciseError, CorruptStateError, CanonicalMissingError, ...)
  # are added by later plans alongside the modules that raise them.
  class Error < StandardError; end
end
